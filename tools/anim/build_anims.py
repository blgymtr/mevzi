#!/usr/bin/env python3
# MEVZİ iskeletli animasyon hattı (Unreal yerine kendi hattımız):
#   MakeHuman taban örgü (CC0) + kendi oyun iskeletimiz (35 kemik, Godot humanoid adları)
#   + CMU mocap (BVH) → yeniden hedefleme (retarget) → adlı kliplerle GLB.
#
# Kullanım (proje kökünden; Blender'ın Python modülü 'bpy' gerekir):
#   python3 tools/anim/build_anims.py                 # indir (önbellek) + üret
#   python3 tools/anim/build_anims.py --only walk,run # hızlı deneme: yalnız bu klipler
#   python3 tools/anim/build_anims.py --decimate 1.0  # tam çözünürlüklü örgü
# Çıktı: assets/anim/soldier_anim.glb + assets/anim/soldier_anim.json (klip bilgisi)
# Kaynak dosyalar tools/anim/.cache altına indirilir (git'e girmez, .gdignore'lu).
import argparse
import json
import math
import os
import subprocess
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import bvh as bvhmod  # noqa: E402
import mh  # noqa: E402
from rmath import (arc, axis_angle, continuous, gauss_smooth, mat_slerp, mat_to_quat,  # noqa: E402
	normalize, rot_z, triad)

CACHE = os.path.join(HERE, ".cache")
# kaynaklar sabit işlemelere (commit) bağlı → yeniden üretilebilir
MH_SHA = "a8bc2d54ff0ac92e78ff71431b1023eda42bf482"
CMU_SHA = "09a07f54f3bbb58797325f009282d0b2048a2871"
MH_RAW = "https://raw.githubusercontent.com/makehumancommunity/makehuman/%s/" % MH_SHA
CMU_RAW = "https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/%s/" % CMU_SHA
MH_FILES = [
	"LICENSE.md", "LICENSE.ASSETS.md",
	"makehuman/data/3dobjs/base.obj",
	"makehuman/data/rigs/default.mhskel",
	"makehuman/data/rigs/default_weights.mhw",
	"makehuman/data/targets/macrodetails/african-male-young.target",
	"makehuman/data/targets/macrodetails/asian-male-young.target",
	"makehuman/data/targets/macrodetails/caucasian-male-young.target",
	"makehuman/data/targets/macrodetails/universal-male-young-maxmuscle-averageweight.target",
	"makehuman/data/targets/macrodetails/height/male-young-averagemuscle-averageweight-maxheight.target",
	"makehuman/data/targets/macrodetails/proportions/male-young-averagemuscle-averageweight-idealproportions.target",
]
CMU_FILES = ["README.md", "READMEFIRST.txt"]

FPS = 30            # çıktı kare hızı
SRC_FPS = 120       # CMU
HEIGHT = 1.80       # asker boyu (m)

# ------------------------------------------------------------------ klip listesi
# src: CMU deneme adı; fr: 120 fps kare aralığı (0 = T-pozu); loop: döngü (yerinde), cyc: döngü boyu aralığı (s)
# turn: kök (Root) dönüşü kök hareketine yazılır; diğer tek seferlik kliplerde yalnız yatay kayma
CLIPS = [
	dict(name="idle", src="77_02", fr=(60, 930), loop=True, cyc=(2.5, 5.0), tr="ayakta bekleme (hafif ağırlık aktarma)"),
	dict(name="walk", src="35_01", fr=(10, 358), loop=True, cyc=(0.95, 1.3), tr="yürüyüş"),
	dict(name="run", src="35_17", fr=(5, 167), loop=True, cyc=(0.6, 0.85), tr="koşu"),
	dict(name="sprint", src="127_07", fr=(25, 999), loop=True, cyc=(0.55, 0.8), tr="depar"),
	dict(name="walk_back", src="141_31", fr=(40, 250), loop=True, cyc=(0.8, 1.4), heading="face", tr="geri geri yürüme"),
	dict(name="strafe_right", src="141_33", fr=(100, 525), loop=True, cyc=(0.7, 1.8), heading="face", tr="yana (sağa) adımlama"),
	dict(name="strafe_left", src="141_33", fr=(565, 965), loop=True, cyc=(0.7, 1.8), heading="face", tr="yana (sola) adımlama"),
	dict(name="crouch_walk", src="77_29", fr=(890, 1145), loop=True, cyc=(1.0, 1.9), crouch=(0.10, 10.0), tr="çömelerek / sinsice yürüme (+10 cm IK ile alçaltılmış)"),
	dict(name="crawl", src="111_03", fr=(560, 1240), loop=True, cyc=(1.0, 2.6), tr="dört ayak (el-diz) sürünme"),
	dict(name="prone_idle", src="140_01", fr=(1, 175), loop=True, cyc=(1.0, 1.4), tr="yüzüstü yatış (bekleme)"),
	dict(name="kneel_idle", src="23_03", fr=(230, 490), loop=True, cyc=(1.2, 2.1), tr="tek diz çökmüş bekleme"),
	dict(name="jump", src="13_11", fr=(150, 395), tr="ileri atlama"),
	dict(name="hit_stagger", src="22_12", fr=(1, 130), tr="darbe / sendeleme ve toparlanma"),
	dict(name="duck", src="77_09", fr=(170, 560), tr="patlamadan korunma: çömelip başı kollarla kapatma"),
	dict(name="fall_back", src="90_18", fr=(70, 185), tr="sırt üstü düşme (ölüm / devrilme)"),
	dict(name="getup", src="77_16", fr=(170, 560), tr="yüzüstü yatıştan kalkıp tetikte duruşa geçme"),
	dict(name="turn_left", src="69_16", fr=(175, 410), turn=True, tr="yerinde 90° sola dönüş"),
	dict(name="turn_right", src="69_18", fr=(125, 345), turn=True, tr="yerinde 90° sağa dönüş"),
	dict(name="kneel_down", src="23_03", fr=(35, 235), tr="tek dize çökme"),
	dict(name="kneel_up", src="23_03", fr=(485, 615), tr="dizden kalkma"),
]


def cmu_path(src):
	subj = src.split("_")[0]
	return "data/%03d/%s.bvh" % (int(subj), src)


def cp(rel):
	return os.path.join(CACHE, rel)


def fetch(base, rel):
	dst = cp(rel)
	if os.path.exists(dst) and os.path.getsize(dst) > 0:
		return
	os.makedirs(os.path.dirname(dst), exist_ok=True)
	print("indiriliyor:", rel)
	subprocess.run(["curl", "-sSfL", "--retry", "3", "-o", dst + ".part", base + rel], check=True)
	os.replace(dst + ".part", dst)


def fetch_all(clips):
	os.makedirs(CACHE, exist_ok=True)
	gd = os.path.join(CACHE, ".gdignore")   # Godot önbellekteki .obj'yi içe aktarmasın
	if not os.path.exists(gd):
		open(gd, "w").close()
	for f in MH_FILES:
		fetch(MH_RAW, f)
	for f in CMU_FILES:
		fetch(CMU_RAW, f)
	for c in clips:
		fetch(CMU_RAW, cmu_path(c["src"]))


# ------------------------------------------------------------------ insan örgüsü
MHD = "makehuman/data/"


def build_human():
	base = mh.BaseMesh(cp(MHD + "3dobjs/base.obj"))
	T = MHD + "targets/macrodetails/"
	# makro: erkek, genç (25), etnik karışım eşit, kas %67, boy biraz uzun, ideal oran yarım
	for r in ("african", "asian", "caucasian"):
		base.apply_target(cp(T + r + "-male-young.target"), 1.0 / 3.0)
	base.apply_target(cp(T + "universal-male-young-maxmuscle-averageweight.target"), 0.35)
	base.apply_target(cp(T + "height/male-young-averagemuscle-averageweight-maxheight.target"), 0.15)
	base.apply_target(cp(T + "proportions/male-young-averagemuscle-averageweight-idealproportions.target"), 0.5)
	sk = mh.Skeleton(cp(MHD + "rigs/default.mhskel"))
	vb = base.to_b()
	keep = {"body", "helper-l-eye", "helper-r-eye"}
	faces = [(g, c) for g, c in base.faces if g in keep]
	body_v = np.array(sorted({v for g, c in faces if g == "body" for v, t in c}))
	floor = vb[body_v, 2].min()
	top = vb[body_v, 2].max()
	s = HEIGHT / (top - floor)
	hipc = 0.5 * (sk.head(vb, "upperleg02.L") + sk.head(vb, "upperleg02.R"))
	vb = (vb - np.array([0.0, hipc[1], floor])) * s
	used = sorted({v for g, c in faces for v, t in c})
	return base, sk, vb, faces, used


# ------------------------------------------------------------------ iskelet
SIDES = (("L", "Left"), ("R", "Right"))
FINGERS = ["ThumbMetacarpal", "ThumbProximal", "IndexProximal", "IndexIntermediate", "MiddleProximal", "MiddleIntermediate"]
ARM_LAYER = []   # tüfek katmanının süzgeci (omuz, kol, el, parmak)
for _s, S in SIDES:
	ARM_LAYER += [S + "Shoulder", S + "UpperArm", S + "LowerArm", S + "Hand"] + [S + f for f in FINGERS]


def rig_layout(sk, vb):
	H = lambda b: sk.head(vb, b)
	T = lambda b: sk.tail(vb, b)
	bones = []
	fwd = (0, 1, 0)
	up = (0, 0, 1)

	def add(n, p, h, t, z):
		bones.append(dict(name=n, parent=p, head=np.array(h, float), tail=np.array(t, float), z=np.array(z, float)))

	hip = {}
	for s, S in SIDES:
		hip[s] = 0.5 * (H("upperleg01." + s) + H("upperleg02." + s))
	hc = 0.5 * (hip["L"] + hip["R"])
	hc[0] = 0.0
	sp4 = H("spine04"); sp4[0] = 0.0
	add("Root", None, (0, 0, 0), (0, 0.2, 0), up)
	add("Hips", "Root", hc, sp4, fwd)
	add("Spine", "Hips", sp4, H("spine02"), fwd)
	add("Chest", "Spine", H("spine02"), H("spine01"), fwd)
	add("UpperChest", "Chest", H("spine01"), H("neck01"), fwd)
	add("Neck", "UpperChest", H("neck01"), H("head"), fwd)
	add("Head", "Neck", H("head"), T("head") + np.array([0, 0, 0.03]), fwd)
	for s, S in SIDES:
		add(S + "Shoulder", "UpperChest", H("clavicle." + s), H("upperarm01." + s), fwd)
		add(S + "UpperArm", S + "Shoulder", H("upperarm01." + s), H("lowerarm01." + s), fwd)
		add(S + "LowerArm", S + "UpperArm", H("lowerarm01." + s), H("wrist." + s), fwd)
		add(S + "Hand", S + "LowerArm", H("wrist." + s), H("finger3-1." + s), up)
		add(S + "ThumbMetacarpal", S + "Hand", H("finger1-1." + s), H("finger1-2." + s), up)
		add(S + "ThumbProximal", S + "ThumbMetacarpal", H("finger1-2." + s), T("finger1-3." + s), up)
		add(S + "IndexProximal", S + "Hand", H("finger2-1." + s), H("finger2-2." + s), up)
		add(S + "IndexIntermediate", S + "IndexProximal", H("finger2-2." + s), T("finger2-3." + s), up)
		add(S + "MiddleProximal", S + "Hand", H("finger3-1." + s), H("finger3-2." + s), up)
		add(S + "MiddleIntermediate", S + "MiddleProximal", H("finger3-2." + s), T("finger3-3." + s), up)
		add(S + "UpperLeg", "Hips", hip[s], H("lowerleg01." + s), fwd)
		add(S + "LowerLeg", S + "UpperLeg", H("lowerleg01." + s), H("foot." + s), fwd)
		add(S + "Foot", S + "LowerLeg", H("foot." + s), H("toe3-1." + s), up)
		add(S + "Toes", S + "Foot", H("toe3-1." + s), T("toe3-3." + s), up)
	# avuç normali (avuç içine doğru): işaret→serçe ekseni × el yönü; başparmak tarafına göre işaret
	palm = {}
	for s, S in SIDES:
		d = normalize(H("finger3-1." + s) - H("wrist." + s))
		across = normalize(H("finger2-1." + s) - H("finger5-1." + s))
		n = normalize(np.cross(d, across))
		thumb = T("finger1-3." + s) - H("wrist." + s)
		if np.dot(n, thumb - d * np.dot(thumb, d)) < 0:
			n = -n
		palm[S] = n
	return bones, palm


def weight_map(n):
	if n.endswith(".L"):
		S, b = "Left", n[:-2]
	elif n.endswith(".R"):
		S, b = "Right", n[:-2]
	else:
		S, b = "", n
	if b in ("root", "pelvis", "spine05"):
		return {"Hips": 1.0}
	if b in ("spine04", "spine03"):
		return {"Spine": 1.0}
	if b == "spine02":
		return {"Chest": 1.0}
	if b in ("spine01", "breast"):
		return {"UpperChest": 1.0}
	if b in ("neck01", "neck02"):
		return {"Neck": 1.0}
	if b == "neck03":
		return {"Neck": 0.5, "Head": 0.5}
	if b == "clavicle":
		return {S + "Shoulder": 1.0}
	if b == "shoulder01":
		return {S + "Shoulder": 0.5, S + "UpperArm": 0.5}
	if b.startswith("upperarm"):
		return {S + "UpperArm": 1.0}
	if b.startswith("lowerarm"):
		return {S + "LowerArm": 1.0}
	if b == "wrist" or b.startswith("metacarpal"):
		return {S + "Hand": 1.0}
	if b.startswith("finger"):
		f, k = (int(x) for x in b[6:].split("-"))
		if f == 1:
			return {S + ("ThumbMetacarpal" if k == 1 else "ThumbProximal"): 1.0}
		nm = "Index" if f == 2 else "Middle"
		return {S + nm + ("Proximal" if k == 1 else "Intermediate"): 1.0}
	if b == "upperleg01":
		return {"Hips": 0.3, S + "UpperLeg": 0.7}
	if b == "upperleg02":
		return {S + "UpperLeg": 1.0}
	if b.startswith("lowerleg"):
		return {S + "LowerLeg": 1.0}
	if b == "foot":
		return {S + "Foot": 1.0}
	if b.startswith("toe"):
		return {S + "Toes": 1.0}
	return {"Head": 1.0}   # yüz, çene, göz, dil kemikleri


def vertex_weights(used):
	W = mh.load_weights(cp(MHD + "rigs/default_weights.mhw"))
	acc = {}
	for mb, lst in W.items():
		m = weight_map(mb)
		for vi, w in lst:
			d = acc.setdefault(vi, {})
			for tb, k in m.items():
				d[tb] = d.get(tb, 0.0) + w * k
	out = {}
	for v in used:
		d = acc.get(v, {"Hips": 1.0})
		top = sorted(d.items(), key=lambda kv: -kv[1])[:4]
		s = sum(w for _, w in top)
		out[v] = [(b, w / s) for b, w in top if w / s > 0.01]
	return out


# ------------------------------------------------------------------ kaynak eşleme
# hedef kemik → (kaynak eklem(ler), T-pozunda yön için hedef nokta)
SRC_MAP = {
	"Hips": (["Hips"], ("hipc", "Spine")),
	"Spine": (["LowerBack"], ("LowerBack", "Spine1")),
	"Chest": (["Spine"], ("Spine", "Spine1")),
	"UpperChest": (["Spine1"], ("Spine1", "Neck1")),
	"Neck": (["Neck", "Neck1"], ("Neck1", "Head")),
	"Head": (["Head"], ("Head", "Head/end")),
}
for _s, S in SIDES:
	SRC_MAP.update({
		S + "Shoulder": ([S + "Shoulder"], (S + "Shoulder", S + "Arm")),
		S + "UpperArm": ([S + "Arm"], (S + "Arm", S + "ForeArm")),
		S + "LowerArm": ([S + "ForeArm"], (S + "ForeArm", S + "Hand")),
		S + "Hand": ([S + "Hand"], (S + "Hand", S + "HandIndex1")),
		S + "UpperLeg": ([S + "UpLeg"], (S + "UpLeg", S + "Leg")),
		S + "LowerLeg": ([S + "Leg"], (S + "Leg", S + "Foot")),
		S + "Foot": ([S + "Foot"], (S + "Foot", S + "ToeBase")),
		S + "Toes": ([S + "ToeBase"], (S + "ToeBase", S + "ToeBase/end")),
	})

# T-pozu yönüne hizalanan uzuvlar (diğerleri dinlenme = T-pozu kabul edilir)
ALIGN = {"UpperArm", "LowerArm", "Hand", "UpperLeg", "LowerLeg"}

# yer teması: (hedef nokta, kaynak nokta, yarıçap m) — "kemik:head|tail|mid"
def contact_points(rig):
	pts = [("Hips:head", "hipc", 0.11), ("Chest:head", "Spine1", 0.11), ("Head:mid", "Head/mid", 0.10)]
	for _s, S in SIDES:
		pts += [
			(S + "Foot:head", S + "Foot", float(rig.hr[S + "Foot"][2])),
			(S + "Toes:head", S + "ToeBase", float(rig.hr[S + "Toes"][2])),
			(S + "Toes:tail", S + "ToeBase/end", float(rig.tr[S + "Toes"][2])),
			(S + "LowerLeg:head", S + "Leg", 0.055),
			(S + "LowerArm:head", S + "ForeArm", 0.04),
			(S + "Hand:head", S + "Hand", 0.03),
			(S + "Hand:tail", S + "HandIndex1", 0.025),
			(S + "UpperArm:head", S + "Arm", 0.06),
		]
	return pts


class Rig:
	"""Blender'dan okunan dinlenme verisi (armatür uzayı = dünya)."""
	def __init__(self, layout, arm):
		self.names = [b["name"] for b in layout]
		self.parent = {b["name"]: b["parent"] for b in layout}
		self.Rr = {}
		self.hr = {}
		self.tr = {}
		self.M = {}
		for n in self.names:
			bb = arm.bones[n]
			M = np.array(bb.matrix_local)
			self.M[n] = M
			self.Rr[n] = M[:3, :3].copy()
			self.hr[n] = np.array(bb.head_local)
			self.tr[n] = np.array(bb.tail_local)
		self.L = {n: float(np.linalg.norm(self.tr[n] - self.hr[n])) for n in self.names}
		self.off = {}
		for n in self.names:
			p = self.parent[n]
			if p:
				self.off[n] = self.Rr[p].T @ (self.hr[n] - self.hr[p])

	def fk(self, W, root_pos, hips_pos):
		"""W: ad→(F,3,3) dünya dönüşleri. Baş ve uç konumları döndürür."""
		head, tail = {}, {}
		for n in self.names:
			p = self.parent[n]
			if n == "Root":
				head[n] = root_pos
			elif n == "Hips":
				head[n] = hips_pos
			else:
				head[n] = head[p] + np.einsum("fij,j->fi", W[p], self.off[n])
			tail[n] = head[n] + W[n][:, :, 1] * self.L[n]
		return head, tail

	def fill_rest(self, W, F, skip=()):
		"""Eşlenmemiş kemikler: ebeveyne göre dinlenme yerel dönüşü."""
		for n in self.names:
			if n in W or n in skip:
				continue
			p = self.parent[n]
			rel = self.Rr[p].T @ self.Rr[n] if p else self.Rr[n]
			W[n] = (W[p] @ rel) if p else np.tile(self.Rr[n], (F, 1, 1))
		return W


def point(name, head, tail):
	b, k = name.split(":")
	if k == "head":
		return head[b]
	if k == "tail":
		return tail[b]
	return 0.5 * (head[b] + tail[b])


# ------------------------------------------------------------------ yeniden hedefleme
RELAX = {"ThumbMetacarpal": 0.1, "ThumbProximal": 0.2, "IndexProximal": 0.25, "IndexIntermediate": 0.3,
	"MiddleProximal": 0.35, "MiddleIntermediate": 0.4}


def finger_curl(rig, palm, W, side, curls):
	"""Parmakları avuca doğru büker (curls: parmak adı → radyan, yerel birikimli)."""
	S = side
	for f in FINGERS:
		n = S + f
		p = rig.parent[n]
		Wn = W[p] @ (rig.Rr[p].T @ rig.Rr[n])
		F = Wn.shape[0]
		d_rest = normalize(rig.tr[n] - rig.hr[n])
		# avuç normali ve parmak yönü el dinlenme çerçevesinde → anlık dünya
		Wh = W[S + "Hand"]
		pl = rig.Rr[S + "Hand"].T @ palm[S]
		dl = rig.Rr[S + "Hand"].T @ d_rest
		ax_local = normalize(np.cross(dl, pl))
		if f.startswith("Thumb"):
			# başparmak avuç üstünden serçe parmağa doğru kapanır: eksen el yönüne yakın
			vt = rig.Rr[S + "Hand"].T @ normalize(rig.tr[n] - rig.hr[n])
			ax_local = dl if np.dot(np.cross(dl, vt), pl) > 0 else -dl
		ang = curls.get(f, 0.0)
		R = np.array([axis_angle(np.einsum("ij,j->i", Wh[i], ax_local), ang) for i in range(F)])
		W[n] = R @ Wn
	return W


def retarget(c, rig, palm):
	B = bvhmod.BVH(cp(cmu_path(c["src"])))
	P, R = B.fk()
	P0, R0 = P[0].copy(), R[0].copy()
	ix = B.index

	def spoint(Px, Rx, nm):
		if nm == "hipc":
			return 0.5 * (Px[..., ix["LeftUpLeg"], :] + Px[..., ix["RightUpLeg"], :])
		if nm.endswith("/end") or nm.endswith("/mid"):
			j = nm.split("/")[0]
			k = ix[j]
			e = bvhmod.C @ B.joints[k].end * bvhmod.CMU_UNIT
			f = 0.5 if nm.endswith("/mid") else 1.0
			return Px[..., k, :] + f * np.einsum("...ij,j->...i", Rx[..., k, :, :], e)
		return Px[..., ix[nm], :]

	a, b = c["fr"]
	b = min(b, B.nframes - 1)
	fr = np.arange(a, b + 1, SRC_FPS // FPS)
	P, R = P[fr], R[fr]
	F = len(fr)
	# ölçek: bacak boyu oranı
	src_leg = np.linalg.norm(P0[ix["LeftUpLeg"]] - P0[ix["LeftLeg"]]) + np.linalg.norm(P0[ix["LeftLeg"]] - P0[ix["LeftFoot"]])
	tgt_leg = rig.L["LeftUpperLeg"] + rig.L["LeftLowerLeg"]
	k = tgt_leg / src_leg
	# yön: döngülerde yürüme yönü, diğerlerinde ilk karedeki kalça yönü → +Y
	hipc = spoint(P, R, "hipc")
	right = np.einsum("fij,jk,k->fi", R[:, ix["Hips"]], R0[ix["Hips"]].T, np.array([1.0, 0, 0]))
	fwd = np.cross(np.array([0, 0, 1.0]), right)
	disp = hipc[-1, :2] - hipc[0, :2]
	if c.get("loop") and c.get("heading") != "face" and np.linalg.norm(disp) > 0.6:
		d = disp
	elif c.get("loop"):
		d = normalize(fwd[:, :2]).mean(axis=0)
	else:
		d = normalize(fwd[:3, :2]).mean(axis=0)
	phi = math.pi / 2 - math.atan2(d[1], d[0])
	Yc = rot_z(phi)
	org = np.array([hipc[0, 0], hipc[0, 1], 0.0])
	P = np.einsum("ij,fkj->fki", Yc, P - org)
	R = np.einsum("ij,fkjl->fkil", Yc, R)
	# hedef dünya dönüşleri
	W = {}
	for tb, (sj, (pa, pb)) in SRC_MAP.items():
		if tb.replace("Left", "").replace("Right", "") in ALIGN:
			# uzuv: A-pozu (hedef) ile T-pozu (kaynak) arasındaki fark giderilir
			d_s = spoint(P0, R0, pb) - spoint(P0, R0, pa)
			d_t = rig.tr[tb] - rig.hr[tb]
			Tb = arc(d_t, d_s) @ rig.Rr[tb]
		else:
			# gövde, köprücük, ayak: kaynağın T-pozu = hedefin doğal dinlenme duruşu
			Tb = rig.Rr[tb]
		Ds = [R[:, ix[j]] @ R0[ix[j]].T for j in sj]
		D = Ds[0] if len(Ds) == 1 else mat_slerp(Ds[0], Ds[1], 0.5)
		W[tb] = D @ Tb
	hips = spoint(P, R, "hipc") * k
	root = np.zeros((F, 3))
	W["Root"] = np.tile(rig.Rr["Root"], (F, 1, 1))
	W = rig.fill_rest(W, F)
	for _s, S in SIDES:
		W = finger_curl(rig, palm, W, S, RELAX)
	# yere oturtma: hedefin en alt temas noktası kaynağınkini izlesin
	head, tail = rig.fk(W, root, hips)
	cps = contact_points(rig)
	tl = np.min(np.stack([point(t, head, tail)[:, 2] - r for t, s, r in cps]), axis=0)
	sl = np.min(np.stack([spoint(P, R, s)[:, 2] * k - r for t, s, r in cps]), axis=0)
	g = float(np.clip(np.percentile(sl, 3), -0.06, 0.06))
	dz = gauss_smooth((sl - g) - tl, 1.0)
	hips[:, 2] += dz
	return dict(W=W, hips=hips, F=F, k=k, P=P, R=R, B=B)


def loop_cut(c, rig, res):
	"""En iyi döngü kesiti + çapraz geçiş + yerinde (kök hareketi çıkarılmış)."""
	W, hips, F = res["W"], res["hips"], res["F"]
	root = np.zeros((F, 3))
	head, tail = rig.fk(W, root, hips)
	keys = ["LeftFoot", "RightFoot", "LeftToes", "RightToes", "LeftLowerLeg", "RightLowerLeg", "LeftHand", "RightHand",
		"LeftLowerArm", "RightLowerArm", "Head"]
	feat = np.concatenate([head[n] - hips for n in keys] + [hips[:, 2:3] * 2.0], axis=1)
	vel = np.gradient(feat, axis=0)
	N = 6
	lo, hi = int(round(c["cyc"][0] * FPS)), int(round(c["cyc"][1] * FPS))
	best = None
	for s in range(N, F - lo):
		for L in range(lo, min(hi, F - 1 - s) + 1):
			e = s + L
			cost = np.sum((feat[s] - feat[e]) ** 2) + 4.0 * np.sum((vel[s] - vel[e]) ** 2)
			if best is None or cost < best[0]:
				best = (cost, s, L)
	if best is None:
		raise SystemExit("%s: döngü bulunamadı (aralık kısa)" % c["name"])
	cost, s, L = best
	speed_v = (hips[s + L, :2] - hips[s, :2]) * FPS / L
	speed = float(np.linalg.norm(speed_v))
	# yerinde: doğrusal sürüklenmeyi çıkar
	t = np.arange(F) - s
	hip_ip = hips.copy()
	hip_ip[:, :2] -= np.outer(t, speed_v / FPS)
	# çapraz geçiş: döngünün son N karesi, başlangıçtan önceki karelere doğru
	Wn = {n: W[n].copy() for n in W}
	for i in range(N):
		w = (i + 1) / N
		e, p = s + L - N + i, s - N + i
		hip_ip[e] = (1 - w) * hip_ip[e] + w * hip_ip[p]
		for n in Wn:
			Wn[n][e] = mat_slerp(W[n][e], W[n][p], w)
	sel = np.r_[np.arange(s, s + L), s]   # son kare = ilk kare
	Wc = {n: Wn[n][sel] for n in Wn}
	hc = hip_ip[sel]
	hc[:, :2] -= hc[:-1, :2].mean(axis=0)
	if c.get("crouch"):
		# daha derin çömelme: kalça alçalır, öne eğilir; ayaklar yerinde kalır (bacak IK)
		drop, lean = c["crouch"]
		head0, _ = rig.fk(Wc, np.zeros((L + 1, 3)), hc)
		ank = {S: head0[S + "Foot"].copy() for _s, S in SIDES}
		hc = hc.copy()
		hc[:, 2] -= drop
		Wc = rotate_subtree(rig, Wc, "Spine", axis_angle([1, 0, 0], math.radians(lean)))
		for _s, S in SIDES:
			Wc = leg_ik(rig, Wc, hc, S, ank[S], np.ones(L + 1))
	slide = {}
	if speed > 0.3:
		Wc, slide = foot_lock(rig, Wc, hc, speed_v, L)
	# hız vektörü Godot çerçevesinde (ileri -Z, sağ +X): B(x, y) → (x, 0, -y)
	info = dict(loop=True, frames=L, length=L / FPS, speed=round(speed, 3),
		velocity=[round(float(speed_v[0]), 3), 0.0, round(float(-speed_v[1]), 3)], src_frames=[int(c["fr"][0] + 4 * s), int(c["fr"][0] + 4 * (s + L))],
		cost=round(float(cost), 4), foot_slide=slide)
	return Wc, hc, np.zeros((L + 1, 3)), np.zeros(L + 1), info


def rotate_subtree(rig, W, bone, Rw):
	"""Kemik ve tüm alt kemiklerinin dünya dönüşüne Rw uygula (kemik başı etrafında)."""
	W = dict(W)
	todo = [bone]
	while todo:
		n = todo.pop()
		W[n] = np.einsum("ij,fjk->fik", Rw, W[n])
		todo += [m for m in rig.names if rig.parent[m] == n]
	return W


def leg_ik(rig, W, hips, S, target, wgt):
	"""İki kemikli bacak IK: ayak bileği hedefe (ağırlıkla), diz düzlemi korunur, ayak dünya yönü korunur."""
	F = hips.shape[0]
	head, tail = rig.fk(W, np.zeros((F, 3)), hips)
	U, Lo = S + "UpperLeg", S + "LowerLeg"
	Wu, Wl = W[U].copy(), W[Lo].copy()
	for i in range(F):
		if wgt[i] <= 1e-4:
			continue
		hp = head[U][i]
		kn = head[Lo][i]
		an = head[S + "Foot"][i]
		tgt = an + wgt[i] * (target[i] - an)
		el, wr = two_bone(hp, rig.L[U], rig.L[Lo], tgt, kn - hp)
		Wu[i] = arc(kn - hp, el - hp) @ Wu[i]
		Wl[i] = arc(an - kn, wr - el) @ Wl[i]
	W = dict(W)
	W[U], W[Lo] = Wu, Wl
	return W


def foot_lock(rig, W, hips, speed_v, L):
	"""Yerinde döngüde ayak kaymasını gider: temas karelerinde bilek dünya konumu sabitlenir
	(dünya = yerinde + hız·t), bacak IK ile. Döngü sarmalı dikkate alınır (kare L = kare 0)."""
	F = L + 1
	head, _ = rig.fk(W, np.zeros((F, 3)), hips)
	t = np.arange(F) / FPS
	v3 = np.array([speed_v[0], speed_v[1], 0.0])
	report = {}
	for _s, S in SIDES:
		ank = head[S + "Foot"][:L]
		world = ank + np.outer(t[:L], v3)
		z = ank[:, 2]
		# döngüsel hız (kare L-1 → 0 geçişinde dünya konumu bir tur kayar)
		nxt = np.r_[world[1:], (ank[0] + v3 * L / FPS)[None]]
		sp = np.linalg.norm((nxt - world)[:, :2], axis=1) * FPS
		contact = (z < z.min() + 0.035) & (sp < max(0.6, 0.25 * np.linalg.norm(v3)))
		before = float(np.mean(sp[contact])) if contact.any() else 0.0
		if not contact.any():
			continue
		# döngüsel ardışık temas parçaları
		idx = np.nonzero(contact)[0]
		segs, cur = [], [idx[0]]
		for a, b in zip(idx[:-1], idx[1:]):
			if b == a + 1:
				cur.append(b)
			else:
				segs.append(cur)
				cur = [b]
		segs.append(cur)
		if len(segs) > 1 and segs[0][0] == 0 and segs[-1][-1] == L - 1:
			segs[0] = [i - L for i in segs[-1]] + segs[0]
			segs.pop()
		target = ank.copy()
		wgt = np.zeros(L)
		ramp = 3
		for sg in segs:
			# çapa: parçanın ortasındaki dünya konumu
			mid = sg[len(sg) // 2]
			anchor = ank[mid % L] + v3 * mid / FPS
			for j in range(sg[0] - ramp, sg[-1] + ramp + 1):
				w = 1.0 if sg[0] <= j <= sg[-1] else 1.0 - (min(abs(j - sg[0]), abs(j - sg[-1])) / (ramp + 1.0))
				k = j % L
				if w > wgt[k]:
					wgt[k] = w
					target[k] = anchor - v3 * j / FPS
					target[k, 2] = ank[k, 2]
		W = leg_ik(rig, W, hips, S, np.r_[target, target[:1]], np.r_[wgt, wgt[:1]])
		head2, _ = rig.fk(W, np.zeros((F, 3)), hips)
		w2 = head2[S + "Foot"][:L] + np.outer(t[:L], v3)
		nx2 = np.r_[w2[1:], (head2[S + "Foot"][0] + v3 * L / FPS)[None]]
		sp2 = np.linalg.norm((nx2 - w2)[:, :2], axis=1) * FPS
		report[S] = [round(before, 3), round(float(np.mean(sp2[contact])), 3)]
	return W, report


def once_cut(c, rig, res):
	"""Tek seferlik: kök (Root) yatay kayma (+ dönüş kliplerinde sapma) taşır."""
	W, hips, F = res["W"], res["hips"], res["F"]
	root = np.zeros((F, 3))
	root[:, :2] = gauss_smooth(hips[:, :2], 6.0)
	root[:, :2] -= root[0, :2]
	yaw = np.zeros(F)
	if c.get("turn"):
		right = W["Hips"][:, :, 0]
		ang = np.unwrap(np.arctan2(right[:, 1], right[:, 0]))
		yaw = gauss_smooth(ang - ang[0], 5.0)
		# yerinde dönüş: yatay kayma yok sayılır (kök yalnız döner)
		root[:, :2] = 0.0
	info = dict(loop=False, frames=F - 1, length=(F - 1) / FPS, root_motion=[round(float(root[-1, 0]), 3), round(float(root[-1, 1]), 3), round(math.degrees(float(yaw[-1])), 1)],
		src_frames=[int(c["fr"][0]), int(c["fr"][0] + 4 * (F - 1))])
	return W, hips, root, yaw, info


# ------------------------------------------------------------------ tüfek katmanı (anahtarlanmış poz)
def two_bone(sh, L1, L2, target, pole):
	d = target - sh
	dist = float(np.linalg.norm(d))
	dist = min(max(dist, abs(L1 - L2) + 1e-3), L1 + L2 - 1e-3)
	u = normalize(d)
	a = (L1 * L1 - L2 * L2 + dist * dist) / (2 * dist)
	h = math.sqrt(max(L1 * L1 - a * a, 0.0))
	pp = normalize(pole - u * np.dot(pole, u))
	elbow = sh + u * a + pp * h
	wrist = sh + u * dist
	return elbow, wrist


def rifle_frame(rig, kind):
	"""Tüfek çerçevesi (dinlenme gövdesinde): dipçik ucu, eksenler X (sağ), Y (namlu), Z (üst)."""
	sh = rig.hr["RightUpperArm"]
	butt = sh + np.array([-0.075, 0.10, 0.015])
	Y = normalize(np.array([-0.08, 1.0, 0.0]))
	Z = np.array([0, 0, 1.0])
	if kind == "ready":
		# alçak hazır: namlu 38° aşağı, dipçik omuzda biraz alçalmış
		Xa = normalize(np.cross(Y, Z))
		Rp = axis_angle(Xa, -math.radians(38))
		Y = Rp @ normalize(np.array([-0.32, 1.0, 0.0]))
		Z = Rp @ Z
		butt = butt + np.array([0.0, -0.01, -0.08])
	X = normalize(np.cross(Y, Z))
	Z = np.cross(X, Y)
	return butt, X, Y, Z


def rifle_pose(rig, palm, kind):
	W = {n: rig.Rr[n][None].copy() for n in rig.names}
	W = {n: W[n] for n in W}
	butt, X, Y, Z = rifle_frame(rig, kind)
	grip = butt + Y * 0.20 - Z * 0.085
	hg = butt + Y * 0.42 - Z * 0.03
	# sağ el: tabanca kabzası (kabza ekseni aşağı-geri 18°), avuç sola bakar
	g_ax = normalize(-Z * math.cos(math.radians(18)) - Y * math.sin(math.radians(18)))
	dR = normalize(Y - g_ax * np.dot(Y, g_ax))
	nR = -X
	wR = grip - dR * 0.075 + X * 0.022
	# sol el: el kundağının altında, avuç yukarı, parmaklar sağ-ileri
	dL = normalize(X * 0.75 + Y * 0.65)
	nL = Z
	wL = hg - Z * 0.042 - dL * 0.07
	out = {}
	clav = {"Left": -math.radians(14 if kind == "aim" else 8), "Right": math.radians(4)}
	lift = {"Left": math.radians(6 if kind == "aim" else 2), "Right": math.radians(8 if kind == "aim" else 3)}
	poles = {"Right": normalize(np.array([0.8, -0.3, -0.6])), "Left": normalize(np.array([-0.35, 0.05, -1.0]))}
	targets = {"Right": (wR, dR, nR), "Left": (wL, dL, nL)}
	for S in ("Left", "Right"):
		# köprücük kemiği: öne (protraksiyon) ve yukarı
		sgn = -1.0 if S == "Left" else 1.0
		cR = axis_angle([0, 0, 1], clav[S]) @ axis_angle([0, 1, 0], -sgn * lift[S])
		W[S + "Shoulder"] = (cR @ rig.Rr[S + "Shoulder"])[None]
		sh = rig.hr[S + "Shoulder"] + W[S + "Shoulder"][0] @ rig.off[S + "UpperArm"]
		wt, dd, nn = targets[S]
		el, wr = two_bone(sh, rig.L[S + "UpperArm"], rig.L[S + "LowerArm"], wt, poles[S])
		u_r = normalize(rig.tr[S + "UpperArm"] - rig.hr[S + "UpperArm"])
		f_r = normalize(rig.tr[S + "LowerArm"] - rig.hr[S + "LowerArm"])
		hinge_r = normalize(np.cross(u_r, f_r))
		u = normalize(el - sh)
		f = normalize(wr - el)
		hinge = normalize(np.cross(u, f))
		Wu = triad(u_r, hinge_r, u, hinge) @ rig.Rr[S + "UpperArm"]
		Wl = triad(f_r, hinge_r, f, hinge) @ rig.Rr[S + "LowerArm"]
		d_rest = normalize(rig.tr[S + "Hand"] - rig.hr[S + "Hand"])
		Wh = triad(d_rest, palm[S], dd, nn) @ rig.Rr[S + "Hand"]
		# önkol burulması: el burulmasının yarısı önkola
		q = mat_to_quat(Wl.T @ Wh)
		tw = 2.0 * math.atan2(q[2], q[0])
		Wl = Wl @ axis_angle([0, 1, 0], 0.5 * tw)
		W[S + "UpperArm"] = Wu[None]
		W[S + "LowerArm"] = Wl[None]
		W[S + "Hand"] = Wh[None]
		out[S] = dict(elbow=el, wrist=wr, reach=float(np.linalg.norm(wt - sh)), maxreach=rig.L[S + "UpperArm"] + rig.L[S + "LowerArm"])
	# parmaklar: sağ kabzayı kavrar (işaret tetikte), sol el kundağı sarar
	for f in FINGERS:
		W.pop("Left" + f, None)
		W.pop("Right" + f, None)
	W = rig.fill_rest(W, 1)
	W = finger_curl(rig, palm, W, "Right", {"ThumbMetacarpal": 0.35, "ThumbProximal": 0.6, "IndexProximal": 0.55, "IndexIntermediate": 0.5,
		"MiddleProximal": 1.3, "MiddleIntermediate": 1.3})
	W = finger_curl(rig, palm, W, "Left", {"ThumbMetacarpal": 0.3, "ThumbProximal": 0.45, "IndexProximal": 0.9, "IndexIntermediate": 0.9,
		"MiddleProximal": 1.0, "MiddleIntermediate": 1.0})
	M = np.eye(4)
	M[:3, 0], M[:3, 1], M[:3, 2], M[:3, 3] = X, Y, Z, butt
	return W, M, out


# ------------------------------------------------------------------ Blender
def make_armature(bpy, scn, layout):
	arm = bpy.data.armatures.new("Armature")
	ao = bpy.data.objects.new("Armature", arm)
	scn.collection.objects.link(ao)
	bpy.context.view_layer.objects.active = ao
	bpy.ops.object.mode_set(mode='EDIT')
	for b in layout:
		eb = arm.edit_bones.new(b["name"])
		eb.head = b["head"].tolist()
		eb.tail = b["tail"].tolist()
		eb.align_roll(b["z"].tolist())
		if b["parent"]:
			eb.parent = arm.edit_bones[b["parent"]]
	bpy.ops.object.mode_set(mode='OBJECT')
	return ao, arm


def blender_build(args, clip_list):
	import bpy
	import bmesh
	from mathutils import Matrix

	bpy.ops.wm.read_factory_settings(use_empty=True)
	scn = bpy.context.scene
	scn.render.fps = FPS

	base, sk, vb, faces, used = build_human()
	layout, palm = rig_layout(sk, vb)
	vw = vertex_weights(used)
	idx = {v: i for i, v in enumerate(used)}

	# --- malzemeler
	# doğrusal (linear) renkler — glTF baseColorFactor doğrusaldır (sRGB ≈ yeşil-haki üniforma)
	MAT = {"uniform": (0.105, 0.115, 0.055), "boots": (0.022, 0.016, 0.011), "gloves": (0.035, 0.03, 0.022),
		"skin": (0.55, 0.32, 0.2), "eyes": (0.01, 0.008, 0.006), "helmet": (0.085, 0.095, 0.045), "weapon": (0.014, 0.014, 0.016)}
	mats = {}
	for n, col in MAT.items():
		m = bpy.data.materials.new(n)
		m.diffuse_color = (*col, 1.0)
		m.use_nodes = True
		bsdf = m.node_tree.nodes.get("Principled BSDF")
		if bsdf:
			bsdf.inputs["Base Color"].default_value = (*col, 1.0)
			bsdf.inputs["Roughness"].default_value = 0.85 if n != "weapon" else 0.5
		mats[n] = m
	order = list(MAT.keys())

	# --- örgü
	verts = vb[used]
	polys = [[idx[v] for v, t in cc] for g, cc in faces]
	me = bpy.data.meshes.new("SoldierBody")
	me.from_pydata(verts.tolist(), [], polys)
	uvl = me.uv_layers.new(name="UVMap")
	uv = []
	for g, cc in faces:
		for v, t in cc:
			uv.extend(base.vt[t] if t >= 0 else (0.0, 0.0))
	uvl.data.foreach_set("uv", uv)
	for n in order:
		me.materials.append(mats[n])
	# bölge: baskın kemik + yükseklik
	z_neck = layout[[b["name"] for b in layout].index("Neck")]["head"][2]
	mi = []
	for (g, cc) in faces:
		if g != "body":
			mi.append(order.index("eyes"))
			continue
		score = {}
		zs = 0.0
		for v, t in cc:
			zs += vb[v, 2]
			for bn, w in vw[v]:
				score[bn] = score.get(bn, 0.0) + w
		dom = max(score.items(), key=lambda kv: kv[1])[0]
		z = zs / len(cc)
		if dom in ("Head", "Neck"):
			mi.append(order.index("skin") if z > z_neck - 0.01 else order.index("uniform"))
		elif dom.endswith("Hand") or any(dom.endswith(f) for f in FINGERS):
			mi.append(order.index("gloves"))
		elif z < 0.19 and (dom.endswith("Foot") or dom.endswith("Toes") or dom.endswith("LowerLeg")):
			mi.append(order.index("boots"))
		else:
			mi.append(order.index("uniform"))
	me.polygons.foreach_set("material_index", mi)
	me.shade_smooth()
	body = bpy.data.objects.new("SoldierBody", me)
	scn.collection.objects.link(body)
	groups = {}
	for b in layout:
		groups[b["name"]] = body.vertex_groups.new(name=b["name"])
	for v in used:
		for bn, w in vw[v]:
			groups[bn].add([idx[v]], w, 'REPLACE')

	# --- miğfer (Head kemiğine tam ağırlık)
	headv = np.array([vb[v] for v in used if vw[v][0][0] == "Head" and vw[v][0][1] > 0.9])
	top = headv[:, 2].max()
	hx = (headv[:, 0].max() - headv[:, 0].min()) * 0.5
	ys = headv[headv[:, 2] > top - 0.1, 1]
	hy = (ys.max() - ys.min()) * 0.5
	cy = 0.5 * (ys.max() + ys.min())
	rim = top - 0.105
	bm = bmesh.new()
	bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=12, radius=1.0)
	for v in list(bm.verts):
		if v.co.z < -0.12:
			bm.verts.remove(v)
	for v in bm.verts:
		z = max(v.co.z, -0.12)
		v.co.x *= hx * 1.22
		v.co.y *= hy * 1.18
		v.co.z = z * (top + 0.03 - rim)
		v.co.y += cy - 0.005
		v.co.z += rim
	hm = bpy.data.meshes.new("Helmet")
	bm.to_mesh(hm)
	bm.free()
	hm.materials.append(mats["helmet"])
	hm.shade_smooth()
	helmet = bpy.data.objects.new("Helmet", hm)
	scn.collection.objects.link(helmet)
	hg = helmet.vertex_groups.new(name="Head")
	hg.add(list(range(len(hm.vertices))), 1.0, 'REPLACE')
	# gövdeye kat (tek deri örgü)
	bpy.context.view_layer.objects.active = body
	body.select_set(True)
	helmet.select_set(True)
	bpy.ops.object.join()
	body = bpy.context.view_layer.objects.active
	body.select_set(False)

	# --- inceltme (simetrik)
	if args.decimate < 0.999:
		mod = body.modifiers.new("dec", 'DECIMATE')
		mod.ratio = args.decimate
		mod.use_symmetry = True
		mod.symmetry_axis = 'X'
		with bpy.context.temp_override(object=body, active_object=body):
			bpy.ops.object.modifier_apply(modifier=mod.name)
	# inceltme ara değerlemesi etki sayısını artırır: en çok 4 kemik, toplam 1
	vgs = body.vertex_groups
	for v in body.data.vertices:
		gs = sorted(((g.group, g.weight) for g in v.groups), key=lambda gw: -gw[1])
		keep = [(gi, w) for gi, w in gs[:4] if w > 0.01]
		tot = sum(w for _, w in keep) or 1.0
		for gi, w in gs:
			vgs[gi].remove([v.index])
		for gi, w in keep:
			vgs[gi].add([v.index], w / tot, 'REPLACE')
	print("en çok kemik etkisi / köşe:", max(len(v.groups) for v in body.data.vertices))

	# --- armatür
	ao, arm = make_armature(bpy, scn, layout)
	body.parent = ao
	am = body.modifiers.new("Armature", 'ARMATURE')
	am.object = ao
	rig = Rig(layout, arm)

	# --- tüfek (sağ el kemiğine bağlı ayrı düğüm: "Rifle")
	Wa, Ma, outa = rifle_pose(rig, palm, "aim")
	rme = rifle_mesh(bpy, bmesh, mats["weapon"])
	rifle = bpy.data.objects.new("Rifle", rme)
	scn.collection.objects.link(rifle)
	hand_head = outa["Right"]["wrist"]
	Mh = np.eye(4)
	Mh[:3, :3] = Wa["RightHand"][0]
	Mh[:3, 3] = hand_head
	Mh[:3, 3] += Wa["RightHand"][0][:, 1] * rig.L["RightHand"]   # kemik ebeveynliği ucu kullanır
	rel = np.linalg.inv(Mh) @ Ma
	rifle.parent = ao
	rifle.parent_type = 'BONE'
	rifle.parent_bone = "RightHand"
	rifle.matrix_parent_inverse = Matrix.Identity(4)
	rifle.matrix_basis = Matrix(rel.tolist())

	# --- klipler
	ao.animation_data_create()
	meta = {}
	for c in clip_list:
		res = retarget(c, rig, palm)
		if c.get("loop"):
			W, hips, root, yaw, info = loop_cut(c, rig, res)
		else:
			W, hips, root, yaw, info = once_cut(c, rig, res)
		info.update(source="CMU %s" % c["src"], desc=c["tr"], scale=round(res["k"], 3))
		# Godot ad soneki: "-loop" → LOOP_LINEAR olarak içe aktarılır, sonek atılır (ad: "walk")
		write_action(bpy, ao, rig, c["name"] + ("-loop" if c.get("loop") else ""), W, hips, root, yaw)
		meta[c["name"]] = info
		print("klip %-12s kare %4d  süre %.2fs  %s" % (c["name"], info["frames"], info["length"],
			("hız %.2f m/s" % info["speed"]) if info["loop"] else ("kök %s" % info["root_motion"])))
	for kind in ("ready", "aim"):
		W, M, out = rifle_pose(rig, palm, kind)
		W2 = {n: np.repeat(W[n], 2, axis=0) for n in W}
		hips = np.repeat(rig.hr["Hips"][None], 2, axis=0)
		write_action(bpy, ao, rig, "rifle_" + kind, W2, hips, np.zeros((2, 3)), np.zeros(2), only=ARM_LAYER)
		meta["rifle_" + kind] = dict(loop=False, frames=1, length=1.0 / FPS, layer=True, source="anahtar poz (IK)",
			desc="tüfek " + ("alçak hazır" if kind == "ready" else "nişan") + " üst gövde katmanı", reach={k: round(v["reach"], 3) for k, v in out.items()})
		print("poz rifle_%s erişim %s" % (kind, {k: (round(v["reach"], 3), round(v["maxreach"], 3)) for k, v in out.items()}))
	ao.animation_data.action = None
	for pb in ao.pose.bones:
		pb.rotation_quaternion = (1, 0, 0, 0)
		pb.location = (0, 0, 0)

	# --- dışa aktarım
	out = os.path.join(ROOT, args.out)
	os.makedirs(os.path.dirname(out), exist_ok=True)
	bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, export_animations=True,
		export_animation_mode='ACTIONS', export_force_sampling=True, export_anim_slide_to_zero=True,
		export_optimize_animation_size=True, export_skins=True, export_influence_nb=4, export_materials='EXPORT',
		export_image_format='NONE', export_def_bones=False, export_rest_position_armature=True, export_reset_pose_bones=True)
	tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
	js = dict(
		model=os.path.basename(out), height_m=HEIGHT, fps=FPS, forward="-Z (Godot), sağ el +X", tris=tris,
		bones=[dict(name=b["name"], parent=b["parent"]) for b in layout],
		arm_layer_bones=ARM_LAYER,
		rifle_node="Rifle", rifle_hand_bone="RightHand",
		clips=meta,
		sources=dict(makehuman=dict(repo="makehumancommunity/makehuman", commit=MH_SHA, license="CC0 1.0 (varlıklar)"),
			cmu=dict(repo="una-dinosauria/cmu-mocap", commit=CMU_SHA, license="CMU Graphics Lab Motion Capture Database — araştırma ve ticari kullanım serbest")),
	)
	with open(os.path.splitext(out)[0] + ".json", "w") as f:
		json.dump(js, f, indent=1, ensure_ascii=False)
	write_import_settings(out, meta)
	print("yazıldı:", out, "%.1f MB" % (os.path.getsize(out) / 1e6), "üçgen:", tris)


def write_import_settings(out, meta):
	"""Godot .import: sabit izler silinmesin (tüfek pozu yalnız sabit izlerden oluşur). Döngü bilgisi ad sonekinde."""
	p = out + ".import"
	subs = "_subresources={}"
	if os.path.exists(p):
		lines = open(p).read().splitlines()
	else:
		lines = ["[remap]", "", 'importer="scene"', "importer_version=1", 'type="PackedScene"', "", "[params]", ""]
	res, depth = [], 0
	for ln in lines:
		if depth > 0:
			# çok satırlı _subresources değeri: süslü parantez derinliği sıfırlanana dek atla
			depth += ln.count("{") - ln.count("}")
			continue
		if ln.startswith("animation/remove_immutable_tracks=") or ln.startswith("animation/fps="):
			continue
		if ln.startswith("_subresources="):
			depth = ln.count("{") - ln.count("}")
			continue
		res.append(ln)
	i = res.index("[params]") + 1
	res[i:i] = ["", "animation/fps=%d" % FPS, "animation/remove_immutable_tracks=false", subs]
	with open(p, "w") as f:
		f.write("\n".join(res) + "\n")


def rifle_mesh(bpy, bmesh, mat):
	"""Basit karabina (dipçik ucu orijinde, namlu +Y, üst +Z)."""
	from mathutils import Matrix
	bm = bmesh.new()

	def box(c, s, rx=0.0):
		M = Matrix.Translation(c) @ Matrix.Rotation(rx, 4, 'X') @ Matrix.Diagonal((s[0], s[1], s[2], 1.0))
		bmesh.ops.create_cube(bm, size=1.0, matrix=M)

	box((0, 0.11, -0.02), (0.038, 0.22, 0.085))           # dipçik
	box((0, 0.31, 0.012), (0.045, 0.24, 0.06))            # gövde
	box((0, 0.20, -0.07), (0.03, 0.04, 0.09), 0.31)       # kabza
	box((0, 0.335, -0.09), (0.028, 0.06, 0.15), -0.18)    # şarjör
	box((0, 0.51, 0.0), (0.05, 0.18, 0.055))              # el kundağı
	box((0, 0.67, 0.005), (0.018, 0.16, 0.018))           # namlu
	box((0, 0.33, 0.055), (0.022, 0.16, 0.025))           # üst ray / nişangâh
	me = bpy.data.meshes.new("Rifle")
	bm.to_mesh(me)
	bm.free()
	me.materials.append(mat)
	return me


def write_action(bpy, ao, rig, name, W, hips, root, yaw, only=None):
	"""Dünya dönüşlerinden poz kemiği yerel dördeyleri; Root ve Hips konumu."""
	F = hips.shape[0]
	act = bpy.data.actions.new(name)
	act.use_fake_user = True
	ao.animation_data.action = act
	# kök poz matrisleri
	Rroot = np.einsum("fij,jk->fik", np.array([rot_z(a) for a in yaw]), rig.Rr["Root"])
	Mroot = np.tile(np.eye(4), (F, 1, 1))
	Mroot[:, :3, :3] = Rroot
	Mroot[:, :3, 3] = root
	W = dict(W)
	W["Root"] = Rroot
	Wloc = {}
	for n in rig.names:
		p = rig.parent[n]
		if p is None:
			L = np.einsum("ij,fjk->fik", rig.Rr[n].T, W[n])
		else:
			rel = rig.Rr[p].T @ rig.Rr[n]
			L = np.einsum("ij,fkj,fkl->fil", rel.T, W[p], W[n])
		Wloc[n] = L
	names = rig.names if only is None else [n for n in rig.names if n in only]
	for n in names:
		q = continuous(mat_to_quat(Wloc[n]))
		for i in range(4):
			key(act, ao, 'pose.bones["%s"].rotation_quaternion' % n, i, n, q[:, i])
	if only is None:
		# Root: Basis = Mrest⁻¹ · Mpose
		Mr = rig.M["Root"]
		loc = np.einsum("ij,fj->fi", np.linalg.inv(Mr)[:3, :3], root - Mr[:3, 3])
		for i in range(3):
			key(act, ao, 'pose.bones["Root"].location', i, "Root", loc[:, i])
		# Hips: A = Mroot_pose · Mroot_rest⁻¹ · Mhips_rest ; Basis = A⁻¹ · Mhips_pose
		Mh = rig.M["Hips"]
		A = Mroot @ (np.linalg.inv(Mr) @ Mh)
		Mp = np.tile(np.eye(4), (F, 1, 1))
		Mp[:, :3, :3] = W["Hips"]
		Mp[:, :3, 3] = hips
		Bs = np.linalg.inv(A) @ Mp
		for i in range(3):
			key(act, ao, 'pose.bones["Hips"].location', i, "Hips", Bs[:, i, 3])
	return act


def key(act, ao, path, i, group, vals):
	fc = act.fcurve_ensure_for_datablock(ao, path, index=i, group_name=group)
	n = len(vals)
	fc.keyframe_points.add(n)
	co = np.empty(2 * n)
	co[0::2] = np.arange(n)
	co[1::2] = vals
	fc.keyframe_points.foreach_set("co", co.tolist())
	fc.keyframe_points.foreach_set("interpolation", [1] * n)   # LINEAR
	fc.update()


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("--out", default="assets/anim/soldier_anim.glb")
	ap.add_argument("--only", default="")
	ap.add_argument("--decimate", type=float, default=0.4)
	ap.add_argument("--fetch-only", action="store_true")
	args = ap.parse_args([a for a in sys.argv[1:]])
	clips = CLIPS
	if args.only:
		want = set(args.only.split(","))
		clips = [c for c in CLIPS if c["name"] in want]
	fetch_all(CLIPS)
	if args.fetch_only:
		return
	blender_build(args, clips)


if __name__ == "__main__":
	main()
