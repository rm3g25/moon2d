# The flight to the stars: the build of the titles

Status: the build plan decided and the track's beat map taken (2026-11-14); stage T1 - the camera - built on the stand, its path laid a third time after two looks and found tolerable at the third (2026-11-14, below); the ground for a lifted eye decided, its first sheet generated and laid as a plane on the stand; the flight through the main dome - the sign, the rib, the sun, the first of the climb - laid on the stand and taken after three looks ("The flight through the dome", below); nothing of the titles in the game yet. The design is `finale.md` ("Decided 2026-11-13: the gate, and the flight to the stars"): its order, its flight, its stages T1-T6. This file is how that design is built: the track's map, the timeline hung on it, the camera, the file of its path, the homes of the code, the order of the work, and the journal of the stages.

## Decided 2026-11-14: the build

- **The wait is filled with credits.** From the logo's flash to the flight's start the track plays 105 seconds of verses, the hero free under the logo and nothing changing: a player may take it for the end and leave before the flight. So the wait carries real titles: three lines under the promise, one at a time, each coming in on the downbeat that starts a section of the track and gone before the next - the lines of the menu's credits screen as they are (`creditsLine3`, `creditsLine4`, `creditsLine5`, both languages), in the small font. The last is gone a bar before the flight: the camera leaves a frame that holds the world, the logo and the promise. A line for the music is open - the game has no such string.
- **The flight keeps its 58 seconds** and lies on the track with no fitting: from the bar the band drops out on to the bar it comes back on are 28 bars, 59.05 s ("The timeline").
- **The states.** The titles' head - the card, the flash, the promise, the credits - lives in `gsPlaying`: the hero is still his own. `gsFinale` is the flight alone, from the camera's first tick to the sky of the menu (input cut, Escape blocked, no HUD). `gsEnding` is rebuilt into the last screen.
- **The clock** is the track's own position where the mixer gives it (`Mix_GetMusicPosition`, SDL_mixer 2.6, not bound yet - a delayed import), the ticks since the track's start where it does not. Before the flight Escape opens the menu as it does now; while the titles' clock runs the menu pauses the track and "continue" resumes both.
- **Bank and pitch are keys of the path**, not derived in the game: what the stand shows is what the file says.
- **The approved city is not moved** to open a way for the camera. The path is laid through the gaps there are; a card too near the eye fades (stage T3).

## The beat map

`bin/music/credits.ogg` as `tools/finale/beat_map.py` hears it (librosa): 238.36 s, 112.35 bpm steady from end to end, a beat 0.534 s, a bar of four 2.136 s. The first pulse is heard at 10.84 s; the band comes in on a kick at 17.21 s, and the bars are counted from there. Its sections, and how loud each plays:

| from | to | level | what |
|---|---|---|---|
| 0 | 17.21 | -26.8 dB | comes in from afar: a pad, a pulse from 10.84 |
| 17.21 | 36.22 | -19.3 | the band in, the first verse |
| 36.22 | 67.94 | -18.3 | |
| 67.94 | 91.14 | -17.3 | |
| 91.14 | 122.74 | -16.9 | the last before the break |
| 122.74 | 131.17 | quiet | the break: the band drops out on the bar; its kick comes back alone at 129.08 |
| 131.17 | 145.94 | | the band back, building |
| 145.94 | 164.91 | -13.9 | the loudest chorus (the low end in at 145.9, the full sound by 148) |
| 164.91 | 181.79 | -18.0 | the bridge, no drums |
| 181.79 | 223.91 | -15 | the band back (a hit at 180.98 leads it in), the last choruses |
| 223.91 | 238.36 | | the last hit at 231.9, the end at 236.3 |

A trap of the analysis: the strongest onset of the band's entry is its snare at 17.74, a beat after the kick; taken for the downbeat it puts every cue half a second late. The kick is the one: every section above starts on a bar counted from 17.21.

## The timeline

Seconds of the track, which starts with the hull's burst (T0; `finale.md`). They are the `cues` of `bin/finale.json`; every one but the hand-over stands on a downbeat.

| track | flight | what |
|---|---|---|
| 0 | | the hull bursts, the track starts |
| 9.0 | | the hand-over (`TLanding.HandsOver`): the world has stood for two seconds |
| 10.84 | | "Computer Dragon presents" in; gone by 16.7 |
| 17.21 | | **the flash**: the logo flares, the gate's lamp goes amber (`TGate.Promise`) |
| 19.32 | | the promise under the logo |
| 36.22, 67.94, 91.14 | | the three lines of the credits, each gone before the next; the last gone by 120.65 |
| 122.74 | 0 | **the flight starts**: away - the push and the rise |
| 129.08 | 6.34 | the kick comes back: the eye goes left |
| 131.17 | 8.43 | the band is in: low along the strip, at speed |
| 143.45 | 20.71 | the TEK sign stutters as the eye goes by it (a bar and a beat before the chorus) |
| 145.94 | 23.20 | out through a cell of the main dome's back, close past its ribs, banked - and the sun floods the frame on the same beat |
| 164.91 | 42.17 | the drums leave: out through the dome's crown, the Moon below |
| 181.79 | 59.05 | the band comes back: the stars of the menu, the last screen |
| 236.3 | | the track ends; the menu's theme takes over |

The flight of `finale.md` was laid out in 58 s by guess: lattice at 16-22, inside to 30, the sunrise to 38, the Moon below to 50, the pitch to 58. The track asks for nearly the same, a little later through the dome.

## The camera

- **One eye, no head to turn.** x along the strip, y up, z into the screen, bank and pitch. It has no yaw: it always looks straight into the depth, so a flat picture is always seen face on and never shows its edge - the flight's "turn to the left" is a slide to the left and a bank. This is what keeps the city from reading flat.
- **The layers get a depth from their speeds.** At rest the eye is the layout's camera (`camera` of `bin/chase-backdrop.json`: horizon 238, base line 266, focal 1024), 28 units over the crater floor. A layer riding K times the city's cruise stands K times as near, 1024 / K from the eye: the play layer 93 (K 11), the fangs 154, the near hills 219, the domes' base line 1024 (the city's cards from 910 to 1225 by their feet), the ridge 2926; the sun at infinity, fixed on the screen. A push of z brings a layer from depth d to d - z, so the near layers come on faster; a lift of y sinks a layer by y times its nearness. At rest every number of the chase is as it was. A push is a flight through the picture, not a crop of it: a layer the eye passes is gone, and what it hid lies bare - the near hills hide the foot of the floor's band.
- **Bank** turns the whole frame about its middle; positive - the left wing down, the picture clockwise. It bares the frame's corners: a banked frame is drawn wider than the screen (626 by 564 units at 25 degrees) - stage T3.
- **Pitch** moves the whole frame along the world's vertical by focal times its tangent; positive - the nose up, the picture down. Only when nothing but the sky, the sun and the limb is in the frame.

## The file of the path

`bin/finale.json`: `track` (the file, its length, tempo and first downbeat), `cues` (above) and `path` - the eye's keys by the seconds of the flight:

```json
{ "t": 6.34, "dx": -45, "y": 0, "z": 0, "bank": 0, "pitch": 0, "note": "cast off through the break" }
{ "t": 11.6, "x": 1730, "y": 0, "z": 0, "bank": 0, "pitch": 0, "note": "over the outskirts, the satellite dome coming" }
```

- `x` - the place along the city's strip that stands in the middle of the screen at the domes' base line. `null` - where the world stood: that depends on how long the fight was (the eye at 2412 after a fight of 220 s, at 2289 after 150, at 1492 after 60).
- `dx` in the stead of `x` - so far from where the world stood, below 0 to the left. The eye's way off the picture is in `dx`: the play layer leaves the same way after a fight of any length; the landmarks of the strip are in `x`.
- A key to the right of the one before it is held at that one's place: after a short fight the world stands early (at the satellite dome after a minute), and the eye never flies to the right - it waits there for the keys that lie to its left.
- `y`, `z` - from the eye's rest, the camera's units. `bank`, `pitch` - degrees. `note` - for the reader.
- **Between the keys** a monotone cubic, a channel at a time (Fritsch-Carlson). The slope of a span is its rise over its time. A key's tangent is 0 at the two ends and where the slopes either side of it differ in sign or one is 0; else, with `b` and `a` the times before and after it and `sb`, `sa` those slopes, `(3a + 3b) / ((2a + b) / sb + (a + 2b) / sa)`. Inside a span of length `h`, at the share `s` of it, from the value `p0` with the tangent `m0` to `p1` with `m1`: `(2s^3 - 3s^2 + 1) p0 + (s^3 - 2s^2 + s) h m0 + (3s^2 - 2s^3) p1 + (s^3 - s^2) h m1`. It passes through every key and never past one - close past a rib that matters - and stands still at its two ends. The game is to play the same arithmetic.

## The homes

Proposed for the game's stages; none written yet.

| unit | what |
|---|---|
| `Levels.EyePath` (Core, new) | the path: its keys and the cubic, the eye at a second. No SDL |
| `Levels.Finale` (Core, new) | `bin/finale.json`: the track, the cues, the path; the level names the file in a `finale` section, as `farPlane` names its layout |
| `Levels.FarPlane` | the eye in the projection - `Nearness`, `ElementLeft`, `FramePoint`; at rest the chase's numbers to the bit, held by a test |
| `Render.FarPlane`, `Render.DomeFrames`, `Levels.Farm` | take the eye; draw wider than the screen for a bank |
| `Render.Target` (Core, new) | a frame drawn into a target texture and put on the screen moved, scaled and turned - the product of the spike |
| `Render.Flare` (Core, new, T4) | the sunrise: halos, the streak, the exposure curve |
| `Game.Finale` (Game, new) | `TFinale` - the clock from T0 and the cues. No SDL |
| `Hud.Titles` (Hud, new) | the card, the promise, the credits, the last screen |
| `Menu` | `TMenuLogo.Flare`, an opacity for `DrawSky`, the Earth in the Moon's place |
| `Audio` | the track's position, the end of a track |
| `Game.Moon` | the wiring: `gsFinale`, `gsEnding` rebuilt |

## The order

Each stage on the stand first, looked at, then in the game; one at a time.

1. **T1 on the stand** - the camera done; its third path looked at in motion and found tolerable, two faults of the look mended (below).
2. **The spike** (F1 of `finale.md`): a target texture behind a debug key. It decides two things at once - the play layer drawn as one card that grows and leaves, and the frame turned for the bank. Fallbacks: the renderer's scale for the play layer, the bank by turning vertices.
3. **The titles' head** (F2-F4): the clock, the card, the flash, the promise, the credits, the lamp; the debug key X goes. Before the camera: it is cheap, it tries the sync, and the game's T1 then starts with the logo standing in the world.
4. **T1 in the game**: the eye in the far plane, `gsFinale`, the play layer leaving as a card.
5. **T2-T6** as `finale.md` has them; its F5 and F6 are inside T5 and T6.

## Stage T1 on the stand (2026-11-14)

The mode "the titles" of `tools/chase/stand.template.html`: the world stands where the flight left it (the mode "the flight" under it, the fight over at N seconds), and the eye flies the keys of `bin/finale.json`; the time of the stage is the flight's own.

- **The eye** (`Eye`, `eyeNearness`, `eyePoint`, `underEye`, `eyeSpan`, `atRest`): a layer drawn where it stands at rest is carried as a whole - scaled about the middle of the horizon by its nearness now over its nearness at rest, and sunk by the lift times its nearness now. Every building, with its lights, its paint, its glass and the emblem, is one such layer by its feet; so are the train, a searchlight's beam, the ridge, the near hills and the play layer. The frames, their shadows, their beacons and the farm's meshes go through `frameProject`, which takes the eye; the farm's sources, the sun's cover (`spanOnScreen`) and a beam's glints (`beamUnderEye`) are found where the eye has them. A layer nearer than 12 units is behind the eye and not drawn. At rest nothing is carried: the chase's and the flight's frames are the same to the pixel as before (compared at 62 and 120 s of the chase, 150 and 235 s of the flight).
- **The path** (`pathTangents`, `pathValue`, `eyeAt`, `flyEye`): the cubic above. `turnFrame` banks and pitches the canvas; no wider frame yet.
- **The play layer** (`drawTitlesPlay`, `drawHarbour`): the game's own pictures where the game draws them - the road's tiles from the pier's edge 160 on (`tek-road-tile`, 17 of them), the facade on them (`s13-gate`; its lamp in units from the picture's top-left, as `Game.Gate` has it, amber in the titles - the flash is 105 s behind), the main barge docked against the pier with its deck on the road's line 352 (`barge-5` of `pads.mset`, 160 by 18), the hero on its deck (the standing frame `1` of `hero.mset`, 64 units from the stern) - and the menu's logo (`logo` of `ui.mset`) in a glow where it flares, the promise under it: the logo's fire and the promise's font are stand-ins still. The first build had the barge and the hero as dashed boxes, a cell too high (the deck at 336): for six seconds they are the main thing in the frame, and a box is what gets judged. Not on the stand: the lamps of the barge's rig.
- **The page**: the switch "the titles", the path's keys in a box, one to a line as the file has them, flown at once by "Fly these keys"; the timeline lists the keys and the track's cues inside the flight. `build_stand.py --track` puts the track inside: the titles play under it at 1x.
- **The address bar**, for shots: `?flight=220` (the flight, the fight over at 220 s), `?titles`, `?keys=[...]` (keys for the path's), `?t=12.5` (paused there), `?bare` (no guides), `?shot` (the stage alone at its own pixels). A frame: `google-chrome --headless=new --enable-unsafe-swiftshader --window-size=1440,1080 --screenshot=f.png "file://.../chase-stand.html?shot&flight=220&titles&t=7.5"`. No `--virtual-time-budget`: with it the page never comes to rest.

**Decided after the first look (2026-11-14).** The first path pushed the eye 180 to 440 units in before the pan: through the near hills, which stand 219 away. The rise over the logo was liked; from the turn to the left on, nothing was. Without the hills the floor's band lay bare to its foot and was stretched to cover the frame, more than twice and changing as the eye came down - the ground breathed; the band rode as one sheet while the rings and the buildings rode by their depths - the domes slid over it; its far edge, faded into the ridge over 16 units and stretched to 40, showed one layer sliding on the other. What was expected of the approach was a crop of the picture, not a flight through it. What came of it and holds:
- **The floor rides in slabs** (`drawFloorUnderEye`): the band cut across into slabs 6 units deep, each carried along the strip by the nearness of its middle, its far edge fading in over the slab behind across 2 units - rows of dunes, the nearer overtaking the farther. At the flight's first tick every slab stands where the band stood. Tried first and left: every row by itself. For a sideways eye that is the exact geometry of a floor, and over a long pan it shears the painting into streaks - the painted relief has height, a floor at a grazing angle has none. A slab as deep as the relief is tall keeps the dunes whole and holds the rings to within a tenth of the pan's speed.
- **The floor's far edge is sharp in the titles** (`floorFade`): from the layout's 16 units to a soft line of 1.5 over the flight's first four seconds.

**Decided after the second look (2026-11-14).** The second path rose over the logo (24 up), went 105 in - past the play layer, which stands 93 - came down again and panned from there. Not liked: a rise that is taken back is a rise for nothing - it is simpler to fly left at once; and coming down, a dark stripe opened between the near hills and the floor - with the eye 105 in the hills sink nine units for every unit of lift and the floor's foot three, so between a lift of 3 and of 17 the band's foot is bare. That is no fault of that path: the ground of two paintings bears no lift at all ("The ground for a lifted eye", below). So, as answered to the forks of the third laying:
- **To the left at once.** "The void left of the barge never enters the frame: push first, turn after" (`finale.md`, the row "Away" of "The flight") is taken back. Left of the barge the play layer simply ends - the barge's stern, whole, against the pier over the open crater, the seamless hills and floor behind it: the truth of the scene, and the picture level 3 starts on, less the pit and the barge.
- **Cast off through the break.** The play layer is eleven times as near as the city: 46.5 units of the eye's way carry it a whole screen. The track's break - 6.34 s with no band - is that way: the eye goes 45 units, the city barely creeping, and the play layer rides off to the right, the hero last. On the kick the eye goes; by the band's entry it is at speed.
- **At the eye's rest for all of T1**: no rise, no push. The ground is the chase's own, to the pixel at the first tick; nothing is stretched and no stripe can open. A rise that is never taken back - left and up, 12 or so, held to the dome, the logo leaving down and to the right - is to be tried by keys once the ground bears it.

**Decided after the third look (2026-11-14).** The third path, flown with the track: much better, tolerable. Two things of the look:
- **The farthest strip of the floor stood still.** A slab rode by the depth of its middle, and the first slab's is three units under the horizon - a tenth of the city's pace, where the ridge behind it rides at 0.35: measured off two frames 0.05 s apart, the ridge moved 2.8 units and the floor's top six units 1.1. Geometry has those rows beyond the ridge; the picture has the ridge rising from the floor's far edge. So no slab rides slower than the ridge (`drawFloorUnderEye`): the floor's first twelve units ride with it, as its foot, and from there on by their depth - 2.8, 2.8, 4.6, 6.4 by the same measure. The first tick is as it was.
- **The fangs are back** (`fangRow`, `drawFangs`, the switch "the fangs"): the game's rules (`Game.Fangs`) by dice of the stand's own - the game's are new with every try - between the near ground and the play layer, in every mode of the stand. The row is rolled once, both ways from the layer's start: the game lets a fang go once past the left edge, and the titles' eye flies back over them. They stand 154 from the eye, 6.67 times as near as the city: on the pan they pass at over a thousand units a second, a fang about every quarter of a second, where the flight had them at 80 - a doubt for the look, as the hills' pace is.

**The path of T1**, to the main dome (the world stood after a fight of 220 s, the eye at 2412):

| flight | along the strip | what, and why these numbers |
|---|---|---|
| 0 | stand | the picture the world stands on |
| 6.34 | stand - 45 | the kick comes back. Through the break the play layer has ridden off: the gate gone by about 3.2 s (11 units of the eye's way), the logo and its line by 5.6 (34), the hero by 6.05 (41), the barge's stern a moment after the kick, at 6.4 (46.5). The eye leaves the break at 15 units a second |
| 8.43 | stand - 200 | the band is in: about 100 a second and gaining |
| 11.6 | 1730 | 160 a second from 10 s on: over the outskirts, the satellite dome coming |
| 14.3 | 1295 | past the satellite dome, along the monorail |
| 17 | 900 | the main dome comes in; the eye is slowing, 88 a second here |
| 19.2 | 760 | the run-out: the eye comes to a stand before the main dome, where T3 takes it on. No part of the design - a path stands still at its last key, and one ending at 17 at the pan's pace ran up to 215 a second on its last stretch to brake from there |

y, z, bank and pitch are 0 in every key.

**Seen on the frames** (`?shot&flight=220&titles&t=...`, from 0 to 19.2 s). The first tick: the frame of the flight's stand but for the harbour's pictures and the lamp - above the harbour and left of the gate nothing differs. The break: the play layer leaves as the table has it, the farm creeping to the right behind it. The pan: the chase's picture flown back - the hills in front at their rest's 4.67 times the city's pace (750 units a second on the screen at the pan's 160; the second path had them at 9 times), the floor in rows of dunes, the domes on their rings. Between the farm and the satellite dome the strip is a few low houses on an empty floor. Stills hide what matters here - the slide of the layers, the pace of the hills, the seams: the path is judged on the stand built with the track.

**Left for the stages to come:**
- The crater floor is still a picture in a band: its slabs hold for an eye that goes sideways at its rest's height and depth. A push or a lift stretches the painting - T2, "The ground for a lifted eye".
- A rib with an end nearer than 0.15 of the focal length (154 units) is dropped whole: close past a rib wants it cut at the eye, as its shadow is - T3. Nothing there is that near in T1.
- The bank's wider frame, the fade of a card near the eye - T3.
- A searchlight's beam is measured against its dome at rest and carried as a picture; scaled up it is soft at its root.
- The fangs in the game: `TFangRow` lets a fang go once past the left edge and rolls the next only at the right one - for the eye flying back the row is to be rolled back from the oldest fang kept, by the same rules.
- The stand's "1080p / 4K" and "real pixels" switches are not wired: the stage is 1440 by 1080.

## The flight through the dome: the first laying on the stand (2026-11-14)

The author's brief, after T1 was taken: a flight close by the flickering TEK sign; then a bank and a flight close by one of the dome's ribs; then the take-off from the ground; the sun with the flare of the opening of Episode III; and the way from the pan into all this natural, not abrupt, but breathtaking. All else was left to the laying. This reorders `finale.md`'s flight - there the lattice came first and the neon inside; here the sign comes first and the rib is the way out.

**What the city is, from above.** Under the main dome (its glass from 768 to 1280 into the depth, 170 high at its middle) the buildings stand in six rows across the eye's way: at 910 (up to 29 high), 985 (up to 46), the five landmarks at 1054 (78 to 110), 1103 and 1156 (up to 52), 1225 (up to 29). The first two rows have no gaps; the landmarks do - 33 units left of the spire, 24 right of it, between it and the pyramid `land-04`. The spire `land-03` stands at the dome's very middle (x 724), the sign on its tip: its middle 131 over the floor, its top 153 - right under the crown. An eye with no head to turn meets the rows face on: "low among the towers" cannot be flown, the rows are flown over.

**The way** (`bin/finale.json`; heights over the crater floor, the eye's rest 28):
- **The turn** (12.7 to 19 s): the way to the left gives over to the way in at one pace - 160 units a second throughout, the velocity swinging from along the strip to into the screen. No stop before the dome: T1's run-out is gone, its keys to 11.6 s stand. The eye rises as it turns: the near hills and the fangs go under it, the floor's band melts into the plane.
- **In** (20.7 s): over the dome's foot at 98 and in through a cell of its front (the triangle 724, 89, 806 - 800, 85, 816 - 766, 123, 852), its right rib some ten units from the eye - a first sweep across the frame.
- **The sign** (20.7 to 21.5 s): at 110 to 115, between the spire and the pyramid and over both, the sign 42 units to the left and a little over the eye. It grows to the height of the frame and leaves by the left edge about a hundred units before the eye is abreast of it. It stutters on the cue `neon` (20.71 s: dim, dim, dark for a fifth of a second, dim, lit); about the cue it burns steady whatever its own dice say (`neonOnCue`).
- **The bank and the ribs** (22.3 to 23.2 s): the frame banks to 14 degrees, its peak on the way out - through a cell of the dome's back (724, 145, 1159 - 791, 123, 1187 - 724, 112, 1217) at 125 over the floor, one rib eight units over the eye and one seven under it. Close by, the ribs leave the frame a fifth of a second before the eye is through: the sweep is the upbeat.
- **The sun** (23.2 s, the loudest chorus): inside the glass the sun is the dome's pink; out of it, white - and the lens floods on the cue `flare` (`flareNow`, `drawFlare`): a bloom about the disc, a streak across the whole frame, level on the screen while the world is banked, ghosts on the line through the frame's middle, the exposure blown for a moment.
- **The climb** (to 32.6 s, where the stand's path ends): up at 30 to 78 a second, quickening. Past a lift of 103 the ridge's skyline is under the horizon at any depth; beyond it is the black.

**Decided after the first look (2026-11-14).** Better; all is well up to the sign. Two things:
- **The camera jerked before the sign.** The keys about it were set each by its own need - the cell's height, the sign's - and the pace between them was not even: to the left 15, 18, 29, 23, 6 units a second over 20.5 to 21.7 s, up 20, 24, 21, 12. The keys of 19.11 to 22.3 s are set again so that each pace only falls: to the left 17, 16, 14, 11, 9; up 18, 17, 16, 15, 13. A key's values are to be read off the paces between keys, not the other way round.
- **The end: no ground beyond the ridge.** The dark plain that showed between the ridge and the horizon as the eye climbed - "a black sea nobody can read" - is gone: the ridge is the edge of the world (`drawPlane` draws no row beyond its foot). The camera goes up, the sun stays and burns, the ridge goes down the frame and out by its bottom edge (27.6 s), and the sun stands alone in the black (29.2 s, where the stand's path ends). Then the sun goes under the horizon and the stars of the menu come out - not for the stand, to be built in the game. This takes "The Moon below" out of the flight: no limb, no globe, no map of the crater from above, and the keys from 24.6 s climb to a lift of 360.

**Decided after the second look (2026-11-14).** Very well now. One thing: at the take-off the ground jerked at the last moment - the camera was being levelled, where it should simply go up. Two levellings were in the keys: the bank swung back from 14 degrees through -2 in a second and a half, turning the frame and its cover's growth under the sinking ridge; and the path came to its stand at 29.2 s, the climb slowing as the ridge left. So: the bank is let go slowly and never past level (10, 6, 2.5, 0.5 over 24.6 to 29.2 s); the climb only quickens (31, 50, 62, 69, 78 units a second) and the path stands still only at 32.6 s, in the black, where nothing shows it. And the sun: it stays where it is while the ridge goes down, then the nose comes up (the pitch from 27.6 s, to 20 degrees) - the sun sinks to the bottom of the frame and leaves by it at about 31 s. Then only the black; the stars of the menu are the game's.

**Taken (2026-11-15).** The third look, with the take-off mended: it will do. The flight on the stand is the flight - from the cast-off to the black. What is left is the game's: the Delphi code of all of it, and the join of the black to the stars of the menu, the last screen and its Earth (`finale.md`, "Decided 2026-11-13").

**Built on the stand for it:**
- **The plane** (`drawPlane`, `planeLevels`): `tools/chase/ground-top.png` - the tile, its weave taken out, not packed into the set yet - laid from under the eye to the horizon a row of the screen at a time, 448 units a tile, its light raised by a quarter. A far row takes a copy of the tile squeezed as many times as it covers rows of it (eight copies, each half the one before in height; in width from the third on). From 1500 to 3000 units off the tile gives way to its mean colour at 0.45 of its light: that far the same dunes come round as a grid, and at its own level the mean stands lighter than the ridge, a bank of fog. Not drawn at the eye's rest.
- **The band melts** (`floorKeep`): all of it up to a lift of 2 or a push of 30, none past 14 or 200.
- **A rib is cut at the eye** (`ribInFront`, 4 units before it), not dropped; one running at the eye is a wedge, thick at its near end; a rib of a frame's far half nearer than the nearest building ahead is drawn over the buildings (`frontCard`).
- **The sun's cover** (`eyeInside`): the eye inside a dome's glass sees the sun through it wherever it stands.
- **The banked frame** is grown till it covers the screen's corners (1.29 at 14 degrees) - a stand-in for the frame drawn wider than the screen, and the reason the bank is 14 and not the design's 25.

**Stand-ins and doubts, for the look:**
- The buildings near the eye are soft: the pyramid at 20.5 s is three and a half times its rest, the spire under the sign more. In the night, at speed, it may read as the near plane out of focus; if not - they fade on the approach, or two or three pieces are generated larger.
- A building flown over has no roof to show: it only sinks.
- The tall fang that happens to stand in the turn's way: the dice's.
- The flare's numbers are first guesses; so are the stutter's.
- Nothing here is measured against the game: the target texture's spike decides the bank there.

## Decided 2026-11-14: the ground for a lifted eye

Stage T2; the plane is on the stand since the first laying of the flight through the dome (above), the rest not built. What the push to the dome, the climb out of it and the Moon below stand on.

- **Why the ground there is bears no lift.** The floor's band and the near hills are two paintings with their perspective painted in, each true for one height of the eye. A painting can be stretched - at a lift of 80 the band's mounds are needles - or slid as a sheet - the stripe. And a plane at the depth d lies on the screen at 238 + (28 + lift) * 1024 / d: at a lift of 100 the domes' base line is at the bottom of the frame, at 300 - the way out through the crown - the bottom of the frame is 2300 away. All the lower frame is then ground between the city and the ridge and beyond the ridge: ground the layout does not have.
- **A plane under all of it, the relief on it as cards.** The crater floor becomes a plane from under the eye to the horizon, a picture of the ground seen from straight above laid on it and put in perspective by code (a mesh, `SDL_RenderGeometry`, as the farm's light): no row of the screen under the horizon is ever without ground. What has height stands on it as cards by its feet, as the city's buildings do - the near hills are such a row already. This also parts what the slabs could not: a painting of dunes cannot be sheared row by row, for its dunes have height; a flat picture can, exactly.
- **The band stays on top and melts.** Tried in thought and left: rows of dunes alone - they bear a lift of 30 or 40, and higher a card is seen face on where it should be seen from above, a wall of terraces; the plane alone - 28 over the floor everything on it is foreshortened 12 to 36 times, and a standing low eye reads it as a carpet. So at rest the floor's band lies over the plane as it does now, the frame the chase's to the pixel, and it fades out as the eye lifts or pushes; the chase is not touched.
- **The art**: `ground-top` - a tile of the ground from straight above, seamless both ways, a low sun beyond its top edge (prompt in `chase-backdrop.md` when it is packed). The first generation, as first prompted - a fine grain, low contrast - came as asked and was the wrong thing: laid on the plane it averaged into felt. The second - 8 to 12 large dunes across, long solid shadows toward the bottom edge over half the ground, bronze crests, no pebbles - reads on the plane at lifts of 30 and 100 as dunes at night, in the band's palette. Taken. Measured on it: it wraps (the jump across either seam is no more than between neighbouring rows); a weave of 2 px from the generator's upscale stands a hundred times over the spectrum's floor - a moire in motion - and a wrapped 1-2-1 along each axis takes it out whole: to be done as it is packed; it is a little darker than the band (30, 29, 29 against 38, 36, 36); at 640 units a tile its swells are larger and fewer than the band's mounds, at 320 to 448 nearer them - a number of the layout, to be set in motion.
- **No second sheet**: a map of the crater from above was to carry the far ground of the climb; with the ridge the edge of the world (decided after the first look at the flight through the dome) there is no far ground to carry.
- **Doubts**: where the band melts into the plane cannot be judged on stills; the far rows of the plane want smaller copies of the tile, or they shimmer in motion.

## Risks and doubts

- **The target texture** under D3D11 with a logical size: not known till the spike. A play layer drawn into a texture with a clear ground comes out premultiplied; it is put over the far plane with a blend of its own (`SDL_ComposeCustomBlendMode`, not bound yet).
- **The Moon below (T5)** - the least solved. A flat floor's horizon stays at the eye's height however high the eye goes, and the eye may not pitch down (a card from above is a flat picture). The limb is to be made: the horizon bent and sunk by the height. A globe may not be needed at all.
- **Cards close by**: the kit is 5.9 px a unit; nearer than three times its rest a building is soft at 4K.
- **The sync**: 123 s by ticks drifts against the audio device; the track's position is the cure, to be measured live.
- **A short fight**: the world stands early and the pan is short; the path's time is the track's, so the eye goes slower, not sooner.
