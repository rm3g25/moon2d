# Tests of the game units

Tables of the tests, one section per unit under test: the test's name,
what holds, the breakage. The rules and the conveyor are in
`../TESTING.md`; a new unit's table goes into the file of its namespace.

## Game.Blasts

State: written, 11 tests, green (239 in the suite). The expectations were
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

## Game.Shroud

State: written, 47 tests, green (291 in the suite). Thirty-eight were
green on the first run (151 in the whole suite then); the nine of the fed
light came with `Game.Uptake` and were green on the first run too - their
mirror and its edits are told there.
The expectations were checked on a Python mirror of the shroud's clock,
bands, motes and mist (single-precision floats for the sinking motes). The
mirror and the unit were made in a session that had read the implementation,
so the table is what the tests answer to. The unit is tried by
`Tests\Game\Tests.Game.Shroud.pas`, fixture `THeroShroudTests`.

Only `THeroShroud` is tried: it counts and touches no SDL. The hero comes
into the test unit as one record, `THeroPose`, built by hand with no
texture (frame 1, a corner, `Mirrored`); the hero himself is never made.
The matter is a function of a point: everywhere open, everywhere solid,
solid from a line down, and no probe at all is a case of its own. The dice
are seeded; "over the seeds" is seeds 1 to 20.

Shared in the unit: the standing pose has its corner at (100, 50); two
seeds in the frame at (4, 6) and (28, 26), and two on the feet row for the
motes that sink. The feet row is row 31 of a frame of 32 units: where a
band leaves the body. A few looks of the tests' own (a halo that sheds
four motes a tick, forty narrow bands, strips shifted by 20) stand beside
the looks of the game; the tests read `Life` and `Bands` of the game's
looks from the records and do not spell them.

Numbers spelled, as decided: a glow under two hundredths of its flash at
the end of every look; the mirror turns a point in the frame about its
middle (x to 32 - x). Not spelled: `MistSink` (the tests say "one even
step, down, under four units"), the speed, life and size of a mote, the
sizes and levels of anything drawn.

The fed light (`Feed`, `Fed`, `FedTint`) is the light of what the hero
takes in. Its tints are `HaleColor` and `WaryColor`; a feed that is not
about its fade leaves nine tenths a tick. Spelled, as the contract of
`Feed`: the share a tick leaves is the keep it was fed with. Not spelled:
the ceiling ("a flood is held at 1 or more and under 2") and the floor
under which the light is put out ("out within forty ticks at four fifths a
tick").

| Test | Holds | Turns red when |
|---|---|---|
| `TestNewShroudIsStillAndDark` | a new shroud is not running and puts no body together; its glow is 0; ten ticks start nothing and leave no motes, mist or bands | a default of `Create` makes the shroud run or leaves something in it |
| `TestStartSetsShroudGoingForItsLife` | `Start`: running; still running a tick before `Life`; over at `Life` | the life is a tick too long or too short |
| `TestAssemblingNeedsRevealAndRunning` | `Assembling` only while running and only for a look with `Reveal`; true of the looks of an appearance (pit, entry, revive), false of the looks of a suit (ice on, ice off, heat) | the body is left undrawn after the shroud is over, or a suit hides the hero |
| `TestStartOnTheRunBeginsTheClockAgain` | six ticks in, `Start` with another look: time 0, the new look, over at its own life and not before | a restart keeps the age or the old look |
| `TestTimeIsTheShareOfLifeGone` | 0 at the start, 0.4 after four ticks of ten, the step between two ticks lies between them, 1 once the shroud is over | the step between ticks is lost, or a finished shroud is not at its end |
| `TestClearStopsAndTakesMotesAndMist` | after `Clear`: not running, no motes, no mist, and ticks bring none back | a restart leaves light and frost over a corpse |
| `TestLeaveMotesTakesMotesAndMistAndKeepsRunning` | after `LeaveMotes`: no motes, no mist; still running, the clock untouched | a door puts the hero's light out, or leaves his motes and frost with him |
| `TestStartDoesNotEraseMotesOrMist` | `Start` on the run: as many motes and as much mist as before; a tick on, the mist stands where it stood and the motes fly on | a new shroud cuts off what the old one left in the air |
| `TestGlowRisesToFlashAtItsPeakAndFalls` | peak at half: 0 at the start, growing to the flash at the peak, falling after it | the peak is off its place, or the halo does not fall |
| `TestGlowWithPeakAtStartOnlyFalls` | peak at 0: the halo starts at the flash and only falls | the glow of a suit grows first |
| `TestGlowIsNearlyOutAtTheEnd` | over every look of the game: at the end the glow is under two hundredths of its flash | a look keeps a smoulder after its life |
| `TestLookWithNoFlashHasNoGlow` | flash 0: no glow at the start, at the peak, at the end | the halo is divided by a flash that is not there |
| `TestPartTimeTogetherIsOneTimeForTheWholeBody` | together: head, middle and feet have one time at every moment, and it does pass | the order is not read from the look |
| `TestPartTimeTopDownLetsTheHeadLead` | top down: the head is never behind the feet and is ahead of them at some moment | the order is turned upside down |
| `TestPartTimeBottomUpLetsTheFeetLead` | the same the other way | the same |
| `TestPartTimeStartsAtZeroAndEndsAtOne` | over the three orders and five places, stagger 0.7: 0 at the start, 1 at the end, never turning back | a part of the body is not done when the shroud is over |
| `TestStripShiftIsZeroOnceTheBodyIsHome` | at the end every strip is home | a strip is left aside |
| `TestNeighbouringStripsStartOnOppositeSides` | at the start no two neighbours are shifted the same way | all strips fly in from one side |
| `TestStripShiftIsZeroWhenTheLookShiftsNothing` | shift 0: every strip at every moment is at 0 | the shift is not read from the look |
| `TestZeroSeedStillRollsTheStrips` | a zero seed: the strips start at different distances | a zero seed freezes the xorshift stream and every strip starts alike |
| `TestStartPlacesBandsInTheirSlotsOnAlternateSides` | five bands: each in its own fifth of the body, none fallen; neighbours on opposite sides and in opposite layers; a look with no bands has none | a band leaves its slot, or the sides and layers do not alternate |
| `TestMotesAreBornAtTheSeedsOnly` | over many seeds, one tick: every mote is within a unit of a point of the list, and both points get motes | motes are born anywhere in the frame |
| `TestMirroredPoseBornOnTheReflectedSide` | a point near the left edge: a mote is born near it; the same shroud with the pose mirrored, near its reflection in the frame | the mirror is not applied to the points |
| `TestNoMotesWithoutSeedsOrFlashOrMotes` | a look that sheds motes does so; with an empty list, with 0 motes, with no flash, none | a mote is born with nothing to be born at |
| `TestMotesDieOutAfterTheShroudIsOver` | the shroud over with motes in the air: no new one is born, and the swarm is empty within two seconds | a shroud that is over goes on shedding, or a mote never dies |
| `TestSinkingMotesStayOutOfMatter` | over the seeds, motes born on the feet row sink onto a floor: after every tick none lies deeper than half a tenth of a unit in matter, and some came down to the floor | frost goes through a floor |
| `TestLooksThatDoNotSinkLeaveNoMist` | over the seeds, a whole run of each look that does not sink down the body (pit, entry, revive, ice off, heat): no mist | a smoke that rises settles on the hero's feet |
| `TestBandAtTheFeetStaysOnTheBodyWhenTravelIsNotDown` | forty bands with travel 0 and -5: no mist; the same bands with travel 30: mist | the check of the travel is lost |
| `TestIceOnLeavesOneCloudPerBandOverItsLife` | over the seeds, a tick before the end of ice on: as many clouds as bands, every band fallen, every one with a cloud of its place and side; at the end the shroud and its mist are gone | a band is lost or falls twice, or the mist outlives its look |
| `TestRestartedIceOnDropsItsMistAgain` | ice on, three quarters in, ice on again: a tick before the end of the second the clouds are the new ones, as many as bands, every band fallen | a restart keeps the bands that have fallen |
| `TestMistIsBornOnTheFeetLineAtTheHerosMiddle` | the first cloud, with the hero at another place: at the middle of his frame, on the feet row, carrying the look it fell from | a cloud is born off the feet or off the hero |
| `TestMistStandsWhereTheHeroFellNotWhereHeGoes` | the hero walks on while the ice is on: every cloud stands at the middle where the hero was on the tick it fell, on the feet row | the mist is carried on after the hero |
| `TestMistSinksEvenlyWhereThereIsNoMatter` | with open air: every cloud sinks by one and the same step on every tick, down, by less than four units, and none is above the feet row | the mist hangs, jerks or climbs |
| `TestMistSettlesOntoAFloorAndStops` | a floor under the feet: all the mist lies within one step of its top, and stands there | mist goes through a floor or stops short of it |
| `TestMistWithNoProbeStands` | no probe: the mist stays on the feet row | a shroud with nothing to ask falls over |
| `TestMistDiesByTheAgeOfItsOwnLook` | a cloud, then a shorter look started: the cloud outlives the new look and is gone when the life of its own look is spent | a cloud is cut by the look that replaced its own, or kept past its own |
| `TestSameSeedGivesTheSameRun` | two shrouds of one seed through a hundred ticks of ice on: the same bands, motes and mist at every tick | the shroud reaches for `Random` |
| `TestOtherSeedGivesAnotherRun` | a shroud of another seed does not keep step with it | the seed is ignored |
| `TestFeedLightsTheBodyAndStartsNoScene` | a feed on a new shroud: the light is the share fed, in the tint fed; the shroud is not running and puts no body together; ten ticks bring no motes, mist or bands | a feed starts a scene: the hero is left undrawn, or a medkit sheds motes |
| `TestFedLightFadesByItsKeepEveryTick` | fed 1 with a keep of a half: a half after a tick, a quarter after two | the fade is skipped or done twice a tick, or the keep is not the one fed |
| `TestFedLightGoesOutAltogether` | fed 1 at four fifths a tick: lit five ticks on, exactly 0 forty ticks on | the floor is lost: the painter goes on drawing a light nobody sees for seconds |
| `TestFeedsAddUpToACeiling` | two feeds of 0.3 make 0.6; a flood is held at 1 or more and under 2, and a second flood lifts it no higher | a feed replaces the light instead of adding to it, or five medkits at once burn the hero white |
| `TestLastFeedSetsTheTintAndTheKeep` | green at a half, then amber at nine tenths: the tint is amber and the next tick leaves nine tenths | the first tint stays: a weapon lights the body green |
| `TestFedLightFadesWhetherAShroudRunsOrNot` | an idle shroud and one running ice on, fed alike: the same light on each of twenty ticks, and it has faded | the fade is tied to a running scene: the light of a medkit stands on the body for ever |
| `TestStartAndLeaveMotesKeepTheFedLight` | fed, then `Start`, then `LeaveMotes`: the light is as it was after each | a respawn or a suit cuts the light of a medkit, or a door leaves it behind |
| `TestClearPutsOutTheFedLight` | fed, then `Clear`: 0, and 0 three ticks on | the light of a medkit survives the hero's death |
| `TestFeedDoesNotTouchARunningShroud` | two shrouds of one seed through a hundred ticks of ice on, one of them fed every five ticks: the same clock, bands, motes and mist at every tick | a feed rolls the shroud's dice or starts its clock again: a medkit in the boss fight cuts the ice glow short |

Left to the eye:

- Everything `TShroudPainter` draws: the bands, the strips, the halo, the
  colours, the layers of the arm and of the mist, the seams between strips.
  `SeedsOf` needs a renderer.
- The fed light as drawn (`DrawFedUnder`, `DrawFedBody`): its spot, its
  halo, the white of the mask, and how it adds to the light of a scene.
- `Band.Puff` and `Band.Wide`: only the painter reads them.
- The pace of the mist: only that it sinks evenly and settles is tried.

Open: motes already in flight take the pull of the look that replaces
their own (`FlyMotes`) and are drawn in its tint (`DrawMotes`). Neither is
tried or decided: a live run says whether frost on a floor turning white
when a respawn comes in the middle of the ice glow is seen at all.

## Game.Uptake

State: written, 41 tests, green on the first run (291 in the whole suite
with the nine of `Game.Shroud` and the two of `Monsters.Bodies` that came
with them). The expectations were checked on a Python mirror of the count -
`CutCrumbs`, `TUptake` and the shroud's fed light: every test is green on
the mirror, green over sixty other seeds of the dice, and red under at
least one of the 67 edits made to the mirror; every edit turns a test red.
The mirror and the unit were made in a session that had read the
implementation, so the table is what the tests answer to. The unit is
tried by `Tests\Game\Tests.Game.Uptake.pas`, fixture `TUptakeTests`.

Only `CutCrumbs` and `TUptake` are tried: they count and touch no SDL.
Shared in the unit:

- A picture is a `TUptakeShape` painted by hand, texel by texel: 64 texels
  to a side over a frame of 32 units unless a test says otherwise, so a
  cell of a grid of 2 units is sixteen texels, as in a 2008 frame. "The
  case" is 20 by 16 units on the bottom of the frame, the shape of the
  medkit, 80 crumbs; "the dot" is one whole cell and so one crumb; "the
  column" and "the beam" cross the frame from edge to edge; "the boot" is
  an L with no mirror in it.
- The picture's corner is at (200, 300). The hero is a `THeroPose` with no
  texture and three points of his frame. He stands "beside" the pickup,
  his frame's corner at (260, 300), or "on" it, his frame over the
  picture's.
- The light a scene gives is caught by the fixture: `TFeedLight` takes a
  method. One test gives the uptake `THeroShroud.Feed` instead, as the
  game does.
- The looks are the game's (`MedkitUptake`, `WeaponUptake`, `PickupBurst`)
  or the medkit's with what a test is about changed: no push and a long
  free flight ("the still look": a crumb stands where it took off), a
  crumbling of 20 ticks in an order, a free flight with no end.
- "Over the seeds" is seeds 1 to 20. "A wreck" is a scene of `PickupBurst`.

Numbers spelled, as decided: a scene that is taken gives the body twice
its `Pulse`, crumb by crumb or at a door; a spot lives `SpotTicks`, read
from the unit; one painted texel of sixteen is no crumb and two are; the
mirror turns a point of a frame about its middle (x to 32 - x); with no
points the hero's frame gives its middle. Not spelled: `Fill`, `Crumble`,
`Burst`, `Pull`, `Scatter` and the lives of a wreck's crumbs - the tests
read them from the records or bound them loosely (a scene is over within
three seconds, a hero running at 10 units a tick is caught within five, a
crumb goes out within half a frame of its point when the hero stands).

| Test | Holds | Turns red when |
|---|---|---|
| `TestSolidPictureIsCutIntoAFullGrid` | a solid frame, a step of 2: 256 cells in rows from the top left, each 2 by 2, fully covered, its middle in its middle | a row or a column of the grid is lost, or the order the painter and the queue go by changes |
| `TestPictureWithNoPaintGivesNoCrumbs` | a clear picture gives none; a faint veil over the whole frame gives none | the veil a generated picture carries counts as paint: the frame crumbles as a square |
| `TestSpeckOfPaintIsNoCrumb` | one painted texel of a cell's sixteen is no crumb, two are, and the cover is their share | the threshold is lost (a stray texel of a 2008 gun flies off as a crumb) or raised |
| `TestCrumbMiddleIsTheMiddleOfItsPaint` | a picture of 16 by 8 units in 16 by 4 texels, paint in one column of a cell: the cell is a step wide and tall, the cover is 2 of 8, the middle is the paint's on both axes | a crumb takes off from the middle of its cell, where there is no paint, or the two axes share a scale |
| `TestCrumbsTileThePictureAtAnyStep` | solid pictures of 64, 192 and 50 texels, steps of 2, 3, 1.5, 2.5, 0.7, 5, 32 and 40: no cell is empty, every source lies in the texels and every cell in the picture, every texel is in one cell and one only | the last column is not cut to the picture (the alpha is read past its end), or a fractional step loses or doubles a line of texels: a seam or a bright stripe in the crumbling picture |
| `TestShortAlphaIsRefused` | an alpha a byte short of the texels raises `EUptakeError` | the check is lost and the cut reads past the array |
| `TestStartSeatsEveryCrumbInAStillPicture` | `Start`: one scene of age 0 with the picture number, the corner, the mirror and the look given; the crumbs `CutCrumbs` gives, all sitting; nothing fed, no spot | the scene loses what the painter draws it by, or a start feeds the body |
| `TestPictureWithNoPaintStartsNoScene` | a clear picture: no scene, ten ticks pass, nothing is fed | the guard is lost: the center of no paint divides by zero |
| `TestFullerCellGivesBiggerCrumb` | a whole cell and a quarter of one: both crumbs have a size, the fuller the bigger | a crumb gets no size and is drawn as nothing in flight, or all are of one size |
| `TestSceneCenterIsTheMiddleOfThePaint` | the boot with a half-painted cell: the scene's center is the middle of the painted texels; of the mirrored scene, its reflection | the center is the frame's or is not weighed by paint: the crumbs burst away from a point that is not the picture's |
| `TestMirroredSceneIsTheSameCrumbsReflected` | the boot under a step of 3, plain and mirrored: as many crumbs; each cell and the middle of its paint reflected in the frame, nothing moved up or down, the cover kept | the mirrored picture is cut anew (another count where the step does not divide the frame), or only the cell or only its middle is turned |
| `TestPictureIsWholeWhileItFills` | the medkit's look, the hero on the pickup: until `Fill` every crumb sits and the scene is a tick older each tick; nothing is fed, no spot | a crumb leaves a picture still taking its color, or the body lights before the picture is full |
| `TestEveryCrumbHasLeftWhenTheCrumblingIsOver` | `Fill + Crumble` ticks on no crumb sits, and they left on three different ticks or more | a crumb sits on for ever, or the picture vanishes in one tick |
| `TestTopDownEmptiesThePictureFromTheTop` | the column, top down over 20 ticks: every crumb of the top row has left before the first of the bottom row | the order is not read from the look, or is upside down |
| `TestNearFirstEmptiesThePictureFromTheHerosSide` | the beam, nearest first: with the hero on the left the left end is gone before the right end starts, with him on the right the other way | the distance is not measured to the hero, or the far end goes first |
| `TestZeroSeedStillScattersTheLeaving` | a seed of zero: the crumbs leave on three different ticks or more | a zero seed freezes the xorshift stream: every crumb leaves on one tick, one way |
| `TestCrumbTakesOffFromTheMiddleOfItsPaint` | the boot, the still look: every crumb in flight stands at the picture's corner plus the middle of its paint, as `CutCrumbs` gives it | a crumb takes off from the corner of its cell or of the frame |
| `TestMirroredPictureCrumblesFromItsReflection` | the same, mirrored: at the corner plus the middle reflected in the frame | the mirror is applied twice or not at all: a turned medkit crumbles from where it is not drawn |
| `TestCrumbGoesForAPointOfTheHerosFrame` | every crumb that has left has one of the points given, and every one of the three points gets crumbs | all crumbs go for one point of the chest, or for a point off the body |
| `TestWithNoPointsCrumbsGoForTheMiddleOfTheFrame` | an empty list of points: every crumb goes for (16, 16), the scene ends and gives its whole light | a frame with no points sends the crumbs to the corner of the frame, or stops the scene |
| `TestHerosLookDoesNotChangeTheScatter` | two uptakes of one seed, crumbs never pulled, one with points and one with none: the same crumbs in the same places at every tick | the die of the body's point is rolled only when there are points: the picture crumbles by what frame the hero shows |
| `TestStandingHeroTakesInEveryCrumb` | the medkit, the hero beside it: the scene is over within three seconds; one feed and one new spot to a crumb; every feed in the look's tint, of one share, with a keep between 0 and 1 | a crumb never comes home or comes twice, or the shares follow the size of a crumb |
| `TestSceneGivesTwiceItsPulseWhateverTickTheDoorComes` | for a door on every tick from the start to past the scene's end: the shares fed sum to twice `Pulse`; no scene and no spot is left; nothing is fed in twenty ticks behind the door | `Settle` forgets the crumbs still sitting, counts the ones already home, feeds nothing, or leaves the scene to fly after the hero through the door |
| `TestCrumbsCatchAHeroWhoRunsAway` | over the seeds, the hero going 10 units a tick from the start: the scene is over within five seconds and gives its whole light | the pull stops growing: a jump in the ice suit outruns the crumbs for good |
| `TestCrumbGoesOutOnItsPointOfTheBody` | over the seeds, the hero standing: every crumb seen going out is within half a frame of its point of the pose | a crumb is counted home anywhere on the screen |
| `TestMirroredPoseTurnsThePointAboutTheFrame` | over the seeds, a mirrored pose and points by the left edge of the frame: every crumb seen going out is nearer the reflected point than the point as painted, and within half a frame of it | the mirror of the pose is not applied: the crumbs go into the air behind the hero's back |
| `TestCrumbsFollowAHeroWhoLeaps` | the first crumbs in the air, none home, and the hero 200 units away up and aside in one tick: the scene ends within three seconds and every crumb seen going out is within a frame of its point where he is now | a crumb flies to where the hero stood when it left the picture |
| `TestSpotLivesItsTicksOnTheBody` | the dot: on the tick its crumb comes home the scene is gone and one spot is there, on a point of the frame, in the look's tint, of the crumb's size, of age 0; it is a tick older every tick and is seen on `SpotTicks` ticks in all | a spot dies a tick early or late or never, or ages before it is shown |
| `TestWreckFeedsNoOneAndLeavesNoSpots` | a wreck with the hero standing on it: it crumbles and is over within three seconds; no feed, no spot on any tick | the crumbs of a pickup blown up seek the hero and light him |
| `TestWreckCrumbsFallAndStopAtAFloor` | over the seeds, a floor on the line the picture stands on: no crumb of a wreck is seen under it; with no matter the lowest crumb is over a frame under that line | the step back out of matter is lost: the crumbs sink through the floor |
| `TestDoorGivesTheLightOfWhatWasTakenAndNoneOfAWreck` | a medkit and a wreck going, a door three ticks in: every feed is in the medkit's tint, they sum to twice its `Pulse`, no scene is left | a wreck is counted as taken at a door |
| `TestDroppedSceneEndsWhateverTickTheHeroDies` | for a death on every tick of a scene: the spots are out at once; the scene is over within three seconds; no spot and no feed after the death | the crumbs go on into a corpse, or a crumb in flight at the death gets no life and flies for ever |
| `TestDroppedCrumbsFallInsteadOfVanishing` | a death with crumbs in the air: ten ticks on the scene is there, every one of them is still in flight and falls faster than it did | `Drop` erases the scenes, or the crumbs are still pulled to the hero |
| `TestDropChangesNothingForAWreck` | two uptakes of one seed with a wreck in the air, one of them told the hero died: the same crumbs in the same places to the end | a death rolls the lives of a wreck's crumbs anew: they hang twice as long |
| `TestClearTakesScenesAndSpots` | a scene on its way with a spot lit, `Clear`: no scene, no spot; three seconds on nothing more is fed or lit | a restart leaves crumbs flying into the reborn hero |
| `TestClockCountsEveryTick` | 0 at birth; 5 after five ticks with no scene; 12 after a scene, seven ticks and `Clear`; 15 three ticks on | the clock runs only while a scene does (the crosses of the medkits that lie stop breathing), or a restart sets it back |
| `TestScenesRunSideBySide` | a dot and a weapon, and eight ticks later a second medkit: the late picture is whole until its own `Fill`; to the end every scene there is in its order with the crumbs it began with; the green light sums to four times `Pulse`, the amber to twice | the scenes share a clock, or dropping a finished scene takes or garbles its neighbour |
| `TestRunsWithNoFeedAndNoProbe` | no feed and no probe given: a medkit's scene ends with a spot to every crumb, a wreck falls and ends | an uptake with no one to feed or nothing to ask falls over |
| `TestSameSeedGivesTheSameRun` | two uptakes of one seed, a medkit and a wreck each: the same crumbs and spots at every one of thirty ticks | the uptake reaches for `Random` |
| `TestOtherSeedGivesAnotherRun` | an uptake of another seed does not keep step with it | the seed is ignored |
| `TestTakenMedkitLightsTheBodyAndTheLightDies` | the uptake feeding a shroud, ticked in the game's order: the shroud never runs; its light rises over zero and stays under twice `Pulse`, in the medkit's tint; it outlives the last crumb and is out three times `PulseTicks` later | `Feed` no longer fits `TFeedLight` (the suite does not build), the light never dies, or taking a medkit starts a shroud |

Left to the eye:

- Everything `TUptakePainter` draws and keeps: the pictures of the sets
  (`PictureOf`, `ShapeOf` - they load a sprite set and need a renderer),
  the fill and its ease, the halo of a filled picture and its second pass
  above 1, the crumbs that sit and the bleed between them (the seams), the
  crumbs in flight and their fade, the spots, the tints, and the light of
  the pickups that lie - the breath of a cross and the halo of a weapon.
- `Flash`, `Tint` and `Size` beyond "a fuller cell is bigger": only the
  painter reads them. So with the push from the center and the scatter of
  a take-off: the tests hold where a crumb starts and that the dice roll
  alike, not how the burst looks.
- `TMonster.ArtSet` and `TMonster.Mirrored`: the game starts a scene by
  them, and a wrong name stops the level's load at once.
- What the game does around the uptake lives in `Moon2D.dpr` and is tried
  in a live run: `TakeLoot` and `BurstPickup`, the tick order with the
  shroud, `Settle` at a door, `Drop` at the death, `Clear` at a restart.

Not tried: `CutCrumbs` with a step of zero or less. The guard gives no
cells; without it the cut never ends, and a test of it would hang the
suite instead of turning red.

Open, found while the tests were designed; neither tried nor decided:

- A wreck's crumb is stepped back out of matter along Y only. A floor and
  a ceiling hold it. A crumb that flies sideways into a wall goes in - up
  to 12 units on the mirror - and hangs there until its life is out. It is
  the model as designed; a live run says whether it is seen: a medkit
  blown up beside a wall.
- Two scenes of different tints coming home on the same ticks (a medkit
  and a weapon taken together): the shroud's light takes the tint of the
  last feed, so its color may change from tick to tick.
- A cell covered by exactly the threshold (3 texels of 25) is likely no
  crumb: the cover is kept as a `Single` and compared with 0.12. No
  picture of the game has such a cell under a step of 2.

## Game.Trial

State: written, 41 tests. Needs no stage: `TGravelTrial` counts and
touches no SDL, and the events are read from JSON. The open sky came with
3.0.58 (stage 5.3), and stage 5 passed its live run. The wave, its
medkit and its level came with 3.0.59 (6.1 and what was added to it
before its live run), and 6.1 was run live; so was 6.2, which edited one
test. With the tests of the arena (3.0.53 to 3.0.59) the
suite counts 488. The unit is tried by `Tests\Game\Tests.Game.Trial.pas`,
in five fixtures: `TTrialSkyTests`, `TTrialWaveTests`,
`TTrialMiddleMedkitTests` (the trial itself), `TFinaleLevelTests` and
`TSkyFallEventTests` (what a level makes of it).

Shared in the unit:

- A trial of the tests deals a batch of one. It is ticked with one body
  holding the gate, so an act never ends by itself; a test that wants an
  act over lets its gravel down and ticks once with nobody holding the
  gate (`GoThroughGravelAct`). `ReachWaveAct` does that for every act of
  gravels.
- "The wave" is a count of 4 with a cap of 2 unless a test says
  otherwise. In its act the test keeps the count of the living itself: a
  body let down is alive from the next tick, and dies when the test says.
- A tick is counted from 1. The trial's own numbers - `TrialActs`,
  `TrialFirstWaveTicks`, `TrialWaveTicks`, `TrialActBreakTicks`,
  `TrialWaveRefillTicks` - are read from the unit, not spelled.
- `FinaleLevel` - a room of `Tests.Rooms` with one screen trigger, a trial
  of 15 and the finale members given; `EventsOf` and `ReadOneEvent` parse
  an events section of the test's own. Three tests load `level2.json`
  beside the executable.

Numbers spelled, as decided: 33 ticks a second; one act more for a wave;
the medkit of the middle on the kill that makes half the batch, none for
an act of one. From `level2.json`, as the plan has them: the arena on
screen 9; the sky opens once, in act 5, with `skyBarrel`; a finale of
`betoner`, 10, 15 and 20 by grade, 3 alive; six balconies in
`s09-press-4`; the wave onto `s09-press-1`; the end sleeps `s09-balcony`;
two pairs of tanks at half the wave, on row 10. A retune of those in the
file turns its test red, by design. Not spelled: the pace of the sky in
the file, the delay between the pairs of tanks.

### TTrialSkyTests

| Test | Holds | Turns red when |
|---|---|---|
| `TestSkyIsShutUntilOpened` | a trial nobody opened the sky of: no `SkyFall` in ten seconds | the sky is open by default: barrels fall in every act |
| `TestOpenSkyLetsABodyFallAtItsPace` | `OpenSky(1)`: three falls in three seconds, on ticks 33, 66 and 99 | the pace is taken in ticks, or the first body falls at once |
| `TestPaceUnderATickIsATick` | `OpenSky(0.001)`: a fall on each of 20 ticks, never more | a pace under a tick rounds to 0: the sky never falls, or divides by zero |
| `TestSkyOpenedAgainTakesTheNewPace` | open at 10 s, a second on open at 1 s: one fall in the next second, on its 33rd tick | a second `OpenSky` keeps the old pace, or counts the new one from the first |
| `TestSkyShutsWithTheAct` | the gravel let down, the sky open a body a tick and falling: on the tick the gate opens, `ActEnded` and no `SkyFall`; none in five seconds after | the sky of act 5 stays open into the next act, or lets a body fall on the tick it shuts |
| `TestSkyOfAStoppedTrialStaysShut` | open, `Stop`, `Start` again: no fall in five seconds | a restart of the trial keeps the sky of the last try |
| `TestSkyIsNotOpenedOutsideTheTrial` | `OpenSky` before `Start`: no fall in five seconds | a sky told while no trial runs opens the next trial's |

### TTrialWaveTests

| Test | Holds | Turns red when |
|---|---|---|
| `TestWithoutFinaleTheGravelsAreTheWholeTrial` | `Start` with no wave: `Acts` is `TrialActs`; the first four acts end without `Finished`, the fifth with it, and the trial runs no more | a trial with no finale gains an act: the trial never ends |
| `TestFinaleIsOneActMore` | a wave: `Acts` is one more; no act of gravels finishes the trial; it runs on into the act of the wave | the last act of gravels still ends the trial: the wave never comes |
| `TestFinaleWithNoCapIsNoWave` | count 4 with cap 0, and count 0 with cap 2: `Acts` is `TrialActs` | a wave nobody may be alive in, or a wave of nobody, holds the trial open for ever |
| `TestWaveFillsUpAWaveApart` | nobody dies, 300 ticks: two bodies let down, the first `TrialActBreakTicks` into the act, the second `TrialWaveTicks` after it | the wave falls at once over the act change, or all of it on one tick |
| `TestWaveNeverPassesItsCap` | count 10, cap 3: the living are never over 3 and end at 3 | the cap is not asked: the room fills with betoners |
| `TestDeadBodyIsReplacedAfterTheRefill` | the wave full, one dies: one body let down, `TrialWaveRefillTicks` after the death | a dead body is replaced at once, never, or by more than one |
| `TestFirstBodyOfTheWaveIsAHerald` | every body dies at once: the first let down carries `Herald`, no other does; one herald in all | the wave comes with no herald, or every body does |
| `TestWaveIsNeitherGravelsNorAimed` | through 300 ticks of the act: no `SpawnGravel`, no `MarkAimed`, no `SpawnAimed` | the act of the wave is dealt as one of gravels, or its bodies are aimed |
| `TestWaveLetsDownItsCountAndNoMore` | every body dead at once: the trial finishes, with `ActEnded`, only after the fourth body and with no fifth; then it runs no more | the count is lost (the wave never ends), or the gate opens before the last body comes |
| `TestWaveGateWaitsForTheLastBody` | count and cap 2, both down: 300 ticks with two alive and one with one alive do not finish; with none it finishes and runs no more | the trial ends over a living betoner: the door opens with the fight on |
| `TestProgressOfTheWaveAct` | in the act of the wave: `Progress.Act` 6, `Batch` the count 4, `Dealt` 0; once it fills, `Dealt` 2 | the events that wait on the wave read the batch of gravels |
| `TestGuestsHoldTheGateButNotTheWave` | four guests alive all along: both bodies of a wave of two come; with the wave dead and the guests alive 300 ticks do not finish; with nobody it finishes | the cap counts the guests (four tanks hold the betoners back), or the gate does not (the door opens over a tank) |
| `TestWaveKillsAreCountedInItsActOnly` | a kill noted in act 1 is not counted; two noted in the act of the wave: `Progress.WaveKilled` 2 | `NoteWaveKilled` counts outside the wave: the tanks come early |

### TTrialMiddleMedkitTests

Shared: a batch of four, half of it two kills. Five acts of two kills
stay under the fifteen that pay a medkit of their own, so every medkit
seen is one of a middle. A medkit is looked for over the five ticks after
the kills.

| Test | Holds | Turns red when |
|---|---|---|
| `TestHalfTheBatchKilledPaysAMedkit` | one kill: no medkit; the second: one; two more: none | the middle is paid early, late or twice |
| `TestEveryActPaysItsMiddle` | in each of the five acts, the batch dealt and two killed: one medkit; the trial is over after the fifth | the kills of the act are not reset at the act change: only act 1 pays |
| `TestHalfTheWaveKilledPaysAMedkit` | the wave of four: one kill no medkit, the second one, the third and the fourth none | the wave's middle is not paid, or is paid by the gravels' count |
| `TestActOfOneHasNoMiddle` | a batch of one, its gravel killed: no medkit | half of one rounds to 0: the middle is paid on no kill, or on every one |

### TFinaleLevelTests

| Test | Holds | Turns red when |
|---|---|---|
| `TestFinaleIsRead` | a finale of `betoner`, count 10, 15, 20 by grade, alive 3: `HasFinale`, its monster, each count on its grade, its cap; a count of 7 alone is 7 on every grade | a member is read from another key, or the grades are swapped |
| `TestTrialWithoutFinaleHasNone` | `gravelBoss` alone: a trial, no finale | a finale is made up for every trial |
| `TestFinaleWithoutTrialRaises` | a finale with no `gravelBoss` raises `ELevelError` | a finale with no trial to end loads and never comes |
| `TestFinaleWithNoMonsterRaises` | no monster, and an empty one, each raise `ELevelError` | a wave of nobody loads |
| `TestFinaleWithABadCountRaises` | each raises `ELevelError`: no count, 0, "ten", a count for one grade only | a typo of the count loads: the wave is empty on some grade |
| `TestFinaleWithNoCapRaises` | no `alive`, and `alive` 0, each raise `ELevelError` | a wave nobody may be alive in loads |
| `TestTrialDoneAndWaveOntoAreRead` | `trialDone` and `waveOnto` to "balcony": `ecTrialDone`, `eaWaveOnto`, its bank; a `waveOnto` with no target raises `ELevelEventError` | a word is renamed in the parser, or a wave onto no bank loads |
| `TestWaveOntoAnUnknownBankRaises` | a `waveOnto` to a bank no shelf stands in raises `ELevelError` at load | a typo of a bank loads: the betoners have nowhere to land |
| `TestLevelTwoArenaEndsInBetoners` | `level2.json`: one finale, on screen 9, `betoner`, 10, 15, 20, cap 3; six shelves in `s09-press-4`; one `waveOnto`, to `s09-press-1`, on `actReached` 6; every `trialDone` event is screen 9's, and one action of them sleeps `s09-balcony`, sparing the hero | the arena loses its finale, its bottom row of balconies, or the calm at its end |
| `TestWaveKilledIsRead` | `waveKilled`, act 6, part 1 of 2: the condition, the act, the part, the whole; no act, part 2 of 2, and no `of` each raise `ELevelEventError` | the share is read wrong: the tanks come at the wrong kill or never |
| `TestStraysLeaveIsRead` | `straysLeave` to "birds": the action and its flock; with no target it raises `ELevelEventError` | a word is renamed, or a leave of no flock loads |
| `TestLevelTwoArenaTanksComeAtHalfTheWave` | `level2.json`: two `waveKilled` events, screen 9, act 6, 1 of 2; each only spawns, a tank of `tank.mns` on row 10, one from the left and one from the right; the two delays differ; one `straysLeave` of `s09-strays` on `trialDone` | a pair comes from one side, both pairs come at once, or the strays stay after the victory |

Edit to an existing test: `TestLevelTwoArenaEndsInBetoners` came with
6.1 asking the wave onto `s09-press-4` and the end to sleep that bank;
with 6.2 it asks the wave onto `s09-press-1` and the end to sleep
`s09-balcony`.

### TSkyFallEventTests

| Test | Holds | Turns red when |
|---|---|---|
| `TestSkyFallReadsItsMonsterAndPace` | `skyFall` of `skyBarrel` every 2.5: `eaSkyFall`, the monster, the pace | the members are read from other keys |
| `TestSkyFallWithNoMonsterRaises` | no monster, and an empty one, each raise `ELevelEventError` | a sky of nothing loads |
| `TestSkyFallWithNoPaceRaises` | no `every`, 0 and -1 each raise `ELevelEventError` | a pace of nothing loads: a barrel every tick, or a division by zero |
| `TestSkyFallNeedsAnEventThatWaitsForAnAct` | a `skyFall` on `enterScreen` raises `ELevelEventError` | a sky with no act to shut it loads and never shuts |
| `TestLevelTwoArenaSkyOpensInActFive` | `level2.json`: one `skyFall`, on screen 9, in act 5, of `skyBarrel` | the sky opens in another act, twice, or drops another body |

Left to the eye: what the game does with a cue, in `Moon2D.dpr` - which
body falls from the sky and where, the side a betoner of the wave is let
down on, the tanks along their lane, the violet glow of an arrival,
`win.ogg` on `Finished`.

Not tried yet: the acts of gravels themselves - the batch and its waves,
the herald of an act of gravels, the aimed gravel, the pit returns,
`RoomBusy` and the medkit of every fifteen.

## Game.Press

State: written, 13 tests. Needs no stage: `TPress` only counts which rows
are out and which are told to move. Came with 6.2 (still 3.0.59), whose
build was run live. The unit is tried by
`Tests\Game\Tests.Game.Press.pas`, fixtures `TPressTests` (the press) and
`TPressLevelTests` (the press action and the press of level 2).

Shared in the unit: the rows are four banks of the test's own, `r1` to
`r4`, top first; the beat is 100 ticks unless a test says otherwise.
`TicksToNextCall` ticks the press until a tick tells the shelves
anything, and gives that tick, counted from 1. `PressArrivalTicks` and
`PressRewakeTicks` are read from the unit, not spelled. `PressEvents`
parses a press action of the test's own; one test loads `level2.json`.

Numbers spelled, as decided: 33 ticks a second; every row starts in; the
order of a beat. From `level2.json`, as the plan has them: one press, on
screen 9, in act 6; four rows `s09-press-1` to `s09-press-4`, top first,
on rows 3, 5, 7 and 9 (decks at y = 96, 160, 224, 288); six shelves a
row, all of them in `s09-balcony` and nothing else in it; the strays of
`s09-strays` between columns 4 and 11. Not spelled: the beat of the file.

| Test | Holds | Turns red when |
|---|---|---|
| `TestEveryRowStartsIn` | `Start`: active, no row out; no call in three beats | the rows start out, or a beat over an empty press tells the shelves something |
| `TestArrivalBringsTheTopRowOut` | `Arrive('r1')`: wakes `r1` and sleeps nothing, `r1` is out; a second arrival onto `r1` tells nothing; an arrival onto `r3` tells nothing and `r3` stays in | an arrival wakes a row that is not the top, or tells a row that is out again |
| `TestBeatRidesTheRowsDownARow` | after an arrival the first call is on tick 100: it sleeps `r1` and wakes `r2`; `r1` is in, `r2` out | the row under is not woken (the body falls to the floor), or the top row stays out |
| `TestBottomRowFallsOffThePress` | one arrival, then a call every 100 ticks: they wake `r2`, `r3`, `r4`; the fourth sleeps `r4` and wakes nothing; every row is in; no call in three beats after | the bottom row wakes a row past the press, or the press goes on beating an empty stack |
| `TestBeatWaitsOutAnArrival` | beat 30, an arrival on tick 20: the next call comes `PressArrivalTicks` after the arrival, and sleeps `r1` | the top row goes from under a betoner still falling onto it |
| `TestRowUnderARowGoesInAndComesOutAgain` | `r1` out, a beat, a newcomer onto `r1` again: the next beat, 100 ticks on, sleeps `r1` and `r2` and wakes `r3`, and `r2` counts as out; `PressRewakeTicks` later a call wakes `r2` and sleeps nothing | the lower row stays out (its own body never falls) or stays in (the body from above falls two rows) |
| `TestShutAndStartedAgain` | after an arrival, `Shut`: not active; an arrival and three beats tell nothing; `Start` again: `r1` is in, and an arrival wakes it | a shut press goes on beating after the trial is won, or a restart keeps the rows of the last try |
| `TestNoRowsOrNoBeatIsNoPress` | `Start` with no rows, and with a beat of 0: not active | a press of no rows indexes nothing, or a beat of 0 beats every tick |
| `TestBeatTicksFromSeconds` | `PressBeatTicks`: 10 s is 330 ticks, 0.001 s is 1 | the beat is taken in ticks, or rounds to 0 |
| `TestPressIsRead` | a press of rows a, b, c every 7.5 in act 6: `eaPress`, the rows in order, the beat | the rows are reversed, or a member is read from another key |
| `TestBadPressRaises` | each raises `ELevelEventError`: no rows, one row, a row of no bank, no beat, a beat of 0, an event that waits for no act | a press that cannot ride or never beats loads, or one that never shuts |
| `TestPressOntoAnUnknownBankRaises` | a press of banks no shelf stands in raises `ELevelError` at load | a typo of a row loads: the betoners fall through a row that is not there |
| `TestLevelTwoArenaPressesItsBalconies` | `level2.json`: one press, screen 9, act 6, the four rows top first; the wave onto `s09-press-1`; one `trialDone` sleep of `s09-balcony`, sparing the hero; each row six shelves at its deck, each in `s09-balcony`, and the bank holds those 24 alone; every pad of `s09-strays` keeps to columns 4 to 11 | a row loses a shelf or its place, the newcomers land on another row, the calm takes a shelf that is no balcony, or the strays fly through the balconies |

Left to the eye: what the shelves do with a call (`TellPress`: a wake
that holds, no mercy on the press) and the body that falls a row; whether
`PressArrivalTicks` and `PressRewakeTicks` fit the fall of a betoner and
a shelf's warning and slide - they are the game's, judged in a live run.
