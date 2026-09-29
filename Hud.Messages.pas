{
  Hud.Messages - the message board, SDL2 heir of moonmessage.pas (2008).

  Three mechanics survive from the original, the fourth lane is new:

  1. TICKER (AddMess of 2008): stacking notice lines at the top-left.
     A fresh line slides in from the left - the 'фишка с выдвиганием' -
     one 2008-column per tick until it parks at column 2. Lines stack
     downward, oldest on top; when one expires the rest close ranks.
     Deviations agreed for the remake: the stack is capped at 5 lines
     (2008 allowed 100 - a wall of text) with the oldest evicted by the
     newcomer, and an expiring line fades to transparent instead of
     blinking out.

  2. TERMINAL (in place of the 2008 RunningString): long texts - the
     tutorial hints, the '_string:' of .mon - no longer crawl right to
     left; they type out in the comm box of Hud.Terminal under the heart
     monitor. The ticker steps down below the box while it stands and
     climbs back when it is gone.

  3. BIG MESSAGE (AddBigMessage of 2008): one headline mid-screen -
     level titles, bonuses, EVOLUTION. A newcomer replaces the current.
     The remake may hang a small note under it for the same lifetime.

  4. SCORE POPUPS (AddScoreMessage of 2008): '+N' floating up from a
     kill. Structure verbatim; monst.pas (1248) confirms the lifetime
     and the '+N' format. The 2008 rise speed was score-proportional
     with jitter - the remake's calm constant is a deviation under
     review (refactoring.md item 24).

  Slow movers (popups, the ticker making room) advance on logic ticks
  but render at frame rate: Draw takes the fixed-timestep interpolation
  alpha and slides them between the previous and current tick positions.

  The board owns no textures - it borrows a TMoonFont for drawing and
  expects Tick once per logic tick and Draw once per frame.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Messages;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Render.Font, Hud.Terminal;

type
  TMessageBoard = class
  private
    type
      TTickerLine = record
        Text: string;
        TicksLeft: Integer;
        TicksTotal: Integer; // for the slide-in: elapsed = total - left
      end;

      TScorePopup = record
        Text: string;
        TicksLeft: Integer;
        X, Y: Double;
      end;
  private
    FFont: TMoonFont;
    FFrameWidth: Integer; // the big headline centers on the display
    FTicker: TArray<TTickerLine>;
    FBigText: string;
    FBigNote: string;
    FBigTicksLeft: Integer;
    FTerminal: THudTerminal;
    FTickerShift: Double; // how far the ticker stepped down for the box
    FTickerShiftBefore: Double; // the same one tick ago, for interpolation
    FPopups: TArray<TScorePopup>;
    procedure ShiftTicker;
    procedure AgeTicker;
    procedure AgePopups;
    procedure DrawTicker(AAlpha: Double);
    procedure DrawPopups(AAlpha: Double);
    procedure DrawBig;
  public
    constructor Create(const AFont: TMoonFont; ARenderer: PSdlRenderer;
      AFrameWidth: Integer);
    destructor Destroy; override;

    // Drops everything - StartMess of 2008. Death silences the board.
    procedure Clear;
    // One logic tick: lifetimes, typing, motion - Timer of 2008.
    procedure Tick;
    // PutMess of 2008. AAlpha is the fixed-timestep interpolation
    // fraction from Render - smooths the popups and the ticker's step.
    procedure Draw(AAlpha: Double);

    // AddMess of 2008: a notice line for the ticker. '' is ignored.
    procedure AddTicker(const AText: string; ATicks: Integer);
    // AddBigMessage of 2008: the mid-screen headline. '' is ignored.
    // ANote is a small line under it, gone with the headline.
    procedure ShowBig(const AText: string; ATicks: Integer;
      const ANote: string = '');
    // A long text for the comm terminal under AHeader; replaces the one
    // being typed. '' is ignored.
    procedure StartTerminal(const AHeader, AText: string);
    // True on a tick the terminal typed a clicking key - the game owns
    // the sound
    function TerminalKeyStruck: Boolean;
    // The game's verdict each tick: the fight the hint waits for is on
    procedure HoldTerminal(AHeld: Boolean);
    // AddScoreMessage of 2008: '+N' rising from a kill. Coordinates are
    // game units of the popup's top-left. '' is ignored.
    procedure AddScorePopup(const AText: string; AX, AY: Double);
    // Popups are positional: a screen transition strands them over the
    // wrong geometry, so the game wipes them alongside the bullets.
    procedure ClearPopups;
  end;

const
  // The standard life of a headline: bonuses, EVOLUTION, ICE FORM, the
  // boss break (2008 passim)
  BigMessageTicks = 100;

implementation

uses
  System.Math;

const
  MaxTickerLines = 5; // grown-up cap; the 2008 board stacked up to 100

  // Ticker lane: 2008 drew at column 2 from row 3 downward. The rows
  // start just under the terminal's top edge, so while the box stands
  // the stack steps down below it.
  TickerX = 2 * LegacyColumnWidth;
  TickerTopY = 52;
  FadeTicks = 33; // ~1 s of fade-out at tickRate 33 (remake deviation)
  TickerBelowBoxGap = 4;
  TickerShiftStep = 4; // game units per tick: a 60-unit step in ~0.5 s

  // Score popups: mechanics verbatim moonmessage.pas (rise per tick,
  // hard vanish); the caller finally surfaced and testified.
  PopupTicks = 50;      // verbatim monst.pas 1248: AddScoreMessage(.., 50, ..)
  // DEVIATION: 2008 rose at (scor + random(5)/10) per tick - a '+10'
  // boss popup rocketed, a '+1' floated. Decision pending (item 24).
  PopupRiseSpeed = 0.5; // game units upward per tick

  // Big message: 2008 drew line2 at row 12 (y = 12 * 12.48). The
  // horizontal was approximated as (17 - len/2) columns; the remake
  // centers exactly - same look, honest math.
  BigMessageY = 150;
  BigNoteGap = 6;

constructor TMessageBoard.Create(const AFont: TMoonFont;
  ARenderer: PSdlRenderer; AFrameWidth: Integer);
begin
  inherited Create;
  FFont := AFont;
  FFrameWidth := AFrameWidth;
  FTerminal := THudTerminal.Create(AFont, ARenderer);
end;

destructor TMessageBoard.Destroy;
begin
  FTerminal.Free;
  inherited;
end;

procedure TMessageBoard.Clear;
begin
  FTicker := nil;
  FPopups := nil;
  FBigTicksLeft := 0;
  FTerminal.Clear;
  FTickerShift := 0;
  FTickerShiftBefore := 0;
end;

procedure TMessageBoard.ClearPopups;
begin
  FPopups := nil;
end;

procedure TMessageBoard.AddTicker(const AText: string; ATicks: Integer);
begin
  if AText = '' then
    Exit;

  // The oldest line yields its seat to the newcomer.
  if Length(FTicker) = MaxTickerLines then
    Delete(FTicker, 0, 1);

  var Line := Default(TTickerLine);
  Line.Text := AText;
  Line.TicksLeft := ATicks;
  Line.TicksTotal := ATicks;
  FTicker := FTicker + [Line];
end;

procedure TMessageBoard.ShowBig(const AText: string; ATicks: Integer;
  const ANote: string);
begin
  if AText = '' then
    Exit;
  FBigText := AText;
  FBigNote := ANote;
  FBigTicksLeft := ATicks;
end;

procedure TMessageBoard.StartTerminal(const AHeader, AText: string);
begin
  FTerminal.Start(AHeader, AText);
end;

function TMessageBoard.TerminalKeyStruck: Boolean;
begin
  Result := FTerminal.KeyStruck;
end;

procedure TMessageBoard.HoldTerminal(AHeld: Boolean);
begin
  FTerminal.Held := AHeld;
end;

procedure TMessageBoard.AddScorePopup(const AText: string; AX, AY: Double);
begin
  if AText = '' then
    Exit;
  var Popup := Default(TScorePopup);
  Popup.Text := AText;
  Popup.TicksLeft := PopupTicks;
  Popup.X := AX;
  Popup.Y := AY;
  FPopups := FPopups + [Popup];
end;

procedure TMessageBoard.ShiftTicker;
begin
  FTickerShiftBefore := FTickerShift;
  var Target: Double := 0;
  if FTerminal.Visible then
    Target := FTerminal.Bottom + TickerBelowBoxGap - TickerTopY;
  if FTickerShift < Target then
    FTickerShift := Min(Target, FTickerShift + TickerShiftStep)
  else
    FTickerShift := Max(Target, FTickerShift - TickerShiftStep);
end;

// Ages the lines and compacts the survivors: when a line dies the ones
// below close ranks upward, as the 2008 Timer shifted YCord.
procedure TMessageBoard.AgeTicker;
begin
  var Alive := 0;
  for var i := 0 to High(FTicker) do
  begin
    Dec(FTicker[i].TicksLeft);
    if FTicker[i].TicksLeft > 0 then
    begin
      FTicker[Alive] := FTicker[i];
      Inc(Alive);
    end;
  end;
  SetLength(FTicker, Alive);
end;

// Same compaction as AgeTicker; a popup also rises while it lives.
procedure TMessageBoard.AgePopups;
begin
  var Alive := 0;
  for var i := 0 to High(FPopups) do
  begin
    FPopups[i].Y := FPopups[i].Y - PopupRiseSpeed;
    Dec(FPopups[i].TicksLeft);
    if FPopups[i].TicksLeft > 0 then
    begin
      FPopups[Alive] := FPopups[i];
      Inc(Alive);
    end;
  end;
  SetLength(FPopups, Alive);
end;

procedure TMessageBoard.Tick;
begin
  if FBigTicksLeft > 0 then
    Dec(FBigTicksLeft);
  FTerminal.Tick;
  ShiftTicker;
  AgeTicker;
  AgePopups;
end;

procedure TMessageBoard.Draw(AAlpha: Double);
begin
  FTerminal.Draw;
  DrawPopups(AAlpha);
  DrawTicker(AAlpha);
  DrawBig;
end;

procedure TMessageBoard.DrawTicker(AAlpha: Double);
begin
  var TopY := TickerTopY + FTickerShiftBefore +
    (FTickerShift - FTickerShiftBefore) * AAlpha;
  for var i := 0 to High(FTicker) do
  begin
    // 'Фишка с выдвиганием' verbatim: while elapsed ticks < text length
    // the line hangs (length - elapsed) columns to the left and slides
    // right one column per tick. Yes, the slide counts CHARACTERS but
    // moves COLUMNS (12.8 units vs 7.68 per glyph) - so the text drives
    // in faster than one glyph per tick. That is the 2008 look.
    var Elapsed := FTicker[i].TicksTotal - FTicker[i].TicksLeft;
    var SlideColumns := Length(FTicker[i].Text) - Elapsed;
    if SlideColumns < 0 then
      SlideColumns := 0;

    var Alpha: UInt8 := 255;
    if FTicker[i].TicksLeft < FadeTicks then
      Alpha := Round(255 * FTicker[i].TicksLeft / FadeTicks);

    FFont.DrawSmall(FTicker[i].Text,
      TickerX - SlideColumns * LegacyColumnWidth,
      TopY + i * SmallLineStep, Alpha);
  end;
end;

procedure TMessageBoard.DrawPopups(AAlpha: Double);
begin
  for var i := 0 to High(FPopups) do
    FFont.DrawSmall(FPopups[i].Text, FPopups[i].X,
      FPopups[i].Y + PopupRiseSpeed * (1 - AAlpha));
end;

procedure TMessageBoard.DrawBig;
begin
  if FBigTicksLeft <= 0 then
    Exit;
  FFont.DrawBig(FBigText,
    (FFrameWidth - FFont.BigTextWidth(FBigText)) / 2, BigMessageY);
  if FBigNote <> '' then
    FFont.DrawSmall(FBigNote, (FFrameWidth - FFont.SmallTextWidth(FBigNote)) / 2,
      BigMessageY + BigGlyphHeight + BigNoteGap);
end;

end.
