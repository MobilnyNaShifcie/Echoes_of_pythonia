from __future__ import annotations

import hashlib
import random
from dataclasses import dataclass

from data.guild import GUILD_RANKS
from data.rifts import (
    OTHER_SEARCHER_TEAMS,
    RIFT_EXP_REWARD,
    RIFT_GOLD_REWARD,
    RIFT_MIN_COMPANIONS,
    RIFT_MODIFIERS,
    RIFT_RANK_INDEX,
    RIFT_RANKS,
    RIFT_SEGMENTS,
    RIFT_THEMES,
    RIFT_UNIQUE_POOLS,
)
from items.affixes import EquipmentQuality, generate_equipment_item
from player.player import Player
from rifts.models import RiftExpedition, RiftInstance, RiftState


@dataclass(frozen=True)
class RiftEnemyProfile:
    enemy_id: str
    name: str
    max_hp: int
    attack: int
    defense: int
    boss: bool = False
    elite: bool = False


@dataclass(frozen=True)
class RiftCompletionReward:
    gold: int
    experience: int
    unique_item_id: str | None


def _seed_int(*parts: object) -> int:
    digest = hashlib.sha256("|".join(map(str, parts)).encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")


def _guild_rank_index(rank_code: str) -> int:
    return next((index for index, rank in enumerate(GUILD_RANKS) if rank.code == rank_code), 0)


def _roll_rift_rank(rng: random.Random, guild_rank_code: str) -> str:
    max_index = min(_guild_rank_index(guild_rank_code), len(RIFT_RANKS) - 1)
    available = list(RIFT_RANKS[: max_index + 1])
    # Najczęściej pojawia się szczelina bliska aktualnej randze, ale niższe
    # nadal wracają jako mniej groźne alarmy Gildii.
    weights = [1 + index * 2 for index in range(len(available))]
    return rng.choices(available, weights=weights, k=1)[0]


def _create_rift(player: Player, current_day: int, guild_rank_code: str) -> RiftInstance:
    seed = _seed_int("rift", player.name, current_day, guild_rank_code)
    rng = random.Random(seed)
    rank_code = _roll_rift_rank(rng, guild_rank_code)
    theme_id = rng.choice(tuple(RIFT_THEMES))
    theme = RIFT_THEMES[theme_id]
    modifier_count = 1 + (1 if RIFT_RANK_INDEX[rank_code] >= 3 else 0) + (1 if RIFT_RANK_INDEX[rank_code] >= 5 else 0)
    modifiers = tuple(rng.sample(tuple(RIFT_MODIFIERS), min(modifier_count, len(RIFT_MODIFIERS))))
    boss_id, boss_name = rng.choice(tuple(theme["bosses"]))
    lifetime = rng.randint(2, 4)
    return RiftInstance(
        rift_id=f"rift-{current_day}-{seed % 1000000}",
        rank_code=rank_code,
        theme_id=theme_id,
        theme_name=str(theme["name"]),
        modifier_ids=modifiers,
        discovered_day=current_day,
        expires_day=current_day + lifetime,
        seed=seed,
        segment_count=RIFT_SEGMENTS[rank_code],
        boss_id=str(boss_id),
        boss_name=str(boss_name),
    )


def ensure_rift_state(state: RiftState, player: Player, current_day: int, guild_rank_code: str) -> str | None:
    """Aktualizuje świat Szczelin wyłącznie w czasie Pythonii."""
    if state.expedition is not None:
        return None

    active = state.active_rift
    if active is not None and not active.closed and current_day > active.expires_day:
        rng = random.Random(_seed_int("rift-claimed", active.rift_id))
        team = rng.choice(OTHER_SEARCHER_TEAMS)
        active.closed = True
        active.closed_by = team
        state.last_resolution_day = current_day
        state.last_notice = f"{team} zamknęła {active.theme_name} rangi {active.rank_code}, zanim twoja drużyna wyruszyła."
        state.active_rift = None
        state.next_spawn_day = current_day + rng.randint(2, 5)
        return state.last_notice

    if state.active_rift is None and current_day >= max(1, state.next_spawn_day):
        state.active_rift = _create_rift(player, current_day, guild_rank_code)
        rng = random.Random(_seed_int("next-rift", state.active_rift.rift_id))
        state.next_spawn_day = current_day + rng.randint(4, 7)
        active = state.active_rift
        state.last_notice = (
            f"ALARM GILDII: wykryto {active.theme_name} rangi {active.rank_code}. "
            f"Jeśli nikt nie wyruszy, inne drużyny zaczną działać po dniu {active.expires_day}."
        )
        return state.last_notice
    return None


def rift_days_remaining(rift: RiftInstance, current_day: int) -> int:
    return max(0, rift.expires_day - current_day + 1)


def can_start_rift(rift: RiftInstance, active_companions: int, guild_rank_code: str) -> tuple[bool, str]:
    if _guild_rank_index(guild_rank_code) < RIFT_RANK_INDEX[rift.rank_code]:
        return False, f"Wymagana Ranga Gildii: {rift.rank_code}."
    required = RIFT_MIN_COMPANIONS[rift.rank_code]
    if active_companions < required:
        return False, f"Ta Szczelina wymaga co najmniej {required} aktywnych kompanów."
    return True, ""


def start_rift_expedition(state: RiftState, current_day: int, companion_ids: tuple[str, ...]) -> RiftExpedition:
    if state.active_rift is None or state.active_rift.closed:
        raise ValueError("Nie ma aktywnej Szczeliny.")
    if state.expedition is not None:
        raise ValueError("Ekspedycja już trwa.")
    state.expedition = RiftExpedition(
        rift_id=state.active_rift.rift_id,
        segment_index=0,
        party_companion_ids=tuple(companion_ids),
        started_day=current_day,
    )
    return state.expedition


def abandon_rift_expedition(state: RiftState, current_day: int) -> None:
    if state.expedition is None:
        return
    state.expedition = None
    if state.active_rift is not None and current_day > state.active_rift.expires_day:
        # Po porzuceniu wygasłej, wcześniej „zarezerwowanej” ekspedycji świat
        # może natychmiast przejąć inna drużyna przy kolejnym odświeżeniu.
        state.active_rift.expires_day = current_day - 1


def rift_segment_kind(rift: RiftInstance, segment_index: int) -> str:
    if segment_index >= rift.segment_count - 1:
        return "boss"
    # Obozowiska są stałymi punktami oddechu i dialogów w długiej wyprawie.
    if segment_index in {4, 9, 14, 19} and segment_index < rift.segment_count - 1:
        return "camp"
    if segment_index == rift.segment_count // 2:
        return "miniboss"
    rng = random.Random(_seed_int(rift.seed, "segment", segment_index))
    roll = rng.random()
    if roll < 0.16:
        return "event"
    if roll < 0.34:
        return "elite"
    return "battle"


def rift_event_text(rift: RiftInstance, segment_index: int) -> tuple[str, str]:
    rng = random.Random(_seed_int(rift.seed, "event", segment_index))
    events = (
        ("Ślad poprzedniej drużyny", "Na ziemi leży zerwany znak Gildii i świeża krew. Nie ma ciał ani śladów odwrotu."),
        ("Niemożliwy korytarz", "Droga prowadzi przez miejsce, które z zewnątrz nie mogłoby pomieścić własnego wnętrza."),
        ("Echo rozmowy", "Przez chwilę słyszycie własne głosy wypowiadające zdania, których nikt jeszcze nie powiedział."),
        ("Pęknięta skrzynia", "Znajdujecie porzucone zapasy. Część jest prawdziwa, część rozpada się w pył po dotknięciu."),
        ("Cisza", "Przez kilka minut Szczelina przestaje wydawać jakiekolwiek dźwięki. Nawet wasze kroki milkną."),
    )
    return rng.choice(events)


def _rank_scale(rank_code: str) -> float:
    return (1.00, 1.10, 1.22, 1.38, 1.58, 1.82, 2.12)[RIFT_RANK_INDEX[rank_code]]


def create_rift_enemy(rift: RiftInstance, player_level: int, segment_index: int, kind: str) -> RiftEnemyProfile:
    theme = RIFT_THEMES[rift.theme_id]
    rng = random.Random(_seed_int(rift.seed, "enemy", segment_index, kind))
    rank_scale = _rank_scale(rift.rank_code)
    depth = 1.0 + (segment_index / max(1, rift.segment_count - 1)) * 0.35
    party_scale = 2.5  # celowo nie jest to content solo
    elite = kind in {"elite", "miniboss"}
    boss = kind == "boss"
    if boss:
        name = rift.boss_name
        factor = 3.2
    elif kind == "miniboss":
        name = str(rng.choice(tuple(theme["elite_names"])))
        factor = 2.0
    elif elite:
        name = str(rng.choice(tuple(theme["elite_names"])))
        factor = 1.45
    else:
        name = str(rng.choice(tuple(theme["enemy_names"])))
        factor = 1.0

    hp = int((55 + player_level * 18) * rank_scale * depth * party_scale * factor)
    attack = int((5 + player_level * 1.65) * rank_scale * depth * (1.10 if elite else 1.0) * (1.18 if boss else 1.0))
    defense = int(1 + player_level / 4 + RIFT_RANK_INDEX[rift.rank_code] * 1.2 + (2 if elite else 0) + (2 if boss else 0))
    for modifier_id in rift.modifier_ids:
        modifier = RIFT_MODIFIERS[modifier_id]
        hp = int(hp * modifier.enemy_hp_multiplier)
        attack = int(attack * modifier.enemy_attack_multiplier)
        defense += modifier.enemy_defense_bonus
    return RiftEnemyProfile(
        enemy_id=f"{rift.rift_id}-{segment_index}-{kind}",
        name=name,
        max_hp=max(1, hp),
        attack=max(1, attack),
        defense=max(0, defense),
        boss=boss,
        elite=elite,
    )


def mana_cost_multiplier(rift: RiftInstance) -> float:
    result = 1.0
    for modifier_id in rift.modifier_ids:
        result *= RIFT_MODIFIERS[modifier_id].player_mana_cost_multiplier
    return result


def resolve_rift_completion(state: RiftState, player: Player, rng: random.Random) -> RiftCompletionReward:
    rift = state.active_rift
    expedition = state.expedition
    if rift is None or expedition is None:
        raise ValueError("Brak aktywnej ekspedycji.")
    low, high = RIFT_GOLD_REWARD[rift.rank_code]
    gold = rng.randint(low, high)
    experience = RIFT_EXP_REWARD[rift.rank_code]
    rank_index = RIFT_RANK_INDEX[rift.rank_code]

    unique_chance = min(0.80, 0.28 + rank_index * 0.07)
    unique_item_id = None
    if rng.random() < unique_chance:
        pool = RIFT_UNIQUE_POOLS.get(player.character_class.code, ())
        if pool:
            unique_item_id = rng.choice(pool)
            item = generate_equipment_item(unique_item_id, rng, quality=EquipmentQuality.BOSS)
            player.inventory.add_equipment_instance(item)

    player.add_gold(gold)
    player.gain_experience(experience)

    rift.closed = True
    rift.closed_by = player.name
    state.completed_total += 1
    state.completed_by_rank[rift.rank_code] = state.completed_by_rank.get(rift.rank_code, 0) + 1
    state.last_resolution_day = expedition.started_day
    state.last_notice = f"{rift.theme_name} rangi {rift.rank_code} została zamknięta przez twoją drużynę."
    state.expedition = None
    state.active_rift = None
    # Kolejna Szczelina nie pojawia się natychmiast po wielkiej ekspedycji.
    state.next_spawn_day = max(state.next_spawn_day, expedition.started_day + rng.randint(3, 6))
    return RiftCompletionReward(gold, experience, unique_item_id)
