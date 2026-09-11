extends "res://ui/screens/black_market/artifact_reference_mesh.gd"
## A heavy fractured stone seal: thick slab, individually raised damaged frame,
## relief crest, faceted inset gem and a real open handle behind the right edge.

const ART = preload("res://assets/items/materials/azhar_sigil.png")


func build(view) -> void:
	initialize(view, ART, Vector2(1254, 1254), 635.0, 1140.0, 1015.0)
	var basalt := reference_material(0.13, 0.84)
	var gold := reference_material(0.60, 0.54)
	var ruby := reference_material(0.30, 0.31, 0.66)
	var outline := points(
		[
			[333, 163],
			[761, 136],
			[947, 352],
			[928, 805],
			[734, 1041],
			[660, 1100],
			[268, 1042],
			[106, 792],
			[145, 387]
		]
	)
	solid(
		outline,
		"BasaltSeal",
		basalt,
		_face_depth,
		func(p: Vector2) -> float: return _face_depth(p) - 170.0,
		3,
		Vector2(130, 45)
	)
	var frame := [
		[[326, 157], [665, 136], [674, 155], [665, 176], [338, 204], [303, 224], [308, 187]],
		[
			[683, 137],
			[771, 125],
			[792, 136],
			[857, 250],
			[876, 289],
			[858, 313],
			[775, 193],
			[743, 169],
			[675, 183]
		],
		[[291, 215], [321, 202], [325, 226], [183, 403], [169, 475], [148, 513], [146, 388]],
		[
			[150, 479],
			[174, 431],
			[176, 504],
			[149, 765],
			[182, 821],
			[166, 859],
			[107, 796],
			[117, 718]
		],
		[
			[168, 813],
			[228, 948],
			[274, 986],
			[369, 1008],
			[366, 1042],
			[270, 1047],
			[237, 1019],
			[158, 841]
		],
		[[276, 993], [615, 1030], [632, 1050], [620, 1066], [322, 1049], [260, 1030]],
		[
			[879, 288],
			[915, 310],
			[958, 377],
			[960, 430],
			[943, 440],
			[924, 396],
			[892, 350],
			[874, 331]
		],
		[
			[924, 417],
			[951, 427],
			[951, 569],
			[936, 608],
			[936, 770],
			[912, 800],
			[897, 775],
			[910, 612]
		],
		[
			[910, 779],
			[929, 805],
			[872, 879],
			[792, 971],
			[765, 976],
			[752, 953],
			[799, 896],
			[852, 840]
		]
	]
	# Deliberately keep the broken lower-right gap visible.
	for i in frame.size():
		relief(points(frame[i]), "BrokenFrame%d" % i, gold, _face_depth, 18.0, 27.0, 2)
	var crest := [
		[
			[488, 252],
			[466, 294],
			[424, 334],
			[400, 377],
			[379, 426],
			[374, 468],
			[388, 511],
			[417, 548],
			[411, 585],
			[358, 568],
			[325, 534],
			[306, 492],
			[301, 449],
			[319, 394],
			[342, 345],
			[362, 321],
			[353, 277],
			[375, 315],
			[418, 285]
		],
		[
			[412, 582],
			[386, 617],
			[359, 664],
			[347, 715],
			[355, 775],
			[382, 816],
			[423, 842],
			[459, 855],
			[475, 897],
			[475, 932],
			[446, 918],
			[401, 902],
			[361, 875],
			[330, 831],
			[309, 782],
			[303, 730],
			[309, 679],
			[330, 634],
			[357, 607]
		],
		[
			[592, 252],
			[626, 276],
			[666, 298],
			[698, 320],
			[741, 261],
			[716, 329],
			[730, 368],
			[753, 426],
			[763, 475],
			[744, 530],
			[714, 558],
			[669, 581],
			[610, 588],
			[626, 557],
			[663, 528],
			[690, 488],
			[702, 451],
			[694, 406],
			[676, 364],
			[648, 319]
		],
		[
			[613, 587],
			[654, 598],
			[694, 620],
			[720, 657],
			[731, 698],
			[718, 752],
			[690, 811],
			[649, 853],
			[600, 884],
			[546, 916],
			[483, 937],
			[489, 893],
			[521, 862],
			[581, 842],
			[629, 815],
			[670, 770],
			[691, 719],
			[690, 680],
			[670, 643],
			[638, 617]
		],
		[[269, 517], [370, 549], [453, 573], [454, 596], [368, 595], [282, 575], [230, 551]],
		[[598, 565], [675, 541], [764, 529], [814, 506], [789, 558], [713, 585], [608, 602]],
		[[511, 331], [529, 387], [526, 461], [503, 490], [486, 453], [494, 388]],
		[[490, 691], [520, 700], [516, 780], [488, 838], [476, 779]]
	]
	for i in crest.size():
		relief(points(crest[i]), "AzharCrest%d" % i, gold, _face_depth, 28.0, 34.0, 2)
	oval_tube(
		Vector2(517, 593),
		Vector2(100, 127),
		9.0,
		_face_depth(Vector2(517, 593)) + 30.0,
		"GemBezel",
		gold
	)
	relief(
		points([[521, 469], [592, 587], [503, 708], [432, 588]]),
		"DiamondMount",
		gold,
		_face_depth,
		35.0,
		42.0,
		2
	)
	faceted_gem(
		Vector2(511, 586),
		Vector2(57, 96),
		_face_depth(Vector2(511, 586)) + 38.0,
		25.0,
		"AzharRuby",
		ruby
	)
	var studs := [
		Vector4(540, 210, 28, 53),
		Vector4(151, 579, 12, 25),
		Vector4(925, 594, 12, 25),
		Vector4(479, 998, 24, 53)
	]
	for i in studs.size():
		var stud: Vector4 = studs[i]
		var center := Vector2(stud.x, stud.y)
		faceted_gem(
			center,
			Vector2(stud.z, stud.w),
			_face_depth(center) + 21.0,
			10.0,
			"FrameStud%d" % i,
			gold
		)
	oval_tube(Vector2(1075, 698), Vector2(79, 186), 15.0, -140.0, "SealHandle", gold)
	lay_on_counter(-12.0)


func _face_depth(pixel: Vector2) -> float:
	return 58.0 + (pixel.x - 550.0) * 0.16 + (pixel.y - 620.0) * 0.035


func points(values: Array) -> Array:
	var result: Array[Vector2] = []
	for value in values:
		result.append(Vector2(value[0], value[1]))
	return result
