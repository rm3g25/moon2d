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
  System.SysUtils, System.JSON, Localization, Monsters.Defs;

type
  ELevelEventError = class(Exception);

  // What the event waits for. The hero must be on the event's screen
  // for any of them; enterScreen asks nothing more. The rest watch the
  // monsters carrying the tag: allDead - none of them alive; livesBelow
  // - one alive with fewer lives than "lives", a mark told for the
  // normal grade that grows with the difficulty as the lives do; enraged
  // - one gone into its rage (the boss below its rage mark, a tank below
  // its own).
  TEventCondition = (ecEnterScreen, ecAllDead, ecLivesBelow, ecEnraged);

  TEventActionKind = (eaBigMessage, eaSmallMessage, eaHint, eaMusic,
    eaIntensity, eaSun, eaTactics, eaRebuild, eaRestore);

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
    Target: string;
    Level: Single;
    Angle: Single;
    Ticks: Integer;
    Tactics: TPilotTactics;
  end;

  // One event in level JSON:
  //   {
  //     "id": "labHint",
  //     "screen": 12,
  //     "when": "allDead", "tag": "labGuard",
  //     (or "when": "livesBelow", "tag": "boss", "lives": 150)
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
    DelayTicks: Integer; // between the condition and the actions
    Actions: TArray<TEventAction>;
  end;

const
  // The JSON vocabulary of "when", of "action" and of the "value" the
  // tactics action takes
  EventConditionIds: array [TEventCondition] of string = (
    'enterScreen', 'allDead', 'livesBelow', 'enraged');
  EventActionIds: array [TEventActionKind] of string = (
    'bigMessage', 'smallMessage', 'hint', 'music', 'intensity', 'sun',
    'tactics', 'rebuild', 'restore');
  EventTacticsIds: array [TPilotTactics] of string = (
    'laps', 'dives', 'rams', 'hunts');

  // The conditions that watch tagged placements
  TaggedConditions = [ecAllDead, ecLivesBelow, ecEnraged];

// Reads the "events" array of a level; an absent section is an empty
// list. ALevelId names the level in errors.
function ParseLevelEvents(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TLevelEvent>;

implementation

uses
  System.Generics.Collections;

resourcestring
  SEventNoId = 'Level "%s": event #%d has no id';
  SEventBadCondition = 'Level "%s": event "%s": unknown condition "%s"';
  SEventNoTag = 'Level "%s": event "%s": %s names no tag';
  SEventNoLives = 'Level "%s": event "%s": livesBelow needs "lives" above zero';
  SEventNoTarget = 'Level "%s": event "%s": intensity names no target';
  SEventBadLevel = 'Level "%s": event "%s": intensity takes a "value", 0..100';
  SEventSunNoTarget = 'Level "%s": event "%s": sun names no target';
  SEventSunNoAngle = 'Level "%s": event "%s": sun takes a "value" in degrees';
  SEventTacticsNoTarget = 'Level "%s": event "%s": tactics names no target';
  SEventBadTactics = 'Level "%s": event "%s": unknown tactics "%s"';
  SEventGroupNoTarget = 'Level "%s": event "%s": %s names no target';
  SEventBadAction = 'Level "%s": event "%s": unknown action "%s"';
  SEventNoActions = 'Level "%s": event "%s" has no actions';

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

// The pad group of a rebuild or a restore
procedure ReadGroupTarget(const AObj: TJSONObject;
  const ALevelId, AEventId: string; var AAction: TEventAction);
begin
  AAction.Target := AObj.GetValue<string>('target', '');
  if AAction.Target = '' then
    raise ELevelEventError.CreateFmt(SEventGroupNoTarget,
      [ALevelId, AEventId, EventActionIds[AAction.Kind]]);
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
    eaIntensity:
      ReadIntensity(AObj, ALevelId, AEventId, Result);
    eaSun:
      ReadSun(AObj, ALevelId, AEventId, Result);
    eaTactics:
      ReadTactics(AObj, ALevelId, AEventId, Result);
    eaRebuild, eaRestore:
      ReadGroupTarget(AObj, ALevelId, AEventId, Result);
  end;
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
  Result.DelayTicks := AObj.GetValue<Integer>('delay', 0);

  var ActionsArr := AObj.GetValue<TJSONArray>('then', nil);
  if (ActionsArr = nil) or (ActionsArr.Count = 0) then
    raise ELevelEventError.CreateFmt(SEventNoActions, [ALevelId, Result.Id]);
  SetLength(Result.Actions, ActionsArr.Count);
  for var i := 0 to ActionsArr.Count - 1 do
    Result.Actions[i] := ReadAction(ActionsArr.Items[i] as TJSONObject,
      ALevelId, Result.Id);
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
