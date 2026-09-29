{
  Hud.Charge - the score as a bonus charge in the top-right corner, the
  twin of the heart monitor: the number, a bar filling toward the next
  reward, and the kill streak as a row of cells. Drawn with the shared
  HUD brush alone - no sprite, no font atlas.

  The bar fills to BonusCost and turns bonus-colored when a reward is
  waiting; the number keeps climbing past the cost until the reward is
  spent. The reward itself flies as sparks from the bar into a slot at
  the panel's left edge, with a mouse glyph in its corner: the right
  button spends it. Until the player has spent one, the slot insists -
  it pulses and the button blinks. The streak row shows the ten kills
  without a scratch that the game rewards but never showed.

  The panel observes rather than listens: it takes the score, the
  streak and the held reward every tick and reacts to the difference
  itself, so the game carries no hooks.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Charge;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Game.Bonus;

type
  THudCharge = class
  private type
    TSpark = record
      X, Y, VX, VY: Single;
      Ticks: Integer;
    end;
  private
    FBrush: THudBrush;
    FNoise: TXorShift;
    FPanelX: Integer;
    FSlotX: Integer;
    FReadoutX: Integer;
    FBarX: Integer;
    FStreakX: Integer;
    FScore: Integer;
    FStreak: Integer;
    FBonus: TBonusKind;
    FNovice: Boolean; // no reward spent yet: the slot insists
    FTick: Integer;
    FBarShown: Single; // the bar eases toward the score, this is where it is
    FBarSpeed: Single;
    FGainTicks: Integer;
    FReadyTicks: Integer;
    FLandTicks: Integer; // the sparks are still on their way to the slot
    FSpentTicks: Integer;
    FStreakGoalTicks: Integer;
    FStreakLostTicks: Integer;
    FStreakLost: Integer; // how many cells the lost streak had
    FSparks: TArray<TSpark>;
    function Tint: TRgb;
    function BarWidth: Single;
    function MouseButtonAlpha: Single;
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
    procedure DrawSlot;
    procedure DrawBonusIcon(AX, AY: Single);
    procedure DrawMouse(AX, AY: Single);
    procedure DrawSparks;
    procedure DrawStreak;
  public
    constructor Create(ARenderer: PSdlRenderer; AFrameWidth: Integer);
    destructor Destroy; override;
    // Once per logic tick: the score, the kill streak, the reward held
    // (bkNone when the slot is empty) and whether the player has yet to
    // spend a reward, all as of now
    procedure Tick(AScore, AStreak: Integer; ABonus: TBonusKind;
      ANovice: Boolean);
    procedure Draw;
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
  // Each tick a spark keeps this share of its burst and closes this
  // share of the way to the slot: a pop, then a pull
  SparkDrag = 0.8;
  SparkPull = 0.12;
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

  SlotWidth = 32; // the reward slot widens the panel to the left
  SlotInset = 4;
  SlotCell = SlotWidth - 2 * SlotInset;
  SlotY = PanelY + SlotInset;
  IconScale = 2;
  IconInset = (SlotCell - IconSize * IconScale) div 2;
  NovicePulseSpeed = 0.2;

  // The mouse glyph hangs off the cell's corner like a hotkey badge
  MouseW = 7;
  MouseH = 10;
  MouseOverhangX = 2;
  MouseOverhangY = 3;
  MouseBlinkPeriod = 40;
  MouseBlinkLit = 26; // ticks of each period the button is lit

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

  // A 7x10 mouse outline split into two buttons, and the right one
  MouseBody: array [0..5] of TIconRect = (
    (X: 1; Y: 0; W: 5; H: 1), (X: 1; Y: 9; W: 5; H: 1),
    (X: 0; Y: 1; W: 1; H: 8), (X: 6; Y: 1; W: 1; H: 8),
    (X: 3; Y: 1; W: 1; H: 3), (X: 1; Y: 4; W: 5; H: 1));
  MouseRightButton: TIconRect = (X: 4; Y: 1; W: 2; H: 3);

constructor THudCharge.Create(ARenderer: PSdlRenderer; AFrameWidth: Integer);
begin
  inherited Create;
  FBrush := THudBrush.Create(ARenderer);
  FNoise.Seed := $2545F491;
  FPanelX := AFrameWidth - PanelMargin - PanelW - SlotWidth;
  FSlotX := FPanelX + SlotInset;
  FReadoutX := FPanelX + SlotWidth;
  FBarX := FReadoutX + ReadoutWidth + InnerMargin;
  FStreakX := FBarX;
end;

destructor THudCharge.Destroy;
begin
  FBrush.Free;
  inherited;
end;

procedure THudCharge.Tick(AScore, AStreak: Integer; ABonus: TBonusKind;
  ANovice: Boolean);
begin
  Inc(FTick);
  ReactToScore(AScore);
  ReactToBonus(ABonus);
  ReactToStreak(AStreak, AScore);
  FScore := AScore;
  FStreak := AStreak;
  FBonus := ABonus;
  FNovice := ANovice;

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
    FLandTicks := SparkLifeTicks;
    SpawnSparks;
  end;
  if (ABonus = bkNone) and (FBonus <> bkNone) then
  begin
    FSpentTicks := SpentFlashTicks;
    FLandTicks := 0; // spent in flight: nothing lands
  end;
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
    FSparks[i].VX := FNoise.NextUnit * 2 - 1;
    FSparks[i].VY := -0.5 - FNoise.NextUnit * 1.5;
    FSparks[i].Ticks := SparkLifeTicks;
  end;
end;

procedure THudCharge.MoveSparks;
begin
  var TargetX := FSlotX + SlotCell / 2;
  var TargetY := SlotY + SlotCell / 2;
  for var i := 0 to High(FSparks) do
  begin
    if FSparks[i].Ticks = 0 then
      Continue;
    Dec(FSparks[i].Ticks);
    FSparks[i].VX := FSparks[i].VX * SparkDrag;
    FSparks[i].VY := FSparks[i].VY * SparkDrag;
    FSparks[i].X := FSparks[i].X + FSparks[i].VX + (TargetX - FSparks[i].X) * SparkPull;
    FSparks[i].Y := FSparks[i].Y + FSparks[i].VY + (TargetY - FSparks[i].Y) * SparkPull;
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
  if FLandTicks > 0 then
  begin
    Dec(FLandTicks);
    if FLandTicks = 0 then
      FReadyTicks := ReadyFlashTicks; // the sparks have landed
  end;
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
  DrawSlot;
  DrawSparks;
  DrawStreak;
  FBrush.EndDraw;
end;

procedure THudCharge.DrawPanel;
begin
  var FullWidth := PanelW + SlotWidth;
  FBrush.Fill(FPanelX, PanelY, FullWidth, PanelH, PanelColor, 0.72);
  FBrush.Fill(FReadoutX, PanelY + 3, 1, PanelH - 6, Tint, 0.2);
  FBrush.Fill(FReadoutX + ReadoutWidth, PanelY + 3, 1, PanelH - 6, Tint, 0.2);
  FBrush.Fill(FBarX, CellY - 2, BarW, 1, Tint, 0.12);
  if FSpentTicks > 0 then
    FBrush.Frame(FPanelX, PanelY, FullWidth, PanelH, White,
      0.3 + 0.7 * FSpentTicks / SpentFlashTicks)
  else
    FBrush.Frame(FPanelX, PanelY, FullWidth, PanelH, Tint, 0.3);
end;

procedure THudCharge.DrawReadout;
begin
  var Value := Min(FScore, MaxShownScore);
  var X := FReadoutX + (ReadoutWidth - NumberWidth(Value)) / 2;
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
  end;
end;

// Empty, or the sparks still in flight: a dim cell waiting to be filled
procedure THudCharge.DrawSlot;
begin
  if (FBonus = bkNone) or (FLandTicks > 0) then
  begin
    FBrush.Frame(FSlotX, SlotY, SlotCell, SlotCell, Tint, 0.25);
    Exit;
  end;

  FBrush.Fill(FSlotX, SlotY, SlotCell, SlotCell, BonusColor, 0.08);
  FBrush.Frame(FSlotX, SlotY, SlotCell, SlotCell, BonusColor, 0.6);
  if FNovice then
    FBrush.Glow(FSlotX - 1, SlotY - 1, SlotCell + 2, SlotCell + 2, BonusColor,
      0.25 + 0.25 * Sin(FTick * NovicePulseSpeed));
  DrawBonusIcon(FSlotX + IconInset, SlotY + IconInset);
  DrawMouse(FSlotX + SlotCell + MouseOverhangX - MouseW,
    SlotY + SlotCell + MouseOverhangY - MouseH);
  if FReadyTicks > 0 then
    FBrush.Glow(FSlotX - 2, SlotY - 2, SlotCell + 4, SlotCell + 4, White,
      0.7 * FReadyTicks / ReadyFlashTicks);
end;

procedure THudCharge.DrawBonusIcon(AX, AY: Single);

  procedure DrawRects(const ARects: array of TIconRect);
  begin
    for var i := 0 to High(ARects) do
      FBrush.Fill(AX + ARects[i].X * IconScale, AY + ARects[i].Y * IconScale,
        ARects[i].W * IconScale, ARects[i].H * IconScale, BonusColor, 1);
  end;

begin
  case FBonus of
    bkHealth: DrawRects(HealthIcon);
    bkFireRain: DrawRects(FireRainIcon);
    bkAura: DrawRects(AuraIcon);
    bkExplosion: DrawRects(ExplosionIcon);
  end;
end;

// A novice sees the right button blink like a press; after the first
// reward spent it stays lit, quietly
procedure THudCharge.DrawMouse(AX, AY: Single);
begin
  FBrush.Fill(AX - 1, AY - 1, MouseW + 2, MouseH + 2, PanelColor, 0.9);
  for var Part in MouseBody do
    FBrush.Fill(AX + Part.X, AY + Part.Y, Part.W, Part.H, White, 0.75);

  FBrush.Fill(AX + MouseRightButton.X, AY + MouseRightButton.Y,
    MouseRightButton.W, MouseRightButton.H, BonusColor, MouseButtonAlpha);
end;

function THudCharge.MouseButtonAlpha: Single;
begin
  if not FNovice then
    Exit(0.6);
  if (FTick mod MouseBlinkPeriod) < MouseBlinkLit then
    Exit(1);
  Result := 0.15;
end;

procedure THudCharge.DrawSparks;
begin
  for var Spark in FSparks do
  begin
    if Spark.Ticks = 0 then
      Continue;
    FBrush.Glow(Round(Spark.X), Round(Spark.Y), 1, 1, BonusColor,
      0.3 + 0.7 * Spark.Ticks / SparkLifeTicks);
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
