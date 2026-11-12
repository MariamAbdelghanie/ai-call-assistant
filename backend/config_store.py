"""Web panel ayarları için doğrulanan ve atomik JSON saklama katmanı."""

from __future__ import annotations

import json
import os
import re
import tempfile
import threading
from pathlib import Path


class JsonConfigStore:
    ALLOWED_KEYS = {
        "preset", "stt_model", "llm_model", "tts_voice", "stt_language",
        "assistant_mode", "owner_language", "work_start", "work_end",
        "assistant_enabled", "greeting_text", "architecture", "realtime_model", "realtime_voice",
    }

    def __init__(self, path: Path, defaults: dict) -> None:
        self.path = Path(path)
        self.defaults = dict(defaults)
        self._lock = threading.RLock()

    def read(self) -> dict:
        with self._lock:
            config = dict(self.defaults)
            if not self.path.exists():
                return config
            try:
                data = json.loads(self.path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                return config
            if isinstance(data, dict):
                config.update({key: value for key, value in data.items() if key in self.ALLOWED_KEYS})
            return config

    def update(self, patch: dict) -> dict:
        if not isinstance(patch, dict):
            raise ValueError("Ayar gövdesi JSON nesnesi olmalıdır.")
        with self._lock:
            config = self.read()
            for key, value in patch.items():
                if key in self.ALLOWED_KEYS and value is not None:
                    config[key] = value if isinstance(value, bool) else str(value).strip()
            self._validate(config)
            self._write(config)
            return config

    @staticmethod
    def _validate(config: dict) -> None:
        if config.get("architecture") not in {"cascade", "realtime"}:
            raise ValueError("architecture cascade veya realtime olmalıdır.")
        if config.get("assistant_mode") not in {"personal", "business", "hybrid"}:
            raise ValueError("assistant_mode personal, business veya hybrid olmalıdır.")
        if config.get("owner_language", "tr") not in {"tr", "en", "ar"}:
            raise ValueError("owner_language tr, en veya ar olmalıdır.")
        for key in ("work_start", "work_end"):
            if not re.fullmatch(r"(?:[01]\d|2[0-3]):[0-5]\d", str(config.get(key, ""))):
                raise ValueError(f"{key} HH:MM biçiminde olmalıdır.")

    def _write(self, config: dict) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temp_name = ""
        try:
            with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False, dir=self.path.parent, suffix=".tmp") as temp_file:
                temp_name = temp_file.name
                json.dump(config, temp_file, ensure_ascii=False, indent=2)
                temp_file.flush()
                os.fsync(temp_file.fileno())
            os.replace(temp_name, self.path)
        except OSError as exc:
            if temp_name:
                Path(temp_name).unlink(missing_ok=True)
            raise RuntimeError("Ayarlar güvenli biçimde yazılamadı.") from exc
