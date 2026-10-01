{
  Menu.Globe - the moon of the menu as a slowly spinning globe
  (Render.Globe). The sun stands still in front of the viewer, a little
  up and to the left; the surface turns under it, so the terminator
  stays and the ground slides into the night. The night side keeps a
  trace of earthshine.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Menu.Globe;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Sprites.Sets, Render.Globe;

type
  TMoonGlobe = class
  private
    FGlobe: TGlobe;
    FSpinStep: Integer;
  public
    constructor Create(ARenderer: PSdlRenderer; const ASpriteSet: TSpriteSet;
      const AMapName: string);
    destructor Destroy; override;
    procedure Tick;
    // ADest is a square in game units; the disc fills it
    procedure Draw(const ADest: TSdlFRect);
  end;

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

  // One turn in this many logic ticks (80 s at the 2008 timer rate)
  SpinTicksPerTurn = 2640;

  // The sun in view space (x right, y up, z toward the viewer), before
  // normalization: mostly frontal, up and to the left, so the terminator
  // sits on the lower right and the disc reads as nearly full
  SunX = -0.50;
  SunY = 0.32;
  SunZ = 0.80;

  TurnUnits = 4294967296.0; // 2^32

constructor TMoonGlobe.Create(ARenderer: PSdlRenderer;
  const ASpriteSet: TSpriteSet; const AMapName: string);
begin
  inherited Create;
  FGlobe := TGlobe.Create(ARenderer, ASpriteSet, AMapName, '', MoonLook);
  FGlobe.LightFrom(SunX, SunY, SunZ);
  FSpinStep := Round(TurnUnits / SpinTicksPerTurn);
end;

destructor TMoonGlobe.Destroy;
begin
  FGlobe.Free;
  inherited;
end;

// Longitude runs the other way from the spin so that the surface
// travels left to right across the face, as a prograde globe does
procedure TMoonGlobe.Tick;
begin
  FGlobe.Spin(-FSpinStep);
end;

procedure TMoonGlobe.Draw(const ADest: TSdlFRect);
begin
  FGlobe.Draw(ADest, White, 1);
end;

end.
