{
  Levels.Rigs - the rigs section of level JSON: what the pads and the
  monsters wear. A rig is a named list of dynamic objects
  (Levels.Dynamics) with no place of their own - a lamp, a jet, the haze
  under it. A wearer - a pad (Levels.Pads) or a monster's placement
  (Levels.Defs) - names the rigs it wears, and at load every part of
  them becomes a dynamic object hung on that wearer: from there on it is
  one of the level's dynamic objects, no different from one written into
  the dynamics section with the wearer for its parent.

  A number of a part may be left as a spread - an object of the one key
  "spread" over a list of two ends: every wearer of the part rolls its
  own value between the two, the same at every load. The roll goes by
  the wearer's tag, the rig's name, the part's number in it and the key:
  move a part within its rig and it rolls anew. Both ends whole, the
  value is whole, either end included: a percentage stays one. A spread
  stands for a number of the part itself, not for one inside a list such
  as a tint.

  A rig nobody wears is not read at all.

  The JSON is shown at WearRigs: a brace would end this comment.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Rigs;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Levels.Dynamics;

type
  ERigError = class(Exception);

  // Who wears rigs: a pad, a monster's placement
  TRigWearer = record
    // Its parts hang on it by the tag; without one it may wear nothing
    Tag: string;
    // As the errors call it: pad "s16-plat-01"
    Name: string;
    // By name, in the order they are hung
    Rigs: TArray<string>;
  end;

// JSON: "rig": ["pad", "arenaAlarm"] on a wearer; absent = it wears
// nothing. AWearer names it in the error, as TRigWearer.Name does: a rig
// that is not a list of names raises.
function ReadRigNames(AObj: TJSONObject;
  const ALevelId, AWearer: string): TArray<string>;

// JSON:
//   "rigs": {
//     "pad": [
//       {"kind": "beacon", "x": 16, "y": 25, "blink": "pulse",
//        "frequency": {"spread": [0.27, 0.45]}},
//       {"kind": "haze", "x": 16, "y": 27, "angle": 270}
//     ]
//   },
//   "pads": [
//     {"sprite": "s16-platform", "tag": "s16-plat-01", "rig": ["pad"]}
//   ],
//   "entities": [
//     {"monsterId": "platform", "tag": "s07-tek-01", "rig": ["pad"]}
//   ]
//
// Hangs on every wearer the parts of the rigs it wears: they join
// ADynamics in the order of the wearers, then of a wearer's rigs, then
// of a rig's parts. A wearer of a rig that carries no tag, two wearers
// of rigs under one tag, a rig the section lacks, a rig that is not a
// list of objects, a part that names a place of its own, a spread that
// is not two numbers in order raise; so does whatever Levels.Dynamics
// refuses in a part.
procedure WearRigs(ARoot: TJSONObject; const ALevelId: string;
  const AWearers: TArray<TRigWearer>; ADynamics: TDynamicObjects);

implementation

uses
  System.StrUtils, System.Generics.Collections;

resourcestring
  SRigBadNames = 'Level "%s": %s has a rig that is not a list of rig names';
  SRigNoTag = 'Level "%s": %s wears a rig and carries no tag - its '
    + 'parts hang on it by the tag';
  SRigSharedTag = 'Level "%s": %s wears a rig, and so does another under '
    + 'its tag - the parts of both would hang on one';
  SRigUnknown = 'Level "%s": %s wears the rig "%s", and the level '
    + 'has none by that name';
  SRigNotList = 'Level "%s": rig "%s" is not a list of dynamic objects';
  SRigOwnPlace = 'Level "%s": part %s names "%s" - a part stands where '
    + 'its wearer does';
  SRigBadSpread = 'Level "%s": part %s takes "%s" as a spread that is not '
    + '[from, to], from no greater than to';

const
  RigsKey = 'rigs';
  SpreadKey = 'spread';
  ParentKey = 'parent';
  // What places an object of the dynamics section; a part has its wearer
  PlaceKeys: array [0..2] of string = (ParentKey, 'screen', 'screens');

type
  // A part of a rig on one that wears it
  TFitting = record
    Wearer: TRigWearer;
    Rig: string;
    Part: Integer; // 1-based, as the errors count
    // Names the part in errors, after its kind: "beacon #2 of rig ..."
    function Where: string;
    // Names the roll of the part's number AKey
    function RollName(const AKey: string): string;
  end;

  TSpreadEnds = record
    Least, Most: Double;
  end;

  // The fitting of one level: who wears, where the rigs are read and
  // where their parts go
  TRigFitter = record
    Wearers: TArray<TRigWearer>;
    Section: TJSONObject; // nil - the level has no rigs
    LevelId: string;
    Dynamics: TDynamicObjects;
    function RigNamed(const AName, AWearerName: string): TJSONArray;
    function WornValue(AValue: TJSONValue; const AFitting: TFitting;
      const AKey: string): TJSONValue;
    function Worn(APart: TJSONObject; const AFitting: TFitting): TJSONObject;
    procedure Hang(ARig: TJSONArray; const ARigName: string;
      const AWearer: TRigWearer);
    function SharesTag(const AWearer: TRigWearer): Boolean;
    procedure Dress(const AWearer: TRigWearer);
  end;

function ReadRigNames(AObj: TJSONObject;
  const ALevelId, AWearer: string): TArray<string>;
begin
  Result := [];
  var Raw := AObj.GetValue('rig');
  if Raw = nil then
    Exit;
  if not (Raw is TJSONArray) then
    raise ERigError.CreateFmt(SRigBadNames, [ALevelId, AWearer]);
  for var Item in TJSONArray(Raw) do
  begin
    // System.JSON holds a number as a string of a kind
    var IsName := (Item is TJSONString) and not (Item is TJSONNumber);
    if not IsName then
      raise ERigError.CreateFmt(SRigBadNames, [ALevelId, AWearer]);
    Result := Result + [Item.Value];
  end;
end;

function TFitting.Where: string;
begin
  Result := Format('#%d of rig "%s" on %s', [Part, Rig, Wearer.Name]);
end;

// Spelled apart from Where: reword an error there, and every lamp of the
// level would roll anew
function TFitting.RollName(const AKey: string): string;
begin
  Result := Format('%s/%s/%d/%s', [Wearer.Tag, Rig, Part, AKey]);
end;

function IsSpread(AValue: TJSONValue): Boolean;
begin
  Result := (AValue is TJSONObject) and
    (TJSONObject(AValue).GetValue(SpreadKey) <> nil);
end;

// {"spread": [from, to]} and nothing beside it, from no greater than to
function TryReadSpread(ASpread: TJSONObject; out AEnds: TSpreadEnds): Boolean;
begin
  AEnds := Default(TSpreadEnds);
  var Raw := ASpread.GetValue(SpreadKey);
  if ASpread.Count <> 1 then
    Exit(False);
  if not (Raw is TJSONArray) then
    Exit(False);
  var Ends := TJSONArray(Raw);
  if Ends.Count <> 2 then
    Exit(False);
  var BothNumbers := (Ends.Items[0] is TJSONNumber) and
    (Ends.Items[1] is TJSONNumber);
  if not BothNumbers then
    Exit(False);
  AEnds.Least := TJSONNumber(Ends.Items[0]).AsDouble;
  AEnds.Most := TJSONNumber(Ends.Items[1]).AsDouble;
  Result := AEnds.Least <= AEnds.Most;
end;

// The number ARoll - 0..1, the 1 left out - picks between the ends.
// Whole ends give a whole number, either end as likely as any between.
function RolledNumber(const AEnds: TSpreadEnds; ARoll: Single): TJSONNumber;
begin
  var Whole := (Frac(AEnds.Least) = 0) and (Frac(AEnds.Most) = 0);
  if not Whole then
  begin
    var Value: Double := AEnds.Least + ARoll * (AEnds.Most - AEnds.Least);
    // Spelled with a point whatever the locale of the machine: with a
    // comma it would not read back as a number
    Exit(TJSONNumber.Create(FloatToStr(Value, TFormatSettings.Invariant)));
  end;
  var Choices: Int64 := Trunc(AEnds.Most) - Trunc(AEnds.Least) + 1;
  var Chosen: Int64 := Trunc(AEnds.Least) + Trunc(ARoll * Choices);
  Result := TJSONNumber.Create(Chosen);
end;

function TRigFitter.RigNamed(const AName, AWearerName: string): TJSONArray;
begin
  var Raw: TJSONValue := nil;
  if Section <> nil then
    Raw := Section.GetValue(AName);
  if Raw = nil then
    raise ERigError.CreateFmt(SRigUnknown, [LevelId, AWearerName, AName]);
  if not (Raw is TJSONArray) then
    raise ERigError.CreateFmt(SRigNotList, [LevelId, AName]);
  Result := TJSONArray(Raw);
end;

// A copy of the part's value for the wearer to keep; a spread - the
// wearer's own roll within it
function TRigFitter.WornValue(AValue: TJSONValue; const AFitting: TFitting;
  const AKey: string): TJSONValue;
var
  Ends: TSpreadEnds;
begin
  if not IsSpread(AValue) then
    Exit(AValue.Clone as TJSONValue);
  if not TryReadSpread(TJSONObject(AValue), Ends) then
    raise ERigError.CreateFmt(SRigBadSpread,
      [LevelId, AFitting.Where, AKey]);
  Result := RolledNumber(Ends, NameRoll(AFitting.RollName(AKey)));
end;

// The part as an object of the dynamics section would be written for
// this wearer: every spread rolled, the wearer for the parent. The
// caller owns the result.
function TRigFitter.Worn(APart: TJSONObject;
  const AFitting: TFitting): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    for var Pair in APart do
    begin
      var Key := Pair.JsonString.Value;
      if MatchStr(Key, PlaceKeys) then
        raise ERigError.CreateFmt(SRigOwnPlace,
          [LevelId, AFitting.Where, Key]);
      Result.AddPair(Key, WornValue(Pair.JsonValue, AFitting, Key));
    end;
    Result.AddPair(ParentKey, AFitting.Wearer.Tag);
  except
    Result.Free;
    raise;
  end;
end;

procedure TRigFitter.Hang(ARig: TJSONArray; const ARigName: string;
  const AWearer: TRigWearer);
var
  Fitting: TFitting;
begin
  Fitting.Wearer := AWearer;
  Fitting.Rig := ARigName;
  for var i := 0 to ARig.Count - 1 do
  begin
    if not (ARig.Items[i] is TJSONObject) then
      raise ERigError.CreateFmt(SRigNotList, [LevelId, ARigName]);
    Fitting.Part := i + 1;
    var WornPart := Worn(TJSONObject(ARig.Items[i]), Fitting);
    try
      Dynamics.Add(ParseDynamic(WornPart, LevelId, Fitting.Where));
    finally
      WornPart.Free;
    end;
  end;
end;

// Another wearer of rigs carries AWearer's tag: placements of one
// monster on two difficulties do. A part finds its parent by the tag
// alone, so the one that lives would carry the parts of both.
function TRigFitter.SharesTag(const AWearer: TRigWearer): Boolean;
begin
  var Dressed := 0;
  for var Other in Wearers do
    if (Other.Tag = AWearer.Tag) and (Length(Other.Rigs) > 0) then
      Inc(Dressed);
  Result := Dressed > 1;
end;

procedure TRigFitter.Dress(const AWearer: TRigWearer);
begin
  if Length(AWearer.Rigs) = 0 then
    Exit;
  if AWearer.Tag = '' then
    raise ERigError.CreateFmt(SRigNoTag, [LevelId, AWearer.Name]);
  if SharesTag(AWearer) then
    raise ERigError.CreateFmt(SRigSharedTag, [LevelId, AWearer.Name]);
  for var RigName in AWearer.Rigs do
    Hang(RigNamed(RigName, AWearer.Name), RigName, AWearer);
end;

procedure WearRigs(ARoot: TJSONObject; const ALevelId: string;
  const AWearers: TArray<TRigWearer>; ADynamics: TDynamicObjects);
var
  Fitter: TRigFitter;
begin
  Fitter.Wearers := AWearers;
  Fitter.Section := ARoot.GetValue<TJSONObject>(RigsKey, nil);
  Fitter.LevelId := ALevelId;
  Fitter.Dynamics := ADynamics;
  for var Wearer in AWearers do
    Fitter.Dress(Wearer);
end;

end.
