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
  System.SysUtils, System.JSON, Localization;

type
  ELevelEventError = class(Exception);

  // What the event waits for. The hero must be on the event's screen
  // for any of them; enterScreen asks nothing more.
  TEventCondition = (ecEnterScreen, ecAllDead);

  TEventActionKind = (eaBigMessage, eaSmallMessage, eaHint, eaMusic);

  TEventAction = record
    Kind: TEventActionKind;
    Text: TLocalizedText; // the message kinds; localized like the triggers
    FileName: string; // eaMusic
  end;

  // One event in level JSON:
  //   {
  //     "id": "labHint",
  //     "screen": 12,
  //     "when": "allDead", "tag": "labGuard",
  //     "delay": 33,
  //     "then": [
  //       {"action": "hint", "text": "...", "textEn": "..."}
  //     ]
  //   }
  TLevelEvent = record
    Id: string;
    Screen: Integer; // 1-based, as the level counts
    Condition: TEventCondition;
    Tag: string; // ecAllDead: the placements that must fall
    DelayTicks: Integer; // between the condition and the actions
    Actions: TArray<TEventAction>;
  end;

const
  // The JSON vocabulary of "when" and "action"
  EventConditionIds: array [TEventCondition] of string = (
    'enterScreen', 'allDead');
  EventActionIds: array [TEventActionKind] of string = (
    'bigMessage', 'smallMessage', 'hint', 'music');

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
  SEventNoTag = 'Level "%s": event "%s": allDead names no tag';
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

function ReadAction(const AObj: TJSONObject;
  const ALevelId, AEventId: string): TEventAction;
begin
  Result := Default(TEventAction);
  Result.Kind := ActionKindOf(AObj.GetValue<string>('action', ''),
    ALevelId, AEventId);
  Result.Text := ReadLocalizedText(AObj, 'text');
  Result.FileName := AObj.GetValue<string>('file', '');
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
  if (Result.Condition = ecAllDead) and (Result.Tag = '') then
    raise ELevelEventError.CreateFmt(SEventNoTag, [ALevelId, Result.Id]);
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
