"""Yanıt süresi ölçümü: terminale yazar ve latency_log.csv dosyasına kaydeder.

Mimariden bağımsız ölçüm:
  - Yanıt süresi (e2e): arayan konuşmayı bitirdiği an -> asistan konuşmaya başladığı an
Cascade modunda ayrıca (LiveKit metrikleri gelirse):
  - EOU (konuşma bitti algılama), STT, LLM ilk token (TTFT), TTS ilk ses (TTFB)
Realtime modunda ayrıca:
  - Model ilk yanıt (TTFT)
"""
import csv
import time
import datetime
from pathlib import Path

LOG_FILE = Path(__file__).parent / "latency_log.csv"
FIELDS = ["timestamp", "call_id", "mode", "stt", "llm", "tts", "lang", "turn", "e2e_ms",
          "eou_ms", "stt_ms", "llm_ttft_ms", "tts_ttfb_ms", "realtime_ttft_ms"]


def _ms(v):
    try:
        return round(float(v) * 1000)
    except (TypeError, ValueError):
        return None


class LatencyLogger:
    def __init__(self, call_id: str, mode: str, stt: str = "", llm: str = "", tts: str = ""):
        self.call_id = call_id
        self.mode = mode
        self.stt, self.llm, self.tts = stt, llm, tts
        self.lang = "?"
        self.turn = 0
        self._user_stopped_at = None
        self._parts: dict = {}
        self.e2e_values: list[int] = []

    # ---- olaylar -------------------------------------------------------
    def set_lang(self, lang: str):
        if lang:
            self.lang = lang

    def on_user_state(self, new_state: str):
        # arayan konuşmayı bitirdi -> sayaç başlar
        if new_state == "listening":
            self._user_stopped_at = time.perf_counter()
        elif new_state == "speaking":
            self._user_stopped_at = None
            self._parts = {}

    def on_agent_state(self, new_state: str):
        if new_state == "speaking" and self._user_stopped_at is not None:
            e2e = round((time.perf_counter() - self._user_stopped_at) * 1000)
            self._user_stopped_at = None
            self._finish_turn(e2e)

    def on_metrics(self, m):
        name = type(m).__name__
        if name == "EOUMetrics":
            self._parts["eou_ms"] = _ms(getattr(m, "end_of_utterance_delay", None))
        elif name == "STTMetrics":
            self._parts["stt_ms"] = _ms(getattr(m, "duration", None))
        elif name == "LLMMetrics":
            self._parts["llm_ttft_ms"] = _ms(getattr(m, "ttft", None))
        elif name == "TTSMetrics":
            self._parts["tts_ttfb_ms"] = _ms(getattr(m, "ttfb", None))
        elif name == "RealtimeModelMetrics":
            self._parts["realtime_ttft_ms"] = _ms(getattr(m, "ttft", None))

    # ---- çıktı ---------------------------------------------------------
    def _finish_turn(self, e2e_ms: int):
        self.turn += 1
        self.e2e_values.append(e2e_ms)
        p = self._parts
        detail = " | ".join(f"{k.replace('_ms','').upper()}={v}ms" for k, v in p.items() if v is not None)
        print(f"[⏱ GECİKME] {self.stt} + {self.llm} + {self.tts} | dil={self.lang} tur={self.turn} "
              f"YANIT SÜRESİ={e2e_ms}ms" + (f" | {detail}" if detail else ""), flush=True)
        row = {"timestamp": datetime.datetime.now().isoformat(timespec="seconds"),
               "call_id": self.call_id, "mode": self.mode, "stt": self.stt, "llm": self.llm,
               "tts": self.tts, "lang": self.lang,
               "turn": self.turn, "e2e_ms": e2e_ms}
        row.update({k: p.get(k) for k in FIELDS if k in p})
        try:
            new = not LOG_FILE.exists()
            with LOG_FILE.open("a", newline="", encoding="utf-8") as f:
                w = csv.DictWriter(f, fieldnames=FIELDS)
                if new:
                    w.writeheader()
                w.writerow(row)
        except Exception as e:
            print(f"[⏱ Log yazılamadı] {e}", flush=True)
        self._parts = {}

    def print_summary(self):
        if not self.e2e_values:
            print(f"[⏱ ÖZET] mod={self.mode}: ölçülen yanıt yok.", flush=True)
            return
        v = sorted(self.e2e_values)
        avg = round(sum(v) / len(v))
        print("=" * 60, flush=True)
        print(f"[⏱ ÖZET] {self.stt} + {self.llm} + {self.tts} | dil={self.lang} | tur={len(v)} | "
              f"ortalama={avg}ms | en kısa={v[0]}ms | en uzun={v[-1]}ms", flush=True)
        print("=" * 60, flush=True)
