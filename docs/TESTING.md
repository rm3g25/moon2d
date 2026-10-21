# Testing

What the test suite is for, what it tries and what it leaves to the eye,
and the conveyor that writes it. The suite grows with the game: a version
that brings mechanics brings the tests of those mechanics.

## What the suite is for

The game is judged by a live run. A test holds what a live run cannot
see or will not see twice: a hole in the ring, an orb struck twice, a
drop that lands on a roof, a count that is off by one.

The suite is made by AI end to end: one model designs the tests, another
writes them. It is not deep. Its measure:

> Of the behavior that can be reached through public interfaces without
> changing game code, at least four fifths has a test. What cannot be
> reached is listed under "Left to the eye" and is tried in a live run.

Tests cover the newest mechanics first (the orbs) and do not go back
into older code until there is a reason to.

## Rules

- **Black box.** A test sees the `interface` section of a unit and
  nothing else. Game code is not changed for a test's sake: nothing
  moves into `interface`, no field is opened. What a test cannot see, it
  does not try. One exception is decided, not a habit: a read-only
  property that shows a state the game keeps anyway (`TMonster.Asleep`,
  `THull.Wake`). It writes nothing, and no field is opened.
- **Behavior, not formula.** A test says what must hold ("the hero is
  inside the ring"), not how the code counts it. A test that repeats the
  formula can only agree with the formula.
- **Numbers.** A test may spell a number of the design, one recorded as
  decided (60 orbs to a cast, a ring of 120 at most, 20 seconds of
  life). When the design changes that number, a red test is the right
  answer. A number still being tuned by eye (sizes, lights, most
  timings) is never spelled: the test bounds it loosely ("gone within a
  second") or compares orbs with each other.
- **Same run, same result.** The units under test roll their own dice
  with fixed seeds; a test uses no `Random` and no clock.
- **No window.** A test never calls `Draw` and never touches SDL. One
  exception is decided, not a habit: the scene director keeps hold of the
  sound bank, and the bank opens the mixer, so `Tests.Scenes.Director`
  opens it on SDL's dummy audio driver, once for its fixture, and plays
  nothing on it.
- **Every test names its breakage.** The tables below give, for each
  test, the edit that would turn it red. A test with no such edit is not
  written.
- **A red test is a question.** Which is wrong, the test or the code, is
  decided before either is edited. A test is never changed to agree with
  the code without that decision.

The code style of tests is CODESTYLE 16.

## Layout

```
Tests\
  Moon2D.Tests.dproj      console project, DUnitX; fourth in Moon2D.groupproj
  Moon2D.Tests.dpr        the runner: verbose log, exit code
  Tests.Matter.pas        the matter of a screen made by hand, for the orbs
  Tests.Rooms.pas         a room of solid cells to stand monsters in, and the
                          level of one for the load tests (LevelFromRows)
  Effects\
    Tests.Effects.Lightning.pas
    Tests.Effects.Traces.pas
  Game\
    Tests.Game.Blasts.pas
    Tests.Game.Press.pas
    Tests.Game.Shroud.pas
    Tests.Game.Trial.pas
    Tests.Game.Uptake.pas
  Levels\
    Tests.Levels.Carousels.pas
    Tests.Levels.Doors.pas     the doors a level shuts
    Tests.Levels.Dynamics.pas  the craft, the looks of a beam, the dust
    Tests.Levels.Entities.pas
    Tests.Levels.Events.pas    the events: heroStands
    Tests.Levels.Graph.pas
    Tests.Levels.Pads.pas
    Tests.Levels.Scenes.pas    the parser of the scenes, and the load
  Monsters\
    Tests.Monsters.pas
    Tests.Monsters.Bodies.pas
    Tests.Monsters.Damage.pas
    Tests.Monsters.Defs.pas
    Tests.Monsters.Hull.pas
    Tests.Monsters.Mount.pas
  Orbs\
    Tests.Orbs.Flock.pas  one test unit to one game unit
    Tests.Orbs.Harvest.pas
    Tests.Orbs.Patterns.pas
    Tests.Orbs.Rite.pas
    Tests.Orbs.Burst.pas
  Pads\
    Tests.Pads.Decks.pas
    Tests.Pads.Flights.pas
    Tests.Pads.Plunge.pas
    Tests.Pads.Shelf.pas
    Tests.Pads.Stray.pas
    Tests.Pads.World.pas    the dormant pad, for now
  Scenes\
    Tests.Scenes.Director.pas
  Sprites\
    Tests.Sprites.Sets.pas  the shipped sets, not the class: no sprite
                            past 2048 px
run-tests.cmd             build and run
```

- A test unit mirrors its game unit: `Game\Orbs\Orbs.Flock.pas` is tried
  by `Tests\Orbs\Tests.Orbs.Flock.pas`. One fixture to a class,
  `T<Class>Tests`; a unit of free functions gets `T<Unit>Tests`.
- A test is named `Test<Subject><Behavior>`.
- A fixture registers itself in its unit's `initialization`; the unit is
  listed in `Moon2D.Tests.dpr` and in `Moon2D.Tests.dproj`.
- Game units reach the project through its search path (`..\Core`,
  `..\Game`, `..\Game\Orbs`, `..\Game\Pads`, `..\Game\Scenes`,
  `..\Hud`); a new folder under test is added there.
- The executable goes to `bin\`, beside `SDL2.dll`: the SDL bindings are
  static imports.
- The project's Debug configuration checks ranges and overflow, as the
  game's does.

## Running

`run-tests.cmd` from the repository root. It builds the Debug
configuration and runs it. Exit code: 0 - all green, 1 - a test is red,
2 - the build failed. It finds RAD Studio through the registry; a RAD
Studio command prompt works too.

A suite already built in the IDE is run as `bin\Moon2D.Tests.exe`, from
a console: started from the IDE, its window closes with the last line.

## Writing tests: traps

- **Places are compared with a slack**, through a helper of the test
  unit (`ExpectAt`). DUnitX has no `Assert.AreEqual` for `Single`: with
  two of them the call is ambiguous.
- **An enum is compared as `Assert.AreEqual<TOrbState>(...)`:** the log
  then names both values.
- **A dropped orb is freed.** The flock owns its orbs; after the tick
  that drops one, a test must not read it. To know whether an orb is
  still there, ask `Flock.Orbs.Contains`.
- **An address comes back.** A new orb may get the address of one just
  freed, so orbs are not told apart by pointer across a tick in which
  some were dropped. A newcomer has `Age = 0` on the tick it appears:
  count births by that.
- **Mist and bands are the shroud's own arrays.** `THeroShroud.Mist` and
  `Bands` hand out the array the shroud works in, and a tick writes into
  it in place: a test that keeps `Before := Shroud.Mist` and compares it
  with the array after the tick compares the array with itself. What is
  to be compared across a tick is copied first (`Copy(Shroud.Mist, 0,
  Length(Shroud.Mist))`). A mote is a pointer into its swarm; it is read
  at once (`Swarm[i]^`) and never kept over a tick.
- **The orbs of a finished rite are gone, not dropped.** On the tick a
  rite tells `reFinished` its orbs are still in the flock, `osGone`, each
  where it went into the hero; the flock is empty a tick later. The same
  holds for whatever a test spends: it is in the list until the next tick.
- **A tick is counted from 0.** What a score puts on tick N has been told
  after N + 1 calls of `Tick`. A fixture that keeps the number of the next
  tick (`FTicks`) keeps the two apart.
- **A seat function is a plain function.** `TPatternSeatFunc` is a
  procedural type: the seat function of a test's own pattern is declared at
  unit level, not as a method and not nested.
- **Scenes and crumbs are the uptake's own arrays.** `TUptake.Scenes` and
  a scene's `Crumbs` hand out the arrays the uptake works in, as the
  shroud's mist does: the crumbs of the tick before are copied
  (`CrumbsOf`) before the tick. A scene read into a variable keeps its old
  `Age` and shows its crumbs as they are now; it is read anew after every
  tick.
- **A scene goes with its last crumb.** On the tick the last crumb of a
  scene goes out the scene is dropped, so that crumb's last state is never
  seen; the spot it lit is. A test that watches crumbs go out counts what
  it saw and asks that it saw some.
- **A JSON key is never given twice.** Of two keys alike in one object
  `GetValue` takes the first: a helper that writes a member and then lets
  a test add the same member "beside" it tries the first, and a test that
  should raise loads. A helper takes the members it writes as parameters
  and leaves one out when told (`SectionOf` of `Tests.Levels.Carousels`).
- **The runner fails a test that asserts nothing.**
- **A shot into the `nil` burst is an access violation.** A room ticks its
  bodies with a `nil` burst, so a body that fires stops the tick with
  `EAccessViolation`. A test of a gun held silent asks for no raise over
  the ticks it would fire in, and proves first, on a body left alone, that
  the room sees the shot (`Monsters.Bodies`).
- **A pad of no sprite asks for no art.** A room may carry pads with
  `"sprite": ""` and make its pad world with no renderer and no cache, as
  a deck of the collision grid has none: such a pad is a floor, a body and
  a thing to fly, and is never drawn. A pad that names a picture waits
  for the stage.
- **A dormant pad needs a scene that wakes it**, or the level does not
  load: a room with one carries a scene of a wake cue beside the test's.

## The conveyor

1. **Design.** The designing model reads the whole game unit and adds
   its table to this file: the test's name, what holds, the breakage.
   Behavior that cannot be seen from outside goes under "Left to the
   eye".
2. **Write.** The writing model gets this file, CODESTYLE 16, the
   `interface` sections of the unit under test and of the units its
   signatures name, and `Tests.Orbs.Flock.pas` as the sample. It works
   from the table. Where it has read the `implementation` all the same,
   the table is what a test answers to: a test that restates a formula
   instead of a behavior is sent back at review.
3. **Run.** `run-tests.cmd` on the developer's machine: there is no
   Delphi compiler where the models work. The log goes back as it is.
4. **Settle the red.** Compile errors are fixed in the test. A red test
   is settled by the rule above.
5. **Commit** when the run is green. The table's "state" line is
   brought up to date in the same commit.

## The tables

The table of every unit under test lives in `testing/`, one file per
namespace: `testing/orbs.md`, `testing/monsters.md`, `testing/game.md`,
`testing/effects.md`, `testing/pads.md`, `testing/sprites.md`,
`testing/scenes.md`. A new unit's table goes into the file of its
namespace; a new namespace gets a new file and a line here.
## The stage

State: proposed, not decided. It is the second of the ways out listed
under `Monsters.Pads`, and the hero needs it as the pads do:
`THero.Create` opens `hero.mset` and `weapon.mset` and makes a burst, and
all three ask a renderer for textures. Until it is decided the rule "No
window" stands as written and the units marked "needs the stage" wait.
`Pads.Plunge`, `Levels.Pads`, `Pads.Formations` and `Pads.Flights` need
none of it.

What it is - `Tests\Tests.Stage.pas`, one stage for the whole run, made
on first use:

- The working directory becomes the executable's: the game asks for its
  sets as `sprites\...`, from where it runs, and `run-tests.cmd` starts
  the suite from the repository root.
- A renderer that draws into memory: a surface of 512 by 384
  (`SDL_CreateRGBSurfaceWithFormat`) and `SDL_CreateSoftwareRenderer` over
  it. No window, no `SDL_Init`. The second call is bound in the test unit
  (`external 'SDL2.dll'`): the game does not import it.
- The art of the pads: a `TSpriteCache` on that renderer, the colour key
  off, `level1-structures.mset` attached - `s16-platform` is in it - and
  `pads.mset`, where the shelf (`shelf`, 32 by 11 units) lives. The smoke
  asks for the shelf's picture too.
- Game code does not change.

The rule would then read: "No window. A test never calls `Draw`. The
stage holds a renderer in memory so that the game's constructors get
their textures; nothing is drawn on it."

Not known before the first run: whether the software renderer and
`IMG_Load_RW` work with no `SDL_Init`. If they do not: `SDL_Init` of the
video with the hint `SDL_VIDEODRIVER` set to `dummy`, still no window.
The stage is tried first by its own smoke, `TestStageGivesAPadItsPicture`:
a pad room is built, and its pad stands where its JSON puts it.

The other two ways stay as they were listed: a door for `nil` art in
`TPadWorld.Create` and `TPad.Create` - game code changed for a test's
sake, and the hero still out of reach -, or the pads and the hero on them
left to the eye.

Shared setup on the stage, `Tests.Rooms` grown:

- `PadRoomFromRows(ARows, APads, AGroups = '')`: the room of
  `RoomFromRows` with the JSON of a `pads` section, and of `padGroups`, in
  its level; the pad world is made with the stage's art, `JumpReach` of
  `Hero.pas` and seed 1. `Room.Pads` and `Room.Level` are read. A pad of a
  test is `"sprite": "s16-platform"`, `"screen": 1`, `"width": 32` and
  carries a tag; the test finds it by `Pads.FindTagged`.
- `Room.Hero`: a `THero` on the stage's renderer, made on first use, on
  screen 1. `Room.PutHero(AX, AY)` is `SetScreenX` and `SetY`: his left
  edge and his feet. Put at a pad's `Left` and `Top`, he stands on it.
- `Room.Tick(ACommands)`: a tick of the game in the game's order (`Update`
  of `Moon2D.dpr`) - the commands to the hero, `Pads.Tick(1)`,
  `Hero.Tick`, then every monster of the room. A key held is its command
  on every tick, as the game polls it; a key let go is its `hcStop...`.
- Rooms: "open" is the floor alone, feet on it at y = 352. "Gap" is solid
  on rows 10 to 12 but for column 9, which is open to the bottom: two
  ledges, their tops at y = 288, and a shaft between them. The pad of a
  gap test stands in the gap, at x = 256, y = 288.

Numbers a pads test may spell, as decided: 33 ticks a second; a cell of
32 units; the hero's step of 2 units a tick and the 4 units a monster
shoves him by (both 2008); a knocked pad goes a cell; a plunging pad
gives for half a second and comes to rest three cells under the screen;
the line of the pit, y = 450.

## Outside the suite

- What an orb strikes and what that costs lives in `Moon2D.dpr`
  (`ResolveOrbHits`) and is tried in a live run. The orb's side of that
  contract is in the tables: when it is armed, and that a spent orb is
  gone on the next tick.
- Traces of the design stand are not used: the game has moved off the
  stand's numbers on purpose, and its dice are not the stand's.
- The ceremony, `Game.Henshin`: the countdown, the cure as a wave sits,
  the mercy from the pause on, the suit going on and coming off. It acts
  on the hero, the sound bank and the message board, and all three ask a
  renderer or a device: it waits for the stage, with the hero. The rite's
  side of that contract is in the table of `Orbs.Rite`: three waves told
  seated, the finish as far from the pause as the mercy is long, a shed
  that tells nothing.
