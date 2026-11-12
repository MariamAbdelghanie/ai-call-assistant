import json
import tempfile
import unittest
from pathlib import Path

from backend.access import is_authorized_request
from backend.config_store import JsonConfigStore
from backend.records import CallRecord, JsonCallRepository, RecordNotFound, StorageError


class BackendTests(unittest.TestCase):
    def _record(self, call_id: str, timestamp: str = "2026-11-12T10:00:00+00:00") -> CallRecord:
        return CallRecord.create(
            call_id=call_id,
            timestamp=timestamp,
            caller_name="Ayşe",
            caller_number="05551112233",
            caller_purpose="Bilgi talebi",
            summary_tr="Geri dönüş istiyor.",
            callback_requested=True,
        )

    def test_repository_upserts_marks_and_deletes_atomically(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            repository = JsonCallRepository(Path(temp_dir) / "calls.json")
            repository.upsert(self._record("call-1"))
            repository.upsert(self._record("call-2", "2026-11-12T11:00:00+00:00"))
            self.assertEqual([item.call_id for item in repository.list_records()], ["call-2", "call-1"])
            changed = repository.mark_called_back("call-1", True)
            self.assertTrue(changed.called_back)
            repository.delete("call-2")
            self.assertEqual([item.call_id for item in repository.list_records()], ["call-1"])
            with self.assertRaises(RecordNotFound):
                repository.delete("unknown")

    def test_repository_does_not_overwrite_corrupt_data(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "calls.json"
            path.write_text("{bozuk json", encoding="utf-8")
            repository = JsonCallRepository(path)
            with self.assertRaises(StorageError):
                repository.upsert(self._record("call-1"))
            self.assertEqual(path.read_text(encoding="utf-8"), "{bozuk json")

    def test_config_store_validates_and_writes(self):
        defaults = {
            "architecture": "cascade", "assistant_mode": "hybrid", "owner_language": "tr",
            "work_start": "09:00", "work_end": "17:00",
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "config.json"
            store = JsonConfigStore(path, defaults)
            updated = store.update({"architecture": "realtime", "owner_language": "en"})
            self.assertEqual(updated["architecture"], "realtime")
            self.assertEqual(json.loads(path.read_text(encoding="utf-8"))["owner_language"], "en")
            with self.assertRaises(ValueError):
                store.update({"work_start": "9am"})

    def test_remote_access_requires_matching_token(self):
        self.assertTrue(is_authorized_request("127.0.0.1", None, None))
        self.assertFalse(is_authorized_request("192.168.1.25", None, "secret"))
        self.assertFalse(is_authorized_request("192.168.1.25", "wrong", "secret"))
        self.assertTrue(is_authorized_request("192.168.1.25", "secret", "secret"))


if __name__ == "__main__":
    unittest.main()
