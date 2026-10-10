{
  Orbs.Rite - the rite of orbs: the choreographer of the henshin. Three
  waves of orbs are drawn out of the matter around the hero, each from all
  sides: they show through on a face, hang over it, fly to their seats in
  a pattern about him (Orbs.Patterns) and sit there. The pattern hangs in
  the air for a while, quickens, stands still and flashes, and then every
  orb draws into him, each in its own time and at its own point of his
  body. The hero keeps his controls throughout; the pattern stands in his
  frame, with no leash.

  An orb is armed only in flight, from its face to its seat: what it
  strikes then is the game's to settle, through the flock. A seated orb is
  a decoration. An orb struck down in flight is replaced from the same
  face, armed while the rite's stock of stand-ins lasts, unarmed after; so
  the pattern has no holes.

  The suit comes off the way it went on, in orbs: each comes out of its own
  point of the hero's body into the pattern, then closes into a ring about
  him that shields him a while and goes out, orb by orb. Here every orb is
  armed from its first tick, and one struck down is not replaced: the ring
  is left gapped on the side the blow came from.

  What passes is told to the listener by events, the oldest first. Where
  the orbs are and when they come and go is the rite's; what it means for
  the hero - the cure, the mercy, the suit - is the listener's. A suit shed
  tells nothing: it ends of itself, and the stage goes back to idle.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Rite;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics,
  Orbs.Flock, Orbs.Harvest, Orbs.Patterns;

type
  // Ticks
  TRiteScore = record
    WaveGap: Integer; // between the calls of the waves
    WaveSpan: Integer; // from a wave's call to its last seat
    HoverTicks: Integer;
    FreezeTicks: Integer; // the last of the hover: the flow stands still
    CollapseTicks: Integer;
    StandIns: Integer; // armed stand-ins for the whole rite
    ShedTicks: Integer; // the ring of a suit shed stands this long
    ShedSpread: Integer; // and up to this much longer, each orb its own
  end;

  TRiteStage = (rsIdle, rsGathering, rsHovering, rsCollapsing, rsShedding);

  TRiteEvent = (reNone, reWaveCalled, reWaveSeated, rePaused, reCollapsing,
    reFinished);

  // How far a called orb has come: it shows through on a face, hangs over
  // it, flies to its seat, sits in it, and at the end draws into the hero.
  // A late stand-in has no face to show through on: it thickens at its
  // seat. An orb of a suit shed has one stage for its whole life: out of the
  // body, in the pattern, in the ring.
  TRiteOrbStage = (roEmerging, roHovering, roFlying, roSeated, roCondensing,
    roCollapsing, roShedding);

  // The points of the hero's body as it stands on the screen, in screen
  // units
  TBodyPoints = TArray<TSdlFPoint>;
  TBodyProbe = reference to function: TBodyPoints;

  TRiteOrb = class(TOrb)
  private
    FWave: Integer;
    FNumber: Integer; // in the wave
    FSpot: TFaceSpot; // where matter gives it up
    FStage: TRiteOrbStage;
    FStageAge: Integer; // ticks
    FBattle: Boolean; // armed in flight
    FSway: Single; // where in its sway over the face it began, radians
    FHangTicks: Integer;
    FFlightTicks: Single;
    FLandAt: Integer; // the rite's tick its flight is due to end
    FTakeoff: TSdlFPoint; // where its flight began
    // The turn about the hero its flight makes, radians
    FSweep: Single;
    // Its drawing into the hero: it waits, then takes this long, winding
    // to one side
    FWait: Single;
    FLength: Single;
    FSide: Single; // 1 or -1
    FEntry: TSdlFPoint; // where it goes into him, from his center
    FFadeAt: Integer; // the shed's tick it draws in at, its own
  end;

  // An orb the rite has called and does not yet see born
  TRiteBirth = record
    Wave: Integer;
    Number: Integer;
    Spot: TFaceSpot;
    Born: Integer; // the rite's tick
    HangTicks: Integer;
    FlightTicks: Single;
    Battle: Boolean; // armed in flight
    // No face and no flight: it thickens at its seat
    Condensing: Boolean;
  end;

  // The face spots of every wave, by wave and then by number
  TRiteSpots = TArray<TArray<TFaceSpot>>;

  TOrbRite = class
  private
    FFlock: TOrbFlock;
    FBodyOf: TBodyProbe;
    FPattern: TOrbPattern;
    FScore: TRiteScore;
    FStage: TRiteStage;
    // The rite's own tick: 0 at the first Tick after Start
    FAge: Integer;
    // The pattern's own clock, ticks, and where it stood a tick ago
    FFlow: Single;
    FFlowBefore: Single;
    // 0..1, at its top as the flow stands still
    FFlash: Single;
    FSpots: TRiteSpots;
    FBirths: TList<TRiteBirth>;
    FEvents: TList<TRiteEvent>;
    FStandIns: Integer; // armed ones left
    // The hero's center as the last Tick had it
    FHeroCenter: TSdlFPoint;
    FLeapt: Boolean; // the hero leapt this tick
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function RiteOrb(AIndex: Integer): TRiteOrb;
    function PauseAt: Integer;
    function CollapseAt: Integer;
    function FinishAt: Integer;
    function FlowStep: Single;
    function FlashAt(ATick: Integer): Single;
    function FlightOf(AAway: Single): Single;
    function SeatFor(AWave, ANumber: Integer): TPatternSeat;
    function SeatLeapt(const AOrb: TRiteOrb): Boolean;
    function BirthAt(AWave, ANumber, ABorn: Integer): TRiteBirth;
    function StandInFor(const ASpent: TRiteOrb): TRiteBirth;
    function NewOrb(const ABirth: TRiteBirth): TRiteOrb;
    function Follow(ACenter: TSdlFPoint): TSdlFPoint;
    function EntryIn(const ABody: TBodyPoints): TSdlFPoint;
    function RingSeat(AWave, ANumber: Integer): TSdlFPoint;
    function ShedOrb(AWave, ANumber: Integer;
      const AEntry: TSdlFPoint): TRiteOrb;
    procedure CallWave(AWave: Integer);
    procedure ReplaceSpent;
    procedure BeBorn;
    procedure FlushBirths;
    procedure RunSchedule;
    procedure BeginHover;
    procedure BeginCollapsing;
    procedure Finish;
    procedure Shine(const AOrb: TRiteOrb; ASize, ALight: Single);
    procedure Lead(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
    procedure Emerge(const AOrb: TRiteOrb);
    procedure Hover(const AOrb: TRiteOrb);
    procedure TakeOff(const AOrb: TRiteOrb);
    procedure Rewind(const AOrb: TRiteOrb);
    procedure Fly(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
    procedure Land(const AOrb: TRiteOrb);
    procedure KeepSeat(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
    procedure Condense(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
    procedure Converge(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
    procedure Shield(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
    procedure TickShed(ACenter: TSdlFPoint);
  public
    // ABody is asked once a rite, as the orbs begin to draw in; with
    // none every orb goes in at the chest
    constructor Create(const ATint: TOrbTint; const ABody: TBodyProbe);
    destructor Destroy; override;
    // The rite begins about the hero's center, on the matter of his
    // screen. One already going is dropped.
    procedure Start(const APattern: TOrbPattern; const AScore: TRiteScore;
      ACenter: TSdlFPoint; const AMatter: TMatter);
    // The suit gives its orbs back: every one comes out of its own point of
    // the hero's body - asked as the collapse asks it - into the pattern,
    // then a ring about him that stands a while and goes out. One already
    // going is dropped.
    procedure Shed(const APattern: TOrbPattern; const AScore: TRiteScore;
      ACenter: TSdlFPoint);
    // Once a tick, with the hero's center where the tick has left it
    procedure Tick(ACenter: TSdlFPoint);
    // What has come to pass since the last call, the oldest first
    function DrainEvent: TRiteEvent;
    // The hero has gone through a door and is this far from where he
    // was: the rite crosses with him, and nobody flies anywhere. An orb
    // still on its face leaves it at once: the face stays on the screen
    // behind.
    procedure Carry(AStepX, AStepY: Single);
    // The hero is dead: every orb draws into its point, the rite is over
    procedure Collapse;
    procedure Clear;
    // The orbs behind the hero, with the marks of the faces, and the
    // orbs in front of him, with the dust
    procedure DrawBehind(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawInFront(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // What the orbs strike is the game's to settle
    property Flock: TOrbFlock read FFlock;
    property Stage: TRiteStage read FStage;
  end;

const
  IceRiteScore: TRiteScore = (WaveGap: 22; WaveSpan: 56; HoverTicks: 32;
    FreezeTicks: 9; CollapseTicks: 22; StandIns: 24; ShedTicks: 100;
    ShedSpread: 33);

implementation

uses
  System.Math;

const
  // An orb shows through in this many ticks: it grows to its size and
  // rises out of the matter along the face's normal
  AppearTicks = 8;
  // Units under its face it begins at, and over it it hangs at
  SunkDepth = 3;
  HoverHeight = 6;
  MarkTick = 2; // of its showing through: the face gets its mark
  // Hanging, an orb sways toward its face and away
  SwayDepth = 1.2; // units either way
  SwayPace = 0.35; // radians of the sway a tick
  SwaySpread = 6; // radians: each orb begins its sway somewhere in these

  // An orb is born 0..BirthSpreadTicks - 1 ticks after its wave is called
  // and hangs HangBaseTicks and 0..HangSpreadTicks - 1 more before it
  // takes off
  BirthSpreadTicks = 3;
  HangBaseTicks = 4;
  HangSpreadTicks = 4;

  // A flight takes this long and a tick more for every FlightPace units
  // the orb was called from, but ends this long before its wave's term
  FlightBaseTicks = 18;
  FlightPace = 9;
  FlightMargin = 16;
  // A flight turns about the hero by this many half-laps, and up to this
  // many more, each orb its own; the middle wave turns the other way
  SweepBase = 0.5;
  SweepSpread = 0.4;

  // Farther in one tick than the hero's body goes: the return from a pit
  LeapStep = 24;
  LeapFlightTicks = 6;

  // An orb struck down is replaced this many ticks later. One that cannot
  // sit before the pause is hurried when the pause is this far off or
  // farther - it leaves its face this long after its birth and sits as the
  // pause begins - and thickens in place when it is nearer.
  StandInDelayTicks = 2;
  HurryLimitTicks = 20;
  HurriedTakeoffTicks = 10;
  CondenseTicks = 8;

  // A seat that keeps to its figure goes no farther than this in a tick;
  // farther, and it has run off the end of the figure and begun it anew
  SeatLeap = 24;

  // The flow quickens through the hover by this much
  HoverQuickening = 0.8;
  // The flash of the freeze, in ticks from the rite's collapse: its
  // window, where its top is and how wide it is
  FlashFromTicks = -4;
  FlashUntilTicks = 8;
  FlashPeakTicks = -3;
  FlashWidthTicks = 3;
  FlashLight = 0.7;
  FlashSize = 0.12;
  // What depth does to an orb: its size grows by this share of the depth
  // - which is 1 in front of the hero and -1 behind him - and its light
  // is this at the far side of the pattern and this much more for every
  // unit of depth toward the near side
  DepthSize = 0.18;
  DepthLightFar = 0.72;
  DepthLightStep = 0.14;

  // A body that gives no points is entered at the chest, this far from
  // its middle
  ChestY = -2;
  // An orb waits up to WaitShare of the drawing in, then takes LengthBase
  // of it and up to LengthSpread more, winding up to WindTurn radians on
  // the way
  WaitShare = 0.45;
  LengthBase = 0.35;
  LengthSpread = 0.2;
  WindTurn = 1.3;
  // An orb shrinks by this share of its size as it draws in, and its light
  // comes up to LightPeak
  ShrinkShare = 0.65;
  LightPeak = 1.15;

  // A suit shed, in ticks from its start: an orb comes out of its point of
  // the body in ShedExitTicks, stands in the pattern until ShedHoldUntil
  // and has closed into the ring by ShedRingUntil. It leaves the body at
  // this size and light. The ring is an oval, as the aura's is: its
  // half-axes, and the ticks it takes to flow once around.
  ShedExitTicks = 6;
  ShedHoldUntil = 12;
  ShedRingUntil = 26;
  ShedExitSize = 0.5;
  ShedExitLight = 0.6;
  RingRadiusX = 28;
  RingRadiusY = 35;
  RingLapTicks = 330;

  DiceSeed = $52697465; // "Rite"

function Shifted(APoint: TSdlFPoint; AStepX, AStepY: Single): TSdlFPoint;
begin
  Result.X := APoint.X + AStepX;
  Result.Y := APoint.Y + AStepY;
end;

// The vector turned by ATurn radians, as the picture turns: Y grows
// downward
function Rotated(AX, AY, ATurn: Single): TSdlFPoint;
begin
  Result.X := AX * Cos(ATurn) - AY * Sin(ATurn);
  Result.Y := AX * Sin(ATurn) + AY * Cos(ATurn);
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

// ---------------------------------------------------------------------------
// TOrbRite
// ---------------------------------------------------------------------------

constructor TOrbRite.Create(const ATint: TOrbTint; const ABody: TBodyProbe);
begin
  inherited Create;
  FFlock := TOrbFlock.Create(ATint);
  FBodyOf := ABody;
  FBirths := TList<TRiteBirth>.Create;
  FEvents := TList<TRiteEvent>.Create;
  FRandom.Seed := DiceSeed;
end;

destructor TOrbRite.Destroy;
begin
  FEvents.Free;
  FBirths.Free;
  FFlock.Free;
  inherited;
end;

function TOrbRite.RiteOrb(AIndex: Integer): TRiteOrb;
begin
  Result := FFlock.Orbs[AIndex] as TRiteOrb;
end;

// The last wave's seat is the pause
function TOrbRite.PauseAt: Integer;
begin
  Result := (PatternWaves - 1) * FScore.WaveGap + FScore.WaveSpan;
end;

function TOrbRite.CollapseAt: Integer;
begin
  Result := PauseAt + FScore.HoverTicks;
end;

function TOrbRite.FinishAt: Integer;
begin
  Result := CollapseAt + FScore.CollapseTicks;
end;

// How far the pattern's clock goes this tick: a tick, then quicker through
// the hover, then slower to a stand through the freeze
function TOrbRite.FlowStep: Single;
begin
  if FAge < PauseAt then
    Exit(1);
  if FAge >= CollapseAt then
    Exit(0);

  Result := 1 + HoverQuickening * (FAge - PauseAt) / FScore.HoverTicks;
  if FAge >= CollapseAt - FScore.FreezeTicks then
    Result := Result * Sqr((CollapseAt - FAge) / FScore.FreezeTicks);
end;

function TOrbRite.FlashAt(ATick: Integer): Single;
begin
  var Since := ATick - CollapseAt;
  if (Since < FlashFromTicks) or (Since > FlashUntilTicks) then
    Exit(0);
  Result := Exp(-Sqr((Since - FlashPeakTicks) / FlashWidthTicks));
end;

function TOrbRite.FlightOf(AAway: Single): Single;
begin
  Result := FlightBaseTicks + AAway / FlightPace;
  var Longest: Single := FScore.WaveSpan - FlightMargin;
  if Result > Longest then
    Result := Longest;
end;

function TOrbRite.SeatFor(AWave, ANumber: Integer): TPatternSeat;
begin
  Result := FPattern.Seat(AWave, ANumber, FPattern.PerWave, FFlow);
end;

function TOrbRite.SeatLeapt(const AOrb: TRiteOrb): Boolean;
begin
  var Seat := SeatFor(AOrb.FWave, AOrb.FNumber);
  var Before := FPattern.Seat(AOrb.FWave, AOrb.FNumber, FPattern.PerWave,
    FFlowBefore);
  Result := Hypot(Seat.X - Before.X, Seat.Y - Before.Y) > SeatLeap;
end;

// The orb of the spot, born ABorn ticks into the rite, as a wave's orb
// is: it shows through, hangs a few ticks and flies the whole way
function TOrbRite.BirthAt(AWave, ANumber, ABorn: Integer): TRiteBirth;
begin
  Result.Wave := AWave;
  Result.Number := ANumber;
  Result.Spot := FSpots[AWave][ANumber];
  Result.Born := ABorn;
  Result.HangTicks := HangBaseTicks + Trunc(FRandom.NextUnit * HangSpreadTicks);
  Result.FlightTicks := FlightOf(Result.Spot.Away);
  Result.Battle := True;
  Result.Condensing := False;
end;

// The orb struck down in flight is born anew from the same face. One that
// would not sit before the pause is hurried, or - with too little time
// left - thickens at its seat, unarmed.
function TOrbRite.StandInFor(const ASpent: TRiteOrb): TRiteBirth;
begin
  Result := BirthAt(ASpent.FWave, ASpent.FNumber, FAge + StandInDelayTicks);
  var Landing: Single := Result.Born + AppearTicks + Result.HangTicks +
    Result.FlightTicks;
  if Landing > PauseAt then
  begin
    if PauseAt - FAge < HurryLimitTicks then
      Result.Condensing := True
    else
    begin
      Result.HangTicks := HurriedTakeoffTicks - AppearTicks;
      Result.FlightTicks := PauseAt - (Result.Born + HurriedTakeoffTicks);
    end;
  end;

  Result.Battle := not Result.Condensing and (FStandIns > 0);
  if Result.Battle then
    Dec(FStandIns);
end;

// The orb under its face; one that thickens at its seat is born there
function TOrbRite.NewOrb(const ABirth: TRiteBirth): TRiteOrb;
begin
  var Spot := ABirth.Spot;
  var StartX: Single := Spot.X - Spot.NormalX * SunkDepth;
  var StartY: Single := Spot.Y - Spot.NormalY * SunkDepth;
  if ABirth.Condensing then
  begin
    var Seat := SeatFor(ABirth.Wave, ABirth.Number);
    StartX := FHeroCenter.X + Seat.X;
    StartY := FHeroCenter.Y + Seat.Y;
  end;

  Result := TRiteOrb.Create(StartX, StartY);
  Result.FWave := ABirth.Wave;
  Result.FNumber := ABirth.Number;
  Result.FSpot := Spot;
  Result.FStage := roEmerging;
  if ABirth.Condensing then
    Result.FStage := roCondensing;
  Result.FHangTicks := ABirth.HangTicks;
  Result.FFlightTicks := ABirth.FlightTicks;
  Result.FBattle := ABirth.Battle;
  Result.FSway := FRandom.NextUnit * SwaySpread;

  // The middle wave turns against the others
  var Sweep: Single := Pi * (SweepBase + SweepSpread * FRandom.NextUnit);
  if Odd(ABirth.Wave) then
    Sweep := -Sweep;
  Result.FSweep := Sweep;

  Result.FWait := FRandom.NextUnit * WaitShare * FScore.CollapseTicks;
  Result.FLength := (LengthBase + LengthSpread * FRandom.NextUnit) *
    FScore.CollapseTicks;
  Result.FSide := 1;
  if FRandom.NextUnit < 0.5 then
    Result.FSide := -1;

  Result.Size := 0;
  Result.Level := 0;
  Result.Armed := False;
end;

// The hero's place of this tick becomes the one remembered, and his step
// from the last one is the result
function TOrbRite.Follow(ACenter: TSdlFPoint): TSdlFPoint;
begin
  Result.X := ACenter.X - FHeroCenter.X;
  Result.Y := ACenter.Y - FHeroCenter.Y;
  FHeroCenter := ACenter;
  FLeapt := Hypot(Result.X, Result.Y) > LeapStep;
end;

procedure TOrbRite.Start(const APattern: TOrbPattern;
  const AScore: TRiteScore; ACenter: TSdlFPoint; const AMatter: TMatter);
begin
  Clear;
  FPattern := APattern;
  FScore := AScore;
  FSpots := HarvestAround(AMatter, ACenter, APattern.PerWave, PatternWaves,
    FRandom);
  FStandIns := AScore.StandIns;
  FHeroCenter := ACenter;
  FStage := rsGathering;
end;

procedure TOrbRite.CallWave(AWave: Integer);
begin
  for var i := 0 to FPattern.PerWave - 1 do
    FBirths.Add(BirthAt(AWave, i,
      FAge + Trunc(FRandom.NextUnit * BirthSpreadTicks)));
  FEvents.Add(reWaveCalled);
end;

procedure TOrbRite.Shed(const APattern: TOrbPattern; const AScore: TRiteScore;
  ACenter: TSdlFPoint);
begin
  Clear;
  FPattern := APattern;
  FScore := AScore;
  FHeroCenter := ACenter;
  var Body: TBodyPoints := nil;
  if Assigned(FBodyOf) then
    Body := FBodyOf();
  for var Wave := 0 to PatternWaves - 1 do
    for var Number := 0 to APattern.PerWave - 1 do
      FFlock.Add(ShedOrb(Wave, Number, EntryIn(Body)));
  FStage := rsShedding;
end;

// An orb struck down in flight is still in the flock until the flock's
// next tick: it is looked for before that
procedure TOrbRite.ReplaceSpent;
begin
  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := RiteOrb(i);
    if (Orb.State = osGone) and (Orb.FStage = roFlying) then
      FBirths.Add(StandInFor(Orb));
  end;
end;

procedure TOrbRite.BeBorn;
begin
  for var i := FBirths.Count - 1 downto 0 do
  begin
    if FBirths[i].Born > FAge then
      Continue;
    FFlock.Add(NewOrb(FBirths[i]));
    FBirths.Delete(i);
  end;
end;

procedure TOrbRite.FlushBirths;
begin
  for var Birth in FBirths do
    FFlock.Add(NewOrb(Birth));
  FBirths.Clear;
end;

procedure TOrbRite.RunSchedule;
begin
  for var Wave := 0 to PatternWaves - 1 do
  begin
    if FAge = Wave * FScore.WaveGap then
      CallWave(Wave);
    if FAge = Wave * FScore.WaveGap + FScore.WaveSpan then
      FEvents.Add(reWaveSeated);
  end;
  if FAge = PauseAt then
    BeginHover;
  if FAge = CollapseAt then
    BeginCollapsing;
end;

// Nobody is armed from the pause on: an orb still in flight, a tick short
// of its seat, sits where it is
procedure TOrbRite.BeginHover;
begin
  FStage := rsHovering;
  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := RiteOrb(i);
    if Orb.FStage = roFlying then
      Land(Orb);
  end;
  FEvents.Add(rePaused);
end;

// A point of the body the dice pick, from the hero's center
function TOrbRite.EntryIn(const ABody: TBodyPoints): TSdlFPoint;
begin
  Result.X := 0;
  Result.Y := ChestY;
  if Length(ABody) = 0 then
    Exit;
  var Pick := Trunc(FRandom.NextUnit * Length(ABody));
  Result.X := ABody[Pick].X - FHeroCenter.X;
  Result.Y := ABody[Pick].Y - FHeroCenter.Y;
end;

// Where the orb of this place in the pattern stands in the ring: the
// places of all the waves, in order, share the oval evenly, and it flows
// slowly about the hero
function TOrbRite.RingSeat(AWave, ANumber: Integer): TSdlFPoint;
begin
  var Place := AWave * FPattern.PerWave + ANumber;
  var Turn: Single := 2 * Pi * (Place / (PatternWaves * FPattern.PerWave) +
    FFlow / RingLapTicks);
  Result.X := RingRadiusX * Cos(Turn);
  Result.Y := RingRadiusY * Sin(Turn);
end;

// The orb of a suit shed, at its point of the body: armed from the first
// tick, and drawn in when its own time is up
function TOrbRite.ShedOrb(AWave, ANumber: Integer;
  const AEntry: TSdlFPoint): TRiteOrb;
begin
  Result := TRiteOrb.Create(FHeroCenter.X + AEntry.X,
    FHeroCenter.Y + AEntry.Y);
  Result.FWave := AWave;
  Result.FNumber := ANumber;
  Result.FStage := roShedding;
  Result.FEntry := AEntry;
  Result.FFadeAt := FScore.ShedTicks +
    Trunc(FRandom.NextUnit * FScore.ShedSpread);
  Result.Size := ShedExitSize;
  Result.Level := ShedExitLight;
  Result.Armed := True;
end;

// The body is taken as it stands now: the points stay where they are
// from the hero's center, whatever he does while the orbs draw in
procedure TOrbRite.BeginCollapsing;
begin
  FStage := rsCollapsing;
  FBirths.Clear;
  var Body: TBodyPoints := nil;
  if Assigned(FBodyOf) then
    Body := FBodyOf();
  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := RiteOrb(i);
    Orb.FStage := roCollapsing;
    Orb.FStageAge := 0;
    Orb.Armed := False;
    Orb.FEntry := EntryIn(Body);
  end;
  FEvents.Add(reCollapsing);
end;

// Every orb is in the body by now, or a hair short of it: all of them
// go at once
procedure TOrbRite.Finish;
begin
  for var Orb in FFlock.Orbs do
    FFlock.Release(Orb);
  FStage := rsIdle;
  FEvents.Add(reFinished);
end;

// The size and the light the orb is drawn with: what its stage gives it,
// and what its depth and the flash of the freeze make of that. Light is a
// share and does not pass the whole, so the flash is carried by the dim
// orbs behind and by the size.
procedure TOrbRite.Shine(const AOrb: TRiteOrb; ASize, ALight: Single);
begin
  AOrb.Size := ASize * (1 + DepthSize * AOrb.Depth) * (1 + FlashSize * FFlash);
  AOrb.Level := UpToOne(ALight *
    (DepthLightFar + DepthLightStep * (AOrb.Depth + 1)) *
    (1 + FlashLight * FFlash));
end;

// Out of the matter along the normal of its face, from under the face
// to where it hangs; a spot in thin air has no normal, and its orb
// shows through where it is
procedure TOrbRite.Emerge(const AOrb: TRiteOrb);
begin
  var Risen := UpToOne(AOrb.FStageAge / AppearTicks);
  var Height: Single := (SunkDepth + HoverHeight) * Risen - SunkDepth;
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
  AOrb.FStage := roHovering;
  AOrb.FStageAge := 0;
end;

procedure TOrbRite.Hover(const AOrb: TRiteOrb);
begin
  var Height: Single := HoverHeight +
    SwayDepth * Sin(AOrb.FStageAge * SwayPace + AOrb.FSway);
  AOrb.MoveTo(AOrb.FSpot.X + AOrb.FSpot.NormalX * Height,
    AOrb.FSpot.Y + AOrb.FSpot.NormalY * Height);
  AOrb.Size := 1;
  AOrb.Level := 1;

  if AOrb.FStageAge >= AOrb.FHangTicks then
    TakeOff(AOrb);
end;

// The orb leaves for its seat from where it is, armed if it is a fighter
procedure TOrbRite.TakeOff(const AOrb: TRiteOrb);
begin
  AOrb.FStage := roFlying;
  AOrb.FStageAge := 0;
  AOrb.FTakeoff.X := AOrb.X;
  AOrb.FTakeoff.Y := AOrb.Y;
  AOrb.FLandAt := FAge + Ceil(AOrb.FFlightTicks);
  AOrb.Armed := AOrb.FBattle;
end;

// The hero is somewhere else: a flight half flown would leap half the way
// with him. It begins anew from where the orb is and is due to end when
// it was, or as soon as a flight may.
procedure TOrbRite.Rewind(const AOrb: TRiteOrb);
begin
  AOrb.FStageAge := 0;
  AOrb.FTakeoff.X := AOrb.X;
  AOrb.FTakeoff.Y := AOrb.Y;
  var Left: Single := AOrb.FLandAt - FAge;
  if Left < LeapFlightTicks then
    Left := LeapFlightTicks;
  AOrb.FFlightTicks := Left;
  AOrb.FLandAt := FAge + Ceil(Left);
end;

// A spiral about the hero: from where the orb took off to its seat, its
// distance from him and its turn about him both eased. The takeoff stands
// where it is while he moves, so the spiral is laid anew from it every
// tick.
procedure TOrbRite.Fly(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
begin
  if FLeapt then
    Rewind(AOrb);

  var Flown := UpToOne(AOrb.FStageAge / AOrb.FFlightTicks);
  var Eased := EasedInOut(Flown);
  var Seat := SeatFor(AOrb.FWave, AOrb.FNumber);
  var Spiral := Rotated(AOrb.FTakeoff.X - FHeroCenter.X,
    AOrb.FTakeoff.Y - FHeroCenter.Y, AOrb.FSweep * Eased);
  // The nearer its seat, the more of the hero's step is the orb's own:
  // that share is no part of what it is drawn on ahead by
  AOrb.MoveBeside(FHeroCenter.X + Spiral.X * (1 - Eased) + Seat.X * Eased,
    FHeroCenter.Y + Spiral.Y * (1 - Eased) + Seat.Y * Eased,
    AHeroStep.X * Eased, AHeroStep.Y * Eased);

  AOrb.Depth := Seat.Depth * Sqr(Eased);
  var Grown := UpToOne(AOrb.Age / AppearTicks);
  Shine(AOrb, Grown, Grown * (1 + (Seat.Level - 1) * Eased));
  if Flown >= 1 then
    Land(AOrb);
end;

procedure TOrbRite.Land(const AOrb: TRiteOrb);
begin
  AOrb.FStage := roSeated;
  AOrb.FStageAge := 0;
  AOrb.Armed := False;
end;

procedure TOrbRite.KeepSeat(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
begin
  var Seat := SeatFor(AOrb.FWave, AOrb.FNumber);
  AOrb.MoveBeside(FHeroCenter.X + Seat.X, FHeroCenter.Y + Seat.Y,
    AHeroStep.X, AHeroStep.Y);
  AOrb.Depth := Seat.Depth;
  Shine(AOrb, 1, Seat.Level);
end;

procedure TOrbRite.Condense(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
begin
  var Seat := SeatFor(AOrb.FWave, AOrb.FNumber);
  AOrb.MoveBeside(FHeroCenter.X + Seat.X, FHeroCenter.Y + Seat.Y,
    AHeroStep.X, AHeroStep.Y);
  AOrb.Depth := Seat.Depth;

  var Grown := UpToOne(AOrb.FStageAge / CondenseTicks);
  Shine(AOrb, Grown, Grown * Seat.Level);
  if Grown >= 1 then
    Land(AOrb);
end;

// From its seat into the hero, to its own point of his body, winding as
// it goes, slowly at first and then all at once. One that has gone in
// stays there, at its smallest and brightest: the body fills with lights,
// orb by orb, until the rite is through.
procedure TOrbRite.Converge(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
begin
  var Entered := UpToOne((FAge - CollapseAt - AOrb.FWait) / AOrb.FLength);
  if Entered < 0 then
    Entered := 0;

  var Seat := SeatFor(AOrb.FWave, AOrb.FNumber);
  var Pull: Single := Entered * Entered * Entered;
  var Entry := AOrb.FEntry;
  var Wound := Rotated(Seat.X - Entry.X, Seat.Y - Entry.Y,
    WindTurn * Sqr(Entered) * AOrb.FSide);
  AOrb.MoveBeside(FHeroCenter.X + Entry.X + Wound.X * (1 - Pull),
    FHeroCenter.Y + Entry.Y + Wound.Y * (1 - Pull), AHeroStep.X, AHeroStep.Y);

  AOrb.Depth := Seat.Depth * (1 - Pull);
  Shine(AOrb, 1 - ShrinkShare * Entered,
    Seat.Level + (LightPeak - Seat.Level) * Entered);
end;

// An orb of a suit shed, by the shed's tick: out of its point of the body to
// its seat, quickest at first, then in the pattern as it stood before the
// collapse, then from its seat into its place in the ring, which it keeps
// in front of the hero until its time is up. Everything stands in the hero's
// frame: a seat that has leapt takes the orb with it, undrawn.
procedure TOrbRite.Shield(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
begin
  var Seat := SeatFor(AOrb.FWave, AOrb.FNumber);
  var Entry := AOrb.FEntry;
  var PlaceX: Single := Seat.X;
  var PlaceY: Single := Seat.Y;
  var Size: Single := 1;
  var Light: Single := Seat.Level;
  var Depth: Single := Seat.Depth;

  if FAge < ShedExitTicks then
  begin
    var Exited: Single := 1 - Sqr(1 - FAge / ShedExitTicks);
    PlaceX := Entry.X + (Seat.X - Entry.X) * Exited;
    PlaceY := Entry.Y + (Seat.Y - Entry.Y) * Exited;
    Size := ShedExitSize + (1 - ShedExitSize) * Exited;
    Light := ShedExitLight + (Seat.Level - ShedExitLight) * Exited;
    Depth := Seat.Depth * Sqr(Exited);
  end
  else if FAge > ShedHoldUntil then
  begin
    var Ringed := EasedInOut(UpToOne((FAge - ShedHoldUntil) /
      (ShedRingUntil - ShedHoldUntil)));
    var Ring := RingSeat(AOrb.FWave, AOrb.FNumber);
    PlaceX := Seat.X + (Ring.X - Seat.X) * Ringed;
    PlaceY := Seat.Y + (Ring.Y - Seat.Y) * Ringed;
    Light := Seat.Level + (1 - Seat.Level) * Ringed;
    Depth := Seat.Depth + (1 - Seat.Depth) * Ringed;
  end;

  AOrb.MoveBeside(FHeroCenter.X + PlaceX, FHeroCenter.Y + PlaceY,
    AHeroStep.X, AHeroStep.Y);
  AOrb.Depth := Depth;
  Shine(AOrb, Size, Light);
  if (FAge <= ShedRingUntil) and SeatLeapt(AOrb) then
    AOrb.Arrive;
  if FAge >= AOrb.FFadeAt then
    FFlock.Implode(AOrb);
end;

// The pattern's clock goes a tick, and every orb is put where its own tick
// has it. Nobody is born and nobody replaced: a ring left gapped stays so.
// With the last orb gone the shed is over.
procedure TOrbRite.TickShed(ACenter: TSdlFPoint);
begin
  FFlock.Tick;
  var HeroStep := Follow(ACenter);
  FFlowBefore := FFlow;
  FFlow := FFlow + 1;

  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := RiteOrb(i);
    if Orb.State = osAlive then
      Shield(Orb, HeroStep);
  end;

  Inc(FAge);
  if FFlock.Orbs.Count = 0 then
    FStage := rsIdle;
end;

procedure TOrbRite.Lead(const AOrb: TRiteOrb; AHeroStep: TSdlFPoint);
begin
  Inc(AOrb.FStageAge);
  case AOrb.FStage of
    roEmerging:
      Emerge(AOrb);
    roHovering:
      Hover(AOrb);
    roFlying:
      Fly(AOrb, AHeroStep);
    roSeated:
      KeepSeat(AOrb, AHeroStep);
    roCondensing:
      Condense(AOrb, AHeroStep);
    roCollapsing:
      Converge(AOrb, AHeroStep);
  end;

  // An orb goes after its seat; behind a seat that has leapt it is not
  // drawn flying, it is there at once
  if (AOrb.FStage in [roFlying, roSeated, roCondensing]) and
    SeatLeapt(AOrb) then
    AOrb.Arrive;
end;

procedure TOrbRite.Tick(ACenter: TSdlFPoint);
begin
  if FStage = rsIdle then
  begin
    FFlock.Tick;
    Exit;
  end;
  if FStage = rsShedding then
  begin
    TickShed(ACenter);
    Exit;
  end;

  ReplaceSpent;
  FFlock.Tick;
  var HeroStep := Follow(ACenter);
  RunSchedule;
  BeBorn;
  FFlowBefore := FFlow;
  FFlow := FFlow + FlowStep;
  FFlash := FlashAt(FAge);

  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := RiteOrb(i);
    if Orb.State = osAlive then
      Lead(Orb, HeroStep);
  end;

  if (FStage = rsCollapsing) and (FAge = FinishAt) then
    Finish;
  Inc(FAge);
end;

function TOrbRite.DrainEvent: TRiteEvent;
begin
  if FEvents.Count = 0 then
    Exit(reNone);
  Result := FEvents[0];
  FEvents.Delete(0);
end;

procedure TOrbRite.Carry(AStepX, AStepY: Single);
begin
  FlushBirths;
  FFlock.Shift(AStepX, AStepY);
  FHeroCenter := Shifted(FHeroCenter, AStepX, AStepY);
  // The faces a stand-in is born on cross with the hero as well
  for var Wave := 0 to High(FSpots) do
    for var i := 0 to High(FSpots[Wave]) do
    begin
      FSpots[Wave][i].X := FSpots[Wave][i].X + AStepX;
      FSpots[Wave][i].Y := FSpots[Wave][i].Y + AStepY;
    end;

  for var i := 0 to FFlock.Orbs.Count - 1 do
  begin
    var Orb := RiteOrb(i);
    Orb.FTakeoff := Shifted(Orb.FTakeoff, AStepX, AStepY);
    if Orb.FStage in [roEmerging, roHovering] then
      TakeOff(Orb);
  end;
end;

procedure TOrbRite.Collapse;
begin
  for var Orb in FFlock.Orbs do
    FFlock.Implode(Orb);
  FBirths.Clear;
  FStage := rsIdle;
end;

procedure TOrbRite.Clear;
begin
  FFlock.Clear;
  FBirths.Clear;
  FEvents.Clear;
  FSpots := nil;
  FStage := rsIdle;
  FAge := 0;
  FFlow := 0;
  FFlowBefore := 0;
  FFlash := 0;
  FLeapt := False;
end;

procedure TOrbRite.DrawBehind(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  FFlock.DrawLayer(ACanvas, AOrigin, AAlpha, olBehind);
end;

procedure TOrbRite.DrawInFront(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  FFlock.DrawLayer(ACanvas, AOrigin, AAlpha, olInFront);
end;

end.
