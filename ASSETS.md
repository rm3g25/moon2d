# Asset licensing

**The MIT license in `LICENSE` covers the source code only.**

Art, audio and level data are not covered by it. Most of these assets were made
by the author — the sprites and textures in 2008, when the original game was
written, and the soundtrack in 2026. A few were not, and this document says
plainly which is which. Everything here is included so the game can be built
and played, not for reuse.

Runtime assets live under `bin/`, next to the executable. Since 2.3.0 every
image is inside a `.mset` sprite container in `bin/sprites/` — one file per
subject, manifest plus packed frames. There are no loose images left, so an
asset is named below by its set, and by its sprite name inside the set where
that matters. The format is described in [`docs/MSET-FORMAT.md`](docs/MSET-FORMAT.md);
`SpritePackCli unpack` takes any set apart if you want to look.

## Made by the author

| Set | What |
|---|---|
| `sprites/hero.mset` | Hero walk and death frames |
| `sprites/gravel`, `gravel2`, `vinter`, `shoot1`, `betoner`, `barrel`, `medic`, `krep`, `platform`, `tank`, `boss1` | Every enemy, boss, pickup and prop |
| `sprites/weapon.mset`, `weapon1`–`weapon4` | Weapon, bullet, crosshair and pickup sprites |
| `sprites/brickwork`, `cargo`, `common`, `conveyor`, `facility`, `machinery`, `mine-interior`, `mine-structure`, `mine-walls`, `mining-rig`, `moon-surface`, `railway` | Every tile and decoration, grouped by theme rather than by level |
| `sprites/ui.mset` | Menu nebula (`sky`), the lunar surface map (`moonmap`), the logo letters, the language flags, the `font`/`fontx`/`fonty` bitmap atlases (`fonty` redrawn at 1024x1024 in 3.0.4, the 2008 one kept byte for byte as `fonty-2008`); stars, halo and embers are generated in code |
| `bin/level1.json`, `level2.json`, `monsters.json` | Level and monster design |

Free to reuse under the same terms as the code, with attribution.

**`bin/music/` - original soundtrack.** Ten tracks composed by the author
using Suno for version 2.1.0, replacing the third-party music the 2008 build
shipped with. In the repository since the tracks settled: 17 MB is a real cost
in a repository this size, but a clone that plays with sound beats a clone that
needs a second download, and finished tracks do not churn the way drafts did.

## Not made by the author

**`sprites/hero.mset`, sprites `ice1`–`ice8`** (the `henshin` sequence) — the
transformed hero frames. Traced and heavily reworked from screenshots of a
tokusatsu television series by a fifteen-year-old in 2008. Eight frames at
sprite resolution, unrecognisable in motion, but the origin is what it is.
Scheduled for replacement with original artwork. Not licensed for reuse.

**`sprites/sky.mset`, sprites `earth` and `earth-night`** - the globe maps of
the Earth in the level sky: NASA Blue Marble Next Generation and NASA Black
Marble 2016, both public domain; clouded (the day map) and reduced to city
lights (the night map) by the author.

**`bin/sounds/`** — mixed. Some samples were recorded or synthesised by the
author; others were collected in 2008 from sources that were not written down.
Short, heavily processed, and treated here as of unknown provenance. Not
licensed for reuse.

## Generated

**Screen backgrounds** (`sprites/level1-backdrops.mset`,
`sprites/level2-backdrops.mset`) - since 3.0.11, generated with ChatGPT's
image model from the author's prompts, then cropped, hazed and packed by the
author; the brightness is set per level in code. They replaced the 2008
backgrounds, which were composited from stock photography of unrecorded
origin. `_black` is a plain fill.

**Level objects** (`sprites/level1-objects.mset` - the ship;
`sprites/sky.mset`, sprite `satellite`) - since 3.0.12, generated with
ChatGPT's image model from the author's prompts, then cut out, scaled and
packed by the author.

**The level-1 boss disc** (`sprites/boss1-disc.mset`) - since 3.0.19,
generated with ChatGPT's image model to the author's direction (a clean and a
battle-worn disc of the same geometry), then straightened, cut into layers
(ring, hub, iris), given a drawn gloss layer and packed. It replaced the eight
spin frames of `boss1.mset`, which stay in the set unused; the death frames
there are still the 2008 ones.

**The barrel** (`sprites/barrel.mset`, sprite `barrel`) - since 3.0.23,
generated with ChatGPT's image model from the author's prompt, then cut out,
scaled to 128x128 and packed. It replaced the four 2008 frames
`boch1`-`boch4`, which stay in the set as the `alive-2008` sequence, unused;
the death frames there are still the 2008 ones.

**The fans** (`sprites/ventilation.mset`) - since 3.0.24, generated with
ChatGPT's image model from the author's prompts (a heavy rotor and a round
guard over it; since 3.0.25 a turbine rotor, a wall plate and a louver
panel), then centered on the axis, blurred into the states a turning
rotor passes through, given a torn variant, cast shadows and a painted
shaft behind, scaled and packed by `tools/fans/build_fans.py`. On level 2
they replaced the 2008 tiles `cooler1`-`cooler4` and `ventelat`, which
stay in `machinery.mset` unplaced.

**`bin/sounds/armor1.wav`-`armor3.wav`, `ricochet.wav`** - since 3.0.20,
synthesised by `tools/sounds/armor.py`: a struck steel plate and the whine
of a ricochet, from noise and sine partials alone.

**`bin/sounds/crash.wav`** - since 3.0.21, synthesised by
`tools/sounds/crash.py`: a heavy disc stopped by a wall, from sine tones
and noise alone.

**`bin/sounds/padhum.wav`, `padclick.wav`, `padclack.wav`** - since 3.0.29,
synthesised by `tools/sounds/pads.py`: the hum that warns of an arena
rebuild, the click of a pad turning the corner of its flight and the clack
of two pads docking, from sine tones and noise alone.

## Third-party runtime libraries

`SDL2.dll`, `SDL2_mixer.dll` and `SDL2_image.dll` are redistributed under the
zlib license. See <https://www.libsdl.org/license.php>.

## If you hold rights to any of this

Open an issue or write to the author and the material will be removed promptly.
Nothing here is worth an argument.
