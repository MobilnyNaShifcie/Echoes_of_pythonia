extends RefCounted
## Sculpted rotational bottle with separate liquid, glass, fittings and wirework.
## All surfaces are geometry/materials, not inventory artwork or billboards.

var host
var gold: StandardMaterial3D
var edge: StandardMaterial3D


func build(view) -> void:
	host = view
	gold = host.material("876137", 0.65, 0.3)
	edge = host.material("c5a270", 0.55, 0.26)
	var enamel = host.material("21182e", 0.2, 0.3)
	# A low circular metal foot belongs to the vessel; no rectangular display block.
	var foot := profile_mesh([Vector2(0, 0.055), Vector2(0.22, 0.055), Vector2(0.26, 0.08), Vector2(0.26, 0.105), Vector2(0.205, 0.15), Vector2(0.18, 0.18), Vector2(0, 0.18)], gold)
	foot.name = "EngravedFoot"
	hoop(0.247, 0.1, 0.012, edge)
	# Wide pear-shaped body and slender neck. Longitudinal fluting catches light.
	var profile := [Vector2(0, 0.13), Vector2(0.17, 0.13), Vector2(0.26, 0.19), Vector2(0.35, 0.3), Vector2(0.385, 0.43), Vector2(0.375, 0.57), Vector2(0.32, 0.7), Vector2(0.225, 0.81), Vector2(0.135, 0.9), Vector2(0.095, 0.99), Vector2(0.095, 1.17), Vector2(0.13, 1.19), Vector2(0.13, 1.24), Vector2(0.087, 1.25), Vector2(0.076, 1.2), Vector2(0.076, 1.02), Vector2(0, 0.99)]
	var glass := ShaderMaterial.new()
	glass.shader = preload("res://ui/screens/black_market/elixir_glass.gdshader")
	profile_mesh(profile, glass, 0.018).name = "FlutedGlass"
	var liquid := ShaderMaterial.new()
	liquid.shader = preload("res://ui/screens/black_market/elixir_liquid.gdshader")
	profile_mesh([Vector2(0, 0.17), Vector2(0.15, 0.17), Vector2(0.235, 0.22), Vector2(0.319, 0.32), Vector2(0.345, 0.44), Vector2(0.335, 0.55), Vector2(0.294, 0.66), Vector2(0.28, 0.676), Vector2(0, 0.666)], liquid, 0.01).name = "LiquidWithMeniscus"
	# Filigree follows the body instead of floating straight bars around it.
	for i in 6:
		var angle := TAU * i / 6.0
		var rib := PackedVector3Array()
		for j in 25:
			var t := j / 24.0
			var y := lerpf(0.17, 0.93, t)
			var radius := body_radius(y) + 0.016
			var theta := angle + 0.1 * sin(t * PI)
			rib.append(Vector3(cos(theta) * radius, y, sin(theta) * radius))
		tube(rib, 0.014, gold)
		for handedness in [-1.0, 1.0]:
			var curl := PackedVector3Array()
			for j in 35:
				var t := j / 34.0
				var spiral := t * TAU * 0.9
				var y := 0.4 + sin(spiral) * 0.145 * (1.0 - t * 0.72)
				var theta: float = angle + handedness * (0.18 + cos(spiral) * 0.25 * (1.0 - t * 0.7))
				var r := body_radius(y) + 0.032
				curl.append(Vector3(cos(theta) * r, y, sin(theta) * r))
			tube(curl, 0.008, edge)
	# Neck collar, engraved grooves, beadwork and faceted garnet stopper.
	profile_mesh([Vector2(0, 0.92), Vector2(0.14, 0.92), Vector2(0.15, 0.95), Vector2(0.125, 0.99), Vector2(0.113, 1.12), Vector2(0.14, 1.15), Vector2(0.14, 1.2), Vector2(0, 1.2)], gold)
	for y in [0.945, 0.99, 1.13, 1.18]:
		hoop(0.13 if y > 1.12 or y < 0.97 else 0.12, y, 0.009, edge)
	for i in 12:
		var a := TAU * i / 12.0
		host.sphere(Vector3.ONE * 0.026, Vector3(cos(a) * 0.139, 1.16, sin(a) * 0.139), edge)
	profile_mesh([Vector2(0, 1.19), Vector2(0.095, 1.19), Vector2(0.105, 1.25), Vector2(0.12, 1.27), Vector2(0, 1.27)], enamel)
	var ruby = host.material("852837", 0.18, 0.18)
	profile_mesh([Vector2(0, 1.24), Vector2(0.10, 1.24), Vector2(0.155, 1.33), Vector2(0.14, 1.42), Vector2(0.075, 1.49), Vector2(0, 1.5)], ruby, 0, 8, false).name = "GarnetStopper"
	hoop(0.112, 1.275, 0.012, edge)
	# Front setting and small inset gemstone provide a readable focal point.
	var setting = host.sphere(Vector3(0.15, 0.22, 0.052), Vector3(0, 0.48, 0.412), gold)
	setting.name = "FrontSetting"
	host.sphere(Vector3(0.092, 0.145, 0.049), Vector3(0, 0.48, 0.442), ruby)


func body_radius(y: float) -> float:
	var samples := [Vector2(0.17, 0.23), Vector2(0.3, 0.35), Vector2(0.43, 0.385), Vector2(0.57, 0.375), Vector2(0.7, 0.32), Vector2(0.81, 0.225), Vector2(0.9, 0.135), Vector2(0.99, 0.095)]
	for i in samples.size() - 1:
		if y <= samples[i + 1].x:
			return lerpf(samples[i].y, samples[i + 1].y, inverse_lerp(samples[i].x, samples[i + 1].x, y))
	return 0.095


func profile_mesh(profile: Array, surface: Material, flute := 0.0, segments := 64, smooth := true) -> MeshInstance3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	if not smooth:
		builder.set_smooth_group(-1)
	for row in profile.size() - 1:
		for side in segments:
			var points: Array[Vector3] = []
			for sample in [Vector2(side, row), Vector2(side + 1, row), Vector2(side, row + 1), Vector2(side + 1, row + 1)]:
				var a: float = TAU * sample.x / segments
				var p: Vector2 = profile[int(sample.y)]
				var r := p.x * (1.0 + flute * cos(a * 12.0))
				points.append(Vector3(cos(a) * r, p.y, sin(a) * r))
			# Godot front faces use clockwise winding (outward normals).
			for index in [0, 1, 2, 1, 3, 2]:
				builder.add_vertex(points[index])
	builder.generate_normals()
	return host.mesh_node(builder.commit(), Vector3.ZERO, surface)


func hoop(radius: float, y: float, thickness: float, surface: Material) -> void:
	var path := PackedVector3Array()
	for i in 65:
		var a := TAU * i / 64.0
		path.append(Vector3(cos(a) * radius, y, sin(a) * radius))
	tube(path, thickness, surface)


func tube(path: PackedVector3Array, radius: float, surface: Material) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in path.size():
		var tangent := (path[mini(i + 1, path.size() - 1)] - path[maxi(0, i - 1)]).normalized()
		var axis := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var u := tangent.cross(axis).normalized()
		var v := tangent.cross(u).normalized()
		var vertices := PackedVector3Array()
		for j in 8:
			var a := TAU * j / 8.0
			vertices.append(path[i] + radius * (cos(a) * u + sin(a) * v))
		rings.append(vertices)
	for i in rings.size() - 1:
		for j in 8:
			var k := (j + 1) % 8
			for p in [rings[i][j], rings[i + 1][j], rings[i][k], rings[i][k], rings[i + 1][j], rings[i + 1][k]]:
				builder.add_vertex(p)
	builder.generate_normals()
	host.mesh_node(builder.commit(), Vector3.ZERO, surface)
