from datetime import date
import unittest

from player.factory import create_player
from quests.contracts import (
    ContractBoard,
    ContractObjectiveType,
)
from systems.contracts import (
    claim_contract,
    contract_is_ready,
    ensure_contract_board,
    objective_progress,
    record_contract_victory,
    record_dungeon_completion,
)


class ContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.player = create_player("Tester")
        self.player.level = 12
        self.board = ContractBoard()
        ensure_contract_board(
            self.board,
            self.player,
            today=date(2026, 8, 9),
        )

    def test_three_dailies_and_one_weekly_are_generated(self) -> None:
        self.assertEqual(len(self.board.daily_contracts), 3)
        self.assertIsNotNone(self.board.weekly_contract)
        self.assertEqual(self.board.daily_date, "2026-08-09")
        self.assertEqual(self.board.weekly_key, "2026-W32")

    def test_same_day_does_not_reroll_contracts(self) -> None:
        before = list(self.board.daily_contracts)

        messages = ensure_contract_board(
            self.board,
            self.player,
            today=date(2026, 8, 9),
        )

        self.assertEqual(messages, [])
        self.assertEqual(self.board.daily_contracts, before)

    def test_next_day_same_week_refreshes_only_daily(self) -> None:
        board = ContractBoard()
        ensure_contract_board(
            board,
            self.player,
            today=date(2026, 8, 11),
        )
        weekly_before = board.weekly_contract
        daily_ids_before = {
            contract.contract_id
            for contract in board.daily_contracts
        }

        ensure_contract_board(
            board,
            self.player,
            today=date(2026, 8, 12),
        )

        daily_ids_after = {
            contract.contract_id
            for contract in board.daily_contracts
        }
        self.assertNotEqual(daily_ids_before, daily_ids_after)
        self.assertEqual(
            board.weekly_contract,
            weekly_before,
        )

    def test_new_iso_week_refreshes_weekly(self) -> None:
        old_id = self.board.weekly_contract.contract_id

        ensure_contract_board(
            self.board,
            self.player,
            today=date(2026, 8, 10),
        )

        self.assertNotEqual(
            self.board.weekly_contract.contract_id,
            old_id,
        )
        self.assertEqual(
            self.board.weekly_contract.period_key,
            "2026-W33",
        )

    def test_collect_daily_consumes_material_on_claim(self) -> None:
        contract = self.board.daily_contracts[1]
        objective = contract.objectives[0]
        self.assertEqual(
            objective.objective_type,
            ContractObjectiveType.COLLECT,
        )

        item_id = str(objective.target_id)
        self.player.inventory.add(
            item_id,
            objective.required_count,
        )

        gold_before = self.player.gold
        result = claim_contract(
            self.player,
            self.board,
            contract.contract_id,
        )

        self.assertEqual(
            self.player.inventory.count(item_id),
            0,
        )
        self.assertEqual(
            self.player.gold,
            gold_before + contract.reward_gold,
        )
        self.assertEqual(result.title, contract.title)
        self.assertIn(
            contract.contract_id,
            self.board.daily_claimed,
        )

    def test_daily_reward_cannot_be_claimed_twice(self) -> None:
        contract = self.board.daily_contracts[1]
        objective = contract.objectives[0]
        self.player.inventory.add(
            str(objective.target_id),
            objective.required_count,
        )

        claim_contract(
            self.player,
            self.board,
            contract.contract_id,
        )

        with self.assertRaises(ValueError):
            claim_contract(
                self.player,
                self.board,
                contract.contract_id,
            )

    def test_elite_daily_tracks_only_real_elite_variants(self) -> None:
        contract = self.board.daily_contracts[2]
        objective = contract.objectives[0]
        self.assertEqual(
            objective.objective_type,
            ContractObjectiveType.KILL_ELITE_REGION,
        )

        region_id = str(objective.target_id)

        record_contract_victory(
            self.player,
            self.board,
            enemy_id="wolf",
            region_id=region_id,
            is_miniboss=False,
            elite_modifier_id=None,
        )
        current, _ = objective_progress(
            self.player,
            self.board,
            contract,
            0,
        )
        self.assertEqual(current, 0)

        for _ in range(objective.required_count):
            record_contract_victory(
                self.player,
                self.board,
                enemy_id="wolf",
                region_id=region_id,
                is_miniboss=False,
                elite_modifier_id="furious",
            )

        self.assertTrue(
            contract_is_ready(
                self.player,
                self.board,
                contract,
            )
        )

    def test_weekly_has_multiple_objectives_and_dungeon(self) -> None:
        contract = self.board.weekly_contract
        objective_types = {
            objective.objective_type
            for objective in contract.objectives
        }

        self.assertGreaterEqual(len(contract.objectives), 3)
        self.assertIn(
            ContractObjectiveType.KILL_REGION,
            objective_types,
        )
        self.assertIn(
            ContractObjectiveType.KILL_ELITE,
            objective_types,
        )
        self.assertIn(
            ContractObjectiveType.COMPLETE_DUNGEON,
            objective_types,
        )

    def test_dungeon_completion_updates_weekly(self) -> None:
        contract = self.board.weekly_contract
        index = next(
            index
            for index, objective
            in enumerate(contract.objectives)
            if objective.objective_type
            is ContractObjectiveType.COMPLETE_DUNGEON
        )

        updates = record_dungeon_completion(
            self.player,
            self.board,
            "sunken_order_crypt",
        )
        current, required = objective_progress(
            self.player,
            self.board,
            contract,
            index,
        )

        self.assertEqual((current, required), (1, 1))
        self.assertTrue(
            any(
                update.objective_index == index
                for update in updates
            )
        )

    def test_daily_gold_rewards_do_not_recreate_inflation(self) -> None:
        total = sum(
            contract.reward_gold
            for contract in self.board.daily_contracts
        )
        self.assertLessEqual(total, 600)

    def test_clock_rollback_does_not_reroll_board(self) -> None:
        before = list(self.board.daily_contracts)

        messages = ensure_contract_board(
            self.board,
            self.player,
            today=date(2026, 8, 8),
        )

        self.assertEqual(messages, [])
        self.assertEqual(self.board.daily_contracts, before)


if __name__ == "__main__":
    unittest.main()
