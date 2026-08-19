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
| `sprites/hero.mset` | Hero walk and death frames, health icon |
| `sprites/gravel`, `gravel2`, `vinter`, `shoot1`, `betoner`, `barrel`, `medic`, `krep`, `platform`, `tank`, `boss1` | Every enemy, boss, pickup and prop |
| `sprites/weapon.mset`, `weapon1`–`weapon4` | Weapon, bullet, crosshair and pickup sprites |
| `sprites/brickwork`, `cargo`, `common`, `conveyor`, `facility`, `machinery`, `mine-interior`, `mine-structure`, `mine-walls`, `mining-rig`, `moon-surface`, `railway` | Every tile and decoration, grouped by theme rather than by level |
| `sprites/ui.mset` | Menu sky, moon, logo, star sprites, language flags, the `font`/`fontx`/`fonty` bitmap atlases |
| `bin/level1.json`, `level2.json`, `monsters.json` | Level and monster design |

Free to reuse under the same terms as the code, with attribution.

**`bin/music/` — original soundtrack.** Eleven tracks composed by the author
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

**`bin/sounds/`** — mixed. Some samples were recorded or synthesised by the
author; others were collected in 2008 from sources that were not written down.
Short, heavily processed, and treated here as of unknown provenance. Not
licensed for reuse.

**Screen backgrounds** (`sprites/level1-backdrops.mset`,
`sprites/level2-backdrops.mset`) — composited from stock photography that was
free to use at the time. The specific sources were not recorded. Scheduled for
replacement.

## Third-party runtime libraries

`SDL2.dll`, `SDL2_mixer.dll` and `SDL2_image.dll` are redistributed under the
zlib license. See <https://www.libsdl.org/license.php>.

## If you hold rights to any of this

Open an issue or write to the author and the material will be removed promptly.
Nothing here is worth an argument.
