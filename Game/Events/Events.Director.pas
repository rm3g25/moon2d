{
  Events.Director - runs the level's events (Levels.Events) against the
  live game: watches each event's condition on the hero's screen, waits
  out its delay, plays its actions once.

  The director acts on the stage it is given - the message board - and
  asks the game for the one thing it does not own, the music, through a
  callback: the game remembers the track for restarts. The monster
  field is reborn on every restart, so it arrives with every tick
  instead of being kept.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Events.Director;
{$I ..\..\Moon2D.inc}

interface

uses
  Levels.Events, Hud.Messages, Monsters;

type
  // Plays a track and remembers it as the level's current one. A
  // method of the game passed directly, no wrapper.
  TChangeMusic = reference to procedure(const AFileName: string);

  TEventDirector = class
  private
    FEvents: TArray<TLevelEvent>;
    FMessages: TMessageBoard;
    FChangeMusic: TChangeMusic;
    FFired: TArray<Boolean>; // in step with FEvents
    FTicksLeft: TArray<Integer>; // of the delay, once the condition holds
    procedure Arm(AIndex: Integer);
    function ConditionHolds(const AEvent: TLevelEvent;
      const AField: TMonsterField): Boolean;
    procedure Play(const AEvent: TLevelEvent);
  public
    constructor Create(const AEvents: TArray<TLevelEvent>;
      const AMessages: TMessageBoard; const AChangeMusic: TChangeMusic);

    // One logic tick with the hero on AScreen
    procedure Tick(AScreen: Integer; const AField: TMonsterField);
    // Death re-enters the screen with its monsters reborn: its events
    // wait for their moment again, as the entity triggers do
    procedure ReArm(AScreen: Integer);
  end;

implementation

uses
  Localization;

constructor TEventDirector.Create(const AEvents: TArray<TLevelEvent>;
  const AMessages: TMessageBoard; const AChangeMusic: TChangeMusic);
begin
  inherited Create;
  FEvents := AEvents;
  FMessages := AMessages;
  FChangeMusic := AChangeMusic;
  SetLength(FFired, Length(FEvents));
  SetLength(FTicksLeft, Length(FEvents));
  for var i := 0 to High(FEvents) do
    Arm(i);
end;

procedure TEventDirector.Arm(AIndex: Integer);
begin
  FFired[AIndex] := False;
  FTicksLeft[AIndex] := FEvents[AIndex].DelayTicks;
end;

procedure TEventDirector.ReArm(AScreen: Integer);
begin
  for var i := 0 to High(FEvents) do
    if FEvents[i].Screen = AScreen then
      Arm(i);
end;

function TEventDirector.ConditionHolds(const AEvent: TLevelEvent;
  const AField: TMonsterField): Boolean;
begin
  // ecEnterScreen asks nothing beyond the screen the caller has checked
  Result := True;
  if AEvent.Condition = ecAllDead then
    Result := not AField.AnyAliveTagged(AEvent.Tag);
end;

procedure TEventDirector.Play(const AEvent: TLevelEvent);
begin
  for var Action in AEvent.Actions do
    case Action.Kind of
      eaBigMessage:
        FMessages.ShowBig(Action.Text.Current, BigMessageTicks);
      eaSmallMessage:
        FMessages.AddTicker(Action.Text.Current, TickerNoticeTicks);
      eaHint:
        FMessages.StartTerminal(Tr(STerminalHeader), Action.Text.Current);
      eaMusic:
        FChangeMusic(Action.FileName);
    end;
end;

// The delay counts only while the condition holds; a condition that
// lapses starts the count over
procedure TEventDirector.Tick(AScreen: Integer; const AField: TMonsterField);
begin
  for var i := 0 to High(FEvents) do
  begin
    if FFired[i] or (FEvents[i].Screen <> AScreen) then
      Continue;
    if not ConditionHolds(FEvents[i], AField) then
    begin
      FTicksLeft[i] := FEvents[i].DelayTicks;
      Continue;
    end;
    if FTicksLeft[i] > 0 then
    begin
      Dec(FTicksLeft[i]);
      Continue;
    end;

    FFired[i] := True;
    Play(FEvents[i]);
  end;
end;

end.
