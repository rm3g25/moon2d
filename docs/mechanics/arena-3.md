# Level 2 finale: the tunnels and the TeK machine (second of the two level 2 bosses, end of 3.0)

Status: designed (2026-10-17), the boss fight reworked around a chase (2026-10-19); stage 1 built (2026-10-19, 3.0.63). Many small stages, each its own commit and live run. The screen numbers 10-13 are a guess (arena 2 is screen 9) - shift them if the layout differs.

## The idea in one line
A false ending: arena 2 is won, the victory track plays, the player thinks the level is over - and the arrow points right. Tunnels of lunar rock, a giant double-barrel, the moon stone, an energy bar at 5%, and a TeK machine that cannot be hurt until the hero becomes the moon form - and that runs away from him in the middle of the fight.

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
- **The gun is huge, out of all proportion to the hero** (decided 2026-10-17). Reason: no close combat with small monsters ahead, and a big boss is hit for sure. A short-range wide spread is exactly the weapon for a 2x2 target.

### The tunnels are giant
The hero walks along a ledge in a tunnel far bigger than the screen: the backdrop is far away - the opposite wall, the vault, the depth of the tunnel going off into the dark. The playfield (floor, ledges, the pedestal) is near and small against it. Scale is the point: a small hero in a huge empty place.

### The living backdrop (all tunnel screens) - a new mechanic, not designed yet
It is the backdrop itself that lives, not effects laid over the playfield. How - not decided. Ideas to choose from or mix:
- **Depth by layers.** The backdrop in two or three layers (far wall, mid arches or pillars, haze) and a slight shift of each against the hero's position - a few units, the far layer least. A still screen gets depth without scrolling. The same layers then serve the belt of the boss arena, where they slide at different speeds (parallax for free).
- **Moving light far away.** Shafts of light through cracks in the vault, crawling slowly as the sun moves; or a beam sweeping the far wall from deep in the tunnel - TeK searchlights at the city gate. A light texture over the backdrop with additive blend, turned or slid slowly.
- **Distant TeK traffic.** Tiny lights or silhouettes crawling along a far ledge or rail - convoys going toward the city. The world beyond the hero's reach is busy; it also points the way.
- **Haze bands.** Long bands of levitating dust hanging in the depth, drifting very slowly and lit where a shaft of light crosses them (no wind on the Moon: the dust is charged and hovers - it drifts, it does not billow).
- **Distant rockfall.** On a tremor (the TeK machine somewhere ahead), far away a piece of the wall comes down slowly in a dust column, its rumble arriving late - the delay sells the distance.
- **Pulsing veins.** Glowing seams in the far rock that breathe; now and then a wave of light runs along them to the right - toward the arena.
- **The glow at the end.** The far end of the tunnel with a faint light that flickers - the city entrance. Grows a little from screen to screen.

Earlier proposal, kept as ideas for the near plane, not as the plan: rare levitating dust specks glinting near the hero, thin slow streams of sand from the ceiling, and tremors - a slight shake every N seconds with more sand falling.

Constraints for whichever is chosen: each layer within 2048 px (old cards); the art is cut into layers at generation time, not after; the layers must also loop for the belt of the boss arena.

### Screen 11 - jumping and the moon stone
- Some jumping, then the moon stone: a big glowing oval, black inside. The "black glow" is an event horizon: the background darkens around the stone (SDL_BLENDMODE_MOD), a thin bright rim at its edge.
- The way on is closed by the same force field while the stone is not taken; taking it puts the field out.
- The shuttle: the moon stone can be used in place of the ice stone, it seems powerful, a strong energy comes off it.
- The energy bar appears the moment the stone is taken, at 5%: the 5% is the stone's own charge.

### Screen 12 - bumps and ORB 100%
- Jumping over bumps (a warm-up, not a lesson - the arena floor is flat).
- New object: ORB, restores 100% health.
- The shuttle: another TeK robot seems to guard the entrance to the city; the ice form does not work yet - it was just used; fight bare-handed and watch the form charge indicator at the top.

### Screen 13 - the boss arena
Flat floor, closed on both sides. Three acts in three tempos: the machine standing its ground (turrets 1 and 2), the chase (turret 3), then the evolution and the air phase on a still screen again.

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
- the floor and the backdrop slide left; the machine stays on the right part of the screen, its wheels turning;
- everything that belongs to the world - the hero, the napalm puddles, the pads, the medkits - is carried left at the belt's speed, in the air as on the floor (otherwise a jump would be a free way to stand still);
- an idle hero drifts back to the left wall, so the hero has to run to keep up. The machine is slow, the hero is faster: running, he gains on the belt at about the belt's own speed;
- the collision grid does not move: the floor is flat and the same along its length, so only the picture slides. The floor art and the backdrop must loop seamlessly;
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
The charge is tied to the lives of the three turrets, but with a delay, so the dependence is not obvious:
- **Hidden tank.** Damage to a turret goes into a tank, not into the bar. The bar drinks from the tank at its own pace - the bar keeps growing a couple of seconds after the hit.
- **Trickle.** The stone charges by itself, about 0.5% a second - the bar lives even with no hits.
- **Ceiling.** While the third turret lives, the bar stops at 95%. 100% comes only with the death of the last turret; the evolution follows at once.

```pascal
// turret damage - into the tank, not the bar
Pool := Pool + Damage * K;

// every tick: the bar drinks from the tank
Take := Min(Pool, DrainPerSec * Dt);
Pool := Pool - Take;
Energy := Min(Energy + Take + TricklePerSec * Dt, CapBeforeLast);

// third turret dies
CapBeforeLast := 100;  // the bar runs to 100 -> Evolution
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
- The blast. The form comes off (black orbs into the aura ring, as the ice form). The level ends - and version 3.0 with it.

## Stage 1 as built (3.0.63)
All of it is data on screen 9 plus a few words of the event vocabulary; no code knows the false ending.

- **The victory track of the trial is a sound, not music** (TSoundBank.PlayTrackHeld: win.ogg decoded whole at startup, played on a sound channel and held). The music channel is free, so the next track fades in over the end of the victory with no conflict. The trial's own track stops at the victory. The game counts down what is left of it (from the decoded length, TSoundBank.SecondsOf); the menu pauses the track and the count with it, a restart and a new level stop it. The victory at the boss of level 1 is still music - it ends the level.
- **Condition `victoryEnds`** (ecVictoryEnds), JSON "lead" in seconds (0 by default): holds once the victory track has "lead" seconds left or fewer, and after its end. A missing win.ogg is a track of 0 seconds - the events fire at once.
- **`music` takes "fade"** (seconds, 0 by default): the track comes in from silence (Mix_FadeInMusic).
- **Action `goRight`** (eaGoRight): the go-right arrow (Hud.GoRight) in the middle of the screen - a hollow arrow of neon tube, three strips of the band glow along its outline (halo, tube, white core), mitered at the corners, so it is sharp at any window size. Four slow blinks, 60 ticks each, every one a raised cosine from dark to full and back, then it is gone - about seven seconds. No sound: the arrow is big enough to be seen (a beep and a slide on each flash were tried and dropped). It also goes out when the hero leaves the screen, on a restart and with the level. The beat (TGoRightBeat) is apart from the picture. Reusable: any event can raise it.
- **The events**: s09-tunnel-music (`victoryEnds`, lead 5: lunar.ogg with fade 5 - remembered as the track a restart plays) and s09-go-on (`victoryEnds` at the very end: `goRight`).
- **The door is still a wall**: screen 9 is the last screen of level 2 until stage 2 adds screen 10. The arrow points at a closed door until then.
- lunar.ogg is put in `bin/music/` by hand; without it the screen stays silent and the arrow shows anyway.

## Stages
Each its own commit, each run live.
1. **False ending.** Built (3.0.63), see "Stage 1 as built".
2. **Screen 10 - the double-barrel room.** Lunar rock, the pedestal, no monsters.
3. **The double-barrel as a weapon.** Huge, spread, damage, reload, sound; the size of the art against the hero.
4. **The living backdrop.** A new mechanic, design first: pick from the ideas in "The living backdrop", then build it once for every tunnel screen.
5. **Screen 11 - jumping and the moon stone.** The black glow, the force field.
6. **The shuttle and the energy bar.** The stone line; the bar at 5% on taking the stone.
7. **Screen 12 - bumps and ORB 100%.** The new healing object; the shuttle's line about the TeK robot.
8. **Screen 13 - the arena and the hull.** Flat floor, closed on both sides; the 2x2 machine on two wheels drives, stops, crushes; the TeK shield; death restarts the fight.
9. **Turret 1** - aimed bursts.
10. **Turret 2** - the sweep, with the warning at the muzzle.
11. **The belt.** The screen slides: floor and backdrop drawn with a looping offset, the world carried left (the hero by ShoveX, in the air too), the hull's wheels turning by the belt, the speed-up and the run-down. Seamless floor and backdrop art.
12. **The napalm launcher.** The shell up and out, the aim a second behind the hero, the warning on the floor, the drop, the splash, the puddles riding the belt; the fire zone and its unstable edge. Art: shell, trail, splash frames, puddle loop.
13. **The drifting pads and the medkits.** Pads on the upper layer carried by the belt, the random pattern with a way up to the hatch every few seconds, medkits riding along and gone at the left edge.
14. **Turret 3 and the brake lurch.** The shielded turret with the open hatch, its fire; the lurch with the brake lights; the end of the chase (launcher folds, belt runs down).
15. **The charge.** Tank, trickle, ceiling 95% until the third turret.
16. **Evolution.** The rite with black orbs, the eclipse pattern.
17. **The moon form.** Orb gun piercing armour, jump +25%, fire rain, black orb aura.
18. **Air phase.** Nozzles, grenades, guns, the hull open to orbs.
19. **The blast.** The explosion, the form off, the end of the level and of 3.0.
20. **Tests and docs.** Codebase maps, PORTING-NOTES, TESTING.md, this plan.

## Open
- The screen numbers (10-13 a guess).
- How the backdrop lives: which of the ideas in "The living backdrop", and how many layers the generated backdrop is cut into.
- The giant double-barrel after level 2: does the hero keep it on the next levels, where small monsters come close?
- Turret patterns and the numbers of the charge (K, drain, trickle) - first guesses, tuned live.
- What the black orb aura and the fire rain do in numbers against the ice form's.
- How the random pad pattern is made. Two ways: a generator that shuffles hand-made chunks of three or four pads (each chunk passable by design, one of them always leading to the hatch height); or the carousels the game already has (Levels.Carousels, counter-clockwise, the track mostly off the screen), two or three at different heights and periods, so the pattern never quite repeats - no new pad code, but no guarantee of a way up either.
- Three turrets or four. A fourth only if the chase is too short: the machine drops a plate and turret 4 sits low on the rear hitch, hit from the floor - turret 3 from above, turret 4 from below.
- A death in the chase restarts the whole fight, as every death here. If the chase makes the fight long, the chase may get its own restart point (turrets 1 and 2 stay dead).

## Risks
- The giant double-barrel's spread meets the honeycomb before the turrets: a lot of flares and no damage until the player understands the turrets are the target. Probably fine - arena 2 taught the honeycomb.
- The charge must never stall: the trickle plus the ceiling guarantee 100% at the third turret's death; check live that the bar does not read as "it fills by itself, the turrets do not matter".
- The air phase with grenades and guns after a long fight - one death replays the whole fight. Keep the fight short.
- The belt and the plain jump: the hatch height must be reachable from the pads with the plain jump - the +25% comes only with the evolution.
- The pads and the belt: a pad that leaves the screen on the left must be allowed to (the pad code may assume pads stay on the screen); and a hero on a pad that the belt carries and a shot or the lurch shoves must never be left hanging in the air.
- The brake lurch with the napalm behind may be one trap too many - tune or drop live.
