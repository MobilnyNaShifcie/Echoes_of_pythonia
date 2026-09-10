"""Isolated 3D head texture-projection experiment; never edits source/game assets.

Run with Blender 4.5 --background --factory-startup --python-exit-code 1.
The input drawing is unchanged. Projection is ordinary 3D UV mapping, not AI art.
"""
import bpy
import hashlib
import json
import math
import sys
from pathlib import Path
import numpy as np
from mathutils import Vector

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SOURCE = Path(r'C:\Users\kamil\Downloads\pierrot_8k.glb.glb')
REFERENCE = REPO / 'art_drafts/pierrot_3d_reference_02/tripo_multiview_v2/pierrot_front_v2.png'
OUT = HERE / 'v05'
OUT.mkdir(parents=True, exist_ok=True)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

hashes = {str(p): digest(p) for p in [SOURCE, REFERENCE]}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
source_obj = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
bpy.context.view_layer.objects.active = source_obj
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
source_mesh = source_obj.data
v = np.empty(len(source_mesh.vertices) * 3, dtype=np.float32)
source_mesh.vertices.foreach_get('co', v)
v = v.reshape(-1, 3)
height = float(v[:, 2].max())
indices = np.empty(len(source_mesh.loops), dtype=np.int32)
source_mesh.loops.foreach_get('vertex_index', indices)
tri = indices.reshape(-1, 3)
keep = np.all(v[tri, 2] > height * 0.805, axis=1)
used, remapped = np.unique(tri[keep], return_inverse=True)
head_v = v[used].copy()
head_mesh = bpy.data.meshes.new('Pierrot_Actual3DHead')
head_mesh.from_pydata(head_v.tolist(), [], remapped.reshape(-1, 3).tolist())
head_mesh.update()
head_mesh.polygons.foreach_set('use_smooth', [True] * len(head_mesh.polygons))
old_uv = np.empty(len(source_mesh.loops) * 2, dtype=np.float32)
source_mesh.uv_layers.active.data.foreach_get('uv', old_uv)
new_uv = old_uv.reshape(-1, 3, 2)[keep].reshape(-1, 2).copy()
original_uv = head_mesh.uv_layers.new(name='Original_Tripo_UV')
original_uv.data.foreach_set('uv', new_uv.ravel())
head_obj = bpy.data.objects.new('Pierrot_Head_Sample', head_mesh)
bpy.context.scene.collection.objects.link(head_obj)
original_mat = source_mesh.materials[0]
base_image = next(n.image for n in original_mat.node_tree.nodes
                  if n.type == 'TEX_IMAGE' and n.image and 'basecolor' in n.image.name)
ref_image = bpy.data.images.load(str(REFERENCE), check_existing=True)
ref_image.pack()

# Orthographic projection registration in the unchanged reference image.
# Mapping and mask parameters are explicit for repeatability and further tuning.
parameters = {'source_pixel_center_x': 306.0, 'pixels_per_model_unit_x': 1100.0,
              'source_pixel_ground_y': 942.0, 'pixels_per_model_unit_z': 949.0,
              'face_center_z_fraction': 0.887, 'face_radius_z_fraction': 0.051,
              'face_radius_x_fraction': 0.054}
if (HERE / 'registration.json').exists():
    parameters.update(json.loads((HERE / 'registration.json').read_text(encoding='utf-8')))
loop_co = head_v[remapped]
projection = np.empty((len(remapped), 2), dtype=np.float32)
projection[:, 0] = (parameters['source_pixel_center_x'] + loop_co[:, 0] * parameters['pixels_per_model_unit_x']) / ref_image.size[0]
projection[:, 1] = 1 - (parameters['source_pixel_ground_y'] - loop_co[:, 2] * parameters['pixels_per_model_unit_z']) / ref_image.size[1]
projection_uv = head_mesh.uv_layers.new(name='Reference_Front_Projection')
projection_uv.data.foreach_set('uv', projection.ravel())

# Source color is used only to gate the face away from red hair / black collar.
pixels = np.empty(base_image.size[0] * base_image.size[1] * 4, dtype=np.float32)
base_image.pixels.foreach_get(pixels)
pixels = pixels.reshape(base_image.size[1], base_image.size[0], 4)
px = np.clip((new_uv[:, 0] * base_image.size[0]).astype(int), 0, base_image.size[0] - 1)
py = np.clip((new_uv[:, 1] * base_image.size[1]).astype(int), 0, base_image.size[1] - 1)
rgb = pixels[py, px, :3]
del pixels

def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)

ellipse = (loop_co[:, 0] / (height * parameters['face_radius_x_fraction'])) ** 2
ellipse += ((loop_co[:, 2] / height - parameters['face_center_z_fraction']) / parameters['face_radius_z_fraction']) ** 2
front = 1 - smooth(-0.020 * height, 0.005 * height, loop_co[:, 1])
skin = smooth(0.14, 0.36, rgb[:, 1])
# Identify red hair shells by connected mesh components. This prevents painting
# an eye onto a strand which physically occludes the eye in the source model.
parent = list(range(len(head_v)))
def root(i):
    while parent[i] != i:
        parent[i] = parent[parent[i]]
        i = parent[i]
    return i
for a, b, c in remapped.reshape(-1, 3):
    ra, rb, rc = root(int(a)), root(int(b)), root(int(c))
    parent[rb] = ra
    parent[rc] = ra
roots = np.array([root(i) for i in range(len(head_v))])
vertex_rgb = np.zeros((len(head_v), 3), dtype=np.float32)
vertex_rgb[remapped] = rgb
hair_vertices = np.zeros(len(head_v), dtype=bool)
component_report = []
for component in np.unique(roots):
    ids = np.flatnonzero(roots == component)
    cols = vertex_rgb[ids]
    red_fraction = np.mean((cols[:, 0] > cols[:, 1] * 1.7) & (cols[:, 0] > cols[:, 2] * 1.3))
    is_hair = red_fraction > 0.60 and np.median(head_v[ids, 2]) > height * 0.86
    if is_hair:
        hair_vertices[ids] = True
    if len(ids) > 150:
        component_report.append({'vertices': len(ids), 'red_fraction': float(red_fraction), 'hair': bool(is_hair)})
skin = np.where(hair_vertices[remapped], 0, 1).astype(np.float32)
source_x = projection[:, 0] * ref_image.size[0]
source_y = (1 - projection[:, 1]) * ref_image.size[1]
reference_face_ellipse = ((source_x - 306) / 37) ** 2 + ((source_y - 111) / 32) ** 2
reference_face_gate = (1 - smooth(0.65, 1.04, reference_face_ellipse))
reference_face_gate *= smooth(78, 89, source_y) * (1 - smooth(132, 141, source_y))
rp = np.empty(ref_image.size[0] * ref_image.size[1] * 4, dtype=np.float32)
ref_image.pixels.foreach_get(rp)
rp = rp.reshape(ref_image.size[1], ref_image.size[0], 4)
rpx = np.clip(source_x.astype(int), 0, ref_image.size[0] - 1)
rpy = np.clip((projection[:, 1] * ref_image.size[1]).astype(int), 0, ref_image.size[1] - 1)
projected_rgb = rp[rpy, rpx, :3]
ref_skin = smooth(0.20, 0.55, projected_rgb[:, 1])
ref_eyes = np.maximum(1 - smooth(0.65, 1, ((source_x - 287) / 12) ** 2 + ((source_y - 96) / 7) ** 2),
                      1 - smooth(0.65, 1, ((source_x - 328) / 12) ** 2 + ((source_y - 96) / 7) ** 2))
reference_face_gate *= np.maximum(ref_skin, ref_eyes)
mask = (1 - smooth(0.62, 1.02, ellipse)) * front * skin * reference_face_gate
colors = np.zeros((len(remapped), 4), dtype=np.float32)
colors[:, :3] = mask[:, None]
colors[:, 3] = 1
attr = head_mesh.color_attributes.new(name='Face_Projection_Mask', type='FLOAT_COLOR', domain='CORNER')
attr.data.foreach_set('color', colors.ravel())

def make_material(name, projected, shaded=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    uv = nt.nodes.new('ShaderNodeUVMap'); uv.uv_map = 'Original_Tripo_UV'
    tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = base_image
    nt.links.new(uv.outputs['UV'], tex.inputs['Vector'])
    color = tex.outputs['Color']
    if projected:
        puv = nt.nodes.new('ShaderNodeUVMap'); puv.uv_map = 'Reference_Front_Projection'
        ptex = nt.nodes.new('ShaderNodeTexImage'); ptex.image = ref_image
        ptex.extension = 'EXTEND'; ptex.interpolation = 'Linear'
        nt.links.new(puv.outputs['UV'], ptex.inputs['Vector'])
        gate = nt.nodes.new('ShaderNodeVertexColor'); gate.layer_name = 'Face_Projection_Mask'
        mix = nt.nodes.new('ShaderNodeMixRGB'); mix.blend_type = 'MIX'
        nt.links.new(gate.outputs['Color'], mix.inputs[0])
        nt.links.new(color, mix.inputs[1]); nt.links.new(ptex.outputs['Color'], mix.inputs[2])
        color = mix.outputs[0]
    if shaded:
        surface = nt.nodes.new('ShaderNodeBsdfPrincipled')
        nt.links.new(color, surface.inputs['Base Color'])
        surface.inputs['Roughness'].default_value = 0.72
        surface.inputs['Metallic'].default_value = 0
        surface.inputs['Specular IOR Level'].default_value = 0.22
    else:
        surface = nt.nodes.new('ShaderNodeEmission')
        nt.links.new(color, surface.inputs['Color'])
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(surface.outputs[0], out.inputs['Surface'])
    return mat

before = make_material('Before_original_8K_basecolor', False)
after = make_material('After_front_reference_projection', True)
shaded = make_material('After_matte_lit_material', True, True)
head_obj.data.materials.append(after)
bpy.data.objects.remove(source_obj, do_unlink=True)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 4
scene.cycles.use_denoising = False
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
scene.render.resolution_percentage = 100
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.image_settings.file_format = 'PNG'
world = bpy.data.worlds.new('Neutral_Review_World'); world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.12, 0.12, 0.12, 1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.7
scene.world = world
cam_data = bpy.data.cameras.new('Comparison_Camera')
cam_data.type = 'ORTHO'; cam_data.ortho_scale = height * 0.245
camera = bpy.data.objects.new('Comparison_Camera', cam_data)
scene.collection.objects.link(camera); scene.camera = camera
target = Vector((0, 0, height * 0.907))
for name, xyz, energy in [('Key', (-0.5, -1, 1.6), 35), ('Fill', (0.6, -0.4, 1), 15)]:
    data = bpy.data.lights.new(name, 'AREA'); data.energy = energy; data.size = 0.8
    obj = bpy.data.objects.new(name, data); scene.collection.objects.link(obj)
    obj.location = xyz; obj.rotation_euler = (target - obj.location).to_track_quat('-Z', 'Y').to_euler()

def render(name, mat, angle):
    head_obj.data.materials[0] = mat
    angle = math.radians(angle)
    camera.location = target + Vector((math.sin(angle), -math.cos(angle), 0)) * 2
    camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = str(OUT / (name + '.png'))
    bpy.ops.render.render(write_still=True)
    print('RENDER_COMPLETE ' + name, flush=True)

render('after_front', after, 0)
render('after_angle', after, 35)
render('after_profile', after, 75)
head_obj.data.materials[0] = after
head_mesh.uv_layers.active_index = 0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'pierrot_head_projection_working.blend'))
report = {'status': 'WIP texture-only head projection; must pass visual review before acceptance',
          'source_hashes': hashes, 'source_unchanged': all(digest(Path(p)) == h for p, h in hashes.items()),
          'head_vertices': len(head_mesh.vertices), 'head_triangles': len(head_mesh.polygons),
          'geometry_modified': False, 'rig_added': False, 'game_integration': False,
          'reference_native_resolution': list(ref_image.size), 'registration': parameters,
          'limitations': ['Original low-resolution approved reference, not newly invented facial details',
                          'Current stage front-face projection with feathered mask, not yet baked/exported',
                          'Original hair geometry and texture retained; facial geometry not sculpted'],
          'uv_mask_pixels_nonzero': int(np.count_nonzero(mask > 0.01)),
          'connected_components': component_report,
          'hair_vertices_excluded_from_projection': int(np.count_nonzero(hair_vertices))}
(OUT / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print('SAMPLE_DONE ' + json.dumps(report), flush=True)
