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
  public
    // ASlot of ASlots: the pad's place among those its carousel carries
    procedure Build(const ACarousel: TCarousel; ASlot, ASlots: Integer);
    // False for a pad on no carousel: Place says nothing then
    function Rides: Boolean;
    // The middle of the deck at ATime ticks, between ticks too
    procedure Place(ATime: Double; out AX, AY: Double);
  end;

const
  CarouselShapeIds: array [TCarouselShape] of string = ('oval', 'box');
  CarouselTurnIds: array [TCarouselTurn] of string = ('cw', 'ccw');

// The section; absent = no carousels. A shape or a turn out of its
// words, a center or a size that is not [x, y], a size of zero or less,
// a corner below zero or wider than half the box, a period of zero or
// less, a start out of 0..1 raise.
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

implementation

uses
  System.Math, System.Generics.Collections;

resourcestring
  SCarouselBadShape = 'Level "%s": carousel "%s" takes shape "%s" - oval or box';
  SCarouselBadTurn = 'Level "%s": carousel "%s" takes turn "%s" - cw or ccw';
  SCarouselBadPair = 'Level "%s": carousel "%s" has a %s that is not [x, y]';
  SCarouselBadNumber = 'Level "%s": carousel "%s" takes %s %g';

const
  // Seconds in JSON, ticks in the code; the logic runs 33 ticks a second
  // (tickRate of Game.Config)
  LogicTicksPerSecond = 33;
  // An oval as a line of this many points: within a hair of the curve
  // at the size of a screen
  OvalPoints = 360;
  // A rounded corner, a quarter of a circle, as this many legs
  CornerLegs = 12;

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
end;

function TCarouselOrbit.Rides: Boolean;
begin
  Result := FRides;
end;

procedure TCarouselOrbit.Place(ATime: Double; out AX, AY: Double);
begin
  FTrack.PointAt(FFirst + FStep * ATime, AX, AY);
end;

// ---------------------------------------------------------------------------
// The section
// ---------------------------------------------------------------------------

function LapTicks(const ACarousel: TCarousel): Integer;
begin
  Result := Max(1, Round(ACarousel.Period * LogicTicksPerSecond));
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
end;

// JSON: {"tag": "s08-carousel", "screen": 8, "shape": "oval", "center":
// [288, 179], "size": [150, 150], "corner": 0, "period": 12, "turn":
// "cw", "start": 0}; shape absent = oval, corner and start absent = 0,
// turn absent = cw
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
