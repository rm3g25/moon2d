{
  Game.Magnet - the electromagnet under the Ram's belly, the spine of its
  air fight. Stowed in the belly till it is told to come out: a breath,
  then it slides down - its first move, the start of the fight.

  From then on it works in a cycle. Cold, it looks for a small barge: the
  one the hero stands on, when its rule says so, else the nearest to its
  face. One out of its beam's reach it only wants - its owner flies it
  there. One in reach it catches: the beam on, the barge drawn up under
  the face in a little over a second - a few units under it, or, caught
  with the hero aboard, a hero's height and a little room lower: the lift.
  Then it holds the barge, heating. Then it seizes it - the barge snaps up
  to the face, the press of a lift - and throws it at the hero. Then,
  empty, it cools: the window. Cold again and rested, it looks for the
  next - unless its owner has given the turn to another weapon: then it
  waits, cold, till it may look again. Told to tuck in, for its owner's
  charge, it slides back into the belly, cold and empty, and out again once
  let; it looks for nothing till it is all the way out.

  It is soft - an orb takes a life of the hull - from the hold till it is
  cold; how hot it is drawn follows: up as it holds, fading as it cools.

  The barges are the caller's, told anew every tick by numbers of its own;
  a caught one is the magnet's till it is seized: where its top left
  corner is and how far it went this tick are told, and the caller moves
  its barge by that. What a thrown barge does is the caller's too. It
  knows no pads, no flock and no hull. No drawing.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Magnet;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

const
  // The beam takes a deck no farther than this from the face
  MagnetReach = 150.0;
  // Told to come out it waits a breath, then slides out of the belly
  DeployBreathTicks = 33;
  DeploySlideTicks = 20;
  // The cycle: the barge drawn up, held, snapped up to the face; then the
  // window, and a rest before the next
  MagnetPullTicks = 40;
  MagnetHoldTicks = 56;
  MagnetPressTicks = 8;
  MagnetWindowTicks = 99;
  MagnetRestTicks = 33;
  // A held deck hangs this far under the face; in a lift a rider's height
  // and LiftRoom more, so his head is clear of it
  ShieldGap = 3.0;
  RiderHeight = 32.0;
  LiftRoom = 8.0;
  NoBarge = -1;

type
  // mgStowed - in the belly; mgComing - the breath and the slide out;
  // mgSeeking - cold, looking for a barge; mgReaching - the beam on, the
  // barge on its way up; mgHolding - under the face, heating; mgPressing -
  // seized, snapping up to the face; mgCooling - empty, the window
  TMagnetStage = (mgStowed, mgComing, mgSeeking, mgReaching, mgHolding,
    mgPressing, mgCooling);

  // mrNearest - the barge nearest to the face; mrHisBarge - the one the
  // hero stands on, when he stands on one, else the nearest
  TMagnetRule = (mrNearest, mrHisBarge);

  // A small barge as the caller tells it: its number with the caller, its
  // deck
  TMagnetBarge = record
    Index: Integer;
    Left, Top, Width: Single;
    HeroAboard: Boolean;
  end;

  // What the magnet sees this tick
  TMagnetSight = record
    // The middle of its face, out of the belly
    Face: TSdlFPoint;
    Barges: TArray<TMagnetBarge>;
    HeroAlive: Boolean;
    // The middle of his body
    Hero: TSdlFPoint;
    // Where a throw goes with no hero to throw at
    Harbour: TSdlFPoint;
    // Another weapon has the turn: cold, it looks for no barge
    Waits: Boolean;
    // Cold, it is to be in the belly: it slides in, and out once this is
    // over
    Tucked: Boolean;
  end;

  TMagnetCue = record
    // It starts to slide out: the fight is on
    Started: Boolean;
    // The beam is on Barge: it is the magnet's from now on
    Caught: Boolean;
    // Barge snaps up to the face, the middle of its deck to Snug over
    // MagnetPressTicks: it is a barge no more. Pressed - it was a lift.
    Seized: Boolean;
    Pressed: Boolean;
    Snug: TSdlFPoint;
    Barge: Integer;
    // The seized barge is thrown at Aim
    Thrown: Boolean;
    Aim: TSdlFPoint;
    // The window is over: cold and empty, it rests and looks for the next
    Cooled: Boolean;
  end;

  TMagnet = class
  private
    FRule: TMagnetRule;
    FStage: TMagnetStage;
    FTicks: Integer;
    FRest: Integer;
    FOut, FLastOut: Single;
    // Ticks of the slide out once it has come: DeploySlideTicks out, 0
    // tucked in
    FSlideTicks: Integer;
    FHeat, FLastHeat: Single;
    FLoad: Integer;
    FLoadWidth: Single;
    FLift: Boolean;
    // The top left corner of the load: where it was caught, where it is
    FFrom: TSdlFPoint;
    FLoadAt, FLastLoadAt: TSdlFPoint;
    FWants: Boolean;
    FWantsOver: Single;
    function Choose(const ASight: TMagnetSight): Integer;
    function Berth(const AFace: TSdlFPoint): TSdlFPoint;
    procedure Catch(const ABarge: TMagnetBarge; var ACue: TMagnetCue);
    function SlideTo(AOut: Boolean): Boolean;
    procedure TickComing(var ACue: TMagnetCue);
    procedure TickSeeking(const ASight: TMagnetSight; var ACue: TMagnetCue);
    procedure TickReaching(const ASight: TMagnetSight);
    procedure TickHolding(const ASight: TMagnetSight; var ACue: TMagnetCue);
    procedure TickPressing(const ASight: TMagnetSight; var ACue: TMagnetCue);
    procedure TickCooling(var ACue: TMagnetCue);
  public
    constructor Create;
    // A death, a new fight: stowed, cold, empty
    procedure Clear;
    // Out of the belly after a breath; nothing unless stowed
    procedure Deploy;
    function Tick(const ASight: TMagnetSight): TMagnetCue;
    property Rule: TMagnetRule read FRule write FRule;
    property Stage: TMagnetStage read FStage;
    // An orb that meets it takes a life of the hull
    function Soft: Boolean;
    // A barge is the magnet's: on its way up or held
    function Holds: Boolean;
    // The caller's number of that barge; NoBarge when it holds none
    property Load: Integer read FLoad;
    // Caught with the hero aboard: the lift
    property Lifts: Boolean read FLift;
    // The top left corner of the barge it holds, and how far it went this
    // tick, across and down
    property LoadLeft: Single read FLoadAt.X;
    property LoadTop: Single read FLoadAt.Y;
    function WayX: Single;
    function WayY: Single;
    // Cold, it wants a barge out of its reach: AOver - where across its
    // owner is to fly it
    function Wants(out AOver: Single): Boolean;
    // AAlpha of the way from the last tick to this one: 0 in the belly to
    // 1 out; 0 cold to 1 hot; the middle of the deck its beam holds
    function OutAt(AAlpha: Single): Single;
    function HeatAt(AAlpha: Single): Single;
    function LoadMiddleAt(AAlpha: Single): TSdlFPoint;
  end;

// How far the face is from the deck of ABarge, the nearest point of it
function DeckDistance(const AFace: TSdlFPoint; const ABarge: TMagnetBarge): Single;

implementation

uses
  System.Math, Game.Space;

const
  // The first barge is looked for this long after the magnet is out: the
  // flock is on its way in
  FirstRestTicks = 66;
  // Hot this far into the hold
  HeatUpTicks = 28;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

function DeckDistance(const AFace: TSdlFPoint; const ABarge: TMagnetBarge): Single;
begin
  var Aside := Max(0.0, Max(ABarge.Left - AFace.X,
    AFace.X - (ABarge.Left + ABarge.Width)));
  Result := Hypot(Aside, ABarge.Top - AFace.Y);
end;

// The middle of its deck is on the screen
function InSight(const ABarge: TMagnetBarge): Boolean;
begin
  var Middle := ABarge.Left + ABarge.Width / 2;
  Result := (Middle >= 0) and (Middle <= ScreenWidth);
end;

constructor TMagnet.Create;
begin
  inherited Create;
  Clear;
end;

procedure TMagnet.Clear;
begin
  FStage := mgStowed;
  FTicks := 0;
  FRest := 0;
  FOut := 0;
  FLastOut := 0;
  FSlideTicks := 0;
  FHeat := 0;
  FLastHeat := 0;
  FLoad := NoBarge;
  FLoadWidth := 0;
  FLift := False;
  FFrom := Default(TSdlFPoint);
  FLoadAt := Default(TSdlFPoint);
  FLastLoadAt := Default(TSdlFPoint);
  FWants := False;
  FWantsOver := 0;
end;

procedure TMagnet.Deploy;
begin
  if FStage <> mgStowed then
    Exit;
  FStage := mgComing;
  FTicks := 0;
end;

function TMagnet.Tick(const ASight: TMagnetSight): TMagnetCue;
begin
  Result := Default(TMagnetCue);
  Result.Barge := NoBarge;
  FLastOut := FOut;
  FLastHeat := FHeat;
  FLastLoadAt := FLoadAt;
  FWants := False;
  case FStage of
    mgComing:
      TickComing(Result);
    mgSeeking:
      TickSeeking(ASight, Result);
    mgReaching:
      TickReaching(ASight);
    mgHolding:
      TickHolding(ASight, Result);
    mgPressing:
      TickPressing(ASight, Result);
    mgCooling:
      TickCooling(Result);
  end;
end;

procedure TMagnet.TickComing(var ACue: TMagnetCue);
begin
  Inc(FTicks);
  ACue.Started := FTicks = DeployBreathTicks + 1;
  FOut := SmoothStep((FTicks - DeployBreathTicks) / DeploySlideTicks);
  if FTicks < DeployBreathTicks + DeploySlideTicks then
    Exit;
  FOut := 1;
  FSlideTicks := DeploySlideTicks;
  FStage := mgSeeking;
  FRest := FirstRestTicks;
end;

// A tick of the slide out or in, as long as the first slide out; True
// while it is on its way
function TMagnet.SlideTo(AOut: Boolean): Boolean;
begin
  var Wanted := 0;
  if AOut then
    Wanted := DeploySlideTicks;
  Result := FSlideTicks <> Wanted;
  if not Result then
    Exit;
  FSlideTicks := FSlideTicks + Sign(Wanted - FSlideTicks);
  FOut := SmoothStep(FSlideTicks / DeploySlideTicks);
end;

// The number in ASight.Barges of the barge to take; NoBarge when none is
// in sight
function TMagnet.Choose(const ASight: TMagnetSight): Integer;
begin
  Result := NoBarge;
  var Nearest: Single := MaxSingle;
  for var i := 0 to High(ASight.Barges) do
  begin
    var Barge := ASight.Barges[i];
    if not InSight(Barge) then
      Continue;
    if (FRule = mrHisBarge) and Barge.HeroAboard then
      Exit(i);
    var Distance := DeckDistance(ASight.Face, Barge);
    if Distance < Nearest then
    begin
      Nearest := Distance;
      Result := i;
    end;
  end;
end;

procedure TMagnet.TickSeeking(const ASight: TMagnetSight; var ACue: TMagnetCue);
begin
  if ASight.Tucked then
  begin
    SlideTo(False);
    Exit;
  end;
  if SlideTo(True) then
    Exit;
  if FRest > 0 then
  begin
    Dec(FRest);
    Exit;
  end;
  if ASight.Waits then
    Exit;
  var Pick := Choose(ASight);
  if Pick = NoBarge then
    Exit;
  var Barge := ASight.Barges[Pick];
  if DeckDistance(ASight.Face, Barge) > MagnetReach then
  begin
    FWants := True;
    FWantsOver := Barge.Left + Barge.Width / 2;
    Exit;
  end;
  Catch(Barge, ACue);
end;

procedure TMagnet.Catch(const ABarge: TMagnetBarge; var ACue: TMagnetCue);
begin
  FStage := mgReaching;
  FTicks := 0;
  FLoad := ABarge.Index;
  FLoadWidth := ABarge.Width;
  FLift := ABarge.HeroAboard;
  FFrom.X := ABarge.Left;
  FFrom.Y := ABarge.Top;
  FLoadAt := FFrom;
  FLastLoadAt := FFrom;
  ACue.Caught := True;
  ACue.Barge := FLoad;
end;

// Where the top left corner of the load hangs under a face at AFace
function TMagnet.Berth(const AFace: TSdlFPoint): TSdlFPoint;
begin
  Result.X := AFace.X - FLoadWidth / 2;
  Result.Y := AFace.Y + ShieldGap;
  if FLift then
    Result.Y := Result.Y + RiderHeight + LiftRoom;
end;

// From where it was caught to its berth, which rides with the face
procedure TMagnet.TickReaching(const ASight: TMagnetSight);
begin
  Inc(FTicks);
  var Share := SmoothStep(FTicks / MagnetPullTicks);
  var Till := Berth(ASight.Face);
  FLoadAt.X := Lerp(FFrom.X, Till.X, Share);
  FLoadAt.Y := Lerp(FFrom.Y, Till.Y, Share);
  if FTicks < MagnetPullTicks then
    Exit;
  FStage := mgHolding;
  FTicks := 0;
end;

procedure TMagnet.TickHolding(const ASight: TMagnetSight; var ACue: TMagnetCue);
begin
  Inc(FTicks);
  FLoadAt := Berth(ASight.Face);
  FHeat := Min(FTicks / HeatUpTicks, 1);
  if FTicks < MagnetHoldTicks then
    Exit;
  ACue.Seized := True;
  ACue.Pressed := FLift;
  ACue.Barge := FLoad;
  ACue.Snug.X := ASight.Face.X;
  ACue.Snug.Y := ASight.Face.Y + ShieldGap;
  FStage := mgPressing;
  FTicks := 0;
  FLoad := NoBarge;
  FLift := False;
  // No way left to go: the caller's barge is a barge no more
  FLastLoadAt := FLoadAt;
end;

procedure TMagnet.TickPressing(const ASight: TMagnetSight; var ACue: TMagnetCue);
begin
  Inc(FTicks);
  if FTicks < MagnetPressTicks then
    Exit;
  ACue.Thrown := True;
  ACue.Aim := ASight.Harbour;
  if ASight.HeroAlive then
    ACue.Aim := ASight.Hero;
  FStage := mgCooling;
  FTicks := 0;
end;

procedure TMagnet.TickCooling(var ACue: TMagnetCue);
begin
  Inc(FTicks);
  FHeat := Max(1 - FTicks / MagnetWindowTicks, 0);
  if FTicks < MagnetWindowTicks then
    Exit;
  FHeat := 0;
  FStage := mgSeeking;
  FRest := MagnetRestTicks;
  ACue.Cooled := True;
end;

function TMagnet.Soft: Boolean;
begin
  Result := FStage in [mgHolding, mgPressing, mgCooling];
end;

function TMagnet.Holds: Boolean;
begin
  Result := FStage in [mgReaching, mgHolding];
end;

function TMagnet.WayX: Single;
begin
  Result := FLoadAt.X - FLastLoadAt.X;
end;

function TMagnet.WayY: Single;
begin
  Result := FLoadAt.Y - FLastLoadAt.Y;
end;

function TMagnet.Wants(out AOver: Single): Boolean;
begin
  AOver := FWantsOver;
  Result := FWants;
end;

function TMagnet.OutAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastOut, FOut, AAlpha);
end;

function TMagnet.HeatAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastHeat, FHeat, AAlpha);
end;

function TMagnet.LoadMiddleAt(AAlpha: Single): TSdlFPoint;
begin
  Result.X := Lerp(FLastLoadAt.X, FLoadAt.X, AAlpha) + FLoadWidth / 2;
  Result.Y := Lerp(FLastLoadAt.Y, FLoadAt.Y, AAlpha);
end;

end.
