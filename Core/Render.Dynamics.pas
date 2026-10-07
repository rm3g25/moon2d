{
  Render.Dynamics - brings a level's dynamic objects (Levels.Dynamics)
  to the screen: ticks them, knows where each one stands, draws the
  ones on the hero's screen, layer by layer.

  Where an object stands: a nailed one on its screen, or on each of
  its run of screens; one under a static object on every screen that
  object stands on, counted from its top-left corner - settled once
  at level load, static objects never move. One under a pad or a
  monster is looked up by tag every tick through the game's callback: a
  monster moves, dies and is reborn with the field on every restart, so
  no reference to one is kept. A monster that spins (a
  disc) also tells its pose of the last two ticks: an object that turns
  with it is drawn where its point has turned to, between the ticks as
  the disc is.

  The solid layer comes from the game too, as a probe, and reaches the
  objects with the canvas: what a kind throws may ring off the walls.
  The probe answers for the hero's screen alone, so an object standing
  on another one meets no walls rather than the wrong ones.

  The backdrop of the screen reaches the objects of the backdrop layer
  with the canvas as well: a kind that bends it draws it again. Which
  backdrop it is the game says (TDynamicWorld.BackdropOf).

  A parent may go into the depth of its screen - a pad in a rebuild
  does. What hangs on it goes along: it draws in toward the parent's
  middle and leaves its layer for a pass of its own, DrawSunk, which the
  game puts behind whatever stands in front; a beacon, a haze and a
  smoke are drawn smaller and darker besides (the canvas' Scale and
  Tone). The backdrop layer alone is drawn whole: it is under everything
  as it is.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Dynamics;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Effects.Sparks, Levels.Defs, Levels.Dynamics;

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

  // A parent gone into the depth of its screen. Sunk: 0 in front .. 1
  // all the way in, at this tick and a tick ago - between the ticks its
  // children go in as its picture does. Shrink and Dim: the shares of
  // its size and of its light it has lost all the way in. Pivot: the
  // point it shrinks about, from its top-left corner. All zero - a
  // parent in front, and one that never leaves it.
  TParentDepth = record
    Sunk, LastSunk: Single;
    Shrink, Dim: Single;
    Pivot: TSdlFPoint;
    function SunkAt(AAlpha: Single): Single;
  end;

  // A parent looked up this tick: its screen, the top-left corner of its
  // picture, whether it still lives and how hard it works, 0..1 - a pad
  // flying, or about to leave its place, works at 1; Spin only when Spins
  TParentStand = record
    Screen: Integer;
    X, Y: Single;
    Alive: Boolean;
    Effort: Single;
    Spins: Boolean;
    Spin: TParentSpin;
    Depth: TParentDepth;
  end;

  // Finds the pad or the monster carrying ATag; False when there is none
  TLocateParent = reference to function(const ATag: string;
    out AStand: TParentStand): Boolean;

  // The backdrop drawn behind AScreen
  TBackdropOf = reference to function(AScreen: Integer): TBackdropView;

  // What the dynamic objects ask of the game they live in
  TDynamicWorld = record
    LocateParent: TLocateParent;
    Solid: TSolidProbe; // of the hero's screen, in screen units
    BackdropOf: TBackdropOf;
  end;

  TDynamicScreenRenderer = class
  private type
    // A screen a dynamic object shows on, and the corner it counts from
    TStand = record
      Screen: Integer;
      OriginX, OriginY: Single;
      Spins: Boolean;
      Spin: TParentSpin;
      Depth: TParentDepth;
    end;

    TPlace = record
      DynamicObject: TDynamicObject;
      Stands: TArray<TStand>;
      FollowsParent: Boolean;
      ParentAlive: Boolean;
      ParentEffort: Single;
      LeadScreen: Integer; // the stand the last tick counted from
    end;

    // A frame being drawn: the hero's screen, the shake and the
    // timestep's alpha
    TFrameView = record
      Screen: Integer;
      Origin: TSdlPoint;
      Alpha: Single;
    end;

    // Which of an object's stands a pass draws: those in front, those in
    // the depth
    TStandSide = (ssFront, ssSunk);
    TStandSides = set of TStandSide;
  private
    FCanvas: TDynamicCanvas;
    FPlaces: TArray<TPlace>;
    FLocateParent: TLocateParent;
    FSolid: TSolidProbe;
    FBackdropOf: TBackdropOf;
    FInView: Boolean; // the object being ticked stands on the hero's screen
    function SolidInView(AX, AY: Single): Boolean;
    function PlaceOf(ADynamic: TDynamicObject;
      const AObjects: TArray<TLevelObject>): TPlace;
    procedure FollowParent(var APlace: TPlace);
    function LeadStand(const APlace: TPlace; AScreen: Integer): TStand;
    function OriginOf(const APlace: TPlace; const AStand: TStand;
      AAlpha: Single): TSdlFPoint;
    function ViewOf(AScreen: Integer; AOrigin: TSdlPoint;
      AAlpha: Single): TFrameView;
    procedure DrawStands(const APlace: TPlace; const AView: TFrameView;
      ASides: TStandSides);
  public
    // The level owns the objects and must outlive this renderer, and
    // AArt - the cache of the level's object art - must too
    constructor Create(ARenderer: PSdlRenderer; ALevel: TLevel;
      AArt: TSpriteCache; const AWorld: TDynamicWorld);
    destructor Destroy; override;
    // AScreen is the hero's: an object standing on several screens
    // counts from its stand there
    procedure Tick(AScreen: Integer);
    // The monsters were reborn (a restart): what hangs on them finds its
    // parent at once, before the next frame shows it at the old stand
    procedure Reseat;
    // The objects of ALayer, but for what hangs on a parent in the
    // depth: DrawSunk draws that. The backdrop layer is drawn whole.
    procedure Draw(AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single;
      ALayer: TDynamicLayer);
    // What hangs on a parent in the depth, whatever its layer - the
    // backdrop layer left out
    procedure DrawSunk(AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
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
  StreakGlowSide = 64;
  BeamGlowSide = 64;
  PuffSide = 64;

function TParentDepth.SunkAt(AAlpha: Single): Single;
begin
  Result := LastSunk + (Sunk - LastSunk) * AAlpha;
end;

constructor TDynamicScreenRenderer.Create(ARenderer: PSdlRenderer;
  ALevel: TLevel; AArt: TSpriteCache; const AWorld: TDynamicWorld);
begin
  inherited Create;
  FLocateParent := AWorld.LocateParent;
  FBackdropOf := AWorld.BackdropOf;
  FCanvas.Renderer := ARenderer;
  FCanvas.Art := AArt;
  FCanvas.Scale := 1;
  FCanvas.Tone := 1;
  FSolid := AWorld.Solid;
  FCanvas.Solid := SolidInView;
  FCanvas.PointGlow := CreateGlowShape(ARenderer, gsPoint, PointGlowSide);
  FCanvas.FlareGlow := CreateGlowShape(ARenderer, gsFlare, FlareGlowSide);
  FCanvas.StarburstGlow := CreateGlowShape(ARenderer, gsStarburst,
    StarburstGlowSide);
  FCanvas.StreakGlow := CreateGlowShape(ARenderer, gsStreak, StreakGlowSide);
  FCanvas.BeamGlow := CreateGlowShape(ARenderer, gsBeam, BeamGlowSide);
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
  if Assigned(FCanvas.BeamGlow) then
    SDL_DestroyTexture(FCanvas.BeamGlow);
  if Assigned(FCanvas.StreakGlow) then
    SDL_DestroyTexture(FCanvas.StreakGlow);
  if Assigned(FCanvas.StarburstGlow) then
    SDL_DestroyTexture(FCanvas.StarburstGlow);
  if Assigned(FCanvas.FlareGlow) then
    SDL_DestroyTexture(FCanvas.FlareGlow);
  if Assigned(FCanvas.PointGlow) then
    SDL_DestroyTexture(FCanvas.PointGlow);
  inherited;
end;

// Levels.Defs has already refused a parent tag that no object, no pad and
// no entity carries: a tag no object carries is a pad's or a monster's
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
    Result.FollowsParent := True;
    Result.ParentAlive := False;
  end;
end;

// A parent that is nowhere keeps its last stand: what is already in
// the air fades where it was
procedure TDynamicScreenRenderer.FollowParent(var APlace: TPlace);
var
  Parent: TParentStand;
begin
  if not FLocateParent(APlace.DynamicObject.Placement.Parent, Parent) then
  begin
    APlace.ParentAlive := False;
    APlace.ParentEffort := 0;
    Exit;
  end;
  SetLength(APlace.Stands, 1);
  APlace.Stands[0].Screen := Parent.Screen;
  APlace.Stands[0].OriginX := Parent.X;
  APlace.Stands[0].OriginY := Parent.Y;
  APlace.Stands[0].Spins := Parent.Spins;
  APlace.Stands[0].Spin := Parent.Spin;
  APlace.Stands[0].Depth := Parent.Depth;
  APlace.ParentAlive := Parent.Alive;
  APlace.ParentEffort := Parent.Effort;
end;

// The corner the object counts from. One that turns with a spinning
// parent counts from wherever its point has turned to, AAlpha of the way
// between the ticks; the rest from the stand's corner - under a parent
// in the depth from a corner that brings the object's point in toward
// the parent's pivot as far as the parent has shrunk.
function TDynamicScreenRenderer.OriginOf(const APlace: TPlace;
  const AStand: TStand; AAlpha: Single): TSdlFPoint;
begin
  var Placement := APlace.DynamicObject.Placement;
  var Depth := AStand.Depth;
  var Shrunk := Depth.Shrink * Depth.SunkAt(AAlpha);
  Result.X := AStand.OriginX + (Depth.Pivot.X - Placement.X) * Shrunk;
  Result.Y := AStand.OriginY + (Depth.Pivot.Y - Placement.Y) * Shrunk;
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
    if FPlaces[i].FollowsParent then
    begin
      FollowParent(FPlaces[i]);
      FPlaces[i].DynamicObject.ForgetOrigin;
    end;
end;

function TDynamicScreenRenderer.SolidInView(AX, AY: Single): Boolean;
begin
  Result := FInView and Assigned(FSolid) and FSolid(AX, AY);
end;

// Every object lives on, whatever screen the hero is on: coming back
// finds a lamp mid-rhythm, not starting over
procedure TDynamicScreenRenderer.Tick(AScreen: Integer);
begin
  for var i := 0 to High(FPlaces) do
  begin
    if FPlaces[i].FollowsParent then
      FollowParent(FPlaces[i]);
    var Lead := LeadStand(FPlaces[i], AScreen);
    // A parent standing elsewhere on the next screen is a jump, not
    // a flight
    if Lead.Screen <> FPlaces[i].LeadScreen then
      FPlaces[i].DynamicObject.ForgetOrigin;
    FPlaces[i].LeadScreen := Lead.Screen;
    FInView := Lead.Screen = AScreen;
    var Origin := OriginOf(FPlaces[i], Lead, ThisTick);
    FPlaces[i].DynamicObject.FollowEffort(FPlaces[i].ParentEffort);
    FPlaces[i].DynamicObject.Tick(Origin.X, Origin.Y, FPlaces[i].ParentAlive);
  end;
end;

function TDynamicScreenRenderer.ViewOf(AScreen: Integer; AOrigin: TSdlPoint;
  AAlpha: Single): TFrameView;
begin
  Result.Screen := AScreen;
  Result.Origin := AOrigin;
  Result.Alpha := AAlpha;
end;

// The stands of the object on the view's screen that are on one of
// ASides, each drawn as deep as its parent is: smaller and darker
procedure TDynamicScreenRenderer.DrawStands(const APlace: TPlace;
  const AView: TFrameView; ASides: TStandSides);
begin
  // What turns with a monster goes with it: there is nothing to turn
  // with once the parent is dead
  if APlace.DynamicObject.Placement.Turns and not APlace.ParentAlive then
    Exit;
  for var Stand in APlace.Stands do
  begin
    if Stand.Screen <> AView.Screen then
      Continue;
    var Depth := Stand.Depth;
    var Sunk := Depth.SunkAt(AView.Alpha);
    var Side := ssFront;
    if Sunk > 0 then
      Side := ssSunk;
    if not (Side in ASides) then
      Continue;
    var Origin := OriginOf(APlace, Stand, AView.Alpha);
    FCanvas.Scale := 1 - Depth.Shrink * Sunk;
    FCanvas.Tone := 1 - Depth.Dim * Sunk;
    APlace.DynamicObject.Draw(FCanvas, Origin.X + AView.Origin.X,
      Origin.Y + AView.Origin.Y, AView.Alpha);
  end;
  // The game draws smoke of its own with this canvas (Canvas): in front
  FCanvas.Scale := 1;
  FCanvas.Tone := 1;
end;

procedure TDynamicScreenRenderer.Draw(AScreen: Integer; AOrigin: TSdlPoint;
  AAlpha: Single; ALayer: TDynamicLayer);
begin
  var View := ViewOf(AScreen, AOrigin, AAlpha);
  var Sides: TStandSides := [ssFront];
  if ALayer = dlBackdrop then
  begin
    FCanvas.Backdrop := FBackdropOf(AScreen);
    Sides := [ssFront, ssSunk];
  end;
  for var Place in FPlaces do
    if Place.DynamicObject.Placement.Layer = ALayer then
      DrawStands(Place, View, Sides);
end;

procedure TDynamicScreenRenderer.DrawSunk(AScreen: Integer;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  var View := ViewOf(AScreen, AOrigin, AAlpha);
  for var Place in FPlaces do
    if Place.DynamicObject.Placement.Layer <> dlBackdrop then
      DrawStands(Place, View, [ssSunk]);
end;

end.
