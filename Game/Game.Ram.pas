{
  Game.Ram - TeK-R13, the Ram: the TeK machine of level 2's boss arena. A
  hull on two wheels that faces left for good and drives back and forth,
  backward when it goes right; a mast of three sections in a well on its
  roof, with a head on the top of it; an eye that lights when the machine
  wakes, and brake lamps that burn as it brakes.

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
  the air, until he comes down onto the floor.

  After the lock the machine drives to a mark of its own, stands, drives
  again. The head does not shoot yet, and bullets pass the mast and the
  head: the heads become targets with their own stage.

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

type
  // rpWaiting - the music fades out, the machine is not on the screen yet;
  // rpBreathing - stopped at the mark of the entrance, the eye still dark
  TRamPhase = (rpAbsent, rpWaiting, rpDriving, rpBreathing, rpRising,
    rpResting);

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
    FHeroInFront: Boolean;
    FDice: TXorShift;
    FCue: TRamCue;
    procedure Place(AX: Single);
    procedure BeginDrive(ATarget, ACruise: Single; AEntering: Boolean);
    procedure BeginRest(ATicks: Integer);
    procedure BeginPatrolLeg;
    procedure TickPhase;
    procedure TickDrive;
    procedure Arrive(AOldSpeed: Single);
    procedure TickSway;
    procedure TickLamps;
    function Overlaps(const ABox: TSdlFRect): Boolean;
  public
    // ABody - the hull and the wheels on a grid of units (TRamArt.Body)
    constructor Create(const ABody: TShieldMask; ASeed: Cardinal);
    destructor Destroy; override;
    // Comes onto the screen as AOrders say: the whole entrance the first
    // time on the level - True, and the music must go silent - from the
    // stop on after that
    function Start(const AOrders: TRamOrders): Boolean;
    // Gone from the screen: a door, a death
    procedure Clear;
    // A new level: gone, and the entrance not seen
    procedure Reset;
    function Tick: TRamCue;
    // Where a bullet's stretch of this tick first meets the shield, which
    // flares there; False when it meets nothing
    function Block(const AFrom, ATo: TSdlFPoint; out AAt: TSdlFPoint): Boolean;
    // The hero's body touches the hull or a wheel and he is in the
    // machine's way: AOnDeck - he stands on a pad, AInAir - on his way up
    // or down. AAway - the side to throw him to, away from its middle.
    function Contact(const AHeroBody: TSdlFRect; AOnDeck, AInAir: Boolean;
      out AAway: Integer): Boolean;
    // On the screen to be seen and touched
    function Present: Boolean;
    // Between the last tick and this one, AAlpha of the way
    function LeftAt(AAlpha: Single): Single;
    function MastAt(AAlpha: Single): Single;
    function SwayAt(AAlpha: Single): Single;
    function LampsAt(AAlpha: Single): Single;
    // Units the hull has rolled this tick, to the right above zero
    function Rolled: Single;
    property Body: TShieldMask read FBody;
    property Shield: TTekShield read FShield;
    property Phase: TRamPhase read FPhase;
    property EyeLit: Boolean read FEyeLit;
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
    FHullArt: THullArt;
    FShield: TShieldArt;
    FLampGlow: PSdlTexture;
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
    procedure DrawMast(const ASprites: TSpriteRenderer; ALeft, AMast,
      ASway: Single);
    procedure DrawLamps(const ASprites: TSpriteRenderer; ALeft, AAlpha: Single);
  public
    // Both belong to the caller and must outlive the painter
    constructor Create(AArt: TRamArt; ARam: TRam);
    destructor Destroy; override;
    // After the Ram's tick: the wheels roll, the eye follows
    procedure Tick;
    // The machine, on the world's shake channel the sprites stand at
    procedure DrawBody(const ASprites: TSpriteRenderer; AAlpha: Single);
    // The shield
    procedure DrawLight(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  end;

implementation

uses
  System.SysUtils, System.Math, Render.Glow, Game.Space;

resourcestring
  SRamArtFailed = 'Cannot read the Ram''s body off "%s": %s';

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

  // The fight: a mark anywhere the hull fits a little off the walls, a leg
  // of a cell and a half at least, a rest of 1.5 to 3 s between legs
  PatrolSpeed = 1.4;
  PatrolMargin = 8;
  PatrolMinLeg = 48;
  PatrolRestMinTicks = 50;
  PatrolRestMaxTicks = 100;
  PatrolStopJolt = 0.12;

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
  // The head: its size and its socket (bottom centre); the sleeve the
  // barrel turns on; the barrel's size and its pivot
  HunterWidth = 27.7;
  HunterHeight = 18.8;
  HunterSocketX = 16.6;
  HunterSocketY = 18.7;
  HunterSleeveX = 1.9;
  HunterSleeveY = 7.1;
  BarrelWidth = 33.3;
  BarrelHeight = 9.3;
  BarrelPivotX = 30.9;
  BarrelPivotY = 4.3;

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
  LampGlowSide = 64;

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
// TRam
// ---------------------------------------------------------------------------

constructor TRam.Create(const ABody: TShieldMask; ASeed: Cardinal);
begin
  inherited Create;
  FBody := ABody;
  FShield := TTekShield.CreateOver(ABody);
  FDice.Seed := ASeed;
end;

destructor TRam.Destroy;
begin
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
  FHeroInFront := False;
end;

function TRam.Start(const AOrders: TRamOrders): Boolean;
begin
  FOrders := AOrders;
  Result := not FEntered;
  FEntered := True;
  FShield.Rise;
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
  FHeroInFront := False;
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

// Somewhere the hull fits a little off the walls, far enough to be a leg
procedure TRam.BeginPatrolLeg;
const
  Tries = 8;
begin
  var Lowest: Single := PatrolMargin;
  var Highest: Single := ScreenWidth - RamWidth - PatrolMargin;
  var Target := FX;
  for var i := 1 to Tries do
  begin
    Target := Lerp(Lowest, Highest, FDice.NextUnit);
    if Abs(Target - FX) >= PatrolMinLeg then
      Break;
  end;
  BeginDrive(Target, PatrolSpeed, False);
end;

function TRam.Tick: TRamCue;
begin
  FCue := Default(TRamCue);
  if FPhase = rpAbsent then
    Exit(FCue);

  Inc(FAge);
  FLastX := FX;
  FLastMast := FMast;
  FLastSway := FSway;
  FLastLamps := FLamps;
  FAccel := 0;
  TickPhase;
  TickSway;
  TickLamps;
  FShield.Tick;
  Result := FCue;
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
          BeginRest(LockRestTicks);
        end;
      end;
    rpResting:
      if FPhaseTicks > 0 then
        Dec(FPhaseTicks)
      else
        BeginPatrolLeg;
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
  FCue.Jolt := PatrolStopJolt;
  BeginRest(PatrolRestMinTicks +
    Round(FDice.NextUnit * (PatrolRestMaxTicks - PatrolRestMinTicks)));
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

procedure TRam.TickLamps;
begin
  if FBraking then
    FLamps := 1
  else if FLampHold > 0 then
    Dec(FLampHold)
  else
    FLamps := Max(0, FLamps - LampFade);
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

function TRam.Contact(const AHeroBody: TSdlFRect; AOnDeck, AInAir: Boolean;
  out AAway: Integer): Boolean;
begin
  AAway := 0;
  if not Present or not Overlaps(AHeroBody) then
  begin
    FHeroInFront := False;
    Exit(False);
  end;
  if AOnDeck then
  begin
    FHeroInFront := True;
    Exit(False);
  end;
  if FHeroInFront and AInAir then
    Exit(False);

  FHeroInFront := False;
  AAway := 1;
  if AHeroBody.X + AHeroBody.W / 2 < FX + RamWidth / 2 then
    AAway := -1;
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
  FHullArt := THullArt.Create(ARenderer, RamHullDef);
  FShield := TShieldArt.Create(ARenderer);
  FLampGlow := CreateGlowShape(ARenderer, gsPoint, LampGlowSide);
  FBody := ReadBody(FSpriteSet);
end;

// The cache before the set: it reads from the set, never the reverse
destructor TRamArt.Destroy;
begin
  if Assigned(FLampGlow) then
    SDL_DestroyTexture(FLampGlow);
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
  FHull := THull.Create(RamHullDef, AArt.FHullArt);
  FHull.Doze;
end;

destructor TRamPainter.Destroy;
begin
  FHull.Free;
  inherited;
end;

procedure TRamPainter.Tick;
begin
  if FRam.EyeLit then
    FHull.Awake := True
  else
    FHull.Doze;
  FHull.Tick(0, 0, FRam.Rolled);
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

// The sections back to front - the narrowest rides out of the wider ones
// - each top raised by its share of the mast's rise; the head on the top
// collar, the barrel over the head on its sleeve. All of it turned with
// the sway about the middle of the well.
procedure TRamPainter.DrawMast(const ASprites: TSpriteRenderer; ALeft, AMast,
  ASway: Single);
begin
  var Pivot := UnitPoint(ALeft + WellX, RamTop + WellY);
  var Rise := AMast - MastRest;
  for var Section := High(FArt.FMasts) downto Low(FArt.FMasts) do
  begin
    var Top := Pivot.Y - MastRest - Rise * Section / High(FArt.FMasts);
    var Middle := UnitPoint(Pivot.X, Top + MastLengths[Section] / 2);
    ASprites.DrawSized(FArt.FMasts[Section], Turned(Middle, Pivot, ASway),
      MastWidths[Section], MastLengths[Section], 1, False, ASway);
  end;

  var HeadLeft := Pivot.X - HunterSocketX;
  var HeadTop := Pivot.Y - MastRest - Rise - HunterSocketY;
  var Head := UnitPoint(HeadLeft + HunterWidth / 2, HeadTop + HunterHeight / 2);
  ASprites.DrawSized(FArt.FHunter, Turned(Head, Pivot, ASway), HunterWidth,
    HunterHeight, 1, False, ASway);
  var Barrel := UnitPoint(
    HeadLeft + HunterSleeveX - BarrelPivotX + BarrelWidth / 2,
    HeadTop + HunterSleeveY - BarrelPivotY + BarrelHeight / 2);
  ASprites.DrawSized(FArt.FHunterBarrel, Turned(Barrel, Pivot, ASway),
    BarrelWidth, BarrelHeight, 1, False, ASway);
end;

procedure TRamPainter.DrawLamps(const ASprites: TSpriteRenderer;
  ALeft, AAlpha: Single);
begin
  var Level := FRam.LampsAt(AAlpha);
  if Level <= 0 then
    Exit;
  for var Lamp in LampPoints do
    DrawGlow(FArt.FRenderer, FArt.FLampGlow,
      ALeft + Lamp.X + ASprites.Origin.X, RamTop + Lamp.Y + ASprites.Origin.Y,
      LampSize, LampColor, Level);
end;

// Back to front: the dark of the well, the arches and the wheels, the
// mast as far as it stays in the hull, the hull with its eye, and what of
// the mast and the head stands over the middle line of the well once more,
// over the hull
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
  DrawMast(ASprites, Left, Mast, Sway);
  ASprites.ClearClip;
  FHull.DrawBody(ASprites, Stand, AAlpha);
  ASprites.ClipAbove(RamTop + WellY);
  DrawMast(ASprites, Left, Mast, Sway);
  ASprites.ClearClip;
  DrawLamps(ASprites, Left, AAlpha);
end;

procedure TRamPainter.DrawLight(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  if not FRam.Present then
    Exit;
  var Middle := UnitPoint(FRam.LeftAt(AAlpha) + FRam.Body.Middle.X + AOrigin.X,
    RamTop + FRam.Body.Middle.Y + AOrigin.Y);
  FRam.Shield.Draw(ACanvas, FArt.FShield, Middle, AAlpha);
end;

end.
