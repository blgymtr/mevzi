#!/usr/bin/env python3
# Efekt flipbook üretici: numpy ile 3B gaz simülasyonu (yanma + duman) ve ışın yürütmeli işleme.
#   python3 tools/fx_sim.py expl     -> assets/fx/expl_flip.png  (patlama ateş topu, 8x6 kare)
#   python3 tools/fx_sim.py smoke    -> assets/fx/smoke_flip.png (yükselen yoğun duman)
# Yöntem: yarı-Lagrange adveksiyon (üç doğrusal örnekleme), sıcaklık/yoğunluk kaldırma kuvveti,
# girdap koruması (vorticity confinement), Jacobi basınç projeksiyonu, yakıt yanması (ısı+is).
# İşleme: yandan ortografik bakış, ön→arka birleştirme, üstten ışığa gölge geçirgenliği,
# sıcaklıktan kara cisim ışıması. Çıktı önceden çarpılmamış RGBA.
import sys, os
import numpy as np
from PIL import Image

KIND = sys.argv[1] if len(sys.argv) > 1 else "expl"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NX, NY, NZ = 64, 128, 64
COLS, ROWS, CELL = 8, 6, 160
NFR = COLS * ROWS
rng = np.random.default_rng(7 if KIND == "expl" else 11)

shape = (NX, NY, NZ)
u = np.zeros(shape, np.float32); v = np.zeros(shape, np.float32); w = np.zeros(shape, np.float32)
dens = np.zeros(shape, np.float32); temp = np.zeros(shape, np.float32); fuel = np.zeros(shape, np.float32)
X, Y, Z = np.meshgrid(np.arange(NX, dtype=np.float32), np.arange(NY, dtype=np.float32), np.arange(NZ, dtype=np.float32), indexing="ij")
cx, cz = NX * 0.5, NZ * 0.5
noise = rng.standard_normal(shape).astype(np.float32)

def blur(a):
	return (a + np.roll(a, 1, 0) + np.roll(a, -1, 0) + np.roll(a, 1, 1) + np.roll(a, -1, 1) + np.roll(a, 1, 2) + np.roll(a, -1, 2)) / 7.0

for _ in range(3):
	noise = blur(noise)
noise /= noise.std() + 1e-6

def sample(f, x, y, z):
	x = np.clip(x, 0, NX - 1.001); y = np.clip(y, 0, NY - 1.001); z = np.clip(z, 0, NZ - 1.001)
	x0 = x.astype(np.int32); y0 = y.astype(np.int32); z0 = z.astype(np.int32)
	fx = x - x0; fy = y - y0; fz = z - z0
	x1 = x0 + 1; y1 = y0 + 1; z1 = z0 + 1
	c000 = f[x0, y0, z0]; c100 = f[x1, y0, z0]; c010 = f[x0, y1, z0]; c110 = f[x1, y1, z0]
	c001 = f[x0, y0, z1]; c101 = f[x1, y0, z1]; c011 = f[x0, y1, z1]; c111 = f[x1, y1, z1]
	c00 = c000 * (1 - fx) + c100 * fx; c10 = c010 * (1 - fx) + c110 * fx
	c01 = c001 * (1 - fx) + c101 * fx; c11 = c011 * (1 - fx) + c111 * fx
	c0 = c00 * (1 - fy) + c10 * fy; c1 = c01 * (1 - fy) + c11 * fy
	return c0 * (1 - fz) + c1 * fz

def advect(fields, dt):
	bx = X - u * dt; by = Y - v * dt; bz = Z - w * dt
	return [sample(f, bx, by, bz) for f in fields]

def grad(p):
	return (np.roll(p, -1, 0) - np.roll(p, 1, 0)) * 0.5, (np.roll(p, -1, 1) - np.roll(p, 1, 1)) * 0.5, (np.roll(p, -1, 2) - np.roll(p, 1, 2)) * 0.5

def project(iters=40):
	global u, v, w
	div = (np.roll(u, -1, 0) - np.roll(u, 1, 0) + np.roll(v, -1, 1) - np.roll(v, 1, 1) + np.roll(w, -1, 2) - np.roll(w, 1, 2)) * 0.5
	p = np.zeros(shape, np.float32)
	for _ in range(iters):
		p = (np.roll(p, 1, 0) + np.roll(p, -1, 0) + np.roll(p, 1, 1) + np.roll(p, -1, 1) + np.roll(p, 1, 2) + np.roll(p, -1, 2) - div) / 6.0
	gx, gy, gz = grad(p)
	u -= gx; v -= gy; w -= gz

def vorticity(eps, dt):
	global u, v, w
	_, uy, uz = grad(u); vx, _, vz = grad(v); wx, wy, _ = grad(w)
	ox = wy - vz; oy = uz - wx; oz = vx - uy
	mag = np.sqrt(ox * ox + oy * oy + oz * oz) + 1e-6
	nx, ny, nz = grad(mag)
	nl = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
	nx /= nl; ny /= nl; nz /= nl
	u += eps * (ny * oz - nz * oy) * dt
	v += eps * (nz * ox - nx * oz) * dt
	w += eps * (nx * oy - ny * ox) * dt

def boundary():
	for f in (u, v, w):
		f[0, :, :] = f[-1, :, :] = 0; f[:, 0, :] = 0; f[:, -1, :] = 0; f[:, :, 0] = f[:, :, -1] = 0
	v[:, 0, :] = np.maximum(v[:, 0, :], 0)

# --- kaynak
def emit(step):
	global u, v, w, dens, temp, fuel
	if KIND == "expl":
		if step == 0:
			r = np.sqrt((X - cx) ** 2 + (Y - 22) ** 2 + (Z - cz) ** 2)
			m = np.clip(1.0 - r / 15.0, 0, 1) ** 0.7 * (0.8 + 0.2 * noise)
			fuel += m * 2.4; temp += m * 1.2; dens += m * 0.2
			dirx = (X - cx) / (r + 1e-3); diry = (Y - 22) / (r + 1e-3); dirz = (Z - cz) / (r + 1e-3)
			sp = m * 9.0 * (1.0 + 0.4 * noise)
			u += dirx * sp; v += diry * sp + m * 6.0; w += dirz * sp
	else:
		if step < 70:
			r = np.sqrt((X - cx) ** 2 + (Y - 6) ** 2 + (Z - cz) ** 2)
			m = np.clip(1.0 - r / 6.0, 0, 1)
			dens += m * 0.35 * (0.8 + 0.2 * noise); temp += m * 0.45
			v += m * 2.0

BURN = 0.55 if KIND == "expl" else 1.8
DT = 0.35
SUB = 2 if KIND == "expl" else 3
frames = []
step = 0
light_dir_k = 1.6 if KIND == "expl" else 1.1
for fr in range(NFR):
	for s in range(SUB):
		emit(step)
		# yanma
		burn = np.minimum(fuel, BURN * DT * (temp > 0.25)).astype(np.float32)
		fuel -= burn; temp += burn * 1.2; dens += burn * (1.1 if KIND == "expl" else 0.0)
		# genleşme: yanan yerden dışa
		if KIND == "expl":
			gx, gy, gz = grad(burn)
			u -= gx * 30 * DT; v -= gy * 30 * DT; w -= gz * 30 * DT
		# kaldırma kuvveti
		v += (temp * (2.6 if KIND == "expl" else 1.6) - dens * 0.22) * DT
		vorticity(1.6 if KIND == "expl" else 0.9, DT)
		boundary()
		project(30)
		u, v, w, dens, temp, fuel = advect([u, v, w, dens, temp, fuel], DT)
		temp *= 0.972 if KIND == "expl" else 0.975
		dens *= 0.997
		# tavana yaklaşan duman sönümlenir (alan sınırında düzleşme olmasın)
		top = np.clip((Y - (NY - 34)) / 30.0, 0, 1)
		dens *= 1.0 - top * 0.08
		v *= 1.0 - top * 0.05
		u *= 0.995; v *= 0.995; w *= 0.995
		step += 1
	# --- işleme (yandan, z ekseni boyunca; y yukarı)
	sig = 1.8 if KIND == "expl" else 1.4
	a = 1.0 - np.exp(-dens * sig)                       # (x,y,z) hücre opaklığı
	# üstten (ve hafif yandan) ışık geçirgenliği
	cum = np.cumsum(dens[:, ::-1, :] * 0.55 * light_dir_k, axis=1)[:, ::-1, :]
	light = np.exp(-cum) * 0.75 + 0.3
	base = np.array([0.5, 0.47, 0.43] if KIND == "expl" else [0.66, 0.64, 0.6], np.float32)
	smoke_rgb = light[..., None] * base[None, None, None, :]
	# kara cisim ışıması (sıcaklık rampası)
	t = np.clip(temp * 1.1, 0, 1.6)
	fire = np.stack([np.clip(t * 2.2, 0, 1.9), np.clip(t * 1.6 - 0.25, 0, 1.5), np.clip(t * 1.4 - 0.8, 0, 1.1)], -1)
	emis_w = np.clip((temp - 0.18) * 2.0, 0, 1)[..., None]
	col = smoke_rgb * (1 - emis_w) + fire * emis_w
	alpha_eff = np.clip(a + emis_w[..., 0] * 0.5 * (1 - a), 0, 1)
	# ön→arka birleştirme (z ekseni)
	T = np.ones((NX, NY), np.float32)
	C = np.zeros((NX, NY, 3), np.float32)
	for zz in range(NZ):
		ai = alpha_eff[:, :, zz]
		C += (T * ai)[..., None] * col[:, :, zz, :]
		T *= (1 - ai)
	A = 1 - T
	rgb = C / np.maximum(A, 1e-4)[..., None]
	img = np.concatenate([np.clip(rgb, 0, 1), A[..., None]], -1)       # (x, y, 4)
	img = np.transpose(img, (1, 0, 2))[::-1]                             # (y aşağı, x)
	# kare kanvas (96 yükseklik → 96x96, yatay ortalı)
	canvas = np.zeros((NY, NY, 4), np.float32)
	ox = (NY - NX) // 2
	canvas[:, ox:ox + NX] = img
	frames.append(Image.fromarray((canvas * 255).astype(np.uint8), "RGBA").resize((CELL, CELL), Image.BICUBIC))
	print("FRAME", fr, "max_t=%.2f max_d=%.2f" % (float(temp.max()), float(dens.max())), flush=True)

atlas = Image.new("RGBA", (COLS * CELL, ROWS * CELL))
for i, f in enumerate(frames):
	atlas.paste(f, ((i % COLS) * CELL, (i // COLS) * CELL))
out = os.path.join(ROOT, "assets", "fx", "%s_flip.png" % KIND)
os.makedirs(os.path.dirname(out), exist_ok=True)
atlas.save(out, optimize=True)
print("ATLAS", out)
