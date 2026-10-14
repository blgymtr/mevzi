# Araç önizleme: blender -b -P preview.py -- <in.glb> <out_prefix>   → <out>_a.png (ön 3/4), <out>_b.png (arka 3/4)
import bpy, sys, math
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=argv[0])
cols = {"paint": (0.5, 0.45, 0.3), "trim": (0.4, 0.36, 0.26), "metal": (0.3, 0.3, 0.29), "track": (0.1, 0.1, 0.09),
        "rubber": (0.05, 0.05, 0.05), "glass": (0.03, 0.05, 0.07), "dark": (0.05, 0.05, 0.05), "light": (1, 0.95, 0.8),
        "canvas": (0.42, 0.4, 0.28), "red": (0.6, 0.05, 0.03), "mark": (0.9, 0.9, 0.9)}
for m in bpy.data.materials:
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    if b:
        for l in list(b.inputs["Base Color"].links):
            m.node_tree.links.remove(l)
        k = m.name.split(".")[0].split("_")[0]
        b.inputs["Base Color"].default_value = (*cols.get(k, (0.5, 0.5, 0.5)), 1)
        b.inputs["Roughness"].default_value = 0.6
        b.inputs["Metallic"].default_value = 0.2 if k in ("paint", "metal") else 0.0
bpy.ops.mesh.primitive_plane_add(size=60)
pm = bpy.data.materials.new("floor"); pm.use_nodes = True
pm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.42, 0.44, 0.4, 1)
bpy.context.active_object.data.materials.append(pm)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE_NEXT'
sc.render.resolution_x = 1200
sc.render.resolution_y = 800
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.35, 0.4, 0.45)
bpy.ops.object.light_add(type='SUN', rotation=(math.radians(50), 0, math.radians(140)))
bpy.context.active_object.data.energy = 4.0
R = float(argv[2]) if len(argv) > 2 else 11.0
for tag, yaw in (("a", 35), ("b", 215)):
    a = math.radians(yaw)
    loc = (math.sin(a) * R, math.cos(a) * R, R * 0.55)
    bpy.ops.object.camera_add(location=loc)
    cam = bpy.context.active_object
    d = (-loc[0], -loc[1], 1.2 - loc[2])
    import mathutils
    cam.rotation_euler = mathutils.Vector(d).to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 50
    sc.camera = cam
    sc.render.filepath = argv[1] + "_" + tag + ".png"
    bpy.ops.render.render(write_still=True)
print("PREVIEW OK")
