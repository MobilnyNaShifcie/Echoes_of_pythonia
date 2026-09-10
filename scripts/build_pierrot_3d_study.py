"""Author a genuine, editable Pierrot 3D design study in Blender 4.5.

This is NOT the production character or an automatic conversion of a portrait.
All surfaces, face features, hair locks and clothing are authored geometry.
No reference image is projected onto the model. The game is never modified.
"""

import argparse
import json
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art_drafts/pierrot_3d_study_01"
OUT = ROOT / "output/pierrot_3d_study_01"
SOURCE.mkdir(parents=True, exist_ok=True)
OUT.mkdir(parents=True, exist_ok=True)
args = argparse.ArgumentParser()
args.add_argument("--quick", action="store_true")
args.add_argument("--no-render", action="store_true")
args.add_argument("--face-only", action="store_true")
args = args.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
random.seed(58)
PI = math.pi

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1.0
scene.render.fps = 30
scene.render.film_transparent = False
scene.render.image_settings.file_format = "PNG"
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 12 if args.quick else 32
scene.cycles.use_denoising = True
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "Medium High Contrast"
scene.view_settings.exposure = 0
scene.view_settings.gamma = 1
scene.world.use_nodes = True
scene.world.node_tree.nodes.get("Background").inputs[0].default_value = (0.16, 0.18, 0.24, 1)
scene.world.node_tree.nodes.get("Background").inputs[1].default_value = 0.55
model_collection = bpy.data.collections.new("PIERROT — DESIGN STUDY 01")
scene.collection.children.link(model_collection)
stage_collection = bpy.data.collections.new("REVIEW STUDIO — not exported")
scene.collection.children.link(stage_collection)
active_collection = model_collection
model_root = bpy.data.objects.new("Pierrot_Study_NOT_PRODUCTION", None)
model_collection.objects.link(model_root)
model_root["status"] = "Unrigged authored geometry study. Requires visual approval and deformation topology work."


def mat(name, color, metallic=0, roughness=0.65, emission=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    node = m.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = (*color, 1)
    node.inputs["Metallic"].default_value = metallic
    node.inputs["Roughness"].default_value = roughness
    node.inputs["Specular IOR Level"].default_value = 0.25
    if emission:
        node.inputs["Emission Color"].default_value = (*color, 1)
        node.inputs["Emission Strength"].default_value = emission
    return m


M = {
    "skin": mat("01 Skin — warm porcelain", (0.78, 0.47, 0.36), roughness=0.86),
    "ear": mat("02 Skin shadow", (0.59, 0.29, 0.27)),
    "lip": mat("03 Rose lips", (0.45, 0.11, 0.14)),
    "lip_light": mat("04 Lip highlight", (0.84, 0.44, 0.42)),
    "ink": mat("05 Ink", (0.008, 0.005, 0.018), roughness=0.9),
    "ivory": mat("06 Ivory fabric", (0.90, 0.87, 0.84), roughness=0.82),
    "black": mat("07 Midnight fabric", (0.022, 0.016, 0.031), roughness=0.72),
    "red": mat("08 Crimson fabric", (0.48, 0.012, 0.055), roughness=0.65),
    "red_light": mat("09 Scarlet fabric", (0.70, 0.026, 0.075), roughness=0.63),
    "hair": mat("10 Garnet hair", (0.22, 0.003, 0.018), roughness=0.72),
    "hair_mid": mat("11 Crimson hair", (0.39, 0.009, 0.031), roughness=0.72),
    "hair_light": mat("12 Hair grouped highlights", (0.57, 0.021, 0.052), roughness=0.72),
    "gold": mat("13 Antique gold", (0.68, 0.38, 0.105), metallic=0.66, roughness=0.34),
    "gold_light": mat("14 Pale gold edges", (0.91, 0.67, 0.27), metallic=0.45, roughness=0.38),
    "ruby": mat("15 Ruby", (0.57, 0.003, 0.057), metallic=0.36, roughness=0.22),
    "ruby_light": mat("16 Ruby lit facets", (0.94, 0.025, 0.16), metallic=0.28, roughness=0.22),
    "ruby_dark": mat("17 Ruby dark facets", (0.16, 0.001, 0.027), metallic=0.40, roughness=0.30),
    "eye_white": mat("18 Eye white", (0.97, 0.90, 0.86), roughness=0.48),
    "iris": mat("19 Crimson iris", (0.54, 0.018, 0.09), roughness=0.42),
    "iris_light": mat("20 Iris lower light", (0.94, 0.09, 0.21), roughness=0.46),
    "glint": mat("21 Eye glint", (1, 0.95, 0.89), roughness=0.32, emission=0.20),
}


def link(obj, parent=True):
    for collection in tuple(obj.users_collection):
        collection.objects.unlink(obj)
    active_collection.objects.link(obj)
    if parent and active_collection == model_collection:
        obj.parent = model_root
    return obj


def mesh(name, verts, faces, materials, indices=None, smooth=True, subdivision=0, thickness=0):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    link(obj)
    for material in materials:
        data.materials.append(M[material] if isinstance(material, str) else material)
    for polygon in data.polygons:
        polygon.use_smooth = smooth
        if indices:
            polygon.material_index = indices[polygon.index]
    if subdivision:
        modifier = obj.modifiers.new("Surface refinement", "SUBSURF")
        modifier.levels = subdivision
        modifier.render_levels = subdivision
    if thickness:
        modifier = obj.modifiers.new("Real fabric thickness", "SOLIDIFY")
        modifier.thickness = thickness
        modifier.offset = 0
    return obj


def curve(name, points, radius, material, cyclic=False):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.resolution_u = 3
    data.bevel_depth = radius
    data.bevel_resolution = 1
    data.use_fill_caps = True
    spline = data.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for p, co in zip(spline.bezier_points, points):
        p.co = co
        p.handle_left_type = "AUTO"
        p.handle_right_type = "AUTO"
    spline.use_cyclic_u = cyclic
    data.materials.append(M[material])
    obj = bpy.data.objects.new(name, data)
    return link(obj)


def ellipsoid(name, center, radii, material, segments=32, rings=20):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.scale = radii
    obj.data.materials.append(M[material])
    for p in obj.data.polygons:
        p.use_smooth = True
    link(obj)
    return obj


def lerp(a, b, t):
    return a * (1 - t) + b * t


def profile_sample(profile, t):
    for i in range(len(profile) - 1):
        if profile[i][0] <= t <= profile[i + 1][0]:
            a, b = profile[i], profile[i + 1]
            u = (t - a[0]) / (b[0] - a[0])
            # Continuous tangents avoid artificial horizontal bands at face rings.
            previous = profile[max(0,i-1)]
            following = profile[min(len(profile)-1,i+2)]
            result=[]
            for axis in range(1,len(a)):
                m0=(b[axis]-previous[axis])/(b[0]-previous[0])
                m1=(following[axis]-a[axis])/(following[0]-a[0])
                value=(2*u**3-3*u*u+1)*a[axis]+(u**3-2*u*u+u)*(b[0]-a[0])*m0+(-2*u**3+3*u*u)*b[axis]+(u**3-u*u)*(b[0]-a[0])*m1
                result.append(max(min(a[axis],b[axis]),min(max(a[axis],b[axis]),value)))
            return tuple(result)
    return profile[0][1:] if t < profile[0][0] else profile[-1][1:]


def loft(name, profile, material, steps=64, segments=48, surface=None):
    verts, faces = [], []
    z0, z1 = profile[0][0], profile[-1][0]
    for ring in range(steps + 1):
        z = lerp(z0, z1, ring / steps)
        rx, ry, cx, cy = profile_sample(profile, z)
        for k in range(segments):
            a = k * 2 * PI / segments
            co = (cx + rx * math.sin(a), cy - ry * math.cos(a), z)
            verts.append(surface(co, a) if surface else co)
    for j in range(steps):
        for k in range(segments):
            a = j * segments + k
            b = j * segments + (k + 1) % segments
            faces.append((a, b, b + segments, a + segments))
    faces.extend([tuple(reversed(range(segments))), tuple(range(steps * segments, (steps + 1) * segments))])
    return mesh(name, verts, faces, [material])


def spline(points, t):
    ps = [Vector(p) for p in points]
    index = min(int(t * (len(ps) - 1)), len(ps) - 2)
    u = t * (len(ps) - 1) - index
    p0 = ps[max(0, index - 1)]
    p1, p2 = ps[index:index + 2]
    p3 = ps[min(len(ps) - 1, index + 2)]
    return .5 * ((2 * p1) + (-p0 + p2) * u + (2*p0 - 5*p1 + 4*p2 - p3) * u*u + (-p0 + 3*p1 - 3*p2 + p3) * u*u*u)


def sweep(name, points, widths, depths, material, sections=28, sides=12, highlight=False):
    verts, faces = [], []
    for j in range(sections + 1):
        t = j / sections
        c = spline(points, t)
        tangent = (spline(points, min(1, t + .005)) - spline(points, max(0, t - .005))).normalized()
        out = Vector((c.x, c.y, .02)).normalized()
        across = tangent.cross(out).normalized()
        if across.length < .5:
            across = tangent.cross(Vector((0, -1, 0))).normalized()
        depth_axis = across.cross(tangent).normalized()
        w = profile_sample(widths, t)[0]
        d = profile_sample(depths, t)[0]
        for k in range(sides):
            a = k * 2 * PI / sides
            verts.append(tuple(c + across * (w * math.cos(a)) + depth_axis * (d * math.sin(a))))
    for j in range(sections):
        for k in range(sides):
            a = j*sides+k
            b = j*sides+(k+1)%sides
            faces.append((a, b, b+sides, a+sides))
    faces.extend([tuple(reversed(range(sides))), tuple(range(sections*sides, (sections+1)*sides))])
    obj = mesh(name, verts, faces, [material, "hair_light"] if highlight else [material])
    # Highlights come from studio lighting. Per-face color stripes produced
    # distracting staircase edges on curved locks in the close-up review.
    return obj


def star(name, center, size, material="gold", points=4, rotation=0, depth=.004):
    x, y, z = center
    vs = [(x, y-depth, z), (x, y+depth, z)]
    for i in range(points*2):
        a = rotation + PI/2 + i*PI/points
        r = size if i % 2 == 0 else size*.32
        vs.append((x+r*math.cos(a), y, z+r*math.sin(a)))
    fs = []
    for i in range(points*2):
        a, b = 2+i, 2+(i+1)%(points*2)
        fs.extend([(0,a,b),(1,b,a)])
    return mesh(name, vs, fs, [material], smooth=False)


# ANATOMY: shaped cross sections rather than a stack of sphere primitives.
torso_profile = [
    (.94, .070, .052, 0, .003), (1.015, .136, .088, 0, .008),
    (1.09, .146, .083, 0, .008), (1.18, .097, .059, 0, 0),
    (1.25, .102, .065, 0, 0), (1.32, .123, .081, 0, -.004),
    (1.405, .160, .104, 0, -.009), (1.457, .162, .083, 0, 0),
    (1.49, .129, .061, 0, .004), (1.525, .052, .037, 0, 0),
    (1.595, .044, .035, 0, 0), (1.62, .044, .035, 0, -.004),
]


def torso_surface(co, angle):
    x, y, z = co
    if math.cos(angle) > 0 and 1.30 < z < 1.47:
        bulge = .039 * math.exp(-((abs(x)-.072)/.050)**2 - ((z-1.407)/.045)**2)
        y -= bulge * max(0, math.cos(angle))
    return x, y, z


loft("Body_Torso_Neck", torso_profile, "skin", surface=torso_surface)
leg_profiles = {}
for sign, side in [(-1, "L"), (1, "R")]:
    profile = [
        (.152, .025, .029, sign*.081, .014), (.235, .028, .034, sign*.083, .009),
        (.37, .048, .045, sign*.088, .020), (.46, .051, .045, sign*.093, .019),
        (.575, .038, .039, sign*.091, -.012), (.63, .044, .044, sign*.088, -.010),
        (.76, .062, .062, sign*.079, .002), (.89, .078, .072, sign*.075, .010),
        (.997, .069, .066, sign*.076, .008), (1.035, .035, .035, sign*.080, .005),
    ]
    leg_profiles[sign] = profile
    loft("Leg_"+side, profile, "skin")
    arm_points = [(sign*.153, .002, 1.465), (sign*.208, .004, 1.42), (sign*.266, -.003, 1.285), (sign*.318, -.016, 1.15), (sign*.35, -.024, 1.075)]
    sweep("Arm_"+side, arm_points, [(0,.053),(.18,.052),(.52,.036),(.72,.03),(1,.024)], [(0,.044),(.3,.039),(.6,.032),(1,.021)], "skin", sections=40, sides=20)
    palm = ellipsoid("Palm_"+side, (sign*.364, -.025, 1.04), (.029,.017,.046), "skin")
    palm.rotation_euler.y = sign*.18
    for digit in range(4):
        dx = -.019 + digit*.012
        base = (sign*(.367+dx), -.026, 1.021)
        length = [.048,.062,.057,.043][digit]
        points = [base, (base[0]+sign*.008, -.031, 1.008), (base[0]+sign*.014,-.038,1.021-length), (base[0]+sign*.013,-.043,1.021-length-.006)]
        sweep("Finger_%s_%s"%(side,digit), points, [(0,.006),( .5,.0055),(1,.0028)], [(0,.006),(.6,.005),(1,.003)], "skin", sections=15, sides=8)
    sweep("Thumb_"+side, [(sign*.345,-.026,1.06),(sign*.332,-.040,1.038),(sign*.330,-.052,1.008)], [(0,.011),(.45,.009),(1,.004)], [(0,.009),(.6,.008),(1,.004)], "skin", sides=10)

# HEAD / FACE: custom face surface with modeled cheeks, nose and jaw.
head_profile = [
    (1.587,.012,.021,0,-.026), (1.607,.032,.042,0,-.027),
    (1.631,.060,.058,0,-.016), (1.659,.083,.065,0,-.005),
    (1.693,.094,.073,0,.003), (1.724,.092,.074,0,.009),
    (1.764,.088,.073,0,.013), (1.797,.064,.062,0,.016),
    (1.818,.008,.012,0,.017),
]


def face_y(x, z):
    rx, ry, _, cy = profile_sample(head_profile, z)
    y = cy - ry * math.sqrt(max(.015, 1 - (x / max(rx,.001))**2))
    nose = .016*math.exp(-(x/.015)**2 - ((z-1.682)/.030)**2)
    nose += .014*math.exp(-(x/.017)**2 - ((z-1.667)/.012)**2)
    sockets = .005*math.exp(-((abs(x)-.047)/.027)**2 - ((z-1.704)/.014)**2)
    return y - nose + sockets


def head_surface(co, a):
    x, y, z = co
    if math.cos(a) > 0:
        y = face_y(x,z)
    return x,y,z


loft("Head_Authored_Face", head_profile, "skin", steps=80, segments=80, surface=head_surface)
for sign, side in [(-1,"L"),(1,"R")]:
    ellipsoid("Ear_"+side, (sign*.093,.009,1.677), (.018,.013,.031), "skin")
    ellipsoid("EarInner_"+side, (sign*.102,-.001,1.678), (.009,.005,.018), "ear", segments=20)
    curve("Earring_chain_"+side, [(sign*.105,-.005,1.654),(sign*.108,-.009,1.631)], .0015,"gold")
    star("Earring_ruby_"+side,(sign*.108,-.010,1.622),.012,"ruby",depth=.003)
    cx, cz, w, h = sign*.044, 1.704, .027, .0085
    def eye_co(a, ring=1):
        x = cx + w*math.cos(a)*ring
        z = cz + h*math.sin(a)*ring + sign*(x-cx)*.11
        return x, face_y(x,z)-.0015-.004*(1-ring*ring), z
    verts = [(cx,face_y(cx,cz)-.0055,cz)]
    for ring in range(1,7):
        verts += [eye_co(i*2*PI/48,ring/6) for i in range(48)]
    faces=[(0,i+1,(i+1)%48+1) for i in range(48)]
    for ring in range(5):
        for i in range(48):
            a=1+ring*48+i;b=1+ring*48+(i+1)%48
            faces.append((a,b,b+48,a+48))
    mesh("EyeWhite_"+side,verts,faces,["eye_white"])
    # Layered, convex iris discs are geometry, not an image on a plane.
    icx = cx
    def eye_disc(name, rx, rz, material, offset, dx=0,dz=0):
        cxx, czz = icx+dx,cz+dz
        y = face_y(cxx,czz)-offset
        vs = [(cxx,y-.0006,czz)]
        for i in range(48):
            a=i*2*PI/48
            x,z=cxx+rx*math.cos(a),czz+rz*math.sin(a)
            vs.append((x,face_y(x,z)-offset,z))
        return mesh(name+side,vs,[(0,i+1,(i+1)%48+1) for i in range(48)],[material], thickness=.0004)
    eye_disc("IrisOutline_",.009,.0081,"ink",.0059)
    eye_disc("Iris_",.008,.0074,"iris",.0064)
    eye_disc("IrisLower_",.006,.003,"iris_light",.0069,dz=-.003)
    eye_disc("Pupil_",.0032,.0056,"ink",.0074)
    eye_disc("EyeGlint_",.002,.0021,"glint",.0082,dx=-.003,dz=.003)
    eye_disc("EyeSmallGlint_",.0008,.0009,"glint",.0082,dx=.003,dz=-.0035)
    upper=[eye_co(i*PI/16) for i in range(17)]
    lower=[eye_co(PI+i*PI/16) for i in range(17)]
    curve("UpperLash_"+side,[(x,y-.001,z) for x,y,z in upper],.0015,"ink")
    curve("LowerLid_"+side,[(x,y-.001,z) for x,y,z in lower],.0008,"ear")
    outerx = cx+sign*w
    lash = [(outerx,face_y(outerx,cz)-.004,cz+.0035),(outerx+sign*.008,face_y(outerx,cz)-.003,cz+.010),(outerx-sign*.006,face_y(outerx,cz)-.006,cz+.010)]
    mesh("OuterLashWing_"+side,lash,[(0,1,2)],["ink"],thickness=.0008)
    brow=[]
    for t in range(7):
        u=t/6
        x=sign*(.022+.054*u)
        z=1.726+.0025*math.sin(u*PI)+.004*u
        brow.append((x,face_y(x,z)-.004,z))
    curve("Eyebrow_"+side,brow,.0025,"hair")
mouth=[(-.015,1.639),(-.007,1.640),(0,1.639),(.007,1.640),(.015,1.641)]
curve("Mouth_line",[(x,face_y(x,z)-.0016,z) for x,z in mouth],.0009,"lip")
curve("Lower_lip",[(x,face_y(x,1.635)-.001,1.635+abs(x)*.1) for x in [-.008,0,.008]],.001,"lip_light")

# HAIR: scalp plus layered tapered locks; no billboard or image projection.
vs,fs=[],[]
for j in range(19):
    t=j/18
    for k in range(64):
        a=k*2*PI/64
        phi_end=1.02 if math.cos(a)>.65 else 2.02
        phi=t*phi_end
        z=1.741+.107*math.cos(phi)
        radius=math.sin(phi)
        vs.append((.107*radius*math.sin(a),.014-.089*radius*math.cos(a),z))
for j in range(18):
    for k in range(64):
        a=j*64+k;b=j*64+(k+1)%64
        fs.append((a,b,b+64,a+64))
mesh("Hair_Scalp",vs,fs,["hair"])
for i in range(32):
    a=2*PI*i/32
    if abs((a+PI)%(2*PI)-PI)<.88:
        continue
    s,c=math.sin(a),math.cos(a)
    endz=1.635+random.uniform(-.025,.020)
    bend=a+.23*math.sin(i*1.4)
    curl=a-.17*math.cos(i)
    points=[(.054*s,.009-.043*c,1.826),(.091*math.sin(a+.1),.012-.086*math.cos(a+.1),1.775),(.115*math.sin(bend),.012-.095*math.cos(bend),1.702),(.110*math.sin(curl),.012-.095*math.cos(curl),endz+.028),(.128*math.sin(curl+.15),.02-.092*math.cos(curl+.15),endz)]
    sweep("Hair_outer_%02d"%i,points,[(0,.009),(.3,.018),(.6,.016),(.83,.011),(1,.0004)],[(0,.004),(.4,.008),(.8,.005),(1,.0003)],"hair_mid" if i%3 else "hair",highlight=i%5==1)
for i in range(9):
    u=i/8
    startx=lerp(.028,.06,u)
    endx=lerp(-.102,-.016,u)
    endz=1.716+.065*u
    points=[(startx,-.023+u*.014,1.830+u*.006),(lerp(startx,endx,.42),-.072,1.812),(endx*.94,-.085,1.772+u*.026),(endx,-.078,endz)]
    sweep("Hair_swept_fringe_%02d"%i,points,[(0,.005),(.25,.017),(.65,.014),(.83,.008),(1,.0003)],[(0,.002),(.3,.005),(.7,.003),(1,.0002)],"hair_mid" if i%2 else "hair",sections=30,highlight=i==4)
for i in range(4):
    points=[(.037+i*.005,-.015,1.838),(.075+i*.009,-.044,1.810),(.09+i*.006,-.066,1.749),(.075+i*.009,-.067,1.721+i*.008)]
    sweep("Hair_parted_right_%s"%i,points,[(0,.004),(.3,.014),(.7,.009),(1,.0002)],[(0,.002),(.4,.005),(1,.0002)],"hair_mid",sections=24)
for i in range(6):
    u=i/5
    points=[(.033+u*.010,-.003+u*.015,1.842),(-.025+u*.012,-.048,1.847-u*.006),(-.075-u*.007,-.073+u*.009,1.814-u*.012),(-.112,-.051+u*.015,1.758-u*.014),(-.106,-.041+u*.012,1.728-u*.007)]
    sweep("Hair_crown_wave_%s"%i,points,[(0,.003),(.23,.011),(.5,.010),(.80,.007),(1,.0002)],[(0,.002),(.4,.005),(.75,.003),(1,.0002)],"hair_mid" if i%2 else "hair",sections=32)
for i in range(17):
    a=1.0+i/16*(2*PI-2)
    s,c=math.sin(a),math.cos(a)
    points=[(.025+s*.01,.005,1.844),(.060*s,.012-.051*c,1.833),(.098*s,.015-.088*c,1.787),(.116*math.sin(a+.08),.015-.098*math.cos(a+.08),1.729),(.110*math.sin(a-.10),.013-.094*math.cos(a-.10),1.708)]
    sweep("Hair_back_crown_%s"%i,points,[(0,.003),(.27,.013),(.58,.015),(.80,.008),(1,.0002)],[(0,.002),(.35,.0045),(.72,.003),(1,.0002)],"hair_mid" if i%3 else "hair",sections=28)
for sign,side in [(-1,"L"),(1,"R")]:
    for i in range(5):
        yy=-.037+i*.023
        points=[(sign*.089,yy,1.762),(sign*(.106+i*.003),yy-.013,1.724),(sign*(.123+i*.002),yy+.003,1.681),(sign*.113,yy+.018,1.637),(sign*.135,yy+.028,1.65)]
        sweep("Hair_curl_%s_%s"%(side,i),points,[(0,.008),(.25,.014),(.65,.011),(.88,.006),(1,.0003)],[(0,.003),(.4,.006),(.85,.003),(1,.0002)],"hair_mid",highlight=False)

# CORSET: follows anatomical surface; central diamond openings remain actual holes.
vs,fs,mi=[],[],[]
rows,cols=72,96
for j in range(rows+1):
    t=j/rows
    for k in range(cols):
        a=k*2*PI/cols
        bottom=.946+.134*(abs(math.sin(a))**1.6)
        top=1.452+.024*(abs(math.sin(a))**1.2)
        z=lerp(bottom,top,t)
        rx,ry,cx,cy=profile_sample(torso_profile,z)
        x,y,z=torso_surface((cx+(rx+.003)*math.sin(a),cy-(ry+.003)*math.cos(a),z),a)
        vs.append((x,y,z))
for j in range(rows):
    for k in range(cols):
        a=j*cols+k;b=j*cols+(k+1)%cols
        x,y,z=vs[a]
        front=math.cos(k*2*PI/cols)>.80
        width=max(.018*max(0,1-abs(z-center)/.023) for center in [1.185,1.245,1.305,1.365])
        if front and 1.151<z<1.383 and abs(x)<width:
            continue
        fs.append((a,b,b+cols,a+cols))
        mi.append(0)
mesh("Corset_seamed_panels",vs,fs,["black","ivory"],mi,thickness=.002)


def bodice_point(x,z,offset=.005):
    rx,ry,_,cy=profile_sample(torso_profile,z)
    a=math.asin(max(-.98,min(.98,x/rx)))
    return torso_surface((x,cy-(ry+offset)*math.cos(a),z),a)


for sign in [-1,1]:
    contour=[(.013,1.445),(.055,1.458),(.104,1.463),(.127,1.445),(.117,1.407),(.073,1.392),(.027,1.408)]
    closed=[(sign*x,0,z) for x,z in contour]
    closed=[closed[-1]]+closed+[closed[0],closed[1]]
    boundary=[]
    for k in range(56):
        p=spline(closed,(1+(k/56)*len(contour))/(len(closed)-1))
        boundary.append((p.x,p.z))
    vs=[bodice_point(sign*.067,1.427,.006)]
    for ring in range(1,9):
        for k in range(56):
            x=lerp(sign*.067,boundary[k][0],ring/8)
            z=lerp(1.427,boundary[k][1],ring/8)
            vs.append(bodice_point(x,z,.006))
    fs=[(0,i+1,(i+1)%56+1) for i in range(56)]
    for ring in range(7):
        for k in range(56):
            a=1+ring*56+k;b=1+ring*56+(k+1)%56
            fs.append((a,b,b+56,a+56))
    mesh("Ivory_cup_%s"%sign,vs,fs,["ivory"],thickness=.001)
    curve("Cup_gold_outline_%s"%sign,vs[-56:],.0011,"gold",True)
for center in [1.185,1.245,1.305,1.365]:
    points=[bodice_point(x,z,.006) for x,z in [(0,center-.024),(.020,center),(0,center+.024),(-.020,center)]]
    edge=curve("Cutout_gold_border_%.3f"%center,points,.0017,"gold",True)
    for point in edge.data.splines[0].bezier_points:
        point.handle_left_type="VECTOR";point.handle_right_type="VECTOR"
for level in ("bottom","top"):
    points=[]
    for k in range(96):
        a=k*2*PI/96
        z=.946+.134*abs(math.sin(a))**1.6 if level=="bottom" else 1.452+.024*abs(math.sin(a))**1.2
        rx,ry,cx,cy=profile_sample(torso_profile,z)
        points.append(torso_surface(((rx+.005)*math.sin(a),cy-(ry+.005)*math.cos(a),z),a))
    curve("Corset_gold_"+level,points,.0015,"gold",True)
for sign in [-1,1]:
    points=[]
    for z in [1.06,1.12,1.18,1.25,1.32,1.40,1.46]:
        rx,ry,_,cy=profile_sample(torso_profile,z)
        a=sign*.67
        p=torso_surface(((rx+.005)*math.sin(a),cy-(ry+.005)*math.cos(a),z),a)
        points.append(p)
    curve("Corset_princess_seam_%s"%sign,points,.0014,"red")
for z in [1.17,1.225,1.283,1.343,1.40]:
    rx,ry,_,cy=profile_sample(torso_profile,z)
    y=torso_surface((0,cy-ry-.006,z),0)[1]
    star("Corset_fastener_%.3f"%z,(0,y,z),.008,"gold",depth=.002)
    if z<1.39:
        curve("Corset_lacing_%.3f"%z,[(-.023,y+.003,z-.024),(0,y-.001,z),(.023,y+.003,z+.024)],.0011,"gold")


def ruffle(name, center, radius, width, material, waves=18, tilt=None):
    vs,fs=[],[]
    for j in range(5):
        t=j/4
        r=radius+width*t
        for k in range(96):
            a=k*2*PI/96
            p=Vector((r*math.cos(a),r*.8*math.sin(a),.009*math.sin(a*waves)*t))
            if tilt:
                p=tilt@p
            vs.append(tuple(Vector(center)+p))
    for j in range(4):
        for k in range(96):
            a=j*96+k;b=j*96+(k+1)%96
            fs.append((a,b,b+96,a+96))
    return mesh(name,vs,fs,[material],thickness=.0015)


ruffle("Neck_ruffle",(0,0,1.553),.044,.024,"black",waves=24)
curve("Neck_gold_line",[(.049*math.sin(a*2*PI/64),-.039*math.cos(a*2*PI/64),1.561) for a in range(64)],.0015,"gold",True)
star("Neck_bow_center",(0,-.070,1.532),.017,"gold",depth=.005)
star("Neck_ruby",(0,-.076,1.532),.011,"ruby",depth=.005)
for sign in [-1,1]:
    mesh("Crimson_bow_wing_%s"%sign,[(sign*.009,-.066,1.533),(sign*.062,-.060,1.551),(sign*.050,-.073,1.521),(sign*.040,-.073,1.512),(sign*.008,-.072,1.526)],[(0,1,2),(0,2,4),(2,3,4)],["red","red_light"],[0,1,0],thickness=.003)
    sweep("Bow_tail_%s"%sign,[(sign*.009,-.067,1.523),(sign*.028,-.071,1.503),(sign*.041,-.074,1.485)],[(0,.008),(.6,.012),(1,.001)],[(0,.002),(1,.001)],"red")

# PUFFED HARLEQUIN SLEEVES with explicit diamond-shaped fabric panels.
for sign,side in [(-1,"L"),(1,"R")]:
    points=[(sign*.208,.004,1.447),(sign*.249,-.003,1.347),(sign*.288,-.008,1.245),(sign*.329,-.018,1.12)]
    direction=(Vector(points[-1])-Vector(points[0])).normalized()
    width_axis=Vector((0,1,0))
    radial_axis=direction.cross(width_axis).normalized()
    def sleeve(t,a,offset=0):
        center=spline(points,t)
        radius=profile_sample([(0,.045),(.2,.060),(.47,.067),(.70,.060),(.88,.056),(1,.030)],t)[0]+offset
        fold=1+.04*math.sin(12*a+t*4)
        return tuple(center+(width_axis*math.sin(a)+radial_axis*math.cos(a))*radius*fold)
    vs=[sleeve(j/56,k*2*PI/64) for j in range(57) for k in range(64)]
    fs=[]
    for j in range(56):
        for k in range(64):
            a=j*64+k;b=j*64+(k+1)%64
            fs.append((a,b,b+64,a+64))
    mesh("Sleeve_ivory_"+side,vs,fs,["ivory"],thickness=.002)
    for row in range(4):
        for col in range(8):
            t=.13+row*.235
            a=(col+(row%2)*.5)*2*PI/8
            diamond=[]
            for u,v in [(0,0),(0,-.113),(.36,0),(0,.113),(-.36,0)]:
                diamond.append(sleeve(max(0,min(1,t+v)),a+u,.0013))
            mesh("Sleeve_diamond_%s_%d_%d"%(side,row,col),diamond,[(0,1,2),(0,2,3),(0,3,4),(0,4,1)],["red" if (col+row)%3 else "black"],thickness=.0005)
    # Ruffles oriented perpendicular to the arm rather than horizontal bracelets.
    rotation=Vector((0,0,1)).rotation_difference(direction).to_matrix()
    ruffle("Shoulder_ruffle_"+side,points[0],.042,.027,"ivory",waves=16,tilt=rotation)
    ruffle("Wrist_ruffle_"+side,points[-1],.027,.027,"black",waves=14,tilt=rotation)
    curve("Wrist_gold_band_"+side,[sleeve(.985,k*2*PI/48,.001) for k in range(48)],.0017,"gold",True)
    star("Shoulder_star_"+side,(sign*.220,-.048,1.45),.026,"gold_light",points=5,depth=.004)
    star("Wrist_star_"+side,(sign*.334,-.062,1.12),.014,"gold",points=5,depth=.003)

# STOCKINGS AND HEELS: full volume, aligned with the floor.
for sign,side in [(-1,"L"),(1,"R")]:
    profile=leg_profiles[sign]
    def stocking(t,a,offset=0):
        top=.877+.026*math.cos(a*2)
        z=lerp(.17,top,t)
        rx,ry,cx,cy=profile_sample(profile,z)
        return (cx+(rx+.0015+offset)*math.sin(a),cy-(ry+.0015+offset)*math.cos(a),z)
    vs=[stocking(j/64,k*2*PI/48) for j in range(65) for k in range(48)]
    fs=[]
    for j in range(64):
        for k in range(48):
            a=j*48+k;b=j*48+(k+1)%48
            fs.append((a,b,b+48,a+48))
    mesh("Stocking_"+side,vs,fs,["ivory"],thickness=.001)
    for row in range(3):
        center=.20+row*.30
        for a in [0,PI]:
            # Triangulated surface sampling keeps diamonds flush with the calf.
            vs=[]
            for j in range(13):
                u=j/12
                t=center+(u-.5)*.35
                half=.72*(1-abs(2*u-1))
                for k in range(9):
                    vs.append(stocking(t,a+lerp(-half,half,k/8),.0015))
            fs=[]
            for j in range(12):
                for k in range(8):
                    q=j*9+k;fs.append((q,q+1,q+10,q+9))
            mesh("Stocking_ruby_diamond_%s_%s_%s"%(side,row,a),vs,fs,["red"],thickness=.0005)
    cx=sign*.081
    # Foot section runs from the pointed toe to the heel cup.
    foot=[(-.170,.001,.002,.031),(-.143,.021,.009,.035),(-.108,.033,.017,.042),(-.055,.037,.028,.060),(.005,.032,.043,.098),(.053,.030,.047,.120),(.064,.009,.022,.129)]
    vs,fs,mi=[],[],[]
    for y,w,h,z in foot:
        for k in range(24):
            a=k*2*PI/24
            vs.append((cx+w*math.sin(a),y,z+h*math.cos(a)))
    for j in range(len(foot)-1):
        for k in range(24):
            q=j*24+k;r=j*24+(k+1)%24
            fs.append((q,r,r+24,q+24));mi.append(1 if j<3 else 0)
    fs += [tuple(reversed(range(24))),tuple(range((len(foot)-1)*24,len(foot)*24))]
    mi += [1,0]
    mesh("Heeled_shoe_"+side,vs,fs,["black","ruby"],mi,subdivision=1)
    sweep("Stiletto_heel_"+side,[(cx,.05,.132),(cx,.051,.055),(cx,.057,.013)],[(0,.013),(.3,.009),(1,.0055)],[(0,.012),(.3,.010),(1,.007)],"black",sections=16,sides=8)
    curve("Heel_gold_line_"+side,[(cx-.013,.044,.13),(cx-.006,.047,.055),(cx-.004,.050,.016)],.0015,"gold")
    curve("Ankle_strap_"+side,[(cx+.029*math.sin(a*2*PI/48),.013-.034*math.cos(a*2*PI/48),.189) for a in range(48)],.005,"black",True)
    star("Ankle_star_"+side,(cx,-.025,.19),.023,"gold",points=5,depth=.004)
    star("Ankle_ruby_"+side,(cx,-.03,.19),.012,"ruby",depth=.003)

# SEPARATE LONG COAT TAILS, open in front so legs remain readable.
for i,degrees in enumerate([64,88,113,140,167,193,220,247,273,297]):
    angle=math.radians(degrees)
    endz=[.28,.16,.23,.11,.19,.14,.13,.26,.18,.32][i]
    length=1.115-endz
    main="black" if i%2 else "red"
    def tail(t,u):
        radius=.142+.12*t+.11*t*t
        width=(.045+.054*math.sin(PI*t*.86)) * (1-t**7)
        width=max(width,.0004)
        a=angle+.14*math.sin(t*PI*1.5+i*.7)
        center=Vector((radius*math.sin(a),-radius*.82*math.cos(a),1.115-length*t))
        across=Vector((math.cos(a),math.sin(a),0))
        return tuple(center+across*(width*u)+Vector((0,.009*math.sin(t*PI*4+u*3+i),.013*math.sin(u*PI)*math.sin(t*PI))))
    vs=[tail(j/40,lerp(-1,1,k/10)) for j in range(41) for k in range(11)]
    fs=[]
    for j in range(40):
        for k in range(10):
            a=j*11+k;fs.append((a,a+1,a+12,a+11))
    mesh("Coat_tail_%02d"%i,vs,fs,[main],thickness=.0025)
    if i in [0,2,7,9]:
        # Large ivory inlays, not a texture painted over the whole model.
        vs=[]
        for j in range(25):
            t=.20+j/24*.57
            width=.75*(1-abs(2*j/24-1))
            for u in [-width,width]:
                x,y,z=tail(t,u)
                vs.append((x,y-.003*math.cos(angle),z+.0005))
        mesh("Tail_ivory_inlay_%02d"%i,vs,[(j*2,j*2+1,j*2+3,j*2+2) for j in range(24)],["ivory"],thickness=.0007)
    if i%2:
        for edge in [-1,1]:
            curve("Tail_gold_edge_%s_%s"%(i,edge),[tail(j/20,edge*.99) for j in range(21)],.0009,"gold")
    tip=Vector(tail(1,0))
    star("Tail_tip_charm_%s"%i,tuple(tip+Vector((0,0,-.011))),.016,"gold",depth=.003)
for sign in [-1,1]:
    star("Hip_gold_star_%s"%sign,(sign*.133,-.045,1.101),.029,"gold",points=5,depth=.006)
    star("Hip_ruby_star_%s"%sign,(sign*.133,-.052,1.101),.019,"ruby",points=5,depth=.005)

# THE DOUBLE-ENDED FATE LANCE, separately editable and ready for a hand socket.
lance_root=bpy.data.objects.new("Fate_Lance_Separate",None)
model_collection.objects.link(lance_root)
lance_root.parent=model_root
lance_root.location=(.61,0,1.075)
lance_root.rotation_euler.y=-.13
weapon_objects=[]
before=set(model_collection.objects)
loft("Lance_shaft",[(-.73,.010,.010,0,0),(.73,.010,.010,0,0)],"black",steps=1,segments=12)
for i in range(3):
    points=[]
    for j in range(91):
        t=j/90;a=t*PI*6+i*2*PI/3
        points.append((.0105*math.cos(a),.0105*math.sin(a),lerp(-.73,.73,t)))
    curve("Lance_crimson_inlay_%s"%i,points,.0019,"ruby")
for sign in [-1,1]:
    z=sign*.745
    loft("Lance_gold_socket_%s"%sign,[(z-.018,.022,.022,0,0),(z,.031,.031,0,0),(z+.018,.019,.019,0,0)],"gold",steps=8,segments=16)
    # Asymmetric light/dark facets describe actual volume in all views.
    base=sign*.77;shoulder=sign*.835;tip=sign*1.02
    vs=[(0,0,base),(0,-.035,shoulder),( .065,0,shoulder),(0,.035,shoulder),(-.065,0,shoulder),(0,0,tip)]
    fs=[(0,2,1),(0,3,2),(0,4,3),(0,1,4),(5,1,2),(5,2,3),(5,3,4),(5,4,1)]
    mesh("Lance_ruby_blade_%s"%sign,vs,fs,["ruby","ruby_light","ruby_dark"],[0,2,0,1,1,0,2,0],smooth=False)
    for k in range(4):
        a=k*PI/2
        x,y=.066*math.cos(a),.036*math.sin(a)
        ridge=curve("Blade_gold_ridge_%s_%s"%(sign,k),[(0,0,base),(x,y,shoulder),(0,0,tip)],.0014,"gold_light")
        for point in ridge.data.splines[0].bezier_points:
            point.handle_left_type="VECTOR";point.handle_right_type="VECTOR"
    for row in range(3):
        z=sign*(.60+row*.067)
        vs=[]
        for zz in [z-.005,z+.005]:
            for k in range(16):
                a=k*2*PI/16+row*.4
                r=(.045+row*.004) if k%4==0 else (.026 if k%2==0 else .017)
                vs.append((r*math.cos(a),r*math.sin(a),zz))
        fs=[tuple(reversed(range(16))),tuple(range(16,32))]
        fs += [(k,(k+1)%16,(k+1)%16+16,k+16) for k in range(16)]
        mesh("Lance_four_point_guard_%s_%s"%(sign,row),vs,fs,["gold"],smooth=False)
        for k in range(4):
            a=k*PI/2+row*.5
            out=Vector((math.cos(a),math.sin(a),0))
            start=Vector((0,0,z))+out*.012
            end=Vector((0,0,z+sign*.043))+out*(.039+row*.006)
            bend=Vector((0,0,z+sign*.006))+out*.029
            sweep("Lance_gold_thorn_%s_%s_%s"%(sign,row,k),[start,bend,end],[(0,.006),(.45,.008),(1,.0003)],[(0,.005),(.6,.004),(1,.0003)],"gold",sections=10,sides=6)
for obj in set(model_collection.objects)-before:
    obj.parent=lance_root
    weapon_objects.append(obj)

# Apply modifiers / convert curves before export so the review GLB is self-contained.
for obj in list(model_collection.objects):
    if obj.type in {"MESH","CURVE"}:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        if obj.type=="CURVE":
            bpy.ops.object.convert(target="MESH")
        for modifier in list(obj.modifiers):
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        # Recalculate consistently outward-facing normals on closed surfaces.
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode="OBJECT")

# Union overlapping locks into one sculpt. Near-coplanar ribbon boundaries on
# the fringe caused visible staircase intersections even without color stripes.
hair_objects=[o for o in model_collection.objects if o.type=="MESH" and o.name.startswith("Hair_")]
bpy.ops.object.select_all(action="DESELECT")
for obj in hair_objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active=bpy.data.objects["Hair_Scalp"]
bpy.ops.object.join()
hair=bpy.context.object
hair.name="Hair_Unified_Sculpt"
union=hair.modifiers.new("Union intersecting authored locks","REMESH")
union.mode="VOXEL"
union.voxel_size=.0012
union.use_smooth_shade=True
bpy.ops.object.modifier_apply(modifier=union.name)
smooth=hair.modifiers.new("Soften voxel surface","SMOOTH")
smooth.factor=.35
smooth.iterations=3
bpy.ops.object.modifier_apply(modifier=smooth.name)
reduce=hair.modifiers.new("Study mesh reduction","DECIMATE")
reduce.ratio=.18
bpy.ops.object.modifier_apply(modifier=reduce.name)
hair.data.materials.clear()
hair.data.materials.append(M["hair_mid"])
for polygon in hair.data.polygons:
    polygon.material_index=0
    polygon.use_smooth=True

# Put the actual soles on z=0, independent of the studio's decorative floor.
sole_min=min((o.matrix_world @ vertex.co).z for o in model_collection.objects if o.type=="MESH" and (o.name.startswith("Heeled_shoe_") or o.name.startswith("Stiletto_heel_")) for vertex in o.data.vertices)
model_root.location.z=-sole_min
bpy.context.view_layer.update()

vertices=sum(len(o.data.vertices) for o in model_collection.objects if o.type=="MESH")
triangles=0
for o in model_collection.objects:
    if o.type=="MESH":
        o.data.calc_loop_triangles()
        triangles+=len(o.data.loop_triangles)
        assert all(math.isfinite(v) for vertex in o.data.vertices for v in vertex.co)
assert bpy.data.objects["Head_Authored_Face"].dimensions.y > .10
assert bpy.data.objects["Body_Torso_Neck"].dimensions.y > .15
assert len(weapon_objects)>20
bpy.ops.object.select_all(action="DESELECT")
for obj in model_collection.objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active=model_root
bpy.ops.export_scene.gltf(filepath=str(SOURCE/"pierrot_study.glb"),export_format="GLB",use_selection=True,export_animations=False,export_yup=True)

# REVIEW STUDIO. This collection is excluded from the exported model.
active_collection=stage_collection
floor_mat=mat("Studio slate",(.023,.031,.052),roughness=.86)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.006))
floor=bpy.context.object;floor.name="StudioFloor";link(floor,parent=False)
floor.data.materials.append(floor_mat)


def light(name, location, energy, color, size, target=(0,0,1)):
    data=bpy.data.lights.new(name,"AREA")
    data.energy=energy;data.color=color;data.shape="DISK";data.size=size
    obj=bpy.data.objects.new(name,data);stage_collection.objects.link(obj)
    obj.location=location
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat("-Z","Y").to_euler()


light("Large ivory key",(-3,-4,5),420,(1,.83,.75),4)
light("Cool fill",(3,-2,3),230,(.66,.78,1),3)
light("Ruby rim",(1,2,3.5),420,(1,.39,.43),2)
camera_data=bpy.data.cameras.new("ReviewCamera")
camera=bpy.data.objects.new("ReviewCamera",camera_data)
stage_collection.objects.link(camera)
scene.camera=camera
camera_data.type="ORTHO"
camera_data.lens=70
camera.location=(3,-6,2.50)
camera.rotation_euler=(Vector((.08,0,.97))-camera.location).to_track_quat("-Z","Y").to_euler()
camera_data.ortho_scale=2.30
scene.render.resolution_x=900
scene.render.resolution_y=1100
scene.render.resolution_percentage=100
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=="VIEW_3D":
            area.spaces.active.region_3d.view_location=(0,0,.97)
            area.spaces.active.region_3d.view_distance=2.8
            area.spaces.active.region_3d.view_rotation=camera.rotation_euler.to_quaternion()
            area.spaces.active.shading.type="SOLID"
            area.spaces.active.shading.color_type="MATERIAL"
            area.spaces.active.overlay.show_extras=False


def render(name, pos, target, scale, width, height):
    camera.location=pos
    camera.rotation_euler=(Vector(target)-camera.location).to_track_quat("-Z","Y").to_euler()
    camera_data.ortho_scale=scale
    scene.render.resolution_x=width
    scene.render.resolution_y=height
    scene.render.resolution_percentage=100
    scene.render.filepath=str(OUT/(name+".png"))
    bpy.ops.render.render(write_still=True)


bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/"pierrot_study.blend"))
manifest={
    "status":"First geometry and costume study. Not rigged, not approved, not integrated into the game.",
    "reference":"godot/assets/combat/heroes/pierrot.png",
    "construction":"Authored 3D meshes, shaped anatomical sections, volumetric hair, modeled face and garments. No image planes.",
    "blender":bpy.app.version_string,"vertices":vertices,"triangles":triangles,
    "mesh_objects":sum(o.type=="MESH" for o in model_collection.objects),
    "materials":list(M),"weapon_is_separate":True,"height_meters":1.85,
    "next":["Visual review of proportions and likeness","Retopology and UVs","Rig and finger grips","Fate thrust animation","Shared Godot 3D combat stage"],
    "limitations":["Back of outfit is an interpretation; source is a single front three-quarter illustration","Study meshes are not final deformation topology","No skeletal animation yet","Materials are flat-color PBR bases, not final anime toon shader"],
}
(SOURCE/"manifest.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding="utf-8")
print("PIERROT_STUDY_GEOMETRY_READY",json.dumps({k:manifest[k] for k in ["vertices","triangles","mesh_objects"]}))
if args.face_only and not args.no_render:
    render("face",(.75,-3,1.85),(0,-.01,1.695),.44,1000,1000)
elif not args.no_render:
    render("three_quarter",(3,-6,2.50),(.08,0,.97),2.30,900,1100)
    if not args.quick:
        render("front",(0,-6,1.40),(.08,0,.98),2.25,900,1100)
        render("back",(0,6,1.48),(.08,0,.98),2.25,900,1100)
        render("face",(.75,-3,1.85),(0,-.01,1.695),.44,1000,1000)
        # A real three-camera-angle board, rendered from three instances of the
        # SAME mesh. No generated illustration or post-render image alteration.
        scene.collection.children.unlink(model_collection)
        review_objects=[]
        for x,angle,label in [(-1.45,0,"PRZOD"),(0,-.55,"3/4"),(1.45,PI,"TYL")]:
            instance=bpy.data.objects.new("Review_"+label,None)
            instance.instance_type="COLLECTION"
            instance.instance_collection=model_collection
            instance.location=(x,0,0)
            instance.rotation_euler.z=angle
            stage_collection.objects.link(instance)
            review_objects.append(instance)
            data=bpy.data.curves.new("Label_"+label,"FONT")
            data.body=label;data.size=.065;data.align_x="CENTER"
            data.materials.append(M["gold_light"])
            text=bpy.data.objects.new("Label_"+label,data)
            text.location=(x,-.05,2.225)
            text.rotation_euler.x=PI/2
            stage_collection.objects.link(text)
            review_objects.append(text)
        render("turnaround",(0,-8,2.20),(.05,0,1.06),4.75,1800,1050)
        for obj in review_objects:
            bpy.data.objects.remove(obj,do_unlink=True)
        scene.collection.children.link(model_collection)
print("PIERROT_STUDY_COMPLETE",str(SOURCE))
