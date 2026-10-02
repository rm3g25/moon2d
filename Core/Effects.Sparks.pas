{
  Effects.Sparks - sparks: short hot streaks that fly from a point, fall,
  slow in the air, cool from white heat to a dull red and are gone in a
  blink. Some ring off the walls on the way, losing speed and life with
  every bounce, and some end in a fork of short sprigs, as steel does.

  A field holds the sparks of one look - how they fly, cool and meet a
  wall. Who throws them, and when, is the owner's business: the field
  only carries them to their end. The solid layer comes from the owner as
  a probe, so the unit knows no level; the picture of a streak comes with
  every draw, so the field owns no texture.

  Pure decoration: a spark wounds nobody.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Effects.Sparks;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush;

type
  // True when the point is inside something solid
  TSolidProbe = reference to function(AX, AY: Single): Boolean;

  TSparkWall = (swPass, swDie, swBounce);

  TSparkHeat = record
    Hot, Warm, Cool: TRgb;
    WarmAt: Single; // the share of the life the warm color falls on
  end;

  TSparkBounce = record
    Keep: Single; // of the speed into the wall
    Grip: Single; // of the speed along a floor
    LifeLost: Single; // of the life still ahead
  end;

  // Speeds in units per tick, lives in ticks, sizes in units, the rest
  // shares, 0..1
  TSparkLook = record
    Gravity: Single; // added to the fall every tick
    AirKeep: Single; // of the speed, per tick
    LifeMin, LifeMax: Single;
    Width: Single; // the thickest streak across
    ThinShare: Single; // the thinnest one, as a share of Width
    StreakTicks: Single; // the streak is the path of this many ticks
    // 1 spreads the speeds of a throw evenly; above it most sparks come
    // out slow and a few fast
    SpeedCurve: Single;
    Level: Single; // the brightness of a fresh spark
    Heat: TSparkHeat;
    Wall: TSparkWall;
    Bounce: TSparkBounce; // read by swBounce alone
    // A spark may throw a fork of sprigs when its life runs out, and
    // again on every bounce it survives
    ForkChance: Single;
  end;

  TSparkSpray = record
    Count: Integer;
    Heading: Single; // degrees counterclockwise from the right, 90 = up
    Cone: Single; // degrees wide, centered on the heading
    SlowSpeed, FastSpeed: Single;
  end;

  // The streak is a glow texture (Render.Glow): the comet with its hot
  // end at the right edge, or a round one for a plain blur
  TSparkBrush = record
    Renderer: PSdlRenderer;
    Streak: PSdlTexture;
  end;

  TSparkField = class
  private type
    TSpark = record
      X, Y: Single;
      SpeedX, SpeedY: Single;
      Age, Life: Integer;
      Width: Single;
      Bounces: Integer;
      IsSprig: Boolean; // thrown by a fork; throws none of its own
    end;
  private
    FLook: TSparkLook;
    FSolid: TSolidProbe;
    FSparks: TArray<TSpark>;
    FCount: Integer;
    FForked: TArray<TSpark>; // this tick's
    FForkCount: Integer;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function Roll(AFrom, ATo: Single): Single;
    procedure Add(const ASpark: TSpark);
    procedure MoveSpark(var ASpark: TSpark);
    procedure Fly(var ASpark: TSpark);
    procedure Rebound(var ASpark: TSpark);
    procedure PayForBounce(var ASpark: TSpark);
    procedure TryFork(const ASpark: TSpark);
    procedure ThrowSprigs(const AParent: TSpark);
    procedure DrawSpark(const ABrush: TSparkBrush; const ASpark: TSpark;
      const AOrigin: TSdlFPoint; AAlpha: Single);
  public
    // ASolid may be nil for sparks that pass through walls. A field past
    // ACapacity drops its oldest sparks.
    constructor Create(const ALook: TSparkLook; const ASolid: TSolidProbe;
      ACapacity: Integer; ASeed: Cardinal);
    procedure Spray(AX, AY: Single; const ASpray: TSparkSpray);
    // The owner's frame moved by (ADX, ADY); what is already in flight
    // stays where it is on the screen
    procedure ShiftFrame(ADX, ADY: Single);
    procedure Tick;
    // AOrigin - where the field's zero stands on the screen; AAlpha is
    // the timestep's, for motion between ticks
    procedure Draw(const ABrush: TSparkBrush; const AOrigin: TSdlFPoint;
      AAlpha: Single);
    procedure Clear;
  end;

function SparkBrush(ARenderer: PSdlRenderer; AStreak: PSdlTexture): TSparkBrush;

implementation

uses
  System.Math;

const
  MaxBounces = 3;
  MinBounceSpeed = 0.6; // slower than this after a bounce, a spark is out
  MinForkSpeed = 0.8;
  MaxForksPerTick = 32;
  SprigsMin = 2;
  SprigsMax = 3;
  SprigCone = 96; // degrees wide, around the parent's heading
  SprigSpeedShare = 0.7; // of the parent's speed
  SprigKick = 0.6; // on top of it, units per tick
  SprigLifeMin = 3;
  SprigLifeMax = 7;
  SprigWidthShare = 0.6;

function SparkBrush(ARenderer: PSdlRenderer; AStreak: PSdlTexture): TSparkBrush;
begin
  Result.Renderer := ARenderer;
  Result.Streak := AStreak;
end;

function HeatColor(const AHeat: TSparkHeat; AShare: Single): TRgb;
begin
  if AShare >= 1 then
    Exit(AHeat.Cool);
  if AShare < AHeat.WarmAt then
    Exit(Mix(AHeat.Hot, AHeat.Warm, AShare / AHeat.WarmAt));
  Result := Mix(AHeat.Warm, AHeat.Cool,
    (AShare - AHeat.WarmAt) / (1 - AHeat.WarmAt));
end;

constructor TSparkField.Create(const ALook: TSparkLook;
  const ASolid: TSolidProbe; ACapacity: Integer; ASeed: Cardinal);
begin
  inherited Create;
  FLook := ALook;
  FSolid := ASolid;
  SetLength(FSparks, ACapacity);
  SetLength(FForked, MaxForksPerTick);
  FRandom.Seed := ASeed or 1;
end;

function TSparkField.Roll(AFrom, ATo: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * FRandom.NextUnit;
end;

procedure TSparkField.Add(const ASpark: TSpark);
begin
  if FCount = Length(FSparks) then
  begin
    for var i := 1 to FCount - 1 do
      FSparks[i - 1] := FSparks[i];
    Dec(FCount);
  end;
  FSparks[FCount] := ASpark;
  Inc(FCount);
end;

procedure TSparkField.Spray(AX, AY: Single; const ASpray: TSparkSpray);
begin
  for var i := 1 to ASpray.Count do
  begin
    var Spark := Default(TSpark);
    Spark.X := AX;
    Spark.Y := AY;
    var Degrees: Single := ASpray.Heading +
      (FRandom.NextUnit - 0.5) * ASpray.Cone;
    var Heading: Single := DegToRad(Degrees);
    var Speed: Single := ASpray.SlowSpeed +
      (ASpray.FastSpeed - ASpray.SlowSpeed) *
      Power(FRandom.NextUnit, FLook.SpeedCurve);
    // Counterclockwise on paper, and the screen's Y runs down
    Spark.SpeedX := Cos(Heading) * Speed;
    Spark.SpeedY := -Sin(Heading) * Speed;
    Spark.Life := Max(1, Round(Roll(FLook.LifeMin, FLook.LifeMax)));
    Spark.Width := FLook.Width * Roll(FLook.ThinShare, 1);
    Add(Spark);
  end;
end;

procedure TSparkField.ShiftFrame(ADX, ADY: Single);
begin
  for var i := 0 to FCount - 1 do
  begin
    FSparks[i].X := FSparks[i].X - ADX;
    FSparks[i].Y := FSparks[i].Y - ADY;
  end;
end;

procedure TSparkField.MoveSpark(var ASpark: TSpark);
begin
  Inc(ASpark.Age);
  if ASpark.Age >= ASpark.Life then
  begin
    TryFork(ASpark);
    Exit;
  end;

  ASpark.SpeedX := ASpark.SpeedX * FLook.AirKeep;
  ASpark.SpeedY := ASpark.SpeedY * FLook.AirKeep + FLook.Gravity;
  case FLook.Wall of
    swDie:
      if FSolid(ASpark.X + ASpark.SpeedX, ASpark.Y + ASpark.SpeedY) then
        ASpark.Age := ASpark.Life
      else
        Fly(ASpark);
    swBounce:
      Rebound(ASpark);
  else
    Fly(ASpark);
  end;
end;

procedure TSparkField.Fly(var ASpark: TSpark);
begin
  ASpark.X := ASpark.X + ASpark.SpeedX;
  ASpark.Y := ASpark.Y + ASpark.SpeedY;
end;

// One axis at a time: a wall turns X back, a floor or a ceiling Y - a
// spark thrown into a corner gets both
procedure TSparkField.Rebound(var ASpark: TSpark);
begin
  var Bounced := False;
  var NextX := ASpark.X + ASpark.SpeedX;
  if FSolid(NextX, ASpark.Y) then
  begin
    ASpark.SpeedX := -ASpark.SpeedX * FLook.Bounce.Keep;
    Bounced := True;
  end
  else
    ASpark.X := NextX;

  var NextY := ASpark.Y + ASpark.SpeedY;
  if FSolid(ASpark.X, NextY) then
  begin
    ASpark.SpeedY := -ASpark.SpeedY * FLook.Bounce.Keep;
    ASpark.SpeedX := ASpark.SpeedX * FLook.Bounce.Grip;
    Bounced := True;
  end
  else
    ASpark.Y := NextY;

  if Bounced then
    PayForBounce(ASpark);
end;

procedure TSparkField.PayForBounce(var ASpark: TSpark);
begin
  Inc(ASpark.Bounces);
  ASpark.Life := ASpark.Life -
    Trunc((ASpark.Life - ASpark.Age) * FLook.Bounce.LifeLost);
  var Speed: Single := Hypot(ASpark.SpeedX, ASpark.SpeedY);
  if (ASpark.Bounces > MaxBounces) or (Speed < MinBounceSpeed) then
  begin
    ASpark.Age := ASpark.Life;
    Exit;
  end;
  TryFork(ASpark);
end;

// Only notes the spark: the field is being swept, and its sprigs must
// not land under the broom
procedure TSparkField.TryFork(const ASpark: TSpark);
begin
  if ASpark.IsSprig or (FForkCount = MaxForksPerTick) then
    Exit;
  if Hypot(ASpark.SpeedX, ASpark.SpeedY) < MinForkSpeed then
    Exit;
  if FRandom.NextUnit >= FLook.ForkChance then
    Exit;
  FForked[FForkCount] := ASpark;
  Inc(FForkCount);
end;

procedure TSparkField.ThrowSprigs(const AParent: TSpark);
begin
  var ParentSpeed: Single := Hypot(AParent.SpeedX, AParent.SpeedY);
  var ParentHeading: Single := ArcTan2(AParent.SpeedY, AParent.SpeedX);
  var Sprigs: Integer := SprigsMin +
    Trunc(FRandom.NextUnit * (SprigsMax - SprigsMin + 1));
  for var i := 1 to Sprigs do
  begin
    var Sprig := Default(TSpark);
    Sprig.X := AParent.X;
    Sprig.Y := AParent.Y;
    var TurnDegrees: Single := (FRandom.NextUnit - 0.5) * SprigCone;
    var Heading: Single := ParentHeading + DegToRad(TurnDegrees);
    var Speed: Single := ParentSpeed * SprigSpeedShare + SprigKick;
    Sprig.SpeedX := Cos(Heading) * Speed;
    Sprig.SpeedY := Sin(Heading) * Speed;
    Sprig.Life := Round(Roll(SprigLifeMin, SprigLifeMax));
    Sprig.Width := AParent.Width * SprigWidthShare;
    Sprig.IsSprig := True;
    Add(Sprig);
  end;
end;

procedure TSparkField.Tick;
begin
  FForkCount := 0;
  var Kept := 0;
  for var i := 0 to FCount - 1 do
  begin
    var Spark := FSparks[i];
    MoveSpark(Spark);
    if Spark.Age >= Spark.Life then
      Continue;
    FSparks[Kept] := Spark;
    Inc(Kept);
  end;
  FCount := Kept;

  for var i := 0 to FForkCount - 1 do
    ThrowSprigs(FForked[i]);
end;

// A streak along the path of the last ticks: the head where the spark
// is, the tail behind it
procedure TSparkField.DrawSpark(const ABrush: TSparkBrush;
  const ASpark: TSpark; const AOrigin: TSdlFPoint; AAlpha: Single);
var
  Dest: TSdlFRect;
begin
  var Share: Single := (ASpark.Age + AAlpha) / ASpark.Life;
  if Share > 1 then
    Share := 1;
  var Level: Single := FLook.Level * (1 - Share * Share);
  var HeadX: Single := AOrigin.X + ASpark.X + ASpark.SpeedX * AAlpha;
  var HeadY: Single := AOrigin.Y + ASpark.Y + ASpark.SpeedY * AAlpha;
  var Speed: Single := Hypot(ASpark.SpeedX, ASpark.SpeedY);
  var StreakLength: Single := Speed * FLook.StreakTicks + ASpark.Width;

  Dest.X := HeadX - ASpark.SpeedX * FLook.StreakTicks / 2 - StreakLength / 2;
  Dest.Y := HeadY - ASpark.SpeedY * FLook.StreakTicks / 2 - ASpark.Width / 2;
  Dest.W := StreakLength;
  Dest.H := ASpark.Width;
  var Color := HeatColor(FLook.Heat, Share);
  SDL_SetTextureColorMod(ABrush.Streak, Color.R, Color.G, Color.B);
  SDL_SetTextureAlphaMod(ABrush.Streak, Round(255 * Level));
  SDL_RenderCopyExF(ABrush.Renderer, ABrush.Streak, nil, @Dest,
    RadToDeg(ArcTan2(ASpark.SpeedY, ASpark.SpeedX)), nil, SdlFlipNone);
end;

procedure TSparkField.Draw(const ABrush: TSparkBrush;
  const AOrigin: TSdlFPoint; AAlpha: Single);
begin
  for var i := 0 to FCount - 1 do
    DrawSpark(ABrush, FSparks[i], AOrigin, AAlpha);
end;

procedure TSparkField.Clear;
begin
  FCount := 0;
end;

end.
