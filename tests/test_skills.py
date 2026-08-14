import unittest

from data.skills import CLASS_SKILL_ORDER, SKILL_DATA
from player.classes import PLAYABLE_CLASSES, PlayerClass
from player.factory import create_player
from player.skills import get_skill, skills_for_class, unlocked_skills


class SkillCatalogTests(unittest.TestCase):
    def test_every_class_has_four_skills(self) -> None:
        for player_class in PLAYABLE_CLASSES:
            self.assertEqual(
                len(skills_for_class(player_class)),
                4,
                player_class.display_name,
            )

    def test_skill_order_references_existing_skills(self) -> None:
        for skill_ids in CLASS_SKILL_ORDER.values():
            for skill_id in skill_ids:
                self.assertIn(skill_id, SKILL_DATA)

    def test_skill_definitions_have_valid_values(self) -> None:
        for skill_id in SKILL_DATA:
            skill = get_skill(skill_id)
            self.assertGreaterEqual(skill.unlock_level, 5)
            self.assertGreater(skill.mana_cost, 0)
            self.assertGreaterEqual(skill.hits, 0)
            self.assertIn(skill.player_class, PLAYABLE_CLASSES)

    def test_skills_unlock_at_expected_character_levels(self) -> None:
        player = create_player("Tester")
        player.level = 5
        player.choose_class(PlayerClass.WARRIOR)

        self.assertEqual(
            [skill.skill_id for skill in unlocked_skills(player)],
            ["power_slash"],
        )

        player.level = 9

        self.assertEqual(
            [skill.skill_id for skill in unlocked_skills(player)],
            [
                "power_slash",
                "armor_break",
                "defensive_stance",
            ],
        )


if __name__ == "__main__":
    unittest.main()
