import unittest

from player.factory import create_player
from quests.models import QuestLog
from systems.quest_system import (
    accept_quest,
    record_enemy_kill,
    turn_in_quest,
)


class MotherQuestRewardTests(unittest.TestCase):
    def test_mother_quest_rewards_potions_not_second_heart(self) -> None:
        player = create_player("Tester")
        log = QuestLog()

        accept_quest(log, "mother_below")
        record_enemy_kill(log, "drowned_mother")
        turn_in_quest(player, log, "mother_below")

        self.assertEqual(
            player.inventory.count("strong_healing_potion"),
            3,
        )
        self.assertEqual(
            player.inventory.count("silentwater_heart"),
            0,
        )


if __name__ == "__main__":
    unittest.main()
