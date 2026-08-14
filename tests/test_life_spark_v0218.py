import unittest

from data.loot_tables import LOOT_TABLES


class LifeSparkDropV0218Tests(unittest.TestCase):
    def test_cursed_scarecrow_life_spark_chance_is_twenty_percent(self) -> None:
        entries = LOOT_TABLES["cursed_scarecrow"]
        spark = next(entry for entry in entries if entry["item_id"] == "spark_of_life")
        self.assertEqual(spark["chance"], 0.20)

    def test_cursed_scarecrow_old_clothes_chance_is_unchanged(self) -> None:
        entries = LOOT_TABLES["cursed_scarecrow"]
        clothes = next(entry for entry in entries if entry["item_id"] == "old_clothes")
        self.assertEqual(clothes["chance"], 0.50)


if __name__ == "__main__":
    unittest.main()
