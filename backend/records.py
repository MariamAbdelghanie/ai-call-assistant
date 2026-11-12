"""Çağrı kayıtları için atomik, yerel JSON deposu.

Firebase etkinleştirilmemişken uygulamanın güvenilir yerel kaynağıdır. Her
yazma geçici dosyaya yapılır ve sonra atomik olarak yer değiştirir; böylece
yarım yazılmış call_logs.json dosyası oluşmaz.
"""

from __future__ import annotations

import json
import os
import tempfile
import threading
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path


class StorageError(RuntimeError):
    pass


class RecordNotFound(KeyError):
    pass


@dataclass(frozen=True)
class CallRecord:
    call_id: str
    timestamp: str
    caller_name: str
    caller_number: str
    caller_purpose: str
    summary_tr: str
    appointment_info: str = ""
    is_urgent: bool = False
    callback_requested: bool = False
    called_back: bool = False
    lang: str = "tr"
    recording_consent: bool = True

    @classmethod
    def create(
        cls,
        *,
        call_id: str,
        caller_name: str,
        caller_number: str,
        caller_purpose: str,
        summary_tr: str,
        appointment_info: str = "",
        is_urgent: bool = False,
        callback_requested: bool = False,
        called_back: bool = False,
        lang: str = "tr",
        recording_consent: bool = True,
        timestamp: str | None = None,
    ) -> "CallRecord":
        record = cls(
            call_id=(call_id or "").strip(),
            timestamp=timestamp or datetime.now(timezone.utc).isoformat(),
            caller_name=(caller_name or "").strip() or "İsimsiz Arayan",
            caller_number=(caller_number or "").strip() or "Bilinmiyor",
            caller_purpose=(caller_purpose or "").strip() or "Mesaj Bırakma",
            summary_tr=(summary_tr or "").strip(),
            appointment_info=(appointment_info or "").strip(),
            is_urgent=bool(is_urgent),
            callback_requested=bool(callback_requested),
            called_back=bool(called_back),
            lang=lang if lang in {"tr", "en", "ar"} else "tr",
            recording_consent=bool(recording_consent),
        )
        if not record.call_id:
            raise ValueError("call_id zorunludur.")
        if record.recording_consent and not record.summary_tr:
            raise ValueError("Kayıt izni olan çağrıda özet zorunludur.")
        return record

    @classmethod
    def from_dict(cls, data: dict) -> "CallRecord":
        return cls.create(
            call_id=str(data.get("call_id", "")),
            timestamp=str(data.get("timestamp", "")) or None,
            caller_name=str(data.get("caller_name", "")),
            caller_number=str(data.get("caller_number", "")),
            caller_purpose=str(data.get("caller_purpose", "")),
            summary_tr=str(data.get("summary_tr", "")),
            appointment_info=str(data.get("appointment_info", "")),
            is_urgent=bool(data.get("is_urgent", False)),
            callback_requested=bool(data.get("callback_requested", False)),
            called_back=bool(data.get("called_back", False)),
            lang=str(data.get("lang", "tr")),
            recording_consent=bool(data.get("recording_consent", True)),
        )

    def to_dict(self) -> dict:
        return asdict(self)


class JsonCallRepository:
    """Tek işlemli yerel kullanım için kilitli ve atomik çağrı kaydı deposu."""

    def __init__(self, path: Path) -> None:
        self.path = Path(path)
        self._lock = threading.RLock()

    def _read_unlocked(self) -> list[CallRecord]:
        if not self.path.exists():
            return []
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise StorageError("Çağrı kayıt dosyası okunamadı; veri korunması için üzerine yazılmadı.") from exc
        if not isinstance(raw, list):
            raise StorageError("Çağrı kayıt dosyası beklenen liste biçiminde değil.")
        try:
            return [CallRecord.from_dict(item) for item in raw if isinstance(item, dict)]
        except ValueError as exc:
            raise StorageError("Çağrı kayıtlarından biri geçersiz.") from exc

    def _write_unlocked(self, records: list[CallRecord]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temp_name = ""
        try:
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", delete=False, dir=self.path.parent, suffix=".tmp"
            ) as temp_file:
                temp_name = temp_file.name
                json.dump([record.to_dict() for record in records], temp_file, ensure_ascii=False, indent=2)
                temp_file.flush()
                os.fsync(temp_file.fileno())
            os.replace(temp_name, self.path)
        except OSError as exc:
            if temp_name:
                Path(temp_name).unlink(missing_ok=True)
            raise StorageError("Çağrı kayıtları güvenli biçimde yazılamadı.") from exc

    def list_records(self) -> list[CallRecord]:
        with self._lock:
            return sorted(self._read_unlocked(), key=lambda record: record.timestamp, reverse=True)

    def upsert(self, record: CallRecord) -> CallRecord:
        with self._lock:
            records = self._read_unlocked()
            for index, old_record in enumerate(records):
                if old_record.call_id == record.call_id:
                    records[index] = record
                    self._write_unlocked(records)
                    return record
            records.append(record)
            self._write_unlocked(records)
            return record

    def mark_called_back(self, call_id: str, called_back: bool) -> CallRecord:
        with self._lock:
            records = self._read_unlocked()
            for index, record in enumerate(records):
                if record.call_id == call_id:
                    updated = CallRecord(**{**record.to_dict(), "called_back": bool(called_back)})
                    records[index] = updated
                    self._write_unlocked(records)
                    return updated
        raise RecordNotFound(call_id)

    def delete(self, call_id: str) -> None:
        with self._lock:
            records = self._read_unlocked()
            remaining = [record for record in records if record.call_id != call_id]
            if len(remaining) == len(records):
                raise RecordNotFound(call_id)
            self._write_unlocked(remaining)
