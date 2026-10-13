# Level 2 screen 9: the gravel arena (first of the two level 2 bosses)

Stage plan. Status: stage 1 done (3.0.53: trial in acts, arrival glow); stage 2 built (3.0.54: acts engine, acts 1-3); stage 0 done (the room, data and art only, 3.0.54; the first run found the waving ladder unclimbable, acts 2-3 relaid with a holding pair pyramid - "пойдёт", pushed); stage 2a done and committed (3.0.55: gravels face either way, pit returns one at a time). Stage 3 redesigned: the bait pads are dropped (nothing new, a medkit on a pad is grabbed and left in one jump) - stage 3 is now the TeK cannons with a partial floor and a thinner pyramid. The second level 2 boss - the mast-turret machine - comes on the screens after this one; this arena must not repeat it and must not repeat the level 1 pad arena.

## The idea in one line
Five arenas in one room: each act brings its own gravels (15 on normal, more on hard and wild); when the last of them is dead, the room rebuilds itself, and every rebuild takes away what the hero stood on. Selena does not throw gravels at the hero - she rearranges the room; the gravels are the weather.

## Rules of the room
- No support lives longer than one act - and that means the REBUILD takes it away, not that a shelf cycles every few seconds. Within an act the hero's steps stand still; what keeps him moving is the aimed rain, not a shaking ladder. (Learned the hard way: a waving ladder is five jumps in a 2.5 s window - nobody climbs it, and act 3 then corners the hero on the doorstep.)
- Gravels (gravelFemale) do not shoot and cannot climb - every permanent height would be a bunker. Hence no static platforms at all; the white blocks of 2008 are gone.
- No roofs: no shelf hangs over another shelf of the ladder. A step under a step is a bunker - random drops and the aimed rain land on the roof and walk off it sideways.
- Steps are two cells wide: a gravel is a cell wide and the aimed one lands on the hero's column, so a one-cell step leaves no sidestep.
- Walls left and right stay; the floor is shelves, as on screen 8 - the room has no painted floor, the back wall below the shelves is the shaft.
- The room art is the ChatGPT generation with the violet ceiling grating; the docks for the sleeping shelves are the shelf-dock of pads.mset behind every shelf, as on screen 8 - the whole room is a wall, so every dock is a wall nest.

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
- Nothing carries over: the next act starts with an empty room. The rebuild is the only breath the hero gets - a short beat (the violet flash, the latches), then the new batch starts falling.
- The finale opens when the last gravel of act 5 is dead.
- Death restarts the trial from act 1 - decided to keep it so for now (no per-act checkpoints).

## Medkits
- The three trial medkits of 2008 are removed. Their triggers (changeMusic, heroX, gravelBoss) live in "screenTriggers" of level2.json - triggers of a screen that no body carries.
- One medkit per 15 killed gravels on every grade (one per act on normal; more per act on hard and wild because their acts are longer), delivered by the same violet teleport; from act 2 on it lands on the top of something the hero has to climb to - the event action medkitsOnto names the bank (act 2: the peak of the pyramid, bank s09-crown).
- On normal the 15th kill is the end of the act, so the medkit comes at the act change. A medkit at the start of every act was offered and turned down - too generous; the medkits stay one per 15 kills.
- Bait pads (two falling pads at the top riding medkits) - dropped 2026-10-13: nothing new, and a medkit on a pad is taken and left in one jump.
- Pickups are excluded from the gate (AnyAliveOnScreen counts them now - an untaken medkit would hold an act forever).

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
- **The bottom steps yield.** Riding through rows 8-9 the cannon would sit on the bottom steps (row 9 cols 2-3 / 12-13: col 2 / col 13 is inside the gun). So when a cannon comes to rows 8-9, the step on its side slides into the wall (as `shelvesSleep`), and slides out again when the cannon rides away. Steps of the bank s09-ladder; cannons in unison, so both steps go and come together. A hero on the step falls. New code: the cannon commands the shelves (today shelves only listen to act events).
- **Fires from the muzzle**, not from the wall.
- **Touching a cannon wounds.** Its body cannot be a bunker: a hero standing inside the gun behind the muzzle (at the bottom row the left gun is over the doorstep, col 1 of row 11) is hurt by the contact. The contact box is the body and carriage, not the empty air over and under the barrels - taken from the art's alpha.
- **Respawn inside a cannon** - the mercy window of the respawn is the time to jump out of it.
- **Look.** Serious guns: TeK grey worn steel, yellow-black hazard stripes, twin ribbed barrels, a dark sensor lens (lit by the code with the red fire), no text or emblem (the right gun is mirrored). The art faces right (left wall) and is mirrored for the right wall.
- **Art.** Generated 2026-10-13 in ChatGPT from the TeK style sheet (`tek-style-reference.png`, made from tank-hull, mount-hull, platform-hull, medic and cordon sets) and the prompt of this plan; accepted. 1774x887, real alpha. To pack: set, contact box, muzzle points (two barrels), lens point.

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
4. **Carousel.** Pads fly in from above and form a box carousel in the centre (rehearsal of the square carousel wanted for the next level). Barrels on the pads. The ladder falls asleep from the bottom up, step by step - late means the pit. The barrels are blown up when the pit below is full of gravels.
5. **Chaos.** The carousel breaks: its pads become falling pads one after another. The floor comes back in random pieces. Shelves blink out of step.
   - Stray pads: ordinary pads fly in from beyond a random edge to a random point, hang, fly on to another point or out. They misbehave at random: fall like a falling pad, turn back halfway, twitch. Transport nobody can count on.
   - Barrels from the sky through the same violet teleport, exploding on impact with the floor, a shelf or a pad. The blast wounds only the hero - gravels walk through it. Not a weapon, the weather.
6. **Finale - betoners.** The floor stands, everything below sleeps. Only the top row of shelves under the ceiling wakes; 10 betoners teleport onto it, no more than 3 alive at once.
   - The press: every ~10 s the top row sleeps and the row below wakes - the betoners drop a row lower. In half a minute they are on the floor beside the hero, point-blank.
   - A killed betoner is replaced on the TOP row: a fast killer keeps them far, a slow one gets all ten at his feet.
   - Barrels keep falling through the finale: time itself hurts.
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
- s09-floor - 14 shelves, row 11 cols 2-15 (held out). Col 15 is a shelf too: a solid cell under the right gap was a bunker from act 3 (the aimed rain is clamped to col 14, falls into the pit and comes back there).
- s09-wall - row 9, cols 1 and 14 (act 1).
- s09-ladder - the pair pyramid: row 9 cols 2-3 and 12-13, row 7 cols 4-5 and 10-11. s09-crown - the peak, row 5 cols 6-9. Every hop is a rise of 2 with no gap (JumpReach(2) = 2). No roofs.
- Events: act 1 - wall alternate (out 2.5, in 1.5, warn 1.2); act 2 - wall sleeps, ladder wakes and holds (order up, step 0.2), crown wakes and holds (order left, step 0.2), medkits onto the crown; act 3 - floor sleeps toward the hero (step 0.35), nothing else moves.
- Acts 4 and 5 run in the room act 3 left (floor gone, pyramid holding) until their stages.

## Stages
Each stage ends with a live run. Versions: one per stage that changes mechanics, next free after 3.0.55; the tag lands after the docs.

0. **Art.** Done (data and art only, 3.0.54): the room, the doorstep, the lamp, docks, the pair pyramid holding through acts 2-3, the floor to col 15.
1. **Trial rework.** Done (3.0.53). Acts as batches: batch size by difficulty (TDifficultyValue), spawn the batch, gate = batch spent and no gravel alive, then the act number goes up and the next batch starts; kill counter for medkits; move the trial triggers off the medkits; remove the medkits; pickups out of the gate; right-exit and pit teleport for gravels; violet arrival (Game.Arrivals); medkit every 15 kills by teleport. Rules in Game.Trial, the game carries out its cue.
2. **Acts engine.** Built (3.0.54). Event condition "act N reached"; actions: shelf bank wake / sleep, program switch (hold, wave, alternate, blink), pad fly-in from above, medkits onto a bank. Acts 1-3 in level2.json. Aimed rain, herald, pit returns over the hero, crown medkits.
2a. **Trial tuning.** Done and committed (3.0.55). Pit returns as a queue (TrialPitReturnTicks 10, cue ReturnFromPit; TMonsterField.TryReturnPitStray, spread 2) - side returns stay at once (ReturnSideStrays); TMonster.HeadRandomly on every trial gravel let down or brought back. The medkit at the start of an act - dropped.
3. **TeK cannons.** (Was "bait pads" - dropped.) The two wall cannons (see TeK cannons above): slide-in from the edges, unison ride on the walls over every row, red fire + padhum before the volley, a long burst sweeping one row, harmless to gravels; the TeK shield (pale honeycomb, flare on a hit, no sparks) as a shared piece for later bosses; the scripted end (shield falls on the last gravel, overheat race, face to face over the pyramid, burst, a joint blast with shake, no damage). Data: the partial floor in islands (not in the corners), a couple of pyramid shelves fewer - both approved. Act 3. Cannons 2x1 cells on the side face of the pillars (cols 1-2 / 13-14, muzzle two cells out), the bottom steps yield to them (cannon -> shelf link, new code), contact wounds, respawn mercy to jump out. Cannon art from ChatGPT (2:1). Version: next free.
4. **Carousel act.** Box carousel built by fly-in, barrels on its pads, ladder sleeping bottom-up. Act 4.
5. **Chaos act.** Carousel pads turn into falling pads; Pads.Stray (edge -> point -> point/edge, random misbehaviour from the existing plunge and path pieces); sky barrels with death-on-landing and a hero-only blast - the flag goes on the spawn, not on the bullet class (the henshin rings use Contact against the boss). Act 5.
6. **Finale.** Betoner wave after the act 5 gate; spawn on the top awake row; cap 3; the press (row wake/sleep on a timer); barrels continue. Check betoners fall when their shelf sleeps (affectedByGravity).
7. **Tests.** Black-box, one module per new entity: trial rules (batch by grade, per-act gate, no carry-over, teleport keeps the gravel, a wave every time while the batch lasts, medkit per 15 kills, pickups out of the gate, aimed every third from act 2, herald, aimed holds the gate, pit returns one per TrialPitReturnTicks), acts conditions, shelf commands (sleep / wake / program from any depth, told-before-origin look), bank orders and waits, parking and fly-in, cannons (unison, one row per volley, volley harmless to gravels, shield takes every hit, shield falls with the act's last gravel, the scene deals no damage, the bottom step sleeps while its cannon is at rows 8-9 and wakes when it leaves, contact wounds), stray pad, sky barrel, press.
8. **Docs.** ASSETS, both codebase maps, PADS-PLAN, PORTING-NOTES, docs/ARENA-2.md (the repository copy is behind since stage 2); then the tag.

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

## Open
- Hard and wild batch sizes: 25 / 40 proposed.
- Ice form on this screen: on or off.
- Where the hero stands at the moment an act floors out under him (act 3) - a grace of a second, or none.
- How many cannons by grade, if two turn out too soft or too hard.
