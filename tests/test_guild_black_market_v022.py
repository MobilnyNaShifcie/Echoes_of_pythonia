import random
import unittest
from datetime import date, timedelta

from data.books import MASTERY_BOOK_IDS, get_book_definition
from data.guild import GUILD_RANK_BY_CODE
from player.factory import create_player
from quests.models import QuestLog
from systems.black_market import (
    BlackMarketState,
    bargain_book_sale,
    bargain_buy,
    buy_black_market_offer,
    check_informant_for_day,
    effective_buy_price,
    ensure_black_market_rotation,
    informant_eligible,
    sell_mastery_book,
    unlock_black_market,
)
from systems.guild_progression import (
    GuildProgress,
    current_guild_rank,
    record_contract_reputation,
    record_guild_milestone,
    record_story_quest_reputation,
)


class FixedRandom(random.Random):
    def __init__(self, values):
        super().__init__(1)
        self.values = iter(values)

    def random(self):
        return next(self.values)


class GuildProgressionV022Tests(unittest.TestCase):
    def test_rank_thresholds_are_f_to_s(self):
        expectations = {
            0: "F", 99: "F", 100: "E", 300: "D", 700: "C",
            1400: "B", 2600: "A", 4500: "S",
        }
        for reputation, code in expectations.items():
            with self.subTest(reputation=reputation):
                self.assertEqual(current_guild_rank(GuildProgress(reputation)).code, code)

    def test_story_contract_and_milestone_reputation_are_one_time(self):
        progress = GuildProgress()
        self.assertEqual(record_story_quest_reputation(progress, "quest_a").amount, 50)
        self.assertIsNone(record_story_quest_reputation(progress, "quest_a"))
        self.assertEqual(record_contract_reputation(progress, "daily-2026-08-12-hunt").amount, 15)
        self.assertIsNone(record_contract_reputation(progress, "daily-2026-08-12-hunt"))
        self.assertEqual(record_guild_milestone(progress, "dungeon:black_fleet_wreck").amount, 250)
        self.assertIsNone(record_guild_milestone(progress, "dungeon:black_fleet_wreck"))

    def test_black_market_contact_requires_rank_c_and_dungeon(self):
        progress = GuildProgress(reputation=700, milestones={"dungeon:sunken_order_crypt"})
        self.assertTrue(informant_eligible(progress, QuestLog()))
        progress.reputation = 699
        self.assertFalse(informant_eligible(progress, QuestLog()))

    def test_informant_has_pity_after_four_failed_daily_checks(self):
        progress = GuildProgress(reputation=700, milestones={"dungeon:sunken_order_crypt"})
        market = BlackMarketState()
        rng = FixedRandom([0.99, 0.99, 0.99, 0.99])
        for day in range(1, 5):
            self.assertFalse(check_informant_for_day(market, progress, QuestLog(), day, rng))
        # Fifth eligible day is guaranteed without consuming another random roll.
        self.assertTrue(check_informant_for_day(market, progress, QuestLog(), 5, rng))

    def test_informant_does_not_reroll_same_day(self):
        progress = GuildProgress(reputation=700, milestones={"dungeon:black_fleet_wreck"})
        market = BlackMarketState()
        rng = FixedRandom([0.01])
        self.assertTrue(check_informant_for_day(market, progress, QuestLog(), 12, rng))
        self.assertTrue(check_informant_for_day(market, progress, QuestLog(), 12, rng))

    def test_market_rotation_is_stable_for_same_period(self):
        market = BlackMarketState(unlocked=True)
        changed = ensure_black_market_rotation(market, "Mobilny", today=date(2026, 8, 12))
        self.assertTrue(changed)
        first = list(market.offers)
        changed = ensure_black_market_rotation(market, "Mobilny", today=date(2026, 8, 12))
        self.assertFalse(changed)
        self.assertEqual(market.offers, first)
        self.assertEqual(len(market.offers), 4)

    def test_black_market_rotates_on_next_real_day(self):
        market = BlackMarketState(unlocked=True)
        first_day = date(2026, 8, 12)
        self.assertTrue(ensure_black_market_rotation(market, "Mobilny", today=first_day))
        first_key = market.rotation_key
        self.assertTrue(
            ensure_black_market_rotation(
                market, "Mobilny", today=first_day + timedelta(days=1)
            )
        )
        self.assertNotEqual(market.rotation_key, first_key)

    def test_bargain_is_one_attempt_per_buy_offer(self):
        player = create_player("Tester")
        player.gold = 100_000
        market = BlackMarketState(unlocked=True)
        ensure_black_market_rotation(market, player.name, today=date(2026, 8, 12))
        offer = market.offers[0]
        result = bargain_buy(market, offer, FixedRandom([0.0, 0.0]))
        self.assertTrue(result.success)
        self.assertLess(result.new_price, result.old_price)
        with self.assertRaises(ValueError):
            bargain_buy(market, offer, random.Random(2))

    def test_purchase_is_single_stock_and_adds_item(self):
        player = create_player("Tester")
        player.gold = 100_000
        market = BlackMarketState(unlocked=True)
        ensure_black_market_rotation(market, player.name, today=date(2026, 8, 12))
        offer = market.offers[0]
        paid = buy_black_market_offer(player, market, offer)
        self.assertEqual(player.inventory.count(offer.item_id), offer.quantity)
        self.assertEqual(paid, offer.base_price)
        with self.assertRaises(ValueError):
            buy_black_market_offer(player, market, offer)

    def test_books_can_be_sold_on_black_market_and_haggled(self):
        player = create_player("Tester")
        item_id = MASTERY_BOOK_IDS[0]
        player.inventory.add(item_id, 2)
        market = BlackMarketState(unlocked=True)
        result = bargain_book_sale(market, item_id, FixedRandom([0.0, 0.0]))
        self.assertTrue(result.success)
        before = player.gold
        earned = sell_mastery_book(player, market, item_id)
        self.assertGreater(earned, get_book_definition(item_id).sell_price)
        self.assertEqual(player.gold, before + earned)
        self.assertEqual(player.inventory.count(item_id), 1)


if __name__ == "__main__":
    unittest.main()
