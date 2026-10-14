# Blender araç kütüphanesi: sert yüzey parçaları (faset stil, pah kırılmış kenarlar).
# Koordinat: Blender Z yukarı, +Y ileri (glTF'te -Z), +X sağ. Birim: metre (gerçek ölçek).
# Düğümler: body (0,0,0), turret (taret halkası), barrel (muylu). Malzeme adları oyundaki Art.material ile eşleşir:
#   paint_<ulus>, trim_<ulus>, metal, track, rubber, glass, dark, light, mark, canvas
import bpy, bmesh, math
from mathutils import Vector, Matrix, Euler

NAT = "usa"
COLS = {"paint": (0.55, 0.5, 0.36), "trim": (0.42, 0.38, 0.28), "metal": (0.35, 0.35, 0.34), "track": (0.12, 0.12, 0.11),
        "rubber": (0.06, 0.06, 0.06), "glass": (0.05, 0.08, 0.1), "dark": (0.06, 0.06, 0.06), "light": (1, 0.95, 0.8),
        "mark": (0.9, 0.9, 0.9), "canvas": (0.45, 0.42, 0.3), "red": (0.6, 0.05, 0.03)}
_M = {}
NODES = {"body": [], "turret": [], "barrel": []}
CUR = "body"

def reset(nat):
    global NAT, CUR
    NAT = nat
    CUR = "body"
    for k in NODES:
        NODES[k] = []
    _M.clear()
    bpy.ops.wm.read_factory_settings(use_empty=True)

def node(n):
    global CUR
    CUR = n
    NODES.setdefault(n, [])

def mat(n):
    full = n + "_" + NAT if n in ("paint", "trim") else n
    if full not in _M:
        m = bpy.data.materials.new(full)
        m.use_nodes = True
        b = m.node_tree.nodes.get("Principled BSDF")
        if b:
            b.inputs["Base Color"].default_value = (*COLS.get(n, (0.5, 0.5, 0.5)), 1)
            b.inputs["Roughness"].default_value = 0.7
        _M[full] = m
    return _M[full]

def _fin(o, mname, bev=0.0, seg=1):
    if bev > 0:
        b = o.modifiers.new("bev", 'BEVEL'); b.width = bev; b.segments = seg; b.limit_method = 'ANGLE'; b.angle_limit = math.radians(40)
    o.data.materials.clear()
    o.data.materials.append(mat(mname))
    NODES[CUR].append(o)
    return o

def box(loc, size, mname="paint", rot=(0, 0, 0), bev=0.02):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    return _fin(o, mname, bev)

def cyl(loc, r, depth, mname="metal", axis="Z", seg=16, r2=None, bev=0.0, rot=None):
    bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r, radius2=r if r2 is None else r2, depth=depth, location=loc)
    o = bpy.context.active_object
    if rot is not None:
        o.rotation_euler = rot
    elif axis == "X":
        o.rotation_euler = (0, math.pi / 2, 0)
    elif axis == "Y":
        o.rotation_euler = (math.pi / 2, 0, 0)
    return _fin(o, mname, bev)

def poly_extrude_x(profile, x0, x1, mname="paint", bev=0.02):
    """YZ düzleminde çokgen (y,z) → X boyunca x0..x1 katı."""
    me = bpy.data.meshes.new("p"); bm = bmesh.new()
    a = [bm.verts.new((x0, y, z)) for y, z in profile]
    b = [bm.verts.new((x1, y, z)) for y, z in profile]
    n = len(profile)
    bm.faces.new(a[::-1]); bm.faces.new(b)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("p", me); bpy.context.collection.objects.link(o)
    return _fin(o, mname, bev)

def loft(sections, mname="paint", bev=0.02, cap=True):
    """sections: [(y, [(x,z), ...])] — her kesit aynı nokta sayısında, x>=0 yarım profil (alt merkezden üst merkeze);
    X'e göre aynalanır. Uçlar kapatılır."""
    me = bpy.data.meshes.new("l"); bm = bmesh.new()
    rings = []
    for y, half in sections:
        pts = list(half) + [(-x, z) for x, z in reversed(half)][1:-1] if half[0][0] == 0 and half[-1][0] == 0 else list(half) + [(-x, z) for x, z in reversed(half)]
        rings.append([bm.verts.new((x, y, z)) for x, z in pts])
    for r1, r2 in zip(rings, rings[1:]):
        n = len(r1)
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((r1[i], r1[j], r2[j], r2[i]))
    if cap:
        bm.faces.new(rings[0][::-1]); bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("l", me); bpy.context.collection.objects.link(o)
    return _fin(o, mname, bev)

def hull_pts(pts, mname="paint", bev=0.02):
    """Dışbükey gövde (nokta bulutundan)."""
    me = bpy.data.meshes.new("h"); bm = bmesh.new()
    for p in pts:
        bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("h", me); bpy.context.collection.objects.link(o)
    return _fin(o, mname, bev)

# ------------------------------------------------------------ yürüyen aksam
def road_wheel(x, y, z, r, w, side):
    s = side
    cyl((x, y, z), r, w, "rubber", "X", seg=20)
    cyl((x + s * w * 0.5, y, z), r * 0.86, 0.03, "paint", "X", seg=20)
    cyl((x + s * (w * 0.5 + 0.02), y, z), r * 0.32, 0.05, "metal", "X", seg=10)
    for k in range(6):
        a = k * math.tau / 6
        cyl((x + s * (w * 0.5 + 0.03), y + math.cos(a) * r * 0.2, z + math.sin(a) * r * 0.2), 0.018, 0.03, "dark", "X", seg=6)
    # ikiz tekerin iç yarısı (arada palet kılavuzu boşluğu)
    cyl((x - s * w * 0.5, y, z), r * 0.86, 0.03, "paint", "X", seg=20)

def sprocket(x, y, z, r, w, side, teeth=11):
    cyl((x, y, z), r * 0.9, w, "metal", "X", seg=22)
    for k in range(teeth):
        a = k * math.tau / teeth
        box((x, y + math.cos(a) * r, z + math.sin(a) * r), (w * 0.6, 0.06, 0.06), "metal", rot=(a, 0, 0), bev=0.0)
    cyl((x + side * w * 0.5, y, z), r * 0.4, 0.06, "dark", "X", seg=10)

def track_loop(x, w, y_front, y_rear, r_front, r_rear, z_bottom=0.0, z_top=None, z_f=None, z_r=None, link=0.17):
    """Tek tek palet baklaları: alt düz + arka dişli yayı + üst dönüş + ön avara yayı."""
    z_f = z_f if z_f is not None else z_bottom + r_front
    z_r = z_r if z_r is not None else z_bottom + r_rear
    z_top = z_top if z_top is not None else max(z_f + r_front, z_r + r_rear) - 0.02
    # yol: noktalar dizisi (y,z)
    path = []
    def arc(cy, cz, r, a0, a1, n):
        for i in range(n + 1):
            a = a0 + (a1 - a0) * i / n
            path.append((cy + math.cos(a) * r, cz + math.sin(a) * r))
    # alt: önden arkaya
    path.append((y_front, z_bottom)); path.append((y_rear, z_bottom))
    arc(y_rear, z_r, r_rear, -math.pi / 2, -math.pi * 1.5, 10)
    path.append((y_front, z_top))
    arc(y_front, z_f, r_front, math.pi / 2, -math.pi / 2, 10)
    # yol boyunca eşit aralık
    segs = []
    tot = 0.0
    for a, b in zip(path, path[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        segs.append((a, b, L)); tot += L
    n = int(tot / link)
    step = tot / n
    d = 0.0
    si = 0; acc = 0.0
    me = bpy.data.meshes.new("trk"); bm = bmesh.new()
    for i in range(n):
        t = i * step
        while si < len(segs) - 1 and acc + segs[si][2] < t:
            acc += segs[si][2]; si += 1
        a, b, L = segs[si]
        f = (t - acc) / max(L, 1e-6)
        y = a[0] + (b[0] - a[0]) * f; z = a[1] + (b[1] - a[1]) * f
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        M = Matrix.Translation((x, y, z)) @ Matrix.Rotation(ang, 4, 'X')
        # bakla: yassı plaka + ortada kılavuz diş + iki yanda kabartı
        for (cx, cy, cz, sx, sy, sz) in ((0, 0, 0, w, link * 0.86, 0.055), (0, 0, 0.05, 0.06, link * 0.5, 0.07), (w * 0.3, 0, -0.035, w * 0.25, link * 0.5, 0.025), (-w * 0.3, 0, -0.035, w * 0.25, link * 0.5, 0.025)):
            g = bmesh.ops.create_cube(bm, size=1.0)
            vs = g["verts"]
            for v in vs:
                v.co = Vector((v.co.x * sx + cx, v.co.y * sy + cy, v.co.z * sz + cz))
                v.co = M @ v.co
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("trk", me); bpy.context.collection.objects.link(o)
    return _fin(o, "track", 0.0)

def running_gear(xc, w, wheels_y, r, y_front, y_rear, r_idler, r_spr, z_top_run=None, rollers_y=(), sprocket_rear=True):
    for s in (-1, 1):
        x = s * xc
        for y in wheels_y:
            road_wheel(x, y, r, r, w * 0.82, s)
        zi = r_idler + 0.02
        cyl((x, y_front, zi + 0.05), r_idler, w * 0.8, "paint", "X", seg=18)
        cyl((x + s * w * 0.42, y_front, zi + 0.05), r_idler * 0.35, 0.04, "metal", "X", seg=8)
        sprocket(x, y_rear, r_spr + 0.1, r_spr, w * 0.8, s)
        zt = z_top_run if z_top_run else max(zi + 0.05 + r_idler, r_spr + 0.1 + r_spr)
        for y in rollers_y:
            cyl((x, y, zt - 0.09), 0.08, w * 0.5, "metal", "X", seg=10)
        track_loop(x, w, y_front, y_rear, r_idler + 0.02, r_spr + 0.02, 0.0, zt, zi + 0.05, r_spr + 0.1)
        # süspansiyon kolları
        for y in wheels_y:
            box((s * (xc - w * 0.55), y + 0.18, r + 0.06), (0.06, 0.4, 0.08), "metal", rot=(0.35, 0, 0), bev=0.0)

# ------------------------------------------------------------ teçhizat
def hatch(x, y, z, r=0.3, open_=False):
    cyl((x, y, z + 0.03), r + 0.04, 0.06, "paint", seg=14, bev=0.01)
    cyl((x, y, z + 0.08), r, 0.05, "paint", seg=14, bev=0.01)
    box((x + r * 0.6, y, z + 0.12), (0.08, 0.12, 0.04), "metal", bev=0.0)

def periscope(x, y, z, yaw=0.0):
    box((x, y, z + 0.05), (0.16, 0.1, 0.1), "paint", rot=(0, 0, yaw), bev=0.01)
    box((x + math.sin(-yaw) * 0.05, y + math.cos(yaw) * 0.05, z + 0.06), (0.13, 0.02, 0.05), "glass", rot=(0, 0, yaw), bev=0.0)

def smoke_launchers(x, y, z, yaw, n=6, side=1):
    box((x, y, z), (0.18, 0.36, 0.22), "paint", rot=(0, 0, yaw), bev=0.015)
    for i in range(n):
        r, c = divmod(i, 3)
        oy = (c - 1) * 0.1
        oz = (r - 0.5) * 0.09
        p = Vector((0.09 * side, oy, oz))
        p.rotate(Euler((0, 0, yaw)))
        cyl((x + p.x, y + p.y, z + p.z + 0.02), 0.035, 0.18, "dark", rot=(0, math.pi / 2 + 0.35 * side, yaw), seg=8)

def mg(x, y, z, yaw=0.0, L=1.1, heavy=False):
    r = 0.04 if heavy else 0.025
    box((x, y, z), (0.12, 0.45 if heavy else 0.35, 0.14), "metal", rot=(0, 0, yaw), bev=0.01)
    dy, dx = math.cos(yaw), -math.sin(yaw)
    cyl((x + dx * (L * 0.5 + 0.2), y + dy * (L * 0.5 + 0.2), z + 0.02), r, L, "metal", rot=(math.pi / 2, 0, yaw), seg=8)
    box((x - dx * 0.05, y - dy * 0.05, z - 0.02), (0.18, 0.12, 0.14), "dark", rot=(0, 0, yaw), bev=0.0)   # şerit kutusu

def rws(x, y, z, heavy=True, low=False):
    """Uzaktan kumandalı silah istasyonu (CROWS tipi)."""
    cyl((x, y, z + 0.05), 0.22, 0.1, "paint", seg=12)
    h = 0.32 if not low else 0.22
    box((x, y, z + 0.1 + h / 2), (0.34, 0.5, h), "paint", bev=0.02)
    box((x + 0.24, y + 0.05, z + 0.12 + h * 0.6), (0.14, 0.26, 0.2), "paint", bev=0.015)        # sensör
    box((x + 0.31, y + 0.18, z + 0.12 + h * 0.6), (0.01, 0.02, 0.1), "glass", bev=0.0)
    mg(x - 0.05, y + 0.25, z + 0.1 + h * 0.6, 0.0, 1.15, heavy)
    box((x - 0.24, y, z + 0.12 + h / 2), (0.14, 0.36, 0.24), "dark", bev=0.01)              # mühimmat

def aps(x, y, z, side):
    """Aktif koruma: radar paneli + fırlatıcı."""
    box((x, y, z), (0.06, 0.42, 0.3), "paint", bev=0.015)
    box((x + side * 0.035, y, z), (0.01, 0.34, 0.22), "dark", bev=0.0)
    cyl((x, y - 0.35, z + 0.12), 0.11, 0.18, "paint", seg=10)
    box((x, y - 0.35, z + 0.25), (0.2, 0.2, 0.08), "paint", bev=0.015)

def era_grid(x0, x1, y0, y1, z0, z1, side, nx=2, ny=8, depth=0.12):
    """Reaktif zırh tuğlaları: yan yüzeyde (x sabit) y-z ızgarası."""
    for j in range(ny):
        for i in range(nx):
            y = y0 + (y1 - y0) * (j + 0.5) / ny
            z = z0 + (z1 - z0) * (i + 0.5) / nx
            box((x0, y, z), (depth, (y1 - y0) / ny * 0.92, (z1 - z0) / nx * 0.9), "paint", bev=0.01)

def jerrycan(x, y, z, yaw=0.0):
    box((x, y, z), (0.17, 0.35, 0.47), "paint", rot=(0, 0, yaw), bev=0.02)

def bag(x, y, z, sx, sy, sz):
    box((x, y, z), (sx, sy, sz), "canvas", bev=min(sx, sy, sz) * 0.3)

def antenna(x, y, z, h=2.2):
    cyl((x, y, z + 0.05), 0.05, 0.1, "dark", seg=8)
    cyl((x, y, z + h / 2), 0.008, h, "dark", seg=4)

def light(x, y, z):
    box((x, y, z), (0.2, 0.12, 0.14), "paint", bev=0.01)
    box((x, y + 0.065, z), (0.15, 0.01, 0.09), "light", bev=0.0)

def grille(x, y, z, w, L, n):
    box((x, y, z), (w, L, 0.04), "dark", bev=0.0)
    for i in range(n):
        box((x, y - L / 2 + (i + 0.5) * L / n, z + 0.03), (w * 0.96, L / n * 0.4, 0.03), "paint", bev=0.0)

# ------------------------------------------------------------ dışa aktarım
def export(path_glb, pivots, meta):
    import json
    for name, obs in NODES.items():
        if not obs:
            continue
        for o in obs:
            bpy.context.view_layer.objects.active = o
            for m in list(o.modifiers):
                bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.ops.object.select_all(action='DESELECT')
        for o in obs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = obs[0]
        bpy.ops.object.join()
        j = bpy.context.active_object
        j.name = name
        j.data.name = name
        bpy.context.scene.cursor.location = pivots.get(name, (0, 0, 0))
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.ops.object.shade_flat()
        # UV (dokular dünya izdüşümüyle de çalışır) + beyaz tepe rengi
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.cube_project(cube_size=4.0)
        bpy.ops.object.mode_set(mode='OBJECT')
        ca = j.data.color_attributes.new("Col", 'BYTE_COLOR', 'CORNER')
        for d in ca.data:
            d.color = (1, 1, 1, 1)
    bpy.ops.export_scene.gltf(filepath=path_glb, export_format='GLB', export_yup=True, export_apply=True)
    def g(p):  # Blender → Godot (x, z, -y)
        return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    js = {"pivots": {k: g(v) for k, v in pivots.items()}, "meta": {k: (g(v) if isinstance(v, (tuple, list)) and len(v) == 3 else v) for k, v in meta.items()}}
    with open(path_glb[:-4] + ".json", "w") as f:
        json.dump(js, f)
    tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == 'MESH' for p in o.data.polygons)
    print("EXPORT", path_glb, "tris", tris)
