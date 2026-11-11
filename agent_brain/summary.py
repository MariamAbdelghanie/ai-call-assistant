"""Sahibe gönderilecek, dil farkını açıkça yöneten çağrı özeti."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from .models import CallMessage, Language


@dataclass(frozen=True)
class OwnerSummary:
    call_id: str
    language: Language
    text: str
    callback_requested: bool
    urgency: str


def build_owner_summary(call: CallMessage, translated_message: Optional[str] = None) -> OwnerSummary:
    if not call.message:
        raise ValueError("Özet için bir mesaj gereklidir.")
    if call.caller_language is not call.owner_language and not translated_message:
        raise ValueError("Farklı diller için doğrulanmış translated_message gereklidir.")
    message = translated_message.strip() if translated_message else call.message.strip()
    name = call.caller_name or _anonymous_label(call.owner_language)
    callback = bool(call.callback_requested)
    return OwnerSummary(call.call_id, call.owner_language, _render(call.owner_language, name, message, callback),
                        callback, call.urgency.value)


def _anonymous_label(language: Language) -> str:
    return {Language.TURKISH: "İsmini paylaşmayan bir arayan", Language.ENGLISH: "An unnamed caller",
            Language.ARABIC: "متصل لم يذكر اسمه"}[language]


def _render(language: Language, name: str, message: str, callback: bool) -> str:
    callback_text = {
        Language.TURKISH: "Geri dönüş istiyor." if callback else "Geri dönüş istemiyor.",
        Language.ENGLISH: "A callback was requested." if callback else "No callback was requested.",
        Language.ARABIC: "طلب معاودة الاتصال." if callback else "لم يطلب معاودة الاتصال.",
    }[language]
    if language is Language.TURKISH:
        return f"{name} aradı. Mesaj: {message} {callback_text}"
    if language is Language.ARABIC:
        return f"اتصل {name}. الرسالة: {message} {callback_text}"
    return f"{name} called. Message: {message} {callback_text}"
