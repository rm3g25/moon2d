{
  Levels.EyePath - the way of the eye in the titles' flight: keys by the
  seconds of the flight and a monotone cubic between them, a channel at a
  time (docs/mechanics/finale-flight.md, "The file of the path"). The
  arithmetic is the stand's (tools/chase: pathTangents, pathValue,
  pathPlaces, eyeAt), number for number.

  A key places the eye along the city's strip - at a place of the strip, so
  far from where the world stood, or where it stood - and gives its lift,
  its push, its bank and its pitch. No key takes the eye to the right of
  the one before it, nor of where the world stood: after a short fight the
  world stands early, and the eye waits there for the keys that lie to its
  left.

  The cubic passes through every key and never past one, and stands still
  at its two ends (Fritsch-Carlson).

  Deliberately not here: reading the file (Levels.Titles) and what the eye
  sees (Levels.FarPlane). No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.EyePath;
{$I ..\Moon2D.inc}

interface

type
  // Where a key has the eye along the strip: where the world stood; so far
  // from there, below 0 to the left; at a place of the strip
  TEyePlacing = (epStand, epFromStand, epAlong);

  TEyeKey = record
    // Of the flight
    Seconds: Double;
    Placing: TEyePlacing;
    // epFromStand - units from where the world stood; epAlong - the place
    // of the strip; epStand - not read
    Place: Double;
    // From the eye's rest, the camera's units: up, into the screen
    Lift, Push: Double;
    // Degrees: the left wing down, the nose up
    Bank, Pitch: Double;
  end;

  // The eye at a moment. Along - the place of the city's strip that stands
  // in the middle of the screen at the domes' base line
  TEye = record
    Along: Double;
    Lift, Push: Double;
    Bank, Pitch: Double;
  end;

  TEyePath = record
    // Their seconds ascending; fewer than two - no path
    Keys: TArray<TEyeKey>;
    function Present: Boolean;
    // The eye at ASeconds of the flight. AStand - the place of the strip
    // that stood in the middle of the screen when the world stood
    function EyeAt(ASeconds, AStand: Double): TEye;
    // Till this second of the flight the eye keeps its rest: it goes along
    // the strip and nowhere else
    function RestTill: Double;
    // Degrees, either way
    function SteepestBank: Double;
  end;

implementation

// The tangents of the cubic through the keys: none at the two ends, none
// at a key where the slopes either side differ in sign or one is level
function Tangents(const ATimes, AValues: TArray<Double>): TArray<Double>;
var
  Slopes: TArray<Double>;
begin
  var Count := Length(ATimes);
  Result := nil;
  SetLength(Result, Count);
  SetLength(Slopes, Count - 1);
  for var i := 0 to Count - 2 do
    Slopes[i] := (AValues[i + 1] - AValues[i]) / (ATimes[i + 1] - ATimes[i]);

  for var i := 1 to Count - 2 do
  begin
    if Slopes[i - 1] * Slopes[i] <= 0 then
      Continue;
    var Before: Double := ATimes[i] - ATimes[i - 1];
    var After: Double := ATimes[i + 1] - ATimes[i];
    var BeforeWeight: Double := 2 * After + Before;
    var AfterWeight: Double := After + 2 * Before;
    Result[i] := (BeforeWeight + AfterWeight) /
      (BeforeWeight / Slopes[i - 1] + AfterWeight / Slopes[i]);
  end;
end;

// The cubic through the keys at ATime; it stands at its first key before
// it and at its last after it
function CubicAt(const ATimes, AValues: TArray<Double>; ATime: Double): Double;
begin
  var Last := High(ATimes);
  if ATime <= ATimes[0] then
    Exit(AValues[0]);
  if ATime >= ATimes[Last] then
    Exit(AValues[Last]);

  var Slants := Tangents(ATimes, AValues);
  var From := 0;
  while ATimes[From + 1] < ATime do
    Inc(From);
  var Span: Double := ATimes[From + 1] - ATimes[From];
  var Share: Double := (ATime - ATimes[From]) / Span;
  var Square: Double := Share * Share;
  var Cube: Double := Square * Share;
  Result := (2 * Cube - 3 * Square + 1) * AValues[From] +
    (Cube - 2 * Square + Share) * Span * Slants[From] +
    (3 * Square - 2 * Cube) * AValues[From + 1] +
    (Cube - Square) * Span * Slants[From + 1];
end;

function PlaceOf(const AKey: TEyeKey; AStand: Double): Double;
begin
  case AKey.Placing of
    epFromStand:
      Result := AStand + AKey.Place;
    epAlong:
      Result := AKey.Place;
  else
    Result := AStand;
  end;
end;

// The places of the keys along the strip: none to the right of the one
// before it, nor of where the world stood
function PlacesAlong(const AKeys: TArray<TEyeKey>; AStand: Double): TArray<Double>;
begin
  Result := nil;
  SetLength(Result, Length(AKeys));
  var Leftmost := AStand;
  for var i := 0 to High(AKeys) do
  begin
    var Place := PlaceOf(AKeys[i], AStand);
    if Place < Leftmost then
      Leftmost := Place;
    Result[i] := Leftmost;
  end;
end;

function TEyePath.Present: Boolean;
begin
  Result := Length(Keys) >= 2;
end;

function TEyePath.EyeAt(ASeconds, AStand: Double): TEye;
var
  Times, Lifts, Pushes, Banks, Pitches: TArray<Double>;
begin
  Result := Default(TEye);
  Result.Along := AStand;
  if not Present then
    Exit;

  var Count := Length(Keys);
  SetLength(Times, Count);
  SetLength(Lifts, Count);
  SetLength(Pushes, Count);
  SetLength(Banks, Count);
  SetLength(Pitches, Count);
  for var i := 0 to Count - 1 do
  begin
    Times[i] := Keys[i].Seconds;
    Lifts[i] := Keys[i].Lift;
    Pushes[i] := Keys[i].Push;
    Banks[i] := Keys[i].Bank;
    Pitches[i] := Keys[i].Pitch;
  end;

  Result.Along := CubicAt(Times, PlacesAlong(Keys, AStand), ASeconds);
  Result.Lift := CubicAt(Times, Lifts, ASeconds);
  Result.Push := CubicAt(Times, Pushes, ASeconds);
  Result.Bank := CubicAt(Times, Banks, ASeconds);
  Result.Pitch := CubicAt(Times, Pitches, ASeconds);
end;

// A key at rest after keys at rest has a level tangent, so up to it the
// cubic never leaves the rest
function TEyePath.RestTill: Double;
begin
  Result := 0;
  for var Key in Keys do
  begin
    var AtRest := (Key.Lift = 0) and (Key.Push = 0) and (Key.Bank = 0) and
      (Key.Pitch = 0);
    if not AtRest then
      Exit;
    Result := Key.Seconds;
  end;
end;

function TEyePath.SteepestBank: Double;
begin
  Result := 0;
  for var Key in Keys do
    if Abs(Key.Bank) > Result then
      Result := Abs(Key.Bank);
end;

end.
