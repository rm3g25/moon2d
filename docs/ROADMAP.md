# Roadmap

What comes next, in what order, and why that order. This is the one
place the order is decided; a plan says how a step will work
(`plans/<name>.md`), a mechanic's file says how a built thing works
(`mechanics/<name>.md`), and `PORTING-NOTES.md` says what state the
project is in today.

Who reads this: a session that plans, or that opens a step. A session
that builds a mechanic reads `PORTING-NOTES.md` and its mechanic's file
and has no business here - the future is not its context.

## Version lines (decided 2026-09-27)

- **2.x - the port.** 2008 restored word for word: the mechanics, the
  timings, the geometry, even the bugs; deviations only deliberate and in
  the table of `PORTING-NOTES.md`. Closed at 2.5.3 "Farewell 2008", the
  last version with the 2008 mode. The journal of the port is
  `PORT-JOURNAL.md`.
- **3.x - the continuation.** 2008 is the foundation, not dogma: the
  word-for-word rule does not hold on 3.x. 3.0.0 = 2.5.3 without the 2008
  mode (no release of its own); the release of 3.0 comes at whichever
  3.0.x finishes the external transformations, its number is not assigned
  in advance. The way back to 2008 is the 2.5.x release.

## Release 3.0: the boundary and what is left (decided 2026-09-30)

**The boundary.** 3.0 takes everything that changes HOW the existing game
is shown (the HUD, the menu, the terminal, the events) and the new
MECHANISMS of a scene - objects and effects. It does not take anything
behind an unsettled format: the tiles (they wait for the editor and for
the decision "collision grid plus objects"), the hero and the monsters
(they wait for the list of forms and the frame contract), the wide frame
(3.1). Art drawn before its format is settled is drawn twice - so the
blur of the game world stays an honest portrait of the 2008 art in 3.0,
except the backdrops: they are HD because they regenerate in minutes and
are remade for 16:9 the same way.

Why the blur at all: everything is drawn into a logical canvas of
512x384 and SDL stretches it onto the window (x2.8 at 1080p); tiles and
sprites are 64 px over 32 units - 2 px a unit against 2.8 px of screen,
a pixel budget below the screen; nearest is on already, code cannot cure
it. The menu is sharp by the same arithmetic the other way: `ui.mset`
feeds MORE pixels than the screen has and the GPU shrinks them.

**Done on the way** (the numbers as they fell): the particle emitter
(`Core/Effects.Emitter`, 3.0.14, with the smoke; moving `Menu.Embers`
onto it is still a separate refactor without a bump, the picture
unchanged), static objects and HD backdrops (3.0.11, 3.0.12), the dynamic
objects - beacon, smoke, the globe (3.0.13, 3.0.14, 3.0.16;
`Render.Globe` lifted out of `Menu.Globe`), the hero's effects as the
shroud (`Game.Shroud`, 3.0.47, in place of emitter presets). Over the
plan: the look of an explosion (3.0.18), the HD boss of level 1 (3.0.19 -
`Monsters.Disc`, drawn by code from layers, so it needs no frame
contract), and all of arena 2 and arena 3 (`mechanics/arena-2.md`,
`mechanics/arena-3.md`). The decisions on the code and the data of the
release plan are the session "план релиза 3.0" in
`mechanics/level-objects.md`. A fifth idea that arrives on the third step
is written into the plans, not into the code.

**Left before the tag** (the order is not decided):
- README for the 3.x line (it still says "Version 2 finished the original
  game"), the stale comments of `Render.Tiles` / `AttachSpriteSet`,
  `legacyTrailing` in the level JSON, the regeneration of both codebase
  maps, the release script, the menu logo (own art);
- an own icon for the exe (the dproj carries the Delphi default) and a
  version resource from `GameVersion` (not embedded today);
- the vignette and the flashes at low health (the deferred step 2.5.4);
- the rename of `THudBrush` in `Render.Brush`;
- the corridor test (a player who has not seen the game, no explanations)
  and a re-shoot of the trailer frame with the logo.
Then the tag, the release, stop. Wanting the old look means downloading
the 2.5.3 release; the game holds no museum.

## The debt of version 3.0 (recorded 2026-10-25, after stage 7b of arena 3)

Not part of the release of 3.0 - the release ships first. This is what
version 3.0 pays before the move to 3.1: a restyle with no change of
behaviour, each item its own commit without a bump, a live run after
each.

a) **Comments.** Measured at 3.0.73: 9.3 thousand lines of comments over
   55 thousand lines of code (17%; Core and Game 20-22%, the tests 8%) -
   not the density but a few thick places. The erasure test (CODESTYLE §8)
   would take 25-35% of the comment lines. By price:
   - references to 2008 line numbers (`moon.dpr 450-513` and the like) -
     19 of them, to go; find them with
     `grep -rEn '//.*(moon\.dpr|\.pas) *[0-9]{2,}'`;
   - unit headers over 30 lines - cut to "what the unit is for and what it
     does not do": `Pads.World` (124 lines), `Monsters` (77), `Levels.Pads`
     (63), `Levels.Dynamics` (49), `Scenes.Director` (47);
   - the descriptions of the kinds in `Levels.Dynamics` (15-25 lines of
     prose a class, convoy and searchlight included) - keep the contract
     (units, what 0 means, the JSON), drop the retelling of field names;
   - one-liners that repeat the name (`// hull dark`, `// Nothing on the
     way, nothing made, not started` over `Rewind`) - delete or rename
     (the ladder of names, §8); one in five in the sample;
   - JSON examples with two homes: the example in a class header and the
     one in `docs/mechanics` disagree; decide where the home is (the class
     - the schema of a kind, the doc - the data of a screen), replace the
     other with a reference.
   Not to touch: external facts and traps (why 2008 counted so, the order
   of freeing, the ties to SDL) and the contracts on declarations.
b) **`Levels.Dynamics`** - 5300+ lines, 14 kinds in one unit ("every kind
   lives in this unit"): the unit has as many reasons to change as it has
   kinds (§6). The split: `Levels.Dynamics` (the ancestor, placement,
   reading, the registry of kinds) plus a unit per family (lights: the
   beacon, the convoy, the searchlight, the beam; depth: the dust, the
   eclipse, the haze; machines: the craft; and so on). `CreateDynamic` and
   `TDynamicKind` stay the point of assembly.
c) **`SlotRoll`** (`Levels.Dynamics`) gives one value to two slots that
   differ only in the low bit: the seed is `(slot xor seed) or 1`. The
   convoy (3.0.73) walks around it with a stride over the slot
   (`ColumnRollStride`); the beacon's `FaultyLevel` does not: two
   neighbouring slots roll "out" and "dim" alike. Curing `SlotRoll` itself
   changes every roll in the game (the phases of the dust, the blink of
   the beacons, the convoy's schedule) - the picture shifts, a decision
   with a live run; curing only `FaultyLevel` is a one-liner.
d) **The chronicle and the map:** `CHANGELOG.md` and both codebase maps
   are not caught up from 3.0.72 (the sphere, the terminal) and 3.0.73
   (the convoy, the searchlight, `TConvoySchedule`, `TPieceInk`,
   `DrawLamp` / `DrawLightCone`, `DrawGlowTurned` / `PointGlowLevel`). The
   map - both languages in one commit.
e) **`TMoonGame`** - about 3600 lines: 154 methods, about 110 fields, as
   many reasons to change as there are subsystems (§6). The main trouble
   was that the class lived in the program: a test unit cannot `uses` a
   program, and everything glued into `TMoonGame` went untested. Step 0
   removed that. The order, from the isolated to the connected:
   - step 0, mechanical - done 2026-10-25: `TMoonGame` in
     `Game/Game.Moon.pas`, the .dpr keeps `RunGame`, the search for levels
     and the uses; not a line of code changed, no version;
   - the debug (`Debug*`, `Nudge*`, `HandleDebug*Key`, `DumpLevelScreens`,
     `SaveScreenPictures`, the atlas, the inspector) - whole, under
     `DEBUGKEYS`;
   - the gravel trial: `FTrial`, `FGravelScreen`, `FMedkitBank`,
     `FWaveMonster`, `FWaveBank`, `FTrialDone`, `FVictory`, `FPress`,
     `FSkyMonster`, `FHeldFlyIns`, `FCannonSmoke`, `FAimedColumn` and their
     methods (`TickGravelAttack`, `LetDown*`, `*Press*`, `*Cannons*`,
     `OpenSky`, `SpawnGuest`, `Send*Onto`);
   - the form and the orbs - done 2026-10-25: `Game/Game.HeroOrbs.pas`
     (`THeroOrbs`) - the aura, the rite, the pattern, the drop and its
     wounded, the rain, the feed, the charge of the form; probes of the
     hero and targets of a strike in place of `TMoonGame`, rewinds itself
     (`BeginLevel`, `Rewind`, `Arrive`, `Fall`), 20 tests on the boundary
     (`Tests.Game.HeroOrbs`); no version. The seam of combat:
     `PopEnemyBullet`, `DangerousMonsterAt` and `WoundByOrb` stayed in
     `Game.Moon` and leave with combat. The name `THeroForm` is taken: it
     is the hero's form in `Hero` (`hfNormal` / `hfIce`), the moon form
     becomes a value of it;
   - combat: `Resolve*`, `Strike*`, `BlastStoppedAt`, `ShardStruck`,
     `SpendBullet`, `RewardMonsterKill`, the kill streak;
   - the loading of a level last (`LoadLevel` 234 lines, `OpenSpriteSet`,
     `OpenLevelArtSet`, `CreateHud`): who sees whom depends on the order
     of creation.
   Traps: the callbacks of events and scenes (`TDirectorCues`) look at
   methods of `TMoonGame` - a piece moved out takes them, it does not know
   the game (a cycle otherwise, §12); `RestartLevel` and `ArriveOnScreen`
   rewind everything in a row - every piece must rewind itself.
   Tests (decided 2026-10-25): `Game.Moon` is not covered head-on - the
   constructor builds the renderer, the font, the sound and the menu, it
   will not stand in a suite without a window, and the methods are private
   over shared state. What is tested is the boundary of every piece moved
   out: the piece takes callbacks and rewinds itself - that is what the
   tests check. A smoke run with a hidden window (every `level*.json`,
   ticks on every screen, no crash) - a separate command beside
   `run-tests.cmd`, after the loading of a level moves out.

## After 3.0: the order (decided 2026-11-07)

Six steps, each with its plan. Levels 1-2 stay as they are through all of
them; the rule of phase 2 holds for every level: each one brings new
code, not only new files.

1. **The hero and the monsters from video** - `plans/video-sprites.md`.
   The living things redrawn from AI video on a green screen, and the
   utility that cuts the frames. First because its one hard decision - the
   frame contract of a sprite - touches hitboxes and timings, and that is
   settled before anything is drawn around it; the frame below does not
   depend on it.
2. **The wide frame** - `plans/wide-frame.md`. The frame grows to 21x12
   (672x384); a 4:3 level sits centered in it. The mechanics do not
   change.
3. **The level editor with an assistant inside** - `plans/level-editor.md`.
   For building level 3; an assistant chat that helps build, not one that
   generates levels.
4. **Level 3** - `plans/level-3.md`. The first wide level, built in the
   editor on a clean sheet.
5. **The train level** - `plans/train-level.md`. Level 4; what it needs
   exists after arena 3 - the belt of the chase and the living backdrop.
6. **Big rooms** - `plans/big-rooms.md`. A room larger than the frame
   (3x3 frames, say), the camera over it; from level 5 or so.

Two notes on the order, proposed 2026-11-07 and not decided:
- step 2 and step 6 meet at the same place - `Game.Space` (`Screen*`
  against `Frame*`) and the same 157 uses of the screen size in 28
  units; if step 2 already makes the room size a property of the level
  with the camera standing at 0, those uses are visited once, not twice.
  Separate commits all the same: first the frame, then the size from the
  level;
- the level format of step 3 should carry the room size in frames from
  its first day (1x1 everywhere for now) and the editor a canvas that can
  be larger than the frame; otherwise step 6 reopens both the format and
  the editor.

Beside the steps, in its own lane: the restyle of the 3.0 debt above,
and the ideas below when a level asks for them.

## Ideas without a place in the order

- **Several forms and several henshins, a third kind of bullet** -
  `plans/hero-forms.md` (recorded 2026-09-27).
- **Selene in the menu** - `plans/selene-menu.md` (recorded 2026-09-30;
  the texture is done, the game code is not touched).
- **One container for the resources** - `plans/wad-packing.md` (open).

## The phases (the long view)

**Phase 1 - the classic to its release.** Finite; done. The portable part
played to the gravel finale, the game speaks English, the repository is
public and tidy, the presentation made. The 2.x line closed at 2.5.3.

**Phase 2 - eight levels forward** (the new life, in small steps). The
criterion: EVERY LEVEL BRINGS NEW CODE, not only new files. A level that
rearranges ready tiles and monsters is content; a level for which a new
mechanic is written (a platform, a new enemy, a trick of gravity) is the
growth of the engine. The game grows in what it can do, not in length.
The units are sorted into folders by layer (`Core/` shared with the editor
and the tools, `Game/`, `Hud/`, `Menu/`), done after 3.0.8; the new is
born as its own units, nothing had to be merged.

**Phase 3 - modern graphics** (after the editor and levels 3-10). The hero
and all the monsters redrawn with modern means, the backdrops and part of
the textures too (the HD backdrops of levels 1-2 went earlier, into 3.0;
the objects layer from there is the first half of the future level
model). No "classic game" mode inside: the museum of 2008 is the 2.5.x
release (decided with the version lines). The number 3.0 went to the
removal of the 2008 mode; the redraw is more like 4.0, but numbers are not
planned that far. The era switch, the `@2008` suffix in `TSpriteCache`
and the questions of the classic seam fell away with the mode.
Open:
- whether the new graphics fit the 2008 contract (sprite 32, Bound 8,
  `TAnimSet` 8+8, the hero's 24 frames) - after 2.x the contract may
  change, but that is a decision about gameplay, not about a picture
  (step 1 above meets this first);
- the style of the tiles and backdrops of levels 3+ is to be settled
  BEFORE they are drawn in the editor, or the skin is pulled over
  finished levels.
