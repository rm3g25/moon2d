{
  Render.Dynamics - brings a level's dynamic objects (Levels.Dynamics)
  to the screen: ticks them, knows where each one stands, draws the
  ones on the hero's screen, layer by layer.

  Where an object stands: a nailed one on its screen, or on each of
  its run of screens; one under a static object on every screen that
  object stands on, counted from its top-left corner - settled once
  at level load, static objects never move. One under a monster is
  looked up by tag every tick through the game's callback: monsters
  move, die and are reborn with the field on every restart, so no
  reference to one is kept. A monster that spins (a disc) also tells its
  pose of the last two ticks: an object that turns with it is drawn
  where its point has turned to, between the ticks as the disc is.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Dynamics;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Levels.Defs, Levels.Dynamics;

type
  // A spinning monster at one tick: its axis on the screen and its
  // angle, degrees clockwise
  TSpinPose = record
    Center: TSdlFPoint;
    Angle: Single;
  end;

  // How a spinning monster stands now and a tick ago, and where its axis
  // sits counted from the sprite's top-left corner
  TParentSpin = record
    Pose: TSpinPose;
    LastPose: TSpinPose;
    Axis: TSdlFPoint;
  end;

  // A monster's sprite this tick: its screen, its top-left corner, and
  // whether it still lives; Spin only when Spins
  TParentStand = record
    Screen: Integer;
    X, Y: Single;
    Alive: Boolean;
    Spins: Boolean;
    Spin: TParentSpin;
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
      Spins: Boolean;
      Spin: TParentSpin;
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
    function OriginOf(const APlace: TPlace; const AStand: TStand;
      AAlpha: Single): TSdlFPoint;
    procedure DrawPlace(const APlace: TPlace; AScreen: Integer;
      AOrigin: TSdlPoint; AAlpha: Single);
  public
    // The level owns the objects and must outlive this renderer, and
    // AArt - the cache of the level's object art - must too
    constructor Create(ARenderer: PSdlRenderer; ALevel: TLevel;
      AArt: TSpriteCache; const ALocateMonster: TLocateMonster);
    destructor Destroy; override;
    // AScreen is the hero's: an object standing on several screens
    // counts from its stand there
    procedure Tick(AScreen: Integer);
    // The monsters were reborn (a restart): what hangs on them finds its
    // parent at once, before the next frame shows it at the old stand
    procedure Reseat;
    procedure Draw(AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single;
      ALayer: TDynamicLayer);
    // The textures, for smoke the game makes itself
    property Canvas: TDynamicCanvas read FCanvas;
  end;

implementation

uses
  System.Math, Render.Glow, Render.Puff;

const
  // The pose a tick has just reached, as an alpha between two ticks
  ThisTick = 1.0;
  PointGlowSide = 64;
  FlareGlowSide = 128;
  // A ray a hair wide needs pixels across it
  StarburstGlowSide = 256;
  PuffSide = 64;

constructor TDynamicScreenRenderer.Create(ARenderer: PSdlRenderer;
  ALevel: TLevel; AArt: TSpriteCache; const ALocateMonster: TLocateMonster);
begin
  inherited Create;
  FLocateMonster := ALocateMonster;
  FCanvas.Renderer := ARenderer;
  FCanvas.Art := AArt;
  FCanvas.PointGlow := CreateGlowShape(ARenderer, gsPoint, PointGlowSide);
  FCanvas.FlareGlow := CreateGlowShape(ARenderer, gsFlare, FlareGlowSide);
  FCanvas.StarburstGlow := CreateGlowShape(ARenderer, gsStarburst,
    StarburstGlowSide);
  FCanvas.Puffs := CreatePuffTextures(ARenderer, PuffSide);

  for var DynamicObject in ALevel.Dynamics do
  begin
    FPlaces := FPlaces + [PlaceOf(DynamicObject, ALevel.Objects)];
    DynamicObject.Acquire(FCanvas);
  end;
end;

destructor TDynamicScreenRenderer.Destroy;
begin
  for var Place in FPlaces do
    Place.DynamicObject.Release;
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
    for var Screen := Placement.Screen to Placement.LastScreen do
    begin
      var Nailed := Default(TStand);
      Nailed.Screen := Screen;
      Nailed.OriginX := 0;
      Nailed.OriginY := 0;
      Result.Stands := Result.Stands + [Nailed];
    end;
    Exit;
  end;

  for var Parent in AObjects do
  begin
    if Parent.Tag <> Placement.Parent then
      Continue;
    var Carried := Default(TStand);
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
  APlace.Stands[0].Spins := Parent.Spins;
  APlace.Stands[0].Spin := Parent.Spin;
  APlace.ParentAlive := Parent.Alive;
end;

// The corner the object counts from. One that turns with a spinning
// parent counts from wherever its point has turned to, AAlpha of the way
// between the ticks; the rest from the stand's corner.
function TDynamicScreenRenderer.OriginOf(const APlace: TPlace;
  const AStand: TStand; AAlpha: Single): TSdlFPoint;
begin
  Result.X := AStand.OriginX;
  Result.Y := AStand.OriginY;
  var Placement := APlace.DynamicObject.Placement;
  var TurnsWithParent := Placement.Turns and AStand.Spins;
  if not TurnsWithParent then
    Exit;

  var Last := AStand.Spin.LastPose;
  var Next := AStand.Spin.Pose;
  var Axis := AStand.Spin.Axis;
  var Angle := DegToRad(Last.Angle + (Next.Angle - Last.Angle) * AAlpha);
  var CenterX := Last.Center.X + (Next.Center.X - Last.Center.X) * AAlpha;
  var CenterY := Last.Center.Y + (Next.Center.Y - Last.Center.Y) * AAlpha;
  var ArmX := Placement.X - Axis.X;
  var ArmY := Placement.Y - Axis.Y;
  Result.X := CenterX + ArmX * Cos(Angle) - ArmY * Sin(Angle) - Placement.X;
  Result.Y := CenterY + ArmX * Sin(Angle) + ArmY * Cos(Angle) - Placement.Y;
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

procedure TDynamicScreenRenderer.Reseat;
begin
  for var i := 0 to High(FPlaces) do
    if FPlaces[i].FollowsMonster then
    begin
      FollowMonster(FPlaces[i]);
      FPlaces[i].DynamicObject.ForgetOrigin;
    end;
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
    var Origin := OriginOf(FPlaces[i], Lead, ThisTick);
    FPlaces[i].DynamicObject.Tick(Origin.X, Origin.Y, FPlaces[i].ParentAlive);
  end;
end;

// What turns with a monster goes with it: there is nothing to turn
// with once the parent is dead
procedure TDynamicScreenRenderer.DrawPlace(const APlace: TPlace;
  AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
begin
  if APlace.DynamicObject.Placement.Turns and not APlace.ParentAlive then
    Exit;
  for var Stand in APlace.Stands do
    if Stand.Screen = AScreen then
    begin
      var Origin := OriginOf(APlace, Stand, AAlpha);
      APlace.DynamicObject.Draw(FCanvas, Origin.X + AOrigin.X,
        Origin.Y + AOrigin.Y, AAlpha);
    end;
end;

procedure TDynamicScreenRenderer.Draw(AScreen: Integer; AOrigin: TSdlPoint;
  AAlpha: Single; ALayer: TDynamicLayer);
begin
  for var Place in FPlaces do
    if Place.DynamicObject.Placement.Layer = ALayer then
      DrawPlace(Place, AScreen, AOrigin, AAlpha);
end;

end.
