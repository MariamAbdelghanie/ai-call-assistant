import unittest

from agent_brain.conversation import CallSession
from agent_brain.language import normalize_language
from agent_brain.models import CallMessage, CallStage, Language, UrgentCallFlag
from agent_brain.summary import build_owner_summary
from agent_brain.tools import InMemoryCallRepository, InMemoryNotificationGateway, flag_urgent_call, save_message


class AgentBrainTests(unittest.TestCase):
    def test_known_details_skip_to_callback_question(self):
        session = CallSession(CallMessage("call_001", Language.TURKISH, Language.ENGLISH))
        session.begin()
        session.merge_details(caller_name="Ahmet", message="Toplantı yarın 11'e alındı.")
        self.assertEqual(session.stage, CallStage.ASKING_CALLBACK)

    def test_changed_message_requires_confirmation_again(self):
        session = CallSession(CallMessage("call_002", Language.TURKISH, Language.TURKISH))
        session.begin()
        session.merge_details(message="Toplantı 10'da.", callback_requested=True)
        session.confirm(True)
        session.merge_details(message="Toplantı 11'de.")
        self.assertEqual(session.stage, CallStage.CONFIRMING)

    def test_unconfirmed_message_is_not_saved(self):
        repository = InMemoryCallRepository()
        call = CallMessage("call_003", Language.ENGLISH, Language.ENGLISH, message="Please call me.", callback_requested=True)
        result = save_message(call, repository)
        self.assertFalse(result.success)
        self.assertEqual(repository.records, {})

    def test_owner_summary_requires_translation_for_different_languages(self):
        call = CallMessage("call_004", Language.TURKISH, Language.ENGLISH, caller_name="Ahmet",
                           message="Toplantı yarın 11'e alındı.", callback_requested=True, confirmed=True)
        summary = build_owner_summary(call, "Tomorrow's meeting was moved to 11:00.")
        self.assertIn("Ahmet called", summary.text)
        with self.assertRaises(ValueError):
            build_owner_summary(call)

    def test_language_and_urgent_notification(self):
        self.assertEqual(normalize_language("EN-us"), Language.ENGLISH)
        gateway = InMemoryNotificationGateway()
        result = flag_urgent_call(UrgentCallFlag("call_005", "Caller reports immediate danger.", Language.ENGLISH), gateway)
        self.assertTrue(result.success)
        self.assertEqual(len(gateway.sent), 1)


if __name__ == "__main__":
    unittest.main()
