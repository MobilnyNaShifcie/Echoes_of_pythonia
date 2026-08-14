from items.catalog import get_item_definition
from items.models import EquipmentItem


def create_equipment_item(item_id: str) -> EquipmentItem:
    """Tworzy bazową instancję bez losowania affixów.

    Funkcja jest używana dla startowego sprzętu, testów i wewnętrznych
    operacji. Gameplayowy drop/crafting korzysta z generatora Equipment 2.0.
    """
    definition = get_item_definition(item_id)

    if not definition.is_equipment:
        raise ValueError(
            f"Przedmiot {item_id} nie jest wyposażeniem."
        )

    return EquipmentItem(
        item_id=item_id,
        item_power=definition.item_power,
    )
