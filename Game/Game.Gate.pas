{
  Game.Gate - the sealed door of the arena given a body: a facade with a
  gate on the tiles of the road come back at the end of the flight
  (Game.Road), part of the picture the titles stand on. A decoration: it
  stops nothing and nothing touches it - the wall is the right edge of the
  screen, as before.

  It has no place of its own. It stands a fixed way along the road from the
  road's edge over the crater, so it rides in with the road and stops with
  it, its right side at the right edge of the screen. What is its own is
  the status lamp over the portal: red while the gate is sealed, amber once
  it is promised to open - "soon", not "never". The gate itself stays shut.

  The lamp's rules do not touch SDL; the picture and the lamp's light are
  the painter's below.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Gate;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Render.Sprites, Levels.Dynamics, Game.Road;

const
  // The facade's picture in the set is 720 by 659 px at 6 px a unit
  GateWidth = 120.0;
  GateHeight = 659 / 6;
  // The lamp turns from red to amber over half a second
  GateLampTurnTicks = 16;

type
  // glSealed - red; glSoon - amber: it will open
  TGateLamp = (glSealed, glSoon);

  TGate = class
  private
    FLamp: TGateLamp;
    FTurnTicks, FLastTurnTicks: Integer;
  public
    // The gate will open: the lamp turns amber. Nothing once promised
    procedure Promise;
    // A death, a new level: sealed again, the lamp red at once
    procedure Clear;
    procedure Tick;
    // How far the lamp has turned, 0 red .. 1 amber, AAlpha of the way
    // from the last tick to this one
    function LampTurn(AAlpha: Single): Single;
    property Lamp: TGateLamp read FLamp;
  end;

  // The facade on the road come back, put in the night, and the lamp's
  // light over its unlit housing. Owns nothing.
  TGatePainter = class
  private
    FTexture: PSdlTexture;
    FGate: TGate;
    FRoad: TRoadEnd;
  public
    constructor Create(ATexture: PSdlTexture; AGate: TGate; ARoad: TRoadEnd);
    // AFoot - the road's line, where the facade stands
    procedure Draw(ASprites: TSpriteRenderer; const ACanvas: TDynamicCanvas;
      AFoot: Double; AAlpha: Single);
  end;

// The facade's left side, the road's edge over the crater at ARoadLeft
function GateLeft(ARoadLeft: Double): Double;
// The lamp's color ATurn (0..1) of the way from red to amber
function GateLampColor(ATurn: Single): TRgb;

implementation

uses
  Game.Space, Game.Landing;

const
  // The road stopped, the facade ends at the right edge of the screen
  GateRoadOffset = ScreenWidth - LandingRoadStop - GateWidth;
  LampRed: TRgb = (R: 255; G: 60; B: 48);
  LampAmber: TRgb = (R: 255; G: 176; B: 64);

function GateLeft(ARoadLeft: Double): Double;
begin
  Result := ARoadLeft + GateRoadOffset;
end;

function GateLampColor(ATurn: Single): TRgb;
begin
  Result := Mix(LampRed, LampAmber, ATurn);
end;

// ---------------------------------------------------------------------------
// TGate
// ---------------------------------------------------------------------------

procedure TGate.Promise;
begin
  FLamp := glSoon;
end;

procedure TGate.Clear;
begin
  FLamp := glSealed;
  FTurnTicks := 0;
  FLastTurnTicks := 0;
end;

procedure TGate.Tick;
begin
  FLastTurnTicks := FTurnTicks;
  if (FLamp = glSoon) and (FTurnTicks < GateLampTurnTicks) then
    Inc(FTurnTicks);
end;

function TGate.LampTurn(AAlpha: Single): Single;
begin
  var Ticks := FLastTurnTicks + (FTurnTicks - FLastTurnTicks) * AAlpha;
  Result := Ticks / GateLampTurnTicks;
end;

// ---------------------------------------------------------------------------
// TGatePainter
// ---------------------------------------------------------------------------

constructor TGatePainter.Create(ATexture: PSdlTexture; AGate: TGate;
  ARoad: TRoadEnd);
const
  // The picture is front-lit; the sun of the crater stands behind it
  NightShadePercent = 35;
begin
  inherited Create;
  FTexture := ATexture;
  FGate := AGate;
  FRoad := ARoad;
  TintTexture(FTexture, NightShadePercent, NightShadePercent,
    NightShadePercent);
end;

procedure TGatePainter.Draw(ASprites: TSpriteRenderer;
  const ACanvas: TDynamicCanvas; AFoot: Double; AAlpha: Single);
const
  // The middle of the lamp housing, units from the picture's top-left
  LampX = 69.7;
  LampY = 47.3;
  LampSize = 16.0;
  LampLight = 1.0;
  // A lamp that does not blink is one long flash
  LampSteady = 1.0;
var
  Dest: TSdlFRect;
begin
  if not FRoad.Arrived then
    Exit;
  Dest.X := GateLeft(FRoad.LeftAt(AAlpha));
  if Dest.X >= ScreenWidth then
    Exit;
  Dest.Y := AFoot - GateHeight;
  Dest.W := GateWidth;
  Dest.H := GateHeight;
  ASprites.DrawRectF(FTexture, Dest);

  var Color := GateLampColor(FGate.LampTurn(AAlpha));
  DrawLamp(ACanvas, Dest.X + LampX + ASprites.Origin.X,
    Dest.Y + LampY + ASprites.Origin.Y, LampSize, Color, LampLight,
    LampSteady);
end;

end.
