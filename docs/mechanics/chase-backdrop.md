# The chase backdrop: out of the tunnel, past the city

The far plane of act 2 (arena-3.md, "Decided 2026-10-30, the chase"): the
end of the tunnel and the city in the crater, built from separate
elements. The numbers are in `bin/chase-backdrop.json` - game data the
level names in its `farPlane` section, and the very file the stand plays
(moved there from `tools/chase/layout.json` with 3.0.88): what is tuned
on the stand is what the game plays. The code: `Levels.FarPlane`,
`Game.FarPlane`, `Render.FarPlane` (arena-3.md, "Stage 11b-1 as built"),
the dome frames `Render.DomeFrames` (arena-3.md, "The city's frames as
built").
The numbers below are the ones after the live runs of 3.0.88 ("Decided
2026-10-31, the far plane" in arena-3.md). The city was rebuilt on
2026-11-01 ("The city" below, and "Decided 2026-11-01, the city" in
arena-3.md): buildings cut from sheets and placed in depth, the dome frames
drawn by code.

## The strip, left to right

```
ground layer  near hills, a seamless band, y 276 down - in front of the tunnel, from the arena's first frame
tunnel layer  |== screen 13 wall ==|~cliff~>
city layer          (behind the cliff)  [ main dome frame + city ]==monorail==[ sat dome frame + industry ]  . ..  .  (outskirts)
ridge layer   ~~~~~~~~~~~~~~~~~~~~~~~~ far crater rim (seamless) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sky           black; the sun is code, fixed on the screen at (288, 208)
```

- **Screen 13's wall** opens the strip as it is - the chase starts on the
  picture of the fight. The far lip, the pillars, the convoys and the
  searchlight ride with it; the convoys stop coming where the strata end.
- **The cliff** - the end of the tunnel's far wall: horizontal strata ending
  in a ragged stepped edge, beyond it nothing. 228 units wide (the first
  generation, 911 by 1536 px trimmed, set by its height of 384). It stands at
  x 400: its left 64 units fade into the wall of 13 (400-464), solid to 512,
  so the join is rock over dark rock along horizontal bands, never through an
  object; every notch of its edge lies right of 512 (the nearest at 517).
- **The overlap is on the screen for the whole fight.** The cliff's part
  over 400-512 is there from the first frame of the arena, not from the
  start of the chase - otherwise the right of the backdrop would change
  under the player the moment the belt starts. It is drawn by code over
  `screen13`, not baked into its picture (decided 2026-10-31): the same
  pixels, nothing to regenerate. Its top goes black into the vault, as
  13's does. No gate and no lights in it - the gate is 13's.
- **The shoulder.** At the sun's height (y 184-230, 48-60% of the cliff) the
  edge is one sloping shoulder descending to the right at 25-30 degrees, not
  steps. The sun is drawn behind the rock, so the slope does it with no code:
  the top of the disc shows first, then the rest as the slope slides off -
  a sunrise over a mountainside, about 7 s for the disc at the wall's 6 a
  second, half a minute and more for the halo.
- **The main dome** stands almost behind the cliff (city-x 468-980): its right
  part shows the moment the rock opens. Its frame is code, the city inside it
  a hundred-odd buildings of the kit placed in depth ("The city").
- **The monorail** - an end station in each dome (the main dome's mirrored,
  its stub to the right), the beam between them at their stub's height on
  pylons every 58 units, at the depth of y 264 ("The monorail" under "The
  city").
- **The satellite dome**, industry (1300-1660): a coarser frame over the
  plant.
- **The outskirts** - small clusters of low buildings on the open crater
  (1700-2470), then empty crater: the last screen is the brake zone.

The city layer is 2688 units long, 5.25 screens.

## Layers and speeds

Back to front. Units a second at cruise; the belt's ramp of 2 s starts all
of them, and its stop stands them.

| Layer | What | Speed |
|---|---|---|
| sky | black, the sun and its halo (code) | 0 |
| ridge | far crater rim, a seamless band, y 202-262 | 0.35 of the city |
| city | crater floor band (`floor-tex`, y 238-320, its top faded over 16 units, its foot under the hills), the dome frames, the buildings, the rail, the outskirts | 0.5 of the tunnel while the cliff is in sight, then 3; a building k of it by its depth |
| tunnel | screen 13 and its far ledge, the cliff | 6 |
| ground | the near hills (`sand-tex`, seamless, y 276 down), in front of the tunnel | 14 |
| fangs | spurs of basalt at random, behind the play layer, from the start (`Game.Fangs`, arena-3.md "Stage 11b-2 as built") | 20 |
| road | the floor tile | 33 |

- **Depth sets the speed.** The far wall carries tiny convoys - far off, as
  the whole arena told the player - so it rides slowly; the city behind
  it slower, the rim slowest; the near hills fast. The first build ran the
  tunnel's layer at 30 (the near hills in it, their start hidden under the
  cliff) and the city at 12 to 7: the far things rushed past. The layout
  keeps the peak, the cruise and the ease of the tunnel; with the peak at
  the cruise the ease does nothing.
- **The near hills stand from the arena's first frame**, in front of the
  wall's foot, and keep 30% of their colour while the tunnel is all on
  the screen (`shadeInTunnel` 0.3) - as dark as the wall around them; they
  brighten as the tunnel leaves, to the full once it is gone. A start
  fading in from the right was tried and read as ground out of nowhere.
- **The brake.** Within the last screen of the city layer its speed goes
  down in proportion to what is left, to a floor of 0.3, never past its
  end; the ridge follows, being a share of it. The tunnel and the hills do
  not brake.

## Timeline (the stand's simulation of the layout)

| t | what |
|---|---|
| 20.5 s | the nearest notch of the cliff passes x 400: the city opens on the right |
| 52.7 s | the shoulder slides off the sun: it rises over the slope, white and hard |
| 61.0 s | the main dome comes in front of the sun: pink-orange |
| 105.7 s | the cliff is gone |
| 232 s | the main dome leaves the sun: white again over the monorail |
| 338 s | the satellite dome takes the sun |
| 458 s | the sun is free over the outskirts |
| 556 s | the brake zone begins |

So a fight of a few minutes sees the main dome and the city in it - what
matters; the satellite dome and the outskirts come only if it drags on.

## The sun

- A disc of 7 units at (288, 208) - right of the middle, left of where the
  machine rides, so it never sits behind the hatch. The ridge's skyline
  (200-214) cuts its lower part.
- A halo of 120 units, additive, over the black sky; the stars are not drawn:
  a low sun on an airless sky drowns them in its glare, and the reference
  has none.
- **The tint.** Each dome marked `tintsSun` in the layout gives its span in
  city-x; while the sun's x falls inside it on the screen, the sun's colour
  goes from white (255, 250, 240) to pink-orange (255, 128, 112), ramped over
  48 units at each end of the span.
- Drawn under every layer: the rock of the cliff hides it, and it comes out
  from behind the edge by itself.

## Size and resolution

- The game letterboxes its 512 x 384 units into the screen's height and draws
  HD textures with linear filtering: 2.8125 px a unit at 1080p, 5.625 at 4K.
- The canvas of the stand is 1440x1080 (1080p) or 2880x2160 (4K), switched
  on the stand; "real pixels" shows it 1:1. Fitted to the page, the stand is
  softer than the game: the browser scales it down once more.
- The elements: the target is 5.625 px a unit, the cap 2048 px a side. The
  main dome (512 units, 4.0 px a unit) is drawn 1.4x down at 1080p and 1.4x up
  at 4K; the cliff (384 tall, 5.3) is near 4K's own. If 4K shows the dome
  soft, the fix is two generations a dome, never a seam through one.
- ChatGPT gives about 1536-1950 px; `check_element.py` scales to the layout's
  box within 2048.

## The light, one for all

Every element is lit as if the sun stood behind it, low - contre-jour: thin
bright rims on the tops and silhouettes, the faces in soft shadow with a
little warm bounce from the ground. The sun is fixed on the screen while
the objects ride past it, so any light from one side would be wrong on the
other half of the strip; light from behind is right on both. The cliff is
the one exception: it is always left of the sun, so it is lit from the right
and behind, as in the reference. The first generations of the city came
lit from one side all the same and read as cardboard: the city was rebuilt
("The city"). The sheets of buildings come lit from the front whatever the
prompt says; the shade puts their faces in the night, and the frames carry
the contre-jour.

No haze, fog, god rays or bloom in any element: vacuum. The glow is the
code's sun.

**The shade.** The generations come out brighter than the night around
them, the domes most of all. An element's `shade` in the layout (0 to 1, 1
when absent) scales its colour as drawn - in the game
`SDL_SetTextureColorMod` with 255 times it, on the stand `brightness()` - so
the pictures stay as generated and the level is set on the stand by eye. It
dims the neon with the rest; the flickering sign is an additive spot of its
own over it.

## The city (2026-11-01)

**Geometry is code, paint is the generation's.** A dome frame is ribs and
rings - mathematics; asked of an image model it came baked into the
pixels, lit from one side, and could not turn as it rode past the sun. So
the frames are drawn by code in a 3D of their own, and the generations
give only what is paint: the buildings.

**The buildings come from sheets.** One generation draws many buildings in
a row on a transparent ground, a gap between any two - one light, one eye
height, one window grid for all of them. `cut_sheet.py` cuts a sheet into
one PNG a building and cleans the coloured fringe off its edge. Four
sheets, at one scale (645 px for the tallest tower, 110 units: 5.9 px a
unit, 4K's own):

| Sheet | Pieces | Height | What |
|---|---|---|---|
| landmarks, `land-01..05` | 5 | 78-110 | the centre: a capsule tower, twin slabs with sky bridges, a stack of discs, an A-frame arcology, a leaning wedge on a truss |
| housing, `house-01..10` | 10 | 16-55 | slab blocks, stacked modules, a terraced block, a round tower, twin narrow towers, a school, a greenhouse vault, the monorail station |
| outskirts, `low-01..16` | 16 | 11-29 | townhouse rows, pods on legs, a ring court, a water tank, a mast, kiosks, sheds |
| industry, `ind-01..11` | 11 | 22-69 | cooling towers, a sphere and three tanks, two cranes, a pipe rack, a mast, a sawtooth workshop, a chimney, a control building |

Their sizes in units at k = 1 are the layout's `cityKit`; every piece is
packed into the set, placed or not.

**The style: the space age as the 1970s saw it** - the colony of a space
programme and of Japanese Metabolism: capsules on cores, discs, slabs,
A-frames, trusses, ribbon windows; off-white panels, brushed aluminium,
thin burnt-orange stripes; a few small pink and cyan neon signs. No domes,
cupolas, spires, needles or finials: the first sheet, Art Deco with spires
and gold domes, read as a Stalinist high-rise, a church and a mosque - the
prompts forbid those shapes by name. The first sheet is described in words
alone, the old style reference not attached; the sheets after it are made
with the first attached.

**The camera** (`camera` in the layout), one for the city: the crater
floor's horizon at y 238, the domes' base line at 266, the focal length
1024 units. A thing whose feet stand at y is k = (y - 238) / 28 as near as
the domes' centres: its width in the layout is already its width there, and
it rides k times the city's speed - the parallax of the depth: the lower its
feet, the nearer and the faster. Depth is the feet alone, no key of its own.

**The frames** (`frames` in the layout): geodesic half-ellipsoids - an
icosahedron cut `frequency` times along each side, a vertex at the top, cut
at the equator, the equator itself the ring the frame stands on; `w` and `h`
its size at the base line, `rib` the thickness of a rib in units. Projected
by the camera, the far half is drawn behind the buildings and the near half
over them, so the city stands inside. Lit from behind, nothing of a frame
faces the eye in the light: a rib is a dark silhouette with a thin rim on
its side toward the sun, brighter the nearer the sun it runs, so the light
walks over the frame as it rides past. The ribs throw long shadows toward
the eye on the crater floor; the sun's own glare is laid over the ribs that
cross its disc. `tintsSun` as the elements had it.

| Frame | x | w x h | frequency | rib |
|---|---|---|---|---|
| `dome-main` | 468 | 512 x 170 | 4 | 2.2 |
| `dome-sat` | 1300 | 360 x 115 | 3 | 2.6 |

**Placed on the stand.** The first placement is a script's: rows at five
depths inside each dome's footprint, the tall pieces kept under the frame,
the landmarks at the centre, the deeper rows darker (shade 0.34 at the back
to 0.52 at the front). From there by hand: "Place buildings" pauses the
stand; a building is dragged along the street and into the depth (it grows
and shrinks with its nearness); M mirrors it, + and - size it, [ and ]
shade it, D copies it, Delete takes it away; a piece of the kit comes in at
the middle of the screen. "Download chase-backdrop.json" writes the layout
file with the city's elements replaced, one to a line, back to front, the
rest of the file as it was.

**The monorail** comes from a sheet of its parts (prompt 15): the beam, a
pylon, the train, an end station. The parts of a sheet came at scales of
their own, so each is set by the station: its stub's foot stands 19.8 units
above its feet and is 6.5 thick, the beam is scaled to that thickness and the
pylon to that height (the kit's `rail-*` sizes). The beam is no picture of
the whole line: the middle 70% of the generated beam, uniform along its
length, is one tile (`rail-beam`, 72.6 units), and the line is tiles laid
end to end, overlapping by 0.3. A tile hangs in the air, so its depth is
given by `groundY` - the feet of the pylons - and the editor moves it along
the street only. The train waits for the life of the city.

**What the game plays** (3.0.90): what the stand plays - the buildings in
depth by their feet, the frames in two halves around them, the shadows,
the glare, the sun tinted by the frames. The kit is a key the game does
not read. The stand's switches (frames, shadows, glare, parallax) are the
stand's alone: the game draws all of it.

**The shadows as they are.** A shadow is a rib dropped onto the floor
along the sun's light, and one end of it falling behind the eye drops the
shadow whole - on the stand, and so in the game. The sun stands 30 units
over the horizon at a focal length of 1024: a rib lifted more than about a
fifth of the main dome's height throws its shadow behind the eye. So the
main dome throws none, the satellite dome only those of its lowest ribs, at
its foot; the long shadows toward the eye do not show. The points on the
equator carry the noise of the arithmetic: the stand lets some of the
chords along it throw a shadow onto themselves, the game none.

## The order of work

1. The cliff - it joins screen 13 and sets the tone. **In the set.**
2. The main dome. **In the set** (the second take: the first was lit from
   the front; the second has the rim light of a sun behind).
3. The ridge, the floor, the sand. **In the set.** The ridge's own
   foothills were tried as the floor: they read as one land but carry 1.6 px
   a unit - soft even at 1080p - so the floor got its own generation.
4. The monorail, the satellite dome. **In the set** (the dome is 320 x 93
   units, its picture set by its width; of two takes the backlit one).
5. The hangar, the landing ring, the dish. **In the set** (96 x 15, 90 x 13
   and 50 x 52 units: the dish is set by its height, the other two by their
   width).
6. The stand judged whole and the backdrop handed to the code of the chase:
   done in 3.0.88 (arena-3.md, stage 11b-1); the speeds tuned live.
7. The city rebuilt (2026-11-01): the four sheets cut and placed; the domes,
   the satellite dome and the outskirts' hangar, ring and dish taken out of
   the layout and the set; the frames on the stand; the first take's
   monorail replaced by the sheet of its parts.

## The pipeline

Each generation, as it comes:

```
python tools/chase/check_element.py <id> <in>.png <work>/<id>.png
python tools/chase/make_seamless.py <in>.png <work>/<id>.png     (bands only)
python tools/chase/cut_sheet.py <sheet>.png <prefix> <work> <n>   (the city's sheets)
python tools/chase/pack_set.py <work>
python tools/chase/build_stand.py chase-stand.html
```

- `check_element.py` fails a missing alpha (a solid texture - the floor - is
  let through), a painted checkerboard and an object cut by the frame (the
  cliff may run out left, top and bottom; a band wherever it is a band). It
  drops the faint glow under alpha 10, makes the body above 248 solid,
  defringes a light halo, trims to the alpha and fits the object into the
  layout's box within 2048 px, printing its size in units - the layout's
  numbers follow the picture, not the other way round.
- `make_seamless.py` levels a skyline that runs downhill (and cuts the foot
  it lifted), evens the light along the band, and cross-fades its ends over
  a quarter of the width.
- `cut_sheet.py` cuts a sheet of buildings at its gaps, one PNG a building
  named `<prefix>-01...` left to right, cleans the coloured fringe off each
  edge and prints the sizes in units; it warns when the count is not the one
  ordered - joined buildings mean a new generation, not a retouch. The sizes
  go into the layout's `cityKit`.
- `pack_set.py` packs `<work>` into `bin/sprites/chase-backdrop.mset` in the
  layout's order, each picture once, every piece of the kit placed or not; an
  element not generated yet is left out. The tools read the layout from
  `bin/chase-backdrop.json`.
- `build_stand.py` writes one HTML page from `stand.template.html`, the
  layout, the set and screen 13's backdrop: the chase played over time,
  1080p or 4K, "real pixels" for a 1:1 look; a PNG named by its id dropped
  on the stage tries a take before it is packed; the frames, the depth and
  the placing of the buildings ("The city"). The working folder of checked
  PNGs is not kept: the set holds them.

## The prompts

Every generation has two attachments: the style reference (the cliff and
the dome, `arena3-style-ref.png`) and, for the cliff, screen 13's backdrop.
Each prompt is whole - copy it as it is, the shared block included.

### The shared block (the end of every prompt)

```
STYLE: Match the attached style reference exactly in rendering, materials and palette: layered dark basalt with a fine plated, flaky texture and warm bronze edge light; architecture in white and pale-gold chrome, soft retro-futurist synthwave forms; only a few small pink and cyan neon accents. Photoreal matte-painting look, crisp detail, no painterly blur, no film grain, no text, no logos, no people.

LIGHT: The reference's own lighting is NOT the target. One low sun, white and hard, stands directly BEHIND the object, slightly above the horizon (contre-jour). Thin bright rim light on the top edges and along the silhouette; the faces turned to the viewer in soft shadow with a little warm bounce light from the ground below. No light from the front or the sides, no second light source. Deep shadows. Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom, no lens flare, no glow in the air. Do not draw the sun.

BACKGROUND: Fully transparent PNG with a real alpha channel. No sky, no stars, no ground or terrain outside the object, no checkerboard pattern, no white or grey background, no cast shadow on the ground. The whole object fits inside the image with a clear empty margin on every side - nothing touches the edge of the image and nothing is cut off by it.
```

### 1. The cliff - `cliff.png`, portrait 1024x1536

Attach: the style reference and `screen13.png`.

```
The END of a giant lava tube's far wall on the Moon, seen from inside the tube: a towering cliff of HORIZONTAL basalt strata, the same strata, spacing, texture and colours as the second attached image (the tunnel wall it continues). Portrait image, 1024x1536.

The rock fills the left part of the image completely and runs out of the image on the LEFT, the TOP and the BOTTOM edges - it continues into the tunnel wall there. Its left third matches the darkness and the strata of the right third of the second attached image, so the two can be blended.

The right side is where the rock ends: a ragged, stepped silhouette of overhanging horizontal ledges, the edge wandering between 55% and 70% of the image width. Above the middle the ledges step out further near the top. Between 48% and 60% of the image height (counted from the top) the edge is one long SLOPING SHOULDER of rock instead of steps: a clean diagonal descending to the RIGHT at about 25-30 degrees, from about 50% to about 85% of the image width, its upper surface catching a thin bright rim of light along its whole length. Below the shoulder the edge goes down in short steps again. Right of the edge the image is fully transparent.

The top 15% of the rock fades into near-black shadow (the vault of the tunnel above, unlit). Light comes from the RIGHT and from behind: the right silhouette edge and the tops of the ledges catch warm bronze-white rim light; the body darkens toward the left, where it joins the dark tunnel.

Strictly horizontal structure: no vertical basalt columns, no vertical cracks, no stalactites, no arches. No lights, no windows, no gate, no glowing points anywhere in the rock.

STYLE: Match the attached style reference exactly in rendering and materials: layered dark basalt with a fine plated, flaky texture and warm bronze edge light. Photoreal matte-painting look, crisp detail, no painterly blur, no film grain, no text.

LIGHT: Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom, no lens flare. Do not draw the sun.

BACKGROUND: Real alpha channel: everything right of the rock edge is fully transparent. No sky, no stars, no checkerboard pattern, no white or grey background. Only the left, top and bottom edges of the image may be touched by the rock; the transparent right part must stay empty.
```

### 2. The main dome and its city - retired

Replaced on 2026-11-01 by the frame in code and the sheets ("The city";
prompts 11-14).

### 3. The far ridge - `ridge-tex.png`, landscape 1536x1024

```
The far rim of a vast lunar crater seen from many kilometres away: a long, low band of worn, rounded mountains, almost flat, the skyline gently ragged with no single peak or feature standing out - even along its whole width (it will be repeated side by side). The band occupies the lower 40% of the image and runs out of the image on the LEFT, RIGHT and BOTTOM edges; above the skyline the image is fully transparent.

Contre-jour: the mountains are a dark blue-grey silhouette with only a thin bright line of light along the skyline and faint lighter folds near it; no detail in the shadowed faces.

STYLE: Match the attached style reference in rendering and palette (the distant crater rim behind its dome). Photoreal matte-painting look, no painterly blur, no film grain, no text.

LIGHT: Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom. Do not draw the sun.

BACKGROUND: Real alpha channel: everything above the skyline is fully transparent. No sky, no stars, no checkerboard pattern, no white or grey background. No buildings, no objects.
```

### 4. The crater floor - `floor-tex.png`, landscape 1536x1024

```
The floor of a vast lunar crater seen at a grazing angle from far away, as a uniform texture: dark grey regolith with low mounds, ripples and scattered small rocks, foreshortened so the rows of mounds read as horizontal bands, smaller and tighter toward the top. Even along its whole width, nothing standing out - no crater, no boulder, no track (it will be repeated side by side). A faint warm sheen on the tops of the mounds toward the top of the image (the low sun is behind, beyond the top); the near faces in shadow.

The texture fills the WHOLE image, edge to edge, fully opaque - this one has no transparency.

STYLE: Match the attached style reference in rendering and palette (the ground of the crater around its dome). Photoreal, crisp, no painterly blur, no film grain, no text. Airless Moon: no haze, no fog, no bloom. No buildings, no objects, no sky.
```

### 5. The near sand - `sand-tex.png`, landscape 1536x1024

```
The near ground on the Moon, as a uniform texture band: low humps and dunes of dark basalt gravel and flaky plated rock, the same as the foreground ground of the attached style reference. The band occupies the lower 45% of the image and runs out of the image on the LEFT, RIGHT and BOTTOM edges; its top is a soft, low, rolling silhouette of humps, even along its whole width with no hump standing out (it will be repeated side by side). Above it the image is fully transparent.

Light from behind and above: warm bronze rims on the tops of the humps, the faces toward the viewer dark.

STYLE: Match the attached style reference in rendering and palette. Photoreal, crisp, no painterly blur, no film grain, no text.

LIGHT: Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom. Do not draw the sun.

BACKGROUND: Real alpha channel: everything above the humps is fully transparent. No sky, no stars, no checkerboard pattern, no white or grey background. No buildings, no objects.
```

### 6. The monorail - retired

The first take, gold and thick beside the new city, replaced on 2026-11-01
by the sheet of its parts (prompt 15).

### 7-10. The satellite dome, the outskirts - retired

Replaced on 2026-11-01 by the frame in code and the sheets of industry and
of the outskirts (prompts 13 and 14).

### 11. Sheet 1, the landmarks - `land`, 5 buildings, no attachment

The style lives in this prompt alone: no reference attached.

```
Five separate retro-futurist lunar colony megastructures standing in a row on one common invisible ground line - the future as imagined by 1970s space-program concept art and Japanese Metabolist architecture. Each a different shape: a tall central core tower with boxy capsule modules cantilevered off it at staggered heights; a pair of flat-topped slab towers joined by two enclosed sky bridges, with vertical radiator fins on their sides; a tall stack of horizontal disc-shaped floors on a slim core, like a pile of plates, with a lattice mast and a small red light on its flat roof; a huge A-frame arcology - a steep triangular megastructure with terraces of ribbon windows on its sloping faces; a leaning wedge tower with one sharply angled face and an open steel truss frame along its back. The tallest reaches about 90% of the image height; the others 60-85%. Seen exactly side-on from several kilometres away, the eye slightly above ground level, so bases read as nearly flat. Windows are long horizontal ribbon bands of dark glass, about 1/30 of the tallest structure's height per floor, the same scale on every building. Intact, clean, empty. Almost all windows dark; two of the buildings have a few warm lit window segments high up; one small pink neon sign on one building, one small cyan sign on another.

FORBIDDEN SHAPES: no domes, no cupolas, no onion domes, no spires, no needles, no finials, no pointed tops, no stepped Art Deco setbacks crowned with a spire, nothing that resembles a church, a mosque, a temple, a cathedral or a Stalinist high-rise. Roofs are flat, sloped, or carry masts and antennas.

LAYOUT: Each building is a separate object with a clear empty gap of at least half a building's width to its neighbours. Nothing touches another building or the edge of the image. No shared base, no plinth, no ground, no road, no terrain, no labels, no numbers, no captions.

STYLE: Clean modular engineering: smooth off-white and warm light-grey panels with fine panel seams, brushed aluminium frames and trusses, dark glass ribbon windows, a few thin burnt-orange accent stripes. No gold, no ornament, no rust, no grime, no cyberpunk clutter. Optimistic, monumental, precise. The only saturated colours are tiny accents of hot pink and electric cyan neon. Photoreal matte-painting look, crisp sharp detail where the panel seams and window bands stay readable, no painterly blur, no film grain, no text, no logos, no people.

LIGHT: Backlit. One low sun, white and hard, stands directly BEHIND the buildings, slightly above the horizon (contre-jour). The faces turned toward the viewer are in SHADOW - dark, cool, low-contrast, with only a little warm bounce light from the ground below. Only a thin bright warm rim of light along the top edges and the silhouettes. Nothing is lit from the front or from the sides. Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom, no lens flare, no glow in the air. Do not draw the sun.

BACKGROUND: Fully transparent PNG with a real alpha channel and clean edges - no coloured fringe, no halo, no outline around the objects. No sky, no stars, no ground outside the objects, no checkerboard pattern, no white or grey background, no cast shadows. Every object fits inside the image with a clear empty margin on every side.
```

### The block of the sheets after the first

Sheets 2-4 attach sheet 1 alone; after the first paragraph of each comes
this block, whole:

```
FORBIDDEN SHAPES: no domes, no cupolas, no onion domes, no spires, no needles, no finials, no pointed tops, nothing that resembles a church, a mosque, a temple, a cathedral or a Stalinist high-rise. Roofs are flat, sloped, sawtooth or barrel-vaulted.

LAYOUT: Each building is a separate object with a clear empty gap of at least half a building's width to its neighbours. Nothing touches another building or the edge of the image. No shared base, no plinth, no ground, no road, no terrain, no labels, no numbers, no captions.

STYLE: Match the attached sheet of buildings exactly: the same materials (off-white and warm light-grey panels with fine seams, brushed aluminium frames, dark glass ribbon windows, thin burnt-orange accent stripes), the same palette, the same window scale, the same rendering and the same light. These buildings belong to the same city, built by the same hands, but they are housing - simpler, more repetitive, more modest. Photoreal matte-painting look, crisp detail, no painterly blur, no film grain, no text, no logos, no people.

LIGHT: Backlit. One low sun, white and hard, stands directly BEHIND the buildings, slightly above the horizon (contre-jour). The faces turned toward the viewer are in SHADOW - dark, cool, low-contrast, with only a little warm bounce light from the ground below. Only a thin bright warm rim of light along the top edges and the silhouettes. Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom, no lens flare. Do not draw the sun.

BACKGROUND: Fully transparent PNG with a real alpha channel and clean edges - no coloured fringe, no halo, no outline around the objects. No sky, no stars, no ground outside the objects, no checkerboard pattern, no white or grey background, no cast shadows. Every object fits inside the image with a clear empty margin on every side.
```

### 12. Sheet 2, housing - `house`, 9 buildings (cut into 10: the twin towers part)

```
Nine separate residential buildings of a retro-futurist lunar colony standing in a row on one common invisible ground line - ordinary housing where thousands of people lived, plainer and lower than the attached landmark towers but clearly from the same city. Each a different simple type: a long slab apartment block with continuous ribbon balconies; a stack of boxy housing modules piled at offsets like children's blocks, each module with one window band; a terraced block stepped back on one side only, with long sloping rows of balconies; a cylindrical residential tower with plain horizontal window bands and a flat roof; an L-shaped low block around a small rooftop terrace; a pair of identical narrow towers side by side; a school-like low building with a sawtooth roof of skylights; a long barrel-vaulted greenhouse hall with ribbed glass panels; a monorail station - a long low box with an elevated track stub ending in mid-air on its right side. The tallest reaches about 60% of the image height, the lowest about 20%. Rooftops carry small practical things: water tanks, little antennas, small dishes, vents, solar panels. Seen exactly side-on from several kilometres away, the eye slightly above ground level. Windows at the same scale as the attached sheet. Intact, clean, empty. Most windows dark; a few scattered warm lit windows on two or three buildings; one small cyan neon sign on the station.
```

### 13. Sheet 3, the outskirts - `low`, 16 buildings

```
Sixteen separate small, low residential and service structures of a retro-futurist lunar colony standing in a row on one common invisible ground line - the quiet outskirts and back streets of the city in the attached sheet. Simple and repetitive: rows of identical two- and three-storey townhouse modules joined in lines of different lengths (some long and low, some short); single boxy housing pods on short legs; a low ring-shaped apartment court; small square blocks with one window band; a water tank on a lattice stand; a short communications mast with a dish; a small airlock entrance kiosk; a little garage shed with a wide door; low pipe-and-cable bridges. None taller than 25% of the image height; the long rows up to 15% of the image width. Rooftops with small vents, dishes and solar panels. Seen exactly side-on from very far away, the eye slightly above ground level; shapes kept simple and readable at small size. Intact, empty. All windows dark except two or three warm lit ones in total; no neon.
```

### 14. Sheet 4, industry - `ind`, 11 structures

```
Eleven separate abandoned industrial structures of the same retro-futurist lunar colony as the attached sheet, standing in a row on one common invisible ground line: two hyperboloid cooling towers of different heights, a large spherical tank on legs, a cluster of three cylindrical tanks, a tall lattice crane with its jib horizontal, a shorter crane with the jib raised, a pipe rack bridge on pylons, a lattice mast, a long low workshop with a sawtooth roof, a chimney stack, a small control building with an antenna. The tallest reaches about 85% of the image height. Seen exactly side-on from several kilometres away, the eye slightly above ground level. Industrial version of the same style: more bare brushed steel and grey concrete, fewer orange stripes, no ornament. Shut down and empty; everything dark except one small cyan sign on the control building and two dim red lamps on the crane tops.
```

### 15. Sheet 5, the monorail - `rail`, 4 parts, sheet 1 attached

```
Four separate parts of one elevated monorail line of a retro-futurist lunar colony, standing in a row on one common invisible ground line, like a kit of parts: (1) a long straight section of the track beam ALONE, with no supports under it - a perfectly level, uniform box beam of the same cross-section along its whole length, with a thin burnt-orange stripe along its side and a fine cyan guide-light strip under the stripe, both ends cut off square; it is the widest part, about 55% of the image width, floating at the height it would have on its supports; (2) one single support pylon - a slender tapered column with a small cross-head at its top where the beam sits, standing on a square footing, its height about one third of the image height; (3) a short monorail train of three streamlined cars in a row, rounded noses at both ends, a continuous band of dark windows along each car, one thin cyan light strip along its lower edge, shown alone without the beam; (4) a monorail end station - a low, long box on stilts with ribbon windows, the track entering it from one side. Seen exactly side-on from several kilometres away, the eye slightly above ground level. Intact, clean, empty. All windows dark.

FORBIDDEN SHAPES: no domes, no cupolas, no spires, no needles, no finials, no pointed tops, nothing that resembles a church, a mosque, a temple or a Stalinist high-rise.

LAYOUT: Each part is a separate object with a clear empty gap to its neighbours. Nothing touches another part or the edge of the image. No shared base, no ground, no road, no terrain, no labels, no numbers, no captions.

STYLE: Match the attached sheet of buildings exactly: the same materials (off-white and warm light-grey panels with fine seams, brushed aluminium, dark glass ribbon windows, thin burnt-orange accent stripes), the same palette, the same rendering and the same light. Built by the same hands as those buildings. Photoreal matte-painting look, crisp detail, no painterly blur, no film grain, no text, no logos, no people.

LIGHT: Backlit. One low sun, white and hard, stands directly BEHIND the parts, slightly above the horizon (contre-jour). The faces turned toward the viewer are in SHADOW - dark, cool, low-contrast, with only a little warm bounce light from the ground below. Only a thin bright warm rim of light along the top edges and the silhouettes. Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom, no lens flare. Do not draw the sun.

BACKGROUND: Fully transparent PNG with a real alpha channel and clean edges - no coloured fringe, no halo, no outline around the objects. No sky, no stars, no ground outside the objects, no checkerboard pattern, no white or grey background, no cast shadows. Every object fits inside the image with a clear empty margin on every side.
```

## Open

- The long shadows ("The shadows as they are"): cut at the eye rather than
  dropped whole, the shadow of a rib would stream toward the bottom of the
  screen, under the near hills - the long shadows toward the eye the frames
  were meant to throw. On the stand first, then in the game.
- The life of the city, a step after the frames: the neon of each piece
  found by its saturation and made to glow and flicker, lamps on the masts'
  tops, the train (`rail-train`) along the beam, into one station and out.
- Dome size in 4K: two generations a dome if one at 4 px a unit is soft.
- The haze of the pad jets over the far plane: off on screen 13 until the
  far plane is drawn into a texture the haze can bend.
