{
  Hud.Vitals - the hero's health as a heart monitor in the top-left
  corner: a running ECG trace, the number, and a row of cells. Drawn
  with fill rects alone - no sprite, no font atlas - so it ships with
  no asset and needs nothing from the 2008 pipeline.

  The cell row is the reading. HealthyHealth cells make the base row;
  the empty ones stay as outlines, so a difficulty that starts below
  the row starts visibly wounded. Health above the row is bonus and
  gets its own cells past a divider, in another color. The pulse
  quickens as the base row empties; the trace goes flat at zero.

  The monitor observes rather than listens: it takes the health every
  tick and reacts to the difference itself, so the damage and cure
  sites of the game carry no hooks.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Vitals;
{$I Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush;

const
  // A full base row. Every point above it is bonus; a difficulty may
  // start below it and shows so from the first frame.
  HealthyHealth = 5;

type
  THudVitals = class
  private const
    TraceSamples = 88; // one sample per game unit of trace width
  private
    FBrush: THudBrush;
    FHealth: Integer;
    FInvulnerable: Boolean;
    FTick: Integer;
    FNoise: TXorShift;
    FTrace: array [0..TraceSamples - 1] of Single;
    FHead: Integer; // next slot to write; the freshest sample sits before it
    FBeatPhase: Integer;
    FNoiseTicks: Integer;
    FHurtTicks: Integer;
    FCureTicks: Integer;
    FLostCell: Integer;
    FLostTicks: Integer;
    FGrownCell: Integer;
    FGrownTicks: Integer;
    function BaseColor: TRgb;
    function BeatsPerMinute: Integer;
    function BeatPeriod: Integer;
    function NoiseSample: Single;
    function NextSample: Single;
    procedure PushSample(AValue: Single);
    procedure ReactToHurt;
    procedure ReactToCure;
    procedure CoolEffects;
    procedure DrawPanel;
    procedure DrawTrace;
    procedure DrawReadout;
    function CellX(AIndex: Integer): Single;
    procedure DrawCells;
    procedure DrawFullCell(AX: Single; AColor: TRgb; ABlink: Boolean);
    procedure DrawEmptyCell(AX: Single; AColor: TRgb);
    procedure DrawBonusCell(AIndex: Integer; ABlink: Boolean);
    procedure DrawCellEffects;
  public
    constructor Create(ARenderer: PSdlRenderer);
    destructor Destroy; override;

    // Once per logic tick. The health is the hero's as of now; a drop
    // or a rise against the last call is what the monitor animates.
    procedure Tick(AHealth: Integer; AInvulnerable: Boolean);
    procedure Draw;
  end;

implementation

uses
  System.Math;

const
  // The pulse is timed in ticks, so the beats-per-minute figures hold
  // at the fixed tick of 2008 only
  TicksPerSecond = 33;
  SamplesPerTick = 2;
  WipeSamples = 4; // the dark stretch ahead of the sweep, oldest samples
  // One heartbeat as trace offsets, up is positive: the small P bump,
  // the QRS spike, the round T wave
  BeatShape: array [0..16] of Single =
    (0, 0, 1, 1, 0, 0, -1, 6, -8, 2, 0, 0, 1, 2, 2, 1, 0);

  HitNoiseTicks = 10;
  HurtFlashTicks = 12;
  CureFlashTicks = 14;
  LostCellTicks = 14;
  GrownCellTicks = 8;
  ShimmerPeriod = 66; // a glint runs down the bonus cells every 2 s
  ShimmerLag = 3;

  PanelX = PanelMargin;
  ReadoutWidth = 30;
  GridStep = 8;
  TraceX = PanelX + 1;
  TraceTop = PanelY + 1;
  TraceHeight = 22;
  TraceMidY = PanelY + 13;
  CellsX = TraceX + 3;
  BonusGap = 5; // extra room before the first bonus cell, the divider inside

procedure Cool(var ATicks: Integer);
begin
  if ATicks > 0 then
    Dec(ATicks);
end;

constructor THudVitals.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FBrush := THudBrush.Create(ARenderer);
  FNoise.Seed := $9E3779B9;
end;

destructor THudVitals.Destroy;
begin
  FBrush.Free;
  inherited;
end;

procedure THudVitals.Tick(AHealth: Integer; AInvulnerable: Boolean);
begin
  Inc(FTick);
  FInvulnerable := AInvulnerable;
  var LastHealth := FHealth;
  FHealth := AHealth;
  if AHealth < LastHealth then
    ReactToHurt
  else if AHealth > LastHealth then
    ReactToCure;

  for var i := 1 to SamplesPerTick do
    PushSample(NextSample);
  CoolEffects;
end;

procedure THudVitals.ReactToHurt;
begin
  FLostCell := FHealth; // the cell that just went dark, 0-based
  FLostTicks := LostCellTicks;
  FNoiseTicks := HitNoiseTicks;
  FHurtTicks := HurtFlashTicks;
end;

procedure THudVitals.ReactToCure;
begin
  FGrownCell := FHealth - 1;
  FGrownTicks := GrownCellTicks;
  FCureTicks := CureFlashTicks;
  FBeatPhase := BeatPeriod; // a beat right now, not at the next due one
end;

procedure THudVitals.CoolEffects;
begin
  Cool(FNoiseTicks);
  Cool(FHurtTicks);
  Cool(FCureTicks);
  Cool(FLostTicks);
  Cool(FGrownTicks);
end;

function THudVitals.BeatsPerMinute: Integer;
begin
  case FHealth of
    0, 1: Result := 152;
    2: Result := 118;
    3: Result := 92;
    4..HealthyHealth: Result := 70;
  else
    Result := 62;
  end;
end;

function THudVitals.BeatPeriod: Integer;
begin
  Result := Round(SamplesPerTick * TicksPerSecond * 60 / BeatsPerMinute);
end;

function THudVitals.NoiseSample: Single;
begin
  Result := Round(FNoise.NextUnit * 10) - 5;
end;

function THudVitals.NextSample: Single;
begin
  if FHealth <= 0 then
    Exit(0);
  if FBeatPhase >= BeatPeriod then
    FBeatPhase := 0;
  Result := 0;
  if FBeatPhase < Length(BeatShape) then
    Result := BeatShape[FBeatPhase];
  if FNoiseTicks > 0 then
    Result := Result + NoiseSample;
  Inc(FBeatPhase);
end;

procedure THudVitals.PushSample(AValue: Single);
begin
  FTrace[FHead] := AValue;
  FHead := (FHead + 1) mod TraceSamples;
end;

function THudVitals.BaseColor: TRgb;
begin
  Result := HealthColor(FHealth);
end;

procedure THudVitals.Draw;
begin
  FBrush.BeginDraw;
  DrawPanel;
  DrawTrace;
  DrawReadout;
  DrawCells;
  FBrush.EndDraw;
end;

procedure THudVitals.DrawPanel;
begin
  var Tint := BaseColor;
  FBrush.Fill(PanelX, PanelY, PanelW, PanelH, PanelColor, 0.72);
  for var i := 1 to (TraceSamples - 1) div GridStep do
    FBrush.Fill(TraceX + i * GridStep, TraceTop, 1, TraceHeight, Tint, 0.07);
  FBrush.Fill(TraceX + 1, CellY - 2, TraceSamples - 2, 1, Tint, 0.12);
  FBrush.Fill(PanelX + TraceSamples + 2, PanelY + 3, 1, PanelH - 6, Tint, 0.2);

  if FHurtTicks > 0 then
    FBrush.Frame(PanelX, PanelY, PanelW, PanelH, AlarmColor,
      0.4 + 0.6 * FHurtTicks / HurtFlashTicks)
  else
    FBrush.Frame(PanelX, PanelY, PanelW, PanelH, Tint, 0.3);
end;

procedure THudVitals.DrawTrace;
begin
  var Tint := Mix(BaseColor, White, FCureTicks / CureFlashTicks);
  var HasPrevious := False;
  var PreviousY := 0;
  for var i := 0 to TraceSamples - 1 do
  begin
    var Age := (FHead - 1 - i + TraceSamples) mod TraceSamples;
    if Age >= TraceSamples - WipeSamples then
    begin
      HasPrevious := False;
      Continue;
    end;
    var Y: Integer := Round(TraceMidY - FTrace[i]);
    if not HasPrevious then
      PreviousY := Y;
    var Top := Min(PreviousY, Y);
    var Bottom := Max(PreviousY, Y);
    FBrush.Fill(TraceX + i, Top, 1, Bottom - Top + 1, Tint,
      1 - 0.85 * Age / TraceSamples);
    PreviousY := Y;
    HasPrevious := True;
  end;

  var Newest := (FHead - 1 + TraceSamples) mod TraceSamples;
  var NewestY: Integer := Round(TraceMidY - FTrace[Newest]);
  FBrush.Glow(TraceX + Newest - 1, NewestY - 1, 3, 3, White, 0.9);
  if FHealth > HealthyHealth then
    FBrush.Glow(TraceX + Newest - 2, NewestY - 2, 5, 5, BonusColor, 0.35)
  else
    FBrush.Glow(TraceX + Newest - 2, NewestY - 2, 5, 5, Tint, 0.35);
end;

procedure THudVitals.DrawReadout;
begin
  var Blink := (FHealth = 1) and (((FTick shr 3) and 1) = 0);
  if Blink then
    Exit;
  var Value := Max(FHealth, 0);
  var X := PanelX + TraceSamples + (ReadoutWidth - NumberWidth(Value)) / 2;
  if FHealth > HealthyHealth then
    FBrush.DrawNumber(Value, X, ReadoutY, BonusColor)
  else
    FBrush.DrawNumber(Value, X, ReadoutY, BaseColor);
end;

function THudVitals.CellX(AIndex: Integer): Single;
begin
  Result := CellsX + AIndex * (CellW + CellGap);
  if AIndex >= HealthyHealth then
    Result := Result + BonusGap;
end;

procedure THudVitals.DrawCells;
begin
  var Tint := BaseColor;
  var Blink := FInvulnerable and (((FTick shr 2) and 1) = 0);
  for var i := 0 to HealthyHealth - 1 do
    if i < FHealth then
      DrawFullCell(CellX(i), Tint, Blink)
    else
      DrawEmptyCell(CellX(i), Tint);

  var BonusCount := FHealth - HealthyHealth;
  if BonusCount > 0 then
  begin
    var DividerX := CellX(HealthyHealth) - BonusGap div 2 - 1;
    FBrush.Fill(DividerX, CellY - 1, 1, CellH + 2, White, 0.35);
    for var i := 0 to BonusCount - 1 do
      DrawBonusCell(i, Blink);
  end;
  DrawCellEffects;
end;

procedure THudVitals.DrawFullCell(AX: Single; AColor: TRgb;
  ABlink: Boolean);
begin
  FBrush.FullCell(AX, CellY, CellW, CellH, AColor, 1);
  if ABlink then
    FBrush.Glow(AX, CellY, CellW, CellH, White, 0.4);
end;

procedure THudVitals.DrawEmptyCell(AX: Single; AColor: TRgb);
begin
  FBrush.EmptyCell(AX, CellY, CellW, CellH, AColor, 1);
end;

procedure THudVitals.DrawBonusCell(AIndex: Integer; ABlink: Boolean);
begin
  var X := CellX(HealthyHealth + AIndex);
  FBrush.BonusCell(X, CellY, CellW, CellH, 1);
  var Shimmer := Abs(FTick mod ShimmerPeriod - AIndex * ShimmerLag) < 2;
  if Shimmer then
    FBrush.Glow(X, CellY, CellW, CellH, White, 0.55);
  if ABlink then
    FBrush.Glow(X, CellY, CellW, CellH, White, 0.4);
end;

procedure THudVitals.DrawCellEffects;
begin
  if FLostTicks > 0 then
    FBrush.Fill(CellX(FLostCell), CellY, CellW, CellH, White,
      FLostTicks / LostCellTicks);
  if FGrownTicks > 0 then
    FBrush.Glow(CellX(FGrownCell) - 1, CellY - 1, CellW + 2, CellH + 2, White,
      0.7 * FGrownTicks / GrownCellTicks);
end;

end.
