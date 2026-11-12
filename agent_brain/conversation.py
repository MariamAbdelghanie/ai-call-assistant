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
        if not self.call.message or not self.call.message.strip():
            return CallStage.COLLECTING_MESSAGE
        if self.call.callback_requested is None:
            return CallStage.ASKING_CALLBACK
        if not self.call.confirmed:
            return CallStage.CONFIRMING
        return CallStage.READY_TO_SAVE

    def begin(self) -> None:
        self.started = True

    def merge_details(
        self,
        *,
        caller_name: Optional[str] = None,
        message: Optional[str] = None,
        callback_requested: Optional[bool] = None,
        callback_number: Optional[str] = None,
    ) -> None:
        """Yalnızca verilen alanları günceller; düzeltilen mesajı yeniden teyit ister."""
        changes: dict[str, object] = {}
        if caller_name is not None:
            changes["caller_name"] = caller_name.strip() or None
        if message is not None:
            changes["message"] = message.strip() or None
            changes["confirmed"] = False
        if callback_requested is not None:
            changes["callback_requested"] = callback_requested
        if callback_number is not None:
            changes["callback_number"] = callback_number.strip() or None
        self.call = replace(self.call, **changes)

    def confirm(self, accepted: bool) -> None:
        if self.stage is not CallStage.CONFIRMING:
            raise ValueError("Teyit, gerekli bilgiler toplandıktan sonra alınabilir.")
        self.call = replace(self.call, confirmed=accepted)

    def mark_completed(self) -> None:
        if self.stage is not CallStage.READY_TO_SAVE:
            raise ValueError("Çağrı yalnızca kaydetmeye hazır olduğunda tamamlanabilir.")
        self.completed = True
