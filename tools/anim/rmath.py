# Dönüş yardımcıları (numpy). Matrisler 3x3 (…,3,3), dördeyler (w, x, y, z).
import numpy as np


def normalize(v, axis=-1):
	n = np.linalg.norm(v, axis=axis, keepdims=True)
	return v / np.maximum(n, 1e-12)


def axis_angle(axis, ang):
	"""Eksen-açı → matris (tek)."""
	a = normalize(np.asarray(axis, dtype=float))
	x, y, z = a
	c, s = np.cos(ang), np.sin(ang)
	C = 1 - c
	return np.array([
		[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
		[y * x * C + z * s, c + y * y * C, y * z * C - x * s],
		[z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


def rot_z(ang):
	return axis_angle([0, 0, 1], ang)


def arc(a, b):
	"""a yönünü b yönüne çeviren en kısa dönüş (tek)."""
	a = normalize(np.asarray(a, dtype=float))
	b = normalize(np.asarray(b, dtype=float))
	c = np.cross(a, b)
	s = np.linalg.norm(c)
	d = float(np.dot(a, b))
	if s < 1e-9:
		if d > 0:
			return np.eye(3)
		# 180°: a'ya dik herhangi bir eksen
		p = np.cross(a, [1, 0, 0])
		if np.linalg.norm(p) < 1e-6:
			p = np.cross(a, [0, 1, 0])
		return axis_angle(p, np.pi)
	return axis_angle(c / s, np.arctan2(s, d))


def triad(a1, a2, b1, b2):
	"""(a1, a2) çiftini (b1, b2) çiftine götüren dönüş; birinci vektör tam, ikinci düzlemde hizalanır."""
	def frame(u, v):
		u = normalize(np.asarray(u, dtype=float))
		w = normalize(np.cross(u, v))
		v2 = np.cross(w, u)
		return np.stack([u, v2, w], axis=1)
	return frame(b1, b2) @ frame(a1, a2).T


def mat_to_quat(M):
	"""(…,3,3) → (…,4) w,x,y,z."""
	M = np.asarray(M, dtype=float)
	sh = M.shape[:-2]
	M = M.reshape(-1, 3, 3)
	q = np.zeros((M.shape[0], 4))
	for i, m in enumerate(M):
		t = m[0, 0] + m[1, 1] + m[2, 2]
		if t > 0:
			s = np.sqrt(t + 1.0) * 2
			q[i] = [0.25 * s, (m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s]
		elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
			s = np.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
			q[i] = [(m[2, 1] - m[1, 2]) / s, 0.25 * s, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s]
		elif m[1, 1] > m[2, 2]:
			s = np.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
			q[i] = [(m[0, 2] - m[2, 0]) / s, (m[0, 1] + m[1, 0]) / s, 0.25 * s, (m[1, 2] + m[2, 1]) / s]
		else:
			s = np.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
			q[i] = [(m[1, 0] - m[0, 1]) / s, (m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, 0.25 * s]
	q = normalize(q)
	return q.reshape(sh + (4,))


def quat_to_mat(q):
	q = normalize(np.asarray(q, dtype=float))
	w, x, y, z = q[..., 0], q[..., 1], q[..., 2], q[..., 3]
	M = np.empty(q.shape[:-1] + (3, 3))
	M[..., 0, 0] = 1 - 2 * (y * y + z * z)
	M[..., 0, 1] = 2 * (x * y - z * w)
	M[..., 0, 2] = 2 * (x * z + y * w)
	M[..., 1, 0] = 2 * (x * y + z * w)
	M[..., 1, 1] = 1 - 2 * (x * x + z * z)
	M[..., 1, 2] = 2 * (y * z - x * w)
	M[..., 2, 0] = 2 * (x * z - y * w)
	M[..., 2, 1] = 2 * (y * z + x * w)
	M[..., 2, 2] = 1 - 2 * (x * x + y * y)
	return M


def slerp(q0, q1, t):
	"""Dördey küresel ara değer; t skaler ya da (…,) dizi."""
	q0 = np.asarray(q0, dtype=float)
	q1 = np.asarray(q1, dtype=float).copy()
	t = np.asarray(t, dtype=float)
	d = np.sum(q0 * q1, axis=-1)
	q1 = np.where((d < 0)[..., None], -q1, q1)
	d = np.abs(d)
	th = np.arccos(np.clip(d, -1, 1))
	s = np.sin(th)
	small = s < 1e-6
	a = np.where(small, 1 - t, np.sin((1 - t) * th) / np.where(small, 1, s))
	b = np.where(small, t, np.sin(t * th) / np.where(small, 1, s))
	return normalize(a[..., None] * q0 + b[..., None] * q1)


def mat_slerp(A, B, t):
	return quat_to_mat(slerp(mat_to_quat(A), mat_to_quat(B), t))


def continuous(q):
	"""(F,4) dördey dizisinde işaret sürekliliği (enterpolasyon dönmesin)."""
	q = q.copy()
	for i in range(1, len(q)):
		if np.dot(q[i], q[i - 1]) < 0:
			q[i] = -q[i]
	return q


def yaw_of(fwd):
	"""Yatay ileri vektörün +Y'den +X'e doğru açısı (radyan)."""
	return np.arctan2(fwd[..., 0], fwd[..., 1])


def gauss_smooth(x, sigma, axis=0):
	"""Kenarları yansıtarak Gauss yumuşatma (kare cinsinden sigma)."""
	if sigma <= 0:
		return x
	r = int(np.ceil(sigma * 3))
	k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
	k /= k.sum()
	x = np.moveaxis(np.asarray(x, dtype=float), axis, 0)
	pad = np.concatenate([x[r:0:-1], x, x[-2:-r - 2:-1]], axis=0) if len(x) > r + 1 else np.concatenate([np.repeat(x[:1], r, 0), x, np.repeat(x[-1:], r, 0)], 0)
	out = np.zeros_like(x)
	for i, w in enumerate(k):
		out += w * pad[i:i + len(x)]
	return np.moveaxis(out, 0, axis)
