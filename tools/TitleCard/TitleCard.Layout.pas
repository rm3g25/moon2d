{
  TitleCard.Layout - where a block of text becomes coordinates.

  Pure arithmetic: no SDL calls, no drawing, nothing that needs a
  renderer alive. It only borrows TMoonFont.ScaledTextWidth so the width
  formula lives in exactly one place - the font's - and cannot drift.

  Three rules the layout obeys, all of them deliberate:

  1. Explicit line breaks are sacred. The joke in "It ran on a timer /
     It did not." IS the line break. Auto-wrap exists (WrapCardText) but
     is an emergency exit the caller has to ask for, never a default.
  2. Scale steps are whole atlas cells. A 28 px bitmap glyph blown up by
     x1.7 has some columns three pixels wide and some four; at whole
     multiples every source pixel becomes the same block. Below x1 there
     is nothing to snap to, so the fit falls back to free scale and says
     so through IsIntegerScale.
  3. Centering is done on the INK, not on the cells. Caps occupy rows
     4..22 of the 28 px cell (measured on fonty.bmp), so a block centred
     by cells sits visibly low. See InkTopRatio below.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit TitleCard.Layout;

interface

uses
  Render.Font;

const
  // Measured on the upright atlas: capital ink spans rows 4..22 of the
  // 28 px cell. Everything vertical below is expressed through these.
  FontInkTopPx = 4;
  FontInkHeightPx = 19;
  InkTopRatio = FontInkTopPx / FontCellPx;      // 0.1429
  CapHeightRatio = FontInkHeightPx / FontCellPx; // 0.6786

type
  TCardGeometry = record
    Width: Integer;
    Height: Integer;
    MarginFraction: Double;        // free space on EACH side, 0.15 = 15%
    OpticalCenterFraction: Double; // 0.45: dead centre reads as sagging
    LineSpacing: Double;           // baseline step in CAP heights, 1.6
  end;

  TScaleMode = (smFitInteger, smFitFree, smExplicit);

  TCardScale = record
    Mode: TScaleMode;
    CellHeight: Double; // pixels; read only when Mode = smExplicit
    class function FitInteger: TCardScale; static;
    class function FitFree: TCardScale; static;
    class function Explicit(ACellHeight: Double): TCardScale; static;
    class function Steps(AStepCount: Integer): TCardScale; static;
  end;

  TPlacedLine = record
    Text: string;
    X: Double; // top-left of the first glyph CELL, in pixels
    Y: Double;
    OverflowChars: Integer; // how many characters past the margin, 0 = fits
  end;

  TCardLayout = record
    CellHeight: Double;
    Lines: TArray<TPlacedLine>;
    CharLimit: Integer; // what fits on one line at this cell height
    function ScaleSteps: Double;
    function IsIntegerScale: Boolean;
    function HasOverflow: Boolean;
    function WorstOverflow: Integer;
  end;

function DefaultCardGeometry: TCardGeometry;
function UsableWidth(const AGeometry: TCardGeometry): Double;
function UsableHeight(const AGeometry: TCardGeometry): Double;
function MaxCharsPerLine(const AGeometry: TCardGeometry;
  ACellHeight: Double): Integer;

function BuildCardLayout(const AFont: TMoonFont; const AText: string;
  const AGeometry: TCardGeometry;
  const AScale: TCardScale): TCardLayout;

// Emergency exit only: re-breaks lines that do not fit, on word
// boundaries. Explicit breaks in AText survive untouched.
function WrapCardText(const AText: string; const AGeometry: TCardGeometry;
  ACellHeight: Double): string;

// Splits a batch file into cards on blank lines.
function SplitCards(const AText: string): TArray<string>;

implementation

uses
  System.SysUtils, System.Math, System.Classes;

// ---------------------------------------------------------------------------
// TCardScale
// ---------------------------------------------------------------------------

class function TCardScale.FitInteger: TCardScale;
begin
  Result.Mode := smFitInteger;
  Result.CellHeight := 0;
end;

class function TCardScale.FitFree: TCardScale;
begin
  Result.Mode := smFitFree;
  Result.CellHeight := 0;
end;

class function TCardScale.Explicit(ACellHeight: Double): TCardScale;
begin
  Result.Mode := smExplicit;
  Result.CellHeight := ACellHeight;
end;

class function TCardScale.Steps(AStepCount: Integer): TCardScale;
begin
  Result := TCardScale.Explicit(AStepCount * FontCellPx);
end;

// ---------------------------------------------------------------------------
// TCardLayout
// ---------------------------------------------------------------------------

function TCardLayout.ScaleSteps: Double;
begin
  Result := CellHeight / FontCellPx;
end;

function TCardLayout.IsIntegerScale: Boolean;
begin
  Result := Abs(ScaleSteps - Round(ScaleSteps)) < 0.001;
end;

function TCardLayout.HasOverflow: Boolean;
begin
  Result := WorstOverflow > 0;
end;

function TCardLayout.WorstOverflow: Integer;
begin
  Result := 0;
  for var Line in Lines do
    if Line.OverflowChars > Result then
      Result := Line.OverflowChars;
end;

// ---------------------------------------------------------------------------
// Geometry helpers
// ---------------------------------------------------------------------------

function DefaultCardGeometry: TCardGeometry;
begin
  Result.Width := 1920;
  Result.Height := 1080;
  Result.MarginFraction := 0.15;
  Result.OpticalCenterFraction := 0.45;
  Result.LineSpacing := 1.6;
end;

function UsableWidth(const AGeometry: TCardGeometry): Double;
begin
  Result := AGeometry.Width * (1 - 2 * AGeometry.MarginFraction);
end;

function UsableHeight(const AGeometry: TCardGeometry): Double;
begin
  Result := AGeometry.Height * (1 - 2 * AGeometry.MarginFraction);
end;

function MaxCharsPerLine(const AGeometry: TCardGeometry;
  ACellHeight: Double): Integer;
begin
  // Inverse of TMoonFont.ScaledTextWidth: the last glyph shows its full
  // width, every earlier one contributes one advance.
  var GlyphWidth := ACellHeight * BigGlyphAspect;
  var Advance := BigAdvanceRatio * GlyphWidth;
  if Advance <= 0 then
    Exit(0);
  Result := Trunc((UsableWidth(AGeometry) - GlyphWidth) / Advance) + 1;
  if Result < 0 then
    Result := 0;
end;

function SplitCardLines(const AText: string): TArray<string>;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    // TStringList.Text keeps empty lines. TStringHelper.Split has a
    // history of opinions about them, and a blank line is exactly how a
    // batch file separates one card from the next - not a detail to
    // leave to somebody else's default.
    Lines.Text := AText;
    if Lines.Count = 0 then
      Lines.Add('');
    SetLength(Result, Lines.Count);
    for var i := 0 to Lines.Count - 1 do
      Result[i] := TrimRight(Lines[i]);
  finally
    Lines.Free;
  end;
end;

// Largest cell height at which every line fits the margins and the whole
// block fits the height. Both limits scale linearly with the cell, so one
// division each settles it - no search loop.
function FitCellHeight(const AFont: TMoonFont; const ALines: TArray<string>;
  const AGeometry: TCardGeometry): Double;
begin
  var WidthPerUnit := 0.0;
  for var Line in ALines do
    WidthPerUnit := Max(WidthPerUnit, AFont.ScaledTextWidth(Line, 1));
  var HeightPerUnit :=
    ((Length(ALines) - 1) * AGeometry.LineSpacing + 1) * CapHeightRatio;

  if (WidthPerUnit <= 0) or (HeightPerUnit <= 0) then
    Exit(FontCellPx);
  Result := Min(UsableWidth(AGeometry) / WidthPerUnit,
                UsableHeight(AGeometry) / HeightPerUnit);
end;

function ResolveCellHeight(const AFont: TMoonFont;
  const ALines: TArray<string>; const AGeometry: TCardGeometry;
  const AScale: TCardScale): Double;
begin
  if AScale.Mode = smExplicit then
    Exit(AScale.CellHeight);

  Result := FitCellHeight(AFont, ALines, AGeometry);
  if AScale.Mode = smFitFree then
    Exit;

  var StepCount := Trunc(Result / FontCellPx);
  if StepCount >= 1 then
    Result := StepCount * FontCellPx;
  // StepCount = 0 means the text does not fit even at native atlas size.
  // Shrinking below x1 is ugly but honest; IsIntegerScale reports it.
end;

function BuildCardLayout(const AFont: TMoonFont; const AText: string;
  const AGeometry: TCardGeometry;
  const AScale: TCardScale): TCardLayout;
var
  Lines: TArray<string>;
begin
  Lines := SplitCardLines(AText);
  Result.CellHeight := ResolveCellHeight(AFont, Lines, AGeometry, AScale);
  Result.CharLimit := MaxCharsPerLine(AGeometry, Result.CellHeight);

  var CapHeight := CapHeightRatio * Result.CellHeight;
  var LineStep := AGeometry.LineSpacing * CapHeight;
  var BlockInkHeight := (Length(Lines) - 1) * LineStep + CapHeight;
  var InkTop := AGeometry.OpticalCenterFraction * AGeometry.Height
    - BlockInkHeight / 2;
  var Limit := UsableWidth(AGeometry);

  SetLength(Result.Lines, Length(Lines));
  for var i := 0 to High(Lines) do
  begin
    var LineWidth := AFont.ScaledTextWidth(Lines[i], Result.CellHeight);
    Result.Lines[i].Text := Lines[i];
    Result.Lines[i].X := (AGeometry.Width - LineWidth) / 2;
    // Y addresses the cell, the block was centred on the ink: back the
    // cell up by the empty rows above the caps.
    Result.Lines[i].Y := InkTop + i * LineStep
      - InkTopRatio * Result.CellHeight;
    if LineWidth > Limit then
      Result.Lines[i].OverflowChars :=
        Max(1, Length(Lines[i]) - Result.CharLimit)
    else
      Result.Lines[i].OverflowChars := 0;
  end;
end;

function WrapSingleLine(const AText: string; ALimit: Integer): string;
var
  Current: string;
  Output: TStringBuilder;
begin
  if (ALimit <= 0) or (Length(AText) <= ALimit) then
    Exit(AText);

  Output := TStringBuilder.Create;
  try
    Current := '';
    for var Token in AText.Split([' ']) do
    begin
      if Token = '' then
        Continue;
      if Current = '' then
        Current := Token
      else if Length(Current) + 1 + Length(Token) <= ALimit then
        Current := Current + ' ' + Token
      else
      begin
        Output.AppendLine(Current);
        Current := Token;
      end;
    end;
    Output.Append(Current);
    Result := Output.ToString;
  finally
    Output.Free;
  end;
end;

function WrapCardText(const AText: string; const AGeometry: TCardGeometry;
  ACellHeight: Double): string;
begin
  var Limit := MaxCharsPerLine(AGeometry, ACellHeight);
  var Wrapped := SplitCardLines(AText);
  for var i := 0 to High(Wrapped) do
    Wrapped[i] := WrapSingleLine(Wrapped[i], Limit);
  Result := string.Join(#10, Wrapped);
end;

function SplitCards(const AText: string): TArray<string>;
var
  Cards: TStringList;
  Current: TStringBuilder;
begin
  Cards := TStringList.Create;
  Current := TStringBuilder.Create;
  try
    for var Line in SplitCardLines(AText) do
      if Line = '' then
      begin
        if Current.Length > 0 then
          Cards.Add(Current.ToString);
        Current.Clear;
      end
      else
      begin
        if Current.Length > 0 then
          Current.Append(#10);
        Current.Append(Line);
      end;
    if Current.Length > 0 then
      Cards.Add(Current.ToString);
    Result := Cards.ToStringArray;
  finally
    Current.Free;
    Cards.Free;
  end;
end;

end.
