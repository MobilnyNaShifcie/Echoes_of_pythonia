extends RefCounted
## Presentation only: never remap drop rarity, prices, affixes or save data.

const ORDER := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
const COLORS := {
	"common": Color("#8b929c"),
	"uncommon": Color("#4ab875"),
	"rare": Color("#4f96e8"),
	"epic": Color("#aa69dc"),
	"legendary": Color("#e35b62"),
	"mythic": Color("#f49b3f"),
}
const LABELS := {
	"common": "Zwykły",
	"uncommon": "Niepospolity",
	"rare": "Rzadki",
	"epic": "Epicki",
	"legendary": "Legendarny",
	"mythic": "Mityczny",
}


static func normalize(value: String) -> String:
	var key := value.strip_edges().to_lower()
	return key if COLORS.has(key) else "common"


static func color_for(value: String) -> Color:
	return COLORS[normalize(value)]


static func label_for(value: String) -> String:
	return LABELS[normalize(value)]
