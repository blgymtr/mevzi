#!/usr/bin/env python3
# Duman pufu atlası (2×2 çeşit, 256² hücre) → assets/fx/smoke_puff.png
#   R,G: doku uzayı yüzey normali (x sağ, y yukarı; 0.5 merkezli)   B: kalınlık (yoğunluk)   A: örtme
# Yoğunluk: iç içe Gauss yumakları (karnabahar kümesi) × çok katlı değer gürültüsü; kenara doğru incelir.
# Normal: küre normali + yoğunluk alanının eğimi (yumak kabartısı) → gölgelendiricide güneşe göre ışık/öz gölge.
# Çalıştırma: "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe" -I tools/fx_smoke_puff.py
import os, struct, zlib
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
S = 256
rng = np.random.default_rng(4242)


def value_noise(n, cells, seed):
	r = np.random.default_rng(seed)
	g = r.random((cells + 1, cells + 1)).astype(np.float32)
	g[-1, :] = g[0, :]
	g[:, -1] = g[:, 0]
	t = np.linspace(0, cells, n, endpoint=False, dtype=np.float32)
	i = t.astype(np.int32)
	f = t - i
	f = f * f * (3 - 2 * f)
	a = g[i][:, i]
	b = g[i][:, i + 1]
	c = g[i + 1][:, i]
	d = g[i + 1][:, i + 1]
	fx = f[None, :]
	fy = f[:, None]
	return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(n, seed):
	out = np.zeros((n, n), np.float32)
	amp, tot = 1.0, 0.0
	for o, cells in enumerate([4, 8, 16, 32, 64]):
		out += value_noise(n, cells, seed + o * 13) * amp
		tot += amp
		amp *= 0.5
	return out / tot


def blur(a, k=2):
	for _ in range(k):
		a = (a + np.roll(a, 1, 0) + np.roll(a, -1, 0) + np.roll(a, 1, 1) + np.roll(a, -1, 1)) / 5.0
	return a


def cell(v):
	y, x = np.mgrid[0:S, 0:S].astype(np.float32)
	u = (x + 0.5) / S * 2 - 1
	w = -((y + 0.5) / S * 2 - 1)               # yukarı +
	H = np.zeros((S, S), np.float32)
	NX = np.zeros_like(H)
	NY = np.zeros_like(H)
	# karnabahar: büyük gövde küresi + çevresinde 10–15 yumak (kürelerin birleşimi → belirgin kabartılar)
	blobs = [(0.0, -0.06, 0.5)]
	for _ in range(rng.integers(10, 16)):
		a = rng.random() * np.pi * 2
		r0 = rng.uniform(0.18, 0.52)
		blobs.append((np.cos(a) * r0, np.sin(a) * r0 * 0.85 + 0.04, rng.uniform(0.15, 0.34)))
	for cx, cy, rad in blobs:
		dx = (u - cx) / rad
		dy = (w - cy) / rad
		q2 = dx * dx + dy * dy
		h = np.sqrt(np.clip(1.0 - q2, 0.0, 1.0)) * rad
		m = h > H
		H = np.where(m, h, H)
		NX = np.where(m, dx, NX)
		NY = np.where(m, dy, NY)
	# ince kabarcıklar: gürültü eğimiyle normal bozulur
	n1 = fbm(S, 100 + v * 31)
	n2 = fbm(S, 500 + v * 17)
	gx = (np.roll(n1, -1, 1) - np.roll(n1, 1, 1)) * S * 0.04
	gy = -(np.roll(n1, -1, 0) - np.roll(n1, 1, 0)) * S * 0.04
	NX = NX - gx
	NY = NY - gy
	NZ = np.sqrt(np.clip(1.0 - NX * NX - NY * NY, 0.0, 1.0)) + 0.15
	ln = np.sqrt(NX * NX + NY * NY + NZ * NZ)
	nx, ny = NX / ln, NY / ln
	t = H / max(H.max(), 1e-6)
	# kenar: kürelerin dış kabuğu yumuşak, gürültüyle aşınmış (tüylü kenar, arkası görünür)
	edge = np.clip(H / 0.14, 0.0, 1.0) ** 1.5
	erode = np.clip((n2 * 1.4 + t * 1.2 - 0.3) / 0.5, 0.0, 1.0)
	alpha = edge * erode * (0.5 + 0.5 * np.clip(t * 1.6, 0.0, 1.0))
	# dış saçak: birleşimin çevresinde ince, gürültülü tül
	halo = blur((H > 0).astype(np.float32), 10) * (0.35 + 0.65 * n2)
	alpha = np.maximum(blur(alpha, 2), halo * 0.22)
	out = np.zeros((S, S, 4), np.uint8)
	out[..., 0] = np.clip((nx * 0.5 + 0.5) * 255, 0, 255)
	out[..., 1] = np.clip((ny * 0.5 + 0.5) * 255, 0, 255)
	out[..., 2] = np.clip(t * 255, 0, 255)
	out[..., 3] = np.clip(alpha * 255, 0, 255)
	return out


def write_png(path, rgba):
	h, w, _ = rgba.shape
	raw = b"".join(b"\x00" + rgba[y].tobytes() for y in range(h))
	def chunk(t, data):
		c = struct.pack(">I", len(data)) + t + data
		return c + struct.pack(">I", zlib.crc32(t + data) & 0xFFFFFFFF)
	png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
	with open(path, "wb") as f:
		f.write(png)


atlas = np.zeros((S * 2, S * 2, 4), np.uint8)
for v in range(4):
	ox, oy = (v % 2) * S, (v // 2) * S
	atlas[oy:oy + S, ox:ox + S] = cell(v)
out = os.path.join(ROOT, "assets", "fx", "smoke_puff.png")
write_png(out, atlas)
print("yazıldı", out)
