# Tests of the effects and the dynamics

Tables of the tests, one section per unit under test: the test's name,
what holds, the breakage. The rules and the conveyor are in
`../TESTING.md`; a new unit's table goes into the file of its namespace.

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

## Effects.Traces

State: written, 19 tests, green (343 in the suite). The
expectations were checked on a Python mirror of the unit: every bound
holds over the seeds and the times the tests use, and the two traps found
there (see `SlotRoll` in the map) are each red on the mirror without
their fix. The unit is tried by `Tests\Effects\Tests.Effects.Traces.pas`, in
three fixtures: `TTraceAnswerTests` (what every shape answers),
`TTraceHeartbeatTests` and `TTraceNoiseAndBarsTests`. The unit is one
function, `TraceAt`; it knows no screen, so the whole of it is seen from
outside, and `Draw` of the graph that asks it is never called.

The sources of the tests have a frequency of 1 unless said otherwise, and
two seeds, `$1234` and `$4321`. A cycle is a second, so a time in seconds
is a number of cycles. "Looking" is sampling a cycle at 400 moments.

Numbers spelled, as decided: 24 noise slots to a cycle; a beat has a spike
over a half; the rest of a beat is exactly 0 from nine tenths of the
cycle on; a bar moves under a tenth between two ticks (33 a second) at a
frequency of 1. Not spelled: how much of a cycle a beat takes, the nodes
of the beat, how far a beat falls short of the full height (the tests ask
for at least 0.7 of it), the speed of a bar.

| Test | Holds | Turns red when |
|---|---|---|
| `TestEveryShapeStaysWithinOne` | every shape, at 0.5, 1 and 3 cycles a second, over three seeds (the lowest, a middle and the highest), at 601 moments from -4 to 8 seconds, cells 0 and 5: the answer is within -1..1 | a shape leaves its frame: the line draws outside the screen of the monitor |
| `TestSameQuestionGetsSameAnswer` | for every shape, the same time and cell asked twice give the same answer | the trace keeps a state or reaches for `Random`: a frame drawn between two ticks disagrees with the tick |
| `TestFrequencyOnlyScalesTime` | for every shape, frequency 2 at half a moment answers as frequency 1 at the moment | the frequency changes the shape, or scales the seed |
| `TestSineHighAtQuarterCycle` | 0 at the start, 1 at a quarter, 0 at a half, -1 at three quarters | the wave is shifted or its sign turned |
| `TestSquareIsHighThenLow` | 1 in the first half of a cycle, -1 in the second, 1 in the next | the halves are swapped or the cycle is off |
| `TestSawClimbsAcrossTheCycle` | -1 at the start, 0 at a half, over 0.9 just before the end, -1 at the next cycle | the saw is falling, or does not wrap |
| `TestFlatStaysOnTheBaseline` | exactly 0 at every moment from -2 seconds on | a dead monitor twitches |
| `TestHeartbeatBeatsOncePerCycle` | looking at ten cycles: the line goes up through a half exactly once in each | a beat splits in two (a bump counts as a spike) or goes missing |
| `TestHeartbeatRestsBeforeTheNextBeat` | from nine tenths of a cycle to its end the answer is exactly 0, over ten cycles | the rest is lost: the trace is a wave, not a heartbeat |
| `TestHeartbeatDipsUnderItsBaseline` | looking at ten cycles: the lowest point is under -0.05 | the dips of Q and S are lost: the beat is a bump |
| `TestBeatsStayNearTheTop` | the peaks of twenty cycles are within 0.7 and 1 | a beat is lost under the jitter, or scaled past the frame |
| `TestNoTwoBeatsAreAsHighAsEachOther` | the peaks of twenty cycles are twenty different numbers; cycles 2k and 2k+1 never share a peak | the beats roll in pairs: the monitor stutters |
| `TestOtherSeedMakesOtherBeats` | the peaks of the two seeds differ in at least 18 of 20 cycles | the seed is dropped, or two seeds roll alike |
| `TestNoiseHoldsStillInsideASlot` | two moments of the first slot answer alike | the noise shivers between its values |
| `TestNoiseRollsNewValueEverySlot` | 120 slots: at least 115 different values | slots roll in pairs, or the roll repeats |
| `TestOtherSeedMakesOtherNoiseNotItsMirror` | 120 slots under two seeds: the mean distance is over 0.3 and the mean product within 0.3 of 0 | two seeds give the same noise less a constant: the second monitor shows the first one upside down (the xorshift is linear) |
| `TestBarsDifferFromEachOther` | at three moments, eight cells give eight different levels | the cells share a clock or targets: the meter moves as one |
| `TestBarsNeverJumpBetweenTicks` | two seeds, eight cells, ten seconds in ticks: no step is a tenth | a bar jumps from target to target instead of easing |
| `TestBarsKeepMoving` | eight cells, ten seconds: every bar swings over 1 | a bar stands still |

Left to the eye: everything the picture of a trace is made of - how the
line looks, the glow, how fast it fades behind the head - lives in
`TGraph.Draw` and is tried in a live run. The slow fade of a long run of
beats (does ten minutes of the same jitter look like a pattern) is a
matter of the eye, too.

## Levels.Graph

State: written, 9 tests, green (343 in the suite). The unit is
tried by `Tests\Levels\Tests.Levels.Graph.pas`, fixture `TLevelGraphTests`,
through `ParseDynamic` and `ParseDynamics` of `Levels.Dynamics`: an object
is parsed from a JSON text of the test and read back through its
`Placement`. Only the `graph` kind is tried here; the other kinds of the
unit have no suite yet. Nothing is drawn, `Acquire` is never called, and
no renderer is made.

Shared in the unit: a graph of a test is `{"kind": "graph", "screen": 1,
"x": 4, "y": 6}` and the words under test; the caller frees what
`ParseGraph` returns. The full set of words is `FullGraph`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestBareGraphComesToItsDefaults` | a graph with nothing but its place is a `TGraph` on the back layer, with no tag, and goes out with its parent | the kind is not registered, or a default layer is another |
| `TestGraphReadsEveryWordItIsGiven` | all the words at once load; the layer, the tag and the tint land where they are read | a word of the kind spoils the common placement |
| `TestEveryShapeWordIsRead` | each of the seven words loads | a word of `GraphShapeIds` is misspelled or a shape is added to `TTraceShape` and not to the words |
| `TestShapeWordIsReadInAnyCase` | `HeartBeat` loads | the words are compared case-sensitively, as no other kind's are |
| `TestUnknownShapeRaises` | `zigzag` raises `EDynamicError` | a typo quietly draws the default heartbeat |
| `TestSizesAndRatesAtZeroRaise` | width, height, frequency, sweep, thickness and gridStep, each at 0 alone, raise `EDynamicError` | a frame of no size, or a sweep that never ends, loads |
| `TestPercentagesOutOfRangeRaise` | amplitude, glow, grid and plate, each at 101 and at -1 alone, raise `EDynamicError` | a percentage over the range loads and the trace leaves its frame |
| `TestBadGridOrPlateTintRaises` | a grid tint of two numbers and a plate tint over 100 raise `ETintError` | the tints of the grid and the plate are skipped or read leniently |
| `TestGraphIsFoundInTheListByItsTag` | `ParseDynamics` of a section with one tagged graph: `AnyTagged` finds it as a `TGraph` and not as a `TBeacon` | the graph is built as another class, or loses its tag on the way |

Left to the eye: where the graph stands on the monitor of the med lab
(`s12-monitor`), whether its grid and head glow read as an oscilloscope.
