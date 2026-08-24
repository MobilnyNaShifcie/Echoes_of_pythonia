class_name DungeonEnemyCatalog
extends RefCounted

const DATA := {
	"drowned_acolyte":
	{
		"display_name": "Akolita Zatopionego Zakonu",
		"max_hp": 50,
		"attack": 13,
		"defense": 4,
		"dodge": 10.0,
		"experience_reward": 110,
		"gold_min": 80,
		"gold_max": 110,
		"special_name": "Modlitwa Głębin",
		"special_chance": 0.25,
		"special_attack_bonus": 4,
		"special_damage_type": "water"
	},
	"drowned_priestess":
	{
		"display_name": "Kapłanka Zatopionych",
		"max_hp": 82,
		"attack": 15,
		"defense": 5,
		"dodge": 12.0,
		"experience_reward": 180,
		"gold_min": 130,
		"gold_max": 180,
		"rank": "elite",
		"special_name": "Pieśń Głębin",
		"special_chance": 0.3,
		"special_attack_bonus": 5,
		"special_damage_type": "water"
	},
	"iron_gate_guardian":
	{
		"display_name": "Strażnik Żelaznych Wrót",
		"max_hp": 105,
		"attack": 16,
		"defense": 9,
		"dodge": 0.0,
		"experience_reward": 220,
		"gold_min": 170,
		"gold_max": 230,
		"rank": "elite",
		"special_name": "Miażdżące Uderzenie",
		"special_chance": 0.25,
		"special_attack_bonus": 5,
		"physical_damage_reduction": 1
	},
	"crypt_warden":
	{
		"display_name": "Strażnik Krypty",
		"max_hp": 120,
		"attack": 17,
		"defense": 10,
		"dodge": 0.0,
		"experience_reward": 260,
		"gold_min": 190,
		"gold_max": 260,
		"rank": "elite",
		"special_name": "Łańcuch Potępionych",
		"special_chance": 0.3,
		"special_attack_bonus": 6,
		"special_damage_type": "water",
		"first_attack_bonus": 2,
		"physical_damage_reduction": 1
	},
	"order_grandmaster":
	{
		"display_name": "Wielki Mistrz Zatopionego Zakonu",
		"max_hp": 220,
		"attack": 18,
		"defense": 9,
		"dodge": 5.0,
		"experience_reward": 800,
		"gold_min": 450,
		"gold_max": 650,
		"rank": "boss",
		"special_name": "Cięcie Zatopionego Ostrza",
		"special_chance": 0.3,
		"special_attack_bonus": 6,
		"special_damage_type": "water"
	},
	"cursed_sailor":
	{
		"display_name": "Przeklęty Marynarz",
		"max_hp": 720,
		"attack": 48,
		"defense": 16,
		"dodge": 8.0,
		"experience_reward": 500,
		"gold_min": 210,
		"gold_max": 285,
		"special_name": "Zardzewiałe Cięcie",
		"special_chance": 0.22,
		"special_attack_bonus": 10,
		"elemental_resistances": {"water": 25, "frost": 25}
	},
	"black_fleet_drowned":
	{
		"display_name": "Topielec Czarnej Floty",
		"max_hp": 880,
		"attack": 50,
		"defense": 19,
		"dodge": 4.0,
		"experience_reward": 540,
		"gold_min": 225,
		"gold_max": 300,
		"special_name": "Uścisk Topielca",
		"special_chance": 0.24,
		"special_attack_bonus": 11,
		"special_damage_type": "water",
		"elemental_resistances": {"water": 45, "frost": 30}
	},
	"cursed_gunner":
	{
		"display_name": "Przeklęty Kanonier",
		"max_hp": 690,
		"attack": 55,
		"defense": 13,
		"dodge": 6.0,
		"experience_reward": 550,
		"gold_min": 235,
		"gold_max": 315,
		"special_name": "Kartacz",
		"special_chance": 0.28,
		"special_attack_bonus": 15,
		"first_attack_bonus": 4
	},
	"spectral_marksman":
	{
		"display_name": "Widmowy Strzelec",
		"max_hp": 640,
		"attack": 52,
		"defense": 12,
		"dodge": 24.0,
		"experience_reward": 560,
		"gold_min": 240,
		"gold_max": 320,
		"special_name": "Widmowy Strzał",
		"special_chance": 0.26,
		"special_attack_bonus": 13,
		"special_damage_type": "wind",
		"elemental_resistances": {"wind": 35}
	},
	"black_fleet_boatswain":
	{
		"display_name": "Bosman Czarnej Floty",
		"max_hp": 1080,
		"attack": 56,
		"defense": 23,
		"dodge": 8.0,
		"experience_reward": 700,
		"gold_min": 300,
		"gold_max": 390,
		"special_name": "Bosmański Hak",
		"special_chance": 0.28,
		"special_attack_bonus": 14,
		"physical_damage_reduction": 2
	},
	"black_fleet_first_officer":
	{
		"display_name": "Pierwszy Oficer Czarnej Floty",
		"max_hp": 2150,
		"attack": 59,
		"defense": 24,
		"dodge": 18.0,
		"experience_reward": 1450,
		"gold_min": 620,
		"gold_max": 820,
		"rank": "miniboss",
		"special_name": "Oficerska Riposta",
		"special_chance": 0.32,
		"special_attack_bonus": 16,
		"extra_attack_chance": 0.1,
		"status_resistance": 0.35,
		"elemental_resistances": {"water": 40, "frost": 30}
	},
	"admiral_varek":
	{
		"display_name": "Admirał Varek",
		"max_hp": 4300,
		"attack": 63,
		"defense": 27,
		"dodge": 16.0,
		"experience_reward": 3200,
		"gold_min": 1300,
		"gold_max": 1700,
		"rank": "boss",
		"special_name": "Cięcie Admirała",
		"special_chance": 0.3,
		"special_attack_bonus": 17,
		"status_resistance": 0.5,
		"elemental_resistances": {"water": 55, "frost": 35, "wind": 25}
	},
}
