import tempfile
import unittest
from pathlib import Path

from aiohttp.test_utils import TestClient, TestServer

import web_dialer
from backend.config_store import JsonConfigStore
from backend.records import CallRecord, JsonCallRepository


class WebApiTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        temp_path = Path(self.temp_dir.name)
        self.old_repository = web_dialer.CALL_LOG_REPOSITORY
        self.old_config_store = web_dialer.CONFIG_STORE
        web_dialer.CALL_LOG_REPOSITORY = JsonCallRepository(temp_path / "calls.json")
        web_dialer.CONFIG_STORE = JsonConfigStore(temp_path / "config.json", web_dialer.DEFAULT_CONFIG)
        self.client = TestClient(TestServer(web_dialer.create_app()))
        await self.client.start_server()

    async def asyncTearDown(self):
        await self.client.close()
        web_dialer.CALL_LOG_REPOSITORY = self.old_repository
        web_dialer.CONFIG_STORE = self.old_config_store
        self.temp_dir.cleanup()

    async def test_calls_are_listed_and_deletion_requires_confirmation(self):
        web_dialer.CALL_LOG_REPOSITORY.upsert(CallRecord.create(
            call_id="web-test-1",
            caller_name="Ayşe",
            caller_number="05551112233",
            caller_purpose="Bilgi",
            summary_tr="Geri dönüş istiyor.",
        ))
        response = await self.client.get("/api/calls")
        self.assertEqual(response.status, 200)
        self.assertEqual((await response.json())[0]["call_id"], "web-test-1")

        response = await self.client.post("/logs/delete", json={"call_id": "web-test-1"})
        self.assertEqual(response.status, 400)
        response = await self.client.post(
            "/logs/delete", json={"call_id": "web-test-1", "confirmed": True}
        )
        self.assertEqual(response.status, 200)

    async def test_all_calls_need_explicit_confirmation_before_deletion(self):
        web_dialer.CALL_LOG_REPOSITORY.upsert(CallRecord.create(
            call_id="web-test-delete-all", caller_name="Ali", caller_number="555",
            caller_purpose="Silme testi", summary_tr="Test kaydı.",
        ))
        response = await self.client.post("/api/calls/delete-all", json={})
        self.assertEqual(response.status, 400)
        response = await self.client.post("/api/calls/delete-all", json={"confirmed": True})
        self.assertEqual(response.status, 200)
        self.assertEqual((await response.json())["deleted_count"], 1)

    async def test_config_rejects_invalid_values_and_health_reports_status(self):
        response = await self.client.post("/api/config", json={"architecture": "unknown"})
        self.assertEqual(response.status, 400)
        response = await self.client.get("/api/health")
        self.assertEqual(response.status, 200)
        body = await response.json()
        self.assertIn("ok", body)
        self.assertIn("issues", body)


if __name__ == "__main__":
    unittest.main()
