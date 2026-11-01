{
  Levels.CityLife - how bright each light of a chase's city is at a tick of
  the far plane's clock (Levels.FarPlane: "cityLights", "emblem",
  "beacons"): a sign's breath and its tired faults, a window waking for a
  span, the TeK emblem going out and lighting again part by part, a
  beacon's flash.

  The dice are a 32-bit integer hash (lowbias32), seeded by places - a
  building's in the city's list and a light's in its piece, a node's on its
  frame - and keyed by what is asked. They are the stand's dice
  (tools/chase/stand.template.html), bit for bit: the same sign stutters on
  the same tick on the stand and in the game. The keys and the small
  numbers below are the stand's.

  No SDL: Render.FarPlane and Render.DomeFrames ask, and draw.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.CityLife;
{$I ..\Moon2D.inc}

interface

uses
  Levels.FarPlane;

type
  // The emblem's relight cycle the tick falls in: its number from the
  // first, and the tick it began on
  TEmblemCycle = record
    Index: Integer;
    Start: Integer;
  end;

// lowbias32
function Mix(AValue: Cardinal): Cardinal;
// 0 .. 1, never 1: the same for the same seed and key
function Roll(ASeed, AKey: Cardinal): Double;
function RollRange(ASeed, AKey: Cardinal; ALeast, AMost: Double): Double;
// ALeast .. AMost, both in
function RollInt(ASeed, AKey: Cardinal; ALeast, AMost: Integer): Integer;
// AElement - the building's place in the city's layer, ALight - the
// light's in its piece
function LightSeed(AElement, ALight: Integer): Cardinal;
// 0..1: a slow breath, and now and then a tube that stutters
function NeonLevel(const AFlicker: TCityFlicker; ASeed: Cardinal; ATick: Integer;
  AFaultShare: Double): Double;
// 0 - dark; a light switched on catches with a flicker
function WindowLevel(const ALights: TCityLights; ASeed: Cardinal; ATick: Integer): Double;
function EmblemCycle(const AEmblem: TCityEmblem; ATick: Integer): TEmblemCycle;
// APart - from 0, in the order the parts light
function EmblemPartLevel(const AEmblem: TCityEmblem; const AFlicker: TCityFlicker;
  APart, ATick: Integer): Double;
// By the node's place on its frame, not by the order of the nodes:
// ANodeX, ANodeZ on the unit half-sphere
function BeaconSeed(AFrame: Integer; ANodeX, ANodeZ: Double): Cardinal;
function BeaconLevel(const ABeacons: TCityBeacons; ASeed: Cardinal; ATick: Integer): Double;

implementation

uses
  System.Math;

const
  HashRange = 4294967296.0;

  BreathPeriodKey = 1;
  BreathPhaseKey = 2;
  WindowKey = 3;
  ShiftKey = 4;
  FaultKeys = 1000;
  KeysAWindow = 16;

  FirstSpanKey = 6;
  SpanKeys = 10;
  SpanOnKeys = 500;
  // A window switched on flickers over its first ticks
  CatchTicks = 4;

  EmblemSeed = $7E4;
  FirstCycleKey = 5;
  CycleLengthKey = 10;
  CycleDarkKey = 11;
  PartGapKeys = 2000;
  CatchFlipsKeys = 3000;
  CatchFlipKeys = 4000;
  CycleKeys = 16;
  PartKeys = 8;
  // The first cycle began long enough ago that the sign is lit when the
  // chase starts
  FirstCycleMargin = 600;
  CatchFlipsLeast = 2;
  CatchFlipsMost = 5;
  CatchFlipLeast = 2;
  CatchFlipMost = 4;

  BeaconPeriodKey = 1;
  BeaconPhaseKey = 2;
  // A node's place to a thousandth, shifted to stay above zero
  NodeGrid = 1000;
  NodeGridShift = 100000;

// The low 32 bits of the product, in halves: no step overflows, so the
// checked builds take it as it is
function MulLow32(A, B: Cardinal): Cardinal;
begin
  var ByLow: UInt64 := UInt64(A) * (B and $FFFF);
  var ByHigh: UInt64 := (UInt64(A) * (B shr 16)) and $FFFF;
  Result := Cardinal((ByLow + (ByHigh shl 16)) and $FFFFFFFF);
end;

function Mix(AValue: Cardinal): Cardinal;
begin
  var X := AValue;
  X := X xor (X shr 16);
  X := MulLow32(X, $7FEB352D);
  X := X xor (X shr 15);
  X := MulLow32(X, $846CA68B);
  Result := X xor (X shr 16);
end;

function Roll(ASeed, AKey: Cardinal): Double;
begin
  Result := Mix(Mix(ASeed) xor AKey) / HashRange;
end;

function RollRange(ASeed, AKey: Cardinal; ALeast, AMost: Double): Double;
begin
  Result := ALeast + (AMost - ALeast) * Roll(ASeed, AKey);
end;

// The products are kept in Double variables: the 32-bit compiler counts in
// the FPU's extended precision, and a product a hair under a whole number
// there is that whole number in the stand's doubles
function RollInt(ASeed, AKey: Cardinal; ALeast, AMost: Integer): Integer;
begin
  var Scaled: Double := Roll(ASeed, AKey) * (AMost - ALeast + 1);
  Result := ALeast + Floor(Scaled);
end;

function LightSeed(AElement, ALight: Integer): Cardinal;
begin
  Result := Mix(AElement * 64 + ALight + 1);
end;

// Flips go down and back: AOnEven on the even ones, AOnOdd on the others
function Alternate(AStep: Integer; AOnEven, AOnOdd: Double): Double;
begin
  Result := AOnEven;
  if Odd(AStep) then
    Result := AOnOdd;
end;

function NeonLevel(const AFlicker: TCityFlicker; ASeed: Cardinal; ATick: Integer;
  AFaultShare: Double): Double;
begin
  var Period := RollRange(ASeed, BreathPeriodKey, AFlicker.BreathLeast, AFlicker.BreathMost);
  var Phase := Roll(ASeed, BreathPhaseKey);
  var Breath: Double := 1 - AFlicker.BreathDepth *
    (0.5 + 0.5 * Sin(2 * Pi * (ATick / Period + Phase)));

  var Window := RollInt(ASeed, WindowKey, AFlicker.WindowLeast, AFlicker.WindowMost);
  var Shifted := ATick + RollInt(ASeed, ShiftKey, 0, Window - 1);
  var Which := Shifted div Window;
  var Inside := Shifted - Which * Window;
  var Base := FaultKeys + Which * KeysAWindow;
  if Roll(ASeed, Base) >= AFaultShare then
    Exit(Breath);

  var Flips := RollInt(ASeed, Base + 1, AFlicker.FlipsLeast, AFlicker.FlipsMost);
  var At := RollInt(ASeed, Base + 2, 0,
    Max(0, Window - Flips * AFlicker.FlipMost - 1));
  for var i := 0 to Flips - 1 do
  begin
    var FlipLength := RollInt(ASeed, Base + 3 + i, AFlicker.FlipLeast, AFlicker.FlipMost);
    if (Inside >= At) and (Inside < At + FlipLength) then
      Exit(Alternate(i, Breath * AFlicker.FaultLow, Breath));
    Inc(At, FlipLength);
  end;
  Result := Breath;
end;

function WindowLevel(const ALights: TCityLights; ASeed: Cardinal; ATick: Integer): Double;
begin
  var Spans := ALights.Windows;
  var Start := -RollInt(ASeed, FirstSpanKey, 0, Spans.SpanMost);
  var Span := 0;
  repeat
    var SpanLength := RollInt(ASeed, SpanKeys + Span, Spans.SpanLeast, Spans.SpanMost);
    if ATick < Start + SpanLength then
      Break;
    Inc(Start, SpanLength);
    Inc(Span);
  until False;

  if Roll(ASeed, SpanOnKeys + Span) >= Spans.OnShare then
    Exit(0);
  var Inside := ATick - Start;
  if (Inside < CatchTicks) and Odd(Inside) then
    Exit(ALights.Flicker.FaultLow);
  Result := 1;
end;

function EmblemCycle(const AEmblem: TCityEmblem; ATick: Integer): TEmblemCycle;
begin
  var Least := AEmblem.DarkMost + AEmblem.PartMost * Length(AEmblem.Parts) +
    FirstCycleMargin;
  Result.Start := -RollInt(EmblemSeed, FirstCycleKey, Least, Max(Least, AEmblem.RelightLeast));
  Result.Index := 0;
  repeat
    var CycleLength := RollInt(EmblemSeed, CycleLengthKey + Result.Index * CycleKeys,
      AEmblem.RelightLeast, AEmblem.RelightMost);
    if ATick < Result.Start + CycleLength then
      Break;
    Inc(Result.Start, CycleLength);
    Inc(Result.Index);
  until False;
end;

// Dark for a while, then each part in turn, catching with a stutter
function EmblemPartLevel(const AEmblem: TCityEmblem; const AFlicker: TCityFlicker;
  APart, ATick: Integer): Double;
begin
  var Cycle := EmblemCycle(AEmblem, ATick);
  var CycleBase := Cycle.Index * CycleKeys;
  var LitAt := Cycle.Start + RollInt(EmblemSeed, CycleDarkKey + CycleBase,
    AEmblem.DarkLeast, AEmblem.DarkMost);
  for var i := 0 to APart do
    Inc(LitAt, RollInt(EmblemSeed, PartGapKeys + CycleBase + i, AEmblem.PartLeast,
      AEmblem.PartMost));
  if ATick < LitAt then
    Exit(0);

  var Flips := RollInt(EmblemSeed, CatchFlipsKeys + CycleBase + APart, CatchFlipsLeast,
    CatchFlipsMost);
  var At := LitAt;
  for var j := 0 to Flips - 1 do
  begin
    var FlipLength := RollInt(EmblemSeed, CatchFlipKeys + (CycleBase + APart) * PartKeys + j,
      CatchFlipLeast, CatchFlipMost);
    if ATick < At + FlipLength then
      Exit(Alternate(j, 1, AFlicker.FaultLow));
    Inc(At, FlipLength);
  end;
  Result := NeonLevel(AFlicker, Mix(EmblemSeed + APart + 1), ATick, AEmblem.FaultShare);
end;

function NodeKey(ACoordinate: Double): Cardinal;
begin
  var Scaled: Double := ACoordinate * NodeGrid;
  // Half up, as the stand's Math.round: Round would go to the even
  Result := Floor(Scaled + 0.5) + NodeGridShift;
end;

function BeaconSeed(AFrame: Integer; ANodeX, ANodeZ: Double): Cardinal;
begin
  Result := Mix(Mix(Mix(AFrame + 1) xor NodeKey(ANodeX)) xor NodeKey(ANodeZ));
end;

function BeaconLevel(const ABeacons: TCityBeacons; ASeed: Cardinal; ATick: Integer): Double;
begin
  var Period := RollInt(ASeed, BeaconPeriodKey, ABeacons.PeriodLeast, ABeacons.PeriodMost);
  var Phase := RollInt(ASeed, BeaconPhaseKey, 0, Period - 1);
  Result := ABeacons.GlowLevel;
  if (ATick + Phase) mod Period < ABeacons.FlashTicks then
    Result := ABeacons.FlashLevel;
end;

end.
