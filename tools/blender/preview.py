# GLB önizleme render'ı: blender -b -P preview.py -- <in.glb> <out.png>
import bpy, sys, math
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=argv[0])
cols = {"uniform": (0.45, 0.42, 0.3), "vest": (0.42, 0.36, 0.26), "pack": (0.4, 0.35, 0.25), "helmet": (0.4, 0.37, 0.27),
        "team": (0.1, 0.4, 0.95), "skin": (0.72, 0.55, 0.42), "boot": (0.35, 0.28, 0.2), "dark": (0.05, 0.05, 0.05), "glove": (0.2, 0.18, 0.15)}
for m in bpy.data.materials:
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        c = cols.get(m.name.split(".")[0], (0.5, 0.5, 0.5))
        bsdf.inputs["Base Color"].default_value = (*c, 1)
        bsdf.inputs["Roughness"].default_value = 0.8
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE_NEXT'
sc.render.resolution_x = 900
sc.render.resolution_y = 900
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.6, 0.62, 0.65)
bpy.ops.object.light_add(type='SUN', rotation=(math.radians(50), 0, math.radians(30)))
bpy.context.active_object.data.energy = 4
for i, (x, rz) in enumerate([(0, 30), (1.1, 200)]):
    pass
bpy.ops.object.camera_add(location=(2.2, -2.6, 2.1), rotation=(math.radians(68), 0, math.radians(40)))
cam = bpy.context.active_object
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 2.2
sc.camera = cam
cam.location = (1.9, -1.9, 1.75)
sc.render.filepath = argv[1]
bpy.ops.render.render(write_still=True)
print("PREVIEW OK")
