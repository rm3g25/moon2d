{
  Hud.Typewriter - text that types itself out: one letter a tick, a line
  break costs a tick like a carriage return, and an empty line between
  paragraphs holds a short breath. Key clicks and the cursor's blink come
  from here too, so every screen that types sounds and blinks the same.

  Logic only: no drawing, no sound. The owner draws Shown(row) per line,
  puts its cursor at CursorRow/CursorColumn, and plays a click when
  KeyStruck is up.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Typewriter;
{$I Moon2D.inc}

interface

type
  // bpOnHold: the text is out and waits - the cursor slows down
  TBlinkPace = (bpTyping, bpOnHold);

  TTypewriter = class
  private
    FLines: TArray<string>;
    FRow: Integer;
    FColumn: Integer; // letters of FLines[FRow] already out
    FTyped: Integer;
    FCharCount: Integer;
    FPauseLeft: Integer;
    FTicks: Integer;
    FKeyStruck: Boolean;
    procedure NextLine;
    procedure TypeChar;
  public
    // Trailing empty lines are dropped - they carry nothing to type
    procedure Start(const ALines: TArray<string>);
    // Counts every call, typing or not: the cursor keeps blinking after
    procedure Tick;
    // The whole text at once - a key pressed by an impatient reader
    procedure Finish;
    function Done: Boolean;
    function Shown(ARow: Integer): string;
    function CursorVisible(APace: TBlinkPace): Boolean;
    property Lines: TArray<string> read FLines;
    property CursorRow: Integer read FRow;
    property CursorColumn: Integer read FColumn;
    property CharCount: Integer read FCharCount;
    property KeyStruck: Boolean read FKeyStruck;
  end;

implementation

const
  ParagraphPauseTicks = 12; // ~0.4 s
  // Blink half-periods as tick shifts: 8 ticks, 32 ticks on hold
  TypingBlinkShift = 3;
  OnHoldBlinkShift = 5;

procedure TTypewriter.Start(const ALines: TArray<string>);
begin
  FLines := ALines;
  while (FLines <> nil) and (FLines[High(FLines)] = '') do
    SetLength(FLines, Length(FLines) - 1);

  FCharCount := 0;
  for var Line in FLines do
    Inc(FCharCount, Length(Line));

  FRow := 0;
  FColumn := 0;
  FTyped := 0;
  FPauseLeft := 0;
  FTicks := 0;
  FKeyStruck := False;
end;

function TTypewriter.Done: Boolean;
begin
  if FLines = nil then
    Exit(True);
  Result := (FRow = High(FLines)) and (FColumn = Length(FLines[FRow]));
end;

procedure TTypewriter.Tick;
begin
  FKeyStruck := False;
  Inc(FTicks);
  if Done then
    Exit;
  if FPauseLeft > 0 then
  begin
    Dec(FPauseLeft);
    Exit;
  end;

  if FColumn = Length(FLines[FRow]) then
    NextLine
  else
    TypeChar;
end;

procedure TTypewriter.NextLine;
begin
  Inc(FRow);
  FColumn := 0;
  if FLines[FRow] = '' then
    FPauseLeft := ParagraphPauseTicks;
end;

// A click on every second letter: one per letter at 33 a second turns
// into a buzz
procedure TTypewriter.TypeChar;
begin
  Inc(FColumn);
  Inc(FTyped);
  FKeyStruck := not Odd(FTyped) and (FLines[FRow][FColumn] <> ' ');
end;

procedure TTypewriter.Finish;
begin
  if FLines = nil then
    Exit;
  FRow := High(FLines);
  FColumn := Length(FLines[FRow]);
  FPauseLeft := 0;
end;

function TTypewriter.Shown(ARow: Integer): string;
begin
  if ARow < FRow then
    Result := FLines[ARow]
  else if ARow = FRow then
    Result := Copy(FLines[ARow], 1, FColumn)
  else
    Result := '';
end;

function TTypewriter.CursorVisible(APace: TBlinkPace): Boolean;
begin
  var Shift := TypingBlinkShift;
  if APace = bpOnHold then
    Shift := OnHoldBlinkShift;
  Result := ((FTicks shr Shift) and 1) = 0;
end;

end.
