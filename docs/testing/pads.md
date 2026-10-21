# Tests of the pads

Tables of the tests, one section per unit under test: the test's name,
what holds, the breakage. The rules and the conveyor are in
`../TESTING.md`; a new unit's table goes into the file of its namespace.

## Pads.Plunge

State: written, 14 tests, green on the first run. Needs no stage:
`TPlungeCycle` is a record that counts. The expectations were checked on
a Python port of the cycle. The unit is tried by
`Tests\Pads\Tests.Pads.Plunge.pas`, fixture `TPlungeCycleTests`;
`..\Game\Pads` is on the search path already.

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

### A pad that stays down (3.0.58)

State: written, 1 test. It came with 5.2, after the run of 5.1 asked for
a broken carousel pad that does not come back (`"staysDown"`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestPadThatStaysDownNeverClimbs` | a plunge with `StaysDown`, trodden and let fall: on each of the 600 ticks after it is `ppFallen`, `Below` the reach | the flag is ignored: a broken carousel pad climbs back into a carousel that is not there |

## Pads.Shelf

State: written, 12 tests, green on the first run (343 in the suite).
Needs no stage: `TShelfCycle` is a
record that counts, built from a `TPadShelf` the test fills by hand
(`Levels.Pads` is in the interface). The expectations were checked on a
Python mirror of the cycle: every test is green on it, and under each of
13 edits made to the mirror (the slides swapped, the offset dropped, the
offset in seconds, the wrap folded by truncation, no least tick, the ease
reversed, a floor while sliding out, a warning from any phase, from the
start of the stand, one tick short, a latch on every tick, a latch at the
end of the stand, the slide back to the first step left out) at least one
test is red. The unit is tried by `Tests\Pads\Tests.Pads.Shelf.pas`,
fixture `TShelfCycleTests`; `Tests.Pads.Plunge.pas` is the sample.

Shared in the unit:

- `ShelfOf(ASteps, ASlide, AWarn, AOffset)` - a `TPadShelf` with `Slides`
  True, the steps as (stand, seconds) pairs, the rest in seconds; `CycleOf`
  builds a `TShelfCycle` from it.
- "The base shelf": out 5 s, in 2 s, slide 1 s, warn 3 s, offset 0. At
  33 ticks a second a lap is 297 ticks: out on ticks 0 to 164, going in on
  165 to 197, in the wall on 198 to 263, going out on 264 to 296, out
  again from 297.
- Every number of a test is in whole seconds, or in hundredths that round
  without a half: `Round` of Delphi rounds a half to the even tick (82.5
  ticks is 82), so a test never spells seconds that land on a half tick.
- A tick is counted from 0. The game asks `Latches` from tick 1 on (the
  clock is raised first), so the tests that count latches count from tick
  1; `Latches(0)` is not a question the game asks and no test pins it.

Numbers spelled, as decided: 33 ticks a second; the order of a lap (a
step, the slide to the next, the last back to the first); the floor and
the body only while out all the way, from the first tick of the slide in to
the first tick out again none. Not spelled: the numbers of the shelf in
`level2.json`, the defaults of the parser.

| Test | Holds | Turns red when |
|---|---|---|
| `TestPadThatIsNoShelfNeverLeavesTheFront` | a `Default(TPadShelf)`: `Slides` False; over a thousand ticks it holds on every one, never warns, never latches, and its depth is 0 at every tick and between ticks | a pad with no shelf word gets a program: every ordinary pad of the game slides |
| `TestProgramGoesRoundAndRepeats` | the base shelf from tick 0: out for 165 ticks, going in for 33, in the wall for 66, going out for 33; the same again a lap on and seven laps on | a span is lost or out of order; the slides in and out are swapped; the slide back to the first step is left out |
| `TestShelfHoldsOnlyWhileOutAllTheWay` | it holds on exactly the ticks it is out (165 a lap) and on no other; on the first tick of the slide in it does not, on the last of the slide out it does not, on the first tick out it does | a floor while sliding: the hero stands on a shelf that has begun to leave, or is caught by one that is not yet out |
| `TestWarningLastsItsTicksAtTheEndOfTheStand` | warn 3 s: it warns on exactly 99 ticks of a lap, those just before the slide in, every one of them a holding tick; never in the slide or in the wall. Warn 0: never. A warning longer than the stand (9 s over 5): it lights on holding ticks only, and on some | the warning is counted from the start of the stand, a tick short or long, or lit through the slide: the lamp of the dock lies about when the floor goes |
| `TestLatchComesOnceWhenTheShelfIsOut` | from tick 1, over three laps: exactly three latches, each on a holding tick whose tick before was the slide out. A program of two outs (out, in, out, in): two a lap | the latch sounds on every tick of the stand, at the end of it, or in the slide: the sound loops or comes late |
| `TestDepthRisesEvenlyOnTheWayInAndFallsOnTheWayOut` | 0 on every tick out; on the slide in: 0 on its first tick, then rising by equal steps, 1 on the first tick in the wall and on every tick of it; on the slide out: 1 on its first tick, then falling, 0 on the first tick out; between two ticks the depth lies between the depths of the two ticks | the ease is reversed (the picture goes out when it should go in), the pace is uneven, or the depth leaves 0 to 1 |
| `TestOffsetStartsTheProgramFurtherIn` | offset 2 s: at every tick of two laps phase, warning and depth (also half a tick on) are those of the unshifted shelf 66 ticks on; offset 13 s (more than a lap, 132 ticks over it): those of the unshifted shelf 132 ticks on | the offset is dropped, or taken in ticks, not seconds: a row of shelves goes in step, not as a wave |
| `TestStepsOfAProgramRunInOrder` | out 1 s, in 2 s, out 3 s, in 4 s, slide 1 s: 33 out, 33 going in, 66 in, 33 going out, 99 out, 33 going in, 132 in, 33 going out, and again | steps are merged or reordered, or the slide between two steps is skipped |
| `TestProgramMayStartInTheWall` | in 1 s, out 2 s, slide 1 s: tick 0 is in the wall (no floor, depth 1); going out from 33; out from 66; the latch on tick 66 and not on 65 | the first step is taken for out whatever it says; the latch is a tick off |
| `TestStepAndSlideShorterThanATickTakeATick` | slide 0 s: a lap has exactly one tick of the slide in and one of the slide out; a step of 0.01 s holds for one tick | the least of one tick is lost: the shelf jumps from out to in with no tick of slide between |
| `TestCycleIsAFunctionOfTheTickAlone` | the base shelf asked for ticks 500, 3, 296, 0, 500, 165, 164, 1000, 3, 297, 298 and then again in the reverse order: the same phase, floor, warning, latch and depth at every tick | the cycle keeps a cursor, a clock or a cache: a hero leaving the screen, or a restart, finds the shelf out of step (not on the mirror - it has no such edit to make) |
| `TestTimeBeforeTheStartIsTheEndOfTheLap` | the pad draws at its clock less one and a share, which after a restart is before the start: the depth at -x equals the depth at a lap less x, for x of 0.25, 0.5, 1, 1.75, 5, 33 and 40.5, and lies in 0 to 1; the phase at -1 is the last slide of the lap | the lap is folded by truncation and not by floor: right after a restart the picture pops or the depth goes below 0 |

Left to the eye: how the slide looks (the sink, the scale, the tone are
the world's and `Draw`'s), and that an even pace in the cycle reads as an
even slide once the world has smoothed it.

Left to the eye and to the ear, for the shelf as a whole:

- The look of the slide (`Draw`: the sink, the scale, the tone), the dock
  art and the lamp's blinking, that the dock's planks are not read as a
  deck, the jump window (jumping from the crates while the shelf is in or
  just out is a trap for the late; if the live run calls it a cheat, the
  stand gets longer).
- The latch's sound as heard: `ShelfLatchSoundFile` and the call that plays
  it live in `Moon2D.dpr` and are tried in a live run. The unit's side is
  the table (once per lap, on the tick it is out, only on the hero's
  screen).
- `LocateParent` of the dock's lamp to the shelf: a wrong tag stops the
  level's load at once.

Open, found while the tests were designed:

- `Latches(0)` is True for a program that starts out: the game never asks
  tick 0, and no test pins it.
- A warning longer than the stand lights the whole stand, the latch tick
  too. The design says nothing; the test only asks that a warning is on
  holding ticks.
- A negative `sink` loads and lifts the picture. Not tried, not decided.
- A shelf over a shaft with a wall at its bottom loads, a plunging pad does
  not. Not decided, so not tried.
- A blow of the boss against a shelf in front knocks it a cell as any pad
  (a shelf in the wall is not struck). No boss stands on a screen with a
  shelf; not decided for a shelf, not tried.
- The judge of a formation (`StillSpans`) counts any pad of the screen that
  is in no group as a foothold, a shelf too. No shelf stands near a group.

## Pads.Stray

State: written, 16 tests. Needs no stage: `TStrayCycle` is a record that
counts, built from a `TPadStray` the test fills by hand. Eleven came with
5.2 (3.0.58); the cycle was run tick by tick in a port of it, against
these tests, before it was handed over, and stage 5 passed its live run.
The five of a pad sent away came with what was added to 6.1 (3.0.59).
The unit is tried by `Tests\Pads\Tests.Pads.Stray.pas`, fixture
`TStrayCycleTests`; `Tests.Pads.Plunge.pas` is the sample.

Shared in the unit:

- `StrayOf(AWait)` - a pad of flock "flock" that strays in the zone of
  the arena, columns 2 to 13 and rows 3 to 8; `CycleOf` rewinds a cycle
  of a pad 32 wide asleep at (-96, -64); `LaunchedCycle(ASeed)` is one
  with no wait, let go at once.
- "Over the seeds" is twelve seeds; "a long run" is 6000 ticks, long
  enough for a pad to come, hang, leave and fall a few times.
- "Out of sight" is the pad wholly past the left or the right edge, or
  above the top. "The room" is the screen less a cell at the left, the
  right and the top.
- A test that asks that something happens at all (a hang, a fall, a ride,
  a return) also asks that it was seen on some seed.

Numbers spelled, as decided: 33 ticks a second; the room; a hang on a
whole cell of the zone; half a second of shaking before a fall, a tick
either way; the jets at half for a pad sent away. Bounds of the tests'
own, loose: a dip under 10 units, a lean under 20 degrees. Not spelled:
the odds of a misbehaviour, the times of a hang and of a wait, the pace
of a leg.

| Test | Holds | Turns red when |
|---|---|---|
| `TestAsleepUntilLetGo` | 300 ticks, never let go: `spAsleep`, where it was put, no deck | a stray comes in before its flock is let go |
| `TestWaitsItsWaitThenFliesInFromBeyondAnEdge` | over the seeds, a wait of 1 s: `spWaiting` on each of its first 32 ticks; on the 33rd `spFlying`, leg `slIn`, out of sight and no deck | the wait is taken in ticks or skipped, or a pad sets off from inside the screen |
| `TestLetGoOnceOnly` | two cycles of one seed, one let go again with another seed on tick 100: the same place on every tick of a long run | a second letting go rolls the dice anew or restarts the wait |
| `TestHangsOnlyAtPointsOfItsZone` | over the seeds, every tick of `spHanging`: the pad stands on whole cells, its column 2 to 13 and its row 3 to 8; some pad hangs | a pad hangs between cells, or outside its zone |
| `TestDeckOnlyInsideTheRoom` | over the seeds, on every tick it is a deck it is inside the room; it is a deck on some ticks and flies with no deck on others | a pad out past a wall is a floor: a rider is carried off the screen |
| `TestHeroAboardNeverLeavesTheRoom` | over the seeds, the hero aboard whenever it is a deck: while it flies, hangs or shakes it stays a deck, and it never flies a leg out; some ride happens | a pad flies the hero out of the room, or turns a leg out into one with him on it |
| `TestEmptyPadComesAndGoes` | over the seeds, empty: a pad that flew a leg out is later seen flying in | a pad that left stays out for good |
| `TestShakesThenFallsOutOfTheScreenAndComesBack` | over the seeds, every shake: in one place across, 16 ticks give or take one, then `spFalling`; the fall never rises and goes past the bottom of the screen; then `spWaiting`; some pad falls | the warning is cut or long, the pad slides as it shakes, stops short of the pit, or never comes back |
| `TestTwitchStaysWithinBounds` | over the seeds, every tick: `Dip` under 10 units and `Lean` under 20 degrees; some lean over a degree | the twitch runs away, or is lost |
| `TestJetsFollowThePhase` | asleep and waiting: `Effort` 0. Then over a long run: flying and shaking - only 0 or 1; waiting and falling - 0; hanging - within 0 to 1 | the jets burn out of sight or in the fall, or idle at half on a leg |
| `TestDiceAreTheSeedsAlone` | two cycles of one seed: the same place on every tick; a cycle of another seed differs on some tick | the cycle reaches for `Random`, or the three pads of the flock fly in step |
| `TestSentAwayFromAHangLeavesQuietlyAndStaysOut` | over the seeds, `Dismiss` at a hang: `Dismissed`; on the next tick `spFlying`, leg `slOut`; then for a long run never shaking or falling, never on a leg `slBack`, the jets never over half; it ends asleep out of sight | a pad sent away misbehaves on its way out, flies at full jets, or comes back in |
| `TestSentAwayWaitsForTheHeroToGetOff` | over the seeds, `Dismiss` at a hang with the hero aboard for 500 ticks: hanging and a deck on every one; then empty, it leaves as above | a pad sent away flies off with the hero on it, out of the room |
| `TestSentAwayWhileWaitingNeverComesIn` | a wait of 1 s, let go and sent away at once: `spAsleep` at once and after a long run; let go again: still asleep | a pad sent away before it came in flies in after the victory, or a later letting go wakes it |
| `TestSentAwayWhileFallingDoesNotComeBack` | over the seeds, `Dismiss` while it shakes: after a long run `spAsleep`; some pad shook | the fall runs out and the pad flies in again after the victory |
| `TestAsleepPadIsNotSentAwayAndARewindForgets` | `Dismiss` on a pad asleep: not `Dismissed`, and it is let go as ever; `Dismiss`, then `Rewind`: not `Dismissed`, and let go again it flies | a dismissal before the flock is let go keeps it away for good, or a restart keeps the strays away |

Left to the eye: how a stall, a turn back and a twitch look; the rigs,
the lamps and the jets as drawn; what `Pads.World` makes of the cycle -
the riders carried, a pad `Behind` out of the room, a gravel that rides
one out and falls - needs the stage.

## Levels.Pads

State: written, green (343 in the suite); the tests of the shelf, below,
green on the first run. Needs no stage. The unit is tried by
`Tests\Levels\Tests.Levels.Pads.pas`, fixture `TLevelPadsTests`, through
`TLevel.LoadFromFile`: the parser (`Levels.Pads`) and the checks at load
(`Levels.Defs`) are one door from outside - a level that loads, its `Pads`
to read, or an exception: `EPadError` from the parser, `ELevelError` from
the checks.

Shared setup: `Tests.Rooms` gains `LevelFromRows(ARows, ASections)` - the
level of a room with `ASections`, JSON members such as `"pads": [...]`
and `"respawns": [...]`, added to its root; no pad world and no registry,
the caller frees it. A pad of a test names a sprite (any name: the level
does not open art), screen 1, x, y and width 32 unless said otherwise.
The room is "open" unless a wall is named.

Only the pads and the respawn points are tried here. The checks of a pad
group belong to the arena, tried by nobody yet.

The tests of a plunge and of a respawn stand in "gap", as in `Pads.World`:
a pad that plunges needs an open shaft under it. A pad group takes 5 to 60
pads, so a plunging pad in a group comes with four mates inside the zone;
in a group of one the level raises for its size, and the test could not
tell that from the plunge. Each such test loads the same pads without the
plunge first.

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

### The shelf (3.0.51)

State: written, 12 tests and one line, green on the first run (343 in
the suite). Needs no stage. The
tests join `TLevelPadsTests` (`Tests\Levels\Tests.Levels.Pads.pas`),
through `TLevel.LoadFromFile` as the others. One line is added to an
existing test, and twelve tests are new.

Shared: `ShelfPad(AMembers)` - a pad of the gap room, `PadJson(GapX,
LedgeTopY, '"shelf":{' + AMembers + '}')`; the checks of a shelf are tried
in the gap, as the plunge's are, and each test that expects a raise loads
the same pads without the fault first, so the raise is the shelf's and not
another check's.

Edit to an existing test: `TestPadReadsItsPlaceAndDefaults` gains one
line, `Shelf.Slides` False. It turns red when a pad with no shelf word
reads as a shelf.

| Test | Holds | Turns red when |
|---|---|---|
| `TestBareShelfComesToItsDefaults` | `"shelf":{}`: it slides; two steps, out then in, each above 0 seconds; the slide above 0; the warning not below 0 and shorter than the out step; the offset 0; the sink 0; the scale above 0 and at most 1; the tone from 0 to 1. The defaults themselves are not spelled: they are tuned by eye | an empty word is no shelf, a default leaves a program that cannot turn, or a scale of 0 (a picture of no size) |
| `TestShelfReadsWhatItIsGiven` | out 3, in 2, slide 0.5, warn 1, offset 4, sink 9, scale 0.5, tone 0.2: the steps are out 3 then in 2, and each other number is in its own field | two members are swapped on the way in: out and in, slide and warn, or sink, scale and tone |
| `TestShelfProgramIsReadInOrder` | a program of in 1, out 2, in 3, out 4 gives four steps in this order, each with its stand and seconds as written | the steps are reversed or reordered, or the first is forced to out |
| `TestShelfStepWordsAreReadInAnyCase` | `["Out", 1]` and `["IN", 2]` load as out then in | the words are compared case-sensitively |
| `TestShelfProgramBesideOutOrInRaises` | a program with `"out"`, and a program with `"in"`, each raises `EPadError`; the program alone and `"out"` with `"in"` alone load | both ways of writing a shelf are given and one quietly wins |
| `TestBadShelfStepRaises` | each alone raises `EPadError`: `["out"]`, `["out", 1, 2]`, `["sideways", 1]`, `[1, 1]`, `["out", "1"]`, `["out", true]`, a step that is the bare word `"out"`, a step of 0 seconds, a step of -1, `"out": 0`, `"in": -1` | a typo in a program loads: the shelf stands in front for ever, or for a time nobody wrote |
| `TestShelfStepsMustTakeTurns` | each alone raises `EPadError`: an empty program; one step; out, out; out, in, out (the last meets the first). In, out and out, in, out, in load | two outs on end load (the slide between them has no direction), or the last step is not asked against the first: the level fails to load, or loads and the shelf never moves |
| `TestBadShelfNumbersRaise` | each alone raises `EPadError`: slide -1, warn -1, offset -1, scale 0, scale 1.01, scale -0.5, tone -0.1, tone 1.1. Slide 0, warn 0, offset 0, scale 1, tone 0 and tone 1 load | a scale of 0 loads (a picture of no size), a tone over 1 loads (a shelf brighter than a pad in front), or a number below 0 loads |
| `TestShelfMayNotPlungeOrJoinAGroup` | the gap, a shelf alone loads; the same pad with `"plunge":{}` raises `ELevelError`; the same shelf joining a group of five (as `GroupOfFive`, its zone given) raises `ELevelError` while the group of five without the shelf loads | the check is dropped: a plunge would drop the deck the shelf has just slid out, a rebuild would fly a pad that is in the wall |
| `TestShelfMayTravelAPath` | a shelf with a ping-pong path to a stop 64 units up loads, as the same path without the shelf does | the shelf is held to its place as a plunging pad is: the decision "a path is allowed" is lost |
| `TestRespawnOverAShelfRaises` | the gap, a respawn point over a still pad: loads; over a shelf: `ELevelError` | a shelf counts as a floor that stays: the hero is reborn over a pad that is in the wall half of every lap and falls into the pit he came from |
| `TestLevelTwoShelfIsInItsFile` | `level2.json` beside the executable loads (as `monsters.json` is found in `Tests.Rooms`); the pad tagged `s07-shelf-01` is on screen 7, slides, is in no group and does not plunge; its warning is shorter than every step that stands out | the word of the level file is renamed or its program stops turning (the level then fails to load at its first screen), or the shelf drops out of the pit. If loading the real level needs a renderer the first run says so, and this one test waits for the stage |

Left to the eye: that the dock's lamp and the shelf's picture sit right
(`s07-shelf-dock`, tint, the unit under the floor line).

### The carousel (3.0.52)

State: written, 13 tests and one line, green on the first run (376 in
the suite). Needs no stage. The
tests join `TLevelPadsTests`, through `TLevel.LoadFromFile` as the others:
what the level makes of a `carousels` section beside its pads, and of an
entity that sits on a pad (`"seat"`), which leans on the pads as a respawn
point does. The track and the orbit themselves are tried in
`Levels.Carousels`, below.

Shared: "the wheel" - `WheelJson`, a circle of 80 round (256, 160), a lap
in 4 seconds; its decks fly from 176 to 336 across and from 80 to 240
down. `RiderJson` - a pad 32 wide on it, with no place of its own;
`WheelOfOne` - the wheel and one rider. "Sky" - a room with no solid cell
at all, where a plunge hits nothing: the tests of what a rider may not do
stand there, and load the same word on a still pad where the rider starts
first, so the raise is the carousel's. `SeatedJson(APad)` - a barrel that
sits on the pad tagged so.

Numbers spelled, as decided: the start on the right of the middle and
clockwise down; the riders a share of the lap apart in file order; the
room of a rider, a cell over its deck and a cell under it; a seated body a
cell wide, its middle over the middle of the deck. Not spelled: the
numbers of the carousel in `level2.json`, how many pads it carries.

Edit to an existing test: `TestPadReadsItsPlaceAndDefaults` gains one
line, `Carousel` empty. It turns red when a pad with no carousel word
reads as a rider.

| Test | Holds | Turns red when |
|---|---|---|
| `TestCarouselPlacesItsPadsWhereTheyStart` | the open room, the wheel and four riders: one carousel, tagged "wheel"; the riders keep its tag and are placed at (320, 160), (240, 240), (160, 160), (240, 80), in file order - the left edge of the deck and its height | the placement holds the middle of the deck, not its left edge; the riders are spaced by their index among all the pads; the start is not on the right or the way is not down |
| `TestCarouselPadTakesNoPlaceOfItsOwn` | a rider loads with no x and no y; with an x it raises `EPadError`, with a y it raises too | a rider takes a place the carousel then quietly overrides, and the file lies about where the pad is |
| `TestCarouselAndItsPadsMustMatch` | the wheel and its rider load; each alone raises `ELevelError`: a second rider of "whel" beside the first, a carousel that carries no pad (a still pad beside it), two carousels tagged "wheel", a carousel on screen 2 of a level of one | a typo of a tag loads: a pad stands at (0, 0) or a carousel turns with nothing on it |
| `TestCarouselPadDoesNothingElse` | sky: the rider alone loads, and a still pad where it starts loads with a path, with a plunge and as a shelf; the rider with a path, with a plunge, as a shelf, in a group (its zone given) each raises `ELevelError` | the check is dropped: two motions fight over one pad, its riders jump between them |
| `TestCarouselKeepsARoomClearOfWalls` | the open room: a ledge on row 1 over the top of the wheel loads, on row 2 raises; a ledge on row 10 under its bottom loads, on row 9 raises; a wall on column 6, in the way of its left side, raises - all `ELevelError` | the room over the deck is dropped (a betoner rides through the ceiling), the room under it is dropped (the body cuts a wall), or only the start is checked and not the lap |
| `TestCarouselStaysOnTheScreen` | the wheel round (256, 112), its top deck at 32 and its room up to the edge: loads; round (256, 100): raises; round (460, 160), its right deck past the edge: raises | a rider flies off the hero's screen with what stands on it |
| `TestCarouselPadsMayNotCutIntoEachOther` | two riders on the wheel load; two on a circle of 10 (half a lap apart, their bodies through one another) raise `ELevelError` | the check of the pairs is dropped: two decks pass through one another and the barrels on them too |
| `TestRespawnOverACarouselPadRaises` | sky, a respawn point on column 11, row 4: over a still pad at (320, 160) it loads; over the rider placed there it raises `ELevelError` | a rider counts as a floor that stays because its placement says it is there: the hero is reborn over a pad that has flown off |
| `TestEntitySitsOnTheMiddleOfItsPad` | a pad 64 wide at (100, 160), tagged "bench", and a barrel on it: `Seat` "bench", `SeatLeft` 116, `SeatFeet` 160, its cell 5 and 5 (the nearest); a barrel beside it with no seat keeps column 12 and row 3, `Seat` empty | the body is set by its left edge on the left of the deck, or by its middle on the left edge; the cell is not put and the triggers of the placement count from (0, 0) |
| `TestEntityOnACarouselSitsOnTheStartItself` | the wheel round (256.4, 160.3) and a rider tagged "ride": the rider is placed at (320, 160), the barrel on it sits from 320.4 with its feet on 160.3 | the seat is taken from the rounded placement: the betoner hangs a few tenths off its deck all the way round |
| `TestSeatedEntityTakesNoCell` | an entity on "bench" loads; with an x it raises `ELevelError`, with a y too | a seated entity takes a cell the seat then overrides |
| `TestSeatOnAnUnknownPadRaises` | a seat on "bnech" raises `ELevelError` | a typo of a seat loads: the barrel stands at (0, 0) |
| `TestLevelTwoCarouselIsInItsFile` | `level2.json` loads; it holds `s08-carousel` on screen 8, turning clockwise; it carries more than two pads; each of them has exactly one entity seated on it; two are betoners and the rest barrels | the hall of screen 8 loses a seat or a word, a pad of the carousel flies empty, or a betoner turns into a barrel |

Left to the eye: that the riders fly round in the game - the world flies
them by the orbit (`Pads.World`, which needs the stage) and the riders go
with them as with any path; that a seated monster is put on the seat and
not on its cell (`Monsters`, which needs a pad world with a carousel); the
picture of the hall and its rigs.

### The arena of act 4 (3.0.57)

State: written, 6 tests. Needs no stage. They join `TLevelPadsTests`, as
the others. Five came with 4.3, whose build was run live; the pyramid's
came with the fixes after that run. Four of the six load
`level2.json` beside the executable (`UseLevelTwo`).

Shared: `BankColumns(Level, Screen, Bank)` - the columns of the shelves
of a bank on a screen, in file order. The shelf of a test stands in the
gap, as before (`ShelfPad`).

Numbers spelled, as decided, from `level2.json`: the arena carousel
`s09-carousel` on screen 9, a box, parked, two medkits on it half a lap
apart; the floor of act 4, `s09-grid` on columns 4, 6, 8, 10 and 14 and
`s09-gaps` on 5 and 11, all of them in `s09-floor`; the pyramid
`s09-pyramid` sleeps once, sparing the hero. Not spelled: how many pads
the arena carousel carries, its size and period.

| Test | Holds | Turns red when |
|---|---|---|
| `TestShelfStandsInEveryBankItIsGiven` | `"bank":"floor"`: in "floor" and not in "grid"; `"bank":["floor","grid"]`: two banks, in both, not in "isle"; no bank word: in no bank | a list of banks is read as its first, or a shelf with no word lands in some bank |
| `TestBadShelfBankRaises` | each alone raises `EPadError`: `""`, `5`, `{}`, `["floor",3]`, `["floor",""]` | a typo of a bank loads: the shelf never hears its act |
| `TestEntityOnAParkedCarouselWaitsOverThePark` | the wheel parked above, a barrel on its rider: it sits from 320, over the rider's slot, with its feet on the parked deck, y = -64 | the seat is taken from the slot on the screen: the medkit hangs in the air over the room while its pad waits above the screen |
| `TestLevelTwoArenaCarouselIsInItsFile` | `s09-carousel` is on screen 9, a box, parked; it carries two pads or more; exactly two entities sit on its pads, both medkits, half the riders apart in file order | the carousel loses its park or its seats, or the medkits ride side by side |
| `TestLevelTwoArenaFloorOfActFourIsOneThroughOne` | on screen 9 `s09-grid` is columns 4 6 8 10 14 and `s09-gaps` is 5 11; every shelf of either is also in `s09-floor` | the floor of act 4 is laid otherwise, or a shelf of it is left out of the floor act 3 takes away |
| `TestLevelTwoArenaPyramidSparesTheHero` | of the `shelvesSleep` actions: `s09-pyramid` once, sparing the hero; `s09-floor` twice (once when it was written; act 5 added the second, see below), never sparing him | the pyramid goes from under the hero's feet, or the floor waits for him |

### The arena of act 5 (3.0.58)

State: written, 9 tests and two edits. Needs no stage. They came with
5.1 and 5.2; stage 5 was run live. Three of the nine load `level2.json`.

Shared: `StrayPad(Zone, Extra)` - a pad of the gap room, 32 wide, that
strays in flock "flock" in the zone given as [left, top, right, bottom]
in cells, counted from 0, with no place of its own. The gap's shaft is
column 8 counted so, open from the top to the bottom; zone [8,2,8,7] is
a zone down it.

Numbers spelled, as decided: a pad that strays waits at x = -96, y = -64,
out of sight, and with no wait word waits 0; its room is the screen less
a cell at the left, the right and the top. From `level2.json`: the arena
carousel breaks once, in act 5, into pads that plunge and stay down; in
act 5 the floor sleeps whole, then a pick of it wakes; the flock
`s09-strays` is on screen 9 and is let go once, in act 5. Not spelled:
how many floor shelves wake, how many pads stray.

Edit to an existing test: `TestPlungeReadsItsNumbers` gains `StaysDown`
False when the word is left out, and True for `"staysDown":true`. It
turns red when a pad climbs home whatever the file says, or every pad
stays down. `TestLevelTwoArenaPyramidSparesTheHero` now asks the floor
to sleep twice, not once: act 5 puts it to sleep too.

| Test | Holds | Turns red when |
|---|---|---|
| `TestLevelTwoArenaCarouselBreaksInActFive` | `s09-carousel` may break, its failing look plunges and stays down; one `breakCarousel` of it, in act 5; on every pad of it some object of the level hangs on `FailingRigTag` of the pad's tag | the carousel never breaks, breaks in another act, a broken pad climbs back, or a pad wears no failing look |
| `TestLevelTwoArenaFloorOfActFiveComesBackInPieces` | of the act 5 actions on `s09-floor`: one sleep of the whole floor (pick 0), before one wake that picks more than none and fewer than all its shelves | the floor of act 5 comes back whole, not at all, or the wake comes before the sleep and is taken back by it |
| `TestStrayReadsWhatItIsGiven` | flock "birds", zone [8,2,8,7], wait 1.5: it strays, each number in its own field; it is placed at (-96, -64); with no wait word the wait is 0; a pad with no stray word does not stray | a member is swapped on the way in, the pad waits on the screen, or every pad strays |
| `TestBadStrayRaises` | each alone raises `EPadError`: a stray given an x and a y, no flock, a zone of three numbers, a wait of -1 | a stray with a place the cycle then overrides loads, or a typo loads |
| `TestStrayDoesNothingElse` | a stray alone loads; with a plunge, and with a path, it raises `ELevelError` | two motions fight over one pad |
| `TestStrayZoneStaysInItsRoom` | each raises `ELevelError`: a zone in the left wall (left 0), in the top row (top 0), one whose pad reaches into the right wall (right 15), one upside down, one past the bottom (row 12) | a pad hangs in a wall or off the screen |
| `TestStrayRowsAndColumnsAreClearOfWalls` | each raises `ELevelError`: a zone from column 7 (it falls onto the ledge), one down to row 9 (it runs into the floor), the zone of the shaft with the shaft plugged at its bottom | a pad flies in through a wall, or falls into one |
| `TestStraysOfAnUnknownFlockRaise` | a `strays` action of "flock" loads; of "nobody" it raises `ELevelError` | a typo of a flock loads: the act comes and no pad strays |
| `TestLevelTwoArenaStraysAreLetGoInActFive` | some pad strays in `s09-strays`, every one of them on screen 9; one `strays` action lets the flock go, in act 5 | the flock is let go in another act, twice, or strays off the arena |

Left to the eye: what the world makes of a bank told to sleep or wake, a
broken carousel and a flock let go - `Pads.World`, which needs the stage.

## Levels.Carousels

State: written, 20 tests, green (376 in the suite) after one red that
was the test's own (a key given twice, above). Needs no stage: the track and the
orbit are records that count, built from a `TCarousel` the test fills by
hand, and `ParseCarousels` takes a JSON root the test makes. The unit is
tried by `Tests\Levels\Tests.Levels.Carousels.pas`, fixtures
`TCarouselTrackTests`, `TCarouselOrbitTests` and `TLevelsCarouselsTests`
(the free functions). The expectations were computed on a Python mirror of
the track and the orbit; `Tests.Pads.Shelf.pas` is the sample.

Shared:

- `CarouselOf(Shape, CenterX, CenterY, Width, Height, Corner)` - a
  carousel tagged "wheel" on screen 1, a lap in 4 seconds, clockwise,
  start 0; `TrackOf` and `OrbitOfSlot` build from it.
- "The circle" (`CircleOf`) - an oval of 160 by 160 round (256, 160): a
  lap of 132 ticks, a quarter in 33.
- A place is compared within 0.01: the points of the track are `Single`.

Numbers spelled, as decided: 33 ticks a second; the start on the right of
the middle, clockwise down the screen; one even pace along the track, not
along the angle; a pad a share of the lap ahead of the one before it in
file order; the start a share of the lap the way the carousel turns; a lap
of one tick at the least; the words oval, box, cw, ccw and the defaults
oval, cw, corner 0, start 0. Not spelled: how many points make an oval or
a corner (only that the track keeps to its curve within a hair).

### TCarouselTrack

| Test | Holds | Turns red when |
|---|---|---|
| `TestOvalStartsRightOfItsMiddleAndGoesDown` | an oval of 200 by 100 round (256, 192): at 0 it is at (356, 192), a quarter round at (256, 242), half round at (156, 192), three quarters at (256, 142) | the start is on another side, or the track runs counter-clockwise on the screen (the angle taken with y up) |
| `TestOvalLiesOnItsCurve` | a hundred points along it lie on the ellipse within a thousandth; its length is Ramanujan's within a thousandth | the width is taken for the half width, or the two halves are swapped |
| `TestOvalIsWalkedAtAnEvenPace` | forty equal steps along it cover lengths on the screen within 2% of one another | the pace follows the angle: the pads bunch at the narrow ends of an oval |
| `TestBoxGoesDownItsRightSideFirst` | a box of 200 by 100 round (256, 192), corners 0: 600 long; at 0 (356, 192), 50 (356, 242), 150 (256, 242), 250 (156, 242), 350 (156, 142), 450 (256, 142), 575 (356, 167) | the box starts in a corner, runs the other way, or a side is left out |
| `TestRoundedBoxCutsItsCornersAndKeepsItsSides` | the same box with corners of 20: shorter than the sharp one by (8 - 2 Pi) * 20 within half a unit; over 2000 points it reaches 156 and 356 across and 142 and 242 down, and never within 7 units of a corner of the box | a corner is rounded outward or about the wrong middle, a side is lost, or the corner is ignored |
| `TestBoxRoundedAllTheWayIsACircle` | a square of 100 with corners of 50: every point within half a unit of 50 from the middle; at 0 (306, 192), a quarter round (256, 242) | a leg of no length (the sides of no length between the quarters) divides by zero: the pad's place is NaN |
| `TestPlaceWrapsPastALapAndBelowZero` | a box with corners of 10: any of five distances is the same place 3 and 1 laps back and 1 and 5 laps on; 25 units back from the start is (356, 167) | the lap is folded by truncation, not floor (below zero reads off the line), or a distance past a lap is not folded |

### TCarouselOrbit

| Test | Holds | Turns red when |
|---|---|---|
| `TestOrbitOfNoCarouselDoesNotRide` | a `Default(TCarouselOrbit)` does not ride; `OrbitOf` gives none to a pad with no carousel word, none to a pad of a carousel the list has not, one to a pad of the wheel | every pad of the game rides, or a misspelt rider goes round a carousel it was not given |
| `TestFirstPadStartsAtItsShareOfTheLap` | the circle, one pad: start 0 at the right; 0.25 clockwise at the bottom; 0.75 clockwise at the top; 0.25 counter-clockwise at the top | the start is counted clockwise whatever the turn, or taken from another side |
| `TestPadsShareTheLapInFileOrder` | five pads: wheel, none, other, wheel, wheel. The three of the wheel at tick 0: the right, a third round (120 degrees), two thirds round; the one of "other" at the right, the only pad of its carousel | the slot is the index among all the pads, or the count of the slots takes the pads of another carousel |
| `TestLapTakesThePeriod` | the circle of 4 seconds: at tick 33 the bottom, at 66 the left; at ticks 0, 7, 50 and 131 the place is the same a lap (132 ticks) on | the period is taken as ticks or frames, or a lap is a tick off and the riders drift from their places lap by lap |
| `TestPadMovesBetweenTicksToo` | a tick takes the pad a 132nd of the circle; half a tick takes it half of that, the other half the rest; half a tick on it is on the circle | the time is cut to whole ticks: the pad stutters on the screen, as drawn between ticks |
| `TestCounterClockwiseMirrorsClockwise` | an oval of 200 by 100, start 0.1, 3 seconds: at ticks 0, 17, 50 and 98 the pad turning counter-clockwise is the clockwise one mirrored over y = 192 | counter-clockwise runs clockwise, or its start is counted the other way |

### The free functions

| Test | Holds | Turns red when |
|---|---|---|
| `TestNoSectionIsNoCarousels` | a root with no section, and an empty section: no carousels | a level without the word fails to load |
| `TestCarouselReadsWhatItIsGiven` | tag, screen 3, box, center (288, 179), size 150 by 120, corner 10, period 12, ccw, start 0.5: each in its own field | two members are swapped on the way in |
| `TestCarouselLeftOutComesToItsDefaults` | only tag, screen, center, size and period: oval, corner 0, clockwise, start 0 | a default changes under the level files |
| `TestWordsAreReadInAnyCase` | "BOX" and "Ccw", "Oval" and "CW" read as their words | the words are compared case-sensitively |
| `TestBadCarouselRaises` | each alone raises `ECarouselError`: shape "circle", turn "left", a center of one number, of three, of a word, no center, a width of 0, a height of -1, no size, a corner of -1, a corner of 60.5 on a box of 150 by 120, a period of 0, of -1, no period, a start of -0.1, of 1. A corner of 60 with a start of 0.99 loads | a typo loads: a carousel of no size, one that never turns or divides by zero, a start a lap on |
| `TestCarouselIsFoundByItsTag` | of two, "second" is found and is the second (screen 5); "third" is not found | the first is given whatever the tag |
| `TestLapIsATickAtTheLeast` | 12 seconds: 396 ticks; a 33rd of a second: 1; a thousandth: 1 | a lap of 0 ticks: the step divides by zero |

Left to the eye: how a pad looks going round - the bob, the sag, the
lamps it wears; that the even pace reads as even in a live run.

### The parked carousel (3.0.57)

State: written, 8 tests and four edits. Needs no stage. They came with
4.2, which joined the build of 3.0.57; that build was run live. A new
fixture, `TCarouselLandingTests`; the rest join `TCarouselOrbitTests` and
`TLevelsCarouselsTests`.

Shared: `BoxPadAt(Along)` - the parked box of 200 by 100 round
(256, 192), its one pad `Along` units round the track: 25 is (356, 217)
on the right side, 575 is (356, 167) above it, 150 is (256, 242), the
middle of the bottom, and 100 and 200 lie 50 to either side of it. A
landing starts from y = -64, two cells over the screen; `SetsOffAt` is
the first tick the pad has left it.

Numbers spelled, as decided: the word `parked` takes `above` alone; a
speed-up at least 0; an even speed-up, which leaves the clock half the
speed-up behind; the deeper slot sets off sooner, every pad brakes at
once, the wave ripples out from the middle. Not spelled: the speed of a
landing and the length of its braking ("the last step is under a quarter
of the largest").

Edits to existing tests: `TestCarouselReadsWhatItIsGiven` gains
`"parked":"above"` and `"speedUp":2.5`, read into their fields;
`TestCarouselLeftOutComesToItsDefaults` gains: not parked, a speed-up of
0; `TestWordsAreReadInAnyCase` gains `"parked":"ABOVE"`;
`TestBadCarouselRaises` gains `"parked":"below"` and `"speedUp":-0.5`.
Each turns red as its table above says, for the new words.

| Test | Holds | Turns red when |
|---|---|---|
| `TestOrbitKnowsItsCarouselIsParked` | the circle: its orbit is not parked; parked, it is; a `Default(TCarouselOrbit)` is not | the orbit does not carry the park: a parked carousel turns on the screen from the start |
| `TestClockWithoutASpeedUpRunsAtItsPace` | no speed-up: `Clock` is the time itself at 0, 0.5, 1, 17 and 500 ticks | a carousel with no speed-up word starts slow |
| `TestClockSpeedsUpFromAStandstill` | a speed-up of 1 s: `Clock(0)` is 0; on each of the first 33 ticks the clock gains more than on the tick before and under a whole tick; on the next ten it gains a whole tick; at 100 it stands at 83.5 | the speed-up jerks, overshoots the pace, or never ends |
| `TestPadWaitsThenComesDownOntoItsSlot` | the pad at 575: at the fly-in its deck is on the park; it sets off after tick 1; on every tick the deck never goes up and never past the slot; it is on the slot at `Done` and fifty ticks on, and not a tick sooner | a pad rises, overshoots its slot, or the slot over the lowest deck sets off at once |
| `TestPadBrakesToAStop` | the pad at 150: once its steps begin to shrink they never grow again; the last step is under a quarter of the largest | the pad lands at full speed, or speeds up again in the braking |
| `TestShortWayIsBrakedAllTheWay` | a way of 20 units, no wait: every step is shorter than the one before, and it ends on 20. A way of nothing with a wait of 3: `Done` is 3, the deck stands where it is at 0 and at 100 | a way shorter than the braking cruises first and stops dead, or a way of nothing divides by zero |
| `TestPadsInAColumnKeepTheGapOfTheirSlots` | the pads at 25 and 575, 50 apart in one column: the lower sets off first; both land on one tick; the gap between them never shrinks and never passes 50, and is 50 once the upper has set off | the decks of one column come down out of step: a pad lands through the one under it |
| `TestWaveRipplesOutFromTheMiddle` | the pads at 150, 100 and 200: the middle sets off first and lands first; the two beside it set off on one tick | the wave runs from one side, or is lost |

### The broken carousel (3.0.58)

State: written, 7 tests and one edit. Needs no stage. They came with 5.1,
which was run live. The halts join `TCarouselOrbitTests`, the failing
look `TLevelsCarouselsTests`.

Numbers spelled, as decided: a halt starts where the clock stood, its
pace falls evenly to nothing, so the clock stands half the halt on (at
full pace) or the pace it had times half the halt; a carousel with no
failing word cannot break. Not spelled: the length of the halt in the
game.

Edit to an existing test: `TestCarouselLeftOutComesToItsDefaults` gains:
the carousel cannot break. It turns red when every carousel of the game
may break.

| Test | Holds | Turns red when |
|---|---|---|
| `TestHaltStartsWhereTheClockStood` | a speed-up of 1 s, a halt of 66 ticks begun 0, 10, 33 and 100 ticks into the turn: at its first tick the clock is where `Clock` had it | the pads jump as the carousel begins to halt |
| `TestHaltRunsDownToAStandstill` | no speed-up, a halt of 66 begun at 100: every tick of it gains less than the one before and more than nothing; 66, 67 and 566 ticks into it the clock stands at 133 | the halt stops dead, runs backward, or never stops |
| `TestHaltInTheSpeedUpBrakesFromTheSlowerPace` | a speed-up of 33 ticks, a halt of 40 begun at 16, the pace then 16/33: the clock stands at `Clock(16)` plus 16/33 of 20 | a halt in the speed-up brakes from the full pace: the pads leap forward |
| `TestHaltOfNoTicksStandsAtOnce` | a halt of 0 begun at 100: 0, 1 and 50 ticks into it the clock stands at `Clock(100)` | a halt of no ticks divides by zero |
| `TestFailingLookReadsWhatItIsGiven` | sprite "pad-out", rigs sparks and smoke, plunge 0.25, 1, 32: it may break, the sprite, the two rigs in order, each plunge number in its own field; with no rig word it wears none, and a plunge of `{}` plunges | a member is swapped on the way in, or the plunge of the look is not read as a pad's |
| `TestBadFailingLookRaises` | no sprite, and no plunge, each raise `ECarouselError`; a plunge with a rise of 0 raises `EPadError`; a rig word that is not a list raises `ERigError` | a broken pad with no picture, or one that never falls, loads |
| `TestFailingRigTagIsATagOfItsOwn` | `FailingRigTag('ride-01')` is not "ride-01", and is not the tag of "ride-02" | the failing look hangs on the pad itself and is drawn before it breaks, or two pads share one look |

Left to the eye: the fly-in, the halt and the fall of a broken pad as
the world flies them (`Pads.World`, which needs the stage); the sparks and
the smoke of the failing look.

## Levels.Entities

State: written, 3 tests, green (239 in the suite). Needs no stage. The
unit is tried by `Tests\Levels\Tests.Levels.Entities.pas`, fixture
`TLevelEntitiesTests`, through `TLevel.LoadFromFile`: the `overrides`
object of a placement and what each word of it makes in `TEntityOverrides`.

Shared setup: `LevelFromRows` takes an `"entities"` member in its sections
and then does not write the empty one of its own (a root with two would
leave the first to win). A placement of a test is one mount on screen 1,
column 12, row 3.

| Test | Holds | Turns red when |
|---|---|---|
| `TestFireOffsetIsReadAsWritten` | `"fireOffset": 22`: `HasFireOffset` and 22 | the word is read from another key, or the flag is not raised |
| `TestFireOffsetLeftOutIsNotSet` | overrides with only `direction`, and a placement with no overrides: `HasFireOffset` false | a missing word counts as offset 0 and the pair of mounts fires in step again |
| `TestOverridesLandEachInItsOwnField` | direction, speed, lives, canShoot false and fireOffset together: each in its own field | two words are swapped on the way in |

Left to the eye: what the monster makes of the offset (above, in
`Monsters.Mount`); the other members of a placement are not tried.

### A spawned body (3.0.57)

State: written, 3 tests. Needs no stage. They came with 4.3, which was
run live. They join `TLevelEntitiesTests`: what a level makes of a body
an event spawns, which has no placement - its tag and the rigs the level
hangs on that tag.

Shared: `SpawnJson(Members)` - an event of act 1 that spawns a platform
along row 2 from the left, with the members given; `LampRig` - a rig of
one beacon, "lamp".

| Test | Holds | Turns red when |
|---|---|---|
| `TestSpawnedBodyWearsTheRigsOfItsTag` | a spawn tagged "guest" wearing "lamp": its tag is "guest", it wears one rig, and one object of the level hangs on "guest" at load | the rig of a spawned platform is never hung: it comes in with no lamp |
| `TestSpawnedBodyWithoutATagWearsNoRig` | a spawn with no tag carries none and wears nothing; the same spawn wearing "lamp" raises `ERigError` | a rig with nothing to hang on loads and hangs at (0, 0) |
| `TestSpawnedBodyTakesNoTagOfAPlacement` | a mount placed with tag "guest" and a rigged spawn tagged "guest" raise `ELevelError` | a lamp hangs on whichever of the two the game finds first |

## Levels.Defs: the doors (3.0.66)

State: written, 7 tests. Needs no stage. Fixture `TLevelDoorsTests` in
`Tests\Levels\Tests.Levels.Doors.pas`, through `TLevel.LoadFromFile`:
the screens a level shuts (`"shutDoors"`, `TLevel.DoorShutOn`), the
`openDoor` action, and what the load turns down.

Shared: `PickupJson` - a medkit tagged "key" on screen 1;
`OpenOnTakingJson` - the event that waits for `allDead` on "key" and opens
the door; `ShutJson(Screens)` - the list.

| Test | Holds | Turns red when |
|---|---|---|
| `TestShutDoorIsShutOnItsScreenAlone` | `[1]` with its opening: screen 1 shut, screen 2 not | the list is not read, or shuts every screen |
| `TestLevelWithoutShutDoorsShutsNone` | no list: screen 1 not shut | a level of 2008 holds the hero at its first door |
| `TestOpenDoorIsReadAsItsAction` | the event's action is `eaOpenDoor` | the word is read as another action, or the parser turns it down |
| `TestShutDoorThatNothingOpensFailsToLoad` | `[1]` with no event to open it raises `ELevelError` | a level loads with a door shut for good - a softlock found only by playing |
| `TestOpeningOnAnOpenScreenFailsToLoad` | the opening with no list raises `ELevelError` | an event on a mistyped screen loads and opens nothing |
| `TestShutDoorOffTheLevelFailsToLoad` | `[1,2]` on a level of one screen raises `ELevelError` | a door of a screen the level has not got loads |
| `TestScreenShutTwiceFailsToLoad` | `[1,1]` raises `ELevelError` | a copied line in the list passes |

Left to the eye: the hero held at the threshold, the arrow on the opening
and the door shut again after a restart - the game's (`Moon2D.dpr`).

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

### The shelf (3.0.51)

State: designed, not written - needs the stage.

Shared: "the shelf" is a pad of sprite `shelf`, screen 1, x = 224, y =
224, width 32, bullets `block`, with the base shelf of `Pads.Shelf` (out
5 s, in 2 s, slide 1 s, warn 3 s, no sink); "a lap" is 297 ticks, "tick
N" is the room after N calls of `Pads.Tick(1)`. The shelf is out on ticks
0 to 164, goes in on 165 to 197, is in the wall on 198 to 263, goes out
on 264 to 296.

| Test | Holds | Turns red when |
|---|---|---|
| `TestShelfIsAFloorAndABodyOnlyWhileOut` | over two laps, on every tick: `DeckUnder` for feet on the deck line, `BodyAt` and `StopsBulletAt` for a point in the body, and `Bodies(1)` holding the shelf's box are all there on the ticks it is out and none on the others. A second shelf with bullets `pass`: `StopsBulletAt` never, `BodyAt` as the first | a shelf in the wall is a floor (the hero walks on air), a roof for the boss and the sparks, or a wall for a bullet |
| `TestShelfStaysOnItsLineAndDoesNotSag` | `Left` and `Top` are the file's on every tick of a lap; `Travels` False, `MotionX` 0; `Press(8)` while out: `Lift(1)` is 0 on each of the next thirty ticks, while an ordinary still pad pressed alike leaves 0 | the guard of `Press` is dropped: a landing sags a shelf bolted to its rails; or the deck wanders |
| `TestShelfWarnsWithItsEffort` | `Effort` is 1 on exactly the 99 ticks before the slide in (ticks 66 to 164) and 0 on every other tick of a lap; `Thrusting` is False throughout | the lamp lights through the slide or on other ticks, or the shelf burns jets |
| `TestShelfRigStaysInFront` | `RigDepth` is 0 at alpha 0 and 1 on every tick of a lap, while `Depth(1)` is 0 when it is out and reaches 1 in the wall | what hangs on the shelf slides into the wall with it: the lamp of the dock shrinks and goes dark behind the dock |
| `TestDepthIsContinuousFromTickToTick` | over two laps `Depth(1)` of a tick equals `Depth(0)` of the next; at alphas 0, 0.5 and 1 it lies in 0 to 1; it rises through the slide in and falls through the slide out | the share between ticks is mapped a tick off: the drawn shelf jumps at every tick it is drawn |
| `TestLatchIsToldOncePerLapAndOnlyOnTheHerosScreen` | with `Pads.Tick(1)`: `ShelfLatched` is True on exactly one tick a lap, the tick the shelf is out all the way (297, 594), and `Latched` of the pad on that tick too. With `Pads.Tick(2)` for 600 ticks: never | a shelf on a screen the hero has left latches (the sound is played in the next room), or the latch is told on every tick of the stand |
| `TestShelfOffTheHerosScreenHoldsStill` | a hundred ticks of `Pads.Tick(2)`: the shelf is as built (out, depth 0); then with `Pads.Tick(1)` it goes tick by tick as the shelf of a room that was never off the screen | the program runs on off the screen: the hero comes back to a shelf in the wall, or one that has latched meanwhile |
| `TestRewindPutsTheShelfBackOnItsProgram` | 230 ticks in (in the wall), `Rewind`: it is out, no floor is missing, depth 0, nothing latched; ticked on, it goes tick by tick as a new room's | a restart leaves the shelf in the wall (the hero is reborn with no floor) or in the middle of its lap |
| `TestDeckWithdrawnIsToldTheTickTheShelfStartsIn` | feet on the deck line, the middle over the shelf: `DeckWithdrawn` is True on exactly one tick a lap, tick 165, and `DeckCarrying` is `nil` on it; it is False for feet a unit above or below the line, a unit past either end of the span, and on screen 2; and False the tick after | told on every tick of the slide or never: the standing hero asks nothing but this and hangs in the air (the bug of the first live run); or told for a hero who is not on the shelf, and one beside it falls |
| `TestFeetFallThroughAShelfInTheWallAndLandOnOneThatIsOut` | `DeckCrossed` for feet 40 units above the line a tick ago and 40 below it now gives the shelf on the ticks it is out and `nil` on the others | feet land on a shelf in the wall, or go through one that is out |
| `TestFastestBulletCannotSkipAShelf` | a bullet falling 12 units a tick, at each of the twelve phases over the deck of an out shelf: one of its points is always in the body, by `StopsBulletAt` | the body is as shallow as the picture (11 units): a bullet is flown through between two ticks. 12 is spelled, as decided: the fastest bullet's pace |

### The dormant pad (3.0.62)

State: written, 7 tests, green on the first run (586 in the suite).
Needs no stage: the pad names no
sprite (`"sprite": ""`), so the world asks no art for it, as for a deck of
the collision grid. They are the first of `Tests\Pads\Tests.Pads.World.pas`,
fixture `TPadWorldTests`; the tests above wait for the stage and join it
then. The test wakes and flies the pad itself, as a scene would
(`Scenes.Director`, in `scenes.md`).

Shared: the open room with "the sleeper", a pad tagged `sleeper` at (96,
224) that is dormant, and a scene of the level that wakes it - the level
loads no pad that sleeps for ever. "Away" is (224, 128). Feet on a deck
are 16 units wide, 8 in from its left edge.

| Test | Holds | Turns red when |
|---|---|---|
| `TestDormantPadIsNoFloorAndNoBody` | `Dormant` and `Behind`; `DeckUnder` and `DeckCrossed` empty for feet on its line and a fall through it, `BodyAt` and `StopsBulletAt` False in its body, `Bodies(1)` empty; the same 30 ticks on. `FindTagged` finds it | the hero stands on a pad still in the hatch, or a bullet bursts on it; or the scene cannot find the pad to wake it |
| `TestWokenPadIsAFloorAndABody` | `Wake`: a floor, a body, one of the bodies of the screen, not `Behind`, where the file puts it; the same 30 ticks on | the woken pad is drawn and stood through |
| `TestFlownInNoTicksItIsThereAtOnce` | `FlyTo(away, 0)`: there before a tick, not `Flying`; `DeckCarrying` for feet on its old line is empty; there 30 ticks on | a jump is flown, or drags its riders across the screen |
| `TestFlownPadGoesStraightThereAndStays` | `FlyTo(away, 30)`: `Flying`; on every one of 90 ticks on the straight line and never further from away; there from tick 30; not `Flying` after; a floor and a body where it landed | the pad flies an L as a rebuild does, overshoots, or lands as no floor |
| `TestFlyingPadWorksItsJets` | at rest `Thrusting` False; in the flight, ticks 1 to 29, `Thrusting` and `Effort` 1; landed, `Thrusting` False | the jets of the pad of the cordon stay dark on the way down |
| `TestFlyingPadCarriesWhatStandsOnIt` | on every tick of the flight, `DeckCarrying` for feet where the deck stood a tick ago gives the pad | the tank falls through the pad that brings it down |
| `TestRewindPutsTheWokenPadBackToSleep` | woken and halfway through a flight, `Rewind(1)`: `Dormant`, not `Flying`, where the file puts it, no floor and no body | a death leaves the pad of the cordon on the dock, or in the air |

Left to the eye: the pad drawn at all only once awake, and the rigs it
wears going out while it sleeps - the parent the game finds for them
(`LocateParent` in `Moon2D.dpr`) is not alive while the pad is dormant.

## Hero.Pads

State: designed, not written - needs the stage. One of its tests is red by
design, marked in the table: it shows a fault found while the suite was
designed. Two more were red by design, the shoves off a pad; 3.0.51 fixed
them (`ShoveX` drops a hero whose deck was under him before the shove and
is not after it). The expectations were checked on a Python port of the
hero's floor physics (the oracles, the walk, the jump, the fall, the deck)
over a port of the pads; on the port the three were red and the rest
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
| `TestShovedOffAPadHeroFalls` | on the still pad, shoved: a hundred ticks on he is on the floor | `ShoveX` writes X and asks for no floor: he hangs at the deck's height until a key is pressed (red by design until 3.0.51) |
| `TestShovedOffAFerryHeroFalls` | the same on the ferry, shoved in the middle of a leg | the same, the case seen in the live run: the pad goes on, he hangs where it was (red by design until 3.0.51) |
| `TestPlungingPadTakesStandingHeroDown` | "gap", a pad with a plunge, he is put on it: for ten ticks `Y` = 288; then `DeckUnderFeet` is the pad and `Y` its `Top` on every tick until `Y` is over 450; the pad is not at rest before that | the pad falls from under him, or stops over the pit's line with him on it |
| `TestHeroWalkingAcrossIsNotTakenDown` | the same room, he walks from the left ledge to the right without a stop and stands: he is on the right ledge, within a unit of y = 288; the pad's `Top` is over 384 within two seconds | a walk across no longer makes it - the delay is shorter than the crossing -, or stepping off saves the pad |
| `TestHeroLeavesAFallingPadOnTheLedgesLine` | the same walk: at the end `Y` is 288 exactly | red by design, by the port: 288.5. The deck's first step down takes him while his middle is on its last unit, and the walk on along the ledge never puts the feet back on the line; a deck on that line would not hold them |
| `TestHeroJumpsOffAsTheFallBegins` | he stands on it until its `Top` first grows, then jumps to the right: he ends standing on the right ledge, `Y` = 288 | the first moment of the fall is too late to jump |
| `TestHeroFallenOntoAClimbingPadComesHomeAndFallsAgain` | the pad trodden with nobody on it and let climb to within 50 units of home; he is put 60 units over it: he lands on it, `DeckUnderFeet` is the pad on every tick up to y = 288, and within a second of that the pad takes him down again | a climbing pad is no floor, or one that brought the hero home holds him |

Open:

- The same hang with no pad in the room: a hero shoved off a wall's top
  while he stands hangs too, on the port. It seems to be the 2008
  behaviour - a shove wrote X and asked for no floor. The fix of 3.0.51
  covers decks only and leaves the grid as it was in 2008, so
  `TestShovedOffALedgeHeroFalls` is not written; if the grid is ever
  fixed, it joins the two.
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

### The shelf (3.0.51)

State: designed, not written - needs the stage. The shelf is the one of
`Pads.World`.

The hero is put on the shelf at its `Left` and `Top`; no key unless said.

| Test | Holds | Turns red when |
|---|---|---|
| `TestStandingHeroFallsWhenTheShelfSlidesIn` | he stands, `Y` is the deck and `DeckUnderFeet` the shelf on every tick up to 164; within two ticks of 165 he is falling; a hundred and fifty ticks on he is on the floor, standing (`Y` = 352) | a standing hero asks the floor nothing and hangs at the deck's height: the bug of the first live run |
| `TestWalkingHeroFallsTheWayHeWalks` | a shelf 96 wide at x = 192 with the program out 1 s, in 10 s, slide 1 s, no warning; he walks right from its left end and is mid-deck when the slide begins: he falls, and his `X` goes on growing; the same to the left from the right end | the walking case of `LoseDeck` is lost: he stops in the air, or drops straight down with the key held |
| `TestFootOnTheGridFloorHoldsHeroWhenTheShelfGoes` | "gap", the shelf in the gap (x = 256, y = 288), flush with the ledges; he stands with his middle over the shelf and a foot over the left ledge (left edge at 244, as read from `GroundUnderFeet`; the first run confirms the place): `Y` is 288 on every tick of two laps, he never falls | the loss of a deck drops a hero who has the grid's floor under a foot: he walks off a ledge he is standing on |
| `TestWarningDoesNotDropTheHero` | on the shelf through ticks 66 to 164 (the warning): `Y` the deck and `Action` standing on every one | the warning is taken for a withdrawal: the hero falls three seconds early |
| `TestDownDropsThroughAShelfThatIsOut` | `hcDrop` on the shelf while it is out: he ends on the floor (`Y` = 352) | the shelf holds the drop: S on a shelf does nothing |
| `TestCorpseOnAShelfFallsWhenItSlidesIn` | `Kill` on the shelf: the corpse lies on the deck through the stand; a hundred and fifty ticks after the slide in begins `Y` = 352 | the corpse hangs over the pit the shelf left (the corpse is not asked for a floor again) |

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

### A straight flight (3.0.62)

State: written, 4 tests, green on the first run (586 in the suite).
Needs no stage. They are the first
of `Tests\Pads\Tests.Pads.Flights.pas`, fixture `TPadFlightsTests`; the
tests of the plan above join them when they are written. A scene flies a
single pad on one leg (`StraightFlight`), at `CalmPace`, its time
stretched over the ticks the scene gives.

Shared: "the flight" is the pad of the cordon's, from (320, 118) down to
(320, 256), over 66 ticks; "the slanted one" goes from (320, 118) to
(224, 200).

| Test | Holds | Turns red when |
|---|---|---|
| `TestStraightFlightGoesFromWhereItIsToWhereItIsSent` | over 66 ticks and over 132: at tick 0 where it set off; a tick before the end still on the way; from the last tick on, for 50 more, where it was sent; `Arrive` and `Done` the ticks | the flight ignores the ticks the scene gives it, ends early or never ends |
| `TestStraightFlightKeepsToTheLine` | the slanted one: on every tick on the straight line between its ends, and never further from where it goes | a scene's flight turns a corner as a rebuild's does |
| `TestStraightFlightSetsOffAndStopsGently` | the first step and the last are under the mean and under the largest; halfway in time it is within a unit of halfway | the pad leaves the hatch at full speed and slams into the dock |
| `TestStraightFlightStaysInFront` | not `Deep`, not `Idle`, `Depart` 0; on every tick to 50 past its end never `Behind`, no corner, depth 0 | the pad goes into the depth on its way down, where it is no floor for the tank |

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

## Pads.Flights: the eased flight (3.0.67)

State: written, 1 test. Needs no stage. It joins `TPadFlightsTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestEasedFlightRunsPastItsPlaceAndLandsOnIt` | `EasedFlight` by `back` from 384 up to 256 over 66 ticks: it goes above 256 by under 8 units, stands on 256 at its last tick and 50 after, and never moves aside | the step of screen 11 overshoots into a bounce, stops short, or drifts off its column |

## Levels.Entities: the shift (3.0.67)

State: written, 1 test. Needs no stage. It joins `TLevelEntitiesTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestShiftMovesTheBodyOffItsCell` | a medkit with `"shiftX": 16`: 16, its cell still 4; a mount with none: 0 | the moon stone stands a half cell off the middle of its column, or the cell itself moves |

Left to the eye: the body born 16 units right of its cell (`TMonster.Create`).
