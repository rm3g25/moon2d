{
  Orbs.Moonrite - the rite of the eclipse, the moon form's henshin: black
  orbs called to the hero one at a time, fast, from all sides and from all
  over - off the faces of the matter well away from him and, every few, out
  of the depth of the far city, where an orb is born a speck and grows on
  its way. Each flies to its seat in the rings of the pattern "eclipse"
  (Orbs.Patterns) and sits there.
  The heart sets the pace, not a clock: every beat shortens the gap between
  two calls. The ring beats with the heart too, drawing in on each thump.

  The ring full, it stands and beats until it is told to draw in; then
  every orb goes into the hero at its own point of his body, as the orbs of
  the ice form's rite do (Orbs.Rite), and the rite is over.

  No orb is armed: there is nothing here to strike. What passes is told by
  events, the oldest first; what it means for the hero - the light in his
  body, the cure, the form - is the listener's.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Moonrite;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics,
  Orbs.Flock, Orbs.Harvest, Orbs.Patterns, Orbs.Rite;

type
  // Ticks
  TMoonRiteScore = record
    FirstGap: Single; // between the first two calls
    LastGap: Single; // the gap is never shorter
    GapStep: Single; // a heartbeat leaves the gap this share of itself
    DeepEvery: Integer; // every this-th orb comes out of the far city
    // Units: no orb comes off a face nearer the hero than this
    Nearest: Integer;
    CollapseTicks: Integer;
  end;

  TMoonRiteStage = (mgIdle, mgGathering, mgRinged, mgDrawingIn);

  TMoonRiteEvent = (mvNone, mvFull, mvDrawingIn, mvFinished);

  // What the heart does this tick
  TRiteBeat = record
    Struck: Boolean;
    Pulse: Single; // 0..1
  end;

  // A called orb shows through on its face, flies to its seat, sits in it
  // and at the end draws into the hero. One out of the depth has no face:
  // it is born flying.
  TMoonOrbStage = (moShowing, moFlying, moSeated, moDrawingIn);

  TMoonOrb = class(TOrb)
  private
    FNumber: Integer; // its seat in the rings
    FStage: TMoonOrbStage;
    FStageAge: Integer; // ticks
    FDeep: Boolean;
    FSpot: TFaceSpot;
    FTakeoff: TSdlFPoint;
    FFlightTicks: Single;
    FSweep: Single; // the turn about the hero its flight makes, radians
    // Its drawing into the hero: it waits, then takes this long, winding
    // to one side
    FWait: Single;
    FLength: Single;
    FSide: Single; // 1 or -1
    FEntry: TSdlFPoint; // where it goes into him, from his center
  end;

  TMoonRite = class
  private
    FFlock: TOrbFlock;
    FBodyOf: TBodyProbe;
    FPattern: TOrbPattern;
    FScore: TMoonRiteScore;
    FStage: TMoonRiteStage;
    // The rite's own tick: 0 at the first Tick after Start
    FAge: Integer;
    FFlow: Single; // the pattern's clock
    FPulse: Single;
    FFaces: TArray<TFaceSpot>;
    FFaceTaken: TArray<Boolean>;
    FDeep: TArray<TSdlFPoint>;
    FCalled: Integer;
    FGathered: Integer;
    FGap: Single;
    FSinceCall: Single;
    // The k-th orb called aims at FFirstTurn and k golden angles more, and
    // takes the free seat nearest that turn as the rings stand
    FFirstTurn: Single;
    FSeatTaken: TArray<Boolean>;
    FDrawInAt: Integer;
    FEvents: TList<TMoonRiteEvent>;
    FHeroCenter: TSdlFPoint;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function MoonOrb(AIndex: Integer): TMoonOrb;
    function SeatOf(ANumber: Integer): TPatternSeat;
    function CallsDeep: Boolean;
    function NearestFreeSeat(ATurn: Single): Integer;
    function NearestFace(ATurn: Single): Integer;
    function FaceOrb(ANumber: Integer): TMoonOrb;
    function DeepOrb(ANumber: Integer): TMoonOrb;
    function Follow(ACenter: TSdlFPoint): TSdlFPoint;
    procedure Call;
    procedure RunCalls(AStruck: Boolean);
    procedure TakeOff(const AOrb: TMoonOrb; AFlightTicks: Single);
    procedure Show(const AOrb: TMoonOrb);
    procedure Fly(const AOrb: TMoonOrb; AHeroStep: TSdlFPoint);
    procedure KeepSeat(const AOrb: TMoonOrb; AHeroStep: TSdlFPoint);
    procedure Converge(const AOrb: TMoonOrb; AHeroStep: TSdlFPoint);
    procedure Lead(const AOrb: TMoonOrb; AHeroStep: TSdlFPoint);
    procedure Finish;
  public
    // ABody is asked once, as the orbs begin to draw in; with none every
    // orb goes in at the chest
    constructor Create(const ABody: TBodyProbe);
    destructor Destroy; override;
    // The rite begins about the hero's center: its orbs off the faces of
    // AMatter and out of the points of ADeep, which may be none. One
    // already going is dropped.
    procedure Start(const APattern: TOrbPattern; const AScore: TMoonRiteScore;
      ACenter: TSdlFPoint; const AMatter: TMatter;
      const ADeep: TArray<TSdlFPoint>);
    // Once a tick, with the hero's center where the tick has left him
    procedure Tick(ACenter: TSdlFPoint; const ABeat: TRiteBeat);
    // Every orb goes into him; the calls not made yet are never made
    procedure DrawIn;
    // What has come to pass since the last call, the oldest first
    function DrainEvent: TMoonRiteEvent;
    // The hero is dead: every orb draws into its point, the rite is over
    procedure Collapse;
    procedure Clear;
    procedure DrawBehind(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawInFront(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // The seats of the ring: 0 before a start
    function Count: Integer;
    // The orbs that have reached their seats since the start; it only grows
    property Gathered: Integer read FGathered;
    property Stage: TMoonRiteStage read FStage;
    property Flock: TOrbFlock read FFlock;
  end;

const
  // About 0.18 s down to 0.03 s: some 4.5 s of calls at the heart's pace,
  // the rings full a second later
  MoonRiteScore: TMoonRiteScore = (FirstGap: 6; LastGap: 1; GapStep: 0.8;
    DeepEvery: 3; Nearest: 112; CollapseTicks: 30);

implementation

uses
  System.Math;

const
  // An orb shows through in this many ticks, rising out of the matter
  // along the face's normal from under it to over it
  ShowTicks = 5;
  SunkDepth = 3;
  RiseHeight = 6;
  MarkTick = 2; // of its showing through: the face gets its mark

  // A flight takes this long and a tick more for every FlightPace units the
  // orb was called from, but no longer than FlightLongest
  FlightBaseTicks = 10;
  FlightPace = 12;
  FlightLongest = 30;
  DeepFlightTicks = 34;
  // A flight turns about the hero by this many half-laps and up to this
  // many more, either way
  SweepBase = 0.25;
  SweepSpread = 0.25;

  // Out of the depth an orb is born this small and dim
  DeepBirthSize = 0.15;
  DeepBirthLight = 0.35;
  BehindDepth = -1;

  // The calls aim a golden angle apart, radians: one after another they
  // come from far round the hero, and no two turns ever come round again
  GoldenTurn = 2.39996323;
  // On a thump the ring draws in by this share and its orbs swell by this
  RingDrawIn = 0.12;
  SeatSwell = 0.15;

  // An orb waits up to WaitShare of the drawing in, then takes LengthBase
  // of it and up to LengthSpread more
  WaitShare = 0.45;
  LengthBase = 0.35;
  LengthSpread = 0.2;
  // It shrinks by this share as it draws in, and its light comes up
  ShrinkShare = 0.65;

  DiceSeed = $4D6F6F6E; // "Moon"

function UpToOne(AShare: Single): Single;
begin
  Result := EnsureRange(AShare, 0, 1);
end;

// The short way round from one turn to the other, radians
function TurnApart(AFrom, ATo: Single): Single;
begin
  Result := Abs(ArcTan2(Sin(ATo - AFrom), Cos(ATo - AFrom)));
end;

// ---------------------------------------------------------------------------
// TMoonRite
// ---------------------------------------------------------------------------

constructor TMoonRite.Create(const ABody: TBodyProbe);
begin
  inherited Create;
  FFlock := TOrbFlock.Create(MoonOrbTint);
  FBodyOf := ABody;
  FEvents := TList<TMoonRiteEvent>.Create;
  FRandom.Seed := DiceSeed;
end;

destructor TMoonRite.Destroy;
begin
  FEvents.Free;
  FFlock.Free;
  inherited;
end;

function TMoonRite.MoonOrb(AIndex: Integer): TMoonOrb;
begin
  Result := FFlock.Orbs[AIndex] as TMoonOrb;
end;

function TMoonRite.Count: Integer;
begin
  Result := PatternWaves * FPattern.PerWave;
end;

// The seat of the number in the ring as it beats: the pattern's seat drawn
// in toward the hero with the pulse
function TMoonRite.SeatOf(ANumber: Integer): TPatternSeat;
begin
  Result := FPattern.Seat(ANumber mod PatternWaves, ANumber div PatternWaves,
    FPattern.PerWave, FFlow);
  var Drawn: Single := 1 - RingDrawIn * FPulse;
  Result.X := Result.X * Drawn;
  Result.Y := Result.Y * Drawn;
end;

procedure TMoonRite.Start(const APattern: TOrbPattern;
  const AScore: TMoonRiteScore; ACenter: TSdlFPoint; const AMatter: TMatter;
  const ADeep: TArray<TSdlFPoint>);
begin
  Clear;
  FPattern := APattern;
  FScore := AScore;
  FHeroCenter := ACenter;
  FDeep := ADeep;
  SetLength(FSeatTaken, Count);
  FFirstTurn := FRandom.NextUnit * 2 * Pi;

  var DeepCount := 0;
  if (Length(FDeep) > 0) and (FScore.DeepEvery > 0) then
    DeepCount := Count div FScore.DeepEvery;
  var FaceCount := Count - DeepCount;
  if FaceCount > 0 then
    FFaces := HarvestAfar(AMatter, ACenter, FaceCount, FScore.Nearest,
      FRandom);
  SetLength(FFaceTaken, Length(FFaces));

  FGap := FScore.FirstGap;
  // The first call comes with the first tick
  FSinceCall := FGap - 1;
  FStage := mgGathering;
end;

function TMoonRite.CallsDeep: Boolean;
begin
  Result := (Length(FDeep) > 0) and (FScore.DeepEvery > 0) and
    ((FCalled + 1) mod FScore.DeepEvery = 0);
end;

// The face whose turn about the hero is nearest ATurn, one not taken yet
// before one that is
function TMoonRite.NearestFace(ATurn: Single): Integer;
begin
  Result := -1;
  var Best: Single := MaxSingle;
  for var Pass := 0 to 1 do
  begin
    for var i := 0 to High(FFaces) do
    begin
      if (Pass = 0) and FFaceTaken[i] then
        Continue;
      var Apart := TurnApart(ATurn, FFaces[i].Turn);
      if Apart < Best then
      begin
        Best := Apart;
        Result := i;
      end;
    end;
    if Result >= 0 then
      Exit;
  end;
end;

// Under the face on the side of its seat: an orb from the left sits on the
// left of the ring
function TMoonRite.FaceOrb(ANumber: Integer): TMoonOrb;
begin
  var Seat := SeatOf(ANumber);
  var Face := NearestFace(ArcTan2(Seat.Y, Seat.X));
  var Spot: TFaceSpot := Default(TFaceSpot);
  Spot.X := FHeroCenter.X + Seat.X;
  Spot.Y := FHeroCenter.Y + Seat.Y;
  if Face >= 0 then
  begin
    FFaceTaken[Face] := True;
    Spot := FFaces[Face];
  end;

  Result := TMoonOrb.Create(Spot.X - Spot.NormalX * SunkDepth,
    Spot.Y - Spot.NormalY * SunkDepth);
  Result.FSpot := Spot;
  Result.FStage := moShowing;
  Result.Size := 0;
  Result.Level := 0;
end;

function TMoonRite.DeepOrb(ANumber: Integer): TMoonOrb;
begin
  var From := FDeep[Trunc(FRandom.NextUnit * Length(FDeep))];
  Result := TMoonOrb.Create(From.X, From.Y);
  Result.FDeep := True;
  Result.Size := DeepBirthSize;
  Result.Level := DeepBirthLight;
  Result.Depth := BehindDepth;
  TakeOff(Result, DeepFlightTicks);
end;

// The rings turn, the outer one against the inner, so a seat's place in the
// figure says nothing of where it stands now: the free seat is found by its
// turn this tick
function TMoonRite.NearestFreeSeat(ATurn: Single): Integer;
begin
  Result := -1;
  var Best: Single := MaxSingle;
  for var i := 0 to Count - 1 do
  begin
    if FSeatTaken[i] then
      Continue;
    var Seat := SeatOf(i);
    var Apart := TurnApart(ATurn, ArcTan2(Seat.Y, Seat.X));
    if Apart < Best then
    begin
      Best := Apart;
      Result := i;
    end;
  end;
end;

procedure TMoonRite.Call;
begin
  var Number := NearestFreeSeat(FFirstTurn + FCalled * GoldenTurn);
  FSeatTaken[Number] := True;
  var Orb: TMoonOrb;
  if CallsDeep then
    Orb := DeepOrb(Number)
  else
    Orb := FaceOrb(Number);
  Orb.FNumber := Number;
  Orb.Armed := False;
  FFlock.Add(Orb);
  Inc(FCalled);
end;

// The pace quickens on the beats only: between two of them the calls come
// at an even gap. The wait starts anew from each call: a part of a tick
// carried over would bring the next call on early once a beat has made the
// gap shorter, under the last gap
procedure TMoonRite.RunCalls(AStruck: Boolean);
begin
  if AStruck then
  begin
    var Shorter: Single := FGap * FScore.GapStep;
    FGap := Max(FScore.LastGap, Shorter);
  end;
  FSinceCall := FSinceCall + 1;
  if (FCalled >= Count) or (FSinceCall < FGap) then
    Exit;
  FSinceCall := 0;
  Call;
end;

// The hero's place of this tick becomes the one remembered, and his step
// from the last one is the result
function TMoonRite.Follow(ACenter: TSdlFPoint): TSdlFPoint;
begin
  Result.X := ACenter.X - FHeroCenter.X;
  Result.Y := ACenter.Y - FHeroCenter.Y;
  FHeroCenter := ACenter;
end;

procedure TMoonRite.TakeOff(const AOrb: TMoonOrb; AFlightTicks: Single);
begin
  AOrb.FStage := moFlying;
  AOrb.FStageAge := 0;
  AOrb.FTakeoff.X := AOrb.X;
  AOrb.FTakeoff.Y := AOrb.Y;
  AOrb.FFlightTicks := AFlightTicks;
  var Sweep: Single := Pi * (SweepBase + SweepSpread * FRandom.NextUnit);
  if FRandom.NextUnit < 0.5 then
    Sweep := -Sweep;
  AOrb.FSweep := Sweep;
end;

// Out of the matter along the normal of its face; a spot in thin air has
// no normal, and its orb shows through where it is. Shown, it is off at
// once.
procedure TMoonRite.Show(const AOrb: TMoonOrb);
begin
  var Risen := UpToOne(AOrb.FStageAge / ShowTicks);
  var Height: Single := (SunkDepth + RiseHeight) * Risen - SunkDepth;
  AOrb.MoveTo(AOrb.FSpot.X + AOrb.FSpot.NormalX * Height,
    AOrb.FSpot.Y + AOrb.FSpot.NormalY * Height);

  var OnFace := (AOrb.FSpot.NormalX <> 0) or (AOrb.FSpot.NormalY <> 0);
  if OnFace and (AOrb.FStageAge = MarkTick) then
    FFlock.MarkFace(AOrb.FSpot.X, AOrb.FSpot.Y, AOrb.FSpot.NormalX,
      AOrb.FSpot.NormalY);

  AOrb.Size := Risen;
  AOrb.Level := Risen;
  if Risen < 1 then
    Exit;
  var Away: Single := Hypot(AOrb.X - FHeroCenter.X, AOrb.Y - FHeroCenter.Y);
  var Flight: Single := FlightBaseTicks + Away / FlightPace;
  if Flight > FlightLongest then
    Flight := FlightLongest;
  TakeOff(AOrb, Flight);
end;

// A spiral about the hero from where it took off to its seat. One out of
// the depth grows from a speck and comes out from behind him on the way.
procedure TMoonRite.Fly(const AOrb: TMoonOrb; AHeroStep: TSdlFPoint);
begin
  var Flown := UpToOne(AOrb.FStageAge / AOrb.FFlightTicks);
  var Eased := EasedInOut(Flown);
  var Seat := SeatOf(AOrb.FNumber);
  var Place := SpiralTo(AOrb.FTakeoff, FHeroCenter, Seat, AOrb.FSweep, Eased);
  AOrb.MoveBeside(Place.X, Place.Y, AHeroStep.X * Eased, AHeroStep.Y * Eased);

  if AOrb.FDeep then
  begin
    var Grown := Sqr(Eased);
    AOrb.Size := DeepBirthSize + (1 - DeepBirthSize) * Grown;
    AOrb.Level := DeepBirthLight + (Seat.Level - DeepBirthLight) * Grown;
    AOrb.Depth := BehindDepth + (Seat.Depth - BehindDepth) * Eased;
  end
  else
  begin
    AOrb.Size := 1;
    AOrb.Level := 1 + (Seat.Level - 1) * Eased;
    AOrb.Depth := Seat.Depth * Eased;
  end;

  if Flown < 1 then
    Exit;
  AOrb.FStage := moSeated;
  AOrb.FStageAge := 0;
  Inc(FGathered);
end;

procedure TMoonRite.KeepSeat(const AOrb: TMoonOrb; AHeroStep: TSdlFPoint);
begin
  var Seat := SeatOf(AOrb.FNumber);
  AOrb.MoveBeside(FHeroCenter.X + Seat.X, FHeroCenter.Y + Seat.Y,
    AHeroStep.X, AHeroStep.Y);
  AOrb.Depth := Seat.Depth;
  AOrb.Size := 1 + SeatSwell * FPulse;
  AOrb.Level := Seat.Level;
end;

// From its seat into the hero, to its own point of his body. One that has
// gone in stays there, at its smallest and brightest, until the rite is
// through.
procedure TMoonRite.Converge(const AOrb: TMoonOrb; AHeroStep: TSdlFPoint);
begin
  var Entered := UpToOne((FAge - FDrawInAt - AOrb.FWait) / AOrb.FLength);
  var Seat := SeatOf(AOrb.FNumber);
  var Place := DrawnInto(Seat, AOrb.FEntry, Entered, AOrb.FSide);
  AOrb.MoveBeside(FHeroCenter.X + Place.X, FHeroCenter.Y + Place.Y,
    AHeroStep.X, AHeroStep.Y);
  AOrb.Depth := Place.Depth;
  AOrb.Size := 1 - ShrinkShare * Entered;
  AOrb.Level := Seat.Level + (1 - Seat.Level) * Entered;
end;

procedure TMoonRite.Lead(const AOrb: TMoonOrb; AHeroStep: TSdlFPoint);
begin
  Inc(AOrb.FStageAge);
  case AOrb.FStage of
    moShowing:
      Show(AOrb);
    moFlying:
      Fly(AOrb, AHeroStep);
    moSeated:
      KeepSeat(AOrb, AHeroStep);
    moDrawingIn:
      Converge(AOrb, AHeroStep);
  end;
end;

procedure TMoonRite.Tick(ACenter: TSdlFPoint; const ABeat: TRiteBeat);
begin
  FFlock.Tick;
  if FStage = mgIdle then
    Exit;

  var HeroStep := Follow(ACenter);
  FPulse := ABeat.Pulse;
  FFlow := FFlow + 1;
  if FStage = mgGathering then
    RunCalls(ABeat.Struck);

  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := MoonOrb(i);
    if Orb.State = osAlive then
      Lead(Orb, HeroStep);
  end;

  if (FStage = mgGathering) and (FGathered >= Count) then
  begin
    FStage := mgRinged;
    FEvents.Add(mvFull);
  end;
  if (FStage = mgDrawingIn) and (FAge - FDrawInAt >= FScore.CollapseTicks) then
    Finish;
  Inc(FAge);
end;

// The body is taken as it stands now: the points stay where they are from
// the hero's center while the orbs draw in
procedure TMoonRite.DrawIn;
begin
  if FStage in [mgIdle, mgDrawingIn] then
    Exit;
  FStage := mgDrawingIn;
  FDrawInAt := FAge;
  var Body: TBodyPoints := nil;
  if Assigned(FBodyOf) then
    Body := FBodyOf();
  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := MoonOrb(i);
    Orb.FStage := moDrawingIn;
    Orb.FStageAge := 0;
    Orb.FEntry := BodyEntry(Body, FHeroCenter, FRandom);
    Orb.FWait := FRandom.NextUnit * WaitShare * FScore.CollapseTicks;
    Orb.FLength := (LengthBase + LengthSpread * FRandom.NextUnit) *
      FScore.CollapseTicks;
    Orb.FSide := 1;
    if FRandom.NextUnit < 0.5 then
      Orb.FSide := -1;
  end;
  FEvents.Add(mvDrawingIn);
end;

// Every orb is in the body by now: all of them go at once
procedure TMoonRite.Finish;
begin
  for var Orb in FFlock.Orbs do
    FFlock.Release(Orb);
  FStage := mgIdle;
  FEvents.Add(mvFinished);
end;

function TMoonRite.DrainEvent: TMoonRiteEvent;
begin
  if FEvents.Count = 0 then
    Exit(mvNone);
  Result := FEvents[0];
  FEvents.Delete(0);
end;

procedure TMoonRite.Collapse;
begin
  for var Orb in FFlock.Orbs do
    FFlock.Implode(Orb);
  FStage := mgIdle;
end;

procedure TMoonRite.Clear;
begin
  FFlock.Clear;
  FEvents.Clear;
  FPattern := Default(TOrbPattern);
  FFaces := nil;
  FFaceTaken := nil;
  FSeatTaken := nil;
  FDeep := nil;
  FStage := mgIdle;
  FAge := 0;
  FFlow := 0;
  FPulse := 0;
  FCalled := 0;
  FGathered := 0;
  FDrawInAt := 0;
end;

procedure TMoonRite.DrawBehind(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  FFlock.DrawLayer(ACanvas, AOrigin, AAlpha, olBehind);
end;

procedure TMoonRite.DrawInFront(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  FFlock.DrawLayer(ACanvas, AOrigin, AAlpha, olInFront);
end;

end.
