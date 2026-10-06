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
  `..\Game\Orbs`); a new folder under test is added there.
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

## Outside the suite

- What an orb strikes and what that costs lives in `Moon2D.dpr`
  (`ResolveOrbHits`) and is tried in a live run. The orb's side of that
  contract is in the tables: when it is armed, and that a spent orb is
  gone on the next tick.
- Traces of the design stand are not used: the game has moved off the
  stand's numbers on purpose, and its dice are not the stand's.
