{
  Levels.Rigs - the rigs section of level JSON: what the pads wear. A rig
  is a named list of dynamic objects (Levels.Dynamics) with no place of
  their own - a lamp, a jet, the haze under it. A pad names the rigs it
  wears (Levels.Pads), and at load every part of them becomes a dynamic
  object hung on that pad: from there on it is one of the level's
  dynamic objects, no different from one written into the dynamics
  section with the pad for its parent.

  A number of a part may be left as a spread - an object of the one key
  "spread" over a list of two ends: every pad that wears the part rolls
  its own value between the two, the same at every load. The roll goes
  by the pad's tag, the rig's name, the part's number in it and the key:
  move a part within its rig and it rolls anew. Both ends whole, the
  value is whole, either end included: a percentage stays one. A spread
  stands for a number of the part itself, not for one inside a list such
  as a tint.

  A rig no pad wears is not read at all.

  The JSON is shown at WearRigs: a brace would end this comment.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Rigs;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Levels.Pads, Levels.Dynamics;

type
  ERigError = class(Exception);

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
//   ]
//
// Hangs on every pad the parts of the rigs it wears: they join ADynamics
// in the order of the pads, then of a pad's rigs, then of a rig's parts.
// A pad that wears a rig and carries no tag, a rig the section lacks, a
// rig that is not a list of objects, a part that names a place of its
// own, a spread that is not two numbers in order raise; so does
// whatever Levels.Dynamics refuses in a part.
procedure WearRigs(ARoot: TJSONObject; const ALevelId: string;
  const APads: TArray<TPadPlacement>; ADynamics: TDynamicObjects);

implementation

uses
  System.StrUtils, System.Generics.Collections;

resourcestring
  SRigNoTag = 'Level "%s": pad "%s" wears a rig and carries no tag - its '
    + 'parts hang on it by the tag';
  SRigUnknown = 'Level "%s": pad "%s" wears the rig "%s", and the level '
    + 'has none by that name';
  SRigNotList = 'Level "%s": rig "%s" is not a list of dynamic objects';
  SRigOwnPlace = 'Level "%s": part %s names "%s" - a part stands where '
    + 'its pad does';
  SRigBadSpread = 'Level "%s": part %s takes "%s" as a spread that is not '
    + '[from, to], from no greater than to';

const
  RigsKey = 'rigs';
  SpreadKey = 'spread';
  ParentKey = 'parent';
  // What places an object of the dynamics section; a part has its pad
  PlaceKeys: array [0..2] of string = (ParentKey, 'screen', 'screens');

type
  // A part of a rig on a pad that wears it
  TFitting = record
    Tag: string; // the pad's
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

  // The fitting of one level: where the rigs are read and where their
  // parts go
  TRigFitter = record
    Section: TJSONObject; // nil - the level has no rigs
    LevelId: string;
    Dynamics: TDynamicObjects;
    function RigNamed(const AName, AWearer: string): TJSONArray;
    function WornValue(AValue: TJSONValue; const AFitting: TFitting;
      const AKey: string): TJSONValue;
    function Worn(APart: TJSONObject; const AFitting: TFitting): TJSONObject;
    procedure Hang(ARig: TJSONArray; const ARigName, ATag: string);
    procedure Dress(const APad: TPadPlacement);
  end;

function TFitting.Where: string;
begin
  Result := Format('#%d of rig "%s" on pad "%s"', [Part, Rig, Tag]);
end;

// Spelled apart from Where: reword an error there, and every lamp of the
// level would roll anew
function TFitting.RollName(const AKey: string): string;
begin
  Result := Format('%s/%s/%d/%s', [Tag, Rig, Part, AKey]);
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

function TRigFitter.RigNamed(const AName, AWearer: string): TJSONArray;
begin
  var Raw: TJSONValue := nil;
  if Section <> nil then
    Raw := Section.GetValue(AName);
  if Raw = nil then
    raise ERigError.CreateFmt(SRigUnknown, [LevelId, AWearer, AName]);
  if not (Raw is TJSONArray) then
    raise ERigError.CreateFmt(SRigNotList, [LevelId, AName]);
  Result := TJSONArray(Raw);
end;

// A copy of the part's value for the pad to keep; a spread - the pad's
// own roll within it
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
// this pad: every spread rolled, the pad for the parent. The caller
// owns the result.
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
    Result.AddPair(ParentKey, AFitting.Tag);
  except
    Result.Free;
    raise;
  end;
end;

procedure TRigFitter.Hang(ARig: TJSONArray; const ARigName, ATag: string);
var
  Fitting: TFitting;
begin
  Fitting.Tag := ATag;
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

procedure TRigFitter.Dress(const APad: TPadPlacement);
begin
  if Length(APad.Rigs) = 0 then
    Exit;
  // Without a tag a pad has no name but its sprite, as in the errors of
  // Levels.Pads
  if APad.Tag = '' then
    raise ERigError.CreateFmt(SRigNoTag, [LevelId, APad.Sprite]);
  for var RigName in APad.Rigs do
    Hang(RigNamed(RigName, APad.Tag), RigName, APad.Tag);
end;

procedure WearRigs(ARoot: TJSONObject; const ALevelId: string;
  const APads: TArray<TPadPlacement>; ADynamics: TDynamicObjects);
var
  Fitter: TRigFitter;
begin
  Fitter.Section := ARoot.GetValue<TJSONObject>(RigsKey, nil);
  Fitter.LevelId := ALevelId;
  Fitter.Dynamics := ADynamics;
  for var Pad in APads do
    Fitter.Dress(Pad);
end;

end.
