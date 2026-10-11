{
  Pads.Shelf - the cycle of a shelf (Levels.Pads, "shelf"): a pad that
  slides out of the wall behind it and back in by its program. A step
  holds it out or in for its seconds; between two steps it slides. The
  program goes round: after its last step the shelf slides to its first.

  The cycle keeps the program laid out in ticks and nothing else. Where
  the shelf is at a tick of its pad's clock it works out anew every
  time: a pad that stood still off the hero's screen, or was rewound,
  needs no telling.

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
  end;

  // Ticks are those of the pad's clock, from its rewind on
  TShelfCycle = record
  private
    // Round the program: a step, the slide to the next, and so on
    FSpans: TArray<TShelfSpan>;
    FCycleTicks: Integer;
    FWarnTicks: Integer;
    FOffsetTicks: Integer;
    function SpanAt(ATime: Double; out AInto: Double): TShelfSpan;
  public
    // The steps take turns, as Levels.Pads reads them. A pad that is no
    // shelf gets a cycle that never leaves the front.
    procedure Build(const AShelf: TPadShelf);
    function Slides: Boolean;
    function PhaseAt(ATick: Integer): TShelfPhase;
    // Out all the way: a floor and a body
    function Holds(ATick: Integer): Boolean;
    // Out, and about to start in
    function Warns(ATick: Integer): Boolean;
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
  // brings it there
  HeldPhases: array [TShelfStand] of TShelfPhase = (spOut, spIn);
  SlidePhases: array [TShelfStand] of TShelfPhase = (spGoingOut, spGoingIn);

function TicksOf(ASeconds: Double): Integer;
begin
  Result := Round(ASeconds * LogicTicksPerSecond);
end;

procedure TShelfCycle.Build(const AShelf: TPadShelf);
var
  Held, Slide: TShelfSpan;
begin
  FSpans := [];
  FCycleTicks := 0;
  FWarnTicks := TicksOf(AShelf.WarnSeconds);
  FOffsetTicks := TicksOf(AShelf.OffsetSeconds);
  if not AShelf.Slides then
    Exit;

  // A step or a slide too short for a tick takes one all the same: a
  // span of no ticks would be a jump
  Slide.Ticks := Max(1, TicksOf(AShelf.SlideSeconds));
  for var i := 0 to High(AShelf.Steps) do
  begin
    var Next := AShelf.Steps[(i + 1) mod Length(AShelf.Steps)];
    Held.Phase := HeldPhases[AShelf.Steps[i].Stand];
    Held.Ticks := Max(1, TicksOf(AShelf.Steps[i].Seconds));
    Slide.Phase := SlidePhases[Next.Stand];
    FSpans := FSpans + [Held, Slide];
    Inc(FCycleTicks, Held.Ticks + Slide.Ticks);
  end;
end;

function TShelfCycle.Slides: Boolean;
begin
  Result := Length(FSpans) > 0;
end;

// The span the cycle is in at ATime, and how many ticks into it
function TShelfCycle.SpanAt(ATime: Double; out AInto: Double): TShelfSpan;
begin
  AInto := ATime + FOffsetTicks;
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

function TShelfCycle.PhaseAt(ATick: Integer): TShelfPhase;
var
  Into: Double;
begin
  if not Slides then
    Exit(spOut);
  Result := SpanAt(ATick, Into).Phase;
end;

function TShelfCycle.Holds(ATick: Integer): Boolean;
begin
  Result := PhaseAt(ATick) = spOut;
end;

// After a span out comes the slide in, whatever the program
function TShelfCycle.Warns(ATick: Integer): Boolean;
var
  Into: Double;
begin
  if not Slides then
    Exit(False);
  var Span := SpanAt(ATick, Into);
  Result := (Span.Phase = spOut) and (Span.Ticks - Into <= FWarnTicks);
end;

function TShelfCycle.Depth(ATime: Double): Double;
var
  Into: Double;
begin
  if not Slides then
    Exit(0);
  var Span := SpanAt(ATime, Into);
  case Span.Phase of
    spGoingIn:
      Result := Into / Span.Ticks;
    spIn:
      Result := 1;
    spGoingOut:
      Result := 1 - Into / Span.Ticks;
  else
    Result := 0;
  end;
end;

end.
