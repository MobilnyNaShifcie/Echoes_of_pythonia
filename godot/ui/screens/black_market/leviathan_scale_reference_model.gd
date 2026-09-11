extends "res://ui/screens/black_market/artifact_reference_mesh.gd"
## A closed, bowed shell with raised growth ribs and a separate metal collar.
## Fixed UVs preserve the inventory artwork when the actual model is moved.

const ART = preload("res://assets/items/materials/leviathan_scale.png")

var shell_outline: PackedVector2Array
var depth_cache := {}


func build(view) -> void:
	initialize(view, ART, Vector2(1273, 1236), 822.0, 1190.0, 1166.0)
	var shell := reference_material(0.30, 0.43)
	var edge := reference_material(0.38, 0.50)
	var silver := reference_material(0.62, 0.45)
	var outline := points(
		[
			[349, 27],
			[415, 31],
			[480, 37],
			[524, 51],
			[562, 54],
			[581, 66],
			[607, 62],
			[653, 85],
			[696, 94],
			[729, 109],
			[755, 149],
			[802, 200],
			[850, 255],
			[892, 298],
			[939, 354],
			[985, 410],
			[1020, 465],
			[1050, 531],
			[1073, 584],
			[1090, 628],
			[1096, 678],
			[1088, 745],
			[1074, 801],
			[1056, 857],
			[1039, 895],
			[1029, 934],
			[991, 980],
			[979, 1041],
			[969, 1082],
			[934, 1098],
			[918, 1151],
			[882, 1174],
			[849, 1190],
			[825, 1180],
			[804, 1181],
			[765, 1151],
			[710, 1155],
			[687, 1114],
			[654, 1074],
			[625, 1060],
			[618, 1034],
			[606, 1000],
			[578, 965],
			[536, 940],
			[482, 914],
			[454, 878],
			[426, 824],
			[378, 791],
			[341, 762],
			[307, 732],
			[284, 678],
			[249, 638],
			[237, 580],
			[211, 537],
			[201, 493],
			[210, 440],
			[209, 407],
			[197, 346],
			[209, 288],
			[220, 237],
			[226, 214],
			[244, 177],
			[247, 139],
			[270, 96],
			[280, 71],
			[315, 43]
		]
	)
	shell_outline = PackedVector2Array(outline)
	solid(outline, "IridescentShell", shell, _shell_depth, _rear_depth, 3)
	# Ribs follow the painted ridges, but have rounded relief and real side walls.
	var ribs := [
		[
			[273, 194],
			[342, 197],
			[408, 209],
			[479, 231],
			[551, 260],
			[612, 296],
			[674, 350],
			[741, 419],
			[808, 495],
			[865, 573],
			[909, 646],
			[944, 722],
			[972, 796],
			[990, 861],
			[992, 903],
			[981, 904],
			[977, 864],
			[959, 800],
			[931, 729],
			[896, 653],
			[852, 582],
			[795, 504],
			[728, 431],
			[660, 362],
			[600, 310],
			[540, 278],
			[472, 247],
			[402, 224],
			[339, 211],
			[272, 207]
		],
		[
			[255, 369],
			[304, 361],
			[359, 361],
			[421, 370],
			[478, 389],
			[547, 422],
			[613, 463],
			[680, 514],
			[742, 568],
			[799, 628],
			[847, 694],
			[883, 765],
			[911, 839],
			[929, 914],
			[931, 946],
			[920, 953],
			[916, 916],
			[898, 844],
			[870, 772],
			[834, 702],
			[786, 639],
			[730, 579],
			[668, 526],
			[602, 475],
			[536, 435],
			[469, 403],
			[417, 384],
			[359, 375],
			[306, 374],
			[258, 383]
		],
		[
			[275, 527],
			[321, 516],
			[365, 518],
			[411, 531],
			[463, 554],
			[516, 585],
			[570, 625],
			[625, 674],
			[682, 735],
			[735, 802],
			[779, 875],
			[814, 951],
			[839, 1029],
			[844, 1053],
			[833, 1054],
			[825, 1030],
			[801, 958],
			[766, 882],
			[722, 810],
			[669, 745],
			[612, 684],
			[558, 636],
			[504, 597],
			[453, 567],
			[406, 545],
			[363, 532],
			[321, 530],
			[277, 541]
		]
	]
	for i in ribs.size():
		_rounded_relief(points(ribs[i]), "GrowthRib%d" % i, edge, 12.0)
	var rim := points(
		[
			[348, 31],
			[413, 35],
			[479, 41],
			[529, 58],
			[586, 72],
			[637, 94],
			[699, 116],
			[681, 125],
			[627, 108],
			[581, 88],
			[525, 72],
			[474, 60],
			[417, 59],
			[370, 64],
			[332, 82],
			[306, 117],
			[286, 154],
			[268, 201],
			[251, 251],
			[240, 301],
			[232, 349],
			[249, 399],
			[235, 435],
			[232, 480],
			[251, 522],
			[264, 557],
			[273, 601],
			[297, 644],
			[326, 681],
			[347, 727],
			[384, 766],
			[427, 795],
			[452, 817],
			[478, 869],
			[502, 900],
			[543, 923],
			[588, 951],
			[621, 989],
			[639, 1017],
			[622, 1030],
			[607, 996],
			[577, 962],
			[530, 935],
			[482, 910],
			[453, 873],
			[427, 821],
			[375, 788],
			[340, 758],
			[310, 729],
			[286, 675],
			[253, 635],
			[239, 578],
			[213, 535],
			[205, 491],
			[214, 442],
			[213, 405],
			[202, 346],
			[214, 289],
			[224, 239],
			[230, 216],
			[248, 179],
			[252, 139],
			[274, 98],
			[284, 74],
			[318, 47]
		]
	)
	_rounded_relief(rim, "ArmoredRim", edge, 14.0)
	var collar := points(
		[
			[618, 1027],
			[650, 1021],
			[694, 1006],
			[719, 1001],
			[735, 1018],
			[755, 1046],
			[777, 1055],
			[829, 1047],
			[879, 1035],
			[901, 1023],
			[912, 1000],
			[916, 969],
			[928, 952],
			[970, 940],
			[1002, 924],
			[1035, 898],
			[1027, 938],
			[1009, 965],
			[994, 978],
			[982, 1040],
			[973, 1082],
			[949, 1094],
			[906, 1102],
			[859, 1113],
			[807, 1122],
			[762, 1136],
			[713, 1156],
			[697, 1147],
			[682, 1119],
			[658, 1084],
			[634, 1065],
			[623, 1053]
		]
	)
	_rounded_relief(collar, "WeatheredCollar", silver, 26.0)
	var bevels := [
		[
			[622, 1033],
			[650, 1027],
			[697, 1011],
			[718, 1006],
			[726, 1019],
			[700, 1028],
			[660, 1044],
			[635, 1049],
			[627, 1045]
		],
		[
			[720, 1008],
			[741, 1030],
			[759, 1051],
			[777, 1060],
			[829, 1052],
			[880, 1040],
			[904, 1027],
			[918, 1007],
			[924, 977],
			[929, 961],
			[963, 951],
			[1006, 931],
			[1022, 923],
			[1015, 940],
			[972, 962],
			[942, 971],
			[935, 1009],
			[920, 1039],
			[889, 1057],
			[832, 1070],
			[777, 1080],
			[754, 1069],
			[733, 1046],
			[709, 1026]
		],
		[
			[714, 1144],
			[762, 1127],
			[806, 1114],
			[858, 1104],
			[903, 1094],
			[949, 1085],
			[966, 1075],
			[971, 1083],
			[949, 1097],
			[907, 1107],
			[860, 1118],
			[809, 1128],
			[765, 1140],
			[716, 1158],
			[706, 1151]
		]
	]
	for i in bevels.size():
		relief(points(bevels[i]), "CollarBevel%d" % i, silver, _shell_depth, 34.0, 14.0, 2)
	lay_on_counter(32.0)


func _shell_depth(pixel: Vector2) -> float:
	if depth_cache.has(pixel):
		return depth_cache[pixel]
	# Narrow organic edge, domed center: no thick wall stretching edge pixels.
	var distance := _distance_inside(pixel, shell_outline)
	var depth := 3.0 + 190.0 * sin(clampf(distance / 290.0, 0.0, 1.0) * PI * 0.5)
	depth_cache[pixel] = depth
	return depth


func _rear_depth(pixel: Vector2) -> float:
	return -_shell_depth(pixel) * 0.43


func _rounded_relief(outline: Array, label: String, mat: Material, rise: float) -> void:
	var boundary := PackedVector2Array(outline)
	var front := func(p: Vector2) -> float:
		return (
			_shell_depth(p)
			+ 3.0
			+ rise * sin(clampf(_distance_inside(p, boundary) / 9.0, 0.0, 1.0) * PI * 0.5)
		)
	var rear := func(p: Vector2) -> float: return _shell_depth(p) - 4.0
	solid(outline, label, mat, front, rear, 2)


func _distance_inside(pixel: Vector2, boundary: PackedVector2Array) -> float:
	if not Geometry2D.is_point_in_polygon(pixel, boundary):
		return 0.0
	var distance := INF
	for i in boundary.size():
		var closest := Geometry2D.get_closest_point_to_segment(
			pixel, boundary[i], boundary[(i + 1) % boundary.size()]
		)
		distance = minf(distance, pixel.distance_to(closest))
	return distance


func points(values: Array) -> Array:
	var result: Array[Vector2] = []
	for value in values:
		result.append(Vector2(value[0], value[1]))
	return result
