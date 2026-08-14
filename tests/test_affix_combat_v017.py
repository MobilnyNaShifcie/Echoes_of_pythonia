import unittest

from combat.combat import CombatEngine
from enemies.factory import create_enemy
from items.affixes import affix_value_for_tier
from items.models import AffixRoll, EquipmentItem, EquipmentSlot
from player.factory import create_player


class NoDodgeCritRng:
    def random(self) -> float:
        return 0.99


class AlwaysCritRng:
    def random(self) -> float:
        return 0.0


class AffixCombatV017Tests(unittest.TestCase):
    def test_crit_chance_affix_unlocks_crits_without_passive(self) -> None:
        player = create_player("Tester")
        value = affix_value_for_tier(
            "crit_chance", 4, 5, EquipmentSlot.RING
        )
        ring = EquipmentItem(
            "abyss_ring",
            item_power=4,
            affixes=[AffixRoll("crit_chance", 5, value)],
        )
        player.equipment.equip_and_return_previous(ring)
        player.recalculate_stats()

        enemy = create_enemy("corrupted_bear")
        combat = CombatEngine(player, enemy, AlwaysCritRng())
        report = combat.player_attack()
        self.assertTrue(report.player_critical)

    def test_boss_damage_affix_increases_real_damage(self) -> None:
        base_player = create_player("Base")
        buffed_player = create_player("Buffed")
        value = affix_value_for_tier(
            "damage_vs_boss", 4, 5, EquipmentSlot.RING
        )
        ring = EquipmentItem(
            "abyss_ring",
            item_power=4,
            affixes=[AffixRoll("damage_vs_boss", 5, value)],
        )
        buffed_player.equipment.equip_and_return_previous(ring)
        buffed_player.recalculate_stats()

        base_enemy = create_enemy("nature_guardian")
        buffed_enemy = create_enemy("nature_guardian")
        base = CombatEngine(base_player, base_enemy, NoDodgeCritRng())
        buffed = CombatEngine(buffed_player, buffed_enemy, NoDodgeCritRng())

        self.assertGreater(
            buffed.player_attack().player_damage,
            base.player_attack().player_damage,
        )

    def test_skill_damage_affix_increases_skill_hit(self) -> None:
        from player.classes import PlayerClass

        base_player = create_player("Base")
        buffed_player = create_player("Buffed")
        for player in (base_player, buffed_player):
            player.level = 12
            player.choose_class(PlayerClass.WARRIOR)
            player.stats.current_mana = player.stats.max_mana

        value = affix_value_for_tier(
            "skill_damage", 4, 5, EquipmentSlot.RING
        )
        ring = EquipmentItem(
            "abyss_ring",
            item_power=4,
            affixes=[AffixRoll("skill_damage", 5, value)],
        )
        buffed_player.equipment.equip_and_return_previous(ring)
        buffed_player.recalculate_stats()
        buffed_player.stats.current_mana = buffed_player.stats.max_mana

        base_enemy = create_enemy("drowned_mother")
        buffed_enemy = create_enemy("drowned_mother")
        base = CombatEngine(base_player, base_enemy, NoDodgeCritRng())
        buffed = CombatEngine(buffed_player, buffed_enemy, NoDodgeCritRng())

        self.assertGreater(
            buffed.player_use_skill("power_slash").player_damage,
            base.player_use_skill("power_slash").player_damage,
        )


if __name__ == "__main__":
    unittest.main()
