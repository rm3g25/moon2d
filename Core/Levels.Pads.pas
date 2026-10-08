{
  Levels.Pads - the pads section of level JSON: platforms apart from the
  collision grid. Model and parser, no game logic - the game runs them
  in Pads.World.

  A pad holds from above only. Its deck, the top edge, carries what lands
  on it; from below and from the side anything passes through. Under the
  deck the pad has a body one cell deep: it stops the boss's flight, the
  sparks and the debris, and the bullets unless the pad lets them by.

  A pad may travel a path - back and forth along its points, or round
  them - and may bob in the air. The path moves the pad itself; the bob
  is for the eye alone (Pads.World says why).

  Pads of a group are rebuilt together: they fly off to a new formation
  inside the group's zone, a cell each. The section padGroups names the
  groups; a pad joins one by its group. It may stand outside the zone in
  the level file: the first rebuild flies it in. A group with a conductor - a
  monster flying its lap - is rebuilt over and over once an event says
  so, the pads setting off as the conductor flies past.

  A pad may plunge: it holds until the hero stands on it, then gives way,
  falls out of the screen and climbs back to its place (Pads.Plunge
  counts the cycle). It is a failing pad and looks it; it stands on its
  place, with no path and in no group.

  A pad may wear rigs - lamps, jets and the like, hung on it as dynamic
  objects. It only names them here; Levels.Rigs holds them and hangs
  them.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Pads;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Levels.Tint;

type
  EPadError = class(Exception);

  // What a pad's body does to a bullet: bursts it, or lets it by
  TPadBullets = (pbBlock, pbPass);

  // How a pad goes along its points: not at all, there and back, or round
  TPadRoute = (prNone, prPingPong, prLoop);

  // The top-left corner of the pad at a stop, in screen units
  TPadStop = record
    X, Y: Single;
  end;

  TPadPath = record
    Route: TPadRoute;
    // The stops after the pad's own place, in order
    Stops: TArray<TPadStop>;
    Speed: Single; // units a second, the mean over a leg
    Pause: Single; // seconds the pad stands at every stop
  end;

  // A pad that gives way under the hero: it holds for Delay seconds
  // after he stands on it, falls out of the screen, lies below for Rest
  // seconds and climbs home at Rise units a second, the mean of an
  // uneven climb
  TPadPlunge = record
    Plunges: Boolean; // False - the pad holds whatever stands on it
    Delay: Single;
    Rest: Single;
    Rise: Single;
  end;

  TPadPlacement = record
    Sprite: string; // in the level's object art, as a static object's
    Screen: Integer; // 1-based
    // The top-left corner and the width in screen units, as a static
    // object's; Y is the deck. The picture's height follows its aspect.
    X: Integer;
    Y: Integer;
    Width: Integer;
    Tint: TColorTint;
    // Names the pad for the dynamic objects hung on it; '' = none
    Tag: string;
    Bullets: TPadBullets;
    Path: TPadPath;
    Bob: Single; // how far the pad sways up and down, in units; 0 = still
    Plunge: TPadPlunge;
    // The pad group it is rebuilt with; '' = none
    Group: string;
    // The rigs it wears, by name, in the order they are hung
    Rigs: TArray<string>;
  end;

  // Cells of a screen, 0-based, the bounds included
  TPadZone = record
    Left, Top, Right, Bottom: Integer;
  end;

  // Pads rebuilt together: where they may stand and what a formation of
  // them has to give
  TPadGroup = record
    Tag: string;
    Screen: Integer; // 1-based
    Zone: TPadZone;
    // At least this many pairs side by side in a formation
    Pairs: Integer;
    // A flight this many cells long or longer is far; a rebuild flies at
    // least FarShare pads far
    FarFlight: Integer;
    FarShare: Integer;
    // The tag of the monster the rebuilds follow, '' = none; the
    // seconds between two rebuilds; the tag of the dynamic objects lit
    // to warn of one, '' = none
    Conductor: string;
    Every: Single;
    Alarm: string;
  end;

const
  PadBulletsIds: array [TPadBullets] of string = ('block', 'pass');
  PadRouteIds: array [TPadRoute] of string = ('none', 'pingpong', 'loop');

// The section; absent = no pads. A width of zero or less, a bullets word
// out of PadBulletsIds, a route other than pingpong or loop, a path
// without stops or with a speed of zero or less, a pause or a bob below
// zero, a plunge with a delay or a rest below zero or a rise of zero or
// less, a rig that is not a list of names raise.
function ParsePads(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TPadPlacement>;
// The section padGroups; absent = no groups. A zone that is not four
// numbers, pairs or farShare below zero, a farFlight below one, a
// conductor without every above zero raise.
function ParsePadGroups(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TPadGroup>;
// A pad as the errors of its rigs call it: by the tag, without one by
// the sprite - the only name it has then
function PadRigName(const APad: TPadPlacement): string;

implementation

uses
  System.Generics.Collections, Levels.Rigs;

resourcestring
  SPadBadWidth = 'Level "%s": pad "%s" is %d units wide';
  SPadBadBullets = 'Level "%s": pad "%s" takes bullets "%s" - block or pass';
  SPadBadRoute = 'Level "%s": pad "%s" takes route "%s" - pingpong or loop';
  SPadNoStops = 'Level "%s": pad "%s" has a path without stops';
  SPadBadStop = 'Level "%s": pad "%s" has a stop that is not [x, y]';
  SPadBadNumber = 'Level "%s": pad "%s" takes %s %g';
  SPadGroupBadZone = 'Level "%s": pad group "%s" has a zone that is not '
    + '[left, top, right, bottom]';
  SPadGroupBadNumber = 'Level "%s": pad group "%s" takes %s %d';
  SPadGroupBadEvery = 'Level "%s": pad group "%s" has a conductor and '
    + 'takes every %g - seconds above zero';

const
  // What a plunge takes for a number it leaves out: seconds, seconds and
  // units a second
  DefaultPlungeDelay = 0.5;
  DefaultPlungeRest = 0.5;
  DefaultPlungeRise = 64;

function ReadBullets(const AObj: TJSONObject;
  const ALevelId, ASprite: string): TPadBullets;
begin
  var Id := AObj.GetValue<string>('bullets', PadBulletsIds[pbBlock]);
  for var Bullets := Low(TPadBullets) to High(TPadBullets) do
    if SameText(Id, PadBulletsIds[Bullets]) then
      Exit(Bullets);
  raise EPadError.CreateFmt(SPadBadBullets, [ALevelId, ASprite, Id]);
end;

function ReadStop(const AValue: TJSONValue;
  const ALevelId, ASprite: string): TPadStop;
begin
  if not (AValue is TJSONArray) or (TJSONArray(AValue).Count <> 2) then
    raise EPadError.CreateFmt(SPadBadStop, [ALevelId, ASprite]);
  var Pair := TJSONArray(AValue);
  if not (Pair.Items[0] is TJSONNumber) or not (Pair.Items[1] is TJSONNumber) then
    raise EPadError.CreateFmt(SPadBadStop, [ALevelId, ASprite]);
  Result.X := TJSONNumber(Pair.Items[0]).AsDouble;
  Result.Y := TJSONNumber(Pair.Items[1]).AsDouble;
end;

// Absent = the pad stands where it is placed
function ReadPath(const AObj: TJSONObject;
  const ALevelId, ASprite: string): TPadPath;
begin
  Result := Default(TPadPath);
  var PathObj := AObj.GetValue<TJSONObject>('path', nil);
  if PathObj = nil then
    Exit;

  var Id := PathObj.GetValue<string>('route', PadRouteIds[prPingPong]);
  Result.Route := prNone;
  for var Route := prPingPong to High(TPadRoute) do
    if SameText(Id, PadRouteIds[Route]) then
      Result.Route := Route;
  if Result.Route = prNone then
    raise EPadError.CreateFmt(SPadBadRoute, [ALevelId, ASprite, Id]);

  var StopsArr := PathObj.GetValue<TJSONArray>('stops', nil);
  if (StopsArr = nil) or (StopsArr.Count = 0) then
    raise EPadError.CreateFmt(SPadNoStops, [ALevelId, ASprite]);
  for var Item in StopsArr do
    Result.Stops := Result.Stops + [ReadStop(Item, ALevelId, ASprite)];

  Result.Speed := PathObj.GetValue<Double>('speed', 0);
  if Result.Speed <= 0 then
    raise EPadError.CreateFmt(SPadBadNumber,
      [ALevelId, ASprite, 'speed', Result.Speed]);
  Result.Pause := PathObj.GetValue<Double>('pause', 0);
  if Result.Pause < 0 then
    raise EPadError.CreateFmt(SPadBadNumber,
      [ALevelId, ASprite, 'pause', Result.Pause]);
end;

// JSON: "plunge": {"delay": 0.5, "rest": 0.5, "rise": 64}; absent = the
// pad holds whatever stands on it
function ReadPlunge(const AObj: TJSONObject;
  const ALevelId, ASprite: string): TPadPlunge;
begin
  Result := Default(TPadPlunge);
  var PlungeObj := AObj.GetValue<TJSONObject>('plunge', nil);
  if PlungeObj = nil then
    Exit;

  Result.Plunges := True;
  Result.Delay := PlungeObj.GetValue<Double>('delay', DefaultPlungeDelay);
  if Result.Delay < 0 then
    raise EPadError.CreateFmt(SPadBadNumber,
      [ALevelId, ASprite, 'delay', Result.Delay]);
  Result.Rest := PlungeObj.GetValue<Double>('rest', DefaultPlungeRest);
  if Result.Rest < 0 then
    raise EPadError.CreateFmt(SPadBadNumber,
      [ALevelId, ASprite, 'rest', Result.Rest]);
  Result.Rise := PlungeObj.GetValue<Double>('rise', DefaultPlungeRise);
  if Result.Rise <= 0 then
    raise EPadError.CreateFmt(SPadBadNumber,
      [ALevelId, ASprite, 'rise', Result.Rise]);
end;

function PadRigName(const APad: TPadPlacement): string;
begin
  var Shown := APad.Sprite;
  if APad.Tag <> '' then
    Shown := APad.Tag;
  Result := Format('pad "%s"', [Shown]);
end;

function ParsePads(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TPadPlacement>;
var
  Section: TJSONArray;
begin
  Result := [];
  if not ARoot.TryGetValue<TJSONArray>('pads', Section) then
    Exit;

  for var Item in Section do
  begin
    var Obj := Item as TJSONObject;
    var Pad: TPadPlacement;
    Pad.Sprite := Obj.GetValue<string>('sprite');
    Pad.Screen := Obj.GetValue<Integer>('screen');
    Pad.X := Obj.GetValue<Integer>('x');
    Pad.Y := Obj.GetValue<Integer>('y');
    Pad.Width := Obj.GetValue<Integer>('width');
    Pad.Tint := ReadTint(Obj, Pad.Sprite);
    Pad.Tag := Obj.GetValue<string>('tag', '');
    Pad.Bullets := ReadBullets(Obj, ALevelId, Pad.Sprite);
    Pad.Path := ReadPath(Obj, ALevelId, Pad.Sprite);
    Pad.Bob := Obj.GetValue<Double>('bob', 0);
    Pad.Plunge := ReadPlunge(Obj, ALevelId, Pad.Sprite);
    Pad.Group := Obj.GetValue<string>('group', '');
    Pad.Rigs := ReadRigNames(Obj, ALevelId, PadRigName(Pad));

    if Pad.Width <= 0 then
      raise EPadError.CreateFmt(SPadBadWidth, [ALevelId, Pad.Sprite, Pad.Width]);
    if Pad.Bob < 0 then
      raise EPadError.CreateFmt(SPadBadNumber,
        [ALevelId, Pad.Sprite, 'bob', Pad.Bob]);

    Result := Result + [Pad];
  end;
end;

// JSON: "zone": [left, top, right, bottom], in cells
function ReadZone(const AObj: TJSONObject;
  const ALevelId, ATag: string): TPadZone;
begin
  var ZoneArr := AObj.GetValue<TJSONArray>('zone', nil);
  if (ZoneArr = nil) or (ZoneArr.Count <> 4) then
    raise EPadError.CreateFmt(SPadGroupBadZone, [ALevelId, ATag]);
  for var Item in ZoneArr do
    if not (Item is TJSONNumber) then
      raise EPadError.CreateFmt(SPadGroupBadZone, [ALevelId, ATag]);
  Result.Left := TJSONNumber(ZoneArr.Items[0]).AsInt;
  Result.Top := TJSONNumber(ZoneArr.Items[1]).AsInt;
  Result.Right := TJSONNumber(ZoneArr.Items[2]).AsInt;
  Result.Bottom := TJSONNumber(ZoneArr.Items[3]).AsInt;
end;

function ParsePadGroups(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TPadGroup>;
var
  Section: TJSONArray;
begin
  Result := [];
  if not ARoot.TryGetValue<TJSONArray>('padGroups', Section) then
    Exit;

  for var Item in Section do
  begin
    var Obj := Item as TJSONObject;
    var Group: TPadGroup;
    Group.Tag := Obj.GetValue<string>('tag');
    Group.Screen := Obj.GetValue<Integer>('screen');
    Group.Zone := ReadZone(Obj, ALevelId, Group.Tag);
    Group.Pairs := Obj.GetValue<Integer>('pairs', 0);
    Group.FarFlight := Obj.GetValue<Integer>('farFlight', 1);
    Group.FarShare := Obj.GetValue<Integer>('farShare', 0);
    Group.Conductor := Obj.GetValue<string>('conductor', '');
    Group.Every := Obj.GetValue<Double>('every', 0);
    Group.Alarm := Obj.GetValue<string>('alarm', '');

    if Group.Pairs < 0 then
      raise EPadError.CreateFmt(SPadGroupBadNumber,
        [ALevelId, Group.Tag, 'pairs', Group.Pairs]);
    if Group.FarFlight < 1 then
      raise EPadError.CreateFmt(SPadGroupBadNumber,
        [ALevelId, Group.Tag, 'farFlight', Group.FarFlight]);
    if Group.FarShare < 0 then
      raise EPadError.CreateFmt(SPadGroupBadNumber,
        [ALevelId, Group.Tag, 'farShare', Group.FarShare]);
    if (Group.Conductor <> '') and (Group.Every <= 0) then
      raise EPadError.CreateFmt(SPadGroupBadEvery,
        [ALevelId, Group.Tag, Group.Every]);

    Result := Result + [Group];
  end;
end;

end.
