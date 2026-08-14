from dataclasses import dataclass, field

from items.catalog import get_item_definition
from items.affixes import EquipmentQuality, generate_equipment_item
from items.factory import create_equipment_item
from items.models import EquipmentItem


@dataclass
class Inventory:
    """Plecak bohatera."""

    stacks: dict[str, int] = field(default_factory=dict)
    equipment_items: list[EquipmentItem] = field(default_factory=list)

    def add(self, item_id: str, quantity: int = 1) -> None:
        if quantity <= 0:
            raise ValueError("Ilość musi być większa od zera.")

        definition = get_item_definition(item_id)

        if definition.is_equipment:
            for _ in range(quantity):
                self.equipment_items.append(
                    create_equipment_item(item_id)
                )
            return

        self.stacks[item_id] = self.stacks.get(item_id, 0) + quantity


    def add_generated_equipment(
        self,
        item_id: str,
        rng,
        *,
        quality: EquipmentQuality = EquipmentQuality.NORMAL,
        quantity: int = 1,
    ) -> list[EquipmentItem]:
        if quantity <= 0:
            raise ValueError("Ilość musi być większa od zera.")

        definition = get_item_definition(item_id)
        if not definition.is_equipment:
            raise ValueError("Ten przedmiot nie jest wyposażeniem.")

        generated: list[EquipmentItem] = []
        for _ in range(quantity):
            item = generate_equipment_item(
                item_id,
                rng,
                quality=quality,
            )
            self.equipment_items.append(item)
            generated.append(item)
        return generated

    def add_equipment_instance(self, item: EquipmentItem) -> None:
        definition = get_item_definition(item.item_id)

        if not definition.is_equipment:
            raise ValueError("Do listy wyposażenia trafił zły typ przedmiotu.")

        self.equipment_items.append(item)

    def count(self, item_id: str) -> int:
        definition = get_item_definition(item_id)

        if definition.is_equipment:
            return sum(
                1
                for item in self.equipment_items
                if item.item_id == item_id
            )

        return self.stacks.get(item_id, 0)

    def has(self, item_id: str, quantity: int = 1) -> bool:
        if quantity <= 0:
            raise ValueError("Ilość musi być większa od zera.")

        return self.count(item_id) >= quantity

    def remove_stack(self, item_id: str, quantity: int = 1) -> None:
        if quantity <= 0:
            raise ValueError("Ilość musi być większa od zera.")

        current = self.stacks.get(item_id, 0)

        if current < quantity:
            raise ValueError("Brak wystarczającej liczby przedmiotów.")

        remaining = current - quantity

        if remaining == 0:
            del self.stacks[item_id]
        else:
            self.stacks[item_id] = remaining

    def remove_item(self, item_id: str, quantity: int = 1) -> None:
        if quantity <= 0:
            raise ValueError("Ilość musi być większa od zera.")

        definition = get_item_definition(item_id)

        if not definition.is_equipment:
            self.remove_stack(item_id, quantity)
            return

        matching_indexes = [
            index
            for index, item in enumerate(self.equipment_items)
            if item.item_id == item_id
        ]

        if len(matching_indexes) < quantity:
            raise ValueError("Brak wystarczającej liczby przedmiotów.")

        for index in reversed(matching_indexes[:quantity]):
            self.equipment_items.pop(index)

    def pop_equipment(self, index: int) -> EquipmentItem:
        if index < 0 or index >= len(self.equipment_items):
            raise IndexError("Nieprawidłowy indeks wyposażenia.")

        return self.equipment_items.pop(index)

    def is_empty(self) -> bool:
        return not self.stacks and not self.equipment_items
