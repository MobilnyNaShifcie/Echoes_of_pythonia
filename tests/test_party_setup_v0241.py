import unittest
from unittest.mock import patch

from companions.models import PartyState
from ui.companions_view import show_party_setup


class PartySetupV0241Tests(unittest.TestCase):
    def test_solo_shortcut_is_available_even_without_companions(self):
        with patch("builtins.input", return_value="s"):
            action, companion_id = show_party_setup(PartyState())
        self.assertEqual(action, "solo")
        self.assertIsNone(companion_id)

    def test_zero_finishes_party_setup(self):
        with patch("builtins.input", return_value="0"):
            action, companion_id = show_party_setup(PartyState())
        self.assertEqual(action, "done")
        self.assertIsNone(companion_id)


if __name__ == "__main__":
    unittest.main()
