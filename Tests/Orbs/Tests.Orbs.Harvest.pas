{
  Tests.Orbs.Harvest - where the orbs of the rite come from: HarvestAround
  gives the spots in waves, each wave from all sides of the hero, the first
  off the nearest faces and the last off the farthest, passing by what lies
  at his very feet and topping up from thin air what the matter is short
  of.

  The hero stands on the floor of a room walled on every side. The dice are
  seeded by the test. How evenly the spots scatter along a face is for the
  eye; HarvestSpots, the aura's harvest, has no test here yet.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Harvest;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TOrbHarvestTests = class
  public
    [Test]
    procedure TestAroundGivesEveryWaveItsCount;
    [Test]
    procedure TestAroundTakesNoSpotTwice;
    [Test]
    procedure TestAroundPassesByTheMatterAtTheHerosFeet;
    [Test]
    procedure TestAroundDrawsEveryWaveFromAllSides;
    [Test]
    procedure TestAroundGivesNearerFacesToEarlierWaves;
    [Test]
    procedure TestAroundOrdersAWaveByItsTurn;
    [Test]
    procedure TestAroundInAnEmptyRoomGivesSpotsInThinAir;
    [Test]
    procedure TestAroundTopsUpShortMatterWithAir;
    [Test]
    procedure TestAroundHarvestsABody;
    [Test]
    procedure TestAroundAwayAndTurnPointFromCenter;
    [Test]
    procedure TestAroundSameDiceGiveSameSpots;
  end;

implementation

uses
  System.SysUtils, Sdl2.Core, Render.Brush, Render.Sprites, Orbs.Harvest,
  Tests.Matter;

type
  TSpots = TArray<TFaceSpot>;
  // By wave, then by number in the wave: as HarvestAround gives them
  TWaveSpots = TArray<TArray<TFaceSpot>>;

const
  DiceSeed = 77;
  OtherDiceSeed = 1077;
  PerWave = 24;
  WaveCount = 3;
  PlaceSlack = 0.01; // units
  // The hero's middle as he stands on the floor of the walled room
  StandX = 256;
  StandY = 336;
  // A spot nearer his middle than this is passed by
  NearestAway = 34;
  // A spot in thin air stands this far from his middle
  AirNearest = 70;
  AirFarthest = 110;
  // Of the spots of a wave in the walled room, at least this many lie to
  // either side of him and above him: a quarter of the wave
  LeastToASide = 6;
  // Two spots nearer than this are one spot
  SameSpot = 0.5;

function Standing: TSdlFPoint;
begin
  Result.X := StandX;
  Result.Y := StandY;
end;

function AroundStanding(const AMatter: TMatter; ASeed: Cardinal): TWaveSpots;
var
  Dice: TXorShift;
begin
  Dice.Seed := ASeed;
  Result := HarvestAround(AMatter, Standing, PerWave, WaveCount, Dice);
end;

function Flattened(const AWaves: TWaveSpots): TSpots;
begin
  Result := nil;
  for var Wave in AWaves do
    Result := Result + Wave;
end;

function IsOnFace(const ASpot: TFaceSpot): Boolean;
begin
  Result := (ASpot.NormalX <> 0) or (ASpot.NormalY <> 0);
end;

function Apart(const ALeft, ARight: TFaceSpot): Single;
begin
  Result := Sqrt(Sqr(ALeft.X - ARight.X) + Sqr(ALeft.Y - ARight.Y));
end;

function MeanAway(const AWave: TSpots): Single;
begin
  Result := 0;
  for var Spot in AWave do
    Result := Result + Spot.Away / Length(AWave);
end;

// The spot lies on the outline of the box
function IsOnOutline(const ASpot: TFaceSpot; const ABox: TSdlFRect): Boolean;
begin
  var IsWithin := (ASpot.X > ABox.X - PlaceSlack) and
    (ASpot.X < ABox.X + ABox.W + PlaceSlack) and
    (ASpot.Y > ABox.Y - PlaceSlack) and
    (ASpot.Y < ABox.Y + ABox.H + PlaceSlack);
  var IsOnSide := (Abs(ASpot.X - ABox.X) < PlaceSlack) or
    (Abs(ASpot.X - ABox.X - ABox.W) < PlaceSlack);
  var IsOnDeck := (Abs(ASpot.Y - ABox.Y) < PlaceSlack) or
    (Abs(ASpot.Y - ABox.Y - ABox.H) < PlaceSlack);
  var IsOnEdge := IsOnSide or IsOnDeck;
  Result := IsWithin and IsOnEdge;
end;

function BoxAt(AX, AY, AWidth, AHeight: Single): TSdlFRect;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.W := AWidth;
  Result.H := AHeight;
end;

procedure TOrbHarvestTests.TestAroundGivesEveryWaveItsCount;
const
  FewPerWave = 10;
  FewWaves = 2;
var
  Dice: TXorShift;
begin
  Dice.Seed := DiceSeed;
  var Waves := HarvestAround(WalledMatter, Standing, PerWave, WaveCount, Dice);
  Assert.AreEqual(WaveCount, Integer(Length(Waves)), 'Waves asked for');
  for var Wave in Waves do
    Assert.AreEqual(PerWave, Integer(Length(Wave)), 'Spots of a wave');

  Waves := HarvestAround(WalledMatter, Standing, FewPerWave, FewWaves, Dice);
  Assert.AreEqual(FewWaves, Integer(Length(Waves)), 'Fewer waves asked for');
  for var Wave in Waves do
    Assert.AreEqual(FewPerWave, Integer(Length(Wave)),
      'Spots of a smaller wave');
end;

procedure TOrbHarvestTests.TestAroundTakesNoSpotTwice;
begin
  var Spots := Flattened(AroundStanding(WalledMatter, DiceSeed));

  for var i := 0 to High(Spots) do
    for var j := i + 1 to High(Spots) do
      Assert.IsTrue(Apart(Spots[i], Spots[j]) > SameSpot,
        Format('Spots %d and %d are one spot', [i, j]));
end;

procedure TOrbHarvestTests.TestAroundPassesByTheMatterAtTheHerosFeet;
begin
  var Spots := Flattened(AroundStanding(WalledMatter, DiceSeed));

  for var Spot in Spots do
  begin
    Assert.IsTrue(IsOnFace(Spot),
      'A room full of matter gave a spot in thin air');
    Assert.IsTrue(Spot.Away >= NearestAway,
      Format('A spot %g units from the hero was taken', [Spot.Away]));
  end;
end;

procedure TOrbHarvestTests.TestAroundDrawsEveryWaveFromAllSides;
begin
  var Waves := AroundStanding(WalledMatter, DiceSeed);

  for var Wave in Waves do
  begin
    var ToTheLeft := 0;
    var ToTheRight := 0;
    var Above := 0;
    for var Spot in Wave do
    begin
      if Spot.X < StandX then
        Inc(ToTheLeft);
      if Spot.X > StandX then
        Inc(ToTheRight);
      if Spot.Y < StandY then
        Inc(Above);
    end;
    var IsFromAllSides := (ToTheLeft >= LeastToASide) and
      (ToTheRight >= LeastToASide) and (Above >= LeastToASide);
    Assert.IsTrue(IsFromAllSides,
      Format('A wave has %d spots to the left, %d to the right, %d above',
      [ToTheLeft, ToTheRight, Above]));
  end;
end;

procedure TOrbHarvestTests.TestAroundGivesNearerFacesToEarlierWaves;
begin
  var Waves := AroundStanding(WalledMatter, DiceSeed);

  var First := MeanAway(Waves[0]);
  var Second := MeanAway(Waves[1]);
  var Third := MeanAway(Waves[2]);
  Assert.IsTrue((First < Second) and (Second < Third),
    Format('The waves lie %g, %g and %g units away on average',
    [First, Second, Third]));
end;

procedure TOrbHarvestTests.TestAroundOrdersAWaveByItsTurn;
begin
  var Waves := AroundStanding(WalledMatter, DiceSeed);

  for var Wave in Waves do
    for var i := 1 to High(Wave) do
      Assert.IsTrue(Wave[i].Turn >= Wave[i - 1].Turn,
        Format('Spot %d of a wave comes before its turn', [i]));
end;

procedure TOrbHarvestTests.TestAroundInAnEmptyRoomGivesSpotsInThinAir;
begin
  var Spots := Flattened(AroundStanding(EmptyMatter, DiceSeed));

  Assert.AreEqual(WaveCount * PerWave, Integer(Length(Spots)));
  for var Spot in Spots do
  begin
    Assert.IsFalse(IsOnFace(Spot), 'A spot in thin air has a normal');
    var IsInTheRing := (Spot.Away > AirNearest - PlaceSlack) and
      (Spot.Away < AirFarthest + PlaceSlack);
    Assert.IsTrue(IsInTheRing,
      Format('A spot in thin air stands %g units away', [Spot.Away]));
  end;
end;

procedure TOrbHarvestTests.TestAroundTopsUpShortMatterWithAir;
const
  LoneCol = 3;
  LoneRow = 3;
  // A cell has four faces of four stretches
  CellSpots = 16;
begin
  var Matter := EmptyMatter;
  Matter.Cells[LoneRow, LoneCol] := True;
  var Cell := BoxAt(LoneCol * TileSize, LoneRow * TileSize, TileSize,
    TileSize);

  var Waves := AroundStanding(Matter, DiceSeed);

  var OnFaces := 0;
  for var Spot in Flattened(Waves) do
  begin
    if not IsOnFace(Spot) then
      Continue;
    Inc(OnFaces);
    Assert.IsTrue(IsOnOutline(Spot, Cell), 'A face spot is off the lone cell');
  end;
  var IsCellUsed := (OnFaces > 0) and (OnFaces <= CellSpots);
  Assert.IsTrue(IsCellUsed, Format('The lone cell gave %d spots', [OnFaces]));

  for var Wave in Waves do
    Assert.AreEqual(PerWave, Integer(Length(Wave)),
      'A wave short of matter is short of spots');
  var LaterSpots := Waves[1] + Waves[2];
  for var Spot in LaterSpots do
    Assert.IsFalse(IsOnFace(Spot),
      'The first wave took air and left matter to a later one');
end;

procedure TOrbHarvestTests.TestAroundHarvestsABody;
begin
  var Pad := BoxAt(64, 96, 64, 32);
  var Matter := EmptyMatter;
  Matter.Bodies := [Pad];

  var Spots := Flattened(AroundStanding(Matter, DiceSeed));

  var OnFaces := 0;
  for var Spot in Spots do
  begin
    if not IsOnFace(Spot) then
      Continue;
    Inc(OnFaces);
    Assert.IsTrue(IsOnOutline(Spot, Pad), 'A face spot is off the body');
  end;
  Assert.IsTrue(OnFaces > 0, 'A body gave no spots');
end;

procedure TOrbHarvestTests.TestAroundAwayAndTurnPointFromCenter;
begin
  var Spots := Flattened(AroundStanding(WalledMatter, DiceSeed));

  for var Spot in Spots do
  begin
    var PointedX: Single := StandX + Spot.Away * Cos(Spot.Turn);
    var PointedY: Single := StandY + Spot.Away * Sin(Spot.Turn);
    var IsThere := (Abs(PointedX - Spot.X) < PlaceSlack) and
      (Abs(PointedY - Spot.Y) < PlaceSlack);
    Assert.IsTrue(IsThere,
      Format('Away and Turn point at (%g, %g), the spot is at (%g, %g)',
      [PointedX, PointedY, Spot.X, Spot.Y]));
  end;
end;

procedure TOrbHarvestTests.TestAroundSameDiceGiveSameSpots;
begin
  var Spots := Flattened(AroundStanding(WalledMatter, DiceSeed));
  var Again := Flattened(AroundStanding(WalledMatter, DiceSeed));
  var Others := Flattened(AroundStanding(WalledMatter, OtherDiceSeed));

  var Differing := 0;
  for var i := 0 to High(Spots) do
  begin
    var IsSame := (Spots[i].X = Again[i].X) and (Spots[i].Y = Again[i].Y) and
      (Spots[i].NormalX = Again[i].NormalX) and
      (Spots[i].NormalY = Again[i].NormalY);
    Assert.IsTrue(IsSame, Format('Spot %d differs on the same dice', [i]));
    if Apart(Spots[i], Others[i]) > SameSpot then
      Inc(Differing);
  end;
  Assert.IsTrue(Differing > 0, 'Other dice gave the same spots');
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbHarvestTests);

end.
