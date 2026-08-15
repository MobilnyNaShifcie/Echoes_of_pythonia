class_name BookService
extends RefCounted

const BookCatalogClass := preload("res://core/progression/book_catalog.gd")
const BookDefinitionClass := preload("res://core/progression/book_definition.gd")
const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)
const PlayerClassCatalogClass := preload("res://core/player/player_class_catalog.gd")
const TalentCatalogClass := preload("res://core/progression/talent_catalog.gd")


static func get_read_error(player, item_id: String) -> String:
	var book: BookDefinitionClass = BookCatalogClass.get_definition(item_id)
	if book == null:
		return "Ten przedmiot nie jest księgą rozwoju."
	if not player.inventory.has(item_id):
		return "Nie masz tej księgi w plecaku."
	if book.book_type == BookDefinitionClass.MASTERY:
		if book.passive_code in player.unlocked_passive_mastery_ids:
			return "To Mistrzostwo zostało już poznane."
		return ""
	if book.book_type == BookDefinitionClass.PATH_UNLOCK:
		if player.character_class_code != book.character_class_code:
			return (
				"Ta Księga Ścieżki jest przeznaczona dla klasy: %s."
				% _class_name(book.character_class_code)
			)
		if book.path_id in player.unlocked_class_path_ids:
			return "Ta Ścieżka została już poznana."
		return ""
	return "Nieznany rodzaj księgi."


static func read(player, item_id: String) -> Dictionary:
	var error := get_read_error(player, item_id)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var book: BookDefinitionClass = BookCatalogClass.get_definition(item_id)
	if not player.inventory.remove_item(item_id):
		return {"ok": false, "message": "Nie udało się wyjąć księgi z plecaka."}
	if book.book_type == BookDefinitionClass.MASTERY:
		player.unlocked_passive_mastery_ids.append(book.passive_code)
		return {
			"ok": true,
			"message":
			(
				"Poznano Mistrzostwo: %s. Limit pasywki wzrasta do %d."
				% [
					PassiveProgressionServiceClass.PASSIVE_NAMES[book.passive_code],
					PassiveProgressionServiceClass.MASTERY_MAX_RANK,
				]
			),
		}
	player.unlocked_class_path_ids.append(book.path_id)
	var path = TalentCatalogClass.get_path_definition(book.path_id)
	return {"ok": true, "message": "Poznano Ścieżkę: %s." % path.display_name}


static func status_for(player, item_id: String) -> String:
	var error := get_read_error(player, item_id)
	if error.is_empty():
		return "NIEPRZECZYTANA"
	if "już poznane" in error or "już poznana" in error:
		return "POZNANA"
	if "przeznaczona dla klasy" in error:
		return "INNA KLASA"
	return "NIEDOSTĘPNA"


static func _class_name(class_code: String) -> String:
	var definition = PlayerClassCatalogClass.get_definition(class_code)
	return definition.display_name if definition != null else class_code
