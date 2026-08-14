import io
import unittest
from contextlib import redirect_stdout

from data.dungeon_narrative import BLACK_FLEET_NARRATIVE
from player.factory import create_player
from ui.dungeon_view import (
    show_black_fleet_treasury,
    show_dungeon_scene,
    show_medical_cabin_result,
)
from world.dungeon import create_dungeon


class BlackFleetAtmosphereV0215Tests(unittest.TestCase):
    def test_black_fleet_has_all_major_narrative_beats(self) -> None:
        expected = {
            "entrance",
            "frozen_deck",
            "wreck_passage",
            "cargo_hold",
            "upper_deck",
            "officer_quarters",
            "first_officer_intro",
            "flagship_approach",
            "varek_intro",
        }
        self.assertTrue(expected <= set(BLACK_FLEET_NARRATIVE))
        for key in expected:
            self.assertGreater(len(BLACK_FLEET_NARRATIVE[key]), 90)

    def test_first_officer_and_varek_have_distinct_introductions(self) -> None:
        officer = BLACK_FLEET_NARRATIVE["first_officer_intro"]
        varek = BLACK_FLEET_NARRATIVE["varek_intro"]
        self.assertIn("Admirał nie przyjmuje gości", officer)
        self.assertIn("Moja flota jeszcze nie zatonęła", varek)
        self.assertIn("widmowi kanonierzy", varek)

    def test_flagship_approach_uses_black_fleet_identity(self) -> None:
        text = BLACK_FLEET_NARRATIVE["flagship_approach"]
        self.assertIn("okręt flagowy", text)
        self.assertIn("Czarnej Floty", text)
        self.assertIn("Jeden raz", text)
        self.assertIn("Trzeci", text)

    def test_dungeon_scene_renders_multiline_narrative(self) -> None:
        out = io.StringIO()
        with redirect_stdout(out):
            show_dungeon_scene(
                "Cmentarzysko Okrętów",
                BLACK_FLEET_NARRATIVE["entrance"],
            )
        text = out.getvalue()
        self.assertIn("CMENTARZYSKO OKRĘTÓW", text)
        self.assertIn("połamane maszty", text.lower())
        self.assertIn("Medalion Czarnej Floty", text)

    def test_black_fleet_entrance_description_is_more_than_rules_text(self) -> None:
        dungeon = create_dungeon("black_fleet_wreck")
        self.assertIn("Połamane maszty", dungeon.description)
        self.assertIn("czarne bandery", dungeon.description)
        self.assertIn("Admirała Vareka", dungeon.description)

    def test_treasury_has_narrative_intro_even_when_empty(self) -> None:
        out = io.StringIO()
        with redirect_stdout(out):
            show_black_fleet_treasury([])
        text = out.getvalue()
        self.assertIn("Ciężkie drzwi ustępują z jękiem", text)
        self.assertIn("pieczęciami Czarnej Floty", text)
        self.assertIn("Skarbiec został już dawno ograbiony", text)

    def test_medical_cabin_result_still_keeps_mechanics_unchanged(self) -> None:
        # Atmospheric pass must not alter the existing 30% restoration mechanic.
        player = create_player("Tester")
        player.stats.max_hp = 100
        player.stats.current_hp = 10
        player.stats.max_mana = 100
        player.stats.current_mana = 10
        from world.dungeon import use_medical_cabin

        healed, restored = use_medical_cabin(player)
        self.assertEqual((healed, restored), (30, 30))

        out = io.StringIO()
        with redirect_stdout(out):
            show_medical_cabin_result(healed, restored)
        self.assertIn("30 HP", out.getvalue())
        self.assertIn("30 Many", out.getvalue())


if __name__ == "__main__":
    unittest.main()
