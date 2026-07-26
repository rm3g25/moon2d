# Moon 2D

A 2D platformer about a lone soldier fighting his way through a lunar mining
complex, with a transformation sequence borrowed wholesale from Japanese
tokusatsu television.

Written in 2008 in Delphi 2005 with OpenGL. This is version 2: the same game,
rebuilt from scratch on Delphi 12 and SDL2.

<!-- ![Moon 2D](docs/screenshot.png) -->

## What this is

The original was a teenager's project — one file, immediate-mode OpenGL, level
data in a hand-rolled binary format, and a 20 ms `WM_Timer` doing duty as a game
loop. Every mechanic worked, and most of them worked for reasons that were not
written down anywhere.

Version 2 is a full rewrite that reproduces the original's behaviour exactly,
down to its arithmetic. Where the 2008 code contained a formula, that formula
was carried over verbatim and cited rather than tidied up: rounding quirks,
asymmetric collision probes, an animation loop that counts backwards. Deliberate
departures from the original are listed in `PORTING.md`, and there are only
seven of them.

What changed underneath:

- SDL2 rendering with a fixed-timestep loop, replacing OpenGL and `WM_Timer`
- Level and monster data moved from binary blobs to readable JSON
- Monster behaviour is data-driven — movement, attack patterns, spawn tables
  and pickup effects all live in `monsters.json`
- English and Russian localisation, switchable in the menu
- Fourteen units with declared responsibilities, replacing one long file

## Playing

Download the release archive, unpack it, run `Moon2D.exe`. Nothing to install.

Cloning the repository and building also works, but the music is not in the
repository — see `ASSETS.md`. The game notices and runs silently.

### Controls

| | |
|---|---|
| Move | Arrow keys |
| Jump | Up arrow |
| Aim | Mouse |
| Fire | Left mouse button |
| Pause / menu | Esc |

## Building

Requires **Delphi 12** or newer, targeting Win32. No third-party components.

1. Open `Moon2D.dproj`
2. Build and run

`SDL2.dll` and `SDL2_mixer.dll` sit next to the executable and are already in
the repository. Both are loaded through delayed imports, so a missing DLL
degrades the game rather than killing it.

## Layout

```
*.pas, *.dpr        engine
level1.json         level geometry, backgrounds, entities, triggers
level2.json
monsters.json       monster definitions - movement, attacks, spawn tables
config.json         window, tick rate, difficulty, language
lang/               en.json, ru.json
heroes/  monsters/  sprite sets, each with an ordered frame list
weapon/  textures/
levels/             per-screen background art
sounds/  music/     music is release-only, see ASSETS.md
```

## Where this is going

Version 2.0 finishes the original game: every screen of the 2008 content is
playable start to finish, in English, in a repository that is not embarrassing.
That was the whole goal of the first phase.

The second phase adds eight new levels, under one rule: **every level must
require new engine code.** A level that rearranges existing tiles and monsters
is content. A level that exists because a new mechanic was written for it is
progress. The first of them is an ore transport train running through the
tunnels below the complex.

## Documentation

- **`PORTING.md`** — what breaks when you port 2008 Delphi and OpenGL to
  Delphi 12 and SDL2. Coordinate systems, collision probes that are not
  symmetric, a font atlas stored rotated ninety degrees, and a rendering
  backend that quietly costs you every fourth frame.
- **`ASSETS.md`** — where the art and audio came from, honestly.
- **`docs/PORTING-NOTES.ru.md`** — the unedited working log kept during the
  port. Russian, session by session, not written for anyone else.

## License

Source code: [MIT](LICENSE).

Art and audio are **not** covered by it. See [`ASSETS.md`](ASSETS.md).

---

Ilia Kuzmin · [github.com/rm3g25](https://github.com/rm3g25)
