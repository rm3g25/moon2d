{
  Hud.Terminal - the station's comm channel: a framed box under the heart
  monitor where a long hint types itself out letter by letter behind a
  blinking cursor, stands long enough to be read, and fades. The reader
  sets the pace by glancing at it, not the text by crawling past.

  The header line names who speaks. Today it is the channel itself, or
  the voice a level gives a transmission; voiced lines later keep the
  same box. Where the box stands is the caller's word: under the heart
  monitor, or along the bottom edge on a screen where the hero comes
  in at the top and the monitor corner would sit on him.

  The typing itself is Hud.Typewriter's. The terminal makes no sound of
  its own: KeyStruck goes up on the ticks a key should click, and the
  game plays the click.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Terminal;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Font, Render.Brush, Hud.Typewriter;

type
  TTerminalPhase = (tpOff, tpTyping, tpHolding, tpFading);
  TTerminalPlace = (tlTop, tlBottom);

  THudTerminal = class
  private
    FFont: TMoonFont;
    FBrush: THudBrush;
    FTypewriter: TTypewriter;
    FHeader: string;
    FPhase: TTerminalPhase;
    FPlace: TTerminalPlace;
    FPhaseTicksLeft: Integer;
    FKeyStruck: Boolean;
    procedure EnterPhase(APhase: TTerminalPhase; ATicks: Integer);
    procedure CountDown(ANextPhase: TTerminalPhase; ANextTicks: Integer);
    function BoxHeight: Single;
    function BoxY: Single;
    function TextTop: Single;
    function Opacity: Single;
    function CursorVisible: Boolean;
    procedure DrawBox(AOpacity: Single);
    procedure DrawCursor(AOpacity: Single);
    procedure DrawText(AOpacity: Single);
  public
    constructor Create(const AFont: TMoonFont; ARenderer: PSdlRenderer);
    destructor Destroy; override;
    // A newcomer replaces the message mid-way: a hint belongs to the
    // screen that fired it, and takes its place with it. A text with no
    // words is ignored.
    procedure Start(const AHeader, AText: string;
      APlace: TTerminalPlace = tlTop);
    procedure Clear;
    procedure Tick;
    procedure Draw;
    function Visible: Boolean;
    // The lowest game-unit Y the box covers; meaningful while Visible
    function Bottom: Single;
    property KeyStruck: Boolean read FKeyStruck;
    // Where the box stands now; the ticker steps aside only for the top
    property Place: TTerminalPlace read FPlace;
  end;

implementation

uses
  System.SysUtils, Game.Space;

const
  BoxX = PanelMargin;
  TopBoxY = PanelY + PanelH + 4;
  BottomGap = PanelMargin;
  BoxW = 360;
  Padding = 6;
  LineStep = SmallLineStep + 3;
  HeaderGap = 3;
  MaxLineChars = Trunc((BoxW - 2 * Padding) / SmallAdvance);

  // Reading time on top of the typing: a second to find the box, then a
  // tick per letter
  ReadBaseTicks = 33;
  ReadTicksPerChar = 1;
  FadeTicks = 33;

  BoxAlpha = 0.72;
  FrameAlpha = 0.45;
  HeaderAlpha = 0.55;
  CursorAlpha = 0.9;

// Word wrap by glyph count - the small font is monospaced, so a count is
// an exact width. A word longer than the line overflows it.
function WrapWords(const AText: string; AMaxChars: Integer): TArray<string>;
begin
  Result := nil;
  var Line := '';
  for var NextWord in AText.Split([' '], TStringSplitOptions.ExcludeEmpty) do
  begin
    if Line = '' then
      Line := NextWord
    else if Length(Line) + 1 + Length(NextWord) <= AMaxChars then
      Line := Line + ' ' + NextWord
    else
    begin
      Result := Result + [Line];
      Line := NextWord;
    end;
  end;
  if Line <> '' then
    Result := Result + [Line];
end;

constructor THudTerminal.Create(const AFont: TMoonFont;
  ARenderer: PSdlRenderer);
begin
  inherited Create;
  FFont := AFont;
  FBrush := THudBrush.Create(ARenderer);
  FTypewriter := TTypewriter.Create;
end;

destructor THudTerminal.Destroy;
begin
  FTypewriter.Free;
  FBrush.Free;
  inherited;
end;

procedure THudTerminal.Start(const AHeader, AText: string;
  APlace: TTerminalPlace);
begin
  var Lines := WrapWords(AText, MaxLineChars);
  if Lines = nil then
    Exit;
  FHeader := AHeader;
  FPlace := APlace;
  FTypewriter.Start(Lines);
  EnterPhase(tpTyping, 0);
end;

procedure THudTerminal.Clear;
begin
  FPhase := tpOff;
  FKeyStruck := False;
end;

procedure THudTerminal.EnterPhase(APhase: TTerminalPhase; ATicks: Integer);
begin
  FPhase := APhase;
  FPhaseTicksLeft := ATicks;
end;

procedure THudTerminal.Tick;
begin
  FKeyStruck := False;
  if FPhase = tpOff then
    Exit;
  FTypewriter.Tick;
  FKeyStruck := FTypewriter.KeyStruck;

  case FPhase of
    tpTyping:
      if FTypewriter.Done then
        EnterPhase(tpHolding,
          ReadBaseTicks + FTypewriter.CharCount * ReadTicksPerChar);
    tpHolding:
      CountDown(tpFading, FadeTicks);
    tpFading:
      CountDown(tpOff, 0);
  end;
end;

procedure THudTerminal.CountDown(ANextPhase: TTerminalPhase;
  ANextTicks: Integer);
begin
  Dec(FPhaseTicksLeft);
  if FPhaseTicksLeft <= 0 then
    EnterPhase(ANextPhase, ANextTicks);
end;

function THudTerminal.Visible: Boolean;
begin
  Result := FPhase <> tpOff;
end;

function THudTerminal.BoxHeight: Single;
begin
  Result := 2 * Padding + SmallGlyphHeight + HeaderGap +
    Length(FTypewriter.Lines) * LineStep - (LineStep - SmallGlyphHeight);
end;

// The bottom box grows upward from the edge, so its top follows the
// number of lines it holds
function THudTerminal.BoxY: Single;
begin
  if FPlace = tlBottom then
    Result := FrameHeight - BottomGap - BoxHeight
  else
    Result := TopBoxY;
end;

function THudTerminal.TextTop: Single;
begin
  Result := BoxY + Padding + SmallGlyphHeight + HeaderGap;
end;

function THudTerminal.Bottom: Single;
begin
  Result := BoxY + BoxHeight;
end;

function THudTerminal.Opacity: Single;
begin
  if FPhase = tpFading then
    Result := FPhaseTicksLeft / FadeTicks
  else
    Result := 1;
end;

function THudTerminal.CursorVisible: Boolean;
begin
  if FPhase = tpFading then
    Exit(False);
  Result := FTypewriter.CursorVisible(bpTyping);
end;

procedure THudTerminal.Draw;
begin
  if FPhase = tpOff then
    Exit;
  var Fade := Opacity;

  FBrush.BeginDraw;
  DrawBox(Fade);
  if CursorVisible then
    DrawCursor(Fade);
  FBrush.EndDraw;

  DrawText(Fade);
end;

procedure THudTerminal.DrawBox(AOpacity: Single);
begin
  FBrush.Fill(BoxX, BoxY, BoxW, BoxHeight, PanelColor, BoxAlpha * AOpacity);
  FBrush.Frame(BoxX, BoxY, BoxW, BoxHeight, CalmColor, FrameAlpha * AOpacity);
end;

procedure THudTerminal.DrawCursor(AOpacity: Single);
begin
  FBrush.Fill(BoxX + Padding + FTypewriter.CursorColumn * SmallAdvance + 1,
    TextTop + FTypewriter.CursorRow * LineStep, SmallAdvance - 1,
    SmallGlyphHeight, CalmColor, CursorAlpha * AOpacity);
end;

procedure THudTerminal.DrawText(AOpacity: Single);
begin
  FFont.DrawSmall('> ' + FHeader, BoxX + Padding, BoxY + Padding,
    Round(255 * HeaderAlpha * AOpacity));
  for var i := 0 to High(FTypewriter.Lines) do
    FFont.DrawSmall(FTypewriter.Shown(i), BoxX + Padding,
      TextTop + i * LineStep, Round(255 * AOpacity));
end;

end.
