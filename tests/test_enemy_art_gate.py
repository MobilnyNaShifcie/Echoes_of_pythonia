from types import SimpleNamespace

import pytest
from PIL import Image, ImageDraw

from scripts import build_art_reference_board as board


def source_png(root, mode="RGBA", bounds=(8, 8, 91, 91)):
    path = root / "godot/assets/combat/enemies/test.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    background = (0, 0, 0, 0) if mode == "RGBA" else (0, 0, 0)
    with Image.new(mode, (100, 100), background) as image:
        if bounds is not None:
            ImageDraw.Draw(image).rectangle(bounds, fill="white")
        image.save(path)
    return path.relative_to(root).as_posix()


def test_rgba_source_reports_canvas_margins_and_fingerprint(tmp_path):
    relative = source_png(tmp_path)
    result = board.inspect_enemy_source(tmp_path, relative)
    assert result["status"] == "PASS"
    assert result["alpha_bounds"] == (8, 8, 92, 92)
    assert result["margin_fractions_ltrb"] == [0.08] * 4
    assert result["corner_alpha"] == [0] * 4
    assert len(result["sha256"]) == 64


@pytest.mark.parametrize("bounds", [
    (1, 8, 91, 91), (8, 1, 91, 91), (8, 8, 98, 91), (8, 8, 91, 98),
])
def test_one_pixel_margin_cannot_pass_as_safe_padding(tmp_path, bounds):
    relative = source_png(tmp_path, bounds=bounds)
    assert board.inspect_enemy_source(tmp_path, relative)["status"] == "FAIL"


@pytest.mark.parametrize("mode,bounds", [
    ("RGB", (8, 8, 91, 91)), ("RGBA", None), ("RGBA", (0, 0, 99, 99)),
])
def test_opaque_empty_and_edge_touching_sources_fail(tmp_path, mode, bounds):
    relative = source_png(tmp_path, mode=mode, bounds=bounds)
    assert board.inspect_enemy_source(tmp_path, relative)["status"] == "FAIL"


def test_five_percent_margin_is_accepted(tmp_path):
    relative = source_png(tmp_path, bounds=(5, 5, 94, 94))
    assert board.inspect_enemy_source(tmp_path, relative)["status"] == "PASS"


def test_scenario_manifest_requires_both_mappings_and_valid_source(tmp_path):
    relative = source_png(tmp_path)
    policy = {
        "scenario_regions": {"combat_test": "ice_coast"},
        "scenario_enemies": {"combat_test": relative},
    }
    record = board.scenario_manifest(tmp_path, policy, "combat_test")
    assert record["enemy_source"] == relative
    assert record["region"] == "ice_coast"
    assert record["enemy_checks"]["status"] == "PASS"
    with pytest.raises(ValueError):
        board.scenario_manifest(tmp_path, policy, "combat_unknown")
    policy["scenario_enemies"]["combat_test"] = "godot/assets/../../outside.png"
    with pytest.raises(ValueError):
        board.scenario_manifest(tmp_path, policy, "combat_test")


def test_changed_and_untracked_enemies_require_mapping(tmp_path, monkeypatch):
    mapped = "godot/assets/combat/enemies/mapped.png"
    changed = "godot/assets/combat/enemies/changed.png"
    untracked = "godot/assets/combat/enemies/new.png"
    calls = []

    def git_result(command, **kwargs):
        calls.append(command)
        paths = [mapped, changed] if command[1] == "diff" else [untracked]
        return SimpleNamespace(stdout=("\0".join(paths) + "\0").encode("utf-8"))

    monkeypatch.setattr(board.subprocess, "run", git_result)
    policy = {"scenario_enemies": {"combat_mapped": mapped}}
    assert board.unmapped_enemy_sources(tmp_path, policy, "review-base") == [changed, untracked]
    assert "review-base" in calls[0]
    assert "--others" in calls[1]
