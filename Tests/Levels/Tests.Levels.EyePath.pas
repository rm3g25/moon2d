{
  Tests.Levels.EyePath - the way of the eye in the titles' flight, over
  the path of the day the tests were written, so tuning the shipped file
  breaks nothing here. The cubic passes through every key, stands at its
  first key before it and at its last after it, and between two keys never
  leaves what lies between them. A key placed from where the world stood
  follows the stand, one placed along the strip does not, and none takes
  the eye to the right: after a short fight the eye waits where the world
  stood for the keys that lie to its left. The eye flies as the stand flies
  it, number for number. It keeps its rest till the last key at rest;
  the steepest bank is told either way; no path - the eye stands.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.EyePath;

interface

uses
  DUnitX.TestFramework,
  Levels.EyePath;

type
  [TestFixture]
  TEyePathTests = class
  private
    FPath: TEyePath;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestThroughEveryKey;
    [Test]
    procedure TestStandsAtItsEnds;
    [Test]
    procedure TestBetweenTwoKeysNeverPastEither;
    [Test]
    procedure TestAKeyFromTheStandFollowsTheStand;
    [Test]
    procedure TestAKeyAlongTheStripDoesNotFollowTheStand;
    [Test]
    procedure TestTheEyeNeverFliesToTheRight;
    [Test]
    procedure TestAfterAShortFightTheEyeWaitsWhereTheWorldStood;
    [Test]
    procedure TestFliesAsTheStandFliesIt;
    [Test]
    procedure TestKeepsItsRestTillTheLastKeyAtRest;
    [Test]
    procedure TestAPathAllAtRestRestsToItsEnd;
    [Test]
    procedure TestAPathLiftedFromItsFirstKeyNeverRests;
    [Test]
    procedure TestTheSteepestBankEitherWay;
    [Test]
    procedure TestNoPathTheEyeStands;
  end;

implementation

const
  Slack = 0.000001;
  // The numbers of the stand are told to six places
  StandSlack = 0.000002;
  // Where the world stands after a fight of 220 s, and after one of 60 s
  LongFightStand = 2412;
  ShortFightStand = 1492;
  // The second the eye leaves its rest at
  StandRestTill = 12.7;
  StandSteepestBank = 14;
  // bin/finale.json of the day: the cast-off, the pan, the turn into the
  // main dome, the sign, the rib, the climb
  StandKeys: array [0..17] of TEyeKey = (
    (Seconds: 0; Placing: epStand; Place: 0; Lift: 0; Push: 0; Bank: 0; Pitch: 0),
    (Seconds: 6.34; Placing: epFromStand; Place: -45; Lift: 0; Push: 0; Bank: 0; Pitch: 0),
    (Seconds: 8.43; Placing: epFromStand; Place: -200; Lift: 0; Push: 0; Bank: 0; Pitch: 0),
    (Seconds: 11.6; Placing: epAlong; Place: 1730; Lift: 0; Push: 0; Bank: 0; Pitch: 0),
    (Seconds: 12.7; Placing: epAlong; Place: 1554; Lift: 0; Push: 0; Bank: 0; Pitch: 0),
    (Seconds: 14.84; Placing: epAlong; Place: 1215; Lift: 2; Push: 25; Bank: 0; Pitch: 0),
    (Seconds: 16.97; Placing: epAlong; Place: 925; Lift: 12; Push: 190; Bank: 0; Pitch: 0),
    (Seconds: 19.11; Placing: epAlong; Place: 808; Lift: 44; Push: 540; Bank: 0; Pitch: 0),
    (Seconds: 20.7; Placing: epAlong; Place: 776; Lift: 72; Push: 800; Bank: 0; Pitch: 0),
    (Seconds: 21.25; Placing: epAlong; Place: 769; Lift: 80.5; Push: 890; Bank: 0; Pitch: 0),
    (Seconds: 22.3; Placing: epAlong; Place: 762; Lift: 92; Push: 1054; Bank: 5; Pitch: 0),
    (Seconds: 23.2; Placing: epAlong; Place: 760; Lift: 97; Push: 1187; Bank: 14; Pitch: 0),
    (Seconds: 24.6; Placing: epAlong; Place: 757; Lift: 140; Push: 1370; Bank: 10; Pitch: 0),
    (Seconds: 26; Placing: epAlong; Place: 755; Lift: 210; Push: 1490; Bank: 6; Pitch: 0),
    (Seconds: 27.6; Placing: epAlong; Place: 754; Lift: 310; Push: 1570; Bank: 2.5; Pitch: 3),
    (Seconds: 29.2; Placing: epAlong; Place: 754; Lift: 420; Push: 1620; Bank: 0.5; Pitch: 7),
    (Seconds: 31; Placing: epAlong; Place: 754; Lift: 560; Push: 1650; Bank: 0; Pitch: 13),
    (Seconds: 32.6; Placing: epAlong; Place: 754; Lift: 680; Push: 1665; Bank: 0; Pitch: 20));
  // The place of the cast-off's end among the keys: so far from the stand
  CastOffKey = 1;
  CastOffWay = -45;
  // The first key placed along the strip
  FirstAlongKey = 3;

function Matches(AValue, AExpected, ASlack: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < ASlack;
end;

function PathOf(const AKeys: array of TEyeKey): TEyePath;
begin
  Result := Default(TEyePath);
  SetLength(Result.Keys, Length(AKeys));
  for var i := 0 to High(AKeys) do
    Result.Keys[i] := AKeys[i];
end;

// A key at the stand, lifted ALift and banked ABank
function KeyAt(ASeconds, ALift, ABank: Double): TEyeKey;
begin
  Result := Default(TEyeKey);
  Result.Seconds := ASeconds;
  Result.Lift := ALift;
  Result.Bank := ABank;
end;

procedure TEyePathTests.Setup;
begin
  FPath := PathOf(StandKeys);
end;

procedure TEyePathTests.TestThroughEveryKey;
begin
  for var i := FirstAlongKey to High(StandKeys) do
  begin
    var Key := StandKeys[i];
    var Eye := FPath.EyeAt(Key.Seconds, LongFightStand);
    Assert.IsTrue(Matches(Eye.Along, Key.Place, Slack), 'Along the strip');
    Assert.IsTrue(Matches(Eye.Lift, Key.Lift, Slack), 'The lift');
    Assert.IsTrue(Matches(Eye.Push, Key.Push, Slack), 'The push');
    Assert.IsTrue(Matches(Eye.Bank, Key.Bank, Slack), 'The bank');
    Assert.IsTrue(Matches(Eye.Pitch, Key.Pitch, Slack), 'The pitch');
  end;
end;

procedure TEyePathTests.TestStandsAtItsEnds;
begin
  var Last := StandKeys[High(StandKeys)];
  var Before := FPath.EyeAt(-5, LongFightStand);
  var After := FPath.EyeAt(Last.Seconds + 60, LongFightStand);
  Assert.IsTrue(Matches(Before.Along, LongFightStand, Slack), 'Before: where the world stood');
  Assert.IsTrue(Matches(Before.Lift, 0, Slack), 'Before: at its rest');
  Assert.IsTrue(Matches(After.Along, Last.Place, Slack), 'After: at the last key''s place');
  Assert.IsTrue(Matches(After.Lift, Last.Lift, Slack), 'After: at the last key''s lift');
  Assert.IsTrue(Matches(After.Pitch, Last.Pitch, Slack), 'After: at the last key''s pitch');
end;

procedure TEyePathTests.TestBetweenTwoKeysNeverPastEither;
const
  Steps = 20;
begin
  for var i := 0 to High(StandKeys) - 1 do
  begin
    var From := StandKeys[i];
    var Till := StandKeys[i + 1];
    for var j := 1 to Steps - 1 do
    begin
      var Seconds: Double := From.Seconds + (Till.Seconds - From.Seconds) * j / Steps;
      var Eye := FPath.EyeAt(Seconds, LongFightStand);
      Assert.IsTrue((Eye.Lift >= From.Lift - Slack) and (Eye.Lift <= Till.Lift + Slack),
        'The lift between its two keys');
      Assert.IsTrue((Eye.Push >= From.Push - Slack) and (Eye.Push <= Till.Push + Slack),
        'The push between its two keys');
    end;
  end;
end;

procedure TEyePathTests.TestAKeyFromTheStandFollowsTheStand;
begin
  var Seconds := StandKeys[CastOffKey].Seconds;
  var Long := FPath.EyeAt(Seconds, LongFightStand);
  var Short := FPath.EyeAt(Seconds, ShortFightStand);
  Assert.IsTrue(Matches(Long.Along, LongFightStand + CastOffWay, Slack), 'A long fight');
  Assert.IsTrue(Matches(Short.Along, ShortFightStand + CastOffWay, Slack), 'A short one');
end;

procedure TEyePathTests.TestAKeyAlongTheStripDoesNotFollowTheStand;
const
  Nearer = 2300;
begin
  var Key := StandKeys[FirstAlongKey];
  var Long := FPath.EyeAt(Key.Seconds, LongFightStand);
  var Other := FPath.EyeAt(Key.Seconds, Nearer);
  Assert.IsTrue(Matches(Long.Along, Key.Place, Slack), 'The place of the strip');
  Assert.IsTrue(Matches(Other.Along, Key.Place, Slack), 'From another stand, the same');
end;

procedure TEyePathTests.TestTheEyeNeverFliesToTheRight;
const
  StepSeconds = 0.05;
  Stands: array [0..1] of Double = (LongFightStand, ShortFightStand);
begin
  var Last := StandKeys[High(StandKeys)].Seconds;
  for var Stand in Stands do
  begin
    var Along: Double := Stand;
    var Seconds: Double := 0;
    while Seconds <= Last do
    begin
      var Flown: Double := FPath.EyeAt(Seconds, Stand).Along;
      Assert.IsTrue(Flown <= Along + Slack, 'Never to the right of where it was');
      Along := Flown;
      Seconds := Seconds + StepSeconds;
    end;
  end;
end;

// The short fight's world stands left of the pan's landmarks: the eye goes
// its cast-off and waits there for the keys of the main dome
procedure TEyePathTests.TestAfterAShortFightTheEyeWaitsWhereTheWorldStood;
const
  PanEnd = 8.43;
  PanEndWay = -200;
  TurnBegins = 12.7;
  // The first key left of where the short fight's cast-off ends
  LeftAgain = 14.84;
  LeftAgainPlace = 1215;
begin
  var Held: Double := ShortFightStand + PanEndWay;
  Assert.IsTrue(Matches(FPath.EyeAt(PanEnd, ShortFightStand).Along, Held, Slack),
    'The cast-off, as after any fight');
  Assert.IsTrue(Matches(FPath.EyeAt(TurnBegins, ShortFightStand).Along, Held, Slack),
    'Held there: the landmarks lie to the right');
  Assert.IsTrue(Matches(FPath.EyeAt(LeftAgain, ShortFightStand).Along, LeftAgainPlace, Slack),
    'On, once a key lies to the left');
end;

// eyeAt of tools/chase/stand.template.html over these keys, the world
// standing at 2412
procedure TEyePathTests.TestFliesAsTheStandFliesIt;
const
  // Seconds, along the strip
  StandAlong: array [0..5, 0..1] of Double = (
    (3, 2402.557153), (5, 2384.717171), (7.5, 2301.20833), (10, 1996.911178),
    (12, 1666.489819), (12.7, 1554));
  // Seconds, lift, push, bank, pitch
  StandTurns: array [0..3, 0..4] of Double = (
    (13.5, 0.337459, 4.064931, 0, 0),
    (16, 5.987421, 93.158723, 0, 0),
    (22.8, 94.530944, 1129.323656, 10.889961, 0),
    (30, 481.301981, 1635.552771, 0.177844, 9.456155));
begin
  for var i := 0 to High(StandAlong) do
  begin
    var Eye := FPath.EyeAt(StandAlong[i, 0], LongFightStand);
    Assert.IsTrue(Matches(Eye.Along, StandAlong[i, 1], StandSlack), 'Along the strip');
  end;
  for var i := 0 to High(StandTurns) do
  begin
    var Eye := FPath.EyeAt(StandTurns[i, 0], LongFightStand);
    Assert.IsTrue(Matches(Eye.Lift, StandTurns[i, 1], StandSlack), 'The lift');
    Assert.IsTrue(Matches(Eye.Push, StandTurns[i, 2], StandSlack), 'The push');
    Assert.IsTrue(Matches(Eye.Bank, StandTurns[i, 3], StandSlack), 'The bank');
    Assert.IsTrue(Matches(Eye.Pitch, StandTurns[i, 4], StandSlack), 'The pitch');
  end;
end;

procedure TEyePathTests.TestKeepsItsRestTillTheLastKeyAtRest;
const
  StepSeconds = 0.1;
begin
  Assert.IsTrue(Matches(FPath.RestTill, StandRestTill, Slack), 'The last key of the pan');
  var Seconds: Double := 0;
  while Seconds <= FPath.RestTill do
  begin
    var Eye := FPath.EyeAt(Seconds, LongFightStand);
    var AtRest := (Eye.Lift = 0) and (Eye.Push = 0) and (Eye.Bank = 0) and (Eye.Pitch = 0);
    Assert.IsTrue(AtRest, 'At its rest all the way');
    Seconds := Seconds + StepSeconds;
  end;
end;

procedure TEyePathTests.TestAPathAllAtRestRestsToItsEnd;
const
  Ends = 9;
begin
  var Path := PathOf([KeyAt(0, 0, 0), KeyAt(4, 0, 0), KeyAt(Ends, 0, 0)]);
  Assert.IsTrue(Matches(Path.RestTill, Ends, Slack), 'Its last key');
end;

procedure TEyePathTests.TestAPathLiftedFromItsFirstKeyNeverRests;
begin
  var Path := PathOf([KeyAt(0, 5, 0), KeyAt(4, 0, 0)]);
  Assert.IsTrue(Matches(Path.RestTill, 0, Slack), 'No second at rest');
end;

procedure TEyePathTests.TestTheSteepestBankEitherWay;
const
  LeftWingUp = -20;
begin
  Assert.IsTrue(Matches(FPath.SteepestBank, StandSteepestBank, Slack), 'The path of the day');
  var Path := PathOf([KeyAt(0, 0, 0), KeyAt(4, 0, LeftWingUp), KeyAt(8, 0, 5)]);
  Assert.IsTrue(Matches(Path.SteepestBank, -LeftWingUp, Slack), 'The other wing down counts');
end;

procedure TEyePathTests.TestNoPathTheEyeStands;
begin
  var Path := Default(TEyePath);
  Assert.IsFalse(Path.Present, 'No keys, no path');
  Assert.IsFalse(PathOf([KeyAt(0, 0, 0)]).Present, 'One key is no path');
  var Eye := Path.EyeAt(10, LongFightStand);
  Assert.IsTrue(Matches(Eye.Along, LongFightStand, Slack), 'Where the world stood');
  Assert.IsTrue(Matches(Eye.Lift, 0, Slack), 'At its rest');
end;

initialization
  TDUnitX.RegisterTestFixture(TEyePathTests);

end.
