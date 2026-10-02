{
  Effects.Debris - what an explosion throws: shards of metal that fly,
  ring off the walls, settle on the floor, cool from white heat to bare
  metal and fade; and a burst of sparks (Effects.Sparks) that die on the
  first wall they meet.

  The solid layer comes from the caller as a probe, so the unit knows no
  level. The shard shapes are generated at startup, like the smoke
  puffs: torn bits of sheet metal, white with the light in them, the
  shape in alpha - the heat arrives at draw time as a color mod.

  Pure decoration: debris wounds nobody, the 2008 fragment fans do.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Effects.Debris;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Render.Brush, Effects.Sparks;

const
  ShardShapes = 4;

type
  EDebrisError = class(Exception);

  // One blast's worth of debris. Speeds in units per tick, sizes in
  // units across; every piece rolls between a share of the value and
  // the value itself.
  TDebrisLook = record
    Shards: Integer;
    ShardSpeed: Single;
    ShardSize: Single;
    ShardCone: Single; // degrees wide, centered straight up
    RestSeconds: Single; // on the floor, before the fade
    Sparks: Integer;
    SparkSpeed: Single;
  end;

  TDebrisField = class
  private type
    // Sliding - down on the floor for good, still skidding
    TShardState = (ssFlying, ssSliding, ssResting);

    TShard = record
      X, Y: Single; // the center, screen units
      SpeedX, SpeedY: Single; // units per tick
      Angle, Spin: Single; // degrees, degrees per tick
      Size: Single;
      Shape: Integer;
      Age, Life: Integer; // ticks
      RestTicks: Integer;
      State: TShardState;
    end;
  private
    FRenderer: PSdlRenderer;
    FProbe: TSolidProbe;
    FShapes: array [0..ShardShapes - 1] of PSdlTexture;
    FGlow: PSdlTexture;
    FShards: TArray<TShard>;
    FShardCount: Integer;
    FSparks: TSparkField;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function Roll(AFrom, ATo: Single): Single;
    procedure AddShard(const AShard: TShard);
    procedure SpawnShard(AX, AY: Single; const ALook: TDebrisLook);
    procedure SpawnSparks(AX, AY: Single; const ALook: TDebrisLook);
    function StopsSpark(AX, AY: Single): Boolean;
    procedure MoveShard(var AShard: TShard);
    procedure FlyShard(var AShard: TShard);
    procedure LandShard(var AShard: TShard; AGroundY: Single);
    procedure SlideShard(var AShard: TShard);
    procedure DrawShard(const AShard: TShard; AOrigin: TSdlPoint;
      AAlpha: Single);
  public
    // AProbe answers in screen units
    constructor Create(ARenderer: PSdlRenderer; const AProbe: TSolidProbe);
    destructor Destroy; override;
    // AX/AY - the heart of the blast, screen units
    procedure Burst(AX, AY: Single; const ALook: TDebrisLook);
    procedure Tick;
    // AOrigin - the shake of the world, which the debris rides
    procedure Draw(AOrigin: TSdlPoint; AAlpha: Single);
    // A door or a death: nothing follows the hero to the next screen
    procedure Clear;
  end;

implementation

uses
  System.Math, Game.Space, Render.Glow;

resourcestring
  SShardTextureFailed = 'Cannot create a shard texture: %s';

const
  LogicTicksPerSecond = 33;
  // A burst over a chain of barrels past these drops the oldest pieces
  MaxShards = 256;
  MaxSparks = 512;

  ShapeSide = 24; // texture pixels
  GlowSide = 32;

  // The fall of the 2008 fragment fans (influence 30, DY += 30/100), so
  // the shards come down with the fire they fly out of
  ShardGravity = 0.3;
  SparkGravity = 0.12;
  ShardAirKeep = 0.99;
  SparkAirKeep = 0.9;
  FloorBounce = 0.35; // the vertical speed kept off the floor
  WallBounce = 0.5;
  FloorGrip = 0.7; // the horizontal speed kept per floor bounce
  SpinGrip = 0.6;
  RestSpeed = 0.9; // a landing slower than this stays down
  SlideGrip = 0.8; // the speed kept per tick of skidding on the floor
  StopSpeed = 0.1;
  // How far under a skidding shard the floor is felt for
  FloorFeel = 1;
  // Halvings of the last step that find where the floor begins
  FloorSearchSteps = 5;
  // A shard lying flat shows above the floor line, not half sunk in it
  RestLift = 0.3;
  MaxFlightTicks = 10 * LogicTicksPerSecond;

  // Every piece rolls its speed and size from this share of the look
  MinShare = 0.35;
  SpawnSpread = 6; // units around the heart of the blast
  MaxShardSpin = 24;
  SparkLifeMin = 5;
  SparkLifeMax = 14;
  // A spark draws as the path it covers in this many ticks
  StreakTicks = 1.6;
  StreakWidth = 3;
  FullCircle = 360;
  SparkSeed = $5370726B; // "Sprk"

  CoolTicks = 45; // white heat to bare metal
  HotShare = 0.25; // of the cooling: white heat to the ember's red
  FadeTicks = 25;
  EmberGlowScale = 3; // the ember's glow across, in shard sizes
  EmberGlowLevel = 0.7;

  HotColor: TRgb = (R: 255; G: 244; B: 214);
  EmberColor: TRgb = (R: 255; G: 96; B: 32);
  MetalColor: TRgb = (R: 92; G: 94; B: 100);

  // The shapes: torn plates of five to seven corners, folded once
  ShardCornersMin = 5;
  ShardCornersMax = 7;
  CornerReachMin = 0.45; // of the half-side
  CornerJitter = 0.6; // of the even step between corners
  ShapeMargin = 0.92;
  LitShade = 1.0;
  ShadowShade = 0.62;
  ShapeSeedSalt = $5EED;
  DiceWarmUp = 3;
  SuperSamples = 4;

type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888

function InsidePolygon(const ACorners: TArray<TSdlFPoint>;
  AX, AY: Single): Boolean;
begin
  Result := False;
  var Previous := High(ACorners);
  for var i := 0 to High(ACorners) do
  begin
    if ((ACorners[i].Y > AY) <> (ACorners[Previous].Y > AY)) and
      (AX < (ACorners[Previous].X - ACorners[i].X) * (AY - ACorners[i].Y) /
      (ACorners[Previous].Y - ACorners[i].Y) + ACorners[i].X) then
      Result := not Result;
    Previous := i;
  end;
end;

// The share of the pixel inside the plate, from a 2x2 grid of samples
function PixelCover(const ACorners: TArray<TSdlFPoint>; ACol, ARow: Integer;
  AHalf: Single): Single;
begin
  var Inside := 0;
  for var Sample := 0 to SuperSamples - 1 do
    if InsidePolygon(ACorners, (ACol + 0.25 + 0.5 * (Sample mod 2) - AHalf) / AHalf,
      (ARow + 0.25 + 0.5 * (Sample div 2) - AHalf) / AHalf) then
      Inc(Inside);
  Result := Inside / SuperSamples;
end;

function ShardCorners(var ADice: TXorShift): TArray<TSdlFPoint>;
begin
  SetLength(Result, ShardCornersMin +
    Trunc(ADice.NextUnit * (ShardCornersMax - ShardCornersMin + 1)));
  for var i := 0 to High(Result) do
  begin
    var Turn: Single := 2 * Pi * (i + (ADice.NextUnit - 0.5) * CornerJitter) /
      Length(Result);
    var Reach: Single := CornerReachMin + (1 - CornerReachMin) * ADice.NextUnit;
    Result[i].X := Cos(Turn) * Reach * ShapeMargin;
    Result[i].Y := Sin(Turn) * Reach * ShapeMargin;
  end;
end;

procedure FillShard(ASurface: PSdlSurface; ASeed: Cardinal);
var
  Dice: TXorShift;
begin
  Dice.Seed := (ASeed shl 8) xor ShapeSeedSalt or 1;
  for var i := 1 to DiceWarmUp do
    Dice.NextUnit;
  var Corners := ShardCorners(Dice);
  // A bent plate: the side of the fold that faces the light is bright
  var FoldTurn: Single := 2 * Pi * Dice.NextUnit;
  var FoldX: Single := Cos(FoldTurn);
  var FoldY: Single := Sin(FoldTurn);

  var Half: Single := ASurface.W / 2;
  SDL_LockSurface(ASurface);
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    for var Col := 0 to ASurface.W - 1 do
    begin
      var Cover := PixelCover(Corners, Col, Row, Half);
      var DX := (Col + 0.5 - Half) / Half;
      var DY := (Row + 0.5 - Half) / Half;
      var Shade: Single := LitShade;
      if DX * FoldX + DY * FoldY < 0 then
        Shade := ShadowShade;
      var Bright: Byte := Round(255 * Shade);
      Pixel[0] := Bright;
      Pixel[1] := Bright;
      Pixel[2] := Bright;
      Pixel[3] := Round(255 * Cover);
      Inc(Pixel);
    end;
  end;
  SDL_UnlockSurface(ASurface);
end;

function CreateShardTexture(ARenderer: PSdlRenderer;
  ASeed: Cardinal): PSdlTexture;
begin
  var Surface := SDL_CreateRGBSurfaceWithFormat(0, ShapeSide, ShapeSide, 32,
    SdlPixelFormatAbgr8888);
  if Surface = nil then
    raise EDebrisError.CreateFmt(SShardTextureFailed, [SdlErrorText]);
  try
    FillShard(Surface, ASeed);
    Result := SDL_CreateTextureFromSurface(ARenderer, Surface);
  finally
    SDL_FreeSurface(Surface);
  end;
  if Result = nil then
    raise EDebrisError.CreateFmt(SShardTextureFailed, [SdlErrorText]);
  SDL_SetTextureBlendMode(Result, SdlBlendModeBlend);
  SDL_SetTextureScaleMode(Result, SdlScaleModeLinear);
end;

// The sparks of a blast cool the way its shards start to
function BlastSparkLook: TSparkLook;
begin
  Result.Gravity := SparkGravity;
  Result.AirKeep := SparkAirKeep;
  Result.LifeMin := SparkLifeMin;
  Result.LifeMax := SparkLifeMax;
  Result.Width := StreakWidth;
  Result.StreakTicks := StreakTicks;
  Result.HotColor := HotColor;
  Result.CoolColor := EmberColor;
  Result.Wall := swDie;
end;

// White heat, the ember's red, bare metal - AShare 0..1 of the cooling
function HeatColor(AShare: Single): TRgb;
begin
  if AShare < HotShare then
    Result := Mix(HotColor, EmberColor, AShare / HotShare)
  else
    Result := Mix(EmberColor, MetalColor, (AShare - HotShare) / (1 - HotShare));
end;

// ---------------------------------------------------------------------------
// TDebrisField
// ---------------------------------------------------------------------------

constructor TDebrisField.Create(ARenderer: PSdlRenderer;
  const AProbe: TSolidProbe);
begin
  inherited Create;
  FRenderer := ARenderer;
  FProbe := AProbe;
  FRandom.Seed := $426F6F6D; // "Boom"
  SetLength(FShards, MaxShards);
  FSparks := TSparkField.Create(BlastSparkLook, StopsSpark, MaxSparks,
    SparkSeed);
  for var i := 0 to ShardShapes - 1 do
    FShapes[i] := CreateShardTexture(ARenderer, i + 1);
  FGlow := CreateGlowShape(ARenderer, gsPoint, GlowSide);
end;

destructor TDebrisField.Destroy;
begin
  // A constructor that raised halfway leaves the rest nil
  for var i := 0 to ShardShapes - 1 do
    if Assigned(FShapes[i]) then
      SDL_DestroyTexture(FShapes[i]);
  if Assigned(FGlow) then
    SDL_DestroyTexture(FGlow);
  FSparks.Free;
  inherited;
end;

function TDebrisField.Roll(AFrom, ATo: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * FRandom.NextUnit;
end;

procedure TDebrisField.AddShard(const AShard: TShard);
begin
  if FShardCount = MaxShards then
  begin
    for var i := 1 to FShardCount - 1 do
      FShards[i - 1] := FShards[i];
    Dec(FShardCount);
  end;
  FShards[FShardCount] := AShard;
  Inc(FShardCount);
end;

procedure TDebrisField.SpawnShard(AX, AY: Single; const ALook: TDebrisLook);
var
  Shard: TShard;
begin
  Shard := Default(TShard);
  Shard.X := AX + Roll(-SpawnSpread, SpawnSpread);
  Shard.Y := AY + Roll(-SpawnSpread, SpawnSpread);
  // Born inside a wall it could never leave
  if FProbe(Shard.X, Shard.Y) then
    Exit;
  var Degrees: Single := 90 + (FRandom.NextUnit - 0.5) * ALook.ShardCone;
  var Heading: Single := DegToRad(Degrees);
  var Speed: Single := ALook.ShardSpeed * Roll(MinShare, 1);
  // Counterclockwise on paper, and the screen's Y runs down
  Shard.SpeedX := Cos(Heading) * Speed;
  Shard.SpeedY := -Sin(Heading) * Speed;
  Shard.Angle := Roll(0, 360);
  Shard.Spin := Roll(-MaxShardSpin, MaxShardSpin);
  Shard.Size := ALook.ShardSize * Roll(MinShare, 1);
  Shard.Shape := Min(ShardShapes - 1, Trunc(FRandom.NextUnit * ShardShapes));
  Shard.Life := MaxFlightTicks;
  Shard.RestTicks := Round(ALook.RestSeconds * LogicTicksPerSecond *
    Roll(MinShare, 1));
  AddShard(Shard);
end;

procedure TDebrisField.SpawnSparks(AX, AY: Single; const ALook: TDebrisLook);
var
  Spray: TSparkSpray;
begin
  Spray.Count := ALook.Sparks;
  Spray.Heading := 0;
  Spray.Cone := FullCircle;
  Spray.SlowSpeed := ALook.SparkSpeed * MinShare;
  Spray.FastSpeed := ALook.SparkSpeed;
  FSparks.Spray(AX, AY, Spray);
end;

procedure TDebrisField.Burst(AX, AY: Single; const ALook: TDebrisLook);
begin
  for var i := 1 to ALook.Shards do
    SpawnShard(AX, AY, ALook);
  SpawnSparks(AX, AY, ALook);
end;

procedure TDebrisField.MoveShard(var AShard: TShard);
begin
  Inc(AShard.Age);
  case AShard.State of
    ssFlying:
      FlyShard(AShard);
    ssSliding:
      SlideShard(AShard);
  end;
end;

// One axis at a time: a wall turns X back, a floor or a ceiling Y - a
// shard thrown into a corner gets both
procedure TDebrisField.FlyShard(var AShard: TShard);
begin
  AShard.SpeedX := AShard.SpeedX * ShardAirKeep;
  AShard.SpeedY := AShard.SpeedY * ShardAirKeep + ShardGravity;
  AShard.Angle := AShard.Angle + AShard.Spin;

  var NextX := AShard.X + AShard.SpeedX;
  if FProbe(NextX, AShard.Y) then
  begin
    AShard.SpeedX := -AShard.SpeedX * WallBounce;
    AShard.Spin := -AShard.Spin * SpinGrip;
  end
  else
    AShard.X := NextX;

  var NextY := AShard.Y + AShard.SpeedY;
  if not FProbe(AShard.X, NextY) then
    AShard.Y := NextY
  else if AShard.SpeedY < 0 then
    AShard.SpeedY := -AShard.SpeedY * WallBounce
  else
    LandShard(AShard, NextY);
end;

// The shard reached the floor somewhere between where it is and
// AGroundY; halving the step finds the line without knowing the grid
procedure TDebrisField.LandShard(var AShard: TShard; AGroundY: Single);
begin
  var Air := AShard.Y;
  var Ground := AGroundY;
  for var i := 1 to FloorSearchSteps do
  begin
    var Middle := (Air + Ground) / 2;
    if FProbe(AShard.X, Middle) then
      Ground := Middle
    else
      Air := Middle;
  end;
  AShard.Y := Air;

  if AShard.SpeedY >= RestSpeed then
  begin
    AShard.SpeedY := -AShard.SpeedY * FloorBounce;
    AShard.SpeedX := AShard.SpeedX * FloorGrip;
    AShard.Spin := AShard.Spin * SpinGrip;
    Exit;
  end;

  AShard.State := ssSliding;
  AShard.Y := Air - AShard.Size * RestLift;
  AShard.SpeedY := 0;
end;

// Down for good, it skids on along the floor until friction stops it;
// past the edge of the floor it falls again
procedure TDebrisField.SlideShard(var AShard: TShard);
begin
  AShard.SpeedX := AShard.SpeedX * SlideGrip;
  AShard.Spin := AShard.Spin * SlideGrip;
  AShard.Angle := AShard.Angle + AShard.Spin;

  var NextX := AShard.X + AShard.SpeedX;
  if FProbe(NextX, AShard.Y) then
    AShard.SpeedX := 0
  else
    AShard.X := NextX;

  if not FProbe(AShard.X, AShard.Y + AShard.Size * RestLift + FloorFeel) then
  begin
    AShard.State := ssFlying;
    Exit;
  end;
  if Abs(AShard.SpeedX) < StopSpeed then
  begin
    AShard.State := ssResting;
    AShard.SpeedX := 0;
    AShard.Spin := 0;
    AShard.Life := AShard.Age + AShard.RestTicks + FadeTicks;
  end;
end;

function OffScreen(AX, AY: Single): Boolean;
begin
  Result := (AX < 0) or (AX > ScreenWidth) or (AY > ScreenHeight) or
    (AY < -ScreenHeight);
end;

function TDebrisField.StopsSpark(AX, AY: Single): Boolean;
begin
  Result := OffScreen(AX, AY) or FProbe(AX, AY);
end;

procedure TDebrisField.Tick;
begin
  var Kept := 0;
  for var i := 0 to FShardCount - 1 do
  begin
    var Shard := FShards[i];
    MoveShard(Shard);
    if (Shard.Age >= Shard.Life) or OffScreen(Shard.X, Shard.Y) then
      Continue;
    FShards[Kept] := Shard;
    Inc(Kept);
  end;
  FShardCount := Kept;

  FSparks.Tick;
end;

procedure TDebrisField.DrawShard(const AShard: TShard; AOrigin: TSdlPoint;
  AAlpha: Single);
var
  Dest: TSdlFRect;
begin
  var Fade: Single := (AShard.Life - AShard.Age - AAlpha) / FadeTicks;
  if Fade <= 0 then
    Exit;
  if Fade > 1 then
    Fade := 1;
  var Cooling: Single := (AShard.Age + AAlpha) / CoolTicks;
  if Cooling > 1 then
    Cooling := 1;
  var Color := HeatColor(Cooling);
  var CenterX: Single := AOrigin.X + AShard.X + AShard.SpeedX * AAlpha;
  var CenterY: Single := AOrigin.Y + AShard.Y + AShard.SpeedY * AAlpha;

  Dest.X := CenterX - AShard.Size / 2;
  Dest.Y := CenterY - AShard.Size / 2;
  Dest.W := AShard.Size;
  Dest.H := AShard.Size;
  var Texture := FShapes[AShard.Shape];
  SDL_SetTextureColorMod(Texture, Color.R, Color.G, Color.B);
  SDL_SetTextureAlphaMod(Texture, Round(255 * Fade));
  SDL_RenderCopyExF(FRenderer, Texture, nil, @Dest,
    AShard.Angle + AShard.Spin * AAlpha, nil, SdlFlipNone);

  if Cooling < 1 then
    DrawGlow(FRenderer, FGlow, CenterX, CenterY,
      AShard.Size * EmberGlowScale, Color,
      EmberGlowLevel * Sqr(1 - Cooling) * Fade);
end;

procedure TDebrisField.Draw(AOrigin: TSdlPoint; AAlpha: Single);
var
  SparkOrigin: TSdlFPoint;
begin
  for var i := 0 to FShardCount - 1 do
    DrawShard(FShards[i], AOrigin, AAlpha);

  SparkOrigin.X := AOrigin.X;
  SparkOrigin.Y := AOrigin.Y;
  FSparks.Draw(SparkBrush(FRenderer, FGlow), SparkOrigin, AAlpha);
end;

procedure TDebrisField.Clear;
begin
  FShardCount := 0;
  FSparks.Clear;
end;

end.
