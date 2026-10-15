#!/usr/bin/env python3
# Kaya yüzeyi dokusu (döşenebilir): albedo + normal + pürüzlülük.
#   python3 tools/rock_tex.py  -> assets/textures/rock_face/{albedo,normal,rough}.jpg
# Yöntem: FFT ile periyodik fraktal gürültü (1/f^b tayf) → kenarları kendiliğinden döşenir.
# Katmanlar: büyük kütle + çarpıtılmış tabakalanma + sırt gürültüsünden çatlaklar + liken/yosun lekeleri.
import os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
S = 1024
rng = np.random.default_rng(23)
fy = np.fft.fftfreq(S)[:, None]
fx = np.fft.fftfreq(S)[None, :]
fr = np.sqrt(fx * fx + fy * fy)
fr[0, 0] = 1.0

def fbm(beta, lo=0.0, hi=0.5, aniso=1.0):
	spec = (rng.standard_normal((S, S)) + 1j * rng.standard_normal((S, S)))
	f = np.sqrt(fx * fx * aniso + fy * fy / aniso)
	f[0, 0] = 1.0
	amp = f ** (-beta)
	amp[(f < lo) | (f > hi)] = 0.0
	amp[0, 0] = 0.0
	n = np.real(np.fft.ifft2(spec * amp))
	n -= n.mean()
	return n / (n.std() + 1e-9)

def warp(a, dx, dy):
	yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
	x = (xx + dx) % S
	y = (yy + dy) % S
	x0 = x.astype(np.int32); y0 = y.astype(np.int32)
	tx = x - x0; ty = y - y0
	x1 = (x0 + 1) % S; y1 = (y0 + 1) % S
	return (a[y0, x0] * (1 - tx) * (1 - ty) + a[y0, x1] * tx * (1 - ty) + a[y1, x0] * (1 - tx) * ty + a[y1, x1] * tx * ty)

big = fbm(1.6, 0, 0.008)
mid = fbm(1.3, 0.004, 0.05)
fine = fbm(0.9, 0.03, 0.5)
wx = fbm(1.8, 0, 0.006) * 70.0
wy = fbm(1.8, 0, 0.006) * 70.0
# tabakalanma: yatay bantlar (periyodik: tam sayı dalga), çarpıtılmış
yy = np.mgrid[0:S, 0:S][0].astype(np.float32)
strata = np.sin(yy / S * np.pi * 2 * 6 + big * 1.8)
strata = warp(strata, wx, wy)
# çatlaklar: sırt gürültüsü (|n| küçük olduğu yerler ince çizgi)
# kırık ağı: periyodik Voronoi hücre kenarları (F2 - F1 küçük), hafif çarpıtılmış → köşeli çatlaklar
def voronoi_edges(npts, wscale):
	pts = rng.random((npts, 2)) * S
	gy, gx = np.mgrid[0:S, 0:S].astype(np.float32)
	gx = gx + wx * wscale
	gy = gy + wy * wscale
	f1 = np.full((S, S), 1e9, np.float32)
	f2 = np.full((S, S), 1e9, np.float32)
	for ox in (-S, 0, S):
		for oy in (-S, 0, S):
			for px, py in pts:
				d = np.sqrt((gx - px - ox) ** 2 + (gy - py - oy) ** 2)
				f2 = np.where(d < f1, f1, np.minimum(f2, d))
				f1 = np.minimum(f1, d)
	return f2 - f1
e1 = voronoi_edges(14, 0.35)
e2 = voronoi_edges(40, 0.2)
cr2 = np.abs(fbm(1.3, 0.004, 0.08))
crack = np.clip(1.0 - e1 / 5.0, 0, 1) ** 1.3 + np.clip(1.0 - e2 / 2.5, 0, 1) ** 1.5 * 0.45 + np.clip(1.0 - cr2 / 0.03, 0, 1) ** 2 * 0.25
crack = np.clip(crack, 0, 1)
height = big * 0.55 + mid * 0.35 + fine * 0.12 + strata * 0.18 - crack * 1.3
height = (height - height.min()) / (height.max() - height.min())

# albedo
base = np.array([0.50, 0.48, 0.45])
warm = np.array([0.56, 0.49, 0.41])
cool = np.array([0.40, 0.41, 0.42])
t1 = np.clip(big * 0.5 + 0.5, 0, 1)[..., None]
col = base * (1 - t1) + warm * t1
t2 = np.clip(strata * 0.5 + 0.5, 0, 1)[..., None] * 0.6
col = col * (1 - t2) + cool * t2
col *= (0.62 + 0.6 * height)[..., None]
col *= (1.0 + fine * 0.09 + mid * 0.08)[..., None]
col *= (1.0 - crack * 0.62)[..., None]
# liken (sarı-yeşil, turuncu) ve yosun: düşük frekanslı eşik + ince dağınıklık
lich = fbm(1.2, 0.003, 0.06)
lmask = np.clip((lich - 1.5) * 2.0, 0, 1) * np.clip(fine * 0.5 + 0.8, 0, 1) * np.clip(1 - crack * 2, 0, 1)
lcol = np.array([0.62, 0.62, 0.40])
col = col * (1 - lmask[..., None] * 0.75) + lcol * lmask[..., None] * 0.75
orange = fbm(1.1, 0.006, 0.08)
omask = np.clip((orange - 2.1) * 2.5, 0, 1) * 0.55
col = col * (1 - omask[..., None]) + np.array([0.70, 0.45, 0.22]) * omask[..., None]
moss = np.clip((big * 0.6 + mid * 0.4 - 1.1) * 1.6, 0, 1) * np.clip(crack * 1.5 + 0.2, 0, 1)
col = col * (1 - moss[..., None] * 0.7) + np.array([0.26, 0.32, 0.15]) * moss[..., None] * 0.7
col = np.clip(col, 0, 1)

# normal (periyodik merkezi fark)
k = 7.0
dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * k
dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * k
n = np.stack([-dx, dy, np.ones_like(dx)], -1)
n /= np.linalg.norm(n, axis=-1, keepdims=True)
rough = np.clip(0.78 + crack * 0.18 - lmask * 0.05 + fine * 0.03, 0, 1)

out = os.path.join(ROOT, "assets", "textures", "rock_face")
os.makedirs(out, exist_ok=True)
Image.fromarray((col * 255).astype(np.uint8), "RGB").save(os.path.join(out, "albedo.jpg"), quality=92)
Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB").save(os.path.join(out, "normal.jpg"), quality=94)
Image.fromarray((rough * 255).astype(np.uint8), "L").save(os.path.join(out, "rough.jpg"), quality=90)
print("OK", out)
