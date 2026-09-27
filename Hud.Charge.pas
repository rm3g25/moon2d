{
  Hud.Charge - the score as a bonus charge in the top-right corner, the
  twin of the heart monitor: the number, a bar filling toward the next
  reward, and the kill streak as a row of cells. Drawn with the shared
  HUD brush alone - no sprite, no font atlas.

  The bar fills to BonusCost and turns bonus-colored when a reward is
  waiting, with the reward's icon punched into it; the number keeps
  climbing past the cost until the reward is spent. The streak row
  shows the ten kills without a scratch that the game rewards but
  never showed.

  The panel observes rather than listens: it takes the score, the
  streak and the held reward every tick and reacts to the difference
  itself, so the game carries no hooks.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Charge;
{$I Moon2D.inc}

interface

uses
  Sdl2.Core, Hud.Draw, Hud.Score, Game.Bonus;

type
  THudCharge = class(TScoreHud)
  private type
    TSpark = record
      X, Y, VX, VY: Single;
      Ticks: Integer;
    end;
  private
    FBrush: THudBrush;
    FNoise: TXorShift;
    FPanelX: Integer;
    FBarX: Integer;
    FStreakX: Integer;
    FScore: Integer;
    FStreak: Integer;
    FBonus: TBonusKind;
    FTick: Integer;
    FBarShown: Single; // the bar eases toward the score, this is where it is
    FBarSpeed: Single;
    FGainTicks: Integer;
    FReadyTicks: Integer;
    FSpentTicks: Integer;
    FStreakGoalTicks: Integer;
    FStreakLostTicks: Integer;
    FStreakLost: Integer; // how many cells the lost streak had
    FSparks: TArray<TSpark>;
    function Tint: TRgb;
    function BarWidth: Single;
    procedure ReactToScore(AScore: Integer);
    procedure ReactToBonus(ABonus: TBonusKind);
    procedure ReactToStreak(AStreak, AScore: Integer);
    procedure SpawnSparks;
    procedure MoveSparks;
    procedure EaseBar;
    procedure CoolEffects;
    procedure DrawPanel;
    procedure DrawReadout;
    procedure DrawBar;
    procedure DrawBonusIcon(AX, AY: Single);
    procedure DrawSparks;
    procedure DrawStreak;
  public
    constructor Create(ARenderer: PSdlRenderer; AScreenWidth: Integer);
    destructor Destroy; override;
    procedure Tick(AScore, AStreak: Integer; ABonus: TBonusKind); override;
    procedure Draw; override;
  end;

implementation

uses
  System.Math;

type
  TIconRect = record
    X, Y, W, H: Byte;
  end;

const
  StreakGoal = 10; // cells in the row: the streak the game pays for
  MaxShownScore = 999; // three digits fit the readout
  GainFlashTicks = 20;
  ReadyFlashTicks = 16;
  SpentFlashTicks = 12;
  StreakGoalTicks = 14;
  StreakLostTicks = 12;
  SparkCount = 14;
  SparkLifeTicks = 24;
  ShimmerPeriod = 66; // a glint runs down the full bar every 2 s
  BarSegments = 5; // a tick every ten points

  ReadoutWidth = 37; // three digits plus two units of air a side
  InnerMargin = 6; // air between the bar, the streak row and the panel frame
  // The streak row sets the width; the bar above it is exactly as wide
  StreakCellW = 6;
  StreakRowWidth = StreakGoal * (StreakCellW + CellGap) - CellGap;
  BarY = PanelY + 7;
  BarW = StreakRowWidth;
  BarH = 10;
  IconSize = 9;

  // 9x9 icons of the four rewards, as rects: a cross, three pairs of
  // falling drops, a ring, a star
  HealthIcon: array [0..1] of TIconRect = (
    (X: 3; Y: 0; W: 3; H: 9), (X: 0; Y: 3; W: 9; H: 3));
  FireRainIcon: array [0..5] of TIconRect = (
    (X: 1; Y: 0; W: 1; H: 3), (X: 1; Y: 5; W: 1; H: 3),
    (X: 4; Y: 2; W: 1; H: 3), (X: 4; Y: 7; W: 1; H: 2),
    (X: 7; Y: 0; W: 1; H: 3), (X: 7; Y: 5; W: 1; H: 3));
  AuraIcon: array [0..8] of TIconRect = (
    (X: 2; Y: 0; W: 5; H: 1), (X: 2; Y: 8; W: 5; H: 1),
    (X: 0; Y: 2; W: 1; H: 5), (X: 8; Y: 2; W: 1; H: 5),
    (X: 1; Y: 1; W: 1; H: 1), (X: 7; Y: 1; W: 1; H: 1),
    (X: 1; Y: 7; W: 1; H: 1), (X: 7; Y: 7; W: 1; H: 1),
    (X: 4; Y: 4; W: 1; H: 1));
  ExplosionIcon: array [0..6] of TIconRect = (
    (X: 4; Y: 0; W: 1; H: 9), (X: 0; Y: 4; W: 9; H: 1),
    (X: 1; Y: 1; W: 2; H: 2), (X: 6; Y: 1; W: 2; H: 2),
    (X: 1; Y: 6; W: 2; H: 2), (X: 6; Y: 6; W: 2; H: 2),
    (X: 3; Y: 3; W: 3; H: 3));

constructor THudCharge.Create(ARenderer: PSdlRenderer; AScreenWidth: Integer);
begin
  inherited Create;
  FBrush := THudBrush.Create(ARenderer);
  FNoise.Seed := $2545F491;
  FPanelX := AScreenWidth - PanelMargin - PanelW;
  FBarX := FPanelX + ReadoutWidth + InnerMargin;
  FStreakX := FBarX;
end;

destructor THudCharge.Destroy;
begin
  FBrush.Free;
  inherited;
end;

procedure THudCharge.Tick(AScore, AStreak: Integer; ABonus: TBonusKind);
begin
  Inc(FTick);
  ReactToScore(AScore);
  ReactToBonus(ABonus);
  ReactToStreak(AStreak, AScore);
  FScore := AScore;
  FStreak := AStreak;
  FBonus := ABonus;

  EaseBar;
  MoveSparks;
  CoolEffects;
end;

procedure THudCharge.ReactToScore(AScore: Integer);
begin
  if AScore > FScore then
    FGainTicks := GainFlashTicks;
end;

procedure THudCharge.ReactToBonus(ABonus: TBonusKind);
begin
  if (ABonus <> bkNone) and (FBonus = bkNone) then
  begin
    FReadyTicks := ReadyFlashTicks;
    SpawnSparks;
  end;
  if (ABonus = bkNone) and (FBonus <> bkNone) then
    FSpentTicks := SpentFlashTicks;
end;

// A streak ends two ways, told apart by the score: the tenth kill pays
// out and resets it, a hit resets it for nothing
procedure THudCharge.ReactToStreak(AStreak, AScore: Integer);
begin
  if (AStreak > 0) or (FStreak = 0) then
    Exit;
  if AScore > FScore then
    FStreakGoalTicks := StreakGoalTicks
  else
  begin
    FStreakLostTicks := StreakLostTicks;
    FStreakLost := FStreak;
  end;
end;

procedure THudCharge.SpawnSparks;
begin
  SetLength(FSparks, SparkCount);
  for var i := 0 to High(FSparks) do
  begin
    FSparks[i].X := FBarX + FNoise.NextUnit * BarW;
    FSparks[i].Y := BarY + FNoise.NextUnit * BarH;
    FSparks[i].VX := FNoise.NextUnit * 1.2 - 0.6;
    FSparks[i].VY := -0.3 - FNoise.NextUnit * 1.1;
    FSparks[i].Ticks := SparkLifeTicks;
  end;
end;

procedure THudCharge.MoveSparks;
begin
  for var i := 0 to High(FSparks) do
  begin
    if FSparks[i].Ticks = 0 then
      Continue;
    Dec(FSparks[i].Ticks);
    FSparks[i].VY := FSparks[i].VY + 0.05;
    FSparks[i].X := FSparks[i].X + FSparks[i].VX;
    FSparks[i].Y := FSparks[i].Y + FSparks[i].VY;
  end;
end;

// A stiff spring: the bar lands within a few ticks and overshoots a
// hair, so a kill reads as a jolt rather than a slide
procedure THudCharge.EaseBar;
begin
  var Target := Min(FScore, BonusCost) / BonusCost * BarW;
  FBarSpeed := (FBarSpeed + (Target - FBarShown) * 0.2) * 0.7;
  FBarShown := Max(0, FBarShown + FBarSpeed);
end;

procedure THudCharge.CoolEffects;
begin
  if FGainTicks > 0 then
    Dec(FGainTicks);
  if FReadyTicks > 0 then
    Dec(FReadyTicks);
  if FSpentTicks > 0 then
    Dec(FSpentTicks);
  if FStreakGoalTicks > 0 then
    Dec(FStreakGoalTicks);
  if FStreakLostTicks > 0 then
    Dec(FStreakLostTicks);
end;

function THudCharge.Tint: TRgb;
begin
  if FBonus <> bkNone then
    Result := BonusColor
  else
    Result := CalmColor;
end;

function THudCharge.BarWidth: Single;
begin
  Result := Round(FBarShown);
end;

procedure THudCharge.Draw;
begin
  FBrush.BeginDraw;
  DrawPanel;
  DrawReadout;
  DrawBar;
  DrawSparks;
  DrawStreak;
  FBrush.EndDraw;
end;

procedure THudCharge.DrawPanel;
begin
  FBrush.Fill(FPanelX, PanelY, PanelW, PanelH, PanelColor, 0.72);
  FBrush.Fill(FPanelX + ReadoutWidth, PanelY + 3, 1, PanelH - 6, Tint, 0.2);
  FBrush.Fill(FBarX, CellY - 2, BarW, 1, Tint, 0.12);
  if FSpentTicks > 0 then
    FBrush.Frame(FPanelX, PanelY, PanelW, PanelH, White,
      0.3 + 0.7 * FSpentTicks / SpentFlashTicks)
  else
    FBrush.Frame(FPanelX, PanelY, PanelW, PanelH, Tint, 0.3);
end;

procedure THudCharge.DrawReadout;
begin
  var Value := Min(FScore, MaxShownScore);
  var X := FPanelX + (ReadoutWidth - NumberWidth(Value)) / 2;
  FBrush.DrawNumber(Value, X, ReadoutY,
    Mix(Tint, White, FGainTicks / GainFlashTicks));
end;

procedure THudCharge.DrawBar;
begin
  var Color := Tint;
  FBrush.Fill(FBarX, BarY, BarW, BarH, Color, 0.1);
  FBrush.Frame(FBarX - 1, BarY - 1, BarW + 2, BarH + 2, Color, 0.3);

  var Alpha: Single := 1;
  if FBonus <> bkNone then
    Alpha := 0.85 + 0.15 * Sin(FTick * 0.25); // a waiting reward breathes
  FBrush.Fill(FBarX, BarY, BarWidth, BarH, Color, Alpha);
  FBrush.Glow(FBarX, BarY, BarWidth, 2, White, 0.3);
  if FBonus <> bkNone then
    FBrush.Fill(FBarX, BarY + BarH - 1, BarWidth, 1, BonusShade, 0.8)
  else
    FBrush.Fill(FBarX, BarY + BarH - 1, BarWidth, 1, CalmShade, 0.8);
  for var i := 1 to BarSegments - 1 do
    FBrush.Fill(FBarX + Round(BarW * i / BarSegments), BarY, 1, BarH,
      PanelColor, 0.6);

  if FBonus <> bkNone then
  begin
    var Glint := (FTick mod ShimmerPeriod) * 2 - 6;
    if Glint < BarW then
      FBrush.Glow(FBarX + Max(0, Glint), BarY, 4, BarH, White, 0.5);
    DrawBonusIcon(FBarX + Round(BarW / 2) - IconSize div 2, BarY + 1);
  end;
  if FReadyTicks > 0 then
    FBrush.Glow(FBarX - 2, BarY - 2, BarW + 4, BarH + 4, White,
      0.7 * FReadyTicks / ReadyFlashTicks);
end;

procedure THudCharge.DrawBonusIcon(AX, AY: Single);

  procedure DrawRects(const ARects: array of TIconRect);
  begin
    for var i := 0 to High(ARects) do
      FBrush.Fill(AX + ARects[i].X, AY + ARects[i].Y, ARects[i].W, ARects[i].H,
        BonusColor, 1);
  end;

begin
  FBrush.Fill(AX - 2, AY - 1, IconSize + 4, IconSize + 2, PanelColor, 0.85);
  case FBonus of
    bkHealth: DrawRects(HealthIcon);
    bkFireRain: DrawRects(FireRainIcon);
    bkAura: DrawRects(AuraIcon);
    bkExplosion: DrawRects(ExplosionIcon);
  end;
end;

procedure THudCharge.DrawSparks;
begin
  for var Spark in FSparks do
  begin
    if Spark.Ticks = 0 then
      Continue;
    FBrush.Glow(Round(Spark.X), Round(Spark.Y), 1, 1, BonusColor,
      Spark.Ticks / SparkLifeTicks);
  end;
end;

procedure THudCharge.DrawStreak;
begin
  for var i := 0 to StreakGoal - 1 do
  begin
    var X := FStreakX + i * (StreakCellW + CellGap);
    if i < FStreak then
      FBrush.FullCell(X, CellY, StreakCellW, CellH, CalmColor, 1)
    else
      FBrush.EmptyCell(X, CellY, StreakCellW, CellH, CalmColor, 1);
    if FStreakGoalTicks > 0 then
      FBrush.Glow(X, CellY, StreakCellW, CellH, White,
        0.8 * FStreakGoalTicks / StreakGoalTicks);
    if (FStreakLostTicks > 0) and (i < FStreakLost) then
      FBrush.Fill(X, CellY, StreakCellW, CellH, AlarmColor,
        0.8 * FStreakLostTicks / StreakLostTicks);
  end;
end;

end.
