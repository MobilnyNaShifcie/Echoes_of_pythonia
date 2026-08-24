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
	"precise_shot": "res://assets/skills/hunter/precise_shot.png",
	"fire_bolt": "res://assets/skills/mage/fire_bolt.png",
	"fate_thrust": "res://assets/skills/pierrot/fate_thrust.png",
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


func test_golden_slice_assigns_only_the_four_approved_skill_images() -> void:
	for skill_id: String in ALL_SKILL_IDS:
		var skill = SkillCatalogClass.get_definition(skill_id)
		if skill_id in GOLDEN_CARD_ART:
			assert_not_null(skill.card_art, skill_id)
			assert_eq(skill.card_art.resource_path, GOLDEN_CARD_ART[skill_id], skill_id)
			assert_eq(skill.card_art.get_size(), Vector2(1086, 1448), skill_id)
		else:
			assert_null(skill.card_art, "%s must keep its explicit placeholder" % skill_id)


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

	var unfinished = SkillCatalogClass.get_definition("double_roll")
	(
		card
		. configure(
			unfinished.skill_id,
			2,
			unfinished.display_name,
			"7 MANY",
			unfinished.description,
			false,
			CombatActionCardClass.accent_for_class("pierrot"),
			CombatActionCardClass.badge_for_skill(unfinished),
			"POZIOM 7",
			{
				"artwork": unfinished.card_art,
				"mechanic": unfinished.dice_notation(),
				"inspection_mode": true,
			},
		)
	)
	assert_true(card.uses_placeholder())
	assert_null(card.artwork_texture())
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
	var placeholder_card := catalog.skill_cards.get_child(1) as CombatActionCardClass
	assert_eq(placeholder_card.action_id, "armor_break")
	assert_true(placeholder_card.uses_placeholder())
	placeholder_card.pressed.emit()
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
