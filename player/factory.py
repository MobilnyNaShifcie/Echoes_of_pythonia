from game.config import STARTING_ARMOR_ID, STARTING_WEAPON_ID
from items.factory import create_equipment_item
from player.player import Player


def create_player(name: str) -> Player:
    """Tworzy nowego bohatera wraz ze startowym wyposażeniem."""
    player = Player(name=name)

    player.equipment.equip_and_return_previous(
        create_equipment_item(STARTING_WEAPON_ID)
    )
    player.equipment.equip_and_return_previous(
        create_equipment_item(STARTING_ARMOR_ID)
    )

    player.recalculate_stats()
    player.stats.restore_full()
    return player
