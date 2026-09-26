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
  Sdl2.Core;

const
  // A full base row. Every point above it is bonus; a difficulty may
  // start below it and shows so from the first frame.
  HealthyHealth = 5;

type
  TRgb = record
    R, G, B: Byte;
  end;

  THudVitals = class
  private const
    TraceSamples = 88; // one sample per game unit of trace width
  private
    FRenderer: PSdlRenderer;
    FHealth: Integer;
    FInvulnerable: Boolean;
    FTick: Integer;
    // Own xorshift stream, not Random: that one feeds the boss spawn
    // table, and a hit on the hero must not reshuffle what falls
    FSeed: Cardinal;
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
    procedure Fill(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
    procedure Glow(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
    procedure Frame(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
    procedure DrawPanel;
    procedure DrawTrace;
    procedure DrawReadout;
    procedure DrawNumber(AValue: Integer; AX, AY: Single; AColor: TRgb);
    procedure DrawDigit(ADigit: Integer; AX, AY: Single; AColor: TRgb);
    function CellX(AIndex: Integer): Single;
    procedure DrawCells;
    procedure DrawFullCell(AX: Single; AColor: TRgb; ABlink: Boolean);
    procedure DrawEmptyCell(AX: Single; AColor: TRgb);
    procedure DrawBonusCell(AIndex: Integer; ABlink: Boolean);
    procedure DrawCellEffects;
  public
    constructor Create(ARenderer: PSdlRenderer);

    // Once per logic tick. The health is the hero's as of now; a drop
    // or a rise against the last call is what the monitor animates.
    procedure Tick(AHealth: Integer; AInvulnerable: Boolean);
    procedure Draw;
  end;

implementation

uses
  System.SysUtils, System.Math;

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

  PanelX = 6;
  PanelY = 4;
  PanelH = 32;
  ReadoutWidth = 30;
  GridStep = 8;
  TraceX = PanelX + 1;
  TraceTop = PanelY + 1;
  TraceHeight = 22;
  TraceMidY = PanelY + 13;
  CellsX = TraceX + 3;
  CellY = PanelY + 25;
  CellW = 7;
  CellH = 4;
  CellGap = 1;
  BonusGap = 5; // extra room before the first bonus cell, the divider inside
  DigitPixel = 3;
  DigitCols = 3;
  DigitRows = 5;
  DigitAdvance = (DigitCols + 1) * DigitPixel;
  // 3x5 pixel digits, row by row
  DigitGlyphs: array [0..9] of string = (
    '111101101101111', '010110010010111', '111001111100111',
    '111001111001111', '101101111001001', '111100111001111',
    '111100111101111', '111001001001001', '111101111101111',
    '111101111001111');

  CalmColor: TRgb = (R: 72; G: 196; B: 255);
  WaryColor: TRgb = (R: 255; G: 178; B: 56);
  AlarmColor: TRgb = (R: 255; G: 74; B: 61);
  BonusColor: TRgb = (R: 124; G: 255; B: 80);
  BonusShade: TRgb = (R: 40; G: 150; B: 30);
  PanelColor: TRgb = (R: 4; G: 12; B: 12);
  White: TRgb = (R: 255; G: 255; B: 255);

function Mix(AFrom, ATo: TRgb; AAmount: Single): TRgb;
begin
  Result.R := Round(AFrom.R + (ATo.R - AFrom.R) * AAmount);
  Result.G := Round(AFrom.G + (ATo.G - AFrom.G) * AAmount);
  Result.B := Round(AFrom.B + (ATo.B - AFrom.B) * AAmount);
end;

procedure Cool(var ATicks: Integer);
begin
  if ATicks > 0 then
    Dec(ATicks);
end;

constructor THudVitals.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSeed := $9E3779B9;
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
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := Integer(FSeed mod 11) - 5;
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
  case FHealth of
    0, 1: Result := AlarmColor;
    2: Result := WaryColor;
  else
    Result := CalmColor;
  end;
end;

procedure THudVitals.Fill(AX, AY, AW, AH: Single; AColor: TRgb;
  AAlpha: Single);
begin
  var Rect: TSdlFRect;
  Rect.X := AX;
  Rect.Y := AY;
  Rect.W := AW;
  Rect.H := AH;
  SDL_SetRenderDrawColor(FRenderer, AColor.R, AColor.G, AColor.B,
    Round(EnsureRange(AAlpha, 0, 1) * 255));
  SDL_RenderFillRectF(FRenderer, @Rect);
end;

procedure THudVitals.Glow(AX, AY, AW, AH: Single; AColor: TRgb;
  AAlpha: Single);
begin
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeAdd);
  Fill(AX, AY, AW, AH, AColor, AAlpha);
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
end;

procedure THudVitals.Frame(AX, AY, AW, AH: Single; AColor: TRgb;
  AAlpha: Single);
begin
  Fill(AX, AY, AW, 1, AColor, AAlpha);
  Fill(AX, AY + AH - 1, AW, 1, AColor, AAlpha);
  Fill(AX, AY + 1, 1, AH - 2, AColor, AAlpha);
  Fill(AX + AW - 1, AY + 1, 1, AH - 2, AColor, AAlpha);
end;

procedure THudVitals.Draw;
begin
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
  DrawPanel;
  DrawTrace;
  DrawReadout;
  DrawCells;
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeNone);
end;

procedure THudVitals.DrawPanel;
const
  PanelW = TraceSamples + ReadoutWidth;
begin
  var Tint := BaseColor;
  Fill(PanelX, PanelY, PanelW, PanelH, PanelColor, 0.72);
  for var i := 1 to (TraceSamples - 1) div GridStep do
    Fill(TraceX + i * GridStep, TraceTop, 1, TraceHeight, Tint, 0.07);
  Fill(TraceX + 1, CellY - 2, TraceSamples - 2, 1, Tint, 0.12);
  Fill(PanelX + TraceSamples + 2, PanelY + 3, 1, PanelH - 6, Tint, 0.2);

  if FHurtTicks > 0 then
    Frame(PanelX, PanelY, PanelW, PanelH, AlarmColor,
      0.4 + 0.6 * FHurtTicks / HurtFlashTicks)
  else
    Frame(PanelX, PanelY, PanelW, PanelH, Tint, 0.3);
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
    Fill(TraceX + i, Top, 1, Bottom - Top + 1, Tint,
      1 - 0.85 * Age / TraceSamples);
    PreviousY := Y;
    HasPrevious := True;
  end;

  var Newest := (FHead - 1 + TraceSamples) mod TraceSamples;
  var NewestY: Integer := Round(TraceMidY - FTrace[Newest]);
  Glow(TraceX + Newest - 1, NewestY - 1, 3, 3, White, 0.9);
  if FHealth > HealthyHealth then
    Glow(TraceX + Newest - 2, NewestY - 2, 5, 5, BonusColor, 0.35)
  else
    Glow(TraceX + Newest - 2, NewestY - 2, 5, 5, Tint, 0.35);
end;

procedure THudVitals.DrawReadout;
begin
  var Blink := (FHealth = 1) and (((FTick shr 3) and 1) = 0);
  if Blink then
    Exit;
  var Value := Max(FHealth, 0);
  var Width := Length(IntToStr(Value)) * DigitAdvance - DigitPixel;
  var X := PanelX + TraceSamples + (ReadoutWidth - Width) / 2;
  if FHealth > HealthyHealth then
    DrawNumber(Value, X, PanelY + 8, BonusColor)
  else
    DrawNumber(Value, X, PanelY + 8, BaseColor);
end;

procedure THudVitals.DrawNumber(AValue: Integer; AX, AY: Single;
  AColor: TRgb);
begin
  var Text := IntToStr(AValue);
  for var i := 1 to Length(Text) do
    DrawDigit(Ord(Text[i]) - Ord('0'), AX + (i - 1) * DigitAdvance, AY, AColor);
end;

procedure THudVitals.DrawDigit(ADigit: Integer; AX, AY: Single;
  AColor: TRgb);
begin
  var Glyph := DigitGlyphs[ADigit];
  for var i := 0 to DigitCols * DigitRows - 1 do
  begin
    if Glyph[i + 1] = '0' then
      Continue;
    Fill(AX + (i mod DigitCols) * DigitPixel, AY + (i div DigitCols) * DigitPixel,
      DigitPixel, DigitPixel, AColor, 1);
  end;
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
    Fill(DividerX, CellY - 1, 1, CellH + 2, White, 0.35);
    for var i := 0 to BonusCount - 1 do
      DrawBonusCell(i, Blink);
  end;
  DrawCellEffects;
end;

procedure THudVitals.DrawFullCell(AX: Single; AColor: TRgb;
  ABlink: Boolean);
begin
  Fill(AX, CellY, CellW, CellH, AColor, 1);
  Glow(AX, CellY, CellW, 1, White, 0.35);
  if ABlink then
    Glow(AX, CellY, CellW, CellH, White, 0.4);
end;

procedure THudVitals.DrawEmptyCell(AX: Single; AColor: TRgb);
begin
  Fill(AX, CellY, CellW, CellH, AColor, 0.08);
  Frame(AX, CellY, CellW, CellH, AColor, 0.3);
end;

procedure THudVitals.DrawBonusCell(AIndex: Integer; ABlink: Boolean);
begin
  var X := CellX(HealthyHealth + AIndex);
  Fill(X, CellY, CellW, CellH, BonusColor, 1);
  Glow(X, CellY, CellW, 1, White, 0.35);
  Fill(X, CellY + CellH - 1, CellW, 1, BonusShade, 0.8);
  var Shimmer := Abs(FTick mod ShimmerPeriod - AIndex * ShimmerLag) < 2;
  if Shimmer then
    Glow(X, CellY, CellW, CellH, White, 0.55);
  if ABlink then
    Glow(X, CellY, CellW, CellH, White, 0.4);
end;

procedure THudVitals.DrawCellEffects;
begin
  if FLostTicks > 0 then
    Fill(CellX(FLostCell), CellY, CellW, CellH, White,
      FLostTicks / LostCellTicks);
  if FGrownTicks > 0 then
    Glow(CellX(FGrownCell) - 1, CellY - 1, CellW + 2, CellH + 2, White,
      0.7 * FGrownTicks / GrownCellTicks);
end;

end.
