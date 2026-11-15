{
  Levels.Titles - the titles that close a level, as data: the cues of its
  end track and the way of the camera's flight
  (docs/mechanics/finale-flight.md, "The timeline", "The file of the
  path"). A level names the file in its "titles" section ("file"); the file
  lies beside the level file (bin/finale.json for level 2) and is the one
  tools/chase/build_stand.py plays on the stand. Titles without a path do
  not fly: the card and the logo are all of them. A path may say how far
  it is flown ("flownTill", a second of the flight) while the game does not
  fly all of it; with none it is flown to its last key. Titles that fly
  read the flight's own cues too - the sign's stutter and the sun's flare.
  Titles that fly may end at the stars: their cues for the sky, the
  phrases, the credits and the last screen go together; without them the
  last screen comes as the path is flown. The track's length, where the
  file gives it, is where the titles end. The sections of the track are
  let be.

  No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Titles;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Levels.EyePath;

type
  ETitlesError = class(Exception);

  // Seconds of the end track, which starts with the titles' clock. Card -
  // the studio's card comes in, gone by CardOut; Flash - the logo flares;
  // Flight - the camera leaves; Neon - the TEK sign stutters as the eye
  // goes by; Flare - the sun comes out of the dome's glass. The last three
  // are read for titles that fly. At the stars: Stars - the sky comes out of
  // the black, standing high; Still - it is at its rest; Mission and
  // Promise - the two phrases come in; Credits - they are gone, the lines of
  // the credits come; Last - the last screen. Zero - titles that do not end
  // at the stars; for those that fly Last is where the path is flown
  TTitlesCues = record
    Card, CardOut: Double;
    Flash: Double;
    Flight: Double;
    Neon, Flare: Double;
    Stars, Still: Double;
    Mission, Promise: Double;
    Credits: Double;
    Last: Double;
  end;

  TTitlesDef = record
    Present: Boolean;
    Cues: TTitlesCues;
    // The way of the camera's flight, by the seconds from the cue Flight
    Path: TEyePath;
    // The second of the flight the path is flown to: its last key's, or
    // the path's "flownTill" while the game does not fly all of it
    FlightTill: Double;
    // The track's length, where the titles end; 0 - not given
    TrackSeconds: Double;
    function Flies: Boolean;
    // Flies and comes to the stars of the menu after the flight
    function EndsAtTheStars: Boolean;
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
  STitlesShortPath = 'Level "%s": the path of its titles needs two keys at the '
    + 'least';
  STitlesKeyOutOfOrder = 'Level "%s": key %d of the path of its titles is not '
    + 'after the one before it';
  STitlesFlownNowhere = 'Level "%s": the path of its titles is flown till %g s - '
    + 'a second of the flight above zero';
  STitlesStarsWithoutFlight = 'Level "%s": its titles come to the stars, but do not fly';
  STitlesTrackTooShort = 'Level "%s": the track of its titles ends before their '
    + 'last screen';

function TTitlesDef.Flies: Boolean;
begin
  Result := Present and Path.Present;
end;

function TTitlesDef.EndsAtTheStars: Boolean;
begin
  Result := Flies and (Cues.Stars > 0);
end;

function ReadCues(const AObj: TJSONObject): TTitlesCues;
begin
  Result.Card := AObj.GetValue<Double>('card');
  Result.CardOut := AObj.GetValue<Double>('cardOut');
  Result.Flash := AObj.GetValue<Double>('flash');
  Result.Flight := AObj.GetValue<Double>('flight', 0);
  Result.Neon := AObj.GetValue<Double>('neon', 0);
  Result.Flare := AObj.GetValue<Double>('flare', 0);
  Result.Stars := AObj.GetValue<Double>('stars', 0);
  Result.Still := AObj.GetValue<Double>('still', 0);
  Result.Mission := AObj.GetValue<Double>('mission', 0);
  Result.Promise := AObj.GetValue<Double>('promise', 0);
  Result.Credits := AObj.GetValue<Double>('credits', 0);
  Result.Last := AObj.GetValue<Double>('last', 0);
end;

// "dx" places the key from where the world stood, "x" along the strip; a
// key with neither, or with an "x" of null, stands where the world stood
function ReadKey(const AObj: TJSONObject): TEyeKey;
begin
  Result := Default(TEyeKey);
  Result.Seconds := AObj.GetValue<Double>('t');
  Result.Lift := AObj.GetValue<Double>('y', 0);
  Result.Push := AObj.GetValue<Double>('z', 0);
  Result.Bank := AObj.GetValue<Double>('bank', 0);
  Result.Pitch := AObj.GetValue<Double>('pitch', 0);

  var FromStand := AObj.GetValue('dx');
  var Along := AObj.GetValue('x');
  if FromStand is TJSONNumber then
  begin
    Result.Placing := epFromStand;
    Result.Place := TJSONNumber(FromStand).AsDouble;
  end
  else if Along is TJSONNumber then
  begin
    Result.Placing := epAlong;
    Result.Place := TJSONNumber(Along).AsDouble;
  end;
end;

function ReadPath(const AObj: TJSONObject): TEyePath;
begin
  Result := Default(TEyePath);
  for var Item in AObj.GetValue<TJSONArray>('keys') do
    Result.Keys := Result.Keys + [ReadKey(Item as TJSONObject)];
end;

// The cubic between two keys divides by the time between them
procedure CheckPath(const APath: TEyePath; const ALevelId: string);
begin
  if Length(APath.Keys) < 2 then
    raise ETitlesError.CreateFmt(STitlesShortPath, [ALevelId]);
  for var i := 1 to High(APath.Keys) do
    if APath.Keys[i].Seconds <= APath.Keys[i - 1].Seconds then
      raise ETitlesError.CreateFmt(STitlesKeyOutOfOrder, [ALevelId, i + 1]);
end;

// The card is gone before the logo flares where it stood, the camera
// leaves a logo that has flared, and the sign and the sun come in the
// flight, in that order
procedure CheckOrder(const ADef: TTitlesDef; const ALevelId: string);
begin
  var Cues := ADef.Cues;
  if Cues.CardOut <= Cues.Card then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'cardOut']);
  if Cues.Flash <= Cues.CardOut then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'flash']);
  if not ADef.Path.Present then
    Exit;
  if Cues.Flight <= Cues.Flash then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'flight']);
  if Cues.Neon <= Cues.Flight then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'neon']);
  if Cues.Flare <= Cues.Neon then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'flare']);
end;

// The sky comes after the sun, and stands still after it comes; the
// phrases come once the sky is out, the credits after them, the last
// screen after the credits, and the track lasts to it
procedure CheckTheStars(const ADef: TTitlesDef; const ALevelId: string);
begin
  var Cues := ADef.Cues;
  if not ADef.Path.Present then
    raise ETitlesError.CreateFmt(STitlesStarsWithoutFlight, [ALevelId]);
  if Cues.Stars <= Cues.Flare then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'stars']);
  if Cues.Still <= Cues.Stars then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'still']);
  if Cues.Mission <= Cues.Stars then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'mission']);
  if Cues.Promise <= Cues.Mission then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'promise']);
  if Cues.Credits <= Cues.Promise then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'credits']);
  if Cues.Last <= Cues.Credits then
    raise ETitlesError.CreateFmt(STitlesCueOutOfOrder, [ALevelId, 'last']);
  if (ADef.TrackSeconds > 0) and (ADef.TrackSeconds <= Cues.Last) then
    raise ETitlesError.CreateFmt(STitlesTrackTooShort, [ALevelId]);
end;

function ReadTrackSeconds(const ARoot: TJSONObject): Double;
var
  Track: TJSONObject;
begin
  Result := 0;
  if ARoot.TryGetValue<TJSONObject>('track', Track) then
    Result := Track.GetValue<Double>('seconds', 0);
end;

// No "path" - titles that do not fly
function ReadTitlesFile(const AFileName, ALevelId: string): TTitlesDef;
var
  PathObj: TJSONObject;
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
    if Root.TryGetValue<TJSONObject>('path', PathObj) then
    begin
      Result.Path := ReadPath(PathObj);
      CheckPath(Result.Path, ALevelId);
      var LastKey := Result.Path.Keys[High(Result.Path.Keys)].Seconds;
      Result.FlightTill := PathObj.GetValue<Double>('flownTill', LastKey);
      if Result.FlightTill <= 0 then
        raise ETitlesError.CreateFmt(STitlesFlownNowhere, [ALevelId, Result.FlightTill]);
    end;
    CheckOrder(Result, ALevelId);
    Result.TrackSeconds := ReadTrackSeconds(Root);
    if Result.Cues.Stars > 0 then
      CheckTheStars(Result, ALevelId)
    else if Result.Path.Present then
      Result.Cues.Last := Result.Cues.Flight + Result.FlightTill;
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
