extends RefCounted
## Forge-only artwork. Never replace an ItemDefinition icon or an equipment instance.
const LANCE := preload("res://assets/ui/blacksmith/caprice_lance_forge_v1.png")


static func texture_for(item_id: String, fallback: Texture2D) -> Texture2D:
	if item_id != "caprice_lance":
		return fallback
	var crop := AtlasTexture.new()
	crop.atlas = LANCE
	crop.region = Rect2(32, 103, 2103, 580)
	return crop
