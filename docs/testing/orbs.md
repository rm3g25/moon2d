# Tests of the orbs

Tables of the tests, one section per unit under test: the test's name,
what holds, the breakage. The rules and the conveyor are in
`../TESTING.md`; a new unit's table goes into the file of its namespace.

## Orbs.Flock

State: written, 17 tests, green.

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
| `TestNewOrbIsInFrontOfTheHero` | a new orb has a depth of zero or more | the default depth goes below zero: the aura and the rain, which know no depth, are drawn behind the hero |
| `TestArrivedOrbStaysWhereItWasPut` | an orb moved and then told it has arrived is where it was moved to, and stays there through a tick | `Arrive` takes back the move instead of what is drawn ahead |

Left to the eye: the breath, the look of an implosion, the dust of a
strike, the mark on a face (`MarkFace`) - the flock keeps them to itself
and only draws them. So with the two layers about the hero (`DrawLayer`
picks one by the depth) and with what an orb is drawn ahead by between
ticks: `MoveBeside` and `Arrive` change no place a test can read.

## Orbs.Harvest

State: `HarvestSpots` - designed, not written. `HarvestAround` - written,
11 tests, green on the first run; its table is the second below. The
unit is tried by `Tests\Orbs\Tests.Orbs.Harvest.pas`, fixture
`TOrbHarvestTests`; the tests of `HarvestSpots` join it when they are
written.

Shared setup, `Tests\Tests.Matter.pas`, written: `MatterFromRows` builds a
`TMatter` from twelve strings of sixteen characters, `#` a solid cell,
`.` an open one; `WalledMatter` is a room shut on every side - the floor,
the ceiling and both walls, a cell thick - and `EmptyMatter` has nothing in
it; `SolidAt(AMatter, AX, AY)` answers for a point in units: a solid cell
or a body. A pad's body a test puts into `Bodies` itself. The dice of a
test are a `TXorShift` with a seed of its own, any but zero: a xorshift
seeded with zero rolls zeros for ever.

`HarvestSpots`:

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

`HarvestAround`. The expectations were checked on a Python mirror of the
harvest, over two hundred seeds of the dice; with the sectors taken out of
the mirror `TestAroundDrawsEveryWaveFromAllSides` is red. The hero stands
on the floor of the walled room, his middle at (256, 336), 16 units over
it; three waves of 24 are asked for unless a test says otherwise. Numbers
spelled, as decided: a spot nearer than 34 units is passed by; a spot in
thin air stands 70 to 110 units away.

| Test | Holds | Turns red when |
|---|---|---|
| `TestAroundGivesEveryWaveItsCount` | three waves of 24 asked - three of 24 given; two of 10 - two of 10 | a wave is cut to what its sectors gave, or the two counts are swapped |
| `TestAroundTakesNoSpotTwice` | of the 72 spots no two lie within half a unit | a wave forgets what the waves before it took |
| `TestAroundPassesByTheMatterAtTheHerosFeet` | every spot has a normal and lies 34 units or more from the hero's middle, though the floor is 16 under it | the nearest spots are taken: orbs are born under the hero's feet with nowhere to fly from |
| `TestAroundDrawsEveryWaveFromAllSides` | in every wave at least 6 of the 24 spots lie to his left, 6 to his right and 6 above him | a wave is the nearest spots by the ruler: the first comes off the floor alone |
| `TestAroundGivesNearerFacesToEarlierWaves` | the mean distance of a wave's spots grows from wave to wave | the waves are dealt without regard to distance, or the last gets the nearest |
| `TestAroundOrdersAWaveByItsTurn` | within a wave `Turn` never falls | the order is lost: the rite seats an orb by its number in the wave |
| `TestAroundInAnEmptyRoomGivesSpotsInThinAir` | no matter: 72 spots, none with a normal, each 70 to 110 units away | the ring of air moves, or a wave of an empty room is short |
| `TestAroundTopsUpShortMatterWithAir` | one lone cell: every wave has its 24; the spots with a normal lie on the cell's outline, 16 at most; the second and the third wave are all air | air is taken while matter is free, or a wave short of matter is short of spots |
| `TestAroundHarvestsABody` | no cells, one pad body: there are spots with a normal, and every one lies on the body's outline | the bodies of pads are not harvested: an arena of pads gives air |
| `TestAroundAwayAndTurnPointFromCenter` | of every spot: the center plus `Away` along `Turn` is the spot | the arguments of the arctangent are swapped: flights are timed and sectors cut by wrong numbers |
| `TestAroundSameDiceGiveSameSpots` | two calls with dice of one seed give the same spots; dice of another seed give others | the function reaches for `Random`, or ignores its dice |

Left to the eye: whether twelve sectors read as "from all sides" on a
real screen with little matter (screens 1 and 5 of level 1).

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

## Orbs.Patterns

State: written, 11 tests, green on the first run. The expectations were
checked on a Python mirror of the two figures. The unit is tried by
`Tests\Orbs\Tests.Orbs.Patterns.pas`, fixture `TOrbPatternsTests`.

A pattern is a function of a wave, a number in it and the pattern's own
clock, so a test asks for the 72 seats of a moment and looks at them as a
figure: at eight moments of the clock where a figure is the subject, tick
by tick where its motion is. The word of a level file is read through
`LevelFromRows` of `Tests.Rooms`.

Numbers spelled, as decided: 72 orbs to a pattern, three waves of 24; the
words `snowflake` and `vortex`; the snowflake's six rays. The bounds are
the plan's and loose: no seat of the snowflake 50 units from the hero's
middle, none of the vortex 60. Not spelled: the radii, the paces and the
lights of either figure. One bound belongs to the rite: it takes a seat
that goes over 24 units in a tick for one that has leapt, so a seat that
keeps to its figure is held under 12 units and one that leaps over 40.

| Test | Holds | Turns red when |
|---|---|---|
| `TestGamePatternsAreFoundByTheirWords` | `snowflake` and `vortex` are found, each with a seat function and 72 orbs in its three waves; the default name finds the snowflake | a word of the level files is renamed, or a pattern leaves the 72 orbs the ceremony's damage is counted by |
| `TestUnknownPatternRaises` | `blizzard` and the empty name raise `EOrbPatternError` | an unknown word quietly gets some pattern: a typo in a level file shows only at the boss |
| `TestLevelFileNamesItsPattern` | a level with `"henshinPattern": "vortex"` gives that word, and the word finds the vortex; a level without the member gives an empty word | the member is renamed in the loader: level 2 silently gets the snowflake |
| `TestSnowflakeRaysAreBehindAndHexagonInFront` | the seats of waves 0 and 1 have a depth below zero, those of wave 2 above | a wave changes its side of the hero |
| `TestSnowflakeSeatsAreApartAndWithinReach` | no two of the 72 seats lie within a unit; none lies 50 units from the hero's middle; every light is 0 to 1 | two orbs share a seat, the figure outgrows the hero, or a light leaves its range |
| `TestSnowflakeHasSixRays` | a sixth of a turn about the middle of the rays lands every seat on a seat of its own wave | a ray, a tip or a twig is lost or misplaced: the figure is no snowflake |
| `TestSnowflakeTurnsAndItsHexagonWalksAgainst` | over 500 ticks of the clock: the seats of the rays all turn one way about the heart and the seats of the hexagon the other; no seat goes 3 units in two ticks of the clock | the hexagon turns with the rays, or a seat of the snowflake leaps |
| `TestVortexGivesEachWaveAnArmOfItsOwn` | the three seats of one number, a wave each, balance about the hero's upright - their X and their depths sum to zero - and are three seats | two waves share an arm, or the arms are not a third of a lap apart |
| `TestVortexOrbGoesRoundTheHero` | within 128 ticks of the clock every seat has been well behind the hero (a depth under -0.5) and well in front of him (over 0.5) | the funnel stands on one side of him |
| `TestVortexIsNarrowAtTheFeetAndWideOverTheHead` | the widest seat over his head is over one and a half times as far from his upright as the widest by his feet; no seat lies 60 units from his middle; every light is 0 to 1 | the funnel is turned upside down or made a column |
| `TestVortexSeatLeapsOnlyWithItsLightOut` | at one tick of the clock a step and at two: a seat goes under 12 units or over 40, nothing between; when it goes over 40 its light is under 0.2 before and after; such leaps do happen | the leap from the top of an arm to its foot is seen, or a step of a seat comes near what the rite takes for a leap |

Left to the eye: whether a figure is beautiful; the wave of light that
runs along the snowflake; the tilt of the vortex's rings.

## Orbs.Rite

State: written, 41 tests, green on the first run (239 in the whole
suite). The expectations were checked on a Python mirror of the rite with
its flock, harvest and patterns: every test is green on the mirror with
the game's dice, green over sixty other seeds of the dice, and red with
the rule it guards taken out of the mirror. The mirror and the unit were made in a session that
had read the implementation, so the table is what the tests answer to.
The unit is tried by `Tests\Orbs\Tests.Orbs.Rite.pas`, fixture
`TOrbRiteTests`.

The rite knows no pattern and no score of its own, and the tests use
that. Shared in the unit:

- The hero is a point the test moves: his middle, (256, 336) as he stands
  on the floor of `WalledMatter`. His body is five points about it, given
  through the rite's `TBodyProbe`; the fixture counts the asks.
- A tick is `Rite.Tick` with his middle and a drain of the events, which
  the fixture keeps with their ticks. Ticks are counted from 0.
- A strike is the game's (`ResolveOrbHits`): an orb alive and armed is
  spent.
- "The grid" is a pattern of the test's own, 10 orbs to a wave: three rows
  of seats that stand still, the first behind the hero (depth -1) and the
  other two in front (depth 1), all at full light. A seat is found by its
  place, so "the grid is full" is: every seat about the hero holds one
  orb, and there are 30 orbs. "The clock pattern" is the grid sinking 0.05
  units for every tick of the pattern's clock: an orb in its seat shows
  how far the clock has gone.
- "The bench score" is a score of the test's own: gap 10, span 40, hover
  12, freeze 4, collapse 9, 5 stand-ins; 30 orbs of a suit shed, standing
  40 ticks and up to 12 more. Its ticks are spelled: calls on 0, 10 and
  20, seats on 40, 50 and 60, the pause on 60, the collapse on 72, the
  finish on 81. The ticks of `IceRiteScore` are never spelled: its numbers
  are still being tuned, and a test reads them from the record.

Numbers spelled, as decided: three waves; 72 orbs with either pattern of
the game and 72 of the ice suit; the oval of the shield, 28 by 35, the
aura's own; a whole rite strikes once for every orb and once for every
stand-in of the stock. Not spelled: sizes and lights (an orb just born is
"under half its size", one behind the hero "smaller and dimmer" than one
in front), the chest ("one point within 4 units of his middle"), the
times of a flight, of the shield's forming ("there half a second on") and
of its lap.

| Test | Holds | Turns red when |
|---|---|---|
| `TestNewRiteIsIdleAndEmpty` | a new rite is idle, has no orbs and nothing to tell; ten ticks change none of it | `Create` leaves a stage or an event behind |
| `TestEventsComeByTheScoresSchedule` | the bench score: three calls on ticks 0, 10, 20; three seats on 40, 50, 60; the pause on 60, after the third seat; the collapse on 72; the finish on 81; nothing more in a hundred ticks | the rite counts by numbers of its own instead of the score's; an event is a tick off, told twice or out of order |
| `TestStageFollowsTheSchedule` | gathering from `Start`; hovering after tick 60, collapsing after 72, idle after 81 | `Stage` lags its event, or never comes back to idle |
| `TestGamePatternsRunTheIceRiteToTheSuit` | the ice score with the snowflake and with the vortex: the nine events in order; 72 orbs and none armed at the pause; the finish comes `HoverTicks + CollapseTicks` after the pause | a pattern of the game breaks the rite; the mercy the ceremony grants at the pause no longer runs out on the tick of the suit |
| `TestEveryWaveBringsItsCountOfOrbs` | no orb before the first tick; between a call and the next exactly 10 orbs are born, the grid's count; 30 at the pause | a wave is short or long, or the rite calls 24 whatever the pattern says |
| `TestOrbsAreBornInTheMatterSmallAndUnarmed` | the walled room: each of the 72 orbs is born at a solid point, under half its size, unarmed | an orb is born over its face or beside it, at its full size, or armed inside the matter |
| `TestOrbIsArmedOnlyOnItsWayToItsSeat` | no orb is born armed; when the first wave is told seated none of its ten is armed; by the pause every orb has been armed; from the pause to the suit none is | a seated orb goes on striking, or an orb never arms |
| `TestPatternIsFullAtThePause` | the grid is full | an orb misses its seat, two share one, or a wave is seated by the seats of another |
| `TestSeatedOrbTakesTheDepthOfItsSeat` | the ten orbs of the back row have a depth below zero, the other twenty have not; an orb behind is smaller and dimmer than one in front, their seats burning alike | the depth of a seat does not reach the orb: the whole pattern is drawn in front of the hero |
| `TestMiddleWaveTurnsAgainstTheOthers` | summed over the flights of a wave, far from the hero: the first and the third wave turn one way about him, the second the other | all three waves spiral one way |
| `TestPatternGathersAboutAWalkingHero` | he walks 2 units a tick through the gathering: at the pause the grid is full about where he is | the flights end where he was |
| `TestSeatedPatternKeepsToTheHeroWhateverHisStep` | after the pause, through a walk, an ice jump and a leap of 200 units: the grid is full about him on every tick | the pattern is on a leash, as the aura is, or a leap leaves it behind |
| `TestLeapDoesNotThrowFlyingOrbs` | the ice score; late in the flight of the first wave the hero is 180 units away within a tick: no orb in flight moves a quarter of that on the tick; at the pause the grid is full about him | a flight half flown is thrown half the way with the hero: the orbs jump across the screen on the return from a pit |
| `TestPauseSeatsWhoeverIsStillInFlight` | a leap three ticks before the pause starts the flights over; at the pause no orb is armed and the grid is full | an orb is still armed inside the mercy of the hover, or the pattern has holes after a late return from a pit |
| `TestRiteInAnEmptyRoomStillFillsItsPattern` | no matter: the grid is full at the pause | a room with no faces gives a rite with no orbs |
| `TestOrbStruckInFlightIsReplaced` | three orbs struck on each of ticks 15, 30, 45 and 52: never more orbs than seats; on tick 65 the grid is full | a loss leaves a hole, or a stand-in is sent for an orb that is still there |
| `TestStandInComesOutOfTheFaceOfTheStruck` | four orbs struck on tick 30: four are born after it, each where one of the four was born, no two at one place | a stand-in comes off another face, or one loss is replaced twice |
| `TestArmedStandInsAreNoMoreThanTheStock` | every armed orb is struck on every tick of a rite: 35 strikes, the 30 orbs and the 5 stand-ins of the bench score; on tick 65 the grid is full all the same | the stock is not counted: a monster in the stream loses a life for every stand-in without end; or the unarmed stand-ins are not sent |
| `TestLateStandInThickensAtItsSeatUnarmed` | every orb in flight struck five ticks before the pause: as many are born as were struck, each on a seat of the grid from its first tick and under half its size; no orb is armed from the strike on; before the collapse the grid is full | a late stand-in flies in through the pause, armed inside the hero's mercy, or is not sent at all |
| `TestPatternClockQuickensThenStandsStillAndFlashes` | the ice score, the clock pattern. Against a tick of the clock before the pause: the quickest tick of the hover is over 1.3 times as long, the last under a tenth; through the freeze the clock only slows. An orb is at its biggest within the freeze, over 5% bigger than at the pause | the pattern is frozen through the hover, falls into the hero while it still turns, or does not flash |
| `TestOrbsDrawIntoTheBodyAndStayUntilTheSuit` | from the collapse to the suit all 30 orbs are alive and none is armed; on the tick of the finish every orb is gone and stands on one of the five points of the body, more than one point used; a tick later the flock is empty and the rite idle | an orb vanishes as it goes in - the fault of the first live run, the lights out before the halo came -, or all go in at one point |
| `TestOrbsDrawInOutOfStep` | the ice score: the orbs come onto the body on five different ticks or more, none leaves it, all are there by the suit | the orbs go in as one |
| `TestBodyIsAskedOnceAsTheCollapseBegins` | the body is not asked for before the tick of the collapse, is asked on it, and not again | the body is asked every tick, or at `Start`, when the hero stands otherwise |
| `TestLightsOnTheBodyRideWithTheHero` | he walks through the collapse: at the suit every orb stands on a point of the body where he is now | the lights stay where he stood as the collapse began |
| `TestWithNoBodyEveryOrbGoesInAtTheChest` | a rite with no probe, and one whose probe gives no points: at the suit all 30 orbs stand at one point, within 4 units of his middle | a body of no points is indexed: the rite of a frame that gave no seeds falls over |
| `TestCollapseImplodesEveryOrbAndTellsNoFinish` | `Collapse` in the gathering: idle at once, every orb imploding; no orb is born after it, the flock is empty within a second, nothing is told in two hundred ticks | the rite goes on over a dead hero: waves are called and the suit goes on a corpse |
| `TestClearLeavesNothingAndNothingComes` | `Clear` two ticks in, with orbs unborn and an event unheard: no orbs, idle, nothing to tell; nothing comes in two hundred ticks | a restart keeps the unborn of the last try, or what it had to tell |
| `TestStartDropsTheRiteAlreadyGoing` | `Start` over a rite thirty ticks old and unheard: no orbs, nothing to tell; the new rite tells its own seven events up to its pause, and the grid is full, not doubled | the orbs or the events of the old rite leak into the new |
| `TestShedAndRiteDropEachOther` | `Shed` over a rite: the orbs of the ring alone, and nothing of the rite is told; `Start` over the ring: no orbs, gathering, the grid full at the pause | a shed and a rite share the flock |
| `TestCarryTakesTheGatheringThroughADoor` | `Carry` after the first tick, part of the first wave unborn: all ten orbs are there and armed, those that were there moved by the door's step; at the pause the grid is full about the hero | an orb waits on a face of the screen left behind, the unborn are lost, or the pattern does not fill behind a door |
| `TestCarrySendsNobodyFlyingBack` | `Carry` twenty ticks in, some orbs in flight and some on their faces: all are armed; on the next tick no orb moves a quarter of the door's step | a flight goes on from its takeoff on the old screen: the orbs fly back across the door |
| `TestCarryKeepsTheSeatedPatternAboutTheHero` | `Carry` in the hover: the grid is full about him at once and a tick later | the seated pattern is left behind the door |
| `TestShedBringsItsOrbsOutOfTheBodyArmed` | `Shed` with the bench score: shedding, the body asked once, 30 orbs at once, each alive, armed and on a point of the body, more than one point used | the ring is no shield until it has formed, or every orb comes out of the chest |
| `TestShedWithNoBodyComesOutOfTheChest` | no probe: every orb at one point, within 4 units of his middle | a shed with no body falls over |
| `TestIceShedStandsInAnEvenRingOfSeventyTwo` | the ice score: 72 orbs; half a second on all are alive, each on the oval of 28 by 35 about the hero, the gaps between neighbours even to 2%, every orb at its full size and light | the count or the oval leaves the aura's; the ring has a knot or a hole |
| `TestShedRingKeepsToAWalkingHeroAndFlowsOneWay` | he walks for twenty ticks: on each every orb is on the oval about him; over them every orb has gone round it, all the same way | the ring stays where the suit came off, or stands still |
| `TestShedRingStandsItsTimeThenGoesOutOrbByOrb` | the bench score: through `ShedTicks` ticks all 30 are alive; then the count falls on five different ticks or more; `ShedSpread` and a second later the flock is empty and the rite idle, having been shedding while an orb was left; nothing was told | the shield goes out before the mercy does, or all at once; the stage never comes back; a shed tells an event |
| `TestShedRingIsLeftGappedAfterLosses` | the ice score, ten neighbours struck: 62 orbs through the next thirty ticks, none born; one gap eleven even gaps wide, the rest even | the ring closes up as the aura's does, or a lost orb is replaced |
| `TestDeathImplodesTheShedRing` | `Collapse` on a ring: idle, every orb imploding, none left a second later | the shield outlives the hero |
| `TestCarryTakesTheShedRingThroughADoor` | `Carry`: every orb moved by the step; a tick later all are alive and on the oval about him | the ring is left behind a door, or flies after him |
| `TestSameCallsGiveTheSameRite` | two rites, the same calls and the same walking hero: the same places, sizes, lights, depths and states on every tick of a whole ice rite | the rite reaches for `Random` |

Open: `TestOrbIsArmedOnlyOnItsWayToItsSeat` and
`TestMiddleWaveTurnsAgainstTheOthers` tell the waves apart by the order of
the flock: the first ten orbs are the first wave. That holds while a wave
is all born before the next is called, as it is with both scores; a score
whose waves overlap at birth would ask for another way.

Left to the eye:

- The look of the way in: the rise out of a face and the mark it leaves,
  the sway over it, the spiral of a flight, the wind of the drawing in.
- What is drawn between ticks: the share of the hero's step an orb takes
  (`MoveBeside`) and the orb that is put at once behind a seat that leapt
  (`Arrive`, the vortex) change no place a test can read.
- The two layers, `DrawBehind` and `DrawInFront`.
- The light of the flash: an orb's `Level` is cut at 1, so only its size
  is tried.
- A hurried stand-in against an unhurried one: both are in their seats by
  the pause, and that is what is tried.
- The light that fills the body through the collapse: the ceremony's, not
  the rite's.

## Orbs.Burst

State: written, 23 tests, not yet run on a compiler.

The rays are watched by their stretches alone: the bench joins every
tick's stretches into the way of each head (`FlyOut`), and a stretch that
begins where no head stood fails the test that flew it. The marks and the
motes are read through `Marks` and `Motes`, read-only properties added
for these tests under the one exception of the rules: they show the two
swarms the burst keeps anyway. Expectations were checked on a Python
mirror of `Orbs.Burst` first; in the walled room all 24 rays leave within
31 ticks of the strike, and a vortex ray turns about 34 degrees in all.

| Test | Holds | Turns red when |
|---|---|---|
| `TestNewBurstIsIdle` | a new burst: not holding, not inhaling, no stretch, mark or mote; a hundred ticks tell nothing and never ask for the body | a burst goes off unstarted |
| `TestWorldStandsForTheInhaleOnly` | after `Start` the world stands and the hero is a figure before each of the `InhaleTicks` ticks, no ray out before the last; from then on neither for a hundred ticks | the inhale is a tick longer or shorter, or never ends |
| `TestStrikeIsToldOnceAfterTheInhale` | `beStruck` once in a hundred ticks, on the last tick of the inhale, with the world moving and the rays out | the strike is told twice, late, or before its rays |
| `TestUnheardStrikeWaitsToBeTold` | ten ticks after the strike unheard: told once, then nothing | an event is lost when the game drains it a tick late |
| `TestStrikeSendsTwentyFourRaysFromTheChest` | 24 stretches on the strike, all from one point within 4 units of the hero's middle, none standing still | the count changes, or a ray leaves from elsewhere |
| `TestRaysGoEveryFifteenDegreesOneStraightUp` | each ray's first stretch goes a multiple of 15 degrees from up, every multiple once, straight up among them | the fan is uneven or turned: the picture is not symmetrical |
| `TestRaysAreAlikeOnEveryTick` | straight and curled: on every tick each stretch is as long as the others and each head as far from the chest | rays get their own speeds or a jitter |
| `TestStretchesJoinIntoTheWayOfEachHead` | a vortex: 24 ways, each stretch begins where its head stood, none twice, each way longer than a stretch and never standing | a stretch skips, repeats or starts afresh: the game strikes where no ray went |
| `TestStraightRayKeepsToItsLine` | no curl: every head on the line of its first stretch, to 0.05 units | a straight ray turns |
| `TestVortexRaysCurlOneWayAndTheCurlDiesOff` | every step of every ray turns the same way; the first turn is more than twice any of the last five; the whole turn is under a quarter | the curl goes the other way for some rays, does not fade, or runs the ray in circles |
| `TestRaysGoThroughMatterAndOffTheScreen` | straight and curled in the walled room: off within two seconds, every way runs through a wall and ends off the screen; nothing after | a wall stops a ray, a ray is dropped on the screen, or never dropped |
| `TestRayMarksTheFaceItGoesInto` | walled room: 24 marks, each in the open within 3 units of matter and on a ray's way, one to each way | a mark is left on the way out of matter, inside it, or twice |
| `TestRayMarksAFaceAgainAfterCrossingASlab` | a slab across the room above the hero: 31 marks; the rays within 45 degrees of up mark two faces, the rest one | a ray marks only its first face, or its way out of the slab |
| `TestEmptyRoomTakesNoMarks` | no matter: all 24 rays fly out, no mark | marks are left off the screen or in the air |
| `TestMarksStayPutThenMeltAway` | the 24 marks stand where they were left two seconds after the strike; none ten seconds after | marks drift, go at once, or never go |
| `TestMotesComeOutOfThePointsOfTheBody` | the body is asked once, at the strike; every mote stands on one of its points, more than one point used; not asked again | motes come out of the chest only, or the body is asked every tick |
| `TestWithNoBodyMotesComeOutOfTheChest` | no probe, and a probe of no points: every mote at one point within 4 units of the middle | a body of no points is indexed |
| `TestMotesLiveAWhileThenGo` | every mote moves on the first tick; all are there half a second on, none ten seconds on | motes stand still, die at once, or never |
| `TestRaysLeaveFromTheHeroAtTheStrikeAndDoNotFollowHim` | the hero leaps through the inhale and on: the rays leave from where he is at the strike, not where it began, and keep to their lines from there, all equally far out | the rays leave from the start, or follow the hero |
| `TestClearLeavesNothingAndNothingComes` | `Clear` in the inhale: the world moves, a hundred quiet ticks, the body never asked; in flight: no stretch, mark, mote or untold strike, and none after | a death in the inhale still strikes, or the echo outlives the hero |
| `TestStartDropsTheBurstAlreadyGoing` | `Start` over a burst in flight: inhaling, nothing of the old burst to tell or see; its strike sends 24 rays from the new hero, told once | the old burst leaks into the new |
| `TestMoonBurstFliesAsTheIceOne` | the moon look and the ice look, the same calls: the same stretches, marks, motes and events on every tick | a look changes the flight, not the colors only |
| `TestSameCallsGiveTheSameBurst` | two bursts, the same calls, a walking hero: the same on every tick for ten seconds | the burst reaches for `Random` |

Left to the eye:

- The look: the veil, the figure and its fringe, the bands of a ray and
  its profile, the head drawn on between ticks, the ring, the flash, the
  look of a mark and of a mote.
- The pace of the motes: their drag, their fall and their spread.
- Whether a mark is the size and light of the design.
- What the game does along a stretch: the bullets put out, a monster
  wounded once a burst, the world standing for the inhale. That is
  `Moon2D.dpr`'s and waits for the scene tests with the hero.
