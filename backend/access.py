"""Yerel yönetim paneli için küçük ve bağımlılıksız erişim denetimi."""

from __future__ import annotations

import hmac


LOOPBACK_ADDRESSES = {"127.0.0.1", "::1", "localhost"}


def is_authorized_request(remote: str | None, presented_token: str | None, configured_token: str | None) -> bool:
    """Yerel istekleri kabul eder; ağ erişimi için sabit-zamanlı token karşılaştırması yapar."""
    if (remote or "").split("%", 1)[0] in LOOPBACK_ADDRESSES:
        return True
    if not configured_token or not presented_token:
        return False
    return hmac.compare_digest(presented_token, configured_token)
