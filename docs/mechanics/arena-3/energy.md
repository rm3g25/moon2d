# Arena 3: the charge of the form

The eclipse gauge, the tank and the ceilings by heads.

## Energy (the form charge)
How it looks and where it stands - "Stage 6 as built".

**Decided 2026-10-28, over the text below where they disagree:** the charge goes by heads - the hunter brings a quarter, the sweeper a quarter, the bunker the half that is left. From the stone's 5%: a ceiling of 30% while the hunter lives, 55% while the sweeper lives, 95% while the bunker lives, 100% on its death. Not tied to the lives exactly and late - the tank keeps pouring a couple of seconds after the hit, film magic. The trickle is cut down, or it would jump the quarters by itself.

```pascal
// a head dies -> the ceiling moves; the tank keeps pouring with a delay
case FHead of
  rhHunter: Cap := 30;
  rhSweeper: Cap := 55;
  rhBunker: Cap := 95; // 100 only on its death
end;
```

The charge is tied to the lives of the three turrets, but with a delay, so the dependence is not obvious:
- **Hidden tank.** Damage to a turret goes into a tank, not into the gauge. The gauge drinks from the tank at its own pace - it keeps growing a couple of seconds after the hit.
- **Trickle.** The stone charges by itself, about 0.5% a second - the gauge lives even with no hits.
- **Ceiling.** While the third turret lives, the gauge stops at 95%. 100% comes only with the death of the last turret; the evolution follows at once. *Replaced 2026-11-04: 97 while it lives, the last 3% in 10-15 s after its death - see "Decided 2026-11-04, after the run of 3.0.98".*

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

## Journal

### Stage 6 as built (3.0.70)
Not a bar: a small eclipse. Three bars were tried on demo stands (2026-10-22) - hollow, filled with a light edge, filled light - and dropped: a bar is the language of a loading screen, and the HUD already has two rectangles. The charge is the moon stone's, so it looks like the stone.

- **The gauge** (Hud.Energy): a black disc 20 units across in a pale halo, in a slot the heart monitor's panel grows on its right, 32 units wide - the twin of the reward slot on the left of the charge panel, so the two corner panels mirror each other. The charge runs round the rim as an arc of light from the top, clockwise, over a faint ring of the whole rim; a white point at its head. The number stands in the middle of the disc with a percent sign - "5" alone did not say five of what: the 3x5 digits at a pixel of 1.4 units (1.2 for "100", or its corners touch the rim), the sign a glyph of the same kind at 1.0, standing on the line. A rise eases the arc in and flashes the halo and the number; a fall (a death) is shown at once. Full, the ring breathes faster. No slot until the first of the charge comes; with the charge gone, it folds back over 8 ticks. Centered was tried and looked lost between the corners; the right panel was tried and crowded the reward slot.
- **The panel's wing** (Hud.Vitals `Wing`): the monitor draws its fill and frame that many units wider, with a divider where its own width ends; what is in the wing is not its business. The game passes the gauge's `WingWidth` every tick.
- **The arc** is drawn as strips of light along the circle (the band glow of the go-right arrow, `SDL_RenderGeometry` over `gsBeam`): round at any size of the window. The disc is a new glow shape, `gsDisc` (Render.Glow) - a disc with a crisp edge, two texels of a 64-pixel texture - drawn black through `CreateShadeShape` (the same shape blended, not added).
- **The orbs** (Orbs.Feed): taking the stone sends the charge out of the hero as black orbs - five at most, the charge split among them, so the stone's 5 is five orbs of 1 and the number counts up as they land. A beat after the taking (15 ticks) they come out of him one after another, 9 ticks apart, growing out of a point over 30 ticks to spots over his head (an arc of 70% of a half-circle, 22-30 units out), hang there 60-85 ticks swaying and keeping to him as he walks, then fly to the middle of the disc in 40 ticks, each on its own bowed curve, gathering speed (cubic), and go into it a little smaller. The first lands about 4.8 seconds after the taking, the last about 6. They strike nothing, and are drawn over the HUD with no shake, so they go into the gauge.
- **The dark orb** (Orbs.Flock, `TOrbTint.Dark`, `MoonOrbTint` - the colors of the moon burst): two units bigger than an ice orb - the halo 15 across, its thick part 10, a white rim 9.2 and a black body 7.6 over it, drawn last; an implosion flashes in the glow color, the black core would add nothing. The canvas of the dynamics has the disc twice now: `DiscGlow` added, `DiscShade` blended. The moon form will fly the same orbs.
- **The event:** the action `energy` (`eaEnergy`, Levels.Events), `"value"` 1..100; the director asks the game (`TEnergyCue`). Screen 11: `s11-door` gives 5 with the door and the fall. The game caps what it starts at what the gauge has room for.
- **A death gives back the charge the hero had on coming onto his screen** (`FEnergyAtEntry`): what a screen gave regrows with its field. Taken on screen 11 and died there - the stone is back, the gauge folds, the stone gives again. The orbs still on their way when he goes through the door count as the charge's already. The dead hero's orbs draw into their points and bring nothing. A new level starts at 0.
- **Not yet:** the tank, the trickle and the ceiling of the charge (stage 15) - the gauge only shows what it is given; the shuttle's line that the stone fits the suit.

### Stage 15a as built (3.0.85)
The charge of the form by the first two heads (decided 2026-10-30: it must grow little by little with the fight, tied to the damage and never read as tied to it), in a unit of its own, `Game.StoneTank` (`TStoneTank`); the gauge takes it straight, with no orbs (`THeroOrbs.Charge`).

- **The tank.** Every hit on a head (`BulletStruckRamEye`; `BulletStruckRamBarrels`, a plate's catch not counted) puts its share of the head's lives into a line of `LateTicks` 50 slots (`Wound`); a wound reaches the tank only when its slot comes round - about 1.5 s after the hit.
- **The pulses.** The gauge drinks from the tank on a clock of its own: every 8 to 30 ticks (`PulseGapLeast`, `PulseGapSpan`, rolled anew each time) a percent, now and then two (`DoublePulseShare` 0.3, when the tank holds them). No even beat follows a burst, and every rise flashes the gauge, as a rise always does.
- **The share.** A head's whole lives pour in `HeadShare` 20% - a little short of its quarter; a trickle of about 0.1% a second (`TricklePerTick`) runs from the first lock, so the gauge lives between the bursts.
- **The ceilings** (`Ceilings`): 30% while the hunter lives, 55% after it. What stands at the ceiling is spilt, not kept: it must not flood the gauge the moment the next head lifts it.
- **A head's death** (`HeadDown` on the cue `Blast`): what is left from the gauge up to that head's ceiling is poured late, as any wound, in place of all that was still on its way - nothing of one head spills over into the next head's quarter - and the next ceiling stands from then on. The gauge goes on growing a few seconds after the blast. The sweeper's death pours up to 55%: the bunker's 95% and 100% are stage 15b.
- **The start and the end.** The tank starts as the first head locks (cue `Locked`), and a death clears it with the Ram, the capsules and the wrecks; the gauge itself goes back to the charge the screen began with (`THeroOrbs.Rewind`), as ever.
- **On a model** (100 hits on the hunter over 40 s, 140 on the sweeper over the next 60): the gauge goes 5, 10, 15, 22, 28 - 31 after the hunter's death - then about 4% every ten seconds to 53, and 55 after the sweeper's.
- **Tests**: `Tests.Game.StoneTank` (9: nothing before the fight; a wound reaches the gauge late; uneven pulses of one or two; never past the hunter's ceiling; a head's death pours up to its ceiling, late; nothing spills into the next quarter; the second ceiling; the trickle with no hit; a clear stops it). `Tests.Game.HeroOrbs`: the direct charge rises at once, stops at full counting the orbs on their way, and gives a corpse nothing.
- First guesses for the live run: the share of the lives, the lag, the gaps of the pulses, the trickle.
