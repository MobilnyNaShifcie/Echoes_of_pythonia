extends "res://ui/screens/black_market/artifact_reference_mesh.gd"
## The inventory illustration is mapped onto closed obsidian, bone and metal
## volumes. The loops are hollow geometry, not transparent illustration planes.

const ART = preload("res://assets/items/materials/hearth_core.png")

var body_outline: PackedVector2Array
var depth_cache := {}


func build(view) -> void:
	initialize(view, ART, Vector2(1082,1454), 475.0, 1360.0, 1337.0)
	var rock := reference_material(0.18,0.80)
	var bone := reference_material(0.08,0.68)
	var gold := reference_material(0.62,0.48)
	var ember := reference_material(0.10,0.42,0.72)
	var body := points([[598,20],[575,127],[600,166],[660,230],[774,273],[809,356],[828,479],[864,525],[889,635],[873,782],[815,941],[757,1080],[717,1143],[640,1235],[563,1313],[510,1327],[471,1357],[427,1318],[379,1300],[346,1228],[326,1152],[334,1073],[282,947],[238,857],[204,744],[195,659],[213,594],[196,506],[218,395],[237,320],[281,333],[309,254],[362,161],[384,185],[441,132]])
	body_outline = PackedVector2Array(body)
	solid(body,"ObsidianBody",rock,_body_depth,func(p: Vector2) -> float: return -_body_depth(p)*0.82,3)
	# Raised angular plates break the silhouette's broad curved mass into rock.
	var plates := [
		[[598,20],[565,214],[512,332],[450,404],[433,356],[442,259],[497,184]],
		[[360,190],[385,269],[347,371],[302,485],[274,614],[222,548],[234,399]],
		[[657,241],[738,282],[777,345],[748,427],[677,508],[594,555],[606,457],[652,357]],
		[[221,640],[279,683],[324,753],[347,858],[295,946],[256,843],[209,741]],
		[[759,756],[837,706],[850,811],[805,924],[749,1011],[687,1042],[675,964]],
		[[455,1091],[532,1146],[567,1229],[524,1297],[471,1349],[422,1305],[392,1234]]
	]
	for i in plates.size():
		relief(points(plates[i]),"ObsidianPlate%d"%i,rock,_body_depth,9.0,15.0,2)
	var windows := [
		[[364,470],[398,426],[430,405],[485,363],[557,327],[552,407],[592,443],[525,490],[479,550],[438,594],[421,582],[413,523]],
		[[513,739],[541,712],[558,684],[647,631],[707,588],[691,653],[650,725],[644,801],[612,850],[586,921],[553,946],[514,898],[488,840]]
	]
	for i in windows.size():
		relief(points(windows[i]),"MoltenWindow%d"%i,ember,_body_depth,3.0,8.0,3)
	var bindings := [
		[[795,200],[859,298],[865,386],[832,463],[766,519],[663,575],[547,644],[386,732],[307,804],[261,896],[239,922],[241,866],[268,810],[307,752],[400,681],[560,584],[652,522],[753,457],[786,391],[799,316]],
		[[892,438],[943,519],[945,595],[927,657],[901,702],[843,747],[747,796],[608,854],[482,922],[411,1000],[370,1085],[342,1139],[335,1085],[350,1005],[391,948],[451,890],[571,818],[750,742],[822,689],[861,638],[874,602],[893,596],[903,550],[886,504]],
		[[266,302],[252,353],[265,404],[307,468],[360,518],[412,547],[396,575],[343,550],[279,505],[239,455],[220,397],[222,355]],
		[[301,951],[347,986],[437,1030],[568,1086],[683,1119],[720,1093],[756,1126],[711,1165],[659,1188],[616,1223],[585,1250],[589,1204],[616,1171],[522,1125],[420,1078],[348,1028]],
		[[390,1197],[435,1216],[487,1251],[523,1288],[514,1321],[483,1298],[444,1263],[404,1238]]
	]
	for i in bindings.size():
		relief(points(bindings[i]),"BoneBinding%d"%i,bone,_body_depth,24.0,35.0,3)
	oval_tube(Vector2(872,834),Vector2(49,63),8.0,85.0,"PendantSuspension",gold)
	for i in 4:
		oval_tube(Vector2(870+(i%2)*-4,907+i*19),Vector2(9,13),3.2,90+i*2,"PendantChain%d"%i,gold)
	var charm := points([[868,956],[880,978],[898,973],[897,991],[919,1008],[910,1023],[919,1040],[902,1044],[901,1062],[886,1056],[879,1080],[868,1065],[852,1075],[846,1056],[827,1055],[835,1037],[817,1025],[833,1012],[827,995],[846,998],[849,977],[862,984]])
	solid(charm,"SunCharm",gold,func(_p: Vector2) -> float: return 113.0,func(_p: Vector2) -> float: return 99.0,1)
	faceted_gem(Vector2(872,1022),Vector2(15,26),118.0,12.0,"CharmAmber",ember)
	solid(points([[873,1088],[889,1108],[869,1150],[856,1113]]),"CharmTail",gold,func(_p: Vector2) -> float: return 108.0,func(_p: Vector2) -> float: return 99.0,1)
	lay_on_counter(40.0)


func _body_depth(pixel: Vector2) -> float:
	if depth_cache.has(pixel):
		return depth_cache[pixel]
	# Front and rear converge at the irregular silhouette. A broad extrusion
	# wall would stretch one row of edge pixels into stripes when turned.
	var distance := 0.0
	if Geometry2D.is_point_in_polygon(pixel,body_outline):
		distance = INF
		for i in body_outline.size():
			var nearest := Geometry2D.get_closest_point_to_segment(pixel,body_outline[i],body_outline[(i+1)%body_outline.size()])
			distance = minf(distance,pixel.distance_to(nearest))
	var depth := 4.0+210.0*sqrt(clampf(distance/210.0,0.0,1.0))
	depth_cache[pixel] = depth
	return depth


func points(values: Array) -> Array:
	var result: Array[Vector2] = []
	for value in values:
		result.append(Vector2(value[0],value[1]))
	return result
