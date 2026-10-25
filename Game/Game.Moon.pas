{
  Game.Moon - TMoonGame, the game the program runs.

  One process, one window, states instead of the 2008 launcher+game pair.
  The game boots into the menu (moon over a starfield, Menu), levels
  load from there; Escape returns to the menu, Alt/Ctrl+Enter toggles
  fullscreen anywhere. In game: WASD/arrows move, Space/W jumps, S/Down
  drops through a pad, the arm tracks the mouse. PgUp/PgDn browse screens
  for debugging.

  Logic runs in game units (SetMaxC of 2008, see Game.Space); the SDL
  logical size is the frame, so mouse events arrive already in game units.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Moon;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Sprites.Sets, Game.Config, Game.Loop,
  Monsters.Defs, Render.Sprites, Levels.Defs, Levels.Events, Render.Tiles,
  Render.Objects, Effects.Debris, Render.Dynamics, Render.Shake, Hero, Bullets,
  Monsters, Monsters.Pilot, Pads.Shelf, Pads.World, Pads.Arena, Render.Font,
  Hud.Briefing, Hud.Messages, Render.Brush, Hud.Vitals, Game.Bonus,
  Game.Henshin, Game.Shroud, Game.Uptake, Game.Sphere, Game.Trial, Game.Press,
  Game.Arrivals, Game.Cannons, Game.Explosions, Game.Blasts, Game.Impacts,
  Game.HeroOrbs, Orbs.Harvest, Orbs.Patterns, Orbs.Rite, Orbs.Burst,
  Events.Director, Scenes.Director, Hud.Charge,
  Hud.Marks, Hud.GoRight, Hud.Energy, Audio, Menu;

const
  // Levels are discovered by this pattern at startup; the menu lists
  // whatever is on disk, all selectable. Deliberate: a showcase build
  // gates nothing - the 2008 unlock file (levels/default.txt) is
  // retired, not postponed.
  LevelFilePattern = 'level%d.json';

type
  // gsMenu: the moon-over-starfield menu (Menu) - the boot state.
  // gsIntro: the level's story text waits for a key.
  // gsEnding: the campaign-end screen - mouse-only exit (part 5.4).
  TGameState = (gsMenu, gsIntro, gsPlaying, gsEnding);

  TArmorPings = record
    WaitTicks: Integer; // until the next one may sound
    Last: Integer; // index into ArmorHitSounds
    Dice: TXorShift;
  end;

  TMoonGame = class(TGameApp)
  private
    FMonsters: TMonsterRegistry;
    FLevel: TLevel;
    FTileCache: TSpriteCache;
    FBackgroundCache: TSpriteCache;
    FObjectCache: TSpriteCache;
    // The sets the current level declared, owned here; the level
    // caches resolve through them and are freed before them.
    FLevelSets: TObjectList<TSpriteSet>;
    // Interface art - sky, moon, logo, flags, stars, font atlas - and
    // the weapon set the menu borrows its cursor from. Both outlive
    // every level, both owned here.
    FUiSet: TSpriteSet;
    FWeaponSet: TSpriteSet;
    FSprites: TSpriteRenderer;
    FTiles: TTileScreenRenderer;
    FObjects: TObjectScreenRenderer;
    FDynamics: TDynamicScreenRenderer;
    FPads: TPadWorld;
    FHero: THero;
    FState: TGameState;
    // Original input model: keyboard.pas kept a Key[] state array and the
    // timer POLLED it - commands fired every tick while held. That is what
    // let the hero grab a ledge mid-jump: the held key kept knocking until
    // CanIFly* opened. Reproduced with these flags.
    FHeldLeft, FHeldRight, FHeldJump, FHeldDown, FHeldFire: Boolean;
    FMonsterBullets: TBurst; // the shared enemy burst
    FField: TMonsterField;
    FHeroHealth: Integer;
    FHurtCooldown: Integer;  // brief mercy window after a hit
    // Checkpoint ('StartHeroX/Y' of 2008): where pits and death return
    // the hero on the CURRENT screen. The level's respawn point of the
    // screen when it names one (PinRespawnPoint); else, as in 2008, the
    // entry point - updated on every screen transition and, later, by
    // heroX/heroY triggers. The entry point is no promise of a floor: a
    // hero who came through the door falling comes back falling.
    FCheckpointX, FCheckpointY: Double;
    FGameOverTimer: Integer; // ticks left of the death pause
    FVitals: THudVitals; // the HUD is reborn with the level
    FCharge: THudCharge;
    FMarks: THudMarks;
    FGoRight: THudGoRight;
    FEnergyGauge: THudEnergy;
    FRenderer: PSdlRenderer; // kept for level restarts
{$IFDEF DEBUGKEYS}
    FInspect: Boolean; // T: show tile name under cursor in the title
    FShowAtlas: Boolean; // F: raw font atlas (orientation check)
{$ENDIF}
    FMouseGX, FMouseGY: Integer;
    FWindow: PSdlWindow;
    FFont: TMoonFont;
    FMessages: TMessageBoard;
    FBriefing: THudBriefing;
    FShake: TScreenShake;
    FExplosions: TExplosions;
    FBlasts: TObjectList<TBlast>; // the waves of the explosions in flight
    FImpacts: TImpacts;
    FArrivals: TArrivals; // the violet light of the trial's arrivals
    FCannonArt: TCannonArt;
    FCannons: TCannonPair; // the wall cannons of the trial
    FOrbs: THeroOrbs; // the hero's orbs and the charge of the form
    FArmorPings: TArmorPings;
    FScore: Integer;
    // Kill-streak achievement of 2008 (moon.dpr 826-864): kills without
    // the hero taking ANY damage; any hit resets the count to zero.
    FKillStreak: Integer;
    FStreakBonusCount: Integer;
    // Entity triggers fire once per game (tutorial hints must not nag);
    // indexed in step with FLevel.Entities.
    FTriggerFired: TArray<Boolean>;
    FAudio: TSoundBank; // silent when SDL2_mixer.dll is absent
    FHenshin: THenshin; // the ceremony; reborn with the hero
    FShroud: THeroShroud; // the hero's smoke and light; reborn with the hero
    FShroudPainter: TShroudPainter;
    FUptake: TUptake; // what the hero takes in; reborn with the level
    FUptakePainter: TUptakePainter;
    FSphere: TLifeSphere; // the sphere of 200% a level forms; reborn with the level
    FSpherePainter: TLifeSpherePainter;
    FDirector: TEventDirector; // the level's events; reborn with the level
    FScenes: TSceneDirector; // the level's scenes; reborn with the level
    FArena: TPadArena; // the rebuilds of the boss fight; reborn with the level
    // The bonus slot: one reward at a time, spent by right click.
    FBonus: TBonusKind;
    FBonusActivateQueued: Boolean; // right click lands between ticks
    // Set by the first reward spent and kept across levels: until then
    // the HUD slot insists and the award names the mouse button
    FBonusLearned: Boolean;
    FMenu: TMoonMenu;
    FLevelLoaded: Boolean;      // 'StartGame' of 2008
    FResumeState: TGameState;   // where Escape-to-menu came from
    FHeldCtrl: Boolean;         // for the fullscreen chord
    FHeldAlt: Boolean;          // Alt+Enter - the industry-standard chord
    FFullscreen: Boolean;
    FDifficulty: TDifficulty;
    // While the trial runs, the right edge is a wall - the fight cannot
    // be skipped by walking out
    FTrial: TGravelTrial;
    FGravelScreen: Integer;  // where the trial rages - spawns pin here
    // The bank of shelves an event sends the trial's medkits down onto;
    // '' - they come down anywhere
    FMedkitBank: string;
    // The monster of the wave the trial ends in, '' - it has none; the bank
    // an event sends its bodies down onto, '' - they come down anywhere
    FWaveMonster: string;
    FWaveBank: string;
    // The trial of the screen is won: the events of the end wait for it
    FTrialDone: Boolean;
    // An event has opened the door the level shuts on the hero's screen;
    // a new screen, a restart and a new level shut it again
    FDoorOpened: Boolean;
    // The trial's victory track, played as a sound, and what is left of it
    // in seconds: 0 once it is over, below 0 while there is none
    FVictory: THeldSound;
    FVictoryLeft: Double;
    // The press of the finale: the balconies ride down; shut outside it
    FPress: TPress;
    // What the open sky of the trial lets fall; '' - the sky is shut
    FSkyMonster: string;
    // The fly-ins told while the cannons' scene plays, and the ticks left
    // of the smoke after their blast: they wait for the scene to end
    FHeldFlyIns: TArray<string>;
    FCannonSmoke: Integer;
    FAimedColumn: Integer; // where the aimed gravel on its way comes down
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
    procedure MoveCheckpoint(ACol, ARow: Integer);
    procedure PinRespawnPoint;
    function BulletStruckWall(const ABullet: TBullet): Boolean;
    function HeroBulletTarget(const ABullet: TBullet): TMonster;
    procedure ResolveHeroBulletHits;
    procedure ResolveMonsterBulletHits;
    function EnemyBulletNear(AX, AY: Single): TBullet;
    function PopEnemyBullet(AX, AY: Single): Boolean;
    function DangerousMonsterAt(AX, AY: Single): TMonster;
    procedure WoundByOrb(const AMonster: TMonster);
    function BlastStoppedAt(AX, AY: Single): Boolean;
    procedure StrikeMonsters(const ABlast: TBlast);
    procedure StrikeHero(const ABlast: TBlast);
    procedure ResolveBlasts;
    function ShardStruck(const AShard: TLiveShard): Boolean;
    procedure ResolveMonsterContact;
    procedure TakeLoot(const AMonster: TMonster);
    procedure FormSphere(ACol, ARow: Integer; ASize: Single);
    procedure ResolveSphereContact;
    procedure GiveSpherePip;
    procedure SettleSphere;
    procedure BeginUptake(const ALook: TUptakeLook; const AMonster: TMonster);
    procedure WarmPickupPictures;
    procedure SpendBullet(const ABullet: TBullet; const AMonster: TMonster);
    procedure SoundArmorHit(AThrewTracer: Boolean);
    procedure ThrowCrashSparks(const ACrash: TPilotCrash);
    procedure PayDodgePrize(const ABoss: TMonster);
    procedure RewardMonsterKill(const AMonster: TMonster);
    procedure BurstPickup(const AMonster: TMonster; const AHeart: TSdlFPoint);
    procedure DrainMonsterEvents;
    procedure CreateHud;
    procedure HurtHero;
    procedure RestartLevel;
    function CrosshairFrame: Integer;
    // The debug keyboard reaches the game through these four and
    // nothing else. All four exist in every build - their BODIES
    // compile away, so no caller needs an ifdef (codestyle 11).
    function HandleDebugKey(AScancode: Integer): Boolean;
    function HandleDebugMenuKey(AScancode: Integer): Boolean;
    procedure UpdateInspectorCaption;
    procedure DrawAtlasOverlay;
{$IFDEF DEBUGKEYS}
    procedure NudgeCrosshair(ADX, ADY: Integer);
    procedure NudgeMinigunMuzzle(ADX, ADY, ADLen: Integer);
    procedure DebugBrowseScreen(ADelta: Integer);
    procedure DebugShowScreen(AScreen: Integer);
    procedure DebugJumpToWork;
    procedure CycleFontFiltering;
    function SaveScreenPictures(const ADir: string): Integer;
    procedure DumpLevelScreens;
    procedure DebugRebuildPads;
    procedure DebugRestorePads;
{$ENDIF}
    function HitEndingLine(const AText: string; ATopRow: Integer): Boolean;
    procedure FireScreenTriggers;
    procedure FireTriggersOf(AIndex, AScreen: Integer;
      AGrades: TDifficultyGrades; const ATriggers: TEntityTriggers);
    procedure TickGravelAttack;
    procedure PlayVictoryTrack;
    procedure StopVictoryTrack;
    function LetDownFromSky(const AMonsterId: string;
      ALook: TArrivalLook = alPlain): TMonster;
    procedure LetDownMedkit;
    function WaveSideWanted: Integer;
    procedure LetDownWave(AHerald: Boolean);
    procedure ArriveAgain(AGravel: TMonster);
    function HeroColumn: Integer;
    function TrialAct: Integer;
    procedure TellShelves(const AAction: TEventAction);
    procedure BreakCarousel(const ATag: string;
      const ABreakdown: TCarouselBreak);
    procedure LetStraysGo(const AFlock: string);
    procedure SendStraysAway(const AFlock: string);
    procedure FlyInParked(const ATag: string);
    function CannonsScenePlays: Boolean;
    procedure ReleaseHeldFlyIns;
    procedure SendMedkitsOnto(const ABank: string);
    procedure SendWaveOnto(const ABank: string);
    procedure StartPress(const AOrders: TPressOrders; AAct: Integer);
    procedure TellPress(const ACall: TPressCall);
    procedure TellPressRow(const ABank: string; ACall: TShelfCall);
    procedure StartCannons(const AOrders: TCannonOrders; AAct: Integer);
    procedure SpawnGuest(const AOrders: TSpawnOrders; AAct: Integer);
    procedure OpenSky(const AOrders: TSkyFall; AAct: Integer);
    procedure TickCannons;
    procedure TellYieldBank(ACall: TShelfCall);
    procedure LandCannonStrike(const APoint: TSdlFPoint);
    procedure BlowCannons(const ACue: TCannonCue);
    procedure ResolveCannonContact;
    function BulletStruckCannon(const ABullet: TBullet): Boolean;
    function CurrentLevelIsLast: Boolean;
    procedure BeginEnding;
    procedure DrawEnding;
    procedure DrawCenteredBig(const AText: string; ARow: Integer);
    procedure HandleEndingClick;
    procedure ProcessKillStreak;
    procedure AwardStreakBonus(const ABig, ASmall: string; APoints: Integer);
    procedure StartPlaying;
    procedure PreloadSounds;
    procedure ChangeMusic(const AFileName: string; AFadeSeconds: Single = 0);
    function HeroRides(const APad: TPad): Boolean;
    function LocateParent(const ATag: string;
      out AStand: TParentStand): Boolean;
    function SceneStage: TSceneStage;
    function SolidUnderPoint(AX, AY: Single): Boolean;
    procedure EchoAftershock;
    procedure CureHero;
    procedure GrantMercy(ATicks: Integer);
    function HeroCenter: TSdlFPoint;
    function HeroStandsIn(ACol, ARow: Integer): Boolean;
    function HeroBodyPoints: TBodyPoints;
    function MatterAround: TMatter;
    function CreateOrbs: THeroOrbs;
    procedure CastAura;
    procedure AwardRandomBonus;
    procedure ActivateQueuedBonus;
    procedure AdvanceBriefing;
    procedure DrawHeroInShroud(AShake: TSdlPoint; ALift, AAlpha: Single);
    procedure DrawHeroSilhouette(AShake: TSdlPoint; ALift: Single);
    procedure LoadLevel(const AFileName: string);
    function OpenSpriteSet(const ASetName: string): TSpriteSet;
    function LevelArtSetFile(const AKind: string): string;
    function OpenLevelArtSet(const AKind: string): TSpriteSet;
    procedure AdvanceToNextLevel;
    procedure OpenMenu;
    procedure ResumeGame;
    procedure ApplyMenuResult(const AResult: TMenuResult);
    procedure SetFullscreen(AValue: Boolean);
    procedure ToggleFullscreen;
  public
    constructor Create(const AMonsters: TMonsterRegistry;
      const ARenderer: PSdlRenderer; const AWindow: PSdlWindow;
      const ALevels: TArray<TLevelChoice>; const AConfig: TGameConfig);
    destructor Destroy; override;
    procedure Update(ADeltaSeconds: Double); override;
    procedure Render(ARenderer: PSdlRenderer; AAlpha: Double); override;
    procedure HandleKey(AScancode: Integer; AAction: TKeyAction;
      AIsRepeat: Boolean); override;
    procedure HandleMouseMove(AX, AY: Integer); override;
    procedure HandleMouseButton(AButton: Integer; ADown: Boolean); override;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.IOUtils, Sdl2.Image,
  Levels.Dynamics, Levels.Pads, Pads.Flights, Game.Space, Localization;

const
  AuthorLinkedInUrl = 'https://www.linkedin.com/in/kusmin-ilia/';
  FontFileName = 'fonty.png';

  SoundsDir = 'sounds';
  MusicDir = 'music';
  // Verbatim weapon->shot map of moon.dpr 1813-1817, including the
  // quirk of weapon 3 borrowing the pistol bark; the Duplet is not of 2008
  WeaponShotSounds: array [0..DupletWeapon] of string =
    ('shoot.wav', 'shootgun.wav', 'granade.wav', 'shoot.wav', 'shoot2.wav',
    'duplet.wav');
  PainSoundFile = 'pain.wav';         // hero hit (moon.dpr 751/984)
  PitSoundFile = 'down.wav';          // fell into a pit (780)
  BonusSoundFile = 'bonus.wav'; // the roulette fanfare (1829)
  // The boss's armor bursting into his rage: what a machine dies with
  RageBlastSoundFile = 'platform.wav';
  BossCrashSoundFile = 'crash.wav';
  // An arena rebuild: the warning, a pad turning the corner of its
  // flight, two pads docking side by side
  PadHumSoundFile = 'padhum.wav';
  PadClickSoundFile = 'padclick.wav';
  PadClackSoundFile = 'padclack.wav';
  // A shelf out all the way: its latch catches
  ShelfLatchSoundFile = 'shelflatch.wav';
  // A bullet on armor: one of the pings, a tracer leaves with a whine
  ArmorHitSounds: array [0..2] of string =
    ('armor1.wav', 'armor2.wav', 'armor3.wav');
  RicochetSoundFile = 'ricochet.wav';
  // A burst of the wall cannons: the hero's own chain gun, one sound for
  // a few rounds
  CannonShotSoundFile = 'shoot2.wav';
  TerminalKeySoundFile = 'terminal.wav';
  // The life sphere: its sparks spiral in; it bursts into the hero
  SphereFormSoundFile = 'sphereform.wav';
  SphereTakeSoundFile = 'spheretake.wav';

  // Victory sting on boss death; the walk-out timer below carries the
  // hero into the next level while it plays
  VictoryMusicFile = 'win.ogg';
  NoVictoryLeft = -1;
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
  // The gravel trial ('Атака грейвелов' of 2008).
  // FEMALES on purpose: patrolNoEdgeCheck walks off ledges, so they
  // descend and besiege the hero - edge-checked males would idle on the
  // top platforms. Author's call by live behavior.
  GravelMonsterId = 'gravelFemale';
  MedkitMonsterId = 'medkit';
  // The main-menu track (StartingPhase, moon.dpr 1857). Played at boot;
  // opening the menu MID-game leaves the level music running - verbatim
  MenuMusicFile = 'moon.ogg';

  // Message display times in logic ticks, verbatim moon.dpr call sites:
  TickerPitTicks = 170;      // 'Вы упали в лунку' (781)
  // deathText times live in monst.pas, not yet on hand -
  // TODO: verify against monst.pas (tracked: part 2 review)
  TickerDeathTextTicks = 125;
  BigTitleTicks = 200;       // level title splash (1682)
  TickerStreakTicks = 200;   // kill-streak bonus captions (837/849/860)

  // Damage bookkeeping, values verbatim 2008:
  HurtMercyTicks = 50;      // 'permission': mercy window after any hit
  GameOverDelayTicks = 125; // 'ToGameOverTime': d-frames before restart
  PitDepthY = 450;          // 'Падаем в лунку' below this Y

  // The hero's hitbox for a bullet: his sprite less this much on either
  // side
  HitInset = 8;
  // A blast throws a pickup this many knocks, where it shoves a heavier
  // body half of one: off a ledge from the next cell
  PickupThrow = 2.5;
  // A live shard wounds once it is lower than this under the heart of
  // its blast: below the feet line of the body that blew up
  ShardWoundsBelow = SpriteSize / 2;
  // Armor struck again sooner than this answers thinner (Game.Impacts):
  // the chain gun lands every 5 ticks, a pistol every 15
  RapidHitTicks = 8;
  // At most one ping in this many ticks: a fan of fragments landing at
  // once must not take every channel of the mixer
  ArmorSoundGapTicks = 4;
  // The pings roll dice of their own: Random feeds the game
  ArmorPingSeed = $50696E67; // "Ping"
  CannonSeed = $43616E6E; // "Cann"

  // The 2008 GL loader displayed a 90-degrees-clockwise atlas correctly
  // (see Render.Font header). If F shows readable glyphs already upright,
  // switch to faUpright - or point FontFileName at the other font file.
  FontOrientation = faRotatedCw;
  // Nearest keeps the hard stepped edge the 2008 font is recognised by;
  // side by side in play, linear bought no visible clarity in exchange.
  FontFiltering = ffNearest;

  // Scancodes beyond Sdl2.Core's basic set
  ScancodeA = 4;
  ScancodeD = 7;
  ScancodeS = 22;
  ScancodeW = 26;

{$IFDEF DEBUGKEYS}
  // The developer keyboard. The numpad carries the two tuners: the
  // minigun muzzle on the arrow cluster (4/6/8/2, +/-), the retired
  // crosshair calibrator on the corners (7/9/1/3).
  ScancodeB = 5;  // trailer frame, bare sky (menu only)
  ScancodeF = 9;  // raw font atlas view (orientation check)
  ScancodeG = 10; // summon the defensive aura on the hero
  ScancodeH = 11; // pour the fire rain over the hero's screen
  ScancodeJ = 13; // the henshin at once: no boss, no countdown
  ScancodeK = 14; // the suit shed at once: the ring of orbs, suit or none
  ScancodeL = 15; // the burst at once on the hero: no rite, no suit
  ScancodeM = 16; // music mute toggle (trailer capture)
  ScancodeN = 17; // cycle the font filtering (redrawn atlas only)
  ScancodeP = 19; // every screen's tiles as pictures, for repainting
  ScancodeR = 21; // rebuild the pad group of the hero's screen
  ScancodeT = 23; // tile inspector in the window title
  ScancodeU = 24; // the burst at once in the moon's look: no rite, no suit
  ScancodeV = 25; // trailer frame, centered logo (menu only)
  ScancodeY = 28; // fly the pad group of the hero's screen back to its places
  ScancodePageUp = 75; // browse screens
  ScancodePageDown = 78;
  ScancodeEnd = 77; // straight to the screen being built, with its music
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
{$ENDIF}

// Every player-facing string lives in lang\*.json now (part 6): the
// S-keys moved to Localization, call sites fetch them through Tr().
resourcestring
  SSpriteSetMissing = 'Level "%s": declared sprite set "%s" not found';
  SAmbiguousSprites =
    'Level "%s": these sprite names live in more than one declared set.' +
    sLineBreak + 'Qualify them in the palette as set:name.' + sLineBreak +
    '  %s';

const
  // Screen-shake doses (2026 addition), in trauma shares - see
  // Render.Shake for the meter. One exploder is a nudge, a chain of
  // them climbs; the boss's two blasts open at the ceiling. The
  // ceremony's own doses live with it in Game.Henshin.
  ExploderTrauma = 0.4;       // barrel, tank, mount, platform
  BossBlastTrauma = 1.0;      // rage wave and the death double fan
  BonusExplosionTrauma = 0.7; // the bottle-and-fan reward
  AftershockTrauma = 0.3; // each pop of the boss's wreck
  BossCrashTrauma = 0.6; // the boss's ram ending in a wall
  CannonBlastTrauma = 0.8; // the two wall cannons blowing up together
  DupletShotTrauma = 0.2; // every shot of the Duplet: the kick of the stock
  // The smoke of the cannons' blast hangs over the room about this long:
  // nothing flies in through it and no gravel falls into it
  CannonSmokeTicks = 50;

  // Campaign-end screen layout, in Render.Font grid steps
  EndingTextColumn = 3;    // farewell prose column (small font)
  EndingTextFirstRow = 7;  // first prose row (small line steps)
  EndingAuthorRow = 14;    // clickable big lines, centered
  EndingMenuRow = 17;
  EndingClickRows = 2;     // click band height of a big line

constructor TMoonGame.Create(const AMonsters: TMonsterRegistry;
  const ARenderer: PSdlRenderer; const AWindow: PSdlWindow;
  const ALevels: TArray<TLevelChoice>; const AConfig: TGameConfig);
begin
  inherited Create;
  FMonsters := AMonsters;
  FWindow := AWindow;
  FRenderer := ARenderer;
  FFullscreen := AConfig.Fullscreen;
  FLevels := ALevels;
  FDifficulty := AConfig.Difficulty;

  // Level-independent subsystems live for the whole process; everything
  // bound to a particular level - including the tile cache, now that it
  // resolves through the level's sprite sets - is born inside LoadLevel.
  FLevelSets := TObjectList<TSpriteSet>.Create(True);
  if FileExists(SpriteSetsDir + 'ui.mset') then
    FUiSet := TSpriteSet.Create(SpriteSetsDir + 'ui.mset');
  if FileExists(SpriteSetsDir + 'weapon.mset') then
    FWeaponSet := TSpriteSet.Create(SpriteSetsDir + 'weapon.mset');
  FSprites := TSpriteRenderer.Create(ARenderer, FrameWidth, FrameHeight);
  FMonsterBullets := TBurst.Create(ARenderer, 'bull');
  FFont := TMoonFont.Create(ARenderer, FontFileName, FontOrientation,
    FUiSet);
  FFont.Filtering := FontFiltering;
  FMessages := TMessageBoard.Create(FFont, ARenderer, FrameWidth);
  FBriefing := THudBriefing.Create(FFont, ARenderer, FrameWidth);
  FShake := TScreenShake.Create;
  FExplosions := TExplosions.Create(ARenderer, SolidUnderPoint,
    EchoAftershock);
  FBlasts := TObjectList<TBlast>.Create(True);
  FImpacts := TImpacts.Create(SolidUnderPoint);
  FArrivals := TArrivals.Create;
  FCannonArt := TCannonArt.Create(ARenderer);
  FCannons := TCannonPair.Create(FCannonArt, CannonSeed);
  FOrbs := CreateOrbs;
  FTrial := TGravelTrial.Create;
  FPress := TPress.Create;
  FArmorPings.Dice.Seed := ArmorPingSeed;
  FAudio := TSoundBank.Create(SoundsDir, MusicDir);
  PreloadSounds;
  FVictory.Channel := -1;
  FVictoryLeft := NoVictoryLeft;

  FMenu := TMoonMenu.Create(ARenderer, FSprites, FFont, ALevels,
    FUiSet, FWeaponSet);
  FMenu.Difficulty := FDifficulty;
  FState := gsMenu;
  FResumeState := gsMenu;
  FAudio.PlayMusic(MenuMusicFile, mmLoop); // moon.ogg of 2008 (1857)
end;

destructor TMoonGame.Destroy;
begin
  FMenu.Free;
  // Before the bank: it stops what it holds
  FScenes.Free;
  FAudio.Free;
  FMarks.Free;
  FGoRight.Free;
  FEnergyGauge.Free;
  FShake.Free;
  FOrbs.Free;
  FImpacts.Free;
  FArrivals.Free;
  // The pair before its art
  FCannons.Free;
  FCannonArt.Free;
  FBlasts.Free;
  FExplosions.Free;
  FMessages.Free;
  FBriefing.Free;
  FFont.Free;
  FVitals.Free;
  FCharge.Free;
  FHenshin.Free;
  FTrial.Free;
  FPress.Free;
  // Before the shroud, which they feed
  FSpherePainter.Free;
  FSphere.Free;
  FUptakePainter.Free;
  FUptake.Free;
  FShroudPainter.Free;
  FShroud.Free;
  FDirector.Free;
  FArena.Free;
  FField.Free;
  FMonsterBullets.Free;
  FHero.Free;
  FDynamics.Free;
  FObjects.Free;
  FPads.Free;
  FTiles.Free;
  FSprites.Free;
  FObjectCache.Free;
  FBackgroundCache.Free;
  FTileCache.Free;
  FLevelSets.Free;
  FUiSet.Free;
  FWeaponSet.Free;
  FLevel.Free; // owned here since the menu became the level picker
  inherited;
end;

// The dice of the pads' rebuilds, new for every try at a level. Not
// Random: that one feeds the boss's spawn table.
function RollDiceSeed: Cardinal;
begin
  Result := Cardinal(SDL_GetPerformanceCounter);
end;

// The 2008 StartLevel: tear down whatever level was running, build the
// next one, reset every per-run counter. RestartLevel stays the light
// version for death - it keeps the level, this one replaces it.
procedure TMoonGame.LoadLevel(const AFileName: string);
begin
  // Before the level: what it plays and darkens goes with it
  FreeAndNil(FScenes);
  FField.Free;
  FHero.Free;
  FDynamics.Free;
  FObjects.Free;
  FPads.Free;
  FTiles.Free;
  FObjectCache.Free;
  FBackgroundCache.Free;
  FTileCache.Free;
  FLevel.Free;
  FField := nil;
  FHero := nil;
  FDynamics := nil;
  FObjects := nil;
  FPads := nil;
  FTiles := nil;
  FObjectCache := nil;
  FBackgroundCache := nil;
  FTileCache := nil;
  FLevelSets.Clear; // caches are gone, the sets may follow

  FLevel := TLevel.Create;
  FLevel.LoadFromFile(AFileName);
  FLevelFile := AFileName; // AdvanceToNextLevel keys off this
  // A name the game does not know raises here, not mid-boss
  var PatternName := FLevel.HenshinPattern;
  if PatternName = '' then
    PatternName := DefaultPatternName;
  var Pattern := FindPattern(PatternName);

  FTileCache := TSpriteCache.Create(FRenderer);
  for var SetName in FLevel.SpriteSets do
    FTileCache.AttachSpriteSet(OpenSpriteSet(SetName));

  // Two declared sets sharing a sprite name still resolve - first wins -
  // but silently, so that reordering the declaration would change a
  // picture without changing a palette. Refuse to start instead: the
  // palette should say 'common:pustota' and mean it.
  var Ambiguous := FTileCache.AmbiguousNames(FLevel.TilePalette);
  if Length(Ambiguous) > 0 then
    raise ELevelError.CreateFmt(SAmbiguousSprites,
      [FLevel.Id, string.Join(sLineBreak + '  ', Ambiguous)]);

  FBackgroundCache := TSpriteCache.Create(FRenderer);
  FBackgroundCache.DisableColorKey;
  FBackgroundCache.EnableLinearFilter;
  FBackgroundCache.AttachSpriteSet(OpenLevelArtSet('backdrops'));
  FTiles := TTileScreenRenderer.Create(FSprites, FTileCache,
    FBackgroundCache, FLevel);

  FObjectCache := TSpriteCache.Create(FRenderer);
  FObjectCache.DisableColorKey;
  FObjectCache.EnableLinearFilter;
  // The level's own objects set comes first; a level whose art is all
  // shared ships none
  if FileExists(LevelArtSetFile('objects')) then
    FObjectCache.AttachSpriteSet(OpenLevelArtSet('objects'));
  for var SetName in FLevel.ObjectSets do
    FObjectCache.AttachSpriteSet(OpenSpriteSet(SetName));
  FObjects := TObjectScreenRenderer.Create(FSprites, FObjectCache, FLevel);
  // Before the dynamics: their parents may be pads
  FPads := TPadWorld.Create(FSprites, FObjectCache, FLevel, JumpReach,
    RollDiceSeed);
  var World: TDynamicWorld;
  World.LocateParent := LocateParent;
  World.Solid := SolidUnderPoint;
  World.BackdropOf := FTiles.Backdrop;
  FDynamics := TDynamicScreenRenderer.Create(FRenderer, FLevel, FObjectCache,
    World);

  FHero := THero.Create(FRenderer, FLevel, FPads);
  FreeAndNil(FSpherePainter);
  FreeAndNil(FSphere);
  FreeAndNil(FUptakePainter);
  FreeAndNil(FUptake);
  FreeAndNil(FShroudPainter);
  FreeAndNil(FShroud);
  FShroud := THeroShroud.Create(SolidUnderPoint, RollDiceSeed);
  FShroudPainter := TShroudPainter.Create(FRenderer, FHero, FShroud);
  FUptake := TUptake.Create(SolidUnderPoint, FShroud.Feed, RollDiceSeed);
  FUptakePainter := TUptakePainter.Create(FRenderer, FUptake);
  FSphere := TLifeSphere.Create(FShroud.Feed, RollDiceSeed);
  FSpherePainter := TLifeSpherePainter.Create(FSphere);
  FreeAndNil(FHenshin);
  var Stage: THenshinStage;
  Stage.Hero := FHero;
  Stage.Audio := FAudio;
  Stage.Messages := FMessages;
  Stage.Shake := FShake;
  Stage.Shroud := FShroud;
  Stage.Rite := FOrbs.Rite;
  Stage.Burst := FOrbs.Burst;
  var Calls: THenshinCalls;
  Calls.Cure := CureHero;
  Calls.GrantMercy := GrantMercy;
  Calls.BeginRite := FOrbs.BeginRite;
  Calls.ShedSuit := FOrbs.ShedSuit;
  Calls.Burst := FOrbs.BurstSuit;
  FHenshin := THenshin.Create(Stage, Calls);
  FField := TMonsterField.Create(FRenderer, FMonsters, FLevel, FPads,
    FDifficulty, DifficultyMonsterLives[FDifficulty]);
  WarmPickupPictures;
  CreateHud;
  FreeAndNil(FArena);
  FArena := TPadArena.Create(FPads, FLevel.Dynamics, FLevel.PadGroups,
    HeroRides);
  FScenes := TSceneDirector.Create(FLevel.Scenes, FLevel.Dynamics, FPads,
    FAudio, FMessages);
  FreeAndNil(FDirector);
  var Cues: TDirectorCues;
  Cues.ChangeMusic := ChangeMusic;
  Cues.Arena.Engage := FArena.Engage;
  Cues.Arena.Restore := FArena.Restore;
  Cues.Arena.FlyIn := FlyInParked;
  Cues.Shelves := TellShelves;
  Cues.BreakCarousel := BreakCarousel;
  Cues.Strays := LetStraysGo;
  Cues.StraysLeave := SendStraysAway;
  Cues.MedkitsOnto := SendMedkitsOnto;
  Cues.WaveOnto := SendWaveOnto;
  Cues.Cannons := StartCannons;
  Cues.Spawn := SpawnGuest;
  Cues.SkyFall := OpenSky;
  Cues.Press := StartPress;
  Cues.StartScene := FScenes.Start;
  // A function without parameters named alone would be called, not
  // passed: the reference wraps it
  Cues.TrialAct :=
    function: Integer
    begin
      Result := TrialAct;
    end;
  Cues.TrialProgress :=
    function: TTrialProgress
    begin
      Result := FTrial.Progress;
    end;
  Cues.TrialDone :=
    function: Boolean
    begin
      Result := FTrialDone;
    end;
  Cues.VictoryLeft :=
    function: Single
    begin
      Result := FVictoryLeft;
    end;
  // Through the field, not its method: the HUD is reborn with the level
  Cues.GoRight :=
    procedure
    begin
      FGoRight.Show;
    end;
  // Open = the arrow: one action of the level says both
  Cues.OpenDoor :=
    procedure
    begin
      FDoorOpened := True;
      FGoRight.Show;
    end;
  Cues.HeroStands := HeroStandsIn;
  Cues.Energy := FOrbs.FeedEnergy;
  Cues.Respawn := MoveCheckpoint;
  Cues.Sphere := FormSphere;
  Cues.SphereTaken :=
    function: Boolean
    begin
      Result := FSphere.Taken;
    end;
  FDirector := TEventDirector.Create(FLevel.Events, FMessages,
    FLevel.Dynamics, Cues);

  FMonsterBullets.Clear;
  FExplosions.Clear;
  FBlasts.Clear;
  FImpacts.Clear;
  FArrivals.Clear;
  FCannons.Clear;
  FOrbs.BeginLevel(Pattern);
  FMessages.Clear;
  StopVictoryTrack;
  FHeroHealth := DifficultyHeroHealth[FDifficulty]; // moon.dpr 1714-1716
  FHurtCooldown := 0;
  FCheckpointX := FHero.X;
  FCheckpointY := FHero.Y;
  // Stale-flag hygiene 2008 never had: StartLevel did not reset
  // GravelAttack - a latent bug that could not fire only because death
  // led to the menu. With checkpoint respawn it would be a softlock.
  FTrial.Stop;
  FMedkitBank := '';
  FWaveMonster := '';
  FWaveBank := '';
  FTrialDone := False;
  FDoorOpened := False;
  FPress.Shut;
  FSkyMonster := '';
  FHeldFlyIns := [];
  FCannonSmoke := 0;
  FEndLevelTimer := 0;
  FScore := 0;
  FKillStreak := 0;
  FStreakBonusCount := 0;
  FBonus := bkNone;
  FBonusActivateQueued := False;
  FTriggerFired := nil;
  SetLength(FTriggerFired,
    Length(FLevel.Entities) + Length(FLevel.ScreenTriggers));

  FLevelLoaded := True;
  FMenu.HasActiveGame := True;

  if FLevel.IntroText.Current <> '' then
  begin
    FBriefing.Start(Tr(SBriefingHeader), FLevel.IntroText.Current);
    FState := gsIntro;
  end
  else
    StartPlaying;
end;

// A set the level names. An absent one is a broken install, not a
// fallback case - the fallback exists for names, not for whole sets.
// The set joins FLevelSets, which owns it.
function TMoonGame.OpenSpriteSet(const ASetName: string): TSpriteSet;
begin
  var SetFile := SpriteSetsDir + ASetName + '.mset';
  if not FileExists(SetFile) then
    raise ELevelError.CreateFmt(SSpriteSetMissing, [FLevel.Id, ASetName]);

  Result := TSpriteSet.Create(SetFile);
  FLevelSets.Add(Result);
end;

// Backdrops and objects follow the level by convention rather than by
// declaration: one set per assetsDir and kind, named after both
function TMoonGame.LevelArtSetFile(const AKind: string): string;
begin
  Result := SpriteSetsDir + FLevel.AssetsDir + '-' + AKind + '.mset';
end;

function TMoonGame.OpenLevelArtSet(const AKind: string): TSpriteSet;
begin
  Result := OpenSpriteSet(FLevel.AssetsDir + '-' + AKind);
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
  FHeldDown := False;
  FHeldFire := False;
  // The current track keeps playing under the farewell - the 2008 exit
  // was silence via GameFree; a track feels kinder (tweak on review)
end;

procedure TMoonGame.DrawCenteredBig(const AText: string; ARow: Integer);
begin
  FFont.DrawBig(AText, (FrameWidth - FFont.BigTextWidth(AText)) / 2,
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
  var Left := (FrameWidth - FFont.BigTextWidth(AText)) / 2;
  Result := (FMouseGX >= Left) and
    (FMouseGX <= Left + FFont.BigTextWidth(AText)) and
    (FMouseGY >= ATopRow * SmallLineStep) and
    (FMouseGY <= (ATopRow + EndingClickRows) * SmallLineStep);
end;

procedure TMoonGame.HandleEndingClick;
begin
  if HitEndingLine(Tr(SEndingAuthor), EndingAuthorRow) then
  begin
    // The browser must land in a visible window - fullscreen drops
    // first. SetFullscreen, not ToggleFullscreen: the player did not
    // choose windowed, and the next run must not remember it
    SetFullscreen(False);
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
  FHeldDown := False;
  FHeldFire := False;
  FMenu.ShowMain;
  // Level music keeps playing under the menu - verbatim 2008 behavior.
  // The victory track is a sound of the world: it waits, or the events
  // timed to its end would come late
  if FScenes <> nil then
    FScenes.Pause;
  FAudio.PauseHeld(FVictory);
end;

// Back from the menu to where Escape came from; a scene waits there
procedure TMoonGame.ResumeGame;
begin
  FState := FResumeState;
  if FState <> gsPlaying then
    Exit;
  if FScenes <> nil then
    FScenes.Resume;
  FAudio.ResumeHeld(FVictory);
end;

procedure TMoonGame.SetFullscreen(AValue: Boolean);
begin
  FFullscreen := AValue;
  if FFullscreen then
    SDL_SetWindowFullscreen(FWindow, SdlWindowFullscreenDesktop)
  else
    SDL_SetWindowFullscreen(FWindow, 0);
end;

procedure TMoonGame.ToggleFullscreen;
begin
  SetFullscreen(not FFullscreen);
  SaveWindowFullscreen(UserSettingsFileName, FFullscreen);
end;

procedure TMoonGame.ApplyMenuResult(const AResult: TMenuResult);
begin
  case AResult.Command of
    mcStartLevel:
      LoadLevel(AResult.LevelFile);
    mcResume:
      ResumeGame;
    mcToggleFullscreen:
      ToggleFullscreen;
    mcSetDifficulty:
      begin
        // Takes effect where the field is reborn: level load or restart
        // (2008 applied per screen - see the menu hint deviation)
        FDifficulty := AResult.Difficulty;
        SaveGameDifficulty(UserSettingsFileName, FDifficulty);
      end;
    mcSetLanguage:
      begin
        // Dictionary first, THEN the menu: the Language setter rebuilds
        // captions through Tr and must read the new words. Menu and HUD
        // switch live; level texts follow on the next load (part 6.3).
        LoadLanguage(AResult.Language);
        SaveGameLanguage(UserSettingsFileName, AResult.Language);
        FMenu.Language := AResult.Language;
      end;
    mcQuit:
      RequestQuit;
  end;
end;

// A new level starts with a fresh HUD: no animation carried over from
// the last one, the charge empty along with the score
procedure TMoonGame.CreateHud;
begin
  FreeAndNil(FVitals);
  FreeAndNil(FCharge);
  FreeAndNil(FMarks);
  FreeAndNil(FGoRight);
  FreeAndNil(FEnergyGauge);
  FVitals := THudVitals.Create(FRenderer);
  FCharge := THudCharge.Create(FRenderer, FrameWidth);
  FMarks := THudMarks.Create(FRenderer);
  FGoRight := THudGoRight.Create(FRenderer);
  FEnergyGauge := THudEnergy.Create(FRenderer);
end;

// The checkpoint on the cell ACol, ARow, columns and rows from 1 as a
// placement's: the hero's corner and feet line, as THero.PlaceAtCell
// puts the start. The hero himself is not moved.
procedure TMoonGame.MoveCheckpoint(ACol, ARow: Integer);
begin
  FCheckpointX := (ACol - 1) * TileSize;
  FCheckpointY := ARow * TileSize;
end;

// The level's respawn point of the hero's screen becomes the
// checkpoint: it has the last word, over the entry point of 2008 and
// over what a heroX / heroY trigger wrote. A screen without one keeps
// those. The hero himself is not moved.
procedure TMoonGame.PinRespawnPoint;
var
  Point: TRespawnPoint;
begin
  if not FLevel.TryFindRespawn(FHero.Screen, Point) then
    Exit;
  MoveCheckpoint(Point.X, Point.Y);
end;

// The hero has just landed on a new screen: pin the checkpoint - the
// landing spot or, when the level names one, the screen's respawn point;
// pits and death return there -, drop what never crosses a door - bullets
// (verbatim moon.dpr 1089-1090: no shooting backwards through it) and
// the positional popups - then greet the arrival. Triggers fire even
// for a debug browse ('no fire rain' of review round five).
procedure TMoonGame.ArriveOnScreen;
begin
  FCheckpointX := FHero.X;
  FCheckpointY := FHero.Y;
  FOrbs.Arrive;
  FHero.Bullets.Clear;
  FMonsterBullets.Clear;
  FExplosions.Clear;
  FBlasts.Clear;
  FImpacts.Clear;
  FArrivals.Clear;
  FCannons.Clear;
  FUptake.Settle;
  SettleSphere;
  FShroud.LeaveMotes;
  FMessages.ClearPopups;
  FGoRight.Hide;
  FDoorOpened := False;
  FireScreenTriggers;
  PinRespawnPoint;
end;

procedure TMoonGame.HandleScreenTransitions;
const
  // Verbatim moon.dpr 1071-1073: the door sits at x > 512-33
  RightDoorX = ScreenWidth - 33;
begin
  if FHero.X < 2 then
    FHero.SetScreenX(2); // no way back - the 2008 doors open one way
  if FHero.X <= RightDoorX then
    Exit;

  // Transition blocked while the gravel trial runs, while the level
  // keeps the door shut and for the dead; land at x=4 - ArriveOnScreen
  // pins the checkpoint
  var DoorShut := FLevel.DoorShutOn(FHero.Screen) and not FDoorOpened;
  if not FTrial.Active and not DoorShut and not FHero.Dead then
  begin
    if FHero.Screen < FLevel.ScreenCount then
    begin
      var LeftX := FHero.X;
      var LeftY := FHero.Y;
      FHero.Screen := FHero.Screen + 1;
      FHero.SetScreenX(4);
      // The rite crosses by the door's step before the new screen is
      // greeted: a trigger there may begin a rite of its own, and that
      // one has crossed nothing. A trigger that moves the hero is a leap
      // to the rite, and it knows leaps.
      FOrbs.CarryRite(FHero.X - LeftX, FHero.Y - LeftY);
      ArriveOnScreen;
      // The aura crosses with him, by the door's step and that of a
      // trigger of the new screen: a leap would fly the orbs after him
      FOrbs.CarryAura(FHero.X - LeftX, FHero.Y - LeftY);
      Exit;
    end;
    if CurrentLevelIsLast then
    begin
      // The 2008 door out of the last screen called GameFree - the game
      // ENDED by walking out. Same door, kinder farewell (part 5.4).
      BeginEnding;
      Exit;
    end;
  end;

  // A closed door is a wall. Refusing only the transition let the hero
  // walk on past x=512 - on the gravel screen through the floor-level
  // gap in the right wall, into off-grid air and down the pit. He waits
  // at the threshold until the breakthrough opens the door; the last
  // screen of a mid-campaign level stays closed, its exit is the boss.
  FHero.SetScreenX(RightDoorX);
end;

// 'Падаем в лунку' verbatim: the pit returns the hero to the
// checkpoint and takes one life. In 2008 the checkpoint was the screen's
// entry point alone; a level's respawn point now comes first - a named
// deviation: a hero who entered a screen falling into its pit fell
// there again and again, to his death and after it.
procedure TMoonGame.HandlePitFall;
begin
  if (FHero.Y > PitDepthY) and not FHero.Dead then
  begin
    FHero.SetScreenX(FCheckpointX);
    FHero.SetY(FCheckpointY);
    FShroud.Start(PitLook);
    FMessages.AddTicker(Tr(SFellIntoPit), TickerPitTicks);
    FAudio.Play(PitSoundFile); // the pit plays down.wav, not pain (780)
    HurtHero;
  end;
end;

// Entity and screen triggers of the CURRENT screen: location titles,
// captions and tutorial hints. Each fires once per game - a hint that nags
// on every backtrack stops being a hint. The 2008 '_string:' hints ran as a
// marquee; here they type out in the comm terminal.
procedure TMoonGame.FireScreenTriggers;
begin
  for var i := 0 to High(FLevel.Entities) do
    FireTriggersOf(i, FLevel.Entities[i].Screen, FLevel.Entities[i].Grades,
      FLevel.Entities[i].Triggers);
  for var i := 0 to High(FLevel.ScreenTriggers) do
    FireTriggersOf(Length(FLevel.Entities) + i, FLevel.ScreenTriggers[i].Screen,
      FLevel.ScreenTriggers[i].Grades, FLevel.ScreenTriggers[i].Triggers);
end;

// AIndex - the place of the trigger in FTriggerFired
procedure TMoonGame.FireTriggersOf(AIndex, AScreen: Integer;
  AGrades: TDifficultyGrades; const ATriggers: TEntityTriggers);
begin
  if AScreen <> FHero.Screen then
    Exit;
  if FTriggerFired[AIndex] then
    Exit;

  // A trigger filtered out by the difficulty grade is silent - a
  // hard-only trial must not arm on normal
  if not (FDifficulty in AGrades) then
    Exit;
  if (ATriggers.BigMessage.Current = '') and
     (ATriggers.SmallMessage.Current = '') and
     (ATriggers.HintText.Current = '') and
     (ATriggers.ChangeMusic = '') and
     not ATriggers.HasHeroX and not ATriggers.HasHeroY and
     not ATriggers.HasGravelBoss then
    Exit;

  FTriggerFired[AIndex] := True;
  FMessages.ShowBig(ATriggers.BigMessage.Current, BigMessageTicks);
  FMessages.AddTicker(ATriggers.SmallMessage.Current, TickerNoticeTicks);
  FMessages.StartTerminal(Tr(STerminalHeader), ATriggers.HintText.Current);
  // The changeMusic field of level JSON waited since part 1 for a
  // player to exist - here it is (empty name is a no-op inside)
  ChangeMusic(ATriggers.ChangeMusic);
  // 'Сменить X/Y герою' of 2008 (884-898): the trigger relocates the
  // hero by CELL number (value*32, no off-by-one - raw as the original
  // did it) and writes the checkpoint for its axis. Death and pits now
  // return to the tunnel entrance, not to the start of the level.
  // SetY drops into a fall - no standing on air (deviation 5).
  if ATriggers.HasHeroX then
  begin
    FHero.SetScreenX(ATriggers.HeroX * TileSize);
    FCheckpointX := FHero.X;
    // A heroY of the same screen may have already settled the hero
    // at an intermediate X where the ground verdict was meaningless
    // (screen 7 pairs them) - settle again at the final spot
    FHero.SettleOnGround;
  end;
  if ATriggers.HasHeroY then
  begin
    FHero.SetY(ATriggers.HeroY * TileSize);
    FCheckpointY := FHero.Y;
  end;
  // 'Атака грейвелов' (955-971): one message armed BOTH the gravel
  // rain and the transformation, and the ceremony fired INSTANTLY.
  // Verbatim: no countdown here - the first wave of orbs must open the
  // scene; the 3..2..1 prelude stays boss-only.
  if ATriggers.HasGravelBoss then
  begin
    // The batch of one act lives in the level JSON, split by difficulty
    // there (15/25/40 for level2) - the game only picks its grade; so
    // does the count of the wave the trial may end in
    FWaveMonster := '';
    if ATriggers.HasFinale then
    begin
      FWaveMonster := ATriggers.Finale.MonsterId;
      FTrial.Start(ATriggers.GravelBatch.ForGrade(FDifficulty),
        ATriggers.Finale.Count.ForGrade(FDifficulty), ATriggers.Finale.Alive);
    end
    else
      FTrial.Start(ATriggers.GravelBatch.ForGrade(FDifficulty));
    FGravelScreen := FHero.Screen;
    FHenshin.Start;
  end;
end;

function TMoonGame.LetDownFromSky(const AMonsterId: string;
  ALook: TArrivalLook): TMonster;
begin
  Result := FField.SpawnFromSky(AMonsterId, FGravelScreen);
  FArrivals.Add(Result.X + SpriteSize / 2, ALook);
end;

// A gravel of the trial back from the side or the pit, in the violet
// light, to walk off whichever way the dice say
procedure TMoonGame.ArriveAgain(AGravel: TMonster);
begin
  FArrivals.Add(AGravel.X + SpriteSize / 2);
  AGravel.HeadRandomly;
end;

// Over a shelf of the bank an event named, when one did - the hero has
// to climb for it
procedure TMoonGame.LetDownMedkit;
var
  ShelfX: Double;
begin
  if not FPads.TryPickBankMiddle(FMedkitBank, ShelfX) then
  begin
    LetDownFromSky(MedkitMonsterId);
    Exit;
  end;
  var Column := Trunc(ShelfX / SpriteSize);
  var Born := FField.SpawnFromSkyOver(MedkitMonsterId, FGravelScreen, Column);
  FArrivals.Add(Born.X + SpriteSize / 2);
end;

// The half of the room with fewer bodies of the wave alive: below 0 the
// left, above 0 the right, 0 when they are even
function TMoonGame.WaveSideWanted: Integer;
begin
  Result := 0;
  for var Monster in FField.Monsters do
  begin
    if (Monster.Screen <> FGravelScreen) or (Monster.Life <> mlAlive) or
      (Monster.Def.Id <> FWaveMonster) then
      Continue;
    if Monster.X + SpriteSize / 2 < ScreenWidth / 2 then
      Inc(Result)
    else
      Dec(Result);
  end;
end;

// Over a shelf of the bank an event named, on the side with fewer of the
// wave; anywhere when it named none. The bank may be the press's top row.
procedure TMoonGame.LetDownWave(AHerald: Boolean);
var
  ShelfX: Double;
begin
  var Look := alPlain;
  if AHerald then
    Look := alHerald;
  // The press brings its top row out for the newcomer, and waits for it
  TellPress(FPress.Arrive(FWaveBank));
  if not FPads.TryPickBankMiddle(FWaveBank, WaveSideWanted, ShelfX) then
  begin
    LetDownFromSky(FWaveMonster, Look);
    Exit;
  end;
  var Column := Trunc(ShelfX / SpriteSize);
  var Born := FField.SpawnFromSkyOver(FWaveMonster, FGravelScreen, Column);
  FArrivals.Add(Born.X + SpriteSize / 2, Look);
end;

// The column over the middle of the hero, kept inside the walls of the
// room
function TMoonGame.HeroColumn: Integer;
const
  FirstColumn = 1;
  LastColumn = ScreenCols - 2;
begin
  Result := Trunc(HeroCenter.X / SpriteSize);
  if Result < FirstColumn then
    Result := FirstColumn
  else if Result > LastColumn then
    Result := LastColumn;
end;

function TMoonGame.TrialAct: Integer;
begin
  Result := 0;
  if FTrial.Active then
    Result := FTrial.Act;
end;

// The order from the farthest shelf to the hero reads where he stands
// now
procedure TMoonGame.TellShelves(const AAction: TEventAction);
var
  Command: TShelfCommand;
begin
  Command := Default(TShelfCommand);
  Command.Call := scWake;
  if AAction.Kind = eaShelvesSleep then
    Command.Call := scSleep;
  Command.Run := AAction.Shelves;
  Command.SpareHero := AAction.SpareHero;
  FPads.TellBank(AAction.Target, Command, AAction.Telling, HeroCenter.X);
end;

procedure TMoonGame.BreakCarousel(const ATag: string;
  const ABreakdown: TCarouselBreak);
begin
  FPads.TryBreakCarousel(ATag, ABreakdown.HaltSeconds, ABreakdown.StepSeconds);
end;

procedure TMoonGame.LetStraysGo(const AFlock: string);
begin
  FPads.TryLaunchFlock(AFlock);
end;

procedure TMoonGame.SendStraysAway(const AFlock: string);
begin
  FPads.TryDismissFlock(AFlock);
end;

// The level lets no tag name both a carousel and a pad group. Told while
// the cannons blow themselves up, the pads wait for the smoke to clear.
procedure TMoonGame.FlyInParked(const ATag: string);
begin
  if CannonsScenePlays then
  begin
    FHeldFlyIns := FHeldFlyIns + [ATag];
    Exit;
  end;
  if not FPads.TryFlyInCarousel(ATag) then
    FArena.FlyIn(ATag);
end;

function TMoonGame.CannonsScenePlays: Boolean;
begin
  Result := FCannons.Leaving or (FCannonSmoke > 0);
end;

procedure TMoonGame.ReleaseHeldFlyIns;
begin
  if FCannonSmoke > 0 then
    Dec(FCannonSmoke);
  if CannonsScenePlays then
    Exit;
  var Held := FHeldFlyIns;
  FHeldFlyIns := [];
  for var Tag in Held do
    FlyInParked(Tag);
end;

procedure TMoonGame.SendMedkitsOnto(const ABank: string);
begin
  FMedkitBank := ABank;
end;

procedure TMoonGame.SendWaveOnto(const ABank: string);
begin
  FWaveBank := ABank;
end;

// The press is the act's, as the sky is: once that act is over it stays
// shut
procedure TMoonGame.StartPress(const AOrders: TPressOrders; AAct: Integer);
begin
  if TrialAct <> AAct then
    Exit;
  FPress.Start(AOrders.Rows, PressBeatTicks(AOrders.EverySeconds));
end;

procedure TMoonGame.TellPress(const ACall: TPressCall);
begin
  for var Bank in ACall.Sleep do
    TellPressRow(Bank, scSleep);
  for var Bank in ACall.Wake do
    TellPressRow(Bank, scWake);
end;

// No mercy on the press: a row goes in under the hero too - the row under
// him has just come out
procedure TMoonGame.TellPressRow(const ABank: string; ACall: TShelfCall);
var
  Command: TShelfCommand;
begin
  Command := Default(TShelfCommand);
  Command.Call := ACall;
  Command.Run.Kind := pgHold;
  FPads.TellBank(ABank, Command, Default(TBankTelling), HeroCenter.X);
end;

// The act the event names, or the one the trial is in: a delayed event
// may fire after its act is over, and then the scene of the end plays at
// once
procedure TMoonGame.StartCannons(const AOrders: TCannonOrders; AAct: Integer);
begin
  var Act := AAct;
  if Act = 0 then
    Act := TrialAct;
  FCannons.Start(AOrders, Act);
end;

// The body belongs to the act the event waits for: once that act is over
// there is no one to let in
procedure TMoonGame.SpawnGuest(const AOrders: TSpawnOrders; AAct: Integer);
begin
  if TrialAct <> AAct then
    Exit;
  FField.SpawnInLane(AOrders, FGravelScreen);
end;

// The sky is the act's, as a guest is: once that act is over it stays shut
procedure TMoonGame.OpenSky(const AOrders: TSkyFall; AAct: Integer);
begin
  if TrialAct <> AAct then
    Exit;
  FSkyMonster := AOrders.MonsterId;
  FTrial.OpenSky(AOrders.EverySeconds);
end;

// A tick of the gravel trial, called every tick while it runs - even over
// the hero's corpse, like the rest of the timer. Game.Trial holds the
// rules; here its cue is carried out on the field. Once the last act is
// through, the breakthrough opens the right edge again.
procedure TMoonGame.TickGravelAttack;
begin
  if not FTrial.Active then
    Exit;

  for var Returned in FField.ReturnSideStrays(GravelMonsterId, FGravelScreen) do
    ArriveAgain(Returned);
  // A body of the wave out of the room would hold the gate forever: it
  // comes back as a gravel does
  if FWaveMonster <> '' then
    for var Returned in FField.ReturnSideStrays(FWaveMonster, FGravelScreen) do
      ArriveAgain(Returned);
  // Released before the room is asked: a carousel let in now is landing
  // this very tick, so the first wave sees no gap between the two
  ReleaseHeldFlyIns;
  FTrial.RoomBusy := CannonsScenePlays or (Length(FHeldFlyIns) > 0) or
    FPads.CarouselLanding;
  // A body an event let in holds the gate with the gravels: it waits for
  // the hero to kill it, so the leave at the gate finds no one alive
  var GateHolders := FField.CountAliveOf(GravelMonsterId, FGravelScreen) +
    FField.CountAliveGuests(FGravelScreen);
  // The wave holds the gate too; its cap is counted against its own
  // living alone, so a guest let in during the wave does not hold it back
  var WaveAlive := 0;
  if FWaveMonster <> '' then
    WaveAlive := FField.CountAliveOf(FWaveMonster, FGravelScreen);
  var Cue := FTrial.Tick(GateHolders + WaveAlive, WaveAlive);
  TellPress(FPress.Tick);
  // A gravel fallen into the pit comes down on the hero who dropped it,
  // and so does a body of the wave, should one fall out of the room
  if Cue.ReturnFromPit then
  begin
    var FromPit: TMonster;
    var Back := FField.TryReturnPitStray(GravelMonsterId, FGravelScreen,
      HeroColumn, FromPit);
    if not Back and (FWaveMonster <> '') then
      Back := FField.TryReturnPitStray(FWaveMonster, FGravelScreen, HeroColumn,
        FromPit);
    if Back then
      ArriveAgain(FromPit);
  end;
  // 2008 lets every monster down heading left; the trial's gravels go
  // either way, or they all pile up on the left
  if Cue.SpawnGravel and Cue.Herald then
    LetDownFromSky(GravelMonsterId, alHerald).HeadRandomly
  else if Cue.SpawnGravel then
    LetDownFromSky(GravelMonsterId).HeadRandomly;
  // The mark goes up over the hero; the gravel follows it there, wherever
  // he has gone meanwhile
  if Cue.MarkAimed then
  begin
    FAimedColumn := HeroColumn;
    FArrivals.Add(FAimedColumn * SpriteSize + SpriteSize / 2);
  end;
  if Cue.SpawnAimed then
    FField.SpawnFromSkyOver(GravelMonsterId, FGravelScreen, FAimedColumn).HeadRandomly;
  if Cue.SpawnWave then
    LetDownWave(Cue.Herald);
  if Cue.SpawnMedkit then
    LetDownMedkit;
  // The violet light marks the column a moment before the body shows
  if Cue.SkyFall then
    LetDownFromSky(FSkyMonster);
  if Cue.ActEnded then
  begin
    FField.DepartGuests(FGravelScreen);
    FPress.Shut;
  end;
  if not Cue.Finished then
    Exit;

  FTrialDone := True;
  FMessages.ShowBig(Tr(SBrokeThrough), BigMessageTicks);
  // The breakthrough shatter RINGS, unlike the silent level-complete
  // one: Snd_bottle right before the suit comes off, which is a ring of
  // orbs now, not the fan of 2008. The levelmass write before it
  // (391-392) is dropped: physics read the hero's and monsters' own
  // copies of the level string, so the write only split off a copy
  // nobody collided with.
  if FHero.HeroForm <> hfNormal then
    FAudio.Play(BottleSoundFile);
  FHenshin.RemoveIceForm;
  // The level goes on: no timer of its end, the events of the screen
  // take over at the end of the track. A restart brings back
  // FCurrentMusic, the trial's own track.
  PlayVictoryTrack;
end;

// As a sound, not as music: the music channel is left free for the next
// track to fade in over the end of this one
procedure TMoonGame.PlayVictoryTrack;
begin
  FAudio.StopMusic;
  FVictory := FAudio.PlayTrackHeld(VictoryMusicFile);
  FVictoryLeft := FAudio.SecondsOf(FVictory);
end;

procedure TMoonGame.StopVictoryTrack;
begin
  FAudio.StopHeld(FVictory);
  FVictory.Channel := -1;
  FVictoryLeft := NoVictoryLeft;
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

// A trigger's or an event's track: played now and remembered, so a
// restart respawns into it. '' is a no-op.
procedure TMoonGame.ChangeMusic(const AFileName: string; AFadeSeconds: Single);
begin
  if AFileName = '' then
    Exit;
  FCurrentMusic := AFileName;
  FAudio.PlayMusic(AFileName, mmLoop, AFadeSeconds);
end;

// The one rider a rebuild keeps out of the depth: monsters fall through
function TMoonGame.HeroRides(const APad: TPad): Boolean;
begin
  Result := APad = FHero.DeckUnderFeet;
end;

// A dynamic object hung on a pad or a monster looks it up here every
// tick. Levels.Defs has refused a tag both carry.
function TMoonGame.LocateParent(const ATag: string;
  out AStand: TParentStand): Boolean;
begin
  AStand := Default(TParentStand);
  var FailingLook: Boolean;
  var Pad := FPads.FindWearer(ATag, FailingLook);
  if Pad <> nil then
  begin
    AStand.Screen := Pad.Screen;
    AStand.X := Pad.Left;
    AStand.Y := Round(Pad.Top) + Pad.Lift(1);
    // A broken pad puts out its own rigs and lights those of its failing
    // look; a dormant pad has none lit
    AStand.Alive := (Pad.Failed = FailingLook) and not Pad.Dormant;
    // A pad working its jets lifts what hangs on it: flat out in a
    // flight and just before one, in fits when it is a pad that plunges;
    // a shelf lights it to warn that it is about to slide in
    AStand.Effort := Pad.Effort;
    // Into the depth as the picture of a flying pad goes: the same depth
    // at the two ticks, the same shrink and shade, about the same point.
    // A shelf slides in alone: what hangs on it stays in front.
    AStand.Depth.Sunk := Pad.RigDepth(1);
    AStand.Depth.LastSunk := Pad.RigDepth(0);
    AStand.Depth.Shrink := 1 - DeepScale;
    AStand.Depth.Dim := 1 - DeepTone;
    AStand.Depth.Pivot := Pad.Middle;
    Exit(True);
  end;
  for var Monster in FField.Monsters do
  begin
    if Monster.Tag <> ATag then
      Continue;
    AStand.Screen := Monster.Screen;
    // Where TMonster.Draw puts the sprite: the feet line is Y, lifted by
    // the deck underfoot
    AStand.X := Round(Monster.X);
    AStand.Y := Round(Monster.Y) - SpriteSize + Monster.DeckLift(1);
    // A body flying off the top keeps its jets: they lift it away
    AStand.Alive := (Monster.Life = mlAlive) or Monster.Leaving;
    AStand.Spins := Monster.Disc <> nil;
    if AStand.Spins then
    begin
      AStand.Spin.Pose.Center := Monster.Disc.Pose.Center;
      AStand.Spin.Pose.Angle := Monster.Disc.Pose.Angle;
      AStand.Spin.LastPose.Center := Monster.Disc.LastPose.Center;
      AStand.Spin.LastPose.Angle := Monster.Disc.LastPose.Angle;
      AStand.Spin.Axis.X := SpriteSize / 2;
      AStand.Spin.Axis.Y := SpriteSize / 2;
    end;
    Exit(True);
  end;
  Result := False;
end;

// What a scene acts on this tick: the field is reborn on every restart
function TMoonGame.SceneStage: TSceneStage;
begin
  Result.Hero.X := FHero.X + SpriteSize / 2;
  Result.Hero.Y := FHero.Y - SpriteSize / 2;
  Result.Field := FField;
  Result.Bullets := FMonsterBullets;
end;

// The solid layer debris and sparks ring off: the collision grid of the
// hero's screen and the bodies of its pads, the point in screen units
function TMoonGame.SolidUnderPoint(AX, AY: Single): Boolean;
begin
  Result := FLevel.SolidAtPoint(FHero.Screen, AX, AY) or
    FPads.BodyAt(FHero.Screen, AX, AY);
end;

// bottle.wav is what a barrel dies with: the pops are barrel blasts
procedure TMoonGame.EchoAftershock;
begin
  FAudio.Play(BottleSoundFile);
  FShake.AddTrauma(AftershockTrauma);
end;

// Warm the sound cache at startup so the first shot reads from RAM,
// not from disk. The roster assembles itself: hero one-shots + the
// weapon map + every deathSounds entry of monsters.json - no second
// hand-maintained list to drift out of sync.
procedure TMoonGame.PreloadSounds;
begin
  FAudio.Load(PainSoundFile);
  FAudio.Load(PitSoundFile);
  FAudio.Load(BottleSoundFile); // the ceremony loads its own; the game's blasts
  FAudio.Load(BonusSoundFile);
  FAudio.Load(RageBlastSoundFile);
  FAudio.Load(BossCrashSoundFile);
  FAudio.Load(PadHumSoundFile);
  FAudio.Load(PadClickSoundFile);
  FAudio.Load(PadClackSoundFile);
  for var Name in ArmorHitSounds do
    FAudio.Load(Name);
  FAudio.Load(RicochetSoundFile);
  FAudio.Load(CannonShotSoundFile);
  FAudio.Load(TerminalKeySoundFile);
  FAudio.Load(SphereFormSoundFile);
  FAudio.Load(SphereTakeSoundFile);
  // Decoded whole at the trial's end it would stall the victory a frame
  FAudio.LoadTrack(VictoryMusicFile);
  for var Name in WeaponShotSounds do
    FAudio.Load(Name);
  for var Def in FMonsters.AllDefs do
    for var Name in Def.DeathSounds do
      FAudio.Load(Name);
end;

// ---------------------------------------------------------------------------
// HENSHIN - what the ceremony (Game.Henshin) asks the game for: a point of
// health, a stretch of mercy; the rite and the burst live in
// Game.HeroOrbs. The world does NOT pause, as it did not in 2008: the boss
// keeps shooting through the ceremony, and an orb on its way to the hero
// wounds what it flies into. It stands only for the burst's inhale, two
// ticks.
// ---------------------------------------------------------------------------

// Original cured up to 15; we agreed on a modest 10
procedure TMoonGame.CureHero;
const
  MaxHealth = 10;
begin
  if FHeroHealth < MaxHealth then
    Inc(FHeroHealth);
end;

// The hero is spared for ATicks, as after a hit; a pit asks no mercy, as
// ever. A mercy never cuts a longer one short.
procedure TMoonGame.GrantMercy(ATicks: Integer);
begin
  if ATicks > FHurtCooldown then
    FHurtCooldown := ATicks;
end;

// ---------------------------------------------------------------------------
// BONUSES - the reward roulette of moon.dpr 531-543 / 565-602. Every 50
// points buys one random reward; it sits in the slot (the charge HUD
// shows it) until the right mouse button spends it.
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
  // repeat Random(BonusCount+1) until <>0 of 2008 collapses to this -
  // same uniform pick over the real rewards, without the dice dance
  FBonus := TBonusKind(1 + Random(Ord(High(TBonusKind))));
  // The fanfare fires THRICE (539-541) - the loudest sound in the game,
  // as befits free stuff; kept verbatim
  FAudio.Play(BonusSoundFile);
  FAudio.Play(BonusSoundFile);
  FAudio.Play(BonusSoundFile);
  var Note: string := '';
  if not FBonusLearned then
    Note := Tr(SBonusHudHint);
  FMessages.ShowBig(Format(Tr(SBonusAwardFmt), [BonusDisplayName(FBonus)]),
    BigMessageTicks, Note);
end;

function TMoonGame.HeroCenter: TSdlFPoint;
begin
  Result.X := FHero.X + HeroSize / 2;
  Result.Y := FHero.Y - HeroSize / 2;
end;

// His middle over the column, his feet on the bottom line of the row, and
// not on his way up or down: a jump that crosses the cell is no landing
function TMoonGame.HeroStandsIn(ACol, ARow: Integer): Boolean;
const
  FeetSlack = 1;
  Airborne = [haJump, haJumpLeft, haJumpRight, haFall, haFallLeft,
    haFallRight];
begin
  if FHero.Dead or (FHero.Action in Airborne) then
    Exit(False);
  var Middle := FHero.X + HeroSize / 2;
  var OnRow := Abs(FHero.Y - (ARow + 1) * TileSize) < FeetSlack;
  Result := OnRow and (Trunc(Middle / TileSize) = ACol);
end;

// The opaque points of the frame the hero is in, where they stand on the
// screen: the orbs of the rite go into him at these
function TMoonGame.HeroBodyPoints: TBodyPoints;
begin
  var Pose := FHero.Pose;
  var Seeds := FShroudPainter.SeedsOf(Pose.Frame);
  SetLength(Result, Length(Seeds));
  for var i := 0 to High(Seeds) do
  begin
    var SeedX := Seeds[i].X;
    if Pose.Mirrored then
      SeedX := HeroSize - SeedX;
    Result[i].X := Pose.Left + SeedX;
    Result[i].Y := Pose.Top + Seeds[i].Y;
  end;
end;

// The matter an aura is drawn out of: the solid cells of the hero's
// screen and the bodies of its pads
function TMoonGame.MatterAround: TMatter;
begin
  for var Row := 0 to ScreenRows - 1 do
    for var Col := 0 to ScreenCols - 1 do
      Result.Cells[Row, Col] := FLevel.SolidAt(FHero.Screen, Col, Row);
  Result.Bodies := FPads.Bodies(FHero.Screen);
end;

// A function without parameters named alone would be called, not passed:
// the references wrap the probes
function TMoonGame.CreateOrbs: THeroOrbs;
var
  Probes: TOrbProbes;
  Targets: TOrbTargets;
begin
  Probes.Alive :=
    function: Boolean
    begin
      Result := not FHero.Dead;
    end;
  Probes.Center :=
    function: TSdlFPoint
    begin
      Result := HeroCenter;
    end;
  Probes.Body :=
    function: TBodyPoints
    begin
      Result := HeroBodyPoints;
    end;
  Probes.Matter :=
    function: TMatter
    begin
      Result := MatterAround;
    end;
  Targets.PopBullet := PopEnemyBullet;
  Targets.MonsterAt := DangerousMonsterAt;
  Targets.Wound := WoundByOrb;
  Result := THeroOrbs.Create(Probes, Targets);
end;

procedure TMoonGame.CastAura;
begin
  if not FOrbs.CastAura then
    Exit;
  // The orbs are still on their way out of the matter and the ring is
  // no shield yet: the mercy of a hit covers the wait. A pit asks no
  // mercy, as ever.
  GrantMercy(HurtMercyTicks);
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
      FOrbs.PourRain;
    bkAura:
      CastAura;
    bkExplosion:
      begin
        // The only reward with its own sound (592) - the other three
        // work in silence, verbatim
        FAudio.Play(BottleSoundFile);
        FHero.Bullets.SpawnFan(FHero.X, FHero.Y, ExplosionFan);
        FShake.AddTrauma(BonusExplosionTrauma);
      end;
  end;
  Dec(FScore, BonusCost); // paid on use, not on the roll
  FBonus := bkNone;
  FBonusLearned := True;
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
  FShroud.Start(EntryLook);
  FireScreenTriggers;
  PinRespawnPoint;
end;

// Cell mapping of the 2008 bullet block: the wall grid of the screen,
// 0-based (BelongToX/YSprite[1] of WindowProc)
function BulletCellCol(AX: Double): Integer;
begin
  Result := Trunc(ScreenCols * AX / ScreenWidth); // CellOfX - 1
end;

function BulletCellRow(AY: Double): Integer;
begin
  Result := Trunc(ScreenRows * AY / ScreenHeight) - 1;
end;

function BulletOffScreen(const ABullet: TBullet): Boolean;
begin
  Result := (ABullet.X > ScreenWidth) or (ABullet.X < 0) or
    (ABullet.Y > ScreenHeight + SpriteSize) or
    (ABullet.Y < -ScreenHeight / 2);
end;

// A wall of the grid or a pad that bursts bullets. A bullet's picture
// hangs a sprite above its Y: the point it strikes with is up there.
function TMoonGame.BulletStruckWall(const ABullet: TBullet): Boolean;
begin
  if ABullet.Y <= 0 then
    Exit(False);
  Result := FLevel.SolidAt(FHero.Screen, BulletCellCol(ABullet.X),
    BulletCellRow(ABullet.Y)) or
    FPads.StopsBulletAt(FHero.Screen, ABullet.X, ABullet.Y - SpriteSize);
end;

// The stretch a bullet flew in its last tick, in honest screen units: a
// bullet's picture hangs a sprite above its Y, and the stretch rises with it
function BulletStretch(const ABullet: TBullet): TStretch;
begin
  Result.Start.X := ABullet.Last.X;
  Result.Start.Y := ABullet.Last.Y - SpriteSize;
  Result.Finish.X := ABullet.X;
  Result.Finish.Y := ABullet.Y - SpriteSize;
end;

// Did the bullet meet the monster's body on its way this tick
function BulletInMonsterBox(const ABullet: TBullet;
  const AMonster: TMonster): Boolean;
begin
  var Share: Single;
  Result := StretchEntry(BulletStretch(ABullet), AMonster.HitBox, Share);
end;

// The monster a hero's bullet lands on. Where boxes overlap, a dangerous
// monster takes the bullet before a medkit or a barrel sharing its cell;
// among equals the first in the list keeps it
function TMoonGame.HeroBulletTarget(const ABullet: TBullet): TMonster;
begin
  Result := nil;
  for var Monster in FField.Monsters do
  begin
    if (Monster.Screen <> FHero.Screen) or (Monster.Life <> mlAlive) or
      not BulletInMonsterBox(ABullet, Monster) then
      Continue;
    if Monster.Def.Dangerous then
      Exit(Monster);
    if Result = nil then
      Result := Monster;
  end;
end;

// A shield takes the bullet into its light, bare steel in sparks; the
// cannons lose nothing either way
function TMoonGame.BulletStruckCannon(const ABullet: TBullet): Boolean;
begin
  var Stretch := BulletStretch(ABullet);
  var At: TSdlFPoint;
  var Met := FCannons.Block(Stretch.Start, Stretch.Finish, At);
  Result := Met <> cbNone;
  if not Result then
    Exit;
  ABullet.Status := bsInactive;
  if Met = cbHull then
    LandCannonStrike(At);
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
    else if BulletStruckWall(Own) then
      Own.StartBurstSliding;

    if (Own.Status <> bsFlying) or BulletStruckCannon(Own) then
      Continue;

    // Hit a monster: knockback dx/2; a death that blows up sends its
    // wave out of RewardMonsterKill
    var Target := HeroBulletTarget(Own);
    if Target <> nil then
    begin
      var Knock := Round(Own.DX / 2);
      SpendBullet(Own, Target);
      Target.TakeDamage(Knock, 1, FMonsterBullets);
      if Target.Life = mlDying then
        RewardMonsterKill(Target);
    end;
  end;
end;

// Where a bullet has struck a monster's armor, in honest screen units:
// the point of its last tick's flight where it first met the hitbox
function ArmorStrike(const ABullet: TBullet; const AMonster: TMonster): TStrike;
begin
  var Body := AMonster.HitBox;
  var Stretch := BulletStretch(ABullet);
  var Share: Single;
  StretchEntry(Stretch, Body, Share);
  var Entry := Stretch.PointAt(Share);

  Result := Default(TStrike);
  Result.X := Entry.X;
  Result.Y := Entry.Y;
  Result.SpeedX := ABullet.DX;
  Result.SpeedY := ABullet.DY;
  Result.Rapid := AMonster.HitWithin(RapidHitTicks);

  TraceEntry(Result, Body);
  if AMonster.Disc <> nil then
    FaceFromCenter(Result, AMonster.Disc.Pose.Center);
end;

// A bullet ends on a monster: in its own burst or, on armor, in sparks
// with no burst at all. Called before the damage lands - the armor is
// asked how long ago it was last hit.
procedure TMoonGame.SpendBullet(const ABullet: TBullet;
  const AMonster: TMonster);
begin
  if AMonster.Def.Material <> mtMetal then
  begin
    ABullet.StartBurst;
    Exit;
  end;
  ABullet.Status := bsInactive;
  var ThrewTracer := FImpacts.Land(ArmorStrike(ABullet, AMonster));
  SoundArmorHit(ThrewTracer);
end;

procedure TMoonGame.SoundArmorHit(AThrewTracer: Boolean);
begin
  if AThrewTracer then
  begin
    FAudio.Play(RicochetSoundFile);
    Exit;
  end;
  if FArmorPings.WaitTicks > 0 then
    Exit;
  // Any ping but the last one: in turn they play a tune
  var Others := Length(ArmorHitSounds) - 1;
  var Step := 1 + Trunc(FArmorPings.Dice.NextUnit * Others);
  FArmorPings.Last := (FArmorPings.Last + Step) mod Length(ArmorHitSounds);
  FAudio.Play(ArmorHitSounds[FArmorPings.Last]);
  FArmorPings.WaitTicks := ArmorSoundGapTicks;
end;

// The kill aftermath: score, death ticker, '+N' popup, streak credit,
// the blast of exploders. AMonster has just flipped to dying. Weather pays
// nothing, shot down or burst: the sky is no bonus farm - only its blast
// goes out.
procedure TMoonGame.RewardMonsterKill(const AMonster: TMonster);
begin
  if not AMonster.Def.Weather then
  begin
    Inc(FScore, AMonster.Def.Score);
    FMessages.AddTicker(AMonster.Def.DeathText.Current,
      TickerDeathTextTicks);
    // '+N' rises from the body top (Y is the feet line, the body
    // is drawn upward from it)
    FMessages.AddScorePopup('+' + IntToStr(AMonster.Def.Score),
      AMonster.X, AMonster.Y - SpriteSize);
    ProcessKillStreak;
  end;
  // From the middle of the body: X is its left edge, Y the feet line
  var Heart: TSdlFPoint;
  Heart.X := AMonster.X + SpriteSize / 2;
  Heart.Y := AMonster.Y - SpriteSize / 2;
  if AMonster.Def.Blast.Enabled then
    FBlasts.Add(TBlast.Create(Heart, AMonster.Def.Blast));
  // As the wave's lives: a shard keeps its worth on every grade
  var ShardLives: Integer := Round(AMonster.Def.Blast.ShardLives *
    DifficultyMonsterLives[FDifficulty]);
  FExplosions.Detonate(Heart.X, Heart.Y, AMonster.Def.Explosion, ShardLives);
  if AMonster.Def.Category = mcPickup then
    BurstPickup(AMonster, Heart);
end;

// A pickup destroyed by anything but the hero: the same picture, crumbled
// and let fall, and sparks where it stood
procedure TMoonGame.BurstPickup(const AMonster: TMonster; const AHeart: TSdlFPoint);
const
  PickupSparks = 6;
begin
  BeginUptake(PickupBurst, AMonster);

  var Strike := Default(TStrike);
  Strike.X := AHeart.X;
  Strike.Y := AHeart.Y;
  Strike.NormalY := -1;
  Strike.ExtraSparks := PickupSparks;
  FImpacts.Land(Strike);
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
    else if BulletStruckWall(Enemy) then
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

function BoxHolds(const ABox: TSdlFRect; AX, AY: Single): Boolean;
begin
  Result := (AX > ABox.X) and (AX < ABox.X + ABox.W) and
    (AY > ABox.Y) and (AY < ABox.Y + ABox.H);
end;

// The enemy bullet in flight within an orb's reach of the point, nil
// when there is none. A bullet's picture hangs a sprite above its Y:
// the point it is met at is up there.
function TMoonGame.EnemyBulletNear(AX, AY: Single): TBullet;
begin
  for var Enemy in FMonsterBullets.Bullets do
    if (Enemy.Status = bsFlying) and (Abs(Enemy.X - AX) < OrbReach) and
      (Abs(Enemy.Y - SpriteSize - AY) < OrbReach) then
      Exit(Enemy);
  Result := nil;
end;

// An enemy bullet within an orb's reach of the point bursts; False when
// there is none
function TMoonGame.PopEnemyBullet(AX, AY: Single): Boolean;
begin
  var Enemy := EnemyBulletNear(AX, AY);
  if Enemy = nil then
    Exit(False);
  Enemy.StartBurst;
  Result := True;
end;

// The dangerous monster of the hero's screen whose body holds the
// point, nil when none does. A medkit, a weapon, a barrel are not
// dangerous: an orb passes through them unspent.
function TMoonGame.DangerousMonsterAt(AX, AY: Single): TMonster;
begin
  for var Monster in FField.Monsters do
    if (Monster.Screen = FHero.Screen) and (Monster.Life = mlAlive) and
      Monster.Def.Dangerous and BoxHolds(Monster.HitBox, AX, AY) then
      Exit(Monster);
  Result := nil;
end;

// What an orb or a ray of the burst costs a monster: a life. Not through
// SpendBullet: armor answers an orb with no sparks and no ping.
procedure TMoonGame.WoundByOrb(const AMonster: TMonster);
begin
  AMonster.TakeDamage(0, 1, FMonsterBullets);
  if AMonster.Life = mlDying then
    RewardMonsterKill(AMonster);
end;

// The hero's body in honest screen units, as a monster's HitBox: the box a
// monster's bullet lands in
function HeroBody(const AHero: THero): TSdlFRect;
begin
  Result.X := AHero.X + HitInset;
  Result.Y := AHero.Y - SpriteSize;
  Result.W := SpriteSize - 2 * HitInset;
  Result.H := SpriteSize;
end;

// What shelters from a blast is what stops a bullet: a wall of the grid
// or a pad that bursts bullets
function TMoonGame.BlastStoppedAt(AX, AY: Single): Boolean;
begin
  Result := FLevel.SolidAtPoint(FHero.Screen, AX, AY) or
    FPads.StopsBulletAt(FHero.Screen, AX, AY);
end;

// A blast is no one's side: an enemy, a barrel, a medkit - whatever
// stands in the wave loses lives. A barrel it kills blows up in its turn.
// A pickup is light: the wave throws it instead of shoving it, and a
// pickup in the air is out of a wave's reach - the next blast of a chain
// neither throws it back nor wears it down.
procedure TMoonGame.StrikeMonsters(const ABlast: TBlast);
begin
  for var Monster in FField.Monsters do
  begin
    if (Monster.Screen <> FHero.Screen) or (Monster.Life <> mlAlive) then
      Continue;
    var IsPickup := Monster.Def.Category = mcPickup;
    if IsPickup and Monster.InFlight then
      Continue;
    var Body := Monster.HitBox;
    var Near := NearestPoint(Body, ABlast.Heart);
    if not ABlast.Strikes(Monster, Near, BlastStoppedAt) then
      Continue;

    var Knock := ABlast.Knock(Near, Body.X + Body.W / 2);
    if IsPickup then
    begin
      Monster.Throw(Round(Knock * PickupThrow));
      Knock := 0;
    end;
    Monster.TakeDamage(Knock,
      ABlast.Lives(Near, DifficultyMonsterLives[FDifficulty]),
      FMonsterBullets);
    if Monster.Life = mlDying then
      RewardMonsterKill(Monster);
  end;
end;

procedure TMoonGame.StrikeHero(const ABlast: TBlast);
begin
  if FHero.Dead then
    Exit;
  var Near := NearestPoint(HeroBody(FHero), ABlast.Heart);
  if not ABlast.Strikes(FHero, Near, BlastStoppedAt) then
    Exit;
  // The mercy window holds against a wave as it does against a bullet
  if FHurtCooldown > 0 then
    Exit;
  FMessages.AddTicker(Tr(SHurtByBlast), TickerNoticeTicks);
  FAudio.Play(PainSoundFile);
  HurtHero;
end;

// A blast born while the waves are walked - a barrel one of them has
// killed - goes to the end of the list and waits for the next tick
procedure TMoonGame.ResolveBlasts;
begin
  for var i := FBlasts.Count - 1 downto 0 do
  begin
    var Blast := FBlasts[i];
    Blast.Spread;
    StrikeMonsters(Blast);
    StrikeHero(Blast);
    if Blast.Spent then
      FBlasts.Delete(i);
  end;
end;

// A live shard wounds the body it falls on - an enemy, a barrel, the
// hero - but only below the feet of the body it flew out of: on that
// body's own floor the wave has had its say, and a shard there is
// decoration. A body it kills may blow up and throw shards of its own.
function TMoonGame.ShardStruck(const AShard: TLiveShard): Boolean;
begin
  Result := False;
  if AShard.Drop <= ShardWoundsBelow then
    Exit;
  // An orb takes a shard as it takes a bullet, ahead of whatever it falls on
  if FOrbs.TakesAt(AShard.X, AShard.X, AShard.Y) then
    Exit(True);

  for var Monster in FField.Monsters do
  begin
    if (Monster.Screen <> FHero.Screen) or (Monster.Life <> mlAlive) or
      not BoxHolds(Monster.HitBox, AShard.X, AShard.Y) then
      Continue;
    Monster.TakeDamage(Round(AShard.SpeedX / 2), AShard.Lives,
      FMonsterBullets);
    if Monster.Life = mlDying then
      RewardMonsterKill(Monster);
    Exit(True);
  end;

  if FHero.Dead or not BoxHolds(HeroBody(FHero), AShard.X, AShard.Y) then
    Exit;
  Result := True;
  // The mercy window holds against a shard as it does against a bullet
  if FHurtCooldown > 0 then
    Exit;
  FMessages.AddTicker(Tr(SHurtByBlast), TickerNoticeTicks);
  FAudio.Play(PainSoundFile);
  HurtHero;
end;

procedure TMoonGame.HurtHero;
begin
  if FHero.Dead then
    Exit;
  FKillStreak := 0; // 2008 reset it at every damage site (752/781/985)
  Dec(FHeroHealth);
  GrantMercy(HurtMercyTicks);
  if FHeroHealth <= 0 then
  begin
    FHero.Kill; // the d-frames play; the world keeps moving without him
    FOrbs.Fall;
    FShroud.Clear;
    FUptake.Drop;
    FSphere.Drop;
    FGameOverTimer := GameOverDelayTicks;
    // Dying cancels the pending exit: the door reopens when the reborn
    // hero kills the reborn boss. (2008 raced its GameOver timer against
    // ToEndLev and the menu won - same spirit, cleaner mechanics.)
    FEndLevelTimer := 0;
  end;
end;

procedure TMoonGame.RestartLevel;
begin
  // Death rewinds to the checkpoint: the respawn point of the CURRENT
  // screen or, without one, its entry point, kept fresh by transitions
  // and heroX/heroY triggers - dying on screen 9 no longer costs the
  // whole level. The world around it
  // restarts in full: monsters and all, barrels regrow, gravels rise
  // again. (2008 had no respawn - death led to the menu; the checkpoint
  // only served the pits. Our auto-restart deviation now reads it too.)
  FField.Free;
  FField := TMonsterField.Create(FRenderer, FMonsters, FLevel, FPads,
    FDifficulty, DifficultyMonsterLives[FDifficulty]);
  WarmPickupPictures;
  // The pads first: Reseat finds the pad of a lamp where the level file
  // puts it
  FPads.Rewind(RollDiceSeed);
  FArena.Reset;
  FDynamics.Reseat;
  FHero.Bullets.Clear;
  FMonsterBullets.Clear;
  FExplosions.Clear;
  FBlasts.Clear;
  FImpacts.Clear;
  FArrivals.Clear;
  FCannons.Clear;
  FOrbs.Rewind;
  FHero.Revive;
  FHero.SetScreenX(FCheckpointX);
  FHero.SetY(FCheckpointY); // drops into a fall: no standing on air
  FUptake.Clear;
  FSphere.Clear;
  FShroud.Clear;
  FShroud.Start(ReviveLook);
  FHeroHealth := DifficultyHeroHealth[FDifficulty];
  FHurtCooldown := 0;
  // See the LoadLevel comment: 2008 never cleared this flag, here it
  // would softlock the reborn screen. The screen trigger of the trial
  // raises it again.
  FTrial.Stop;
  FMedkitBank := '';
  FWaveMonster := '';
  FWaveBank := '';
  FTrialDone := False;
  // What opened the door regrows with the field: the door waits for it
  // again
  FDoorOpened := False;
  FPress.Shut;
  FSkyMonster := '';
  FHeldFlyIns := [];
  FCannonSmoke := 0;
  // Monsters regrow, so the score they paid out is taken back -
  // otherwise dying becomes a farming strategy. Captions die with you.
  FScore := 0;
  FKillStreak := 0;
  FStreakBonusCount := 0;
  FMessages.Clear;
  FGoRight.Hide;
  StopVictoryTrack;
  // A fresh boss means a fresh ceremony (the new TMonster resets its
  // henshin flag too)
  FHenshin.Reset;
  // Score burns on restart (anti-farm), so the unspent reward burns too
  FBonus := bkNone;
  FBonusActivateQueued := False;
  // The boss regrows calm, so his rage track must not outlive him -
  // and win.ogg dies with the cancelled exit. FCurrentMusic covers the
  // screens that have no changeMusic trigger of their own (most of
  // them); a screen that HAS one replays it via the re-arm below.
  FAudio.PlayMusic(FCurrentMusic, mmLoop);
  // Death re-enters the screen: its one-shot triggers re-arm and fire
  // again - teleports are idempotent while the level keeps the screen's
  // respawn point on their target, as both levels do,
  // captions re-introduce the place, the gravel trial rises with the
  // barrels. In 2008 once-per-game came for free - doors open one way
  // and death led to the menu; here death stays on the screen, so the
  // reading is once-per-LIFE.
  for var i := 0 to High(FLevel.Entities) do
    if FLevel.Entities[i].Screen = FHero.Screen then
      FTriggerFired[i] := False;
  for var i := 0 to High(FLevel.ScreenTriggers) do
    if FLevel.ScreenTriggers[i].Screen = FHero.Screen then
      FTriggerFired[Length(FLevel.Entities) + i] := False;
  FDirector.ReArm(FHero.Screen);
  FScenes.ReArm(FHero.Screen, SceneStage);
  FireScreenTriggers;
  // The triggers have just written the checkpoint again
  PinRespawnPoint;
end;

// What the hero touches is his this tick; what is seen of it from here on
// is the uptake's
procedure TMoonGame.TakeLoot(const AMonster: TMonster);
begin
  var Look := MedkitUptake;
  if AMonster.Def.PickupEffect.Kind = peGiveWeapon then
    Look := WeaponUptake;
  BeginUptake(Look, AMonster);
  AMonster.Collect;
end;

procedure TMoonGame.BeginUptake(const ALook: TUptakeLook; const AMonster: TMonster);
begin
  var Picture := FUptakePainter.PictureOf(AMonster);
  var Box := AMonster.PictureBox;
  FUptake.Start(ALook, Picture, FUptakePainter.ShapeOf(Picture),
    Box.X, Box.Y, AMonster.Mirrored, HeroCenter);
end;

// Built now, so that the first touch does not stop on loading a picture
procedure TMoonGame.WarmPickupPictures;
begin
  for var Monster in FField.Monsters do
    if Monster.Def.Category = mcPickup then
      FUptakePainter.PictureOf(Monster);
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

    // Weather that comes down on the hero bursts on him
    if Monster.Def.Weather then
    begin
      Monster.Burst(FMonsterBullets);
      Continue;
    end;

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
          TakeLoot(Monster);
        end;
    else
      if Monster.Def.Dangerous then
      begin
        Monster.NoteHeroContact;
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

// The sphere forms with its middle on the middle of the cell
procedure TMoonGame.FormSphere(ACol, ARow: Integer; ASize: Single);
begin
  FSphere.Form(FHero.Screen, (ACol - 0.5) * TileSize, (ARow - 0.5) * TileSize,
    ASize);
  FAudio.Play(SphereFormSoundFile);
end;

// The burst and the first pip are in the tick of the touch; the rest of
// the pips follow the sphere's clock
procedure TMoonGame.ResolveSphereContact;
begin
  if FHero.Dead or not FSphere.Touches(HeroBody(FHero), FHero.Screen) then
    Exit;
  FSphere.Take;
  FAudio.Play(SphereTakeSoundFile);
end;

procedure TMoonGame.GiveSpherePip;
begin
  if FSphere.PipDue and (FHeroHealth < SphereHealth) then
    Inc(FHeroHealth);
end;

// Through a door the pips still due are his at once, as the light is
procedure TMoonGame.SettleSphere;
begin
  if FSphere.Filling then
    FHeroHealth := SphereHealth;
  FSphere.Settle;
end;

// A cannon is no bunker: its body wounds, and shoves the hero off the wall
// it hangs on
procedure TMoonGame.ResolveCannonContact;
const
  CannonShove = 4;
begin
  if FHero.Dead then
    Exit;
  var Side: TCannonSide;
  if not FCannons.Touches(HeroBody(FHero), Side) then
    Exit;
  if FHurtCooldown = 0 then
  begin
    FMessages.AddTicker(Tr(SHurtByMonster), TickerNoticeTicks);
    FAudio.Play(PainSoundFile);
    HurtHero;
  end;
  if Side = csLeft then
    FHero.ShoveX(CannonShove)
  else
    FHero.ShoveX(-CannonShove);
end;

// A tick of the wall cannons, carried out: the rules are Game.Cannons'
procedure TMoonGame.TickCannons;
begin
  if not FCannons.Active then
    Exit;
  var Body := Default(TSdlFRect);
  if not FHero.Dead then
    Body := HeroBody(FHero);
  var Cue := FCannons.Tick(TrialAct, Body, FOrbs.TakesAt);
  if Cue.Hum then
    FAudio.Play(PadHumSoundFile);
  if Cue.Shot then
    FAudio.Play(CannonShotSoundFile);
  if Cue.YieldSleep then
    TellYieldBank(scSleep);
  if Cue.YieldWake then
    TellYieldBank(scWake);
  for var Strike in Cue.Strikes do
    LandCannonStrike(Strike);
  // The mercy window holds against a round as it does against a bullet
  if Cue.HeroHit and not FHero.Dead and (FHurtCooldown = 0) then
  begin
    FMessages.AddTicker(Tr(SHitByBullet), TickerNoticeTicks);
    FAudio.Play(PainSoundFile);
    HurtHero;
  end;
  if Cue.Blast then
    BlowCannons(Cue);
end;

// The bank of shelves in the cannons' way: into the wall, or out to hold
procedure TMoonGame.TellYieldBank(ACall: TShelfCall);
var
  Command: TShelfCommand;
begin
  Command := Default(TShelfCommand);
  Command.Call := ACall;
  Command.Run.Kind := pgHold;
  FPads.TellBank(FCannons.YieldBank, Command, Default(TBankTelling),
    HeroCenter.X);
end;

// Sparks off a cannon's steel, thrown back the way the shot came from:
// the cannon on the left faces right
procedure TMoonGame.LandCannonStrike(const APoint: TSdlFPoint);
begin
  var Strike := Default(TStrike);
  Strike.X := APoint.X;
  Strike.Y := APoint.Y;
  Strike.NormalX := 1;
  if APoint.X > ScreenWidth / 2 then
    Strike.NormalX := -1;
  SoundArmorHit(FImpacts.Land(Strike));
end;

// The end of their scene: decoration only - it wounds no one
procedure TMoonGame.BlowCannons(const ACue: TCannonCue);
begin
  for var Point in ACue.BlastPoints do
    FExplosions.Detonate(Point.X, Point.Y, ekMachine);
  FAudio.Play(RageBlastSoundFile);
  FShake.AddTrauma(CannonBlastTrauma);
  FCannonSmoke := CannonSmokeTicks;
end;

// A fan of sparks off the rim that struck, with its flash, and thinner
// ones along the wall on either side. Those land as rapid hits - no
// flash of their own, or the light piles up white. A body flung at a
// wall throws far more than a bullet: every fan gets extra sparks.
procedure TMoonGame.ThrowCrashSparks(const ACrash: TPilotCrash);
const
  FansPerSide = 7;
  FanGap = 2; // units between two fans
  RimExtraSparks = 27;
  SideExtraSparks = 6;
var
  Strike: TStrike;
begin
  Strike := Default(TStrike);
  Strike.X := ACrash.X;
  Strike.Y := ACrash.Y;
  Strike.SpeedX := ACrash.SpeedX;
  Strike.SpeedY := ACrash.SpeedY;
  Strike.NormalX := ACrash.NormalX;
  Strike.NormalY := ACrash.NormalY;
  Strike.ExtraSparks := RimExtraSparks;
  FImpacts.Land(Strike);

  Strike.Rapid := True;
  Strike.ExtraSparks := SideExtraSparks;
  for var i := -FansPerSide to FansPerSide do
  begin
    if i = 0 then
      Continue;
    // Along the wall: the normal turned a quarter
    Strike.X := ACrash.X - ACrash.NormalY * i * FanGap;
    Strike.Y := ACrash.Y + ACrash.NormalX * i * FanGap;
    FImpacts.Land(Strike);
  end;
end;

procedure TMoonGame.PayDodgePrize(const ABoss: TMonster);
begin
  // A dash through a corpse touches nobody, yet nothing was dodged
  if FHero.Dead then
    Exit;
  var Prize := ABoss.Def.Boss.DodgePrize;
  if Prize = '' then
    Exit;
  FField.SpawnOn(Prize, ABoss.Screen, FHero.X, FHero.Y);
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
          begin
            // Everything dies through TakeDamage, so pickups chirp here
            // too (medic/gun of 2008); tank and boss carry two sounds -
            // the double explosion plays both, verbatim 903-925
            for var Name in Monster.Def.DeathSounds do
              FAudio.Play(Name);
            if (Monster.Def.Id = GravelMonsterId) and
              (Monster.Screen = FGravelScreen) then
              FTrial.NoteGravelKilled;
            if (FWaveMonster <> '') and (Monster.Def.Id = FWaveMonster) and
              (Monster.Screen = FGravelScreen) then
              FTrial.NoteWaveKilled;
            if Monster.Def.Boss.EndsLevelOnDeath then
              FShake.AddTrauma(BossBlastTrauma)
            else if Monster.Def.Blast.Enabled then
              FShake.AddTrauma(ExploderTrauma);
          end;
        meHenshin:
          // The boss dropped below 2/3 - three seconds of countdown,
          // then the ceremony; the ice form arrives when the rite of
          // orbs is through
          FHenshin.StartCountdown;
        meBossRage:
          begin
            // 'Сменить музыку' of 2008 (868-869): the rage track loops
            // until the boss dies or the hero does
            FAudio.PlayMusic(Monster.Def.Boss.RageMusic, mmLoop);
            FShake.AddTrauma(BossBlastTrauma);
            // The armor bursts as the rage wave leaves it: a wreck's
            // blast, not the death's - the boss flies on
            FExplosions.Detonate(Monster.X + SpriteSize / 2,
              Monster.Y - SpriteSize / 2, ekMachine);
            FAudio.Play(RageBlastSoundFile);
          end;
        meBossWantsMinion:
          // The weighted table of AddMonstOnBoss1 (medkit counted
          // twice) rains reinforcements - and mercy - from the sky
          FField.SpawnFromSky(Monster.Def.Boss.PickSpawn,
            Monster.Screen);
        meBossCrashed:
          begin
            FShake.AddTrauma(BossCrashTrauma);
            FAudio.Play(BossCrashSoundFile);
            ThrowCrashSparks(Monster.LastCrash);
            FPads.Shove(Monster.Screen, Monster.LastCrash.Blow, LapHolds);
          end;
        meBossOwesPrize:
          PayDodgePrize(Monster);
        meBurst:
          // No blow killed it: the blast is sent out here
          RewardMonsterKill(Monster);
        meLevelComplete:
          begin
            // The suit comes off in a ring of orbs, the victory track
            // plays over the wreckage, and 'ToEndLev := 400' (949) starts
            // the walk-out timer - Update loads the next level when it dries
            FHenshin.RemoveIceForm;
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
    if FState = gsIntro then
      FBriefing.Tick;
    if (FState = gsIntro) and FBriefing.KeyStruck then
      FAudio.Play(TerminalKeySoundFile);
    Exit;
  end;
  if FState = gsEnding then
    Exit; // the farewell screen is static; only the mouse works there

  FMessages.Tick;
  if FMessages.TerminalKeyStruck then
    FAudio.Play(TerminalKeySoundFile);
  FVitals.Tick(FHeroHealth, FHurtCooldown > 0);
  FMarks.Tick(FHeroHealth, FHurtCooldown > 0, FHero.Screen);
  FCharge.Tick(FScore, FKillStreak, FBonus, not FBonusLearned);
  FGoRight.Tick;
  // Down to 0 and no further: below 0 is no victory at all
  if FVictoryLeft > ADeltaSeconds then
    FVictoryLeft := FVictoryLeft - ADeltaSeconds
  else if FVictoryLeft > 0 then
    FVictoryLeft := 0;
  FShake.Tick; // before the level switch: the boss's blast rides the walk-out
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
  // Enough points on the meter and an empty slot: the roulette spins (531)
  if (FScore >= BonusCost) and (FBonus = bkNone) then
    AwardRandomBonus;
  ActivateQueuedBonus;

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
  if FHeldDown then
    FHero.Command(hcDrop);

  // The pads go first: their riders move with them, then by themselves.
  // A shelf told to spare the hero asks where he stands.
  var HeroDeck: TPad := nil;
  if not FHero.Dead then
    HeroDeck := FHero.DeckUnderFeet;
  FPads.Tick(FHero.Screen, HeroDeck);
  if FPads.CornerTurned then
    FAudio.Play(PadClickSoundFile);
  if FPads.PairDocked then
    FAudio.Play(PadClackSoundFile);
  if FPads.ShelfLatched then
    FAudio.Play(ShelfLatchSoundFile);
  FHero.Tick;
  if FHeldFire and FHero.Fire then
  begin
    FAudio.Play(WeaponShotSounds[FHero.WeaponType]);
    if FHero.WeaponType = DupletWeapon then
      FShake.AddTrauma(DupletShotTrauma);
  end;

  // The burst's inhale: the world stands, the hero, his arms and the pads
  // go on
  var WorldStands := FOrbs.Holding;
  if not WorldStands then
  begin
    FField.Tick(FHero.Screen, Round(FHero.X), Round(FHero.Y),
      FMonsterBullets);
    DrainMonsterEvents;
  end;

  FHero.Bullets.Update;
  if not WorldStands then
    FMonsterBullets.Update;
  FExplosions.Tick;
  FImpacts.Tick;
  FArrivals.Tick;
  FOrbs.Tick;
  // After the rite and the burst: what they tell this tick, the ceremony
  // hears this tick
  FHenshin.Tick;
  var HeroPose := FHero.Pose;
  var HeroSeeds := FShroudPainter.SeedsOf(HeroPose.Frame);
  // The uptake first: what comes in feeds the shroud's light, and the
  // light then fades by a tick
  FUptake.Tick(HeroPose, HeroSeeds);
  FSphere.Tick(HeroCenter);
  FShroud.Tick(HeroPose, HeroSeeds);
  FOrbs.TickAfterCeremony;
  FEnergyGauge.Tick(FOrbs.Energy);
  FVitals.Wing := FEnergyGauge.WingWidth;
  if FArmorPings.WaitTicks > 0 then
    Dec(FArmorPings.WaitTicks);
  ResolveHeroBulletHits;
  // Before the monster half: an orb takes a bullet ahead of the hero
  FOrbs.Strike;
  ResolveBlasts;
  FExplosions.StrikeShards(ShardStruck);
  ResolveMonsterBulletHits;
  ResolveMonsterContact;
  ResolveSphereContact;
  GiveSpherePip;
  if not WorldStands then
    TickCannons;
  ResolveCannonContact;
  // The verdicts of the tick are in; the dead watch no events and direct
  // no arena - the restart re-arms the screen anyway
  if not FHero.Dead then
  begin
    FDirector.Tick(FHero.Screen, FField);
    FArena.Tick(FHero.Screen, FField);
    if FArena.Warned then
      FAudio.Play(PadHumSoundFile);
  end;
  // Before the dynamics: a craft it moves moves this tick
  FScenes.Tick(FHero.Screen, SceneStage);
  FShake.AddTrauma(FScenes.Trauma);
  FShake.AddTrauma(FScenes.TakeJolt);
  // After the monsters have moved: smoke must leave a monster where this
  // frame draws it, not a tick behind
  FDynamics.Tick(FHero.Screen);
  FShake.AddTrauma(FDynamics.TakeJolt);
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

  UpdateInspectorCaption;
end;

// The hero and his shroud, on the hero's shake channel, lifted with the
// deck under his feet
procedure TMoonGame.DrawHeroInShroud(AShake: TSdlPoint; ALift, AAlpha: Single);
begin
  FShroudPainter.DrawUnder(FDynamics.Canvas, AShake, ALift, AAlpha);
  FSprites.Origin := AShake;
  FSprites.FineY := ALift;
  if not FShroud.Assembling then
    FHero.Draw(FSprites);
  FShroudPainter.DrawBody(AShake, ALift, AAlpha);
  // The strips make the body, the arm stays his own
  if FShroud.Assembling then
    FHero.DrawArm(FSprites);
  FSprites.FineY := 0;
  FShroudPainter.DrawOver(FDynamics.Canvas, AShake, ALift, AAlpha);
end;

// The hero as the burst's bare figure: the mask of his frame, where the
// frame stands
procedure TMoonGame.DrawHeroSilhouette(AShake: TSdlPoint; ALift: Single);
var
  Figure: TBurstFigure;
begin
  var Pose := FHero.Pose;
  Figure.Mask := FShroudPainter.MaskOf(Pose.Frame);
  Figure.Frame.X := Pose.Left + AShake.X;
  Figure.Frame.Y := Pose.Top + AShake.Y + ALift;
  Figure.Frame.W := HeroSize;
  Figure.Frame.H := HeroSize;
  Figure.Mirrored := Pose.Mirrored;
  FOrbs.DrawSilhouette(FDynamics.Canvas, Figure);
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
        FBriefing.Draw(Tr(SPressAnyKey));
      end;
    gsEnding:
      DrawEnding;
    gsPlaying:
      begin
        // Back to front, each layer on its own shake channel. The
        // backdrop stands still - what a jolt bares at the edge is sky,
        // not void; cursor and HUD are glass over the world and stand too
        FSprites.Origin := NoShake;
        FTiles.DrawBackground(FHero.Screen);
        // The haze bends the still backdrop where its pad has been jolted
        // to: placed with the world, it reads the backdrop as it stands
        FDynamics.Draw(FHero.Screen, FShake.Offset(scWorld), AAlpha,
          dlBackdrop);
        FDynamics.Draw(FHero.Screen, NoShake, AAlpha, dlSky);
        FDynamics.Draw(FHero.Screen, FShake.Offset(scWorld), AAlpha, dlAloft);
        FSprites.Origin := FShake.Offset(scWorld);
        // Objects stand on the tiles, so they jolt with them - a still
        // ship over a shaking floor would float
        FObjects.Draw(FHero.Screen);
        // The pads in the depth with what hangs on them, then the pads
        // in front, which pass before both
        FPads.Draw(FHero.Screen, AAlpha, plDeep);
        FDynamics.DrawSunk(FHero.Screen, FSprites.Origin, AAlpha);
        FPads.Draw(FHero.Screen, AAlpha, plFront);
        FDynamics.Draw(FHero.Screen, FSprites.Origin, AAlpha, dlBack);
        FTiles.DrawTiles(FHero.Screen);
        FExplosions.DrawSmoke(FDynamics.Canvas, FSprites.Origin, AAlpha);
        FCannons.DrawBodies(FSprites, AAlpha);
        FSprites.Origin := FShake.Offset(scMonsters);
        FUptakePainter.DrawBehind(FField, FHero.Screen, FSprites.Origin, AAlpha);
        FField.Draw(FSprites, FHero.Screen, AAlpha);
        FUptakePainter.DrawLoot(FDynamics.Canvas, FField, FHero.Screen,
          FSprites.Origin, AAlpha);
        FSpherePainter.DrawSphere(FDynamics.Canvas, FHero.Screen,
          FSprites.Origin, AAlpha);
        FField.DrawSmoke(FDynamics.Canvas, FHero.Screen, FSprites.Origin,
          AAlpha);
        FField.DrawSparks(FDynamics.Canvas, FHero.Screen, FSprites.Origin,
          AAlpha);
        FDynamics.Draw(FHero.Screen, FSprites.Origin, AAlpha, dlFront);
        FOrbs.DrawBehind(FDynamics.Canvas, FShake.Offset(scWorld), AAlpha);
        var HeroShake := FShake.Offset(scHero);
        var HeroLift := FHero.DeckLift(AAlpha);
        FOrbs.DrawVeil(FDynamics.Canvas, HeroShake);
        // The burst's inhale: a bare figure stands for the hero and his
        // shroud
        if FOrbs.Inhaling then
          DrawHeroSilhouette(HeroShake, HeroLift)
        else
          DrawHeroInShroud(HeroShake, HeroLift, AAlpha);
        FUptakePainter.DrawOver(FDynamics.Canvas, FHero.Pose, HeroShake, HeroLift,
          AAlpha);
        FSpherePainter.DrawOver(FDynamics.Canvas, HeroCenter, HeroShake, AAlpha);
        FSprites.Origin := FShake.Offset(scWorld);
        FHero.Bullets.Draw(FSprites);
        FMonsterBullets.Draw(FSprites);
        FCannons.DrawLight(FDynamics.Canvas, FSprites.Origin, AAlpha);
        FOrbs.DrawOrbs(FDynamics.Canvas, FSprites.Origin, AAlpha);
        FExplosions.Draw(FDynamics.Canvas, FSprites.Origin, AAlpha);
        FImpacts.Draw(FDynamics.Canvas, FShake.Offset(scMonsters), AAlpha);
        FArrivals.Draw(FDynamics.Canvas, FShake.Offset(scMonsters), AAlpha);
        // Over the world, under the HUD
        FOrbs.DrawGlass(FDynamics.Canvas, AAlpha);
        FScenes.DrawShade(ARenderer);
        FMarks.Draw(FHero, FField, FShake.Offset(scHero),
          FShake.Offset(scMonsters));
        FSprites.Origin := NoShake;
        FHero.DrawCrosshair(FSprites, CrosshairFrame);
        FVitals.Draw;
        FEnergyGauge.Draw(AAlpha);
        // Over the gauge: the orbs go into it
        FOrbs.DrawFeed(FDynamics.Canvas, NoShake, AAlpha);
        FCharge.Draw;
        FGoRight.Draw(AAlpha);
        FMessages.Draw(AAlpha);
        // Topmost: the ceremony outranks the news
        FHenshin.DrawCountdown(FFont, AAlpha);
      end;
  end;

  DrawAtlasOverlay;
end;

// The first key hurries the story out, the next one starts the level
procedure TMoonGame.AdvanceBriefing;
begin
  if FBriefing.Done then
    StartPlaying
  else
    FBriefing.Finish;
end;

// ---------------------------------------------------------------------------
// THE DEBUG KEYBOARD - everything below is compiled out unless DEBUGKEYS
// is on in Moon2D.inc. The four entry points keep their signatures in
// every build so that Update, Render and HandleKey read the same either
// way; only the bodies vanish.
// ---------------------------------------------------------------------------

// The tile inspector (T): the window caption reports what sits under the
// cursor. The fps updater overwrites it once a second - live with it.
procedure TMoonGame.UpdateInspectorCaption;
begin
{$IFDEF DEBUGKEYS}
  if not (FInspect and Assigned(FWindow)) then
    Exit;
  var Col := FMouseGX div TileSize;
  var Row := FMouseGY div TileSize;
  var Tile := FLevel.TileAt(FHero.Screen, Col, Row);
  var Name := 'empty';
  if Tile <> EmptyTile then
    Name := FLevel.TilePalette[Tile - 1];
  SDL_SetWindowTitle(FWindow, PAnsiChar(SdlText(Format(
    'scr %d cell %d,%d tile %d = %s',
    [FHero.Screen, Col, Row, Tile, Name]))));
{$ENDIF}
end;

// The raw font atlas (F), drawn over everything: the orientation check
// that caught the 90-degrees-clockwise atlas of 2008.
procedure TMoonGame.DrawAtlasOverlay;
begin
{$IFDEF DEBUGKEYS}
  if FShowAtlas then
    FFont.DrawAtlas((FrameWidth - FrameHeight) div 2, 0, FrameHeight);
{$ENDIF}
end;

{$IFDEF DEBUGKEYS}
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
  DebugShowScreen(FHero.Screen + ADelta);
end;

procedure TMoonGame.DebugShowScreen(AScreen: Integer);
begin
  if (AScreen < 1) or (AScreen > FLevel.ScreenCount) then
    Exit;
  FHero.Screen := AScreen;
  FHero.SetY(FHero.Y); // settles or falls, as any teleport
  ArriveOnScreen;
end;

type
  // On one screen the triggers fire on arrival, the events after them
  TMusicTurn = (mtTrigger, mtEvent);

// The track a hero who walked in would hear on AScreen: the level's own,
// then the last change the screens before it make. An event counts
// whether or not its condition ever held.
function TrackBefore(ALevel: TLevel; AScreen: Integer;
  ADifficulty: TDifficulty): string;
var
  Chosen: string;
  LastScreen: Integer;
  LastTurn: TMusicTurn;

  procedure Consider(const ATrack: string; ATrackScreen: Integer;
    ATurn: TMusicTurn);
  begin
    if (ATrack = '') or (ATrackScreen >= AScreen) then
      Exit;
    var Later := (ATrackScreen > LastScreen) or
      ((ATrackScreen = LastScreen) and (ATurn >= LastTurn));
    if not Later then
      Exit;
    Chosen := ATrack;
    LastScreen := ATrackScreen;
    LastTurn := ATurn;
  end;

begin
  Chosen := ALevel.Music;
  LastScreen := 0;
  LastTurn := mtTrigger;
  for var Placement in ALevel.Entities do
    if ADifficulty in Placement.Grades then
      Consider(Placement.Triggers.ChangeMusic, Placement.Screen, mtTrigger);
  for var Trigger in ALevel.ScreenTriggers do
    if ADifficulty in Trigger.Grades then
      Consider(Trigger.Triggers.ChangeMusic, Trigger.Screen, mtTrigger);
  for var Event in ALevel.Events do
    for var Action in Event.Actions do
      if Action.Kind = eaMusic then
        Consider(Action.FileName, Event.Screen, mtEvent);
  Result := Chosen;
end;

// End: the screen being built now, from anywhere in the campaign. The
// story is skipped, the hero stands on the screen's respawn point, and
// the music becomes the one a walk there would have brought.
procedure TMoonGame.DebugJumpToWork;
const
  WorkLevel = 2;
  WorkScreen = 10;
begin
  var LevelFile := Format(LevelFilePattern, [WorkLevel]);
  if not SameText(LevelFile, FLevelFile) then
  begin
    LoadLevel(LevelFile);
    if FState = gsIntro then
      StartPlaying;
  end;

  var Track := TrackBefore(FLevel, WorkScreen, FDifficulty);
  if not SameText(Track, FCurrentMusic) then
    ChangeMusic(Track);

  DebugShowScreen(WorkScreen);
  FHero.SetScreenX(FCheckpointX);
  FHero.SetY(FCheckpointY);
end;

// N: the three ways to filter a redrawn font, compared live on the
// same screen. The 2008 atlas ignores it - it is nearest in every mode.
procedure TMoonGame.CycleFontFiltering;
const
  FilteringNames: array[TFontFiltering] of string = ('linear', 'nearest',
    'linear small, nearest large');
begin
  if FFont.Filtering = High(TFontFiltering) then
    FFont.Filtering := Low(TFontFiltering)
  else
    FFont.Filtering := Succ(FFont.Filtering);
  SDL_SetWindowTitle(FWindow, PAnsiChar(SdlText(
    'font: ' + FilteringNames[FFont.Filtering])));
end;

// AWidth x AHeight must be the target's own size: nil reads all of it
function SaveTargetAsPng(ARenderer: PSdlRenderer; AWidth, AHeight: Integer;
  const AFileName: string): Boolean;
begin
  var Surface := SDL_CreateRGBSurfaceWithFormat(0, AWidth, AHeight, 32,
    SdlPixelFormatAbgr8888);
  if Surface = nil then
    Exit(False);
  try
    if SDL_RenderReadPixels(ARenderer, nil, SdlPixelFormatAbgr8888,
      Surface.Pixels, Surface.Pitch) <> 0 then
      Exit(False);
    Result := IMG_SavePNG(Surface, PAnsiChar(SdlText(AFileName))) = 0;
  finally
    SDL_FreeSurface(Surface);
  end;
end;

// Offscreen, an art pixel to a picture pixel - the window's size stays
// out of the picture. Returns how many screens reached a file.
function TMoonGame.SaveScreenPictures(const ADir: string): Integer;
const
  ScreenFilePattern = 'screen%.2d.png';
begin
  Result := 0;
  var PictureWidth := FLevel.GridWidth * TileArtSize;
  var PictureHeight := FLevel.GridHeight * TileArtSize;
  var Target := SDL_CreateTexture(FRenderer, SdlPixelFormatAbgr8888,
    SdlTextureAccessTarget, PictureWidth, PictureHeight);
  if Target = nil then
    Exit;
  try
    if SDL_SetRenderTarget(FRenderer, Target) <> 0 then
      Exit;
    // A target switch resets the logical size to the texture's own; the
    // switch back restores the frame's
    SDL_RenderSetLogicalSize(FRenderer, FLevel.GridWidth * TileSize,
      FLevel.GridHeight * TileSize);
    // Alpha 0: the picture is empty wherever no tile stands
    SDL_SetRenderDrawColor(FRenderer, 0, 0, 0, 0);
    FSprites.Origin := NoShake;

    for var Screen := 1 to FLevel.ScreenCount do
    begin
      SDL_RenderClear(FRenderer);
      FTiles.DrawTiles(Screen);

      var FileName := TPath.Combine(ADir,
        Format(ScreenFilePattern, [Screen]));
      if SaveTargetAsPng(FRenderer, PictureWidth, PictureHeight,
        FileName) then
        Inc(Result);
    end;
  finally
    SDL_SetRenderTarget(FRenderer, nil);
    SDL_DestroyTexture(Target);
  end;
end;

// P: the source pictures for repainting the level's art outside the game
procedure TMoonGame.DumpLevelScreens;
const
  DumpDir = 'dump';
begin
  var Dir := TPath.GetFullPath(TPath.Combine(DumpDir, FLevel.Id));
  ForceDirectories(Dir);

  var SavedCount := SaveScreenPictures(Dir);
  var Tally := Format('dumped %d of %d screens',
    [SavedCount, FLevel.ScreenCount]);
  // Fullscreen has no caption to read the report in
  FMessages.AddTicker(Tally, TickerNoticeTicks);

  var Report := Tally + ' to ' + Dir;
  if SavedCount < FLevel.ScreenCount then
    Report := Report + ': ' + SdlErrorText;
  SDL_SetWindowTitle(FWindow, PAnsiChar(SdlText(Report)));
end;

// R: the pad group of the hero's screen flies to a new formation, every
// pad at once; the pad under the hero stays in front. Once the last pad
// has landed.
procedure TMoonGame.DebugRebuildPads;
begin
  for var Group in FLevel.PadGroups do
    if Group.Screen = FHero.Screen then
      FPads.RequestRebuild(Group.Tag, HeroRides, nil, nil);
end;

// Y: the pad group of the hero's screen flies back to where the level
// file puts it, every pad at once
procedure TMoonGame.DebugRestorePads;
begin
  for var Group in FLevel.PadGroups do
    if Group.Screen = FHero.Screen then
      FPads.RequestRestore(Group.Tag, HeroRides, nil, CalmPace);
end;
{$ENDIF} // DEBUGKEYS

// The menu-state debug keys: the two trailer frames. True = consumed.
function TMoonGame.HandleDebugMenuKey(AScancode: Integer): Boolean;
begin
  Result := False;
{$IFDEF DEBUGKEYS}
  case AScancode of
    ScancodeV:
      FMenu.ShowShowcase(skLogo);
    ScancodeB:
      FMenu.ShowShowcase(skSky);
    ScancodeN:
      CycleFontFiltering;
  else
    Exit;
  end;
  Result := True;
{$ENDIF}
end;

// The in-game debug keys. True = consumed, so HandleKey bows out before
// it reaches the real bindings.
function TMoonGame.HandleDebugKey(AScancode: Integer): Boolean;
begin
  Result := False;
{$IFDEF DEBUGKEYS}
  case AScancode of
    ScancodeT:
      FInspect := not FInspect;
    ScancodeF:
      FShowAtlas := not FShowAtlas;
    ScancodeN:
      CycleFontFiltering;
    ScancodeG:
      // The roulette hands the aura out once in four rewards - too
      // rare to tune against. Straight onto the hero, slot untouched.
      CastAura;
    ScancodeH:
      FOrbs.PourRain;
    ScancodeJ:
      // The boss gives the ceremony once a fight, at two thirds of his
      // lives - too far to tune against
      FHenshin.Start;
    ScancodeK:
      // The ring and its mercy, as the boss's death gives them, with
      // no suit to take off - too far to tune against
      begin
        FOrbs.ShedSuit;
        GrantMercy(IceRiteScore.ShedTicks);
      end;
    ScancodeL:
      // The burst as the ceremony gives it, with no rite before it and no
      // suit after - too far to tune against
      FOrbs.StartBurst(IceBurstLook);
    ScancodeU:
      // The moon form's burst: no form wears it yet
      FOrbs.StartBurst(MoonBurstLook);
    ScancodeM:
      // Trailer capture: silence the score, keep the gunshots -
      // the footage gets its music in the edit, not in the engine
      FAudio.ToggleMusicMuted;
    ScancodeP:
      DumpLevelScreens;
    ScancodeR:
      DebugRebuildPads;
    ScancodeY:
      DebugRestorePads;
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
    // The crosshair calibrator is DONE (values confirmed by the macro
    // photo and baked into Create) - it retires to the corner cluster,
    // kept for the day a new monitor disagrees
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
    ScancodeEnd:
      DebugJumpToWork;
  else
    Exit;
  end;
  Result := True;
{$ENDIF}
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

    case Monster.HealthTier of
      htHale: Exit(2);
      htWounded: Exit(3);
    else
      Exit(4);
    end;
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
    // Any key ends a showcase; bare Alt/Ctrl exited above as modifiers
    if FMenu.ShowcaseActive then
    begin
      if AAction = kaDown then
        FMenu.EndShowcase;
      Exit;
    end;
    if (AAction = kaDown) and HandleDebugMenuKey(AScancode) then
      Exit;
    // Escape steps back from a sub-screen; on the main screen it
    // resumes a running game (idle Escape at boot does nothing)
    if (AScancode = SdlScancodeEscape) and (AAction = kaDown) then
      if not FMenu.HandleEscape and FLevelLoaded then
        ResumeGame;
    Exit;
  end;

  // The story screen: Escape backs out to the menu, anything else
  // finishes the typing, then starts the game (2008 had no way back -
  // deviation logged)
  if (FState = gsIntro) and (AAction = kaDown) then
  begin
    if AScancode = SdlScancodeEscape then
      OpenMenu
    else
      AdvanceBriefing;
    Exit;
  end;

  if AAction = kaDown then
  begin
    if HandleDebugKey(AScancode) then
      Exit;
    case AScancode of
      SdlScancodeEscape:
        OpenMenu; // 2008: VK_ESCAPE raised the menu, never quit outright
      SdlScancodeLeft, ScancodeA:
        FHeldLeft := True;
      SdlScancodeRight, ScancodeD:
        FHeldRight := True;
      SdlScancodeSpace, ScancodeW, SdlScancodeUp:
        FHeldJump := True;
      ScancodeS, SdlScancodeDown:
        FHeldDown := True;
    end;
  end
  else
    case AScancode of
      SdlScancodeLeft, ScancodeA:
        FHeldLeft := False;
      SdlScancodeRight, ScancodeD:
        FHeldRight := False;
      SdlScancodeSpace, ScancodeW, SdlScancodeUp:
        FHeldJump := False;
      ScancodeS, SdlScancodeDown:
        FHeldDown := False;
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
      AdvanceBriefing;
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

end.
