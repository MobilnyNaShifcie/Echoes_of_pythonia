extends RefCounted
## Fixed review item lineup; affixes use normal game generation.
## Never reads or modifies an existing player save.

const NewGame := preload("res://core/game/new_game_service.gd")


static func create_session():
	var session = NewGame.new().create_session("Aria", 1, null, "female")
	while session.player.level < 9:
		session.player.gain_experience(session.player.experience_remaining_to_next_level())
	assert(session.player.choose_class("pierrot"))
	for item_id: String in [
		"leather_hood",
		"hunter_gloves",
		"reinforced_boots",
		"nature_earrings",
		"nature_bracelet",
		"nature_ring",
	]:
		session.player.inventory.add(item_id)
		assert(
			(
				session.player.equip_from_inventory(
					session.player.inventory.equipment_items.size() - 1
				)
				!= null
			)
		)
	session.player.inventory.add("strong_healing_potion", 3)
	return session
