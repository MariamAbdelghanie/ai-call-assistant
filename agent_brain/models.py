"""Çağrı asistanının sağlayıcıdan bağımsız veri modelleri."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional


class Language(str, Enum):
    TURKISH = "tr"
    ENGLISH = "en"
    ARABIC = "ar"


class CallStage(str, Enum):
    GREETING = "greeting"
    COLLECTING_PURPOSE = "collecting_purpose"
    COLLECTING_MESSAGE = "collecting_message"
    ASKING_CALLBACK = "asking_callback"
    ASKING_CALLBACK_NUMBER = "asking_callback_number"
    CONFIRMING = "confirming"
    READY_TO_SAVE = "ready_to_save"
    COMPLETED = "completed"


class Urgency(str, Enum):
    NORMAL = "normal"
    HIGH = "high"


@dataclass
class CallMessage:
    """Arayan tarafından doğrulanan, saklanabilir çağrı kaydı."""

    call_id: str
    caller_language: Language
    owner_language: Language
    caller_purpose: Optional[str] = None
    message: Optional[str] = None
    caller_name: Optional[str] = None
    callback_requested: Optional[bool] = None
    callback_number: Optional[str] = None
    callback_number_required: bool = False
    recording_consent: bool = True
    confirmed: bool = False
    urgency: Urgency = Urgency.NORMAL
    metadata: dict[str, str] = field(default_factory=dict)

    def missing_required_fields(self) -> list[str]:
        missing: list[str] = []
        if not self.call_id.strip():
            missing.append("call_id")
        if self.callback_requested is None:
            missing.append("callback_requested")
        # Geri aranmak isteyen ve numarasi gorunmeyen arayanin numarasi sorulur.
        if (
            self.callback_requested
            and self.callback_number_required
            and not (self.callback_number or "").strip()
        ):
            missing.append("callback_number")
        if self.recording_consent:
            # Kayit izni varsa gorusmenin nedeni ve mesaji eksiksiz olmalidir.
            if not self.caller_purpose or not self.caller_purpose.strip():
                missing.append("caller_purpose")
            if not self.message or not self.message.strip():
                missing.append("message")
        elif not self.callback_requested:
            # Izin yoksa icerik saklanmaz; cagri en azindan bir geri arama
            # talebi birakmalidir, aksi halde kayit tamamen anlamsizdir.
            missing.append("callback_request_for_no_consent")
        if not self.confirmed:
            missing.append("confirmed")
        return missing


@dataclass(frozen=True)
class ToolResult:
    success: bool
    message: str
    call_id: str
    error_code: Optional[str] = None


@dataclass(frozen=True)
class UrgentCallFlag:
    call_id: str
    reason: str
    caller_language: Language
    notify_owner: bool = True
    urgency: Urgency = Urgency.HIGH
