# Asset licensing

**The MIT license in `LICENSE` covers the source code only.**

Art, audio and level data are not covered by it. Most of these assets were made
by the author — the sprites and textures in 2008, when the original game was
written, and the soundtrack in 2026. A few were not, and this document says
plainly which is which. Everything here is included so the game can be built
and played, not for reuse.

Runtime assets live under `bin/`, next to the executable.

## Made by the author

| Path | What |
|---|---|
| `bin/monsters/` | All enemy, boss, pickup and prop sprite sets |
| `bin/heroes/` | Hero walk and death frames, health icon |
| `bin/textures/` | Every tile and decoration |
| `bin/weapon/` | Weapon, bullet and crosshair sprites |
| `bin/Stars/`, `sky.png`, `fullmoon.png`, `logo.png` | Menu backdrop and logo |
| `bin/font.png`, `fontx.png`, `fonty.png` | Bitmap font atlases |
| `bin/level1.json`, `level2.json`, `monsters.json` | Level and monster design |

Free to reuse under the same terms as the code, with attribution.

**`bin/music/` — original soundtrack.** Eleven tracks composed by the author
using Suno for version 2.1.0, replacing the third-party music the 2008 build
shipped with. Not in the repository: at 17 MB it would outweigh the code, and a
soundtrack gets revised far more often than an engine does — every revision
would live in git history forever. It ships with the release archives instead,
and the game runs silently without it.

## Not made by the author

**`bin/heroes/ice1.png` – `ice8.png`** — the transformed ("henshin") hero
frames. Traced and heavily reworked from screenshots of a tokusatsu television
series by a fifteen-year-old in 2008. Eight frames at sprite resolution,
unrecognisable in motion, but the origin is what it is. Scheduled for
replacement with original artwork. Not licensed for reuse.

**`bin/sounds/`** — mixed. Some samples were recorded or synthesised by the
author; others were collected in 2008 from sources that were not written down.
Short, heavily processed, and treated here as of unknown provenance. Not
licensed for reuse.

**Screen backgrounds** (`bin/levels/level1/_scr*.png`,
`bin/levels/level2/screen*.png`) — composited from stock photography that was
free to use at the time. The specific sources were not recorded. Scheduled for
replacement.

## Third-party runtime libraries

`SDL2.dll`, `SDL2_mixer.dll` and `SDL2_image.dll` are redistributed under the
zlib license. See <https://www.libsdl.org/license.php>.

## If you hold rights to any of this

Open an issue or write to the author and the material will be removed promptly.
Nothing here is worth an argument.
