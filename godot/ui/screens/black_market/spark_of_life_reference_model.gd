extends "res://ui/screens/black_market/artifact_reference_mesh.gd"
## Original pale-green spark held by two closed, curved bronze leaves.
## Fixed illustration UVs on authored volumes, never camera-facing cutouts.

const ART = preload("res://assets/items/materials/spark_of_life.png")

var silhouette: PackedVector2Array
var core_outline: PackedVector2Array
var depth_cache := {}


func build(view) -> void:
	initialize(view, ART, Vector2(1254, 1254), 505.0, 1202.0, 1170.0)
	var bronze := reference_material(0.52, 0.53)
	var vein := reference_material(0.57, 0.46)
	# Pale emission belongs to the crystal, not to the enclosing metal leaves.
	var crystal := reference_material(0.08, 0.31, 0.68)
	silhouette = PackedVector2Array(points([
		[766, 33], [750, 52], [743, 85], [749, 115], [754, 151],
		[771, 184], [787, 223], [790, 275], [797, 329], [802, 365],
		[824, 398], [862, 428], [901, 463], [932, 502], [958, 535],
		[977, 514], [990, 478], [1007, 453], [1020, 434], [1022, 405],
		[1011, 380], [987, 359], [1004, 366], [1024, 386], [1036, 415],
		[1035, 449], [1025, 482], [1006, 518], [992, 551], [1005, 615],
		[1010, 682], [1006, 746], [990, 801], [959, 855], [921, 897],
		[877, 944], [825, 981], [772, 1010], [702, 1031], [638, 1047],
		[607, 1067], [584, 1107], [543, 1127], [492, 1139], [468, 1154],
		[476, 1181], [479, 1201], [466, 1193], [444, 1170], [424, 1140],
		[415, 1116], [425, 1093], [453, 1073], [480, 1050], [484, 1026],
		[468, 983], [448, 932], [421, 883], [389, 845], [359, 809],
		[322, 769], [301, 727], [290, 679], [283, 624], [283, 566],
		[289, 502], [293, 445], [307, 397], [329, 356], [365, 318],
		[404, 280], [454, 249], [508, 216], [555, 209], [601, 211],
		[635, 218], [678, 188], [706, 167], [719, 144], [712, 117],
		[718, 85], [736, 53], [752, 35]
	]))
	# Hidden overlap under the metal lips prevents dark assembly seams.
	var core := points([
		[730, 196], [763, 203], [785, 226], [787, 278], [794, 329],
		[802, 367], [824, 401], [862, 435], [899, 470], [928, 512],
		[969, 544], [959, 596], [933, 635], [902, 673], [868, 715],
		[829, 762], [787, 803], [741, 845], [690, 889], [647, 936],
		[598, 980], [550, 1025], [514, 1048], [509, 967], [519, 916], [537, 862],
		[538, 818], [529, 777], [517, 735], [508, 692], [504, 652],
		[492, 611], [477, 567], [460, 514], [460, 457], [468, 409],
		[488, 361], [514, 319], [553, 281], [595, 248], [644, 220], [685, 195]
	])
	core_outline = PackedVector2Array(core)
	solid(core, "LivingCrystal", crystal, _volume_depth, _rear_depth, 3)
	var left_leaf := points([
		[766, 33], [750, 52], [743, 85], [749, 115], [749, 141],
		[739, 164], [716, 184], [684, 204], [641, 227], [597, 252],
		[557, 284], [524, 322], [497, 366], [480, 412], [470, 462],
		[472, 514], [488, 562], [504, 607], [516, 650], [521, 693],
		[531, 735], [543, 776], [551, 819], [549, 865], [532, 919],
		[524, 970], [524, 1015], [498, 1051], [482, 1026], [467, 981],
		[445, 930], [421, 884], [389, 845], [360, 809], [324, 769],
		[304, 726], [293, 679], [286, 623], [286, 566], [292, 503],
		[296, 445], [310, 398], [331, 358], [367, 320], [406, 282],
		[456, 251], [510, 219], [555, 212], [601, 214], [636, 221],
		[680, 190], [709, 168], [722, 144], [715, 117], [721, 87],
		[739, 55], [754, 37]
	])
	var right_leaf := points([
		[988, 360], [1005, 368], [1022, 387], [1034, 416], [1032, 448],
		[1022, 482], [1003, 519], [989, 552], [1002, 615], [1007, 682],
		[1003, 745], [987, 800], [956, 853], [918, 895], [875, 942],
		[823, 978], [770, 1007], [700, 1028], [637, 1044], [605, 1064],
		[580, 1077], [543, 1091], [511, 1109], [484, 1120], [462, 1114],
		[469, 1094], [501, 1071], [532, 1037], [561, 1002], [589, 961],
		[625, 920], [673, 871], [718, 836], [766, 796], [810, 753],
		[852, 709], [889, 664], [921, 621], [948, 575], [972, 526],
		[987, 480], [1004, 454], [1017, 433], [1019, 406], [1008, 382]
	])
	_leaf(left_leaf, "LeftBronzeLeaf", bronze)
	_leaf(right_leaf, "RightBronzeLeaf", bronze)
	var stem := points([
		[490, 1041], [511, 1048], [542, 1044], [577, 1047], [613, 1042],
		[609, 1064], [591, 1090], [582, 1105], [542, 1124], [493, 1136],
		[470, 1147], [464, 1155], [473, 1181], [477, 1199], [465, 1190],
		[446, 1169], [427, 1139], [419, 1117], [428, 1096], [455, 1076], [480, 1058]
	])
	solid(stem, "TwistedStem", vein, _stem_front, _rear_depth, 3)
	var veins := [
		[[597, 227], [563, 250], [526, 277], [487, 313], [450, 353], [417, 395], [388, 443], [367, 493], [351, 548], [342, 606], [344, 665], [357, 726], [385, 788], [420, 850], [453, 923], [484, 1000]],
		[[329, 402], [336, 441], [351, 478], [368, 499]],
		[[475, 353], [470, 399], [451, 439], [416, 469], [368, 499]],
		[[296, 565], [314, 597], [343, 622]],
		[[470, 520], [431, 542], [390, 579], [343, 622]],
		[[511, 659], [464, 688], [419, 718], [369, 752]],
		[[548, 805], [525, 839], [489, 870], [439, 894]],
		[[987, 557], [968, 613], [945, 672], [924, 729], [905, 790], [876, 850], [836, 901], [793, 946], [740, 981], [681, 1004], [620, 1021]],
		[[1004, 684], [973, 718], [925, 737]],
		[[865, 704], [884, 752], [900, 789]],
		[[972, 822], [928, 846], [880, 852]],
		[[776, 793], [815, 850], [836, 901]],
		[[864, 945], [826, 950], [788, 947]],
		[[671, 874], [706, 924], [740, 981]],
		[[591, 974], [604, 1000], [620, 1021]]
	]
	for i in veins.size():
		_make_vein(points(veins[i]), "LeafVein%d" % i, vein)
	lay_on_counter(-28.0)


func _volume_depth(pixel: Vector2) -> float:
	if depth_cache.has(pixel):
		return depth_cache[pixel]
	var distance := _distance_inside(pixel, silhouette)
	var depth := 3.0 + 218.0 * sin(clampf(distance / 290.0, 0.0, 1.0) * PI * 0.5)
	depth_cache[pixel] = depth
	return depth


func _rear_depth(pixel: Vector2) -> float:
	return -_volume_depth(pixel) * 0.64


func _stem_front(pixel: Vector2) -> float:
	return _volume_depth(pixel) + 9.0


func _leaf(outline: Array, label: String, mat: Material) -> void:
	var boundary := PackedVector2Array(outline)
	var front := func(p: Vector2) -> float:
		return _volume_depth(p) + 4.0 + 12.0 * sin(clampf(_distance_inside(p, boundary) / 18.0, 0.0, 1.0) * PI * 0.5)
	# The reverse converges on the outside edge while wrapping around the core.
	solid(outline, label, mat, front, _rear_depth, 3)


func _make_vein(path: Array, label: String, mat: Material) -> void:
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	for i in path.size():
		var direction: Vector2 = path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]
		var normal := Vector2(-direction.y, direction.x).normalized()
		var half_width := 2.5 if i == 0 or i == path.size() - 1 else 4.0
		left.append(path[i] + normal * half_width)
		right.push_front(path[i] - normal * half_width)
	left.append_array(right)
	relief(left, label, mat, _volume_depth, 22.0, 14.0, 2)


func _distance_inside(pixel: Vector2, boundary: PackedVector2Array) -> float:
	if not Geometry2D.is_point_in_polygon(pixel, boundary):
		return 0.0
	var distance := INF
	for i in boundary.size():
		var closest := Geometry2D.get_closest_point_to_segment(pixel, boundary[i], boundary[(i + 1) % boundary.size()])
		distance = minf(distance, pixel.distance_to(closest))
	return distance


func points(values: Array) -> Array:
	var result: Array[Vector2] = []
	for value in values:
		result.append(Vector2(value[0], value[1]))
	return result
