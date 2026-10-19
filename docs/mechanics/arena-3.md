# Level 2 finale: the tunnels and the TeK machine (second of the two level 2 bosses, end of 3.0)

Status: designed (2026-10-17); stage 1 built (2026-10-19, 3.0.63). Many small stages, each its own commit and live run. The screen numbers 10-13 are a guess (arena 2 is screen 9) - shift them if the layout differs.

## The idea in one line
A false ending: arena 2 is won, the victory track plays, the player thinks the level is over - and the arrow points right. Tunnels of lunar rock, a giant double-barrel, the moon stone, an energy bar at 5%, and a TeK machine that cannot be hurt until the hero becomes the moon form.

## Rules of the finale
- No monsters on the tunnel screens. The emptiness is the threat.
- The boss fights alone - no other enemies help it.
- Death in the boss fight restarts the fight from its start (the boss screen), not from the tunnels. The battles are short - no checkpoints inside.
- The floor of the boss arena is flat.
- TeK armour = the shared TeK shield of arena 2 (the pale gold honeycomb, flare on a hit, no sparks). The player has learned it on the cannons: honeycomb means "do not waste bullets". The ricochet of the 2026-10-08 idea is dropped - one sign of invulnerability, not two.

## Screens
### The false ending (screen 9, after the trial)
- win.ogg plays to its end; the anxious retro ambient, lunar.ogg ("Lunar Silence", made in Suno, 3 minutes - for the three tunnel screens before the boss), fades in under its last seconds; at its very end the go-right arrow. (The chewed-tape slowdown was turned down - cannot be done.) As built - see "Stage 1 as built".

### Screen 10 - the double-barrel
- A room of lunar rock, the double-barrel on a pedestal, as the super shotgun in Doom 2. No monsters.
- **The gun is huge, out of all proportion to the hero** (decided 2026-10-17). Reason: no close combat with small monsters ahead, and a big boss is hit for sure. A short-range wide spread is exactly the weapon for a 2x2 target.

### Tunnel life (all tunnel screens)
No wind on the Moon - no billowing dust. Instead:
- Levitating dust: rare tiny particles drifting slowly and glinting (lunar regolith is charged and hovers - a real effect).
- Thin straight streams of sand from the ceiling, slow, no clouds (low gravity).
- Tremors: every N seconds the screen shakes slightly and more sand falls. That is the TeK machine somewhere ahead - the boss announces itself three screens early.

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
Flat floor. The machine, then the evolution, then the air phase, then the blast.

## The boss: TeK machine
- A big TeK wheeled vehicle, 2x2 cells, under the TeK shield - cannot be wounded.
- Ground phase: drives, stops, shoots, drives again, crushes the hero (decided 2026-10-08).
- Turrets come out on top on a mast (up to three cells high, swaying - the 2026-10-08 idea) and can be hit. Three stages, three turrets, each shooting differently. First guess:
  1. Aimed bursts at the hero - teaches to move.
  2. A mortar, shells on an arc - teaches to look up.
  3. A long horizontal sweep, as the arena 2 cannons - teaches to jump.
- The behaviour in detail is worked out at its stages.

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
4. **Tunnel life.** Levitating dust, sand streams, tremors - once, for every tunnel screen.
5. **Screen 11 - jumping and the moon stone.** The black glow, the force field.
6. **The shuttle and the energy bar.** The stone line; the bar at 5% on taking the stone.
7. **Screen 12 - bumps and ORB 100%.** The new healing object; the shuttle's line about the TeK robot.
8. **Screen 13 - the arena and the hull.** Flat floor; the 2x2 machine drives, stops, crushes; the TeK shield; death restarts the fight.
9. **Turret 1** - aimed bursts.
10. **Turret 2** - the mortar.
11. **Turret 3** - the sweep.
12. **The charge.** Tank, trickle, ceiling 95% until the third turret.
13. **Evolution.** The rite with black orbs, the eclipse pattern.
14. **The moon form.** Orb gun piercing armour, jump +25%, fire rain, black orb aura.
15. **Air phase.** Nozzles, grenades, guns, the hull open to orbs.
16. **The blast.** The explosion, the form off, the end of the level and of 3.0.
17. **Tests and docs.** Codebase maps, PORTING-NOTES, TESTING.md, this plan.

## Open
- The screen numbers (10-13 a guess).
- The giant double-barrel after level 2: does the hero keep it on the next levels, where small monsters come close?
- Turret patterns and the numbers of the charge (K, drain, trickle) - first guesses, tuned live.
- What the black orb aura and the fire rain do in numbers against the ice form's.

## Risks
- The giant double-barrel's spread meets the honeycomb before the turrets: a lot of flares and no damage until the player understands the turrets are the target. Probably fine - arena 2 taught the honeycomb.
- The charge must never stall: the trickle plus the ceiling guarantee 100% at the third turret's death; check live that the bar does not read as "it fills by itself, the turrets do not matter".
- The air phase with grenades and guns after a long fight - one death replays the whole fight. Keep the fight short.
