# Arena 3: the Ram's air fight (stage 18d and on)

Status: designed 2026-11-09; 18d-1 (the barges) built in 3.0.120, the rest not built. The last fight of level 2 before the drone (designed later) and the blast (stage 19). This file is the whole of it: a chat that builds a step of 18d reads `PORTING-NOTES.md`, this file and, for the code it touches, `evolution.md` ("Stage 17a as built", "Stage 17b-2 as built") - nothing else of the arena.

The animated sketches of the design chat are `ram-air-sketches.html` beside this file: schematic, not to scale, made before every number below was settled. Where a sketch and this file disagree, this file is right (the ladder's sketches, for one, show the main barge standing still; it drifts).

## Where the game stands (3.0.119)
- The hero, in the moon form (jump +15%), stands aboard the barge `s13-barge` (`barge-5`, 160 wide), moored at its station in the middle of the screen (`StationLeft`, `Game.Barge`, `TBargeRide`). The checkpoint rides its deck (`PinPierCheckpoint`); point B puts him there (`ResumeAboard`).
- The world flies at `BeltFlight` 4.0: the far plane, the fangs and the city go by fast. Under the barge is the abyss; a fall is a pit (`HandlePitFall`).
- The Ram hangs over the hero with a lag (`TTakeoff.Hang`, `HangLift` 184), rocking, its engine bays and petal nozzles out and burning. It has no turrets, no honeycomb, no wheels.
- The hero holds the orb launcher: endless, a cooldown of 4 (about 8 shots a second at 33 ticks), damage 1. Since 17a an orb that meets the bare hull takes a life; anything on the nozzles or the wheels ricochets (`TMoonGame.BulletStruckRam`, `TRam.StrikeNozzles`). The hull's lives are 150, 225, 300 by the grade (`Game.HullLives`, `THullLives`), shown by the long bar (`Hud.HullBar`).
- A touch of the hull in flight wounds and knocks him down and aside, never up (`THero.Knock`, 3.0.119).
- The Ram does nothing against him. That is the problem this file solves.

## Why
Four faults of what stands now, each answered below:
- **A shooting gallery.** An endless gun against a hull that takes every orb: about 18 s of a held button and the fight is over.
- **The speed is wallpaper.** The flight is fast only on the far plane; nothing in play feels it.
- **The Ram has no teeth and no armour.** No weapon left, no defence left.
- **Nothing makes it move.** It hangs over the hero; leaving the screen or coming close would have no reason.

## The idea in one line
The Ram fights with what flies around it: a magnet under its belly grabs the barges - with the hero on them, too - holds them as a shield and throws them; from its stern mortar it knocks barges out from under him; it rams across the screen and drops like a stone. It can be hurt only where it is hot, and it is hot only after it has done something.

## Rules of the air fight
- **Hot is soft.** The hull is armour everywhere: an orb ricochets as off the bare hull since 3.0.110 (the clink, the sparks, the orb thrown off). A life is taken only by an orb that meets a hot part. Supersedes 17a's "an orb that meets the bare hull while it has lives sinks in". The hot parts:
  - the magnet, while it holds a load and while it cools after a throw;
  - the nozzles, while they relight after a dive and while they brake after a charge.
- **The heat is shown, not told.** A hot part is tinted in code from its own colours toward a hot orange over its art (no second picture: a generation is never drawn twice the same). The tint fades as the part cools - the fade is the window's timer, no counter on the screen.
- **The bar says it too.** While no part is hot the hull bar stands grey with the word "armour" beside it; while any part is hot its cells pulse. The bar's drop and boot (17a) stay.
- **One hint, once.** At the first window of a run the terminal types "Strike what glows" (both languages in `bin/lang`), the comm terminal's line, never again in the run.
- **One threat at a time** till the last tier (see "The ladder"): an attack begins only when the last one has ended. The last tier chains them.
- **The main barge never suffers.** The magnet cannot lift it, a shell bursts on it as on the ground, a dive only rocks it, the charge's corridor never covers it. It is the hero's harbour - a moving one.
- **Never without a floor.** At any time at least one small barge is within a jump of the main barge (see "The barges").
- **No throw upward.** Every touch of the hull in flight knocks as 3.0.119 does: down and aside.
- **The barges block bullets** both ways, as the pads do (`bullets` block): a barge between the hero and the Ram is a wall for both.

## The barges
### The main barge
- `s13-barge` (`barge-5`) as now. Once the fight starts (the first move of the magnet, see "The ladder") it leaves its station and drifts on a slow wide loop of its own: across about the middle 60% of the screen and up and down about half a cell about the road's line, slower than any small barge. It never leaves the screen and never stops for long.
- The checkpoint rides it as now; a pit and a death bring him back onto its deck wherever it is.
- It does not obey the hero and does not follow him; nor does it follow the Ram.

### The small barges
- `barge-2`, `barge-3`, `barge-4` of `pads.mset` (66.8, 104.1 and 122.8 units long; 3.0.118's art).
- Each flies a path of its own, independent of the others and of the hero. The kinds, as a first proposal for 18d-1: a drift along a lane with a slow swell; a loop or a figure of eight; a slow climb or descent across the screen; an overtaking pass from right to left. The lanes lie between the main barge's deck and the Ram's belly.
- **They come in from the right, fast, and brake** to their path's pace - the one place the flight's speed is felt in play. Now and then one passes through without stopping.
- **They leave** past the left edge (their path done), in the magnet, knocked off by a shell, smashed by the charge or the dive. Every one that leaves is replaced: a new one comes in from the right after a short gap (first guess 1-2 s).
- **How many** small barges fly at once grows with the tier: 2, 3, 3, 4 (first guesses).
- **The neighbour guarantee**: a small barge within the moon form's jump of the main barge at all times - the replacement is planned with room to spare, never to the last barge (the pool risk of the chase, "Risks").
- A hero on a small barge rides it as he rides a pad (`TPad.Carry`, riders carried).

## The Ram's weapons
### The magnet (tier 1 on)
The spine of the fight: a cycle that repeats through all four tiers.
- **The art**: generated 2026-11-09 - an electromagnet clamp module, a squat coil housing with a flat round face pointing down, an armoured collar with four bolts and a hazard stripe, cable bundles on both sides, worn grey metal, on a clear ground (1254 square). It hangs under the belly between the two bays, about 30 units wide (first guess). At that size the fine honeycomb and grilles merge into texture - the silhouette is what reads. The heat tints the round face and the side panels; the collar stays cold.
- **The cycle**:
  1. **The pick.** Tier 1: the nearest small barge. From tier 2: the barge the hero stands on, if he stands on a small one; else the nearest. Never the main barge.
  2. **The reach.** A beam from the magnet to the barge (a code line, the magnet's blue), the barge pulled up under the belly, a few units below it. If no small barge is in reach the Ram flies for one - off the screen, to the side or up, and back with it. This is why it leaves the screen.
  3. **The shield.** The held barge rides under the belly and blocks shots from below. The magnet heats while it holds.
  4. **The throw.** The barge is thrown at the hero, aimed - the wrecks' flight of 18a-2 (`Game.Wrecks`, held and aimed), the other way round this time: the Ram learned it from him. A thrown barge that meets the main barge breaks into pieces that fall and are gone; the main barge rocks. A hit on the hero wounds.
  5. **The window.** The magnet, empty, glows and cools over about 3 s (first guess); the orbs sink into it. Cold again, it reaches for the next barge.
- **The lift** (the magnet's catch with the hero aboard): his barge rises with him to just under the belly - a hero's height and a little room between his head and the hull - in about 1.2 s; it holds about 1.7 s with the magnet's hum rising (first guesses). There, the magnet hot and no shield between them, he strikes point-blank. Then **the press**: the barge snaps up to the belly; a hero still on it is wounded and knocked off (down and aside). Then the throw of the empty barge. Jumping off before the press drops him onto whatever flies below - or into the pit. The lift is the Ram's attack - it steals his floor - and the point-blank window is his answer to it.
- While the lift runs no shell is lobbed (one threat at a time).
- The magnet's hum: a new sound, rising in pitch and loudness from the catch to the press.

### The bombs (tier 2 on)
- The third head's shell (`Game.Shells`, `Lob`, the ring on the deck it will strike) lobbed from the stern mortar, which is in `tek-machine.mset` since the machine's art and never used (stage 12, the napalm, was not built). One shell at a time, never a pair.
- The target: the barge under the hero.
- **On a small barge**: the barge is knocked off - it flies away to the left and down, slowing, turning a little, and is gone past the bottom or the left edge. The hero may jump off it; one who rides it out of the bottom falls into the pit.
- **On the main barge**: it bursts as a shell on the road does (`ShellBurstReach` 48, the halved zone of 3.0.98), the barge unharmed.

### The charge (tier 3 on)
- The Ram's own name: it leaves the screen to one side for a run-up.
- **The warning**: a red band blinking at the edge it will come from, across the height of its corridor, the eye red; about 1.3 s.
- **The corridor** is about the hull's height, chosen from the main barge's height of the moment so that it never covers the main barge's deck (the hero on the main barge is always out of it).
- **The pass**: across the whole screen at speed. A small barge in the corridor is smashed to pieces; a hero in it is wounded and knocked along the Ram's way and down - likely into the pit.
- **The brake**: it comes back from the far edge braking - the hull leaning back, the nozzles swivelled forward within their 12 degrees (the swivel put off to 18d in 3.0.113, see "Carried over"), the fire thrown ahead - and hangs low, side-on, about 2.5 s. The nozzles are hot: the window. Then it climbs back to hang over the hero.

### The dive (tier 4)
- **The warning** is all but none: the eye flashes, the jets go out - half a second of silence.
- **The drop**: straight down, like a stone, to just over the main barge's deck. A small barge in its way bursts into shrapnel - its pieces fly as bullets and wound (the 2008 explosion-as-bullets, the game's own grammar). The main barge rocks and the screen shakes. A hero under the hull is touched (wounded, knocked aside).
- **The window**: low, the nozzles relighting hot, about 3 s; then it rises.

## The ladder
The attacks are learned one at a time and then mixed. The tier follows the hull's lives as a share of its full count, so every grade climbs the same ladder (first guesses, from 150, 120, 85, 50 of the first grade):

| tier | lives | adds | small barges |
|---|---|---|---|
| 1 | 100% - 80% | the magnet (the pick is the nearest barge) | 2 |
| 2 | 80% - 57% | the bombs; the magnet picks his barge - the lift | 3 |
| 3 | 57% - 33% | the charge | 3 |
| 4 | 33% - 0 | the dive; the attacks chain (a throw and a dive at once after it) | 4 |

- The magnet's cycle is the spine; the other attacks are chosen between its cycles, at random among the tier's, never the same twice in a row.
- **The numbers**: about 8 orbs a second into a 3 s window is about 25 lives; 150 lives are about six windows - about one and a half a tier. The fight runs about two to three minutes. Tuned live.
- **Point C**: a restart point at the door of tier 3. A death after it brings the hero back on the main barge with the hull's lives at the tier's door, not at full - one death must not replay the whole air fight (the old risk, "Carried over"). With points A and B that is three.

## What comes after
- **The hull's end**: at no lives the hull cracks and bursts, and a small fast drone with few lives flies out of it (the Batpod out of the Tumbler) - the very last part of the fight, designed later in its own chat. Then the blast and the titles (stage 19, `docs/mechanics/finale.md`).
- **Proposed, not decided**: in the windows of tiers 3 and 4, a rotor glimpsed turning inside the open bay - the drone shown before it comes.

## Art
- **In hand**: the magnet (2026-11-09, the source picture outside the repository as all source generations); the barges `barge-2`..`barge-5` (`pads.mset`, 3.0.118); the stern mortar (`tek-machine.mset`).
- **Drawn in code**: the heat tint, the magnet's beam, the shells and their rings, the red band of the charge, the pieces and the shrapnel (cut from the barges' own sprites).
- **To make**: the magnet's hum, the dive's cut-out and drop, the charge's rush, the barge breaking - sounds, by `tools/sounds` as the others.

## Steps
Each its own commit and live run; the version rises by the project's rule.
- **18d-1. The barges.** The flock of small barges with their own paths, coming in fast and braking, leaving and replaced, the neighbour guarantee, the count by tier (fixed at tier 1 till 18d-6); the main barge drifting from the fight's start. The Ram hangs as now. A question to settle first: the flock as a unit of its own beside `Game.Barge` or as a mode of `Pads.Drift` (the chase's drifting pads, which already let a pad go past the left edge and carry riders).
- **18d-2. The magnet and the heat.** The magnet in `tek-machine.mset` (or its own set) by a tool beside `tools/machine/build_machine.py`; the pick, the reach, the shield, the throw on the wrecks' flight, the window. The rule of the hot parts replaces 17a's wound; the heat tint, the bar's two states, the hint. The lift and the press. The hum.
- **18d-3. The bombs.** The stern mortar, the shell of the third head at the barge under the hero, the knocked barge flying off, the burst on the main barge.
- **18d-4. The charge.** The run-up off the screen, the red band, the corridor from the main barge's height, the pass, the smashed barges, the brake with the nozzles' swivel, the window.
- **18d-5. The dive.** The cut-out, the drop, the shrapnel, the rock of the main barge, the window.
- **18d-6. The ladder.** The tiers by the hull's lives, the choice between attacks, the chains of tier 4, point C, the End key's stop at point C; tuning.

## Open
- The flock's unit (18d-1, above) - settled 2026-11-10: a unit of its own, `Game.Flock` (see "Stage 18d-1 as built (3.0.120)").
- The barges' paths: which kinds, how fast, at what lanes; whether one ever comes from below. A first answer is built in 3.0.120, to be judged live.
- The magnet's size under the belly and the gap of the lift; the reach of its beam.
- Where a thrown barge flies if the hero stands on a small barge - at it, or at the main barge.
- The charge's knock: how hard along its way.
- The second dome (the greenhouses, raised 2026-11-09): the flight runs on into another dome, which lengthens the field and could come with tier 3. Not decided.
- The rotor in the bay (above).

### Carried over from the arena's plan
Moved here from `plan.md` when this file was opened; kept as they were written, with what this design answers.

- 18d and on. **The air fight**, designed in a chat of its own: the barges of 17b as the floor - the big one and the shorter ones of `pads.mset`, flying with the hero, nothing passing through them, none destroyed - the fall back onto a barge; grenades, guns, the hull open to orbs. Likely split into steps when designed. Art in hand since 17b: the road's end, the machine on its nozzles, the barges; still to make: whatever the Ram fights with. **To design with it (decided 2026-11-07): the nozzles' own swivel.** Since 3.0.113 a nozzle is fixed to the hull and tilts only with its lean and bank; the swivel - turned about the bay's ring by the pace across (flying right, its bottom swings left and the fire pushes it on; braking, the other way), on top of the hull's lean, the fire and the warmth on the road following - was put off to the air fight, where it may become part of the fight (a nozzle turned away as the window to strike). Keep it within about 12 degrees: the actuators are painted fixed in the bay.
- **The hanging hull within his jump** (noticed 2026-11-08): from the road the hero can jump high enough to touch the hanging hull - its bottom was set just over the moon form's jump (18c), and the touch wounds. Since 3.0.119 the jump is about 25 lower (+15%) and a touch knocks him down, not up.
- **The gallery of 17a**: from the gun to 18d the hull does nothing against him - about 18 s of a held button at the first grade's 150 lives. A stopgap till the air fight is designed.
- The fight in motion (2026-11-01), to settle before stage 18d (the henshin and the throw play on a stopped world, decided 2026-11-04): the belt after the takeoff - the same speed as the chase or faster; what presses the hero in the air in place of the napalm's leash; how the long pads move among themselves; how the bottom of the screen reads as an abyss once the road is gone (the near hills reach the bottom edge and must not read as a floor to drop onto); the end - whether the blast stops the world, the pads and the far plane coming to rest with the city in sight, as the silence falls.
- The air phase with grenades and guns after a long fight - one death replays the whole fight. Keep the fight short.

Answered by this design: the floor of long pads is the flock of barges and the main barge; what presses the hero in the air is the magnet's cycle and the ladder; the swivel is the charge's brake; the gallery of 17a ends with the rule of the hot parts; the hull within his jump stays a touch that knocks him down, and the dive now brings the hull down on purpose; one death replaying the fight is answered by point C. Still open from them: how the bottom of the screen reads as an abyss, and whether the blast stops the world.

## The first designs of the air phase
Kept as they were written before this file; the design above is over them where they disagree.

### Air phase
- No turrets left: the machine takes off, nozzles in place of wheels (the 2026-10-08 idea).
- Drops grenades on the hero and shoots its guns.
- The hero shoots the machine itself - the orbs pierce the armour.

**Decided 2026-11-01, the fight in motion and the air phase, over the text above and "End of the chase" where they disagree:**
- **The fight does not stop.** The chase is long enough to carry the rest of the fight (a live run rode it for minutes with the city still going by): after the bunker the belt runs on, and the evolution and the air phase play in motion. Each act a game of its own, not the same game with bigger numbers: standing ground, the belt, the air.
- **The road ends.** As the machine takes off - the wheels into the hull, the nozzles out - the road runs out under the hero: its edge rides in from the right, and past it nothing, no floor below. The machine needs the road no more, and the road ends: one reason for both.
- **Long pads fly on with the hero.** Over the edge the hero jumps onto long pads that fly right with him and the machine, their nozzles turned to the left. On the screen they keep up rather than drift: the belt carries them and the hero no more, and the speed is the far plane's and the fangs'. The pads move among themselves - not a still floor in the sky; how (falling behind, overtaking, coming in) is the stage's design.
- **A fall is the pit.** Under the pads is the abyss; a fall is a pit, as everywhere in the game, and brings the hero back on a pad - the checkpoint rides with the pads. A death still restarts the fight.
- **The moon form is made for it**: the jump of +25% is the hop between pads over the abyss.

## Decided 2026-11-09, the air fight
The design chat, in order:
- Four ways were shown on animated sketches - the magnet with a shield of pads, the nozzles' fire shower, the charge, the dome pressing the Ram down. **The magnet was chosen** as the spine.
- **The barges fly on their own paths**, independent of each other and of the hero; the Ram picks them up even with the hero aboard; those that are thrown, knocked off or smashed are replaced by new ones.
- **The bombs** knock small barges off - they fly away left and down, losing speed - and burst on the main barge as on the ground; the main barge is too heavy to suffer.
- **The charge** as sketched; **the dive** comes unexpectedly and smashes small barges into shrapnel that wounds; the main barge does not suffer.
- **The mechanics grow one at a time**: one first, then several - the ladder.
- **The main barge drifts too** - "the hero should be as interested as possible".
- **The lift is taken**, as an attack of the Ram's, not a rest: it picks his barge, the press wounds a hero who stays.
- **Damage only in the windows**, and it must be shown where to strike - the rule of the hot parts, the fading heat, the bar, the hint.
- **The magnet's art** generated and accepted.
- **The docs**: arena 3 split into the folder `docs/mechanics/arena-3/`, this file opened for the air fight, the sketches kept beside it.

## Journal

### Stage 18d-1 as built (3.0.120)
The barges, as decided 2026-11-10: the flock is a unit of its own beside `Game.Barge` (not a mode of `Pads.Drift`: the drift sends pads by the road's run, only to the left, and refuses any pad but 32 and 64 wide at load), and the neighbour guarantee is kept by an escort - one small barge always bound to the main one.
- **The main barge drifts** (`Game.Barge`, `TBargeRide`, stage `bsDrift`): the hero aboard at its station (after the cast-off, or at point B the tick he lands on it), it lets go of the station and flies a figure of eight lying on its side - its middle `256 + DriftReachX sin t` (`DriftReachX` 0.3 of the screen, 153.6: across the middle three fifths), its deck `-DriftReachY sin 2t` from the line it was moored on (`DriftReachY` 16, half a cell), a lap in `DriftLapTicks` 594 (18 s), the pace grown into from a standstill over `LooseTicks` 66 - from the station itself, no jerk. At most about 1.6 units a tick across, never still for long; on without him once started. `Dip` - its deck under its line, `WayDown` - how far down this tick, beside `Way`. The game carries its pad across and down (`TPad.Carry(wayX, wayY)`, new) and the checkpoint follows its deck (`PinPierCheckpoint`: `RamFloorY + Dip`).
- **The flock** (`Game.Flock`, `TBargeFlock`): a pool the game names by widths - the pads `s13-flock-1`..`-9` of level2.json, stowed, three each of `barge-2`, `barge-3`, `barge-4` (67, 104, 123 wide), `bullets` block, `bob` 1, their rigs `barge2`..`barge4` (the lamps and the fire of `barge`, the prow's lamps moved by the length). `Start(count)` once the main barge drifts - the count `FlockCounts[1]` = 2 (the table 2, 3, 3, 4 waits for 18d-6). The game wakes a pad as its barge comes in (`FlyTo` its place at once), carries it by the barge's way each tick before the pads' tick, puts it to sleep once gone (`TMoonGame.TickFlock`, from `TickPier`); `ClearPier` grounds the flock.
- **The escort** comes first, at once: its deck `EscortRise` 64 over the main barge's (swelling 4 over 3 s), its middle swaying `EscortSway` 64 either side of the main barge's over 7 s, kept on the screen - always over or beside the main barge, within the jump. After 10-15 s of service the next barge to come in comes as its relief, to the same place; once the relief is in and within the jump, the old escort is let go - a lane from where it is, off to the left.
- **The free barges**, at decks `LaneHighest` 208 to `LaneLowest` 248 (a hero standing on 208 keeps his head under the Ram's belly at about 168), a free barge's deck at least `LanesApart` 20 off the others' when the dice allow: a lane (left at 1.0-1.4 units a tick, a swell of 6 over 4 s; 35%), a loop (48 by 16, a lap in 4 s, two or three laps in place, then off at a lane's pace; 25%), a climb (from 0.7 of the screen at 1.1, from one end of the lanes to the other; 25%), a pass (right through at 2.6; 15%).
- **In and out**: every barge comes in with its left edge 8 past the right edge at `EnterPace` 7 and brakes to its path's pace (the way in eases out as a square, `ComeTicks` from the distance); it is gone once wholly past the left edge - a hero still on it is pushed off by the screen's edge and falls into the pit. The next comes in `ReplaceGapLeast` 33 to `ReplaceGapMost` 66 ticks after a barge is gone; the second of the start comes as long after the escort.
- **Neighbour**: `WithinJump` - a deck no more than `NeighbourRise` 80 up or down from the main barge's, and no more than `NeighbourGap` 64 across, edge to edge; the moon form clears about 100 across at a rise of 80. The escort keeps it from the moment it is in - about a second after the start - on.
- **Riders and bullets**: the small barges are pads - riders carried as on any pad (across and down now), bullets burst on their bodies both ways.
- **Tests**: `Tests.Game.Flock` (new) - `TBargeFlockTests` 17; `TBargeRideTests` +8 (the drift) and 2 reworked (the station held with nobody aboard, a drift once he is aboard); `TPadWorldTests` +3 (carried across and down, the glide between the ticks, the deck in fractions). The tables: `docs/testing/game.md` (Game.Barge, Game.Flock), `docs/testing/pads.md` (carried by the game).
- First guesses for the live run: the drift's reach of 0.3 of the screen and 16, its lap of 18 s and its start of 2 s; the flock of two; the escort's rise of 64, sway of 64 over 7 s and service of 10-15 s, and the relief coming in to the old escort's place (they meet for a moment - watch whether it reads); the lanes of 208-248 and their 20 apart; the paths' shares, paces and sizes; the way in at 7 and the gap of 1-2 s; the neighbour's 80 and 64; the small barges' bob of 1; the prow's lamps of the short barges where the long one's are.

### After the live run of 3.0.120 (2026-11-10)
The paths were right, but the barges moved in jerks, not smoothly as the Ram does. The cause: a pad was drawn on the tick and on a whole unit (`Round(FLeft)`, `Round(FTop)`), while the Ram is drawn between the ticks (`LeftAt`, `LiftAt`). A barge drifting at a fraction of a unit a tick - the main barge's deck goes up and down at about 0.3 - stood still for a few frames and then stepped a whole unit, about three pixels on a wide window, at 33 ticks a second. Fixed in the same version, before its commit:
- **`TPad.Glide(alpha)`** - the pad is drawn on its way from where it stood a tick ago, in fractions of a unit (`Draw`: `FLeft + Glide.X`); **`Lift`** carries the deck's fraction and `Glide.Y`, so whatever is drawn with the Lift goes with it.
- **The riders go with it**: the hero by `THero.DeckSlide` across (the renderer's new `FineX`) and the Lift down (`FineY`, as before); a monster on a deck the same way (`TMonster.DeckSlide`) - the betoners on the carousels included.
- **The lamps and the fire go with it**: the game gives a pad's `Glide(0)` to its rigs (`TParentStand.Glide`), and `Render.Dynamics` draws them that far back between the ticks.
- Every moving pad of the game is smoother for it - the paths, the carousels, the drift of the chase, the pier. Tests: `TPadWorldTests` +2 (the glide between the ticks, the deck in fractions). Left to the eye: the hero and the monsters with their decks, the lamps with their barges; a hero who jumps off a moving barge is drawn on his own tick from then on - a step of up to the barge's way in a tick, about 1.6 units, at the jump (to watch).
- **A death in the air fight** put the hero over the abyss at the right edge first: the restart pinned the checkpoint while the barge was still away (`ClearPier` sends it off, and the Ram's cue that brings it back to its station fires with the screen's triggers on the next tick), so he fell, and the pit brought him to the barge. Older than 3.0.120 - since point B (3.0.118). Now the restart seats the barge at its station itself (`SeatBarge`, shared with `ResumeAboard`) before it pins the checkpoint and places him.
