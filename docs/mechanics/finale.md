# Finale: the end of arena 3 and the titles that close 3.0

Status: designed (2026-10-22), nothing built. Part 1 hangs on the boss (arena 3, stages 8-19). Part 2, the titles, needs nothing but a picture to stand on and can be built first. The end track, "Legendary" (Suno, indie psychedelic of the 80s, male vocal), is made.

## The idea in one line
The machine blows up, the tense music dies with it, and in the silence after the blast the end track comes in over the very picture of the victory: a studio card, the logo flaring on a beat, a promise under it - then the camera climbs out of the tunnel into the stars of the menu, and the stars turn into the menu.

## Decided (2026-10-22)
- No victory track at the end. win.ogg already lied once, at the end of arena 2; a second time would be a joke at the player's expense.
- The boss's tense track falls silent after the blast.
- Legendary is the end track and keeps playing after the exit to the main menu.
- The order of the titles, over the main screen (the arena after the blast, the hero standing in it, no control):
  1. "Computer Dragon presents".
  2. A couple of seconds later the Moon2D logo flares in the middle, as on the menu. The fire of the menu logo is already written - this moment strengthens it and is tuned to the music.
  3. A line under the logo: the Master will return, in the sequel and in a new form (wording below).
  4. The climb: the backdrop is extended upward and goes slowly into the dark, the camera moves up, the game picture with the logo and the hero stays below. The hero cannot be steered.
  5. The stars of the menu come in, a smooth transition.
  6. A new line of text (not written yet).
  7. The exit to the main menu.

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
- The beat map: onset and beat times of legendary.ogg by librosa, the cue times of the table above read off it. Needs the track.
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
- F7. **The end of the fight.** The boss def's `ending`, the silence scene, the unkillable hero, `finale` (after stage 19 of arena 3).
- F8. **Sync, tests, docs.** The beat map in the timeline, the black-box tests of the timeline director, the codebase maps, the version.

## Open
- The wreck: stays (darkened, smoking) or a clean floor.
- The hero's pose at the finale: where he stood, or a short scripted walk to the middle.
- The wording of the line under the logo and of the last line.
- The exit: automatically at the end of the track, or by a click on "Main menu" (the old farewell's two lines, with the author's link), or both; whether Escape skips to the last line.
- The track: file name, loudness against the other tracks, its length.
- Whether the titles are a data file (a timeline in JSON) rather than code: the game has at least two more endings ahead (the shift to Selene, the end of the hero), and each would be a timeline.

## Risks
- Escape on the menu resumes a loaded level: after the finale the level must read as finished, or the menu resumes the titles.
- The mercy window and the cleared fire must hold for the whole of the silence and the titles; a stray napalm puddle killing a hero who has won is the worst possible ending.
- The flash lands on the beat only as well as the clock does: measure the drift over the first 30 seconds before trusting ticks.
- The flash against a dark arena can look like a stage effect; its strength is a live-run knob.
