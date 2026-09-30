"""Shared pieces of the Selene painter: sphere-sampled noise, wrap-aware
filters, and the river tracer.

Every map here is equirectangular, 2:1, longitude -180..180 left to right.
Filters wrap horizontally and clamp vertically, and noise is sampled on
the unit sphere rather than the flat map, so nothing seams at the date
line or pinches at the poles.
"""
import numpy as np
from scipy import ndimage

RiverCount = 60
RiverMinLength = 70


def blur(a, sigma):
    # wrap horizontally (longitude), clamp vertically (poles)
    return ndimage.gaussian_filter(a, sigma, mode=('nearest', 'wrap'))


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def mix(a, b, t):
    return a + (b - a) * t[..., None]


def sphere_coords(h, w):
    lat = (0.5 - (np.arange(h) + 0.5) / h) * np.pi
    lon = ((np.arange(w) + 0.5) / w) * 2 * np.pi - np.pi
    lon, lat = np.meshgrid(lon, lat)
    x = np.cos(lat) * np.cos(lon)
    y = np.cos(lat) * np.sin(lon)
    z = np.sin(lat)
    return x, y, z, np.degrees(lat)


class Noise3:
    """Value noise on a 3D lattice, trilinear, fBm on top."""

    def __init__(self, seed, size=64):
        rng = np.random.default_rng(seed)
        self.size = size
        self.grid = rng.random((size, size, size))

    def value(self, x, y, z):
        n = self.size
        xi, yi, zi = np.floor(x), np.floor(y), np.floor(z)
        fx, fy, fz = x - xi, y - yi, z - zi
        fx, fy, fz = [f * f * (3 - 2 * f) for f in (fx, fy, fz)]
        xi, yi, zi = [v.astype(np.int64) % n for v in (xi, yi, zi)]
        g = self.grid
        res = 0
        for dx in (0, 1):
            for dy in (0, 1):
                for dz in (0, 1):
                    wgt = ((fx if dx else 1 - fx) * (fy if dy else 1 - fy) *
                           (fz if dz else 1 - fz))
                    res = res + wgt * g[(xi + dx) % n, (yi + dy) % n,
                                        (zi + dz) % n]
        return res

    def fbm(self, x, y, z, freq, octaves, gain=0.5):
        total, amp, norm = 0, 1.0, 0
        for o in range(octaves):
            f = freq * (2 ** o)
            total = total + amp * self.value(x * f + 17.3 * o, y * f + 5.1 * o,
                                             z * f + 9.7 * o)
            norm += amp
            amp *= gain
        return total / norm # 0..1, centered ~0.5


def stamp_disc(target, pr, pc, radius):
    h, w = target.shape
    for rr in range(int(pr - radius - 1), int(pr + radius + 2)):
        if rr < 0 or rr >= h:
            continue
        for cc in range(int(pc - radius - 1), int(pc + radius + 2)):
            v = min(max(radius + 0.5 - np.hypot(rr - pr, cc - pc), 0), 1)
            if v > target[rr, cc % w]:
                target[rr, cc % w] = v


def trace_rivers(height, water, land_h, rng):
    h, w = height.shape
    rivers = np.zeros_like(height)
    lakes = np.zeros_like(height)
    # a river that comes near another one joins it instead of running beside
    taken = np.zeros(height.shape, dtype=bool)
    cand = np.argwhere((~water) & (land_h > 0.25) & (land_h < 0.9))
    # keep away from the smeared polar rows
    cand = cand[(cand[:, 0] > h * 0.22) & (cand[:, 0] < h * 0.78)]
    rng.shuffle(cand)
    made = 0
    for r0, c0 in cand:
        if made >= RiverCount:
            break
        if taken[r0, c0]:
            continue
        path = [(r0, c0)]
        r, c = r0, c0 # c is unwrapped, so the smoothing below never jumps
        seen = {(r, c % w)}
        ended_in_water = False
        for _ in range(900):
            best, br, bc = height[r, c % w], None, None
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    if dr == 0 and dc == 0:
                        continue
                    rr, cc = r + dr, c + dc
                    if rr < 0 or rr >= h:
                        continue
                    if height[rr, cc % w] < best:
                        best, br, bc = height[rr, cc % w], rr, cc
            if br is None:
                break # a pit: may become a lake below
            r, c = br, bc
            if (r, c % w) in seen:
                break
            seen.add((r, c % w))
            path.append((r, c))
            if water[r, c % w] or taken[r, c % w]:
                ended_in_water = True
                break
        if len(path) < RiverMinLength:
            continue
        pts = np.array(path, dtype=np.float64)
        # an 8-way walk draws stairs; a moving average turns them into bends
        k = 21
        padded = np.vstack([np.repeat(pts[:1], k, 0), pts, np.repeat(pts[-1:], k, 0)])
        kernel = np.ones(k) / k
        smooth = np.stack([np.convolve(padded[:, j], kernel, 'same')[k:-k]
                           for j in (0, 1)], axis=1)
        # a slope-following walk runs straight for long stretches; real
        # rivers do not, so bend it sideways along its own length
        tangent = np.gradient(smooth, axis=0)
        tangent /= np.linalg.norm(tangent, axis=1, keepdims=True) + 1e-9
        normal = np.stack([-tangent[:, 1], tangent[:, 0]], axis=1)
        s_len = np.arange(len(smooth), dtype=np.float64)
        phase = rng.uniform(0, 2 * np.pi, 2)
        swing = (3.5 * np.sin(s_len / 11.0 + phase[0]) +
                 2.0 * np.sin(s_len / 4.7 + phase[1]))
        fade = np.minimum(1, np.minimum(s_len, s_len[::-1]) / 12.0)
        smooth += normal * (swing * fade)[:, None]
        smooth[-1] = pts[-1] # the mouth stays where the water is
        n = len(smooth)
        for i in range(n - 1):
            a, b = smooth[i], smooth[i + 1]
            width = 0.7 + 1.5 * (i / n)
            steps = max(int(np.hypot(*(b - a)) * 2), 1)
            for t in np.linspace(0, 1, steps, endpoint=False):
                pr, pc = a + (b - a) * t
                stamp_disc(rivers, pr, pc, width)
        for pr, pc in pts.astype(int):
            rr0, rr1 = max(pr - 9, 0), min(pr + 10, h)
            cols = np.arange(pc - 9, pc + 10) % w
            taken[rr0:rr1][:, cols] = True
        if not ended_in_water and rng.random() < 0.4:
            pr, pc = smooth[-1]
            stamp_disc(lakes, pr, pc, rng.uniform(3, 7))
        made += 1
    return rivers, lakes, made
