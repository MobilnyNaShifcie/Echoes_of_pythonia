from __future__ import annotations

from dataclasses import dataclass, field

from items.catalog import get_item_definition
from items.models import ItemCategory
from systems.carry_weight import carry_capacity, inventory_weight, stack_weight
from systems.companions import set_companion_active, set_party_solo
from systems.guild_storage import GuildStorage, withdraw_stack


PRESET_ORDER: tuple[str, ...] = ("solo", "boss", "dungeon", "rift")
PRESET_NAMES: dict[str, str] = {
    "solo": "SOLO",
    "boss": "BOSS",
    "dungeon": "DUNGEON",
    "rift": "SZCZELINA",
}


@dataclass
class ExpeditionPreset:
    preset_id: str
    configured: bool = False
    active_companion_ids: list[str] = field(default_factory=list)
    supplies: dict[str, int] = field(default_factory=dict)


@dataclass
class ExpeditionPreparationState:
    selected_location_id: str = ""
    presets: dict[str, ExpeditionPreset] = field(
        default_factory=lambda: {
            preset_id: ExpeditionPreset(preset_id=preset_id)
            for preset_id in PRESET_ORDER
        }
    )


@dataclass(frozen=True)
class PresetApplyResult:
    activated_companions: tuple[str, ...]
    unavailable_companions: tuple[str, ...]
    withdrawn: dict[str, int]
    missing: dict[str, int]


def healing_supply_ids(player, storage: GuildStorage) -> list[str]:
    """Zwraca dostępne przedmioty użytkowe z plecaka i magazynu."""
    ids = set(player.inventory.stacks) | set(storage.inventory.stacks)
    result: list[str] = []
    for item_id in ids:
        definition = get_item_definition(item_id)
        if not definition.is_consumable:
            continue
        if player.inventory.count(item_id) + storage.inventory.count(item_id) <= 0:
            continue
        result.append(item_id)
    result.sort(key=lambda item_id: get_item_definition(item_id).name)
    return result


def save_preset(
    preparation: ExpeditionPreparationState,
    preset_id: str,
    party,
    supplies: dict[str, int],
) -> ExpeditionPreset:
    if preset_id not in PRESET_NAMES:
        raise KeyError("Nieznany preset wyprawowy.")

    clean_supplies: dict[str, int] = {}
    for item_id, quantity_raw in supplies.items():
        quantity = int(quantity_raw)
        if quantity < 0:
            raise ValueError("Ilość zapasu nie może być ujemna.")
        definition = get_item_definition(item_id)
        if definition.category is not ItemCategory.CONSUMABLE:
            raise ValueError(f"{definition.name} nie jest zapasem użytkowym.")
        if quantity > 0:
            clean_supplies[item_id] = quantity

    companion_ids = [] if preset_id == "solo" else [
        companion.companion_id for companion in party.active_companions()
    ]
    preset = ExpeditionPreset(
        preset_id=preset_id,
        configured=True,
        active_companion_ids=companion_ids,
        supplies=clean_supplies,
    )
    preparation.presets[preset_id] = preset
    return preset


def clear_preset(preparation: ExpeditionPreparationState, preset_id: str) -> None:
    if preset_id not in PRESET_NAMES:
        raise KeyError("Nieznany preset wyprawowy.")
    preparation.presets[preset_id] = ExpeditionPreset(preset_id=preset_id)


def apply_preset(
    preparation: ExpeditionPreparationState,
    preset_id: str,
    player,
    party,
    storage: GuildStorage,
) -> PresetApplyResult:
    if preset_id not in PRESET_NAMES:
        raise KeyError("Nieznany preset wyprawowy.")
    preset = preparation.presets[preset_id]
    if not preset.configured:
        raise ValueError("Ten preset nie został jeszcze skonfigurowany.")

    # Najpierw wyliczamy, co realnie możemy dobrać z magazynu. Dzięki temu
    # przeciążenie nie prowadzi do częściowo zastosowanego loadoutu.
    planned_withdrawals: dict[str, int] = {}
    missing: dict[str, int] = {}
    for item_id, target_quantity in preset.supplies.items():
        owned = player.inventory.count(item_id)
        needed = max(0, target_quantity - owned)
        if needed <= 0:
            continue
        available = storage.inventory.count(item_id)
        take = min(needed, available)
        if take > 0:
            planned_withdrawals[item_id] = take
        if take < needed:
            missing[item_id] = needed - take

    added_weight = sum(
        stack_weight(item_id, quantity)
        for item_id, quantity in planned_withdrawals.items()
    )
    projected = inventory_weight(player.inventory) + added_weight
    capacity = carry_capacity(player)
    if projected > capacity + 1e-9:
        raise ValueError(
            "Preset przekroczyłby udźwig: "
            f"{projected:.1f}/{capacity:.1f} kg. Odłóż część rzeczy przed uzupełnieniem zapasów."
        )

    set_party_solo(party)
    activated: list[str] = []
    unavailable: list[str] = []
    for companion_id in preset.active_companion_ids:
        companion = party.companion_by_id(companion_id)
        if companion is None:
            unavailable.append(companion_id)
            continue
        if not companion.can_join_party:
            unavailable.append(companion.name)
            continue
        try:
            set_companion_active(party, companion_id, True)
            activated.append(companion.name)
        except ValueError:
            unavailable.append(companion.name)

    for item_id, quantity in planned_withdrawals.items():
        withdraw_stack(player, storage, item_id, quantity)

    return PresetApplyResult(
        activated_companions=tuple(activated),
        unavailable_companions=tuple(unavailable),
        withdrawn=planned_withdrawals,
        missing=missing,
    )
