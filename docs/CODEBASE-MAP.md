# Moon 2D - Codebase Map

Reference document. Purpose: given this file plus a task description, know which
files to open without re-exploring the repository.

Repo: `https://github.com/rm3g25/moon2d/`, Delphi 10.3+ (inline var) + SDL2,
Win32. Logic space 512x384 game units (16x12 cells of 32), tile art 64 px,
fixed tick 33 Hz, screen-by-screen levels.

Regenerated at `v3.0.3`, patched through `v3.0.12` (the folder layout came
between 3.0.8 and 3.0.9). Where the map and the code disagree, the code is right.

## Source layout

The units live in four folders under the root; `Moon2D.dpr`, `.dproj` and
`Moon2D.inc` stay in the root, and every unit includes `{$I ..\Moon2D.inc}`.

- `Core/` - what the level editor and the tools share: SDL bindings, sprite
  sets, rendering, the brush, the level/monster/config/language models, the
  frame-vs-screen space. **Core never uses a unit outside Core** - a tool or
  the editor that references only `Core/` fails to build the day that rule
  breaks.
- `Game/` - the game itself: hero, monsters, bullets, sound, the loop host,
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
`Sdl2.Core` / `Sprites.Sets` -> `Render.*` / `Audio` / `Game.Config` /
`Game.Bonus` / `Game.Space` / `Localization` / `Render.Brush` ->
`Levels.Events` -> `Levels.Defs` /
`Monsters.Defs` / `Hud.Vitals` / `Hud.Charge` / `Hud.Typewriter` ->
`Hud.Terminal` / `Hud.Briefing` ->
`Bullets` -> `Hero` /
`Monsters` / `Hud.Messages` / `Render.Tiles` / `Render.Objects` -> `Hud.Marks` /
`Game.Henshin` / `Events.Director` -> `Game.Loop` -> `Moon2D.dpr`. The menu sky rig on the
side: `Render.Brush` -> `Render.Glow` -> `Menu.Starfield` / `Menu.Embers` ->
`Menu.Logo` -> `Menu` (with `Menu.Globe`).

---

## Game units

### `Core/Sdl2.Core.pas` (~365 lines)
Hand-written SDL2 bindings. No classes - constants, records, `external`
declarations against `SDL2.dll`.
- **Constants**: init flags, window flags (incl. `SdlWindowHidden` for the
  offscreen tools), renderer flags, texture access (incl. `Target`), hints
  (`SdlHintRenderDriver`, `SdlHintRenderScaleQuality`), event type ids, flip
  flags, pixel format `SdlPixelFormatAbgr8888`, blend modes (`None`, `Blend`,
  `Add` - the last one is the HUD's glints), the scancodes the game uses.
- **Records**: `TSdlRect`, `TSdlFRect`, `TSdlPoint`, `TSdlRendererInfo`,
  `TSdlVersion`, `TSdlSurface` (partial mirror - leading fields only),
  `TSdlKeysym`, `TSdlKeyboardEvent`, `TSdlMouseMotionEvent`,
  `TSdlMouseButtonEvent`, `TSdlEvent` (variant record, 56-byte padding arm).
- **Imports**: window/renderer lifecycle, draw calls (`SDL_RenderCopy/F/Ex`,
  fill, clear, present), surfaces + color key + format conversion, textures
  (incl. target textures and `SDL_RenderReadPixels` - used by TitleCard),
  events, timing (`SDL_GetPerformanceCounter/Frequency`, `SDL_Delay`),
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

### `Core/Render.Sprites.pas` (~490 lines)
Texture cache + low-level sprite drawing. Owns the unit-size constants.
- **Constants**: `SpriteSetsDir` ('sprites\'), `SpriteSize=32`, `TileSize=32`
  (game units!), `TileArtSize=64` (texture px!), `FramesAlive=8`,
  `FramesDeath=8`. The 32-vs-64 split is the coordinate-system discipline in
  code form.
- **`TSpriteCache`** - dictionary `set:name -> PSdlTexture`, lazy load from the
  sets attached via `AttachSpriteSet` (not owned - the opener frees them).
  Resolution: a qualified name (`common:pustota`) goes to that set alone; a
  bare name takes the first attached set that has it; **a name no attached set
  carries raises `ESpriteError`** - there is no folder fallback left. Path and
  extension are dropped when looking up, so the 2008 spellings in level
  palettes (`level1\doom1.png`) still resolve. `AmbiguousNames` reports bare
  names carried by more than one attached set - those would resolve by
  declaration order, which is exactly what the qualifier exists to avoid.
  Optional color key (`SetColorKey`/`DisableColorKey`). `EnableLinearFilter`
  gives the cache's textures the linear filter over the global nearest - for
  art denser than the logical screen (the HD backdrops), where nearest
  downscaling turns detail into grain. Both apply to textures loaded after
  the call.
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
- **`TSpriteRenderer`** - draws in game units: `DrawCell` (sprite grid),
  `DrawTile` (tile grid, the top-left 64x64 crop reproduced from
  `sttextures.pas`), `Draw` (free position, optional mirror), `DrawRect`,
  `DrawRotated` (weapon arm). **`Origin`** (a `TSdlPoint`) shifts every one of
  them - the screen-shake hook; nothing here resets it, the caller sets it per
  layer and draws the still layers (backdrop, cursor, HUD) at `NoShake`.

### `Core/Sdl2.Image.pas` (~70 lines)
SDL2_image bindings, delayed imports in the shape of `Audio.pas`.
`IMG_Load_RW` replaced `SDL_LoadBMP_RW` at every load site. `EnsureImageLib`
runs at startup and raises plainly if the DLL is absent - unlike the optional
mixer, missing art is fatal.

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
  linear filter, fed from `<assetsDir>-objects.mset`; not owned here.

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
- The doses live in the dpr (`*Trauma` constants), not here - what shakes how
  much is game-flow policy; this unit is the mechanism.

### `Core/Render.Font.pas` (~405 lines)
Bitmap font, 448 px atlas, 16x16 glyph grid (CP1251 layout).
- **Constants**: atlas geometry (`FontAtlasSize`, `FontGridCells`,
  `FontCellPx`) + verbatim-2008 glyph metrics derived from the original's NDC
  math (`LegacyColumnWidth`, `SmallGlyphWidth/Height`, `BigGlyphWidth/Height`,
  `BigAdvanceRatio=0.8` - 20% overlap, `BigGlyphAspect`).
- **`TFontAtlasOrientation`** = (`faUpright`, `faRotatedCw`) - the atlas
  orientation fix.
- **`TMoonFont`** - takes an optional `TSpriteSet` (attached, not owned) and
  reads its atlas sprite out of it. `DrawSmall`, `DrawBig`, `DrawScaled`
  (arbitrary glyph height - the countdown digits),
  width measurers (`SmallTextWidth`, `BigTextWidth`, `ScaledTextWidth`),
  `DrawAtlas` (debug view, F key).

### `Game/Audio.pas` (~230 lines)
SDL2_mixer bindings (`delayed` imports - the game survives a missing DLL) plus
the sound bank.
- **`TMusicMode`** = (`mmLoop`, `mmOnce`).
- **`TSoundBank`** - dictionary of WAV chunks + one music slot. `Load`/`Play`
  (sounds\, strict: a bad name blows up at startup, not mid-boss),
  `PlayMusic`/`StopMusic` (music\, OGG, lenient: a missing track skips
  silently), `ToggleMusicMuted`, `Enabled` (False when the mixer DLL is absent
  -> every call becomes a no-op).

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
- ~60 `S*` string-key constants (protocol ids into the lang dictionaries):
  gameplay tickers, streak captions, henshin/bonus texts, ending screen, the
  full menu vocabulary.
- Free functions: `LoadLanguage` (swaps the flat dictionary from
  lang\en.json / ru.json, validated against the full key roster), `Tr(key)`,
  `CurrentLanguage`, `ReadLocalizedText(jsonObj, key)`, `MakeLocalizedText`.

### `Core/Levels.Defs.pas` (~545 lines)
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
  triggers, `Tag` (names the placement for the events' `allDead`; '' = none).
  `SpriteList` still carries the 2008 `.mns` spelling (`gravel.mns`); the stem
  names the `.mset` set and the extension is dropped at load. Renaming the
  field is a data change and waits for its own step.
- **`TColorTint`** (record) - R/G/B multipliers in percent, applied when
  the picture is drawn; `Neutral` = 100/100/100 (as painted). Shared by the
  backdrops and the objects.
- **`TBackgroundChange`** (record) - fromScreen + image + tint. The free
  `ReadTint` reads `"tint": [r, g, b]` for both; absent = neutral, any other
  shape or a value outside 0..100 raises (a picture silently left at full
  brightness looks like a tint nobody tuned).
- **`TLevelObject`** (record) - free-form art over the backdrop: sprite (in
  `<assetsDir>-objects.mset`), screen (1-based), x/y (top-left) and width in
  screen units, tint. No height: it follows the art's aspect, so a picture
  is never stretched. No collision - the grid alone decides where the hero
  stands.
- **`TLevel`** (class) - the parsed level: tiles `[screen][row][col]`,
  collision strings `[screen][row]` ('1' = solid), tile palette, backgrounds,
  entities, id/title/assetsDir/**spriteSets**/music/introText, grid dims,
  screenCount. `SpriteSets` is the environment sets in resolution order - tiles
  only; screen backdrops follow the `<assetsDir>-backdrops` convention and
  never appear there. `Objects` - the free-form art, in file order (later
  draws over earlier); the private `ParseObjects` reads the optional
  `objects` section and refuses an object off the screen list or with a
  width of zero or less. `Events` - the level's events (`Levels.Events`), in
  file order. Queries: `TileAt`, `SolidAt`, `BackgroundFor` (the whole
  change, last one wins; `Image = ''` when the level defines none).
  `LoadFromFile`; private `CheckEvents` refuses an event off the screen
  list or one waiting for a tag no placement carries (the latter would fire
  at once - nobody alive to hold it).

### `Core/Levels.Events.pas` (~140 lines)
The `events` section of level JSON: model and parser, no game logic (the
game runs them through `Events.Director`; the editor will write them).
- **`TEventCondition`** = (`ecEnterScreen`, `ecAllDead`) - what the event
  waits for. The hero must be on the event's screen for any of them;
  enterScreen asks nothing more, allDead waits until no live body carries
  the event's tag.
- **`TEventActionKind`** = (`eaBigMessage`, `eaSmallMessage`, `eaHint`,
  `eaMusic`); **`TEventAction`** (record) - kind + localized `Text` (the
  message kinds) or `FileName` (music).
- **`TLevelEvent`** (record) - id, screen (1-based), condition, tag,
  `DelayTicks` (counted after the condition holds, for any condition),
  actions. JSON: `"when": "allDead", "tag": "labGuard", "delay": 33,
  "then": [{"action": "hint", "text": "...", "textEn": "..."}]`.
- `EventConditionIds` / `EventActionIds` - the JSON vocabulary as typed
  constants. `ParseLevelEvents(root, levelId)`; an absent section is an
  empty list, an unknown condition or action, a missing id, an allDead
  without a tag or an event without actions raises `ELevelEventError`.
- Extending: a condition is an enum member, a word in `EventConditionIds`
  and a branch in the director's `ConditionHolds`; an action the same with
  `EventActionIds` and `Play`.

### `Core/Monsters.Defs.pas` (~440 lines)
Monster definition model + registry (parses monsters.json). No behavior.
- **Enums**: `TMonsterCategory` (mcEnemy/Pickup/Prop/Boss), `TMovementKind`
  (mkStatic/Patrol/PatrolNoEdgeCheck/ChaseHero/BossFly), `TAttackPattern`
  (apNone/StraightSingle/StraightCluster5/AimedSingle/AimedDouble/RainVolley),
  `TPickupEffectKind` (peNone/Heal/GiveWeapon).
- **Records**: `TMovementDef` (kind+speed); `TAttackDef` (pattern, fire cadence,
  bullet speed, pattern-specific params, `HasAttack`); `TPickupEffectDef`
  (peGiveWeapon rewires the whole weapon: type, cooldown, speed, gravity);
  `TSpawnEntry` (monsterId+weight); `TBossDef` (endsLevelOnDeath, spawn
  cadence/screen/table, `RageMusic`, `PickSpawn` weighted random);
  `TMonsterDef` - the full sheet: id, legacyName, displayName (localized),
  spriteList, category, dangerous, affectedByGravity, explodesOnDeath,
  movement, attack, pickupEffect, lives, score, animFreq, deathText
  (localized), deathSounds array, boss.
- **`TMonsterRegistry`** (class) - owns all defs; `LoadFromFile/String`,
  `Find`, `FindByLegacyName`, `TryFind`, `Count`, `AllDefs` (the sound bank
  warms its cache from here), spawn-table validation.

### `Game/Bullets.pas` (~310 lines)
Projectiles + all the 2008 particle-hack spawners.
- **`TFanShape`** (record) - rows/cols/baseSpeed/speedSpread of the k/t fan
  formula (the travel-test record: one template, five wearers).
- **`TBulletStatus`** = (`bsFlying`, `bsBursting`, `bsInactive`).
- **`TBullet`** - position, velocity, gravity ('dyy'), burst animation frame,
  `Contact` (participates in bullet-vs-bullet interception). `Move`,
  `StartBurst`, `StartBurstSliding` (a wall hit keeps 1/8 inertia).
- **`TBurst`** - owns a bullet list, its sprite set and its cache ('bullet' =
  hero, 'bull' = monsters; flight frame + destruction frames 2..8).
  `NewBullet`, `Clear` (screen transitions wipe bullets), `Update`, `Draw`.
  Spawners, all verbatim 2008: `SpawnExplosionFan` (a 180-fragment barrel /
  chain-reaction fan), `SpawnFan(shape)` (henshin finale / ice shatter / boss
  victory), `SpawnConvergingRing` (the henshin healing waves; Contact=True, so
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

### `Game/Monsters.pas` (~905 lines)
Monster behavior (data-driven off `TMonsterDef`) plus the field managing them.
- **Enums**: `TMonsterAction` (stand/walk/fall/fly x4), `TMonsterLife`
  (mlAlive/Dying/Dead), `TMonsterEvent` (meNone/BossWantsMinion/Henshin/
  BossRage/LevelComplete/Died) - 'MessageToMain' of 2008, drained by the game
  loop every tick.
- **`TMonster`** - position, screen, the placement's `Tag`, direction, lives
  (+`LivesAll`), anim frame, step, fire timer, enrage flag, boss minion timer, a one-shot henshin
  flag, the event list. Its own collision oracles
  (`CanGoLeftEdgeAware`/`WallOnly` pairs = CanIGo*1/2 of 2008, `CanGoDown`),
  `ShoveX`. Movement: `MoveWalking`/`Falling`/`Flying`, `PatrolStep`. Combat:
  `FireAt` (patterns from `TAttackDef`), `TakeDamage` (knockback through the
  wall oracle + explosion fans + events), `EnrageTankIfLow`,
  `ProcessBossThresholds`, `BeginDying`. Public: `Tick(heroX, heroY, bullets)`,
  `Draw`, `DrainEvent`, `HealthTier` (the crosshair's thirds of `LivesAll` as
  `TMonsterHealthTier` - the one home of that rule, via `ThirdMark`),
  `TierShare` (how full the current third is, 0..1), `TicksSinceHit` /
  `HitWithin(ticks)` (-1 until the first hit; the health rows read it, so the
  HUD keeps no memory of the field). `FSecret` is declared and always False -
  the placement flag it waits for is not in the level format yet.
- **`TMonsterField`** - owns `TObjectList<TMonster>`, the animset cache keyed
  by the placement's spriteList name, and one `TSpriteSet` plus one
  `TSpriteCache` per monster (all owned here; `AnimFor` opens
  `sprites\<stem>.mset` on first use). `FLivesScale` is the difficulty
  multiplier applied to every monster born in this field. `Tick` (current
  screen), `SpawnFromSky` (boss minions at a random top cell),
  `AnyAliveOnScreen` (the breakthrough gate - pickups count, verbatim),
  `AnyAliveTagged(tag)` (any live body carrying the placement tag, on any
  screen - the events' allDead), `Draw`.

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
  box is gone. The constructor takes the renderer for the terminal's brush.
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
The brush everything drawn with primitives shares: the HUD panels, the menu sky
rig and `Render.Glow`. No sprite, no font atlas. (Was Hud.Draw until the menu
started drawing with it; the class inside still carries the old name,
`THudBrush`.)
- **`TRgb`** (record); the palette as typed constants (`CalmColor` blue,
  `WaryColor` amber, `AlarmColor` red, `HaleColor` green, `BonusColor` lime +
  `BonusShade`, `CalmShade`, `PanelColor`, `White`); `Mix` (lerp);
  `HealthColor(health)` (red at 0-1, amber at 2, calm above).
- **`TXorShift`** (record) - an own random stream for HUD flourishes; `Random`
  feeds the boss spawn table and must not be touched by a spark.
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
- The readout: 3x5 digits, lime while a bonus is held, blinking at 1.
- Observes rather than listens: reacts to the difference between ticks
  (lost cell flash, grown cell glow, cure sweep on the trace, red frame on a
  hit, white blink of the cells during the mercy window).

### `Hud/Hud.Charge.pas` (~460 lines)
The score display: the bonus charge in the top-right corner, the twin of the
heart monitor, widened on the left by the reward slot (150 units against the
monitor's 118). **`THudCharge`** - `Tick(score, streak, bonus, novice)` once
per logic tick (bonus = the reward held, bkNone when the slot is empty; novice
= no reward spent yet), `Draw`.
- The readout (36 units, three digits, capped at 999), a bar filling toward
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
  bonus explosion, and the dpr reads the name from here.

### `Game/Events/Events.Director.pas` (~130 lines)
Runs the level's events (`Levels.Events`) against the live game.
**`TEventDirector`** takes the events, the message board and a
`TChangeMusic` callback (`reference to procedure`; the game passes its
`ChangeMusic` method, which also remembers the track for restarts). The
monster field is reborn on every restart, so it arrives with every tick
instead of being kept.
- `Tick(screen, field)` - once per logic tick with the hero's screen: for
  every unfired event of that screen, the condition is checked
  (`ConditionHolds`); while it holds the delay counts down, a lapse starts
  the count over; at zero the actions play once (`Play`: `ShowBig`,
  `AddTicker`, `StartTerminal` with the terminal header, the music
  callback). The game skips the tick over the hero's corpse.
- `ReArm(screen)` - death re-enters the screen with its monsters reborn,
  so its events wait for their moment again, as the entity triggers do.
- Reborn with the level (`LoadLevel`), like the ceremony and the HUD.

### `Core/Render.Glow.pas` (~165 lines)
Light drawn instead of loaded: white textures with the shape in their alpha,
additive, linear-filtered, so one texture serves every tint and level.
- **`TGlowShape`** = (`gsPoint`, `gsFlare`) - a Gaussian point and a
  four-spike flare, analytic (`PointSigma`, `Flare*` metrics in half-sides).
- Free functions: `CreateGlowShape(renderer, shape, side)`,
  `CreateGlowTexture(renderer, surface)` (a shape computed elsewhere - the
  logo halo - arrives as a surface and leaves with the same settings),
  `DrawGlow(renderer, texture, cx, cy, size, tint, level)` (centered
  square), `DrawGlowRect(..., dest, tint, level)`. Tint = color mod, level =
  alpha mod.
- Users: the stars, the embers, the logo halo. `EGlowError`.

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

### `Menu/Menu.Globe.pas` (~400 lines)
The moon of the menu as a spinning globe on the CPU. **`TMoonGlobe`** takes
the ui set and the map name (`moonmap`, 2048x1024 equirectangular, must be a
power-of-two width twice its height).
- Startup: `LoadMap` -> `BuildPyramid` (four halved levels: the limb samples
  a coarser level instead of skipping texels) -> `BuildTables` (every texel of
  the 512-texel disc gets its map row, longitude as a 32-bit turn, detail
  level, sunlight - Lommel-Seeliger with a `LimbFade`, earthshine on the
  night side, a `TGlobePixel` each) -> `BuildCurves` (gain and tone tables,
  `Exposure`, the cool 2008 tint, a soft `ToneKnee`).
- Runtime: `Tick` adds `FSpinStep` (one turn in 2640 ticks = 80 s) and marks
  dirty; `Draw(dest)` repaints the streaming texture once per tick and copies
  it into the square. The axis leans (`AxisRollDegrees`, `AxisTipDegrees`) so
  the spin reads as a globe, not a scrolling picture. Compiled `{$O+,R-,Q-}`
  whatever the build: a 33 Hz walk over a quarter million texels.

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
  (attached, not owned).
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
  `RequestQuit`.
- **`TGameHost`** - creates the window and renderer (the D3D11 hint lives
  here), `Run(app)`: event pump, fixed 33 Hz accumulator, fps title with
  worst-frame diagnostics, frame-budget wait for the no-vsync path.
  `TKeyAction` = (kaDown, kaUp).

### `Moon2D.dpr` (~1890 lines - NOT a stub, always grep it too)
Composition root plus the whole game-flow state machine (`TMoonGame`).
- **Top constants**: the level discovery pattern, config file name, asset dir
  names (`SoundsDir`, `MusicDir`), the weapon->shot sound map, named one-shot
  sounds (the bonus cost lives in `Game.Bonus`),
  `VictoryMusicFile`, `MenuMusicFile`, `LevelEndLingerTicks=400`,
  per-difficulty hero health and monster-lives multipliers, gravel trial
  cadence, ticker durations, the screen-shake doses (`ExploderTrauma`,
  `BossBlastTrauma`, `BonusExplosionTrauma`, `BonusFireRainTrauma` - a 2026
  addition; the ceremony's own live in `Game.Henshin`), ending-screen layout
  rows.
- **Types**: `TGameState` (gsMenu/gsIntro/gsPlaying/gsEnding).
- **`TMoonGame`** (extends `TGameApp`) - owns everything: registry, level, the
  level's sprite sets and its three caches (tiles, backdrops, objects), the ui
  and weapon sets, the sprite, tile and object renderers, hero, monster
  field, both bursts, font, message board, the screen shake, sound bank,
  menu, the ceremony (`THenshin`), the event director (`TEventDirector`),
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
    still, objects + tiles + bullets on the world channel - objects stand on
    the tiles and jolt with them - monsters and hero on their own, cursor and
    HUD still), `LoadLevel`, `OpenLevelArtSet` (the `<assetsDir>-<kind>.mset`
    convention of the backdrops and the objects in one place; the objects
    set is opened only by a level that places some), `StartPlaying`,
    `RestartLevel`,
    `AdvanceToNextLevel`, `CurrentLevelIsLast`, `BeginEnding`, `OpenMenu`,
    `ApplyMenuResult`, `ToggleFullscreen` (the player's switch, remembered in
    settings.json), `SetFullscreen` (the bare switch - the ending screen drops
    fullscreen for the browser through it, unremembered), `PreloadSounds`,
    `CreateHud` (builds the three HUD objects afresh on every level load),
    `ChangeMusic` (a trigger's or an event's track: played and remembered
    for restarts; '' is a no-op).
  - World: `HandleScreenTransitions`, `ArriveOnScreen`, `HandlePitFall`,
    `FireScreenTriggers`, `TickGravelAttack`; the events are the director's
    (`FDirector.Tick` after the tick's verdicts, `ReArm` in `RestartLevel`).
  - Combat: `ResolveHeroBulletHits`, `ResolveMonsterBulletHits`,
    `ResolveMonsterContact`, `RewardMonsterKill`, `HurtHero`,
    `DrainMonsterEvents` (also where explosions and boss blasts feed the
    shake), `ProcessKillStreak`, `AwardStreakBonus`.
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
    `NudgeMinigunMuzzle`, `DebugBrowseScreen`.
- **Free functions**: `OpenWebPage`, `BonusDisplayName`, bullet cell and
  off-screen helpers, `ReadLevelTitle`, `DiscoverLevels`, `RunGame` (the actual
  main: config -> host -> registry -> game).

---

## Tools

### `tools/SpritePack/` - sprite set packer (console app)
Builds and inspects `.mset` files. Wraps `Sprites.Sets` and nothing else.
- **`SpritePackCli.dpr`** (~350 lines) - commands `pack` / `list` / `unpack`.
  `pack` takes every PNG in a folder in natural order (2 before 10); `--list`
  splits a 2008 sprite list into named sequences by its length (16 lines ->
  alive+death, 24 -> walk+death+henshin, anything else -> one group). `unpack`
  writes the images plus `manifest.json`, so a set can always be taken apart.
- The sets are edited with the CLI alone: `unpack`, change, `pack`. The
  `pack-sets.ps1` script that built them from the loose 2008 art was a
  one-shot migration tool and is gone with the art (3.0.0; in git history).
- A VCL half (`SpritePack.exe`, sprite and description editing) is planned; the
  logic stays in `Sprites.Sets` so both executables are thin.

### `tools/TitleCard/` - trailer text-card generator (VCL app)
Renders arbitrary text in the game's bitmap font to PNG. Reuses `Sdl2.Core`,
`Sprites.Sets` and `Render.Font` from `Core/` by relative path - it opens
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
  batch pattern), ini load/save, `ResolveSpriteSet` (walks up to six folders
  looking for the set).
- **`TitleCard.Main.pas`** (~425 lines) - **`TMainForm`** (VCL): memo plus
  combos for aspect/scale/margins, live preview, single save and batch render.
- **`Image.Png.pas`** (~190 lines) - `SavePngRgba` free function, a hand-rolled
  PNG writer.

### `tools/bmp2png/convert.py`
The one-shot BMP->PNG migration with the color-key rule baked in (pure black ->
transparent). Kept for provenance; nothing calls it now.

### `tools/Selene/` - Selene map painter (Python)
Paints the living anti-moon for the menu globe from the menu's own `moonmap`;
nothing in the game reads the result yet. numpy + scipy + pillow.
- **`extract_moonmap.py`** - pulls `moonmap` out of `ui.mset`.
- **`paint_selene.py`** - surface + water mask, and (`clouds`) the cloud layer;
  seas from dark albedo, colour from a climate model, baked relief, rivers.
  Seeded: the same input gives the same planet bit for bit.
- **`preview_globe.py`** - renders the globe in "photo" light (glint, limb haze,
  terminator, cloud shadows) as the reference for a future `Menu.Globe`.
- **`selene_lib.py`** - sphere-sampled noise, wrap-aware filters, river tracer.
- **`out/`** - the approved maps (2048x1024) and preview.

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

### `monsters.json` (~11 KB)
Keys: `version`, `comment`, `defaults` (bound, spritesToDeath, animFreq, score,
dangerous - inherited by monsters), `monsters` array. 15 ids: `gravel`,
`gravelFemale`, `winter`, `zombieShooter`, `betoner`, `platform`, `tank`,
`mount`, `barrel`, `medkit`, `weaponShotgun`, `weaponGrenade`, `weapon3`,
`weapon4`, `boss1`. Parsed by `TMonsterRegistry` into `TMonsterDef` (see
Monsters.Defs above for the full field sheet). Nine of the fifteen carry no
`spriteList` - theirs comes from the level placement instead.

### `level1.json` (~49 KB) / `level2.json` (~19 KB)
The unified level format, parsed by `TLevel`. Keys: `version`, `id`,
`title`/`titleEn`, `assetsDir`, **`spriteSets`** (the environment sets, in resolution order),
`music`, `legacyTrailing` (a migration artifact, cleanup pending), `grid`
(16x12), `backgrounds` (fromScreen + image + optional `tint`, three
percentages), `objects` (optional: sprite, screen, x, y, width in screen
units, optional `tint`), `tilePalette`
(sprite names; index N in tiles -> palette[N-1]), `tiles` (`encoding`,
`emptyValue`, `screens` array of [row][col] grids), `entities` (placements:
monsterId, screen, x, y, spriteList, optional `difficulty` grades,
`overrides`, `triggers` - messages/hints/changeMusic/heroX-heroY/gravelBoss,
optional `tag` for the events), `events` (each: `id`, `screen`, `when` =
enterScreen | allDead + `tag`, optional `delay` in ticks, `then` = a list
of `action` objects - bigMessage/smallMessage/hint with `text`/`textEn`,
music with `file`; the med lab hint is the first), `introText`/`introTextEn`.
- level1: 17 screens, 145 entities, a 156-tile palette, 4 backgrounds - night
  (1-7), pre-dawn (8-11), `_black` for the fully tiled lab screens 12-13,
  sunrise (14-17); sets
  `brickwork mine-structure facility conveyor mining-rig railway mine-walls
  cargo mine-interior`. Objects: the ship on screen 1 (in place of the 2008
  shuttle), the broken satellite in the sky of 14-17.
- level2: 9 screens, 38 entities, a 35-tile palette, 4 backgrounds - day
  (1), the chasm edge (2), rock (3-5), the same rock darker (6-9); sets
  `moon-surface machinery facility common mine-interior`. Object: the
  satellite on screen 1, lit a little brighter (day). The gravel trial and
  the boss live here, and it ends the original campaign.

### `sprites\*.mset` (34 sets)
- **Hero and weapons**: `hero` (the walk/death/henshin sequences),
  `weapon` (held gun frames, bullets, crosshair),
  `weapon1`-`weapon4` (the pickups).
- **Entities**: `gravel`, `gravel2`, `vinter`, `shoot1`, `betoner`, `barrel`,
  `medic`, `krep`, `platform`, `tank`, `boss1` - referenced by a placement's
  `spriteList`, still spelled `<stem>.mns`.
- **Tile themes**: `brickwork`, `cargo`, `common`, `conveyor`, `facility`,
  `machinery`, `mine-interior`, `mine-structure`, `mine-walls`, `mining-rig`,
  `moon-surface`, `railway` - grouped by subject, not by level, because levels
  share tiles.
- **Backdrops**: `level1-backdrops`, `level2-backdrops` - found by the
  `<assetsDir>-backdrops` convention, never declared in `spriteSets`. HD
  since 3.0.11: 1440x1080 (4:3, the playfield of a 1080p screen 1:1), drawn
  linear-filtered and tinted per change; `_black` stays a 512x512 fill.
- **Objects**: `level1-objects` (`ship`, `satellite`), `level2-objects`
  (`satellite`, the same picture) - the `<assetsDir>-objects` convention,
  never declared in `spriteSets`. Drawn at backdrop density (1440 px per
  512 units), transparent pixels filled with the edge color so the linear
  filter leaves no dark fringe.
- **Interface**: `ui` - `sky` (16:9 nebula), `moonmap` (2048x1024 lunar
  surface), `logo` (letters alone), the language flags (240x160) and the
  `font`/`fontx`/`fonty` atlases. Stars, halo and embers are generated.

### `lang/en.json` / `lang/ru.json` (~2-3 KB)
Flat key->string dictionaries for UI and gameplay text (every `S*` key of
`Localization.pas`): tickers, streaks, henshin/bonus, ending screen, the full
menu vocabulary. Level and monster content is NOT here - it is localized in
place in the level and monster JSONs via the base-field + `En`-sibling pattern.

### `sounds/` (18 WAV) and `music/` (OGG)
One-shots load strictly at startup; music loads leniently. Tracks referenced by
data: `moon.ogg` (menu), `moon_surface.ogg`, `underground.ogg`,
`moon_surface2.ogg`, `boss1.ogg`, `hallu.ogg`, `under01.ogg`, `boss2.ogg`,
`win.ogg`.

---

## Quick task-routing table

| Task smells like... | Look at |
| --- | --- |
| Hero movement / collision / jump feel | Hero.pas |
| Weapon patterns / crosshair | Hero.pas (+Bullets.pas) |
| Monster behavior / AI / boss | Monsters.pas + Monsters.Defs.pas + monsters.json |
| New monster (data only) | monsters.json + a `.mset` set (spriteList keeps the `.mns` spelling) |
| Explosions / particles | Bullets.pas |
| The henshin ceremony: countdown, waves, the suit on and off | Game.Henshin.pas (+Bullets.pas for the fans and rings) |
| Level content / triggers / screens | levelN.json + Levels.Defs.pas |
| A level event: when it fires, what it does; a new condition or action | `events` in levelN.json + Levels.Events.pas (model) + Events.Director.pas (runner) |
| Game flow / state machine / scoring / bonuses / gravel trial | Moon2D.dpr |
| Screen size vs frame size; anything for the wide screen | Game.Space.pas (then every reader of `Frame*` / `Screen*`) |
| Health monitor / bonus charge panels: look, colors, timings | Hud.Vitals.pas / Hud.Charge.pas (+Render.Brush.pas for the brush and palette) |
| Health rows over the hero / monsters; the crosshair's thirds | Hud.Marks.pas (+Render.Brush.pas for the cells) + Monsters.pas (`HealthTier`, `TicksSinceHit`) |
| Screen transitions / checkpoints | Moon2D.dpr (HandleScreenTransitions, ArriveOnScreen) |
| Menu screens / layout / language switching / trailer showcase frames | Menu.pas + Localization.pas |
| Menu sky: stars, the spinning moon, the dolly into a submenu | Menu.Starfield.pas / Menu.Globe.pas / Menu.pas (`DrawSky`, `*Zoom`) |
| Logo halo and embers; a redrawn logo | Menu.Logo.pas + Menu.Embers.pas (+ the `logo` sprite in ui.mset) |
| Anything that glows additively | Render.Glow.pas |
| Text rendering / new captions | Render.Font.pas + Hud.Messages.pas + lang JSONs |
| Level hints / the comm terminal | Hud.Terminal.pas (+Hud.Messages.pas for the ticker lane, `hintText` in level JSON) |
| Story screen before a level / typing rhythm | Hud.Briefing.pas / Hud.Typewriter.pas (+`introText` in level JSON) |
| Frame pacing / window / vsync | Game.Loop.pas (+Sdl2.Core.pas) |
| Sound / music | Audio.pas (+data fields in JSONs) |
| Tile/background rendering | Render.Tiles.pas + Render.Sprites.pas |
| Free-form art over the backdrop (the ship, the satellite): place, size, tint | `objects` in levelN.json + `<assetsDir>-objects.mset` + Render.Objects.pas (+Levels.Defs.pas `TLevelObject`) |
| Screen shake: doses, what shakes, what stands still | Moon2D.dpr (`*Trauma` constants, `Render`, `DrainMonsterEvents`) + Render.Shake.pas |
| A sprite name resolves to the wrong picture | Render.Sprites.pas (Get, AmbiguousNames) + the level's `spriteSets` order |
| A monster/hero loads wrong frames from a set | Monsters.pas AnimFor / Hero.pas OpenFrames |
| Sprite sets / the `.mset` format | Sprites.Sets.pas + docs/MSET-FORMAT.md |
| Packing or inspecting sets | tools/SpritePack/* |
| Trailer cards | tools/TitleCard/* |
| Selene: the living moon's map for the menu | tools/Selene/* |
| PNG loading / image DLL | Sdl2.Image.pas |
