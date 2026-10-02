{
  Effects.Sparks - sparks: short hot streaks that fly from a point, fall,
  slow in the air, cool from white heat to a dull red and are gone in a
  blink.

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

  TSparkWall = (swPass, swDie);

  // Speeds in units per tick, lives in ticks, sizes in units
  TSparkLook = record
    Gravity: Single; // added to the fall every tick
    AirKeep: Single; // of the speed, per tick
    LifeMin, LifeMax: Single;
    Width: Single; // the streak across
    StreakTicks: Single; // the streak is the path of this many ticks
    HotColor, CoolColor: TRgb;
    Wall: TSparkWall;
  end;

  TSparkSpray = record
    Count: Integer;
    Heading: Single; // degrees counterclockwise from the right, 90 = up
    Cone: Single; // degrees wide, centered on the heading
    SlowSpeed, FastSpeed: Single;
  end;

  // The streak is a glow texture (Render.Glow)
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
    end;
  private
    FLook: TSparkLook;
    FSolid: TSolidProbe;
    FSparks: TArray<TSpark>;
    FCount: Integer;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function Roll(AFrom, ATo: Single): Single;
    procedure Add(const ASpark: TSpark);
    procedure MoveSpark(var ASpark: TSpark);
    procedure DrawSpark(const ABrush: TSparkBrush; const ASpark: TSpark;
      const AOrigin: TSdlFPoint; AAlpha: Single);
  public
    // ASolid may be nil for sparks that pass through walls. A field past
    // ACapacity drops its oldest sparks.
    constructor Create(const ALook: TSparkLook; const ASolid: TSolidProbe;
      ACapacity: Integer; ASeed: Cardinal);
    procedure Spray(AX, AY: Single; const ASpray: TSparkSpray);
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

function SparkBrush(ARenderer: PSdlRenderer; AStreak: PSdlTexture): TSparkBrush;
begin
  Result.Renderer := ARenderer;
  Result.Streak := AStreak;
end;

constructor TSparkField.Create(const ALook: TSparkLook;
  const ASolid: TSolidProbe; ACapacity: Integer; ASeed: Cardinal);
begin
  inherited Create;
  FLook := ALook;
  FSolid := ASolid;
  SetLength(FSparks, ACapacity);
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
    var Speed := Roll(ASpray.SlowSpeed, ASpray.FastSpeed);
    // Counterclockwise on paper, and the screen's Y runs down
    Spark.SpeedX := Cos(Heading) * Speed;
    Spark.SpeedY := -Sin(Heading) * Speed;
    Spark.Life := Max(1, Round(Roll(FLook.LifeMin, FLook.LifeMax)));
    Add(Spark);
  end;
end;

procedure TSparkField.MoveSpark(var ASpark: TSpark);
begin
  Inc(ASpark.Age);
  ASpark.SpeedX := ASpark.SpeedX * FLook.AirKeep;
  ASpark.SpeedY := ASpark.SpeedY * FLook.AirKeep + FLook.Gravity;
  var NextX := ASpark.X + ASpark.SpeedX;
  var NextY := ASpark.Y + ASpark.SpeedY;
  if (FLook.Wall = swDie) and FSolid(NextX, NextY) then
  begin
    ASpark.Age := ASpark.Life;
    Exit;
  end;
  ASpark.X := NextX;
  ASpark.Y := NextY;
end;

procedure TSparkField.Tick;
begin
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
  var Level: Single := 1 - Share * Share;
  var HeadX: Single := AOrigin.X + ASpark.X + ASpark.SpeedX * AAlpha;
  var HeadY: Single := AOrigin.Y + ASpark.Y + ASpark.SpeedY * AAlpha;
  var Speed: Single := Hypot(ASpark.SpeedX, ASpark.SpeedY);
  var StreakLength: Single := Speed * FLook.StreakTicks + FLook.Width;

  Dest.X := HeadX - ASpark.SpeedX * FLook.StreakTicks / 2 - StreakLength / 2;
  Dest.Y := HeadY - ASpark.SpeedY * FLook.StreakTicks / 2 - FLook.Width / 2;
  Dest.W := StreakLength;
  Dest.H := FLook.Width;
  var Color := Mix(FLook.HotColor, FLook.CoolColor, Share);
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
