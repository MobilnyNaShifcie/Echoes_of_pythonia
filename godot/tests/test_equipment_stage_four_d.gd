extends GutTest

const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const CombatEnemyClass := preload("res://core/combat/enemy.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const EquipmentAffixClass := preload("res://core/items/equipment_affix.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const EquipmentSetCatalogClass := preload("res://core/items/equipment_set_catalog.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")


func test_affix_catalog_generation_and_tier_values_match_terminal_equipment_two() -> void:
	assert_eq(
		(
			EquipmentAffixServiceClass.DEFENSIVE_AFFIXES.size()
			+ EquipmentAffixServiceClass.OFFENSIVE_AFFIXES.size()
		),
		17,
	)
	assert_eq(EquipmentAffixServiceClass.value_for("attack", 1, 5, "weapon"), 2.0)
	assert_eq(EquipmentAffixServiceClass.value_for("earth_resistance", 1, 3, "chest"), 3.0)
	assert_eq(EquipmentAffixServiceClass.value_for("fire_resistance", 2, 5, "belt"), 4.0)
	assert_almost_eq(EquipmentAffixServiceClass.value_for("crit_chance", 1, 5, "belt"), 1.9, 0.001)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var item = ItemCatalogClass.create_equipment_item("nature_amulet", rng)
	var seen := {}
	assert_eq(item.item_power, 1)
	assert_eq(item.affixes.size(), 2)
	assert_eq(EquipmentAffixServiceClass.validate(item.definition, item.affixes), "")
	for affix in item.affixes:
		assert_true(affix.affix_id in EquipmentAffixServiceClass.OFFENSIVE_AFFIXES)
		assert_false(seen.has(affix.affix_id))
		seen[affix.affix_id] = true


func test_better_source_quality_never_lowers_tier_for_the_same_rolls() -> void:
	var normal_rng := RandomNumberGenerator.new()
	var boss_rng := RandomNumberGenerator.new()
	normal_rng.seed = 77
	boss_rng.seed = 77
	var normal_item = ItemCatalogClass.create_equipment_item(
		"north_armor", normal_rng, EquipmentAffixServiceClass.QUALITY_NORMAL
	)
	var boss_item = ItemCatalogClass.create_equipment_item(
		"north_armor", boss_rng, EquipmentAffixServiceClass.QUALITY_BOSS
	)

	assert_eq(normal_item.affixes.size(), 3)
	assert_eq(boss_item.affixes.size(), 3)
	for index in normal_item.affixes.size():
		assert_eq(normal_item.affixes[index].affix_id, boss_item.affixes[index].affix_id)
		assert_gte(boss_item.affixes[index].tier, normal_item.affixes[index].tier)


func test_nature_set_activates_only_with_all_four_terminal_items() -> void:
	var equipment := PlayerEquipmentClass.new()
	for item_id: String in ["nature_amulet", "nature_ring", "nature_bracelet", "nature_earrings"]:
		var definition = ItemCatalogClass.get_definition(item_id)
		assert_eq(definition.set_id, "nature_guardian")
		equipment.equip_and_return_previous(EquipmentItemClass.new(definition))

	var bonuses := equipment.total_bonuses()
	assert_eq(bonuses.attack, 7)
	assert_eq(bonuses.defense, 2)
	assert_eq(bonuses.max_hp, 10)
	assert_eq(bonuses.max_mana, 26)
	assert_eq(bonuses.elemental_resistances.earth, 15)
	assert_eq(bonuses.active_set_names, ["Zestaw Natury"])

	equipment.unequip(PlayerEquipmentClass.RING)
	assert_true(EquipmentSetCatalogClass.active_sets(equipment.slots).is_empty())


func test_affixes_flow_from_item_instance_into_advanced_player_stats() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	var definition = ItemCatalogClass.get_definition("nature_amulet")
	var item := (
		EquipmentItemClass
		. new(
			definition,
			0,
			[
				EquipmentAffixClass.new("attack", 5, 2.0),
				EquipmentAffixClass.new("crit_damage", 5, 8.0),
			],
			1,
		)
	)
	player.equipment.equip_and_return_previous(item)
	player.recalculate_stats()

	assert_eq(player.stats.attack, 7)
	assert_eq(player.stats.max_mana, 8)
	assert_eq(player.stats.crit_damage, 8.0)


func test_three_regional_class_effects_change_real_turn_based_combat() -> void:
	var warrior = _class_player("warrior")
	_equip_raw(warrior, "north_armor")
	var warrior_combat := CombatEngineClass.new(warrior, _enemy(500, 1))
	var defense_report := warrior_combat.player_defend()
	assert_true(warrior_combat.warrior_retribution_ready)
	assert_string_contains("\n".join(defense_report.class_effect_notes), "ODWET")
	var attack_report := warrior_combat.player_attack()
	assert_string_contains("\n".join(attack_report.class_effect_notes), "DEF dodaje")

	var hunter = _class_player("hunter")
	_equip_raw(hunter, "snow_griffin_cloak")
	hunter.stats.dodge = 100.0
	var hunter_combat := CombatEngineClass.new(hunter, _enemy(500, 10))
	var dodge_report := hunter_combat.player_defend()
	assert_true(hunter_combat.hunter_instinct_ready)
	assert_string_contains("\n".join(dodge_report.class_effect_notes), "unik przygotowuje")
	var instinct_report := hunter_combat.player_attack()
	assert_string_contains("\n".join(instinct_report.class_effect_notes), "+20% obrażeń")

	var mage = _class_player("mage")
	_equip_raw(mage, "black_sea_amulet")
	mage.stats.restore_full()
	var mana_before: int = mage.stats.current_mana
	var mage_combat := CombatEngineClass.new(mage, _enemy(1000, 0))
	var mana_report := {}
	for _cast in 4:
		mana_report = mage_combat.player_use_skill("fire_bolt")
	assert_eq(mage.stats.current_mana, mana_before - 19)
	assert_string_contains("\n".join(mana_report.class_effect_notes), "PRZYPŁYW MANY")


func test_skill_and_boss_damage_affixes_are_used_by_hit_resolver() -> void:
	var player = _class_player("mage")
	player.stats.magic_power = 0
	player.attributes.intelligence = 3
	player.stats.skill_damage = 10.0
	player.stats.damage_vs_boss = 20.0
	var combat := CombatEngineClass.new(player, _enemy(1000, 0, {"defense": 0, "rank": "miniboss"}))

	var report := combat.player_use_skill("fire_bolt")

	assert_eq(report.player_damage, 19)


func test_equipment_round_trip_and_schema_six_backfill_preserve_instances() -> void:
	var service := SaveGameServiceClass.new("user://stage_four_d_not_written")
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	var item = ItemCatalogClass.create_equipment_item("nature_amulet", rng)
	session.player.inventory.add_equipment_instance(item)
	var payload: Dictionary = service._serialize_session(session)
	var serialized_item: Dictionary = payload.session.player.inventory.equipment_items[0]

	assert_eq(payload.schema_version, 13)
	assert_eq(serialized_item.item_power, 1)
	assert_eq(serialized_item.affixes.size(), 2)
	var round_trip := service._deserialize_payload(payload, 1)
	assert_true(round_trip.ok, round_trip.message)
	_assert_same_affixes(item, round_trip.session.player.inventory.equipment_items[0])
	var tampered_payload := payload.duplicate(true)
	tampered_payload.session.player.inventory.equipment_items[0].affixes[0].value += 1.0
	var tampered_result := service._deserialize_payload(tampered_payload, 1)
	assert_false(tampered_result.ok)
	assert_string_contains(tampered_result.message, "Nieprawidłowe afiksy")

	var legacy_payload := payload.duplicate(true)
	legacy_payload.schema_version = 6
	_remove_generation_fields(legacy_payload.session.player.equipment)
	_remove_generation_fields_from_inventory(legacy_payload.session.player.inventory)
	_remove_generation_fields_from_inventory(legacy_payload.session.guild_storage)
	var first_migration := service._deserialize_payload(legacy_payload, 1)
	var second_migration := service._deserialize_payload(legacy_payload, 1)
	assert_true(first_migration.ok, first_migration.message)
	assert_true(second_migration.ok, second_migration.message)
	var first_item = first_migration.session.player.inventory.equipment_items[0]
	var second_item = second_migration.session.player.inventory.equipment_items[0]
	assert_eq(first_item.instance_id, item.instance_id)
	_assert_same_affixes(first_item, second_item)


func test_equipment_details_expose_item_power_affixes_sets_and_class_effects() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 16
	assert_true(session.player.choose_class("warrior"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var regional_item = ItemCatalogClass.create_equipment_item("north_armor", rng)
	var set_item = ItemCatalogClass.create_equipment_item("nature_amulet", rng)
	var screen = EQUIPMENT_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)

	var regional_text: String = screen._format_item_details(regional_item)
	var set_text: String = screen._format_item_details(set_item)
	assert_string_contains(regional_text, "Moc przedmiotu: 6")
	assert_string_contains(regional_text, "Afiksy:")
	assert_string_contains(regional_text, "Efekt klasowy — Odwet")
	assert_string_contains(set_text, "Zestaw: Zestaw Natury")


func _class_player(class_code: String):
	var player = NewGameServiceClass.new().create_session("Tester", 1).player
	player.level = 16
	assert_true(player.choose_class(class_code))
	player.stats.restore_full()
	return player


func _equip_raw(player, item_id: String) -> void:
	var definition = ItemCatalogClass.get_definition(item_id)
	player.equipment.equip_and_return_previous(EquipmentItemClass.new(definition))
	player.recalculate_stats()
	player.stats.restore_full()


func _enemy(hp: int, attack: int, extra: Dictionary = {}):
	var data := {
		"enemy_id": "stage_four_d_target",
		"display_name": "Cel etapu 4D",
		"max_hp": hp,
		"attack": attack,
		"defense": 0,
		"dodge": 0.0,
	}
	data.merge(extra, true)
	return CombatEnemyClass.new(data)


func _assert_same_affixes(expected, actual) -> void:
	assert_eq(actual.item_power, expected.item_power)
	assert_eq(actual.affixes.size(), expected.affixes.size())
	for index in expected.affixes.size():
		assert_eq(actual.affixes[index].affix_id, expected.affixes[index].affix_id)
		assert_eq(actual.affixes[index].tier, expected.affixes[index].tier)
		assert_eq(actual.affixes[index].value, expected.affixes[index].value)


func _remove_generation_fields(equipment: Dictionary) -> void:
	for item_data in equipment.values():
		item_data.erase("item_power")
		item_data.erase("affixes")


func _remove_generation_fields_from_inventory(inventory: Dictionary) -> void:
	for item_data in inventory.equipment_items:
		item_data.erase("item_power")
		item_data.erase("affixes")
