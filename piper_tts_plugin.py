import asyncio
import io
import json
import os
import re
import time
import uuid
import aiohttp
import edge_tts
import miniaudio
from pathlib import Path
from openai import AsyncOpenAI
from piper.voice import PiperVoice
from livekit import rtc
from livekit.agents import stt, tts, utils, APIConnectOptions, DEFAULT_API_CONNECT_OPTIONS
import speech_recognition as sr

CONFIG_FILE = Path(__file__).parent / "agent_config.json"

ACTIVE_CALL_LANG = "tr"


def set_active_call_lang(lang_code: str) -> None:
    global ACTIVE_CALL_LANG
    if lang_code and lang_code != "auto":
        ACTIVE_CALL_LANG = lang_code.lower()[:2]


WHISPER_LANG_TO_ISO = {
    "turkish": "tr", "arabic": "ar", "english": "en", "german": "de", "french": "fr",
    "spanish": "es", "italian": "it", "russian": "ru", "kazakh": "kk", "portuguese": "pt",
    "dutch": "nl", "polish": "pl", "ukrainian": "uk", "greek": "el", "persian": "fa",
    "urdu": "ur", "hindi": "hi", "bengali": "bn", "indonesian": "id", "malay": "ms",
    "vietnamese": "vi", "thai": "th", "chinese": "zh", "japanese": "ja", "korean": "ko",
    "swedish": "sv", "norwegian": "no", "danish": "da", "finnish": "fi", "czech": "cs",
    "romanian": "ro", "hungarian": "hu", "bulgarian": "bg", "serbian": "sr", "croatian": "hr",
    "slovak": "sk", "azerbaijani": "az", "uzbek": "uz", "georgian": "ka", "armenian": "hy",
    "albanian": "sq", "bosnian": "bs", "catalan": "ca", "estonian": "et", "latvian": "lv",
    "lithuanian": "lt", "macedonian": "mk", "slovenian": "sl", "tagalog": "tl", "swahili": "sw",
    "afrikaans": "af", "amharic": "am", "nepali": "ne", "sinhala": "si", "tamil": "ta",
    "telugu": "te", "kannada": "kn", "malayalam": "ml", "marathi": "mr", "gujarati": "gu",
}

MULTILINGUAL_EDGE_VOICES: dict[str, dict[str, str]] = {
    "tr": {"female": "tr-TR-EmelNeural", "male": "tr-TR-AhmetNeural"},
    "ar": {"female": "ar-SA-ZariyahNeural", "male": "ar-SA-HamedNeural"},
    "en": {"female": "en-US-AriaNeural", "male": "en-US-GuyNeural"},
    "ru": {"female": "ru-RU-SvetlanaNeural", "male": "ru-RU-DmitryNeural"},
    "kk": {"female": "kk-KZ-AigulNeural", "male": "kk-KZ-DauletNeural"},
    "de": {"female": "de-DE-KatjaNeural", "male": "de-DE-ConradNeural"},
    "fr": {"female": "fr-FR-DeniseNeural", "male": "fr-FR-HenriNeural"},
    "es": {"female": "es-ES-ElviraNeural", "male": "es-ES-AlvaroNeural"},
    "it": {"female": "it-IT-ElsaNeural", "male": "it-IT-DiegoNeural"},
    "pt": {"female": "pt-BR-FranciscaNeural", "male": "pt-BR-AntonioNeural"},
    "nl": {"female": "nl-NL-ColetteNeural", "male": "nl-NL-MaartenNeural"},
    "pl": {"female": "pl-PL-ZofiaNeural", "male": "pl-PL-MarekNeural"},
    "uk": {"female": "uk-UA-PolinaNeural", "male": "uk-UA-OstapNeural"},
    "el": {"female": "el-GR-AthinaNeural", "male": "el-GR-NestorasNeural"},
    "fa": {"female": "fa-IR-DilaraNeural", "male": "fa-IR-FaridNeural"},
    "ur": {"female": "ur-PK-UzmaNeural", "male": "ur-PK-AsadNeural"},
    "hi": {"female": "hi-IN-SwaraNeural", "male": "hi-IN-MadhurNeural"},
    "id": {"female": "id-ID-GadisNeural", "male": "id-ID-ArdiNeural"},
    "ms": {"female": "ms-MY-YasminNeural", "male": "ms-MY-OsmanNeural"},
    "vi": {"female": "vi-VN-HoaiMyNeural", "male": "vi-VN-NamMinhNeural"},
    "th": {"female": "th-TH-PremwadeeNeural", "male": "th-TH-NiwatNeural"},
    "zh": {"female": "zh-CN-XiaoxiaoNeural", "male": "zh-CN-YunxiNeural"},
    "ja": {"female": "ja-JP-NanamiNeural", "male": "ja-JP-KeitaNeural"},
    "ko": {"female": "ko-KR-SunHiNeural", "male": "ko-KR-InJoonNeural"},
    "sv": {"female": "sv-SE-SofieNeural", "male": "sv-SE-MattiasNeural"},
    "ro": {"female": "ro-RO-AlinaNeural", "male": "ro-RO-EmilNeural"},
    "az": {"female": "az-AZ-BanuNeural", "male": "az-AZ-BabekNeural"},
    "uz": {"female": "uz-UZ-MadinaNeural", "male": "uz-UZ-SardorNeural"},
}

_ALL_VOICES_LOADED = False


async def ensure_all_75_edge_voices() -> None:
    global _ALL_VOICES_LOADED
    if _ALL_VOICES_LOADED:
        return
    _ALL_VOICES_LOADED = True
    try:
        voices = await edge_tts.list_voices()
        for v in voices:
            locale = v.get("Locale", "")
            short_name = v.get("ShortName", "")
            gender = v.get("Gender", "").lower()
            lang_code = locale.split("-")[0].lower()
            if not lang_code or not short_name:
                continue
            if lang_code not in MULTILINGUAL_EDGE_VOICES:
                MULTILINGUAL_EDGE_VOICES[lang_code] = {"female": short_name, "male": short_name}
            else:
                if gender == "female" and MULTILINGUAL_EDGE_VOICES[lang_code].get("female") == MULTILINGUAL_EDGE_VOICES[lang_code].get("male"):
                    MULTILINGUAL_EDGE_VOICES[lang_code]["female"] = short_name
                elif gender == "male" and MULTILINGUAL_EDGE_VOICES[lang_code].get("male") == MULTILINGUAL_EDGE_VOICES[lang_code].get("female"):
                    MULTILINGUAL_EDGE_VOICES[lang_code]["male"] = short_name
    except Exception:
        pass


ARABIC_HOUR_WORDS = {
    1: "الواحدة", 2: "الثانية", 3: "الثالثة", 4: "الرابعة",
    5: "الخامسة", 6: "السادسة", 7: "السابعة", 8: "الثامنة",
    9: "التاسعة", 10: "العاشرة", 11: "الحادية عشرة", 12: "الثانية عشرة",
}

TURKISH_HOUR_WORDS = {
    1: "bir", 2: "iki", 3: "üç", 4: "dört", 5: "beş", 6: "altı",
    7: "yedi", 8: "sekiz", 9: "dokuz", 10: "on", 11: "on bir", 12: "on iki",
}

ENGLISH_HOUR_WORDS = {
    1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six",
    7: "seven", 8: "eight", 9: "nine", 10: "ten", 11: "eleven", 12: "twelve",
}

RUSSIAN_HOUR_WORDS = {
    1: "час", 2: "два часа", 3: "три часа", 4: "четыре часа",
    5: "пять часов", 6: "шесть часов", 7: "семь часов", 8: "восемь часов",
    9: "девять часов", 10: "десять часов", 11: "одиннадцать часов", 12: "двенадцать часов",
}

KAZAKH_HOUR_WORDS = {
    1: "бір", 2: "екі", 3: "үш", 4: "төрт", 5: "бес", 6: "алты",
    7: "жеті", 8: "сегіз", 9: "тоғыз", 10: "он", 11: "он бір", 12: "он екі",
}


def format_single_time_spoken(hour: int, minute: int, lang: str) -> str:
    h12 = hour % 12
    if h12 == 0:
        h12 = 12
    is_morning = hour < 12

    if lang == "ar":
        h_word = ARABIC_HOUR_WORDS.get(h12, str(h12))
        period = "صباحاً" if is_morning else "مساءً"
        if minute == 0:
            return f"{h_word} {period}"
        if minute == 30:
            return f"{h_word} والنصف {period}"
        if minute == 15:
            return f"{h_word} والربع {period}"
        if minute == 45:
            return f"{h_word} إلا ربع {period}"
        return f"{h_word} و{minute} دقيقة {period}"

    if lang == "tr":
        h_word = TURKISH_HOUR_WORDS.get(h12, str(h12))
        period = "sabah" if is_morning else ("öğleden sonra" if hour < 17 else "akşam")
        if minute == 0:
            return f"{period} saat {h_word}"
        if minute == 30:
            return f"{period} saat {h_word} buçuk"
        return f"{period} saat {h_word} {minute}"

    if lang == "ru":
        h_word = RUSSIAN_HOUR_WORDS.get(h12, str(h12))
        period = "утра" if is_morning else ("дня" if hour < 17 else "вечера")
        if minute == 0:
            return f"{h_word} {period}"
        if minute == 30:
            return f"{h_word} тридцать минут {period}"
        return f"{h_word} {minute} минут {period}"

    if lang == "kk":
        h_word = KAZAKH_HOUR_WORDS.get(h12, str(h12))
        period = "таңғы" if is_morning else ("күндізгі" if hour < 17 else "кешкі")
        if minute == 0:
            return f"{period} сағат {h_word}"
        if minute == 30:
            return f"{period} сағат {h_word} жарым"
        return f"{period} сағат {h_word} {minute}"

    h_word = ENGLISH_HOUR_WORDS.get(h12, str(h12))
    period = "in the morning" if is_morning else ("in the afternoon" if hour < 17 else "in the evening")
    if minute == 0:
        return f"{h_word} {period}"
    if minute == 30:
        return f"{h_word} thirty {period}"
    return f"{h_word} {minute} {period}"


def humanize_times_for_tts(text: str, lang: str) -> str:
    cleaned = re.sub(r"\(\s*\d{4}[-‑–]\d{2}[-‑–]\d{2}\s*\)", "", text)
    cleaned = re.sub(r"\b\d{4}[-‑–]\d{2}[-‑–]\d{2}\b", "", cleaned)

    def _replace_time(match: re.Match) -> str:
        try:
            hr = int(match.group(1))
            mn = int(match.group(2))
            if 0 <= hr <= 23 and 0 <= mn <= 59:
                return format_single_time_spoken(hr, mn, lang)
        except Exception:
            pass
        return match.group(0)

    cleaned = re.sub(r"\b(\d{1,2})\s*[:.]\s*(\d{2})\b", _replace_time, cleaned)
    return cleaned


TURKISH_COMMON_WORDS = {
    "merhaba", "evet", "hayır", "tamam", "meryem", "randevu", "müsait", "değil",
    "saat", "mesaj", "not", "teşekkür", "iyi", "günler", "nasıl", "yardımcı",
    "olabilirim", "adınız", "nedir", "lütfen", "yarın", "bugün", "geri", "arama",
    "türkçe", "için", "basın", "veya", "konuşabilirsiniz",
}

ENGLISH_COMMON_WORDS = {
    "hello", "hi", "the", "is", "are", "you", "can", "please", "appointment",
    "message", "call", "available", "busy", "today", "tomorrow", "thank", "name",
    "how", "help", "would", "like", "leave", "note", "sorry", "currently",
    "for", "english", "press", "speak", "language",
}

GERMAN_COMMON_WORDS = {
    "hallo", "guten", "ich", "sie", "ist", "nicht", "termin", "nachricht",
    "bitte", "danke", "heute", "morgen", "uhr", "kann", "wie", "helfen",
}

FRENCH_COMMON_WORDS = {
    "bonjour", "salut", "je", "vous", "est", "pas", "disponible", "message",
    "merci", "rendez", "vous", "demain", "aujourd", "comment", "aider",
}

SPANISH_COMMON_WORDS = {
    "hola", "buenos", "como", "esta", "cita", "mensaje", "por", "favor",
    "gracias", "hoy", "manana", "disponible", "puedo", "ayudar",
}

ITALIAN_COMMON_WORDS = {
    "ciao", "buongiorno", "sono", "non", "disponibile", "appuntamento",
    "messaggio", "grazie", "come", "posso", "aiutarti", "oggi", "domani",
}


def detect_text_language(text: str) -> str:
    m = re.match(r"^\s*\[LANG:([a-z]{2,3})\]", text, flags=re.IGNORECASE)
    if m:
        return m.group(1).lower()[:2]

    if re.search(r"[\u0600-\u06FF]", text):
        return "ar"
    if re.search(r"[әӘғҒқҚңҢөӨұҰүҮһҺіІ]", text):
        return "kk"
    if re.search(r"[\u0400-\u04FF]", text):
        if ACTIVE_CALL_LANG == "kk":
            return "kk"
        return "ru"
    if re.search(r"[\u0370-\u03FF]", text):
        return "el"
    if re.search(r"[\u3040-\u30FF]", text):
        return "ja"
    if re.search(r"[\uAC00-\uD7AF]", text):
        return "ko"
    if re.search(r"[\u4E00-\u9FFF]", text):
        return "zh"
    if re.search(r"[\u0900-\u097F]", text):
        return "hi"
    if re.search(r"[\u0E00-\u0E7F]", text):
        return "th"
    if re.search(r"[ğĞşŞıİ]", text):
        return "tr"

    words = set(re.findall(r"[a-zA-ZçğıöşüÇĞİÖŞÜäßéèêàùñòì]+", text.lower()))
    if words & TURKISH_COMMON_WORDS:
        return "tr"
    if words & ENGLISH_COMMON_WORDS:
        return "en"
    if words & GERMAN_COMMON_WORDS:
        return "de"
    if words & FRENCH_COMMON_WORDS:
        return "fr"
    if words & SPANISH_COMMON_WORDS:
        return "es"
    if words & ITALIAN_COMMON_WORDS:
        return "it"
    if ACTIVE_CALL_LANG and ACTIVE_CALL_LANG != "auto":
        return ACTIVE_CALL_LANG
    if re.search(r"[çÇöÖüÜ]", text):
        return "tr"
    return "tr"


def get_active_tts_mode() -> str:
    if CONFIG_FILE.exists():
        try:
            data = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
            return data.get("tts_voice", "edge-emel")
        except Exception:
            pass
    return "edge-emel"


def clean_turkish_tts_text(text: str) -> str:
    cleaned = re.sub(r"<think>.*?</think>", "", text, flags=re.DOTALL)
    cleaned = re.sub(r"^\s*\[LANG:[a-zA-Z\-]+\]\s*", "", cleaned)
    cleaned = (
        cleaned.replace("\u00a0", " ")
        .replace("\u202f", " ")
        .replace("\u200f", " ")
        .replace("\u200e", " ")
        .replace("\u2011", "-")
        .replace("\u2013", " ")
        .replace("\u2014", " ")
        .replace("\u2026", ".")
    )
    cleaned = re.sub(r"\(\s*[A-Za-z]\s*\)", "", cleaned)
    cleaned = cleaned.replace("*", "").replace("#", "").replace("•", " ")
    cleaned = re.sub(r"(^|\s)-\s+", " ", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned.strip()


class PiperTTS(tts.TTS):
    def __init__(self, model_path: str | Path) -> None:
        self.model_path = Path(model_path)
        if not self.model_path.exists():
            raise FileNotFoundError(f"Piper model not found at {self.model_path}")

        self.voice = PiperVoice.load(str(self.model_path))
        sample_rate = self.voice.config.sample_rate
        self._lock = asyncio.Lock()
        self._cache: dict[str, bytes] = {}

        super().__init__(
            capabilities=tts.TTSCapabilities(streaming=False),
            sample_rate=sample_rate,
            num_channels=1,
        )

    def synthesize_raw(self, text: str) -> bytes:
        key = humanize_times_for_tts(clean_turkish_tts_text(text).replace("|", " "), "tr")
        if not key or not re.search(r"\w", key):
            return b"\x00\x00" * 800
        cache_key = f"piper-dfki::{key}"
        if cache_key in self._cache:
            return self._cache[cache_key]
        chunks = []
        for chunk in self.voice.synthesize(key):
            chunks.append(chunk.audio_int16_bytes)
        pause = b"\x00\x00" * int(self.sample_rate * 0.10)
        chunks.append(pause)
        data = b"".join(chunks)
        if len(self._cache) < 256:
            self._cache[cache_key] = data
        return data

    async def _synthesize_single_edge_segment(self, segment_text: str, voice_id: str) -> bytes:
        await ensure_all_75_edge_voices()
        raw_seg = segment_text.strip()
        if not raw_seg:
            return b""
        lang = detect_text_language(raw_seg)
        seg = humanize_times_for_tts(clean_turkish_tts_text(raw_seg), lang)
        if not seg or not re.search(r"[\w\u0600-\u06FF\u0400-\u04FF]", seg):
            return b""
        gender = "male" if voice_id == "edge-ahmet" else "female"
        voice_pair = MULTILINGUAL_EDGE_VOICES.get(lang, MULTILINGUAL_EDGE_VOICES["tr"])
        edge_voice_name = voice_pair.get(gender) or voice_pair.get("female") or "tr-TR-EmelNeural"
        seg_cache_key = f"{edge_voice_name}::{seg}"
        if seg_cache_key in self._cache:
            return self._cache[seg_cache_key]

        try:
            comm = edge_tts.Communicate(seg, edge_voice_name, rate="+0%")
            mp3_chunks = []
            async for chunk in comm.stream():
                if chunk["type"] == "audio":
                    mp3_chunks.append(chunk["data"])
            raw_mp3 = b"".join(mp3_chunks)
        except Exception:
            raw_mp3 = b""

        if not raw_mp3:
            return await self._synthesize_single_google_segment(f"[LANG:{lang}] {seg}")

        decoded = await asyncio.to_thread(
            miniaudio.decode,
            raw_mp3,
            output_format=miniaudio.SampleFormat.SIGNED16,
            nchannels=1,
            sample_rate=self.sample_rate,
        )
        pause = b"\x00\x00" * int(self.sample_rate * 0.14)
        pcm_data = decoded.samples.tobytes() + pause
        if len(self._cache) < 256:
            self._cache[seg_cache_key] = pcm_data
        return pcm_data

    async def _synthesize_single_elevenlabs_segment(self, segment_text: str) -> bytes:
        """ElevenLabs REST TTS. Anahtar ve ses kimligi .env dosyasindan okunur."""
        api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
        voice_id = os.getenv("ELEVENLABS_VOICE_ID", "").strip()
        model_id = os.getenv("ELEVENLABS_MODEL", "eleven_flash_v2_5").strip() or "eleven_flash_v2_5"
        if not api_key or not voice_id:
            raise RuntimeError("ELEVENLABS_API_KEY veya ELEVENLABS_VOICE_ID tanimli degil")
        raw_seg = segment_text.strip()
        if not raw_seg:
            return b""
        lang = detect_text_language(raw_seg)
        seg = humanize_times_for_tts(clean_turkish_tts_text(raw_seg), lang)
        if not seg or not re.search(r"[\w\u0600-\u06FF\u0400-\u04FF]", seg):
            return b""
        cache_key = f"eleven::{voice_id}::{model_id}::{seg}"
        if cache_key in self._cache:
            return self._cache[cache_key]

        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128"
        headers = {"xi-api-key": api_key, "Content-Type": "application/json", "Accept": "audio/mpeg"}
        payload = {"text": seg, "model_id": model_id}
        timeout = aiohttp.ClientTimeout(total=20)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            async with session.post(url, json=payload, headers=headers) as resp:
                if resp.status != 200:
                    body = (await resp.text())[:200]
                    raise RuntimeError(f"ElevenLabs HTTP {resp.status}: {body}")
                raw_mp3 = await resp.read()
        if not raw_mp3:
            raise RuntimeError("ElevenLabs bos ses dondurdu")

        decoded = await asyncio.to_thread(
            miniaudio.decode,
            raw_mp3,
            output_format=miniaudio.SampleFormat.SIGNED16,
            nchannels=1,
            sample_rate=self.sample_rate,
        )
        pause = b"\x00\x00" * int(self.sample_rate * 0.14)
        pcm_data = decoded.samples.tobytes() + pause
        if len(self._cache) < 256:
            self._cache[cache_key] = pcm_data
        return pcm_data

    async def synthesize_elevenlabs_raw(self, text: str) -> bytes:
        if not text or not text.strip():
            return b"\x00\x00" * 800
        segments = [s.strip() for s in text.split("|") if s.strip()]
        pcm_parts = []
        for seg in segments:
            part = await self._synthesize_single_elevenlabs_segment(seg)
            if part:
                pcm_parts.append(part)
        data = b"".join(pcm_parts)
        return data if data else b"\x00\x00" * 800

    async def synthesize_edge_raw(self, text: str, voice_id: str) -> bytes:
        if not text or not text.strip():
            return b"\x00\x00" * 800
        full_cache_key = f"edge-multi-{voice_id}-{ACTIVE_CALL_LANG}::{text.strip()}"
        if full_cache_key in self._cache:
            return self._cache[full_cache_key]

        segments = [s.strip() for s in text.split("|") if s.strip()]
        pcm_parts = []
        for seg in segments:
            part = await self._synthesize_single_edge_segment(seg, voice_id)
            if part:
                pcm_parts.append(part)
        data = b"".join(pcm_parts)
        if not data:
            return b"\x00\x00" * 800
        if len(self._cache) < 256:
            self._cache[full_cache_key] = data
        return data

    async def _synthesize_single_google_segment(self, segment_text: str) -> bytes:
        raw_seg = segment_text.strip()
        if not raw_seg:
            return b""
        lang = detect_text_language(raw_seg)
        seg = humanize_times_for_tts(clean_turkish_tts_text(raw_seg), lang)
        if not seg or not re.search(r"[\w\u0600-\u06FF\u0400-\u04FF]", seg):
            return b""
        gtts_lang = "ru" if lang == "kk" else lang
        seg_cache_key = f"google-tts-{gtts_lang}::{seg}"
        if seg_cache_key in self._cache:
            return self._cache[seg_cache_key]

        def _make_gtts_mp3(txt: str, language_code: str) -> bytes:
            from gtts import gTTS
            buf = io.BytesIO()
            try:
                gTTS(text=txt, lang=language_code, slow=False).write_to_fp(buf)
            except Exception:
                gTTS(text=txt, lang="en", slow=False).write_to_fp(buf)
            return buf.getvalue()

        try:
            raw_mp3 = await asyncio.to_thread(_make_gtts_mp3, seg, gtts_lang)
        except Exception:
            raw_mp3 = b""

        if not raw_mp3:
            if lang == "tr":
                return await asyncio.to_thread(self.synthesize_raw, seg)
            return b"\x00\x00" * 800

        decoded = await asyncio.to_thread(
            miniaudio.decode,
            raw_mp3,
            output_format=miniaudio.SampleFormat.SIGNED16,
            nchannels=1,
            sample_rate=self.sample_rate,
        )
        pause = b"\x00\x00" * int(self.sample_rate * 0.14)
        pcm_data = decoded.samples.tobytes() + pause
        if len(self._cache) < 256:
            self._cache[seg_cache_key] = pcm_data
        return pcm_data

    async def synthesize_google_raw(self, text: str) -> bytes:
        if not text or not text.strip():
            return b"\x00\x00" * 800
        full_cache_key = f"google-multi-{ACTIVE_CALL_LANG}::{text.strip()}"
        if full_cache_key in self._cache:
            return self._cache[full_cache_key]

        segments = [s.strip() for s in text.split("|") if s.strip()]
        pcm_parts = []
        for seg in segments:
            part = await self._synthesize_single_google_segment(seg)
            if part:
                pcm_parts.append(part)
        data = b"".join(pcm_parts)
        if not data:
            return b"\x00\x00" * 800
        if len(self._cache) < 256:
            self._cache[full_cache_key] = data
        return data

    def prewarm(self, sentences: list[str] | None = None) -> None:
        if not sentences:
            return
        for s in sentences:
            self.synthesize_raw(s)

    def synthesize(
        self, text: str, *, conn_options: APIConnectOptions = DEFAULT_API_CONNECT_OPTIONS
    ) -> tts.ChunkedStream:
        return PiperChunkedStream(tts=self, input_text=text, conn_options=conn_options)


class PiperChunkedStream(tts.ChunkedStream):
    def __init__(
        self, *, tts: PiperTTS, input_text: str, conn_options: APIConnectOptions
    ) -> None:
        super().__init__(tts=tts, input_text=input_text, conn_options=conn_options)
        self._piper_tts = tts

    async def _run(self, output_emitter: tts.AudioEmitter) -> None:
        request_id = str(uuid.uuid4())
        output_emitter.initialize(
            request_id=request_id,
            sample_rate=self._piper_tts.sample_rate,
            num_channels=1,
            mime_type="audio/pcm",
        )

        t0 = time.perf_counter()
        raw_input = self.input_text
        detected_lang = "multi" if "|" in raw_input else detect_text_language(raw_input)
        key = humanize_times_for_tts(clean_turkish_tts_text(raw_input), detected_lang if detected_lang != "multi" else "tr")
        mode = get_active_tts_mode()

        if not key or not re.search(r"[\w\u0600-\u06FF\u0400-\u04FF]", key):
            output_emitter.push(b"\x00\x00" * 400)
            output_emitter.flush()
            return

        is_eleven_ar = mode.startswith("elevenlabs-ar")
        use_eleven = mode == "elevenlabs" or (is_eleven_ar and detected_lang == "ar")
        edge_fallback = "edge-ahmet" if mode.endswith("ahmet") else "edge-emel"
        if use_eleven:
            try:
                pcm_bytes = await self._piper_tts.synthesize_elevenlabs_raw(raw_input)
            except Exception as e:
                print(f"[TTS Fallback] ElevenLabs hatasi ({e}); Edge TTS kullaniliyor", flush=True)
                pcm_bytes = await self._piper_tts.synthesize_edge_raw(raw_input, edge_fallback)
        elif mode in ("edge-emel", "edge-ahmet") or is_eleven_ar or (mode == "piper-dfki" and detected_lang != "tr"):
            try:
                pcm_bytes = await self._piper_tts.synthesize_edge_raw(raw_input, mode if mode in ("edge-emel", "edge-ahmet") else edge_fallback)
            except Exception as e:
                print(f"[TTS Fallback] Edge TTS error ({e}), using Google TTS fallback", flush=True)
                pcm_bytes = await self._piper_tts.synthesize_google_raw(raw_input)
        elif mode == "google-tts":
            try:
                pcm_bytes = await self._piper_tts.synthesize_google_raw(raw_input)
            except Exception as e:
                print(f"[TTS Fallback] Google TTS error ({e})", flush=True)
                pcm_bytes = b"\x00\x00" * 800
        else:
            async with self._piper_tts._lock:
                pcm_bytes = await asyncio.to_thread(self._piper_tts.synthesize_raw, key)

        elapsed_ms = int((time.perf_counter() - t0) * 1000)
        print(
            f"[Cascade TTS Metric] Voice={mode} | Lang={detected_lang} | Synthesis={elapsed_ms}ms | Text='{key[:65]}'",
            flush=True,
        )

        chunk_size = 4410 * 2
        for i in range(0, len(pcm_bytes), chunk_size):
            output_emitter.push(pcm_bytes[i : i + chunk_size])

        output_emitter.flush()


class GroqMultilingualSTT(stt.STT):
    def __init__(
        self,
        *,
        model: str = "whisper-large-v3",
        api_key: str = "",
        language: str = "auto",
        prompt: str = "",
        on_language_detected=None,
        allowed_langs: tuple = ("tr", "ar", "en"),
        fallback_lang: str = "tr",
    ) -> None:
        super().__init__(
            capabilities=stt.STTCapabilities(streaming=False, interim_results=False)
        )
        self._allowed_langs = tuple(allowed_langs)
        self._fallback_lang = fallback_lang
        self._model = model if model in ("whisper-large-v3", "whisper-large-v3-turbo") else "whisper-large-v3"
        self._language = language
        self._prompt = prompt
        self._on_language_detected = on_language_detected
        self._client = AsyncOpenAI(
            base_url="https://api.groq.com/openai/v1",
            api_key=api_key or os.getenv("GROQ_API_KEY", ""),
        )

    def update_options(
        self,
        *,
        language: str | None = None,
        detect_language: bool | None = None,
        prompt: str | None = None,
        **kwargs,
    ) -> None:
        if detect_language is True:
            self._language = "auto"
        elif language:
            self._language = language
            set_active_call_lang(language)
        if prompt is not None:
            self._prompt = prompt

    async def _recognize_impl(
        self,
        buffer: utils.AudioBuffer,
        *,
        language: str | None = None,
        conn_options: APIConnectOptions = DEFAULT_API_CONNECT_OPTIONS,
    ) -> stt.SpeechEvent:
        t0 = time.perf_counter()
        combined = rtc.combine_audio_frames(buffer)
        duration_sec = combined.samples_per_channel / float(combined.sample_rate or 16000)
        if duration_sec < 0.35:
            return stt.SpeechEvent(
                type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                alternatives=[stt.SpeechData(language="tr", text="", confidence=0.0)],
            )

        wav_bytes = combined.to_wav_bytes()
        req_kwargs: dict = {
            "file": ("speech.wav", wav_bytes, "audio/wav"),
            "model": self._model,
            "response_format": "verbose_json",
            "temperature": 0.0,
        }
        if self._language and self._language != "auto":
            req_kwargs["language"] = self._language
            if self._prompt:
                req_kwargs["prompt"] = self._prompt

        try:
            resp = await self._client.audio.transcriptions.create(**req_kwargs)
            raw_text = (getattr(resp, "text", "") or "").strip()
            raw_lang = (getattr(resp, "language", "") or "").strip().lower()
            segments = getattr(resp, "segments", None) or []

            if segments:
                first_seg = segments[0] if isinstance(segments[0], dict) else segments[0].__dict__
                no_speech_prob = float(first_seg.get("no_speech_prob", 0.0) or 0.0)
                avg_logprob = float(first_seg.get("avg_logprob", 0.0) or 0.0)
                if no_speech_prob > 0.62 or avg_logprob < -0.92:
                    print(
                        f"[Whisper Confidence Filter] Ignored noise (no_speech={no_speech_prob:.2f}, logprob={avg_logprob:.2f}): '{raw_text}'",
                        flush=True,
                    )
                    return stt.SpeechEvent(
                        type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                        alternatives=[stt.SpeechData(language="tr", text="", confidence=0.0)],
                    )

            iso_lang = WHISPER_LANG_TO_ISO.get(raw_lang, raw_lang[:2] if len(raw_lang) >= 2 else "tr")
            if self._language and self._language != "auto":
                iso_lang = self._language
            elif self._allowed_langs and iso_lang not in self._allowed_langs and raw_text:
                # Desteklenmeyen dil algılandı (ör. İzlandaca): varsayılan dille yeniden çöz
                print(f"[STT] '{raw_lang}' algılandı, desteklenmiyor -> {self._fallback_lang} ile yeniden deneniyor", flush=True)
                retry_kwargs = dict(req_kwargs)
                retry_kwargs["language"] = self._fallback_lang
                resp = await self._client.audio.transcriptions.create(**retry_kwargs)
                raw_text = (getattr(resp, "text", "") or "").strip()
                iso_lang = self._fallback_lang

            if raw_text:
                set_active_call_lang(iso_lang)
                if self._on_language_detected:
                    try:
                        self._on_language_detected(iso_lang, raw_text)
                    except Exception:
                        pass

            elapsed_ms = int((time.perf_counter() - t0) * 1000)
            print(
                f"[Cascade STT Metric] Model={self._model} | DetectedLang={iso_lang} ({raw_lang}) | {elapsed_ms}ms | Text='{raw_text}'",
                flush=True,
            )
            return stt.SpeechEvent(
                type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                alternatives=[
                    stt.SpeechData(
                        language=iso_lang,
                        text=raw_text,
                        confidence=0.95 if raw_text else 0.0,
                    )
                ],
            )
        except Exception as e:
            print(f"[GroqMultilingualSTT Error] {e}", flush=True)
            return stt.SpeechEvent(
                type=stt.SpeechEventType.FINAL_TRANSCRIPT,
                alternatives=[stt.SpeechData(language="tr", text="", confidence=0.0)],
            )


class GoogleFreeSTT(stt.STT):
    def __init__(self, language: str = "tr-TR") -> None:
        super().__init__(
            capabilities=stt.STTCapabilities(streaming=False, interim_results=False)
        )
        self._language = language
        self._recognizer = sr.Recognizer()

    def update_options(self, *, language: str | None = None, **kwargs) -> None:
        if language and language != "auto":
            lang_map = {
                "tr": "tr-TR", "ar": "ar-SA", "en": "en-US", "ru": "ru-RU",
                "kk": "kk-KZ", "de": "de-DE", "fr": "fr-FR", "es": "es-ES", "it": "it-IT",
            }
            self._language = lang_map.get(language, language)
            set_active_call_lang(language)

    async def _recognize_impl(
        self,
        buffer: utils.AudioBuffer,
        *,
        language: str | None = None,
        conn_options: APIConnectOptions = DEFAULT_API_CONNECT_OPTIONS,
    ) -> stt.SpeechEvent:
        t0 = time.perf_counter()
        merged = utils.merge_frames(buffer)
        raw_bytes = bytes(merged.data)
        sample_rate = merged.sample_rate

        def _run_google_sr() -> str:
            audio_data = sr.AudioData(raw_bytes, sample_rate, 2)
            try:
                return self._recognizer.recognize_google(audio_data, language=self._language)
            except sr.UnknownValueError:
                return ""
            except Exception as e:
                print(f"[Google STT Warning] {e}", flush=True)
                return ""

        text = await asyncio.to_thread(_run_google_sr)
        elapsed_ms = int((time.perf_counter() - t0) * 1000)
        print(f"[Cascade STT Metric] Engine=google-stt | Lang={self._language} | Recognition={elapsed_ms}ms | Text='{text}'", flush=True)
        return stt.SpeechEvent(
            type=stt.SpeechEventType.FINAL_TRANSCRIPT,
            alternatives=[
                stt.SpeechData(
                    language=self._language[:2],
                    text=text,
                    confidence=0.95 if text else 0.0,
                )
            ],
        )
