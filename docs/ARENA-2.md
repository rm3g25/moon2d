# Level 2 screen 9: the gravel arena (first of the two level 2 bosses)

Stage plan. Status: stage 1 done (3.0.53: trial in acts, arrival glow); stage 2 built (3.0.54: acts engine, acts 1-3); stage 0 done (the room, data and art only, 3.0.54; the first run found the waving ladder unclimbable, acts 2-3 relaid with a holding pair pyramid - "пойдёт", pushed); stage 2a done and committed (3.0.55: gravels face either way, pit returns one at a time). Stage 3 built (3.0.56: the TeK cannons, the shared TeK shield, the floor islands, the bottom steps yielding; waits for its live run). Stage 4 (act 4, the carousel) is designed (2026-10-13); 4.1 (the platforms' engine) is built (2026-10-13) - nothing in the data uses it until 4.3, so it has no live run of its own; 4.2 and 4.3 are not built. The second level 2 boss - the mast-turret machine - comes on the screens after this one; this arena must not repeat it and must not repeat the level 1 pad arena.

## The idea in one line
Five arenas in one room: each act brings its own gravels (15 on normal, more on hard and wild); when the last of them is dead, the room rebuilds itself, and every rebuild takes away what the hero stood on. Selena does not throw gravels at the hero - she rearranges the room; the gravels are the weather.

## Rules of the room
- No support lives longer than one act - and that means the REBUILD takes it away, not that a shelf cycles every few seconds. Within an act the hero's steps stand still; what keeps him moving is the aimed rain, not a shaking ladder. (Learned the hard way: a waving ladder is five jumps in a 2.5 s window - nobody climbs it, and act 3 then corners the hero on the doorstep.)
- Gravels (gravelFemale) do not shoot and cannot climb - every permanent height would be a bunker. Hence no static platforms at all; the white blocks of 2008 are gone.
- No roofs: no shelf hangs over another shelf of the ladder. A step under a step is a bunker - random drops and the aimed rain land on the roof and walk off it sideways.
- Steps are two cells wide: a gravel is a cell wide and the aimed one lands on the hero's column, so a one-cell step leaves no sidestep.
- Walls left and right stay; the floor is shelves, as on screen 8 - the room has no painted floor, the back wall below the shelves is the shaft.
- The room art is the ChatGPT generation with the violet ceiling grating; the docks for the sleeping shelves are the shelf-dock of pads.mset behind every shelf, as on screen 8 - the whole room is a wall, so every dock is a wall nest.
- Barrels and gravels: a barrel's blast strikes every living monster of the screen inside its radius (StrikeMonsters in Moon2D.dpr), gravels included, and the kills are rewarded. A barrel the hero can shoot over a pack is a gravel grinder, so no barrels ride the carousel (decided 2026-10-13). The sky barrels of act 5 stay hero-only - the flag goes on the spawn.

## Gravels
- Arrive in violet light - Selena's colour: a column of light from the top edge and a glow gathering into the point (Game.Arrivals, a light effect of its own, not the hero's shroud).
- A gravel that walks out of the RIGHT gap teleports to a random top point, again with the violet glow. The left gap is a wall for them (the hero's entry).
- A gravel that falls into a hole (acts 3-4) teleports back over the hero's column: what he dropped falls back on him (3.0.54). One at a time, every 10 ticks, up to two columns either way (3.0.55) - the whole pit at once was a crowd on the hero's head.
- Every gravel of the trial walks off to a side the dice pick - at birth from the sky, the aimed one too, and at every return (3.0.55). 2008 sends every monster left, and a landing takes its step from that facing, so the room filled from the left.
- No teleport while walking on the floor.
- A teleported gravel is the same gravel - it still has to be killed.
- No cap on the living: a wave comes every time while the batch lasts, whoever is still alive. The batch is the only limit; a cap made standing still pay off.
- The first gravel of every act is a herald: a column twice as broad and long, standing twice as long (3.0.54).
- Aimed rain from act 2: every third gravel of a batch - the mark goes up over the hero's column, the gravel follows it 10 ticks later at that column (3.0.54).

## Act advance - all of the act's gravels killed
- Each act has its own batch of gravels: it spawns exactly that many and no more.
- The next act does NOT come until every gravel of the current act is dead - the room is clear of them. Then the rebuild.
- The batch size depends on the difficulty: normal 15, hard and wild more. Proposed: normal 15 / hard 25 / wild 40 - five acts give 75 / 125 / 200, the very totals of 2008 ("gravelBoss"), so the size of the trial does not change. Tuned by live runs.
- JSON: the batch is a TDifficultyValue ({"normal": 15, "hard": 25, "wild": 40}), the same shape as gravelBoss today.
- It is the 2008 gate (quota spent and nobody alive), only per act instead of once for the whole trial. An aimed gravel still on its way holds the gate too, and so does a gravel waiting in the pit for its turn to come back.
- Since 3.0.56 the gate is watched every tick once the batch is spent, not at the wave pace: the room rebuilds the moment the last gravel dies.
- Nothing carries over: the next act starts with an empty room. The rebuild is the only breath the hero gets - a short beat (the violet flash, the latches), then the new batch starts falling.
- The finale opens when the last gravel of act 5 is dead.
- Death restarts the trial from act 1 - decided to keep it so for now (no per-act checkpoints).

## Medkits
- The three trial medkits of 2008 are removed. Their triggers (changeMusic, heroX, gravelBoss) live in "screenTriggers" of level2.json - triggers of a screen that no body carries.
- One medkit per 15 killed gravels on every grade (one per act on normal; more per act on hard and wild because their acts are longer), delivered by the same violet teleport; from act 2 on it lands on the top of something the hero has to climb to - the event action medkitsOnto names the bank (act 2: the peak of the pyramid, bank s09-crown).
- On normal the 15th kill is the end of the act, so the medkit comes at the act change. A medkit at the start of every act was offered and turned down - too generous; the medkits stay one per 15 kills.
- Bait pads (two falling pads at the top riding medkits) - dropped 2026-10-13: nothing new, and a medkit on a pad is taken and left in one jump.
- Pickups are excluded from the gate (AnyAliveOnScreen counts them now - an untaken medkit would hold an act forever).
- Act 4 (decided 2026-10-13): two medkits, both riding carousel pads (a seat, as the barrels and betoners of screen 8), not teleported onto a bank - the crown sleeps in act 4, and a medkit on a pad that has to be caught on the fly is a reason to climb. The hero is worn by then and act 5 is chaos. The two sit on pads half a lap apart. Whether the per-15-kills teleport also brings one in act 4: see Open.

## TeK cannons (stage 3)
The room gets guns that do not aim. They sweep a whole level of the pyramid at once from both sides: the damage is unavoidable on that level, and the only way out is not to be on it.
- **Whose.** TeK, not Selena: grey metal, gold trim (the colours of TeK, gold as their letters). The cannons are drawn from scratch in ChatGPT.
- **Arrival.** Both slide in from beyond the left and right screen edges once, at the start of the act, and settle on the walls - the walls are solid there.
- **Movement.** They ride up and down their walls in unison - always face to face, on the same row. So a volley always sweeps exactly one row, and the other rows are free: never every row at once, with no rule of its own for it.
- **Every row, the bottom one too.** They come down to the floor level, or the floor is the safe place. The heights are the heights of a standing hero: floor row 11 -> the volley at row 10, a step on row 9 -> row 8, and so on.
- **Warning.** No row highlight - the cannon riding to a row is the warning. Before firing: a red muzzle fire and `padhum.wav` (the level 1 arena's rebuild warning).
- **Volley.** A long, heavy automatic burst across the room, both cannons at once (the .50 of Rambo 4), not a single shot. The two bursts meet the opposite cannon - the shield takes them.
- **Gravels.** The volley does not hurt gravels (as the sky barrels) - otherwise the room kills them for the hero.
- **Invulnerable.** They cannot be killed. Bullets (theirs and the hero's) hit the shield.
- **The partial floor.** The floor comes back in pieces: a couple of floor shelves (decided 2026-10-13), islands of 1-2 shelves within jump reach, never in the corners (the corners stay pit). The level above the floor is swept too, so standing on an island is no hiding place. The right-gap teleport has no part here: there is no floor at the gap, the gravels fall into the pit and return.
- **The thinner pyramid.** A couple more shelves of the pyramid were to go. The bottom pair (row 9 cols 2-3 and 12-13) cannot simply go: row 7 is then 4 rows above the floor and JumpReach is 2, so the hero who drops to the islands never climbs back; and row 9 has no other place without a roof (cols 4-11 are under row 7 and the crown). They yield to the cannons instead (see Mount). No other pyramid shelf goes for now (decided 2026-10-13); revisit at the live run.
- **Lifetime.** One act. They come at its start and die at its end.
- **Act.** Act 3 (decided 2026-10-13): the collapse takes the floor, then the islands come back and the cannons slide in.
- **Size.** 2x1 cells (64x32 units; art 6 px a unit, 384x192 px) - serious guns.
- **Mount (variant B, decided 2026-10-13).** The cannon is clamped to the SIDE face of the wall pillar, not to its front: the pillar is col 0 (x 0-32) on the left and col 15 (x 480-512) on the right, so the cannons take cols 1-2 and 13-14 and the muzzle stands two cells out of the wall (x 96 / x 416). The monorail on the front of the pillar (variant A, cols 0-1) was weighed and turned down: cheaper, but the gun looks like a fitting on the pillar.
- **The bottom steps yield.** Riding through rows 8-9 the cannon would sit on the bottom steps (row 9 cols 2-3 / 12-13: col 2 / col 13 is inside the gun). So when a cannon comes to rows 8-9, the step on its side slides into the wall (as `shelvesSleep`), and slides out again when the cannon rides away. Steps of their own bank s09-foot (3.0.56); cannons in unison, so both steps go and come together. A hero on the step falls. The cannon commands the shelves.
- **Fires from the muzzle**, not from the wall.
- **Touching a cannon wounds.** Its body cannot be a bunker: a hero standing inside the gun behind the muzzle (at the bottom row the left gun is over the doorstep, col 1 of row 11) is hurt by the contact. The contact box is the body and carriage, not the empty air over and under the barrels - taken from the art's alpha.
- **Respawn inside a cannon** - the mercy window of the respawn is the time to jump out of it.
- **Look.** Serious guns: TeK grey worn steel, yellow-black hazard stripes, twin ribbed barrels, a dark sensor lens (lit by the code with the red fire), no text or emblem (the right gun is mirrored). The art faces right (left wall) and is mirrored for the right wall.
- **Art.** Generated 2026-10-13 in ChatGPT from the TeK style sheet (`tek-style-reference.png`, made from tank-hull, mount-hull, platform-hull, medic and cordon sets) and the prompt of this plan; accepted. 1774x887, real alpha. Packed (3.0.56) by tools/cannon/build_cannon.py from `cannon.png` in the sources dir.

### The TeK shield (shared)
A shield for the TeK machines while they cannot be hit - the cannons first, the bosses later (the mast-turret machine and the ones after it). Not orbs.
- A pale gold honeycomb always visible around the machine.
- A bright flare of the cells around the point of a hit, fading in about half a second.
- No sparks: sparks are the game's sign of a wound, and this is not one.
- Telling it from the boss hull: the ricochet of the mast-turret machine is a hull that is invulnerable always; the shield is invulnerability that will fall.

### The scripted end of the cannons
Their death is a scene, not a mechanic: they do not die of hits. The hero may shoot - his fire is too weak to matter.
1. The last gravel of the act dies - the shield falls at once (the cells blink and go out).
2. Overheat: the barrels go red. The cannons stop firing and race up and down the walls in unison, fast, with `padhum.wav` playing.
3. They stop dead face to face above the pyramid, in the upper part of the screen.
4. A long burst point-blank into each other.
5. Both explode at the same moment (with screen shake). Above the pyramid - spectacular and out of the hero's way.
- The whole scene deals no damage: from the peak the hero can jump to its height (JumpReach 2), so nothing in it may hurt him.
- Debris, if any, goes into the pit or off the screen.
- Length: about 3 s of racing, half a second to stop, about 1.5 s of the burst, then the blast. Not shortened for now, even though the restart from act 1 replays it on every try.

## Acts (batch of 15 on normal)
1. **Floor.** Flat floor, two shelves at the walls. Random drops. "A shooting gallery." The wall shelves alternate with a long warning (1.2 s) - the lamp lesson in the safe act.
2. **Ladder.** The pair pyramid wakes from both walls up to the peak and HOLDS for the act. Aimed rain starts: every third gravel arrives in the column over the hero. The medkit goes on the peak. A rehearsal act: the player learns the ladder while the floor is still there.
3. **Collapse.** The floor slides away in sections from the end farthest from the hero toward him, the wave drives the hero onto the ladder, which holds. Below - a pit; a fallen gravel teleports up over the hero. Gravels landing on steps walk off them and cascade down. Then the floor comes back as islands and the TeK cannons arrive (see TeK cannons) - decided 2026-10-13, the cannons and the islands both approved.
4. **Carousel.** The room is rebuilt around a box carousel in the centre (a rehearsal of the square carousel wanted for the next level). Details in "Stage 4 design" below.
   - The pyramid thins out: the crown and the ladder go to sleep from the bottom up, step by step - late means the pit - and only the foot (row 9, cols 2-3 and 12-13) stays, as ledges at the walls.
   - The floor comes back one through one: a shelf, a hole, a shelf.
   - The carousel, parked above the screen, flies in and stands on its track, then starts to turn. Two medkits ride two of its pads. No barrels.
   - Two TeK-K10 platforms come gradually - the first at a third of the batch, the second at two thirds - one above the carousel, one below it; they leave when the act ends.
5. **Chaos.** The carousel breaks: its pads become falling pads one after another. The floor comes back in random pieces. Shelves blink out of step.
   - Stray pads: ordinary pads fly in from beyond a random edge to a random point, hang, fly on to another point or out. They misbehave at random: fall like a falling pad, turn back halfway, twitch. Transport nobody can count on.
   - Barrels from the sky through the same violet teleport, exploding on impact with the floor, a shelf or a pad. The blast wounds only the hero - gravels walk through it. Not a weapon, the weather.
   - Idea (2026-10-13, not decided): big shells in place of the barrels, striking the hero only.
6. **Finale - betoners.** The floor stands, everything below sleeps. Only the top row of shelves under the ceiling wakes; 10 betoners teleport onto it, no more than 3 alive at once.
   - The press: every ~10 s the top row sleeps and the row below wakes - the betoners drop a row lower. In half a minute they are on the floor beside the hero, point-blank.
   - A killed betoner is replaced on the TOP row: a fast killer keeps them far, a slow one gets all ten at his feet.
   - Barrels keep falling through the finale: time itself hurts (or the big shells, if the idea stands).
   - The way up to them is the falling and stray pads in the middle of the room.
   - Note: the pyramid has no "rows" to press down; the press needs rows of its own (betoner rows may roof each other - betoners shoot, a roof does not shelter from them). Decide at stage 6.

## The acts engine as built (3.0.54)
- Condition `"when": "actReached", "act": N` - holds while the trial's act is N or later (the director pulls the act through a cue; 0 while the trial does not run). A restart re-arms the screen and the trial is back on act 1, so act 1 events fire again.
- Shelf banks: `"shelf": {..., "bank": "s09-ladder", "held": "in"}` - a held shelf runs no file program, stands out or in until an event tells it. "held" needs a bank.
- Actions: `shelvesWake` (program optional, hold by default), `shelvesProgram` (program required, wakes a sleeping shelf), `shelvesSleep` (warns if out, slides in, stays). Keys: target (bank), program (hold / wave / alternate / blink), out, in, warn (seconds; 0 = the shelf's own), order (file / left / right / up / down / toHero), step (seconds between shelves).
- A told shelf starts its run from wherever it stands (slide from the current depth); the order step and the program's own wait (alternate: every other shelf waits a turn out plus a slide; blink: a dice wait within one round) delay the command itself, so the shelf keeps its old run until its moment.
- Fly-in: `"parked": "above"` on a pad group - its pads wait two cells above the top edge over their file places; the action `flyIn` restores the group at BriskPace (rippling from the zone middle). Not used in acts 1-3; first use in act 4.
- `medkitsOnto` (target bank) - the trial's medkits come down over a random shelf of that bank from then on.

## Screen 9 as seated (stage 0, after the first live run)
- Objects: s09-room (0, 0, 512), s09-doorstep (0, 351, 64 - the left slab of s08-room, cols 0-1 of row 11), s09-lamp-off (15, 126, 8) with a dying beacon on s09-room at 18.4, 132.6; a shelf-dock (x-3, y+1, width 38, tint 70) behind every shelf. Tiles of 2008 cleared, the 14 fans of 2008 removed.
- Grid: row 11 = cols 0-1 solid (the doorstep; respawn 2, 11 = col 1), cols 2-15 open.
- s09-floor - 14 shelves, row 11 cols 2-15 (held out). Col 15 is a shelf too: a solid cell under the right gap was a bunker from act 3 (the aimed rain is clamped to col 14, falls into the pit and comes back there). Since 3.0.56 cols 4-5 and 10-11 are the bank s09-isle.
- s09-wall - row 9, cols 1 and 14 (act 1).
- s09-ladder - the pair pyramid: row 7 cols 4-5 and 10-11; its bottom pair row 9 cols 2-3 and 12-13 is the bank s09-foot since 3.0.56. s09-crown - the peak, row 5 cols 6-9. Every hop is a rise of 2 with no gap (JumpReach(2) = 2). No roofs.
- Events: act 1 - wall alternate (out 2.5, in 1.5, warn 1.2); act 2 - wall sleeps, foot wakes, ladder wakes and holds (order up, step 0.2), crown wakes and holds (order left, step 0.2), medkits onto the crown; act 3 - floor and isle sleep toward the hero (step 0.35); 200 ticks into act 3 (s09-act3-cannons) the isle wakes and the cannons come.
- Acts 4 and 5 run in the room act 3 left (floor gone but the islands, pyramid holding) until their stages.

## Stage 3 as built (3.0.56)
- **Units.** Game.Shield (TShieldArt - one hex cell texture; TTekShield - an ellipse of pointy-topped cells about the machine's middle, flares of 16 ticks within 9 units of a hit, Fall = blink and out in 14 ticks, TryEntry for a stretch). The honeycomb lies on the rim alone (asked after the first look: a full honeycomb hid the gun): at rest only the cells past 0.72 of the ellipse show, easing in to full at 0.95; a flare reaches in to 0.5 and no further; cells under 0.01 are not drawn. Game.Cannons (TCannonArt - the set tek-cannon; TCannonPair - rules and look, the game carries out TCannonCue).
- **Art.** tools/cannon/build_cannon.py -> bin/sprites/tek-cannon.mset: hull and heat (the barrels in alpha, added red as they overheat), 384x192. Measured in units of the right-facing art: muzzles 63.4, 14.07 / 21.54; lens 32.16, 12.37; contact boxes plate 0.6..8.3 x 0.65..31.2, receiver 8.3..40.8 x 7.0..25.7, barrels 40.8..63.4 x 11.7..24.0.
- **Event action** `{"action": "cannons", "rows": [10, 8, 6, 4], "yield": "s09-foot", "yieldRows": [8, 9]}` (Levels.Events TCannonOrders; Levels.Defs checks the yield bank). The pair lives the act its event waits for (actReached N); fired late, its scene plays at once.
- **Cycle.** Slide in at row 2 (30 ticks, smoothstep) -> ride to a random stop other than the current one (3 u/tick) -> red fire at the muzzles + padhum (20 ticks) -> burst (40 ticks, a round from each cannon every 2 ticks, barrels in turn, 16 u/tick, streak 18x3; shot sound shoot2.wav every 4 ticks) -> rest 22 ticks (rounds reach the far shield) -> next stop.
- **Yield.** A ride whose path touches rows 8-9 first tells s09-foot to sleep and waits 28 ticks (the shelf's warn + slide); the bank wakes (hold) once the pair has left the band and does not ride back into it. s09-foot = the four bottom steps (row 9 cols 2-3, 12-13), woken in act 2 before the ladder.
- **Hits.** A round on the hero's body wounds (mercy holds; SHitByBullet). Rounds stop in the other shield with a flare. Hero bullets: into a shield - gone with a flare; on bare steel (scene) - armor sparks and ping, no damage. Contact boxes wound (SHurtByMonster) and shove the hero 4 off the wall.
- **Scene.** The trial's act changes -> shields fall, rounds in flight harmless, heat rises over 100 ticks, padhum every 36 ticks; race between rows 1 and 6 at 8 u/tick, 5 legs; to row 2, hold 16 ticks, duel 50 ticks (harmless rounds, sparks on the other muzzle every 4th tick), then both blow up (ekMachine, decoration shards, platform.wav, trauma 0.8). Nothing in the scene wounds, contact included.
- **Trial.** The gate is now watched every tick once a batch is spent (the room rebuilds the moment the last gravel dies; an aimed gravel let down that same tick holds it). RoomBusy = the pair is leaving: the first wave of the next act waits for the scene.
- **Floor islands.** s09-isle = floor shelves cols 4-5 and 10-11: they sleep with the floor at act 3 and come back with the cannons 200 ticks into it (event s09-act3-cannons).
- **Left for the live run.** Shield ellipse 38x22 eats hero bullets near the walls, and its rim ring still crosses the muzzle tips and the clamp plate (31 units out of a 38 half-axis) - 42x24 would clear the gun but eat more bullets; burst/warn/ride tuning; the islands' roofs (every floor column has a pyramid shelf above); the doorstep under the bottom-row cannon.

## Stage 4 design (act 4: the carousel)
Decided 2026-10-13 unless marked "first guess"; the numbers are tuned at the live run.

### The room in act 4
- **Pyramid.** The crown (s09-crown) and the ladder (the row 7 pairs) sleep from the bottom up, step by step, before the pads land - they stand inside the carousel's box. s09-foot (row 9, cols 2-3 and 12-13) stays: the doorstep -> the left foot is a rise of 2 (JumpReach), and the foot is the ledge from which the bottom run of the carousel is reached. Twelve shelves of the pyramid become four.
- **Floor, one through one.** Shelves on cols 4, 6, 8, 10 and 14 (floor-03, -05, -07, -09, -13), holes between. Cols 2 and 12 are left out on purpose: with the foot over them they would be a roof (the aimed rain and the random drops land on the foot and walk off, so the hero under it is untouched - a bunker). Under each foot there is a hole two cells wide instead. Col 15 stays a hole (the right gap, where gravels walk out and teleport). The shelves of the old isle that are not in the new set (floor-04, -10) sleep.
- **A hole of one cell is a real hole.** The hero stands on a deck by the point of his middle (THero.DeckUnderFeet), so he falls when his middle is over a hole and crosses it by a jump. A gravel falls into it the same way and comes back through the pit queue.
- **Carousel.** One carousel of shape "box" (Levels.Carousels has it, with a rounded corner). First guess: centre (256, 232), size 224 x 112, corner 24, 8-10 pads, a lap in 14-16 s, clockwise. The bottom run is at about y 288 - a rise of 2 from the floor, level with the foot. The pads fly the lap on their own thrust (rig "pad"), as on screen 8.
- **No barrels.** See "Rules of the room".

### Parked carousel
- The whole carousel is parked: its pads wait two cells above the top edge over their slots on the track. A pad of a carousel joins no group today, so the `flyIn` of a parked pad group does not reach it - the parked flag goes on the carousel itself, and `flyIn` takes a carousel tag as well as a group tag.
- On the event the pads ride out from above one after another (BriskPace, rippling from the middle) and stand on the track in their slots. They stand still until every pad has settled; then the carousel starts to turn, its clock speeding up from zero over about 3 s (first guess). A pad that caught up with a running slot would be a chase, not a landing.
- The orbit clock runs at a constant step today (TCarouselOrbit): the speed-up is a new piece. A rewind (death restarts the trial from act 1) parks the carousel again.

### Shooting platforms
- **Who.** The TeK-K10 platform of monsters.json as it is: patrolNoEdgeCheck at speed 2 (a horizontal lane, wall to wall), aimedDouble every 41 ticks at bullet speed 5, 27 lives, a machine explosion with a blast of 100 lives over 80 units. Shootable, as on level 1.
- **When.** By the birth of the batch's gravels, not by kills (no cap on the living, so the two differ): the first when gravel number floor(batch / 3) + 1 is born, the second at floor(2 * batch / 3) + 1. Normal (15): the 6th and the 11th; hard (25): the 9th and the 17th; wild (40): the 14th and the 27th.
- **Where.** Two lanes. The upper at row 2 over the carousel (hull about y 70-90; the top run is at about y 176, so a hero on it has 54 units of air over his head), entering from the left wall. The lower at row 10, the hero's own row, sweeping the floor wall to wall, entering from the right wall (hull about y 326-346, 6 units under the carousel's pad bodies). The lower one wounds by touch and aims: the floor is no place to stand, the way out is up, onto the foot and the carousel. The foot ledges (row 9) are above its hull and do not touch it.
- **Entering.** A slide from beyond the screen edge, as the cannons do.
- **Leaving.** They fly up off the screen when the act's gate opens, so the room is clear for the rebuild (default, not confirmed). Not a kill: no score, no wreck. They do not hold the gate - the gate counts gravels only.
- **New engine pieces (built at 4.1).**
  - The event condition `gravelDealt` - JSON `"when": "gravelDealt", "act": 4, "part": 1, "of": 3`. It holds from the moment gravel number batch * part div of + 1 of that act is let down, and stays true once the act is past. The count is of gravels dealt, so an aimed gravel counts from its mark, 10 ticks before it falls. "part" 1 of 3 gives the 6th / 9th / 14th gravel on normal / hard / wild, "part" 2 of 3 the 11th / 17th / 27th. The director pulls the trial's progress (act, batch, gravels dealt: TTrialProgress from Game.Trial) through a cue, as it does the act.
  - The event action `spawn` - JSON `{"action": "spawn", "monster": "platform", "spriteList": "platform.mns", "row": 2, "from": "left"}`. The event must wait for an act (the parser refuses it otherwise). "spriteList" is optional and is the key a placement has: the definition of the platform in monsters.json names none, so the action has to. TMonsterField.SpawnInLane makes the body in the cell column 1 of the row's feet line, TMonster.EnterFrom puts it off the screen on the side (x -40 / x 520), and it slides in through the wall pillar at 4 units a tick (LaneStep) - no wall oracle is asked while it slides - to x 32 / x 448, then patrols as a placed platform does, away from the side it came from. It holds fire until it is in. The game lets it in only while the trial is still in the act the event waits for (SpawnGuest in Moon2D.dpr). TMonsterField.Create checks the monster ids of every spawn action at level start.
  - Leaving: the trial's cue carries `ActEnded` (every gate, the last one too); the game tells the field `DepartGuests`, and every body that came in along a lane flies off the top at 8 units a tick (LaneLeaveStep). TMonster.Depart puts it to mlDead with no death event - no wreck, no score, no blast, it hurts and is shot no more - and it is drawn while it flies, then gone. A guest killed before the gate dies as any platform does. The gate still counts gravels only.
  - A spawned platform wears no rig: see Open.

### Sequence of the act
1. The trial reaches act 4: the crown and the ladder go to sleep from the bottom up; the floor wakes one through one; the carousel flies in and then starts to turn; the first wave waits until it stands (RoomBusy, as for the cannons' scene - to settle at 4.2); then the batch begins to fall.
2. The 6th gravel born (normal): the first platform enters. The 11th: the second.
3. The last gravel dies: the platforms fly up, the rebuild goes on into act 5.

## Stages
Each stage ends with a live run. Versions: one per stage that changes mechanics, next free after 3.0.56; the tag lands after the docs.

0. **Art.** Done (data and art only, 3.0.54): the room, the doorstep, the lamp, docks, the pair pyramid holding through acts 2-3, the floor to col 15.
1. **Trial rework.** Done (3.0.53). Acts as batches: batch size by difficulty (TDifficultyValue), spawn the batch, gate = batch spent and no gravel alive, then the act number goes up and the next batch starts; kill counter for medkits; move the trial triggers off the medkits; remove the medkits; pickups out of the gate; right-exit and pit teleport for gravels; violet arrival (Game.Arrivals); medkit every 15 kills by teleport. Rules in Game.Trial, the game carries out its cue.
2. **Acts engine.** Built (3.0.54). Event condition "act N reached"; actions: shelf bank wake / sleep, program switch (hold, wave, alternate, blink), pad fly-in from above, medkits onto a bank. Acts 1-3 in level2.json. Aimed rain, herald, pit returns over the hero, crown medkits.
2a. **Trial tuning.** Done and committed (3.0.55). Pit returns as a queue (TrialPitReturnTicks 10, cue ReturnFromPit; TMonsterField.TryReturnPitStray, spread 2) - side returns stay at once (ReturnSideStrays); TMonster.HeadRandomly on every trial gravel let down or brought back. The medkit at the start of an act - dropped.
3. **TeK cannons.** Built (3.0.56), see "Stage 3 as built"; waits for its live run.
4. **Carousel act (3.0.57).** Designed, see "Stage 4 design". Three commits, a live run after the last:
   - 4.1 **Platforms' engine.** Built (2026-10-13), see "New engine pieces" under Shooting platforms; compiled and run by him, not by Claude. Game.Version is still 3.0.56 after it - nothing in the data uses the new pieces yet. Files: Game.Trial (TTrialProgress, Progress, ActEnded), Monsters.Defs (TLaneSide), Levels.Events (gravelDealt, spawn), Events.Director (two cues), Monsters (the lane phases, SpawnInLane, DepartGuests), Moon2D.dpr (the wiring).
   - 4.2 **Parked carousel.** `parked` on the carousel, `flyIn` by a carousel tag, the clock speed-up from zero, a rewind parks it again, RoomBusy for the fly-in.
   - 4.3 **Act 4 data.** The banks (the foot stays, the crown and the ladder sleep bottom-up, the one-through-one floor), the carousel and its pads with two medkit seats in level2.json, the act 4 events, the two platforms.
5. **Chaos act.** Carousel pads turn into falling pads; Pads.Stray (edge -> point -> point/edge, random misbehaviour from the existing plunge and path pieces); sky barrels with death-on-landing and a hero-only blast - the flag goes on the spawn, not on the bullet class (the henshin rings use Contact against the boss). Act 5. Big shells in place of the sky barrels are an idea (2026-10-13), to decide here.
6. **Finale.** Betoner wave after the act 5 gate; spawn on the top awake row; cap 3; the press (row wake/sleep on a timer); barrels continue. Check betoners fall when their shelf sleeps (affectedByGravity).
7. **Tests.** Black-box, one module per new entity: trial rules (batch by grade, per-act gate, no carry-over, teleport keeps the gravel, a wave every time while the batch lasts, medkit per 15 kills, pickups out of the gate, aimed every third from act 2, herald, aimed holds the gate - also the aimed one let down on the gate's tick, pit returns one per TrialPitReturnTicks, RoomBusy holds only the first wave), acts conditions, shelf commands (sleep / wake / program from any depth, told-before-origin look), bank orders and waits, parking and fly-in (the parked carousel, the clock speed-up, the re-park on a rewind), the batch-birth condition (thirds by grade) and the spawn action (lane, entrance, leave at the gate, the gate not held), cannons (TCannonPair with no renderer needs a TCannonArt - split the art off or pass nil; unison, one row per volley, rounds harmless to gravels, shield takes every hit, shield falls with the act change, the scene deals no damage, the yield bank sleeps before a ride through rows 8-9 and wakes after, contact wounds, a late event plays the scene at once), the shield (cells inside the ellipse, flare fades in 16 ticks, fall in 14), stray pad, sky barrel, press.
8. **Docs.** ASSETS (tek-cannon.mset, tools/cannon), both codebase maps (Game.Shield, Game.Cannons, the cannons action, RoomBusy), PADS-PLAN, PORTING-NOTES, the stage 4 units, docs/ARENA-2.md (the repository copy was refreshed to stage 3 on 2026-10-13; refresh it again from this plan); then the tag.

## Risks
- Five acts = five balances; acts 3 and 5 on wild (40 each) will be meat - tune the batch sizes by live runs.
- No cap: on wild up to 40 gravels can be alive at once. If it turns to mush, a cap for wild alone (about 25) - not for normal.
- The last gravel of an act stuck somewhere unreachable holds the act forever - a gravel cannot hide (it always walks, the right gap and the pit teleport it), but check live: a gravel riding a stray pad or stuck on a sleeping shelf's edge.
- The pause between acts must stay short - a long one is the calm zone we removed. The cannons' end scene (about 5 s) is the exception, taken on purpose.
- Pit returns over the hero: one every 10 ticks since 3.0.55 - a pit of ten takes 3 s to empty, and the act lasts that much longer. Watch live.
- The peak (row 5, four cells) is a support for the whole of act 3. If it can be sat out there, one blinking step - not the whole ladder.
- Stray pads and falling carousel pads meeting each other - keep their zones apart or let them pass through (pads do not collide).
- The hero in the right gap while the floor is out: gravels teleport at x > 480 - check live that they touch him before that.
- Cannons: the long burst holds a row closed - if it outlasts a jump down and a landing, the row becomes a grinder. Tune the burst length, the red fire (about 0.6 s) and the ride speed live.
- Cannons: a jump between two rows passes through the swept row in between - the best trap of the act, but check it is not a certain death on take-off.
- Cannons: the bottom steps sit right at the muzzle (when they are out) and so does the island next to a wall - they take the volley with no flight time; and a step yielding under the hero is a fall into the pit - check live that it is readable (the cannon riding toward it is the warning) - more dangerous than a centre island. Probably fine (the centre has the aimed rain), check live.
- Cannons: a debug browse (PgUp/PgDn) off the screen while s09-foot is asleep leaves it asleep - the door is closed during the trial, so only the debug path reaches it.
- Act 4: the pads ride out while the first gravels fall - a gravel landing on a pad still on its way in, or under the box while the ladder is still sleeping down. RoomBusy holds the first wave until the carousel stands; check live.
- Act 4: the lower platform on the floor lane, the one-through-one floor and the aimed rain together are thick. If too much, the lower platform comes later or the lane goes to row 9 (then the foot ledges, which stand on row 9, would have to go and the bottom run of the carousel would have to come down a row).
- Act 4: the crown and the ladder sleep bottom-up while the hero may be standing on them - a fall readable only if the order is clear; the step against the fly-in is a live-run matter.
- Act 4: the wreck of the lower platform (blast of 100 lives over 80 units) at floor height hurts the hero and the gravels around it - a point-blank kill costs him; that is the price of the kill.
- Act 4: a platform leaving flies up through the room (about 1.5 s from the lower lane) and is harmless and unshootable while it does; look at it live - if it reads wrong, it can fade instead.

## Open
- Hard and wild batch sizes: 25 / 40 proposed.
- Ice form on this screen: on or off.
- Where the hero stands at the moment an act floors out under him (act 3) - a grace of a second, or none.
- How many cannons by grade, if two turn out too soft or too hard.
- Act 4 floor: cols 4, 6, 8, 10 and 14 (cols 2 and 12 left out under the foot) - proposed, to be seen live.
- Platforms: counted by dealt, not by kills, and leaving at the gate - both defaults; by kills would need one more cue.
- A spawned platform wears no rig. The rig "tekPlatform" (two blue beacons, a haze and a smoke jet under the hull) is hung at level load on the entities and pads that name it, by tag; a body made by an event has no placement, so it flies naked. Decide at 4.3: fly naked, or let the spawn action carry a tag and let the level dress that tag without a placement (a small addition to Levels.Rigs), or place the two platforms in level2.json as parked entities with their rig and let the event let them in (a "parked" phase and a let-in action instead of the spawn).
- Medkits in act 4: the two on pads; whether the per-15-kills teleport also brings one in act 4 (no bank to land on) - default: no, the two replace it.
- Carousel size, pad count, period and speed-up time: first guesses, tuned live.
- Act 5: big shells in place of the sky barrels - an idea, to decide at stage 5.
