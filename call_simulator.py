"""Haricî API kullanmadan çağrı asistanı kurallarını gösteren yerel simülatör.

Çalıştırma:
    python call_simulator.py --scenario all
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict

from agent_brain.conversation import CallSession
from agent_brain.models import CallMessage, Language, UrgentCallFlag
from agent_brain.summary import build_owner_summary
from agent_brain.tools import (
    InMemoryCallRepository,
    InMemoryNotificationGateway,
    flag_urgent_call,
    save_message,
)


try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


def simulate_normal_message() -> dict:
    """Tam bilgi, onay ve kayıtla sonuçlanan standart mesaj bırakma akışı."""
    call = CallMessage("demo_normal_001", Language.TURKISH, Language.TURKISH)
    session = CallSession(call)
    session.begin()
    session.merge_details(
        caller_name="Ayşe Demir",
        caller_purpose="Toplantı saati",
        message="Yarınki toplantının saatini öğrenmek istiyorum.",
        callback_requested=True,
        callback_number="0555 111 22 33",
    )
    stage_before_confirmation = session.stage.value
    session.confirm(True)
    repository = InMemoryCallRepository()
    saved = save_message(session.call, repository)
    session.mark_completed()
    summary = build_owner_summary(session.call)

    return {
        "scenario": "normal_message",
        "stage_before_confirmation": stage_before_confirmation,
        "final_stage": session.stage.value,
        "saved": saved.success,
        "record_count": len(repository.records),
        "owner_summary": summary.text,
    }


def simulate_message_correction() -> dict:
    """Mesaj değiştiğinde eski onayın geçersiz sayıldığını gösterir."""
    call = CallMessage("demo_correction_001", Language.ENGLISH, Language.TURKISH)
    session = CallSession(call)
    session.begin()
    session.merge_details(caller_purpose="Toplantı", message="Toplantı saat 10'da.", callback_requested=True)
    session.confirm(True)
    session.merge_details(message="Düzeltme: toplantı saat 11'de.")

    repository = InMemoryCallRepository()
    save_before_reconfirmation = save_message(session.call, repository)
    stage_after_correction = session.stage.value
    session.confirm(True)
    save_after_reconfirmation = save_message(session.call, repository)

    return {
        "scenario": "message_correction",
        "stage_after_correction": stage_after_correction,
        "saved_before_new_confirmation": save_before_reconfirmation.success,
        "saved_after_new_confirmation": save_after_reconfirmation.success,
        "record_count": len(repository.records),
    }


def simulate_urgent_call() -> dict:
    """Açık gerekçeli acil çağrıda yalnızca sahibine bildirim üretir."""
    gateway = InMemoryNotificationGateway()
    flag = UrgentCallFlag(
        call_id="demo_urgent_001",
        reason="Arayan, acil geri dönüş gerektiğini belirtti.",
        caller_language=Language.TURKISH,
    )
    result = flag_urgent_call(flag, gateway)
    return {
        "scenario": "urgent_call",
        "notification_created": result.success,
        "notification_count": len(gateway.sent),
        "flag": asdict(gateway.sent[0]) if gateway.sent else None,
    }


SCENARIOS = {
    "normal": simulate_normal_message,
    "correction": simulate_message_correction,
    "urgent": simulate_urgent_call,
}


def run_scenarios(scenario: str) -> list[dict]:
    if scenario == "all":
        return [runner() for runner in SCENARIOS.values()]
    return [SCENARIOS[scenario]()]


def main() -> int:
    parser = argparse.ArgumentParser(description="Agent brain metin tabanlı çağrı simülatörü")
    parser.add_argument("--scenario", choices=["all", *SCENARIOS], default="all")
    args = parser.parse_args()
    print(json.dumps(run_scenarios(args.scenario), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
