{
  Tests.Orbs.Grip - the orbs that take the pads at the throw: one leaves
  his body a tick, out of a point of it; every pad gets its seats, half
  on the top edge of its beam and half on the bottom, more on a long one;
  the pads are gripped once each, in their order, once their orbs are all
  seated; an orb seated within its longest flight; seated, the orbs turn
  with the beam and go where it goes; they are smaller than the rite's
  and swell on a thump; none is armed; a pad blown up burns out its own
  orbs and no other's; a death draws them in, a clear takes them all. An orb leaves from the point of his body that faces
  its seat, his center when he has none.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Grip;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Orbs.Flock,
  Orbs.Rite,
  Orbs.Grip;

type
  [TestFixture]
  TOrbGripTests = class
  private
    FGrip: TOrbGrip;
    FBeams: TArray<TGripBeam>;
    // Ticked till every pad is gripped; the pads in the order gripped
    function GripAll: TArray<Integer>;
    function Tick(APulse: Single = 0): TArray<Integer>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestOneLeavesHisBodyATick;
    [Test]
    procedure TestSeatsOnBothEdgesMoreOnALongBeam;
    [Test]
    procedure TestGrippedOnceEachInTheirOrder;
    [Test]
    procedure TestSeatedWithinItsLongestFlight;
    [Test]
    procedure TestSeatedTheyTurnWithTheBeam;
    [Test]
    procedure TestSeatedTheyGoWhereTheBeamGoes;
    [Test]
    procedure TestSmallerThanTheRitesAndSwellOnAThump;
    [Test]
    procedure TestNoneIsArmed;
    [Test]
    procedure TestABlownPadBurnsOutItsOwnOrbs;
    [Test]
    procedure TestADeathDrawsThemIn;
    [Test]
    procedure TestAClearTakesThemAll;
  end;

  [TestFixture]
  TFacingPointTests = class
  public
    [Test]
    procedure TestThePointThatFacesTheTarget;
    [Test]
    procedure TestNoBodyTheCenter;
  end;

implementation

uses
  System.Math,
  System.SysUtils;

const
  Slop = 0.01;
  HalfDepth = 3.0;
  ManyTicks = 400;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Beam(AX, AY, AWidth: Single): TGripBeam;
begin
  Result.Middle := At(AX, AY);
  Result.Spin := 0;
  Result.HalfWidth := AWidth / 2;
  Result.HalfDepth := HalfDepth;
end;

function Chest: TSdlFPoint;
begin
  Result := At(440, 330);
end;

function Body: TBodyPoints;
begin
  Result := [At(436, 330), At(444, 330), At(440, 322), At(440, 340)];
end;

function AliveOrbs(const AFlock: TOrbFlock): TArray<TOrb>;
begin
  Result := [];
  for var Orb in AFlock.Orbs do
    if Orb.State = osAlive then
      Result := Result + [Orb];
end;

// From the beam's middle as it lies unturned
function Unturned(const ABeam: TGripBeam; const APoint: TSdlFPoint): TSdlFPoint;
begin
  var Angle := DegToRad(ABeam.Spin);
  var X := APoint.X - ABeam.Middle.X;
  var Y := APoint.Y - ABeam.Middle.Y;
  Result.X := X * Cos(Angle) + Y * Sin(Angle);
  Result.Y := -X * Sin(Angle) + Y * Cos(Angle);
end;

procedure TOrbGripTests.Setup;
begin
  FGrip := TOrbGrip.Create;
  FBeams := [Beam(300, 250, 32), Beam(200, 150, 64), Beam(100, 220, 32)];
  FGrip.Start(FBeams);
end;

procedure TOrbGripTests.TearDown;
begin
  FGrip.Free;
end;

function TOrbGripTests.Tick(APulse: Single): TArray<Integer>;
begin
  Result := FGrip.Tick(Body, Chest, FBeams, APulse);
end;

function TOrbGripTests.GripAll: TArray<Integer>;
begin
  Result := [];
  for var i := 1 to ManyTicks do
    Result := Result + Tick;
  Assert.AreEqual(Length(FBeams), Length(Result), 'All gripped');
end;

procedure TOrbGripTests.TestOneLeavesHisBodyATick;
begin
  for var i := 1 to 3 do
  begin
    Tick;
    Assert.AreEqual(Integer(i), FGrip.Flock.Orbs.Count, Format('Tick %d', [i]));
  end;
  FGrip.Clear;
  FGrip.Start(FBeams);
  FGrip.Tick(Body, Chest, FBeams, 0);
  var First := FGrip.Flock.Orbs[0];
  var OutOfHim := False;
  for var Point in Body do
    OutOfHim := OutOfHim or (Hypot(First.X - Point.X, First.Y - Point.Y) < 6);
  Assert.IsTrue(OutOfHim, 'Out of his body');
end;

procedure TOrbGripTests.TestSeatsOnBothEdgesMoreOnALongBeam;
begin
  GripAll;
  Assert.IsTrue(FGrip.Seats(1) > FGrip.Seats(0), 'More on the long one');
  Assert.AreEqual(FGrip.Seats(0), FGrip.Seats(2), 'As many on beams alike');
  for var Orb in AliveOrbs(FGrip.Flock) do
  begin
    var OnSome := False;
    for var Each in FBeams do
    begin
      var Local := Unturned(Each, At(Orb.X, Orb.Y));
      var OnEdge := Abs(Abs(Local.Y) - HalfDepth) < Slop;
      OnSome := OnSome or (OnEdge and (Abs(Local.X) < Each.HalfWidth));
    end;
    Assert.IsTrue(OnSome, Format('An orb at %.1f, %.1f', [Orb.X, Orb.Y]));
  end;
end;

procedure TOrbGripTests.TestGrippedOnceEachInTheirOrder;
begin
  var Order := GripAll;
  for var i := 0 to High(Order) do
    Assert.AreEqual(Integer(i), Order[i], 'In their order');
  for var i := 0 to High(FBeams) do
    Assert.AreEqual(FGrip.Seats(i), FGrip.Seated(i), Format('Pad %d full', [i]));
end;

procedure TOrbGripTests.TestSeatedWithinItsLongestFlight;
begin
  var Seats := FGrip.Seats(0);
  var Gripped := False;
  var Ticks := 0;
  while not Gripped do
  begin
    Inc(Ticks);
    for var Pad in Tick do
      Gripped := Gripped or (Pad = 0);
    Assert.IsTrue(Ticks <= Seats * GripGapTicks + GripFlightLongest, 'Too long');
  end;
end;

procedure TOrbGripTests.TestSeatedTheyTurnWithTheBeam;
begin
  GripAll;
  for var i := 0 to High(FBeams) do
    FBeams[i].Spin := 70;
  Tick;
  for var Orb in AliveOrbs(FGrip.Flock) do
  begin
    var OnSome := False;
    for var Each in FBeams do
      OnSome := OnSome or (Abs(Abs(Unturned(Each, At(Orb.X, Orb.Y)).Y) - HalfDepth) < Slop);
    Assert.IsTrue(OnSome, 'On an edge of a turned beam');
  end;
end;

procedure TOrbGripTests.TestSeatedTheyGoWhereTheBeamGoes;
const
  Up = 40.0;
begin
  GripAll;
  var Before: TArray<Single> := [];
  for var Orb in AliveOrbs(FGrip.Flock) do
    Before := Before + [Orb.Y];
  for var i := 0 to High(FBeams) do
    FBeams[i].Middle.Y := FBeams[i].Middle.Y - Up;
  Tick;
  var Orbs := AliveOrbs(FGrip.Flock);
  for var i := 0 to High(Orbs) do
    Assert.AreEqual(Double(Before[i] - Up), Double(Orbs[i].Y), Slop, Format('Orb %d', [i]));
end;

procedure TOrbGripTests.TestSmallerThanTheRitesAndSwellOnAThump;
begin
  GripAll;
  var Orb := AliveOrbs(FGrip.Flock)[0];
  Assert.IsTrue(Orb.Size < 1, 'Smaller');
  var Calm := Orb.Size;
  Tick(1);
  Assert.IsTrue(Orb.Size > Calm, 'Swells');
end;

procedure TOrbGripTests.TestNoneIsArmed;
begin
  GripAll;
  for var Orb in FGrip.Flock.Orbs do
    Assert.IsFalse(Orb.Armed, 'Armed');
end;

procedure TOrbGripTests.TestABlownPadBurnsOutItsOwnOrbs;
const
  Blown = 1;
begin
  GripAll;
  var All := Length(AliveOrbs(FGrip.Flock));
  var Left := All - FGrip.Seats(Blown);
  FGrip.Burn(Blown);
  Assert.AreEqual(Left, Length(AliveOrbs(FGrip.Flock)), 'Its orbs out');
  for var i := 1 to ManyTicks do
    Tick;
  Assert.AreEqual(Left, FGrip.Flock.Orbs.Count, 'Burnt out, the rest still cling');
  Assert.AreEqual(Left, Length(AliveOrbs(FGrip.Flock)), 'None called again');
end;

procedure TOrbGripTests.TestADeathDrawsThemIn;
begin
  GripAll;
  FGrip.Collapse;
  Assert.AreEqual(0, Length(AliveOrbs(FGrip.Flock)), 'None alive');
  for var i := 1 to ManyTicks do
    Tick;
  Assert.AreEqual(0, Length(AliveOrbs(FGrip.Flock)), 'None called again');
end;

procedure TOrbGripTests.TestAClearTakesThemAll;
begin
  GripAll;
  FGrip.Clear;
  Assert.AreEqual(0, FGrip.Flock.Orbs.Count, 'No orb');
  Assert.AreEqual(0, FGrip.Count, 'No pad');
end;

{ TFacingPointTests }

procedure TFacingPointTests.TestThePointThatFacesTheTarget;
begin
  var Point := FacingPoint(Body, Chest, At(100, 330));
  Assert.AreEqual(436.0, Double(Point.X), Slop, 'To the left');
  Point := FacingPoint(Body, Chest, At(440, 20));
  Assert.AreEqual(322.0, Double(Point.Y), Slop, 'Up');
end;

procedure TFacingPointTests.TestNoBodyTheCenter;
begin
  var Point := FacingPoint([], Chest, At(100, 330));
  Assert.AreEqual(Double(Chest.X), Double(Point.X), Slop, 'Across');
  Assert.AreEqual(Double(Chest.Y), Double(Point.Y), Slop, 'Down');
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbGripTests);
  TDUnitX.RegisterTestFixture(TFacingPointTests);

end.
