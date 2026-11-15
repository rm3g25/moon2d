{
  Hud.Titles - what the titles show (docs/mechanics/finale-flight.md): over
  the picture the flight leaves, the studio's card, then the menu's logo
  flaring where the card stood, over the farm's crown, and the white of the
  logo's flash over the frame; at the stars, the two phrases, the lines of
  the credits and the last screen. Each as the titles' clock says
  (Game.Titles). The card and the logo stand in the world, so they are
  drawn where its shake has it. The dark the flight ends in lies over the
  whole frame, the far layers too: it is drawn by itself.

  The last screen is drawn and clicked by one geometry: what is seen is
  what is clicked.

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
    procedure DrawBigCentered(const AText: string; ATop, ALevel: Single);
    procedure DrawSmallCentered(const AText: string; ATop, ALevel: Single);
    function AuthorRect: TSdlFRect;
    function MainMenuRect: TSdlFRect;
  public
    // AFont, ALogo - the menu's - and ATitles belong to the caller and
    // must outlive the painter
    constructor Create(ARenderer: PSdlRenderer; const AFont: TMoonFont;
      ALogo: TMenuLogo; ATitles: TTitles);
    destructor Destroy; override;
    // AOrigin - the world's shake
    procedure Draw(const AOrigin: TSdlPoint; AAlpha: Single);
    // The dark over the frame as the path ends
    procedure DrawDark(AAlpha: Single);
    // The phrases and the credits at the stars
    procedure DrawAtTheStars(AAlpha: Single);
    // The last screen, ALevel of it, 0..1: the author's line with its
    // note, and the way to the menu
    procedure DrawLast(ALevel: Single);
    // The mouse at AX, AY, game units, over the author's line or its note
    function HitsAuthor(AX, AY: Single): Boolean;
    // The same over "Main menu"
    function HitsMainMenu(AX, AY: Single): Boolean;
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
  Dark: TRgb = (R: 0; G: 0; B: 0);

  // At the stars the lines stand in the lower half, under the Earth's
  // first way: the phrases one under the other, a line of the credits
  // where they stood
  MissionTop = 262.0;
  PromiseTop = 287.0;
  CreditTop = 280.0;
  // The last screen: the author, his note under him, the way to the menu
  AuthorTop = 230.0;
  NoteTop = 247.0;
  MainMenuTop = 285.0;
  // A click this near a line still takes it
  HitMargin = 3.0;

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

function Opacity(ALevel: Single): UInt8;
begin
  Result := Round(OpaqueAlpha * ALevel);
end;

// On the middle of the logo's place: the logo flares where the card stood
procedure THudTitles.DrawCard(const AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Level := FTitles.CardLevel(AAlpha);
  if Level <= 0 then
    Exit;
  var Card := Tr(SCreditsLine1);
  FFont.DrawBig(Card, AOrigin.X + PlaceMiddle - FFont.BigTextWidth(Card) / 2,
    AOrigin.Y + PlaceTop + (PlaceHeight - BigGlyphHeight) / 2, Opacity(Level));
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

procedure THudTitles.DrawDark(AAlpha: Single);
begin
  var Level := FTitles.DarkLevel(AAlpha);
  if Level <= 0 then
    Exit;
  FBrush.BeginDraw;
  FBrush.Fill(0, 0, FrameWidth, FrameHeight, Dark, Level);
  FBrush.EndDraw;
end;

procedure THudTitles.DrawBigCentered(const AText: string; ATop, ALevel: Single);
begin
  if ALevel <= 0 then
    Exit;
  FFont.DrawBig(AText, (FrameWidth - FFont.BigTextWidth(AText)) / 2, ATop,
    Opacity(ALevel));
end;

procedure THudTitles.DrawSmallCentered(const AText: string; ATop, ALevel: Single);
begin
  if ALevel <= 0 then
    Exit;
  FFont.DrawSmall(AText, (FrameWidth - FFont.SmallTextWidth(AText)) / 2, ATop,
    Opacity(ALevel));
end;

procedure THudTitles.DrawAtTheStars(AAlpha: Single);
begin
  if not FTitles.AtTheStars then
    Exit;
  DrawBigCentered(Tr(SEndingMission), MissionTop, FTitles.MissionLevel(AAlpha));
  DrawBigCentered(Tr(SEndingReturn), PromiseTop, FTitles.PromiseLevel(AAlpha));
  var Lines: TArray<string> := [Tr(SCreditsLine3), Tr(SCreditsLine4),
    Tr(SCreditsLine5)];
  for var i := 0 to High(Lines) do
    DrawSmallCentered(Lines[i], CreditTop, FTitles.CreditLevel(i, AAlpha));
end;

procedure THudTitles.DrawLast(ALevel: Single);
begin
  DrawBigCentered(Tr(SEndingAuthor), AuthorTop, ALevel);
  DrawSmallCentered(Tr(SEndingAuthorNote), NoteTop, ALevel);
  DrawBigCentered(Tr(SEndingMenu), MainMenuTop, ALevel);
end;

// The wider of the author's line and its note, from the one's top to the
// other's foot
function THudTitles.AuthorRect: TSdlFRect;
begin
  var AuthorWidth := FFont.BigTextWidth(Tr(SEndingAuthor));
  var NoteWidth := FFont.SmallTextWidth(Tr(SEndingAuthorNote));
  Result.W := AuthorWidth;
  if NoteWidth > AuthorWidth then
    Result.W := NoteWidth;
  Result.X := (FrameWidth - Result.W) / 2;
  Result.Y := AuthorTop;
  Result.H := NoteTop + SmallGlyphHeight - AuthorTop;
end;

function THudTitles.MainMenuRect: TSdlFRect;
begin
  Result.W := FFont.BigTextWidth(Tr(SEndingMenu));
  Result.X := (FrameWidth - Result.W) / 2;
  Result.Y := MainMenuTop;
  Result.H := BigGlyphHeight;
end;

function Hits(const ARect: TSdlFRect; AX, AY: Single): Boolean;
begin
  Result := (AX >= ARect.X - HitMargin) and (AX <= ARect.X + ARect.W + HitMargin) and
    (AY >= ARect.Y - HitMargin) and (AY <= ARect.Y + ARect.H + HitMargin);
end;

function THudTitles.HitsAuthor(AX, AY: Single): Boolean;
begin
  Result := Hits(AuthorRect, AX, AY);
end;

function THudTitles.HitsMainMenu(AX, AY: Single): Boolean;
begin
  Result := Hits(MainMenuRect, AX, AY);
end;

end.
