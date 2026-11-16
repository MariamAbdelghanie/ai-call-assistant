"""Projeyi başlatmadan önce eksik veya güvensiz ayarları raporlar.

Bu modül anahtarların değerlerini hiç yazdırmaz; yalnızca hangi ayarın
eksik, örnek değer veya geliştirme değeri olduğunu bildirir.
"""

from __future__ import annotations

import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping


try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


PROJECT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = PROJECT_DIR / "agent_config.json"


@dataclass(frozen=True)
class ValidationIssue:
    severity: str  # "error" veya "warning"
    code: str
    message: str
    fix: str


def _is_real_value(value: str | None) -> bool:
    """Boş ve .env.example içindeki örnek değerleri yapılandırılmamış sayar."""
    text = (value or "").strip()
    if not text:
        return False
    lowered = text.lower()
    placeholders = ("your_", "buraya_", "replace_", "changeme", "example", "...")
    return not any(marker in lowered for marker in placeholders)


def _resolve_path(project_dir: Path, value: str) -> Path:
    candidate = Path(value)
    return candidate if candidate.is_absolute() else project_dir / candidate


def read_env_file(path: Path) -> dict[str, str]:
    """Basit KEY=VALUE biçimindeki .env dosyasını gizli değeri göstermeden okur."""
    if not path.exists():
        return {}

    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        if key:
            values[key] = value.strip().strip("\"'")
    return values


def load_agent_config(path: Path = CONFIG_PATH) -> dict:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def validate_configuration(
    *,
    project_dir: Path = PROJECT_DIR,
    config: Mapping | None = None,
    env: Mapping[str, str] | None = None,
) -> list[ValidationIssue]:
    """Çalışma zamanı ve isteğe bağlı servis ayarlarını denetler."""
    project_dir = Path(project_dir)
    current_config = dict(config if config is not None else load_agent_config(project_dir / "agent_config.json"))
    file_env = read_env_file(project_dir / ".env")
    merged_env = dict(file_env)
    merged_env.update(dict(os.environ if env is None else env))
    issues: list[ValidationIssue] = []

    if not (project_dir / ".env").exists():
        issues.append(ValidationIssue(
            "warning", "env-file-missing", ".env dosyası bulunamadı.",
            ".env.example dosyasını .env olarak kopyalayıp gerekli değerleri girin.",
        ))

    architecture = str(current_config.get("architecture", "cascade")).strip().lower()
    if architecture not in {"cascade", "realtime"}:
        issues.append(ValidationIssue(
            "error", "architecture-invalid", "architecture değeri cascade veya realtime değil.",
            "agent_config.json içindeki architecture alanını cascade ya da realtime yapın.",
        ))
    else:
        required = ["LIVEKIT_URL", "LIVEKIT_API_KEY", "LIVEKIT_API_SECRET"]
        if architecture == "cascade":
            required.append("GROQ_API_KEY")
        else:
            required.append("GOOGLE_API_KEY")

        for key in required:
            if not _is_real_value(merged_env.get(key)):
                provider = "Groq" if key == "GROQ_API_KEY" else "Gemini" if key == "GOOGLE_API_KEY" else "LiveKit"
                issues.append(ValidationIssue(
                    "error", f"{key.lower()}-missing", f"{provider} için {key} ayarlanmamış.",
                    f".env dosyasına {key}=... satırını ekleyin.",
                ))

    tts_voice = str(current_config.get("tts_voice", "")).strip().lower()
    if architecture == "cascade" and tts_voice.startswith("elevenlabs"):
        for key in ("ELEVENLABS_API_KEY", "ELEVENLABS_VOICE_ID"):
            if not _is_real_value(merged_env.get(key)):
                issues.append(ValidationIssue(
                    "warning", f"{key.lower()}-missing",
                    f"ElevenLabs sesi seçili ama {key} ayarlanmamış; Edge TTS'e geri dönülecek.",
                    f".env dosyasına {key}=... satırını ekleyin.",
                ))

    if merged_env.get("LIVEKIT_API_KEY") == "devkey" or merged_env.get("LIVEKIT_API_SECRET") == "secret":
        issues.append(ValidationIssue(
            "warning", "livekit-dev-credentials", "LiveKit geliştirme anahtarları kullanılıyor.",
            "Yerel test dışında rastgele ve güçlü LiveKit anahtarları kullanın.",
        ))

    google_credentials_name = merged_env.get("GOOGLE_CREDENTIALS_PATH", "firebase-credentials.json")
    firebase_credentials_name = merged_env.get("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
    google_credentials_exist = _resolve_path(project_dir, google_credentials_name).exists()
    firebase_credentials_exist = _resolve_path(project_dir, firebase_credentials_name).exists()
    calendar_id_ok = _is_real_value(merged_env.get("GOOGLE_CALENDAR_ID"))
    if not google_credentials_exist:
        issues.append(ValidationIssue(
            "warning", "google-calendar-credentials-missing", "Google Calendar servis hesabı JSON dosyası bulunamadı.",
            "JSON dosyasını proje klasörüne koyun ve GOOGLE_CREDENTIALS_PATH yolunu güncelleyin.",
        ))
    if not firebase_credentials_exist:
        issues.append(ValidationIssue(
            "warning", "firebase-credentials-missing", "Firebase servis hesabı JSON dosyası bulunamadı.",
            "JSON dosyasını proje klasörüne koyun ve FIREBASE_CREDENTIALS_PATH yolunu güncelleyin.",
        ))
    if not calendar_id_ok:
        issues.append(ValidationIssue(
            "warning", "calendar-id-missing", "GOOGLE_CALENDAR_ID ayarlanmamış; takvim işlemleri kullanılamaz.",
            "Test için ayrı bir takvim oluşturup kimliğini .env dosyasına yazın.",
        ))
    if not _is_real_value(merged_env.get("NTFY_TOPIC")):
        issues.append(ValidationIssue(
            "warning", "ntfy-topic-missing", "NTFY_TOPIC ayarlanmamış; bildirim gönderilemez.",
            "Tahmin edilmesi zor, özel bir ntfy konu adı belirleyin.",
        ))

    model_path = project_dir / "models" / "tr_TR-dfki-medium.onnx"
    if not model_path.exists():
        issues.append(ValidationIssue(
            "error", "piper-model-missing", "Yerel Piper ses modeli bulunamadı.",
            "Bu uygulama başlangıçta Piper'ı yükler; models/tr_TR-dfki-medium.onnx dosyasını ekleyin.",
        ))

    return issues


def format_report(issues: list[ValidationIssue]) -> str:
    if not issues:
        return "[OK] Ayar denetimi tamamlandı. Zorunlu ayarlar hazır."
    lines = ["Ayar denetimi sonucu:"]
    for issue in issues:
        label = "HATA" if issue.severity == "error" else "UYARI"
        lines.append(f"[{label}] {issue.message} Çözüm: {issue.fix}")
    return "\n".join(lines)


def main() -> int:
    issues = validate_configuration()
    print(format_report(issues))
    return 1 if any(issue.severity == "error" for issue in issues) else 0


if __name__ == "__main__":
    raise SystemExit(main())
