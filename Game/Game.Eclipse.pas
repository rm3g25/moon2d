{
  Game.Eclipse - the scene of the henshin from the brake of the Ram to
  the diamond ring: the clock it runs by and what it shows at each tick.

  The charge full, the game brakes the Ram and the road, and starts the
  clock. The road runs down for BeltRampTicks; with the world at rest the
  disc of the charge, up at the top centre, becomes the eclipsed sun: a
  corona flares round its rim and settles, and the world darkens under
  one overlay. Then the diamond ring: one bright point on the disc's edge,
  on the side of the hero, three blinks, and lit from the third on. From
  the start nothing wounds the hero.

  The clock knows neither the Ram nor the gauge: the game starts it,
  carries out its cues and reads its levels. TEclipsePainter draws the
  darkness; the corona and the diamond are the gauge's (Hud.Energy).

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Eclipse;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Hud.Energy, Game.Belt;

const
  LogicTicksPerSecond = 33;
  // The world at rest: the road has run down
  CoronaAt = BeltRampTicks;
  // The darkness comes in over this many ticks, the track fading out with it
  DarkTicks = 40;
  EclipseFadeSeconds = DarkTicks / LogicTicksPerSecond;
  DarkDepth = 0.85;
  // The dark is all but in
  DiamondAt = CoronaAt + 30;
  DiamondBlinks = 3;

type
  TEclipseCue = record
    // The corona flares: the darkness starts in, the track fades to silence
    Corona: Boolean;
    // The diamond ring begins: its point is to be set on the rim
    Diamond: Boolean;
  end;

  TEclipseScene = class
  private
    FRunning: Boolean;
    FTicks: Integer;
    FDiamondAngle: Single;
    function Clock(AAlpha: Single): Single;
  public
    // At the brake: the first tick of the scene is the next one
    procedure Start;
    procedure Clear;
    function Tick: TEclipseCue;
    // Where on the rim the diamond burns: radians on the screen, 0 to the
    // right, growing downward
    procedure AimDiamond(AAngle: Single);
    // From the brake on: nothing wounds the hero
    function Spares: Boolean;
    // How dark the world is, 0 to DarkDepth, AAlpha ticks past this one
    function Darkness(AAlpha: Single): Single;
    // How bright the corona is, 0..1: a flare up to 1, then settled lower
    function Corona(AAlpha: Single): Single;
    // How far the disc is eclipsed, 0..1: its own light goes as the corona
    // flares
    function Covered(AAlpha: Single): Single;
    // The diamond, 0 dark or 1 lit, by whole ticks
    function Diamond: Single;
    // All of it as the gauge draws it
    function Gauge(AAlpha: Single): TGaugeEclipse;
    property Running: Boolean read FRunning;
  end;

  TEclipsePainter = class
  private
    FRenderer: PSdlRenderer;
    FEclipse: TEclipseScene;
  public
    // The eclipse belongs to the caller and must outlive the painter
    constructor Create(ARenderer: PSdlRenderer; AEclipse: TEclipseScene);
    // Over the far plane and the play layer, under the hero and the HUD
    procedure DrawDark(AAlpha: Single);
  end;

// The diamond's angle on the rim of a disc at ADisc toward AHero
function DiamondAngleToward(const ADisc, AHero: TSdlFPoint): Single;

implementation

uses
  System.Math, Render.Brush;

const
  CoronaFlareTicks = 10;
  CoronaSettleTicks = 25;
  CoronaHold = 0.55;
  DiamondOnTicks = 6;
  DiamondOffTicks = 5;
  // Deep night with a little of the moon's violet in it
  DarkTint: TRgb = (R: 6; G: 4; B: 16);
  WholeFrame: PSdlFRect = nil;
  DarkVisible = 1 / 255;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0, 1);
  Result := Share * Share * (3 - 2 * Share);
end;

function DiamondAngleToward(const ADisc, AHero: TSdlFPoint): Single;
begin
  Result := ArcTan2(AHero.Y - ADisc.Y, AHero.X - ADisc.X);
end;

{ TEclipseScene }

procedure TEclipseScene.Start;
begin
  FRunning := True;
  FTicks := 0;
  FDiamondAngle := Pi / 2;
end;

procedure TEclipseScene.Clear;
begin
  FRunning := False;
  FTicks := 0;
end;

function TEclipseScene.Tick: TEclipseCue;
begin
  Result := Default(TEclipseCue);
  if not FRunning then
    Exit;
  Inc(FTicks);
  Result.Corona := FTicks = CoronaAt;
  Result.Diamond := FTicks = DiamondAt;
end;

procedure TEclipseScene.AimDiamond(AAngle: Single);
begin
  FDiamondAngle := AAngle;
end;

function TEclipseScene.Spares: Boolean;
begin
  Result := FRunning;
end;

function TEclipseScene.Clock(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  Result := FTicks + AAlpha;
end;

function TEclipseScene.Darkness(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  Result := DarkDepth * SmoothStep((Clock(AAlpha) - CoronaAt) / DarkTicks);
end;

function TEclipseScene.Corona(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  var Since := Clock(AAlpha) - CoronaAt;
  if Since <= 0 then
    Exit(0);
  if Since < CoronaFlareTicks then
    Exit(Sqrt(Since / CoronaFlareTicks));
  Result := 1 + (CoronaHold - 1) *
    SmoothStep((Since - CoronaFlareTicks) / CoronaSettleTicks);
end;

function TEclipseScene.Covered(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  Result := SmoothStep((Clock(AAlpha) - CoronaAt) / CoronaFlareTicks);
end;

// Lit, dark, lit, dark, lit - and lit from the third on
function TEclipseScene.Diamond: Single;
const
  BlinkTicks = DiamondOnTicks + DiamondOffTicks;
begin
  if not FRunning then
    Exit(0);
  var Since := FTicks - DiamondAt;
  if Since < 0 then
    Exit(0);
  if (Since >= (DiamondBlinks - 1) * BlinkTicks) or
    (Since mod BlinkTicks < DiamondOnTicks) then
    Result := 1
  else
    Result := 0;
end;

function TEclipseScene.Gauge(AAlpha: Single): TGaugeEclipse;
begin
  Result.Corona := Corona(AAlpha);
  Result.Covered := Covered(AAlpha);
  Result.Diamond := Diamond;
  Result.DiamondAngle := FDiamondAngle;
end;

{ TEclipsePainter }

constructor TEclipsePainter.Create(ARenderer: PSdlRenderer; AEclipse: TEclipseScene);
begin
  inherited Create;
  FRenderer := ARenderer;
  FEclipse := AEclipse;
end;

procedure TEclipsePainter.DrawDark(AAlpha: Single);
begin
  var Depth := FEclipse.Darkness(AAlpha);
  if Depth < DarkVisible then
    Exit;
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
  SDL_SetRenderDrawColor(FRenderer, DarkTint.R, DarkTint.G, DarkTint.B,
    Round(255 * Depth));
  SDL_RenderFillRectF(FRenderer, WholeFrame);
end;

end.
