extends GutTest

const Catalog := preload("res://ui/presentation/combat_presentation_catalog.gd")
const Visual := preload("res://ui/components/combatant_visual/combatant_visual.tscn")
const APPROVED := [
	"wild_dog",
	"slime",
	"wolf",
	"boar",
	"cursed_scarecrow",
	"plains_spirit",
	"nature_guardian",
	"forest_cultist",
	"rotting_knight",
	"corrupted_bear",
	"black_hart",
	"gallows_wraith",
	"blackwood_executioner",
	"bog_crawler",
	"drowned_dead",
	"swamp_witch",
	"bone_crocodile",
	"mist_walker",
	"drowned_mother",
	"boneburner",
	"red_salamander",
	"hearth_devourer",
	"azhar",
	"frozen_castaway",
	"ice_crab",
]


func test_owner_approved_cutouts_have_safe_alpha_and_no_obsolete_pixel_crop() -> void:
	assert_eq(APPROVED.size(), 25)
	assert_false("venom_spider" in APPROVED)
	for enemy_id: String in APPROVED:
		var presentation := Catalog.enemy_presentation(enemy_id)
		assert_false(presentation.has("crop"), enemy_id)
		assert_false(bool(presentation.get("flip_h", false)), enemy_id)
		var image: Image = presentation.texture.get_image()
		var bounds := image.get_used_rect()
		var dimensions := image.get_size()
		assert_ne(image.detect_alpha(), Image.ALPHA_NONE, enemy_id)
		assert_gte(float(bounds.position.x) / dimensions.x, 0.05, enemy_id)
		assert_gte(float(bounds.position.y) / dimensions.y, 0.05, enemy_id)
		assert_gte(float(dimensions.x - bounds.end.x) / dimensions.x, 0.05, enemy_id)
		assert_gte(float(dimensions.y - bounds.end.y) / dimensions.y, 0.05, enemy_id)


func test_complete_painted_silhouette_fits_the_slot_and_shared_ground_line() -> void:
	var visual = Visual.instantiate()
	add_child_autofree(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	for dimensions: Vector2 in [Vector2(460, 480), Vector2(760, 720)]:
		visual.size = dimensions
		for enemy_id: String in APPROVED:
			var presentation := Catalog.enemy_presentation(enemy_id)
			var source: Texture2D = presentation.texture
			visual.show_static(source, "PRZECIWNIK", enemy_id, presentation)
			await get_tree().process_frame
			var sprite: TextureRect = visual.static_texture
			var atlas: AtlasTexture = sprite.texture as AtlasTexture
			assert_not_null(atlas, enemy_id)
			assert_eq(atlas.region, Rect2(source.get_image().get_used_rect()), enemy_id)
			assert_gte(sprite.position.x, -0.01, enemy_id)
			assert_gte(sprite.position.y, -0.01, enemy_id)
			assert_lte(sprite.position.x + sprite.size.x, dimensions.x + 0.01, enemy_id)
			assert_almost_eq(
				sprite.position.y + sprite.size.y, dimensions.y * 0.965, 0.01, enemy_id
			)
			assert_almost_eq(
				sprite.size.x / sprite.size.y,
				atlas.region.size.x / atlas.region.size.y,
				0.001,
				enemy_id
			)
