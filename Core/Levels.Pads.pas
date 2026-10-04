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
  end;

const
  PadBulletsIds: array [TPadBullets] of string = ('block', 'pass');
  PadRouteIds: array [TPadRoute] of string = ('none', 'pingpong', 'loop');

// The section; absent = no pads. A width of zero or less, a bullets word
// out of PadBulletsIds, a route other than pingpong or loop, a path
// without stops or with a speed of zero or less, a pause or a bob below
// zero raise.
function ParsePads(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TPadPlacement>;

implementation

resourcestring
  SPadBadWidth = 'Level "%s": pad "%s" is %d units wide';
  SPadBadBullets = 'Level "%s": pad "%s" takes bullets "%s" - block or pass';
  SPadBadRoute = 'Level "%s": pad "%s" takes route "%s" - pingpong or loop';
  SPadNoStops = 'Level "%s": pad "%s" has a path without stops';
  SPadBadStop = 'Level "%s": pad "%s" has a stop that is not [x, y]';
  SPadBadNumber = 'Level "%s": pad "%s" takes %s %g';

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

    if Pad.Width <= 0 then
      raise EPadError.CreateFmt(SPadBadWidth, [ALevelId, Pad.Sprite, Pad.Width]);
    if Pad.Bob < 0 then
      raise EPadError.CreateFmt(SPadBadNumber,
        [ALevelId, Pad.Sprite, 'bob', Pad.Bob]);

    Result := Result + [Pad];
  end;
end;

end.
