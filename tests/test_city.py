import unittest

from world.city_factory import create_city


class CityTests(unittest.TestCase):
    def test_varenhold_has_required_services(self) -> None:
        city = create_city("varenhold")
        self.assertEqual(city.name, "Varenhold")
        self.assertTrue(city.blacksmith_name)
        self.assertTrue(city.workshop_name)
        self.assertTrue(city.merchant_name)
        self.assertTrue(city.inn_name)
        self.assertTrue(city.guild_name)
        self.assertGreaterEqual(len(city.rumors), 3)
