{
  Pads.Shelf - the cycle of a shelf (Levels.Pads, "shelf"): a pad that
  slides out of the wall behind it and back in by its program. A step
  holds it out or in for its seconds; between two steps it slides. The
  program goes round: after its last step the shelf slides to its first.

  The cycle keeps its run laid out in ticks and nothing else. Where the
  shelf is at a tick of its pad's clock it works out anew every time: a
  pad that stood still off the hero's screen, or was rewound, needs no
  telling.

  A run starts at a tick of the clock: the level file's at the clock's
  start, a run an event tells (Command) at the tick it is told. A told
  run plays its lead once - the warning, the slide from wherever the
  shelf stood - and then goes round its program, from its first step, or
  rests out in front or in the wall for good. Before its tick the shelf
  stands as it stood the tick before: a shelf that is told late keeps to
  its old run until then, and that is up to the pad.

  Out all the way, the shelf holds: it is a floor and a body. From the
  tick it starts in until it is out again it is neither - what stood on
  it falls. Before it starts in it warns. Pads.World asks; the slide is
  drawn there, as the depth of a flying pad is.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.Shelf;
{$I ..\..\Moon2D.inc}

interface

uses
  Levels.Pads;

type
  // Out in front, on its way into the wall, in the wall, on its way out
  TShelfPhase = (spOut, spGoingIn, spIn, spGoingOut);

  TShelfSpan = record
    Phase: TShelfPhase;
    Ticks: Integer;
    // A slide starts this deep: 0 out in front .. 1 in the wall
    From: Double;
  end;

  // To the wall for good, or out and the program
  TShelfCall = (scSleep, scWake);

  // What an event tells a shelf
  TShelfCommand = record
    Call: TShelfCall;
    Run: TShelfProgram; // scWake: the program it runs once out
    // scSleep: a shelf the hero stands on waits until he is off it
    SpareHero: Boolean;
  end;

  // Where a shelf stands at a moment
  TShelfLook = record
    Phase: TShelfPhase;
    Depth: Double;
    Warns: Boolean;
  end;

  // Ticks are those of the pad's clock, from its rewind on
  TShelfCycle = record
  private
    FSlides: Boolean;
    FSlideTicks: Integer;
    FOwnWarnTicks: Integer;
    FWarnTicks: Integer; // of the run
    FOrigin: Integer;
    // Played once from FOrigin on
    FLead: TArray<TShelfSpan>;
    // Then round the program: a step, the slide to the next, and so on;
    // without one the shelf rests in FRest
    FSpans: TArray<TShelfSpan>;
    FCycleTicks: Integer;
    FOffsetTicks: Integer;
    FRest: TShelfPhase;
    // A run an event told: before FOrigin the shelf looks FBefore
    FTold: Boolean;
    FBefore: TShelfLook;
    function SpanAt(ATime: Double; out AInto: Double): TShelfSpan;
    function LookAt(ATime: Double): TShelfLook;
    procedure AddLead(APhase: TShelfPhase; ATicks: Integer; AFrom: Double);
    procedure AddStep(AStand: TShelfStand; AHeldTicks: Integer;
      ANext: TShelfStand);
    procedure BuildProgram(const AProgram: TShelfProgram);
  public
    // The steps take turns, as Levels.Pads reads them. A pad that is no
    // shelf gets a cycle that never leaves the front.
    procedure Build(const AShelf: TPadShelf);
    // A run from ATick on: the shelf goes into the wall and stays, or
    // comes out and runs the program of ACommand
    procedure Command(ATick: Integer; const ACommand: TShelfCommand);
    function Slides: Boolean;
    function PhaseAt(ATick: Integer): TShelfPhase;
    // Out all the way: a floor and a body
    function Holds(ATick: Integer): Boolean;
    // Out, and about to start in
    function Warns(ATick: Integer): Boolean;
    // At this tick the shelf has come out all the way: its latch catches
    function Latches(ATick: Integer): Boolean;
    // 0 out in front .. 1 all the way in, at an even pace; ATime between
    // ticks
    function Depth(ATime: Double): Double;
  end;

implementation

uses
  System.Math;

const
  // Seconds in JSON, ticks in the code; the logic runs 33 ticks a second
  // (tickRate of Game.Config)
  LogicTicksPerSecond = 33;
  // The phase a step holds the shelf in, and the phase of the slide that
  // brings it there, and the depth that slide starts from
  HeldPhases: array [TShelfStand] of TShelfPhase = (spOut, spIn);
  SlidePhases: array [TShelfStand] of TShelfPhase = (spGoingOut, spGoingIn);
  SlideStarts: array [TShelfStand] of Double = (1, 0);
  // A rest lasts as long as the run: longer than any clock gets
  RestTicks = MaxInt;

function TicksOf(ASeconds: Double): Integer;
begin
  Result := Round(ASeconds * LogicTicksPerSecond);
end;

function SpanDepth(const ASpan: TShelfSpan; AInto: Double): Double;
begin
  case ASpan.Phase of
    spGoingIn:
      Result := ASpan.From + (1 - ASpan.From) * AInto / ASpan.Ticks;
    spIn:
      Result := 1;
    spGoingOut:
      Result := ASpan.From * (1 - AInto / ASpan.Ticks);
  else
    Result := 0;
  end;
end;

procedure TShelfCycle.AddLead(APhase: TShelfPhase; ATicks: Integer;
  AFrom: Double);
var
  Span: TShelfSpan;
begin
  Span.Phase := APhase;
  Span.Ticks := ATicks;
  Span.From := AFrom;
  FLead := FLead + [Span];
end;

// A step held, then the slide to the step after it. A step or a slide
// too short for a tick takes one all the same: a span of no ticks would
// be a jump.
procedure TShelfCycle.AddStep(AStand: TShelfStand; AHeldTicks: Integer;
  ANext: TShelfStand);
var
  Held, Slide: TShelfSpan;
begin
  Held.Phase := HeldPhases[AStand];
  Held.Ticks := Max(1, AHeldTicks);
  Held.From := 0;
  Slide.Phase := SlidePhases[ANext];
  Slide.Ticks := FSlideTicks;
  Slide.From := SlideStarts[ANext];
  FSpans := FSpans + [Held, Slide];
  Inc(FCycleTicks, Held.Ticks + Slide.Ticks);
end;

procedure TShelfCycle.Build(const AShelf: TPadShelf);
begin
  FSlides := AShelf.Slides;
  FSlideTicks := Max(1, TicksOf(AShelf.SlideSeconds));
  FOwnWarnTicks := TicksOf(AShelf.WarnSeconds);
  FWarnTicks := FOwnWarnTicks;
  FOrigin := 0;
  FLead := [];
  FSpans := [];
  FCycleTicks := 0;
  FOffsetTicks := TicksOf(AShelf.OffsetSeconds);
  FRest := HeldPhases[AShelf.HeldStand];
  FTold := False;
  if not FSlides or AShelf.Held then
    Exit;

  for var i := 0 to High(AShelf.Steps) do
  begin
    var Next := AShelf.Steps[(i + 1) mod Length(AShelf.Steps)];
    AddStep(AShelf.Steps[i].Stand, TicksOf(AShelf.Steps[i].Seconds),
      Next.Stand);
  end;
end;

// Out for its seconds, in for its seconds, round and round; hold has no
// round to go - the shelf rests out
procedure TShelfCycle.BuildProgram(const AProgram: TShelfProgram);
begin
  FRest := spOut;
  if AProgram.Kind = pgHold then
    Exit;
  AddStep(shOut, TicksOf(AProgram.OutSeconds), shIn);
  AddStep(shIn, TicksOf(AProgram.InSeconds), shOut);
end;

procedure TShelfCycle.Command(ATick: Integer; const ACommand: TShelfCommand);
begin
  if not FSlides then
    Exit;
  var Before := LookAt(ATick - 1);
  FTold := True;
  FBefore := Before;
  FOrigin := ATick;
  FLead := [];
  FSpans := [];
  FCycleTicks := 0;
  FOffsetTicks := 0;
  FWarnTicks := FOwnWarnTicks;
  if ACommand.Run.WarnSeconds > 0 then
    FWarnTicks := TicksOf(ACommand.Run.WarnSeconds);

  case ACommand.Call of
    scSleep:
    begin
      if (Before.Phase = spOut) and (FWarnTicks > 0) then
        AddLead(spOut, FWarnTicks, 0);
      if Before.Depth < 1 then
        AddLead(spGoingIn, Max(1, Ceil((1 - Before.Depth) * FSlideTicks)),
          Before.Depth);
      FRest := spIn;
    end;
    scWake:
    begin
      if Before.Depth > 0 then
        AddLead(spGoingOut, Max(1, Ceil(Before.Depth * FSlideTicks)),
          Before.Depth);
      BuildProgram(ACommand.Run);
    end;
  end;
end;

function TShelfCycle.Slides: Boolean;
begin
  Result := FSlides;
end;

// The span the run is in at ATime, and how many ticks into it; ATime
// not before FOrigin for a told run
function TShelfCycle.SpanAt(ATime: Double; out AInto: Double): TShelfSpan;
begin
  AInto := ATime - FOrigin;
  for var Span in FLead do
  begin
    if AInto < Span.Ticks then
      Exit(Span);
    AInto := AInto - Span.Ticks;
  end;

  if FCycleTicks = 0 then
  begin
    Result.Phase := FRest;
    Result.Ticks := RestTicks;
    Result.From := 0;
    Exit;
  end;
  AInto := AInto + FOffsetTicks;
  AInto := AInto - FCycleTicks * Floor(AInto / FCycleTicks);
  for var Span in FSpans do
  begin
    if AInto < Span.Ticks then
      Exit(Span);
    AInto := AInto - Span.Ticks;
  end;
  // A time a hair before a round's end may round up to the end itself
  Result := FSpans[High(FSpans)];
  AInto := Result.Ticks;
end;

function TShelfCycle.LookAt(ATime: Double): TShelfLook;
var
  Into: Double;
begin
  if not FSlides then
  begin
    Result.Phase := spOut;
    Result.Depth := 0;
    Result.Warns := False;
    Exit;
  end;
  if FTold and (ATime < FOrigin) then
    Exit(FBefore);
  var Span := SpanAt(ATime, Into);
  Result.Phase := Span.Phase;
  Result.Depth := SpanDepth(Span, Into);
  // After a span out comes the slide in, whatever the program
  Result.Warns := (Span.Phase = spOut) and (Span.Ticks - Into <= FWarnTicks);
end;

function TShelfCycle.PhaseAt(ATick: Integer): TShelfPhase;
begin
  Result := LookAt(ATick).Phase;
end;

function TShelfCycle.Holds(ATick: Integer): Boolean;
begin
  Result := PhaseAt(ATick) = spOut;
end;

function TShelfCycle.Warns(ATick: Integer): Boolean;
begin
  Result := LookAt(ATick).Warns;
end;

function TShelfCycle.Latches(ATick: Integer): Boolean;
begin
  Result := Holds(ATick) and not Holds(ATick - 1);
end;

function TShelfCycle.Depth(ATime: Double): Double;
begin
  Result := LookAt(ATime).Depth;
end;

end.
