import unittest

from data.dungeons import DUNGEON_DATA
from data.economy import MERCHANT_STOCK
from data.item_sets import ITEM_SET_DATA
from data.items import ITEM_DATA
from data.locations import LOCATION_DATA
from data.loot_tables import LOOT_TABLES
from data.quests import QUEST_DATA, QUEST_ORDER
from data.recipes import RECIPE_DATA, RECIPE_ORDER
from data.weather_loot import WEATHER_BOSS_WEAPONS
from data.enemies import ENEMY_DATA


class DataIntegrityTests(unittest.TestCase):
    def test_loot_references_existing_items_and_enemies(self) -> None:
        for enemy_id, entries in LOOT_TABLES.items():
            self.assertIn(enemy_id, ENEMY_DATA)
            for entry in entries:
                self.assertIn(entry["item_id"], ITEM_DATA)
                self.assertGreaterEqual(float(entry["chance"]), 0.0)
                self.assertLessEqual(float(entry["chance"]), 1.0)

    def test_recipes_reference_existing_items(self) -> None:
        self.assertEqual(len(RECIPE_ORDER), len(set(RECIPE_ORDER)))
        for recipe_id in RECIPE_ORDER:
            self.assertIn(recipe_id, RECIPE_DATA)

        for recipe in RECIPE_DATA.values():
            self.assertIn(recipe["output_item_id"], ITEM_DATA)
            for item_id, quantity in recipe["ingredients"].items():
                self.assertIn(item_id, ITEM_DATA)
                self.assertGreater(int(quantity), 0)

    def test_quests_reference_existing_targets_and_rewards(self) -> None:
        self.assertEqual(len(QUEST_ORDER), len(set(QUEST_ORDER)))
        for quest_id in QUEST_ORDER:
            self.assertIn(quest_id, QUEST_DATA)

        for quest in QUEST_DATA.values():
            if quest["objective_type"] == "kill":
                self.assertIn(quest["target_id"], ENEMY_DATA)
            elif quest["objective_type"] == "collect":
                self.assertIn(quest["target_id"], ITEM_DATA)
            else:
                self.fail("Nieznany typ celu questa.")

            reward_item = quest.get("reward_item_id")
            if reward_item is not None:
                self.assertIn(reward_item, ITEM_DATA)

    def test_world_encounters_reference_existing_enemies(self) -> None:
        for location in LOCATION_DATA.values():
            for table_name in ("day_encounters", "night_encounters"):
                for enemy_id, weight in location[table_name].items():
                    self.assertIn(enemy_id, ENEMY_DATA)
                    self.assertGreater(int(weight), 0)

    def test_merchant_stock_references_existing_items(self) -> None:
        for entry in MERCHANT_STOCK:
            self.assertIn(entry["item_id"], ITEM_DATA)
            self.assertGreater(int(entry["buy_price"]), 0)

    def test_weather_boss_loot_references_existing_entities(self) -> None:
        for boss_id, weather_map in WEATHER_BOSS_WEAPONS.items():
            self.assertIn(boss_id, ENEMY_DATA)
            for entry in weather_map.values():
                self.assertIn(entry["item_id"], ITEM_DATA)
                self.assertGreaterEqual(float(entry["chance"]), 0.0)
                self.assertLessEqual(float(entry["chance"]), 1.0)

    def test_item_sets_reference_existing_equipment(self) -> None:
        for item_set in ITEM_SET_DATA.values():
            required = item_set["required_items"]
            self.assertEqual(len(required), len(set(required)))
            for item_id in required:
                self.assertIn(item_id, ITEM_DATA)
                self.assertEqual(ITEM_DATA[item_id]["category"], "equipment")

    def test_dungeon_entry_requirements_reference_existing_keys(self) -> None:
        for dungeon in DUNGEON_DATA.values():
            entry_item_id = dungeon.get("entry_item_id")
            if entry_item_id is None:
                continue
            self.assertIn(entry_item_id, ITEM_DATA)
            self.assertEqual(
                ITEM_DATA[entry_item_id]["category"],
                "key",
            )
            self.assertGreater(
                int(dungeon.get("entry_item_quantity", 0)),
                0,
            )

    def test_recipe_gold_costs_are_non_negative(self) -> None:
        for recipe in RECIPE_DATA.values():
            self.assertGreaterEqual(
                int(recipe.get("gold_cost", 0)),
                0,
            )
