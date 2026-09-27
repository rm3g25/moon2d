{
  Hud.Marks - health rows over the figures, drawn with the brush. The
  hero's row speaks the monitor's grammar: five cells of norm with the
  empty ones as outlines, bonus cells past a divider. A monster's row is
  six cells, a pair per third of full health, colored by the crosshair's
  thirds - a pair empties in the tick the color turns, so the two say the
  same thing about the same target.

  A row shows for a while after a change and fades; the hero's stays
  while he is down to his last point. The hero's health arrives every
  tick and the difference is what animates; a monster carries its own
  time since the last hit, so the rows need no memory of the field.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Marks;
{$I Moon2D.inc}

interface

uses
  Sdl2.Core, Hud.Draw, Hero, Monsters;

type
  THudMarks = class
  private
    FBrush: THudBrush;
    FTick: Integer;
    FHealth: Integer;
    FScreen: Integer;
    FInvulnerable: Boolean;
    FShowTicks: Integer;
    FHurtTicks: Integer;
    FLostCell: Integer;
    FLostTicks: Integer;
    FGrownCell: Integer;
    FGrownTicks: Integer;
    function HeroAlpha: Single;
    procedure DrawPlate(AX, AY, AWidth, AAlpha: Single);
    procedure DrawHeroRow(const AHero: THero; AShift: TSdlPoint);
    procedure DrawMonsterRow(const AMonster: TMonster; AShift: TSdlPoint);
  public
    constructor Create(ARenderer: PSdlRenderer);
    destructor Destroy; override;

    // Once per logic tick, with the hero's health and screen as of now;
    // a new screen drops the row, whatever it was showing
    procedure Tick(AHealth: Integer; AInvulnerable: Boolean; AScreen: Integer);
    // The rows ride their figures' shake channels, not the world's
    procedure Draw(const AHero: THero; const AField: TMonsterField;
      AHeroShift, AMonsterShift: TSdlPoint);
  end;

implementation

uses
  System.Math, System.Generics.Collections, Render.Sprites, Monsters.Defs,
  Hud.Vitals;

const
  MarkCell = 4;
  MarkGap = 2;
  MarkLift = 9; // from the sprite's top edge up to the row
  BonusGap = 5; // extra room before the first bonus cell, the divider inside
  PlatePad = 2;
  CellsPerThird = 2;
  MonsterCells = 3 * CellsPerThird;
  ShowTicks = 80;
  FadeTicks = 20; // the last of ShowTicks
  HurtFlashTicks = 12;
  LostCellTicks = 14;
  GrownCellTicks = 8;

function TierColor(ATier: TMonsterHealthTier): TRgb;
begin
  case ATier of
    htHale: Result := HaleColor;
    htWounded: Result := WaryColor;
  else
    Result := AlarmColor;
  end;
end;

function IsMarked(const AMonster: TMonster; AScreen: Integer): Boolean;
begin
  Result := (AMonster.Screen = AScreen) and
    (AMonster.Def.Category in [mcEnemy, mcBoss]) and
    AMonster.HitWithin(ShowTicks);
end;

// Full pairs for the thirds below the current one, then the current
// third's own share; a living monster keeps at least one cell
function MonsterFullCells(const AMonster: TMonster): Integer;
var
  ThirdsBelow: Integer;
begin
  if AMonster.Lives <= 0 then
    Exit(0);
  case AMonster.HealthTier of
    htHale: ThirdsBelow := 2;
    htWounded: ThirdsBelow := 1;
  else
    ThirdsBelow := 0;
  end;
  Result := ThirdsBelow * CellsPerThird +
    Max(1, Ceil(CellsPerThird * AMonster.TierShare));
end;

// A living monster's row stays ShowTicks and fades at the end; a killed
// one's snaps to empty and dissolves at once
function MonsterAlpha(const AMonster: TMonster): Single;
begin
  if AMonster.Life = mlAlive then
    Result := Min(1.0, (ShowTicks - AMonster.TicksSinceHit) / FadeTicks)
  else
    Result := 1 - AMonster.TicksSinceHit / FadeTicks;
end;

// The row is centered over a 32-unit figure whose Y is the feet line
function RowX(AFigureX: Double; AWidth: Integer; AShift: TSdlPoint): Single;
begin
  Result := Round(AFigureX + (SpriteSize - AWidth) / 2) + AShift.X;
end;

function RowY(AFigureY: Double; AShift: TSdlPoint): Single;
begin
  Result := Round(AFigureY) - SpriteSize - MarkLift + AShift.Y;
end;

constructor THudMarks.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FBrush := THudBrush.Create(ARenderer);
end;

destructor THudMarks.Destroy;
begin
  FBrush.Free;
  inherited;
end;

procedure THudMarks.Tick(AHealth: Integer; AInvulnerable: Boolean;
  AScreen: Integer);
begin
  Inc(FTick);
  FInvulnerable := AInvulnerable;
  if AScreen <> FScreen then
  begin
    FScreen := AScreen;
    FShowTicks := 0;
    FHurtTicks := 0;
    FLostTicks := 0;
    FGrownTicks := 0;
  end;

  var LastHealth := FHealth;
  FHealth := AHealth;
  if AHealth < LastHealth then
  begin
    FShowTicks := ShowTicks;
    FHurtTicks := HurtFlashTicks;
    FLostCell := AHealth;
    FLostTicks := LostCellTicks;
  end
  else if AHealth > LastHealth then
  begin
    FShowTicks := ShowTicks;
    FGrownCell := AHealth - 1;
    FGrownTicks := GrownCellTicks;
  end;

  if FShowTicks > 0 then
    Dec(FShowTicks);
  if FHurtTicks > 0 then
    Dec(FHurtTicks);
  if FLostTicks > 0 then
    Dec(FLostTicks);
  if FGrownTicks > 0 then
    Dec(FGrownTicks);
end;

function THudMarks.HeroAlpha: Single;
begin
  if FHealth <= 1 then
    Exit(1);
  Result := Min(1.0, FShowTicks / FadeTicks);
end;

procedure THudMarks.Draw(const AHero: THero; const AField: TMonsterField;
  AHeroShift, AMonsterShift: TSdlPoint);
begin
  FBrush.BeginDraw;
  for var Monster in AField.Monsters do
    if IsMarked(Monster, AHero.Screen) then
      DrawMonsterRow(Monster, AMonsterShift);
  DrawHeroRow(AHero, AHeroShift);
  FBrush.EndDraw;
end;

procedure THudMarks.DrawPlate(AX, AY, AWidth, AAlpha: Single);
begin
  FBrush.Fill(AX - PlatePad, AY - PlatePad, AWidth + 2 * PlatePad,
    MarkCell + 2 * PlatePad, PanelColor, 0.5 * AAlpha);
end;

procedure THudMarks.DrawHeroRow(const AHero: THero; AShift: TSdlPoint);
var
  X: Single;

  function CellX(AIndex: Integer): Single;
  begin
    Result := X + AIndex * (MarkCell + MarkGap);
    if AIndex >= HealthyHealth then
      Result := Result + BonusGap;
  end;

begin
  if AHero.Dead then
    Exit;
  var Alpha := HeroAlpha;
  if Alpha <= 0 then
    Exit;

  var BonusCount := Max(FHealth - HealthyHealth, 0);
  var Width := (HealthyHealth + BonusCount) * (MarkCell + MarkGap) - MarkGap;
  if BonusCount > 0 then
    Width := Width + BonusGap;
  X := RowX(AHero.X, Width, AShift);
  var Y := RowY(AHero.Y, AShift);
  // The row comes up red on a hit and cools to its own color
  var Hurt := FHurtTicks / HurtFlashTicks;
  var Tint := Mix(HealthColor(FHealth), AlarmColor, Hurt);
  var Blink := FInvulnerable and (((FTick shr 2) and 1) = 0);

  DrawPlate(X, Y, Width, Alpha);
  if FHurtTicks > 0 then
  begin
    FBrush.Fill(X - PlatePad, Y - PlatePad, Width + 2 * PlatePad,
      MarkCell + 2 * PlatePad, AlarmColor, 0.35 * Hurt * Alpha);
    FBrush.Frame(X - PlatePad, Y - PlatePad, Width + 2 * PlatePad,
      MarkCell + 2 * PlatePad, AlarmColor, Hurt * Alpha);
  end;
  for var i := 0 to HealthyHealth - 1 do
    if i < FHealth then
      FBrush.FullCell(CellX(i), Y, MarkCell, MarkCell, Tint, Alpha)
    else
      FBrush.EmptyCell(CellX(i), Y, MarkCell, MarkCell, Tint, Alpha);
  if BonusCount > 0 then
  begin
    var DividerX := CellX(HealthyHealth) - BonusGap div 2 - 1;
    FBrush.Fill(DividerX, Y - 1, 1, MarkCell + 2, White, 0.35 * Alpha);
    for var i := 0 to BonusCount - 1 do
      FBrush.BonusCell(CellX(HealthyHealth + i), Y, MarkCell, MarkCell, Alpha);
  end;

  if Blink then
    for var i := 0 to FHealth - 1 do
      FBrush.Glow(CellX(i), Y, MarkCell, MarkCell, White, 0.4 * Alpha);
  if FLostTicks > 0 then
    FBrush.Fill(CellX(FLostCell), Y, MarkCell, MarkCell, White,
      FLostTicks / LostCellTicks * Alpha);
  if FGrownTicks > 0 then
    FBrush.Glow(CellX(FGrownCell) - 1, Y - 1, MarkCell + 2, MarkCell + 2, White,
      0.7 * FGrownTicks / GrownCellTicks * Alpha);
end;

procedure THudMarks.DrawMonsterRow(const AMonster: TMonster;
  AShift: TSdlPoint);
begin
  var Alpha := MonsterAlpha(AMonster);
  if Alpha <= 0 then
    Exit;
  var Width := MonsterCells * (MarkCell + MarkGap) - MarkGap;
  var X := RowX(AMonster.X, Width, AShift);
  var Y := RowY(AMonster.Y, AShift);
  var Tint := TierColor(AMonster.HealthTier);
  var FullCells := MonsterFullCells(AMonster);

  DrawPlate(X, Y, Width, Alpha);
  for var i := 0 to MonsterCells - 1 do
  begin
    var CellX := X + i * (MarkCell + MarkGap);
    if i < FullCells then
      FBrush.FullCell(CellX, Y, MarkCell, MarkCell, Tint, Alpha)
    else
      FBrush.EmptyCell(CellX, Y, MarkCell, MarkCell, Tint, Alpha);
  end;
end;

end.
