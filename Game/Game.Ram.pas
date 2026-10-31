{
  Game.Ram - TeK-R13, the Ram: the TeK machine of level 2's boss arena. A
  hull on two wheels that faces left for good and drives back and forth,
  backward when it goes right; a mast of three sections in a well on its
  roof, with a head on the top of it; an eye that lights when the machine
  wakes, and brake lamps that burn as it brakes. Its two exhausts smoke a
  little at rest and hard while it drives, the jet thrown back off the
  stern.

  The eye is its telegraph: lit, it breathes slowly, and it blinks fast
  only as a warning - while a head rises or the heads change. The head's
  lens winks once a second while the head is up and locked, and burns red
  before and through a burst.

  The entrance is the machine's own: the music before it fades out, it
  drives in from beyond the right edge in the silence and brakes at its
  mark, a breath, the eye lights, the mast rises with the hunter on top,
  and the head locks - the moment the boss track starts. A death replays
  it from the stop on: the machine stands at its mark, the mast rises and
  the track plays on.

  Its hull wears the TeK shield over its body: a bullet flares the
  honeycomb and does nothing. Any touch of the hull or a wheel wounds the
  hero and throws him off - but the machine drives behind the pads: a hero
  who stands on one is out of its way, and stays so while he is over it in
  the air, until he comes down onto the floor. The throw goes away from
  its middle - straight up when that side leaves him no room to the wall
  (the screen's edge), so a hero pinned at a wall goes up toward the low
  pad there - and a thrown hero is out of its way until he comes down.
  Come down inside the hull, he has a moment to walk out of it unhurt;
  once he is clear, or the moment is over, a touch is a touch again.

  After the lock it watches the hero. Low - on the road, or in a jump off
  it under the low pads, where it can crush him - it presses: a rev, and
  to the wall on his side at a run a little slower than his. Higher -
  on a pad - it is out of reach of the ram but not of the gun: the
  machine roams in short legs, keeping him in the barrel's sights, and the
  hunter fires. With no hero to watch it roams the whole floor, one leg in
  three to the far wall.

  The hunter: its barrel turns on the sleeve within its own half, from
  straight up to a little under level, and follows the hero; past the
  vertical the head turns by squashing across its socket and opening
  mirrored. A burst comes after the lens has burned red for a while, and
  a rest comes after the burst - something to see coming and a gap to
  get out of the way. It grows harder by the thirds of its lives: three
  shots where the hero stood; three where he will be if he keeps going;
  a hose of six that keeps following him.

  The only target is the hunter's eye - its lens. Bullets pass the mast,
  the head and the barrel. Its lives show as a row of cells over the head:
  as the head locks the row lights cell by cell while the lens burns white
  - this is what has lives - and only then the first burst. The last of
  its lives blows the head up, the empty row fades; the
  empty mast sinks into the well, the eye blinks, and the next head - the
  sweeper - rises.

  The sweeper: four level barrels that do not tilt. The head rides the
  mast to the hero's row - never under its own roof - stops, its barrels
  redden, and it sweeps the row in a stream. A hero on the road is the
  ram's: the sweeper sinks to the bottom of its mast and sweeps the row
  just over his jump - the closed ceiling. By the thirds of its lives: one
  sweep; the fork - his row, then at once the row he is likely to jump
  to; the ladder - it rides the mast while it fires. The target is the
  whole barrel pack, but two honeycomb plates under it take every bullet
  that climbs: the floor does it no harm. Its last life does not blow it
  up at once. The gun falls silent and its barrels burn red, the eye
  blinks, the alarm of an arena rebuild sounds; the machine brakes to a
  stand, holds a moment, then backs off to the right wall - a hero in its
  way is touched as ever. Only there the head overloads: it heats from
  red to white, its bolts thicken - then bursts with a white flash and a
  heavier jolt than the hunter's. A shock wave runs out of the burst over
  the whole screen in about a second - a dark band behind a thin white
  front, dust kicked up where it runs along the road - and throws the
  hero clear, as a touch of the hull does but with no wound: away from
  the hull, or from over it toward the side with more road - and with the
  hull at the wall that is always the left: the chase that follows starts
  from there; come down inside the hull, he walks out of it as after any
  throw. The empty mast sinks and the machine stands at the wall; there is no third
  head yet. After the time the third would take to rise and light its
  row, and a breath, the machine drives off and the chase begins: it
  does not leave the screen, the road slides under it (Game.Belt).

  Under half its lives either head shorts out: small bolts over it, the
  more often the fewer lives are left. The hunter smokes too at its last
  third.

  As either head's lives pass into their next third the machine tells it:
  the shuttle pays for a third with a medkit, two a head.

  TRam is the rules; TRamPainter draws them with TRamArt. The game carries
  out the cue of a tick: the sounds, the shake and the boss track, and the
  wound and the throw of a touch.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Ram;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Render.Sprites, Sprites.Sets, Levels.Events,
  Levels.Dynamics, Monsters.Defs, Monsters.Hull, Game.Shield;

const
  RamWidth = 169.0;
  RamHeight = 128.0;
  // The road of the boss arena: the top of row 11
  RamFloorY = 352.0;
  RamTop = RamFloorY - RamHeight;
  // The hunter's eye on the first grade; the game scales them by its own
  HunterLives = 100;
  SweeperLives = 140;
  // Units a tick, as TBurst.NewBullet takes them
  HunterBulletSpeed = 6;
  SweeperBulletSpeed = 5;
  // The head's row of lives: three thirds of four cells
  HeadRowCells = 12;

type
  // rpWaiting - the music fades out, the machine is not on the screen yet;
  // rpBreathing - stopped at the mark of the entrance, the eye still dark;
  // rpRevving - the engine roars before it presses the hero; rpChanging -
  // a head is dead: the empty mast sinks and the next head rises
  TRamPhase = (rpAbsent, rpWaiting, rpDriving, rpBreathing, rpRising,
    rpResting, rpRevving, rpChanging);

  TRamHead = (rhNone, rhHunter, rhSweeper);

  // The gun: idle (aiming or riding, resting), the warning before a burst
  // - the hunter's lens, the sweeper's barrels burning red - the burst
  TRamFire = (rfIdle, rfFlare, rfBurst);

  // The head's row of lives as the HUD draws it
  TRamRow = record
    // A head up, or one blown up a moment ago
    Shown: Boolean;
    // Cells lit so far as the row comes up after the lock
    Lit: Integer;
    // Lives left of the full
    Share: Single;
    // Ticks since the eye was last struck
    HitTicks: Integer;
    // 1, going to 0 as the row of a dead head fades
    Fade: Single;
  end;

  // What the machine sees of the hero this tick
  // The shock wave of the sweeper's blast: its front runs out at an even
  // pace to the farthest corner of the screen and is gone
  TShockWave = record
    // How far the front runs, units
    Reach: Single;
    // Ticks since the blast; below 0 - no wave
    Ticks: Integer;
    // The hero has been thrown by it
    Threw: Boolean;
    // From AFrom, the front at nothing
    procedure Start(const AFrom: TSdlFPoint);
    procedure Stop;
    procedure Tick;
    function Running: Boolean;
    // The front ATicks after the blast, units from it
    function FrontOf(ATicks: Single): Single;
  end;

  TRamTarget = record
    Alive: Boolean;
    Body: TSdlFRect;
    // Stands on a pad
    OnDeck: Boolean;
  end;

  TRamCue = record
    // The engine runs: the rumble loops from now on
    Rumble: Boolean;
    // It has stopped: the rumble cuts to the brake's hiss
    Hiss: Boolean;
    // The mast starts up
    Whine: Boolean;
    // The head has locked at its height: the boss track
    Locked: Boolean;
    // A shake, in trauma shares; 0 - none
    Jolt: Single;
    // The head fires a bullet from ShotFrom along ShotAngle, degrees
    // counter-clockwise from the right, at ShotSpeed
    Shot: Boolean;
    ShotFrom: TSdlFPoint;
    ShotAngle: Integer;
    ShotSpeed: Integer;
    // The head has lost its last life: it blows up at BlastAt
    Blast: Boolean;
    BlastAt: TSdlFPoint;
    // The blast is the sweeper's: an overload, not a hit - the low blow,
    // the flash, and the shock wave it sends out
    Shock: Boolean;
    // One more cell of the head's row lit
    RowCell: Boolean;
    // The sweeper backs off to the wall: the alarm of an arena rebuild
    Alarm: Boolean;
    // The head's lives have passed into their next third
    Third: Boolean;
    // It drives off: the chase begins, the road slides under it
    Chase: Boolean;
  end;

  TRam = class
  private
    FBody: TShieldMask;
    FShield: TTekShield;
    FOrders: TRamOrders;
    FEntered: Boolean; // the whole entrance has begun on this level
    FPhase: TRamPhase;
    FPhaseTicks: Integer;
    FEntering: Boolean; // the drive under way is the entrance
    FAge: Integer;
    FX, FLastX: Single; // the hull's left edge, screen units
    FSpeed: Single; // units a tick, below 0 to the left
    FAccel: Single; // the change of the speed this tick
    FCruise: Single;
    FTarget: Single;
    FBraking: Boolean;
    FMast, FLastMast: Single;
    FSway, FLastSway: Single; // degrees clockwise
    FSwaySpeed: Single;
    FLamps, FLastLamps: Single;
    FLampHold: Integer;
    FEyeLit: Boolean;
    FEye, FLastEye: Single;
    FBreathTicks: Integer;
    FArmed: Boolean; // the head is up and locked
    FArmedTicks: Integer;
    FLens, FLastLens: Single;
    FHeroInFront: Boolean;
    FHeroThrown: Boolean; // flying from a throw: out of its way till he lands
    // Thrown, by a touch or the wave: ticks left to walk out of the hull
    // unhurt, if he comes down inside it
    FClearTicks: Integer;
    FArrivals: Integer;
    FDice: TXorShift;
    FCue: TRamCue;
    // The hero as it sees him, and how he moves: units a tick, smoothed
    FHero: TRamTarget;
    FHeroSeen: Boolean;
    FHeroCenter: TSdlFPoint;
    FHeroPace: TSdlFPoint;
    // Pressing a hero low on the road; the ticks that decide it
    FPressing: Boolean;
    FLowTicks, FAboveTicks, FDeckTicks: Integer;
    // The head, its lives and its facing: -1 left, as the art is drawn
    FHead: TRamHead;
    FLives, FFullLives: Integer;
    FLivesShare: Single; // the grade's
    FThirds: Integer; // the thirds of the head's lives told so far
    FHeadKilled: Boolean; // the last life is gone; it blows up next tick
    FKilled: TRamHead; // the head the change of heads began with
    FChangePending: Boolean; // braking to stand for the change of heads
    FChangeFrom: Single; // the mast's height as the change began
    FFacing: Integer;
    FTurnTicks: Integer; // a turn of the head under way, ticks left
    FPastTicks: Integer; // the hero has stood past the vertical
    // The barrel: its angle before the sway, degrees counter-clockwise from
    // the right, and the one it wants
    FAim, FLastAim: Single;
    FWant: Single;
    FInSights: Boolean; // the hero is within the barrel's half
    FFire: TRamFire;
    FFireTicks: Integer;
    FShotsLeft: Integer;
    // Where a burst goes, held from the moment the lens lights
    FFrozenAt: TSdlFPoint;
    FLensHot: Boolean;
    FHurtTicks: Integer;
    // The row of lives: ticks since the lock (-1 - none), since the last
    // hit, since the blast (-1 - none)
    FRowTicks: Integer;
    FHitTicks: Integer;
    FGoneTicks: Integer;
    // The sweeper: the row its barrels go to and sweep, a sweep of the
    // fork still to come, the way a ladder rides, the barrel that fires
    // next, how red the barrels burn
    FRowY: Single;
    FForkLeft: Boolean;
    FLadderWay: Integer;
    FNextBarrel: Integer;
    FHeat, FLastHeat: Single;
    FHeatTicks: Integer; // the whole of the burning before this sweep
    FPlates: array [0..1] of TTekShield;
    // The sweeper's last life gone: backing off to the right wall, ticks
    // since, ticks it has stood before the drive
    FRetreating: Boolean;
    FRetreatTicks: Integer;
    FStoodTicks: Integer;
    // Both heads gone, it has driven off into the chase
    FChased: Boolean;
    // Then: ticks of its overload so far
    FOverloadTicks: Integer;
    // The white of the sweeper's blast, 1 the tick it bursts, and where
    FFlash, FLastFlash: Single;
    FBlastAt: TSdlFPoint;
    FWave: TShockWave;
    procedure TickKill;
    procedure TickThirds;
    procedure BeginRetreat;
    procedure TickRetreat;
    function Spent: Boolean;
    procedure TickSpent;
    function WaveSide(const AHeroBody: TSdlFRect): Integer;
    procedure Place(AX: Single);
    procedure Arm(ALivesShare: Single);
    procedure BeginDrive(ATarget, ACruise: Single; AEntering: Boolean);
    procedure BeginRest(ATicks: Integer);
    procedure BeginLeg;
    procedure BeginPatrolLeg;
    procedure BeginHuntLeg;
    procedure BeginRev;
    procedure BeginChange;
    procedure SeeHero(const ATarget: TRamTarget);
    procedure TickMode;
    procedure PressNow;
    function PressWall: Single;
    function StopAhead: Single;
    function InSightsFrom(ALeft: Single): Boolean;
    procedure KillHead;
    procedure TickPhase;
    procedure TickChange;
    procedure TickDrive;
    procedure Arrive(AOldSpeed: Single);
    procedure TickSway;
    procedure TickAim;
    procedure TickRide;
    procedure TickFire;
    procedure TickSweep;
    procedure BeginSweep(AFlareTicks: Integer);
    function ForkRow: Single;
    procedure Shoot;
    procedure ShootBarrel;
    procedure TickHeat;
    procedure LockSweeper;
    function SweeperMastFor(ARowY: Single): Single;
    function SweeperRowY(AMast: Single): Single;
    function ToHead(const APoint: TSdlFPoint): TSdlFPoint;
    function Tier: Integer;
    function CanShoot: Boolean;
    procedure TickRow;
    function RowLit: Integer;
    procedure TickLamps;
    procedure TickEye;
    procedure TickLens;
    function Overlaps(const ABox: TSdlFRect): Boolean;
    function SpanAcross(const ABox: TSdlFRect; out AFirst,
      ALast: Integer): Boolean;
    function ThrowSide(const AHeroBody: TSdlFRect): Integer;
  public
    // ABody - the hull and the wheels on a grid of units (TRamArt.Body)
    constructor Create(const ABody: TShieldMask; ASeed: Cardinal);
    destructor Destroy; override;
    // Comes onto the screen as AOrders say: the whole entrance the first
    // time on the level - True, and the music must go silent - from the
    // stop on after that. The hunter comes with HunterLives times
    // ALivesShare.
    function Start(const AOrders: TRamOrders; ALivesShare: Single = 1): Boolean;
    // Gone from the screen: a door, a death
    procedure Clear;
    // A new level: gone, and the entrance not seen
    procedure Reset;
    function Tick(const ATarget: TRamTarget): TRamCue; overload;
    // No hero to watch: it roams and holds its fire
    function Tick: TRamCue; overload;
    // Where a bullet's stretch of this tick first meets the shield, which
    // flares there; False when it meets nothing
    function Block(const AFrom, ATo: TSdlFPoint; out AAt: TSdlFPoint): Boolean;
    // Where a bullet's stretch of this tick meets the hunter's eye, which
    // loses a life; False when it misses
    function StrikeEye(const AFrom, ATo: TSdlFPoint; out AAt: TSdlFPoint): Boolean;
    // Where a bullet's stretch of this tick meets the sweeper's barrel
    // pack: AGuarded - a climbing bullet, taken by a plate under it, which
    // flares; otherwise the pack loses a life. False when it misses.
    function StrikeBarrels(const AFrom, ATo: TSdlFPoint; out AAt: TSdlFPoint;
      out AGuarded: Boolean): Boolean;
    // The hunter's lens on the screen now
    function LensPoint: TSdlFPoint;
    // The middle of the sweeper's barrel pack on the screen now
    function BarrelsPoint: TSdlFPoint;
    // The hero's body touches the hull or a wheel and he is in the
    // machine's way: AOnDeck - he stands on a pad, AInAir - on his way up
    // or down. AAway - the side to throw him to, away from its middle; 0 -
    // straight up, pinned against a wall. A thrown hero who comes down
    // inside the hull is out of its way until he is clear of it, for
    // ClearTicks at most.
    function Contact(const AHeroBody: TSdlFRect; AOnDeck, AInAir: Boolean;
      out AAway: Integer): Boolean;
    // On the screen to be seen and touched
    function Present: Boolean;
    // Between the last tick and this one, AAlpha of the way
    function LeftAt(AAlpha: Single): Single;
    function MastAt(AAlpha: Single): Single;
    function SwayAt(AAlpha: Single): Single;
    function LampsAt(AAlpha: Single): Single;
    function EyeAt(AAlpha: Single): Single;
    function LensAt(AAlpha: Single): Single;
    function AimAt(AAlpha: Single): Single;
    // How red the sweeper's barrels burn, 0 cold to 1 the sweep
    function HeatAt(AAlpha: Single): Single;
    // Units the hull has rolled this tick, to the right above zero
    function Rolled: Single;
    // The head's width as a share of its own: 1 but in the middle of a turn
    function TurnSquash: Single;
    // At the last third of its lives
    function Wounded: Boolean;
    // How hard the head shorts out: 0 over half its lives, from the
    // tank's floor at half up to 1 as the last of them goes
    function ShortLevel: Single;
    // The sweeper has lost its last life and backs off to the right wall
    property Retreating: Boolean read FRetreating;
    // The sweeper, at the wall, overloads and has not burst yet
    function Overloading: Boolean;
    // How far the overload has gone, 0 none to 1 the burst
    function Overload: Single;
    // The white of the sweeper's blast between two ticks, 0 none to 1 the
    // tick it bursts
    function FlashAt(AAlpha: Single): Single;
    property BlastAt: TSdlFPoint read FBlastAt;
    // The shock wave's front between two ticks: units from BlastAt; below
    // 0 when there is no wave
    function WaveFrontAt(AAlpha: Single): Single;
    // How far the front runs: to the farthest corner of the screen
    property WaveReach: Single read FWave.Reach;
    // The front has reached APoint by this tick
    function WaveReaches(const APoint: TSdlFPoint): Boolean;
    // The front has reached the middle of the hero's body this tick, once a
    // wave: he is thrown to AAway, with no wound, and is out of the
    // machine's way until he comes down
    function WaveStrikes(const AHeroBody: TSdlFRect;
      out AAway: Integer): Boolean;
    // The eye or the barrels were struck a moment ago
    function Hurt: Boolean;
    // The row of lives is still coming up: the target burns white
    function Booting: Boolean;
    function Row: TRamRow;
    // The middle of the top of the head, between two ticks
    function HeadTopAt(AAlpha: Single): TSdlFPoint;
    property Head: TRamHead read FHead;
    property Facing: Integer read FFacing;
    property Lives: Integer read FLives;
    property FullLives: Integer read FFullLives;
    property Pressing: Boolean read FPressing;
    // The whole entrance has begun on this level: the hero has come to the
    // fight, and a death brings him back to it
    property Entered: Boolean read FEntered;
    // The head is up and locked
    property Armed: Boolean read FArmed;
    property Fire: TRamFire read FFire;
    // The lens burns red: a burst is coming or under way
    property LensHot: Boolean read FLensHot;
    property Body: TShieldMask read FBody;
    property Shield: TTekShield read FShield;
    // The sweeper's plates, under its barrels
    function Plate(AIndex: Integer): TTekShield;
    property Phase: TRamPhase read FPhase;
    property EyeLit: Boolean read FEyeLit;
    // How bright the eye burns, 0 dark to 1 the flash of a blink
    property Eye: Single read FEye;
    // How bright the head's lens burns, 0 dark to 1 a wink
    property Lens: Single read FLens;
    // Counts the starts: a painter that sees it change knows the machine
    // came anew, and what it left in the air is gone
    property Arrivals: Integer read FArrivals;
    // The mast's height: units the socket of the head stands over the
    // middle line of the well
    property Mast: Single read FMast;
    property Left: Single read FX;
    property Track: string read FOrders.Track;
  end;

  // The art of the Ram through a cache of its own: painted with soft edges,
  // so no color key; drawn at a size of its own, so linear filtering. The
  // hull, its worn copy and the wheels are the hull art's.
  TRamArt = class
  private
    FRenderer: PSdlRenderer;
    FSpriteSet: TSpriteSet;
    FCache: TSpriteCache;
    FWell: PSdlTexture;
    FMasts: array [1..3] of PSdlTexture;
    FHunter: PSdlTexture;
    FHunterBarrel: PSdlTexture;
    FSweeper: PSdlTexture;
    FSweeperHeat: PSdlTexture;
    FHullArt: THullArt;
    FShield: TShieldArt;
    // A point of light: the brake lamps, the eye, the lens
    FGlow: PSdlTexture;
    // The dark band of the shock wave: a ring just inside the edge of its
    // square, drawn black
    FWaveBand: PSdlTexture;
    FBody: TShieldMask;
  public
    constructor Create(ARenderer: PSdlRenderer);
    destructor Destroy; override;
    // The hull and the wheels on a grid of units, read off the art
    property Body: TShieldMask read FBody;
  end;

  TRamPainter = class
  private
    FArt: TRamArt;
    FRam: TRam;
    FHull: THull;
    FExhausts: array [0..1] of TSmoke;
    FExhaustDriving: Boolean;
    // From a wounded head, or from the top of an empty mast
    FHeadSmoke: TSmoke;
    FHeadSmoking: Boolean;
    // The bolts over a head under half its lives, one source a head
    FShorts: array [rhHunter..rhSweeper] of TLightning;
    // The thick bolts of the sweeper's overload
    FOverloadShort: TLightning;
    // The dust the wave kicks up where its front runs along the road, one
    // a side of the blast
    FWaveDust: array [0..1] of TSmoke;
    FArrivals: Integer;
    procedure TickArrival;
    procedure TickExhausts(ABeltShift: Single);
    procedure TickHeadSmoke(ABeltShift: Single);
    procedure TickShorts;
    procedure TickWaveDust;
    procedure DrawMast(const ASprites: TSpriteRenderer; ALeft, AMast,
      ASway, AAlpha: Single);
    procedure DrawHead(const ASprites: TSpriteRenderer; ALeft, AMast,
      ASway, AAlpha: Single);
    procedure DrawLamps(const ASprites: TSpriteRenderer; ALeft, AAlpha: Single);
    procedure DrawEye(const ASprites: TSpriteRenderer; ALeft, AAlpha: Single);
    procedure DrawLens(const ASprites: TSpriteRenderer; ALeft, AMast, ASway,
      AAlpha: Single);
    procedure DrawHeat(const ASprites: TSpriteRenderer; ALeft, AMast, ASway,
      AAlpha: Single);
    procedure DrawOverload(const ASprites: TSpriteRenderer; ALeft, AMast,
      ASway: Single);
    procedure DrawFlash(AOrigin: TSdlPoint; AAlpha: Single);
    procedure DrawWave(AOrigin: TSdlPoint; AAlpha: Single);
  public
    // Both belong to the caller and must outlive the painter
    constructor Create(AArt: TRamArt; ARam: TRam);
    destructor Destroy; override;
    // After the Ram's tick: the wheels roll, the exhausts smoke.
    // ABeltShift - units the road has gone left under it this tick: the
    // wheels roll by it too, the exhausts work as in a drive, and the
    // smoke in the air rides away with the road.
    procedure Tick(ABeltShift: Single);
    // The exhausts' smoke, before the body: the machine backs into it
    procedure DrawSmoke(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // The machine, on the world's shake channel the sprites stand at
    procedure DrawBody(const ASprites: TSpriteRenderer; AAlpha: Single);
    // The dust of the wave, the bolts of a head, the shield, the sweeper's
    // plates, the wave itself and the white of the blast
    procedure DrawLight(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  end;

implementation

uses
  System.SysUtils, System.Math, Render.Glow, Levels.Tint, Game.Space;

resourcestring
  SRamArtFailed = 'Cannot read the Ram''s body off "%s": %s';

type
  // A third of the hunter's lives: how long the lens burns before the
  // burst, how many shots and how far apart, the rest after; Lead - it
  // aims where he will be; Hose - it keeps following him through the burst
  TFirePattern = record
    FlareTicks, Shots, GapTicks, RestTicks: Integer;
    Lead, Hose: Boolean;
  end;

  THeadShape = record
    Width, Height, SocketX, SocketY: Single;
  end;

  // A third of the sweeper's lives: how long the barrels burn before the
  // sweep, how many shots and how far apart, the rest after; Fork - a
  // second sweep at once, a row over or under; Ladder - it rides the mast
  // while it sweeps
  TSweepPattern = record
    HeatTicks, Shots, GapTicks, RestTicks: Integer;
    Fork, Ladder: Boolean;
  end;

const
  FirePatterns: array [0..2] of TFirePattern = (
    (FlareTicks: 20; Shots: 3; GapTicks: 4; RestTicks: 50; Lead: False; Hose: False),
    (FlareTicks: 16; Shots: 3; GapTicks: 4; RestTicks: 40; Lead: True; Hose: False),
    (FlareTicks: 14; Shots: 6; GapTicks: 5; RestTicks: 45; Lead: False; Hose: True));

  SweepPatterns: array [0..2] of TSweepPattern = (
    (HeatTicks: 22; Shots: 8; GapTicks: 3; RestTicks: 55; Fork: False; Ladder: False),
    (HeatTicks: 18; Shots: 8; GapTicks: 3; RestTicks: 50; Fork: True; Ladder: False),
    (HeatTicks: 16; Shots: 12; GapTicks: 3; RestTicks: 50; Fork: False; Ladder: True));

  // The heads as the art draws them, facing left; the socket at the bottom
  HeadShapes: array [TRamHead] of THeadShape = (
    (Width: 0; Height: 0; SocketX: 0; SocketY: 0),
    (Width: 27.7; Height: 18.8; SocketX: 16.6; SocketY: 18.7),
    (Width: 42.1; Height: 18.7; SocketX: 29.2; SocketY: 18.7));

const
  LogicTicksPerSecond = 33;
  RamSetName = 'tek-machine';

  // The entrance. The hull comes in a little beyond the right edge, so its
  // rumble is heard before its ram is seen; about 3 s from the edge to the
  // stop.
  EnterFromX = ScreenWidth + 40;
  EnterSpeed = 2.8; // units a tick
  // Units a tick every tick, braking and getting up to speed alike: a
  // stop from the entrance's speed takes about 20 units
  Brake = 0.2;
  // A brake never comes to rest short of its mark
  CreepSpeed = 0.3;
  // The silence after the fade-out, before the rumble
  SilenceBeatTicks = 16;
  BreathTicks = 16;
  RiseTicks = 50;
  // From the lock to the first drive of the fight
  LockRestTicks = 33;
  EntranceStopJolt = 0.25;

  // The fight: a mark anywhere the hull fits between the walls, a leg of a
  // cell and a half at least, a rest of 1.5 to 3 s between legs; now and
  // then a leg to the far wall
  PatrolSpeed = 1.4;
  PatrolMinLeg = 48;
  WallLegShare = 1 / 3;
  PatrolRestMinTicks = 50;
  PatrolRestMaxTicks = 100;
  PatrolStopJolt = 0.12;

  // Low is where the ram can crush him: feet under the line two cells over
  // the road - the road and a jump off it, not the low pads (their decks
  // stand at 280). It presses once he has been low this long; it lets go
  // once he has stood on a pad, or kept above the line, this long.
  LowLine = RamFloorY - 64;
  PressAfterTicks = 10;
  LeaveOnDeckTicks = 6;
  LeaveAboveTicks = 33;
  // The press: a rev, then to the wall on his side a little slower than he
  // runs (2 a tick); at the last third a little faster. A short rest at the
  // wall, then it looks again.
  RevTicks = 8;
  RevJolt = 0.06;
  PressSpeeds: array [0..2] of Single = (1.9, 1.9, 2.1);
  PressRestTicks = 13;
  // The hunt: short legs that keep the hero in the barrel's sights
  HuntSpeed = 1.1;
  HuntMinLeg = 32;
  HuntMaxLeg = 96;
  HuntRestMinTicks = 15;
  HuntRestMaxTicks = 40;
  // Out of its sights it does not stand long
  HuntBlindRestTicks = 5;

  // The barrel aims within its half, from straight up to this far under
  // level; it turns this fast following the hero, and the hose of the last
  // third follows him slower through its burst
  AimBelow = 25.0;
  TrackRate = 3.0;
  HoseRate = 2.0;
  // A burst begins once the barrel is this close to where it wants to be
  AimSlack = 3.0;
  // The head turns once the hero has stood past the vertical this far, this
  // long; the turn itself, squashed across the socket and opened mirrored
  TurnPast = 15.0;
  TurnHoldTicks = 10;
  TurnTicks = 10;
  // The lead of the second third: so far ahead at most
  LeadMax = 80.0;
  // How fast the eye learns how the hero moves
  PaceLearn = 0.3;
  // From the lock to the first burst
  FirstBurstTicks = 33;

  // The change of heads: the empty mast sinks, a beat, the next head rises
  SinkTicks = 25;
  EmptyTicks = 5;
  ChangeRiseTicks = 30;
  SweeperMast = 48.0;
  // After the sweeper, the breath between the third head's row lit and
  // the chase: within 0.5-1 s
  ChaseBreathTicks = 25;
  HeadBlastJolt = 0.5;
  // A hero thrown, by a touch or the wave, who comes down inside the hull
  // walks out of it unhurt for this long after he lands: from its middle
  // at a run, half its length, is about 45 ticks
  ClearTicks = 60;
  // The sweeper's end. First it backs off to the right wall: a stand of
  // half a second, then the drive, the alarm every 1.5 s (the hum lasts
  // 1.2), the barrels throbbing red. From the far wall about 4.5 s.
  RetreatStandTicks = 16;
  RetreatSpeed = 2.5;
  AlarmEveryTicks = 50;
  RetreatHeatLow = 0.6;
  RetreatThrobTicks = 16;
  // At the wall about 0.6 s of overload, then a blast that shakes harder
  // than the hunter's and whites the screen out for a few ticks
  OverloadTicks = 20;
  SweeperBlastJolt = 0.8;
  BlastFlashTicks = 6;
  // The shock wave crosses the screen to its farthest corner in a second
  WaveTicks = 33;
  NoWave = -1;
  ScreenCorners: array [0..3] of TSdlFPoint = ((X: 0; Y: 0),
    (X: ScreenWidth; Y: 0), (X: 0; Y: ScreenHeight),
    (X: ScreenWidth; Y: ScreenHeight));

  // The sweeper rides the mast between its roof and three cells: its
  // barrels' bottom never under the roof line. It follows the hero's row
  // this fast and sweeps once it stands this near it; a fork's second row
  // is a cell away, and a ladder rides this fast while it sweeps.
  SweeperMastLowest = 12.0;
  SweeperMastHighest = 96.0;
  RideRate = 1.5;
  RowSlack = 4.0;
  ForkStep = 32.0;
  ForkHeatTicks = 10;
  LadderRate = 1.3;
  // The hero stands this far past the socket on the other side for
  // TurnHoldTicks, and the sweeper turns to him
  SweeperTurnPast = 8.0;
  // On the sweeper, facing left: the barrel pack, its four muzzles, the
  // plates under it (their middles; strips of two small cells)
  BarrelsLeft = 0.0;
  BarrelsRight = 17.5;
  BarrelsTop = 2.0;
  BarrelsBottom = 14.0;
  MuzzleX = 0.2;
  MuzzleYs: array [0..3] of Single = (3.4, 6.4, 9.4, 12.6);
  PlateCells = 2;
  PlateScale = 0.6;
  PlateMiddles: array [0..1] of THullPoint = ((X: 4.5; Y: 16.0),
    (X: 13.0; Y: 16.0));
  PlateBottom = 18.0;
  // A bullet that climbs steeper than this comes from below: the plates
  // take it
  PlateCover = 6.0;
  // A turn this far squashed leaves no pack to hit
  ThinHeadSquash = 0.5;
  // Along a stretch the pack is looked for this often, head units
  StrikeStep = 0.5;
  // The barrels' white while its row comes up, and their red
  HeatWhite: TRgb = (R: 255; G: 255; B: 255);
  HeatRed: TRgb = (R: 255; G: 48; B: 28);
  HeatFrom = 0.4;

  // The eye: a circle around the lens; a hit flashes it white
  EyeRadius = 5.0;
  HurtFlashTicks = 4;
  LensFlareFrom = 0.4;

  // The row of lives comes up a cell at a time after the lock, under a
  // second - before the first burst; a dead head's row fades
  RowBootTicks = 30;
  RowFadeTicks = 20;
  // Long enough ago to be no hit at all
  NoHitTicks = 10000;

  // The mast. Its height is how far the socket of the head stands over the
  // middle line of the well: at rest the head lies under the opening, out
  // of sight; three cells is the most. The hunter stands at a cell and a
  // half.
  WellX = 69.9;
  WellY = 14.6;
  MastRest = -20.0;
  HunterMast = 48.0;
  // Below this line of the hull the sections stay inside it, and drawn
  // behind it they would show through the open arch over the front wheel
  MastHiddenBelow = 90.0;
  // Widest first; the art's sizes, units
  MastWidths: array [1..3] of Single = (31.4, 22.6, 16.8);
  MastLengths: array [1..3] of Single = (78.0, 69.6, 65.9);
  // On the hunter: the sleeve the barrel turns on, the lens; the barrel's
  // size, its pivot on the sleeve and its muzzle, lying level to the left
  HunterSleeveX = 1.9;
  HunterSleeveY = 7.1;
  HunterLensX = 17.1;
  HunterLensY = 8.8;
  BarrelWidth = 33.3;
  BarrelHeight = 9.3;
  BarrelPivotX = 30.9;
  BarrelMuzzleX = 0.2;

  // The mast sways: a spring that the drive's starts and stops kick, over
  // a slow sway of its own. A brake leans its top forward about 4 degrees.
  SwaySpring = 0.02;
  SwayDamping = 0.12;
  SwayInertia = 0.4;
  SwayMax = 8.0;
  IdleSway = 0.6;
  IdleSwayTicks = 150;

  LampHoldTicks = 20;
  LampFade = 0.08;
  LampPoints: array [0..1] of THullPoint = ((X: 160.9; Y: 43.3),
    (X: 160.9; Y: 51.2));
  LampSize = 8.0;
  LampColor: TRgb = (R: 255; G: 48; B: 32);
  GlowSide = 64;

  // The eye, lit: a slow breath between two dim levels; a warning is a
  // fast blink between a flash and next to nothing. Its size grows with
  // the square of the level, so the breath barely swells it.
  EyeBreathLow = 0.3;
  EyeBreathHigh = 0.55;
  EyeBreathTicks = 83;
  EyeBlinkLow = 0.1;
  EyeBlinkTicks = 3; // each half of a blink
  EyeRestSize = 4.0;
  EyeFlashSize = 9.0;
  EyeColor: TRgb = (R: 255; G: 36; B: 20);

  // The lens of the head, armed: a wink a second over a faint ember. Pale,
  // not red: red on this machine is a warning, and a light that burns red
  // all the time would teach the player to ignore it.
  LensPeriodTicks = 33;
  LensWinkTicks = 4;
  LensEmber = 0.15;
  LensEmberSize = 2.5;
  LensWinkSize = 7.0;
  LensColor: TRgb = (R: 220; G: 236; B: 255);
  // Before and through a burst: bigger and red, held
  LensHotSize = 10.0;
  LensHotColor: TRgb = (R: 255; G: 40; B: 24);
  LensHurtSize = 9.0;

  // A wounded head smokes, and so does an empty mast going down: thin,
  // slow, no air to lift it
  HeadSmokeLook: TSmokeLook = (Rate: 12; Life: 1.6; Size: 3; EndSize: 16;
    Opacity: 0.5; Angle: 90; Cone: 50; Speed: 10; Drag: 0.5; Lift: 0;
    Wind: 0; Turbulence: 4; Spin: 30; Flow: sfGusty; Frequency: 1;
    Heat: 0; EndTint: (R: 40; G: 40; B: 44));
  HeadSmokeSeed = $48656164; // "Head"
  HeadSmokeRampTicks = 10;

  // Under half its lives a head shorts out as the tank's wreck does, and
  // from the wreck's floor: the bolts of a head just under half come
  // about once a second, of one at its last life twice
  ShortFloor = 0.35;
  ShortSpan = 0.65;
  // Over the middle of the head, in a box about its width
  HeadShorts: array [rhHunter..rhSweeper] of TLightningLook = (
    (Reach: 14; Spread: (X: 10; Y: 6); Angle: 90; Cone: 360; Collide: lcNone;
    Size: 0.9; Jag: 0.26; Fork: 0.18; Frequency: 2.2; Strokes: 2; Life: 0.11;
    Leader: 0; Spell: 0; Pause: 0; Flash: 0.55; Jolt: 0;
    Tint: (R: 66; G: 74; B: 100)),
    (Reach: 16; Spread: (X: 16; Y: 6); Angle: 90; Cone: 360; Collide: lcNone;
    Size: 1; Jag: 0.26; Fork: 0.18; Frequency: 2.2; Strokes: 2; Life: 0.11;
    Leader: 0; Spell: 0; Pause: 0; Flash: 0.55; Jolt: 0;
    Tint: (R: 66; G: 74; B: 100)));
  ShortSeeds: array [rhHunter..rhSweeper] of Cardinal = ($53687431,
    $53687432); // "Sht1", "Sht2"
  // The overload over its shorts: longer, thicker, many times as often
  OverloadShortLook: TLightningLook = (Reach: 24; Spread: (X: 16; Y: 6);
    Angle: 90; Cone: 360; Collide: lcNone; Size: 1.8; Jag: 0.3; Fork: 0.3;
    Frequency: 9; Strokes: 3; Life: 0.09; Leader: 0; Spell: 0; Pause: 0;
    Flash: 0.8; Jolt: 0; Tint: (R: 80; G: 88; B: 100));
  OverloadShortSeed = $4F766C64; // "Ovld"
  // The head whitening: its art once more over itself, added
  OverloadWhite = 0.9;
  // The blast's white: the whole frame, and a light about the head
  FlashScreen = 0.85;
  FlashGlowSize = 160.0;
  FlashColor: TRgb = (R: 255; G: 255; B: 255);
  // The shock wave as in film, with no color: a dark band just behind a
  // thin white front, both fading as it runs out. The band is a ring of
  // its square at WaveBandRadius of the half side, WaveBandWidth across.
  WaveBandSide = 256;
  WaveBandRadius = 0.93;
  WaveBandWidth = 0.05;
  WaveBandDepth = 0.6;
  WaveFrontWidth = 1.2;
  WaveFrontLevel = 0.85;
  WaveFrontSegments = 96;
  WaveBlack: TRgb = (R: 0; G: 0; B: 0);
  // The road's dust where the front runs along it: thrown up a little,
  // no air to carry it, settling as it fades
  WaveDustLook: TSmokeLook = (Rate: 70; Life: 1.1; Size: 3; EndSize: 14;
    Opacity: 0.45; Angle: 90; Cone: 70; Speed: 14; Drag: 0.4; Lift: 0;
    Wind: 0; Turbulence: 2; Spin: 20; Flow: sfGusty; Frequency: 1;
    Heat: 0; EndTint: (R: 50; G: 48; B: 45));
  WaveDustTint: TColorTint = (R: 70; G: 68; B: 64);
  WaveDustSeeds: array [0..1] of Cardinal = ($44737431, $44737432); // "Dst1"
  // Its puffs rise off the road, not out of it
  WaveDustOverRoad = 1.0;

  // The exhausts: where the jet leaves the mouths of the two pipes on the
  // stern. It flies back on its own speed and does not rise - no air to
  // lift it - and comes in puffs at the rate the rumble throbs.
  ExhaustPoints: array [0..1] of THullPoint = ((X: 167.3; Y: 14.9),
    (X: 167.3; Y: 28.5));
  ExhaustSmoke: TSmokeLook = (Rate: 30; Life: 1.3; Size: 3; EndSize: 20;
    Opacity: 0.55; Angle: 8; Cone: 24; Speed: 34; Drag: 0.6; Lift: 0;
    Wind: 0; Turbulence: 3; Spin: 40; Flow: sfPuffs; Frequency: 4;
    Heat: 0; EndTint: (R: 46; G: 46; B: 50));
  ExhaustTint: TColorTint = (R: 62; G: 62; B: 64);
  ExhaustIdle = 0.3;
  ExhaustRampTicks = 8;
  ExhaustSeeds: array [0..1] of Cardinal = ($45786831, $45786832); // "Exh1"

  // Read off the art: a unit of the grid is solid where the art is this
  // opaque at its middle
  BodyAlpha = 128;
  Axles: array [0..1] of THullPoint = ((X: 61.1; Y: 107.5),
    (X: 133.2; Y: 107.5));
  WheelRadius = 20.5;
  WheelSide = 41.0;
  EyePoint: THullPoint = (X: 22.2; Y: 54.8);

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

// APoint turned ADegrees clockwise about APivot, on the screen
function Turned(const APoint, APivot: TSdlFPoint; ADegrees: Single): TSdlFPoint;
begin
  var Angle := DegToRad(ADegrees);
  var AcrossX := APoint.X - APivot.X;
  var DownY := APoint.Y - APivot.Y;
  Result.X := APivot.X + AcrossX * Cos(Angle) - DownY * Sin(Angle);
  Result.Y := APivot.Y + AcrossX * Sin(Angle) + DownY * Cos(Angle);
end;

function UnitPoint(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

// The middle of the well, which the mast turns about with the sway
function MastPivot(ALeft: Single): TSdlFPoint;
begin
  Result := UnitPoint(ALeft + WellX, RamTop + WellY);
end;

// A point of a head's art, AX, AY units from its corner as drawn facing
// left, on the screen: the head on the top of the mast, facing AFacing,
// squashed to ASquash of its width about the socket, all of it turned with
// the sway
function HeadPoint(ALeft, AMast, ASway: Single; AHead: TRamHead;
  AFacing: Integer; ASquash, AX, AY: Single): TSdlFPoint;
begin
  var Shape := HeadShapes[AHead];
  var Pivot := MastPivot(ALeft);
  var Upright := UnitPoint(Pivot.X - AFacing * (AX - Shape.SocketX) * ASquash,
    Pivot.Y - AMast + AY - Shape.SocketY);
  Result := Turned(Upright, Pivot, ASway);
end;

// Along ADegrees counter-clockwise from the right, a unit long, on the
// screen
function Heading(ADegrees: Single): TSdlFPoint;
begin
  var Angle := DegToRad(ADegrees);
  Result := UnitPoint(Cos(Angle), -Sin(Angle));
end;

// Degrees counter-clockwise from the right, from AFrom toward ATo
function Bearing(const AFrom, ATo: TSdlFPoint): Single;
begin
  Result := RadToDeg(ArcTan2(AFrom.Y - ATo.Y, ATo.X - AFrom.X));
end;

// The bearing as the barrel of a head facing AFacing can take it: within
// its half, from straight up to AimBelow under level. A hero on the other
// side holds it straight up, waiting for the head to turn; one too low
// holds it at its lowest. AReached - no limit held it.
function AimWithin(ABearing: Single; AFacing: Integer;
  out AReached: Boolean): Single;
begin
  AReached := False;
  Result := ABearing;
  if AFacing < 0 then
  begin
    if Result < 0 then
      Result := Result + 360;
    if (Result < 90) or (Result > 270) then
      Exit(90);
    if Result > 180 + AimBelow then
      Exit(180 + AimBelow);
  end
  else
  begin
    if (Result > 90) or (Result < -90) then
      Exit(90);
    if Result < -AimBelow then
      Exit(-AimBelow);
  end;
  AReached := True;
end;

function RamHullDef: THullDef;
begin
  Result := Default(THullDef);
  Result.SetName := RamSetName;
  Result.Width := RamWidth;
  Result.Height := RamHeight;
  Result.WearFull := 1;
  Result.Eye := EyePoint;
  Result.Wheels.Side := WheelSide;
  Result.Wheels.Radius := WheelRadius;
  Result.Wheels.Axles := [Axles[0], Axles[1]];
end;

// ---------------------------------------------------------------------------
// TShockWave
// ---------------------------------------------------------------------------

procedure TShockWave.Start(const AFrom: TSdlFPoint);
begin
  Ticks := 0;
  Threw := False;
  Reach := 0;
  for var Corner in ScreenCorners do
    Reach := Max(Reach, Hypot(Corner.X - AFrom.X, Corner.Y - AFrom.Y));
end;

procedure TShockWave.Stop;
begin
  Ticks := NoWave;
  Threw := False;
end;

// Gone once past the farthest corner
procedure TShockWave.Tick;
begin
  if not Running then
    Exit;
  Inc(Ticks);
  if Ticks > WaveTicks then
    Stop;
end;

function TShockWave.Running: Boolean;
begin
  Result := Ticks <> NoWave;
end;

function TShockWave.FrontOf(ATicks: Single): Single;
begin
  Result := Reach * EnsureRange(ATicks / WaveTicks, 0, 1);
end;

// ---------------------------------------------------------------------------
// TRam
// ---------------------------------------------------------------------------

constructor TRam.Create(const ABody: TShieldMask; ASeed: Cardinal);
begin
  inherited Create;
  FBody := ABody;
  FShield := TTekShield.CreateOver(ABody);
  for var i := Low(FPlates) to High(FPlates) do
    FPlates[i] := TTekShield.CreateStrip(PlateCells, PlateScale);
  FDice.Seed := ASeed;
  FWave.Stop;
end;

destructor TRam.Destroy;
begin
  for var Plate in FPlates do
    Plate.Free;
  FShield.Free;
  inherited;
end;

procedure TRam.Place(AX: Single);
begin
  FX := AX;
  FLastX := AX;
  FSpeed := 0;
  FAccel := 0;
  FBraking := False;
  FMast := MastRest;
  FLastMast := MastRest;
  FSway := 0;
  FLastSway := 0;
  FSwaySpeed := 0;
  FLamps := 0;
  FLastLamps := 0;
  FLampHold := 0;
  FEyeLit := False;
  FEye := 0;
  FLastEye := 0;
  FBreathTicks := 0;
  FArmed := False;
  FLens := 0;
  FLastLens := 0;
  FHeroInFront := False;
  FHeroThrown := False;
  FClearTicks := 0;
end;

// A fight from its start: the hunter on the mast with all its lives,
// facing left, the barrel level, the gun quiet, nobody pressed
procedure TRam.Arm(ALivesShare: Single);
begin
  FHead := rhHunter;
  FKilled := rhNone;
  FLivesShare := ALivesShare;
  FFullLives := Max(1, Round(HunterLives * ALivesShare));
  FLives := FFullLives;
  FThirds := 0;
  FHeadKilled := False;
  FChangePending := False;
  FFacing := -1;
  FTurnTicks := 0;
  FPastTicks := 0;
  FAim := 180;
  FLastAim := 180;
  FWant := 180;
  FInSights := False;
  FFire := rfIdle;
  FFireTicks := FirstBurstTicks;
  FLensHot := False;
  FHurtTicks := 0;
  FRowTicks := -1;
  FHitTicks := NoHitTicks;
  FGoneTicks := -1;
  FPressing := False;
  FLowTicks := 0;
  FAboveTicks := 0;
  FDeckTicks := 0;
  FHeroSeen := False;
  FForkLeft := False;
  FLadderWay := 0;
  FNextBarrel := 0;
  FHeat := 0;
  FLastHeat := 0;
  FRetreating := False;
  FRetreatTicks := 0;
  FStoodTicks := 0;
  FChased := False;
  FOverloadTicks := 0;
  FFlash := 0;
  FLastFlash := 0;
  FWave.Stop;
end;

function TRam.Start(const AOrders: TRamOrders; ALivesShare: Single): Boolean;
begin
  FOrders := AOrders;
  Result := not FEntered;
  FEntered := True;
  Inc(FArrivals);
  FShield.Rise;
  for var Plate in FPlates do
    Plate.Rise;
  Arm(ALivesShare);
  if Result then
  begin
    Place(EnterFromX);
    FPhase := rpWaiting;
    FPhaseTicks := Round(AOrders.SilenceSeconds * LogicTicksPerSecond) +
      SilenceBeatTicks;
  end
  else
  begin
    Place(AOrders.Stop);
    FPhase := rpBreathing;
    FPhaseTicks := BreathTicks;
  end;
end;

procedure TRam.Clear;
begin
  FPhase := rpAbsent;
  FSpeed := 0;
  FEyeLit := False;
  FEye := 0;
  FArmed := False;
  FLens := 0;
  FLensHot := False;
  FFire := rfIdle;
  FPressing := False;
  FHeroInFront := False;
  FHeroThrown := False;
  FClearTicks := 0;
  FFlash := 0;
  FLastFlash := 0;
  FWave.Stop;
end;

procedure TRam.Reset;
begin
  Clear;
  FEntered := False;
end;

function TRam.Present: Boolean;
begin
  Result := not (FPhase in [rpAbsent, rpWaiting]);
end;

procedure TRam.BeginDrive(ATarget, ACruise: Single; AEntering: Boolean);
begin
  FTarget := ATarget;
  FCruise := ACruise;
  FEntering := AEntering;
  FPhase := rpDriving;
  FCue.Rumble := True;
end;

procedure TRam.BeginRest(ATicks: Integer);
begin
  FPhase := rpResting;
  FPhaseTicks := ATicks;
end;

// The far wall now and then, so no floor by a wall is safe from it; else
// somewhere the hull fits, far enough to be a leg
procedure TRam.BeginPatrolLeg;
const
  Tries = 8;
begin
  var Highest: Single := ScreenWidth - RamWidth;
  if FDice.NextUnit < WallLegShare then
  begin
    var Wall: Single := 0;
    if FX < Highest / 2 then
      Wall := Highest;
    BeginDrive(Wall, PatrolSpeed, False);
    Exit;
  end;

  var Target := FX;
  for var i := 1 to Tries do
  begin
    Target := Highest * FDice.NextUnit;
    if Abs(Target - FX) >= PatrolMinLeg then
      Break;
  end;
  BeginDrive(Target, PatrolSpeed, False);
end;

// With no hero it roams; a hero low it presses, a hero high it hunts
procedure TRam.BeginLeg;
begin
  if not FHero.Alive then
    BeginPatrolLeg
  else if FPressing then
    BeginRev
  else
    BeginHuntLeg;
end;

// A short leg either way from where he stays in its sights; when no such
// leg comes up, the one farthest from him
procedure TRam.BeginHuntLeg;
const
  Tries = 8;
begin
  var Highest: Single := ScreenWidth - RamWidth;
  var Farthest := FX;
  var FarthestGap: Single := -1;
  for var i := 1 to Tries do
  begin
    var Way := HuntMinLeg + FDice.NextUnit * (HuntMaxLeg - HuntMinLeg);
    if FDice.NextUnit < 0.5 then
      Way := -Way;
    var Target := EnsureRange(FX + Way, 0, Highest);
    if Abs(Target - FX) < HuntMinLeg / 2 then
      Continue;
    if InSightsFrom(Target) then
    begin
      BeginDrive(Target, HuntSpeed, False);
      Exit;
    end;
    var Gap := Abs(Target + RamWidth / 2 - FHeroCenter.X);
    if Gap > FarthestGap then
    begin
      FarthestGap := Gap;
      Farthest := Target;
    end;
  end;
  if FarthestGap < 0 then
  begin
    Farthest := 0;
    if FX < Highest / 2 then
      Farthest := Highest;
  end;
  BeginDrive(Farthest, HuntSpeed, False);
end;

// The engine roars and the exhausts puff before the press
procedure TRam.BeginRev;
begin
  FPhase := rpRevving;
  FPhaseTicks := RevTicks;
  FCue.Rumble := True;
  FCue.Jolt := Max(FCue.Jolt, RevJolt);
end;

// The wall on the hero's side; the other one when it already stands there
function TRam.PressWall: Single;
begin
  var Highest: Single := ScreenWidth - RamWidth;
  Result := 0;
  if FHeroCenter.X > FX + RamWidth / 2 then
    Result := Highest;
  if Abs(Result - FX) < PatrolMinLeg then
    Result := Highest - Result;
end;

// Standing at ALeft, could the hunter's barrel reach him - is he no
// lower than its lowest. The sweeper rides to his row from anywhere.
function TRam.InSightsFrom(ALeft: Single): Boolean;
begin
  if FHead <> rhHunter then
    Exit(True);
  var Facing := -1;
  if FHeroCenter.X > ALeft + WellX then
    Facing := 1;
  var Sleeve := HeadPoint(ALeft, HunterMast, 0, rhHunter, Facing, 1,
    HunterSleeveX, HunterSleeveY);
  AimWithin(Bearing(Sleeve, FHeroCenter), Facing, Result);
end;

function TRam.Tick: TRamCue;
begin
  Result := Tick(Default(TRamTarget));
end;

function TRam.Tick(const ATarget: TRamTarget): TRamCue;
begin
  FCue := Default(TRamCue);
  if FPhase = rpAbsent then
    Exit(FCue);

  Inc(FAge);
  FLastX := FX;
  FLastMast := FMast;
  FLastSway := FSway;
  FLastLamps := FLamps;
  FLastEye := FEye;
  FLastLens := FLens;
  FLastAim := FAim;
  FLastHeat := FHeat;
  FLastFlash := FFlash;
  FFlash := Max(0, FFlash - 1 / BlastFlashTicks);
  // The way out counts from the moment he lands
  if (FClearTicks > 0) and not FHeroThrown then
    Dec(FClearTicks);
  FAccel := 0;
  SeeHero(ATarget);
  TickThirds;
  TickKill;
  FWave.Tick;
  TickMode;
  TickPhase;
  TickRow;
  TickSway;
  TickAim;
  TickFire;
  TickLamps;
  TickEye;
  TickLens;
  TickHeat;
  FShield.Tick;
  for var Plate in FPlates do
    Plate.Tick;
  Result := FCue;
end;

// Where he is and how he moves, learnt over a few ticks
procedure TRam.SeeHero(const ATarget: TRamTarget);
begin
  FHero := ATarget;
  if not ATarget.Alive then
  begin
    FHeroSeen := False;
    FHeroPace := UnitPoint(0, 0);
    Exit;
  end;
  var Center := UnitPoint(ATarget.Body.X + ATarget.Body.W / 2,
    ATarget.Body.Y + ATarget.Body.H / 2);
  if FHeroSeen then
  begin
    FHeroPace.X := Lerp(FHeroPace.X, Center.X - FHeroCenter.X, PaceLearn);
    FHeroPace.Y := Lerp(FHeroPace.Y, Center.Y - FHeroCenter.Y, PaceLearn);
  end;
  FHeroCenter := Center;
  FHeroSeen := True;
end;

// One third a tick: a volley that crosses two is told over two ticks. The
// last life is a blast, not a third.
procedure TRam.TickThirds;
begin
  if (FHead = rhNone) or FHeadKilled or (Tier <= FThirds) then
    Exit;
  Inc(FThirds);
  FCue.Third := True;
end;

// The last life gone: the hunter blows up at once; the sweeper backs off
// to the right wall, overloads there and bursts at the end of it
procedure TRam.TickKill;
begin
  if not FHeadKilled then
    Exit;
  if FHead <> rhSweeper then
  begin
    KillHead;
    Exit;
  end;
  // The tick it stands at the wall the overload begins
  if FRetreating then
  begin
    TickRetreat;
    if FRetreating then
      Exit;
  end;
  if FOverloadTicks < OverloadTicks then
  begin
    Inc(FOverloadTicks);
    Exit;
  end;
  KillHead;
end;

// The gun falls silent and the head stands where it is; a machine that
// drives brakes to a stand, one that revs or rests stays standing
procedure TRam.BeginRetreat;
begin
  FFire := rfIdle;
  FTurnTicks := 0;
  FPressing := False;
  case FPhase of
    rpDriving:
      if not FEntering then
        FTarget := StopAhead;
    rpRevving:
      BeginRest(0);
  end;
end;

// A stand first, then back to the right wall; standing there, it is done
// and the overload begins
procedure TRam.TickRetreat;
begin
  if FRetreatTicks = 0 then
    BeginRetreat;
  if FRetreatTicks mod AlarmEveryTicks = 0 then
    FCue.Alarm := True;
  Inc(FRetreatTicks);
  if FPhase = rpDriving then
    Exit;
  if FStoodTicks < RetreatStandTicks then
  begin
    Inc(FStoodTicks);
    Exit;
  end;
  var Wall: Single := ScreenWidth - RamWidth;
  if FX < Wall then
    BeginDrive(Wall, RetreatSpeed, False)
  else
    FRetreating := False;
end;

// Both heads gone: it stands at the wall, where the chase will begin
function TRam.Spent: Boolean;
begin
  Result := (FHead = rhNone) and (FKilled = rhSweeper);
end;

// Standing at the wall it waits out its rest, then drives off - once
procedure TRam.TickSpent;
begin
  if FChased then
    Exit;
  if FPhaseTicks > 0 then
  begin
    Dec(FPhaseTicks);
    Exit;
  end;
  FChased := True;
  FCue.Chase := True;
  FCue.Rumble := True;
end;

// Low long enough - the press; on a pad, or high, long enough - the hunt.
// An overloading head presses nobody.
procedure TRam.TickMode;
begin
  if FHeadKilled or Spent then
  begin
    FPressing := False;
    Exit;
  end;
  var Low := FHero.Alive and not FHero.OnDeck and
    (FHero.Body.Y + FHero.Body.H > LowLine);
  FLowTicks := IfThen(Low, FLowTicks + 1, 0);
  FAboveTicks := IfThen(FHero.Alive and not Low, FAboveTicks + 1, 0);
  FDeckTicks := IfThen(FHero.Alive and FHero.OnDeck, FDeckTicks + 1, 0);

  if FPressing then
  begin
    if not FHero.Alive or (FDeckTicks >= LeaveOnDeckTicks) or
      (FAboveTicks >= LeaveAboveTicks) then
      FPressing := False;
    Exit;
  end;
  if FLowTicks >= PressAfterTicks then
  begin
    FPressing := True;
    PressNow;
  end;
end;

// The press begins: a rest ends at once; a hunting leg toward him runs on
// at the press's pace, one away from him brakes first
procedure TRam.PressNow;
begin
  case FPhase of
    rpResting:
      FPhaseTicks := 0;
    rpDriving:
      if not FEntering and not FChangePending then
      begin
        var Wall := PressWall;
        var Way := Sign(FSpeed);
        if (Way = 0) or (Sign(Wall - FX) = Way) then
        begin
          FTarget := Wall;
          FCruise := PressSpeeds[Tier];
        end
        else
          FTarget := StopAhead;
      end;
  end;
end;

// Where it comes to rest braking from now on, short of the walls
function TRam.StopAhead: Single;
begin
  var Pace := Abs(FSpeed);
  Result := EnsureRange(FX + Sign(FSpeed) * (Sqr(Pace) / (2 * Brake) + Pace / 2),
    0, ScreenWidth - RamWidth);
end;

// The last life gone: the head blows up, and the machine stands for the
// change - at once, or once it has braked
procedure TRam.KillHead;
begin
  FHeadKilled := False;
  FCue.Blast := True;
  var Shape := HeadShapes[FHead];
  FCue.BlastAt := HeadPoint(FX, FMast, FSway, FHead, FFacing, TurnSquash,
    Shape.Width / 2, Shape.Height / 2);
  FCue.Jolt := Max(FCue.Jolt, HeadBlastJolt);
  FBlastAt := FCue.BlastAt;
  if FHead = rhSweeper then
  begin
    FCue.Shock := True;
    FCue.Jolt := Max(FCue.Jolt, SweeperBlastJolt);
    FFlash := 1;
    FOverloadTicks := 0;
    FWave.Start(FBlastAt);
  end;
  FKilled := FHead;
  FHead := rhNone;
  FArmed := False;
  FFire := rfIdle;
  FLensHot := False;
  FTurnTicks := 0;
  FPressing := False;
  FRowTicks := -1;
  FGoneTicks := 0;
  case FPhase of
    rpDriving:
      begin
        FChangePending := True;
        FTarget := StopAhead;
      end;
    rpResting, rpRevving:
      BeginChange;
  else
    FChangePending := True;
  end;
end;

procedure TRam.BeginChange;
begin
  FChangePending := False;
  FPhase := rpChanging;
  FPhaseTicks := 0;
  FChangeFrom := FMast;
end;

// The empty mast sinks, a beat, the sweeper rises and the fight goes on.
// After the sweeper the mast stays down and the machine stands at the
// wall as long as the third head would take to rise and light its row,
// then a breath before the chase.
// TODO: the bunker rises here, and the breath counts from its row lit
// (tracked: arena-3.md, stage 14)
procedure TRam.TickChange;
begin
  Inc(FPhaseTicks);
  if FPhaseTicks <= SinkTicks then
  begin
    FMast := Lerp(FChangeFrom, MastRest, SmoothStep(FPhaseTicks / SinkTicks));
    Exit;
  end;
  var Rising := FPhaseTicks - SinkTicks - EmptyTicks;
  if Rising < 0 then
    Exit;
  if FKilled = rhSweeper then
  begin
    BeginRest(ChangeRiseTicks + RowBootTicks + ChaseBreathTicks);
    Exit;
  end;
  if Rising = 0 then
  begin
    FHead := rhSweeper;
    FFacing := -1;
    FCue.Whine := True;
    Exit;
  end;
  FMast := Lerp(MastRest, SweeperMast, SmoothStep(Rising / ChangeRiseTicks));
  if Rising >= ChangeRiseTicks then
  begin
    LockSweeper;
    BeginRest(LockRestTicks);
  end;
end;

// Locked on the mast with all its lives; the row comes up and the first
// sweep waits for it
procedure TRam.LockSweeper;
begin
  FArmed := True;
  FArmedTicks := 0;
  FFullLives := Max(1, Round(SweeperLives * FLivesShare));
  FLives := FFullLives;
  FThirds := 0;
  FHurtTicks := 0;
  FHitTicks := NoHitTicks;
  FGoneTicks := -1;
  FRowTicks := 0;
  FFire := rfIdle;
  FFireTicks := FirstBurstTicks;
  FPastTicks := 0;
  FForkLeft := False;
  FLadderWay := 0;
  FRowY := SweeperRowY(FMast);
end;

procedure TRam.TickPhase;
begin
  case FPhase of
    rpWaiting:
      if FPhaseTicks > 0 then
        Dec(FPhaseTicks)
      else
      begin
        // It comes in at speed: the drive began beyond the edge
        FSpeed := -EnterSpeed;
        BeginDrive(FOrders.Stop, EnterSpeed, True);
      end;
    rpDriving:
      TickDrive;
    rpBreathing:
      if FPhaseTicks > 0 then
        Dec(FPhaseTicks)
      else
      begin
        FEyeLit := True;
        FPhase := rpRising;
        FPhaseTicks := 0;
        FCue.Whine := True;
      end;
    rpRising:
      begin
        Inc(FPhaseTicks);
        var Share: Single := FPhaseTicks / RiseTicks;
        FMast := Lerp(MastRest, HunterMast, SmoothStep(Share));
        if Share >= 1 then
        begin
          FCue.Locked := True;
          FArmed := True;
          FArmedTicks := 0;
          FRowTicks := 0;
          BeginRest(LockRestTicks);
        end;
      end;
    rpResting:
      begin
        if FChangePending then
        begin
          BeginChange;
          Exit;
        end;
        // A dying head holds the machine as its end says; a spent one
        // stands at the wall, and the road runs under it
        if FHeadKilled then
          Exit;
        if Spent then
        begin
          TickSpent;
          Exit;
        end;
        if FHero.Alive and not FPressing and (FHead = rhHunter) and
          not InSightsFrom(FX) then
          FPhaseTicks := Min(FPhaseTicks, HuntBlindRestTicks);
        if FPhaseTicks > 0 then
          Dec(FPhaseTicks)
        else
          BeginLeg;
      end;
    rpRevving:
      if FPhaseTicks > 0 then
        Dec(FPhaseTicks)
      else
      begin
        BeginDrive(PressWall, PressSpeeds[Tier], False);
        // The rumble has run since the rev
        FCue.Rumble := False;
      end;
    rpChanging:
      TickChange;
  end;
end;

// Up to speed and down again by Brake a tick: the brake begins where what
// is left of the way is what the speed needs to die out
procedure TRam.TickDrive;
begin
  var OldSpeed := FSpeed;
  var Way := FTarget - FX;
  var Pace := Abs(FSpeed);
  FBraking := Sqr(Pace) / (2 * Brake) + Pace / 2 >= Abs(Way);
  if FBraking then
    Pace := Max(Pace - Brake, CreepSpeed)
  else
    Pace := Min(Pace + Brake, FCruise);
  if Pace >= Abs(Way) then
  begin
    FX := FTarget;
    Arrive(OldSpeed);
    Exit;
  end;
  FSpeed := Sign(Way) * Pace;
  FX := FX + FSpeed;
  FAccel := FSpeed - OldSpeed;
end;

procedure TRam.Arrive(AOldSpeed: Single);
begin
  FSpeed := 0;
  FAccel := -AOldSpeed;
  FBraking := False;
  FLamps := 1;
  FLampHold := LampHoldTicks;
  FCue.Hiss := True;
  if FEntering then
  begin
    FCue.Jolt := EntranceStopJolt;
    FPhase := rpBreathing;
    FPhaseTicks := BreathTicks;
    Exit;
  end;
  FCue.Jolt := Max(FCue.Jolt, PatrolStopJolt);
  if FChangePending then
    BeginChange
  else if not FHero.Alive then
    BeginRest(PatrolRestMinTicks +
      Round(FDice.NextUnit * (PatrolRestMaxTicks - PatrolRestMinTicks)))
  else if FPressing then
    BeginRest(PressRestTicks)
  else
    BeginRest(HuntRestMinTicks +
      Round(FDice.NextUnit * (HuntRestMaxTicks - HuntRestMinTicks)));
end;

// The top keeps going as the hull speeds up or brakes: it leans against
// the change of the speed and swings back about its own slow sway
procedure TRam.TickSway;
begin
  var Rest := IdleSway * Sin(2 * Pi * FAge / IdleSwayTicks);
  FSwaySpeed := FSwaySpeed - SwaySpring * (FSway - Rest) -
    SwayDamping * FSwaySpeed - SwayInertia * FAccel;
  FSway := EnsureRange(FSway + FSwaySpeed, -SwayMax, SwayMax);
end;

// The row lights a cell at a time after the lock; the clocks of the hit
// and the blast run on
procedure TRam.TickRow;
begin
  if FHitTicks < NoHitTicks then
    Inc(FHitTicks);
  if FGoneTicks >= 0 then
    Inc(FGoneTicks);
  if FRowTicks < 0 then
    Exit;
  var Before := RowLit;
  if FRowTicks < RowBootTicks then
    Inc(FRowTicks);
  if RowLit > Before then
    FCue.RowCell := True;
end;

function TRam.RowLit: Integer;
begin
  Result := 0;
  if FRowTicks > 0 then
    Result := Min(HeadRowCells, FRowTicks * HeadRowCells div RowBootTicks);
end;

function TRam.Row: TRamRow;
begin
  Result := Default(TRamRow);
  Result.HitTicks := FHitTicks;
  if Present and (FHead <> rhNone) and (FRowTicks >= 0) then
  begin
    Result.Shown := True;
    Result.Lit := RowLit;
    Result.Share := FLives / FFullLives;
    Result.Fade := 1;
  end
  else if Present and (FGoneTicks >= 0) and (FGoneTicks < RowFadeTicks) then
  begin
    Result.Shown := True;
    Result.Lit := HeadRowCells;
    Result.Fade := 1 - FGoneTicks / RowFadeTicks;
  end;
end;

function TRam.HeadTopAt(AAlpha: Single): TSdlFPoint;
begin
  var Head := FHead;
  if Head = rhNone then
    Head := rhHunter;
  Result := HeadPoint(LeftAt(AAlpha), MastAt(AAlpha), SwayAt(AAlpha), Head,
    FFacing, 1, HeadShapes[Head].Width / 2, 0);
end;

function TRam.Tier: Integer;
begin
  Result := 0;
  if FLives * 3 <= FFullLives * 2 then
    Result := 1;
  if FLives * 3 <= FFullLives then
    Result := 2;
end;

function TRam.CanShoot: Boolean;
begin
  Result := (FHead <> rhNone) and FArmed and not FHeadKilled and FHero.Alive and
    (FTurnTicks = 0) and (FPhase in [rpDriving, rpResting, rpRevving]) and
    not ((FPhase = rpDriving) and FEntering);
end;

// The barrel follows the hero within its half; past the vertical the
// head turns, never in the middle of a burst. While the lens burns the
// barrel holds on the point it took - or, the hose, follows him slower.
procedure TRam.TickAim;
begin
  if (FHead = rhNone) or FHeadKilled or not FHero.Alive then
  begin
    FPastTicks := 0;
    FInSights := False;
    Exit;
  end;

  if FTurnTicks > 0 then
  begin
    Dec(FTurnTicks);
    if FTurnTicks = TurnTicks div 2 then
    begin
      FFacing := -FFacing;
      FAim := 180 - FAim;
      FLastAim := FAim;
    end;
    Exit;
  end;
  if FHead = rhSweeper then
  begin
    TickRide;
    Exit;
  end;

  var Sleeve := HeadPoint(FX, FMast, FSway, rhHunter, FFacing, 1,
    HunterSleeveX, HunterSleeveY);
  FWant := AimWithin(Bearing(Sleeve, FHeroCenter), FFacing, FInSights) + FSway;

  var OtherSide := (FHeroCenter.X - Sleeve.X) * -FFacing;
  var OffVertical := RadToDeg(ArcTan2(OtherSide, Sleeve.Y - FHeroCenter.Y));
  if (OtherSide > 0) and (OffVertical > TurnPast) then
    Inc(FPastTicks)
  else
    FPastTicks := 0;
  if (FPastTicks >= TurnHoldTicks) and FArmed and (FFire = rfIdle) then
  begin
    FPastTicks := 0;
    FTurnTicks := TurnTicks;
    Exit;
  end;

  var Goal := FWant;
  var Rate := TrackRate;
  if FFire <> rfIdle then
    if FirePatterns[Tier].Hose then
      Rate := HoseRate
    else
    begin
      var Reached: Boolean;
      Goal := AimWithin(Bearing(Sleeve, FFrozenAt), FFacing, Reached) + FSway;
    end;
  FAim := FAim + EnsureRange(Goal - FAim, -Rate, Rate);
end;

// Rest, the lens burning red, the burst, rest again. A press holds the
// fire: no new burst, and a lens that burns goes out; a burst under way
// is let out.
procedure TRam.TickFire;
begin
  if not CanShoot then
  begin
    if FFire <> rfIdle then
    begin
      FFire := rfIdle;
      FFireTicks := FirePatterns[Tier].RestTicks;
      if FHead = rhSweeper then
        FFireTicks := SweepPatterns[Tier].RestTicks;
    end;
    Exit;
  end;
  if FHead = rhSweeper then
  begin
    TickSweep;
    Exit;
  end;

  var Pattern := FirePatterns[Tier];
  case FFire of
    rfIdle:
      if FFireTicks > 0 then
        Dec(FFireTicks)
      else if not FPressing and FInSights and
        (Abs(FWant - FAim) <= AimSlack) then
      begin
        FFire := rfFlare;
        FFireTicks := Pattern.FlareTicks;
        FFrozenAt := FHeroCenter;
        if Pattern.Lead then
        begin
          // Where he will be when the bullet gets there, if he keeps going
          var Sleeve := HeadPoint(FX, FMast, FSway, rhHunter, FFacing, 1,
            HunterSleeveX, HunterSleeveY);
          var Flight := Hypot(FHeroCenter.X - Sleeve.X,
            FHeroCenter.Y - Sleeve.Y) / HunterBulletSpeed + Pattern.FlareTicks;
          FFrozenAt := UnitPoint(
            FHeroCenter.X + EnsureRange(FHeroPace.X * Flight, -LeadMax, LeadMax),
            FHeroCenter.Y + EnsureRange(FHeroPace.Y * Flight, -LeadMax, LeadMax));
        end;
      end;
    rfFlare:
      if FPressing then
      begin
        FFire := rfIdle;
        FFireTicks := Pattern.RestTicks div 2;
      end
      else if FFireTicks > 1 then
        Dec(FFireTicks)
      else
      begin
        FFire := rfBurst;
        FShotsLeft := Pattern.Shots;
        FFireTicks := 0;
      end;
    rfBurst:
      if FFireTicks > 0 then
        Dec(FFireTicks)
      else
      begin
        Shoot;
        Dec(FShotsLeft);
        FFireTicks := Pattern.GapTicks;
        if FShotsLeft <= 0 then
        begin
          FFire := rfIdle;
          FFireTicks := Pattern.RestTicks;
        end;
      end;
  end;
end;

// A bullet out of the muzzle, along the barrel as the sway has it
procedure TRam.Shoot;
begin
  var Sleeve := HeadPoint(FX, FMast, FSway, rhHunter, FFacing, 1,
    HunterSleeveX, HunterSleeveY);
  var Along := FAim - FSway;
  var Barrel := Heading(Along);
  var Reach := BarrelPivotX - BarrelMuzzleX;
  FCue.Shot := True;
  FCue.ShotFrom := UnitPoint(Sleeve.X + Barrel.X * Reach,
    Sleeve.Y + Barrel.Y * Reach);
  FCue.ShotAngle := Round(Along);
  FCue.ShotSpeed := HunterBulletSpeed;
end;

// The barrels' middle row on the screen with the mast at AMast, the sway
// left out
function TRam.SweeperRowY(AMast: Single): Single;
begin
  Result := RamTop + WellY - AMast - HeadShapes[rhSweeper].SocketY +
    (BarrelsTop + BarrelsBottom) / 2;
end;

function TRam.SweeperMastFor(ARowY: Single): Single;
begin
  Result := EnsureRange(RamTop + WellY - ARowY -
    HeadShapes[rhSweeper].SocketY + (BarrelsTop + BarrelsBottom) / 2,
    SweeperMastLowest, SweeperMastHighest);
end;

// Turns to a hero on its other side; idle, follows his row - the bottom
// of the mast while the ram presses him, the closed ceiling; a ladder
// rides its row through the sweep. The mast goes after the row.
procedure TRam.TickRide;
begin
  if not FArmed then
    Exit;
  var OtherSide := (FHeroCenter.X - MastPivot(FX).X) * -FFacing;
  if OtherSide > SweeperTurnPast then
    Inc(FPastTicks)
  else
    FPastTicks := 0;
  if (FPastTicks >= TurnHoldTicks) and (FFire = rfIdle) then
  begin
    FPastTicks := 0;
    FTurnTicks := TurnTicks;
    Exit;
  end;

  var Highest := SweeperRowY(SweeperMastHighest);
  var Lowest := SweeperRowY(SweeperMastLowest);
  case FFire of
    rfIdle:
      if FPressing then
        FRowY := Lowest
      else
        FRowY := FHeroCenter.Y;
    rfBurst:
      FRowY := FRowY + FLadderWay * LadderRate;
  end;
  FRowY := EnsureRange(FRowY, Highest, Lowest);
  var Goal := SweeperMastFor(FRowY);
  FMast := FMast + EnsureRange(Goal - FMast, -RideRate, RideRate);
end;

// Rest; on its row, with him in front, the barrels burn red; the sweep.
// The fork sweeps once more at once a row away; the ladder rides through
// its sweep toward the side with more room.
procedure TRam.TickSweep;
begin
  var Pattern := SweepPatterns[Tier];
  var OnRow := Abs(SweeperRowY(FMast) - FRowY) <= RowSlack;
  case FFire of
    rfIdle:
      if FFireTicks > 0 then
        Dec(FFireTicks)
      else if OnRow and
        ((FHeroCenter.X - MastPivot(FX).X) * -FFacing <= SweeperTurnPast) then
      begin
        FForkLeft := Pattern.Fork;
        BeginSweep(Pattern.HeatTicks);
      end;
    rfFlare:
      if not OnRow then
        Exit
      else if FFireTicks > 1 then
        Dec(FFireTicks)
      else
      begin
        FFire := rfBurst;
        FShotsLeft := Pattern.Shots;
        FFireTicks := 0;
        FLadderWay := 0;
        if Pattern.Ladder then
        begin
          FLadderWay := 1;
          if FRowY - SweeperRowY(SweeperMastHighest) >
            SweeperRowY(SweeperMastLowest) - FRowY then
            FLadderWay := -1;
        end;
      end;
    rfBurst:
      if FFireTicks > 0 then
        Dec(FFireTicks)
      else
      begin
        ShootBarrel;
        Dec(FShotsLeft);
        FFireTicks := Pattern.GapTicks;
        if FShotsLeft > 0 then
          Exit;
        FLadderWay := 0;
        if FForkLeft then
        begin
          FForkLeft := False;
          FRowY := ForkRow;
          BeginSweep(ForkHeatTicks);
        end
        else
        begin
          FFire := rfIdle;
          FFireTicks := Pattern.RestTicks;
        end;
      end;
  end;
end;

procedure TRam.BeginSweep(AFlareTicks: Integer);
begin
  FFire := rfFlare;
  FFireTicks := AFlareTicks;
  FHeatTicks := AFlareTicks;
end;

// A cell up - the jump is the way out of a row - or down when he is
// already falling, or when up is past the mast
function TRam.ForkRow: Single;
const
  Falling = 0.5;
begin
  var Way := -1;
  if FHeroPace.Y > Falling then
    Way := 1;
  Result := FRowY + Way * ForkStep;
  if (Result < SweeperRowY(SweeperMastHighest)) or
    (Result > SweeperRowY(SweeperMastLowest)) then
    Result := FRowY - Way * ForkStep;
end;

// Level out of the next of the four muzzles in turn
procedure TRam.ShootBarrel;
begin
  FCue.Shot := True;
  FCue.ShotFrom := HeadPoint(FX, FMast, FSway, rhSweeper, FFacing, 1, MuzzleX,
    MuzzleYs[FNextBarrel]);
  FCue.ShotAngle := 180;
  if FFacing > 0 then
    FCue.ShotAngle := 0;
  FCue.ShotSpeed := SweeperBulletSpeed;
  FNextBarrel := (FNextBarrel + 1) mod Length(MuzzleYs);
end;

procedure TRam.TickHeat;
begin
  FHeat := 0;
  if (FHead <> rhSweeper) or not FArmed then
    Exit;
  if FRetreating then
  begin
    FHeat := Lerp(RetreatHeatLow, 1,
      0.5 - 0.5 * Cos(2 * Pi * FRetreatTicks / RetreatThrobTicks));
    Exit;
  end;
  case FFire of
    rfFlare:
      FHeat := Lerp(HeatFrom, 1, 1 - FFireTicks / FHeatTicks);
    rfBurst:
      FHeat := 1;
  end;
end;

procedure TRam.TickLamps;
begin
  if FBraking then
    FLamps := 1
  else if FLampHold > 0 then
    Dec(FLampHold)
  else
    FLamps := Max(0, FLamps - LampFade);
end;

// Lit, it breathes; while a head rises, through a change of heads and
// through the sweeper's end, it blinks - the warning
procedure TRam.TickEye;
begin
  if not FEyeLit then
    FEye := 0
  else if (FPhase in [rpRising, rpChanging]) or FRetreating or Overloading then
  begin
    var Clock := FPhaseTicks;
    if FRetreating then
      Clock := FRetreatTicks
    else if Overloading then
      Clock := FOverloadTicks;
    FEye := EyeBlinkLow;
    if (Clock div EyeBlinkTicks) mod 2 = 0 then
      FEye := 1;
  end
  else
  begin
    var Breath: Single := 0.5 - 0.5 * Cos(2 * Pi * FBreathTicks / EyeBreathTicks);
    FEye := Lerp(EyeBreathLow, EyeBreathHigh, Breath);
    Inc(FBreathTicks);
  end;
end;

// The first wink comes the tick the head locks. The lens burns red,
// brighter and brighter, before a burst and through it - the warning
// comes first, a struck eye only flashes when the lens is not burning.
procedure TRam.TickLens;
begin
  FLensHot := False;
  var Struck := FHurtTicks > 0;
  if Struck then
    Dec(FHurtTicks);
  if not FArmed or (FHead <> rhHunter) then
  begin
    FLens := 0;
    Exit;
  end;
  // The row comes up: the eye burns white with it - this is what has lives
  if RowLit < HeadRowCells then
  begin
    FLens := 1;
    Exit;
  end;
  case FFire of
    rfFlare:
      begin
        FLensHot := True;
        FLens := Lerp(LensFlareFrom, 1,
          1 - FFireTicks / FirePatterns[Tier].FlareTicks);
        Exit;
      end;
    rfBurst:
      begin
        FLensHot := True;
        FLens := 1;
        Exit;
      end;
  end;
  if Struck then
  begin
    FLens := 1;
    Exit;
  end;
  FLens := LensEmber;
  if FArmedTicks mod LensPeriodTicks < LensWinkTicks then
    FLens := 1;
  Inc(FArmedTicks);
end;

function TRam.Overlaps(const ABox: TSdlFRect): Boolean;
begin
  var FirstCol := Floor(ABox.X - FX);
  var LastCol := Ceil(ABox.X + ABox.W - FX) - 1;
  var FirstRow := Floor(ABox.Y - RamTop);
  var LastRow := Ceil(ABox.Y + ABox.H - RamTop) - 1;
  for var Row := Max(FirstRow, 0) to Min(LastRow, FBody.Height - 1) do
    for var Col := Max(FirstCol, 0) to Min(LastCol, FBody.Width - 1) do
      if FBody.At(Col, Row) then
        Exit(True);
  Result := False;
end;

// The columns of the body that the rows of ABox meet, the whole width of
// the hull; False when the box is above or below it
function TRam.SpanAcross(const ABox: TSdlFRect; out AFirst,
  ALast: Integer): Boolean;
begin
  AFirst := FBody.Width;
  ALast := -1;
  var FirstRow := Max(Floor(ABox.Y - RamTop), 0);
  var LastRow := Min(Ceil(ABox.Y + ABox.H - RamTop) - 1, FBody.Height - 1);
  for var Row := FirstRow to LastRow do
    for var Col := 0 to FBody.Width - 1 do
      if FBody.At(Col, Row) then
      begin
        AFirst := Min(AFirst, Col);
        ALast := Max(ALast, Col);
      end;
  Result := ALast >= 0;
end;

// Away from the middle - but straight up when that side leaves less room
// to the wall than his body needs: a throw into the wall would land him
// in the hull again, and again, while it stands there
function TRam.ThrowSide(const AHeroBody: TSdlFRect): Integer;
begin
  Result := 1;
  if AHeroBody.X + AHeroBody.W / 2 < FX + RamWidth / 2 then
    Result := -1;
  var First, Last: Integer;
  if not SpanAcross(AHeroBody, First, Last) then
    Exit;
  var Room: Single := FX + First;
  if Result > 0 then
    Room := ScreenWidth - (FX + Last + 1);
  if Room < AHeroBody.W then
    Result := 0;
end;

function TRam.Contact(const AHeroBody: TSdlFRect; AOnDeck, AInAir: Boolean;
  out AAway: Integer): Boolean;
begin
  AAway := 0;
  if FHeroThrown and AInAir then
    Exit(False);
  FHeroThrown := False;
  if not Present or not Overlaps(AHeroBody) then
  begin
    FHeroInFront := False;
    FClearTicks := 0;
    Exit(False);
  end;
  if FClearTicks > 0 then
    Exit(False);
  if AOnDeck then
  begin
    FHeroInFront := True;
    Exit(False);
  end;
  if FHeroInFront and AInAir then
    Exit(False);

  FHeroInFront := False;
  FHeroThrown := True;
  FClearTicks := ClearTicks;
  AAway := ThrowSide(AHeroBody);
  Result := True;
end;

function TRam.Block(const AFrom, ATo: TSdlFPoint; out AAt: TSdlFPoint): Boolean;
begin
  AAt := ATo;
  if not Present then
    Exit(False);
  var MiddleX := FX + FBody.Middle.X;
  var MiddleY := RamTop + FBody.Middle.Y;
  var From: TSdlFPoint;
  From.X := AFrom.X - MiddleX;
  From.Y := AFrom.Y - MiddleY;
  var Till: TSdlFPoint;
  Till.X := ATo.X - MiddleX;
  Till.Y := ATo.Y - MiddleY;
  var Entry: TSdlFPoint;
  Result := FShield.TryEntry(From, Till, Entry);
  if not Result then
    Exit;
  FShield.Strike(Entry);
  AAt.X := MiddleX + Entry.X;
  AAt.Y := MiddleY + Entry.Y;
end;

function TRam.LensPoint: TSdlFPoint;
begin
  Result := HeadPoint(FX, FMast, FSway, rhHunter, FFacing, TurnSquash,
    HunterLensX, HunterLensY);
end;

// The stretch against a circle about the lens: the first point of it
// within the circle. Only a hunter up and locked has an eye to hit.
function TRam.StrikeEye(const AFrom, ATo: TSdlFPoint;
  out AAt: TSdlFPoint): Boolean;
begin
  AAt := ATo;
  if not Present or (FHead <> rhHunter) or not FArmed or FHeadKilled then
    Exit(False);
  var Lens := LensPoint;
  var AlongX := ATo.X - AFrom.X;
  var AlongY := ATo.Y - AFrom.Y;
  var FromX := AFrom.X - Lens.X;
  var FromY := AFrom.Y - Lens.Y;
  // |From + Along t| = EyeRadius, the smaller t in 0..1
  var A := Sqr(AlongX) + Sqr(AlongY);
  var B := 2 * (FromX * AlongX + FromY * AlongY);
  var C := Sqr(FromX) + Sqr(FromY) - Sqr(EyeRadius);
  var Share: Single;
  if C <= 0 then
    Share := 0
  else
  begin
    var Discriminant := Sqr(B) - 4 * A * C;
    if (A = 0) or (Discriminant < 0) then
      Exit(False);
    Share := (-B - Sqrt(Discriminant)) / (2 * A);
    if (Share < 0) or (Share > 1) then
      Exit(False);
  end;
  AAt := UnitPoint(AFrom.X + AlongX * Share, AFrom.Y + AlongY * Share);
  FHurtTicks := HurtFlashTicks;
  FHitTicks := 0;
  Dec(FLives);
  if FLives <= 0 then
    FHeadKilled := True;
  Result := True;
end;

// A point of the screen in the sweeper's own units, as its art is drawn
// facing left: the sway, the facing and the squash of a turn undone
function TRam.ToHead(const APoint: TSdlFPoint): TSdlFPoint;
begin
  var Shape := HeadShapes[rhSweeper];
  var Pivot := MastPivot(FX);
  var Upright := Turned(APoint, Pivot, -FSway);
  Result := UnitPoint(Shape.SocketX - (Upright.X - Pivot.X) / (FFacing * TurnSquash),
    Upright.Y - Pivot.Y + FMast + Shape.SocketY);
end;

// The first point of the stretch on the pack or under it. Under it, or
// climbing into it, the bullet comes from below: a plate takes it.
function TRam.StrikeBarrels(const AFrom, ATo: TSdlFPoint; out AAt: TSdlFPoint;
  out AGuarded: Boolean): Boolean;
begin
  AAt := ATo;
  AGuarded := False;
  if not Present or (FHead <> rhSweeper) or not FArmed or FHeadKilled or
    (TurnSquash < ThinHeadSquash) then
    Exit(False);
  var From := ToHead(AFrom);
  var Till := ToHead(ATo);
  var Steps := Max(1, Ceil(Hypot(Till.X - From.X, Till.Y - From.Y) / StrikeStep));
  var Met := -1;
  var Under := False;
  for var i := 0 to Steps do
  begin
    var Point := UnitPoint(Lerp(From.X, Till.X, i / Steps),
      Lerp(From.Y, Till.Y, i / Steps));
    if not InRange(Point.X, BarrelsLeft, BarrelsRight) or
      not InRange(Point.Y, BarrelsTop, PlateBottom) then
      Continue;
    Met := i;
    Under := Point.Y > BarrelsBottom;
    Break;
  end;
  if Met < 0 then
    Exit(False);

  AAt := UnitPoint(Lerp(AFrom.X, ATo.X, Met / Steps),
    Lerp(AFrom.Y, ATo.Y, Met / Steps));
  var Climbs := AFrom.Y - ATo.Y > Abs(ATo.X - AFrom.X) * Tan(DegToRad(PlateCover));
  if Under or Climbs then
  begin
    AGuarded := True;
    var Local := ToHead(AAt);
    var Nearest := 0;
    if Abs(Local.X - PlateMiddles[1].X) < Abs(Local.X - PlateMiddles[0].X) then
      Nearest := 1;
    FPlates[Nearest].Strike(UnitPoint(
      -FFacing * (Local.X - PlateMiddles[Nearest].X) * TurnSquash, 0));
    Exit(True);
  end;

  FHurtTicks := HurtFlashTicks;
  FHitTicks := 0;
  Dec(FLives);
  if FLives <= 0 then
  begin
    FHeadKilled := True;
    FRetreating := True;
  end;
  Result := True;
end;

function TRam.BarrelsPoint: TSdlFPoint;
begin
  Result := HeadPoint(FX, FMast, FSway, rhSweeper, FFacing, TurnSquash,
    (BarrelsLeft + BarrelsRight) / 2, (BarrelsTop + BarrelsBottom) / 2);
end;

function TRam.Plate(AIndex: Integer): TTekShield;
begin
  Result := FPlates[AIndex];
end;

function TRam.HeatAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastHeat, FHeat, AAlpha);
end;

function TRam.Booting: Boolean;
begin
  Result := (FHead <> rhNone) and FArmed and (RowLit < HeadRowCells);
end;

function TRam.AimAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastAim, FAim, AAlpha);
end;

function TRam.TurnSquash: Single;
begin
  Result := 1;
  if FTurnTicks > 0 then
    Result := Abs(2 * FTurnTicks / TurnTicks - 1);
end;

function TRam.Wounded: Boolean;
begin
  Result := (FHead = rhHunter) and (Tier = 2);
end;

function TRam.Overloading: Boolean;
begin
  Result := FHeadKilled and (FHead = rhSweeper) and not FRetreating;
end;

function TRam.Overload: Single;
begin
  Result := 0;
  if Overloading then
    Result := FOverloadTicks / OverloadTicks;
end;

function TRam.FlashAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastFlash, FFlash, AAlpha);
end;

function TRam.WaveFrontAt(AAlpha: Single): Single;
begin
  if not FWave.Running then
    Exit(NoWave);
  Result := FWave.FrontOf(FWave.Ticks - 1 + AAlpha);
end;

function TRam.WaveReaches(const APoint: TSdlFPoint): Boolean;
begin
  Result := FWave.Running and (Hypot(APoint.X - FBlastAt.X,
    APoint.Y - FBlastAt.Y) <= FWave.FrontOf(FWave.Ticks));
end;

// Away from the hull; from over it, toward the side with more road
function TRam.WaveSide(const AHeroBody: TSdlFRect): Integer;
begin
  var Middle := AHeroBody.X + AHeroBody.W / 2;
  if Middle < FX then
    Exit(-1);
  if Middle > FX + RamWidth then
    Exit(1);
  Result := 1;
  if FX > ScreenWidth - (FX + RamWidth) then
    Result := -1;
end;

function TRam.WaveStrikes(const AHeroBody: TSdlFRect;
  out AAway: Integer): Boolean;
begin
  AAway := 0;
  if FWave.Threw or not WaveReaches(UnitPoint(AHeroBody.X + AHeroBody.W / 2,
    AHeroBody.Y + AHeroBody.H / 2)) then
    Exit(False);
  FWave.Threw := True;
  FHeroThrown := True;
  FHeroInFront := False;
  FClearTicks := ClearTicks;
  AAway := WaveSide(AHeroBody);
  Result := True;
end;

function TRam.ShortLevel: Single;
begin
  if (FHead = rhNone) or not FArmed or (FLives * 2 > FFullLives) then
    Exit(0);
  Result := ShortFloor + ShortSpan * (1 - FLives * 2 / FFullLives);
end;

function TRam.Hurt: Boolean;
begin
  Result := FHurtTicks > 0;
end;

function TRam.LeftAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastX, FX, AAlpha);
end;

function TRam.MastAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastMast, FMast, AAlpha);
end;

function TRam.SwayAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastSway, FSway, AAlpha);
end;

function TRam.LampsAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastLamps, FLamps, AAlpha);
end;

function TRam.EyeAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastEye, FEye, AAlpha);
end;

function TRam.LensAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastLens, FLens, AAlpha);
end;

function TRam.Rolled: Single;
begin
  Result := FX - FLastX;
end;

// ---------------------------------------------------------------------------
// TRamArt
// ---------------------------------------------------------------------------

function ReadArtSurface(const ASpriteSet: TSpriteSet;
  const AName: string): PSdlSurface;
begin
  var Loaded := LoadImageSurface(ASpriteSet, AName);
  if Loaded = nil then
    raise ESpriteError.CreateFmt(SRamArtFailed, [AName, SdlErrorText]);
  Result := SDL_ConvertSurfaceFormat(Loaded, SdlPixelFormatAbgr8888, 0);
  SDL_FreeSurface(Loaded);
  if Result = nil then
    raise ESpriteError.CreateFmt(SRamArtFailed, [AName, SdlErrorText]);
end;

// How opaque the art is at the middle of the unit ACol, ARow
function AlphaAt(ASurface: PSdlSurface; ACol, ARow: Integer): Byte;
type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888
begin
  var PixelX := Min(Trunc((ACol + 0.5) * ASurface.W / RamWidth), ASurface.W - 1);
  var PixelY := Min(Trunc((ARow + 0.5) * ASurface.H / RamHeight), ASurface.H - 1);
  var Pixel := PPixelBytes(PByte(ASurface.Pixels) + PixelY * ASurface.Pitch +
    PixelX * SizeOf(TPixelBytes));
  Result := Pixel[3];
end;

function WithinWheel(ACol, ARow: Integer): Boolean;
begin
  for var Axle in Axles do
    if Sqr(ACol + 0.5 - Axle.X) + Sqr(ARow + 0.5 - Axle.Y) <=
      Sqr(WheelRadius) then
      Exit(True);
  Result := False;
end;

// The hull, the dark of its arches and the wheels: everything a touch
// meets
function ReadBody(const ASpriteSet: TSpriteSet): TShieldMask;
begin
  Result.Width := Round(RamWidth);
  Result.Height := Round(RamHeight);
  Result.Middle.X := RamWidth / 2;
  Result.Middle.Y := RamHeight / 2;
  SetLength(Result.Solid, Result.Width * Result.Height);
  var Hull := ReadArtSurface(ASpriteSet, 'hull');
  try
    var Chassis := ReadArtSurface(ASpriteSet, 'chassis');
    try
      SDL_LockSurface(Hull);
      SDL_LockSurface(Chassis);
      for var Row := 0 to Result.Height - 1 do
        for var Col := 0 to Result.Width - 1 do
          Result.Solid[Row * Result.Width + Col] :=
            (AlphaAt(Hull, Col, Row) >= BodyAlpha) or
            (AlphaAt(Chassis, Col, Row) >= BodyAlpha) or WithinWheel(Col, Row);
      SDL_UnlockSurface(Chassis);
      SDL_UnlockSurface(Hull);
    finally
      SDL_FreeSurface(Chassis);
    end;
  finally
    SDL_FreeSurface(Hull);
  end;
end;

// A ring just inside the edge of its square, soft both ways; blended, not
// added, so drawn black it darkens what lies under it
function CreateWaveBand(ARenderer: PSdlRenderer): PSdlTexture;
begin
  var Image: TArray<Single>;
  SetLength(Image, WaveBandSide * WaveBandSide);
  var Half := WaveBandSide / 2;
  for var Row := 0 to WaveBandSide - 1 do
    for var Col := 0 to WaveBandSide - 1 do
    begin
      var Off := (Hypot(Col + 0.5 - Half, Row + 0.5 - Half) / Half -
        WaveBandRadius) / WaveBandWidth;
      Image[Row * WaveBandSide + Col] := Exp(-Off * Off);
    end;
  Result := CreateGlowFromImage(ARenderer, Image, WaveBandSide, WaveBandSide);
  SDL_SetTextureBlendMode(Result, SdlBlendModeBlend);
end;

constructor TRamArt.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSpriteSet := TSpriteSet.Create(SpriteSetsDir + RamSetName + '.mset');
  FCache := TSpriteCache.Create(ARenderer);
  FCache.DisableColorKey;
  FCache.EnableLinearFilter;
  FCache.AttachSpriteSet(FSpriteSet);
  FWell := FCache.Get('well');
  for var i := Low(FMasts) to High(FMasts) do
    FMasts[i] := FCache.Get('mast' + IntToStr(i));
  FHunter := FCache.Get('hunter');
  FHunterBarrel := FCache.Get('hunterBarrel');
  FSweeper := FCache.Get('sweeper');
  FSweeperHeat := FCache.Get('sweeperHeat');
  FHullArt := THullArt.Create(ARenderer, RamHullDef);
  FShield := TShieldArt.Create(ARenderer);
  FGlow := CreateGlowShape(ARenderer, gsPoint, GlowSide);
  FWaveBand := CreateWaveBand(ARenderer);
  FBody := ReadBody(FSpriteSet);
end;

// The cache before the set: it reads from the set, never the reverse
destructor TRamArt.Destroy;
begin
  if Assigned(FWaveBand) then
    SDL_DestroyTexture(FWaveBand);
  if Assigned(FGlow) then
    SDL_DestroyTexture(FGlow);
  FShield.Free;
  FHullArt.Free;
  FCache.Free;
  FSpriteSet.Free;
  inherited;
end;

// ---------------------------------------------------------------------------
// TRamPainter
// ---------------------------------------------------------------------------

constructor TRamPainter.Create(AArt: TRamArt; ARam: TRam);
begin
  inherited Create;
  FArt := AArt;
  FRam := ARam;
  // The hull's own eye stays dark: the Ram lights its eye itself, and
  // the hull's fades too slowly for a blink to read
  FHull := THull.Create(RamHullDef, AArt.FHullArt);
  FHull.Doze;
  var Placement := Default(TDynamicPlacement);
  Placement.Tint := ExhaustTint;
  for var i := Low(FExhausts) to High(FExhausts) do
    FExhausts[i] := TSmoke.CreateLook(Placement, ExhaustSmoke, ExhaustIdle,
      ExhaustSeeds[i]);
  FHeadSmoke := TSmoke.CreateLook(Placement, HeadSmokeLook, 0, HeadSmokeSeed);
  for var Head := Low(FShorts) to High(FShorts) do
    FShorts[Head] := TLightning.CreateLook(Default(TDynamicPlacement),
      HeadShorts[Head], 0, ShortSeeds[Head]);
  FOverloadShort := TLightning.CreateLook(Default(TDynamicPlacement),
    OverloadShortLook, 0, OverloadShortSeed);
  var DustPlacement := Default(TDynamicPlacement);
  DustPlacement.Tint := WaveDustTint;
  for var i := Low(FWaveDust) to High(FWaveDust) do
    FWaveDust[i] := TSmoke.CreateLook(DustPlacement, WaveDustLook, 0,
      WaveDustSeeds[i]);
end;

destructor TRamPainter.Destroy;
begin
  for var Dust in FWaveDust do
    Dust.Free;
  FOverloadShort.Free;
  for var Short in FShorts do
    Short.Free;
  FHeadSmoke.Free;
  for var Exhaust in FExhausts do
    Exhaust.Free;
  FHull.Free;
  inherited;
end;

procedure TRamPainter.Tick(ABeltShift: Single);
begin
  FHull.Tick(0, 0, FRam.Rolled + ABeltShift);
  TickArrival;
  TickExhausts(ABeltShift);
  TickHeadSmoke(ABeltShift);
  TickShorts;
  TickWaveDust;
end;

// A machine come anew left nothing in the air
procedure TRamPainter.TickArrival;
begin
  if FRam.Arrivals = FArrivals then
    Exit;
  FArrivals := FRam.Arrivals;
  FExhaustDriving := False;
  for var Exhaust in FExhausts do
    Exhaust.Rewind;
  FHeadSmoking := False;
  FHeadSmoke.Rewind;
  for var Short in FShorts do
    Short.Rewind;
  FOverloadShort.Rewind;
  for var Dust in FWaveDust do
    Dust.Rewind;
end;

// One that drives smokes hard, on the road or on the belt
procedure TRamPainter.TickExhausts(ABeltShift: Single);
begin
  if not FRam.Present then
    Exit;

  var Driving := (FRam.Phase in [rpDriving, rpRevving]) or (ABeltShift > 0);
  if Driving <> FExhaustDriving then
  begin
    FExhaustDriving := Driving;
    var Level: Single := ExhaustIdle;
    if Driving then
      Level := 1;
    for var Exhaust in FExhausts do
      Exhaust.FadeTo(Level, ExhaustRampTicks);
  end;
  for var i := Low(FExhausts) to High(FExhausts) do
  begin
    FExhausts[i].Drift(-ABeltShift, 0);
    FExhausts[i].Tick(FRam.Left + ExhaustPoints[i].X,
      RamTop + ExhaustPoints[i].Y, True);
  end;
end;

// A wounded hunter smokes from its head; an empty mast from its top while
// it goes down and until the next head comes up
procedure TRamPainter.TickHeadSmoke(ABeltShift: Single);
begin
  if not FRam.Present then
    Exit;
  var Smoking := FRam.Wounded or (FRam.Head = rhNone);
  if Smoking <> FHeadSmoking then
  begin
    FHeadSmoking := Smoking;
    FHeadSmoke.FadeTo(Ord(Smoking), HeadSmokeRampTicks);
  end;
  var Source := MastPivot(FRam.Left);
  Source.Y := Source.Y - FRam.Mast;
  if FRam.Head <> rhNone then
  begin
    var Shape := HeadShapes[FRam.Head];
    Source := HeadPoint(FRam.Left, FRam.Mast, FRam.SwayAt(1), FRam.Head,
      FRam.Facing, 1, Shape.Width / 2, Shape.Height / 2);
  end;
  FHeadSmoke.Drift(-ABeltShift, 0);
  FHeadSmoke.Tick(Source.X, Source.Y, True);
end;

// The head on the mast shorts out as hard as its lives say, the
// overloading sweeper thicker and thicker over that; the bolts of a head
// blown up die out where they struck
procedure TRamPainter.TickShorts;
begin
  if not FRam.Present then
    Exit;
  for var Head := Low(FShorts) to High(FShorts) do
  begin
    var OnTheMast := FRam.Head = Head;
    var Level: Single := 0;
    if OnTheMast then
      Level := FRam.ShortLevel;
    FShorts[Head].FadeTo(Level, 0);
    var Shape := HeadShapes[Head];
    var Middle := HeadPoint(FRam.Left, FRam.Mast, FRam.SwayAt(1), Head,
      FRam.Facing, FRam.TurnSquash, Shape.Width / 2, Shape.Height / 2);
    FShorts[Head].Tick(Middle.X, Middle.Y, OnTheMast);
    if Head = rhSweeper then
    begin
      FOverloadShort.FadeTo(FRam.Overload, 0);
      FOverloadShort.Tick(Middle.X, Middle.Y, FRam.Overloading);
    end;
  end;
end;

// Where the front runs along the road - one point each side of the blast
// - the dust is kicked up; off the screen, or with no wave, none
procedure TRamPainter.TickWaveDust;
begin
  if not FRam.Present then
    Exit;
  var Front := FRam.WaveFrontAt(1);
  var Below := RamFloorY - FRam.BlastAt.Y;
  var Crossing := Front > Below;
  var Along: Single := 0;
  if Crossing then
    Along := Sqrt(Sqr(Front) - Sqr(Below));
  for var i := Low(FWaveDust) to High(FWaveDust) do
  begin
    var Side := 2 * i - 1;
    var X := FRam.BlastAt.X + Side * Along;
    var Kicking := Crossing and (X >= 0) and (X <= ScreenWidth);
    FWaveDust[i].FadeTo(Ord(Kicking), 0);
    FWaveDust[i].Tick(X, RamFloorY - WaveDustOverRoad, Kicking);
  end;
end;

// The sections back to front - the narrowest rides out of the wider ones
// - each top raised by its share of the mast's rise, then the head on the
// top collar. All of it turned with the sway about the middle of the well.
procedure TRamPainter.DrawMast(const ASprites: TSpriteRenderer; ALeft, AMast,
  ASway, AAlpha: Single);
begin
  var Pivot := MastPivot(ALeft);
  var Rise := AMast - MastRest;
  for var Section := High(FArt.FMasts) downto Low(FArt.FMasts) do
  begin
    var Top := Pivot.Y - MastRest - Rise * Section / High(FArt.FMasts);
    var Middle := UnitPoint(Pivot.X, Top + MastLengths[Section] / 2);
    ASprites.DrawSized(FArt.FMasts[Section], Turned(Middle, Pivot, ASway),
      MastWidths[Section], MastLengths[Section], 1, False, ASway);
  end;
  DrawHead(ASprites, ALeft, AMast, ASway, AAlpha);
end;

// The head facing its way, squashed in a turn; the hunter's barrel over it
// on the sleeve, along its aim. The art faces left; facing right it is
// mirrored, and so is the barrel, which then lies along the aim from the
// other end.
procedure TRamPainter.DrawHead(const ASprites: TSpriteRenderer; ALeft, AMast,
  ASway, AAlpha: Single);
begin
  var Head := FRam.Head;
  if Head = rhNone then
    Exit;
  var Shape := HeadShapes[Head];
  var Facing := FRam.Facing;
  var Squash := FRam.TurnSquash;
  var Mirrored := Facing > 0;
  var Texture := FArt.FHunter;
  if Head = rhSweeper then
    Texture := FArt.FSweeper;
  ASprites.DrawSized(Texture, HeadPoint(ALeft, AMast, ASway, Head, Facing,
    Squash, Shape.Width / 2, Shape.Height / 2), Shape.Width * Squash,
    Shape.Height, 1, Mirrored, ASway);
  if Head <> rhHunter then
    Exit;

  var Sleeve := HeadPoint(ALeft, AMast, ASway, rhHunter, Facing, Squash,
    HunterSleeveX, HunterSleeveY);
  var Along := FRam.AimAt(AAlpha) - ASway;
  var Barrel := Heading(Along);
  var Reach := BarrelPivotX - BarrelWidth / 2;
  var Turn := 180 - Along;
  if Mirrored then
    Turn := -Along;
  ASprites.DrawSized(FArt.FHunterBarrel, UnitPoint(Sleeve.X + Barrel.X * Reach,
    Sleeve.Y + Barrel.Y * Reach), BarrelWidth, BarrelHeight, 1, Mirrored, Turn);
end;

// The barrels in white over the sweeper: red as they burn before and
// through a sweep, white while its row comes up, for a moment when they
// are struck, and as the overload whitens the head
procedure TRamPainter.DrawHeat(const ASprites: TSpriteRenderer; ALeft, AMast,
  ASway, AAlpha: Single);
begin
  var Level := FRam.HeatAt(AAlpha);
  var Color := HeatRed;
  if FRam.Overloading then
  begin
    Level := FRam.Overload;
    Color := HeatWhite;
  end
  else if (Level <= 0) and (FRam.Booting or FRam.Hurt) then
  begin
    Level := 1;
    Color := HeatWhite;
  end;
  if Level <= 0 then
    Exit;
  var Shape := HeadShapes[rhSweeper];
  SDL_SetTextureColorMod(FArt.FSweeperHeat, Color.R, Color.G, Color.B);
  ASprites.DrawSized(FArt.FSweeperHeat, HeadPoint(ALeft, AMast, ASway,
    rhSweeper, FRam.Facing, FRam.TurnSquash, Shape.Width / 2, Shape.Height / 2),
    Shape.Width * FRam.TurnSquash, Shape.Height, Level, FRam.Facing > 0, ASway);
end;

// The whole head whitening as the overload goes on: its art added over
// itself, brighter and brighter
procedure TRamPainter.DrawOverload(const ASprites: TSpriteRenderer; ALeft,
  AMast, ASway: Single);
begin
  var Level := FRam.Overload;
  if Level <= 0 then
    Exit;
  var Shape := HeadShapes[rhSweeper];
  var Texture := FArt.FSweeper;
  SDL_SetTextureBlendMode(Texture, SdlBlendModeAdd);
  ASprites.DrawSized(Texture, HeadPoint(ALeft, AMast, ASway, rhSweeper,
    FRam.Facing, FRam.TurnSquash, Shape.Width / 2, Shape.Height / 2),
    Shape.Width * FRam.TurnSquash, Shape.Height, OverloadWhite * Level,
    FRam.Facing > 0, ASway);
  SDL_SetTextureBlendMode(Texture, SdlBlendModeBlend);
end;

// The white of the blast: the whole frame for a moment, and a light about
// where the head burst
procedure TRamPainter.DrawFlash(AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Level := FRam.FlashAt(AAlpha);
  if Level <= 0 then
    Exit;
  var Renderer := FArt.FRenderer;
  SDL_SetRenderDrawBlendMode(Renderer, SdlBlendModeBlend);
  SDL_SetRenderDrawColor(Renderer, FlashColor.R, FlashColor.G, FlashColor.B,
    Round(255 * FlashScreen * Sqr(Level)));
  SDL_RenderFillRectF(Renderer, nil);
  DrawGlow(Renderer, FArt.FGlow, FRam.BlastAt.X + AOrigin.X,
    FRam.BlastAt.Y + AOrigin.Y, FlashGlowSize * Level, FlashColor, Level);
end;

// The dark band behind, then the thin white front over it as a ring of
// triangles, both fading as the wave runs out
procedure TRamPainter.DrawWave(AOrigin: TSdlPoint; AAlpha: Single);
var
  Vertices: array [0..2 * WaveFrontSegments + 1] of TSdlVertex;
  Indices: array [0..6 * WaveFrontSegments - 1] of Integer;
begin
  var Front := FRam.WaveFrontAt(AAlpha);
  if Front <= 0 then
    Exit;
  var Fade := 1 - Front / FRam.WaveReach;
  var CenterX := FRam.BlastAt.X + AOrigin.X;
  var CenterY := FRam.BlastAt.Y + AOrigin.Y;
  var Renderer := FArt.FRenderer;
  DrawGlow(Renderer, FArt.FWaveBand, CenterX, CenterY, 2 * Front, WaveBlack,
    WaveBandDepth * Fade);

  var Color := Default(TSdlColor);
  Color.R := 255;
  Color.G := 255;
  Color.B := 255;
  Color.A := Round(255 * WaveFrontLevel * Fade);
  var Inner := Max(0, Front - WaveFrontWidth);
  for var i := 0 to WaveFrontSegments do
  begin
    var Angle := 2 * Pi * i / WaveFrontSegments;
    Vertices[2 * i].Position := UnitPoint(CenterX + Front * Cos(Angle),
      CenterY + Front * Sin(Angle));
    Vertices[2 * i + 1].Position := UnitPoint(CenterX + Inner * Cos(Angle),
      CenterY + Inner * Sin(Angle));
    Vertices[2 * i].Color := Color;
    Vertices[2 * i + 1].Color := Color;
  end;
  for var i := 0 to WaveFrontSegments - 1 do
  begin
    Indices[6 * i] := 2 * i;
    Indices[6 * i + 1] := 2 * i + 1;
    Indices[6 * i + 2] := 2 * i + 2;
    Indices[6 * i + 3] := 2 * i + 1;
    Indices[6 * i + 4] := 2 * i + 3;
    Indices[6 * i + 5] := 2 * i + 2;
  end;
  SDL_SetRenderDrawBlendMode(Renderer, SdlBlendModeBlend);
  SDL_RenderGeometry(Renderer, nil, @Vertices[0], Length(Vertices),
    @Indices[0], Length(Indices));
end;

procedure TRamPainter.DrawLamps(const ASprites: TSpriteRenderer;
  ALeft, AAlpha: Single);
begin
  var Level := FRam.LampsAt(AAlpha);
  if Level <= 0 then
    Exit;
  for var Lamp in LampPoints do
    DrawGlow(FArt.FRenderer, FArt.FGlow,
      ALeft + Lamp.X + ASprites.Origin.X, RamTop + Lamp.Y + ASprites.Origin.Y,
      LampSize, LampColor, Level);
end;

procedure TRamPainter.DrawEye(const ASprites: TSpriteRenderer;
  ALeft, AAlpha: Single);
begin
  var Level := FRam.EyeAt(AAlpha);
  if Level <= 0 then
    Exit;
  DrawGlow(FArt.FRenderer, FArt.FGlow, ALeft + EyePoint.X + ASprites.Origin.X,
    RamTop + EyePoint.Y + ASprites.Origin.Y,
    Lerp(EyeRestSize, EyeFlashSize, Sqr(Level)), EyeColor, Level);
end;

// On the hunter's head, turned and squashed as the head is: pale and
// winking, red and bigger while it burns, a flash when it is struck
procedure TRamPainter.DrawLens(const ASprites: TSpriteRenderer; ALeft, AMast,
  ASway, AAlpha: Single);
begin
  if FRam.Head <> rhHunter then
    Exit;
  var Level := FRam.LensAt(AAlpha);
  if Level <= 0 then
    Exit;
  var Lens := HeadPoint(ALeft, AMast, ASway, rhHunter, FRam.Facing,
    FRam.TurnSquash, HunterLensX, HunterLensY);
  var Size := Lerp(LensEmberSize, LensWinkSize, Level);
  var Color := LensColor;
  if FRam.LensHot then
  begin
    Size := Lerp(LensEmberSize, LensHotSize, Level);
    Color := LensHotColor;
  end
  else if FRam.Hurt then
    Size := LensHurtSize;
  DrawGlow(FArt.FRenderer, FArt.FGlow, Lens.X + ASprites.Origin.X,
    Lens.Y + ASprites.Origin.Y, Size, Color, Level);
end;

// Back to front: the dark of the well, the arches and the wheels, the
// mast as far as it stays in the hull, the hull with its eye, and what of
// the mast and the head - and the lens - stands over the middle line of
// the well once more, over the hull
procedure TRamPainter.DrawBody(const ASprites: TSpriteRenderer;
  AAlpha: Single);
begin
  if not FRam.Present then
    Exit;
  var Left := FRam.LeftAt(AAlpha);
  var Stand: THullStand;
  Stand.Center := UnitPoint(Left + RamWidth / 2, RamTop + RamHeight / 2);
  Stand.Mirrored := False;
  var Mast := FRam.MastAt(AAlpha);
  var Sway := FRam.SwayAt(AAlpha);

  ASprites.DrawSized(FArt.FWell, Stand.Center, RamWidth, RamHeight);
  FHull.DrawUnder(ASprites, Stand, AAlpha);
  ASprites.ClipAbove(RamTop + MastHiddenBelow);
  DrawMast(ASprites, Left, Mast, Sway, AAlpha);
  ASprites.ClearClip;
  FHull.DrawBody(ASprites, Stand, AAlpha);
  DrawEye(ASprites, Left, AAlpha);
  ASprites.ClipAbove(RamTop + WellY);
  DrawMast(ASprites, Left, Mast, Sway, AAlpha);
  DrawLens(ASprites, Left, Mast, Sway, AAlpha);
  // Once: the mast is drawn twice, and the heat is see-through
  if FRam.Head = rhSweeper then
  begin
    DrawOverload(ASprites, Left, Mast, Sway);
    DrawHeat(ASprites, Left, Mast, Sway, AAlpha);
  end;
  ASprites.ClearClip;
  DrawLamps(ASprites, Left, AAlpha);
end;

procedure TRamPainter.DrawSmoke(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  if not FRam.Present then
    Exit;
  for var Exhaust in FExhausts do
    Exhaust.Draw(ACanvas, Exhaust.Origin.X + AOrigin.X,
      Exhaust.Origin.Y + AOrigin.Y, AAlpha);
  FHeadSmoke.Draw(ACanvas, FHeadSmoke.Origin.X + AOrigin.X,
    FHeadSmoke.Origin.Y + AOrigin.Y, AAlpha);
end;

procedure TRamPainter.DrawLight(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  if not FRam.Present then
    Exit;
  for var Dust in FWaveDust do
    Dust.Draw(ACanvas, Dust.Origin.X + AOrigin.X, Dust.Origin.Y + AOrigin.Y,
      AAlpha);
  for var Short in FShorts do
    Short.Draw(ACanvas, Short.Origin.X + AOrigin.X, Short.Origin.Y + AOrigin.Y,
      AAlpha);
  FOverloadShort.Draw(ACanvas, FOverloadShort.Origin.X + AOrigin.X,
    FOverloadShort.Origin.Y + AOrigin.Y, AAlpha);
  var Left := FRam.LeftAt(AAlpha);
  var Middle := UnitPoint(Left + FRam.Body.Middle.X + AOrigin.X,
    RamTop + FRam.Body.Middle.Y + AOrigin.Y);
  FRam.Shield.Draw(ACanvas, FArt.FShield, Middle, AAlpha);
  if (FRam.Head = rhSweeper) and FRam.Armed then
  begin
    var Mast := FRam.MastAt(AAlpha);
    var Sway := FRam.SwayAt(AAlpha);
    for var i := Low(PlateMiddles) to High(PlateMiddles) do
    begin
      var Plate := HeadPoint(Left, Mast, Sway, rhSweeper, FRam.Facing,
        FRam.TurnSquash, PlateMiddles[i].X, PlateMiddles[i].Y);
      FRam.Plate(i).Draw(ACanvas, FArt.FShield,
        UnitPoint(Plate.X + AOrigin.X, Plate.Y + AOrigin.Y), AAlpha);
    end;
  end;
  DrawWave(AOrigin, AAlpha);
  DrawFlash(AOrigin, AAlpha);
end;

end.
