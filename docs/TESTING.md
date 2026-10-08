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
  does not try.
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
- **No window.** A test never calls `Draw` and never touches SDL.
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
  Tests.Rooms.pas         a room of solid cells to stand monsters in
  Effects\
    Tests.Effects.Lightning.pas
  Game\
    Tests.Game.Blasts.pas
  Monsters\
    Tests.Monsters.pas
    Tests.Monsters.Bodies.pas
    Tests.Monsters.Damage.pas
  Orbs\
    Tests.Orbs.Flock.pas  one test unit to one game unit
run-tests.cmd             build and run
```

- A test unit mirrors its game unit: `Game\Orbs\Orbs.Flock.pas` is tried
  by `Tests\Orbs\Tests.Orbs.Flock.pas`. One fixture to a class,
  `T<Class>Tests`; a unit of free functions gets `T<Unit>Tests`.
- A test is named `Test<Subject><Behavior>`.
- A fixture registers itself in its unit's `initialization`; the unit is
  listed in `Moon2D.Tests.dpr` and in `Moon2D.Tests.dproj`.
- Game units reach the project through its search path (`..\Core`,
  `..\Game`, `..\Game\Orbs`, `..\Game\Pads`); a new folder under test
  is added there.
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
- **The runner fails a test that asserts nothing.**

## The conveyor

1. **Design.** The designing model reads the whole game unit and adds
   its table to this file: the test's name, what holds, the breakage.
   Behavior that cannot be seen from outside goes under "Left to the
   eye".
2. **Write.** The writing model gets this file, CODESTYLE 16, the
   `interface` sections of the unit under test and of the units its
   signatures name, and `Tests.Orbs.Flock.pas` as the sample. It does
   not get the `implementation` section.
3. **Run.** `run-tests.cmd` on the developer's machine: there is no
   Delphi compiler where the models work. The log goes back as it is.
4. **Settle the red.** Compile errors are fixed in the test. A red test
   is settled by the rule above.
5. **Commit** when the run is green. The table's "state" line is
   brought up to date in the same commit.

## Orbs.Flock

State: written, 15 tests.

| Test | Holds | Turns red when |
|---|---|---|
| `TestNewOrbIsAliveArmedAndFull` | a new orb is where it was made, alive, armed, at full size and light, of age 0 | a default of `TOrb.Create` changes |
| `TestAddKeepsOwnersOrder` | `Add` appends | `Add` stops appending: an aura seats its orbs by their order |
| `TestInsertPutsOrbBeforeIndex` | `Insert` puts the orb before the one at the index | the index shifts by one |
| `TestTickAgesEveryOrb` | each tick adds one to the age of every orb, each from its own birth | an age is skipped or shared |
| `TestMovedOrbStaysPutThroughTicks` | an orb moved once stands there | a tick carries an orb on by what it is drawn ahead by |
| `TestMoveBesidePutsOrbWhereMoveToWould` | the body's step changes nothing in the orb's place | the body's step is taken off the place |
| `TestImplodingOrbLingersThenIsDropped` | an imploding orb is in the flock for more than a tick and for less than a second | an implosion ends at once or never |
| `TestSecondImplodeDoesNotStartOver` | of two orbs imploded together, the one imploded again goes on the same tick | `Implode` loses its guard and starts the count anew |
| `TestSpentOrbIsGoneAtOnceAndDroppedAtTick` | `Spend`: gone at once, in the list until the tick | `Spend` deletes from the list the game is walking |
| `TestReleasedOrbIsGoneAtOnceAndDroppedAtTick` | the same of `Release` | the same |
| `TestSpendTakesImplodingOrbAtOnce` | a strike ends an implosion | `Spend` passes over an orb that is not alive |
| `TestGoneOrbDoesNotImplode` | `Implode` leaves a gone orb gone | a struck orb comes back to implode |
| `TestTickDropsOnlyTheGone` | the others stay, in their order | the tick drops a neighbour or reorders |
| `TestShiftCarriesEveryOrbByTheStep` | a door moves every orb by its step | an axis is lost or swapped |
| `TestClearEmptiesTheFlock` | nothing is left | `Clear` forgets the orbs |

Left to the eye: the breath, the look of an implosion, the dust of a
strike, the mark on a face (`MarkFace`) - the flock keeps them to itself
and only draws them.

## Orbs.Harvest

State: designed, not written.

Shared setup, `Tests\Tests.Matter.pas`: `MatterFromRows` builds a
`TMatter` from twelve strings of sixteen characters, `#` a solid cell,
`.` an open one, and `SolidAt(AMatter, AX, AY)` answers for a point in
units. The dice of a test are a `TXorShift` with a seed of its own, any
but zero: a xorshift seeded with zero rolls zeros for ever.

| Test | Holds | Turns red when |
|---|---|---|
| `TestGivesExactlyTheCountAsked` | over a floor, 60 asked - 60 given; 0 asked - none | the count is cut to what the matter has |
| `TestEverySpotOnFaceLooksIntoTheOpen` | matter: a floor two cells thick over the whole width, a wall on it, a lone cell in the air. Of every spot with a normal: two units along the normal is on the screen and open, two units against it is solid | a seam between two cells, a face on the screen's edge or the wrong side of a face gives a spot |
| `TestFaceUnderBodyGivesNoSpot` | a pad body lying on a floor, its edges on multiples of 8 units: no spot lies on the floor's top within the body's span | bodies are not counted as matter |
| `TestBodyGivesSpots` | no cells, one body: every spot with a normal lies on the body's outline | bodies are not harvested |
| `TestEmptyMatterGivesSpotsInThinAir` | no matter: every spot has no normal and stands 50 to 90 units from the center | the air ring moves or a normal is made up |
| `TestShortMatterIsToppedUpWithAir` | one cell, 30 asked: spots with a normal come first, spots without one after them, both are there | air is mixed in before the matter runs out |
| `TestNearerMatterComesFirst` | a cell beside the center and a cell across the screen, 10 asked: all ten are on the near cell | the sort is lost or reversed |
| `TestAwayAndTurnPointFromCenter` | of every spot: the center plus `Away` along `Turn` is the spot | the arguments of the arctangent are swapped |
| `TestSameDiceGiveSameSpots` | two calls with dice of one seed give the same spots | the function reaches for `Random` |

Left to the eye: how evenly the spots scatter along a face.

## Orbs.Rain

State: designed, not written.

Every test pours over a matter and ticks the rain, looking at
`Flock.Orbs` after each tick. Births are counted by `Age = 0`. "The
whole rain" is 200 ticks.

| Test | Holds | Turns red when |
|---|---|---|
| `TestOnePourBringsFourHundredEightyDrops` | none before the first tick; 480 births over the whole rain | a wave or a column is lost |
| `TestSecondPourAddsToTheFirst` | a pour, five ticks, a pour: 960 births | a pour replaces the one before |
| `TestRainCoversTheWholeWidth` | every one of the sixteen columns of cells sees a drop; no drop is off the screen's sides | the veil is narrower than the screen |
| `TestDropsFallEvenly` | no matter. A newborn is above the screen. From one tick to the next every drop of age 1 or more has fallen by one and the same step, downward, the same on every tick (such a drop was in the flock a tick ago: its address is safe to look up) | drops fall at paces of their own, or a drop is born on the screen |
| `TestRoofDoesNotStopDrop` | a platform over the whole width with open cells under it down to the bottom: every drop seen is armed, and drops are seen below the screen's bottom edge | a drop lands on matter that does not reach the bottom |
| `TestFloorDisarmsDropAndTakesItBack` | a floor two cells thick: no armed drop at or below the floor's top; unarmed drops are seen; no drop is seen below the screen's bottom edge; the flock is empty when the rain is over | a drop strikes from inside the floor, or is never let go |
| `TestFloorIsTheMatterThatReachesTheBottom` | a platform, an open row, a floor: armed drops are seen between the platform and the floor, none at or below the floor's top | the floor is taken for the first matter met |
| `TestPitLetsDropsOutOfTheScreen` | a floor with a pit two cells wide: drops are seen below the screen's bottom edge, armed, every one of them within the pit's span | a pit gets a floor, or a floor lets a drop through |
| `TestCollapseImplodesTheBornAndCancelsTheUnborn` | a pour, ten ticks, `Collapse`: every orb is imploding; no birth after it; the flock is empty within a second | the unborn keep falling over a dead hero |
| `TestClearLeavesNothingToFall` | a pour, ten ticks, `Clear`: no orb then and none a hundred ticks on | the unborn survive a restart |
| `TestSameMatterGivesSameRain` | two rains over one matter are in the same places tick by tick | the rain reaches for `Random` |

Left to the eye: the sway, the fade and shrink of a landed drop, the
mark on the floor.

## Orbs.Aura

State: designed, not written. The slacks below are a first guess: the
first green run confirms them or the design is looked at again.

Shared in the test unit, free functions over `Flock.Orbs` and the hero's
center:

- `TurnsAround`: the turns the ring makes about the center, the sum of
  the angles between neighbours in list order, the last to the first
  included, in whole laps. "The hero is inside the ring" is one turn.
- `GapsAreEven`: the distances between neighbours in list order, the
  last to the first included, are all within 15% of their mean.

A ring is "settled" 200 ticks after its cast with the hero standing. The
matter is a floor two cells thick; the hero's center is a cell above it.

| Test | Holds | Turns red when |
|---|---|---|
| `TestCastBringsSixtyOrbs` | 60 orbs in the flock at once, none armed, all of size 0 | the count of a cast changes, or an orb is armed inside the matter |
| `TestOrbsArmOneByOneAndAllInTheEnd` | none is armed five ticks in; arming takes ten different ticks or more; a settled ring is all armed, at full size and light | the ring is a shield before it is there, or an orb never arms |
| `TestSettledRingStandsAroundHeroAtEvenGaps` | one turn about the hero; even gaps; the nearest orb is no nearer than half the farthest | the ring has a hole, a knot, or has fallen in |
| `TestRingFlowsOneWay` | a settled ring a second later: every orb has turned about the hero, all the same way | the flow stops or a seat runs backward |
| `TestRingKeepsAroundWalkingHero` | the hero walks 2 units a tick for 100 ticks: one turn about him on every tick | he walks out of the ring |
| `TestRingKeepsAroundHeroInIceJump` | 10 units a tick for 40 ticks: one turn about him on every tick | the leash is longer than the ring is wide |
| `TestLeapDoesNotCarryRingAndItClosesAgain` | the hero is 200 units away in one tick: on that tick no orb moves half that far; three seconds on, standing, one turn about him and even gaps | the ring leaps with the hero, or never comes |
| `TestCarryTakesRingThroughDoorWithoutFlight` | a settled ring, `Carry(-480, 0)`: every orb is 480 units to the left; on the next tick, the hero's center moved the same way, no orb moves five units | the path or the seats stay behind the door and the ring flies after him |
| `TestCarrySendsOrbsOnFacesToRing` | a cast, five ticks, `Carry`: every orb is armed at once | an orb waits on a face of the screen left behind |
| `TestSecondCastWeavesNewOrbsBetweenOld` | a settled ring, a cast: 120 orbs; the old sixty keep their order and stand at every second place | the newcomers are appended, or the old are reshuffled |
| `TestThirdCastAddsNothingToFullRing` | 120 stay 120 | the ceiling is lost |
| `TestOrbLivesTwentySecondsAndThreeAtMost` | 659 ticks after a cast all 60 are alive; the count falls on ten different ticks or more; 792 ticks after it the flock is empty | the life changes, or the ring goes out at once |
| `TestRingClosesUpAfterLoss` | five neighbours of a settled ring are spent: two seconds on, 55 orbs, one turn, even gaps | the hole stays |
| `TestCollapseImplodesEveryOrb` | every orb is imploding; the flock is empty within a second | the ring outlives the hero |
| `TestSameCallGivesSameRing` | two auras, the same casts and ticks: the same places tick by tick | the aura reaches for `Random` |

Left to the eye: the ceremony itself (the rise out of a face, the sway,
the spiral of the flight), the squeeze of the tail into a drop, the
thread of a leap in flight, a ring called after an empty one.

## Monsters

State: written, not yet run on a compiler. The first suite over
`Monsters.pas`: the shove of a blow (`TakeDamage`) and what it must never
do - leave a body in a wall or hanging in the air. The floor, the corpse
and the patrol are tried in `Monsters.Bodies` below; the rest of
`TMonster` (the chase, health tiers, the events but one) is left to a
later batch. The unit is tried by `Tests\Monsters\Tests.Monsters.pas`, fixture `TMonsterTests`;
the search path of the project grows by `..\Game` and `..\Game\Pads`.

Shared setup, `Tests\Tests.Rooms.pas` (the monsters of every later batch
stand in it too):

- `RoomFromRows` takes twelve strings of sixteen characters, `#` a solid
  cell, `.` an open one, as `MatterFromRows` does, and builds: a
  one-screen `TLevel` through a temporary JSON file (`id`, `grid` 16 by
  12, an empty `tilePalette`, `backgrounds` and `entities`, one screen
  whose `rows` are all zeros and whose `collision` is the strings); a
  `TPadWorld` over it - the level has no pads, so the renderer and the
  sprite cache are `nil` and no pad ever asks them, the jump reach is
  `nil` too; a `TMonsterRegistry` loaded from `monsters.json` beside the
  executable. The room owns all three.
- `Room.Place(AMonsterId, ACol, ARow)` gives a `TMonster` on that cell,
  counted from 1 as the level file counts, its feet on the bottom line of
  the cell. No animation set (`Default(TAnimSet)`), no disc art, lives
  scale 1.
- The bursts are `nil`. A body that explodes, brought to zero lives, fans
  bullets into its burst, so none is killed in this suite: the blows of
  this batch are struck with `ALosses` 0, and the one test that spends a
  life spends a single one. A gravel has no fan and does die into a `nil`
  burst: `Monsters.Bodies` kills it. `Tick` takes the hero at (0, 0) and a
  `nil` burst: the subjects never shoot.
- A body falls slowly: it needs about a hundred and twenty ticks to drop
  the height of the screen, so a test that waits for a landing waits a
  hundred and fifty.
- The subjects are `medkit` (a static pickup) and `gravel` (a patrol
  walker). Neither carries smoke, which is made only for machines and for
  the barrel.
- Rooms: "floor" is the last row solid; a body standing on it has its
  feet at y = 352. "Wall right" adds a solid column 14 over the floor
  (its face at x = 416), "wall left" a solid column 3 (its face at
  x = 96). "Drop" is a wall column 10 over the floor with the body put
  at column 9, row 2, in the air. "Ledge" is solid cells on row 9,
  columns 4 to 6 (the top at y = 256), the body put on its right end.
- A body is flush to a wall when the edge of its art - `X + 24` going
  right, `X + 8` going left - lies within one unit of the wall's face and
  not inside it. 8 is the margin of the art in the 32-unit sprite, a 2008
  number the game keeps as its hit inset, not a figure under tuning.

| Test | Holds | Turns red when |
|---|---|---|
| `TestKnockMovesBodyAwayByHalfTheBlow` | floor, a medkit mid-screen: a blow of 8 to the right moves it 4 units right, a blow of -8 brings it back | the recoil is cut off or the statics are held fast |
| `TestKnockMovesWalkerToo` | the same with a gravel: it moves by half the blow | the recoil is kept for some kinds of body only |
| `TestKnockStopsFlushAgainstRightWall` | wall right, a medkit at column 8: fifty blows of 8 and the body is flush to the wall | the body ends inside the wall (the shove asks about the cell it stands in) or stops short of it |
| `TestKnockStopsFlushAgainstLeftWall` | wall left, a blow of -8, the same | the same on the other side: the two sides have probes of their own |
| `TestKnocksDoNotSinkBodyDeeper` | wall right: after fifty blows the place is X; two hundred and fifty blows on, it is still X | blows pile depth up in the wall |
| `TestFallingBodyKnockedAlongWallStillLands` | drop: a tick to start the fall, then a blow of 8 and a tick, a hundred and fifty times: the body rests on the floor (y = 352) and is not inside the wall | a sliver of the art in the wall holds a falling body in the air |
| `TestKnockOffLedgeDropsBodyToTheFloor` | ledge: a hundred and fifty blows of 8, each with a tick: the body ends on the floor (y = 352) beyond the ledge's right end | a shove stops at an edge with nothing under it; a medkit can no longer be knocked off a floor |
| `TestKnockKeepsBodyOnTheScreen` | floor, three hundred blows of 8: X is 482 at most; three hundred of -8 on: X is 0 at least | nothing holds a body at the edge of the screen |
| `TestHitCostsTheLosses` | a blow with `ALosses` 1: `Lives` is one lower than before | a blow stops counting, or counts twice |

Left to the eye:

- The mirroring of a body at rest. Its facing has no reader outside
  `Draw`; what made it flicker - the body hung in the air - is test 6.
- The boss in a maneuver is not shoved: a boss needs the textures of its
  disc.
- A blow that kills a body that explodes: the fans of fragments go into
  a `TBurst`, which needs a renderer.
- The barrel. It carries smoke; if the smoke builds without a window the
  first run will show it, and a barrel joins tests 1, 3 and 6 as a second
  subject.
- The invisible wall of a level: a solid column no art draws is art
  against collision, and the level file is judged by a live run.

## Monsters.Bodies

State: written, 11 tests, not yet run on a compiler. The expectations were
checked on a Python port of the monster's floor physics (the oracles, the
patrol, the fall, the death) with the corpse rule switched on and off: with
it off, test 6 is red. The unit is tried by
`Tests\Monsters\Tests.Monsters.Bodies.pas`, fixture `TMonsterBodyTests`.

Shared setup: `Tests.Rooms`, as above. `RoomRowsOf` (the rows of a room
with a wall column and a ledge) lives there now, for both monster units;
the corridor - the floor and two solid columns, 5 and 12, their faces at
x = 160 and x = 352 - is built from it in the unit. The subjects are the
`gravel` (a patrol walker that turns at a ledge's end) and the
`gravelFemale` (walls only). Neither explodes, so both die into a `nil`
burst. A body is laid dead by one blow for all its lives and a hundred
ticks at most.

| Test | Holds | Turns red when |
|---|---|---|
| `TestLethalHitStartsDyingAndTellsTheGameOnce` | floor, a gravel struck for all its lives: `mlDying`; `DrainEvent` gives `meDied`, then `meNone` | a death is not told, or told twice |
| `TestHitThatLeavesLivesKillsNobody` | a blow that leaves one life: alive, no event | the line of death moves by one |
| `TestDyingBodyBecomesACorpseThatLiesStill` | floor: the body is dead within a hundred ticks; a hundred and fifty on, it is dead, in the same place, on the floor | a corpse goes on patrolling, or sinks |
| `TestCorpseIsNotKilledAgain` | a corpse struck twice more: still dead, no second `meDied` | a dead body can die again: the score and the fragments twice |
| `TestCorpseOnALedgeStaysOnIt` | ledge, a corpse mid-ledge: a hundred and fifty ticks on it is on the ledge (y = 256) | the fall rule fires for a corpse that has the grid under it |
| `TestCorpseKnockedOffALedgeFallsToTheFloor` | ledge: a corpse on the right end, ten blows of 8, a hundred and fifty ticks: on the floor (y = 352), still dead | a corpse is never asked for a floor: it hangs where the blows left it - the bug of the corpse on a pad that flew away, reached without a pad |
| `TestBodyKilledInTheAirLandsAndLiesStill` | floor, a gravel in the air: a tick to start the fall, a lethal blow, a hundred and fifty ticks: on the floor, dead, X as it fell | a dying body's fall is cut short, or a corpse slides on landing |
| `TestPatrolTurnsBackAtTheEndOfALedge` | ledge, a gravel mid-ledge: nine hundred ticks, every one of them on the ledge (y = 256); the body has been on both sides of its start | the edge-aware oracle lets it walk off, or it stops at the first turn |
| `TestPatrolTurnsBackAtWalls` | corridor: nine hundred ticks, the art never more than two units into a wall; the body has gone both ways | a walker passes through a wall, or sticks to one. Two units, not none: the probes of 2008 let the art in by one before they turn it |
| `TestWalkerWithNoEdgeCheckWalksOffALedge` | ledge, a gravel female: three hundred ticks on, it is on the floor | the edge check is put on every walker |
| `TestWalkerDroppedAboveALedgeLandsOnIt` | ledge, a gravel dropped above it: after a hundred and fifty ticks it is on the ledge (y = 256), not on the floor | a fall goes by a ledge to the floor |

Left to the eye:

- The corpse of the boss. It flies and ignores gravity: it hangs where it
  died by design (`Monsters.Pilot`), and it needs the textures of its disc.
- A body that ignores gravity (the platform, the mount) hanging in the air.
  Both carry a gun that fires into the `nil` burst on its interval, and
  both carry smoke or art the room does not build.
- A corpse over a pit. The fall out of the world below the floor line is
  the 2008 behaviour, and no test pins it.

## Monsters.Pads

State: designed, not written - needs the stage. `TPadWorld.Create` asks
the level's sprite cache for the texture of every pad (`ACache.Get`), and
a texture needs a renderer: the level of `Tests.Rooms` has no pads for
exactly that reason. Three ways out, one to be chosen before the unit is
written:

- A change of game code: `TPadWorld.Create` takes a `nil` texture when it
  is given no cache, and `TPad.Create` does not ask a `nil` texture for
  its size (a pad then draws nothing, which is all a test asks of it).
  The rule of the suite is that game code is not changed for a test's
  sake: this would be the one exception.
- A software renderer in the tests (`SDL_CreateSoftwareRenderer` over a
  surface, no window) and a real `TSpriteCache` on it. No game code
  changes, but the suite then touches SDL, which its rules forbid ("No
  window"). This way has grown into `The stage` below, proposed for the
  pads and the hero together.
- The pads are left to the eye.

The unit is tried by `Tests\Monsters\Tests.Monsters.Pads.pas`, fixture
`TMonsterPadTests`, in the pad rooms of the stage: the pads are reached
through `FindTagged` and moved by `Room.Tick`, the pads before the
monsters, as the game does. "The still pad", "the ferry" and "gap" are
those of `Pads.World`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestBodyStandsOnAPadInTheAir` | a pad over open cells, a gravel put on its deck: a hundred ticks on it is still on the deck's line | a deck is no floor for the feet |
| `TestPatrolTurnsBackAtTheEndsOfAPad` | the same, nine hundred ticks: on the deck throughout, and on both sides of its start | the edge-aware oracle asks the grid alone |
| `TestPadOnAPathCarriesItsRider` | the ferry, a medkit on it: over a whole cycle the rider is on the deck and goes where the pad goes | the ride is lost, or the rider is left behind |
| `TestCorpseRidesAPad` | the same with a corpse | the dead are not carried |
| `TestBodyDroppedOnAPadLandsOnIt` | a gravel dropped above a pad: it lands on the deck, not on the floor | a fall goes through a deck |
| `TestCorpseLandsOnThePadBelow` | a corpse falls from a pad onto another under it | a corpse falls through a deck |
| `TestMonsterDoesNotTripAPlungingPad` | "gap", a pad with a plunge: a medkit lies on it and a gravel is dropped onto it from above; 300 ticks on the pad's `Top` is the file's | the pad gives way under anybody: only the hero makes it fall |

The two tests of a body on a pad that flies into the depth are one test
of `Pads.Rebuild`, `TestNoBodyHangsAfterARebuild`, flown on the arena the
game has: there the judge has ground to jump from, and its jump reach is
`JumpReach` of `Hero.pas`, a free function.

## Monsters.Damage

State: written, 9 tests, not yet run on a compiler. The expectations were
checked on a Python mirror of the window. The unit is tried by
`Tests\Monsters\Tests.Monsters.Damage.pas`, in two fixtures:
`TDamageWindowTests` (the window alone, no room) and `TCappedBossTests`
(`boss1` in a room).

The window's cap is the one `boss1` carries, 30 lives in 33 ticks, so the
tests also hold the number to what it was set for: the hero's best guns
go through it untouched, a bigger blow does not. The guns are numbers
here - 3 bullets every 5 ticks (the chain gun), 22 pellets every 40 (the
grenade volley) - not shots through the game.

| Test | Holds | Turns red when |
|---|---|---|
| `TestBlowsOverTheCapAreCutAtTheCap` | one blow of a hundred: 30 count, the next blow none | the cap is not applied to a single big blow |
| `TestSingleHitsLandUpToTheCapThenNone` | a hundred hits of one: 30 land | the count is kept per blow, not per life |
| `TestHitsLeaveTheWindowWhenItsTickIsOver` | 30 land on tick 0; on tick 32 none more; on tick 33 all 30 again | the window is a tick too long or too short, or never slides |
| `TestNoRunOfTicksTakesMoreThanTheCap` | five lives asked every tick for ten seconds: every run of 33 ticks takes 30 at most | a fixed window that lets 60 through across its edge |
| `TestSteadyFireIsLetThroughAtTheCapRate` | the same ten seconds: 300 in all | the cap is stingier than its word |
| `TestChainGunIsNeverThrottled` | 3 every 5 ticks for ten seconds: none cut | the cap is set under the chain gun (20 a second) |
| `TestGrenadeVolleyIsNeverThrottled` | 22 every 40 ticks for ten seconds: none cut | the cap is set under a point-blank volley |
| `TestHundredBlowsOnOneTickTakeNoMoreThanTheCap` | `boss1` struck a hundred times for one life on one tick: it has lost the cap and is alive | the boss is not given a window, or `TakeDamage` goes round it |
| `TestBlowOverTheCapStillShovesTheBoss` | the cap spent, a blow of 8: no life lost, X moved by 4 | a capped blow stops shoving - the boss would stand still under a barrage |

Left to the eye:

- A barrel blown beside the boss in the game: how the cap reads on the
  screen. Since 3.0.41 the barrel lands one blow of its blast, not a
  hundred fragments; the cap cuts it the same.
- The ticking: the boss in a room does not tick here (it flies, and its
  disc needs textures). The slide of the window is tried on the window.

Open: the shove test leans on a fresh `boss1` not being busy with a
maneuver and on its row being open; the first run shows it.

## Game.Blasts

State: written, 11 tests, not yet run on a compiler. The expectations were
checked on a Python mirror of the wave. The unit is tried by
`Tests\Game\Tests.Game.Blasts.pas`, fixture `TBlastTests`.

The blast is the barrel's in numbers - 100 lives over 80 units, the wave
8 units a tick - with its heart at the origin. Bodies are points on the X
axis and plain objects to tell them apart; walls are functions of a
point. No room and no monster: the unit knows neither. The last test
reads the real barrel from `monsters.json` beside the executable.

| Test | Holds | Turns red when |
|---|---|---|
| `TestWaveReachesANearBodyBeforeAFarOne` | a body 24 units off is struck on tick 3, one 56 off on tick 7 | the blast strikes everything at once, or the wave's speed moves |
| `TestBodyIsStruckOnce` | ten ticks over a body 24 units off: one strike | a body is wounded on every tick the wave lives |
| `TestBodyBeyondTheRadiusIsNeverStruck` | a body 81 units off, twelve ticks: no strike | the wave outruns its radius |
| `TestWallSheltersTheBodyBehindIt` | a wall from 40 to 48: the body at 24 is struck, the one at 56 is not | a blast goes through walls, or a wall shelters what stands before it |
| `TestSightDoesNotAskTheFarEnd` | matter from 56 on: the sight to 56 is clear, to 64 is not | a body flush against a wall is hidden by the wall it leans on |
| `TestBlastIsSpentWhenTheWaveHasGoneItsRadius` | nine ticks: not spent; the tenth: spent | a blast is dropped a tick early, or never |
| `TestLivesFallWithTheDistance` | 100 at the heart, 70 at 24 units, 30 at 56 units up, 1 at the radius | the falloff bends, or forgets the vertical |
| `TestLivesGrowWithTheGrade` | 24 units off: 105 on x1.5, 140 on x2 | a barrel loses its worth on a harder grade |
| `TestKnockShovesAwayFromTheHeart` | 24 units off: 22 for a body to the right, -22 to the left, 0 over the heart | a blast pulls bodies in, or shoves all one way |
| `TestNearestPointLiesOnTheBody` | a 16 by 32 body: its left edge from the left, its corner from below right, the point itself from inside | the distance is taken to a body's corner or middle |
| `TestBarrelKillsFiftyLivesNextDoorOnEveryGrade` | the barrel of `monsters.json`, a body in the next cell: at least 50, 75 and 100 lives on the three grades | the barrel's numbers are tuned below the gunner of level 2, screen 4 |

Left to the eye:

- Who the game strikes and with what: `ResolveBlasts`, `StrikeMonsters`
  and `StrikeHero` live in the dpr, out of the suite's reach. A barrel
  among monsters, a chain of barrels, the hero in the wave and in the
  mercy window, a pad as a shelter - by a live run.
- The feel: the wave's speed against the picture of `Game.Explosions`,
  the shove of a body, the radius against the hero's habit of standing
  close.

## Effects.Lightning

State: written, 31 tests, green on the first run. The unit is tried by
`Tests\Effects\Tests.Effects.Lightning.pas`, in two fixtures:
`TBoltShapeTests` for `BuildBoltShape` (a free function; the shape is a
record, and all of it is seen) and `TBoltFieldTests` for `TBoltField`, its
public part: `Shoot`, `Tick`, `TakeJolt`, `Clear`, `Count`. `Draw` is never
called and SDL is never touched; the unit sits in `Core\`, already on the
search path.

A field keeps its bolts to itself, so a test reads it through two doors:
`Count` (is the bolt still there) and `TakeJolt`. A stroke gives its jolt on
the tick it begins and no two strokes begin on one tick, so the ticks that
give a jolt are the ticks of the strokes. Tick 0 is the moment right after
`Shoot`, tick N the moment after the N-th `Tick`. A test that counts strokes
shoots a look with a jolt above zero, or it would see none.

The numbers spelled are the ones the design has decided: the pieces of a
channel (4 for a bolt of 10 units, 128 for 380 and for any longer), the
tries at a branch (one, and one more for every 36 units, five at most), the
branch's width 0.55, light 0.6, lean 18 to 44 degrees, length 30 to 70% of
what is left of its parent but not under 3 units, its place 12 to 75% along,
a depth of two, strokes 1 to 8, the wait between strokes 1 to 4 ticks, their
strength 0.6 to 0.95 of the first. The numbers of a look in a level (the
reach, the size, the frequency) are never spelled.

The shapes are built over thirty seeds, fork chance 1 where branches are
the subject. The unit sets the low bit of every seed it takes, so the seeds a
test sets against each other are odd and far apart: 2 and 3 are one seed.

| Test | Holds | Turns red when |
|---|---|---|
| `TestSameSeedsGiveSameShape` | two builds with the same arguments and seeds give the same limbs and the same offsets | the build reaches for `Random` or for something that is not in its arguments |
| `TestOtherSeedsGiveOtherShape` | another coarse seed gives another shape, and so does another fine seed | a seed is dropped or fixed |
| `TestTrunkComesFirstAtFullStrength` | limb 0 hangs on nothing, is as long as asked, at width 1 and light 1; it tapers when asked and not otherwise | the trunk is born with a parent or a share of its own, or its taper ignores the argument |
| `TestLongerBoltIsCutIntoMorePiecesWithinLimits` | a trunk of 1 unit is 2 pieces, of 10 units 4, of 380 units 128, of 5000 units still 128 | the length of a piece changes, or the floor or the ceiling of the generations is lost |
| `TestEveryLimbIsPinnedAtBothEnds` | of every limb of a long forked bolt, the first and the last offset are zero | a generation writes over an end: the channel no longer reaches its root or its tip |
| `TestChannelStaysNearItsAxis` | no offset of a limb is wider than twice the jag times that limb's own length | the shift stops halving from generation to generation, or is taken from the trunk's length |
| `TestNoForkChanceGivesJustTheTrunk` | at fork chance 0 the shape is one limb | a branch is born without its roll passing |
| `TestSureForkGivesAsManyBranchesAsTriesAllow` | at fork chance 1 the trunk carries 1 branch at 10 units, 3 at 80, 5 at 380 | the tries are counted another way, or the ceiling of five is lost |
| `TestBranchesComeAfterTheirParents` | every limb after the first hangs on one earlier in the list | a branch is put before its parent: the drawing places limbs in list order and would find the parent not yet placed |
| `TestBranchesOfBranchesAreOneDeepNoMore` | over many bolts, the deepest limb is a branch of a branch, and none is deeper | branches of branches are lost, or nothing stops the depth |
| `TestBranchIsNarrowerDimmerAndTapers` | a branch is 0.55 of its parent in width and 0.6 in light, and tapers even when the trunk does not | a share changes, or a branch is born blunt |
| `TestBranchesLeanBothWaysWithinTheirBand` | every branch leans 18 to 44 degrees off its parent, and over many bolts to both sides | the lean loses its sign, or the band moves |
| `TestBranchLengthIsAShareOfWhatIsLeftOfItsParent` | a branch longer than the shortest is 30 to 70% of what is left of its parent past its base | the share is taken from the whole parent, or the band moves |
| `TestNoBranchIsShorterThanThreeUnits` | on a short bolt, where the share would give less, no branch is under 3 units | the shortest length is lost: slivers of branches |
| `TestBranchLeavesItsParentBetweenItsEnds` | a branch leaves neither at the parent's root nor at its tip, and 12 to 75% along it (to within half a piece) | a branch leaves at an end, or the band moves |
| `TestOtherFineSeedKeepsBranchesAndBigPicture` | a bolt of 100 units built with one coarse seed and two fine: the same limbs, the same offsets at the root, the quarters and the tip of the trunk, and a channel that is not the same | the fine seed reaches a decision about branches or a coarse generation: a second stroke would jump instead of shiver |
| `TestBoltLivesExactlyItsLifeInTicks` | a bolt shot with a life of 5 is in the field at once, still there after 4 ticks, gone after the 5th | a bolt is lit a tick too long or too short, or joins the field a tick late |
| `TestLeaderHoldsBackTheFirstStroke` | with a leader of 4 ticks, the one stroke's jolt comes on tick 4 and not before | the leader is ignored, or the first stroke begins with it |
| `TestBoltOutlivesItsLeader` | a bolt with a leader of 4 and a life of 3 is in the field through the leader and gone after the 7th tick | the life is counted from the shot, not from the first stroke |
| `TestBoltLivesItsLifePastTheLastStroke` | a bolt of 8 strokes and a life of 4 is still there 3 ticks after its last stroke begins, and gone on the 4th | the life is counted from the first stroke: the bolt goes while its last strokes are still due |
| `TestStrokesCountIsWhatTheLookAsks` | a look asking 1, 2 and 5 strokes gives 1, 2 and 5 jolts over the bolt's life | a stroke is lost, or struck twice |
| `TestStrokesAreHeldToOneThroughEight` | 0 asked gives 1 stroke, 20 asked gives 8 | the clamp moves, or a bolt of none is born |
| `TestRestrokesComeOneToFourTicksApart` | over thirty fields, the waits between strokes are 1 tick at the least and 4 at the most, and both are met | the band of the wait changes; a wait of 0 would put two strokes on one tick |
| `TestRestrokesAreWeakerThanTheFirst` | the first stroke gives the look's jolt whole, every later one 0.6 to 0.95 of it | later strokes are as strong as the first, or fainter than the band |
| `TestTakeJoltGivesTheLooksJoltOnceAndEmpties` | after one shot with a jolt of 0.14 the ask gives 0.14 and the next ask gives 0 | the ask does not empty the jolt, or the first stroke is scaled by something besides its look |
| `TestJoltsOfTwoShotsAddUp` | two shots before one ask: the ask gives the sum | a second shot's jolt writes over the first |
| `TestLaterStrokesPileUpUntilAsked` | a bolt of 3 strokes, 60 ticks, nobody asks, a jolt of 1: the ask gives the first whole and two weaker ones, 2.2 to 2.9 | a jolt is lost when its bolt is dropped, or kept only for the tick it came |
| `TestSameSeedsGiveSameStrokes` | two fields of one seed give the same jolts tick by tick; a field of another seed does not | the field reaches for `Random`, or ignores its seed |
| `TestFullFieldDropsItsOldest` | a field of 3 with one long-lived bolt and three short ones: 3 in the field, and none once the short ones' life is spent | the newest is refused instead of the oldest dropped, or the count runs past the capacity |
| `TestTickDropsOnlyTheSpent` | bolts of life 2, 6 and 2: one is left after 2 ticks, it stays through the 5th and goes on the 6th | the tick shifts the kept bolts wrong when it drops the spent |
| `TestClearEmptiesTheFieldAndItsPendingJolt` | after `Clear`: no bolts, no jolt, and none comes back with the tick | `Clear` forgets a bolt or the jolt: a restart of the world shakes the screen |

Left to the eye: everything `Draw` makes - the three passes, the bloom of
the first tick, the fade, the lights at the ends, the glow of the room, the
leader growing along the trunk, and whether the channel reads as lightning
at all. `ShiftFrame`: it moves the end of a bolt that struck a wall, and
that end is seen only in the drawing. The clamp of a life under 1: a field
shows no difference without a `Draw`, which divides by it. The half chance
of a branch of a branch: it is a share of tries, not a thing a single seed
holds. `TLightning` (when it shoots, where it ends) is a game unit with its
own door, `TakeJolt`, and is not tried here.

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
  off, `level1-structures.mset` attached - `s16-platform` is in it.
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

## Pads.Plunge

State: designed, not written. Needs no stage: `TPlungeCycle` is a record
that counts. The expectations were checked on a Python port of the cycle.
The unit is tried by `Tests\Pads\Tests.Pads.Plunge.pas`, fixture
`TPlungeCycleTests`; `..\Game\Pads` is on the search path already.

Shared in the unit: `CycleOf(ADelay, ARest, ARise)` - a cycle rewound with
a `TPadPlunge` that plunges, a reach of 200 and seed 7. Unless a test says
otherwise the delay is 1 s, the rest 1 s and the rise 66 units a second:
an even climb would take 100 ticks. "The whole cycle" is 600 ticks from
the tread.

| Test | Holds | Turns red when |
|---|---|---|
| `TestHoldsUntilTrodden` | 1000 ticks, never trodden: `ppHolding`, `Below` 0 throughout | a failing pad falls by itself |
| `TestPadThatDoesNotPlungeNeverGives` | a `TPadPlunge` with `Plunges` False, trodden on every one of 1000 ticks: `ppHolding`, `Below`, `Dip`, `Lean` and `Effort` all 0 throughout | an ordinary pad twitches, flares or falls under the hero |
| `TestGivesForTheDelayThenFalls` | trodden once: `ppGiving` before any tick; `ppGiving` with `Below` 0 on each of 32 ticks; `ppFalling` or later by the 34th | the pad falls at once, or the delay is counted in the wrong unit |
| `TestStandingOnDoesNotStartTheDelayOver` | one cycle trodden once, another trodden on every tick: both leave `ppGiving` on the same tick | `Tread` loses its guard: a hero who stands still never falls |
| `TestNoDelayFallsOnTheNextTick` | delay 0: one tick after the tread it is `ppFalling` | a delay of zero, which the level file allows, never runs out |
| `TestFallSpeedsUpToTheReach` | from the tread to `ppFallen`: `Below` never shrinks and is never over the reach; until the tick it comes to rest no step down is smaller than the one before; the first step is under a unit and some step is over six; at rest `Below` is the reach; the fall takes under two seconds | the pad goes down at an even pace, like a lift; or it overshoots its place under the screen |
| `TestLiesBelowForTheRestThenClimbs` | `ppFallen` with `Below` at the reach on each of 32 ticks after it comes to rest; `ppClimbing` or later by the 34th | the pad bounces back at once, or never climbs |
| `TestClimbsHomeUnevenlyAndHoldsAgain` | on the climb `Below` never grows; its steps take five different sizes or more; home - `Below` 0, `ppHolding` - no sooner than 50 ticks after the climb began and within 400 | the climb is a jump, an even glide or endless |
| `TestTroddenOnTheClimbItComesHomeThenGivesAgain` | trodden on every tick of two whole cycles: on the first climb `Below` never grows; on the tick after it is home it is `ppGiving`; it reaches `ppFalling` a second time | a pad stood on drops again from halfway up, or holds for good once it is back |
| `TestFailingPadTwitchesWithinBounds` | 300 ticks of holding: `Dip` and `Lean` each leave zero; `Dip` stays within 8 units and `Lean` within 15 degrees | the twitch is lost, or its spring runs away |
| `TestDeadPadComesToRest` | rest 10 s: within three seconds of `ppFallen` both `Dip` and `Lean` are 0, and stay 0 until the climb | a pad with dead jets goes on kicking |
| `TestJetsFollowThePhase` | `Effort` over the phases: holding, 300 ticks - within 0..1 and never 1; giving, delay 5 s - only 0 and 1, both seen; falling and fallen - 0 on every tick; climbing - above 0 and at most 1 on every tick | the jets burn through the fall, die on the climb, or idle at the full |
| `TestDiceAreTheSeedsAlone` | two cycles of seed 7 through the whole cycle: `Below`, `Dip`, `Lean` and `Effort` equal tick by tick; a third of seed 8: its `Dip` differs on some tick | the cycle reaches for `Random`, or two pads twitch in step |
| `TestRewindPutsItHomeHolding` | rewound in the middle of the fall: `ppHolding`, `Below`, `Dip` and `Lean` 0 | a restart leaves the pad under the screen |

Left to the eye: how a twitch looks and how the jets cough - the rig
reads the effort, and a rig is drawn.

## Levels.Pads

State: designed, not written. Needs no stage. The unit is tried by
`Tests\Levels\Tests.Levels.Pads.pas`, fixture `TLevelPadsTests`, through
`TLevel.LoadFromFile`: the parser (`Levels.Pads`) and the checks at load
(`Levels.Defs`) are one door from outside - a level that loads, its
`Pads` to read, or an exception: `EPadError` from the parser,
`ELevelError` from the checks.

Shared setup: `Tests.Rooms` gains `LevelFromRows(ARows, ASections)` - the
level of a room with `ASections`, JSON members such as `"pads": [...]`
and `"respawns": [...]`, added to its root; no pad world and no registry,
the caller frees it. A pad of a test names a sprite (any name: the level
does not open art), screen 1, x, y and width 32 unless said otherwise.
The room is "open" unless a wall is named.

Only the pads and the respawn points are tried here. The checks of a pad
group belong to the arena, tried by nobody yet.

| Test | Holds | Turns red when |
|---|---|---|
| `TestPadReadsItsPlaceAndDefaults` | a pad with the five members it must have: one pad, its sprite, screen, x, y and width as written; bullets `pbBlock`, route `prNone`, bob 0, no tag, no group, `Plunges` False | a default changes: the pads of level 1 are cover because they block |
| `TestPadReadsWhatItIsGiven` | `"bullets": "pass"`, a tag, a bob, a ping-pong path of two stops with a speed and a pause: each lands in its own field, the stops in their order | two members are swapped, or the stops reversed |
| `TestRouteDefaultsToPingPong` | a path with stops and a speed and no route: `prPingPong`; `"route": "loop"`: `prLoop` | the default route changes under the level files |
| `TestBadPadNumbersRaise` | each alone raises `EPadError`: width 0, bob -1, bullets "bounce" | a typo loads |
| `TestBadPathRaises` | each alone raises `EPadError`: route "zigzag", no stops, a stop of three numbers, speed 0, pause -1 | a pad on a broken path loads and stands, or divides by zero |
| `TestStopOffTheScreenRaises` | a stop at x = 496 for a pad 32 wide raises `ELevelError`; at x = 480 it loads | a pad travels off the hero's screen without its riders |
| `TestTwoPadsOfOneTagRaise` | two pads tagged alike raise `ELevelError`; two with no tag load | a lamp hangs on the wrong pad of two |
| `TestPlungeReadsItsNumbers` | `"plunge": {"delay": 1, "rest": 2, "rise": 3}`: `Plunges`, and each number in its own field | two members are swapped |
| `TestPlungeLeftOutTakesHalfASecond` | `"plunge": {}`: `Plunges`, the delay 0.5, the rest not below 0, the rise above 0 | the pad that fails "half a second later" fails at once or late |
| `TestBadPlungeNumbersRaise` | each alone raises `EPadError`: delay -1, rest -1, rise 0 | a pad that never climbs back loads |
| `TestPlungingPadMustStandOnItsPlace` | a pad that plunges and has a path raises `ELevelError`; one that plunges and joins a group raises too | a pad is asked to fall and to travel at once |
| `TestPlungingPadOverAWallRaises` | "gap", the pad in the gap: it loads; a solid cell put in the shaft on the bottom row raises `ELevelError`; a pad 64 wide over the gap and the ledge beside it raises | a pad falls into a wall and out through it with its rider |
| `TestRespawnNeedsAFloorThatStays` | "gap", a respawn point on column 9, row 8, over the gap: over a still pad in the gap it loads; over a pad that plunges, and over one on a path, it raises `ELevelError`; with no pad it raises | the hero is reborn over a pad that drops him into the pit he came from, for ever |

Left to the eye: nothing here is drawn. The checks of the groups, of the
rigs a pad wears and of the events that rebuild are not tried.

## Pads.World

State: designed, not written - needs the stage. The first suite over
`Pads.World`: what a deck answers to the feet, how a pad travels, what a
blow does to it and how a pad that plunges moves - the pad's side of the
contract with its riders. The rebuild is `Pads.Rebuild` below. The unit
is tried by `Tests\Pads\Tests.Pads.World.pas`, fixture `TPadWorldTests`.
A pad is reached through its world (`FindTagged`), and moved by
`Pads.Tick(1)` alone: no hero and no monster is in the room.

Shared in the unit: the room is "open" unless a wall is named; a pad with
a plunge stands in the gap of "gap" - the level takes it nowhere else -
and its plunge is `{}`, the numbers the parser gives. "The still pad"
stands at x = 224, y = 224. "The ferry" is the same pad with a
ping-pong path of one stop 64 units to the left, 32 units a second and a
pause of a second: a leg of 66 ticks, a cycle of 198. "The lift" has its
one stop 96 units up. A "blow to the right" is a `TPadBlow` whose box
lies inside the pad's body, `WayX` 1, `WayY` 0, 50 ticks, and no fence.

| Test | Holds | Turns red when |
|---|---|---|
| `TestStillPadKeepsItsDeckAndOnlyBobs` | the still pad with a bob of 1.5, 200 ticks: `Left` and `Top` are the file's on every tick, `Travels` False, `Effort` 0; `Lift(1)` takes different values and stays within 1.5 units | the bob moves the deck - the riders jitter and the 2008 wall probes read the wrong row -, or an ordinary pad flares its jets |
| `TestDeckHoldsFeetOnItsLineAndSpan` | `DeckUnder` gives the pad for feet at its `Top` with a point inside the span, and with a point on either end of it; `nil` a unit above the line, a unit below it, a unit past either end, and on screen 2 | feet on the very edge fall, or a deck holds feet that are not on it |
| `TestDeckCatchesAFallAtAnySpeed` | `DeckCrossed` gives the pad for feet 40 units above the deck a tick ago and 40 below it now, and for feet that came down onto its very line; `nil` for feet below it on both ticks, for feet that rose from under it to over it, and for a fall beside the span | a fast fall goes through a deck, or a jump from below is caught by it |
| `TestFallLandsOnTheHighestDeckCrossed` | two pads, one 64 units under the other: a fall that crossed both gives the upper | a fall lands on the lower deck through the upper |
| `TestDroppedDeckLetsFeetByWithItsNeighbour` | two pads flush side by side and a third 64 units under them: with the first passed as `AIgnored`, a drop on the seam of the two gives the third | a drop on a seam lands on the neighbour, or the drop lets every deck by |
| `TestBodyIsACellDeepUnderTheDeck` | `BodyAt`: True a unit under the deck and 31 under, at the left edge; False 32 under, a unit over the deck, and at the right edge. `Bodies(1)` is one box: the pad's place, its width, a cell deep | the body is not the cell the boss, the sparks and the debris are stopped by |
| `TestPadThatLetsBulletsByIsStillABody` | two pads, `block` and `pass`: `StopsBulletAt` inside the first True, inside the second False; `BodyAt` True in both | the bullets property is ignored, or it opens the pad to the boss |
| `TestFerryGoesToItsStopAndBack` | the ferry, two cycles: it never leaves the stretch between its place and its stop and `Top` never changes; it stands on the stop for a second at least and on its place as long; the second cycle repeats the first place by place | a stop is overshot, a pause skipped, or the path drifts |
| `TestFerrySetsOffAndStopsGently` | over a leg: the first step and the last are under a quarter of a unit, no step is over twice the mean of the leg | the pad jerks off its stop at full speed |
| `TestPingPongAndLoopPassTheirStopsInOrder` | two stops, a pause of a second: there and back the pad stands, in turn, on stop 1, stop 2, stop 1, its place; round - on stop 1, stop 2, its place | the routes are swapped, or a stop is passed without a pause |
| `TestPadOffTheHerosScreenHoldsStill` | the ferry ticked 30 times with `Pads.Tick(2)`: it stands on its place, `MotionX` 0; then with `Pads.Tick(1)`: it sets off as from a rewind | the pads of a screen left behind travel on and drop what lies on them |
| `TestMotionAndPrevTopTellTheTicksStep` | the ferry and the lift, a cycle: on every tick `MotionX` is `Left` less the `Left` of the tick before, and `PrevTop` is the `Top` of the tick before | a rider carried by the deck's step is carried by the wrong one |
| `TestDeckCarriesFeetFromWhereItStood` | the lift, on a tick of its leg when the deck moved over half a unit: for feet on the line it left, inside the span, `DeckCarrying` gives the pad and `DeckUnder` gives `nil`; for feet on its new line `DeckCarrying` gives `nil` | the carrying deck is looked for where it stands now: a rider is dropped on every tick the lift moves |
| `TestRisingDeckPicksUpStillFeet` | the lift going up: `DeckCrossed` for feet that stood still on a line the deck rose past in this tick gives the pad | a lift passes up through whoever stands in its way |
| `TestBlowKnocksAPadACellAndItComesHome` | the still pad, a blow to the right: `Knocked` at once; its `Left` grows to 32 units from home and no further, `Top` unchanged; 50 ticks on it is home to the unit and not `Knocked` | the knock is lost, goes further than a cell, or leaves the pad off its place |
| `TestKnockStopsFlushAtAWall` | a still pad at x = 240 and a solid cell 16 units from its right edge, in the body's row: the blow takes it 16 units, flush to the wall, never into it | a knocked pad ends in a wall |
| `TestKnockStopsAtAPadTheFenceAndTheScreensEdge` | each alone stops the blow 16 units out: another pad 16 units to the right; a fence shut from 16 units past the right edge on; the edge of the screen for a pad at x = 464 | pads are knocked into one another, into the boss's lap or off the screen |
| `TestKnockKeepsRoomOverTheDeck` | a still pad at y = 160 with a solid cell over it, a cell of air between: a blow straight up leaves `Top` where it was through all its 50 ticks, though the pad is `Knocked` | a rider is crushed into the ceiling by a knocked pad |
| `TestSlantedBlowSlidesAlongAWall` | the pad and the wall of `TestKnockStopsFlushAtAWall`, a blow down and to the right (0.707, 0.707): the right edge stops at the wall, the pad goes on down over 16 units | a pad stopped one way stops both |
| `TestSecondBlowTakesAPadFromWhereItIs` | a blow to the right, ten ticks, another: on the tick of the second blow and after it the pad never moves over 12 units in a tick; it is home by the end of the second blow's ticks | a pad struck twice snaps home between the blows |
| `TestFerryOnlyRocksUnderABlow` | two rooms, a ferry in each, one struck after 40 ticks: `Knocked`, and its `Left` and `Top` equal the other's on every tick | a blow tears a pad off its path |
| `TestBlowThatMissesKnocksNothing` | a blow whose box lies a cell from every body: no pad is `Knocked` or moves | a blow strikes by nearness |
| `TestPlungingPadHoldsUntilTheHeroTreads` | a pad with a plunge, 300 ticks: `Top` is the file's on every tick while `Lift(1)` leaves zero; then `Press(8)` - a landing that is not the hero's - and 300 more: `Top` still the file's | the twitch moves the deck, or a monster or a medkit sends the pad down |
| `TestTroddenPadFallsUnderTheScreenAndStops` | `Tread` once: `Top` is the file's for ten ticks and has begun to grow by the 25th, `Left` never changes; it comes to rest at y = 480, three cells under the screen, and lies there | the pad stops above the pit's line, 450: a hero riding it down is never taken out of the pit |
| `TestPlungingPadCarriesFromTreadToHome` | from the tread until the pad is home: on every tick `DeckCarrying` for feet on the line it left gives the pad, and `DeckUnder` for feet on its line gives the pad | the deck falls from under its rider, or is no floor on the way up |
| `TestPlungedPadComesHomeAndPlungesAgain` | it is back on the file's `Top` to the unit within ten seconds of the tread and stands there; `Tread` again: it falls again | the pad stops short of its place, or holds for good |
| `TestRewindPutsEveryPadHome` | a ferry 50 ticks out, a still pad knocked, a pad with a plunge in its fall; `Rewind(1)`: each stands on its place, none is `Knocked`; ticked on, each does what a pad of a new room does, tick by tick | a restart leaves a pad off its place or in the middle of its path |

Left to the eye:

- The sag under a landing, the rock of a knocked pad, the look of a pad
  in the depth: `Lift` is seen, but what it should be is judged on the
  screen. `Draw` is never called.
- The lamps and the jets hung on a pad: the rigs read `Effort` and
  `Thrusting` in the game.
- The boss against a pad - the dive that goes round it, the ram that
  breaks on it: `Monsters.Pilot`, and a boss needs the textures of its
  disc.

## Hero.Pads

State: designed, not written - needs the stage. Three of its tests are
red by design, marked in the table: they show two faults found while the
suite was designed. The expectations were checked on a Python port of the
hero's floor physics (the oracles, the walk, the jump, the fall, the
deck) over a port of the pads; on the port the three are red and the rest
green. The unit is tried by `Tests\Hero\Tests.Hero.Pads.pas`, fixture
`THeroPadTests`.

Shared setup: the stage's rooms, `Room.PutHero`, `Room.Tick`. "The still
pad", "the ferry" and "the lift" are those of `Pads.World`; in "gap" the
pad stands in the gap. "On the floor" is feet at y = 352, standing.
"Shoved" is `Hero.ShoveX(4)` and a tick, as a monster's touch does it,
eight times over.

| Test | Holds | Turns red when |
|---|---|---|
| `TestHeroStandsOnAStillPad` | put on the still pad, 100 ticks: `Y` is the deck, `haStand`, `DeckUnderFeet` is the pad on every tick | a deck does not hold |
| `TestHeroWalksOffTheEndAndFalls` | he walks right off the still pad and the key is let go: `Y` is the deck while his middle is over it; a hundred and fifty ticks on he is on the floor | he walks on air past the end, or sinks while still on the deck |
| `TestHeroWalksOverASeamOfTwoPads` | two pads flush side by side, he walks from one onto the other: `Y` is the deck on every tick and no tick finds him falling | the seam trips him |
| `TestHeroWalksFromLedgeOverPadToLedge` | "gap", a still pad in the gap: he walks from the left ledge to the right one, `Y` = 288 on every tick | the ledge check lets him fall between a wall's top and a deck |
| `TestFallLandsOnADeck` | put 270 units over the still pad, in the air: he ends standing on it | a fall goes through a deck |
| `TestJumpFromBelowGoesThroughAndLandsOnTheWayDown` | "open", a pad two rows over the floor (y = 288), he stands under it and jumps: his feet rise over 288, and he ends standing on the pad | his head bumps the pad, or he falls back through it |
| `TestDownDropsThroughADeckNotTheFloor` | on the still pad, `hcDrop`: he ends on the floor; `hcDrop` again there: `Y` and `Action` do not change in ten ticks | Down does nothing on a deck, or the grid's floor lets him through |
| `TestDropOnASeamReachesTheFloor` | two pads flush side by side, his middle on the seam, `hcDrop`: on the floor | the drop lands on the neighbour |
| `TestDropLandsOnThePadBelow` | a pad 96 units under the one he stands on, `hcDrop`: he ends standing on the lower; `hcDrop` again: on the floor | a drop forgets nothing and falls through every deck, or the lower deck is the one let by |
| `TestFerryCarriesStandingHero` | on the ferry, two cycles: `X` less the pad's `Left` does not change by a hundredth, `Y` is the deck and `DeckUnderFeet` the pad on every tick | the rider is left behind, slides or drops |
| `TestLiftCarriesHeroUpAndDown` | the same on the lift | a rider is dropped between the rows |
| `TestSlantedPathCarriesHero` | the same on a pad whose stop is 56 units right and 48 down, as on level 2 screen 2 | the two carries do not go together |
| `TestWallScrapesHeroOffAFerry` | the ferry's stop 160 units to the left, and a solid cell in the row over its deck with its face at x = 128, in the hero's way: he never gets over two units into the wall (`X` + 8 is 126 at least), and ends on the floor | he is carried into a wall, or left standing where the deck was |
| `TestLiftUnderACeilingDropsHero` | the lift's stop at y = 144 under solid cells whose bottom is at y = 128: his feet never rise over y = 160, and he ends on the floor | he is pushed into the ceiling |
| `TestJumpOffAFerryKeepsItsOwnPlace` | on the ferry in the middle of a leg, a jump straight up: from the second tick in the air to the landing `X` does not change | a jump inherits the pad's speed |
| `TestCorpseLandsOnADeck` | put 88 units over the still pad, `Kill`: a hundred ticks on, `Y` is the deck | a corpse falls through a deck |
| `TestCorpseRidesAFerry` | on the ferry, `Kill`, two cycles: `X` less the pad's `Left` does not change, `Y` is the deck | the dead are not carried |
| `TestShoveAlongTheDeckKeepsHeroRiding` | on the ferry, one `ShoveX(4)`: two cycles on he stands on it, 4 units from where he stood on it | a shove throws a rider off a deck that is still under him |
| `TestShovedOffAPadHeroFalls` | on the still pad, shoved: a hundred ticks on he is on the floor | red by design. Nobody asks a standing hero for a floor after a shove: he hangs at the deck's height until a key is pressed |
| `TestShovedOffAFerryHeroFalls` | the same on the ferry, shoved in the middle of a leg | red by design: the case seen in the live run. The pad goes on, he hangs where it was |
| `TestPlungingPadTakesStandingHeroDown` | "gap", a pad with a plunge, he is put on it: for ten ticks `Y` = 288; then `DeckUnderFeet` is the pad and `Y` its `Top` on every tick until `Y` is over 450; the pad is not at rest before that | the pad falls from under him, or stops over the pit's line with him on it |
| `TestHeroWalkingAcrossIsNotTakenDown` | the same room, he walks from the left ledge to the right without a stop and stands: he is on the right ledge, within a unit of y = 288; the pad's `Top` is over 384 within two seconds | a walk across no longer makes it - the delay is shorter than the crossing -, or stepping off saves the pad |
| `TestHeroLeavesAFallingPadOnTheLedgesLine` | the same walk: at the end `Y` is 288 exactly | red by design, by the port: 288.5. The deck's first step down takes him while his middle is on its last unit, and the walk on along the ledge never puts the feet back on the line; a deck on that line would not hold them |
| `TestHeroJumpsOffAsTheFallBegins` | he stands on it until its `Top` first grows, then jumps to the right: he ends standing on the right ledge, `Y` = 288 | the first moment of the fall is too late to jump |
| `TestHeroFallenOntoAClimbingPadComesHomeAndFallsAgain` | the pad trodden with nobody on it and let climb to within 50 units of home; he is put 60 units over it: he lands on it, `DeckUnderFeet` is the pad on every tick up to y = 288, and within a second of that the pad takes him down again | a climbing pad is no floor, or one that brought the hero home holds him |

Open:

- The same hang with no pad in the room: a hero shoved off a wall's top
  while he stands hangs too, on the port. It seems to be the 2008
  behaviour - a shove wrote X and asked for no floor. Whether the fix of
  the two shove tests covers the grid is not decided; if it does,
  `TestShovedOffALedgeHeroFalls` joins them.
- `TestHeroLeavesAFallingPadOnTheLedgesLine` is a question before it is a
  test: half a unit is not seen on the screen, and no pad of level 2
  stands on that line past the plunging one.

Left to the eye and outside the suite:

- The monster's touch itself and the pit that takes a faller out
  (`ResolveMonsterContact`, `HandlePitFall`) live in `Moon2D.dpr`. The
  hero's side is in the table: what a shove of 4 units does, and that he
  is past y = 450 before the pad stops.
- The picture of the hero on a deck: he is drawn with the `Lift` of his
  deck (`DeckLift`).
- A restart: `RestartLevel` rewinds the world (`TestRewindPutsEveryPadHome`)
  and revives the hero, in the game.

## Pads.Formations

State: designed, not written. Needs no stage: free functions over cells.
The unit is tried by `Tests\Pads\Tests.Pads.Formations.pas`, fixture
`TPadFormationsTests`.

Shared in the unit, cells as (column, row) from 0:

- "The zone" is a `TPadGroup` of columns 2 to 13 and rows 4 to 8, 2
  pairs, far flights of 5 cells, 5 of them - the numbers of screen 17.
- "The crane" is the launch span: columns 6 to 9 on row 10. "The floor"
  is a span over the whole width on row 11.
- "The reach" is the table the arena was laid out by, as a function: up
  0 or 1 rows - 3 empty cells across, up 2 - 2, up 3 or more - none (-1),
  down 1 to 4 - 4.
- "Formation one": the pairs (6, 8)-(7, 8) and (10, 7)-(11, 7), and
  (3, 6), (13, 6), (5, 4), (9, 5), (2, 8), (12, 4). "Formation two": the
  pairs (8, 8)-(9, 8) and (3, 7)-(4, 7), and (12, 7), (6, 6), (11, 5),
  (2, 5), (13, 4), (7, 4). The judge takes both from the crane, on a
  Python port of it; they share no cell.
- Dice are a `TXorShift` of a seed that is not zero; "over the seeds" is
  seeds 1 to 50.

| Test | Holds | Turns red when |
|---|---|---|
| `TestJumpReachIsTheTableTheArenaWasLaidOutBy` | `JumpReach` of `Hero.pas` gives the reach above for every rise from -4 to 3 | the hero's jump changes and the arena's formations are judged by a jump he no longer has |
| `TestThrowGivesTheCountInsideTheZone` | over the seeds, 10 cells asked: every throw that succeeds gives 10 cells, all different, all in the zone, and its first four are two pairs side by side | a cell is thrown twice or out of the zone, or the pairs are left to luck |
| `TestThrowFailsWhenTheZoneHasNoRoom` | a zone of three by three, 10 cells asked: False | a throw that cannot fit reports a formation |
| `TestJudgeTakesAFormationThatKeepsTheRules` | formations one and two from the crane: taken, by the reach above and by `JumpReach` alike | the judge turns down what the arena is made of |
| `TestJudgeTurnsDownAPadOverAPad` | formation one with (3, 6) moved to (2, 7), right over (2, 8): turned down | the hero on the lower pad stands in the body of the upper |
| `TestJudgeTurnsDownARunOfThreeAndTooFewPairs` | formation one with (6, 8) moved to (9, 7), beside the pair of row 7: turned down; with (6, 8) moved to (2, 4), one pair left: turned down | a wall of pads, or a formation with no pair to dock |
| `TestJudgeWantsEveryThirdOfTheZone` | (6, 8), (7, 8), (8, 6), (9, 6), (3, 6), (2, 4), (5, 4), (9, 4), (2, 8), (4, 7) - nothing in columns 10 to 13: turned down; (6, 8), (7, 8), (10, 7), (11, 7), (3, 8), (13, 8), (5, 7), (9, 6), (2, 6), (12, 6) - nothing on rows 4 and 5: turned down. Each breaks this rule alone | the arena piles up in a corner |
| `TestJudgeWantsEveryPadWithinAJump` | formation one from the floor alone, three rows under the zone: turned down; with no launch span at all: turned down | a pad nobody can climb to |
| `TestAssignmentMovesEveryPadAndSplitsThePairs` | over the seeds, formation one assigned to formation two - it holds on every seed, on the port: every cell of the new one is taken once; no pad keeps its cell; no two pads that stood side by side stand side by side again; five flights or more are 5 cells or longer | a rebuild in which a pad stays put, or an old pair flies off together |
| `TestSameDiceSameFormation` | two throws, and two assignments, with dice of one seed: the same cells | the functions reach for `Random` |

Left to the eye: whether a formation is fun to fight on.

## Pads.Flights

State: designed, not written. Needs no stage. The unit is tried by
`Tests\Pads\Tests.Pads.Flights.pas`, fixture `TPadFlightsTests`.

Shared in the unit: "a plan" is `TryPlanFlights` over a brief of ten pads
from formation one of `Pads.Formations` to formation two, cell by cell in
the order they are listed there, nobody loaded, every release 0, no bar,
`BriskPace`; "over the seeds" as there. A pad "holds
space" at a tick when its flight is not `Deep`, or the tick is its
`Arrive` or later.

| Test | Holds | Turns red when |
|---|---|---|
| `TestFlightGoesFromItsCellToItsCell` | every flight of a plan: `Place` at tick 0 is its start cell, at `Done` and after it its target cell; in between the pad is never outside the box of the two | a pad lands off its cell, or swings out of the zone |
| `TestFlightIsAnLWithOneCorner` | a flight between cells that differ both ways: `TurnsCorner` is True on one tick and the pad stands on the corner for the pace's pause; between cells of one row it never is | the corner is cut, or clicks twice |
| `TestFlightKeepsToItsPace` | every flight of a plan: no step of a tick is over the pace's top speed; the first step of a leg is smaller than its largest | a pad is thrown faster than its pace, or leaves at full speed |
| `TestPadsInFrontNeverCutIntoOneAnother` | over the seeds, every plan that succeeds, every tick to the last `Done`: any two pads that hold space are a cell or more apart across or down | two bodies in front fly through one another - the floor under the hero is two floors |
| `TestLoadedPadIsNeverSentDeep` | over the seeds, three pads loaded: in every plan that succeeds none of the three is `Deep` | the hero is taken into the depth, where a pad is no floor |
| `TestPadStaysHomeUntilItsRelease` | releases of 0, 6, 12 ... by pad: each flight's `Depart` is its release at least, and `Place` is the start cell up to it | the wave behind the conductor is ignored |
| `TestDeepPadIsBehindFromTheStart` | every `Deep` flight of the plans: `Behind` from tick 0 to the tick before `Done`, not at `Done`; `Depth` 0 at tick 0, 1 on the way, 0 at `Done` | a pad the hero may still land on goes into the depth under him |
| `TestBarredPlaceIsNotFlownThroughInFront` | a bar shut on every tick, for a pad that is not deep, wherever its body would cut into columns 7 and 8 of rows 5 to 7 - cells neither formation holds: over the seeds some plan succeeds, and in each that does no pad that holds space cuts into those cells from its `Depart` on | a pad in front flies through the boss |
| `TestCalmPlanTakesLongerThanBrisk` | one brief planned at `BriskPace` and at `CalmPace`: the last `Done` of the calm one is later | the way home is flown as a fight |
| `TestSameDiceSamePlan` | two plans with dice of one seed: the same flights | the plan reaches for `Random` |

Left to the eye: how the ballet reads - the order, the corners, the
depth.

## Pads.Rebuild

State: designed, not written - needs the stage. The world's rebuild and
restore, flown on the arena the game has: `level1.json` beside the
executable, screen 17, the group `arena17` - the one layout the planning
is known to manage, and a guard that the level file's arena still
rebuilds. The unit is tried by `Tests\Pads\Tests.Pads.Rebuild.pas`,
fixture `TPadRebuildTests`.

Shared in the unit: the level is loaded from the file, the world made on
the stage's art with `JumpReach` and a seed; nobody conducts, so a rebuild
is asked for with `RequestRebuild('arena17', ALoad, nil, nil)` and flown
by `Pads.Tick(17)` until `Rebuilding` is False, 300 ticks at most. "Over
the seeds" is worlds of seeds 1 to 20.

| Test | Holds | Turns red when |
|---|---|---|
| `TestRebuildFliesEveryPadToANewCellOfTheZone` | over the seeds: the rebuild is over within 300 ticks; all ten pads stand on whole cells of the zone, no two on one, none where it stood, the pad from the door among them | the arena does not rebuild, or the door pad never joins |
| `TestAskingAgainMidRebuildDoesNothing` | a rebuild asked for again on every tick of one: the pads fly as in a world of the same seed asked once | a second ask restarts the flights |
| `TestPadInTheDepthIsNoFloorAndNoBody` | over the seeds, every tick, every pad that is `Behind`: `DeckUnder` on its deck, `BodyAt` in its body are empty, and `Bodies(17)` does not hold it; some pad was `Behind` on some seed | a body or a bullet meets a pad that is drawn far away |
| `TestLoadedPadStaysInFront` | over the seeds, `ALoad` True for one pad: it is never `Behind` | the hero's pad goes into the depth |
| `TestKnockedPadHoldsTheRebuildBack` | a pad of the group struck, a rebuild asked for: no pad is `Flying` while `GroupKnocked`; the rebuild starts after | a pad is flown from where a blow left it |
| `TestBlowDuringARebuildOnlyRocks` | a pad on its cell struck in the middle of a rebuild: `Knocked`, and its `Left` and `Top` do not change | a knocked pad cuts into one landing beside it |
| `TestRebuildWaitsForTheHerosScreen` | asked for, then 100 ticks of `Pads.Tick(16)`: no pad of the group moves; `Pads.Tick(17)`: they fly | the arena rebuilds with the hero away |
| `TestRestoreBringsEveryPadHome` | a rebuild, then `RequestRestore`: within 600 ticks `GroupRestored`, every pad on the file's place to the unit | a pad is left in the zone after the fight |
| `TestRewindCancelsARebuild` | `Rewind` in the middle of a rebuild: every pad on the file's place, none `Flying`, `Rebuilding` False | a restart keeps the flights of the last try |
| `TestHeroRidesHisPadThroughARebuild` | the hero put on a pad of the zone, `ALoad` the game's - the pad is his `DeckUnderFeet` -, a rebuild: `Y` is that pad's `Top` on every tick, and at the end he stands on it on its new cell | the hero is thrown off, or taken into the depth |
| `TestNoBodyHangsAfterARebuild` | a gravel on each of the nine pads of the zone, every second one laid dead (`Monsters.Bodies` says how), a rebuild with nobody loaded, the monsters ticked after the pads: 300 ticks after it every body has a deck or a wall's top under its feet, or is gone under the screen | the bug of the corpse on a pad that flew away: a pad in the depth carries nobody, and what stood on it hangs |

Left to the eye and to the ear:

- `Pads.Arena`: the rage, the hold of the lap, the second of warning,
  the wave behind the boss, the parade lap of the hunter. A conductor is
  a boss that flies, and a boss needs the textures of its disc.
- `CornerTurned` and `PairDocked`: a tick each, voiced by the game.
- The picture of a pad going into the depth.

## Outside the suite

- What an orb strikes and what that costs lives in `Moon2D.dpr`
  (`ResolveOrbHits`) and is tried in a live run. The orb's side of that
  contract is in the tables: when it is armed, and that a spent orb is
  gone on the next tick.
- Traces of the design stand are not used: the game has moved off the
  stand's numbers on purpose, and its dice are not the stand's.
