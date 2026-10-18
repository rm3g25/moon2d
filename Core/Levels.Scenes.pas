{
  Levels.Scenes - the scenes of a level: the "scenes" section of level
  JSON. A scene is a play on one screen: cues on a timeline of ticks
  move the level's crafts and turn their parts, aim beams, light and put
  out the dynamic objects, set the sound, the light and the ground under
  the hero, speak through the terminal, hold monsters and kill them,
  bring new ones and wake pads, while the player keeps the controls. An
  event starts it (the action "scene" of Levels.Events); a scene has no
  conditions of its own. Model and parser only: the game runs them
  (Scenes.Director), the editor will write them.

  A cue plays at a tick of the scene, or a number of ticks after another
  cue has played. A wait is a cue that plays once its condition holds:
  the cues after it count from that moment, and the timeline stops being
  the same tick for tick.

  The aftermath is the world the scene leaves behind, as far as the
  level file does not: the monsters it brought and took, the pads it
  moved. The game puts it whenever a death rebuilds the world after the
  scene has played to its end.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Scenes;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Localization, Levels.Dynamics;

type
  ELevelSceneError = class(Exception);

  // Level: the scene plays once a level - a death in the middle of it
  // plays it again from the start, a death after it finds its end
  // standing. Life: a death rewinds what it moved, and it plays again as
  // the events of the screen do.
  TSceneOnce = (soLevel, soLife);

  // Sound: a sound of the sound folder plays from the cue on; the scene
  // stops it if it ends early. Music: the level's music fades to a share
  // of its volume. Shade: the world darkens by a share. Shake: the
  // ground trembles, as a share of the scene's full rumble. Move: the
  // craft Target heads for x and/or y, each axis on its own. Track: the
  // parts tagged Part of the craft Target follow the mark. Aim: the beam
  // Target swings onto the mark and stays on it; lightning tagged Target
  // turns its bolts toward it. Intensity: the dynamic objects tagged
  // Target fade to a share. Hint: the terminal prints a line in the name
  // of Header. Hold: the monsters tagged Target hold their fire from now
  // on. Kill: they die, and nobody is paid for it. Spawn: a monster is
  // born, standing, tagged Target - asleep, if told so. Release: the
  // monsters tagged Target wake and fire again. Remove: they are gone, as
  // if never there. Wake: the pad Target, asleep in the level file, is
  // there. Fly: the pad Target flies to x, y. Wait: nothing, once its
  // condition holds.
  TSceneCueKind = (ckSound, ckMusic, ckShade, ckShake, ckMove, ckTrack,
    ckAim, ckIntensity, ckHint, ckHold, ckKill, ckSpawn, ckRelease, ckRemove,
    ckWake, ckFly, ckWait);

  // What a part follows or a beam is aimed at: the hero, the monster
  // tagged MarkTag, a point of the screen, or nothing - a part goes back
  // to rest
  TSceneMark = (smHero, smMonster, smPoint, smNothing);

  // What a wait waits for: no live monster on the deck of the pad Target
  TSceneWait = (swDeckEmpty);

  // One cue in level JSON:
  //   {"at": 99, "do": "move", "target": "cordon", "x": -989.8,
  //    "ticks": 363, "ease": "out"}
  //   {"at": 0, "do": "sound", "file": "cordon.ogg"}
  //   {"at": 0, "do": "music", "value": 0, "ticks": 66}
  //   {"at": 99, "do": "track", "target": "cordon", "part": "gun",
  //    "on": "hero"}
  //   {"at": 627, "do": "aim", "target": "cordonScan", "on": "cordonPrey",
  //    "ticks": 66, "ease": "inOut"}
  //   {"at": 700, "do": "aim", "target": "cordonLift", "x": 336, "y": 272,
  //    "ticks": 14}
  //   {"at": 495, "do": "intensity", "target": "cordonLensL", "value": 100,
  //    "ticks": 4}
  //   {"at": 545, "do": "hint", "header": "TEK-Q6", "text": "...",
  //    "textEn": "..."}
  //   {"at": 0, "do": "hold", "target": "cordonPrey"}
  //   {"at": 693, "do": "kill", "target": "cordonPrey"}
  //   {"at": 714, "do": "spawn", "monster": "tank", "spriteList": "tank.mns",
  //    "tag": "cordonTank", "seat": "s09-lift", "facing": "right",
  //    "asleep": true}
  //   {"id": "docked", "at": 780, "do": "release", "target": "cordonTank"}
  //   {"do": "remove", "target": "cordonPrey"}
  //   {"at": 714, "do": "wake", "target": "s09-lift"}
  //   {"at": 714, "do": "fly", "target": "s09-lift", "x": 320, "y": 256,
  //    "ticks": 66}
  //   {"id": "unloaded", "after": "docked", "do": "wait",
  //    "until": "deckEmpty", "target": "s09-lift"}
  // "at" - ticks from the start of the scene; or "after", the id of a cue
  // above it in the file, and "delay", ticks after that cue has played, 0
  // by default. "value" is a percentage; "ticks" 0 by default - at once;
  // "ease" one of "linear" (by default), "in", "out", "inOut". "on" is
  // "hero", a monster's tag or, for a track alone, "none"; in place of
  // "on", "x" and "y" name a point of the screen. A hint takes a "header"
  // and a "text" (localized, "headerEn", "textEn") and "place" - "top" by
  // default, or "bottom". A spawn stands the body in the middle of the
  // deck of the pad "seat", or with the left edge of its cell at "x" and
  // its feet at "y"; "facing" is "left" by default. Its "spriteList" is
  // the monster's own when left out, as an event's spawn reads it - a
  // monster with none, as a hull's, needs one here.
  TSceneCue = record
    Id: string; // '' - no cue counts from it
    At: Integer; // ticks from the start of the scene; NotTimed after a cue
    After: Integer; // the index of the cue counted from; -1 - none
    Delay: Integer;
    // The tick it plays at when no wait holds it up: the cues stand in
    // this order
    Plan: Integer;
    Kind: TSceneCueKind;
    Target: string; // for a spawn, the tag it gives
    Part: string;
    Mark: TSceneMark;
    MarkTag: string; // smMonster
    FileName: string;
    Level: Single; // 0..1
    MovesX, MovesY: Boolean;
    X, Y: Single; // a move's, a fly's, a spawn's, smPoint's
    Ticks: Integer;
    Ease: TMotionEase;
    Header: TLocalizedText;
    Text: TLocalizedText;
    AtBottom: Boolean;
    Monster: string; // a spawn's
    SpriteList: string; // a spawn's; '' - the monster's own
    Seat: string; // a spawn's pad; '' - at x, y
    FacesRight: Boolean;
    Asleep: Boolean;
    Waits: TSceneWait;
  end;

  // One scene in level JSON:
  //   {"id": "cordon9", "screen": 9, "once": "level", "cues": [...],
  //    "aftermath": [...]}
  // "once" is "level" by default. The aftermath is a list of cues with
  // neither "at" nor "after", played all at once; no hint, sound or wait
  // among them.
  TLevelScene = record
    Id: string;
    Screen: Integer; // 1-based, as the level counts
    Once: TSceneOnce;
    Cues: TArray<TSceneCue>; // by their Plan, the file's order among equals
    Aftermath: TArray<TSceneCue>;
  end;

const
  NotTimed = -1;
  SceneOnceIds: array [TSceneOnce] of string = ('level', 'life');
  SceneCueIds: array [TSceneCueKind] of string = ('sound', 'music', 'shade',
    'shake', 'move', 'track', 'aim', 'intensity', 'hint', 'hold', 'kill',
    'spawn', 'release', 'remove', 'wake', 'fly', 'wait');
  SceneWaitIds: array [TSceneWait] of string = ('deckEmpty');
  // The words of "on" that are not a tag
  SceneMarkHero = 'hero';
  SceneMarkNothing = 'none';
  // What a cue does to the monsters and the pads: the world the aftermath
  // puts, not the scene's own things
  SceneWorldCues = [ckHold, ckKill, ckSpawn, ckRelease, ckRemove, ckWake,
    ckFly, ckWait];
  // The cues that name a monster by Target
  SceneMonsterCues = [ckHold, ckKill, ckSpawn, ckRelease, ckRemove];
  // The cues that name a pad by Target
  ScenePadCues = [ckWake, ckFly, ckWait];

// Reads the "scenes" array of a level; an absent section is an empty
// list. ALevelId names the level in errors.
function ParseLevelScenes(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TLevelScene>;

implementation

uses
  System.Generics.Collections;

resourcestring
  SSceneNoId = 'Level "%s": scene #%d has no id';
  SSceneTwice = 'Level "%s": two scenes are called "%s"';
  SSceneBadWord = 'Level "%s": scene "%s": unknown %s "%s"';
  SSceneNoCues = 'Level "%s": scene "%s" has no cues';
  SSceneBadTick = 'Level "%s": scene "%s": cue #%d takes "at", "delay" and '
    + '"ticks" from 0 up';
  SSceneNoFile = 'Level "%s": scene "%s": a sound cue names no "file"';
  SSceneBadLevel = 'Level "%s": scene "%s": cue #%d takes a "value", 0..100';
  SSceneNoTarget = 'Level "%s": scene "%s": cue #%d names no "target"';
  SSceneMoveNowhere = 'Level "%s": scene "%s": a move names neither "x" '
    + 'nor "y"';
  SSceneNoPart = 'Level "%s": scene "%s": a track names no "part"';
  SSceneNoMark = 'Level "%s": scene "%s": cue #%d says nothing "on"';
  SSceneAimNowhere = 'Level "%s": scene "%s": a beam is aimed at something, '
    + 'not "none"';
  SSceneHintMute = 'Level "%s": scene "%s": a hint takes a "header" and a '
    + '"text"';
  SSceneWhen = 'Level "%s": scene "%s": cue #%d takes "at" or "after", '
    + 'one of the two';
  SSceneAfterUnknown = 'Level "%s": scene "%s": cue #%d plays after "%s", '
    + 'which no cue above it is called';
  SSceneIdTwice = 'Level "%s": scene "%s": two cues are called "%s"';
  SSceneFlyNowhere = 'Level "%s": scene "%s": a fly takes "x" and "y"';
  SSceneSpawnBlank = 'Level "%s": scene "%s": a spawn takes a "monster" and '
    + 'a "tag"';
  SSceneSpawnNowhere = 'Level "%s": scene "%s": a spawn takes a "seat" or '
    + '"x" and "y", one or the other';
  SSceneAftermathTimed = 'Level "%s": scene "%s": aftermath cue #%d takes '
    + 'no "at", "after" or "id" - it plays at once';
  SSceneAftermathKind = 'Level "%s": scene "%s": aftermath cue #%d is a '
    + '"%s" - no sound, hint or wait plays at once';

const
  // Where a hint's box stands, by AtBottom
  HintPlaceIds: array [Boolean] of string = ('top', 'bottom');
  // Which way a spawn faces, by FacesRight
  FacingIds: array [Boolean] of string = ('left', 'right');
  NoCue = -1;
  // Played at once, these do nothing a reader could see or hear
  MuteAtOnce = [ckSound, ckHint, ckWait];

// A typo raises, as an event's does: a scene that never plays is a
// debugging season, not a feature
function WordOf(const AId: string; const AIds: array of string;
  const ALevelId, ASceneId, AWhat: string): Integer;
begin
  for var i := 0 to High(AIds) do
    if SameText(AId, AIds[i]) then
      Exit(i);
  raise ELevelSceneError.CreateFmt(SSceneBadWord,
    [ALevelId, ASceneId, AWhat, AId]);
end;

procedure ReadCueLevel(const AObj: TJSONObject; const ALevelId,
  ASceneId: string; ANumber: Integer; var ACue: TSceneCue);
begin
  var Percent := AObj.GetValue<Integer>('value', -1);
  if (Percent < 0) or (Percent > 100) then
    raise ELevelSceneError.CreateFmt(SSceneBadLevel,
      [ALevelId, ASceneId, ANumber]);
  ACue.Level := Percent / 100;
end;

procedure ReadTarget(const AObj: TJSONObject; const ALevelId,
  ASceneId: string; ANumber: Integer; var ACue: TSceneCue);
begin
  ACue.Target := AObj.GetValue<string>('target', '');
  if ACue.Target = '' then
    raise ELevelSceneError.CreateFmt(SSceneNoTarget,
      [ALevelId, ASceneId, ANumber]);
end;

procedure ReadEase(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  var ACue: TSceneCue);
begin
  ACue.Ease := TMotionEase(WordOf(AObj.GetValue<string>('ease',
    MotionEaseIds[meLinear]), MotionEaseIds, ALevelId, ASceneId, 'ease'));
end;

// "x" and "y", either of them; False when neither is there
function ReadAxes(const AObj: TJSONObject; var ACue: TSceneCue): Boolean;
var
  Value: Double;
begin
  ACue.MovesX := AObj.TryGetValue<Double>('x', Value);
  if ACue.MovesX then
    ACue.X := Value;
  ACue.MovesY := AObj.TryGetValue<Double>('y', Value);
  if ACue.MovesY then
    ACue.Y := Value;
  Result := ACue.MovesX or ACue.MovesY;
end;

procedure ReadMove(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  var ACue: TSceneCue);
begin
  if not ReadAxes(AObj, ACue) then
    raise ELevelSceneError.CreateFmt(SSceneMoveNowhere, [ALevelId, ASceneId]);
  ReadEase(AObj, ALevelId, ASceneId, ACue);
end;

procedure ReadFly(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  var ACue: TSceneCue);
begin
  ReadAxes(AObj, ACue);
  if not (ACue.MovesX and ACue.MovesY) then
    raise ELevelSceneError.CreateFmt(SSceneFlyNowhere, [ALevelId, ASceneId]);
end;

procedure ReadMark(const AObj: TJSONObject; const ALevelId,
  ASceneId: string; ANumber: Integer; var ACue: TSceneCue);
begin
  var Mark := AObj.GetValue<string>('on', '');
  if Mark = '' then
  begin
    ReadAxes(AObj, ACue);
    if not (ACue.MovesX and ACue.MovesY) then
      raise ELevelSceneError.CreateFmt(SSceneNoMark,
        [ALevelId, ASceneId, ANumber]);
    ACue.Mark := smPoint;
  end
  else if SameText(Mark, SceneMarkHero) then
    ACue.Mark := smHero
  else if SameText(Mark, SceneMarkNothing) then
    ACue.Mark := smNothing
  else
  begin
    ACue.Mark := smMonster;
    ACue.MarkTag := Mark;
  end;
end;

procedure ReadTrack(const AObj: TJSONObject; const ALevelId,
  ASceneId: string; ANumber: Integer; var ACue: TSceneCue);
begin
  ACue.Part := AObj.GetValue<string>('part', '');
  if ACue.Part = '' then
    raise ELevelSceneError.CreateFmt(SSceneNoPart, [ALevelId, ASceneId]);
  ReadMark(AObj, ALevelId, ASceneId, ANumber, ACue);
end;

procedure ReadAim(const AObj: TJSONObject; const ALevelId,
  ASceneId: string; ANumber: Integer; var ACue: TSceneCue);
begin
  ReadMark(AObj, ALevelId, ASceneId, ANumber, ACue);
  if ACue.Mark = smNothing then
    raise ELevelSceneError.CreateFmt(SSceneAimNowhere, [ALevelId, ASceneId]);
  ReadEase(AObj, ALevelId, ASceneId, ACue);
end;

// The header is the voice of whoever speaks: a scene has no channel of
// its own to fall back on
procedure ReadHint(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  var ACue: TSceneCue);
begin
  ACue.Header := ReadLocalizedText(AObj, 'header');
  ACue.Text := ReadLocalizedText(AObj, 'text');
  if (ACue.Header.Current = '') or (ACue.Text.Current = '') then
    raise ELevelSceneError.CreateFmt(SSceneHintMute, [ALevelId, ASceneId]);
  ACue.AtBottom := Boolean(WordOf(AObj.GetValue<string>('place',
    HintPlaceIds[False]), HintPlaceIds, ALevelId, ASceneId, 'place'));
end;

procedure ReadSpawn(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  var ACue: TSceneCue);
begin
  ACue.Monster := AObj.GetValue<string>('monster', '');
  ACue.Target := AObj.GetValue<string>('tag', '');
  if (ACue.Monster = '') or (ACue.Target = '') then
    raise ELevelSceneError.CreateFmt(SSceneSpawnBlank, [ALevelId, ASceneId]);
  ACue.SpriteList := AObj.GetValue<string>('spriteList', '');
  ACue.Seat := AObj.GetValue<string>('seat', '');
  var HasPoint := ReadAxes(AObj, ACue);
  var Placed := (ACue.MovesX and ACue.MovesY) and (ACue.Seat = '');
  var Seated := not HasPoint and (ACue.Seat <> '');
  if not (Placed or Seated) then
    raise ELevelSceneError.CreateFmt(SSceneSpawnNowhere, [ALevelId, ASceneId]);
  ACue.FacesRight := Boolean(WordOf(AObj.GetValue<string>('facing',
    FacingIds[False]), FacingIds, ALevelId, ASceneId, 'facing'));
  ACue.Asleep := AObj.GetValue<Boolean>('asleep', False);
end;

// What the cue does; when it plays is the caller's to read
function ReadCue(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  ANumber: Integer): TSceneCue;
begin
  Result := Default(TSceneCue);
  Result.Kind := TSceneCueKind(WordOf(AObj.GetValue<string>('do', ''),
    SceneCueIds, ALevelId, ASceneId, 'cue'));
  Result.At := NotTimed;
  Result.After := NoCue;
  Result.Ticks := AObj.GetValue<Integer>('ticks', 0);
  if Result.Ticks < 0 then
    raise ELevelSceneError.CreateFmt(SSceneBadTick,
      [ALevelId, ASceneId, ANumber]);
  if Result.Kind in [ckMove, ckTrack, ckAim, ckIntensity, ckHold, ckKill,
    ckRelease, ckRemove, ckWake, ckFly, ckWait] then
    ReadTarget(AObj, ALevelId, ASceneId, ANumber, Result);
  case Result.Kind of
    ckSound:
      begin
        Result.FileName := AObj.GetValue<string>('file', '');
        if Result.FileName = '' then
          raise ELevelSceneError.CreateFmt(SSceneNoFile, [ALevelId, ASceneId]);
      end;
    ckMusic, ckShade, ckShake, ckIntensity:
      ReadCueLevel(AObj, ALevelId, ASceneId, ANumber, Result);
    ckMove:
      ReadMove(AObj, ALevelId, ASceneId, Result);
    ckTrack:
      ReadTrack(AObj, ALevelId, ASceneId, ANumber, Result);
    ckAim:
      ReadAim(AObj, ALevelId, ASceneId, ANumber, Result);
    ckHint:
      ReadHint(AObj, ALevelId, ASceneId, Result);
    ckSpawn:
      ReadSpawn(AObj, ALevelId, ASceneId, Result);
    ckFly:
      ReadFly(AObj, ALevelId, ASceneId, Result);
    ckWait:
      Result.Waits := TSceneWait(WordOf(AObj.GetValue<string>('until', ''),
        SceneWaitIds, ALevelId, ASceneId, 'until'));
  end;
end;

function IndexOfCue(const ACues: TArray<TSceneCue>; const AId: string;
  ABefore: Integer): Integer;
begin
  for var i := 0 to ABefore - 1 do
    if ACues[i].Id = AId then
      Exit(i);
  Result := NoCue;
end;

// "at", or "after" a cue above it in the file and a "delay": the cue
// counted from is known by then, so its Plan is too, and no two cues can
// wait for each other
procedure ReadWhen(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  ANumber: Integer; var ACues: TArray<TSceneCue>);
begin
  var Index := ANumber - 1;
  ACues[Index].Id := AObj.GetValue<string>('id', '');
  if (ACues[Index].Id <> '') and
    (IndexOfCue(ACues, ACues[Index].Id, Index) <> NoCue) then
    raise ELevelSceneError.CreateFmt(SSceneIdTwice,
      [ALevelId, ASceneId, ACues[Index].Id]);

  var AfterId := AObj.GetValue<string>('after', '');
  var HasAt := AObj.GetValue('at') <> nil;
  if HasAt = (AfterId <> '') then
    raise ELevelSceneError.CreateFmt(SSceneWhen, [ALevelId, ASceneId, ANumber]);
  if HasAt then
  begin
    ACues[Index].At := AObj.GetValue<Integer>('at', NotTimed);
    if ACues[Index].At < 0 then
      raise ELevelSceneError.CreateFmt(SSceneBadTick,
        [ALevelId, ASceneId, ANumber]);
    ACues[Index].Plan := ACues[Index].At;
    Exit;
  end;

  ACues[Index].After := IndexOfCue(ACues, AfterId, Index);
  if ACues[Index].After = NoCue then
    raise ELevelSceneError.CreateFmt(SSceneAfterUnknown,
      [ALevelId, ASceneId, ANumber, AfterId]);
  ACues[Index].Delay := AObj.GetValue<Integer>('delay', 0);
  if ACues[Index].Delay < 0 then
    raise ELevelSceneError.CreateFmt(SSceneBadTick,
      [ALevelId, ASceneId, ANumber]);
  ACues[Index].Plan := ACues[ACues[Index].After].Plan + ACues[Index].Delay;
end;

// By their Plan; cues of one Plan keep the order of the file, so a later
// one may override an earlier one, and a cue counted from another stays
// after it. After points at an index of the file and follows the move.
procedure SortByPlan(var ACues: TArray<TSceneCue>);
var
  Order: TArray<Integer>; // the file index of each place
  PlaceOf: TArray<Integer>; // the place of each file index
begin
  SetLength(Order, Length(ACues));
  for var i := 0 to High(ACues) do
    Order[i] := i;
  for var i := 1 to High(Order) do
  begin
    var Moving := Order[i];
    var j := i - 1;
    while (j >= 0) and (ACues[Order[j]].Plan > ACues[Moving].Plan) do
    begin
      Order[j + 1] := Order[j];
      Dec(j);
    end;
    Order[j + 1] := Moving;
  end;

  SetLength(PlaceOf, Length(ACues));
  for var i := 0 to High(Order) do
    PlaceOf[Order[i]] := i;
  var Sorted: TArray<TSceneCue>;
  SetLength(Sorted, Length(ACues));
  for var i := 0 to High(Order) do
  begin
    Sorted[i] := ACues[Order[i]];
    if Sorted[i].After <> NoCue then
      Sorted[i].After := PlaceOf[Sorted[i].After];
  end;
  ACues := Sorted;
end;

function ReadCues(const AArr: TJSONArray; const ALevelId,
  ASceneId: string): TArray<TSceneCue>;
begin
  SetLength(Result, AArr.Count);
  for var i := 0 to AArr.Count - 1 do
  begin
    var CueObj := AArr.Items[i] as TJSONObject;
    Result[i] := ReadCue(CueObj, ALevelId, ASceneId, i + 1);
    ReadWhen(CueObj, ALevelId, ASceneId, i + 1, Result);
  end;
  SortByPlan(Result);
end;

function ReadAftermath(const AArr: TJSONArray; const ALevelId,
  ASceneId: string): TArray<TSceneCue>;
begin
  Result := nil;
  if AArr = nil then
    Exit;
  SetLength(Result, AArr.Count);
  for var i := 0 to AArr.Count - 1 do
  begin
    var CueObj := AArr.Items[i] as TJSONObject;
    var Timed := (CueObj.GetValue('at') <> nil) or
      (CueObj.GetValue('after') <> nil) or (CueObj.GetValue('id') <> nil);
    if Timed then
      raise ELevelSceneError.CreateFmt(SSceneAftermathTimed,
        [ALevelId, ASceneId, i + 1]);
    Result[i] := ReadCue(CueObj, ALevelId, ASceneId, i + 1);
    if Result[i].Kind in MuteAtOnce then
      raise ELevelSceneError.CreateFmt(SSceneAftermathKind,
        [ALevelId, ASceneId, i + 1, SceneCueIds[Result[i].Kind]]);
  end;
end;

function ReadScene(const AObj: TJSONObject; const ALevelId: string;
  AIndex: Integer): TLevelScene;
begin
  Result := Default(TLevelScene);
  Result.Id := AObj.GetValue<string>('id', '');
  if Result.Id = '' then
    raise ELevelSceneError.CreateFmt(SSceneNoId, [ALevelId, AIndex + 1]);
  Result.Screen := AObj.GetValue<Integer>('screen');
  Result.Once := TSceneOnce(WordOf(AObj.GetValue<string>('once',
    SceneOnceIds[soLevel]), SceneOnceIds, ALevelId, Result.Id, 'once'));

  var CuesArr := AObj.GetValue<TJSONArray>('cues', nil);
  if (CuesArr = nil) or (CuesArr.Count = 0) then
    raise ELevelSceneError.CreateFmt(SSceneNoCues, [ALevelId, Result.Id]);
  Result.Cues := ReadCues(CuesArr, ALevelId, Result.Id);
  Result.Aftermath := ReadAftermath(AObj.GetValue<TJSONArray>('aftermath',
    nil), ALevelId, Result.Id);
end;

function ParseLevelScenes(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TLevelScene>;
begin
  Result := nil;
  var ScenesArr := ARoot.GetValue<TJSONArray>('scenes', nil);
  if ScenesArr = nil then
    Exit;

  SetLength(Result, ScenesArr.Count);
  for var i := 0 to ScenesArr.Count - 1 do
  begin
    Result[i] := ReadScene(ScenesArr.Items[i] as TJSONObject, ALevelId, i);
    for var j := 0 to i - 1 do
      if SameText(Result[j].Id, Result[i].Id) then
        raise ELevelSceneError.CreateFmt(SSceneTwice, [ALevelId, Result[i].Id]);
  end;
end;

end.
