{
  Hud.Messages - the message board, SDL2 heir of moonmessage.pas (2008).

  Four mechanics survive from the original:

  1. TICKER (AddMess of 2008): stacking notice lines at the top-left.
     A fresh line slides in from the left - the 'фишка с выдвиганием' -
     one 2008-column per tick until it parks at column 2. Lines stack
     downward, oldest on top; when one expires the rest close ranks.
     Deviations agreed for the remake: the stack is capped at 5 lines
     (2008 allowed 100 - a wall of text) with the oldest evicted by the
     newcomer, and an expiring line fades to transparent instead of
     blinking out.

  2. MARQUEE (RunningString of 2008): the classic right-to-left running
     line for long texts - tutorial hints, the '_string:' of .mon.
     Position and speed are verbatim; only the lane moved slightly down,
     below the health icons - in 2008 they overlapped the text.

  3. BIG MESSAGE (AddBigMessage of 2008): one headline mid-screen -
     level titles, bonuses, EVOLUTION. A newcomer replaces the current.

  4. SCORE POPUPS (AddScoreMessage of 2008): '+N' floating up from a
     kill. Structure verbatim; monst.pas (1248) confirms the lifetime
     and the '+N' format. The 2008 rise speed was score-proportional
     with jitter - the remake's calm constant is a deviation under
     review (refactoring.md item 24).

  Slow movers (marquee, popups) advance on logic ticks but render at
  frame rate: Draw takes the fixed-timestep interpolation alpha and
  slides them between the previous and current tick positions.

  The board owns no textures - it borrows a TMoonFont for drawing and
  expects Tick once per logic tick and Draw once per frame.

  Moon 2D remake. Requires Delphi 12+.
}
unit Hud.Messages;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, Render.Font;

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
    FScreenWidth: Integer;
    FTicker: TArray<TTickerLine>;
    FBigText: string;
    FBigTicksLeft: Integer;
    FMarqueeText: string;
    FMarqueeX: Double;
    FMarqueeActive: Boolean;
    FPopups: TArray<TScorePopup>;
    procedure TickMarquee;
    procedure AgeTicker;
    procedure AgePopups;
    procedure DrawTicker;
    procedure DrawMarquee(AAlpha: Double);
    procedure DrawPopups(AAlpha: Double);
    procedure DrawBig;
  public
    constructor Create(const AFont: TMoonFont; AScreenWidth: Integer);

    // Drops everything - StartMess of 2008. Death silences the board.
    procedure Clear;
    // One logic tick: lifetimes, marquee motion - Timer of 2008.
    procedure Tick;
    // PutMess of 2008. AAlpha is the fixed-timestep interpolation
    // fraction from Render - smooths the marquee and the popups.
    procedure Draw(AAlpha: Double);

    // AddMess of 2008: a notice line for the ticker. '' is ignored.
    procedure AddTicker(const AText: string; ATicks: Integer);
    // AddBigMessage of 2008: the mid-screen headline. '' is ignored.
    procedure ShowBig(const AText: string; ATicks: Integer);
    // 'Бегущая строка' of 2008: starts the marquee, replacing any
    // current one mid-run - exactly as the original overwrote its vars.
    procedure StartMarquee(const AText: string);
    // AddScoreMessage of 2008: '+N' rising from a kill. Coordinates are
    // game units of the popup's top-left. '' is ignored.
    procedure AddScorePopup(const AText: string; AX, AY: Double);
    // Popups are positional: a screen transition strands them over the
    // wrong geometry, so the game wipes them alongside the bullets.
    procedure ClearPopups;
  end;

implementation

const
  MaxTickerLines = 5; // grown-up cap; the 2008 board stacked up to 100

  // Ticker lane: 2008 drew at column 2 from row 3 downward. Rows moved
  // below the marquee lane so the two never overlap.
  TickerX = 2 * LegacyColumnWidth;
  TickerTopY = 36;
  FadeTicks = 33; // ~1 s of fade-out at tickRate 33 (remake deviation)

  // Marquee: start and speed verbatim from moon.dpr. The lane is the
  // agreed deviation: 2008 ran it at row 2 (y=19.2) UNDER the health
  // display and it was hard to read; parked just below the icons now.
  MarqueeStartX = 41 * LegacyColumnWidth;  // RunningStringPos := 41
  MarqueeStepX = 0.15 * LegacyColumnWidth; // RunningStringPos - 0.15
  MarqueeY = 24;

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

constructor TMessageBoard.Create(const AFont: TMoonFont;
  AScreenWidth: Integer);
begin
  inherited Create;
  FFont := AFont;
  FScreenWidth := AScreenWidth;
end;

procedure TMessageBoard.Clear;
begin
  FTicker := nil;
  FPopups := nil;
  FBigTicksLeft := 0;
  FMarqueeActive := False;
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

procedure TMessageBoard.ShowBig(const AText: string; ATicks: Integer);
begin
  if AText = '' then
    Exit;
  FBigText := AText;
  FBigTicksLeft := ATicks;
end;

procedure TMessageBoard.StartMarquee(const AText: string);
begin
  if AText = '' then
    Exit;
  FMarqueeText := AText;
  FMarqueeX := MarqueeStartX;
  FMarqueeActive := True;
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

procedure TMessageBoard.TickMarquee;
begin
  if not FMarqueeActive then
    Exit;
  FMarqueeX := FMarqueeX - MarqueeStepX;
  // 2008 waited until column -Length; ending at the real text width
  // is the same moment for the eye and honest for the math.
  if FMarqueeX < -FFont.SmallTextWidth(FMarqueeText) then
    FMarqueeActive := False;
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
  TickMarquee;
  AgeTicker;
  AgePopups;
end;

procedure TMessageBoard.Draw(AAlpha: Double);
begin
  DrawMarquee(AAlpha);
  DrawPopups(AAlpha);
  DrawTicker;
  DrawBig;
end;

procedure TMessageBoard.DrawTicker;
begin
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
      TickerTopY + i * SmallLineStep, Alpha);
  end;
end;

procedure TMessageBoard.DrawMarquee(AAlpha: Double);
begin
  if not FMarqueeActive then
    Exit;
  // Interpolate between the previous tick position (X + step) and the
  // current one: logic runs at 33 Hz, frames come much faster - without
  // this the line freezes for a few frames and lurches 2 units at once.
  FFont.DrawSmall(FMarqueeText,
    FMarqueeX + MarqueeStepX * (1 - AAlpha), MarqueeY);
end;

procedure TMessageBoard.DrawPopups(AAlpha: Double);
begin
  for var i := 0 to High(FPopups) do
    FFont.DrawSmall(FPopups[i].Text, FPopups[i].X,
      FPopups[i].Y + PopupRiseSpeed * (1 - AAlpha));
end;

procedure TMessageBoard.DrawBig;
begin
  if FBigTicksLeft > 0 then
    FFont.DrawBig(FBigText,
      (FScreenWidth - FFont.BigTextWidth(FBigText)) / 2, BigMessageY);
end;

end.
