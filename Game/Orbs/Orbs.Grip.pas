{
  Orbs.Grip - the orbs that take the pads at the throw: black orbs out of
  the hero's body, one at a time, each flying off him on a bowed way to a
  seat on the beam of a pad - along the beam's top edge and its bottom
  edge - and clinging there, turning with the pad as it spins and going
  where it goes. The pads are taken in the order the owner gives them,
  every seat of one before the next; the last orb of a pad seated, the
  pad is gripped. The orbs swell a little with the heart; they are
  smaller than the orbs of the rite - many of them on a thin beam.

  Where the beams are and how they turn is the owner's: it hands them in
  every tick (TGripBeam). No orb is armed. A pad thrown, its orbs ride it;
  blown up, they burn out where they cling.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Grip;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics,
  Orbs.Flock, Orbs.Rite;

const
  // Units between two seats along an edge of a beam
  GripSpacing = 10.0;
  // An orb leaves him every this many ticks
  GripGapTicks = 1;
  // A flight takes this long and a tick more for every GripFlightPace
  // units of the way, but no longer than GripFlightLongest
  GripFlightBaseTicks = 10;
  GripFlightPace = 12.0;
  GripFlightLongest = 30;
  // Of an orb of the rite, seated
  GripSize = 0.55;

type
  // A pad's beam as the owner has it this tick: its middle - the point it
  // turns about - its spin, degrees clockwise, and its half sizes
  TGripBeam = record
    Middle: TSdlFPoint;
    Spin: Single;
    HalfWidth, HalfDepth: Single;
  end;

  TOrbGrip = class
  private type
    TGripOrb = class(TOrb)
    private
      FPad: Integer;
      // From the beam's middle as it lies unturned
      FSeat: TSdlFPoint;
      FSeated: Boolean;
      FAge: Integer;
      FTakeoff: TSdlFPoint;
      FFlightTicks: Integer;
      // How far the way is bowed aside, units, either side
      FBow: Single;
    end;

    // A seat yet to be flown to: whose and where on the beam
    TSeatCall = record
      Pad: Integer;
      Seat: TSdlFPoint;
    end;
  private
    FFlock: TOrbFlock;
    FCalls: TList<TSeatCall>;
    FNextCall: Integer;
    FSinceCall: Integer;
    // A pad's seats, and how many of them are taken
    FSeats: TArray<Integer>;
    FSeated: TArray<Integer>;
    FRandom: TXorShift;
    function GripOrb(AIndex: Integer): TGripOrb;
    procedure Call(const ABody: TBodyPoints; const ACenter: TSdlFPoint;
      const ABeams: TArray<TGripBeam>);
    procedure Fly(const AOrb: TGripOrb; const ABeam: TGripBeam;
      var AGripped: TArray<Integer>);
    procedure Cling(const AOrb: TGripOrb; const ABeam: TGripBeam;
      APulse: Single);
  public
    constructor Create;
    destructor Destroy; override;
    // The pads of ABeams to be taken, in their order; the orbs before are
    // dropped
    procedure Start(const ABeams: TArray<TGripBeam>);
    // Once a tick: the beams as the pads stand, the points of his body and
    // his center to leave from, the heart's pulse. The pads gripped this
    // tick, by their number.
    function Tick(const ABody: TBodyPoints; const ACenter: TSdlFPoint;
      const ABeams: TArray<TGripBeam>; APulse: Single): TArray<Integer>;
    // The pad APad is blown up: its orbs burn out where they cling
    procedure Burn(APad: Integer);
    // The hero is dead: every orb draws into its point
    procedure Collapse;
    procedure Clear;
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // The pads it takes
    function Count: Integer;
    // The seats of the pad APad, and the ones taken
    function Seats(APad: Integer): Integer;
    function Seated(APad: Integer): Integer;
    property Flock: TOrbFlock read FFlock;
  end;

// The point of his body an orb for ATarget leaves from: of ABody, the one
// farthest toward ATarget from ACenter; ACenter when ABody has none
function FacingPoint(const ABody: TBodyPoints; const ACenter,
  ATarget: TSdlFPoint): TSdlFPoint;

// A point of a beam on the screen: ASeat from its middle as it lies
// unturned, turned with it
function OnBeam(const ABeam: TGripBeam; const ASeat: TSdlFPoint): TSdlFPoint;

implementation

uses
  System.Math;

const
  // The way is bowed aside by this much and up to GripBowSpan more
  GripBowLeast = 8.0;
  GripBowSpan = 24.0;
  // Out of his body an orb grows to its size over this share of its flight
  GripBirthShare = 0.25;
  GripBirthSize = 0.3;
  // On a thump a seated orb swells by this share
  GripSwell = 0.15;

  DiceSeed = $47726970; // "Grip"

function FacingPoint(const ABody: TBodyPoints; const ACenter,
  ATarget: TSdlFPoint): TSdlFPoint;
begin
  Result := ACenter;
  var TowardX := ATarget.X - ACenter.X;
  var TowardY := ATarget.Y - ACenter.Y;
  var Farthest: Single := -MaxSingle;
  for var Point in ABody do
  begin
    var Toward := (Point.X - ACenter.X) * TowardX + (Point.Y - ACenter.Y) * TowardY;
    if Toward > Farthest then
    begin
      Farthest := Toward;
      Result := Point;
    end;
  end;
end;

// Clockwise on the screen, the Y axis down
function OnBeam(const ABeam: TGripBeam; const ASeat: TSdlFPoint): TSdlFPoint;
begin
  var Angle := DegToRad(ABeam.Spin);
  Result.X := ABeam.Middle.X + ASeat.X * Cos(Angle) - ASeat.Y * Sin(Angle);
  Result.Y := ABeam.Middle.Y + ASeat.X * Sin(Angle) + ASeat.Y * Cos(Angle);
end;

// Evenly along the top edge and the bottom edge, a top seat and the bottom
// one under it in turn
function SeatsOf(const ABeam: TGripBeam): TArray<TSdlFPoint>;
begin
  Result := [];
  var Along := Max(2, Round(2 * ABeam.HalfWidth / GripSpacing));
  var Step: Single := 2 * ABeam.HalfWidth / Along;
  for var i := 0 to Along - 1 do
  begin
    var Seat: TSdlFPoint;
    Seat.X := -ABeam.HalfWidth + (i + 0.5) * Step;
    Seat.Y := -ABeam.HalfDepth;
    Result := Result + [Seat];
    Seat.Y := ABeam.HalfDepth;
    Result := Result + [Seat];
  end;
end;

{ TOrbGrip }

constructor TOrbGrip.Create;
begin
  inherited Create;
  FFlock := TOrbFlock.Create(MoonOrbTint);
  FCalls := TList<TSeatCall>.Create;
  FRandom.Seed := DiceSeed;
end;

destructor TOrbGrip.Destroy;
begin
  FCalls.Free;
  FFlock.Free;
  inherited;
end;

function TOrbGrip.GripOrb(AIndex: Integer): TGripOrb;
begin
  Result := TGripOrb(FFlock.Orbs[AIndex]);
end;

procedure TOrbGrip.Start(const ABeams: TArray<TGripBeam>);
begin
  Clear;
  SetLength(FSeats, Length(ABeams));
  SetLength(FSeated, Length(ABeams));
  for var i := 0 to High(ABeams) do
  begin
    var Seats := SeatsOf(ABeams[i]);
    FSeats[i] := Length(Seats);
    FSeated[i] := 0;
    for var Seat in Seats do
    begin
      var SeatCall: TSeatCall;
      SeatCall.Pad := i;
      SeatCall.Seat := Seat;
      FCalls.Add(SeatCall);
    end;
  end;
end;

// Out of the point of his body that faces the seat
procedure TOrbGrip.Call(const ABody: TBodyPoints; const ACenter: TSdlFPoint;
  const ABeams: TArray<TGripBeam>);
begin
  var SeatCall := FCalls[FNextCall];
  Inc(FNextCall);
  var Target := OnBeam(ABeams[SeatCall.Pad], SeatCall.Seat);
  var From := FacingPoint(ABody, ACenter, Target);
  var Orb := TGripOrb.Create(From.X, From.Y);
  Orb.Armed := False;
  Orb.Size := GripBirthSize * GripSize;
  Orb.FPad := SeatCall.Pad;
  Orb.FSeat := SeatCall.Seat;
  Orb.FTakeoff := From;
  var Way := Hypot(Target.X - From.X, Target.Y - From.Y);
  Orb.FFlightTicks := Min(GripFlightLongest,
    GripFlightBaseTicks + Round(Way / GripFlightPace));
  Orb.FBow := GripBowLeast + GripBowSpan * FRandom.NextUnit;
  if FRandom.NextUnit < 0.5 then
    Orb.FBow := -Orb.FBow;
  FFlock.Add(Orb);
end;

// Along the straight line to its seat, wherever the seat is now, bowed
// aside in the middle; there it clings
procedure TOrbGrip.Fly(const AOrb: TGripOrb; const ABeam: TGripBeam;
  var AGripped: TArray<Integer>);
begin
  var Target := OnBeam(ABeam, AOrb.FSeat);
  var Flown: Single := Min(AOrb.FAge / AOrb.FFlightTicks, 1);
  var Eased := EasedInOut(Flown);
  var AcrossX := Target.X - AOrb.FTakeoff.X;
  var AcrossY := Target.Y - AOrb.FTakeoff.Y;
  var Way := Hypot(AcrossX, AcrossY);
  var Bowed: Single := 0;
  if Way > 0 then
    Bowed := AOrb.FBow * Sin(Pi * Flown) / Way;
  AOrb.MoveTo(AOrb.FTakeoff.X + AcrossX * Eased - AcrossY * Bowed,
    AOrb.FTakeoff.Y + AcrossY * Eased + AcrossX * Bowed);
  var Grown: Single := Min(Flown / GripBirthShare, 1);
  AOrb.Size := GripSize * (GripBirthSize + (1 - GripBirthSize) * Grown);
  if Flown < 1 then
    Exit;
  AOrb.FSeated := True;
  Inc(FSeated[AOrb.FPad]);
  if FSeated[AOrb.FPad] = FSeats[AOrb.FPad] then
    AGripped := AGripped + [AOrb.FPad];
end;

procedure TOrbGrip.Cling(const AOrb: TGripOrb; const ABeam: TGripBeam;
  APulse: Single);
begin
  var Place := OnBeam(ABeam, AOrb.FSeat);
  AOrb.MoveTo(Place.X, Place.Y);
  AOrb.Size := GripSize * (1 + GripSwell * APulse);
end;

function TOrbGrip.Tick(const ABody: TBodyPoints; const ACenter: TSdlFPoint;
  const ABeams: TArray<TGripBeam>; APulse: Single): TArray<Integer>;
begin
  Result := [];
  FFlock.Tick;
  if (FNextCall < FCalls.Count) and (FSinceCall mod GripGapTicks = 0) then
    Call(ABody, ACenter, ABeams);
  Inc(FSinceCall);

  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := GripOrb(i);
    if Orb.State <> osAlive then
      Continue;
    Inc(Orb.FAge);
    var Beam := ABeams[Orb.FPad];
    if Orb.FSeated then
      Cling(Orb, Beam, APulse)
    else
      Fly(Orb, Beam, Result);
  end;
end;

procedure TOrbGrip.Burn(APad: Integer);
begin
  for var i := 0 to FFlock.Orbs.Count - 1 do
    if GripOrb(i).FPad = APad then
      FFlock.Implode(GripOrb(i));
end;

procedure TOrbGrip.Collapse;
begin
  for var Orb in FFlock.Orbs do
    FFlock.Implode(Orb);
  FCalls.Clear;
  FNextCall := 0;
end;

procedure TOrbGrip.Clear;
begin
  FFlock.Clear;
  FCalls.Clear;
  FNextCall := 0;
  FSinceCall := 0;
  FSeats := nil;
  FSeated := nil;
end;

procedure TOrbGrip.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FFlock.Draw(ACanvas, AOrigin, AAlpha);
end;

function TOrbGrip.Count: Integer;
begin
  Result := Length(FSeats);
end;

function TOrbGrip.Seats(APad: Integer): Integer;
begin
  Result := FSeats[APad];
end;

function TOrbGrip.Seated(APad: Integer): Integer;
begin
  Result := FSeated[APad];
end;

end.
