"""Bake the reviewed projection to an ordinary portable UV texture and GLB."""
import bpy
import hashlib
import json
import math
from pathlib import Path
import numpy as np
from mathutils import Vector

HERE = Path(__file__).resolve().parent
WORK = HERE / 'v05'
OUT = HERE / 'sample_v05'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(WORK / 'pierrot_head_projection_working.blend'))
obj = bpy.data.objects['Pierrot_Head_Sample']
mesh = obj.data
scene = bpy.context.scene
before_mat = bpy.data.materials.new('Before_original_8K_basecolor')
before_mat.use_nodes = True
bn = before_mat.node_tree; bn.nodes.clear()
bt = bn.nodes.new('ShaderNodeTexImage')
bt.image = next(im for im in bpy.data.images if 'basecolor' in im.name)
bu = bn.nodes.new('ShaderNodeUVMap'); bu.uv_map = 'Original_Tripo_UV'
bn.links.new(bu.outputs['UV'], bt.inputs['Vector'])
be = bn.nodes.new('ShaderNodeEmission'); bn.links.new(bt.outputs['Color'], be.inputs['Color'])
bo = bn.nodes.new('ShaderNodeOutputMaterial'); bn.links.new(be.outputs[0], bo.inputs[0])
before_mesh = mesh.copy()
before_mesh.name = 'Comparison_only_original_head'
source_positions = np.empty(len(mesh.vertices) * 3, dtype=np.float32)
mesh.vertices.foreach_get('co', source_positions)
geometry_hash = hashlib.sha256(source_positions.tobytes()).hexdigest()

source_uv_data = np.empty(len(mesh.loops) * 2, dtype=np.float32)
mesh.uv_layers['Original_Tripo_UV'].data.foreach_get('uv', source_uv_data)
atlas = mesh.uv_layers.new(name='Head_Atlas_UV')
atlas.data.foreach_set('uv', source_uv_data)
mesh.uv_layers.active_index = len(mesh.uv_layers) - 1
mesh.uv_layers.active.active_render = True
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.select_all(action='SELECT')
bpy.ops.uv.pack_islands(rotate=False, margin=0.006, shape_method='AABB')
bpy.ops.object.mode_set(mode='OBJECT')
check_uv = np.empty_like(source_uv_data)
mesh.uv_layers['Original_Tripo_UV'].data.foreach_get('uv', check_uv)
assert np.array_equal(source_uv_data, check_uv), 'Packing must not alter original sampling UVs'

image = bpy.data.images.new('Pierrot_head_basecolor_2048', width=2048, height=2048, alpha=False)
image.colorspace_settings.name = 'sRGB'
mat = obj.data.materials[0]
target = mat.node_tree.nodes.new('ShaderNodeTexImage')
target.image = image
mat.node_tree.nodes.active = target
scene.cycles.samples = 1
scene.cycles.use_denoising = False
scene.render.bake.use_selected_to_active = False
scene.render.bake.margin = 12
bpy.ops.object.bake(type='EMIT')
image.filepath_raw = str(OUT / 'pierrot_head_basecolor_2048.png')
image.file_format = 'PNG'
image.save()
image.pack()

def baked_material(name, unlit):
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    nt = result.node_tree; nt.nodes.clear()
    tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = image
    uv = nt.nodes.new('ShaderNodeUVMap'); uv.uv_map = 'Head_Atlas_UV'
    nt.links.new(uv.outputs['UV'], tex.inputs['Vector'])
    if unlit:
        surface = nt.nodes.new('ShaderNodeEmission')
        nt.links.new(tex.outputs['Color'], surface.inputs['Color'])
    else:
        surface = nt.nodes.new('ShaderNodeBsdfPrincipled')
        nt.links.new(tex.outputs['Color'], surface.inputs['Base Color'])
        surface.inputs['Metallic'].default_value = 0
        surface.inputs['Roughness'].default_value = 0.75
        surface.inputs['Specular IOR Level'].default_value = 0.2
    output = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(surface.outputs[0], output.inputs['Surface'])
    return result

flat = baked_material('Head_comparison_basecolor_only', True)
lit = baked_material('Pierrot_head_matte_surface', False)
mesh.materials.clear(); mesh.materials.append(lit)
for name in [layer.name for layer in mesh.uv_layers]:
    if name != 'Head_Atlas_UV':
        mesh.uv_layers.remove(mesh.uv_layers[name])
for name in [layer.name for layer in mesh.color_attributes]:
    mesh.color_attributes.remove(mesh.color_attributes[name])
check_positions = np.empty_like(source_positions)
mesh.vertices.foreach_get('co', check_positions)
assert np.array_equal(source_positions, check_positions), 'Texture bake must not alter geometry'

bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'pierrot_head_sample.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT / 'pierrot_head_sample.glb'), export_format='GLB',
                          use_selection=True, export_animations=False, export_skins=False)

# Actual side-by-side 3D renders, not an edited screenshot or regenerated portrait.
baseline = bpy.data.objects.new('Before_original_8K', before_mesh)
scene.collection.objects.link(baseline)
baseline.data.materials.clear(); baseline.data.materials.append(before_mat)
baseline.location.x = -0.125
obj.location.x = 0.125
mesh.materials[0] = flat
scene.render.resolution_x = 1440
scene.render.resolution_y = 850
scene.cycles.samples = 8
scene.camera.data.ortho_scale = 0.51
scene.camera.location = (0, -2, 0.897)
scene.camera.rotation_euler = (Vector((0, 0, 0.897)) - scene.camera.location).to_track_quat('-Z', 'Y').to_euler()

label_mat = bpy.data.materials.new('Review_labels')
label_mat.use_nodes = True
nt = label_mat.node_tree; nt.nodes.clear()
em = nt.nodes.new('ShaderNodeEmission'); em.inputs['Color'].default_value = (0.85, 0.86, 0.89, 1)
out = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(em.outputs[0], out.inputs[0])
for text, x in [('TRIPO 8K', -0.125), ('PROJEKCJA - PROBA', 0.125)]:
    data = bpy.data.curves.new(text, 'FONT'); data.body = text
    data.align_x = 'CENTER'; data.size = 0.010
    label = bpy.data.objects.new(text, data); scene.collection.objects.link(label)
    label.location = (x, -0.20, 1.025); label.rotation_euler = (math.pi / 2, 0, 0)
    data.materials.append(label_mat)

for label, angle in [('comparison_front', 0), ('comparison_angle', 35)]:
    for head in [obj, baseline]:
        head.rotation_euler.z = math.radians(-angle)
    scene.render.filepath = str(OUT / (label + '.png'))
    bpy.ops.render.render(write_still=True)
    print('COMPARISON ' + label, flush=True)

report = json.loads((WORK / 'report.json').read_text(encoding='utf-8'))
report.update({'status': 'Portable experimental head texture sample; awaits visual/user review',
               'baked_texture_resolution': [2048, 2048],
               'geometry_sha256_before_and_after_bake': geometry_hash,
               'bake_geometry_unchanged': True,
               'files': ['pierrot_head_sample.glb', 'pierrot_head_sample.blend',
                         'pierrot_head_basecolor_2048.png', 'comparison_front.png', 'comparison_angle.png'],
               'limitations': ['Frontal reference only, feathered into original side texture',
                               'Source face is a small region of a 548x956 reference; no detail invented',
                               'Hair geometry, face shape and rig are not corrected in this sample',
                               'Neutral basecolor comparisons exclude lighting; exported material responds to light']})
(OUT / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print('PORTABLE_SAMPLE_DONE', flush=True)
