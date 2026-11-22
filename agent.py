import os
import re
import sys
import json
import uuid
import asyncio
import datetime
import certifi
from pathlib import Path
from dotenv import load_dotenv
from openai import AsyncOpenAI

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

os.environ["OMP_NUM_THREADS"] = "1"
os.environ["MKL_NUM_THREADS"] = "1"
os.environ["SSL_CERT_FILE"] = certifi.where()
os.environ["REQUESTS_CA_BUNDLE"] = certifi.where()
os.environ["GRPC_DEFAULT_SSL_ROOTS_FILE_PATH"] = certifi.where()

from livekit.agents import (
    Agent,
    AgentSession,
    AutoSubscribe,
    JobContext,
    RunContext,
    StopResponse,
    WorkerOptions,
    cli,
    function_tool,
    llm,
)
from livekit.agents.voice import room_io
from livekit.plugins import openai, silero

# Realtime (Gemini Live) eklentisi ana thread'de yüklenmeli (LiveKit kuralı)
try:
    from livekit.plugins import google as lk_google
except ImportError:
    lk_google = None

from piper_tts_plugin import (
    PiperTTS,
    GroqMultilingualSTT,
    GoogleFreeSTT,
    clean_turkish_tts_text,
    detect_text_language,
    set_active_call_lang,
    CONFIG_FILE,
)
from services import CalendarAndNotesService, TURKISH_DAYS, URGENT_KEYWORDS
from latency_logger import LatencyLogger
from config_validation import format_report, load_agent_config, validate_configuration
from agent_brain import CallMessage, Language

load_dotenv()

# ---------------------------------------------------------------------------
# Diller: yalnızca Türkçe, Arapça, İngilizce
# Açılış her zaman Türkçe; arayan hangi dilde konuşursa görüşme o dilde sürer.
# Özet ve bildirim de görüşmenin yapıldığı dilde olur.
# ---------------------------------------------------------------------------
SUPPORTED_LANGS = ("tr", "ar", "en")
DEFAULT_LANG = "tr"
LANG_NAMES_TR = {"tr": "Türkçe", "ar": "Arapça", "en": "İngilizce"}

OPENING_GREETING = (
    "Merhaba, ben bir yapay zekâ asistanıyım. Aradığınız kişi şu anda müsait değil. "
    "Görüşmemiz kaydedilmektedir. Size nasıl yardımcı olabilirim?"
)

DISABLED_MESSAGE = "Merhaba, yapay zekâ asistanı şu anda devre dışıdır. Lütfen daha sonra tekrar arayın."

NO_CONSENT_TEXT = {
    "tr": ("Geri Arama Talebi (Kayıt İzni Yok)",
           "Arayan kişi görüşmenin kaydedilmesine izin vermedi; yalnızca geri arama talebi alındı."),
    "ar": ("طلب معاودة الاتصال (بدون إذن تسجيل)",
           "لم يوافق المتصل على تسجيل المكالمة؛ تم تسجيل طلب معاودة الاتصال فقط."),
    "en": ("Callback Request (No Recording Consent)",
           "The caller did not consent to recording; only a callback request was taken."),
}

APPOINTMENT_TEXT = {
    "tr": "{name} için {when} saatine '{reason}' randevusu oluşturuldu.",
    "ar": "تم حجز موعد لـ {name} في {when} بخصوص: {reason}.",
    "en": "An appointment for {name} was booked at {when} regarding: {reason}.",
}

ANONYMOUS = {"tr": "İsimsiz Arayan", "ar": "متصل مجهول", "en": "Anonymous Caller"}


def normalize_lang(code, fallback: str = DEFAULT_LANG) -> str:
    c = (code or "").strip().lower()[:2]
    return c if c in SUPPORTED_LANGS else fallback


PROMPTS_BY_LANG = {
    "tr": (
        "kız kardeşiyim, arkadaşıyım, merhaba, "
        "mesaj bırakmak istiyorum, ona söyle, beni geri arasın, acil, hastane, kaza, "
        "randevu almak istiyorum, randevumu sil, randevuyu iptal et."
    ),
    "ar": (
        "مرحبا، السلام عليكم، أنا صديقه، أخته، أريد ترك رسالة، "
        "حجز موعد، إلغاء الموعد، اتصل بي، عاجل، مستشفى، الساعة التاسعة صباحاً، الخامسة مساءً. "
        # Lehceli kaliplar: Whisper'in agizlari dogru yazmasina yardim eder.
        "عايز أسيب رسالة، إيه الأخبار، ممكن تقوله، كلمني، أنا صاحبه، عايز أحجز معاد، "
        "بدي احكي معه، شو الأخبار، بدي احجز موعد، خلينا نشوف، "
        "أبغى أحجز موعد، وش الأخبار، أبي أكلمه، تكفى خبره."
    ),
    "en": (
        "Hello, I would like to leave a message, book an appointment, "
        "cancel my appointment, please call me back, urgent."
    ),
}


HALLUCINATION_PHRASES = (
    "altyazı",
    "m.k.",
    "izlediğiniz için",
    "abone ol",
    "thank you for watching",
    "thanks for watching",
    "sorry?",
    "subtitle",
    "je crois que c'est",
    "sous-titres",
    "amara.org",
)


def is_valid_caller_speech(text: str) -> bool:
    cleaned = (text or "").strip()
    if len(cleaned) < 1:
        return False
    lower = cleaned.lower()
    if any(h in lower for h in HALLUCINATION_PHRASES):
        return False
    if re.search(r"[\u0590-\u05FF]", cleaned):
        return False
    return True


def to_brain_language(code: str) -> Language:
    """agent_brain dil tipine cevirir (varsayilan Turkce)."""
    return {
        "tr": Language.TURKISH,
        "ar": Language.ARABIC,
        "en": Language.ENGLISH,
    }.get(normalize_lang(code, DEFAULT_LANG), Language.TURKISH)


MISSING_FIELD_HINTS = {
    "message": "arayanin mesajini",
    "callback_requested": "geri aranmak isteyip istemedigini",
    "confirmed": "bilgileri tekrar edip onayini",
}


ARABIC_RANGE = re.compile(r"[\u0600-\u06FF]")
TURKISH_CHARS = re.compile(r"[ğşıİĞŞÇÖÜçöü]")


def script_hint(text: str) -> str | None:
    """Yazi sisteminden kesin dil ipucu verir; yoksa None doner.

    Whisper kisa cumlelerde dili karistirabiliyor. Arap harfleri gorulduyse
    dil kesin Arapca; Turkce'ye ozgu harfler varsa kesin Turkce sayilir.
    """
    if not text:
        return None
    if ARABIC_RANGE.search(text):
        return "ar"
    if TURKISH_CHARS.search(text):
        return "tr"
    return None


MODEL_PATH = Path(__file__).parent / "models" / "tr_TR-dfki-medium.onnx"
STARTUP_CONFIG_ISSUES = validate_configuration(
    project_dir=Path(__file__).parent,
    config=load_agent_config(Path(__file__).parent / "agent_config.json"),
)
if STARTUP_CONFIG_ISSUES:
    print(format_report(STARTUP_CONFIG_ISSUES), flush=True)
if any(issue.severity == "error" for issue in STARTUP_CONFIG_ISSUES):
    raise RuntimeError(
        "Ayar denetimi başarısız. Yukarıdaki HATA satırlarını düzeltip yeniden başlatın."
    )

service_manager = CalendarAndNotesService()
GLOBAL_TTS = PiperTTS(model_path=MODEL_PATH)
GLOBAL_TTS.prewarm([
    OPENING_GREETING,
    "Rica ederim, iyi günler dilerim!",
])
GLOBAL_VAD = silero.VAD.load(
    min_speech_duration=0.15,
    min_silence_duration=0.42,
    activation_threshold=0.45,
    max_buffered_speech=20.0,
)
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")


def load_active_config() -> dict:
    default_cfg = {
        "preset": "natural_emel",
        "stt_model": "whisper-large-v3-turbo",
        "llm_model": "openai/gpt-oss-20b",
        "tts_voice": "edge-emel",
        "stt_language": "auto",
        "assistant_mode": "hybrid",
        "owner_language": "tr",
        "work_start": "09:00",
        "work_end": "17:00",
        "assistant_enabled": True,
        "greeting_text": "",
        "architecture": "realtime",
        "realtime_model": "",
        "realtime_voice": "Puck",
    }
    if CONFIG_FILE.exists():
        try:
            data = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                default_cfg.update(data)
        except Exception:
            pass
    return default_cfg


def build_agent_instructions(lang: str, live_schedule: str, active_cfg: dict, greeted_already: bool = True) -> str:
    today = datetime.date.today()
    tomorrow = today + datetime.timedelta(days=1)
    today_tr = f"{today.isoformat()} ({TURKISH_DAYS[today.weekday()]})"
    tomorrow_tr = f"{tomorrow.isoformat()} ({TURKISH_DAYS[tomorrow.weekday()]})"
    work_start = active_cfg.get("work_start", "09:00")
    work_end = active_cfg.get("work_end", "17:00")
    mode = active_cfg.get("assistant_mode", "hybrid")
    owner_lang = normalize_lang(active_cfg.get("owner_language"), DEFAULT_LANG)

    lang_rules = {
        "tr": "Arayanla YALNIZCA doğal ve akıcı TÜRKÇE konuş.",
        "ar": "افهم المتصل مهما كانت لهجته: المصرية أو الشامية أو الخليجية أو المغاربية أو العراقية أو السودانية أو الفصحى، وافهم الكلمات العامية والاختصارات الدارجة ولا تطلب منه أن يتحدث بالفصحى أبداً. إذا لم تفهم كلمة واحدة فقط فاسأل عنها بلطف ولا تعتذر كثيراً. أما ردك أنت فيكون بالعربية الفصحى الحديثة فقط، بأسلوب طبيعي وودود وواضح وقصير، ولا تستخدم أي لهجة عامية في كلامك. لا تستخدم رموزاً أو نقاطاً (-) في ردك.",
        "en": "Speak with the caller ONLY in natural, friendly ENGLISH.",
    }
    lang_rule = lang_rules.get(
        lang,
        "Arayan Türkçe, Arapça veya İngilizce konuşursa O DİLDE yanıt ver ve görüşme boyunca o dilde devam et. "
        "Arayan başka bir dilde konuşursa Türkçe konuş.",
    )

    first_turn_disclosure = (
        ""
        if greeted_already
        else (
            "İLK YANIT: Açılış Türkçe yapıldı. Arayanın dilinde çok kısaca bir yapay zekâ asistanı olduğunu ve "
            "görüşmenin kaydedildiğini söyle, sonra hemen isteğine yanıt ver.\n"
        )
    )

    mode_instruction = (
        "Hem kişisel mesaj/not bırakma hem de mesai içi randevu taleplerini karşıla."
        if mode == "hybrid"
        else ("Yalnızca mesaj ve geri arama talebi al, randevu verme." if mode == "personal" else "Randevu ve mesaj taleplerini karşıla.")
    )

    return (
        "Sen telefon sahibinin sesli yapay zekâ asistanısın (Türkçe, Arapça, İngilizce). "
        "Telefon sahibinin adını asla söyleme; 'aradığınız kişi' de. Kısa (1-2 cümle), doğal, samimi ve kibar konuş.\n"
        f"BUGÜN: {today_tr} | YARIN: {tomorrow_tr} | MESAİ: {work_start}-{work_end} | MOD: {mode_instruction}\n"
        f"SAHİP ÖZETİ DİLİ: {LANG_NAMES_TR[owner_lang]}.\n"
        f"DİL KURALI: {lang_rule}\n"
        f"{first_turn_disclosure}"
        f"TAKVİM ÖZETİ: {live_schedule}\n"
        "SAAT VE TARİH OKUMA KURALI (ÇOK ÖNEMLİ):\n"
        "- Yanıtlarında ASLA '9.00', '09:00', '13:30', '17:00' gibi rakamlı saat veya '2026-11-03' gibi ISO tarih yazma!\n"
        "- Saatleri her dilde SADECE sabah/akşam kelimeleriyle doğal oku:\n"
        "  * Arapça: 'التاسعة صباحاً'، 'الخامسة مساءً'، 'الواحدة والنصف مساءً'\n"
        "  * Türkçe: 'sabah saat dokuz', 'akşam beş', 'öğleden sonra bir buçuk'\n"
        "  * İngilizce: 'nine in the morning', 'five in the evening'\n"
        "- Araç (function tool) çağırırken parametrelerde YYYY-MM-DD ve HH:MM formatını kullan, ama konuşma metninde asla rakamlı saat/tarih kullanma.\n"
        "TEMEL KURALLAR:\n"
        "0. ARAÇ OLMADAN İŞLEM YOK: Randevu oluşturma, iptal veya değiştirme işlemini YALNIZCA ilgili aracı çağırıp 'BAŞARILI' sonucunu aldıktan sonra arayana bildir. "
        "Aracı çağırmadan 'iptal ettim', 'iptal ediyorum', 'oluşturdum' gibi cümleler KURMA.\n"
        "1. GİZLİLİK: Telefon sahibinin kiminle randevusu olduğunu veya özel program detaylarını asla söyleme; sadece müsait veya meşgul olduğunu belirt.\n"
        f"2. RANDEVU VE MESAİ: Randevular YALNIZCA mesai saatleri ({work_start}-{work_end}) içinde verilir (`book_calendar_appointment`). "
        "Arayan mesai dışında bir saat isterse (gece, sabah erken veya mesai sonrası) randevu OLUŞTURMA; kibarca mesai saatlerini söyle, "
        "mesai içinde en yakın uygun saati öner veya mesaj bırakmasını teklif et.\n"
        "3. MESAJ VE NOT: Mesaj bırakmak isteyenden adını, mesajını ve geri aranmak isteyip istemediğini öğren. "
        "Sonra mesajı KISACA tekrar edip 'doğru mu, kaydedeyim mi?' diye sor. Net bir evet aldıktan sonra "
        "`save_call_note` aracını caller_confirmed=True ile çağır. Araç HATA dönerse eksiği sor ve tekrar dene. "
        "Özet metnini SAHİP ÖZETİ DİLİNDE yaz. İsimleri, telefon numaralarını, tarihleri ve saatleri değiştirme; "
        "olmayan bilgi ekleme. Kayıt izni vermezse `recording_consent=False` gönder.\n"
        "4. BİLGİLERİ TEKRAR SORMA: Arayan adını, konusunu veya saati bir kez söylediyse bunu hatırla ve tekrar sorma. Ad yalnızca hiç söylenmediyse sorulur.\n"
        "5. TELEFON NUMARASI SORMA: Arayanın numarası arama sırasında sistem tarafından otomatik alınır; numara isteme.\n"
        "6. RANDEVUYU SEN BAŞLATMA: Randevuyu YALNIZCA arayan açıkça isterse aç. Arayan randevu istemediyse randevu önerme ve oluşturma; mesaj al. Mevcut bir toplantının saatini değiştirme talebi de bir MESAJDIR (telefon sahibi karar verir).\n"
        "6b. RANDEVU ÜÇ ADIMDIR: (1) ad ve SOYADI öğren, (2) tarihi ve saati netleştir, (3) '<Ad Soyad>, <gün> <saat> için randevu oluşturuyorum, onaylıyor musunuz?' diye SOR ve net bir evet al. Ancak bundan sonra `book_calendar_appointment` aracını caller_confirmed=True ile çağır. Araç HATA dönerse eksik bilgiyi sor ve tekrar dene; 'BAŞARILI' görmeden randevu oluştu deme.\n"
        "7. RANDEVU İPTALİ: Önce KİM olduğunu öğren: ADINI VE SOYADINI sor. Sonra randevunun TARİHİNİ ve SAATİNİ sor. "
        "Bu üçü tam olmadan `cancel_calendar_appointment` çağırma; tek isimle veya eksik bilgiyle iptal etme. "
        "Araç 'BAŞARILI' dönmezse randevuyu iptal edilmiş gibi gösterme ve başka kişilerin randevu bilgilerini asla söyleme.\n"
        "7b. RANDEVU DEĞİŞTİRME: Arayan KENDİ randevusunun saatini değiştirmek isterse önce adı-soyadı, eski tarih ve saati doğrula; yeni saatin müsaitliğini `check_calendar_availability` ile kontrol et; "
        "sonra eski randevuyu `cancel_calendar_appointment` ile iptal et ve yenisini `book_calendar_appointment` ile oluştur. İki işlem de BAŞARILI olmadan değişti deme.\n"
        "'yarın', 'öbür gün', 'gelecek pazartesi' gibi ifadeleri BUGÜN tarihine göre YYYY-MM-DD'ye çevir.\n"
        "8. ACİL DURUM: Acil/hastane/kaza durumunda hemen `save_call_note(is_urgent=True)` çağır. Hayati tehlike varsa 112'yi aramasını söyle.\n"
        f"9. SABAH MI AKŞAM MI: Arayan 'saat üçte' gibi belirsiz bir saat söylerse sabah mı yoksa öğleden sonra mı olduğunu KISACA sor. "
        "Araca verirken 24 saatlik sisteme çevir: sabah sekiz=08:00, öğleden sonra üç=15:00, akşam yedi=19:00, gece yarısından sonra bir=01:00. "
        f"Mesai {work_start}-{work_end} olduğu için gece yarısından sonraki veya mesai dışındaki saatlere randevu verme.\n"
        "10. ARKADAŞ VE AİLE ARAMALARI: Arayan telefon sahibinin arkadaşı, akrabası veya ailesinden biri olduğunu söylerse resmi davranma. "
        "Sıcak, samimi ve tamamen doğal konuş; adını nazikçe öğren, mesajını al ve geri aranmak isteyip istemediğini sor. "
        "Bu bir iş görüşmesi değildir: MESAİ SAATLERİNDEN, randevu takviminden, müsaitlikten veya kurumsal ifadelerden ASLA bahsetme. "
        "Böyle bir arayan bir buluşma saati söylerse (örneğin 'yarın akşam dokuzda görüşelim') bu bir RANDEVU DEĞİL, bir MESAJDIR: "
        "saati olduğu gibi mesaja yaz, takvime bakma, 'mesai dışı' deme, onay isteme. Telefon sahibi kendisi karar verir.\n"
        "10b. YAKINLIK ADI SAYILIR: Arayan kendini 'annesiyim', 'ablasıyım', 'arkadaşıyım', 'ممكن أنا ماما', 'أنا أخته' gibi bir yakınlıkla tanıtırsa "
        "bu GEÇERLİ bir isimdir ve ad sorulmaya devam edilmez. Kayda '<Telefon sahibi>'nin annesi' biçiminde yaz. "
        "Gerçek adını kendiliğinden söylerse onu kullan; söylemiyorsa yakınlık ifadesi yeterlidir, ısrar etme.\n"
        f"10c. KAYIT DİLİ: `save_call_note` aracında iki alan İKİ FARKLI dilde yazılır. "
        "`caller_purpose` alanını ARAYANIN GÖRÜŞMEDE KONUŞTUĞU DİLDE yaz: arayan Türkçe konuştuysa Türkçe, "
        "Arapça konuştuysa Arapça, İngilizce konuştuysa İngilizce. "
        f"`summary_tr` alanını ise DAİMA {LANG_NAMES_TR[owner_lang].upper()} yaz, çünkü onu telefon sahibi okuyacak. "
        "Arayan Türkçe veya Arapça konuşurken `caller_purpose` alanına İngilizce yazma.\n"
        "10d. BİLGİ UYDURMA: Fiyat, ücret, adres, süre veya başka bir ayrıntıyı kendiliğinden söyleme. "
        "Telefon sahibinin sana vermediği bir bilgiyi tahmin etme; bilmiyorsan 'bunu kendisine ileteceğim' de.\n"
        "11. DOĞALLIK: Robot gibi konuşma. Tek seferde tek soru sor, maddeler halinde sayma, arayanın sözünü kesme, kısa ve insan gibi yanıt ver."
    )


class TurkishCallAssistant(Agent):
    def __init__(self, call_state: dict, live_schedule: str, active_cfg: dict) -> None:
        self.call_state = call_state
        self.live_schedule = live_schedule
        self.active_cfg = active_cfg
        super().__init__(
            instructions=build_agent_instructions("auto", live_schedule, active_cfg, greeted_already=True)
        )

    def current_lang(self) -> str:
        return normalize_lang(self.call_state.get("selected_lang"), DEFAULT_LANG)

    def llm_node(self, chat_ctx: llm.ChatContext, tools: list[llm.Tool], model_settings):
        try:
            items = getattr(chat_ctx, "items", None)
            if isinstance(items, list) and len(items) > 16:
                sys_items = [it for it in items if getattr(it, "role", None) in ("system", "developer")]
                other_items = [it for it in items if getattr(it, "role", None) not in ("system", "developer")]
                if len(other_items) > 10:
                    trimmed = sys_items[:1] + other_items[-10:]
                    while len(trimmed) > 1 and getattr(trimmed[1], "type", "") == "function_call_output":
                        trimmed.pop(1)
                    items[:] = trimmed
        except Exception:
            pass
        return Agent.default.llm_node(self, chat_ctx, tools, model_settings)

    async def on_user_turn_completed(
        self, turn_ctx: llm.ChatContext, new_message: llm.ChatMessage
    ) -> None:
        text = (new_message.text_content or "").strip()
        if not is_valid_caller_speech(text):
            print(f"[Filtered Noise] Ignored: {text}", flush=True)
            raise StopResponse()

        # Dil: Whisper'ın algıladığı dil (yalnızca tr/ar/en; diğerleri -> Türkçe)
        previous = self.call_state.get("selected_lang")
        detected = normalize_lang(self.call_state.get("last_detected_iso"), DEFAULT_LANG)
        if detected != previous:
            first_switch = previous in (None, "auto")
            self.call_state["selected_lang"] = detected
            set_active_call_lang(detected)
            if self.call_state.get("latency"):
                self.call_state["latency"].set_lang(detected)
            print(f"[Dil] Görüşme dili: {LANG_NAMES_TR[detected]}", flush=True)
            notify = self.call_state.get("notify_lang")
            if notify:
                asyncio.create_task(notify(detected))
            # Açılış Türkçe yapıldığı için Türkçe dışı dile ilk geçişte kısa AI/kayıt bilgilendirmesi
            await self.update_instructions(
                build_agent_instructions(
                    detected, self.live_schedule, self.active_cfg,
                    greeted_already=(detected == "tr" or not first_switch),
                )
            )

    @function_tool(description="Belirtilen tarihteki (YYYY-MM-DD) çalışma saatleri (09:00-17:00) içindeki müsait ve dolu saatleri kontrol eder.")
    async def check_calendar_availability(
        self, context: RunContext, date_str: str
    ) -> str:
        print(f"[Tool Call] Checking calendar availability for: {date_str}", flush=True)
        return await asyncio.to_thread(service_manager.get_available_slots, date_str)

    @function_tool(description="Arayanın AÇIKÇA istediği ve SÖZLÜ OLARAK onayladığı randevuyu mesai saatleri içinde Google Takvim'e kaydeder. caller_name ad ve soyad olmalı; caller_confirmed yalnızca arayan 'evet' dedikten sonra True gönderilir. start_iso formatı: YYYY-MM-DDTHH:MM:00.")
    async def book_calendar_appointment(
        self,
        context: RunContext,
        caller_name: str,
        reason: str,
        start_iso: str,
        caller_confirmed: bool = False,
    ) -> str:
        print(
            f"[Tool Call] Booking calendar event for {caller_name} at {start_iso} "
            f"(confirmed={caller_confirmed})",
            flush=True,
        )
        # Guvenlik kapisi: asistan kendi basina randevu olusturamaz.
        if not caller_confirmed:
            return (
                "HATA: Arayan randevuyu henuz onaylamadi. Tarihi, saati ve adini "
                "tekrar edip onay iste; ancak net bir evet aldiktan sonra bu araci "
                "caller_confirmed=True ile cagir."
            )
        if len(str(caller_name or "").strip().split()) < 2:
            return (
                "HATA: Randevu icin ad ve soyad gerekli. Arayandan adini ve soyadini "
                "iste, sonra tekrar dene."
            )
        if not str(start_iso or "").strip():
            return "HATA: Randevu tarihi ve saati eksik."
        res = await asyncio.to_thread(
            service_manager.book_appointment, caller_name, reason, start_iso
        )
        if res.startswith("BAŞARILI"):
            lang = self.current_lang()
            when = start_iso[:16].replace('T', ' ')
            self.call_state["caller_name"] = caller_name or ANONYMOUS[lang]
            self.call_state["caller_purpose"] = reason
            self.call_state["appointment_info"] = f"{when} ({reason})"
            await asyncio.to_thread(
                service_manager.save_call_summary,
                self.call_state["caller_name"],
                self.call_state["caller_purpose"],
                APPOINTMENT_TEXT[lang].format(name=self.call_state["caller_name"], when=when, reason=reason),
                self.call_state["appointment_info"],
                self.call_state["call_id"],
                False,
                lang=lang,
            )
        return res

    @function_tool(description="Randevuyu iptal eder. ÜÇ bilgi de zorunludur: caller_name (randevu sahibinin adı soyadı), date_str (YYYY-MM-DD) ve time_hm (HH:MM). Bilgiler takvimdeki randevuyla eşleşmezse iptal edilmez.")
    async def cancel_calendar_appointment(
        self,
        context: RunContext,
        date_str: str = "",
        time_hm: str = "",
        caller_name: str = "",
    ) -> str:
        print(
            f"[Tool Call] Canceling calendar event: date={date_str}, time={time_hm}, caller={caller_name}",
            flush=True,
        )
        eksik = []
        if len(str(caller_name or "").strip().split()) < 2:
            eksik.append("ad ve soyad")
        if not str(date_str or "").strip():
            eksik.append("randevunun tarihi")
        if not str(time_hm or "").strip():
            eksik.append("randevunun saati")
        if eksik:
            return (
                "HATA: Iptal icin " + ", ".join(eksik) + " gerekli. "
                "Arayandan bu bilgileri iste ve sonra tekrar dene."
            )
        res = await asyncio.to_thread(
            service_manager.cancel_appointment, date_str, time_hm, caller_name
        )
        if res.startswith("BAŞARILI"):
            self.call_state["appointment_canceled"] = True
            self.call_state["appointment_info"] = f"İPTAL EDİLDİ ({date_str} {time_hm})"
        return res

    @function_tool(description="Arayanın SÖZLÜ ONAYINDAN sonra mesajı, arama nedenini, geri aranma isteğini ve acil durumu kaydeder. caller_purpose ve summary_tr sahibin dilinde yazılır. caller_confirmed yalnızca arayan bilgileri onayladıktan sonra True gönderilir.")
    async def save_call_note(
        self,
        context: RunContext,
        caller_name: str = "İsimsiz Arayan",
        caller_purpose: str = "Mesaj Bırakma",
        summary_tr: str = "",
        callback_requested: bool = False,
        is_urgent: bool = False,
        recording_consent: bool = True,
        caller_confirmed: bool = False,
    ) -> str:
        print(
            f"[Tool Call] Saving call note for {caller_name} (urgent={is_urgent}, callback={callback_requested}, consent={recording_consent})",
            flush=True,
        )
        owner_lang = normalize_lang(self.active_cfg.get("owner_language"), DEFAULT_LANG)

        # agent_brain sozlesmesi: eksik veya teyitsiz kayit kabul edilmez.
        draft = CallMessage(
            call_id=str(self.call_state.get("call_id") or "cagri"),
            caller_language=to_brain_language(self.current_lang()),
            owner_language=to_brain_language(owner_lang),
            message=(summary_tr or "").strip() or None,
            caller_name=(caller_name or "").strip() or None,
            callback_requested=bool(callback_requested),
            confirmed=bool(caller_confirmed),
        )
        missing = draft.missing_required_fields()
        if missing:
            eksik = ", ".join(MISSING_FIELD_HINTS.get(f, f) for f in missing)
            print(f"[Brain] Kayit reddedildi, eksik: {missing}", flush=True)
            return (
                f"HATA: Kayit yapilamadi. Once {eksik} ogren, mesaji tekrar edip "
                "onayini al, sonra bu araci caller_confirmed=True ile tekrar cagir."
            )

        safe_name = (caller_name or "").strip()
        if not safe_name or safe_name in ANONYMOUS.values():
            # Randevu alinirken veya daha once ogrenilmis bir ad varsa onu koru.
            known = str(self.call_state.get("caller_name") or "").strip()
            if known and known not in ANONYMOUS.values():
                safe_name = known
        if not safe_name or safe_name in ANONYMOUS.values():
            # Isimsiz kayitlara yalnizca gercek bir mesaj veya acil durum
            # varsa izin verilir; aksi halde modelden once ismi sormasi istenir.
            if not is_urgent and len(str(summary_tr or "").split()) < 4:
                print("[Brain] Kayit reddedildi: isim ve mesaj yok", flush=True)
                return (
                    "HATA: Kayit yapilamadi. Arayanin adini nazikce sor; ad vermek "
                    "istemiyorsa en azindan birakmak istedigi mesaji ogren, sonra "
                    "bu araci tekrar cagir."
                )
            safe_name = ANONYMOUS[owner_lang]
        if not recording_consent:
            caller_purpose, summary_tr = NO_CONSENT_TEXT[owner_lang]

        self.call_state["caller_name"] = safe_name
        self.call_state["caller_purpose"] = caller_purpose
        self.call_state["is_urgent"] = bool(is_urgent)
        self.call_state["callback_requested"] = bool(callback_requested)
        self.call_state["recording_consent"] = bool(recording_consent)

        await asyncio.to_thread(
            service_manager.save_call_summary,
            safe_name,
            caller_purpose,
            summary_tr,
            self.call_state.get("appointment_info", ""),
            self.call_state["call_id"],
            False,
            is_urgent=bool(is_urgent),
            callback_requested=bool(callback_requested),
            caller_number=self.call_state.get("caller_number", "VoIP / Web"),
            lang=owner_lang,
        )
        return "Mesaj ve görüşme notu başarıyla kaydedildi."



class RealtimeCallAssistant(TurkishCallAssistant):
    """Realtime (Gemini Live): aynı talimatlar ve araçlar; dili model kendisi algılar."""

    async def on_user_turn_completed(self, turn_ctx, new_message) -> None:
        # Realtime modelde sıra ve dil yönetimini model yapar; müdahale etmiyoruz.
        return


# services.py'deki ortak listeye birkac belirti daha eklenir.
EXTRA_URGENT_WORDS = (
    "ameliyat", "polis", "ölüm", "olum", "kalp", "nefes", "112",
    "نزيف", "إغماء", "اغماء", "حريق", "خطر",
    "fire", "police", "bleeding", "unconscious",
)
ALL_URGENT_WORDS = tuple(URGENT_KEYWORDS) + EXTRA_URGENT_WORDS


def transcript_has_urgency(transcript_lines: list[str]) -> bool:
    """Gorusmede gercekten acil bir belirti gecip gecmedigine bakar.

    Model zaman zaman siradan bir sohbeti de acil isaretliyor; bu durumda
    kayit kurallari devre disi kaliyordu. Metinde hicbir acil isareti yoksa
    etiket guvenilmez sayilir.
    """
    text = " ".join(transcript_lines).lower()
    return any(word in text for word in ALL_URGENT_WORDS)


def caller_word_count(transcript_lines: list[str]) -> int:
    """Yalnizca ARAYANIN soyledigi kelimeleri sayar.

    Asistanin kendi karsilama cumlesi de bir satir oldugu icin satir sayisina
    bakmak yetmiyordu: telefonu acip hemen kapatan biri bile kayit olusturuyordu.
    """
    total = 0
    for line in transcript_lines:
        if line.startswith("Arayan:"):
            total += len(line.split(":", 1)[1].split())
    return total


def should_skip_log(transcript_lines: list[str], call_state: dict) -> str:
    """Kaydedilmeyecek gorusmeler icin sebebi, kaydedilecekse bos metin doner.

    Acil durumlar her zaman kaydedilir; kisa ya da isimsiz olmalari onemli degil.
    """
    if call_state.get("is_urgent") and transcript_has_urgency(transcript_lines):
        return ""
    words = caller_word_count(transcript_lines)
    if words < 4:
        return f"arayan konusmadi (yalnizca {words} kelime)"
    if not str(call_state.get("caller_name") or "").strip() and words < 10:
        return f"isim yok ve icerik cok kisa ({words} kelime)"
    return ""


async def auto_summarize_on_hangup(transcript_lines: list[str], call_state: dict):
    if call_state.get("final_summary_done") or len(transcript_lines) < 2:
        return

    skip = should_skip_log(transcript_lines, call_state)
    if skip:
        call_state["final_summary_done"] = True
        print(f"[Auto Summary] Kayit olusturulmadi: {skip}", flush=True)
        return

    call_state["final_summary_done"] = True
    caller_lang = normalize_lang(call_state.get("selected_lang"), DEFAULT_LANG)
    owner_lang = normalize_lang(call_state.get("owner_language"), DEFAULT_LANG)

    if call_state.get("recording_consent") is False:
        purpose, summary = NO_CONSENT_TEXT[owner_lang]
        await asyncio.to_thread(
            service_manager.save_call_summary,
            call_state.get("caller_name") or ANONYMOUS[owner_lang],
            purpose,
            summary,
            "",
            call_state["call_id"],
            True,
            is_urgent=call_state.get("is_urgent", False),
            callback_requested=True,
            caller_number=call_state.get("caller_number", "VoIP / Web"),
            lang=owner_lang,
        )
        return

    client = await asyncio.to_thread(
        lambda: AsyncOpenAI(
            base_url="https://api.groq.com/openai/v1",
            api_key=GROQ_API_KEY,
        )
    )
    try:
        print(f"[Auto Summary] Görüşme özeti hazırlanıyor ({LANG_NAMES_TR[owner_lang]})...", flush=True)
        today_str = datetime.date.today().isoformat()
        tomorrow_str = (datetime.date.today() + datetime.timedelta(days=1)).isoformat()
        convo_text = "\n".join(transcript_lines)
        resp = await client.chat.completions.create(
            model="openai/gpt-oss-20b",
            temperature=0.1,
            response_format={"type": "json_object"},
            messages=[
                {
                    "role": "system",
                    "content": (
                        f"Bugünün tarihi: {today_str}, yarının tarihi: {tomorrow_str}.\n"
                        f"Aşağıdaki telefon görüşmesini analiz et. Görüşme {LANG_NAMES_TR[caller_lang]} yapıldı; "
                        f"caller_name alanındaki gerçek adı koru. "
                        f"caller_purpose alanını ARAYANIN KONUŞTUĞU DİLDE ({LANG_NAMES_TR[caller_lang].upper()}) yaz. "
                        f"summary_tr ve calendar_event_title alanlarını ise {LANG_NAMES_TR[owner_lang].upper()} yaz. "
                        "KURAL: Yalnızca görüşmede GEÇEN bilgileri yaz. Fiyat, ücret, adres, "
                        "süre, kişi sayısı gibi konuşulmamış hiçbir ayrıntıyı ekleme veya tahmin etme. "
                        "Emin olmadığın bir şeyi hiç yazma.\n"
                        "KURAL: Saatleri daima 24 saatlik biçimde yaz (14:30), '2:30' gibi yazma.\n"
                        "Yalnızca JSON döndür:\n"
                        '{\n'
                        f'  "caller_name": "Arayanın adı. Ad vermediyse ama yakınlığını söylediyse (annesi, ablası, arkadaşı) bunu ad olarak yaz, örn. \'Meryem\'in annesi\'. Hiçbiri yoksa \'{ANONYMOUS[owner_lang]}\'",\n'
                        f'  "caller_purpose": "Arama nedeni, kısa, {LANG_NAMES_TR[caller_lang]} dilinde",\n'
                        '  "summary_tr": "Arayanın mesajının ve görüşmenin net özeti (sahibin dilinde)",\n'
                        '  "is_urgent": "Yalnızca hastane, kaza, ambulans, yangın gibi gerçek bir acil durum varsa true; randevu, buluşma veya sıradan mesajlarda daima false",\n'
                        '  "callback_requested": "Arayan AÇIKÇA geri aranmak istediyse true, aksi halde false",\n'
                        '  "recording_consent": "Arayan kayda itiraz ettiyse false, aksi halde true",\n'
                        '  "calendar_event_iso": "Yalnızca mesai saatleri içinde kesin onaylanmış bir randevu varsa YYYY-MM-DDTHH:MM:00; yoksa boş string \'\'",\n'
                        '  "calendar_event_title": "Takvim için kısa başlık"\n'
                        '}'
                    ),
                },
                {"role": "user", "content": convo_text},
            ],
        )
        data = json.loads(resp.choices[0].message.content)
        def pick_name(*candidates: str) -> str:
            for value in candidates:
                text = str(value or "").strip()
                if text and text not in ANONYMOUS.values():
                    return text
            return ANONYMOUS[owner_lang]

        caller_name = pick_name(data.get("caller_name"), call_state.get("caller_name"))
        caller_purpose = data.get("caller_purpose") or call_state.get("caller_purpose") or ""
        summary_tr = data.get("summary_tr") or convo_text
        is_urgent = bool(data.get("is_urgent")) or bool(call_state.get("is_urgent"))
        if is_urgent and not transcript_has_urgency(transcript_lines):
            print("[Auto Summary] 'acil' etiketi metinde karsiligi olmadigi icin kaldirildi", flush=True)
            is_urgent = False
        if any(k in convo_text.lower() for k in ALL_URGENT_WORDS):
            is_urgent = True
        callback_requested = (
            bool(data.get("callback_requested"))
            if "callback_requested" in data
            else bool(call_state.get("callback_requested", True))
        )
        recording_consent = data.get("recording_consent", True)
        if recording_consent is False:
            caller_purpose, summary_tr = NO_CONSENT_TEXT[owner_lang]

        cal_iso = (data.get("calendar_event_iso") or "").strip()
        cal_title = (data.get("calendar_event_title") or caller_purpose).strip()

        if cal_iso and not call_state.get("appointment_info"):
            # Takvime yazilmaz, yalnizca ozete not dusulur: randevu acmak
            # arayanin acik onayini gerektirir (bkz. kural 6 ve 6b).
            print(f"[Auto Summary] Randevu onerisi kaydedilmedi (onay yok): {cal_iso} {cal_title}", flush=True)

        # Ozet ciktiktan sonraki son kontrol: ne isim, ne randevu, ne de
        # anlamli bir mesaj varsa kayit tutmanin degeri yok.
        meaningful = (
            is_urgent
            or bool(str(caller_name or "").strip() and caller_name not in ANONYMOUS.values())
            or bool(call_state.get("appointment_info"))
            or len(str(summary_tr or "").split()) >= 4
        )
        if not meaningful:
            print("[Auto Summary] Kayit olusturulmadi: isimsiz ve iceriksiz gorusme", flush=True)
            return

        await asyncio.to_thread(
            service_manager.save_call_summary,
            caller_name,
            caller_purpose,
            summary_tr,
            call_state.get("appointment_info", ""),
            call_state["call_id"],
            True,
            is_urgent=is_urgent,
            callback_requested=callback_requested,
            caller_number=call_state.get("caller_number", "VoIP / Web"),
            lang=owner_lang,
        )
        print("[Auto Summary] Saved call summary successfully!", flush=True)
    except Exception as e:
        call_state["final_summary_done"] = False
        print(f"[Auto Summary Error] {e}", flush=True)
    finally:
        await client.close()


async def entrypoint(ctx: JobContext):
    active_cfg = load_active_config()
    config_issues = validate_configuration(
        project_dir=Path(__file__).parent,
        config=active_cfg,
    )
    if config_issues:
        print(format_report(config_issues), flush=True)
    config_errors = [issue for issue in config_issues if issue.severity == "error"]
    if config_errors:
        raise RuntimeError(
            "Zorunlu ayarlar eksik. Ayrıntılar yukarıda listelendi; "
            "anahtar değerlerini değil yalnızca .env alanlarını kontrol edin."
        )

    architecture = str(active_cfg.get("architecture", "realtime")).strip().lower()
    if architecture not in ("cascade", "realtime"):
        architecture = "cascade"
    rt_model_name = str(active_cfg.get("realtime_model", "") or "").strip()
    rt_voice = str(active_cfg.get("realtime_voice", "Puck") or "Puck").strip()
    stt_model = active_cfg.get("stt_model", "whisper-large-v3-turbo")
    llm_model = active_cfg.get("llm_model", "openai/gpt-oss-20b")
    tts_voice = active_cfg.get("tts_voice", "edge-emel")
    assistant_enabled = active_cfg.get("assistant_enabled", True)

    if architecture == "realtime":
        print(
            f"[Agent] Room: {ctx.room.name} | MİMARİ=REALTIME | Gemini Live model={rt_model_name or 'varsayılan'}, ses={rt_voice} "
            f"| Diller: TR/AR/EN | Açılış: Türkçe",
            flush=True,
        )
    else:
        print(
            f"[Agent] Room: {ctx.room.name} | MİMARİ=CASCADE | STT={stt_model}, LLM={llm_model}, TTS={tts_voice} "
            f"| Diller: TR/AR/EN | Açılış: Türkçe",
            flush=True,
        )

    live_schedule_task = asyncio.create_task(
        asyncio.to_thread(service_manager.get_live_week_context)
    )
    if architecture == "cascade" and tts_voice != "elevenlabs":
        _greet_voice = tts_voice if tts_voice in ("edge-emel", "edge-ahmet") else (
            "edge-ahmet" if tts_voice.endswith("ahmet") else "edge-emel"
        )
        asyncio.create_task(GLOBAL_TTS.synthesize_edge_raw(OPENING_GREETING, _greet_voice))

    await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)
    live_schedule = await live_schedule_task

    # Arayan numarası: SIP/GSM çağrısında LiveKit katılımcı özelliklerinden otomatik alınır
    caller_number = "Web Simülasyonu"
    try:
        participant = await asyncio.wait_for(ctx.wait_for_participant(), timeout=10)
        sip_number = (participant.attributes or {}).get("sip.phoneNumber", "")
        if sip_number:
            caller_number = sip_number
        elif "sip" in ctx.room.name.lower():
            caller_number = "Bilinmeyen numara"
    except Exception:
        pass
    print(f"[Arayan] Numara: {caller_number}", flush=True)

    call_state = {
        "call_id": f"call_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:4]}",
        "final_summary_done": False,
        "caller_name": "",
        "caller_number": caller_number,
        "caller_purpose": "",
        "appointment_info": "",
        "appointment_canceled": False,
        "is_urgent": False,
        # Geri arama yalnizca arayan istediginde isaretlenir; varsayilan olarak
        # true birakilinca her kayit "geri donus bekliyor" gorunuyordu.
        "callback_requested": False,
        "recording_consent": True,
        "owner_language": normalize_lang(active_cfg.get("owner_language"), DEFAULT_LANG),
        "selected_lang": "auto",
        "last_detected_iso": DEFAULT_LANG,
    }
    set_active_call_lang(DEFAULT_LANG)
    if architecture == "realtime":
        latency = LatencyLogger(call_state["call_id"], "realtime", stt="gemini-live",
                                llm=rt_model_name or "varsayılan", tts=rt_voice)
    else:
        latency = LatencyLogger(call_state["call_id"], "cascade", stt=stt_model, llm=llm_model, tts=tts_voice)
    latency.set_lang(DEFAULT_LANG)
    call_state["latency"] = latency
    transcript_lines: list[str] = []

    async def shutdown_summary_callback():
        latency.print_summary()
        await auto_summarize_on_hangup(transcript_lines, call_state)

    ctx.add_shutdown_callback(shutdown_summary_callback)

    session_stt = None

    async def notify_lang(lang: str):
        # Arayüzde görüşme dilini göstermek için
        try:
            payload = json.dumps({"type": "lang", "lang": lang}).encode("utf-8")
            await ctx.room.local_participant.publish_data(payload, reliable=True)
        except Exception:
            pass

    call_state["notify_lang"] = notify_lang

    def on_whisper_lang_detected(iso_lang: str, text_val: str):
        text = (text_val or "").strip()
        lang = script_hint(text) or normalize_lang(iso_lang, DEFAULT_LANG)
        call_state["last_detected_iso"] = lang

        if session_stt is None or len(text.split()) < 2:
            return

        # Tek bir yanlis tanima tum gorusmeyi yanlis dile kilitlemesin:
        # ust uste iki ayni tahmin gerekiyor. Yazi sistemi ipucu (Arap harfleri,
        # Turkce'ye ozgu harfler) tek basina da yeterli sayilir.
        votes = call_state.setdefault("lang_votes", [])
        votes.append(lang)
        del votes[:-2]
        strong = script_hint(text) is not None
        if not strong and (len(votes) < 2 or votes[0] != votes[1]):
            return

        if call_state.get("stt_lang") == lang:
            return

        call_state["stt_lang"] = lang
        try:
            session_stt.update_options(language=lang, prompt=PROMPTS_BY_LANG.get(lang, ""))
            print(f"[STT] Dil ayarlandi: {LANG_NAMES_TR[lang]}", flush=True)
        except Exception as e:
            print(f"[STT] Dil ayarlanamadi: {e}", flush=True)

    if architecture == "realtime":
        if lk_google is None:
            raise RuntimeError(
                "Realtime için 'livekit-plugins-google' kurulu değil: "
                "pip install \"livekit-plugins-google==1.8.10\""
            )
        if not os.getenv("GOOGLE_API_KEY"):
            print("[HATA] .env içinde GOOGLE_API_KEY bulunamadı.", flush=True)
        rt_kwargs = {"voice": rt_voice, "temperature": 0.6}
        if rt_model_name:
            rt_kwargs["model"] = rt_model_name
        # Yerel VAD yalnızca "arayan sustu" anını ölçmek için (sıra yönetimini yine Gemini yapar)
        session = AgentSession(llm=lk_google.realtime.RealtimeModel(**rt_kwargs), vad=GLOBAL_VAD)
        assistant_agent = RealtimeCallAssistant(
            call_state=call_state,
            live_schedule=live_schedule,
            active_cfg=active_cfg,
        )
    else:
        if stt_model == "google-stt":
            # Google STT dil algılayamaz: yalnızca Türkçe dinler (karşılaştırma amaçlı)
            print("[Uyarı] Google STT seçili: yalnızca Türkçe tanınır, dil algılama kapalı.", flush=True)
            session_stt = GoogleFreeSTT(language="tr-TR")
        else:
            session_stt = GroqMultilingualSTT(
                model=stt_model,
                api_key=GROQ_API_KEY,
                language="auto",
                prompt="",
                on_language_detected=on_whisper_lang_detected,
            )

        # Istemci olusturmak SSL baglami kurdugu icin senkron calisirsa
        # olay dongusunu saniyelerce tikiyor ve ses gecikiyordu.
        primary_llm = await asyncio.to_thread(
            lambda: openai.LLM(
                base_url="https://api.groq.com/openai/v1",
                api_key=GROQ_API_KEY,
                model=llm_model,
                temperature=0.2,
            )
        )
        fallback_fast_llm = openai.LLM(
            base_url="https://api.groq.com/openai/v1",
            api_key=GROQ_API_KEY,
            model="llama-3.1-8b-instant" if llm_model != "llama-3.1-8b-instant" else "openai/gpt-oss-20b",
            temperature=0.2,
        )
        fallback_llama_llm = openai.LLM(
            base_url="https://api.groq.com/openai/v1",
            api_key=GROQ_API_KEY,
            model="llama-3.1-8b-instant",
            temperature=0.2,
        )
        session_llm = llm.FallbackAdapter([primary_llm, fallback_fast_llm, fallback_llama_llm])

        session = AgentSession(
            vad=GLOBAL_VAD,
            stt=session_stt,
            llm=session_llm,
            tts=GLOBAL_TTS,
            preemptive_generation=True,
            turn_handling={
                "turn_detection": "vad",
                "interruption": {"enabled": True, "mode": "vad"},
            },
        )

        assistant_agent = TurkishCallAssistant(
            call_state=call_state,
            live_schedule=live_schedule,
            active_cfg=active_cfg,
        )

    # ---- Gecikme ölçümü (terminal + latency_log.csv) ----
    @session.on("user_state_changed")
    def on_user_state(ev):
        latency.on_user_state(str(getattr(ev, "new_state", "")))

    @session.on("agent_state_changed")
    def on_agent_state(ev):
        latency.on_agent_state(str(getattr(ev, "new_state", "")))

    @session.on("metrics_collected")
    def on_metrics(ev):
        try:
            latency.on_metrics(ev.metrics)
        except Exception:
            pass

    @session.on("user_input_transcribed")
    def on_user_transcribed(ev):
        if ev.is_final and ev.transcript.strip():
            txt = ev.transcript.strip()
            if not is_valid_caller_speech(txt):
                return
            print(f"[Caller Said] {txt}", flush=True)
            transcript_lines.append(f"Arayan: {txt}")
            if architecture == "realtime":
                # Whisper yok: dili metinden tahmin et (yalnızca tr/ar/en)
                guess = normalize_lang(detect_text_language(txt), call_state.get("selected_lang") if call_state.get("selected_lang") in SUPPORTED_LANGS else DEFAULT_LANG)
                if guess != call_state.get("selected_lang"):
                    call_state["selected_lang"] = guess
                    latency.set_lang(guess)
                    print(f"[Dil] Görüşme dili: {LANG_NAMES_TR[guess]}", flush=True)
                    asyncio.create_task(notify_lang(guess))
            if any(k in txt.lower() for k in URGENT_KEYWORDS):
                call_state["is_urgent"] = True

    @session.on("conversation_item_added")
    def on_item_added(ev):
        try:
            role = getattr(ev.item, "role", "")
            text = clean_turkish_tts_text(getattr(ev.item, "text_content", "") or "")
            if role == "assistant" and text.strip():
                print(f"[AI Assistant] {text}", flush=True)
                transcript_lines.append(f"Asistan: {text}")
        except Exception:
            pass

    @session.on("close")
    def on_session_close(ev):
        asyncio.create_task(auto_summarize_on_hangup(transcript_lines, call_state))

    if architecture == "realtime":
        await session.start(room=ctx.room, agent=assistant_agent)
    else:
        await session.start(
            room=ctx.room,
            agent=assistant_agent,
            room_output_options=room_io.RoomOutputOptions(
                audio_sample_rate=GLOBAL_TTS.sample_rate,
                sync_transcription=False,
            ),
        )

    async def speak(text: str):
        if architecture == "realtime":
            # Realtime modelde ayrı TTS yok; cümleyi modele aynen söyletiyoruz
            await session.generate_reply(
                instructions=f"Arayana Türkçe olarak şu cümleyi aynen, doğal bir tonla söyle ve başka bir şey ekleme: \"{text}\""
            )
        else:
            await session.say(text, allow_interruptions=True)

    if not assistant_enabled:
        await speak(DISABLED_MESSAGE)
        return

    # Açılış her zaman Türkçe: yapay zekâ + kayıt bilgilendirmesi, isim yok
    await speak(OPENING_GREETING)


if __name__ == "__main__":
    cli.run_app(
        WorkerOptions(
            entrypoint_fnc=entrypoint,
        )
    )
