{
  Levels.Pads - the pads section of level JSON: platforms apart from the
  collision grid. Model and parser, no game logic - the game runs them
  in Pads.World.

  A pad holds from above only. Its deck, the top edge, carries what lands
  on it; from below and from the side anything passes through. Under the
  deck the pad has a body as deep as its picture, a cell at the most: it
  stops the boss's flight, the sparks and the debris, and the bullets
  unless the pad lets them by.

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

  A pad may be a shelf: it slides out of the wall behind it and back in
  by a program of steps that goes round and round (Pads.Shelf counts the
  cycle). Out, it is a pad as any other; on its way and in the wall it
  is neither a floor nor a body. It joins no group and does not plunge;
  a path it may travel.

  Shelves of one bank are told together by the level's events: to fall
  asleep in the wall, to wake, to run another program. A shelf of a bank
  may be held from the start - out in front or in the wall - and run no
  program until an event tells it one.

  The pads of a group may be parked above the screen: each waits over
  its own place until an event flies the group in.

  A pad may ride a carousel (Levels.Carousels): it flies round the
  carousel's track with the other pads it carries. The carousel places
  it, so the pad takes no x or y; it travels no path, does not plunge,
  is no shelf and joins no group.

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

  // Where a step of a shelf's program holds it: out in front, or in the
  // wall
  TShelfStand = (shOut, shIn);

  TShelfStep = record
    Stand: TShelfStand;
    Seconds: Single; // held there, the slide not counted
  end;

  // A pad all the way into the depth: its size and its light, as shares
  // of what they are in front, and how far down its picture has gone
  TPadDeepLook = record
    Scale: Single;
    Tone: Single;
    Sink: Single; // units
  end;

  // A pad that slides out of the wall behind it and back in. Its steps
  // take turns, out and in, and go round: after the last comes the
  // first. Between two steps it slides for SlideSeconds; WarnSeconds
  // before it leaves the front it says so. It starts OffsetSeconds into
  // its program: shelves in a row go as a wave.
  TPadShelf = record
    Slides: Boolean; // False - the pad never leaves the front
    Steps: TArray<TShelfStep>;
    SlideSeconds: Single;
    WarnSeconds: Single;
    OffsetSeconds: Single;
    Deep: TPadDeepLook; // in the wall
    // The bank the events tell it with; '' = none
    Bank: string;
    // Held at HeldStand from the start, the steps run not at all, until
    // an event tells it otherwise
    Held: Boolean;
    HeldStand: TShelfStand;
  end;

  // What a bank of shelves runs once an event tells it to:
  // - hold: out, and stays out;
  // - wave: out and in by turns, each shelf a step after the one before;
  // - alternate: out and in by turns, every other shelf out of step;
  // - blink: short turns, every shelf at a time of its own.
  TShelfProgramKind = (pgHold, pgWave, pgAlternate, pgBlink);

  TShelfProgram = record
    Kind: TShelfProgramKind;
    OutSeconds: Single;
    InSeconds: Single;
    // Of the warning before a shelf leaves the front; 0 = the shelf's own
    WarnSeconds: Single;
  end;

  // The order the shelves of a bank are told in, one a step after
  // another: as the level file lists them, from the left, from the
  // right, from the bottom, from the top, or from the farthest from the
  // hero to the nearest
  TBankOrder = (boFile, boLeft, boRight, boUp, boDown, boToHero);

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
    Shelf: TPadShelf;
    // The pad group it is rebuilt with; '' = none
    Group: string;
    // The carousel it rides; '' = none. The carousel puts X and Y.
    Carousel: string;
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
    // The pads wait above the screen, each over its place, until the
    // group is flown in
    Parked: Boolean;
  end;

const
  PadBulletsIds: array [TPadBullets] of string = ('block', 'pass');
  PadRouteIds: array [TPadRoute] of string = ('none', 'pingpong', 'loop');
  ShelfStandIds: array [TShelfStand] of string = ('out', 'in');
  ShelfProgramIds: array [TShelfProgramKind] of string = (
    'hold', 'wave', 'alternate', 'blink');
  BankOrderIds: array [TBankOrder] of string = (
    'file', 'left', 'right', 'up', 'down', 'toHero');
  PadParkedAbove = 'above';

// The section; absent = no pads. A width of zero or less, a bullets word
// out of PadBulletsIds, a route other than pingpong or loop, a path
// without stops or with a speed of zero or less, a pause or a bob below
// zero, a plunge with a delay or a rest below zero or a rise of zero or
// less, a rig that is not a list of names raise. So does a shelf with a
// program beside its out or in, with a step that is not a stand and
// seconds above zero, with steps that do not take turns, with a slide,
// a warn or an offset below zero, a scale out of 0..1 or zero, a tone
// out of 0..1, a shelf held but in no bank or held neither out nor in.
// A pad on a carousel that is given an x or a y raises too: the carousel
// places it.
function ParsePads(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TPadPlacement>;
// The section padGroups; absent = no groups. A zone that is not four
// numbers, pairs or farShare below zero, a farFlight below one, a
// conductor without every above zero, parked anywhere but above raise.
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
  SPadCarouselPlaced = 'Level "%s": pad "%s" rides carousel "%s" and is '
    + 'given an x or a y - the carousel places it';
  SPadShelfTwoPrograms = 'Level "%s": pad "%s" is a shelf with a program '
    + 'and with out or in beside it - one or the other';
  SPadShelfBadStep = 'Level "%s": pad "%s" has a shelf step that is not '
    + '["out", seconds] or ["in", seconds]';
  SPadShelfNoTurns = 'Level "%s": pad "%s" has a shelf program whose steps '
    + 'do not take turns, out and in, the last and the first too';
  SPadShelfHeldAlone = 'Level "%s": pad "%s" is a shelf held in no bank - '
    + 'no event could ever let it go';
  SPadShelfBadHeld = 'Level "%s": pad "%s" is a shelf held "%s" - out or in';
  SPadGroupBadZone = 'Level "%s": pad group "%s" has a zone that is not '
    + '[left, top, right, bottom]';
  SPadGroupBadNumber = 'Level "%s": pad group "%s" takes %s %d';
  SPadGroupBadEvery = 'Level "%s": pad group "%s" has a conductor and '
    + 'takes every %g - seconds above zero';
  SPadGroupBadParked = 'Level "%s": pad group "%s" is parked "%s" - above '
    + 'is the only place';

const
  // What a plunge takes for a number it leaves out: seconds, seconds and
  // units a second
  DefaultPlungeDelay = 0.5;
  DefaultPlungeRest = 0.5;
  DefaultPlungeRise = 64;
  // What a shelf takes for a number it leaves out: the seconds it stays
  // out, stays in, slides and warns; its size and its light in the wall
  DefaultShelfOut = 2.0;
  DefaultShelfIn = 1.5;
  DefaultShelfSlide = 0.25;
  DefaultShelfWarn = 0.5;
  DefaultShelfScale = 0.72;
  DefaultShelfTone = 0.4;

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

// JSON: ["out", 2] or ["in", 1.5]
function ReadShelfStep(const AValue: TJSONValue;
  const ALevelId, ASprite: string): TShelfStep;
begin
  var IsPair := (AValue is TJSONArray) and (TJSONArray(AValue).Count = 2);
  if not IsPair then
    raise EPadError.CreateFmt(SPadShelfBadStep, [ALevelId, ASprite]);
  var Id := TJSONArray(AValue).Items[0];
  var Held := TJSONArray(AValue).Items[1];
  // System.JSON holds a number as a string of a kind
  var IsWord := (Id is TJSONString) and not (Id is TJSONNumber);
  if not IsWord or not (Held is TJSONNumber) then
    raise EPadError.CreateFmt(SPadShelfBadStep, [ALevelId, ASprite]);

  Result.Seconds := TJSONNumber(Held).AsDouble;
  for var Stand := Low(TShelfStand) to High(TShelfStand) do
    if SameText(Id.Value, ShelfStandIds[Stand]) then
    begin
      Result.Stand := Stand;
      Exit;
    end;
  raise EPadError.CreateFmt(SPadShelfBadStep, [ALevelId, ASprite]);
end;

// The program the keys "out" and "in" stand for: out for the seconds of
// the one, then in for the seconds of the other
function StepsOfOutAndIn(const AShelf: TJSONObject): TArray<TShelfStep>;
var
  StaysOut, StaysIn: TShelfStep;
begin
  StaysOut.Stand := shOut;
  StaysOut.Seconds := AShelf.GetValue<Double>('out', DefaultShelfOut);
  StaysIn.Stand := shIn;
  StaysIn.Seconds := AShelf.GetValue<Double>('in', DefaultShelfIn);
  Result := [StaysOut, StaysIn];
end;

// No two steps on end hold the shelf alike, the last and the first
// neither: between any two it has a slide to make
function StepsTakeTurns(const ASteps: TArray<TShelfStep>): Boolean;
begin
  for var i := 0 to High(ASteps) do
    if ASteps[i].Stand = ASteps[(i + 1) mod Length(ASteps)].Stand then
      Exit(False);
  Result := Length(ASteps) > 0;
end;

function ReadShelfSteps(const AShelf: TJSONObject;
  const ALevelId, ASprite: string): TArray<TShelfStep>;
begin
  Result := [];
  var ProgramArr := AShelf.GetValue<TJSONArray>('program', nil);
  var HasOutOrIn := (AShelf.GetValue('out') <> nil) or
    (AShelf.GetValue('in') <> nil);
  if (ProgramArr <> nil) and HasOutOrIn then
    raise EPadError.CreateFmt(SPadShelfTwoPrograms, [ALevelId, ASprite]);

  if ProgramArr = nil then
    Result := StepsOfOutAndIn(AShelf)
  else
    for var Item in ProgramArr do
      Result := Result + [ReadShelfStep(Item, ALevelId, ASprite)];

  for var Step in Result do
    if Step.Seconds <= 0 then
      raise EPadError.CreateFmt(SPadBadNumber,
        [ALevelId, ASprite, 'shelf step', Step.Seconds]);
  if not StepsTakeTurns(Result) then
    raise EPadError.CreateFmt(SPadShelfNoTurns, [ALevelId, ASprite]);
end;

// JSON: "held": "out" or "in"; absent = the shelf runs its steps
procedure ReadShelfHeld(const AShelfObj: TJSONObject;
  const ALevelId, ASprite: string; var AShelf: TPadShelf);
begin
  var Id := AShelfObj.GetValue<string>('held', '');
  AShelf.Held := Id <> '';
  if not AShelf.Held then
    Exit;
  if AShelf.Bank = '' then
    raise EPadError.CreateFmt(SPadShelfHeldAlone, [ALevelId, ASprite]);
  for var Stand := Low(TShelfStand) to High(TShelfStand) do
    if SameText(Id, ShelfStandIds[Stand]) then
    begin
      AShelf.HeldStand := Stand;
      Exit;
    end;
  raise EPadError.CreateFmt(SPadShelfBadHeld, [ALevelId, ASprite, Id]);
end;

// JSON: "shelf": {"out": 2, "in": 1.5, "slide": 0.25, "warn": 0.5,
// "offset": 0, "sink": 7, "scale": 0.72, "tone": 0.4, "bank": "ladder",
// "held": "in"}, or with "program": [["out", 2], ["in", 0.5],
// ["out", 0.5], ["in", 1.5]] in place of "out" and "in"; absent = the
// pad never leaves the front
function ReadShelf(const AObj: TJSONObject;
  const ALevelId, ASprite: string): TPadShelf;
var
  ShelfObj: TJSONObject;

  function NotBelowZero(const AKey: string; ADefault: Double): Double;
  begin
    Result := ShelfObj.GetValue<Double>(AKey, ADefault);
    if Result < 0 then
      raise EPadError.CreateFmt(SPadBadNumber,
        [ALevelId, ASprite, AKey, Result]);
  end;

begin
  Result := Default(TPadShelf);
  ShelfObj := AObj.GetValue<TJSONObject>('shelf', nil);
  if ShelfObj = nil then
    Exit;

  Result.Slides := True;
  Result.Steps := ReadShelfSteps(ShelfObj, ALevelId, ASprite);
  Result.SlideSeconds := NotBelowZero('slide', DefaultShelfSlide);
  Result.WarnSeconds := NotBelowZero('warn', DefaultShelfWarn);
  Result.OffsetSeconds := NotBelowZero('offset', 0);
  Result.Bank := ShelfObj.GetValue<string>('bank', '');
  ReadShelfHeld(ShelfObj, ALevelId, ASprite, Result);

  Result.Deep.Sink := ShelfObj.GetValue<Double>('sink', 0);
  Result.Deep.Scale := ShelfObj.GetValue<Double>('scale', DefaultShelfScale);
  Result.Deep.Tone := ShelfObj.GetValue<Double>('tone', DefaultShelfTone);
  // At a scale of zero there is no picture to draw
  var ScaleFits := (Result.Deep.Scale > 0) and (Result.Deep.Scale <= 1);
  if not ScaleFits then
    raise EPadError.CreateFmt(SPadBadNumber,
      [ALevelId, ASprite, 'scale', Result.Deep.Scale]);
  var ToneFits := (Result.Deep.Tone >= 0) and (Result.Deep.Tone <= 1);
  if not ToneFits then
    raise EPadError.CreateFmt(SPadBadNumber,
      [ALevelId, ASprite, 'tone', Result.Deep.Tone]);
end;

function PadRigName(const APad: TPadPlacement): string;
begin
  var Shown := APad.Sprite;
  if APad.Tag <> '' then
    Shown := APad.Tag;
  Result := Format('pad "%s"', [Shown]);
end;

// A pad on a carousel is placed by it: Levels.Defs puts its X and Y
procedure ReadPlace(const AObj: TJSONObject; const ALevelId: string;
  var APad: TPadPlacement);
begin
  APad.X := 0;
  APad.Y := 0;
  if APad.Carousel = '' then
  begin
    APad.X := AObj.GetValue<Integer>('x');
    APad.Y := AObj.GetValue<Integer>('y');
    Exit;
  end;
  if (AObj.GetValue('x') <> nil) or (AObj.GetValue('y') <> nil) then
    raise EPadError.CreateFmt(SPadCarouselPlaced,
      [ALevelId, APad.Sprite, APad.Carousel]);
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
    Pad.Carousel := Obj.GetValue<string>('carousel', '');
    ReadPlace(Obj, ALevelId, Pad);
    Pad.Width := Obj.GetValue<Integer>('width');
    Pad.Tint := ReadTint(Obj, Pad.Sprite);
    Pad.Tag := Obj.GetValue<string>('tag', '');
    Pad.Bullets := ReadBullets(Obj, ALevelId, Pad.Sprite);
    Pad.Path := ReadPath(Obj, ALevelId, Pad.Sprite);
    Pad.Bob := Obj.GetValue<Double>('bob', 0);
    Pad.Plunge := ReadPlunge(Obj, ALevelId, Pad.Sprite);
    Pad.Shelf := ReadShelf(Obj, ALevelId, Pad.Sprite);
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
    var Parked := Obj.GetValue<string>('parked', '');
    Group.Parked := Parked <> '';
    if Group.Parked and not SameText(Parked, PadParkedAbove) then
      raise EPadError.CreateFmt(SPadGroupBadParked,
        [ALevelId, Group.Tag, Parked]);

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
