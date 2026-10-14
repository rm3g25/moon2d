{
  Events.Director - runs the level's events (Levels.Events) against the
  live game: watches each event's condition on the hero's screen, waits
  out its delay, plays its actions once.

  The director acts on the stage it is given - the message board and
  the level's dynamic objects - and asks the game for the things it does
  not own through callbacks: the music, whose track the game remembers
  for restarts; the arena that rebuilds a pad group, restores it and
  flies it in; the shelves of a bank, which take their order from where
  the hero stands; the trial's medkits; the wall cannons of the trial;
  the bodies an event lets in; and how far the gravel trial has come. The
  monster field is reborn on every restart, so it arrives with every tick
  instead of being kept: asked for the conditions, told the tactics.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Events.Director;
{$I ..\..\Moon2D.inc}

interface

uses
  Levels.Events, Levels.Dynamics, Hud.Messages, Monsters, Game.Trial;

type
  // Plays a track and remembers it as the level's current one. A
  // method of the game passed directly, no wrapper.
  TChangeMusic = reference to procedure(const AFileName: string);
  // A word to the arena about the pad group tagged AGroup (Pads.Arena)
  TArenaCue = reference to procedure(const AGroup: string);

  TArenaCues = record
    Engage: TArenaCue; // the group is rebuilt from now on
    Restore: TArenaCue; // no more: its pads fly back to their places
    // The group or the carousel parked above flies in to its places
    FlyIn: TArenaCue;
  end;

  // A shelf action of an event: its bank, its program, its order
  TShelfCue = reference to procedure(const AAction: TEventAction);
  // The trial's medkits come down over the shelves of ABank from now on
  TBankCue = reference to procedure(const ABank: string);
  // The act the gravel trial has come to; 0 while it does not run
  TTrialAct = reference to function: Integer;
  // The wall cannons come in for the act AAct of the trial - the act the
  // event waits for, 0 for one that waits for no act
  TCannonsCue = reference to procedure(const AOrders: TCannonOrders;
    AAct: Integer);
  // How far the trial has come: its act, its batch and the gravels dealt
  TTrialProgressCue = reference to function: TTrialProgress;
  // A body comes in along a lane for the act AAct of the trial
  TSpawnCue = reference to procedure(const AOrders: TSpawnOrders;
    AAct: Integer);

  TDirectorCues = record
    ChangeMusic: TChangeMusic;
    Arena: TArenaCues;
    Shelves: TShelfCue;
    MedkitsOnto: TBankCue;
    TrialAct: TTrialAct;
    TrialProgress: TTrialProgressCue;
    Cannons: TCannonsCue;
    Spawn: TSpawnCue;
  end;

  TEventDirector = class
  private
    FEvents: TArray<TLevelEvent>;
    FMessages: TMessageBoard;
    FDynamics: TDynamicObjects;
    FCues: TDirectorCues;
    FFired: TArray<Boolean>; // in step with FEvents
    FTicksLeft: TArray<Integer>; // of the delay, once the condition holds
    procedure Arm(AIndex: Integer);
    procedure RewindTargets(const AEvent: TLevelEvent);
    function GravelDealt(const AEvent: TLevelEvent): Boolean;
    function ConditionHolds(const AEvent: TLevelEvent;
      const AField: TMonsterField): Boolean;
    procedure Play(const AEvent: TLevelEvent; const AField: TMonsterField);
    procedure PlayHint(const AAction: TEventAction);
  public
    constructor Create(const AEvents: TArray<TLevelEvent>;
      const AMessages: TMessageBoard; const ADynamics: TDynamicObjects;
      const ACues: TDirectorCues);

    // One logic tick with the hero on AScreen
    procedure Tick(AScreen: Integer; const AField: TMonsterField);
    // Death re-enters the screen with its monsters reborn: its events
    // wait for their moment again, as the entity triggers do, and the
    // dynamic objects they turned go back to the level file
    procedure ReArm(AScreen: Integer);
  end;

implementation

uses
  Localization, Hud.Terminal;

constructor TEventDirector.Create(const AEvents: TArray<TLevelEvent>;
  const AMessages: TMessageBoard; const ADynamics: TDynamicObjects;
  const ACues: TDirectorCues);
begin
  inherited Create;
  FEvents := AEvents;
  FMessages := AMessages;
  FDynamics := ADynamics;
  FCues := ACues;
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

// An act past counts as dealt too: the event waits for a moment that has
// gone by
function TEventDirector.GravelDealt(const AEvent: TLevelEvent): Boolean;
begin
  var Progress := FCues.TrialProgress();
  if Progress.Act <> AEvent.Act then
    Exit(Progress.Act > AEvent.Act);
  var Number := Progress.Batch * AEvent.Part div AEvent.Whole + 1;
  Result := Progress.Dealt >= Number;
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
    ecActReached:
      Result := FCues.TrialAct() >= AEvent.Act;
    ecGravelDealt:
      Result := GravelDealt(AEvent);
  else
    Result := True;
  end;
end;

// A hint speaks in the voice its event gives it, the channel's own when
// the event gives none
procedure TEventDirector.PlayHint(const AAction: TEventAction);
begin
  var Header := AAction.Header.Current;
  if Header = '' then
    Header := Tr(STerminalHeader);
  var Place := tlTop;
  if AAction.AtBottom then
    Place := tlBottom;
  FMessages.StartTerminal(Header, AAction.Text.Current, Place);
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
        PlayHint(Action);
      eaMusic:
        FCues.ChangeMusic(Action.FileName);
      eaIntensity:
        FDynamics.FadeTagged(Action.Target, Action.Level, Action.Ticks);
      eaSun:
        FDynamics.TurnSunTagged(Action.Target, Action.Angle, Action.Ticks);
      eaTactics:
        AField.SetTaggedTactics(Action.Target, Action.Tactics);
      eaRebuild:
        FCues.Arena.Engage(Action.Target);
      eaRestore:
        FCues.Arena.Restore(Action.Target);
      eaFlyIn:
        FCues.Arena.FlyIn(Action.Target);
      eaShelvesWake, eaShelvesSleep, eaShelvesProgram:
        FCues.Shelves(Action);
      eaMedkitsOnto:
        FCues.MedkitsOnto(Action.Target);
      eaCannons:
        FCues.Cannons(Action.Cannons, AEvent.Act);
      eaSpawn:
        FCues.Spawn(Action.Spawn, AEvent.Act);
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
