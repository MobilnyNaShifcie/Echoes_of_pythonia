class_name WorldRegionMap
extends Control

signal region_selected(region_id: String)
signal region_hovered(region_id: String)
signal city_selected(city_id: String)

const MAP_REFERENCE_SIZE := Vector2(2560.0, 1440.0)
const INITIAL_ZOOM := 1.0
const DRAG_THRESHOLD := 7.0
const VARENHOLD_ID := "varenhold"
const VARENHOLD_VALLEY_ID := "varenhold_valley"
const ValleyLayout := preload("res://ui/screens/world_map/varenhold_valley_layout.gd")
const VARENHOLD_REFERENCE_RECT := ValleyLayout.REFERENCE_RECT
const REGION_ORDER: Array[String] = [
	"twilight_plains",
	"black_forest",
	"silentwater_marshes",
	"ashen_borderlands",
	"ice_coast",
]
const REGION_ID_CODES := {
	"varenhold_valley": 26,
	"twilight_plains": 51,
	"black_forest": 102,
	"silentwater_marshes": 153,
	"ashen_borderlands": 204,
	"ice_coast": 255,
}
const REGION_ID_TEXTURE := preload("res://assets/world_map/pythonia_region_atlas_v2.png")
var _region_polygons := {
	"twilight_plains":
	PackedVector2Array(
		[
			Vector2(526, 278),
			Vector2(506, 270),
			Vector2(486, 257),
			Vector2(467, 248),
			Vector2(446, 237),
			Vector2(427, 229),
			Vector2(407, 222),
			Vector2(386, 219),
			Vector2(365, 224),
			Vector2(344, 215),
			Vector2(323, 218),
			Vector2(303, 210),
			Vector2(283, 215),
			Vector2(263, 223),
			Vector2(242, 225),
			Vector2(222, 235),
			Vector2(202, 239),
			Vector2(184, 247),
			Vector2(173, 257),
			Vector2(169, 273),
			Vector2(157, 282),
			Vector2(164, 299),
			Vector2(148, 309),
			Vector2(145, 327),
			Vector2(129, 338),
			Vector2(135, 352),
			Vector2(116, 364),
			Vector2(118, 382),
			Vector2(96, 391),
			Vector2(88, 406),
			Vector2(70, 417),
			Vector2(54, 437),
			Vector2(45, 453),
			Vector2(49, 470),
			Vector2(64, 485),
			Vector2(52, 501),
			Vector2(35, 519),
			Vector2(22, 540),
			Vector2(31, 561),
			Vector2(26, 582),
			Vector2(43, 602),
			Vector2(47, 623),
			Vector2(66, 641),
			Vector2(86, 655),
			Vector2(105, 672),
			Vector2(128, 680),
			Vector2(148, 696),
			Vector2(174, 699),
			Vector2(193, 716),
			Vector2(216, 727),
			Vector2(239, 728),
			Vector2(260, 746),
			Vector2(284, 754),
			Vector2(307, 752),
			Vector2(330, 772),
			Vector2(354, 783),
			Vector2(379, 780),
			Vector2(404, 794),
			Vector2(430, 796),
			Vector2(455, 786),
			Vector2(487, 781),
			Vector2(480, 757),
			Vector2(498, 739),
			Vector2(492, 718),
			Vector2(515, 701),
			Vector2(510, 680),
			Vector2(535, 661),
			Vector2(532, 641),
			Vector2(556, 622),
			Vector2(554, 601),
			Vector2(579, 584),
			Vector2(577, 563),
			Vector2(603, 547),
			Vector2(601, 527),
			Vector2(623, 510),
			Vector2(624, 492),
			Vector2(650, 477),
			Vector2(670, 465),
			Vector2(692, 448),
			Vector2(674, 426),
			Vector2(650, 418),
			Vector2(627, 404),
			Vector2(604, 399),
			Vector2(583, 385),
			Vector2(558, 382),
			Vector2(542, 371),
			Vector2(525, 356),
			Vector2(534, 341),
			Vector2(520, 324),
			Vector2(529, 309),
			Vector2(516, 294),
			Vector2(526, 278),
		]
	),
	"black_forest":
	PackedVector2Array(
		[
			Vector2(526, 278),
			Vector2(510, 266),
			Vector2(498, 250),
			Vector2(480, 240),
			Vector2(466, 224),
			Vector2(448, 215),
			Vector2(430, 204),
			Vector2(411, 196),
			Vector2(395, 183),
			Vector2(379, 173),
			Vector2(363, 162),
			Vector2(355, 146),
			Vector2(365, 132),
			Vector2(384, 124),
			Vector2(401, 111),
			Vector2(421, 107),
			Vector2(442, 99),
			Vector2(463, 94),
			Vector2(481, 99),
			Vector2(502, 88),
			Vector2(523, 89),
			Vector2(544, 82),
			Vector2(563, 86),
			Vector2(582, 78),
			Vector2(601, 80),
			Vector2(620, 71),
			Vector2(638, 76),
			Vector2(655, 67),
			Vector2(676, 69),
			Vector2(693, 53),
			Vector2(713, 63),
			Vector2(731, 60),
			Vector2(750, 74),
			Vector2(770, 69),
			Vector2(789, 82),
			Vector2(810, 84),
			Vector2(829, 92),
			Vector2(851, 91),
			Vector2(871, 104),
			Vector2(894, 107),
			Vector2(914, 119),
			Vector2(936, 127),
			Vector2(955, 141),
			Vector2(973, 151),
			Vector2(962, 163),
			Vector2(974, 176),
			Vector2(961, 189),
			Vector2(978, 201),
			Vector2(982, 217),
			Vector2(973, 232),
			Vector2(990, 249),
			Vector2(981, 264),
			Vector2(997, 280),
			Vector2(985, 295),
			Vector2(1000, 312),
			Vector2(988, 329),
			Vector2(1004, 347),
			Vector2(995, 365),
			Vector2(1010, 386),
			Vector2(1001, 405),
			Vector2(1012, 426),
			Vector2(1001, 444),
			Vector2(1004, 461),
			Vector2(1013, 472),
			Vector2(1025, 482),
			Vector2(1037, 496),
			Vector2(1020, 485),
			Vector2(1007, 476),
			Vector2(993, 463),
			Vector2(973, 467),
			Vector2(953, 459),
			Vector2(932, 455),
			Vector2(911, 447),
			Vector2(890, 448),
			Vector2(870, 459),
			Vector2(849, 467),
			Vector2(827, 469),
			Vector2(804, 477),
			Vector2(781, 473),
			Vector2(759, 476),
			Vector2(738, 469),
			Vector2(714, 461),
			Vector2(692, 448),
			Vector2(674, 426),
			Vector2(650, 418),
			Vector2(627, 404),
			Vector2(604, 399),
			Vector2(583, 385),
			Vector2(558, 382),
			Vector2(542, 371),
			Vector2(525, 356),
			Vector2(534, 341),
			Vector2(520, 324),
			Vector2(529, 309),
			Vector2(516, 294),
			Vector2(526, 278),
		]
	),
	"silentwater_marshes":
	PackedVector2Array(
		[
			Vector2(973, 151),
			Vector2(959, 140),
			Vector2(965, 122),
			Vector2(983, 112),
			Vector2(1002, 106),
			Vector2(1020, 102),
			Vector2(1038, 91),
			Vector2(1057, 94),
			Vector2(1075, 87),
			Vector2(1093, 89),
			Vector2(1110, 99),
			Vector2(1125, 115),
			Vector2(1144, 119),
			Vector2(1163, 114),
			Vector2(1181, 123),
			Vector2(1200, 114),
			Vector2(1217, 122),
			Vector2(1236, 118),
			Vector2(1254, 129),
			Vector2(1273, 135),
			Vector2(1294, 143),
			Vector2(1312, 154),
			Vector2(1332, 158),
			Vector2(1350, 170),
			Vector2(1366, 184),
			Vector2(1384, 195),
			Vector2(1403, 205),
			Vector2(1418, 220),
			Vector2(1437, 225),
			Vector2(1454, 237),
			Vector2(1471, 250),
			Vector2(1489, 256),
			Vector2(1506, 270),
			Vector2(1523, 280),
			Vector2(1539, 296),
			Vector2(1554, 312),
			Vector2(1564, 330),
			Vector2(1581, 342),
			Vector2(1601, 348),
			Vector2(1616, 363),
			Vector2(1620, 383),
			Vector2(1607, 399),
			Vector2(1588, 405),
			Vector2(1572, 416),
			Vector2(1552, 420),
			Vector2(1535, 414),
			Vector2(1518, 420),
			Vector2(1503, 411),
			Vector2(1486, 416),
			Vector2(1470, 405),
			Vector2(1453, 408),
			Vector2(1436, 397),
			Vector2(1419, 401),
			Vector2(1401, 394),
			Vector2(1384, 400),
			Vector2(1374, 402),
			Vector2(1361, 412),
			Vector2(1345, 411),
			Vector2(1331, 423),
			Vector2(1314, 422),
			Vector2(1300, 435),
			Vector2(1284, 435),
			Vector2(1269, 449),
			Vector2(1253, 447),
			Vector2(1238, 460),
			Vector2(1221, 456),
			Vector2(1205, 466),
			Vector2(1188, 462),
			Vector2(1172, 474),
			Vector2(1154, 470),
			Vector2(1138, 482),
			Vector2(1122, 476),
			Vector2(1106, 489),
			Vector2(1090, 482),
			Vector2(1072, 494),
			Vector2(1054, 489),
			Vector2(1037, 496),
			Vector2(1021, 490),
			Vector2(1007, 480),
			Vector2(993, 472),
			Vector2(1004, 461),
			Vector2(1001, 444),
			Vector2(1012, 426),
			Vector2(1001, 405),
			Vector2(1010, 386),
			Vector2(995, 365),
			Vector2(1004, 347),
			Vector2(988, 329),
			Vector2(1000, 312),
			Vector2(985, 295),
			Vector2(997, 280),
			Vector2(981, 264),
			Vector2(990, 249),
			Vector2(973, 232),
			Vector2(982, 217),
			Vector2(978, 201),
			Vector2(961, 189),
			Vector2(974, 176),
			Vector2(962, 163),
			Vector2(973, 151),
		]
	),
	"ashen_borderlands":
	PackedVector2Array(
		[
			Vector2(692, 448),
			Vector2(714, 461),
			Vector2(738, 469),
			Vector2(759, 476),
			Vector2(781, 473),
			Vector2(804, 477),
			Vector2(827, 469),
			Vector2(849, 467),
			Vector2(870, 459),
			Vector2(890, 448),
			Vector2(911, 447),
			Vector2(932, 455),
			Vector2(953, 459),
			Vector2(973, 467),
			Vector2(993, 463),
			Vector2(1007, 476),
			Vector2(1020, 485),
			Vector2(1037, 496),
			Vector2(1053, 510),
			Vector2(1061, 526),
			Vector2(1079, 539),
			Vector2(1078, 555),
			Vector2(1094, 571),
			Vector2(1090, 588),
			Vector2(1107, 603),
			Vector2(1103, 621),
			Vector2(1119, 637),
			Vector2(1114, 655),
			Vector2(1127, 673),
			Vector2(1119, 691),
			Vector2(1130, 708),
			Vector2(1120, 727),
			Vector2(1107, 741),
			Vector2(1096, 757),
			Vector2(1080, 769),
			Vector2(1067, 786),
			Vector2(1048, 794),
			Vector2(1032, 808),
			Vector2(1024, 821),
			Vector2(1008, 838),
			Vector2(987, 850),
			Vector2(966, 862),
			Vector2(944, 874),
			Vector2(922, 880),
			Vector2(901, 891),
			Vector2(877, 891),
			Vector2(855, 901),
			Vector2(832, 893),
			Vector2(810, 903),
			Vector2(788, 892),
			Vector2(764, 895),
			Vector2(742, 886),
			Vector2(718, 884),
			Vector2(697, 871),
			Vector2(675, 869),
			Vector2(654, 857),
			Vector2(633, 850),
			Vector2(610, 843),
			Vector2(589, 830),
			Vector2(568, 827),
			Vector2(547, 815),
			Vector2(525, 811),
			Vector2(505, 800),
			Vector2(487, 781),
			Vector2(480, 757),
			Vector2(498, 739),
			Vector2(492, 718),
			Vector2(515, 701),
			Vector2(510, 680),
			Vector2(535, 661),
			Vector2(532, 641),
			Vector2(556, 622),
			Vector2(554, 601),
			Vector2(579, 584),
			Vector2(577, 563),
			Vector2(603, 547),
			Vector2(601, 527),
			Vector2(623, 510),
			Vector2(624, 492),
			Vector2(650, 477),
			Vector2(670, 465),
			Vector2(692, 448),
		]
	),
	"ice_coast":
	PackedVector2Array(
		[
			Vector2(1037, 496),
			Vector2(1054, 489),
			Vector2(1072, 494),
			Vector2(1090, 482),
			Vector2(1106, 489),
			Vector2(1122, 476),
			Vector2(1138, 482),
			Vector2(1154, 470),
			Vector2(1172, 474),
			Vector2(1188, 462),
			Vector2(1205, 466),
			Vector2(1221, 456),
			Vector2(1238, 460),
			Vector2(1253, 447),
			Vector2(1269, 449),
			Vector2(1284, 435),
			Vector2(1300, 435),
			Vector2(1314, 422),
			Vector2(1331, 423),
			Vector2(1345, 411),
			Vector2(1361, 412),
			Vector2(1374, 402),
			Vector2(1392, 386),
			Vector2(1413, 377),
			Vector2(1432, 383),
			Vector2(1453, 376),
			Vector2(1473, 386),
			Vector2(1494, 385),
			Vector2(1516, 398),
			Vector2(1537, 406),
			Vector2(1554, 418),
			Vector2(1575, 427),
			Vector2(1594, 441),
			Vector2(1583, 456),
			Vector2(1589, 471),
			Vector2(1578, 486),
			Vector2(1590, 501),
			Vector2(1575, 518),
			Vector2(1587, 536),
			Vector2(1578, 552),
			Vector2(1590, 570),
			Vector2(1578, 587),
			Vector2(1560, 598),
			Vector2(1542, 610),
			Vector2(1522, 621),
			Vector2(1504, 633),
			Vector2(1486, 645),
			Vector2(1467, 653),
			Vector2(1447, 665),
			Vector2(1428, 676),
			Vector2(1407, 686),
			Vector2(1388, 697),
			Vector2(1367, 707),
			Vector2(1348, 720),
			Vector2(1327, 730),
			Vector2(1308, 743),
			Vector2(1287, 754),
			Vector2(1267, 767),
			Vector2(1247, 778),
			Vector2(1227, 791),
			Vector2(1205, 799),
			Vector2(1184, 811),
			Vector2(1163, 819),
			Vector2(1142, 831),
			Vector2(1122, 838),
			Vector2(1102, 847),
			Vector2(1082, 842),
			Vector2(1064, 831),
			Vector2(1047, 827),
			Vector2(1031, 822),
			Vector2(1024, 821),
			Vector2(1032, 808),
			Vector2(1048, 794),
			Vector2(1067, 786),
			Vector2(1080, 769),
			Vector2(1096, 757),
			Vector2(1107, 741),
			Vector2(1120, 727),
			Vector2(1130, 708),
			Vector2(1119, 691),
			Vector2(1127, 673),
			Vector2(1114, 655),
			Vector2(1119, 637),
			Vector2(1103, 621),
			Vector2(1107, 603),
			Vector2(1090, 588),
			Vector2(1094, 571),
			Vector2(1078, 555),
			Vector2(1079, 539),
			Vector2(1061, 526),
			Vector2(1053, 510),
			Vector2(1037, 496),
		]
	),
}

var _available_region_ids: Array[String] = []
var _selected_region_id := "twilight_plains"
var _hovered_region_id := ""
var _selection_locked := false
var _pan_offset := Vector2.ZERO
var _drag_origin := Vector2.ZERO
var _pan_origin := Vector2.ZERO
var _drag_distance := 0.0
var _dragging := false
var _region_id_image: Image

@onready var _map_texture: TextureRect = get_node("../MapTexture") as TextureRect
@onready var _varenhold_module: TextureRect = get_node("../VarenholdModule") as TextureRect
@onready var _region_borders: TextureRect = get_node("../RegionBorders") as TextureRect


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	mouse_exited.connect(_clear_hover)
	resized.connect(_on_resized)
	_region_id_image = REGION_ID_TEXTURE.get_image()
	_map_texture.material = _map_texture.material.duplicate()
	_varenhold_module.material = _varenhold_module.material.duplicate()
	ValleyLayout.configure_material(_varenhold_module.material as ShaderMaterial)
	for layer: TextureRect in [_map_texture, _varenhold_module]:
		layer.material.set_shader_parameter("region_ids", REGION_ID_TEXTURE)
	_varenhold_module.material.set_shader_parameter(
		"world_rect_uv",
		Vector4(
			VARENHOLD_REFERENCE_RECT.position.x / MAP_REFERENCE_SIZE.x,
			VARENHOLD_REFERENCE_RECT.position.y / MAP_REFERENCE_SIZE.y,
			VARENHOLD_REFERENCE_RECT.size.x / MAP_REFERENCE_SIZE.x,
			VARENHOLD_REFERENCE_RECT.size.y / MAP_REFERENCE_SIZE.y
		)
	)
	_sync_view()
	_sync_highlights()


func configure(
	available_region_ids: Array[String], selected_region_id: String, selection_locked: bool
) -> void:
	_available_region_ids.assign(available_region_ids)
	_selected_region_id = selected_region_id
	_selection_locked = selection_locked
	if is_node_ready():
		_set_hovered_region(_hovered_region_id)
		_sync_highlights()


func select_region(region_id: String) -> void:
	if region_id not in REGION_ORDER:
		return
	_selected_region_id = region_id
	_sync_highlights()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_over_map(event.position):
			_begin_drag(event.position)
			accept_event()
		elif not event.pressed and _dragging:
			_finish_drag(event.position)
			accept_event()
	elif event is InputEventMouseMotion:
		if _dragging:
			_drag_map(event.position)
			accept_event()
		else:
			_set_hovered_region(_region_at(event.position))
			_position_hint(event.position)


func _region_at(local_position: Vector2) -> String:
	if size.x <= 0.0 or size.y <= 0.0 or _region_id_image == null:
		return ""
	var map_scale := _map_scale()
	var reference_position := (local_position - _map_offset(map_scale)) / map_scale
	var pixel := Vector2i(floori(reference_position.x), floori(reference_position.y))
	if (
		pixel.x < 0
		or pixel.y < 0
		or pixel.x >= int(MAP_REFERENCE_SIZE.x)
		or pixel.y >= int(MAP_REFERENCE_SIZE.y)
	):
		return ""
	var region_code := roundi(_region_id_image.get_pixelv(pixel).r * 255.0)
	if region_code == REGION_ID_CODES[VARENHOLD_VALLEY_ID]:
		return _valley_location_at(reference_position)
	for region_id in REGION_ID_CODES:
		if REGION_ID_CODES[region_id] == region_code and region_id in _available_region_ids:
			return region_id
	return ""


func _begin_drag(local_position: Vector2) -> void:
	_dragging = true
	_drag_origin = local_position
	_pan_origin = _pan_offset
	_drag_distance = 0.0
	_set_hovered_region("")
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _drag_map(local_position: Vector2) -> void:
	var drag_delta := local_position - _drag_origin
	_drag_distance = maxf(_drag_distance, drag_delta.length())
	_pan_offset = _clamp_pan(_pan_origin + drag_delta)
	_sync_view()


func _finish_drag(local_position: Vector2) -> void:
	var was_click := (
		maxf(_drag_distance, local_position.distance_to(_drag_origin)) <= DRAG_THRESHOLD
	)
	_dragging = false
	if was_click:
		var region_id := _region_at(local_position)
		if region_id == VARENHOLD_ID and not _selection_locked:
			city_selected.emit(VARENHOLD_ID)
		elif (
			not region_id.is_empty()
			and region_id in _available_region_ids
			and (not _selection_locked or region_id == _selected_region_id)
		):
			region_selected.emit(region_id)
	_set_hovered_region(_region_at(local_position))
	_refresh_cursor()


func _set_hovered_region(region_id: String) -> void:
	if _selection_locked and not region_id.is_empty() and region_id != _selected_region_id:
		region_id = ""
	if region_id == _hovered_region_id:
		_refresh_cursor()
		return
	_hovered_region_id = region_id
	_sync_highlights()
	_refresh_cursor()
	region_hovered.emit(region_id)


func _refresh_cursor() -> void:
	if _dragging:
		mouse_default_cursor_shape = Control.CURSOR_DRAG
	elif _hovered_region_id == VARENHOLD_ID or _hovered_region_id in _available_region_ids:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		mouse_default_cursor_shape = Control.CURSOR_MOVE


func _clear_hover() -> void:
	if not _dragging:
		_set_hovered_region("")


func _on_resized() -> void:
	_pan_offset = _clamp_pan(_pan_offset)
	_sync_view()


func _sync_view() -> void:
	if not is_node_ready() or size.x <= 0.0 or size.y <= 0.0:
		return
	var map_scale := _map_scale()
	var map_offset := _map_offset(map_scale)
	_map_texture.position = map_offset
	_map_texture.size = MAP_REFERENCE_SIZE * map_scale
	_region_borders.position = map_offset
	_region_borders.size = _map_texture.size
	_varenhold_module.position = map_offset + VARENHOLD_REFERENCE_RECT.position * map_scale
	_varenhold_module.size = VARENHOLD_REFERENCE_RECT.size * map_scale


func _sync_highlights() -> void:
	if not is_node_ready():
		return
	var hover_code := float(REGION_ID_CODES.get(_hovered_region_id, -1))
	for layer: TextureRect in [_map_texture, _varenhold_module]:
		layer.material.set_shader_parameter("hover_code", hover_code)
		layer.material.set_shader_parameter("hover_strength", 0.42 if hover_code >= 0.0 else 0.0)
	var city_material := _varenhold_module.material as ShaderMaterial
	city_material.set_shader_parameter(
		"city_hover_strength", 0.46 if _hovered_region_id == VARENHOLD_ID else 0.0
	)


func _valley_location_at(reference_position: Vector2) -> String:
	if not VARENHOLD_REFERENCE_RECT.has_point(reference_position):
		return ""
	var uv := (
		(reference_position - VARENHOLD_REFERENCE_RECT.position) / VARENHOLD_REFERENCE_RECT.size
	)
	var pixel := Vector2i(floori(reference_position.x), floori(reference_position.y))
	if roundi(_region_id_image.get_pixelv(pixel).r * 255.0) != REGION_ID_CODES[VARENHOLD_VALLEY_ID]:
		return ""
	return VARENHOLD_ID if ValleyLayout.is_city(uv) else VARENHOLD_VALLEY_ID


func _position_hint(local_position: Vector2) -> void:
	var hint := get_node("MapHintLabel") as Label
	var desired := local_position + Vector2(18, 24)
	var hint_size := hint.get_minimum_size()
	hint.position = Vector2(
		clampf(desired.x, 8.0, maxf(8.0, size.x - hint_size.x - 8.0)),
		clampf(desired.y, 8.0, maxf(8.0, size.y - hint_size.y - 8.0)),
	)


func _map_scale() -> float:
	return max(size.x / MAP_REFERENCE_SIZE.x, size.y / MAP_REFERENCE_SIZE.y) * INITIAL_ZOOM


func _map_offset(map_scale: float) -> Vector2:
	return (size - MAP_REFERENCE_SIZE * map_scale) * 0.5 + _pan_offset


func _clamp_pan(value: Vector2) -> Vector2:
	var map_size := MAP_REFERENCE_SIZE * _map_scale()
	var limit := Vector2(
		maxf(0.0, (map_size.x - size.x) * 0.5),
		maxf(0.0, (map_size.y - size.y) * 0.5),
	)
	return Vector2(
		clampf(value.x, -limit.x, limit.x),
		clampf(value.y, -limit.y, limit.y),
	)


func _is_over_map(local_position: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(local_position)
