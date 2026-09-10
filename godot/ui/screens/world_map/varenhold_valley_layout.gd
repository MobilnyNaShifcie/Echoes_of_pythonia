extends RefCounted
## Shared placement, visual coverage and interaction of the independent valley layer.

const REFERENCE_RECT := Rect2(100.0, 350.0, 850.0, 850.0)
const CITY_CENTER_UV := Vector2(0.362, 0.468)
const CITY_POLYGON := [
	Vector2(0.365, 0.310),
	Vector2(0.388, 0.367),
	Vector2(0.422, 0.380),
	Vector2(0.466, 0.399),
	Vector2(0.499, 0.450),
	Vector2(0.506, 0.486),
	Vector2(0.487, 0.523),
	Vector2(0.439, 0.546),
	Vector2(0.366, 0.560),
	Vector2(0.293, 0.540),
	Vector2(0.244, 0.519),
	Vector2(0.216, 0.480),
	Vector2(0.225, 0.435),
	Vector2(0.261, 0.391),
	Vector2(0.311, 0.382),
	Vector2(0.343, 0.398),
]
const NEUTRAL_RANGE := Vector2(0.045, 0.14)
const PALE_RANGE := Vector2(0.62, 0.82)
const WHITE_RANGE := Vector2(0.74, 0.90)
const EAST_BLEND_RANGE := Vector2(0.78, 0.94)
const HIT_ALPHA := 0.55


static func configure_material(material: ShaderMaterial) -> void:
	material.set_shader_parameter("neutral_range", NEUTRAL_RANGE)
	material.set_shader_parameter("pale_range", PALE_RANGE)
	material.set_shader_parameter("white_range", WHITE_RANGE)
	material.set_shader_parameter("east_blend_range", EAST_BLEND_RANGE)
	material.set_shader_parameter("city_polygon", PackedVector2Array(CITY_POLYGON))


static func coverage(sample: Color, uv: Vector2) -> float:
	if not Rect2(Vector2.ZERO, Vector2.ONE).has_point(uv):
		return 0.0
	var highest := maxf(sample.r, maxf(sample.g, sample.b))
	var lowest := minf(sample.r, minf(sample.g, sample.b))
	var neutral := 1.0 - smoothstep(NEUTRAL_RANGE.x, NEUTRAL_RANGE.y, highest - lowest)
	var luminance := sample.r * 0.299 + sample.g * 0.587 + sample.b * 0.114
	var pale := smoothstep(PALE_RANGE.x, PALE_RANGE.y, luminance)
	var white := smoothstep(WHITE_RANGE.x, WHITE_RANGE.y, lowest)
	var alpha := sample.a * (1.0 - maxf(neutral * pale, white))
	return alpha * (1.0 - smoothstep(EAST_BLEND_RANGE.x, EAST_BLEND_RANGE.y, uv.x))


static func is_city(uv: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(uv, PackedVector2Array(CITY_POLYGON))


static func city_reference_position() -> Vector2:
	return REFERENCE_RECT.position + CITY_CENTER_UV * REFERENCE_RECT.size
