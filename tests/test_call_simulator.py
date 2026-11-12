import unittest

from call_simulator import (
    run_scenarios,
    simulate_message_correction,
    simulate_normal_message,
    simulate_urgent_call,
)


class CallSimulatorTests(unittest.TestCase):
    def test_normal_message_is_confirmed_saved_and_completed(self):
        result = simulate_normal_message()
        self.assertEqual(result["stage_before_confirmation"], "confirming")
        self.assertEqual(result["final_stage"], "completed")
        self.assertTrue(result["saved"])
        self.assertEqual(result["record_count"], 1)

    def test_corrected_message_needs_a_new_confirmation(self):
        result = simulate_message_correction()
        self.assertEqual(result["stage_after_correction"], "confirming")
        self.assertFalse(result["saved_before_new_confirmation"])
        self.assertTrue(result["saved_after_new_confirmation"])

    def test_urgent_call_creates_an_owner_notification(self):
        result = simulate_urgent_call()
        self.assertTrue(result["notification_created"])
        self.assertEqual(result["notification_count"], 1)

    def test_all_scenarios_are_available(self):
        self.assertEqual(len(run_scenarios("all")), 3)


if __name__ == "__main__":
    unittest.main()
