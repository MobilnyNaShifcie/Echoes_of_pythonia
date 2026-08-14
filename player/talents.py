from __future__ import annotations

from data.talents import CLASS_PATHS, TALENT_DATA, TalentDefinition


def total_tree_points_for_level(level: int, has_class: bool) -> int:
    if not has_class or level < 5:
        return 0
    return 1 + max(0, (level - 4) // 2)


def spent_tree_points(talents: dict[str, int]) -> int:
    return sum(max(0, int(rank)) for rank in talents.values())


def available_tree_points(player) -> int:
    return max(
        0,
        total_tree_points_for_level(player.level, player.character_class.code != "none")
        - spent_tree_points(player.talents),
    )


def talent_rank(player, talent_id: str) -> int:
    return int(player.talents.get(talent_id, 0))


def has_talent(player, talent_id: str, rank: int = 1) -> bool:
    return talent_rank(player, talent_id) >= rank


def path_is_unlocked(player, path_id: str) -> bool:
    path = CLASS_PATHS[path_id]
    if path.class_code != player.character_class.code:
        return False
    return path.book_item_id is None or path_id in player.unlocked_class_paths


def talent_can_be_learned(player, talent: TalentDefinition) -> tuple[bool, str]:
    if talent.class_code != player.character_class.code:
        return False, "Talent nie należy do twojej klasy."
    if not path_is_unlocked(player, talent.path_id):
        return False, "Ta ścieżka wymaga Księgi Ścieżki."
    current = talent_rank(player, talent.talent_id)
    if current >= talent.max_rank:
        return False, "Talent ma już maksymalną rangę."
    if available_tree_points(player) <= 0:
        return False, "Brak wolnych punktów drzewka."
    for required_id, required_rank in talent.prerequisites:
        if talent_rank(player, required_id) < required_rank:
            required = TALENT_DATA[required_id]
            return False, f"Wymaga: {required.name} {required_rank}/{required.max_rank}."
    return True, ""


def learn_talent(player, talent_id: str) -> int:
    try:
        talent = TALENT_DATA[talent_id]
    except KeyError as error:
        raise KeyError(f"Nieznany talent: {talent_id}") from error
    allowed, reason = talent_can_be_learned(player, talent)
    if not allowed:
        raise ValueError(reason)
    new_rank = talent_rank(player, talent_id) + 1
    player.talents[talent_id] = new_rank
    player.recalculate_stats()
    return new_rank


def reset_tree_cost(player) -> int:
    spent = spent_tree_points(player.talents)
    return 1000 + spent * 250


def reset_talents(player) -> int:
    cost = reset_tree_cost(player)
    if player.gold < cost:
        raise ValueError(f"Brakuje Golda. Potrzeba {cost}, masz {player.gold}.")
    player.gold -= cost
    player.talents.clear()
    player.recalculate_stats()
    return cost


def specialization_name(player) -> str | None:
    # Specjalizacja pojawia się dopiero po faktycznym wejściu w kluczowy talent ścieżki.
    core_talents = {
        "heavy_knight_core": "warrior_heavy_knight",
        "phantom_archer_core": "hunter_phantom_archer",
        "arcana_core": "mage_arcana",
        "fortuna_core": "pierrot_fortuna",
    }
    for talent_id, path_id in core_talents.items():
        if has_talent(player, talent_id):
            return CLASS_PATHS[path_id].specialization_name
    return None


def active_skill_talent_ids(player) -> set[str]:
    result: set[str] = set()
    for talent in TALENT_DATA.values():
        if talent.active_skill_id and has_talent(player, talent.talent_id):
            result.add(talent.active_skill_id)
    return result
