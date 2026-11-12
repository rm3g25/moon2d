{
  Game.Breakup - the end of the Ram's hull, its lives gone in the air. It
  does not burst where the last orb found it - low over the hero after a
  dive, at the right edge after a charge's brake: first the throe. The
  hull cracks, lurches to its place over the middle of the screen, its
  jets coughing - catching for a moment and dying - shuddering, a blast
  or two on it; the jets die for good, and it bursts. Then the series:
  one blast after another on its pieces, an order the dice give, uneven
  gaps between them - not one bang.

  Only the clock and the order: where the hull is in its throe and what
  each tick tells. Where the places of its blasts are on the hull, how it
  breaks into pieces and how they fly - the Ram's and Game.Wreckage. No
  drawing, no hull, no SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Breakup;
{$I ..\Moon2D.inc}

interface

uses
  Render.Brush;

const
  // From the crack to the burst: a second
  ThroeTicks = 33;
  // The small blasts on the hull in its throe, ticks after the crack
  ThroePops: array [0..2] of Integer = (6, 15, 24);
  // The first blast on a piece this long after the burst, then one every
  // so many ticks, as the dice give
  SeriesFirstTicks = 8;
  SeriesGapLeast = 9;
  SeriesGapMost = 14;

type
  // buIdle - whole; buThroe - cracked, on its way to burst; buSeries -
  // burst, its pieces blowing up one by one; buOver - the last of them gone
  TBreakupStage = (buIdle, buThroe, buSeries, buOver);

  TBreakupCue = record
    // The hull cracks: the first flash
    Cracks: Boolean;
    // A small blast on the hull in its throe, at the place PopPlace of
    // ThroePops
    Pops: Boolean;
    PopPlace: Integer;
    // Its jets catch for a moment, and die again
    JetsCatch: Boolean;
    JetsDie: Boolean;
    // It bursts: the hull is gone, its pieces fly
    Breaks: Boolean;
    // A piece blows up: Piece, of the pieces the start was told of
    PieceBlows: Boolean;
    Piece: Integer;
    // The last blast of the series
    Over: Boolean;
  end;

  TBreakup = class
  private
    FStage: TBreakupStage;
    // Ticks into the stage
    FTicks: Integer;
    FDice: TXorShift;
    FFromLeft, FFromLift, FFromLean: Single;
    FToLeft, FToLift: Single;
    FLeft, FLift, FLean: Single;
    FJetsLit: Boolean;
    // Ticks after the burst each blast of the series comes, and on which
    // piece
    FPopTicks: TArray<Integer>;
    FPopPieces: TArray<Integer>;
    procedure PlanSeries(APieces: Integer);
    procedure TickThroe(var ACue: TBreakupCue);
    procedure TickSeries(var ACue: TBreakupCue);
  public
    // ASeed - the dice of the series
    constructor Create(ASeed: Cardinal);
    // The last life gone: the hull, its left edge at ALeft, ALift over the
    // road, leaning ALean degrees clockwise, cracks - and lurches to
    // AToLeft, AToLift to burst there; APieces of it blow up after the
    // burst, one each. Nothing unless whole.
    procedure Start(ALeft, ALift, ALean, AToLeft, AToLift: Single;
      APieces: Integer);
    // A death, a new level: whole again
    procedure Clear;
    function Tick: TBreakupCue;
    // Cracked and not yet over
    function Running: Boolean;
    // Burst: the hull is no more
    function Broken: Boolean;
    property Stage: TBreakupStage read FStage;
    // Where the hull is in its throe, as Start was told
    property Left: Single read FLeft;
    property Lift: Single read FLift;
    property Lean: Single read FLean;
    // Its jets burn this tick
    property JetsLit: Boolean read FJetsLit;
  end;

implementation

uses
  System.Math;

const
  // It shudders this far either way, a swing in this many ticks, grown
  // into over the first ShudderGrowTicks
  ShudderDegrees = 4.0;
  ShudderTicks = 5;
  ShudderGrowTicks = 10;
  // Its jets cough: lit CoughLitTicks of every CoughTicks, out for good
  // the last JetsDeadTicks of the throe
  CoughTicks = 7;
  CoughLitTicks = 4;
  JetsDeadTicks = 8;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

constructor TBreakup.Create(ASeed: Cardinal);
begin
  inherited Create;
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;
  Clear;
end;

procedure TBreakup.Clear;
begin
  FStage := buIdle;
  FTicks := 0;
  FJetsLit := False;
  FPopTicks := nil;
  FPopPieces := nil;
end;

procedure TBreakup.Start(ALeft, ALift, ALean, AToLeft, AToLift: Single;
  APieces: Integer);
begin
  if FStage <> buIdle then
    Exit;
  FStage := buThroe;
  FTicks := 0;
  FFromLeft := ALeft;
  FFromLift := ALift;
  FFromLean := ALean;
  FToLeft := AToLeft;
  FToLift := AToLift;
  FLeft := ALeft;
  FLift := ALift;
  FLean := ALean;
  FJetsLit := True;
  PlanSeries(APieces);
end;

// Every piece once, in an order the dice give, the gaps uneven
procedure TBreakup.PlanSeries(APieces: Integer);
begin
  SetLength(FPopPieces, Max(APieces, 0));
  SetLength(FPopTicks, Length(FPopPieces));
  for var i := 0 to High(FPopPieces) do
    FPopPieces[i] := i;
  for var i := High(FPopPieces) downto 1 do
  begin
    var Other := Min(Trunc(FDice.NextUnit * (i + 1)), i);
    var Kept := FPopPieces[i];
    FPopPieces[i] := FPopPieces[Other];
    FPopPieces[Other] := Kept;
  end;
  var At := SeriesFirstTicks;
  for var i := 0 to High(FPopTicks) do
  begin
    FPopTicks[i] := At;
    At := At + SeriesGapLeast +
      Min(Trunc(FDice.NextUnit * (SeriesGapMost - SeriesGapLeast + 1)),
      SeriesGapMost - SeriesGapLeast);
  end;
end;

function TBreakup.Tick: TBreakupCue;
begin
  Result := Default(TBreakupCue);
  case FStage of
    buThroe:
      TickThroe(Result);
    buSeries:
      TickSeries(Result);
  end;
end;

procedure TBreakup.TickThroe(var ACue: TBreakupCue);
begin
  Inc(FTicks);
  if FTicks = 1 then
    ACue.Cracks := True;
  for var i := Low(ThroePops) to High(ThroePops) do
    if FTicks = ThroePops[i] then
    begin
      ACue.Pops := True;
      ACue.PopPlace := i;
    end;

  var Way := SmoothStep(FTicks / ThroeTicks);
  FLeft := FFromLeft + (FToLeft - FFromLeft) * Way;
  FLift := FFromLift + (FToLift - FFromLift) * Way;
  var Grown: Single := Min(FTicks / ShudderGrowTicks, 1.0);
  FLean := FFromLean * (1 - Way) +
    Grown * ShudderDegrees * Sin(2 * Pi * FTicks / ShudderTicks);

  var Lit := (FTicks mod CoughTicks < CoughLitTicks) and
    (FTicks < ThroeTicks - JetsDeadTicks);
  ACue.JetsCatch := Lit and not FJetsLit;
  ACue.JetsDie := not Lit and FJetsLit;
  FJetsLit := Lit;

  if FTicks < ThroeTicks then
    Exit;
  ACue.Breaks := True;
  FStage := buSeries;
  FTicks := 0;
  if Length(FPopTicks) = 0 then
  begin
    ACue.Over := True;
    FStage := buOver;
  end;
end;

procedure TBreakup.TickSeries(var ACue: TBreakupCue);
begin
  Inc(FTicks);
  for var i := 0 to High(FPopTicks) do
    if FPopTicks[i] = FTicks then
    begin
      ACue.PieceBlows := True;
      ACue.Piece := FPopPieces[i];
    end;
  if FTicks < FPopTicks[High(FPopTicks)] then
    Exit;
  ACue.Over := True;
  FStage := buOver;
end;

function TBreakup.Running: Boolean;
begin
  Result := FStage in [buThroe, buSeries];
end;

function TBreakup.Broken: Boolean;
begin
  Result := FStage in [buSeries, buOver];
end;

end.
