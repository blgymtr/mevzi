# MakeHuman (CC0) taban örgüsü okuyucu: OBJ + hedef (target) uygulama + eklem konumları + ağırlıklar.
# Blender'a bağımlı değil (numpy). Birimler MakeHuman'da desimetre; çıktı B çerçevesinde metre.
import json
import os
import numpy as np

# MakeHuman OBJ: Y yukarı, +Z'ye bakar → B: Z yukarı, +Y'ye bakar, sağ +X
C = np.array([[-1.0, 0.0, 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0]])


class BaseMesh:
	def __init__(self, path: str):
		vs, vts, faces = [], [], []   # faces: (grup, [(v, vt)...])
		group = ""
		with open(path) as f:
			for line in f:
				if line.startswith("v "):
					vs.append([float(x) for x in line.split()[1:4]])
				elif line.startswith("vt "):
					vts.append([float(x) for x in line.split()[1:3]])
				elif line.startswith("g "):
					group = line.split()[1]
				elif line.startswith("f "):
					corners = []
					for c in line.split()[1:]:
						p = c.split("/")
						corners.append((int(p[0]) - 1, int(p[1]) - 1 if len(p) > 1 and p[1] else -1))
					faces.append((group, corners))
		self.v = np.array(vs)
		self.vt = np.array(vts)
		self.faces = faces

	def apply_target(self, path: str, w: float):
		if w == 0.0:
			return
		idx, d = [], []
		with open(path) as f:
			for line in f:
				if not line.strip() or line[0] == "#":
					continue
				p = line.split()
				idx.append(int(p[0]))
				d.append([float(x) for x in p[1:4]])
		if idx:
			self.v[np.array(idx)] += w * np.array(d)

	def to_b(self, scale: float = 0.1) -> np.ndarray:
		"""Köşeler B çerçevesinde (metre)."""
		return (self.v @ C.T) * scale


class Skeleton:
	"""default.mhskel: kemik başı/ucu köşe gruplarının ortalaması."""
	def __init__(self, path: str):
		with open(path) as f:
			d = json.load(f)
		self.bones = d["bones"]
		self.joints = d["joints"]

	def joint(self, vb: np.ndarray, name: str) -> np.ndarray:
		return vb[np.array(self.joints[name])].mean(axis=0)

	def head(self, vb, bone):
		return self.joint(vb, self.bones[bone]["head"])

	def tail(self, vb, bone):
		return self.joint(vb, self.bones[bone]["tail"])


def load_weights(path: str) -> dict:
	with open(path) as f:
		return json.load(f)["weights"]


def cache_path(root: str, rel: str) -> str:
	return os.path.join(root, rel)
