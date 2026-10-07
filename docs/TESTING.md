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
  Monsters\
    Tests.Monsters.pas
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
do - leave a body in a wall or hanging in the air. The rest of `TMonster` (patrol turns,
the chase, health tiers, events) is left to a later batch. The unit is
tried by `Tests\Monsters\Tests.Monsters.pas`, fixture `TMonsterTests`;
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
- The bursts are `nil`. A monster brought to zero lives fans bullets into
  its burst, so no test here kills one: blows are struck with `ALosses` 0,
  and the one test that spends a life spends a single one. `Tick` takes
  the hero at (0, 0) and a `nil` burst: the subjects never shoot.
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
- A blow that kills: the fans of fragments go into a `TBurst`, which
  needs a renderer.
- The barrel. It carries smoke; if the smoke builds without a window the
  first run will show it, and a barrel joins tests 1, 3 and 6 as a second
  subject.
- The invisible wall of a level: a solid column no art draws is art
  against collision, and the level file is judged by a live run.

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

## Outside the suite

- What an orb strikes and what that costs lives in `Moon2D.dpr`
  (`ResolveOrbHits`) and is tried in a live run. The orb's side of that
  contract is in the tables: when it is armed, and that a spent orb is
  gone on the next tick.
- Traces of the design stand are not used: the game has moved off the
  stand's numbers on purpose, and its dice are not the stand's.
