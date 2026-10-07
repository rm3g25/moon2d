{
  Events.Director - runs the level's events (Levels.Events) against the
  live game: watches each event's condition on the hero's screen, waits
  out its delay, plays its actions once.

  The director acts on the stage it is given - the message board and
  the level's dynamic objects - and asks the game for the two things it
  does not own through callbacks: the music, whose track the game
  remembers for restarts, and the arena that rebuilds a pad group and
  restores it. The monster field is reborn on every restart, so it
  arrives with every tick instead of being kept: asked for the
  conditions, told the tactics.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Events.Director;
{$I ..\..\Moon2D.inc}

interface

uses
  Levels.Events, Levels.Dynamics, Hud.Messages, Monsters;

type
  // Plays a track and remembers it as the level's current one. A
  // method of the game passed directly, no wrapper.
  TChangeMusic = reference to procedure(const AFileName: string);
  // A word to the arena about the pad group tagged AGroup (Pads.Arena)
  TArenaCue = reference to procedure(const AGroup: string);

  TArenaCues = record
    Engage: TArenaCue; // the group is rebuilt from now on
    Restore: TArenaCue; // no more: its pads fly back to their places
  end;

  TEventDirector = class
  private
    FEvents: TArray<TLevelEvent>;
    FMessages: TMessageBoard;
    FDynamics: TDynamicObjects;
    FChangeMusic: TChangeMusic;
    FArena: TArenaCues;
    FFired: TArray<Boolean>; // in step with FEvents
    FTicksLeft: TArray<Integer>; // of the delay, once the condition holds
    procedure Arm(AIndex: Integer);
    procedure RewindTargets(const AEvent: TLevelEvent);
    function ConditionHolds(const AEvent: TLevelEvent;
      const AField: TMonsterField): Boolean;
    procedure Play(const AEvent: TLevelEvent; const AField: TMonsterField);
  public
    constructor Create(const AEvents: TArray<TLevelEvent>;
      const AMessages: TMessageBoard; const ADynamics: TDynamicObjects;
      const AChangeMusic: TChangeMusic; const AArena: TArenaCues);

    // One logic tick with the hero on AScreen
    procedure Tick(AScreen: Integer; const AField: TMonsterField);
    // Death re-enters the screen with its monsters reborn: its events
    // wait for their moment again, as the entity triggers do, and the
    // dynamic objects they turned go back to the level file
    procedure ReArm(AScreen: Integer);
  end;

implementation

uses
  Localization;

constructor TEventDirector.Create(const AEvents: TArray<TLevelEvent>;
  const AMessages: TMessageBoard; const ADynamics: TDynamicObjects;
  const AChangeMusic: TChangeMusic; const AArena: TArenaCues);
begin
  inherited Create;
  FEvents := AEvents;
  FMessages := AMessages;
  FDynamics := ADynamics;
  FChangeMusic := AChangeMusic;
  FArena := AArena;
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
  begin
    if FEvents[i].Screen <> AScreen then
      Continue;
    Arm(i);
    RewindTargets(FEvents[i]);
  end;
end;

procedure TEventDirector.RewindTargets(const AEvent: TLevelEvent);
begin
  for var Action in AEvent.Actions do
    if Action.Kind = eaIntensity then
      FDynamics.RewindTagged(Action.Target);
end;

function TEventDirector.ConditionHolds(const AEvent: TLevelEvent;
  const AField: TMonsterField): Boolean;
begin
  // ecEnterScreen asks nothing beyond the screen the caller has checked
  case AEvent.Condition of
    ecAllDead:
      Result := not AField.AnyAliveTagged(AEvent.Tag);
    ecLivesBelow:
      Result := AField.AnyTaggedLivesBelow(AEvent.Tag, AEvent.Lives);
    ecEnraged:
      Result := AField.AnyTaggedEnraged(AEvent.Tag);
  else
    Result := True;
  end;
end;

procedure TEventDirector.Play(const AEvent: TLevelEvent;
  const AField: TMonsterField);
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
      eaIntensity:
        FDynamics.FadeTagged(Action.Target, Action.Level, Action.Ticks);
      eaSun:
        FDynamics.TurnSunTagged(Action.Target, Action.Angle, Action.Ticks);
      eaTactics:
        AField.SetTaggedTactics(Action.Target, Action.Tactics);
      eaRebuild:
        FArena.Engage(Action.Target);
      eaRestore:
        FArena.Restore(Action.Target);
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
    Play(FEvents[i], AField);
  end;
end;

end.
