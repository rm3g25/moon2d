# Moon 2D - Codebase Map

Reference document. Purpose: given this file plus a task description, know which
files to open without re-exploring the repository.

Repo: `https://github.com/rm3g25/moon2d/`, Delphi 10.3+ (inline var) + SDL2,
Win32. Logic space 512x384 game units (16x12 cells of 32), tile art 64 px,
fixed tick 33 Hz, screen-by-screen levels (no scrolling).

Regenerated at `v3.0.3`, patched through `v3.0.23` (the folder layout came
between 3.0.8 and 3.0.9) and checked against the code section by section at
`v3.0.19`. Where the map and the code disagree, the code is right.

## Source layout

The units live in four folders under the root; `Moon2D.dpr`, `.dproj` and
`Moon2D.inc` stay in the root, and every unit includes it (`{$I ..\Moon2D.inc}`;
`{$I ..\..\Moon2D.inc}` from `Game/Events/`).

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
  runs the level events.
- `Hud/` - everything drawn over the playfield, plus the story screen and the
  typewriter they share.
- `Menu/` - the main menu and its sky rig.

Game, Hud and Menu are peers above Core and may use each other. Level events
driven from level JSON split by that rule: the model and parser
(`Levels.Events`) sit in `Core/`, since the editor will write them; the
runner (`Events.Director`) in `Game/Events/`. Two unit names in `Core/` still carry the `Game.` prefix (`Game.Config`,
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
`Levels.Defs` / `Hud.Vitals` / `Hud.Charge` / `Hud.Typewriter` ->
`Hud.Terminal` / `Hud.Briefing` ->
`Bullets` / `Monsters.Disc` (the boss's disc: over `Render.Sprites` and
`Monsters.Defs`, its sensor through `Render.Glow`) / `Monsters.Pilot` (the
boss's pilot: over `Levels.Defs`, `Monsters.Defs`, `Game.Space` and the
sizes of `Render.Sprites`) -> `Hero` /
`Monsters` / `Hud.Messages` / `Render.Tiles` / `Render.Objects` /
`Render.Dynamics` / `Game.Explosions` (over `Effects.Debris`,
`Levels.Dynamics` and `Monsters.Defs`) / `Game.Impacts` (over
`Effects.Sparks` and `Levels.Dynamics`) -> `Hud.Marks` /
`Game.Henshin` / `Events.Director` -> `Moon2D.dpr`, which also drives
`Game.Loop` (the host: over `Sdl2.Core` and `Game.Config` alone, it knows no
game unit). The menu sky rig on the
side: `Render.Brush` -> `Render.Glow` -> `Menu.Starfield` / `Menu.Embers` ->
`Menu.Logo` -> `Menu` (with `Menu.Globe`, a thin moon over `Render.Globe`).

---

## Game units

### `Core/Sdl2.Core.pas` (~395 lines)
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
  `TSdlRendererInfo`,
  `TSdlVersion`, `TSdlSurface` (partial mirror - leading fields only),
  `TSdlKeysym`, `TSdlKeyboardEvent`, `TSdlMouseMotionEvent`,
  `TSdlMouseButtonEvent`, `TSdlEvent` (variant record, 56-byte padding arm).
- **Imports**: window/renderer lifecycle, draw calls (`SDL_RenderCopy/F/Ex/ExF`,
  fill, clear, present), surfaces + color key + format conversion, textures
  (incl. target textures, streaming `SDL_LockTexture`/`SDL_UnlockTexture` -
  the globe, per-texture `SDL_SetTextureScaleMode`, color and alpha mod, and
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
  properties `Id`, `Description`, `Entries`, `Sequences`.
- **`TSpriteSetWriter`** - write side. `AddSprite`/`AddSpriteFile`,
  `AddSequence`, `SaveToFile`. Offsets are handed out at save time in add
  order; writing is deterministic, so an unchanged set rebuilds byte for byte.
  Validates duplicate names and sequences pointing at absent frames.
- Format spec: `docs/MSET-FORMAT.md`.

### `Core/Render.Sprites.pas` (~530 lines)
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
  three apply to textures loaded after the call.
- **`LoadImageSurface(spriteSet, name)`** (free function) - the one place that
  turns stored bytes into a surface. Returns `nil` for a nil set or an unknown
  name; the caller words the error, since only it knows what the picture was
  for.
- **`TAnimSet`** (record) - `Alive[0..7]` + `Death[0..7]` texture arrays;
  `IsLoaded`. Built by **`LoadAnimSet(cache, spriteSet)`** from the manifest's
  `alive` and `death` sequences, each validated to exactly eight frames -
  `TAnimSet` is the 2008 contract and it is fixed-size.
- **`TintTexture(texture, r, g, b)`** (free function) - color mod per channel
  in percent, 100 = as painted. The texture keeps it until the next call, so
  a picture shared under different tints is tinted before every draw. The
  backdrops and the level objects both tint through it.
  **`PercentToColorMod(percent)`** - one channel of that conversion, public
  for a caller that passes the color on instead of setting it on a texture
  (the beacon's tint becomes the glow color through it).
- **`TSpriteRenderer`** - draws in game units: `DrawCell` (sprite grid),
  `DrawTile` (tile grid, the top-left 64x64 crop reproduced from
  `sttextures.pas`), `Draw` (free position, optional mirror), `DrawRect`,
  `DrawRotated` (weapon arm), `DrawTurned(texture, center, side, angle,
  level = 1)` - a square of any size centered on a float point, turned
  clockwise, at an opacity; float all the way (`SDL_RenderCopyExF`), so a
  mover drawn between ticks does not snap to logical units - the boss's
  disc draws its layers through it. It sets the texture's alpha mod on
  every call. **`Origin`** (a `TSdlPoint`) shifts every one of
  them - the screen-shake hook; nothing here resets it, the caller sets it per
  layer and draws the still layers (backdrop, cursor, HUD) at `NoShake`. The
  constructor takes the logical size and sets it on the renderer
  (`SDL_RenderSetLogicalSize` - the dpr passes the frame of `Game.Space`).

### `Core/Sdl2.Image.pas` (~70 lines)
SDL2_image bindings, delayed imports in the shape of `Audio.pas`.
`IMG_Load_RW` replaced `SDL_LoadBMP_RW` at every load site. `EnsureImageLib`
runs at startup and raises plainly if the DLL is absent - unlike the optional
mixer, missing art is fatal. `IMG_SavePNG` is the one writer: the debug
screen dump of the dpr.

### `Core/Render.Tiles.pas` (~100 lines)
- **`TTileScreenRenderer`** - draws one screen as two layers the caller
  orders: `DrawBackground` (the screen's backdrop sprite via
  `FBackgroundCache`), then `DrawTiles` (palette indices from `TLevel` via
  `FTileCache`). Separate calls, no combined one, so the backdrop can stand
  still while the tiles shake. Both caches are fed from `.mset` sets by the
  composition root, and neither is owned here. `DrawBackground` sets the
  change's tint (`TintTexture`) on every draw, not once at load: two changes
  may share one picture under different tints.

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

### `Core/Render.Dynamics.pas` (~325 lines)
- **`TDynamicScreenRenderer`** - brings the level's dynamic objects
  (`Levels.Dynamics`) to the screen. Owns the textures of the
  `TDynamicCanvas` (point, flare, starburst and streak glows - `Render.Glow`; the
  smoke puffs - `Render.Puff`) and lends it the cache of the level's
  object art (`Art`), made at level load; the objects
  themselves are the level's. After the canvas every object `Acquire`s
  what it draws with (a sky globe its `TGlobe`); the destructor `Release`s them
  before the canvas goes, so every SDL texture dies before the renderer. Per object a `TPlace`: its stands (screen + origin), a
  monster flag, the parent's life, the lead screen. A nailed object stands
  at (0, 0) on its screen, or on each screen of its `screens` run; one under a static object on every screen that
  object stands on, at its top-left - settled once, static objects never
  move. A tag no object carries is a monster's: that stand is looked up
  every tick through **`TLocateMonster`** (`reference to function(tag, out
  TParentStand)`: screen, sprite top-left, alive; for a monster that spins
  also `Spins` and a `TParentSpin` - its `TSpinPose` (the axis on the
  screen, the angle in degrees clockwise) now and a tick ago, plus where the
  axis sits from the sprite's top-left) - the field is reborn on
  restart, so no reference is kept; a monster that is nowhere keeps its
  last stand. **`OriginOf(place, stand, alpha)`** is the corner an object
  counts from: the stand's, or - for a placement that `Turns` under a parent
  that spins - wherever its point has turned to around the axis, alpha of
  the way between the two poses: a lamp rides the boss's disc between ticks
  exactly as the disc is drawn. `Tick(screen)` ticks every object whatever
  the screen (a
  lamp keeps its rhythm off screen) with the origin of its stand on the
  hero's screen, else its first (at the pose the tick has just reached,
  `ThisTick`); a lead stand on another screen is a jump
  (`ForgetOrigin`), not a flight. `Draw(screen, origin, alpha, layer)` draws
  the ones on the screen in one layer (`dlSky` / `dlBack` / `dlFront`); a
  place that `Turns` is not drawn once its parent is no longer alive (dying
  included) - there is nothing left to turn with. **`Reseat`** - the monsters
  were reborn (a
  restart): every place that follows a monster finds its parent at once and
  forgets its origin, so the frame before the next tick does not show it at
  the old stand. `Canvas` - the
  textures, lent to the monsters' wreck smoke and sparks, to the
  explosions (`Game.Explosions`) and the impacts (`Game.Impacts`).
  The constructor takes a **`TDynamicWorld`** (record) - what the objects
  ask of the game: `LocateMonster` and `Solid`, the game's `TSolidProbe`,
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
  `BigAdvanceRatio=0.8` - 20% overlap, `BigGlyphAspect`).
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
  silently), `ToggleMusicMuted`, `Enabled` (False when the mixer DLL is absent
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

### `Core/Levels.Defs.pas` (~665 lines)
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
  monster; '' = none).
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
  collision - the grid alone decides where the hero stands.
- **`TLevel`** (class) - the parsed level: tiles `[screen][row][col]`,
  collision strings `[screen][row]` ('1' = solid), tile palette, backgrounds,
  entities, id/title/assetsDir/**spriteSets**/**objectSets**/music/introText, grid dims,
  screenCount. `SpriteSets` is the environment sets in resolution order - tiles
  only; screen backdrops follow the `<assetsDir>-backdrops` convention and
  never appear there. `Objects` - the free-form art, in file order (later
  draws over earlier); the private `ParseObjects` reads the optional
  `objects` section and refuses an object off the screen list or with a
  width of zero or less. `Events` - the level's events (`Levels.Events`), in
  file order. Queries: `TileAt`, `SolidAt`, `SolidAtPoint(screen, x, y)` (the
  same for a point in screen units - the one home of the units-to-cells
  rule and its guard against negatives; the solid probes of the game and
  of the monsters call it), `BackgroundFor` (the whole
  change, last one wins; `Image = ''` when the level defines none).
  `LoadFromFile`; the dynamics are parsed before the events, since an event
  may name a dynamic object's tag. Private `CheckEvents` refuses an event
  off the screen list, one watching a tag no placement carries, and
  (`CheckEventTargets` -> `CheckEventTarget`) an intensity action turning a
  tag no dynamic object carries, a sun action turning a tag no globe
  carries or a tactics action naming a tag no placement carries. `Dynamics` - the dynamic objects (`Levels.Dynamics`), owned by
  the level (the only destructor here) and kept through a restart - a lamp
  keeps its rhythm; only what a re-armed event changed goes back. Private
  `CheckDynamics` refuses a nailed object off the screen list or a
  `screens` run running backwards or past it (`CheckDynamicScreens`), a parent tag
  neither an object nor an entity carries, a tag carried by both, two
  objects with one tag on one screen, and (`CheckMonsterParent`) two
  entities with one tag on a shared difficulty grade (the child could not
  tell its parent).

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
What an explosion throws, decoration only - the 2008 fragment fans wound,
this does not. **`TDebrisField`** takes the renderer and a
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
`PuffShapes` (4) ragged puffs at level load: a soft falloff eaten into by
fractal value noise (`FractalNoise`, octaves of `ValueNoise` over a
`TXorShift`-hashed lattice), the outline bent by the same noise, white
pixels with a mottled brightness, the shape in alpha. **Alpha blended**,
linear-filtered - smoke hides what is behind it, light (`Render.Glow`) only
adds. `DrawPuff(renderer, texture, cx, cy, size, angle, color, level)` -
centered, turned (`SDL_RenderCopyExF`), tint as color mod, density as alpha
mod. `FreePuffTextures`. `EPuffError`.

### `Core/Levels.Tint.pas` (~70 lines)
- **`TColorTint`** (record) - R/G/B multipliers in percent, applied when
  the picture is drawn; `Neutral` = 100/100/100 (as painted).
- **`ReadTint(obj, owner, key = 'tint')`** - reads `"tint": [r, g, b]` (or
  another key of that shape - the smoke's `endTint`); absent = neutral,
  any other shape or a value outside 0..100 raises `ETintError` (a picture
  silently left at full brightness looks like a tint nobody tuned).
- Its own unit because three readers share it - backdrops and static
  objects (`Levels.Defs`), dynamic objects (`Levels.Dynamics`) - and
  `Levels.Defs` uses `Levels.Dynamics`, so the tint could live in neither.

### `Core/Levels.Dynamics.pas` (~1595 lines)
The `dynamics` section of level JSON: things placed like the static
objects, but alive. **Every kind lives in this unit**: a new kind is a class
here, a word in `DynamicKindIds`, its layer in `DefaultLayers` and a branch
in `CreateDynamic`.
- **`TDynamicPlacement`** (record) - what every kind shares: `Screen`,
  `screens` (JSON `[first, last]` - one object on a run of screens, read
  into `Screen`..`LastScreen`) or `Parent` (exactly one - with a parent the
  parent decides the screens; the parent is a static object's or a
  monster's tag), `X`/`Y` (screen units; from the parent's top-left under
  one), `Tint`, `Tag` (the name events turn it by), `Layer`
  (`TDynamicLayer`: `dlSky` - right over the backdrop, still while the
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
  (a `TValueFade`; JSON `intensity`, a percentage, 100 by default). `Tick(originX, originY, parentAlive)` works
  out how far the origin moved since the last tick, steps the fade and
  calls the kind's protected abstract `Advance(motionX, motionY,
  parentAlive)`; `FadeTo(level, ticks)`, `Rewind` (virtual: back to the
  level file's intensity, origin forgotten), `ForgetOrigin` (the next tick
  counts no motion), `Origin` (where the last tick counted from). Two
  constructors: from JSON, or with the intensity given (for objects the
  game makes itself). `Draw(canvas, originX, originY, alpha)` adds X/Y to
  the origin and calls the protected abstract `DrawAt`. Virtual
  `Acquire(canvas)` / `Release` - what a kind makes for itself to draw with
  (empty in the ancestor). The parent is coordinates only,
  VCL-style: it owns nothing.
- **`TDynamicObjects`** (`TObjectList<TDynamicObject>`) - `FadeTagged(tag,
  level, ticks)`, `RewindTagged(tag)`, `TurnSunTagged(tag, degrees,
  ticks)`, `AnyTagged(tag, kind = nil)`: what the events and the level
  checks ask.
- **`TDynamicCanvas`** (record) - renderer + the glow textures + the puff
  textures every kind draws with + `Art` (the cache of the level's object
  art - its own set and the declared shared ones);
  the textures are made and freed by `Render.Dynamics`, `Art` is handed to
  it and outlives it. `Solid` - the solid layer as a `TSolidProbe` in
  screen units, for what a kind throws (`SolidInView` of
  `Render.Dynamics`).
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
  between ticks never disagrees with them. The seed is the position
  (`PlacementSeed`), so lamps at different points fail out of step.
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
  toward `FireColor` and carries an additive glow for `HeatShare` of its
  life. Intensity scales the rate and, as its square root, a puff's
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
- **`ParseDynamics(root, levelId)`** - reads the section (absent = empty
  list, the caller owns it); an unknown kind, layer, blink, flow,
  surface or collide, none or more than one of screen, screens and parent, a broken
  `screens` pair, a number out of range raise `EDynamicError`
  (`ReadWord`, `ReadShare`, `ReadPositive`, `ReadReach`, `ReadScreens`).
- `LogicTicksPerSecond = 33` - frequencies are per second; the logic runs
  33 ticks a second.

### `Core/Levels.Events.pas` (~235 lines)
The `events` section of level JSON: model and parser, no game logic (the
game runs them through `Events.Director`; the editor will write them).
- **`TEventCondition`** = (`ecEnterScreen`, `ecAllDead`, `ecLivesBelow`,
  `ecEnraged`) - what the event waits for. The hero must be on the event's
  screen for any of them; enterScreen asks nothing more; the rest
  (`TaggedConditions`) watch the monsters carrying the tag: allDead - none
  alive, livesBelow - one alive with fewer lives than `lives`, enraged -
  one alive in its rage (the boss below its rage mark, a tank below its
  own).
- **`TEventActionKind`** = (`eaBigMessage`, `eaSmallMessage`, `eaHint`,
  `eaMusic`, `eaIntensity`, `eaSun`, `eaTactics`); **`TEventAction`**
  (record) - kind +
  localized `Text` (the message kinds), `FileName` (music), or `Target` /
  `Level` (0..1) / `Ticks` (intensity: the dynamic objects carrying the tag
  fade there; JSON `target`, `value` a percentage, `ticks` 0 = at once),
  or `Target` / `Angle` / `Ticks` (sun: the globes carrying the tag turn
  their sun there; JSON `value` in degrees), or `Target` / `Tactics`
  (tactics: the monsters placed with the tag fly by them from now on, see
  `Monsters.Pilot`; JSON `target`, `value` - a word of `EventTacticsIds`:
  laps / dives / rams / hunts).
- **`TLevelEvent`** (record) - id, screen (1-based), condition, tag,
  `Lives` (livesBelow), `DelayTicks` (counted after the condition holds,
  for any condition), actions. JSON: `"when": "allDead", "tag":
  "labGuard", "delay": 33, "then": [{"action": "hint", "text": "...",
  "textEn": "..."}]`; `"when": "livesBelow", "tag": "boss", "lives": 150,
  "then": [{"action": "intensity", "target": "bossSmoke", "value": 60,
  "ticks": 66}]`.
- `EventConditionIds` / `EventActionIds` / `EventTacticsIds` - the JSON
  vocabulary as typed
  constants. `ParseLevelEvents(root, levelId)`; an absent section is an
  empty list, an unknown condition or action, a missing id, a tagged
  condition without a tag, livesBelow without lives above zero, intensity
  without a target or with a value outside 0..100, sun without a target or
  without a `value`, tactics without a target or with an unknown word, or
  an event without actions raises `ELevelEventError`.
- Extending: a condition is an enum member, a word in `EventConditionIds`
  and a branch in the director's `ConditionHolds`; an action the same with
  `EventActionIds` and `Play`.

### `Core/Monsters.Defs.pas` (~570 lines)
Monster definition model + registry (parses monsters.json). No behavior.
- **Enums**: `TMonsterCategory` (mcEnemy/Pickup/Prop/Boss), `TMovementKind`
  (mkStatic/Patrol/PatrolNoEdgeCheck/ChaseHero/BossFly), `TAttackPattern`
  (apNone/StraightSingle/StraightCluster5/AimedSingle/AimedDouble/RainVolley),
  `TPickupEffectKind` (peNone/Heal/GiveWeapon), `TExplosionKind`
  (ekNone/Barrel/Machine/Boss - the look of a death, JSON `explosion`, an
  unknown word raises; independent of the fans of `explodesOnDeath`),
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
  `TMonsterDef` - the full sheet: id, legacyName, displayName (localized),
  spriteList, category, dangerous, affectedByGravity, explodesOnDeath,
  explosion, material, movement, attack, pickupEffect, lives, score, animFreq, deathText
  (localized), deathSounds array, boss, disc.
- **`TMonsterRegistry`** (class) - owns all defs; `LoadFromFile/String`,
  `Find`, `FindByLegacyName`, `TryFind`, `Count`, `AllDefs` (the sound bank
  warms its cache from here), spawn-table and dodge-prize validation.

### `Game/Bullets.pas` (~310 lines)
Projectiles + all the 2008 particle-hack spawners.
- **`TFanShape`** (record) - rows/cols/baseSpeed/speedSpread of the k/t fan
  formula (the travel-test record: one template, seven shapes - `DeathFan`
  here, `RageWave` / `FastFragments` / `SlowFragments` in `Monsters`,
  `FinishFan` / `ShatterFan` in `Game.Henshin`, `ExplosionFan` in
  Moon2D.dpr).
- **`TBulletStatus`** = (`bsFlying`, `bsBursting`, `bsInactive`).
- **`TBullet`** - position, velocity, gravity ('dyy'), burst animation frame,
  `Contact` (participates in bullet-vs-bullet interception). `Move`,
  `StartBurst`, `StartBurstSliding` (a wall hit keeps 1/8 inertia).
- **`TBurst`** - owns a bullet list, its sprite set and its cache ('bullet' =
  hero, 'bull' = monsters; flight frame + destruction frames 2..8).
  `NewBullet`, `Clear` (screen transitions wipe bullets), `Update`, `Draw`.
  Spawners, all verbatim 2008: `SpawnExplosionFan` (a 180-fragment barrel /
  chain-reaction fan), `SpawnFan(centerX, centerY, shape)` (henshin finale /
  ice shatter / boss
  rage wave / boss victory double fan / the explosion bonus),
  `SpawnConvergingRing` (the henshin healing waves; Contact=True, so
  the ring wounds the boss), `SpawnFireRain` (768 slow bullets on a 16-unit
  grid), `SpawnStaticAura` (motionless bullets = the 2008 shield hack, halved
  to 250 in 2.1.1).
- Known wart: `TBurst.Draw` advances burst animation frames - it mutates
  simulation state from the render path, and that is what blocks render
  interpolation for the game world.

### `Game/Hero.pas` (~1170 lines)
The hero: physics, weapons, death. Owns `HeroSize=32`; the screen size it
moves in comes from `Game.Space`.
- **Enums**: `THeroAction` (stand/walk/jump/fall x direction), `THeroCommand`
  (go/stop left/right, jump/stopJump), `THeroForm` (hfNormal/hfIce),
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
  - Weapon: `FBullets: TBurst`, type 0..4 (pistol / shotgun x5 / grenade
    cloud x22 / chain x3 / minigun with alternating side shots), cooldown /
    speed / gravity state, `Fire: Boolean` (True = a shot actually left the
    barrel, so the caller barks the sound), `SetWeaponAngle`, `DrawWeapon`,
    the crosshair (`DrawCrosshair` frames 1..4 = the smart cursor colors), the
    minigun muzzle live tuner (`NudgeMinigun`, DEBUGKEYS).
  - Lifecycle: `Command`, `Tick` (verbatim OurHero.Timer), `Draw`, `SetMouse`,
    `PlaceAtCell`, `SetScreenX`, `SetY`, `ShoveX` (unit by unit, stops at
    walls), `ApplyWeaponPickup`, `Kill`, `Revive`.

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

### `Game/Monsters.Pilot.pas` (~975 lines)
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
  nothing else and the motion is the earlier one tick for tick.
- **Types**: `THeading` (hdDown/Left/Up/Right), `TPilotState`
  (psLap/Brake/Ponder/Dive/Aim/Dash/Stun/Return), `TPilotGaze`
  (pgHero/AimPoint/Nowhere - what the eye is on), `TCell` (a cell of the
  screen's grid, 0-based), `TPlace` (screen units: a point or a
  direction), `TPilotCrash` (a dash stopped by a wall: the rim of the body
  that struck, its speed, the way the wall faces), `TPilotBrief` (what the
  monster tells its pilot every tick: its own step, the hero's feet point,
  `BodyAlive`).
- **`TPilot`** - `Create(level, screen, baseStep)`; `Tick(var x, y,
  brief)` moves the feet point; `SetTactics` (new tactics open with a
  maneuver at once - `FRestWaived`); `NoteHeroContact` (the game has seen
  the body touch the hero); `Busy` (in a maneuver: a bullet's shove moves
  nothing); `GunHeld` (the monster's aimed gun is silent: in the pondering
  the ports speak, in the aim, the dash and the stun the eye is off the
  hero) and `GunClockRuns` (false on the ticks the slow clock of a
  maneuver skips - every `ManeuverGunSlowdown` = 2nd tick counts);
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
  the aimed gun on its slow clock. It sets off toward the hero (`BeginDive`),
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
  to dodge. `ptHunts` never goes back to the lap (`EndManeuver`): the next
  maneuver starts from the cell the last one ended at, a dive leg between
  any two rams (`MayRam`).
- **The arena**: the screen's cells that are not solid, rows
  `ArenaTopRow` (under the HUD) to `ArenaBottomRow` (above the bottom row
  of floor and pits) - `CellOpen`.

### `Game/Monsters.pas` (~1330 lines)
Monster behavior (data-driven off `TMonsterDef`) plus the field managing them.
- **Enums**: `TMonsterAction` (stand/walk/fall/flying), `TMonsterLife`
  (mlAlive/Dying/Dead), `TMonsterHealthTier` (htHale/Wounded/Critical - the
  crosshair's thirds), `TMonsterEvent` (meNone/BossWantsMinion/Henshin/
  BossRage/LevelComplete/Died/BossCrashed/BossOwesPrize) - 'MessageToMain'
  of 2008, drained by the game loop every tick.
- **`TMonster`** - position, screen, the placement's `Tag`, direction, lives
  (+`LivesAll`), anim frame, step, fire timer, enrage flag (`Enraged`), boss minion timer, a one-shot henshin
  flag, the event list, for a disc monster its `TDisc` (`Disc`, nil
  for the rest) and for an `mkBossFly` monster its `TPilot`. Its own
  collision oracles
  (`CanGoLeftEdgeAware`/`WallOnly` pairs = CanIGo*1/2 of 2008, `CanGoDown`),
  `ShoveX`. Movement: `MoveWalking`/`Falling`/`Flying` (the boss:
  `MoveFlying` hands `Monsters.Pilot` a `TPilotBrief` - the step, the
  hero, whether the body lives - and the pilot moves X, Y; a crash and an
  owed prize come back as `meBossCrashed` / `meBossOwesPrize`),
  `PatrolStep`. Combat:
  `FireAt` (patterns from `TAttackDef`; an aimed shot of a monster whose
  `Disc.Muzzle` is above zero leaves from the rim, `Muzzle` out from the
  middle toward the hero, instead of the 2008 point (X + 8, Y + 8) - the
  angle is still the verbatim one, from the monster's X, Y to the hero's,
  so the shot now runs through the middle of the hero's hitbox, not along
  its left edge), `FirePorts` (a volley when the pilot says `PortsDue`:
  one bullet out of every angle of `Disc.PortAngles`, turned with the
  rim, `Muzzle` from the axis, straight out; fired after `TickDisc`, so
  the ports are where the frame shows them), `TakeDamage` (knockback
  through the wall oracle - not while the pilot is `Busy`: the oracle asks
  one row, and a body between two rows would be shoved into a wall -
  + explosion fans + events), `EnrageTankIfLow`,
  `ProcessBossThresholds`, `BeginDying`. The disc: `TickDisc` (late in
  `Tick`: only the ports' volley comes after) hands it `DiscCenter` (the
  middle of the sprite), `EyeTarget`
  (the hero's middle; under the pilot's `Gaze` - the point a ram has
  locked on, or the disc's own middle for a stunned eye), the step over
  the definition's speed (rage doubles the step, so the spin; a pilot's
  `SpinScale` has the last word), `DiscWear` (lives lost since birth over `WearFull` -
  `FLivesBorn`, because rage resets `LivesAll`) and `DiscCharge` (rises
  over the last `TelegraphTicks` = 10 before a shot, 1 on the tick of one;
  where the pilot holds the gun - its `Charge` instead). The aimed gun
  under a pilot: held (`PilotHoldsGun`), its timer stays at zero - a whole
  interval passes after a hold before it speaks; in the rest of a maneuver
  the timer counts only the ticks of the pilot's slow clock
  (`GunClockRuns`), so the gun fires half as often. The interval and its
  `=` test are the 2008 ones.
  Public: `Tick(heroX, heroY, bullets)`, `SetTactics` (a flying boss takes
  them up, the rest have no pilot), `NoteHeroContact`, `LastCrash` (asked
  on `meBossCrashed`),
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
  (`renderer, registry, level, difficulty, livesScale`) skips every
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
  `AnyTaggedEnraged(tag)` (live bodies only - livesBelow and enraged),
  `Draw(sprites, screen, alpha)`, `DrawSmoke(canvas, screen, origin, alpha)`,
  `DrawSparks` (the same shape, over the smoke).
  `DiscArtFor(def)` - one `TDiscArt` per disc set name, opened on first use
  and owned here; the destructor frees the monsters before the art they
  draw with.
- **Body smoke** (a 2026 addition, default behavior, no data): `TBodySmoke`
  is one body's smoke - the `TSmokeLook`, the tint, the point on the
  left-facing art, the level before the last third and in it, the ramp in
  ticks. Two wear it. A machine - `IsMachine`, explodes on death and is not
  static: the tank and the flying platform; the mount is not - takes
  `WreckSmoke` (the boss's first smoke, straight up): unlit until
  `HealthTier` reaches `htCritical` (the red third of the health row), then
  60% within a second. An explosive prop - `IsExplosiveProp`, explodes on
  death and is of the `prop` category: the barrel - takes `BarrelSmoke`: a
  pale wisp off the relief valve at 40% from birth, the full plume within
  half a second of `htCritical`. `CreateSmoke(bodySmoke)` makes the `TSmoke`
  and keeps the record in `FBodySmoke`; `WreckIfCritical` and `TickSmoke`
  read the level and the point from there. No emission once the monster is
  no longer alive (dying included). The point mirrors with `FacesRight`,
  the one home of the facing rule, which `Draw` uses too - a barrel shoved
  nine units into a wall or over a ledge turns around, valve and all. The smoke dies
  with the monster, so a restart clears it. `TMonster` got its destructor
  (it frees the disc, the sparks, the smoke and the event list).
- **Wreck sparks** (default behavior, no data): the same machines own a
  `TSparks` made from the `WreckSparks` look (a rare crackle: two sparks a
  second and an arc of about five every second and a half, ringing off
  the floor), unlit until the same moment - `WreckIfCritical` is the one
  trigger of the smoke and the sparks - then at full at once. The point
  (`WreckSparksX/Y`) mirrors like the smoke's; the probe is the monster's
  own screen (`SolidUnderPoint` over `TLevel.SolidAtPoint`); the seed is
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
  `Shown(row)` (the typed part of a line), `CursorRow`/`CursorColumn`,
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
`Game.Explosions`, `Game.Impacts`, `Monsters.Disc` and the menu sky rig. No sprite, no font atlas. (Was Hud.Draw
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
fans stay with the monster and the dpr). **`TExplosions`**, made once
with the game (renderer + the solid probe + the aftershock echo), cleared
on a door, a death and a level load.
- **`TEchoAftershock`** (`reference to procedure`) - the game's answer to an
  aftershock, its sound and its jolt. The game sounds the blasts it
  detonates itself; the aftershocks go off here on their own clock, so
  each one calls back right after its `Detonate`.
- `Detonate(x, y, kind)` - x/y the heart of the blast in screen units;
  `ekNone` does nothing. Per kind a private typed constant
  `TExplosionLook`: a `TDebrisLook`, the flash (`FlashSize`, `FlashTicks` -
  two `gsPoint` glows, a swelling warm one and a white core, fading as a
  square), the plume (`TSmokeLook` + `SmokeTint` - a `TSmoke` made by
  `CreateLook` at full intensity and faded to zero over `SmokeTicks`, so it
  pours and thins; freed once `Exhausted`), and aftershocks (count, kind,
  spread, span - a queue of later `Detonate`s, `TickAftershocks`).
- Sizes: `BarrelExplosion` (14 shards, 40 sparks, flash 96),
  `MachineExplosion` (22, 60, 130 - the tank, the platform, the boss's
  rage), `BossExplosion` (40, 120, 220, plus five barrel blasts within 24
  units over 50 ticks - the wreck keeps popping).
- `Tick` (aftershocks, flashes, debris, plumes), `DrawSmoke(canvas, origin,
  alpha)` - the plumes, drawn right after the tiles, behind the figures;
  `Draw(canvas, origin, alpha)` - debris and flashes, over the bullets.
  Both on the world shake channel; the textures come from
  `FDynamics.Canvas`. Own `TXorShift` for the aftershocks.

### `Game/Game.Impacts.pas` (~350 lines)
What a bullet throws off the armor it strikes - the look only; the wound,
the knockback and the sound stay with the dpr. **`TImpacts`**, made once
with the game (the solid probe), cleared on a door, a death and a level
load.
- **`TStrike`** (record) - a bullet meeting armor: the point, the bullet's
  speed, the normal (the way the armor faces there), `Rapid` (the armor
  was struck a moment ago).
- `TraceEntry(strike, box)` - the bullet is already inside the hitbox:
  moves the strike back along its path to the edge it came in through (no
  further than one tick) and turns the normal the way that edge faces; a
  bullet hanging still (the aura) gets the normal up.
  `FaceFromCenter(strike, center)` - round armor: the normal from the
  center through the point (the boss's disc).
- `Land(strike)` - `GlanceOf` reflects the speed off the normal, as a
  mirror does; `ThrowFan` sprays `FanSparks` (9, or `RapidFanSparks` 4)
  within `FanCone` around a heading that leans `GlanceShare` from the
  normal toward the glance (`HitSparkLook`: bounce, forks); `AddFlash` - a
  3-tick flash, dimmer when rapid, and one a tick for the hits that crowd
  one armor; `ThrowTracer` - with `TracerChance`, never when rapid or for a
  bullet that hung still - one long fast streak along the glance
  (`TracerSparkLook`: next to no gravity, a springy bounce). True when a
  tracer flew - the game gives it its whine.
- Two `TSparkField`s (`MaxSparks` 512, `MaxTracers` 16), `MaxFlashes` 16,
  own `TXorShift`. `Tick`, `Draw(canvas, origin, alpha)` - over the
  bullets, on the monsters' shake channel; the textures come from
  `FDynamics.Canvas`.

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

### `Game/Events/Events.Director.pas` (~160 lines)
Runs the level's events (`Levels.Events`) against the live game.
**`TEventDirector`** takes the events, the message board, the level's
dynamic objects and a `TChangeMusic` callback (`reference to procedure`; the game passes its
`ChangeMusic` method, which also remembers the track for restarts). The
monster field is reborn on every restart, so it arrives with every tick
instead of being kept: asked for the conditions, told the tactics.
- `Tick(screen, field)` - once per logic tick with the hero's screen: for
  every unfired event of that screen, the condition is checked
  (`ConditionHolds`); while it holds the delay counts down, a lapse starts
  the count over; at zero the actions play once (`Play`: `ShowBig`,
  `AddTicker`, `StartTerminal` with the terminal header, the music
  callback, `FadeTagged` / `TurnSunTagged` on the dynamics,
  `SetTaggedTactics` on the field). The game skips the tick over
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
The stars of the menu sky, generated, not loaded. **`TStarfield`**.
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
fade, atmosphere 0..1, air color, night gain).
- Startup: `LoadMap` -> `BuildPyramid` (`HalveLevel` three times: the limb
  samples a coarser level instead of skipping texels) -> `BuildTables`
  (`PlaceTexel`: every texel of the disc gets its map row, longitude as a
  32-bit turn, detail level, coverage and a `TGlobeNormal` - normal, limb
  weight, air depth; with air the disc shrinks to leave room for a halo of
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
  (`PaintRow` -> `PaintGround` / `PaintAir`, inline), tint = color mod,
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
- Everything in letter texels; `Draw(dest, alpha, lettersW, lettersH)` scales
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

### `Moon2D.dpr` (~2230 lines - NOT a stub, always grep it too)
Composition root plus the whole game-flow state machine (`TMoonGame`).
- **Top constants**: the level discovery pattern, config file name, asset dir
  names (`SoundsDir`, `MusicDir`), the weapon->shot sound map, named one-shot
  sounds (the bonus cost lives in `Game.Bonus`),
  `VictoryMusicFile`, `MenuMusicFile`, `LevelEndLingerTicks=400`,
  per-difficulty hero health and monster-lives multipliers, gravel trial
  cadence, ticker durations, damage bookkeeping (`HurtMercyTicks`,
  `GameOverDelayTicks`, `PitDepthY`), the font choice (`FontFileName`,
  `FontOrientation`, `FontFiltering`), `AuthorLinkedInUrl`, `MaxLevelSlots`,
  extra scancodes (the debug ones under DEBUGKEYS), the screen-shake doses
  (`ExploderTrauma`, `BossBlastTrauma`, `BonusExplosionTrauma`,
  `BonusFireRainTrauma`, `AftershockTrauma`, `BossCrashTrauma` - a 2026
  addition; the
  ceremony's own live in `Game.Henshin`), ending-screen layout rows.
- **Types**: `TGameState` (gsMenu/gsIntro/gsPlaying/gsEnding).
- **`TMoonGame`** (extends `TGameApp`) - holds the registry (owned by
  `RunGame`) and owns the rest: level, the
  level's sprite sets and its three caches (tiles, backdrops, objects), the ui
  and weapon sets, the sprite, tile, object and dynamic-object renderers
  (`FDynamics`, reborn with the level, freed before it), hero (his burst is
  his own, `THero.Bullets`), monster
  field, the shared enemy burst (`FMonsterBullets`), font, message board,
  the briefing (`THudBriefing`), the screen shake, sound bank,
  menu, the explosions and the impacts (`FExplosions`, `FImpacts`, one of
  each for the run), the ceremony
  (`THenshin`), the event director (`TEventDirector`),
  the two corner HUDs (`THudVitals`, `THudCharge`) and the health rows over
  the figures (`THudMarks`) - the ceremony, the director and the three HUD
  objects are reborn with every level, so nothing carries over. Key state:
  game state + resume state, held-key flags (the 2008
  polled-keyboard model), health + hurt cooldown, game-over timer, checkpoint
  X/Y, score + kill streak, per-entity trigger-fired flags, the bonus slot
  (+ its queued activation; `FBonusLearned` - the first reward spent - is the
  one thing that survives levels, so the HUD insists once per launch), the
  gravel trial (attack flag, quota, wave timer, screen), the
  end-level timer, the level list + current file + current music, fullscreen,
  difficulty.
  Method clusters:
  - Flow: `Update`, `Render` (the layer order there is the shake spec: backdrop
    still and the sky dynamics (the Earth) with it, objects + back
    dynamics + tiles + bullets on the world channel -
    objects stand on the tiles and jolt with them, the back dynamics draw
    right after the objects, behind tiles and hero - monsters (the field gets
    the frame's alpha:
    the boss's disc draws between ticks), then the
    machines' wreck smoke and sparks, then the front dynamics (the boss smoke and
    lamps), on
    the monsters' channel - the explosion plumes before them, right after
    the tiles, the explosion debris and flashes after the bullets, then the
    impacts (on the monsters' channel - they sit on armor), then the
    health rows (`FMarks`, each on its figure's channel) - the
    hero on
    his own, cursor and HUD still; `Update` ticks `FDynamics` after the
    monsters and the director, so a smoking monster's puffs leave from
    where this frame draws it), `LoadLevel` (the object cache: the
    level's own objects set if it ships one, then `objectSets`; handed to
    `Render.Objects` and `Render.Dynamics`; the dynamics also get a
    `TDynamicWorld` - `LocateMonster` and `SolidUnderPoint`), `OpenSpriteSet` (a named set
    into `FLevelSets`, a missing one raises), `LevelArtSetFile` /
    `OpenLevelArtSet` (the `<assetsDir>-<kind>.mset` convention of the
    backdrops and the objects in one place), `StartPlaying`,
    `RestartLevel` (the field is reborn, then `FDynamics.Reseat` puts what
    hangs on monsters onto the new ones),
    `AdvanceToNextLevel`, `CurrentLevelIsLast`, `BeginEnding`, `OpenMenu`,
    `ApplyMenuResult`, `ToggleFullscreen` (the player's switch, remembered in
    settings.json), `SetFullscreen` (the bare switch - the ending screen drops
    fullscreen for the browser through it, unremembered), `PreloadSounds`,
    `CreateHud` (builds the three HUD objects afresh on every level load),
    `ChangeMusic` (a trigger's or an event's track: played and remembered
    for restarts; '' is a no-op), `LocateMonster` (the `TLocateMonster` of
    `Render.Dynamics`: the first monster carrying the tag - screen, sprite
    top-left as `TMonster.Draw` puts it, alive, and for a disc monster the
    disc's last two poses with the axis in the middle of the sprite).
  - World: `HandleScreenTransitions`, `ArriveOnScreen`, `HandlePitFall`,
    `FireScreenTriggers`, `TickGravelAttack`; the events are the director's
    (`FDirector.Tick` after the tick's verdicts, `ReArm` in `RestartLevel`).
  - Combat: `ResolveHeroBulletHits` (the bullet ends in `SpendBullet`: in
    its own burst or, on a monster whose `material` is metal, with no
    burst at all - a strike for `FImpacts` built by the free `ArmorStrike`
    (honest screen units, the hitbox as a box, `HitInset`; `Rapid` asked of
    the monster before the damage lands, `RapidHitTicks`) and a sound from
    `SoundArmorHit`: the whine of a tracer, else one of three pings at
    random, never the same twice running (`TArmorPings`, dice of its
    own), no more than one in `ArmorSoundGapTicks`),
    `ResolveMonsterBulletHits`,
    `ResolveMonsterContact`, `RewardMonsterKill` (also `Detonate` of the
    monster's `explosion` at the middle of its sprite, in the tick of the
    kill), `HurtHero`, `DrainMonsterEvents` (also where explosions and boss
    blasts feed the shake; `meBossRage` detonates a machine-size blast on
    the boss and sounds it with `RageBlastSoundFile` - a machine's
    `platform.wav`; `meBossCrashed` - the boss's ram ended in a wall:
    `BossCrashTrauma`, `BossCrashSoundFile` (`crash.wav`) and
    `ThrowCrashSparks` - fans of `Game.Impacts` sparks off the rim that
    struck and along the wall; `meBossOwesPrize` - `PayDodgePrize` hands
    a living hero the boss's `DodgePrize` with `SpawnOn`),
    `ResolveMonsterContact` also reports every touch to the monster
    (`NoteHeroContact` - the pilot's prize rule), `EchoAftershock` (the `TEchoAftershock` of
    `Game.Explosions`: each pop of the boss's wreck plays `bottle.wav` and
    adds `AftershockTrauma`), `SolidUnderPoint` (the probe of debris, impacts and
    dynamic objects: `TLevel.SolidAtPoint` for the hero's screen, honest
    screen units - no bullet -1 row), `ProcessKillStreak`, `AwardStreakBonus`.
  - Bonus: `CureHero` (+1 up to 10 - also the ceremony's cure callback),
    `AwardRandomBonus` (the headline carries the mouse hint until the first
    reward is spent), `ActivateQueuedBonus` (pays `BonusCost` on use). The
    ceremony itself is driven through `FHenshin`: started
    by `meHenshin` (countdown) and the gravel trigger (straight in), ticked in
    `Update`, drawn last in `Render`, reset in `RestartLevel`.
  - Drawing/input: `AdvanceBriefing`, `DrawEnding`, `DrawCenteredBig`,
    `HitEndingLine`, `HandleEndingClick`, `CrosshairFrame`,
    `HandleKey/MouseMove/MouseButton`.
  - Debug: `HandleDebugKey`, `HandleDebugMenuKey`, `UpdateInspectorCaption`,
    `DrawAtlasOverlay` - the four doors the debug keyboard uses, and nothing
    else. All four exist in every build; their bodies compile away, so no
    caller needs an ifdef. Behind them: `NudgeCrosshair`,
    `NudgeMinigunMuzzle`, `DebugBrowseScreen`, `CycleFontFiltering`,
    `DumpLevelScreens` (P: the tiles of every screen of the level, each
    alone on a transparent ground, one PNG per screen in
    `dump\<level id>\` of the working folder (`bin`) - the source
    pictures for repainting the art outside the game; the count goes to
    the ticker, the folder to the caption; `SaveScreenPictures` draws
    them past the window into a target texture of grid x `TileArtSize`
    pixels, so the picture does not depend on the window).
- **Free functions**: `OpenWebPage`, `BonusDisplayName`, bullet cell and
  off-screen helpers, `SaveTargetAsPng` (under DEBUGKEYS: the current
  render target into a PNG through `IMG_SavePNG`), `ReadLevelTitle`,
  `DiscoverLevels`, `RunGame` (the actual
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
wall. `material`: `metal` on the platform, the tank, the mount, the barrel
and `boss1` - a bullet throws sparks off them instead of bursting
(`Game.Impacts`). `disc` (only `boss1`) draws the living monster as a spinning disc out
of the layers of a set instead of its `alive` frames: `set`, `side`,
`muzzle`, `spin`, `irisReach`, `wearFull`, `portAngles` (the six gun
ports of the ring art: 0, 51, 129, 180, 231, 309) - see `TDiscDef`. Its
`boss` block names `dodgePrize`: `medkit`.

### `level1.json` (~63 KB) / `level2.json` (~22 KB)
The unified level format, parsed by `TLevel`. Keys: `version`, `id`,
`title`/`titleEn`, `assetsDir`, **`spriteSets`** (the environment sets, in resolution order),
**`objectSets`** (optional: shared object art searched after the level's own
objects set, e.g. `["sky"]`),
`music`, `legacyTrailing` (a migration artifact, cleanup pending), `grid`
(16x12), `backgrounds` (fromScreen + image + optional `tint`, three
percentages), `objects` (optional: sprite, screen, x, y, width in screen
units, optional `tint`, optional `tag`), `dynamics` (optional: `kind`
(beacon / smoke / globe / sparks), `screen`, `screens` [first, last] or `parent` -
a static object's or a monster's tag -, `x`, `y`, optional `tint`, `tag`,
`layer`, `intensity`, `turns`
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
optional `tag` for the events and the dynamics; `secret` on one level-1
medkit is data nobody reads yet), `events` (each: `id`,
`screen`, `when` = enterScreen | allDead / enraged + `tag` | livesBelow +
`tag` + `lives`, optional `delay` in ticks, `then` = a list of `action`
objects - bigMessage/smallMessage/hint with `text`/`textEn`, music with
`file`, intensity with `target`/`value`/`ticks`, sun with
`target`/`value` (degrees)/`ticks`; the med lab hint, `labHint`, is the
plainest example), `introText`/`introTextEn`.
- level1: 17 screens, 145 entities, a 156-tile palette, 4 backgrounds - night
  (1-7), pre-dawn (8-11), `_black` for the fully tiled lab screens 12-13,
  sunrise (14-17); sets
  `brickwork mine-structure facility conveyor mining-rig railway mine-walls
  cargo mine-interior`. Objects: the ship on screen 1 (in place of the 2008
  shuttle), the broken satellite in the sky of 14-17, tagged `ship` and
  `satellite`. Dynamics: the Earth (a `globe`) in the sky of screens 1-17 - hidden by
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
  disc a bare glow does not read).
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
  17: livesBelow 150 - bossSmoke to 60%; enraged -
  bossSmoke off, and (`bossRageLamps`) the blue lamps fade out, the red in,
  over 20 ticks, and (`bossRageSparks`) bossSparks light to 50%;
  livesBelow 30 - bossSmoke, bossBurn and bossSparks to 100%. The boss's
  tactics ride the same three moments (`bossSmokeTactics`,
  `bossRageTactics`, `bossBurnTactics`): dives while it smokes, rams in
  its rage, hunts once it burns.
- level2: 9 screens, 38 entities, a 35-tile palette, 4 backgrounds - day
  (1), the chasm edge (2), rock (3-5), the same rock darker (6-9); sets
  `moon-surface machinery facility common mine-interior`. Object: the
  satellite on screen 1, lit a little brighter (day), tagged `satellite`;
  the Earth on screen 1 as level 1 left it, a thinner crescent (sun 70, no
  events); all its object art is shared - no level2-objects set;
  its lamp is `dying` - a dim fast flutter, the battery running out, and
  one leak is left, a puff now and then (`flow` puffs); the breach still
  sparks, at intensity 25 - a spark now and then. The gravel trial
  lives here (screen 9: the `gravelBoss` trigger, quota 75/125/200 by
  difficulty, under `boss2.ogg`) - there is no boss monster - and it ends
  the original campaign.

### `sprites\*.mset` (35 sets)
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
  `TAnimSet` contract; its `death` frames still play.
- **Tile themes**: `brickwork`, `cargo`, `common`, `conveyor`, `facility`,
  `machinery`, `mine-interior`, `mine-structure`, `mine-walls`, `mining-rig`,
  `moon-surface`, `railway` - grouped by subject, not by level, because levels
  share tiles.
- **Backdrops**: `level1-backdrops`, `level2-backdrops` - found by the
  `<assetsDir>-backdrops` convention, never declared in `spriteSets`. HD
  since 3.0.11: 1440x1080 (4:3, the playfield of a 1080p screen 1:1), drawn
  linear-filtered and tinted per change; `_black` stays a 512x512 fill.
- **Objects**: `level1-objects` (`ship`) - the `<assetsDir>-objects`
  convention, never declared, optional (level 2 ships none). Shared:
  `sky` (`earth`, `earth-night`, `satellite`), declared by both levels in
  `objectSets`. The ship and the satellite are drawn at backdrop density
  (1440 px per
  512 units), transparent pixels filled with the edge color so the linear
  filter leaves no dark fringe; `earth` and `earth-night` are 1024x512
  equirectangular globe maps for `Render.Globe`.
- **Interface**: `ui` - `sky` (16:9 nebula), `moonmap` (2048x1024 lunar
  surface), `logo` (letters alone), the language flags (240x160) and the
  `font`/`fontx`/`fonty` atlases plus `fonty-2008` (the original 448x448
  atlas, kept, unreferenced). Stars, halo and embers are generated.

### `lang/en.json` / `lang/ru.json` (~2-3 KB)
Flat key->string dictionaries for UI and gameplay text (every `S*` key of
`Localization.pas`): tickers, streaks, henshin/bonus, ending screen, the full
menu vocabulary. Level and monster content is NOT here - it is localized in
place in the level and monster JSONs via the base-field + `En`-sibling pattern.

### `sounds/` (24 WAV) and `music/` (OGG)
One-shots are preloaded at startup and fail loudly when a file is missing;
music loads leniently. Four one-shots are synthesised by
`tools/sounds/armor.py`: `armor1..3.wav` and `ricochet.wav`; a fifth,
`crash.wav`, by `tools/sounds/crash.py`. Tracks named by code: `moon.ogg` (menu,
`MenuMusicFile`), `win.ogg` (`VictoryMusicFile`). By data:
`moon_surface.ogg` (level 1), `underground.ogg`, `moon_surface2.ogg`,
`boss1.ogg`, `boss1b.ogg` (the boss's `rageMusic`), `hallu.ogg` (level 2),
`under01.ogg`, `boss2.ogg`. Ten OGG files, all used.

---

## Quick task-routing table

| Task smells like... | Look at |
| --- | --- |
| Hero movement / collision / jump feel | Hero.pas |
| Weapon patterns / crosshair | Hero.pas (+Bullets.pas) |
| Monster behavior / AI / boss | Monsters.pas + Monsters.Defs.pas + monsters.json |
| The boss's flight: the lap, the maneuvers (ponder, dive, ram, stun), their numbers | Monsters.Pilot.pas (+Monsters.pas `MoveFlying`, `FirePorts`, `EyeTarget`; the `tactics` events of level1.json; `portAngles` / `dodgePrize` in monsters.json; Moon2D.dpr `ThrowCrashSparks`, `PayDodgePrize`; tools/sounds/crash.py) |
| The boss's disc: layers, spin, eye, wear, the shot from the rim | Monsters.Disc.pas + `disc` in monsters.json + `boss1-disc.mset` (+Monsters.pas `TickDisc`, `FireAt`) |
| Lamps riding the boss's disc | `turns` beacons in level1.json + Render.Dynamics.pas (`OriginOf`, `TParentSpin`) + Moon2D.dpr `LocateMonster` |
| New monster (data only) | monsters.json + a `.mset` set (spriteList keeps the `.mns` spelling) |
| Explosion mechanics: the fragment fans that wound | Bullets.pas (+Monsters.pas `BeginDying`, Moon2D.dpr `RewardMonsterKill`) |
| Explosion look: flash, debris, plume; sizes; a new kind | Game.Explosions.pas (+Effects.Debris.pas for shard physics, `explosion` in monsters.json, `TExplosionKind` in Monsters.Defs.pas) |
| Sparks: how they fly, bounce, fork and draw | Effects.Sparks.pas (+Render.Glow.pas `gsStreak`) |
| A spark source in a level (the satellite, the boss) | `sparks` in the `dynamics` of levelN.json + Levels.Dynamics.pas `TSparks` (+Render.Dynamics.pas `SolidInView`) |
| Sparks off armor under fire; which monsters are metal; the ping and the whine | Game.Impacts.pas + Moon2D.dpr `SpendBullet` / `ArmorStrike` / `SoundArmorHit` + `material` in monsters.json (+tools/sounds/armor.py) |
| Wreck smoke and sparks of the machines | Monsters.pas (`WreckIfCritical`, `WreckSmoke`, `WreckSparks`) |
| The barrel's smoke; one more body that smokes | Monsters.pas (`BarrelSmoke`, `TBodySmoke`, `IsExplosiveProp`, `CreateSmoke`) |
| HD art in a monster set: filter, color key | Monsters.pas `AnimFor` + Render.Sprites.pas `ExpectDenseArtAbove` |
| The henshin ceremony: countdown, waves, the suit on and off | Game.Henshin.pas (+Bullets.pas for the fans and rings) |
| Level content / triggers / screens | levelN.json + Levels.Defs.pas |
| A level event: when it fires, what it does; a new condition or action | `events` in levelN.json + Levels.Events.pas (model) + Events.Director.pas (runner) |
| Game flow / state machine / scoring / bonuses / gravel trial | Moon2D.dpr (+Game.Bonus.pas) |
| Screen size vs frame size; anything for the wide screen | Game.Space.pas (then every reader of `Frame*` / `Screen*`) |
| Health monitor / bonus charge panels: look, colors, timings | Hud.Vitals.pas / Hud.Charge.pas (+Render.Brush.pas for the brush and palette) |
| Health rows over the hero / monsters; the crosshair's thirds | Hud.Marks.pas (+Render.Brush.pas for the cells) + Monsters.pas (`HealthTier`, `TicksSinceHit`) + Moon2D.dpr `CrosshairFrame` |
| Screen transitions / checkpoints | Moon2D.dpr (HandleScreenTransitions, ArriveOnScreen) |
| Menu screens / layout / language switching / trailer showcase frames | Menu.pas + Localization.pas |
| Menu sky: stars, the spinning moon, the dolly into a submenu | Menu.Starfield.pas / Menu.Globe.pas / Menu.pas (`DrawSky`, `*Zoom`) |
| A lit sphere: shading, terminator, atmosphere, night lights | Render.Globe.pas |
| The Earth in a level's sky; its phase and the dawn | `dynamics` (`globe`) and `events` (`sun`) in levelN.json + Levels.Dynamics.pas (`TSkyGlobe`) + the `earth` / `earth-night` maps in `sky.mset` (shared, declared in `objectSets`) + Render.Globe.pas |
| Logo halo and embers; a redrawn logo | Menu.Logo.pas + Menu.Embers.pas (+ the `logo` sprite in ui.mset) |
| Anything that glows additively | Render.Glow.pas |
| A dynamic object (a beacon, its blink, rays); a new kind; hanging one on a static object | `dynamics` in levelN.json + Levels.Dynamics.pas (kinds, parser) + Render.Dynamics.pas (where it stands, layer) (+`tag` on `objects`) |
| Text rendering / new captions | Render.Font.pas + Hud.Messages.pas + an `S*` key in Localization.pas + both lang JSONs |
| Level hints / the comm terminal | Hud.Terminal.pas (+Hud.Messages.pas for the ticker lane, `hintText` in level JSON) |
| Story screen before a level / typing rhythm | Hud.Briefing.pas / Hud.Typewriter.pas (+`introText` in level JSON) |
| Frame pacing / window / vsync | Game.Loop.pas (+Sdl2.Core.pas) |
| Sound / music | Audio.pas (+sound constants and `PreloadSounds` in Moon2D.dpr, the ceremony's in Game.Henshin.pas, data fields in JSONs) |
| Tile/background rendering | Render.Tiles.pas + Render.Sprites.pas |
| Screen pictures for repainting the art (the P debug key) | Moon2D.dpr (`DumpLevelScreens`, `SaveScreenPictures`, `SaveTargetAsPng`) + Sdl2.Image.pas (`IMG_SavePNG`) |
| Free-form art over the backdrop (the ship, the satellite): place, size, tint | `objects` in levelN.json + `<assetsDir>-objects.mset` or a shared set in `objectSets` (`sky.mset`) + Render.Objects.pas (+Levels.Defs.pas `TLevelObject`) |
| Screen shake: doses, what shakes, what stands still | Moon2D.dpr (`*Trauma` constants, `Render`, `DrainMonsterEvents`, `EchoAftershock`, `ActivateQueuedBonus`) + Game.Henshin.pas (`WaveTrauma`, `FinishTrauma`) + Render.Shake.pas |
| A sprite name resolves to the wrong picture | Render.Sprites.pas (Get, AmbiguousNames) + the level's `spriteSets` order |
| A monster/hero loads wrong frames from a set | Monsters.pas AnimFor / Hero.pas OpenFrames |
| Sprite sets / the `.mset` format | Sprites.Sets.pas + docs/MSET-FORMAT.md |
| Packing or inspecting sets | tools/SpritePack/* |
| Trailer cards | tools/TitleCard/* |
| Selene: the living moon's map for the menu | tools/Selene/* |
| PNG loading / image DLL | Sdl2.Image.pas |
