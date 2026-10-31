# The chase backdrop: out of the tunnel, past the city

The far plane of act 2 (arena-3.md, "Decided 2026-10-30, the chase"): the
end of the tunnel and the city in the crater, built from separate
elements. The numbers are in `bin/chase-backdrop.json` - game data the
level names in its `farPlane` section, and the very file the stand plays
(moved there from `tools/chase/layout.json` with 3.0.88): what is tuned
on the stand is what the game plays. The code: `Levels.FarPlane`,
`Game.FarPlane`, `Render.FarPlane` (arena-3.md, "Stage 11b-1 as built").
The numbers below are the ones after the live runs of 3.0.88 ("Decided
2026-10-31, the far plane" in arena-3.md).

## The strip, left to right

```
ground layer  near hills, a seamless band, y 276 down - in front of the tunnel, from the arena's first frame
tunnel layer  |== screen 13 wall ==|~cliff~>
city layer          (behind the cliff)  [ main dome + city ]==monorail==[ sat dome ]  hangar  ring  dish  (empty crater)
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
  part shows the moment the rock opens. The city's pictures are drawn
  mirrored (`"mirror": true`): the sun fell on them from the wrong side.
- **The monorail** (920-1360) is drawn behind both domes; its cut ends hide in
  their skylines.
- **The satellite dome**, industry (1300-1620).
- **The outskirts** - a hangar (1700), a landing ring (1880), a radio dish
  (2060) - then empty crater: the last screen is the brake zone.

The city layer is 2688 units long, 5.25 screens.

## Layers and speeds

Back to front. Units a second at cruise; the belt's ramp of 2 s starts all
of them, and its stop stands them.

| Layer | What | Speed |
|---|---|---|
| sky | black, the sun and its halo (code) | 0 |
| ridge | far crater rim, a seamless band, y 202-262 | 0.35 of the city |
| city | crater floor band (`floor-tex`, y 238-320, its top faded over 16 units, its foot under the hills), the domes, the rail, the outskirts | 0.5 of the tunnel while the cliff is in sight, then 3 |
| tunnel | screen 13 and its far ledge, the cliff | 6 |
| ground | the near hills (`sand-tex`, seamless, y 276 down), in front of the tunnel | 14 |
| fangs | behind the play layer | 20 |
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
| 445 s | the sun is free over the outskirts |
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
and behind, as in the reference. The generations of the city came lit from
one side all the same, and the wrong one: they are drawn mirrored. Lit
from one side they read as cardboard - the city gets a step of its own.

No haze, fog, god rays or bloom in any element: vacuum. The glow is the
code's sun.

**The shade.** The generations come out brighter than the night around
them, the domes most of all. An element's `shade` in the layout (0 to 1, 1
when absent) scales its colour as drawn - in the game
`SDL_SetTextureColorMod` with 255 times it, on the stand `brightness()` - so
the pictures stay as generated and the level is set on the stand by eye. It
dims the neon with the rest; the flickering sign is an additive spot of its
own over it.

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

## The pipeline

Each generation, as it comes:

```
python tools/chase/check_element.py <id> <in>.png <work>/<id>.png
python tools/chase/make_seamless.py <in>.png <work>/<id>.png     (bands only)
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
- `pack_set.py` packs `<work>` into `bin/sprites/chase-backdrop.mset` in the
  layout's order; an element not generated yet is left out. The three tools
  read the layout from `bin/chase-backdrop.json`.
- `build_stand.py` writes one HTML page from `stand.template.html`, the
  layout, the set and screen 13's backdrop: the chase played over time,
  1080p or 4K, "real pixels" for a 1:1 look; a PNG named by its id dropped
  on the stage tries a take before it is packed. The working folder of
  checked PNGs is not kept: the set holds them.

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

### 2. The main dome and its city - `dome-main.png`, landscape 1536x1024

```
An abandoned retro-futurist lunar city under a gigantic dome that is only its open frame: great curved ribs meeting at a crown ring, two or three horizontal rings around it, NO glass, nothing between the ribs. Seen from the side at a distance of several kilometres, the eye just above the base, so the round base reads as a very flat ellipse. The dome is about 2.4 times as wide as it is tall and fills about 92% of the image width, centred.

The city inside: slender white and chrome spires of different heights (the tallest about two thirds of the dome's height), domed halls, stepped ziggurats, ring roads around the foot; a monorail station at the right edge of the city with a short stub of elevated track ending inside the dome. Intact, clean, NOT ruined - simply empty: everyone died or left. Most windows dark; only four or five small neon signs still lit, pink and cyan, scattered, one of them half-broken.

The dome's legs stand on a low circular base wall with a thin railing, and the whole city stands on a thin flat concrete plinth that ends in a clean edge. The legs, the base wall and the plinth are all fully inside the image with a margin below them.

STYLE: Match the attached style reference exactly in rendering, materials and palette: layered dark basalt with a fine plated, flaky texture and warm bronze edge light; architecture in white and pale-gold chrome, soft retro-futurist synthwave forms; only a few small pink and cyan neon accents. Photoreal matte-painting look, crisp detail, no painterly blur, no film grain, no text, no logos, no people.

LIGHT: The reference's own lighting is NOT the target. One low sun, white and hard, stands directly BEHIND the object, slightly above the horizon (contre-jour). Thin bright rim light on the top edges and along the silhouette; the faces turned to the viewer in soft shadow with a little warm bounce light from the ground below. No light from the front or the sides, no second light source. Deep shadows. Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom, no lens flare, no glow in the air. Do not draw the sun.

BACKGROUND: Fully transparent PNG with a real alpha channel. No sky, no stars, no ground or terrain outside the object, no checkerboard pattern, no white or grey background, no cast shadow on the ground. The whole object fits inside the image with a clear empty margin on every side - nothing touches the edge of the image and nothing is cut off by it.
```

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

### 6. The monorail - `monorail.png`, landscape 1536x1024

```
A long elevated monorail line on the Moon seen exactly side-on from far away: one straight, perfectly level track beam on eight slender tapered pylons, evenly spaced, each standing on a small square footing. The beam runs across about 92% of the image width, centred, and both of its ends are cleanly squared-off cut ends. The pylons are about one tenth of the line's length tall. White and pale-gold chrome, a thin cyan guide-light strip along the side of the beam, dimly lit. No train, no station, no buildings.

STYLE: Match the attached style reference exactly in rendering, materials and palette: architecture in white and pale-gold chrome, soft retro-futurist synthwave forms; only a few small pink and cyan neon accents. Photoreal matte-painting look, crisp detail, no painterly blur, no film grain, no text, no logos, no people.

LIGHT: The reference's own lighting is NOT the target. One low sun, white and hard, stands directly BEHIND the object, slightly above the horizon (contre-jour). Thin bright rim light on the top edges and along the silhouette; the faces turned to the viewer in soft shadow with a little warm bounce light from the ground below. No light from the front or the sides, no second light source. Deep shadows. Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom, no lens flare, no glow in the air. Do not draw the sun.

BACKGROUND: Fully transparent PNG with a real alpha channel. No sky, no stars, no ground or terrain outside the object, no checkerboard pattern, no white or grey background, no cast shadow on the ground. The whole object fits inside the image with a clear empty margin on every side - nothing touches the edge of the image and nothing is cut off by it.
```

### 7. The satellite dome, industry - `dome-sat.png`, landscape 1536x1024

```
An abandoned lunar industrial zone under a smaller open dome frame - plainer and more utilitarian than a city dome: fewer, heavier ribs, one crown ring, NO glass. Seen from the side at a distance of several kilometres, the eye just above the base. The dome is about 2.3 times as wide as it is tall and fills about 92% of the image width, centred.

Inside: two hyperboloid cooling towers, spherical and cylindrical tanks, pipe racks, two tall lattice cranes, a few lattice masts; a monorail station at the LEFT edge with a short stub of elevated track ending inside the dome. Intact, not ruined - shut down and empty. Everything dark; only one small cyan sign still lit.

The dome's legs stand on a low circular base wall; the zone stands on a thin flat concrete plinth with a clean edge. Everything fully inside the image with a margin below it.

STYLE: Match the attached style reference exactly in rendering, materials and palette: architecture in white and pale-gold chrome, soft retro-futurist synthwave forms; only a few small pink and cyan neon accents. Photoreal matte-painting look, crisp detail, no painterly blur, no film grain, no text, no logos, no people.

LIGHT: The reference's own lighting is NOT the target. One low sun, white and hard, stands directly BEHIND the object, slightly above the horizon (contre-jour). Thin bright rim light on the top edges and along the silhouette; the faces turned to the viewer in soft shadow with a little warm bounce light from the ground below. No light from the front or the sides, no second light source. Deep shadows. Airless Moon: no atmosphere, no haze, no fog, no god rays, no bloom, no lens flare, no glow in the air. Do not draw the sun.

BACKGROUND: Fully transparent PNG with a real alpha channel. No sky, no stars, no ground or terrain outside the object, no checkerboard pattern, no white or grey background, no cast shadow on the ground. The whole object fits inside the image with a clear empty margin on every side - nothing touches the edge of the image and nothing is cut off by it.
```

### 8-10. The outskirts - square 1024x1024 each

The same shared block after each; only the first paragraph changes.

`hangar.png`:
```
A low half-cylinder hangar on the Moon, seen side-on from far away: ribbed white-chrome shell about three times as long as it is tall, a big closed sliding door on the long side, a dark service slot, two small cyan lamps by the door. Abandoned, intact. Standing on a thin flat concrete pad with a clean edge. The object fills about 80% of the image width, centred.
```

`landing-ring.png`:
```
A circular landing pad on the Moon seen from the side, from far away: a flat round deck on short sturdy legs, a ring of small lamps around its rim all unlit except one dim cyan one, a short boarding ramp on one side. Abandoned, intact, no ship. The deck reads as a flat ellipse; the object fills about 80% of the image width, centred.
```

`dish.png`:
```
A radio telescope dish on the Moon seen from the side, from far away: a large white parabolic dish tilted up toward the sky on a lattice tower with a turntable base, a small feed horn on struts at its focus. Abandoned, intact. The object fills about 70% of the image height, centred.
```

## Open

- The city: lit from one side it reads as cardboard, and it has no lights
  and no life - a step of its own, likely a unit of its own. The flickering
  neon sign and the contact shadow under the domes belong to it. The
  mirror swapped the sides of the monorail's stations; set right there.
- Dome size in 4K: two generations a dome if one at 4 px a unit is soft.
- The haze of the pad jets over the far plane: off on screen 13 until the
  far plane is drawn into a texture the haze can bend.
