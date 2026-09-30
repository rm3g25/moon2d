{
  Render.Dynamics - brings a level's dynamic objects (Levels.Dynamics)
  to the screen: ticks them, knows where each one stands, draws the
  ones on the hero's screen, layer by layer.

  Where an object stands: a nailed one on its screen; one under a
  static object on every screen that object stands on, counted from its
  top-left corner - settled once at level load, static objects never
  move. One under a monster is looked up by tag every tick through the
  game's callback: monsters move, die and are reborn with the field on
  every restart, so no reference to one is kept.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Dynamics;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Levels.Defs, Levels.Dynamics;

type
  // A monster's sprite this tick: its screen, its top-left corner, and
  // whether it still lives
  TParentStand = record
    Screen: Integer;
    X, Y: Single;
    Alive: Boolean;
  end;

  // Finds the monster carrying ATag; False when there is none
  TLocateMonster = reference to function(const ATag: string;
    out AStand: TParentStand): Boolean;

  TDynamicScreenRenderer = class
  private type
    // A screen a dynamic object shows on, and the corner it counts from
    TStand = record
      Screen: Integer;
      OriginX, OriginY: Single;
    end;

    TPlace = record
      DynamicObject: TDynamicObject;
      Stands: TArray<TStand>;
      FollowsMonster: Boolean;
      ParentAlive: Boolean;
      LeadScreen: Integer; // the stand the last tick counted from
    end;
  private
    FCanvas: TDynamicCanvas;
    FPlaces: TArray<TPlace>;
    FLocateMonster: TLocateMonster;
    function PlaceOf(ADynamic: TDynamicObject;
      const AObjects: TArray<TLevelObject>): TPlace;
    procedure FollowMonster(var APlace: TPlace);
    function LeadStand(const APlace: TPlace; AScreen: Integer): TStand;
    procedure DrawPlace(const APlace: TPlace; AScreen: Integer;
      AOrigin: TSdlPoint; AAlpha: Single);
  public
    // The level owns the objects and must outlive this renderer
    constructor Create(ARenderer: PSdlRenderer; ALevel: TLevel;
      const ALocateMonster: TLocateMonster);
    destructor Destroy; override;
    // AScreen is the hero's: an object standing on several screens
    // counts from its stand there
    procedure Tick(AScreen: Integer);
    procedure Draw(AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single;
      ALayer: TDynamicLayer);
    // The textures, for smoke the game makes itself
    property Canvas: TDynamicCanvas read FCanvas;
  end;

implementation

uses
  Render.Glow, Render.Puff;

const
  PointGlowSide = 64;
  FlareGlowSide = 128;
  // A ray a hair wide needs pixels across it
  StarburstGlowSide = 256;
  PuffSide = 64;

constructor TDynamicScreenRenderer.Create(ARenderer: PSdlRenderer;
  ALevel: TLevel; const ALocateMonster: TLocateMonster);
begin
  inherited Create;
  FLocateMonster := ALocateMonster;
  FCanvas.Renderer := ARenderer;
  FCanvas.PointGlow := CreateGlowShape(ARenderer, gsPoint, PointGlowSide);
  FCanvas.FlareGlow := CreateGlowShape(ARenderer, gsFlare, FlareGlowSide);
  FCanvas.StarburstGlow := CreateGlowShape(ARenderer, gsStarburst,
    StarburstGlowSide);
  FCanvas.Puffs := CreatePuffTextures(ARenderer, PuffSide);

  for var DynamicObject in ALevel.Dynamics do
    FPlaces := FPlaces + [PlaceOf(DynamicObject, ALevel.Objects)];
end;

destructor TDynamicScreenRenderer.Destroy;
begin
  FreePuffTextures(FCanvas.Puffs);
  if Assigned(FCanvas.StarburstGlow) then
    SDL_DestroyTexture(FCanvas.StarburstGlow);
  if Assigned(FCanvas.FlareGlow) then
    SDL_DestroyTexture(FCanvas.FlareGlow);
  if Assigned(FCanvas.PointGlow) then
    SDL_DestroyTexture(FCanvas.PointGlow);
  inherited;
end;

// Levels.Defs has already refused a parent tag that neither an object
// nor an entity carries: a tag no object carries is a monster's
function TDynamicScreenRenderer.PlaceOf(ADynamic: TDynamicObject;
  const AObjects: TArray<TLevelObject>): TPlace;
begin
  Result := Default(TPlace);
  Result.DynamicObject := ADynamic;
  Result.ParentAlive := True;
  var Placement := ADynamic.Placement;
  if Placement.Parent = '' then
  begin
    var Nailed: TStand;
    Nailed.Screen := Placement.Screen;
    Nailed.OriginX := 0;
    Nailed.OriginY := 0;
    Result.Stands := [Nailed];
    Exit;
  end;

  for var Parent in AObjects do
  begin
    if Parent.Tag <> Placement.Parent then
      Continue;
    var Carried: TStand;
    Carried.Screen := Parent.Screen;
    Carried.OriginX := Parent.X;
    Carried.OriginY := Parent.Y;
    Result.Stands := Result.Stands + [Carried];
  end;

  if Length(Result.Stands) = 0 then
  begin
    Result.FollowsMonster := True;
    Result.ParentAlive := False;
  end;
end;

// A monster that is nowhere keeps its last stand: what is already in
// the air fades where it was
procedure TDynamicScreenRenderer.FollowMonster(var APlace: TPlace);
var
  Parent: TParentStand;
begin
  if not FLocateMonster(APlace.DynamicObject.Placement.Parent, Parent) then
  begin
    APlace.ParentAlive := False;
    Exit;
  end;
  SetLength(APlace.Stands, 1);
  APlace.Stands[0].Screen := Parent.Screen;
  APlace.Stands[0].OriginX := Parent.X;
  APlace.Stands[0].OriginY := Parent.Y;
  APlace.ParentAlive := Parent.Alive;
end;

function TDynamicScreenRenderer.LeadStand(const APlace: TPlace;
  AScreen: Integer): TStand;
begin
  for var Stand in APlace.Stands do
    if Stand.Screen = AScreen then
      Exit(Stand);
  if Length(APlace.Stands) > 0 then
    Exit(APlace.Stands[0]);
  Result := Default(TStand);
end;

// Every object lives on, whatever screen the hero is on: coming back
// finds a lamp mid-rhythm, not starting over
procedure TDynamicScreenRenderer.Tick(AScreen: Integer);
begin
  for var i := 0 to High(FPlaces) do
  begin
    if FPlaces[i].FollowsMonster then
      FollowMonster(FPlaces[i]);
    var Lead := LeadStand(FPlaces[i], AScreen);
    // A parent standing elsewhere on the next screen is a jump, not
    // a flight
    if Lead.Screen <> FPlaces[i].LeadScreen then
      FPlaces[i].DynamicObject.ForgetOrigin;
    FPlaces[i].LeadScreen := Lead.Screen;
    FPlaces[i].DynamicObject.Tick(Lead.OriginX, Lead.OriginY,
      FPlaces[i].ParentAlive);
  end;
end;

procedure TDynamicScreenRenderer.DrawPlace(const APlace: TPlace;
  AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Stand in APlace.Stands do
    if Stand.Screen = AScreen then
      APlace.DynamicObject.Draw(FCanvas, Stand.OriginX + AOrigin.X,
        Stand.OriginY + AOrigin.Y, AAlpha);
end;

procedure TDynamicScreenRenderer.Draw(AScreen: Integer; AOrigin: TSdlPoint;
  AAlpha: Single; ALayer: TDynamicLayer);
begin
  for var Place in FPlaces do
    if Place.DynamicObject.Placement.Layer = ALayer then
      DrawPlace(Place, AScreen, AOrigin, AAlpha);
end;

end.
