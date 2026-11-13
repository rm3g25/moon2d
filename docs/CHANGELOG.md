# Changelog

What each version brought, newest first. These paragraphs were the
status chain at the head of `PORTING-NOTES.md`; they are kept as
written. Where one says "the session below", the session is now in the
journal of the mechanic's file under `mechanics/` (see `README.md`).
Versions before 2.2.0 have no entry here: their story is
`PORT-JOURNAL.md`, the roadmap of the port as it was kept.

2026-11-14: **3.0.130 - the gate.** The sealed door of arena 3 has a
body: a facade with a gate in the manner of the city - a capsule roof, a
ribbon of windows, a burnt-orange stripe, two ribbed leaves shut - on the
far end of the road that comes back at the end of the flight (`Game.Gate`,
new; the picture `s13-gate` in `level2-objects.mset`, packed by
`tools/gate/build_gate.py`). It has no place of its own: it stands a fixed
way along the road, rides in with it in the slowdown - its edge showing
after the last blast of the hull - and stops with it, its right side at
the right edge of the screen, 392..512; the road knows it came back
(`TRoadEnd.Arrived`), so the pier of the road running out has no gate. Its
front-lit picture is put in the night at 35%. Over its unlit lamp housing
burns the game's light, a signal lamp as the beacons are drawn (`DrawLamp`
of `Levels.Dynamics`, public now): red while the gate is sealed, amber over
half a second once it is promised to open (`TGate.Promise`) - the cue of
the titles' flare, which is not built; the debug key X gives it till then.
The gate stays shut: it opens in level 3. On the stand a `gate.png`
dropped on the stage is taken now (its id was not among those the stage
takes). The end track comes in with the hull's burst now, a second after
the last orb, at once and with no fade of ours - it came 10 s after, over
a fade of two more, and its own first bars come from far off: too much
silence; the hand-over a breath after the stand stays, the titles' cue.
10 tests more.

2026-11-13: **3.0.129 - the farm under the long dome.** Stage 19a of
arena 3: at the end of the city's strip, where the crater had an empty
tail, stands a long dome - a capsule, a barrel vault with a quarter dome at
each end, its glass on a diagrid with heavy belts every four cells, its
ends' ribs fanning out of the poles at the foot - and under it 86
greenhouses of their own sheets, their glass glowing magenta, amber and
blue (`Levels.Capsule`, new). Each greenhouse's grow light burns on a clock
of its own: lit for most of its spans, dark for some, catching with a
flicker and warming up like a sodium lamp when it comes on; the lit glass
fills the dome's air with its colour, lights the inner face of the far
ribs and spills onto the crater floor in front of the dome, gapped by the
ribs' feet (`Levels.Farm`, new; the glass a picture of its own,
`<id>-glow`, drawn over the shaded piece and not shaded). The city's brake
parks the dome in the frame by the end of the air fight, the sun behind it
turning pink; while the dome stands before the sun its glare gives way to
the glass, down to 0.3 of itself, so the greenhouses round the disc do not
wash out. Built on the stand first (the mode "the flight"), then in the
game tick for tick, checked against the stand by the numbers. On the
stand, the capsule's feet, crown and ends' tips are exact zeros now - the
crown no longer changes halves with the sign of a `cos(PI / 2)`, the feet
throw no shadow of no length - and a beacon's seed takes its row, so the
crown's lights no longer blink in pairs. `Render.DomeFrames` holds every
frame's edges in units and draws a rib in its own dark; the frames'
projection is `TFarPlaneDef.FramePoint` now. The pit has a bottom: a body
fallen out of a room hangs a screen under the floor, still in the pit,
where in 2008 it fell for good - after half an hour of the world standing
at the end of the flight its feet passed the reach of an Integer cell and
the game fell over. 41 tests more.

2026-11-12: **3.0.128 - the end in the air.** Stage 19 of arena 3: the
fight ends at the hull's last life. The hull cracks - a flash, a groan of
torn plates - and for a second lurches to its place over the middle of
the screen, shuddering, its jets coughing, a few small blasts on it; then
it bursts with a boss's blast into twelve big pieces - its picture cut
three by two, the engine bays, the nozzles, the magnet and the mortar -
which fall slowly, as the moon pulls, each in a trail of fire and smoke
the flight's wind streams back, while the series blows them up one after
another (`Game.Breakup`, `Game.Wreckage`, new). The flight's track is cut
at the crack and the hull's bar goes up out of sight. From the crack on
the hero is spared: the moon form comes off in a ring of
its own dark orbs, which carry him onto the main barge if he is not on it;
what flew at him bursts harmless, no small barge comes in, the barge the
magnet held falls burning. Two seconds after the burst the flight slows to
a stand over six seconds, the small barges leave off the left edge, the
main barge glides to its berth in the middle of the screen and waits; the
road comes back from beyond the right edge, the barge docks against its
edge and rides on with it, and the world stops with the barge against the
left edge of the screen - nowhere left to fall. His keys stay his; the key
down drops him through neither the main barge nor the road, the whole air
fight (`HeroOnTheHarbour`, `TMoonGame.DockBarge`)
(`Game.Landing`, new; `TBelt.Run(speed, ticks)`, `RampTravelLeft`,
`TRoadEnd.Arrive`, `TBargeRide.Berth`, `Dock`, `Ride`, `TBargeFlock.Close`, `Disperse`,
`Drop`, `THullLives.Retire`, `THenshin.RemoveForm`,
`THeroOrbs.ShedMoonSuit`). A dock, two seconds of silence over the still
picture, and Legendary comes in over two seconds - the hand-over to the
titles, which are still to come; till then the picture stands and Escape
opens the menu. Four new sounds (`tools/sounds/finale.py`): the crack's
groan, the burst, the flight winding down, the dock. The key O on the
finisher's stretch takes the hull to its last life, then that one. And
from the live run: a small barge the dive smashes over the main barge is
crushed with no shrapnel - its fan rained on a hero under the hull, out
of a barge the hull hid, too close to dodge (`OverTheHarbour`).

2026-11-12: **3.0.127 - the ladder.** The air fight's rungs, the choice of
the turn and its chains are a unit of their own (`Game.Ladder`, new): the
hull's lives are 240 on the first grade (the grades' share for the hull
1.0, 1.25, 1.5), the rungs at 15%, 33% and 60% spent and the finisher's
stretch from 85%. After each window of the magnet the turn goes to one
of the rung's weapons at random, never the last one, the rung's newest
first; the mortar lobs two shells on its own rung, one after. On the
last rung, once the dive has been seen, about half the magnet's cycles
chain: the dive the moment the barge is thrown - the magnet tucked in
hot, its window lost - or a shell at his feet while the magnet holds its
shield. On the last stretch the finisher: the charge goes right through
the screen without a brake, then a red band blinks along the top edge
over where he stands and the hull drops out of the sky as the dive does
(`TChargeEnd.ceThrough`, `TDive.StartAbove`, `TTakeoff.Settle`). The
flock grows by the rung, 2, 3, 3, 4. Point C at the door of the third
rung: a death after it comes back aboard with the hull's lives of that
door; the End key's fifth stop; the key O aloft goes to the next door.
The hull shows its wounds: its worn copy, never shown before, fades in
with the lives spent, and from the third rung it shorts out over its
cracks and smokes, harder rung by rung; on the finisher's stretch thick
bolts burst out of it, more as its last lives go. Fixed after the first
live run: a hero whose barge was taken from under him by the magnet or
smashed by the charge or the dive hung in the air - the deck put to sleep
after his tick was never seen gone; now the hero remembers standing on a
deck and falls when it is not there (`THero.FRidden`), and a door onto a
screen with a lower floor drops him too (`THero.LookDown`).

2026-11-12: **3.0.126 - the dive.** The air fight's fourth rung
(`AirTierSpent` 0.67): the turn after the magnet's window goes round the
rung's weapons - the dive, the charge, the mortar - the dive first
(`Game.Dive`, new). All but no warning: the Ram's eye flashes, its jets
go out and for half a second it only sags in the silence; then it drops
like a stone, straight down, to just over the head of a hero standing on
the main barge - he is never struck there. A small barge in its way is
smashed into shrapnel: the bullets of a 2008 fan, the monsters' own, that
wound; a hero under it in the air or on a small barge is struck once and
knocked aside. The main barge rocks and the screen shakes. Low, riding
the main barge's deck, its jets catch again hot for about 3 s - an orb on
a nozzle takes a life, the honeycomb down - and their fire burns a hero
standing under a nozzle and throws him out of it: the place to stand is
under the belly between them. Then it rises to hang. The takeoff's jets
can be put out and lit again (`TTakeoff.Douse`, `Relight`); the charge's
and the dive's sweep are one (`TRam.HullSweep`, `HullStrikes`). New
sounds: `divecut.wav`, `divefall.wav`, `diveslam.wav`, `diverelight.wav`
(`tools/sounds/dive.py`).

2026-11-12: **3.0.125 - the charge.** The air fight's third rung (`AirTierSpent`
0.43): the turn after the magnet's window goes to the charge and the
mortar by turns, the charge first (`Game.Charge`, new). The magnet tucks
into the belly, the Ram falls back past the left edge, and a red band
blinks at that edge across the corridor it will run along, its eye red
there, for 1.3 s; then it rams in from behind at speed, low - its belly
just over the head of a hero on the main barge - smashing every small
barge it meets into pieces and knocking a hero in its way along and down
with a wound; it brakes short of the right edge, bow up, its nozzles
swivelled ahead and the fire thrown forward, and hangs there low for
2.5 s with its nozzles hot - an orb on a nozzle takes a life, the
honeycomb down - then climbs back to hang. While it runs no small barge
comes in. The charge carries the flight (`TTakeoff.Carry`); the nozzles
swivel with the flight from now on, within 12 degrees
(`TTakeoff.SwivelAt`). New sounds: `chargewarn.wav`, `chargerush.wav`,
`chargebrake.wav` (`tools/sounds/charge.py`).

2026-11-11: **3.0.124 - the knocked barge burns and lists.** After the
live run of 3.0.123: a barge knocked off by a shell burns where it was
struck - a flame, a flickering glow, thick black smoke the flight's wind
streams back and the shorts of its torn wiring crackling out in small
bolts (`Game.BargeFire`, new) - and lists to that side, jolted at
once, then heeling over more and more, the steeper the farther from its
middle the hit (`TBargeFlock.Heel`). The list is drawn, not felt
(`TPad.Heel`): the deck stays level, but a rider is drawn on the listing
picture and slides down it toward its low end, at about 30 degrees as
fast as he walks (`TPad.RiderSlide`, `THero.RideDeck`); what hangs on the
barge turns with it, and its dead engine puts its lamps and its jet out.

2026-11-11: **3.0.123 - the bombs.** The air fight climbs its first two
rungs: the rung follows the share of the hull's lives spent
(`TRam.AirTier`). On the first the magnet takes the barge nearest its
face and that is all - the player learns to dodge the thrown barges.
From the second (a fifth of the lives gone) it takes his barge first -
the lift - and after each of its windows the stern mortar has a turn
(`Game.Mortar`, new): it rises from behind the rear block with a
hydraulic whine and a clank, the magnet waits cold, two shells go one at
a time at the deck under his feet, each once the last is gone, and it
folds. A shell rides the barge it was aimed at (`TBunkerShells.Carry`), its
ring on that deck; with no road aloft one that meets no deck falls past
the bottom, with no ring. On a small barge it bursts as in the chase and
knocks the barge off its path: engine dead, it falls behind and sinks ever
faster till it is gone past the left or the bottom edge - a pad still,
so he may jump off or ride it into the pit (`TBargeFlock.Knock`); another
comes in for it, the escort at once. On the main barge it bursts and the
barge only rocks. The rings of the shells are drawn between ticks now,
the chase's too. Debug key O aloft takes a fifth of the hull's lives. New
sound: `mortarrise.wav` (`tools/sounds/mortar.py`).

2026-11-11: **3.0.122 - the honeycomb aloft.** The flying Ram wears its
honeycomb again, so the player sees why a hit fails. As the rear wheel is
thrown it kindles back outward from the magnet, cell by cell over a
second (`TTekShield.Restore`, the new state `sdRising`): over the flying
hull - rimmed under the belly too (`CreateAfloat`), its cells over the
arches, where the bays and the fire are, hidden but holding and lit by a
hit (`Hide`) - and in a ring about the magnet. Both lean and rise with
the hull (`Draw(turn)`, `TRam.BlockAloft`). As the magnet grows soft they
blink out with the window; hard again, they kindle back from the magnet
in half a second, holding from the first cell. Point B finds them up.
The bar, its word and the rules of the fight are unchanged: the magnet
alone takes a life. While the honeycomb is up no bullet rings off the
machine through it: where its outline leaves a part bare - the nozzles'
tips, the magnet's corners - it takes the bullet all the same
(`TRam.BlockBareAloft`). Every fourth small barge to come in brings a
medkit on its deck, carried with it and gone with it. The bunker's last
third - the hunt, the hull turned round - holds out twice as long: a life
every second strike (`BunkerLastThirdStrikes`), the stone's charge told
half a life a strike (`TRam.HitShare`). New sounds:
`honeycombdown.wav`, `honeycombup.wav` (`tools/sounds/honeycomb.py`).

2026-11-11: **3.0.121 - the magnet and the heat (stage 18d-2).** The Ram
fights back. He aboard at the station, a breath, and a magnet slides out
of the belly between the engine bays (`Game.Magnet`, `TMagnet`, the Ram's;
the art `magnet` and `magnetHeat` in `tek-machine.mset` by
`tools/machine/add_magnet.py`) - its first move is the start of the fight:
the barge is let go on its drift (`TBargeRide.Loose`) and the flock comes
in. From then on the magnet works in a cycle: it takes the small barge he
stands on, else the nearest (the hull flies over one out of the beam's
reach); a blue beam draws the barge up under its face - with him aboard a
hero's height lower, the lift; it holds the barge as a shield, heating,
the hum rising; then it seizes it - in a lift the press: he is wounded and
the deck is gone from under him - and throws it at him along the wrecks'
flight (`TPadWrecks.Fling`); a thrown barge wounds and knocks him, and
breaks into pieces on the main barge, which rocks (`Game.Pieces`,
`TBargeRide.Rock`); then the magnet, empty, cools - the window. The hull's
armour is whole now: an orb takes a life only in the magnet from the hold
till it is cold, everything else ricochets (17a's wound of the bare hull is
gone). It is shown: the magnet's housing is tinted hot orange over its art
and glows, the hull's bar stands grey over the word "armour" and pulses in
its colours while the magnet is hot (`THullLives.Tick(hot)`,
`Hud.HullBar`), and at the first throw of a level the terminal types
"Strike what glows". The flock gives up a taken barge and sends another -
at once for the escort (`Take`, `GiveBack`). New sounds: `magnethum.wav`,
`magnetthrow.wav` (`tools/sounds/magnet.py`). No bombs, charge or dive
yet; the flock stays at two.

2026-11-10: **3.0.120 - the barges of the air fight (stage 18d-1).** The
first step of the Ram's air fight. The hero aboard at its station, the
barge leaves it and drifts on a slow wide loop of its own - a figure of
eight lying on its side, across the middle three fifths of the screen and
half a cell up and down, never stopping, on without him (`TBargeRide`,
`bsDrift`, `Dip`, `WayDown`); the checkpoint rides its deck up and down
too. Round it flies a flock of small barges (`Game.Flock`, `TBargeFlock`;
the pads `s13-flock-1`..`-9` of level2.json, stowed, `barge-2`..`barge-4`
with their own rigs): two at once for now, each in from beyond the right
edge fast and braking to its path's pace, out past the left edge and
replaced after a second or two. One is always the escort - over the main
barge, a jump up, swaying along it - so a floor is within his jump at all
times; it is relieved by the next to come in and let go. The others fly a
lane with a swell, a few loops in place, a climb or a descent, or a pass
straight through. Riders are carried as on pads, across and now up and
down (`TPad.Carry(wayX, wayY)`); bullets burst on the barges both ways.
The Ram only hangs, as before. After the first live run, in the same
version: the pads are drawn between the ticks and in fractions of a unit
(`TPad.Glide`, `Lift` with the deck's fraction), with their riders
(`DeckSlide`, the renderer's `FineX`) and their lamps (`TParentStand.Glide`)
- the barges, and every moving pad, no longer jerk a whole unit at a time.
A death in the air fight no longer puts the hero over the abyss first: the
restart seats the barge at its station before it places him (`SeatBarge`).
Tests: `TBargeFlockTests` 17, new; `TBargeRideTests` +8 and 2 reworked;
`TPadWorldTests` +3.

2026-11-09: **3.0.119 - the cliff and the barge's lights (stage 17b-2).**
After 3.0.118 was played: no landslide - the road's tiles no longer break
off and the pier no longer collapses; the chase goes on at its cruise
after the orb launcher's take (`BeltCreep` gone), the road's end - a cliff
- comes in from beyond the right edge and rides away left, and the barge
hangs a cell past it from the start (`TBargeRide.Moor`; the glide in, the
pier's grace and `TBargeCue` gone; `TRoadEnd` is a place and an end now;
`TPad.Trim` gone, the pier as long as its pad). Aboard, the flight is
twice as fast as before - `BeltFlight` 4.0; the barge's station is the
middle of the screen (`StationLeft` 176). The barge wears the rig `barge`:
its six painted lamps flash in turn from the stern to the prow, an amber
run and a cyan run, by a new `phase` of the beacon (`TBeacon.FPhase`), and
its turbine burns - glows in the mouth, a hot flame and a grey trail.
The moon form jumps +15% (`MoonJumpBoost`), the ice form +25% as before;
a touch of the hull rising or hanging knocks the hero down and a little
aside (`THero.Knock`), no more up into it. The End key reads the next stop
off the game instead of counting its presses (`DebugNextStop`). Tests: `TRoadEndTests` 7 and `TBargeRideTests` 11, rewritten;
`TBeltTests` reworked; `TPadWorldTests` -1; `TBeaconTests` 2, new.

2026-11-08: **3.0.118 - the pier and the barge (stage 17b).** The orb
launcher taken, the chase goes on: the world moves off at a crawl
(`BeltCreep`, `TBelt.Run`), no more pads are sent (`TPadDrift.Cease`), and
the road runs out two cells past the gun - the tiles beyond `RoadBreakX`
break off one after another, the farthest first, and tumble into the
crater with a thump and a jolt, while what is left - the pier - rides the
belt as a pad trimmed to its tiles (`Game.Road`: `TRoadEnd`,
`TRoadPainter`; `TPad.Carry`, `TPad.Trim`; the grid's row erased,
`TLevel.EraseRow`). A TeK hover-barge five cells long glides in from
beyond the right edge and moors a jump past the pier's end, riding with
it; the hero aboard, it casts off to its station and the belt runs up to
twice the chase's cruise (`Game.Barge`: `TBargeRide`; `BeltFlight`); the
pier falls behind him. In the air past the launcher the belt carries him
no more - a jump off the barge lands on it. The checkpoint is the barge's
deck: a pit brings him back aboard with a wound, a death to point B -
aboard, the hull hanging bare (`TRam.StartHanging`, `TTakeoff.Hang`,
`TTekShield.Vanish`), the launcher in his hands (`TOrbLauncherArrival.Grant`),
the world at the flight's pace; the End key's 4th press goes there. The
art: four barges cut from one generation at its ribs and put together
again, never stretched (`pads.mset`: `barge-5`..`barge-2`;
`tools/barge/build_barge.py`); the pads `s13-road` and `s13-barge` are
stowed (`"stowed": true` - dormant with no scene to wake them). Tests:
`TRoadEndTests` 10, `TBargeRideTests` 12, `TLevelGridTests` 5,
`TBeltTests` +1, `TPadWorldTests` +3, `TPadDriftTests` +1,
`TRamBrakeTests` +2, `TTakeoffTests` +1, `TShieldCrumbleTests` +1,
`TOrbLauncherArrivalTests` +1.

2026-11-08: **3.0.117 - the orb launcher; he sways in the throw.** The
orb gun of 3.0.116 is named the orb launcher ("Орбомёт"), in the game, the
data, the code and the files (`orblauncher.mset`, `orblauncher.wav`,
`Game.OrbLauncher`, `weaponOrbLauncher`). Its shot's orb is smaller: a rim
of 7.2 units, not 9.2 (`Orbs.Shots`, `ShotSize`). Held in his place in the
throw, the hero sways up and down - 2 units either way over two seconds,
growing over the first swing - drawn by his lift, not moved
(`TThrowScene.Sway`). Tests: `TThrowSceneTests` +2.

2026-11-08: **3.0.116 - the orb gun (stage 17a).** Once the Ram hangs,
a breath, and the orb gun appears in the middle of the road under the
shroud of the respawn - on the next cell when the hero stands there - and
lies there, a pickup (`Game.OrbGun`, `weaponOrbGun`). Taken, it is in his
hands in place of his own gun, which is put away (`THero.StowGun`), and
the fight with the bare hull begins: the hull's lives - 150 on the first
grade, by the grade - on a long bar along the top of the screen between
the HUD's panels, coming down and lighting a cell at a time
(`Game.HullLives`, `Hud.HullBar`). The art is the generated white
blaster, `orbgun.mset` (`lying`, `held` 16 units long, `gone`;
`tools/orbgun/build_orbgun.py`). It fires one black orb a shot, a
cooldown of 4 (`OrbGunWeapon` 6, `blOrb`, its look `Orbs.Shots`, its
sound `orbgun.wav`); an orb that meets the bare hull takes a life of it
(`orbhit.wav`), the nozzles and the wheels throw it off - the nozzles,
out of the body's grid, now throw any shot off (`TRam.StrikeNozzles`).
The shroud's painter is handed a figure - its frames and its pose - in
place of the hero (`TShroudPainter.Create`, `HeroShroudFrames`), so the
gun wears one too. The world stands till 17b; a death goes to point A,
the old gun back in his hands. Tests: `TOrbGunArrivalTests` 9,
`THullLivesTests` 7, `TOrbShotsTests` 7, `TRamBrakeTests` +2.

2026-11-08: **3.0.115 - the flight's own track.** From the fall of the
Ram's honeycomb `flight.ogg` plays in place of `boss3.ogg` started again:
from its beginning, fading in over 1.5 s under the blast, looping. Named
in the level: the `ram` action's `"flightFile"` (`TRamOrders.FlightTrack`;
the fight's `"file"` when absent); screen 13 names `flight.ogg`. A death
goes back to point A with the boss track, as before. `credits.ogg`, the
end titles' "Legendary", is in `bin/music/` and in the docs, played by
nothing yet. Tests: `TRamLevelTests` +1.

2026-11-07: **3.0.114 - the wheels bounce, the eclipse's charge held.**
A shed wheel no longer rolls at once: it strikes the road, keeps 0.6 of
its speed up and bounces lower and lower till a bounce has under 1 a tick
in it, then rolls (`Game.Wheel`: `Struck`, `Contact`, `Drop`). Every strike
sparks off the road in the scrape's look and shakes a little, the harder
the more; it is heard (`wheelland.wav`) from a strike of 2 a tick - the
front wheel's hop, the rear one's first three. The rear wheel is no
longer spat out on the road: the rise starts with it in its well, and at
a lift of 48 the rear jet throws it down out of it (`SpitLift`,
`TTakeoff.Spat`); it strikes at about 5.5 and bounces to about 40, 16
and 7. In the eclipse the light on the body is held at its top from the
end of the orbs' drawing in through the burst's 16 ticks of inhale to
the strike (`TShroudLook.Hold`, `ChargeLook` with the inhale); the ice
form's rite is as it was. Tests: `TLooseWheelTests` reworked (13),
`TTakeoffTests` the rear jet's test reworked, `TRamBrakeTests` +2,
`THeroShroudTests` +2.

2026-11-07: **3.0.113 - the Ram's engine bays and nozzles (stage 18c-3).**
At the takeoff the arches no longer stay empty: the engine bays come out
of their depth (growing out of the dark over 14 ticks), then the petal
nozzles slide down out of the bays' rings (8 ticks), then the front jet
catches and the takeoff of 18c-1 goes on - 22 ticks later than before;
the rear bay and nozzle come out behind the rear wheel, which the rear
jet still spits out (`Game.Takeoff`, stage `tkOpening`, `BayAt`,
`NozzleAt`). On the road a nozzle slides out no deeper than the road and
comes out the rest of the way as the hull lifts. The nozzles turn with
the hull's lean and are lit from below while their fire burns
(`TRamPainter.DrawEngines`; `TSpriteRenderer.DrawHanging` draws the part
of a picture slid out of a slot; `THull` draws the chassis and the wheels
apart). New sprites `engineBay`, `engineNozzle`, `engineNozzleLit` in
`tek-machine.mset`, made by `tools/machine/extend_machine.py` out of the
generated `machine-bay.png` and `machine-nozzle.png`: the bay cut by a
mask read off the hull's own arches, one for both, darkened from half
its light at the top to three quarters at the bottom; the nozzle not
darkened. The fire is new: no smoke, a flame texture drawn twice along
the hull's down out of the nozzle - an orange sheath 30 by 8, a
white-blue core 12 by 3.2, flickering - ending high over the road; only
a warm pool of light reaches the road under each jet. A shed wheel's
well is hollow to bullets and touch till its bay comes out
(`TRamArt.Wells`, `TRam.WellOpen`). Tests: `TTakeoffTests` +2 and
reworked for the opening, `TRamBrakeTests` +1.

На 2026-11-07: **3.0.112 - Таран висит и качается (этап 18c-2).**
Успокоившись после взлёта, корпус покачивается: вверх-вниз на 3 ед. за
80 тиков и креном 1.2 градуса за 110 тиков, амплитуда нарастает за 33
тика, чтобы не было рывка (`Game.Takeoff`, стадия `tkHanging`). Висит над
героем с запаздыванием: пружина к середине героя (в пределах экрана) и
вязкость, ускорение не больше 0.06 за тик, скорость не больше 1.6 (герой
бегает 2), с 200 ед. подходит примерно за 200 тиков без перелёта;
кренится в сторону движения, 2.5 градуса на единицу скорости. Таран
двигает `FX` на `Pace` (`TRam.TickTakeoff`). Дым из выхлопных труб гаснет
с началом взлёта. Люк над пустой шахтой мачты: после взрыва третьей
головы, когда мачта опустилась, за 20 тиков задвигается от дальнего края
(`ShutterAt`, `DrawShutter` с горизонтальным срезом), дым из шахты
прекращается; в точке A (после бункера) люк уже закрыт. Спрайт
`wellShutter` - сгенерированный объёмный люк сверху-спереди с толстой
кромкой (`machine-hatch.png` в исходниках, белый фон вычищается),
лицевая сторона сплющена в эллипс устья новым
`tools/machine/extend_machine.py` (дописывает спрайты в готовый
`tek-machine.mset` без исходников сборки). Точка B переехала в 17a: в
зависании убить героя пока нечем, а точка B должна давать орбомет.
Тесты: `TTakeoffTests` переделаны под зависание и +3, `TRamBrakeTests`
+1, `TRamBunkerTests` +2.

На 2026-11-07: **3.0.111 - взлёт Тарана (этап 18c-1).** Переднее колесо
укатилось за правый край (сцена слышит `WheelGone`, стадии `tsGone` ->
`tsTakenOff`), пауза 20 тиков (`TakeoffAfterTicks`, сигнал `TakeOff`) - и
Таран взлетает (`TRam.TakeOff`, только без переднего колеса, один раз за
бой). Движение - новый модуль `Game.Takeoff` (`TTakeoff`, у Тарана -
`Flight`): из пустой передней арки бьёт струя, нос за 24 тика поднимается
на 10 градусов вокруг точки касания заднего колеса; через 33 тика бьёт
задняя струя и выплёвывает заднее колесо (`SpitWheel`, `RearWheel`,
подскок `WheelSpitKick` 4 - примерно на 56 ед., дальше катится к герою,
как первое: второй прыжок). Корпус за 75 тиков поднимается на 184 ед.
(`HangLift`: низ корпуса около 150, чуть выше вершины лунного прыжка),
шарнир за 20 тиков переезжает с колеса в середину корпуса, а пружина с
затуханием выравнивает наклон: перелёт за горизонт примерно на 3 градуса,
обратно, успокоение примерно через 100 тиков после плевка (`Steady`,
`tkHanging`). Положение корпуса - новый `TRamPose` (`PoseAt`, `Posed`,
`PoseSpot` вместо `LeanSpot`): прямой корпус на дороге, поворот вокруг
касания заднего колеса, сдвиг. С ним ходят глаз, фонари, выхлоп, дым арок
и пустой мачты, искры носа, слои корпуса; касание (`Overlaps`,
`SpanAcross` через `UprightBox`) и рикошет (`StrikeHull`) тоже считаются
по позе - висящий корпус ранит и отбивает пули наверху, не на дороге.
Огонь кодом: `TSmoke` с огненным видом вниз из каждой арки, свечение и
белое ядро у устья, пыль с дороги, пока струя до неё достаёт. Звуки
`tools/sounds/jet.py`: `jetfire.wav` на каждое зажигание (с тряской 0.35)
и петля `jethover.wav` вместо грохота мотора с момента плевка. Герой
только смотрит и прыгает через второе колесо. Тесты: `Tests.Game.Takeoff`
(новый, 9), `TRamBrakeTests` +6, `Tests.Game.Throw` +2,
`Tests.Game.Wheel` +1.

На 2026-11-07: **3.0.110 - рикошет от голого корпуса и колеса (к этапу
18b).** Пока соты держат, пулю берут они (`TRam.Block`), как раньше. Соты
сошли (`State <> sdUp`) - пуля отскакивает от самого корпуса, как от брони
танка: искры веером по отражению, иногда трассер-рикошет со своим звуком,
иначе пинг брони (`FImpacts.Land`, `SoundArmorHit`). Попадание ищется по
маске тела (`TShieldMask`) вдоль отрезка тика шагом 0.5: отрезок
поворачивается в систему прямого корпуса вокруг точки касания заднего
колеса, первая твёрдая клетка возвращается к ребру, через которое пуля
вошла (`TraceEntry`, как у коробки брони), точка и нормаль поворачиваются
обратно с наклоном (`TRam.StrikeHull`). Отвалившееся колесо - пересечение
отрезка с окружностью, нормаль от центра (`TLooseWheel.Strike`,
`TRam.StrikeWheel`). Частые попадания - `Rapid` по `HullStruckWithin`
(8 тиков), без лишних вспышек. Урона нет ни корпусу, ни колесу. Тесты:
`Tests.Game.Wheel` +3, `TRamBrakeTests` +4. Заодно: у `Tests.Game.Wheel`
не было регистрации фикстуры - его 8 тестов из 3.0.109 не запускались.

На 2026-11-06: **3.0.109 - колесо арены 3 (этап 18b).** Соты погасли до
последней ячейки (`sdDown`, сцена слышит `HoneycombDown` с залпа), пауза
16 тиков (`WheelAfterTicks`, стадии `tsBare` -> `tsLoose`, сигнал
`Shed`) - и у Тарана отваливается переднее колесо, носовое, к герою
(`TRam.ShedWheel`, только оглушённым, один раз за бой). `crash.wav`,
новый `scrape.wav`, тряска 0.5. Корпус клюёт носом: поворот всех слоёв
вокруг точки касания заднего колеса (`LeanPivot`), 3 градуса за 6 тиков с
ускорением (`LeanDegrees`, `LeanTicks`). Плуг носа и так стоит на дороге,
поэтому его острие уходит под линию дороги примерно на 7 ед. - "зарылся".
Из острия плуга (`NosePoint`) 30 тиков летят искры вперёд-вверх, гаснут
(`TRamPainter.TickScrape`, свой `TSparkField`, отскок от дороги).
Наклон - в `THullStand` (`Lean`, `Pivot`, `Shed` - снятые оси;
`Turned`, `TurnedCenter`): колодец, шасси, колесо, корпус, его глаз,
глаз Тарана, фонари, точки дыма арок и выхлопа поворачиваются как одно.
Мачта в покое не рисуется, пока корпус наклонён: её режут горизонтальные
клипы, а она всё равно спрятана. Колесо - новый юнит `Game.Wheel`
(`TLooseWheel`, его держит Таран, рисует `THull.DrawWheel`): своего
размера 41 (решено: настоящий, а не под лунный прыжок), подскок 2.5 вверх
под лунным притяжением (около 22 ед.), приземление - `wheelland.wav`
(сигнал `WheelLands`), катится вправо 3 ед./тик, вращаясь по пути, и
исчезает за правым краем. С отрывом колеса герой отпущен
(`THero.Release`, падает на дорогу с 8 ед.), управление его, затмение
больше не щадит (`TEclipseScene.StopSparing`). Колесо ранит и отбрасывает,
как касание корпуса, от своей середины, у правой стены - вверх
(`ResolveWheelContact`); касание корпуса снова ранит (решено: бой
продолжается с колеса - `Contact` молчит, пока стоит, только до колеса).
Звуки - `tools/sounds/scrape.py`. Побочное: на ударе лунного взрыва
крупно "Форма Луны" / "Moon Form" и строкой "MOON FORM: прыжок +25%"
(`moonForm`, `moonFormPerk`), как у льда. Дальше сцена стоит до взлёта
(18c). Тесты: `Tests.Game.Wheel` (новый, 8), `TRamBrakeTests` +6,
`Tests.Game.Throw` +3, `Tests.Game.Eclipse` +1, `Tests.Monsters.Hull` +2.

На 2026-11-06: **3.0.108 - бросок хеншина арены 3, залп (этап 18a-2).**
Раскрутились пады - правая кнопка (та, что на глифе) бросает их; пока
герой держим, клик идёт в сцену, а не в бонус (`TThrowScene.Press`).
Нажатие слышно только после раскрутки; без него пады уходят сами через
3 с после подсказки (`ThrowAfterTicks` 99). С залпом тишина: сердце
останавливается (`Beats` - до залпа), гул `spinhold.wav` обрывается,
подсказка гаснет. Каждый пад срывается со своей задержкой 0-6 тиков
(`LetGoDelay`, золотое сечение: первый сразу, соседи не вместе) и летит
как обломок 10c-3, но прицельно (`TPadWrecks.Hurl`): пинок 2, тяга 0.45
к середине корпуса против сопротивления и лунного притяжения, старт с
изгибом вбок-вверх на 15-40 градусов, у каждого свой, изгиб гаснет
(0.92 за тик) - ни двух одинаковых путей, ни одной прямой; картинка
крутится дальше, как крутилась в руках; сопла горят снова (огонь,
искры, свечение, молнии), огонь теперь от картинки (`PictureAt`), а не
от середины балки. Орбы едут на паду и сгорают во взрыве
(`TOrbGrip.Burn`). Попадание - вход в соты по отрезку тика, как пуля
(`TRam.Block`): взрыв машины, `platform.wav`, тряска 0.4, кусок сот
откалывается и разлетается осколками ячеек (`TTekShield.Shatter`,
`TRam.ShatterShield`). Последнее - взрыв босса, `bottle.wav` +
`platform.wav` + `sweeperblast.wav`, тряска 1.0, и соты осыпаются
(`TTekShield.Crumble`, `sdCrumbling`): остаток мигает и гаснет ячейка за
ячейкой от отколотых мест наружу, 3 ед. за тик; с ним заново, с начала
и с наплывом 1.5 с, стартует трек босса - временно, под этот момент
задуман свой трек (`CrumbleHoneycomb`). Промахнувшийся пад
засчитывается без взрыва; без падов соты осыпаются сразу на залпе. Дальше
сцена стоит до колеса (18b). Тесты: `Tests.Game.Throw` +6,
`TPadHurledTests` 6 в `Tests.Game.Wrecks`, `Tests.Orbs.Grip` +1,
`Tests.Game.Shield` (новый, 6).

На 2026-11-06: **3.0.107 - бросок хеншина арены 3, первая половина (этап
18a-1).** Сразу после удара 16e Таран, оглушённый, отъезжает влево,
оставив за кормой клетку дороги (`RamPlaceLeft` 32; `TRam.Withdraw`:
рокот, медленно-быстро-медленно, 2 ед./тик, шипение тормоза). Через
секунду (`CatchAfterTicks` 33) управление отнимается, и орбы относят
героя из кадра - к правому краю, на 8 ед. над дорогой (`Game.Hoist`
переписан: прямая с изгибом вверх, 3 ед./тик). Там из точек его тела по
одному за тик вылетают чёрные орбы (`Orbs.Grip`), летят к падам -
ближайший первым - и облепляют балку пада по верхнему и нижнему краю (3
или 6 на сторону), держатся на ней и вращаются с ней; размер 0.55 от
орба обряда. Пад облеплен - засыпает, на его месте держимый обломок
(`TPadWrecks.Hold`): без сопел, огня и свечения, крутится вокруг
середины балки (`PadBeamDepth` 6.3, `PivotDrop`, `PictureAt`), а не
центра спрайта, и медленно, 4 с, плывёт к своему месту на широкой дуге
вокруг Тарана (`PlanArc`: от 105 до 10 градусов, верх дуги в 36 ед. под
верхним краем экрана, радиус 252, места поровну по всей дуге при любом
числе падов - запас на разгон залпа; места по повороту вокруг Тарана -
`ArcOrder`). Все пады взяты - раскрутка 4 с до 24 град./тик, у каждого
своя доля 0.8-1.2, каждый пятый в другую сторону, на ударе сердца
быстрее на 0.3. Сердце заново с поимки, 70 -> 150 по раскрутке
(`SpinTempo`); гул - подъём `spinrise.wav` (4 с) и петля `spinhold.wav`
до броска (`tools/sounds/spin.py`); фонари и глаз Тарана мигают вместе в
тревоге по доле раскрутки, раз в 20 тиков в начале и раз в 6 в конце
(`TRam.LightsAlarm`); соты не мигают - Таран не боится. Раскрутилось -
над головой глиф мыши бонуса (вынесен в `DrawMouseGlyph`), вдвое
крупнее, пульсирует с сердцем; нажатие пока ничего не делает (18a-2).
Меньше 4 падов на экране - недостающие зовутся из пула погони и влетают
из-за ближнего края (`PlaceCalledPads`); больше 7 - берутся 7 ближайших
к герою. Часы сцены - `Game.Throw` (`TThrowScene`, `TThrowPainter`),
гаснут с `ClearEclipse`. Первая сборка (нити орбов от героя к падам,
подъём на клетку на месте, вращение вокруг центра спрайта) после прогона
переделана в той же версии; после второго прогона Таран отъезжает
дальше, дуга шире и выше. Тесты: `Tests.Game.Throw` (новый, 10 + 8 + 5),
`Tests.Orbs.Grip` (новый, 10 + 2), `Tests.Game.Hoist` переписан (6),
`TPadHeldTests` 7 в `Tests.Game.Wrecks`, `Tests.Game.Heartbeat` +4,
`TRamBrakeTests` +5.

На 2026-11-06: **3.0.106 - взрыв хеншина арены 3 (этап 16e).** Взрыв
остаётся одним на все формы: форма даёт цвета (`TBurstLook`), силу задаёт
вызывающий (`TBurstPower` в `TOrbBurst.Start`). `SuitBurst` - числа арен
1-2 один в один; `EclipseBurst` - 36 лучей через 10 градусов, 26 ед. за
тик, хвост 340, луч уходит целиком с экрана из любой точки (980 =
диагональ 640 + хвост), кольцо 420 за 16 тиков, вдох 16 тиков без вуали
и фигуры, белая вспышка 0.95 держится 2 тика и гаснет за 3. Лунный облик
получил белое ядро у головы луча (`Heart`, `HeartLevel` 0.9) и белую
вспышку: белое ядро, чёрный хвост, светлый ореол. Порядок: орбы ушли в
тело - последний, самый сильный удар сердца (`THeartbeat.StrikeLast`,
пульс x1.6, звук дважды) - полсекунды тишины, монитор на нуле - удар.
Лунная форма и +3 надеваются в момент удара, как ледяной костюм; тряска
1.0, `bottle.wav` дважды. Темнота срывается за один кадр
(`TEclipseScene.Strike`), луч и рябь гаснут, датчик гаснет навсегда
(`Fade` = 1 после удара), трек на паузе до взлёта, сердце отпускает
монитор. Лучи затмения никого не ранят и не закручиваются вихрем
уровня. Таран (`TRam.Stun`, `htStunned`): отлетает от героя на 16 ед.
за 6 тиков с замедлением, от середины - кормой; у левого края корма
уходит за край. Лампы гаснут, глаз мигает вразнобой (`FlickerEye`), дым
из колёсных арок (`ArchSmokePoints`); стоит проходимым, не тормозит
снова. Герой внутри проходимого корпуса в момент удара остаётся там -
из корпуса его выведет подъём броска (18a). Тесты: `Tests.Orbs.Burst`
+4 (стенд на `SuitBurst`), `Tests.Game.Heartbeat` +5,
`Tests.Game.Eclipse` +6, `TRamBrakeTests` +8, `Tests.Game.HeroOrbs` +4.

На 2026-11-06: **3.0.105 - верх голов Тарана честный.** Решено
2026-11-06: пули пролетали сквозь видимый верх первой и третьей головы.
Охотник: кроме глаза (круг 5 у линзы) жизнь снимает верх головы от
контура арта до линии линзы - пуля сверху или сбоку; снизу, сквозь
голову, верх встречается изнутри и пуля летит дальше. Бункер: верх -
купол по контуру арта до ряда сот (`OpenTop`) и крышка в любом её
положении - закрыта, открыта, на ходу (`InLid` откручивает её поворот и
сдвиг, как рисует `DrawLid`); раньше верх был линией у ряда сот шириной
люка, и пули проходили сквозь плечи купола и закрытую крышку. После
прогона бункер стал слишком лёгким: крутизна 30 градусов вместо 15
(`HatchFallLeast`), положе - вспышка сот; соты не тронуты. Контуры сняты с арта
`tek-machine.mset` (`HunterTop`, `DomeTop`, `LidTop`, `LidBottom`),
`HatchHalfWidth` убран. `StrikeEye` -> `StrikeHunter`,
`BulletStruckRamEye` -> `BulletStruckRamHunter`; общий `TopShare` шагает
по отрезку в кадре головы (`ToHead` теперь любой головы). Тесты:
`TestOnlyTheEyeTakesAHit` -> `TestTheEyeAndTheTopTakeAHit`, в
`TRamBunkerTests` +2 (закрытая крышка, плечи по обе стороны люка);
`TestARowOffTheTopReachesFromLower` -> `TestOnlyASteepBulletTakesALife`
(16 градусов - соты, 32 - жизнь), выстрелы с пада - 35, 45 и 60
градусов вместо 25, 40 и 60.

На 2026-11-06: **3.0.104 - герой свободен в обряде.** Решено
2026-11-06: паралич от тормоза до колеса слишком долгий. Герой бегает,
прыгает и стреляет через обряд, луч и взрыв, ничто его не ранит; кольца,
луч и рябь и так рисовались вокруг него каждый тик. Поимка и подъём
(`Game.Hoist`, `THero.Hold`) переезжают в бросок (18a), до него их никто
не вызывает. Стоящий Таран проходим насквозь - стена потребовала бы
запрыгивать на корпус и бегать по крыше, такой механики в игре нет.
Бонус в сцене закрыт: ледяная аура или дождь посреди лунного обряда.
`Game.Eclipse`: нет `Holds` и `Hoisted`; `CatchAt` -> `CallAt`, сигналы
`Called` (мир встал, обряд вызван) и `FirstSeat` (первый орб сел, трек
гаснет); `CatchHero` и `FHoist` убраны. Два бага `TMoonRite`, пойманные
тестами 3.0.103: места шли шагом 23 по номеру, а кольца крутятся
навстречу - соседние вызовы сходились в один угол; теперь каждый вызов
целит на золотой угол дальше и берёт ближайшее по углу свободное место
(`NearestFreeSeat`). Остаток тика переносился через вызов и после удара
давал вызов раньше последнего зазора; теперь ожидание считается заново
от каждого вызова. Тесты: `Tests.Game.Eclipse` 18.

На 2026-11-05: **3.0.103 - обряд затмения (этап 16d).** Между поимкой
и лучом теперь обряд: новый `Orbs.Moonrite` (`TMoonRite`) - свой
хореограф рядом с волнами `TOrbRite`. Чёрные орбы по одному, 60 штук, никого не
ранят: каждый третий рождается крошкой в глубине дальнего города
(`TFarPlaneDef.CityPoints`) и растёт на лету из-за спины героя,
остальные проступают на гранях материи - дорога, пады, корпус Тарана,
кончики фангов - со всех сторон и со всего экрана, не ближе 112 к
герою (новый `HarvestAfar`: секторы по очереди, в секторе грань
наугад); места идут шагом 23 из 60, орб берёт ближайшую по углу
свободную грань. Зазор между вызовами сокращается только на ударе
сердца (x0.8, от 6 тиков до 1). Кольца - третий паттерн `eclipse` рядом
со снежинкой и вихрем: два кольца по 30 мест вокруг груди, радиусы 30
и 42, внешнее крутится против внутреннего; бьются с сердцем (сжимаются
на 0.12 пульса). Сцена
`Game.Eclipse` больше не таймер, а дирижёр: игра каждый тик отдаёт ей
`TRingProgress`; первый севший орб поднимает героя (часы `Game.Hoist`
от `Lifted`) и гасит трек, тьма идёт за долей кольца (не быстрее темпа
16c-2, никогда не светлеет), луч падает на полном кольце, через 50 тиков
в луче сцена велит орбам войти в тело. На каждом ударе от героя бежит
бледная рябь света по тёмному миру. Сердце в сцене - `RiteTempo`: 90 на
пустом кольце, 140 на полном. На поимке - выкрик **EVOLUTION** и
`evolution.wav` дважды, как в аренах 1-2 (`THenshin.Shout`,
`StartEclipse`). Коллапс в тело - тело наливается светом (`ChargeLook`
переехал в `Game.Shroud`); в конце обряда +3 здоровья и форма `hfMoon`
(в 3.0 выглядит как ледяная, прыжок +25%: `SuitForms`). Взрыв - 16e.
Общие ходы орба вынесены из `Orbs.Rite`: `SpiralTo`, `DrawnInto`,
`BodyEntry`, `EasedInOut`. Тесты: `Tests.Orbs.Moonrite` (19, новый),
`Tests.Game.Eclipse` переписан (20), `Tests.Orbs.Patterns` +4,
`Tests.Orbs.Harvest` +6, `Tests.Game.Heartbeat` +6,
`Tests.Game.FarPlane` +1.

На 2026-11-05: **3.0.102 - порядок сцены переделан, подъём и луч
(этап 16c-2).** Решено 2026-11-05: луч из бриллианта на диске читался
лазером, а не светом сверху - корона, бриллиант и затмение диска
(`TGaugeEclipse`) из 3.0.101 убраны. Новый порядок от тормоза: мир
встал (66 тиков) - управление отнято, герой пойман где есть и поднят на
клетку (здесь в 16d придут орбы); через 30 тиков гаснет свет - тьма за
40 тиков, диск заряда гаснет вместе с ней (`Fade`), трек босса уходит
на паузу; когда тьма легла - сверху падает луч, как на постере Tron
Legacy: вертикальная колонна от верхнего края экрана до героя, белое
ядро шириной с него в широком лунном ореоле, мягкие края и хвост ниже
ног, вспышка при касании, ореол вокруг тела, пульс на каждом ударе
сердца (`TEclipsePainter.DrawBeam`). Подвес героя - `THero.Hold`/
`HoldAt`/`Release`: `Tick` крутит только руку и остывание оружия, без
падов, падения и ходьбы, `DeckUnderFeet` = nil; клавиши не опрашиваются,
огонь и бонус заперты. Подъём - новый `Game.Hoist`, чистая геометрия:
от краёв экрана не ближе 48, от рамки корпуса не ближе 16, сначала вбок,
потом на клетку вверх за 30 тиков; висит до колеса (18b).
`ClearEclipse` снимает подвес. Тесты: `Tests.Game.Eclipse` переписан
(13), `Tests.Game.Hoist` (11).

На 2026-11-04: **3.0.101 - тормоз и тьма (этап 16c-1).** Этап 16c
разрезан надвое: 16c-1 - тормоз и тьма, 16c-2 - луч и подъём. На 100%
после бункера (Таран целиком на экране, в охоте) мир встаёт: новый
`Game.Eclipse` (`TEclipseScene`) - часы сцены от тормоза, без знания о
Таране и диске. Таран тормозит (`BrakeToAStand`, `htBraking` ->
`htHalted`: лампы, шипение и толчок 0.3 на остановке), стоит с горящим
глазом, не касается и не швыряет; лента выбегает как в 11a. Герой в
корпусе выставлен из него броском без раны (`InTheHull`); `HurtHero`
молчит, пока сцена его щадит. Через 66 тиков (мир стоит) диск наверху
- затмённое солнце: корона вспыхивает по ободу и оседает, свой свет
диска гаснет (`TGaugeEclipse`); мир темнеет одним оверлеем после
`dlFront` (0.85 за 40 тиков), глаз Тарана дорисован поверх
(`DrawEyeOverDark`). Ещё через 30 тиков - бриллиант: точка на ободе со
стороны героя, три мигания и горит. Трек босса на короне затухает и
встаёт на паузу (`TSoundBank.PauseMusic`/`ResumeMusic`, своя доля
громкости `FHush`); рестарт снимает паузу до проверки `Plays`. Тесты:
`Tests.Game.Eclipse` (12), `TRamBrakeTests` (6).

На 2026-11-04: **3.0.100 - последние 3% и сердцебиение (этап 16b).**
После смерти бункера диск заряда выезжает из слота на панели монитора
сердца к середине строки названия уровня (`TGaugeRide`: 66 тиков,
smoothstep, рост втрое) и остаётся там; слот открыт и пуст, число
считает дальше. Сердцебиение - новый `Game.Heartbeat` (`THeartbeat`):
темп ему даёт игра каждый тик, удар в первый тик после остановки,
дальше по накопленной фазе; `ChargeTempo` - 60 ударов в минуту на 97,
90 на 100. Бьётся после бункера с зарядом от 97 (`TickHeartbeat`);
каждый удар - `heartbeat.wav` (двойной низкий "тук-тук",
`tools/sounds/heartbeat.py`, второй удар через 0.24 с - `DubTicks` 8 в
коде), диск набухает на 8% и вспыхивает гало, монитор (`Paced`, `Beat`)
рисует один комплекс на двойной удар. Точка A выезжает из слота заново.
`BigMessageY` вынесен в интерфейс `Hud.Messages`. Тесты:
`Tests.Game.Heartbeat` (13), `TGaugeRideTests` (7).

На 2026-11-04: **3.0.99 - точка перезапуска перед хеншином и End в три
шага (этап 16a).** Взрыв бункера ставит точку A (`FPastBunker`): смерть
после него возвращает героя прямо перед хеншином с 5 здоровья
(`PastBunkerHealth`), на дорогу правее середины (`PastBunkerHeroX` 352).
Событие экрана 13 зовёт `StartRam`, и мимо бункера он ведёт в
`ResumePastBunker`: `TRam.StartPastBunker` - мачта пуста, разворот за
левым краем (`htTurning`, красный глаз у края) и охота передом; пады
экрана гаснут (`Doze`), как от волны подметальщика; дальний план
прокручен с начала на крейсерской скорости дороги, пока шпиль с неоновым
TEK не встанет над серединой (`TFarPlane.RideToEmblem`, часы города
тоже); группы падов сразу густые (`TPadDrift.BeginAfterWave`); лента
разгоняется; бак - все головы сняты (`TStoneTank.BeginPastTheHeads`),
заряд 97, последние 3% по своим часам; гул и трек босса. End шагает:
конец арены 2, вход на экран 13 с Дуплетом и 10 здоровья (`DebugJumpToRam`), точка A - Дуплет и 5
(`DebugJumpPastBunker` - тот же `RestartLevel`, что и смерть); четвёртое
нажатие ничего не делает. Тесты: `TestPastTheHeadsItFillsFromTheBunkersCeiling`,
`TestRidesToTheEmblemOverTheMiddle`,
`TestPastTheBunkerItTurnsOffTheLeftEdgeAndHunts`.

На 2026-11-04: **3.0.98 - третья фаза бункера (14c) переделана: волна на
проход, охота передом.** 3.0.97 строилась по неверно понятому договору.
Теперь толпа падов (волна) - только на перестройку машины от правой
стены к левой, чтобы герой её перепрыгнул: `BeginRows` кладёт три ряда
на палубах подъёма - подножие 272, шаг 192, верх 144
(`ClimbFootHighest`, `WayUpDeck`), зазоры 4-12, - и держит их пады
(`FWave`); каждый ряд влетает со своей стороны (`RowsComeFrom`): нижний
из-за правого края, средний из-за левого, верхний сверху
(`TPad.SetAdriftComing` берёт смещение точкой, `LetGoPastLeft` не
отпускает ещё летящий пад); `SendRow` больше нет. Пока волна летит,
ничего не подаётся; потом снова группы, первая - сразу за концом волны
на дороге, страховка считается от него. Волна не в счёте `AdriftOn` -
группы не ждут, пока она уедет. После волны группы гуще: страховка 4 с
вместо 6 (`HuntGuardUnits` 132), подъёмов 70% вместо 60%
(`HuntClimbShare`). Проход идёт за левый край (до `-RamWidth -
PassBeyond`, тормозит невидимо), без шипения и толчка, гул не гаснет.
Герой на дороге в проходе - бросок через корпус вправо с раной
(`ThrowsOverTheHull`; толчок носом, прижим у края, `Shoves`,
`THero.Shove`, `ResolveRamShove` - выкинуты). За кадром разворот 50
тиков (`htTurning`): корпус с первого тика смотрит вправо
(`FHullFacing`, `HullMirrored`), глаз мигает, последние 16 тиков красный
отсвет глаза на левой кромке (`PeekLevel`, `DrawPeek`). Въезд
(`htEntering`) - только вперёд, до 3 за тик, пока весь не на экране.
Охота передом (`TickHuntDrive`, `HuntMark`): нос на 24 позади середины
героя, до 1.5 за тик, но в левой половине - дальше середины экрана не
идёт (`HuntLine`). Раз в 6-9 с, после мигания глаза, рывок почти к
правому краю (`THuntSurge`: 75 тиков на 3 за тик, нос до 472) и так же
быстро назад - прижать ненадолго, не ловушка. Право - территория героя,
лево - машины: назад только к герою за кормой не на паде - врезается и
бросает вправо; героя на паде за ней дорога сама везёт над люком.
Касание на дороге - таран вправо; броска назад у правой стены нет - нос
до стены не доходит. Зеркало без нового арта: `HullSpot` и `WellAt`,
`MastPivot`/`HeadPoint` берут X колодца, маска касания читается
зеркально (`SolidAt`), соты корпуса тоже (`TTekShield.Mirrored`);
художник рисует колодец, шасси, корпус и мачту зеркально, глаз и
стоп-сигналы на зеркальных местах, у выхлопов вторая пара дымов в другую
сторону. `Place` возвращает корпус лицом влево. Числа - первые прикидки.
Тесты: `TRamBunkerTests` +6 (16 вместо 10 на охоту и после бункера; два
теста смерти бункера переписаны), в `TPadDriftTests` два заменены,
`TStoneTankTests` +1, `TBunkerShellTests` +3, тест пар в охоте заменён
одиночным и ещё +2 в `TRamBunkerTests`, DUnitX находит 1066. После
прогона: взрыв снаряда вдвое уже (`ShellBlast` 40 вместо 80) - было
слишком сложно. Машина переживает бункер: голова взорвана, мачта уходит
в колодец там, где машина стоит, и охота идёт дальше без головы -
снарядов нет, бить нечего, таран на дороге остаётся - до хеншина героя
(этап 16); убитый раньше последней трети (клавиша O) начинает охоту там
же. Заряд: потолок бункера 97 (`Ceilings` 30, 55, 97, 97, `HeadShares`
бункера 38), его смерть доливает до 97, последние 3% - по проценту раз в
4 с (`TickFinal`), полный примерно через 12 с после взрыва. Погоня
облегчена: в охоте бункер стреляет по одному снаряду, чуть чаще (прицел
35 тиков вместо 50); пады сбиваются, но реже - стоит на паде, снаряд в
этот пад, иначе в дорогу рядом, где на пути дуги нет пада
(`TBunkerShells.RoadMark`, `TRamCue.LobForRoad`); `AheadShellMark` пока
не используется. С купола снят ряд сот: открытый верх на ряд (5.1) ниже
(`OpenTop`), попасть можно с чуть более низкого или дальнего пада.
Граната катится туда, куда летела (`TShell.RollWay`): выстрел вправо
развёрнутой машиной - катится вправо. Подробности - в
`docs/mechanics/arena-3/chase.md`, "Decided 2026-11-04, phase 3 reworked" и
"Stage 14c reworked (3.0.98)".

До этого, на 2026-11-03: **3.0.97 - третья фаза бункера (14c), охота кормой вперёд.**
Последняя треть жизней бункера - охота. Смена там, где машина стоит (у
стены или на середине отката - откат бросается): тревога (гул
перестройки), глаз мигает, бункер молчит, игра зовёт три ряда падов
(`BeginHunt`, cue `Rows`). Ряды влетают (решено 2026-11-03: на ленте они
закрывали бы экран 15 с, а проход должен их ждать; объяснить нельзя, но
зрелищно): первый отрезок трёх рядов, от левого края до 128 за правым,
подаётся разом и летит из-за правого края за 3.6 с на реактивах, гаснет
квадратом и приходит к скорости ленты (`TPad.SetAdriftComing`, место
пада всё это время едет с лентой); дальше ряды подаются у правого края по
ходу дороги, подъёмов больше нет (`TPadDrift.BeginRows`, `SendRow`).
Палубы 272, 192, 120 - нижний ряд на прыжок с дороги, средний над верхом
бункера, верхний - высота стрельбы; зазоры 4-12 уже тела героя (16) -
падает только в дыру от снаряда; слот, где уже едет пад, остаётся ему.
Пул экрана 13 вырос до 52 падов. Когда ряды влетели (`RowsIn` ->
`RowsArrived`), ещё полсекунды мигания - и проход к левому краю сквозь
героя рывком 3 за тик, молча. На паде - пропускает под собой (`Contact` в
проходе и охоте выключен). На дороге - нос толкает его к левому краю
(`Shoves`, `ResolveRamShove`, `THero.Shove`), прижатого там бросает через
корпус вправо с раной (решено: как в плане - пока везёт, прыжок на нижний
ряд спасает жизнь); упавшего внутрь корпуса - сразу. Свой ход броска
теперь задаёт Таран (`TOverTheHull`, `THero.Fling(side, way)`): 3 за тик
против ленты в 1 - около 190 к моменту, когда он опускается ниже крыши; в
фазе 2 по-прежнему 1. Потом охота сзади (`TickHuntDrive`): машина не
мира, лента её не везёт; люк держится на 24 позади середины героя, чуть
быстрее его бега по ряду против ленты (1.5 за тик) - бегущий уходит
вперёд, вставший получает люк под себя. Просчитано (решено 2026-11-03):
с верхнего ряда пуля входит в люк с 300+ по горизонтали, со среднего - со
100, так что сверху бьётся всегда, опасность - выбитые ряды и таран;
столб остаётся - на шаг позади он мимо бегущего и стоящего, достаёт
только вернувшегося над люк. Касание на дороге - таран: бросок вперёд
вправо с раной (у правой стены, где за кормой нет места, - назад влево),
машина стоит 50 тиков, пока он летит. Снаряды снова парой: первый к
ногам, второй - `AheadShellMark` (`Game.Shells`): ближний пад впереди по
его ряду, иначе дорога впереди. `Hunts` - крючок для напалма этапа 12:
в охоте его нет. Смерть бункера заканчивает охоту, машина едет к стене,
ряды едут дальше. Числа - первые прикидки для живого прогона. Тесты -
ещё 17 (`TRamBunkerTests` 10, новый `TAheadShellMarkTests` 3,
`TPadDriftTests` 4), DUnitX находит 1054; толчок, бросок и влёт рядов -
игры и падов, проверяются глазом. Подробности - в
`docs/mechanics/arena-3/chase.md`, "Decided 2026-11-03, phase 3" и "Stage 14c
as built (3.0.97)".

До этого, на 2026-11-03: **3.0.96 - вторая фаза бункера (14b), откат.** С двух
третей жизней бункера Таран время от времени отступает: при закрытом люке
глаз мигает полсекунды, машина рывком (3 за тик) уходит к середине экрана
- таран на x 256, к левому краю никогда, - стоит секунду и медленнее (1.2)
едет назад к стене; первый откат через 2 с фазы, дальше раз в 6-8 с
(`TFallBack`, `TickFallBack`, `BunkerSecondPhase`). От предупреждения до
стоянки бункер молчит (`HoldsFire`), на обратном пути снова целится;
`FallingBack` - пауза для напалма этапа 12. Дорога за кормой на откате не
героя: опустившийся на неё правее кормы брошен назад через корпус влево с
раной (`ThrowsOverTheHull`, `ResolveRamThrowOver` до касания; рана -
общий `HurtByRam`). Бросок - настоящий прыжок, не скрипт (решено
2026-11-03): `THero.Fling` - разгон 10, около 150 вверх при корпусе 128,
управление отнято на весь взлёт, свой ход вбок 1 за тик до приземления;
`Throw` теперь идёт через общий `BeginThrow`. Снаряды во второй фазе
парой из обоих стволов: первый к ногам, второй (`SecondLob`) - в
`TRamTarget.SecondAt` из `SecondShellMark` (`Game.Shells`): стоит на паде -
по этому паду; нет - по ближнему паду на прыжок вверх, который уже
проехал середину экрана; таких нет - на дорогу на 64 впереди, его качение
вернётся к нему. Сначала второй бил по любой палубе подъёма - на первом
прогоне сбивал каждый пад на подлёте, забраться было нельзя совсем; а
одна дорога оставила бы лестницу всегда целой. Решено: пад пускают
въехать, а бьют, когда проехал середину, - лестницу ловят на правой
половине, слева не отсидеться. Два снаряда пары на одном паде за тик
сбивают его один раз (`Knocked` в `TickShells`) - один обломок, а не два
в разные стороны. Снаряды ранят (второй прогон: бункер не попадал, ранил
только катящийся снаряд; это поверх решения 2026-11-02 "падает с падом без
раны"): снаряд ловится и в полёте - рвётся на герое, рана; каждый взрыв -
на палубе и на нём - волна `TBlast` как у танка (`ShellBlast`, радиус 80,
без осколков), ранит всех рядом, и стоящего на сбитом паде тоже. Бункер,
умерший не у стены, - машина едет к ней. Фаза 1 по сложности не тронута (решено 2026-11-03:
три фазы подкручиваются вместе после 14c); до 14c обе поздние трети -
фаза 2. Числа - первые прикидки для живого прогона. Тесты - ещё 14
(`TRamBunkerTests` 9, новый `TSecondShellMarkTests` 5), DUnitX находит
1037; сам бросок - героя, вне досягаемости тестов, проверяется глазом.
Подробности - в `docs/mechanics/arena-3/chase.md`, "Decided 2026-11-03, phase 2"
и "Stage 14b as built (3.0.96)".

До этого, на 2026-11-02: **3.0.95 - прожекторы города погони.** Два тёплых луча
из главного купола блуждают по небу и что-то ищут. Луч яркий в воздухе
купола, у стекла - горячее пятно и ступенька вниз, дальше слабый хвост в
лунной пыли; на ближних рёбрах, которые он пересекает, вспыхивают блики.
Угол - прицел и две медленные волны на собственных часах лампы, которые
время от времени плавно замирают; дрожь в замирании пробовали и убрали -
на длине луча она читается как дёрганье. Сначала стенд, потом игра тик в
тик. Данные - `searchlights` в `Levels.FarPlane` (`TCitySearchlights`,
лампы `TSearchlightLamp`, паузы `TSearchlightPause`) с отказами на
кривые данные; новый юнит `Levels.Searchlights` без SDL - часы лампы
(`SearchlightClock`), угол, луч на экране и его стекло
(`SearchlightBeam`), уровень по ходу (`BeamLevel`, `TailLevel`); кости
`Levels.CityLife`. Рисует `Render.FarPlane`: луч - полоса треугольников
по свечению луча на глубине лампы среди зданий, пятно и блики - после
ближних рёбер. `GameVersion` поднят сразу до 3.0.95: на 3.0.94 строка
осталась 3.0.93. Тесты - ещё 20 (новый `Tests.Levels.Searchlights` 15 -
таблицы, снятые функциями стенда под node; `Tests.Game.FarPlane` 5),
DUnitX находит 1023. Подробности - в `docs/mechanics/chase-backdrop.md`,
"The searchlights".

До этого, на 2026-11-01: **3.0.93 - поезд на монорельсе.** Один поезд
челноком по балке между двумя станциями города погони: стоянка,
разгон до круиза, ход, торможение, обратно. Нос уходит в станцию и
обрезан у рта, вагон из трёх стоит на балке всю стоянку; полоса огней
поезда режется вместе с ним. Данные - `train` в `Levels.FarPlane`
(`TCityTrain`, станции находит `CityElements`, без двух станций падает);
новый юнит `Levels.Monorail` без SDL - линия на глубине станций
(`MonorailLine`), пробег (`TrainRun`), место по часам (`TrainLeft`),
видимая доля (`TrainShown`); стоянки - кости `Levels.CityLife`. Время -
часы с дробью: `TFarPlane.ClockAt(alpha)` = тик до последнего плюс доля
кадра, как лежат смещения, так что поезд скользит с городом, а огни
остаются на целом тике. Рисует `Render.FarPlane.DrawTrain` на глубине
линии среди зданий; `DrawLight` берёт отрезок экрана (`TScreenSpan`,
`GlowWithin`). Числа - первые прикидки для живого прогона (круиз 16,
разгон 132 тика, стоянка 300-600). Тесты - ещё 24 (новый
`Tests.Levels.Monorail` 19 - таблицы, снятые функциями стенда под node;
`Tests.Game.FarPlane` 5), DUnitX находит 972. Подробности - в
`docs/mechanics/arena-3/chase.md`, "The train as built (3.0.93)", и
`docs/mechanics/chase-backdrop.md`, "The train".

До этого, на 2026-11-01: **3.0.92 - жизнь города погони.** Огни города
тик в тик со стендом: вывески дышат и спотыкаются, окна просыпаются
отрезками, красные лампы на мачтах, неоновая эмблема TEK на центральном
шпиле гаснет и зажигается заново по частям, эмблема старой краской на
двух стенах, красные маячки на верхних узлах каркасов. Данные в
`Levels.FarPlane` (`cityLights`, `emblem`, `beacons`, `beaconsAbove`
каркаса, `paint` элемента) с отказами на кривые данные; новый юнит
`Levels.CityLife` без SDL - кости стенда до бита (lowbias32, `Roll`,
`RollInt`) и уровни огней; часы - `TFarPlane.Clock`, тик стенда (его дорога
трогается на втором тике). Маячки - узлы каркаса в `TDomeFrames`, дальние до
зданий, ближние с ближними рёбрами. Рисует `Render.FarPlane`: после
каждого здания города - краска, огни (`gsPoint` над вывеской и лампой,
`gsBeam` над полосой и окном), эмблема на шпиле; картинки эмблемы
(`tek-*`) из набора - их кладёт `tools/chase/make_emblem.py`, а
`pack_set.py` их выкидывает: после перепаковки набора make_emblem
прогоняется заново. Тесты - ещё 36 (новый `Tests.Levels.CityLife` 18 -
таблицы, снятые функциями самого стенда под node; `Tests.Game.FarPlane`
14; `Tests.Render.DomeFrames` 4), DUnitX находит 948. Подробности - в
`docs/mechanics/arena-3/chase.md`, "The city's life as built (3.0.92)", и
`docs/mechanics/chase-backdrop.md`, от "The lights" до "The beacons".

До этого, на 2026-11-01: **3.0.91 - длинные тени каркасов.** Тень ребра
больше не выбрасывается целиком, когда её конец уходит за глаз: она
режется у плоскости глаза (`TDomeFrames.CutAtEye`) и стекает по полу
кратера и дальше по ближним холмам. Тень - мазок, а не полоса: солнце -
диск, поэтому за ребром тень мягчает, её полутень расходится на угол
диска, умноженный на путь света от ребра, и тонкое ребро закрывает лишь
часть диска. У ноги купола тень полная и резкая, к зрителю широкая и
бледная; вместе мазки дают вуаль с мягкими лучами света между тенями
рёбер. Мазок - 16 точек (`TShadowSample`), сетка с альфой в вершинах
через `SDL_RenderGeometry`; рисуется дважды с обрезкой
(`SDL_RenderSetClipRect`) - на полосе пола и от верха песка до низа
экрана. На стенде мазки рисует WebGL: canvas не умеет закрашивать
треугольник по углам. Испробовано и оставлено: свет теней выше диска
солнца, плотнее тень на песке, жёсткие полосы, тень только на песке
(текстурой песка - в игре не показалась). Тесты -
`Tests.Render.DomeFrames` 18 (было 15: две старых про тени заменены,
четыре новых), DUnitX находит 912. Подробности - в
`docs/mechanics/arena-3/chase.md`, "The long shadows as built (3.0.91)", и
`docs/mechanics/chase-backdrop.md`, "The shadows".

До этого, на 2026-11-01: **3.0.90 - город погони в глубину и каркасы
куполов.** Город пересобран из листов зданий (четыре генерации -
ориентиры, жильё, окраины, промзона, 42 куска; плюс лист частей
монорельса), купола и старые картинки города ушли из набора, их место
заняли каркасы кодом. Здания едут по своим ступням: чем ниже ступни, тем
ближе и быстрее (`TFarPlaneDef.ElementLeft` - `cityLeft` стенда; камера
`camera` в layout, балка монорельса - по ступням своих опор `groundY`).
Каркасы - новый юнит `Render.DomeFrames`: геодезические полуэллипсоиды
строятся один раз, через камеру города делятся на дальнюю половину (за
зданиями) и ближнюю (поверх), рёбра - ленты треугольников без текстуры
через `SDL_RenderGeometry`, тёмные с кромкой света к солнцу, цвет и
альфа в вершинах, края гаснут за один пиксель окна (`SDL_RenderGetScale`
- новая привязка); поверх диска солнца блик, солнце в тинте под
каркасом (`tintsSun` у каркасов). Без шейдеров. Стенд - эталон число в
число: геометрия сверена с ним на порте, рёбра совпали один в один.
Длинных теней к зрителю нет ни на стенде, ни в игре: тень ребра, у
которой конец уходит за глаз, отбрасывается целиком; резать её у глаза -
открытый вопрос, сначала на стенде. Тесты - ещё 28
(`Tests.Game.FarPlane` 13 и новый `Tests.Render.DomeFrames` 15), DUnitX
находит 909, все зелёные. Подробности - в `docs/mechanics/arena-3/chase.md`,
"The city's frames as built", и `docs/mechanics/chase-backdrop.md`, "The
city".

До этого, на 2026-10-31: **3.0.89 - клыки погони.** Этап 11b-2 боя на
экране 13. Отроги базальта встают из-под нижнего края и едут между
ближними холмами и дорогой, за игровым слоем, на своём движении
(`fmFangs`, 20 ед/с, на долю скорости ленты, без круиза и тормоза).
Новый юнит `Game.Fangs`: правила (`TFangRow`) и рисование
(`TFangPainter`), как у обломков и капсул. Каждое число - от костей:
какая картинка кита (четыре клыка экрана 11 из `level2-objects`),
масштаб 0.5-0.8, верх (низкие 250-310, высокие 140-200, каждый
четвёртый), зеркало, отступ тинта, дорога до следующего 60-240.
Высокий - только из видов, которым можно, и не раньше чем через экран
дороги после прошлого высокого: двух высоких на экране не бывает, город
важнее. Клык никогда не висит: не достаёт со своего верха под нижний
край - увеличен, сколько даёт масштаб, потом утоплен. Тёмные в тоннеле
(35/33/37), светлее снаружи (55/52/56). Данные - секция `fangs` в
`bin/chase-backdrop.json`; рисуются после дальнего уступа (`dlSky`) и
до шаттла (`dlAloft`). Тесты - ещё 24 (`Tests.Game.Fangs`). Подробности
- в `docs/mechanics/arena-3/`, этап 11b-2.

До этого, на 2026-10-31: **3.0.88 - дальний план погони.** Этап 11b-1 боя
на экране 13 (11b разрезан: 11b-1 - задник, 11b-2 - клыки). За дорогой
едет конец тоннеля и город в кратере, собранный из элементов набора
`chase-backdrop.mset`; числа - в `bin/chase-backdrop.json` (переехал из
`tools/chase/layout.json`: один источник для стенда и игры), уровень
называет его секцией `farPlane` (экран 13), набор - в `objectSets`. Три
новых юнита: данные (`Levels.FarPlane`), движение (`Game.FarPlane` -
правила стенда тик в тик, всё умножено на долю скорости ленты, так что
стоп ленты ставит и задник) и рисование (`Render.FarPlane` - чёрное небо,
солнце кодом, слои геометрией с альфой и цветом в вершинах). Слои от
дальнего к ближнему: хребет, город (дно кратера, купола, монорельс,
окраины), тоннель (стена экрана 13 и скала) и ближние холмы перед ним.
После первого прогона всё замедлено: стена с конвоями 6 ед/с, город 3,
хребет - доля города; холмы отделены в свой слой на 14 и стоят с первого
кадра арены, тёмные (30%) и светлеющие по мере ухода тоннеля; город
зазеркален - солнце падало на него не с той стороны. Скала рисуется
кодом поверх стены 13, а не запечена в картинку. Дальний уступ экрана 13
(губа, столбы, конвои, прожектор) едет со стеной: у `Render.Dynamics`
теперь угол и в долях единицы. Марево падов на этом экране выключено -
гнуть нечего, вернётся отдельным шагом. Смерть возвращает задник на
старт погони. Город пока картонный - свой шаг потом. Тесты - ещё 23
(`Tests.Game.FarPlane`), в наборе 951 (по числу `[Test` в коде).
Подробности - в `docs/mechanics/arena-3/`, этап 11b-1, и
`docs/mechanics/chase-backdrop.md`.

До этого, на 2026-10-31: **3.0.87 - платформы погони и их аптечки.**
Этап 13 боя на экране 13 и в той же версии этап 13b. Пока бежит дорога,
из-за правого края подаются платформы из пула экрана (новый юнит
`Pads.Drift`; в `level2.json` на экране 13 - 12 платформ с `"drift":
true`: 8 малых по 32 и 4 длинных по 64), едут влево вместе с седоками и
за левым краем отпускаются обратно в пул. Не лесенка по метроному из
плана (на прогоне - слишком много, искать нечего, город за ними закрыт), а
случайная структура: группы вдоль дороги - одинокая платформа на любой
высоте или подъём случайной формы от прыжка с дороги до высоты, откуда
выстрел достаёт до люка (настил 144 и выше), к машине или от неё;
подъёмов 0.6 групп, страховка - подъём, если 6 с дороги его не было, не
больше 10 платформ разом. Дорога тикает в голове тика, до платформ.
Герой: палуба, вытянутая стеной, отпускает и идущего, а `CarryX` не
уводит его левее 2 - иначе платформа у левого края уезжала из-под него
незамеченной и он висел в воздухе. 13b: один подъём из трёх (какой из
трёх - кости) несёт аптечку на средней по высоте платформе; диспетчер
отдаёт метку наружу (`TDriftCue`), аптечку ставит игра
(`StandMedkitOn`, через него же и аптечки капсул). Аптечка на платформе
уезжает с ней за левый край и исчезает: раньше край экрана в `CarryX`
держал её, и она падала на дорогу (`TMonster.RideBelt` отдаёт остаток
пути палубы). Тесты - ещё 23 (`Tests.Pads.Drift`: `TPadDriftTests` 21,
`TDriftLootTests` 2), в наборе 924 (по числу `[Test` в коде).
Подробности - в `docs/mechanics/arena-3/`, этапы 13 и 13b.

До этого, на 2026-10-31: **3.0.86 - лента погони.** Этап 11a боя на
экране 13 (этап 11 разрезан: 11a - лента, 11b - задник, клыки уходят в
11b). Таран после взрыва свипера стоит у правой стены; выждав столько,
сколько третья голова будет подниматься и зажигать ряд жизней, и ещё
вдох в 0.75 с, он уезжает (cue `Chase`, `Rumble`) - и не покидает
экран: под ним едет дорога (новый юнит `Game.Belt`). Дорога трогается
и останавливается за 2 с плавной ступенькой, без рывка, стоп посреди
разгона тоже плавный; круиз - 1 единица за тик, 33 в секунду, герой
бегом (2 за тик) обгоняет её со скоростью самой дороги. 16 плиток
дороги экрана 13 помечены в данных `"belt": true` и уезжают влево по
кругу ширины экрана (`BeltX` в `Render.Objects`). Герой едет с дорогой
и на полу, и в воздухе (`THero.RideBelt` через `CarryX`, в долях
единицы), стоящего на палубе везёт палуба - задел на пады этапа 13;
стоящий без дела дрейфует к левой стене. Добыча на дороге едет тоже и
исчезает за левым краем (`CarryLoot`). Колёса крутятся по дороге,
выхлоп работает как в езде, дым выхлопа и пустой мачты уносит с дорогой
(`TSmoke.Drift`). Пока бункера нет, лента бежит до смерти: остановка -
со смертью бункера, этап 14. Отладочная клавиша `I` - очко здоровья
(`CureHero`, до 10). Тесты - ещё 14 (`Tests.Game.Belt` 13,
`TestDrivesOffIntoTheChaseOnce`), в наборе 899 (по числу `[Test` в
коде). Подробности - в `docs/mechanics/arena-3/`, этап 11a.

До этого, на 2026-10-30: **3.0.85 - камень заряжается в бою.** Этап 15a
боя на экране 13: заряд формы по первым двум головам. Растёт понемногу
по ходу боя, связан с уроном, но связь не читается. Каждое попадание по
голове (глаз охотника, пачка стволов свипера; пластина не в счёт) кладёт
свою долю жизней головы в скрытый бак (новый юнит `Game.StoneTank`) -
и доходит до бака только через 50 тиков, около полутора секунд. Шкала
пьёт из бака по своим часам: раз в 8-30 тиков, каждый раз по-новому, по
проценту, иногда по два, - ровного такта после очереди нет, каждый рост
вспыхивает на шкале, как всегда. Все жизни головы дают 20%, чуть меньше
её четверти; с первой защёлки капает около 0.1% в секунду, чтобы шкала
жила и между очередями. Потолки: 30%, пока жив охотник, 55% после;
что упёрлось в потолок - проливается, а не копится. Смерть головы
доливает оставшееся до её потолка - тоже с опозданием и вместо всего,
что ещё было в пути, так что ничего не перетекает в четверть следующей
головы; шкала растёт ещё несколько секунд после взрыва. Шкала берёт
заряд напрямую, без орбов (`THeroOrbs.Charge`). Бак стартует на
защёлке первой головы, смерть его очищает вместе с Тараном, шкала
откатывается к заряду, с которым герой вошёл на экран. 95% и 100% -
этап 15b, вместе с бункером. Тесты - ещё 12 (`Tests.Game.StoneTank` 9,
`Tests.Game.HeroOrbs` 3), в наборе 883 (по числу `[Test` в коде).
Подробности - в `docs/mechanics/arena-3/`, этап 15a.

До этого, на 2026-10-30: **3.0.84 - шаттл сбрасывает аптечки.** Этап 10d
боя на экране 13. Когда жизни головы Тарана переходят в следующую
треть - те, по которым усложняется её огонь, - машина говорит об этом
(cue `Third`, `TRam.TickThirds`): по разу на треть, две на голову,
четыре на охотника и свипера; последняя жизнь - взрыв, а не треть. На
каждую треть шаттл сбрасывает капсулу (новый юнит `Game.Capsules`).
Охотникову - на середину деки того пада из названных действием `ram` в
`"medkitPads"`, что дальше от героя (на уровне 2 `s13-pad-2` и
`s13-pad-3`, высокие пады по краям, под прицелом); свиперову - на дорогу
в 16 единицах от стены, дальней от Тарана, под закрытым потолком. Капсула
нарисована кодом: корпус из двух дисков, зелёный крест, мигающий зелёный
маячок, снизу факел тормоза. Падает из-за верхнего края за секунду с
любой высоты - сначала быстро, к земле тормозит; на приземлении щелчок
пада (`padclack.wav`), скорлупа раскрывается на две половинки, и через
5 тиков на метке стоит обычная аптечка (`SpawnStanding`) - берётся как
любая. Смерть убирает капсулы, лежащие аптечки уходят вместе с полем,
трети начинаются заново. Тесты - ещё 10 (`Tests.Game.Capsules` 7,
`TestEachThirdCallsTheShuttle` у охотника и у свипера,
`TestMedkitPadsAreRead`), в наборе 870 (по числу `[Test` в коде).
Подробности - в `docs/mechanics/arena-3/`, этап 10d.

До этого, на 2026-10-30: **3.0.83 - обломки отрывает взрывом, свипер
взрывается как танк.** Доводка этапа 10c-3 после живого прогона:
обломки летели строем - один слабый старт на всех, потом разгон на тяге,
один курс, одна скорость и одно вращение. Теперь удар зависит от
расстояния до головы (7 у неё, 3.5 там, где волна гаснет; `Launch` берёт
`FRam.WaveReach`), сопротивление гасит пинок, тяга сопла 0.15 держит
остаток. У каждого обломка свой подъём (20-40 градусов), своя скорость
вращения (5-14 градусов за тик при полном ударе, вдвое меньше на краю
волны), свой разгон кручения, примерно каждый пятый крутится против
остальных; потолок 24 вместо 45 - иначе картинка пада читается
пропеллером. Разброс - устойчивый хеш от номера обломка (`WreckVariety`):
тот же взрыв даёт тот же салют, но без двух одинаковых обломков. На
дорогу по-прежнему не падает ни один, последний уходит примерно за
4.7 с. Звук: `sweeperblast.wav` почти целиком лежал ниже 100 Гц и на
обычных колонках был немым, а хлопок хантера свипер не играл. Теперь
свипер умирает звуками танка (`bottle.wav` и `platform.wav`), под ними
его гул; в `sweeperblast.py` фильтр поднят до 700 Гц ради обертонов,
добавлено тело удара в низкой середине и мягкое ограничение, треска
по-прежнему нет. Тесты - `Tests.Game.Wrecks` 7 (тест вращения заменён,
новые: ближний бьёт сильнее, пинок гаснет, нет двух одинаковых вращений),
в наборе 859 (по числу `[Test` в коде). Подробности - в
`docs/mechanics/arena-3/ram.md`, "The wrecks and the blast retuned".

До этого, на 2026-10-30: **3.0.82 - Таран отъезжает перед взрывом.** Этап
10c-4 боя на экране 13. Последняя жизнь свипера больше не перегружает
голову на месте: ствол молчит, стволы пульсируют красным, глаз часто
мигает, каждые 1.5 с звучит тревога перестройки арены 1 (`padhum.wav`,
cue `Alarm`). Машина тормозит, полсекунды стоит и задом едет к правой
стене (2.5 за тик, от дальней стены около 4.5 с); кто на пути - касание,
как всегда. Только у стены перегруз от красного до белого и взрыв - и
волна бросает героя влево, потому что справа дороги нет: погоня начнётся
с машиной справа, мост из новых падов не нужен. Пустой Таран стоит у
стены до бункера (`Spent`). Весь бой, а не только в конце: герой,
брошенный касанием или волной и приземлившийся внутри корпуса, выходит
из него без раны - 60 тиков с приземления (`FClearTicks`), дальше касание
снова касание: одна рана за одну ошибку, но корпус не укрытие. Тесты -
ещё 2 (`TRamSweeperTests`: отъезд к стене вместо стоянки в перегрузе,
новый - выход из корпуса после волны; `TRamTests`: выход из корпуса
закрывается), в наборе 856 (по числу `[Test` в коде). Подробности - в `docs/mechanics/arena-3/`, этап 10c-4.

До этого, на 2026-10-29: **3.0.81 - пады улетают.** Этап 10c-3 боя на
экране 13, последний шаг взрыва свипера. Каждый пад экрана, до середины
которого дошёл фронт волны, засыпает (`TPad.Doze`: ни пол, ни тело, не
рисуется, огни на нём гаснут), а на его месте взлетает обломок в его
картинке - новый юнит `Game.Wrecks`. Полёт по числам второго стенда:
медленно прочь от взрыва и вверх, курс плавно ложится на 30 градусов
наружу, тяга, притяжение и сопротивление; картинка крутится отдельно, с
18 до 45 градусов за тик. Ни один из пяти падов не падает на дорогу ни от
какого места взрыва над крышей, все уходят за край меньше чем за 4 с.
Огонь из сопла с дымом, оставляющий горящий след, оранжевое зарево,
искры и мелкие молнии по палубе. Сквозь героя проходят без раны. Пад
усыпляется между тиком падов и тиком героя - стоявший на нём падает в
тот же тик. Смерть возвращает пады перемоткой уровня, а обломки
убирает вместе с Тараном - сцена не нужна. Поля волны собраны в запись
`TShockWave`. Тесты - новых 7 (`Tests.Game.Wrecks` 4, `Tests.Pads.World`
2, волна 1), в наборе 854 (по числу `[Test` в коде, с новой фикстурой). Подробности - в `docs/mechanics/arena-3/`,
этап 10c-3.

До этого, на 2026-10-29: **3.0.80 - ударная волна.** Этап 10c-2 боя на
экране 13. Взрыв свипера пускает волну от головы: фронт ровно бежит до
дальнего угла экрана за 33 тика (около секунды) и гаснет; смерть её
убирает. Вид - бесцветный, как в кино: мягкая тёмная полоса (своё
кольцо `CreateWaveBand`, чёрным на 0.6) за тонким белым фронтом (кольцо
из треугольников через `SDL_RenderGeometry`), оба гаснут по мере бега.
Где фронт идёт по дороге, по обе стороны от взрыва поднимается пыль - два
`TSmoke`, едущих с фронтом. Герой отброшен один раз за волну, как
касанием корпуса, но без раны и без звука боли, с моментом пощады
(`TRam.WaveStrikes`, `TMoonGame.ResolveRamWave`): от корпуса, а с
корпуса - туда, где больше дороги. Пады пока стоят - это этап 10c-3.
Тесты - новых 3 (`TRamSweeperTests`), в наборе 846 (по числу `[Test` в
коде). Подробности - в `docs/mechanics/arena-3/`, этап 10c-2.

До этого, на 2026-10-28: **3.0.79 - свипер перегружается.** Этап 10c-1 боя
на экране 13. Последняя жизнь свипера больше не взрывает голову сразу:
20 тиков (около 0.6 с) перегруза - ствол молчит, голова не едет и не
разворачивается, пули её не берут, давка отпущена, едущая машина
тормозит до стоянки; глаз часто мигает, голова белеет (её арт ещё раз
поверх, аддитивно), стволы белые, поверх замыкания бьют толстые молнии
перегруза. Потом взрыв: cue `Shock`, толчок 0.8 (у охотника 0.5), белая
вспышка на весь кадр, гаснущая за 6 тиков, со свечением у головы, и
новый звук `sweeperblast.wav` - удар и гул, уходящий вниз (синтез
`tools/sounds/sweeperblast.py`, семейство `stonewake.py`, без треска).
Решено на стенде: обломки падов летят медленно и крутятся быстро (полёт
по своему курсу, спрайт крутится отдельно); погоня ждёт героя слева от
Тарана - после волны справа заходят два пада мостиком над крышей (этапы
11 и 13). Тесты - новых 2 (перегруз до взрыва, машина стоит в
перегрузе), взрыв охотника без волны; в наборе 843 (по числу `[Test` в
коде). Подробности - в `docs/mechanics/arena-3/`, этап 10c-1.

До этого, на 2026-10-28: **3.0.78 - головы искрят.** Этап 10b боя на
экране 13: обе головы Тарана - и охотник, и свипер - с половины жизней
замыкают. Над головой мелкие молнии, как у обломка танка: выше половины
ничего, на половине примерно молния в секунду, на последней жизни около
двух, длиннее и толще (`TRam.ShortLevel`: от 0.35 на половине до 1).
Молнии - `TLightning` на каждую голову в `TRamPainter`, коробка по
ширине головы, висят над её серединой с качанием и разворотом,
рисуются в `DrawLight`; взорванная голова их больше не даёт, летящие
догорают. Дым охотника на последней трети остаётся. Перемотка машины,
пришедшей заново, вынесена из `TickExhausts` в `TickArrival`. Тесты -
новых 2 (`TestShortsOutFromHalfItsLives` в фикстурах охотника и
свипера), в наборе 841 (по числу `[Test` в коде). Подробности - в
`docs/mechanics/arena-3/`, этап 10b.

До этого, на 2026-10-28: **3.0.77 - свипер метёт.** Второй этап боя на
экране 13: после охотника на мачту встаёт свипер. Голова ездит по мачте
за рядом героя, от крыши Тарана (нижний край стволов над линией 224) до
трёх клеток, 1.5 за тик; встала на ряд, герой спереди - стволы
краснеют (`sweeperHeat`, подкрашен кодом), и поток пуль монстров по
ряду, по очереди из четырёх стволов, скорость 5. Герой на дороге - его
давит таран, а свипер садится вниз мачты и метёт ряд над его прыжком:
закрытый потолок, давка огня не держит. По третям жизней: один проход;
вилка - его ряд и сразу соседний (вверх, если он не падает); лестница -
голова едет по мачте прямо в очереди. Герой с другой стороны -
голова разворачивается сплющиванием, как у охотника. Мишень - весь блок
стволов, 140 жизней на первой сложности, 210 и 280 дальше; под стволами
два щитка из сот (`TTekShield.CreateStrip` - короткая полоска мелких
ячеек), они берут пулю снизу и любую, что лезет вверх круче 6 градусов:
с пола свипера не убить. Попадание - искры и звон брони, щиток - только
вспышка сот. Ряд жизней - тот же, что у охотника, на загрузке ряда
стволы горят белым. Последняя жизнь взрывает голову, пустая мачта уходит
в колодец и остаётся там: третьей головы ещё нет. Заодно: смерть в бою
с Тараном возвращает героя с 10 здоровья (`RamRestartHealth`), а у
Дуплета больше нет отдачи - она сбрасывала с падов. В движке:
`StrikeBarrels`, `BarrelsPoint`, `HeatAt`, `Booting`, `Plate`, cue
`ShotSpeed`; в игре `BulletStruckRamBarrels` между глазом и щитом.
Тесты - новых 12 (`TRamSweeperTests` и полоска в `TBodyShieldTests`),
в наборе 839 (по числу `[Test` в коде). Подробности - в
`docs/mechanics/arena-3/`, этап 10a.

До этого, на 2026-10-27: **3.0.76 - охотник бьёт, Таран давит.** Первый
этап боя на экране 13. Таран смотрит, где герой. Внизу - на дороге или в
прыжке с неё ниже низких падов, там, где его можно задавить, - давит:
рык мотора, и до стены с его стороны на 1.9 за тик (герой бегает 2), на
последней трети 2.1; ствол в давке молчит. На падах герой для тарана
недостижим, но не для ствола: машина бродит короткими плечами, держа его
в прицеле, охотник стреляет. Ствол ходит в своей половине, от вертикали
до 25 градусов ниже горизонта, за вертикалью голова разворачивается
сплющиванием. Очереди - пулями монстров: перед каждой линза горит
красным, после - отдых; по третям жизней сложнее - три в точку, где
стоял, три с упреждением, шланг из шести, который ведёт героя. Мишень
одна - глаз охотника (круг 5 у линзы), мачта, голова и ствол пули
пропускают; жизней 100 на первой сложности, 150 и 200 дальше
(`DifficultyMonsterLives`). Последняя жизнь взрывает голову, пустая мачта
дымит и уходит в колодец, глаз мигает, поднимается свипер и молчит до
этапа 10. Мачта на давку не прячется. Над головой - ряд жизней из 12
ячеек, по четыре на треть, в цветах третей: на защёлке встаёт по ячейке
под щелчок терминала, линза в это время горит белым, и только потом
первая очередь; попадание краснит рамку, ряд мёртвой головы тает
(`TRam.Row`, `THudMarks.DrawRam`). В движке: `TRamTarget`,
`Tick(target)`, `StrikeEye`, `LensPoint`, cue `Shot` и `Blast`,
`Start(orders, livesShare)`, геометрия головы `HeadPoint` для правил и
художника; в игре `BulletStruckRamEye` перед щитом. Тесты - новых 15
(`TRamHunterTests` в `Tests.Game.Ram`), в наборе 826 (по числу `[Test`
в коде). Подробности - в `docs/mechanics/arena-3/`, этап 9.

До этого, на 2026-10-26: **3.0.75 - Таран въезжает.** На экран 13 второго
уровня пришла машина - TEK-R13, Таран: корпус 169 на 128 единиц на двух
колёсах, всегда носом влево, назад - задним ходом. Въезд целиком, по
порядку: музыка туннеля гаснет за 2.5 с в тишину, из-за правого края
под рокот (петля `ramrumble.wav`) въезжает Таран, тормозит кончиком тарана
на 260 (стоп-сигналы, рокот рвётся в шипение `ramhiss.wav`, толчок),
вдох, загорается глаз, из колодца под вой `ramwhine.wav` поднимается
мачта из трёх секций с охотником, и на защёлке головы стартует
`boss3.ogg`. После смерти - короткий повтор: Таран уже на стопе, мачта,
трек играет дальше. После защёлки Таран ездит к своим отметкам между
стенами и стоит 1.5-3 с - первый набросок патруля акта 1, обсуждается
после живого прогона. Голова не стреляет и пули не ловит (этап 9).
Броня - щит TEK по силуэту корпуса (`TTekShield.CreateOver`, маска
корпуса и колёс с альфы арта): соты по контуру, как у пушек арены 2, по
полу обода нет; пуля вспыхивает сотами и ничего не делает. Касание
корпуса или колеса ранит и бросает героя прочь от середины машины,
вверх, с 14 тиками без управления (`THero.Throw`); герой, стоящий на
паде, вне её пути - и в воздухе над ней, пока не сойдёт на пол. Музыка
через смерть: тот же трек, что уже играет, рестарт больше не начинает с
начала - на всех экранах. В движке: юнит `Game.Ram` (`TRam`,
`TRamArt`, `TRamPainter`), действие событий `ram` (`stop`, `file`,
`fadeOut`) вместо `s13-music`, `TSoundBank.PlayLooped`/`Plays`/
`FadeOutMusic`, `THull.DrawUnder`/`DrawBody`,
`TSpriteRenderer.ClipAbove`/`ClearClip` (биндинг
`SDL_RenderSetClipRect`). Звуки синтезирует `tools/sounds/ram.py`.
`boss3.ogg` - настоящий трек. Тесты - новых 16 (`Tests.Game.Ram`), в
наборе 804 (по числу `[Test` в коде). Подробности - в
`docs/mechanics/arena-3/`, этап 8b.

До этого, на 2026-10-25: **3.0.74 - экран 13 стоит, трек босса после
затухания.** Экран 13 второго уровня - арена босса - собран данными и
артом; машины ещё нет (этап 8b). Пол ровный, ряд 11 от стены до стены,
точка возрождения на клетке 2, 11; дверь вправо запечатана навсегда
(`"sealedDoors": [13]` - новое слово загрузчика: запертая дверь, которую
не открывает ни одно событие, игра кончается на этом экране взрывом и
титрами, а не дверью), стрелки там не бывает; пока взрыва нет, 13 -
тупик. Задник - своя
генерация (стена 12, сдвинутая на треть и дорисованная вправо; ChatGPT
перерисовал и сохранённую часть, и картинка взята целиком), ворота на
254 единице. Дальний уступ на 13 свой: губа, три столба, конвои до ворот
и прожектор на весь экран; горят с загрузки уровня, смерть их не
откатывает. Пол 12 и 13 - городская дорога `tek-road-tile` (полоса
опасности замкнута торцами, как палуба пада - шов не нужен), городские
пады `city-pad` и `city-pad-long` стоят на 13 впятером: два нижних у
стен, два верхних и средний повыше; машина (4x4) ездит по всему полу
позади падов - правило для 8b; линия конвоев свободна. В движке
два слова: `"sealedDoors"` уровня и `"fadeOut"` у действия `music` - играющий трек гаснет,
новый ждёт тишины (`TSoundBank.HandOverMusic`, `Tick`) и запоминается
сразу, так что рестарт во время затухания играет уже его; трек, который
уже играет, не трогается. Трек босса - `boss3.ogg`, пока на его месте
копия `boss1b.ogg`. Тесты - новых 6 (три в `Tests.Levels.Events`, три в
`Tests.Levels.Doors`), в наборе 785 (по числу `[Test]` в коде). Подробности - в
`docs/mechanics/arena-3/`, этап 8a.
До этого, на 2026-10-25: **3.0.73 - конвои и прожектор.** Дальний
уступ экрана 12 ожил: по нему ползут огни колонн TEK (фара, ходовые
огни, красный стоп, у части колонн оранжевая мигалка), прячась за
столбами, вторая полоса подключается со второй колонной первой, зазор
между колоннами сужается до плотного потока за 25 секунд; из ворот
прожектор водит пятно восьмёркой по левым двум третям стены, и столбы
под пятном загораются своим силуэтом. Оба загораются с первой строкой
челнока. В движке: виды динамики `convoy` (`TConvoy`, расписание
`TConvoySchedule`) и `searchlight` (`TSearchlight`, `TSweep`, `catches`
- `TCraft.DrawLit`) в `Levels.Dynamics`. Подробности - в
`docs/mechanics/arena-3/`, этап 7b.
До этого, на 2026-10-24: **3.0.72 - сфера жизни, терминал держит
очередь.** На экране 12 после двух строк челнока из искр собирается
зелёная сфера (как сфера здоровья Doom): взял - здоровье до 10, пять
сверх черты зелёные, дверь открывается со стрелкой. Терминал больше не
обрывает текст новым: следующий ждёт, пока предыдущий отстоит своё
время. В движке: `Game.Sphere` (`TLifeSphere`, `TLifeSpherePainter`),
условия событий `hintTyped` и `sphereTaken`, действие `sphere`.
Подробности - в `docs/mechanics/arena-3/`, этап 7a.
До этого, на 2026-10-22: **3.0.71 - камни падают свободно, чекпойнт у
камня.** Камни, падающие после взятия лунного камня, теперь падают
по-настоящему. Раньше они сперва оседали и летели по кубу времени;
теперь их просто отпускают, без оседания и разгона, и они падают тем же
притяжением, что и герой (`Gravity` из `Hero.pas`: 1/7 единицы за тик,
каждый тик - лунное притяжение игры): путь растёт как квадрат времени,
камень трогается сразу. Первой идёт ступень, с 10-го тика, ближние к
камню раньше дальних. Музыку падение больше не приглушает: провал на
пробуждении единственный, а падение лишь возвращает громкость, если
камень взят раньше, чем пробуждение успело это сделать. Чекпойнт: герой,
взявший камень и прыгнувший обратно в яму, раньше возвращался к входу на
экран - камни уже упали, камень взят, к колонке C не подняться, тупик.
Теперь точка возрождения экрана переезжает на колонку камня (клетка 13,
6): герой возвращается на C, в шаге от выхода. Смерть перезапускает
экран целиком (камень снова растёт, камни подняты) и ставит героя на ту
же клетку, у камня; собственная точка возрождения экрана, вход, после
этого закреплена заново. В движке: действие событий `respawn`
(`eaRespawn`; `"x"`, `"y"` с 1, как у точки возрождения; загрузка держит
клетку на сетке, вне стены и над полом), сигнал `TRespawnCue` в
`Events.Director`, `MoveCheckpoint` в `Moon2D.dpr`, ease `fall`
(`meFall`) в `Levels.Dynamics`. Тесты - новых 7 (один на падение в
`Tests.Levels.Dynamics`, шесть на `respawn` в `Tests.Levels.Events`), в
наборе 663 (по числу `[Test]` в коде), результат прогона не указан.
Подробности - в `docs/mechanics/arena-3/`, этап 5e, таблица тестов - в
`docs/testing/scenes.md`.
До этого, на 2026-10-22: **3.0.70 - заряд камня.** Камень теперь
заряжает героя, и заряд виден. Взял камень - через 15 тиков из героя
один за другим, с интервалом в 9 тиков, выходят чёрные орбы: не больше
пяти, заряд делится между ними, так что пятёрка камня - это пять орбов
по единице. Каждый вырастает из точки в пятно над головой, висит,
покачиваясь и держась за героем, потом летит к датчику по своей дуге,
набирая скорость; первый долетает секунды через 4,8 после взятия,
последний - через 6. Датчик - в крыле панели монитора справа: чёрный
диск в бледном ореоле, заряд бежит по ободу дугой света от верха по
часовой, в центре число с процентом. Прирост въезжает плавно со
вспышкой, падение (смерть) показывается сразу, полный круг дышит чаще;
пока заряда нет, слота нет. Не полоска: три полоски на стендах
отвергнуты - полоска это язык экрана загрузки, а заряд принадлежит камню
и выглядит как камень. Смерть на экране возвращает тот заряд, с которым
герой на него вошёл: камень снова на месте, датчик складывается. Новый
уровень начинается с нуля. В движке: `Hud.Energy` (датчик), крыло панели
в `Hud.Vitals`, `Orbs.Feed` (орбы заряда), тёмный орб в `Orbs.Flock` (на
2 единицы крупнее ледяного), новая форма свечения `gsDisc` в
`Render.Glow`, действие событий `energy` (значение 1..100; на экране 11
его даёт `s11-door`). Бак, струйка и потолок заряда (этап 15 арены) ещё
не сделаны: датчик только показывает то, что ему дали. Тесты - новых 21
(девять в `Tests.Hud.Energy`, двенадцать в `Tests.Orbs.Feed`), в наборе
656 (по числу `[Test]` в коде), результат прогона не указан.
Подробности - в `docs/mechanics/arena-3/`, этап 6, и в
`docs/mechanics/hud.md`, сессия "заряд формы".
До этого, на 2026-10-21: **3.0.69 - камни падают обратно.** Взял лунный
камень - камни, поднявшиеся из ямы, теряют силу и падают обратно,
ближние к камню первыми; ступень тоже, и кто на ней стоял, едет в яму,
как на паде. Сначала каждый камень оседает на 4 единицы, потом падает
под линию ямы по кубу времени, чтобы упавший в яму герой не сел на него.
Гул пробуждения гаснет (`stonefall.wav`: тот же гул, тон проседает на
октаву за 3 секунды, глухой удар, 7 секунд), музыка снова уходит под
него, на сотом тике толчок экрана, пыль возвращается к своему ходу, нимб
камня гаснет за 20 тиков. Раз за жизнь: смерть на экране 11 - камень
опять на колонке, камни подняты, дверь снова ждёт камня; смерть на
другом экране оставляет падение как есть. Заодно в этой версии:
пьедестал экрана 10 пересажен на свою материю (ступени, верх и стенки
встали на сетку); левая губа ямы нарисована на 8 единиц в соседнюю
колонку и подпёрта падом без картинки `s10-pit-lip`, так что герой
доходит до нарисованного края и падает только за ним; дверь арены 2
держит героя, пока не загорится стрелка (экран 9 в `shutDoors`, событие
`s09-go-on` открывает её действием `openDoor`); сообщение победы арены 2
теперь "Вы закрыли прорыв!" (было "Вы прорвались! Вперёд!"). В движке:
сцена, запущенная, пока идёт другая, больше не теряется - подхватывает
на следующем тике как склейка (`TakeOver` в `Scenes.Director`;
пробуждение идёт 13 секунд, дольше пути от колонки B до камня); на
смерти `ReArm` сначала перематывает сцены раз за жизнь, потом ставит
конечные состояния сцен раз за уровень. Падение - вторая сцена,
`s11-fall`, её запускает событие `s11-door`. Записан план финала и
титров, без кода: `docs/mechanics/finale.md`. Тесты - новых 2 (подхват и
порядок перемоток в `Tests.Scenes.Director`), в наборе 635 (по числу
`[Test]` в коде), результат прогона не указан. Подробности - в
`docs/mechanics/arena-3/`, этап 5e, и в `docs/mechanics/scenes.md`.
До этого, на 2026-10-21: **3.0.67 - камень просыпается.** Герой встаёт
на колонку B экрана 11 - и камень просыпается. Полсекунды тишины, пыль
замирает; вокруг камня густеет тьма в холодном ореоле, и по комнате
бежит кольцо темноты, видное там, где оно проходит по освещённой стене.
Потом из ямы поднимаются камни: каждый в свой срок, своим темпом, на
свою высоту, с лёгким перелётом и толчком экрана в миг отрыва. Один из
них - ступень между B и колонкой C, на которой лежит камень; остальные -
декор на разной глубине, они покачиваются. Растёт низкий гул, музыка
уходит под него и возвращается. Вся сцена идёт около 13 секунд. Камень -
ломаная глыба шириной 24 единицы, не овал (овал читался порталом): он
поворачивается раз в 20 секунд и парит на полторы единицы. Его не
двигает ни удар, ни взрыв, ни пад, и он неуязвим: выстрел лопается о
него, ничего не отнимая (сбитый, он открыл бы дверь, не будучи взятым).
Взял - нимб гаснет. Челнок говорит, едва герой входит на экран: "Мастер,
это лунный камень. От него идут волны энергии." В движке: сцена
`s11-wake` раз за уровень, её запускает новое условие событий
`heroStands` (герой стоит на клетке: серединой над колонкой, ногами на
нижней линии ряда, не в прыжке и не мёртв); ease `back` (проскок на 4% и
посадка); ход часов динамического объекта (`pace`, пока ему подчиняется
только пыль); вид динамики `eclipse` (`void` и `wave`); картинка монстра
может вращаться и парить (`turn`, `hover`), у размещения есть `shiftX`;
монстр может быть якорным и неуязвимым (`anchored`, `invulnerable` в
`monsters.json`); у сцены новая команда `jolt` - разовый толчок экрана;
камни - спящие пады под нижним краем (`dormant`), ступень не качается;
звук `stonewake.wav` (13 секунд, синтез `tools/sounds/stonewake.py`).
Тесты - новых 17, в наборе 633 (по числу `[Test]` в коде), результат
прогона не указан. Подробности - в `docs/mechanics/arena-3/`, этап 5d,
и в `docs/mechanics/scenes.md`.
До этого, на 2026-10-21: **3.0.66 - закрытые двери.** Экран можно
запереть, пока на нём что-то не случится: герой упирается в невидимый
порог, как у двери испытания. Отпирает событие, и вместе с ним
загорается стрелка вправо - одно действие, не два. На втором уровне
заперты экран 10 (пока не взят Дуплет) и новый экран 11. Экран 11 стоит
данными: далёкая стена экрана 10, сдвинутая влево на треть экрана, так
что дыра свода и её луч оказались слева; три колонки базальта A, B и C,
на C лежит лунный камень; между колонками яма - падение в неё как яма
2008 (жизнь и возврат на точку возрождения у входа); клыки на среднем
плане, камни-декор, пыль экрана 10 с перенесённым лучом. Камни пока
стоят поднятыми с самого начала, ступень - обычный пол, камень берётся
сразу, и его взятие отпирает дверь; дальше экрана 11 пока ничего нет,
его дверь - последняя в кампании (там встают финальные титры). В движке:
список `shutDoors` в корне уровня (`TLevel.DoorShutOn`), действие
`openDoor` (`eaOpenDoor`), флаг `FDoorOpened` в игре сбрасывается на
каждом входе на экран, на рестарте и на новом уровне; загрузка отвергает
дверь, которую ничто не отпирает (замок навсегда), отпирание на экране
без запертой двери, экран вне уровня и экран, названный дважды;
подбираемый предмет `moonStone` в `monsters.json` пока без эффекта и
звука. Тесты - новых 7 (`Tests.Levels.Doors`), в наборе 616 (по числу
`[Test]` в коде), результат прогона не указан. Подробности - в
`docs/mechanics/arena-3/`, этапы 5a-5c, таблица тестов - в
`docs/testing/pads.md`.
До этого, на 2026-10-21: **3.0.65 - пыль туннеля.** Над экраном 10
повисла пыль: длинные полосы заряженной пыли в глубине тянутся вправо, к
городу и боссу, и видны только там, где сквозь них идёт свет - луч из
дыры в своде и тёплое пятно от освещённого пола. Ветра на Луне нет,
поэтому пыль не клубится, а плывёт и слегка покачивается. Скорости полос
12, 8 и 5 единиц в секунду: после первого живого прогона их удвоили,
прежняя пыль была почти не видна. Слой стоит, когда мир трясётся, как
далёкая стена. В движке: новый вид динамики `dust` (`TDust` в
`Levels.Dynamics`); свет поля (`TDustLight`: луч, свечение пола, фон)
считается в углах сетки поверх полосы и складывается с тем, что за ней
(`SdlBlendModeAdd`), текстуры луча нет - его рисует сама пыль; полосы
(`TDustBand`) катятся и качаются по часам от загрузки уровня, смерть их
не откатывает; арт - `dust.mset`, три закольцованные полосы из шума
(`tools/dust/build_dust.py`). Для старых видеокарт: не больше трёх
текстур по 1536 px и шести вызовов отрисовки за кадр. Тесты - новых 10,
в наборе 609 (по числу `[Test]` в коде), результат прогона не указан.
Подробности - в `docs/mechanics/arena-3/`, этап 4, таблица тестов - в
`docs/testing/scenes.md`.
До этого, на 2026-10-20: **3.0.64 - Дуплет.** На пьедестале экрана 10
лежит Дуплет (по-английски Double Tap) - двустволка лунной экспедиции:
чёрный полимер и воронёная сталь, перфорированный кожух, ни дерева, ни
свечения. Это оружие 5 (0-4 - стволы 2008), в руках он вдвое длиннее
обычного ствола, и выстрел вылетает далеко от героя - мишень у него
большая машина TEK. Выстрел - 12 красных дробин, по шесть из каждого
ствола; перезарядка 34 тика против 20 у дробовика: за выстрел дроби в
2,4 раза больше, выстрелы в 1,7 раза реже, дроби в секунду в 1,4 раза
больше. Отдача 6 единиц назад по X выплачивается по тику: стена её
останавливает, край настила роняет героя; плюс лёгкая тряска. Звук -
дробовик 2008, замедленный до 0,8 и выстрелянный дважды с разницей в 14
мс, поверх удар с 110 до 42 Гц, 0,75 секунды. В движке: картинка монстра
может быть шире клетки (`"picture"` в описании, `TPictureDef`,
`PictureBox`), подбор берёт из неё угол, размер, силуэт и ореол;
`TSpriteRenderer.DrawRotated` принимает сторону квадрата; у пули
появился вид (`TBulletLook`: простая и красная); отдача идёт через
`ShoveX`. Арт - `duplet.mset` (`tools/duplet/build_duplet.py`), звук -
`tools/sounds/duplet.py`. Тесты - новых нет, в наборе 599 (по числу
`[Test]` в коде), результат прогона не указан. Подробности - в
`docs/mechanics/arena-3/`, этап 3.
До этого, на 2026-10-19: **3.0.63 - ложный финал, стрелка вправо.**
Арена 2 выиграна, играет трек победы - и игрок решает, что уровень
кончился, а стрелка зовёт вправо. Трек победы теперь звук, а не музыка
(`win.ogg` декодируется целиком на старте и играет на звуковом канале,
удерживаясь), поэтому музыкальный канал свободен: за 5 секунд до конца
победы из тишины въезжает эмбиент туннелей `lunar.ogg` ("Lunar Silence",
Suno, три минуты), а в самом конце вспыхивает стрелка - полая неоновая,
четыре медленных мигания по 60 тиков, около семи секунд, без звука.
Стрелка гаснет, если уйти с экрана, на рестарте и с уровнем. За дверью
арены - новый экран 10: комната лунной породы в гигантском туннеле,
герой на уступе над провалом, далёкая стена, свод слишком высок, чтобы
быть виден; на пьедестале пока дробовик 2008 как заглушка до Дуплета.
Эмбиент идёт дальше с экрана 9, рестарт на экране 10 играет его же.
Клавиша End (отладочная) прыгает на строящийся экран с той музыкой,
которую принесла бы ходьба. В движке: условие событий `victoryEnds`
(поле "lead" - сколько секунд до конца победы; нет `win.ogg` - трек в 0
секунд), у `music` поле "fade", действие `goRight` (`Hud.GoRight`, ритм
`TGoRightBeat` отдельно от картинки), `TSoundBank.PlayTrackHeld` и
`SecondsOf`; меню ставит трек и его счёт на паузу; события
`s09-tunnel-music` и `s09-go-on`; экран 10 - данные (сетка, слои,
`level2.json` и два набора), кода нет. Тесты - новых 11
(`Tests.Hud.GoRight`), в наборе 599 (по числу `[Test]` в коде),
результат прогона не указан. Подробности - в
`docs/mechanics/arena-3/`, этапы 1 и 2.
До этого, на 2026-10-19: **3.0.62 - сцены, кордон.** У уровня появились
сцены: постановка на одном экране по шкале тиков, управление у игрока не
отнимается ни на тик. Первая - TEK-Q6, Кордон, над экраном 9 первого
уровня, около 33 секунд: гул и дрожь из тишины, брюхо корабля выходит
сверху и ползёт справа налево, глаз находит героя, луч сканера, строка
терминала, жгущий луч сжигает бетонера в яме без очков, по тяговому
столбу из люка спускается пад с первым танком игры, танк съезжает на
крышу, пад отходит на стоянку, корабль уходит вверх. Раз за уровень:
смерть посреди - сцена заново с начала, после конца - конечное
состояние. В движке: `Levels.Scenes` и `Scenes.Director`, виды динамики
`craft` и `beam`, слой `aloft`, спящий пад, удерживаемые звуки. Экран 9
переложен: дом к краю, яма в 6 клеток, танк 2008 из файла убран. Заодно
id сцены ищется в любом регистре, как его находит загрузка. Тесты -
новых 67, в наборе 586, все зелёные с первого прогона. Подробности - в
`docs/mechanics/scenes.md`. Ещё в 3.0.62 настилы сетки перестали
проседать под приземлением: картинки у них нет, и седоки уходили в тайлы
уровня (балка экрана 3 под стеной). Тест - один новый, в наборе 587.
Подробности - в `docs/mechanics/pads.md`, сессия "настил не
проседает".
До этого, на 2026-10-17: **3.0.61 - сброс костюма.** У момента костюма
появился удар. Обряд кончается не тиком, а сбросом: вдох (два тика мир
стоит, герой ходит и стреляет, экран под вуалью, герой - белый силуэт),
удар (24 луча через 15 градусов, первый вверх, кольцо, вспышка, тряска),
полёт (лучи сквозь стены и за экран, следы на гранях), эхо (пылинки из
тела). Костюм надевается в тик удара, на два тика позже, чем раньше.
Лучи ранят по всему пути, и за стеной: монстр теряет не больше одной
жизни за сброс, вражеская пуля на пути гаснет. У вихря второго уровня
лучи закручены. Тёмный облик луны готов заранее, для ARENA-3. Тесты -
новых 23, в наборе 519, на компиляторе ещё не гонялись. Подробности - в `docs/mechanics/henshin.md`: раздел "Сброс", этапы 8-10 и
сессия "сброс костюма" в журнале.
До этого, на 2026-10-17: **3.0.60 - настилы сетки.** В сетке коллизий
третья буква: '0' - воздух, '1' - стена, '2' - настил (deck), пол,
который держит только сверху. Новой физики нет: загрузка сворачивает
каждую серию '2' в строке в невидимый неподвижный пад, дальше работают
правила падов - снизу и сбоку проходим, S/вниз спрыгивает, пули бьются.
Для кода 2008 '2' - воздух. На уровне 1 так стали балконы экранов 14-15,
балка экрана 3 и уступ экрана 4 (17 клеток, 9 настилов, 30 падов на
уровне); уровень 2 не тронут. Тесты - новых 8. Подробности - в сессии
"настилы сетки" внизу и в `docs/mechanics/pads.md`, этап 11.
До этого, на 2026-10-16: **3.0.59 - арена грейвелов готова.** Последний
экран второго уровня (экран 9) перерисован и стал первым из двух боссов
уровня: испытание грейвелов идёт шестью актами в одной комнате, и каждый
акт перестраивает комнату. 1 - пол и полки у стен; 2 - парная пирамида и
прицельный дождь; 3 - пол уходит волной к герою, возвращается островами,
по стенам ездят две пушки TEK под щитом и в конце сами себя расстреливают;
4 - карусель-коробка прилетает сверху, две летающие платформы TEK ждут,
пока их убьют; 5 - карусель ломается в падающие пады, блуждающие пады,
бочки с неба; 6 - финал: десять бетонеров на балконах у стен, пресс
опускает балконы ряд за рядом, на половине волны снизу въезжают четыре
танка; после победы - трек победы первого уровня, балконы уезжают, уровень
идёт дальше. Аптечки - за каждого 15-го и в середине каждого акта.
Миниган стал кучнее, центр бьёт двумя. Всё отыграно вживую и закоммичено;
тесты - 488 (новых 112). Весь план и данные акт за актом - `docs/mechanics/arena-2.md`,
коротко о том, что легко забыть, - в сессии "арена грейвелов, этапы 3-6"
внизу. Между этой записью и следующей - 3.0.53-3.0.55 (испытание актами,
движок актов, комната, настройка) и передача на экране 7 без своей версии.
До этого, на 2026-10-12: **3.0.52 - карусель.** Новая родня пада: карусель
водит платформы по замкнутой дорожке, одну за другой, без конца - овал
или коробка со скруглёнными углами, свой размер, период, направление и
старт. Не новый род, а путь: орбита подменяет путь платформы, поэтому
седоки, пули и провал по S у неё те же. Монстр теперь может сидеть на
платформе по её тегу (`seat`) вместо клетки. Первая карусель - на
перерисованном экране 8 второго уровня: восемь платформ по кругу
посреди зала, на них два бетонера и шесть бочек вместо девяти бочек
2008, пол над ямой - двенадцать полок, тройками вперемешку. Тесты - 376
из 376, новые 33 зелёные (одна красная была ошибкой самого теста).
Подробности - в сессии "карусель" внизу.
До этого, на 2026-10-12: **3.0.51 - полка.** Новая родня пада: полка
выдвигается из стены за ней и убирается обратно по программе, без всякого
участия героя. Выдвинутая до конца - обычный пад; в пути и в стене - ни
пол, ни тело: кто стоял, падает, пули летят насквозь. Перед уездом мигает
красная лампа под гнездом, встав на место, полка щёлкает защёлкой (звук
из дубля Suno). Первая стоит на перерисованном экране 7 второго уровня, в
проломе пола под шахтой, вместо падающей платформы. Заодно закрыты две
дыры героя на падах: стоящий не падал с уехавшей полки, вытолкнутый
монстром за край пада висел в воздухе. Тесты - 343 из 343, новые 24
зелёные с первого прогона; тесты полки в комнате ждут стенда. Подробности
- в сессии "полка" внизу.
Между этой записью и следующей - график на мониторе медлаборатории, без
своей версии, со своей сессией внизу.
До этого, на 2026-10-11: **3.0.50 - подбор предметов.** Взятая аптечка больше
не темнеет кадрами смерти 2008: она стоит на месте, целиком заливается
зелёным, рассыпается на крошки, и крошки влетают в тело героя, каждая в
свою точку; тело на мгновение подсвечивается. Убежавшего или прыгнувшего
героя крошки догоняют. Оружие берётся так же, янтарным. Предмет,
уничтоженный чем угодно ещё, рассыпается светлыми крошками, которые падают
и героя не ищут. На полу аптечка теперь HD-кейс, его крест дышит светом;
лежащее оружие светится ореолом. Здоровье и ствол выдаются в тик касания,
как раньше, управление не отнимается. Отыграно и принято; тесты - 291 из
291, зелёные с первого прогона. Вживую не проверены два случая: предмет,
разнесённый у стены, и аптечка с оружием, взятые разом. Подробности - в
сессии "подбор предметов" внизу.
Между этой записью и следующей - версии 3.0.41-3.0.49, у каждой своя сессия
внизу: 3.0.41 - взрывная волна вместо веера; 3.0.42 - рисованное облако
взрыва убрано; 3.0.43 - огненный шар во взрыве; 3.0.44 - осколки ранят
тех, кто ниже; 3.0.45 - танк TEK, корпус на колёсах и стрельба из стволов;
3.0.46 - падающий пад на экране 4 второго уровня; 3.0.47 - покров героя;
3.0.48 - крепление TEK в HD: корпус, ритм и часовой, взрыв; 3.0.49 -
хеншин орбами. Без своей версии: перерисовка экрана 4 второго уровня и
попадание по телу монстра.
До этого, на 2026-10-07: **перерисовка второго уровня, экраны 1-3 (версия та же,
3.0.40: одни данные).** Экран 1 - арена первого уровня, сдвинутая влево: её
платформы стали падами, пол вернулся землёй, через провал ходит паром. Экран
2 - яма: три пада на своих путях ведут от входа к HD-входу в туннели. Экран 3 -
зал секции A одной картинкой, в его колодцах три вентилятора. Материя экрана 3
не тронута. Как делается такой экран - `docs/REPAINT.md`, с него начинать
следующий. Delphi это не собирал и никто не играл. Подробности - в сессии
"перерисовка второго уровня" внизу.
До этого, на 2026-10-07: **3.0.37 - лампы и марево летающих платформ.** На
корпусе каждой платформы TEK мигают две синие лампы, под пластинами сопел
рябит задник. Это обвес `tekPlatform` из `rigs`: обвесы теперь носят не
только пады, но и расстановки монстров, по тегу. У убитой платформы лампы
и марево гаснут: рендерер динамики не рисует маячок и марево под мёртвым
родителем.
Поведение то же, пады экранов 16-17 не тронуты. Это этап 2 плана
docs/mechanics/tek-platform.md. Delphi этап не собирал и никто не играл. Подробности - в
сессии "лампы и марево платформ" внизу.
До этого, на 2026-10-07: **3.0.36 - летающая платформа в HD.** Платформа
рисуется корпусом из двух слоёв (целый и изношенный поверх, по доле
потерянных жизней) вместо кадров полёта 2008; красный глаз разгорается
перед выстрелом. Дым, искры и разряд подбитой платформы идут из точек
корпуса и не зеркалятся. Поведение то же: коробка попадания, огонь,
скорость, оракулы стен не тронуты. Это этап 1 плана docs/mechanics/tek-platform.md.
Delphi этап не собирал и никто не играл. Подробности - в сессии "HD-корпус
платформы" внизу.
До этого, на 2026-10-06: **3.0.32 - аура добывается из материи.** Орбы
ауры больше не рождаются сразу в кольце: по вызову они проступают на
открытых гранях стен, пола, потолка и платформ экрана (ближайшие к герою
первыми), зависают над гранью и по спирали вокруг героя слетаются на
свои места. Орб бьёт с момента, как оторвался от грани; на время
церемонии герою даётся окно пощады, как после ранения. У кольца
появился потолок - 120 орбов. Это этап 4 серии орбов. Delphi этап 4 ещё
не собирал и никто не играл. Подробности - в сессии "добыча и церемония
ауры" внизу, план серии - docs/mechanics/orbs.md.
До этого 3.0.31 - аура из орбов. Бонус "Аура" больше не
расставляет 250 неподвижных пуль 2008: вокруг героя встаёт кольцо из 60
орбов - светящихся сущностей, которые летают по формулам и материю не
замечают. Кольцо течёт по овалу, идёт за героем на поводке (капля носом
вперёд), после ямы летит к нему ниткой, переходит с ним через дверь,
тратится об пули и опасных монстров и гаснет по сроку. Это этап 3 серии
орбов; этапы 1-2 (стая орбов и удар) закоммичены раньше. Подробности - в
сессии "аура из орбов" внизу.
До этого 3.0.30 - обвес платформ с соплами и точки
возрождения. Под платформами экранов 16-17 голубые струи (у двух
сломанных - кашель огнём) и марево (шестой вид динамики, `haze`); лампы,
марево и струи висят на платформах обвесом из шаблонов (`rigs`) и уходят
вглубь вместе с платформой; струя
вспыхивает перед вылетом платформы. У каждого экрана обоих уровней
точка возрождения: яма и смерть возвращают героя на неё, а не туда, где
он вошёл. Предупреждение о перестройке арены длится секунду.
Подробности - в сессиях "обвес платформ" и "точки возрождения и сопла"
внизу.
До этого 3.0.26-3.0.29 - платформы: держат сверху и пропускают снизу,
ездят и качаются, слетают от тарана, в ярости арена босса перестраивается
волной вслед за ним. Сессии - внизу, план - docs/mechanics/pads.md.
До этого 3.0.25 (статус на 2026-10-04) - вентиляторы на втором уровне. Турбина
за квадратной плитой с проёмом и глухие жалюзи встали на место тайлов 2008
`cooler` и `ventelat`: два вентилятора на экране 3, четырнадцать на экране
9, с красным светом из шахты. У вида `fan` появилась подложка (`back`).
Delphi это ещё не собирал и никто не играл. Подробности - в сессии
"вентиляторы на втором уровне" внизу.
До этого 3.0.24 - вентиляторы, собрана и сыграна. Пятый вид динамики, `fan`:
ротор крутит код, решётка перед ним стоит; скорость размывает лопасти в
диск, интенсивность разгоняет и останавливает, мотор умеет умирать. Шесть
вентиляторов стоят в отсеках башни на экранах 14-15 первого уровня. Арт -
картинки ChatGPT, набор `ventilation.mset` собирает
tools/fans/build_fans.py. Подробности - в сессии "вентилятор -
динамический объект" внизу.
До этого 3.0.23 - HD-бочка с дымом. Бочка 2008 заменена
одним HD-кадром (ChatGPT, 128x128): блик ушёл, вместо него из клапана идёт
дым - струйка всю жизнь, столбик на последней трети. Наборы монстров держат
плотный арт рядом с кадрами 2008. Подробности - в сессии "HD-бочка с
дымом" внизу.
До этого 3.0.22 - пилот босса после живого прогона.
3.0.21 собралась и сыграна: манёвры босса остались, поправлено четыре
вещи - таран летит в место героя, виден тот или нет; в манёвре прицельная
пушка стреляет вдвое реже, а не молчит; в ярости нырок и рывок быстрее;
горящий босс не раздумывает. Эти правки Delphi ещё не собирал и никто не
играл. Подробности - в сессии "пилот босса после живого прогона" внизу.
Поверх неё, без версии: отладочная клавиша P выгружает чистые картинки
экранов уровня - первый шаг конвейера перерисовки арта первых двух
уровней (сессия "картинки экранов для перерисовки арта" внизу).
До этого 3.0.21 - пилот босса: босс первого уровня
уходит с круга в манёвры: раздумье на месте с залпами из портов диска, с
дыма - нырок за героем, в ярости - таран с ударом о стену и призом за
увёртку, в огне - охота без возврата на круг. Подробности - в сессии
"пилот босса" внизу. До этого 3.0.20 - искры: один базовый модуль
(Core/Effects.Sparks) и три жизни: искропад из пробоины спутника (вид
`sparks` в динамике уровня - фон, без столкновений), искры подбитых машин и
босса в ярости (со звоном об пол) и искры из брони под пулей - веер по
рикошету, вспышка, изредка трассер; спрайт разрыва пули на железе убран.
После живого прогона: спутник первого уровня искрит по экранам (14-15 -
один дым, 16 - умеренно, 17 - в полную силу) и с перерывами, звоны брони
случайные. Подробности - в сессии "искры" внизу. До этого 3.0.19 - HD-босс первого
уровня: TEK-R1 рисуется диском из слоёв (сессия "HD-босс первого уровня").
Ещё раньше - шаги релиза 3.0, у каждого своя сессия внизу: 3.0.18 - вид взрыва (вспышка,
искры, осколки, плюм), 3.0.17 - общий арт объектов (objectSets), 3.0.16 -
Земля в небе и рассвет первого уровня, 3.0.15 - дым подбитых машин,
3.0.14 - дым и газ, события интенсивности, 3.0.13 - динамические объекты,
маячок, 3.0.12 - статические объекты уровня, 3.0.11 - HD-задники уровней
1-2. До этого 3.0.10 - события уровня из JSON. В level*.json
появилась секция events: условие (enterScreen, allDead по тегу расстановок),
задержка, действия (bigMessage, smallMessage, hint, music). Модель и парсер -
Core/Levels.Events, исполнитель - Game/Events/Events.Director. Подсказка
медлаба выходит через секунду после гибели четырёх labGuard, а не посреди
боя; hintHoldWhileAlive снят. Подробности - в сессии "события уровня из
JSON" внизу. До этого 3.0.9 - настройки игрока отдельно: выбор игрока
(сложность, язык, полный экран - он теперь запоминается) пишется в
%APPDATA%\Moon2D\settings.json и перекрывает bin\config.json по ключам;
config.json игра больше не пишет, в поставке vsync включён. До этого 3.0.8 -
терминал связи. Бегущая строка ушла:
подсказки уровня печатаются по буквам в рамке под кардиомонитором, текст
перед уровнем - так же, на подложке поверх неба. После тега юниты разложены по
папкам Core/Game/Hud/Menu, Hud.Draw стал Render.Brush (поведение то же).
До этого 3.0.5 - слот бонуса вместо подписи внизу, 3.0.4 - шрифт в HD,
3.0.3 - меню. Небо меню собрано заново кодом
(туманность, три слоя звёзд, луна-глобус на CPU), логотип светится и сыплет
углями из собственной альфы, сложность листается кликом без подменю,
колонка пунктов вернулась на 2008-ю, подпись - Computer Dragon, флаги в
HD, вход в подменю - наезд камеры. Подробности - в сессии 2026-09-28/29
внизу. До неё: 3.0.2 - церемония хеншина вынесена из dpr в Game.Henshin
(первый автомат, покинувший TMoonGame; образец для гравела и бонус-слота),
3.0.1 - кадр отделён от экрана уровня (Game.Space), фундамент широкого
экрана, оба без изменения поведения. 3.0.0 - режим 2008 удалён: кругали
здоровья, строка "Score: N", пункт меню и ключи данных ушли; кардиомонитор,
заряд и ряды над фигурами - единственный HUD. Релиза пока нет: он выйдет
на той 3.0.x, которой закончатся внешние преобразования; номер заранее не
назначен.

Линейка 2.x закрыта: 2.5.3 "Farewell 2008" - последняя версия с режимом
2008 и последний релиз ветки 2; режим 2008 в ней включён по умолчанию.
Серия 2.5:
2.5.0 - кардиомонитор здоровья, 2.5.1 - режим 2008 (пункт меню, живое
переключение), 2.5.2 - заряд бонуса справа и общая кисть HUD, 2.5.3 -
ряды здоровья над героем и монстрами. Всё проверено живым прогоном.
Релиз на GitHub с архивом - после тега (предыдущий опубликованный -
2.3.1). Фаза 1 закрыта целиком (классика играется, англоязычна,
репозиторий публичный).
