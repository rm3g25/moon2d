{
  Orbs.Aura - the hero's aura: a ring of orbs on an oval around his body,
  standing at even gaps and slowly flowing along it. The ring goes where
  he goes on a leash: its nose keeps with him, its tail walks his path a
  little behind, and no orb's oval is let farther back than the leash is
  long - so he shows out of the ring at no pace, not in a jump on ice. A
  leap no body makes, the return from a pit, pays the ring out as a
  thread instead.

  Every orb has a time of its own; after each loss the ring closes up to
  even gaps. A call over a living ring weaves the new orbs in between
  the old.

  Where the orbs are and when their time is up, nothing more: what an orb
  strikes is the game's to settle, through the flock.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Aura;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics,
  Orbs.Flock;

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

  TAuraOrb = class(TOrb)
  private
    FLife: Integer; // ticks
    // Ticks behind the hero the center of its oval walks his path
    FLag: Single;
    // Where the formula put it a tick ago; not known of a newcomer, nor
    // after the ring has changed its count
    FAim: TSdlFPoint;
    FAimKnown: Boolean;
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
    function NewOrb(ACenter: TSdlFPoint; ASeat: Single): TAuraOrb;
    function Follow(ACenter: TSdlFPoint): TSdlFPoint;
    function PathPoint(ALag: Single): TSdlFPoint;
    function ShareBehind(AOffset: TSdlFPoint): Single;
    procedure SetLag(const AOrb: TAuraOrb; ABehind: Single);
    function AimOf(const AOrb: TAuraOrb; AOffset: TSdlFPoint): TSdlFPoint;
    procedure Chase(const AOrb: TAuraOrb; AAim, AHeroStep: TSdlFPoint);
    procedure Lead(const AOrb: TAuraOrb; ASeat: Single;
      AHeroStep: TSdlFPoint);
    procedure Forget;
  public
    constructor Create(const ATint: TOrbTint);
    destructor Destroy; override;
    // A ring of orbs around the hero's center, in screen units; over a
    // living ring the new orbs are woven in between the old
    procedure Cast(ACenter: TSdlFPoint);
    // Once a tick, with the hero's center where the tick has left it
    procedure Tick(ACenter: TSdlFPoint);
    // The hero has gone through a door and is this far from where he
    // was: the ring and its memory of his path cross with him, and
    // nobody flies anywhere
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
  System.Math;

const
  OrbsPerCast = 60;
  // A quarter wider than the hero's body asks: he is cramped in less
  RadiusX = 28;
  RadiusY = 35;
  OvalChords = 256;
  LapTicks = 330; // the ring flows around in ten seconds
  AppearTicks = 10;
  LifeTicks = 660; // twenty seconds
  // And up to three seconds more, each orb its own: they go one by one
  LifeSpreadTicks = 99;

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
  // An orb takes the step its aim has just made, whole - a steady walk
  // leaves it no way behind - and this share of what is left
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

function TAura.NewOrb(ACenter: TSdlFPoint; ASeat: Single): TAuraOrb;
begin
  var Offset := FOval.PointAt(ASeat);
  Result := TAuraOrb.Create(ACenter.X + Offset.X, ACenter.Y + Offset.Y);
  Result.FLife := LifeTicks + Trunc(FRandom.NextUnit * LifeSpreadTicks);
  Result.Size := 0;
  Result.Level := 0;
end;

procedure TAura.Cast(ACenter: TSdlFPoint);
begin
  var Old := FFlock.Orbs.Count;
  var Total := Old + OrbsPerCast;
  var Kept := 0; // the old orbs seated so far
  // The old orbs keep their order and spread evenly through the new
  // count: each only moves half a gap aside to let a newcomer in
  for var Seat := 0 to Total - 1 do
    if (Seat + 1) * Old div Total > Kept then
      Inc(Kept)
    else
      FFlock.Insert(Seat, NewOrb(ACenter, FFlow + Seat / Total));
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

procedure TAura.Chase(const AOrb: TAuraOrb; AAim, AHeroStep: TSdlFPoint);
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

  var MoveX: Single := AimStepX + (AAim.X - AimStepX - AOrb.X) * ChaseShare;
  var MoveY: Single := AimStepY + (AAim.Y - AimStepY - AOrb.Y) * ChaseShare;
  var Speed: Single := Hypot(MoveX, MoveY);
  if Speed > ChaseSpeedLimit then
  begin
    MoveX := MoveX * ChaseSpeedLimit / Speed;
    MoveY := MoveY * ChaseSpeedLimit / Speed;
  end;

  // An orb of the thread flies free; one of the ring keeps beside the
  // hero
  if FThreadTicks > 0 then
    AOrb.MoveTo(AOrb.X + MoveX, AOrb.Y + MoveY)
  else
    AOrb.MoveBeside(AOrb.X + MoveX, AOrb.Y + MoveY, AHeroStep.X,
      AHeroStep.Y);
end;

procedure TAura.Lead(const AOrb: TAuraOrb; ASeat: Single;
  AHeroStep: TSdlFPoint);
begin
  var Offset := FOval.PointAt(ASeat);
  SetLag(AOrb, ShareBehind(Offset));
  Chase(AOrb, AimOf(AOrb, Offset), AHeroStep);

  var Shown: Single := AOrb.Age / AppearTicks;
  if Shown > 1 then
    Shown := 1;
  AOrb.Size := Shown;
  AOrb.Level := Shown;

  if AOrb.Age >= AOrb.FLife then
    FFlock.Implode(AOrb);
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
