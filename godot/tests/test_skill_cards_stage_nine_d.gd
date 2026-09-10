extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const COMBAT_ACTION_CARD_SCENE := preload(
	"res://ui/components/combat_action_card/combat_action_card.tscn"
)
const CombatActionCardClass := preload(
	"res://ui/components/combat_action_card/combat_action_card.gd"
)
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const SKILLS_SCENE := preload("res://ui/screens/skills/skills.tscn")
const SkillsScreenClass := preload("res://ui/screens/skills/skills.gd")

const GOLDEN_CARD_ART := {
	"power_slash": "res://assets/skills/warrior/power_slash.png",
	"armor_break": "res://assets/skills/warrior/armor_break.png",
	"defensive_stance": "res://assets/skills/warrior/defensive_stance.png",
	"blood_strike": "res://assets/skills/warrior/blood_strike.png",
	"shield_bash": "res://assets/skills/warrior/shield_bash.png",
	"provoke": "res://assets/skills/warrior/provoke.png",
	"precise_shot": "res://assets/skills/hunter/precise_shot.png",
	"bleeding_shot": "res://assets/skills/hunter/bleeding_shot.png",
	"shadow_step": "res://assets/skills/hunter/shadow_step.png",
	"double_shot": "res://assets/skills/hunter/double_shot.png",
	"piercing_arrow": "res://assets/skills/hunter/piercing_arrow.png",
	"frost_arrow": "res://assets/skills/hunter/frost_arrow.png",
	"explosive_arrow": "res://assets/skills/hunter/explosive_arrow.png",
	"phantom_arrow": "res://assets/skills/hunter/phantom_arrow.png",
	"rain_of_arrows": "res://assets/skills/hunter/rain_of_arrows.png",
	"splitting_arrow": "res://assets/skills/hunter/splitting_arrow.png",
	"thousand_arrows": "res://assets/skills/hunter/thousand_arrows.png",
	"fire_bolt": "res://assets/skills/mage/fire_bolt.png",
	"frost_lance": "res://assets/skills/mage/frost_lance.png",
	"lightning": "res://assets/skills/mage/lightning.png",
	"mana_burst": "res://assets/skills/mage/mana_burst.png",
	"fate_thrust": "res://assets/skills/pierrot/fate_thrust.png",
	"double_roll": "res://assets/skills/pierrot/double_roll.png",
	"fate_feint": "res://assets/skills/pierrot/fate_feint.png",
	"grand_gamble": "res://assets/skills/pierrot/grand_gamble.png",
	"va_banque": "res://assets/skills/pierrot/va_banque.png",
}
const ALL_SKILL_IDS := [
	"power_slash",
	"armor_break",
	"defensive_stance",
	"blood_strike",
	"shield_bash",
	"provoke",
	"precise_shot",
	"bleeding_shot",
	"shadow_step",
	"double_shot",
	"piercing_arrow",
	"frost_arrow",
	"explosive_arrow",
	"phantom_arrow",
	"rain_of_arrows",
	"splitting_arrow",
	"thousand_arrows",
	"fire_bolt",
	"frost_lance",
	"lightning",
	"mana_burst",
	"fate_thrust",
	"double_roll",
	"fate_feint",
	"grand_gamble",
	"va_banque",
]


func test_approved_catalog_assigns_each_skill_its_own_image() -> void:
	var assigned_paths: Array[String] = []
	for skill_id: String in ALL_SKILL_IDS:
		var skill = SkillCatalogClass.get_definition(skill_id)
		assert_not_null(skill.card_art, skill_id)
		assert_eq(skill.card_art.resource_path, GOLDEN_CARD_ART[skill_id], skill_id)
		assert_eq(skill.card_art.get_size(), Vector2(1086, 1448), skill_id)
		assigned_paths.append(skill.card_art.resource_path)
	assert_eq(assigned_paths.size(), 26)
	assert_eq(_unique_strings(assigned_paths).size(), 26)


func test_shared_card_clips_art_and_keeps_ui_owned_metadata() -> void:
	var card := COMBAT_ACTION_CARD_SCENE.instantiate() as CombatActionCardClass
	add_child_autofree(card)
	var skill = SkillCatalogClass.get_definition("fate_thrust")
	(
		card
		. configure(
			skill.skill_id,
			1,
			skill.display_name,
			"5 MANY",
			skill.description,
			true,
			CombatActionCardClass.accent_for_class("pierrot"),
			CombatActionCardClass.badge_for_skill(skill),
			"GOTOWA",
			{"artwork": skill.card_art, "mechanic": skill.dice_notation()},
		)
	)
	assert_true(card.clip_contents)
	assert_eq(card.artwork_texture(), skill.card_art)
	assert_false(card.uses_placeholder())
	assert_eq(card.mechanic_badge(), "1K6")
	assert_eq(card.badge_label.text, "LOS")
	assert_eq(card.cost_label.text, "5 MANY")
	assert_eq(card.state_label.text, "GOTOWA")
	assert_string_contains(card.text, "PCHNIĘCIE LOSU")

	var inspection_skill = SkillCatalogClass.get_definition("double_roll")
	(
		card
		. configure(
			inspection_skill.skill_id,
			2,
			inspection_skill.display_name,
			"7 MANY",
			inspection_skill.description,
			false,
			CombatActionCardClass.accent_for_class("pierrot"),
			CombatActionCardClass.badge_for_skill(inspection_skill),
			"POZIOM 7",
			{
				"artwork": inspection_skill.card_art,
				"mechanic": inspection_skill.dice_notation(),
				"inspection_mode": true,
			},
		)
	)
	assert_false(card.uses_placeholder())
	assert_eq(card.artwork_texture(), inspection_skill.card_art)
	assert_eq(card.mechanic_badge(), "2K6")
	assert_false(card.disabled)


func test_combat_and_catalog_use_the_same_art_without_changing_actions() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("warrior"))
	var combat := COMBAT_SCENE.instantiate() as CombatScreenClass
	combat.configure(session, "wolf", "expedition")
	add_child_autofree(combat)
	var combat_card := combat.skill_cards.get_child(0) as CombatActionCardClass
	assert_eq(combat_card.action_id, "power_slash")
	assert_eq(combat_card.artwork_texture().resource_path, GOLDEN_CARD_ART.power_slash)
	assert_false(combat_card.uses_placeholder())

	var catalog := SKILLS_SCENE.instantiate() as SkillsScreenClass
	catalog.configure(session)
	add_child_autofree(catalog)
	assert_eq(catalog.skill_cards.get_child_count(), catalog.skill_list.item_count)
	var catalog_card := catalog.skill_cards.get_child(0) as CombatActionCardClass
	assert_eq(catalog_card.action_id, "power_slash")
	assert_eq(catalog_card.artwork_texture(), combat_card.artwork_texture())
	var second_card := catalog.skill_cards.get_child(1) as CombatActionCardClass
	assert_eq(second_card.action_id, "armor_break")
	assert_false(second_card.uses_placeholder())
	assert_eq(second_card.artwork_texture().resource_path, GOLDEN_CARD_ART.armor_break)
	second_card.pressed.emit()
	assert_eq(catalog.skill_name_label.text, "Roztrzaskanie Pancerza")


func test_pierrot_card_declares_dice_count_but_combat_still_owns_the_roll() -> void:
	assert_eq(SkillCatalogClass.get_definition("fate_thrust").dice_notation(), "1K6")
	assert_eq(SkillCatalogClass.get_definition("double_roll").dice_notation(), "2K6")
	assert_eq(SkillCatalogClass.get_definition("fate_feint").dice_notation(), "1K6")
	assert_eq(SkillCatalogClass.get_definition("grand_gamble").dice_notation(), "3K6")
	assert_eq(SkillCatalogClass.get_definition("va_banque").dice_notation(), "3K6")
	assert_eq(SkillCatalogClass.get_definition("power_slash").dice_notation(), "")

	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("pierrot"))
	var combat := COMBAT_SCENE.instantiate() as CombatScreenClass
	combat.configure(session, "wolf", "expedition")
	add_child_autofree(combat)
	var card := combat.skill_cards.get_child(0) as CombatActionCardClass
	assert_eq(card.mechanic_badge(), "1K6")
	assert_eq(card.artwork_texture().resource_path, GOLDEN_CARD_ART.fate_thrust)
	assert_eq(combat.dice_row.get_child_count(), 0)
	card.pressed.emit()
	assert_true(combat.dice_row.visible)
	assert_eq(combat.dice_row.get_child_count(), 1)


func test_skill_cards_stay_inside_supported_full_hd_and_fallback_layouts() -> void:
	for viewport_size: Vector2 in [Vector2(1920, 1080), Vector2(1280, 720)]:
		var host := Control.new()
		host.size = viewport_size
		add_child(host)
		var session = NewGameServiceClass.new().create_session("Aria", 1)
		session.player.level = 5
		assert_true(session.player.choose_class("mage"))

		var combat := COMBAT_SCENE.instantiate() as CombatScreenClass
		combat.configure(session, "wolf", "expedition")
		host.add_child(combat)
		await get_tree().process_frame
		var combat_card := combat.skill_cards.get_child(0) as CombatActionCardClass
		assert_lte(combat.get_global_rect().end.y, host.get_global_rect().end.y)
		assert_lte(
			combat_card.get_global_rect().end.y,
			combat.skill_cards_scroll.get_global_rect().end.y,
		)
		host.remove_child(combat)
		combat.free()

		var catalog := SKILLS_SCENE.instantiate() as SkillsScreenClass
		catalog.configure(session)
		host.add_child(catalog)
		await get_tree().process_frame
		var first_card := catalog.skill_cards.get_child(0) as CombatActionCardClass
		assert_lte(catalog.get_global_rect().end.y, host.get_global_rect().end.y)
		assert_lte(
			first_card.get_global_rect().end.x,
			catalog.get_node("Page/Body/CatalogPanel").get_global_rect().end.x,
		)
		host.free()


func _unique_strings(values: Array[String]) -> Dictionary:
	var unique := {}
	for value: String in values:
		unique[value] = true
	return unique
