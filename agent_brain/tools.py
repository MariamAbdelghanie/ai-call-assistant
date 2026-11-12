"""LiveKit function tool'larına bağlanabilecek güvenli iş kuralları."""

from __future__ import annotations

from dataclasses import replace
from typing import Protocol

from .models import CallMessage, ToolResult, UrgentCallFlag


class CallRepository(Protocol):
    def save(self, call: CallMessage) -> None: ...


class NotificationGateway(Protocol):
    def notify_urgent(self, flag: UrgentCallFlag) -> None: ...


class InMemoryCallRepository:
    """Test ve yerel geliştirme için geçici kayıt deposu."""

    def __init__(self) -> None:
        self.records: dict[str, CallMessage] = {}

    def save(self, call: CallMessage) -> None:
        self.records[call.call_id] = replace(call, metadata=dict(call.metadata))


class InMemoryNotificationGateway:
    def __init__(self) -> None:
        self.sent: list[UrgentCallFlag] = []

    def notify_urgent(self, flag: UrgentCallFlag) -> None:
        self.sent.append(flag)


def save_message(call: CallMessage, repository: CallRepository) -> ToolResult:
    """Yalnızca teyitli ve tam çağrı bilgisini kaydeder."""
    validation = validate_call_for_storage(call)
    if not validation.success:
        return validation
    try:
        repository.save(call)
    except Exception:
        return ToolResult(False, "Message could not be saved at this time.", call.call_id, "repository_unavailable")
    return ToolResult(True, "Message saved successfully.", call.call_id)


def validate_call_for_storage(call: CallMessage) -> ToolResult:
    """Kalıcı kayıt öncesi rapordaki zorunlu alan ve teyit kurallarını uygular."""
    missing = call.missing_required_fields()
    if missing:
        return ToolResult(
            False,
            "Message was not saved because required details are missing.",
            call.call_id,
            "missing_required_fields:" + ",".join(missing),
        )
    return ToolResult(True, "Call details are ready to save.", call.call_id)


def flag_urgent_call(flag: UrgentCallFlag, gateway: NotificationGateway) -> ToolResult:
    """Açık acil beyan sonrası sahibine bildirim gönderir; acil servis yerine geçmez."""
    if not flag.reason.strip():
        return ToolResult(False, "Urgency reason is required.", flag.call_id, "missing_reason")
    try:
        if flag.notify_owner:
            gateway.notify_urgent(flag)
    except Exception:
        return ToolResult(False, "Urgent notification could not be sent.", flag.call_id, "notification_failed")
    return ToolResult(True, "Urgent call was flagged.", flag.call_id)
