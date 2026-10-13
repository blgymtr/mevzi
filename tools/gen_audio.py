# Mevzi seslerini sentezler (44.1 kHz, 16 bit WAV). Tamamen prosedürel, telifsiz.
import numpy as np, wave, os
SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'audio')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1820)

def save(name, x, peak=0.9):
    x = np.asarray(x, np.float64)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    d = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes())
    print('ok', name)

def T(s): return np.arange(int(SR * s)) / SR
def N(s): return rng.uniform(-1, 1, int(SR * s))

def fft_filter(x, lo=0.0, hi=None):
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    m = np.ones_like(f)
    if lo > 0: m *= 1 / (1 + (lo / np.maximum(f, 1)) ** 4)
    if hi: m *= 1 / (1 + (f / hi) ** 4)
    return np.fft.irfft(X * m, len(x))

def env(n, a, d):
    t = np.arange(n) / SR
    e = np.exp(-t / d)
    ai = int(a * SR)
    if ai > 0: e[:ai] *= np.linspace(0, 1, ai)
    return e

def reverb(x, sec=1.2, mix=0.25):
    m = int(SR * sec)
    ir = rng.normal(0, 1, m) * np.exp(-np.arange(m) / (SR * sec / 6))
    ir = fft_filter(ir, 0, 3500)
    L = len(x) + m
    y = np.fft.irfft(np.fft.rfft(x, L) * np.fft.rfft(ir, L), L)
    y = y / (np.max(np.abs(y)) + 1e-9) * np.max(np.abs(x))
    out = np.zeros(len(y)); out[:len(x)] = x * (1 - mix)
    return out + y * mix

def crack(dur=0.6, body=180, bright=5000, tail=0.35, seed_shift=0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    c = N(dur) * np.exp(-t / 0.004)                      # ani çatlama
    b = np.sin(2 * np.pi * body * t * (1 - t * 0.6)) * np.exp(-t / 0.05)  # gövde
    r = fft_filter(N(dur), 300, bright) * np.exp(-t / tail) * 0.35        # yankı kuyruğu
    x = fft_filter(c, 600, 12000) * 1.0 + b * 0.7 + r
    return reverb(x, 0.9, 0.22)

def boom(dur=3.0, f0=55, low=900, tail=0.9, crackle=0.2):
    n = int(SR * dur); t = np.arange(n) / SR
    thump = np.sin(2 * np.pi * (f0 * np.exp(-t * 2.5)) * t) * np.exp(-t / 0.25)
    rum = fft_filter(N(dur), 20, low) * np.exp(-t / tail)
    hit = fft_filter(N(dur), 200, 6000) * np.exp(-t / 0.03)
    cr = fft_filter(N(dur), 1500, 9000) * (rng.random(n) < 0.002) * np.exp(-t / 0.6) * 6
    x = thump * 1.2 + rum * 1.4 + hit * 0.6 + cr * crackle
    return reverb(x, 1.6, 0.3)

def loop_fade(x, sec=0.4):
    k = int(sec * SR); x = x.copy()
    x[:k] = x[:k] * np.linspace(0, 1, k) + x[-k:] * np.linspace(1, 0, k)
    return x[:-k]

# --- silahlar
for i in range(1, 4):
    save('rifle%d' % i, crack(0.7, 150 + i * 25, 6500, 0.28))
for i in range(1, 3):
    save('mg%d' % i, crack(0.5, 120 + i * 15, 5000, 0.2))
save('pistol', crack(0.45, 260, 7000, 0.15))
for i in range(1, 3):
    save('hmg%d' % i, crack(0.6, 85 + i * 10, 3500, 0.3))
save('autocannon', boom(1.0, 90, 2500, 0.25, 0.0))
save('tank_fire', boom(2.8, 45, 1200, 0.7, 0.0))
for i in range(1, 3):
    save('expl_big%d' % i, boom(4.0, 38 + i * 4, 800, 1.2, 0.6))
    save('expl_med%d' % i, boom(2.6, 55 + i * 6, 1400, 0.7, 0.4))
    save('expl_small%d' % i, boom(1.6, 80 + i * 8, 2200, 0.4, 0.2))
# roket: tıslama + ateşleme
t = T(1.4)
x = fft_filter(N(1.4), 800, 7000) * np.exp(-t / 0.5) * (1 - np.exp(-t / 0.02))
x[:3000] += fft_filter(rng.uniform(-1, 1, 3000), 100, 4000) * np.exp(-np.arange(3000) / 500) * 2
save('rpg', reverb(x, 0.8, 0.2))
# mermi vızıltısı
t = T(0.35)
save('whiz', np.sin(2 * np.pi * (2400 - 1800 * t / 0.35) * t) * np.sin(np.pi * t / 0.35) ** 2 * 0.6 + fft_filter(N(0.35), 2000, 8000) * np.sin(np.pi * t / 0.35) * 0.4)
for i in range(1, 3):
    t = T(0.6)
    f = 1800 + i * 500
    save('ricochet%d' % i, np.sin(2 * np.pi * (f * (1 - t * 0.5)) * t) * np.exp(-t / 0.15) + fft_filter(N(0.6), 3000, 9000) * np.exp(-t / 0.02))
t = T(1.0)
save('hit_metal', reverb(sum(np.sin(2 * np.pi * f * t) * np.exp(-t / d) for f, d in [(420, 0.4), (1130, 0.25), (2470, 0.15), (3810, 0.1)]) + fft_filter(N(1.0), 500, 8000) * np.exp(-t / 0.02) * 2, 0.8, 0.3))
# yıkım
t = T(1.8)
grains = np.zeros(len(t))
for k in range(60):
    p = int(rng.uniform(0, 1.2) * SR); L = int(rng.uniform(0.01, 0.06) * SR)
    if p + L < len(t): grains[p:p + L] += fft_filter(rng.uniform(-1, 1, L), 300, 5000) * np.exp(-np.arange(L) / (L / 4)) * rng.uniform(0.3, 1.0)
save('crumble', reverb(grains + fft_filter(N(1.8), 40, 400) * np.exp(-t / 0.4) * 0.6, 1.0, 0.25))
t = T(3.0)
save('collapse', reverb(np.concatenate([grains, grains * 0.6])[:len(t)] + fft_filter(N(3.0), 30, 300) * np.exp(-t / 0.9), 1.4, 0.3))
t = T(0.3)
save('throw', fft_filter(N(0.3), 400, 3000) * np.sin(np.pi * t / 0.3) * 0.5)
t = T(1.5)
save('smoke_pop', fft_filter(N(1.5), 200, 6000) * np.exp(-t / 0.5) * (1 - np.exp(-t / 0.05)))
t = T(0.25)
save('hammer', reverb(np.sin(2 * np.pi * 900 * t) * np.exp(-t / 0.03) + fft_filter(N(0.25), 800, 6000) * np.exp(-t / 0.01), 0.4, 0.2))

# --- motorlar (döngü)
t = T(4.4)
f0 = 38
x = np.zeros(len(t))
for h, a in [(1, 1.0), (2, 0.6), (3, 0.4), (4, 0.25), (6, 0.15)]:
    x += a * np.sin(2 * np.pi * f0 * h * t + rng.uniform(0, 6))
x *= 1 + 0.25 * np.sin(2 * np.pi * 9 * t)
x += fft_filter(N(4.4), 30, 600) * 1.2
clank = (np.sin(2 * np.pi * 7.5 * t) > 0.97) * fft_filter(N(4.4), 1500, 6000) * 0.8
save('engine_tank', loop_fade(fft_filter(x, 20, 1800) + clank, 0.4), 0.7)
t = T(4.4)
x = np.zeros(len(t))
for h, a in [(1, 1.0), (2, 0.5), (3, 0.35), (5, 0.2)]:
    x += a * np.sin(2 * np.pi * 52 * h * t + rng.uniform(0, 6))
x *= 1 + 0.15 * np.sin(2 * np.pi * 13 * t)
x += fft_filter(N(4.4), 40, 900)
save('engine_truck', loop_fade(fft_filter(x, 30, 2200), 0.4), 0.7)
# ortam
t = T(16.4)
w = fft_filter(N(16.4), 80, 900)
w *= 0.5 + 0.5 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 7.3)) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 3.1 + 1))
save('wind', loop_fade(w, 0.4), 0.5)
far = np.zeros(len(t))
for k in range(55):
    p = int(rng.uniform(0, 15.5) * SR)
    s = boom(1.5, 40, 300, 0.6, 0) if rng.random() < 0.25 else crack(0.4, 100, 1200, 0.2)
    s = fft_filter(s, 20, 900) * rng.uniform(0.05, 0.35)
    L = min(len(s), len(far) - p)
    far[p:p + L] += s[:L]
save('battle_far', loop_fade(far, 0.4), 0.45)

# --- arayüz
def blip(fs, d=0.06, vol=1.0):
    out = []
    for f in fs:
        t = T(d); out.append(np.sin(2 * np.pi * f * t) * np.exp(-t / (d / 3)) * vol)
    return np.concatenate(out)
save('ui_click', blip([1500], 0.03), 0.5)
save('ui_select', blip([900, 1300], 0.04), 0.45)
save('ui_move', blip([700, 1050], 0.05), 0.45)
save('ui_attack', blip([600, 450], 0.06), 0.5)
save('ui_place', blip([500, 750, 1000], 0.05), 0.5)
save('ui_error', blip([300, 220], 0.09), 0.5)
save('ui_done', blip([800, 1000, 1350], 0.07), 0.5)
save('ui_alert', blip([1200, 900, 1200, 900], 0.07), 0.55)
save('win', reverb(blip([523, 659, 784, 1046], 0.22), 1.5, 0.35), 0.6)
save('lose', reverb(blip([392, 330, 262, 196], 0.28), 1.5, 0.35), 0.6)

# helikopter (döngü): pal darbesi + türbin
t = T(4.4)
blade = 18.0
thump = np.zeros(len(t))
ph = (t * blade) % 1.0
thump = np.exp(-ph * 18) * fft_filter(N(4.4), 40, 500) * 2.5
whine = np.sin(2 * np.pi * 1450 * t) * 0.05 + np.sin(2 * np.pi * 2900 * t) * 0.02
save('heli', loop_fade(thump + fft_filter(N(4.4), 60, 1200) * 0.4 + whine, 0.4), 0.7)
