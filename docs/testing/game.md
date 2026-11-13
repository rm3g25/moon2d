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
  and `StrikeHero` live in `Game.Moon`, not under tests yet. A barrel
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
- What the game does around the uptake lives in `Game.Moon` and is tried
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

Left to the eye: what the game does with a cue, in `Game.Moon` - which
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

## Game.Ram

State: written, 16 tests (3.0.75). Needs no stage: `TRam` only counts -
the drive, the mast, the contact, the shield. The unit is tried by
`Tests\Game\Tests.Game.Ram.pas`, fixtures `TRamTests` (the Ram),
`TBodyShieldTests` (the shield over a body, `Game.Shield`) and
`TRamLevelTests` (the ram action and the Ram of level 2).

Shared in the unit: the body is the hull's whole box solid (`SolidBody`),
its middle in its middle; the orders stop the ram at 260 after a silence
of 1 s. `TicksUntil` ticks the Ram until a cue of the kind asked comes,
and gives that tick, counted from 1. `StandAtTheStop` sees the whole
entrance and a death: the Ram stands at its mark. `OnTheRoad` is a hero's
body 16 by 32 with his feet on the road. `RamEvents` parses a ram action of
the test's own; one test loads `level2.json`.

Numbers spelled, as decided: 33 ticks a second; about 3 s from the rumble
to the stop; a breath of a second at most; about 1.5 s of the mast; the
stop 260 and the track `boss3.ogg` of level 2. Not spelled: the speeds,
the brake, the patrol's marks.

| Test | Holds | Turns red when |
|---|---|---|
| `TestWholeEntranceWaitsOutTheSilence` | the first `Start` is True and not `Present`; the rumble comes after the 33 ticks of the fade-out and before 66; the hull is beyond the right edge | the machine drives into the music, waits too long, or appears on the screen |
| `TestDrivesInAndStopsAtItsMark` | the hiss after 2.5-4 s of drive; the left edge exactly at the stop; the eye dark | the ram stops short or past its mark, or the drive-in is too fast or slow |
| `TestHeadLocksAfterTheBreath` | the whine within a second of the stop, the eye lit with it; the lock 1-2 s later, the mast a cell higher than at rest | the mast rises with no breath, the eye stays dark, the head never locks or never comes up |
| `TestDeathReplaysFromTheStop` | after `Clear`, `Start` is False, `Present` at once at the stop; no rumble and no hiss before the lock | a death replays the whole drive-in |
| `TestNewLevelSeesTheWholeEntranceAgain` | after `Reset`, `Start` is True | a new level or the End key gets the short entrance |
| `TestAfterTheLockItDrivesLegsBetweenTheWalls` | six legs: each starts with the rumble, stays inside the screen every tick and goes a cell at least | the machine stands for good, drives through a wall, or twitches on the spot |
| `TestTouchOnTheFloorWounds` | a hero on the road over the hull is touched, one clear of it not | the ram drives through the hero, or wounds from afar |
| `TestHeroOnAPadIsOutOfItsWay` | on a deck over it - no touch; off it in the air - none; down on the road - a touch | a hero on a pad is crushed by a machine behind it, or the pad shields him on the floor too |
| `TestFallOntoItWounds` | over the roof - none; dropped onto it in the air - a touch | the roof is a safe place to land |
| `TestThrownAwayFromTheMiddle` | left of the middle - thrown left, right of it - right | the throw pulls the hero into the machine |
| `TestShieldTakesABullet` | a bullet into the hull meets the shield within the margin before the outline; one over the machine flies on | bullets pass the hull, or the shield hangs in the air over it |
| `TestAbsentMeetsNothing` | before a start, and while the music fades, no touch and no block | an unseen machine wounds or stops bullets |
| `TestHoldsTheBodyAndAMarginPastIt` | a body 10 by 10: the middle, a unit and a half past the side and over the top are held; past the margin, and under its foot, not | the shield is no wider than the body, or reaches into the floor |
| `TestRamIsRead` | a ram action: `eaRam`, its stop, track and fade-out | a member is read from another key |
| `TestBadRamRaises` | each raises `ELevelEventError`: no stop, a stop off either edge, no track | a Ram with nowhere to stop or no track loads |
| `TestLevelTwoArenaBringsTheRam` | `level2.json`: on screen 13 one ram action, on arrival, stop 260, `boss3.ogg`, and no music action | the arena's music is started by an event again, or the Ram is lost |

Left to the eye: the picture - the mast between the hull's halves, the
clips, the sway, the lamps, the honeycomb along the outline; the throw
(`THero` needs a renderer); the sounds and the music handed over; the
numbers of the entrance and the patrol.

## Game.Barge

State: written, 21 tests; the drift came with 3.0.120 (stage 18d-1),
the rest with 3.0.118-3.0.119; since 3.0.121 (stage 18d-2) the drift
starts by the caller's word (`Loose`), not by the hero aboard, and a blow
rocks the deck - 2 tests new, 3 reworked, and every drift test lets the
barge go itself. Needs no stage: `TBargeRide` only counts
where its left edge and its deck are. The unit is tried by
`Tests\Game\Tests.Game.Barge.pas`, fixture `TBargeRideTests`. The table
holds the drift; the mooring, the cast-off and the station are told in the
unit's header.

Numbers spelled, as decided: the drift across the middle three fifths of
the screen (its middle between a fifth and four fifths), half a cell up
and down. Not spelled: the lap, the start, the pace.

| Test | Holds | Turns red when |
|---|---|---|
| `TestBoardedItCastsOffToItsStation` | reworked (3.0.121): at the station with him aboard, it holds it | his boarding starts the fight before the magnet does |
| `TestStationIsThereAtOnce` | reworked: held with nobody aboard, nothing told when he boards | point B tells a boarding and runs the belt up again |
| `TestItHoldsItsStationTillLetGo` | reworked (3.0.121): `Station`, 100 ticks with nobody aboard and 100 with him: `bsStation`, at `StationLeft`, `Dip` 0 | the barge drifts off before the magnet has made its first move |
| `TestLetGoAtItsStationItDrifts` | reworked (3.0.121): `Loose` at the station: `bsDrift` at once; 100 ticks on over a cell off the station | the fight's start does not move the barge |
| `TestLetGoElsewhereChangesNothing` | `Loose` away and moored: the stage as it was, the mooring kept | a magnet deployed early sets a moored barge adrift from the pier |
| `TestABlowRocksItsDeckAndDiesOut` | against a barge let go on the same tick and not struck, `Rock(8)` after 50 ticks, 99 ticks watched: the deck dips more than 4 and less than 16 under the calm one's, the left edge is the same, at the end within a unit of it | a thrown barge does not move the main barge, throws it off its loop, or leaves it bobbing for good |
| `TestDriftSetsOffGentlyFromTheStation` | the first tick of the drift at the station and on its line; the way across and down changes by less than 0.1 a tick over the first 100 ticks | the barge jerks off under the hero |
| `TestDriftKeepsToTheMiddleThreeFifths` | two laps: the middle between a fifth and four fifths of the screen, past a quarter and three quarters; `Dip` within half a cell, past a quarter cell both ways | the loop leaves the screen, crowds the edges, or is too small to be felt |
| `TestDriftIsNeverStillForLong` | from tick 100, two laps: never 33 ticks in a row slower than 0.2 a tick | it stands at the ends of its loop |
| `TestDriftGoesOnWithoutHim` | aboard 10 ticks, then 100 with nobody aboard: still `bsDrift`, over a cell farther | a hero who jumps off stops his harbour |
| `TestWayDownIsWhatItWentThisTick` | 400 ticks: `WayDown` is `Dip` less the last tick's, `Way` is `Left` less the last tick's | the pad is carried by another step than the barge's: the hero slides or drops |
| `TestClearEndsTheDrift` | a clear mid-drift: away, `Dip` 0; `Station` - at the station on its line | a death keeps the barge where the drift left it |

Left to the eye: the barge's pad and its riders going up and down with it
(`TickPier`), the checkpoint on its deck.

## Game.Flock

State: written, 36 tests (17 of 3.0.120, stage 18d-1; 7 of 3.0.121, stage
18d-2 - the barge the magnet takes; 5 of 3.0.123, stage 18d-3 - the barge
a shell knocks off; 3 of 3.0.124 - its list; 4 of 3.0.125, stage 18d-4 -
the barge the charge smashes, the flock held). Needs no stage:
`TBargeFlock` only counts places. The unit is tried by
`Tests\Game\Tests.Game.Flock.pas`, fixture `TBargeFlockTests`.

Shared: the main barge is `Game.Barge`'s own, let go at its station and
drifting, its deck on the road's line 352; the pool is nine
barges, three each of 67, 104 and 123 units; the dice 7; the count 2. "A
long run" is 8000 ticks, four minutes. `Step` ticks the main barge, then
the flock.

Numbers spelled, as decided: a gone barge replaced after 1-2 s
(`ReplaceGapLeast`, `ReplaceGapMost` read from the unit); the count of the
first tier, 2. Not spelled: the paces, the paths, the escort's place - the
tests bound them loosely or read the unit's constants.

| Test | Holds | Turns red when |
|---|---|---|
| `TestNothingFliesTillStarted` | 200 ticks unstarted: not `Started`, none flies, no escort | barges fly in before the fight starts |
| `TestTheEscortComesFirstAtOnce` | `Start(2)` and a tick: one flies, it is the escort, on `fpEscort` | the first barge is a free one: no floor bound to the main barge |
| `TestTheNextComesAfterAGap` | the second comes 33 to 67 ticks after the first | both come in at once, or the second never does |
| `TestNeverMoreThanTheCount` | a long run: never more than two | a relief or a replacement overfills the sky |
| `TestStartedOnceTillAClear` | `Start(4)` after `Start(2)`: never more than two in 2000 ticks | a second start changes the count mid-fight |
| `TestComesInFromBeyondTheRightEdgeFastAndBrakes` | a long run, every barge that comes in: its first tick beyond the right edge, its second faster left than 2.5 a tick, 165 ticks in slower than 4.5; over six come in | a barge appears on the screen, drifts in slowly, or never brakes |
| `TestLeavesOnlyPastTheLeftEdge` | a long run: every barge that stops flying is wholly past the left edge; over four leave | a barge vanishes on the screen, with the hero on it |
| `TestAGoneBargeIsReplacedSoon` | once full, a long run: never more than 67 ticks in a row short of the count | a gone barge is never replaced |
| `TestAlwaysABargeWithinJumpOfTheMain` | from the first neighbour (within 330 ticks), a long run: on every tick a flying barge `WithinJump` of the main one | the hero on the main barge has no small barge to jump to - the guarantee |
| `TestTheEscortKeepsToTheScreen` | from 330 ticks after the first neighbour, a long run: the escort inside the screen | the escort slides off an edge as the main barge swings to it |
| `TestTheEscortIsRelievedAndLetGo` | a long run: at every change of the escort the old one still flies on a free path and the new one is within the jump; at least two changes | the escort serves forever, vanishes at the hand-over, or hands over from afar |
| `TestNoneRisesIntoTheRamsBelly` | a long run: every flying barge's deck at 198 or lower down | a lane puts a hero's head into the hanging hull |
| `TestWayIsWhatItWentThisTick` | 2000 ticks, a barge flying on two ticks running: `WayX`, `WayY` are its step | the pad is carried by another step than the barge's |
| `TestClearGroundsTheFlock` | a clear mid-fight: not started, none flies, no escort, none comes in 100 ticks; started anew, one at once | a death leaves barges in the sky, or the flock never starts again |
| `TestSameDiceSameFlight` | two flocks of the same dice over two main barges alike, 3000 ticks: the same barges fly at the same places | the flock reads a clock or `Random` |
| `TestASmallPoolFliesWhatItHas` | a pool of one: never more than one, it escorts and flies; a pool of none: none flies | a short pool indexes past its end |
| `TestWithinJumpIsAJumpUpOrDownAndAcross` | over the main barge at 64 and at 80 up - within, 81 - not; 64 down - within; 64 across either side - within, 65 - not | the guarantee is measured with the wrong sign or from the wrong edge |
| `TestATakenBargeFliesNoMore` | a free barge taken: not `Flying`, `Taken`, one fewer flies; 2000 ticks on it never flies | the magnet's barge is flown on by the flock, or sent in again while the magnet holds it |
| `TestATakenBargeIsReplacedByAnother` | a free barge taken: within 67 ticks the count is full again | the magnet thins the flock for good |
| `TestATakenEscortIsReplacedAtOnce` | the escort taken: a tick later another barge is the escort and flies; within 330 ticks a barge is within the jump | the taken escort leaves the main barge with no neighbour for a gap and more |
| `TestTheEscortTakenItsReliefIsTheEscort` | run till a relief is on its way, the escort taken: the relief is the escort at once, flies on 330 ticks, a barge within the jump | the hand-over lets go of an escort that is not there: an index of -1 |
| `TestGivenBackItFliesAgain` | a pool of two, the escort taken: 330 ticks it never flies; given back - not `Taken`, and in a long run it flies again | a thrown barge is lost to the pool, and the pool runs dry |
| `TestTakingOneNotFlyingChangesNothing` | an idle barge taken: not `Taken`, the escort and the count as they were | a stale number from the magnet grounds a barge |
| `TestClearForgetsTheTaken` | the escort taken, a clear: not `Taken`, none flies | a death leaves a barge out of the pool |
| `TestAKnockedBargeFallsBehindAndSinks` (3.0.123) | a free barge knocked: `Knocked`, on `fpKnocked`; at once left and down; for 20 ticks ever farther behind and ever faster down, never faster than 4 across nor 6 down | the knocked barge stops dead, climbs back, or drops out of sight in a tick - no time to jump off |
| `TestAKnockedBargeIsGoneSoon` (3.0.123) | knocked: it stops flying within 132 ticks, past the left or the bottom edge, and is knocked no more | a knocked barge falls for ever, or vanishes on the screen with him on it |
| `TestAKnockedBargeIsReplacedWhileItFalls` (3.0.123) | knocked: one fewer on its path at once; within 67 ticks the count on their paths is full again | a falling barge keeps its place in the count and the flock thins while it falls |
| `TestAKnockedEscortIsReplacedAtOnce` (3.0.123) | the escort knocked: no escort at once; a tick later another, on its path | the knocked escort leaves the main barge with no neighbour for a gap |
| `TestAKnockedBargeListsToTheSideStruckMoreAndMore` (3.0.124) | struck 20 left of its middle: its left end down a tick on; past the blow's jolt, ever steeper till it is gone, never past 40 | the barge lists away from the hit, rights itself, or turns over |
| `TestTheFartherFromItsMiddleTheSteeper` (3.0.124) | two flocks of the same dice, the same barge struck 5 and half its width right of its middle: both list right, 12 ticks on the far hit more than 5 degrees steeper | every hit lists a barge alike |
| `TestOnItsPathNoList` (3.0.124) | 330 ticks of the flock: every barge level | a barge on its path flies askew |
| `TestASmashedBargeIsGoneAndReplaced` (3.0.125) | a free barge smashed: flying no more, not taken, out of the count; within the longest gap and a tick another is in | a smashed barge flies on behind its pieces, or is never replaced |
| `TestASmashedKnockedBargeIsGoneToo` (3.0.125) | a knocked barge smashed a tick later: gone, knocked no more | a falling barge the charge meets falls on through its own pieces |
| `TestSmashingOneNotFlyingChangesNothing` (3.0.125) | an idle barge smashed: as many fly, the escort kept | a stale number loses the escort |
| `TestHeldNoneComesInLetGoTheEscortAtOnce` (3.0.125) | held, every flying barge smashed: three of the longest gaps and none came in; let go: the escort the next tick, flying | a barge comes in through the low hull during the charge, or the floor stays empty after it |
| `TestKnockingOneNotFlyingOrKnockedChangesNothing` (3.0.123) | an idle barge knocked: not sent in, not knocked; a falling one knocked again: its sink goes on, not thrown anew | a second shell on a falling barge kicks it up again, or a stale number sends a barge in |

Left to the eye: the pads following the barges (`TickFlock`), the paths'
feel, the hand-over's look, the rigs of the short barges, a hero pushed off
a barge leaving past the left edge; the taken pad carried by the magnet; a
hero riding a knocked barge and jumping off it.

## Game.Magnet

State: written, 22 tests (19 of 3.0.121, stage 18d-2; 2 of 3.0.123, stage
18d-3 - the window told over, the wait; 1 of 3.0.125, stage 18d-4 - tucked
in). Needs no
stage: `TMagnet` only counts. The unit is tried by
`Tests\Game\Tests.Game.Magnet.pas`, fixture `TMagnetTests`.

Shared: the face stands at 256, 190; the hero's middle at 200, 320, the
harbour at 256, 352; the barges are 67 wide - the near one (number 3)
under the face 40 lower, the low one (5) under it 90 lower, the far one
(7) at the left edge, in sight and out of reach. `Step` ticks the magnet
and adds up its cues; `StepTill(stage, limit)` steps till a stage;
`BringOut` deploys and steps till it seeks; `CatchNear` brings it out and
steps till the near barge is caught. "A cycle" is 330 ticks.

Numbers spelled: none of the timings, gaps or the reach - all first
guesses; the tests bound them (a breath of more than a tick; under the face
by less than half a rider's height; a window of 1 to 6 s) or read the
unit's constants (`RiderHeight`, `NoBarge`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestStowedItDoesNothing` | a cycle of ticks with a barge under it: stowed, not out, no cue, not soft, holds nothing | the magnet fights before the fight is started |
| `TestDeployedItWaitsThenSlidesOutAndTellsItsStartOnce` | deployed: it is not out till its start is told, more than a tick later; it never slides back; out by the time it seeks; the start told once, and not again in a cycle | the fight starts the tick he lands, the magnet jumps out, or the barge is let go twice |
| `TestDeployedTwiceItComesOutOnce` | a second `Deploy` ten ticks in: it seeks as soon as one deployed once | the game's word every tick restarts the breath for ever |
| `TestItCatchesTheNearestBargeInReach` | the low and the near barge in sight: one catch, the near one's number, its load, held, no lift | it takes the farther barge, or tells the caller the wrong number |
| `TestByItsRuleItTakesHisBargeFirst` | `mrHisBarge`, he on the low barge: the low one, a lift; `mrNearest`, the same sight: the near one | the rule of the tier is not obeyed: no lift at tier 2, or one at tier 1 by design |
| `TestABargeOutOfSightIsNotTaken` | a barge whose middle is past the right edge, the face beside it, a cycle: no catch, nothing wanted | a barge is plucked from beyond the screen's edge |
| `TestOutOfReachItOnlyWantsTillItsFaceIsOverIt` | the far barge alone, a cycle: no catch, it wants to be over the middle of its deck; the face moved there: caught on the next tick, nothing wanted | the beam reaches across the whole screen, or the Ram is never sent for a barge |
| `TestTheBargeIsDrawnUpSmoothlyToJustUnderTheFace` | from where it was caught, every tick: the way is what it went, less than 8 units, never down; held: its middle under the face, its deck under it by less than 16 | the barge jumps to the magnet, sinks on its way, or hangs off to a side |
| `TestInALiftItStopsARidersHeightLower` | caught with him aboard: a lift; held, a rider's head is under the face by less than 16 | the lift puts his head into the magnet, or leaves him too far to strike point-blank |
| `TestTheHeldBargeRidesWithTheFace` | held, the face moved 1.5 across and 0.5 up a tick for 10 ticks: the way is the face's | the shield is left behind as the hull flies |
| `TestItSeizesThenThrowsAtTheHero` | the seize comes before the throw, never by way of seeking: the held barge's number, no press, snug under the face, the barge no more the magnet's, no way left; the hero moved, then the throw: once, at where he is at the throw | the pad is carried on after it became a wreck, the throw aims at where he was at the catch, or comes twice |
| `TestALiftEndsInAPress` | caught with him aboard: the seize is a press | the lift does him no harm |
| `TestWithNoHeroItThrowsAtTheHarbour` | he dead at the throw: the aim is the harbour | a throw at the corner of the screen where a dead hero's body was |
| `TestOneBargeAtATime` | two barges in sight: one catch till the throw | it reaches for a second barge while it holds one |
| `TestSoftFromTheHoldTillItIsCold` | not soft seeking nor on the barge's way up; soft at every stage from the hold till it seeks again; then not | the window opens early, closes before the heat is gone, or never closes |
| `TestItHeatsAsItHoldsAndCoolsThroughItsWindow` | cold on the way up; in the hold the heat never falls and is full by its end; in the window it never rises and is none at its end; the window lasts 1 to 6 s | the tint is not the window's timer |
| `TestColdAgainItTakesTheNext` | after a window, the low barge left in sight: a second catch, its number | one cycle and the magnet is done |
| `TestAClearStowsIt` | a clear in the hold: stowed, not out, cold, not soft, no load, and nothing told in a cycle | a death leaves a hot magnet holding a barge of the flock that is gone |
| `TestDeckDistanceIsToTheNearestPointOfTheDeck` | a face 30 over a deck - 30; 40 past either end of it and 30 over - 50 | the reach is measured to a barge's corner or middle: wide barges are out of reach under the face |
| `TestItTellsItsWindowOverOnce` (3.0.123) | a barge caught: not told while it cools; told as it seeks again; once in a cycle more | the mortar's turn begins mid-window, or after every tick of the seek |
| `TestToldToWaitItTakesNoBargeTillTheWaitIsLifted` (3.0.123) | out, the near barge in reach, told to wait: a cycle seeking, nothing caught, cold; the wait lifted: caught on the next tick | the lift meets the mortar's shells, or the magnet never comes back after a turn |
| `TestToldToTuckInItSlidesInAndOutTakingNothingTillOut` (3.0.125) | out, the near barge in reach, tucked: never out more, in the belly within the slide and ten ticks, nothing caught, cold; let out: never in again, nothing caught on the way, out in `DeploySlideTicks`; then it takes the barge | the magnet hangs out under a hull that rams across the lanes, or snatches a barge as it slides out |

Left to the eye: the whole of it on the screen - the pick as he hops
between barges, the beam, the lift and the press, the throw against his
dodge, the heat.

## Game.Mortar

State: written, 13 tests (3.0.123, stage 18d-3). Needs no stage: `TMortar`
only counts. The unit is tried by `Tests\Game\Tests.Game.Mortar.pas`,
fixture `TMortarTests`.

Shared: the pivot at 300, 60; his feet at 240, 240, on a deck unless a
test says not; no shell aloft unless a test says so. `Step` ticks the
mortar and adds up its cues; `StepTill(stage, limit)`, `StepTillLob(limit)`.
"A turn" is 330 ticks.

Numbers spelled: none - the timings are read from the unit's constants
(`MortarRiseTicks`, `MortarAimTicks`, `MortarWaitTicks`, `MortarGapTicks`,
`MortarFoldTicks`, `MortarKickTicks`, `MortarTiltMost`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestFoldedItDoesNothing` | a turn's ticks unbegun: folded, not out, no cue, not busy | shells from a mortar nobody gave a turn |
| `TestGivenATurnItRisesAndTellsItOnce` | a turn of two: it only rises, out in its rise, the rise told once, no shell while it rises | the mortar pops out, or its sound plays every tick |
| `TestOutItLobsAtHisFeetOnceAimed` | out: a lob as soon as it is aimed, at his feet; one shell left | it lobs at once with no warning, or at where he is not |
| `TestOneShellAtATime` | a shell aloft through a turn's ticks: no second lob, waiting | a pair of shells - never in the air fight |
| `TestTheNextShellComesAGapAfterTheLastIsGone` | the shell gone: the next after the gap and the aim exactly | the shells come at once after one another, or the gap counts from the lob |
| `TestHeStandsLateItLobsThen` | he in the air through the aim and half the wait: nothing; standing: a lob that tick | a shell is lobbed at a hero in the air, with no deck to ride |
| `TestHeStaysInTheAirTheShellIsGivenUp` | in the air the whole wait: one tick short both shells are left, at its end one is given up, nothing lobbed, the next aimed | a hero who keeps jumping stalls the fight for ever |
| `TestItsShellsSpentItFoldsAndTellsIt` | a turn of one: folding after its shell is gone, folded in its fold, told once, behind the block | the turn never ends, and the magnet never comes back |
| `TestBusyThroughItsTurn` | busy from the turn's start to the fold; two shells | the magnet takes a barge in the middle of a turn |
| `TestItLeansTowardHisFeetNeverPastItsMost` | `MortarTilt`: upright over him, its most far right and far left; aiming at a hero far right: never past its most, at the end leaning right near it | the tube points away from him, or lies flat |
| `TestALobKicksItAndTheKickDies` | at the lob the kick is full, a few ticks on none | the mortar stays sunk after a shot |
| `TestATurnIsNotBegunTwiceNorWithNoShells` | no turn of no shells; a second turn mid-turn: the shells left and the stage kept | the magnet's window gives the mortar a second rise mid-turn |
| `TestAClearFoldsIt` | a clear mid-turn: folded, no turn, no shells, behind the block, upright | a death leaves the mortar up and aiming |

Left to the eye: the mortar on the hull - its rise from behind the block,
the lean, the kick, the fold - and its sound under the jets.

## Game.Shells: aloft

State: written, 6 tests (3.0.123, stage 18d-3): fixture `TShellsAloftTests`
in `Tests\Game\Tests.Game.Shells.pas`, beside the chase's.

Shared: the shells with no road (the chase's road line, 352, given and
switched off); the mortar's muzzle at 300, 12; a small barge 104 wide at
160, its deck at 230; the carrier 3, the rise 20. `Fly(deck, way)` moves
the deck and tells the shells.

| Test | Holds | Turns red when |
|---|---|---|
| `TestItRidesItsBargeAndBurstsOnIt` | the barge flying 1.5 left and 0.4 down a tick: the burst on it, where it was aimed on the deck as it has flown, on its top | the shell is aimed at where the barge was and falls into the abyss behind it |
| `TestAnotherBargesWayIsNotItsOwn` | another carrier's way and the road's told every tick, the barge still: the burst where it was aimed | a shell rides every barge's way at once |
| `TestWithNoRoadItFallsPastTheBottom` | aimed at the road's line over nothing: no ring, never landed, never burst, gone past the bottom edge | a shell rolls along an invisible road in the sky |
| `TestWithNoRoadTheRingLiesOnlyOnADeck` | a deck under the arc: a ring on it; the deck gone: no ring | the ring stays on the empty air where a barge was |
| `TestTheRingIsDrawnBetweenTicksAsItsDeckFlies` | five ticks of a barge flying 2 left: the ring went 2 this tick | the ring jumps a step a tick behind its deck |
| `TestALowerArcOfItsOwn` | from 100 onto the barge: a rise of 10 tops more than 15 lower than the bunker's 40 | the air's arc climbs as high as the chase's, its top far over the screen |

## Game.Pieces

State: written, 10 tests (3.0.121, stage 18d-2). Needs no
stage: `TBargePieces` only counts, and a barge of no pad has no picture.
The unit is tried by `Tests\Game\Tests.Game.Pieces.pas`, fixture
`TBargePiecesTests`.

Shared: a barge 104 by 14 with its middle at 256, 330; the dice 11.
Numbers spelled: none.

| Test | Holds | Turns red when |
|---|---|---|
| `TestNothingTillABargeBreaks` | none, none in the air, a tick changes nothing | pieces from nowhere |
| `TestItBreaksIntoPiecesOfItsWholePicture` | at least four pieces, in the air; every part inside the picture; the parts add up to the picture once, the pieces to the barge's area | a barge breaks into one piece, a strip of it is lost or drawn twice |
| `TestEachPieceStartsWhereItWasInTheBarge` | unturned: each piece's middle where its part lies in the barge | the pieces start in a heap at the middle, or mirrored |
| `TestATurnedBargeBreaksTurned` | turned a quarter: each piece turned so, the barge's length running down the screen | a tumbling barge snaps level as it breaks |
| `TestTheyTumble` | a tick on: every piece has turned by more than a degree | flat pieces sliding off |
| `TestTheyKeepAShareOfTheBargesWay` | of two barges of the same dice, one going right at 10: a tick on each of its pieces is farther right than its twin, by less than 10 | the pieces stop dead where the barge struck, or fly on as fast as it came |
| `TestTheyFallAndAreGoneSoon` | within 200 ticks: none in the air, the list empty, and they went down past the bottom edge | pieces hang over the main barge, or pile up in memory through a long fight |
| `TestASecondBargeBreaksWhileTheFirstFalls` | a second barge a tick after the first: twice the pieces | the second break wipes the first one's pieces |
| `TestAClearTakesThemAway` | a clear: none | a death leaves pieces falling over the restart |
| `TestSameDiceSameFlight` | two of the same dice, 20 ticks: the same places and turns | the pieces read `Random` |

Left to the eye: the pieces' picture, their look against the barge.

## Game.Ram: the magnet

State: written, 18 tests (12 of 3.0.121-3.0.122, stages 18d-2 and the
honeycomb; 6 of 3.0.123, stage 18d-3 - the rungs and the mortar): fixture
`TRamMagnetTests` in `Tests\Game\Tests.Game.Ram.pas`. The magnet's own
rules are tried in `Tests.Game.Magnet`; here, what the Ram does with it.

Shared: the body and the orders of the other fixtures; `HangWithTheMagnetOut`
starts it hanging over a point, deploys and ticks till the magnet seeks;
`BargeUnderTheFace` - a barge 67 wide under the face, 40 lower.

| Test | Holds | Turns red when |
|---|---|---|
| `TestOnTheRoadTheMagnetStaysStowed` | past the bunker on the road, told to deploy on every one of 400 ticks: no start, stowed | a magnet under a hull that drives |
| `TestHangingAndToldItComesOutAndTellsItsStart` | hanging and not told, 400 ticks: no start, stowed; told: the start once in 400 ticks, out | the Ram deploys by itself, or the game never hears the start |
| `TestItCatchesTheBargeUnderItsFace` | the magnet out, a barge under the face told with the hero: a catch with its number, held | the barges of the target never reach the magnet, or its face is not where the hull's is |
| `TestWantingABargeTheHullFliesOverIt` | hanging at 400, he at the right, the only barge at the left edge: within 800 ticks a catch, the hull's middle more than 100 left of where it hung | the hull stays over the hero and the fight stalls with every barge out of reach |
| `TestABulletFromUnderMeetsTheMagnetBetweenTheNozzles` | straight up along the hanging hull: one run of hits 24 to 36 wide, each from below more than 8 under the hull's bottom (at its very sides the rocking hull may take one through a side face), its middle within a quarter of the hull of the hull's | the magnet's box is not where its picture is, or as wide as the belly |
| `TestStowedNoMagnetToMeet` | hanging, the magnet stowed: no hit anywhere along the hull | orbs ring off a magnet that is not there |
| `TestTheMagnetIsSoftOnlyWhileHot` | a strike into the face is met at every stage; the magnet is not soft while it seeks, soft in the hold, not soft once it seeks again | the hull can be hurt at any time - the gallery of 17a - or never |
| `TestTheMagnetIsNoBodyToTouch` | a box under the hull's bottom, wholly within the magnet: not in the hull | a hero on a high lane is wounded by the magnet's side |
| `TestAClearStowsTheMagnet` | a clear with the magnet out: stowed, not out | a death leaves the magnet out, and the fight starts without its start |
| `TestHangingItsHoneycombIsUp` (3.0.122) | hanging: the hull's honeycomb and the ring up; a bullet into the side of the risen hull is taken at its side; a clear: down | the restart aloft finds the hull bare, or the honeycomb is met where the hull stood on the road |
| `TestUnderTheHoneycombNothingIsBare` (3.0.122) | the honeycomb up, straight up along the hanging hull: wherever the magnet or a nozzle would take a bullet, `Block` takes it | sparks and a ricochet off the machine through the honeycomb - its outline leaves the nozzles' tips or the magnet's corners bare |
| `TestTheHoneycombFallsWithTheSoftMagnetAndComesBack` (3.0.122) | a barge caught: as the magnet grows soft both fall, the fall told once; on to the next seek: no second fall, the return told once, both kindling | the honeycomb stands over a soft magnet - the window hidden - or never comes back |
| `TestTheRungsFollowTheHullsSpentLives` (3.0.123, reworked 3.0.127) | none spent: rung 1; a hair short of each door of `AirTierSpent`: the rung below, at it: its rung; all spent: the top rung | the ladder counts lives left for lives spent, or a rung by its upper bound |
| `TestFromTheLiftsRungTheMagnetTakesHisBargeFirst` (3.0.123) | none spent: the nearest; the lift's rung: his barge first | the lift comes on the first rung, or never |
| `TestOnTheFirstRungNoMortar` (3.0.123) | none spent, 1200 ticks, at least two windows: no rise, no lob, folded | the bombs come before the player has learnt the thrown barges |
| `TestFromTheBombsRungTheMortarHasATurnAfterTheWindow` (3.0.123) | the bombs' rung: nothing till the window is over; then the rise, busy; through the turn the magnet seeks and catches nothing; the rung's lobs (`MortarShells`, two) at his feet out of a muzzle over the hull; folded, the magnet catches again | the shells meet the lift, come mid-window, aim off his feet, or the magnet is never given back the turn |
| `TestTheMuzzleStandsOverTheHull` (3.0.123) | hanging: the muzzle over the hull's top by more than 15, within the hull across | shells come out of the hull's middle |
| `TestAClearFoldsTheMortar` (3.0.123) | a clear mid-turn: not busy, not out | a death leaves the mortar up |

## Game.Shield: restored, afloat, hidden

State: written, 5 tests (3.0.122): fixture `TShieldRestoreTests` in
`Tests\Game\Tests.Game.Shield.pas`, beside `TShieldCrumbleTests`.

Shared: the crumble fixture's ellipse 40 by 20, vanished; a solid body 40
by 20.

| Test | Holds | Turns red when |
|---|---|---|
| `TestRestoredItHoldsAtOnceAndComesUp` | restored over 12 ticks: rising, holding before a tick; up, in no fewer than 12 | the window stays open while the cells kindle, or it never comes up |
| `TestOnlyADownShieldIsRestored` | up: stays up; falling: the fall goes on | a restore cuts a fall short, or restarts a whole shield |
| `TestARisingShieldFalls` | a tick into the rise, a fall: falling, holding no more, then down | a window that opens during the kindle is shut |
| `TestAfloatItHoldsUnderTheBody` | just under the body's bottom: no shield over a standing body, a shield under one afloat | the flying hull's belly is bare |
| `TestHiddenCellsHold` | every cell hidden: it holds | hiding cells over the fire opens a hole in the armour |

## Game.Wrecks: the fling

State: written, 6 tests (3.0.121, stage 18d-2): fixture
`TPadFlungTests` in `Tests\Game\Tests.Game.Wrecks.pas`.

Shared: a barge 104 wide held at 256, 195 - under the hanging hull - and
flung at 180, 336, a hero on the main barge. Numbers spelled: none.

| Test | Holds | Turns red when |
|---|---|---|
| `TestItPassesCloseByItsMark` | within 45 ticks its way passes within 20 of the mark | the throw is not aimed |
| `TestPastItsMarkItNeverTurnsBack` | once it recedes from the mark it never comes nearer again | a dodged barge circles the place he stood, as a hurled pad would |
| `TestAMissIsGoneOffTheScreen` | within 200 ticks: gone, none in the air | a missed barge flies on unseen for ever |
| `TestFlungDownItIsGoneUnderTheScreen` | flung straight down: gone, under the screen | the bottom edge is no edge, as for the wave's wrecks |
| `TestItTumblesWhateverTheHeldSpinIs` | the same pad of the same turn with the held spin 0 and 20: it turns more than a degree a tick, alike both times | a barge thrown outside the henshin flies stiff, or spins as a propeller with the last scene's spin |
| `TestAWreckNotHeldIsNotFlung` | a wave's wreck flung: not hurled, not flung | any wreck can be re-aimed |

## Game.HullLives: the bar's heat

State: written, 4 tests (3.0.121, stage 18d-2), beside the 7
of 3.0.116 in `Tests\Game\Tests.Game.HullLives.pas`, fixture
`THullLivesTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestArmouredTillAPartIsHot` | armed, 1000 ticks with nothing hot: not hot, no pulse; a tick with a hot part: hot; a tick with none: not hot, no pulse | the bar pulses over an armoured hull, or stays hot after the window |
| `TestHotTheBarPulses` | two pulses' ticks hot: the pulse within 0 and 1, seen under 0.2 and over 0.8 | the bar stands still while the hull can be hurt |
| `TestANewHeatStartsThePulseAnew` | five ticks hot, two not, five hot: the second five read as the first | a window opens in the middle of a pulse, dim |
| `TestArmingAndAClearLeaveItArmoured` | armed anew while hot, and cleared and armed: not hot | a restart shows a hot bar over a stowed magnet |

## Game.Charge

State: written, 13 tests (3.0.125, stage 18d-4). Needs no stage:
`TCharge` only counts. The unit is tried by
`Tests\Game\Tests.Game.Charge.pas`, fixture `TChargeTests`.

Shared: a hull 169 wide; begun from a hang with its left edge at 170, at
rest, at `HangLift`, its corridor at a lift of 56. `Step` ticks it and
adds up its cues; `StepTill(stage, limit)`. "A charge" is 500 ticks.

Numbers spelled: the hull's width, its place and the corridor's lift - the
caller's; the rest is read from the unit's constants (`ChargeWarnTicks`,
`ChargePace`, `ChargeLeaveMost`, `ChargeBeyond`, `ChargeHoldInset`,
`ChargeRamPace`, `ChargeBrakeBow`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestNotBegunItDoesNothing` | a charge's ticks unbegun: not running, nothing told, not low, not ramming, not soft, the flock not held | a charge from a Ram nobody gave the turn |
| `TestItFallsBackPastTheLeftEdgeEverFaster` | leaving: the pace never gains to the right, never past its most to the left, at its height while seen; its fall back told once; off past the left edge | the Ram jumps off the screen, or drops before it is gone |
| `TestOutThereTheBandBlinksAtItsCorridor` | the band told once, down to its corridor, the corridor told; through the band out there, standing, the band lit and dark; in after its while, the band gone | no warning, a band that does not blink, or one that lasts into the pass |
| `TestItRushesInAtItsPace` | the rush told once, at its pace at once, coming in; at its pace through the pass | it creeps in, or comes in from nowhere |
| `TestItBrakesShortOfTheRightEdgeSlowingAllTheWay` | the brake told once, fast as it starts; slowing every tick, never back, never past where it stops; at a stand with its right edge just inside the screen's | the brake overshoots off the right edge, jerks, or stops mid-screen |
| `TestItRamsInThePassAndTheFastPartOfTheBrakeOnly` | ramming only in the pass and the brake, and only at its ram pace or faster; it does ram | the hero is struck by a hull that hangs still, or never |
| `TestLowFromThePassTillItClimbs` | low exactly in the pass, the brake and the hold, at its corridor then | the barges are smashed by a hull out of the lanes, or spared by one in them |
| `TestHotFromTheBrakeCoolingAsItHolds` | soft as it brakes; hot as it stops; soft and cooling every tick of the hold; hard and cold as it climbs | no window, or one that stays open as it climbs |
| `TestItsBowDipsInThePassAndIsThrownUpInTheBrake` | bow down in the pass; bow up past half its brake's lean as it stops | a charge that flies flat - the brake does not read |
| `TestItClimbsToItsHeightLevelAndIsDone` | never down in the climb, straight up; done told once, not running, at its height, level; still once after a charge's ticks | the hull is let go mid-air or tilted, and jumps as it hangs again |
| `TestItHoldsTheFlockFromTheBandTillItIsUp` | the flock held exactly from the band to the climb | a barge comes in through the low hull, or none ever again |
| `TestAStartWhileItChargesIsNothing` | a start in the pass: still in the pass, where it was | a second window restarts a charge mid-run |
| `TestAClearStopsIt` | a clear in the brake: not running, not soft, not low, the flock not held, cold | a death leaves the hull low and hot |

Left to the eye: the charge on the screen - the band and the eye, the
rush, the brake's swivel and fire, the heat of the nozzles - and its
three sounds.

## Game.Takeoff: the carry and the swivel

State: written, 6 tests (3.0.125, stage 18d-4), beside the takeoff's own
in `Tests\Game\Tests.Game.Takeoff.pas`, fixture `TTakeoffTests`.

Numbers spelled: the corridor's lift 56, a run of 20 a tick, a loss of 0.8
a tick; the swivel's most is read (`SwivelMost`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestCarriedItIsWhereItIsTold` | hung, a tick, carried: carried, aloft, its pace, height and lean as told, between the ticks on its way there; a tick told nothing, the hero far: where it was put | the charge's hull is pulled back over the hero, or jumps between the ticks |
| `TestLetGoItHangsOnFromItsHeight` | carried to its height and let go: hanging, ten ticks with no step of half a unit, about its height | the hull jumps as the charge hands it back |
| `TestOnItsWayUpItCannotBeCarried` | rising: a carry moves nothing, still rising, not aloft; a release is nothing | a charge begun mid-takeoff tears the hull off its rise |
| `TestGoingRightTheNozzlesSwingBackNeverPastTheirMost` | carried right at 20 for 40 ticks: never past its most; swung clockwise past half of it | the nozzles turn into the actuators painted fixed, or stay straight in the pass |
| `TestAHardBrakeThrowsTheNozzlesAhead` | then losing 0.8 a tick for 15 ticks, still going right: never past its most; swung the other way past half of it | the brake's fire still pushes it on |
| `TestOnTheRoadTheNozzlesDoNotSwivel` | from the start of a takeoff, the hero far: straight down every tick | the nozzles wag as they come out of the arches |

Left to the eye: the swivel in the hang - whether it reads.

## Game.Ram: the charge

State: written, 7 tests (3.0.125, stage 18d-4): fixture `TRamChargeTests`
in `Tests\Game\Tests.Game.Ram.pas`. The charge's own rules are tried in
`Tests.Game.Charge`; here, what the Ram does with it.

Shared: the body and the orders of the other fixtures; the hero aboard
over the middle, the main barge's deck at its highest 16 over the road's
line; `HangReady` (`HangWithTheMagnetOut`, shared with the dive's
fixture) starts it hanging, brings the magnet out and puts a barge under
its face; `TickTillCharge`; `RunTheCharge(hero, body)` ticks
the charge to its end, adding up what it did and asking for a strike of
`body` every tick (`HullSweep`, `HullStrikes` since 3.0.126 - the charge's
and the dive's).

| Test | Holds | Turns red when |
|---|---|---|
| `TestBeforeItsRungNoCharge` | a hair short of the charge's rung, 1500 ticks, at least two windows: never a charge | the charge comes on the second rung |
| `TestOnItsRungTheChargeFirstThenTheMortarThenTheCharge` | on its rung: the charge first, not the mortar; after it the mortar, never two charges; after the mortar the charge again | the mortar is never given a turn again, or the charge comes back to back |
| `TestTheMagnetTucksInForTheCharge` | in the belly while it charges; out again after, nothing caught on its way out | the magnet hangs under the ramming hull |
| `TestItFliesOffAndBackLowOverTheHarbourAndUpToHang` | off past the left edge, across past the middle, never off the right edge; in, braked and done once each; it swept low; its bottom within 20 under a rider's head at the harbour's highest, never down to it; hanging at its height after | the corridor covers the main barge's deck, misses the lanes, or the hull is lost off the screen |
| `TestItsSweepStrikesAHeroInItsCorridorOnce` | a hero on a lane in the middle: struck once, knocked along its way | the charge passes through him, or wounds him every tick it overlaps |
| `TestAHeroOnTheMainBargeIsUnderItsCorridor` | a hero on the deck at its highest at 40, 240 and 440, a charge each: never struck | the main barge is no harbour |
| `TestAfterTheBrakeTheNozzlesAreHotAndTheHoneycombFalls` | hot from the brake; the honeycomb fell and kindled back once each; cold once it is up | the window after the charge is hidden under the honeycomb, or never shuts |

## Game.Dive

State: written, 11 tests (3.0.126, stage 18d-5). Needs no stage: `TDive`
only counts. The unit is tried by `Tests\Game\Tests.Game.Dive.pas`,
fixture `TDiveTests`.

Shared: begun from a hang at `HangLift`, drifting right at 1.5, its bow 3
down; its floor at a lift of 40, told every tick (`FFloor`, moved by one
test). `Step` ticks it and adds up its cues; `StepTill(stage, limit)`. "A
dive" is 330 ticks.

Numbers spelled: the hang's pace, bow and the floor - the caller's; the
rest is read from the unit's constants (`DiveSag`, `DiveRelightTicks`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestNotBegunItDoesNothing` | a dive's ticks unbegun: not running, no cue, no flash, not falling, not low, not soft, the flock not held | a dive from a Ram nobody gave the turn |
| `TestTheSilenceFlashesAndOnlySags` | through the silence: the eye flashes, its way across dies out, it never rises and sags no more than `DiveSag`, not low, not hot, not striking; the silence told once, then the fall; straight down from there, the flash over | no warning at all, a warning that drags, or a hull that drifts on across as it falls |
| `TestItFallsEverFasterNeverPastItsFloor` | every tick of the fall faster than the last, straight down, never past its floor; the blow told once, on its floor, falling over 10 a tick at the end | a fall that floats, or a hull that sinks into the main barge |
| `TestItStrikesOnlyWhileItFalls` | striking exactly in the fall | a hero struck by a hull that hangs low and still, or never |
| `TestLowItRidesTheFloor` | low, the floor raised 20, then lowered again: 30 ticks later on it each time | the hull stays put as the main barge rises into it, or floats off as it dips |
| `TestItsJetsCatchAFewTicksOnThenItIsHotAndCools` | not hot the tick it lands nor before its jets catch; they catch `DiveRelightTicks` after the blow, told once; hot at full then, soft and cooling all the hold; hard and cold as it rises | no window, one open in the silence, or one that stays open as it rises |
| `TestItRisesToItsHeightLevelAndIsDone` | never down on the way up; done told once, not running, at its height, level | the hull is let go mid-air or tilted, and jumps as it hangs again |
| `TestLowFromTheFallTillItRises` | low exactly in the fall and the hold | small barges smashed by a hull out of their lanes, or spared by one in them |
| `TestItHoldsTheFlockFromTheSilenceTillItIsUp` | the flock held from its start while it runs, not once it is up | a barge comes in under the low hull, or none ever again |
| `TestAStartWhileItDivesIsNothing` | a start in the hold: still low, where it was | a second window restarts a dive mid-run |
| `TestAClearStopsIt` | a clear in the hot hold: not running, not soft, not low, the flock not held, no flash, cold | a death leaves the hull low and hot |

Left to the eye: the dive on the screen - the flash, the jets dying and
catching, the fall, the blow and the shake - and its four sounds.

## Game.Takeoff: the jets put out and lit again

State: written, 3 tests (3.0.126, stage 18d-5), beside the takeoff's own
in `Tests\Game\Tests.Game.Takeoff.pas`, fixture `TTakeoffTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestPutOutTheFireIsGoneInAFewTicksAndStaysOut` | hung, put out: the fire dying, never back, both out in 6 ticks; out still 600 ticks later, aloft all the same | the jets flicker back by themselves in the silence, or cut off at once with no fade |
| `TestLitAgainTheJetsCatchFlaring` | out for 10 ticks, lit: a flare past 1, both steady at 1 within 30 ticks | the relight is a switch, not a catch |
| `TestOnItsWayUpTheJetsCannotBePutOut` | rising, put out: both still burn 10 ticks on | a dive begun mid-takeoff drops the rising hull |

## Game.Ram: the dive

State: written, 7 tests (3.0.126, stage 18d-5): fixture `TRamDiveTests`
in `Tests\Game\Tests.Game.Ram.pas`. The dive's own rules are tried in
`Tests.Game.Dive`; here, what the Ram does with it.

Shared: the body and the orders of the other fixtures; the hero standing
on the main barge over the middle, its deck 6 over the road's line where
the game says it is now (`Harbour`), 16 over at its highest;
`HangWithTheMagnetOut`; `TickTill(hero, whose)` - ticks till the dive,
the charge or the mortar has its turn, failing if another comes first;
`TickOut(hero, whose)` - while it lasts; `RunTheDive(hero, body)` ticks
the dive to its end, adding up what it did and asking for a strike of
`body` every tick.

| Test | Holds | Turns red when |
|---|---|---|
| `TestBeforeItsRungNoDive` | a hair short of the dive's rung, 3000 ticks, at least two windows: never a dive | the dive comes on the charge's rung |
| `TestOnItsRungTheDiveFirstThenNotTheDive` (reworked 3.0.127) | on its rung: the dive first, with no other on the way; after it, the charge or the mortar before any dive | the newest weapon is not seen alone first, or the dive comes back to back |
| `TestTheEyeFlashesTheJetsGoOutAndTheMagnetTucksIn` | its eye at full in the silence, both jets out, the magnet in the belly; lit again once, burning as it hangs after | the dive comes with no flash, with the jets burning, or leaves them out |
| `TestItDropsOverTheHeadOfAHeroOnTheMainBargeAndHangsAgain` | its bottom within 20 over the head of a hero standing on the deck where it is, never down to it; landed and done once; that hero never struck; hanging at its height after | the dive crushes the main barge's rider, or stops high over him |
| `TestItsFallStrikesAHeroUnderItOnce` | a hero on a lane under the left half of the hull: struck once, knocked left - away from its middle | the fall passes through him, wounds him every tick, or throws him under the hull |
| `TestLowItsFireBurnsUnderANozzleNotUnderTheBelly` | before its jets are hot no fire anywhere under it; hot: none under the middle of the belly nor past the bow, some under a nozzle, a hero burnt there thrown aside; none once it is up | the window has no place to stand, the fire burns before it is lit, or it burns on after |
| `TestAfterTheBlowTheNozzlesAreHotAndTheHoneycombFalls` | hot after the blow; the honeycomb fell and kindled back once each; cold once it is up | the window after the dive is hidden under the honeycomb, or never shuts |

## Game.Charge: through

State: written, 1 test (3.0.127, stage 18d-6), beside the charge's own in
`Tests\Game\Tests.Game.Charge.pas`, fixture `TChargeTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestThroughItIsGonePastTheRightEdgeAtItsPace` | begun to go through: from the pass on never braking nor hot, at `ChargePace` every tick it runs; then past the right edge, gone told once, no brake and no climb told, the flock let go; still once 500 ticks on | the finisher brakes at the edge, stops short, or is told gone twice |

## Game.Dive: from above

State: written, 3 tests (3.0.127, stage 18d-6), beside the dive's own in
`Tests\Game\Tests.Game.Dive.pas`, fixture `TDiveTests`. Over the top edge is
a lift of 376, as the finisher puts it.

| Test | Holds | Turns red when |
|---|---|---|
| `TestFromAboveTheBandBlinksStillThenItFalls` | begun from above: the band first, `DiveMarkTicks` long, still up there with no way across, nothing of a dive yet but the flock held, the band lit; told once; no silence; then the fall told, the band out, from a standstill | the finisher falls with no warning, drifts while it warns, or flashes an eye that is off the screen |
| `TestFromAboveItGoesOnAsAnyDive` | from above: ever faster, never past its floor; the blow, the relight and the rise once each, at its height after | the drop from the sky ends anywhere but just over the main barge |
| `TestAStartFromAboveWhileItDivesIsNothing` | a start from above in the fall: still falling, where it was | a finisher's drop snatches a dive mid-fall up off the screen |

## Game.Takeoff: settled

State: written, 2 tests (3.0.127, stage 18d-6), beside the takeoff's own
in `Tests\Game\Tests.Game.Takeoff.pas`, fixture `TTakeoffTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestSettledItIsWhereItWasPutBetweenTheTicks` | carried at a run, swivelled; carried over the top edge, level, and settled: there and level at the last tick too, still, the nozzles straight then and now | the hull streaks across the screen between two ticks as it is put over the top edge, or swings its nozzles there |
| `TestHangingSettlingIsNothing` | hanging, settled: still hanging, its pace and its last height kept | a hanging hull stops dead between ticks |

## Game.Magnet: tucked while it cools

State: written, 1 test (3.0.127, stage 18d-6), beside the magnet's own in
`Tests\Game\Tests.Game.Magnet.pas`, fixture `TMagnetTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestToldToTuckInWhileItCoolsItsWindowIsLost` | a barge thrown, a tick into the window: soft; tucked: seeking, not soft, no heat at once; in the belly 30 ticks on; no window told | the chained dive comes down with a hot magnet out under it, or the lost window still gives the slot a turn |

## Game.Flock: grown

State: written, 2 tests (3.0.127, stage 18d-6), beside the flock's own in
`Tests\Game\Tests.Game.Flock.pas`, fixture `TBargeFlockTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestGrownMoreFlyNeverMoreThanTheNewCount` | started at 2, the escort in, grown to 4: the count is 4; four minutes never more than 4 flying, more than 2 at some time | the ladder's rungs leave the flock at two, or overfill it |
| `TestGrownToFewerOrBeforeTheStartNothingChanges` | grown before the start: not started, no count; started at 3, grown to 2: still 3 | a growth starts the fight's flock, or a lower rung after a restart thins it |

## Game.HullLives: resumed

State: written, 2 tests (3.0.127, stage 18d-6), beside the others in
`Tests\Game\Tests.Game.HullLives.pas`, fixture `THullLivesTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestResumedTheLivesAreThoseToldWithinTheFull` | armed at the first grade, resumed at 160: those lives, the full kept, the bar's share by them; resumed past the full: the full; below none: none | point C brings the hull back whole, or past whole |
| `TestNotArmedAResumeIsNothing` | not armed, resumed: not armed, no lives | a death in the road phase arms the hull |

## Game.Ladder

State: written, 17 tests (3.0.127, stage 18d-6). Needs no stage:
`TAirLadder` only counts. The unit is tried by
`Tests\Game\Tests.Game.Ladder.pas`, fixture `TAirLadderTests`.

Shared: a ladder seeded 7; the second rung at 0.2 spent, the third at
0.45, the last at 0.7, the finisher's stretch at 0.9; "many" is 200 asks.
`TurnsAt(spent, count)` asks one turn after another.

Numbers spelled: the spent shares of the rungs and the stretch, the tries;
the doors themselves are read from the unit (`AirTierSpent`,
`FinisherSpent`, `AirDoorTier`, `MortarShells`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestTheRungFollowsTheSpentLives` | none spent: 1; a hair short of each door: the rung below, at it: its rung; all spent: the top | a rung by its upper bound, or the ladder off by one |
| `TestTheFinishersStretchClosesTheLastRung` | short of `FinisherSpent`: not on it; at it: on it, and on the top rung | the finisher comes before the dive's rung, or never |
| `TestOnTheFirstRungNoTurn` | five asks at 0.1: none | the mortar before the player has learnt the thrown barges |
| `TestOnTheSecondRungTheMortarEveryTime` | five asks: the mortar each time | the rule of no repeats leaves the second rung with no turn |
| `TestOnTheThirdRungTheChargeFirstThenByTurns` | the charge first; then one of the two, never the same twice | the charge is not seen alone first, or two come back to back |
| `TestOnTheLastRungTheDiveFirstThenNeverTwiceInARow` | 200 asks: the dive first; each of the three, never the same twice | the dive is not seen first, or a weapon back to back |
| `TestOnTheLastRungEachWeaponComesNowAndThen` | 200 asks: all three came | a weapon of the rung never chosen |
| `TestOnItsStretchTheFinisherFirstThenAmongTheRest` | after the dive, on the stretch: the finisher first; never twice in a row; all four came | the finisher hidden among the others, or gone after its first |
| `TestNoChainBeforeTheLastRung` | at 0, 0.2, 0.45: 200 asks each, no chain | two threats at once before the last rung |
| `TestNoChainBeforeTheDiveIsSeen` | on the last rung, no turn yet: no chain | the dive comes chained before it was ever seen alone |
| `TestOnTheLastRungChainsComeNowAndThen` | after the dive: of 200 catches more than a fifth and fewer than four fifths chain; both chains came | chains every cycle, never, or only one of the two |
| `TestNoShieldChainInALift` | 200 catches in a lift: never the shells | the shells and the lift meet |
| `TestAChainCountsAsItsWeaponsTurn` | after a chain: the last turn is its weapon's, and the next turn not that weapon | a chained dive followed at once by a dive |
| `TestNoChainOnTheStretchTillTheFinisherIsSeen` | on the stretch before the finisher: no chain; then the finisher; then chains | a chain swallows the finisher's first turn |
| `TestAClearForgetsWhatWasSeen` | five asks, a clear: no last turn, the dive first again | a restart at point C skips the newest weapon's lone turn |
| `TestTheDoorOfPointCIsOnItsRung` | of 50, 240, 300, 360, 361: the door's lives are on its rung, a life more is the rung below | point C brings him back a rung below its door, or a life short |
| `TestTheMortarsShellsGoByTheRung` | two on the bombs' rung, one on the charge's and the last | the mortar's long turn of two shells on the mixed rungs |

## Game.Ram: the ladder

State: written, 4 tests (3.0.127, stage 18d-6): fixture `TRamLadderTests`
in `Tests\Game\Tests.Game.Ram.pas`. The ladder's choice is tried in
`Tests.Game.Ladder`; here, what the Ram does with it.

Shared: the body and the orders of the other fixtures, the hero of the
dive's fixture on the main barge; `HangWithTheMagnetOut`;
`TickTillChain(hero, chain)` ticks till a catch is told with that chain,
failing past 12000 ticks.

| Test | Holds | Turns red when |
|---|---|---|
| `TestAChainedDiveComesAtTheThrowAndTheWindowIsLost` | on the last rung, a throw-and-dive chain: no dive till the throw; the dive the tick it throws; the magnet not soft a tick on; through the dive no window told, nothing else; after it no turn till the next catch | the chain waits out the magnet's window, gives a second turn, or the magnet hangs hot under the dive |
| `TestAChainedShellIsLobbedWhileTheMagnetHoldsItsShield` | a shield-and-shells chain: a shield, not a lift; the mortar up at the catch; its one shell lobbed while the magnet holds, before the throw | the shells come in a lift, or only after the window |
| `TestTheFinisherGoesThroughAndDropsFromAboveOverTheHero` | on the stretch, the hero at 100: the finisher first; the charge never brakes and goes past the right edge; then over the top edge, the hull's middle over his, there between the ticks too, out of sight; the band blinked, its jets out up there; down to within 20 over the head of a hero on the main barge, never down to it; hanging after | the hull streaks across the screen, drops off where he is not, or crushes the main barge's rider |
| `TestTheHullWearsShortsAndSmokesByTheRung` | none spent: whole, no bolts, no smoke; short of the charge's rung: worn, no bolts, no smoke; at it: bolts and smoke; at the dive's: both more, no bursts; at the finisher's stretch: bursts; all spent: all worn, full bolts, full bursts, more than at the stretch's door | the damage shows before the charge, never, or not harder as the fight goes; the bursts come before the end |

## Game.Breakup

State: written, 13 tests (3.0.128, stage 19). Needs no stage: `TBreakup`
only counts. The unit is tried by `Tests\Game\Tests.Game.Breakup.pas`,
fixture `TBreakupTests`.

Shared: a breakup seeded 7, started from 40 across, 60 up, leaning 6, to
burst at 171.5 across and 184 up; 8 pieces unless a test says; `Throe`
ticks `ThroeTicks` and gives the cues, `Series` ticks till it is over,
failing past 400 ticks.

Numbers spelled: the places and the pieces, the shudder's 4 degrees and
the jets' last 8 dead ticks; the ticks of the throe, the small blasts and
the series' gaps are read from the unit (`ThroeTicks`, `ThroePops`,
`SeriesFirstTicks`, `SeriesGapLeast`, `SeriesGapMost`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestWholeItDoesNothing` | 66 ticks unstarted: no cue, idle, neither running nor broken | the hull bursts by itself |
| `TestItCracksOnceAtOnce` | started: running, not broken; the crack on the first tick, never again | the crack's flash and groan come late or twice |
| `TestTheThroeTakesItToWhereItBursts` | through the throe: never back across, never back down, never past its place; at its end there, across and up | the hull bursts short of its place, or overshoots it |
| `TestItShuddersInItsThroe` | within its lean and the shudder; in the second half both ways | it lurches over stiff, or shakes past its lean |
| `TestTheSmallBlastsComeOnceEachAtTheirPlaces` | each place of `ThroePops` once, at its tick | a blast on the hull missed or doubled |
| `TestTheJetsCoughThenAreDeadBeforeTheBurst` | they catch again at least twice and die at least three times; dead the last 8 ticks | the jets burn steady to the burst, or never catch |
| `TestItBurstsOnceAsTheThroeEnds` | no burst in the throe; on its last tick; broken from then, still once the series is over | the hull bursts twice, or stays to be seen |
| `TestEveryPieceBlowsUpOnce` | each of 8 pieces once; over once; not in the order of their numbers | a piece blows twice, never, or the series reads as a row |
| `TestTheBlastsComeOneAtATimeWithGaps` | the first `SeriesFirstTicks` after the burst; the gaps between `SeriesGapLeast` and `SeriesGapMost` | one bang, or the series drags |
| `TestNoPiecesItIsOverAtTheBurst` | no pieces: burst and over on the throe's last tick | an empty series hangs |
| `TestAStartWhileItRunsIsNothing` | started again ten ticks in: no second crack, on its way as it was | a second last life restarts the throe |
| `TestAClearMakesItWhole` | after the throe, cleared: idle, neither running nor broken; started, it cracks again | a restart leaves the hull broken |
| `TestSameDiceSameSeries` | two breakups seeded alike: the same blasts on the same pieces | the series is not the dice's |

## Game.Wreckage

State: written, 11 tests (3.0.128, stage 19). Needs no stage: `TWreckage`
only counts; the pictures are left out. The unit is tried by
`Tests\Game\Tests.Game.Wreckage.pas`, fixture `TWreckageTests`.

Shared: a wreckage seeded 11; `Parts(heart)` cuts a hull of 169 by 128
about the heart into a grid of 3 by 2, as the painter does, turned 3
degrees; the heart at 256, 104; the flight's wind 4.

| Test | Holds | Turns red when |
|---|---|---|
| `TestNothingTillItBursts` | a tick before any burst: none, nothing falls | pieces out of nowhere |
| `TestEachPartFliesFromItsPlace` | as many as the parts, each from its place, turned as the hull was; on the screen | the pieces jump at the burst |
| `TestOutFromTheHeart` | 20 ticks, no way, no wind: the left column went left, the right one right | the burst does not throw its pieces out |
| `TestUpFirstThenFallingSlowly` | the top row going up after a tick; none gone two seconds on; all falling four seconds on | the moon's pull too strong, or none |
| `TestTheyTumble` | 10 ticks: each turned more than a degree | the pieces fly stiff |
| `TestTheWindTakesThemBack` | 150 ticks against a calm twin: each going left more than a unit faster, never faster than the world | the smoke streams back and the pieces do not |
| `TestBetweenTicksAPieceLiesBetweenThem` | halfway between two ticks: the middle and the turn halfway | the pieces step on the tick |
| `TestAllGoneUnderTheScreenInTheEnd` | ticked till none falls, within 1000: each gone | a piece hangs on the screen forever |
| `TestANewBurstReplacesTheOld` | a second burst of one part: one piece | the pieces of two bursts pile up |
| `TestAClearEmptiesTheAir` | cleared: none, nothing falls | a restart leaves pieces in the air |
| `TestSameDiceSameFlight` | two wreckages seeded alike, 30 ticks: in the same places | the flight is not the dice's |

## Game.Landing

State: written, 8 tests (3.0.128, stage 19). Needs no stage: `TLanding`
only counts. The unit is tried by `Tests\Game\Tests.Game.Landing.pas`,
fixture `TLandingTests`, with a `TBelt` of its own run as the game runs
it.

Shared: the belt run up to the flight's pace and past its ramp; `Step` -
the belt's tick, the road's edge riding it once in, then the landing told
what the belt has left to run and whether it stands, the slowdown carried
out on the belt; 600 ticks are enough for all of it.

| Test | Holds | Turns red when |
|---|---|---|
| `TestIdleItTellsNothing` | 600 ticks unstarted: not running, no cue, the flight at its pace | the flight ends with no burst |
| `TestBegunItRunsTheFlightGoesOnThenSlowsOnce` | running from the start; at the flight's pace a tick short of `LandingSlowAfterTicks`; the slowdown once, then | the world stops under the burst, or never |
| `TestTheRoadComesInOnceFromBeyondTheRightEdge` | once; no farther than `LandingRoadEnterGap` beyond the edge, and from beyond it | the road pops up on the screen, or twice |
| `TestTheRoadStopsABargesLengthFromTheLeftEdge` | where the world stops: its edge at `BargeLength`, within 0.01; it came in right of the barge at its berth | the barge docked against it stops off the left edge, or the road comes in short of the barge and never meets it |
| `TestItTellsOnceThatTheWorldStands` | once, `LandingSlowTicks` after the slowdown; standing | the stand before the stop, or never |
| `TestTheHandOverABreathAfterTheStand` | once, `LandingHandOverAfterTicks` after the stand; handed over | the titles take over the slowdown, or never |
| `TestAStartWhileItRunsIsNothing` | started again ten ticks short of the slowdown: the slowdown on time | a second last life sets the clock back |
| `TestAClearMakesItIdle` | cleared: not running, idle, nothing handed over | a restart keeps the hero spared |

## Game.Ram: its end

State: written, 6 tests (3.0.128, stage 19): fixture `TRamBreakupTests`
in `Tests\Game\Tests.Game.Ram.pas`. The clock of the end is tried in
`Tests.Game.Breakup`; here, what the Ram does with it.

Shared: the body and the orders of the other fixtures; `HangOver(x)` -
hanging over x, the magnet told out, 400 ticks with the hero on the road
under it; 300 ticks hold the throe and the series.

| Test | Holds | Turns red when |
|---|---|---|
| `TestOnTheRoadAWreckIsNothing` | past the bunker on the road, wrecked: whole, no crack | the hull bursts before the air phase |
| `TestWreckedAloftItCracksAndFightsNoMore` | the magnet out, wrecked: the crack on the next tick with a jolt; through the throe no catch, no lob, no charge, no dive, the magnet stowed, nothing hot; there to be seen | the dead hull still fights, or vanishes at the crack |
| `TestItBurstsOverTheMiddleWhereverItDied` | wrecked hanging over 120: it bursts with its middle over the middle of the screen, no lower than it was | it bursts on the hero's head after a dive, or off the screen |
| `TestBurstItIsNoMoreToBeSeenOrTouched` | after the throe: not present, no touch where it was, no sweep; 300 ticks on, never again | the burst hull still wounds, or comes back |
| `TestTheSeriesBlowsEachPieceOnce` | each of `WreckParts` once at most, `WreckBlasts` in all; over | a piece blows twice, or the bays and the hull's pieces are skipped |
| `TestAClearMakesItWhole` | after its end, cleared: whole; hanging again, present | a restart after the end leaves no Ram |

## Game.Belt: a ramp of its own, the way left

State: written, 3 tests (3.0.128, stage 19), beside the belt's own in
`Tests\Game\Tests.Game.Belt.pas`, fixture `TBeltTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestALongerRampTakesItsTicks` | from the flight's pace, run to a stand over 165: moving a tick short, gentler than the usual ramp; at a stand when it is over | the flight stops over the usual two seconds |
| `TestTheRampLeftIsWhatItRunsToTheStop` | 40 ticks into it: what is left is what it then runs, within 0.001; none at a stand | the road comes back short of the barge, or over it |
| `TestNoRampUnderWayNoneLeft` | standing, and at cruise: none | a road comes in while the belt runs on |

## Game.Road: come back

State: written, 1 test (3.0.128, stage 19), beside the road's own in
`Tests\Game\Tests.Game.Road.pas`, fixture `TRoadEndTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestComeBackItsEdgeIsWhereToldAndRidesTheBelt` | come back at 516: there, between the ticks too; 30 ticks at 2 left: 60 farther; on the screen, its tiles past the right edge | the road comes back flown in, or short |

## Game.Barge: the berth

State: written, 6 tests (3.0.128, stage 19), beside the others in
`Tests\Game\Tests.Game.Barge.pas`, fixture `TBargeRideTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestBerthedItGlidesToItsStationAndLineAndStands` | drifted away from the station, berthed over 165: berthing; not berthed a tick short; then at its station, on its line, and there still, no way, 100 ticks on | the barge stops anywhere but against the road |
| `TestBerthingItGoesOnTheWayItWentAtFirstNotFar` | berthed going right: on to the right on its first tick; never farther than `BerthCarryX` past where it was | the barge jerks to a stop and turns, or sails off |
| `TestBerthedABlowStillRocksIt` | berthed, struck: it dips more than half the blow; back on its line, not moved across | the dock's rock is lost, or moves it |
| `TestOnlyAtItsStationOrDriftingDoesItBerth` | away, moored and casting off: told to berth, it stays so | a restart's end berths a barge not yet boarded |
| `TestDockedItRidesWithTheWorld` | berthing, docked at 150: docked, there at once; 20 ticks ridden at 1.5 left: the world's way each tick, carried 30, on its line | the docked barge stands while the road runs on, or bobs off the road |
| `TestOnlyBerthingOrBerthedDoesItDockOnlyDockedRide` | at its station: a ride and a dock do nothing; drifting, a dock does nothing; berthing, it docks | the world drags a barge not docked, or the drift docks one the road never touched |

## Game.Flock: closed, let go, dropped

State: written, 5 tests (3.0.128, stage 19), beside the flock's own in
`Tests\Game\Tests.Game.Flock.pas`, fixture `TBargeFlockTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestClosedNoneComesIn` | the escort in, closed: 2000 ticks, none came in | new barges come in after the burst |
| `TestLetGoAllLeaveFastAndNoneComesIn` | let go: no escort; each flying going left at `DispersePace`; 260 ticks on none flies | the barges linger over the still picture |
| `TestAClearOpensItAgain` | let go, cleared: open; started, the escort comes | a restart leaves the flock shut |
| `TestADroppedBargeFallsFromWhereItWasHeld` | taken, dropped at 200, 160: not taken, knocked, there; then behind and down; out of the count | the magnet's barge hangs in the air at the burst |
| `TestDroppingOneNotTakenChangesNothing` | a free one dropped: on its path where it was | a barge on its path falls for nothing |

## Game.HullLives: retired

State: written, 4 tests (3.0.128, stage 19), beside the others in
`Tests\Game\Tests.Game.HullLives.pas`, fixture `THullLivesTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestRetiredTheBarGoesUpAndIsGone` | armed, lit, retired: shown and going up each tick of `HullBarDropTicks`; then gone, and gone 1000 ticks on | the bar hangs over the burst, or blinks out |
| `TestRetiredNoLifeIsTaken` | retired: no life taken, as many left | an orb in the air ends the fight twice |
| `TestNotArmedARetireIsNothing` | retired unarmed, then armed: in its place, a life taken | a retire before the gun spoils the bar |
| `TestArmedAgainTheBarComesBack` | retired, armed again: in its place | the next fight has no bar |

## Game.HeroOrbs: the moon form shed

State: written, 1 test and an ask more in another (3.0.128, stage 19),
beside the others in `Tests\Game\Tests.Game.HeroOrbs.pas`, fixture
`THeroOrbsTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestTheMoonFormComesOffInARingOfItsOwn` | shed: an armed ring; no orb of the ice form's rite | the moon form comes off in ice-white orbs, or in a ring that shields nothing |
| `TestCorpseCallsUpNoOrbs` | asks the moon form's shed too: no armed orb over the corpse | a dead hero sheds a ring |

## The farm

State: written, 40 tests (3.0.129, stage 19a of arena 3,
`chase-backdrop.md`, "The farm"). The capsule and the farm's light are no
`Game` units, but they close the chase's far plane, whose tests live here.
Needs no stage: all of it is numbers. The stand
(`tools/chase/stand.template.html`) is the reference; the numbers marked
"the stand's" were taken from it over the layout's dome-farm and glow of
the day, set in the tests, so tuning the layout breaks nothing.

### Levels.Capsule

Fixture `TCapsuleTests` in `Tests\Levels\Tests.Levels.Capsule.pas`, over
the dome-farm: 640 by 220 by 90, 12 rows, 16 cells, a belt every 4, 5 cells
of turn.

| Test | Holds | Turns red when |
|---|---|---|
| `TestFeetStandOnTheBaseLine` | rows 0 and 12 at three places along: Y exactly 0 | a foot lifts by the noise of a cosine and throws a shadow |
| `TestFarFootBehindNearFootInFront` | Z half the depth at row 0, minus it at row 12 | the arch goes round the wrong way |
| `TestCrownIsItsHeightHalfwayBetweenTheHalves` | row 6: Y the height, Z exactly 0 | the crown changes halves with the FPU |
| `TestEndsTurnDownToTheirTips` | at the tips, the crown's row: Y exactly 0, X a quarter turn past the barrel | the ends stand open or stick out |
| `TestShapeIsTheStands` | 1272 edges, 291 nodes, 240 of the belts, 128 of the ring | an edge is added, lost or thickened apart from the stand |
| `TestNoEdgeIsAPoint` | every edge has a length | the poles' collapsed purlins come back |
| `TestBeltsCrossTheBarrelEveryBeltEveryCells` | five belts, at the barrel's ends and every 4 cells, within 0.001 | a belt is lost or shifted |
| `TestNodesStandAboveTheFeet` | no node under the ground or on a foot | a beacon sits on the ground |
| `TestEveryNodeHasAKeyOfItsOwn` | no two nodes share a seed's key | the crown's beacons blink in pairs again |

### Levels.Farm: the grow lights

Fixture `TFarmGlowTests` in `Tests\Levels\Tests.Levels.Farm.pas`, over the
layout's glow: spans of 900-2400 ticks, 0.85 lit, a warm-up of 90, a
flicker of 12.

| Test | Holds | Turns red when |
|---|---|---|
| `TestGlowMatchesTheStand` | eight of the stand's ticks of greenhouses 0 and 7: full, dark, the flicker's dark tick, the warm-up's steps | a hall lights on another tick than on the stand |
| `TestGlowNeverPastItsLevel` | ten halls over 40000 ticks: within 0 and the level | the warm-up overshoots |
| `TestGlowLitAboutItsShare` | twenty halls: lit 0.85 of the time, within 0.1 | the dice or the share are read wrong |
| `TestGlowSwitchedOnFlickersAndWarmsUp` | the first switch on: dark ticks in its first 12, then never down, at its level by the warm-up's end | it comes on at full, or flickers for good |
| `TestGlowSwitchedOffGoesOutAtOnce` | each switch off for good: at full the tick before | a light fades out |

### Levels.Farm: the light

Fixture `TFarmLightTests`, over a far plane of its own: the stand's
camera, the dome-farm, one greenhouse 40 wide and 20 tall near the dome's
middle, its glass at a quarter across and halfway down, half of it lit -
lit at tick 0, as the stand has the first hall.

| Test | Holds | Turns red when |
|---|---|---|
| `TestNoFarmLightsNothing` | no farm: no source | a farm lights a city with none |
| `TestLitGreenhouseIsASourceAtItsGlass` | one source at full: at the glass's centre, its power the share times the area over a hall's, its nearness | the light stands off the glass or is too strong |
| `TestMirrorMovesTheSource` | mirrored: the source the other side of the piece | a mirrored hall lights from its blank side |
| `TestGreenhouseFarOffTheScreenIsDark` | far off: no source, the glass dark | halls off the screen light the dome |
| `TestLightAtTheGlassIsItsColourTimesItsPower` | at the glass: each channel the colour times the power | the colour is lost |
| `TestLightFallsToAShareOfOneOverEAtItsReach` | a reach away at its nearness: times 1 / e | the falloff or the nearness is wrong |
| `TestLightFarOffIsNothing` | ten reaches away: nothing | a far hall tints the whole dome |
| `TestExposedNeverPastFull` | a huge light: under full; none stays none | many halls burn white past full |
| `TestExposedKeepsTheHue` | the channels in their order | the light changes colour as it brightens |
| `TestAirCoversTheNearHalf` | 65 by 7 corners, two triangles a cell; between the crown and the near foot on the screen; lit somewhere | the air spills over the dome or misses its half |
| `TestApronLitAtTheFootDarkTowardTheEye` | every quad dark at its outer corners, which lie lower on the screen; lit at a foot | the apron runs away from the eye or is lit to its end |
| `TestApronNoneWithTheDomeOffTheScreen` | the dome far off: nothing | light lies on the floor with no dome |

### Render.DomeFrames: the capsule

Fixture `TCapsuleFrameTests` in `Tests\Render\Tests.Render.DomeFrames.pas`,
over the frames' far plane with the dome-farm alone, its beacons above 0.9,
centred on the screen.

| Test | Holds | Turns red when |
|---|---|---|
| `TestRibsAreTheStands` | 623 far, 649 near; the far behind the centre | the frame is built or split apart from the stand |
| `TestCrownStandsWithTheNearHalf` | the crown's 26 purlins (Z exactly 0) among the near | the crown changes halves |
| `TestShadowsAreTheStands` | 320 shadows | a foot throws a shadow, or a lifted rib none |
| `TestBeaconsAreTheStandsEachItsOwnSeed` | 18 behind, 37 in front, no seed twice | the crown's beacons blink in pairs |
| `TestRibsAreTheFarmsUnderTheFarm` | no farm: none the farm's; the farm under it: all | a city dome is lit by the farm, or the farm's is not |
| `TestRibsCarryTheFramesDark` | every rib the frames' dark, 26, 23, 21 | the painter draws a rib in no colour |

### Levels.FarPlane: the glare and the farm read

In `Tests\Game\Tests.Game.FarPlane.pas`: `TFarPlaneSunTests` +2,
`TFarPlaneReadTests` +6, over the depth layout with the dome-farm and the
farm of the day.

| Test | Holds | Turns red when |
|---|---|---|
| `TestGlareWholeWithoutAFarm` | deep inside the main dome, no farm: 1 | the city's glare is cut |
| `TestGlareGivesWayToTheFarmsDome` | before it 1; deep inside 0.3; halfway up the ramp 0.65 | the glare jumps, or never gives way |
| `TestLevelTwoReadsItsFarm` | a farm under a capsule, with glass, its glare under 1 | the layout's farm is lost |
| `TestACapsuleAndItsFarmRead` | the capsule's numbers, the farm's frame, glare, span and glass by piece | a key is read wrong |
| `TestAFrameOfAnUnknownKindRaises` | "tent": raises | a typo draws a geodesic dome |
| `TestACapsuleOfOddRowsRaises` | 11 rows: raises | the crown falls between rows |
| `TestACapsuleDeeperThanLongRaises` | 700 deep: raises | the barrel turns inside out |
| `TestAFarmUnderADomeRaises` | the farm under a dome: raises | the farm lights a geodesic it cannot read |

## The gate

State: written, 10 tests (3.0.130, `docs/mechanics/finale.md`, "The gate
as built"). The picture, its shade and the lamp's light are the painter's:
a live run.

### Game.Gate

Fixture `TGateTests` in `Tests\Game\Tests.Game.Gate.pas`, a gate of its
own; the place tests ride a road of their own.

| Test | Holds | Turns red when |
|---|---|---|
| `TestSealedTheLampStaysRed` | new: sealed; 32 ticks on: sealed, the turn 0 | the lamp turns by itself |
| `TestPromisedTheLampTurnsAmberOverItsTicks` | promised: soon, the turn 0 till a tick; 8 ticks: 0.5; 16: 1 | the lamp jumps, or never turns |
| `TestTheTurnStopsAtAmber` | 48 ticks after the promise: 1, at rest between the ticks | the lamp goes on past amber |
| `TestASecondPromiseDoesNotStartTheTurnAgain` | promised again halfway: still 0.5; 8 ticks on: 1 | a second flare blinks the lamp back to red |
| `TestATurnBetweenTicksLiesBetweenThem` | 3 ticks in: the last tick 2/16, this one 3/16, halfway 2.5/16 | the lamp steps at 33 Hz |
| `TestClearSealsItAgainAtOnce` | amber, cleared: sealed, the turn 0 at both ends of the tick; 16 ticks on: 0 | a restart keeps the amber, or fades it back |
| `TestTheFacadeEndsAtTheRightEdgeOnceTheRoadStands` | the road at its stop: the left side 392, the right side 512 | the facade stands off the stand's place, or over the logo's |
| `TestTheFacadeComesInAfterTheRoadAndRidesWithIt` | the road come in at the gap: the facade beyond the right edge; 30 ticks at 2 left: 60 farther, between the ticks too | the facade pops in with the road's edge, or lags the road |
| `TestTheLampColorGoesFromRedToAmber` | green rises from red through halfway to amber, red the same, amber's blue under its green | the turn passes through another colour |

### Game.Road: arrived

In `Tests\Game\Tests.Game.Road.pas`, fixture `TRoadEndTests`, +1.

| Test | Holds | Turns red when |
|---|---|---|
| `TestItHasArrivedOnlyComeBack` | new, and running out: not arrived; come back: arrived; running out again, and cleared: not | the pier of the road running out carries a gate |
