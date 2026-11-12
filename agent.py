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
from agent_brain.language import normalize_language
from agent_brain.models import CallMessage, Urgency
from agent_brain.recovery import ClarificationTracker, emergency_guidance, is_life_threatening
from agent_brain.personality import personality_rule
from agent_brain.tools import validate_call_for_storage

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
        "حجز موعد، إلغاء الموعد، اتصل بي، عاجل، مستشفى، الساعة التاسعة صباحاً، الخامسة مساءً."
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


def has_usable_callback_number(value: str) -> bool:
    """SIP'ten gelen veya arayanın verdiği geri dönüş numarasını ayırt eder."""
    cleaned = re.sub(r"\D", "", value or "")
    return 7 <= len(cleaned) <= 16


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
    min_speech_duration=0.22,
    min_silence_duration=0.50,
    activation_threshold=0.65,
    max_buffered_speech=15.0,
)
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")


def load_active_config() -> dict:
    default_cfg = {
        "preset": "natural_emel",
        "stt_model": "whisper-large-v3-turbo",
        "llm_model": "openai/gpt-oss-120b",
        "tts_voice": "edge-emel",
        "stt_language": "auto",
        "assistant_mode": "hybrid",
        "owner_language": "tr",
        "work_start": "09:00",
        "work_end": "17:00",
        "assistant_enabled": True,
        "greeting_text": "",
        "architecture": "cascade",
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

    language_for_personality = normalize_language(lang, normalize_language(DEFAULT_LANG))
    lang_rule = personality_rule(language_for_personality)

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
        f"DİL VE KİŞİLİK KURALI: {lang_rule}\n"
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
        "2. RANDEVU VE İPTAL: Randevular yalnız mesai saatleri içinde verilir (`book_calendar_appointment`). İptal için önce arayanın adını ve saatini sorup doğrula (`cancel_calendar_appointment`).\n"
        "3. MESAJ VE NOT: Mesaj bırakmak isteyenden sırasıyla adını (vermek istemezse anonim devam et), ARAMA NEDENİNİ, MESAJINI ve geri aranmak isteyip istemediğini öğren. "
        "Mesajı, nedeni ve geri dönüş isteğini görüşme sonunda aynen tekrar edip açık onay al. Ancak bundan sonra `save_call_note(details_confirmed=True)` aracını çağır. "
        "`summary_tr` alan adı eski uyumluluk içindir: özetin kendisini SAHİP ÖZETİ DİLİNDE yaz. İsimleri, telefon numaralarını, tarihleri ve saatleri değiştirme; olmayan bilgi ekleme.\n"
        "4. KAYIT İZNİ: Arayan kayda izin vermediğini söylerse `recording_consent=False` kullan. Bu durumda mesajın veya arama nedeninin içeriğini kaydetme; yalnızca arayan isterse teyit edilmiş geri arama talebini al.\n"
        "5. ANLAŞILMAYAN BİLGİ: Bir bilgi anlaşılmazsa yavaşça tekrar iste. İkinci başarısız denemede nedeni ve mesajı kısa cümlelerle ayrı ayrı iste. Üçüncü başarısız denemede doğrulanamayan bilgiyi kaydetme; yalnız geri arama talebi teklif et.\n"
        "6. TELEFON NUMARASI: Geri arama isteniyorsa önce sistemde numara olup olmadığını kontrol et. Sistem numarası yoksa arayandan geri dönüş numarasını iste ve `callback_number` alanına yaz. Geri arama istenmiyorsa numara sorma.\n"
        "6. MESAJ Mİ RANDEVU MU: Arayan mevcut bir toplantının saatini değiştirmek istiyorsa bu bir MESAJDIR (telefon sahibi karar verir). Yalnızca arayan açıkça yeni randevu isterse `book_calendar_appointment` çağır. "
        "Randevu oluşturduğunu SÖYLEMEDEN ÖNCE aracı mutlaka çağır ve sonucun 'BAŞARILI' olduğunu gör.\n"
        "7. RANDEVU İPTALİ: İptal için arayanın ADINI ve randevunun TARİHİNİ ve SAATİNİ sor; üçü olmadan `cancel_calendar_appointment` çağırma. "
        "Araç 'BAŞARILI' dönmezse randevuyu iptal edilmiş gibi gösterme ve başka kişilerin randevu bilgilerini asla söyleme.\n"
        "7b. RANDEVU DEĞİŞTİRME: Arayan KENDİ randevusunun saatini değiştirmek isterse önce adı-soyadı, eski tarih ve saati doğrula; yeni saatin müsaitliğini `check_calendar_availability` ile kontrol et; "
        "sonra eski randevuyu `cancel_calendar_appointment` ile iptal et ve yenisini `book_calendar_appointment` ile oluştur. İki işlem de BAŞARILI olmadan değişti deme.\n"
        "'yarın', 'öbür gün', 'gelecek pazartesi' gibi ifadeleri BUGÜN tarihine göre YYYY-MM-DD'ye çevir.\n"
        "8. ACİL DURUM: Acil/hastane/kaza durumunda hemen `save_call_note(is_urgent=True)` çağır. Hayati tehlike varsa, mesaj almaya devam etmeden önce arayanın dilinde 112'yi aramasını söyle."
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
            if isinstance(items, list) and len(items) > 40:
                sys_items = [it for it in items if getattr(it, "role", None) in ("system", "developer")]
                other_items = [it for it in items if getattr(it, "role", None) not in ("system", "developer")]
                if len(other_items) > 30:
                    trimmed = sys_items[:1] + other_items[-30:]
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
            tracker = ClarificationTracker(attempts=int(self.call_state.get("clarification_attempts", 0)))
            prompt, stop_capture = tracker.next_prompt(normalize_language(self.current_lang()))
            self.call_state["clarification_attempts"] = tracker.attempts
            self.call_state["clarification_prompt"] = prompt
            self.call_state["stop_message_capture"] = stop_capture
            print(f"[Filtered Noise] Ignored: {text}", flush=True)
            raise StopResponse()

        self.call_state["clarification_attempts"] = 0
        self.call_state["stop_message_capture"] = False
        if is_life_threatening(text):
            self.call_state["life_threatening"] = True
            guidance = emergency_guidance(normalize_language(self.current_lang()))
            await self.update_instructions(
                build_agent_instructions(self.current_lang(), self.live_schedule, self.active_cfg, greeted_already=True)
                + f"\nACİL YÖNERGE: Arayanın son ifadesi hayatî risk gösterebilir. İlk yanıtın şu olmalı: {guidance}"
            )

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

    @function_tool(description="Çalışma saatleri (09:00-17:00) içinde talep edilen randevuyu Google Takvim'e kaydeder. start_iso formatı: YYYY-MM-DDTHH:MM:00.")
    async def book_calendar_appointment(
        self,
        context: RunContext,
        caller_name: str,
        reason: str,
        start_iso: str,
    ) -> str:
        print(f"[Tool Call] Booking calendar event for {caller_name} at {start_iso}", flush=True)
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
        res = await asyncio.to_thread(
            service_manager.cancel_appointment, date_str, time_hm, caller_name
        )
        if res.startswith("BAŞARILI"):
            self.call_state["appointment_canceled"] = True
            self.call_state["appointment_info"] = f"İPTAL EDİLDİ ({date_str} {time_hm})"
        return res

    @function_tool(description="Telefon sahibine bırakılan mesajı yalnızca arayanın açık teyidinden sonra kaydeder. Arama nedeni, mesaj, geri arama tercihi ve details_confirmed zorunludur. Geri arama istenip sistem numarası yoksa callback_number zorunludur. Kayıt izni yoksa yalnızca teyit edilmiş geri arama talebi saklanabilir.")
    async def save_call_note(
        self,
        context: RunContext,
        caller_name: str = "İsimsiz Arayan",
        caller_purpose: str = "",
        summary_tr: str = "",
        callback_requested: bool | None = None,
        callback_number: str = "",
        details_confirmed: bool = False,
        is_urgent: bool = False,
        recording_consent: bool = True,
    ) -> str:
        print(
            f"[Tool Call] Saving call note for {caller_name} (urgent={is_urgent}, callback={callback_requested}, consent={recording_consent})",
            flush=True,
        )
        owner_lang = normalize_lang(self.active_cfg.get("owner_language"), DEFAULT_LANG)
        safe_name = (caller_name or "").strip()
        if not safe_name or safe_name == "İsimsiz Arayan":
            safe_name = ANONYMOUS[owner_lang]
        system_number = self.call_state.get("caller_number", "")
        effective_callback_number = (callback_number or system_number).strip()
        callback_number_required = bool(callback_requested) and not has_usable_callback_number(effective_callback_number)
        brain_call = CallMessage(
            call_id=self.call_state["call_id"],
            caller_language=normalize_language(self.current_lang()),
            owner_language=normalize_language(owner_lang),
            caller_name=None if safe_name == ANONYMOUS[owner_lang] else safe_name,
            caller_purpose=caller_purpose,
            message=summary_tr,
            callback_requested=callback_requested,
            callback_number=effective_callback_number if has_usable_callback_number(effective_callback_number) else None,
            callback_number_required=callback_number_required,
            recording_consent=bool(recording_consent),
            confirmed=bool(details_confirmed),
            urgency=Urgency.HIGH if is_urgent else Urgency.NORMAL,
        )
        if not recording_consent and not callback_requested:
            return "KAYDEDİLMEDİ: Kayıt izni yok ve geri arama talebi de bulunmuyor."
        validation = validate_call_for_storage(brain_call)
        if not validation.success:
            return f"KAYDEDİLMEDİ: Önce eksik bilgileri tamamla ve arayandan teyit al. ({validation.error_code})"
        if not recording_consent:
            caller_purpose, summary_tr = NO_CONSENT_TEXT[owner_lang]

        self.call_state["caller_name"] = safe_name
        self.call_state["caller_purpose"] = caller_purpose
        self.call_state["is_urgent"] = bool(is_urgent)
        self.call_state["callback_requested"] = bool(callback_requested)
        self.call_state["recording_consent"] = bool(recording_consent)
        self.call_state["callback_number"] = effective_callback_number

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
            caller_number=effective_callback_number or self.call_state.get("caller_number", "VoIP / Web"),
            lang=owner_lang,
            recording_consent=bool(recording_consent),
        )
        self.call_state["note_confirmed"] = True
        self.call_state["final_summary_done"] = True
        return "Mesaj ve görüşme notu başarıyla kaydedildi."



class RealtimeCallAssistant(TurkishCallAssistant):
    """Realtime (Gemini Live): aynı talimatlar ve araçlar; dili model kendisi algılar."""

    async def on_user_turn_completed(self, turn_ctx, new_message) -> None:
        # Realtime modelde sıra ve dil yönetimini model yapar; müdahale etmiyoruz.
        return


async def auto_summarize_on_hangup(transcript_lines: list[str], call_state: dict):
    if call_state.get("final_summary_done") or len(transcript_lines) < 2:
        return
    if not call_state.get("note_confirmed"):
        print("[Auto Summary] Teyit edilmiş mesaj olmadığı için özet kaydedilmedi.", flush=True)
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

    client = AsyncOpenAI(
        base_url="https://api.groq.com/openai/v1",
        api_key=GROQ_API_KEY,
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
                        f"caller_name alanındaki gerçek adı koru; caller_purpose, summary_tr ve calendar_event_title alanlarını {LANG_NAMES_TR[owner_lang].upper()} yaz. "
                        "Yalnızca JSON döndür:\n"
                        '{\n'
                        f'  "caller_name": "Arayanın adı (söylemediyse \'{ANONYMOUS[owner_lang]}\')",\n'
                        '  "caller_purpose": "Arama nedeni (kısa)",\n'
                        '  "summary_tr": "Arayanın mesajının ve görüşmenin net özeti (sahibin dilinde)",\n'
                        '  "is_urgent": false,\n'
                        '  "callback_requested": true,\n'
                        '  "recording_consent": true,\n'
                        '  "calendar_event_iso": "Yalnızca mesai saatleri içinde kesin onaylanmış bir randevu varsa YYYY-MM-DDTHH:MM:00; yoksa boş string \'\'",\n'
                        '  "calendar_event_title": "Takvim için kısa başlık"\n'
                        '}'
                    ),
                },
                {"role": "user", "content": convo_text},
            ],
        )
        data = json.loads(resp.choices[0].message.content)
        caller_name = data.get("caller_name") or call_state.get("caller_name") or ANONYMOUS[owner_lang]
        caller_purpose = data.get("caller_purpose") or call_state.get("caller_purpose") or ""
        summary_tr = data.get("summary_tr") or convo_text
        is_urgent = bool(data.get("is_urgent")) or bool(call_state.get("is_urgent"))
        if any(k in convo_text.lower() for k in URGENT_KEYWORDS):
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

        if (
            cal_iso
            and not call_state.get("appointment_info")
            and not call_state.get("appointment_canceled")
            and recording_consent is not False
        ):
            print(f"[Auto Summary Calendar Sync] Booking planned event at {cal_iso}: {cal_title}", flush=True)
            cal_res = await asyncio.to_thread(
                service_manager.book_appointment, caller_name, cal_title, cal_iso
            )
            if cal_res.startswith("BAŞARILI"):
                call_state["appointment_info"] = f"{cal_iso[:16].replace('T', ' ')} ({cal_title})"

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

    architecture = str(active_cfg.get("architecture", "cascade")).strip().lower()
    if architecture not in ("cascade", "realtime"):
        architecture = "cascade"
    rt_model_name = str(active_cfg.get("realtime_model", "") or "").strip()
    rt_voice = str(active_cfg.get("realtime_voice", "Puck") or "Puck").strip()
    stt_model = active_cfg.get("stt_model", "whisper-large-v3-turbo")
    llm_model = active_cfg.get("llm_model", "openai/gpt-oss-120b")
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
    if architecture == "cascade" and tts_voice in ("edge-emel", "edge-ahmet"):
        asyncio.create_task(GLOBAL_TTS.synthesize_edge_raw(OPENING_GREETING, tts_voice))

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
        "callback_requested": True,
        "recording_consent": True,
        "note_confirmed": False,
        "clarification_attempts": 0,
        "stop_message_capture": False,
        "life_threatening": False,
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
        lang = normalize_lang(iso_lang, DEFAULT_LANG)
        call_state["last_detected_iso"] = lang
        # Arayan dil değiştirmez: ilk anlamlı cümleden sonra STT dilini sabitle
        if not call_state.get("stt_locked") and len((text_val or "").split()) >= 2 and session_stt is not None:
            call_state["stt_locked"] = True
            try:
                session_stt.update_options(language=lang, prompt=PROMPTS_BY_LANG.get(lang, ""))
                print(f"[STT] Dil sabitlendi: {LANG_NAMES_TR[lang]}", flush=True)
            except Exception as e:
                print(f"[STT] Dil sabitlenemedi: {e}", flush=True)

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

        primary_llm = openai.LLM(
            base_url="https://api.groq.com/openai/v1",
            api_key=GROQ_API_KEY,
            model=llm_model,
            temperature=0.2,
        )
        fallback_fast_llm = openai.LLM(
            base_url="https://api.groq.com/openai/v1",
            api_key=GROQ_API_KEY,
            model="openai/gpt-oss-20b" if llm_model != "openai/gpt-oss-20b" else "openai/gpt-oss-120b",
            temperature=0.2,
        )
        fallback_llama_llm = openai.LLM(
            base_url="https://api.groq.com/openai/v1",
            api_key=GROQ_API_KEY,
            model="llama-3.3-70b-versatile",
            temperature=0.2,
        )
        session_llm = llm.FallbackAdapter([primary_llm, fallback_fast_llm, fallback_llama_llm])

        session = AgentSession(
            vad=GLOBAL_VAD,
            stt=session_stt,
            llm=session_llm,
            tts=GLOBAL_TTS,
            preemptive_generation=False,
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
