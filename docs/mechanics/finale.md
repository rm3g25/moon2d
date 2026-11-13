# Finale: the end of arena 3 and the titles that close 3.0

Status: designed (2026-10-22), the end of the fight moved into the air (2026-11-12, see "Decided 2026-11-12" - it supersedes Part 1 where they differ; its drone and Cordon put off to a later version, "Decided 2026-11-12, after 3.0.126"); the end of the fight built (stage 19 of arena 3, 3.0.128, see "Decided 2026-11-12, stage 19" and "Stage 19 as built (3.0.128)" - they supersede Part 1 and F7 where they differ); the titles not built. Part 1 hangs on the boss (arena 3, stages 8-19). Part 2, the titles, needs nothing but a picture to stand on and can be built first. The end track, "Legendary" (Suno, indie psychedelic of the 80s, male vocal), is made: `bin/music/credits.ogg` (since 2026-11-07; Vorbis, stereo, 48 kHz, 160 kbit/s, 3:58, about -14.2 LUFS - as loud as the boss tracks, -14.5 and -14.7). Nothing plays it yet: the titles are not built.

## The idea in one line
The machine blows up, the tense music dies with it, and in the silence after the blast the end track comes in over the very picture of the victory: a studio card, the logo flaring on a beat, a promise under it - then the camera climbs out of the tunnel into the stars of the menu, and the stars turn into the menu.

## Decided (2026-10-22)
- No victory track at the end. win.ogg already lied once, at the end of arena 2; a second time would be a joke at the player's expense.
- The boss's tense track falls silent after the blast - by then the flight's, `flight.ogg` (arena 3, since 3.0.115).
- Legendary is the end track and keeps playing after the exit to the main menu.
- The order of the titles, over the main screen (the arena after the blast, the hero standing in it, no control):
  1. "Computer Dragon presents".
  2. A couple of seconds later the Moon2D logo flares in the middle, as on the menu. The fire of the menu logo is already written - this moment strengthens it and is tuned to the music.
  3. A line under the logo: the Master will return, in the sequel and in a new form (wording below).
  4. The climb: the backdrop is extended upward and goes slowly into the dark, the camera moves up, the game picture with the logo and the hero stays below. The hero cannot be steered.
  5. The stars of the menu come in, a smooth transition.
  6. A new line of text (not written yet).
  7. The exit to the main menu.

## Decided 2026-11-12: the end in the air
The fight ends aloft now (arena 3's air fight, `docs/mechanics/arena-3/ram-air.md`), not on the road of screen 13. In order:
1. The hull's lives run out: it cracks and bursts, and a small fast drone flies out of it. **The drone cannot be killed** here - it is kept for a half-boss of a later level.
2. **The flight does not slow.** The Cordon (TEK-Q6, `docs/mechanics/scenes.md` - the ship of level 1's screen 9) catches up at the flight's speed with its bay open - the bay the tank of screen 9 came out of. The drone flies into the bay and the Cordon flies off.
3. **The flight slows down**, and from here the hero is not his own (input cut). The tiles of the road come in again, and the main barge with him on it stops beside them.
4. The titles, over that picture: the main barge at rest by the road's edge, the hero standing on it.

What this changes in the rest of the file: "the arena after the blast" of the titles' order is the picture of step 3; "the blast" of Part 1's table is the hull's burst; the wreck (Part 1, "Art", "Open") is gone - the hull bursts in the air; the extension of the climb is outpainted from the air fight's backdrop where the barge stops, not from screen 13's.

Open, for the build: whether the hero keeps control between the burst and the slowdown (and with it, from the burst on, no wound and nothing left firing - the rule of Part 1 moves to the burst); what the hero's shots do to the drone; how the Cordon flies at the flight's speed with a world that moves (the level-1 scene stands on a still screen); the sound under the Cordon - its hum, its track or silence - between the flight's track cut at the burst and Legendary.

## Decided 2026-11-12, after 3.0.126: the drone put off
The drone and the Cordon (steps 1 and 2 above) are put off to a later version and kept as they are written - not built in 3.0. The titles and the climb into the stars stand. The end of 3.0, in order:
1. The hull's lives run out: it cracks and bursts in the air. Nothing flies out of it.
2. **The flight slows down**, and from here the hero is not his own (input cut). The tiles of the road come in again, and the main barge with him on it stops beside them.
3. The titles over that picture, and the climb into the stars of the menu (Part 2).

Of "Open, for the build" above, what stays for 3.0: whether the hero keeps control between the burst and the slowdown (and with it, from the burst on, no wound and nothing left firing); the sound between the flight's track cut at the burst and Legendary. The drone's and the Cordon's questions go with them.

## Decided 2026-11-12, stage 19
The forks of the build chat (arena 3's stage 19), as answered - all as proposed:
- **The homes**: three units of rules - `Game.Breakup` (the hull's end: the throe, the burst, the order of the series; the Ram's), `Game.Wreckage` (the pieces of the burst hull, cut from its layers by the Ram's painter) and `Game.Landing` (the end of the flight, the game's to carry out). Not a stretch of `Game.Pieces`: a barge's picture is one layer, the hull's several, with trails and blasts.
- **Where it bursts**: not where the last orb found it - low over the hero after a dive, at the right edge after a charge's brake - but after a throe of a second, over the middle of the screen at the hang's height, about 150 units over the head of a hero on the main barge.
- **The controls**: cut at the last life (as Part 1 had it at the blast); the orbs that leave his body carry him onto the main barge's deck if he is not on it (`Game.Hoist`'s way), wherever he was - a small barge, the lift, the air.
- **The aura**: one ring - the moon form comes off as the ice form does, its ring of its own dark orbs, and that ring is the shield; no second aura (the aura's orbs come out of the matter of the screen, and aloft there is next to none).
- **What is quenched**: nothing is frozen - everything plays out with no teeth. The monsters' bullets and the shrapnel burst where they fly, the shells in the air burst harmless, no small barge comes in; the barge the magnet held falls as a knocked one does, burning; a thrown barge flies on and may break on the main barge (a rock, no wound); the knocked barges burn on. At the slowdown every small barge left leaves off the left edge, fast.
- **The sound**: no music between the cut and Legendary, but not mute - the groan of the crack, the burst, the blasts of the series, the flight's wind dying with the slowdown, the dock; then about two seconds of silence, and Legendary comes in from it over two seconds - the titles' T0, which F2 will hang on.
- **After the hand-over, till the titles are built**: the picture stands, Legendary plays, Escape opens the menu and "continue" comes back to the same picture. For a short while: the next stage rebuilds it (the titles).

## Decided 2026-11-13, after the first look at 3.0.128
Changed in the same version, before its commit:
- **The controls stay his** to the end of this stage: the hero is not stilled at the end till the camera has gone up (the titles, a later stage). Of "The controls" above only the carry stays - the orbs that leave him take him onto the main barge if he is not on it; then he walks and shoots as he likes, spared.
- **No drop through the main barge**: the key down does not drop him through the main barge's deck, nor through the road's - under either is the abyss, and there it is a needless sacrifice. It holds the whole air fight, not only its end.
- **The barge docks against the road, and the world carries both to the left edge**: the road's edge comes in and meets the main barge waiting at its berth; docked, the barge rides on with the road, and the world stops with the barge against the left edge of the screen and the road from its side on - the left edge is a wall, the right one the sealed door of the arena: nowhere to fall, so no way to end himself.

## Stage 19 as built (3.0.128)
As decided above; the numbers are first guesses for the live run.
- **The last life** (`Game.Moon`, `WoundHull`): an orb sinking into a hot part takes it - none while he lies dead, so the win is never a corpse's - and the last one ends the fight (`EndTheFight`), in the same tick: the landing begun (`Game.Landing`), the music stopped (`FCurrentMusic` none), the jets' loop stopped, the hull's bar retired - up out of sight as it came down (`THullLives.Retire`) -, the magnet's catch let go (`LetGoOfTheCatch`: a barge in its beam dropped into the flock as a knocked one, `TBargeFlock.Drop`; one seized, a wreck at its face, flung under the screen), the fire quenched (`QuenchTheFire`: the monsters' bullets burst, the shells in the air a barrel's blast each and cleared), the flock closed, the Ram wrecked, the moon form taken off (`THenshin.RemoveForm` - the ring of `MoonOrbTint`, `THeroOrbs.ShedMoonSuit`, the mercy as long as it stands), and he is carried aboard (`CarryHeroAboard`: held, the hoist's way to the deck where it is, followed every tick, let go on it).
- **Spared** from then on (`TLanding.Running`): `HurtHero` and `StrikeHero` do nothing, the monsters' bullets, the thrown barge, the Ram's touches, sweeps, fire, column and shells strike nothing; a pit brings him back with no word and no wound. No death can come, so no restart can undo the win. The keys and the gun stay his (decided 2026-11-13); the key down drops him through neither the main barge nor the road (`HeroOnTheHarbour`), in the whole air fight.
- **The throe** (`Game.Breakup`, `TRam.Wreck`, `TickBreakup`): the magnet, the mortar, the charge and the dive cleared, the armour stowed. The crack on the next tick - a machine's blast at the hull's middle, `hullgroan.wav`, a jolt of 0.35. Over `ThroeTicks` 33 (1 s) it is carried by a smooth step from where it was to `BurstLeft` (the middle of the screen) and `BurstLift` (the hang's 184: its bottom at 168), shuddering 4 degrees in 5 ticks; small blasts (a barrel's, `bottle.wav`, a jolt of 0.15) at the top plate's tear, the rear block and the bow's flank at ticks 6, 15 and 24; its jets lit 4 of every 7 ticks - each catch heard (`jetfire.wav`) - and dead the last 8.
- **The burst** at tick 33 (1 s after the last orb): the hull is no more (`Present` false - no touch, no sweep, nothing drawn of it); a boss's blast at its heart with its after-pops, `hullbreak.wav` and `platform.wav`, a jolt of 1. Its pieces (`TRamPainter.Shatter`, `Game.Wreckage`): its picture - the well, the chassis, the hull and its worn copy, one over the other - cut 3 by 2 into six of about 56 by 64, then the two engine bays (42 by 36), the two nozzles, the magnet and the mortar - 12 - each from its place, mirrored and turned as the hull was, with half the hull's way, out from the heart at 0.3-1.0 and up at 0.5-1.3 units a tick, tumbling 1-4 degrees a tick. The moon's pull is 0.05 a tick (a barge piece's 0.25): from the middle of the screen a piece is under it in about 4-4.5 s; the flight's wind closes 0.8% of the gap to the world's pace a tick, so they fall behind, slowly at first. Each trails fire and smoke (a `TBargeFire` of 12, the knocked barges' look, the smoke streamed back by 0.6 of the wind) till it is gone.
- **The series** (`Game.Breakup`): the six hull pieces and the two bays blow up once each - a machine's blast at the piece, `platform.wav`, a jolt of 0.25 - in the dice's order, the first 8 ticks after the burst, then every 9-14 ticks: 8 blasts over about 2.8 s, done about 3.8 s after the last orb. A piece fallen lower than `WreckBlastFloor` 280 blows up no more - the decks are under it and the blast would stand on the head of the hero (about 320 on the main barge): the fastest of the bottom row gets there about 2 s after the burst, the rest later, so most of the 8 come; a skipped one is silent. With the crack, the three small blasts and the burst: up to 13 in about 3.8 s. The nozzles, the magnet and the mortar only fly.
- **The flight runs on** at its pace (4 units a tick) for `LandingSlowAfterTicks` 66 after the last orb (2 s); then the slowdown (`TLanding.SlowsDown`): the belt down to a stand over `LandingSlowTicks` 198 (6 s, `TBelt.Run(0, 198)`; 396 units run), `flightdown.wav` - the wind and the engines winding down; the small barges let go (`TBargeFlock.Disperse`: off along a lane at 3 a tick, the escort too; none comes in); the main barge berths (`TBargeRide.Berth(LandingBerthTicks)`, 50: from its drift to its station 176..336 and its line in 1.5 s, going on the way it went at first by 24 at most, a cubic eased to a stand) and waits there.
- **The road comes back** (`TLanding.RoadIn`, `TRoadEnd.Arrive`): the tick the slowdown's travel left (`TBelt.RampTravelLeft`, the speeds to come summed) brings the stop - `LandingRoadStop`, a barge's length, 160 - within 8 of the right edge, its edge comes in there, its pad woken under its tiles; from then it rides the belt and stops exactly there. About 0.3 s into the slowdown, at nearly the flight's pace.
- **The dock** (`TMoonGame.DockBarge`, `TBargeRide.Dock`, `Ride`): the tick the road's edge comes against the right side of the barge, berthing or waiting at its berth - about 1.8 s into the slowdown, 3.8 s after the last orb - the barge is set against it (`bsDocked`), `bargedock.wav`, rocked by 3, a jolt of 0.1; from then it rides the world with the road, and stops with its left edge at the screen's: the barge 0..160, the road from 160 on. The far plane, the fangs and the city stand with the belt (`TLanding.Stands`), 8 s after the last orb.
- **The hand-over** (`TLanding.HandsOver`) 66 ticks (2 s) after the stand - 10 s after the last orb: `credits.ogg` once, in over 2 s. The picture stands from then on: the barge against the left edge, the road to the arena's sealed door, the hero free on them and spared, nothing firing at him. Escape opens the menu; "continue" comes back to it.
- **What falls where**: the burst is over the middle, its pieces fan out about it, the lower row falling past the main barge's deck about 2.5-3.5 s after the burst - behind the pads (drawn after the Ram's body, before the pads), never over the hero. The small blasts of the throe are on the hull, over him by about 120 at the least.
- **Debug**: the key O on the finisher's stretch takes the hull to its last life, a second press takes that one - the end at once, no window to wait for.
- **Sounds** (`tools/sounds/finale.py`): `hullgroan.wav` 1.1 s (four inharmonic plates beating and sliding down, crackling wiring in fits, a turbine's whine falling); `hullbreak.wav` 2.6 s (a deep blow sliding from 70 to 24 Hz, tearing metal, a roll of thunder, debris rattling, thinning); `flightdown.wav` 6 s (the wind's band sinking from 2.2 kHz to 260 Hz and the engines' drone sliding an octave down, both dying with the belt's own step); `bargedock.wav` 0.8 s (a dull thump, a latch, a short rattle).
- **Tests**: `Tests.Game.Breakup` (new) - `TBreakupTests` 13; `Tests.Game.Wreckage` (new) - `TWreckageTests` 11; `Tests.Game.Landing` (new) - `TLandingTests` 8; `TRamBreakupTests` 6 (new fixture in `Tests.Game.Ram`); `TBeltTests` +3; `TRoadEndTests` +1; `TBargeRideTests` +6; `TBargeFlockTests` +5; `THullLivesTests` +4; `THeroOrbsTests` +1 and one ask more. The tables: `docs/testing/game.md`. Written without a compiler, as all here.
- First guesses for the live run: the throe's second and its shudder; where it bursts; the pieces' cut (3 by 2), their scatter, hop, tumble and the moon's 0.05; the wind's 0.008; the fire's look on a piece (the barges'); the series' 8 blasts and their 9-14 ticks; the two seconds before the slowdown and its six; the road's coming in and the dock (about 1.8 s into it); the ride to the left edge; the dock's rock; the silence of two seconds before Legendary; the four sounds' levels; the bar retiring as the hull cracks; the carry's pace (the hoist's 3 a tick) from a small barge high up.
- Not built, on purpose: the titles (F1-F6) and with them `gsFinale`; the boss def's `ending` key of Part 1 - the Ram is no monster of `monsters.json`, its end is its own; the scene `s13-end` - the belt, the road and the barge are not the scenes' vocabulary.

## The final picture (3.0.129)
Stage 19a of arena 3 (`chase-backdrop.md`, "The farm"): the picture the
world stands on at the end of the flight is no longer the empty tail of the
crater. Behind the docked barge and the road, at the end of the city's
strip, stands the farm - a long dome of glass on a diagrid, the greenhouses
under it glowing magenta, amber and blue, burning out of step; their light
fills the dome's air and spills onto the crater floor in front of it. The
sun stands behind the dome, pink; its glare over the dome is softened to
0.3 so it does not wash the greenhouses into a haze. The city's brake parks
the dome in the frame by the end of a fight of two minutes and more; a
shorter fight stands with the dome coming in on the right. The titles
(F1-F6) and the climb will stand on this picture.

## Part 1 - the end of the fight
What the code does at a boss's death today (`meLevelComplete`): the suit comes off, win.ogg plays through, a timer of 400 ticks runs, then the next level loads - past the last one, the menu opens. Two of the three are wrong here, so this boss gets an ending of its own:
- A key in the boss def (`"ending": "finale"`, `"advance"` by default) turns the victory track off and, when the timer dries, starts the titles instead of loading the next level.
- The suit still comes off in a ring of orbs (black ones: the moon form), as the ice form does.
- **From the blast on the hero cannot die.** A death here would restart the whole fight after the victory. At the blast the napalm puddles, shells and the machine's last bullets are cleared, and the mercy window is held until the titles begin. Input is cut at the same moment; the hero stands where he stood.

The first seconds are a scene of the level (`s13-end`, existing vocabulary only: music, jolt, shake, sound), then a new action `finale` hands over to the titles:

| time | what |
|---|---|
| 0 | the blast; the boss track is cut at the first flash, not faded - the machine takes it with it |
| 0-3 s | the wreck burns, debris lands |
| 3-6 s | silence: only the crackle of the wreck; the suit comes off |
| 6 s | the first note of Legendary comes in from silence (fade about 2 s); the titles begin |

The 6 s are a first guess for the live run.

## Part 2 - the titles
A game state of its own (`gsFinale`, unit `Game.Finale`), not a scene: the level's scenes keep the player's control and live inside the playing state, the titles take it away and draw the menu's sky. The state ticks only the ambient layers of the frozen world (smoke, sparks, lamps), the sky and the logo; the hero, the monsters, the pads and the bullets stand. HUD and cursor are off.

### The timeline
Times are from the first note (T0); the slots marked "beat map" are filled once the track is analysed (see "Sync").

| time | what |
|---|---|
| T0 | the track fades in over about 2 s |
| T0 + 0.5 s | "Computer Dragon presents" fades in over 1 s, at the middle of the frame |
| first strong beat (beat map) | **the flash**: the line goes out in the same tick; the logo's letters come in at once; the halo spikes to about 2.5 times its level and decays to the breathing level over 1.5 s; a burst of embers; a short white flash (3 ticks); a jolt of 15% |
| flash + 1.5 s | the line under the logo fades in over 1 s |
| a musical turn (beat map) | **the climb** starts: about 10 s, eased at both ends; the picture, the logo and the line ride down and out of the frame |
| 40% of the climb | the stars of the menu come in over the darkening extension |
| last quarter of the climb | the menu's sky (nebula, stars, moon) crossfades in over everything |
| after the climb | the last line over the sky |
| the end | the exit (see "Open") |

A fade, not the typewriter, for every line: the terminal's key beep would fight the song.

### The flash
The menu logo is `TMenuLogo` (letters, a halo computed from their alpha, embers drifting off their outline); the menu already draws it centered at 1.5 times its size for the trailer frame. New: `Flare(Strength)` on the logo - a decaying multiplier on the halo and a burst of extra embers. The finale takes the menu's logo by a property and does not build a second one.

### The lines
- "Computer Dragon presents" is the menu's credits line (`creditsLine1`), reused.
- Under the logo (one of, to taste; the longer line is 44 glyphs, about 590 units in the big font against a frame of 512 - two lines, or the small font):
  - "The Master will return in a new chapter and a new form" / "Мастер вернётся в продолжении и в новом облике"
  - "To be continued. The Master will return in a new form." / "Продолжение следует. Мастер вернётся в новом облике."
- The last line, candidates: "Next stop - Selene." / "Следующая остановка - Селена."; "Thank you for playing." / "Спасибо, что играли."; the old farewell reworked (the new levels are coming, follow the updates).
- The old farewell (`endingLine1-5`: "the classic levels of 2008 end here") is no longer true - level 2's end is new content. Its lines are rewritten or retired together with this.

### The climb
- The picture and what rides on it stand in the world: the world is the bottom screen, the extension (one more screen, outpainted upward from the arena's backdrop to black) is above it. The camera goes up by one screen.
- The stars: the menu's own `TStarfield`, `TMoonGlobe` and nebula. The menu's `DrawSky` gets an opacity (1 by default, so the menu and the story screen do not change). Because the climb ends on the very sky the menu draws, the exit is not a cut: the items come in over a sky already there.
- Optional polish: the stars drift down at their three depth rates while the camera climbs (a vertical parallax in `TStarfield.Draw`). Without it they stay in their own motion, which is enough.

### The camera - the one real risk
Everything in the frame is drawn through `FSprites.Origin`, a point of whole units (56 uses in the sources), with some layers taking an explicit offset besides. A slow pan in whole units steps 3-4 px a tick at 1080p - and the eased start and end of the climb are slower than one unit a tick. Ways, in order of preference:
1. Draw the whole world into a target texture at the output size and copy it to the frame with a float offset: no layer is touched, the pan is sub-pixel, the world stays alive. The logical size of the renderer is dropped on a target - scale by hand. `SDL_SetRenderTarget` is bound in `Sdl2.Core` and TitleCard renders into a target; the game itself never has. **A spike comes first** (stage F1) and decides.
2. A float origin through the layers: the blast radius is those 56 uses and every explicit offset. Only if (1) fails.
3. Whole units with the steps accepted, the climb faster at its ends. The fallback.

A camera offset is also what the train level's "screenUp" will need.

## Sync
- The track's own time is the clock. Two ways: ticks since `PlayMusic` (33 Hz, drifts a little against the audio device, a constant lead for the mixer's buffer), or `Mix_GetMusicPosition` (SDL_mixer 2.6+, a delayed import with the ticks as its fallback). The first sync-critical moment, the flash, is within seconds of the start, so ticks are enough; measure live before anything more.
- The beat map: onset and beat times of credits.ogg by librosa, the cue times of the table above read off it. Needs the track.
- No mixer (the DLL is missing): the titles still run, by ticks; the track's length is kept in the timeline data for that case.
- The end of the track in the menu: there is no detection today (no `Mix_PlayingMusic` in `Audio.pas`). Added, so the menu theme (moon.ogg) takes over when Legendary ends, instead of a silent menu.

## Art
- **The extension** of the arena backdrop upward: one screen (1440x1080 at backdrop density, within 2048 px), outpainted from the finished backdrop of screen 13 as screen 11's was (the seam blended over 120 px), the strata thinning into black; the top edge forced to the sky's black in code, so the stars stand on a clean ground. If the backdrop's top is already near black, a gradient will do - decided on seeing it.
- The wreck (open): the hull's own layers darkened, smoke and sparks as boss 1's wreck has - no new drawing.
- Nothing for the stars: they are the menu's.

## Stages
Each its own commit, each run live. The titles are tried on any existing screen through a debug key that puts the hero on it and starts the finale - so F1-F7 do not wait for the boss.
- F1. **The camera spike.** The target texture pan of a live frame, go or no-go.
- F2. **The state.** `gsFinale`: the frozen world with ambient layers alive, HUD and input off, the timeline director, the track in, "Computer Dragon presents". The debug key.
- F3. **The flash.** `TMenuLogo.Flare`, the jolt and the white flash, tuned to the beat map.
- F4. **The lines.** The line under the logo, the strings of both languages.
- F5. **The climb.** The camera, the extension (placeholder: black), the star opacity.
- F6. **The sky and the exit.** The menu sky's opacity, the last line, the exit to the menu with the track going on, the end-of-track detection.
- F7. **The end of the fight.** Built as stage 19 of arena 3 (3.0.128, "Stage 19 as built"): the unkillable hero, the silence, the hand-over at Legendary's first note. Left for the titles: `gsFinale` taking over at `TLanding.HandsOver`.
- F8. **Sync, tests, docs.** The beat map in the timeline, the black-box tests of the timeline director, the codebase maps, the version.

## Open
- ~~The wreck: stays (darkened, smoking) or a clean floor.~~ None: the hull bursts in the air (2026-11-12).
- The hero's pose at the finale: where he stood, or a short scripted walk to the middle.
- The wording of the line under the logo and of the last line.
- The exit: automatically at the end of the track, or by a click on "Main menu" (the old farewell's two lines, with the author's link), or both; whether Escape skips to the last line.
- ~~The track: file name, loudness against the other tracks, its length.~~ `credits.ogg`, about -14.2 LUFS (the boss tracks -14.5 and -14.7, the tunnels' `lunar.ogg` -16.4), 238 s (2026-11-08).
- Whether the titles are a data file (a timeline in JSON) rather than code: the game has at least two more endings ahead (the shift to Selene, the end of the hero), and each would be a timeline.

## Risks
- Escape on the menu resumes a loaded level: after the finale the level must read as finished, or the menu resumes the titles.
- The mercy window and the cleared fire must hold for the whole of the silence and the titles; a stray napalm puddle killing a hero who has won is the worst possible ending. Since 3.0.128 it is not a window: from the last life on the landing spares him outright, and nothing of the fight touches him.
- The flash lands on the beat only as well as the clock does: measure the drift over the first 30 seconds before trusting ticks.
- The flash against a dark arena can look like a stage effect; its strength is a live-run knob.
