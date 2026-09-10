extends RefCounted
## Fixed illustration UVs on closed artifact volumes;
## no camera-facing item planes, generated replacement icons or save access.

const PITCH := 0.3399
const YAW := 0.05449
const REFERENCE_HEIGHT := 1506.0 * 0.00104

var host
var reference_art: Texture2D
var art_size: Vector2
var axis_x: float
var floor_pixel: float
var pixel_scale: float
var source_image: Image
var uv_cache := {}


func initialize(view, art: Texture2D, dimensions: Vector2, axis: float, floor_y: float, silhouette_height: float) -> void:
	host = view
	reference_art = art
	art_size = dimensions
	axis_x = axis
	floor_pixel = floor_y
	pixel_scale = REFERENCE_HEIGHT / silhouette_height
	source_image = art.get_image()
	if source_image.is_compressed():
		source_image.decompress()


func reference_material(metallic: float, roughness: float, emission := 0.58) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = reference_art
	mat.albedo_color = Color(0.42,0.42,0.42)
	mat.metallic = metallic
	mat.metallic_specular = 0.12
	mat.roughness = roughness
	mat.emission_enabled = true
	mat.emission_texture = reference_art
	mat.emission = Color.WHITE
	mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	mat.emission_energy_multiplier = emission
	return mat


func point(pixel: Vector2, depth: float) -> Vector3:
	var z := depth*pixel_scale
	var y := (floor_pixel-pixel.y)*pixel_scale/cos(PITCH)+z*tan(PITCH)+0.035
	return Vector3((pixel.x-axis_x)*pixel_scale,y,z).rotated(Vector3.UP,YAW)


func uv(pixel: Vector2, toward: Vector2) -> Vector2:
	var key := Vector4(pixel.x,pixel.y,toward.x,toward.y)
	if uv_cache.has(key):
		return uv_cache[key]
	var safe := pixel
	# Sample inside the opaque cutout to avoid its undefined border RGB colors.
	for step in 24:
		safe = pixel.lerp(toward,step*0.02)
		var opaque := true
		for offset: Vector2i in [Vector2i.ZERO,Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]:
			var sample := Vector2i(safe)+offset
			if sample.x < 0 or sample.y < 0 or sample.x >= int(art_size.x) or sample.y >= int(art_size.y) or source_image.get_pixel(sample.x,sample.y).a < 0.98:
				opaque = false
				break
		if opaque:
			break
	var result := safe/art_size
	uv_cache[key] = result
	return result


func emit_triangle(st: SurfaceTool, vertices: Array, uvs: Array, outward: Vector3) -> void:
	# Godot front faces are clockwise. The generated normals must point OUT.
	var cross: Vector3 = (vertices[1]-vertices[0]).cross(vertices[2]-vertices[0])
	var order := [0,2,1] if cross.dot(outward) > 0 else [0,1,2]
	for index in order:
		st.set_uv(uvs[index])
		st.add_vertex(vertices[index])


func solid(outline: Array, label: String, mat: Material, front: Callable, rear: Callable, subdivisions := 2, back_offset := Vector2.ZERO) -> void:
	var polygon := PackedVector2Array(outline)
	var area := 0.0
	var center := Vector2.ZERO
	for i in polygon.size():
		area += polygon[i].cross(polygon[(i+1)%polygon.size()])
		center += polygon[i]/polygon.size()
	if area < 0:
		polygon.reverse()
	var indices := Geometry2D.triangulate_polygon(polygon)
	assert(not indices.is_empty(),label+" must triangulate")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,indices.size(),3):
		var pixels := [polygon[indices[i]],polygon[indices[i+1]],polygon[indices[i+2]]]
		_face(st,pixels,center,front,true,Vector2.ZERO,subdivisions)
		_face(st,pixels,center,rear,false,back_offset,subdivisions)
	var steps := int(pow(2,subdivisions))
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i+1)%polygon.size()]
		var direction := (b-a).normalized()
		var outward := point(center+Vector2(direction.y,-direction.x),0)-point(center,0)
		for step in steps:
			var p := a.lerp(b,float(step)/steps)
			var q := a.lerp(b,float(step+1)/steps)
			var vertices := [point(p,front.call(p)),point(q,front.call(q)),point(p+back_offset,rear.call(p)),point(q+back_offset,rear.call(q))]
			var uvs := [uv(p,center),uv(q,center),uv(p+back_offset,center+back_offset),uv(q+back_offset,center+back_offset)]
			for tri in [[0,1,2],[1,3,2]]:
				emit_triangle(st,[vertices[tri[0]],vertices[tri[1]],vertices[tri[2]]],[uvs[tri[0]],uvs[tri[1]],uvs[tri[2]]],outward)
	finish(st,label,mat)


func _face(st: SurfaceTool, pixels: Array, center: Vector2, depth: Callable, front: bool, offset: Vector2, subdivisions: int) -> void:
	if subdivisions > 0:
		var ab: Vector2 = (pixels[0]+pixels[1])*0.5
		var bc: Vector2 = (pixels[1]+pixels[2])*0.5
		var ca: Vector2 = (pixels[2]+pixels[0])*0.5
		for tri in [[pixels[0],ab,ca],[ab,pixels[1],bc],[ca,bc,pixels[2]],[ab,bc,ca]]:
			_face(st,tri,center,depth,front,offset,subdivisions-1)
		return
	var vertices: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	for pixel: Vector2 in pixels:
		vertices.append(point(pixel+offset,depth.call(pixel)))
		# The unseen rear reuses the front's illustration, like the other models.
		uvs.append(uv(pixel,center))
	emit_triangle(st,vertices,uvs,(Vector3.BACK if front else Vector3.FORWARD).rotated(Vector3.UP,YAW))


func relief(outline: Array, label: String, mat: Material, depth: Callable, lift: float, thickness: float, subdivisions := 2) -> void:
	solid(outline,label,mat,func(p: Vector2) -> float: return float(depth.call(p))+lift,func(p: Vector2) -> float: return float(depth.call(p))+lift-thickness,subdivisions)


func oval_tube(center: Vector2, extent: Vector2, radius: float, depth: float, label: String, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in 72:
		for side in 12:
			var vertices: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			var outward := Vector3.ZERO
			for corner: Vector2i in [Vector2i(ring,side),Vector2i(ring+1,side),Vector2i(ring,side+1),Vector2i(ring+1,side+1)]:
				var angle := TAU*corner.x/72.0
				var section := TAU*corner.y/12.0
				var radial := Vector2(cos(angle),sin(angle))
				var path := center+radial*extent
				var pixel := path+radial*cos(section)*radius
				var vertex := point(pixel,depth+sin(section)*radius)
				vertices.append(vertex)
				uvs.append(uv(pixel,path))
				outward += vertex-point(path,depth)
			for tri in [[0,1,2],[1,3,2]]:
				emit_triangle(st,[vertices[tri[0]],vertices[tri[1]],vertices[tri[2]]],[uvs[tri[0]],uvs[tri[1]],uvs[tri[2]]],outward)
	finish(st,label,mat)


func faceted_gem(center: Vector2, extent: Vector2, depth: float, rise: float, label: String, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shape := [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]
	for i in 4:
		var a: Vector2 = center+shape[i]*extent
		var b: Vector2 = center+shape[(i+1)%4]*extent
		var inner_a := center.lerp(a,0.60)
		var inner_b := center.lerp(b,0.60)
		for tri in [[a,inner_a,b],[b,inner_a,inner_b],[inner_a,center,inner_b]]:
			var vertices: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for pixel: Vector2 in tri:
				var z := depth+(rise if pixel==center else (rise*0.75 if pixel==inner_a or pixel==inner_b else 0.0))
				vertices.append(point(pixel,z))
				uvs.append(uv(pixel,center))
			emit_triangle(st,vertices,uvs,Vector3.BACK.rotated(Vector3.UP,YAW))
		# The base is a closed pyramid, embedded in its mounting.
		emit_triangle(st,[point(a,depth),point(center,depth-rise*0.3),point(b,depth)],[uv(a,center),uv(center,center),uv(b,center)],Vector3.FORWARD.rotated(Vector3.UP,YAW))
	finish(st,label,mat)


func lay_on_counter(turn_degrees: float) -> void:
	# Put the illustrated broad face UP, baking the pose into real 3D geometry.
	# No support, stretched sprite or camera-facing billboard is introduced.
	# point() compensates image Y for camera pitch, but its constant-depth
	# broad face still has a +Z normal. Tilting this by camera pitch again
	# would make the resting face slope away from the viewer and edge-on.
	var face_normal := Vector3.BACK.rotated(Vector3.UP, YAW)
	var basis := Basis(Vector3.UP, deg_to_rad(turn_degrees)) * Basis(Quaternion(face_normal, Vector3.UP))
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for part: MeshInstance3D in host.model.get_children():
		var arrays := part.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var welded_positions := {}
		for i in vertices.size():
			# UV/normal seams duplicate vertices. Weld sub-pixel subdivision
			# round-off before rotating so the closed surface stays watertight.
			var key := Vector3i((vertices[i] * 100000.0).round())
			if not welded_positions.has(key):
				welded_positions[key] = basis * vertices[i]
			vertices[i] = welded_positions[key]
			normals[i] = basis * normals[i]
			minimum = minimum.min(vertices[i])
			maximum = maximum.max(vertices[i])
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		part.mesh = mesh
	var footprint := Vector2(maximum.x - minimum.x, maximum.z - minimum.z)
	settle_on_mat(footprint + Vector2(0.12, 0.12), true)


func settle_on_mat(shadow_size: Vector2, centered := false) -> void:
	var bottom := INF
	for node: MeshInstance3D in host.model.get_children():
		bottom = minf(bottom,node.get_aabb().position.y)
	var foot := Vector3.ZERO
	var count := 0
	for node: MeshInstance3D in host.model.get_children():
		var vertices: PackedVector3Array = node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			if vertex.y <= bottom+0.035:
				foot += vertex
				count += 1
	foot /= maxf(count,1)
	if centered:
		var bounds := AABB()
		var first := true
		for node: MeshInstance3D in host.model.get_children():
			bounds = node.get_aabb() if first else bounds.merge(node.get_aabb())
			first = false
		foot = bounds.get_center()
	var offset := Vector3(-foot.x,0.018-bottom,-foot.z)
	for node: MeshInstance3D in host.model.get_children():
		node.position += offset
	var mesh := PlaneMesh.new()
	mesh.size = shadow_size
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded,cull_disabled,depth_draw_never; void fragment(){float r=length((UV-vec2(0.5))*2.0); ALBEDO=vec3(0.025,0.012,0.006); ALPHA=0.38*(1.0-smoothstep(0.15,1.0,r));}"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var contact = host.mesh_node(mesh,Vector3(0,0.004,0),mat)
	contact.name = "ContactShadow"
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func finish(st: SurfaceTool, label: String, mat: Material) -> void:
	st.generate_normals()
	st.index()
	var node = host.mesh_node(st.commit(),Vector3.ZERO,mat)
	node.name = label
