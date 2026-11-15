# Moon 2D

**A 2D platformer written in Delphi in 2008. Ported line for line in 2026 -
and then reborn as 3.0.**

Screenshots and a new trailer come with 3.1. Until then, the only way to see
it is to play it: [the latest release](https://github.com/rm3g25/moon2d/releases/latest).

*One thing to look for: when the hero calls his aura, he does not conjure it.
He pulls it out of the floors, the walls and the ceilings around him.*

---

## Two lives of one game

**2.x - the port.** The game of 2008 was deleted and built again from an empty
folder: new renderer, new file formats, new asset pipeline, new soundtrack -
and the same game on the other side. One rule: *replace the entire machine,
change nothing the player can feel.* That line closed at 2.5.3 "Farewell 2008".
If you want the original, that release is the original.

**3.x - the continuation.** 2008 is the foundation, not dogma. Version 3.0
reworks everything - I'll leave what exactly for the game to show. From here
on there is a new rule, and it holds for every level still to come: **every
level must require new engine code.** A level that rearranges existing tiles
is content. A level that exists because a mechanic was written for it is
progress. The game should grow richer, not longer.

---

## The numbers

| | 2.5.3 | 3.0 |
| --- | --- | --- |
| Lines of Delphi | 11,000 | 133,800 |
| Of them, tests | 0 | 50,000 |
| Tests | 0 | 1,899 |

543 commits and 138 versions, from 3.0.0 to 3.0.137, in seven weeks - next
to a full-time job.

## How it is made

The code is written with an AI assistant, Claude Opus 5.5. The ideas, the
design, every decision and every review are mine. The assistant works from
the sources, not from memory: the 2008 code, the design notes in `docs/`,
and a style guide it has to follow over whatever it has seen elsewhere -
[DelphiStyle](https://github.com/rm3g25/DelphiStyle/blob/main/CODESTYLE.md). Every change is played live before it is
committed; the tests catch what the eye does not.

---

## The 2.x port: greatest hits from the excavation

The port turned up things the original author - me - had no memory of
writing. Full accounts in [`PORTING.md`](PORTING.md); the highlights:

- **The timer lied for eighteen years.** The loop asked Windows for 20 ms.
  `WM_Timer` delivered about 33. Every constant in the game - jump height,
  monster speed, fire rate - was tuned by hand against a number that appears
  nowhere in the source. The specification lived in an OS scheduler.

- **The font atlas has been stored sideways since 2008, and it was correct.**
  The old texture loader transposed on upload. The glyphs were *authored*
  through that same broken path - drawn, rotated until they looked right,
  saved. A bug compensated elsewhere is not a bug. It is a load-bearing wall.

- **Two ground probes, `y-3` and `y+3`, that must never be unified.** One for
  the hero, one for monsters, written years apart, each correct inside its own
  caller. Merge them and monsters sink into floors. They look like the same
  function. They are not the same function. Both were ported, both kept, both
  commented with a warning.

- **The animation counter runs backwards.** `9 - Round(CurrentSprite)`.
  Preserved. And `Round` in Delphi is banker's rounding, which quietly picks a
  different frame than a naive reading expects - documented, not fixed.

- **Every fourth frame was going somewhere.** SDL2 still defaults to the
  Direct3D **9** renderer on Windows. The hint that fixes it is ignored
  silently if you set it after creating the renderer.

- **...and naming the driver cost us the batching.** Set `SDL_RENDER_DRIVER`
  and SDL quietly stops batching draw calls - it assumes you now talk to the
  GPU yourself. Nobody noticed for three months, until a henshin threw a few
  thousand glows into one frame and an RTX 4070 dropped to seven frames a
  second. One more hint put it back.

The rule of the port, as a table - history now, but it is what 3.0 stands on:

| Torn out and rebuilt | Carried across untouched (in 2.x) |
| --- | --- |
| OpenGL -> SDL2, D3D11 backend | Every sprite, drawn by hand in 2008 |
| `WM_Timer` -> fixed 33 Hz timestep | Hero physics, constant for constant |
| Binary level blobs -> readable JSON | Collision oracles, including the asymmetric ones |
| Loose PNGs -> `.mset` sprite containers | Weapon patterns, all five of them |
| Hardcoded monsters -> `monsters.json` | The bullet-spawner particle hacks |
| Third-party music -> an original score | The bitmap font, glyph for glyph |
| One long file -> a unit per responsibility | The feel |

---

## The game

An elemental master lands on a lunar mining complex that stopped answering
three days ago. The transmitter is on the far side of it. Between him and the
transmitter is everything that came up out of the shafts.

Two levels, in English and Russian. More are coming.

**Controls**

| | |
| --- | --- |
| Move | Arrow keys |
| Jump | Up |
| Aim | Mouse |
| Fire | Left mouse button |
| Use the held bonus | Right mouse button |
| Pause / menu | Esc |

---

## Read the code

That is half the reason this repository is public. It is modern Object Pascal
written the way modern Object Pascal should look - guard clauses, records for
data that travels together, `implementation uses` by default, no `with`, no
aligned columns, no `u` prefixes. Every unit declares one responsibility.

Good places to start:

- **`Game/Hero.pas`** - physics, weapons, death. The densest concentration of
  cited-2008 arithmetic in the project.
- **`Game/Bullets.pas`** - the particle system, which in 2008 was five
  different abuses of the projectile list. All still hacks. All now named.
- **`Game/Orbs/Orbs.Harvest.pas`** - 3.x, not 2008: where the aura's orbs are
  pulled out of the matter around the hero.
- **`Game/Game.Moon.pas`** - the game-flow state machine (`TMoonGame`), the
  game the program runs; `Moon2D.dpr` is the start-up alone.
- **`docs/CODEBASE-MAP.md`** - the whole layout, unit by unit, if you would
  rather orient before diving.

---

## Playing

Take the release archive, unpack it, run `Moon2D.exe`. Nothing installs,
nothing registers, nothing phones anywhere. The one file written outside the
game folder is `%APPDATA%\Moon2D\settings.json` - what you chose in the game
(difficulty, language, fullscreen), laid over the shipped `config.json`.

Starts fullscreen; Alt+Enter switches to a window and back, and the choice is
remembered. If the screen stays black, press Alt+Enter. Failing that, set
`"fullscreen"` to `false` in `config.json` and delete `settings.json` if it
exists - it overrides `config.json`.

### System requirements

| | |
|---|---|
| OS | Windows 7 SP1 or later (Direct3D 11 needs the Platform Update on 7) |
| Disk | 150 MB |
| Graphics | not measured for 3.0 |

The 2.x numbers do not carry over: 3.0 draws far more glow, light and depth
than the game it grew from. Until 3.0 has been tried on modest hardware, a
discrete card from the last ten years is the honest answer.

Cloning and building works too, and the clone is complete - the soundtrack is
in the repository. If you delete `bin/music/` anyway, the game does not care:
the audio DLL is a delayed import, so a missing library or a missing track
degrades to silence rather than to a crash.

## Building

Developed on the current RAD Studio release, Win32 target. No third-party
components.

1. Open `Moon2D.dproj`
2. Build and run - output lands in `bin\`, next to the assets

The real floor is inline variable declarations, which arrived in **Delphi 10.3
Rio** - anything from there upward builds this, including the free Community
Edition. The `.dproj` is saved by a recent IDE and may want its version
attribute nudged before an older one will open it.

The tests are DUnitX: `run-tests.cmd` builds `Tests\Moon2D.Tests.dproj` and
runs it (exit code 0 - all green, 1 - a test is red, 2 - the build failed).
See [`docs/TESTING.md`](docs/TESTING.md).

`SDL2.dll`, `SDL2_image.dll` and `SDL2_mixer.dll` live in `bin\` and are in
the repository already.

## Layout

```
Moon2D.dpr, .dproj     the start-up and the project
Core/                  shared with the tools and the level editor: SDL,
                       sprite sets, rendering, level and monster models
Game/                  the game (Game.Moon), hero, monsters, bullets, sound,
                       the game loop; Orbs/, Pads/, Scenes/, Events/ inside
Hud/                   everything drawn over the playfield
Menu/                  the main menu and its sky
Tests/                 the DUnitX suite
bin/                   everything the game reads at runtime, and nothing else
  Moon2D.exe
  SDL2*.dll              renderer, image and mixer
  level1.json            geometry, objects, effects, entities, events
  level2.json
  monsters.json          movement, attacks, spawn tables, pickup effects
  chase-backdrop.json    a backdrop with depth
  finale.json            the cues of the end
  config.json            shipped defaults: window, tick rate, difficulty, language
  lang/                  en.json, ru.json
  sprites/               *.mset containers: manifest + packed frames, one file
                         per subject
  sounds/                WAV one-shots
  music/                 OGG tracks
tools/                 SpritePackCli (asset packer), TitleCard (trailer text),
                       and the scripts that build the art of each machine
docs/                  roadmap, changelog, mechanics, codebase map, lore
```

`bin/` is the entire shipping surface. The release packager copies that folder
rather than consulting a list, because a directory layout that encodes the rule
cannot drift out of sync with it.

---

## Where this goes

The order lives in [`docs/ROADMAP.md`](docs/ROADMAP.md). In short:

- The hero and the monsters redrawn from AI video
- A wider frame - 3.1
- A level editor with an assistant inside, sharing the game's own level and
  render units
- Level 3, the first one built in it - and the levels after it

## Documentation

- **[`docs/ROADMAP.md`](docs/ROADMAP.md)** - what comes next, and why in that
  order.
- **[`docs/CHANGELOG.md`](docs/CHANGELOG.md)** - what each version brought.
  Spoilers.
- **[`PORTING.md`](PORTING.md)** - what breaks when you move 2008 Delphi and
  OpenGL to modern Delphi and SDL2.
- **[`ASSETS.md`](ASSETS.md)** - where the art and audio came from, honestly.
- **[`docs/CODEBASE-MAP.md`](docs/CODEBASE-MAP.md)** - unit-by-unit
  structural map.
- **`docs/mechanics/`** - the design of each mechanic and the journal of the
  sessions that built it.
- **`docs/PORT-JOURNAL.md`** - the unedited working log of the 2.x port.
  Russian, part by part, written for nobody.

## Credits

Computer Dragon presents.

- Idea, code, art, story: Ilia Kuzmin (RedMask)
- Original idea: Alexander Friz (sw0000)

## Related

- **[dark-planet-win](https://github.com/rm3g25/dark-planet-win)** - a 1998 DOS
  game reverse-engineered and ported to Delphi VCL. Same universe, earlier
  archaeology, worse tooling.

## License

Source code: [MIT](LICENSE). Art and audio are **not** covered by it - see
[`ASSETS.md`](ASSETS.md).

---

Ilia Kuzmin | [github.com/rm3g25](https://github.com/rm3g25)
