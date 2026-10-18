{
  Levels.Scenes - the scenes of a level: the "scenes" section of level
  JSON. A scene is a play on one screen: cues on a timeline of ticks
  move the level's crafts and turn their parts, aim beams, light and put
  out the dynamic objects, set the sound, the light and the ground under
  the hero, speak through the terminal, hold monsters and kill them,
  while the player keeps the controls. An event starts it (the action
  "scene" of Levels.Events); a scene has no conditions of its own. Model
  and parser only: the game runs them (Scenes.Director), the editor will
  write them.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Scenes;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Localization, Levels.Dynamics;

type
  ELevelSceneError = class(Exception);

  // Level: the scene plays once a level - a death after its start finds
  // its end standing. Life: a death rewinds what it moved, and it plays
  // again as the events of the screen do.
  TSceneOnce = (soLevel, soLife);

  // Sound: a sound of the sound folder plays from the cue on; the scene
  // stops it if it ends early. Music: the level's music fades to a share
  // of its volume. Shade: the world darkens by a share. Shake: the
  // ground trembles, as a share of the scene's full rumble. Move: the
  // craft Target heads for x and/or y, each axis on its own. Track: the
  // parts tagged Part of the craft Target follow the mark. Aim: the beam
  // Target swings onto the mark and stays on it; lightning tagged Target
  // turns its bolts toward it. Intensity: the dynamic
  // objects tagged Target fade to a share. Hint: the terminal prints a
  // line in the name of Header. Hold: the monsters tagged Target hold
  // their fire from now on. Kill: they die, and nobody is paid for it.
  TSceneCueKind = (ckSound, ckMusic, ckShade, ckShake, ckMove, ckTrack,
    ckAim, ckIntensity, ckHint, ckHold, ckKill);

  // What a part follows or a beam is aimed at: the hero, the monster
  // tagged MarkTag, or nothing - a part goes back to rest
  TSceneMark = (smHero, smMonster, smNothing);

  // One cue in level JSON:
  //   {"at": 99, "do": "move", "target": "cordon", "x": -989.8,
  //    "ticks": 363, "ease": "out"}
  //   {"at": 0, "do": "sound", "file": "cordon.ogg"}
  //   {"at": 0, "do": "music", "value": 0, "ticks": 66}
  //   {"at": 99, "do": "track", "target": "cordon", "part": "gun",
  //    "on": "hero"}
  //   {"at": 627, "do": "aim", "target": "cordonScan", "on": "cordonPrey",
  //    "ticks": 66, "ease": "inOut"}
  //   {"at": 495, "do": "intensity", "target": "cordonLensL", "value": 100,
  //    "ticks": 4}
  //   {"at": 545, "do": "hint", "header": "TEK-Q6", "text": "...",
  //    "textEn": "..."}
  //   {"at": 0, "do": "hold", "target": "cordonPrey"}
  //   {"at": 693, "do": "kill", "target": "cordonPrey"}
  // "value" is a percentage; "ticks" 0 by default - at once; "ease" one
  // of "linear" (by default), "in", "out", "inOut". "on" is "hero", a
  // monster's tag or, for a track alone, "none". A hint takes a "header"
  // and a "text" (localized, "headerEn", "textEn") and "place" - "top"
  // by default, or "bottom".
  TSceneCue = record
    At: Integer; // ticks from the start of the scene
    Kind: TSceneCueKind;
    Target: string;
    Part: string;
    Mark: TSceneMark;
    MarkTag: string; // smMonster
    FileName: string;
    Level: Single; // 0..1
    MovesX, MovesY: Boolean;
    X, Y: Single;
    Ticks: Integer;
    Ease: TMotionEase;
    Header: TLocalizedText;
    Text: TLocalizedText;
    AtBottom: Boolean;
  end;

  // One scene in level JSON:
  //   {"id": "cordon9", "screen": 9, "once": "level", "cues": [...]}
  // "once" is "level" by default.
  TLevelScene = record
    Id: string;
    Screen: Integer; // 1-based, as the level counts
    Once: TSceneOnce;
    Cues: TArray<TSceneCue>; // by their tick, the file's order among equals
    // The tick by which the last cue is done
    function EndTick: Integer;
  end;

const
  SceneOnceIds: array [TSceneOnce] of string = ('level', 'life');
  SceneCueIds: array [TSceneCueKind] of string = ('sound', 'music', 'shade',
    'shake', 'move', 'track', 'aim', 'intensity', 'hint', 'hold', 'kill');
  // The words of "on" that are not a tag
  SceneMarkHero = 'hero';
  SceneMarkNothing = 'none';

// Reads the "scenes" array of a level; an absent section is an empty
// list. ALevelId names the level in errors.
function ParseLevelScenes(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TLevelScene>;

implementation

resourcestring
  SSceneNoId = 'Level "%s": scene #%d has no id';
  SSceneTwice = 'Level "%s": two scenes are called "%s"';
  SSceneBadWord = 'Level "%s": scene "%s": unknown %s "%s"';
  SSceneNoCues = 'Level "%s": scene "%s" has no cues';
  SSceneBadTick = 'Level "%s": scene "%s": cue #%d takes "at" and "ticks" '
    + 'from 0 up';
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

const
  // Where a hint's box stands, by AtBottom
  HintPlaceIds: array [Boolean] of string = ('top', 'bottom');

function TLevelScene.EndTick: Integer;
begin
  Result := 0;
  for var Cue in Cues do
    if Cue.At + Cue.Ticks > Result then
      Result := Cue.At + Cue.Ticks;
end;

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

procedure ReadMove(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  var ACue: TSceneCue);
var
  Value: Double;
begin
  ACue.MovesX := AObj.TryGetValue<Double>('x', Value);
  if ACue.MovesX then
    ACue.X := Value;
  ACue.MovesY := AObj.TryGetValue<Double>('y', Value);
  if ACue.MovesY then
    ACue.Y := Value;
  if not (ACue.MovesX or ACue.MovesY) then
    raise ELevelSceneError.CreateFmt(SSceneMoveNowhere, [ALevelId, ASceneId]);
  ReadEase(AObj, ALevelId, ASceneId, ACue);
end;

procedure ReadMark(const AObj: TJSONObject; const ALevelId,
  ASceneId: string; ANumber: Integer; var ACue: TSceneCue);
begin
  var Mark := AObj.GetValue<string>('on', '');
  if Mark = '' then
    raise ELevelSceneError.CreateFmt(SSceneNoMark,
      [ALevelId, ASceneId, ANumber]);
  if SameText(Mark, SceneMarkHero) then
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

function ReadCue(const AObj: TJSONObject; const ALevelId, ASceneId: string;
  ANumber: Integer): TSceneCue;
begin
  Result := Default(TSceneCue);
  Result.Kind := TSceneCueKind(WordOf(AObj.GetValue<string>('do', ''),
    SceneCueIds, ALevelId, ASceneId, 'cue'));
  Result.At := AObj.GetValue<Integer>('at', -1);
  Result.Ticks := AObj.GetValue<Integer>('ticks', 0);
  if (Result.At < 0) or (Result.Ticks < 0) then
    raise ELevelSceneError.CreateFmt(SSceneBadTick,
      [ALevelId, ASceneId, ANumber]);
  if Result.Kind in [ckMove, ckTrack, ckAim, ckIntensity, ckHold, ckKill] then
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
  end;
end;

// By their tick; cues on one tick keep the order of the file, so a later
// one may override an earlier one
procedure SortByTick(var ACues: TArray<TSceneCue>);
begin
  for var i := 1 to High(ACues) do
  begin
    var Moving := ACues[i];
    var j := i - 1;
    while (j >= 0) and (ACues[j].At > Moving.At) do
    begin
      ACues[j + 1] := ACues[j];
      Dec(j);
    end;
    ACues[j + 1] := Moving;
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
  SetLength(Result.Cues, CuesArr.Count);
  for var i := 0 to CuesArr.Count - 1 do
    Result.Cues[i] := ReadCue(CuesArr.Items[i] as TJSONObject, ALevelId,
      Result.Id, i + 1);
  SortByTick(Result.Cues);
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
