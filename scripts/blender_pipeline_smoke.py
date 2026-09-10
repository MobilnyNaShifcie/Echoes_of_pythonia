"""Run inside Blender: a technical skin/animation probe, NOT character artwork.

Usage: blender --background --factory-startup --python-exit-code 1 --python <script>
Generated files are kept in an isolated Godot test project and ignored by Git.
"""

import json
from pathlib import Path

import bpy
from mathutils import Vector


PROJECT = Path(__file__).resolve().parents[1]
OUTPUT = PROJECT / "tools" / "character_3d_smoke" / "generated"
OUTPUT.mkdir(parents=True, exist_ok=True)
SOURCE_OUTPUT = PROJECT / "build" / "character_3d_pipeline"
SOURCE_OUTPUT.mkdir(parents=True, exist_ok=True)

# Only factory-startup contents of this disposable Blender process are removed.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = 31
scene.render.fps = 30

armature = bpy.data.armatures.new("ProbeSkeleton")
rig = bpy.data.objects.new("PipelineProbe", armature)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
root = armature.edit_bones.new("root")
root.head = (0, 0, 0)
root.tail = (0, 0, 1)
upper = armature.edit_bones.new("upper")
upper.head = (0, 0, 1)
upper.tail = (0, 0, 2)
upper.parent = root
upper.use_connect = True
bpy.ops.object.mode_set(mode="OBJECT")

vertices = []
faces = []
levels = [0.0, 0.4, 0.8, 1.0, 1.2, 1.6, 2.0]
for z in levels:
    for x, y in [(-0.20, -0.13), (0.20, -0.13), (0.20, 0.13), (-0.20, 0.13)]:
        vertices.append((x, y, z))
faces.append((3, 2, 1, 0))
for ring in range(len(levels) - 1):
    for corner in range(4):
        a = ring * 4 + corner
        b = ring * 4 + (corner + 1) % 4
        faces.append((a, b, b + 4, a + 4))
faces.append(tuple(range(len(vertices) - 4, len(vertices))))
mesh_data = bpy.data.meshes.new("SkinnedProbeMesh")
mesh_data.from_pydata(vertices, [], faces)
mesh_data.update()
mesh = bpy.data.objects.new("SkinnedProbe", mesh_data)
scene.collection.objects.link(mesh)
mesh.parent = rig
modifier = mesh.modifiers.new("Skin", "ARMATURE")
modifier.object = rig
groups = {name: mesh.vertex_groups.new(name=name) for name in ("root", "upper")}
for index, (_, _, z) in enumerate(vertices):
    upper_weight = min(1.0, max(0.0, (z - 0.8) / 0.4))
    if upper_weight < 1.0:
        groups["root"].add([index], 1.0 - upper_weight, "REPLACE")
    if upper_weight > 0.0:
        groups["upper"].add([index], upper_weight, "REPLACE")

material = bpy.data.materials.new("ProbeCrimson")
material.diffuse_color = (0.45, 0.025, 0.08, 1)
material.use_nodes = True
bsdf = material.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Base Color"].default_value = material.diffuse_color
bsdf.inputs["Roughness"].default_value = 0.6
mesh.data.materials.append(material)

bone = rig.pose.bones["upper"]
bone.rotation_mode = "XYZ"
for frame, angle in [(1, 0.0), (16, 0.65), (31, 0.0)]:
    bone.rotation_euler = (0.0, 0.0, angle)
    bone.keyframe_insert(data_path="rotation_euler", frame=frame, group="upper")
rig.animation_data.action.name = "ProbeBend"

def evaluated_tip(frame):
    scene.frame_set(frame)
    graph = bpy.context.evaluated_depsgraph_get()
    evaluated = mesh.evaluated_get(graph)
    # The last vertex has weight 1 on the upper bone.
    return evaluated.matrix_world @ evaluated.data.vertices[-1].co


start = evaluated_tip(1)
bent = evaluated_tip(16)
returned = evaluated_tip(31)
assert (start - bent).length > 0.4, "Rig must actually deform the mesh."
assert (start - returned).length < 1e-5, "Animation must return to its initial pose."
scene.frame_set(1)
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
mesh.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(
    filepath=str(OUTPUT / "pipeline_probe.glb"),
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_force_sampling=True,
    export_skins=True,
    export_yup=True,
)

# A small CPU render confirms this runtime can render as well as export.
camera_data = bpy.data.cameras.new("ProbeCamera")
camera = bpy.data.objects.new("ProbeCamera", camera_data)
scene.collection.objects.link(camera)
camera.location = (3, -5, 2.8)
camera.rotation_euler = (Vector((0, 0, 1)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 2.9
scene.camera = camera
light_data = bpy.data.lights.new("ProbeKey", "AREA")
light_data.energy = 500
light_data.shape = "DISK"
light_data.size = 4
light = bpy.data.objects.new("ProbeKey", light_data)
scene.collection.objects.link(light)
light.location = (2, -4, 5)
light.rotation_euler = (Vector((0, 0, 1)) - light.location).to_track_quat("-Z", "Y").to_euler()
scene.world.color = (0.2, 0.2, 0.2)
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 8
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = True
scene.render.filepath = str(OUTPUT / "blender_render.png")
scene.frame_set(16)
bpy.ops.render.render(write_still=True)
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_OUTPUT / "pipeline_probe.blend"))
report = {
    "blender_version": bpy.app.version_string,
    "purpose": "Technical pipeline probe, not a Pierrot character model",
    "bone_count": len(armature.bones),
    "vertex_count": len(vertices),
    "skin_deformation_distance": (start - bent).length,
    "return_error": (start - returned).length,
    "glb_bytes": (OUTPUT / "pipeline_probe.glb").stat().st_size,
    "cpu_render": "blender_render.png",
}
(OUTPUT / "blender_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("BLENDER_PIPELINE_SMOKE_OK", json.dumps(report))
