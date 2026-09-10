extends RefCounted
## Volumetric reconstruction of the approved illustration, with authored contours
## and fixed UVs. This is not a camera-facing plane: front and back form a closed
## bottle and the fittings have their own depth. The unseen back uses a mirrored
## version of the front artwork. The texture includes painted lighting, so this
## asset is intended for the counter camera rather than physical glass simulation.

const ART = preload("res://assets/items/consumables/grandmaster_elixir.png")
const ART_SIZE := Vector2(1024, 1536)
const PIXEL_SCALE := 0.00104
const AXIS_X := 513.0
const FLOOR_PIXEL := 1515.0
const PITCH := 0.3399
const YAW := 0.05449
const SEGMENTS := 64

# Pixel-space radius / height measurements, bottom to top. These form a closed
# cross-section reconstruction of the octagonal foot, vessel, neck and stopper.
const FOOT := [Vector2(0,1511), Vector2(105,1496), Vector2(192,1465), Vector2(231,1433), Vector2(235,1411), Vector2(215,1394), Vector2(162,1350), Vector2(136,1326)]
const BODY := [Vector2(136,1326), Vector2(147,1274), Vector2(177,1200), Vector2(214,1114), Vector2(250,1025), Vector2(289,935), Vector2(315,850), Vector2(331,779), Vector2(315,735), Vector2(284,687), Vector2(246,639), Vector2(201,591), Vector2(161,548), Vector2(139,507)]
const NECK := [Vector2(139,507), Vector2(132,490), Vector2(128,462), Vector2(128,419), Vector2(126,386), Vector2(130,369), Vector2(120,349), Vector2(128,322), Vector2(151,293), Vector2(163,270), Vector2(160,248), Vector2(139,230)]
const CORK := [Vector2(139,230), Vector2(132,209), Vector2(136,175), Vector2(141,134), Vector2(151,101), Vector2(151,81), Vector2(140,56), Vector2(110,30), Vector2(72,16), Vector2(0,9)]

var host
var surface: StandardMaterial3D


func build(view) -> void:
	host = view
	surface = StandardMaterial3D.new()
	surface.albedo_texture = ART
	surface.albedo_color = Color(0.42, 0.42, 0.42)
	surface.metallic = 0.02
	surface.metallic_specular = 0.12
	surface.roughness = 0.8
	# Preserve the artist's light/reflection design, allowing a modest response to
	# the room's real light. Avoid stacking strong specular over baked highlights.
	surface.emission_enabled = true
	surface.emission_texture = ART
	surface.emission = Color.WHITE
	surface.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	surface.emission_energy_multiplier = 0.58
	build_shell(FOOT, "OctagonalFoot", 0.7, 0.04)
	build_shell(BODY, "FacetedVessel", 0.7, 0.045)
	build_shell(NECK, "LeatherCollarAndLip", 0.7, 0.012)
	build_shell(CORK, "WaxSealedCork", 0.7, 0.015)
	# Front relief follows the actual jewellery in the painting, not invented rings.
	beveled_diamond(Vector2(513,446), Vector2(58,81), 89, "CollarAmethyst")
	beveled_diamond(Vector2(690,770), Vector2(35,59), 196, "HangingAmethyst")
	cord([Vector2(653,498),Vector2(673,538),Vector2(674,578),Vector2(667,620),Vector2(663,664),Vector2(672,707)], 5.0, "LeatherCord")
	cord([Vector2(709,817),Vector2(726,866),Vector2(749,920),Vector2(778,965),Vector2(800,987)], 5.0, "LeatherTail")
	# A low, soft ground contact. Separate geometry, not an item-image rectangle.
	var contact := CylinderMesh.new()
	contact.top_radius = 0.21
	contact.bottom_radius = 0.21
	contact.height = 0.001
	contact.radial_segments = 48
	var shadow := ShaderMaterial.new()
	shadow.shader = preload("res://ui/screens/black_market/elixir_contact.gdshader")
	var node = host.mesh_node(contact, Vector3(0, 0.01, 0), shadow)
	node.name = "ContactShadow"
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func point(pixel: Vector2, depth_pixels: float) -> Vector3:
	var z := depth_pixels * PIXEL_SCALE
	# Cross-section centers follow the photograph; slight shear compensates the
	# oblique reference camera. UV coordinates stay attached during any rotation.
	var y := (FLOOR_PIXEL - pixel.y) * PIXEL_SCALE / cos(PITCH) + z * tan(PITCH) + 0.035
	return Vector3((pixel.x - AXIS_X) * PIXEL_SCALE, y, z).rotated(Vector3.UP, YAW)


func build_shell(profile: Array, label: String, depth_ratio: float, bevel: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in profile.size() - 1:
		for side in SEGMENTS:
			var vertices: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for corner: Vector2i in [Vector2i(side,row),Vector2i(side+1,row),Vector2i(side,row+1),Vector2i(side+1,row+1)]:
				var theta := TAU * corner.x / SEGMENTS
				var sample: Vector2 = profile[corner.y]
				var flute := 1.0 - bevel * (1.0 - cos(theta * 8.0)) * 0.5
				var x := cos(theta) * sample.x * flute
				var z := sin(theta) * sample.x * depth_ratio * flute
				var px := Vector2(AXIS_X + x, sample.y)
				vertices.append(point(px, z))
				uvs.append(px / ART_SIZE)
			for index in [0, 1, 2, 1, 3, 2]:
				st.set_uv(uvs[index])
				st.add_vertex(vertices[index])
	st.generate_normals()
	st.index()
	var node = host.mesh_node(st.commit(), Vector3.ZERO, surface)
	node.name = label


func beveled_diamond(center: Vector2, extent: Vector2, depth: float, label: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shape := [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]
	for i in 4:
		var j := (i + 1) % 4
		var a: Vector2 = center + shape[i] * extent
		var b: Vector2 = center + shape[j] * extent
		var inner_a := center.lerp(a, 0.78)
		var inner_b := center.lerp(b, 0.78)
		for tri in [[a,inner_a,b],[b,inner_a,inner_b],[inner_a,center,inner_b]]:
			for px: Vector2 in tri:
				var raised := 17.0 if px == center else (10.0 if px == inner_a or px == inner_b else 0.0)
				st.set_uv(px / ART_SIZE)
				st.add_vertex(point(px, depth + raised))
	st.generate_normals()
	var material_copy := surface.duplicate() as StandardMaterial3D
	material_copy.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node = host.mesh_node(st.commit(), Vector3.ZERO, material_copy)
	node.name = label


func surface_depth(pixel: Vector2) -> float:
	var profile := BODY + NECK
	for i in profile.size() - 1:
		var low: Vector2 = profile[i]
		var high: Vector2 = profile[i + 1]
		if pixel.y <= low.y and pixel.y >= high.y and low.y != high.y:
			var radius := lerpf(low.x, high.x, inverse_lerp(low.y, high.y, pixel.y))
			return sqrt(maxf(0, radius * radius - pow(pixel.x - AXIS_X, 2))) * 0.7
	return 0.0


func cord(path: Array, width: float, label: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in path.size() - 1:
		for j in 12:
			var points: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for corner: Vector2i in [Vector2i(j,i),Vector2i(j+1,i),Vector2i(j,i+1),Vector2i(j+1,i+1)]:
				var a := TAU * corner.x / 12.0
				var p: Vector2 = path[corner.y]
				p.x += cos(a) * width
				points.append(point(p, surface_depth(path[corner.y]) + 4.0 + sin(a) * width))
				uvs.append(p / ART_SIZE)
			for index in [0,2,1,1,2,3]:
				st.set_uv(uvs[index])
				st.add_vertex(points[index])
	st.generate_normals()
	var node = host.mesh_node(st.commit(), Vector3.ZERO, surface)
	node.name = label
