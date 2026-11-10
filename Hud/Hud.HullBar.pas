{
  Hud.HullBar - the long bar of the Ram's hull along the top of the
  screen, between the hero's monitor on the left and the charge panel on
  the right: a slim plate with a row of cells, in the grammar of the
  head's row (Hud.Marks) - the thirds' colours, a cell lit at a time as
  it comes up, a red frame and a white cell where a life was just taken.
  It comes down into its place from over the top edge.

  While no part of the hull is hot the bar stands grey, the word for its
  armour under it: shooting it is of no use. While a part is hot the cells
  take their colours and pulse.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.HullBar;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Render.Font, Game.HullLives;

type
  THudHullBar = class
  private
    FBrush: THudBrush;
    FFont: TMoonFont;
    FArmourWord: string;
  public
    // AFont belongs to the caller and must outlive the bar; AArmourWord -
    // what is written under the bar while the hull is armoured
    constructor Create(const AFont: TMoonFont; ARenderer: PSdlRenderer;
      const AArmourWord: string);
    destructor Destroy; override;
    procedure Draw(const ABar: THullBar);
  end;

implementation

uses
  System.Math, Game.Space;

const
  BarCell = 4;
  BarCellHeight = 6;
  BarGap = 2;
  PlatePad = 4;
  // The plate's middle on the middle of the panels' height
  BarMiddleY = PanelY + PanelH / 2;
  // The newest cell of the bar coming up glows
  BootGlow = 0.8;
  // Armoured: the cells and the word under the plate
  ArmourColor: TRgb = (R: 142; G: 152; B: 158);
  ArmourWordGap = 1;
  ArmourWordAlpha = 190;
  // Hot, the cells dim to this between the pulses, and glow at their peak
  PulseFloor = 0.5;
  PulseGlow = 0.45;

constructor THudHullBar.Create(const AFont: TMoonFont; ARenderer: PSdlRenderer;
  const AArmourWord: string);
begin
  inherited Create;
  FBrush := THudBrush.Create(ARenderer);
  FFont := AFont;
  FArmourWord := AArmourWord;
end;

destructor THudHullBar.Destroy;
begin
  FBrush.Free;
  inherited;
end;

procedure THudHullBar.Draw(const ABar: THullBar);
begin
  if not ABar.Shown then
    Exit;
  var Width := HullBarCells * (BarCell + BarGap) - BarGap;
  var X: Single := Round((ScreenWidth - Width) / 2);
  var PlateHeight := BarCellHeight + 2 * PlatePad;
  // Down from over the top edge into its place
  var Fall: Single := (BarMiddleY + PlateHeight / 2) * (1 - ABar.Drop);
  var Y: Single := Round(BarMiddleY - BarCellHeight / 2 - Fall);

  var Tint := HaleColor;
  if ABar.Share * 3 <= 2 then
    Tint := WaryColor;
  if ABar.Share * 3 <= 1 then
    Tint := AlarmColor;
  var Full := 0;
  if ABar.Share > 0 then
    Full := Max(1, Ceil(HullBarCells * ABar.Share));
  var CellTint := ArmourColor;
  var CellLevel: Single := 1;
  if ABar.Hot then
  begin
    CellTint := Tint;
    CellLevel := PulseFloor + (1 - PulseFloor) * ABar.Pulse;
  end;

  FBrush.BeginDraw;
  FBrush.Fill(X - PlatePad, Y - PlatePad, Width + 2 * PlatePad, PlateHeight,
    PanelColor, 0.72);
  var FrameTint := Tint;
  var FrameLevel: Single := 0.3;
  if ABar.HitTicks < HullBarHitTicks then
  begin
    var Hit: Single := 1 - ABar.HitTicks / HullBarHitTicks;
    FrameTint := AlarmColor;
    FrameLevel := 0.4 + 0.6 * Hit;
    if Full < HullBarCells then
      FBrush.Fill(X + Full * (BarCell + BarGap), Y, BarCell, BarCellHeight,
        White, Hit);
  end;
  FBrush.Frame(X - PlatePad, Y - PlatePad, Width + 2 * PlatePad, PlateHeight,
    FrameTint, FrameLevel);
  for var i := 0 to ABar.Lit - 1 do
  begin
    var CellX := X + i * (BarCell + BarGap);
    if i < Full then
      FBrush.FullCell(CellX, Y, BarCell, BarCellHeight, CellTint, CellLevel)
    else
      FBrush.EmptyCell(CellX, Y, BarCell, BarCellHeight, CellTint, 1);
  end;
  if ABar.Hot and (ABar.Lit >= HullBarCells) and (Full > 0) then
    FBrush.Glow(X - 1, Y - 1, Full * (BarCell + BarGap) - BarGap + 2,
      BarCellHeight + 2, Tint, PulseGlow * ABar.Pulse);
  if (ABar.Lit > 0) and (ABar.Lit < HullBarCells) then
    FBrush.Glow(X + (ABar.Lit - 1) * (BarCell + BarGap) - 1, Y - 1,
      BarCell + 2, BarCellHeight + 2, White, BootGlow);
  FBrush.EndDraw;

  if not ABar.Hot and (ABar.Lit >= HullBarCells) then
    FFont.DrawSmall(FArmourWord,
      (ScreenWidth - FFont.SmallTextWidth(FArmourWord)) / 2,
      Y - PlatePad + PlateHeight + ArmourWordGap, ArmourWordAlpha);
end;

end.
