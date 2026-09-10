"""Reimport the delivered GLB and render its embedded texture independently."""
import bpy
import hashlib
import json
from pathlib import Path
from mathutils import Vector

HERE = Path(__file__).resolve().parent
OUT = HERE / 'sample_v05'
FILE = OUT / 'pierrot_head_sample.glb'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(FILE))
objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
assert len(objects) == 1
obj = objects[0]
triangles = sum(len(p.vertices) - 2 for p in obj.data.polygons)
assert triangles == 244665, triangles
assert len(obj.data.uv_layers) == 1
texture = next(im for im in bpy.data.images if list(im.size) == [2048, 2048])
assert texture.packed_file is not None
mat = obj.data.materials[0]
nt = mat.node_tree
pbr = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
assert pbr.inputs['Base Color'].is_linked
tex = pbr.inputs['Base Color'].links[0].from_node
assert tex.type == 'TEX_IMAGE'
assert pbr.inputs['Metallic'].default_value == 0
assert pbr.inputs['Roughness'].default_value > 0.7
has_rig = any(o.type == 'ARMATURE' for o in bpy.context.scene.objects)
assert not has_rig

# Review output isolates embedded basecolor from lighting; exported GLB stays PBR.
em = nt.nodes.new('ShaderNodeEmission')
nt.links.new(tex.outputs['Color'], em.inputs['Color'])
output = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
nt.links.new(em.outputs[0], output.inputs['Surface'])
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'; scene.cycles.samples = 4; scene.cycles.use_denoising = False
scene.view_settings.view_transform = 'Standard'; scene.view_settings.look = 'None'
scene.render.resolution_x = 800; scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
world = bpy.data.worlds.new('Export_check_world'); world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.12, 0.12, 0.12, 1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.7
scene.world = world
camera_data = bpy.data.cameras.new('Export_check_camera')
camera_data.type = 'ORTHO'; camera_data.ortho_scale = 0.24
camera = bpy.data.objects.new('Export_check_camera', camera_data)
scene.collection.objects.link(camera); scene.camera = camera
camera.location = (0, -2, 0.888)
camera.rotation_euler = (Vector((0, 0, 0.888)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
scene.render.filepath = str(OUT / 'verified_glb_front.png')
bpy.ops.render.render(write_still=True)
validation = {'glb_reimport_passed': True, 'triangles': triangles,
              'uv_layers': 1, 'embedded_texture': [2048, 2048],
              'matte_pbr_material': True, 'rigged': has_rig,
              'file_sha256': hashlib.sha256(FILE.read_bytes()).hexdigest(),
              'game_integration': False}
(OUT / 'validation.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
print('EXPORT_VALIDATED ' + json.dumps(validation), flush=True)
