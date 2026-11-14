{
  Levels.Titles - the titles that close a level, as data: the cues of its
  end track (docs/mechanics/finale-flight.md, "The timeline"). A level
  names the file in its "titles" section ("file"); the file lies beside the
  level file (bin/finale.json for level 2) and is the one
  tools/chase/build_stand.py plays on the stand. The keys the game does not
  play yet - the flight's cues, the path of its camera, the lines at the
  stars - are let be.

  No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Titles;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON;

type
  ETitlesError = class(Exception);

  // Seconds of the end track, which starts with the titles' clock. Card -
  // the studio's card comes in, gone by CardOut; Flash - the logo flares
  TTitlesCues = record
    Card, CardOut: Double;
    Flash: Double;
  end;

  TTitlesDef = record
    Present: Boolean;
    Cues: TTitlesCues;
  end;

// The titles of the level ARoot: its "titles" section names the file,
// which lies in ALevelDir. No section - no titles
function ReadTitles(const ARoot: TJSONObject;
  const ALevelId, ALevelDir: string): TTitlesDef;

implementation

uses
  System.IOUtils;

resourcestring
  STitlesNoFile = 'Level "%s": the file of its titles "%s" is missing';
  STitlesBadFile = 'Level "%s": the file of its titles "%s" does not read';
  STitlesCueOutOfOrder = 'Level "%s": the cue "%s" of its titles is not after the '
    + 'one before it';

function ReadCues(const AObj: TJSONObject): TTitlesCues;
begin
  Result.Card := AObj.GetValue<Double>('card');
  Result.CardOut := AObj.GetValue<Double>('cardOut');
  Result.Flash := AObj.GetValue<Double>('flash');
end;

// The card is gone before the logo flares where it stood
procedure CheckOrder(const ACues: TTitlesCues; const ALevelId: string);
begin
  if ACues.CardOut <= ACues.Card then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'cardOut']);
  if ACues.Flash <= ACues.CardOut then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'flash']);
end;

function ReadTitlesFile(const AFileName, ALevelId: string): TTitlesDef;
begin
  Result := Default(TTitlesDef);
  if not FileExists(AFileName) then
    raise ETitlesError.CreateFmt(STitlesNoFile, [ALevelId, AFileName]);
  var Root := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8)) as TJSONObject;
  if Root = nil then
    raise ETitlesError.CreateFmt(STitlesBadFile, [ALevelId, AFileName]);
  try
    Result.Cues := ReadCues(Root.GetValue<TJSONObject>('cues'));
    CheckOrder(Result.Cues, ALevelId);
    Result.Present := True;
  finally
    Root.Free;
  end;
end;

function ReadTitles(const ARoot: TJSONObject;
  const ALevelId, ALevelDir: string): TTitlesDef;
var
  Section: TJSONObject;
begin
  Result := Default(TTitlesDef);
  if not ARoot.TryGetValue<TJSONObject>('titles', Section) then
    Exit;
  Result := ReadTitlesFile(
    TPath.Combine(ALevelDir, Section.GetValue<string>('file')), ALevelId);
end;

end.
