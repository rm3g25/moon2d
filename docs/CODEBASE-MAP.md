# Moon 2D — Codebase Map

Reference document for Claude. Purpose: given this file + a task description,
know which files to request/inspect without re-exploring the repository.

Repo: `https://github.com/rm3g25/moon2d/` · Delphi 12 + SDL2, Win32.
Logic space 512×384 game units (16×12 cells of 32), tile art 64px,
fixed tick 33 Hz, screen-by-screen levels. CODESTYLE-3.6 applies throughout.

Dependency direction (roughly bottom-up):
`Sdl2.Core` → `Render.*` / `Audio` / `Game.Config` / `Localization` →
`Levels.Defs` / `Monsters.Defs` → `Bullets` → `Hero` / `Monsters` /
`Hud.Messages` / `Menu` / `Render.Tiles` → `Game.Loop` → `Moon2D.dpr`.

---

## Game units

### `Sdl2.Core.pas` (~350 lines)
Hand-written SDL2 bindings. No classes — constants, records, `external`
declarations against `SDL2.dll`.
- **Constants**: init flags, window flags, renderer flags, texture access,
  hints (`SdlHintRenderDriver`, scale quality), event type ids, flip flags,
  pixel format `SdlPixelFormatAbgr8888`, blend modes, scancodes used by the game.
- **Records**: `TSdlRect`, `TSdlFRect`, `TSdlPoint`, `TSdlRendererInfo`,
  `TSdlVersion`, `TSdlSurface`, `TSdlKeysym`, `TSdlKeyboardEvent`,
  `TSdlMouseMotionEvent`, `TSdlMouseButtonEvent`, `TSdlEvent` (variant record).
- **Imports**: window/renderer lifecycle, draw calls (`SDL_RenderCopy/F/Ex`,
  fill, clear, present), surfaces + color key + format conversion, textures
  (incl. target textures + `SDL_RenderReadPixels` — used by TitleCard),
  events, timing (`SDL_GetPerformanceCounter/Frequency`, `SDL_Delay`),
  `SDL_SetHint`, `SDL_RenderSetLogicalSize`.
- **Helpers**: `SdlText(string)→UTF8String`, `SdlErrorText`.
- Touch this file when: new SDL function needed, event handling, ABI questions.

### `Render.Sprites.pas` (~345 lines)
Texture cache + low-level sprite drawing. Owns the unit-size constants.
- **Constants**: `SpriteSize=32`, `TileSize=32` (game units!),
  `TileArtSize=64` (texture px!), `FramesAlive=8`, `FramesDeath=8`.
  The 32-vs-64 split is the coordinate-system discipline in code form.
- **`TSpriteCache`** — dictionary `filename → PSdlTexture`, lazy load of PNGs
  from a base dir, optional color key (`SetColorKey`/`DisableColorKey`).
  One cache per asset root (textures\, monsters\, heroes\, weapon\, levels\...).
- **`TAnimSet`** (record) — `Alive[0..7]` + `Death[0..7]` texture arrays;
  `IsLoaded`. Built by free function **`LoadAnimSet(cache, mnsFile)`**
  which parses a `.mns` sprite list.
- **`TSpriteRenderer`** — draws in game units: `DrawCell` (sprite grid),
  `DrawTile` (tile grid), `Draw` (free position, optional mirror),
  `DrawRect`, `DrawRotated` (weapon arm).

### `Sprites.Sets.pas` (~430 lines)
The `.mset` sprite set container: a JSON manifest followed by every image
concatenated behind it. Read by the game, the packer and (later) the level
editor — one unit, three callers. Nothing in the engine calls it yet.
- **Constants**: `MsetVersion=1`. Manifest field names are constants
  (`KeyId`, `KeySprites`, `KeyOffset`…) — a typo in a literal compiles.
- **Records**: `TSpriteEntry` (name, description, offset, size — offset is
  measured from the start of the blob block, not the file), `TSpriteSequence`
  (name, description, frames), `TMsetHeader` (packed: magic, version,
  manifest size), `TMsetMagic` (named type — an anonymous
  `array[0..3] of AnsiChar` will not assign to another one).
- **`TSpriteSet`** — read side. Opening parses the manifest only; image bytes
  arrive on demand via `ReadSprite(name)`. `Contains`, `SequenceFrames`.
- **`TSpriteSetWriter`** — write side. `AddSprite`/`AddSpriteFile`,
  `AddSequence`, `SaveToFile`. Offsets are handed out at save time in add
  order; writing is deterministic, so an unchanged set rebuilds byte for byte.
  Validates duplicate names and sequences pointing at absent frames.
- Format spec: `docs/MSET-FORMAT.md`.

### `Sdl2.Image.pas` (~75 lines)
SDL2_image bindings, delayed imports in the shape of `Audio.pas`.
`IMG_Load_RW` replaced `SDL_LoadBMP_RW` at all four load sites.
`EnsureImageLib` runs at startup and raises plainly if the DLL is absent —
unlike the optional mixer, missing art is fatal.

### `Render.Tiles.pas` (100 lines)
- **`TTileScreenRenderer`** — draws one screen: `DrawScreen` =
  `DrawBackground` (per-screen PNG from `FBackgroundCache`, level dir) +
  `DrawTiles` (palette indices from `TLevel` via `FTileCache`, textures\ dir).
  This background/tiles split is the hook for the future
  "AI backgrounds as art layer" idea.

### `Render.Font.pas` (~345 lines)
Bitmap font, 448px atlas, 16×16 glyph grid (CP1251 layout).
- **Constants**: atlas geometry + verbatim-2008 glyph metrics
  (`SmallGlyphWidth/Height`, `BigGlyphWidth/Height`, `BigAdvanceRatio=0.8`
  — 20% overlap, all derived from NDC math of the original).
- **`TFontAtlasOrientation`** = (`faUpright`, `faRotatedCw`) — the atlas
  orientation fix.
- **`TMoonFont`** — `DrawSmall`, `DrawBig`, `DrawSmallBlock` (multi-line),
  `DrawScaled` (arbitrary glyph height — countdown digits), width measurers
  (`SmallTextWidth`, `BigTextWidth`, `ScaledTextWidth`),
  `DrawAtlas` (debug view, F key).

### `Audio.pas` (~230 lines)
SDL2_mixer bindings (`delayed` imports — game survives a missing DLL) +
sound bank.
- **`TMusicMode`** = (`mmLoop`, `mmOnce`).
- **`TSoundBank`** — dictionary of WAV chunks + one music slot.
  `Load`/`Play` (sounds\), `PlayMusic`/`StopMusic` (music\, OGG),
  `ToggleMusicMuted`, `Enabled` (False if mixer DLL absent → all no-ops).

### `Game.Config.pas` (~225 lines)
- **`TDifficulty`** = (`dfNormal`, `dfHard`, `dfWild`); `TDifficultyGrades`
  set; `DifficultyIds` protocol strings ('normal'/'hard'/'wild').
- **`TLanguage`** = (`lgEnglish`, `lgRussian`); `LanguageIds` ('en'/'ru').
- **`TGameConfig`** (record) — window w/h, fullscreen, vsync, fpsCap,
  tickRate, difficulty, language; `Defaults` factory.
- Free functions: `LoadGameConfig`, `SaveGameDifficulty`, `SaveGameLanguage`
  (partial rewrites of config.json).

### `Localization.pas` (~310 lines)
- **`TLocalizedText`** (record) — `Values[TLanguage]`, `Current`.
  Used for level/monster content (base JSON field = RU, `En` sibling = EN,
  absent sibling falls back).
- ~60 `S*` string-key constants (protocol ids into lang dictionaries):
  gameplay tickers, streak captions, henshin/bonus texts, ending screen,
  full menu vocabulary.
- Free functions: `LoadLanguage` (swaps the flat dictionary from
  lang\en.json / ru.json), `Tr(key)`, `CurrentLanguage`,
  `ReadLocalizedText(jsonObj, key)`, `MakeLocalizedText`.

### `Levels.Defs.pas` (~390 lines)
Level data model + JSON parser. No game logic.
- **`TEntityOverrides`** (record) — optional per-placement direction, speed,
  lives, canShoot (Has* flag + value pairs).
- **`TDifficultyValue`** (record) — one int per grade; JSON = number or
  `{"normal":..,"hard":..,"wild":..}`; `Uniform`, `ForGrade`.
- **`TEntityTriggers`** (record) — `BigMessage`/`SmallMessage`/`HintText`
  (localized), `ChangeMusic`, heroX/heroY reposition (vertical transitions),
  gravel trial quota (`HasGravelBoss` + `GravelQuota: TDifficultyValue`).
- **`TEntityPlacement`** (record) — monsterId, screen (1-based), x/y
  (sprite grid), spriteList (.mns), `Grades` (Doom skill-flag idiom),
  overrides, triggers.
- **`TBackgroundChange`** (record) — fromScreen + image.
- **`TLevel`** (class) — parsed level: tiles `[screen][row][col]`,
  collision strings `[screen][row]` ('1' = solid), tile palette,
  backgrounds, entities, id/title/assetsDir/music/introText, grid dims,
  screenCount. Queries: `TileAt`, `SolidAt`, `BackgroundFor` (last change
  wins). `LoadFromFile`.

### `Monsters.Defs.pas` (~440 lines)
Monster definition model + registry (parses monsters.json). No behavior.
- **Enums**: `TMonsterCategory` (mcEnemy/Pickup/Prop/Boss),
  `TMovementKind` (mkStatic/Patrol/PatrolNoEdgeCheck/ChaseHero/BossFly),
  `TAttackPattern` (apNone/StraightSingle/StraightCluster5/AimedSingle/
  AimedDouble/RainVolley), `TPickupEffectKind` (peNone/Heal/GiveWeapon).
- **Records**: `TMovementDef` (kind+speed); `TAttackDef` (pattern, fire
  cadence, bullet speed, pattern-specific params, `HasAttack`);
  `TPickupEffectDef` (peGiveWeapon rewires the whole weapon: type,
  cooldown, speed, gravity); `TSpawnEntry` (monsterId+weight);
  `TBossDef` (endsLevelOnDeath, spawn cadence/screen/table, `RageMusic`,
  `PickSpawn` weighted random);
  `TMonsterDef` — the full sheet: id, legacyName, displayName (localized),
  spriteList, category, dangerous, affectedByGravity, explodesOnDeath,
  movement, attack, pickupEffect, lives, score, animFreq, deathText
  (localized), deathSounds array, boss.
- **`TMonsterRegistry`** (class) — owns all defs; `LoadFromFile/String`,
  `Find`, `FindByLegacyName`, `TryFind`, `Count`, `AllDefs`
  (sound-bank warmup), spawn-table validation.

### `Bullets.pas` (~300 lines)
Projectiles + all the 2008 particle-hack spawners.
- **`TFanShape`** (record) — rows/cols/baseSpeed/speedSpread of the k/t fan
  formula (the travel-test record: same template, five wearers).
- **`TBulletStatus`** = (`bsFlying`, `bsBursting`, `bsInactive`).
- **`TBullet`** — position, velocity, gravity ('dyy'), burst animation
  frame, `Contact` (participates in bullet-vs-bullet interception).
  `Move`, `StartBurst`, `StartBurstSliding` (wall hit keeps 1/8 inertia).
- **`TBurst`** — owns a bullet list + its textures ('bullet' = hero,
  'bull' = monsters; flight frame + destruction frames 2..8).
  `NewBullet`, `Clear` (screen transitions wipe bullets), `Update`, `Draw`.
  Spawners, all verbatim 2008: `SpawnExplosionFan` (180-fragment barrel/
  chain-reaction fan), `SpawnFan(shape)` (henshin finale / ice shatter /
  boss victory), `SpawnConvergingRing` (henshin healing waves; Contact=True,
  ring wounds the boss), `SpawnFireRain` (768 slow bullets on 16-unit grid),
  `SpawnStaticAura` (500 motionless bullets = the 2008 shield hack).
- Known wart: `TBurst.Draw` mutates simulation state (refactoring.md #14,
  blocks interpolation #19).

### `Hero.pas` (~1150 lines)
The hero: physics, weapons, death. Owns `GameWidth=512`, `GameHeight=384`,
`HeroSize=32`.
- **Enums**: `THeroAction` (stand/walk/jump/fall × direction),
  `THeroCommand` (go/stop left/right, jump/stopJump),
  `THeroForm` (hfNormal/hfIce), `TPendingSide` ('ExtraInstruction' of 2008 —
  queued side intent executed when the barrier clears).
- **`THero`** —
  - State: FX/FY (Y = FEET line), screen, action, direction, walk frame,
    acceleration, form, death fields (frame 9→16, corpse settling).
  - Collision oracles (verbatim 2008): `Solid`, `CellOfX/Y`, `CellsOfX/Y`
    (32-unit span straddling two cells), `CanIGoLeft/Right/Up/Down`,
    `CanIFlyLeft/Right`, `WallBlocksLeft/Right` (side-effect-free probes
    for shoves), `GroundUnderFeet`, `LandExactly`, `SettleOnGround`.
  - Weapon: `FBullets: TBurst`, type 0..4 (pistol/shotgun×5/grenade
    cloud×22/chain×3/minigun with alternating side shots), cooldown/speed/
    gravity state, `Fire: Boolean` (True = shot left the barrel → caller
    plays sound), `SetWeaponAngle`, `DrawWeapon`, crosshair (`DrawCrosshair`
    frames 1..4 = smart cursor colors), minigun muzzle live-tuner
    (`NudgeMinigun`, DEBUGKEYS).
  - Lifecycle: `Command`, `Tick` (verbatim OurHero.Timer), `Draw`,
    `SetMouse`, `PlaceAtCell`, `SetScreenX`, `SetY`, `ShoveX` (unit-by-unit,
    stops at walls), `ApplyWeaponPickup`, `Kill`, `Revive`.

### `Monsters.pas` (~840 lines)
Monster behavior (data-driven off `TMonsterDef`) + the field managing them.
- **Enums**: `TMonsterAction` (stand/walk/fall/fly×4),
  `TMonsterLife` (mlAlive/Dying/Dead),
  `TMonsterEvent` (meNone/BossWantsMinion/Henshin/BossRage/LevelComplete/
  Died) — 'MessageToMain' of 2008, drained by the game loop each tick.
- **`TMonster`** — position, screen, direction, lives (+`LivesAll`),
  anim frame, step, fire timer, enrage flag, boss minion timer, event list.
  Own collision oracles (`CanGoLeftEdgeAware`/`WallOnly` pairs = CanIGo*1/2
  of 2008, `CanGoDown`), `ShoveX`. Movement: `MoveWalking`/`Falling`/
  `Flying`, `PatrolStep`. Combat: `FireAt` (patterns from `TAttackDef`),
  `TakeDamage` (knockback through wall oracle + explosion fans + events),
  `EnrageTankIfLow`, `ProcessBossThresholds`, `BeginDying`.
  Public: `Tick(heroX, heroY, bullets)`, `Draw`, `DrainEvent`.
- **`TMonsterField`** — owns `TObjectList<TMonster>`, animset cache
  (.mns → `TAnimSet`), monsters\ sprite cache, `FLivesScale` (difficulty
  multiplier applied to every monster born here). `Tick` (current screen),
  `SpawnFromSky` (boss minions at random top cell), `AnyAliveOnScreen`
  (the breakthrough gate — pickups count, verbatim), `Draw`.

### `Hud.Messages.pas` (~310 lines)
- **`TMessageBoard`** — the 2008 message system: ticker lines (slide-in,
  private `TTickerLine` record), big mid-screen headline, marquee
  ('Бегущая строка'), score popups (private `TScorePopup`, '+N' rising).
  `Tick` / `Draw(alpha)` — draw is interpolation-aware (marquee, popups).
  API: `AddTicker`, `ShowBig`, `StartMarquee`, `AddScorePopup`,
  `ClearPopups` (screen transitions strand popups), `Clear` (death silences).

### `Menu.pas` (~875 lines)
Main menu with the flying moon/starfield.
- **Records**: `TLevelChoice` (fileName + localized title; discovery done
  by composition root), `TMenuResult` (command + payload), `TMenuItem`,
  `TStar` (verbatim TStar of MenuPic.pas: kind 0..7 = speed class AND
  sprite index; texture resolved once at init), `TMoonDrift` (the drifting
  moon in the 2008 "sdvig" ±500 space; `Respawn`, `Tick`).
- **Enums**: `TMenuCommand` (mcNone/StartLevel/Resume/ToggleFullscreen/
  SetDifficulty/SetLanguage/Quit), `TMenuScreen` (msMain/LevelSelect/
  Difficulty/Credits/QuitConfirm), `TItemAction` (internal navigation vs
  surfaced commands).
- **`TMoonMenu`** — sky/moon/logo textures, stars, item list per screen,
  language flags (owned textures, `FlagRect` = draw AND hit-test geometry),
  difficulty display copy. `ShowMain`, `Tick`, `Draw(alpha)`,
  `DrawSky(alpha)` (story screen reuses the live sky as scenery),
  `MouseMove`, `Click → TMenuResult`, `HandleEscape` (True = consumed).
  Properties `HasActiveGame`, `Difficulty`, `Language` (setter rebuilds
  captions via `Tr` — set AFTER the dictionary swap).

### `Game.Loop.pas` (~390 lines)
Host: window/renderer + fixed-timestep loop.
- **`TGameApp`** (abstract) — `Update(dt)` (fixed), `Render(renderer,
  alpha)` (alpha = interpolation fraction), `HandleKey/MouseMove/
  MouseButton`, `RequestQuit`.
- **`TGameHost`** — creates window+renderer (D3D11 hint lives here),
  `Run(app)`: event pump, fixed 33 Hz accumulator, fps title with
  worst-frame diagnostics, frame-budget wait for the no-vsync path.
  `TKeyAction` = (kaDown, kaUp).

### `Moon2D.dpr` (~1800 lines — NOT a stub, always grep it too)
Composition root + the whole game-flow state machine (`TMoonGame`).
- **Top constants**: asset dir names, ticker durations, henshin wave
  schedule (`HenshinWaves[0..4]`: tick/bullets/radius), flash/finish ticks,
  ending-screen layout rows, countdown tuning (3..2..1 prelude — a 2026
  authorial addition).
- **Types**: `TGameState` (gsMenu/gsIntro/gsPlaying/gsEnding),
  `THenshinWave` (record), `TBonusKind` (bkNone/Health/FireRain/Aura/
  Explosion).
- **`TMoonGame`** (extends `TGameApp`) — owns everything: registry, level,
  caches, sprite/tile renderers, hero, monster field, both bursts, font,
  message board, sound bank, menu. Key state: game state + resume state,
  held-key flags (2008 polled-keyboard model), health + hurt cooldown,
  checkpoint X/Y, score + kill streak, per-entity trigger-fired flags,
  henshin (active/tick) + countdown (digit/tick/handover), bonus slot
  (+ queued activation), gravel trial (attack flag, quota, wave timer,
  screen), end-level timer, level list + current file + current music,
  fullscreen/difficulty.
  Method clusters:
  - Flow: `Update`, `Render`, `LoadLevel`, `StartPlaying`, `RestartLevel`,
    `AdvanceToNextLevel`, `CurrentLevelIsLast`, `BeginEnding`,
    `OpenMenu`, `ApplyMenuResult`, `ToggleFullscreen`.
  - World: `HandleScreenTransitions`, `ArriveOnScreen`, `HandlePitFall`,
    `FireScreenTriggers`, `TickGravelAttack`.
  - Combat: `ResolveHeroBulletHits`, `ResolveMonsterBulletHits`,
    `ResolveMonsterContact`, `RewardMonsterKill`, `HurtHero`,
    `DrainMonsterEvents`, `ProcessKillStreak`, `AwardStreakBonus`.
  - Henshin/bonus: `StartHenshinCountdown`/`TickCountdown`/`DrawCountdown`,
    `StartHenshin`/`TickHenshin`/`FinishHenshin`, `RemoveIceForm`,
    `CureHero`, `AwardRandomBonus`, `ActivateQueuedBonus`, `DrawBonusHud`.
  - Drawing/input: `DrawHud`, `DrawIntro`, `DrawEnding`, `DrawMessages`,
    `CrosshairFrame`, `HandleKey/MouseMove/MouseButton`,
    `HandleEndingClick`, debug tuners (`NudgeCrosshair`,
    `NudgeMinigunMuzzle`, `DebugBrowseScreen`).
- **Free functions**: `OpenWebPage`, `BonusDisplayName`, bullet cell/
  off-screen helpers, `ReadLevelTitle`, `DiscoverLevels`, `RunGame`
  (the actual main: config → host → registry → game).

---

## Tools

### `tools/TitleCard/` — trailer text-card generator (VCL app)
Renders arbitrary text in the game's bitmap font to PNG. Reuses
`Sdl2.Core` + `Render.Font` by relative path.
- **`TitleCard.dpr`** — VCL bootstrap.
- **`TitleCard.Layout.pas`** — pure layout math. Constants: measured font
  ink metrics (`InkTopRatio`, `CapHeightRatio`). Records: `TCardGeometry`
  (size, margins, optical center 0.45, line spacing), `TCardScale`
  (smFitInteger/FitFree/Explicit + factories), `TPlacedLine`, `TCardLayout`
  (cellHeight, lines, charLimit, overflow queries). Functions:
  `BuildCardLayout`, `WrapCardText` (emergency word-wrap), `SplitCards`
  (batch file on blank lines), geometry helpers.
- **`TitleCard.Renderer.pas`** — **`TCardRenderer`**: hidden SDL window +
  target texture, renders a layout, `RenderCard → TBytes` (RGBA top-down)
  via `SDL_RenderReadPixels`. `TCardBackground` = (cbTransparent, cbBlack).
- **`TitleCard.Config.pas`** — **`TTitleCardConfig`** record (atlas path,
  render driver, geometry, scale steps, batch pattern), JSON load.
- **`TitleCard.Main.pas`** — **`TMainForm`** (VCL): memo + combos for
  aspect/scale/margins, live preview, single save + batch render.
- **`Image.Png.pas`** — `SavePngRgba` free function, hand-rolled PNG writer.

### `tools/SpritePack/` — sprite set packer (console app)
Builds and inspects `.mset` files. Wraps `Sprites.Sets` and nothing else.
- **`SpritePackCli.dpr`** — commands `pack` / `list` / `unpack`. `pack` takes
  every PNG in a folder in natural order (2 before 10); `--list` splits a
  2008 sprite list into named sequences by its length (16 lines →
  alive+death, 24 → walk+death+henshin, else one group). `unpack` writes the
  images plus `manifest.json`, so a set can always be taken apart.
- **`pack-sets.ps1`** — builds all 29 sets in one run and holds the tile
  theme tables: first matching pattern claims a name, leftovers are packed
  separately and reported. Tiles are staged through a scratch folder because
  the game still reads the loose images where they are.
- A VCL half (`SpritePack.exe`, sprite/description editing) is planned; the
  logic stays in `Sprites.Sets` so both executables are thin.

---

## JSON data (bin\)

### `config.json` (tiny)
`window` (width/height/fullscreen/vsync/fpsCap) + `game` (tickRate,
difficulty id, language id). Read by `Game.Config`; difficulty and
language are saved back individually.

### `monsters.json` (~11 KB)
Keys: `version`, `comment`, `defaults` (bound, spritesToDeath, animFreq,
score, dangerous — inherited by monsters), `monsters` array.
15 ids: `gravel`, `gravelFemale`, `winter`, `zombieShooter`, `betoner`,
`platform`, `tank`, `mount`, `barrel`, `medkit`, `weaponShotgun`,
`weaponGrenade`, `weapon3`, `weapon4`, `boss1`.
Parsed by `TMonsterRegistry` into `TMonsterDef` (see Monsters.Defs above
for the full field sheet: movement/attack/pickup/boss blocks, localized
displayName/deathText, deathSounds).

### `level1.json` (~49 KB) / `level2.json` (~19 KB)
Unified level format, parsed by `TLevel`. Keys: `version`, `id`,
`title`/`titleEn`, `assetsDir`, `music`, `legacyTrailing` (migration
artifact, cleanup pending), `grid` (16×12), `backgrounds` (fromScreen +
image), `tilePalette` (texture names; index N in tiles → palette[N-1]),
`tiles` (`encoding`, `emptyValue`, `screens` array of [row][col] grids),
`entities` (placements: monsterId, screen, x, y, spriteList, optional
`difficulty` grades, `overrides`, `triggers` — messages/hints/changeMusic/
heroX-heroY/gravelBoss), `introText`/`introTextEn`.
- level1: 17 screens, 145 entities, 156-tile palette, 4 backgrounds.
- level2: 9 screens, 38 entities, 35-tile palette, 3 backgrounds
  (gravel trial + boss live here; ends the original campaign).

### `lang/en.json` / `lang/ru.json` (~2–3 KB)
Flat key→string dictionaries for UI/gameplay text (all `S*` keys of
`Localization.pas`): tickers, streaks, henshin/bonus, ending screen,
full menu vocabulary. Level/monster content is NOT here — it is localized
in-place in level/monster JSONs via the base-field + `En`-sibling pattern.

---

## Quick task-routing table

| Task smells like… | Look at |
| --- | --- |
| Hero movement / collision / jump feel | Hero.pas |
| Weapon patterns / crosshair | Hero.pas (+Bullets.pas) |
| Monster behavior / AI / boss | Monsters.pas + Monsters.Defs.pas + monsters.json |
| New monster (data only) | monsters.json (+.mns asset) |
| Explosions / particles / henshin visuals | Bullets.pas (+dpr henshin cluster) |
| Level content / triggers / screens | levelN.json + Levels.Defs.pas |
| Game flow / state machine / scoring / bonuses / gravel trial | Moon2D.dpr |
| Screen transitions / checkpoints | Moon2D.dpr (HandleScreenTransitions, ArriveOnScreen) |
| Menu / language switching | Menu.pas + Localization.pas |
| Text rendering / new captions | Render.Font.pas + Hud.Messages.pas + lang JSONs |
| Frame pacing / window / vsync | Game.Loop.pas (+Sdl2.Core.pas) |
| Sound / music | Audio.pas (+data fields in JSONs) |
| Tile/background rendering | Render.Tiles.pas + Render.Sprites.pas |
| Trailer cards | tools/TitleCard/* |
| Sprite sets / .mset format | Sprites.Sets.pas + docs/MSET-FORMAT.md |
| Packing or inspecting sets | tools/SpritePack/* |
| PNG loading / image DLL | Sdl2.Image.pas |
