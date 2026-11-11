"""Dil normalleştirme ve kısa karşılama metinleri."""

from __future__ import annotations

from .models import Language

_ALIASES = {
    "tr": Language.TURKISH, "tur": Language.TURKISH, "turkish": Language.TURKISH, "türkçe": Language.TURKISH,
    "en": Language.ENGLISH, "eng": Language.ENGLISH, "english": Language.ENGLISH,
    "ar": Language.ARABIC, "ara": Language.ARABIC, "arabic": Language.ARABIC, "العربية": Language.ARABIC,
}


def normalize_language(value: str | None, fallback: Language = Language.TURKISH) -> Language:
    if not value:
        return fallback
    normalized = value.strip().casefold().replace("_", "-")
    return _ALIASES.get(normalized, _ALIASES.get(normalized.split("-", 1)[0], fallback))


def greeting(language: Language) -> str:
    return {
        Language.TURKISH: "Merhaba, ben yapay zekâ asistanıyım. Şu an uygun değil. Mesajınızı alabilirim.",
        Language.ENGLISH: "Hello, I am the AI assistant. The owner is unavailable right now. I can take a message.",
        Language.ARABIC: "مرحبًا، أنا المساعد الذكي. صاحب الهاتف غير متاح الآن، ويمكنني تدوين رسالتك.",
    }[language]
