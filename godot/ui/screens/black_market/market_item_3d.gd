extends SubViewportContainer
## Live geometry for the counter. Illustration-derived textures are mapped onto
## solid meshes; item images are never displayed as camera-facing planes.

var viewport_3d: SubViewport
var model: Node3D
var key_light: DirectionalLight3D
var current_item := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(320, 240)
	viewport_3d.transparent_bg = true
	viewport_3d.own_world_3d = true
	viewport_3d.msaa_3d = Viewport.MSAA_4X
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport_3d)
	var world := Node3D.new()
	viewport_3d.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0, 0, 0, 0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("ada19a")
	environment.environment.ambient_light_energy = 0.48
	world.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.25
	camera.position = Vector3(0.3, 2.6, 5.5)
	world.add_child(camera)
	camera.look_at(Vector3(0, 0.65, 0))
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-48, -38, 0)
	key_light.light_color = Color("ffcf92")
	key_light.light_energy = 1.05
	key_light.shadow_enabled = true
	world.add_child(key_light)
	model = Node3D.new()
	world.add_child(model)
	if not current_item.is_empty():
		build(current_item)


func highlight(active: bool) -> void:
	if key_light:
		key_light.light_energy = 1.3 if active else 1.05


func build(item_id: String) -> void:
	if model and current_item == item_id and model.get_child_count() > 0:
		return
	current_item = item_id
	if not model:
		return
	for child in model.get_children():
		child.free()
	if item_id.is_empty():
		return
	var bronze := material("6c5236", 0.65, 0.5)
	if item_id == "grandmaster_elixir":
		preload("res://ui/screens/black_market/elixir_reference_model.gd").new().build(self)
		return
	if item_id == "black_pearl":
		preload("res://ui/screens/black_market/black_pearl_reference_model.gd").new().build(self)
		return
	if item_id == "mastery_attack_speed_book":
		preload("res://ui/screens/black_market/swift_blade_manuscript_reference_model.gd").new().build(self)
		return
	if item_id == "hearth_core":
		preload("res://ui/screens/black_market/hearth_core_reference_model.gd").new().build(self)
		return
	if item_id == "azhar_sigil":
		preload("res://ui/screens/black_market/azhar_sigil_reference_model.gd").new().build(self)
		return
	if item_id == "leviathan_scale":
		preload("res://ui/screens/black_market/leviathan_scale_reference_model.gd").new().build(self)
		return
	if item_id == "spark_of_life":
		preload("res://ui/screens/black_market/spark_of_life_reference_model.gd").new().build(self)
		return
	match item_id:
		"common_essence":
			var gem := material("7796b1", 0.25, 0.3)
			for i in 5:
				var crystal := cylinder(0.11 + i * 0.014, 0.0, 0.65 + (i % 3) * 0.19, Vector3((i - 2) * 0.16, 0.43, (i % 2) * 0.13 - 0.05), gem, 5)
				crystal.rotation_degrees.z = (i - 2) * -12.0
		_:
			# The remaining rotation entries are mastery/path books.
			var leather := material("453334", 0.0, 0.85)
			box(Vector3(0.72, 0.12, 0.85), Vector3(0, 0.21, 0), material("b9a788", 0, 1))
			for y in [0.135, 0.29]:
				box(Vector3(0.8, 0.035, 0.9), Vector3(0, y, 0), leather)
			box(Vector3(0.065, 0.03, 0.9), Vector3(-0.23, 0.32, 0), bronze)
			box(Vector3(0.065, 0.03, 0.9), Vector3(0.23, 0.32, 0), bronze)
			box(Vector3(0.2, 0.04, 0.22), Vector3(0, 0.33, 0), bronze)
			box(Vector3(0.06, 0.18, 0.86), Vector3(-0.38, 0.21, 0), leather)
			for i in 4:
				box(Vector3(0.71, 0.006, 0.85), Vector3(0, 0.17 + i * 0.027, 0), material("79654c", 0, 1))
			for x in [-0.32, 0.32]:
				for z in [-0.38, 0.38]:
					box(Vector3(0.13, 0.012, 0.12), Vector3(x, 0.318, z), bronze)
	_place_legacy_on_counter(item_id == "common_essence")


func _place_legacy_on_counter(on_side: bool) -> void:
	var bounds := AABB()
	var first := true
	for part: MeshInstance3D in model.get_children():
		if on_side:
			part.transform = Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3.ZERO) * part.transform
		var box: AABB = part.transform * part.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var center := bounds.get_center()
	var offset := Vector3(-center.x, 0.018 - bounds.position.y, -center.z)
	for part: MeshInstance3D in model.get_children():
		part.position += offset
	var plane := PlaneMesh.new()
	plane.size = Vector2(bounds.size.x + 0.12, bounds.size.z + 0.12)
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded,cull_disabled,depth_draw_never; void fragment(){float r=length((UV-vec2(0.5))*2.0); ALBEDO=vec3(0.025,0.012,0.006); ALPHA=0.38*(1.0-smoothstep(0.15,1.0,r));}"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var contact := mesh_node(plane, Vector3(0, 0.004, 0), mat)
	contact.name = "ContactShadow"
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func material(hex: String, metallic: float, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(hex)
	result.metallic = metallic
	result.roughness = roughness
	return result


func mesh_node(mesh: Mesh, position_3d: Vector3, surface: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = surface
	node.position = position_3d
	model.add_child(node)
	return node


func box(dimensions: Vector3, pos: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return mesh_node(mesh, pos, surface)


func cylinder(bottom: float, top: float, height: float, pos: Vector3, surface: Material, sides := 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	return mesh_node(mesh, pos, surface)


func sphere(dimensions: Vector3, pos: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 10
	var node := mesh_node(mesh, pos, surface)
	node.scale = dimensions
	return node


func ring(radius: float, pos: Vector3, surface: Material) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.025
	mesh.outer_radius = radius + 0.025
	mesh.rings = 20
	mesh.ring_segments = 8
	mesh_node(mesh, pos, surface)


func lathe(profile: PackedVector2Array, surface: Material) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 16
	for row in profile.size() - 1:
		for side in segments:
			var a := TAU * side / segments
			var b := TAU * (side + 1) / segments
			var low := profile[row]
			var high := profile[row + 1]
			var points := [Vector3(cos(a) * low.x, low.y, sin(a) * low.x), Vector3(cos(b) * low.x, low.y, sin(b) * low.x), Vector3(cos(a) * high.x, high.y, sin(a) * high.x), Vector3(cos(b) * high.x, high.y, sin(b) * high.x)]
			for index in [0, 2, 1, 1, 2, 3]:
				builder.add_vertex(points[index])
	builder.generate_normals()
	mesh_node(builder.commit(), Vector3.ZERO, surface)
