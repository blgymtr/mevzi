#!/usr/bin/env python3
# MEVZİ — gerçekçi asker modeli (Roadmap 1 / 17):
#   MakeHuman CC0 gövde (baş, boyun, eller) + MakeHuman CC0 sistem kıyafetleri (mhclo ile gövdeye oturtulur:
#   üst + pantolon + bot) + katmanlı teçhizat (kask, plaka taşıyıcı, cepler, kemer, çanta, dizlik...)
#   → oyunun 10 kemikli iskeletine (pelvis/spine/arm_r/fore_r/arm_l/fore_l/leg_r/knee_r/leg_l/knee_l)
#   derili TEK örgü, TEK yüzey (tek çizim çağrısı): malzeme kimliği UV2.x'te, kıvrım gölgesi (AO) köşe renginde.
#
# Kullanım (proje kökünden):
#   blender -b --factory-startup -P tools/anim/build_soldier.py -- --nation usa
#   blender -b --factory-startup -P tools/anim/build_soldier.py -- --nation rus --preview shots/soldier_rus.png
# Çıktı: assets/models/soldier_<ulus>_rig.glb (+ .json bilgi) ve assets/models/soldier_<ulus>_fold_n.png
#   (kıyafet kıvrım normali; shaders/soldier.gdshader kullanır)
#
# Eksenler (Blender): Z yukarı, +Y ileri (glTF/Godot'ta -Z), anatomik sağ +X. Oyundaki gövde de böyle:
# arm_r/leg_r +X'te (soldier_body.gd pozları ayna uzayında yazılıdır, uygularken X'e göre aynalanır).
# Kaynaklar tools/anim/.cache altına indirilir (git'e girmez): MakeHuman deposu (sabit işleme) ve
# MakeHuman sistem varlık paketi (CC0, sha256 doğrulamalı).
import argparse
import hashlib
import json
import math
import os
import subprocess
import sys
import zipfile

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import build_anims as ba  # noqa: E402
import mh  # noqa: E402

SYS_URL = "https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip"
SYS_SHA = "b542127a8e25547c7c29c19f2d1d2adb9a664c80396ecd694095dbc8028a0107"
SYS_ZIP = os.path.join(ba.CACHE, "mhsys", "makehuman_system_assets_cc0.zip")
SYS_DIR = os.path.join(ba.CACHE, "mhsys", "x")
MHD = "makehuman/data/"

# ------------------------------------------------------------------ oyun iskeleti (soldier_body.gd ile aynı)
HIP = 0.92            # kalça eklemi / pelvis
SH_X, SH_Z = 0.19, 1.38    # omuz eklemi (kollar gevşek sarkarken; MakeHuman ölçüsü)
UPPER = 0.26          # omuz → dirsek
GRIP = 0.33           # dirsek → avuç (kabza) noktası (soldier_body.gd HAND_LEN)
LEG_X = 0.10
THIGH = 0.40          # kalça → diz
SHIN = 0.52           # diz → taban
GAME_BONES = ["pelvis", "spine", "arm_r", "fore_r", "arm_l", "fore_l", "leg_r", "knee_r", "leg_l", "knee_l"]

# ulusa göre: kıyafet, bot, etnik karışım
NATION = {
	"usa": dict(suit="male_casualsuit02", boots="shoes03", mix={"african": 0.3, "asian": 0.2, "caucasian": 0.5},
		skin="young_caucasian_male", blouse=True),
	"rus": dict(suit="male_casualsuit05", boots="shoes03", mix={"caucasian": 0.85, "asian": 0.15},
		skin="young_caucasian_male", blouse=True),
}

# malzeme kimlikleri (UV2.x) — shaders/soldier.gdshader ile aynı sıra
MAT_ID = {"uniform": 0, "vest": 1, "pack": 2, "helmet": 3, "boot": 4, "glove": 5, "skin": 6, "dark": 7,
	"gun": 8, "team": 9, "lens": 10, "red": 11, "rubber": 12, "canvas": 13, "eye": 14, "strap": 15}
# önizleme renkleri (doğrusal değil, kabaca)
PREV_COL = {"uniform": (0.45, 0.43, 0.32), "vest": (0.55, 0.47, 0.33), "pack": (0.5, 0.43, 0.3), "helmet": (0.52, 0.46, 0.33),
	"boot": (0.5, 0.4, 0.28), "glove": (0.33, 0.28, 0.2), "skin": (0.78, 0.6, 0.48), "dark": (0.1, 0.1, 0.1),
	"gun": (0.2, 0.2, 0.21), "team": (0.2, 0.45, 0.9), "lens": (0.9, 0.5, 0.1), "red": (0.8, 0.1, 0.1),
	"rubber": (0.08, 0.08, 0.08), "canvas": (0.6, 0.56, 0.42), "eye": (0.9, 0.9, 0.88), "strap": (0.3, 0.27, 0.2)}
CAMO_TILE = 0.55      # kamuflaj dokusunun bir tekrarı (m)
TWIST = 1.0           # ön kol çevirme (1: avuç arkadan içe, 90°)
CLAV = 0.35           # kolu indirme açısının köprücük kemiğine düşen payı
DEC_SKIN = 0.28       # baş + eller inceltme oranı
DEC_BOOT = 0.45


def cp(rel):
	return os.path.join(ba.CACHE, rel)


def sp(rel):
	return os.path.join(SYS_DIR, rel)


# ------------------------------------------------------------------ kaynaklar
def fetch_sys(prefixes):
	os.makedirs(os.path.dirname(SYS_ZIP), exist_ok=True)
	if not os.path.exists(SYS_ZIP):
		print("indiriliyor:", SYS_URL)
		subprocess.run(["curl", "-sSfL", "--retry", "3", "-o", SYS_ZIP + ".part", SYS_URL], check=True)
		os.replace(SYS_ZIP + ".part", SYS_ZIP)
	h = hashlib.sha256()
	with open(SYS_ZIP, "rb") as f:
		for blk in iter(lambda: f.read(1 << 20), b""):
			h.update(blk)
	if h.hexdigest() != SYS_SHA:
		raise SystemExit("sistem varlık paketi sha256 uyuşmuyor: " + h.hexdigest())
	with zipfile.ZipFile(SYS_ZIP) as z:
		for n in z.namelist():
			if n.endswith("/") or not any(n.startswith(p) for p in prefixes):
				continue
			dst = sp(n)
			if os.path.exists(dst) and os.path.getsize(dst) > 0:
				continue
			os.makedirs(os.path.dirname(dst), exist_ok=True)
			with z.open(n) as src, open(dst, "wb") as out:
				out.write(src.read())


# ------------------------------------------------------------------ insan
def human(nat):
	base = mh.BaseMesh(cp(MHD + "3dobjs/base.obj"))
	T = MHD + "targets/macrodetails/"
	for r, w in NATION[nat]["mix"].items():
		base.apply_target(cp(T + r + "-male-young.target"), w)
	base.apply_target(cp(T + "universal-male-young-maxmuscle-averageweight.target"), 0.4)
	base.apply_target(cp(T + "height/male-young-averagemuscle-averageweight-maxheight.target"), 0.15)
	base.apply_target(cp(T + "proportions/male-young-averagemuscle-averageweight-idealproportions.target"), 0.5)
	sk = mh.Skeleton(cp(MHD + "rigs/default.mhskel"))
	return base, sk


class Frame:
	"""MakeHuman (dm, Y yukarı) → B (m, Z yukarı, +Y ileri): kalça eklemi HIP yüksekliğinde, taban z=0."""
	def __init__(self, base, sk):
		vb = base.to_b()
		body_v = np.array(sorted({v for g, c in base.faces if g == "body" for v, t in c}))
		floor = vb[body_v, 2].min()
		hip = 0.25 * (sk.head(vb, "upperleg01.L") + sk.head(vb, "upperleg02.L") + sk.head(vb, "upperleg01.R") + sk.head(vb, "upperleg02.R"))
		self.off = np.array([0.0, hip[1], floor])
		self.s = HIP / (hip[2] - floor)

	def __call__(self, pts_mh):
		return ((np.asarray(pts_mh) @ mh.C.T) * 0.1 - self.off) * self.s


def base_weights(nv):
	W = mh.load_weights(cp(MHD + "rigs/default_weights.mhw"))
	acc = [dict() for _ in range(nv)]
	for mb, lst in W.items():
		m = ba.weight_map(mb)
		for vi, w in lst:
			d = acc[vi]
			for tb, k in m.items():
				d[tb] = d.get(tb, 0.0) + w * k
	return acc


def norm_w(d, top=4):
	it = sorted(((b, w) for b, w in d.items() if w > 0.0), key=lambda kv: -kv[1])[:top]
	s = sum(w for _, w in it)
	if s <= 0.0:
		return {"Hips": 1.0}
	return {b: w / s for b, w in it if w / s > 0.01}


# ------------------------------------------------------------------ kıyafet (mhclo)
class Clo:
	def __init__(self, folder, name):
		self.dir = sp("clothes/%s/" % folder)
		self.refs, self.wts, self.offs = [], [], []
		self.scales = {}
		self.delete = set()
		mode = None
		with open(os.path.join(self.dir, name + ".mhclo")) as f:
			for line in f:
				s = line.strip()
				if not s or s[0] == "#":
					continue
				p = s.split()
				if p[0] in ("x_scale", "y_scale", "z_scale"):
					self.scales["xyz".index(p[0][0])] = (int(p[1]), int(p[2]), float(p[3]))
					continue
				if p[0] == "verts":
					mode = "v"
					continue
				if p[0] == "delete_verts":
					mode = "d"
					continue
				if not p[0][0].isdigit():
					mode = None     # başka bir anahtar sözcük
					continue
				if mode == "v":
					if len(p) == 1:
						self.refs.append((int(p[0]),) * 3)
						self.wts.append((1.0, 0.0, 0.0))
						self.offs.append((0.0, 0.0, 0.0))
					else:
						self.refs.append(tuple(int(x) for x in p[0:3]))
						self.wts.append(tuple(float(x) for x in p[3:6]))
						self.offs.append(tuple(float(x) for x in p[6:9]))
				elif mode == "d":
					i = 0
					while i < len(p):
						if i + 2 < len(p) and p[i + 1] == "-":
							self.delete.update(range(int(p[i]), int(p[i + 2]) + 1))
							i += 3
						else:
							self.delete.add(int(p[i]))
							i += 1
		self.mesh = mh.BaseMesh(os.path.join(self.dir, name + ".obj"))
		self.refs = np.array(self.refs)
		self.wts = np.array(self.wts)
		self.offs = np.array(self.offs)
		assert len(self.refs) == len(self.mesh.v), (name, len(self.refs), len(self.mesh.v))

	def fit(self, vmh):
		sc = np.ones(3)
		for i, (v1, v2, den) in self.scales.items():
			sc[i] = abs(vmh[v1][i] - vmh[v2][i]) / den
		r, w = self.refs, self.wts
		return vmh[r[:, 0]] * w[:, 0, None] + vmh[r[:, 1]] * w[:, 1, None] + vmh[r[:, 2]] * w[:, 2, None] + self.offs * sc

	def weights(self, bw):
		out = []
		for r, w in zip(self.refs, self.wts):
			d = {}
			for k in range(3):
				if w[k] == 0.0:
					continue
				for b, x in bw[r[k]].items():
					d[b] = d.get(b, 0.0) + x * w[k]
			out.append(norm_w(d))
		return out


# ------------------------------------------------------------------ doku örnekleme (Blender görüntüsü)
def load_img(bpy, path):
	img = bpy.data.images.load(path, check_existing=True)
	w, h = img.size
	px = np.empty(w * h * img.channels, np.float32)
	img.pixels.foreach_get(px)
	return img, px.reshape(h, w, img.channels)


def sample(px, uv):
	h, w = px.shape[0], px.shape[1]
	x = np.clip(np.asarray(uv)[:, 0] % 1.0 * (w - 1), 0, w - 1).astype(int)
	y = np.clip(np.asarray(uv)[:, 1] % 1.0 * (h - 1), 0, h - 1).astype(int)
	return px[y, x, :3]


def uv_density(v, faces_vt, vt):
	"""kıyafet UV atlasında 1 UV birimi kaç metre (kenar oranlarının medyanı)"""
	rs = []
	for cc in faces_vt:
		for k in range(len(cc)):
			a, ta = cc[k]
			b, tb = cc[(k + 1) % len(cc)]
			if ta < 0 or tb < 0:
				continue
			d3 = np.linalg.norm(v[a] - v[b])
			d2 = np.linalg.norm(vt[ta] - vt[tb])
			if d2 > 1e-6 and d3 > 1e-5:
				rs.append(d3 / d2)
	return float(np.median(rs))


# ------------------------------------------------------------------ Blender yardımcıları
class B:
	bpy = None
	scn = None
	mats = {}


def mat(name):
	if name not in B.mats:
		m = B.bpy.data.materials.new(name)
		c = PREV_COL.get(name, (0.5, 0.5, 0.5))
		m.diffuse_color = (c[0], c[1], c[2], 1.0)
		B.mats[name] = m
	return B.mats[name]


def make_obj(name, verts, polys, mats, face_mat, uv=None, col=None, weights=None):
	"""verts Nx3, polys: köşe dizinleri listesi, face_mat: yüz başına malzeme adı,
	uv/col: köşe (loop) başına liste (polys sırasıyla), weights: köşe başına {kemik: ağırlık}"""
	bpy = B.bpy
	me = bpy.data.meshes.new(name)
	me.from_pydata(np.asarray(verts, float).tolist(), [], [list(p) for p in polys])
	me.update()
	for m in mats:
		me.materials.append(mat(m))
	me.polygons.foreach_set("material_index", [mats.index(m) for m in face_mat])
	nl = len(me.loops)
	ul = me.uv_layers.new(name="UVMap")
	if uv is not None:
		ul.data.foreach_set("uv", np.asarray(uv, np.float32).reshape(-1)[:nl * 2])
	me.uv_layers.new(name="ID")
	ca = me.color_attributes.new("Col", 'BYTE_COLOR', 'CORNER')
	c = np.ones((nl, 4), np.float32)
	if col is not None:
		c[:, :3] = np.asarray(col, np.float32).reshape(-1, 3)[:nl]
	ca.data.foreach_set("color", c.reshape(-1))
	ob = bpy.data.objects.new(name, me)
	B.scn.collection.objects.link(ob)
	if weights is not None:
		set_weights(ob, weights)
	return ob


def obj_coords(ob):
	n = len(ob.data.vertices)
	a = np.empty(n * 3, np.float64)
	ob.data.vertices.foreach_get("co", a)
	return a.reshape(n, 3)


def set_coords(ob, co):
	ob.data.vertices.foreach_set("co", np.asarray(co, np.float64).reshape(-1))
	ob.data.update()


def obj_weights(ob):
	names = [g.name for g in ob.vertex_groups]
	out = []
	for v in ob.data.vertices:
		out.append({names[g.group]: g.weight for g in v.groups if g.weight > 0.0})
	return out


def set_weights(ob, weights):
	for g in list(ob.vertex_groups):
		ob.vertex_groups.remove(g)
	groups = {}
	for vi, d in enumerate(weights):
		for bn, w in d.items():
			g = groups.get(bn)
			if g is None:
				g = groups[bn] = ob.vertex_groups.new(name=bn)
			g.add([vi], float(w), 'REPLACE')


def apply_mods(ob):
	bpy = B.bpy
	for m in list(ob.modifiers):
		with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob], selected_editable_objects=[ob]):
			bpy.ops.object.modifier_apply(modifier=m.name)


def game_bone(hb):
	"""insansı kemik adı → oyun kemiği (anatomik sağ = oyunda _r, +X)"""
	if hb in ("Root", "Hips"):
		return "pelvis"
	if hb in ("Spine", "Chest", "UpperChest", "Neck", "Head", "LeftShoulder", "RightShoulder"):
		return "spine"
	side = "r" if hb.startswith("Right") else "l"
	b = hb[5:] if side == "r" else hb[4:]
	if b == "UpperArm":
		return "arm_" + side
	if b in ("LowerArm", "Hand") or b in ba.FINGERS:
		return "fore_" + side
	if b == "UpperLeg":
		return "leg_" + side
	return "knee_" + side


def merge_game(d):
	out = {}
	for b, w in d.items():
		g = b if b in GAME_BONES else game_bone(b)
		out[g] = out.get(g, 0.0) + w
	return norm_w(out)


# ------------------------------------------------------------------ duruş: MakeHuman A-pozu → oyunun dinlenme pozu
def repose(ao, palm, objs):
	"""parmaklar kabza tutuşuna kıvrılır; kollar ve bacaklar dikey (oyunda tüm pivot dönüşleri 0 iken
	kollar ve bacaklar dümdüz aşağı). DQS (hacim koruyan) deri ile uygulanır, sonra dinlenme örgüsü olur."""
	bpy = B.bpy
	from mathutils import Matrix, Vector
	bpy.context.view_layer.objects.active = ao
	bpy.ops.object.mode_set(mode='POSE')
	P = ao.pose.bones

	def upd():
		bpy.context.view_layer.update()

	def rot(name, R):
		pb = P[name]
		M = pb.matrix.copy()
		h = M.translation.copy()
		pb.matrix = Matrix.Translation(h) @ R.to_4x4() @ Matrix.Translation(-h) @ M
		upd()

	def bdir(name):
		pb = P[name]
		return (pb.tail - pb.head).normalized()

	def align(name, target):
		d = bdir(name)
		rot(name, d.rotation_difference(Vector(target)).to_matrix())

	down = (0.0, 0.0, -1.0)
	for S in ("Left", "Right"):
		# kolu indirmenin bir kısmı köprücük kemiğinde (omuz düşer, omuz başı şişmez)
		d = bdir(S + "UpperArm")
		q = d.rotation_difference(Vector(down))
		ax, ang = q.to_axis_angle()
		rot(S + "Shoulder", Matrix.Rotation(ang * CLAV, 3, ax))
		align(S + "UpperArm", down)
		align(S + "LowerArm", down)
		align(S + "Hand", tuple(bdir(S + "LowerArm")))
		# ön kol nötr: avuç içe (uyluğa) bakar, başparmak önde — çevirme ön kol ve bilek arasında bölünür
		tw = -0.5 * math.pi * (1.0 if S == "Right" else -1.0) * TWIST
		rot(S + "LowerArm", Matrix.Rotation(tw * 0.5, 3, Vector(down)))
		rot(S + "Hand", Matrix.Rotation(tw * 0.5, 3, Vector(down)))
		fr = P[S + "Foot"].bone.matrix_local.copy()   # ayak tabanı dünyada aynı kalsın
		align(S + "UpperLeg", down)
		align(S + "LowerLeg", down)
		pb = P[S + "Foot"]
		M = fr.copy()
		M.translation = pb.matrix.translation.copy()
		pb.matrix = M
		upd()
	J = {pb.name: (np.array(pb.head), np.array(pb.tail)) for pb in P}
	bpy.ops.object.mode_set(mode='OBJECT')
	for ob in objs:
		apply_mods(ob)
	return J


def retarget(J, objs):
	"""dinlenme pozundaki eklemleri oyun iskeletinin eklemlerine taşı (kemik başına öteleme + kemik ekseninde
	ölçek; oyun kemiği ağırlıklarıyla harmanlanır)"""
	hipc = 0.5 * (J["LeftUpperLeg"][0] + J["RightUpperLeg"][0])
	A = {}
	sh_z = 0.5 * (J["LeftUpperArm"][0][2] + J["RightUpperArm"][0][2])
	k_sp = 1.0     # gövde boyu korunur; omuz yüksekliği iskeletle zaten uyumlu (bkz. json: shoulder)
	A["pelvis"] = (hipc, np.array([0.0, 0.0, HIP]), np.array([1.0, 1.0, 1.0]))
	A["spine"] = (hipc, np.array([0.0, 0.0, HIP]), np.array([1.0, 1.0, k_sp]))
	info = {"k_spine": round(float(k_sp), 3)}
	for S, s, sx in (("Right", "r", 1.0), ("Left", "l", -1.0)):
		sh = J[S + "UpperArm"][0]
		el = J[S + "LowerArm"][0]
		wr = J[S + "Hand"][0]
		kn = J[S + "Hand"][1]
		grip = wr + 0.5 * (kn - wr)
		ku = UPPER / (sh[2] - el[2])
		kf = GRIP / (el[2] - grip[2])
		A["arm_" + s] = (sh, np.array([sx * SH_X, 0.0, SH_Z]), np.array([1.0, 1.0, ku]))
		A["fore_" + s] = (el, np.array([sx * SH_X, 0.0, SH_Z - UPPER]), np.array([1.0, 1.0, kf]))
		hp = J[S + "UpperLeg"][0]
		kq = J[S + "LowerLeg"][0]
		kt = THIGH / (hp[2] - kq[2])
		ks = SHIN / kq[2]
		A["leg_" + s] = (hp, np.array([sx * LEG_X, 0.0, HIP]), np.array([1.0, 1.0, kt]))
		A["knee_" + s] = (kq, np.array([sx * LEG_X, 0.0, HIP - THIGH]), np.array([1.0, 1.0, ks]))
		info[S] = dict(shoulder=np.round(sh, 3).tolist(), elbow=np.round(el, 3).tolist(), grip=np.round(grip, 3).tolist(),
			hip=np.round(hp, 3).tolist(), knee=np.round(kq, 3).tolist(), k_upper=round(float(ku), 3), k_fore=round(float(kf), 3),
			k_thigh=round(float(kt), 3), k_shin=round(float(ks), 3))
	for ob in objs:
		co = obj_coords(ob)
		W = obj_weights(ob)
		out = np.zeros_like(co)
		for i, d in enumerate(W):
			acc = np.zeros(3)
			tot = 0.0
			for b, w in d.items():
				o, t, k = A[b]
				acc += w * (t + k * (co[i] - o))
				tot += w
			out[i] = acc / tot if tot > 0 else co[i]
		set_coords(ob, out)
	return info


def game_armature():
	bpy = B.bpy
	arm = bpy.data.armatures.new("rig")
	ao = bpy.data.objects.new("rig", arm)
	B.scn.collection.objects.link(ao)
	bpy.context.view_layer.objects.active = ao
	bpy.ops.object.mode_set(mode='EDIT')
	eb = arm.edit_bones

	def bone(n, h, t, p=None):
		b = eb.new(n)
		b.head = h
		b.tail = t
		b.roll = 0.0
		if p:
			b.parent = eb[p]
	bone("pelvis", (0, 0, HIP), (0, 0, HIP + 0.08))
	bone("spine", (0, 0, HIP), (0, 0, 1.5), "pelvis")
	for s, x in (("r", SH_X), ("l", -SH_X)):
		bone("arm_" + s, (x, 0, SH_Z), (x, 0, SH_Z - UPPER), "spine")
		bone("fore_" + s, (x, 0, SH_Z - UPPER), (x, 0, SH_Z - UPPER - GRIP), "arm_" + s)
	for s, x in (("r", LEG_X), ("l", -LEG_X)):
		bone("leg_" + s, (x, 0, HIP), (x, 0, HIP - THIGH), "pelvis")
		bone("knee_" + s, (x, 0, HIP - THIGH), (x, 0.03, 0.0), "leg_" + s)
	bpy.ops.object.mode_set(mode='OBJECT')
	return ao


# ------------------------------------------------------------------ parmaklar: kabza tutuşu
# MakeHuman'ın parmak başına 3 boğumlu kemikleriyle (dinlenme örgüsünde, numpy DDS/LBS). Her parmak kendi
# eklem merkezlerinde, avuç normaline doğru kıvrılır. Sağ el kabzada (işaret parmağı tetik boyunca hafif kıvrık),
# sol el el kundağını kavrar. (proksimal, orta, uç boğum) radyan; 1 = başparmak
FINGER_CURL = {
	"R": {1: (0.15, 0.4, 0.3), 2: (0.35, 0.35, 0.2), 3: (1.15, 1.25, 0.75), 4: (1.2, 1.3, 0.75), 5: (1.25, 1.25, 0.75)},
	"L": {1: (0.2, 0.35, 0.25), 2: (0.85, 0.95, 0.55), 3: (0.95, 1.0, 0.55), 4: (1.0, 1.05, 0.55), 5: (1.05, 1.05, 0.55)},
}


def rotm(ax, a):
	ax = ax / np.linalg.norm(ax)
	x, y, z = ax
	c, s = math.cos(a), math.sin(a)
	C = 1.0 - c
	return np.array([[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
		[y * x * C + z * s, c + y * y * C, y * z * C - x * s],
		[z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


def curl_fingers(vb, sk, palm):
	W = mh.load_weights(cp(MHD + "rigs/default_weights.mhw"))
	out = vb.copy()
	for s, S in (("L", "Left"), ("R", "Right")):
		n = palm[S]
		for f, angs in FINGER_CURL[s].items():
			b0 = "finger%d-1.%s" % (f, s)
			d0 = sk.tail(vb, b0) - sk.head(vb, b0)
			ax = np.cross(d0 / np.linalg.norm(d0), n)
			if np.linalg.norm(ax) < 1e-4:
				continue
			Rc = np.eye(3)
			tc = np.zeros(3)
			for k, a in enumerate(angs):
				bn = "finger%d-%d.%s" % (f, k + 1, s)
				h = Rc @ sk.head(vb, bn) + tc
				Rk = rotm(ax, a)
				Rc = Rk @ Rc
				tc = Rk @ (tc - h) + h
				for vi, w in W.get(bn, []):
					out[vi] += w * ((Rc @ vb[vi] + tc) - vb[vi])
	return out


# ------------------------------------------------------------------ gövde + kıyafet parçaları
def dominant(d):
	return max(d.items(), key=lambda kv: kv[1])[0] if d else "Hips"


def compact(verts, polys):
	used = sorted({v for p in polys for v in p})
	idx = {v: i for i, v in enumerate(used)}
	return np.asarray(verts)[used], [[idx[v] for v in p] for p in polys], used


def body_parts(cfg, base, F, vb, bw, info):
	bpy = B.bpy
	vmh = base.v
	suit = Clo(cfg["suit"], cfg["suit"])
	boots = Clo(cfg["boots"], cfg["boots"])
	dele = suit.delete | boots.delete
	objs = []

	# --- gövdenin görünen kısımları (baş, boyun, eller) + gözler
	faces = []
	for g, cc in base.faces:
		if g == "body":
			if any(v in dele for v, t in cc):
				continue
			faces.append(("body", cc))
		elif g in ("helper-l-eye", "helper-r-eye"):
			faces.append((g, cc))
	polys = [[v for v, t in cc] for g, cc in faces]
	verts, polys, used = compact(vb, polys)
	W = [norm_w(bw[v]) for v in used]
	uvs = np.array([base.vt[t] if t >= 0 else (0.0, 0.0) for g, cc in faces for v, t in cc])
	fm = []
	for g, cc in faces:
		if g != "body":
			fm.append("eye")
			continue
		sc = {}
		for v, t in cc:
			for b, w in bw[v].items():
				sc[b] = sc.get(b, 0.0) + w
		dom = dominant(sc)
		fm.append("glove" if dom.endswith("Hand") or any(dom.endswith(f) for f in ba.FINGERS) else "skin")
	# ten: MakeHuman ten dokusu köşe rengine (kaş, dudak, sakal gölgesi), ortanca tene göre oran
	sdir = sp("skins/%s/" % cfg["skin"])
	png = [f for f in os.listdir(sdir) if f.endswith(".png") and "diffuse" in f][0]
	_, px = load_img(bpy, os.path.join(sdir, png))
	rgb = sample(px, uvs)
	corner_mat = np.array([m for m, (g, cc) in zip(fm, faces) for _ in cc])
	sk = corner_mat == "skin"
	med = np.median(rgb[sk], axis=0)
	col = np.clip(rgb / np.maximum(med, 1e-3), 0.45, 1.25)
	col[corner_mat == "glove"] = 1.0
	# gözler: beyaz sklera, kahverengi iris, siyah gözbebeği (ileri yönde)
	corner_v = np.array([v for g, cc in faces for v, t in cc])
	for eg in ("helper-l-eye", "helper-r-eye"):
		ev = sorted({v for g, cc in faces if g == eg for v, t in cc})
		if not ev:
			continue
		c = vb[ev].mean(axis=0)
		r = np.linalg.norm(vb[ev] - c, axis=1).max()
		m = np.array([g == eg for g, cc in faces for _ in cc])
		fwd = (vb[corner_v[m], 1] - c[1]) / r
		e = np.full((m.sum(), 3), 0.92)
		e[fwd > 0.72] = (0.3, 0.2, 0.12)
		e[fwd > 0.93] = (0.04, 0.035, 0.03)
		col[m] = e
	objs.append(make_obj("skin", verts, polys, ["skin", "glove", "eye"], fm, uv=np.zeros((len(uvs), 2)), col=col, weights=W))

	# --- botlar
	bv = F(boots.fit(vmh))
	boot_top = float(bv[:, 2].max())
	bf = boots.mesh.faces
	bpol = [[v for v, t in cc] for g, cc in bf]
	buv = np.array([boots.mesh.vt[t] for g, cc in bf for v, t in cc])
	dens_b = uv_density(bv, [cc for g, cc in bf], boots.mesh.vt)
	bdir = boots.dir
	png = [f for f in os.listdir(bdir) if f.endswith("_diffuse.png")][0]
	_, px = load_img(bpy, os.path.join(bdir, png))
	# ayakkabı + çorap konçu tek parça: çorap kısmı deri konç olur (≈24 cm, 8 inç bot); taban dışa
	# taşırılıp kauçuk olur (kalın dişli taban görünümü, ayak yerden kalkmaz)
	lum = sample(px, buv) @ np.array([0.3, 0.59, 0.11])
	sock = lum > 0.42
	med = float(np.median(lum[~sock])) if (~sock).any() else 0.25
	bl = np.where(sock, 0.9, np.clip(lum / max(med, 1e-3), 0.55, 1.25))
	bcol = np.repeat(bl[:, None], 3, axis=1)
	for sx in (1.0, -1.0):
		m = (bv[:, 0] * sx > 0) & (bv[:, 2] < 0.035)
		if not m.any():
			continue
		c = bv[m][:, :2].mean(axis=0)
		d = bv[m][:, :2] - c
		L = np.maximum(np.linalg.norm(d, axis=1, keepdims=True), 1e-4)
		bv[np.where(m)[0], :2] += d / L * (0.006 * (1.0 - bv[m][:, 2] / 0.035))[:, None]
	bfm = ["rubber" if np.mean([bv[v, 2] for v in p]) < 0.022 else "boot" for p in bpol]
	objs.append(make_obj("boots", bv, bpol, ["boot", "rubber"], bfm, uv=buv * (dens_b / 0.25), col=bcol, weights=boots.weights(bw)))

	# --- üniforma (üst + pantolon); pantolon paçası bot konçuna sokulur (konç üstünden 2,5 cm içeride biter)
	sv = F(suit.fit(vmh))
	sw = suit.weights(bw)
	sf = suit.mesh.faces
	keep = []
	for g, cc in sf:
		vs = [v for v, t in cc]
		low = all(sv[v, 2] < boot_top - 0.025 for v in vs)
		leg = any(dominant(sw[v]).endswith(("LowerLeg", "Foot", "Toes")) for v in vs)
		if not (low and leg):
			keep.append(cc)
	spol = [[v for v, t in cc] for cc in keep]
	suv = np.array([suit.mesh.vt[t] for cc in keep for v, t in cc])
	dens = uv_density(sv, keep, suit.mesh.vt)
	_, px = load_img(bpy, os.path.join(suit.dir, cfg["suit"] + "_ao.png"))
	ao = sample(px, suv)[:, 0]
	scol = np.repeat((0.32 + 0.68 * ao)[:, None], 3, axis=1)
	verts, spol, used = compact(sv, spol)
	objs.append(make_obj("uniform", verts, spol, ["uniform"], ["uniform"] * len(spol), uv=suv, col=scol, weights=[sw[v] for v in used]))
	info.update(boot_top=round(boot_top, 3), suit_m_per_uv=round(dens, 3), boot_m_per_uv=round(dens_b, 3))
	# kıyafetin kıvrım normal haritası (4096²) → 1024² oyun dokusu
	img = bpy.data.images.load(os.path.join(suit.dir, cfg["suit"] + "_normal.png"))
	img.scale(1024, 1024)
	fold = os.path.join(ROOT, "assets/models/soldier_%s_fold_n.png" % info["nation"])
	img.filepath_raw = fold
	img.file_format = 'PNG'
	img.save()
	info["fold_normal"] = os.path.basename(fold)
	return objs, dens / CAMO_TILE


# ------------------------------------------------------------------ birleştirme, tek malzeme, dışa aktarım
def finalize(objs, rig, preview_path):
	bpy = B.bpy
	for o in bpy.context.selected_objects:
		o.select_set(False)
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.join()
	body = bpy.context.view_layer.objects.active
	body.name = "body"
	body.data.name = "body"
	me = body.data
	names = [m.name.split(".")[0] for m in me.materials]
	np_ = len(me.polygons)
	mi = np.empty(np_, np.int32)
	me.polygons.foreach_get("material_index", mi)
	ls = np.empty(np_, np.int32)
	lt = np.empty(np_, np.int32)
	me.polygons.foreach_get("loop_start", ls)
	me.polygons.foreach_get("loop_total", lt)
	nl = len(me.loops)
	loop_mat = np.empty(nl, np.int32)
	for p in range(np_):
		loop_mat[ls[p]:ls[p] + lt[p]] = mi[p]
	ids = np.array([MAT_ID[n] for n in names], np.float32)[loop_mat]
	idu = np.zeros((nl, 2), np.float32)
	idu[:, 0] = ids
	me.uv_layers["ID"].data.foreach_set("uv", idu.reshape(-1))
	me.uv_layers.active = me.uv_layers["UVMap"]
	if preview_path:
		col = np.empty(nl * 4, np.float32)
		me.color_attributes["Col"].data.foreach_get("color", col)
		col = col.reshape(nl, 4)
		pc = np.array([PREV_COL[n] for n in names], np.float32)[loop_mat]
		pv = me.color_attributes.new("Prev", 'FLOAT_COLOR', 'CORNER')
		out = np.ones((nl, 4), np.float32)
		out[:, :3] = pc * col[:, :3]
		pv.data.foreach_set("color", out.reshape(-1))
		me.color_attributes.active_color = pv
		render_preview(body, preview_path)
		me.color_attributes.remove(me.color_attributes["Prev"])
		me.color_attributes.active_color = me.color_attributes["Col"]
	me.materials.clear()
	sm = bpy.data.materials.new("soldier")
	me.materials.append(sm)
	bpy.context.view_layer.objects.active = body
	bpy.ops.object.shade_smooth()
	body.parent = rig
	am = body.modifiers.new("rig", 'ARMATURE')
	am.object = rig
	return body


def render_preview(body, path):
	bpy = B.bpy
	scn = B.scn
	scn.render.engine = 'BLENDER_WORKBENCH'
	sh = scn.display.shading
	sh.light = 'STUDIO'
	sh.color_type = 'VERTEX'
	sh.show_shadows = True
	sh.show_cavity = True
	scn.render.resolution_x = 420
	scn.render.resolution_y = 860
	scn.render.film_transparent = False
	if scn.world is None:
		scn.world = bpy.data.worlds.new("w")
	scn.world.color = (0.62, 0.64, 0.66)
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	scn.collection.objects.link(cam)
	scn.camera = cam
	cam.data.type = 'ORTHO'
	views = [((0, 5, 0.93), (math.pi / 2, 0, math.pi), 1.95), ((5, 0, 0.93), (math.pi / 2, 0, math.pi / 2), 1.95),
		((0, -5, 0.93), (math.pi / 2, 0, 0), 1.95), ((3.6, 3.6, 0.93), (math.pi / 2, 0, math.radians(135)), 1.95),
		((0, 5, 1.6), (math.pi / 2, 0, math.pi), 0.55), ((5, 0, 1.6), (math.pi / 2, 0, math.pi / 2), 0.55),
		((SH_X, 5, 0.88), (math.pi / 2, 0, math.pi), 0.4), ((5, 0, 0.88), (math.pi / 2, 0, math.pi / 2), 0.4)]
	tiles = []
	tmp = os.path.splitext(path)[0]
	for i, (loc, rot, osc) in enumerate(views):
		cam.location = loc
		cam.rotation_euler = rot
		cam.data.ortho_scale = osc
		if i >= 4:
			scn.render.resolution_y = 420
		scn.render.filepath = tmp + "_%d.png" % i
		bpy.ops.render.render(write_still=True)
		img = bpy.data.images.load(scn.render.filepath)
		w, h = img.size
		a = np.empty(w * h * 4, np.float32)
		img.pixels.foreach_get(a)
		tiles.append(a.reshape(h, w, 4))
		bpy.data.images.remove(img)
		os.remove(scn.render.filepath)
	top = np.concatenate(tiles[:4], axis=1)
	heads = np.concatenate(tiles[4:], axis=1)
	allp = np.concatenate([heads, top], axis=0)
	h, w = allp.shape[:2]
	im = bpy.data.images.new("prev", w, h, alpha=True)
	im.pixels.foreach_set(allp.reshape(-1))
	im.filepath_raw = path
	im.file_format = 'PNG'
	im.save()
	bpy.data.objects.remove(cam)
	print("önizleme:", path)


def export(rig, body, out):
	bpy = B.bpy
	for o in bpy.context.selected_objects:
		o.select_set(False)
	kw = dict(filepath=out, export_format='GLB', export_yup=True, export_skins=True, export_animations=False,
		export_texcoords=True, export_normals=True, export_materials='EXPORT', export_image_format='NONE',
		export_def_bones=False, export_influence_nb=4)
	try:
		bpy.ops.export_scene.gltf(export_vertex_color='ACTIVE', **kw)
	except TypeError:
		bpy.ops.export_scene.gltf(**kw)


def main():
	argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	ap = argparse.ArgumentParser()
	ap.add_argument("--nation", default="usa", choices=sorted(NATION.keys()))
	ap.add_argument("--out", default="")
	ap.add_argument("--preview", default="")
	ap.add_argument("--no-gear", action="store_true")
	args = ap.parse_args(argv)
	import bpy
	B.bpy = bpy
	cfg = NATION[args.nation]
	for f in ba.MH_FILES:
		ba.fetch(ba.MH_RAW, f)
	fetch_sys(["clothes/%s/" % cfg["suit"], "clothes/%s/" % cfg["boots"], "skins/%s/" % cfg["skin"]])
	bpy.ops.wm.read_factory_settings(use_empty=True)
	B.scn = bpy.context.scene
	B.mats = {}
	base, sk = human(args.nation)
	F = Frame(base, sk)
	vb = F(base.v)
	bw = base_weights(len(vb))
	layout, palm = ba.rig_layout(sk, vb)
	vb = curl_fingers(vb, sk, palm)
	info = {"nation": args.nation}
	objs, camo_k = body_parts(cfg, base, F, vb, bw, info)
	ao, _arm = ba.make_armature(bpy, B.scn, layout)
	for ob in objs:
		m = ob.modifiers.new("Armature", 'ARMATURE')
		m.object = ao
		m.use_deform_preserve_volume = True
	J = repose(ao, palm, objs)
	bpy.data.objects.remove(ao)
	for ob in objs:
		set_weights(ob, [merge_game(d) for d in obj_weights(ob)])
	info["retarget"] = retarget(J, objs)
	if not args.no_gear:
		objs += gear(args.nation, objs, info)
	# üçgen bütçesi: baş/eller ve botlar inceltilir (simetrik); kıyafet zaten düşük poligon
	for ob in objs:
		r = {"skin": DEC_SKIN, "boots": DEC_BOOT}.get(ob.name.split(".")[0], 1.0)
		if r < 0.999:
			m = ob.modifiers.new("dec", 'DECIMATE')
			m.ratio = r
			m.use_symmetry = True
			m.symmetry_axis = 'X'
			apply_mods(ob)
		tri = sum(len(p.vertices) - 2 for p in ob.data.polygons)
		info.setdefault("tris_part", {})[ob.name] = tri
	print("parça üçgenleri:", info.get("tris_part"))
	rig = game_armature()
	body = finalize(objs, rig, os.path.join(ROOT, args.preview) if args.preview else "")
	tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
	info.update(tris=tris, verts=len(body.data.vertices), camo_k=round(camo_k, 4))
	out = os.path.join(ROOT, args.out or "assets/models/soldier_%s_rig.glb" % args.nation)
	os.makedirs(os.path.dirname(out), exist_ok=True)
	export(rig, body, out)
	with open(os.path.splitext(out)[0] + ".json", "w", encoding="utf-8") as f:
		json.dump(info, f, indent=1, ensure_ascii=False)
	print("yazıldı:", out, "üçgen:", tris, "köşe:", len(body.data.vertices), "camo_k:", round(camo_k, 4))


# ------------------------------------------------------------------ teçhizat
class Geo:
	"""teçhizat örgüsü biriktirici: her parça tek kemiğe sert bağlı; UV kutu izdüşümü (m / CAMO_TILE)"""
	def __init__(self):
		self.v = []
		self.f = []
		self.fm = []
		self.vb = []

	def add_bm(self, bm, mat, bone, R=None, t=(0.0, 0.0, 0.0)):
		R = np.eye(3) if R is None else np.asarray(R)
		t = np.asarray(t, float)
		base = len(self.v)
		bm.verts.index_update()
		for v in bm.verts:
			self.v.append(R @ np.array(v.co) + t)
			self.vb.append(bone)
		for f in bm.faces:
			self.f.append([base + v.index for v in f.verts])
			self.fm.append(mat)
		bm.free()

	def obj(self, name):
		if not self.f:
			return None
		V = np.array(self.v)
		uv = []
		for p in self.f:
			P = V[p]
			n = np.cross(P[1] - P[0], P[2] - P[0])
			a = int(np.argmax(np.abs(n)))
			ij = [(1, 2), (0, 2), (0, 1)][a]
			for q in P:
				uv.append((q[ij[0]] / CAMO_TILE, q[ij[1]] / CAMO_TILE))
		mats = sorted(set(self.fm))
		W = [{b: 1.0} for b in self.vb]
		return make_obj(name, V, self.f, mats, self.fm, uv=np.array(uv), weights=W)


def bm_box(size, bev=0.0, seg=2):
	import bmesh
	bm = bmesh.new()
	bmesh.ops.create_cube(bm, size=1.0)
	for v in bm.verts:
		v.co.x *= size[0]
		v.co.y *= size[1]
		v.co.z *= size[2]
	if bev > 0.0:
		bmesh.ops.bevel(bm, geom=list(bm.edges) + list(bm.verts), offset=min(bev, 0.49 * min(size)), segments=seg,
			profile=0.5, affect='EDGES', clamp_overlap=True)
	return bm


def bm_cyl(r, h, seg=12, r2=None, caps=True):
	import bmesh
	bm = bmesh.new()
	bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=h)
	return bm


def bm_sphere(rad, seg=16, rings=10):
	import bmesh
	bm = bmesh.new()
	bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=1.0)
	for v in bm.verts:
		v.co.x *= rad[0]
		v.co.y *= rad[1]
		v.co.z *= rad[2]
	return bm


def bm_tube(pts, rad, seg=10, closed=False):
	"""çoklu çizgi boyunca eliptik kesitli tüp (kayış, hortum, kemer); rad: (yatay, dikey) her nokta için"""
	import bmesh
	from mathutils import Vector
	bm = bmesh.new()
	P = [Vector(p) for p in pts]
	n = len(P)
	rings = []
	for i in range(n):
		if closed:
			d = (P[(i + 1) % n] - P[i - 1]).normalized()
		else:
			d = (P[min(i + 1, n - 1)] - P[max(i - 1, 0)]).normalized()
		up = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((0, 1, 0))
		x = d.cross(up).normalized()
		y = x.cross(d).normalized()
		rx, ry = rad[i]
		rings.append([bm.verts.new(P[i] + x * (rx * math.cos(a)) + y * (ry * math.sin(a)))
			for a in (2 * math.pi * k / seg for k in range(seg))])
	m = n if closed else n - 1
	for i in range(m):
		A, Bq = rings[i], rings[(i + 1) % n]
		for k in range(seg):
			bm.faces.new((A[k], A[(k + 1) % seg], Bq[(k + 1) % seg], Bq[k]))
	if not closed:
		bm.faces.new(rings[0])
		bm.faces.new(rings[-1])
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	return bm


def eul(rx=0.0, ry=0.0, rz=0.0):
	cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
	Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
	Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
	return Rz @ Ry @ Rx


def section(P, z, dz=0.02, seg=24):
	"""gövde kesiti: z yüksekliğinde her açı diliminde merkezden en uzak nokta (merkez: x=0, y orta)"""
	m = np.abs(P[:, 2] - z) < dz
	Q = P[m]
	if len(Q) < 8:
		return None
	cy = 0.5 * (Q[:, 1].max() + Q[:, 1].min())
	ang = np.arctan2(Q[:, 1] - cy, Q[:, 0])
	r = np.hypot(Q[:, 0], Q[:, 1] - cy)
	out = np.zeros(seg)
	for k in range(seg):
		a0 = -math.pi + 2 * math.pi * k / seg
		sel = np.abs(np.angle(np.exp(1j * (ang - a0)))) < math.pi / seg * 1.6
		out[k] = r[sel].max() if sel.any() else 0.0
	# boş dilimleri komşulardan doldur
	for _ in range(3):
		for k in range(seg):
			if out[k] == 0.0:
				out[k] = max(out[k - 1], out[(k + 1) % seg])
	return cy, out


def bm_shell(zs, secs, off, seg=24):
	"""ölçülen kesitlerden gövdeyi saran kapalı halka şerit (yelek, kemer); secs: [(cy, r[seg])]"""
	import bmesh
	bm = bmesh.new()
	rings = []
	for z, (cy, r) in zip(zs, secs):
		ring = []
		for k in range(seg):
			a = -math.pi + 2 * math.pi * k / seg
			rr = r[k] + off
			ring.append(bm.verts.new((rr * math.cos(a), cy + rr * math.sin(a), z)))
		rings.append(ring)
	for i in range(len(rings) - 1):
		A, Bq = rings[i], rings[i + 1]
		for k in range(seg):
			bm.faces.new((A[k], A[(k + 1) % seg], Bq[(k + 1) % seg], Bq[k]))
	return bm


def solidify(bm, t):
	"""kabuğa kalınlık (içe): yüzleri ve sınır kenarlarını kapatarak"""
	import bmesh
	geom = bmesh.ops.solidify(bm, geom=list(bm.faces), thickness=t)
	return bm


def gear(nat, objs, info):
	usa = nat == "usa"
	G = Geo()
	skin = next(o for o in objs if o.name.startswith("skin"))
	uni = next(o for o in objs if o.name.startswith("uniform"))
	SP = obj_coords(skin)
	SW = obj_weights(skin)
	UP = obj_coords(uni)
	UW = obj_weights(uni)
	torso = np.array([dominant(w) in ("spine", "pelvis") for w in UW])
	TP = UP[torso]
	# --- ölçüler
	head = np.array([dominant(w) == "spine" and p[2] > 1.5 for p, w in zip(SP, SW)])
	HP = SP[head]
	htop = float(HP[:, 2].max())
	eye_z = htop - 0.115
	# kafatası: kaş hizasının üstü (yüz ve kulak hariç: |x| kulak içi, ön yüz burnun gerisi)
	hz = HP[(HP[:, 2] > eye_z + 0.01)]
	hcx = 0.0
	hcy = 0.5 * (hz[:, 1].max() + hz[:, 1].min())
	hrx = float(np.abs(hz[:, 0]).max())
	hry = 0.5 * float(hz[:, 1].max() - hz[:, 1].min())
	face_y = float(HP[(np.abs(HP[:, 2] - eye_z) < 0.02) & (np.abs(HP[:, 0]) < 0.03)][:, 1].max())
	info["head"] = dict(top=round(htop, 3), cy=round(hcy, 3), rx=round(hrx, 3), ry=round(hry, 3), face_y=round(face_y, 3))
	zs = [1.02, 1.08, 1.14, 1.2, 1.26, 1.32, 1.38, 1.42]
	secs = [section(TP, z) for z in zs]
	sec = dict(zip(zs, secs))
	front = {z: s[0] + s[1][18] for z, s in sec.items() if s}    # açı +90° (ileri) dilimi: k = seg*3/4
	back = {z: s[0] - s[1][6] for z, s in sec.items() if s}
	info["torso_front"] = {str(k): round(float(v), 3) for k, v in front.items()}
	# omuz üstü (yelek askısı için)
	shz = {}
	for sx in (1.0, -1.0):
		m = (TP[:, 0] * sx > 0.115) & (TP[:, 0] * sx < 0.15) & (np.abs(TP[:, 1]) < 0.04)
		shz[sx] = float(TP[m][:, 2].max()) if m.any() else 1.45
	info["shoulder_top"] = round(shz[1.0], 3)
	# --- kask (kabuk kafatasının ~3 cm dışında: iç yastık + 1 cm kabuk)
	HC = np.array([hcx, hcy, eye_z + 0.012])
	HR = (hrx + 0.028, hry + 0.03, htop + 0.035 - HC[2])
	bmh = bm_sphere(HR, 24, 16)
	import bmesh

	def on_shell(d):
		d = np.asarray(d, float)
		d = d / np.linalg.norm(d / np.array(HR))
		return HC + d

	cut_front = eye_z + 0.035
	cut_back = eye_z - 0.085
	kill = []
	for v in bmh.verts:
		y = v.co.y
		# kesim yüksekliği yatay açıya göre: önde kaş, arkada ense; yanlarda kulak üstü
		ph = math.atan2(v.co.y / HR[1], v.co.x / HR[0])
		t = 0.5 * (1.0 + math.sin(ph))                            # 0 arka, 1 ön
		t = t * t * (3 - 2 * t)
		zr = (cut_back + (cut_front - cut_back) * t) - HC[2]
		# yüksek kesim (ABD IHPS/FAST): kulak üstü oyuk; Rus 6B47 kulakları kısmen örter
		side = abs(math.cos(ph))
		ear = math.exp(-((y + 0.01) / 0.05) ** 2) * (0.045 if usa else 0.014) * max(0.0, side - 0.5) * 2.0
		if v.co.z < zr + ear:
			kill.append(v)
	bmesh.ops.delete(bmh, geom=kill, context='VERTS')
	bmesh.ops.solidify(bmh, geom=list(bmh.faces), thickness=0.011)
	G.add_bm(bmh, "helmet", "spine", t=HC)
	rim_z = htop - 0.11
	if usa:
		p = on_shell((0, 1.0, 0.45))
		G.add_bm(bm_box((0.05, 0.022, 0.045), 0.006), "dark", "spine", R=eul(-0.35, 0, 0), t=p + (0, 0.008, 0))            # NVG yuvası
		G.add_bm(bm_box((0.028, 0.02, 0.026), 0.004), "gun", "spine", t=p + (0, 0.022, -0.012))
		for sx in (1, -1):
			p = on_shell((sx, 0.0, 0.3))
			G.add_bm(bm_box((0.012, 0.11, 0.022), 0.003), "dark", "spine", t=p + (sx * 0.004, 0, 0))                     # yan ray (ARC)
			p = on_shell((sx * 0.45, -0.55, 0.75))
			G.add_bm(bm_box((0.045, 0.035, 0.004), 0.0), "team", "spine", R=eul(-0.6, 0, -sx * 0.5), t=p)               # IR / kimlik yaması
			G.add_bm(bm_sphere((0.022, 0.034, 0.042), 12, 7), "dark", "spine", t=(sx * (hrx + 0.016), hcy - 0.004, eye_z - 0.03))  # aktif kulaklık
		p = on_shell((0, -1.0, 0.25))
		G.add_bm(bm_box((0.085, 0.03, 0.05), 0.008), "pack", "spine", t=p + (0, -0.01, 0))                               # karşı ağırlık / pil
		G.add_bm(bm_box((0.05, 0.006, 0.022), 0.0), "team", "spine", t=p + (0, -0.027, 0))                              # strob
		G.add_bm(bm_tube([(-0.02, face_y - 0.02, eye_z - 0.055), (-0.085, face_y - 0.04, eye_z - 0.04), (-hrx - 0.01, hcy, eye_z - 0.03)],
			[(0.004, 0.004)] * 3, 6), "dark", "spine")                                                              # mikrofon kolu
		# balistik gözlük
		for sx in (1, -1):
			G.add_bm(bm_sphere((0.026, 0.008, 0.017), 10, 6), "dark", "spine", t=(sx * 0.034, face_y + 0.012, eye_z + 0.002))
		G.add_bm(bm_box((0.13, 0.008, 0.008), 0.002), "dark", "spine", t=(0, face_y + 0.012, eye_z + 0.018))
	else:
		# 6B47 kumaş örtü: kabuk üzerinde iki dikiş halkası + arkada kimlik bandı
		for zl in (0.045, 0.095):
			k = math.sqrt(max(0.0, 1.0 - (zl / HR[2]) ** 2))
			G.add_bm(bm_tube([(HC[0] + math.cos(a) * (HR[0] * k + 0.004), HC[1] + math.sin(a) * (HR[1] * k + 0.004), HC[2] + zl)
				for a in np.linspace(0, 2 * math.pi, 25)[:-1]], [(0.004, 0.004)] * 24, 5, closed=True), "pack", "spine")
		p = on_shell((0, -1.0, 0.35))
		G.add_bm(bm_box((0.06, 0.012, 0.018), 0.002), "team", "spine", t=p + (0, -0.004, 0))
		for sx in (1, -1):
			G.add_bm(bm_sphere((0.026, 0.04, 0.046), 12, 8), "dark", "spine", t=(sx * (hrx + 0.012), hcy - 0.005, eye_z - 0.035))
	for sx in (1, -1):    # çene kayışı
		G.add_bm(bm_tube([(sx * (hrx + 0.01), hcy + 0.01, rim_z + 0.02), (sx * (hrx - 0.005), hcy + 0.03, eye_z - 0.07),
			(sx * 0.04, face_y - 0.05, eye_z - 0.105)], [(0.008, 0.002)] * 3, 4), "strap", "spine")

	# --- plaka taşıyıcı: ölçülen gövde kesitine oturan kabuk + ön/arka plaka + omuz askıları + kummerbund
	vz = [z for z in zs if sec.get(z) and 1.06 <= z <= 1.38]
	shell = bm_shell(vz, [sec[z] for z in vz], 0.022)
	bmesh.ops.solidify(shell, geom=list(shell.faces), thickness=0.012)
	G.add_bm(shell, "vest", "spine")
	pw, ph = (0.27, 0.32) if usa else (0.3, 0.36)
	fz = 1.235
	fy = max(front[z] for z in front if 1.1 <= z <= 1.36) + 0.032
	by = min(back[z] for z in back if 1.1 <= z <= 1.36) - 0.032
	G.add_bm(bm_box((pw, 0.04, ph), 0.014), "vest", "spine", t=(0, fy, fz))
	G.add_bm(bm_box((pw, 0.04, ph + 0.02), 0.014), "vest", "spine", t=(0, by, fz + 0.01))
	for sx in (1, -1):
		x = sx * 0.105
		# omuz askısı gövde yüzeyini izler: x düzleminde merkezden yayılan ışınlarla en dış gövde noktası
		band = TP[np.abs(TP[:, 0] - x) < 0.025]
		c0 = np.array([0.0, 1.3])
		path = [(x, fy - 0.012, fz + ph * 0.5 - 0.03)]
		for th in np.linspace(math.radians(25), math.radians(155), 9):
			dvec = np.array([math.cos(th), math.sin(th)])
			rel = band[:, 1:3] - c0
			proj = rel @ dvec
			perp = np.abs(rel @ np.array([-dvec[1], dvec[0]]))
			sel = (perp < 0.02) & (proj > 0)
			r = float(proj[sel].max()) if sel.any() else 0.15
			q = c0 + dvec * (r + 0.009)
			path.append((x, float(q[0]), float(q[1])))
		path.append((x, by + 0.012, fz + ph * 0.5 - 0.02))
		G.add_bm(bm_tube(path, [(0.03, 0.006)] * len(path), 6), "vest", "spine")
		G.add_bm(bm_box((0.055, 0.014, 0.075), 0.004), "vest", "spine", t=(x, fy - 0.004, fz + ph * 0.5 + 0.02))   # askı tokası
	# MOLLE şeritleri (ön plaka)
	for k in range(4):
		G.add_bm(bm_box((pw * 0.9, 0.006, 0.012), 0.0), "strap", "spine", t=(0, fy + 0.022, fz - 0.1 + k * 0.05))
	# cepler: ABD 3'lü M4 şarjör cebi + idari cep; Rus 6B45: 4'lü AK şarjör cebi (eğik) + yaka koruması
	if usa:
		for x in (-0.085, 0.0, 0.085):
			G.add_bm(bm_box((0.074, 0.05, 0.13), 0.01), "vest", "spine", t=(x, fy + 0.045, fz - 0.07))
			G.add_bm(bm_box((0.03, 0.06, 0.05), 0.004), "gun", "spine", R=eul(0.08, 0, 0), t=(x, fy + 0.04, fz + 0.005))
			G.add_bm(bm_box((0.034, 0.012, 0.008), 0.0), "dark", "spine", t=(x, fy + 0.072, fz - 0.02))           # şok kordonu
		G.add_bm(bm_box((0.17, 0.03, 0.085), 0.008), "vest", "spine", t=(0, fy + 0.035, fz + 0.095))              # idari cep
		G.add_bm(bm_box((0.11, 0.004, 0.03), 0.0), "strap", "spine", t=(0, fy + 0.052, fz + 0.1))                  # ad bandı (cırt)
	else:
		for x in (-0.105, -0.035, 0.035, 0.105):
			G.add_bm(bm_box((0.066, 0.05, 0.15), 0.01), "vest", "spine", t=(x, fy + 0.045, fz - 0.06))
			G.add_bm(bm_box((0.034, 0.05, 0.06), 0.004), "gun", "spine", R=eul(0.25, 0, 0), t=(x, fy + 0.035, fz + 0.03))
		G.add_bm(bm_tube([(math.cos(a) * 0.1, 0.005 + math.sin(a) * 0.09, 1.45) for a in np.linspace(math.radians(-200), math.radians(20), 9)],
			[(0.03, 0.018)] * 9, 6), "vest", "spine")                                                                 # yaka koruması
		G.add_bm(bm_box((0.22, 0.03, 0.14), 0.02), "vest", "spine", R=eul(-0.12, 0, 0), t=(0, fy - 0.01, 0.94))        # kasık koruması
	# yan: telsiz cebi (sol) + anten; IFAK (sağ arka) + turnike (sağ askı)
	G.add_bm(bm_box((0.045, 0.07, 0.15), 0.008), "vest", "spine", t=(-0.2, -0.04, 1.22))
	G.add_bm(bm_box((0.035, 0.05, 0.12), 0.006), "dark", "spine", t=(-0.205, -0.04, 1.3))
	G.add_bm(bm_cyl(0.004, 0.38, 6), "dark", "spine", R=eul(0.12, 0, 0), t=(-0.205, -0.06, 1.52))
	G.add_bm(bm_tube([(-0.2, -0.02, 1.36), (-0.15, 0.06, 1.44), (-0.1, fy - 0.02, 1.4)], [(0.006, 0.006)] * 3, 6), "dark", "spine")  # PTT kablosu
	G.add_bm(bm_box((0.11, 0.045, 0.1), 0.01), "pack", "spine", t=(0.16, by - 0.03, 1.12))
	G.add_bm(bm_box((0.035, 0.004, 0.035), 0.0), "red", "spine", t=(0.16, by - 0.054, 1.12))
	G.add_bm(bm_box((0.03, 0.03, 0.09), 0.005), "dark", "spine", t=(0.105, fy + 0.0, fz + ph * 0.5 + 0.075))
	G.add_bm(bm_box((0.034, 0.008, 0.014), 0.0), "red", "spine", t=(0.105, fy + 0.017, fz + ph * 0.5 + 0.1))
	# --- sırt çantası
	pk = (0.3, 0.16, 0.4) if usa else (0.28, 0.15, 0.36)
	py = by - 0.02 - pk[1] * 0.5
	G.add_bm(bm_box(pk, 0.03), "pack", "spine", t=(0, py, 1.25))
	G.add_bm(bm_box((pk[0] * 0.94, pk[1] * 0.9, 0.06), 0.015), "pack", "spine", t=(0, py, 1.25 + pk[2] * 0.5))           # kapak
	G.add_bm(bm_box((0.18, 0.035, 0.17), 0.012), "pack", "spine", t=(0, py - pk[1] * 0.5 - 0.012, 1.22))                 # ön cep
	for sx in (1, -1):
		G.add_bm(bm_box((0.02, 0.01, pk[2] * 0.9), 0.0), "strap", "spine", t=(sx * 0.075, py - pk[1] * 0.5 - 0.03, 1.25))
		G.add_bm(bm_box((0.012, pk[1] * 1.04, 0.02), 0.0), "strap", "spine", t=(sx * (pk[0] * 0.5 + 0.004), py, 1.18))
		G.add_bm(bm_box((0.04, 0.1, 0.18), 0.01), "pack", "spine", t=(sx * (pk[0] * 0.5 + 0.02), py, 1.2))
	if usa:
		G.add_bm(bm_box((0.012, 0.03, 0.2), 0.003), "dark", "spine", t=(pk[0] * 0.5 + 0.012, py, 1.27))                    # çanta yan şeridi
	else:
		G.add_bm(bm_box((0.012, 0.03, 0.24), 0.003), "gun", "spine", t=(-pk[0] * 0.5 - 0.01, py, 1.22))                   # kürek sapı
		G.add_bm(bm_box((0.012, 0.13, 0.13), 0.01), "gun", "spine", t=(-pk[0] * 0.5 - 0.01, py, 1.06))
	# --- kemer (battle belt) + bel cepleri + tabanca kılıfı
	bz = [0.95, 0.99]
	bsec = [section(TP, z, 0.015) for z in bz]
	if all(bsec):
		belt = bm_shell(bz, bsec, 0.014)
		bmesh.ops.solidify(belt, geom=list(belt.faces), thickness=0.01)
		G.add_bm(belt, "strap", "pelvis")
		bfy = bsec[1][0] + bsec[1][1][18] + 0.016
		bby = bsec[1][0] - bsec[1][1][6] - 0.016
		G.add_bm(bm_box((0.055, 0.014, 0.04), 0.004), "gun", "pelvis", t=(0, bfy + 0.006, 0.97))
		G.add_bm(bm_box((0.07, 0.045, 0.09), 0.01), "pack", "pelvis", t=(-0.17, bby * 0.5 - 0.02, 0.95))           # dökme cebi
		G.add_bm(bm_cyl(0.038, 0.13, 14), "pack", "pelvis", t=(-0.19, bby * 0.7, 0.94))                          # matara
		G.add_bm(bm_box((0.12, 0.04, 0.075), 0.01), "pack", "pelvis", t=(0.0, bby - 0.02, 0.96))                  # IFAK
		G.add_bm(bm_box((0.03, 0.004, 0.03), 0.0), "red", "pelvis", t=(0.0, bby - 0.041, 0.965))
	# tabanca kılıfı: sağ uyluk (bacak kemiğine)
	G.add_bm(bm_box((0.045, 0.085, 0.16), 0.01), "dark", "leg_r", t=(0.205, 0.015, 0.8))
	G.add_bm(bm_box((0.035, 0.05, 0.07), 0.006), "gun", "leg_r", t=(0.205, -0.005, 0.89))
	G.add_bm(bm_tube([(math.cos(a) * 0.088 + 0.1, math.sin(a) * 0.09, 0.76) for a in np.linspace(0, 2 * math.pi, 17)[:-1]],
		[(0.012, 0.003)] * 16, 4, closed=True), "strap", "leg_r")
	# --- bacaklar: kargo cebi (uyluk yanı), dizlik, bot körüğü (pantolon paçası bota sokulu)
	for s, sx in (("r", 1.0), ("l", -1.0)):
		lp = UP[np.array([dominant(w) == "leg_" + s for w in UW])]
		kz = HIP - THIGH
		th = lp[np.abs(lp[:, 2] - 0.7) < 0.03]
		if len(th):
			ox = float(np.abs(th[:, 0]).max())
			if s == "l":
				G.add_bm(bm_box((0.035, 0.12, 0.15), 0.012), "uniform", "leg_" + s, t=(sx * (ox + 0.006), 0.012, 0.69))
				G.add_bm(bm_box((0.012, 0.125, 0.04), 0.005), "uniform", "leg_" + s, t=(sx * (ox + 0.022), 0.012, 0.765))
		kp = UP[np.array([dominant(w) in ("knee_" + s, "leg_" + s) for w in UW])]
		kn = kp[np.abs(kp[:, 2] - kz) < 0.03]
		ky = float(kn[:, 1].max()) if len(kn) else 0.06
		pad = bm_sphere((0.055, 0.03, 0.068), 16, 10)
		G.add_bm(pad, "rubber", "knee_" + s, t=(sx * LEG_X, ky + 0.012, kz - 0.005))
		G.add_bm(bm_box((0.045, 0.01, 0.045), 0.006), "dark", "knee_" + s, t=(sx * LEG_X, ky + 0.04, kz - 0.005))
		# bot körüğü: pantolon paçası konç üstünde toplanır (ölçülen baldır kesitine göre)
		bt = info["boot_top"]
		sh = kp[np.abs(kp[:, 2] - (bt + 0.03)) < 0.02]
		if len(sh):
			cx = float(sh[:, 0].mean())
			cyy = 0.5 * float(sh[:, 1].max() + sh[:, 1].min())
			rr = 0.5 * float(max(sh[:, 0].max() - sh[:, 0].min(), sh[:, 1].max() - sh[:, 1].min()))
			G.add_bm(bm_tube([(cx + math.cos(a) * (rr + 0.004), cyy + math.sin(a) * (rr + 0.006), bt + 0.006) for a in np.linspace(0, 2 * math.pi, 15)[:-1]],
				[(0.01, 0.013)] * 14, 6, closed=True), "uniform", "knee_" + s)
	# --- kollar: omuz cebi + dost/düşman tanıma (IFF) bandı: üst kola sarılı takım renkli bant (gerçek
	# cephelerde renkli bantla tanıma yapılır; RTS'de takım rengi uzaktan seçilir)
	for s, sx in (("r", 1.0), ("l", -1.0)):
		ap = UP[np.array([dominant(w) == "arm_" + s for w in UW])]
		a = ap[np.abs(ap[:, 2] - (SH_Z - 0.1)) < 0.03]
		if len(a):
			ox = float(np.abs(a[:, 0]).max())
			G.add_bm(bm_box((0.012, 0.075, 0.085), 0.004), "uniform", "arm_" + s, t=(sx * (ox + 0.004), 0.0, SH_Z - 0.11))
		b = ap[np.abs(ap[:, 2] - (SH_Z - 0.19)) < 0.02]
		if len(b):
			cx = float(b[:, 0].mean())
			cyy = 0.5 * float(b[:, 1].max() + b[:, 1].min())
			rx = 0.5 * float(b[:, 0].max() - b[:, 0].min()) + 0.006
			ry = 0.5 * float(b[:, 1].max() - b[:, 1].min()) + 0.006
			G.add_bm(bm_tube([(cx + math.cos(t) * rx, cyy + math.sin(t) * ry, SH_Z - 0.19) for t in np.linspace(0, 2 * math.pi, 15)[:-1]],
				[(0.002, 0.022)] * 14, 4, closed=True), "team", "arm_" + s)
	o = G.obj("gear")
	return [o] if o else []


if __name__ == "__main__":
	main()
