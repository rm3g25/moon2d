{
  Levels.Carousels - the carousels section of level JSON: pads that fly
  round a closed track, one after another, without end. The model, the
  parser and the track itself; Pads.World flies the pads, Levels.Defs
  places them and checks their round.

  The track is the path of the middle of every deck: an oval, or a box
  whose corners may be rounded. It starts on the right of its middle and
  runs clockwise on the screen - down from there. The pads go round it
  at one even pace, a lap in the carousel's period, the way it turns,
  each a share of the lap ahead of the one before it in file order. A
  pad keeps its deck level all the way round.

  A pad joins a carousel by its "carousel". The carousel places it, so
  the pad takes no x or y of its own.

  A carousel may be parked above the screen: its pads wait over their
  slots - the places they start the lap from - until an event flies it
  in. Each comes straight down to its slot; the carousel turns once all
  of them are on it, its clock coming up to its pace from a standstill
  over the carousel's speed-up.

  A carousel may break, when an event says so: its clock runs down to a
  standstill, and its pads, one after another, become pads that plunge
  where they stand. A carousel that may break says what its pads look
  like then - another picture, other rigs - and how they plunge. The
  rigs of that look hang on a tag of its own, made from the pad's tag:
  the game lights them when the pad breaks and puts out the pad's own.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Carousels;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Levels.Pads;

type
  ECarouselError = class(Exception);

  TCarouselShape = (csOval, csBox);

  // Clockwise as seen on the screen
  TCarouselTurn = (ctClockwise, ctCounterClockwise);

  // What a pad of a broken carousel becomes: its picture in the level's
  // object art, the rigs it wears from then on, the way it plunges
  TCarouselFailing = record
    Breaks: Boolean; // False - the carousel cannot break
    Sprite: string;
    Rigs: TArray<string>;
    Plunge: TPadPlunge;
  end;

  TCarousel = record
    Tag: string;
    Screen: Integer; // 1-based
    Shape: TCarouselShape;
    // The middle of the track and its size across and down, in screen
    // units
    CenterX, CenterY: Single;
    Width, Height: Single;
    // A box's corners are rounded to this radius; 0 = sharp
    Corner: Single;
    Period: Single; // seconds a lap
    Turn: TCarouselTurn;
    // Where the first pad starts: a share of the lap from the right of
    // the middle, the way the carousel turns
    Start: Single;
    // Its pads wait above the screen until an event flies it in
    Parked: Boolean;
    // Seconds the clock takes to come up to the pace of the period from a
    // standstill once the carousel starts to turn; 0 = at its pace at once
    SpeedUp: Single;
    Failing: TCarouselFailing;
  end;

  // A parked pad's way down to its slot: straight down at an even pace,
  // braking to a stop on the slot
  TCarouselLanding = record
  private
    FFromY, FToY: Double;
    FDepart: Double; // ticks after the fly-in before it sets off
    FCruiseTicks: Double;
    FBrakeTicks: Double;
  public
    procedure Build(AFromY, AToY, ADepart: Double);
    // The deck ATime ticks after the fly-in, between ticks too
    function DeckAt(ATime: Double): Double;
    // The first tick the pad stands on its slot
    function Done: Integer;
  end;

  // The track as a closed line of points, the last joined to the first
  TCarouselTrack = record
  private
    FPoints: TArray<TPadStop>;
    // Along the line from the first point to every point
    FDistances: TArray<Double>;
    FLength: Double;
    procedure Add(AX, AY: Double);
    procedure AddCorner(ACenterX, ACenterY, ARadius, AFromDegrees: Double);
    procedure BuildOval(const ACarousel: TCarousel);
    procedure BuildBox(const ACarousel: TCarousel);
    procedure Measure;
  public
    procedure Build(const ACarousel: TCarousel);
    // Clockwise from the start of the track; any distance, past a lap or
    // below zero too
    procedure PointAt(ADistance: Double; out AX, AY: Double);
    property Length: Double read FLength;
  end;

  // One pad's way round: where on its track it is at a tick of its clock
  TCarouselOrbit = record
  private
    FTrack: TCarouselTrack;
    FRides: Boolean;
    FFirst: Double; // along the track at tick 0
    FStep: Double; // units a tick, below zero counter-clockwise
    FParked: Boolean;
    FSpeedUpTicks: Integer;
    // The middle of the carousel across and its lowest deck: what the
    // landing of a parked pad goes by
    FCenterX: Double;
    FBottom: Double;
  public
    // ASlot of ASlots: the pad's place among those its carousel carries
    procedure Build(const ACarousel: TCarousel; ASlot, ASlots: Integer);
    // False for a pad on no carousel: Place says nothing then
    function Rides: Boolean;
    // The middle of the deck at ATime ticks, between ticks too
    procedure Place(ATime: Double; out AX, AY: Double);
    // Its carousel waits above the screen until an event flies it in
    function Parked: Boolean;
    // The time of Place ATurning ticks after the carousel started to turn:
    // from a standstill up to its pace over the speed-up, at its pace on
    function Clock(ATurning: Double): Double;
    // The time of Place ABraking ticks into a halt that began ATurning
    // ticks after the carousel started to turn: the pace the clock had
    // then falls evenly to nothing over AHaltTicks, and the clock stands
    // from there on
    function Halting(ATurning, AHaltTicks, ABraking: Double): Double;
    // The pad's way down from its deck at AFromY to its slot, where Place
    // puts it at time 0. The deeper the slot, the sooner the pad sets off:
    // every pad of the carousel brakes at once, so a pad over another
    // keeps the gap of their slots from the moment it sets off. Across,
    // the wave ripples out from the middle.
    function Landing(AFromY: Double): TCarouselLanding;
  end;

const
  CarouselShapeIds: array [TCarouselShape] of string = ('oval', 'box');
  CarouselTurnIds: array [TCarouselTurn] of string = ('cw', 'ccw');

// The section; absent = no carousels. A shape or a turn out of its
// words, a center or a size that is not [x, y], a size of zero or less,
// a corner below zero or wider than half the box, a period of zero or
// less, a start out of 0..1, a speed-up below zero, parked anywhere but
// above raise; so does a failing look with no sprite or no plunge, or a
// plunge or rigs a pad would refuse.
function ParseCarousels(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TCarousel>;
// False when no carousel carries the tag
function TryFindCarousel(const ACarousels: TArray<TCarousel>;
  const ATag: string; out ACarousel: TCarousel): Boolean;
// The way round of the pad at AIndex: its place among the pads of its
// carousel, in file order. A pad on no carousel, or on one the level
// does not have, gets an orbit that does not ride.
function OrbitOf(const ACarousels: TArray<TCarousel>;
  const APads: TArray<TPadPlacement>; AIndex: Integer): TCarouselOrbit;
// The ticks of a lap, one at the least
function LapTicks(const ACarousel: TCarousel): Integer;
// The tag the rigs of a pad's failing look hang on
function FailingRigTag(const APadTag: string): string;

implementation

uses
  System.Math, System.Generics.Collections, Levels.Rigs;

resourcestring
  SCarouselBadShape = 'Level "%s": carousel "%s" takes shape "%s" - oval or box';
  SCarouselBadTurn = 'Level "%s": carousel "%s" takes turn "%s" - cw or ccw';
  SCarouselBadPair = 'Level "%s": carousel "%s" has a %s that is not [x, y]';
  SCarouselBadNumber = 'Level "%s": carousel "%s" takes %s %g';
  SCarouselBadParked = 'Level "%s": carousel "%s" is parked "%s" - above '
    + 'is the only place';
  SCarouselFailingNoSprite = 'Level "%s": carousel "%s" fails into pads '
    + 'that name no "sprite"';
  SCarouselFailingNoPlunge = 'Level "%s": carousel "%s" fails into pads '
    + 'that do not "plunge"';

const
  // Seconds in JSON, ticks in the code; the logic runs 33 ticks a second
  // (tickRate of Game.Config)
  LogicTicksPerSecond = 33;
  // A parked pad comes down at this many units a tick and brakes over the
  // last LandingBrakeTicks of its way
  LandingSpeed = 8.0;
  LandingBrakeTicks = 10;
  // A pad a cell of 32 units farther from the middle across sets off 4
  // ticks later, as a pad of a group flown in does
  LandingRippleTicksPerUnit = 4 / 32;
  // An oval as a line of this many points: within a hair of the curve
  // at the size of a screen
  OvalPoints = 360;
  // A rounded corner, a quarter of a circle, as this many legs
  CornerLegs = 12;
  // Joined to a pad's tag: no tag of a level file holds a slash
  FailingRigSuffix = '/failing';

// ---------------------------------------------------------------------------
// TCarouselTrack
// ---------------------------------------------------------------------------

procedure TCarouselTrack.Add(AX, AY: Double);
var
  Point: TPadStop;
begin
  Point.X := AX;
  Point.Y := AY;
  FPoints := FPoints + [Point];
end;

// A quarter of a circle, clockwise from AFromDegrees: its first point is
// the last one added already
procedure TCarouselTrack.AddCorner(ACenterX, ACenterY, ARadius,
  AFromDegrees: Double);
begin
  for var i := 1 to CornerLegs do
  begin
    var Angle := DegToRad(AFromDegrees + 90 * i / CornerLegs);
    Add(ACenterX + ARadius * Cos(Angle), ACenterY + ARadius * Sin(Angle));
  end;
end;

// Y grows down the screen: an angle that grows goes clockwise
procedure TCarouselTrack.BuildOval(const ACarousel: TCarousel);
begin
  for var i := 0 to OvalPoints - 1 do
  begin
    var Angle := 2 * Pi * i / OvalPoints;
    Add(ACarousel.CenterX + ACarousel.Width / 2 * Cos(Angle),
      ACarousel.CenterY + ACarousel.Height / 2 * Sin(Angle));
  end;
end;

// Down the right side, along the bottom to the left, up the left side
// and along the top back to the right
procedure TCarouselTrack.BuildBox(const ACarousel: TCarousel);
begin
  var Left := ACarousel.CenterX - ACarousel.Width / 2;
  var Right := ACarousel.CenterX + ACarousel.Width / 2;
  var Top := ACarousel.CenterY - ACarousel.Height / 2;
  var Bottom := ACarousel.CenterY + ACarousel.Height / 2;
  var Radius := ACarousel.Corner;

  Add(Right, ACarousel.CenterY);
  Add(Right, Bottom - Radius);
  if Radius > 0 then
    AddCorner(Right - Radius, Bottom - Radius, Radius, 0);
  Add(Left + Radius, Bottom);
  if Radius > 0 then
    AddCorner(Left + Radius, Bottom - Radius, Radius, 90);
  Add(Left, Top + Radius);
  if Radius > 0 then
    AddCorner(Left + Radius, Top + Radius, Radius, 180);
  Add(Right - Radius, Top);
  if Radius > 0 then
    AddCorner(Right - Radius, Top + Radius, Radius, 270);
end;

procedure TCarouselTrack.Measure;
begin
  SetLength(FDistances, System.Length(FPoints));
  FLength := 0;
  for var i := 0 to High(FPoints) do
  begin
    FDistances[i] := FLength;
    var Next := FPoints[(i + 1) mod System.Length(FPoints)];
    FLength := FLength + Hypot(Next.X - FPoints[i].X, Next.Y - FPoints[i].Y);
  end;
end;

procedure TCarouselTrack.Build(const ACarousel: TCarousel);
begin
  FPoints := [];
  case ACarousel.Shape of
    csOval:
      BuildOval(ACarousel);
    csBox:
      BuildBox(ACarousel);
  end;
  Measure;
end;

procedure TCarouselTrack.PointAt(ADistance: Double; out AX, AY: Double);
begin
  var Along := ADistance - Floor(ADistance / FLength) * FLength;

  // The last point at or before Along
  var Lower := 0;
  var Upper := High(FDistances);
  while Lower < Upper do
  begin
    var Middle := (Lower + Upper + 1) div 2;
    if FDistances[Middle] <= Along then
      Lower := Middle
    else
      Upper := Middle - 1;
  end;

  var From := FPoints[Lower];
  var Next := FPoints[(Lower + 1) mod System.Length(FPoints)];
  var LegEnd := FLength;
  if Lower < High(FDistances) then
    LegEnd := FDistances[Lower + 1];
  var Leg := LegEnd - FDistances[Lower];
  var Share: Double := 0;
  // Two points in one place - a side as short as its corners - are a
  // leg of no length
  if Leg > 0 then
    Share := (Along - FDistances[Lower]) / Leg;
  AX := From.X + (Next.X - From.X) * Share;
  AY := From.Y + (Next.Y - From.Y) * Share;
end;

// ---------------------------------------------------------------------------
// TCarouselOrbit
// ---------------------------------------------------------------------------

procedure TCarouselOrbit.Build(const ACarousel: TCarousel;
  ASlot, ASlots: Integer);
begin
  FTrack.Build(ACarousel);
  FRides := True;
  var Way := 1;
  if ACarousel.Turn = ctCounterClockwise then
    Way := -1;
  var Share := Frac(ACarousel.Start + ASlot / ASlots);
  FFirst := Way * Share * FTrack.Length;
  FStep := Way * FTrack.Length / LapTicks(ACarousel);
  FParked := ACarousel.Parked;
  FSpeedUpTicks := Round(ACarousel.SpeedUp * LogicTicksPerSecond);
  FCenterX := ACarousel.CenterX;
  FBottom := ACarousel.CenterY + ACarousel.Height / 2;
end;

function TCarouselOrbit.Rides: Boolean;
begin
  Result := FRides;
end;

procedure TCarouselOrbit.Place(ATime: Double; out AX, AY: Double);
begin
  FTrack.PointAt(FFirst + FStep * ATime, AX, AY);
end;

function TCarouselOrbit.Parked: Boolean;
begin
  Result := FParked;
end;

function TCarouselOrbit.Clock(ATurning: Double): Double;
begin
  if ATurning >= FSpeedUpTicks then
    Exit(ATurning - FSpeedUpTicks / 2);
  // The pace grows evenly from nothing: the clock runs the area under it
  Result := Sqr(ATurning) / (2 * FSpeedUpTicks);
end;

function TCarouselOrbit.Halting(ATurning, AHaltTicks,
  ABraking: Double): Double;
begin
  Result := Clock(ATurning);
  if AHaltTicks <= 0 then
    Exit;
  var Pace: Double := 1;
  if ATurning < FSpeedUpTicks then
    Pace := ATurning / FSpeedUpTicks;
  var Braked := Min(ABraking, AHaltTicks);
  Result := Result + Pace * (Braked - Sqr(Braked) / (2 * AHaltTicks));
end;

function TCarouselOrbit.Landing(AFromY: Double): TCarouselLanding;
var
  SlotX, SlotY: Double;
begin
  Place(0, SlotX, SlotY);
  var Ripple := LandingRippleTicksPerUnit * Abs(SlotX - FCenterX);
  // A slot higher than the lowest deck by some units waits as many units
  // of the pace: it then flies the very way of the lowest, that much behind
  var Wait := (FBottom - SlotY) / LandingSpeed;
  Result.Build(AFromY, SlotY, Ripple + Wait);
end;

// ---------------------------------------------------------------------------
// TCarouselLanding
// ---------------------------------------------------------------------------

procedure TCarouselLanding.Build(AFromY, AToY, ADepart: Double);
begin
  FFromY := AFromY;
  FToY := AToY;
  FDepart := ADepart;
  var Distance := Max(0.0, AToY - AFromY);
  // A way shorter than the braking is braked all the way, in fewer ticks
  var BrakeDistance := Min(Distance, LandingSpeed * LandingBrakeTicks / 2);
  FBrakeTicks := 2 * BrakeDistance / LandingSpeed;
  FCruiseTicks := (Distance - BrakeDistance) / LandingSpeed;
end;

function TCarouselLanding.DeckAt(ATime: Double): Double;
begin
  var Flown := ATime - FDepart;
  if Flown <= 0 then
    Exit(FFromY);
  if Flown <= FCruiseTicks then
    Exit(FFromY + LandingSpeed * Flown);
  var Braking := Flown - FCruiseTicks;
  if Braking >= FBrakeTicks then
    Exit(FToY);
  Result := FFromY + LandingSpeed *
    (FCruiseTicks + Braking - Sqr(Braking) / (2 * FBrakeTicks));
end;

function TCarouselLanding.Done: Integer;
begin
  Result := Ceil(FDepart + FCruiseTicks + FBrakeTicks);
end;

// ---------------------------------------------------------------------------
// The section
// ---------------------------------------------------------------------------

function LapTicks(const ACarousel: TCarousel): Integer;
begin
  Result := Max(1, Round(ACarousel.Period * LogicTicksPerSecond));
end;

function FailingRigTag(const APadTag: string): string;
begin
  Result := APadTag + FailingRigSuffix;
end;

// JSON: [x, y]
procedure ReadPair(const AObj: TJSONObject; const AKey, ALevelId,
  ATag: string; out AX, AY: Single);
begin
  var Pair := AObj.GetValue<TJSONArray>(AKey, nil);
  var IsPair := (Pair <> nil) and (Pair.Count = 2) and
    (Pair.Items[0] is TJSONNumber) and (Pair.Items[1] is TJSONNumber);
  if not IsPair then
    raise ECarouselError.CreateFmt(SCarouselBadPair, [ALevelId, ATag, AKey]);
  AX := TJSONNumber(Pair.Items[0]).AsDouble;
  AY := TJSONNumber(Pair.Items[1]).AsDouble;
end;

function ReadShape(const AObj: TJSONObject;
  const ALevelId, ATag: string): TCarouselShape;
begin
  var Id := AObj.GetValue<string>('shape', CarouselShapeIds[csOval]);
  for var Shape := Low(TCarouselShape) to High(TCarouselShape) do
    if SameText(Id, CarouselShapeIds[Shape]) then
      Exit(Shape);
  raise ECarouselError.CreateFmt(SCarouselBadShape, [ALevelId, ATag, Id]);
end;

function ReadTurn(const AObj: TJSONObject;
  const ALevelId, ATag: string): TCarouselTurn;
begin
  var Id := AObj.GetValue<string>('turn', CarouselTurnIds[ctClockwise]);
  for var Turn := Low(TCarouselTurn) to High(TCarouselTurn) do
    if SameText(Id, CarouselTurnIds[Turn]) then
      Exit(Turn);
  raise ECarouselError.CreateFmt(SCarouselBadTurn, [ALevelId, ATag, Id]);
end;

function ReadParked(const AObj: TJSONObject;
  const ALevelId, ATag: string): Boolean;
begin
  var Place := AObj.GetValue<string>('parked', '');
  Result := Place <> '';
  if Result and not SameText(Place, PadParkedAbove) then
    raise ECarouselError.CreateFmt(SCarouselBadParked, [ALevelId, ATag, Place]);
end;

// JSON: "failing": {"sprite": "s16-platform-out", "rig": ["padFailing"],
// "plunge": {"delay": 0.5, "rest": 0.5, "rise": 64}}; absent = the
// carousel cannot break
function ReadFailing(const AObj: TJSONObject;
  const ALevelId, ATag: string): TCarouselFailing;
begin
  Result := Default(TCarouselFailing);
  var FailingObj := AObj.GetValue<TJSONObject>('failing', nil);
  if FailingObj = nil then
    Exit;

  Result.Breaks := True;
  Result.Sprite := FailingObj.GetValue<string>('sprite', '');
  if Result.Sprite = '' then
    raise ECarouselError.CreateFmt(SCarouselFailingNoSprite, [ALevelId, ATag]);
  Result.Rigs := ReadRigNames(FailingObj, ALevelId,
    Format('failing pads of carousel "%s"', [ATag]));
  Result.Plunge := ReadPlunge(FailingObj, ALevelId,
    Format('%s (failing)', [ATag]));
  if not Result.Plunge.Plunges then
    raise ECarouselError.CreateFmt(SCarouselFailingNoPlunge, [ALevelId, ATag]);
end;

procedure CheckNumbers(const ACarousel: TCarousel; const ALevelId: string);

  procedure Refuse(const AKey: string; AValue: Double);
  begin
    raise ECarouselError.CreateFmt(SCarouselBadNumber,
      [ALevelId, ACarousel.Tag, AKey, AValue]);
  end;

begin
  if ACarousel.Width <= 0 then
    Refuse('width', ACarousel.Width);
  if ACarousel.Height <= 0 then
    Refuse('height', ACarousel.Height);
  var HalfSide := Min(ACarousel.Width, ACarousel.Height) / 2;
  if (ACarousel.Corner < 0) or (ACarousel.Corner > HalfSide) then
    Refuse('corner', ACarousel.Corner);
  if ACarousel.Period <= 0 then
    Refuse('period', ACarousel.Period);
  if (ACarousel.Start < 0) or (ACarousel.Start >= 1) then
    Refuse('start', ACarousel.Start);
  if ACarousel.SpeedUp < 0 then
    Refuse('speedUp', ACarousel.SpeedUp);
end;

// JSON: {"tag": "s08-carousel", "screen": 8, "shape": "oval", "center":
// [288, 179], "size": [150, 150], "corner": 0, "period": 12, "turn":
// "cw", "start": 0, "parked": "above", "speedUp": 3, "failing": {...}};
// shape absent = oval, corner, start and speedUp absent = 0, turn absent
// = cw, parked absent = in its place from the start
function ParseCarousels(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TCarousel>;
var
  Section: TJSONArray;
begin
  Result := [];
  if not ARoot.TryGetValue<TJSONArray>('carousels', Section) then
    Exit;

  for var Item in Section do
  begin
    var Obj := Item as TJSONObject;
    var Carousel: TCarousel;
    Carousel.Tag := Obj.GetValue<string>('tag');
    Carousel.Screen := Obj.GetValue<Integer>('screen');
    Carousel.Shape := ReadShape(Obj, ALevelId, Carousel.Tag);
    ReadPair(Obj, 'center', ALevelId, Carousel.Tag, Carousel.CenterX,
      Carousel.CenterY);
    ReadPair(Obj, 'size', ALevelId, Carousel.Tag, Carousel.Width,
      Carousel.Height);
    Carousel.Corner := Obj.GetValue<Double>('corner', 0);
    Carousel.Period := Obj.GetValue<Double>('period', 0);
    Carousel.Turn := ReadTurn(Obj, ALevelId, Carousel.Tag);
    Carousel.Start := Obj.GetValue<Double>('start', 0);
    Carousel.Parked := ReadParked(Obj, ALevelId, Carousel.Tag);
    Carousel.SpeedUp := Obj.GetValue<Double>('speedUp', 0);
    Carousel.Failing := ReadFailing(Obj, ALevelId, Carousel.Tag);
    CheckNumbers(Carousel, ALevelId);
    Result := Result + [Carousel];
  end;
end;

function TryFindCarousel(const ACarousels: TArray<TCarousel>;
  const ATag: string; out ACarousel: TCarousel): Boolean;
begin
  for var Carousel in ACarousels do
    if Carousel.Tag = ATag then
    begin
      ACarousel := Carousel;
      Exit(True);
    end;
  Result := False;
end;

function OrbitOf(const ACarousels: TArray<TCarousel>;
  const APads: TArray<TPadPlacement>; AIndex: Integer): TCarouselOrbit;
var
  Carousel: TCarousel;
begin
  Result := Default(TCarouselOrbit);
  var Tag := APads[AIndex].Carousel;
  if (Tag = '') or not TryFindCarousel(ACarousels, Tag, Carousel) then
    Exit;

  var Slot := 0;
  var Slots := 0;
  for var i := 0 to High(APads) do
    if APads[i].Carousel = Tag then
    begin
      if i < AIndex then
        Inc(Slot);
      Inc(Slots);
    end;
  Result.Build(Carousel, Slot, Slots);
end;

end.
