#!/usr/bin/env python3
# MEVZİ — mocap yürüyüş verisi (Roadmap 17/25): CMU döngü klipleri (build_anims.py ile aynı yeniden hedefleme
# ve döngü kesimi) oyunun 10 pivotlu iskeletinin POZ (ayna) uzayındaki açılarına çevrilir. Oyunda bacak, kalça
# ve gövde hareketi bu veriden örneklenir; kollar silaha IK ile oturmaya devam eder (soldier_body.gd).
#
# Kullanım (proje kökünden):  blender -b --factory-startup -P tools/anim/build_loco.py
# Çıktı: assets/anim/loco.json — {klip: {fps, frames, length, speed, ch: [kanal adları], data: [[...], ...]}}
# Kanallar (soldier_body.gd'deki j/T anahtarları, poz uzayı): py prx pry prz srx sry lrx lrz krx llx llz klx
#
# Dönüşüm: her kemiğin dünya dönüşü G = W(t)·Rr⁻¹·C; C oyunun dinlenme yönünü (bacak dümdüz aşağı, gövde dik)
# MakeHuman dinlenme yönüne taşır. Yerel = ebeveyn G⁻¹·G. B (Z yukarı, +Y ileri) → Godot (Y yukarı, −Z ileri),
# sonra poz uzayına ayna (X): R → M·R·M. Euler sırası Godot varsayılanı YXZ (R = Ry·Rx·Rz).
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import build_anims as ba  # noqa: E402

GAME_HIP = 0.92
CLIPS = ["idle", "walk", "run", "sprint", "walk_back", "strafe_right", "strafe_left", "crouch_walk", "crawl", "prone_idle", "kneel_idle"]
P = np.array([[1.0, 0, 0], [0, 0, 1.0], [0, -1.0, 0]])     # B → Godot
MX = np.diag([-1.0, 1.0, 1.0])                              # poz uzayı aynası


def arc(a, b):
	a = a / np.linalg.norm(a)
	b = b / np.linalg.norm(b)
	v = np.cross(a, b)
	c = float(np.dot(a, b))
	if np.linalg.norm(v) < 1e-8:
		return np.eye(3) if c > 0 else -np.eye(3)
	K = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
	return np.eye(3) + K + K @ K * (1.0 / (1.0 + c))


def euler_yxz(R):
	"""R = Ry(y)·Rx(x)·Rz(z) → (x, y, z) (Godot Basis.get_euler varsayılanı)"""
	x = math.asin(max(-1.0, min(1.0, -R[1, 2])))
	if abs(R[1, 2]) < 0.9999:
		y = math.atan2(R[0, 2], R[2, 2])
		z = math.atan2(R[1, 0], R[1, 1])
	else:
		y = math.atan2(-R[2, 0], R[0, 0])
		z = 0.0
	return x, y, z


def main():
	import bpy
	ba.fetch_all([c for c in ba.CLIPS if c["name"] in CLIPS])
	bpy.ops.wm.read_factory_settings(use_empty=True)
	scn = bpy.context.scene
	base, sk, vb, faces, used = ba.build_human()
	layout, palm = ba.rig_layout(sk, vb)
	ao, arm = ba.make_armature(bpy, scn, layout)
	rig = ba.Rig(layout, arm)
	down = np.array([0.0, 0.0, -1.0])
	C = {}
	for n in ("LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg"):
		d0 = rig.tr[n] - rig.hr[n]
		C[n] = rig.Rr[n].T @ arc(down, d0)        # kemik yerel çerçevesinde: oyun dinlenmesi → MH dinlenmesi
	hip_rest = 0.5 * (rig.hr["LeftUpperLeg"][2] + rig.hr["RightUpperLeg"][2])
	ks = GAME_HIP / hip_rest
	out = {}
	for c in ba.CLIPS:
		if c["name"] not in CLIPS:
			continue
		res = ba.retarget(c, rig, palm)
		W, hips, root, yaw, info = ba.loop_cut(c, rig, res)
		F = W["Hips"].shape[0]

		def G(n, t):
			Rw = W[n][t] @ rig.Rr[n].T
			return Rw @ (rig.Rr[n] @ C[n]) if n in C else Rw

		rows = []
		for t in range(F):
			gh = G("Hips", t)
			gc = G("UpperChest", t)
			loc = {"p": gh, "s": gh.T @ gc}
			for S, s in (("Right", "r"), ("Left", "l")):
				gu = G(S + "UpperLeg", t)
				gl = G(S + "LowerLeg", t)
				loc["l" + s] = gh.T @ gu
				loc["k" + s] = gu.T @ gl
			e = {}
			for k, R in loc.items():
				Rg = P @ R @ P.T
				Rm = MX @ Rg @ MX
				e[k] = euler_yxz(Rm)
			py = float(hips[t][2]) * ks
			rows.append([round(float(v), 4) for v in [py, e["p"][0], e["p"][1], e["p"][2], e["s"][0], e["s"][1],
				e["lr"][0], e["lr"][2], e["kr"][0], e["ll"][0], e["ll"][2], e["kl"][0]]])
		# evre sıfırı: sağ uyluk en önde (topuk basışı) — klipler arası harmanlamada adımlar hizalı kalsın
		ph0 = int(np.argmax([r[6] for r in rows[:-1]])) / float(F - 1)
		out[c["name"]] = dict(fps=ba.FPS, frames=F - 1, length=round((F - 1) / ba.FPS, 4), speed=float(info.get("speed", 0.0)), ph0=round(float(ph0), 4),
			ch=["py", "prx", "pry", "prz", "srx", "sry", "lrx", "lrz", "krx", "llx", "llz", "klx"], data=rows)
		print("klip %-12s kare %3d hız %.2f m/s  py %.2f–%.2f  diz r %.2f–%.2f" % (c["name"], F - 1, info.get("speed", 0.0),
			min(r[0] for r in rows), max(r[0] for r in rows), min(r[8] for r in rows), max(r[8] for r in rows)))
	dst = os.path.join(ROOT, "assets/anim/loco.json")
	with open(dst, "w", encoding="utf-8") as f:
		json.dump(dict(source="CMU mocap (bkz. assets/anim/CREDITS.txt), tools/anim/build_loco.py", clips=out), f, separators=(",", ":"))
	print("yazıldı:", dst, "%.1f KB" % (os.path.getsize(dst) / 1024))


if __name__ == "__main__":
	main()
