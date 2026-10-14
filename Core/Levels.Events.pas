{
  Levels.Events - the events of a level: the "events" section of level
  JSON. An event names a screen, a condition the game watches for on
  it, a delay, and the actions that follow once. Model and parser only:
  the game runs them (Events.Director), the editor will write them.
  The JSON shape is spelled out at TLevelEvent - a brace comment cannot
  hold a JSON object.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Events;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Localization, Monsters.Defs, Levels.Pads;

type
  ELevelEventError = class(Exception);

  // What the event waits for. The hero must be on the event's screen
  // for any of them; enterScreen asks nothing more. The rest watch the
  // monsters carrying the tag: allDead - none of them alive; livesBelow
  // - one alive with fewer lives than "lives", a mark told for the
  // normal grade that grows with the difficulty as the lives do; enraged
  // - one gone into its rage (the boss below its rage mark, a tank below
  // its own). actReached watches the gravel trial: it has come to its
  // act "act" or past it. gravelDealt watches the batch of the act "act":
  // it holds from the moment the gravel number batch * part div of + 1 is
  // let down - a third of a batch of 15 puts it at the sixth gravel, and
  // the batch is told by the grade. JSON: "act", "part" (0 by default), "of".
  TEventCondition = (ecEnterScreen, ecAllDead, ecLivesBelow, ecEnraged,
    ecActReached, ecGravelDealt);

  TEventActionKind = (eaBigMessage, eaSmallMessage, eaHint, eaMusic,
    eaIntensity, eaSun, eaTactics, eaRebuild, eaRestore, eaShelvesWake,
    eaShelvesSleep, eaShelvesProgram, eaFlyIn, eaMedkitsOnto, eaCannons,
    eaSpawn);

  // The wall cannons of the gravel trial: the rows they stop at to fire,
  // the bank of shelves in their way and the rows that bank stands in the
  // way at. Rows are the cells of the screen, 0 at the top; a cannon is
  // one row tall.
  TCannonOrders = record
    Rows: TArray<Integer>;
    YieldBank: string;
    YieldRows: TArray<Integer>;
  end;

  // A body let in along a row of the screen: which monster, the sprite list
  // it wears when its definition names none, the row (the cells of the
  // screen, 0 at the top) and the side it comes in from; the tag it
  // carries ('' = none) and the rigs the level hangs on that tag, as on a
  // placement
  TSpawnOrders = record
    MonsterId: string;
    SpriteList: string;
    Row: Integer;
    Side: TLaneSide;
    Tag: string;
    Rigs: TArray<string>;
  end;

  TEventAction = record
    Kind: TEventActionKind;
    Text: TLocalizedText; // the message kinds; localized like the triggers
    FileName: string; // eaMusic
    // eaIntensity: the dynamic objects tagged Target fade to Level
    // (0..1) over Ticks. JSON: "target", "value" (a percentage),
    // "ticks" (0 by default - at once).
    // eaSun: the globes tagged Target turn their sun to Angle degrees
    // over Ticks. JSON: "target", "value" (degrees), "ticks".
    // eaTactics: the monsters placed with the tag Target fly by
    // Tactics from now on (Monsters.Pilot). JSON: "target", "value" (a
    // word of EventTacticsIds).
    // eaRebuild: the pad group tagged Target is rebuilt from now on,
    // over and over, as its conductor flies (Pads.Arena). JSON:
    // "target".
    // eaRestore: the pad group tagged Target is rebuilt no more, its
    // pads fly back to where the level file puts them (Pads.Arena).
    // JSON: "target".
    // eaShelvesWake: the shelves of the bank Target come out of the wall
    // and run Shelves - hold, unless "program" says another.
    // eaShelvesProgram: they run Shelves from now on, waking if asleep.
    // eaShelvesSleep: they warn and go into the wall, and stay there;
    // with SpareHero a shelf the hero stands on waits until he is off it.
    // The three tell the shelves in Order, each StepSeconds after the one
    // before. JSON: "target", "program" (a word of ShelfProgramIds),
    // "out", "in", "warn" (seconds), "order" (a word of BankOrderIds,
    // file by default), "step" (seconds, 0 by default); eaShelvesSleep
    // also "spareHero" (false by default).
    // eaFlyIn: the pads of the group Target, parked above the screen,
    // fly in to where the level file puts them (Pads.Arena); or the
    // carousel Target, parked, comes down to its track and turns
    // (Pads.World). JSON: "target".
    // eaMedkitsOnto: from now on the trial's medkits come down over the
    // shelves of the bank Target. JSON: "target".
    // eaCannons: the two TeK cannons slide in on the walls for the act of
    // the trial they come in (Game.Cannons). JSON: "rows" (the rows they
    // fire at), "yield" (a bank of shelves, optional) and "yieldRows"
    // (while a cannon is on any of them the bank stays in the wall).
    // eaSpawn: a body of the monster Spawn.MonsterId slides in through the
    // wall along the row, for the act of the trial the event waits for, and
    // flies off when that act ends - so the event must wait for one. JSON:
    // "monster", "spriteList" (optional), "row", "from" ("left" or "right"),
    // "tag" and "rig" (optional, a rig needs the tag).
    // eaHint: Header names who speaks, empty for the channel itself;
    // AtBottom puts the box on the bottom edge instead of under the
    // heart monitor, for a screen where the hero comes in at the top.
    // JSON: "header" (localized like "text"), "place" ("top" by
    // default, or "bottom").
    Target: string;
    Header: TLocalizedText;
    AtBottom: Boolean;
    Level: Single;
    Angle: Single;
    Ticks: Integer;
    Tactics: TPilotTactics;
    Shelves: TShelfProgram;
    Order: TBankOrder;
    StepSeconds: Single;
    SpareHero: Boolean;
    Cannons: TCannonOrders;
    Spawn: TSpawnOrders;
  end;

  // One event in level JSON:
  //   {
  //     "id": "labHint",
  //     "screen": 12,
  //     "when": "allDead", "tag": "labGuard",
  //     (or "when": "livesBelow", "tag": "boss", "lives": 150,
  //     or "when": "actReached", "act": 2
  //     or "when": "gravelDealt", "act": 4, "part": 1, "of": 3)
  //     "delay": 33,
  //     "then": [
  //       {"action": "hint", "text": "...", "textEn": "..."}
  //     ]
  //   }
  TLevelEvent = record
    Id: string;
    Screen: Integer; // 1-based, as the level counts
    Condition: TEventCondition;
    Tag: string; // the placements the monster conditions watch
    Lives: Integer; // ecLivesBelow
    Act: Integer; // ecActReached, ecGravelDealt
    Part: Integer; // ecGravelDealt
    Whole: Integer; // ecGravelDealt, "of" in JSON
    DelayTicks: Integer; // between the condition and the actions
    Actions: TArray<TEventAction>;
  end;

const
  // The JSON vocabulary of "when", of "action" and of the "value" the
  // tactics action takes
  EventConditionIds: array [TEventCondition] of string = (
    'enterScreen', 'allDead', 'livesBelow', 'enraged', 'actReached',
    'gravelDealt');
  EventActionIds: array [TEventActionKind] of string = (
    'bigMessage', 'smallMessage', 'hint', 'music', 'intensity', 'sun',
    'tactics', 'rebuild', 'restore', 'shelvesWake', 'shelvesSleep',
    'shelvesProgram', 'flyIn', 'medkitsOnto', 'cannons', 'spawn');
  EventTacticsIds: array [TPilotTactics] of string = (
    'laps', 'dives', 'rams', 'hunts');
  EventLaneSideIds: array [TLaneSide] of string = ('left', 'right');

  // The conditions that watch tagged placements
  TaggedConditions = [ecAllDead, ecLivesBelow, ecEnraged];
  // The actions that tell a bank of shelves
  ShelfActions = [eaShelvesWake, eaShelvesSleep, eaShelvesProgram];

// Reads the "events" array of a level; an absent section is an empty
// list. ALevelId names the level in errors.
function ParseLevelEvents(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TLevelEvent>;

implementation

uses
  System.Generics.Collections, System.Math, Game.Space, Levels.Rigs;

resourcestring
  SEventNoId = 'Level "%s": event #%d has no id';
  SEventBadCondition = 'Level "%s": event "%s": unknown condition "%s"';
  SEventNoTag = 'Level "%s": event "%s": %s names no tag';
  SEventNoLives = 'Level "%s": event "%s": livesBelow needs "lives" above zero';
  SEventNoAct = 'Level "%s": event "%s": actReached needs "act" above zero';
  SEventNoBatchAct = 'Level "%s": event "%s": gravelDealt needs "act" above zero';
  SEventBadShare = 'Level "%s": event "%s": gravelDealt takes "of" above zero '
    + 'and "part" from 0 to below "of"';
  SEventNoTarget = 'Level "%s": event "%s": intensity names no target';
  SEventBadLevel = 'Level "%s": event "%s": intensity takes a "value", 0..100';
  SEventSunNoTarget = 'Level "%s": event "%s": sun names no target';
  SEventSunNoAngle = 'Level "%s": event "%s": sun takes a "value" in degrees';
  SEventTacticsNoTarget = 'Level "%s": event "%s": tactics names no target';
  SEventBadTactics = 'Level "%s": event "%s": unknown tactics "%s"';
  SEventGroupNoTarget = 'Level "%s": event "%s": %s names no target';
  SEventBadAction = 'Level "%s": event "%s": unknown action "%s"';
  SEventNoActions = 'Level "%s": event "%s" has no actions';
  SEventBadPlace = 'Level "%s": event "%s": a hint takes "place" top or '
    + 'bottom, not "%s"';
  SEventBadProgram = 'Level "%s": event "%s": unknown shelf program "%s"';
  SEventNoProgram = 'Level "%s": event "%s": shelvesProgram names no program';
  SEventBadOrder = 'Level "%s": event "%s": unknown bank order "%s"';
  SEventShelfNumber = 'Level "%s": event "%s": %s takes %s %g';
  SEventNoCannonRows = 'Level "%s": event "%s": cannons name no "rows"';
  SEventBadCannonRow = 'Level "%s": event "%s": cannons: row %d is off the '
    + 'screen';
  SEventNoYieldRows = 'Level "%s": event "%s": cannons name a bank to '
    + 'yield but no "yieldRows"';
  SEventNoSpawnMonster = 'Level "%s": event "%s": spawn names no "monster"';
  SEventBadSpawnRow = 'Level "%s": event "%s": spawn: row %d is off the screen';
  SEventBadLaneSide = 'Level "%s": event "%s": spawn comes "from" left or '
    + 'right, not "%s"';
  SEventSpawnNoAct = 'Level "%s": event "%s": spawn needs an event that waits '
    + 'for an act';

const
  // What a shelf program takes for the seconds it leaves out: the turns
  // of a wave and of an alternation, and the short ones of a blink
  DefaultTurnOut = 2.0;
  DefaultTurnIn = 1.5;
  DefaultBlinkOut = 0.6;
  DefaultBlinkIn = 0.5;

// A typo raises, as a difficulty grade does in Levels.Defs: an event
// that never fires is a debugging season, not a feature
function ConditionOf(const AId, ALevelId, AEventId: string): TEventCondition;
begin
  for var Condition := Low(TEventCondition) to High(TEventCondition) do
    if SameText(AId, EventConditionIds[Condition]) then
      Exit(Condition);
  raise ELevelEventError.CreateFmt(SEventBadCondition,
    [ALevelId, AEventId, AId]);
end;

function ActionKindOf(const AId, ALevelId, AEventId: string): TEventActionKind;
begin
  for var Kind := Low(TEventActionKind) to High(TEventActionKind) do
    if SameText(AId, EventActionIds[Kind]) then
      Exit(Kind);
  raise ELevelEventError.CreateFmt(SEventBadAction, [ALevelId, AEventId, AId]);
end;

procedure ReadIntensity(const AObj: TJSONObject;
  const ALevelId, AEventId: string; var AAction: TEventAction);
begin
  AAction.Target := AObj.GetValue<string>('target', '');
  if AAction.Target = '' then
    raise ELevelEventError.CreateFmt(SEventNoTarget, [ALevelId, AEventId]);
  var Percent := AObj.GetValue<Integer>('value', -1);
  if (Percent < 0) or (Percent > 100) then
    raise ELevelEventError.CreateFmt(SEventBadLevel, [ALevelId, AEventId]);
  AAction.Level := Percent / 100;
  AAction.Ticks := AObj.GetValue<Integer>('ticks', 0);
end;

procedure ReadSun(const AObj: TJSONObject; const ALevelId, AEventId: string;
  var AAction: TEventAction);
var
  Angle: Double;
begin
  AAction.Target := AObj.GetValue<string>('target', '');
  if AAction.Target = '' then
    raise ELevelEventError.CreateFmt(SEventSunNoTarget, [ALevelId, AEventId]);
  if not AObj.TryGetValue<Double>('value', Angle) then
    raise ELevelEventError.CreateFmt(SEventSunNoAngle, [ALevelId, AEventId]);
  AAction.Angle := Angle;
  AAction.Ticks := AObj.GetValue<Integer>('ticks', 0);
end;

function TacticsOf(const AId, ALevelId, AEventId: string): TPilotTactics;
begin
  for var Tactics := Low(TPilotTactics) to High(TPilotTactics) do
    if SameText(AId, EventTacticsIds[Tactics]) then
      Exit(Tactics);
  raise ELevelEventError.CreateFmt(SEventBadTactics, [ALevelId, AEventId, AId]);
end;

procedure ReadTactics(const AObj: TJSONObject;
  const ALevelId, AEventId: string; var AAction: TEventAction);
begin
  AAction.Target := AObj.GetValue<string>('target', '');
  if AAction.Target = '' then
    raise ELevelEventError.CreateFmt(SEventTacticsNoTarget,
      [ALevelId, AEventId]);
  AAction.Tactics := TacticsOf(AObj.GetValue<string>('value', ''), ALevelId,
    AEventId);
end;

// The pad group of a rebuild, a restore or a fly-in; the bank of the
// shelf actions
procedure ReadGroupTarget(const AObj: TJSONObject;
  const ALevelId, AEventId: string; var AAction: TEventAction);
begin
  AAction.Target := AObj.GetValue<string>('target', '');
  if AAction.Target = '' then
    raise ELevelEventError.CreateFmt(SEventGroupNoTarget,
      [ALevelId, AEventId, EventActionIds[AAction.Kind]]);
end;

function ShelfProgramOf(const AId, ALevelId, AEventId: string): TShelfProgramKind;
begin
  for var Kind := Low(TShelfProgramKind) to High(TShelfProgramKind) do
    if SameText(AId, ShelfProgramIds[Kind]) then
      Exit(Kind);
  raise ELevelEventError.CreateFmt(SEventBadProgram, [ALevelId, AEventId, AId]);
end;

function BankOrderOf(const AId, ALevelId, AEventId: string): TBankOrder;
begin
  for var Order := Low(TBankOrder) to High(TBankOrder) do
    if SameText(AId, BankOrderIds[Order]) then
      Exit(Order);
  raise ELevelEventError.CreateFmt(SEventBadOrder, [ALevelId, AEventId, AId]);
end;

// A program without its word is hold for a wake; a program switch must
// say which
procedure ReadShelfProgram(const AObj: TJSONObject;
  const ALevelId, AEventId: string; var AAction: TEventAction);
begin
  var Id := AObj.GetValue<string>('program', '');
  if (Id = '') and (AAction.Kind = eaShelvesProgram) then
    raise ELevelEventError.CreateFmt(SEventNoProgram, [ALevelId, AEventId]);
  if Id = '' then
    Id := ShelfProgramIds[pgHold];
  AAction.Shelves.Kind := ShelfProgramOf(Id, ALevelId, AEventId);

  var DefaultOut := DefaultTurnOut;
  var DefaultIn := DefaultTurnIn;
  if AAction.Shelves.Kind = pgBlink then
  begin
    DefaultOut := DefaultBlinkOut;
    DefaultIn := DefaultBlinkIn;
  end;
  AAction.Shelves.OutSeconds := AObj.GetValue<Double>('out', DefaultOut);
  AAction.Shelves.InSeconds := AObj.GetValue<Double>('in', DefaultIn);
  var Shortest := Min(AAction.Shelves.OutSeconds, AAction.Shelves.InSeconds);
  if Shortest <= 0 then
    raise ELevelEventError.CreateFmt(SEventShelfNumber,
      [ALevelId, AEventId, EventActionIds[AAction.Kind], 'a turn', Shortest]);
end;

procedure ReadShelves(const AObj: TJSONObject;
  const ALevelId, AEventId: string; var AAction: TEventAction);
begin
  ReadGroupTarget(AObj, ALevelId, AEventId, AAction);
  if AAction.Kind <> eaShelvesSleep then
    ReadShelfProgram(AObj, ALevelId, AEventId, AAction);
  AAction.Shelves.WarnSeconds := AObj.GetValue<Double>('warn', 0);
  AAction.Order := BankOrderOf(AObj.GetValue<string>('order',
    BankOrderIds[boFile]), ALevelId, AEventId);
  AAction.StepSeconds := AObj.GetValue<Double>('step', 0);
  if AAction.Kind = eaShelvesSleep then
    AAction.SpareHero := AObj.GetValue<Boolean>('spareHero', False);
  var Shortest := Min(AAction.Shelves.WarnSeconds, AAction.StepSeconds);
  if Shortest < 0 then
    raise ELevelEventError.CreateFmt(SEventShelfNumber,
      [ALevelId, AEventId, EventActionIds[AAction.Kind], 'a wait', Shortest]);
end;

// The rows of a list, each one on the screen; an absent list is empty
function ReadRows(const AObj: TJSONObject; const AKey: string;
  const ALevelId, AEventId: string): TArray<Integer>;
begin
  Result := nil;
  var RowsArr := AObj.GetValue<TJSONArray>(AKey, nil);
  if RowsArr = nil then
    Exit;
  SetLength(Result, RowsArr.Count);
  for var i := 0 to RowsArr.Count - 1 do
  begin
    Result[i] := RowsArr.Items[i].GetValue<Integer>;
    if (Result[i] < 0) or (Result[i] >= ScreenRows) then
      raise ELevelEventError.CreateFmt(SEventBadCannonRow,
        [ALevelId, AEventId, Result[i]]);
  end;
end;

procedure ReadCannons(const AObj: TJSONObject;
  const ALevelId, AEventId: string; var AAction: TEventAction);
begin
  AAction.Cannons.Rows := ReadRows(AObj, 'rows', ALevelId, AEventId);
  if AAction.Cannons.Rows = nil then
    raise ELevelEventError.CreateFmt(SEventNoCannonRows, [ALevelId, AEventId]);
  AAction.Cannons.YieldBank := AObj.GetValue<string>('yield', '');
  AAction.Cannons.YieldRows := ReadRows(AObj, 'yieldRows', ALevelId, AEventId);
  if (AAction.Cannons.YieldBank <> '') and (AAction.Cannons.YieldRows = nil) then
    raise ELevelEventError.CreateFmt(SEventNoYieldRows, [ALevelId, AEventId]);
end;

function LaneSideOf(const AId, ALevelId, AEventId: string): TLaneSide;
begin
  for var Side := Low(TLaneSide) to High(TLaneSide) do
    if SameText(AId, EventLaneSideIds[Side]) then
      Exit(Side);
  raise ELevelEventError.CreateFmt(SEventBadLaneSide, [ALevelId, AEventId, AId]);
end;

procedure ReadSpawn(const AObj: TJSONObject; const ALevelId, AEventId: string;
  var AAction: TEventAction);
begin
  AAction.Spawn.MonsterId := AObj.GetValue<string>('monster', '');
  if AAction.Spawn.MonsterId = '' then
    raise ELevelEventError.CreateFmt(SEventNoSpawnMonster, [ALevelId, AEventId]);
  AAction.Spawn.SpriteList := AObj.GetValue<string>('spriteList', '');
  AAction.Spawn.Row := AObj.GetValue<Integer>('row', -1);
  if (AAction.Spawn.Row < 0) or (AAction.Spawn.Row >= ScreenRows) then
    raise ELevelEventError.CreateFmt(SEventBadSpawnRow,
      [ALevelId, AEventId, AAction.Spawn.Row]);
  AAction.Spawn.Side := LaneSideOf(AObj.GetValue<string>('from', ''), ALevelId,
    AEventId);
  AAction.Spawn.Tag := AObj.GetValue<string>('tag', '');
  AAction.Spawn.Rigs := ReadRigNames(AObj, ALevelId,
    Format('spawn of event "%s"', [AEventId]));
end;

procedure ReadHint(const AObj: TJSONObject; const ALevelId, AEventId: string;
  var AAction: TEventAction);
begin
  AAction.Header := ReadLocalizedText(AObj, 'header');
  var Place := AObj.GetValue<string>('place', 'top');
  if SameText(Place, 'bottom') then
    AAction.AtBottom := True
  else if not SameText(Place, 'top') then
    raise ELevelEventError.CreateFmt(SEventBadPlace,
      [ALevelId, AEventId, Place]);
end;

function ReadAction(const AObj: TJSONObject;
  const ALevelId, AEventId: string): TEventAction;
begin
  Result := Default(TEventAction);
  Result.Kind := ActionKindOf(AObj.GetValue<string>('action', ''),
    ALevelId, AEventId);
  Result.Text := ReadLocalizedText(AObj, 'text');
  Result.FileName := AObj.GetValue<string>('file', '');
  case Result.Kind of
    eaHint:
      ReadHint(AObj, ALevelId, AEventId, Result);
    eaIntensity:
      ReadIntensity(AObj, ALevelId, AEventId, Result);
    eaSun:
      ReadSun(AObj, ALevelId, AEventId, Result);
    eaTactics:
      ReadTactics(AObj, ALevelId, AEventId, Result);
    eaRebuild, eaRestore, eaFlyIn, eaMedkitsOnto:
      ReadGroupTarget(AObj, ALevelId, AEventId, Result);
    eaShelvesWake, eaShelvesSleep, eaShelvesProgram:
      ReadShelves(AObj, ALevelId, AEventId, Result);
    eaCannons:
      ReadCannons(AObj, ALevelId, AEventId, Result);
    eaSpawn:
      ReadSpawn(AObj, ALevelId, AEventId, Result);
  end;
end;

procedure ReadGravelDealt(const AObj: TJSONObject; const ALevelId: string;
  var AEvent: TLevelEvent);
begin
  if AEvent.Act <= 0 then
    raise ELevelEventError.CreateFmt(SEventNoBatchAct, [ALevelId, AEvent.Id]);
  AEvent.Part := AObj.GetValue<Integer>('part', 0);
  AEvent.Whole := AObj.GetValue<Integer>('of', 0);
  if (AEvent.Whole <= 0) or (AEvent.Part < 0) or (AEvent.Part >= AEvent.Whole) then
    raise ELevelEventError.CreateFmt(SEventBadShare, [ALevelId, AEvent.Id]);
end;

function ReadEvent(const AObj: TJSONObject; const ALevelId: string;
  AIndex: Integer): TLevelEvent;
begin
  Result := Default(TLevelEvent);
  Result.Id := AObj.GetValue<string>('id', '');
  if Result.Id = '' then
    raise ELevelEventError.CreateFmt(SEventNoId, [ALevelId, AIndex + 1]);

  Result.Screen := AObj.GetValue<Integer>('screen');
  Result.Condition := ConditionOf(AObj.GetValue<string>('when', ''),
    ALevelId, Result.Id);
  Result.Tag := AObj.GetValue<string>('tag', '');
  if (Result.Condition in TaggedConditions) and (Result.Tag = '') then
    raise ELevelEventError.CreateFmt(SEventNoTag,
      [ALevelId, Result.Id, EventConditionIds[Result.Condition]]);
  Result.Lives := AObj.GetValue<Integer>('lives', 0);
  if (Result.Condition = ecLivesBelow) and (Result.Lives <= 0) then
    raise ELevelEventError.CreateFmt(SEventNoLives, [ALevelId, Result.Id]);
  Result.Act := AObj.GetValue<Integer>('act', 0);
  if (Result.Condition = ecActReached) and (Result.Act <= 0) then
    raise ELevelEventError.CreateFmt(SEventNoAct, [ALevelId, Result.Id]);
  if Result.Condition = ecGravelDealt then
    ReadGravelDealt(AObj, ALevelId, Result);
  Result.DelayTicks := AObj.GetValue<Integer>('delay', 0);

  var ActionsArr := AObj.GetValue<TJSONArray>('then', nil);
  if (ActionsArr = nil) or (ActionsArr.Count = 0) then
    raise ELevelEventError.CreateFmt(SEventNoActions, [ALevelId, Result.Id]);
  SetLength(Result.Actions, ActionsArr.Count);
  for var i := 0 to ActionsArr.Count - 1 do
    Result.Actions[i] := ReadAction(ActionsArr.Items[i] as TJSONObject,
      ALevelId, Result.Id);
  for var Action in Result.Actions do
    if (Action.Kind = eaSpawn) and (Result.Act <= 0) then
      raise ELevelEventError.CreateFmt(SEventSpawnNoAct, [ALevelId, Result.Id]);
end;

function ParseLevelEvents(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TLevelEvent>;
begin
  Result := nil;
  var EventsArr := ARoot.GetValue<TJSONArray>('events', nil);
  if EventsArr = nil then
    Exit;

  SetLength(Result, EventsArr.Count);
  for var i := 0 to EventsArr.Count - 1 do
    Result[i] := ReadEvent(EventsArr.Items[i] as TJSONObject, ALevelId, i);
end;

end.
