# GLB çok açılı önizleme: blender -b -P preview_turn.py -- <in.glb> <out.png>
# Aynı modeli 4 açıdan (ön, 3/4, yan, arka) yan yana dizip tek görüntü olarak çizer.
import bpy, sys, math
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
cols = {"uniform": (0.36, 0.38, 0.3), "vest": (0.06, 0.06, 0.06), "pack": (0.36, 0.3, 0.2), "helmet": (0.38, 0.4, 0.32),
        "team": (0.1, 0.35, 0.95), "skin": (0.75, 0.58, 0.42), "boot": (0.42, 0.34, 0.22), "dark": (0.035, 0.035, 0.035),
        "glove": (0.12, 0.12, 0.1), "lens": (0.9, 0.45, 0.05), "gun": (0.3, 0.3, 0.3)}
xs = [-1.5, -0.5, 0.5, 1.5]
rots = [180, 140, 90, 0]
for i in range(4):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=argv[0])
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.parent is None:
            o.location.x = xs[i]
            o.rotation_mode = 'XYZ'
            o.rotation_euler.z = math.radians(rots[i])
for m in bpy.data.materials:
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    if b:
        for l in list(b.inputs["Base Color"].links):
            m.node_tree.links.remove(l)
        c = cols.get(m.name.split(".")[0], (0.5, 0.5, 0.5))
        b.inputs["Base Color"].default_value = (*c, 1)
        b.inputs["Roughness"].default_value = 0.25 if m.name.startswith("lens") else 0.85
bpy.ops.mesh.primitive_plane_add(size=20)
pl = bpy.context.active_object
pm = bpy.data.materials.new("floor"); pm.use_nodes = True
pm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.42, 0.47, 0.52, 1)
pl.data.materials.append(pm)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE_NEXT'
sc.render.resolution_x = 1600
sc.render.resolution_y = 900
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.3, 0.35, 0.4)
bpy.ops.object.light_add(type='SUN', rotation=(math.radians(55), math.radians(0), math.radians(160)))
bpy.context.active_object.data.energy = 3.5
bpy.ops.object.camera_add(location=(0, 6.0, 1.0), rotation=(math.radians(88), 0, math.radians(180)))
cam = bpy.context.active_object
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 4.4
sc.camera = cam
sc.render.filepath = argv[1]
bpy.ops.render.render(write_still=True)
print("PREVIEW OK")
