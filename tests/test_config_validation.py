import tempfile
import unittest
from pathlib import Path

from config_validation import format_report, read_env_file, validate_configuration


class ConfigValidationTests(unittest.TestCase):
    def _valid_livekit_env(self) -> dict[str, str]:
        return {
            "LIVEKIT_URL": "ws://127.0.0.1:7880",
            "LIVEKIT_API_KEY": "local-test-key",
            "LIVEKIT_API_SECRET": "local-test-secret",
        }

    def test_cascade_requires_groq_key(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            env = self._valid_livekit_env()
            issues = validate_configuration(
                project_dir=Path(temp_dir),
                config={"architecture": "cascade"},
                env=env,
            )
        self.assertIn("groq_api_key-missing", {issue.code for issue in issues})

    def test_realtime_requires_gemini_not_groq(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            env = self._valid_livekit_env()
            issues = validate_configuration(
                project_dir=Path(temp_dir),
                config={"architecture": "realtime"},
                env=env,
            )
        codes = {issue.code for issue in issues}
        self.assertIn("google_api_key-missing", codes)
        self.assertNotIn("groq_api_key-missing", codes)

    def test_placeholder_values_are_not_accepted(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            env = self._valid_livekit_env()
            env["GROQ_API_KEY"] = "your_groq_api_key_here"
            issues = validate_configuration(
                project_dir=Path(temp_dir),
                config={"architecture": "cascade"},
                env=env,
            )
        self.assertIn("groq_api_key-missing", {issue.code for issue in issues})

    def test_env_reader_keeps_values_with_equals_signs(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            env_file = Path(temp_dir) / ".env"
            env_file.write_text("GROQ_API_KEY=part=with=equals\n", encoding="utf-8")
            values = read_env_file(env_file)
        self.assertEqual(values["GROQ_API_KEY"], "part=with=equals")

    def test_report_never_includes_secret_value(self):
        report = format_report(validate_configuration(
            project_dir=Path(tempfile.gettempdir()) / "missing-config-dir",
            config={"architecture": "cascade"},
            env=self._valid_livekit_env(),
        ))
        self.assertNotIn("local-test-secret", report)

    def test_calendar_and_firebase_paths_are_checked_separately(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            project_dir = Path(temp_dir)
            (project_dir / "calendar.json").write_text("{}", encoding="utf-8")
            env = self._valid_livekit_env()
            env.update({
                "GROQ_API_KEY": "local-groq-key",
                "GOOGLE_CREDENTIALS_PATH": "calendar.json",
                "FIREBASE_CREDENTIALS_PATH": "missing-firebase.json",
            })
            issues = validate_configuration(
                project_dir=project_dir,
                config={"architecture": "cascade"},
                env=env,
            )
        codes = {issue.code for issue in issues}
        self.assertNotIn("google-calendar-credentials-missing", codes)
        self.assertIn("firebase-credentials-missing", codes)


if __name__ == "__main__":
    unittest.main()
