import json
import tempfile
import unittest
from datetime import date, timedelta
from pathlib import Path
from unittest.mock import patch

from combat.combat import CombatEngine
from combat.fate import FateEngine
from data.books import PATH_UNLOCK_BOOK_IDS
from data.class_loot import CLASS_GEAR_POOL, CLASS_WEAPON_POOLS
from data.guild_rumors import available_guild_rumors
from data.recipes import RECIPE_DATA
from data.talents import CLASS_PATHS
from enemies.factory import create_enemy
from game.config import SAVE_SCHEMA_VERSION
from game.state import GameState
from items.catalog import get_item_definition
from items.models import EquipmentSlot
from player.attributes import AttributeType
from player.classes import PLAYABLE_CLASSES, PlayerClass
from player.factory import create_player
from player.passive_specializations import choose_passive_specialization
from player.passives import PassiveType
from player.skills import get_skill, unlocked_skills
from player.talents import (
    available_tree_points,
    learn_talent,
    reset_talents,
    specialization_name,
    total_tree_points_for_level,
)
from systems.black_market import BlackMarketState, ensure_black_market_rotation
from systems.class_loot import roll_class_gear_drop, roll_class_weapon_drop
from systems.crafting import CRAFTING_CATEGORIES, get_all_recipes, recipes_for_category
from systems.path_books import read_path_book, roll_path_book_drop
from systems.save_system import load_game, save_game


class DeterministicRng:
    def __init__(self, *, random_values=None, dice=None, choice_index=0):
        self.random_values = iter(random_values or [])
        self.dice = iter(dice or [])
        self.choice_index = choice_index

    def random(self):
        try:
            return next(self.random_values)
        except StopIteration:
            return 0.99

    def randint(self, a, b):
        try:
            value = next(self.dice)
        except StopIteration:
            value = b
        return max(a, min(b, value))

    def choice(self, seq):
        return seq[self.choice_index % len(seq)]

    def uniform(self, a, b):
        return (a + b) / 2.0

    def shuffle(self, seq):
        return None


class ClassesV023Tests(unittest.TestCase):
    def _class_player(self, player_class: PlayerClass, level: int = 20):
        player = create_player("Tester")
        player.level = level
        player.choose_class(player_class)
        player.stats.current_mana = max(200, player.stats.max_mana)
        player.stats.max_mana = max(player.stats.max_mana, 200)
        return player

    def _training_enemy(self, attack=0):
        enemy = create_enemy("trial_wraith")
        enemy.max_hp = 5000
        enemy.current_hp = 5000
        enemy.attack = attack
        enemy.defense = 0
        enemy.dodge = 0.0
        enemy.special_chance = 0.0
        enemy.extra_attack_chance = 0.0
        return enemy

    def test_schema_is_thirteen(self):
        self.assertEqual(SAVE_SCHEMA_VERSION, 15)

    def test_four_playable_classes_include_pierrot(self):
        self.assertEqual(len(PLAYABLE_CLASSES), 4)
        self.assertIn(PlayerClass.PIERROT, PLAYABLE_CLASSES)

    def test_tree_points_level_eighteen_equal_eight(self):
        self.assertEqual(total_tree_points_for_level(18, True), 8)
        player = self._class_player(PlayerClass.WARRIOR, 18)
        self.assertEqual(available_tree_points(player), 8)

    def test_base_path_can_be_learned_without_book(self):
        player = self._class_player(PlayerClass.WARRIOR)
        rank = learn_talent(player, "warrior_battle_fury")
        self.assertEqual(rank, 1)

    def test_locked_path_requires_book(self):
        player = self._class_player(PlayerClass.WARRIOR)
        with self.assertRaises(ValueError):
            learn_talent(player, "heavy_knight_core")

    def test_path_book_unlocks_only_matching_class_and_is_consumed(self):
        player = self._class_player(PlayerClass.WARRIOR)
        player.inventory.add("path_heavy_knight_book")
        result = read_path_book(player, "path_heavy_knight_book")
        self.assertEqual(result.path_id, "warrior_heavy_knight")
        self.assertIn("warrior_heavy_knight", player.unlocked_class_paths)
        self.assertEqual(player.inventory.count("path_heavy_knight_book"), 0)

        player.inventory.add("path_arcana_book")
        with self.assertRaises(ValueError):
            read_path_book(player, "path_arcana_book")
        self.assertEqual(player.inventory.count("path_arcana_book"), 1)

    def test_path_book_drop_uses_common_random_pool(self):
        rng = DeterministicRng(random_values=[0.0], choice_index=2)
        drop = roll_path_book_drop("admiral_varek", rng)
        self.assertEqual(drop, PATH_UNLOCK_BOOK_IDS[2])

    def test_tree_reset_refunds_points_but_keeps_unlocked_path(self):
        player = self._class_player(PlayerClass.WARRIOR)
        player.unlocked_class_paths.add("warrior_heavy_knight")
        learn_talent(player, "heavy_knight_core")
        learn_talent(player, "heavy_shield_mastery")
        player.gold = 10_000
        cost = reset_talents(player)
        self.assertEqual(cost, 1500)
        self.assertEqual(player.talents, {})
        self.assertIn("warrior_heavy_knight", player.unlocked_class_paths)

    def test_heavy_knight_name_appears_after_core_talent(self):
        player = self._class_player(PlayerClass.WARRIOR)
        player.unlocked_class_paths.add("warrior_heavy_knight")
        learn_talent(player, "heavy_knight_core")
        self.assertEqual(specialization_name(player), "Ciężki Rycerz")

    def test_class_choice_equips_signature_weapon_and_offhand(self):
        expected = {
            PlayerClass.WARRIOR: ("starter_sword", "training_shield"),
            PlayerClass.HUNTER: ("hunting_bow", "simple_quiver"),
            PlayerClass.MAGE: ("apprentice_staff", "mana_crystal_artifact"),
            PlayerClass.PIERROT: ("caprice_lance", "worn_fate_dice"),
        }
        for player_class, (weapon_id, offhand_id) in expected.items():
            player = self._class_player(player_class, 5)
            self.assertEqual(player.equipment.get(EquipmentSlot.WEAPON).item_id, weapon_id)
            self.assertEqual(player.equipment.get(EquipmentSlot.OFF_HAND).item_id, offhand_id)

    def test_wrong_class_cannot_equip_class_weapon(self):
        mage = self._class_player(PlayerClass.MAGE)
        mage.inventory.add("black_sea_bow")
        with self.assertRaises(ValueError):
            mage.equip_from_inventory(len(mage.inventory.equipment_items) - 1)

    def test_luck_is_pierrot_only(self):
        warrior = self._class_player(PlayerClass.WARRIOR)
        warrior.unspent_attribute_points = 4
        with self.assertRaises(ValueError):
            warrior.spend_attribute_points(AttributeType.LUCK, 1)

        pierrot = self._class_player(PlayerClass.PIERROT)
        pierrot.unspent_attribute_points = 4
        pierrot.spend_attribute_points(AttributeType.LUCK, 4)
        self.assertEqual(pierrot.attributes.luck, 4)

    def test_heavy_knight_defend_prepares_def_based_retribution(self):
        player = self._class_player(PlayerClass.WARRIOR)
        player.unlocked_class_paths.add("warrior_heavy_knight")
        player.talents.update({"heavy_knight_core": 1, "heavy_bastion": 1})
        enemy = self._training_enemy(attack=0)
        engine = CombatEngine(player, enemy, DeterministicRng())
        defend = engine.player_defend()
        self.assertTrue(any("75% DEF" in note for note in defend.class_effect_notes))
        attack = engine.player_attack()
        self.assertTrue(any("ODWET" in note for note in attack.class_effect_notes))

    def test_mage_arcana_double_cast_uses_one_enemy_turn(self):
        player = self._class_player(PlayerClass.MAGE)
        player.unlocked_class_paths.add("mage_arcana")
        player.talents.update({"arcana_core": 1, "arcana_double_weave": 1})
        enemy = self._training_enemy(attack=0)
        engine = CombatEngine(player, enemy, DeterministicRng())

        for _ in range(3):
            engine.player_use_skill("fire_bolt")
        self.assertTrue(engine.can_double_cast())
        before = enemy.attacks_made
        report = engine.player_use_skill_pair("frost_lance", "lightning")
        self.assertEqual(enemy.attacks_made, before + 1)
        self.assertTrue(any("PODWÓJNY SPLOT" in note for note in report.class_effect_notes))
        self.assertTrue(any("80%" in note for note in report.class_effect_notes))

    def test_perfect_weave_raises_second_spell_to_ninety_five_percent(self):
        player = self._class_player(PlayerClass.MAGE)
        player.unlocked_class_paths.add("mage_arcana")
        player.talents.update({
            "arcana_core": 1,
            "arcana_double_weave": 1,
            "arcana_efficiency": 1,
            "arcana_perfect_weave": 1,
        })
        enemy = self._training_enemy(attack=0)
        engine = CombatEngine(player, enemy, DeterministicRng())
        engine._arcane_weave = 3
        report = engine.player_use_skill_pair("fire_bolt", "frost_lance")
        self.assertTrue(any("95%" in note for note in report.class_effect_notes))
        self.assertEqual(report.skill_mana_cost, 11)  # 6 + round(7*0.75)=5

    def test_hunter_techniques_do_not_consume_physical_ammo_items(self):
        player = self._class_player(PlayerClass.HUNTER)
        player.talents["hunter_frost_arrow"] = 1
        before = dict(player.inventory.stacks)
        enemy = self._training_enemy(attack=0)
        CombatEngine(player, enemy, DeterministicRng()).player_use_skill("frost_arrow")
        self.assertEqual(player.inventory.stacks, before)

    def test_hunter_phantom_arrow_echoes_after_next_action(self):
        player = self._class_player(PlayerClass.HUNTER)
        player.talents.update({"hunter_frost_arrow": 1, "hunter_phantom_arrow": 1})
        enemy = self._training_enemy(attack=0)
        engine = CombatEngine(player, enemy, DeterministicRng())
        first = engine.player_use_skill("phantom_arrow")
        self.assertTrue(any("WIDMOWE ECHO" in note for note in first.skill_notes))
        second = engine.player_attack()
        self.assertTrue(any("WIDMOWE ECHO materializuje" in note for note in second.skill_notes))

    def test_hunter_triple_phantom_discovers_named_combo(self):
        player = self._class_player(PlayerClass.HUNTER)
        player.talents.update({"hunter_frost_arrow": 1, "hunter_phantom_arrow": 1})
        enemy = self._training_enemy(attack=0)
        engine = CombatEngine(player, enemy, DeterministicRng())
        reports = [engine.player_use_skill("phantom_arrow") for _ in range(3)]
        self.assertIn("phantom_parade", player.discovered_hunter_combos)
        self.assertTrue(any("Parada Widm" in note for report in reports for note in report.class_effect_notes))

    def test_hunter_explosive_arrow_detonates_on_third_charge(self):
        player = self._class_player(PlayerClass.HUNTER)
        player.talents.update({"hunter_piercing_arrow": 1, "hunter_explosive_arrow": 1})
        enemy = self._training_enemy(attack=0)
        engine = CombatEngine(player, enemy, DeterministicRng())
        reports = [engine.player_use_skill("explosive_arrow") for _ in range(3)]
        self.assertTrue(any("DETONACJA 3/3" in note for note in reports[-1].skill_notes))
        self.assertEqual(engine._hunter_explosive_charges, 0)

    def test_pierrot_bad_roll_generates_fate_tokens(self):
        player = self._class_player(PlayerClass.PIERROT)
        enemy = self._training_enemy(attack=0)
        engine = CombatEngine(player, enemy, DeterministicRng(dice=[1]))
        report = engine.player_use_skill("fate_thrust")
        self.assertTrue(any("PECHOWY NUMER" in note for note in report.skill_notes))
        self.assertGreaterEqual(engine._fate_tokens, 2)

    def test_pierrot_lucky_seven_has_distinct_result(self):
        player = self._class_player(PlayerClass.PIERROT)
        enemy = self._training_enemy(attack=0)
        engine = CombatEngine(player, enemy, DeterministicRng(dice=[3, 4]))
        report = engine.player_use_skill("double_roll")
        self.assertTrue(any("SZCZĘŚLIWA SIÓDEMKA" in note for note in report.skill_notes))
        self.assertEqual(engine._fate_tokens, 2)

    def test_crooked_mirror_reflects_next_direct_attack(self):
        player = self._class_player(PlayerClass.PIERROT)
        player.talents.update({"pierrot_wild_roll": 1, "pierrot_crooked_mirror": 1})
        player.stats.defense = 0
        enemy = self._training_enemy(attack=12)
        engine = CombatEngine(player, enemy, DeterministicRng(dice=[3, 3]))
        before = enemy.current_hp
        report = engine.player_use_skill("double_roll")
        self.assertEqual(report.enemy_damage, 0)
        self.assertLess(enemy.current_hp, before)
        self.assertTrue(any("KRZYWE ZWIERCIADŁO" in note for note in report.class_effect_notes))

    def test_fate_engine_loaded_die_and_cheat_are_centralized(self):
        fate = FateEngine(DeterministicRng(dice=[1, 5, 3, 3]), luck=20)
        roll, spent = fate.roll(1, loaded_die=True)
        self.assertEqual(roll.dice, (5,))
        roll, spent = fate.roll(2, cheat_to_seven=True, fate_tokens=1)
        self.assertEqual(roll.total, 7)
        self.assertEqual(spent, 1)

    def test_pierrot_offhand_supports_dice_and_cards(self):
        self.assertEqual(get_item_definition("worn_fate_dice").equipment_type, "fate_dice")
        self.assertEqual(get_item_definition("trickster_card_deck").equipment_type, "fate_cards")
        self.assertEqual(get_item_definition("trickster_card_deck").slot, EquipmentSlot.OFF_HAND)

    def test_mage_offhand_is_artifact_not_focus(self):
        artifact = get_item_definition("mana_crystal_artifact")
        self.assertEqual(artifact.equipment_type, "artifact")
        self.assertIn("artefakt", artifact.description.lower())

    def test_class_weapons_cover_existing_progression_and_are_drop_only(self):
        recipe_outputs = {str(data["output_item_id"]) for data in RECIPE_DATA.values()}
        for region, pool in CLASS_WEAPON_POOLS.items():
            self.assertEqual(len(pool), 3, region)
            for item_id in pool:
                definition = get_item_definition(item_id)
                self.assertIsNotNone(definition.required_class_code)
                self.assertNotIn(item_id, recipe_outputs)

    def test_class_weapon_drop_uses_regional_pool_not_specific_weapon(self):
        rng = DeterministicRng(random_values=[0.0], choice_index=1)
        drop = roll_class_weapon_drop("venom_spider", "normal", elite=False, rng=rng)
        self.assertEqual(drop, CLASS_WEAPON_POOLS["blackwood"][1])

    def test_class_offhands_are_drop_only(self):
        recipe_outputs = {str(data["output_item_id"]) for data in RECIPE_DATA.values()}
        for item_id in CLASS_GEAR_POOL:
            self.assertNotIn(item_id, recipe_outputs)

    def test_crafting_every_recipe_has_one_of_visible_categories(self):
        recipes = get_all_recipes()
        allowed = set(CRAFTING_CATEGORIES)
        self.assertTrue(recipes)
        self.assertTrue(all(recipe.crafting_category in allowed for recipe in recipes))
        reconstructed = []
        for category in CRAFTING_CATEGORIES:
            reconstructed.extend(recipes_for_category(recipes, category))
        self.assertEqual(len(reconstructed), len(recipes))

    def test_guild_rumors_unlock_kingdom_book_ban_with_rank(self):
        novice = available_guild_rumors("F", market_unlocked=False, milestones=set())
        seeker = available_guild_rumors("D", market_unlocked=False, milestones=set())
        self.assertFalse(any("zakaz" in rumor.text.lower() and "ksi" in rumor.text.lower() for rumor in novice))
        self.assertTrue(any("zakaz" in rumor.text.lower() and "ksi" in rumor.text.lower() for rumor in seeker))

    def test_black_market_can_rotate_path_books_but_not_every_rotation(self):
        market = BlackMarketState(unlocked=True)
        seen_path = False
        seen_no_path = False
        start = date(2026, 1, 1)
        for offset in range(0, 80):
            ensure_black_market_rotation(market, "Tester", today=start + timedelta(days=offset))
            ids = {offer.item_id for offer in market.offers}
            has_path = bool(ids.intersection(PATH_UNLOCK_BOOK_IDS))
            seen_path |= has_path
            seen_no_path |= not has_path
            if seen_path and seen_no_path:
                break
        self.assertTrue(seen_path)
        self.assertTrue(seen_no_path)

    def test_passive_specialization_requires_mastery_ten_and_is_saved_on_player(self):
        player = self._class_player(PlayerClass.WARRIOR)
        player.passive_masteries.add(PassiveType.INCREASED_ATTACK.code)
        player.passives.increased_attack = 10
        choose_passive_specialization(player, PassiveType.INCREASED_ATTACK, "raw_strength")
        self.assertEqual(player.passive_specializations["increased_attack"], "raw_strength")

    def test_v12_migration_equips_hunter_bow_and_preserves_old_weapon(self):
        player = create_player("LegacyHunter")
        player.level = 18
        player.character_class = PlayerClass.HUNTER
        state = GameState(active_game=True, player=player)
        with tempfile.TemporaryDirectory() as temp:
            save_dir = Path(temp)
            save_path = save_dir / "save.json"
            with patch("systems.save_system.get_save_directory", return_value=save_dir), patch(
                "systems.save_system.get_save_path", return_value=save_path
            ):
                save_game(state)
                payload = json.loads(save_path.read_text(encoding="utf-8"))
                payload["schema_version"] = 12
                payload["game_version"] = "0.22.0"
                for key in ("talents", "unlocked_class_paths", "discovered_hunter_combos", "passive_specializations"):
                    payload["player"].pop(key, None)
                payload["player"]["attributes"].pop("luck", None)
                save_path.write_text(json.dumps(payload), encoding="utf-8")
                loaded = load_game()

        self.assertEqual(loaded.player.equipment.get(EquipmentSlot.WEAPON).item_id, "hunting_bow")
        self.assertEqual(loaded.player.equipment.get(EquipmentSlot.OFF_HAND).item_id, "simple_quiver")
        self.assertIn("starter_sword", [item.item_id for item in loaded.player.inventory.equipment_items])

    def test_v023_save_roundtrip_preserves_talents_paths_luck_and_combos(self):
        player = self._class_player(PlayerClass.PIERROT)
        player.attributes.luck = 17
        player.talents["pierrot_wild_roll"] = 1
        player.unlocked_class_paths.add("pierrot_fortuna")
        player.discovered_hunter_combos.add("phantom_parade")
        state = GameState(active_game=True, player=player)
        with tempfile.TemporaryDirectory() as temp:
            save_dir = Path(temp)
            save_path = save_dir / "save.json"
            with patch("systems.save_system.get_save_directory", return_value=save_dir), patch(
                "systems.save_system.get_save_path", return_value=save_path
            ):
                save_game(state)
                loaded = load_game()
        self.assertEqual(loaded.player.attributes.luck, 17)
        self.assertEqual(loaded.player.talents["pierrot_wild_roll"], 1)
        self.assertIn("pierrot_fortuna", loaded.player.unlocked_class_paths)
        self.assertIn("phantom_parade", loaded.player.discovered_hunter_combos)

    def test_pierrot_fate_skills_are_marked_offensive_except_feint(self):
        self.assertTrue(get_skill("fate_thrust").is_offensive)
        self.assertTrue(get_skill("double_roll").is_offensive)
        self.assertFalse(get_skill("fate_feint").is_offensive)


if __name__ == "__main__":
    unittest.main()
