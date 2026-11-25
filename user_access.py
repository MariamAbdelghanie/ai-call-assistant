"""Kim hangi cagri kaydini gorebilir: kimlik dogrulama ve sahiplik.

Onceki durumda /logs ucuna dogru API_TOKEN ile gelen herkes TUM cagri
kayitlarini okuyabiliyordu; hangi hesapla giris yapildiginin bir onemi
yoktu. Bu modul iki seyi ekler:

1. Istegi yapanin kim oldugunu Firebase kimlik belirtecinden dogrular.
2. Her cagri kaydini bir sahibe (owner_uid) baglar ve yalnizca o sahibin
   kayitlarini dondurur.

Sahiplik modeli: bir kurulum (bu sunucu + bu asistan) tek bir isletme
sahibine aittir. Ilk giris yapan hesap asistani "sahiplenir" ve
owner.json dosyasina yazilir. Sonradan giren baska bir hesap kendi bos
listesini gorur; baskasinin kayitlarina erisemez.
"""

from __future__ import annotations

import json
import os
import threading
from dataclasses import dataclass
from pathlib import Path

OWNER_FILE = Path(__file__).parent / "owner.json"
_LOCK = threading.RLock()


@dataclass(frozen=True)
class Caller:
    """Istegi yapan kimlik."""

    uid: str
    email: str

    @property
    def is_admin_token(self) -> bool:
        """Yerel panel API_TOKEN ile geldiyse sahibi gibi davranir."""
        return self.uid == "__api_token__"


def _read_owner() -> dict:
    if not OWNER_FILE.exists():
        return {}
    try:
        data = json.loads(OWNER_FILE.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def _write_owner(data: dict) -> None:
    tmp = OWNER_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    os.replace(tmp, OWNER_FILE)


def owner_uid() -> str:
    """Bu asistanin sahibi; henuz sahiplenilmediyse bos."""
    with _LOCK:
        return str(_read_owner().get("owner_uid") or "")


def claim_owner(caller: Caller) -> str:
    """Asistan sahipsizse ilk giren hesaba baglar ve sahibi dondurur."""
    with _LOCK:
        data = _read_owner()
        current = str(data.get("owner_uid") or "")
        if current:
            return current
        if caller.is_admin_token or not caller.uid:
            return current
        _write_owner({"owner_uid": caller.uid, "owner_email": caller.email})
        print(f"[Access] Asistan sahiplendi: {caller.email}", flush=True)
        return caller.uid


def verify_firebase_token(id_token: str) -> Caller | None:
    """Firebase kimlik belirtecini dogrular; gecersizse None."""
    if not id_token:
        return None
    try:
        import firebase_admin
        from firebase_admin import auth as fb_auth, credentials
    except ImportError:
        return None
    try:
        if not firebase_admin._apps:
            path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
            if not os.path.exists(path):
                return None
            firebase_admin.initialize_app(credentials.Certificate(path))
        decoded = fb_auth.verify_id_token(id_token)
    except Exception:
        return None
    uid = str(decoded.get("uid") or decoded.get("user_id") or "")
    if not uid:
        return None
    return Caller(uid=uid, email=str(decoded.get("email") or ""))


def visible_to(record: dict, caller: Caller, owner: str) -> bool:
    """Kaydi bu kullanici gorebilir mi.

    Sahipsiz eski kayitlar (owner_uid yok) kurulumun sahibine sayilir;
    boylece gecis sirasinda mevcut veriler kaybolmaz.
    """
    record_owner = str(record.get("owner_uid") or "") or owner
    if caller.is_admin_token:
        return True
    return bool(caller.uid) and record_owner == caller.uid
