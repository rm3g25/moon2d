# Tests of the monsters

Tables of the tests, one section per unit under test: the test's name,
what holds, the breakage. The rules and the conveyor are in
`../TESTING.md`; a new unit's table goes into the file of its namespace.

## Monsters

State: written, green (239 in the suite). The first suite over
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
  scale 1. `Room.Place(APlacement)` is the same for a placement with its
  overrides filled in; the room sets the screen.
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

State: written, 13 tests, green (291 in the suite). Eleven were green
before (239 in the suite then); the two of `Collect` came with
`Game.Uptake` and were green on the first run. The
expectations were checked on a Python port of the monster's floor physics
(the oracles, the patrol, the fall, the death) with the corpse rule
switched on and off: with it off, test 6 is red. The unit is tried by
`Tests\Monsters\Tests.Monsters.Bodies.pas`, fixture `TMonsterBodyTests`.

Shared setup: `Tests.Rooms`, as above. `RoomRowsOf` (the rows of a room
with a wall column and a ledge) lives there now, for both monster units;
the corridor - the floor and two solid columns, 5 and 12, their faces at
x = 160 and x = 352 - is built from it in the unit. The subjects are the
`gravel` (a patrol walker that turns at a ledge's end) and the
`gravelFemale` (walls only). Neither explodes, so both die into a `nil`
burst. A body is laid dead by one blow for all its lives and a hundred
ticks at most. The pickup the hero takes is a `medkit`, on the floor.

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
| `TestCollectedPickupIsGoneAtOnceAndTellsTheGameOnce` | floor, a medkit, alive; `Collect`: `mlDead` on the spot, never `mlDying`; `DrainEvent` gives `meDied`, then `meNone` | a taken pickup stays alive and is taken again on the next tick, or its sound is not played, or played twice |
| `TestCollectedPickupIsNotKilledByALaterBlow` | a medkit collected, then struck for all its lives: still `mlDead`, no second `meDied` | a blast of the same tick finds a taken pickup dying: the game rewards it as killed and bursts it as a wreck over its own uptake |

Left to the eye:

- The corpse of the boss. It flies and ignores gravity: it hangs where it
  died by design (`Monsters.Pilot`), and it needs the textures of its disc.
- A body that ignores gravity (the platform, the mount) hanging in the air.
  Both carry a gun that fires into the `nil` burst on its interval, and
  both carry smoke or art the room does not build.
- A corpse over a pit. The fall out of the world below the floor line is
  the 2008 behaviour, and no test pins it.

### Weather (3.0.58)

State: written, 5 tests. They came with 5.3; stage 5 was run live. They
join `TMonsterBodyTests`. A barrel now dies into a `nil` burst too: its
blast is the game's to send out, and the header of `Tests.Rooms` says so.

Shared: `HoledRows(From)` - the floor with a hole three cells wide;
`TickWhileAlive` ticks a body until it is no longer alive, a hundred and
fifty ticks at most. The subjects are `skyBarrel` (weather) and `barrel`,
put at row 2, in the air.

| Test | Holds | Turns red when |
|---|---|---|
| `TestWeatherBurstsWhereItLands` | floor: the sky barrel is `mlDying` with its feet on the floor (y = 352); `DrainEvent` gives `meDied`, `meBurst`, then `meNone` | it bursts in the air, never, or without telling the game: no blast |
| `TestWeatherBurstsOnALedge` | ledge: it is `mlDying` with its feet on the ledge (y = 256) | weather asks the floor alone and falls through what it lands on |
| `TestWeatherThePitTakesIsGoneWithoutABlast` | the barrel over the hole, three hundred ticks: `mlDead`, no event; a hundred and fifty ticks on, it has not moved | a barrel the pit takes blows up under the screen, or falls for ever |
| `TestWeatherBurstsOnce` | `Burst` twice, then a hundred and fifty ticks with a landing in them: `meDied`, `meBurst`, `meNone` | a second burst, or the landing, sends a second blast |
| `TestBarrelOfTheLevelsLandsAndStands` | the barrel, a hundred and fifty ticks: alive, on the floor, no event | weather leaks to the barrel: every barrel of the levels blows up where it stands |

Left to the eye: the burst on the hero (`ResolveMonsterContact`) and the
blast, the shards and the score the game gives a burst body, in
`Moon2D.dpr`.

### What a scene does to a body (3.0.62)

State: written, 7 tests, not run yet. They join `TMonsterBodyTests`: the
hands a scene lays on a body - asleep, its fire held, struck down, taken
away, stood where it says. The hold of the fire is seen through the `nil`
burst: a shot into it stops the run with an access violation, so a
betoner that fires is a raise and one held is none. The first half of
that test is the control: a betoner left alone raises within 60 ticks,
or the room sees no shot and the held one proves nothing.

Shared: `Tests.Rooms` grows `RoomFromRows(ARows, ASections)` - the room
with more members in its level, pads of no sprite among them - and shows
the room's `Level` and `Pads`. "The deck" is a pad of no picture at (224,
224). A body "walks within" N ticks when it stands off its start on any of
them: a patrol comes back past its start, so its last place proves
nothing.

| Test | Holds | Turns red when |
|---|---|---|
| `TestDormantBodyStandsStillAndSleeps` | a gravel on the floor made `Dormant`: it does not walk within 200 ticks and is `Asleep`; woken, it walks within 200 | the tank on the pad drives off the deck on the way down, or never wakes |
| `TestDormantBodyStillFalls` | a gravel in the air made `Dormant`: on the floor 150 ticks on | a sleeper hangs in the air when its deck leaves |
| `TestHeldBodyWalksAndHoldsItsFire` | a betoner left alone: 60 ticks raise (the control); a betoner `Held`: 300 ticks raise nothing, and it walks within them | the hold is lost - the betoner in the pit shoots the hero who looks up - or the hold freezes its feet |
| `TestSmittenBodyDiesTellingOnlyItsDeath` | `Smite`: `mlDying`, `meDied` and then nothing - no `meBurst`; struck again, nothing | the game blows up the body a scene burns, or tells its death twice |
| `TestRemovedBodyIsGoneWithNoDeath` | a gravel in the air, `Vanish`: `mlDead`, no event, and 150 ticks on it has not fallen | a removed body plays its death sound, is paid for, or goes on falling |
| `TestStoodBodyIsPutAtRest` | a gravel thrown in the air, `Stand(160, floor, right)`: there, facing right, not `InFlight`; a tick on it walks right | the tank stood on the roof keeps its throw or its fall, or faces the wrong way |
| `TestBodyStoodOnADeckHasItUnderItsFeet` | stood on the deck: `DeckUnderFeet` is the deck; stood on the floor: none | the wait for an empty deck never sees the tank on it |

Left to the eye: the eye of a hull dark at once in its sleep (`Doze`,
`Monsters.Hull` above) on a body that needs its art; the wheels at rest
after `Stand`.

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

### The shelf (3.0.51)

State: designed, not written - needs the stage. The shelf is the one of
`Pads.World`.

| Test | Holds | Turns red when |
|---|---|---|
| `TestBodyOnAShelfFallsWhenItSlidesIn` | a medkit, and then a gravel on a shelf 96 wide, stand on its deck through the stand; a hundred and fifty ticks after the slide in begins each is on the floor (y = 352) | a monster asks no deck of a shelf in the wall: a medkit hangs over the pit |
| `TestBodyDroppedOnAShelfThatIsInFallsToTheFloor` | a gravel dropped over the shelf in the wall lands on the floor; one dropped over it while it is out lands on its deck | a shelf in the wall catches a falling body, or a shelf that is out does not |

## Monsters.Damage

State: written, 9 tests, green (239 in the suite). The expectations were
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

## Monsters.Mount

State: written, 11 tests, green (239 in the suite). The expectations were
checked on a Python port of the strip and of the offset's range. The unit
is tried by `Tests\Monsters\Tests.Monsters.Mount.pas`, fixture
`TMountTests`: the TeK mount in an open room, the hero two numbers handed
to `Tick`.

Two things are tried: the fire offset of a placement (the tick a mount
starts counting from) and the sentry (a mount asleep until the hero stands
in the strip under it). The way in is `Room.Place(APlacement)` with the
overrides filled in, and `TMonster.Asleep`, a read-only property of the
state the monster keeps anyway.

The mount stands at column 8, row 3 (the middle of its cell is x = 240, its
feet line y = 96); the hero is on the floor (feet at y = 352), his left
edge as far from the mount's own as the test says. Equal X is a hero
centred under the mount. The reach of the strip is read from the mount's
definition, not spelled: it is tuned by eye, and the tests hold its shape
(an edge, both sides, one unit beyond), not its width.

A mount fires when its count reaches its interval, and the room has no
burst to take the volley (a burst needs a renderer): no test here ticks a
mount for more than a few ticks.

| Test | Holds | Turns red when |
|---|---|---|
| `TestMountIsBornAsleep` | a fresh mount, no tick: `Asleep` | the sentry is born awake: it would fire a volley at an empty screen on the first tick |
| `TestHeroUnderTheMountWakesIt` | the hero right under it, one tick: awake | the strip is never found, the mount sleeps for ever |
| `TestHeroFarToEitherSideLeavesItAsleep` | the hero three reaches off to the right, then to the left: asleep both times | the sideways distance is not asked |
| `TestStripEdgeIsInAndOneUnitBeyondIsOut` | the hero at exactly one reach off the middle: awake; one unit beyond: asleep; on both sides | the strip is measured from the hero's edge and not from his middle, is lopsided, or its edge is left out |
| `TestHeroLevelWithTheMountIsNotInTheStrip` | the hero's feet on the mount's feet line: asleep; one unit lower: awake | "below" turns into "level or below": the mount fires at a hero its bullets fall past |
| `TestHeroAboveTheMountIsNotInTheStrip` | the hero in line with it and 64 units above: asleep | the mount shoots up through the ceiling it hangs from |
| `TestMountFollowsTheHeroInAndOut` | under it (awake), away (asleep), under it again (awake) | the sleep sticks once woken, or the wake once slept |
| `TestMountThatCannotShootStaysAsleep` | `canShoot` false, the hero under it for three ticks: asleep | a mute mount lights its eye and watches |
| `TestBodiesWithoutASentryNeverSleep` | a medkit and a gravel, the hero far off: not asleep before the first tick nor after three | the sleep leaks to bodies with no sentry word |
| `TestFireOffsetFromZeroToBelowTheIntervalLoads` | offsets 0 and interval minus 1 place a mount | the high end is cut one tick short |
| `TestFireOffsetOutsideTheIntervalRaises` | -1, the interval and the interval plus 1 raise `ELevelError` | an offset past the interval loads: the first volley would come at once or never |

Left to the eye:

- The volleys: the first one 23 ticks after the hero comes under the
  lower mount of screen 6 and 45 after the upper one; the gap of 22 and
  23 ticks between the pair ("boom - boom"); a hero who leaves and comes
  back starting a full count again. The Python port of the count gave
  23, 68, 113 and 45, 90, 135.
- The lens rising over the ramp as the hero steps in, and going dark as
  he steps out.
- The strip does not look at walls: a hero behind a slab in the strip
  wakes the mount and the volley goes into the slab.
- The mount builds sparks and a bolt of lightning at its birth (it can
  short out); if they need a window the first run shows it, and the
  whole fixture goes red at once.

## Monsters.Hull

State: written, 4 tests, green (239 in the suite). The expectations were
checked on a Python port of the ramp. The unit is tried by
`Tests\Monsters\Tests.Monsters.Hull.pas`, fixture `THullTests`: the hull
of the mount (its definition is read from `monsters.json`) made with no
art. A tick of a hull moves numbers and never touches a picture; `Draw`
is not called.

The ramp is tuned by eye (8 ticks as written), so no test spells it: a
test asks that the eye is on its way after one tick and all the way within
a second (33 ticks), never moving back on the way. `THull.Wake` is the
read-only property the tests look through: 0 the eye dark, 1 the eye
smoldering at its rest level.

| Test | Holds | Turns red when |
|---|---|---|
| `TestHullIsBornAwakeAndLit` | a new hull: `Awake`, `Wake` 1, and 1 still after a second of ticks | a hull is born dark: every tank and platform would start with a dead eye |
| `TestDozedHullIsDarkAndStaysDark` | after `Doze`: not `Awake`, `Wake` 0 at once, and 0 after a second | the dozing hull is lit for a moment (a flash at birth), or wakes by itself |
| `TestWakingHullComesUpByDegrees` | dozed, then `Awake`: one tick puts `Wake` strictly between 0 and 1; over a second it never falls and ends at 1 | the eye jumps to full in a tick, or never gets there, or stutters |
| `TestHullPutToSleepGoesDarkByDegrees` | awake, then not: one tick puts `Wake` strictly between 0 and 1; over a second it never rises and ends at 0 | the eye cuts out at a stroke when the hero leaves, or never goes out |

Left to the eye: how the glow looks at each step (`Draw`), and that the
resting eye is a smolder and not a flame.

## Monsters.Defs

State: written, 5 tests, green (239 in the suite). The unit is tried by
`Tests\Monsters\Tests.Monsters.Defs.pas`, fixture `TMonsterDefsTests`,
through `TMonsterRegistry`: the real `monsters.json` beside the executable
for what the game's definitions say, and a one-monster file of the test's
own (`post`, a static `rainVolley`) for what the sentry word of an attack
makes of its input.

| Test | Holds | Turns red when |
|---|---|---|
| `TestMountIsASentryWithAReach` | the mount of `monsters.json`: `Sentry.Enabled` and a `Reach` above 0 | the word is dropped from the file or misspelled: the mount is blind again |
| `TestOtherAttackersAreNoSentries` | gravel, platform, tank and zombie shooter are no sentries | the sentry becomes a default of every attack |
| `TestSentryReadsItsReach` | `{"reach":30}`: enabled, reach 30 | the reach is read from another word, or lost |
| `TestAttackWithoutSentryIsNoSentry` | an attack with no sentry word: not enabled | a missing word counts as a sentry |
| `TestSentryWithNoReachRaises` | reach 0, reach -5 and `{}` each raise `EMonsterDefError` | a sentry of no width loads: it would never wake, and no one would see why |

Left to the eye: nothing here is drawn. The number in `monsters.json`
(48 at the first go) is tuned in a live run.

### Weather (3.0.58)

State: written, 3 tests. They came with 5.3; stage 5 was run live. They
join `TMonsterDefsTests`: the weather word, on the real `monsters.json`
and on a one-monster file of the test's own (`drop`, a static prop).

| Test | Holds | Turns red when |
|---|---|---|
| `TestSkyBarrelIsWeatherThatPaysNothing` | `skyBarrel` of `monsters.json`: weather, a score of 0, a blast; `barrel` is not weather | the sky barrel stands where it lands, pays a score, or does not blow up; the barrel of the levels bursts on landing |
| `TestBodyWithNoWeatherWordIsNoWeather` | a body with no weather word is no weather | weather becomes a default: every body bursts where it lands |
| `TestWeatherFreeOfGravityRaises` | `"weather":true` with `"affectedByGravity":false` raises `EMonsterDefError` | weather that never falls loads, and never lands to burst |
