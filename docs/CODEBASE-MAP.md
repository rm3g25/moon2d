# Moon 2D - Codebase Map

Reference document. Purpose: given this file plus a task description, know which
files to open without re-exploring the repository.

Repo: `https://github.com/rm3g25/moon2d/`, Delphi 10.3+ (inline var) + SDL2,
Win32. Logic space 512x384 game units (16x12 cells of 32), tile art 64 px,
fixed tick 33 Hz, screen-by-screen levels (no scrolling).

Regenerated at `v3.0.3`, patched through `v3.0.33` and for the platform's
hull at `v3.0.36` and its rig at `v3.0.37`, for the arena's pads at
`v3.0.38` and its restore at `v3.0.39`, for the boss's damage cap at
`v3.0.40`, for the repaint of level 2's screens 1-3 after it, for the blast
wave at `v3.0.41`, the emptied death frames at `v3.0.42`, the fireball
at `v3.0.43`, the live shards at `v3.0.44`, the tank's hull at `v3.0.45`, the plunging pad at `v3.0.46`, the hero's
shroud at `v3.0.47`, the henshin on orbs at `v3.0.49`, the uptake of
pickups at `v3.0.50`, the shelf at `v3.0.51`, the carousel at
`v3.0.52`, the gravel arena of level 2's screen 9 at `v3.0.53` to
`v3.0.59`, the collision decks at `v3.0.60`, the burst of the henshin
suit at `v3.0.61` and the scenes - the cordon over level 1's screen 9 - at
`v3.0.62`, then for the way on after arena 2 at `v3.0.63`, the Duplet at
`v3.0.64`, the tunnel dust at `v3.0.65`, the shut doors at `v3.0.66`,
the moon stone at `v3.0.67`, the fall of the rocks at `v3.0.69` and the
charge of the stone at `v3.0.70` and the free fall of the rocks with
the checkpoint on the stone at `v3.0.71`, then for `TMoonGame` moving
out of `Moon2D.dpr` into `Game.Moon` after `v3.0.73` and the hero's orbs
moving out of it into `Game.HeroOrbs` (`v3.0.72` to
`v3.0.74` themselves are not caught up yet), then for the Ram at
`v3.0.75`, with
the lightning of `v3.0.34` caught up (the folder layout came between 3.0.8 and 3.0.9) and checked against the code section by section at
`v3.0.19`. Where the map and the code disagree, the code is right.

## Source layout

The units live in four folders under the root; `Moon2D.dpr`, `.dproj` and
`Moon2D.inc` stay in the root, and every unit includes it (`{$I ..\Moon2D.inc}`;
`{$I ..\..\Moon2D.inc}` from `Game/Events/`, `Game/Pads/`, `Game/Orbs/` and
`Game/Scenes/`).

- `Core/` - what the level editor and the tools share: SDL bindings, sprite
  sets, rendering (the shake included, and what is made of a picture's alpha -
  `Render.Silhouette`), the brush, the effects (particle
  swarm, sparks, debris), the level/monster/config/language models, the
  frame-vs-screen space. **Core never uses a unit outside Core** - a tool or
  the editor that references only `Core/` fails to build the day that rule
  breaks.
- `Game/` - the game itself: `TMoonGame` (`Game.Moon`), hero, monsters,
  the boss's disc and its pilot,
  bullets,
  explosions, bullet impacts, sound, the loop host,
  the bonus vocabulary, the henshin ceremony, the hero's shroud, the taking
  of a pickup (`Game.Uptake`), the hero's orbs and the charge of the form
  (`Game.HeroOrbs`), the version, and the gravel arena of level
  2: the rules of the trial (`Game.Trial`), the violet light its bodies
  come down in (`Game.Arrivals`), the TeK wall cannons (`Game.Cannons`)
  and the shield they wear (`Game.Shield`), the press of the finale
  (`Game.Press`); and TeK-R13, the Ram of level 2's boss arena
  (`Game.Ram`, 3.0.75). `Game/Events/`
  runs the level events; `Game/Scenes/` plays the level's scenes
  (`Scenes.Director`, 3.0.62); `Game/Pads/` holds the pads in play
  (`Pads.World`), the cycle of a pad that plunges under the hero
  (`Pads.Plunge`), the cycle of a shelf that slides in and out of its
  wall (`Pads.Shelf`), the cycle of a pad that strays (`Pads.Stray`),
  the rebuild of a pad group (`Pads.Formations`,
  `Pads.Flights`) and the director of the boss fight over one and of the
  restore after it (`Pads.Arena`); `Game/Orbs/` holds the orbs - the flock
  (`Orbs.Flock`), the harvest of spots on the matter of a screen
  (`Orbs.Harvest`), the hero's aura over both (`Orbs.Aura`), the fire
  rain (`Orbs.Rain`), the patterns of the henshin (`Orbs.Patterns`), the
  rite that builds them about the hero (`Orbs.Rite`) and the burst of the
  light the suit cannot hold (`Orbs.Burst`).
- `Hud/` - everything drawn over the playfield, plus the story screen and the
  typewriter they share.
- `Menu/` - the main menu and its sky rig.
- `Tests/` - the test suite, a console project of its own (see Tests
  below). Its folders mirror the folders of what it tries; no game unit
  uses anything from it.

Game, Hud and Menu are peers above Core and may use each other. Level events
driven from level JSON split by that rule: the model and parser
(`Levels.Events`) sit in `Core/`, since the editor will write them; the
runner (`Events.Director`) in `Game/Events/`. The pads split the same way:
the model and parser (`Levels.Pads`) sit in `Core/` beside `Levels.Events`,
since the editor will write pads too, and the carousels they may fly round
(`Levels.Carousels`) with them; the pads in play (`Pads.World`) and their
rebuilds in `Game/Pads/`; what a pad or a monster wears, its rigs
(`Levels.Rigs`), is a parser in `Core/` too. The scenes split the same
way (3.0.62): the model and parser (`Levels.Scenes`) in `Core/`, the
director that plays them (`Scenes.Director`) in `Game/Scenes/`. Two unit
names in `Core/` still carry the `Game.` prefix (`Game.Config`,
`Game.Space`) - the folder is the truth about the layer, not the prefix.

Dependency direction (roughly bottom-up):
`Sdl2.Core` / `Sprites.Sets` -> `Sdl2.Image` -> `Render.*` / `Audio` / `Game.Config` /
`Game.Bonus` / `Game.Space` / `Localization` / `Render.Brush` ->
`Monsters.Defs` -> `Levels.Tint` / `Levels.Events` (over `Monsters.Defs`
for the tactics an event sets and the side a body comes in from, and over
`Levels.Pads` for the shelf programs and bank orders an event tells) / `Effects.Emitter` / `Render.Puff` /
`Effects.Sparks` (its streak texture comes from the owner) /
`Effects.Traces` (over `Render.Brush` for its xorshift) ->
`Effects.Debris` (over `Effects.Sparks`, draws through `Render.Glow`) ->
`Render.Globe` -> `Levels.Dynamics` (over `Effects.Sparks` for the sparks
kind and `Effects.Traces` for the graph kind; draws through `Render.Glow`, `Render.Puff` and `Render.Globe`) ->
`Levels.Rigs` (what the pads and the monsters wear: over
`Levels.Dynamics`) -> `Levels.Pads` (over `Levels.Tint`, and over
`Levels.Rigs` for the names of the rigs a pad wears) ->
`Levels.Carousels` (the carousels and the track round which they fly
their pads: over `Levels.Pads` alone) / `Levels.Scenes` (the scenes:
over `Localization` and `Levels.Dynamics`, for the eases of a move) ->
`Levels.Defs` -> `Pads.Formations` (the dice and the judge of a rebuild:
over `Levels.Pads`, `Levels.Defs`, `Render.Brush` and `Game.Space`) ->
`Pads.Flights` (over `Pads.Formations`) / `Pads.Plunge` (the cycle of a
plunging pad: over `Levels.Pads` and `Render.Brush` alone) / `Pads.Shelf`
(the cycle of a shelf: over `Levels.Pads` alone) -> `Pads.Stray` (the
cycle of a pad that strays: over `Levels.Pads`, `Pads.Plunge` for its
fall, `Render.Brush` for its dice, `Render.Sprites` and `Game.Space` for
the sizes) -> `Pads.World`
(the pads in play: over the five, `Levels.Pads`, `Levels.Carousels`,
`Levels.Defs`,
`Render.Sprites`,
`Render.Brush`, `Game.Space` and `Sdl2.Core`) / `Hud.Vitals` / `Hud.Charge` /
`Hud.Energy` (3.0.70: over `Render.Brush` and `Sdl2.Core`, drawn through
`Render.Glow`) /
`Hud.Typewriter` ->
`Hud.Terminal` / `Hud.Briefing` ->
`Bullets` / `Monsters.Disc` (the boss's disc: over `Render.Sprites` and
`Monsters.Defs`, its sensor through `Render.Glow`) / `Monsters.Hull` (the
hulls of the platform and the tank: the same, the eye through `Render.Glow`) / `Monsters.Pilot` (the
boss's pilot: over `Levels.Defs`, `Monsters.Defs`, `Pads.World`,
`Game.Space` and the sizes of `Render.Sprites`) / `Monsters.Damage` (the
window of a monster's damage cap: over `Monsters.Defs`) -> `Hero` /
`Monsters` (both over `Pads.World` too; `Monsters` over `Levels.Events`
for the orders of a body an event lets in) / `Hud.Messages` / `Render.Tiles` / `Render.Objects` /
`Render.Dynamics` / `Game.Explosions` (over `Effects.Debris`,
`Levels.Dynamics` and `Monsters.Defs`) / `Game.Blasts` (the wave of an
explosion: over `Monsters.Defs`, `Effects.Sparks` for the probe type and
`Sdl2.Core`) / `Game.Impacts` (over
`Effects.Sparks` and `Levels.Dynamics`) / `Orbs.Flock` (the orbs: over
`Effects.Emitter`, `Render.Brush` and the canvas of `Levels.Dynamics`,
drawn through `Render.Glow`) / `Orbs.Harvest` (where the orbs of the aura
and of the rite come
from: over `Game.Space`, `Render.Brush` and `Sdl2.Core` alone - it knows
neither the level nor the pads) / `Orbs.Patterns` (the figures of the
henshin: over no unit of the game) -> `Hud.Marks` /
`Game.Shroud` (the hero's shroud: over `Hero`, `Render.Silhouette` for the
art of his frames, `Effects.Emitter`,
`Effects.Sparks` for the probe type and the canvas of `Levels.Dynamics`;
it draws through `Render.Glow` and `Render.Puff`) /
`Game.Uptake` (the taking of a pickup: over `Hero`, `Monsters`,
`Monsters.Defs`, `Render.Silhouette`, `Render.Brush`, `Effects.Sparks` for
the probe type and the canvas of `Levels.Dynamics`; it draws through
`Render.Glow`, reads the sprite sets itself through `Sprites.Sets` and
`Render.Sprites` and knows no shroud - the light goes to the body through
a callback) /
`Orbs.Rite` (the rite of the henshin: over `Orbs.Flock`, `Orbs.Harvest`
and `Orbs.Patterns`, `Render.Brush` and the canvas of `Levels.Dynamics`) /
`Orbs.Burst` (the burst of the suit: over `Orbs.Rite` for the body
probe, `Orbs.Harvest` for the matter, `Effects.Emitter` for its swarms,
`Render.Brush`, `Game.Space`, the cell size of `Render.Sprites` and the
canvas of `Levels.Dynamics`, drawn through `Render.Glow`) /
`Game.Henshin` (over `Game.Shroud`, `Orbs.Rite` and `Orbs.Burst` too) /
`Orbs.Feed` (3.0.70, the orbs that carry a charge into its gauge: over
`Orbs.Flock`, `Render.Brush` and the canvas of `Levels.Dynamics`) /
`Game.Trial`
(the rules of the gravel trial: over no unit of the game) / `Game.Press`
(the press of its finale: over no unit of the game either) /
`Game.Arrivals` (the violet light: over `Sdl2.Core`, `Render.Brush` and
the canvas of `Levels.Dynamics`, drawn through `Render.Glow`) /
`Game.Shield` (the TeK shield: over `Sdl2.Core`, `Render.Brush` and the
canvas of `Levels.Dynamics`, drawn through `Render.Glow`) ->
`Game.Cannons` (the wall cannons: over `Game.Shield`, `Levels.Events`
for their orders, `Sprites.Sets` and `Render.Sprites` for their art,
`Render.Brush`, `Game.Space` and the canvas of `Levels.Dynamics`) /
`Game.Ram` (the Ram: over `Game.Shield`, `Monsters.Hull` and
`Monsters.Defs` for its hull, `Levels.Events` for its orders,
`Sprites.Sets` and `Render.Sprites` for its art, `Render.Brush`,
`Game.Space` and the canvas of `Levels.Dynamics`) /
`Events.Director` (over `Game.Trial` for the progress it reads) / `Orbs.Aura` (the hero's aura: over
`Orbs.Flock` and `Orbs.Harvest`) / `Orbs.Rain` (the fire rain: over the
same two, and `Game.Space`) / `Game.HeroOrbs` (the hero's orbs: over
`Orbs.Aura`, `Orbs.Rite`, `Orbs.Burst`, `Orbs.Rain`, `Orbs.Feed`,
`Monsters` for the type of what it wounds and `Hud.Energy` for the full
gauge and its heart) / `Pads.Arena` (the director of the
rebuilds: over `Pads.World`, `Pads.Formations`, `Monsters`,
`Monsters.Pilot`, `Levels.Pads`, `Levels.Dynamics` and `Render.Sprites`) /
`Scenes.Director` (the scenes: over `Levels.Scenes`, `Levels.Dynamics`,
`Audio`, `Hud.Messages`, `Monsters`, `Bullets` and `Pads.World`; the
place of a line from `Hud.Terminal`) -> `Game.Moon` (the game: over all
of them, `Menu` and `Game.Loop`) -> `Moon2D.dpr` (the start-up), which
also drives `Game.Loop` (the host: over `Sdl2.Core` and `Game.Config`
alone, it knows no game unit). The menu sky rig on the
side: `Render.Brush` -> `Render.Glow` -> `Menu.Starfield` / `Menu.Embers` ->
`Menu.Logo` -> `Menu` (with `Menu.Globe`, a thin moon over `Render.Globe`).
`Render.Silhouette` stands over `Render.Glow` and `Sdl2.Core` alone.

---

## Game units

### `Core/Sdl2.Core.pas` (~420 lines)
Hand-written SDL2 bindings. No classes - constants, records, `external`
declarations against `SDL2.dll`.
- **Constants**: init flags, window flags (incl. `SdlWindowHidden` for the
  offscreen tools), renderer flags, texture access (incl. `Target`), hints
  (`SdlHintRenderDriver`, `SdlHintRenderScaleQuality`), event type ids, flip
  flags, pixel format `SdlPixelFormatAbgr8888`, blend modes (`None`, `Blend`,
  `Add` - the last one is the HUD's glints), scale modes
  (`SdlScaleModeNearest`/`Linear` - per-texture filtering), the basic
  scancodes (Return, Escape, Ctrl/Alt, Space, arrows; the letter, numpad and
  debug keys are constants in `Game.Moon`).
- **Records**: `TSdlRect`, `TSdlFRect`, `TSdlPoint`, `TSdlFPoint`,
  `TSdlColor`, `TSdlVertex` (a corner of a triangle: where it lands, what
  tints it, the point of the texture it shows, 0..1 across and down),
  `TSdlRendererInfo`,
  `TSdlVersion`, `TSdlSurface` (partial mirror - leading fields only),
  `TSdlKeysym`, `TSdlKeyboardEvent`, `TSdlMouseMotionEvent`,
  `TSdlMouseButtonEvent`, `TSdlEvent` (variant record, 56-byte padding arm).
- **Imports**: window/renderer lifecycle, draw calls (`SDL_RenderCopy/F/Ex/ExF`,
  `SDL_RenderGeometry` - triangles, the mesh of a haze: the vertices carry
  the color and the alpha, the texture's color and alpha mod are ignored,
  its blend mode is not; SDL 2.0.18+ -,
  fill, clear, present), surfaces + color key + format conversion, textures
  (incl. target textures, streaming `SDL_LockTexture`/`SDL_UnlockTexture` -
  the globe, per-texture `SDL_SetTextureScaleMode`, color and alpha mod, the
  blend
  mode set and read back (`SDL_SetTextureBlendMode`,
  `SDL_GetTextureBlendMode`), and
  `SDL_RenderReadPixels` - used by TitleCard and the screen dump),
  events, `SDL_ShowCursor`, `SDL_GetRendererInfo`, `SDL_GetVersion`, timing
  (`SDL_GetPerformanceCounter/Frequency`, `SDL_Delay`),
  `SDL_SetHint`, `SDL_RenderSetLogicalSize`, `SDL_RWFromMem`.
- **Helpers**: `SdlText(string)->UTF8String`, `SdlErrorText`.
- Touch this file when: a new SDL function is needed, event handling, ABI
  questions.
- 3.0.75: `SDL_RenderSetClipRect` - the clip of the drawing, in logical
  units as a copy's destination; nil lets it land anywhere again.

### `Core/Sprites.Sets.pas` (~445 lines)
The `.mset` sprite set container: a JSON manifest followed by every image
concatenated behind it. Read by the game, the packer and (later) the level
editor - one unit, three callers. Every sprite in the game comes from a set;
loose image files no longer ship. `SetQualifier` (':') lives here too, since
the editor and the packer read the same syntax.
- **Constants**: `MsetVersion=1`, `SetQualifier=':'`. Manifest field names are
  constants (`KeyId`, `KeySprites`, `KeyOffset`...) - a typo in a literal
  compiles.
- **Records**: `TSpriteEntry` (name, description, offset, size - offset is
  measured from the start of the blob block, not the file), `TSpriteSequence`
  (name, description, frames), `TMsetHeader` (packed: magic, version, manifest
  size), `TMsetMagic` (named type - an anonymous `array[0..3] of AnsiChar` will
  not assign to another one).
- **`TSpriteSet`** - read side. Opening parses the manifest only; image bytes
  arrive on demand via `ReadSprite(name)`. `Contains`, `SequenceFrames`;
  properties `FileName`, `Id`, `Description`, `Entries`, `Sequences`.
- **`TSpriteSetWriter`** - write side. `AddSprite`/`AddSpriteFile`,
  `AddSequence`, `SaveToFile`. Offsets are handed out at save time in add
  order; writing is deterministic, so an unchanged set rebuilds byte for byte.
  Validates duplicate names and sequences pointing at absent frames.
- Format spec: `docs/MSET-FORMAT.md`.

### `Core/Render.Sprites.pas` (~585 lines)
Texture cache + low-level sprite drawing. Owns the unit-size constants.
- **Constants**: `SpriteSetsDir` ('sprites\'), `SpriteSize=32`, `TileSize=32`
  (game units!), `TileArtSize=64` (texture px!), `FramesAlive=8`,
  `FramesDeath=8`. The 32-vs-64 split is the coordinate-system discipline in
  code form.
- **`TSpriteCache`** - dictionary `set:name -> PSdlTexture`, lazy load from the
  sets attached via `AttachSpriteSet` (not owned - the opener frees them);
  `Get(name)` returns the texture, loading the image on first request.
  Resolution: a qualified name (`common:pustota`) goes to that set alone; a
  bare name takes the first attached set that has it; **a name no attached set
  carries raises `ESpriteError`** - there is no folder fallback left. Path and
  extension are dropped when looking up, so the 2008 spellings in level
  palettes (`level1\doom1.png`) still resolve. `SourceOf(name, out bare)` -
  the same resolution without a texture: the set and the name as it knows
  it (the sky globe reads its maps through it). `AmbiguousNames` reports bare
  names carried by more than one attached set - those would resolve by
  declaration order, which is exactly what the qualifier exists to avoid.
  Color key: black by default (`SetColorKey` changes the color,
  `DisableColorKey` drops it - the backdrop, object and disc caches do).
  `EnableLinearFilter`
  gives the cache's textures the linear filter over the global nearest - for
  art denser than the logical screen (the HD backdrops), where nearest
  downscaling turns detail into grain. `ExpectDenseArtAbove(width)` is for a
  cache that holds HD art beside the 2008 frames (the monster sets): a
  picture wider than `width` pixels is loaded without the color key - dense
  art comes with its own alpha, and the key would punch a hole in every
  pure-black pixel of its paint - and with the linear filter; the narrower
  ones load as the cache is set (for a monster set: keyed and nearest). All
  three apply to textures loaded after the call. `Count` - the textures
  loaded so far.
- **`LoadImageSurface(spriteSet, name)`** (free function) - the one place that
  turns stored bytes into a surface. Returns `nil` for a nil set or an unknown
  name; the caller words the error, since only it knows what the picture was
  for.
- **`TAnimSet`** (record) - `Alive[0..7]` + `Death[0..7]` texture arrays
  (`TFrameIndex` indexes both);
  `IsLoaded`. Built by **`LoadAnimSet(cache, spriteSet)`** from the manifest's
  `alive` and `death` sequences, each validated to exactly eight frames -
  `TAnimSet` is the 2008 contract and it is fixed-size.
- **`TintTexture(texture, r, g, b)`** (free function) - color mod per channel
  in percent, 100 = as painted. The texture keeps it until the next call, so
  a picture shared under different tints is tinted before every draw. The
  backdrops, the level objects and the pads tint through it.
  **`PercentToColorMod(percent)`** - one channel of that conversion, public
  for a caller that passes the color on instead of setting it on a texture
  (the beacon's tint becomes the glow color through it).
- **`TSpriteRenderer`** - draws in game units: `DrawCell` (sprite grid),
  `DrawTile` (tile grid, the top-left 64x64 crop reproduced from
  `sttextures.pas`), `Draw` (free position, optional mirror), `DrawRect`,
  `DrawRectF` (the same in fractions of a unit, turned by an angle round
  its middle - the pads' picture, which sways and rocks smoothly), `DrawRotated` (weapon arm), `DrawTurned(texture,
  center, side, angle, level = 1)` - a square of any size centered on a
  float point, turned clockwise, at an opacity; float all the way, so a
  mover drawn between ticks does not snap to logical units - the boss's
  disc draws its layers through it. `DrawSized(texture, center, width,
  height, level = 1, mirrored = False)` - the same for a rectangle,
  unturned, mirrored left to right on demand: the layers of a hull. It sets the texture's alpha mod on
  every call. `Draw`, `DrawRotated`, `DrawTurned` and `DrawSized` all draw a float
  rectangle through `SDL_RenderCopyExF` (at whole units the picture is
  what the integer call drew), and so does `DrawRectF` since 3.0.28
  (`SDL_RenderCopyF` before);
  `DrawTile` and `DrawRect` stay integer (`SDL_RenderCopy`), `DrawCell`
  goes through `Draw`. **`Origin`** (a `TSdlPoint`) shifts every one of
  them - the screen-shake hook; nothing here resets it, the caller sets it per
  layer and draws the still layers (backdrop, cursor, HUD) at `NoShake`.
  **`FineY`** (a `Single`, 0 from birth) - a fraction of a unit under
  `Origin.Y`, added by `Draw`, `DrawRotated`, `DrawTurned` and `DrawSized` alone (so by
  `DrawCell` too): a body riding a swaying pad sways with it, not in whole
  units. The caller sets it around one figure's draw and puts it back to 0;
  nothing here resets it either. The
  constructor takes the logical size and sets it on the renderer
  (`SDL_RenderSetLogicalSize` - `Game.Moon` passes the frame of `Game.Space`).
- 3.0.64: `DrawRotated` takes the square's side (`ASide`, `SpriteSize`
  by default) - a gun bigger than the 2008 frames, the Duplet's 48. 3.0.67:
  `DrawSized` turns the rectangle `AAngleDegrees` clockwise round its
  middle - a picture that turns, the moon stone.
- 3.0.75: `ClipAbove(y)` - every draw from then on lands only above the
  line `y` units down, shifted by `Origin` as the draws are (the logical
  width is kept from the constructor, `FWidth`, and the clip reaches a
  width past either side for a shake); `ClearClip` lets them land anywhere
  again. Whole units: the renderer clips no finer. The Ram's mast is drawn
  through it.

### `Core/Sdl2.Image.pas` (~70 lines)
SDL2_image bindings, delayed imports in the shape of `Audio.pas`.
`IMG_Load_RW` replaced `SDL_LoadBMP_RW` at every load site. `EnsureImageLib`
runs at startup and raises plainly if the DLL is absent - unlike the optional
mixer, missing art is fatal. `IMG_SavePNG` is the one writer: the debug
screen dump of `Game.Moon`.

### `Core/Render.Tiles.pas` (~115 lines)
- **`TTileScreenRenderer`** - draws one screen as two layers the caller
  orders: `DrawBackground` (the screen's backdrop sprite via
  `FBackgroundCache`), then `DrawTiles` (palette indices from `TLevel` via
  `FTileCache`). Separate calls, no combined one, so the backdrop can stand
  still while the tiles shake. Both caches are fed from `.mset` sets by the
  composition root, and neither is owned here. `DrawBackground` sets the
  change's tint (`TintTexture`) on every draw, not once at load: two changes
  may share one picture under different tints. **`Backdrop(screen)`** - what
  `DrawBackground` draws, as a `TBackdropView` of `Levels.Dynamics` (the
  texture, its tint, the screen it is stretched over; texture nil - the
  screen has none): the one answer to what stands behind a screen.
  `DrawBackground` draws what it says, and the game hands it to the dynamic
  objects - a haze bends the backdrop.

### `Core/Render.Objects.pas` (~80 lines)
- **`TObjectScreenRenderer`** - draws a screen's level objects (free-form
  art, `TLevelObject`) in file order, each at its rectangle with its tint.
  The constructor resolves every sprite and measures every rectangle up
  front (height from the art's aspect), so a sprite the set lacks raises at
  level load, not on the screen that shows it; after that `Draw(screen)` only
  walks the list. The cache comes from the composition root - no color key
  (honest PNG alpha: black glass and shadows would vanish through a key),
  linear filter, fed from the level's own `<assetsDir>-objects.mset` (when
  the level ships one) and the shared sets of `objectSets`; not owned here.

### `Core/Render.Dynamics.pas` (~495 lines)
- **`TDynamicScreenRenderer`** - brings the level's dynamic objects
  (`Levels.Dynamics`) to the screen. Owns the textures of the
  `TDynamicCanvas` (point, flare, starburst, streak and beam glows -
  `Render.Glow`, the beam's `gsBeam` since 3.0.62; the
  smoke puffs - `Render.Puff`) and lends it the cache of the level's
  object art (`Art`), made at level load; the objects
  themselves are the level's. After the canvas every object `Acquire`s
  what it draws with (a sky globe its `TGlobe`); the destructor `Release`s them
  before the canvas goes, so every SDL texture dies before the renderer. Per object a `TPlace`: its stands (screen + origin),
  `FollowsParent` (a parent looked up by tag), the parent's life, the lead
  screen. A nailed object stands
  at (0, 0) on its screen, or on each screen of its `screens` run; one under a static object on every screen that
  object stands on, at its top-left - settled once, static objects never
  move. One under a craft (3.0.62) stands on every screen the craft does
  and keeps a reference to the craft itself (`TPlace.Craft`, found by
  `CraftTagged`): a craft never leaves the level, so nothing is looked
  up; `OriginOf` adds the craft's `CornerAt(alpha)`, and what hangs on a
  craft in flight is drawn with the hull between the ticks, not a tick
  behind it. The craft goes first in the level file (`Levels.Defs`
  checks), so it has moved by the time its children tick. A tag no
  object and no craft carries is a pad's or a monster's: that stand is
  looked up every tick (`FollowParent`) through **`TLocateParent`**
  (`reference to function(tag, out TParentStand)`: screen, the top-left of
  the parent's picture, alive, `Effort` - how hard it works, 0..1: a pad
  flying or about to leave its place works at 1, a pad that plunges in
  fits (3.0.46, `TPad.Effort`), a shelf at 1 while it warns that it is
  about to slide in (3.0.51), and `Tick` passes it on
  to the object before the tick (`FollowEffort`); for a monster that spins
  also `Spins` and a `TParentSpin` - its `TSpinPose` (the axis on the
  screen, the angle in degrees clockwise) now and a tick ago, plus where the
  axis sits from the sprite's top-left) - the field is reborn on
  restart, so no reference is kept; a parent that is nowhere keeps its
  last stand. **`OriginOf(place, stand, alpha)`** is the corner an object
  counts from: the stand's, or - for a placement that `Turns` under a parent
  that spins - wherever its point has turned to around the axis, alpha of
  the way between the two poses: a lamp rides the boss's disc between ticks
  exactly as the disc is drawn. Under a parent gone into the depth of its
  screen - a pad in a rebuild - the corner brings the object's point in
  toward the parent's pivot as far as the parent has shrunk: a lamp stays
  on the same point of its pad's shrinking picture. The stand carries a
  **`TParentDepth`** for it: `Sunk` / `LastSunk` (0 in front .. 1 all the
  way in, at this tick and a tick ago - `SunkAt(alpha)` between them, so the
  children go in as the parent's picture does), `Shrink` and `Dim` (the
  shares of its size and of its light the parent has lost all the way in),
  `Pivot` (the point it shrinks about, from its top-left corner); all zero -
  a parent in front, and one that never leaves it. A shelf slides into its
  wall without what hangs on it (3.0.51): the game hands it the depth of
  a flight alone (`TPad.RigDepth`), zero for a shelf. `Tick(screen)` ticks
  every object whatever
  the screen (a
  lamp keeps its rhythm off screen) with the origin of its stand on the
  hero's screen, else its first (at the pose the tick has just reached,
  `ThisTick`); a lead stand on another screen is a jump
  (`ForgetOrigin`), not a flight. `Draw(screen, origin, alpha, layer)` draws
  the ones on the screen in one layer (`dlBackdrop` / `dlSky` / `dlAloft`
  (3.0.62) / `dlBack` / `dlFront`; before the backdrop layer it puts the screen's backdrop on the
  canvas, asked of the game); a
  place that `Turns` is not drawn once its parent is no longer alive (dying
  included) - there is nothing left to turn with. What hangs on a parent in
  the depth leaves its layer: `Draw` passes it over and
  **`DrawSunk(screen, origin, alpha)`** draws it, whatever its layer, for
  the game to put behind what stands in front; the backdrop layer alone is
  drawn whole - it is under everything as it is. Both go through
  `DrawStands(place, view, sides)` (`TFrameView` - the screen, the shake, the
  alpha; `TStandSides` - `ssFront` / `ssSunk`), which sets the canvas'
  `Scale` and `Tone` for every stand it draws and puts them back to 1: the
  game draws smoke of its own with the same canvas. Under a parent that is
  dead or gone it draws neither a placement that `Turns` nor a kind that
  `GoesOutWithParent` - by the place's own `ParentAlive`, which `Reseat`
  refreshes at once, so after a restart the lamps are back in the first
  frame. **`Reseat`** - the monsters
  were reborn (a
  restart): every place that follows a parent finds it at once and
  forgets its origin, so the frame before the next tick does not show it at
  the old stand. `Canvas` - the
  textures, lent to the monsters' wreck smoke and sparks, to the
  explosions (`Game.Explosions`) and the impacts (`Game.Impacts`).
  The constructor takes a **`TDynamicWorld`** (record) - what the objects
  ask of the game: `LocateParent`, `BackdropOf` (`TBackdropOf`,
  `reference to function(screen): TBackdropView` - the backdrop drawn
  behind a screen; the game gives the tile renderer's `Backdrop`) and
  `Solid`, the game's `TSolidProbe`,
  which answers for the hero's screen. The canvas hands the objects
  `SolidInView` instead of it: the game's probe while the object being
  ticked stands on the hero's screen (`FInView`, set per place in `Tick`),
  no walls at all otherwise - an object on another screen must not ring
  off the wrong grid.

### `Core/Render.Shake.pas` (~110 lines)
Screen shake as one trauma meter for the whole game, read back as a draw
offset per layer. Draw-side only: the world's arithmetic never sees it.
- **`TShakeChannel`** = (`scWorld`, `scHero`, `scMonsters`) - the world (tiles,
  bullets) jolts as one piece; the hero and the monsters ride it with a small
  jitter of their own (`FigureJitterRatio=0.25`), so the figures look loose.
- **`TScreenShake`** - `AddTrauma(amount)` (soft saturation `T += A*(1-T)`: a
  chain of barrels climbs toward the ceiling without hitting it), `Tick` (once
  per logic tick: linear decay `TraumaDecayPerTick=0.03`, then a fresh roll of
  all three offsets - amplitude is `T^2*MaxShakeOffset(8)`, so a lone barrel is
  a nudge and a boss is the ceiling), `Offset(channel)`. Its own xorshift
  stream, not `Random`: that one feeds the boss spawn table. `NoShake` is the
  zero offset constant.
- The doses live with whoever shakes (`*Trauma` constants: the blasts and
  bonuses in `Game.Moon`, the suit going on in `Game.Henshin`), not
  here - what shakes how much is game-flow policy; this unit is the
  mechanism.

### `Core/Render.Font.pas` (~405 lines)
Bitmap font: a square atlas holding a 16x16 glyph grid (CP1251 layout). The
2008 atlas is 448 px (28 px cells); a redrawn one may be any square whose
side divides by 16 - the cell size is read from the image at load.
- **Constants**: atlas geometry (`FontAtlasSize`, `FontGridCells`,
  `FontCellPx`) + verbatim-2008 glyph metrics derived from the original's NDC
  math (`LegacyColumnWidth`, `SmallGlyphWidth/Height`, `BigGlyphWidth/Height`,
  `SmallAdvance` / `SmallLineStep` - a glyph and a row; `BigAdvanceRatio=0.8` -
  20% overlap, giving `BigAdvance`; `BigGlyphAspect`).
- **`TFontAtlasOrientation`** = (`faUpright`, `faRotatedCw`) - the atlas
  orientation fix.
- **`TFontFiltering`** = (`ffLinear`, `ffNearest`, `ffLinearSmallOnly`) - how
  a redrawn atlas is filtered, set through `TMoonFont.Filtering` (`Game.Moon`
  picks `ffNearest`; N cycles it in a DEBUGKEYS build). A redrawn atlas
  (cells larger than `FontCellPx`) is kept as two textures, nearest and
  linear; the 2008 atlas has no linear copy and is always nearest.
  `TTextSize` = (`tsSmall`, `tsLarge`) tells `ffLinearSmallOnly` which text
  is which.
- **`TMoonFont`** - takes a `TSpriteSet` (attached, not owned) and
  reads its atlas sprite out of it; the parameter defaults to nil, but
  without a set the load raises `EFontError` - there is no file fallback.
  `DrawSmall`, `DrawBig`, `DrawScaled`
  (arbitrary glyph height - the countdown digits),
  width measurers (`SmallTextWidth`, `BigTextWidth`, `ScaledTextWidth`),
  `DrawAtlas` (debug view, F key).

### `Game/Audio.pas` (~470 lines)
SDL2_mixer bindings (`delayed` imports - the game survives a missing DLL) plus
the sound bank.
- **`TMusicMode`** = (`mmLoop`, `mmOnce`).
- **`TSoundBank`** - dictionary of WAV chunks + one music slot. `Load`/`Play`
  (`sounds\`, strict: a missing file raises `EAudioError` - at startup for what
  `Game.Moon` preloads, on first `Play` for a name it did not),
  `PlayMusic`/`StopMusic` (`music\`, OGG, lenient: a missing track skips
  silently), `ToggleMusicMuted` (`MusicMuted` reads it back), `Enabled`
  (False when the mixer DLL is absent
  -> every call becomes a no-op). `MixChannels` = 32: a one-shot with no free
  channel is dropped in silence, and the chain gun's 2.4 s shots alone hold
  sixteen.
- Held sounds (3.0.62, for the scenes): **`PlayHeld(file)`** plays as
  `Play` does and gives back a **`THeldSound`** (the channel and the
  chunk - 3.0.63, was the file name); `StopHeld`, `PauseHeld`, `ResumeHeld` act on it only while that
  channel still plays that chunk (`StillHeld`) - a sound that has ended,
  and whose channel another sound has taken, is left alone.
  **`SetMusicLevel(level)`** - the music at a share of its volume, 0..1,
  kept through track changes; muting outranks it (`ApplyMusicVolume`). A
  scene's own music plays as a held sound: the music stream is one, the
  level's track fades under it.
- 3.0.63, for the end of arena 2: `PlayMusic(file, mode, fadeSeconds)` -
  above 0 the track comes in from silence (`Mix_FadeInMusic`). Tracks of
  the music folder played as sounds: `LoadTrack(file)` decodes one whole
  (lenient, as music: a missing track is none; `FTracks`),
  **`PlayTrackHeld(file)`** plays it once on a sound channel, held, so the
  music channel stays free for the next track to fade in over its end;
  **`SecondsOf(held)`** - how long it plays from its start, by the
  chunk's bytes over `FBytesPerSecond` (`MixerBytesPerSecond`,
  `Mix_QuerySpec`). `PMixChunk` is a typed `TMixChunk` now.
- 3.0.74, for the boss arena of level 2: **`HandOverMusic(file, mode,
  fadeOutSeconds, fadeInSeconds)`** - the track that plays fades out
  (`Mix_FadeOutMusic`) and the new one waits in **`TQueuedTrack`**
  (`FNextTrack`) until **`Tick`** - called by the game every tick, in
  every state - finds the music silent (`Mix_PlayingMusic`) and starts it
  as `PlayMusic` would, with its fade-in. Nothing playing - it starts at
  once; the track already playing (`FMusicName`, the file `FMusic` holds)
  is left alone, so an event fired again after a restart does not fade
  the track the restart has just started. `PlayMusic` and `StopMusic`
  drop a track that waits: a restart, the boss's rage, the menu cut
  through a fade.
- 3.0.75: `PlayLooped(file)` - a held sound over and over until it is
  stopped (`PlayChunkHeld` takes `ALooped`: the loops of
  `Mix_PlayChannelTimed` -1); the Ram's rumble. `Plays(file)` - that track
  is the music that plays, a fade included, and none waits to follow it.
  `FadeOutMusic(seconds)` - the music fades out to silence and nothing
  follows: a waiting track is dropped, and the fading one is no longer the
  one that plays (`FMusicName` emptied), so asked for again it waits for
  the silence and starts over. The game's restart asks `Plays` before it
  plays its track: a death no longer starts the track that plays over.

### `Game/Game.Version.pas` (~20 lines)
One constant, `GameVersion`, the only place the game knows its own version.
It moves with the git tag: bumped in the commit that becomes the version.
Read by `Menu` (the corner tag) and the dpr (window title). The dproj carries
no version resource, so nothing else has to agree with it.

### `Core/Game.Config.pas` (~285 lines)
- **`TDifficulty`** = (`dfNormal`, `dfHard`, `dfWild`); `TDifficultyGrades`
  set; `DifficultyIds` protocol strings ('normal'/'hard'/'wild');
  `AllDifficultyGrades`.
- **`TLanguage`** = (`lgEnglish`, `lgRussian`); `LanguageIds` ('en'/'ru') - one
  vocabulary serving both config files and the dictionary file names.
- **`TGameConfig`** (record) - window w/h, fullscreen, vsync, fpsCap, tickRate,
  difficulty, language; `Defaults` factory.
- Two layers over `Defaults`: `bin\config.json` (shipped, read only) and
  `%APPDATA%\Moon2D\settings.json` (the player's choices; the path comes from
  `UserSettingsFileName`). `LoadGameConfig(shipped, settings)` overlays them in
  that order, key by key (private `OverlayConfigFile`); a file with any problem
  is skipped whole and the layers below stay - configuration is a preference,
  never a reason to crash.
- Savers: `SaveGameDifficulty`, `SaveGameLanguage`, `SaveWindowFullscreen` -
  one key each into settings.json through the private `SaveKey` (section, key,
  owned `TJSONValue`). The folder is created on the first save, an unparsable
  file is left alone, a locked one is swallowed. Nothing writes config.json.
  An `era` key left over from a 2.5.x config is ignored, not rejected.

### `Core/Localization.pas` (~305 lines)
- **`TLocalizedText`** (record) - `Values[TLanguage]`, `Current`. Used for
  level and monster content (base JSON field = RU, `En` sibling = EN, an absent
  sibling falls back at parse time).
- ~55 `S*` string-key constants (protocol ids into the lang dictionaries):
  gameplay tickers, streak captions, henshin/bonus texts, the terminal and
  briefing headers, ending screen, the full menu vocabulary with the credits
  block.
- Free functions: `LoadLanguage` (swaps the flat dictionary from
  lang\en.json / ru.json, validated against the full key roster), `Tr(key)`,
  `CurrentLanguage`, `ReadLocalizedText(jsonObj, key)`, `MakeLocalizedText`.

### `Core/Levels.Defs.pas` (~2035 lines)
Level data model + JSON parser. No game logic.
- **`EmptyTile = 0`** - grid value 0 is nothing; N >= 1 maps to
  `TilePalette[N - 1]`.
- **`CollisionAir = '0'`, `CollisionSolid = '1'`, `CollisionDeck = '2'`**
  (3.0.60) - the three letters of the collision grid. A deck holds the
  hero from above only; a run of decks is loaded as a pad with no picture
  (`AddCollisionDecks`, below), so a deck plays by the rules of pads.
- **`TEntityOverrides`** (record) - optional per-placement direction, speed,
  lives, canShoot, fireOffset (Has* flag + value pairs; `fireOffset` - the
  tick of its fire count a monster starts from, held against the monster's own
  interval by `TMonster.FireStartOf`).
- **`TDifficultyValue`** (record) - one int per grade; JSON = a number or
  `{"normal":..,"hard":..,"wild":..}`; `Uniform`, `ForGrade`.
- **`TEntityTriggers`** (record) - `BigMessage`/`SmallMessage`/`HintText`
  (localized), `ChangeMusic`, heroX/heroY reposition (vertical transitions),
  the gravel trial (`HasGravelBoss` + `GravelBatch: TDifficultyValue` - the
  gravels of one act since 3.0.53, `"gravelBoss": {"normal": 15, "hard":
  25, "wild": 40}` on level 2; it was the quota of the whole trial), and
  the wave it may end in (3.0.59: `HasFinale` + `Finale`).
- **`TTrialFinale`** (record, 3.0.59) - `MonsterId`, `Count` (a
  `TDifficultyValue`), `Alive` (the cap of the living): the act after the
  gravels. JSON beside `gravelBoss`: `"finale": {"monster": "betoner",
  "count": {"normal": 10, "hard": 15, "wild": 20}, "alive": 3}`
  (`ReadFinale`). Refused (`ELevelError`): a finale with no gravelBoss
  (`SLevelFinaleNoTrial`), no monster (`SLevelFinaleNoMonster`), a count
  that is no number or not above zero on some grade
  (`SLevelFinaleBadCount`), alive not above zero (`SLevelFinaleBadAlive`);
  the errors name the owner (`ReadTriggers` takes the level id and the
  owner now). The monster id is checked at level start by
  `TMonsterField.CheckSpawnIds`.
- **`TScreenTrigger`** (record, 3.0.53) - `Screen` (1-based), `Grades`,
  `Triggers`: the triggers of a screen that no body carries. JSON: the
  root section `"screenTriggers": [{"screen": 9, "difficulty": ["hard"],
  "triggers": {...}}]` (`ParseScreenTriggers`; `difficulty` absent = all
  grades). The trial medkits of 2008 carried the trial's triggers
  (changeMusic, heroX, gravelBoss); the medkits went, the triggers moved
  here. `TLevel.ScreenTriggers`; the game fires them after the entities'
  (`FireScreenTriggers`).
- **`TEntityPlacement`** (record) - monsterId, screen (1-based), x/y (sprite
  grid), spriteList, `Grades` (the Doom skill-flag idiom), overrides,
  triggers, `Tag` (names the placement for the events' tagged conditions -
  `allDead`, `livesBelow`, `enraged` - and for the dynamic objects hung on a
  monster; '' = none), `Rigs` (the rigs it wears, by name, in the order
  they are hung - JSON `"rig": ["tekPlatform"]`, read by `ReadRigNames` of
  `Levels.Rigs`; their parts hang on the monster by its tag, counted from
  the top-left corner of its cell). `Seat` (3.0.52) - the pad it sits on,
  by tag, in place of a cell: JSON `"seat": "s08-ride-01"` with no `x`
  and no `y` (`ReadEntityCell` reads the cell or refuses one beside a
  seat, `SLevelEntitySeatPlaced`); '' = none. `SeatLeft` and `SeatFeet` -
  where it sits, in screen units: put at load by `SeatEntities` ->
  `SeatEntity`, after the pads - its body a cell wide, its middle over
  the middle of the deck as the pad starts out (a carousel's pad by its
  orbit at tick 0, not by its rounded placement), its feet on the deck;
  `X`/`Y` become the cell nearest to that, so the triggers of the
  placement and whatever counts cells still have one. A seat no pad
  carries (`SLevelEntitySeatUnknown`) or a pad of another screen
  (`SLevelEntitySeatScreen`) is refused. `TMonster.Create` puts a seated
  monster on the seat, not on its cell. `ShiftX` (3.0.67) - units the
  body stands right of its cell (below 0 - left): a thing between two
  cells, the moon stone on a column two cells wide; JSON `"shiftX"`, 0 by
  default, refused beside a seat as `x` and `y` are.
  `SpriteList` still carries the 2008 `.mns` spelling (`gravel.mns`); the stem
  names the `.mset` set and the extension is dropped at load. Renaming the
  field is a data change and waits for its own step.
- **`TBackgroundChange`** (record) - fromScreen + image + tint
  (`TColorTint` of `Levels.Tint`).
- **`TLevelObject`** (record) - free-form art over the backdrop: sprite (in
  `<assetsDir>-objects.mset` or a shared set of `objectSets`), screen
  (1-based), x/y (top-left) and width in
  screen units, tint, `Tag` (names it for the dynamic objects hung on it;
  one picture on several screens carries the same tag on each). No height:
  it follows the art's aspect, so a picture is never stretched. No
  collision - the grid and the pads (`Levels.Pads`) decide where the hero
  stands.
- **`TLevel`** (class) - the parsed level: tiles `[screen][row][col]`,
  collision strings `[screen][row]` ('0' = air, '1' = solid, '2' = deck,
  3.0.60; `ParseTiles` -> `CheckCollisionRow` refuses any other letter with
  `ELevelError` `SLevelBadCollisionChar`, naming screen, row and column),
  tile palette, backgrounds,
  entities, id/title/assetsDir/**spriteSets**/**objectSets**/music/introText, grid dims,
  screenCount. `HenshinPattern` (3.0.49) - the word `henshinPattern` of the
  file's root: the pattern the orbs of the henshin build on this level; ''
  when the file has none. `Core` knows no game unit, so the default and the
  refusal of an unknown word are the game's (`LoadLevel` in `Game.Moon`).
  `SpriteSets` is the environment sets in resolution order - tiles
  only; screen backdrops follow the `<assetsDir>-backdrops` convention and
  never appear there. `Objects` - the free-form art, in file order (later
  draws over earlier); the private `ParseObjects` reads the optional
  `objects` section and refuses an object off the screen list or with a
  width of zero or less. `Pads` - the platforms apart from the grid
  (`Levels.Pads`), in file order, then the collision decks (3.0.60):
  `ParseRoot` calls `AddCollisionDecks` right after `ParsePads` and before
  every check of the pads, and it folds each maximal horizontal run of '2'
  in a row into one static pad (`DecksOfRow` -> `DeckPad`): `Sprite` '',
  no tag, `Bullets` `pbBlock`, X and Y the run's top-left cell, width the
  run, no path, group, plunge, shelf, carousel or stray. The decks are
  appended screen by screen, row by row, left to right. Being still and
  untagged, a deck is a floor to `RespawnHasFloor`. `SolidAt` reads '1'
  only, so to the 2008 oracles a deck is air; the private `CheckPads` refuses a pad off
  the screen list (`SLevelPadBadScreen`), two pads with one tag
  (`SLevelPadTwoTags` - a dynamic object hung on it would go to the
  first) and a path with a stop that puts the pad past an edge of its
  screen (`TryStopOffScreen` finds the first: X below zero or X + width
  past `ScreenWidth`, Y below zero or past `ScreenHeight`;
  `SLevelPadStopOff` - the pad would leave the hero's screen without its
  riders); and, for a pad that plunges (3.0.46, `CheckPadPlunge`), a path
  or a group (`SLevelPadPlungeMoves` - it stands on its place) and a wall
  in the cells under it down to the bottom of the grid, its own included
  (`ShaftUnder` makes the zone, `TryFindWall` looks;
  `SLevelPadPlungeWall` - it falls straight out of its screen, through
  anything, its riders with it); and, for a shelf (3.0.51,
  `CheckPadShelf`), a plunge or a group (`SLevelPadShelfBusy` - a shelf
  leaves the front by its program alone: a plunge would drop the deck it
  has just slid out, a rebuild would fly a pad that is in the wall; a path
  it may travel). `PadGroups` - the pads rebuilt together (`Levels.Pads`), in
  file order. The private `CheckPadGroups` -> `CheckPadGroup` refuses a
  group off the screen list, two groups with one tag, a zone off the
  screen, under three cells either way, with a wall in it (`TryFindWall`)
  or too small for the group's `farFlight` (`CheckPadGroupZone`); a pad
  of the group that does not fill one cell of its screen (`FillsCell`:
  a cell wide, on the grid's lines, on the screen - a cell of the zone no longer, 3.0.38:
  the pad may stand outside and fly in with the first rebuild) or travels
  a path; a pad of the group outside the zone that stands in a wall or
  flush on one (`StandsGrounded`, `SLevelPadGroupGrounded`: no flight
  takes it off); a pad of the
  screen that cuts into the zone and is not of the group (`CutsZone`);
  fewer pads than the pairs and the far flights take, or more than the
  zone has cells; and a pad naming a group nobody carries. After the
  dynamics, `CheckPadGroupLinks` refuses a `conductor` no entity of the
  group's screen carries (`AnyPlacementTaggedOn`) and an `alarm` no
  dynamic object carries. `Carousels` (3.0.52) - the carousels
  (`Levels.Carousels`), in file order, parsed right after the pads and
  before their checks: `PlaceCarouselPads` writes into the `X`/`Y` of a
  carousel's pad where it starts (its orbit at tick 0, the deck's left
  edge and height rounded to whole units), so what reads the places of the
  pads before the game flies them - the checks, an editor - finds them
  there. The private `CheckCarousels` refuses a carousel off the screen
  list (`SLevelCarouselBadScreen`), two with one tag
  (`SLevelCarouselTwoTags`), one with no pad (`SLevelCarouselEmpty` - a
  typo of a tag); for each pad of a carousel (`CheckCarouselPad`) a
  carousel nobody carries (`SLevelCarouselUnknown`), one of another
  screen (`SLevelCarouselScreen`), a pad that also travels a path,
  plunges, is a shelf or joins a group (`SLevelCarouselBusy` - the
  carousel alone moves it), and at any tick of a lap (`LapTicks`) its
  body and the room of its riders - the deck's width, a cell over the
  deck and a cell under it - in a wall or off the screen (`RoomClear`:
  the box on the screen, and no point of it, 8 units apart and half a
  unit inside its edges, `SolidAtPoint`; `SLevelCarouselWall`); for each
  pair of pads of one carousel (`CheckCarouselRoom` ->
  `CheckCarouselPair`) bodies that cut into one another anywhere on the
  lap - closer than their half widths across and a cell down; touching is
  no cut (`SLevelCarouselCrowded`).
  A pad that strays (3.0.58, `CheckPadStray`): one that also travels a
  path, plunges, is a shelf, joins a group or rides a carousel
  (`SLevelPadStrayBusy` - its cycle alone moves it); a zone outside its
  room - left and top from 1, the pad's right edge a cell short of the
  screen's, the bottom on the screen (`SLevelPadStrayOutOfRoom`); a row of
  the zone a wall crosses between the walls of the room, the room over the
  deck included (`SLevelPadStrayRowShut` - the way in, out and across), a
  column of it a wall crosses from the top of the room to the bottom of
  the screen (`SLevelPadStrayColumnShut` - the way down, the fall); all
  through `RoomClear`. A parked carousel (3.0.57) seats an entity over the
  park: `SeatEntity` takes `PadParkedTop` for the deck when the orbit is
  `Parked`, and the body rides its pad down.
  `Events` - the level's events (`Levels.Events`), in
  file order. Queries: `TileAt`, `SolidAt`, `SolidAtPoint(screen, x, y)` (the
  same for a point in screen units - the one home of the units-to-cells
  rule and its guard against negatives; the solid probes of the game and
  of the monsters call it), `BackgroundFor` (the whole
  change, last one wins; `Image = ''` when the level defines none).
  `LoadFromFile`; the pads are parsed before the dynamics, since a dynamic
  object may hang on one; the events right after the dynamics and before
  the rigs (3.0.57: a body an event spawns may wear rigs); the rigs the pads and the monsters wear are hung
  right after the dynamics are parsed and before the checks (`WearRigs` of
  `Levels.Rigs` over the wearers `RigWearersOf` lists - the pads first,
  each followed by its failing look when it rides a carousel that may
  break (`FailingWearer`, 3.0.58: the rigs hang on `FailingRigTag` of the
  pad's tag, named `pad "..." broken`), then the placements, then the
  bodies the spawn actions let in (`SpawnWearer`, 3.0.57: the action's
  `Tag` and `Rigs`, named `spawn of event "..."`), each in file order, so
  the parts of the pads keep
  their places in the list; `PadWearer` and `EntityWearer` make them,
  named for the errors by `PadRigName` of `Levels.Pads` and by
  `EntityRigName` - a placement by its tag or, without one, by what
  stands where: their parts are dynamic objects as the rest, and a
  group's alarm lamps may be among them). Private `CheckEvents` refuses an event
  off the screen list, one watching a tag no placement carries, and
  (`CheckEventTargets` -> `CheckEventTarget`) an intensity action turning a
  tag no dynamic object carries, a sun action turning a tag no globe
  carries, a tactics action naming a tag no placement carries or a
  rebuild or a restore action (3.0.39: `SLevelEventRestoreUnknown`)
  naming a tag no pad group carries; and since 3.0.54: a flyIn whose tag
  is neither a parked pad group nor a parked carousel
  (`SLevelEventFlyInUnknown`) or is carried by both a group and a
  carousel (`SLevelEventFlyInTwoKinds`; `CheckFlyIn` - the game asks the
  carousels first); a shelf action, medkitsOnto, waveOnto, a press row or
  a cannons' yield naming a bank no shelf stands in
  (`SLevelEventBankUnknown`, `AnyShelfOfBank` over `TPadShelf.InBank`); a
  breakCarousel naming no carousel that may break
  (`SLevelEventBreakUnknown`); strays or straysLeave naming a flock no pad
  strays in (`SLevelEventStraysUnknown`). `Dynamics` - the dynamic objects (`Levels.Dynamics`), owned by
  the level (the only destructor here) and kept through a restart - a lamp
  keeps its rhythm; only what a re-armed event changed goes back. Private
  `CheckDynamics` refuses a nailed object off the screen list or a
  `screens` run running backwards or past it (`CheckDynamicScreens`), and
  (`CheckDynamicParent`, which counts the kinds carrying the tag - an
  object, a pad (its own tag or that of its failing look,
  `AnyFailingLookTagged`), an entity, a body a spawn action lets in
  (`AnySpawnTagged`): exactly one) a parent tag none of them carries, a
  tag carried by more than one kind, two
  objects with one tag on one screen, and (`CheckMonsterParent`) two
  entities with one tag on a shared difficulty grade (the child could not
  tell its parent). **`TRespawnPoint`** (record: `Screen`, `X`, `Y`) and
  `Respawns` - where a pit and death return the hero on a screen: a cell
  counted as an entity's is - columns and rows from 1, the feet on the
  bottom line of the row; put there, the hero drops to the floor below.
  JSON: `"respawns": [{"screen": 17, "x": 4, "y": 11}]`, a screen each at
  most (`ParseRespawns`, after the pads). `TryFindRespawn(screen, out
  point)` - False when the level names none for the screen, and the game
  keeps the way of 2008 there: back to where the hero came in. Private
  `CheckRespawns` refuses a point off the screen list
  (`SLevelRespawnBadScreen`), two on one screen (`SLevelRespawnTwice`), a
  cell off the grid (`SLevelRespawnOffGrid`), one in a wall
  (`SLevelRespawnInWall`) and one with no floor under it
  (`SLevelRespawnOverPit`; `RespawnHasFloor` - a wall below in the column,
  or under the cell's middle the deck of a pad that stands still, one with
  no path, no group, no plunge, no shelf and no carousel: a pad that
  travels, is rebuilt, plunges, slides in or flies round may not be
  there). The checks of the cell are `CheckRespawnCell` (3.0.71), and
  `CheckEventRespawns` holds the cell of every respawn action of an event
  (`Levels.Events`) to them, on the event's screen.
  Coming through a door moves nobody to the point; a named deviation from
  2008, whose checkpoint was the entry point and what a heroX / heroY
  trigger wrote.
- The scenes (3.0.62): **`Scenes`** - the level's scenes in file order
  (`Levels.Scenes`), parsed after the dynamics. Private `CheckScenes`
  refuses a scene off the screen list (`SLevelSceneBadScreen`) and, cue by
  cue of its timeline and its aftermath (`CheckSceneCue`): a wake, a fly,
  a wait or a spawn's seat naming no pad of the scene's screen
  (`SLevelScenePadUnknown`, `AnyPadTaggedOn`); a move of no craft
  (`SLevelSceneCraftUnknown`); a track of a part no craft of the tag has
  that turns or slides (`SLevelScenePartUnknown`, `AnyFollowerOf` over
  `TCraft.HasFollower`); an aim at no beam and no lightning
  (`SLevelSceneBeamUnknown`); an intensity of a tag no dynamic object
  carries (`SLevelSceneLightUnknown`); a hold, kill, release or remove -
  and the mark of a track or an aim - naming a tag no entity carries and
  the scene does not bring itself, on its timeline or in its aftermath
  (`SLevelSceneMonsterUnknown`, `SceneSpawns`). Then `CheckDormantPads`:
  a dormant pad no scene's cue wakes (`SLevelPadNeverWakes`). The monster
  ids of a scene's spawns are the field's to check (`CheckSpawnIds`).
  `CheckEvents` refuses a scene action naming a scene the level does not
  have, in any case (`SLevelEventSceneUnknown`, `AnySceneCalled`).
  `CheckDynamicParent` counts a craft among the kinds that carry a tag,
  and `CheckCraftAhead` refuses an object that hangs on a craft standing
  after it in the file (`SLevelDynamicCraftBehind`): it would trail the
  hull by a tick. A pace cue (3.0.67) is checked as an intensity is.
- The shut doors (3.0.66): **`DoorShutOn(screen)`** - the way on out of
  the screen is shut until an event of the screen opens it (the action
  `openDoor` of `Levels.Events`); the door is not seen, the hero stops at
  the threshold. JSON: `"shutDoors": [10, 11]` (read by `ReadScreens`,
  after the events). Sealed doors (3.0.74): `"sealedDoors": [13]` - shut
  for good, no event may open them: the level ends on that screen by its
  own events (level 2's boss arena); `DoorShutOn` is true for them too.
  Private `CheckShutDoors` refuses a screen off the lists
  (`SLevelDoorBadScreen`), one named twice in them together
  (`SLevelDoorTwice`), a shut door no event of its screen opens
  (`SLevelDoorNeverOpens`, `AnyEventOpensDoorOn`), an openDoor on a sealed
  door (`SLevelDoorSealedOpens`) and one on a screen with no shut door
  (`SLevelDoorNotShut`). `CheckEvents` also refuses a heroStands cell off
  the grid (`SLevelEventCellOff`, 3.0.67).

### `Core/Effects.Emitter.pas` (~105 lines)
- **`TParticle`** (record) - place, speed (units per tick), angle and spin,
  age and life (ticks), and three owner's fields: `Shape`, `Scale`,
  `Weight`. `PParticle` - the owner stirs particles through it.
- **`TParticleSwarm`** - particles in order of birth (drawn in order, the
  newest on top), a growing array. `Add`, `Advance(drag, pullX, pullY)`
  (move, keep the drag share of the speed, add the pull, age, drop the
  expired - order kept), `ShiftFrame(dx, dy)` (the owner's frame moved;
  what is in flight stays put on the screen), `Clear`, `Count`, default
  `Particles[i]`. Knows nothing of looks. Users: the smoke; the menu embers
  still carry their own loop.

### `Core/Effects.Sparks.pas` (~385 lines)
The base module of every spark in the game, decoration only. A
**`TSparkField`** holds the sparks of one look and carries them to their
end; who throws them, and when, is the owner's business. Owners: the blast
(`Effects.Debris`), the spark sources of a level and of the game (`TSparks`
in `Levels.Dynamics`), the hits on armor (`Game.Impacts`).
- **`TSolidProbe`** (`reference to function(x, y): Boolean`) - the solid
  layer as the owner sees it, in the field's own coordinates; the unit
  knows no level.
- **`TSparkLook`** (record; per tick, in ticks, in units) - `Gravity`,
  `AirKeep`, `LifeMin..LifeMax`, `Width` and `ThinShare` (every spark rolls
  its width), `StreakTicks`, `SpeedCurve` (1 = even speeds; above it most
  sparks are slow and a few fast - the fan of a grinder), `Level`, `Heat`
  (`TSparkHeat`: hot -> warm at `WarmAt` of the life -> cool), `Wall`
  (`TSparkWall`: `swPass` / `swDie` / `swBounce`), `Bounce` (`TSparkBounce`:
  `Keep` of the speed into the wall, `Grip` along a floor, `LifeLost` of
  the life still ahead), `ForkChance`.
- **`TSparkSpray`** (record) - one throw: `Count`, `Heading` (degrees
  counterclockwise from the right), `Cone`, `SlowSpeed..FastSpeed`.
- `Spray(x, y, spray)`, `ShiftFrame(dx, dy)` (the owner's frame moved; what
  is in flight stays put on the screen), `Tick`, `Draw(brush, origin,
  alpha)`, `Clear`. A field past its capacity drops its oldest sparks.
- Flight (`MoveSpark`): drag, gravity, then by `Wall` - fly on, die on the
  first solid point, or `Rebound`: one axis at a time, like the shards (a
  wall turns X back, a floor or a ceiling Y); every bounce costs
  (`PayForBounce`) a share of the life, and the spark is out on the bounce
  past `MaxBounces` (3) or once slower than `MinBounceSpeed`.
- Forks, the signature of steel: a spark whose life runs out, or that
  survives a bounce, may (`ForkChance`, and only above `MinForkSpeed`)
  throw 2-3 short sprigs within `SprigCone` of its heading. `TryFork` only
  notes the spark while the field is being swept; `ThrowSprigs` runs after
  the sweep. A sprig never forks.
- Drawing (`DrawSpark`): a streak along the speed - the rectangle from the
  tail to the head, `StreakTicks` of path long, turned by
  `SDL_RenderCopyExF`; color by `HeatColor`, brightness `Level * (1 -
  share^2)`, position extrapolated by speed. The texture comes with every
  draw in a **`TSparkBrush`** (`SparkBrush(renderer, streak)`): the
  `gsStreak` comet of `Render.Glow`, or a `gsPoint` blur (the blast).
- Own `TXorShift`, never `Random`.

### `Core/Effects.Traces.pas` (~140 lines)
What a monitor draws, as a pure function. **`TraceAt(source, time, cell)`**
answers -1..1 for a moment in seconds, from the time and the seed alone:
nothing is buffered, so a frame drawn between two ticks agrees with both,
and whoever draws asks for the moment of every column. Knows no screen, no
color and no size. Users: `TGraph` in `Levels.Dynamics`.
- **`TTraceShape`** = (`trHeartbeat`, `trSine`, `trSquare`, `trSaw`,
  `trNoise`, `trFlat`, `trBars`); **`TTraceSource`** (record) - `Shape`,
  `Frequency` (cycles a second; the caller keeps it above zero), `Seed`.
- Heartbeat: a cycle is one beat (`BeatShare` of it; `BeatNodes` - the P
  bump, the dip of Q, the spike of R, the dip of S, the T wave, joined by
  straight lines) and a flat rest. Every beat comes out up to `BeatJitter`
  lower, rolled by its cycle number. Noise: `NoiseSlotsPerCycle` (24) new
  values a cycle, held still inside a slot. Bars: `ACell` is read by bars
  alone; every cell has a clock offset of its own and rolls its targets
  from the seed and its number, and the level eases (smoothstep) from one
  target to the next.
- `SlotRoll(slot, seed)` (private) - 0..1 by a numbered slot. The slot is
  multiplied by a factor under 2^31 in Int64 and added to the seed, not
  xored: the xorshift is linear, so two seeds xored with the same slots
  roll the same numbers less a constant, and a second noise is the first
  one mirrored. `Levels.Dynamics` keeps a `SlotRoll` of its own.

### `Core/Effects.Lightning.pas` (~790 lines, 3.0.34)
The bolt engine under the `lightning` kind of `Levels.Dynamics`; no level
JSON of its own.
- **`TBoltLimb`** / **`TBoltShape`** - the trunk and its branches as
  offsets across their axes (both ends zero, a channel never turns back);
  **`BuildBoltShape(length, jag, fork, coarseSeed, fineSeed, tapers)`** -
  the same seeds, the same shape.
- **`TBoltEnd`** = (`beBridge`, `beStrike` - the end stays put while the
  frame moves, `beStreamer`); **`TBoltLook`** (widths, jag, fork, flash,
  jolt, life, leader, strokes, tint); **`TBoltShot`** (root, end, ending,
  seed); **`TBoltBrush`** / `BoltBrush` - the `gsBeam` band and the
  `gsPoint` glow of `Render.Glow`.
- **`TBoltField`** - `Create(capacity, seed)` (past it the oldest bolt
  goes), `Shoot(shot, look)`, `ShiftFrame(dx, dy)`, `Tick`, `TakeJolt`
  (the strokes since the last ask), `Draw(brush, origin, alpha)`,
  `Clear`, `Count`. A bolt: the leader feels its way, then up to
  `MaxBoltStrokes` (8) strokes along one channel.
- Tests: `Tests.Effects.Lightning`.

### `Core/Effects.Debris.pas` (~635 lines)
What an explosion throws. Decoration, unless a burst is born live
(3.0.44): then each shard carries the lives it takes off a body until it
strikes one or touches a floor - `LandShard` blunts it. The field only
carries the number and shows its live shards to the caller: `Strike(verdict)`
lists them first (`TLiveShard`: `Id`, `X`, `Y`, `SpeedX`, `Drop` - units
below the heart of its blast, `Lives`) and blunts by `Id` the ones the
verdict (`TShardStrike`) says struck, so the caller may burst more debris
from inside the call. Whom a shard strikes is the caller's to say. **`TDebrisField`** takes the renderer and a
**`TSolidProbe`** (of `Effects.Sparks`; in screen units here - the game
passes `SolidUnderPoint`, so the unit knows no level).
- **`TDebrisLook`** (record) - one blast's worth: `Shards`, `ShardSpeed`,
  `ShardSize`, `Heading` (degrees counterclockwise from the right, 90 =
  up: where the shards and the sparks are thrown), `ShardCone` (degrees
  wide, centered on the heading), `RestSeconds`, `Sparks`, `SparkSpeed`,
  `SparkCone` (the same for the sparks, 360 = every way); every piece
  rolls between `MinShare` (0.35) of a value and the value.
- Shards: `TShardState` = (`ssFlying`, `ssSliding`, `ssResting`).
  `FlyShard` moves one axis at a time - a wall turns X back (`WallBounce`),
  a ceiling Y; a floor goes to `LandShard`, which halves the step to find
  the floor line and bounces (`FloorBounce` 0.35, `FloorGrip`) or, slower
  than `RestSpeed`, lets it down to skid (`SlideShard`, `SlideGrip`; off
  the edge of a floor it flies again) and rest. A resting shard lies
  `RestSeconds`, then fades over `FadeTicks`. Color by `HeatColor`: white
  heat -> the ember's red -> bare metal over `CoolTicks`, with a fading
  `gsPoint` glow while hot. Gravity `ShardGravity` = 0.3, the fall of the
  2008 fans. A shard born inside a wall is dropped.
- Sparks: a `TSparkField` of `Effects.Sparks` with `BlastSparkLook`
  (`SpawnSparks` throws them along the look's `Heading` within
  `SparkCone`: all round for the barrel, the machine and the boss) -
  streaks drawn with the
  `gsPoint` glow, white to the ember's red over a life of 5..14 ticks,
  gone on the first solid point or past the edge of the screen
  (`StopsSpark`); no bounce, no forks.
- Shapes: `ShardShapes` (4) torn plates of 5..7 corners, folded once (a lit
  and a shaded half), 2x2 supersampled (`PixelCover`); white, shape in
  alpha, alpha blended, linear - generated in the constructor like the
  puffs.
- Caps `MaxShards` 256, `MaxSparks` 512 - a barrel chain evicts the oldest.
  Own `TXorShift` ("Boom"), never `Random`. `Burst`, `Tick`,
  `Draw(origin, alpha)` (pure: position extrapolated by speed, like the
  smoke), `Clear`. `EDebrisError`.

### `Core/Render.Puff.pas` (~240 lines)
Smoke drawn instead of loaded. `CreatePuffTextures(renderer, side)` makes
`PuffShapes` (4) ragged puffs (`TPuffTextures`) at level load: a soft
falloff eaten into by
fractal value noise (`FractalNoise`, octaves of `ValueNoise` over a
`TXorShift`-hashed lattice), the outline bent by the same noise, white
pixels with a mottled brightness, the shape in alpha. **Alpha blended**,
linear-filtered - smoke hides what is behind it, light (`Render.Glow`) only
adds. `DrawPuff(renderer, texture, cx, cy, size, angle, color, level)` -
centered, turned (`SDL_RenderCopyExF`), tint as color mod, density as alpha
mod. `DrawPuffRect(renderer, texture, dest, color, level)` (3.0.47) - the
puff stretched into a rectangle, unturned: a band of the hero's shroud is
wider than it is tall. `FreePuffTextures`. `EPuffError`.

### `Core/Levels.Tint.pas` (~75 lines)
- **`TColorTint`** (record) - R/G/B multipliers in percent, applied when
  the picture is drawn; `Neutral` = 100/100/100 (as painted).
- **`ReadTint(obj, owner, key = 'tint')`** - reads `"tint": [r, g, b]` (or
  another key of that shape - the smoke's `endTint`); absent = neutral,
  any other shape or a value outside 0..100 raises `ETintError` (a picture
  silently left at full brightness looks like a tint nobody tuned).
- Its own unit because several readers share it - backdrops and static
  objects (`Levels.Defs`), pads (`Levels.Pads`), dynamic objects
  (`Levels.Dynamics`) - and `Levels.Defs` uses `Levels.Dynamics`, so the
  tint could live in neither.

### `Core/Levels.Dynamics.pas` (~4560 lines)
The `dynamics` section of level JSON: things placed like the static
objects, but alive. **Every kind lives in this unit**: a new kind is a class
here, a word in `DynamicKindIds`, its layer in `DefaultLayers` and a branch
in `CreateDynamic`.
- **`TDynamicPlacement`** (record) - what every kind shares: `Screen`,
  `screens` (JSON `[first, last]` - one object on a run of screens, read
  into `Screen`..`LastScreen`) or `Parent` (exactly one - with a parent the
  parent decides the screens; the parent is a static object's, a pad's,
  a monster's or - 3.0.62 - a craft's tag), `X`/`Y` (screen units; from the parent's top-left under
  one), `Tint`, `Tag` (the name events turn it by), `Layer`
  (`TDynamicLayer`: `dlBackdrop` - the backdrop itself, bent, under
  everything else: a haze's; `dlSky` - right over the backdrop, still while the
  world shakes, the far things; `dlAloft` (3.0.62) - over the sky, behind
  the static objects and the pads, shaking with the world: what flies
  over the place, a craft and what hangs on it; `dlBack` - with the static objects, behind
  the tiles; `dlFront` - over the monsters, under the hero; the default is
  the kind's), `Turns` (JSON `turns`: the point turns with a parent that
  spins - a lamp on the boss's disc; without a parent it raises at load;
  under a parent that does not spin the point stays where it is, but under
  any monster a place that turns is no longer drawn once that monster is
  dying, dead or gone).
- **`TValueFade`** (record) - a value and where the events take it:
  initial, current, target, step; `Settle`, `HeadFor(target, ticks)`,
  `Tick`. The intensity of every object, the sun of a sky globe; the
  shade, the rumble and the music of a scene (`Scenes.Director`).
- **`TMotionEase`** (3.0.62) = (`meLinear`, `meIn`, `meOut`, `meInOut`,
  `meBack` - 3.0.67, `meFall` - 3.0.71) - how a motion gathers and loses
  speed (**`EasedShare(ease, share)`**, public since 3.0.67: cubic in,
  cubic out, smoothstep; back runs a little past the mark and settles
  onto it, `BackOvershoot` 1.0 - a thing thrown up that hangs; fall is
  the square, a thing let go under a steady pull, so the ticks of a fall
  of d units at a pull g are `sqrt(2 d / g)`); `MotionEaseIds` -
  its JSON words. **`TAxisMotion`**
  (record) - one axis of a motion: `Current`, `From`, `Target`, `Ticks`,
  `Elapsed`, `Ease`; `Settle(value)`, `HeadFor(target, ticks, ease)` (0
  ticks - there at once), `Tick`. A craft's two axes and a beam's swing.
- **`TDynamicObject`** (abstract) - holds the placement and the intensity
  (a `TValueFade`; JSON `intensity`, a percentage, 100 by default) and the
  surge (JSON `surge`, a percentage, 0 by default): how far a parent at
  full effort lifts the intensity toward full - the protected `Intensity`
  every kind reads is level + (1 - level) * surge * effort, never over 1.
  **`FollowEffort(effort)`** - how hard the parent works now, 0..1, told by
  the renderer before the tick; the object eases there and back over
  `EffortEaseTicks` (6) - a jet spools up, it does not switch; an object
  nobody tells stays at rest. `Tick(originX, originY, parentAlive)` works
  out how far the origin moved since the last tick, steps the fade and
  calls the kind's protected abstract `Advance(motionX, motionY,
  parentAlive)`; `FadeTo(level, ticks)`, `Rewind` (virtual: back to the
  level file's intensity, origin forgotten), `ForgetOrigin` (the next tick
  counts no motion), `Origin` (where the last tick counted from). Two
  constructors: from JSON, or with the intensity given (for objects the
  game makes itself). `Draw(canvas, originX, originY, alpha)` adds X/Y to
  the origin and calls the protected abstract `DrawAt`. Virtual
  `Acquire(canvas)` / `Release` - what a kind makes for itself to draw with
  (empty in the ancestor). The pace (3.0.67): `Pace` - how far the
  object's own clock moves in a tick (a `TValueFade`, 1 - as the level
  file has it, 0 - stopped), `PaceTo(pace, ticks)`; the scene cue `pace`
  stills the dust with it. Virtual `GoesOutWithParent` - True for a kind
  that leaves nothing in the air, a beacon and a haze (False in the
  ancestor): `Render.Dynamics` does not draw such an object while its
  parent monster is dead or gone, so the lamps and the haze of a dead
  monster go out with it. The parent is coordinates only,
  VCL-style: it owns nothing.
- **`TDynamicObjects`** (`TObjectList<TDynamicObject>`) - `FadeTagged(tag,
  level, ticks)`, `PaceTagged(tag, pace, ticks)` (3.0.67), `RewindTagged(tag)`, `TurnSunTagged(tag, degrees,
  ticks)`, `AnyTagged(tag, kind = nil)` (the kind is a
  `TDynamicObjectClass`, nil = any): what the events and the level
  checks ask.
- **`TDynamicCanvas`** (record) - renderer + the glow textures (since
  3.0.70 the disc twice: `DiscGlow` added, `DiscShade` blended) + the puff
  textures every kind draws with + `Art` (the cache of the level's object
  art - its own set and the declared shared ones);
  the textures are made and freed by `Render.Dynamics`, `Art` is handed to
  it and outlives it. `Solid` - the solid layer as a `TSolidProbe` in
  screen units, for what a kind throws (`SolidInView` of
  `Render.Dynamics`). `Backdrop` - a **`TBackdropView`** (the texture, its
  tint, the screen units it is stretched over; texture nil - the screen has
  none), set by the renderer before it draws the backdrop layer. `Scale` /
  `Tone` - how much of its size and of its light the object being drawn
  keeps: 1 in front, less under a parent gone into the depth of the screen;
  the renderer sets them for every object, and the kinds that hang on pads
  obey them - a beacon, a haze and a smoke.
- **`TBeacon`** - a signal lamp: hot core (tint mixed toward white), halo,
  spill of light around (`SpillScale`), four-spike glint on the flash peak,
  optional starburst rays that stretch with the flash (`RayRestReach`); the
  glass keeps an ember between flashes (`EmberLevel`). JSON properties:
  `blink` (`TBlinkPattern`: steady / pulse / flash / double / faulty /
  dying; default flash), `frequency` (per second of game time), `intensity`,
  `glint`, `rayIntensity` (percentages), `size` (halo across), `rays` (reach
  of a ray, 0 = none). `faulty` - a cycle cut into slots that hold, sag or
  drop out; `dying` - every cycle a new dim level (5-40%); both roll through
  `SlotRoll` (own `TXorShift`, never `Random` - that one feeds the boss
  spawn table), a pure function of the slot number, so a frame drawn
  between ticks never disagrees with them. The seed is the position, under
  a parent mixed with the parent's tag (`PlacementSeed`, `TagSalt` - for
  every kind), so lamps at different points, and the lamps of one rig on
  different pads, fail out of step. In the depth (the canvas' `Scale` and
  `Tone`) the lamp is smaller and dimmer, as its pad is. Under a parent
  that is dead or gone it is not drawn (`GoesOutWithParent`).
- **`TSmoke`** - smoke, gas, steam: puffs born at the point (spread around
  it by `SpawnJitter` and, for a moving parent, along the stretch it
  covered this tick - a trail, not beads), thrown along `angle` within
  `cone`, growing from `size` to `endSize` (fast first), fading in over
  `FadeInShare` and out along `FadeOutPower`, tinted `tint` -> `endTint`,
  turning by a random `spin`. Once out, a puff stays put on the screen
  (`ShiftFrame`) and is carried by `drag`, `lift`, `wind` and a swirl -
  `Stir`, a stream-function flow of two drifting waves that grips a puff
  harder as it ages (`TurbulenceGrip`), so a fresh jet flies straight and
  old smoke curls. `flow` (`TSmokeFlow`): steady, gusty (rate modulated by
  value noise over time, knots `frequency` apart, floor `GustFloor`), puffs
  (separate clouds `frequency` a second). `heat` - a fresh puff mixes
  toward the heat color and carries an additive glow of it for
  `HeatShare` of its life: `FireColor`, or JSON `heatTint` (three
  percentages) when the level names one - the blue of a jet; the smokes
  the game makes itself all burn with fire (the tint is read by the JSON
  constructor, it is not of `TSmokeLook`). In the depth (the canvas'
  `Scale` and `Tone`) the whole plume draws in toward its point, smaller
  and dimmer. Intensity scales the rate and, as its square root, a puff's
  density (fixed at birth, so smoke already out fades on its own when the
  events turn the source off). No emission while the parent monster is
  dead or nowhere. `Rewind` also clears the swarm (a death restarts the
  world in full). Particles: `TParticleSwarm` of `Effects.Emitter`, drawn
  through `DrawPuff`; units per second in JSON, per tick in the code. The
  look is a **`TSmokeLook`** record in JSON units (`ReadSmokeLook` fills it
  from the level file, `TakeLook` turns it into ticks); `CreateLook(
  placement, look, intensity, seed)` makes a smoke from code - the wreck
  smoke of the machines in `Monsters`, the explosion plumes.
  `Exhausted` - the source is off and the last puff is gone (an
  explosion's plume is freed then). JSON `outlives` (3.0.62, false by
  default): a smoke on a monster keeps going on its dead body - what
  smoulders after a kill (`cordonAshes` on the betoner the cordon burns).
- **`TSparks`** (kind `sparks`) - sparks from torn metal and bare wires: a
  steady fall (`rate`) and, now and then, an arc - `burst` sparks at once,
  `frequency` a second with uneven gaps, poured over `ArcTicks` under a
  cold flash (`flash`, `ArcColor`) that fades by `FlashKeep`. The sparks
  fly in a `TSparkField` of `Effects.Sparks`, counted from the point they
  leave (`ShiftFrame` keeps them put under a moving parent): `angle`,
  `cone`, `speed` (the fastest one; `SparkSpeedCurve` makes most slower),
  `gravity`, `drag`, `life` (half as much either way), `size` (the streak
  across), `opacity`, `fork`, and the colors `tint` (a fresh spark) ->
  `midTint` -> `endTint`, steel by default. `collide` - `none` / `die` /
  `bounce` (`TSparkWall`): bounce by default in the front layer, none
  behind it; the probe is the canvas's (`Acquire`), shifted into the
  field's frame by `Blocked`. Intensity scales the rate and, softer, the
  size and the frequency of the arcs (`StartArc`); no emission while the
  parent monster is dead or nowhere, and an arc cut short does not resume.
  A source with a `pause` rests: it pours for a `spell`, goes out for a
  `pause` (seconds; each span rolls between half and one and a half of
  its mean) and opens the next spell with an arc - a `TRestClock`,
  ticked at the head of `Emit` (`TickRestClock`). Without a pause the
  clock is never asked and the dice roll as they did.
  `Rewind` also clears the field and puts the clock back on the edge of
  a spell. The look is a **`TSparkSourceLook`**
  record in JSON units (`ReadSparkSourceLook` fills it, `TakeLook` takes
  it, `FieldLook` turns it into a `TSparkLook`); the arc's timers are a
  `TArcClock`. `CreateLook(placement, look, intensity, seed)` makes a
  source from code - the wreck sparks of the machines in `Monsters`, which
  hand over a probe of their own with `UseSolid`. Back layer by default.
- **`TSkyGlobe`** (kind `globe`) - a body in the sky, the Earth over the
  Moon unless the level says otherwise (the dead Earth of Selene, Proxima
  c): a `TGlobe`
  (`Render.Globe`) made in `Acquire` from the object art (`map`, default
  `earth`, resolved like an object's sprite - `sky:earth` names the set;
  optional `night` - city lights, in the same set or `EDynamicError`),
  freed in `Release`. The sun
  travels the arc over the screen - `sun` in degrees: 0 the left horizon,
  90 overhead, 180 the right horizon, below zero not yet risen; the Earth
  hangs at `altitude` over the horizon and `azimuth` right of straight
  ahead (at 90 it sits on the sun's arc - where an eclipse can happen).
  `Relight` turns them into the sun vector of the Earth's own view, so
  phase and the lean of the terminator come out as in the real sky: a sun
  on the left horizon leaves a half lit on the left, one not yet risen
  more than half, one climbing toward the Earth a crescent. The sun is a
  `TValueFade` the `sun` event action turns (`TurnSun`) - only onward: a
  turn back is ignored, so an event replayed after a death cannot undo the
  morning. The globe is lit again once the sun moved `RelightStep` (0.05
  degrees). Other JSON: `size` (the disc across, screen units; x, y its
  center), `brightness` (a percentage of `GlobeLook.Exposure`, past 100
  allowed), `nightBrightness` (a percentage of `GlobeLook.NightGain`, 2.5 -
  city lights are a few texels across and need more than sunlit ground),
  `longitude` (the meridian facing the Moon), `tilt` (the axis
  top leaning left), `atmosphere` (a percentage, 0 = airless - the dead
  Earth of Selene), `surface` (matte / regolith). Intensity is the globe's
  alpha, tint its color mod. Sky layer by default.
- **`TFan`** (kind `fan`) - a ventilation fan: a rotor the code turns
  behind a guard that stands still, so the light painted on the guard never
  spins with the blades. The pictures come from the object art by the
  middle of their names: `rotor` "heavy" is `rotor-heavy-N`,
  `rotor-heavy-smear-N` and `rotor-heavy-disc-N`, the optional `guard`
  "spider" is `guard-spider-N`, the optional `back` "shaft" is
  `back-shaft-N` - every one a square with the axis at its center. The
  back stands behind the rotor, under the light: a guard that is a plate
  with an opening would show the backdrop through it. N is the side:
  `FanArtSideFor` takes the smallest of `FanArtSides`
  (64 / 128 / 256 / 512) that is still as dense as the backdrops
  (`FanArtDensity`); a bare name only, no `set:` qualifier. `Acquire` asks
  the cache for them, so a picture the art lacks raises `ESpriteError` at
  level load. `rpm` is turns a minute, counterclockwise above zero and
  clockwise below: a rotor is painted turning counterclockwise, and a fan
  that turns clockwise mirrors it. The rotor blurs with its speed
  (`DrawAt`; a `TFanArt` holds the five pictures): sharp up to
  `SharpUpToRpm` (40), fully smeared at
  `SmearedAtRpm` (110), a disc from `DiscFromRpm` (230), neighbors
  crossfaded - at 60 frames a second sharp blades turning fast strobe and
  seem to crawl backward. `Advance` eases the rate toward the full rate
  times the intensity (`SpinUpEase`; `CoastEases` - a rotor coasts down
  far longer than it spins up), so the intensity events spin a fan up and
  down; a dead parent monster cuts the power; unpowered and under
  `StandstillRate` the rotor stops. `run` (`TMotorRun`) is `steady` or
  `dying`: a dying motor catches and stalls on a `TMotorClock`
  (`TickMotor` - a catch is short far more often than long and pulls
  `CatchFloor`..1 of the full speed; own `TXorShift`), and its rotor drags
  to a stop sooner. Fans at different points stand at different angles
  and turn up to `SpeedDetune` (4%) apart - `SlotRoll` over
  `PlacementSeed`, in even slots (`SlotRoll` sets the lowest bit of the
  seed, so slot 1 rolls as slot 0). Other JSON: `size` (the square across;
  x, y its center), `tint` (multiplies the art), `light` (the glow of the
  shaft behind the blades, three percentages, absent = none;
  `ShaftLightScale` of the size across). Every picture goes through
  `DrawFanLayer` with a `TFanPose` (dest, angle, flip, tint) - two poses a
  frame, one standing for the back and the guard, one turning for the
  rotor - which skips a picture that is not there and puts the alpha mod
  back to opaque: the static objects draw from the same cache and set no
  alpha. Bottom to top: back, light, disc, smear, sharp, guard. `Rewind`
  puts the rotor back as the level opened
  (`Start`: a steady fan at speed, a dying one standing on the edge of a
  catch). Back layer by default.
- **`THaze`** (kind `haze`) - heat haze: the backdrop seen through hot
  gas. The picture behind a plume is drawn again on a mesh
  (`SDL_RenderGeometry`; `BuildMesh` - `HazeColumns` (16) cells across,
  however wide the plume is there, and cells `HazeRowLength` (2 units)
  long) whose corners smooth noise pushes about: `RollPushes` - two layers
  of noise (`HazeLayers`: large slow eddies and small fast ones, so no wave
  shows) carried along the flow; `PlaceVertices` - every knot
  (`THazeKnot`: `Across`, `Along`, `Grip`) stays where
  the plume puts it and shows the point of the backdrop its push has moved
  there, hardest in the core and not at all on the rim (`Grip` is 0 on all
  four rims: no seam by construction). A second, part-clear copy
  (`THazeCopy` = `hcSharp` / `hcBlur`, `HazeBlurOpacity`), pushed a quarter
  turn round, blurs the picture, and the vertex color shades the core. It
  bends the backdrop alone: it lives on the layer `backdrop` (any other
  raises, `SHazeLayer`) and draws nothing on a screen without a backdrop.
  Hazes do not add up - where two overlap, the later in the file paints the
  backdrop over the earlier one's. JSON: `angle` (degrees counterclockwise
  from the right, 90 = up, the default), `length`, `mouth` and `width`
  (across at the point and at the far end; the plume widens fast at the
  point - `HazeFlare`), `shift` (the farthest a point of the backdrop is
  moved across the flow), `grain` (the size of the larger eddies; under 1
  raises - `MinHazeGrain`), `speed` (the flow, units a second), `shade` (a
  percentage), `blur` (false leaves the second copy out); intensity scales
  the shift and the shade. The noise: a lattice point rolls through
  `LatticeRoll` - `Scramble` twice, a multiplication in Int64 by a factor
  under 2^31, so the overflow check has nothing to catch (the xorshift of
  `SlotRoll` leaves the neighbours of a lattice alike, and the noise shows
  blocks); a frame rolls the lattice round the plume once for each layer
  (**`TNoiseWindow`**: `Roll`, `NoiseAt`) - a knot reads four points and a
  point is read by many knots; the window's edges are spelled as the knots'
  own places, so a knot on the edge cannot round out of it. The rows of
  the lattice repeat after `NoiseRows` (65536); the flow is counted within
  them, in Double. In the depth (the canvas' `Scale` and `Tone`) the plume
  is smaller about its point and weaker. Under a parent that is dead or
  gone it is not drawn (`GoesOutWithParent`). Backdrop layer by default.
- **`TGraph`** (kind `graph`) - a trace on a screen: the line a monitor
  draws, in a frame of its own. `TGraphLook` (record: `Width`, `Height`,
  `Amplitude`, `Sweep`, `Thickness`, `Glow`, `Grid`, `GridStep`,
  `GridColor`, `Plate`, `PlateColor`) lays the frame out; a `TTraceSource`
  of `Effects.Traces` (seed from `PlacementSeed`) says what is drawn. A
  `THudBrush` made in `Acquire` and freed in `Release` draws, bottom to
  top: the plate, the grid (lines go out from the middle, so the baseline
  is a line of the grid), the trace. `DrawTrace` cuts the frame into
  columns (`GraphColumnsPerUnit`, 2 a unit) and sweeps a head across them
  left to right once in `sweep` seconds; a column shows the trace as it was
  when the head passed it, so the farther the head is past it the dimmer
  (down to `GraphTrailKeep`) and the less white it is, a stretch of
  `GraphWipeShare` ahead of the head is dark and the line is not carried
  across it, and a glow rides the head. Bars (`DrawBars`) have no head: they
  stand on the bottom edge of the frame, never shorter than a line. The light
  is the intensity times the canvas' `Tone`. JSON: `shape` (heartbeat /
  sine / square / saw / noise / flat / bars; heartbeat by default),
  `frequency` (cycles a second), `width`, `height`, `thickness`, `gridStep`
  (units) and `sweep` (seconds) - all above zero; `amplitude` (80), `glow`
  (60), `grid` (0) and `plate` (0) - percentages; `gridTint` (the tint by
  default) and `plateTint`; `tint` is the color of the trace. A bad word, a
  zero size or a percentage out of 0..100 raises `EDynamicError`, a bad
  tint `ETintError`. Back layer by default; goes out with its parent
  (`GoesOutWithParent`). Hangs on the monitor of the med lab (`s12-monitor`
  of level 1).
- **`TLightning`** (kind `lightning`, 3.0.34) - now and then a crooked
  bolt strikes within `reach` of the point, throws branches and fades -
  a short in a panel, a wire gone live; pure decoration, a bolt wounds
  nobody. The root rolls in a box (`spread`) round the point, the bolt
  leaves along `angle` within `cone`, 55-100% of reach long.
  **`TLightningCollide`**: `lcNone` - it spans the two points and lights
  both (back layer); `lcStrike` - it marches through the solid layer
  (`UseSolid`, `FindMatter`) and ends on matter with a flash and a light
  over the room, or goes out as a short streamer (front layer).
  **`TLightningLook`** - the JSON words (size, jag, fork, frequency,
  strokes, life, leader, spell, pause, flash, jolt) as shares;
  `BoltLook` turns it into the engine's `TBoltLook` at the intensity.
  The bolts live in a `TBoltField` of `Effects.Lightning`; `TakeJolt`
  (virtual on the ancestor) hands the game the shake of the strokes;
  `PointAt` - see `TBeam`. Intensity scales the frequency, the length,
  the width and the strokes; 0 - silent.
- **`TCraft`** (kind `craft`, 3.0.62) - a machine built of the pictures
  of one set of the level's object art (`set`): a body (`body`, `width` in
  units, the height from the picture) and its parts (**`TCraftPart`**:
  `sprite`, `tag` - a group shares one -, `at` - the point of the body it
  hangs on -, `width`, `anchor` - `top` by default, `center` or `pivot`
  with a `pivot` of its own picture -, `turns` - degrees either way a part
  that swings about its pivot may go, a gun - or `reach` - units a part
  slides toward a point, a pupil; never both, and a part that turns hangs
  by its pivot: `SCraftTurnsAndSlides`, `SCraftTurnsLoose`), drawn back
  to front in the file's order, every picture tinted by `tint`, the whole
  as opaque as the intensity. The one kind that never moves by itself: it
  stands at `x`, `y` (the body's top-left) until a scene moves it -
  **`MoveX` / `MoveY(target, ticks, ease)`**, each axis a `TAxisMotion`
  of its own. **`CornerAt(alpha)`** - the corner between the last tick
  and this one: the craft and what hangs on it are drawn there.
  **`Watch(partTag, point)`** - the parts of the tag that follow head for
  the point, told every tick; `Unwatch(partTag)` - back to how they are
  drawn; a gun swings `PartTurnPerTick` (1.5 degrees) a tick, a pupil
  slides `PartSlidePerTick` (0.25 units) - a machine's pace, not a
  glance; both drawn between the ticks. **`HasFollower(partTag)`** - some
  part of the tag turns or slides (the level's check of a track).
  `Rewind` - back to the file's place at once, the parts at rest. A body
  wider than 2048 px is cut into strips (the cordon's hull, `hull-1..3`):
  the strips after the first hang on it as parts by their top-left
  corner (`anchor` `pivot`, `pivot` [0, 0]). `Acquire` asks the canvas'
  `Art` for every picture (`set:name`). Aloft by default.
- **`TBeam`** (kind `beam`, 3.0.62) - a beam of light from its point to
  the point it is aimed at, all of one colour, the tint. **`TBeamLook`**
  (JSON `look`): `blScan` (by default) - a soft cone (`DrawCone`, the
  `gsBeam` glow of the canvas), 2 units at the source and `width` at the
  mark (14 by default), full light to a knee a little short of the mark
  (`BeamFadeBefore`) and out to nothing a little past it
  (`BeamFadeAfter`) - light does not stop on a body -, a brighter core
  on the axis, a glow on the lens, a spot on the mark, a faint shimmer;
  `blTractor` - a column of one width, dimmer, rings of light running
  from the source down to the mark and fading toward both ends
  (`DrawRing`). The intensity is how bright it burns, 0 is out. Until a
  scene aims it the end stands at the source; **`AimAt(point, ticks,
  ease)`** swings the end onto the mark - from where it was, or out of
  the source when the beam is dark -, **`Follow(point)`** tells it where
  the mark is now; `Rewind` - back at the source, aimed at nothing.
  Front layer by default; the tractor of the cordon is aloft. A scene's
  aim turns lightning too: **`TLightning.PointAt(point)`** heads the
  angle of its look there from then on, the cone round it - the arcs run
  down the burning beam.
- **`TDust`** (kind `dust`, 3.0.65) - levitating dust in the depth of
  the tunnel screens of level 2: long bands (**`TDustBand`**: `Sprite`,
  `Y` - the middle line -, `Height`, `Length` - one turn of the art, 768
  by default -, `Speed` units a second, `Sway` units each way over
  `SwayTime` seconds from a phase of its own, `Density`; `SeamAt`,
  `MiddleAt`) that drift and sway, slow - no wind on the Moon. A band is
  seen only as the light finds it: **`TDustLight`** - a shaft out of a
  hole (`from`, `to`, `width` at both ends, `level`), a glow off a lit
  floor (`at`, `reach`, `level`) and `ambient`; `LevelAt(x, y)` is
  reckoned at the corners of a mesh over the band (`DustColumnStep` 4,
  `DustRows` 8, `DrawBand` -> `DrawRun`), tinted by the light and added
  over what is behind. No `light` lights the bands evenly and in full.
  The art is white, the dust in its alpha, seamless across (`dust.mset`,
  `tools/dust/build_dust.py`). Sky layer by default; the bands move by
  the object's clock (`FClock`, at its pace - 3.0.67), so a scene stills
  them. `SDustNoBands`, `SDustNoSprite`, `SDustShaftNowhere`,
  `SDustBadWidths`, `SDustBadReach`.
- **`TEclipse`** (kind `eclipse`, 3.0.67) - the dark a thing of the void
  spreads round itself, the moon stone's black glow. **`TEclipseLook`**
  (JSON `look`, `EclipseLookIds`): `elVoid` (by default) - the world
  darkens toward black in a soft disc `reach` units from the heart,
  `depth` deep at full intensity (80 by default), and a soft cold halo
  `rim` units across glows behind the heart in the tint (0 - none);
  `elWave` - the ring of dark it sends out as it wakes: out from the heart
  to `reach` as the intensity runs 0 to 1, fading as it goes, not there
  at either end - a scene runs it up once. Owned textures, a disc and a
  ring of `EclipseImageSide` (128) px (`RadialImage`, `DiscLevel`,
  `RingLevel`, `CreateDarkTexture`), made in `Acquire`. Back layer by
  default: over the static objects and the pads, under the monsters - the
  stone stays clear of its dark.
- **`ParseDynamic(obj, levelId, where)`** - one object, written as an item
  of the section is; `where` names it in errors after its kind ("#2" makes
  "beacon #2"). The section and the rigs (`Levels.Rigs`) both read through
  it. **`NameRoll(name)`** - 0..1 by a name, the 1 left out, the same at
  every load (`TagSalt` - a name as a number - and `Scramble` twice): the
  dice of a rig's spreads.
- **`ParseDynamics(root, levelId)`** - reads the section (absent = empty
  list, the caller owns it); an unknown kind, layer, blink, flow,
  surface, collide or run, none or more than one of screen, screens and parent, a broken
  `screens` pair, a number out of range raise `EDynamicError`
  (`ReadWord`, `ReadShare`, `ReadPositive`, `ReadReach`, `ReadScreens`).
- `LogicTicksPerSecond = 33` - frequencies are per second; the logic runs
  33 ticks a second.

### `Core/Levels.Events.pas` (~710 lines)
The `events` section of level JSON: model and parser, no game logic (the
game runs them through `Events.Director`; the editor will write them).
Most of the vocabulary since 3.0.54 belongs to the gravel arena of level
2's screen 9 (`docs/mechanics/arena-2.md`).
- **`TEventCondition`** = (`ecEnterScreen`, `ecAllDead`, `ecLivesBelow`,
  `ecEnraged`, `ecActReached`, `ecGravelDealt`, `ecTrialDone`,
  `ecWaveKilled`, `ecVictoryEnds` (3.0.63), `ecHeroStands` (3.0.67)) -
  what the event waits for. The hero must be on the
  event's screen for any of them; enterScreen asks nothing more; the
  tagged ones (`TaggedConditions`) watch the monsters carrying the tag:
  allDead - none alive, livesBelow - one alive with fewer lives than
  `lives` (a mark told for the normal grade: it grows with the difficulty
  as the lives do - `TMonsterField.AnyTaggedLivesBelow`), enraged - one
  alive in its rage (the boss below its rage mark, a tank below its own).
  The trial's (3.0.54 on): actReached - the gravel trial has come to its
  act `act` or past it (0 while it does not run, so a restart, which
  starts the trial on act 1 again, re-arms the act 1 events);
  gravelDealt (3.0.57) - gravel number `batch * part div of + 1` of act
  `act` is let down (an aimed one counts from its mark), and stays true
  once the act is past: `"part": 1, "of": 3` of a batch of 15 is the 6th;
  trialDone (3.0.59) - the trial of the screen has finished, its last act
  won (cleared by a restart); waveKilled (3.0.59) - `count * part div of`
  bodies of the wave are killed in act `act`, true once the act is past
  (`"act": 6, "part": 1, "of": 2` - half the wave). `ReadActShare` reads
  the act and the share of the last two. victoryEnds (3.0.63) - the
  trial's victory track has `lead` seconds left or fewer (`LeadSeconds`,
  0 by default - it is over, `SEventBadLead` below 0), true after its
  end, cleared by a restart. heroStands (3.0.67) - the hero stands in the
  cell `x`, `y` (`CellX`, `CellY`, counted as a placement's, from 1 -
  `SEventNoCell`): his middle over the column, his feet on the row's
  bottom line, not in a jump or a fall.
- **`TEventActionKind`** = (`eaBigMessage`, `eaSmallMessage`, `eaHint`,
  `eaMusic`, `eaIntensity`, `eaSun`, `eaTactics`, `eaRebuild`, `eaRestore`
  (3.0.39), `eaShelvesWake`, `eaShelvesSleep`, `eaShelvesProgram`,
  `eaFlyIn`, `eaMedkitsOnto` (3.0.54), `eaCannons` (3.0.56), `eaSpawn`
  (3.0.57), `eaBreakCarousel`, `eaStrays`, `eaSkyFall` (3.0.58),
  `eaWaveOnto`, `eaStraysLeave`, `eaPress` (3.0.59), `eaScene`
  (3.0.62), `eaGoRight` (3.0.63), `eaOpenDoor` (3.0.66), `eaEnergy`
  (3.0.70), `eaRespawn` (3.0.71)). **`TEventAction`**
  (record) - kind and what the kind reads:
  - the messages: localized `Text`; a hint also `Header` (who speaks,
    localized as the text; empty - the channel itself, `STerminalHeader`)
    and `AtBottom` (JSON `"place": "bottom"`, `"top"` by default - the
    comm box on the bottom edge for a screen where the hero comes in at
    the top; `SEventBadPlace` for another word; `ReadHint`; added for the
    transmission of level 2's screen 7, between 3.0.52 and 3.0.53);
  - music: `FileName`, `FadeSeconds` (3.0.63, JSON `fade`, 0 by
    default - at once; `SEventBadFade` below 0: the track comes in from
    silence), `FadeOutSeconds` (3.0.74, JSON `fadeOut`, 0 by default - the
    track before is cut; `SEventBadFadeOut` below 0: the track that plays
    fades out first, then this one starts); intensity: `Target`, `Level` (0..1, JSON `value`
    a percentage), `Ticks`; sun: `Target`, `Angle` (JSON `value` in
    degrees), `Ticks`; tactics: `Target`, `Tactics` (a word of
    `EventTacticsIds`: laps / dives / rams / hunts, see
    `Monsters.Pilot`); rebuild, restore: `Target` (a pad group,
    `Pads.Arena`);
  - the shelves (`ShelfActions`: shelvesWake, shelvesSleep,
    shelvesProgram; `ReadShelves`): `Target` - a bank (`TPadShelf.Banks`
    of `Levels.Pads`); `Shelves` (a `TShelfProgram`: `Kind` - a word of
    `ShelfProgramIds`, hold / wave / alternate / blink, `"program"`, hold
    by default, required by shelvesProgram (`SEventNoProgram`); `out`
    and `in` seconds, 2 and 1.5 by default, 0.6 and 0.5 for a blink;
    `warn` seconds, 0 - the shelf's own); `Telling` (a `TBankTelling`:
    `order` - a word of `BankOrderIds`, file / left / right / up / down /
    toHero, file by default; `step` seconds between two shelves; `pick` -
    only that many of the bank, as the dice pick them, 0 = every one,
    3.0.58); `SpareHero` (shelvesSleep only, `"spareHero": true`,
    3.0.57: a shelf the hero stands on waits until he is off it).
    shelvesWake brings the bank out to run its program, shelvesProgram
    switches it (waking one asleep), shelvesSleep warns and slides it in
    for good. A turn of no seconds, a wait or a step below zero, a pick
    below zero raise (`SEventShelfNumber`, `SEventBadPick`);
  - flyIn (3.0.54): `Target` - a pad group parked above
    (`Pads.Arena.FlyIn`) or, since 3.0.57, a parked carousel
    (`TPadWorld.TryFlyInCarousel`); medkitsOnto and waveOnto (3.0.59):
    `Target` - a bank the trial's medkits / the bodies of its wave come
    down over from now on; strays and straysLeave: `Target` - a flock
    (`Pads.Stray`): let go, or sent away for good;
  - cannons (3.0.56): `Cannons` - a **`TCannonOrders`**: `Rows` (the
    rows they stop at to fire, cells from 0 at the top, on the screen -
    `SEventNoCannonRows`, `SEventBadCannonRow`), `YieldBank` (`"yield"`,
    optional) and `YieldRows` (`"yieldRows"`, required with a yield -
    `SEventNoYieldRows`; `ReadRows`): `Game.Cannons`;
  - spawn (3.0.57): `Spawn` - a **`TSpawnOrders`**: `MonsterId`
    (`"monster"`), `SpriteList` (optional - the key a placement has; the
    platform's definition names none), `Row` (on the screen,
    `SEventBadSpawnRow`), `Side` (`"from"`: a word of `EventLaneSideIds`,
    left / right, `TLaneSide` of `Monsters.Defs`), `Tag` and `Rigs`
    (`"tag"`, `"rig"` - optional, the rigs hang on the tag at load):
    the body comes in through the wall along the row
    (`TMonsterField.SpawnInLane`);
  - breakCarousel (3.0.58): `Target` and `Breakdown` - a
    **`TCarouselBreak`**: `HaltSeconds`, `StepSeconds` (`"halt"`,
    `"step"`, 0 by default, not below 0 - `SEventBreakNumber`);
  - skyFall (3.0.58): `SkyFall` - a **`TSkyFall`**: `MonsterId`,
    `EverySeconds` (above 0; `SEventNoSkyMonster`, `SEventBadSkyPace`);
  - press (3.0.59): `Press` - a **`TPressOrders`**: `Rows` (banks, top
    first, two at least, none empty - `SEventPressRows`), `EverySeconds`
    (above 0 - `SEventPressPace`): `Game.Press`;
  - scene (3.0.62): `Target` - the id of a scene of the level
    (`Levels.Scenes`); the director's cue `StartScene` begins it. The
    scene has no condition of its own: an event is its start;
  - goRight (3.0.63): nothing more - the go-right arrow blinks over the
    screen (`Hud.GoRight`), the way on is open;
  - openDoor (3.0.66): nothing more - the door the level shuts on the
    event's screen (`shutDoors`, `Levels.Defs`) opens, and the arrow says
    so. A pickup taken is dead to the field, so allDead on its tag waits
    for the taking;
  - energy (3.0.70): `Amount` - `"value"`, 1..100 (`SEventBadEnergy`
    otherwise, `ReadEnergy`): that many percent of the form's charge come
    out of the hero as orbs and fly into its gauge (the cue `Energy`);
  - respawn (3.0.71): `CellX`, `CellY` - `"x"`, `"y"` from 1, as a
    respawn point's (`SEventBadRespawn` otherwise, `ReadRespawn`; the
    rules of a respawn point at load, `Levels.Defs`): the hero's
    checkpoint moves to that cell of the event's screen (the cue
    `Respawn`); the hero himself is not moved.
  spawn, skyFall and press need an event that waits for an act
  (`SEventSpawnNoAct`, `SEventActOnly`): what they bring belongs to that
  act alone.
- **`TLevelEvent`** (record) - id, screen (1-based), condition, tag,
  `Lives` (livesBelow), `Act` (actReached, gravelDealt, waveKilled),
  `Part` / `Whole` (gravelDealt, waveKilled; `"of"` in JSON),
  `DelayTicks` (counted after the condition holds, for any condition),
  actions. JSON: `"when": "allDead", "tag": "labGuard", "delay": 33,
  "then": [{"action": "hint", "text": "...", "textEn": "..."}]`;
  `"when": "actReached", "act": 4, "then": [{"action": "shelvesSleep",
  "target": "s09-pyramid", "order": "up", "step": 0.2, "spareHero":
  true}, {"action": "flyIn", "target": "s09-carousel"}]`.
- `EventConditionIds` / `EventActionIds` / `EventTacticsIds` /
  `EventLaneSideIds` - the JSON vocabulary as typed constants.
  `ParseLevelEvents(root, levelId)`; an absent section is an empty list,
  an unknown condition or action, a missing id, a tagged condition
  without a tag, livesBelow without lives above zero, actReached without
  an act above zero (`SEventNoAct`), gravelDealt or waveKilled without an
  act (`SEventNoBatchAct`) or with a share that is no share - `of` above
  zero, `part` from 0 to below `of` (`SEventBadShare`) -, intensity
  without a target or with a value outside 0..100, sun without a target
  or without a `value`, tactics without a target or with an unknown word,
  an action that needs a target without one (`ReadGroupTarget`,
  `SEventGroupNoTarget`), an unknown shelf program or bank order
  (`SEventBadProgram`, `SEventBadOrder`), what each action above refuses,
  or an event without actions raises `ELevelEventError`. What needs the
  level - the banks, the carousels, the flocks, the parked groups - is
  `Levels.Defs`' (`CheckEventTarget`, `CheckFlyIn`); the monster ids of
  spawn and skyFall are checked by the field at level start
  (`TMonsterField.CheckSpawnIds`).
- Extending: a condition is an enum member, a word in `EventConditionIds`
  and a branch in the director's `ConditionHolds`; an action the same with
  `EventActionIds` and `Play`, and a cue of `TDirectorCues` when the game
  has to carry it out.
- 3.0.75: the action `ram` (`eaRam`, `ReadRam`): `TRamOrders` - `Stop`
  (JSON `"stop"`, units, the tip of the ram after the drive-in, on the
  screen, `SEventBadRamStop`), `Track` (`"file"`, `SEventNoRamTrack`),
  `SilenceSeconds` (`"fadeOut"`).

### `Core/Levels.Scenes.pas` (~565 lines)
The `scenes` section of level JSON (3.0.62): model and parser, no game
logic (the game plays them through `Scenes.Director`; the editor will
write them). A scene is a play on one screen: cues on a timeline of
ticks move the level's crafts and turn their parts, aim beams, light and
put out dynamic objects, set the sound, the shade and the rumble, speak
through the terminal, hold, kill, bring and take away monsters, wake
and fly pads - while the player keeps the controls. An event starts it
(the action `scene`); it has no conditions of its own. The plan and the
journal of the first one, the cordon over level 1's screen 9, are in
`docs/mechanics/scenes.md`.
- **`TSceneOnce`** = (`soLevel`, `soLife`; JSON `once`, `level` by
  default) - once a level: a death in the middle plays it again from the
  start, a death after it finds its end standing (the aftermath); once a
  life: a death on its screen rewinds it and it plays again.
- **`TSceneCueKind`** = (`ckSound`, `ckMusic`, `ckShade`, `ckShake`,
  `ckJolt` (3.0.67), `ckMove`, `ckTrack`, `ckAim`, `ckIntensity`,
  `ckPace` (3.0.67), `ckHint`, `ckHold`, `ckKill`, `ckSpawn`,
  `ckRelease`, `ckRemove`, `ckWake`, `ckFly`, `ckWait`); `SceneCueIds` its
  words (JSON `do`). Jolt - one blow to the screen, a share of the
  hardest the game deals; pace - the clocks of the dynamic objects of
  `target` run at a share of the level file's over `ticks` (0 stills
  them); a fly takes `ease` too (`Eased`; without one it brakes as a pad
  does), `back` for the moon stone's step. **`TSceneMark`** =
  (`smHero`, `smMonster`, `smPoint`, `smNothing`) - what a track or an
  aim follows (JSON `on`: `hero`, a monster's tag, `none` - a track only
  -, or `x` and `y` in its place, a point of the screen).
  **`TSceneWait`** = (`swDeckEmpty`) - no live monster on the deck of the
  pad `target` (JSON `until`).
- **`TSceneCue`** (record) - `Id` ('' - nobody counts from it), `At`
  (ticks from the start; `NotTimed` after a cue), `After` (the index of
  the cue it counts from, -1 none), `Delay`, **`Plan`** (the tick it plays
  at if no wait holds it up - the cues stand in this order), `Kind`,
  `Target` (for a spawn the tag it gives), `Part`, `Mark` / `MarkTag`,
  `FileName`, `Level` (0..1, JSON `value` a percentage), `MovesX` /
  `MovesY` / `X` / `Y` (a move's, a fly's, a spawn's, a point mark's),
  `Ticks` (0 - at once), `Ease` (`TMotionEase`, linear by default),
  `Eased` (a fly that follows `Ease`, 3.0.67), `Header` / `Text` (localized; a hint needs both - the header is the
  voice: a scene has no channel of its own), `AtBottom` (JSON `place`),
  `Monster`, `SpriteList` ('' - the monster's own), `Seat` (a pad: the
  body stands in the middle of its deck; or `x`/`y` - the left edge of
  its cell and its feet, one or the other), `FacesRight` (JSON `facing`,
  left by default), `Asleep`, `Waits`.
- **`TLevelScene`** (record) - `Id`, `Screen` (1-based), `Once`, `Cues`
  (sorted by `Plan`, the file's order among equals: a later cue of a
  tick overrides an earlier one, and a cue counted from another stays
  after it; `SortByPlan` keeps `After` pointing at the same cue),
  `Aftermath` (cues with neither `at` nor `after` nor `id`, played all at
  once: the world the scene leaves behind - no sound, hint or wait,
  `MuteAtOnce`).
- When: `at`, or `after` - the id of a cue **above it in the file** - and
  `delay` (0 by default); the cue counted from is known by then, so its
  `Plan` is too, and no two cues can wait for each other (`ReadWhen`,
  `IndexOfCue`). A wait is a cue (`do: "wait"`) that plays once its
  condition holds: the cues after it count from that tick.
- `SceneWorldCues` - what acts on the monsters and the pads (the world
  the aftermath puts, not the scene's own things); `SceneMonsterCues`,
  `ScenePadCues` - the cues whose `target` is a monster's tag, a pad's.
- **`ParseLevelScenes(root, levelId)`** - an absent section is an empty
  list; a typo raises `ELevelSceneError` (`WordOf`: an unknown cue, ease,
  once, until, place or facing), and so do: a scene with no id, two of
  one id in any case, no cues; a cue with both or neither of at and
  after, after a cue not above it, two cues of one id, a tick, a delay or
  ticks below 0, a sound of no file, a value outside 0..100, a cue of no
  target, a move of no axis, a fly not of both, a track of no part, no
  mark, an aim at `none`, a hint short of a header or a text, a spawn
  short of a monster or a tag or not on exactly one of a seat and a point;
  an aftermath cue that is timed or a sound, hint or wait. What needs the
  level is `Levels.Defs`' (`CheckScenes`).

### `Core/Levels.Pads.pas` (~745 lines)
The `pads` section of level JSON: platforms apart from the collision grid.
Model and parser, no game logic (the game runs them in `Pads.World`; the
editor will write them). A pad holds from above only: its deck, the top
edge, carries what lands on it; from below and from the side anything
passes through. Under the deck the pad has a body as deep as its picture,
a cell at the most (3.0.51; `Pads.World` keeps half a cell at the least):
it stops the boss's flight, the sparks and the debris, and the bullets
unless the pad lets them by. A pad may travel a path - there and back along its
stops, or round them - and may bob in the air: the path moves the pad
itself, the bob is for the eye alone (`Pads.World` says why). Pads of a
group are rebuilt together: they fly to a new formation inside the
group's zone, a cell each (`padGroups` names the groups, a pad joins one
by its `group`); a pad the file puts outside the zone flies in with the
first rebuild (3.0.38). A pad may plunge (3.0.46): it holds until the hero
stands on it, then gives way, falls out of the screen and climbs back to
its place - a failing pad, and it looks it (`Pads.Plunge` counts the
cycle); it stands on its place, with no path and in no group. A pad may
be a shelf (3.0.51): it slides out of the wall behind it and back in by a
program of steps that goes round and round (`Pads.Shelf` counts the
cycle); out, it is a pad as any other, on its way and in the wall it is
neither a floor nor a body; it joins no group and does not plunge, a path
it may travel. A pad may ride a carousel (3.0.52, `Levels.Carousels`): it
flies round the carousel's track with the other pads it carries; the
carousel places it, so it takes no `x` or `y`, and it travels no path,
does not plunge, is no shelf and joins no group. Since 3.0.54 shelves
stand in banks the events tell together (a shelf may stand in several,
3.0.57), and a bank's shelf may be held out or in from the start, running
no program until told; the pads of a group may be parked above the
screen until an event flies them in. A pad may stray (3.0.58,
`Pads.Stray`): once an event lets its flock go it flies in from beyond an
edge to points of its zone and out again, misbehaving now and then; its
cycle places it, so it takes no `x` or `y` and does nothing else. A plunge
may stay down for good (3.0.58). A 2026 addition.
- **`TPadPlacement`** (record) - `Sprite` (in the level's object art, as a
  static object's), `Screen` (1-based), `X`/`Y` (the top-left corner in
  screen units, as a static object's; Y is the deck), `Width` (screen
  units; the picture's height follows its aspect), `Tint`, `Tag` (names
  the pad for the dynamic objects hung on it; '' = none), `Bullets`,
  `Path` (a `TPadPath`; `prNone` - the pad stands where it is placed),
  `Stray` (a `TPadStray`, 3.0.58; `Strays` False - it does not),
  `Bob` (how far the pad sways up and down, in units; 0 = still),
  `Plunge` (a `TPadPlunge`; `Plunges` False - the pad holds whatever
  stands on it), `Shelf` (a `TPadShelf`; `Slides` False - the pad never
  leaves the front), `Group`
  (the pad group it is rebuilt with; '' = none), `Carousel` (3.0.52: the
  carousel it rides, by tag; '' = none - the carousel puts `X` and `Y`,
  `Levels.Defs` writes them at load), `Rigs` (the rigs it wears,
  by name, in the order they are hung - `Levels.Rigs` holds them and hangs
  them), `Dormant` (3.0.62, JSON `"dormant": true`: the pad is not there -
  not drawn, neither a floor nor a body - until a scene wakes it; one no
  scene wakes does not load).
- **`TPadPlunge`** (record, 3.0.46) - a pad that gives way under the
  hero: `Plunges`, `Delay` (seconds it holds after he stands on it),
  `Rest` (seconds it lies under the screen), `Rise` (units a second it
  climbs home at - the mean of an uneven climb), `StaysDown` (3.0.58,
  JSON `"staysDown"`, false by default: fallen, it never climbs - the
  broken carousel pads of the arena). `ReadPlunge(obj, levelId, name)` is
  public since 3.0.58: the failing look of a carousel reads its plunge
  with it, the error naming its owner. `DefaultPlungeDelay`
  (0.5), `DefaultPlungeRest` (0.5), `DefaultPlungeRise` (64) - what a
  plunge takes for a number it leaves out.
- **`TPadShelf`** (record, 3.0.51) - a pad that slides out of the wall
  behind it and back in: `Slides`, `Steps` (a `TArray<TShelfStep>`: the
  program, its steps taking turns, out and in, the last and the first
  too; after the last comes the first), `SlideSeconds` (between two
  steps), `WarnSeconds` (before it leaves the front it says so),
  `OffsetSeconds` (it starts this far into its program: shelves in a row
  go as a wave), `Deep` (how it looks in the wall); since 3.0.54 `Banks`
  (the banks the events tell it with: JSON `"bank": "s09-ladder"` or, since
  3.0.57, a list `["s09-floor", "s09-grid"]` - `ReadShelfBanks`; none -
  no event tells it), `Held` and `HeldStand` (JSON `"held": "out"` or
  `"in"` - `ReadShelfHeld`: it stands there from the start and runs no
  steps until an event tells it otherwise; a held shelf needs a bank),
  `InBank(bank)`. **`TShelfStand`** =
  (`shOut`, `shIn`) - where a step holds it; `ShelfStandIds`
  ('out'/'in') - the JSON words. **`TShelfStep`** (record) - `Stand`,
  `Seconds` (held there, the slide not counted). **`TPadDeepLook`**
  (record) - a pad all the way into the depth: `Scale` and `Tone` (shares
  of its size and its light in front), `Sink` (units its picture goes
  down). `DefaultShelfOut` (2.0), `DefaultShelfIn` (1.5),
  `DefaultShelfSlide` (0.25), `DefaultShelfWarn` (0.5),
  `DefaultShelfScale` (0.72), `DefaultShelfTone` (0.4) - what a shelf
  takes for a number it leaves out; the offset and the sink take 0.
- **`TShelfProgramKind`** = (`pgHold`, `pgWave`, `pgAlternate`,
  `pgBlink`) and **`TShelfProgram`** (record: `Kind`, `OutSeconds`,
  `InSeconds`, `WarnSeconds` - 0 the shelf's own) - what a bank runs once
  an event tells it (3.0.54): out for good; out and in by turns, each a
  step after the one before; every other one out of step; short turns,
  each at a time of its own. `ShelfProgramIds` ('hold' / 'wave' /
  'alternate' / 'blink'). **`TBankOrder`** = (`boFile`, `boLeft`,
  `boRight`, `boUp`, `boDown`, `boToHero` - from the farthest from the
  hero to the nearest) and `BankOrderIds`. **`TBankTelling`** (record,
  3.0.58) - `Order`, `StepSeconds`, `Pick` (0 = every shelf): how a bank
  is told; the events read it, `TPadWorld.TellBank` takes it.
- **`TPadStray`** (record, 3.0.58) - `Strays`, `Flock` (the flock an
  event lets go), `Zone` (cells the top-left corner of the deck hangs at),
  `Wait` (seconds after the flock is let go before it first flies in).
  JSON: `"stray": {"flock": "s09-strays", "zone": [4, 3, 11, 8], "wait":
  1.5}` (`ReadStray`; `wait` absent = 0). A pad that strays is placed by
  `ReadPlace` at `PadStrayWaitLeft` (-96), `PadParkedTop` (-64): out of
  sight with its rigs.
- **`PadParkedAbove`** ('above' - the one word of `"parked"`) and
  **`PadParkedTop`** (-64, two cells over the top edge: where a parked
  pad, a parked carousel's pad and a stray wait; moved here from
  `Pads.World` at 3.0.57 so the level seats on a parked carousel at the
  same height the world parks).
- **`TPadZone`** (record) - `Left`, `Top`, `Right`, `Bottom`: cells of a
  screen, 0-based, the bounds included; declared before `TPadPlacement`
  since the stray needs it. **`TPadGroup`** (record) - `Tag`,
  `Screen` (1-based), `Zone`, `Pairs` (at least this many pairs side by
  side in a formation), `FarFlight` / `FarShare` (a flight of `FarFlight`
  cells or more is far; a rebuild flies at least `FarShare` pads far),
  `Conductor` (the tag of the monster the rebuilds follow; '' = none),
  `Every` (seconds between two rebuilds), `Alarm` (the tag of the dynamic
  objects lit to warn of one; '' = none), `Parked` (3.0.54, JSON
  `"parked": "above"`: its pads wait above the screen over their places
  until an event flies the group in; another word -
  `SPadGroupBadParked`).
- **`ParsePadGroups(root, levelId)`** - the section `padGroups`; absent =
  no groups. JSON: `{"tag", "screen", "zone": [left, top, right, bottom],
  "pairs", "farFlight", "farShare", "conductor", "every", "alarm"}`
  (`pairs` and `farShare` absent = 0, `farFlight` absent = 1). `EPadError`
  is raised by a zone that is not four numbers (`ReadZone`, which names
  its owner since 3.0.58 - a group or a stray pad; `SPadGroupBadZone`), pairs or farShare below zero, a farFlight below one
  (`SPadGroupBadNumber`) and a conductor without `every` above zero
  (`SPadGroupBadEvery`). What needs the level - the screen, the walls, the
  group's pads, the conductor, the alarm - is `Levels.Defs`'
  (`CheckPadGroups`, `CheckPadGroupLinks`).
- **`TPadBullets`** = (`pbBlock`, `pbPass`) - what the body does to a
  bullet: bursts it or lets it by. `PadBulletsIds` ('block'/'pass') - the
  JSON words.
- **`TPadRoute`** = (`prNone`, `prPingPong`, `prLoop`) - how a pad goes
  along its stops: not at all, there and back, or round. `PadRouteIds`
  ('none'/'pingpong'/'loop') - the JSON words; a file may write only the
  last two.
- **`TPadStop`** (record) - `X`, `Y` (Single): the top-left corner of the
  pad at a stop, in screen units. **`TPadPath`** (record) - `Route`,
  `Stops` (the stops after the pad's own place, in order), `Speed` (units
  a second, the mean over a leg), `Pause` (seconds the pad stands at
  every stop).
- **`ParsePads(root, levelId)`** - absent section = no pads; `x` and `y`
  are read by `ReadPlace` - required of a pad on no carousel, refused
  beside a `"carousel"` (`SPadCarouselPlaced`), left 0 for `Levels.Defs`
  to fill; `bullets`
  absent = block; `path` absent = no path (`ReadPath`), `bob` absent = 0.
  The JSON: `"path": {"route", "stops": [[x, y], ...], "speed",
  "pause"}` (`route` absent = pingpong, `pause` absent = 0), `"bob"`,
  `"plunge": {"delay": 0.5, "rest": 0.5, "rise": 64}` (`ReadPlunge`;
  absent = the pad holds, a number left out takes its default),
  `"shelf": {"out": 2, "in": 1.5, "slide": 0.25, "warn": 0.5, "offset":
  0, "sink": 7, "scale": 0.72, "tone": 0.4}` (`ReadShelf`; absent = the
  pad never leaves the front, `{}` - a shelf on the defaults), or with
  `"program": [["out", 2], ["in", 0.5], ["out", 0.5], ["in", 1.5]]` in
  place of `"out"` and `"in"` (`ReadShelfSteps`: `StepsOfOutAndIn` makes
  the two-step program of the keys, `ReadShelfStep` reads a step, the
  words in any case; `StepsTakeTurns` asks the order),
  `"group"` and `"rig": ["pad", "arenaAlarm"]` (`ReadRigNames` of
  `Levels.Rigs`; absent = the pad wears nothing). **`PadRigName(pad)`** -
  the pad as the errors of its rigs call it: `pad "<tag>"`, without a tag
  `pad "<sprite>"`, the only name it has then.
  `EPadError` is raised by a width of zero or less (`SPadBadWidth`), a
  bullets word out of `PadBulletsIds` (`SPadBadBullets`), a route other
  than pingpong or loop (`SPadBadRoute`), a path without stops
  (`SPadNoStops`), a stop that is not a pair of numbers (`ReadStop`,
  `SPadBadStop`), a speed of zero or less, a pause or a bob below zero,
  a plunge with a delay or a rest below zero or a rise of zero or less
  (`SPadBadNumber`); a shelf with a `program` beside its `out` or `in`
  (`SPadShelfTwoPrograms`), a step that is not `["out", seconds]` or
  `["in", seconds]` (`SPadShelfBadStep`), steps that do not take turns or
  no steps (`SPadShelfNoTurns`), a step of zero seconds or less, a slide,
  a warn or an offset below zero, a scale out of 0..1 or zero, a tone out
  of 0..1 (`SPadBadNumber`); a bank that is neither a name nor a list of
  names (`SPadShelfBadBank`), a shelf held in no bank
  (`SPadShelfHeldAlone`) or held neither out nor in (`SPadShelfBadHeld`);
  a pad that strays and is given an x or a y (`SPadStrayPlaced`), strays
  in no flock (`SPadStrayNoFlock`), or waits below zero
  (`SPadBadNumber`); a rig that is not a list of names raises
  `ERigError`, in `Levels.Rigs`. The
  screen range, a tag on two pads, a stop off
  the screen, what a plunge needs of the level - no path, no group, a
  clear shaft - and what a shelf may not - plunge, join a group - are
  `Levels.Defs`' (`CheckPads`); what a carousel's pad may not, and the room
  of its lap, too (`CheckCarousels`).

### `Core/Levels.Carousels.pas` (~610 lines)
The `carousels` section of level JSON (3.0.52): pads that fly round a
closed track, one after another, without end. Model, parser and the track
itself, no game logic: `Pads.World` flies the pads, `Levels.Defs` places
them and checks their round. The track is the path of the middle of
every deck - an oval, or a box whose corners may be rounded. It starts on
the right of its middle and runs clockwise on the screen, down from
there (Y grows down: an angle that grows goes clockwise). The pads go
round it at one even pace - by length along the track, not by angle, so
they do not bunch at the narrow ends of an oval - a lap in the
carousel's period, the way it turns, each a share of the lap ahead of the
one before it in file order. A pad keeps its deck level all the way
round. A pad joins by its `"carousel"`; the carousel places it. Since
3.0.57 a carousel may be parked above the screen until an event flies it
in: each pad comes straight down to its slot, and the carousel turns once
all of them are on it, its clock coming up to its pace over the speed-up.
Since 3.0.58 it may break: its clock runs down to a standstill, and its
pads, one after another, become pads that plunge where they stand, in a
look of their own. A 2026 addition.
- **`TCarouselShape`** = (`csOval`, `csBox`), **`TCarouselTurn`** =
  (`ctClockwise`, `ctCounterClockwise` - as seen on the screen);
  `CarouselShapeIds` ('oval'/'box') and `CarouselTurnIds` ('cw'/'ccw') -
  the JSON words, read in any case.
- **`TCarousel`** (record) - `Tag`, `Screen` (1-based), `Shape`,
  `CenterX`/`CenterY` and `Width`/`Height` (the middle of the track and
  its size across and down, screen units, `Single`), `Corner` (a box's
  corner radius; 0 = sharp), `Period` (seconds a lap), `Turn`, `Start`
  (where the first pad starts: a share of the lap from the right of the
  middle, the way the carousel turns); `Parked` (3.0.57, JSON `"parked":
  "above"`, another word - `SCarouselBadParked`; `ReadParked`),
  `SpeedUp` (3.0.57, seconds from a standstill to the pace of the
  period once it starts to turn; 0 = at its pace at once; below 0
  refused), `Failing` (3.0.58).
- **`TCarouselFailing`** (record, 3.0.58) - what a pad of a broken
  carousel becomes: `Breaks` (False - it cannot break), `Sprite` (in the
  level's object art), `Rigs` (by name), `Plunge` (a `TPadPlunge`, read
  by `ReadPlunge` of `Levels.Pads`). JSON: `"failing": {"sprite":
  "s16-platform-out", "rig": ["padFailing"], "plunge": {"delay": 0.5,
  "rise": 64, "staysDown": true}}` (`ReadFailing`); no sprite
  (`SCarouselFailingNoSprite`), no plunge (`SCarouselFailingNoPlunge`),
  or a plunge or rigs a pad would refuse raise. **`FailingRigTag(padTag)`**
  - the tag the rigs of a pad's failing look hang on: the pad's tag plus
  `/failing` (`FailingRigSuffix`; no tag of a file holds a slash).
- **`TCarouselTrack`** (record; its state is private) - the track as a
  closed line of points, the last joined to the first. `Build(carousel)`
  - an oval as `OvalPoints` (360) points (`BuildOval`, within a hair of
  the curve at the size of a screen); a box (`BuildBox`) down the right
  side from the middle, along the bottom, up the left, along the top,
  each rounded corner a quarter circle of `CornerLegs` (12) legs
  (`AddCorner`); then `Measure` - the distance along the line to every
  point and the `Length`. `PointAt(distance, out x, y)` - any distance,
  past a lap or below zero too (folded by `Floor`, not truncation), a
  binary search for the leg, a leg of no length (a side as short as its
  corners - a box rounded all the way is a circle) taken as a point.
- **`TCarouselOrbit`** (record) - one pad's way round: `Build(carousel,
  slot, slots)` - the track, the start `Frac(Start + slot / slots)` of a
  lap along it, the step a lap / `LapTicks` per tick, both negative for
  counter-clockwise. `Rides` - False for `Default(TCarouselOrbit)`, the
  orbit of a pad on no carousel: `Place` says nothing then.
  `Place(time, out x, y)` - the middle of the deck at `time` ticks,
  between ticks too (the world draws between them). `Parked` - its
  carousel waits above the screen. `Clock(turning)` (3.0.57) - the time of
  `Place` that many ticks after the carousel started to turn: the pace
  grows evenly from nothing over the speed-up (the clock runs the area
  under it, `turning^2 / (2 * speedUp)`), after it the clock runs half the
  speed-up behind. `Halting(turning, haltTicks, braking)` (3.0.58) - the
  time of `Place` that many ticks into a halt begun `turning` ticks after
  the start: the pace of that moment (lower inside the speed-up) falls
  evenly to nothing over the halt, and the clock stands from there on.
  `Landing(fromY)` (3.0.57) - the pad's way down to its slot, a
  `TCarouselLanding`: a slot higher than the carousel's lowest deck waits
  its height over it divided by the pace, so every pad brakes at once
  and a pad over another keeps the gap of their slots from the moment it
  sets off; across, the wave ripples out from the middle, 4 ticks a cell
  (`LandingRippleTicksPerUnit`).
- **`TCarouselLanding`** (record, 3.0.57) - `Build(fromY, toY, depart)`:
  straight down at `LandingSpeed` (8 units a tick), braking over the last
  `LandingBrakeTicks` (10); a way shorter than the braking is braked all
  the way, in fewer ticks. `DeckAt(time)` - the deck at a time after the
  fly-in, between ticks too; `Done` - the first tick it stands on its
  slot.
- **`ParseCarousels(root, levelId)`** - absent section = no carousels.
  JSON: `{"tag": "s08-carousel", "screen": 8, "shape": "oval", "center":
  [288, 179], "size": [150, 150], "corner": 0, "period": 12, "turn":
  "cw", "start": 0, "parked": "above", "speedUp": 3, "failing": {...}}`;
  `shape` absent = oval, `turn` absent = cw, `corner`, `start` and
  `speedUp` absent = 0, `parked` absent = in its place from the start; `period` has no default - absent it reads 0 and
  is refused. `ECarouselError` is raised by a shape or a turn out of its
  words (`SCarouselBadShape`, `SCarouselBadTurn`), a `center` or a `size`
  that is not `[x, y]` (`ReadPair`, `SCarouselBadPair`), a width or a
  height of zero or less, a corner below zero or past half the shorter
  side, a period of zero or less, a start out of 0..1, 1 itself excluded
  (`CheckNumbers`, `SCarouselBadNumber`). The screen range, the tags and
  the room of the lap are `Levels.Defs`' (`CheckCarousels`).
- **`TryFindCarousel(carousels, tag, out carousel)`** - False when no
  carousel carries the tag. **`OrbitOf(carousels, pads, index)`** - the
  orbit of the pad at `index`: its slot among the pads of its carousel, in
  file order, counting only the pads of that carousel; a pad on no
  carousel, or on one the list has not, gets one that does not ride.
  **`LapTicks(carousel)`** - the period in ticks (seconds * 33,
  `LogicTicksPerSecond`, local; `Round`), one at the least.

### `Core/Levels.Rigs.pas` (~320 lines)
The `rigs` section of level JSON: what the pads and the monsters wear. A
rig is a named list of dynamic objects (`Levels.Dynamics`) with no place of
their own - a lamp, a jet, the haze under it. A wearer - a pad
(`TPadPlacement.Rigs`) or a monster's placement (`TEntityPlacement.Rigs`) -
names the rigs it wears, and at load every part of them becomes a dynamic
object hung on that wearer: from there on it is one of the level's dynamic
objects, no different from one written into `dynamics` with the wearer for
its parent. A part counts from its parent's top-left corner: a pad's, or
that of a monster's cell. The unit knows neither a pad nor a placement:
`Levels.Pads` and `Levels.Defs` stand over it. A 2026 addition.
- **`TRigWearer`** (record) - who wears: `Tag` (the parts hang on it by the
  tag), `Name` (as the errors call it: `pad "s16-plat-01"`, `entity
  "s07-tek-01"` - `PadRigName`, `EntityRigName`), `Rigs` (by name, in the order
  they are hung).
- **`ReadRigNames(obj, levelId, wearer)`** - the `"rig"` list of a wearer,
  absent = it wears nothing; the one reader for the pads and the
  placements. A rig that is not a list of names raises (`SRigBadNames`).
- **`WearRigs(root, levelId, wearers, dynamics)`** - hangs on every wearer
  the parts of the rigs it wears: they join the list in the order of the
  wearers, then of a wearer's rigs, then of a rig's parts - the drawing
  order within a layer, and the order in which a haze paints over a haze.
  A rig nobody wears is not read at all. `ERigError` is raised by a wearer
  of a rig that carries no tag (`SRigNoTag` - its parts hang on it by the
  tag), two wearers of rigs under one tag (`SRigSharedTag` - placements of
  one monster on two difficulties: a part finds its parent by the tag
  alone, so the one that lives would carry the parts of both), a rig the
  section lacks (`SRigUnknown`), a rig that is not a list of objects
  (`SRigNotList`), a part that names `parent`, `screen` or `screens`
  (`SRigOwnPlace` - a part stands where its wearer does), a spread that is
  not two numbers in order (`SRigBadSpread`); whatever `Levels.Dynamics`
  refuses in a part raises as it does there.
- How a part is hung (`TRigFitter`: `Dress` a wearer, `Hang` a rig, `Worn`
  a part): the part is written out as an object of the dynamics section
  would be for this wearer - a fresh JSON object with the part's values
  copied, every spread rolled and `"parent"` set to the wearer's tag - and
  read by `ParseDynamic`. A `TFitting` (the wearer, the rig, the part's
  number) names the part in errors (`Where` gives "#2 of rig "pad" on pad
  "s16-plat-01"", which `Levels.Dynamics` puts after the kind: "beacon #2
  of rig ...") and names its rolls (`RollName` - spelled apart from
  `Where`: reword an error and every lamp of the level would roll anew).
- **A spread** - `{"spread": [from, to]}` in place of a number of the part
  itself, not of one inside a list such as a tint: every wearer of the
  part rolls its own value between the two, the same at every load
  (`NameRoll` of `Levels.Dynamics` over the wearer's tag, the rig's name,
  the part's number and the key - move a part within its rig and it rolls
  anew; two lamps of one rig are two parts, and each rolls its own). Both
  ends whole - a whole value, either end included (`RolledNumber`): a
  percentage stays one, and `[1, 3]` gives 1, 2 or 3 alone. A fraction is
  spelled with a point whatever the locale of the machine
  (`TFormatSettings.Invariant`): with a comma it would not read back as a
  number.
- JSON: `"rigs": {"pad": [{"kind": "beacon", "x": 16, "y": 25,
  "frequency": {"spread": [0.27, 0.45]}}, {"kind": "haze", "x": 16,
  "y": 27, "angle": 270}]}`; a pad: `"rig": ["pad"]`; a monster:
  `"tag": "s07-tek-01", "rig": ["tekPlatform"]`.

### `Core/Monsters.Defs.pas` (~870 lines)
Monster definition model + registry (parses monsters.json). No behavior.
- **Enums**: `TMonsterCategory` (mcEnemy/Pickup/Prop/Boss), `TMovementKind`
  (mkStatic/Patrol/PatrolNoEdgeCheck/ChaseHero/BossFly), `TAttackPattern`
  (apNone/StraightSingle/StraightCluster5/AimedSingle/AimedDouble/RainVolley),
  `TPickupEffectKind` (peNone/Heal/GiveWeapon), `TExplosionKind`
  (ekNone/Barrel/Machine/Boss/Mount - the look of a death, JSON `explosion`,
  an unknown word raises; independent of the `blast`),
  `TMonsterMaterial` (mtNone/Metal - JSON `material`, what a bullet does to
  the body: metal throws sparks, see `Game.Impacts`; an unknown word
  raises), `TPilotTactics` (ptLaps/Dives/Rams/Hunts - what a flying boss
  does besides his lap, see `Monsters.Pilot`; set by the level's events,
  not by monsters.json).
- **Records**: `TMovementDef` (kind+speed); `TAttackDef` (pattern, fire cadence,
  bullet speed, pattern-specific params, `Sentry`, `HasAttack`);
  `TSentryDef` (JSON `attack.sentry`: `Reach` - the units either way of the
  monster's middle that the strip it watches reaches; `ParseSentry` refuses a
  reach of 0 or less, `SBadSentry`); `TPickupEffectDef`
  (peGiveWeapon rewires the whole weapon: type, cooldown, speed, gravity);
  `TSpawnEntry` (monsterId+weight); `TBossDef` (endsLevelOnDeath, spawn
  cadence/screen/table, `RageMusic`, `DodgePrize` - JSON `dodgePrize`, the
  monster id of what a hero who has dodged a ram is handed, '' = nothing -
  `PickSpawn` weighted random);
  `TDiscDef` (JSON `disc` - the living monster is drawn as a spinning disc
  out of layers, see `Monsters.Disc`: `SetName` - the layers' set, `Side` -
  their square in screen units, `Muzzle` - how far from the axis an aimed
  shot leaves, 0 = where any monster's does, `Spin` - degrees a tick,
  counterclockwise, `IrisReach` - how far the eye slides toward the hero,
  `WearFull` - the share of lives lost at which the worn look is complete,
  `PortAngles` - JSON `portAngles`, where the barrels of the art point on
  the unturned rim, degrees counterclockwise from the right; a volley is
  one bullet out of each, none by default;
  `Enabled`; a disc without a set or a positive side, with a muzzle outside
  0..side/2 or `wearFull` outside (0, 100] raises at load);
  `THullDef` (JSON `hull` - the living monster is drawn as a hull out of
  layers, see `Monsters.Hull`: `SetName` - the layers' set, `Width`,
  `Height` - the hull's size in screen units, `WearFull` - as the disc's,
  `Eye`, `Smoke`,
  `Sparks` - `THullPoint`s, screen units from the hull's top-left corner:
  the middle of the lens, where a wrecked body smokes, where it sparks
  and shorts out; `Mirrors` (JSON `mirrors`, false by default) - the art
  faces left and is mirrored whole while the monster heads right;
  `Wheels` - a `TWheelsDef` (JSON `wheels`, none by default: `Side` - the
  square of the set's `wheel` picture, `Radius` - from the axle to the
  floor, `Axles` - `THullPoint`s; `Enabled` = it has an axle; wheels
  without a positive side and radius or without an axle, or an axle that
  is not two numbers, raise at load); `HasMuzzle`, `Muzzle` (JSON
  `muzzle`, none by default) - the cut of the barrel a straight
  shot leaves, or the middle of the ports a volley leaves; a muzzle on a
  monster that fires neither raises at load; `Enabled`; a hull without a set, a
  positive width and
  height or with `wearFull` outside (0, 100], or a point that is not two
  numbers, raises at load - and so does a monster with a disc and a hull);
  `TBlastDef` (JSON `blast` - what the monster's death does to the bodies
  around it, see `Game.Blasts`: `Radius` - how far the wave goes, units,
  `Lives` - what it takes at the heart, `ShardLives` (3.0.44) - what a
  shard of the debris takes off a body it falls on, 0 by default,
  `Enabled`; a blast without a positive radius and lives, or with negative
  `shardLives`, raises at load; absent - the monster dies
  quietly. It replaced the `explodesOnDeath` flag in 3.0.41);
  `TDamageCap` (JSON `damageCap` in `stats` - the most lives a monster may
  lose in any run of `Ticks` ticks, see `Monsters.Damage`: `Lives`, `Ticks`,
  `Enabled`; a cap without positive lives and ticks raises at load);
  `TMonsterDef` - the full sheet: id, legacyName, displayName (localized),
  spriteList, category, dangerous, affectedByGravity, blast,
  explosion, material, movement, attack, pickupEffect, lives, score, damageCap, animFreq, deathText
  (localized), deathSounds array, boss, disc, hull, and `Weather` (3.0.58,
  JSON `"weather"`, false by default: a body the sky lets fall - it bursts
  where it lands, the pit takes it without a blast, and its death pays
  the hero nothing, shot down or burst; the sky barrel of the gravel
  trial; weather free of gravity raises, `SWeatherFloats`).
- **`TLaneSide`** = (`lsLeft`, `lsRight`) (3.0.57) - the side of the
  screen a body an event lets in comes from (`Levels.Events`
  `TSpawnOrders`, `TMonster.EnterFrom`).
- **`TMonsterRegistry`** (class) - owns all defs; `LoadFromFile/String`,
  `Find`, `FindByLegacyName`, `TryFind`, `Count`, `AllDefs` (the sound bank
  warms its cache from here), spawn-table and dodge-prize validation.
- **`TPictureDef`** (3.0.64; `Picture`, JSON `"picture": {"width": 42,
  "height": 12}`) - a frame of its own size in place of the cell,
  standing on the feet line and centered on the cell's middle: a pickup
  wider than a cell, the Duplet. `Enabled` - a width above 0;
  `SBadPicture` for a size not above 0, `SPictureAndLayers` beside a disc
  or a hull. 3.0.67: `TurnSeconds` (`turn` - once round clockwise, 0
  stands) and `Hover` (`hover` - units up and down), `SBadPictureMotion`
  below 0: a thing of the void that does not lie as a stone does.
- **`Anchored`** (3.0.67, JSON `anchored`) - nothing moves the body: no
  blow, no blast, no deck under it. **`Invulnerable`** (`invulnerable`) -
  nothing takes a life of it, a shot still bursts on it. Both the moon
  stone's, which only the hero's hand takes.

### `Game/Bullets.pas` (~280 lines)
Projectiles + the one 2008 particle-hack spawner that is left.
- **`TFanShape`** (record) - rows/cols/baseSpeed/speedSpread of the k/t fan
  formula (the travel-test record: one template, four shapes -
  `RageWave` / `FastFragments` / `SlowFragments` in `Monsters`,
  `ExplosionFan` in `Game.Moon`).
- **`TBulletStatus`** = (`bsFlying`, `bsBursting`, `bsInactive`).
- **`TBullet`** - position (`X`, `Y`), velocity (`DX`, `DY`, writable),
  gravity ('dyy'), burst animation frame, `Status` (writable),
  `Contact` (participates in bullet-vs-bullet interception), `Last` (where
  it stood before its last `Move`: what it hits lies on the stretch
  between). `Move`,
  `StartBurst`, `StartBurstSliding` (a wall hit keeps 1/8 inertia).
- **`TBurst`** - owns a bullet list, its sprite set and its cache ('bullet' =
  hero, 'bull' = monsters; flight frame + destruction frames 2..8).
  `NewBullet`, `Clear` (screen transitions wipe bullets), `Update`, `Draw`.
  The spawner, verbatim 2008: `SpawnFan(centerX, centerY, shape)` (boss
  rage wave / boss victory double fan / the explosion bonus). The
  henshin's own are gone since 3.0.49 - the converging rings
  (`SpawnConvergingRing`) and its two fans (`FinishFan`, `ShatterFan`):
  the ceremony is a rite of orbs now (`Orbs.Rite`; the record of what
  went is in PORTING-NOTES, the session of 3.0.49). The 180-fragment fan
  of a dying barrel or
  machine is not here since 3.0.41: an explosion wounds by its wave
  (`Game.Blasts`). The 2008 fire rain and shield aura are not
  here: both are orbs now (`Orbs.Rain`, `Orbs.Aura`; the record of what
  went is in PORTING-NOTES, the session of 3.0.33).
- Known wart: `TBurst.Draw` advances burst animation frames - it mutates
  simulation state from the render path, and that is what blocks render
  interpolation for the game world.
- **`TBulletLook`** (3.0.64) = (`blPlain`, `blRed`) - `NewBullet` takes
  it (plain by default), `Look` reads it back; a red one is the Duplet's
  shot: `DrawBullet` tints the shared texture (`RedShotRed/Green/Blue`
  100/28/22 percent) for its own draw and puts it back.

### `Game/Pads/Pads.Formations.pas` (~450 lines)
The dice, the judge and the assignment of a pad group's rebuild
(`Levels.Pads`): the cells the group's pads stand on next, and which pad
flies to which. Pure functions on cells; the flights are `Pads.Flights`',
the pads `Pads.World`'s. A 2026 addition.
- **Types**: `TPadCell` (`Col`, `Row`, 0-based), `TPadCells`; `TPadSpan`
  (`Left`, `Right`, `Row` - ground the hero stands on, the row of the feet
  line), `TPadSpans`; `TJumpReach` - `reference to function(rise):
  Integer`, the most empty cells a jump crosses sideways to land `rise`
  rows up, -1 when no jump makes it (the game passes `Hero.JumpReach`).
- `Roll(random, count)` - 0..count - 1 off a `TXorShift`
  (`Render.Brush`): the rebuilds never touch `Random`, which feeds the
  boss's spawn table.
- `LaunchSpans(level, group, still)` - where a climb into the zone
  starts: the tops of the grid's walls under the zone (`WallTop`: a wall
  cell with air over it; `WallTopsOfRow`) and `still` - the screen's pads
  outside the group - under it too.
- `TryThrowFormation(random, group, count, out cells)` - the group's
  pairs first (two cells side by side), then single cells, all in the
  zone; False when `ThrowTriesPerCell` (100) tries a cell gave no room.
- `JudgeFormation(cells, group, launch, reach)` - a formation plays when
  no pad stands right over another (`NoneStacked`: the hero on the lower
  one would stand in the upper one's body), no run of three stands side
  by side and the pairs are the group's at least (`PairsOf`), every third
  of the zone across and down holds a pad (`Spread`, `ThirdOf`) and the
  hero reaches every pad jump by jump from the launch spans
  (`AllReachable`: the reach table read once into `TReachTable`,
  `Jumps(from, to, reach)` by the rise between the rows and the gap across,
  `GapAcross`).
- `TryAssignFormation(random, start, cells, group, out target)` -
  `target[i]` is the cell the pad on `start[i]` flies to. Up to
  `AssignTries` (512) shuffles are tried, the first `AssignKept` (64) that
  hold are compared (`AssignmentHolds`: every pad moves, at least
  `FarShare` of them fly `FarFlight` cells or more, no two pads that stood
  side by side do so again - `PairedAgain`), and the one whose shortest
  flights are the longest wins (`SortedFlights`, `ShortestLonger`).
  `FlightCells(from, to)` - the cells of an L: across plus down.

### `Game/Pads/Pads.Flights.pas` (~515 lines)
The flights of a rebuild: every pad from its cell to the cell the
assignment gave it, and when it sets off. Pure functions; `Pads.World`
flies the pads along them. A 2026 addition.
- **`TPadFlight`** (record; ticks count from the start of the rebuild,
  places are the pad's top-left corner) - an L: `From*`, `Corner*`, `To*`,
  the two legs' distances and ticks, `CornerTicks` (the pause on the
  corner, the pace's `CornerPauseTicks`; 0 for a single leg), `Depart`,
  `Deep` (flown in the depth behind the others), `Pace` (3.0.39: the
  `TFlightPace` it is flown at). `Arrive` - on the cell; `Done` - for a
  deep pad the pace's `SinkTicks` later, out of the depth. `Idle` (3.0.39)
  - the pad stays on its cell, in front: nothing to fly.
  `Place(tick, out x, y)`;
  `TurnsCorner(tick)` - the tick the pad comes onto its corner;
  `Behind(tick)` - in the depth, neither a floor nor a body: a deep pad
  from tick 0 to `Done`; `Depth(time)` - 0 in front .. 1 in the depth:
  sinking over the first `SinkTicks` of the pace, rising over the last.
- **`TFlightPace`** (3.0.39; record) - how briskly a plan is flown:
  `TopSpeed` (units a tick), `Acceleration` (units a tick a tick),
  `CornerPauseTicks`, `SinkTicks`, `MaxHoldTicks`, `HoldStepTicks`. The
  constants `BriskPace` (14, 2, 3, 6, 33, 3: a rebuild in a fight, about
  a second and a half on screen 17) and `CalmPace` (4, 0.25, 10, 14, 198,
  6: the way home after it, five to eight seconds, a wait of up to six).
- A leg speeds up at the pace's `Acceleration` to its `TopSpeed` at most
  and brakes at the same rate (`RampTime`, `LegTime`, `LegTicks` - its
  time rounded up to whole ticks, `LegCovered` - the distance covered a
  tick into it; each takes the pace).
- **`TFlightBar`** (3.0.38) - `reference to function(tick, x, y, deep):
  Boolean`: a place barred to a pad's body, its top-left corner at x, y,
  at a tick; `ADeep` - the pad is in the depth, what stands in front
  alone is not in its way. **`TFlightBrief`** (record; replaces the loose
  arrays of 3.0.37) - `Start`, `Target` (`TPadCells`, pad by pad),
  `Loaded` (a rider stands on the pad), `Release` (ticks before which the
  pad stays home), `Pace` (3.0.39), `Bar` (nil: the pads alone are in one
  another's way).
- `TryPlanFlights(random, brief, out flights)` (`TPadFlights`, a flight
  per pad) -
  the pads are planned one by one (`PlanOrder`, `PlansBefore`: the loaded
  first, then - 3.0.39 - the pads that stay on their cells, the rest fly
  round them, then the longest flights, then the file order), each
  against the space the planned ones hold tick by tick (`Clash`: two
  bodies a cell big cut into one another, touching - `TouchSlack` - is no
  cut; `HoldsSpace`: a deep pad holds its cell only from `Arrive`) and
  against the bar (`Barred`: the bar asked at every tick from `Depart` to
  `Done`; `Fits` - no clash and not barred). `TryLegs`: the legs in the
  order rolled, else the other way round - in front and, since 3.0.38, in
  the depth too. In front (`TryFront`): the start held back from
  `release[i]` in steps of the pace's `HoldStepTicks` up to its
  `MaxHoldTicks`; a loaded pad may hold `LoadedHoldScale` (3) times
  longer. Else deep (`TryDeep`): sunk at the very start, off no sooner
  than `SinkTicks`. A loaded pad - the hero stands on it - never goes
  deep; False when a pad fits nowhere, and the caller throws the
  formation again or asks again.
- **`StraightFlight(fromX, fromY, toX, toY, ticks, pace)`** (3.0.62) - the
  flight a scene flies a single pad on: one leg, straight from one place
  to another, setting off at once and in front, sped up and braked as the
  pace does, its time stretched over the ticks given (`LegCovered` takes
  the leg's own time over them). No corner, never deep; the places must
  differ and the ticks be above zero (`TPad.FlyTo` sees to both).
- **`EasedFlight(fromX, fromY, toX, toY, ticks, ease)`** (3.0.67) - the
  same straight flight going the way a `TMotionEase` shapes it, over the
  ticks: the first leg is `Eased` and goes the share `EasedShare` gives,
  not the pace's. The scene's fly with an ease (the moon stone's step).

### `Game/Pads/Pads.Plunge.pas` (~305 lines)
The cycle of a pad that plunges under the hero (`Levels.Pads`, `plunge`;
3.0.46): it holds until he stands on it, gives for the delay, falls out
of the screen, lies below for the rest and climbs home, to hold again.
Once it gives, stepping off does not save it. The pad is failing and
shows it all the way round: it twitches, and its jets work unevenly - in
fits while it holds, flat out and choking while it gives, dead in the
fall, by lunges on the climb, which goes as unevenly as they do. A plunge
told to stay down (`StaysDown`, 3.0.58) lies below for good once it has
fallen: the rest never runs out. The
cycle only counts: how far below its place the pad is, how far a twitch
dips and leans its picture, how hard its jets work. `Pads.World` moves
the pad and draws it; the game passes the effort on to what hangs on the
pad. No SDL and no level in it - a record a test drives alone. The dice
are the cycle's own (`TXorShift`), seeded by the pad: two plunging pads
twitch out of step, and every try at a level twitches alike. A 2026
addition.
- **`TPlungePhase`** = (`ppHolding` - on its place, the hero not on it
  yet; `ppGiving` - he has stood on it, the delay runs; `ppFalling`;
  `ppFallen` - at rest under the screen; `ppClimbing` - on the way home).
- **`TTwitchSpring`** (record) - `Value`, `Speed`: a value on a damped
  spring; `Kick(speed)` sets it swinging about zero, `Tick` steps it - the
  spring of a pad's sag under a landing, so the two read as one machine
  (`SpringStiffness` 0.18, `SpringDamping` 0.3, at rest closer than
  `SpringRest` 0.05). **`TTickSpan`** (record) - `Least`, `Most`: ticks
  from one throw of the dice to the next, either end included.
- **`TPlungeCycle`** (record; its state is private, the face below is all
  a caller has) -
  - `Rewind(plunge, reach, seed)` - on its place, holding: the delay and
    the rest in ticks (seconds * 33, `LogicTicksPerSecond`, local), the
    rise in units a tick at an even gait, `reach` - how far below its
    place the pad falls, the dice `seed or 1`. A pad that does not plunge
    (`Plunges` False) never leaves this state: its `Tick` and `Tread` do
    nothing, its `Effort`, `Dip`, `Lean` and `Below` stay zero.
  - `Tread` - the hero stands on the pad this tick: holding, it starts to
    give; in any other phase nothing.
  - `Tick` - a tick of the phase, the power first (the climb of this tick
    goes by it): giving, the fall starts once the delay is out; falling
    (`Fall`), the speed gains `FallGravity` (0.5 units a tick) every tick
    up to `FallTopSpeed` (12) until the pad is `reach` below its place;
    fallen, the climb starts once the rest is out; climbing (`Climb`), the
    pad comes up by the rise times a gait from `ClimbGaitLeast` (0.3) to
    `ClimbGaitMost` (1.7) by the jets' power - from a crawl to a lunge,
    the pad's own pace on average - and holds again at zero. `Enter`
    starts a phase: its ticks from zero, and both dice thrown anew on the
    next tick - the pad lurches the moment the hero is on it.
  - The twitch (`TickTwitch`), for the picture alone: `Dip` - units down,
    `Lean` - degrees. The springs swing on in every phase; the kicks stop
    with the jets, in the fall and under the screen. A kick comes every
    `CalmTwitchSpan` (6..30 ticks), giving every `GivingTwitchSpan`
    (2..5) and `GivingTwitchGain` (1.3) times harder: the dip always down
    - the pad sinks a little and catches itself - by up to `DipKick`
    (1.8 units a tick), the lean either way by up to `LeanKick` (2.2
    degrees a tick), neither softer than `KickFloor` (0.5) of that
    (`RollKick`). On the bench: some two units and three degrees at the
    widest while it holds, six and eight while it gives.
  - The jets (`TickPower`, `Effort`): a power 0..1 is thrown every
    `CalmPowerSpan` (3..9 ticks; giving `GivingPowerSpan`, 2..4) - held
    long enough for what hangs on the pad to follow (`EffortEaseTicks` of
    `Levels.Dynamics`). `Effort`, 0..1: holding - `IdleEffortMost` (0.6)
    times the power squared, low with a flare now and then; giving - 1,
    and 0 for the throws under `GivingChoke` (0.3), flat out and cutting
    out; falling and fallen - 0; climbing - from `ClimbEffortLeast` (0.4)
    to 1 by the power.
  - `Phase`; `Below` - units below its place.

### `Game/Pads/Pads.Shelf.pas` (~325 lines)
The cycle of a shelf (`Levels.Pads`, `shelf`; 3.0.51): a pad that slides
out of the wall behind it and back in by its program. A step holds it out
or in for its seconds; between two steps it slides. The program goes
round: after its last step the shelf slides to its first. The cycle keeps
the program laid out in ticks and nothing else: where the shelf is at a
tick of its pad's clock it works out anew every time, so a pad that stood
still off the hero's screen, or was rewound, needs no telling. Out all
the way, the shelf holds: it is a floor and a body; from the tick it
starts in until it is out again it is neither. Before it starts in it
warns. Since 3.0.54 an event may tell it a run of its own (`Command`):
the run starts at the tick it is told, plays its lead once - the warning,
the slide from wherever the shelf stood - and then goes round a program
from its first step, or rests out in front or in the wall for good;
before its tick the shelf stands as it stood the tick before, so a shelf
told late keeps to its old run until then. No SDL and no level in it - a
record a test drives alone. `Pads.World` asks it and draws the slide. A
2026 addition.
- **`TShelfPhase`** = (`spOut`, `spGoingIn`, `spIn`, `spGoingOut`).
  **`TShelfSpan`** (record) - `Phase`, `Ticks`, `From` (3.0.54: the depth
  a slide starts at, 0 out .. 1 in): a held step or a slide.
- **`TShelfCall`** = (`scSleep` - into the wall for good, `scWake` - out
  and the program); **`TShelfCommand`** (record) - `Call`, `Run` (a
  `TShelfProgram` of `Levels.Pads`, for a wake), `SpareHero` (a sleep:
  the world holds it while the hero stands on the shelf). **`TShelfLook`**
  (record) - `Phase`, `Depth`, `Warns`: where a shelf stands at a moment.
- **`TShelfCycle`** (record; its state is private) -
  - `Build(shelf)` - the program in ticks (seconds * 33,
    `LogicTicksPerSecond`, local; `Round`, so a half tick goes to the even
    one): round the steps, a span held (`HeldPhases`: `spOut` / `spIn`)
    and the slide to the next step (`SlidePhases`: `spGoingOut` /
    `spGoingIn`, by where the next one stands), the last step's slide back
    to the first; a step or a slide too short for a tick takes one all the
    same - a span of no ticks would be a jump. The warning and the offset
    in ticks. A pad that is no shelf gets no spans: `Slides` False, and
    every answer below is the front's. A shelf `Held` by the file rests
    at its `HeldStand` from the start and runs no steps.
  - `Command(tick, command)` (3.0.54) - a run from that tick on: the look
    of the tick before is kept for the time before it (`FBefore`, through
    `LookAt`), the lead (`AddLead`) is a warning if the shelf is out and
    goes in, then the slide from its present depth; a wake then goes
    round its program (`BuildProgram`: hold - rest out; wave and
    alternate - out and in by the program's seconds; blink - the same,
    short; the waits of an order and of the program are the world's) and
    a sleep rests in (`RestTicks` = `MaxInt`). The run's own warning,
    when the program gives one, replaces the shelf's.
  - `PhaseAt(tick)`; `Holds(tick)` - out all the way (`spOut`), a floor
    and a body; `Warns(tick)` - out, and the end of the stand closer than
    the warning (after a span out comes the slide in, whatever the
    program): the pad's `Effort` is 1 then; `Latches(tick)` - out at this
    tick and not at the one before: the shelf has come out all the way and
    its latch catches. `Depth(time)` - 0 out .. 1 all the way in, at an
    even pace through a slide, `time` between ticks (the world eases it).
  - `SpanAt(time, into)` (private) - the span at a time and how far into
    it: the offset added, the lap folded by `Floor` (a time before the
    start, which a draw right after a restart asks, is the end of the
    lap), a time a hair before the lap's end that rounds up to the end
    itself held at the last span.

### `Game/Pads/Pads.Stray.pas` (~560 lines)
The cycle of a pad that strays (`Levels.Pads`, `stray`; 3.0.58, the act 5
chaos of the gravel arena): transport nobody can count on. Asleep out of
sight until its flock is let go (the event action `strays`); then it waits
its wait, flies in from beyond the left, the right or the top edge (a cell
beyond, `OutsideMargin`, its rigs out of sight too) along the row or down
the column of a point of its zone, hangs there 1-2.5 s (`HangSpan`), and
then falls (odds `FallOdds` 0.15), flies out beyond an edge (`OutOdds`
0.35, never with the hero aboard) or flies on to another point straight
across the zone. Legs are eased (`Smoothstep`), 96 units a second on
average (`StrayPace`). A leg on or out turns back at 35-65 % of its way
(`TurnOdds` 0.2); any leg but a leg back stalls at 25-75 % of its way for
8-14 ticks, twitching, its jets cut (`StallOdds` 0.2); a hang is twitchy
(`TwitchyOdds` 0.3), its jets in fits. The fall is a `TPlungeCycle` with
half a second of shaking and no rest: it falls three cells under the
screen (`FallDepth`) and the pad waits 1-4 s out of sight
(`ReturnSpan`) to come in again; so does a pad flown out. With the hero
aboard, a leg out turns back on the spot. A pad sent away (3.0.59, the
action `straysLeave`, `Dismiss`) flies out along its row beyond the
nearer side at half the pace (`QuietShare`), its jets at half
(`QuietEffort`), and stays asleep out of sight; it no longer turns back,
stalls, twitches or falls; a leg or a fall under way runs out first;
with the hero aboard it hangs until he is off it. The room is the screen
less a cell at the left, the right and the top (`RoomInset`): only inside
it is the pad a deck - out past the walls nobody rides it, and a rider it
takes there falls. The cycle only counts; `Pads.World` moves the pad and
draws it. No SDL and no level in it - a record a test drives alone
(`Tests.Pads.Stray`). A 2026 addition.
- **`TStrayPhase`** = (`spAsleep`, `spWaiting`, `spFlying`, `spHanging`,
  `spGiving` - shaking before a fall, `spFalling`). **`TStrayLeg`** =
  (`slIn`, `slOn`, `slOut`, `slBack` - back to where the leg it turned
  from began).
- **`TStrayCycle`** (record; its state is private) -
  - `Rewind(stray, width, waitLeft, waitTop)` - asleep at that place,
    out of sight; a pad that does not stray never leaves this state.
  - `Launch(seed)` - its flock is let go: it waits its wait, then flies
    in; its dice (`TXorShift`) seeded by the caller. Nothing for a pad
    let go already, or sent away.
  - `Dismiss` - sent away; nothing for a pad asleep, which stays asleep.
  - `Tick(loaded)` - `loaded`: the hero stands on it this tick.
  - `Deck` - in the air inside the room: a floor and a body. `Effort` -
    the jets, 0..1. `Dip`, `Lean` - the twitch, for the picture alone
    (two `TTwitchSpring`s of `Pads.Plunge`, kicked every 2-6 ticks by up
    to `DipKick` 2.2 units and `LeanKick` 3 degrees). `Phase`, `Leg`,
    `Dismissed`, `Left`, `Top` (the top-left corner of the deck; the fall
    adds its depth).

### `Game/Pads/Pads.World.pas` (~2070 lines)
The level's pads (`Levels.Pads`) in play: where each one stands, what its
deck carries, what its body stops, and its picture. The world keeps no
riders: the hero and the monsters ask it for the deck under their feet,
for the deck that stood under them a tick ago and carries them along, and
for the deck their feet came down onto in a tick; the 2008 grid goes on
answering everything else. On a screen without pads every answer is nil or
False, so the old rules stand alone there. A pad travels its path eased
in and out of every stop, and only the pads of the hero's screen go on: a
screen left behind holds still with whatever lies on its pads, as its
monsters do. The bob and the sag under a landing are the pad's `Lift` -
drawn, not felt: a pad standing still keeps its deck on the line the level
file puts it on, where the 2008 wall probes, which count rows from the
feet, read the right row. A path that climbs takes its riders between the
rows: keep it clear of the grid's walls. The `Lift` is drawn in
fractions of a unit and between ticks - a sway of a unit and a half in
whole units would jerk from one to the next. A blow - the boss's ram -
knocks a pad off its place: a cell along the blow, or as far as the walls,
the other pads and the caller's fence (the boss's lap) let it; out in a few
ticks, rocking, held while the boss lies stunned, home by the time he flies
again. The riders go with it as with a path; a pad on a path only rocks,
and so does every pad of a screen whose group is being rebuilt. A rebuild
(3.0.29) flies the pads of a group to a new formation (`Pads.Formations`,
`Pads.Flights`): asked for, it starts on the group's screen once no pad
of the group is knocked. A pad flown in the depth is neither a floor nor
a body until it comes out on its cell - what stands on it falls. A flying
pad stills its bob and takes it up again on its cell, in step with the
ripple there. A pad of the group the level file puts outside the zone
flies in with the first rebuild (3.0.38); out there a flight minds more
than the pads: the walls, the ground it would skim and what the caller
says flies there (`TPadTraffic`). A restore (3.0.39) is a rebuild flown
the other way: every pad of the group back to its place in the level
file, calmly (`CalmPace`), thrown and judged by nobody. A pad that
plunges (3.0.46; `Pads.Plunge` counts its cycle) is told when the hero
stands on it - the one thing a rider tells a pad. It falls under him as a
path would take it: the deck goes, the rider with it, out of the screen
and past the line where the game takes a faller out of the pit; no wall
stops it - the level keeps the shaft under it clear. It climbs back as a
floor and carries up whoever lands on it; its twitch is drawn with the
sag, not felt. A shelf (3.0.51; `Pads.Shelf` counts its cycle) slides
into the wall behind it and out again. It goes nowhere: its deck stays on
its line, and while the shelf is not out all the way it is neither a
floor nor a body, as a pad flown into the depth - what stands on it
falls, bullets fly through. The slide is drawn as that depth is, at the
shelf's own size and light (`TPadDeepLook` of the level file), its
picture sinking. A shelf does not sag and has no jets: its `Effort` is
its warning. What hangs on it is the wall's and stays in front. The
monsters ask for their deck every tick and fall by themselves; the hero,
who asks nothing while he stands, asks `DeckWithdrawn`. The tick its
latch catches the world tells, as a rebuild's sounds, and the game
voices. A pad on a carousel (3.0.52, `Levels.Carousels`) goes round its
track at an even pace from the place its orbit gives it at the start of
its clock: its path is the track, and the riders go with it as with any
path. It travels, so a ram only rocks it.
The gravel arena (3.0.54-3.0.59) added five things. The shelves of a bank
are told together (`TellBank`) - to go into the wall, to come out, to run
another program - in an order, a step apart, so a bank wakes the room as
a wave; the program adds a wait of its own (every other shelf of an
alternation a turn, every shelf of a blink a time the dice give), and a
told shelf keeps to its run until its moment; a few of a bank may be told
(the pick), and a sleep may spare the hero (the shelf waits while he
stands on it). The pads of a parked group wait above the screen over
their places, and a restore flies them in. The pads of a parked carousel
wait above the screen over their slots; a fly-in brings them straight
down, jets flat out, and the carousel turns once the last of them is on
its slot, its clock speeding up from a standstill. A turning carousel may
break: its clock runs down to a standstill, then its pads, one after
another in an order the dice give, become pads that plunge where they
stand, in the picture of their failing look; a carousel not yet in the
room does not break. A pad that strays (`Pads.Stray`) waits out of sight
until its flock is let go, then its cycle places it as a path would, the
riders with it; out of the room it is `Behind`, and it travels, so a ram
only rocks it.
Born with the level (`LoadLevel`); a restart rewinds it, the dice of the
rebuilds new for the new try.
- **`TOrbitPhase`** = (`opTurning`, `opParked`, `opLanding`, `opOnSlot`,
  `opHalting`) (3.0.57-3.0.58) - a pad of a carousel: going round, waiting
  above the screen, coming down to its slot, standing on it until the
  rest are down, its clock running down after a break; `opTurning` for a
  pad on none. **`TPadFailLook`** (record, 3.0.58) - `Breaks`, `Texture`,
  `Plunge`: what a pad of a carousel that may break becomes; built by the
  world from the carousel's `Failing` (its sprite from the object cache).
- **`TPadFence`** - `reference to function(x, y): Boolean`: the point is
  shut to a knocked pad besides the walls (the game passes
  `Monsters.Pilot.LapHolds`).
- **`TPadBlow`** - a body that struck: `Left`, `Top`, `Right`, `Bottom` -
  its corners a step on, where the walls stopped it (a pad holding one is
  struck); `WayX`, `WayY` - the way it went, a unit vector; `Ticks` - how
  long the struck pad stays out. `TPilotCrash.Blow` carries one.
- **`TPadLoad`** - `reference to function(pad): Boolean`: the pad carries
  a rider a rebuild must not take into the depth (the game passes
  `HeroRides`). **`TPadRelease`** - `reference to function(cell): Integer`:
  ticks after the start of a rebuild before which the pad on the cell
  stays home (`Pads.Arena` passes the wave behind the boss; nil - all at
  once). **`TPadTraffic`** (3.0.38) - `reference to function(tick, x,
  y): Boolean`: something of the caller's would cut into a pad's body, its
  top-left corner at x, y, at that tick of a rebuild (the game's arena
  passes `LapBars`; nil - the walls alone). **`TRebuildAsk`** (record, the
  field `FAsked`) - the asked rebuild as one: `Group` ('' - none), `Load`,
  `Release`, `Traffic` and `Restore` (back to the file's places).
  **`TPadLayer`** = (`plDeep`, `plFront`) - the pads gone into the
  depth, at whatever depth, and the rest: the layer `Draw` takes.
  `DeepScale` (0.85) and `DeepTone` (0.6) - a pad all the way into the
  depth, its size and its light; open, for the game passes them on to what
  hangs on the pad. `FlownDeep` (implementation) - the same as a
  `TPadDeepLook` with no sink: what every pad but a shelf draws its depth
  by (`FDeep`); a shelf draws by its placement's `Shelf.Deep`.
- **`TPad`** - one pad: `Left`, `Right` (`Left` + width), `Top` (the deck -
  the feet line of whatever stands on the pad), `PrevTop` (the deck a tick
  ago), `Screen`, `Tag`, `Bullets`, `Group`, `Placement`, `HomeLeft` /
  `HomeTop` (where the path or the flight puts the pad, the knock left
  out), `WasBehind` (3.0.51: `Behind` a tick ago - `Tick` catches it
  first, `Rewind` last). `Create(placement, texture, orbit)` - the orbit
  (3.0.52, `FOrbit`) is the pad's way round its carousel, one that does
  not ride for a pad on none; the world makes it with `OrbitOf`.
  - The path: `BuildCycle` (in the constructor) makes it one cycle of
    stops - the first is the level file's place, the path's stops follow;
    pingpong comes back through the inner stops (each passed twice, the
    two ends once), loop goes from the last stop back to the first. A
    leg's ticks are its distance over `Speed` at 33 ticks a second
    (`LogicTicksPerSecond`, local - the `tickRate` of `Game.Config`; one
    tick at least), the pause at every stop `Pause` * 33 ticks.
    `Tick(onView)` keeps the place a tick ago (`FPrevLeft`, `FPrevTop`)
    first and, on the hero's screen only, advances `FClock` (the ticks the
    pad has lived on the hero's screen), places the pad on the cycle
    (`PlaceOnPath`: a leg, then the pause at the stop it ends at; the leg
    eased by `Smoothstep` - the pad sets off and comes to a stop gently),
    flies its flight when in one (`TickFlight`), fades the bob
    (`TickBob`) and steps the sag (`TickSag`) and the knock (`TickKnock`);
    the path's or the flight's place (`FPathLeft`, `FPathTop`) plus the
    knock's offset - and, down, how far its plunge has the pad below
    (`FPlunge.Tick` after the knock, `Below`) - is the pad's place.
    `Rewind` - the clock to 0, the pad
    on the level file's place, no sag, no knock, no flight, its plunge
    holding; the
    constructor ends with it. A pad of a carousel (3.0.52): `PlaceOnPath`
    hands over to `PlaceOnOrbit` - the orbit's place at `FClock` is the
    middle of the deck, the pad's left edge half its width off; `Rewind`
    puts it there too, on the start itself, not on the placement, which
    holds it rounded to whole units (the riders seated on the pad sit on
    the start itself).
    `MotionX` - how far the pad went across this tick.
  - The deck and the body: `DeckSpans(left, right)` - the deck spans some
    of left..right, edges included (closed) and `EdgeSlop` (0.001) past
    them: a rider carried a unit at a time on a fast pad ends a hair off
    the very edge by rounding and must not drop;
    `DeckSpannedBefore(left, right)` - the same for the deck as it stood a
    tick ago;
    `BodyHolds(x, y)` - the point lies in the body, the deck's width across
    and `FBodyDepth` down from the deck, half-open (`Left` <= x <
    `Right`, `Top` <= y < `Top` + `FBodyDepth`). `Body` - the same body as
    a box, in screen units. `FBodyDepth` (3.0.51, the constructor) - the
    picture's height, no shallower than `ThinnestBody` (half a cell: the
    fastest bullet flies 12 units a tick and strikes with a point, a
    shallower body would be flown through between two ticks) and no deeper
    than `TileSize`. The pads of the game before the shelf are square
    pictures - a cell, as before; the shelf (32 by 11 units) - 16. A pad
    with no picture (a collision deck, 3.0.60) takes `TileSize` as its
    picture height: its body is the cell the wall stood in.
  - `Lift(alpha)` - units down from the deck the pad is drawn at, a
    fraction (never rounded): the bob (`Bob` times a sine, one sway in
    `BobPeriodTicks` = 3 s, taken at `FClock` - 1 + alpha - between the
    ticks - the phase shifted by `FBobX` across the screen: the
    placement's X, after a flight the cell the pad landed on - a row of
    pads ripples -, the sway scaled by `FBobShare`, which a flight fades
    to 0 over `BobFadeTicks` (10) and the cell brings back) plus the sag
    of this tick and the twitch of a pad that plunges (`FSag`,
    `FPlunge.Dip`, on the tick:
    the lamps hung on the pad read it there). `Lift(1)` - the pad as this
    tick leaves it.
    `Press(speed)` - something landed on the deck
    at speed units a tick: the sag's speed takes speed * `SagGain` (0.6),
    no more than `SagMaxKick` (2.7 - about three units down at the
    deepest; a shelf does not give - it is bolted to its rails, `Press`
    does nothing; nor does a pad with no picture, a grid deck, since
    3.0.62 - the level's art under it stands still and the riders would
    sink into it), and a damped spring (`SagStiffness` 0.18, `SagDamping` 0.3)
    brings it back, at rest closer than `SagRest` (0.05). The physics deck
    stays on the path: the feet never feel the `Lift`.
  - The knock (3.0.28): `Knock(dx, dy, ticks)` - the pad goes dx, dy from
    where it stands and is back on its path `ticks` later (no fewer than
    out and home take). `KnockOffset` - off the path by `FKnockFrom*` at
    the blow (a pad struck again before it is home) easing to `FKnockTo*`
    over `KnockOutTicks` (6), held, eased home over the last
    `KnockBackTicks` (12); `NoKnock` (-1) on the clock - none. `Tilt(alpha)`
    - the rock, drawn only: `KnockTilt` (7 degrees) times a sine of one rock
    in `KnockTiltPeriodTicks` (8), dying by `KnockTiltDecayTicks` (12),
    between ticks. `Travels` - the pad has a path, or rides a carousel
    (3.0.52). `ClearOf(other, dx, dy)` -
    the body moved dx, dy would not cut into the other's; touching is no
    cut. `Knocked` - off its place by a blow.
  - The plunge (3.0.46): `FPlunge` - the pad's `TPlungeCycle`
    (`Pads.Plunge`), idle for a pad whose placement does not plunge.
    `Rewind` rewinds it with the placement's `Plunge`, the reach -
    `ScreenHeight` + `PlungeDepth` less the placement's Y: the pad comes
    to rest `PlungeDepth` (3 cells) under the screen, past the line where
    the game takes a faller out of the pit (`PitDepthY` of `Game.Moon`, 66
    units under it), so a hero riding it down is in the pit before it
    stops - and the seed `PlungeSeed` (the placement's X, screen and Y).
    `Tread` - the hero stands on the deck this tick
    (`THero.LandOnDeck`); the pad starts to give way. `Effort` - how hard
    the pad works its jets, 0..1: 1 while `Thrusting`, else what the
    cycle says - 0 for a pad that does not plunge; the game hands it to
    what hangs on the pad. The riders go down and up with the deck as
    with a path; a ram would knock the pad as it knocks any pad without
    a path.
  - The shelf (3.0.51): `FShelf` - the pad's `TShelfCycle`
    (`Pads.Shelf`), built in the constructor from the placement's `Shelf`
    and asked at `FClock`; a pad that is no shelf gets one that never
    leaves the front. `Behind` - flown into the depth, or a shelf that
    does not hold (`not FShelf.Holds`). `Effort` - 1 while `Thrusting` or
    while the shelf warns. `Depth(alpha)` - the deeper of the flight's
    and the slide's (`FShelf.Depth` at `FClock` - 1 + alpha, eased by
    `Smoothstep`); `RigDepth(alpha)` - the flight's alone, for what hangs
    on the pad: a flight takes it along, a shelf slides in without it.
    One tick only: `Latched` - `FShelf.Latches` at the tick the clock has
    just reached (only on the hero's screen: the clock goes nowhere
    elsewhere).
  - The arena's pieces (3.0.54-3.0.59): `Tick(onView, heroAboard)` - the
    hero stands on its deck this tick (a sleep that spares him waits; a
    stray with him aboard never leaves the room). `TellShelf(command,
    delay)` - a shelf takes up the command that many ticks after the next
    tick of its clock (`FShelfCommand`, `FShelfCommandAt`); a command told
    before replaces one that has not come yet. `MeantOut` - a shelf meant
    to stand out: told to come out, or never told and held out by the
    file or running its file program (where a medkit may come down).
    `Park(top)` - waits with its deck at that height over its place, for
    a parked group. The carousel: `Land` (a parked pad sets off down its
    `TCarouselLanding`, `FLandingClock`), `StartTurning` (on its slot it
    starts round, `FOrbitClock` from zero, eased by `TCarouselOrbit.Clock`),
    `BreakDown(haltTicks, failTicks)` (the clock runs down over the halt -
    `Halting`, `FHaltFrom`, `FHaltClock` -, and `failTicks` after the next
    tick the pad `Fail`s: its plunge cycle rewound with the failing plunge,
    the reach as far under the screen as a placed pad's goes from where the
    pad stands now, the picture switched to the failing texture; nothing
    for a pad on no carousel or of one not yet in the room); `OrbitPhase`,
    `Failed`, `CanFail`; `RewindOrbit` parks the pads of a parked carousel
    again. The stray: `FStray` - its `TStrayCycle`; `Launch(seed)`,
    `Dismiss`; it places the pad, `Behind` while it is not a `Deck`, its
    twitch on the sag, its jets its `Effort`. `Effort` is also 1 while a
    pad comes down to its slot.
  - The flight (3.0.29): `Fly(flight)` - the pad flies a `TPadFlight`,
    its ticks counted from now (`FFlightClock`; `NoFlight` = -1 - none).
    `TickFlight` puts the path's place where the flight has it, moves the
    bob's `FBobX` along and ends the flight a tick past its `Done` - the
    last tick of coming out of the depth is still drawn between the
    ticks. `Flying`; `Thrusting` - the pad works its jets hard: from
    `ThrustLeadTicks` (10) before it leaves its place in a flight until it
    is on its cell - the moment before is the tell of the pad about to go;
    `Settled` - in no flight, or its flight is over;
    `Behind` - in the depth, neither a floor nor a body (a shelf not out
    all the way too); `Depth(alpha)` - 0 in front .. 1 in the depth,
    eased; `FlushWith(other)` - the two
    stand flush side by side where their paths or flights put them. One
    tick only: `TurnedCorner` (a flight in front came onto its corner - in
    the depth a corner is turned out of earshot) and `Landed` (the flight
    ended on its cell).
  - The dormant pad (3.0.62): `Dormant` - asleep as the level file says
    (`TPadPlacement.Dormant`): `Behind` (neither a floor nor a body), not
    drawn, and what hangs on it out (`LocateParent` of the game gives it
    no life); **`Wake`** - there from now on; `Rewind` puts it to sleep
    again. **`FlyTo(x, y, ticks)`** - a scene flies the pad straight from
    where its path or its last flight left it (a knock is not minded) to
    x, y, its top-left corner, over the ticks (`StraightFlight` at
    `CalmPace`; `Thrusting` while it goes, so its jets burn); 0 ticks or no
    distance - there at once, the `Prev*` caught up, and what stood on it
    is left in the air. It stays where it is flown.
  - The picture: `Draw(sprites, alpha)` - nothing for a pad with no
    texture (a collision deck, 3.0.60); else its height from the art's
    aspect, drawn at (`Round(Left)`, `Round(Top)` + `Lift(alpha)`) in
    fractions of a unit (`DrawRectF`), turned by `Tilt(alpha)` plus the
    lean of a plunging pad's twitch (`FPlunge.Lean`), in the
    depth smaller about its middle (`Middle` - from the picture's top-left
    corner, the one point `Draw` and the pad's rig shrink about;
    `FDeep.Scale` - 0.85 for a flight), darker
    (`FDeep.Tone` - 0.6 for a flight) and lower by `FDeep.Sink` (0 for a
    flight; 3.0.51) by `Depth(alpha)` - the riders are drawn with the same
    `Lift` (through the renderer's `FineY`), so the feet do not flicker
    into the deck - with the pad's tint set before every draw
    (`TintTexture`), as a static object is.
- **`TPadWorld`** - `Create(sprites, cache, level, reach, seed)`: `reach`
  is how far the hero jumps (`TJumpReach`, for the judge of a formation),
  `seed` the dice of the rebuilds; the cache is the
  level's object art, the textures are its; it and the level (the
  placements, and the grid a knock is tried against) must outlive the
  world; a picture the cache lacks raises here, at level load
  (`PadTexture`: a pad whose `Sprite` is '' - a collision deck, 3.0.60 -
  asks the cache for nothing and gets no texture); every
  pad gets its orbit here (`OrbitOf` over the level's `Carousels`,
  3.0.52) and its failing look (3.0.58); a parked group is parked
  (`ParkGroups`, after every rewind too). `Tick(screen, heroDeck)` - before
  the riders move (`heroDeck`, 3.0.57: the pad the hero stands on, nil
  while he is dead; every pad is told whether it is that one): a rebuild asked for may start (`StartAskedRebuild`),
  then every pad's `Tick`, on view for the pads of that screen alone - a
  pad elsewhere keeps its `Prev*` caught up and goes nowhere -, then
  `HearFlights` and `HearShelves`, then `TurnLandedCarousels` (3.0.57: a
  carousel every pad of which is on its slot starts to turn).
  `Rewind(seed)` - every pad back to where the level file puts it, no
  rebuild asked for or flying, the dice seeded anew (`seed or 1`: an
  xorshift seeded with zero stays at zero). The deck and body queries
  below - `DeckUnder`, `DeckCarrying`, `DeckCrossed`, `BodyAt`,
  `StopsBulletAt` - and the knock (`PadStruck`, `RoomFor`) pass over a
  pad that is `Behind`; `FindTagged` and `Draw` do not.
  `DeckUnder(screen, left, right, feetY)` - the deck the feet stand on:
  within `DeckSlop` (0.5) of feetY and spanning some of left..right, nil
  when there is none (a fraction left by arithmetic must not drop a
  rider). `DeckCarrying(screen, left, right, feetY)` - the deck the feet
  stood on a tick ago (`PrevTop` within the slop of feetY,
  `DeckSpannedBefore`), which carries them this tick.
  `DeckWithdrawn(screen, left, right, feetY)` (3.0.51) - a deck the feet
  stood on a tick ago has gone from under them this tick, and not by
  moving: a pad of the screen `Behind` now and not a tick ago
  (`WasBehind`), its `PrevTop` within the slop of feetY and spanning them
  before - a shelf that has started into its wall. `DeckCrossed(screen,
  left, right, prevY, feetY, ignored)` - the deck the feet came down onto
  between two ticks: the previous feet not below the deck as it stood
  (prevY <= `PrevTop`) and the feet not above it now (feetY >= `Top`) - a
  deck rising into still feet catches them too; the highest one when they
  passed several; `ignored` (may be nil) is the
  deck the feet are dropping through, and every deck at its height (within
  the slop) is let by - else a drop on the seam of two pads side by side
  would land on the neighbour. `BodyAt(screen, x, y)` - a body at the point
  (what stops the boss, the sparks and the debris); `StopsBulletAt(screen,
  x, y)` - the same for the `pbBlock` pads alone; `Bodies(screen)` - the
  bodies of the screen's pads standing in front, as boxes: the matter of
  the pads, which an aura is drawn out of (a pad in the depth is none);
  `FindWearer(tag, out failingLook)` (3.0.58, in place of `FindTagged`) -
  the pad the rigs tagged so hang on: by its own tag, or by the tag of its
  failing look (`FailingRigTag`), which `failingLook` tells; nil when none; `Draw(screen, alpha, layer)` - the pads of
  that screen in one layer, the frame's alpha passed on to their `Lift`:
  the game draws the pads in the depth first, then what hangs on them,
  then the pads in front, which pass before both.
  `Shove(screen, blow, fence)` - the boss's ram: `PadStruck` - the pad
  holding a corner of the blow (what the pilot's walls found); none - no
  knock. A pad on a path only rocks (`Knock(0, 0, ticks)`), and so does any
  pad
  of a screen whose group is being rebuilt (`FlyingOn`): knocked off its
  cell, it would cut into a pad landing next to it. Else unit by unit
  along the way, `KnockReach` (a cell) at most: the whole step if
  `RoomFor` lets it, else its X alone, else its Y alone (sliding along what
  stops one way), else stop; the pad is knocked as far as it got - with no
  room at all it still rocks. `RoomFor(pad, dx, dy, fence)` - the body
  moved stays on the screen, its rows (`RowShut`, a hair -
  `WallProbeInset` - inside the edges, points a cell apart across) out of
  the grid's walls and the fence, the riders' room (a cell over the deck)
  out of the walls - not the fence: the boss lies stunned while the pad is
  out - and the body `ClearOf` every other pad of the screen.
  The rebuild (3.0.29): `RequestRebuild(group, load, release, traffic)`
  (`traffic` since 3.0.38; the debug key passes nil) - the pads
  of the group fly to a new formation; nothing while one is asked for or
  flying (`Rebuilding`) or for a group without pads (`TakeAsk`, the door
  of the restore too). `StartAskedRebuild`
  starts it on the group's screen once none of its pads is knocked
  (`GroupKnocked` - the same question for a caller: the arena asks it
  before it warns); `StartRebuild` -> `TryPlanRebuild`: `BriefOf` makes
  the `TFlightBrief` - the start cells (`CellOfPlace` of every pad's
  home), who is loaded (`load`), the release ticks (`release`; zeros
  without one) and the bar (`FlightBarOf`: inside the zone, `InsideZone`,
  nothing bars; outside it the ground does every flight - `GroundShut`,
  the body in a wall or flush on one - and the caller's `traffic` the
  flights in front, a pad in the depth passes behind it) -, then up to
  `MaxThrows` (500) formations thrown, judged, assigned and planned at
  `BriskPace` (`TryThrowFormation`, `JudgeFormation` against `LaunchSpans` with the
  screen's other pads as `StillSpans`, `TryAssignFormation`,
  `TryPlanFlights`); past the last throw the level file's own formation
  (`FileCellsOf`), not judged - only when the file keeps the whole group
  in the zone (`CellsInZone`; not so on screen 17); no plan at all - no
  rebuild this time. `StartRebuild` flies no `Idle` flight: a pad that
  stays on its cell bobs on. The restore (3.0.39):
  `RequestRestore(group, load, release, pace)` - the same ask with
  `Restore` set, at a pace of the caller's (3.0.54: `CalmPace` for a
  restore, `BriskPace` for a fly-in, `TRebuildAsk.Pace`); `TryPlanRestore` plans every pad to its own place of the level
  file at `CalmPace` - no dice, no judge - and flies nothing when a
  pad finds no way: the caller asks again.
  `GroupRestored(group)` - every pad stands on its file place and none
  flies. `MembersOf(tag)` - the group's pads in file order;
  `GroupFlying`. `HearFlights` gathers what the tick sounded like, for
  the game to voice, one tick only: `CornerTurned` - a pad in front
  turned the corner of its flight; `PairDocked` - a pad landed flush
  beside one that is `Settled` (`DocksBeside`). `HearShelves` (3.0.51)
  the same for `ShelfLatched` - a shelf latched this tick; only the pads
  of the hero's screen tick their clocks, so it is always one of his.
  `Rewind` clears it.
  The banks (3.0.54): `TellBank(bank, command, telling, heroX)` - the
  shelves of the bank (`BankOf`, `TPadShelf.InBank`) in the order of the
  telling (`OrderedBank`; `boToHero` from the farthest from `heroX`),
  `Picked` down to the pick (3.0.58: each in its order with the odds of
  the places left, so every set is as likely as another), each told
  `step * i` ticks on plus `ProgramWait` (alternate: every odd one a turn
  out and a slide; blink: a dice wait within one round). `TryPickBankMiddle
  (bank, out x)` / `(bank, side, out x)` (3.0.54 / 3.0.59) - the middle
  across of a shelf of the bank as the dice pick it, among those
  `MeantOut` when any is (all of them else), and from the half of the
  screen `side` names (below 0 the left, above 0 the right) when that
  half has one; False for a bank with no shelf.
  The carousels (3.0.57-3.0.58): `TryFlyInCarousel(tag)` - the parked
  carousel's pads `Land`; False when no carousel carries the tag, True and
  nothing more for one not parked or flown in already.
  `CarouselLanding` - a carousel flown in does not turn yet (the game's
  `RoomBusy`). `TryBreakCarousel(tag, halt, step)` - every pad of a
  turning carousel `BreakDown`s at once (a pad over another keeps the gap
  of their slots as the clock runs down), each failing at the halt and
  then one every step, in a `Shuffled` order; False for a tag of no
  carousel that may break. `RidersOf(tag)`.
  The strays (3.0.58-3.0.59): `TryLaunchFlock(flock)` - every pad of the
  flock `Launch`es, each with its own seed off the world's dice, new for
  every try; `TryDismissFlock(flock)` - every one `Dismiss`es; both False
  for a flock no pad strays in.
- `TPad.FlyEased(x, y, ticks, ease)` (3.0.67) - `Fly` over an
  `EasedFlight`: a scene's fly with an ease.

### `Game/Pads/Pads.Arena.pas` (~370 lines)
The director of a boss fight over a pad group that is rebuilt: when the
pads fly, and in step with whom; since 3.0.39 also the calm flight home
after it. A 2026 addition (3.0.29).
- **`TPadArena`** - `Create(pads, dynamics, groups, load)`: the pad world
  and the level's dynamic objects must outlive it; `load` is the
  `TPadLoad` of the rebuilds. `Engage(group)` - the events' `rebuild`
  action: the group is rebuilt from now on (nothing for a group without a
  conductor, or while one is engaged). `Tick(screen, field)` - once a
  logic tick after the monsters have moved, the field arriving with it as
  it is reborn on a restart; `Reset` - a restart: asleep until the event
  engages it again, the alarm as the level file has it. `Warned` - one
  tick only: the warning of a rebuild has begun (the game hums).
  `Restore(group)` (3.0.39) - the events' `restore` action: the group is
  rebuilt no more (`FallAsleep`: the lamps out), whether it was engaged
  or not, and its pads fly home (`arRestoring`). `FlyIn(group)` (3.0.54) -
  the events' `flyIn` for a parked group: the same restore at
  `BriskPace`, rippling from the middle of the zone (`StartRestore` takes
  the pace; `Restore` passes `CalmPace`).
- **`TArenaPhase`** = (`arAsleep`, `arResting`, `arHolding`, `arWarning`,
  `arFlying`, `arRestoring`). `arResting` counts the group's `Every`
  seconds (the first rebuild comes at once), then holds the conductor's lap
  (`TMonster.HoldLap`). `arHolding` waits until the conductor flies the
  lap (`FliesLap`), no other rebuild - the debug key's - is in the air
  and no pad of the group is knocked, then fades the group's `Alarm`
  lamps in (`FadeTagged`, `AlarmFadeInTicks` 2). `arWarning` lasts
  `WarningTicks` (33, a second - five flashes of the lamps, and the hum of
  tools/sounds/pads.py is made for it: 1.2 s, its tail dying under the
  first flights; a rebuild of another's started
  meanwhile -
  back to holding), then foresees the lap (`LapAhead`, `LapAheadTicks` =
  15 s - a whole lap even at three units a tick), asks for the rebuild
  with `ReleaseOf` as the release and `LapBars` as the traffic and fades
  the lamps out. `arFlying`
  waits for the last pad, lets the lap go and rests again. The conductor
  dead - `FallAsleep`: no rebuild more, a flying one lands as planned.
  `arRestoring` (3.0.39; `TickRestoring`, run before the conductor is
  looked for): `LetLapGo` (a conductor alive has its lap back), then it
  waits for a flying rebuild and for knocked pads, goes to sleep once
  `GroupRestored`, else asks `RequestRestore` with `RippleOf` as the
  release, and again every `RestoreRetryTicks` (15) - a loaded pad may
  find no way at first.
- `RippleCell` / `RippleOf(cell)` (3.0.39) - the wave of a restore: it
  spreads from the cell under the middle of the conductor's body, dead or
  alive (`TMonsterField.FirstTagged`; the middle of the zone without
  one), a pad setting off `RippleTicksPerCell` (4) ticks per cell of
  distance later.
- `LapBars(tick, x, y)` (3.0.38) - the traffic of a rebuild: the
  conductor's body on the foreseen lap (`TLapStep.Feet`), within
  `LapSlackTicks` (20) ticks either way of the tick, too near the pad's
  body (`LapClearance` = 16 units); the pads move before the
  monsters, so a tick of the rebuild is the step of the lap before it.
- `ReleaseOf(cell)` - the first tick the foreseen lap flies past the
  cell: over its column on a level side of the lap, past its row on an
  upright one; 0 for a cell it never passes. A pad going deep sinks at
  once all the same, as in every rebuild.

### `Game/Hero.pas` (~1585 lines)
The hero: physics, weapons, death. Owns `HeroSize=32`; the screen size it
moves in comes from `Game.Space`.
- **Enums**: `THeroAction` (stand/walk/jump/fall x direction), `THeroCommand`
  (go/stop left/right, jump/stopJump, drop), `THeroForm` (hfNormal/hfIce),
  `TPendingSide` ('ExtraInstruction' of 2008 - a queued side intent executed
  once the barrier clears).
- **`THero`** -
  - Art: `hero.mset` (24 frames as the `walk`, `death` and `henshin` sequences,
    named by `HeroFrameSequences`) plus the weapon set, both owned;
    `OpenFrames` pulls named sequences out of a set; `SkinSet` (public) hands
    the hero's set to whoever builds something out of his frames - the
    shroud's masks and halos.
  - State: FX/FY (Y = the FEET line), screen, action, direction, walk frame,
    acceleration, form, death fields (frame 9->16, corpse settling).
  - Collision oracles (verbatim 2008): `Solid`, `CellOfX/Y`, `CellsOfX/Y` (a
    32-unit span straddling two cells), `CanIGoLeft/Right/Up/Down`,
    `CanIFlyLeft/Right`, `WallBlocksLeft/Right` (side-effect-free probes for
    shoves), `GroundUnderFeet`, `LandExactly`, `SettleOnGround`.
  - Pads (a 2026 addition; the constructor takes the pad world -
    `Create(renderer, level, pads)`): a deck holds the hero from above only,
    and the 2008 oracles go on asking the grid. `DeckUnderFeet` - the deck
    under his middle (`FX + HeroSize / 2`); the floor half of the ledge
    check in `CanIGoLeft/Right` also asks for one, so a walk off the grid
    onto a deck does not fall. `RideDeck` at the head of `Tick`, right
    after `PrevY` is caught (the feet where the last tick left them): the
    deck the feet stood on a tick ago (`DeckCarrying`) takes them where it
    went - across by its `MotionX` a unit at a time (`CarryX`, the wall -
    `WallBlocksLeft/Right` - asked before every one: a knocked deck goes
    several units a tick), up or down to its `Top` unless it rises and
    the head is blocked (`CanIGoUp`): then it rises through him - that
    deck becomes `FDropFrom` and he falls (`haFall`, acceleration 1). A
    deck a wall has pulled from under him (no `DeckUnderFeet` after the
    ride) leaves him to the ground below: a standing hero through
    `SettleOnGround`, the corpse unsettled (`FCorpseSettled` False) to fall
    again. No deck carrying him, but one withdrawn from under him
    (`DeckWithdrawn`, 3.0.51 - a shelf has started into its wall):
    `LoseDeck` - the corpse unsettled; a foot on the grid's floor
    (`GroundUnderFeet`, or no `CanIGoDown`) still holds him; else he falls
    the way he was going, as off a ledge - `haStand` into `haFall`,
    `haWalkLeft/Right` into `haFallLeft/Right`, acceleration 1: a stand
    asks the floor nothing, and a walk only sees the ledge once the cells
    on both sides of him are empty. `LandOnDeck(prevY)` at the end of `Tick`, after the verbatim
    state machine: a deck the feet came down onto this tick, or one that
    rose into them (`DeckCrossed`), holds them at its `Top`, the
    acceleration zeroed, and is told so (`Tread`, 3.0.46 - every tick it
    holds them, a stand and a walk included: a pad that plunges starts to
    give way) - no downward move is needed, but a rising jump
    (`haJump*`) never lands; only the fall states press the deck (`Press`
    with the acceleration - the sag). The fall states land there -
    `haFall` through `StandAfterFall` (the landing of a straight fall, lifted out of the `haFall` branch: a side
    held in the air walks at once), `haFallLeft/Right` into a walk. `hcDrop`
    -> `DropThroughDeck`: from a stand or a walk on a deck, into the
    matching fall at acceleration 1, the way a ledge is walked off; the
    grid's floor lets nobody through. `FDropFrom` - the deck dropped
    through, let by for that one crossing (the `ignored` of `DeckCrossed`),
    forgotten once the feet are a body (`HeroSize`) below its deck - a
    deck going down would catch up -, on the ground (a stand or a walk at
    the head of `Tick`) and in `Revive`. `SettleOnGround` stands him on a
    deck where he is (no snap to a cell line); the corpse settles on a
    deck under it or lands on one it falls onto. `DeckLift(alpha)` - the
    `Lift(alpha)` of the deck underfoot, a fraction of a unit (0 with no
    deck): the units down his picture is drawn, which the feet do not
    feel.
  - Weapon: `FBullets: TBurst` (public as `Bullets`), type 0..4
    (`WeaponType`: pistol / shotgun x5 / grenade
    cloud x22 / chain x3 / minigun: since 3.0.57 a doubled center line - a
    second round half a flight step behind - and a side pair alternating
    `MinigunNarrowAngle` 5 and `MinigunWideAngle` 10 degrees, 15 and 30
    before), cooldown /
    speed / gravity state, `Fire: Boolean` (True = a shot actually left the
    barrel, so the caller barks the sound), `SetWeaponAngle` (verbatim, but
    the sine goes into `ArcSin` clamped to -1..1: feet on a fraction - a
    deck between the rows - round the distance down past the leg, and the
    NaN ended in `EIntOverflow`; a no-op on whole coordinates), `DrawWeapon`,
    the crosshair (`DrawCrosshair` frames 1..4 = the smart cursor colors;
    `CrossDX` / `CrossDY` - its calibration offset), the
    minigun muzzle live tuner (`NudgeMinigun`, DEBUGKEYS; read back through
    `MinigunBaseX`, `MinigunBaseY`, `MinigunMuzzleLen`).
  - Drawing (3.0.47): **`THeroPose`** (record: `Frame` 1..24, `Texture`,
    `Left`, `Top` in screen units, `Mirrored`) is what `Draw` puts on the
    screen this tick; `Pose` is the one place that picks the frame (the
    verbatim `OurHero.Put` selection - death frame, walk cycle, ice skin at
    +16), and `Draw` is `Pose` plus `DrawArm`. `DrawArm` (public) is the
    weapon arm alone, no body: while the shroud puts the body together out
    of strips the game calls it instead of `Draw`. `Pose` has no side effects,
    so the shroud takes the very frame the hero is drawn with.
  - Lifecycle: `Command`, `Tick` (verbatim OurHero.Timer), `Draw`, `SetMouse`,
    `PlaceAtCell`, `SetScreenX`, `SetY`, `ShoveX` (unit by unit, stops at
    walls; 3.0.51: one who stood on a deck before the shove and has none
    under his middle after it is shoved off its edge - `LoseDeck`; off a
    ledge of the grid a shove still drops nobody, as in 2008),
    `ApplyWeaponPickup`, `Kill`, `Revive`; `Dead`, `HeroForm`
    (writable - the ceremony sets it).
- **The arc of a jump** (3.0.29): the two steps of the 2008 arc are the
  free `RiseStep(y, acceleration)` (False once the arc has peaked) and
  `FallStep` - `RiseOneTick` / `FallOneTick` of the tick call them, the
  numbers are the verbatim ones. **`JumpReach(rise)`** (public, free) flies
  the same arc ahead of time: the most empty cells a jump crosses
  sideways to land on a deck `rise` rows up (down when below zero), -1
  when none makes it - the hero's middle a `Bound` (8) inside the deck he
  leaves and the one he lands on, the peak a `Bound` over the deck.
  Up 0-1 rows - 3 cells, up 2 - 2, up 3 - none (the peak is 100 units
  against 96), down 1-4 rows - 4. `Pads.Formations` judges a formation by it
  (`TJumpReach`): the table is the hero's own constants, not a copy.
  `DeckUnderFeet` is public: the game asks which pad the hero rides.
- The Duplet (3.0.64), weapon **`DupletWeapon`** = 5 (0..4 are the 2008
  guns): two barrels, `PelletsPerBarrel` (6) red pellets each from a
  square `PelletSpread` (6) across at the muzzle (`FireDuplet`:
  `MuzzleReach` 32 along the shot, `BoreLift`, `BoreHalfGap`); no kick
  back since 3.0.77 (it threw the hero off his pads). In the hands: `duplet.mset`, sprite
  `held`, its own cache with alpha and linear filtering
  (`FDupletCache`, `FDupletSet`, `FDupletHeld`), drawn `DupletHeldSide`
  (48) square by `DrawRotated`.
- 3.0.75: `Throw(side)` - thrown off a machine he touched: a jump to the
  side (`haJumpLeft` / `haJumpRight`) at `ThrowBoost` 7, about 75 units up,
  with the controls out of his hands for `ThrowLockTicks` 14
  (`FThrownTicks`; `Command` ignores everything meanwhile - the
  `hcStopJump` the game sends every tick would cut the rise short); nothing
  for the dead or for one still flying from the last throw; `Kill` and
  `Revive` drop it. `InAir` - in a jump or a fall (the game's
  `HeroStandsIn` asks it).

### `Game/Monsters.Disc.pas` (~250 lines)
A monster drawn as a spinning disc out of layers instead of its `alive`
frames - the level-1 boss, TEK-R1. Art and pose only: the disc knows nothing
of the monster's logic, and the
logic reads two things of the disc - `FireAt` moves an aimed shot out to
the rim by `Disc.Muzzle`, and `FirePorts` takes the rim's angle
(`Pose.Angle`) to find where the ports have turned to (see `Monsters`).
Not here: the death - a dying disc
monster plays
the `death` frames of its own set, as every monster does.
- **`TDiscArt`** - the layers of one disc set (`rim`, `rimDamaged`, `core`,
  `coreDamaged`, `iris`, `gloss`) through a set and a cache of its own: no
  color key (soft painted edges), linear filter (drawn at every angle).
  Also owns the sensor's glow texture (`Render.Glow`). The destructor
  frees the cache before the set.
- **`TDiscDrive`** (record) - what the monster tells its disc every tick:
  `Center`, `Hero` (what the eye follows), `SpinScale` (1 at the base step),
  `Wear` and `Charge` (0..1).
- **`TDiscPose`** (record) - the disc at one tick: `Center`, `Angle`
  (degrees clockwise), `Iris` (the eye's slide from the center), `Sensor`.
- **`TDisc`** - keeps the pose of the last two ticks (`Pose`, `LastPose`)
  and draws between them: the logic runs at 33 Hz, the screen as fast as it
  can. The constructor places it (`ACenter`), since a screen may be drawn
  before the disc is ever ticked. `Tick(drive)`: `TurnRim` eases the spin
  rate toward `-Spin * SpinScale` (`SpinEase` - the disc spins up from a
  standstill and into its rage in about a second) and keeps the two angles
  unwrapped against each other; `FollowHero` eases the iris toward the
  hero, `IrisReach` out (`IrisEase`, `IrisDeadZone`); the sensor takes the
  charge and fades after a shot (`SensorFade`). `Draw(sprites, alpha)`, back
  to front: the ring turned, its worn copy over it at `Wear`, the hub, its
  worn copy, the iris shifted, the gloss (still - the light does not spin
  with the metal), then the red sensor glow over the eye (`SensorRest*` ..
  `SensorChargedSize`). The layers go through
  `TSpriteRenderer.DrawTurned`, so they shake with the monsters' channel;
  the glow adds the renderer's `Origin` itself.

### `Game/Monsters.Hull.pas` (~255 lines)
A monster drawn as a hull out of layers instead of its `alive` frames -
the TeK platform, the TeK tank (3.0.45), the TeK mount (3.0.48). The disc's
twin without the iris:
art and pose only, the hull knows nothing of the monster's logic. Not here:
where the hull stands - the monster says (`TMonster.HullStand`); the
death - a dying hull monster plays the `death` frames of its own set, as
every monster does.
- **`THullArt`** - the layers of one hull set (`hull`, `hullDamaged`, and
  for a hull on wheels `chassis` and `wheel`) through
  a set and a cache of its own: no color key (soft painted edges), linear
  filter (drawn at a size of its own). `Create(renderer, def)` takes the
  hull's definition: the set's name and whether to ask the set for the
  wheel layers. Also owns the eye's glow texture
  (`Render.Glow`). The destructor frees the cache before the set.
- **`THullStand`** - where a hull stands and which way it heads: `Center`
  (the middle of the hull, screen units) and `Mirrored` (the left-facing
  art heads right).
- **`THull`** - `Tick(wear, charge, rolled)`: the wear is kept, the eye
  takes the charge and fades by `EyeFade` a tick after a shot, and a hull
  on wheels turns them (`TurnWheels`) by `rolled` - the units the body has
  rolled along the floor since the last tick, to the right above zero - over
  the wheel's `Radius`: clockwise for a roll to the right, wrapped past
  `WrapDegrees` with the last angle moved along.
  `Awake` (born True) and `Doze` put the eye to sleep: `FWake` climbs or
  falls by 1 / `WakeTicks` a tick, and the eye's rest glow (`EyeRestLevel`) is
  scaled by it between two ticks - a sleeping hull's eye is dark, though a
  charge still lights it; `Doze` drops it to dark at once. `Wake` is `FWake`,
  read-only: 0 dark to 1 lit.
  `Draw(sprites, stand, alpha)`: for a hull on wheels first `chassis` - the
  dark of the wheel wells - and the `wheel` picture at every axle, turned
  to the angle between its two ticks (`DrawWheels`, through `DrawTurned`);
  then the whole hull and, over it, the worn copy
  at the wear as its opacity (all through `TSpriteRenderer.DrawSized`,
  mirrored by the stand, so
  they shake with the monsters' channel and ride a pad by `FineY`), then the
  red eye glow (`EyeRest*` .. `EyeCharged*`) at the `eye` point, between the
  two ticks of the eye - only the eye and the wheels draw between ticks, the
  hull stands on whole units like a frame. The hull hides the top of a
  wheel behind its fenders and carries their shade in the wheel cuts, so
  the shade stands still while the wheel turns. A wheel is not mirrored
  with the hull: it is painted in flat light, and a mirror would only jerk
  the mark on its hub at every turn of the body. The platform and the mount
  are never mirrored: their art is symmetric,
  and the torn panel of the worn layer would jump from side to side at every
  turn. `Spot(stand, point)` - where a point of the art falls on the
  screen, mirrored across the hull with the stand: the eye, the axles, and
  for the monster the
  smoke, the sparks and the short of a wreck.
- 3.0.75: `Draw` is `DrawUnder` (the chassis and the wheels; nothing
  without wheels) then `DrawBody` (the hull, the worn copy, the eye): a
  machine that puts something between its wheels and its body - the
  Ram's mast - draws the two in turn. `Opaque` is a constant of the
  unit.

### `Game/Monsters.Pilot.pas` (~1075 lines)
The one who flies a monster of the `mkBossFly` kind - the level-1 boss:
where its body goes this tick and what it is up to. The monster keeps its
place, its step and its guns; the pilot moves the place and answers the
monster's questions. Not here: what a maneuver looks and sounds like - the
disc, the bullets and the sparks of a crash are the monster's and the
game's. A 2026 addition all but the lap.
- **The lap** - the boss's rectangle as it was before the pilot, to the
  number: `LapLeft` 32, `LapRight` 448, `LapTop` 96 (one cell under 2008's
  64, clear of the HUD panels), `LapBottom` 320 by the feet point, every
  side overshooting its mark by what the step leaves, no wall asked
  (`FlyLap`, `PastLapMark`). After a maneuver it is flown the other way
  round (`FClockwise`, the `*Turn` tables). Under `ptLaps` the pilot does
  nothing else and the motion is the earlier one tick for tick. A tick of
  it is the free `FlyLapStep(feet, heading, clockwise, step)`, which
  `FlyLap` and `LapAhead` share.
- **The held lap** (3.0.29, for `Pads.Arena`): `HoldLap(hold)` - while
  held, `Cruise` starts no maneuver and `EndManeuver` brings the body
  back to the lap, a hunt too (its parade lap); let go, the rest on the
  lap is rolled anew (`RollRestTicks` at the last step told,
  `FLapStep`) - none for a hunt or when new tactics are owed at once
  (`FRestWaived`). `FliesLap` - the state is the lap. `LapAhead(x, y,
  ticks)` - the lap flown on from the feet point for that many ticks, as
  `TLapStep`s (`Feet` - the feet point of the body, since 3.0.38; `Cell`
  under the middle of the body, `Heading` it flew there by): the pilot
  itself goes nowhere.
- **Types**: `THeading` (hdDown/Left/Up/Right), `TPilotState`
  (psLap/Brake/Ponder/Dive/Aim/Dash/Stun/Return), `TPilotGaze`
  (pgHero/AimPoint/Nowhere - what the eye is on), `TCell` (a cell of the
  screen's grid, 0-based), `TPlace` (screen units: a point or a
  direction), `TPilotCrash` (a dash stopped by a wall: the rim of the body
  that struck, its speed, the way the wall faces, and the `Blow` to a pad
  - `BlowOf` the body a step on, the dash's direction and `StunTicks`),
  `LapHolds(x, y)` (the point lies in a cell of the lap: the fence of a
  knocked pad - he flies the lap without asking the walls), `TPilotBrief` (what the
  monster tells its pilot every tick: its own step, the hero's feet point,
  `BodyAlive`).
- **`TPilot`** - `Create(level, pads, screen, baseStep)` (the pads must
  outlive the pilot); `Tick(var x, y,
  brief)` moves the feet point; `SetTactics` (new tactics open with a
  maneuver at once - `FRestWaived`); `NoteHeroContact` (the game has seen
  the body touch the hero); `Busy` (in a maneuver: a bullet's shove moves
  nothing); `GunHeld` (the monster's aimed gun is silent: in any maneuver
  - off the lap the maneuver is the threat, and the ports speak in the
  pondering - and while the lap is held; the gun fires on a free lap
  alone);
  `Gaze` / `AimPoint`, `Charge` (0..1, for
  the sensor), `SpinScale(lapScale)` (the braking, the pondering and the
  ram spin the disc up by `ManeuverSpinBoost`, a stun stops it, a dive
  spins as the lap does); one-tick pulses `PortsDue`,
  `Crashed` (+`LastCrash`), `OwesPrize`.
- **A maneuver** leaves the lap and comes back to it. Every one opens the
  same way - the one tell to learn: `Cruise` counts the rest down
  (`RollRestTicks`, `MinRestLaps`..`MaxRestLaps` at the step flown), then
  `BeginBrake` onto the lap cell ahead (`LapCellAhead` - on the lane the
  heading flies, whatever a shove or an overshoot did to the body);
  `Brake` eases onto the cell (`BrakeShare`); `Ponder` stands
  `PonderTicks` = 50 and fires the ports on a beat (`PortVolleys` = 5,
  every `PortsEveryTicks`, the last as the maneuver leaves);
  `PickManeuver` then chooses by the tactics. A hunt alone does not
  ponder: its `Brake` goes straight to `PickManeuver`.
- **The dive** (`ptDives`; the other tactics too where a ram has no
  runway): cell by cell through the arena at the monster's own step - the
  rage doubles it - for `DiveTicks` = 130 (`HuntDiveTicks` = 65 in a hunt),
  the aimed gun silent. It sets off toward the hero (`BeginDive`),
  and every turn after has a cause (`DiveHeading`): the
  hero's row or column crossed - onto it, toward him (`CrossesHeroLine`,
  `HeroSide`); a wall ahead - to his side, else the other, else back. Then
  `PathToLap` (breadth-first over open cells, shortest way to the lap),
  `FlyBack`, `JoinLap`.
- **The ram** (`ptRams`, `ptHunts`): flown at where the hero stands,
  seen or not, as long as the dash has a runway (`HasRunway` - the dash
  itself, flown ahead of time: `MinRunway` = 64 units of open flight, or
  to within `SightGap` of him); under `ptRams` the pilot on the lap first
  looks for a cell with one, a lap at most (`SearchesForRunway`).
  No runway - a dive instead. `Aim` holds the
  eye on the point `AimTicks` = 15 and flies the first stride in its last
  tick (a touch in that tick is the dash's), `Dash` flies there in a straight line
  and on at `DashStepScale` = 4 base steps, unit by unit (`Advance`,
  `BodyBlocked` - the body's corners drawn in by `BodyInset`, the arena's
  bounds), into the first wall: `HitWall` (+`WallNormal`), `Stun` for
  `StunTicks` = 50. The tick after the crash `OwesPrize` says the dash
  came to the point the eye had locked on (`DashCameToAim`) and never
  touched the hero: a wall short of the point stopped a dash nobody had
  to dodge. `ptHunts` never goes back to the lap (`EndManeuver`) unless
  it is held: the next maneuver starts from the cell the last one ended
  at, a dive leg between any two rams (`MayRam`).
- **The arena**: the screen's cells whose middle is not walled, rows
  `ArenaTopRow` (under the HUD) to `ArenaBottomRow` (above the bottom row
  of floor and pits) - `CellOpen`. Off the lap a wall is `Walled(x, y)`:
  the grid (`SolidAtPoint`) or the body of a pad (`BodyAt`) - asked by
  `CellOpen` at the cell's middle and by `BodyBlocked` at the body's
  corners, so a dive goes round a pad and a ram crashes into one as into
  a wall.

### `Game/Monsters.Damage.pas` (~65 lines)
The window of a monster's damage cap (`TDamageCap`, JSON `stats.damageCap`):
how many lives the monster may still lose. It only counts; what a blow does
besides taking lives is the monster's.
- **`TDamageWindow`** - `Create(cap)` keeps the cap and a ring of `Ticks`
  slots, one per tick, each holding the lives landed on that tick. `Advance`
  (once a tick, from `TMonster.Tick`) steps to the next slot and forgets
  what it held: the tick that has left the window. `Admit(losses)` gives how
  many of the losses count - the cap less the sum of the window, never below
  zero, never above the losses - and writes them into the current slot. What
  is over the cap is lost, not held over for a later tick. So any `Ticks`
  ticks in a row take at most `Lives` lives, and a gun that fires less than
  that is never touched.

### `Game/Monsters.pas` (~2430 lines)
Monster behavior (data-driven off `TMonsterDef`) plus the field managing them.
- **Enums**: `TMonsterAction` (stand/walk/fall/flying), `TMonsterLife`
  (mlAlive/Dying/Dead), `TMonsterHealthTier` (htHale/Wounded/Critical - the
  crosshair's thirds), `TMonsterEvent` (meNone/BossWantsMinion/Henshin/
  BossRage/LevelComplete/Died/BossCrashed/BossOwesPrize/Burst) - 'MessageToMain'
  of 2008, drained by the game loop every tick; `meBurst` (3.0.58) follows
  the `meDied` of a body that burst by itself - no blow killed it, so the
  game sends its blast out. `TLanePhase` = (`lpNone`, `lpEntering`,
  `lpOnLane`, `lpLeaving`, `lpGone`) and `TLaneRun` (3.0.57) - where a
  body an event let in stands in its lane.
- **The arena's pieces of `TMonster`** (3.0.53-3.0.58): `StrayedOut` - out
  at the right edge, where a patrol turns, or below the screen (a trial
  gravel that walked out of the right gap or fell into the pit);
  `Reappear(x, y)` - put there as if just born, falling, nothing thrown;
  `HeadRandomly` - walks off the way the dice say (2008 lets every
  monster down heading left). The lane: `EnterFrom(side)` - comes in from
  off the screen (x -40 / x 520) through the wall pillar at `LaneStep` 4
  units a tick, no wall oracle asked, to x 32 / x 448, then patrols away
  from that side (`MoveInLane`, `SlideIn`; it holds fire until in);
  `Depart` - a body that came in flies off the top at `LaneLeaveStep` 8
  (`FlyAway`): `mlDead` with no death event, no wreck, no score, it hurts
  and is shot no more; `Leaving` - on its way off, still drawn (its hull
  too); `CameAlongLane`. The drift (`FFallDriftX`, 3.0.57): a body that
  walks off a moving deck keeps the deck's carry across while it falls
  (`CarryX` in `MoveFalling`), or the deck slides back under the feet and
  lands them, over and over; zero when a wall pulled it off, after a
  `Reappear` and on landing. Weather (`TMonsterDef.Weather`):
  `EndWeather` after the move - it bursts on the tick it lands
  (`FLanded`, set by `MoveFalling`), on the grid's floor or a deck; one a
  sprite past the bottom of the screen is gone (`FGone`: dead, never
  drawn, never ticked, no events), and so are the remains of a burst one
  the pit took; `Burst` - dying at once, `meDied` then `meBurst` (the game
  bursts weather on the hero with it too).
- **What a scene does to a body** (3.0.62): `Held` (read-write) - its
  fire held: it walks as ever, its gun silent until let go; `Dormant`
  (read-write, `SetDormant`) - asleep: no step, no shot, no frame, the
  eye of its hull dark at once (`THull.Doze`), the deck and gravity still
  at work (`FallIfUnsupported`), `Asleep` True; `Smite` - struck down
  where it stands: dying at once with `meDied` alone, no `meBurst`, and
  no blow for the game to pay for; `Vanish` - gone from the world: dead,
  never drawn, never ticked, no death to tell (`FGone`); `Stand(x, y,
  facesRight)` - stands there, the left edge of its cell and its feet,
  facing as told: nothing thrown, no drift, the wheels of a hull at rest,
  walking the way it faces; `DeckUnderFeet` - the deck under it, nil for
  one falling, flying or that ignores gravity (a scene's wait reads it).
- **`TMonster`** - position, screen, the placement's `Tag`, direction, `Life`,
  lives (+`LivesAll`), anim frame, step, fire timer, enrage flag (`Enraged`), boss minion timer, a one-shot henshin
  flag, the event list, for a disc monster its `TDisc` (`Disc`, nil
  for the rest), for a hull monster its `THull` (`FHull`, nil for the
  rest) and for an `mkBossFly` monster its `TPilot`. Its own
  collision oracles
  (`CanGoLeftEdgeAware`/`WallOnly` pairs = CanIGo*1/2 of 2008, `CanGoDown`),
  `ShoveX`. The constructor puts the monster on its placement's cell
  (column - 1 and row, times the sprite size), a seated one (3.0.52,
  `TEntityPlacement.Seat`) on the seat itself - `SeatLeft` and
  `SeatFeet`, in screen units. Pads (a 2026 addition; the constructor
  takes the pad world):
  the floor half of the edge-aware oracles asks `FloorAhead` - the grid's
  cell ahead or a deck spanning the inset edge the oracle looks at - and
  the pull of gravity in `MoveWalking` holds off while `StandsOnDeck`
  (either inset edge of the body on a deck); `DeckEdgeInset` = 0.5 - the
  grid asks for the cell an inset edge stands in, a deck for the point
  half a unit inside it, and on whole units the two answers agree at a
  deck's ends too. `MoveFalling` lands on a deck the feet came down onto
  (`DeckCrossed` over the inset span) at its `Top`, as on the grid's
  floor, and presses it (`Press` with the acceleration). A walker's walls
  stay the grid's alone. `RideDeck` at the start of `Tick` (not while
  flying or falling - a falling body lands by `MoveFalling` alone): the
  deck the body lay on a tick ago (`DeckCarrying` over the inset span)
  puts the feet on its `Top` and takes the body across by its `MotionX` a
  unit at a time while the wall oracle (`CanGoLeft/RightWallOnly`) lets it
  (`CarryX`); a deck a
  wall has pulled away leaves the body falling (`maFalling`) when no deck
  holds it (`StandsOnDeck`), the way down is open (`CanGoDown`) and
  gravity holds it - the dead and a gun that never walks too.
  `DeckLift(alpha)` - the `Lift(alpha)` of the deck underfoot, a fraction
  of a unit, 0 while flying or with no deck: the units down the picture is
  drawn. Movement: `MoveWalking`/`Falling`/`Flying` (the boss:
  `MoveFlying` hands `Monsters.Pilot` a `TPilotBrief` - the step, the
  hero, whether the body lives - and the pilot moves X, Y; a crash and an
  owed prize come back as `meBossCrashed` / `meBossOwesPrize`),
  `PatrolStep`. Combat:
  `FireAt` (patterns from `TAttackDef`; an aimed shot of a monster whose
  `Disc.Muzzle` is above zero leaves from the rim, `Muzzle` out from the
  middle toward the hero, instead of the 2008 point (X + 8, Y + 8) - the
  angle is still the verbatim one, from the monster's X, Y to the hero's,
  so the shot now runs through the middle of the hero's hitbox, not along
  its left edge; a straight shot of a monster whose hull `HasMuzzle`
  leaves from that point of the art, put on the screen by `THull.Spot`
  over `HullStand` - so it turns round with the hull - and moved a sprite
  down into a bullet's units, instead of the 2008 quarter of the cell;
  the cluster of five keeps its cross about it; the rain volley of a
  monster whose hull `HasMuzzle` is a row about that same point - the
  first bullet `(VolleyCount - 1) / 2` steps of `volleySpacingX` to its
  left, the same step on from there - and without a hull it is the 2008
  row; `MuzzleSpot` is the one home of the point for both), `FirePorts` (a volley when the pilot says `PortsDue`:
  one bullet out of every angle of `Disc.PortAngles`, turned with the
  rim, `Muzzle` from the axis, straight out; fired after `TickDisc`, so
  the ports are where the frame shows them), `TakeDamage` (knockback
  through the wall oracle - not while the pilot is `Busy`: the oracle asks
  one row, and a body between two rows would be shoved into a wall -
  + the boss's fans + events; the lives that land go through the monster's
  `FDamageWindow` - `Admit` in `TakeDamage`, `Advance` in `Tick`, nil for a
  monster with no `damageCap` - so a blow over the cap still shoves the
  body and trips the thresholds, only its lives do not count),
  `EnrageTankIfLow`,
  `ProcessBossThresholds`, `BeginDying`. The disc: `TickDisc` (late in
  `Tick`: only the ports' volley comes after) hands it `ArtCenter` (the
  middle of the sprite), `EyeTarget`
  (the hero's middle; under the pilot's `Gaze` - the point a ram has
  locked on, or the disc's own middle for a stunned eye), the step over
  the definition's speed (rage doubles the step, so the spin; a pilot's
  `SpinScale` has the last word), `Wear(WearFull)` (lives lost since birth over `WearFull` -
  `FLivesBorn`, because rage resets `LivesAll`; the hull's too) and `ShotCharge` (rises
  over the last `TelegraphTicks` = 10 before a shot, 1 on the tick of one;
  where the pilot holds the gun - its `Charge` instead; 0 while a sentry
  sleeps). The hull:
  `TickHull` right after `TickDisc` hands `THull.Tick` the same `Wear`
  (over the hull's `WearFull`), `ShotCharge` and how far the body has
  rolled since the last tick: its travel in X since `FHullX` less what a
  deck carried it this tick (`FCarriedX`, measured around `RideDeck`) - a
  step and a shove turn the wheels, a ride on a pad does not. `Draw` stands
  the hull at
  `HullStand` - on whole units, as a frame
  stands, so the picture, the hitbox and the smoke stay glued: the middle
  of the sprite for a hull that flies, the feet line under the bottom edge
  for one that gravity pulls (`AffectedByGravity`), whatever its height;
  mirrored when the hull `Mirrors` and the body `FacesRight` - while the
  monster lives; a dying one plays its `death` frames. The aimed gun
  under a pilot: held (`PilotHoldsGun` - in every maneuver and while the
  lap is held), its timer stays at zero - a whole interval passes after a
  hold before it speaks; on a free lap the interval and its `=` test are
  the 2008 ones. The rage (`ProcessBossThresholds`): below `FRageLives` -
  `BossRageLives` (120; 80 in 2008) times the difficulty's lives scale,
  as the lives themselves - the step doubles, the fragment wave flies and
  `meBossRage` goes out, as in 2008; the aimed gun's interval is divided
  by `BossRageFireRate` (1: no faster; 2008 had 3).
  Public: `Tick(heroX, heroY, bullets)`, `SetTactics` (a flying boss takes
  them up, the rest have no pilot), `NoteHeroContact`, `LastCrash` (asked
  on `meBossCrashed`), `HoldLap` / `FliesLap` / `LapAhead(ticks)` (the
  pilot's, for `Pads.Arena`; a body without a pilot holds nothing, never
  flies a lap and has none ahead),
  `Draw(sprites, alpha)` (a living disc monster draws its disc between
  ticks; everything else - frames on the tick, alpha unused; a pickup
  that is not alive is not drawn at all - 3.0.50, below),
  `DrawSmoke(canvas, origin, alpha)`, `DrawSparks` (the same shape),
  `DrainEvent`, `Collect`, `ArtSet` and `Mirrored` (3.0.50: see "A pickup
  leaves no body" below), `HealthTier` (the
  crosshair's thirds of `LivesAll` as
  `TMonsterHealthTier` - the one home of that rule, via `ThirdMark`),
  `TierShare` (how full the current third is, 0..1), `TicksSinceHit` /
  `HitWithin(ticks)` (-1 until the first hit; the health rows read it, so the
  HUD keeps no memory of the field). `HitBox` - where a shot lands on the
  body, in screen units, the one box bullets, blasts, orbs and shards all
  read: a hull's `width` x `height` plus `HullHitMargin` (2) on every side
  around its `HullStand` center, a disc's `side` square around the art
  center, for the rest the 2008 column (the sprite less `MonsterBound` on
  either side). `FSecret` is declared and always False -
  the placement flag it waits for is not in the level format yet.
- **`TMonsterField`** - owns `TObjectList<TMonster>`, the animset cache keyed
  by the placement's spriteList name, and one `TSpriteSet` plus one
  `TSpriteCache` per sprite list (all owned here; `AnimFor` opens
  `sprites\<stem>.mset` on first use and has the cache expect dense art
  above `Frame2008Side`, 64 px - the HD barrel lives beside its 2008
  frames). `FLivesScale` is the difficulty
  multiplier applied to every monster born in this field. The constructor
  (`renderer, registry, level, pads, difficulty, livesScale`; the pads must
  outlive the field, every monster gets them) skips every
  placement whose `Grades` do not hold the difficulty - the field is reborn
  on restart, so a difficulty change lands here. `Tick` (current
  screen), `SpawnFromSky(monsterId, screen)` (boss minions and the gravel
  trial's gravels, at a random column of `SkyColumns` (15) one row above
  the screen - the fall is the entry; returns the body since 3.0.53),
  `SpawnFromSkyOver(monsterId, screen, column)` (the same over a column of
  the caller's, 0-based: the aimed gravel, a medkit or a body of the wave
  over a shelf), `SpawnInLane(orders, screen)` (3.0.57: the body of a
  spawn action, made in column 1 of the row's feet line with the orders'
  tag and sprite list, then `EnterFrom`), `DepartGuests(screen)` (every
  body that came along a lane flies off the top), `CountAliveOf(monsterId,
  screen)`, `CountAliveGuests(screen)` (the gate of the trial counts
  them), `ReturnSideStrays(monsterId, screen)` (the live bodies of that
  kind gone out of the side come back from the sky, each over a column of
  its own), `TryReturnPitStray(monsterId, screen, pitColumn, out body)`
  (one fallen into the pit comes back over that column or up to two
  beside it), `CheckSpawnIds` (in the constructor: `Find` raises on an
  unknown monster of a spawn or a skyFall action or of a finale, at level
  start), `SpawnPlaced` (the private maker of a body from a placement),
  `SpawnOn(monsterId, screen, x, y)` (on the very place
  of a body at the point: a prize put into the hero's hands, the contact
  of the same tick collects it; both over the private `SpawnAt` in
  placement cells), `SetTaggedTactics(tag, tactics)` (the events' tactics
  action),
  `AnyAliveTagged(tag)` (any live body carrying the placement tag, on any
  screen - the events' allDead), `AnyTaggedLivesBelow(tag, lives)` and
  `AnyTaggedEnraged(tag)` (live bodies only - livesBelow and enraged; the
  livesBelow mark is told for the normal grade and compared times
  `FLivesScale`, so a boss's marks keep their order on every grade),
  `FirstAliveTagged(tag)` (the first live body carrying the tag, nil when
  none - the arena's conductor), `FirstTagged(tag)` (the same, dead or
  alive - 3.0.39, the arena's ripple of a restore; a scene's mark and its
  spawn), the scenes' hands (3.0.62) - `HoldTagged(tag, held)`,
  `SmiteTagged(tag, bullets)`, `ReleaseTagged(tag)` (neither held nor
  asleep), `RemoveTagged(tag)` (`Vanish`), every body carrying the tag -
  and `SpawnStanding(monsterId, spriteList, screen, x, y, tag,
  facesRight)` (a body tagged and stood at the point, its sprite list the
  monster's own when '' - a monster with none, the tank, needs one;
  `CheckSpawnIds` refuses a scene's spawn of a monster with no art on
  either side, `SSceneSpawnNoArt`),
  `Draw(sprites, screen, alpha)` (each monster with the sprites' `FineY`
  set to its `DeckLift(alpha)` - `Origin` stays the monsters' shake -,
  `FineY` put back to 0 after; two passes, so a medkit or a weapon still
  there is drawn over the corpses),
  `DrawSmoke(canvas, screen, origin, alpha)`, `DrawSparks` (the same
  shape, over the smoke).
  `DiscArtFor(def)` - one `TDiscArt` per disc set name, opened on first use
  and owned here, `HullArtFor(def)` - the same for the `THullArt` of a hull
  set; the destructor frees the monsters before the art they draw with.
- **Body smoke** (a 2026 addition, default behavior, no data): `TBodySmoke`
  is one body's smoke - the `TSmokeLook`, the tint, the point on the
  left-facing art, the level before the last third and in it, the ramp in
  ticks. Two wear it. A machine - `IsMachine`, has a `blast` and is not
  static: the tank and the flying platform; the mount is not - takes
  `WreckSmoke` (the boss's first smoke, straight up): unlit until
  `HealthTier` reaches `htCritical` (the red third of the health row), then
  60% within a second. An explosive prop - `IsExplosiveProp`, explodes on
  death and is of the `prop` category: the barrel - takes `BarrelSmoke`: a
  pale wisp off the relief valve at 40% from birth, the full plume within
  half a second of `htCritical`. `CreateSmoke(bodySmoke)` makes the `TSmoke`
  and keeps the record in `FBodySmoke`; `WreckIfCritical` and `TickSmoke`
  read the level and the point from there. No emission once the monster is
  no longer alive (dying included). The point goes through `BodyPoint` and mirrors with `FacesRight`,
  the one home of the facing rule, which `Draw` uses too - a barrel shoved
  nine units into a wall or over a ledge turns around, valve and all. A hull's
  point is the hull's own `Smoke`, put on the screen by
  `THull.Spot` over `HullStand`: it turns round with a hull that mirrors
  and stays put on one that does not. The smoke dies
  with the monster, so a restart clears it. `TMonster` got its destructor
  (it frees the hull, the disc, the sparks, the smoke and the event list).
- **Fire start and sentry** (3.0.48): `FFireStart` is where the fire count
  begins - the placement's `fireOffset`, 0 without one - and `FTimeOfFire` is
  born at it. `FireStartOf` holds the offset against the interval and raises
  `ELevelError` (`SFireOffsetOutOfRange`) below 0 or from the interval up. A
  sentry (`Attack.Sentry`) is born asleep (`FAsleep`; its hull `Doze`s), and
  every tick `SentrySleeps` asks whether it still must be: not while it is
  alive, armed (`FCanShoot`) and `HeroInSentryStrip` - the hero's middle
  (`FHeroX + 16`) within `Reach` of the monster's middle (`ArtCenter.X`) and
  the hero's feet line lower than the monster's. A sleeper holds the count at
  `FFireStart` rather than freezing it, so a hero who leaves and returns
  meets the whole interval again; its `ShotCharge` is 0, and `TickHull`
  hands the hull `Awake := not FAsleep`. Only the monsters of the hero's
  screen tick, so the strip is read there alone. Level 2's three mounts all
  watch (`reach` 48 - three cells), and the second of screen 6 starts at 22:
  with the hero in both strips it fires on tick 23 and the first on tick 45.
  `Asleep` is `FAsleep`, read-only.
- **Wreck sparks** (default behavior, no data): the bodies `ShortsOut`
  names - a machine, and a body that has a `blast` and a hull, which makes
  the mount one though it is no machine - own a `TSparks` made from the
  `WreckSparks` look (a rare crackle: two sparks a second and an arc of
  about five every second and a half, ringing off the floor) and a
  `TLightning` for the short, unlit until the same moment -
  `WreckIfCritical` is the one trigger, and it asks nothing of the smoke:
  the red third sets `FWrecked`, and the smoke and the sparks each light
  up if the body has them (the mount has no smoke) - then at full at once. The point
  (`WreckSparksX/Y`) mirrors like the smoke's - a hull's `Sparks` stands for
  it and for the short's, mirrored only with the hull; the probe is the monster's
  own screen (`SolidUnderPoint`: `TLevel.SolidAtPoint` or a pad's body,
  `BodyAt`); the seed is
  `SpawnSeed` (the spawn point, the smoke's seed too) under a salt, so the
  two do not roll alike. `TickSparks` after `TickSmoke`, `DrawSparks` over
  the smoke.
- **A pickup leaves no body** (3.0.50): `Collect` is the hero's take -
  `FLife` goes straight to `mlDead`, `FStep` to 0, and one `meDied` goes
  out, on which the game plays the pickup's sound as for any death.
  Neither `TakeDamage` nor `BeginDying` is called: nothing dies, the body
  is gone at once, and a later blow does not kill it again. A pickup
  destroyed by anything else still dies through `TakeDamage`. Either way
  `Draw` leaves a pickup (`mcPickup`) that is not `mlAlive` undrawn - its
  `death` frames no longer play, and what is seen of it from that tick on
  is `Game.Uptake`'s to draw. `ArtSet` - the stem of the sprite list the
  body was born with (`medic`, `weapon1`), kept in the constructor: the
  set's name, by which `TUptakePainter.PictureOf` finds the picture.
  `Mirrored` - whether the picture is drawn turned over: `FacesRight`,
  what `Draw` hands the sprites for a living body.
- 3.0.64: **`PictureBox`** - where the frame is drawn, in screen units,
  the deck's lift aside: the cell, or the def's `Picture` standing on the
  feet line and centered on the cell (drawn through `DrawSized`); the
  uptake and the hit tests of a picture read it. 3.0.67: `DrawPicture` -
  the picture turned and lifted by its clock (`FAgeTicks`, ticks lived on
  the hero's screen; `PictureHoverSeconds` 4 for one hover there and
  back); an `Anchored` def is moved by no blow, blast, deck or pilot, an
  `Invulnerable` one loses no life; an entity's `ShiftX` moves it off its
  cell.

### `Hud/Hud.Messages.pas` (~335 lines)
- **`TMessageBoard`** - the 2008 message system: ticker lines (slide-in,
  private `TTickerLine` record), the big mid-screen headline, score popups
  (private `TScorePopup`, '+N' rising), and the comm terminal it owns
  (`Hud.Terminal`) in place of the 2008 marquee. `Tick` / `Draw(alpha)` - draw
  is interpolation-aware (popups, the ticker's step). API: `AddTicker`,
  `ShowBig`, `StartTerminal(header, text, place)` (`place` - a
  `TTerminalPlace`, top by default; the ticker steps down only for a box
  at the top), `TerminalKeyStruck` (the game plays
  the click), `AddScorePopup`, `ClearPopups` (screen transitions strand popups
  over the wrong geometry), `Clear` (death silences the board, the terminal
  too). The ticker stacks from y=52; while the terminal box stands the stack
  steps down below it (`ShiftTicker`, 4 units a tick) and climbs back when the
  box is gone. The ticker holds five lines at most (`MaxTickerLines`; a
  newcomer evicts the oldest) and a line fades over its last 33 ticks; a
  popup lives 50 ticks, rising 0.5 a tick. The constructor takes the font,
  the renderer (for the terminal's brush) and the frame width (the headline
  centers on it).
  `BigMessageTicks=100`
  and `TickerNoticeTicks=125` (interface consts) are the standard lives of a
  headline and of a ticker notice. `ShowBig` takes an
  optional note - a small line under the headline, gone with it (the first
  bonus names the mouse button this way).

### `Hud/Hud.Typewriter.pas` (~145 lines)
- **`TTypewriter`** - text that types itself out, logic only (no drawing, no
  sound): one letter a tick, a line break costs a tick, an empty line between
  paragraphs pauses 12 ticks. `Start(lines)` (trailing empty lines dropped),
  `Tick` (counts even when done - the blink runs on it), `Finish`, `Done`,
  `Shown(row)` (the typed part of a line), `Lines`, `CursorRow`/`CursorColumn`,
  `CharCount`, `KeyStruck` (every second typed letter that is not a space),
  `CursorVisible(TBlinkPace)` (`bpTyping` 8-tick half-period, `bpOnHold` 32).
  Shared by `Hud.Terminal` and `Hud.Briefing`.

### `Hud/Hud.Briefing.pas` (~170 lines)
- **`THudBriefing`** - the story before a level (`introText`), typed over the
  menu sky. No frame: a dark plate (`PanelColor`, 0.72) under the header and
  text only. The author's line breaks and indents are kept, nothing is
  re-wrapped; text at (26, 60), header `> ` + `briefingHeader` above it, prompt
  centered at y=344 once the text is out, blinking with the slow cursor.
  `Start(header, text)`, `Tick`, `Finish`, `Done`, `Draw(prompt)`,
  `KeyStruck`. Owned by `TMoonGame`; `AdvanceBriefing` there decides
  "finish typing" or "start the level".

### `Hud/Hud.Terminal.pas` (~270 lines)
- **`THudTerminal`** - the station's comm channel: a framed box (x=6, y=40,
  360 wide) under the heart monitor. A long text is word-wrapped by glyph count
  (45 per line - the small font is monospaced), typed by its own `TTypewriter`,
  held for 1 s plus a tick per letter, then faded in 1 s.
  `TTerminalPhase` = (`tpOff`, `tpTyping`, `tpHolding`, `tpFading`);
  `TTerminalPlace` = (`tlTop`, `tlBottom`) - under the heart monitor, or
  along the bottom edge (a gap of `PanelMargin`, the box growing upward
  from it: `BoxY`) on a screen where the hero comes in at the top and the
  monitor corner would sit on him. `Start` (header, text, place; a
  newcomer replaces the current and takes its place with it), `Place`, `Clear`, `Tick`, `Draw`,
  `Visible`, `Bottom` (the ticker lane reads it), `KeyStruck` (every second
  typed letter that is not a space - the terminal makes no sound itself).
  Header `> ` + `terminalHeader` from the lang files, or the voice an
  event's hint gives (its `header`, the screen 7 transmission). Box and cursor through its own `THudBrush`, text through the font.
  The terminal knows nothing of the fight: a hint that must wait for one is
  a level event (`Levels.Events`) that starts it after the last body falls.

### `Game/Game.Bonus.pas` (~25 lines)
The vocabulary of the bonus roulette, shared by the game that runs it and the
HUD that shows it: **`TBonusKind`** (bkNone/Health/FireRain/Aura/Explosion;
bkNone = empty slot) and `BonusCost=50`. Since 2.5.2 the cost is paid when
the reward is activated, not when it is rolled, so the score keeps climbing
past 50 while a reward waits.

### `Core/Game.Space.pas` (~45 lines)
The two sizes of the coordinate space, kept apart on purpose. The SCREEN is
one flip-screen of a level (`ScreenCols=16`, `ScreenRows=12`,
`ScreenWidth=512`, `ScreenHeight=384` - cells, walls, doors, bullets
leaving the world). The FRAME is what the window shows (`FrameWidth`,
`FrameHeight` - the SDL logical size, HUD corners, centered text, the
menu). Equal today; the wide frame grows past a 4:3 screen, and later the
screen size follows the level. Every reader of either must survive the two
diverging. Replaced `GameWidth`/`GameHeight` of `Hero` and the literal
512/384 of `Monsters`, `Bullets` and the dpr (3.0.1).

### `Core/Render.Brush.pas` (~235 lines)
The brush the primitive-drawn panels share - the HUD units and the menu's
difficulty cells - plus the color and random vocabulary of the whole
renderer: `TRgb`, `Mix` and `TXorShift` serve `Render.Glow`, `Render.Globe`,
`Render.Puff`, `Effects.Sparks`, `Effects.Debris`, `Levels.Dynamics`,
`Game.Explosions`, `Game.Impacts`, `Monsters.Disc`, `Monsters.Hull` and the menu sky rig. No sprite, no font atlas. (Was Hud.Draw
until the menu
started drawing with it; the class inside still carries the old name,
`THudBrush`.)
- **`TRgb`** (record); the palette as typed constants (`CalmColor` blue,
  `WaryColor` amber, `AlarmColor` red, `HaleColor` green, `BonusColor` lime +
  `BonusShade`, `CalmShade`, `PanelColor`, `White`); `Mix` (lerp);
  `HealthColor(health)` (red at 0-1, amber at 2, calm above).
- **`TXorShift`** (record: `Seed`, `NextUnit` -> 0..1) - an own random
  stream for HUD flourishes; the RTL `Random`
  feeds the boss spawn table and must not be touched by a spark. The owner
  sets a non-zero `Seed` - xorshift never leaves zero.
- **`THudBrush`** - `Fill` (alpha blended rect in game units), `Glow`
  (additive), `Frame` (a one-unit outline from four rects), `DrawNumber` (3x5
  pixel digits; `NumberWidth` measures; since 3.0.70 both take the size of
  a pixel, `DigitPixel` 3 by default), `DrawPercent` (3.0.70, a 3x5 percent
  sign; digits and sign go through `DrawGlyph`), the cells every health row is made
  of - `FullCell` (fill + top sheen), `EmptyCell` (dim outline), `BonusCell`
  (lime with a shaded foot), all with an alpha so a row can fade -
  `BeginDraw`/`EndDraw` (blend mode on and off again - the rest of the game
  draws opaque).
- Panel geometry constants shared by both corners: `PanelMargin=6`,
  `PanelY=4`, `PanelH=32`, `PanelW=118`, `ReadoutY`, the cell row (`CellY`,
  `CellW=7`, `CellH=4`, `CellGap=1`); `DigitPixel=3` (at the top of the
  interface since 3.0.70: it is a default of `DrawNumber`).

### `Hud/Hud.Vitals.pas` (~365 lines)
The hero's health display: a heart monitor in the top-left corner, drawn
with the brush alone. **`THudVitals`** - `Tick(health, invulnerable)` once
per logic tick, `Draw`.
- `HealthyHealth=5` (interface const): the base row of five cells; empty ones
  stay as outlines, so hard/wild start visibly wounded. Health above five is
  bonus and gets lime cells past a divider (cure ceiling 10).
- The ECG lane: an 88-sample ring buffer, two samples per tick, a PQRST beat
  shape, tempo by health (62 bpm with bonus, 70 at 4-5, 92, 118, 152 at 1),
  flat at zero, noise for 10 ticks after a hit; a 4-sample wipe ahead of the
  sweep, the trace fades with age.
- The readout: 3x5 digits, lime while health is above `HealthyHealth`,
  blinking at 1.
- Observes rather than listens: reacts to the difference between ticks
  (lost cell flash, grown cell glow, the trace flashing white with a beat at
  once on a cure, red frame on a
  hit, white blink of the cells during the mercy window).
- **`Wing`** (3.0.70, units) - the panel reaches that far past its own width,
  inside its frame, with a divider where its width ends: the slot of the
  form's charge. What is in it is `Hud.Energy`'s; the game passes
  `THudEnergy.WingWidth` every tick.

### `Hud/Hud.GoRight.pas` (~235 lines, 3.0.63)
The go-right arrow: the way on is open. A tube of light along an arrow's
outline, blinking a few beats, then gone.
- **`TGoRightBeat`** - the blink: `Show` (from the first blink), `Hide`,
  `Tick` (after the last blink it hides itself), `LevelAt(phase)` - how
  lit, 0..1, between ticks; `Shown`.
- **`THudGoRight`** - `Create(renderer)`, `Show`, `Hide`, `Tick`,
  `Draw(alpha)`; drawn as passes of **`TTubePass`** (width, level,
  whiteness, miter limit) along the outline through a beam texture
  (`DrawTube`, vertices and indices of its own).
- Who shows it: the events' `goRight` and `openDoor`
  (`TDirectorCues.GoRight` / `OpenDoor`); the game hides it on a new
  screen. Tests: `Tests.Hud.GoRight`.

### `Hud/Hud.Energy.pas` (~340 lines, 3.0.70)
The charge of the form: a small eclipse in the slot the heart monitor's
panel grows on its right (`docs/mechanics/arena-3.md`, stage 6).
- `FullEnergy=100` (interface const).
- **`TEnergyReading`** - `Tick(charge)`; `Charge`; `Wing` (how open the
  slot is, 0..1: up over `WingTicks` 8 once there is a charge, down again
  without one); `Arc` (the charge the arc shows: a rise eased in,
  `ArcPull` 0.12 a tick, standing on it within `ArcSnap`; a fall - a death
  - at once); `Flash` (1 at a rise, out over 14 ticks); `Age`.
- **`THudEnergy`** - `Create(renderer)`, `Tick(charge)`, `Draw(alpha)`,
  `WingWidth` (32 units as open as it is), `Heart` (class function: the
  middle of the disc - where the orbs fly), `Reading`. Draws a halo
  (`gsPoint`, breathing, flashing, faster when full), the black disc 20
  across (`gsDisc` through `CreateShadeShape`), a faint ring of the whole
  rim, the arc from the top clockwise in two strips (`DrawRim`:
  `SDL_RenderGeometry` over `gsBeam`, up to 64 segments a circle) and a
  white head, the number with a percent sign in the middle (pixel 1.4,
  1.2 for 100; the sign at 1.0 on the line).
- Tests: `Tests.Hud.Energy`.

### `Hud/Hud.Charge.pas` (~460 lines)
The score display: the bonus charge in the top-right corner, the twin of the
heart monitor, widened on the left by the reward slot (150 units against the
monitor's 118). **`THudCharge`** - `Tick(score, streak, bonus, novice)` once
per logic tick (bonus = the reward held, bkNone when the slot is empty; novice
= no reward spent yet), `Draw`.
- The readout (37 units - three digits plus two units of air a side - capped
  at 999), a bar filling toward
  `BonusCost` with a tick every ten points (a stiff spring, so a kill jolts),
  and the kill streak as a row of ten cells (`StreakGoal`) - the ten kills
  without a scratch the game rewards but never showed.
- A waiting reward turns the bar lime, breathing, with a glint every 2 s.
  The reward itself sits in the slot: a 24x24 cell with its icon at double
  scale (`HealthIcon`/`FireRainIcon`/`AuraIcon`/`ExplosionIcon` as 9x9 rect
  lists) and a 7x10 mouse glyph (`MouseBody`, `MouseRightButton`) hanging off
  the corner like a hotkey badge. On award, sparks burst from the bar and are
  pulled into the slot; the icon appears with a flash when they land. The
  frame flashes white when the reward is spent.
- A novice gets insisted on: the slot pulses and the right button blinks like
  a press. After the first reward spent the button stays lit, dim and still.
- Streak endings are told apart by the score: reset with points = the tenth
  kill paid out (white flash), reset without = a hit (red flash on the lost
  cells).

### `Hud/Hud.Marks.pas` (~350 lines)
Health rows over the figures, drawn with the brush; built by `CreateHud` in
`Game.Moon` with the corner HUDs. **`THudMarks`**.
- The Ram's head (3.0.76, `DrawRam(ram, shift, alpha)` on the world's
  channel, after `Draw`): `HeadRowCells` 12 cells, four a third, colored
  by the share of its lives in the thirds' colors (they are also how it
  fires), `HeadRowLift` 6 over `TRam.HeadTopAt`; it does not fade while
  the head is up. `TRam.Row` tells it all: `Lit` - the cells come up one
  by one after the lock, the newest glowing; a hit reddens the frame and
  whitens the cell it emptied into for `HeadHitTicks` 8; a dead head's
  row, empty, fades. `DrawCells` - the row of full and empty cells,
  shared with the monsters' rows.
- The hero's row: 4x4 cells with a gap of 2, centered over the head (9 units
  above the sprite's top), the monitor's grammar - `HealthyHealth` cells of
  norm with the empty ones as outlines, bonus cells past a divider, on a dark
  plate. Shows on any change (`Tick(health, invulnerable, screen)` - observes
  the difference like the monitor), 80 ticks with a 20-tick fade; stays while
  health is 1; nothing over a dead hero; a new screen drops it. On a hit the
  cells, plate and a frame come up red and cool over 12 ticks; lost cell
  flashes white, grown cell glows, mercy-window blink.
- A monster's row: six cells, a pair per third (`MonsterFullCells`: full
  pairs below the current third + one or two by `TierShare`), so a pair
  empties in the tick the color turns; colored by `HealthTier`
  (green/amber/red like the crosshair), only over
  `mcEnemy`/`mcBoss` on the hero's screen and only within 80 ticks of a hit
  (`HitWithin`); a hit extends the row, nothing flashes. A kill finishes it:
  the cells drop to zero over the dying figure and the row dissolves in 20
  ticks (`MonsterAlpha`).
- `Draw(hero, field, heroShift, monsterShift)`: the rows ride their figures'
  shake channels - the brush draws past the sprite renderer's `Origin`, so the
  offsets are passed by hand. Drawn after the bullets, before the crosshair
  and the corner HUDs.

### `Game/Game.Explosions.pas` (~400 lines)
The one home of "something blew up" - the look, not the mechanics (the
wave that wounds is `Game.Blasts`). **`TExplosions`**, made once
with the game (renderer + the solid probe + the aftershock echo), cleared
on a door, a death and a level load.
- **`TEchoAftershock`** (`reference to procedure`) - the game's answer to an
  aftershock, its sound and its jolt. The game sounds the blasts it
  detonates itself; the aftershocks go off here on their own clock, so
  each one calls back right after its `Detonate`.
- `Detonate(x, y, kind, shardLives = 0)` - x/y the heart of the blast in
  screen units; `ekNone` does nothing; `shardLives` above zero bursts the
  debris live, and `StrikeShards(verdict)` hands the game the live shards
  once a tick (`TDebrisField.Strike`). Per kind a private typed constant
  `TExplosionLook`: a `TDebrisLook`, the flash (`FlashSize`, `FlashTicks` -
  two `gsPoint` glows, a swelling warm one and a white core, fading as a
  square), two clouds, each a `TCloudLook` - `Puffs` (a `TSmokeLook`),
  `Tint`, `Ticks`: `Pour` makes a `TSmoke` by `CreateLook` at full
  intensity and fades it to zero over `Ticks`, so it pours and thins, and
  it is freed once `Exhausted` - and aftershocks (count, kind, spread,
  span - a queue of later `Detonate`s, `TickAftershocks`). The clouds:
  `Fire` (3.0.43), the fireball - hot puffs thrown all round the heart,
  heat 1, orange cooling to a dark red, dense and short-lived, so that
  something burns for half a second where the body stood; and `Smoke`,
  the grey plume. The two roll different dice from one point
  (`FireSeedSalt`).
- Sizes: `BarrelExplosion` (18 shards, 64 sparks, flash 96 for 7 ticks,
  about 25 puffs of fire some 60 units across), `MachineExplosion` (28,
  90, 130 for 8, about 39 puffs - the tank, the platform, the boss's
  rage), `BossExplosion` (48, 160, 220 for 11, about 75 puffs, plus five
  barrel blasts within 24 units over 50 ticks - the wreck keeps popping),
  `MountExplosion` (3.0.48: the barrel's size thrown down - `Heading` 270,
  shards in a cone of 80, sparks of 120, fire of 140, smoke of 120 - for
  the mount, which hangs in a niche one cell wide and would throw
  everything up into the plate).
  The fireball stays inside the flash: 3.0.43 made the blasts denser,
  not bigger.
- `Tick` (aftershocks, flashes, debris, both clouds - `TickClouds`),
  `Clear` (all five),
  `DrawSmoke(canvas, origin,
  alpha)` - the plumes, drawn right after the tiles, behind the figures;
  `Draw(canvas, origin, alpha)` - the fireballs, then debris and flashes,
  over the bullets.
  Both on the world shake channel; the textures come from
  `FDynamics.Canvas`. Own `TXorShift` for the aftershocks.

### `Game/Game.Blasts.pas` (~150 lines)
What an explosion does, as `Game.Explosions` is what it looks like: a wave
out of the heart of a blown-up body that wounds what it reaches. The unit
knows neither a monster nor the hero - the game shows it bodies as objects
and points and hands out the lives and the shove itself (`ResolveBlasts`
in `Game.Moon`). A 2026 mechanic: 2008 wounded with a fan of 180 bullets.
- **`TBlast`** - `Create(heart, def)` (`TBlastDef` of `Monsters.Defs`).
  `Spread` - a tick of the wave, `WaveSpeed` (8) units; `Spent` - the wave
  has gone its radius. `Strikes(body, near, solid)` - True once for a body:
  the wave has reached `near`, the point of the body nearest to the heart,
  and nothing solid stands between (`SightClear`); the body is remembered
  (`FStruck`), so a body the shove has moved is not struck again, and a
  body sheltered now may still be struck if it steps out while the wave
  lives. `Share(point)` - what is left of the blast there, 1 at the heart,
  0 at the radius, falling in a straight line. `Lives(point, scale)` - the
  def's lives by the share and by the difficulty's scale of the monsters'
  lives, at least one. `Knock(point, middleX)` - the shove as a bullet's
  knock, `HeartKnock` (32) by the share, signed away from the heart by
  where the body's middle lies.
- `NearestPoint(body, from)` - the point of a rectangle nearest to a
  point. `SightClear(from, to, solid)` - asks the probe every `SightStep`
  (4) units from `from` up to, not at, `to`: a body stands flush against
  matter, and its own edge must not hide it.

### `Game/Game.Impacts.pas` (~410 lines)
What a bullet throws off the armor it strikes - the look only; the wound,
the knockback and the sound stay with `Game.Moon`. **`TImpacts`**, made once
with the game (the solid probe), cleared on a door, a death and a level
load.
- **`TStrike`** (record) - a bullet meeting armor: the point, the bullet's
  speed, the normal (the way the armor faces there), `Rapid` (the armor
  was struck a moment ago), `ExtraSparks` (sparks on top of the fan - a
  heavier blow throws more; 0 for a bullet - both builders in `Game.Moon`
  start from `Default(TStrike)`).
- `TraceEntry(strike, box)` - the bullet is already inside the hitbox:
  moves the strike back along its path to the edge it came in through (no
  further than one tick) and turns the normal the way that edge faces; a
  bullet hanging still (the aura) gets the normal up.
  `FaceFromCenter(strike, center)` - round armor: the normal from the
  center through the point (the boss's disc).
- `TStretch` (record: `Start`, `Finish`, `PointAt(share)`) - the straight
  stretch a bullet flew in one tick. `StretchEntry(stretch, box, share)` -
  where along it the stretch first meets the box, 0 at its start, 1 at its
  end (0 when it starts inside); False when none of it lies in the box.
  A bullet is a point only at the two ends of its tick, and between them it
  can cross a corner both ends miss (`TShareSpan`, private: the stretch
  clipped by the two pairs of edges in turn).
- `Land(strike)` - `GlanceOf` reflects the speed off the normal, as a
  mirror does; `ThrowFan` sprays `FanSparks` (9, or `RapidFanSparks` 4) plus the
  strike's `ExtraSparks`
  within `FanCone` around a heading that leans `GlanceShare` from the
  normal toward the glance (`HitSparkLook`: bounce, forks); `AddFlash` - a
  3-tick flash, dimmer when rapid, and one a tick for the hits that crowd
  one armor; `ThrowTracer` - with `TracerChance`, never when rapid or for a
  bullet that hung still - one long fast streak along the glance
  (`TracerSparkLook`: next to no gravity, a springy bounce). True when a
  tracer flew - the game gives it its whine.
- Two `TSparkField`s (`MaxSparks` 512, `MaxTracers` 16), `MaxFlashes` 16,
  own `TXorShift`. `Tick`, `Clear`, `Draw(canvas, origin, alpha)` - over the
  bullets, on the monsters' shake channel; the textures come from
  `FDynamics.Canvas`.

### `Game/Orbs/Orbs.Flock.pas` (~525 lines)
The orbs: small lights that fly by a formula, not by ballistics, and take
no notice of matter - no wall stops one. The look and the life of an orb
only: where it is, its owner decides tick by tick; what it strikes is
settled in `Game.HeroOrbs` (`Strike`), what that costs by the game
(`WoundByOrb` in `Game.Moon`).
- **`TOrbTint`** (record) - `Core` (the white-hot point; the body of a dark
  orb), `Glow` and (3.0.70) `Dark` - the body is drawn over the world, not
  added: a black hole. `IceOrbTint` - the hero's element on levels 1-2;
  `MoonOrbTint` (3.0.70, dark, the colors of the moon burst) - the stone's
  charge, and the moon form's to come. A dark orb (`DrawDarkBody`) is two
  units bigger: the halo 15 across, its thick part 10, a white rim 9.2
  (`DiscGlow`) and the black body 7.6 (`DiscShade`) drawn last; its
  implosion flashes in the glow color.
- **`TOrbState`** = (`osAlive`, `osImploding`, `osGone`).
- **`TOrbLayer`** = (`olBehind`, `olInFront`) (3.0.49) - the two passes of
  a flock's drawing about the hero.
- **`TOrb`** (class) - `X`, `Y`, `Size` and `Level` (shares 0..1 of the full
  size and light, written by the owner - an orb coming into being), `Depth`
  (3.0.49; written by the owner, 0 from birth: below zero the orb is drawn
  behind the hero - the flock only picks the layer by it, the owner sets
  `Size` and `Level` to suit the depth), `Age`
  (ticks), `State`. `MoveTo(x, y)` - where the owner's formula puts the orb
  this tick; the step piles up until the flock's next tick, and between
  ticks the orb is drawn on ahead by it, as sparks and smoke are.
  `MoveBeside(x, y, bodyStepX, bodyStepY)` - the same for an orb that keeps
  beside a body drawn where the tick left it (the hero): the body's step
  is taken out of what the orb is drawn ahead by, or the ring would
  tremble against him. `Arrive` (3.0.49) - the orb is at once where this
  tick has put it: nothing of the move is drawn on ahead - for a leap,
  which is no flight. `Armed` (True from birth, written by the owner):
  an orb not armed strikes nothing - the game passes it by; one still on
  its way out of matter. An owner declares a descendant with fields of
  its own and casts to it in one place.
- **`TOrbFlock`** - owns the orbs in the order their owner gave them
  (`Orbs`), the dust and the marks (a `TParticleSwarm` each) and a
  `TXorShift` of its own.
  `Add`, `Insert(index, orb)` - into the owner's order; the three ends,
  `Implode` (the time is up: `ImplodeTicks` 9 of drawing into the point,
  with a flash), `Spend` (it has struck: gone at once, `DustMotes` 7) and
  `Release` (the owner lets it go: gone at once, no flash, no dust - a
  drop that fell off the screen or sank into a floor) - all three only
  mark the orb and `Tick` drops the gone, so they may be called inside a
  walk over `Orbs`. `Tick` comes first in the owner's tick (ages
  the orbs, zeroes their steps, drops the gone, flies the dust): an orb
  not moved after it stands still. `MarkFace(x, y, normalX, normalY)` -
  matter gives an orb up at the point of a face: a streak of light runs
  out along the face (across its normal) and fades over `MarkTicks` 12,
  with a breath of light over the point; both are the point glow, the
  streak stretched. `Shift(stepX, stepY)` - a door: orbs and dust are in
  the new frame at once and nothing is drawn flying; the marks stay
  behind with their faces. `DrawLayer(canvas, origin, alpha, layer)`
  (3.0.49) - one of the two passes about the hero: `olBehind` is the
  marks and the orbs of a depth below zero, `olInFront` the rest of the
  orbs and the dust; an orb is three point glows through `Render.Glow`
  (the halo, breathing; the body; the core). `Draw(canvas, origin,
  alpha)` - both layers in one call, the one behind and then the one in
  front: for an owner whose orbs have no depth (the aura, the rain), in
  the order it always had - the marks, the orbs, the dust. `Clear`.
- The sizes and the lights are constants at the top of `implementation`
  (`HaloAcross`, `BodyAcross`, `CoreAcross`, the breath, the implosion,
  the dust, the mark).

### `Game/Orbs/Orbs.Harvest.pas` (~380 lines)
Where the orbs come from (3.0.32): the matter around the hero. Two
functions and no state, over `Game.Space` and the dice alone - they can
be tried with no game behind them: `HarvestSpots` for the aura and
(3.0.49) `HarvestAround` for the rite of the henshin. Both glean the
faces by the one private walk (`GleanFaces`, with `SpotAt`, `RankSpot`
and `AirSpot`).
- **`TMatter`** (record) - the matter of one screen: `Cells`
  (`TSolidCells`, the solid cells by row and column) and `Bodies` (the
  bodies of the pads standing in front, `TPadWorld.Bodies`). The game
  fills it in `MatterAround`.
- **`TFaceSpot`** (record) - a point on a face of matter: `X`, `Y`, the
  normal (a unit along one axis, looking into the open; zero for a spot
  in thin air) and where the spot lies from the hero's center - `Away`
  (units) and `Turn` (radians).
- **`HarvestSpots(matter, center, count, dice)`** - `count` spots. Every
  solid cell and every body is a box with four sides (up, down, left,
  right); a side gives a spot to every stretch of 8 units
  (`StretchLength`) that looks into the open - the point a unit off the
  stretch's middle (`OpenAt`) lies on the screen, in no solid cell and in
  no body, so a face looking off the screen, into a wall or into the pad
  flush beside it gives nothing. The spot stands off the middle of its
  stretch by up to 2 units (`SpotScatter`). The spots are sorted by their
  distance from the center, each counted as up to 45% farther than it is
  (`NearnessScatter`): the nearer first, but not by the ruler. The whole
  screen is in reach. What the matter is short of stands in thin air 50
  to 90 units from the center, after the rest.
- **`HarvestAround(matter, center, perWave, waves, dice)`** (3.0.49) -
  `perWave` spots for each of `waves` waves
  (`TArray<TArray<TFaceSpot>>`), every wave from all sides of the center:
  the first off the nearest faces, the last off the farthest. The faces
  are gleaned as for `HarvestSpots`, each spot counted as up to 30%
  farther than it is (`AroundScatter`); a spot nearer the center than 34
  units (`NearestAway`) is passed by. The turns about the center are cut
  into 12 equal sectors (`SectorCount`). A wave (`ReapWave`) walks the
  free spots, the nearer first, and takes of one sector no more than
  `perWave` / 12, rounded up; if the sectors gave short, the nearest free
  of the rest, with no limit; if the matter gave short, thin air 70 to
  110 units from the center, in any direction. What a wave has taken is
  marked in the private `TStock`, so no spot is given twice and what one
  wave passed over is free for the next. Within a wave the spots go by
  their turn about the center: the index in the wave's array is the
  orb's number in the wave.

### `Game/Orbs/Orbs.Aura.pas` (~755 lines)
The hero's aura (3.0.31; drawn out of the matter around since 3.0.32): a
ring of orbs on an oval around his body - at even gaps, slowly flowing,
following him on a leash. The formulas are the stand's (the "Orbs Moon2D"
artifact: `aura-core.js`, mode `leash`, for the ring; `castAura` and
`stepRing` of the page for the call); the numbers are constants at the
top of `implementation`. Where the orbs are and when their time is up,
nothing more.
- **`TOvalTrack`** (record) - an oval walked by its length: `Lay(radiusX,
  radiusY)` lays 256 chords, `PointAt(share)` is the point that share of
  the lap along, from the oval's center - equal shares are equal stretches
  of the line.
- **`TAuraStage`** = (`asEmerging`, `asHovering`, `asFlying`,
  `asSeated`) - how far a called orb has come.
- **`TAuraOrb`** (`TOrb`) - its life, its lag (ticks behind the hero the
  center of its oval walks his path) and its aim of a tick ago; its place
  in the ring (`FPlace`: kept from the call on - the ring makes room for
  an orb before the orb is there; the orb itself is shown there once it
  is seated); its stage and the ticks in it, the spot matter gives it up
  at, how long it hangs and flies, its sway, where its flight began and
  the turn about the hero the flight makes.
- **`TAura`** - owns its flock (`Flock`: the game settles the strikes
  through it), the track (half-axes 28 and 35), the hero's path (his
  center tick by tick, the last 128), his course (his speed, smoothed by a
  fifth a tick) and the flow (a lap in 330 ticks).
  - `Cast(center, matter)` - up to 60 orbs (`OrbsPerCast`), as many as
    the ring's ceiling of 120 (`RingCeiling`) leaves room for: a third
    call in a row adds nothing. Over a living ring the new orbs are woven
    in between the old, which keep their order and spread evenly through
    the new count (`FreeSeats` names the seats left to the newcomers).
    The spots come from `HarvestSpots` and are sorted by their turn about
    the hero; the first takes the free seat it faces (`SeatFacing`) and
    the rest follow seat by seat, so no newcomer crosses the hero on its
    way. Each orb (`NewOrb`) begins 3 units under its face (`SunkDepth`),
    unarmed, with a life of 20 s and up to 3 more; it hangs 16 ticks and
    0.7 more for every spot of the call nearer than its own
    (`NearerSpots`), and flies 20 ticks and one more for every 7 units it
    was called from.
  - `Tick(center)` - `Flock.Tick`, then `Follow` (the hero's place into
    the path, his step into the course, a leap noticed), then every orb
    by `Lead`. Its seat is `flow + i / count` of the lap. `ShareBehind` -
    0 at the ring's nose, 1 at its tail, by the angle between the seat
    and the course; 0 all round while the hero stands. `SetLag` takes the
    orb's lag toward `TailLagTicks` 14 times that share, no faster than
    half a tick a tick. `AimOf` - the seat on an oval whose center is
    where the hero was that lag ago (`PathPoint`), drawn in to
    `LeashLength` 12 of him (`Leashed`) and narrowed the farther behind it
    is (`SqueezeLength`). `Chase` - the orb's place takes the step its
    aim has made, whole, and 22% of what is left, no faster than 14 units
    a tick. Then the orb is shown by its stage. When the count changes -
    a loss, a cast - the orbs forget their aims and their places slide to
    the new seats.
  - The call, stage by stage. `Emerge` - `AppearTicks` 10: the orb rises
    along the normal of its face from 3 units under it to 6 over it
    (`HoverHeight`) and grows to its size; on its second tick the face
    gets its mark (`TOrbFlock.MarkFace`). An orb in thin air has no
    normal and no mark: it shows through where it is. `Hover` - it hangs
    over the face, swaying by 1.2 units. `TakeOff` - it leaves from where
    it is and is armed. `Fly` - a spiral about the hero: the distance
    from him and the turn about him both go eased (`EasedInOut`) from the
    takeoff to the orb's place in the ring. The takeoff stands still
    while the hero moves, so the spiral is laid anew from it every tick.
    Which way round is settled on the flight's first tick (`FirstSweep`:
    with the flow; against it only when that takes 0.4 radians or less,
    or when with the flow it would be more than 1.25 pi); after that the sweep only follows the two
    turns (`SweepNear`) - counted anew every tick, as the stand counts
    it, it flips to the other way round in mid-flight and throws the orb
    across the hero. The orb moves by `MoveBeside` with the eased share
    of the hero's step. `KeepSeat` - seated: the orb is at its place, by
    `MoveBeside` with the hero's whole step; past its life it implodes
    and keeps its seat until it is gone.
  - A leap - the hero's step over `LeapStep` 24, the return from a pit:
    the lags are set at once to `ThreadLagTicks` 26 times the share and
    held for `ThreadTicks` 52, the leash off, the seated orbs moved by
    `MoveTo`: the ring pays out as a thread, nose first. An orb in flight
    begins its flight anew from where it is, with the time its new
    distance asks; an orb on its face stays there and flies to wherever
    the hero is when its wait is over.
  - `Carry(stepX, stepY)` - a door: the flock (`Shift`), the path, the
    aims, the places and the takeoffs move by the hero's step, and nobody
    flies. An orb still on its face takes off at once, armed: the face
    stays on the screen behind. `Collapse` - the hero's death: every orb
    implodes, wherever the call has it. `Clear` - the flock and the
    memory of the path (`Forget`, which an empty ring also does every
    tick, so the next cast starts from a hero at rest). `Draw`.

### `Game/Orbs/Orbs.Rain.pas` (~245 lines)
The fire rain (3.0.33): a veil of orbs poured down the hero's screen. The
choreographer of a flock, like the aura, but with no state carried from tick
to tick: where a drop is, is a formula of the time since its birth. The
formulas are the stand's (the artifact "Orbs Moon2D": the rain script, `pour`
and the rain step). What a drop strikes is settled through
`Flock` (`Strike` in `Game.HeroOrbs`), as for the aura.
- **`TDropSeed`** (record) - what a drop is born of: `StartX`, `Birth` (the
  rain's tick), `Sway` (where in its sway it begins, radians), `Floor` (where
  the matter of its column takes it back). **`TRainDrop`** (`TOrb`) - a seed,
  a stage (`rsFalling`, `rsSinking`) and the ticks sunk.
- **`TOrbRain`** - owns a `TOrbFlock` (`Flock`), the seeds not yet born and
  its own `TXorShift` (not `Random`: that one feeds the boss spawn table).
  `Pour(matter)` - `WaveCount` 15 waves of `DropColumns` 32 seeds (a column
  to `DropColumnWidth` 16 units, a drop off its middle by up to half of
  `ColumnScatter` 6); a wave follows the one before by `WaveGapTicks` 4, a
  seed is born up to `BirthSpreadTicks` 9 later. A second pour is added to
  the one falling, no ceiling. The floor of a column is the top of the
  matter that reaches the bottom row of the screen (`FloorOfColumn`; only
  solid cells - a pad is no floor, drops fall through pads and roofs); over a
  pit it is `NoFloor` and the drop leaves the screen.
  `Tick` - the flock first, then the births (a drop is made at the place its
  formula puts it at that very tick, or it would be drawn on ahead by the
  whole way), then every drop: `x = StartX + SwayReach * sin(SwayPace * age +
  Sway)`, `y = FallStartY + FallSpeed * age` (`PlaceAt`). Below the screen by
  `LeaveMargin` 20 a drop is released; at its floor it lands (`Land`: it is
  not armed any more, `MarkFace` leaves a streak on the face) and sinks
  (`Sink`: `FloorSinkTicks` 6, fading and, by `FloorShrinkTicks` 9,
  shrinking). `Collapse` - the hero's death: the seeds not yet born are
  dropped, every orb implodes. `Draw`, `Clear` (the flock, the seeds and the
  rain's clock).
- A drop falls armed all the way: the game takes bullets and dangerous
  monsters with it as with the aura's orbs. A barrel or a medkit is passed.

### `Game/Orbs/Orbs.Patterns.pas` (~240 lines)
The patterns the rite of orbs builds about the hero (3.0.49): a seat for
every orb of every wave at any moment of the pattern's own clock. A
pattern is a function and a name, with no state; it knows nothing of how
the orbs come to their seats or what the seats are for. Over no unit of
the game. The formulas and the numbers are the stand's
(`docs/mechanics/henshin.md`); the numbers are constants in `implementation`.
- **`TPatternSeat`** (record) - a seat in the hero's own frame: `X`, `Y`
  (units right and down from the middle of his body), `Depth` (from -1
  behind him to 1 in front) and `Level` (its light, 0..1).
- **`TPatternSeatFunc`** = `function(wave, index, perWave, flow):
  TPatternSeat` - `wave` 0..`PatternWaves` - 1 (`PatternWaves` = 3: every
  pattern is built in three waves), `index` 0..`perWave` - 1, `flow` - the
  pattern's own clock in ticks, which the rite runs.
- **`TOrbPattern`** (record) - `Name` (the word of a level file),
  `PerWave`, `Seat`. **`FindPattern(name)`** - the pattern of the name out
  of the table at the bottom of the unit (`Patterns`, a typed constant:
  `snowflake` and `vortex`, 24 a wave each); an unknown name raises
  `EOrbPatternError`. `DefaultPatternName` = `'snowflake'`. A new pattern
  is a seat function and a line in the table.
- The snowflake (`SnowflakeSeat`), about a heart 2 units above the middle
  of the body (`HeartY`): six rays that turn once round in 420 ticks
  (`SpinTicks`). Wave 0 - the rays (`RaySeat`: the first orb 14 units
  out, the wave spread over 24), behind the hero; wave 1 - their tips and
  the twigs off them, alternately along a ray (`BranchSeat`: the tips go
  on from 38 units, the twigs branch off at 32, 7 units a twig, to one
  side and then the other), behind him too (depth -0.5); wave 2 - a
  hexagon of radius 22 in front of him (depth 1) with its corners on the
  rays, whose orbs walk its sides against the turn of the rays, a lap in
  210 ticks (`HexSeat`). The light of the rays and twigs runs along them
  in a wave (`Lit`: 0.8, give or take 0.2); the hexagon burns at 1.
- The vortex (`VortexSeat`): a funnel of three arms, one to a wave,
  narrow at the feet (radius 12, 16 units under the middle of the body)
  and wide over the head (22 units wider, 62 units up). An orb climbs
  its arm in 64 ticks (`VortexClimbTicks`), winding 1.6 laps on the way,
  and the whole column turns against the winding (`VortexSpinPace`). A
  seat is put on its ring by `ColumnSeat`: the depth is the sine of its
  turn, so an orb is behind the hero for half a lap and in front of him
  for the other half, and the ring is seen a little from above
  (`ColumnTilt`). At the top of its arm a seat is at the feet again - a
  leap in one tick; its light is out at both ends of the arm (`ArmFade`,
  through `Smoothed`), so the leap itself is not seen, and the rite puts
  the orb there with nothing drawn on ahead (`SeatLeapt` in `Orbs.Rite`).
- Tests: `Tests/Orbs/Tests.Orbs.Patterns.pas` - see Tests below; whether
  a figure is beautiful is for the eye.

### `Game/Orbs/Orbs.Rite.pas` (~1005 lines)
The rite of orbs (3.0.49): the choreographer of the henshin, in place of
the rings and fans of 2008. Three waves of orbs are drawn out of the
matter around the hero, each from all sides; they show through on a
face, hang over it, fly to their seats in a pattern about him
(`Orbs.Patterns`) and sit there; the pattern hovers, quickens, stands
still and flashes, and then every orb draws into him, each in its own
time and at its own point of his body. The same class takes the suit
off: the orbs come out of the body into a ring that shields him a while.
Where the orbs are and when they come and go, nothing more: what an orb
strikes is settled through `Flock` (`Strike` in
`Game.HeroOrbs`), what it all means for the hero - the cure, the mercy, the suit -
is the listener's (`Game.Henshin`). The hero keeps his controls
throughout; the pattern stands in his frame, with no leash. Built as the
aura is: a flock of its own, a descendant of `TOrb`, its own `TXorShift`
(not `Random`: that one feeds the boss spawn table), the numbers
constants at the top of `implementation`. The rite knows no pattern and
no score of its own: both are handed to `Start`. The design, the numbers
and the record stage by stage: `docs/mechanics/henshin.md`.
- **`TRiteScore`** (record, ticks) - the numbers of a rite: `WaveGap`
  (between the calls of the waves), `WaveSpan` (from a wave's call to its
  last seat), `HoverTicks`, `FreezeTicks` (the last of the hover),
  `CollapseTicks`, `StandIns` (armed stand-ins for the whole rite), and
  for the suit shed `ShedOrbs`, `ShedTicks`, `ShedSpread`.
  **`IceRiteScore`** = 22, 56, 32, 9, 22, 24 and 72, 100, 33: the waves
  are called at ticks 0, 22 and 44 and seated by 56, 78 and 100; the
  pause is at 100, the freeze from 123, the collapse at 132, the end at
  154 (`PauseAt`, `CollapseAt`, `FinishAt`) - since 3.0.61 the burst's
  inhale begins there, and the suit goes on with its strike at 156.
- **`TRiteStage`** = (`rsIdle`, `rsGathering`, `rsHovering`,
  `rsCollapsing`, `rsShedding`). **`TRiteEvent`** = (`reNone`,
  `reWaveCalled`, `reWaveSeated`, `rePaused`, `reCollapsing`,
  `reFinished`): `reWaveCalled` and `reWaveSeated` come by the schedule,
  three times each - the listener counts the waves itself.
- **`TRiteOrb`** (`TOrb`) - its wave and its number in it (its seat; its
  place in the ring for an orb of a suit shed), the spot matter gives it
  up at, its stage (**`TRiteOrbStage`** = `roEmerging`, `roHovering`,
  `roFlying`, `roSeated`, `roCondensing`, `roCollapsing`, `roShedding`)
  and the ticks in it, whether it is armed in flight, how long it hangs,
  its flight (how long, the rite's tick it is due to land at, where it
  took off, the turn about the hero it makes), its drawing in (a wait, a
  length, a side and the point of the body it enters at) and the tick it
  fades at in the ring. **`TRiteBirth`** - an orb the rite has called and
  does not yet see born. **`TBodyProbe`** (`reference to function:
  TBodyPoints`) - the points of the hero's body as it stands on the
  screen; the game's `HeroBodyPoints`, passed through `Game.HeroOrbs`,
  and the burst
  (`Orbs.Burst`) asks the same.
- **`TOrbRite`**:
  - `Create(tint, body)`. `Start(pattern, score, center, matter)` - a
    rite already going is dropped (`Clear`); the spots of all the waves
    are taken at once (`HarvestAround`, `pattern.PerWave` a wave) and the
    stage is `rsGathering`. `Tick(center)` - once a tick, with the hero's
    center where the tick has left it: `ReplaceSpent`, `Flock.Tick`,
    `Follow` (the hero's step, a leap noticed), `RunSchedule`, `BeBorn`,
    the pattern's clock and the flash, then every living orb by `Lead`,
    and `Finish` on the tick of the suit. Idle, it ticks the flock alone:
    the dust flies and what is imploding goes out. `DrainEvent` - what
    has come to pass since the last call, the oldest first; `reNone` when
    there is nothing.
  - The gathering. `CallWave` queues a wave's births, each up to 2 ticks
    after the call. An orb (`NewOrb`) begins 3 units under its face,
    unarmed, at no size and no light. `Emerge` - 8 ticks (`AppearTicks`)
    along the normal of the face to 6 units over it, the face marked on
    the second tick (`MarkFace`); a spot in thin air has no normal and no
    mark. `Hover` - it sways over the face for 4 to 7 ticks. `TakeOff` -
    it leaves from where it is, armed if it is a fighter. `Fly` - a
    spiral about the hero from the takeoff to the seat, the distance from
    him and the turn about him both eased (`EasedInOut`); the turn is 0.5
    to 0.9 of a half-lap, each orb its own, the middle wave against the
    others; the seat's depth and light come in with the flight. A flight
    takes 18 ticks and one more for every 9 units the orb was called
    from, but ends 16 ticks before its wave's term at the latest
    (`FlightOf`): the far ones fly faster and a wave arrives as a blow.
    `Land` - seated and unarmed; `KeepSeat` holds it in its seat by
    `MoveBeside` with the hero's whole step.
  - Only an orb in flight is armed. At the pause (`BeginHover`) whoever
    is still in flight sits where it is, and nobody is armed from there
    on.
  - Stand-ins: an orb struck down in flight (`osGone` at `roFlying`) is
    found before the flock's tick drops it (`ReplaceSpent`) and born anew
    from the same face 2 ticks later (`StandInFor`) - armed while the
    stock lasts (`StandIns`), unarmed after. One that would not sit
    before the pause is hurried (it leaves its face 10 ticks after its
    birth and lands as the pause begins) or, with the pause nearer than
    20 ticks, thickens at its seat in 8 ticks, unarmed (`roCondensing`,
    `Condense`). So the pattern has no holes.
  - A leap of the hero - a step over `LeapStep` 24, the return from a
    pit: an orb in flight begins its flight anew from where it is
    (`Rewind`), due when it was but no sooner than 6 ticks from now; the
    seated go with him.
  - The pattern's clock (`FFlow`, by `FlowStep`): a tick a tick through
    the gathering, quicker and quicker through the hover (toward 1.8),
    slowing to a stand over the last `FreezeTicks`, standing through the
    collapse. The flash of the freeze (`FlashAt`): a bell with its top 3
    ticks before the collapse, from 4 ticks before it to 8 after. `Shine`
    writes the size and the light an orb is drawn with: what its stage
    gives it, what its depth makes of that (size by 18% of the depth,
    light from 0.72 at the far side to 1 at the near one) and the flash
    (light up to 1.7 times, size up to 1.12); light does not pass 1, so
    the flash is carried by the dim orbs behind and by the size.
  - A seat that leaps (the vortex): `SeatLeapt` compares an orb's seat
    with where it stood a tick ago (`FFlowBefore`); farther than
    `SeatLeap` 24, and `Lead` calls `TOrb.Arrive` - the orb is there at
    once, with no trail under the hero's feet. For the flying, the seated
    and the condensing.
  - The collapse (`BeginCollapsing`): the body is asked once and every
    orb is given a point of it by the dice (`EntryIn`; no probe or no
    points - the chest, 2 units above the middle of the body). `Converge`
    - an orb waits its own time (up to 45% of the collapse), then goes in
    over 35% to 55% of it, winding to one side, shrinking to 0.35 of its
    size and brightening; one that has gone in stays on the body, its
    point standing rigidly from the hero's center whatever he does.
    `Finish` - on the rite's last tick all are released at once, with no
    dust; the stage is `rsIdle` and `reFinished` is told (the ceremony
    asks for the burst on it).
  - `Shed(score, center)` - the suit gives its orbs back: a rite going is
    dropped, the body is asked once, and `ShedOrbs` orbs are born at
    once, each at its own point of the body, armed from the first tick.
    `TickShed` leads them by `Shield`: 6 ticks (`ShedExitTicks`) out of
    the point to the orb's place in the ring, quickest at first (size
    from 0.5, light from 0.6), then in the ring - the aura's oval,
    half-axes 28 and 35, the orbs sharing it evenly by their numbers, a
    lap in 330 ticks (`RingSeat`) - in the hero's frame and in front of
    him (depth 0). No pattern, no waves, no stand-ins: a ring that has
    lost orbs stays gapped. Each orb implodes at its own tick -
    `ShedTicks` and up to `ShedSpread` more; with the flock empty the
    stage is `rsIdle`. A shed tells no events.
  - `Carry(stepX, stepY)` - a door: the births still waiting are born at
    once (`FlushBirths`); the flock (`Shift`), the hero's center, the
    spots of the waves (a stand-in's face crosses too) and the takeoffs
    move by the step, and nobody flies anywhere. An orb still on its face
    takes off at once: the face stays on the screen behind. `Collapse` -
    the hero's death: every orb implodes, a ring of a suit shed too, the
    births are dropped, the stage is `rsIdle`; `reFinished` never comes.
    `Clear`. `DrawBehind` / `DrawInFront` - the two layers of the flock
    (`TOrbFlock.DrawLayer`): the marks of the faces and the orbs behind
    the hero, the orbs in front of him and the dust.
- Tests: `Tests/Orbs/Tests.Orbs.Rite.pas`, with `Tests.Orbs.Harvest.pas`
  for the spots - see Tests below; the look of it all is for the eye.

### `Game/Orbs/Orbs.Burst.pas` (~915 lines)
The burst of the suit (3.0.61): the suit takes as much light as it holds,
and the rest goes out of the hero. The end of the ceremony in place of the
one tick the suit went on in, four beats: the inhale (two ticks: the world
stands, the hero does not; a veil goes over the screen and he is a bare
figure on it), the strike (24 rays out of his chest, a ring running out
over the room, a flash), the flight (the rays go through matter and off
the screen, leaving a mark where they go into a face), the echo (motes out
of the points of his body; the marks melt). The look and the time only:
what a ray strikes is settled through `Stretches`
(`Strike` in `Game.HeroOrbs`), and what the strike means - the suit on -
is the ceremony's (`Game.Henshin`). One burst for every form; a form lends
it its colors only. Its own `TXorShift` (seed `$42757273`), the numbers
constants at the top of `implementation`. The design, the numbers and the
record of the stage: `docs/mechanics/henshin.md`, the section on the burst and
stages 8-10.
- **`TBurstLook`** (record) - the colors a form lends: `Glow` (the haze,
  the glow, the halo), `Core` (the heart of a light ray, the body of a
  dark one), `Dark` (a black hole: the bodies are drawn over, not added,
  and the inhale is a negative - a light veil, a dark figure), `Flash`,
  `Veil` and `VeilLevel`, `Silhouette`, `Mote`. **`IceBurstLook`** - light
  on light; **`MoonBurstLook`** - the black hole, waiting for the moon form
  (`docs/mechanics/arena-3.md`); only the U debug key wears it yet.
- **`TBurstEvent`** = (`beNone`, `beStruck`). **`TBurstStretch`** - what a
  ray's head passed this tick, from and to. **`TBurstFigure`** - the
  hero's frame as a bare figure: the white mask (`TShroudPainter.MaskOf`),
  where the frame stands on the screen, whether it is turned.
- **`TOrbBurst`**:
  - `Create(body)` - the body probe of the rite (`TBodyProbe`), asked once
    a burst, at the strike. `Start(look, curl, center, matter)` - a burst
    already going is dropped (`Clear`); the inhale is `InhaleTicks` = 2.
    `curl` is a flag, not a pattern: the game passes `True` for the
    vortex, and the burst knows no pattern. `Tick(center)` - once a tick,
    with the hero's center where the tick has left it: through the inhale
    the center is followed, on its last tick comes the strike and the
    center is kept from there on - the rays neither lag behind the hero
    nor follow him. `DrainEvent` - `beStruck` once, waiting until it is
    asked; `Holding` / `Inhaling` - the inhale (the world stands; the hero
    is drawn as a figure). `Marks`, `Motes` - the two swarms, read-only,
    for the tests.
  - The strike: the rays go out of the chest (2 units over the middle of
    the body), one every 15 degrees, the first straight up, all alike - 20
    units a tick, a tail of up to 170 units along the head's way; the head
    walks in steps of 2 units. In a vortex each step turns the ray one way
    by `0.06 * step / 20 * exp(-flown / 220)` radians, so the curl dies
    off (about 35 degrees in all). A ray is gone once its head is 590
    units from the center (`RayReach`: its whole tail is off the screen).
    The ring (13 ticks) and the flash (4 ticks) start with the strike; 56
    motes leave the points of the body (the chest with no probe or no
    points), slow down by 0.93 a tick, sink, live 70 to 120 ticks.
  - Matter is touched for the marks only (`MatterAt`: a solid cell or a
    pad's body on the screen; off the screen there is none): where a
    head steps from the open into matter, a mark is left at its last open
    point - a particle that grows over 6 ticks to 18 units, shows in 4,
    melts linearly by tick 130.
  - Drawn as the lightning is (`Effects.Lightning`, `AppendLimb`): a ray
    and the ring are a band of `gsBeam` (the canvas' `BeamGlow`) laid
    along points by the private `AppendStrip` - a ray every 4 units from
    tail to head, width and strength by its profile (`k^0.7`, thinning by
    0.6 over the last fifth: no knot of light at the head), the head drawn
    on between ticks; the ring a closed oval of 96 points. Three passes a
    ray, haze to heart; a dark look draws its body with the band's texture
    switched to blending, then back. `DrawVeil(canvas, origin)` - under
    the hero, through the inhale: the veil over the frame, and for a light
    look a white glow about him (`gsPoint` 130 across, 0.35).
    `DrawSilhouette(canvas, figure)` - the figure in his place; a light
    look doubles it at the edges (red 1.5 units left, blue right, 0.7),
    then white over; a dark look has no fringe. `DrawWorld` - the marks,
    the rays, the ring, the motes, on the world channel. `DrawGlass` - the
    flash over the whole frame, blended, not added, unshaken.
- Tests: `Tests/Orbs/Tests.Orbs.Burst.pas` - see Tests below; the look is
  for the eye, and what the game does along a stretch waits for the scene
  tests.

### `Game/Orbs/Orbs.Feed.pas` (~275 lines, 3.0.70)
The orbs that carry a charge into its gauge. **`TOrbFeed`** owns a flock
(`Create(tint)`; the game's is `MoonOrbTint`) and a `TXorShift` of its own.
- `Start(amount, target)` - the charge is split among `FeedOrbs` 5 orbs at
  most (the remainder to the first); a feed under way goes on.
- `Tick(heroCenter)` - every tick, a feed or none. An orb comes out of the
  hero 15 ticks after the start and 9 after the one before, grows out of a
  point over 30 ticks to a spot over his head (an arc of 70% of a
  half-circle, 22-30 out, 4 higher), hangs there 60-85 ticks swaying and
  keeping to him (`MoveBeside`), then flies to the target in 40 ticks on a
  bowed curve, cubic, a little smaller, and is released into it.
- `TakeLanded` (the charge landed since the last call), `Pending` (on its
  way, the landed not yet taken among it), `Collapse` (the hero is dead:
  the orbs out implode, the charge with them), `Clear`, `Draw`, `Flock`.
  The orbs are not armed.
- Tests: `Tests.Orbs.Feed`.

### `Game/Game.Shroud.pas` (~980 lines)
The hero's shroud (3.0.47): smoke and light that gather round him when he
appears and when he changes his suit. A picture over the hero's frame that
lives on its own clock and dies out: bands of smoke and light cross the
body, the body may be put together out of strips, a halo flares round it and
motes drift off. It never takes the controls from the hero and knows nothing
of how he looks - sizes and shapes come from his 24 frames, so a redrawn hero
brings his own shroud. Since 3.0.50 the shroud also holds one light that is
no scene's: what the hero takes in (`Game.Uptake`) feeds it, it lights the
body and dies out by itself, whether a scene runs or not. The plan, the
numbers and the rules for whoever writes it: `docs/mechanics/hero-shroud.md` (the
project's storage, not the repository).
- **`TShroudLook`** (record, one per scene; ticks, screen units and shares):
  `Life`, `Bands`, `WidthFrom`/`WidthTo`, `Travel` (down the body over a
  band's life, up below zero), `Order` (`TShroudOrder` = `soTogether`,
  `soTopDown`, `soBottomUp`), `Stagger`, `Smoke`, `Light`, `Reveal` (the body
  is put together out of `ShroudStrips`=16 strips), `Shift`, `Flash` (the
  halo's peak, above 1 drawn twice) at `FlashAt`, `Motes`, `Lift` (a mote's
  pull, up below zero), `Tint`. What differs between the scenes is numbers
  only, typed constants in the unit: `PitLook` (back from a pit, 14 ticks),
  `EntryLook` (the first screen of a level, 40), `ReviveLook` (alive after a
  death, 24; the three are light smoke, `Tint` 236/240/255 - the body comes
  together), `IceOnLook` (the ice suit on, 130; frost runs down), `HeatOnLook`
  (110, sparks off a burning suit - nothing starts it yet), `IceOffLook` (the
  suit shatters, 18). The game says which one to start and when.
- **`THeroShroud`** counts and touches no SDL: the clock, the bands
  (`TShroudBand`: `At`, `Side`, `Puff`, `Wide`, `InFront`, `Fallen`), the
  strips, the motes (`TParticleSwarm`), the mist. Own `TXorShift` dice from
  the seed it is given, never `Random`. The probe (`TSolidProbe`, screen
  units) is the game's `SolidUnderPoint`. `Tick(pose, seeds)` runs, in this
  order: the fade of the fed light, the clock (age + 1, the end at `Life`),
  the mist, and while active
  the bands' fall and the birth of motes, then the flight and the settling of
  motes. Reads for the painter: `Time(alpha)`, `PartTime`, `Glow`,
  `StripShift`, `Look`, `Bands`, `Motes`, `Mist`, `Fed`, `FedTint`;
  `Active`; `Assembling`
  (the body is being put together: the game leaves him undrawn).
  - `Start(look)` begins a scene; it erases neither motes nor mist. `Clear`
    erases everything (death, a restart); `LeaveMotes` is a door - what has
    left the hero (the motes and the mist) stays behind, the light goes with
    him.
  - Motes are born at the opaque points of the frame (the seeds of
    `Render.Silhouette`: alpha from 128; mirrored with the hero) at a rate
    of `Motes` x the halo's level; a
    sinking mote (`Lift` above zero) is settled out of matter by the probe.
    A mote already in flight when a new `Start` comes takes the new look's
    `Lift` and is drawn in its `Tint` (open: docs/mechanics/hero-shroud.md).
  - Mist: a band that reaches the feet line (`HeroSize - 1`; only a look with
    `Travel` above zero gets there - `IceOnLook`) leaves the hero, is marked
    `Fallen` and is copied into `Mist` as a **`TShroudCloud`** (its look, the
    band, the age, the place `X`, `Y` - the middle of the band on its row).
    The mist stands on the screen, lives by its own look's clock (a new
    `Start` does not hurry it), and sinks `MistSink`=1.2 units a tick until
    the probe says "inside" matter; with no probe it stands.
  - The fed light (3.0.50): `Feed(tint, share, keep)` adds the share to
    the level, up to `FedCeiling` 1.3, and takes the tint and the keep of
    the last feed. Every `Tick`, before anything else and whether a scene
    runs or not, the level is multiplied by the keep; under `FedFloor`
    0.01 it is 0. `Clear` puts it out; `Start` and `LeaveMotes` do not
    touch it - through a door the light goes with the hero. A feed rolls
    no dice and starts no scene. `Fed` is the level, `FedTint` the tint.
- **`TShroudPainter`** draws, and makes at load what the drawing needs from the
  hero's 24 frames: a `TSilhouette` each (`BuildSilhouette` of
  `Render.Silhouette` at `HeroSize` - the seed points, a white mask with the
  frame's alpha, a halo and the margins it reaches past the frame; the
  making of them lived here until 3.0.50). `SeedsOf(frame)` hands the points
  out: the game gives them to the shroud, to the rite and (3.0.50) to the
  uptake. `MaskOf(frame)` (3.0.61) hands out a frame's white mask, nil for
  no frame: the burst draws the hero's bare figure with it. The mask adds
  by its make; whoever draws it otherwise puts its mode back.
  Three calls bracket the hero's draw: `DrawUnder` (behind him: the mist
  behind, the fed light - `DrawFedUnder` -, the far bands, the halo),
  `DrawBody` (on him: the fed light - `DrawFedBody` -, the strips while he
  is put together, the light on the body, through the mask), `DrawOver` (over
  him: the near bands, the mist before him, the motes). The fed light is
  drawn whenever its level is above zero, a scene or none, and the two
  lights add up, each in its own tint: under the body a `gsPoint` of 44
  units at the middle of the frame (0.3 of the level) and the frame's halo
  (the level, no higher than 1, one pass); on the body his own frame added
  on (0.45) and the white mask in the tint taken 0.35 toward white (0.6) -
  but not while he is put together: there is nothing whole to light. A band and a piece of
  mist share `DrawCloud`: smoke is `DrawPuffRect` of `Render.Puff` (alpha
  blended), light is `DrawGlowRect` over `gsPoint` of `Render.Glow` (additive).
  The painter restores the texture's alpha mod and blend mode after it
  paints with a hero texture. The hero's channel of the shake and the deck's
  lift go in as arguments; the mist takes the shake only, since it stands on
  the screen, and is drawn even after the shroud has ended.
- Tests: `Tests/Game/Tests.Game.Shroud.pas` - the counting class alone (the
  painter draws, so it is judged by eye): see Tests below.

### `Game/Game.Uptake.pas` (~1205 lines)
The hero takes a pickup in (3.0.50): the picture stays where it lay, fills
with color, crumbles, and the crumbs fly into his body, each one lighting
the point it enters. A pickup that is destroyed instead is filled and
crumbled the same way, but its crumbs fall and seek no one. The unit is the
picture alone: health and the weapon are the game's to give, in the tick of
the touch, and nothing here takes the controls from the hero. What differs
between a medkit, a weapon and a wreck is numbers only. The plan and the
model: `docs/mechanics/pickups.md` (the project's storage, not the repository).
- **`TUptakeLook`** (record, one per kind of scene; ticks, screen units and
  shares): `Fill` (the picture takes the color), `Crumble` (the crumbs
  leave, from the first to the last), `Order` (`TUptakeOrder` =
  `uoScattered`, `uoTopDown`, `uoNearFirst`), `Crumb` (the side of a
  crumb), `Flash` (the halo of the filled picture), `Apart` (the crumbs
  fall and seek no one), `Scatter` (a crumb's speed as it leaves), `Burst`
  (ticks it flies free before the pull), `Pull`, `Pulse` (half of the
  light the whole picture gives the body: the feeds of a scene sum to 2 x
  `Pulse`) and `PulseTicks` (the light is all but gone in this many),
  `Tint`. Typed constants in the unit: `MedkitUptake`
  (`Fill` 5, `Crumble` 6, `Crumb` 2, `Pulse` 0.65 over 14 ticks; green
  64/208/96), `WeaponUptake` (the same numbers, amber 255/178/56) and
  `PickupBurst` (`Apart`; `Fill` 2, `Crumble` 2, `Pulse` 0; pale
  236/240/255). All three leave `uoScattered`. The game says which one to
  start and when.
- **`TUptakeShape`** - a picture as the count sees it, since the count
  touches no SDL: `Alpha` row by row, `TexW` / `TexH`, `Width` / `Height`
  in units.
- **`CutCrumbs(shape, crumb)`** (a free function, no state): the cells of a
  grid of step `crumb` from the picture's top left corner that hold paint,
  in rows. A cell's texels run from `Round` of its left edge to `Round` of
  its right one, cut at the picture's edge, so no texel is lost or taken
  twice at a fractional step; a cell with no texels is skipped. A texel is
  painted from alpha 128 (`PaintedAlpha`); a cell covered by less than
  `MinCover` 0.12 is no crumb. A **`TCrumbCell`**: `Source` (texels), `X`,
  `Y`, `W`, `H` (units from the picture's corner, of the texel box),
  `MidX`, `MidY` (the middle of what is painted in it) and `Cover`. A
  picture of no texels or a step of zero or less gives no cells; an
  `Alpha` shorter than `TexW` x `TexH` raises `EUptakeError`.
- **`TUptake`** counts and touches no SDL: the scenes (**`TUptakeScene`**:
  the look by copy, `Picture` - the painter's number, only carried -,
  `Left` / `Top` - the picture's corner on the screen -, `Mirrored`, `Age`,
  `CenterX` / `CenterY` - the middle of all that is painted, each cell by
  the paint it holds -, `Crumbs`), the crumbs (**`TCrumb`**: its cell,
  `LeaveAt`, `State` = `csSitting` / `csFlying` / `csGone`, place and
  speed, `Age` and `Life` in flight, `Size`, `Seed` - its point on the
  hero's frame), the spots on the body (**`TBodySpot`**: `Seed`, `Age`,
  `Tint`, `Size`) and the `Clock`. Own `TXorShift` dice from the seed it is
  given (a zero seed becomes 1), never `Random`. `Create(solid, feed,
  seed)`: the probe is a `TSolidProbe` of `Effects.Sparks` (screen units;
  the game's `SolidUnderPoint`), the feed a **`TFeedLight`** (`reference to
  procedure(tint, share, keep)`; the game passes `FShroud.Feed`). Either
  may be nil: no probe - a falling crumb meets no floor, no feed - nobody
  is lit. Reads for the painter: `Scenes`, `Spots`, `Clock`.
  - `Start(look, picture, shape, left, top, mirrored, hero)`: cuts the
    shape by the look's `Crumb`; a picture with no painted cell starts no
    scene. A mirrored scene has its cells reflected about the picture's
    width. Every crumb gets its `LeaveAt` = `Fill` + queue x `Crumble` -
    the queue is a roll for `uoScattered`; for the other two, 0.8 of the
    crumb's place between the nearest and the farthest key (its height for
    `uoTopDown`, the distance from it to `hero`, the middle of the hero,
    for `uoNearFirst`) plus 0.2 of a roll - and its `Size` = `Crumb` x
    (0.7 + 0.6 x `Cover`).
  - `Tick(pose, seeds)` runs, in this order: the clock + 1; the spots age,
    and one that has reached `SpotTicks` (6, public) is dropped - a spot
    born in a tick is aged first in the next, so it is there for six; every
    scene steps (age + 1; a sitting crumb whose `LeaveAt` has come is
    launched and flies in that same tick; the flying fly); the scenes with
    every crumb `csGone` are dropped.
  - A crumb leaves (`Launch`) from the middle of its paint, at a rolled
    angle and a speed of `Scatter` x 0.4..1, lifted by 0.35 x `Scatter`
    and pushed away from the scene's center. In a scene that is not
    `Apart` it rolls its point of the frame the hero shows this tick
    (`PickSeed`: the die is thrown always, so the stream does not depend
    on how the hero looks; no points - the middle of the frame). In one
    that is `Apart` it gets a kick upward and a life of 20..41 ticks.
  - To the hero (`FlyHome`): for `Burst` ticks the crumb coasts, speed x
    0.86; then it goes for its point on the pose as it is this tick
    (mirrored with the hero). Within its own speed of the point, or
    within 3 units if it is slower, it is home: `Arrive` and `csGone`.
    Else speed x 0.78 plus `Pull` x (1 + ticks past the burst / 25) toward
    the point. There is no life: the pull grows until a hero who runs or
    leaps is caught.
  - `Arrive`: one feed for the crumb that came - the look's `Tint`, 2 x
    `Pulse` / the crumbs of the scene, a keep of exp(-3 / `PulseTicks`)
    (0 for `PulseTicks` of zero or less) - and a spot on its point. A look
    with `Pulse` 0 feeds all the same, a share of 0.
  - Apart (`FlyApart`): gravity 0.32, the speed along X x 0.97; a crumb
    that has gone into matter by the probe steps back along Y alone and
    bounces (speed Y x -0.3, X x 0.7); at its life it is `csGone`.
  - `Settle` (a door): every scene that is not `Apart` gives one feed for
    all that has not come home, sitting and flying - 2 x `Pulse` x left /
    all -, then every scene and every spot is erased, the wrecks among
    them. `Drop` (the hero is dead): a scene that is not `Apart` becomes
    one - its flying crumbs get a life of 20..41 ticks from the age they
    have, the sitting ones leave in their turn and fall -, a scene already
    `Apart` is left as it is; the spots are erased. `Clear` erases the
    scenes and the spots; it does not reset the `Clock`.
- **`TUptakePainter`** draws, and keeps what is made of the pickups'
  pictures: one picture to a sprite set, in a dictionary by the set's name
  in lower case - the `TUptakeShape`, the `TSilhouette`
  (`Render.Silhouette`, at `SpriteSize`), the frame's own texture and, when
  the set carries a sprite `light`, a glow texture of it and the middle of
  the cross (the middle of its alpha). `PictureOf(setName)` builds it on
  the first ask and answers the number `Start` takes: `sprites\<name>.mset`
  is opened, the first frame of `alive` read (`LoadImageSurface`, turned
  into ABGR8888); a frame wider than 64 px is dense art and gets the linear
  filter, any other - 64 px and under, the 2008 frames on black - gets the
  color key, as in the monsters' cache. A set with no frame in `alive` or a picture
  that cannot be read raises `EUptakeError`. `ShapeOf(picture)` hands the
  shape over. Three calls:
  - `DrawBehind(field, screen, origin, alpha)` - under the pickups: the
    halo of every scene in its `Tint` (`Flash` x the ease of age / `Fill`
    while it fills, then `Flash` x the share of crumbs still sitting; a
    level above 1 is drawn in two passes) and the halos of the weapons
    that lie.
  - `DrawLoot(canvas, field, screen, origin, alpha)` - over them: the light
    of the crosses, then the scenes. While a scene fills: the frame as
    painted and over it the mask in the `Tint` taken 0.2 toward white,
    rising to a solid silhouette. After `Fill` the frame is gone: only
    the sitting crumbs are drawn, pieces of that same mask, each
    `CrumbBleed` 0.15 units wider on every side - on a window scaled to
    fractions the seams between neighbors would show as hairs. The mask
    is a glow texture, additive by its make: for these two it is laid on
    by plain alpha and put back to additive before the call returns.
  - `DrawOver(canvas, pose, origin, lift, alpha)` - over the hero: the
    crumbs in flight (two `gsPoint` glows, a spot of 2 x `Size` in the
    `Tint` and a core of 0.8 x `Size` near white, carried between ticks by
    the speed; in a scene `Apart` both fade as (1 - age / life)^1.2) and
    the spots on his body (on the frame as he stands now, mirrored with
    him, `lift` added: 3.2 x `Size`, dying out over `SpotTicks`).
  - The light of a pickup that lies - of the screen, `mcPickup`, `mlAlive`
    - breathes on the uptake's `Clock`: its level x (0.45 + 0.55 x a sine
    wave of the period). A set with a `light` (the medkit): the `light`
    sprite added over the frame in `MedkitUptake.Tint` taken 0.25 toward
    white, and a `gsPoint` of 15 units at the middle of the cross; level
    0.60, period 50 ticks. A set without one (a weapon): the halo of its
    silhouette under the frame in `WeaponUptake.Tint`; level 0.55, period
    60. Both stand where the monster is drawn - `Round(X)`, `Round(Y)` -
    `SpriteSize`, the origin and the monster's `DeckLift(alpha)` - and
    turn over with it (`Mirrored`). A scene does not ride a deck: it
    stands on the screen where the pickup was.
- Tests: `Tests/Game/Tests.Game.Uptake.pas` - `CutCrumbs` and the counting
  class (the painter draws, so it is judged by eye): see Tests below.
- 3.0.64: `PictureOf(monster)` (was a set name) - the picture is built at
  the size the body is drawn (`PictureBox`; `BuildPicture(name, width,
  height)`, `ShapeOfSurface` likewise), so a wide pickup - the Duplet -
  is taken as it is seen.

### `Game/Game.Henshin.pas` (~335 lines)
The transformation ceremony as one automaton, lifted out of the dpr (3.0.2)
and rebuilt on orbs (3.0.49): the 3..2..1 prelude (2026), the rite of orbs
about the hero (`Orbs.Rite`), (3.0.61) the burst of the suit
(`Orbs.Burst`), the suit going on with its strike - and the suit coming
off.
The five rings of bullets closing in on the hero and the two fans of 2008
are gone. The ceremony has no clock of its own: the rite leads the orbs and
tells what has come to pass, the ceremony listens and does the game's side
of it. **`THenshin`** takes the
stage it acts on - **`THenshinStage`**, a record of the hero, the sound bank,
the message board, the shake meter, (3.0.47) the shroud, (3.0.49) the
rite and (3.0.61) the burst - and what it asks the game for -
**`THenshinCalls`**, a record of five callbacks (`reference to
procedure`; the game passes its own methods and those of its orbs
directly):
`Cure` (`TCureHero`: +1 health), `GrantMercy` (`TGrantMercy`: mercy for the
hero for a number of ticks), `BeginRite` (`TBeginRite`: the rite begins
about the hero - his orbs (`Game.HeroOrbs`) know his center, the matter of his screen and
the level's pattern), `ShedSuit` (`TShedSuit`: the suit's orbs come out
about him) and (3.0.61) `Burst` (`TBurstSuit`: the burst begins about him,
with his center, the matter of his screen and the curl of the level's
pattern). So the constructor stays at two parameters.
Reborn with the hero on every level load.
- `StartCountdown` (the boss path: prelude, then the ceremony), `Start`
  (straight in - the gravel trial: the big message, `evolution.wav` twice,
  `BeginRite`), `Tick` (once a logic tick, right after the rite's and the
  burst's own, even over the corpse: the prelude, `HearRite`, then
  `HearBurst`), `DrawCountdown(font,
  alpha)` (the growing, dissolving digit, topmost), `RemoveIceForm`, `Reset`
  (restart: the countdown, the burst asked for and the ice form die with
  the hero, the suit comes off silently; the rite and the burst are the
  game's to clear).
- `HearRite` drains the rite's events until `reNone`: `reWaveSeated` -
  `Cure` and the regen ticker (three times: the rite's ticks 56, 78 and
  100); `rePaused` - `GrantMercy` for `HoverTicks` + `CollapseTicks` of
  `IceRiteScore` + `InhaleTicks` of the burst, 56 ticks - to the strike
  (the rite's ticks 100 to 155); `reCollapsing` - the shroud starts
  `ChargeLook` (a private function: `IceOnLook` with no bands and no motes
  and its top at 0.9 of a life counted from `CollapseTicks` - the body
  fills with light as the orbs go in; the look tops out a tick past the
  collapse, and the burst's inhale covers the body with a bare figure
  until `IceOnLook` takes the light over at the strike); `reFinished`
  (3.0.61) - `FBursting` up and `Burst()`: the burst inhales. `reWaveCalled`
  has no listener yet: it and `reCollapsing` are where the sounds of the
  rite will go.
- `HearBurst` (3.0.61) drains the burst's events: `beStruck` with
  `FBursting` up - `Finish`. A burst the ceremony did not ask for (the L
  and U debug keys) puts no suit on.
- `Finish` - the strike: `FBursting` down, the perk ticker, three `Cure`
  (with the point of each wave that sat, the six of the 2008 ceremony),
  `hfIce`, the shroud's `IceOnLook`, `bottle.wav`, `FinishTrauma`, the big
  message. No fan. Since 3.0.61 all of it lands two ticks after the rite's
  end, on the rite's tick 156.
- `RemoveIceForm` (nothing if the hero is not wearing the suit): `hfNormal`,
  the shroud's `IceOffLook`, `ShedSuit` and `GrantMercy` for
  `IceRiteScore.ShedTicks` - 100 ticks, as long as the ring stands: the ring
  is up against what a dying boss throws in that very tick. No sound of its
  own.
- Owns its tuning: the regen and perk
  ticker lives, its one shake dose (`FinishTrauma`), the
  countdown tuning, and its sound names (`evolution.wav`, `countdown.wav`,
  `bottle.wav`) - loaded strictly in the
  constructor. The numbers of the rite are not here: `IceRiteScore` lives in
  `Orbs.Rite`, those of the burst in `Orbs.Burst`. `Reset` leaves the
  shroud as it is
  (`Game.Moon` clears it). `BottleSoundFile` is public: the barrel burst doubles as the
  bonus explosion and the pops of the boss's wreck, and `Game.Moon` reads the
  name from here.

### `Game/Game.Trial.pas` (~400 lines)
The rules of the gravel trial of level 2's screen 9 (3.0.53, reworked
into acts; `docs/mechanics/arena-2.md` holds the whole design): no monster field,
no hero and no SDL in it - a class a test drives alone
(`Tests.Game.Trial`). The trial runs in acts (`TrialActs` = 5): an act is
a batch of gravels let down a wave at a time (`TrialFirstWaveTicks` 25,
then `TrialWaveTicks` 18 - the pace of 2008), with no cap on the living -
the batch is the only limit. The next act does not come until every
gravel of the batch is dead: once the batch is spent the gate is watched
every tick (`WatchGate`), so the room rebuilds the moment the last one
dies; an aimed gravel still on its way holds it, the one let down this
very tick too. Then the room breathes (`TrialActBreakTicks` 40) and the
next batch falls; a room busy with a scene of its own (`RoomBusy`, the
game's word) holds the first wave of the next act back. The gate of the
last act ends the trial. Nothing carries over between acts. The first
gravel of every act is a herald; from act 2 (`TrialAimedFromAct`) every
third (`TrialAimedEvery`) is aimed: a mark over the hero's column, the
gravel `TrialAimedLeadTicks` (10) after it. A gravel fallen into the pit
comes back one at a time, a beat apart (`TrialPitReturnTicks` 10).
Medkits: one per `TrialKillsPerMedkit` (15) gravels killed, counted
across the acts, and (3.0.59) one more at the middle of every act - the
kill that makes half its batch, or half the wave (`PayMiddle`; an act of
one has no middle). An event may open the sky for its act (3.0.58,
`OpenSky`): a body falls every so many seconds until that act is over -
the trial keeps the pace, the game picks the body. The trial may end in a
wave (3.0.59): one act more, dealt by `DealWave` instead of
`DealGravel` - a count, not a batch, never more of it alive than its cap
(a body `TrialWaveTicks` apart while the room fills up, a dead one
replaced `TrialWaveRefillTicks` (33) after it is gone); only the wave's
own living count against the cap; no body of it is aimed, its first is a
herald. A 2026 addition.
- **`TTrialCue`** (record) - what the game carries out on a tick:
  `SpawnGravel`, `SpawnWave`, `Herald` (the gravel or body let down is
  the first of its act), `MarkAimed` / `SpawnAimed`, `ReturnFromPit`,
  `SpawnMedkit`, `SkyFall`, `ActEnded` (the gate opened, the last one
  too), `Finished`.
- **`TTrialProgress`** (record, 3.0.57) - `Act`, `Batch` (the wave's count
  in its act), `Dealt` (of the batch, an aimed one from its mark),
  `WaveKilled` (0 outside the act of the wave); all zero while the trial
  does not run. The events' gravelDealt and waveKilled read it.
- **`TGravelTrial`** (class) - `Start(batch, waveCount = 0, waveCap =
  0)` (both above 0 - a trial of `TrialActs + 1` acts, `Acts`), `Stop`,
  `NoteGravelKilled`, `NoteWaveKilled` (only in the act of the wave),
  `OpenSky(seconds)` (a tick at least; told again, the new pace from now;
  nothing outside the trial), `Tick(gateHolders, waveAlive = 0)` - the
  gate holders are everyone the game counts in (the gravels, the guests
  an event let in, the wave), `waveAlive` the wave's own living;
  `Progress`, `Active`, `Act` (1..`Acts`), `Acts`, `RoomBusy` (read and
  written by the game). The act's end shuts the sky, and nothing falls on
  the tick it shuts; `Start` and `Stop` shut it too.

### `Game/Game.Arrivals.pas` (~150 lines)
The violet light a body comes down in (3.0.53) - Selena's colour: where
the trial lets a gravel, a medkit, a sky barrel or a body of the wave
down from the sky, where a gravel that strayed out comes back, and over
the column of an aimed one. A mark is a column of light from the top edge
(`ArrivalBeamWidth` 14, `ArrivalBeamLength` 60) and a glow just inside
it (`ArrivalHeight` 14, `ArrivalSize` 44, a white core of
`ArrivalCoreShare`) on its own clock (`ArrivalTicks` 14): it gathers into
the point, peaks and dies out (`Sin(Pi * share)`). The herald's mark
(`alHerald`) is twice as long, broader and stands twice as long
(`ArrivalScales`). The look only - the body is the field's; a light of
its own, not the hero's shroud (decided). A 2026 addition.
- **`TArrivalLook`** = (`alPlain`, `alHerald`). **`TArrivals`** (class) -
  `Add(x, look)` (x - the middle of the body, screen units), `Tick`,
  `Draw(canvas, origin, alpha)` (through `DrawGlow` / `DrawGlowRect` of
  `Render.Glow`, on the monsters' channel), `Clear` (a door or a death:
  nothing follows the hero to the next screen).

### `Game/Game.Shield.pas` (~545 lines)
The shield of a TeK machine while it cannot be hit (3.0.56): a pale gold
honeycomb about it, always seen, on its rim alone - the machine inside
stays in plain view (asked after the first look: a full honeycomb hid the
gun). A hit lights the cells about its point, and the flare dies out in
about half a second; no sparks - sparks are the game's sign of a wound,
and a shield takes none. A shield that falls blinks its cells a few times
and goes out; it does not come back by itself. The cannons wear it first;
it is meant for the bosses after them while they may not be hit (unlike
the mast-turret machine's hull, which is invulnerable always). A 2026
addition.
- **`TShieldArt`** (class) - one hex cell texture in additive light
  (`FillCell`, `CellSide` 48 px), one for every shield of the game.
- **`TShieldState`** = (`sdUp`, `sdFalling`, `sdDown`).
- **`TTekShield`** (class) - `Create(radiusX, radiusY)`: an ellipse of
  pointy-topped cells (`HexSize` 3.4, `LayCells`) about the machine's
  middle, each with its `Rim` share (0 middle .. 1 edge). At rest only the
  cells past `RestRimFrom` (0.72) show, easing in to full at `RimFull`
  (0.95); a flare reaches in to `FlareRimFrom` (0.5); cells under
  `DimmestLevel` (0.01) are not drawn. `Rise`, `Fall` (blinks every
  `FallBlinkTicks` and is out in `FallTicks` 14), `Strike(point)` (a
  flare of `FlareTicks` 16 within `FlareReach` 9 units), `Holds(point)`,
  `TryEntry(from, to, out entry)` - where a stretch first comes into it,
  looked for every `EntryStep` unit; False outside it or when it is not
  up; `Tick`, `Draw(canvas, art, center, alpha)`, `State`. Points are
  from the machine's middle.
- 3.0.75: **a shield over a body** - `TShieldMask` (a grid of units row
  by row from the top-left corner, `Solid`, `Middle`, `At` - False off the
  grid) and `CreateOver(body)`: the body two units wider on every side but
  the floor (`Widen`, `BodyMargin`), its depth under the outline by a
  chamfer of two passes (`DepthsOf`; off the grid is open to the sides and
  above, solid below - no rim along the floor), the honeycomb kept over it
  with the rim share `1 - depth / RimDepth` (28 units - about a cannon's
  rim across) (`LayCellsOverBody`); `Holds` asks the grid. The cannons'
  ellipse is unchanged.

- 3.0.77: **a strip** - `CreateStrip(cells, scale)`: a short row of
  cells about the middle at `scale` of the full cell (`FScale`, also the
  size `Draw` gives them), every one of them rim (`LayStrip`), held as a
  box of the row's half-length and a cell's half-height. A plate that
  guards one side of a gun: the Ram's sweeper wears two under its
  barrels.
### `Game/Game.Cannons.pas` (~900 lines)
The two TeK cannons of the gravel arena (3.0.56, act 3): guns clamped to
the side faces of the wall pillars (cols 1-2 and 13-14, the muzzle two
cells out of the wall; variant B of the design) that do not aim. They
slide in from beyond both edges once (`ArrivalTicks` 30, smoothstep) and
ride the walls in unison, face to face, always on one row (`RideSpeed`
3); at a row they warn with a red fire at the muzzles (`WarnTicks` 20,
the game hums `padhum.wav`) and sweep it with a long burst from both
sides at once (`BurstTicks` 40, a round every `ShotEveryTicks` 2 from
each, barrels in turn, `RoundSpeed` 16, a streak 18x3), then rest
(`RestTicks` 22, the rounds reach the far shield) and ride to another
row of their orders. A row a volley sweeps is closed, the others free.
The shield of each (`TTekShield`, 38x22) takes the rounds of the other
and the hero's bullets; a round wounds the hero alone - a gravel is no
one's target. Touching a cannon wounds (the contact boxes - plate,
receiver, barrels - measured on the art, `ContactBoxes`), so its body is
no bunker. When a cannon is to ride through the rows a bank of shelves
stands in its way at (the `yield` of the orders - the bottom steps
s09-foot at rows 8-9), the bank goes into the wall first (`YieldTicks` 28,
the shelf's warning and slide) and comes out once the pair has left those
rows. A pair lives one act: when the trial moves past it, the shields
fall, rounds in flight go harmless, the barrels overheat (`HeatTicks`
100), the pair races up and down between rows 1 and 6 (`RaceSpeed` 8,
`RaceLegs` 5, `padhum` every `RaceHumTicks` 36), stops face to face at
row 2 over the pyramid (`HaltTicks` 16), duels point-blank (`DuelTicks`
50, harmless, sparks on the other muzzle) and both blow up: a scene, not
a death of hits, and nothing in it wounds. The rules and the look; the
game carries out the cue - the sounds, the wound, the shelves, the sparks
and the blast. A 2026 addition.
- **`TCannonSide`** = (`csLeft`, `csRight`); **`TCannonBlock`** =
  (`cbNone`, `cbShield`, `cbHull`) - what a hero's bullet ran into;
  **`TRoundCatch`** - `reference to function(fromX, toX, y): Boolean`: the
  game's word on a round's stretch of the tick (an orb took it -
  `THeroOrbs.TakesAt`, 3.0.57); **`TCannonCue`** (record) - `Hum`,
  `Shot` (one shot sound stands for a few rounds, `ShotSoundEveryTicks`
  4), `HeroHit`, `YieldSleep`, `YieldWake`, `Strikes` (rounds on bare
  steel in the scene: sparks, no wound), `Blast` and `BlastPoints`.
- **`TCannonArt`** (class) - the set `tek-cannon` (`bin/sprites`,
  `tools/cannon/build_cannon.py`): the hull and the heat (the barrels in
  alpha, added red as they overheat), through a cache of its own with
  soft edges and linear filtering (drawn at a size of its own), and the
  shield's `TShieldArt`. The art faces right and is mirrored for the
  right wall; measured points in units of it: muzzles 63.4, 14.07 /
  21.54, lens 32.16, 12.37.
- **`TCannonPhase`** = (`cpGone`, `cpArriving`, `cpYielding`,
  `cpRiding`, `cpWarning`, `cpFiring`, `cpResting`, `cpRacing`,
  `cpHalting`, `cpHolding`, `cpDueling`).
- **`TCannonPair`** (class) - `Create(art, seed)`; `Start(orders, act)` -
  both slide in for that act of the trial (an event fired after its act
  plays the scene at once); `Clear` (a door, a death: gone, no scene);
  `Tick(act, heroBody, catch)` - `act` the trial's now (0 when it does not
  run), `heroBody` empty for the dead, `catch` asked of every round that
  can wound before the hero is (its whole stretch of the tick, so a round
  does not jump an orb); `Block(from, to, out at)` - where a bullet's
  stretch runs into a cannon, the shield lighting up; `Touches(body, out
  side)` - nothing in the scene wounds; `DrawBodies(sprites, alpha)`,
  `DrawLight(canvas, origin, alpha)` (rounds, muzzles, lens, shields);
  `Active`, `Leaving` (the scene plays: the game's `RoomBusy`),
  `YieldBank`.

### `Game/Game.Ram.pas` (~2530 lines, 3.0.77)
TeK-R13, the Ram, of level 2's boss arena (`docs/mechanics/arena-3.md`,
stages 8b and 9): a hull on two wheels that faces left for good and
drives back and forth, a mast of three sections in a well on its roof
with a head on top - the hunter, then the sweeper -, an eye, brake lamps,
two smoking exhausts, the TeK shield over its body. It presses a hero
low on the road and hunts one on the pads; the hunter fires bursts and
its eye is the only target. A unit of the game as the cannons are, not a
monster. The game carries out the cue.
- **`TRamCue`** (record) - `Rumble` (the engine starts: the loop),
  `Hiss` (stopped: the loop cuts to the brake), `Whine` (the mast starts
  up), `Locked` (the head locked: the boss track), `Jolt` (trauma shares),
  `Shot`/`ShotFrom`/`ShotAngle` (the hunter fires), `Blast`/`BlastAt`
  (the head blows up).
- **`TRamPhase`** = (`rpAbsent`, `rpWaiting` - the music fades, the
  machine not on the screen yet, `rpDriving`, `rpBreathing` - at the
  entrance's mark, the eye dark, `rpRising`, `rpResting`, `rpRevving` -
  the rev before a press, `rpChanging` - the change of heads).
  **`TRamHead`** = (`rhNone`, `rhHunter`, `rhSweeper`); **`TRamFire`** =
  (`rfIdle`, `rfFlare` - the lens burns red, `rfBurst`); **`TRamTarget`**
  (record: `Alive`, `Body`, `OnDeck`) - the hero as the machine sees him.
  `HunterLives` 100, `HunterBulletSpeed` 6.
- **`TRam`** - `Create(body, seed)` (the body - `TRamArt.Body` - and the
  shield `CreateOver` it); `Start(orders)` - True for the whole entrance
  (the first on the level, `FEntered`): `rpWaiting` for the fade-out
  seconds and `SilenceBeatTicks` 16, then the drive from `EnterFromX`
  (40 beyond the right edge) already at `EnterSpeed` 2.8 to the stop;
  False after that: placed at the stop, `rpBreathing`. `Clear` (a door, a
  death), `Reset` (a new level: the entrance not seen). `Tick` - the
  phase, the sway, the lamps, the eye, the lens, the shield. The drive (`TickDrive`): up to
  speed and down by `Brake` 0.2 a tick, the brake beginning where the way
  left is what the speed needs to die out, never below `CreepSpeed`, the
  arrival on the mark exactly (`Arrive`: the hiss, the lamps held
  `LampHoldTicks`, a jolt - `EntranceStopJolt` 0.25 or `PatrolStopJolt`
  0.12; the entrance breathes `BreathTicks` 16, a leg rests 50-100
  ticks). The breath over, the eye lights and the mast rises over
  `RiseTicks` 50 (smoothstep) from `MastRest` -20 to `HunterMast` 48:
  `Locked` (the head armed), a rest of `LockRestTicks` 33, then the legs
  (`BeginPatrolLeg`: one in three, `WallLegShare`, to the far wall - no
  floor by a wall is safe; else a mark anywhere between the walls,
  `PatrolMinLeg` 48 at least; at `PatrolSpeed` 1.4; its own `TXorShift`).
  The eye (`TickEye`): dark until lit; while a head rises it blinks -
  the warning, `EyeBlinkTicks` 3 a half, 1 against `EyeBlinkLow` 0.1;
  otherwise it breathes between `EyeBreathLow` 0.3 and `EyeBreathHigh`
  0.55 over `EyeBreathTicks` 83. The lens (`TickLens`): dark until the
  head locks, then a wink of `LensWinkTicks` 4 every `LensPeriodTicks` 33
  over an ember of `LensEmber` 0.15. The sway
  (`TickSway`): a spring toward a slow sway of its own (`IdleSway` 0.6
  degrees over `IdleSwayTicks` 150) that the change of the speed kicks
  (`SwayInertia`), held to `SwayMax` 8. `Block(from, to, at)` - a bullet's
  stretch against the shield, which flares there. `Contact(body, onDeck,
  inAir, away)` - the hero's body against the body (`Overlaps`); a hero on
  a deck is in front of it (`FHeroInFront`) and stays so in the air while
  over it; a hero it threw is out of its way until he lands
  (`FHeroThrown`); `away` (`ThrowSide`) - the side away from its middle,
  0 - straight up - when that side leaves less room to the screen's edge
  than his body's width (`SpanAcross`: the body's columns on his rows), so
  a hero pinned at a wall goes up toward the low pad there. `Present`
  (seen and touched: not absent, not waiting), `LeftAt`, `MastAt`,
  `SwayAt`, `LampsAt`, `EyeAt`, `LensAt` (between two ticks), `Rolled`,
  `Body`, `Shield`, `Phase`, `EyeLit`, `Eye`, `Lens`, `Arrivals` (counts
  the starts), `Mast`, `Left`, `Track`. `RamWidth` 169, `RamHeight` 128,
  `RamFloorY` 352 (the road), `RamTop`.
  **The fight (stage 9).** `Start(orders, livesShare)` arms the hunter
  (`Arm`: `HunterLives` times the share, facing left, the gun quiet) on
  every start. `Tick(target)` - the hero seen (`SeeHero`: his centre and
  pace), the mode (`TickMode`: feet under `LowLine` 288 and off a pad for
  `PressAfterTicks` 10 - `FPressing`; let go after `LeaveOnDeckTicks` 6
  on a pad or `LeaveAboveTicks` 33 above the line; `PressNow` cuts a rest,
  speeds a leg toward him or brakes one away, `StopAhead`), the phase,
  the sway, the aim, the fire; `Tick` with no hero - the old roam.
  `BeginLeg`: no hero - `BeginPatrolLeg`; pressing - `BeginRev`
  (`rpRevving` `RevTicks` 8) and then to `PressWall` at `PressSpeeds`
  (1.9, 1.9, 2.1 by the third), resting `PressRestTicks` 13; else
  `BeginHuntLeg` (32-96 units at `HuntSpeed` 1.1 where `InSightsFrom`
  holds, else the farthest from him; rests 15-40, at most 5 out of his
  sights). `TickAim`: the barrel's angle `FAim` (before the sway, degrees
  counter-clockwise) toward him within `AimWithin` (straight up to
  `AimBelow` 25 under level on its side) at `TrackRate` 3; past the
  vertical by `TurnPast` 15 for `TurnHoldTicks` 10 the head turns over
  `TurnTicks` 10 (`TurnSquash`, mirrored at the middle), never in a burst;
  in a burst the barrel keeps on the point it took (`FFrozenAt`) or, the
  hose, follows at `HoseRate` 2. `TickFire` by `FirePatterns` (`Tier` - the
  third of its lives): rest, `rfFlare` (20/16/14 ticks; the lead of the
  second third, at most `LeadMax` 80), `rfBurst` (3/3/6 shots, `Shoot`:
  from the muzzle 30.7 along the barrel), rest (50/40/45); `CanShoot` -
  a hunter up, a hero alive, no turn, a fight phase; a press starts no
  burst and puts out a flare. `StrikeEye(from, to, at)` - a stretch
  against a circle of `EyeRadius` 5 about `LensPoint`: a life, a white
  flash of `HurtFlashTicks` 4; the last one sets `FHeadKilled`, and the
  next tick `KillHead` gives the `Blast` and stands the machine (braking
  first, `FChangePending`) for `BeginChange`/`TickChange`: the mast sinks
  `SinkTicks` 25, `EmptyTicks` 5, the sweeper rises `ChangeRiseTicks` 30
  to `SweeperMast` 48 with the whine. The eye blinks through `rpRising`
  and `rpChanging`; the lens (`TickLens`) burns red (`LensHot`) through a
  flare and a burst, flashes when struck, otherwise winks. `AimAt`,
  `TurnSquash`, `Wounded` (a hunter at its last third), `Hurt`, `Head`,
  `Facing`, `Lives`, `FullLives`, `Pressing`, `Fire`, `LensHot`. The
  geometry of a head is one function for the rules and the painter:
  `HeadPoint(left, mast, sway, head, facing, squash, x, y)` over
  `HeadShapes` (hunter 27.7 by 18.8, socket 16.6, 18.7; sweeper 42.1 by
  18.7, socket 29.2, 18.7), with `Turned`, `MastPivot`, `Bearing`,
  `Heading`. The row of lives: `Row` (`TRamRow`: `Shown`, `Lit`, `Share`,
  `HitTicks`, `Fade`) - from the lock `TickRow` lights a cell of
  `HeadRowCells` 12 every `RowBootTicks` 30 / 12 ticks (the cue
  `RowCell`), the lens burning white meanwhile; the first burst comes
  after; a dead head's row fades over `RowFadeTicks` 20. `HeadTopAt` -
  the middle of the top of the head, for the row.
- **`TRamArt`** - the set `tek-machine` through a cache of its own (no
  color key, linear): `well`, `mast1`..`mast3`, `hunter`,
  `hunterBarrel`, `sweeper`; a `THullArt` for the hull, its worn copy, the chassis and
  the wheel (`RamHullDef`: eye 22.2, 54.8, axles 61.1 and 133.2 at 107.5,
  radius 20.5); the shield's `TShieldArt`; a point glow for the lamps,
  the eye and the lens. `Body` - read
  off the art at load (`ReadBody`): a unit solid where `hull` or `chassis`
  is half opaque at its middle, or inside a wheel.
- **`TRamPainter`** - `Create(art, ram)` (a `THull` of its own, dozing for
  good - its eye is the Ram's, drawn here; two `TSmoke` of `ExhaustSmoke`,
  a body smoke as the monsters' are: a jet from the pipes' mouths at x
  167.3, y 14.9 and 28.5, angle 8, no lift, puffs at 4 a second as the
  rumble throbs); `Tick` after the Ram's (the wheels roll by `Rolled`; the
  exhausts at `ExhaustIdle` 0.3, full while it drives, `ExhaustRampTicks`
  8 between, rewound when `Arrivals` changes); `DrawSmoke(canvas, origin,
  alpha)` - the exhausts, before the body, so the machine backs into its
  own cloud; `DrawBody(sprites, alpha)` - the well, the
  hull's `DrawUnder`, the mast clipped above `MastHiddenBelow` 90 of the
  hull (lower, it would show through the open front arch), the hull's
  `DrawBody`, the eye (`DrawEye`, its size growing with the square of its
  level), the mast again clipped above the well line with the lens on the
  head (`DrawLens`, turned with the sway; pale - red is the machine's
  warning), the brake lamps;
  `DrawMast` - the sections narrowest first, each top raised by its share
  of the rise, the head's socket on the top collar, the barrel on its
  sleeve, all turned with the sway about the middle of the well (`Turned`);
  `DrawLight(canvas, origin, alpha)` - the shield. Stage 9: `DrawMast`
  ends in `DrawHead` - the head by `HeadPoint`, its width squashed in a
  turn and mirrored facing right, and the hunter's barrel from the sleeve
  along `AimAt` (turned 180 less the angle, or less the angle mirrored);
  `DrawLens` - pale and winking, red and up to `LensHotSize` 10 while it
  burns, `LensHurtSize` 9 when struck; a third `TSmoke`, `HeadSmokeLook`,
  from the head of a wounded hunter and from the top of an empty mast
  (`TickHeadSmoke`, drawn with the exhausts); the exhausts full in a rev
  too.

- 3.0.77, **the sweeper** (stage 10a). `LockSweeper` at the end of the
  change: `SweeperLives` 140 times the grade's share (`FLivesShare`), the
  row from 0, the first sweep after `FirstBurstTicks`. `TickRide` (from
  `TickAim` for the sweeper): the turn to a hero past the socket by
  `SweeperTurnPast` 8; the row `FRowY` - the hero's idle, the lowest while
  pressing (the closed ceiling), a ladder's through a burst at
  `LadderRate` 1.3 - between `SweeperRowY(SweeperMastHighest` 96) and
  `SweeperRowY(SweeperMastLowest` 12); the mast after it at `RideRate`
  1.5 (`SweeperMastFor`). `TickSweep` (from `TickFire`) by
  `SweepPatterns`: on the row within `RowSlack` 4 with the hero in front,
  `BeginSweep` - the barrels burn (`TickHeat`, `HeatAt`; the countdown
  waits for the row) - then `ShootBarrel` out of `MuzzleYs` in turn, level,
  `ShotSpeed` = `SweeperBulletSpeed` 5; the fork (`ForkRow`, `ForkStep`
  32, `ForkHeatTicks` 10) and the ladder (`FLadderWay` toward more room).
  `StrikeBarrels(from, to, at, guarded)`: the stretch in head units
  (`ToHead`), walked by `StrikeStep` 0.5 against the pack (`BarrelsLeft`..
  `BarrelsRight`, `BarrelsTop`..`BarrelsBottom`) and the room under it to
  `PlateBottom`; under it, or climbing past `PlateCover` 6 degrees -
  guarded, the nearer `Plate` flares (`PlateMiddles`, strips of
  `PlateCells` 2 at `PlateScale` 0.6); else a life and `Hurt`. Not hit
  squashed under `ThinHeadSquash`. `BarrelsPoint`, `Booting` (the row
  still coming up). `FKilled`: after the sweeper the mast sinks and stays
  down. `TRamPainter.DrawHeat`: `sweeperHeat` over the head, `HeatRed`
  by its heat, `HeatWhite` while booting or struck; `DrawLight` draws the
  plates under the head. `CanShoot` and `Row` take any head now; the
  hunter's `Shoot` sets `ShotSpeed` too.
### `Game/Game.Press.pas` (~205 lines)
The press of the gravel trial's finale (3.0.59, stage 6.2): its rules,
with no pads, no monsters and no SDL - a class a test drives alone
(`Tests.Game.Press`). The press is a stack of rows of shelves, top first
(the balconies at the walls, rows 3, 5, 7 and 9 of screen 9; the betoners
stand on them). The rows that are out ride down together like a conveyor:
on every beat each row out goes into the wall and the row under it comes
out, so whoever stood on a row falls one row lower; the bottom row going
in drops its bodies onto the floor; a row whose body is dead rides on all
the same. A newcomer comes down onto the top row: its arrival brings the
top row out and holds the beat `PressArrivalTicks` (45) - the top row
does not go from under a body still in the air. Two rows out one over
the other (not in the first design): the lower goes in with the beat to
drop its own body and comes out again `PressRewakeTicks` (40) later, to
catch the body of the row over it, which falls a row only. The press
counts which rows are out and which are told to move; the game tells the
shelves. A 2026 addition.
- **`TPressCall`** (record) - `Sleep`, `Wake` (banks), `IsEmpty`.
- **`TPress`** (class) - `Start(rows, beatTicks)` (every row starts in;
  nothing for no rows or a beat below a tick), `Shut` (stops where it
  stands, no rows told), `Arrive(bank)` (nothing for another bank than
  the top row), `Tick`, `RowOut(bank)`, `Active`, `Rows`.
  **`PressBeatTicks(seconds)`** - the level file's seconds in ticks, a
  tick at least.

### `Game/Events/Events.Director.pas` (~340 lines)
Runs the level's events (`Levels.Events`) against the live game.
**`TEventDirector`** takes the events, the message board, the level's
dynamic objects and the cues (3.0.54: one record, **`TDirectorCues`**, in
place of the two callbacks): `ChangeMusic` (the game's method, which also
remembers the track for restarts), `Arena` (`TArenaCues`: `Engage`,
`Restore` of `TPadArena` and, since 3.0.54, `FlyIn` - the game's
`FlyInParked`), `Shelves` (`TShelfCue` - a shelf action whole),
`BreakCarousel` (`TBreakCue`), `Strays` / `StraysLeave` (`TFlockCue`),
`MedkitsOnto` / `WaveOnto` (`TBankCue`), `TrialAct` (`TTrialAct` - the
trial's act, 0 while it does not run), `TrialDone` (`TTrialDone`),
`TrialProgress` (`TTrialProgressCue` - a `TTrialProgress` of
`Game.Trial`), `Cannons` (`TCannonsCue`), `Spawn` (`TSpawnCue`),
`SkyFall` (`TSkyFallCue`), `Press` (`TPressCue`); the last four take the
act the event waits for, 0 for one that waits for none; `StartScene`
(`TSceneStart`, 3.0.62 - the scene director's `Start`); `VictoryLeft`
(`TVictoryLeft`, 3.0.63 - the seconds the trial's victory track has left,
0 once over, below 0 while there is none), `GoRight` (`TGoRightCue`),
`OpenDoor` (`TOpenDoorCue`, 3.0.66), `HeroStands` (`THeroStandsCue`,
3.0.67 - the cell from 0; the game's `HeroStandsIn`), `Energy`
(`TEnergyCue`, 3.0.70 - `THeroOrbs.FeedEnergy`), `Respawn`
(`TRespawnCue`, 3.0.71 - the cell from 1; the game's `MoveCheckpoint`).
`TChangeMusic`
takes the fade seconds too (3.0.63), and the fade-out seconds (3.0.74). The director
pulls the trial's state through these, it does not push. The monster
field is reborn on every restart, so it arrives with every tick instead
of being kept: asked for the conditions, told the tactics.
- `Tick(screen, field)` - once per logic tick with the hero's screen: for
  every unfired event of that screen, the condition is checked
  (`ConditionHolds`: actReached - `TrialAct() >= act`; gravelDealt -
  `GravelDealt`, `Dealt >= batch * part div of + 1`; waveKilled -
  `WaveKilled`, `WaveKilled >= batch * part div of`; both true once the
  act is past; trialDone - `TrialDone()`; victoryEnds - `VictoryLeft()`
  from 0 to lead; heroStands - `HeroStands(x - 1, y - 1)`); while it holds the delay
  counts down, a lapse starts the count over; at zero the actions play
  once (`Play`: `ShowBig`, `AddTicker`, a hint through `PlayHint` -
  `StartTerminal` with the event's header or the channel's own and its
  place -, the music cue, `FadeTagged` / `TurnSunTagged` on the dynamics,
  `SetTaggedTactics` on the field, and every other action through its
  cue). The game skips the tick over the hero's corpse.
- `ReArm(screen)` - death re-enters the screen with its monsters reborn,
  so its events wait for their moment again, as the entity triggers do,
  and the dynamic objects their intensity actions turned are rewound
  (`RewindTargets` -> `RewindTagged`) - the boss stops smoking again.
- Reborn with the level (`LoadLevel`), like the ceremony and the HUD.
- 3.0.75: the cue `Ram` (`TRamStartCue`, the orders of the `ram`
  action; the game's `StartRam`).

### `Game/Scenes/Scenes.Director.pas` (~650 lines)
Plays the level's scenes (`Levels.Scenes`) against the live game, one at
a time, cue by cue on its timeline (3.0.62). **`TSceneDirector`** takes
the scenes, the level's dynamic objects, the pads, the sound bank and
the message board - all the level's, outliving it. The monster field is
reborn on every restart, so it comes with every tick in a
**`TSceneStage`** (record: `Hero` - his middle in screen units -,
`Field`, `Bullets` - the monsters' burst), as the event director's does.
- `Start(id)` - the scene begins (its id in any case, as the load finds
  it), unless it has played (`FPlayed`): `Open` - the clock to 0, every
  cue `NotPlayed` -, then the shade and the rumble to 0, the music to
  full. With one under way it waits in `FNext` (3.0.69).
- **`TakeOver`** (3.0.69) - the first thing of a tick with `FNext`: the
  scene under way lands every cue of its own things but the music, the
  shade and the shake (`CarriedCues`) at once, its world is put as its
  aftermath says (`Settle`), and the waiting one is `Open`ed - the held
  sounds stay held, the music, the shade and the rumble go on from where
  they are.
- `Tick(screen, stage)` - the hero off the scene's screen: `Finish`.
  Else `PlayDue` - every cue not yet played whose tick has come (`Due`:
  from its `At`, or from the tick the cue it counts from played plus its
  `Delay`; a wait only when its condition `Holds` - `DeckEmpty`: no body
  `mlAlive` with the pad as its `DeckUnderFeet`; a corpse rides along,
  and so does the hero) plays in the order of the plan, so a chain with
  no delay plays out on one tick (`FPlayedAt` - the tick each played);
  `FollowMarks` tells every part and beam it follows where its mark is;
  the shade, the rumble and the music step (`TValueFade`) and the bank
  gets the music's level. **Over** once every cue has played and run its
  ticks: the held sounds play out their tails on their own.
- `Play(cue, atOnce, screen, stage)` - sound (`PlayHeld`, kept in
  `FHeld`), music, shade, shake (`HeadFor` the level over the ticks),
  move (`MoveCrafts` - `MoveX` / `MoveY` of every craft of the tag),
  track and aim (`Pursue` keeps the cue, a later one for the same parts
  or beam replacing it, `none` ending it - `Unwatch`; `MarkOf`: the hero,
  the middle of the `HitBox` of the first body of the tag, dead or alive,
  or the point; `Tell` - `TCraft.Watch`, `TBeam.Follow`,
  `TLightning.PointAt`; an aim `AimAt`s the beam over its ticks),
  intensity (`FadeTagged`), hint (`StartTerminal` with the header and
  the place), hold, kill (`SmiteTagged` - nobody is paid), release,
  remove (the field's tagged hands), spawn (`Spawn`: a body the tag
  already names is not born twice - alive, it is stood where the cue
  says; dead, it lies where it fell; none - `SpawnStanding`; then
  `Dormant` as `asleep` says; a seat is the middle of the pad's deck),
  wake (`TPad.Wake`), fly (`TPad.FlyTo`). At once (`atOnce`): the ticks 0,
  no sound, no line.
- **`Finish`** - the hero left in the middle: every cue of the scene's
  own things plays at once, in order (a later one overrides an earlier
  one as it would have), then the world is put as its aftermath says
  (`Settle`) - replayed at once, the pad would leave before the tank got
  off it; the held sounds stop, the music stays where it was.
- **`ReArm(screen, stage)`** - a death: a scene waiting to take over is
  dropped; a scene under way on another screen is finished; the one under
  way, and every scene once a life of the death's screen, is rewound (`Rewind`: its held sounds stop, what
  its move, track, aim and intensity cues set going goes back to the
  level file - `RewindTagged` -, the shade and the rumble to 0, the music
  to full, and it waits for its event again); then, every rewind done
  (3.0.69), every scene once a level that has played puts its
  aftermath, whatever the screen, over the monsters reborn and the pads
  rewound.
- `Pause` / `Resume` - the menu: the held sounds wait with the timeline,
  the music under the menu at full volume. `Trauma` - what the rumble
  adds to the screen's shake a tick (`RumbleTraumaPerTick` 0.05 at the
  full). `DrawShade(renderer)` - the shade, black over the whole frame.
- Reborn with the level (`LoadLevel`); the destructor stops what it holds
  and, with a scene under way, gives the music back its volume.
- 3.0.67: the cue jolt adds to `FJolt`, **`TakeJolt`** hands it to the
  game once a tick (`FShake.AddTrauma`), and it is gone; pace -
  `PaceTagged` on the dynamics (rewound as intensity is); a fly with an
  ease - `TPad.FlyEased`.

### `Core/Render.Glow.pas` (~345 lines)
Light drawn instead of loaded: white textures with the shape in their alpha,
additive, linear-filtered, so one texture serves every tint and level.
- **`TGlowShape`** = (`gsPoint`, `gsFlare`, `gsStarburst`, `gsStreak`,
  `gsBeam`, `gsDisc` (3.0.70: a disc with a crisp edge, `DiscEdge` 0.06 of
  the half-side)) - a
  Gaussian point, a four-spike flare, the long thin cross of a starburst
  (rays thinner than a flare spike and slower to fade) and the streak of a
  spark (it lies along X: full at the hot end by the right edge, rounded
  off over `StreakCapShare`, the tail thinning out to the left by
  `StreakTailPower`), analytic (`PointSigma`, `Flare*`, `StarburstRayWidth`,
  `Streak*` metrics in half-sides).
- Free functions: `CreateGlowShape(renderer, shape, side)`,
  `CreateShadeShape(renderer, shape, side)` (3.0.70: the same blended, not
  added - drawn black, a hole),
  `CreateGlowTexture(renderer, surface)` (a shape computed elsewhere - the
  logo halo - arrives as a surface and leaves with the same settings),
  `DrawGlow(renderer, texture, cx, cy, size, tint, level)` (centered
  square), `DrawGlowRect(..., dest, tint, level)`. Tint = color mod, level =
  alpha mod.
- A glow out of an image of levels (lifted out of `Menu.Logo` at 3.0.47,
  since the shroud's halos are made the same way): `BlurImage(image, w, h,
  radius, passes)` - box blurs on an array of `Single`, the outside counts
  as dark, three passes make a near-Gaussian bloom; `CreateGlowFromImage(
  renderer, image, w, h)` - the levels scaled to a peak of one, white with
  the levels in alpha, through `CreateGlowTexture`.
- Users: the stars, the embers, the logo halo, the beacons, the heat of a
  smoke puff, the explosion flash, the sparks (`gsStreak`; the blast's with
  `gsPoint`) and hot shards, the flash of a hit and of an arc, the sensor
  eye of the boss's disc, the masks and the halos of `Render.Silhouette`
  (the hero's shroud, the pickups), the light of the shroud, and of
  `Game.Uptake` the cross of a medkit, the crumbs and the spots.
  `EGlowError`.

### `Core/Render.Silhouette.pas` (~185 lines)
What is made of the alpha of a picture: the points that lie in its body, a
white mask in its shape and a blurred halo round it. Lifted out of
`Game.Shroud` for 3.0.50, since the pickups are lit by the same art.
Nothing here knows what the picture is: the caller says how large it is
drawn, in screen units, and the points come back in those units, from the
picture's corner as painted.
- **`TSeedList`** = `TArray<TSdlFPoint>` - the opaque points of a picture.
- **`TSilhouette`** (record): `Seeds`, `Mask` (white, with the picture's
  alpha), `Halo` (the alpha blurred), `HaloMarginX` / `HaloMarginY` (the
  units the halo reaches past the picture), `TexW` / `TexH` (the texels of
  the picture). The mask and the halo are glow textures of `Render.Glow`:
  additive by their make, so whoever lays one on by plain alpha puts the
  blend mode back.
- `BuildSilhouette(renderer, surface, width, height)` - the surface is
  ABGR8888, the size is the picture's on the screen, in units. Under one
  lock of the surface: the seeds (a point at the middle of every texel
  with alpha from `SeedAlpha` 128), the mask (through `CreateGlowTexture`)
  and the halo - the alpha gathered into cells (a picture wider than
  `HaloMaxCells` 64 is shrunk by a whole factor first), set in an apron,
  blurred by `BlurImage` in `HaloPasses` 3 passes of a radius of
  `HaloReach` 2.5 units (no less than one cell) and made a glow by
  `CreateGlowFromImage`; the margins are the apron in units. A halo that
  fails frees the mask before the error goes on. `ESilhouetteError` - the
  mask's surface could not be made.
- `FreeSilhouette(var silhouette)` destroys the two textures and empties
  the record.
- Users: `TShroudPainter` (the hero's frames, at `HeroSize`) and
  `TUptakePainter` (the first `alive` frame of a pickup's set, at
  `SpriteSize`).

### `Menu/Menu.Starfield.pas` (~250 lines)
The stars of the menu sky, generated, not loaded. **`TStarfield`** of
`TStar` records.
- Three depth layers (`StarLayers`: density per 10000 square units, speed
  rightward, size and brightness spans, flare share, **`ZoomShare`** - the
  share of a frame zoom the layer answers with: 0.4 / 0.7 / 1.0). Star count
  = density x frame area, so a wide frame gets more stars, not stretched
  ones. Tints by temperature (`StarTints`, weighted toward white), twinkle
  on 35% (`TTwinkle`: phase, step, depth). Own `TXorShift` stream, seed
  "Moon" - the same sky on every run, the trailer relies on it.
- `Tick` (crawl + wrap fully off-screen), `Draw(alpha, zoom)` - interpolated
  with the timestep alpha; zoom > 1 spreads the stars from the frame center
  by each star's share (the submenu dolly). Textures: an 8 px point and a
  48 px flare from `Render.Glow`.

### `Core/Render.Globe.pas` (~650 lines)
A body of the sky as a lit sphere on the CPU. **`TGlobe`** takes a sprite
set, a map name (equirectangular, a power-of-two width twice its height),
an optional night map of the same size and a **`TGlobeLook`** (texture side,
surface - **`TGlobeSurface`** = (`gsRegolith`, `gsMatte`); the `gs` prefix is
shared with `TGlowShape` and `TGameState` of `Game.Moon` - axis roll and tip, night
ambient, tint, exposure, regolith limb
fade, atmosphere 0..1, air color, night gain; the ambient, the tint and the
air color are `TGlobeChannels` - red, green, blue).
- Startup: `LoadMap` -> `BuildPyramid` (`HalveLevel` three times: the limb
  samples a coarser level instead of skipping texels; a level is a
  `TMapLevel`) -> `BuildTables`
  (`PlaceTexel`: every texel of the disc gets its map row, longitude as a
  32-bit turn, detail level and coverage (a `TGlobePixel`) and a
  `TGlobeNormal` - normal, limb
  weight, air depth; a `TRowSpan` keeps the columns of a texture row that
  the table covers; with air the disc shrinks to leave room for a halo of
  `AirHaloShare` radii, whose texels are `AirOnly`) -> `BuildCurves` (gain
  and tone tables, a soft `ToneKnee`). The globe is dark until lit.
- `LightFrom(x, y, z)` - the sun in view space: every texel gets its
  shade (`gsRegolith` - Lommel-Seeliger, bright to the limb, the Moon;
  `gsMatte` - Lambert, the Earth), its night weight (the night map shows
  from `NightOnset` past the terminator), and with air its haze (a veil on
  the day side thickening at the limb, reaching `AirWrap` past the
  terminator), the ground it hides (`Clear`) and the halo's density.
- `Spin(units)`, `Face(longitude)`, `DestFor(cx, cy, diameter)` (the
  square that puts the disc there, halo included), `Draw(dest, tint,
  level)` - repaints the streaming texture only after a change
  (`PaintRow` along the row's `TRowSpan` -> `PaintGround` / `PaintAir`,
  inline, a `TGlobeTexel` each), tint = color mod,
  level = alpha mod. `Confine` replaces Max/Min/EnsureRange on Doubles:
  those have an overload per float type and an untyped literal next to a
  Double can match two. Compiled `{$O+,R-,Q-}` whatever the build: a 33 Hz
  walk over a quarter million texels. Users: `Menu.Globe` (the menu moon),
  `TSkyGlobe` of `Levels.Dynamics`.

### `Menu/Menu.Globe.pas` (~95 lines)
The moon of the menu as a spinning `TGlobe`. **`TMoonGlobe`** takes the ui
set and the map name (`moonmap`, 2048x1024) and owns the look as a typed
constant `MoonLook` (512 texels, regolith, the axis leaning 18 and tipping
12 degrees so the spin reads as a globe, earthshine on the night side, the
cool 2008 tint, no air). The sun stands still, up and to the left; `Tick`
spins one turn in 2640 ticks (80 s), `Draw(dest)` draws untinted, at full
level.

### `Menu/Menu.Logo.pas` (~220 lines)
The title logo and the light it sheds. **`TMenuLogo`** loads `logo.png`
(2:1, letters alone on transparent) and builds everything else from it, so a
redrawn logo brings its own glow.
- Halo: the letters' alpha shrunk 4x into an apron-padded image, three box
  blurs (`HaloBlurRadius=5`, `HaloBlurPasses=3`: `BlurImage` of `Render.Glow`),
  normalized to a peak of one and made a texture (`CreateGlowFromImage`
  of `Render.Glow`, lifted out of this unit at 3.0.47); tinted with `InkTint` (the mean ink color
  at full brightness); breathes on a 16 s sine (`HaloBaseLevel=0.55`,
  `HaloSwing=0.2`).
- Owns a `TEmbers`. `Tick`, `Draw(dest, alpha)` - halo under, letters, embers
  over; the halo reaches `HaloApron` texels past the letters' rectangle,
  scaled by the same factor the letters are.

### `Menu/Menu.Embers.pas` (~220 lines)
Sparks drifting off the outline of the logo. **`TEmbers`** takes the locked
letters surface and reads the outline itself (`ReadOutline`: every ink texel
with air beside it is a `TEmberSeed` with the alpha slope as its normal).
- One ember in flight per `OutlinePerEmber=200` outline texels (26 on the
  current logo). An ember (`TEmber`) is born on a random seed, flies out
  along the normal with a sideways throw, `EmberLift` bends it upward,
  `EmberDrag` slows it, it cools `EmberBirthColor` -> `EmberDeathColor` and
  fades over the last `EmberFadeShare` of a 70..140-tick life, then is
  reborn elsewhere. Ages staggered at start. Own `TXorShift`, seed "Fire".
- `Tick` flies them. Everything in letter texels;
  `Draw(dest, alpha, lettersW, lettersH)` scales
  to the units of the rectangle, so the trailer's larger logo scales its
  sparks too. Drawn with the `gsPoint` glow.

### `Menu/Menu.pas` (~915 lines)
The main menu: the sky rig, the screens, the dolly between them.
- **Records**: `TLevelChoice` (fileName + localized title; discovery is done by
  the composition root, which owns the file system), `TMenuResult` (command +
  payload), `TMenuItem`, `TMoonDrift` (the drifting moon in the 2008 "sdvig"
  +-500 space; `Respawn`, `Tick`).
- **Enums**: `TMenuCommand` (mcNone/StartLevel/Resume/ToggleFullscreen/
  SetDifficulty/SetLanguage/Quit), `TMenuScreen` (msMain/LevelSelect/
  Credits/QuitConfirm - the difficulty submenu is gone), `TItemAction`
  (internal navigation vs surfaced commands; `iaDifficulty` cycles the grade
  in place), **`TShowcaseKind`** (skNone/skLogo/skSky) - the trailer frames:
  the live sky rig alone, with or without the logo. Only the debug keys can
  enter one, so with DEBUGKEYS off the state stays skNone.
- **`TMoonMenu`** - the sky texture (16:9 nebula, `CoverSource` crops it to
  the frame, `SkyShade` dims it), `TStarfield`, `TMoonGlobe` (sized by the
  frame height, `MoonDiameter`), `TMenuLogo`, a `THudBrush` for the
  difficulty cells, an item list per screen, language flags (owned textures,
  240x160 drawn into 30x20 units; `FlagRect` is the draw AND hit-test
  geometry), a difficulty display copy. Takes the ui set and the weapon set
  (attached, not owned): both feed its own color-keyed `TSpriteCache` for
  the cursor frames; the ui set alone serves the sky, the moon map, the logo
  and the flags. `EMenuError`.
  - Layout constants: the 2008 NDC geometry frozen in units (`LogoLeft/Top/
    Width/Height`, `BigRowStep=12.5`, `ItemColumnX` = column 17, `TitleX/Y`
    on the flags' line, `LogoCaptionX/Y`, the difficulty cell metrics
    (`DifficultyCell*`, `MenuInkColor` = the atlas green), the flags, the
    version tag margin, the cursor frames and offsets).
  - The dolly: `FDepth`/`FDepthTarget` (0 = main, 1 = a submenu), one step per
    tick over `DollyTicks=26`, eased in `DrawDepth`; `DrawSky` grows the
    nebula by `SkyZoom`, the stars by `StarZoom` (via their shares), the moon
    and its drift by `MoonZoom` - all 0.2 but the sky's 0.04.
  - `ShowMain`, `Tick`, `Draw(alpha)`, `DrawSky(alpha)` (the story screen
    reuses the live sky as scenery), `MouseMove`, `Click -> TMenuResult`,
    `HandleEscape` (True = consumed), `ShowShowcase`/`ShowcaseActive`/
    `EndShowcase`, `DrawVersion` (the `vX.Y.Z` tag in the bottom-right corner
    of every menu screen), `DrawDifficultyCells`, `DrawDifficultyNote` (the
    grade's name and, over a running game, when it bites - while the cursor
    rests on the item), `DrawCredits` (five lines on the 2008 rows).
    `ItemWidth` = caption plus whatever rides after it, one width for drawing
    and hit-testing. Properties `HasActiveGame`, `Difficulty`, `Language`
    (the setter rebuilds captions through `Tr` - set it AFTER the dictionary
    swap).

### `Game/Game.Loop.pas` (~385 lines)
Host: window and renderer plus the fixed-timestep loop.
- **`TGameApp`** (abstract) - `Update(dt)` (fixed), `Render(renderer, alpha)`
  (alpha = the interpolation fraction), `HandleKey/MouseMove/MouseButton`,
  `RequestQuit` / `QuitRequested`.
- **`TGameHost`** - `Create(config, title)`: declares per-monitor DPI
  awareness before `SDL_Init`, creates the window and renderer (the D3D11
  hint lives here, and right after it `SDL_RENDER_BATCHING`: naming a
  driver turns SDL's batching off), hides the OS cursor (the game draws its own) and stamps
  the renderer backend and SDL version into the title once. Properties
  `Renderer`, `Window`. `Run(app)`: event pump, fixed-step accumulator at
  the config's `TickRate` (33 by default; a stalled frame is clamped to
  `MaxFrameSeconds=0.25`), frame-budget wait for the no-vsync path. The
  once-a-second fps title with worst-frame diagnostics is compiled only
  under `TITLESTATS`, off in `Moon2D.inc`. `EGameHostError`.
  `TKeyAction` = (kaDown, kaUp).

### `Game/Game.HeroOrbs.pas` (~450 lines)
The hero's orbs and the charge of the form, moved out of `TMoonGame`
before stage 8 of arena 3 (no version): the aura, the rite of the
henshin, the burst of the suit, the fire rain, and the orbs that carry
the charge into its gauge. It does not know the game: it asks about the
hero through probes, and what an orb strikes is settled through the
targets the game hands in - the unit decides when an orb or a ray
strikes, the game what stands there and what a wound costs. Which form
the hero wears is not here: that is `THero.HeroForm` (`hfNormal`,
`hfIce`).
- **`OrbReach`** (6, in `interface` - the game's `EnemyBulletNear` reads it
  too: how near an orb takes an enemy bullet); `BurstHitStep` (4, in
  `implementation`: how often along a ray's way the burst strikes, under
  the orb's reach so no bullet slips between).
- **`TOrbProbes`** (record) - `Alive` (`THeroAlive`), `Center`
  (`THeroCenter`, screen units), `Body` (`TBodyProbe` of `Orbs.Rite`),
  `Matter` (`TMatterProbe`). **`TOrbTargets`** (record) - `PopBullet`
  (`TBulletPop`: bursts the enemy bullet within `OrbReach` of a point,
  True if there was one), `MonsterAt` (`TMonsterProbe`: the dangerous
  monster whose body holds a point, nil when none does), `Wound`
  (`TOrbWound`: a life off, a kill rewarded).
- **`THeroOrbs`** - made once with the game (`CreateOrbs`), freed with
  it; owns `FAura` (`TAura` of `IceOrbTint`), `FRite` (`TOrbRite` of
  `IceOrbTint`, the `Body` probe), `FPattern` (the figure the rite builds
  on this level), `FBurst` (`TOrbBurst`, the same probe), `FBurstWounded`
  (none loses more than a life a burst), `FRain` (`TOrbRain` of
  `IceOrbTint`), `FFeed` (`TOrbFeed` of `MoonOrbTint`), `FEnergy`
  (0..`FullEnergy` of `Hud.Energy`) and `FEnergyAtEntry`.
  - The rewinds - the game only says which: `BeginLevel(pattern)` (every
    flock cleared, the charge and its entry zeroed, the level's pattern
    taken); `Rewind` (every flock cleared, the charge back to its entry);
    `Arrive` (the entry becomes the charge + `FFeed.Pending` - the orbs on
    their way are the charge's already; the rain put out, as a door puts
    out bullets); `Fall` (the hero's death: the aura, the rite, the rain
    and the feed collapse - the feed's charge with them; the burst cleared,
    no strike, no suit). A door: `CarryRite(step)` before
    `ArriveOnScreen`, by the door's step alone - a trigger of the new
    screen may begin a rite of its own, which has crossed nothing;
    `CarryAura(step)` after it, a trigger's leap included. The burst is
    not carried: its marks, rays and motes stand in screen units.
  - The calls, nothing over the corpse (`Alive`): `BeginRite`
    (`FRite.Start(FPattern, IceRiteScore, center, matter)`), `ShedSuit`
    (`FRite.Shed(IceRiteScore, center)`), `StartBurst(look)`
    (`FBurstWounded` emptied, `FBurst.Start(look, pattern = 'vortex',
    center, matter)`), `BurstSuit` (the ice look, as the ceremony asks),
    `FeedEnergy(amount)` (capped at the room the gauge has, what is on its
    way counted; flies to `THudEnergy.Heart`), `CastAura` (True when cast:
    the game then grants the mercy of a hit), `PourRain`.
  - The tick: `Tick` (the aura, the rite and the burst, with the hero's
    center - before the ceremony's tick, which hears what they tell),
    `TickAfterCeremony` (the rain, then the feed; `TakeLanded` goes into
    `FEnergy`), `Strike` (the aura, the rite, the burst, the rain: an orb
    alive and armed is spent on a bullet popped there, else on a monster
    there, which is wounded; every stretch of `FBurst.Stretches` walked in
    steps of no more than `BurstHitStep`, a bullet popped at every point,
    a monster wounded once a burst - behind walls too, and off the
    screen). `TakesAt(fromX, toX, y)` (3.0.57) - the first armed orb of the
    aura, the rite or the rain within `OrbReach` of the stretch is spent on
    what flies there: a cannon's round, a live shard. `Holding` /
    `Inhaling` - the burst's inhale: the world stands, the hero is a bare
    figure.
  - The draw, in layers the game interleaves with the hero: `DrawBehind`
    (the rite behind him), `DrawVeil`, `DrawSilhouette(figure)`,
    `DrawOrbs` (the aura, the rite in front, the burst's world layer, the
    rain), `DrawGlass`, `DrawFeed` (over the gauge). `Energy`; `Rite` and
    `Burst` - the ceremony's stage watches them.
- Tests: `Tests/Game/Tests.Game.HeroOrbs.pas`.

### `Game/Game.Moon.pas` (~3640 lines)
The whole game-flow state machine (`TMoonGame`) - the game the program
runs. Moved out of `Moon2D.dpr` word for word before stage 8 of arena 3,
so a unit (and later a test) can reach it. `interface` holds
`LevelFilePattern`, `TGameState`, `TArmorPings` and the class; the rest is
`implementation`.
- **Top constants**: the level file pattern (`LevelFilePattern`, in
  `interface` - the program's discovery reads it too), asset dir names (`SoundsDir`, `MusicDir`), the weapon->shot sound map, named one-shot
  sounds (the bonus cost lives in `Game.Bonus`; the three of an arena
  rebuild - `PadHumSoundFile`, `PadClickSoundFile`, `PadClackSoundFile`;
  the latch of a shelf - `ShelfLatchSoundFile`, 3.0.51; the burst of the
  wall cannons - `CannonShotSoundFile`, `shoot2.wav`, 3.0.56),
  `VictoryMusicFile`, `MenuMusicFile`, `LevelEndLingerTicks=400`,
  per-difficulty hero health and monster-lives multipliers, gravel trial
  monster (`GravelMonsterId`) and the medkit it lets down
  (`MedkitMonsterId`), the cannons' dice (`CannonSeed`) and the smoke the
  next act waits out after their blast (`CannonSmokeTicks` 50), ticker
  durations, damage
  bookkeeping (`HurtMercyTicks`,
  `GameOverDelayTicks`, `PitDepthY`), the font choice (`FontFileName`,
  `FontOrientation`, `FontFiltering`), `AuthorLinkedInUrl`,
  extra scancodes (`ScancodeS` - the drop - among them; the debug ones
  under DEBUGKEYS), the screen-shake doses
  (`ExploderTrauma`, `BossBlastTrauma`, `BonusExplosionTrauma`,
  `AftershockTrauma`, `BossCrashTrauma`, `CannonBlastTrauma` - a 2026
  addition; the
  ceremony's own live in `Game.Henshin`), ending-screen layout rows. The
  developer-facing level errors are resourcestrings in English, outside
  the dictionaries (`SSpriteSetMissing`, `SAmbiguousSprites`).
- **Types**: `TGameState` (gsMenu/gsIntro/gsPlaying/gsEnding).
- **`TMoonGame`** (extends `TGameApp`) - holds the registry (owned by
  `RunGame` of `Moon2D.dpr`) and owns the rest: level, the
  level's sprite sets and its three caches (tiles, backdrops, objects), the ui
  and weapon sets, the sprite, tile, object and dynamic-object renderers
  (`FDynamics`, reborn with the level, freed before it), the pad world
  (`FPads`, reborn with the level, freed before the object cache), hero (his burst is
  his own, `THero.Bullets`), monster
  field, the shared enemy burst (`FMonsterBullets`), font, message board,
  the briefing (`THudBriefing`), the screen shake, sound bank,
  menu, the explosions and the impacts (`FExplosions`, `FImpacts`, one of
  each for the run), the gravel arena's (3.0.53-3.0.59, one each for the
  run, made in the constructor): the trial's rules (`FTrial:
  TGravelTrial`), the violet light (`FArrivals: TArrivals`), the wall
  cannons (`FCannons: TCannonPair` over `FCannonArt`), the press of the
  finale (`FPress: TPress`), the hero's orbs and the charge of the form
  (`FOrbs: THeroOrbs`, `Game.HeroOrbs`, one for the run too), the ceremony
  (`THenshin`), the uptake of pickups (`FUptake: TUptake` and
  `FUptakePainter`, 3.0.50; reborn with the level, right after the
  shroud), the event director (`TEventDirector`), the arena of the
  boss fight (`FArena: TPadArena`, made before the director, which gets
  its `Engage` and `Restore` as the `TArenaCues` built in `LoadLevel`),
  the two corner HUDs (`THudVitals`, `THudCharge`) and the health rows over
  the figures (`THudMarks`) - the ceremony, the director and the three HUD
  objects are reborn with every level, as the arena is, so nothing carries over. Key state:
  game state + resume state, held-key flags (the 2008
  polled-keyboard model; `FHeldDown` - S/Down - sends `hcDrop` every
  tick, after the jump command), health + hurt cooldown, game-over timer, checkpoint
  X/Y (where pits and death return the hero on the current screen: the
  level's respawn point of the screen when it names one, else - as in
  2008 - the entry point and what a heroX / heroY trigger wrote), score +
  kill streak, per-entity trigger-fired flags, the bonus slot
  (+ its queued activation; `FBonusLearned` - the first reward spent - is the
  one thing that survives levels, so the HUD insists once per launch), the
  gravel trial's screen (`FGravelScreen`) and what the events told it -
  the bank its medkits come down onto (`FMedkitBank`), the monster and the
  bank of its wave (`FWaveMonster`, `FWaveBank`), the body of its open sky
  (`FSkyMonster`), the column of the aimed gravel on its way
  (`FAimedColumn`), the fly-ins held through the cannons' scene
  (`FHeldFlyIns`, `FCannonSmoke`) and whether it is won (`FTrialDone`) -
  all of it cleared by `LoadLevel` and `RestartLevel`, the
  end-level timer, the level list + current file + current music, fullscreen,
  difficulty.
  Method clusters:
  - Flow: `Update`, `Render` (the layer order there is the shake spec: backdrop
    still, the backdrop layer of the dynamics on the world channel - a
    haze bends the still backdrop where its jolted pad is -, the sky
    dynamics (the Earth) still again, the aloft dynamics (3.0.62: a
    scene's craft, its tractor and its lamps) on the world channel,
    objects + pads + back
    dynamics + tiles + bullets on the world channel -
    objects stand on the tiles and jolt with them, the pads draw right
    after the objects (with the frame's alpha - their sway between ticks):
    the pads in the depth, what hangs on them (`FDynamics.DrawSunk`), then
    the pads in front;
    the back dynamics right after the pads, behind tiles
    and hero - monsters (the field gets
    the frame's alpha:
    the boss's disc draws between ticks; the uptake's halos right before
    them - `FUptakePainter.DrawBehind` - and its loot layer right after -
    `DrawLoot`), then the
    machines' wreck smoke and sparks, then the front dynamics (the boss smoke and
    lamps), on
    the monsters' channel - the explosion plumes before them, right after
    the tiles, the explosion debris and flashes after the bullets, then the
    impacts (on the monsters' channel - they sit on armor), then the
    health rows (`FMarks`, each on its figure's channel) - the
    hero on
    his own, the back layer of the rite behind him (`FOrbs.DrawBehind`,
    on the world channel), the burst's veil (`FOrbs.DrawVeil`) and - while the
    burst inhales - his bare figure alone (`DrawHeroSilhouette`) in place
    of what follows up to the uptake; else `DrawHeroInShroud` (since
    3.0.61 these lines live in it), with `FineY` =
    `FHero.DeckLift(alpha)`: the shroud under him
    (`FShroudPainter.DrawUnder`), him (`FHero.Draw`, skipped while
    `FShroud.Assembling`), the light on his body (`DrawBody`), his arm alone
    while he is put together (`FHero.DrawArm`), then `FineY` back to 0,
    the shroud over him (`DrawOver`) and the uptake over that
    (`FUptakePainter.DrawOver`) -, the burst's flash over the world and
    under the HUD (`FOrbs.DrawGlass`, right after the arrivals, unshaken),
    cursor and HUD still; `Update` ticks the pads right before
    the hero
    (`FPads.Tick(FHero.Screen)`, then `FHero.Tick` - the riders move with
    their decks, then by themselves; right after the pads' tick it voices
    a rebuild - `padclick.wav` on `CornerTurned`, `padclack.wav` on
    `PairDocked` - and a shelf, `shelflatch.wav` on `ShelfLatched`; since
    3.0.57 `FPads.Tick(FHero.Screen, HeroDeck)` - the pad under the living
    hero, for a sleep that spares him and a stray he rides), runs
    `TickGravelAttack` before the input (the slot of 2008), ticks
    `FArrivals` after the impacts, `TickCannons` and
    `ResolveCannonContact` right after `ResolveMonsterContact`, ticks
    the arena right after the director, both skipped
    over the hero's corpse (`FArena.Tick`, then `padhum.wav` on
    `Warned`), and `FDynamics` after the monsters
    and the director, so a smoking monster's puffs leave from where this
    frame draws it), `LoadLevel` (the level's `HenshinPattern` is looked
    up as soon as the file is read and handed to `FOrbs.BeginLevel` with
    the rewinds: `FindPattern` of the word,
    `DefaultPatternName` for an empty one - a name the game does not know
    raises `EOrbPatternError` there, not mid-boss; the tile cache refuses
    a palette name two
    declared sets carry - `AmbiguousNames`, `SAmbiguousSprites`; the object
    cache: the
    level's own objects set if it ships one, then `objectSets`; handed to
    `Render.Objects`, `Pads.World` and `Render.Dynamics`; `FPads` is made
    after the objects renderer and before the dynamics - their parents may
    be pads -, with `JumpReach` of `Hero` and a seed of `RollDiceSeed`
    (the performance counter: the dice of the rebuilds are new on every
    try and are not `Random`), and handed to the hero and the field; the dynamics also get a
    `TDynamicWorld` - `LocateParent`, `SolidUnderPoint` and the tile
    renderer's `Backdrop`), `OpenSpriteSet` (a named set
    into `FLevelSets`, a missing one raises `SSpriteSetMissing`),
    `LevelArtSetFile` /
    `OpenLevelArtSet` (the `<assetsDir>-<kind>.mset` convention of the
    backdrops and the objects in one place), `StartPlaying`,
    `RestartLevel` (the field is reborn over the same `FPads`,
    `FPads.Rewind(RollDiceSeed)` puts the pads back where the level file
    has them - first, so `Reseat` finds a lamp's pad there -, `FArena.Reset`
    puts the arena to sleep, then
    `FDynamics.Reseat` puts what hangs on monsters onto the new ones),
    `AdvanceToNextLevel`, `CurrentLevelIsLast`, `BeginEnding`, `OpenMenu`,
    `ApplyMenuResult`, `ToggleFullscreen` (the player's switch, remembered in
    settings.json), `SetFullscreen` (the bare switch - the ending screen drops
    fullscreen for the browser through it, unremembered), `PreloadSounds`,
    `CreateHud` (builds the three HUD objects afresh on every level load),
    `ChangeMusic` (a trigger's or an event's track: played and remembered
    for restarts; '' is a no-op; with a fade-out - 3.0.74 - handed over
    by `HandOverMusic` and remembered at once, so a death in the fade
    restarts into the new track), `HeroRides(pad)` (the `TPadLoad` of the
    rebuilds: the pad under the hero - monsters are no riders, they fall
    through a pad that goes deep), `LocateParent` (the `TLocateParent` of
    `Render.Dynamics`: a pad first (`FindWearer` since 3.0.58: a pad's
    own rigs live until it breaks, those of its failing look from then on
    - the rig is alive only while it fits the pad as it is) - its screen, `Left` /
    `Round(Top)` + `Lift(1)` (where the pad is drawn as the tick leaves it -
    a fraction, the stand's Y is a `Single`), alive, its effort
    (`TPad.Effort`: 1 while the pad is `Thrusting`, in fits when it is a
    pad that plunges, 1 while a shelf warns - what hangs on it surges),
    and how deep it
    stands (`TParentDepth`: the pad's `RigDepth(1)` and `RigDepth(0)`,
    1 - `DeepScale`, 1 - `DeepTone`, its `Middle`) - what hangs on a pad
    goes into the depth as the picture of a flying pad does, and stays in
    front of a shelf that slides in; else the
    first monster carrying the tag - screen, sprite top-left as
    `TMonster.Draw` puts it (Y lowered by `DeckLift(1)`), alive, and for a disc monster the
    disc's last two poses with the axis in the middle of the sprite;
    `Levels.Defs` has refused a tag both carry).
  - World: `HandleScreenTransitions`, `ArriveOnScreen`, `HandlePitFall`,
    `MoveCheckpoint(col, row)` (3.0.71: a cell from 1 becomes the
    checkpoint - taken to the hero's corner and feet line as
    `THero.PlaceAtCell` does; the hero himself is not moved; the cue
    `Respawn` of the director), `PinRespawnPoint` (the level's respawn
    point of the hero's screen becomes the checkpoint through
    `MoveCheckpoint`; called after `FireScreenTriggers` in
    `ArriveOnScreen`, `StartPlaying` and `RestartLevel`, so the point has
    the last word over the entry point and over the triggers; the hero
    himself is not moved),
    `FireScreenTriggers` (the entities' triggers, then since 3.0.53 the
    level's `ScreenTriggers`, both through `FireTriggersOf`: the gravel
    trigger starts `FTrial` with the batch of the grade and, with a
    finale, its count and cap - `FWaveMonster` -, and the ceremony
    straight in), `TickGravelAttack`; the events are the director's
    (`FDirector.Tick` after the tick's verdicts, `ReArm` in `RestartLevel`;
    its `TDirectorCues` are built in `LoadLevel`).
  - The scenes (3.0.62): `FScenes`, a `TSceneDirector` made in `LoadLevel`
    over the level's scenes and dynamics, the pads, the sound bank and the
    message board; the events start a scene through the cue
    `StartScene`. `SceneStage` - the hero's middle, the field and the
    monsters' burst of this tick. `Update` ticks it after the arena and
    before the dynamics (a craft it moves moves this tick) - over the
    hero's corpse too - and adds its `Trauma` to the shake; `RestartLevel`
    calls `ReArm` right after the event director's; `OpenMenu` and the way
    back pause and resume it; `Render` draws its shade right after the
    burst's glass, over the world and under the marks and the HUD.
    `LocateParent` gives a dormant pad no life (`Alive` = the look fits
    and not `Dormant`): its rigs are out while it sleeps. Since 3.0.67
    the scene's jolts join the shake once a tick (`FScenes.TakeJolt`).
  - After arena 2 (3.0.63, `docs/mechanics/arena-3.md`): the trial's
    victory track plays as a held sound, not as music
    (`PlayVictoryTrack`: `FAudio.StopMusic`, `PlayTrackHeld(VictoryMusicFile)`,
    preloaded by `LoadTrack` in `LoadLevel`), so the music channel is free
    for the next track to fade in over its end (`ChangeMusic(file,
    fadeSeconds)`); `FVictory`, `FVictoryLeft` (seconds left, counted down
    in `Update`, `NoVictoryLeft` -1 while none) - the events' victoryEnds
    reads it (cue `VictoryLeft`). `StopVictoryTrack` on a restart and a new
    level; the menu pauses and resumes it with the scenes. `FGoRight` - a
    `THudGoRight`, made in `LoadLevel`, hidden on a new screen, shown by
    the cues `GoRight` and `OpenDoor`, ticked in `Update`, drawn with the
    HUD.
  - The charge of the form (3.0.70) lives in `FOrbs` (`Game.HeroOrbs`);
    the cue `Energy` is `FOrbs.FeedEnergy`. The gauge is the game's:
    `FEnergyGauge` (`THudEnergy`) is made in `CreateHud`, ticked in
    `Update` right after `FOrbs.TickAfterCeremony` with `FOrbs.Energy`,
    and `FVitals.Wing` takes its `WingWidth`; `Render` draws it after
    `FVitals.Draw` and the feed over it (`FOrbs.DrawFeed`), unshaken, so
    the orbs go into the disc.
  - The shut doors (3.0.66): `FDoorOpened` - an event has opened the door
    the level shuts on the hero's screen (`FLevel.DoorShutOn`); a new
    screen, a restart and a new level shut it again. `HandleScreenTransitions`
    lets the hero through the right edge only while no trial runs, the
    door is not shut and he is alive. `HeroStandsIn(col, row)` (3.0.67) -
    the cue `HeroStands`: his middle over the column, his feet on the
    row's bottom line, not on his way up or down.
  - The Duplet (3.0.64): `WeaponShotSounds` reaches `DupletWeapon`
    (`duplet.wav`), every shot adds `DupletShotTrauma` (0.2) - the kick of
    the stock; the uptake asks `PictureOf(monster)` and `PictureBox`.
  - The gravel arena (3.0.53-3.0.59; rules in `Game.Trial`, `Game.Press`,
    `Game.Cannons`, the design in `docs/mechanics/arena-2.md`): `TickGravelAttack` -
    every tick while the trial runs, even over the corpse: the gravels
    and the wave's bodies out of the right gap come back from the sky
    (`ReturnSideStrays`, `ArriveAgain` - the violet light and
    `HeadRandomly`); `ReleaseHeldFlyIns` (before the room is asked, so a
    carousel let in is landing on this very tick); `FTrial.RoomBusy` = the
    cannons' scene or their smoke (`CannonsScenePlays`), a held fly-in, or
    a carousel landing; the gate holders = the gravels alive + the guests
    (`CountAliveGuests`) + the wave alive, the cap counted against the
    wave alone; then `FTrial.Tick` and `TellPress(FPress.Tick)`, and the
    cue carried out: a pit return over `HeroColumn` (a gravel first, then
    a body of the wave), a gravel let down (`LetDownFromSky`, the herald's
    light on the first, `HeadRandomly`), the mark of an aimed one
    (`FAimedColumn`) and the gravel over it, a body of the wave
    (`LetDownWave`: the press told `Arrive` first, then over a shelf of
    `FWaveBank` picked from the half with fewer of the wave -
    `WaveSideWanted`, `TryPickBankMiddle(bank, side)`; no bank - a random
    column), a medkit (`LetDownMedkit`: over a shelf of `FMedkitBank`),
    the sky's body (`FSkyMonster`); `ActEnded` - `DepartGuests` and
    `FPress.Shut`; `Finished` - `FTrialDone`, the breakthrough message,
    `bottle.wav` and `RemoveIceForm` as before, and `win.ogg` once
    (`VictoryMusicFile`, `mmOnce`) with no level-end timer - the level
    goes on to the second boss. The cues of the director: `TellShelves`
    (an action into a `TShelfCommand`; `TellBank` with the hero's middle),
    `BreakCarousel`, `LetStraysGo`, `SendStraysAway`, `FlyInParked` (held
    in `FHeldFlyIns` while `CannonsScenePlays`; then
    `TryFlyInCarousel`, else `FArena.FlyIn`), `SendMedkitsOnto`,
    `SendWaveOnto`, `StartCannons` (the event's act, or the trial's for one
    that names none), `SpawnGuest` / `OpenSky` / `StartPress` (only in the
    act the event waits for: `TrialAct`), and the pulls `TrialAct`,
    `TrialProgress`, `TrialDone`. The press: `TellPress` ->
    `TellPressRow` (`TellBank` sleep, or wake with hold; no spareHero -
    no mercy on the press). The cannons: `TickCannons` (`FCannons.Tick`
    with `TrialAct`, the living hero's body and `FOrbs.TakesAt`; the cue: hum,
    shot, the yield bank through `TellYieldBank`, sparks off steel through
    `LandCannonStrike`, `SHitByBullet` and `HurtHero` under the mercy
    window, `BlowCannons` - two `ekMachine` blasts, `platform.wav`,
    `CannonBlastTrauma`, the smoke), `ResolveCannonContact` (a touch
    wounds, `SHurtByMonster`, and shoves the hero `CannonShove` 4 off the
    wall), `BulletStruckCannon` (in `ResolveHeroBulletHits`: a shield eats
    the bullet, bare steel gives sparks and a ping, no damage).
    `FOrbs.TakesAt` takes the cannons' rounds and, through `ShardStruck`,
    a live shard ahead of what they would strike. Weather (3.0.58): `ResolveMonsterContact` bursts it on the hero
    (`Monster.Burst`), `meBurst` sends its blast out (`RewardMonsterKill`),
    and `RewardMonsterKill` pays nothing for it - no score, ticker, popup
    or streak. `DrainMonsterEvents` tells the trial of a gravel killed on
    its screen (`NoteGravelKilled`) and of a body of the wave
    (`NoteWaveKilled`). Drawn: `FCannons.DrawBodies` after the explosion
    smoke, before the monsters; `DrawLight` after the bullets;
    `FArrivals.Draw` after the impacts, on the monsters' channel.
    `ArriveOnScreen`, `LoadLevel` and `RestartLevel` clear the arrivals
    and the cannons.
  - Combat: `ResolveHeroBulletHits` (a bullet lands on the monster whose
    `HitBox` the stretch of its last tick meets: `HeroBulletTarget` over
    `BulletInMonsterBox`, `BulletStretch` and `StretchEntry`, the stretch
    lifted by `SpriteSize` as a bullet's picture hangs above its Y; the
    bullet ends in `SpendBullet`: in
    its own burst or, on a monster whose `material` is metal, with no
    burst at all - a strike for `FImpacts` built by the free `ArmorStrike`
    (honest screen units, at the point where the stretch first met the
    hitbox; `Rapid` asked of
    the monster before the damage lands, `RapidHitTicks`) and a sound from
    `SoundArmorHit`: the whine of a tracer, else one of three pings at
    random, never the same twice running (`TArmorPings`, dice of its
    own seeded with `ArmorPingSeed`), no more than one in
    `ArmorSoundGapTicks`),
    `ResolveMonsterBulletHits` (both burst a bullet on `BulletStruckWall`:
    the grid's cell, as before, or `StopsBulletAt` of a pad at the bullet's
    X and Y - `SpriteSize` - a bullet's picture hangs a sprite above its Y,
    the point it strikes with is up there; nothing while Y <= 0),
    `ResolveBlasts` (after the orbs, before the monsters' bullets: every
    `TBlast` of `FBlasts` spreads a tick, then `StrikeMonsters` - every
    living body of the hero's screen, enemy, barrel or pickup, by its
    `HitBox`: `TakeDamage` with the blast's knock and lives, the
    lives scaled by `DifficultyMonsterLives`, `RewardMonsterKill` on a
    death - and `StrikeHero` - `HeroBody`; one health and the
    `hurtByBlast` ticker unless the mercy window is on; `BlastStoppedAt`
    is the shelter, what stops a bullet: the grid's cell or
    `StopsBulletAt` of a pad; a spent blast is dropped; a blast born in
    the walk - a barrel a wave has killed - waits for the next tick;
    `FBlasts` is cleared with the explosions), then
    `FExplosions.StrikeShards(ShardStruck)` (3.0.44): a live shard lower
    than `ShardWoundsBelow` (half a sprite) under the heart of its blast -
    below the feet of the body that blew up - wounds the body it is in,
    a monster of any kind by `HitBox` (`TakeDamage` with half the
    shard's speed as the knock, `RewardMonsterKill` on a death) or the
    hero by `HeroBody` (one health, the mercy window holds); on the
    blast's own floor a shard is decoration,
    `ResolveMonsterContact`, `RewardMonsterKill` (also the `TBlast` of a
    monster with a `blast` and `Detonate` of the monster's `explosion`,
    both at the middle of its sprite, in the tick of the kill; the debris
    is detonated live with the blast's `ShardLives` scaled by
    `DifficultyMonsterLives`; a pickup killed so also gets `BurstPickup` -
    Uptake below), `HurtHero`, `DrainMonsterEvents` (also where explosions and boss
    blasts feed the shake; `meBossRage` detonates a machine-size blast on
    the boss and sounds it with `RageBlastSoundFile` - a machine's
    `platform.wav`; `meBossCrashed` - the boss's ram ended in a wall:
    `BossCrashTrauma`, `BossCrashSoundFile` (`crash.wav`) and
    `ThrowCrashSparks` - fans of `Game.Impacts` sparks off the rim that
    struck and along the wall, seven a side two units apart
    (`FansPerSide`, `FanGap`; three four apart before 3.0.27), every fan
    heavier than a bullet's by the strike's `ExtraSparks` - 27 on the rim
    (`RimExtraSparks`), 6 on each fan along the wall (`SideExtraSparks`) -
    and `FPads.Shove` with the crash's `Blow` and `LapHolds` (3.0.28);
    `meBossOwesPrize` - `PayDodgePrize` hands
    a living hero the boss's `DodgePrize` with `SpawnOn`),
    `ResolveMonsterContact` also reports every touch to the monster
    (`NoteHeroContact` - the pilot's prize rule) and takes a pickup the
    hero touches through `TakeLoot` (3.0.50, Uptake below), `EchoAftershock` (the `TEchoAftershock` of
    `Game.Explosions`: each pop of the boss's wreck plays `bottle.wav` and
    adds `AftershockTrauma`), `SolidUnderPoint` (the probe of debris, impacts and
    dynamic objects: `TLevel.SolidAtPoint` or a pad's body (`BodyAt`) for
    the hero's screen, honest screen units - no bullet -1 row), `ProcessKillStreak`, `AwardStreakBonus`.
  - Bonus: `CureHero` (+1 up to 10 - also the ceremony's cure callback),
    `AwardRandomBonus` (the headline carries the mouse hint until the first
    reward is spent), `ActivateQueuedBonus` (pays `BonusCost` on use; the
    aura reward goes to `CastAura`). The
    ceremony itself is driven through `FHenshin`: started
    by `meHenshin` (`StartCountdown`) and the gravel trigger (`Start`,
    straight in), ticked in
    `Update` right after the rite and the burst - after the monsters'
    events, so the
    first tick of a countdown falls on the tick of the boss's event -,
    drawn last in `Render`, reset in `RestartLevel`; the suit comes off
    (`RemoveIceForm`) on `meLevelComplete` and at the breakthrough of the
    gravel trial (`TickGravelAttack`, with `bottle.wav` there). What the
    ceremony asks the game for (its `THenshinCalls`, filled in
    `LoadLevel`): `CureHero`; `GrantMercy(ticks)` - `FHurtCooldown`
    becomes no less than `ticks`: a mercy never cuts a longer one short,
    and the window after a hit (`HurtHero`) and the aura's (`CastAura`)
    go through it too; `BeginRite`, `ShedSuit` and `Burst` are
    `FOrbs.BeginRite`, `FOrbs.ShedSuit` and `FOrbs.BurstSuit`, and the
    stage's `Rite` and `Burst` are `FOrbs.Rite` and `FOrbs.Burst`.
  - Orbs (`FOrbs: THeroOrbs`, `Game.HeroOrbs`): what the orbs and the
    burst do lives there. `CreateOrbs`, in the constructor, hands it the
    probes - `Alive` (not `FHero.Dead`), `HeroCenter` (the middle of the
    hero's body), `HeroBodyPoints` (the opaque points of the frame he is
    in, `FShroudPainter.SeedsOf`, mirrored with him, where they stand on
    the screen), `MatterAround` (the solid cells of his screen and the
    bodies of its pads, `FPads.Bodies`), each wrapped in an anonymous
    function - and the targets, the combat's half: `PopEnemyBullet` (an
    enemy bullet in flight within `OrbReach` of the point on both axes,
    `EnemyBulletNear` - a bullet's point is at its Y - `SpriteSize` -
    bursts), `DangerousMonsterAt` (a living dangerous monster of the
    hero's screen whose `HitBox` holds the point - the box `ArmorStrike`
    takes too - by `BoxHolds`), `WoundByOrb` (`TakeDamage(0, 1, ...)`,
    `RewardMonsterKill` on its death; not through `SpendBullet` - armor
    answers an orb with no sparks and no ping). `CastAura` (the aura
    reward and the G debug key) is `FOrbs.CastAura`, then the mercy window
    of a hit, `GrantMercy(HurtMercyTicks)`, because the ring is no shield
    until the orbs are in it - the HUD blinks as after a hit, a pit hurts
    as ever. The fire rain reward (`bkFireRain`) and the H key call
    `FOrbs.PourRain`. `Update`: `FOrbs.Holding` into `WorldStands` once a
    tick, before the field - while the burst inhales, `FField.Tick` with
    `DrainMonsterEvents`, `FMonsterBullets.Update` and `TickCannons` do
    not run, and the strike does not wake the cannons of that tick;
    `FOrbs.Tick` right after the arrivals, before `FHenshin.Tick`;
    `FOrbs.TickAfterCeremony` after the shroud, then the gauge;
    `FOrbs.Strike` between `ResolveHeroBulletHits` and `ResolveBlasts`,
    so an orb takes a bullet ahead of the hero. The rewinds:
    `FOrbs.BeginLevel` in `LoadLevel`, `FOrbs.Rewind` in `RestartLevel`,
    `FOrbs.Arrive` in `ArriveOnScreen`, `FOrbs.Fall` in `HurtHero`;
    `HandleScreenTransitions` calls `FOrbs.CarryRite` before
    `ArriveOnScreen` and `FOrbs.CarryAura` after it. `Render`:
    `FOrbs.DrawOrbs` after the cannons' light; while `FOrbs.Inhaling`,
    `DrawHeroSilhouette` in place of the hero (`FShroudPainter.MaskOf` of
    his frame, where `Pose` puts it with his shake and `DeckLift`,
    mirrored with him, drawn by `FOrbs.DrawSilhouette`).
  - Shroud (3.0.47): `FShroud` (`THeroShroud`; the probe is
    `SolidUnderPoint`, the dice seed `RollDiceSeed`) and `FShroudPainter` are
    reborn in `LoadLevel` with the hero, before the ceremony, which gets the
    shroud in its `THenshinStage` and starts the ice looks itself. Starts
    here: `HandlePitFall` - `PitLook`, after the hero is put back (`SetY`)
    and before `HurtHero`; `StartPlaying` - `EntryLook`; `RestartLevel` -
    `Clear`, then `ReviveLook` once the hero is revived and put down.
    `HurtHero` clears it on the hero's death; `ArriveOnScreen` calls
    `LeaveMotes` - a door leaves the motes and the mist behind. `Update`
    ticks it after the ceremony, right after the uptake: one `FHero.Pose`
    read gives both the pose and the frame whose seeds the painter hands
    over (`SeedsOf`), and the two get the same pair. The destructor frees
    the ceremony, the uptake, the painter and the shroud before the hero.
  - Uptake (3.0.50): `FUptake` (`TUptake`; the probe is `SolidUnderPoint`,
    the feed `FShroud.Feed`, the dice seed `RollDiceSeed`) and
    `FUptakePainter` are reborn in `LoadLevel` right after the shroud - the
    feed is its method - and before the ceremony and the field; they are
    freed there before the shroud's pair. `WarmPickupPictures`, after every
    birth of the field (`LoadLevel`, `RestartLevel`), asks the painter for
    the picture of every pickup's `ArtSet`: the first touch does not stop
    on loading one, and a set that cannot be read stops the load of the
    level, not the touch. A pickup born later - from the sky, a prize -
    has its picture built when it is first drawn or taken.
    Starts: `BeginUptake(look, monster)` is the one place a scene begins -
    the painter's picture and shape of the monster's `ArtSet`, the corner
    its frame is drawn at (`Round(X)`, `Round(Y)` - `SpriteSize`), its
    `Mirrored`, `HeroCenter`. `TakeLoot`, from the pickup branch of
    `ResolveMonsterContact` after the ticker and the cure or the weapon, in
    place of the lethal `TakeDamage` of 2008: `WeaponUptake` for a
    `peGiveWeapon` pickup, `MedkitUptake` for any other, then
    `Monster.Collect`. `BurstPickup`, at the end of `RewardMonsterKill`
    for a body of the `mcPickup` category: `PickupBurst` and one strike
    for `FImpacts.Land` at the middle of the frame, normal up, with
    `PickupSparks` = 6 as its `ExtraSparks`. `RewardMonsterKill` is called
    in the tick of the kill from all four places a monster is killed (a
    bullet, an orb, a wave, a shard), so the scene begins in the tick the
    body stops being drawn and the pickup does not vanish for a tick. (An
    orb strikes dangerous bodies only and no pickup is one: as the data
    stands, a pickup dies of a bullet, a wave or a shard.)
    `DrainMonsterEvents` is as it was: the pickup's sound plays on
    `meDied`, taken or destroyed.
    `Update` ticks it after the ceremony and right before the shroud, with
    the same pose and seeds: what comes home feeds the shroud's light, and
    the light then fades by a tick. The contact is resolved later in
    `Update`, so a scene takes its first step on the tick after the touch.
    `Render`: `DrawBehind` right before `FField.Draw` and `DrawLoot` right
    after it, both on the monsters' channel; `DrawOver` right after the
    shroud's, with `FHero.Pose`, the hero's channel and his `DeckLift`.
    `ArriveOnScreen` - `FUptake.Settle`, right before `FShroud.LeaveMotes`:
    what was on its way is the hero's at once and nothing flies beyond the
    door. `HurtHero`, on the hero's death - `FUptake.Drop`, after
    `FShroud.Clear`: the light is out and the crumbs fall. `RestartLevel` -
    `FUptake.Clear`, before `FShroud.Clear`. The destructor frees the
    painter, then the count, after the ceremony and before the shroud's
    pair.
  - Drawing/input: `AdvanceBriefing`, `DrawEnding`, `DrawCenteredBig`,
    `HitEndingLine`, `HandleEndingClick`, `CrosshairFrame`,
    `HandleKey/MouseMove/MouseButton` (S/Down hold `FHeldDown` - the drop
    through a pad).
  - Debug: `HandleDebugKey`, `HandleDebugMenuKey`, `UpdateInspectorCaption`,
    `DrawAtlasOverlay` - the four doors the debug keyboard uses, and nothing
    else. All four exist in every build; their bodies compile away, so no
    caller needs an ifdef. Behind them: `CastAura` (G: the aura straight
    onto the hero, the slot untouched), `FOrbs.PourRain` (H: the fire rain over
    the hero's screen, the slot untouched), `FHenshin.Start` (J,
    `ScancodeJ`, 3.0.49: the henshin at once, no boss and no countdown),
    `FOrbs.ShedSuit` with `GrantMercy(IceRiteScore.ShedTicks)` (K, `ScancodeK`,
    3.0.49: the ring of orbs and its mercy as the boss's death gives
    them, with no suit to take off), `FOrbs.StartBurst(IceBurstLook)` (L,
    `ScancodeL`, 3.0.61: the burst on the hero at once, no rite and no
    suit - the look, the world standing and the strikes only),
    `FOrbs.StartBurst(MoonBurstLook)` (U, `ScancodeU`, 3.0.61: the same in the
    moon's look, which no form wears yet), `NudgeCrosshair`,
    `NudgeMinigunMuzzle`, `DebugBrowseScreen` (PgUp/PgDn, through
    `DebugShowScreen`), `DebugJumpToWork` (End, `ScancodeEnd`, since 3.0.74:
    the false ending of level 2 from anywhere - another level is loaded
    and its story skipped, the gravel trial's screen 9 is entered with its
    triggers spent (`DebugSpendTriggers`: counted as fired, their track
    changed to, so a restart plays what a walk in would have), the hero
    stands on the screen's respawn point, its events are re-armed and the
    trial is won at once (`CelebrateBreakthrough`, the end of
    `TickGravelAttack` taken out for the two): the victory track, the
    tunnel music under its end, the arrow, the whole way on; every press
    plays it anew. Before, it took the hero to screen 10 with the music a
    walk there would have brought - `TrackBefore`, gone with it),
    `CycleFontFiltering`,
    `DebugRebuildPads` (R: the pad group of the hero's screen is rebuilt at
    once, every pad free to set off - no lap held, no warning, no wave, no
    traffic: nil), `DebugRestorePads` (Y, `ScancodeY`, 3.0.39: the same
    group flies back to the level file's places at once, calmly, no
    ripple),
    `DumpLevelScreens` (P: the tiles of every screen of the level, each
    alone on a transparent ground, one PNG per screen in
    `dump\<level id>\` of the working folder (`bin`) - the source
    pictures for repainting the art outside the game; the count goes to
    the ticker, the folder to the caption; `SaveScreenPictures` draws
    them past the window into a target texture of grid x `TileArtSize`
    pixels, so the picture does not depend on the window).
- **Free functions**: `OpenWebPage`, `BonusDisplayName`, bullet cell and
  off-screen helpers, `BulletStretch` (a bullet's last tick of flight in
  honest screen units) and `BoxHolds` (whether a box holds a point),
  `SaveTargetAsPng` (under DEBUGKEYS: the current
  render target into a PNG through `IMG_SavePNG`), `RollDiceSeed`.
- 3.0.75, **the Ram**: `FRamArt`, `FRam`, `FRamPainter` (made with the
  game, freed after the cannons), `FRamRumble` (the held loop). `StartRam`
  (the cue of the `ram` action) - the whole entrance clears `FCurrentMusic`
  and fades the music out to silence. `TickRam` (with the cannons, not
  while the world stands): the Ram's tick and its painter's, the rumble
  started over (`PlayLooped`) and cut by the hiss (`StopRamRumble`), the
  whine, the jolt, and on `Locked` the track - `ChangeMusic` unless it
  already plays. `ResolveRamContact` after the cannons': a touch wounds as
  a monster does, under the mercy, and throws (`THero.Throw`); the hero
  is on a deck when he stands on one. `BulletStruckRam` beside
  `BulletStruckCannon`. Drawn after the static objects and before the
  pads (`DrawBody`), its shield with the cannons' light (`DrawLight`).
  `LoadLevel` resets it, `ArriveOnScreen` and `RestartLevel` clear it,
  stopping the rumble; the menu pauses and resumes the rumble;
  `DebugJumpToWork` resets it, so the End key sees the whole entrance.
  `RestartLevel` plays its track only when `Plays` says it does not play
  already. `HeroStandsIn` asks `THero.InAir`.

### `Moon2D.dpr` (~200 lines)
The program: the start-up and nothing else. `RunGame` (the actual main:
config -> language -> level discovery -> registry -> host -> game),
`DiscoverLevels` (`LevelFilePattern` from 1 to `MaxLevelSlots`, the first
gap ends the list), `ReadLevelTitle` (the title of a level file without
building the level), `ConfigFileName`, `SNoLevelsFound`; a start-up
failure ends in a message box. Its uses clause lists every unit of the
game with its path - that is how the units find one another, so a new
unit goes there and into `Moon2D.dproj`.

---

## Tools

### `tools/SpritePack/` - sprite set packer (console app)
Builds and inspects `.mset` files. Wraps `Sprites.Sets` and nothing else.
- **`SpritePackCli.dpr`** (~350 lines) - commands `pack` / `list` / `unpack`.
  `pack` takes every PNG in a folder in natural order (2 before 10); `--list`
  splits a 2008 sprite list into named sequences by its length (16 lines ->
  alive+death, 24 -> walk+death+henshin, anything else -> one group,
  `frames`); `--id` names the set (default: the folder name). `unpack`
  writes the images plus `manifest.json`, so a set can always be taken apart.
- `unpack` then `pack` is not a round trip: `pack` ignores `manifest.json` -
  sprites go back in natural order, descriptions come out empty, sequences
  come only from `--list`. A set with descriptions or a hand-set order
  (`boss1-disc`, `sky`, `level1-objects`, `level1-backdrops`, `ui`) needs
  `TSpriteSetWriter` driven directly until SpritePack.exe exists; an animated
  set needs its sprite list written out again for `--list`. The
  `pack-sets.ps1` script that built them from the loose 2008 art was a
  one-shot migration tool and is gone with the art (3.0.0; in git history).
- A VCL half (`SpritePack.exe`, sprite and description editing) is planned; the
  logic stays in `Sprites.Sets` so both executables are thin.

### `tools/TitleCard/` - trailer text-card generator (VCL app)
Renders arbitrary text in the game's bitmap font to PNG. Reuses `Sdl2.Core`,
`Sdl2.Image`, `Sprites.Sets`, `Render.Sprites` and `Render.Font` from `Core/`
by relative path - it opens
`ui.mset` and asks for the `fonty` sprite, the same path the game takes.
- **`TitleCard.dpr`** - VCL bootstrap.
- **`TitleCard.Layout.pas`** (~355 lines) - pure layout math. Constants:
  measured font ink metrics (`InkTopRatio`, `CapHeightRatio`). Records:
  `TCardGeometry` (size, margins, optical center 0.45, line spacing),
  `TCardScale` (smFitInteger/FitFree/Explicit + factories), `TPlacedLine`,
  `TCardLayout` (cellHeight, lines, charLimit, overflow queries). Functions:
  `BuildCardLayout`, `WrapCardText` (emergency word-wrap), `SplitCards` (a
  batch file split on blank lines), geometry helpers.
- **`TitleCard.Renderer.pas`** (~165 lines) - **`TCardRenderer`**: a hidden SDL
  window plus a target texture, renders a layout, `RenderCard -> TBytes` (RGBA
  top-down) via `SDL_RenderReadPixels`. `TCardBackground` = (cbTransparent,
  cbBlack).
- **`TitleCard.Config.pas`** (~170 lines) - **`TTitleCardConfig`** record
  (sprite set path, font sprite name, render driver, geometry, scale steps,
  batch pattern, uniform batch scale), ini load/save, `ResolveSpriteSet`
  (walks up to six folders
  looking for the set).
- **`TitleCard.Main.pas`** (~425 lines) - **`TMainForm`** (VCL): memo,
  combos for aspect and scale, percent edits for margin / optical center /
  line spacing, checkboxes for black background, emergency wrap and one
  scale per batch, live preview, single save and batch render.
- **`Image.Png.pas`** (~190 lines) - `SavePngRgba` free function, a hand-rolled
  PNG writer.

### `tools/bmp2png/convert.py`
The one-shot BMP->PNG migration with the color-key rule baked in (pure black,
plus thin near-black fringes and flat near-black fills at the border ->
transparent; backdrops and the root atlases stay opaque). Kept for provenance;
nothing calls it now.

### `tools/Selene/` - Selene map painter (Python)
Paints the living anti-moon for the menu globe from the menu's own `moonmap`;
nothing in the game reads the result yet. numpy + scipy + pillow.
- **`extract_moonmap.py`** - pulls `moonmap` out of `ui.mset`.
- **`paint_selene.py`** - surface + water mask, and (`clouds`) the cloud layer;
  seas from dark albedo, colour from a climate model, baked relief, rivers.
  Seeded: the same input gives the same planet bit for bit.
- **`preview_globe.py`** - renders the globe in "photo" light (glint, limb haze,
  terminator, cloud shadows) as the reference for Selene in the menu
  (per-pixel precompute, the way `Render.Globe` does its shade).
- **`selene_lib.py`** - sphere-sampled noise, wrap-aware filters, river tracer.
- **`out/`** - the approved maps (2048x1024) and preview.

### `tools/sounds/armor.py`
Synthesises the sounds of a bullet on armor into `bin/sounds`: three pings
(`armor1..3.wav` - a struck plate: a click of noise and the partials of a
free bar; all within a semitone, one plate and not three notes) and the
whine of a tracer (`ricochet.wav`). Seeded: the same
files bit for bit. numpy.

### `tools/sounds/crash.py`
Synthesises the boss ramming a wall into `bin/sounds/crash.wav`: a thud
sliding down in pitch, a crunch of noise with the treble taken off and the
hull ringing after them, pushed into a soft clip. Borrows the bar ratios,
`finish` and `save` from `armor.py` beside it. Seeded. numpy.

### `tools/sounds/cordon.py` and `tools/sounds/cordonburn.py`
Synthesise the sounds of the cordon (3.0.62) after `pads.py`:
`cordonhum.wav` - the hum of the hull from silence, its envelope baked
to the scene's timeline (the stop at 13 s, the climb from 25.6 s, silence
by 30.6 s); `cordonburn.wav` - the burning beam: an uneven drone of the
arc, hiss and quick clicks of every strength, a heavy click at the first
second where the betoner dies, then the arc dies out.

### `tools/sounds/pads.py`
Synthesises the sounds of an arena rebuild into `bin/sounds`: `padhum.wav`
(the warning: two low buzzing tones a hair apart, climbing, throbbing at
the rate the alarm lamps blink), `padclick.wav` (a pad turning the corner
of its flight: a small latch, the armor ping's plate higher and shorter)
and `padclack.wav` (two pads docking: two latches over a thump). Borrows
`strike`, `finish` and `save` from `armor.py` beside it. Seeded. numpy.

### `tools/sounds/shelf.py`
Cuts the latch of a shelf (`bin/sounds/shelflatch.wav`, 3.0.51) out of a
take generated in Suno: the first of its three sounds, a heavy steel latch
striking twice with a low thud dying under it. Nothing is done but the
cut: the take's two channels averaged, its 48 kHz brought to the game's
44.1 kHz, `CutFrom` 0.060 to `CutTo` 0.800 s of it, the mean taken off
first (a low thud cut mid-swing leaves one), a fade in of `FadeIn` (2 ms)
and out of `FadeOut` (50 ms), the peak at `LatchPeak` (0.45 of full
scale - well under the crash: the shelf of a screen latches every few
seconds). `python shelf.py <take.wav> [path/to/bin/sounds]`; the take is
not in the repository. Borrows `SampleRate` and `save` from `armor.py`
beside it. numpy, scipy.

### `tools/fans/build_fans.py`
Builds `bin/sprites/ventilation.mset`, the art of `TFan`, from generated
pictures - rotors seen from the front in flat light, the guards in front
of them and a louver panel - found in a sources folder under the names in
`ROTORS`, `GUARDS` and `LOUVER_FILE`. `build` centers every picture on
its axis in one square (the measured centers and radii are in those
tables), mirrors a rotor generated leaning the wrong way, derives the
smear and the disc from each rotor, tears a blade off for the torn
variant, bakes a guard's cast shadow into the guard, cuts a plate around
its opening, makes it solid outside the opening and gives it a seam
along the border, paints the shaft back,
shrinks every picture to 512 / 256 / 128 / 64 px in premultiplied alpha
with the edge color bled outward, and packs the set. `measure` prints
the axis, the reach and the lean of the blades of a new rotor, and the
ring and the opening of a new guard. The same set byte for byte from the
same sources and library versions; the sources are not in the
repository. numpy, scipy, Pillow.

### `tools/tank/build_tank.py`
Builds `bin/sprites/tank-hull.mset`, the art of the tank's hull
(`Monsters.Hull`), from three generated pictures - the tank whole, the
same tank battle-worn, one wheel seen from the front in flat light -
found in a sources folder under the names in `WHOLE_FILE`, `DAMAGED_FILE`
and `WHEEL_FILE`. `build` cuts the worn tank by the frame of the whole
one, cuts the painted tyres out of both (ellipses - a painted tyre is
pressed against the ground - and everything below the belly), paints the
dark of the wheel wells (`chassis`) and the fenders' shade in the cuts of
the whole hull, moves the wheel's hub onto the tyre's axis, shrinks all
of it to `DENSITY` (6 px a screen unit: just past what a 4K screen
shows) in premultiplied alpha with the edge color bled outward, and
packs the set; it prints the points of the art in screen units. The
measured boxes, axles and radii are constants at the top; a denser
screen is `DENSITY` and a rebuild. The sources are not in the
repository. numpy, scipy, Pillow.

### `tools/cordon/build_cordon.py`
Builds `bin\sprites\cordon.mset` (3.0.62) from four ChatGPT pictures
that are not in the repository (`cordon-scan.png`, `cordon-cargo.png`,
`cordon-eye.png`, `cordon-turret.png`) and the iris of `boss1-disc.mset`:
the hull at 2.6 px a unit as it was generated, cut in three strips
(`hull-1..3`, 2045, 1064 and 1063 px - no texture over 2048 px), the first
cut on the seam of the sections; the eye, the iris and the turret
(`turretMount`, `turretGun`) at 6 px a unit. The points of every picture
are in `docs/mechanics/scenes.md`.

### `tools/medkit/build_medkit.py`
Puts the HD art of the medkit into `bin/sprites/medic.mset` from one
generated picture - the TeK case seen from the front on a clear ground:
`build <picture> <set>`. The set is read and written: the 2008 frames in
it are carried over byte for byte, and what the script makes is made anew
on every run. `build` puts the generator's alpha right (8 of 255 and below
is nothing, 250 and above is solid: the case stands at 253 and a veil of
1..5 lies around it), cuts the case by the box of its silhouette, sets it
in a square of a monster's cell (32 units to the 20 of the case's width,
centered, standing on the bottom edge), takes the cross out as a light
(what is green enough, the largest patch of it; white with the shape in
alpha), shrinks both to `DENSITY` (6 px a screen unit, 192x192) in
premultiplied alpha with the edge color bled outward, adds the clear frame
`gone` and writes the sequences: `alive` is `medkit` eight times, `death`
is `gone` eight times, the 2008 ones stay under `alive-2008` and
`death-2008`. It prints the box of the case and the box and the middle of
the cross in screen units. The source picture is not in the repository.
numpy, scipy, Pillow.

### `tools/duplet/build_duplet.py` (3.0.64)
Builds `duplet.mset` from one generated side view of the gun: `lying`
(the pickup's `picture` box) and `held` (the grip in the fist of the 2008
arm frame, a 48-unit square).

### `tools/dust/build_dust.py` (3.0.65)
Builds `dust.mset` from noise, not generated: long white strips, the dust
in the alpha, seamless across, clear at top and bottom.

### `tools/sounds/duplet.py`, `stonewake.py`, `stonefall.py`
The Duplet's shot (the 2008 shotgun slowed, doubled, over a sliding
thump); the moon stone's waking drone and its power-down with the rocks'
far blow - built as the cordon's hum is. Need numpy and `armor.py`.

### `tools/sounds/ram.py` (3.0.75)
The Ram's three sounds: `ramrumble.wav` - a 2 s loop with no seam (every
period a whole number of times in it, its noise shaped round the loop in
the frequency domain): the engine at 31 Hz, a 4 Hz throb, the cleats 13
times a second, the road; `ramhiss.wav` - the brake's clunk and the air;
`ramwhine.wav` - the pump of the mast climbing for 1.5 s and the clank of
the lock. Needs numpy, scipy and `armor.py`.

### `tools/cannon/build_cannon.py`
Builds `bin/sprites/tek-cannon.mset`, the art of the TeK wall cannon of the
gravel arena (`Game.Cannons`), from one generated picture - the cannon
seen from the side, facing right, at exactly 2:1 - found in a sources
folder as `cannon.png` (`SOURCE_FILE`): `build <sources dir> <set>`. It
scales the picture whole to `DENSITY` (6 px a screen unit, 384x192 for a
gun of 64 x 32 units) in premultiplied alpha, cuts the heat layer (the
barrels from where they leave the receiver) out of it, measures the
contact boxes from the alpha, and prints the points in screen units - the
muzzles, the lens and the boxes `Game.Cannons` holds as constants. The
measured points of the source are constants at the top. No text and no
emblem on the art: the right gun is the left one mirrored. The source is
not in the repository. numpy, scipy, Pillow.

### `tools/machine/build_machine.py`
Builds `bin/sprites/tek-machine.mset`, the art of the TeK machine, the
second level 2 boss (stage 8b of arena 3; nothing draws it yet), from five
generated pictures found in a sources folder under the names in
`WHOLE_FILE`, `DAMAGED_FILE`, `WHEEL_FILE`, `MAST_FILE` and `HEADS_FILE`:
`build <sources dir> <set>`. The hull is scaled by its height to 128
units (169 long), standing on the tip of the ram; the worn hull is mapped
onto the whole one's box and cut by its silhouette; the back half of the
mast well's dark is lifted into a layer of its own, and the dark of the
arches is laid behind the wheels; the wheel is resampled about the middle
of its box to the wheel's radius; the mast sections, the mortar and the
heads are cut by their boxes at their own scales (the widest section fills
the well, a head's socket sits on the top collar of `mast3`); the
sweeper's barrels are taken out white as a heat layer and the bunker's lid
is lifted off it. Everything is mirrored at the end - the machine faces
left and never turns - and the points are written into the descriptions
after the mirror. The measured points of the sources are constants at the
top of the file; the sources are not in the repository. numpy, scipy,
Pillow.

---

## Tests

The concept, the rules and the tables of tests are in `docs/TESTING.md`.
At 3.0.52 the suite was 376 tests, all green; the gravel arena
(3.0.53-3.0.59) brought 112 more - 488; the collision decks (3.0.60)
brought 8 - six in `Tests.Pads.Decks`, two in `Tests.Levels.Pads` (a run
of decks loads as one pad with no picture and is no wall; a bad collision
letter raises); the burst of the suit (3.0.61) brought 23 in
`Tests.Orbs.Burst` - 519; the scenes (3.0.62) brought 67, green on the
first run - 586, see below. After 3.0.62 (counted by `[Test]` methods
added): 3.0.63 - 13 in the new `Hud/Tests.Hud.GoRight` (the beat and the
arrow); 3.0.64 - the Duplet's picture in `Tests.Monsters.Defs`,
`Tests.Monsters.Bodies`; 3.0.65 - the dust in `Tests.Levels.Dynamics`;
3.0.66 - 8 in the new `Levels/Tests.Levels.Doors` (shutDoors refused or
kept, openDoor); 3.0.67 - the eclipse, the pace and the back ease in
`Tests.Levels.Dynamics`, heroStands in `Tests.Levels.Events`, jolt and
pace in `Tests.Levels.Scenes`, `shiftX` in `Tests.Levels.Entities`, the
eased flight in `Tests.Pads.Flights`, a grid deck in `Tests.Pads.Decks`;
3.0.69 - the takeover in `Tests.Scenes.Director`. 54 in all. 3.0.70 - 9 in
the new `Hud/Tests.Hud.Energy` (the reading of the gauge, the energy
action, the moon stone's 5) and 12 in the new `Orbs/Tests.Orbs.Feed`; their
tables are in `docs/testing/hud.md` and `docs/testing/orbs.md`. 3.0.71 -
the fall ease in `Tests.Levels.Dynamics` and 6 for the respawn action in
`Tests.Levels.Events`; their table is in `docs/testing/scenes.md`. Not every test unit has its
entry below yet: `Tests.Rooms`, `Tests.Monsters`, `Tests.Monsters.Defs`,
`Tests.Monsters.Hull`, `Tests.Monsters.Mount`, `Tests.Levels.Entities`,
`Tests.Levels.Pads`, `Tests.Levels.Carousels`, `Tests.Effects.Lightning`,
`Tests.Pads.Plunge`, `Tests.Pads.Shelf`, and the arena's new units
`Tests.Game.Trial` (the trial's sky, wave and middle medkits; the finale
and the sky events of the level), `Tests.Game.Press` and
`Tests.Pads.Stray` are told in `docs/TESTING.md` alone. 3.0.75 - 22 in the
new `Game/Tests.Game.Ram` (the entrance whole and from the stop, the legs
and the legs to a wall, the eye's blink and breath, the lens, the contact,
its pad rule, the throw straight up at a wall and the thrown hero out of
its way, the shield, the shield over a body, the ram action, the Ram of
level 2). 3.0.76 - 11 more there, a fixture of their own
(`TRamHunterTests`: the lives by the grade, the eye the only target, the
head blown up and the sweeper rising, the press to the wall and its held
fire, no press on a pad, the red lens before a burst, the rests between
bursts, the first shots at the hero, the turn past the vertical, the
hose of the last third), and 4 on the row of lives (none before the lock,
up a cell at a time before the first shot, following the lives, fading
with a dead head). 3.0.77 - 11 more, `TRamSweeperTests` (the lives by
the grade, the ride to the hero's row, the closed ceiling at the bottom
of the mast, the red barrels before a sweep, a sweep level along his row,
the whole pack hit from above and level, the plates taking a bullet from
below and a climbing one, the fork a cell away, the ladder, the turn, the
empty mast after the last life), and one in `TBodyShieldTests` (a strip
holds its row).

### `Tests/` - the test suite (console app, DUnitX)
Fourth project of `Moon2D.groupproj`. Tries what the game counts, not
what it draws: no window, and no SDL but the mixer the scene director's
sound bank opens, on the dummy audio driver. Game units come in through
the project's search path (`..\Core`, `..\Game`, `..\Game\Orbs`,
`..\Game\Pads`, `..\Game\Scenes`, `..\Hud`); the executable goes to
`bin\`.
- **`Moon2D.Tests.dpr`** (~70 lines) - the runner: every registered
  fixture, a verbose console log, the exit code (0 - green). A test that
  asserts nothing fails.
- **`Orbs/Tests.Orbs.Flock.pas`** (~320 lines) - **`TOrbFlockTests`**
  (17 tests):
  the life of an orb in a flock through its public face - the order of
  `Add` / `Insert`, aging, the three ends (`Implode`, `Spend`,
  `Release`), what `Tick` drops, `Shift`, `Clear`, and (3.0.49) the depth
  of a new orb and `Arrive`. A fixture registers
  itself in its unit's `initialization`.
- **`Tests.Matter.pas`** (~100 lines) - no fixture: the matter of a
  screen made by hand, for the orbs that are drawn out of it -
  `MatterFromRows` (the twelve rows of a screen, `#` solid, `.` open),
  `WalledMatter` (a room shut on every side), `EmptyMatter`, `SolidAt`.
- **`Orbs/Tests.Orbs.Harvest.pas`** (~340 lines) - **`TOrbHarvestTests`**
  (11 tests): `HarvestAround` - every wave its count, no spot twice, the
  matter at the hero's feet passed by, every wave from all sides, the
  nearer faces to the earlier waves, a wave ordered by its turn, thin air
  in an empty room and for what the matter is short of, a body
  harvested, `Away` and `Turn` from the center, the same dice - the same
  spots. `HarvestSpots`, the aura's harvest, has no test yet.
- **`Orbs/Tests.Orbs.Patterns.pas`** (~445 lines) -
  **`TOrbPatternsTests`** (11 tests): the names (the game's patterns are
  found by their words, an unknown word raises, a level file names its
  pattern), the snowflake (the rays behind and the hexagon in front, the
  seats apart and within reach, six rays, the hexagon walking against
  the turn) and the vortex (an arm to a wave, an orb goes round the
  hero, narrow at the feet and wide over the head, a seat leaps only
  with its light out).
- **`Orbs/Tests.Orbs.Rite.pas`** (~1620 lines) - **`TOrbRiteTests`** (41
  tests): the rite ticked with no window, mostly on a pattern and a score
  of the test's own - a grid of seats that stand still and a short score
  whose ticks are spelled: the events and the stages by the schedule, the
  count of orbs and where they are born, an orb armed only on its way to
  its seat, a pattern with no holes after a walk, a leap, a door and
  losses in flight, the stand-ins and their stock, the pattern's clock
  and the flash, the drawing into the body, death, a restart, and the
  suit shed as a ring; the ice score runs the game's two patterns to the
  suit.
- **`Orbs/Tests.Orbs.Burst.pas`** (~1055 lines, 3.0.61) -
  **`TOrbBurstTests`** (23 tests): the burst ticked with no window, the
  rays watched by their stretches alone - the bench joins every tick's
  stretches into the way of each head (`FlyOut`), and a stretch that
  begins where no head stood fails. The inhale and the one strike told;
  24 rays from the chest every 15 degrees, one straight up, all alike on
  every tick; a straight ray keeps its line, a vortex's curl one way and
  dying off; through matter and off the screen; a mark on each face a ray
  goes into, none in an empty room, the marks melting; the motes out of
  the points of the body (out of the chest with none), living a while;
  the rays leaving from the hero at the strike and not following him;
  `Clear`, `Start` over a burst in flight, the moon flying as the ice,
  the dice. The marks and the motes are read through `Marks` and
  `Motes`.
- **`Game/Tests.Game.Blasts.pas`** (~270 lines) - **`TBlastTests`**: the
  wave of `Game.Blasts` - a near body before a far one, a body struck
  once, none beyond the radius, a wall's shelter, the lives and the knock
  by the distance and the grade, and the barrel of monsters.json against
  the 50-life gunner of level 2.
- **`Game/Tests.Game.HeroOrbs.pas`** (~430 lines) - **`THeroOrbsTests`**
  (20 tests): `THeroOrbs` at its border, no SDL - the hero a point in a
  walled room (`Tests.Rooms`, `Tests.Matter`), his body no points, the
  targets the fixture's (a bullet or a monster everywhere or nowhere,
  every call counted); `Setup` zeroes the fixture's state, since one
  fixture runs every test. The corpse calls up nothing and is fed
  nothing, `CastAura` says whether it cast; the charge lands, stops at
  full counting what is on its way, a rewind gives back the charge of
  entry and keeps what was on its way at the door, a new level zeroes
  both, a fall takes what is on its way and keeps the rest; a fall and a
  rewind leave no armed orb, a door puts out the rain and keeps the aura;
  `TakesAt` spends an armed orb in reach and none out of it; an orb spent
  on a bullet wounds nothing, an orb on a monster wounds it; the burst
  holds the world through its inhale and wounds a monster once a burst,
  and again the next.
- **`Monsters/Tests.Monsters.Damage.pas`** (~235 lines) -
  **`TDamageWindowTests`**: the window alone - the cut at the cap, the slide
  of the window, no run of `Ticks` ticks over the cap, the hero's chain gun
  and grenade volley never cut; **`TCappedBossTests`**:
  `boss1` on one tick takes no more than the cap, and a blow over it still
  shoves him.
- **`Game/Tests.Game.Shroud.pas`** (~1410 lines) - **`THeroShroudTests`**
  (47 tests): the counting half of `Game.Shroud`, no SDL - a new shroud is
  still and dark, `Start` and the restart on the run, `Clear` and
  `LeaveMotes` against `Start`, the glow's peak, the own clock of a part of
  the body in each order, the strips' sides and their stop at home, the motes
  (born at the seeds only, mirrored, none without seeds, dying out, the
  sinking ones out of matter), the mist (one cloud per band of `IceOnLook`,
  born on the feet line, standing where the hero fell, sinking, settling,
  with no probe, dying by its own look's age), the dice (the same seed
  - the same run) and (3.0.50, nine tests) the fed light: a feed lights
  the body and starts no scene, the light fades by its keep every tick,
  a scene or none, and goes out altogether, feeds add up to a ceiling, the
  last feed sets the tint and the keep, `Start` and `LeaveMotes` keep the
  light and `Clear` puts it out, a feed changes nothing in a running
  shroud.
- **`Game/Tests.Game.Uptake.pas`** (~1660 lines) - **`TUptakeTests`** (41
  tests, 3.0.50): `CutCrumbs` and `TUptake`, no SDL - pictures painted by
  hand, texel by texel, the hero a pose with a few points of his frame,
  the matter a function, the dice seeded, the light a scene gives caught
  by the fixture. The cut (a full grid, no paint - no crumbs, a speck is
  no crumb, the middle of a crumb's paint, the tiling at any step, a short
  alpha refused); the plan of a scene (every crumb seated, no paint - no
  scene, a fuller cell - a bigger crumb, the center, the mirror); the
  leaving (whole while it fills, all gone when the crumbling is over, the
  two orders, a zero seed); the flight home (a point of the hero's frame,
  no points - the middle, the hero's look does not change the scatter,
  a hero who stands, runs away and leaps, the mirrored pose, twice the
  `Pulse` in all whatever tick a door comes, the spot and its ticks); the
  wreck (no feed, no spots, the fall and the floor); `Settle`, `Drop`,
  `Clear`, the clock, scenes side by side, no feed and no probe, the
  dice; and one test wires the uptake to a shroud as the game does.
- **`Monsters/Tests.Monsters.Bodies.pas`** (~350 lines) -
  **`TMonsterBodyTests`** (13 tests): what the floor does to a body, alive
  and dead - a lethal hit starts the dying and tells the game once, the
  corpse lies where it died and falls when nothing is under it, the patrol
  turns at a ledge's end and at walls, a walker with no edge check walks
  off, a body dropped above a ledge lands on it - and (3.0.50, two tests)
  `Collect`: a collected pickup is gone at once and tells the game once,
  and a later blow does not kill it again. The tests of `Collect` live
  here, not in the uptake's unit: a test unit mirrors its game unit.
- **`Pads/Tests.Pads.Decks.pas`** (~140 lines, 3.0.60) -
  **`TDeckTests`** (6 tests): a run of decks on row 8 of an empty room
  (`Tests.Rooms`, `LevelFromRows`) in a `TPadWorld` with no sprites and
  no cache - feet on the deck line are held and at the underside are not
  (`DeckUnder`), feet falling onto it are caught (`DeckCrossed`), feet
  rising from below pass through, a bullet stops in the body only - not
  above, below or beside it (`StopsBulletAt`), the deck cells are no wall
  to the level (`SolidAt`), and feet beside the run find no deck.
- The scenes (3.0.62; the tables in `docs/testing/scenes.md`,
  `pads.md` and `monsters.md`):
  - **`Levels/Tests.Levels.Scenes.pas`** - **`TLevelScenesTests`** (16):
    the parser over a root of JSON alone - at, after and delay, the plan
    and the sort, after looking only up, the aftermath, the spawn, the
    marks, the axes of a move, the wait, every word and member that does
    not load; **`TSceneLoadTests`** (7): the checks of the load through
    `LevelFromRows` and the cordon of `level1.json`.
  - **`Levels/Tests.Levels.Dynamics.pas`** - **`TCraftTests`** (12): a
    craft read by `ParseDynamic` and ticked by hand, seen by `CornerAt`
    alone - its place, its axes, the eases (the back and, 3.0.71, the
    fall by `EasedShare`), the corner between the
    ticks, `Rewind`, `HasFollower`, the parts that do not load; the
    looks of a beam.
  - **`Pads/Tests.Pads.Flights.pas`** - **`TPadFlightsTests`** (4): the
    straight flight of a scene; the plan's tests are designed only.
  - **`Pads/Tests.Pads.World.pas`** - **`TPadWorldTests`** (7): the
    dormant pad, a pad of no sprite in a world with no art - no floor and
    no body asleep, woken, flown at once and over ticks, its jets, its
    rider carried, rewound to sleep.
  - **`Monsters/Tests.Monsters.Bodies.pas`** - 7 more in
    **`TMonsterBodyTests`**: asleep, held (seen through the `nil` burst:
    a shot is an access violation), smitten, removed, stood, on a deck.
  - **`Scenes/Tests.Scenes.Director.pas`** - **`TSceneDirectorTests`**
    (19): a scene played over a stage made by hand - bodies from the
    level's entities put in a field of no art, pads of no sprite, a
    craft - the ticks of its cues, the wait, the end, leaving and dying
    before and after the end, once a life, the order of the rewinds, the
    takeover, the shake, the jolt, the tagged hands, the spawn, the
    sleeping pad. The bank is opened once, on the dummy
    audio driver.
  - `Tests.Rooms` grows `RoomFromRows(rows, sections)` (pads of no
    sprite in the room's level) and shows `Level` and `Pads`.
- **`run-tests.cmd`** (repository root) - builds the Debug configuration
  and runs it; exit code 0 / 1 (a red test) / 2 (the build failed).

---

## Runtime data (`bin\`)

### `config.json` (tiny)
Shipped defaults: `window` (width/height/fullscreen/vsync/fpsCap) + `game`
(tickRate, difficulty id, language id). Read by `Game.Config`, never written by
the game.

The player's layer, `%APPDATA%\Moon2D\settings.json`, has the same shape but
holds only the keys the player touched (difficulty, language, fullscreen - or
anything written in by hand) and overrides config.json key by key. It lives
outside the game folder: not in the repository, not in a release, kept when a
new release is unpacked over the old one.

### `monsters.json` (~15 KB)
Keys: `version`, `comment`, `defaults` (bound, spritesToDeath, animFreq, score,
dangerous - inherited by monsters), `monsters` array. The 16 ids to 3.0.63: `gravel`,
`gravelFemale`, `winter`, `zombieShooter`, `betoner`, `platform`, `tank`,
`mount`, `barrel`, `skyBarrel` (3.0.58: the barrel's art, lives, blast
and explosion, score 0, `weather` - the sky barrel of the gravel arena's
act 5), `medkit`, `weaponShotgun`, `weaponGrenade`, `weapon3`,
`weapon4`, `boss1`; since 3.0.64 `weaponDuplet` (a pickup giving weapon
type 5, `picture` 42 x 12) and since 3.0.67 `moonStone` (a pickup,
`anchored`, `invulnerable`, `picture` 24 x 37 turning in 20 s and
hovering 1.5) - 18 ids. Parsed by `TMonsterRegistry` into `TMonsterDef` (see
Monsters.Defs above for the full field sheet). Nine of the fifteen carry no
`spriteList` - theirs comes from the level placement instead. `explosion`
names the look of a death: `barrel` (the barrel), `machine` (the tank, the
platform), `boss` (`boss1`), `mount` (the mount, 3.0.48). `blast` (the barrel, the tank, the platform, the mount) is what the
death does to the bodies around: `radius` 80, `lives` 100 and `shardLives`
6 on all four - see `TBlastDef`. `material`: `metal` on the platform, the tank, the mount, the barrel
and `boss1` - a bullet throws sparks off them instead of bursting
(`Game.Impacts`). `disc` (only `boss1`) draws the living monster as a spinning disc out
of the layers of a set instead of its `alive` frames: `set`, `side`,
`muzzle`, `spin`, `irisReach`, `wearFull`, `portAngles` (the six gun
ports of the ring art: 0, 51, 129, 180, 231, 309) - see `TDiscDef`. Its
`boss` block names `dodgePrize`: `medkit`. `hull` (`platform`, `tank` and `mount`) draws
the living monster as a hull out of the layers of a set: the platform's -
`set` (`platform-hull`), `width` 40, `height` 20.33, `wearFull` 80, and the
points `eye`, `smoke`, `sparks`; the tank's (3.0.45) - `set` (`tank-hull`),
`width` 38, `height` 31, `wearFull` 80, the same points, `mirrors`: true,
`wheels` (`side` 16, `radius` 7.76, two `axles`) and `muzzle` (5.5, 5.4 -
the cut of the middle barrel); the mount's (3.0.48) - `set` (`mount-hull`),
`width` 36.5, `height` 32, `wearFull` 80, the same points (its `smoke` is read
and unused: the mount does not smoke) and `muzzle` (18.2, 30.2 - the middle of
the row of ports; the volley's row is centered on it) - see `THullDef`. Its
`attack` also carries `sentry`: `reach` 48 - see `TSentryDef`.
`stats.damageCap` (only `boss1`)
limits the lives he may lose: `lives` 30 in any `ticks` 33, a second - see
`TDamageCap`. The cap does not grow with the difficulty, as the lives do:
the hero's guns do not either.

### `level1.json` (~107 KB) / `level2.json` (~97 KB)
The unified level format, parsed by `TLevel`. Keys: `version`, `id`,
`title`/`titleEn`, `assetsDir`, **`spriteSets`** (the environment sets, in resolution order),
**`objectSets`** (optional: shared object art searched after the level's own
objects set, e.g. `["sky"]`),
`music`, `henshinPattern` (optional, 3.0.49: the word of the pattern the
orbs of the henshin build on this level - `snowflake` on level 1, `vortex`
on level 2; none - the game's default, `snowflake`; a word the game does
not know stops the load), `legacyTrailing` (a migration artifact, cleanup
pending), `grid`
(16x12), `backgrounds` (fromScreen + image + optional `tint`, three
percentages), `objects` (optional: sprite, screen, x, y, width in screen
units, optional `tint`, optional `tag`), `pads` (optional: sprite, screen,
x, y - the deck -, width in screen units, optional `tint`, optional `tag`,
`bullets` block / pass, block when absent, optional `path` - `route`,
`stops`, `speed`, `pause` -, `bob`, `plunge` - `delay`, `rest`, `rise` -,
`plunge` also `staysDown` -,
`shelf` - `out` and `in` or `program`, `slide`, `warn`, `offset`, `sink`,
`scale`, `tone`, `bank` (a name or a list), `held` -, `group`, `carousel` -
the carousel it rides, in place of `x` and `y` -, `stray` - `flock`,
`zone`, `wait`, in place of `x` and `y` - and `rig` - the rigs it wears;
see `Levels.Pads`),
`carousels` (optional, 3.0.52: `tag`, `screen`, `shape` oval / box,
`center` and `size` [x, y] in screen units, `corner`, `period` in
seconds, `turn` cw / ccw, `start`, `parked`, `speedUp`, `failing` - see
`Levels.Carousels`),
`padGroups` (optional: `tag`, `screen`, `zone` [left, top, right, bottom]
in cells, `pairs`, `farFlight`, `farShare`, optional `conductor`, `every`,
`alarm` and `parked` - the pads rebuilt together, see `Levels.Pads`),
`screenTriggers` (optional, 3.0.53: `screen`, `difficulty`, `triggers` -
the triggers of a screen no body carries, see `Levels.Defs`), `rigs`
(optional: named lists of dynamic objects with no place of their own, a
number of a part may be `{"spread": [from, to]}` - see `Levels.Rigs`),
`respawns` (optional: `screen`, `x`, `y` - the cell a pit and death
return the hero to, counted as an entity's - see `Levels.Defs`), `dynamics`
(optional: `kind`
(beacon / smoke / globe / sparks / fan / haze / lightning / graph / craft
/ beam), `screen`, `screens`
[first, last] or `parent` -
a static object's, a pad's, a monster's or a craft's tag -, `x`, `y`, optional `tint`, `tag`,
`layer`, `intensity`, `surge`, `turns`
(under a spinning parent), then the
kind's own properties - see `Levels.Dynamics`), `scenes` (optional,
3.0.62: `id`, `screen`, `once`, `cues` - each `at` or `after` (+
`delay`), `do` and what that cue reads -, `aftermath` - see
`Levels.Scenes`),
`tilePalette`
(sprite names in their 2008 file spelling - `level1\doom1.png`, `base1.png` -
or qualified `set:name` when two declared sets share a name; index N in
tiles -> palette[N-1]), `tiles` (`encoding` "csv-rows" and `emptyValue` -
informational, unread; `note`; `screens` - one object per screen: `screen`,
`rows` (12 strings of 16 comma-separated palette indices) and `collision`
(12 strings of 16 '0'/'1'/'2': 1 = solid - the grid `SolidAt` reads;
2 = deck, 3.0.60 - a run of them loads as a pad with no picture, see
`Levels.Defs`; any other letter fails the load)),
`entities` (placements:
monsterId, screen, x, y - or, since 3.0.52, `seat`: the tag of the pad it
sits on, in place of both -, spriteList, optional `difficulty` grades (parsed,
unused by both levels),
`overrides` (direction / speed / lives / canShoot / fireOffset), `triggers` -
messages/hints/changeMusic/heroX-heroY/gravelBoss (the gravels of one
act per difficulty) and `finale`,
optional `tag` for the events and the dynamics, optional `rig` - the rigs
the monster wears, which takes the tag (see `Levels.Rigs`); `secret` on one level-1
medkit is data nobody reads yet), `events` (each: `id`,
`screen`, `when` = enterScreen | allDead / enraged + `tag` | livesBelow +
`tag` + `lives` | actReached + `act` | gravelDealt / waveKilled + `act`,
`part`, `of` | trialDone, optional `delay` in ticks, `then` = a list of
`action` objects - bigMessage/smallMessage/hint with `text`/`textEn` (a
hint also `header`, `place`), music with `file`, intensity with
`target`/`value`/`ticks`, sun with `target`/`value` (degrees)/`ticks`,
tactics with `target`/`value`, rebuild and restore with `target`, and
the arena's: shelvesWake / shelvesSleep / shelvesProgram, flyIn,
medkitsOnto, waveOnto, cannons, spawn, breakCarousel, strays,
straysLeave, skyFall, press - see `Levels.Events`; the med lab hint,
`labHint`, is the plainest example), `introText`/`introTextEn`.
- level1: 17 screens, 145 entities, a 156-tile palette, 4 backgrounds - night
  (1-7), pre-dawn (8-11), `_black` for the fully tiled lab screens 12-13,
  sunrise (14-17); sets
  `brickwork mine-structure facility conveyor mining-rig railway mine-walls
  cargo mine-interior`. Objects: the ship on screen 1 (in place of the 2008
  shuttle), the broken satellite in the sky of 14-17, tagged `ship` and
  `satellite`. Pads: the 21 platforms of screens 16-17 (`s16-platform`,
  `s16-platform-out`; tagged `s16-plat-01`..`11` and `s17-plat-01`..`10`,
  bullets block) - static objects over solid cells before, the cells now
  cleared from the grid; the lamps hung on them keep the same tags. Since
  3.0.60 nine collision decks join them at load (17 cells '1' -> '2'):
  the balconies of screens 14 and 15, a beam on the left of screen 3, a
  ledge on the left of screen 4 - 30 pads in all. Every
  pad bobs: 1.5 on screen 16, 1 on screen 17. The ten pads of
  screen 17 (`s17-plat-01`..`10`) are the pad group `arena17`: zone
  columns 2-13, rows 4-8, two pairs, five flights of five cells or more,
  conductor `boss`, every 10 seconds, alarm `arena17Alarm`; the bottom
  pad in column 0 (`s17-plat-10`, row 10, outside the zone) flies in with
  the first rebuild (3.0.38) - no pad of the screen stands still. Two
  sets of screen 16
  travel, pingpong at speed 30 with a pause of 1: the trio
  `s16-plat-05`..`07` is a ferry - 64 units left, to x 64..128, docking
  by the ledge of columns 0-1, and back (a cycle of about 6.2 s);
  `s16-plat-09`/`10` a lift - 96 up to y 224 and back (about 8.4 s). The
  medkits on 05, 07 and 10 ride along.
  Dynamics: the Earth (a `globe`) in the sky of screens 1-17 - hidden by
  the tiles of the lab screens 12-13 - (tagged
  `earth`, at (392, 82), 38 across, Africa and Europe facing, night map
  `earth-night`, sun starting at -40 - three quarters lit on the left), a blue double-flash beacon on the ship's fin, a red
  faulty one with starburst rays on the satellite's antenna, three gusty
  gas leaks venting from the satellite's breach and a broken ring joint
  (vacuum: no lift, little drag), a fall of sparks from the breach
  (`sparks`, back layer, no collision: slow, far, fading on the way down,
  a small arc every couple of seconds; tagged `satelliteSparks`,
  intensity 0, spells of about 7 seconds with pauses of about 3), two
  smokes hung on the boss (tagged
  `boss`; `bossSmoke`, `bossBurn` with heat, front layer, intensity 0) and
  a spark source beside them (`bossSparks`, front layer, bouncing,
  intensity 0),
  four lamps on the boss's disc (`turns`, front layer, in the two sockets
  of the ring art: a blue pulsing pair `bossLamp` and a red flashing pair
  `bossLampRage` at intensity 0; halo 10 across with starburst rays of 24
  units - the satellite's are 36 - that reach past the rim: on the light
  disc a bare glow does not read), ten red alarm lamps `arena17Alarm`
  (a second beacon on each pad of the group, over the blue one: flash,
  5 a second, intensity 0 - the arena lights them to warn of a rebuild),
  six fans (`fan`) in the bays of the
  tower on screens 14-15, under `s14-tower` and `s15-tower`: 43.4 across,
  14 turns a minute counterclockwise, a dim cold light in the shaft; the
  bottom right one on screen 15 is `dying`, on the `heavy-torn` rotor.
  The thirteen TeK platforms - one on screen 7, one on 8, two on 10, four
  on 11, five on 13 - are tagged `s07-tek-01`..`s13-tek-05` (the screen,
  then the number on it) and wear the rig `tekPlatform`: two blue pulsing
  lamps on the hull (front layer, halo 5 across, intensity 70, 0.8-1.2
  blinks a second, each lamp its own roll) and a haze under each nozzle
  plate (downward, 28 long, 4 across widening to 14). The points count
  from the top-left corner of the cell: a point of the hull moved by
  (-4, 5.83).
  Events: the dawn, tied to the screens - on entering screen N
  (`dawn1`..`dawn17`) the sun heads over 20 seconds to -40 + 100 * N / 17:
  three quarters lit at the start, a half by screen 7, a crescent with
  the night side lit by cities on the last screen; the backdrops of 14-17
  paint the sunrise itself. On screen 12: `labHint` -
  allDead on the four `labGuard` bodies (two tanks, a female gravel, a
  betoner), 33 ticks later the med lab hint types out in the terminal.
  The satellite's sparks, staged by screen: smoke alone on 14-15, on
  entering 16 (`satelliteSparks16`, 40 ticks later) to 45%, on entering
  17 (`satelliteSparks17`) to 100%.
  On screen
  17: livesBelow 200 - bossSmoke to 60%; enraged -
  bossSmoke off, and (`bossRageLamps`) the blue lamps fade out, the red in,
  over 20 ticks, and (`bossRageSparks`) bossSparks light to 50%;
  livesBelow 45 - bossSmoke, bossBurn and bossSparks to 100%. The boss's
  tactics ride the same three moments (`bossSmokeTactics`,
  `bossRageTactics`, `bossBurnTactics`): dives while it smokes, rams in
  its rage, hunts once it burns; in the rage the arena is rebuilt too
  (`bossRageRebuilds`: rebuild `arena17`), and once the boss is dead the
  pads fly back to the level file's places (3.0.39,
  `bossDeadArenaRestores`: allDead of `boss`, 100 ticks later, restore
  `arena17`). The marks are those of the
  normal grade (400 lives: dives under 200, the rage under 120, hunts
  under 45) and grow with the difficulty - by 1.5 on hard, 2 on wild.
- level2: 9 screens, 36 entities, a 35-tile palette, 4 backgrounds - day
  (1), the chasm edge (2), rock (3-5), the same rock darker (6-9); sets
  `moon-surface machinery facility common mine-interior`. Object: the
  satellite on screen 1, lit a little brighter (day), tagged `satellite`;
  the Earth on screen 1 as level 1 left it, a thinner crescent (sun 70, no
  events); the satellite's lamp is `dying` - a dim fast flutter, the battery running out, and
  one leak is left, a puff now and then (`flow` puffs); the breach still
  sparks, at intensity 25 - a spark now and then. Two fans (`fan`: the
  `turbine` rotor behind the `bezel` plate over the `shaft` back, one
  cell each) stand where the 2008 tiles `cooler1`-`cooler4` stood on the
  floor of screen 3, at 150 turns a minute, with a `louver-2x1` object
  between them - the cells are empty in the grid and solid as before, the
  names stay in the palette; the fourteen on the ducts of screen 9 went
  with its repaint (3.0.54). The one TeK platform, on screen 6, is tagged `s06-tek-01` and
  wears the rig `tekPlatform` - the numbers of level 1, written again in
  this file's `rigs`. Screens 1-4 are repainted (`docs/REPAINT.md`).
  Screen 1 is the arena of level 1's screen 17 moved six cells left:
  its floor and crane as objects, twelve pads in the rigs `pad` and
  `padBroken` (written again in this file's `rigs`), one of them a
  ferry between x 288 and 352 at 30 units a second. Screen 2 is a pit:
  two still pads at the entry, three on paths of their own - sideways,
  up and down, and a diagonal that stops flush with the tunnel floor -
  and the object `tunnel-gate` at the far side; the gravel that carries
  the screen's title stands in the gate. Screen 3 is one object,
  `s03-room`, its tiles dark and its matter as it was, with three
  `heavy` fans behind `spider` guards hung on it: one of 100 units in
  the hall at 22 turns a minute, two of 53 turning against each other
  at 64 in the sealed chamber under the corridor. Screen 4 is
  `s04-room`, a corridor over a cargo shaft: the pit is three cells
  where 2008 had two (under that ceiling a jump carries the hero 72
  units), the one pad `s04-plat-01` stands in the middle of it (x 256)
  and plunges under the hero (3.0.46: `plunge` with delay 0.5, rest 0.5,
  rise 64; a ferry between x 224 and 288 before), and the
  two crates, a cell to the right of where they stood, are the object
  `s04-tek-crates` over their solid cells. The pad is the picture
  `s16-platform-out` in the rig `padFailing`: the haze of the rig `pad`
  and, lifted by the pad's effort (`surge` 100), a red `flash` beacon
  that is dark at rest (intensity 0) - the tell of the pad that falls,
  which `padBroken` has not -, the blue jet of `pad` at intensity 15, the
  dark puffs of `padBroken` at 60 and sparks from its side, which pass
  through its own body (`collide` none). `tunnel-gate`, `s03-room`,
  `s04-room` and `s04-tek-crates` are the level's own art, the set
  `level2-objects`. Screens 5 and 6 are repainted too (the rooms of the
  TeK mount; `docs/PORTING-NOTES.md`). Screen 7 is `s07-room`, joined
  from several generations, its tiles cleared and its matter as it was
  but one floor cell (column 6, row 10, under the shaft) taken out; the
  crates are objects of the earlier screens (`s07-pile` of `s02-crates`
  with `s07-pile-top`, `s07-stash` of `s04-tek-crates`), a `dying` beacon
  on the room. A still pad `s07-plat-01` hangs at the first descent on
  the right, so the player learns one may jump down from a pad. In the
  hole stands the first shelf (3.0.51), `s07-shelf-01` - the picture
  `shelf` of the set `pads`, which the level declares in `objectSets`:
  out 2.5 s, in 1.5 s, slide 0.25, warn 0.6, sink 7, scale 0.72, tone 0.4
  - 82 ticks out (the last 20 warning), 8 going in, 50 in, 8 going out,
  148 a lap. Behind it the dock, the object `s07-shelf-dock` (`shelf-dock`,
  tinted 55, a unit under the floor line so its plank is not read as a
  deck); on the shelf the rig `shelfDock` - a red `flash` beacon dark at
  rest (intensity 0) and lit by the shelf's warning (`surge` 100); it stays
  on the dock while the shelf goes in. Screen 8 (3.0.52) is a hall with a
  carousel in its middle: `s08-room` (the set `level2-objects`), its
  tiles cleared and its matter new - the hero comes in on a ledge at the
  top left (respawn column 1, row 4), the floor of row 11 is a pit from
  column 2 to 13, the way out at the bottom right. Over the pit twelve
  shelves stand side by side as the floor, `s08-shelf-01` to `-12` (x 64
  to 416, deck 352), each in its dock (`s08-shelf-dock-01` to `-12`,
  tinted 55) and wearing `shelfDock`: out 2.6 s, in 1.5, slide 0.25, warn
  0.6, sink 7, scale 0.72, tone 0.4 - 86 ticks out, 8 going in, 50 in, 8
  going out, 152 a lap; three by three they take turns (`offset` 0 and
  2.3 - 76 ticks, half a lap). In the air eight pads `s08-ride-01` to
  `-08` (`s16-platform`, 32 wide, `bullets` pass, `bob` 1, the rig `pad`)
  fly round `s08-carousel` - an oval of 150 by 150 round (288, 179), a lap
  in 12 s (396 ticks), clockwise; the decks go from 104 to 254 down. No
  wheel, no rim, no pylon: the pads fly the round on their own thrust.
  The nine barrels of 2008 are gone; on every pad sits a monster (`seat`):
  betoners on `-01` and `-05` (speed 0; the first keeps the `heroY` 4
  trigger of the 2008 first barrel), barrels on the rest (direction 1).
  A `dying` beacon on the room. Screen 9 is the gravel arena
  (3.0.53-3.0.59; the whole design and the data act by act are in
  `docs/mechanics/arena-2.md`): `s09-room` (the ChatGPT room with the violet
  ceiling grating), `s09-doorstep` (the left slab, cols 0-1 of row 11 -
  the only solid floor; respawn column 2, row 11), `s09-lamp-off` with a
  `dying` beacon, and a `shelf-dock` behind every shelf (49 objects in
  all). The trial's triggers are a screen trigger (`changeMusic`
  `boss2.ogg`, `heroX` 1, `gravelBoss` 15 / 25 / 40, `finale` betoner
  10 / 15 / 20 alive 3); the three trial medkits of 2008 are gone. 57 pads:
  46 shelves held at the start in their banks - `s09-floor` (14, row 11
  cols 2-15) with its subsets `s09-isle`, `s09-grid`, `s09-gaps`,
  `s09-wall` (row 9 cols 1, 14), `s09-foot` (row 9 cols 2-3, 12-13),
  `s09-ladder` (row 7 cols 4-5, 10-11), `s09-crown` (row 5 cols 6-9),
  `s09-pyramid` (the ladder and the crown), the press rows
  `s09-press-1..3` (rows 3, 5, 7, cols 1-3 and 12-14) and `s09-press-4`
  (the wall and the foot), all 24 of the four also `s09-balcony` -; eight
  pads `s09-ride-01..08` on `s09-carousel` (a box round (256, 232), 224 by
  112, corner 24, 15 s a lap, parked above, speed-up 3 s, bullets block,
  breaking into `s16-platform-out` / `padFailing` with a plunge that
  stays down), the two medkits of act 4 seated on `-03` and `-07`; three
  strays `s09-stray-01..03` of the flock `s09-strays` (zone [4, 3, 11,
  8], waits 0, 1.5, 3). Twelve events run the six acts: `s09-act1` ..
  `s09-act6` (actReached), `s09-act3-cannons` (200 ticks into act 3),
  `s09-act4-tek-upper` / `-lower` (gravelDealt: the two TeK-K10 platforms,
  tagged `s09-tek-01` / `-02`, wearing `tekPlatform`), `s09-act6-tanks`
  and `-tanks-2` (waveKilled 1 of 2: two tanks from each side, the second
  pair 66 ticks later), `s09-done` (trialDone: every balcony slides in
  sparing the hero, the strays leave). There is no boss monster; the
  victory track plays at the end and the level goes on - the second boss
  of level 2 comes on the screens after it (not yet built).
- After the arena (3.0.63-3.0.69, `docs/mechanics/arena-3.md`): `"shutDoors":
  [9, 10, 11]`. Screen 9: `s09-tunnel-music` (victoryEnds, lead 5: music
  `lunar.ogg` fading in over 5 s) and `s09-go-on` (victoryEnds: openDoor).
  Screen 10 - a layered tunnel with `dust` and a pedestal (`s10-pit-lip`):
  the Duplet lies on it (`weaponDuplet`, tag `s10-duplet`), `s10-door`
  opens on its taking (allDead). Screen 11 - the moon stone (`moonStone`,
  tag `s11-stone`, `shiftX` 16) over `dust` and two `eclipse`s (`s11-void`,
  `s11-wave`); `s11-shuttle` (enterScreen: the shuttle's hint),
  `s11-wake` (heroStands 8, 8: scene `s11-wake`, once a level - the music,
  the hum, the dust stilled, the dark wave, the rocks `s11-rock-block`,
  `-chunk`, `-shard`, `s11-step` woken and flown up with jolts),
  `s11-door` (allDead on the stone: openDoor and scene `s11-fall`, once a
  life - the risen rocks drop back, 3.0.69, in a free fall at the hero's
  pull since 3.0.71, the music no longer ducked; energy 5, 3.0.70; respawn
  13, 6 - the checkpoint by the stone, 3.0.71). Respawns on 9, 10 and 11
  at column 2, row 11.

### `sprites\*.mset` (48 sets)
Since 3.0.62: `duplet` (3.0.64 - `lying`, the pickup on its pedestal, and
`held`, the gun in the hero's hands; `tools/duplet/build_duplet.py`),
`dust` (3.0.65 - the white bands of the tunnel dust;
`tools/dust/build_dust.py`), `moonstone` (3.0.67 - the moon stone; no
build script in the repository); `level2-backdrops` and
`level2-objects` grew the tunnel screens 10 and 11.

- **Hero and weapons**: `hero` (the walk/death/henshin sequences),
  `weapon` (held gun frames, bullets, crosshair),
  `weapon1`-`weapon4` (the pickups: 2008 frames; since 3.0.50 their
  `death` frames are never drawn either, and with no `light` sprite in the
  set a weapon that lies is lit by the halo of its own silhouette).
- **Entities**: `gravel`, `gravel2`, `vinter`, `shoot1`, `betoner`, `barrel`,
  `medic`, `krep`, `platform`, `tank`, `boss1` - referenced by a placement's
  `spriteList`, still spelled `<stem>.mns`. All frames are 64x64, 2 px a
  unit, but in two sets. `barrel` carries the HD sprite `barrel` (128x128,
  4 px a unit; its `alive` is that one frame eight times over) beside the
  2008 frames `boch1`-`boch4` (the `alive-2008` sequence, which nothing
  asks for). `medic` (3.0.50) carries `medkit` (192x192, 6 px a unit: a
  TeK case of 20 x 16 units standing on the bottom edge of the cell; its
  `alive` is that one frame eight times over) and `light` (the cross of
  the case alone, white with the shape in alpha, in the same 192x192
  frame; the build script puts the middle of its box at 16.00, 25.25
  units from the frame's corner, the game measures the middle itself,
  weighed by alpha - about 16.02, 25.32; no sequence names it,
  `Game.Uptake` finds it by its name and lights it)
  beside the 2008 frames `1`-`5` and `d1`-`d8` (`alive-2008` and
  `death-2008`, which nothing asks for); its `death` is the clear 64x64
  frame `gone` eight times over, loaded for the `TAnimSet` contract and
  never drawn - a pickup that is not alive is not drawn. Built by
  `tools/medkit/build_medkit.py`.
- **Disc layers**: `boss1-disc` (`rim`, `rimDamaged`, `core`, `coreDamaged`,
  `iris`, `gloss`; 144x144 each - 4 px per screen unit, a 36-unit square -
  every layer centered on the rotation axis, transparent pixels filled
  with the edge color) - named by `disc.set` in monsters.json, drawn by
  `Monsters.Disc`. `boss1` keeps its eight `alive` frames only for the
  `TAnimSet` contract.
- **Hull layers**: `platform-hull` (`hull`, `hullDamaged`; 240x122 each - 6 px
  per screen unit, a 40 x 20.33 unit hull - transparent pixels filled with
  the edge color) and `tank-hull` (3.0.45: `chassis`, `hull`, `hullDamaged`,
  228x186 each - a 38 x 31 unit hull, the wheels cut out of both hulls -
  and `wheel`, 96x96, 16 units; the same density and edge fill; built by
  `tools/tank/build_tank.py`) - named by `hull.set` in monsters.json, drawn by
  `Monsters.Hull`. `platform` keeps its flight frames `plat1`-`plat3` and
  `tank` its drive frames `tank1`-`tank3` for
  the `TAnimSet` contract.
- **The TeK wall cannon** (3.0.56): `tek-cannon` - `hull` (the cannon
  whole, facing right, the lens unlit) and `heat` (the barrels alone,
  white, their shape in alpha), 384x192 each, 6 px a unit, a 64 x 32 unit
  gun; built by `tools/cannon/build_cannon.py`, read by `TCannonArt` of
  `Game.Cannons` (no monster, so no `hull` entry in monsters.json).
- **The TeK machine** (2026-10-26, art only): `tek-machine` - the second
  level 2 boss, 6 px a unit, facing left for good (mirrored when packed).
  Back to front: `well`, `chassis`, `wheel` (twice, radius 20.5), `mortar`,
  `mast3`, `mast2`, `mast1`, `hull`, `hullDamaged` (each hull layer
  1014x768, a 169 x 128 unit machine), then a head on `mast3`: `hunter`
  with `hunterBarrel`, `sweeper` with `sweeperHeat`, `bunker` with
  `bunkerLid`. The points are in the descriptions. Built by
  `tools/machine/build_machine.py`; the plan is in
  docs/mechanics/arena-3.md.
- **Death frames of what blows up** (3.0.42): in `barrel`, `tank`,
  `platform`, `krep` and `boss1` the `death` sequence is the empty frame
  `e8` eight times - the body vanishes in the tick it dies, and what the
  death looks like is `Game.Explosions` alone. The painted cloud of 2008,
  `e1`-`e7`, stays in each set as the `death-2008` sequence, unused, until
  frames of metal falling apart take the `death` name. No code knows of
  it: `TMonster.Draw` plays `death` as for any monster.
- **Tile themes**: `brickwork`, `cargo`, `common`, `conveyor`, `facility`,
  `machinery`, `mine-interior`, `mine-structure`, `mine-walls`, `mining-rig`,
  `moon-surface`, `railway` - grouped by subject, not by level, because levels
  share tiles.
- **Backdrops**: `level1-backdrops`, `level2-backdrops` - found by the
  `<assetsDir>-backdrops` convention, never declared in `spriteSets`. HD
  since 3.0.11: 1440x1080 (4:3, the playfield of a 1080p screen 1:1), drawn
  linear-filtered and tinted per change; `_black` stays a 512x512 fill.
- **Objects**: `level1-objects` (`ship`) and `level2-objects`
  (`tunnel-gate` and `s04-tek-crates`, 6 px a unit; `s03-room`,
  `s04-room` and the rooms of the screens repainted after them up to
  `s09-room` - 3.0.54 -, whole screens at backdrop density, with
  `s09-doorstep` and `s09-lamp-off`) - the `<assetsDir>-objects` convention, never declared,
  optional. Shared:
  `sky` (`earth`, `earth-night`, `satellite`), declared by both levels in
  `objectSets`. The ship and the satellite are drawn at backdrop density
  (1440 px per
  512 units), transparent pixels filled with the edge color so the linear
  filter leaves no dark fringe; `earth` and `earth-night` are 1024x512
  equirectangular globe maps for `Render.Globe`. Declared the same way:
  `level1-structures` and `train` (the art of the repainted level-1
  screens) and `ventilation`, declared by both levels - the fans of
  `TFan`: the rotors `rotor-heavy` (five blades), `rotor-heavy-torn` (one
  of them torn off) and `rotor-turbine` (eight), each with its `-smear`
  and `-disc`; the guards `guard-spider` (a ring on four struts) and
  `guard-bezel` (a square wall plate with a round opening), both carrying
  their own cast shadow; the back `back-shaft`; every picture at 512,
  256, 128 and 64 px as `<picture>-<side>`. Squares centered on the
  rotation axis: the spider ring reaches 95.5% of the half-side on average
  and 96.5% at its widest, the bezel plate fills the square like a tile,
  and the blade tips of either rotor (90.6% and 88%) end under the ring
  of either guard. Beside them `louver-2x1` (256x128) - a blind louver
  panel for a static object, 64 by 32 units. `pads` (3.0.51, declared by
  level 2) - the art of the pads and their kin, shared by every level, 6
  px a unit: `shelf` (192x68, 32 units wide) and `shelf-dock` (228x132, 38
  units wide, the lamp glass painted off - a beacon is its light). The
  pads before it, `s16-platform` and `s16-platform-out`, still live in
  `level1-structures`.
- **The cordon** (3.0.62): `cordon` - the TEK-Q6 over level 1's screen
  9, declared by level 1 in `objectSets`: `hull-1..3` (the hull in three
  strips, 2.6 px a unit), `eye`, `iris`, `turretMount`, `turretGun` (6 px
  a unit); built by `tools/cordon/build_cordon.py`, drawn as a `craft`.
- **Interface**: `ui` - `sky` (16:9 nebula), `moonmap` (2048x1024 lunar
  surface), `logo` (letters alone), the language flags (240x160) and the
  `font`/`fontx`/`fonty` atlases plus `fonty-2008` (the original 448x448
  atlas, kept, unreferenced). Stars, halo and embers are generated.

### `lang/en.json` / `lang/ru.json` (~2-3 KB)
Flat key->string dictionaries for UI and gameplay text (every `S*` key of
`Localization.pas`): tickers, streaks, henshin/bonus, ending screen, the full
menu vocabulary. Level and monster content is NOT here - it is localized in
place in the level and monster JSONs via the base-field + `En`-sibling pattern.

### `sounds/` (36 WAV, 1 OGG) and `music/` (OGG)
One-shots are preloaded at startup and fail loudly when a file is missing;
music loads leniently. Four one-shots are synthesised by
`tools/sounds/armor.py`: `armor1..3.wav` and `ricochet.wav`; a fifth,
`crash.wav`, by `tools/sounds/crash.py`; three more - `padhum.wav`,
`padclick.wav`, `padclack.wav` - by `tools/sounds/pads.py`; `shelflatch.wav`
is cut from a Suno take by `tools/sounds/shelf.py`. The cordon's
(3.0.62): `cordonhum.wav` and `cordonburn.wav` by `tools/sounds/cordon.py`
and `cordonburn.py`, and `cordon.ogg` (Suno, "The Descent") - the scene's
music, played as a sound: the music stream is one, and the level's track
fades under it. Tracks named by code: `moon.ogg` (menu,
`MenuMusicFile`), `win.ogg` (`VictoryMusicFile`). By data:
`moon_surface.ogg` (level 1), `underground.ogg`, `moon_surface2.ogg`,
`boss1.ogg`, `boss1b.ogg` (the boss's `rageMusic`), `hallu.ogg` (level 2),
`under01.ogg`, `boss2.ogg`, `lunar.ogg` (3.0.63 - the tunnel's, fading
in as the victory track ends; `win.ogg` is decoded whole and played as a
held sound since then). Eleven OGG files, all used. 3.0.64: `duplet.wav`
(`tools/sounds/duplet.py`, from the 2008 shotgun); 3.0.67:
`stonewake.wav`, `stonefall.wav` (`tools/sounds/stonewake.py`,
`stonefall.py` - the drone of the stone waking and powering down);
3.0.75: `ramrumble.wav`, `ramhiss.wav`, `ramwhine.wav`
(`tools/sounds/ram.py`) and `boss3.ogg`, the track of the Ram's fight -
twelve OGG files.

---

## Quick task-routing table

| Task smells like... | Look at |
| --- | --- |
| Hero movement / collision / jump feel | Hero.pas |
| The way on after arena 2: the victory track's end, the tunnel music fading in, the go-right arrow | `events` of screen 9 in level2.json (victoryEnds, music with fade, goRight / openDoor) + Levels.Events.pas + Events.Director.pas (`VictoryLeft`, `GoRight`) + Hud.GoRight.pas + Audio.pas (`LoadTrack`, `PlayTrackHeld`, `SecondsOf`, `PlayMusic` fade) + Game.Moon.pas (`PlayVictoryTrack`, `FVictoryLeft`, `FGoRight`) + Tests.Hud.GoRight.pas (+docs/mechanics/arena-3.md) |
| The boss arena of level 2 (screen 13): the tunnel music faded to silence and the boss track on the Ram's lock (3.0.75; the hand-over of 3.0.74 before it), the city road on 12 and 13, the far ledge, convoys and searchlight of 13, the city pads in the set | `events` of screen 13 in level2.json (the `ram` action with fadeOut and file - Game.Ram) + `sealedDoors` + Levels.Defs.pas (`CheckShutDoors`) + Levels.Events.pas (`FadeOutSeconds`) + Events.Director.pas (`TChangeMusic`) + Audio.pas (`HandOverMusic`, `Tick`) + Game.Moon.pas (`ChangeMusic`) + level2-objects.mset (`tek-road-tile`, `city-pad`, `city-pad-long`) + level2-backdrops.mset (`screen13`) + Tests.Levels.Events.pas, Tests.Levels.Doors.pas (+docs/mechanics/arena-3.md) |
| A screen whose way on is shut until an event opens it, or sealed for good | `shutDoors` / `sealedDoors` + an `openDoor` event in level JSON + Levels.Defs.pas (`DoorShutOn`, `CheckShutDoors`) + Game.Moon.pas (`FDoorOpened`, `HandleScreenTransitions`) + Tests.Levels.Doors.pas |
| The Duplet: the double-barrel, its red shot, a pickup wider than a cell | Hero.pas (`DupletWeapon`, `FireDuplet`) + Bullets.pas (`TBulletLook`) + Monsters.Defs.pas (`TPictureDef`) + Monsters.pas (`PictureBox`) + Game.Uptake.pas (`PictureOf`) + Render.Sprites.pas (`DrawRotated` side) + monsters.json `weaponDuplet` + duplet.mset (tools/duplet) + tools/sounds/duplet.py |
| The tunnel dust, its light | `dust` in `dynamics` + Levels.Dynamics.pas (`TDust`, `TDustLight`, `TDustBand`) + dust.mset (tools/dust) + Tests.Levels.Dynamics.pas |
| The moon stone: its picture that turns and hovers, its dark, its waking and the fall of the rocks | monsters.json `moonStone` (`anchored`, `invulnerable`, `picture` turn / hover) + `eclipse` in `dynamics` + scenes `s11-wake`, `s11-fall` of level2.json + Levels.Dynamics.pas (`TEclipse`, `PaceTo`, `meBack`) + Levels.Scenes.pas (`ckJolt`, `ckPace`, fly `ease`) + Scenes.Director.pas (`TakeJolt`, `TakeOver`) + Pads.Flights.pas (`EasedFlight`) + Monsters.pas (`DrawPicture`) + Game.Moon.pas (`HeroStandsIn`) + tools/sounds/stonewake.py, stonefall.py |
| Lightning: bolts that short across panels, wrecks and the satellite | `lightning` in `dynamics` + Levels.Dynamics.pas (`TLightning`) + Effects.Lightning.pas (`TBoltField`) + Tests.Effects.Lightning.pas (+docs/mechanics/lightning.md) |
| Pads - platforms apart from the grid: decks, the drop through one (S/Down), what a body stops, a lamp hung on one; paths, the bob and the sag, riding; the ram's knock; the collision decks ('2' in `collision`) | `pads` in levelN.json + Levels.Pads.pas (model, parser) + Levels.Defs.pas (`AddCollisionDecks`) + Pads.World.pas (decks, bodies, picture; paths, bob and sag - `Tick`, `Lift`, `Press`; riding - `DeckCarrying`; the knock - `Shove`, `RoomFor`, `Knock`, `Tilt`) + Monsters.Pilot.pas (`TPilotCrash.Blow`, `LapHolds`) + Hero.pas (`DeckUnderFeet`, `RideDeck`, `LandOnDeck`, `DropThroughDeck`, `DeckLift`) + Monsters.pas (`FloorAhead`, `StandsOnDeck`, `RideDeck`, `MoveFalling`, `DeckLift`) + Monsters.Pilot.pas `Walled` + Game.Moon.pas `BulletStruckWall` / `LocateParent` (+docs/mechanics/pads.md for the plan) |
| A pad that plunges under the hero: how long it holds, how it falls, lies below and climbs back; its twitch, its uneven jets and the red lamp; where it may stand | `plunge` on a pad + the rig `padFailing` in levelN.json + Levels.Pads.pas (`TPadPlunge`, `ReadPlunge`) + Pads.Plunge.pas (`TPlungeCycle`: `Tread`, `Tick`, `Fall`, `Climb`, `TickTwitch`, `Effort` and the constants) + Pads.World.pas (`FPlunge`, `Tread`, `Effort`, `PlungeDepth`, `Lift`) + Hero.pas `LandOnDeck` + Levels.Defs.pas (`CheckPadPlunge`, `RespawnHasFloor`) + Game.Moon.pas (`LocateParent`, `HandlePitFall`, `PitDepthY`) (+docs/mechanics/pads.md, stage 8) |
| A shelf that slides out of its wall and back in: its program, the slide, the warning lamp, the latch's sound, the hero falling off it; where it may stand | `shelf` on a pad + the object `s07-shelf-dock` + the rig `shelfDock` in level2.json + Levels.Pads.pas (`TPadShelf`, `TShelfStep`, `TPadDeepLook`, `ReadShelf`) + Pads.Shelf.pas (`TShelfCycle`: `Build`, `Holds`, `Warns`, `Latches`, `Depth`) + Pads.World.pas (`FShelf`, `Behind`, `Depth`, `RigDepth`, `Effort`, `Press`, `FBodyDepth`, `DeckWithdrawn`, `HearShelves`, `Draw`) + Hero.pas (`RideDeck`, `LoseDeck`, `ShoveX`) + Levels.Defs.pas (`CheckPadShelf`, `RespawnHasFloor`) + Game.Moon.pas (`LocateParent`, `ShelfLatchSoundFile`) + pads.mset + tools/sounds/shelf.py (+docs/mechanics/pads.md, stage 9) |
| A scene - a play on one screen while the player keeps the controls: its timeline (at, after, delay, wait), its cues (sound, music, shade, shake, move, track, aim, intensity, hint, hold, kill, spawn, release, remove, wake, fly), its aftermath, once a level or a life, what a death or a door does to it; the craft and its beams; the cordon over level 1's screen 9 | `scenes` + `dynamics` (`craft`, `beam`) + `dormant` on a pad + the action `scene` of an event in level1.json + Levels.Scenes.pas (model, parser) + Levels.Defs.pas (`CheckScenes`, `CheckSceneCue`, `CheckDormantPads`, `CheckCraftAhead`) + Scenes.Director.pas (`Start`, `Tick`, `PlayDue`, `Due`, `Play`, `Finish`, `ReArm`, `Rewind`) + Levels.Dynamics.pas (`TCraft`, `TBeam`, `TAxisMotion`, `TLightning.PointAt`) + Render.Dynamics.pas (`TPlace.Craft`, `OriginOf`) + Pads.World.pas (`Wake`, `FlyTo`, `Dormant`) + Pads.Flights.pas (`StraightFlight`) + Monsters.pas (`Held`, `Dormant`, `Smite`, `Stand`, `Vanish`, the field's tagged hands, `SpawnStanding`) + Audio.pas (`PlayHeld`, `SetMusicLevel`) + Game.Moon.pas (`FScenes`, `SceneStage`, `LocateParent`) + cordon.mset (tools/cordon/build_cordon.py) + tools/sounds/cordon.py, cordonburn.py + Tests.Scenes.Director.pas, Tests.Levels.Scenes.pas (+docs/mechanics/scenes.md) |
| A carousel: pads flying round a track - its shape, size and pace, the slots of its pads, where each starts; a monster seated on a pad; where a carousel may turn | `carousels` + `carousel` on a pad + `seat` on an entity in levelN.json + Levels.Carousels.pas (`TCarousel`, `TCarouselTrack`: `BuildOval`, `BuildBox`, `PointAt`; `TCarouselOrbit`: `Build`, `Place`; `OrbitOf`, `LapTicks`, `ParseCarousels`) + Levels.Pads.pas (`TPadPlacement.Carousel`, `ReadPlace`) + Levels.Defs.pas (`PlaceCarouselPads`, `CheckCarousels`, `CheckCarouselPad`, `CheckCarouselPair`, `RoomClear`, `SeatEntity`, `ReadEntityCell`, `RespawnHasFloor`) + Pads.World.pas (`FOrbit`, `PlaceOnOrbit`, `Rewind`, `Travels`) + Monsters.pas (`TMonster.Create`) (+docs/mechanics/pads.md, stage 10) |
| The arena rebuild of a boss fight: which formations play, how the pads fly and avoid one another (and the conductor's body, and the ground outside the zone), the depth, the wave behind the boss, the warning, how often, the sounds; the calm restore of the pads after the boss dies and its ripple | `padGroups` + the `rebuild` / `restore` events + the alarm beacons in levelN.json + Pads.Formations.pas (dice, judge, assignment) + Pads.Flights.pas (the L, `TFlightPace`, `TFlightBrief`, `TFlightBar`, the plan, deep flights) + Pads.World.pas (`RequestRebuild`, `RequestRestore`, `TryPlanRebuild`, `TryPlanRestore`, `FlightBarOf`, `TickFlight`, `Depth`, `HearFlights`) + Pads.Arena.pas (phases, `ReleaseOf`, `LapBars`, `RippleOf`, `WarningTicks`) + Monsters.Pilot.pas (`HoldLap`, `LapAhead`) + Hero.pas `JumpReach` + Events.Director.pas (`TArenaCues`) + Game.Moon.pas (`FArena`, `HeroRides`, `DebugRebuildPads` - the R debug key, `DebugRestorePads` - Y) + tools/sounds/pads.py (+docs/mechanics/pads.md) |
| The boss's rage: when it starts, how fast the gun fires in it; when the aimed gun is silent | Monsters.pas (`BossRageLives`, `BossRageFireRate`, `ProcessBossThresholds`, `AnyTaggedLivesBelow`) + Monsters.Pilot.pas `GunHeld` + the `livesBelow` / `enraged` events of level1.json |
| Weapon patterns / crosshair | Hero.pas (+Bullets.pas) |
| Monster behavior / AI / boss | Monsters.pas + Monsters.Defs.pas + monsters.json |
| The boss's flight: the lap, the maneuvers (ponder, dive, ram, stun), their numbers | Monsters.Pilot.pas (+Monsters.pas `MoveFlying`, `FirePorts`, `EyeTarget`; the `tactics` events of level1.json; `portAngles` / `dodgePrize` in monsters.json; Game.Moon.pas `ThrowCrashSparks`, `PayDodgePrize`; tools/sounds/crash.py) |
| The boss's disc: layers, spin, eye, wear, the shot from the rim | Monsters.Disc.pas + `disc` in monsters.json + `boss1-disc.mset` (+Monsters.pas `TickDisc`, `FireAt`) |
| The hulls of the platform and the tank: layers, wear, eye, wheels, mirroring, where a hull stands, where its straight shot leaves, the wreck points | Monsters.Hull.pas + `hull` in monsters.json + `platform-hull.mset`, `tank-hull.mset` (+Monsters.pas `TickHull`, `HullStand`, `BodyPoint`, `FireAt`; Render.Sprites.pas `DrawSized`; tools/tank/build_tank.py makes the tank's set) |
| The platform's lamps and the haze under its nozzles; what goes out when a monster dies | the rig `tekPlatform` + `"tag"` and `"rig"` on the platforms in levelN.json + Levels.Rigs.pas + Levels.Dynamics.pas (`GoesOutWithParent` of `TBeacon`, `THaze`) + Render.Dynamics.pas `DrawStands` + Game.Moon.pas `LocateParent` |
| Lamps riding the boss's disc | `turns` beacons in level1.json + Render.Dynamics.pas (`OriginOf`, `TParentSpin`) + Game.Moon.pas `LocateParent` |
| New monster (data only) | monsters.json + a `.mset` set (spriteList keeps the `.mns` spelling) |
| Explosion mechanics: the wave that wounds, its speed, falloff, shove and shelter; who a blast strikes; the shards that wound what stands below (Effects.Debris.pas `Strike`, Game.Moon.pas `ShardStruck`) | Game.Blasts.pas + Game.Moon.pas (`ResolveBlasts`, `StrikeMonsters`, `StrikeHero`, `RewardMonsterKill`) + `blast` in monsters.json (`TBlastDef` in Monsters.Defs.pas) |
| Explosion look: flash, debris, plume; sizes; a new kind | Game.Explosions.pas (+Effects.Debris.pas for shard physics, `explosion` in monsters.json, `TExplosionKind` in Monsters.Defs.pas) |
| Sparks: how they fly, bounce, fork and draw | Effects.Sparks.pas (+Render.Glow.pas `gsStreak`) |
| A spark source in a level (the satellite, the boss) | `sparks` in the `dynamics` of levelN.json + Levels.Dynamics.pas `TSparks` (+Render.Dynamics.pas `SolidInView`) |
| A fan in a level: size, speed, direction, blur, a dying motor; a new rotor, guard or back; a louver panel beside it | `fan` in the `dynamics` of levelN.json (the louver - in `objects`) + Levels.Dynamics.pas `TFan` + `ventilation.mset` (declared in `objectSets`; tools/fans/build_fans.py makes the pictures) |
| Sparks off armor under fire; which monsters are metal; the ping and the whine | Game.Impacts.pas + Game.Moon.pas `SpendBullet` / `ArmorStrike` / `SoundArmorHit` + `material` in monsters.json (+tools/sounds/armor.py) |
| Wreck smoke and sparks of the machines | Monsters.pas (`WreckIfCritical`, `WreckSmoke`, `WreckSparks`, `BodyPoint`; a hull's points: `hull` in monsters.json) |
| The barrel's smoke; one more body that smokes | Monsters.pas (`BarrelSmoke`, `TBodySmoke`, `IsExplosiveProp`, `CreateSmoke`) |
| HD art in a monster set: filter, color key | Monsters.pas `AnimFor` + Render.Sprites.pas `ExpectDenseArtAbove` |
| The henshin ceremony: the countdown, what each event of the rite and the burst means for the hero (the cure, the mercy, the light on the body, the suit), the suit on and off | Game.Henshin.pas (`HearRite`, `HearBurst`, `Finish`, `RemoveIceForm`, `ChargeLook`) + Game.HeroOrbs.pas (`BeginRite`, `ShedSuit`, `BurstSuit`) + Game.Moon.pas (`GrantMercy`, `DrainMonsterEvents`, `FireScreenTriggers`, `TickGravelAttack`; the J and K debug keys) + docs/mechanics/henshin.md |
| The burst of the suit: the inhale (the world standing, the veil, the bare figure), the rays (count, speed, tail, the vortex's curl, through walls), the marks, the ring, the flash, the motes, the moon's dark look; what a ray strikes, a life a burst | Orbs.Burst.pas (formulas, numbers, `IceBurstLook`, `MoonBurstLook`) + Game.Henshin.pas (`HearBurst`, `Finish`) + Game.Shroud.pas `MaskOf` + Game.HeroOrbs.pas (`StartBurst`, `BurstSuit`, `ResolveBurstHits`, `StrikeWithBurst`, `BurstHitStep`) + Game.Moon.pas (`WorldStands` in `Update`, `DrawHeroSilhouette`, `DrawHeroInShroud`; the L and U debug keys) + Tests.Orbs.Burst.pas / Tests.Game.HeroOrbs.pas + docs/mechanics/henshin.md |
| The rite of orbs of the henshin: its schedule (`IceRiteScore`), the waves and where they are drawn from, the flight to a seat, when an orb is armed, the stand-ins and their stock, the freeze and the flash, the collapse over the body, a door, a leap, the hero's death | Orbs.Rite.pas (formulas and numbers) + Orbs.Harvest.pas (`HarvestAround`) + Game.HeroOrbs.pas (`BeginRite`, `ResolveOrbHits`, `CarryRite`, `Fall`, `DrawBehind` / `DrawOrbs`) + Game.Moon.pas (`HeroBodyPoints`, `HandleScreenTransitions`, `HurtHero`) + Tests.Orbs.Rite.pas / Tests.Orbs.Harvest.pas + docs/mechanics/henshin.md |
| A pattern of the henshin: the snowflake, the vortex, a new one; which level builds which | Orbs.Patterns.pas (`SnowflakeSeat`, `VortexSeat`, the `Patterns` table) + `henshinPattern` in levelN.json + Levels.Defs.pas (`HenshinPattern`) + Game.Moon.pas `LoadLevel` + Orbs.Rite.pas `SeatLeapt` (a seat that leaps) + Tests.Orbs.Patterns.pas |
| The suit coming off: the ring of orbs, how long it stands, the mercy | Orbs.Rite.pas (`Shed`, `Shield`, `RingSeat`; `ShedOrbs` / `ShedTicks` / `ShedSpread` of the score) + Game.Henshin.pas `RemoveIceForm` + Game.HeroOrbs.pas `ShedSuit` + Game.Moon.pas `GrantMercy` |
| The hero's shroud: when it plays and with which look, what a look says (bands, strips, halo, motes, mist), what the painter draws and in what order, the light of the ice suit | Game.Shroud.pas (`TShroudLook` and the looks, `THeroShroud`, `TShroudPainter`) + Hero.pas (`Pose`, `DrawArm`, `SkinSet`) + Game.Henshin.pas (`Finish`, `RemoveIceForm`, `ChargeLook`) + Render.Glow.pas / Render.Puff.pas (`DrawGlowRect`, `DrawPuffRect`) + Game.Moon.pas (`LoadLevel`, `HandlePitFall`, `StartPlaying`, `RestartLevel`, `HurtHero`, `ArriveOnScreen`, `Update`, `Render`) + Render.Silhouette.pas (the masks, the halos, the seeds) + Tests.Game.Shroud.pas (+docs/mechanics/hero-shroud.md, in the project's storage) |
| Taking a pickup: the fill, the crumbs, their flight into the hero's body and the light on it; a pickup destroyed instead; the light of a medkit and of a weapon that lie; a door, the hero's death and a restart in the middle of a scene; one more kind of pickup | Game.Uptake.pas (`TUptakeLook` and the three looks, `CutCrumbs`, `TUptake`, `TUptakePainter`) + Game.Shroud.pas (`Feed`, `DrawFedUnder`, `DrawFedBody`) + Render.Silhouette.pas + Monsters.pas (`Collect`, `ArtSet`, `Mirrored`, `Draw`) + Game.Moon.pas (`TakeLoot`, `BeginUptake`, `BurstPickup`, `WarmPickupPictures`, `ResolveMonsterContact`, `RewardMonsterKill`, `ArriveOnScreen`, `HurtHero`, `RestartLevel`, `Update`, `Render`) + `medic.mset` (`medkit`, `light`; tools/medkit/build_medkit.py makes them) + Tests.Game.Uptake.pas (+docs/mechanics/pickups.md, in the project's storage) |
| What is made of a picture's alpha - the mask, the halo, the points: for one more thing that glows in its own shape | Render.Silhouette.pas (+Render.Glow.pas `BlurImage`, `CreateGlowFromImage`) |
| Level content / triggers / screens | levelN.json + Levels.Defs.pas |
| A level event: when it fires, what it does; a new condition or action | `events` in levelN.json + Levels.Events.pas (model) + Events.Director.pas (runner) |
| Game flow / state machine / scoring / bonuses | Game.Moon.pas (+Game.Bonus.pas) |
| The gravel trial: acts and batches, the gate, the breath between acts, the herald, the aimed rain, pit and side returns, the medkits (per 15 kills, the middle of an act), the open sky, the wave of the finale and its cap; where a body comes down | Game.Trial.pas (rules) + Game.Moon.pas (`TickGravelAttack`, `LetDownFromSky`, `LetDownMedkit`, `LetDownWave`, `WaveSideWanted`, `HeroColumn`, `ArriveAgain`, `FireTriggersOf`) + `screenTriggers` (`gravelBoss`, `finale`) in level2.json + docs/mechanics/arena-2.md |
| The gravel arena's room act by act: which shelves wake, sleep or blink, in which order, sparing the hero or not | `events` of screen 9 in level2.json (`s09-act1`..`s09-done`) + the banks of the shelves there + Levels.Events.pas (`ShelfActions`, `TBankTelling`) + Pads.World.pas (`TellBank`, `OrderedBank`, `Picked`, `ProgramWait`) + Pads.Shelf.pas (`Command`) + docs/mechanics/arena-2.md |
| The violet light of an arrival; the herald's | Game.Arrivals.pas (+Game.Moon.pas `LetDownFromSky`, `ArriveAgain`) |
| The TeK wall cannons: ride, warn, burst, rows, the shelves that yield, the contact, the scripted end; their art | Game.Cannons.pas + the `cannons` action in level2.json + Game.Moon.pas (`StartCannons`, `TickCannons`, `TellYieldBank`, `BlowCannons`, `ResolveCannonContact`, `BulletStruckCannon`, `CannonsScenePlays`) + `tek-cannon.mset` (tools/cannon/build_cannon.py) |
| The TeK shield: the honeycomb, its rim, a flare, the fall | Game.Shield.pas (+Game.Cannons.pas, which wears it) |
| The Ram (TeK-R13): the entrance, the drive and the brake, the mast, the eye, the lens and the lamps, the exhaust smoke, the patrol, the contact and the throw, the shield over its body; its sounds and the boss track | Game.Ram.pas + Game.Shield.pas (`CreateOver`) + Monsters.Hull.pas (`DrawUnder`, `DrawBody`) + Levels.Dynamics.pas (`TSmoke.CreateLook`) + Hero.pas (`Throw`) + Audio.pas (`PlayLooped`, `Plays`, `FadeOutMusic`) + the `ram` action in level2.json + Game.Moon.pas (`StartRam`, `TickRam`, `ResolveRamContact`, `BulletStruckRam`, the draw of the smoke) + `tek-machine.mset` (tools/machine/build_machine.py) + tools/sounds/ram.py |
| The Ram's sweeper (3.0.77): the ride to the hero's row, the red barrels and the sweep, the closed ceiling, the fork and the ladder by the thirds, the barrel pack as the target and the plates under it, the empty mast after it | Game.Ram.pas (`TickRide`, `TickSweep`, `ForkRow`, `ShootBarrel`, `TickHeat`, `LockSweeper`, `StrikeBarrels`, `ToHead`; `TRamPainter.DrawHeat`, `DrawLight` - the plates) + Game.Shield.pas (`CreateStrip`) + Game.Moon.pas (`BulletStruckRamBarrels`; `TickRam` - `ShotSpeed`) + Tests.Game.Ram.pas (`TRamSweeperTests`) |
| The Ram's act 1 (3.0.76): the press of a hero low and the hunt of one on the pads; the hunter's aim, turn and bursts by the thirds, its eye and lives by the grade, the head's blast and the change to the sweeper | Game.Ram.pas (`TickMode`, `BeginRev`, `BeginHuntLeg`, `TickAim`, `TickFire`, `StrikeEye`, `KillHead`, `TickChange`; `TRamPainter.DrawHead`, `DrawLens`, `TickHeadSmoke`) + Game.Moon.pas (`TickRam` - the target, the shot into the monsters' burst, the blast; `BulletStruckRamEye`; `StartRam` - `DifficultyMonsterLives`) + Tests.Game.Ram.pas (`TRamHunterTests`) |
| The press of the finale: the conveyor of balconies, the beat, a newcomer onto the top row | Game.Press.pas + the `press` and `waveOnto` actions in level2.json + Game.Moon.pas (`StartPress`, `TellPress`, `TellPressRow`, `LetDownWave`) |
| Bodies an event lets in along a row (the TeK-K10 platforms, the tanks of the finale): their way in, their rigs, holding the gate | the `spawn` action in level2.json + Monsters.pas (`SpawnInLane`, `EnterFrom`, `Depart`, `CountAliveGuests`) + Levels.Defs.pas (`SpawnWearer`) + Game.Moon.pas `SpawnGuest` |
| A parked carousel flying in, its speed-up; a carousel that breaks into falling pads | `parked`, `speedUp`, `failing` of a carousel in level2.json + Levels.Carousels.pas (`TCarouselLanding`, `Clock`, `Halting`, `FailingRigTag`) + Pads.World.pas (`TryFlyInCarousel`, `TryBreakCarousel`, `TurnLandedCarousels`, `TPad.Land` / `BreakDown` / `Fail`) + Game.Moon.pas (`FlyInParked`, `ReleaseHeldFlyIns`) |
| Stray pads: when they come, where they hang, how they misbehave, sent away | Pads.Stray.pas + `stray` on a pad and the `strays` / `straysLeave` actions in level2.json + Pads.World.pas (`TryLaunchFlock`, `TryDismissFlock`) + Levels.Defs.pas `CheckPadStray` |
| Weather: a body that bursts where it lands (the sky barrel) | `weather` in monsters.json + Monsters.pas (`EndWeather`, `Burst`) + Game.Moon.pas (`meBurst`, `RewardMonsterKill`, `ResolveMonsterContact`) + Game.Trial.pas `OpenSky` |
| The hero's aura of orbs: the ring, its flow, how it follows (the leash, the thread of a leap), lives, weaving a second cast in, the ring's ceiling, a door, the hero's death | Orbs.Aura.pas (formulas and numbers) + Game.HeroOrbs.pas (`CastAura`, `CarryAura`, `Fall`) + Game.Moon.pas (`CastAura`, `HandleScreenTransitions`, `HurtHero`) + docs/mechanics/orbs.md |
| The call of the aura: where the orbs show through (faces of cells and pads, thin air), the wait over a face, the flight, when an orb is armed, the mercy window | Orbs.Harvest.pas (the spots) + Orbs.Aura.pas (`Cast`, `Emerge`, `Hover`, `Fly`) + Pads.World.pas (`Bodies`) + Game.HeroOrbs.pas `CastAura` + Game.Moon.pas (`MatterAround`, `CastAura`, `GrantMercy`) |
| The fire rain of orbs: the waves, the formula of a drop, the floor of a column (matter, a pit), landing, a second pour, the hero's death | Orbs.Rain.pas (formulas and numbers) + Game.HeroOrbs.pas (`PourRain`, `ResolveOrbHits`, `Arrive`, `Fall`) + Game.Moon.pas (`HurtHero`, `ArriveOnScreen`) + docs/mechanics/orbs.md |
| An orb: its look, its three ends (implosion, dust, release), the mark on a face, how it is drawn between ticks, its depth and the two layers about the hero; what an orb strikes and what that costs | Orbs.Flock.pas + Game.HeroOrbs.pas (`ResolveOrbHits`, `TakesAt`, `OrbReach`) + Game.Moon.pas (`PopEnemyBullet`, `EnemyBulletNear`, `DangerousMonsterAt`, `WoundByOrb`) + `dangerous` in monsters.json |
| Screen size vs frame size; anything for the wide screen | Game.Space.pas (then every reader of `Frame*` / `Screen*`) |
| Health monitor / bonus charge panels: look, colors, timings | Hud.Vitals.pas / Hud.Charge.pas (+Render.Brush.pas for the brush and palette) |
| The charge of the form: the eclipse gauge in the monitor's wing, the black orbs that bring it, what a death gives back | Hud.Energy.pas + Orbs.Feed.pas + Orbs.Flock.pas (`MoonOrbTint`, `DrawDarkBody`) + Hud.Vitals.pas (`Wing`) + the `energy` action (Levels.Events.pas, Events.Director.pas) + Game.HeroOrbs.pas (`FEnergy`, `FEnergyAtEntry`, `FeedEnergy`, `TickAfterCeremony`, `Arrive`, `Rewind`) + Game.Moon.pas (`FEnergyGauge` in `Update`) + Tests.Hud.Energy.pas, Tests.Orbs.Feed.pas, Tests.Game.HeroOrbs.pas (+docs/mechanics/arena-3.md, stage 6) |
| Health rows over the hero / monsters; the crosshair's thirds | Hud.Marks.pas (+Render.Brush.pas for the cells) + Monsters.pas (`HealthTier`, `TicksSinceHit`) + Game.Moon.pas `CrosshairFrame` |
| Screen transitions / checkpoints; where a pit or death returns the hero on a screen | Game.Moon.pas (`HandleScreenTransitions`, `ArriveOnScreen`, `PinRespawnPoint`, `HandlePitFall`, `MoveCheckpoint`) + `respawns` and the `respawn` action in levelN.json + Levels.Defs.pas (`TRespawnPoint`, `CheckRespawns`, `CheckRespawnCell`) + Levels.Events.pas (`eaRespawn`) |
| A jet under a pad: its color, length and strength, the flare around a flight, a coughing engine | the smoke part of a rig in levelN.json (`heatTint`, `speed`, `life`, `intensity`, `surge`, `flow`) + Levels.Dynamics.pas (`TSmoke`, `FollowEffort`, `EffortEaseTicks`) + Pads.World.pas (`Effort`, `Thrusting`, `ThrustLeadTicks`) + Pads.Plunge.pas `Effort` + Game.Moon.pas `LocateParent` |
| Menu screens / layout / language switching / trailer showcase frames | Menu.pas + Localization.pas |
| Menu sky: stars, the spinning moon, the dolly into a submenu | Menu.Starfield.pas / Menu.Globe.pas / Menu.pas (`DrawSky`, `*Zoom`) |
| A lit sphere: shading, terminator, atmosphere, night lights | Render.Globe.pas |
| The Earth in a level's sky; its phase and the dawn | `dynamics` (`globe`) and `events` (`sun`) in levelN.json + Levels.Dynamics.pas (`TSkyGlobe`) + the `earth` / `earth-night` maps in `sky.mset` (shared, declared in `objectSets`) + Render.Globe.pas |
| Logo halo and embers; a redrawn logo | Menu.Logo.pas + Menu.Embers.pas (+ the `logo` sprite in ui.mset) |
| Anything that glows additively | Render.Glow.pas |
| Heat haze - under a jet, over a turbine: the plume, its strength, grain and flow | `haze` in `dynamics` or in a rig of levelN.json + Levels.Dynamics.pas (`THaze`, `HazeLayers`, `TNoiseWindow`) + Render.Dynamics.pas (the backdrop layer, `BackdropOf`) + Render.Tiles.pas `Backdrop` + Sdl2.Core.pas `SDL_RenderGeometry` |
| What the pads and the monsters wear - lamps, hazes, jets: one list for many wearers, a number rolled wearer by wearer | `rigs` + `"rig"` on the pads and the entities in levelN.json + Levels.Rigs.pas (`WearRigs`, `ReadRigNames`, `TRigWearer`) + Levels.Defs.pas `RigWearersOf` + Levels.Dynamics.pas (`ParseDynamic`, `NameRoll`, `PlacementSeed`) |
| What hangs on a pad going into the depth with it: smaller, darker, behind the pads in front | Render.Dynamics.pas (`TParentDepth`, `OriginOf`, `DrawSunk`) + Levels.Dynamics.pas (the canvas' `Scale` / `Tone` in `TBeacon`, `THaze`, `TSmoke`) + Pads.World.pas (`DeepScale`, `DeepTone`, `Middle`) + Game.Moon.pas (`LocateParent`, the order in `Render`) |
| A dynamic object (a beacon, its blink, rays; a graph on a screen - its shape, frame, grid); a new kind; hanging one on a static object | `dynamics` in levelN.json + Levels.Dynamics.pas (kinds, parser) + Effects.Traces.pas (what a trace answers) + Render.Dynamics.pas (where it stands, layer) (+`tag` on `objects`) |
| Text rendering / new captions | Render.Font.pas + Hud.Messages.pas + an `S*` key in Localization.pas + both lang JSONs |
| Level hints / the comm terminal; a hint's voice and place | Hud.Terminal.pas (+Hud.Messages.pas for the ticker lane, `hintText` in level JSON, `header` / `place` of a hint event) |
| Story screen before a level / typing rhythm | Hud.Briefing.pas / Hud.Typewriter.pas (+`introText` in level JSON) |
| Frame pacing / window / vsync | Game.Loop.pas (+Sdl2.Core.pas) |
| Sound / music | Audio.pas (+sound constants and `PreloadSounds` in Game.Moon.pas, the ceremony's in Game.Henshin.pas, data fields in JSONs) |
| Tile/background rendering | Render.Tiles.pas + Render.Sprites.pas |
| Repainting a 2008 screen: what becomes a pad, an object, a fan; the blockout and the prompt; seating a picture on the grid; what may be done to a generated picture | docs/REPAINT.md + levelN.json (`objects`, `pads`, `dynamics`, `tiles`) + `<assetsDir>-objects.mset` |
| Screen pictures for repainting the art (the P debug key) | Game.Moon.pas (`DumpLevelScreens`, `SaveScreenPictures`, `SaveTargetAsPng`) + Sdl2.Image.pas (`IMG_SavePNG`) |
| Free-form art over the backdrop (the ship, the satellite): place, size, tint | `objects` in levelN.json + `<assetsDir>-objects.mset` or a shared set in `objectSets` (`sky.mset`) + Render.Objects.pas (+Levels.Defs.pas `TLevelObject`) |
| Screen shake: doses, what shakes, what stands still | Game.Moon.pas (`*Trauma` constants, `Render`, `DrainMonsterEvents`, `EchoAftershock`, `ActivateQueuedBonus`) + Game.Henshin.pas (`FinishTrauma`) + Render.Shake.pas |
| A sprite name resolves to the wrong picture | Render.Sprites.pas (Get, AmbiguousNames) + the level's `spriteSets` order |
| A monster/hero loads wrong frames from a set | Monsters.pas AnimFor / Hero.pas OpenFrames |
| Sprite sets / the `.mset` format | Sprites.Sets.pas + docs/MSET-FORMAT.md |
| Packing or inspecting sets | tools/SpritePack/* |
| A test: where it lives, how it is run, what is left to the eye; a new test unit | Tests/* + run-tests.cmd + docs/TESTING.md |
| Trailer cards | tools/TitleCard/* |
| Selene: the living moon's map for the menu | tools/Selene/* |
| PNG loading / image DLL | Sdl2.Image.pas |
