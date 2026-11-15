{
  Hud.Titles - what the titles show over the picture the flight ends on
  (docs/mechanics/finale-flight.md): the studio's card, then the menu's
  logo flaring where the card stood, over the farm's crown; and the white
  of the logo's flash over the frame. Each as the titles' clock says
  (Game.Titles). They stand in the world, so they are drawn where its shake
  has it. The dark the flight ends in lies over the whole frame, the far
  layers too: it is drawn by itself, last.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Titles;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Font, Render.Brush, Menu.Logo, Game.Titles;

type
  THudTitles = class
  private
    FFont: TMoonFont;
    FLogo: TMenuLogo;
    FTitles: TTitles;
    FBrush: THudBrush;
    procedure DrawCard(const AOrigin: TSdlPoint; AAlpha: Single);
    procedure DrawLogo(const AOrigin: TSdlPoint; AAlpha: Single);
    procedure DrawFlash(AAlpha: Single);
  public
    // AFont, ALogo - the menu's - and ATitles belong to the caller and
    // must outlive the painter
    constructor Create(ARenderer: PSdlRenderer; const AFont: TMoonFont;
      ALogo: TMenuLogo; ATitles: TTitles);
    destructor Destroy; override;
    // AOrigin - the world's shake
    procedure Draw(const AOrigin: TSdlPoint; AAlpha: Single);
    // The dark over the frame as the flight ends
    procedure DrawTail(AAlpha: Single);
  end;

implementation

uses
  Game.Space, Localization;

const
  // Where the logo flares: over the farm's crown, with room for its fire
  PlaceLeft = 136.0;
  PlaceTop = 60.0;
  PlaceWidth = 240.0;
  PlaceHeight = 96.0;
  PlaceMiddle = PlaceLeft + PlaceWidth / 2;
  // The frame at the flash is this white at the most
  FlashWhite = 0.85;
  OpaqueAlpha = 255;
  TailDark: TRgb = (R: 0; G: 0; B: 0);

constructor THudTitles.Create(ARenderer: PSdlRenderer; const AFont: TMoonFont;
  ALogo: TMenuLogo; ATitles: TTitles);
begin
  inherited Create;
  FFont := AFont;
  FLogo := ALogo;
  FTitles := ATitles;
  FBrush := THudBrush.Create(ARenderer);
end;

destructor THudTitles.Destroy;
begin
  FBrush.Free;
  inherited;
end;

// On the middle of the logo's place: the logo flares where the card stood
procedure THudTitles.DrawCard(const AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Level := FTitles.CardLevel(AAlpha);
  if Level <= 0 then
    Exit;
  var Card := Tr(SCreditsLine1);
  FFont.DrawBig(Card, AOrigin.X + PlaceMiddle - FFont.BigTextWidth(Card) / 2,
    AOrigin.Y + PlaceTop + (PlaceHeight - BigGlyphHeight) / 2,
    Round(OpaqueAlpha * Level));
end;

// As tall as its place, as wide as its letters make it
procedure THudTitles.DrawLogo(const AOrigin: TSdlPoint; AAlpha: Single);
var
  Dest: TSdlFRect;
begin
  if not FTitles.LogoShown then
    Exit;
  Dest.H := PlaceHeight;
  Dest.W := PlaceHeight * FLogo.Aspect;
  Dest.X := AOrigin.X + PlaceMiddle - Dest.W / 2;
  Dest.Y := AOrigin.Y + PlaceTop;
  FLogo.Draw(Dest, AAlpha);
end;

procedure THudTitles.DrawFlash(AAlpha: Single);
begin
  var Level := FTitles.FlashLevel(AAlpha);
  if Level <= 0 then
    Exit;
  FBrush.BeginDraw;
  FBrush.Fill(0, 0, FrameWidth, FrameHeight, White, FlashWhite * Level);
  FBrush.EndDraw;
end;

procedure THudTitles.Draw(const AOrigin: TSdlPoint; AAlpha: Single);
begin
  if not FTitles.Running then
    Exit;
  DrawCard(AOrigin, AAlpha);
  DrawLogo(AOrigin, AAlpha);
  DrawFlash(AAlpha);
end;

procedure THudTitles.DrawTail(AAlpha: Single);
begin
  var Level := FTitles.TailLevel(AAlpha);
  if Level <= 0 then
    Exit;
  FBrush.BeginDraw;
  FBrush.Fill(0, 0, FrameWidth, FrameHeight, TailDark, Level);
  FBrush.EndDraw;
end;

end.
