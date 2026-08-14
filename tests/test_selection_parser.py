import unittest

from ui.selection_parser import parse_index_ranges


class IndexRangeParserTests(unittest.TestCase):
    def test_preserves_user_order_across_indexes_and_ranges(self) -> None:
        self.assertEqual(parse_index_ranges("3,1,4-5", 5), [2, 0, 3, 4])

    def test_rejects_out_of_bounds_index(self) -> None:
        with self.assertRaisesRegex(ValueError, r"Pozycja \[4\] nie istnieje"):
            parse_index_ranges("4", 3)

    def test_rejects_reversed_range(self) -> None:
        with self.assertRaisesRegex(ValueError, "Nieprawidłowy zakres"):
            parse_index_ranges("3-1", 3)

    def test_rejects_duplicate_hidden_inside_range(self) -> None:
        with self.assertRaisesRegex(ValueError, "więcej niż raz"):
            parse_index_ranges("1-3,2", 3)


if __name__ == "__main__":
    unittest.main()
