extends SubViewportContainer
## A wooden price board suspended from the counter lip by two real cord meshes.
## Its price is written on the 3D face. It stays put when the goods are lifted.

var viewport_3d: SubViewport
var camera: Camera3D
var price_text: Label3D
var stand: Node3D
var _mount_anchor := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = false
	# Fixed supersampled surface: clean small lettering without four large worlds.
	viewport_3d = SubViewport.new()
	viewport_3d.size = Vector2i(480, 300)
	viewport_3d.transparent_bg = true
	viewport_3d.own_world_3d = true
	viewport_3d.msaa_3d = Viewport.MSAA_4X
	add_child(viewport_3d)
	stand = Node3D.new()
	viewport_3d.add_child(stand)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("bcab91")
	environment.environment.ambient_light_energy = 0.65
	stand.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -32, 0)
	light.light_color = Color("ffdaa6")
	light.light_energy = 1.0
	stand.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.65
	# The counter's front lip rises slightly to the right in the source artwork.
	camera.position = Vector3(-1.5, 2.3, 6)
	stand.add_child(camera)
	camera.look_at(Vector3(0, -0.55, 0))
	_build_stand()
	_request_render()


func _build_stand() -> void:
	var wood := ShaderMaterial.new()
	var grain := Shader.new()
	grain.code = "shader_type spatial; void fragment(){ float g=sin(UV.y*103.0+sin(UV.x*9.0)*0.8)*0.035+sin(UV.y*37.0)*0.045; ALBEDO=vec3(0.23,0.145,0.08)*(0.96+g); ROUGHNESS=0.91; }"
	wood.shader = grain
	var dark_wood := _material("302219", 0.0, 0.93)
	var edge := _material("65472f", 0.0, 0.86)
	var brass := _material("987440", 0.48, 0.7)
	var slate := _material("282624", 0.0, 0.98)
	var board := Node3D.new()
	board.name = "HangingBoard"
	board.position = Vector3(0, -0.83, 0.035)
	stand.add_child(board)
	_box(board, "SolidBoard", Vector3(1.9, 0.72, 0.09), Vector3.ZERO, dark_wood)
	_box(board, "SlateFace", Vector3(1.7, 0.53, 0.015), Vector3(0, 0, 0.054), slate)
	for y in [-0.315, 0.315]:
		_box(board, "WoodRail", Vector3(1.9, 0.09, 0.095), Vector3(0, y, 0.025), wood)
		_box(board, "WornRailEdge", Vector3(1.85, 0.012, 0.01), Vector3(0, y + 0.032, 0.078), edge)
	for x in [-0.905, 0.905]:
		_box(board, "WoodStile", Vector3(0.09, 0.54, 0.095), Vector3(x, 0, 0.025), wood)
		for y in [-0.285, 0.285]:
			var rivet := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = 0.019
			mesh.height = 0.038
			mesh.radial_segments = 8
			mesh.rings = 4
			rivet.mesh = mesh
			rivet.material_override = brass
			rivet.position = Vector3(x, y, 0.08)
			board.add_child(rivet)
	var twine := ShaderMaterial.new()
	var fibers := Shader.new()
	fibers.code = "shader_type spatial; void fragment(){float strand=sin(UV.x*18.8496+UV.y*30.0)*0.10; ALBEDO=vec3(0.45,0.32,0.17)*(1.0+strand); ROUGHNESS=0.98;}"
	twine.shader = fibers
	for side: int in [-1, 1]:
		var prefix := "Left" if side == -1 else "Right"
		var mount := Vector3(side * 0.68, 0, 0.015)
		var eye := Vector3(side * 0.68, -0.49, 0.11)
		_sphere(stand, prefix + "Mount", mount, 0.03, brass)
		_eyelet(prefix + "Eyelet", eye, brass)
		_cord(prefix + "Cord", mount + Vector3(0, -0.013, 0.015), eye, twine)
		# A small wrapped knot at each metal eye gives the rope a real termination.
		var knot := _sphere(stand, prefix + "Knot", eye + Vector3(0, 0.015, 0.026), 0.027, twine)
		knot.scale = Vector3(0.9, 1.35, 0.8)
	price_text = Label3D.new()
	price_text.name = "WrittenPrice"
	price_text.font = ThemeDB.fallback_font
	price_text.font_size = 96
	price_text.pixel_size = 0.0039
	price_text.position = Vector3(0, 0.005, 0.068)
	price_text.modulate = Color("dcc698")
	price_text.outline_modulate = Color("17140f")
	price_text.outline_size = 2
	price_text.double_sided = false
	board.add_child(price_text)
	var shadow := MeshInstance3D.new()
	shadow.name = "BoardShadow"
	# This is a shadow against the vertical wooden front, not a footprint on top.
	var plane := QuadMesh.new()
	plane.size = Vector2(2.13, 0.91)
	shadow.mesh = plane
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; void fragment(){vec2 p=abs(UV-vec2(0.5))*2.0; float r=length(max(p-vec2(0.7),vec2(0.0)))/0.3; ALBEDO=vec3(0.02,0.012,0.007); ALPHA=0.36*(1.0-smoothstep(0.0,1.0,r));}"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	shadow.material_override = mat
	shadow.position = Vector3(0.045, -0.87, -0.055)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stand.add_child(shadow)


func set_price(price: int, sold: bool) -> void:
	var digits := str(maxi(price, 0))
	var grouped := ""
	for index in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			grouped += " "
		grouped += digits[index]
	price_text.text = "SPRZEDANE" if sold else "%s zł" % grouped
	price_text.modulate = Color("9c8c76") if sold else Color("dcc698")
	# Keep even a six-digit price inside the physical frame.
	var width := (
		price_text
		. font
		. get_string_size(price_text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, price_text.font_size)
		. x
	)
	price_text.pixel_size = minf(0.0039, 1.5 / maxf(width, 1.0))
	_request_render()


func hang_from_counter(anchor: Vector2, display_size: Vector2) -> void:
	_mount_anchor = anchor
	size = Vector2(viewport_3d.size)
	scale = display_size / size
	# Align the two upper rope mounts to the front lip; the board hangs below.
	position = anchor - camera.unproject_position(Vector3.ZERO) * scale


func _sphere(
	parent: Node3D, node_name: String, at: Vector3, radius: float, mat: Material
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node


func _eyelet(node_name: String, at: Vector3, mat: Material) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.026
	mesh.outer_radius = 0.047
	mesh.rings = 20
	mesh.ring_segments = 8
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = mat
	node.rotation_degrees.x = 90
	node.position = at
	stand.add_child(node)


func _cord(node_name: String, start: Vector3, end: Vector3, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 16:
		for side in 10:
			var vertices: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for corner: Vector2i in [
				Vector2i(side, row),
				Vector2i(side + 1, row),
				Vector2i(side, row + 1),
				Vector2i(side + 1, row + 1)
			]:
				var t := corner.y / 16.0
				var angle := TAU * corner.x / 10.0
				var center := (
					start.lerp(end, t) + Vector3(0.006 * sin(t * PI), 0, 0.012 * sin(t * PI))
				)
				vertices.append(center + Vector3(cos(angle), 0, sin(angle)) * 0.019)
				uvs.append(Vector2(corner.x / 10.0, t))
			for index in [0, 2, 1, 1, 2, 3]:
				st.set_uv(uvs[index])
				st.add_vertex(vertices[index])
	st.generate_normals()
	st.index()
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = st.commit()
	node.material_override = mat
	stand.add_child(node)


func _request_render() -> void:
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
	# Font layout can update after this call; refresh once more on the next frame.
	call_deferred("_refresh_surface")


func _refresh_surface() -> void:
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE


func _material(hex: String, metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.metallic = metallic
	mat.roughness = roughness
	return mat


func _box(
	parent: Node3D, node_name: String, dimensions: Vector3, at: Vector3, mat: Material
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node
