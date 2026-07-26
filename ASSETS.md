# Asset licensing

**The MIT license in `LICENSE` covers the source code only.**

Art, audio and level data are not covered by it. Most of these assets were made
by the author in 2008, when the original game was written; a few were not, and
this document says plainly which is which. They are included so the game can be
built and played, not for reuse.

## Made by the author

| Path | What |
|---|---|
| `monsters/` | All enemy, boss, pickup and prop sprite sets |
| `heroes/` | Hero walk and death frames, health icon |
| `textures/` | Every tile and decoration |
| `weapon/` | Weapon, bullet and crosshair sprites |
| `Stars/`, `sky.bmp`, `fullmoon.bmp`, `logo.bmp` | Menu backdrop and logo |
| `font.bmp`, `fontx.bmp`, `fonty.bmp` | Bitmap font atlases |
| `level1.json`, `level2.json`, `monsters.json` | Level and monster design |

Free to reuse under the same terms as the code, with attribution.

## Not made by the author

**`heroes/ice1.bmp` – `ice8.bmp`** — the transformed ("henshin") hero frames.
Traced and heavily reworked from screenshots of a tokusatsu television series
by a fifteen-year-old in 2008. Eight frames at sprite resolution, unrecognisable
in motion, but the origin is what it is. Scheduled for replacement with original
artwork. Not licensed for reuse.

**`music/` — not included in this repository.** Ten tracks of third-party
origin, retained from the 2008 build. They are distributed only in the release
archive, and are not licensed for redistribution. The game detects their absence
and runs silently, so a clone of this repository is playable without them. These
tracks are scheduled for replacement.

**`sounds/`** — mixed. Some samples were recorded or synthesised by the author;
others were collected in 2008 from sources that were not written down. Short,
heavily processed, and treated here as of unknown provenance. Not licensed for
reuse.

**Screen backgrounds** (`levels/level1/_scr*.bmp`, `levels/level2/screen*.bmp`)
— composited from stock photography that was free to use at the time. The
specific sources were not recorded. Scheduled for replacement.

## Third-party runtime libraries

`SDL2.dll` and `SDL2_mixer.dll` are redistributed under the zlib license.
See <https://www.libsdl.org/license.php>.

## If you hold rights to any of this

Open an issue or write to the author and the material will be removed promptly.
Nothing here is worth an argument.
