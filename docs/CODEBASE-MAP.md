# Moon 2D — Codebase Map

Reference document. Purpose: given this file plus a task description, know which
files to open without re-exploring the repository.

Repo: `https://github.com/rm3g25/moon2d/` · Delphi 10.3+ (inline var) + SDL2,
Win32. Logic space 512×384 game units (16×12 cells of 32), tile art 64 px,
fixed tick 33 Hz, screen-by-screen levels.

Regenerated at `c4896e0`. Where the map and the code disagree, the code is right.

Dependency direction (roughly bottom-up):
`Sdl2.Core` / `Sprites.Sets` → `Render.*` / `Audio` / `Game.Config` /
`Localization` → `Levels.Defs` / `Monsters.Defs` → `Bullets` → `Hero` /
`Monsters` / `Hud.Messages` / `Menu` / `Render.Tiles` → `Game.Loop` →
`Moon2D.dpr`.

---

## Game units

### `Sdl2.Core.pas` (~365 lines)
Hand-written SDL2 bindings. No classes — constants, records, `external`
declarations against `SDL2.dll`.
- **Constants**: init flags, window flags (incl. `SdlWindowHidden` for the
  offscreen tools), renderer flags, texture access (incl. `Target`), hints
  (`SdlHintRenderDriver`, `SdlHintRenderScaleQuality`), event type ids, flip
  flags, pixel format `SdlPixelFormatAbgr8888`, blend modes, the scancodes the
  game uses.
- **Records**: `TSdlRect`, `TSdlFRect`, `TSdlPoint`, `TSdlRendererInfo`,
  `TSdlVersion`, `TSdlSurface` (partial mirror — leading fields only),
  `TSdlKeysym`, `TSdlKeyboardEvent`, `TSdlMouseMotionEvent`,
  `TSdlMouseButtonEvent`, `TSdlEvent` (variant record, 56-byte padding arm).
- **Imports**: window/renderer lifecycle, draw calls (`SDL_RenderCopy/F/Ex`,
  fill, clear, present), surfaces + color key + format conversion, textures
  (incl. target textures and `SDL_RenderReadPixels` — used by TitleCard),
  events, timing (`SDL_GetPerformanceCounter/Frequency`, `SDL_Delay`),
  `SDL_SetHint`, `SDL_RenderSetLogicalSize`, `SDL_RWFromMem`.
- **Helpers**: `SdlText(string)→UTF8String`, `SdlErrorText`.
- Touch this file when: a new SDL function is needed, event handling, ABI
  questions.

### `Sprites.Sets.pas` (~445 lines)
The `.mset` sprite set container: a JSON manifest followed by every image
concatenated behind it. Read by the game, the packer and (later) the level
editor — one unit, three callers. Every sprite in the game comes from a set;
loose image files no longer ship. `SetQualifier` (':') lives here too, since
the editor and the packer read the same syntax.
- **Constants**: `MsetVersion=1`, `SetQualifier=':'`. Manifest field names are
  constants (`KeyId`, `KeySprites`, `KeyOffset`…) — a typo in a literal
  compiles.
- **Records**: `TSpriteEntry` (name, description, offset, size — offset is
  measured from the start of the blob block, not the file), `TSpriteSequence`
  (name, description, frames), `TMsetHeader` (packed: magic, version, manifest
  size), `TMsetMagic` (named type — an anonymous `array[0..3] of AnsiChar` will
  not assign to another one).
- **`TSpriteSet`** — read side. Opening parses the manifest only; image bytes
  arrive on demand via `ReadSprite(name)`. `Contains`, `SequenceFrames`;
  properties `Id`, `Description`, `Entries`, `Sequences`.
- **`TSpriteSetWriter`** — write side. `AddSprite`/`AddSpriteFile`,
  `AddSequence`, `SaveToFile`. Offsets are handed out at save time in add
  order; writing is deterministic, so an unchanged set rebuilds byte for byte.
  Validates duplicate names and sequences pointing at absent frames.
- Format spec: `docs/MSET-FORMAT.md`.

### `Render.Sprites.pas` (~455 lines)
Texture cache + low-level sprite drawing. Owns the unit-size constants.
- **Constants**: `SpriteSetsDir` ('sprites\'), `SpriteSize=32`, `TileSize=32`
  (game units!), `TileArtSize=64` (texture px!), `FramesAlive=8`,
  `FramesDeath=8`. The 32-vs-64 split is the coordinate-system discipline in
  code form.
- **`TSpriteCache`** — dictionary `set:name → PSdlTexture`, lazy load from the
  sets attached via `AttachSpriteSet` (not owned — the opener frees them).
  Resolution: a qualified name (`common:pustota`) goes to that set alone; a
  bare name takes the first attached set that has it; **a name no attached set
  carries raises `ESpriteError`** — there is no folder fallback left. Path and
  extension are dropped when looking up, so the 2008 spellings in level
  palettes (`level1\doom1.png`) still resolve. `AmbiguousNames` reports bare
  names carried by more than one attached set — those would resolve by
  declaration order, which is exactly what the qualifier exists to avoid.
  Optional color key (`SetColorKey`/`DisableColorKey`).
- **`LoadImageSurface(spriteSet, name)`** (free function) — the one place that
  turns stored bytes into a surface. Returns `nil` for a nil set or an unknown
  name; the caller words the error, since only it knows what the picture was
  for.
- **`TAnimSet`** (record) — `Alive[0..7]` + `Death[0..7]` texture arrays;
  `IsLoaded`. Built by **`LoadAnimSet(cache, spriteSet)`** from the manifest's
  `alive` and `death` sequences, each validated to exactly eight frames —
  `TAnimSet` is the 2008 contract and it is fixed-size.
- **`TSpriteRenderer`** — draws in game units: `DrawCell` (sprite grid),
  `DrawTile` (tile grid, the top-left 64×64 crop reproduced from
  `sttextures.pas`), `Draw` (free position, optional mirror), `DrawRect`,
  `DrawRotated` (weapon arm).

### `Sdl2.Image.pas` (~70 lines)
SDL2_image bindings, delayed imports in the shape of `Audio.pas`.
`IMG_Load_RW` replaced `SDL_LoadBMP_RW` at every load site. `EnsureImageLib`
runs at startup and raises plainly if the DLL is absent — unlike the optional
mixer, missing art is fatal.

### `Render.Tiles.pas` (~100 lines)
- **`TTileScreenRenderer`** — draws one screen: `DrawScreen` =
  `DrawBackground` (the screen's backdrop sprite via `FBackgroundCache`) +
  `DrawTiles` (palette indices from `TLevel` via `FTileCache`). Both caches are
  fed from `.mset` sets by the composition root, and neither is owned here.
  The background/tiles split is the hook for the future "AI backgrounds as art
  layer" idea.

### `Render.Font.pas` (~350 lines)
Bitmap font, 448 px atlas, 16×16 glyph grid (CP1251 layout).
- **Constants**: atlas geometry (`FontAtlasSize`, `FontGridCells`,
  `FontCellPx`) + verbatim-2008 glyph metrics derived from the original's NDC
  math (`LegacyColumnWidth`, `SmallGlyphWidth/Height`, `BigGlyphWidth/Height`,
  `BigAdvanceRatio=0.8` — 20% overlap, `BigGlyphAspect`).
- **`TFontAtlasOrientation`** = (`faUpright`, `faRotatedCw`) — the atlas
  orientation fix.
- **`TMoonFont`** — takes an optional `TSpriteSet` (attached, not owned) and
  reads its atlas sprite out of it. `DrawSmall`, `DrawBig`, `DrawSmallBlock`
  (multi-line), `DrawScaled` (arbitrary glyph height — the countdown digits),
  width measurers (`SmallTextWidth`, `BigTextWidth`, `ScaledTextWidth`),
  `DrawAtlas` (debug view, F key).

### `Audio.pas` (~230 lines)
SDL2_mixer bindings (`delayed` imports — the game survives a missing DLL) plus
the sound bank.
- **`TMusicMode`** = (`mmLoop`, `mmOnce`).
- **`TSoundBank`** — dictionary of WAV chunks + one music slot. `Load`/`Play`
  (sounds\, strict: a bad name blows up at startup, not mid-boss),
  `PlayMusic`/`StopMusic` (music\, OGG, lenient: a missing track skips
  silently), `ToggleMusicMuted`, `Enabled` (False when the mixer DLL is absent
  → every call becomes a no-op).

### `Game.Config.pas` (~225 lines)
- **`TDifficulty`** = (`dfNormal`, `dfHard`, `dfWild`); `TDifficultyGrades`
  set; `DifficultyIds` protocol strings ('normal'/'hard'/'wild');
  `AllDifficultyGrades`.
- **`TLanguage`** = (`lgEnglish`, `lgRussian`); `LanguageIds` ('en'/'ru') — one
  vocabulary serving both config.json and the dictionary file names.
- **`TGameConfig`** (record) — window w/h, fullscreen, vsync, fpsCap, tickRate,
  difficulty, language; `Defaults` factory. Any parse problem returns
  `Defaults`: configuration is a preference, never a reason to crash.
- Free functions: `LoadGameConfig`, `SaveGameDifficulty`, `SaveGameLanguage`
  (partial rewrites of config.json, silent on a locked file).

### `Localization.pas` (~310 lines)
- **`TLocalizedText`** (record) — `Values[TLanguage]`, `Current`. Used for
  level and monster content (base JSON field = RU, `En` sibling = EN, an absent
  sibling falls back at parse time).
- ~60 `S*` string-key constants (protocol ids into the lang dictionaries):
  gameplay tickers, streak captions, henshin/bonus texts, ending screen, the
  full menu vocabulary.
- Free functions: `LoadLanguage` (swaps the flat dictionary from
  lang\en.json / ru.json, validated against the full key roster), `Tr(key)`,
  `CurrentLanguage`, `ReadLocalizedText(jsonObj, key)`, `MakeLocalizedText`.

### `Levels.Defs.pas` (~405 lines)
Level data model + JSON parser. No game logic.
- **`EmptyTile = 0`** — grid value 0 is nothing; N ≥ 1 maps to
  `TilePalette[N - 1]`.
- **`TEntityOverrides`** (record) — optional per-placement direction, speed,
  lives, canShoot (Has* flag + value pairs).
- **`TDifficultyValue`** (record) — one int per grade; JSON = a number or
  `{"normal":..,"hard":..,"wild":..}`; `Uniform`, `ForGrade`.
- **`TEntityTriggers`** (record) — `BigMessage`/`SmallMessage`/`HintText`
  (localized), `ChangeMusic`, heroX/heroY reposition (vertical transitions),
  the gravel trial quota (`HasGravelBoss` + `GravelQuota: TDifficultyValue`).
- **`TEntityPlacement`** (record) — monsterId, screen (1-based), x/y (sprite
  grid), spriteList, `Grades` (the Doom skill-flag idiom), overrides, triggers.
  `SpriteList` still carries the 2008 `.mns` spelling (`gravel.mns`); the stem
  names the `.mset` set and the extension is dropped at load. Renaming the
  field is a data change and waits for its own step.
- **`TBackgroundChange`** (record) — fromScreen + image.
- **`TLevel`** (class) — the parsed level: tiles `[screen][row][col]`,
  collision strings `[screen][row]` ('1' = solid), tile palette, backgrounds,
  entities, id/title/assetsDir/**spriteSets**/music/introText, grid dims,
  screenCount. `SpriteSets` is the environment sets in resolution order — tiles
  only; screen backdrops follow the `<assetsDir>-backdrops` convention and
  never appear there. Queries: `TileAt`, `SolidAt`, `BackgroundFor` (last
  change wins). `LoadFromFile`.

### `Monsters.Defs.pas` (~440 lines)
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
  `TMonsterDef` — the full sheet: id, legacyName, displayName (localized),
  spriteList, category, dangerous, affectedByGravity, explodesOnDeath,
  movement, attack, pickupEffect, lives, score, animFreq, deathText
  (localized), deathSounds array, boss.
- **`TMonsterRegistry`** (class) — owns all defs; `LoadFromFile/String`,
  `Find`, `FindByLegacyName`, `TryFind`, `Count`, `AllDefs` (the sound bank
  warms its cache from here), spawn-table validation.

### `Bullets.pas` (~310 lines)
Projectiles + all the 2008 particle-hack spawners.
- **`TFanShape`** (record) — rows/cols/baseSpeed/speedSpread of the k/t fan
  formula (the travel-test record: one template, five wearers).
- **`TBulletStatus`** = (`bsFlying`, `bsBursting`, `bsInactive`).
- **`TBullet`** — position, velocity, gravity ('dyy'), burst animation frame,
  `Contact` (participates in bullet-vs-bullet interception). `Move`,
  `StartBurst`, `StartBurstSliding` (a wall hit keeps 1/8 inertia).
- **`TBurst`** — owns a bullet list, its sprite set and its cache ('bullet' =
  hero, 'bull' = monsters; flight frame + destruction frames 2..8).
  `NewBullet`, `Clear` (screen transitions wipe bullets), `Update`, `Draw`.
  Spawners, all verbatim 2008: `SpawnExplosionFan` (a 180-fragment barrel /
  chain-reaction fan), `SpawnFan(shape)` (henshin finale / ice shatter / boss
  victory), `SpawnConvergingRing` (the henshin healing waves; Contact=True, so
  the ring wounds the boss), `SpawnFireRain` (768 slow bullets on a 16-unit
  grid), `SpawnStaticAura` (motionless bullets = the 2008 shield hack, halved
  to 250 in 2.1.1).
- Known wart: `TBurst.Draw` advances burst animation frames — it mutates
  simulation state from the render path, and that is what blocks render
  interpolation for the game world.

### `Hero.pas` (~1170 lines)
The hero: physics, weapons, death. Owns `GameWidth=512`, `GameHeight=384`,
`HeroSize=32`.
- **Enums**: `THeroAction` (stand/walk/jump/fall × direction), `THeroCommand`
  (go/stop left/right, jump/stopJump), `THeroForm` (hfNormal/hfIce),
  `TPendingSide` ('ExtraInstruction' of 2008 — a queued side intent executed
  once the barrier clears).
- **`THero`** —
  - Art: `hero.mset` (24 frames as the `walk`, `death` and `henshin` sequences)
    plus the weapon set, both owned; `OpenFrames` pulls named sequences out of
    a set.
  - State: FX/FY (Y = the FEET line), screen, action, direction, walk frame,
    acceleration, form, death fields (frame 9→16, corpse settling).
  - Collision oracles (verbatim 2008): `Solid`, `CellOfX/Y`, `CellsOfX/Y` (a
    32-unit span straddling two cells), `CanIGoLeft/Right/Up/Down`,
    `CanIFlyLeft/Right`, `WallBlocksLeft/Right` (side-effect-free probes for
    shoves), `GroundUnderFeet`, `LandExactly`, `SettleOnGround`.
  - Weapon: `FBullets: TBurst`, type 0..4 (pistol / shotgun×5 / grenade
    cloud×22 / chain×3 / minigun with alternating side shots), cooldown /
    speed / gravity state, `Fire: Boolean` (True = a shot actually left the
    barrel, so the caller barks the sound), `SetWeaponAngle`, `DrawWeapon`,
    the crosshair (`DrawCrosshair` frames 1..4 = the smart cursor colors), the
    minigun muzzle live tuner (`NudgeMinigun`, DEBUGKEYS).
  - Lifecycle: `Command`, `Tick` (verbatim OurHero.Timer), `Draw`, `SetMouse`,
    `PlaceAtCell`, `SetScreenX`, `SetY`, `ShoveX` (unit by unit, stops at
    walls), `ApplyWeaponPickup`, `Kill`, `Revive`.

### `Monsters.pas` (~830 lines)
Monster behavior (data-driven off `TMonsterDef`) plus the field managing them.
- **Enums**: `TMonsterAction` (stand/walk/fall/fly×4), `TMonsterLife`
  (mlAlive/Dying/Dead), `TMonsterEvent` (meNone/BossWantsMinion/Henshin/
  BossRage/LevelComplete/Died) — 'MessageToMain' of 2008, drained by the game
  loop every tick.
- **`TMonster`** — position, screen, direction, lives (+`LivesAll`), anim
  frame, step, fire timer, enrage flag, boss minion timer, a one-shot henshin
  flag, the event list. Its own collision oracles
  (`CanGoLeftEdgeAware`/`WallOnly` pairs = CanIGo*1/2 of 2008, `CanGoDown`),
  `ShoveX`. Movement: `MoveWalking`/`Falling`/`Flying`, `PatrolStep`. Combat:
  `FireAt` (patterns from `TAttackDef`), `TakeDamage` (knockback through the
  wall oracle + explosion fans + events), `EnrageTankIfLow`,
  `ProcessBossThresholds`, `BeginDying`. Public: `Tick(heroX, heroY, bullets)`,
  `Draw`, `DrainEvent`. `FSecret` is declared and always False — the placement
  flag it waits for is not in the level format yet.
- **`TMonsterField`** — owns `TObjectList<TMonster>`, the animset cache keyed
  by the placement's spriteList name, and one `TSpriteSet` plus one
  `TSpriteCache` per monster (all owned here; `AnimFor` opens
  `sprites\<stem>.mset` on first use). `FLivesScale` is the difficulty
  multiplier applied to every monster born in this field. `Tick` (current
  screen), `SpawnFromSky` (boss minions at a random top cell),
  `AnyAliveOnScreen` (the breakthrough gate — pickups count, verbatim), `Draw`.

### `Hud.Messages.pas` (~310 lines)
- **`TMessageBoard`** — the 2008 message system: ticker lines (slide-in,
  private `TTickerLine` record), the big mid-screen headline, the marquee
  ('Бегущая строка'), score popups (private `TScorePopup`, '+N' rising).
  `Tick` / `Draw(alpha)` — draw is interpolation-aware (marquee, popups).
  API: `AddTicker`, `ShowBig`, `StartMarquee`, `AddScorePopup`, `ClearPopups`
  (screen transitions strand popups over the wrong geometry), `Clear` (death
  silences the board).

### `Menu.pas` (~945 lines)
The main menu with its flying moon and starfield.
- **Records**: `TLevelChoice` (fileName + localized title; discovery is done by
  the composition root, which owns the file system), `TMenuResult` (command +
  payload), `TMenuItem`, `TStar` (verbatim TStar of MenuPic.pas: kind 0..7 =
  speed class AND sprite index; the texture is resolved once at init),
  `TMoonDrift` (the drifting moon in the 2008 "sdvig" ±500 space; `Respawn`,
  `Tick`).
- **Enums**: `TMenuCommand` (mcNone/StartLevel/Resume/ToggleFullscreen/
  SetDifficulty/SetLanguage/Quit), `TMenuScreen` (msMain/LevelSelect/
  Difficulty/Credits/QuitConfirm), `TItemAction` (internal navigation vs
  surfaced commands), **`TShowcaseKind`** (skNone/skLogo/skSky) — the trailer
  frames: the live sky rig alone, with or without the logo. Only the debug keys
  can enter one, so with DEBUGKEYS off the state stays skNone.
- **`TMoonMenu`** — sky/moon/logo textures, stars, an item list per screen,
  language flags (owned textures; `FlagRect` is the draw AND hit-test
  geometry), a difficulty display copy. Takes the ui set and the weapon set
  (attached, not owned). `ShowMain`, `Tick`, `Draw(alpha)`, `DrawSky(alpha)`
  (the story screen reuses the live sky as scenery), `MouseMove`,
  `Click → TMenuResult`, `HandleEscape` (True = consumed),
  `ShowShowcase`/`ShowcaseActive`/`EndShowcase`. Properties `HasActiveGame`,
  `Difficulty`, `Language` (the setter rebuilds captions through `Tr` — set it
  AFTER the dictionary swap).

### `Game.Loop.pas` (~385 lines)
Host: window and renderer plus the fixed-timestep loop.
- **`TGameApp`** (abstract) — `Update(dt)` (fixed), `Render(renderer, alpha)`
  (alpha = the interpolation fraction), `HandleKey/MouseMove/MouseButton`,
  `RequestQuit`.
- **`TGameHost`** — creates the window and renderer (the D3D11 hint lives
  here), `Run(app)`: event pump, fixed 33 Hz accumulator, fps title with
  worst-frame diagnostics, frame-budget wait for the no-vsync path.
  `TKeyAction` = (kaDown, kaUp).

### `Moon2D.dpr` (~1955 lines — NOT a stub, always grep it too)
Composition root plus the whole game-flow state machine (`TMoonGame`).
- **Top constants**: the level discovery pattern, config file name, asset dir
  names (`SoundsDir`, `MusicDir`), the weapon→shot sound map, named one-shot
  sounds, the bonus roulette (`BonusCost=50` and its HUD slide),
  `VictoryMusicFile`, `MenuMusicFile`, `LevelEndLingerTicks=400`,
  per-difficulty hero health and monster-lives multipliers, gravel trial
  cadence, ticker durations, the henshin wave schedule (`HenshinWaves[0..4]`:
  tick/bullets/radius), flash and finish ticks, ending-screen layout rows,
  countdown tuning (the 3..2..1 prelude — a 2026 authorial addition).
- **Types**: `TGameState` (gsMenu/gsIntro/gsPlaying/gsEnding), `THenshinWave`
  (record), `TBonusKind` (bkNone/Health/FireRain/Aura/Explosion).
- **`TMoonGame`** (extends `TGameApp`) — owns everything: registry, level, the
  level's sprite sets and both level caches, the ui and weapon sets, sprite and
  tile renderers, hero, monster field, both bursts, font, message board, sound
  bank, menu. Key state: game state + resume state, held-key flags (the 2008
  polled-keyboard model), health + hurt cooldown, game-over timer, checkpoint
  X/Y, score + kill streak, per-entity trigger-fired flags, henshin
  (active/tick) + countdown (digit/tick/handover), the bonus slot (+ its queued
  activation), the gravel trial (attack flag, quota, wave timer, screen), the
  end-level timer, the level list + current file + current music, fullscreen
  and difficulty.
  Method clusters:
  - Flow: `Update`, `Render`, `LoadLevel`, `StartPlaying`, `RestartLevel`,
    `AdvanceToNextLevel`, `CurrentLevelIsLast`, `BeginEnding`, `OpenMenu`,
    `ApplyMenuResult`, `ToggleFullscreen`, `PreloadSounds`.
  - World: `HandleScreenTransitions`, `ArriveOnScreen`, `HandlePitFall`,
    `FireScreenTriggers`, `TickGravelAttack`.
  - Combat: `ResolveHeroBulletHits`, `ResolveMonsterBulletHits`,
    `ResolveMonsterContact`, `RewardMonsterKill`, `HurtHero`,
    `DrainMonsterEvents`, `ProcessKillStreak`, `AwardStreakBonus`.
  - Henshin/bonus: `StartHenshinCountdown`/`TickCountdown`/`DrawCountdown`,
    `StartHenshin`/`TickHenshin`/`FinishHenshin`, `RemoveIceForm`, `CureHero`,
    `AwardRandomBonus`, `ActivateQueuedBonus`, `DrawBonusHud`.
  - Drawing/input: `DrawHud`, `DrawIntro`, `DrawEnding`, `DrawCenteredBig`,
    `HitEndingLine`, `HandleEndingClick`, `DrawMessages`, `CrosshairFrame`,
    `HandleKey/MouseMove/MouseButton`.
  - Debug: `HandleDebugKey`, `HandleDebugMenuKey`, `UpdateInspectorCaption`,
    `DrawAtlasOverlay` — the four doors the debug keyboard uses, and nothing
    else. All four exist in every build; their bodies compile away, so no
    caller needs an ifdef. Behind them: `NudgeCrosshair`,
    `NudgeMinigunMuzzle`, `DebugBrowseScreen`.
- **Free functions**: `OpenWebPage`, `BonusDisplayName`, bullet cell and
  off-screen helpers, `ReadLevelTitle`, `DiscoverLevels`, `RunGame` (the actual
  main: config → host → registry → game).

---

## Tools

### `tools/SpritePack/` — sprite set packer (console app)
Builds and inspects `.mset` files. Wraps `Sprites.Sets` and nothing else.
- **`SpritePackCli.dpr`** (~350 lines) — commands `pack` / `list` / `unpack`.
  `pack` takes every PNG in a folder in natural order (2 before 10); `--list`
  splits a 2008 sprite list into named sequences by its length (16 lines →
  alive+death, 24 → walk+death+henshin, anything else → one group). `unpack`
  writes the images plus `manifest.json`, so a set can always be taken apart.
- **`pack-sets.ps1`** — builds every set in one run and holds the tile theme
  tables: the first matching pattern claims a name, leftovers are packed
  separately and reported so nothing disappears quietly. It rebuilds the sets
  from a working copy of the loose art — the shipped game has none, so this is
  a maintenance tool, not a build step.
- A VCL half (`SpritePack.exe`, sprite and description editing) is planned; the
  logic stays in `Sprites.Sets` so both executables are thin.

### `tools/TitleCard/` — trailer text-card generator (VCL app)
Renders arbitrary text in the game's bitmap font to PNG. Reuses `Sdl2.Core`,
`Sprites.Sets` and `Render.Font` by relative path — it opens `ui.mset` and asks
for the `fonty` sprite, the same path the game takes.
- **`TitleCard.dpr`** — VCL bootstrap.
- **`TitleCard.Layout.pas`** (~355 lines) — pure layout math. Constants:
  measured font ink metrics (`InkTopRatio`, `CapHeightRatio`). Records:
  `TCardGeometry` (size, margins, optical center 0.45, line spacing),
  `TCardScale` (smFitInteger/FitFree/Explicit + factories), `TPlacedLine`,
  `TCardLayout` (cellHeight, lines, charLimit, overflow queries). Functions:
  `BuildCardLayout`, `WrapCardText` (emergency word-wrap), `SplitCards` (a
  batch file split on blank lines), geometry helpers.
- **`TitleCard.Renderer.pas`** (~165 lines) — **`TCardRenderer`**: a hidden SDL
  window plus a target texture, renders a layout, `RenderCard → TBytes` (RGBA
  top-down) via `SDL_RenderReadPixels`. `TCardBackground` = (cbTransparent,
  cbBlack).
- **`TitleCard.Config.pas`** (~170 lines) — **`TTitleCardConfig`** record
  (sprite set path, font sprite name, render driver, geometry, scale steps,
  batch pattern), ini load/save, `ResolveSpriteSet` (walks up to six folders
  looking for the set).
- **`TitleCard.Main.pas`** (~425 lines) — **`TMainForm`** (VCL): memo plus
  combos for aspect/scale/margins, live preview, single save and batch render.
- **`Image.Png.pas`** (~190 lines) — `SavePngRgba` free function, a hand-rolled
  PNG writer.

### `tools/bmp2png/convert.py`
The one-shot BMP→PNG migration with the color-key rule baked in (pure black →
transparent). Kept for provenance; nothing calls it now.

---

## Runtime data (`bin\`)

### `config.json` (tiny)
`window` (width/height/fullscreen/vsync/fpsCap) + `game` (tickRate, difficulty
id, language id). Read by `Game.Config`; difficulty and language are saved back
individually.

### `monsters.json` (~11 KB)
Keys: `version`, `comment`, `defaults` (bound, spritesToDeath, animFreq, score,
dangerous — inherited by monsters), `monsters` array. 15 ids: `gravel`,
`gravelFemale`, `winter`, `zombieShooter`, `betoner`, `platform`, `tank`,
`mount`, `barrel`, `medkit`, `weaponShotgun`, `weaponGrenade`, `weapon3`,
`weapon4`, `boss1`. Parsed by `TMonsterRegistry` into `TMonsterDef` (see
Monsters.Defs above for the full field sheet). Nine of the fifteen carry no
`spriteList` — theirs comes from the level placement instead.

### `level1.json` (~49 KB) / `level2.json` (~19 KB)
The unified level format, parsed by `TLevel`. Keys: `version`, `id`,
`title`/`titleEn`, `assetsDir`, **`spriteSets`** (the environment sets, in
resolution order), `music`, `legacyTrailing` (a migration artifact, cleanup
pending), `grid` (16×12), `backgrounds` (fromScreen + image), `tilePalette`
(sprite names; index N in tiles → palette[N-1]), `tiles` (`encoding`,
`emptyValue`, `screens` array of [row][col] grids), `entities` (placements:
monsterId, screen, x, y, spriteList, optional `difficulty` grades,
`overrides`, `triggers` — messages/hints/changeMusic/heroX-heroY/gravelBoss),
`introText`/`introTextEn`.
- level1: 17 screens, 145 entities, a 156-tile palette, 4 backgrounds; sets
  `brickwork mine-structure facility conveyor mining-rig railway mine-walls
  cargo mine-interior`.
- level2: 9 screens, 38 entities, a 35-tile palette, 3 backgrounds; sets
  `moon-surface machinery facility common mine-interior`. The gravel trial and
  the boss live here, and it ends the original campaign.

### `sprites\*.mset` (32 sets)
- **Hero and weapons**: `hero` (the walk/death/henshin sequences plus the
  health icon), `weapon` (held gun frames, bullets, crosshair),
  `weapon1`–`weapon4` (the pickups).
- **Entities**: `gravel`, `gravel2`, `vinter`, `shoot1`, `betoner`, `barrel`,
  `medic`, `krep`, `platform`, `tank`, `boss1` — referenced by a placement's
  `spriteList`, still spelled `<stem>.mns`.
- **Tile themes**: `brickwork`, `cargo`, `common`, `conveyor`, `facility`,
  `machinery`, `mine-interior`, `mine-structure`, `mine-walls`, `mining-rig`,
  `moon-surface`, `railway` — grouped by subject, not by level, because levels
  share tiles.
- **Backdrops**: `level1-backdrops`, `level2-backdrops` — found by the
  `<assetsDir>-backdrops` convention, never declared in `spriteSets`.
- **Interface**: `ui` — sky, fullmoon, logo, the star sprites, language flags,
  and the `font`/`fontx`/`fonty` atlases.

### `lang/en.json` / `lang/ru.json` (~2–3 KB)
Flat key→string dictionaries for UI and gameplay text (every `S*` key of
`Localization.pas`): tickers, streaks, henshin/bonus, ending screen, the full
menu vocabulary. Level and monster content is NOT here — it is localized in
place in the level and monster JSONs via the base-field + `En`-sibling pattern.

### `sounds/` (18 WAV) and `music/` (OGG)
One-shots load strictly at startup; music loads leniently. Tracks referenced by
data: `moon.ogg` (menu), `moon_surface.ogg`, `underground.ogg`,
`moon_surface2.ogg`, `boss1.ogg`, `hallu.ogg`, `under01.ogg`, `boss2.ogg`,
`win.ogg`.

---

## Quick task-routing table

| Task smells like… | Look at |
| --- | --- |
| Hero movement / collision / jump feel | Hero.pas |
| Weapon patterns / crosshair | Hero.pas (+Bullets.pas) |
| Monster behavior / AI / boss | Monsters.pas + Monsters.Defs.pas + monsters.json |
| New monster (data only) | monsters.json + a `.mset` set (spriteList keeps the `.mns` spelling) |
| Explosions / particles / henshin visuals | Bullets.pas (+dpr henshin cluster) |
| Level content / triggers / screens | levelN.json + Levels.Defs.pas |
| Game flow / state machine / scoring / bonuses / gravel trial | Moon2D.dpr |
| Screen transitions / checkpoints | Moon2D.dpr (HandleScreenTransitions, ArriveOnScreen) |
| Menu / language switching / trailer showcase frames | Menu.pas + Localization.pas |
| Text rendering / new captions | Render.Font.pas + Hud.Messages.pas + lang JSONs |
| Frame pacing / window / vsync | Game.Loop.pas (+Sdl2.Core.pas) |
| Sound / music | Audio.pas (+data fields in JSONs) |
| Tile/background rendering | Render.Tiles.pas + Render.Sprites.pas |
| A sprite name resolves to the wrong picture | Render.Sprites.pas (Get, AmbiguousNames) + the level's `spriteSets` order |
| A monster/hero loads wrong frames from a set | Monsters.pas AnimFor / Hero.pas OpenFrames |
| Sprite sets / the `.mset` format | Sprites.Sets.pas + docs/MSET-FORMAT.md |
| Packing or inspecting sets | tools/SpritePack/* |
| Trailer cards | tools/TitleCard/* |
| PNG loading / image DLL | Sdl2.Image.pas |
