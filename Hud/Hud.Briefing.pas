{
  Hud.Briefing - the story before a level, typed out over the menu sky
  the way the comm terminal types a hint: same letters a tick, same
  clicks, same cursor. No frame - the whole screen is the transmission -
  only a dark plate under the text, so the drifting moon never swallows
  the letters.

  The author's line breaks and indents are kept as written; nothing is
  re-wrapped. A key while the text types finishes it; once it is out,
  the prompt blinks under it and the next key belongs to the game.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Briefing;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Font, Render.Brush, Hud.Typewriter;

type
  THudBriefing = class
  private
    FFont: TMoonFont;
    FBrush: THudBrush;
    FTypewriter: TTypewriter;
    FFrameWidth: Integer;
    FHeader: string;
    function TextWidth: Single;
    procedure DrawPlate;
    procedure DrawCursor;
    procedure DrawText;
    procedure DrawPrompt(const APrompt: string);
  public
    constructor Create(const AFont: TMoonFont; ARenderer: PSdlRenderer;
      AFrameWidth: Integer);
    destructor Destroy; override;
    // AText as the level file holds it: LF-separated, laid out by hand
    procedure Start(const AHeader, AText: string);
    procedure Tick;
    procedure Finish;
    function Done: Boolean;
    // APrompt shows only once the text is out
    procedure Draw(const APrompt: string);
    function KeyStruck: Boolean;
  end;

implementation

uses
  System.SysUtils;

const
  // The layout the 2008 story screen used: the widest level1 line sits
  // roughly centered from here
  TextLeft = 26;
  TextTop = 60;
  HeaderGap = 6;
  PlatePadding = 10;
  PromptY = 344;

  PlateAlpha = 0.72;
  HeaderAlpha = 0.55;
  CursorAlpha = 0.9;

constructor THudBriefing.Create(const AFont: TMoonFont;
  ARenderer: PSdlRenderer; AFrameWidth: Integer);
begin
  inherited Create;
  FFont := AFont;
  FFrameWidth := AFrameWidth;
  FBrush := THudBrush.Create(ARenderer);
  FTypewriter := TTypewriter.Create;
end;

destructor THudBriefing.Destroy;
begin
  FTypewriter.Free;
  FBrush.Free;
  inherited;
end;

procedure THudBriefing.Start(const AHeader, AText: string);
begin
  FHeader := AHeader;
  FTypewriter.Start(AText.Split([#10]));
end;

procedure THudBriefing.Tick;
begin
  FTypewriter.Tick;
end;

procedure THudBriefing.Finish;
begin
  FTypewriter.Finish;
end;

function THudBriefing.Done: Boolean;
begin
  Result := FTypewriter.Done;
end;

function THudBriefing.KeyStruck: Boolean;
begin
  Result := FTypewriter.KeyStruck;
end;

function THudBriefing.TextWidth: Single;
begin
  Result := FFont.SmallTextWidth('> ' + FHeader);
  for var Line in FTypewriter.Lines do
    if FFont.SmallTextWidth(Line) > Result then
      Result := FFont.SmallTextWidth(Line);
end;

procedure THudBriefing.Draw(const APrompt: string);
begin
  FBrush.BeginDraw;
  DrawPlate;
  DrawCursor;
  FBrush.EndDraw;

  DrawText;
  DrawPrompt(APrompt);
end;

procedure THudBriefing.DrawPlate;
begin
  var HeaderTop := TextTop - SmallGlyphHeight - HeaderGap;
  var TextBottom := TextTop + Length(FTypewriter.Lines) * SmallLineStep;
  FBrush.Fill(TextLeft - PlatePadding, HeaderTop - PlatePadding,
    TextWidth + 2 * PlatePadding, TextBottom - HeaderTop + 2 * PlatePadding,
    PanelColor, PlateAlpha);
end;

procedure THudBriefing.DrawCursor;
begin
  var Pace := bpTyping;
  if FTypewriter.Done then
    Pace := bpOnHold;
  if not FTypewriter.CursorVisible(Pace) then
    Exit;
  FBrush.Fill(TextLeft + FTypewriter.CursorColumn * SmallAdvance + 1,
    TextTop + FTypewriter.CursorRow * SmallLineStep, SmallAdvance - 1,
    SmallGlyphHeight, CalmColor, CursorAlpha);
end;

procedure THudBriefing.DrawText;
begin
  FFont.DrawSmall('> ' + FHeader, TextLeft,
    TextTop - SmallGlyphHeight - HeaderGap, Round(255 * HeaderAlpha));
  for var i := 0 to High(FTypewriter.Lines) do
    FFont.DrawSmall(FTypewriter.Shown(i), TextLeft, TextTop + i * SmallLineStep);
end;

// The prompt blinks at the waiting cursor's pace
procedure THudBriefing.DrawPrompt(const APrompt: string);
begin
  if not FTypewriter.Done then
    Exit;
  if not FTypewriter.CursorVisible(bpOnHold) then
    Exit;
  FFont.DrawSmall(APrompt, (FFrameWidth - FFont.SmallTextWidth(APrompt)) / 2,
    PromptY);
end;

end.
