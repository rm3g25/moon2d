"""Renders Selene as the menu would show her, in "photo" light: a sun
glint on the sea, blue haze toward the limb, a warm soft terminator, and
clouds with their shadows. Reads the maps paint_selene.py wrote to out/.

  python preview_globe.py      out/selene-globe.png (the approved look)
                               out/selene-sheet.png (moon vs Selene,
                               straight and tilted 30 to show the pole)

Everything but the clouds depends only on the disc pixel - the sun stands
still in the menu - so a game renderer can precompute it per disc pixel
the way Menu.Globe precomputes Shade; the clouds cost a second texture
walk per frame.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

OutDir = Path(__file__).parent / 'out'
Radius = 200
Tile = 450
SunDir = np.array([-0.55, 0.40, 0.73]) # x right, y up, z to the viewer
SunDir /= np.linalg.norm(SunDir)
HalfVec = SunDir + np.array([0, 0, 1.0])
HalfVec /= np.linalg.norm(HalfVec)
Haze = np.array([0.42, 0.60, 0.92])


def load(path, gray=False):
    im = Image.open(path).convert('L' if gray else 'RGB')
    if im.size != (2048, 1024):
        im = im.resize((2048, 1024), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64) / 255
    return a[..., None] if gray else a


def sample(tex, lat, lon):
    h, w, _ = tex.shape
    u = (lon / (2 * np.pi) + 0.5) % 1.0 * w - 0.5
    v = np.clip((0.5 - lat / np.pi) * h - 0.5, 0, h - 1)
    u0, v0 = np.floor(u).astype(int), np.floor(v).astype(int)
    fu, fv = (u - u0)[..., None], (v - v0)[..., None]
    u1, v1 = (u0 + 1) % w, np.minimum(v0 + 1, h - 1)
    u0 %= w
    top = tex[v0, u0] * (1 - fu) + tex[v0, u1] * fu
    bot = tex[v1, u0] * (1 - fu) + tex[v1, u1] * fu
    return top * (1 - fv) + bot * fv


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def render(tex, spin_deg, tilt_deg, photo, water=None, clouds=None):
    yy, xx = np.mgrid[0:Tile, 0:Tile]
    px = (xx + 0.5 - Tile / 2) / Radius
    py = -(yy + 0.5 - Tile / 2) / Radius
    r2 = px * px + py * py
    dist = np.sqrt(r2)
    inside = r2 <= 1.0
    pz = np.sqrt(np.clip(1 - r2, 0, 1))
    # tilt: the viewer rises above the equator by tilt_deg
    t = np.radians(tilt_deg)
    wy = py * np.cos(t) + pz * np.sin(t)
    wz = -py * np.sin(t) + pz * np.cos(t)
    lat = np.arcsin(np.clip(wy, -1, 1))
    lon = np.arctan2(px, wz) + np.radians(spin_deg)

    color = sample(tex, lat, lon)
    normal = np.stack([px, py, pz], axis=-1)
    ndl = normal @ SunDir

    if not photo:
        light = np.clip(ndl, 0, 1)[..., None] ** 0.85
        out = color * light + color * 0.2
        alpha = np.clip((1 - dist) * Radius + 0.5, 0, 1)[..., None]
        return np.clip(out * alpha, 0, 1)

    if clouds is not None:
        cover = sample(clouds, lat, lon)
        # the shadow of a cloud lies a little away from the sun
        shadow = sample(clouds, lat - 0.006, lon + 0.008)
        color = color * (1 - 0.45 * shadow)
    # soft terminator with a warm band where the light grazes
    light = smoothstep(-0.12, 0.9, ndl)[..., None]
    warm = 1 - smoothstep(0.0, 0.3, ndl)
    tint = np.stack([1 + 0.0 * warm, 1 - 0.22 * warm, 1 - 0.45 * warm], -1)
    out = color * light * tint * 1.12
    if water is not None:
        wet = sample(water, lat, lon)
        if clouds is not None:
            wet = wet * (1 - cover)
        spec = np.clip(normal @ HalfVec, 0, 1) ** 220
        out = out + wet * spec[..., None] * np.array([1.0, 0.92, 0.8]) * 0.55
    if clouds is not None:
        cloud_col = np.array([0.97, 0.97, 0.98]) * light * tint
        out = out * (1 - cover) + cloud_col * cover
    # thicker air toward the limb washes the ground out to blue
    limb = ((1 - pz) ** 1.8)[..., None]
    day = smoothstep(-0.2, 0.6, ndl)[..., None]
    out = out * (1 - limb * 0.55) + Haze * limb * 0.75 * day
    out = out + color * 0.012 # earthshine on the night side
    alpha = np.clip((1 - dist) * Radius + 0.5, 0, 1)[..., None]
    out = out * alpha
    halo = np.where(~inside, np.exp(-(dist - 1) * 32), 0)
    halo_day = smoothstep(-0.4, 0.5, px * SunDir[0] + py * SunDir[1] + 0.25)
    out = out + (halo * halo_day)[..., None] * Haze * 0.8
    return np.clip(out, 0, 1)


def save(img, path):
    Image.fromarray((img * 255 + 0.5).astype(np.uint8)).save(path)


def main():
    moon = load('moonmap.png')
    selene = load(OutDir / 'selenemap.png')
    water = load(OutDir / 'selenemap-water.png', gray=True)
    clouds = load(OutDir / 'selenemap-clouds.png', gray=True)
    save(render(selene, 0, 0, True, water, clouds), OutDir / 'selene-globe.png')

    cols = [('Moon, menu light', lambda s, t: render(moon, s, t, False)),
            ('Selene, no clouds', lambda s, t: render(selene, s, t, True, water)),
            ('Selene', lambda s, t: render(selene, s, t, True, water, clouds))]
    views = [(0, 0), (40, 30)]
    sheet = Image.new('RGB', (Tile * len(cols), Tile * len(views)), (3, 4, 9))
    draw = ImageDraw.Draw(sheet)
    rng = np.random.default_rng(3)
    for _ in range(600):
        b = int(rng.integers(50, 190))
        draw.point((int(rng.integers(0, sheet.width)),
                    int(rng.integers(0, sheet.height))), fill=(b, b, b))
    for ci, (label, fn) in enumerate(cols):
        for ri, (spin, tilt) in enumerate(views):
            img = fn(spin, tilt)
            tile = Image.fromarray((img * 255 + 0.5).astype(np.uint8))
            mask = Image.fromarray((np.clip(img.max(axis=2) * 8, 0, 1) * 255)
                                   .astype(np.uint8))
            sheet.paste(tile, (ci * Tile, ri * Tile), mask)
            view = 'straight' if tilt == 0 else f'tilted {tilt}, north pole'
            draw.text((ci * Tile + 12, ri * Tile + 10), f'{label} - {view}',
                      fill=(205, 205, 215))
    sheet.save(OutDir / 'selene-sheet.png')


if __name__ == '__main__':
    main()
