# Tests of the scenes

Tables of the tests, one section per unit under test: the test's name,
what holds, the breakage. The rules and the conveyor are in
`../TESTING.md`. The scene itself, the cordon over screen 9 of level 1,
is in `../mechanics/scenes.md`.

The pads a scene wakes and flies are in `pads.md` (`Pads.World`, the
dormant pad; `Pads.Flights`, the straight flight), and what a scene does
to a body in `monsters.md` (`Monsters.Bodies`, what a scene does to a
body).

## Levels.Scenes

State: written, 16 and 7 tests, green on the first run (3.0.62, 586 in
the suite). Needs no stage.
The unit is tried by `Tests\Levels\Tests.Levels.Scenes.pas`: the parser
alone by `TLevelScenesTests`, over a root of JSON holding the scenes of
the test and nothing else (`ParseLevelScenes`, `ELevelSceneError`); the
checks of the level's load by `TSceneLoadTests`, through `LevelFromRows`
(`ELevelError`). `..\Game\Scenes` and `..\Hud` join the search path for
the director below.

Shared in the unit: "a scene" is `{"id": "scene", "screen": 1, "cues":
[...]}` with the cues of the test. "The stage" of the load is the open
room with a pad tagged `lift`, a craft tagged `ship` (an iris that slides,
a plate that does neither), a beam `scan` and a beacon `lamp` on it, and
a gravel tagged `guard`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestSceneComesToItsDefaults` | a scene of one shade of 50: its id and screen as written, `soLevel`, no aftermath; the cue `ckShade`, 0 ticks, level 0.5, no id. `"once": "life"` gives `soLife` | a scene with no "once" plays once a life: the cordon comes back after every death |
| `TestCueAtPlaysOnItsTick` | `"at": 7`: `At` and `Plan` 7, `After` -1, the ticks as written | the plan of a timed cue is not its tick: the order of the timeline is lost |
| `TestCueAfterCountsFromTheCueItNames` | `first` at 10, `second` after it with a delay of 5, `third` after `second` with none: plans 15 and 15, delays 5 and 0, and each `After` points at the cue it names | the delay is lost or counted from the start of the scene, or a cue counts from the wrong one |
| `TestCuesStandInTheOrderOfTheirPlan` | five cues written out of order: they stand `early twin middle late counted` - by the plan, the file's order between equals; the cue counted from `early` still points at it after the sort | the sort is unstable (a later cue no longer overrides an earlier one of its tick), or `After` points at the place the cue had in the file |
| `TestCueAfterLooksOnlyUp` | after a cue further down, after itself, after an id nobody has: each raises | a cue may wait for one below it: two cues can wait for each other and the scene never ends |
| `TestCueTakesAtOrAfter` | both, and neither: each raises | a cue with no time plays at 0 unnoticed |
| `TestNegativeTicksRaise` | at -1, a delay of -1, ticks -1: each raises | a typo plays a cue before the scene |
| `TestTwoOfOneIdRaise` | two cues of one id raise; two scenes of one id in another case raise | `after` finds whichever of the two it meets first, or an event starts the wrong scene |
| `TestAftermathPlaysAtOnce` | an aftermath of remove, wake and fly: three cues in the file's order; a cue of it with `at`, with `after`, with `id`, a sound, a hint, a wait: each raises | the aftermath plays a sound on every death, or waits for nothing |
| `TestSpawnStandsOnASeatOrAPoint` | `seat` alone: the seat and the tag; `x` and `y` alone: the point; a seat and a point, a seat and an x, an x alone, neither, no monster, no tag: each raises | a body is born at (0, 0), or on a seat and a point at once |
| `TestSpawnReadsWhatItIsGiven` | bare: no sprite list, facing left, awake; with `spriteList`, `"facing": "right"`, `"asleep": true`: each read | the tank comes down awake, or faces the wrong way |
| `TestAimTakesAMarkOrAPoint` | on `hero`, on a tag (its ease read), on `x` and `y`, a track on `none`: the four marks; an aim on `none`, a point of one axis, no mark, a track of no part: each raises | the tractor beam is aimed at the hero, or a beam at nothing loads |
| `TestMoveReadsTheAxesItIsGiven` | a move of `x` alone moves no `y` and keeps its ease; a move of `y` alone eases linearly by default | a move across drags the craft to y = 0 |
| `TestWaitReadsItsCondition` | a wait after `docked`: `ckWait`, `swDeckEmpty`, its pad | the wait reads no pad and holds nothing up |
| `TestUnknownWordsRaise` | an unknown cue, ease, condition, place, facing and once: each raises | a typo plays as a default and the scene does something else in silence |
| `TestCueWithoutWhatItNeedsRaises` | a sound of no file, a shade of no value or of 101, a move of no axis or no target, a fly of one axis, a hint of no header or no text, a kill of no target, a scene of no cues, a scene of no id: each raises | a cue that can do nothing loads |
| `TestSceneNamesOnlyPadsItsScreenHas` | a fly of `lift` and a spawn seated on it load; a fly, a wake and a wait of a pad nobody has, and a spawn seated on it, raise | a scene flies a pad that is not there, and the spawn finds no seat |
| `TestSceneNamesBodiesOfTheFileOrOfItsOwn` | a hold of `guard`, a kill of a body the scene's cues bring, a release of one its aftermath brings, an aim on `guard`: load; a hold, a kill, a release, a remove and an aim of a tag nobody carries: raise | the tank of the cordon, which no file holds, cannot be released; or a typo in a tag holds no one |
| `TestDormantPadNeedsASceneThatWakesIt` | a dormant pad with no scene, and with a scene that does not wake it: raise; one a scene wakes: loads | a pad that is never there at all loads |
| `TestSceneNamesOnlyWhatTheDynamicsCarry` | a move of the craft, a track of the iris, an aim of the beam, an intensity of the beacon: load; a move of the beacon or of nothing, a track of the plate, an aim of the beacon, an intensity of nothing: raise | a scene moves a lamp, or turns a part that cannot turn |
| `TestCraftGoesBeforeWhatHangsOnIt` | the craft ahead of its beacon loads; the beacon ahead of it raises | the lamps of the cordon trail the hull by a tick |
| `TestSceneScreenAndItsEventMustBeThere` | a scene on screen 2 of one: raises; an event that starts the scene loads, by its id and in another case; one that starts a scene not there raises | a scene never plays, and nobody hears of it |
| `TestCordonOfLevelOneStandsAsDecided` | `level1.json` beside the executable: `cordon9` on screen 9, once a level; it waits for the deck of `s09-lift`; its aftermath brings `cordonTank` and takes `cordonPrey`; `s09-lift` sleeps in the file; an event of screen 9 starts it | the cordon plays again after a death, leaves the tank in the pit, or loses its pad |

Left to the eye: nothing of the parser is drawn. What the timeline looks
and sounds like is the cordon's live run.

## Levels.Dynamics: the craft

State: written, 10 tests, green on the first run (3.0.62). Needs no
stage. The
craft is tried by `Tests\Levels\Tests.Levels.Dynamics.pas`, fixture
`TCraftTests`. A craft is read by `ParseDynamic`, as the level reads it,
and ticked with its origin at the corner of the screen; its corner
(`CornerAt`) is all that is seen of it.

Shared: "the craft" stands at (10, -50), 100 units wide, with a gun that
turns 30 degrees, an iris that slides 3 units and a plate that does
neither.

| Test | Holds | Turns red when |
|---|---|---|
| `TestCraftStandsWhereTheFileSaysUntilMoved` | 50 ticks: the corner where the file puts it | a craft drifts by itself |
| `TestCraftMovesEachAxisOnItsOwn` | x over 20 ticks and y over 40: x there at 20 and y on the way; both there at 40. A move across alone leaves y where it was | one axis waits for the other, or a move of one drags the other along |
| `TestCraftMovedInNoTicksIsThereAtOnce` | a move of 0 ticks, a tick on: the corner there at alpha 0 and 1 | a jump is drawn as a glide across the screen |
| `TestCraftGetsThereByItsTicksAndStays` | each ease, a move of 30 ticks: never back, never past the target; there from tick 30 for 30 more | an ease overshoots, or the move ends a tick late or never |
| `TestEaseShapesTheWayNotTheEnd` | half the ticks of a move of 100: "out" further than "linear", "in" short of it, "inOut" short of "out" | the eases are swapped: the hull rushes in and crawls to a stop the wrong way |
| `TestCornerBetweenTicksLiesBetweenThem` | a move of 20 ticks: `CornerAt(0.5)` strictly between `CornerAt(0)` and `CornerAt(1)` on every tick | the hull trembles between the ticks, and what hangs on it with it |
| `TestRewindPutsTheCraftBackAtOnce` | mid-move, `Rewind`: at the file's place at once, and still there 30 ticks on | a death leaves the cordon in the sky, or flying on |
| `TestCraftKnowsWhichPartsFollow` | `HasFollower`: the gun and the iris, not the plate, not a tag nobody carries | the level's check of a track is fooled |
| `TestBadCraftRaises` | a part that turns and slides, a part that turns and hangs by no pivot, a part with no point, a craft of no body, a craft of no width: each raises `EDynamicError` | a part swings about a point it does not hang on |
| `TestBeamReadsItsLook` | a beam of no look, of "scan" and of "tractor" reads as a beam; "spiral" raises | a typo in a look draws a scanner where a tractor stands |

Left to the eye: how the parts turn and slide after the hero - the angle
and the shift are drawn, never read -; the beam's swing, its follow and
its two looks; the craft as a parent (`Render.Dynamics`), whose renderer
makes textures; the layer `aloft`.

## Levels.Dynamics: the dust

State: written, 10 tests (3.0.65). Needs no stage. Fixture `TDustTests`
in `Tests\Levels\Tests.Levels.Dynamics.pas`. The light of a field
(`TDustLight`) and a band (`TDustBand`) are records the test builds by
hand and asks; the field itself is read by `ParseDynamic`.

Shared: "the shaft" falls straight down from (100, 0) to (100, 400), 4
units wide at its hole and 40 at its end, nothing else lit. "The glow"
has its middle at the corner, its oval 100 across by 50 down. "The band"
turns its art every 100 units, rolls 10 a second, sways 5 each way over
20 seconds.

| Test | Holds | Turns red when |
|---|---|---|
| `TestShaftIsBrightestOnItsAxis` | at y 200: the axis brighter than 10 off, 10 off brighter than 60 off; the same 10 off either side | the shaft is drawn off its axis, or lopsided |
| `TestShaftWidensAsItFalls` | 10 off the axis: brighter far below than near the hole | the shaft is a rod, or a cone the wrong way up |
| `TestNothingIsLitAboveTheHole` | on the axis's line: lit just under the hole, dark just over it | the light runs up past the vault |
| `TestGlowFadesFromItsMiddleAsAnOval` | the middle brighter than 60 aside, 60 aside brighter than 60 above; 600 away gone | the glow is a disc, or its reaches are swapped |
| `TestAmbientLightsEverywhereAlike` | an ambient alone: the same level at four points far apart | the ambient leans on a place |
| `TestSeamRollsWithTheSpeed` | the seam at the edge at the start; 25 after 2.5 s to the right, 75 to the left; a turn later where it was | the dust drifts the wrong way, or at the wrong pace |
| `TestSeamStaysInTheArtAfterHours` | 1 to 6 hours on, both ways: the seam inside the art, and a second moves it by the speed | a long session makes the bands judder or stop |
| `TestSwayStaysWithinItsReach` | over a cycle: never past the sway, nearly all the way both ways; a cycle later where it was | a band wanders off its line |
| `TestDustReadsFromItsFile` | a field of one band reads as dust, on the layer `sky`; with "aloft" on `aloft` | the dust is drawn over the spurs it should hide behind |
| `TestBadDustRaises` | no bands, an empty list, a band of no sprite, a density past 100, a shaft from a point to itself, a shaft of no width, a glow of no height: each raises `EDynamicError` | a typo in the file draws nothing and says nothing |

Left to the eye: the drawing - the mesh, the runs at the seam, the
additive light, the tint of the light -; the bands behind the static
objects; the sway and the roll as they are seen; the art of
`dust.mset`.

## Scenes.Director

State: written, 16 tests, green on the first run (3.0.62). The unit is
tried by
`Tests\Scenes\Tests.Scenes.Director.pas`, fixture
`TSceneDirectorTests`. Needs no stage, but opens the mixer: the
director keeps hold of the sound bank, and `TSoundBank.Create` calls
`Mix_OpenAudio`. The fixture sets `SDL_AUDIODRIVER` to `dummy` and makes
the bank once for all its tests: it plays to nowhere, or, if the mixer
does not open, it is off. No scene of the tests plays a sound or prints a
line, and the message board is `nil`. This is the one exception to "No
window" (`TESTING.md`), decided with this unit.

Shared in the unit: "the stage" is the open room of `LevelFromRows` with a
pad `lift` at (224, 224), a dormant pad `sleeper` at (96, 224) and a scene
of its own that wakes it (the level loads no pad that sleeps for ever), a
craft `ship` at (0, -100), and two gravels as entities, `prey` and
`rider`. The test makes the bodies itself from those entities, with no
art, and puts them in `Field.Monsters`; the field stands over a level of
no entities, so it asks for no art. "A tick" is the game's order: the
director, the pads, the dynamic objects. "Elsewhere" is screen 2: the
director asks no level about it. "The aftermath of the lift" flies `lift`
to (64, 224) at once.

| Test | Holds | Turns red when |
|---|---|---|
| `TestCueActsFromItsTickOn` | a move at 10 over 20 ticks: the craft at its place after 10 ticks, there after 30 | a cue plays a tick early or late, or not at all |
| `TestCueAfterAnotherPlaysItsDelayLater` | `a` at 5, `b` after it, a third 4 after `b`: after 5 ticks nothing; after 6 both `a` and `b`; after 9 the third has not played; after 10 it has | a chain with no delay plays a tick apart (the pad leaves before the beam comes on), or the delay is counted from the start |
| `TestWaitHoldsWhatComesAfterUntilTheDeckIsEmpty` | `rider` stood on `lift`, a wait on its deck, a move 5 after it: 40 ticks, no move; `rider` removed, 5 more ticks, no move; one more, the move | the pad of the cordon leaves with the tank still on it, or the cues after a wait count from the scene's start |
| `TestCorpseOnTheDeckHoldsNothingUp` | `rider` on the deck struck down: the wait holds the tick after | a dying tank keeps the pad at the dock for ever |
| `TestSceneIsStartedByItsIdInAnyCase` | the scene `s` started as `S`: it plays | an event the load lets through by its id in another case never plays its scene |
| `TestSceneThatHasPlayedDoesNotStartAgain` | played, the craft put back by hand, started again: nothing moves | the scene plays twice in a life, each time the hero comes back on its screen |
| `TestLeavingMidSceneLandsItAndLeavesTheAftermath` | 20 ticks into a move of 50, a tick elsewhere: the craft where its move ends, the lift where the aftermath puts it | the hero who runs off in the middle comes back to a hull halfway down and a pad still at the hatch |
| `TestLeavingAfterTheEndLeavesTheWorldAlone` | 60 ticks after a move of 50, a tick elsewhere: the lift where it stood | the scene is never over, and the aftermath lands on a world that has moved on |
| `TestDeathMidSceneTakesItBackToTheStart` | 20 ticks into a move of 100, `ReArm` on its screen: the craft at its place at once, no aftermath; started again, 20 ticks on it stands where it stood the first time | a death in the middle leaves the hero with the end standing, or the scene goes on from the middle |
| `TestDeathAfterTheEndPutsTheAftermathOnAnyScreen` | a scene played to its end, `ReArm` elsewhere: the lift flown, `prey` dead; the pads rewound and `ReArm` on its screen: flown again; started again: nothing moves | the betoner of 9999 lives is back as a shooter after a death on another screen, or the cordon comes again |
| `TestSceneOfALifeIsRewoundByADeathOnItsScreen` | once a life, played: `ReArm` elsewhere, the craft put back, started - nothing moves; `ReArm` on its screen, started - it plays; the lift never flown | a scene of a life replays after a death anywhere, or never, or puts an aftermath |
| `TestShakeRunsFromItsCueToARewind` | a shake at 3: `Trauma` 0 after 3 ticks, above 0 after 4; `ReArm` on its screen: 0 | the ground shakes before the cordon is heard, or on after a death |
| `TestJoltIsOneBlowTakenOnce` | a jolt of 40 at 3: `TakeJolt` 0 after 3 ticks; 0.4 after 4, then 0 taken again; 0 a tick later | the rocks of screen 11 come free without a blow, or every tick after deals one |
| `TestCuesActOnTheBodiesTheyTag` | hold, release, kill and remove at 0, 2, 4 and 6: `prey` held and `rider` not; `prey` released - neither held nor asleep; `rider` dying, `meDied` and nothing more; `prey` dead, no event | a scene's kill pays a burst, a release leaves a tank asleep, a hold holds every body |
| `TestSpawnStandsTheBodyItsTagNames` | a spawn of `rider` seated on `lift`, facing right, asleep: no body more; `rider` at (224, 224), the deck under its feet, facing right, asleep | a death past the cordon's end puts a second tank on the roof, or one that falls through the pad |
| `TestSpawnLeavesADeadBodyWhereItLies` | `prey` killed, then a spawn of it: no body more, it stays dead where it lay | the scene raises the dead it has just burnt |
| `TestWakeAndFlyBringTheSleepingPad` | a wake and a fly over 20 ticks: asleep before; awake and flying after a tick; where it is flown 25 ticks on | the pad of the cordon never comes out of the hatch |

Left to the eye and to the ear:

- `track` and `aim`: what they tell the parts, the beams and the lightning
  is drawn, never read (`Levels.Dynamics`, above).
- `intensity`: the level of a dynamic object is not read from outside.
- `shade` (`DrawShade`), `music` (the bank keeps the volume to itself),
  `sound` and the held sounds through a pause, a cut and a rewind.
- `hint`: the line of the terminal; no message board here.
- A `spawn` that brings a body nobody carries: the field asks the
  renderer for its art (`SpawnStanding`), which waits for the stage.
- That a scene's kill pays nobody: `RewardMonsterKill` is the game's
  (`Moon2D.dpr`); the body's side - no `meBurst` - is above.
- The order the game ticks the director in (`Update` of `Moon2D.dpr`), the
  pause under the menu, and the scene a death interrupts while the hero
  falls into the pit: the cordon's live run.

## Levels.Dynamics: the back ease and the eclipse (3.0.67)

State: written, 4 tests. Needs no stage. `TestBackEaseRunsPastItsMarkAndSettles` joins `TCraftTests`; fixture `TEclipseTests` in `Tests\Levels\Tests.Levels.Dynamics.pas` reads an eclipse from JSON (`ParseDynamic`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestBackEaseRunsPastItsMarkAndSettles` | a craft sent 100 units over 40 ticks by `back`: its corner goes past the mark, by under 5%, and stands on the mark when the ticks are out and 10 after | the rocks of screen 11 stop short, bounce, or never settle |
| `TestEclipseReadsFromItsFile` | reach 70, depth 75, rim 34: the void look, 70, 0.75, 34, on the back layer; with reach alone: no rim, depth 0.8 | the black glow reads its numbers from other keys, or covers the stone (a layer over the monsters) |
| `TestWaveIsTheOtherLook` | `"look": "wave"`, reach 340: the wave, 340 | the wave is read as a second void |
| `TestBadEclipseRaises` | no reach, a reach of 0, a depth of 120, a rim of -1, the look "hole": each raises `EDynamicError` | an eclipse of no size loads and draws nothing |

Left to the eye: the dark, the halo and the wave as they are drawn, and the pace of a dynamic object - only the dust minds it, and its drawing is not tried.

## Levels.Scenes: the pace and the eased fly (3.0.67)

State: written, 2 tests and 3 more refusals in `TestCueWithoutWhatItNeedsRaises`. Needs no stage. They join `TLevelScenesTests`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestFlyEasesOnlyWhenTold` | a fly with no ease is not eased; one with `"ease": "back"` is, with `meBack`, x 290, y 256 | the cordon's lift loses its pad's braking, or the rocks of screen 11 fly as a pad brakes |
| `TestPaceReadsItsTargetAndShare` | `pace` of "dust" to 0 over 15: `ckPace`, the target, 0, 15; to 50: 0.5 | the dust is told another share, or never stilled |
| `TestJoltReadsItsShare` | `jolt` of 40: `ckJolt`, 0.4; no value, a value of 120 - refused | a blow of screen 11 lands at another strength, or a jolt of nothing loads |

Refusals added: a pace with no target, a pace past 100, a fly of an unknown ease.

## Levels.Events: heroStands (3.0.67)

State: written, 3 tests. Needs no stage. Fixture `TLevelEventsTests` in `Tests\Levels\Tests.Levels.Events.pas`: the parser over a root of the test's events (`ParseLevelEvents`, `ELevelEventError`), the grid through `LevelFromRows` (`ELevelError`).

| Test | Holds | Turns red when |
|---|---|---|
| `TestHeroStandsReadsItsCell` | `"x": 8, "y": 8`: `ecHeroStands`, cell 8, 8 | the stone wakes for a hero in another cell |
| `TestHeroStandsWithoutACellRaises` | no cell, no y, a column of 0: each raises | an event of no cell loads and never fires |
| `TestHeroStandsOffTheGridFailsToLoad` | column 17 on a grid of 16 raises | a cell nobody can stand in loads |

Left to the eye: whether the hero stands in the cell - his middle, his feet, not in a jump - is the game's (`HeroStandsIn` of `Moon2D.dpr`).

## Scenes.Director: the takeover and the order of the rewinds (3.0.69)

State: written, 2 tests. They join `TSceneDirectorTests` and its stage; the stage's scene that wakes the sleeper is `WakingId` now.

| Test | Holds | Turns red when |
|---|---|---|
| `TestSceneStartedMidAnotherTakesOverFromIt` | ten ticks into a move of fifty, the waking is started: a tick later the craft is at 200, the lift where the aftermath flies it, the sleeper awake | the stone taken before the waking is over leaves the rocks standing |
| `TestRewindOfALifeLeavesTheAftermathOfALevel` | a scene once a level moves the craft to x 200 (its aftermath too), one of a life to y 50; a death: x 200, y back to the file | a death after the fall leaves the dust of screen 11 running over the stone that waits again |

Left to the eye: that the old scene's sounds play on and the music, the shade and the rumble carry over - the volume and the shade are not seen here.
