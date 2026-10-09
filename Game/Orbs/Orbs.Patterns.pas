{
  Orbs.Patterns - the patterns the rite of orbs builds about the hero: a
  seat for every orb of every wave at any moment of the pattern's own
  clock. A pattern is a function and a name, no more; it knows nothing of
  how the orbs come to their seats or what the seats are for.

  A seat is in the hero's own frame - units right and down from the
  middle of his body - and says how far in front of him or behind him it
  lies and how brightly it burns. A seat may run off the end of its
  figure and begin it anew, a leap in one tick: its light is out at both
  ends. The level file names the pattern by its word; the names are in a
  table at the bottom of the unit.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Patterns;
{$I ..\..\Moon2D.inc}

interface

uses
  System.SysUtils;

const
  // Every pattern is built in this many waves
  PatternWaves = 3;
  DefaultPatternName = 'snowflake';

type
  EOrbPatternError = class(Exception);

  // A seat of a pattern, from the middle of the hero's body: units
  // right and down. Depth - from -1 behind him to 1 in front.
  TPatternSeat = record
    X, Y: Single;
    Depth: Single;
    Level: Single; // 0..1
  end;

  // AWave 0..PatternWaves - 1, AIndex 0..APerWave - 1; AFlow - the
  // pattern's own clock, ticks
  TPatternSeatFunc = function(AWave, AIndex, APerWave: Integer;
    AFlow: Single): TPatternSeat;

  TOrbPattern = record
    Name: string; // the word of a level file
    PerWave: Integer;
    Seat: TPatternSeatFunc;
  end;

// The pattern of the name; a name unknown raises
function FindPattern(const AName: string): TOrbPattern;

implementation

uses
  System.Math;

resourcestring
  SUnknownPattern = 'Unknown orb pattern "%s"';

const
  // The middle of every figure: a little above the middle of the body,
  // where the chest is
  HeartY = -2;
  // The figure's rays turn once round in this many ticks
  SpinTicks = 420;
  RayCount = 6;
  RayTurn = Pi / 3;
  BehindDepth = -0.5;
  FrontDepth = 1;

  // The rays: one wave of orbs stands along them, spread over this many
  // units from where the first stands
  RayStart = 14;
  RaySpan = 24;
  // Their ends: the tips go on from here, the twigs branch off here
  TipStart = 38;
  TwigStem = 32;
  TwigStep = 7;

  // The hexagon in front of the hero, and how long its orbs take to walk
  // one lap of it - against the turn of the rays
  HexRadius = 22;
  HexLapTicks = 210;

  // A figure's light runs along it in a wave
  LitBase = 0.8;
  LitSwing = 0.2;
  LitPace = 0.22; // radians a tick
  LitReachPace = 0.16; // radians a unit

function Lit(AReach, AFlow: Single): Single;
begin
  Result := LitBase + LitSwing * Sin(AFlow * LitPace - AReach * LitReachPace);
end;

// A seat of a ray, AReach units from the heart along ATurn
function RaySeat(ATurn, AReach, AFlow: Single): TPatternSeat;
begin
  Result.X := AReach * Cos(ATurn);
  Result.Y := HeartY + AReach * Sin(ATurn);
  Result.Depth := BehindDepth;
  Result.Level := Lit(AReach, AFlow);
end;

// The tips of the rays and the twigs off them, alternately: along the ray
// a tip, a twig to one side, a tip, a twig to the other
function BranchSeat(ATurn: Single; AAlong: Integer;
  AStep, AFlow: Single): TPatternSeat;
begin
  if AAlong mod 2 = 0 then
    Exit(RaySeat(ATurn, TipStart + (AAlong div 2) * AStep, AFlow));

  var Twig := (AAlong - 1) div 2;
  var Side := -1;
  if Odd(Twig) then
    Side := 1;
  var Far: Single := TwigStep * (Twig div 2 + 1);
  var Branch: Single := ATurn + Side * RayTurn;
  Result.X := TwigStem * Cos(ATurn) + Far * Cos(Branch);
  Result.Y := HeartY + TwigStem * Sin(ATurn) + Far * Sin(Branch);
  Result.Depth := BehindDepth;
  Result.Level := Lit(TwigStem + Far, AFlow);
end;

// The hexagon with its corners on the rays; the orbs are spread evenly
// along its sides and walk them
function HexSeat(AIndex, APerWave: Integer; ASpin, AFlow: Single): TPatternSeat;
begin
  var Lap: Single := Frac(AIndex / APerWave - AFlow / HexLapTicks);
  // Frac keeps the sign, and the flow outruns the index
  if Lap < 0 then
    Lap := Lap + 1;
  var Walked: Single := Lap * RayCount;
  var Corner := Trunc(Walked);
  var Between: Single := Walked - Corner;

  var FromTurn: Single := ASpin - Pi / 2 + Corner * RayTurn;
  var ToTurn: Single := FromTurn + RayTurn;
  var FromX: Single := HexRadius * Cos(FromTurn);
  var FromY: Single := HeartY + HexRadius * Sin(FromTurn);
  var ToX: Single := HexRadius * Cos(ToTurn);
  var ToY: Single := HeartY + HexRadius * Sin(ToTurn);
  Result.X := FromX + (ToX - FromX) * Between;
  Result.Y := FromY + (ToY - FromY) * Between;
  Result.Depth := FrontDepth;
  Result.Level := 1;
end;

// Wave 0 - the rays, behind the hero; wave 1 - their tips and twigs,
// behind him too; wave 2 - the hexagon, in front
function SnowflakeSeat(AWave, AIndex, APerWave: Integer;
  AFlow: Single): TPatternSeat;
begin
  var Spin: Single := AFlow * 2 * Pi / SpinTicks;
  if AWave = 2 then
    Exit(HexSeat(AIndex, APerWave, Spin, AFlow));

  var Ray := AIndex mod RayCount;
  var Along := AIndex div RayCount;
  var Turn: Single := Spin + Ray * RayTurn - Pi / 2;
  var Step: Single := RaySpan / (APerWave / RayCount);
  if AWave = 0 then
    Result := RaySeat(Turn, RayStart + Along * Step, AFlow)
  else
    Result := BranchSeat(Turn, Along, Step, AFlow);
end;

const
  // The vortex stands on the hero's feet line, this far under the middle
  // of his body, and rises this far, to over his head
  VortexFootY = 16;
  VortexRise = 62;
  // Narrow at the feet, wide at the top: the radius at the foot and what
  // the climb adds to it, quicker at first
  VortexFootRadius = 12;
  VortexFlare = 22;
  VortexFlarePower: Single = 0.8;
  // An orb climbs its arm in this many ticks, and the arm winds this
  // many laps on the way; the whole column turns against the winding
  VortexClimbTicks = 64;
  VortexLaps = 1.6;
  VortexSpinPace = 0.085; // radians a tick
  // The rings of the column are seen a little from above: the near side
  // of a ring hangs lower by this share of its radius
  ColumnTilt = 0.26;
  // An orb's light comes up over this share of its arm as it sets out
  // and dies over as much as it arrives
  ArmFade = 0.12;

// 0..1 in, 0..1 out, slow at both ends; past either end it stays there
function Smoothed(AShare: Single): Single;
begin
  if AShare <= 0 then
    Exit(0);
  if AShare >= 1 then
    Exit(1);
  Result := AShare * AShare * (3 - 2 * AShare);
end;

// A seat on a ring about the hero's upright, ATurn round it; the ring
// lies ARow units under the middle of his body. Its near half is in front
// of him, its far half behind.
function ColumnSeat(ATurn, ARow, ARadius, ALevel: Single): TPatternSeat;
begin
  Result.Depth := Sin(ATurn);
  Result.X := ARadius * Cos(ATurn);
  Result.Y := ARow + Result.Depth * ARadius * ColumnTilt;
  Result.Level := ALevel;
end;

// A funnel of three arms, one to a wave. An orb climbs its arm from the
// feet to over the head and is at the feet again
function VortexSeat(AWave, AIndex, APerWave: Integer;
  AFlow: Single): TPatternSeat;
begin
  var Climbed: Single := Frac(AIndex / APerWave + AFlow / VortexClimbTicks);
  var Turn: Single := AWave * 2 * Pi / PatternWaves +
    VortexLaps * 2 * Pi * Climbed - AFlow * VortexSpinPace;
  var Radius: Single := VortexFootRadius +
    VortexFlare * Power(Climbed, VortexFlarePower);
  var Light: Single := Smoothed(Climbed / ArmFade) *
    Smoothed((1 - Climbed) / ArmFade);
  Result := ColumnSeat(Turn, VortexFootY - Climbed * VortexRise, Radius,
    Light);
end;

const
  Patterns: array [0..1] of TOrbPattern = (
    (Name: 'snowflake'; PerWave: 24; Seat: SnowflakeSeat),
    (Name: 'vortex'; PerWave: 24; Seat: VortexSeat));

function FindPattern(const AName: string): TOrbPattern;
begin
  for var Pattern in Patterns do
    if Pattern.Name = AName then
      Exit(Pattern);
  raise EOrbPatternError.CreateFmt(SUnknownPattern, [AName]);
end;

end.
