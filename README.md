# Moon 2D

A 2D platformer about a lone soldier fighting his way through a lunar mining
complex, with a transformation sequence borrowed wholesale from Japanese
tokusatsu television.

Written in 2008 in Delphi 2005 with OpenGL. This is version 2: the same game,
rebuilt from scratch on Delphi 13 and SDL2.

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
- An original soundtrack, replacing the third-party music the 2008 build
  shipped with
- Fourteen units with declared responsibilities, replacing one long file

## Playing

Download the release archive, unpack it, run `Moon2D.exe`. Nothing to install.
The game starts fullscreen; if the screen stays black, set `"fullscreen"` to
`false` in `config.json`.

Cloning the repository and building also works, but the soundtrack is not in
the repository — at 17 MB it would outweigh the code, and it changes far more
often. Take `moon2d-music-*.zip` from the latest release and unpack it over
your clone, or don't: the game notices its absence and runs silently.

### Controls

| | |
|---|---|
| Move | Arrow keys |
| Jump | Up arrow |
| Aim | Mouse |
| Fire | Left mouse button |
| Pause / menu | Esc |

## Building

Developed on **Delphi 13 Florence**, targeting Win32. No third-party
components.

1. Open `Moon2D.dproj`
2. Build and run — output goes to `bin\`, next to the assets

The binding language constraint is inline variable declarations, which require
Delphi 10.3 Rio or later. Nothing newer is used deliberately, but earlier
releases in that range are untested. The newest free Community Edition at the
time of writing is Delphi 12.1 Athens, which is well within range.

Art ships as `.mset` sprite sets in `bin\sprites\` — one file per monster,
one for the hero, a dozen grouped by subject for the tiles. `docs/MSET-FORMAT.md`
describes the container; `tools/SpritePack` builds and unpacks it.

`SDL2.dll`, `SDL2_mixer.dll` and `SDL2_image.dll` live in `bin\` and are
already in the repository. All three are loaded through delayed imports. A
missing mixer only costs you the sound; a missing image library is fatal and
says so, since every sprite in the game is a PNG.

## Layout

```
*.pas, *.dpr           engine sources
bin/                   everything the game needs at runtime
  Moon2D.exe             built here
  level1.json            level geometry, backgrounds, entities, triggers
  level2.json
  monsters.json          movement, attacks, spawn tables, pickup effects
  config.json            window, tick rate, difficulty, language
  lang/                  en.json, ru.json
  heroes/  monsters/     sprite sets, each with an ordered frame list
  weapon/  textures/
  levels/                per-screen background art
  sounds/
  music/                 release-only, see ASSETS.md
tools/TitleCard/       renders text through the game's own font engine
docs/                  working notes
```

`bin/` is the whole shipping surface: everything the game reads at runtime is
in there, and nothing else is. The release packager copies that folder rather
than consulting a list, because a directory layout that encodes the rule cannot
drift out of sync with it.

## Where this is going

Version 2.0 finished the original game: every screen of the 2008 content
playable start to finish, in English and Russian, in a repository that is not
embarrassing. That was the whole goal of the first phase.

The second phase adds eight new levels, under one rule: **every level must
require new engine code.** A level that rearranges existing tiles and monsters
is content. A level that exists because a new mechanic was written for it is
progress. The first of them is an ore transport train running through the
tunnels below the complex.

## Documentation

- **`PORTING.md`** — what breaks when you port 2008 Delphi and OpenGL to
  Delphi 13 and SDL2. Coordinate systems, collision probes that are not
  symmetric, a font atlas stored rotated ninety degrees, and a rendering
  backend that quietly costs you every fourth frame.
- **`ASSETS.md`** — where the art and audio came from, honestly.
- **`docs/PORTING-NOTES.md`** — the unedited working log kept during the port.
  Russian, session by session, not written for anyone else.

## License

Source code: [MIT](LICENSE).

Art and audio are **not** covered by it. See [`ASSETS.md`](ASSETS.md).

---

Ilia Kuzmin · [github.com/rm3g25](https://github.com/rm3g25)
