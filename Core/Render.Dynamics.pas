{
  Render.Dynamics - brings a level's dynamic objects (Levels.Dynamics)
  to the screen: ticks them, knows where each one stands, draws the
  ones on the hero's screen.

  Where an object stands is settled at level load: a nailed one on its
  screen, one under a parent on every screen the parent's static object
  stands on, counted from that object's top-left corner. Static objects
  never move, so the answer is computed once.

  The layer is the static objects' own - behind the tiles and whoever
  walks over them: the hero passing the ship hides its lamp.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Dynamics;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Levels.Defs, Levels.Dynamics;

type
  TDynamicScreenRenderer = class
  private type
    // One screen a dynamic object shows on, and the corner it counts from
    TStand = record
      DynamicObject: TDynamicObject;
      Screen: Integer;
      OriginX, OriginY: Single;
    end;
  private
    FCanvas: TDynamicCanvas;
    FDynamics: TDynamicObjects;
    FStands: TArray<TStand>;
    procedure AddStands(ADynamic: TDynamicObject;
      const AObjects: TArray<TLevelObject>);
  public
    // The level owns the objects and must outlive this renderer
    constructor Create(ARenderer: PSdlRenderer; ALevel: TLevel);
    destructor Destroy; override;
    procedure Tick;
    procedure Draw(AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
  end;

implementation

uses
  Render.Glow;

const
  PointGlowSide = 64;
  FlareGlowSide = 128;
  // A ray a hair wide needs pixels across it
  StarburstGlowSide = 256;

constructor TDynamicScreenRenderer.Create(ARenderer: PSdlRenderer;
  ALevel: TLevel);
begin
  inherited Create;
  FCanvas.Renderer := ARenderer;
  FCanvas.PointGlow := CreateGlowShape(ARenderer, gsPoint, PointGlowSide);
  FCanvas.FlareGlow := CreateGlowShape(ARenderer, gsFlare, FlareGlowSide);
  FCanvas.StarburstGlow := CreateGlowShape(ARenderer, gsStarburst,
    StarburstGlowSide);

  FDynamics := ALevel.Dynamics;
  for var DynamicObject in FDynamics do
    AddStands(DynamicObject, ALevel.Objects);
end;

destructor TDynamicScreenRenderer.Destroy;
begin
  if Assigned(FCanvas.StarburstGlow) then
    SDL_DestroyTexture(FCanvas.StarburstGlow);
  if Assigned(FCanvas.FlareGlow) then
    SDL_DestroyTexture(FCanvas.FlareGlow);
  if Assigned(FCanvas.PointGlow) then
    SDL_DestroyTexture(FCanvas.PointGlow);
  inherited;
end;

// Levels.Defs has already refused a parent tag no object carries
procedure TDynamicScreenRenderer.AddStands(ADynamic: TDynamicObject;
  const AObjects: TArray<TLevelObject>);
begin
  var Placement := ADynamic.Placement;
  if Placement.Parent = '' then
  begin
    var Nailed: TStand;
    Nailed.DynamicObject := ADynamic;
    Nailed.Screen := Placement.Screen;
    Nailed.OriginX := 0;
    Nailed.OriginY := 0;
    FStands := FStands + [Nailed];
    Exit;
  end;

  for var Parent in AObjects do
  begin
    if Parent.Tag <> Placement.Parent then
      Continue;
    var Carried: TStand;
    Carried.DynamicObject := ADynamic;
    Carried.Screen := Parent.Screen;
    Carried.OriginX := Parent.X;
    Carried.OriginY := Parent.Y;
    FStands := FStands + [Carried];
  end;
end;

// Every object lives on, whatever screen the hero is on: coming back
// finds a lamp mid-rhythm, not starting over
procedure TDynamicScreenRenderer.Tick;
begin
  for var DynamicObject in FDynamics do
    DynamicObject.Tick;
end;

procedure TDynamicScreenRenderer.Draw(AScreen: Integer; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  for var Stand in FStands do
  begin
    if Stand.Screen <> AScreen then
      Continue;
    Stand.DynamicObject.Draw(FCanvas, Stand.OriginX + AOrigin.X,
      Stand.OriginY + AOrigin.Y, AAlpha);
  end;
end;

end.
