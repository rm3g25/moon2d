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
at `v3.0.43`, the live shards at `v3.0.44` and the tank's hull at `v3.0.45` (the folder layout came between 3.0.8 and 3.0.9) and checked against the code section by section at
`v3.0.19`. Where the map and the code disagree, the code is right.

## Source layout

The units live in four folders under the root; `Moon2D.dpr`, `.dproj` and
`Moon2D.inc` stay in the root, and every unit includes it (`{$I ..\Moon2D.inc}`;
`{$I ..\..\Moon2D.inc}` from `Game/Events/`, `Game/Pads/` and `Game/Orbs/`).

- `Core/` - what the level editor and the tools share: SDL bindings, sprite
  sets, rendering (the shake included), the brush, the effects (particle
  swarm, sparks, debris), the level/monster/config/language models, the
  frame-vs-screen space. **Core never uses a unit outside Core** - a tool or
  the editor that references only `Core/` fails to build the day that rule
  breaks.
- `Game/` - the game itself: hero, monsters, the boss's disc and its pilot,
  bullets,
  explosions, bullet impacts, sound, the loop host,
  the bonus vocabulary, the henshin ceremony, the version. `Game/Events/`
  runs the level events; `Game/Pads/` holds the pads in play
  (`Pads.World`), the rebuild of a pad group (`Pads.Formations`,
  `Pads.Flights`) and the director of the boss fight over one and of the
  restore after it (`Pads.Arena`); `Game/Orbs/` holds the orbs - the flock
  (`Orbs.Flock`), the harvest of spots on the matter of a screen
  (`Orbs.Harvest`), the hero's aura over both (`Orbs.Aura`) and the fire
  rain (`Orbs.Rain`).
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
since the editor will write pads too; the pads in play (`Pads.World`) and
their rebuilds in `Game/Pads/`; what a pad or a monster wears, its rigs
(`Levels.Rigs`), is a parser in `Core/` too. Two unit names in `Core/` still
carry the `Game.` prefix (`Game.Config`,
`Game.Space`) - the folder is the truth about the layer, not the prefix.

Dependency direction (roughly bottom-up):
`Sdl2.Core` / `Sprites.Sets` -> `Sdl2.Image` -> `Render.*` / `Audio` / `Game.Config` /
`Game.Bonus` / `Game.Space` / `Localization` / `Render.Brush` ->
`Monsters.Defs` -> `Levels.Tint` / `Levels.Events` (over `Monsters.Defs`
for the tactics an event sets) / `Effects.Emitter` / `Render.Puff` /
`Effects.Sparks` (its streak texture comes from the owner) ->
`Effects.Debris` (over `Effects.Sparks`, draws through `Render.Glow`) ->
`Render.Globe` -> `Levels.Dynamics` (over `Effects.Sparks` for the sparks
kind; draws through `Render.Glow`, `Render.Puff` and `Render.Globe`) ->
`Levels.Rigs` (what the pads and the monsters wear: over
`Levels.Dynamics`) -> `Levels.Pads` (over `Levels.Tint`, and over
`Levels.Rigs` for the names of the rigs a pad wears) ->
`Levels.Defs` -> `Pads.Formations` (the dice and the judge of a rebuild:
over `Levels.Pads`, `Levels.Defs`, `Render.Brush` and `Game.Space`) ->
`Pads.Flights` (over `Pads.Formations`) -> `Pads.World` (the pads in play:
over the two, `Levels.Pads`, `Levels.Defs`, `Render.Sprites`,
`Render.Brush`, `Game.Space` and `Sdl2.Core`) / `Hud.Vitals` / `Hud.Charge` /
`Hud.Typewriter` ->
`Hud.Terminal` / `Hud.Briefing` ->
`Bullets` / `Monsters.Disc` (the boss's disc: over `Render.Sprites` and
`Monsters.Defs`, its sensor through `Render.Glow`) / `Monsters.Hull` (the
hulls of the platform and the tank: the same, the eye through `Render.Glow`) / `Monsters.Pilot` (the
boss's pilot: over `Levels.Defs`, `Monsters.Defs`, `Pads.World`,
`Game.Space` and the sizes of `Render.Sprites`) / `Monsters.Damage` (the
window of a monster's damage cap: over `Monsters.Defs`) -> `Hero` /
`Monsters` (both over `Pads.World` too) / `Hud.Messages` / `Render.Tiles` / `Render.Objects` /
`Render.Dynamics` / `Game.Explosions` (over `Effects.Debris`,
`Levels.Dynamics` and `Monsters.Defs`) / `Game.Blasts` (the wave of an
explosion: over `Monsters.Defs`, `Effects.Sparks` for the probe type and
`Sdl2.Core`) / `Game.Impacts` (over
`Effects.Sparks` and `Levels.Dynamics`) / `Orbs.Flock` (the orbs: over
`Effects.Emitter`, `Render.Brush` and the canvas of `Levels.Dynamics`,
drawn through `Render.Glow`) / `Orbs.Harvest` (where an aura's orbs come
from: over `Game.Space`, `Render.Brush` and `Sdl2.Core` alone - it knows
neither the level nor the pads) -> `Hud.Marks` /
`Game.Henshin` / `Events.Director` / `Orbs.Aura` (the hero's aura: over
`Orbs.Flock` and `Orbs.Harvest`) / `Orbs.Rain` (the fire rain: over the
same two, and `Game.Space`) / `Pads.Arena` (the director of the
rebuilds: over `Pads.World`, `Pads.Formations`, `Monsters`,
`Monsters.Pilot`, `Levels.Pads`, `Levels.Dynamics` and `Render.Sprites`) -> `Moon2D.dpr`, which also drives
`Game.Loop` (the host: over `Sdl2.Core` and `Game.Config` alone, it knows no
game unit). The menu sky rig on the
side: `Render.Brush` -> `Render.Glow` -> `Menu.Starfield` / `Menu.Embers` ->
`Menu.Logo` -> `Menu` (with `Menu.Globe`, a thin moon over `Render.Globe`).

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
  debug keys are constants in the dpr).
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

### `Core/Render.Sprites.pas` (~555 lines)
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
  (`SDL_RenderSetLogicalSize` - the dpr passes the frame of `Game.Space`).

### `Core/Sdl2.Image.pas` (~70 lines)
SDL2_image bindings, delayed imports in the shape of `Audio.pas`.
`IMG_Load_RW` replaced `SDL_LoadBMP_RW` at every load site. `EnsureImageLib`
runs at startup and raises plainly if the DLL is absent - unlike the optional
mixer, missing art is fatal. `IMG_SavePNG` is the one writer: the debug
screen dump of the dpr.

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

### `Core/Render.Dynamics.pas` (~460 lines)
- **`TDynamicScreenRenderer`** - brings the level's dynamic objects
  (`Levels.Dynamics`) to the screen. Owns the textures of the
  `TDynamicCanvas` (point, flare, starburst and streak glows - `Render.Glow`; the
  smoke puffs - `Render.Puff`) and lends it the cache of the level's
  object art (`Art`), made at level load; the objects
  themselves are the level's. After the canvas every object `Acquire`s
  what it draws with (a sky globe its `TGlobe`); the destructor `Release`s them
  before the canvas goes, so every SDL texture dies before the renderer. Per object a `TPlace`: its stands (screen + origin),
  `FollowsParent` (a parent looked up by tag), the parent's life, the lead
  screen. A nailed object stands
  at (0, 0) on its screen, or on each screen of its `screens` run; one under a static object on every screen that
  object stands on, at its top-left - settled once, static objects never
  move. A tag no object carries is a pad's or a monster's: that stand is
  looked up every tick (`FollowParent`) through **`TLocateParent`**
  (`reference to function(tag, out TParentStand)`: screen, the top-left of
  the parent's picture, alive, `Effort` - how hard it works, 0..1: a pad
  flying or about to leave its place works at 1, and `Tick` passes it on
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
  a parent in front, and one that never leaves it. `Tick(screen)` ticks
  every object whatever
  the screen (a
  lamp keeps its rhythm off screen) with the origin of its stand on the
  hero's screen, else its first (at the pose the tick has just reached,
  `ThisTick`); a lead stand on another screen is a jump
  (`ForgetOrigin`), not a flight. `Draw(screen, origin, alpha, layer)` draws
  the ones on the screen in one layer (`dlBackdrop` / `dlSky` / `dlBack` /
  `dlFront`; before the backdrop layer it puts the screen's backdrop on the
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
  bonuses in the dpr, the henshin rings and finish in `Game.Henshin`), not
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
  a redrawn atlas is filtered, set through `TMoonFont.Filtering` (the dpr
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

### `Game/Audio.pas` (~230 lines)
SDL2_mixer bindings (`delayed` imports - the game survives a missing DLL) plus
the sound bank.
- **`TMusicMode`** = (`mmLoop`, `mmOnce`).
- **`TSoundBank`** - dictionary of WAV chunks + one music slot. `Load`/`Play`
  (`sounds\`, strict: a missing file raises `EAudioError` - at startup for what
  the dpr preloads, on first `Play` for a name it did not),
  `PlayMusic`/`StopMusic` (`music\`, OGG, lenient: a missing track skips
  silently), `ToggleMusicMuted` (`MusicMuted` reads it back), `Enabled`
  (False when the mixer DLL is absent
  -> every call becomes a no-op). `MixChannels` = 32: a one-shot with no free
  channel is dropped in silence, and the chain gun's 2.4 s shots alone hold
  sixteen.

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

### `Core/Levels.Defs.pas` (~1100 lines)
Level data model + JSON parser. No game logic.
- **`EmptyTile = 0`** - grid value 0 is nothing; N >= 1 maps to
  `TilePalette[N - 1]`.
- **`TEntityOverrides`** (record) - optional per-placement direction, speed,
  lives, canShoot (Has* flag + value pairs).
- **`TDifficultyValue`** (record) - one int per grade; JSON = a number or
  `{"normal":..,"hard":..,"wild":..}`; `Uniform`, `ForGrade`.
- **`TEntityTriggers`** (record) - `BigMessage`/`SmallMessage`/`HintText`
  (localized), `ChangeMusic`, heroX/heroY reposition (vertical transitions),
  the gravel trial quota (`HasGravelBoss` + `GravelQuota: TDifficultyValue`).
- **`TEntityPlacement`** (record) - monsterId, screen (1-based), x/y (sprite
  grid), spriteList, `Grades` (the Doom skill-flag idiom), overrides,
  triggers, `Tag` (names the placement for the events' tagged conditions -
  `allDead`, `livesBelow`, `enraged` - and for the dynamic objects hung on a
  monster; '' = none), `Rigs` (the rigs it wears, by name, in the order
  they are hung - JSON `"rig": ["tekPlatform"]`, read by `ReadRigNames` of
  `Levels.Rigs`; their parts hang on the monster by its tag, counted from
  the top-left corner of its cell).
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
  collision strings `[screen][row]` ('1' = solid), tile palette, backgrounds,
  entities, id/title/assetsDir/**spriteSets**/**objectSets**/music/introText, grid dims,
  screenCount. `SpriteSets` is the environment sets in resolution order - tiles
  only; screen backdrops follow the `<assetsDir>-backdrops` convention and
  never appear there. `Objects` - the free-form art, in file order (later
  draws over earlier); the private `ParseObjects` reads the optional
  `objects` section and refuses an object off the screen list or with a
  width of zero or less. `Pads` - the platforms apart from the grid
  (`Levels.Pads`), in file order; the private `CheckPads` refuses a pad off
  the screen list (`SLevelPadBadScreen`), two pads with one tag
  (`SLevelPadTwoTags` - a dynamic object hung on it would go to the
  first) and a path with a stop that puts the pad past an edge of its
  screen (`TryStopOffScreen` finds the first: X below zero or X + width
  past `ScreenWidth`, Y below zero or past `ScreenHeight`;
  `SLevelPadStopOff` - the pad would leave the hero's screen without its
  riders). `PadGroups` - the pads rebuilt together (`Levels.Pads`), in
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
  dynamic object carries. `Events` - the level's events (`Levels.Events`), in
  file order. Queries: `TileAt`, `SolidAt`, `SolidAtPoint(screen, x, y)` (the
  same for a point in screen units - the one home of the units-to-cells
  rule and its guard against negatives; the solid probes of the game and
  of the monsters call it), `BackgroundFor` (the whole
  change, last one wins; `Image = ''` when the level defines none).
  `LoadFromFile`; the pads are parsed before the dynamics, since a dynamic
  object may hang on one; the rigs the pads and the monsters wear are hung
  right after the dynamics are parsed and before the checks (`WearRigs` of
  `Levels.Rigs` over the wearers `RigWearersOf` lists - the pads first,
  then the placements, each in file order, so the parts of the pads keep
  their places in the list; `PadWearer` and `EntityWearer` make them,
  named for the errors by `PadRigName` of `Levels.Pads` and by
  `EntityRigName` - a placement by its tag or, without one, by what
  stands where: their parts are dynamic objects as the rest, and a
  group's alarm lamps may be among them); and the dynamics before the
  events, since an
  event may name a dynamic object's tag. Private `CheckEvents` refuses an event
  off the screen list, one watching a tag no placement carries, and
  (`CheckEventTargets` -> `CheckEventTarget`) an intensity action turning a
  tag no dynamic object carries, a sun action turning a tag no globe
  carries, a tactics action naming a tag no placement carries or a
  rebuild or a restore action (3.0.39: `SLevelEventRestoreUnknown`)
  naming a tag no pad group carries. `Dynamics` - the dynamic objects (`Levels.Dynamics`), owned by
  the level (the only destructor here) and kept through a restart - a lamp
  keeps its rhythm; only what a re-armed event changed goes back. Private
  `CheckDynamics` refuses a nailed object off the screen list or a
  `screens` run running backwards or past it (`CheckDynamicScreens`), and
  (`CheckDynamicParent`, which counts the kinds carrying the tag - an
  object, a pad, an entity: exactly one) a parent tag no object, no pad and
  no entity carries, a tag carried by more than one kind, two
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
  no path and no group: a pad that travels or is rebuilt may not be there).
  Coming through a door moves nobody to the point; a named deviation from
  2008, whose checkpoint was the entry point and what a heroX / heroY
  trigger wrote.

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

### `Core/Effects.Debris.pas` (~560 lines)
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
  `ShardSize`, `ShardCone` (degrees wide, centered straight up),
  `RestSeconds`, `Sparks`, `SparkSpeed`; every piece rolls between
  `MinShare` (0.35) of a value and the value.
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
  (`SpawnSparks` throws them every way at once) - streaks drawn with the
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

### `Core/Render.Puff.pas` (~230 lines)
Smoke drawn instead of loaded. `CreatePuffTextures(renderer, side)` makes
`PuffShapes` (4) ragged puffs (`TPuffTextures`) at level load: a soft
falloff eaten into by
fractal value noise (`FractalNoise`, octaves of `ValueNoise` over a
`TXorShift`-hashed lattice), the outline bent by the same noise, white
pixels with a mottled brightness, the shape in alpha. **Alpha blended**,
linear-filtered - smoke hides what is behind it, light (`Render.Glow`) only
adds. `DrawPuff(renderer, texture, cx, cy, size, angle, color, level)` -
centered, turned (`SDL_RenderCopyExF`), tint as color mod, density as alpha
mod. `FreePuffTextures`. `EPuffError`.

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

### `Core/Levels.Dynamics.pas` (~2480 lines)
The `dynamics` section of level JSON: things placed like the static
objects, but alive. **Every kind lives in this unit**: a new kind is a class
here, a word in `DynamicKindIds`, its layer in `DefaultLayers` and a branch
in `CreateDynamic`.
- **`TDynamicPlacement`** (record) - what every kind shares: `Screen`,
  `screens` (JSON `[first, last]` - one object on a run of screens, read
  into `Screen`..`LastScreen`) or `Parent` (exactly one - with a parent the
  parent decides the screens; the parent is a static object's, a pad's
  or a monster's tag), `X`/`Y` (screen units; from the parent's top-left under
  one), `Tint`, `Tag` (the name events turn it by), `Layer`
  (`TDynamicLayer`: `dlBackdrop` - the backdrop itself, bent, under
  everything else: a haze's; `dlSky` - right over the backdrop, still while the
  world shakes, the far things; `dlBack` - with the static objects, behind
  the tiles; `dlFront` - over the monsters, under the hero; the default is
  the kind's), `Turns` (JSON `turns`: the point turns with a parent that
  spins - a lamp on the boss's disc; without a parent it raises at load;
  under a parent that does not spin the point stays where it is, but under
  any monster a place that turns is no longer drawn once that monster is
  dying, dead or gone).
- **`TValueFade`** (record) - a value and where the events take it:
  initial, current, target, step; `Settle`, `HeadFor(target, ticks)`,
  `Tick`. The intensity of every object, the sun of a sky globe.
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
  (empty in the ancestor). Virtual `GoesOutWithParent` - True for a kind
  that leaves nothing in the air, a beacon and a haze (False in the
  ancestor): `Render.Dynamics` does not draw such an object while its
  parent monster is dead or gone, so the lamps and the haze of a dead
  monster go out with it. The parent is coordinates only,
  VCL-style: it owns nothing.
- **`TDynamicObjects`** (`TObjectList<TDynamicObject>`) - `FadeTagged(tag,
  level, ticks)`, `RewindTagged(tag)`, `TurnSunTagged(tag, degrees,
  ticks)`, `AnyTagged(tag, kind = nil)` (the kind is a
  `TDynamicObjectClass`, nil = any): what the events and the level
  checks ask.
- **`TDynamicCanvas`** (record) - renderer + the glow textures + the puff
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
  explosion's plume is freed then).
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

### `Core/Levels.Events.pas` (~255 lines)
The `events` section of level JSON: model and parser, no game logic (the
game runs them through `Events.Director`; the editor will write them).
- **`TEventCondition`** = (`ecEnterScreen`, `ecAllDead`, `ecLivesBelow`,
  `ecEnraged`) - what the event waits for. The hero must be on the event's
  screen for any of them; enterScreen asks nothing more; the rest
  (`TaggedConditions`) watch the monsters carrying the tag: allDead - none
  alive, livesBelow - one alive with fewer lives than `lives` (a mark told
  for the normal grade: it grows with the difficulty as the lives do -
  `TMonsterField.AnyTaggedLivesBelow`), enraged -
  one alive in its rage (the boss below its rage mark, a tank below its
  own).
- **`TEventActionKind`** = (`eaBigMessage`, `eaSmallMessage`, `eaHint`,
  `eaMusic`, `eaIntensity`, `eaSun`, `eaTactics`, `eaRebuild`, `eaRestore`
  (3.0.39)); **`TEventAction`**
  (record) - kind +
  localized `Text` (the message kinds), `FileName` (music), or `Target` /
  `Level` (0..1) / `Ticks` (intensity: the dynamic objects carrying the tag
  fade there; JSON `target`, `value` a percentage, `ticks` 0 = at once),
  or `Target` / `Angle` / `Ticks` (sun: the globes carrying the tag turn
  their sun there; JSON `value` in degrees), or `Target` / `Tactics`
  (tactics: the monsters placed with the tag fly by them from now on, see
  `Monsters.Pilot`; JSON `target`, `value` - a word of `EventTacticsIds`:
  laps / dives / rams / hunts), or `Target` alone (rebuild: the pad group
  carrying the tag is rebuilt from now on, over and over, as its
  conductor flies - `Pads.Arena`; JSON `target`; restore (3.0.39): the
  same group is rebuilt no more and its pads fly back to where the level
  file puts them; JSON `target`, the word `restore`).
- **`TLevelEvent`** (record) - id, screen (1-based), condition, tag,
  `Lives` (livesBelow), `DelayTicks` (counted after the condition holds,
  for any condition), actions. JSON: `"when": "allDead", "tag":
  "labGuard", "delay": 33, "then": [{"action": "hint", "text": "...",
  "textEn": "..."}]`; `"when": "livesBelow", "tag": "boss", "lives": 200,
  "then": [{"action": "intensity", "target": "bossSmoke", "value": 60,
  "ticks": 66}]`.
- `EventConditionIds` / `EventActionIds` / `EventTacticsIds` - the JSON
  vocabulary as typed
  constants. `ParseLevelEvents(root, levelId)`; an absent section is an
  empty list, an unknown condition or action, a missing id, a tagged
  condition without a tag, livesBelow without lives above zero, intensity
  without a target or with a value outside 0..100, sun without a target or
  without a `value`, tactics without a target or with an unknown word,
  rebuild or restore without a target (`ReadGroupTarget`,
  `SEventGroupNoTarget`), or an event without actions raises
  `ELevelEventError`.
- Extending: a condition is an enum member, a word in `EventConditionIds`
  and a branch in the director's `ConditionHolds`; an action the same with
  `EventActionIds` and `Play`.

### `Core/Levels.Pads.pas` (~295 lines)
The `pads` section of level JSON: platforms apart from the collision grid.
Model and parser, no game logic (the game runs them in `Pads.World`; the
editor will write them). A pad holds from above only: its deck, the top
edge, carries what lands on it; from below and from the side anything
passes through. Under the deck the pad has a body one cell deep: it stops
the boss's flight, the sparks and the debris, and the bullets unless the
pad lets them by. A pad may travel a path - there and back along its
stops, or round them - and may bob in the air: the path moves the pad
itself, the bob is for the eye alone (`Pads.World` says why). Pads of a
group are rebuilt together: they fly to a new formation inside the
group's zone, a cell each (`padGroups` names the groups, a pad joins one
by its `group`); a pad the file puts outside the zone flies in with the
first rebuild (3.0.38). A 2026 addition.
- **`TPadPlacement`** (record) - `Sprite` (in the level's object art, as a
  static object's), `Screen` (1-based), `X`/`Y` (the top-left corner in
  screen units, as a static object's; Y is the deck), `Width` (screen
  units; the picture's height follows its aspect), `Tint`, `Tag` (names
  the pad for the dynamic objects hung on it; '' = none), `Bullets`,
  `Path` (a `TPadPath`; `prNone` - the pad stands where it is placed),
  `Bob` (how far the pad sways up and down, in units; 0 = still), `Group`
  (the pad group it is rebuilt with; '' = none), `Rigs` (the rigs it wears,
  by name, in the order they are hung - `Levels.Rigs` holds them and hangs
  them).
- **`TPadZone`** (record) - `Left`, `Top`, `Right`, `Bottom`: cells of a
  screen, 0-based, the bounds included. **`TPadGroup`** (record) - `Tag`,
  `Screen` (1-based), `Zone`, `Pairs` (at least this many pairs side by
  side in a formation), `FarFlight` / `FarShare` (a flight of `FarFlight`
  cells or more is far; a rebuild flies at least `FarShare` pads far),
  `Conductor` (the tag of the monster the rebuilds follow; '' = none),
  `Every` (seconds between two rebuilds), `Alarm` (the tag of the dynamic
  objects lit to warn of one; '' = none).
- **`ParsePadGroups(root, levelId)`** - the section `padGroups`; absent =
  no groups. JSON: `{"tag", "screen", "zone": [left, top, right, bottom],
  "pairs", "farFlight", "farShare", "conductor", "every", "alarm"}`
  (`pairs` and `farShare` absent = 0, `farFlight` absent = 1). `EPadError`
  is raised by a zone that is not four numbers (`ReadZone`,
  `SPadGroupBadZone`), pairs or farShare below zero, a farFlight below one
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
- **`ParsePads(root, levelId)`** - absent section = no pads; `bullets`
  absent = block; `path` absent = no path (`ReadPath`), `bob` absent = 0.
  The JSON: `"path": {"route", "stops": [[x, y], ...], "speed",
  "pause"}` (`route` absent = pingpong, `pause` absent = 0), `"bob"`,
  `"group"` and `"rig": ["pad", "arenaAlarm"]` (`ReadRigNames` of
  `Levels.Rigs`; absent = the pad wears nothing). **`PadRigName(pad)`** -
  the pad as the errors of its rigs call it: `pad "<tag>"`, without a tag
  `pad "<sprite>"`, the only name it has then.
  `EPadError` is raised by a width of zero or less (`SPadBadWidth`), a
  bullets word out of `PadBulletsIds` (`SPadBadBullets`), a route other
  than pingpong or loop (`SPadBadRoute`), a path without stops
  (`SPadNoStops`), a stop that is not a pair of numbers (`ReadStop`,
  `SPadBadStop`), a speed of zero or less, a pause or a bob below zero
  (`SPadBadNumber`); a rig that is not a list of names raises `ERigError`,
  in `Levels.Rigs`. The
  screen range, a tag on two pads and a stop off
  the screen are `Levels.Defs`' (`CheckPads`).

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

### `Core/Monsters.Defs.pas` (~570 lines)
Monster definition model + registry (parses monsters.json). No behavior.
- **Enums**: `TMonsterCategory` (mcEnemy/Pickup/Prop/Boss), `TMovementKind`
  (mkStatic/Patrol/PatrolNoEdgeCheck/ChaseHero/BossFly), `TAttackPattern`
  (apNone/StraightSingle/StraightCluster5/AimedSingle/AimedDouble/RainVolley),
  `TPickupEffectKind` (peNone/Heal/GiveWeapon), `TExplosionKind`
  (ekNone/Barrel/Machine/Boss - the look of a death, JSON `explosion`, an
  unknown word raises; independent of the `blast`),
  `TMonsterMaterial` (mtNone/Metal - JSON `material`, what a bullet does to
  the body: metal throws sparks, see `Game.Impacts`; an unknown word
  raises), `TPilotTactics` (ptLaps/Dives/Rams/Hunts - what a flying boss
  does besides his lap, see `Monsters.Pilot`; set by the level's events,
  not by monsters.json).
- **Records**: `TMovementDef` (kind+speed); `TAttackDef` (pattern, fire cadence,
  bullet speed, pattern-specific params, `HasAttack`); `TPickupEffectDef`
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
  shot leaves; a muzzle on a monster that fires no straight shot raises at
  load; `Enabled`; a hull without a set, a
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
  (localized), deathSounds array, boss, disc, hull.
- **`TMonsterRegistry`** (class) - owns all defs; `LoadFromFile/String`,
  `Find`, `FindByLegacyName`, `TryFind`, `Count`, `AllDefs` (the sound bank
  warms its cache from here), spawn-table and dodge-prize validation.

### `Game/Bullets.pas` (~275 lines)
Projectiles + the 2008 particle-hack spawners that are left.
- **`TFanShape`** (record) - rows/cols/baseSpeed/speedSpread of the k/t fan
  formula (the travel-test record: one template, six shapes -
  `RageWave` / `FastFragments` / `SlowFragments` in `Monsters`,
  `FinishFan` / `ShatterFan` in `Game.Henshin`, `ExplosionFan` in
  Moon2D.dpr).
- **`TBulletStatus`** = (`bsFlying`, `bsBursting`, `bsInactive`).
- **`TBullet`** - position (`X`, `Y`), velocity (`DX`, `DY`, writable),
  gravity ('dyy'), burst animation frame, `Status` (writable),
  `Contact` (participates in bullet-vs-bullet interception). `Move`,
  `StartBurst`, `StartBurstSliding` (a wall hit keeps 1/8 inertia).
- **`TBurst`** - owns a bullet list, its sprite set and its cache ('bullet' =
  hero, 'bull' = monsters; flight frame + destruction frames 2..8).
  `NewBullet`, `Clear` (screen transitions wipe bullets), `Update`, `Draw`.
  Spawners, all verbatim 2008: `SpawnFan(centerX, centerY, shape)` (henshin finale /
  ice shatter / boss
  rage wave / boss victory double fan / the explosion bonus),
  `SpawnConvergingRing` (the henshin healing waves; Contact=True, so
  the ring wounds the boss). The 180-fragment fan of a dying barrel or
  machine is not here since 3.0.41: an explosion wounds by its wave
  (`Game.Blasts`). The 2008 fire rain and shield aura are not
  here: both are orbs now (`Orbs.Rain`, `Orbs.Aura`; the record of what
  went is in PORTING-NOTES, the session of 3.0.33).
- Known wart: `TBurst.Draw` advances burst animation frames - it mutates
  simulation state from the render path, and that is what blocks render
  interpolation for the game world.

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

### `Game/Pads/Pads.Flights.pas` (~470 lines)
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

### `Game/Pads/Pads.World.pas` (~1255 lines)
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
file, calmly (`CalmPace`), thrown and judged by nobody.
Born with the level (`LoadLevel`); a restart rewinds it, the dice of the
rebuilds new for the new try.
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
  hangs on the pad.
- **`TPad`** - one pad: `Left`, `Right` (`Left` + width), `Top` (the deck -
  the feet line of whatever stands on the pad), `PrevTop` (the deck a tick
  ago), `Screen`, `Tag`, `Bullets`, `Group`, `Placement`, `HomeLeft` /
  `HomeTop` (where the path or the flight puts the pad, the knock left
  out).
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
    knock's offset is the pad's place. `Rewind` - the clock to 0, the pad
    on the level file's place, no sag, no knock, no flight; the
    constructor ends with it.
    `MotionX` - how far the pad went across this tick.
  - The deck and the body: `DeckSpans(left, right)` - the deck spans some
    of left..right, edges included (closed) and `EdgeSlop` (0.001) past
    them: a rider carried a unit at a time on a fast pad ends a hair off
    the very edge by rounding and must not drop;
    `DeckSpannedBefore(left, right)` - the same for the deck as it stood a
    tick ago;
    `BodyHolds(x, y)` - the point lies in the body, the deck's width across
    and one cell (`TileSize`) down from the deck, half-open (`Left` <= x <
    `Right`, `Top` <= y < `Top` + `TileSize`). `Body` - the same body as
    a box, in screen units.
  - `Lift(alpha)` - units down from the deck the pad is drawn at, a
    fraction (never rounded): the bob (`Bob` times a sine, one sway in
    `BobPeriodTicks` = 3 s, taken at `FClock` - 1 + alpha - between the
    ticks - the phase shifted by `FBobX` across the screen: the
    placement's X, after a flight the cell the pad landed on - a row of
    pads ripples -, the sway scaled by `FBobShare`, which a flight fades
    to 0 over `BobFadeTicks` (10) and the cell brings back) plus the sag
    of this tick (`FSag`, on the tick:
    the lamps hung on the pad read it there). `Lift(1)` - the pad as this
    tick leaves it.
    `Press(speed)` - something landed on the deck
    at speed units a tick: the sag's speed takes speed * `SagGain` (0.6),
    no more than `SagMaxKick` (2.7 - about three units down at the
    deepest), and a damped spring (`SagStiffness` 0.18, `SagDamping` 0.3)
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
    between ticks. `Travels` - the pad has a path. `ClearOf(other, dx, dy)` -
    the body moved dx, dy would not cut into the other's; touching is no
    cut. `Knocked` - off its place by a blow.
  - The flight (3.0.29): `Fly(flight)` - the pad flies a `TPadFlight`,
    its ticks counted from now (`FFlightClock`; `NoFlight` = -1 - none).
    `TickFlight` puts the path's place where the flight has it, moves the
    bob's `FBobX` along and ends the flight a tick past its `Done` - the
    last tick of coming out of the depth is still drawn between the
    ticks. `Flying`; `Thrusting` - the pad works its jets hard: from
    `ThrustLeadTicks` (10) before it leaves its place in a flight until it
    is on its cell - the moment before is the tell of the pad about to go;
    `Settled` - in no flight, or its flight is over;
    `Behind` - in the depth, neither a floor nor a body; `Depth(alpha)` -
    0 in front .. 1 in the depth, eased; `FlushWith(other)` - the two
    stand flush side by side where their paths or flights put them. One
    tick only: `TurnedCorner` (a flight in front came onto its corner - in
    the depth a corner is turned out of earshot) and `Landed` (the flight
    ended on its cell).
  - The picture: `Draw(sprites, alpha)` - its height from the art's
    aspect, drawn at (`Round(Left)`, `Round(Top)` + `Lift(alpha)`) in
    fractions of a unit (`DrawRectF`), turned by `Tilt(alpha)`, in the
    depth smaller about its middle (`Middle` - from the picture's top-left
    corner, the one point `Draw` and the pad's rig shrink about;
    `DeepScale` 0.85) and darker
    (`DeepTone` 0.6) by `Depth(alpha)` - the riders are drawn with the same
    `Lift` (through the renderer's `FineY`), so the feet do not flicker
    into the deck - with the pad's tint set before every draw
    (`TintTexture`), as a static object is.
- **`TPadWorld`** - `Create(sprites, cache, level, reach, seed)`: `reach`
  is how far the hero jumps (`TJumpReach`, for the judge of a formation),
  `seed` the dice of the rebuilds; the cache is the
  level's object art, the textures are its; it and the level (the
  placements, and the grid a knock is tried against) must outlive the
  world; a picture the cache lacks raises here, at level load. `Tick(screen)` - before
  the riders move: a rebuild asked for may start (`StartAskedRebuild`),
  then every pad's `Tick`, on view for the pads of that screen alone - a
  pad elsewhere keeps its `Prev*` caught up and goes nowhere -, then
  `HearFlights`.
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
  `DeckSpannedBefore`), which carries them this tick. `DeckCrossed(screen,
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
  `FindTagged(tag)` - nil
  when no pad carries the tag; `Draw(screen, alpha, layer)` - the pads of
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
  `RequestRestore(group, load, release)` - the same ask with `Restore`
  set; `TryPlanRestore` plans every pad to its own place of the level
  file at `CalmPace` - no dice, no judge - and flies nothing when a
  pad finds no way: the caller asks again.
  `GroupRestored(group)` - every pad stands on its file place and none
  flies. `MembersOf(tag)` - the group's pads in file order;
  `GroupFlying`. `HearFlights` gathers what the tick sounded like, for
  the game to voice, one tick only: `CornerTurned` - a pad in front
  turned the corner of its flight; `PairDocked` - a pad landed flush
  beside one that is `Settled` (`DocksBeside`).

### `Game/Pads/Pads.Arena.pas` (~350 lines)
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
  or not, and its pads fly home (`arRestoring`).
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

### `Game/Hero.pas` (~1410 lines)
The hero: physics, weapons, death. Owns `HeroSize=32`; the screen size it
moves in comes from `Game.Space`.
- **Enums**: `THeroAction` (stand/walk/jump/fall x direction), `THeroCommand`
  (go/stop left/right, jump/stopJump, drop), `THeroForm` (hfNormal/hfIce),
  `TPendingSide` ('ExtraInstruction' of 2008 - a queued side intent executed
  once the barrier clears).
- **`THero`** -
  - Art: `hero.mset` (24 frames as the `walk`, `death` and `henshin` sequences)
    plus the weapon set, both owned; `OpenFrames` pulls named sequences out of
    a set.
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
    again. `LandOnDeck(prevY)` at the end of `Tick`, after the verbatim
    state machine: a deck the feet came down onto this tick, or one that
    rose into them (`DeckCrossed`), holds them at its `Top`, the
    acceleration zeroed - no downward move is needed, but a rising jump
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
    cloud x22 / chain x3 / minigun with alternating side shots), cooldown /
    speed / gravity state, `Fire: Boolean` (True = a shot actually left the
    barrel, so the caller barks the sound), `SetWeaponAngle` (verbatim, but
    the sine goes into `ArcSin` clamped to -1..1: feet on a fraction - a
    deck between the rows - round the distance down past the leg, and the
    NaN ended in `EIntOverflow`; a no-op on whole coordinates), `DrawWeapon`,
    the crosshair (`DrawCrosshair` frames 1..4 = the smart cursor colors;
    `CrossDX` / `CrossDY` - its calibration offset), the
    minigun muzzle live tuner (`NudgeMinigun`, DEBUGKEYS; read back through
    `MinigunBaseX`, `MinigunBaseY`, `MinigunMuzzleLen`).
  - Lifecycle: `Command`, `Tick` (verbatim OurHero.Timer), `Draw`, `SetMouse`,
    `PlaceAtCell`, `SetScreenX`, `SetY`, `ShoveX` (unit by unit, stops at
    walls), `ApplyWeaponPickup`, `Kill`, `Revive`; `Dead`, `HeroForm`
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

### `Game/Monsters.Hull.pas` (~230 lines)
A monster drawn as a hull out of layers instead of its `alive` frames -
the TeK platform, the TeK tank (3.0.45). The disc's twin without the iris:
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
  the mark on its hub at every turn of the body. The platform is never
  mirrored: its art is symmetric,
  and the torn panel of the worn layer would jump from side to side at every
  turn. `Spot(stand, point)` - where a point of the art falls on the
  screen, mirrored across the hull with the stand: the eye, the axles, and
  for the monster the
  smoke, the sparks and the short of a wreck.

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

### `Game/Monsters.pas` (~1650 lines)
Monster behavior (data-driven off `TMonsterDef`) plus the field managing them.
- **Enums**: `TMonsterAction` (stand/walk/fall/flying), `TMonsterLife`
  (mlAlive/Dying/Dead), `TMonsterHealthTier` (htHale/Wounded/Critical - the
  crosshair's thirds), `TMonsterEvent` (meNone/BossWantsMinion/Henshin/
  BossRage/LevelComplete/Died/BossCrashed/BossOwesPrize) - 'MessageToMain'
  of 2008, drained by the game loop every tick.
- **`TMonster`** - position, screen, the placement's `Tag`, direction, `Life`,
  lives (+`LivesAll`), anim frame, step, fire timer, enrage flag (`Enraged`), boss minion timer, a one-shot henshin
  flag, the event list, for a disc monster its `TDisc` (`Disc`, nil
  for the rest), for a hull monster its `THull` (`FHull`, nil for the
  rest) and for an `mkBossFly` monster its `TPilot`. Its own
  collision oracles
  (`CanGoLeftEdgeAware`/`WallOnly` pairs = CanIGo*1/2 of 2008, `CanGoDown`),
  `ShoveX`. Pads (a 2026 addition; the constructor takes the pad world):
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
  the cluster of five keeps its cross about it), `FirePorts` (a volley when the pilot says `PortsDue`:
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
  where the pilot holds the gun - its `Charge` instead). The hull:
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
  ticks; everything else - frames on the tick, alpha unused),
  `DrawSmoke(canvas, origin, alpha)`, `DrawSparks` (the same shape),
  `DrainEvent`, `HealthTier` (the
  crosshair's thirds of `LivesAll` as
  `TMonsterHealthTier` - the one home of that rule, via `ThirdMark`),
  `TierShare` (how full the current third is, 0..1), `TicksSinceHit` /
  `HitWithin(ticks)` (-1 until the first hit; the health rows read it, so the
  HUD keeps no memory of the field). `FSecret` is declared and always False -
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
  trial's gravels, at a random column one row above the screen - the fall
  is the entry), `SpawnOn(monsterId, screen, x, y)` (on the very place
  of a body at the point: a prize put into the hero's hands, the contact
  of the same tick collects it; both over the private `SpawnAt` in
  placement cells), `SetTaggedTactics(tag, tactics)` (the events' tactics
  action),
  `AnyAliveOnScreen` (the breakthrough gate - pickups count, verbatim),
  `AnyAliveTagged(tag)` (any live body carrying the placement tag, on any
  screen - the events' allDead), `AnyTaggedLivesBelow(tag, lives)` and
  `AnyTaggedEnraged(tag)` (live bodies only - livesBelow and enraged; the
  livesBelow mark is told for the normal grade and compared times
  `FLivesScale`, so a boss's marks keep their order on every grade),
  `FirstAliveTagged(tag)` (the first live body carrying the tag, nil when
  none - the arena's conductor), `FirstTagged(tag)` (the same, dead or
  alive - 3.0.39, the arena's ripple of a restore),
  `Draw(sprites, screen, alpha)` (each monster with the sprites' `FineY`
  set to its `DeckLift(alpha)` - `Origin` stays the monsters' shake -,
  `FineY` put back to 0 after),
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
- **Wreck sparks** (default behavior, no data): the same machines own a
  `TSparks` made from the `WreckSparks` look (a rare crackle: two sparks a
  second and an arc of about five every second and a half, ringing off
  the floor), unlit until the same moment - `WreckIfCritical` is the one
  trigger of the smoke and the sparks - then at full at once. The point
  (`WreckSparksX/Y`) mirrors like the smoke's - a hull's `Sparks` stands for
  it and for the short's, mirrored only with the hull; the probe is the monster's
  own screen (`SolidUnderPoint`: `TLevel.SolidAtPoint` or a pad's body,
  `BodyAt`); the seed is
  `SpawnSeed` (the spawn point, the smoke's seed too) under a salt, so the
  two do not roll alike. `TickSparks` after `TickSmoke`, `DrawSparks` over
  the smoke.

### `Hud/Hud.Messages.pas` (~335 lines)
- **`TMessageBoard`** - the 2008 message system: ticker lines (slide-in,
  private `TTickerLine` record), the big mid-screen headline, score popups
  (private `TScorePopup`, '+N' rising), and the comm terminal it owns
  (`Hud.Terminal`) in place of the 2008 marquee. `Tick` / `Draw(alpha)` - draw
  is interpolation-aware (popups, the ticker's step). API: `AddTicker`,
  `ShowBig`, `StartTerminal(header, text)`, `TerminalKeyStruck` (the game plays
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

### `Hud/Hud.Terminal.pas` (~245 lines)
- **`THudTerminal`** - the station's comm channel: a framed box (x=6, y=40,
  360 wide) under the heart monitor. A long text is word-wrapped by glyph count
  (45 per line - the small font is monospaced), typed by its own `TTypewriter`,
  held for 1 s plus a tick per letter, then faded in 1 s.
  `TTerminalPhase` = (`tpOff`, `tpTyping`, `tpHolding`, `tpFading`). `Start`
  (header, text; a newcomer replaces the current), `Clear`, `Tick`, `Draw`,
  `Visible`, `Bottom` (the ticker lane reads it), `KeyStruck` (every second
  typed letter that is not a space - the terminal makes no sound itself).
  Header `> ` + `terminalHeader` from the lang files today; a named speaker
  later. Box and cursor through its own `THudBrush`, text through the font.
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

### `Core/Render.Brush.pas` (~215 lines)
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
  pixel digits; `NumberWidth` measures), the cells every health row is made
  of - `FullCell` (fill + top sheen), `EmptyCell` (dim outline), `BonusCell`
  (lime with a shaded foot), all with an alpha so a row can fade -
  `BeginDraw`/`EndDraw` (blend mode on and off again - the rest of the game
  draws opaque).
- Panel geometry constants shared by both corners: `PanelMargin=6`,
  `PanelY=4`, `PanelH=32`, `PanelW=118`, `ReadoutY`, the cell row (`CellY`,
  `CellW=7`, `CellH=4`, `CellGap=1`), `DigitPixel=3`.

### `Hud/Hud.Vitals.pas` (~355 lines)
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

### `Hud/Hud.Marks.pas` (~290 lines)
Health rows over the figures, drawn with the brush; built by `CreateHud` in
the dpr with the corner HUDs. **`THudMarks`**.
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

### `Game/Game.Explosions.pas` (~300 lines)
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
  barrel blasts within 24 units over 50 ticks - the wreck keeps popping).
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
in the dpr). A 2026 mechanic: 2008 wounded with a fan of 180 bullets.
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

### `Game/Game.Impacts.pas` (~350 lines)
What a bullet throws off the armor it strikes - the look only; the wound,
the knockback and the sound stay with the dpr. **`TImpacts`**, made once
with the game (the solid probe), cleared on a door, a death and a level
load.
- **`TStrike`** (record) - a bullet meeting armor: the point, the bullet's
  speed, the normal (the way the armor faces there), `Rapid` (the armor
  was struck a moment ago), `ExtraSparks` (sparks on top of the fan - a
  heavier blow throws more; 0 for a bullet - both builders in the dpr
  start from `Default(TStrike)`).
- `TraceEntry(strike, box)` - the bullet is already inside the hitbox:
  moves the strike back along its path to the edge it came in through (no
  further than one tick) and turns the normal the way that edge faces; a
  bullet hanging still (the aura) gets the normal up.
  `FaceFromCenter(strike, center)` - round armor: the normal from the
  center through the point (the boss's disc).
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

### `Game/Orbs/Orbs.Flock.pas` (~435 lines)
The orbs: small lights that fly by a formula, not by ballistics, and take
no notice of matter - no wall stops one. The look and the life of an orb
only: where it is, its owner decides tick by tick; what it strikes, and
what that costs, the game does (`ResolveOrbHits` in the dpr).
- **`TOrbTint`** (record) - `Core` (the white-hot point) and `Glow`.
  `IceOrbTint` is the one tint so far: the hero's element on levels 1-2.
- **`TOrbState`** = (`osAlive`, `osImploding`, `osGone`).
- **`TOrb`** (class) - `X`, `Y`, `Size` and `Level` (shares 0..1 of the full
  size and light, written by the owner - an orb coming into being), `Age`
  (ticks), `State`. `MoveTo(x, y)` - where the owner's formula puts the orb
  this tick; the step piles up until the flock's next tick, and between
  ticks the orb is drawn on ahead by it, as sparks and smoke are.
  `MoveBeside(x, y, bodyStepX, bodyStepY)` - the same for an orb that keeps
  beside a body drawn where the tick left it (the hero): the body's step
  is taken out of what the orb is drawn ahead by, or the ring would
  tremble against him. `Armed` (True from birth, written by the owner):
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
  behind with their faces. `Draw(canvas, origin, alpha)` - the marks,
  then three point glows an orb through `Render.Glow` (the halo,
  breathing; the body; the core), then the dust; `Clear`.
- The sizes and the lights are constants at the top of `implementation`
  (`HaloAcross`, `BodyAcross`, `CoreAcross`, the breath, the implosion,
  the dust, the mark).

### `Game/Orbs/Orbs.Harvest.pas` (~240 lines)
Where the orbs of an aura come from (3.0.32): the matter around the hero.
One function and no state, over `Game.Space` and the dice alone - it can
be tried with no game behind it.
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
and the rain step). What a drop strikes is the game's to settle through
`Flock` (`ResolveOrbHits` in the dpr), as for the aura.
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

### `Game/Game.Henshin.pas` (~280 lines)
The transformation ceremony as one automaton, lifted out of the dpr (3.0.2):
the 3..2..1 prelude (2026), the five converging healing waves of 2008, the
flash, the suit going on - and the suit coming off. **`THenshin`** takes the
stage it acts on (hero, sound bank, message board, shake meter) plus a
`TCureHero` callback (`reference to procedure`) for the one thing it does not
own, the hero's health; the game passes its `CureHero` method directly.
Reborn with the hero on every level load.
- `StartCountdown(henshinAtTick)` (the boss path: prelude, then the
  cinematic), `Start(atTick)` (straight in; 30 skips the first wave - the
  gravel trial), `Tick` (prelude and cinematic in one breath, every logic
  tick, even over the corpse), `DrawCountdown(font, alpha)` (the growing,
  dissolving digit, topmost), `RemoveIceForm` (the shatter fan, no sound of
  its own), `Reset` (restart: everything dies, the suit comes off silently).
- Owns its schedule and tuning: the wave table (`Waves[0..4]`:
  tick/bullets/radius), `FlashTick=135`, `FinishTick=140`, the regen and perk
  ticker lives, its two shake doses (`WaveTrauma`, `FinishTrauma`), the
  countdown tuning, and its sound names - loaded strictly in the
  constructor. `BottleSoundFile` is public: the barrel burst doubles as the
  bonus explosion and the pops of the boss's wreck, and the dpr reads the
  name from here.

### `Game/Events/Events.Director.pas` (~175 lines)
Runs the level's events (`Levels.Events`) against the live game.
**`TEventDirector`** takes the events, the message board, the level's
dynamic objects and two callbacks (`reference to procedure`): `TChangeMusic` (the game passes its
`ChangeMusic` method, which also remembers the track for restarts) and
`TArenaCues` (3.0.39; a record of two `TArenaCue`s: the game passes
`TPadArena.Engage` and `TPadArena.Restore`). The
monster field is reborn on every restart, so it arrives with every tick
instead of being kept: asked for the conditions, told the tactics.
- `Tick(screen, field)` - once per logic tick with the hero's screen: for
  every unfired event of that screen, the condition is checked
  (`ConditionHolds`); while it holds the delay counts down, a lapse starts
  the count over; at zero the actions play once (`Play`: `ShowBig`,
  `AddTicker`, `StartTerminal` with the terminal header, the music
  callback, `FadeTagged` / `TurnSunTagged` on the dynamics,
  `SetTaggedTactics` on the field, the arena cues for `rebuild` and
  `restore`). The game skips the tick over
  the hero's corpse.
- `ReArm(screen)` - death re-enters the screen with its monsters reborn,
  so its events wait for their moment again, as the entity triggers do,
  and the dynamic objects their intensity actions turned are rewound
  (`RewindTargets` -> `RewindTagged`) - the boss stops smoking again.
- Reborn with the level (`LoadLevel`), like the ceremony and the HUD.

### `Core/Render.Glow.pas` (~210 lines)
Light drawn instead of loaded: white textures with the shape in their alpha,
additive, linear-filtered, so one texture serves every tint and level.
- **`TGlowShape`** = (`gsPoint`, `gsFlare`, `gsStarburst`, `gsStreak`) - a
  Gaussian point, a four-spike flare, the long thin cross of a starburst
  (rays thinner than a flare spike and slower to fade) and the streak of a
  spark (it lies along X: full at the hot end by the right edge, rounded
  off over `StreakCapShare`, the tail thinning out to the left by
  `StreakTailPower`), analytic (`PointSigma`, `Flare*`, `StarburstRayWidth`,
  `Streak*` metrics in half-sides).
- Free functions: `CreateGlowShape(renderer, shape, side)`,
  `CreateGlowTexture(renderer, surface)` (a shape computed elsewhere - the
  logo halo - arrives as a surface and leaves with the same settings),
  `DrawGlow(renderer, texture, cx, cy, size, tint, level)` (centered
  square), `DrawGlowRect(..., dest, tint, level)`. Tint = color mod, level =
  alpha mod.
- Users: the stars, the embers, the logo halo, the beacons, the heat of a
  smoke puff, the explosion flash, the sparks (`gsStreak`; the blast's with
  `gsPoint`) and hot shards, the flash of a hit and of an arc, the sensor
  eye of the boss's disc. `EGlowError`.

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
shared with `TGlowShape` and the dpr's `TGameState` - axis roll and tip, night
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

### `Menu/Menu.Logo.pas` (~285 lines)
The title logo and the light it sheds. **`TMenuLogo`** loads `logo.png`
(2:1, letters alone on transparent) and builds everything else from it, so a
redrawn logo brings its own glow.
- Halo: the letters' alpha shrunk 4x into an apron-padded image, three box
  blurs (`HaloBlurRadius=5`, `HaloBlurPasses=3`), normalized to a peak of one,
  handed to `CreateGlowTexture`; tinted with `InkTint` (the mean ink color
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
  hint lives here), hides the OS cursor (the game draws its own) and stamps
  the renderer backend and SDL version into the title once. Properties
  `Renderer`, `Window`. `Run(app)`: event pump, fixed-step accumulator at
  the config's `TickRate` (33 by default; a stalled frame is clamped to
  `MaxFrameSeconds=0.25`), frame-budget wait for the no-vsync path. The
  once-a-second fps title with worst-frame diagnostics is compiled only
  under `TITLESTATS`, off in `Moon2D.inc`. `EGameHostError`.
  `TKeyAction` = (kaDown, kaUp).

### `Moon2D.dpr` (~2565 lines - NOT a stub, always grep it too)
Composition root plus the whole game-flow state machine (`TMoonGame`).
- **Top constants**: the level discovery pattern, config file name, asset dir
  names (`SoundsDir`, `MusicDir`), the weapon->shot sound map, named one-shot
  sounds (the bonus cost lives in `Game.Bonus`; the three of an arena
  rebuild - `PadHumSoundFile`, `PadClickSoundFile`, `PadClackSoundFile`),
  `VictoryMusicFile`, `MenuMusicFile`, `LevelEndLingerTicks=400`,
  per-difficulty hero health and monster-lives multipliers, gravel trial
  cadence and monster (`GravelMonsterId`), ticker durations, damage
  bookkeeping (`HurtMercyTicks`,
  `GameOverDelayTicks`, `PitDepthY`), `OrbReach` (how near an orb takes an
  enemy bullet), the font choice (`FontFileName`,
  `FontOrientation`, `FontFiltering`), `AuthorLinkedInUrl`, `MaxLevelSlots`,
  extra scancodes (`ScancodeS` - the drop - among them; the debug ones
  under DEBUGKEYS), the screen-shake doses
  (`ExploderTrauma`, `BossBlastTrauma`, `BonusExplosionTrauma`,
  `AftershockTrauma`, `BossCrashTrauma` - a 2026
  addition; the
  ceremony's own live in `Game.Henshin`), ending-screen layout rows. The
  three developer-facing errors are resourcestrings in English, outside
  the dictionaries (`SNoLevelsFound`, `SSpriteSetMissing`, `SAmbiguousSprites`).
- **Types**: `TGameState` (gsMenu/gsIntro/gsPlaying/gsEnding).
- **`TMoonGame`** (extends `TGameApp`) - holds the registry (owned by
  `RunGame`) and owns the rest: level, the
  level's sprite sets and its three caches (tiles, backdrops, objects), the ui
  and weapon sets, the sprite, tile, object and dynamic-object renderers
  (`FDynamics`, reborn with the level, freed before it), the pad world
  (`FPads`, reborn with the level, freed before the object cache), hero (his burst is
  his own, `THero.Bullets`), monster
  field, the shared enemy burst (`FMonsterBullets`), font, message board,
  the briefing (`THudBriefing`), the screen shake, sound bank,
  menu, the explosions and the impacts (`FExplosions`, `FImpacts`, one of
  each for the run), the hero's aura (`FAura: TAura`, one for the run
  too), the ceremony
  (`THenshin`), the event director (`TEventDirector`), the arena of the
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
  gravel trial (attack flag, quota, wave timer, screen), the
  end-level timer, the level list + current file + current music, fullscreen,
  difficulty.
  Method clusters:
  - Flow: `Update`, `Render` (the layer order there is the shake spec: backdrop
    still, the backdrop layer of the dynamics on the world channel - a
    haze bends the still backdrop where its jolted pad is -, the sky
    dynamics (the Earth) still again, objects + pads + back
    dynamics + tiles + bullets on the world channel -
    objects stand on the tiles and jolt with them, the pads draw right
    after the objects (with the frame's alpha - their sway between ticks):
    the pads in the depth, what hangs on them (`FDynamics.DrawSunk`), then
    the pads in front;
    the back dynamics right after the pads, behind tiles
    and hero - monsters (the field gets
    the frame's alpha:
    the boss's disc draws between ticks), then the
    machines' wreck smoke and sparks, then the front dynamics (the boss smoke and
    lamps), on
    the monsters' channel - the explosion plumes before them, right after
    the tiles, the explosion debris and flashes after the bullets, then the
    impacts (on the monsters' channel - they sit on armor), then the
    health rows (`FMarks`, each on its figure's channel) - the
    hero on
    his own, with `FineY` = `FHero.DeckLift(alpha)`, back to 0 right after
    his draw -, cursor and HUD still; `Update` ticks the pads right before
    the hero
    (`FPads.Tick(FHero.Screen)`, then `FHero.Tick` - the riders move with
    their decks, then by themselves; right after the pads' tick it voices
    a rebuild - `padclick.wav` on `CornerTurned`, `padclack.wav` on
    `PairDocked`), ticks the arena right after the director, both skipped
    over the hero's corpse (`FArena.Tick`, then `padhum.wav` on
    `Warned`), and `FDynamics` after the monsters
    and the director, so a smoking monster's puffs leave from where this
    frame draws it), `LoadLevel` (the tile cache refuses a palette name two
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
    for restarts; '' is a no-op), `HeroRides(pad)` (the `TPadLoad` of the
    rebuilds: the pad under the hero - monsters are no riders, they fall
    through a pad that goes deep), `LocateParent` (the `TLocateParent` of
    `Render.Dynamics`: a pad first (`FindTagged`) - its screen, `Left` /
    `Round(Top)` + `Lift(1)` (where the pad is drawn as the tick leaves it -
    a fraction, the stand's Y is a `Single`), alive, its effort (1 while
    the pad is `Thrusting` - what hangs on it surges), and how deep it
    stands (`TParentDepth`: the pad's `Depth(1)` and `Depth(0)`,
    1 - `DeepScale`, 1 - `DeepTone`, its `Middle`) - what hangs on a pad
    goes into the depth as the pad's own picture does; else the
    first monster carrying the tag - screen, sprite top-left as
    `TMonster.Draw` puts it (Y lowered by `DeckLift(1)`), alive, and for a disc monster the
    disc's last two poses with the axis in the middle of the sprite;
    `Levels.Defs` has refused a tag both carry).
  - World: `HandleScreenTransitions`, `ArriveOnScreen`, `HandlePitFall`,
    `PinRespawnPoint` (the level's respawn point of the hero's screen
    becomes the checkpoint - the cell taken to the hero's corner and feet
    line as `THero.PlaceAtCell` does; called after `FireScreenTriggers` in
    `ArriveOnScreen`, `StartPlaying` and `RestartLevel`, so the point has
    the last word over the entry point and over the triggers; the hero
    himself is not moved),
    `FireScreenTriggers`, `TickGravelAttack`; the events are the director's
    (`FDirector.Tick` after the tick's verdicts, `ReArm` in `RestartLevel`).
  - Combat: `ResolveHeroBulletHits` (the bullet ends in `SpendBullet`: in
    its own burst or, on a monster whose `material` is metal, with no
    burst at all - a strike for `FImpacts` built by the free `ArmorStrike`
    (honest screen units, the hitbox as a box, `HitInset`; `Rapid` asked of
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
    `MonsterBody`: `TakeDamage` with the blast's knock and lives, the
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
    a monster of any kind by `MonsterBody` (`TakeDamage` with half the
    shard's speed as the knock, `RewardMonsterKill` on a death) or the
    hero by `HeroBody` (one health, the mercy window holds); on the
    blast's own floor a shard is decoration,
    `ResolveMonsterContact`, `RewardMonsterKill` (also the `TBlast` of a
    monster with a `blast` and `Detonate` of the monster's `explosion`,
    both at the middle of its sprite, in the tick of the kill; the debris
    is detonated live with the blast's `ShardLives` scaled by
    `DifficultyMonsterLives`), `HurtHero`, `DrainMonsterEvents` (also where explosions and boss
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
    (`NoteHeroContact` - the pilot's prize rule), `EchoAftershock` (the `TEchoAftershock` of
    `Game.Explosions`: each pop of the boss's wreck plays `bottle.wav` and
    adds `AftershockTrauma`), `SolidUnderPoint` (the probe of debris, impacts and
    dynamic objects: `TLevel.SolidAtPoint` or a pad's body (`BodyAt`) for
    the hero's screen, honest screen units - no bullet -1 row), `ProcessKillStreak`, `AwardStreakBonus`.
  - Bonus: `CureHero` (+1 up to 10 - also the ceremony's cure callback),
    `AwardRandomBonus` (the headline carries the mouse hint until the first
    reward is spent), `ActivateQueuedBonus` (pays `BonusCost` on use; the
    aura reward goes to `CastAura`). The
    ceremony itself is driven through `FHenshin`: started
    by `meHenshin` (countdown) and the gravel trigger (straight in), ticked in
    `Update`, drawn last in `Render`, reset in `RestartLevel`.
  - Orbs: `CastAura` (the aura reward and the G debug key: `FAura.Cast`
    around `HeroCenter`, the middle of the hero's body, out of
    `MatterAround` - the solid cells of the hero's screen and the bodies
    of its pads, `FPads.Bodies`; then the mercy window of a hit,
    `FHurtCooldown := HurtMercyTicks`, because the ring is no shield
    until the orbs are in it - the HUD blinks as after a hit, a pit hurts
    as ever; over the corpse it does nothing). `Update` ticks the aura
    right after the impacts
    (`FAura.Tick(HeroCenter)`) and calls `ResolveOrbHits(FAura.Flock)`
    between `ResolveHeroBulletHits` and `ResolveMonsterBulletHits`, so an
    orb takes a bullet ahead of the hero. For every orb alive and armed
    (an orb still on its face is not): an enemy
    bullet in flight within `OrbReach` of it on both axes
    (`EnemyBulletNear`; a bullet's point is at its Y - `SpriteSize`)
    bursts and the orb is spent; else a living dangerous monster of the
    hero's screen whose body holds the orb (`DangerousMonsterAt` over the
    free `MonsterBody` - the box `ArmorStrike` takes too - and `BoxHolds`)
    loses a life (`TakeDamage`, `RewardMonsterKill` on its death) and the
    orb is spent. Not through `SpendBullet`: armor answers an orb with no
    sparks and no ping. `Render` draws the aura after the bullets, on the
    world channel. `HandleScreenTransitions` takes it through a door by
    the hero's whole step, the teleport of a trigger of the new screen
    included (`FAura.Carry`) - `ArriveOnScreen` leaves it alone;
    `HurtHero` collapses it on the hero's death; `LoadLevel` and
    `RestartLevel` clear it.
    The rain: `PourRain` (the fire rain reward - `bkFireRain` in
    `ActivateQueuedBonus` - and the H debug key: `FRain.Pour` over
    `MatterAround`; over the corpse it does nothing; no shake, no mercy
    window). `Update` ticks it right after the aura (`FRain.Tick`) and
    calls `ResolveOrbHits(FRain.Flock)` after the aura's - one verdict for
    both flocks; `Render` draws it right after the aura (`FRain.Draw`).
    `HurtHero` collapses it (`FRain.Collapse`); `LoadLevel`,
    `RestartLevel` and `ArriveOnScreen` clear it - a door puts the rain
    out, as it does bullets, while the aura goes through with the hero.
  - Drawing/input: `AdvanceBriefing`, `DrawEnding`, `DrawCenteredBig`,
    `HitEndingLine`, `HandleEndingClick`, `CrosshairFrame`,
    `HandleKey/MouseMove/MouseButton` (S/Down hold `FHeldDown` - the drop
    through a pad).
  - Debug: `HandleDebugKey`, `HandleDebugMenuKey`, `UpdateInspectorCaption`,
    `DrawAtlasOverlay` - the four doors the debug keyboard uses, and nothing
    else. All four exist in every build; their bodies compile away, so no
    caller needs an ifdef. Behind them: `CastAura` (G: the aura straight
    onto the hero, the slot untouched), `PourRain` (H: the fire rain over
    the hero's screen, the slot untouched), `NudgeCrosshair`,
    `NudgeMinigunMuzzle`, `DebugBrowseScreen`, `CycleFontFiltering`,
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
  off-screen helpers, `MonsterBody` and `BoxHolds` (a monster's body as a
  box in honest screen units, and whether it holds a point),
  `SaveTargetAsPng` (under DEBUGKEYS: the current
  render target into a PNG through `IMG_SavePNG`), `ReadLevelTitle`,
  `DiscoverLevels`, `RollDiceSeed`, `RunGame` (the actual
  main: config -> language -> level discovery -> registry -> host -> game).

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

### `tools/sounds/pads.py`
Synthesises the sounds of an arena rebuild into `bin/sounds`: `padhum.wav`
(the warning: two low buzzing tones a hair apart, climbing, throbbing at
the rate the alarm lamps blink), `padclick.wav` (a pad turning the corner
of its flight: a small latch, the armor ping's plate higher and shorter)
and `padclack.wav` (two pads docking: two latches over a thump). Borrows
`strike`, `finish` and `save` from `armor.py` beside it. Seeded. numpy.

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

---

## Tests

The concept, the rules and the tables of tests are in `docs/TESTING.md`.

### `Tests/` - the test suite (console app, DUnitX)
Fourth project of `Moon2D.groupproj`. Tries what the game counts, not
what it draws: no window, no SDL call. Game units come in through the
project's search path (`..\Core`, `..\Game\Orbs`); the executable goes
to `bin\`.
- **`Moon2D.Tests.dpr`** (~45 lines) - the runner: every registered
  fixture, a verbose console log, the exit code (0 - green). A test that
  asserts nothing fails.
- **`Orbs/Tests.Orbs.Flock.pas`** (~295 lines) - **`TOrbFlockTests`**:
  the life of an orb in a flock through its public face - the order of
  `Add` / `Insert`, aging, the three ends (`Implode`, `Spend`,
  `Release`), what `Tick` drops, `Shift`, `Clear`. A fixture registers
  itself in its unit's `initialization`.
- **`Game/Tests.Game.Blasts.pas`** (~270 lines) - **`TBlastTests`**: the
  wave of `Game.Blasts` - a near body before a far one, a body struck
  once, none beyond the radius, a wall's shelter, the lives and the knock
  by the distance and the grade, and the barrel of monsters.json against
  the 50-life gunner of level 2.
- **`Monsters/Tests.Monsters.Damage.pas`** (~235 lines) -
  **`TDamageWindowTests`**: the window alone - the cut at the cap, the slide
  of the window, no run of `Ticks` ticks over the cap, the hero's chain gun
  and grenade volley never cut; **`TCappedBossTests`**:
  `boss1` on one tick takes no more than the cap, and a blow over it still
  shoves him.
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

### `monsters.json` (~12 KB)
Keys: `version`, `comment`, `defaults` (bound, spritesToDeath, animFreq, score,
dangerous - inherited by monsters), `monsters` array. 15 ids: `gravel`,
`gravelFemale`, `winter`, `zombieShooter`, `betoner`, `platform`, `tank`,
`mount`, `barrel`, `medkit`, `weaponShotgun`, `weaponGrenade`, `weapon3`,
`weapon4`, `boss1`. Parsed by `TMonsterRegistry` into `TMonsterDef` (see
Monsters.Defs above for the full field sheet). Nine of the fifteen carry no
`spriteList` - theirs comes from the level placement instead. `explosion`
names the look of a death: `barrel` (the barrel), `machine` (the tank, the
platform), `boss` (`boss1`); the mount has none - it explodes inside the
wall. `blast` (the barrel, the tank, the platform, the mount) is what the
death does to the bodies around: `radius` 80, `lives` 100 and `shardLives`
6 on all four - see `TBlastDef`. `material`: `metal` on the platform, the tank, the mount, the barrel
and `boss1` - a bullet throws sparks off them instead of bursting
(`Game.Impacts`). `disc` (only `boss1`) draws the living monster as a spinning disc out
of the layers of a set instead of its `alive` frames: `set`, `side`,
`muzzle`, `spin`, `irisReach`, `wearFull`, `portAngles` (the six gun
ports of the ring art: 0, 51, 129, 180, 231, 309) - see `TDiscDef`. Its
`boss` block names `dodgePrize`: `medkit`. `hull` (`platform` and `tank`) draws
the living monster as a hull out of the layers of a set: the platform's -
`set` (`platform-hull`), `width` 40, `height` 20.33, `wearFull` 80, and the
points `eye`, `smoke`, `sparks`; the tank's (3.0.45) - `set` (`tank-hull`),
`width` 38, `height` 31, `wearFull` 80, the same points, `mirrors`: true,
`wheels` (`side` 16, `radius` 7.76, two `axles`) and `muzzle` (5.5, 5.4 -
the cut of the middle barrel) - see `THullDef`. `stats.damageCap` (only `boss1`)
limits the lives he may lose: `lives` 30 in any `ticks` 33, a second - see
`TDamageCap`. The cap does not grow with the difficulty, as the lives do:
the hero's guns do not either.

### `level1.json` (~97 KB) / `level2.json` (~36 KB)
The unified level format, parsed by `TLevel`. Keys: `version`, `id`,
`title`/`titleEn`, `assetsDir`, **`spriteSets`** (the environment sets, in resolution order),
**`objectSets`** (optional: shared object art searched after the level's own
objects set, e.g. `["sky"]`),
`music`, `legacyTrailing` (a migration artifact, cleanup pending), `grid`
(16x12), `backgrounds` (fromScreen + image + optional `tint`, three
percentages), `objects` (optional: sprite, screen, x, y, width in screen
units, optional `tint`, optional `tag`), `pads` (optional: sprite, screen,
x, y - the deck -, width in screen units, optional `tint`, optional `tag`,
`bullets` block / pass, block when absent, optional `path` - `route`,
`stops`, `speed`, `pause` -, `bob`, `group` and `rig` - the rigs it wears;
see `Levels.Pads`),
`padGroups` (optional: `tag`, `screen`, `zone` [left, top, right, bottom]
in cells, `pairs`, `farFlight`, `farShare`, optional `conductor`, `every`
and `alarm` - the pads rebuilt together, see `Levels.Pads`), `rigs`
(optional: named lists of dynamic objects with no place of their own, a
number of a part may be `{"spread": [from, to]}` - see `Levels.Rigs`),
`respawns` (optional: `screen`, `x`, `y` - the cell a pit and death
return the hero to, counted as an entity's - see `Levels.Defs`), `dynamics`
(optional: `kind`
(beacon / smoke / globe / sparks / fan / haze), `screen`, `screens`
[first, last] or `parent` -
a static object's, a pad's or a monster's tag -, `x`, `y`, optional `tint`, `tag`,
`layer`, `intensity`, `surge`, `turns`
(under a spinning parent), then the
kind's own properties - see `Levels.Dynamics`),
`tilePalette`
(sprite names in their 2008 file spelling - `level1\doom1.png`, `base1.png` -
or qualified `set:name` when two declared sets share a name; index N in
tiles -> palette[N-1]), `tiles` (`encoding` "csv-rows" and `emptyValue` -
informational, unread; `note`; `screens` - one object per screen: `screen`,
`rows` (12 strings of 16 comma-separated palette indices) and `collision`
(12 strings of 16 '0'/'1', 1 = solid - the grid `SolidAt` reads)),
`entities` (placements:
monsterId, screen, x, y, spriteList, optional `difficulty` grades (parsed,
unused by both levels),
`overrides` (direction / speed / lives / canShoot), `triggers` -
messages/hints/changeMusic/heroX-heroY/gravelBoss (the wave quota per
difficulty),
optional `tag` for the events and the dynamics, optional `rig` - the rigs
the monster wears, which takes the tag (see `Levels.Rigs`); `secret` on one level-1
medkit is data nobody reads yet), `events` (each: `id`,
`screen`, `when` = enterScreen | allDead / enraged + `tag` | livesBelow +
`tag` + `lives`, optional `delay` in ticks, `then` = a list of `action`
objects - bigMessage/smallMessage/hint with `text`/`textEn`, music with
`file`, intensity with `target`/`value`/`ticks`, sun with
`target`/`value` (degrees)/`ticks`, tactics with `target`/`value`, rebuild
and restore with `target`; the med lab hint, `labHint`, is the
plainest example), `introText`/`introTextEn`.
- level1: 17 screens, 145 entities, a 156-tile palette, 4 backgrounds - night
  (1-7), pre-dawn (8-11), `_black` for the fully tiled lab screens 12-13,
  sunrise (14-17); sets
  `brickwork mine-structure facility conveyor mining-rig railway mine-walls
  cargo mine-interior`. Objects: the ship on screen 1 (in place of the 2008
  shuttle), the broken satellite in the sky of 14-17, tagged `ship` and
  `satellite`. Pads: the 21 platforms of screens 16-17 (`s16-platform`,
  `s16-platform-out`; tagged `s16-plat-01`..`11` and `s17-plat-01`..`10`,
  bullets block) - static objects over solid cells before, the cells now
  cleared from the grid; the lamps hung on them keep the same tags. Every
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
- level2: 9 screens, 38 entities, a 35-tile palette, 4 backgrounds - day
  (1), the chasm edge (2), rock (3-5), the same rock darker (6-9); sets
  `moon-surface machinery facility common mine-interior`. Object: the
  satellite on screen 1, lit a little brighter (day), tagged `satellite`;
  the Earth on screen 1 as level 1 left it, a thinner crescent (sun 70, no
  events); the satellite's lamp is `dying` - a dim fast flutter, the battery running out, and
  one leak is left, a puff now and then (`flow` puffs); the breach still
  sparks, at intensity 25 - a spark now and then. Sixteen fans (`fan`:
  the `turbine` rotor behind the `bezel` plate over the `shaft` back, one
  cell each) stand where the 2008 tiles `cooler1`-`cooler4` and `ventelat`
  stood - the cells are empty in the grid and solid as before, the names
  stay in the palette: two at 150 turns a minute on the floor of screen 3
  with a `louver-2x1` object between them, fourteen at 180 on the ducts
  of screen 9 with the red of the old grille for a light, one of them
  `dying`. The one TeK platform, on screen 6, is tagged `s06-tek-01` and
  wears the rig `tekPlatform` - the numbers of level 1, written again in
  this file's `rigs`. Screens 1-3 are repainted (`docs/REPAINT.md`).
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
  at 64 in the sealed chamber under the corridor. `tunnel-gate` and
  `s03-room` are the level's own art, the set `level2-objects`. The
  gravel trial
  lives here (screen 9: the `gravelBoss` trigger, quota 75/125/200 by
  difficulty, under `boss2.ogg`) - there is no boss monster - and it ends
  the original campaign.

### `sprites\*.mset` (40 sets)
- **Hero and weapons**: `hero` (the walk/death/henshin sequences),
  `weapon` (held gun frames, bullets, crosshair),
  `weapon1`-`weapon4` (the pickups).
- **Entities**: `gravel`, `gravel2`, `vinter`, `shoot1`, `betoner`, `barrel`,
  `medic`, `krep`, `platform`, `tank`, `boss1` - referenced by a placement's
  `spriteList`, still spelled `<stem>.mns`. All frames are 64x64, 2 px a
  unit, but one: `barrel` carries the HD sprite `barrel` (128x128, 4 px a
  unit; its `alive` is that one frame eight times over) beside the 2008
  frames `boch1`-`boch4` (the `alive-2008` sequence, which nothing asks
  for).
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
  (`tunnel-gate`, 6 px a unit; `s03-room`, a whole screen at backdrop
  density) - the `<assetsDir>-objects` convention, never declared,
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
  panel for a static object, 64 by 32 units.
- **Interface**: `ui` - `sky` (16:9 nebula), `moonmap` (2048x1024 lunar
  surface), `logo` (letters alone), the language flags (240x160) and the
  `font`/`fontx`/`fonty` atlases plus `fonty-2008` (the original 448x448
  atlas, kept, unreferenced). Stars, halo and embers are generated.

### `lang/en.json` / `lang/ru.json` (~2-3 KB)
Flat key->string dictionaries for UI and gameplay text (every `S*` key of
`Localization.pas`): tickers, streaks, henshin/bonus, ending screen, the full
menu vocabulary. Level and monster content is NOT here - it is localized in
place in the level and monster JSONs via the base-field + `En`-sibling pattern.

### `sounds/` (27 WAV) and `music/` (OGG)
One-shots are preloaded at startup and fail loudly when a file is missing;
music loads leniently. Four one-shots are synthesised by
`tools/sounds/armor.py`: `armor1..3.wav` and `ricochet.wav`; a fifth,
`crash.wav`, by `tools/sounds/crash.py`; three more - `padhum.wav`,
`padclick.wav`, `padclack.wav` - by `tools/sounds/pads.py`. Tracks named by code: `moon.ogg` (menu,
`MenuMusicFile`), `win.ogg` (`VictoryMusicFile`). By data:
`moon_surface.ogg` (level 1), `underground.ogg`, `moon_surface2.ogg`,
`boss1.ogg`, `boss1b.ogg` (the boss's `rageMusic`), `hallu.ogg` (level 2),
`under01.ogg`, `boss2.ogg`. Ten OGG files, all used.

---

## Quick task-routing table

| Task smells like... | Look at |
| --- | --- |
| Hero movement / collision / jump feel | Hero.pas |
| Pads - platforms apart from the grid: decks, the drop through one (S/Down), what a body stops, a lamp hung on one; paths, the bob and the sag, riding; the ram's knock | `pads` in levelN.json + Levels.Pads.pas (model, parser) + Pads.World.pas (decks, bodies, picture; paths, bob and sag - `Tick`, `Lift`, `Press`; riding - `DeckCarrying`; the knock - `Shove`, `RoomFor`, `Knock`, `Tilt`) + Monsters.Pilot.pas (`TPilotCrash.Blow`, `LapHolds`) + Hero.pas (`DeckUnderFeet`, `RideDeck`, `LandOnDeck`, `DropThroughDeck`, `DeckLift`) + Monsters.pas (`FloorAhead`, `StandsOnDeck`, `RideDeck`, `MoveFalling`, `DeckLift`) + Monsters.Pilot.pas `Walled` + Moon2D.dpr `BulletStruckWall` / `LocateParent` (+docs/PADS-PLAN.md for the plan) |
| The arena rebuild of a boss fight: which formations play, how the pads fly and avoid one another (and the conductor's body, and the ground outside the zone), the depth, the wave behind the boss, the warning, how often, the sounds; the calm restore of the pads after the boss dies and its ripple | `padGroups` + the `rebuild` / `restore` events + the alarm beacons in levelN.json + Pads.Formations.pas (dice, judge, assignment) + Pads.Flights.pas (the L, `TFlightPace`, `TFlightBrief`, `TFlightBar`, the plan, deep flights) + Pads.World.pas (`RequestRebuild`, `RequestRestore`, `TryPlanRebuild`, `TryPlanRestore`, `FlightBarOf`, `TickFlight`, `Depth`, `HearFlights`) + Pads.Arena.pas (phases, `ReleaseOf`, `LapBars`, `RippleOf`, `WarningTicks`) + Monsters.Pilot.pas (`HoldLap`, `LapAhead`) + Hero.pas `JumpReach` + Events.Director.pas (`TArenaCues`) + Moon2D.dpr (`FArena`, `HeroRides`, `DebugRebuildPads` - the R debug key, `DebugRestorePads` - Y) + tools/sounds/pads.py (+docs/PADS-PLAN.md) |
| The boss's rage: when it starts, how fast the gun fires in it; when the aimed gun is silent | Monsters.pas (`BossRageLives`, `BossRageFireRate`, `ProcessBossThresholds`, `AnyTaggedLivesBelow`) + Monsters.Pilot.pas `GunHeld` + the `livesBelow` / `enraged` events of level1.json |
| Weapon patterns / crosshair | Hero.pas (+Bullets.pas) |
| Monster behavior / AI / boss | Monsters.pas + Monsters.Defs.pas + monsters.json |
| The boss's flight: the lap, the maneuvers (ponder, dive, ram, stun), their numbers | Monsters.Pilot.pas (+Monsters.pas `MoveFlying`, `FirePorts`, `EyeTarget`; the `tactics` events of level1.json; `portAngles` / `dodgePrize` in monsters.json; Moon2D.dpr `ThrowCrashSparks`, `PayDodgePrize`; tools/sounds/crash.py) |
| The boss's disc: layers, spin, eye, wear, the shot from the rim | Monsters.Disc.pas + `disc` in monsters.json + `boss1-disc.mset` (+Monsters.pas `TickDisc`, `FireAt`) |
| The hulls of the platform and the tank: layers, wear, eye, wheels, mirroring, where a hull stands, where its straight shot leaves, the wreck points | Monsters.Hull.pas + `hull` in monsters.json + `platform-hull.mset`, `tank-hull.mset` (+Monsters.pas `TickHull`, `HullStand`, `BodyPoint`, `FireAt`; Render.Sprites.pas `DrawSized`; tools/tank/build_tank.py makes the tank's set) |
| The platform's lamps and the haze under its nozzles; what goes out when a monster dies | the rig `tekPlatform` + `"tag"` and `"rig"` on the platforms in levelN.json + Levels.Rigs.pas + Levels.Dynamics.pas (`GoesOutWithParent` of `TBeacon`, `THaze`) + Render.Dynamics.pas `DrawStands` + Moon2D.dpr `LocateParent` |
| Lamps riding the boss's disc | `turns` beacons in level1.json + Render.Dynamics.pas (`OriginOf`, `TParentSpin`) + Moon2D.dpr `LocateParent` |
| New monster (data only) | monsters.json + a `.mset` set (spriteList keeps the `.mns` spelling) |
| Explosion mechanics: the wave that wounds, its speed, falloff, shove and shelter; who a blast strikes; the shards that wound what stands below (Effects.Debris.pas `Strike`, Moon2D.dpr `ShardStruck`) | Game.Blasts.pas + Moon2D.dpr (`ResolveBlasts`, `StrikeMonsters`, `StrikeHero`, `RewardMonsterKill`) + `blast` in monsters.json (`TBlastDef` in Monsters.Defs.pas) |
| Explosion look: flash, debris, plume; sizes; a new kind | Game.Explosions.pas (+Effects.Debris.pas for shard physics, `explosion` in monsters.json, `TExplosionKind` in Monsters.Defs.pas) |
| Sparks: how they fly, bounce, fork and draw | Effects.Sparks.pas (+Render.Glow.pas `gsStreak`) |
| A spark source in a level (the satellite, the boss) | `sparks` in the `dynamics` of levelN.json + Levels.Dynamics.pas `TSparks` (+Render.Dynamics.pas `SolidInView`) |
| A fan in a level: size, speed, direction, blur, a dying motor; a new rotor, guard or back; a louver panel beside it | `fan` in the `dynamics` of levelN.json (the louver - in `objects`) + Levels.Dynamics.pas `TFan` + `ventilation.mset` (declared in `objectSets`; tools/fans/build_fans.py makes the pictures) |
| Sparks off armor under fire; which monsters are metal; the ping and the whine | Game.Impacts.pas + Moon2D.dpr `SpendBullet` / `ArmorStrike` / `SoundArmorHit` + `material` in monsters.json (+tools/sounds/armor.py) |
| Wreck smoke and sparks of the machines | Monsters.pas (`WreckIfCritical`, `WreckSmoke`, `WreckSparks`, `BodyPoint`; a hull's points: `hull` in monsters.json) |
| The barrel's smoke; one more body that smokes | Monsters.pas (`BarrelSmoke`, `TBodySmoke`, `IsExplosiveProp`, `CreateSmoke`) |
| HD art in a monster set: filter, color key | Monsters.pas `AnimFor` + Render.Sprites.pas `ExpectDenseArtAbove` |
| The henshin ceremony: countdown, waves, the suit on and off | Game.Henshin.pas (+Bullets.pas for the fans and rings) |
| Level content / triggers / screens | levelN.json + Levels.Defs.pas |
| A level event: when it fires, what it does; a new condition or action | `events` in levelN.json + Levels.Events.pas (model) + Events.Director.pas (runner) |
| Game flow / state machine / scoring / bonuses / gravel trial | Moon2D.dpr (+Game.Bonus.pas) |
| The hero's aura of orbs: the ring, its flow, how it follows (the leash, the thread of a leap), lives, weaving a second cast in, the ring's ceiling, a door, the hero's death | Orbs.Aura.pas (formulas and numbers) + Moon2D.dpr (`CastAura`, `HandleScreenTransitions`, `HurtHero`) + docs/ORBS-PLAN.md |
| The call of the aura: where the orbs show through (faces of cells and pads, thin air), the wait over a face, the flight, when an orb is armed, the mercy window | Orbs.Harvest.pas (the spots) + Orbs.Aura.pas (`Cast`, `Emerge`, `Hover`, `Fly`) + Pads.World.pas (`Bodies`) + Moon2D.dpr (`MatterAround`, `CastAura`) |
| The fire rain of orbs: the waves, the formula of a drop, the floor of a column (matter, a pit), landing, a second pour, the hero's death | Orbs.Rain.pas (formulas and numbers) + Moon2D.dpr (`PourRain`, `ResolveOrbHits`, `HurtHero`, `ArriveOnScreen`) + docs/ORBS-PLAN.md |
| An orb: its look, its three ends (implosion, dust, release), the mark on a face, how it is drawn between ticks; what an orb strikes and what that costs | Orbs.Flock.pas + Moon2D.dpr (`ResolveOrbHits`, `EnemyBulletNear`, `DangerousMonsterAt`, `OrbReach`) + `dangerous` in monsters.json |
| Screen size vs frame size; anything for the wide screen | Game.Space.pas (then every reader of `Frame*` / `Screen*`) |
| Health monitor / bonus charge panels: look, colors, timings | Hud.Vitals.pas / Hud.Charge.pas (+Render.Brush.pas for the brush and palette) |
| Health rows over the hero / monsters; the crosshair's thirds | Hud.Marks.pas (+Render.Brush.pas for the cells) + Monsters.pas (`HealthTier`, `TicksSinceHit`) + Moon2D.dpr `CrosshairFrame` |
| Screen transitions / checkpoints; where a pit or death returns the hero on a screen | Moon2D.dpr (`HandleScreenTransitions`, `ArriveOnScreen`, `PinRespawnPoint`, `HandlePitFall`) + `respawns` in levelN.json + Levels.Defs.pas (`TRespawnPoint`, `CheckRespawns`) |
| A jet under a pad: its color, length and strength, the flare around a flight, a coughing engine | the smoke part of a rig in levelN.json (`heatTint`, `speed`, `life`, `intensity`, `surge`, `flow`) + Levels.Dynamics.pas (`TSmoke`, `FollowEffort`, `EffortEaseTicks`) + Pads.World.pas (`Thrusting`, `ThrustLeadTicks`) + Moon2D.dpr `LocateParent` |
| Menu screens / layout / language switching / trailer showcase frames | Menu.pas + Localization.pas |
| Menu sky: stars, the spinning moon, the dolly into a submenu | Menu.Starfield.pas / Menu.Globe.pas / Menu.pas (`DrawSky`, `*Zoom`) |
| A lit sphere: shading, terminator, atmosphere, night lights | Render.Globe.pas |
| The Earth in a level's sky; its phase and the dawn | `dynamics` (`globe`) and `events` (`sun`) in levelN.json + Levels.Dynamics.pas (`TSkyGlobe`) + the `earth` / `earth-night` maps in `sky.mset` (shared, declared in `objectSets`) + Render.Globe.pas |
| Logo halo and embers; a redrawn logo | Menu.Logo.pas + Menu.Embers.pas (+ the `logo` sprite in ui.mset) |
| Anything that glows additively | Render.Glow.pas |
| Heat haze - under a jet, over a turbine: the plume, its strength, grain and flow | `haze` in `dynamics` or in a rig of levelN.json + Levels.Dynamics.pas (`THaze`, `HazeLayers`, `TNoiseWindow`) + Render.Dynamics.pas (the backdrop layer, `BackdropOf`) + Render.Tiles.pas `Backdrop` + Sdl2.Core.pas `SDL_RenderGeometry` |
| What the pads and the monsters wear - lamps, hazes, jets: one list for many wearers, a number rolled wearer by wearer | `rigs` + `"rig"` on the pads and the entities in levelN.json + Levels.Rigs.pas (`WearRigs`, `ReadRigNames`, `TRigWearer`) + Levels.Defs.pas `RigWearersOf` + Levels.Dynamics.pas (`ParseDynamic`, `NameRoll`, `PlacementSeed`) |
| What hangs on a pad going into the depth with it: smaller, darker, behind the pads in front | Render.Dynamics.pas (`TParentDepth`, `OriginOf`, `DrawSunk`) + Levels.Dynamics.pas (the canvas' `Scale` / `Tone` in `TBeacon`, `THaze`, `TSmoke`) + Pads.World.pas (`DeepScale`, `DeepTone`, `Middle`) + Moon2D.dpr (`LocateParent`, the order in `Render`) |
| A dynamic object (a beacon, its blink, rays); a new kind; hanging one on a static object | `dynamics` in levelN.json + Levels.Dynamics.pas (kinds, parser) + Render.Dynamics.pas (where it stands, layer) (+`tag` on `objects`) |
| Text rendering / new captions | Render.Font.pas + Hud.Messages.pas + an `S*` key in Localization.pas + both lang JSONs |
| Level hints / the comm terminal | Hud.Terminal.pas (+Hud.Messages.pas for the ticker lane, `hintText` in level JSON) |
| Story screen before a level / typing rhythm | Hud.Briefing.pas / Hud.Typewriter.pas (+`introText` in level JSON) |
| Frame pacing / window / vsync | Game.Loop.pas (+Sdl2.Core.pas) |
| Sound / music | Audio.pas (+sound constants and `PreloadSounds` in Moon2D.dpr, the ceremony's in Game.Henshin.pas, data fields in JSONs) |
| Tile/background rendering | Render.Tiles.pas + Render.Sprites.pas |
| Repainting a 2008 screen: what becomes a pad, an object, a fan; the blockout and the prompt; seating a picture on the grid; what may be done to a generated picture | docs/REPAINT.md + levelN.json (`objects`, `pads`, `dynamics`, `tiles`) + `<assetsDir>-objects.mset` |
| Screen pictures for repainting the art (the P debug key) | Moon2D.dpr (`DumpLevelScreens`, `SaveScreenPictures`, `SaveTargetAsPng`) + Sdl2.Image.pas (`IMG_SavePNG`) |
| Free-form art over the backdrop (the ship, the satellite): place, size, tint | `objects` in levelN.json + `<assetsDir>-objects.mset` or a shared set in `objectSets` (`sky.mset`) + Render.Objects.pas (+Levels.Defs.pas `TLevelObject`) |
| Screen shake: doses, what shakes, what stands still | Moon2D.dpr (`*Trauma` constants, `Render`, `DrainMonsterEvents`, `EchoAftershock`, `ActivateQueuedBonus`) + Game.Henshin.pas (`WaveTrauma`, `FinishTrauma`) + Render.Shake.pas |
| A sprite name resolves to the wrong picture | Render.Sprites.pas (Get, AmbiguousNames) + the level's `spriteSets` order |
| A monster/hero loads wrong frames from a set | Monsters.pas AnimFor / Hero.pas OpenFrames |
| Sprite sets / the `.mset` format | Sprites.Sets.pas + docs/MSET-FORMAT.md |
| Packing or inspecting sets | tools/SpritePack/* |
| A test: where it lives, how it is run, what is left to the eye; a new test unit | Tests/* + run-tests.cmd + docs/TESTING.md |
| Trailer cards | tools/TitleCard/* |
| Selene: the living moon's map for the menu | tools/Selene/* |
| PNG loading / image DLL | Sdl2.Image.pas |
