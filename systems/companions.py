from __future__ import annotations

import copy
import hashlib
import random
from typing import Iterable
from uuid import uuid4

from companions.models import (
    Companion,
    CompanionCandidate,
    FallenCompanion,
    PartyMessage,
    PartyState,
    COMPANION_TACTICS,
)
from data.companions import CANDIDATE_CONVERSATIONS, COMPANION_TEMPLATES, PAIR_BANTER, CompanionTemplate
from data.guild import GUILD_RANKS
from data.items import ITEM_DATA
from data.talents import CLASS_PATH_ORDER, CLASS_PATHS, TALENT_DATA, talents_for_path
from items.affixes import EquipmentQuality, generate_equipment_item
from items.catalog import get_item_definition
from items.models import EquipmentItem, EquipmentSlot
from player.attributes import Attributes
from player.classes import PlayerClass, player_class_from_code
from player.inventory import Inventory
from player.player import Player
from player.talents import total_tree_points_for_level

MAX_COMPANIONS = 4
MAX_ACTIVE_COMPANIONS = 3
CANDIDATES_PER_DAY = 2
CANDIDATE_LEVEL_DELTA = 8

_RANK_INDEX = {rank.code: index for index, rank in enumerate(GUILD_RANKS)}

_CLASS_ATTRIBUTE_WEIGHTS: dict[str, tuple[float, float, float, float, float, float]] = {
    # STR, VIT, INT, DEX, END, SZCZĘŚCIE
    "warrior": (0.34, 0.24, 0.00, 0.08, 0.34, 0.00),
    "hunter": (0.28, 0.18, 0.00, 0.40, 0.14, 0.00),
    "mage": (0.00, 0.20, 0.50, 0.14, 0.16, 0.00),
    "pierrot": (0.18, 0.16, 0.00, 0.24, 0.06, 0.36),
}

_CLASS_WEAPONS: dict[str, tuple[tuple[int, str], ...]] = {
    "warrior": ((0, "starter_sword"), (5, "executioner_axe"), (8, "drowned_mother_blade"), (14, "azhar_blade"), (20, "varek_sabre")),
    "hunter": ((5, "hunting_bow"), (6, "blackwood_longbow"), (9, "mireglass_bow"), (14, "ashwind_bow"), (17, "black_sea_bow")),
    "mage": ((5, "apprentice_staff"), (6, "blackwood_staff"), (9, "mire_staff"), (14, "ember_staff"), (17, "black_sea_staff")),
    "pierrot": ((5, "caprice_lance"), (6, "crooked_fate_lance"), (9, "drowned_fate_lance"), (14, "ashen_fate_lance"), (17, "black_tide_fate_lance")),
}

_CLASS_OFFHANDS: dict[str, tuple[tuple[int, str], ...]] = {
    "warrior": ((5, "training_shield"), (14, "hearthguard_shield")),
    "hunter": ((5, "simple_quiver"), (14, "echo_quiver")),
    "mage": ((5, "mana_crystal_artifact"), (14, "weave_relic")),
    "pierrot": ((5, "worn_fate_dice"), (14, "trickster_card_deck")),
}

_GENERIC_SLOT_ITEMS: dict[EquipmentSlot, tuple[str, ...]] = {
    EquipmentSlot.HEAD: ("leather_hood", "rotting_knight_helm", "drowned_mother_crown", "azhar_crown"),
    EquipmentSlot.CHEST: ("worn_leather_armor", "stitched_armor", "blackwood_mail", "sunken_knight_armor", "wasteland_armor"),
    EquipmentSlot.HANDS: ("hunter_gloves", "spiderweave_gloves", "drowned_gauntlets", "hearth_gauntlets"),
    EquipmentSlot.FEET: ("reinforced_boots", "spiderstep_boots", "mirewalker_boots", "northern_trail_boots"),
    EquipmentSlot.BELT: ("leather_belt", "bearhide_belt", "scale_belt", "wasteland_belt"),
    EquipmentSlot.NECKLACE: ("wolf_tooth_necklace", "cultist_pendant", "drowned_mother_medallion", "sun_talisman"),
    EquipmentSlot.BRACELET: ("nature_bracelet", "order_bracelet", "captain_signet"),
    EquipmentSlot.EARRINGS: ("nature_earrings", "mist_earrings", "black_pearl_earrings"),
    EquipmentSlot.RING: ("nature_ring", "dark_sigil_ring", "witchbone_ring", "abyss_ring", "azhar_ring", "leviathan_ring"),
}

# Dodane w data/items.py przez v0.24. Kandydat ma niewielką szansę przyjść z
# unikatem, ale przed rekrutacją gracz widzi wyłącznie „Ekwipunek: nieznany”.
_RIFT_UNIQUES_BY_CLASS: dict[str, tuple[str, ...]] = {
    "warrior": ("rift_bastion_shield", "last_guard_plate", "oathbreaker_edge", "warden_chain"),
    "hunter": ("third_echo_quiver", "riftglass_bow", "silent_volley_cloak", "afterimage_ring"),
    "mage": ("split_weave_artifact", "twin_star_staff", "empty_mana_robe", "storm_archive_relic"),
    "pierrot": ("two_lies_dice", "deck_without_ace", "seven_chances_lance", "crooked_smile_mask"),
}


def _seed_int(*parts: object) -> int:
    text = "|".join(str(part) for part in parts)
    digest = hashlib.sha256(text.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")


def _choose_for_level(options: tuple[tuple[int, str], ...], level: int) -> str:
    chosen = options[0][1]
    for required, item_id in options:
        if level >= required:
            chosen = item_id
    return chosen


def _attributes_for_level(class_code: str, level: int, rng: random.Random) -> Attributes:
    points = max(0, int(level)) * 4
    weights = list(_CLASS_ATTRIBUTE_WEIGHTS[class_code])
    # Małe ręcznie kontrolowane odchylenie daje dwóm NPC tej samej klasy
    # różne profile, ale nie robi z Maga przypadkowego tanka STR.
    jitter = [max(0.0, weight + rng.uniform(-0.035, 0.035)) for weight in weights]
    total = sum(jitter) or 1.0
    raw = [points * value / total for value in jitter]
    values = [int(value) for value in raw]
    remaining = points - sum(values)
    order = sorted(range(len(raw)), key=lambda index: raw[index] - values[index], reverse=True)
    for index in order[:remaining]:
        values[index] += 1
    return Attributes(
        strength=values[0], vitality=values[1], intelligence=values[2],
        dexterity=values[3], endurance=values[4], luck=values[5],
    )


def _talents_for_build(class_code: str, path_id: str, level: int, rng: random.Random) -> dict[str, int]:
    points = total_tree_points_for_level(level, True)
    paths = list(CLASS_PATH_ORDER[class_code])
    preferred = path_id
    secondary = next((path for path in paths if path != preferred), preferred)
    result: dict[str, int] = {}

    # 80% punktów trafia w główną ścieżkę, reszta może tworzyć hybrydę.
    for _ in range(points):
        target_path = preferred if rng.random() < 0.80 else secondary
        candidates = []
        for talent in talents_for_path(target_path):
            current = result.get(talent.talent_id, 0)
            if current >= talent.max_rank:
                continue
            if all(result.get(req_id, 0) >= req_rank for req_id, req_rank in talent.prerequisites):
                candidates.append(talent)
        if not candidates and target_path != preferred:
            for talent in talents_for_path(preferred):
                current = result.get(talent.talent_id, 0)
                if current < talent.max_rank and all(result.get(req_id, 0) >= req_rank for req_id, req_rank in talent.prerequisites):
                    candidates.append(talent)
        if not candidates:
            break
        # Rdzeń rzadkiej ścieżki i aktywne skille są atrakcyjniejsze dla AI.
        candidates.sort(key=lambda talent: (0 if "core" in talent.talent_id else 1, 0 if talent.active_skill_id else 1, talent.talent_id))
        talent = candidates[0] if rng.random() < 0.70 else rng.choice(candidates)
        result[talent.talent_id] = result.get(talent.talent_id, 0) + 1
    return result


def _valid_item_for_level(item_id: str, level: int) -> bool:
    try:
        definition = get_item_definition(item_id)
    except KeyError:
        return False
    return definition.is_equipment and definition.item_power > 0 and definition.required_level <= level


def _generate_personal_equipment(companion_id: str, class_code: str, level: int, rare_path: bool, rng: random.Random):
    from player.equipment import Equipment

    equipment = Equipment()
    personal_ids: set[str] = set()
    personal_storage: list[EquipmentItem] = []

    def add(item_id: str, quality: EquipmentQuality, upgrade: int = 0) -> None:
        if not _valid_item_for_level(item_id, level):
            return
        item = generate_equipment_item(
            item_id,
            rng,
            quality=quality,
            upgrade_level=upgrade,
            instance_id=f"npc-{companion_id}-{item_id}-{len(personal_ids)}",
        )
        previous = equipment.equip_and_return_previous(item)
        if previous is not None:
            personal_storage.append(previous)
        personal_ids.add(item.instance_id)

    quality = EquipmentQuality.ELITE if level < 14 else EquipmentQuality.MINIBOSS
    upgrade = min(8, max(0, level // 4 - 1))
    add(_choose_for_level(_CLASS_WEAPONS[class_code], level), quality, upgrade)
    add(_choose_for_level(_CLASS_OFFHANDS[class_code], level), quality, max(0, upgrade - 1))

    for slot, pool in _GENERIC_SLOT_ITEMS.items():
        valid = [item_id for item_id in pool if _valid_item_for_level(item_id, level)]
        if valid and rng.random() < 0.72:
            add(valid[-1] if rng.random() < 0.55 else rng.choice(valid), quality, max(0, upgrade - 2))

    uniques = [item_id for item_id in _RIFT_UNIQUES_BY_CLASS.get(class_code, ()) if _valid_item_for_level(item_id, level)]
    unique_chance = 0.16 if rare_path else 0.08
    if uniques and rng.random() < unique_chance:
        add(rng.choice(uniques), EquipmentQuality.BOSS, min(10, upgrade + 2))

    return equipment, personal_ids, personal_storage


def _generate_new_candidate(template: CompanionTemplate, player: Player, day: int, slot_index: int) -> CompanionCandidate:
    rng = random.Random(_seed_int("candidate", player.name, day, slot_index, template.template_id))
    class_code = rng.choice(template.allowed_classes)
    low = max(5, player.level - 6)
    high = max(low, player.level + CANDIDATE_LEVEL_DELTA)
    # Wyższe poziomy istnieją, ale środek rozkładu nadal siedzi blisko gracza.
    level = max(5, min(high, int(round(rng.triangular(low, high, player.level)))))
    normal_path, rare_path_id = CLASS_PATH_ORDER[class_code]
    rare_path = rng.random() < (0.18 + (0.04 if template.base_willingness < 50 else 0.0))
    path_id = rare_path_id if rare_path else normal_path
    attributes = _attributes_for_level(class_code, level, rng)
    talents = _talents_for_build(class_code, path_id, level, rng)
    companion_id = f"{template.template_id}-{day}-{slot_index}-{rng.randrange(1000, 9999)}"
    equipment, personal_ids, personal_storage = _generate_personal_equipment(companion_id, class_code, level, rare_path, rng)
    arc = rng.choice(template.arcs)
    companion = Companion(
        companion_id=companion_id,
        template_id=template.template_id,
        name=template.name,
        class_code=class_code,
        level=level,
        experience=0,
        path_id=path_id,
        talents=talents,
        attributes=attributes,
        equipment=equipment,
        personal_instance_ids=personal_ids,
        personal_storage=personal_storage,
        quest_arc_id=arc.arc_id,
    )
    return CompanionCandidate(
        candidate_id=f"cand-{companion_id}",
        companion=companion,
        generated_day=day,
        recruitment_roll=rng.randint(20, 92),
    )


def refresh_injuries(party: PartyState, current_day: int) -> list[str]:
    healed: list[str] = []
    for companion in party.companions:
        if companion.injury_until_day and current_day >= companion.injury_until_day:
            companion.injury_until_day = 0
            healed.append(companion.name)
    return healed


def ensure_daily_candidates(party: PartyState, player: Player, current_day: int, guild_rank_code: str) -> bool:
    """Tworzy dzienną rotację kandydatów. Restart tego samego dnia jej nie zmienia."""
    if party.candidates_day == current_day:
        return False
    party.candidates_day = current_day
    party.candidates = []
    rank_index = _RANK_INDEX.get(guild_rank_code, 0)

    available_templates = [
        template for template in COMPANION_TEMPLATES.values()
        if _RANK_INDEX.get(template.min_guild_rank, 0) <= rank_index
        and all(companion.template_id != template.template_id for companion in party.companions)
    ]
    rng = random.Random(_seed_int("guild-candidates", player.name, current_day, guild_rank_code))

    # Były kompan może wrócić do świata, ale nie od razu po rozstaniu.
    returning = [
        companion for companion in party.dismissed_companions
        if not companion.dead and current_day - companion.dismissed_day >= 3
    ]
    if returning and rng.random() < 0.28:
        companion = copy.deepcopy(rng.choice(returning))
        template = COMPANION_TEMPLATES[companion.template_id]
        party.candidates.append(
            CompanionCandidate(
                candidate_id=f"return-{companion.companion_id}-{current_day}",
                companion=companion,
                generated_day=current_day,
                recruitment_roll=max(15, min(90, 55 - companion.relation // 2)),
                impression=max(0, companion.relation // 3),
                returning=True,
            )
        )
        available_templates = [t for t in available_templates if t.template_id != companion.template_id]

    rng.shuffle(available_templates)
    while len(party.candidates) < CANDIDATES_PER_DAY and available_templates:
        template = available_templates.pop()
        party.candidates.append(_generate_new_candidate(template, player, current_day, len(party.candidates)))
    return True


def candidate_path_name(candidate: CompanionCandidate) -> tuple[str, bool]:
    path = CLASS_PATHS[candidate.companion.path_id]
    return path.name, path.book_item_id is not None


def candidate_willingness_score(candidate: CompanionCandidate, player: Player, guild_rank_code: str, rifts_closed: int = 0) -> int:
    template = COMPANION_TEMPLATES[candidate.companion.template_id]
    score = template.base_willingness
    score += _RANK_INDEX.get(guild_rank_code, 0) * 4
    score += min(12, max(0, int(rifts_closed)) * 2)
    score += candidate.impression
    level_diff = candidate.companion.level - player.level
    if level_diff > 0:
        score -= min(18, level_diff * 2)
    elif level_diff < 0:
        score += min(6, (-level_diff) // 2)
    if CLASS_PATHS[candidate.companion.path_id].book_item_id is not None:
        score -= 5
    if candidate.returning:
        score += 12 + min(12, candidate.companion.relation // 4)
    return max(5, min(95, score))


def willingness_label(score: int) -> str:
    if score >= 80:
        return "bardzo wysoka"
    if score >= 65:
        return "wysoka"
    if score >= 50:
        return "umiarkowana"
    if score >= 35:
        return "niska"
    return "bardzo niska"


def talk_to_candidate(candidate: CompanionCandidate, choice: int) -> str:
    candidate.talked = True
    conversations = CANDIDATE_CONVERSATIONS.get(candidate.companion.template_id, ())
    if 1 <= choice <= len(conversations):
        response, impression = conversations[choice - 1]
        candidate.impression += impression
        return response
    return "Rozmowa urywa się bez większego wrażenia."


def recruit_candidate(party: PartyState, candidate: CompanionCandidate, player: Player, guild_rank_code: str, rifts_closed: int = 0) -> tuple[bool, str, int]:
    if len(party.companions) >= MAX_COMPANIONS:
        raise ValueError(f"Masz już maksymalną liczbę kompanów ({MAX_COMPANIONS}).")
    if candidate.recruitment_attempted:
        raise ValueError("Ten kandydat podjął już dziś decyzję.")
    candidate.recruitment_attempted = True
    score = candidate_willingness_score(candidate, player, guild_rank_code, rifts_closed)
    template = COMPANION_TEMPLATES[candidate.companion.template_id]
    if score < candidate.recruitment_roll:
        return False, template.recruit_fail, score

    companion = copy.deepcopy(candidate.companion)
    companion.relation = max(companion.relation, candidate.impression)
    companion.active = len(party.active_companions()) < MAX_ACTIVE_COMPANIONS
    companion.dismissed_day = 0
    party.companions.append(companion)
    party.candidates = [item for item in party.candidates if item.candidate_id != candidate.candidate_id]
    party.dismissed_companions = [item for item in party.dismissed_companions if item.companion_id != companion.companion_id]
    party.messages.append(PartyMessage(candidate.generated_day, companion.companion_id, companion.name, template.recruit_success))
    return True, template.recruit_success, score


def set_companion_active(party: PartyState, companion_id: str, active: bool) -> None:
    companion = party.companion_by_id(companion_id)
    if companion is None:
        raise KeyError("Nie znaleziono kompana.")
    if active:
        if not companion.can_join_party:
            raise ValueError("Ten kompan nie może teraz wyruszyć na wyprawę.")
        if len(party.active_companions()) >= MAX_ACTIVE_COMPANIONS and not companion.active:
            raise ValueError(f"Aktywna drużyna może mieć maksymalnie {MAX_ACTIVE_COMPANIONS} kompanów.")
    companion.active = bool(active)


def set_party_solo(party: PartyState) -> int:
    """Wyłącza wszystkich kompanów z aktywnego składu i zwraca liczbę zmian."""
    changed = 0
    for companion in party.companions:
        if companion.active:
            companion.active = False
            changed += 1
    return changed


def set_companion_tactic(party: PartyState, companion_id: str, tactic: str) -> None:
    companion = party.companion_by_id(companion_id)
    if companion is None:
        raise KeyError("Nie znaleziono kompana.")
    if tactic not in COMPANION_TACTICS:
        raise ValueError("Nieznana taktyka kompana.")
    companion.tactic = tactic


def _restore_personal_slot(companion: Companion, slot: EquipmentSlot) -> None:
    candidates = [
        item for item in companion.personal_storage
        if get_item_definition(item.item_id).slot is slot
    ]
    if not candidates:
        return
    candidates.sort(key=lambda item: (get_item_definition(item.item_id).item_power, item.upgrade_level), reverse=True)
    item = candidates[0]
    companion.personal_storage.remove(item)
    companion.equipment.equip_and_return_previous(item)


def equip_player_item_to_companion(player: Player, companion: Companion, inventory_index: int) -> EquipmentItem:
    if inventory_index < 0 or inventory_index >= len(player.inventory.equipment_items):
        raise IndexError("Nieprawidłowy indeks wyposażenia.")
    item = player.inventory.equipment_items[inventory_index]
    definition = get_item_definition(item.item_id)
    if definition.required_level > companion.level:
        raise ValueError(f"Kompan potrzebuje poziomu {definition.required_level}.")
    if definition.required_class_code is not None and definition.required_class_code != companion.class_code:
        raise ValueError(f"Ten przedmiot wymaga klasy: {definition.required_class_name}.")
    item = player.inventory.pop_equipment(inventory_index)
    previous = companion.equipment.equip_and_return_previous(item)
    if previous is not None:
        if companion.owns_item(previous):
            companion.personal_storage.append(previous)
        else:
            player.inventory.add_equipment_instance(previous)
    return item


def remove_player_item_from_companion(player: Player, companion: Companion, slot: EquipmentSlot) -> EquipmentItem:
    item = companion.equipment.get(slot)
    if item is None:
        raise ValueError("Ten slot jest pusty.")
    if companion.owns_item(item):
        raise ValueError("To osobisty przedmiot kompana. Nie możesz go zabrać.")
    removed = companion.equipment.unequip(slot)
    assert removed is not None
    player.inventory.add_equipment_instance(removed)
    _restore_personal_slot(companion, slot)
    return removed


def return_player_owned_gear(player: Player, companion: Companion) -> list[EquipmentItem]:
    returned: list[EquipmentItem] = []
    for slot in list(companion.equipment.slots):
        item = companion.equipment.get(slot)
        if item is None or companion.owns_item(item):
            continue
        removed = companion.equipment.unequip(slot)
        if removed is not None:
            player.inventory.add_equipment_instance(removed)
            returned.append(removed)
            _restore_personal_slot(companion, slot)
    return returned


def dismiss_companion(party: PartyState, player: Player, companion_id: str, current_day: int) -> Companion:
    companion = party.companion_by_id(companion_id)
    if companion is None:
        raise KeyError("Nie znaleziono kompana.")
    return_player_owned_gear(player, companion)
    companion.active = False
    companion.dismissed_day = current_day
    party.companions = [item for item in party.companions if item.companion_id != companion_id]
    party.dismissed_companions = [item for item in party.dismissed_companions if item.companion_id != companion_id]
    party.dismissed_companions.append(copy.deepcopy(companion))
    return companion


def companion_to_player(companion: Companion) -> Player:
    player_class = player_class_from_code(companion.class_code)
    unlocked_paths = {
        companion.path_id
    } if CLASS_PATHS[companion.path_id].book_item_id is not None else set()
    combatant = Player(
        name=companion.name,
        level=companion.level,
        experience=companion.experience,
        character_class=player_class,
        attributes=copy.deepcopy(companion.attributes),
        talents=dict(companion.talents),
        unlocked_class_paths=unlocked_paths,
        inventory=Inventory(),
        equipment=copy.deepcopy(companion.equipment),
    )
    combatant.recalculate_stats()
    combatant.stats.current_hp = combatant.stats.max_hp if companion.current_hp <= 0 else min(companion.current_hp, combatant.stats.max_hp)
    combatant.stats.current_mana = combatant.stats.max_mana if companion.current_mana <= 0 else min(companion.current_mana, combatant.stats.max_mana)
    return combatant


def sync_companion_from_player(companion: Companion, combatant: Player) -> None:
    companion.current_hp = max(0, combatant.stats.current_hp)
    companion.current_mana = max(0, combatant.stats.current_mana)


def _auto_allocate_level(companion: Companion, levels: int, rng: random.Random) -> None:
    if levels <= 0:
        return
    weights = _CLASS_ATTRIBUTE_WEIGHTS[companion.class_code]
    attrs = ["strength", "vitality", "intelligence", "dexterity", "endurance", "luck"]
    for _ in range(levels * 4):
        choice = rng.choices(attrs, weights=weights, k=1)[0]
        setattr(companion.attributes, choice, getattr(companion.attributes, choice) + 1)
    # Nowe punkty drzewka dokładamy do głównej ścieżki, zachowując build NPC.
    desired_points = total_tree_points_for_level(companion.level, True)
    while sum(companion.talents.values()) < desired_points:
        options = []
        for talent in talents_for_path(companion.path_id):
            current = companion.talents.get(talent.talent_id, 0)
            if current < talent.max_rank and all(companion.talents.get(req, 0) >= rank for req, rank in talent.prerequisites):
                options.append(talent)
        if not options:
            break
        talent = options[0]
        companion.talents[talent.talent_id] = companion.talents.get(talent.talent_id, 0) + 1


def gain_companion_experience(companion: Companion, amount: int) -> int:
    if amount <= 0 or companion.dead:
        return 0
    companion.experience += int(amount)
    levels = 0
    while True:
        required = int(50 * ((companion.level + 1) ** 1.5))
        if companion.experience < required:
            break
        companion.experience -= required
        companion.level += 1
        levels += 1
    if levels:
        _auto_allocate_level(companion, levels, random.Random(_seed_int("npc-level", companion.companion_id, companion.level)))
        companion.current_hp = 0
        companion.current_mana = 0
    return levels


def available_personal_stage(companion: Companion):
    template = COMPANION_TEMPLATES[companion.template_id]
    arc = next((arc for arc in template.arcs if arc.arc_id == companion.quest_arc_id), None)
    if arc is None or companion.quest_stage >= len(arc.stages):
        return None
    stage = arc.stages[companion.quest_stage]
    if companion.rifts_together < stage.unlock_rifts:
        return None
    return arc, stage


def complete_personal_stage(companion: Companion, choice_index: int) -> tuple[str, str, int]:
    available = available_personal_stage(companion)
    if available is None:
        raise ValueError("Ten etap historii nie jest jeszcze dostępny.")
    arc, stage = available
    if not 0 <= choice_index < len(stage.choices):
        raise ValueError("Nieprawidłowa odpowiedź.")
    choice = stage.choices[choice_index]
    companion.relation = max(-100, min(100, companion.relation + choice.relation_delta))
    if choice.memory_tag:
        companion.memories.add(choice.memory_tag)
    companion.quest_stage += 1
    return stage.title, choice.response, choice.relation_delta


def ensure_daily_party_message(party: PartyState, current_day: int, player_name: str) -> PartyMessage | None:
    if party.last_message_day >= current_day or not party.companions:
        return None
    party.last_message_day = current_day
    candidates = [companion for companion in party.companions if not companion.dead]
    if not candidates:
        return None
    rng = random.Random(_seed_int("party-message", player_name, current_day, len(candidates)))
    companion = rng.choice(candidates)
    template = COMPANION_TEMPLATES[companion.template_id]
    if companion.is_injured:
        text = rng.choice((
            "Nie próbuj mnie wyciągać z łóżka przed czasem. Mirela zagroziła, że jeśli pękną szwy, zszyje mnie grubszą nicią.",
            "Powrót do sił idzie wolniej, niż bym chciał. Nie oznacza to, że macie robić coś głupiego beze mnie.",
        ))
    else:
        text = rng.choice(template.messages)
    message = PartyMessage(current_day, companion.companion_id, companion.name, text, False)
    party.messages.append(message)
    party.messages = party.messages[-60:]
    return message


def mark_messages_read(party: PartyState) -> None:
    party.messages = [PartyMessage(m.day, m.sender_id, m.sender_name, m.text, True) for m in party.messages]


def camp_banter(party: PartyState, seed: int) -> tuple[str, ...]:
    active = party.active_companions()
    if len(active) >= 2:
        rng = random.Random(seed)
        pairs = []
        for index, first in enumerate(active):
            for second in active[index + 1:]:
                key = frozenset((first.template_id, second.template_id))
                if key in PAIR_BANTER:
                    pairs.append((first, second, key))
        rng.shuffle(pairs)
        for first, second, key in pairs:
            scenes = PAIR_BANTER[key]
            for scene_index, scene in enumerate(scenes):
                scene_id = f"{first.template_id}:{second.template_id}:{scene_index}"
                if scene_id in party.seen_banter:
                    continue
                party.seen_banter.add(scene_id)
                return scene
    if active:
        companion = random.Random(seed).choice(active)
        template = COMPANION_TEMPLATES[companion.template_id]
        return (f"{companion.name}: {random.Random(seed + 1).choice(template.camp_lines)}",)
    return ()


def record_rift_together(party: PartyState, companion_ids: Iterable[str]) -> None:
    ids = set(companion_ids)
    for companion in party.companions:
        if companion.companion_id in ids and not companion.dead:
            companion.rifts_together += 1
            companion.relation = min(100, companion.relation + 3)


def critically_injure(companion: Companion, current_day: int, days: int) -> None:
    companion.active = False
    companion.injury_until_day = max(companion.injury_until_day, current_day + max(1, days))
    companion.current_hp = 1


def kill_companion(party: PartyState, player: Player, companion: Companion, current_day: int, cause: str, rift_rank: str | None = None) -> FallenCompanion:
    return_player_owned_gear(player, companion)
    companion.dead = True
    companion.active = False
    memorial = FallenCompanion(
        companion.companion_id, companion.name, companion.class_code,
        companion.level, current_day, cause, rift_rank,
    )
    party.fallen.append(memorial)
    party.companions = [item for item in party.companions if item.companion_id != companion.companion_id]

    # Reakcja żyjącego kompana jest ręcznie osadzona w tonie świata, ale
    # wybór nadawcy zależy od aktualnej drużyny.
    survivors = [item for item in party.companions if not item.dead]
    if survivors:
        sender = survivors[0]
        party.messages.append(
            PartyMessage(
                current_day, sender.companion_id, sender.name,
                f"Nie mogę przestać myśleć o {companion.name}. Mieliśmy czas zareagować. Następnym razem nie możemy pozwolić, żeby cisza trwała o jedną rundę za długo.",
                False,
            )
        )
    return memorial


def all_equipment_items(companion: Companion) -> list[EquipmentItem]:
    return list(companion.equipment.slots.values()) + list(companion.personal_storage)
