"""Paints Selene - the living anti-moon of the lore - over the menu's moon
map, aiming at "photo from orbit", not "atlas".

Dark albedo (old lava plains) stands in for lowland and becomes sea, so
the Moon's face stays recognizable. Land colour comes from a climate
model: latitude belts, moisture from the coast, cold with height. Relief
is baked in as hill shading, rivers are forest corridors. Clouds and the
water mask are separate maps so a renderer can spin the clouds on their
own and put a sun glint on the sea.

  python paint_selene.py [moonmap.png]        surface + water mask
  python paint_selene.py clouds               cloud layer

Outputs go to out/, 2048x1024 like the menu's moonmap:
  selenemap.png         surface
  selenemap-water.png   255 = sea (ice excluded)
  selenemap-clouds.png  255 = opaque cloud

Every random choice is seeded: the same moonmap gives the same planet.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage
from selene_lib import Noise3, blur, smoothstep, mix, sphere_coords, trace_rivers

OutDir = Path(__file__).parent / 'out'

Seed = 1999
SeaShare = 0.28 # darkest share of the lit rows that becomes water
IceCapLat = 72.0
MinLakeArea = 40 # water specks smaller than this (px) dry up
ReliefStrength = 4.0


def C(*v):
    return np.array(v, dtype=np.float64)[None, None] / 255


def climate_moisture(lat, noise_field, coast_dist):
    alat = np.abs(lat)
    # Hadley cells: wet equator, dry 20-30, wet storm tracks 45-60
    belt = (0.62 * np.exp(-(lat / 13.0) ** 2) +
            0.50 * np.exp(-((alat - 52) / 13.0) ** 2) + 0.18)
    coast = 0.30 * np.exp(-coast_dist / 55.0)
    return np.clip(belt + coast + (noise_field - 0.5) * 0.95, 0, 1.2)


def hillshade(height, lat):
    # equirect texels are narrower toward the poles: steepen x accordingly
    coslat = np.clip(np.cos(np.radians(lat)), 0.15, 1)
    gy = np.gradient(height, axis=0)
    # x wraps around the date line; np.gradient would go one-sided there
    gx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) / 2
    gx = gx / coslat
    nx, ny, nz = -gx * ReliefStrength, gy * ReliefStrength, np.ones_like(gx)
    norm = np.sqrt(nx * nx + ny * ny + nz * nz)
    light = np.array([-0.6, 0.6, 0.53]) # from north-west, fairly low
    light /= np.linalg.norm(light)
    shade = (nx * light[0] + ny * light[1] + nz * light[2]) / norm
    flat = light[2]
    return shade / flat # 1.0 = flat ground


def paint(moonmap_path):
    src = np.asarray(Image.open(moonmap_path).convert('RGB'), dtype=np.float64) / 255
    albedo = src.mean(axis=2)
    h, w = albedo.shape
    x, y, z, lat = sphere_coords(h, w)
    alat = np.abs(lat)
    noise = Noise3(Seed)
    rng = np.random.default_rng(Seed)

    coast_coarse = noise.fbm(x, y, z, 6.0, 5) - 0.5
    coast_fine = noise.fbm(x + 9, y, z, 40.0, 3) - 0.5
    moist_noise = noise.fbm(x + 3, y, z, 3.5, 5)
    grain = noise.fbm(x, y + 7, z, 26.0, 3) - 0.5
    ridged = 1 - np.abs(noise.fbm(x, y, z + 4, 9.0, 5) * 2 - 1)

    relief = blur(albedo, 5) - blur(albedo, 90)
    shaped = relief + coast_coarse * 0.03 + coast_fine * 0.012
    lit = shaped[int(h * 0.15):int(h * 0.85)]
    sea_level = np.percentile(lit, SeaShare * 100)
    top, bottom = np.percentile(lit, 97), np.percentile(lit, 2)
    water = shaped < sea_level

    # drop specks: tiny water blobs become land
    labels, count = ndimage.label(water)
    sizes = ndimage.sum(water, labels, index=np.arange(1, count + 1))
    water = water & (sizes[labels - 1] >= MinLakeArea) & (labels > 0)
    water_t = ndimage.gaussian_filter(water.astype(np.float64), 0.7,
                                      mode=('nearest', 'wrap'))

    land_h = np.clip((shaped - sea_level) / (top - sea_level), 0, 1)
    depth = np.clip((sea_level - shaped) / (sea_level - bottom), 0, 1)
    coast_dist = ndimage.distance_transform_edt(~water)

    # height for shading: broad land height, crater rims from the moon
    # itself, and ridged mountain chains where the land is high
    craters = blur(albedo, 1.2) - blur(albedo, 6)
    mountains = ridged ** 2 * smoothstep(0.45, 0.9, land_h)
    height = land_h * 0.6 + craters * 0.9 + mountains * 0.9
    height = np.where(water, 0.0, height)
    shade = hillshade(blur(height, 0.8), lat)
    # the source map is smeared near the poles: no relief from there
    shade = 1 + (shade - 1) * smoothstep(68, 58, alat)
    gy, gx = np.gradient(blur(height, 1.5))
    slope = np.hypot(gx, gy) * 60
    detail = np.clip(albedo / (blur(albedo, 3) + 1e-4), 0.7, 1.4)

    moisture = climate_moisture(lat, moist_noise, coast_dist)
    temperature = 1.0 - (alat / 80.0) ** 2.2 - land_h * 0.4 + grain * 0.1

    rain_forest, forest = C(28, 50, 22), C(46, 64, 30)
    boreal, savanna = C(34, 46, 30), C(118, 110, 64)
    desert, red_desert = C(192, 166, 118), C(170, 124, 82)
    tundra, rock, snow = C(104, 96, 78), C(90, 80, 64), C(232, 236, 240)

    green = mix(savanna, forest, smoothstep(0.35, 0.62, moisture))
    green = mix(green, rain_forest,
                smoothstep(0.75, 0.95, moisture) * smoothstep(0.6, 0.85, temperature))
    arid = mix(red_desert, desert, smoothstep(0.3, 0.6, moist_noise))
    arid = arid + (savanna - arid) * 0.35
    land = mix(arid, green, smoothstep(0.2, 0.42, moisture))
    land = mix(land, boreal, smoothstep(0.48, 0.3, temperature) * smoothstep(0.3, 0.5, moisture))
    land = mix(land, tundra, smoothstep(0.3, 0.12, temperature))
    rockiness = (land_h * 0.55 + mountains * 0.5 + np.clip(slope, 0, 1) * 0.35 +
                 grain * 0.3)
    land = mix(land, rock, smoothstep(0.6, 1.0, rockiness) * 0.7)
    snowline = smoothstep(0.1, -0.02, temperature + grain * 0.15 - mountains * 0.12)
    land = mix(land, snow, snowline)

    # rivers: forest corridors, water only near the mouth of long ones
    meander = noise.fbm(x, y, z + 11, 14.0, 3) - 0.5
    field = (blur(albedo, 14) - blur(albedo, 90) + coast_coarse * 0.012 +
             meander * 0.012)
    rivers, lakes, _ = trace_rivers(field, water, land_h, rng)
    land = mix(land, forest * 0.85, np.clip(blur(rivers, 3) * 1.6, 0, 0.5))
    land = mix(land, C(24, 44, 58), np.clip(rivers - 0.6, 0, 1) * 1.2)
    land = mix(land, C(16, 36, 62), lakes)

    land = land * np.clip(shade, 0.45, 1.5)[..., None]
    land = land * (detail[..., None] ** 0.45)
    land = land * (0.94 + grain[..., None] * 0.22)

    deep, mid, shallow = C(6, 16, 40), C(12, 34, 70), C(34, 78, 96)
    sea = mix(shallow, mid, smoothstep(0.0, 0.1, depth))
    sea = mix(sea, deep, smoothstep(0.1, 0.8, depth))
    sea = sea * (0.96 + grain[..., None] * 0.12)

    out = mix(land, sea, water_t)

    ice = smoothstep(IceCapLat - 2, IceCapLat + 3, alat + coast_coarse * 12)
    ice_col = C(226, 234, 242) * (0.93 + grain[..., None] * 0.12)
    out = mix(out, ice_col, ice)
    water_mask = water_t * (1 - ice)

    out = np.clip(out, 0, 1) ** 0.95
    OutDir.mkdir(exist_ok=True)
    Image.fromarray((out * 255 + 0.5).astype(np.uint8)).save(OutDir / 'selenemap.png')
    Image.fromarray((water_mask * 255 + 0.5).astype(np.uint8)).save(
        OutDir / 'selenemap-water.png')
    print(f'water {water.mean():.0%}')


def clouds():
    h, w = 1024, 2048
    x, y, z, lat = sphere_coords(h, w)
    alat = np.abs(lat)
    noise = Noise3(77)
    # domain warp twice: turns blobs into swirls and streaks
    zs = z * 1.8 # stretch east-west
    q = [noise.fbm(x + o, y, zs, 2.5, 4) - 0.5 for o in (0.0, 5.2, 9.1)]
    x1, y1, z1 = x + q[0] * 0.7, y + q[1] * 0.7, zs + q[2] * 0.45
    r = [noise.fbm(x1 + o, y1, z1, 3.5, 4) - 0.5 for o in (1.7, 8.3, 2.8)]
    x2, y2, z2 = x1 + r[0] * 0.22, y1 + r[1] * 0.22, z1 + r[2] * 0.15
    base = noise.fbm(x2, y2, z2, 4.0, 7)
    fine = noise.fbm(x2, y2, z2, 24.0, 4)
    # where clouds live: equator band, storm tracks, little over the subtropics
    belt = (0.10 * np.exp(-(lat / 7.0) ** 2) +
            0.12 * np.exp(-((alat - 55) / 12.0) ** 2) -
            0.07 * np.exp(-((alat - 25) / 8.0) ** 2))
    c = base + belt + (fine - 0.5) * 0.22
    cover = smoothstep(0.47, 0.68, c) ** 1.3 * 0.95
    OutDir.mkdir(exist_ok=True)
    Image.fromarray((cover * 255 + 0.5).astype(np.uint8)).save(
        OutDir / 'selenemap-clouds.png')
    print(f'cloud cover {cover.mean():.0%}')


if __name__ == '__main__':
    if 'clouds' in sys.argv[1:]:
        clouds()
    else:
        paint(sys.argv[1] if len(sys.argv) > 1 else 'moonmap.png')
