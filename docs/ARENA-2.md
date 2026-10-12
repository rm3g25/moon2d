# Level 2 screen 9: the gravel arena (first of the two level 2 bosses)

Working plan, not for the repo. Status: design accepted ("всё нравится"), no code yet. The second level 2 boss - the mast-turret machine - comes on the screens after this one (see the level2-boss notes); this arena must not repeat it and must not repeat the level 1 pad arena.

## The idea in one line
Five arenas in one room: every 15 gravels the room rebuilds itself, and every rebuild takes away what the hero stood on. Selena does not throw gravels at the hero - she rearranges the room; the gravels are the weather.

## Rules of the room
- No support lives longer than one act. Nowhere to sit it out: not the floor, not the height.
- Gravels (gravelFemale) do not shoot and cannot climb - every permanent height would be a bunker. Hence no static platforms at all; the white blocks of 2008 are gone.
- Walls left and right stay, the floor stays (it is shelves, as on screen 8, nobody knows yet).
- The room art is the ChatGPT generation with the violet ceiling grating (accepted as the base); docks for the sleeping shelves are seated by us, they must read as nests on the wall or the player will not see where things come from.

## Gravels
- Arrive like the hero at the start of a level, but violet - Selena's colour, slightly violet (EntryLook with a violet tint, one shroud per arrival - a pool).
- A gravel that walks out of the RIGHT gap teleports to a random top point, again with the violet glow. The left gap is a wall for them (the hero's entry).
- A gravel that falls into a hole (acts 3-4) teleports the same way.
- No teleport while walking on the floor.
- Cap on the living: a wave is skipped while N gravels are alive (they never leave now - without the cap 200 on wild pile up).

## Medkits
- The three trial medkits of 2008 are removed. Their triggers (changeMusic, heroX, gravelBoss) move to another carrier - an event or a screen trigger - before the medkits go.
- One medkit per 15 gravels, delivered by the same violet teleport; from act 2 on it lands on the top of something the hero has to climb to.
- Bait pads: two falling pads at the top travel left-right in opposite phase; a medkit can land on a pad and ride it. Stepping on the pad takes the medkit and drops the pad (and the hero) half a second later. Not taken - it rides on, the next one lands on the other pad.
- Pickups are excluded from the trial gate (AnyAliveOnScreen counts them now - an untaken medkit would block the finale).

## Acts (by the share of the quota burned, not by the count - the quota is 75/125/200)
1. **Floor** (0-1/5). Flat floor, two shelves at the walls. Random drops. "A shooting gallery."
2. **Ladder** (1/5-2/5). A zigzag of shelves wakes from both walls up to the ceiling. Aimed rain starts: every third gravel arrives in the column over the hero. The medkit goes on the top step.
3. **Collapse** (2/5-3/5). The floor slides away in sections from left to right, the wave drives the hero onto the ladder. Below - a pit; a fallen gravel teleports up. The crowd lives on the steps with the hero; a shelf going in drops its gravels on his head.
4. **Carousel** (3/5-4/5). Pads fly in from above and form a box carousel in the centre (rehearsal of the square carousel wanted for the next level). Barrels on the pads. The ladder falls asleep from the bottom up, step by step - late means the pit. The barrels are blown up when the pit below is full of gravels.
5. **Chaos** (4/5-5/5). The carousel breaks: its pads become falling pads one after another. The floor comes back in random pieces. Shelves blink out of step.
   - Stray pads: ordinary pads fly in from beyond a random edge to a random point, hang, fly on to another point or out. They misbehave at random: fall like a falling pad, turn back halfway, twitch. Transport nobody can count on.
   - Barrels from the sky through the same violet teleport, exploding on impact with the floor, a shelf or a pad. The blast wounds only the hero - gravels walk through it. Not a weapon, the weather.
6. **Finale - betoners.** The floor stands, everything below sleeps. Only the top row of shelves under the ceiling wakes; 10 betoners teleport onto it, no more than 3 alive at once.
   - The press: every ~10 s the top row sleeps and the row below wakes - the betoners drop a row lower. In half a minute they are on the floor beside the hero, point-blank.
   - A killed betoner is replaced on the TOP row: a fast killer keeps them far, a slow one gets all ten at his feet.
   - Barrels keep falling through the finale: time itself hurts.
   - The way up to them is the falling and stray pads in the middle of the room.

## Stages
Each stage ends with a live run. Versions: one per stage that changes mechanics, next free after 3.0.52; the tag lands after the docs.

0. **Art.** s09-room from the accepted generation (cropped to grid, walls straight); dock sprites for sleeping shelves (wall nest and free-hanging nest) - use the existing shelf sheet where possible; .mset. One lamp out on the left wall gets a dying beacon (the life-on-every-screen rule).
1. **Trial rework.** Move the trial triggers off the medkits; remove the medkits; pickups out of the gate; living cap; right-exit and pit teleport for gravels; violet arrival (shroud pool + violet look); medkit every 15 by teleport. The room is still flat - the old trial on the new rules.
2. **Acts engine.** Event condition "quota burned >= share"; actions: shelf group wake / sleep by tag, shelf group program switch (wave, alternate, blink), pad fly-in from above to a formation. Acts 1-3 in level2.json. Aimed rain (every third over the hero).
3. **Bait pads.** Falling pad with a ping-pong path (lift the Levels.Pads ban, return point = the current point of the path); medkit spawned onto a pad (SpawnOn) and riding it - check pickups ride as the carousel betoners do.
4. **Carousel act.** Box carousel built by fly-in, barrels on its pads, ladder sleeping bottom-up. Act 4.
5. **Chaos act.** Carousel pads turn into falling pads; Pads.Stray (edge -> point -> point/edge, random misbehaviour from the existing plunge and path pieces); sky barrels with death-on-landing and a hero-only blast - the flag goes on the spawn, not on the bullet class (the henshin rings use Contact against the boss). Act 5.
6. **Finale.** Betoner wave after the gravel gate; spawn on the top awake row; cap 3; the press (row wake/sleep on a timer); barrels continue. Check betoners fall when their shelf sleeps (affectedByGravity).
7. **Tests.** Black-box, one module per new entity: trial rules (teleport, cap, medkit per 15, gate), acts conditions, shelf groups, bait pad, stray pad, sky barrel, press.
8. **Docs.** ASSETS, both codebase maps, PADS-PLAN, PORTING-NOTES; then the tag.

## Risks
- Five acts = five balances; acts 3 and 5 on wild will be meat. Shares, not counts; tune by live runs.
- Jump heights between shelf rows are guessed - check against Hero (jump start, JumpDel) when the rows are placed; the ice form is off on this screen as on screen 8? - to decide.
- Many latch sounds on one tick when a whole group wakes - stagger or one sound per group.
- Stray pads and falling carousel pads meeting each other - keep their zones apart or let them pass through (pads do not collide).

## Open
- Ice form on this screen: on or off.
- Where the hero stands at the moment an act floors out under him (act 3) - a grace of a second, or none.
