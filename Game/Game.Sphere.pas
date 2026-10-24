{
  Game.Sphere - the life sphere: a pickup of 200% that a level forms where
  it says (Levels.Events, action sphere). Green sparks spiral in and the
  sphere grows out of them; whole, it breathes and sways; touched, it
  bursts, its sparks fly into the hero along curves and light his body,
  and his health fills to ten a pip at a time.

  Not a monster: it has no art, no def and no place in the field, so the
  field's conditions do not see it - the level waits for it with
  sphereTaken. It stays on the screen it formed on until it is taken, so
  a hero who walks off and comes back finds it there.

  Two classes, two reasons to change:
  - TLifeSphere counts: the phase, the sparks, the clock of the fill. It
    touches no SDL; the game reads the pips it is due and gives them.
  - TLifeSpherePainter draws it with the shapes of the dynamics' canvas -
    a disc, points of light, a flare. No texture of its own.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Sphere;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Levels.Dynamics, Game.Uptake;

const
  // The health the sphere fills to: 200% of the norm of five
  SphereHealth = 10;
  // The fill gives a pip every this many ticks, the first in the tick of
  // the touch
  PipEvery = 4;

type
  // spBurst: taken, the sparks on their way into the hero; spDone: all of
  // them in, only the flash on him left
  TSpherePhase = (spNone, spForming, spWhole, spBurst, spDone);

  // Ticks and screen units. A forming spark spirals from Angle and Reach
  // round the middle into it; a burst spark flies out of the middle by the
  // bend and into the point Aim of the hero's body, from his middle.
  TSphereSpark = record
    Angle, Reach: Single;
    BendX, BendY: Single;
    AimX, AimY: Single;
    Delay, Ticks: Integer;
    X, Y, LastX, LastY: Single;
    Home: Boolean;
  end;

  TLifeSphere = class
  private
    FFeed: TFeedLight;
    FDice: TXorShift;
    FPhase: TSpherePhase;
    FScreen: Integer;
    FX, FY: Single; // the middle
    FSize: Single;
    FAge: Integer; // in the phase
    FClock: Integer;
    FSparks: TArray<TSphereSpark>;
    FHome: Integer;
    FDropped: Boolean;
    FFilling: Boolean;
    FFillAge: Integer;
    procedure SeedFormingSparks;
    procedure SeedBurstSparks;
    procedure TickBurst(const AHeroMiddle: TSdlFPoint);
    procedure FlySpark(var ASpark: TSphereSpark; const AHeroMiddle: TSdlFPoint);
    function SparkShare: Single;
    function FeedKeep: Single;
  public
    constructor Create(const AFeed: TFeedLight; ASeed: Cardinal);
    // Forms the sphere anew, whatever it was: AX, AY its middle in screen
    // units
    procedure Form(AScreen: Integer; AX, AY, ASize: Single);
    procedure Tick(const AHeroMiddle: TSdlFPoint);
    // Only a whole sphere is touched: while it forms, it is not there yet
    function Touches(const ABody: TSdlFRect; AScreen: Integer): Boolean;
    procedure Take;
    // A pip of health is due this tick; the game caps it at SphereHealth
    function PipDue: Boolean;
    // A door: the sparks on their way are in at once, with all their light.
    // The pips still due are the game's to give, while Filling says so.
    procedure Settle;
    // The hero is dead: the sparks fade where they are, the fill stops
    procedure Drop;
    procedure Clear;
    function Taken: Boolean;
    property Phase: TSpherePhase read FPhase;
    property Screen: Integer read FScreen;
    property X: Single read FX;
    property Y: Single read FY;
    property Size: Single read FSize;
    property Age: Integer read FAge;
    property Clock: Integer read FClock;
    property Sparks: TArray<TSphereSpark> read FSparks;
    property Dropped: Boolean read FDropped;
    property Filling: Boolean read FFilling;
  end;

  TLifeSpherePainter = class
  private
    FSphere: TLifeSphere;
    procedure DrawBody(const ACanvas: TDynamicCanvas; ACenterX, ACenterY,
      AScale, ALevel, ATime: Single);
    procedure DrawBands(const ACanvas: TDynamicCanvas; ACenterX, ACenterY,
      ADiameter, ALevel, ATime: Single);
    procedure DrawOrbiters(const ACanvas: TDynamicCanvas; ACenterX, ACenterY,
      ADiameter, ALevel, ATime: Single; AFront: Boolean);
    procedure DrawSpark(const ACanvas: TDynamicCanvas; AX, AY, ALevel: Single);
    procedure DrawForming(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawWhole(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawBurstSparks(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawBurstFlash(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      ATime: Single);
  public
    constructor Create(const ASphere: TLifeSphere);
    // With the pickups, on the monsters' shake: the sphere, the sparks it
    // forms from and the flash it bursts in
    procedure DrawSphere(const ACanvas: TDynamicCanvas; AScreen: Integer;
      AOrigin: TSdlPoint; AAlpha: Single);
    // Over the hero: the sparks flying into him and the flash on him;
    // AHeroMiddle in screen units
    procedure DrawOver(const ACanvas: TDynamicCanvas;
      const AHeroMiddle: TSdlFPoint; AOrigin: TSdlPoint; AAlpha: Single);
  end;

// Where a forming spark is at ATime ticks of the forming, in units from the
// middle; False before it sets off and once it is in
function FormingSparkAt(const ASpark: TSphereSpark; ATime: Single;
  out APoint: TSdlFPoint): Boolean;

implementation

uses
  System.Math, Render.Glow;

const
  // The forming, 1.6 seconds: the sparks set off within the first
  // FormStagger ticks and come in from FormArriveFirst on; the sphere grows
  // from GrowFrom to the end and flashes as it comes whole
  FormTicks = 53;
  FormSparks = 26;
  FormReachMin = 40;
  FormReachMax = 100;
  FormStagger = 12;
  FormArriveFirst = 30;
  FormTurns = 1.25;
  GrowFrom = 30;
  FormFlashTicks = 8;
  FormFlashGrowth = 4; // of the diameter

  // The burst: the sphere flashes and swells over BurstFlashTicks, its
  // sparks fly out within BurstStagger ticks and spend BurstFlightMin to
  // BurstFlightMax ticks on their way; the hero flashes once all are in
  BurstFlashTicks = 5;
  BurstSwell = 0.6;
  BurstSparks = 26;
  BurstStagger = 4;
  BurstFlightMin = 16;
  BurstFlightMax = 24;
  BurstBendMin = 18;
  BurstBendMax = 40;
  BurstLift = 12; // the curves rise before they fall onto him
  AimSpreadX = 12;
  AimSpreadY = 20;
  HomeFlashTicks = 8;
  HomeFlashSize = 48;
  HomeFlashLevel = 0.8;
  DropTicks = 10;

  // The light on the body: the sparks of a sphere give 2 * SpherePulse in
  // all, as the uptake's crumbs do, and it is all but gone in
  // SpherePulseTicks
  SpherePulse = 0.9;
  SpherePulseTicks = 20;

  // The most the fill gives: from a single point of health to ten
  FillPips = SphereHealth - 1;

  // The look of the whole sphere
  BreathDepth = 0.08;
  BreathPeriod = 50;
  SwayReach = 1.5;
  SwayPeriod = 132;
  HaloGrowth = 3;
  HaloLevel = 0.35;
  CoreGrowth = 1.1;
  CoreLevel = 0.8;
  GlintShift = 0.22;
  GlintGrowth = 0.45;
  GlintLevel = 0.7;
  BodyShade: TRgb = (R: 24; G: 96; B: 32);

  BandCount = 3;
  BandDots = 10;
  BandReach = 0.38;
  BandFlat = 0.35;
  BandDotGrowth = 0.16;
  BandFrontLevel = 0.55;
  BandBackLevel = 0.15;
  BandWhite = 0.5;
  BandPeriods: array [0..BandCount - 1] of Integer = (40, 55, 70);
  BandTilts: array [0..BandCount - 1] of Single = (0, 60, 120); // degrees

  OrbiterCount = 2;
  OrbiterReach = 0.8;
  OrbiterFlat = 0.3;
  OrbiterTilt = -20; // degrees
  OrbiterPeriod = 45;
  OrbiterGrowth = 0.35;
  OrbiterCoreGrowth = 0.15;
  OrbiterLevel = 0.6;

  SparkSpotSize = 5;
  SparkCoreSize = 2;
  SparkSpotLevel = 0.7;
  SparkWhite = 0.6;
  SparkFadeIn = 0.2; // of a forming spark's way

function Clamp01(AValue: Single): Single;
begin
  Result := Min(Max(AValue, Single(0)), Single(1));
end;

function EaseOut(AShare: Single): Single;
begin
  Result := 1 - Sqr(1 - AShare);
end;

function FormingSparkAt(const ASpark: TSphereSpark; ATime: Single;
  out APoint: TSdlFPoint): Boolean;
begin
  var Share := (ATime - ASpark.Delay) / ASpark.Ticks;
  Result := (Share >= 0) and (Share < 1);
  if not Result then
    Exit;
  var Way := EaseOut(Share);
  var Reach := ASpark.Reach * (1 - Way);
  var Angle := ASpark.Angle + 2 * Pi * FormTurns * Way;
  APoint.X := Cos(Angle) * Reach;
  APoint.Y := Sin(Angle) * Reach;
end;

{ TLifeSphere }

constructor TLifeSphere.Create(const AFeed: TFeedLight; ASeed: Cardinal);
begin
  inherited Create;
  FFeed := AFeed;
  FDice.Seed := ASeed or 1;
end;

procedure TLifeSphere.Form(AScreen: Integer; AX, AY, ASize: Single);
begin
  FPhase := spForming;
  FScreen := AScreen;
  FX := AX;
  FY := AY;
  FSize := ASize;
  FAge := 0;
  FHome := 0;
  FDropped := False;
  SeedFormingSparks;
end;

// The dice in this order for every spark: where it starts, how far out,
// when it sets off, when it is in
procedure TLifeSphere.SeedFormingSparks;
begin
  SetLength(FSparks, FormSparks);
  for var i := 0 to High(FSparks) do
  begin
    var Spark := Default(TSphereSpark);
    Spark.Angle := FDice.NextUnit * 2 * Pi;
    Spark.Reach := FormReachMin + FDice.NextUnit * (FormReachMax - FormReachMin);
    Spark.Delay := Trunc(FDice.NextUnit * FormStagger);
    var Arrive := FormArriveFirst + FDice.NextUnit * (FormTicks - FormArriveFirst);
    Spark.Ticks := Max(Round(Arrive) - Spark.Delay, 1);
    FSparks[i] := Spark;
  end;
end;

// The dice in this order for every spark: the way of its bend, how far
// out, the point of the body, when it sets off, how long it flies
procedure TLifeSphere.SeedBurstSparks;
begin
  SetLength(FSparks, BurstSparks);
  for var i := 0 to High(FSparks) do
  begin
    var Spark := Default(TSphereSpark);
    var Angle := FDice.NextUnit * 2 * Pi;
    var Bend := BurstBendMin + FDice.NextUnit * (BurstBendMax - BurstBendMin);
    Spark.BendX := Cos(Angle) * Bend;
    Spark.BendY := Sin(Angle) * Bend - BurstLift;
    Spark.AimX := (FDice.NextUnit - 0.5) * AimSpreadX;
    Spark.AimY := (FDice.NextUnit - 0.5) * AimSpreadY;
    Spark.Delay := Trunc(FDice.NextUnit * BurstStagger);
    Spark.Ticks := BurstFlightMin +
      Trunc(FDice.NextUnit * (BurstFlightMax - BurstFlightMin + 1));
    Spark.X := FX;
    Spark.Y := FY;
    Spark.LastX := FX;
    Spark.LastY := FY;
    FSparks[i] := Spark;
  end;
end;

procedure TLifeSphere.Tick(const AHeroMiddle: TSdlFPoint);
begin
  Inc(FClock);
  if FFilling then
  begin
    Inc(FFillAge);
    if FFillAge >= FillPips * PipEvery then
      FFilling := False;
  end;
  if FPhase = spNone then
    Exit;

  Inc(FAge);
  case FPhase of
    spForming:
      if FAge >= FormTicks then
      begin
        FPhase := spWhole;
        FAge := 0;
      end;
    spBurst:
      TickBurst(AHeroMiddle);
  end;
end;

procedure TLifeSphere.TickBurst(const AHeroMiddle: TSdlFPoint);
begin
  if FDropped then
  begin
    if FAge >= DropTicks then
    begin
      FPhase := spDone;
      FAge := HomeFlashTicks;
    end;
    Exit;
  end;

  for var i := 0 to High(FSparks) do
    if not FSparks[i].Home then
      FlySpark(FSparks[i], AHeroMiddle);
  if FHome < Length(FSparks) then
    Exit;
  FPhase := spDone;
  FAge := 0;
end;

// Along a curve whose end is the hero as he stands this tick: the one who
// runs is caught all the same
procedure TLifeSphere.FlySpark(var ASpark: TSphereSpark;
  const AHeroMiddle: TSdlFPoint);
begin
  ASpark.LastX := ASpark.X;
  ASpark.LastY := ASpark.Y;
  var Share := (FAge - ASpark.Delay) / ASpark.Ticks;
  if Share <= 0 then
    Exit;
  var EndX := AHeroMiddle.X + ASpark.AimX;
  var EndY := AHeroMiddle.Y + ASpark.AimY;
  if Share >= 1 then
  begin
    ASpark.X := EndX;
    ASpark.Y := EndY;
    ASpark.Home := True;
    Inc(FHome);
    FFeed(BonusColor, SparkShare, FeedKeep);
    Exit;
  end;

  // Slow out of the sphere, fast into him
  var Way := Sqr(Share);
  var Rest := 1 - Way;
  ASpark.X := Rest * Rest * FX + 2 * Rest * Way * (FX + ASpark.BendX) +
    Way * Way * EndX;
  ASpark.Y := Rest * Rest * FY + 2 * Rest * Way * (FY + ASpark.BendY) +
    Way * Way * EndY;
end;

function TLifeSphere.SparkShare: Single;
begin
  Result := 2 * SpherePulse / BurstSparks;
end;

function TLifeSphere.FeedKeep: Single;
begin
  Result := Exp(-3 / SpherePulseTicks);
end;

function TLifeSphere.Touches(const ABody: TSdlFRect; AScreen: Integer): Boolean;
begin
  if (FPhase <> spWhole) or (AScreen <> FScreen) then
    Exit(False);
  var Half := FSize / 2;
  Result := (ABody.X < FX + Half) and (ABody.X + ABody.W > FX - Half) and
    (ABody.Y < FY + Half) and (ABody.Y + ABody.H > FY - Half);
end;

procedure TLifeSphere.Take;
begin
  if FPhase <> spWhole then
    Exit;
  FPhase := spBurst;
  FAge := 0;
  FHome := 0;
  FDropped := False;
  FFilling := True;
  FFillAge := 0;
  SeedBurstSparks;
end;

function TLifeSphere.PipDue: Boolean;
begin
  Result := FFilling and (FFillAge mod PipEvery = 0);
end;

procedure TLifeSphere.Settle;
begin
  FFilling := False;
  if (FPhase <> spBurst) or FDropped then
    Exit;
  var Left := Length(FSparks) - FHome;
  if Left > 0 then
    FFeed(BonusColor, SparkShare * Left, FeedKeep);
  FHome := Length(FSparks);
  FPhase := spDone;
  FAge := HomeFlashTicks;
end;

procedure TLifeSphere.Drop;
begin
  FFilling := False;
  if (FPhase <> spBurst) or FDropped then
    Exit;
  FDropped := True;
  FAge := 0;
  for var i := 0 to High(FSparks) do
  begin
    FSparks[i].LastX := FSparks[i].X;
    FSparks[i].LastY := FSparks[i].Y;
  end;
end;

procedure TLifeSphere.Clear;
begin
  FPhase := spNone;
  FSparks := nil;
  FHome := 0;
  FAge := 0;
  FDropped := False;
  FFilling := False;
end;

function TLifeSphere.Taken: Boolean;
begin
  Result := FPhase in [spBurst, spDone];
end;

{ TLifeSpherePainter }

constructor TLifeSpherePainter.Create(const ASphere: TLifeSphere);
begin
  inherited Create;
  FSphere := ASphere;
end;

procedure TLifeSpherePainter.DrawSpark(const ACanvas: TDynamicCanvas;
  AX, AY, ALevel: Single);
begin
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, SparkSpotSize,
    BonusColor, SparkSpotLevel * ALevel);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, SparkCoreSize,
    Mix(BonusColor, White, SparkWhite), ALevel);
end;

// AScale - of the size, the breath on top; ALevel - how much of it is
// there; ATime - the sphere's clock, for the breath, the sway, the bands
procedure TLifeSpherePainter.DrawBody(const ACanvas: TDynamicCanvas;
  ACenterX, ACenterY, AScale, ALevel, ATime: Single);
begin
  var Breath := 1 + BreathDepth / 2 * Sin(2 * Pi * ATime / BreathPeriod);
  var Diameter := FSphere.Size * AScale * Breath;
  var CenterY := ACenterY + SwayReach * Sin(2 * Pi * ATime / SwayPeriod);

  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, ACenterX, CenterY,
    HaloGrowth * Diameter, BonusColor, HaloLevel * Breath * ALevel);
  DrawOrbiters(ACanvas, ACenterX, CenterY, Diameter, ALevel, ATime, False);
  DrawGlow(ACanvas.Renderer, ACanvas.DiscShade, ACenterX, CenterY, Diameter,
    BodyShade, ALevel);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, ACenterX, CenterY,
    CoreGrowth * Diameter, BonusColor, CoreLevel * ALevel);
  DrawBands(ACanvas, ACenterX, CenterY, Diameter, ALevel, ATime);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow,
    ACenterX - GlintShift * Diameter, CenterY - GlintShift * Diameter,
    GlintGrowth * Diameter, White, GlintLevel * ALevel);
  DrawOrbiters(ACanvas, ACenterX, CenterY, Diameter, ALevel, ATime, True);
end;

// Rings of light turning inside the body, each a circle seen at a slant:
// the half that faces us bright, the half behind it dim
procedure TLifeSpherePainter.DrawBands(const ACanvas: TDynamicCanvas;
  ACenterX, ACenterY, ADiameter, ALevel, ATime: Single);
begin
  var Reach := BandReach * ADiameter;
  var Tint := Mix(BonusColor, White, BandWhite);
  for var Band := 0 to BandCount - 1 do
  begin
    var Turn := 2 * Pi * ATime / BandPeriods[Band];
    var Tilt := DegToRad(BandTilts[Band]);
    for var Dot := 0 to BandDots - 1 do
    begin
      var Angle := 2 * Pi * Dot / BandDots + Turn;
      var Along := Cos(Angle) * Reach;
      var Across := Sin(Angle) * Reach * BandFlat;
      var Level := BandBackLevel;
      if Sin(Angle) > 0 then
        Level := BandFrontLevel;
      DrawGlow(ACanvas.Renderer, ACanvas.PointGlow,
        ACenterX + Along * Cos(Tilt) - Across * Sin(Tilt),
        ACenterY + Along * Sin(Tilt) + Across * Cos(Tilt),
        BandDotGrowth * ADiameter, Tint, Level * ALevel);
    end;
  end;
end;

// Two sparks circling the sphere: the half of the way behind it is drawn
// before the body, the half in front after it
procedure TLifeSpherePainter.DrawOrbiters(const ACanvas: TDynamicCanvas;
  ACenterX, ACenterY, ADiameter, ALevel, ATime: Single; AFront: Boolean);
begin
  var Reach := OrbiterReach * ADiameter;
  var Tilt := DegToRad(OrbiterTilt);
  for var i := 0 to OrbiterCount - 1 do
  begin
    var Angle := 2 * Pi * (ATime / OrbiterPeriod + i / OrbiterCount);
    if (Sin(Angle) > 0) <> AFront then
      Continue;
    var Along := Cos(Angle) * Reach;
    var Across := Sin(Angle) * Reach * OrbiterFlat;
    var X := ACenterX + Along * Cos(Tilt) - Across * Sin(Tilt);
    var Y := ACenterY + Along * Sin(Tilt) + Across * Cos(Tilt);
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X, Y,
      OrbiterGrowth * ADiameter, BonusColor, OrbiterLevel * ALevel);
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X, Y,
      OrbiterCoreGrowth * ADiameter, Mix(BonusColor, White, SparkWhite),
      ALevel);
  end;
end;

procedure TLifeSpherePainter.DrawForming(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Time := FSphere.Age + AAlpha;
  var CenterX := FSphere.X + AOrigin.X;
  var CenterY := FSphere.Y + AOrigin.Y;
  if Time > GrowFrom then
  begin
    var Grown := EaseOut(Clamp01((Time - GrowFrom) / (FormTicks - GrowFrom)));
    DrawBody(ACanvas, CenterX, CenterY, Grown, Grown, FSphere.Clock + AAlpha);
  end;
  for var Spark in FSphere.Sparks do
  begin
    var Point: TSdlFPoint;
    if not FormingSparkAt(Spark, Time, Point) then
      Continue;
    var Share := (Time - Spark.Delay) / Spark.Ticks;
    DrawSpark(ACanvas, CenterX + Point.X, CenterY + Point.Y,
      Clamp01(Share / SparkFadeIn));
  end;
end;

procedure TLifeSpherePainter.DrawWhole(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Time := FSphere.Age + AAlpha;
  var CenterX := FSphere.X + AOrigin.X;
  var CenterY := FSphere.Y + AOrigin.Y;
  DrawBody(ACanvas, CenterX, CenterY, 1, 1, FSphere.Clock + AAlpha);
  if Time >= FormFlashTicks then
    Exit;
  DrawGlow(ACanvas.Renderer, ACanvas.FlareGlow, CenterX, CenterY,
    FormFlashGrowth * FSphere.Size, Mix(BonusColor, White, BandWhite),
    1 - Time / FormFlashTicks);
end;

// Between the ticks each spark goes on along the step it has just made
procedure TLifeSpherePainter.DrawBurstSparks(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Level: Single := 1;
  if FSphere.Dropped then
    Level := Clamp01(1 - (FSphere.Age + AAlpha) / DropTicks);
  for var Spark in FSphere.Sparks do
  begin
    if Spark.Home or (FSphere.Age <= Spark.Delay) then
      Continue;
    var X := Spark.LastX + (Spark.X - Spark.LastX) * AAlpha + AOrigin.X;
    var Y := Spark.LastY + (Spark.Y - Spark.LastY) * AAlpha + AOrigin.Y;
    DrawSpark(ACanvas, X, Y, Level);
  end;
end;

// The sphere swells white and is gone
procedure TLifeSpherePainter.DrawBurstFlash(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; ATime: Single);
begin
  if ATime >= BurstFlashTicks then
    Exit;
  var Share := ATime / BurstFlashTicks;
  var Diameter := FSphere.Size * (1 + BurstSwell * Share);
  var CenterX := FSphere.X + AOrigin.X;
  var CenterY := FSphere.Y + AOrigin.Y;
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    HaloGrowth * Diameter, BonusColor, HaloLevel * (1 - Share));
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    CoreGrowth * Diameter, Mix(BonusColor, White, BandWhite), 1 - Share);
end;

procedure TLifeSpherePainter.DrawSphere(const ACanvas: TDynamicCanvas;
  AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
begin
  if FSphere.Screen <> AScreen then
    Exit;
  case FSphere.Phase of
    spForming:
      DrawForming(ACanvas, AOrigin, AAlpha);
    spWhole:
      DrawWhole(ACanvas, AOrigin, AAlpha);
    spBurst:
      if not FSphere.Dropped then
        DrawBurstFlash(ACanvas, AOrigin, FSphere.Age + AAlpha);
  end;
end;

procedure TLifeSpherePainter.DrawOver(const ACanvas: TDynamicCanvas;
  const AHeroMiddle: TSdlFPoint; AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Time := FSphere.Age + AAlpha;
  case FSphere.Phase of
    spBurst:
      DrawBurstSparks(ACanvas, AOrigin, AAlpha);
    spDone:
      if Time < HomeFlashTicks then
        DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AHeroMiddle.X + AOrigin.X,
          AHeroMiddle.Y + AOrigin.Y, HomeFlashSize, BonusColor,
          HomeFlashLevel * (1 - Time / HomeFlashTicks));
  end;
end;

end.
