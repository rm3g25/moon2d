{
  Moon2D - entry point of the remake.

  One process, one window, states instead of the 2008 launcher+game pair.
  The game boots into the menu (moon over a starfield, Menu), levels
  load from there; Escape returns to the menu, Alt/Ctrl+Enter toggles
  fullscreen anywhere. In game: WASD/arrows move, Space/W jumps, the arm
  tracks the mouse. PgUp/PgDn browse screens for debugging.

  Logic runs in the original 512x384 game units (SetMaxC of 2008);
  SDL logical size matches, so mouse events arrive already in game units.
}
program Moon2D;

{$APPTYPE GUI}
{$DEFINE DEBUGKEYS} // PgUp/PgDn browse, T inspector, F atlas, M mute,
                    // numpad tuners. Comment out for release builds.

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Sdl2.Core in 'Sdl2.Core.pas',
  Game.Config in 'Game.Config.pas',
  Game.Loop in 'Game.Loop.pas',
  Monsters.Defs in 'Monsters.Defs.pas',
  Render.Sprites in 'Render.Sprites.pas',
  Levels.Defs in 'Levels.Defs.pas',
  Render.Tiles in 'Render.Tiles.pas',
  Hero in 'Hero.pas',
  Bullets in 'Bullets.pas',
  Monsters in 'Monsters.pas',
  Render.Font in 'Render.Font.pas',
  Hud.Messages in 'Hud.Messages.pas',
  Audio in 'Audio.pas',
  Localization in 'Localization.pas',
  Menu in 'Menu.pas';

const
  // Levels are discovered by this pattern at startup; the menu lists
  // whatever is on disk, all selectable. Deliberate: a showcase build
  // gates nothing - the 2008 unlock file (levels/default.txt) is
  // retired, not postponed.
  LevelFilePattern = 'level%d.json';
  MaxLevelSlots = 99;
  // Read at startup and written back by the difficulty click - the 2008
  // menu saved startcfg.txt the same way (1448)
  ConfigFileName = 'config.json';
  AuthorLinkedInUrl = 'https://www.linkedin.com/in/kusmin-ilia/';
  TexturesDir = 'textures';
  LevelsDir = 'levels';
  HeroSkinFile = 'heroes\default.txt';
  WeaponListFile = 'weapon\default.txt';
  FontFileName = 'fonty.bmp';

  SoundsDir = 'sounds';
  MusicDir = 'music';
  // Verbatim weapon->shot map of moon.dpr 1813-1817, including the
  // quirk of weapon 3 borrowing the pistol bark
  WeaponShotSounds: array [0..4] of string =
    ('shoot.wav', 'shootgun.wav', 'granade.wav', 'shoot.wav', 'shoot2.wav');
  PainSoundFile = 'pain.wav';         // hero hit (moon.dpr 751/984)
  PitSoundFile = 'down.wav';          // fell into a pit (780)
  HenshinSoundFile = 'evolution.wav'; // the transformation sting (878/966)
  // The waves ring platform.wav; bottle.wav is the barrel burst that
  // doubles as the henshin flash (498) and the bonus explosion (592)
  HenshinWaveSoundFile = 'platform.wav';
  BottleSoundFile = 'bottle.wav';
  // Synthesized tick for the countdown - see PORTING-NOTES for why this
  // one is code-generated instead of downloaded
  CountdownBeepFile = 'countdown.wav';
  BonusSoundFile = 'bonus.wav'; // the roulette fanfare (1829)

  // The bonus roulette of moon.dpr 531-543: every 50 points buys one
  // random reward, held until the right mouse button spends it
  BonusCost = 50;
  BonusHudStartCol = -35.0; // the caption crawls in from off-screen...
  BonusHudTargetCol = 1.0;  // ...to column 1 at 0.1 col/tick (315-319)
  BonusHudSlideStep = 0.1;
  BonusHudTopRow = 37;      // two small lines at the screen bottom
  // Victory sting on boss death; the walk-out timer below carries the
  // hero into the next level while it plays
  VictoryMusicFile = 'win.ogg';
  // 'ToEndLev := 400' of the boss handler (moon.dpr 949): the level is
  // won, the hero lingers this many ticks over the wreckage - about
  // twelve seconds at the real 33 Hz - then the campaign moves on
  LevelEndLingerTicks = 400;
  // 'Обычная'/'Сложная'/'Дикая' of 2008: hero hearts at level start
  // (moon.dpr 1714-1716) and the monster-lives multiplier handed to
  // FindMostersOnScreen (1092-1094). AddGravel(0/1/3) joins in the
  // gravel-trial chapter.
  DifficultyHeroHealth: array [TDifficulty] of Integer = (5, 4, 2);
  DifficultyMonsterLives: array [TDifficulty] of Double = (1.0, 1.5, 2.0);
  // The gravel trial ('Атака грейвелов', moon.dpr 955-971 / GravAttack
  // 371-408): first wave 25 ticks after the trigger, then every 18.
  // FEMALES on purpose: patrolNoEdgeCheck walks off ledges, so they
  // descend and besiege the hero - edge-checked males would idle on the
  // top platforms. Author's call by live behavior.
  GravelMonsterId = 'gravelFemale';
  GravelFirstWaveTicks = 25;
  GravelWaveTicks = 18;
  // The main-menu track (StartingPhase, moon.dpr 1857). Played at boot;
  // opening the menu MID-game leaves the level music running - verbatim
  MenuMusicFile = 'moon.ogg';

  // Message display times in logic ticks, verbatim moon.dpr call sites:
  TickerNoticeTicks = 125;   // 'Вас задело пулей' (752), 'Вы ранены
                             // монстром' (985), small trigger captions
  TickerPitTicks = 170;      // 'Вы упали в лунку' (781)
  // deathText times live in monst.pas, not yet on hand -
  // TODO: verify against monst.pas (tracked: part 2 review)
  TickerDeathTextTicks = 125;
  BigMessageTicks = 100;     // bonuses, EVOLUTION, boss break (passim)
  BigTitleTicks = 200;       // level title splash (1682)
  TickerStreakTicks = 200;   // kill-streak bonus captions (837/849/860)
  HenshinRegenTicks = 100;   // 'регенерировала здоровье +1' (457 et al.)
  HenshinPerkTicks = 300;    // 'ICE FORM: прыжок +25%' (501)

  // Damage bookkeeping, values verbatim 2008:
  HurtMercyTicks = 50;      // 'permission': mercy window after any hit
  GameOverDelayTicks = 125; // 'ToGameOverTime': d-frames before restart
  PitDepthY = 450;          // 'Падаем в лунку' below this Y
  // The 2008 GL loader displayed a 90-degrees-clockwise atlas correctly
  // (see Render.Font header). If F shows readable glyphs already upright,
  // switch to faUpright - or point FontFileName at the other font file.
  FontOrientation = faRotatedCw;

  // Scancodes beyond Sdl2.Core's basic set
  ScancodeA = 4;
  ScancodeD = 7;
  ScancodeF = 9;  // debug: raw font atlas view (orientation check)
  ScancodeM = 16; // debug: music mute toggle (trailer capture)
  ScancodeT = 23; // debug: tile inspector in the window title
  ScancodeW = 26;
  ScancodePageUp = 75; // debug: browse screens
  ScancodePageDown = 78;
  // Debug tuners on the numpad; per-key semantics live at the HandleKey
  // call sites - the minigun muzzle on the arrow cluster (4/6/8/2, +/-),
  // the retired crosshair calibrator on the corners (7/9/1/3)
  ScancodeKp1 = 89;
  ScancodeKp2 = 90;
  ScancodeKp3 = 91;
  ScancodeKp4 = 92;
  ScancodeKp6 = 94;
  ScancodeKp7 = 95;
  ScancodeKp8 = 96;
  ScancodeKp9 = 97;
  ScancodeKpMinus = 86;
  ScancodeKpPlus = 87;

// Every player-facing string lives in lang\*.json now (part 6): the
// S-keys moved to Localization, call sites fetch them through Tr().
resourcestring
  // Developer-facing startup error - may fire before any dictionary
  // is loaded, hence English and outside the localization system
  SNoLevelsFound = 'No levels found (level1.json onward)';

type
  // gsMenu: the moon-over-starfield menu (Menu) - the boot state.
  // gsIntro: the level's story text waits for a key.
  // gsEnding: the campaign-end screen - mouse-only exit (part 5.4).
  TGameState = (gsMenu, gsIntro, gsPlaying, gsEnding);

  // One healing wave of the transformation cinematic
  THenshinWave = record
    AtTick: Integer;
    Bullets: Integer;
    RadiusX: Integer;
  end;

  // The four rewards of bonus.pas. bkNone doubles as 'slot is empty';
  // the roulette picks uniformly from the four real ones - the exact
  // index order of the 2008 BonusName[] array is irrelevant for that.
  TBonusKind = (bkNone, bkHealth, bkFireRain, bkAura, bkExplosion);

const
  // The five converging waves of moon.dpr 453-497: the ring tightens
  // (40 -> 5) while the fragment count grows (50 -> 100) - the ice
  // closing in on the hero. Each wave heals +1 and rings platform.wav.
  HenshinWaves: array [0..4] of THenshinWave = (
    (AtTick: 20; Bullets: 50; RadiusX: 40),
    (AtTick: 40; Bullets: 60; RadiusX: 30),
    (AtTick: 60; Bullets: 70; RadiusX: 20),
    (AtTick: 80; Bullets: 80; RadiusX: 10),
    (AtTick: 100; Bullets: 100; RadiusX: 5));
  HenshinFlashTick = 135;  // bottle.wav teaser before the finale (498)
  HenshinFinishTick = 140; // the suit goes on (499-513)

  // Campaign-end screen layout, in Render.Font grid steps
  EndingTextColumn = 3;    // farewell prose column (small font)
  EndingTextFirstRow = 7;  // first prose row (small line steps)
  EndingAuthorRow = 14;    // clickable big lines, centered
  EndingMenuRow = 17;
  EndingClickRows = 2;     // click band height of a big line

  // Pre-henshin countdown (author's 2026 addition, not in the original):
  // 3..2..1 in screen center telegraphs the ceremony - one second of
  // logic per digit, three seconds to run INTO the monster crowd (ring
  // fragments are live hero bullets, positioning is a damage buff)
  CountdownStartValue = 3;
  CountdownTicksPerDigit = 33;      // = one second at tickRate 33
  CountdownFadeStartRatio = 0.6;    // opaque for 60%, dissolves over 40%
  CountdownMinGlyphHeight = 24.0;   // birth size, game units
  CountdownMaxGlyphHeight = 132.0;  // size at the moment it dies
  CountdownCenterY = 168.0;         // above true center: clears hero/HUD

type
  TMoonGame = class(TGameApp)
  private
    FMonsters: TMonsterRegistry;
    FLevel: TLevel;
    FTileCache: TSpriteCache;
    FBackgroundCache: TSpriteCache;
    FSprites: TSpriteRenderer;
    FTiles: TTileScreenRenderer;
    FHero: THero;
    FState: TGameState;
    // Original input model: keyboard.pas kept a Key[] state array and the
    // timer POLLED it - commands fired every tick while held. That is what
    // let the hero grab a ledge mid-jump: the held key kept knocking until
    // CanIFly* opened. Reproduced with these flags.
    FHeldLeft, FHeldRight, FHeldJump, FHeldFire: Boolean;
    FMonsterBullets: TBurst; // the shared enemy burst
    FField: TMonsterField;
    FHeroHealth: Integer;
    FHurtCooldown: Integer;  // brief mercy window after a hit
    // Checkpoint ('StartHeroX/Y' of 2008): the entry point of the
    // CURRENT screen - updated on every screen transition and, later,
    // by heroX/heroY triggers. Pits and death return here, which is
    // guaranteed walkable: the hero has just stood there.
    FCheckpointX, FCheckpointY: Double;
    FGameOverTimer: Integer; // ticks left of the death pause
    FHudCache: TSpriteCache; // health icons (heroes\health.bmp of 2008)
    FRenderer: PSdlRenderer; // kept for level restarts
    FInspect: Boolean; // T: show tile name under cursor in the title
    FMouseGX, FMouseGY: Integer;
    FWindow: PSdlWindow;
    FFont: TMoonFont;
    FMessages: TMessageBoard;
    FScore: Integer;
    // Kill-streak achievement of 2008 (moon.dpr 826-864): kills without
    // the hero taking ANY damage; any hit resets the count to zero.
    FKillStreak: Integer;
    FStreakBonusCount: Integer;
    // Entity triggers fire once per game (tutorial hints must not nag);
    // indexed in step with FLevel.Entities.
    FTriggerFired: TArray<Boolean>;
    FShowAtlas: Boolean; // F: raw font atlas (orientation check)
    FAudio: TSoundBank; // silent when SDL2_mixer.dll is absent
    // The transformation cinematic ('Henshin'/'HenshinTime' of 2008):
    // a tick counter walks the wave schedule while the game keeps running
    FHenshinActive: Boolean;
    FHenshinTick: Integer;
    // The 3..2..1 prelude; 0 = idle. Carries the AtTick for the
    // cinematic it hands over to when the last digit dissolves.
    FCountdownDigit: Integer;
    FCountdownTick: Integer;
    FCountdownHenshinAtTick: Integer;
    // The bonus slot: one reward at a time, spent by right click.
    // The HUD caption position lives here because it belongs to the
    // slot's lifetime, not to the drawing code.
    FBonus: TBonusKind;
    FBonusHudCol: Double;
    FBonusActivateQueued: Boolean; // right click lands between ticks
    FMenu: TMoonMenu;
    FLevelLoaded: Boolean;      // 'StartGame' of 2008
    FResumeState: TGameState;   // where Escape-to-menu came from
    FHeldCtrl: Boolean;         // for the fullscreen chord
    FHeldAlt: Boolean;          // Alt+Enter - the industry-standard chord
    FFullscreen: Boolean;
    FDifficulty: TDifficulty;
    // 'GravelAttack' of 2008 (moon.dpr 136): while the trial runs, the
    // right edge is a wall (1072) - the fight cannot be skipped by
    // walking out. The gravel chapter raises it; the block and the
    // resets are ported now.
    FGravelAttack: Boolean;
    FGravelLeft: Integer;    // 'GravelLeft': wave quota, may run negative
    FToNextGravel: Integer;  // 'ToNextGravel': ticks to the next wave
    FGravelScreen: Integer;  // where the trial rages - spawns pin here
    // 'EndLev'/'ToEndLev' of 2008 (525-528): the boss is dead, the
    // victory track plays, and this many ticks later the next level
    // loads. 0 = idle.
    FEndLevelTimer: Integer;
    FLevels: TArray<TLevelChoice>; // the discovered campaign, in order
    FLevelFile: string;            // which of FLevels is loaded now
    // The track a restart must bring back: the level default or the
    // last changeMusic trigger - NOT the boss rage and NOT the victory
    // sting (triggers fire once and will not replay after a death)
    FCurrentMusic: string;
    procedure HandleScreenTransitions;
    procedure HandlePitFall;
    procedure ArriveOnScreen;
    procedure ResolveHeroBulletHits;
    procedure ResolveMonsterBulletHits;
    procedure ResolveMonsterContact;
    procedure RewardMonsterKill(const AMonster: TMonster);
    procedure DrainMonsterEvents;
    procedure HurtHero;
    procedure RestartLevel;
    procedure DrawHud(const ARenderer: PSdlRenderer);
    function CrosshairFrame: Integer;
    procedure NudgeCrosshair(ADX, ADY: Integer);
    procedure NudgeMinigunMuzzle(ADX, ADY, ADLen: Integer);
    procedure DebugBrowseScreen(ADelta: Integer);
    function HitEndingLine(const AText: string; ATopRow: Integer): Boolean;
    procedure FireScreenTriggers;
    procedure TickGravelAttack;
    function CurrentLevelIsLast: Boolean;
    procedure BeginEnding;
    procedure DrawEnding;
    procedure DrawCenteredBig(const AText: string; ARow: Integer);
    procedure HandleEndingClick;
    procedure ProcessKillStreak;
    procedure AwardStreakBonus(const ABig, ASmall: string; APoints: Integer);
    procedure StartPlaying;
    procedure PreloadSounds;
    // AAtTick 0 = the boss path; 30 skips the first wave - the gravel
    // trial of level 2 starts mid-sequence (moon.dpr 969), wired later
    procedure StartHenshinCountdown(AAtTick: Integer);
    procedure TickCountdown;
    procedure DrawCountdown(AAlpha: Double);
    procedure StartHenshin(AAtTick: Integer);
    procedure TickHenshin;
    procedure FinishHenshin;
    procedure RemoveIceForm;
    procedure CureHero;
    procedure AwardRandomBonus;
    procedure ActivateQueuedBonus;
    procedure DrawBonusHud(AAlpha: Double);
    procedure DrawMessages(AAlpha: Double);
    procedure DrawIntro;
    procedure LoadLevel(const AFileName: string);
    procedure AdvanceToNextLevel;
    procedure OpenMenu;
    procedure ApplyMenuResult(const AResult: TMenuResult);
    procedure ToggleFullscreen;
  public
    constructor Create(const AMonsters: TMonsterRegistry;
      const ARenderer: PSdlRenderer; const AWindow: PSdlWindow;
      const ALevels: TArray<TLevelChoice>; AStartFullscreen: Boolean;
      AStartDifficulty: TDifficulty);
    destructor Destroy; override;
    procedure Update(ADeltaSeconds: Double); override;
    procedure Render(ARenderer: PSdlRenderer; AAlpha: Double); override;
    procedure HandleKey(AScancode: Integer; AAction: TKeyAction;
      AIsRepeat: Boolean); override;
    procedure HandleMouseMove(AX, AY: Integer); override;
    procedure HandleMouseButton(AButton: Integer; ADown: Boolean); override;
  end;

constructor TMoonGame.Create(const AMonsters: TMonsterRegistry;
  const ARenderer: PSdlRenderer; const AWindow: PSdlWindow;
  const ALevels: TArray<TLevelChoice>; AStartFullscreen: Boolean;
  AStartDifficulty: TDifficulty);
begin
  inherited Create;
  FMonsters := AMonsters;
  FWindow := AWindow;
  FRenderer := ARenderer;
  FFullscreen := AStartFullscreen;
  FLevels := ALevels;
  FDifficulty := AStartDifficulty;

  // Level-independent subsystems live for the whole process; everything
  // bound to a particular level is born inside LoadLevel.
  FTileCache := TSpriteCache.Create(ARenderer, TexturesDir);
  FSprites := TSpriteRenderer.Create(ARenderer, GameWidth, GameHeight);
  FMonsterBullets := TBurst.Create(ARenderer, 'bull');
  FHudCache := TSpriteCache.Create(ARenderer, 'heroes');
  FFont := TMoonFont.Create(ARenderer, FontFileName, FontOrientation);
  FMessages := TMessageBoard.Create(FFont, GameWidth);
  FAudio := TSoundBank.Create(SoundsDir, MusicDir);
  PreloadSounds;

  FMenu := TMoonMenu.Create(ARenderer, FSprites, FFont, ALevels);
  FMenu.Difficulty := FDifficulty;
  FState := gsMenu;
  FResumeState := gsMenu;
  FAudio.PlayMusic(MenuMusicFile, mmLoop); // moon.ogg of 2008 (1857)
end;

destructor TMoonGame.Destroy;
begin
  FMenu.Free;
  FAudio.Free;
  FMessages.Free;
  FFont.Free;
  FHudCache.Free;
  FField.Free;
  FMonsterBullets.Free;
  FHero.Free;
  FTiles.Free;
  FSprites.Free;
  FBackgroundCache.Free;
  FTileCache.Free;
  FLevel.Free; // owned here since the menu became the level picker
  inherited;
end;

// The 2008 StartLevel: tear down whatever level was running, build the
// next one, reset every per-run counter. RestartLevel stays the light
// version for death - it keeps the level, this one replaces it.
procedure TMoonGame.LoadLevel(const AFileName: string);
begin
  FField.Free;
  FHero.Free;
  FTiles.Free;
  FBackgroundCache.Free;
  FLevel.Free;
  FField := nil;
  FHero := nil;
  FTiles := nil;
  FBackgroundCache := nil;

  FLevel := TLevel.Create;
  FLevel.LoadFromFile(AFileName);
  FLevelFile := AFileName; // AdvanceToNextLevel keys off this

  FBackgroundCache := TSpriteCache.Create(FRenderer,
    IncludeTrailingPathDelimiter(LevelsDir) + FLevel.AssetsDir);
  FBackgroundCache.DisableColorKey;
  FTiles := TTileScreenRenderer.Create(FSprites, FTileCache,
    FBackgroundCache, FLevel);
  FHero := THero.Create(FRenderer, FLevel, HeroSkinFile, WeaponListFile);
  FField := TMonsterField.Create(FRenderer, FMonsters, FLevel,
    FDifficulty, DifficultyMonsterLives[FDifficulty]);

  FMonsterBullets.Clear;
  FMessages.Clear;
  FHeroHealth := DifficultyHeroHealth[FDifficulty]; // moon.dpr 1714-1716
  FHurtCooldown := 0;
  FCheckpointX := FHero.X;
  FCheckpointY := FHero.Y;
  // Stale-flag hygiene 2008 never had: StartLevel did not reset
  // GravelAttack - a latent bug that could not fire only because death
  // led to the menu. With checkpoint respawn it would be a softlock.
  FGravelAttack := False;
  FEndLevelTimer := 0;
  FScore := 0;
  FKillStreak := 0;
  FStreakBonusCount := 0;
  FCountdownDigit := 0;
  FCountdownTick := 0;
  FHenshinActive := False;
  FHenshinTick := 0;
  FBonus := bkNone;
  FBonusActivateQueued := False;
  FTriggerFired := nil;
  SetLength(FTriggerFired, Length(FLevel.Entities));

  FLevelLoaded := True;
  FMenu.HasActiveGame := True;

  if FLevel.IntroText.Current <> '' then
    FState := gsIntro
  else
    StartPlaying;
end;

// Opens AUrl in the default browser. Deliberately Windows-only, as is
// the whole runtime (SDL2.dll beside the exe); the platform ifdef lives
// here and nowhere else (codestyle 11).
procedure OpenWebPage(const AUrl: string);
begin
  {$IF Defined(MSWINDOWS)}
  ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
  {$ENDIF}
end;

function TMoonGame.CurrentLevelIsLast: Boolean;
begin
  Result := (FLevels <> nil) and
    SameText(FLevels[High(FLevels)].FileName, FLevelFile);
end;

procedure TMoonGame.BeginEnding;
begin
  FState := gsEnding;
  // The campaign is over: nothing to resume behind the farewell
  FMenu.HasActiveGame := False;
  FHeldLeft := False;
  FHeldRight := False;
  FHeldJump := False;
  FHeldFire := False;
  // The current track keeps playing under the farewell - the 2008 exit
  // was silence via GameFree; a track feels kinder (tweak on review)
end;

procedure TMoonGame.DrawCenteredBig(const AText: string; ARow: Integer);
begin
  FFont.DrawBig(AText, (GameWidth - FFont.BigTextWidth(AText)) / 2,
    ARow * SmallLineStep);
end;

procedure TMoonGame.DrawEnding;
begin
  var Lines: TArray<string> := [Tr(SEndingLine1), Tr(SEndingLine2),
    Tr(SEndingLine3), Tr(SEndingLine4), Tr(SEndingLine5)];
  for var i := 0 to High(Lines) do
    FFont.DrawSmall(Lines[i], EndingTextColumn * LegacyColumnWidth,
      (EndingTextFirstRow + i) * SmallLineStep);

  DrawCenteredBig(Tr(SEndingAuthor), EndingAuthorRow);
  DrawCenteredBig(Tr(SEndingMenu), EndingMenuRow);
  // A pointer to click with: the calm green crosshair
  FHero.DrawCrosshair(FSprites, 1);
end;

function TMoonGame.HitEndingLine(const AText: string;
  ATopRow: Integer): Boolean;
begin
  var Left := (GameWidth - FFont.BigTextWidth(AText)) / 2;
  Result := (FMouseGX >= Left) and
    (FMouseGX <= Left + FFont.BigTextWidth(AText)) and
    (FMouseGY >= ATopRow * SmallLineStep) and
    (FMouseGY <= (ATopRow + EndingClickRows) * SmallLineStep);
end;

procedure TMoonGame.HandleEndingClick;
begin
  if HitEndingLine(Tr(SEndingAuthor), EndingAuthorRow) then
  begin
    // The browser must land in a visible window - fullscreen drops first
    if FFullscreen then
      ToggleFullscreen;
    OpenWebPage(AuthorLinkedInUrl);
  end
  else if HitEndingLine(Tr(SEndingMenu), EndingMenuRow) then
  begin
    // OpenMenu keeps the level track by design (the pause menu); the
    // campaign exit deserves the title theme instead
    FAudio.PlayMusic(MenuMusicFile, mmLoop);
    OpenMenu;
  end;
end;

// The 2008 outer loop was 'while True do begin StartLevel; FreeLevel
// end' with 'LevelNum := LevelNum + 1' between (163): the campaign ran
// in file order. Past the last level 2008 indexed beyond its LevelList
// (undefined ground); we bow out to the menu instead - deviation logged.
procedure TMoonGame.AdvanceToNextLevel;
begin
  for var i := 0 to High(FLevels) - 1 do
    if SameText(FLevels[i].FileName, FLevelFile) then
    begin
      LoadLevel(FLevels[i + 1].FileName);
      Exit;
    end;
  OpenMenu;
end;

procedure TMoonGame.OpenMenu;
begin
  FResumeState := FState;
  FState := gsMenu;
  // Keys released while the menu is up never reach the game; a stale
  // held flag would sprint the hero the moment the menu closes
  FHeldLeft := False;
  FHeldRight := False;
  FHeldJump := False;
  FHeldFire := False;
  FMenu.ShowMain;
  // Level music keeps playing under the menu - verbatim 2008 behavior
end;

procedure TMoonGame.ToggleFullscreen;
begin
  FFullscreen := not FFullscreen;
  if FFullscreen then
    SDL_SetWindowFullscreen(FWindow, SdlWindowFullscreenDesktop)
  else
    SDL_SetWindowFullscreen(FWindow, 0);
end;

procedure TMoonGame.ApplyMenuResult(const AResult: TMenuResult);
begin
  case AResult.Command of
    mcStartLevel:
      LoadLevel(AResult.LevelFile);
    mcResume:
      FState := FResumeState;
    mcToggleFullscreen:
      ToggleFullscreen;
    mcSetDifficulty:
      begin
        // Takes effect where the field is reborn: level load or restart
        // (2008 applied per screen - see the menu hint deviation)
        FDifficulty := AResult.Difficulty;
        SaveGameDifficulty(ConfigFileName, FDifficulty);
      end;
    mcSetLanguage:
      begin
        // Dictionary first, THEN the menu: the Language setter rebuilds
        // captions through Tr and must read the new words. Menu and HUD
        // switch live; level texts follow on the next load (part 6.3).
        LoadLanguage(AResult.Language);
        SaveGameLanguage(ConfigFileName, AResult.Language);
        FMenu.Language := AResult.Language;
      end;
    mcQuit:
      RequestQuit;
  end;
end;

// The hero has just landed on a new screen: pin the checkpoint (pits
// and death return here), drop what never crosses a door - bullets
// (verbatim moon.dpr 1089-1090: no shooting backwards through it) and
// the positional popups - then greet the arrival. Triggers fire even
// for a debug browse ('no fire rain' of review round five).
procedure TMoonGame.ArriveOnScreen;
begin
  FCheckpointX := FHero.X;
  FCheckpointY := FHero.Y;
  FHero.Bullets.Clear;
  FMonsterBullets.Clear;
  FMessages.ClearPopups;
  FireScreenTriggers;
end;

procedure TMoonGame.HandleScreenTransitions;
begin
  // Verbatim moon.dpr 1071-1073: transition at x > 512-33, blocked
  // while the gravel trial runs and for the dead; land at x=4,
  // checkpoint there
  if (FHero.X > GameWidth - 33) and not FGravelAttack and
     not FHero.Dead then
  begin
    if FHero.Screen < FLevel.ScreenCount then
    begin
      FHero.Screen := FHero.Screen + 1;
      FHero.SetScreenX(4);
      ArriveOnScreen;
    end
    else if CurrentLevelIsLast then
      // The 2008 door out of the last screen called GameFree - the game
      // ENDED by walking out. Same door, kinder farewell (part 5.4).
      BeginEnding;
    // else: the last screen of a mid-campaign level stays walled - its
    // exit is the boss (meLevelComplete), not the edge
  end
  else if FHero.X < 2 then
    FHero.SetScreenX(2); // no way back - the 2008 doors open one way
end;

// 'Падаем в лунку' verbatim: the pit returns the hero to the
// screen's entry point and takes one life
procedure TMoonGame.HandlePitFall;
begin
  if (FHero.Y > PitDepthY) and not FHero.Dead then
  begin
    FHero.SetScreenX(FCheckpointX);
    FHero.SetY(FCheckpointY);
    FMessages.AddTicker(Tr(SFellIntoPit), TickerPitTicks);
    FAudio.Play(PitSoundFile); // the pit plays down.wav, not pain (780)
    HurtHero;
  end;
end;

// Entity triggers of the CURRENT screen: location titles, captions and
// tutorial hints. Each fires once per game - a hint that nags on every
// backtrack stops being a hint. The 2008 '_string:' hints ran as the
// marquee ('Бегущая строка' of moon.dpr 816) - reproduced here.
procedure TMoonGame.FireScreenTriggers;
begin
  for var i := 0 to High(FLevel.Entities) do
  begin
    if FLevel.Entities[i].Screen <> FHero.Screen then
      Continue;
    if FTriggerFired[i] then
      Continue;

    // An entity filtered out by the difficulty grade takes its
    // triggers with it - a hard-only trial must not arm on normal
    if not (FDifficulty in FLevel.Entities[i].Grades) then
      Continue;
    var Triggers := FLevel.Entities[i].Triggers;
    if (Triggers.BigMessage.Current = '') and
       (Triggers.SmallMessage.Current = '') and
       (Triggers.HintText.Current = '') and
       (Triggers.ChangeMusic = '') and
       not Triggers.HasHeroX and not Triggers.HasHeroY and
       not Triggers.HasGravelBoss then
      Continue;

    FTriggerFired[i] := True;
    FMessages.ShowBig(Triggers.BigMessage.Current, BigMessageTicks);
    FMessages.AddTicker(Triggers.SmallMessage.Current, TickerNoticeTicks);
    FMessages.StartMarquee(Triggers.HintText.Current);
    // The changeMusic field of level JSON waited since part 1 for a
    // player to exist - here it is (empty name is a no-op inside)
    if Triggers.ChangeMusic <> '' then
      FCurrentMusic := Triggers.ChangeMusic; // restarts respawn into it
    FAudio.PlayMusic(Triggers.ChangeMusic, mmLoop);
    // 'Сменить X/Y герою' of 2008 (884-898): the trigger relocates the
    // hero by CELL number (value*32, no off-by-one - raw as the original
    // did it) and writes the checkpoint for its axis. Death and pits now
    // return to the tunnel entrance, not to the start of the level.
    // SetY drops into a fall - no standing on air (deviation 5).
    if Triggers.HasHeroX then
    begin
      FHero.SetScreenX(Triggers.HeroX * TileSize);
      FCheckpointX := FHero.X;
      // A heroY of the same screen may have already settled the hero
      // at an intermediate X where the ground verdict was meaningless
      // (screen 7 pairs them) - settle again at the final spot
      FHero.SettleOnGround;
    end;
    if Triggers.HasHeroY then
    begin
      FHero.SetY(Triggers.HeroY * TileSize);
      FCheckpointY := FHero.Y;
    end;
    // 'Атака грейвелов' (955-971): one message armed BOTH the gravel
    // rain and the transformation - 'Henshin := 1; HenshinTime := 30'
    // fired the ceremony INSTANTLY, mid-sequence (tick-20 wave skipped).
    // Verbatim: no countdown here - the bullet rain must open the scene
    // (first ring 10 ticks in); the 3..2..1 prelude stays boss-only.
    if Triggers.HasGravelBoss then
    begin
      FGravelAttack := True;
      // The quota lives in the level JSON, split by difficulty there
      // (75/125/200 for level2) - the game only picks its grade
      FGravelLeft := Triggers.GravelQuota.ForGrade(FDifficulty);
      FToNextGravel := GravelFirstWaveTicks;
      FGravelScreen := FHero.Screen;
      StartHenshin(30);
    end;
  end;
end;

// 'GravAttack' of moon.dpr 371-408, called every tick while the flag is
// up (545) - even over the hero's corpse, like the rest of the timer.
// Each wave burns one unit of the quota and drops gravels from the sky;
// once the quota is dry AND the screen holds no live body, the
// breakthrough opens the right edge again.
procedure TMoonGame.TickGravelAttack;
begin
  if not FGravelAttack then
    Exit;

  Dec(FToNextGravel);
  if FToNextGravel <> 0 then
    Exit;
  FToNextGravel := GravelWaveTicks;

  Dec(FGravelLeft);
  if FGravelLeft > 0 then
    FField.SpawnFromSky(GravelMonsterId, FGravelScreen);

  if (FGravelLeft < 1) and not FField.AnyAliveOnScreen(FGravelScreen) then
  begin
    FGravelAttack := False;
    FMessages.ShowBig(Tr(SBrokeThrough), BigMessageTicks);
    // The breakthrough shatter RINGS, unlike the silent level-complete
    // one: Snd_bottle right before the same 12x16 fan (397-403). The
    // 2008 tile edit that retired the trigger for good (391-392) is
    // replaced by the once-per-life trigger reading (see RestartLevel).
    if FHero.HeroForm <> hfNormal then
      FAudio.Play(BottleSoundFile);
    RemoveIceForm;
  end;
end;

// Verbatim ladder of moon.dpr 826-864, quirks included: the 4th bonus
// is 'Неуязвимый' +25 and the 7th is 'Бог войны' +50; every other one
// pays +10 until the end of days. The counter dies with any damage
// (see HurtHero).
procedure TMoonGame.ProcessKillStreak;
const
  StreakGoal = 10;
begin
  Inc(FKillStreak);
  if FKillStreak < StreakGoal then
    Exit;
  FKillStreak := 0;

  Inc(FStreakBonusCount);
  case FStreakBonusCount of
    4: AwardStreakBonus(Tr(SStreakBigInvincible),
         Tr(SStreakSmallInvincible), 25);
    7: AwardStreakBonus(Tr(SStreakBigWarGod), Tr(SStreakSmallWarGod), 50);
  else
    AwardStreakBonus(Tr(SStreakBigTen), Tr(SStreakSmallTen), 10);
  end;
end;

procedure TMoonGame.AwardStreakBonus(const ABig, ASmall: string;
  APoints: Integer);
begin
  FMessages.ShowBig(ABig, BigMessageTicks);
  FMessages.AddTicker(ASmall, TickerStreakTicks);
  Inc(FScore, APoints);
end;

// Warm the sound cache at startup so the first shot reads from RAM,
// not from disk. The roster assembles itself: hero one-shots + the
// weapon map + every deathSounds entry of monsters.json - no second
// hand-maintained list to drift out of sync.
procedure TMoonGame.PreloadSounds;
begin
  FAudio.Load(PainSoundFile);
  FAudio.Load(PitSoundFile);
  FAudio.Load(HenshinSoundFile);
  FAudio.Load(HenshinWaveSoundFile);
  FAudio.Load(BottleSoundFile);
  FAudio.Load(CountdownBeepFile);
  FAudio.Load(BonusSoundFile);
  for var Name in WeaponShotSounds do
    FAudio.Load(Name);
  for var Def in FMonsters.AllDefs do
    for var Name in Def.DeathSounds do
      FAudio.Load(Name);
end;

// ---------------------------------------------------------------------------
// HENSHIN - the transformation cinematic, verbatim moon.dpr 450-513.
// Five converging rings heal the hero one heart at a time, then the flash:
// the ice form goes on with a double fan. The world does NOT pause - the
// boss keeps shooting through the ceremony, and the ring fragments are
// honest hero bullets that can wound him back. That is the 2008 deal.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// COUNTDOWN - the 3..2..1 prelude to the transformation. Each digit is
// born small in screen center, grows for its whole second of life and
// dissolves near the peak; when the last one dies, the cinematic starts.
// ---------------------------------------------------------------------------

procedure TMoonGame.StartHenshinCountdown(AAtTick: Integer);
begin
  FCountdownDigit := CountdownStartValue;
  FCountdownTick := 0;
  FCountdownHenshinAtTick := AAtTick;
  FAudio.Play(CountdownBeepFile); // '3' announces itself too
end;

procedure TMoonGame.TickCountdown;
begin
  if FCountdownDigit = 0 then
    Exit;
  Inc(FCountdownTick);
  if FCountdownTick < CountdownTicksPerDigit then
    Exit;

  FCountdownTick := 0;
  Dec(FCountdownDigit);
  if FCountdownDigit = 0 then
    StartHenshin(FCountdownHenshinAtTick) // EVOLUTION shout replaces the tick
  else
    FAudio.Play(CountdownBeepFile);
end;

procedure TMoonGame.DrawCountdown(AAlpha: Double);
begin
  if FCountdownDigit = 0 then
    Exit;

  // Fractional progress through the digit's life: logic runs at 33 Hz,
  // rendering at ~164 fps - without the timestep alpha the growth would
  // stutter in 3.3-unit jumps (the marquee lesson of part 2). Stays
  // below 1.0 by construction: the tick resets at the boundary and the
  // timestep alpha never reaches a full tick.
  var Progress := (FCountdownTick + AAlpha) / CountdownTicksPerDigit;
  var GlyphHeight := CountdownMinGlyphHeight +
    (CountdownMaxGlyphHeight - CountdownMinGlyphHeight) * Progress;

  var Opacity := 255;
  if Progress > CountdownFadeStartRatio then
    Opacity := Round(255 * (1 - (Progress - CountdownFadeStartRatio) /
      (1 - CountdownFadeStartRatio)));

  var Digit := IntToStr(FCountdownDigit);
  FFont.DrawScaled(Digit,
    (GameWidth - FFont.ScaledTextWidth(Digit, GlyphHeight)) / 2,
    CountdownCenterY - GlyphHeight / 2,
    GlyphHeight, Opacity);
end;

procedure TMoonGame.StartHenshin(AAtTick: Integer);
begin
  FMessages.ShowBig(Tr(SEvolution), BigMessageTicks);
  // The sting fires twice back to back (878-879 / 966-967) - a poor
  // man's volume boost, kept verbatim
  FAudio.Play(HenshinSoundFile);
  FAudio.Play(HenshinSoundFile);
  FHenshinActive := True;
  FHenshinTick := AAtTick;
end;

procedure TMoonGame.TickHenshin;
begin
  if not FHenshinActive then
    Exit;
  Inc(FHenshinTick);

  for var Wave in HenshinWaves do
    if FHenshinTick = Wave.AtTick then
    begin
      FAudio.Play(HenshinWaveSoundFile);
      CureHero;
      FMessages.AddTicker(Tr(SIceRegen), HenshinRegenTicks);
      FHero.Bullets.SpawnConvergingRing(FHero.X, FHero.Y,
        Wave.Bullets, Wave.RadiusX);
    end;

  if FHenshinTick = HenshinFlashTick then
    FAudio.Play(BottleSoundFile);
  if FHenshinTick = HenshinFinishTick then
    FinishHenshin;
end;

procedure TMoonGame.FinishHenshin;
const
  FinishFan: TFanShape = (Rows: 12; Cols: 42; BaseSpeed: 6; SpeedSpread: 3);
begin
  FMessages.AddTicker(Tr(SIceFormPerk), HenshinPerkTicks);
  CureHero;
  FHero.HeroForm := hfIce;
  FAudio.Play(BottleSoundFile);
  FHero.Bullets.SpawnFan(FHero.X, FHero.Y, FinishFan);
  FMessages.ShowBig(Tr(SIceForm), BigMessageTicks);
  FHenshinActive := False;
  FHenshinTick := 0;
end;

procedure TMoonGame.RemoveIceForm;
const
  ShatterFan: TFanShape = (Rows: 12; Cols: 16; BaseSpeed: 4; SpeedSpread: 3);
begin
  if FHero.HeroForm = hfNormal then
    Exit;
  // Verbatim 940-947: the suit shatters with a fan but NO sound of its
  // own - the victory music covers the moment (2008 played nothing here)
  FHero.HeroForm := hfNormal;
  FHero.Bullets.SpawnFan(FHero.X, FHero.Y, ShatterFan);
end;

// Original cured up to 15; we agreed on a modest 10
procedure TMoonGame.CureHero;
const
  MaxHealth = 10;
begin
  if FHeroHealth < MaxHealth then
    Inc(FHeroHealth);
end;

// ---------------------------------------------------------------------------
// BONUSES - the reward roulette of moon.dpr 531-543 / 565-602. Every 50
// points buys one random reward; it sits in the slot (bottom-left HUD
// caption crawls in to remind) until the right mouse button spends it.
// ---------------------------------------------------------------------------

function BonusDisplayName(AKind: TBonusKind): string;
begin
  case AKind of
    bkHealth: Result := Tr(SBonusHealth);
    bkFireRain: Result := Tr(SBonusFireRain);
    bkAura: Result := Tr(SBonusAura);
    bkExplosion: Result := Tr(SBonusExplosion);
  else
    Result := '';
  end;
end;

procedure TMoonGame.AwardRandomBonus;
begin
  Dec(FScore, BonusCost);
  // repeat Random(BonusCount+1) until <>0 of 2008 collapses to this -
  // same uniform pick over the real rewards, without the dice dance
  FBonus := TBonusKind(1 + Random(Ord(High(TBonusKind))));
  FBonusHudCol := BonusHudStartCol;
  // The fanfare fires THRICE (539-541) - the loudest sound in the game,
  // as befits free stuff; kept verbatim
  FAudio.Play(BonusSoundFile);
  FAudio.Play(BonusSoundFile);
  FAudio.Play(BonusSoundFile);
  FMessages.ShowBig(Format(Tr(SBonusAwardFmt), [BonusDisplayName(FBonus)]),
    BigMessageTicks);
end;

procedure TMoonGame.ActivateQueuedBonus;
const
  HealCharges = 5;
  ExplosionFan: TFanShape =
    (Rows: 12; Cols: 22; BaseSpeed: 4; SpeedSpread: 2);
begin
  if not FBonusActivateQueued then
    Exit;
  FBonusActivateQueued := False;
  if FBonus = bkNone then
    Exit; // a click with an empty slot buys nothing

  case FBonus of
    bkHealth:
      for var i := 1 to HealCharges do
        CureHero;
    bkFireRain:
      FHero.Bullets.SpawnFireRain;
    bkAura:
      FHero.Bullets.SpawnStaticAura(FHero.X, FHero.Y);
    bkExplosion:
      begin
        // The only reward with its own sound (592) - the other three
        // work in silence, verbatim
        FAudio.Play(BottleSoundFile);
        FHero.Bullets.SpawnFan(FHero.X, FHero.Y, ExplosionFan);
      end;
  end;
  FBonus := bkNone;
end;

procedure TMoonGame.DrawBonusHud(AAlpha: Double);
begin
  if FBonus = bkNone then
    Exit;

  // The crawl moves 0.77 units/tick - interpolate or it stutters at
  // render rate (the marquee lesson, third time a charm)
  var Col := FBonusHudCol;
  if Col < BonusHudTargetCol then
    Col := Col + BonusHudSlideStep * AAlpha;

  FFont.DrawSmall(Format(Tr(SBonusHudFmt), [BonusDisplayName(FBonus)]),
    Col * SmallGlyphWidth, BonusHudTopRow * SmallLineStep);
  FFont.DrawSmall(Tr(SBonusHudHint),
    Col * SmallGlyphWidth, (BonusHudTopRow + 1) * SmallLineStep);
end;

procedure TMoonGame.StartPlaying;
begin
  FState := gsPlaying;
  // '1.Космопорт' - the moonlev.txt splash (moon.dpr 1682, 200 ticks)
  FMessages.ShowBig(FLevel.Title.Current, BigTitleTicks);
  // Project[8] of the .moon manifest played here in 2008 (moon.dpr 1731).
  // Remembered as the restart track until a changeMusic trigger takes over
  FCurrentMusic := FLevel.Music;
  FAudio.PlayMusic(FCurrentMusic, mmLoop);
  FireScreenTriggers;
end;

// Cell mapping of the 2008 bullet block: the 16x12 wall grid, 0-based
// (BelongToX/YSprite[1] of WindowProc)
function BulletCellCol(AX: Double): Integer;
begin
  Result := Trunc(16 * AX / GameWidth); // CellOfX - 1
end;

function BulletCellRow(AY: Double): Integer;
begin
  Result := Trunc(12 * AY / GameHeight) - 1;
end;

function BulletOffScreen(const ABullet: TBullet): Boolean;
begin
  Result := (ABullet.X > GameWidth) or (ABullet.X < 0) or
    (ABullet.Y > GameHeight + SpriteSize) or
    (ABullet.Y < -GameHeight / 2);
end;

// Verbatim port of the hero half of the WindowProc bullet block: a
// Contact bullet intercepts monster bullets mid-air, any bullet bursts
// against a solid wall keeping 1/8 inertia, off-screen means gone.
procedure TMoonGame.ResolveHeroBulletHits;
begin
  for var Own in FHero.Bullets.Bullets do
  begin
    if Own.Status <> bsFlying then
      Continue;

    // Anti-missile: a Contact bullet destroys a monster bullet mid-air
    if Own.Contact then
      for var Enemy in FMonsterBullets.Bullets do
        if (Enemy.Status = bsFlying) and
           (Own.X > Enemy.X - 6) and (Own.X < Enemy.X + 6) and
           (Own.Y > Enemy.Y - 6) and (Own.Y < Enemy.Y + 6) then
        begin
          Enemy.StartBurst;
          Own.StartBurst;
          Break;
        end;

    if Own.Status <> bsFlying then
      Continue;

    if BulletOffScreen(Own) then
      Own.Status := bsInactive
    else if (Own.Y > 0) and
      FLevel.SolidAt(FHero.Screen,
        BulletCellCol(Own.X), BulletCellRow(Own.Y)) then
      Own.StartBurstSliding;

    if Own.Status <> bsFlying then
      Continue;

    // Hit a monster: verbatim bound-box of WindowProc, knockback dx/2,
    // barrel-class deaths also fan into the HERO'S burst (the second
    // half of the original double explosion).
    for var Monster in FField.Monsters do
      if (Monster.Screen = FHero.Screen) and (Monster.Life = mlAlive) and
         (Own.X > Monster.X + 8) and
         (Own.X < Monster.X - 8 + SpriteSize) and
         // Verbatim 2008 hitbox: DOWNWARD from Y - bullets spawn at
         // heroY+8, below the feet line, and this is where they land
         (Own.Y > Monster.Y) and (Own.Y < Monster.Y + SpriteSize) then
      begin
        var Knock := Round(Own.DX / 2);
        Own.StartBurst;
        Monster.TakeDamage(Knock, 1, FMonsterBullets);
        if Monster.Life = mlDying then
          RewardMonsterKill(Monster);
        Break;
      end;
  end;
end;

// The kill aftermath: score, death ticker, '+N' popup, streak credit,
// the explosion fan of exploders. AMonster has just flipped to dying.
procedure TMoonGame.RewardMonsterKill(const AMonster: TMonster);
begin
  Inc(FScore, AMonster.Def.Score);
  FMessages.AddTicker(AMonster.Def.DeathText.Current,
    TickerDeathTextTicks);
  // '+N' rises from the body top (Y is the feet line, the body
  // is drawn upward from it)
  FMessages.AddScorePopup('+' + IntToStr(AMonster.Def.Score),
    AMonster.X, AMonster.Y - SpriteSize);
  ProcessKillStreak;
  if AMonster.Def.ExplodesOnDeath then
    FHero.Bullets.SpawnExplosionFan(AMonster.X, AMonster.Y);
end;

// The monster half: walls and the void as above, plus the hero's hide -
// the same downward hitbox, guarded by the mercy window
procedure TMoonGame.ResolveMonsterBulletHits;
begin
  for var Enemy in FMonsterBullets.Bullets do
  begin
    if Enemy.Status <> bsFlying then
      Continue;
    if BulletOffScreen(Enemy) then
      Enemy.Status := bsInactive
    else if (Enemy.Y > 0) and
      FLevel.SolidAt(FHero.Screen,
        BulletCellCol(Enemy.X), BulletCellRow(Enemy.Y)) then
      Enemy.StartBurstSliding
    else if (FHurtCooldown = 0) and not FHero.Dead and
      (Enemy.X > FHero.X + 8) and
      (Enemy.X < FHero.X - 8 + SpriteSize) and
      (Enemy.Y > FHero.Y) and (Enemy.Y < FHero.Y + SpriteSize) then
    begin
      Enemy.StartBurst;
      FMessages.AddTicker(Tr(SHitByBullet), TickerNoticeTicks);
      FAudio.Play(PainSoundFile);
      HurtHero;
    end;
  end;
end;

procedure TMoonGame.HurtHero;
begin
  if FHero.Dead then
    Exit;
  FKillStreak := 0; // 2008 reset it at every damage site (752/781/985)
  Dec(FHeroHealth);
  FHurtCooldown := HurtMercyTicks;
  if FHeroHealth <= 0 then
  begin
    FHero.Kill; // the d-frames play; the world keeps moving without him
    FGameOverTimer := GameOverDelayTicks;
    // Dying cancels the pending exit: the door reopens when the reborn
    // hero kills the reborn boss. (2008 raced its GameOver timer against
    // ToEndLev and the menu won - same spirit, cleaner mechanics.)
    FEndLevelTimer := 0;
  end;
end;

procedure TMoonGame.RestartLevel;
begin
  // Death rewinds to the checkpoint: the entry point of the CURRENT
  // screen, kept fresh by transitions and heroX/heroY triggers - dying
  // on screen 9 no longer costs the whole level. The world around it
  // restarts in full: monsters and all, barrels regrow, gravels rise
  // again. (2008 had no respawn - death led to the menu; the checkpoint
  // only served the pits. Our auto-restart deviation now reads it too.)
  FField.Free;
  FField := TMonsterField.Create(FRenderer, FMonsters, FLevel,
    FDifficulty, DifficultyMonsterLives[FDifficulty]);
  FHero.Bullets.Clear;
  FMonsterBullets.Clear;
  FHero.Revive;
  FHero.SetScreenX(FCheckpointX);
  FHero.SetY(FCheckpointY); // drops into a fall: no standing on air
  FHeroHealth := DifficultyHeroHealth[FDifficulty];
  FHurtCooldown := 0;
  // See the LoadLevel comment: 2008 never cleared this flag, here it
  // would softlock the reborn screen. The gravel chapter re-raises it
  // through its screen trigger.
  FGravelAttack := False;
  // Monsters regrow, so the score they paid out is taken back -
  // otherwise dying becomes a farming strategy. Captions die with you.
  FScore := 0;
  FKillStreak := 0;
  FStreakBonusCount := 0;
  FMessages.Clear;
  // A fresh boss means a fresh ceremony: the countdown, the cinematic
  // and the ice form die with the hero (the new TMonster resets its
  // henshin flag too)
  FCountdownDigit := 0;
  FCountdownTick := 0;
  FHenshinActive := False;
  FHenshinTick := 0;
  FHero.HeroForm := hfNormal;
  // Score burns on restart (anti-farm), so the unspent reward burns too
  FBonus := bkNone;
  FBonusActivateQueued := False;
  // The boss regrows calm, so his rage track must not outlive him -
  // and win.ogg dies with the cancelled exit. FCurrentMusic covers the
  // screens that have no changeMusic trigger of their own (most of
  // them); a screen that HAS one replays it via the re-arm below.
  FAudio.PlayMusic(FCurrentMusic, mmLoop);
  // Death re-enters the screen: its one-shot triggers re-arm and fire
  // again - teleports are idempotent (the checkpoint IS their target),
  // captions re-introduce the place, the gravel trial rises with the
  // barrels. The 2008 'for good' tile edit (391-392) becomes this
  // once-per-LIFE reading.
  for var i := 0 to High(FLevel.Entities) do
    if FLevel.Entities[i].Screen = FHero.Screen then
      FTriggerFired[i] := False;
  FireScreenTriggers;
end;

procedure TMoonGame.ResolveMonsterContact;
begin
  // Verbatim guard of 2008 ('if not MyHero.death'): the dead are
  // beyond contact - no shoves, no pickups, no desecration.
  if FHero.Dead then
    Exit;

  for var Monster in FField.Monsters do
  begin
    if Monster.Screen <> FHero.Screen then
      Continue;
    if Monster.Life <> mlAlive then
      Continue;

    // Verbatim 2008 box: bounds trimmed on both sides, Y DOWNWARD
    // from both feet lines - the third victim of the same Y-sign trap
    var Touching :=
      (FHero.X + 8 < Monster.X + SpriteSize - 8) and
      (FHero.X + SpriteSize - 8 > Monster.X + 8) and
      (FHero.Y < Monster.Y + SpriteSize) and
      (FHero.Y + SpriteSize > Monster.Y);
    if not Touching then
      Continue;

    case Monster.Def.Category of
      mcPickup:
        begin
          // 'Аптечка активирована' and friends - pickups score nothing
          FMessages.AddTicker(Monster.Def.DeathText.Current,
            TickerDeathTextTicks);
          case Monster.Def.PickupEffect.Kind of
            peHeal:
              CureHero;
            peGiveWeapon:
              FHero.ApplyWeaponPickup(
                Monster.Def.PickupEffect.WeaponType,
                Monster.Def.PickupEffect.FireCooldown,
                Monster.Def.PickupEffect.BulletSpeed,
                Monster.Def.PickupEffect.BulletGravity);
          end;
          Monster.TakeDamage(0, Monster.Lives, FMonsterBullets);
        end;
    else
      if Monster.Def.Dangerous then
      begin
        if FHurtCooldown = 0 then
        begin
          FMessages.AddTicker(Tr(SHurtByMonster), TickerNoticeTicks);
          FAudio.Play(PainSoundFile);
          HurtHero;
        end;
        // 'Монстряк слегка толкает героя' - a 4-unit shove away.
        // Through ShoveX, not a raw X write: 2008 wrote the position
        // directly and a monster could grind the hero into a wall
        if FHero.X > Monster.X then
          FHero.ShoveX(4)
        else
          FHero.ShoveX(-4);
      end;
    end;
  end;
end;

procedure TMoonGame.DrainMonsterEvents;
begin
  for var i := FField.Monsters.Count - 1 downto 0 do
  begin
    var Monster := FField.Monsters[i];
    var Event := Monster.DrainEvent;
    while Event <> meNone do
    begin
      case Event of
        meDied:
          // Everything dies through TakeDamage, so pickups chirp here
          // too (medic/gun of 2008); tank and boss carry two sounds -
          // the double explosion plays both, verbatim 903-925
          for var Name in Monster.Def.DeathSounds do
            FAudio.Play(Name);
        meHenshin:
          // The boss dropped below 2/3 - three seconds of countdown,
          // then the cinematic; the ice form arrives 140 ticks of
          // waves after that
          StartHenshinCountdown(0);
        meBossRage:
          // 'Сменить музыку' of 2008 (868-869): the rage track loops
          // until the boss dies or the hero does
          FAudio.PlayMusic(Monster.Def.Boss.RageMusic, mmLoop);
        meBossWantsMinion:
          // The weighted table of AddMonstOnBoss1 (medkit counted
          // twice) rains reinforcements - and mercy - from the sky
          FField.SpawnFromSky(Monster.Def.Boss.PickSpawn,
            Monster.Screen);
        meLevelComplete:
          begin
            // The suit comes off with a shatter, the victory track plays
            // over the wreckage, and 'ToEndLev := 400' (949) starts the
            // walk-out timer - Update loads the next level when it dries
            RemoveIceForm;
            FAudio.PlayMusic(VictoryMusicFile, mmOnce);
            FEndLevelTimer := LevelEndLingerTicks;
          end;
      end;
      Event := Monster.DrainEvent;
    end;
  end;
end;

procedure TMoonGame.Update(ADeltaSeconds: Double);
begin
  if FState in [gsMenu, gsIntro] then
  begin
    // Only the sky moves; the world below is frozen. The story screen
    // keeps the same live sky - in 2008 it WAS the menu, text on top
    FMenu.Tick;
    Exit;
  end;
  if FState = gsEnding then
    Exit; // the farewell screen is static; only the mouse works there

  FMessages.Tick;
  // 'if EndLev then ToEndLev--' (moon.dpr 525-528): the level is won,
  // the hero lingers; when the timer dries up the campaign moves on.
  // Everything below touches the OLD level's objects - hence the hard
  // exit right after the switch.
  if FEndLevelTimer > 0 then
  begin
    Dec(FEndLevelTimer);
    if FEndLevelTimer = 0 then
    begin
      AdvanceToNextLevel;
      Exit;
    end;
  end;
  // The prelude and the cinematic count in the same breath as the 2008
  // timer did (450): they keep ticking even over the hero's corpse -
  // restart resets both
  TickCountdown;
  TickHenshin;

  // Enough points on the meter and an empty slot: the roulette spins (531)
  if (FScore >= BonusCost) and (FBonus = bkNone) then
    AwardRandomBonus;
  ActivateQueuedBonus;
  if (FBonus <> bkNone) and (FBonusHudCol < BonusHudTargetCol) then
    FBonusHudCol := FBonusHudCol + BonusHudSlideStep;

  // 'if GravelAttack then GravAttack' (545) sat right after the
  // roulette - same slot here
  TickGravelAttack;

  // Poll held keys every tick, verbatim input model of 2008
  if FHeldLeft then
    FHero.Command(hcGoLeft)
  else
    FHero.Command(hcStopLeft);
  if FHeldRight then
    FHero.Command(hcGoRight)
  else
    FHero.Command(hcStopRight);
  if FHeldJump then
    FHero.Command(hcJump)
  else
    FHero.Command(hcStopJump);

  FHero.Tick;
  if FHeldFire and FHero.Fire then
    FAudio.Play(WeaponShotSounds[FHero.WeaponType]);

  FField.Tick(FHero.Screen, Round(FHero.X), Round(FHero.Y),
    FMonsterBullets);
  DrainMonsterEvents;

  FHero.Bullets.Update;
  FMonsterBullets.Update;
  ResolveHeroBulletHits;
  ResolveMonsterBulletHits;
  ResolveMonsterContact;
  if FHurtCooldown > 0 then
    Dec(FHurtCooldown);
  if FHero.Dead then
  begin
    Dec(FGameOverTimer);
    if FGameOverTimer <= 0 then
      RestartLevel;
  end;

  HandleScreenTransitions;
  HandlePitFall;

  if FInspect and Assigned(FWindow) then
  begin
    var Col := FMouseGX div TileSize;
    var Row := FMouseGY div TileSize;
    var Tile := FLevel.TileAt(FHero.Screen, Col, Row);
    var Name := 'empty';
    if Tile <> EmptyTile then
      Name := FLevel.TilePalette[Tile - 1];
    SDL_SetWindowTitle(FWindow, PAnsiChar(SdlText(Format(
      'scr %d cell %d,%d tile %d = %s',
      [FHero.Screen, Col, Row, Tile, Name]))));
  end;
end;

procedure TMoonGame.Render(ARenderer: PSdlRenderer; AAlpha: Double);
begin
  SDL_SetRenderDrawColor(ARenderer, 10, 12, 40, 255);
  SDL_RenderClear(ARenderer);

  case FState of
    gsMenu:
      FMenu.Draw(AAlpha);
    gsIntro:
      begin
        // 2008 typed the story right over the living menu sky - same
        // stars and moon, no logo, text on top
        FMenu.DrawSky(AAlpha);
        DrawIntro;
      end;
    gsEnding:
      DrawEnding;
    gsPlaying:
      begin
        FTiles.DrawScreen(FHero.Screen);
        FField.Draw(FSprites, FHero.Screen);
        FHero.Draw(FSprites);
        FHero.Bullets.Draw(FSprites);
        FMonsterBullets.Draw(FSprites);
        FHero.DrawCrosshair(FSprites, CrosshairFrame);
        DrawHud(ARenderer);
        DrawMessages(AAlpha);
        DrawCountdown(AAlpha); // topmost: the ceremony outranks the news
      end;
  end;

  if FShowAtlas then
    FFont.DrawAtlas((GameWidth - GameHeight) div 2, 0, GameHeight);
end;

procedure TMoonGame.DrawIntro;
const
  TextLeft = 26;  // roughly centers the widest level1 intro line
  TextTop = 60;
  PromptY = 344;
begin
  FFont.DrawSmallBlock(FLevel.IntroText.Current, TextLeft, TextTop);
  FFont.DrawSmall(Tr(SPressAnyKey),
    (GameWidth - FFont.SmallTextWidth(Tr(SPressAnyKey))) / 2, PromptY);
end;

procedure TMoonGame.DrawMessages(AAlpha: Double);
const
  ScoreMargin = 6; // top-right corner, clear of the ticker lane
begin
  var ScoreText := Format(Tr(SScoreFmt), [FScore]);
  FFont.DrawSmall(ScoreText,
    GameWidth - FFont.SmallTextWidth(ScoreText) - ScoreMargin, ScoreMargin);

  DrawBonusHud(AAlpha);
  FMessages.Draw(AAlpha);
end;

procedure TMoonGame.NudgeCrosshair(ADX, ADY: Integer);
begin
  FHero.CrossDX := FHero.CrossDX + ADX;
  FHero.CrossDY := FHero.CrossDY + ADY;
  SDL_SetWindowTitle(FWindow, PAnsiChar(SdlText(Format(
    'crosshair offset: DX=%d DY=%d  (report these two numbers)',
    [FHero.CrossDX, FHero.CrossDY]))));
end;

// The weapon-4 muzzle tuner: same workflow as the crosshair one - the
// FPS updater will fight over the caption once a second, live with it
procedure TMoonGame.NudgeMinigunMuzzle(ADX, ADY, ADLen: Integer);
begin
  FHero.NudgeMinigun(ADX, ADY, ADLen);
  SDL_SetWindowTitle(FWindow, PAnsiChar(SdlText(Format(
    'minigun: baseX=%.0f baseY=%.0f len=%.0f  (report these three)',
    [FHero.MinigunBaseX, FHero.MinigunBaseY, FHero.MinigunMuzzleLen]))));
end;

// PgUp/PgDn debug browse. The 2008 debug jump (F1, 1144-1145) wrote the
// checkpoint too - without it a death on the browsed screen respawns
// into coordinates borrowed from the screen left behind; ArriveOnScreen
// covers that and the rest of the door ritual.
procedure TMoonGame.DebugBrowseScreen(ADelta: Integer);
begin
  var Target := FHero.Screen + ADelta;
  if (Target < 1) or (Target > FLevel.ScreenCount) then
    Exit;
  FHero.Screen := Target;
  FHero.SetY(FHero.Y); // settles or falls, as any teleport
  ArriveOnScreen;
end;

// The smart cursor: green over a healthy enemy, yellow when it is
// wounded, red when one more shot should do - thresholds verbatim.
function TMoonGame.CrosshairFrame: Integer;
begin
  Result := 1;
  for var Monster in FField.Monsters do
  begin
    if (Monster.Screen <> FHero.Screen) or (Monster.Life <> mlAlive) then
      Continue;
    // Verbatim hover of 2008: the cursor Y is shifted +32 before the
    // downward box test - i.e. the check lands on the VISIBLE body
    if (FMouseGX <= Monster.X) or (FMouseGX >= Monster.X + SpriteSize) or
       (FMouseGY + SpriteSize <= Monster.Y) or
       (FMouseGY + SpriteSize >= Monster.Y + SpriteSize) then
      Continue;

    if Monster.Lives > Round(Monster.LivesAll * 2 / 3) then
      Exit(2);
    if Monster.Lives > Round(Monster.LivesAll / 3) then
      Exit(3);
    Exit(4);
  end;
end;

procedure TMoonGame.DrawHud(const ARenderer: PSdlRenderer);
var
  Dest: TSdlRect;
begin
  // Barrels hurt bystanders and pits cost a life - now the player can
  // SEE it: one icon per health point, top-left.
  var Icon := FHudCache.Get('health.bmp');
  for var i := 0 to FHeroHealth - 1 do
  begin
    Dest.X := 4 + i * 18;
    Dest.Y := 4;
    Dest.W := 16;
    Dest.H := 16;
    FSprites.DrawRect(Icon, Dest);
  end;
end;

procedure TMoonGame.HandleKey(AScancode: Integer; AAction: TKeyAction;
  AIsRepeat: Boolean);
begin
  if AIsRepeat then
    Exit;

  // Alt+Enter (or Ctrl+Enter) toggles fullscreen anywhere - menu, story,
  // battle. Bare modifiers are tracked, not acted on.
  if AScancode in [SdlScancodeLCtrl, SdlScancodeRCtrl] then
  begin
    FHeldCtrl := AAction = kaDown;
    Exit; // a bare modifier is not 'any key' for the story screen
  end;
  if AScancode in [SdlScancodeLAlt, SdlScancodeRAlt] then
  begin
    FHeldAlt := AAction = kaDown;
    Exit;
  end;
  if (AScancode = SdlScancodeReturn) and (AAction = kaDown) and
     (FHeldAlt or FHeldCtrl) then
  begin
    ToggleFullscreen;
    Exit;
  end;

  if FState = gsEnding then
    Exit; // mouse-only by design: no key leaves the farewell screen

  if FState = gsMenu then
  begin
    // Escape steps back from a sub-screen; on the main screen it
    // resumes a running game (idle Escape at boot does nothing)
    if (AScancode = SdlScancodeEscape) and (AAction = kaDown) then
      if not FMenu.HandleEscape and FLevelLoaded then
        FState := FResumeState;
    Exit;
  end;

  // The story screen: Escape backs out to the menu, anything else
  // starts the game (2008 had no way back - deviation logged)
  if (FState = gsIntro) and (AAction = kaDown) then
  begin
    if AScancode = SdlScancodeEscape then
      OpenMenu
    else
      StartPlaying;
    Exit;
  end;

  if AAction = kaDown then
    case AScancode of
      SdlScancodeEscape:
        OpenMenu; // 2008: VK_ESCAPE raised the menu, never quit outright
      SdlScancodeLeft, ScancodeA:
        FHeldLeft := True;
      SdlScancodeRight, ScancodeD:
        FHeldRight := True;
      SdlScancodeSpace, ScancodeW, SdlScancodeUp:
        FHeldJump := True;
{$IFDEF DEBUGKEYS}
      ScancodeT:
        FInspect := not FInspect;
      ScancodeF:
        FShowAtlas := not FShowAtlas;
      ScancodeM:
        // Trailer capture: silence the score, keep the gunshots -
        // the footage gets its music in the edit, not in the engine
        FAudio.ToggleMusicMuted;
      // Weapon-4 muzzle tuner on the arrow cluster - the keys a hand
      // reaches for first: 4/6 = X, 8/2 = Y (8 lifts, 2 lowers),
      // plus/minus = barrel length; values land in the window caption
      ScancodeKp4:
        NudgeMinigunMuzzle(-1, 0, 0);
      ScancodeKp6:
        NudgeMinigunMuzzle(1, 0, 0);
      ScancodeKp8:
        NudgeMinigunMuzzle(0, -1, 0);
      ScancodeKp2:
        NudgeMinigunMuzzle(0, 1, 0);
      ScancodeKpMinus:
        NudgeMinigunMuzzle(0, 0, -1);
      ScancodeKpPlus:
        NudgeMinigunMuzzle(0, 0, 1);
      // The crosshair calibrator is DONE (values confirmed by the
      // macro photo and baked into Create) - it retires to the corner
      // cluster, kept for the day a new monitor disagrees
      ScancodeKp7:
        NudgeCrosshair(-1, 0);
      ScancodeKp9:
        NudgeCrosshair(1, 0);
      ScancodeKp3:
        NudgeCrosshair(0, -1);
      ScancodeKp1:
        NudgeCrosshair(0, 1);
      ScancodePageDown:
        DebugBrowseScreen(1);
      ScancodePageUp:
        DebugBrowseScreen(-1);
{$ENDIF}
    end
  else
    case AScancode of
      SdlScancodeLeft, ScancodeA:
        FHeldLeft := False;
      SdlScancodeRight, ScancodeD:
        FHeldRight := False;
      SdlScancodeSpace, ScancodeW, SdlScancodeUp:
        FHeldJump := False;
    end;
end;

procedure TMoonGame.HandleMouseButton(AButton: Integer; ADown: Boolean);
begin
  if FState = gsMenu then
  begin
    if (AButton = 1) and ADown then
      ApplyMenuResult(FMenu.Click);
    Exit;
  end;

  if FState = gsEnding then
  begin
    if (AButton = 1) and ADown then
      HandleEndingClick;
    Exit;
  end;

  if FState = gsIntro then
  begin
    if ADown then
      StartPlaying;
    Exit; // the click that closed the story must not fire the weapon
  end;

  if AButton = 1 then // left
    FHeldFire := ADown;
  if (AButton = 3) and ADown then // right: spend the bonus slot
    FBonusActivateQueued := True;
end;

procedure TMoonGame.HandleMouseMove(AX, AY: Integer);
begin
  // Logical size = game units, no conversion needed
  FMouseGX := AX;
  FMouseGY := AY;
  FMenu.MouseMove(AX, AY);
  if Assigned(FHero) then // no hero exists until the first level loads
    FHero.SetMouse(AX, AY);
end;

// Peeks at a level manifest for its display title without building the
// whole TLevel - the menu only needs the label on the door.
function ReadLevelTitle(const AFileName: string): TLocalizedText;
begin
  var Root := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8)) as TJSONObject;
  if Root = nil then
    Exit(MakeLocalizedText(AFileName)); // the label on a broken door
  try
    Result := ReadLocalizedText(Root, 'title', AFileName);
  finally
    Root.Free;
  end;
end;

function DiscoverLevels: TArray<TLevelChoice>;
begin
  Result := nil;
  for var i := 1 to MaxLevelSlots do
  begin
    var FileName := Format(LevelFilePattern, [i]);
    if not FileExists(FileName) then
      Break; // numbering is contiguous - the first gap ends the list
    var Choice: TLevelChoice;
    Choice.FileName := FileName;
    Choice.Title := ReadLevelTitle(FileName);
    Result := Result + [Choice];
  end;
end;

procedure RunGame;
const
  MonstersFileName = 'monsters.json';
var
  Monsters: TMonsterRegistry;
  Host: TGameHost;
  Game: TMoonGame;
begin
  // 2008 seeded inside MoonTimer of all places; without ANY call the
  // bonus roulette and the moon fly the same route every run
  Randomize;

  var Config := LoadGameConfig(ConfigFileName);
  // The dictionary must stand before the first Tr() - the menu builds
  // its captions inside TMoonGame.Create. A missing or broken language
  // file dies here, in the startup message box, not mid-frame.
  LoadLanguage(Config.Language);
  var Levels := DiscoverLevels;
  if Levels = nil then
    raise Exception.Create(SNoLevelsFound);

  Monsters := TMonsterRegistry.Create;
  try
    Monsters.LoadFromFile(MonstersFileName);

    Host := TGameHost.Create(Config, 'Moon 2D');
    try
      Game := TMoonGame.Create(Monsters, Host.Renderer, Host.Window,
        Levels, Config.Fullscreen, Config.Difficulty);
      try
        Host.Run(Game);
      finally
        Game.Free;
      end;
    finally
      Host.Free;
    end;
  finally
    Monsters.Free;
  end;
end;

begin
  try
    RunGame;
  except
    on E: Exception do
      MessageBox(0, PChar(E.Message), 'Moon 2D - startup error',
        MB_OK or MB_ICONERROR);
  end;
end.
