# BVH okuyucu + ileri kinematik (numpy). Blender'a bağımlı değil.
# Çıktı çerçevesi "B": Blender dünyası — Z yukarı, karakter +Y'ye bakar, sağ taraf +X, metre.
# CMU (cgspeed) BVH: Y yukarı, T-pozu +Z'ye bakar, birim ≈ 0.0564 m ((1/0.45) inç), 120 fps.
import numpy as np

# BVH(Y yukarı, +Z ileri, sağ -X) → B(Z yukarı, +Y ileri, sağ +X): (x, y, z) → (-x, z, y)
C = np.array([[-1.0, 0.0, 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0]])
CMU_UNIT = (1.0 / 0.45) * 0.0254


def _rot(axis: str, deg):
	a = np.radians(deg)
	c, s = np.cos(a), np.sin(a)
	n = a.shape[0]
	R = np.zeros((n, 3, 3))
	if axis == "X":
		R[:, 0, 0] = 1; R[:, 1, 1] = c; R[:, 1, 2] = -s; R[:, 2, 1] = s; R[:, 2, 2] = c
	elif axis == "Y":
		R[:, 1, 1] = 1; R[:, 0, 0] = c; R[:, 0, 2] = s; R[:, 2, 0] = -s; R[:, 2, 2] = c
	else:
		R[:, 2, 2] = 1; R[:, 0, 0] = c; R[:, 0, 1] = -s; R[:, 1, 0] = s; R[:, 1, 1] = c
	return R


class Joint:
	def __init__(self, name, parent):
		self.name = name
		self.parent = parent        # indeks ya da -1
		self.offset = np.zeros(3)
		self.channels = []
		self.ch0 = 0                # hareket satırındaki ilk kanal sütunu
		self.end = None             # uç (End Site) ofseti


class BVH:
	def __init__(self, path: str):
		self.joints: list[Joint] = []
		with open(path) as f:
			tok = f.read().split()
		i = 0
		stack = []
		ncol = 0
		cur = None
		while tok[i] != "MOTION":
			t = tok[i]
			if t in ("ROOT", "JOINT"):
				j = Joint(tok[i + 1], stack[-1] if stack else -1)
				self.joints.append(j)
				cur = len(self.joints) - 1
				i += 2
			elif t == "End":
				i += 2
				# { OFFSET x y z }
				assert tok[i] == "{" and tok[i + 1] == "OFFSET"
				self.joints[stack[-1]].end = np.array([float(x) for x in tok[i + 2:i + 5]])
				i += 6
			elif t == "{":
				stack.append(cur)
				i += 1
			elif t == "}":
				stack.pop()
				i += 1
			elif t == "OFFSET":
				self.joints[cur].offset = np.array([float(x) for x in tok[i + 1:i + 4]])
				i += 4
			elif t == "CHANNELS":
				n = int(tok[i + 1])
				self.joints[cur].channels = tok[i + 2:i + 2 + n]
				self.joints[cur].ch0 = ncol
				ncol += n
				i += 2 + n
			else:
				i += 1
		nf = int(tok[i + 2])
		self.dt = float(tok[i + 5])
		data = np.array([float(x) for x in tok[i + 6:i + 6 + nf * ncol]]).reshape(nf, ncol)
		self.data = data
		self.nframes = nf
		self.index = {j.name: k for k, j in enumerate(self.joints)}

	def fk(self, scale: float = CMU_UNIT):
		"""Tüm kareler için B çerçevesinde küresel konum (F,J,3) ve dönüş (F,J,3,3)."""
		F, J = self.nframes, len(self.joints)
		P = np.zeros((F, J, 3))
		R = np.zeros((F, J, 3, 3))
		for k, j in enumerate(self.joints):
			loc = np.tile(np.eye(3), (F, 1, 1))
			pos = np.tile(j.offset, (F, 1))
			for ci, ch in enumerate(j.channels):
				col = self.data[:, j.ch0 + ci]
				if ch.endswith("rotation"):
					loc = loc @ _rot(ch[0], col)
				elif ch == "Xposition":
					pos[:, 0] = col
				elif ch == "Yposition":
					pos[:, 1] = col
				elif ch == "Zposition":
					pos[:, 2] = col
			if j.parent < 0:
				R[:, k] = loc
				P[:, k] = pos
			else:
				R[:, k] = R[:, j.parent] @ loc
				P[:, k] = P[:, j.parent] + np.einsum("fij,fj->fi", R[:, j.parent], pos)
		# B çerçevesine çevir
		P = np.einsum("ij,fkj->fki", C, P) * scale
		R = np.einsum("ij,fkjl,ml->fkim", C, R, C)
		return P, R

	def end_positions(self, P, R, name: str, scale: float = CMU_UNIT):
		"""Bir eklemin uç (End Site) noktası, B çerçevesinde."""
		k = self.index[name]
		e = C @ self.joints[k].end * scale
		# R zaten B çerçevesinde, ofset BVH çerçevesinde: R_B · (C·e)
		return P[:, k] + np.einsum("fij,j->fi", R[:, k], e)
