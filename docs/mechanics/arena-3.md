# Level 2 finale: the tunnels and the TeK machine (second of the two level 2 bosses, end of 3.0)

Status: designed (2026-10-17), the boss fight reworked around a chase (2026-10-19); stage 1 built (2026-10-19, 3.0.63); the tunnels made giant with a living backdrop, the chase on a tiled floor under a still backdrop (2026-10-20); stage 2 built (2026-10-20, data, no version): screen 10 stands on a layered tunnel; stage 3 built (2026-10-20, 3.0.64): the Duplet; stage 4 built (2026-10-21, 3.0.65): the dust of screen 10; screen 11 designed (2026-10-21): the stone that wakes and builds its own way, closed doors as a common mechanic, the fang kit; stage 5a built (2026-10-21, 3.0.66): closed doors; stages 5b and 5c built (2026-10-21, data, no version): the art and the data of screen 11; stage 5d built (2026-10-21, 3.0.67): the stone wakes; stage 5e built (2026-10-21, 3.0.69): the rocks fall back; the fall retuned as a free fall, the music left alone in it and the checkpoint moved to the stone (2026-10-22, 3.0.71); screen 12 designed and its art made (2026-10-23): the far ledge with convoys and a searchlight, the sphere of 200%, two lines of the shuttle. Many small stages, each its own commit and live run. The screen numbers 10-13 are a guess (arena 2 is screen 9) - shift them if the layout differs.

## The idea in one line
A false ending: arena 2 is won, the victory track plays, the player thinks the level is over - and the arrow points right. Tunnels of lunar rock, a giant double-barrel, the moon stone, an energy gauge at 5%, and a TeK machine that cannot be hurt until the hero becomes the moon form - and that runs away from him in the middle of the fight.

## Rules of the finale
- No monsters on the tunnel screens. The emptiness is the threat.
- The boss fights alone - no other enemies help it. The napalm and the drifting pads of the chase are the machine and the room, not helpers.
- Death in the boss fight restarts the fight from its start (the boss screen), not from the tunnels. The battles are short - no checkpoints inside.
- The floor of the boss arena is flat.
- The boss screen is closed on both sides: a wall on the left, no way on to the right - it is the last screen of the level.
- TeK armour = the shared TeK shield of arena 2 (Game.Shield: the pale gold honeycomb, flare on a hit, no sparks). The player has learned it on the cannons: honeycomb means "do not waste bullets". The ricochet of the 2026-10-08 idea is dropped - one sign of invulnerability, not two.
- TeK fire is napalm: sticky orange and black, it burns where it lands. The fire rain and the orbs are the hero's friends and never come from TeK.

## Screens
### The false ending (screen 9, after the trial)
- win.ogg plays to its end; the anxious retro ambient, lunar.ogg ("Lunar Silence", made in Suno, 3 minutes - for the three tunnel screens before the boss), fades in under its last seconds; at its very end the go-right arrow. (The chewed-tape slowdown was turned down - cannot be done.) As built - see "Stage 1 as built".

### Screen 10 - the double-barrel
- A room of lunar rock, the double-barrel on a pedestal, as the super shotgun in Doom 2. No monsters.
- **The gun is big against the hero, not monstrous** (decided 2026-10-17, size settled 2026-10-20). Reason: no close combat with small monsters ahead, and a big boss is hit for sure. A short-range wide spread is exactly the weapon for a 2x2 target. On the pedestal it is 42 units long (three cells and then two were too much); in the hands about twice an ordinary weapon.
- **The door is shut until the gun is taken** (see "Closed doors"): taking it opens the door, and the arrow says so.
- The look: a modern, utilitarian combat double-barrel of a lunar expedition - black polymer and gunmetal, a perforated shroud over the barrels, no wood, no glow, nothing of TeK (the honeycomb is the enemy's language).

### The tunnels are giant
The hero walks along a ledge in a tunnel far bigger than the screen: the backdrop is far away - the opposite wall, the vault, the depth of the tunnel going off into the dark. The playfield (floor, ledges, the pedestal) is near and small against it. Scale is the point: a small hero in a huge empty place.

How the picture says it (learned on screen 10):
- no near ceiling and no near wings: the top of the frame is black, the vault too high to be seen; the far wall rises out of the bottom edge and fades into the dark at the top, its foot never shown - the hero stands high over the floor of the tube;
- the light has a story: sunlight through a small hole high in the vault falls on the floor of the tube far below, and the lit floor lights the wall from below, warm; in a vacuum the shadows are black and nothing glows in the air;
- balance, not symmetry: the light and the interest on one side, the near matter (the TeK casing) on the other;
- even flat light and an even rhythm make wallpaper, not a place.

### The living backdrop (tunnel screens 10-12) - a new mechanic
It is the backdrop itself that lives, not effects laid over the playfield. The screens do not scroll and the backdrop never moves as a whole - no parallax anywhere, the boss arena included.

**Layers for occlusion, not for motion.** The backdrop is two or three still layers - the far wall, the arches or pillars in front of it, the haze between. A layer is a stage wing: something alive can pass behind it. The art is cut into layers at generation time (a prompt per layer), not after; each layer within 2048 px (old cards).

**One event per screen, growing toward the boss** (decided 2026-10-20) - silence, one blow, then a busy world:
- **Screen 10 (the double-barrel) - haze only.** Long bands of levitating dust hanging in the depth, drifting very slowly, lit where a shaft of light crosses them (no wind on the Moon: the dust is charged and hovers - it drifts, it does not billow). Nothing else moves: the first screen after the false ending says "you are tiny and it is empty".
- **Screen 11 (the moon stone) - the stone wakes.** The event of this screen is the stone itself (decided 2026-10-21, in place of the distant rockfall): the dust of the screen stops dead and settles a little when the stone wakes - the stone stops even the air - and the rocks it raises are the motion. See "Screen 11".
- **Screen 12 (the sphere, the shuttle) - the far ledge is busy.** Tiny lights of TeK convoys crawl right along a far ledge, hiding behind the pillars; a searchlight from the city gate at the far end of the tunnel sweeps the far wall (a light texture with additive blend). The shuttle says the entrance is guarded - the backdrop shows it.

**Dropped** (2026-10-20): pulsing veins in the rock (glowing things are the hero's language - orbs, the stone); sunlight crawling through cracks (a lunar day is two weeks long, and the tunnels are dark); the near-plane dust specks, sand streams and periodic tremors of the first proposal (noise next to a living backdrop).

### Closed doors (decided 2026-10-21)
A common mechanic, not a feature of the tunnels: a screen whose way on is shut until something happens on it. The train level will use it too (no way on while a monster lives).
- **Shut** is a list of the level (`"shutDoors": [9, 10, 11]`). The door is invisible, as the 2008 breakthrough: the hero stops at the threshold, as at the door of the trial.
- **Open** is an action of the events (`openDoor`), and it raises the go-right arrow itself: open = the arrow, one action, never two. No sound, as the arrow of stage 1.
- **What opens it** is any condition of the events. A pickup taken is dead to the field, so `allDead` on the pickup's tag is the taking (the Duplet, the moon stone) - no word of its own was needed; `allDead` on the monsters is the train; `trialDone` is there too.
- A restart shuts the door again if the thing is not done (a pickup not taken comes back with the screen).

### Screen 11 - jumping and the moon stone
The stone builds its own way to the hero - and takes it back once it is in his hands. Seen as a sketch (2026-10-21) and accepted.

**The backdrop is screen 10's far wall, slid left** (decided 2026-10-21). A screen to the right, the far wall moves a third of a screen: the hole of the vault and its shaft now stand at the left (about x 160). The scale is sold by the step between two screens, with no parallax at run time. The new right third (outpainted in ChatGPT from the shifted wall; the original pixels kept on the left, the seam blended over 120 px) is darker and turns from basalt columns to horizontal strata - the way to screen 13 begins here. 1440x1080, as screen 10. The dust of screen 10 again, its shaft moved with the hole.

**The grid** (16x12, rows from the top, cells counted from 0):
- the way in: the ledge of screen 10 going on, cols 0-2 on row 11 (floor line 352) - cut out of `s10-room`, so the ledge runs on through the door with no seam;
- column A, cols 4-5, top on row 10; column B, col 7, top on row 8; column C, cols 12-13, top on row 6 - the stone on it; the way out, cols 14-15 on row 11, right against C, cut out of `s10-room` too; the right edge open from row 0 to 10;
- the columns are columnar basalt, as the pedestal of screen 10, rising out of the dark of the pit; a fall into the pit is the 2008 pit (a life, back to the respawn point at cell 2, 11);
- by the hero's own arc, not the table of `JumpReach`: in to A a gap of one up 1, A to B a gap of one up 2, C to the way out a step off its edge, a drop of 5 with no gap - all pass. No gap at the way out on purpose: once the stone is taken the rocks are gone, and a hero dropped into the pit there would come back at the way in with no way up to C and the door - a softlock. B to C is four cells (128 units) up 2, out of reach - the stone cannot be reached without the rocks. Nothing goes round C: it is a wall;
- **`JumpReach` is the safe reach, not the longest** (found on the first live run, 2026-10-21): it keeps the hero's middle a Bound inside both decks, so a gap it calls out of reach may be crossed from the very edge. The arc itself carries the middle 120 units up 0-1 rows, 102 up 2 and 72 up 3 (peak 100 units over the start). C stood three cells (96 units) from B and was jumped without the step; a gap that must not be crossed is checked against the arc.
- the stone stands high and in the dark at the right, away from the shaft: the black glow reads where there is no light.

**The stone wakes** (on the hero landing on B - a new condition, the hero on a cell):
1. half a second of nothing - no sound, the dust stops dead and settles a little;
2. the stone wakes: its rim brightens, the dark thickens round it (SDL_BLENDMODE_MOD), and a ring of darkness runs out over the room - seen where it crosses the lit wall;
3. grit rises out of the pit first - the warning;
4. the rocks rise out of the pit, each at its own delay and pace, to its own height: an ease-out with a slight overshoot, the tilt dying away, grit falling off their undersides. One rock is the step: it stops with its top on row 8 between B and C, 34 units from each (B to it at one level, it to C up 2). The others are decoration at different depths, slowly bobbing; one or two big blocks deep behind, so the rocks do not read as rubble against the giant tunnel. The step does not bob;
5. a low hum grows under it all; the crack of stone as the rocks come free.

The rocks are pads (Levels.Pads): a path from under the bottom edge to their place, one stop, no way back; the ease is the one new thing in their motion. Steps 1.5-2 cells across.

**The stone is taken:**
- the rocks lose their strength and fall back into the pit - the step too: there is no way back; the dust comes back to life;
- the energy gauge at 5% (stage 6);
- the door opens and the arrow comes (`allDead` on the stone's tag -> `openDoor`);
- the checkpoint of the screen moves to the stone's column (`respawn` in the same event): a hero who jumps back into the pit after the rocks have fallen comes back by the stone, not at the way in with no way up.
- **In reserve** (decided 2026-10-21): the eclipse - on taking, the stone drinks the light: the shaft of the vault goes out, the dust sinks into the dark, the backdrop goes black but for the rim of the stone and the gauge. The same tools as the waking at full strength; kept for the finale if the taking needs more.

**Dropped** (2026-10-21): the force field over the way out (a TeK field on natural rock is out of place - the closed door is invisible); the distant rockfall (the stone is the event); a fang shot down by the Duplet into a bridge, and a fang broken by a falling rock (a believable fall needs drawn animation; rigid motion, light and sound are what this game does well).

### The fangs (decided 2026-10-21)
The basalt spurs of `s10-depth` - the "fangs" - are kept and multiplied:
- a kit: one ChatGPT sheet of four or five fangs of different heights and outlines on black, cut by script into separate sprites, each within 2048 px (old cards); neutral rim light, tinted per screen;
- screen 11: two or three fangs at the depth of `s10-depth`, the rocks rise in front of them;
- the chase (stage 11): the fangs ride through from right to left at random, the "posts by the road" that sell the speed. A fang is a separate sprite, nothing to loop. Their speed is tuned live: slower than the floor (they stand deeper - discrete objects need no seamless backdrop) or with it.

### Screen 12 - the far ledge and the sphere (designed 2026-10-23)
A pause before the fight: flat floor, nothing to jump, the shuttle speaks, the far ledge comes alive, and the way on opens only with the sphere. The bumps of the first plan are dropped - a flat screen lets the player look at the tunnel while the shuttle talks.

**The backdrop is screen 11's far wall, slid left again** - the same step of a third (480 px of 1440), the new right third outpainted in ChatGPT: horizontal strata only, the warm light of the vault dies on the left, and at the right edge, at the far end of the tunnel, a small lit gate building on a natural stratum - the brightest point at (472, 217). The word "city" is not said on this level: the gate is "the end of the tunnel", what lies behind it is the next level's first frame. `level2-backdrops.mset`: `screen12`, 1440x1080 (the generation came 1448x1086 and was scaled).

**The far ledge** - one object, `s12-far-ledge`, a thin level shelf the full width of the backdrop, its top on 217 (611 px), running into the base of the gate. The convoys ride on it. The same sprite, at the same y, stands on screens 10 and 11 at x -341 and -171 (the step of a third): the walls are one wall, so the ledge was always there - empty on 10 and 11, alive on 12.

**The pillars** - a kit of four, one generation each from a silhouette, neutral light, tinted per place: `s12-pillar-needle` (A, 43 units tall), `-twin` (C, 38), `-block` (B, 30), `-stump` (D, 23), feet on the ledge. Screen 12 has five: needle at 50, twin at 153, block at 256, stump at 331, the needle mirrored at 395 - each about 20% darker than the wall behind it, so it reads as a silhouette; at the gate end they all but vanish until a convoy light goes out behind them or the searchlight passes. They are what the convoy lights hide behind.

**The convoys** (code, `Beacon` lights in a row): columns of 3-5 lights - a warm headlight in front, a red tail light at the back, an orange flasher now and then - crawling right along the ledge at 8 units a second, two lanes a little apart, the second 20% slower. Drawn under the pillars, over the wall. A column that reaches the gate fades out there. **The start:** on 10 and 11 the ledge is empty; on 12 the first column comes in from the left alone, on the shuttle's first line; then the gap between columns narrows from half the ledge to dense traffic over 45 seconds; the second lane joins from the second column. The clock starts when the hero comes onto the screen, and a death restarts it.

**The searchlight** (code, a new dynamic): a cone of light out of the gate (additive, over `gsBeam` like the go-right arrow) and a spot on the far wall that walks a figure of eight over the left two thirds of the wall in 11 seconds; a pillar under the spot lights up. It lights with the shuttle's first line. It never touches the playfield.

**The playfield:** row 11 is the floor, the floor line 352, flat from wall to wall; the rest is air. Cols 0-9 - lava crust (`s12-crust`, one object, joins `s11-way-out` with no seam, its broken lip 8 units over col 10); cols 10-15 - the made road of TeK: one square tile, `s12-road-tile`, 32 by 32 units, a self-contained plate with a frame on all four sides and a hazard stripe under its rim, repeated six times - a brick, not a seamless strip. The same tile is the floor of the boss arena. The respawn point at cell 1, 11. `"shutDoors": [12]`, the door opens with the sphere.

**The order of events:**
1. The hero comes onto the screen. Half a second later the shuttle's first line; on the same beat the first convoy comes in from the left and the searchlight lights.
2. The second line; the energy gauge blinks.
3. When the second line is typed out the sphere forms.
4. The sphere is taken - health to 10, the door opens, the go-right arrow lights.

**The shuttle** - two lines, header ЧЕЛНОК: "Мастер! В конце тоннеля что-то большое." and "Лёд не ответит. Бей и следи за зарядом камня." - the threat without a name (the machine is the answer to "something"), why henshin does nothing, and that the fight is what charges the gauge (not "hold out": the charge comes from hitting the turrets). The moon form is not named before it happens. The line "the stone fits the suit" of screen 11 is covered by the second line.

**The sphere** (`TLifeSphere`, drawn in code, no art) - the soulsphere of Doom: 200%, health to 10, the five past the divider green. 16 units across by default. A green body (a light spot upper left, dark at the rim) in a soft green halo, breathing (8%), three bands of light running round it inside, two sparks orbiting, a slow sway up and down. **Forming:** about 26 green sparks spiral in from 40-100 units over 1.6 seconds, the sphere grows out of them and flashes. **Taken:** it bursts, the sparks fly into the hero along curves, a flash on him, the pips fill to 10 (the green ones past the divider). The green is the HUD's bonus green. Not an orb: orbs are the hero's projectiles, the sphere is a pickup.

### Screen 13 - the boss arena
The end of the tunnels and the way out to the city. The backdrop of screen 10 would not do for the chase: its basalt columns are verticals, and a vertical that does not ride past while the floor slides shows the belt for a treadmill. This one: horizontal strata only, no columns, cracks or stalactites running up and down; finer texture and lower contrast, farther than on screen 10; no bright spot in the middle - the light is a distant glow of the city along the horizon at the end of the tunnel. Screens 10-12 lead to it: each a little farther and more horizontal than the one before. Flat tiled floor - a made road, the machine drives on it - closed on both sides. The backdrop is still: no events of its own (the foreground is full - napalm, pads, turrets) and no motion in the chase (see "The belt"). Three acts in three tempos: the machine standing its ground (turrets 1 and 2), the chase (turret 3), then the evolution and the air phase on a still screen again.

## The boss: TeK machine
- A big heavy TeK vehicle on two wheels, 2x2 cells, under the TeK shield - the double-barrel does not get through it. Drawn as a hull (Monsters.Hull: layers, wheels turned by how far the body has rolled).
- Only the turrets can be hit. They come out on top on a mast (up to three cells high, swaying - the 2026-10-08 idea). Kill one, the next comes out and shoots differently.
- Three turrets. A fourth only if the chase proves too short live (see Open).

### Act 1 - standing ground (turrets 1 and 2)
- The machine drives back and forth across the arena, stops, shoots, drives again, and crushes the hero it drives into (decided 2026-10-08).
- Turret 1: aimed bursts at the hero - teaches to move.
- Turret 2: a long horizontal sweep, as the arena 2 cannons, with the red warning at the muzzle first - teaches to jump.

### Act 2 - the chase (turret 3)
Turret 2 dies: turret 3 comes out, a napalm launcher opens on the stern, and the machine drives off to the right. It does not leave the screen - the screen moves under it.

**The belt.** The screen becomes a treadmill the hero does not steer:
- the floor slides left; the machine stays on the right part of the screen, its wheels turning;
- the backdrop stands still (decided 2026-10-20): a seamless backdrop is not going to be made, and it does not have to be - the far wall of a giant tunnel would barely move anyway, as distant mountains from a car window. The speed is shown by the floor, the things of the world riding it and the wheels;
- everything that belongs to the world - the hero, the napalm puddles, the pads, the medkits - is carried left at the belt's speed, in the air as on the floor (otherwise a jump would be a free way to stand still);
- an idle hero drifts back to the left wall, so the hero has to run to keep up. The machine is slow, the hero is faster: running, he gains on the belt at about the belt's own speed;
- the collision grid does not move: the floor is flat and the same along its length, so only the picture slides. The floor is a row of tiles - a classic square sprite, so sliding it is a tile offset that wraps, nothing to stitch;
- the fangs ride through from right to left at random - separate sprites, nothing to loop - "posts by the road" that sell the speed (decided 2026-10-21, see "The fangs");
- the belt comes up to speed from a standstill and runs down to one at the end - no jerk either way.

**The napalm launcher - why the hero runs.** An unkillable launcher on the machine's stern (part of the armoured hull: hits on it flare the honeycomb):
- fires almost straight up; the shell climbs off the top of the screen;
- it falls straight down behind the hero: it is aimed at where the hero was about a second ago - a running hero leaves it behind, a standing one gets it on his head;
- the shells land in the fire zone only - from the left wall to the fire's edge. The edge is unstable: it breathes, and now and then lurches a couple of cells toward the middle for a few seconds, narrowing the room. More often as turret 3 loses lives;
- every shell leaves a burning puddle that lives a few seconds and rides the belt to the wall. The wall of fire at the left is not an effect of its own - it is the puddles piling up there.
- The look, in four beats: the launch (a flash at the stern, a thick orange tracer with a smoke trail climbing out of sight, a dull thump); the wait (about 0.7 s: a shimmer or a red flicker on the floor where it will land, a whistle growing from above - the warning); the drop (a blob of napalm with a ragged dripping trail); the splash (tongues of fire to the sides, then the puddle, a loop of a few frames).
- Contact with the falling drop or a puddle wounds the hero.

**Turret 3 - hit from above only.** Shielded on its sides and front by the honeycomb, open on top: a hatch. The hero aims with the mouse in any direction, so from a pad above the machine he shoots down into the hatch. From the floor every shot meets the shield. Its own fire is worked out at its stage; first guess - low bursts back along the floor, so the floor is no shelter and the pads are the way.

**The drifting pads.** Pads on the upper layer, standing still in the world, so on the screen they drift left with the floor:
- a pad carries whoever stands on it toward the fire, as the floor does: a pad is not a rest but a stepping stone - cross it to the next one;
- a ladder of heights: low pads reachable from the floor with the plain jump, higher ones, and the height of the hatch;
- the pattern is random (decided), but a stretch that leads up to the hatch comes at least every few seconds, so the player is never left with nothing to climb.

**Medkits on the upper layer.** A medkit rides the upper layer with the pads and drifts past: climbed up and took it - good; did not - it is gone off the left edge.

**The brake lurch.** Now and then the machine brakes hard and rolls back about a cell. The warning: its brake lights flash red for about half a second. Whoever clings to its rear is crushed (decided 2026-10-19). With the fire behind, jumping clear of the bumper may land in the napalm - check live that it is not too much.

### End of the chase
Turret 3 dies: the launcher folds into the hull, the belt runs down to a standstill, the machine stops. The energy reaches 100% - the evolution. The rest of the fight is on a still screen.

## Energy (the form charge)
How it looks and where it stands - "Stage 6 as built".

The charge is tied to the lives of the three turrets, but with a delay, so the dependence is not obvious:
- **Hidden tank.** Damage to a turret goes into a tank, not into the gauge. The gauge drinks from the tank at its own pace - it keeps growing a couple of seconds after the hit.
- **Trickle.** The stone charges by itself, about 0.5% a second - the gauge lives even with no hits.
- **Ceiling.** While the third turret lives, the gauge stops at 95%. 100% comes only with the death of the last turret; the evolution follows at once.

```pascal
// turret damage - into the tank, not the gauge
Pool := Pool + Damage * K;

// every tick: the gauge drinks from the tank
Take := Min(Pool, DrainPerSec * Dt);
Pool := Pool - Take;
Energy := Min(Energy + Take + TricklePerSec * Dt, CapBeforeLast);

// third turret dies
CapBeforeLast := 100;  // the gauge runs to 100 -> Evolution
```

K is tuned so the turrets bring about 90-95% and the trickle the rest - a slow player never sticks at 94%.

## Evolution and the moon form
- Evolution: black orbs fly to the hero - the henshin rite (docs/mechanics/henshin.md) with black orbs and a third pattern, "eclipse": a black ring closing in (snowflake for arena 1, vortex for the gravels, eclipse here). Healing as the rite heals.
- The moon form: an orb gun - black orbs that pierce the TeK armour; jump +25%, as the ice form; the fire rain and the protective aura, both of black orbs.
- The look of the moon form comes in the next version; in 3.0 it looks like the ice form. It must be felt through the weapon: the orb gun fires slower but heavier, with visible recoil and sound - a sledgehammer after a pistol.
- Death after the evolution: the fight restarts from its start (as every death here).

## Air phase
- No turrets left: the machine takes off, nozzles in place of wheels (the 2026-10-08 idea).
- Drops grenades on the hero and shoots its guns.
- The hero shoots the machine itself - the orbs pierce the armour.

## The end
- The blast. The form comes off (black orbs into the aura ring, as the ice form). No victory track (decided 2026-10-22: win.ogg already lied once, at the end of arena 2); the boss track falls silent, and the titles close the level - and version 3.0 with it. See docs/mechanics/finale.md.

## Stage 1 as built (3.0.63)
All of it is data on screen 9 plus a few words of the event vocabulary; no code knows the false ending.

- **The victory track of the trial is a sound, not music** (TSoundBank.PlayTrackHeld: win.ogg decoded whole at startup, played on a sound channel and held). The music channel is free, so the next track fades in over the end of the victory with no conflict. The trial's own track stops at the victory. The game counts down what is left of it (from the decoded length, TSoundBank.SecondsOf); the menu pauses the track and the count with it, a restart and a new level stop it. The victory at the boss of level 1 is still music - it ends the level.
- **Condition `victoryEnds`** (ecVictoryEnds), JSON "lead" in seconds (0 by default): holds once the victory track has "lead" seconds left or fewer, and after its end. A missing win.ogg is a track of 0 seconds - the events fire at once.
- **`music` takes "fade"** (seconds, 0 by default): the track comes in from silence (Mix_FadeInMusic).
- **Action `goRight`** (eaGoRight): the go-right arrow (Hud.GoRight) in the middle of the screen - a hollow arrow of neon tube, three strips of the band glow along its outline (halo, tube, white core), mitered at the corners, so it is sharp at any window size. Four slow blinks, 60 ticks each, every one a raised cosine from dark to full and back, then it is gone - about seven seconds. No sound: the arrow is big enough to be seen (a beep and a slide on each flash were tried and dropped). It also goes out when the hero leaves the screen, on a restart and with the level. The beat (TGoRightBeat) is apart from the picture. Reusable: any event can raise it.
- **The events**: s09-tunnel-music (`victoryEnds`, lead 5: lunar.ogg with fade 5 - remembered as the track a restart plays) and s09-go-on (`victoryEnds` at the very end: `openDoor`). Screen 9 is a shut door too: the trial over, the hero still waits at the threshold until the victory track ends and the arrow lights - the way on opens with the arrow, never before it.
- **The door is still a wall**: screen 9 is the last screen of level 2 until stage 2 adds screen 10. The arrow points at a closed door until then.
- lunar.ogg is put in `bin/music/` by hand; without it the screen stays silent and the arrow shows anyway.

## Stage 2 as built (data, no version)
Screen 10 of level 2 is all data: `bin/level2.json` and the two level sets. The art is five ChatGPT generations; what was done to each is in its description in the set.

- **The grid** (16x12, rows from the top): col 0 rows 0-9 the TeK casing; row 10 the slot out of screen 9 (open at col 0), under the casing column of screen 9's right edge; row 11 the ledge, floor line 352 as the shelves of screen 9, broken at cols 4-5 (two cells, jumped at one level), its left lip drawn 8 units into col 4 and held by a pad with no picture (`s10-pit-lip`, 128, deck on 352, 8 wide, lets bullets by), so the hero walks to the drawn edge before he falls; the pedestal - a step at (8, 10), the top at row 9 cols 9-11, a step at (12, 10); the right edge open from row 0 to 10.
- **The layers, back to front:** `backgrounds` from screen 10, `screen10` (the far wall, 1440x1080, tint 75/75/80); `s10-depth` (two basalt spurs in the middle distance, tint 60/60/64, the space over the pedestal kept clear); `s10-pedestal` (columnar basalt, re-cut onto its matter: 160 units wide at 256, 287 - the steps 32 units each, the middle 96, its top on 288 and the steps on 320; set into the ledge so the ledge drawn over it hides the joint); `s10-room` (the ledge of solidified lava crust, the slot with a steel sill flush with the floor, the violet bar); `s10-casing` (the concrete casing cut out of the room's own pixels, tint 45/38/33, so it sits with the rock).
- No 4K yet: the room is at backdrop density; a 4K room comes as four objects of 256 units once it is upscaled outside the session.
- **The gun:** a placeholder until stage 3 - the 2008 `weaponShotgun` at cell 11, 9 (feet on 288, the top of the pedestal). Its picture waits for stage 3 at 42 units, 6 px a unit.
- **The respawn point:** cell 2, 11 (as every placement here, counted from 1).
- **The door from screen 9** needed no code: with a tenth screen the right door of screen 9 leads on, closed while the trial runs. The ending titles moved with it: the right edge of screen 10 is now the last door of the campaign until screen 11 comes.
- `lunar.ogg` plays on from screen 9; a restart on screen 10 plays it too.
- **The End debug key** goes straight to this screen from anywhere, with the music a walk there would have brought (`DebugJumpToWork`, `TrackBefore`). Move its screen number on with the work.
- Nothing moved on the screen at this stage; the haze came with stage 4. No lamp-and-beacon of REPAINT here - on screen 10 only the dust moves.

## Stage 3 as built (3.0.64)
The look and the shot went in together, as one commit: 3a and 3b were one reason - the new gun.

- **The name: the Duplet** ("Дуплет", en "Double Tap") - a hunter's word for a shot from both barrels at once: the name says what the gun does. Pickup `weaponDuplet` in `bin/monsters.json`, weapon type 5 (`DupletWeapon` in Hero.pas; 0..4 are the 2008 guns).
- **The art:** `bin/sprites/duplet.mset`, made by `tools/duplet/build_duplet.py` from one generation (the source is not kept): `lying` - the pickup, 42 x 12 units at 6 px a unit, the gun 11.2 units tall on the bottom edge (so it sits on the stone, drawn a unit under the matter); `held` - the gun in the hands, 32 units long (twice a 2008 gun) in a square of 48, the grip in the fist of the 2008 arm frame, so the gun sticks out ahead of the hero (decided: the shot leaves far from him - his target is a big TeK machine); `gone` - a clear frame.
- **A picture wider than its cell:** `"picture": {"width", "height"}` in a monster's def (`TPictureDef`). `TMonster.PictureBox` - the frame's box: the cell, or the picture standing on the feet line, centered on the cell. The monster draws its frame there, and the uptake takes its corner, its size, its silhouette and its halo from it (`TUptakePainter.PictureOf` takes the monster now). The pickup's hit box and its contact stay the cell.
- **In the hands:** `TSpriteRenderer.DrawRotated` takes the square's side (the 2008 32 by default); the held frame is dense art in a cache of its own (no color key, linear filter).
- **The shot:** 12 pellets, six out of each barrel (bores 2 units apart across the shot), born at the muzzle, 32 units ahead of the hand and 2 over its line, each barrel's shot from a square 6 units across, all at the aim angle - the shotgun's pattern, doubled. Cooldown 34 ticks against the shotgun's 20, speed 8, gravity 1: 2.4 times the shotgun a shot, 1.7 times slower; 1.4 times the shotgun a second.
- **Red shot:** `TBulletLook` (blPlain, blRed) on a bullet; a red one tints the shared texture for its own draw (100/28/22 percent) and puts it back - the flight and the burst frames alike.
- **The recoil:** 6 units along X against the shot (the cosine of the aim: a shot straight down barely moves him), paid in halves a tick at a time through `ShoveX` - a wall stops it, a deck's edge drops him. Kill and Revive drop what is left. Plus a light shake, trauma 0.2 a shot.
- **The sound:** `bin/sounds/duplet.wav` by `tools/sounds/duplet.py` - the 2008 shotgun slowed to 0.8, fired twice 14 ms apart, over a thump sliding from 110 to 42 Hz, soft-clipped; 0.75 s.
- First guesses for the live run: the muzzle reach, the recoil, the trauma, how red the shot reads.

## Stage 4 as built (3.0.65)
A new kind of the dynamics, `dust` (`TDust` in Levels.Dynamics), and one field of it on screen 10. No render code changed: the kind lives on the `sky` layer by default, drawn after the backdrop and before the static objects, so the spurs of `s10-depth`, the pedestal and the room stand in front of the dust by the order the game already draws in. The layer stands still while the world shakes, as the far wall does.

- **Seen only where it is lit.** A field has one light (`TDustLight`): a shaft out of a hole - brightest on its axis, wider the farther it falls, dark above its source -, a glow off the lit floor (an oval fading from its middle) and an ambient. The light is reckoned at the corners of a mesh laid over each band (a corner every 4 units across at most, 8 rows down; `SDL_RenderGeometry`), its tint is the color of the light, and the band is added over what is behind it (`SdlBlendModeAdd`). There is no texture of a beam: in a vacuum the shaft is seen only where dust crosses it, so the dust draws it. The light stands still while the dust moves through it.
- **The bands** (`TDustBand`) roll across at a steady speed and sway up and down, slow; each is stretched to its length (one turn of the art) and height. A band is drawn in runs, one for each turn of the art the field's width crosses, so no texture wrap is asked of the renderer. The sway of every band starts at a point of its own (`SlotRoll` of its index). Time counts from the level's load and a restart does not rewind it: the dust does not jump on a death.
- **The art:** `bin/sprites/dust.mset`, three strips drawn by `tools/dust/build_dust.py` from wrapping value noise (fixed seeds, the same set every run): white, the dust in the alpha, seamless across, 1536 px wide - `dust-band-1` a thin torn thread, `dust-band-2` the wide even body, `dust-band-3` dense with gaps. `dust` joined the `objectSets` of level 2.
- **Screen 10:** tag `s10-dust`, the light warm (tint 100/80/60); the shaft from the hole of the vault (341, 16 - measured on `screen10`) to (322, 470) under the bottom edge, 3 units wide at the hole and 48 below; the glow at (318, 430), reach 205 by 240, 75%; ambient 5%. Bands, top to bottom: `dust-band-1` at y 128, 40 high, 720 long, 12 units a second, 60%; `dust-band-2` at 205, 90 high, 900 long, 8 a second, 100%; `dust-band-3` at 282, 70 high, 800 long, 5 a second, 90%. All drift right, toward the city and the boss - the arrow has gone out, the dust keeps pointing. Sways 3, 4 and 2 units over 25, 35 and 45 seconds. Doubled after the first live run (2026-10-21): at 6, 4 and 2.5 units a second over 50-90 seconds the dust was all but invisible.
- **Old cards:** three textures of 1536 px at most, six draw calls a frame at most, a few thousand corners.
- First guesses for the live run: the densities, the width of the shaft, how bright the glow lifts the low band.

## Stage 5a as built (3.0.66)
Closed doors, a mechanic of any level; on level 2 it shuts screen 10 until the Duplet is taken.

- **The level** (Levels.Defs): `"shutDoors": [10]` in the root, a list of screens (`TLevel.DoorShutOn`). The load turns down a door that no event of its screen opens (`SLevelDoorNeverOpens` - a softlock caught at load), an opening on a screen whose door is not shut (`SLevelDoorNotShut` - a screen number gone astray), a screen off the level (`SLevelDoorBadScreen`) and one named twice (`SLevelDoorTwice`).
- **The action** `openDoor` (`eaOpenDoor`, Levels.Events), JSON nothing more; the director calls the cue `OpenDoor` (`TOpenDoorCue`, Events.Director).
- **The game** (Moon2D.dpr): `FDoorOpened`, raised by the cue, which shows the go-right arrow in the same breath - open = the arrow, one action. `HandleScreenTransitions` lets the hero through the right door only when `not (FLevel.DoorShutOn(screen) and not FDoorOpened)`, as it does while the trial runs: a shut door is the wall the trial's door already was. `FDoorOpened` drops with every arrival on a screen, every restart (the pickup grows back with the field, and the door waits for it again) and every new level.
- **Screen 10:** the Duplet carries the tag `s10-duplet`; the event `s10-door` waits for `allDead` on it and opens the door. Until a screen 11 comes, the door it opens is the last door of the campaign (the ending titles).
- **Tests:** `Tests.Levels.Doors` - the list read, the action read, the four refusals at load.

## Stages 5b and 5c as built (data, no version)
Screen 11 of level 2 is all data, the rocks standing in their places; the stone's waking and its taking are 5d and 5e.

- **The art: one ChatGPT generation an element**, each on a clear ground (real alpha) with a silhouette of its geometry and the screen 10 composite for its style; what was done to each is in its description in the set. In `level2-objects.mset`: four fangs (`s11-fang-needle`, `-crown`, `-double`, `-leaning` - the last kept for the chase), three columns (`s11-column-a`, `-b`, `-c`, drawn 2 units past each edge of their cells), four rocks (`s11-rock-step`, `-block`, `-chunk`, `-shard`), the ledges in and out (`s11-way-in`, `s11-way-out`, cut pixel for pixel from `s10-room`). Near objects at 6 px a unit for the width they are drawn at, never above the generation's own pixels; every texture within 2048 px. In `level2-backdrops.mset`: `screen11`, the outpaint.
- **The moon stone is a broken lump, not an oval** (decided 2026-10-21): the first generation, an upright oval with a rim, read as a portal - its own file was named "black portal". The lump, 24 units wide (smaller than the hero, decided on the first look), in `moonstone.mset`: `lying` is a picture 56 units wide with the stone's middle 44 units from its left, so that the picture, centred on the cell of column 12, puts the stone on the middle of column C; `gone` is clear. The pickup `moonStone` (`bin/monsters.json`): no effect yet, no sound; taking it is what counts.
- **The level** (`bin/level2.json`): the grid of "Screen 11"; the backdrop from screen 11, tint 75/75/80; the objects back to front - the fangs tinted to their depth (needle 55/52/55, crown 45/43/46, double 40/38/42), the rocks of decoration (55/55/62, 70/70/78, 60/60/68), the columns, the ledges; the step as a still pad (`s11-step`, 290, deck on 256, 60 wide, blocks bullets); the dust of screen 10 with the shaft moved with the hole (from 161, 16 to 142, 470, the glow at 138, 430); the respawn point at cell 2, 11; `"shutDoors": [10, 11]` and the event `s11-door` (`allDead` on `s11-stone` -> `openDoor`).
- **The End debug key** stays on screen 10: the whole way from the Duplet on is seen in one walk.
- Until 5d the rocks stand risen from the start, and the step is a plain floor. Until a screen 12 comes, the door of screen 11 is the last door of the campaign.

## Stage 5d as built (3.0.67, tuned in 3.0.68)
The waking is a scene (Levels.Scenes) - `s11-wake`, once a level - started by an event the hero sets off by landing on column B. All but four pieces of it the scenes already had: the sound, the music, the shake, waking pads and flying them.

- **The condition `heroStands`** (`ecHeroStands`, Levels.Events): `"x"`, `"y"` from 1, as a placement's cell. The director asks the game (`THeroStandsCue`, `HeroStandsIn` of Moon2D.dpr): the hero's middle over the column, his feet on the bottom line of the row (to a unit), not dead, not in a jump or a fall. The load turns down a cell off the grid. Screen 11: `s11-wake`, x 8, y 8 - on B.
- **The back ease** (`meBack`, `"ease": "back"`, Levels.Dynamics `EasedShare`, now in the interface): an ease-out that runs about 4% of the way past its mark at two thirds of its time and settles onto it. A fly of a scene may take an ease now (`Eased` on the cue; `EasedFlight` of Pads.Flights, `TPad.FlyEased`); a fly without one brakes as a pad does, as before - the cordon's lift unchanged.
- **The pace** of a dynamic object (Levels.Dynamics): its clock's speed, 1 as the level file has it, faded as the intensity is (`PaceTo`, `TDynamicObjects.PaceTagged`), back to 1 on a rewind. A scene sets it with the cue `pace` (`ckPace`; a target and a value, a percentage). Only the dust minds it: its bands roll and sway by a clock that runs at its pace. The dust of screen 11 is stilled over 30 ticks as the stone wakes.
- **The eclipse** (`TEclipse`, kind `eclipse`, Levels.Dynamics; back layer by default - over the static objects and the pads, under the monsters, so the stone stays clear of its own dark): look `void` - the world darkened toward black in a soft disc of `reach` units, `depth` deep at full intensity, and a soft cold halo `rim` units across behind the heart; look `wave` - a ring of dark running out to `reach` as the intensity runs from 0 to 1, fading as it goes, gone at either end. The dark is drawn black at the alpha of a glow made at startup (`CreateGlowFromImage`, blend mode set to blend); the halo is added. A round ring for the rim was tried on the preview and dropped: round against the broken stone it read as a portal again.
- **The stone turns** (Monsters.Defs `TPictureDef`: `"turn"`, seconds a turn, `"hover"`, units; Monsters `DrawPicture` through `DrawSized`, which takes an angle now): the moon stone turns once in 20 seconds and hovers 1.5 units over 4. Its picture is the stone alone with 4 clear units over and under it (24 x 37) so it turns about its own middle and never touches its column; the placement's `"shiftX": 16` (Levels.Defs `TEntityPlacement.ShiftX`, taken by `TMonster.Create`) stands it on the middle of column C, which is two cells wide.
- **The rocks are pads** asleep under the bottom edge (y 384, `"dormant": true`): the step `s11-step` (still, blocks bullets) and three of decoration (`s11-rock-block`, `-chunk`, `-shard`; let bullets by, bob a unit). The decoration can be stood on - nothing up there leads anywhere. The chunk stands over the gap between A and B: over B it rose into the hero's head. The shard rises over the way out, to y 70, out of the hero's reach from C: over C it passed under the stone, and the stone - a monster, riding the decks as monsters do - went up with it.
- **The jolt** (`ckJolt`, cue `jolt`, 3.0.68): one blow to the screen, `value` a percentage of a trauma of 1 (the boss's blast). The director gathers the jolts of a tick and the game takes them once (`TSceneDirector.TakeJolt`); a scene cut short or put as an aftermath deals none. The rumble of `shake` alone is a tremble of about a unit at full: under a third it was not felt at all.
- **The scene** (about twice as slow in 3.0.68 - the first cut was over before it could be watched): the music ducks to 15% over 40 ticks and comes back over 99 from tick 340; `stonewake.wav` plays from tick 0; the dust is stilled over 30 from 0; the void fades in over 70 from 25, with a jolt of 20; the wave runs over 90 from 35; the rumble rises to 40% from 30 and to 80% from 60, gone from 260 over 80; the rocks wake and fly by `back`, each with a jolt as it comes free - the block at 60 (140 ticks, jolt 45), the step at 85 (120, 40), the chunk at 105 (130, 30), the shard at 125 (150, 30). The aftermath (a death after the scene): the dust stilled, the void and the wave at full, every rock awake in its place.
- **The sound:** `bin/sounds/stonewake.wav` by `tools/sounds/stonewake.py` - a drone made as the cordon's hum is (`cordon.py`): two stacks of 12 overtones at 41 Hz, half a hertz apart, the pitch settling from 6% above over the first 4 seconds and drifting a little, soft-clipped, then low-passed at 260 Hz; under it noise low-passed at 70 Hz. Half a second of nothing, awake by 4 seconds, held to 8.5, gone by 12.5 as the music comes back; 13 seconds. No cracks: clicks and a bright hum over noise sounded like a vacuum cleaner, not a ship's bulk.
- **The stone is anchored** (`"anchored": true` in monsters.json, Monsters.Defs `Anchored`, 3.0.68): no blow, no blast's throw and no deck moves it. A pickup of 2008 is knocked about by shots; the stone was shot off its column and left its halo hanging where it had lain. It is invulnerable too (`"invulnerable": true`, `Invulnerable`): a shot bursts on it and takes nothing - shot down, it would have opened the door without being taken.
- **The halo goes with the stone:** taking it (event `s11-door`) fades the void to nothing over 20 ticks. The wave is left alone - at full it is not seen, and faded back it would run in.
- **The shuttle** speaks as the hero comes onto the screen (event `s11-shuttle`, `enterScreen`): a hint at the top, header ЧЕЛНОК - "Мастер, это лунный камень. От него идут волны энергии." That the stone fits the suit is said later.
- **Left out:** the grit falling off the rocks' undersides and the rocks' tilt dying away - a pad neither sheds nor turns; worth it only if the live run asks.
- First guesses for the live run: the depth of the dark (in the dark corner of the stone it shows little; the wave shows over the lit wall), the halo's size and color, the overshoot, the music's dip, how loud the hum is.

## Stage 5e as built (3.0.69)
Taking the stone starts a second scene, `s11-fall`: the event `s11-door` (`allDead` on `s11-stone`) opens the door and starts it.

- **A scene takes over** (Scenes.Director): a scene started while another plays used to be dropped, and the waking runs about 13 seconds - longer than the way from B over the step to the stone. Now the new one takes over on the next tick, as a cut: the old one's things land (`TakeOver`), its world is put as its aftermath says - a rock still rising snaps to its place, to fall from there -, its sounds play on, still held, and the music, the shade and the rumble go on from where they are; the new scene's cues lead them on.
- **The rewinds before the aftermaths** (`ReArm`): a death rewinds the scenes it rewinds first, then puts the aftermath of every scene once a level that has played. Before, they went in the order of the file, and the fall - a scene of a life after the waking - took the dust back to the level file over the waking's aftermath, which stills it.
- **Once a life:** the field is reborn on a death, and the stone with it - the rocks must stand again for it to be taken. A death on screen 11 rewinds the fall, the waking's aftermath raises the rocks, the event waits for the stone again. A death elsewhere puts the waking's aftermath and leaves the fall alone: the stone is back on its column, the rocks are up under it.
- **The halo** fades in the fall (the void to 0 over 20), not in the event: the takeover lands the waking's own cues, the void at full among them, a tick after the event, and would have lit it again.
- **The fall** (33 ticks a second): the rocks are let go - no sag, no wind-up - and fall by the pull the hero falls by (`Gravity` of Hero.pas: 1/7 of a unit a tick, every tick), the moon's pull of the game. The ease is `fall` (`meFall`, Levels.Dynamics): the way grows as the square of the time, so a rock sets off at once, and the ticks of a fall are `sqrt(2 d / g)` for the distance d - a heavier or lighter pull is four numbers in the scene. Each rock drops to y 520, under the pit line (450) with its deck, so a hero falling into the pit never lands on it: the step from tick 10 (264 units, 61 ticks), the shard from 20 (450, 79), the chunk from 30 (305, 65), the block from 40 (370, 72) - nearest to the stone first. The music is not ducked again: the dip of the waking is the only one, and the fall gives the volume back over 99 from 150 for a stone taken before the waking has done so. The rumble to 30% over 25, gone from 110 over 60; `stonefall.wav` from 0. A jolt of 25 at 100 as they come down far below; the dust back to its pace over 90 from 60. The aftermath: every rock at y 520, the dust at its pace.
- **The sound:** `bin/sounds/stonefall.wav` by `tools/sounds/stonefall.py` - the drone of the waking powering down: the same two stacks at 41 Hz, the pitch sinking an octave over 3 seconds as the level dies by 3.2; a dull blow at 3 seconds (noise and a 30 Hz thump under a low-pass at 90 Hz, a 30 ms attack, 0.8 s decay); 7 seconds. No clicks.
- **A hero on the step** when it drops rides it down into the pit, as a pad carries him: the step goes first but 10 ticks after the stone is taken, by when he stands on C.
- **Tests:** two in `Tests.Scenes.Director` - the takeover, and the rewind of a scene of a life under the aftermath of a scene once a level.
- **The checkpoint** (3.0.71): the event `s11-door` moves the screen's checkpoint to the stone's column, cell 13, 6. The action `respawn` (`eaRespawn`, Levels.Events; `"x"`, `"y"` from 1 as a respawn point's, held at load to the rules of one - on the grid, out of a wall, over a floor), the cue `Respawn` (`TRespawnCue`, Events.Director), `MoveCheckpoint` of Moon2D.dpr. The pit is not a death: it takes a life and sends the hero back to the checkpoint with the field untouched, so a hero who took the stone and jumped back into the pit came back at the way in, the rocks gone and the stone taken, with no way up to C - a softlock. Now he comes back on C, a step from the way out. A death restarts the screen whole - the stone grows back, the rocks stand risen - and puts him on the same cell, by the stone; the screen's own respawn point, the way in, is pinned again after it.

## Stage 6 as built (3.0.70)
Not a bar: a small eclipse. Three bars were tried on demo stands (2026-10-22) - hollow, filled with a light edge, filled light - and dropped: a bar is the language of a loading screen, and the HUD already has two rectangles. The charge is the moon stone's, so it looks like the stone.

- **The gauge** (Hud.Energy): a black disc 20 units across in a pale halo, in a slot the heart monitor's panel grows on its right, 32 units wide - the twin of the reward slot on the left of the charge panel, so the two corner panels mirror each other. The charge runs round the rim as an arc of light from the top, clockwise, over a faint ring of the whole rim; a white point at its head. The number stands in the middle of the disc with a percent sign - "5" alone did not say five of what: the 3x5 digits at a pixel of 1.4 units (1.2 for "100", or its corners touch the rim), the sign a glyph of the same kind at 1.0, standing on the line. A rise eases the arc in and flashes the halo and the number; a fall (a death) is shown at once. Full, the ring breathes faster. No slot until the first of the charge comes; with the charge gone, it folds back over 8 ticks. Centered was tried and looked lost between the corners; the right panel was tried and crowded the reward slot.
- **The panel's wing** (Hud.Vitals `Wing`): the monitor draws its fill and frame that many units wider, with a divider where its own width ends; what is in the wing is not its business. The game passes the gauge's `WingWidth` every tick.
- **The arc** is drawn as strips of light along the circle (the band glow of the go-right arrow, `SDL_RenderGeometry` over `gsBeam`): round at any size of the window. The disc is a new glow shape, `gsDisc` (Render.Glow) - a disc with a crisp edge, two texels of a 64-pixel texture - drawn black through `CreateShadeShape` (the same shape blended, not added).
- **The orbs** (Orbs.Feed): taking the stone sends the charge out of the hero as black orbs - five at most, the charge split among them, so the stone's 5 is five orbs of 1 and the number counts up as they land. A beat after the taking (15 ticks) they come out of him one after another, 9 ticks apart, growing out of a point over 30 ticks to spots over his head (an arc of 70% of a half-circle, 22-30 units out), hang there 60-85 ticks swaying and keeping to him as he walks, then fly to the middle of the disc in 40 ticks, each on its own bowed curve, gathering speed (cubic), and go into it a little smaller. The first lands about 4.8 seconds after the taking, the last about 6. They strike nothing, and are drawn over the HUD with no shake, so they go into the gauge.
- **The dark orb** (Orbs.Flock, `TOrbTint.Dark`, `MoonOrbTint` - the colors of the moon burst): two units bigger than an ice orb - the halo 15 across, its thick part 10, a white rim 9.2 and a black body 7.6 over it, drawn last; an implosion flashes in the glow color, the black core would add nothing. The canvas of the dynamics has the disc twice now: `DiscGlow` added, `DiscShade` blended. The moon form will fly the same orbs.
- **The event:** the action `energy` (`eaEnergy`, Levels.Events), `"value"` 1..100; the director asks the game (`TEnergyCue`). Screen 11: `s11-door` gives 5 with the door and the fall. The game caps what it starts at what the gauge has room for.
- **A death gives back the charge the hero had on coming onto his screen** (`FEnergyAtEntry`): what a screen gave regrows with its field. Taken on screen 11 and died there - the stone is back, the gauge folds, the stone gives again. The orbs still on their way when he goes through the door count as the charge's already. The dead hero's orbs draw into their points and bring nothing. A new level starts at 0.
- **Not yet:** the tank, the trickle and the ceiling of the charge (stage 15) - the gauge only shows what it is given; the shuttle's line that the stone fits the suit.

## Stages
Each its own commit, each run live.
1. **False ending.** Built (3.0.63), see "Stage 1 as built".
2. **Screen 10 - the double-barrel room.** Built, see "Stage 2 as built".
3. **The double-barrel as a weapon.** Built (3.0.64), see "Stage 3 as built".
4. **The living backdrop.** Built (3.0.65), see "Stage 4 as built". The far ledge comes with its screen (stage 7).
5. **Screen 11.** In steps, each its own commit:
   - 5a. **Closed doors.** Built (3.0.66), see "Stage 5a as built".
   - 5b. **The art of screen 11.** Built, see "Stages 5b and 5c as built".
   - 5c. **Screen 11 as data.** Built, see "Stages 5b and 5c as built".
   - 5d. **The stone wakes.** Built (3.0.67), see "Stage 5d as built".
   - 5e. **The stone is taken.** Built (3.0.69), see "Stage 5e as built".
6. **The energy gauge.** Built (3.0.70), see "Stage 6 as built". The stone line was built with stage 5d.
7. **Screen 12.** Designed (2026-10-23), see "Screen 12"; the art is made. In steps: 7a the sphere (`TLifeSphere`, the pickup, its forming and its taking); 7b the convoys and the searchlight (the far ledge as a living backdrop); 7c screen 12 as data (the objects, the ledge on 10 and 11, the floor, the events, the shut door).
8. **Screen 13 - the arena and the hull.** Flat floor, closed on both sides; the 2x2 machine on two wheels drives, stops, crushes; the TeK shield; death restarts the fight.
9. **Turret 1** - aimed bursts.
10. **Turret 2** - the sweep, with the warning at the muzzle.
11. **The belt.** The tiled floor slides with a wrapping offset, the backdrop stands; the world carried left (the hero by ShoveX, in the air too), the hull's wheels turning by the belt, the speed-up and the run-down. Art: the floor tile.
12. **The napalm launcher.** The shell up and out, the aim a second behind the hero, the warning on the floor, the drop, the splash, the puddles riding the belt; the fire zone and its unstable edge. Art: shell, trail, splash frames, puddle loop.
13. **The drifting pads and the medkits.** Pads on the upper layer carried by the belt, the random pattern with a way up to the hatch every few seconds, medkits riding along and gone at the left edge.
14. **Turret 3 and the brake lurch.** The shielded turret with the open hatch, its fire; the lurch with the brake lights; the end of the chase (launcher folds, belt runs down).
15. **The charge.** Tank, trickle, ceiling 95% until the third turret.
16. **Evolution.** The rite with black orbs, the eclipse pattern.
17. **The moon form.** Orb gun piercing armour, jump +25%, fire rain, black orb aura.
18. **Air phase.** Nozzles, grenades, guns, the hull open to orbs.
19. **The blast.** The explosion, the form off, silence instead of the victory track, the hand-over to the titles (docs/mechanics/finale.md, stage F7; the titles themselves, F1-F6, can be built before the boss).
20. **Tests and docs.** Codebase maps, PORTING-NOTES, TESTING.md, this plan.

## Open
- The screen number 13 (10 and 11 are built, 12 is designed).
- Screen 13's backdrop: one more step of a third (the gate near x 300 units, the ledge running to it) or a generation of its own - decided after screen 12 is played.
- The road tile may be redrawn - one sprite, swapped any time.
- The crust of screen 12 is below 6 px a unit (1527 px for 328 units): regenerate in two halves for 4K.
- The 4K room of screen 10: four objects of 256 units from an upscale.
- The speed of the fangs in the chase: slower than the floor or with it.
- The eclipse on taking the stone: kept in reserve.
- The Duplet after level 2: does the hero keep it on the next levels, where small monsters come close?
- Turret patterns and the numbers of the charge (K, drain, trickle) - first guesses, tuned live.
- What the black orb aura and the fire rain do in numbers against the ice form's.
- How the random pad pattern is made. Two ways: a generator that shuffles hand-made chunks of three or four pads (each chunk passable by design, one of them always leading to the hatch height); or the carousels the game already has (Levels.Carousels, counter-clockwise, the track mostly off the screen), two or three at different heights and periods, so the pattern never quite repeats - no new pad code, but no guarantee of a way up either.
- Three turrets or four. A fourth only if the chase is too short: the machine drops a plate and turret 4 sits low on the rear hitch, hit from the floor - turret 3 from above, turret 4 from below.
- A death in the chase restarts the whole fight, as every death here. If the chase makes the fight long, the chase may get its own restart point (turrets 1 and 2 stay dead).

## Risks
- The giant double-barrel's spread meets the honeycomb before the turrets: a lot of flares and no damage until the player understands the turrets are the target. Probably fine - arena 2 taught the honeycomb.
- The charge must never stall: the trickle plus the ceiling guarantee 100% at the third turret's death; check live that the gauge does not read as "it fills by itself, the turrets do not matter".
- The air phase with grenades and guns after a long fight - one death replays the whole fight. Keep the fight short.
- The belt and the plain jump: the hatch height must be reachable from the pads with the plain jump - the +25% comes only with the evolution.
- The pads and the belt: a pad that leaves the screen on the left must be allowed to (the pad code may assume pads stay on the screen); and a hero on a pad that the belt carries and a shot or the lurch shoves must never be left hanging in the air.
- The brake lurch with the napalm behind may be one trap too many - tune or drop live.
