{
  Render.Brush - the brush the primitive-drawn HUD panels share: fill rects
  in game units with alpha or additive glow, one-unit frames, 3x5 pixel
  digits, and the cells every health row is made of. No sprite, no font
  atlas. The palette and the panel geometry live here too, so the panels
  and the marks over the figures stay one instrument.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Brush;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

type
  TRgb = record
    R, G, B: Byte;
  end;

  // Own xorshift stream, not Random: that one feeds the boss spawn
  // table, and a HUD flourish must not reshuffle what falls
  TXorShift = record
    Seed: Cardinal;
    function NextUnit: Single; // 0..1
  end;

  THudBrush = class
  private
    FRenderer: PSdlRenderer;
    procedure DrawDigit(ADigit: Integer; AX, AY: Single; AColor: TRgb;
      AAlpha: Single);
  public
    constructor Create(ARenderer: PSdlRenderer);
    // Alpha blending on, and off again: the rest of the game draws
    // opaque and must not inherit the mode
    procedure BeginDraw;
    procedure EndDraw;
    procedure Fill(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
    procedure Glow(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
    procedure Frame(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
    procedure DrawNumber(AValue: Integer; AX, AY: Single; AColor: TRgb;
      AAlpha: Single = 1);
    // The cells of a health row: full with a sheen along the top, empty
    // as a dim outline, bonus in its own color with a shaded foot
    procedure FullCell(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
    procedure EmptyCell(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
    procedure BonusCell(AX, AY, AW, AH: Single; AAlpha: Single);
  end;

function Mix(AFrom, ATo: TRgb; AAmount: Single): TRgb;
function NumberWidth(AValue: Integer): Integer;
// The hero's color by health: red at the last point, amber at two, calm
// above - the crosshair's language
function HealthColor(AHealth: Integer): TRgb;

const
  CalmColor: TRgb = (R: 72; G: 196; B: 255);
  WaryColor: TRgb = (R: 255; G: 178; B: 56);
  AlarmColor: TRgb = (R: 255; G: 74; B: 61);
  HaleColor: TRgb = (R: 64; G: 208; B: 96);
  BonusColor: TRgb = (R: 124; G: 255; B: 80);
  BonusShade: TRgb = (R: 40; G: 150; B: 30);
  CalmShade: TRgb = (R: 20; G: 90; B: 140);
  PanelColor: TRgb = (R: 4; G: 12; B: 12);
  White: TRgb = (R: 255; G: 255; B: 255);

  // One panel per top corner, both this tall and this far from the edge
  PanelMargin = 6;
  PanelY = 4;
  PanelH = 32;
  PanelW = 118;
  ReadoutY = PanelY + 8;
  // The cell row along the bottom of a panel
  CellY = PanelY + 25;
  CellW = 7;
  CellH = 4;
  CellGap = 1;
  DigitPixel = 3;

implementation

uses
  System.SysUtils, System.Math;

const
  DigitCols = 3;
  DigitRows = 5;
  DigitAdvance = (DigitCols + 1) * DigitPixel;
  // 3x5 pixel digits, row by row
  DigitGlyphs: array [0..9] of string = (
    '111101101101111', '010110010010111', '111001111100111',
    '111001111001111', '101101111001001', '111100111001111',
    '111100111101111', '111001001001001', '111101111101111',
    '111101111001111');

function Mix(AFrom, ATo: TRgb; AAmount: Single): TRgb;
begin
  Result.R := Round(AFrom.R + (ATo.R - AFrom.R) * AAmount);
  Result.G := Round(AFrom.G + (ATo.G - AFrom.G) * AAmount);
  Result.B := Round(AFrom.B + (ATo.B - AFrom.B) * AAmount);
end;

function TXorShift.NextUnit: Single;
begin
  Seed := Seed xor (Seed shl 13);
  Seed := Seed xor (Seed shr 17);
  Seed := Seed xor (Seed shl 5);
  Result := (Seed and $FFFF) / $10000;
end;

function NumberWidth(AValue: Integer): Integer;
begin
  Result := Length(IntToStr(AValue)) * DigitAdvance - DigitPixel;
end;

function HealthColor(AHealth: Integer): TRgb;
begin
  case AHealth of
    0, 1: Result := AlarmColor;
    2: Result := WaryColor;
  else
    Result := CalmColor;
  end;
end;

constructor THudBrush.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FRenderer := ARenderer;
end;

procedure THudBrush.BeginDraw;
begin
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
end;

procedure THudBrush.EndDraw;
begin
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeNone);
end;

procedure THudBrush.Fill(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
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

procedure THudBrush.Glow(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
begin
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeAdd);
  Fill(AX, AY, AW, AH, AColor, AAlpha);
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
end;

procedure THudBrush.Frame(AX, AY, AW, AH: Single; AColor: TRgb; AAlpha: Single);
begin
  Fill(AX, AY, AW, 1, AColor, AAlpha);
  Fill(AX, AY + AH - 1, AW, 1, AColor, AAlpha);
  Fill(AX, AY + 1, 1, AH - 2, AColor, AAlpha);
  Fill(AX + AW - 1, AY + 1, 1, AH - 2, AColor, AAlpha);
end;

procedure THudBrush.DrawNumber(AValue: Integer; AX, AY: Single; AColor: TRgb;
  AAlpha: Single);
begin
  var Text := IntToStr(AValue);
  for var i := 1 to Length(Text) do
    DrawDigit(Ord(Text[i]) - Ord('0'), AX + (i - 1) * DigitAdvance, AY,
      AColor, AAlpha);
end;

procedure THudBrush.DrawDigit(ADigit: Integer; AX, AY: Single; AColor: TRgb;
  AAlpha: Single);
begin
  var Glyph := DigitGlyphs[ADigit];
  for var i := 0 to DigitCols * DigitRows - 1 do
  begin
    if Glyph[i + 1] = '0' then
      Continue;
    Fill(AX + (i mod DigitCols) * DigitPixel, AY + (i div DigitCols) * DigitPixel,
      DigitPixel, DigitPixel, AColor, AAlpha);
  end;
end;

procedure THudBrush.FullCell(AX, AY, AW, AH: Single; AColor: TRgb;
  AAlpha: Single);
begin
  Fill(AX, AY, AW, AH, AColor, AAlpha);
  Glow(AX, AY, AW, 1, White, 0.35 * AAlpha);
end;

procedure THudBrush.EmptyCell(AX, AY, AW, AH: Single; AColor: TRgb;
  AAlpha: Single);
begin
  Fill(AX, AY, AW, AH, AColor, 0.08 * AAlpha);
  Frame(AX, AY, AW, AH, AColor, 0.3 * AAlpha);
end;

procedure THudBrush.BonusCell(AX, AY, AW, AH: Single; AAlpha: Single);
begin
  Fill(AX, AY, AW, AH, BonusColor, AAlpha);
  Glow(AX, AY, AW, 1, White, 0.35 * AAlpha);
  Fill(AX, AY + AH - 1, AW, 1, BonusShade, 0.8 * AAlpha);
end;

end.
