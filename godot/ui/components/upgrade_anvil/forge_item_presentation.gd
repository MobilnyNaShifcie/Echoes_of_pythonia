extends RefCounted
## Forge-only artwork. Never replace an ItemDefinition icon or an equipment instance.
const LANCE := preload("res://assets/ui/blacksmith/caprice_lance_forge_v1.png")
static var _cropped: Dictionary = {}


static func texture_for(item_id: String, fallback: Texture2D) -> Texture2D:
	if item_id != "caprice_lance":
		return _visible_texture(fallback)
	var crop := AtlasTexture.new()
	crop.atlas = LANCE
	crop.region = Rect2(32, 103, 2103, 580)
	return crop


static func _visible_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	if _cropped.has(texture):
		return _cropped[texture]
	var image := texture.get_image()
	if image == null:
		return texture
	if image.is_compressed() and image.decompress() != OK:
		return texture
	var bounds := image.get_used_rect()
	if not bounds.has_area():
		return texture
	var crop := AtlasTexture.new()
	crop.atlas = texture
	crop.region = Rect2(bounds)
	_cropped[texture] = crop
	return crop
