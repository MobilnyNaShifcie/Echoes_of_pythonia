from datetime import date
import unittest

from player.factory import create_player
from quests.contracts import ContractBoard, ContractObjectiveType
from systems.contracts import ensure_contract_board


class ContractV021Tests(unittest.TestCase):
    def test_high_level_weekly_uses_black_fleet_wreck(self) -> None:
        player = create_player("Tester")
        player.level = 17
        board = ContractBoard()
        ensure_contract_board(board, player, today=date(2026, 8, 10))
        contract = board.weekly_contract
        self.assertIsNotNone(contract)
        targets = [
            objective.target_id
            for objective in contract.objectives
            if objective.objective_type is ContractObjectiveType.COMPLETE_DUNGEON
        ]
        self.assertEqual(targets, ["black_fleet_wreck"])


if __name__ == "__main__":
    unittest.main()
