"""Konuşma akışını prompt'tan bağımsız ve test edilebilir tutar."""

from __future__ import annotations

from dataclasses import replace
from typing import Optional

from .models import CallMessage, CallStage


class CallSession:
    """LLM'nin çıkardığı alanları bir çağrı oturumunda güvenle birleştirir."""

    def __init__(self, call: CallMessage) -> None:
        self.call = call
        self.started = False
        self.completed = False

    @property
    def stage(self) -> CallStage:
        if self.completed:
            return CallStage.COMPLETED
        if not self.started:
            return CallStage.GREETING
        if self.call.recording_consent and not (self.call.caller_purpose or "").strip():
            return CallStage.COLLECTING_PURPOSE
        if self.call.recording_consent and not (self.call.message or "").strip():
            return CallStage.COLLECTING_MESSAGE
        if self.call.callback_requested is None:
            return CallStage.ASKING_CALLBACK
        if (
            self.call.callback_requested
            and self.call.callback_number_required
            and not (self.call.callback_number or "").strip()
        ):
            return CallStage.ASKING_CALLBACK_NUMBER
        if not self.call.confirmed:
            return CallStage.CONFIRMING
        return CallStage.READY_TO_SAVE

    def begin(self) -> None:
        self.started = True

    def merge_details(
        self,
        *,
        caller_name: Optional[str] = None,
        caller_purpose: Optional[str] = None,
        message: Optional[str] = None,
        callback_requested: Optional[bool] = None,
        callback_number: Optional[str] = None,
        recording_consent: Optional[bool] = None,
    ) -> None:
        """Yalnızca verilen alanları günceller; düzeltilen mesajı yeniden teyit ister."""
        changes: dict[str, object] = {}
        if caller_name is not None:
            changes["caller_name"] = caller_name.strip() or None
        if caller_purpose is not None:
            changes["caller_purpose"] = caller_purpose.strip() or None
            changes["confirmed"] = False
        if message is not None:
            changes["message"] = message.strip() or None
            changes["confirmed"] = False
        if callback_requested is not None:
            changes["callback_requested"] = callback_requested
            changes["confirmed"] = False
        if callback_number is not None:
            changes["callback_number"] = callback_number.strip() or None
            changes["confirmed"] = False
        if recording_consent is not None:
            changes["recording_consent"] = recording_consent
            changes["confirmed"] = False
        self.call = replace(self.call, **changes)

    def confirm(self, accepted: bool) -> None:
        if self.stage is not CallStage.CONFIRMING:
            raise ValueError("Teyit, gerekli bilgiler toplandıktan sonra alınabilir.")
        self.call = replace(self.call, confirmed=accepted)

    def mark_completed(self) -> None:
        if self.stage is not CallStage.READY_TO_SAVE:
            raise ValueError("Çağrı yalnızca kaydetmeye hazır olduğunda tamamlanabilir.")
        self.completed = True
