{
  Events.Director - runs the level's events (Levels.Events) against the
  live game: watches each event's condition on the hero's screen, waits
  out its delay, plays its actions once.

  The director acts on the stage it is given - the message board and
  the level's dynamic objects - and asks the game for the things it does
  not own through callbacks: the music, whose track the game remembers
  for restarts; the arena that rebuilds a pad group, restores it and
  flies it in; the shelves of a bank, which take their order from where
  the hero stands; a carousel that breaks; a flock of stray pads let go
  and sent away; the trial's medkits and the bank its wave comes down
  onto; the wall cannons of the trial; the bodies an event lets in; the
  open sky of the trial; the press of its finale; the scene an event
  begins; how far the gravel trial has come, whether it is won and how
  much of its victory track is left; where the hero stands; the go-right
  arrow; the door of the screen, which the game keeps shut or open; the
  charge of the form the hero takes in; the life sphere it forms and
  whether the hero has taken it. Which hint is typed out the director
  keeps itself, by the tickets of the terminal. The monster field is reborn on
  every restart, so it arrives with every tick instead of being kept:
  asked for the conditions, told the tactics.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Events.Director;
{$I ..\..\Moon2D.inc}

interface

uses
  Levels.Events, Levels.Dynamics, Hud.Messages, Monsters, Game.Trial;

type
  // Plays a track and remembers it as the level's current one, coming in
  // from silence over AFadeSeconds; with AFadeOutSeconds above 0 the track
  // that plays fades out first. A method of the game passed directly, no
  // wrapper.
  TChangeMusic = reference to procedure(const AFileName: string;
    AFadeSeconds, AFadeOutSeconds: Single);
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
  // The carousel tagged ATag breaks as ABreakdown says
  TBreakCue = reference to procedure(const ATag: string;
    const ABreakdown: TCarouselBreak);
  // The pads of the flock AFlock stray from now on
  TFlockCue = reference to procedure(const AFlock: string);
  // The trial's medkits come down over the shelves of ABank from now on
  TBankCue = reference to procedure(const ABank: string);
  // The act the gravel trial has come to; 0 while it does not run
  TTrialAct = reference to function: Integer;
  // The trial of the screen has finished, its last act won
  TTrialDone = reference to function: Boolean;
  // The wall cannons come in for the act AAct of the trial - the act the
  // event waits for, 0 for one that waits for no act
  TCannonsCue = reference to procedure(const AOrders: TCannonOrders;
    AAct: Integer);
  // How far the trial has come: its act, its batch and the gravels dealt
  TTrialProgressCue = reference to function: TTrialProgress;
  // A body comes in along a lane for the act AAct of the trial
  TSpawnCue = reference to procedure(const AOrders: TSpawnOrders;
    AAct: Integer);
  // The sky opens for the act AAct of the trial
  TSkyFallCue = reference to procedure(const AOrders: TSkyFall;
    AAct: Integer);
  // The press starts for the act AAct of the trial
  TPressCue = reference to procedure(const AOrders: TPressOrders;
    AAct: Integer);
  // The scene AScene begins (Scenes.Director)
  TSceneStart = reference to procedure(const AScene: string);
  // The seconds the trial's victory track has left to play: 0 once it is
  // over, below 0 while there is none
  TVictoryLeft = reference to function: Single;
  // The go-right arrow shows over the screen
  TGoRightCue = reference to procedure;
  // The door the level shuts on the hero's screen opens
  TOpenDoorCue = reference to procedure;
  // The hero stands in the cell ACol, ARow of his screen, from 0, on his
  // feet
  THeroStandsCue = reference to function(ACol, ARow: Integer): Boolean;
  // AAmount percent of the form's charge come out of the hero for its
  // gauge
  TEnergyCue = reference to procedure(AAmount: Integer);
  // The hero's checkpoint moves to the cell ACol, ARow of his screen,
  // counted as a respawn point's: from 1
  TRespawnCue = reference to procedure(ACol, ARow: Integer);
  // The life sphere forms on the cell ACol, ARow of the hero's screen,
  // counted as a placement's - from 1 -, ASize units across
  TSphereCue = reference to procedure(ACol, ARow: Integer; ASize: Single);
  // The hero has taken the life sphere of his screen
  TSphereTakenCue = reference to function: Boolean;

  TDirectorCues = record
    ChangeMusic: TChangeMusic;
    Arena: TArenaCues;
    Shelves: TShelfCue;
    BreakCarousel: TBreakCue;
    Strays: TFlockCue;
    // The pads of a flock fly out quietly and stay out
    StraysLeave: TFlockCue;
    MedkitsOnto: TBankCue;
    // The bodies of the trial's wave come down over the shelves of a bank
    WaveOnto: TBankCue;
    TrialAct: TTrialAct;
    TrialDone: TTrialDone;
    TrialProgress: TTrialProgressCue;
    Cannons: TCannonsCue;
    Spawn: TSpawnCue;
    SkyFall: TSkyFallCue;
    Press: TPressCue;
    StartScene: TSceneStart;
    VictoryLeft: TVictoryLeft;
    GoRight: TGoRightCue;
    OpenDoor: TOpenDoorCue;
    HeroStands: THeroStandsCue;
    Energy: TEnergyCue;
    Respawn: TRespawnCue;
    Sphere: TSphereCue;
    SphereTaken: TSphereTakenCue;
  end;

  TEventDirector = class
  private
    FEvents: TArray<TLevelEvent>;
    FMessages: TMessageBoard;
    FDynamics: TDynamicObjects;
    FCues: TDirectorCues;
    FFired: TArray<Boolean>; // in step with FEvents
    FTicksLeft: TArray<Integer>; // of the delay, once the condition holds
    // In step with FEvents: the terminal's ticket of the hint the event
    // typed, 0 for none; and the event whose hint a hintTyped one waits
    // for, -1 for none
    FHintTickets: TArray<Integer>;
    FHintSources: TArray<Integer>;
    procedure Arm(AIndex: Integer);
    procedure FindHintSources;
    function HintTyped(AIndex: Integer): Boolean;
    procedure RewindTargets(const AEvent: TLevelEvent);
    function GravelDealt(const AEvent: TLevelEvent): Boolean;
    function WaveKilled(const AEvent: TLevelEvent): Boolean;
    function ConditionHolds(AIndex: Integer;
      const AField: TMonsterField): Boolean;
    procedure Play(AIndex: Integer; const AField: TMonsterField);
    procedure PlayHint(AIndex: Integer; const AAction: TEventAction);
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
  System.SysUtils, Localization, Hud.Terminal;

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
  SetLength(FHintTickets, Length(FEvents));
  FindHintSources;
  for var i := 0 to High(FEvents) do
    Arm(i);
end;

// The level has checked at load that the event named is there
procedure TEventDirector.FindHintSources;
begin
  SetLength(FHintSources, Length(FEvents));
  for var i := 0 to High(FEvents) do
  begin
    FHintSources[i] := -1;
    if FEvents[i].Condition <> ecHintTyped then
      Continue;
    for var j := 0 to High(FEvents) do
      if SameText(FEvents[j].Id, FEvents[i].HintEvent) then
        FHintSources[i] := j;
  end;
end;

procedure TEventDirector.Arm(AIndex: Integer);
begin
  FFired[AIndex] := False;
  FTicksLeft[AIndex] := FEvents[AIndex].DelayTicks;
  FHintTickets[AIndex] := 0;
end;

function TEventDirector.HintTyped(AIndex: Integer): Boolean;
begin
  var Source := FHintSources[AIndex];
  Result := (Source >= 0) and FMessages.TerminalTyped(FHintTickets[Source]);
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

// As GravelDealt: a share of the wave's count, an act past counts too
function TEventDirector.WaveKilled(const AEvent: TLevelEvent): Boolean;
begin
  var Progress := FCues.TrialProgress();
  if Progress.Act <> AEvent.Act then
    Exit(Progress.Act > AEvent.Act);
  var Count := Progress.Batch * AEvent.Part div AEvent.Whole;
  Result := Progress.WaveKilled >= Count;
end;

function TEventDirector.ConditionHolds(AIndex: Integer;
  const AField: TMonsterField): Boolean;
begin
  var Event := FEvents[AIndex];
  // ecEnterScreen asks nothing beyond the screen the caller has checked
  case Event.Condition of
    ecAllDead:
      Result := not AField.AnyAliveTagged(Event.Tag);
    ecLivesBelow:
      Result := AField.AnyTaggedLivesBelow(Event.Tag, Event.Lives);
    ecEnraged:
      Result := AField.AnyTaggedEnraged(Event.Tag);
    ecActReached:
      Result := FCues.TrialAct() >= Event.Act;
    ecGravelDealt:
      Result := GravelDealt(Event);
    ecTrialDone:
      Result := FCues.TrialDone();
    ecWaveKilled:
      Result := WaveKilled(Event);
    ecVictoryEnds:
      begin
        var Left := FCues.VictoryLeft();
        Result := (Left >= 0) and (Left <= Event.LeadSeconds);
      end;
    ecHeroStands:
      Result := FCues.HeroStands(Event.CellX - 1, Event.CellY - 1);
    ecHintTyped:
      Result := HintTyped(AIndex);
    ecSphereTaken:
      Result := FCues.SphereTaken();
  else
    Result := True;
  end;
end;

// A hint speaks in the voice its event gives it, the channel's own when
// the event gives none
procedure TEventDirector.PlayHint(AIndex: Integer; const AAction: TEventAction);
begin
  var Header := AAction.Header.Current;
  if Header = '' then
    Header := Tr(STerminalHeader);
  var Place := tlTop;
  if AAction.AtBottom then
    Place := tlBottom;
  FHintTickets[AIndex] := FMessages.StartTerminal(Header, AAction.Text.Current,
    Place);
end;

procedure TEventDirector.Play(AIndex: Integer; const AField: TMonsterField);
begin
  var Event := FEvents[AIndex];
  for var Action in Event.Actions do
    case Action.Kind of
      eaBigMessage:
        FMessages.ShowBig(Action.Text.Current, BigMessageTicks);
      eaSmallMessage:
        FMessages.AddTicker(Action.Text.Current, TickerNoticeTicks);
      eaHint:
        PlayHint(AIndex, Action);
      eaMusic:
        FCues.ChangeMusic(Action.FileName, Action.FadeSeconds,
          Action.FadeOutSeconds);
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
      eaWaveOnto:
        FCues.WaveOnto(Action.Target);
      eaCannons:
        FCues.Cannons(Action.Cannons, Event.Act);
      eaSpawn:
        FCues.Spawn(Action.Spawn, Event.Act);
      eaBreakCarousel:
        FCues.BreakCarousel(Action.Target, Action.Breakdown);
      eaStrays:
        FCues.Strays(Action.Target);
      eaStraysLeave:
        FCues.StraysLeave(Action.Target);
      eaSkyFall:
        FCues.SkyFall(Action.SkyFall, Event.Act);
      eaPress:
        FCues.Press(Action.Press, Event.Act);
      eaScene:
        FCues.StartScene(Action.Target);
      eaGoRight:
        FCues.GoRight();
      eaOpenDoor:
        FCues.OpenDoor();
      eaEnergy:
        FCues.Energy(Action.Amount);
      eaRespawn:
        FCues.Respawn(Action.CellX, Action.CellY);
      eaSphere:
        FCues.Sphere(Action.CellX, Action.CellY, Action.Size);
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
    if not ConditionHolds(i, AField) then
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
    Play(i, AField);
  end;
end;

end.
