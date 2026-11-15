{
  Menu.Globe - a body of the menu's sky as a slowly spinning globe
  (Render.Globe): the moon of the menu, or the Earth of level 1 in its
  place on the menu the titles end on. The sun stands still; the surface
  turns under it, so the terminator stays and the ground slides into the
  night. The moon's sun is in front of the viewer, a little up and to the
  left, its night side keeping a trace of earthshine; the Earth's comes
  from the left, so half of her is in the night and her cities show.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Menu.Globe;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Sprites.Sets, Render.Globe;

type
  // A body of the menu's sky: its maps, how it looks, where its sun stands
  // (view space, x right, y up, z toward the viewer; normalized by the
  // globe) and the meridian it faces at first
  TMenuBody = record
    MapName, NightMapName: string;
    Look: TGlobeLook;
    SunX, SunY, SunZ: Double;
    FacesLongitude: Double;
  end;

  TMenuGlobe = class
  private
    FGlobe: TGlobe;
    FSpinStep: Integer;
    // A body with air draws its halo past the disc
    FHaloed: Boolean;
  public
    constructor Create(ARenderer: PSdlRenderer; const ASpriteSet: TSpriteSet;
      const ABody: TMenuBody);
    destructor Destroy; override;
    procedure Tick;
    // ADest is a square in game units; the disc fills it, its halo past it
    procedure Draw(const ADest: TSdlFRect);
  end;

// The moon of the menu from the map AMapName
function MoonBody(const AMapName: string): TMenuBody;
// The Earth of level 1 from its maps
function EarthBody(const AMapName, ANightMapName: string): TMenuBody;

implementation

uses
  Render.Brush;

const
  MoonLook: TGlobeLook = (
    Side: 512;
    Surface: gsRegolith;
    // The axis leans and tips, so a little of the north pole shows and
    // the spin reads as a globe and not as a scrolling picture
    AxisRoll: 18.0;
    AxisTip: 12.0;
    // The night side under earthshine, slightly blue
    Ambient: (0.035, 0.042, 0.056);
    // The cool tone of the 2008 moon, gently
    Tint: (0.93, 0.99, 1.08);
    Exposure: 1.7;
    // Lunar regolith reflects almost equally to the limb; this power
    // fades the outermost limb a touch so the ball reads round
    LimbFade: 0.12;
    Atmosphere: 0;
    AirColor: (0, 0, 0);
    NightGain: 0);

  // The globe of level 1's sky (Levels.Dynamics, the "earth" object of
  // level1.json: tilt -20, air 60, city lights at their standard glow),
  // as many texels as the menu's moon
  EarthLook: TGlobeLook = (
    Side: 512;
    Surface: gsMatte;
    AxisRoll: -20.0;
    AxisTip: 12.0;
    Ambient: (0.006, 0.007, 0.010);
    Tint: (1, 1, 1);
    Exposure: 1.7;
    LimbFade: 0;
    Atmosphere: 0.6;
    AirColor: (0.32, 0.55, 1.0);
    NightGain: 2.5);
  // The meridian level 1's Earth faces the Moon with
  EarthLongitude = 45.0;

  // One turn in this many logic ticks (80 s at the 2008 timer rate)
  SpinTicksPerTurn = 2640;

  TurnUnits = 4294967296.0; // 2^32

function MoonBody(const AMapName: string): TMenuBody;
begin
  Result := Default(TMenuBody);
  Result.MapName := AMapName;
  Result.Look := MoonLook;
  // Mostly frontal, up and to the left, so the terminator sits on the
  // lower right and the disc reads as nearly full
  Result.SunX := -0.50;
  Result.SunY := 0.32;
  Result.SunZ := 0.80;
end;

function EarthBody(const AMapName, ANightMapName: string): TMenuBody;
begin
  Result := Default(TMenuBody);
  Result.MapName := AMapName;
  Result.NightMapName := ANightMapName;
  Result.Look := EarthLook;
  // From the left and a little up: the right half in the night
  Result.SunX := -0.95;
  Result.SunY := 0.25;
  Result.SunZ := 0.18;
  Result.FacesLongitude := EarthLongitude;
end;

constructor TMenuGlobe.Create(ARenderer: PSdlRenderer;
  const ASpriteSet: TSpriteSet; const ABody: TMenuBody);
begin
  inherited Create;
  FGlobe := TGlobe.Create(ARenderer, ASpriteSet, ABody.MapName,
    ABody.NightMapName, ABody.Look);
  if ABody.FacesLongitude <> 0 then
    FGlobe.Face(ABody.FacesLongitude);
  FGlobe.LightFrom(ABody.SunX, ABody.SunY, ABody.SunZ);
  FSpinStep := Round(TurnUnits / SpinTicksPerTurn);
  FHaloed := ABody.Look.Atmosphere > 0;
end;

destructor TMenuGlobe.Destroy;
begin
  FGlobe.Free;
  inherited;
end;

// Longitude runs the other way from the spin so that the surface
// travels left to right across the face, as a prograde globe does
procedure TMenuGlobe.Tick;
begin
  FGlobe.Spin(-FSpinStep);
end;

procedure TMenuGlobe.Draw(const ADest: TSdlFRect);
begin
  if not FHaloed then
  begin
    FGlobe.Draw(ADest, White, 1);
    Exit;
  end;
  var Dest := FGlobe.DestFor(ADest.X + ADest.W / 2, ADest.Y + ADest.H / 2, ADest.W);
  FGlobe.Draw(Dest, White, 1);
end;

end.
