{
  Orbs.Aura - the hero's aura: a ring of orbs on an oval around his body,
  standing at even gaps and slowly flowing along it. The ring goes where
  he goes on a leash: its nose keeps with him, its tail walks his path a
  little behind, and no orb's oval is let farther back than the leash is
  long - so he shows out of the ring at no pace, not in a jump on ice. A
  leap no body makes, the return from a pit, pays the ring out as a
  thread instead.

  A call draws the orbs out of the matter around (Orbs.Harvest): each
  shows through on a face, hangs over it, the nearest the shortest, and
  flies to its seat in a spiral about the hero. It is armed from the
  moment it leaves the face; until then the ring it will sit in is no
  shield.

  Every orb has a time of its own; after each loss the ring closes up to
  even gaps. A call over a living ring weaves the new orbs in between
  the old, up to the ring's ceiling.

  Where the orbs are and when their time is up, nothing more: what an orb
  strikes is the game's to settle, through the flock.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Aura;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics,
  Orbs.Flock, Orbs.Harvest;

type
  // An oval walked by its length: equal shares of the lap are equal
  // stretches of the line, which equal turns of the angle are not
  TOvalTrack = record
  private
    FPoints: TArray<TSdlFPoint>;
    FReach: TArray<Single>; // the length walked to each point
  public
    procedure Lay(ARadiusX, ARadiusY: Single);
    // From the oval's center; AShare in laps, any number of them
    function PointAt(AShare: Single): TSdlFPoint;
  end;

  // How far a called orb has come: it shows through on its face, hangs
  // over it, flies to the ring, sits in it
  TAuraStage = (asEmerging, asHovering, asFlying, asSeated);

  TAuraOrb = class(TOrb)
  private
    FLife: Integer; // ticks
    // Ticks behind the hero the center of its oval walks his path
    FLag: Single;
    // Where the formula put it a tick ago; not known of a newcomer, nor
    // after the ring has changed its count
    FAim: TSdlFPoint;
    FAimKnown: Boolean;
    // Its place in the ring, kept from the call on: the ring makes room
    // for an orb before the orb is there
    FPlace: TSdlFPoint;
    FStage: TAuraStage;
    FStageAge: Integer; // ticks
    FSpot: TFaceSpot; // where matter gives it up
    FHoverTicks: Single;
    FFlightTicks: Single;
    FSway: Single; // where in its sway over the face it began, radians
    FTakeoff: TSdlFPoint; // where its flight began
    // The turn about the hero its flight makes, radians; not known
    // before the flight's first tick
    FSweep: Single;
    FSweepKnown: Boolean;
  end;

  TAura = class
  private
    FFlock: TOrbFlock;
    FOval: TOvalTrack;
    // The hero's center tick by tick, the newest last
    FPath: TList<TSdlFPoint>;
    // His speed, smoothed: the ring's nose looks that way
    FCourse: TSdlFPoint;
    FFlow: Single; // how far along the oval the ring has flowed, in laps
    FLeapt: Boolean; // the hero leapt this tick
    // Left of a leap's thread; the leash is off meanwhile
    FThreadTicks: Integer;
    FRinged: Integer; // the orbs of the ring a tick ago
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function RingOrb(AIndex: Integer): TAuraOrb;
    function SeatFacing(ATurn: Single; const ASeats: TArray<Integer>;
      ATotal: Integer): Integer;
    function NewOrb(ACenter: TSdlFPoint; ASeat: Single;
      const ASpot: TFaceSpot; ANearer: Integer): TAuraOrb;
    function Follow(ACenter: TSdlFPoint): TSdlFPoint;
    function PathPoint(ALag: Single): TSdlFPoint;
    function ShareBehind(AOffset: TSdlFPoint): Single;
    procedure SetLag(const AOrb: TAuraOrb; ABehind: Single);
    function AimOf(const AOrb: TAuraOrb; AOffset: TSdlFPoint): TSdlFPoint;
    procedure Chase(const AOrb: TAuraOrb; AAim: TSdlFPoint);
    procedure Emerge(const AOrb: TAuraOrb);
    procedure Hover(const AOrb: TAuraOrb);
    procedure TakeOff(const AOrb: TAuraOrb);
    procedure Fly(const AOrb: TAuraOrb; AHeroStep: TSdlFPoint);
    procedure KeepSeat(const AOrb: TAuraOrb; AHeroStep: TSdlFPoint);
    procedure Lead(const AOrb: TAuraOrb; ASeat: Single;
      AHeroStep: TSdlFPoint);
    procedure Forget;
  public
    constructor Create(const ATint: TOrbTint);
    destructor Destroy; override;
    // Orbs for a ring around the hero's center, in screen units, drawn
    // out of AMatter; over a living ring they are woven in between the
    // old, as many as its ceiling leaves room for
    procedure Cast(ACenter: TSdlFPoint; const AMatter: TMatter);
    // Once a tick, with the hero's center where the tick has left it
    procedure Tick(ACenter: TSdlFPoint);
    // The hero has gone through a door and is this far from where he
    // was: the ring and its memory of his path cross with him, and
    // nobody flies anywhere. An orb still on its face leaves it for the
    // ring at once: the face stays on the screen behind.
    procedure Carry(AStepX, AStepY: Single);
    // The hero is dead: every orb draws into its point
    procedure Collapse;
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure Clear;
    // What the orbs strike is the game's to settle
    property Flock: TOrbFlock read FFlock;
  end;

implementation

uses
  System.Math, System.Generics.Defaults;

const
  OrbsPerCast = 60;
  // A call tops the ring up to this many and no further: two calls'
  // worth is a tube without a gap already
  RingCeiling = 2 * OrbsPerCast;
  // A quarter wider than the hero's body asks: he is cramped in less
  RadiusX = 28;
  RadiusY = 35;
  OvalChords = 256;
  LapTicks = 330; // the ring flows around in ten seconds
  LifeTicks = 660; // twenty seconds
  // And up to three seconds more, each orb its own: they go one by one
  LifeSpreadTicks = 99;

  // An orb shows through in this many ticks: it grows to its size and
  // rises out of the matter along the face's normal
  AppearTicks = 10;
  // Units under its face it begins at, and over it it hangs at
  SunkDepth = 3;
  HoverHeight = 6;
  MarkTick = 2; // of its showing through: the face gets its mark
  // Hanging, an orb sways toward its face and away
  SwayDepth = 1.2; // units either way
  SwayPace = 0.35; // radians of the sway a tick
  SwaySpread = 6; // radians: each orb begins its sway somewhere in these
  // The nearest orb hangs this long, each farther one this much longer:
  // the ring closes from the hero outward
  HoverTicks = 16;
  HoverTicksApart = 0.7;
  // A flight takes this long and a tick more for every FlightPace units
  // the orb was called from
  FlightTicks = 20;
  FlightPace = 7;
  // A flight turns about the hero the way the ring flows. It turns
  // against the flow when that takes SweepSlack radians or less, or when
  // with the flow it would turn more than LongestSweep.
  SweepSlack = 0.4;
  LongestSweep = 1.25 * Pi;

  // The hero's speed of a tick is taken into his course by this share: a
  // turn swings the ring's nose over, it does not snap it
  CourseShare = 0.2;
  // Slower than this the hero stands: the ring has no nose and no tail
  CourseAtRest = 0.05; // units a tick
  // The ring's tail walks the hero's path this far behind him, its nose
  // no way behind
  TailLagTicks = 14;
  // A lag changes no faster, in ticks a tick: when the course turns, an
  // oval's center slides along the path, it does not jump
  LagSlew = 0.5;
  // No oval's center is let farther from the hero, at any speed. Less
  // than the gap between his body and the oval (20), or he would show
  // out of the ring
  LeashLength = 12;
  // An oval this far behind the hero is half as wide: the tail draws
  // into a drop
  SqueezeLength = 60;
  // An orb's place takes the step its aim has just made, whole - a
  // steady walk leaves it no way behind - and this share of what is left
  ChaseShare = 0.22;
  // Units a tick: above the hero's fastest fall
  ChaseSpeedLimit = 14;

  // Farther in one tick than the hero's body goes: the return from a pit
  LeapStep = 24;
  // On a leap the ring pays out as a thread: the nose leaves at once,
  // the tail this many ticks later
  ThreadLagTicks = 26;
  // The tail's wait and as long again for its flight
  ThreadTicks = 2 * ThreadLagTicks;

  PathTicks = 128; // the path remembered: longer than any lag
  DiceSeed = $41757261; // "Aura"

function Shifted(APoint: TSdlFPoint; AStepX, AStepY: Single): TSdlFPoint;
begin
  Result.X := APoint.X + AStepX;
  Result.Y := APoint.Y + AStepY;
end;

// APoint, drawn in to the leash's length of the hero
function Leashed(APoint, AHero: TSdlFPoint): TSdlFPoint;
begin
  Result := APoint;
  var Away: Single := Hypot(APoint.X - AHero.X, APoint.Y - AHero.Y);
  if Away <= LeashLength then
    Exit;
  Result.X := AHero.X + (APoint.X - AHero.X) * LeashLength / Away;
  Result.Y := AHero.Y + (APoint.Y - AHero.Y) * LeashLength / Away;
end;

// The seats of a ring of ATotal left to newcomers when the AOld orbs it
// holds keep their order and spread evenly through it: each of them
// only moves half a gap aside to let a newcomer in
function FreeSeats(AOld, ATotal: Integer): TArray<Integer>;
begin
  SetLength(Result, ATotal - AOld);
  var Kept := 0; // the old orbs seated so far
  var Freed := 0;
  for var Seat := 0 to ATotal - 1 do
    if (Seat + 1) * AOld div ATotal > Kept then
      Inc(Kept)
    else
    begin
      Result[Freed] := Seat;
      Inc(Freed);
    end;
end;

function ByTurn(const ALeft, ARight: TFaceSpot): Integer;
begin
  Result := CompareValue(ALeft.Turn, ARight.Turn);
end;

// How many of the spots are nearer the hero than the one at AIndex; of
// two as near, the earlier counts as nearer
function NearerSpots(const ASpots: TArray<TFaceSpot>;
  AIndex: Integer): Integer;
begin
  Result := 0;
  var Away := ASpots[AIndex].Away;
  for var i := 0 to High(ASpots) do
  begin
    var AsNearBefore := (ASpots[i].Away = Away) and (i < AIndex);
    if (ASpots[i].Away < Away) or AsNearBefore then
      Inc(Result);
  end;
end;

// A share past the whole is the whole
function UpToOne(AShare: Single): Single;
begin
  Result := AShare;
  if Result > 1 then
    Result := 1;
end;

// Slow away, slow home; 0..1 in, 0..1 out
function EasedInOut(AShare: Single): Single;
begin
  if AShare < 0.5 then
    Exit(2 * AShare * AShare);
  Result := 1 - Sqr(2 - 2 * AShare) / 2;
end;

// The turn a flight makes about the hero, from the turn its takeoff
// lies at to the turn of its seat: ATurn, give or take whole laps
function FirstSweep(ATurn: Single): Single;
begin
  Result := ATurn;
  while Result < -SweepSlack do
    Result := Result + 2 * Pi;
  while Result > 2 * Pi - SweepSlack do
    Result := Result - 2 * Pi;
  if Result > LongestSweep then
    Result := Result - 2 * Pi;
end;

// ATurn, give or take whole laps, as near ASweep as they bring it
function SweepNear(ATurn, ASweep: Single): Single;
begin
  Result := ATurn + 2 * Pi * Round((ASweep - ATurn) / (2 * Pi));
end;

// ---------------------------------------------------------------------------
// TOvalTrack
// ---------------------------------------------------------------------------

procedure TOvalTrack.Lay(ARadiusX, ARadiusY: Single);
begin
  SetLength(FPoints, OvalChords + 1);
  SetLength(FReach, OvalChords + 1);
  for var i := 0 to OvalChords do
  begin
    var Turn: Single := 2 * Pi * i / OvalChords;
    FPoints[i].X := ARadiusX * Cos(Turn);
    FPoints[i].Y := ARadiusY * Sin(Turn);
  end;

  FReach[0] := 0;
  for var i := 1 to OvalChords do
    FReach[i] := FReach[i - 1] + Hypot(FPoints[i].X - FPoints[i - 1].X,
      FPoints[i].Y - FPoints[i - 1].Y);
end;

function TOvalTrack.PointAt(AShare: Single): TSdlFPoint;
begin
  var Lap: Single := Frac(AShare);
  if Lap < 0 then
    Lap := Lap + 1;
  var Walked: Single := Lap * FReach[OvalChords];

  var Before := 0;
  var After := OvalChords;
  while After - Before > 1 do
  begin
    var Middle := (Before + After) div 2;
    if FReach[Middle] <= Walked then
      Before := Middle
    else
      After := Middle;
  end;

  var Along: Single := (Walked - FReach[Before]) /
    (FReach[After] - FReach[Before]);
  Result.X := FPoints[Before].X +
    (FPoints[After].X - FPoints[Before].X) * Along;
  Result.Y := FPoints[Before].Y +
    (FPoints[After].Y - FPoints[Before].Y) * Along;
end;

// ---------------------------------------------------------------------------
// TAura
// ---------------------------------------------------------------------------

constructor TAura.Create(const ATint: TOrbTint);
begin
  inherited Create;
  FFlock := TOrbFlock.Create(ATint);
  FPath := TList<TSdlFPoint>.Create;
  FOval.Lay(RadiusX, RadiusY);
  FRandom.Seed := DiceSeed;
end;

destructor TAura.Destroy;
begin
  FPath.Free;
  FFlock.Free;
  inherited;
end;

function TAura.RingOrb(AIndex: Integer): TAuraOrb;
begin
  Result := FFlock.Orbs[AIndex] as TAuraOrb;
end;

// Which of ASeats, seats of a ring of ATotal, lies from the hero nearest
// the way ATurn looks; the result counts along ASeats
function TAura.SeatFacing(ATurn: Single; const ASeats: TArray<Integer>;
  ATotal: Integer): Integer;
begin
  Result := 0;
  var Nearest: Single := 2 * Pi;
  for var i := 0 to High(ASeats) do
  begin
    var Offset := FOval.PointAt(FFlow + ASeats[i] / ATotal);
    var Apart: Single := Abs(ArcTan2(Offset.Y, Offset.X) - ATurn);
    if Apart > Pi then
      Apart := 2 * Pi - Apart;
    if Apart < Nearest then
    begin
      Nearest := Apart;
      Result := i;
    end;
  end;
end;

// An orb under the face of ASpot, its place in the ring on ASeat;
// ANearer - how many of the call hang shorter than it
function TAura.NewOrb(ACenter: TSdlFPoint; ASeat: Single;
  const ASpot: TFaceSpot; ANearer: Integer): TAuraOrb;
begin
  Result := TAuraOrb.Create(ASpot.X - ASpot.NormalX * SunkDepth,
    ASpot.Y - ASpot.NormalY * SunkDepth);
  var Offset := FOval.PointAt(ASeat);
  Result.FPlace := Shifted(ACenter, Offset.X, Offset.Y);
  Result.FSpot := ASpot;
  Result.FHoverTicks := HoverTicks + ANearer * HoverTicksApart;
  Result.FFlightTicks := FlightTicks + ASpot.Away / FlightPace;
  Result.FLife := LifeTicks + Trunc(FRandom.NextUnit * LifeSpreadTicks);
  Result.FSway := FRandom.NextUnit * SwaySpread;
  Result.Size := 0;
  Result.Level := 0;
  Result.Armed := False;
end;

procedure TAura.Cast(ACenter: TSdlFPoint; const AMatter: TMatter);
begin
  var Old := FFlock.Orbs.Count;
  var Fresh := Min(OrbsPerCast, RingCeiling - Old);
  if Fresh <= 0 then
    Exit;
  var Total := Old + Fresh;
  var Seats := FreeSeats(Old, Total);

  var Spots := HarvestSpots(AMatter, ACenter, Fresh, FRandom);
  // By the turn about the hero, and seated in that order from the seat
  // the first one faces: no newcomer crosses him on its way
  TArray.Sort<TFaceSpot>(Spots, TComparer<TFaceSpot>.Construct(ByTurn));
  var Facing := SeatFacing(Spots[0].Turn, Seats, Total);

  var Newcomers: TArray<TAuraOrb>;
  SetLength(Newcomers, Fresh);
  for var i := 0 to Fresh - 1 do
  begin
    var Taken := (Facing + i) mod Fresh;
    Newcomers[Taken] := NewOrb(ACenter, FFlow + Seats[Taken] / Total,
      Spots[i], NearerSpots(Spots, i));
  end;
  // Seat by seat upward: every insert finds the seats before it taken
  for var i := 0 to Fresh - 1 do
    FFlock.Insert(Seats[i], Newcomers[i]);
end;

// The hero's place of this tick goes into the path and his step from the
// last one into the course; the step is the result
function TAura.Follow(ACenter: TSdlFPoint): TSdlFPoint;
begin
  var Previous := ACenter;
  if FPath.Count > 0 then
    Previous := FPath.Last;
  FPath.Add(ACenter);
  if FPath.Count > PathTicks then
    FPath.Delete(0);

  Result.X := ACenter.X - Previous.X;
  Result.Y := ACenter.Y - Previous.Y;
  FCourse.X := FCourse.X + (Result.X - FCourse.X) * CourseShare;
  FCourse.Y := FCourse.Y + (Result.Y - FCourse.Y) * CourseShare;

  FLeapt := Hypot(Result.X, Result.Y) > LeapStep;
  if FLeapt then
  begin
    // Nothing to smooth: the nose looks where he went
    FCourse := Result;
    FThreadTicks := ThreadTicks;
  end;
  if FThreadTicks > 0 then
    Dec(FThreadTicks);
end;

// Where the hero was ALag ticks ago, between two ticks of his path
function TAura.PathPoint(ALag: Single): TSdlFPoint;
begin
  var Newest := FPath.Count - 1;
  var Back: Single := ALag;
  if Back > Newest then
    Back := Newest;
  var Whole: Integer := Trunc(Back);
  var Later := FPath[Newest - Whole];
  var Earlier := FPath[Max(0, Newest - Whole - 1)];
  var Between: Single := Back - Whole;
  Result.X := Later.X + (Earlier.X - Later.X) * Between;
  Result.Y := Later.Y + (Earlier.Y - Later.Y) * Between;
end;

// 0 for a seat at the ring's nose, 1 for one at its tail; AOffset - the
// seat from the oval's center
function TAura.ShareBehind(AOffset: TSdlFPoint): Single;
begin
  var Speed: Single := Hypot(FCourse.X, FCourse.Y);
  if Speed <= CourseAtRest then
    Exit(0);
  // The oval pressed back into a circle: the turn the seat was laid at
  var OnCircleX: Single := AOffset.X / RadiusX;
  var OnCircleY: Single := AOffset.Y / RadiusY;
  var SeatTurn: Single := ArcTan2(OnCircleY, OnCircleX);
  var CourseTurn: Single := ArcTan2(FCourse.Y, FCourse.X);
  Result := (1 - Cos(SeatTurn - CourseTurn)) / 2;
end;

procedure TAura.SetLag(const AOrb: TAuraOrb; ABehind: Single);
begin
  if FLeapt then
  begin
    // All at once, the nose first: the ring pays out as a thread
    AOrb.FLag := ThreadLagTicks * ABehind;
    AOrb.FAimKnown := False;
    Exit;
  end;
  // The thread is paying out: the lags hold
  if FThreadTicks > 0 then
    Exit;

  var Change: Single := TailLagTicks * ABehind - AOrb.FLag;
  if Change > LagSlew then
    Change := LagSlew;
  if Change < -LagSlew then
    Change := -LagSlew;
  AOrb.FLag := AOrb.FLag + Change;
end;

// Where the formula puts the orb this tick: on its seat, AOffset from
// the center of an oval that walks the hero's path the orb's lag behind
// him
function TAura.AimOf(const AOrb: TAuraOrb; AOffset: TSdlFPoint): TSdlFPoint;
begin
  var Hero := FPath.Last;
  var Center := PathPoint(AOrb.FLag);
  if FThreadTicks = 0 then
    Center := Leashed(Center, Hero);

  var Away: Single := Hypot(Center.X - Hero.X, Center.Y - Hero.Y);
  var Squeeze: Single := 1 / (1 + Away / SqueezeLength);
  Result.X := Center.X + AOffset.X * Squeeze;
  Result.Y := Center.Y + AOffset.Y * Squeeze;
end;

// The orb's place in the ring goes after its aim
procedure TAura.Chase(const AOrb: TAuraOrb; AAim: TSdlFPoint);
begin
  var AimStepX: Single := 0;
  var AimStepY: Single := 0;
  if AOrb.FAimKnown then
  begin
    AimStepX := AAim.X - AOrb.FAim.X;
    AimStepY := AAim.Y - AOrb.FAim.Y;
  end;
  AOrb.FAim := AAim;
  AOrb.FAimKnown := True;

  var MoveX: Single := AimStepX +
    (AAim.X - AimStepX - AOrb.FPlace.X) * ChaseShare;
  var MoveY: Single := AimStepY +
    (AAim.Y - AimStepY - AOrb.FPlace.Y) * ChaseShare;
  var Speed: Single := Hypot(MoveX, MoveY);
  if Speed > ChaseSpeedLimit then
  begin
    MoveX := MoveX * ChaseSpeedLimit / Speed;
    MoveY := MoveY * ChaseSpeedLimit / Speed;
  end;
  AOrb.FPlace := Shifted(AOrb.FPlace, MoveX, MoveY);
end;

// Out of the matter along the normal of its face, from under the face
// to where it hangs; a spot in thin air has no normal, and its orb
// shows through where it is
procedure TAura.Emerge(const AOrb: TAuraOrb);
begin
  var Risen := UpToOne(AOrb.FStageAge / AppearTicks);
  var Height: Single := (SunkDepth + HoverHeight) * Risen - SunkDepth;
  AOrb.MoveTo(AOrb.FSpot.X + AOrb.FSpot.NormalX * Height,
    AOrb.FSpot.Y + AOrb.FSpot.NormalY * Height);

  var OnFace := (AOrb.FSpot.NormalX <> 0) or (AOrb.FSpot.NormalY <> 0);
  if OnFace and (AOrb.FStageAge = MarkTick) then
    FFlock.MarkFace(AOrb.FSpot.X, AOrb.FSpot.Y, AOrb.FSpot.NormalX,
      AOrb.FSpot.NormalY);

  if Risen < 1 then
    Exit;
  AOrb.FStage := asHovering;
  AOrb.FStageAge := 0;
end;

procedure TAura.Hover(const AOrb: TAuraOrb);
begin
  var Height: Single := HoverHeight +
    SwayDepth * Sin(AOrb.FStageAge * SwayPace + AOrb.FSway);
  AOrb.MoveTo(AOrb.FSpot.X + AOrb.FSpot.NormalX * Height,
    AOrb.FSpot.Y + AOrb.FSpot.NormalY * Height);

  if AOrb.FStageAge >= AOrb.FHoverTicks then
    TakeOff(AOrb);
end;

// The orb leaves for the ring from where it is, and is armed
procedure TAura.TakeOff(const AOrb: TAuraOrb);
begin
  AOrb.FStage := asFlying;
  AOrb.FStageAge := 0;
  AOrb.FTakeoff.X := AOrb.X;
  AOrb.FTakeoff.Y := AOrb.Y;
  AOrb.FSweepKnown := False;
  AOrb.Armed := True;
end;

// A spiral about the hero: from where the orb took off to its place in
// the ring, its distance from him and its turn about him both go
// eased. The takeoff stands where it is while he moves, so the spiral
// is laid anew from it every tick.
procedure TAura.Fly(const AOrb: TAuraOrb; AHeroStep: TSdlFPoint);
begin
  var Hero := FPath.Last;
  if FLeapt then
  begin
    // The hero is somewhere else: a flight half flown would leap half
    // the way with him. It begins anew from where the orb is.
    TakeOff(AOrb);
    AOrb.FFlightTicks := FlightTicks +
      Hypot(AOrb.X - Hero.X, AOrb.Y - Hero.Y) / FlightPace;
  end;

  var Flown := UpToOne(AOrb.FStageAge / AOrb.FFlightTicks);
  var Eased := EasedInOut(Flown);
  var FromAway: Single := Hypot(AOrb.FTakeoff.X - Hero.X,
    AOrb.FTakeoff.Y - Hero.Y);
  var FromTurn: Single := ArcTan2(AOrb.FTakeoff.Y - Hero.Y,
    AOrb.FTakeoff.X - Hero.X);
  var ToAway: Single := Hypot(AOrb.FPlace.X - Hero.X,
    AOrb.FPlace.Y - Hero.Y);
  var ToTurn: Single := ArcTan2(AOrb.FPlace.Y - Hero.Y,
    AOrb.FPlace.X - Hero.X);

  // Which way round is settled on the flight's first tick. After it the
  // sweep only follows the two turns as they move: counted anew, it
  // would flip to the other way round in mid-flight, and the orb with
  // it to the other side of the hero.
  if AOrb.FSweepKnown then
    AOrb.FSweep := SweepNear(ToTurn - FromTurn, AOrb.FSweep)
  else
    AOrb.FSweep := FirstSweep(ToTurn - FromTurn);
  AOrb.FSweepKnown := True;

  var Away: Single := FromAway + (ToAway - FromAway) * Eased;
  var Turn: Single := FromTurn + AOrb.FSweep * Eased;
  // The nearer its seat, the more of the hero's step is the orb's own:
  // that share is no part of what it is drawn on ahead by
  AOrb.MoveBeside(Hero.X + Cos(Turn) * Away, Hero.Y + Sin(Turn) * Away,
    AHeroStep.X * Eased, AHeroStep.Y * Eased);

  if Flown >= 1 then
    AOrb.FStage := asSeated;
end;

procedure TAura.KeepSeat(const AOrb: TAuraOrb; AHeroStep: TSdlFPoint);
begin
  // An orb of the thread flies free; one of the ring keeps beside the
  // hero
  if FThreadTicks > 0 then
    AOrb.MoveTo(AOrb.FPlace.X, AOrb.FPlace.Y)
  else
    AOrb.MoveBeside(AOrb.FPlace.X, AOrb.FPlace.Y, AHeroStep.X,
      AHeroStep.Y);

  if AOrb.Age >= AOrb.FLife then
    FFlock.Implode(AOrb);
end;

procedure TAura.Lead(const AOrb: TAuraOrb; ASeat: Single;
  AHeroStep: TSdlFPoint);
begin
  var Offset := FOval.PointAt(ASeat);
  SetLag(AOrb, ShareBehind(Offset));
  Chase(AOrb, AimOf(AOrb, Offset));

  Inc(AOrb.FStageAge);
  case AOrb.FStage of
    asEmerging:
      Emerge(AOrb);
    asHovering:
      Hover(AOrb);
    asFlying:
      Fly(AOrb, AHeroStep);
    asSeated:
      KeepSeat(AOrb, AHeroStep);
  end;

  var Shown := UpToOne(AOrb.Age / AppearTicks);
  AOrb.Size := Shown;
  AOrb.Level := Shown;
end;

procedure TAura.Tick(ACenter: TSdlFPoint);
begin
  FFlock.Tick;
  var Count := FFlock.Orbs.Count;
  if Count = 0 then
  begin
    Forget;
    Exit;
  end;

  var HeroStep := Follow(ACenter);
  FFlow := Frac(FFlow + 1 / LapTicks);
  // The ring has changed its count: the orbs slide to their new seats,
  // they do not hop
  if Count <> FRinged then
    for var i := 0 to Count - 1 do
      RingOrb(i).FAimKnown := False;
  FRinged := Count;

  for var i := 0 to Count - 1 do
    Lead(RingOrb(i), FFlow + i / Count, HeroStep);
end;

procedure TAura.Carry(AStepX, AStepY: Single);
begin
  FFlock.Shift(AStepX, AStepY);
  for var i := 0 to FPath.Count - 1 do
    FPath[i] := Shifted(FPath[i], AStepX, AStepY);
  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := RingOrb(i);
    Orb.FAim := Shifted(Orb.FAim, AStepX, AStepY);
    Orb.FPlace := Shifted(Orb.FPlace, AStepX, AStepY);
    Orb.FTakeoff := Shifted(Orb.FTakeoff, AStepX, AStepY);
    if Orb.FStage in [asEmerging, asHovering] then
      TakeOff(Orb);
  end;
end;

procedure TAura.Collapse;
begin
  for var Orb in FFlock.Orbs do
    FFlock.Implode(Orb);
end;

procedure TAura.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FFlock.Draw(ACanvas, AOrigin, AAlpha);
end;

// A ring called after this one starts from a hero at rest
procedure TAura.Forget;
begin
  FPath.Clear;
  FCourse := Default(TSdlFPoint);
  FLeapt := False;
  FThreadTicks := 0;
  FRinged := 0;
end;

procedure TAura.Clear;
begin
  FFlock.Clear;
  Forget;
end;

end.
