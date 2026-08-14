import io
import unittest
from contextlib import redirect_stdout

from items.catalog import get_item_definition
from items.models import EquipmentItem
from ui.inventory_view import _equipment_meta, _print_equipment_detail_body


class EquipmentUiV0179Tests(unittest.TestCase):
    def test_compact_meta_hides_internal_equipment_role(self) -> None:
        item = EquipmentItem(item_id="grandmaster_sword", item_power=4)
        meta = _equipment_meta(item)

        self.assertIn("IP IV", meta)
        self.assertNotIn("Ofensywny", meta)
        self.assertNotIn("Defensywny", meta)
        self.assertNotIn("Mieszany", meta)

    def test_full_details_do_not_show_role_line(self) -> None:
        item = EquipmentItem(item_id="grandmaster_sword", item_power=4)
        output = io.StringIO()

        with redirect_stdout(output):
            _print_equipment_detail_body(item)

        rendered = output.getvalue()
        self.assertNotIn("Rola:", rendered)
        self.assertNotIn("Ofensywny", rendered)

    def test_role_still_exists_in_item_model(self) -> None:
        definition = get_item_definition("grandmaster_sword")
        self.assertIsNotNone(definition.equipment_role)
        self.assertEqual(definition.equipment_role.display_name, "Ofensywny")


if __name__ == "__main__":
    unittest.main()
