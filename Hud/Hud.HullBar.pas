{
  Hud.HullBar - the long bar of the Ram's hull along the top of the
  screen, between the hero's monitor on the left and the charge panel on
  the right: a slim plate with a row of cells, in the grammar of the
  head's row (Hud.Marks) - the thirds' colours, a cell lit at a time as
  it comes up, a red frame and a white cell where a life was just taken.
  It comes down into its place from over the top edge.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.HullBar;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Game.HullLives;

type
  THudHullBar = class
  private
    FBrush: THudBrush;
  public
    constructor Create(ARenderer: PSdlRenderer);
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

constructor THudHullBar.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FBrush := THudBrush.Create(ARenderer);
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
      FBrush.FullCell(CellX, Y, BarCell, BarCellHeight, Tint, 1)
    else
      FBrush.EmptyCell(CellX, Y, BarCell, BarCellHeight, Tint, 1);
  end;
  if (ABar.Lit > 0) and (ABar.Lit < HullBarCells) then
    FBrush.Glow(X + (ABar.Lit - 1) * (BarCell + BarGap) - 1, Y - 1,
      BarCell + 2, BarCellHeight + 2, White, BootGlow);
  FBrush.EndDraw;
end;

end.
