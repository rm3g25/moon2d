# Selene

Paints Selene - the living anti-moon of the lore - as a map for the menu
globe: the same face as the Moon, but with seas, forests, deserts, ice caps
and a cloud layer. Nothing in the game reads these maps yet; the tool and
its approved output sit here until Selene reaches the menu (see
PORTING-NOTES, "ИДЕЯ 3.x - СЕЛЕНА В МЕНЮ").

## Run

Python 3 with `numpy`, `scipy` and `pillow`. From this folder:

1. `python extract_moonmap.py` - pulls `moonmap` out of `bin/sprites/ui.mset`
   into `moonmap.png` (the painter's only input).
2. `python paint_selene.py` - surface and water mask, about a minute and a
   half.
3. `python paint_selene.py clouds` - the cloud layer.
4. `python preview_globe.py` - `out/selene-globe.png` (the approved look) and
   `out/selene-sheet.png` (Moon vs Selene, straight and tilted 30 degrees to
   show the pole).

Every random choice is seeded, so the same `moonmap` gives the same planet
bit for bit. `out/` keeps the approved maps; `moonmap.png` and the sheet are
regenerated, not committed.

## Output

| File | What |
| --- | --- |
| `out/selenemap.png` | Surface, 2048x1024 equirectangular - the shape `Menu.Globe` demands of `moonmap` |
| `out/selenemap-water.png` | 255 = open sea (ice excluded); for the sun glint |
| `out/selenemap-clouds.png` | 255 = opaque cloud; meant to spin on its own |
| `out/selene-globe.png` | Preview in "photo" light |

## How it paints

- **Sea = dark albedo.** The maria are old lava plains, so they stand in for
  lowland. The continental-scale exposure of the photo is subtracted first,
  or the whole darker north floods. The darkest 28% of the lit rows is sea.
- **Height = brightness above sea level.** A stand-in: there is no elevation
  map in the input (see Limits).
- **Colour from climate, not from noise blobs.** Wet equator, deserts near 25
  degrees, wet storm tracks near 52, wetter along coasts, colder with height.
  Muted tones in the range of orbital photos of Earth, not of an atlas.
- **Relief is baked in** as hill shading: land height, the Moon's own crater
  rims, and ridged mountain chains where land is high. Relief fades out above
  58-68 degrees, where the source map is smeared.
- **Rivers** follow the slope of the blurred albedo, bend along their length,
  merge when they meet, and show as forest corridors; open water only near
  the mouths of long ones.
- **Clouds**: domain-warped noise stretched east-west, denser over the
  equator and the storm tracks, thin over the subtropics.
- All noise is sampled on the unit sphere and filters wrap in longitude, so
  there is no seam at the date line and no pinch at the poles.

## Limits

- The input is the menu's `moonmap`, whose two halves are nearly the same
  picture (correlation 0.97 at a shift of 1024 px): the globe shows the near
  side twice and has no far side - so Selene has one face twice as well.
- Brightness is not height: mountains stand where the Moon is bright (Tycho's
  rays, highlands), not where it is high.
- Both go away with real data: the LROC colour map and the LOLA elevation map
  from NASA's CGI Moon Kit, https://svs.gsfc.nasa.gov/4720 (credit "NASA's
  Scientific Visualization Studio"). `ldem_4.tif` and `lroc_color_poles_2k.tif`
  are enough for a 2048 map. The far side then gets the South Pole-Aitken
  basin, which floods into one great ocean.
- Three steps do not wrap in longitude - the slope gradient, the distance to
  the coast, and the small-lake filter - so pixels at the date line differ
  slightly more than elsewhere (mean 2.7 against 2.1 levels). Not visible on
  the globe; wrap them when the painter next changes, since that shifts the
  approved pixels near the seam.
