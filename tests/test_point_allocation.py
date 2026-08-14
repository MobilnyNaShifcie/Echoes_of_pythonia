import unittest
from unittest.mock import patch

from ui.point_allocation import ask_point_quantity


class PointAllocationInputTests(unittest.TestCase):
    def test_max_returns_maximum(self) -> None:
        with patch("builtins.input", return_value="MAX"):
            self.assertEqual(ask_point_quantity(7), 7)

    def test_number_returns_requested_amount(self) -> None:
        with patch("builtins.input", return_value="3"):
            self.assertEqual(ask_point_quantity(7), 3)

    def test_zero_cancels(self) -> None:
        with patch("builtins.input", return_value="0"):
            self.assertIsNone(ask_point_quantity(7))
