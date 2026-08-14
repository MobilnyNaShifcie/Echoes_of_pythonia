from dataclasses import dataclass

from items.catalog import get_item_definition
from player.player import Player


@dataclass(frozen=True)
class ConsumableUseResult:
    item_id: str
    healed_hp: int = 0
    restored_mana: int = 0


def use_consumable(
    player: Player,
    item_id: str,
) -> ConsumableUseResult:
    """Używa przedmiotu użytkowego z plecaka.

    Przedmiot jest zużywany tylko wtedy, gdy przyniesie przynajmniej
    jeden efekt: odzyskanie HP lub Many.
    """
    definition = get_item_definition(item_id)

    if not definition.is_consumable:
        raise ValueError("Wybrany przedmiot nie jest przedmiotem użytkowym.")

    if not player.inventory.has(item_id):
        raise ValueError("Nie posiadasz tego przedmiotu.")

    missing_hp = max(
        0,
        player.stats.max_hp - player.stats.current_hp,
    )
    missing_mana = max(
        0,
        player.stats.max_mana - player.stats.current_mana,
    )

    hp_power = definition.heal_hp
    if definition.heal_hp_percent > 0:
        hp_power += max(1, round(player.stats.max_hp * definition.heal_hp_percent / 100.0))

    mana_power = definition.restore_mana
    if definition.restore_mana_percent > 0 and player.stats.max_mana > 0:
        mana_power += max(1, round(player.stats.max_mana * definition.restore_mana_percent / 100.0))

    healed_hp = min(hp_power, missing_hp)
    restored_mana = min(mana_power, missing_mana)

    if healed_hp <= 0 and restored_mana <= 0:
        if definition.restore_mana > 0 or definition.restore_mana_percent > 0:
            raise ValueError("Masz już pełne HP i Manę.")
        raise ValueError("Masz już pełne HP.")

    player.stats.current_hp += healed_hp
    player.stats.current_mana += restored_mana
    player.inventory.remove_stack(item_id, 1)

    return ConsumableUseResult(
        item_id=item_id,
        healed_hp=healed_hp,
        restored_mana=restored_mana,
    )
