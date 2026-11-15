{
  Tests.Levels.Titles - the titles of a level as data: a level without the
  section has none; the file it names must be there and must read; its
  cues are read as written; a cue that does not come after the one before
  it raises. Titles without a path do not fly; a path is read as written,
  each key placed where the world stood, from there or along the strip; a
  path wants its flight's cue after the flash, two keys at the least and
  each after the one before it. Titles that fly read the flight's own cues
  - the sign's and the flare's - and want them in the flight, the flare
  after the sign. A path is flown to its last key, or short of it as far as
  the file says, and one flown nowhere raises. The file level 2 ships
  reads, and flies to its last key.

  Titles that end at the stars read their cues and the track's length as
  written; a cue of theirs not after the one before it raises, and so do
  a track that ends before the last screen and stars without a flight.
  Titles that fly with no stars have their last screen where the path is
  flown. The file level 2 ships ends at the stars.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Titles;

interface

uses
  DUnitX.TestFramework,
  Levels.EyePath, Levels.Titles;

type
  [TestFixture]
  TTitlesReadTests = class
  public
    [Test]
    procedure TestNoSectionNoTitles;
    [Test]
    procedure TestAMissingFileRaises;
    [Test]
    procedure TestAFileThatDoesNotReadRaises;
    [Test]
    procedure TestTheCuesAreReadAsWritten;
    [Test]
    procedure TestACueNotAfterTheOneBeforeItRaises;
    [Test]
    procedure TestTheFileOfLevelTwoReads;
    [Test]
    procedure TestWithoutAPathTheTitlesDoNotFly;
    [Test]
    procedure TestThePathIsReadAsWritten;
    [Test]
    procedure TestAPathWithoutItsFlightsCueRaises;
    [Test]
    procedure TestAFlightNotAfterTheFlashRaises;
    [Test]
    procedure TestAPathOfOneKeyRaises;
    [Test]
    procedure TestAKeyNotAfterTheOneBeforeItRaises;
    [Test]
    procedure TestAPathIsFlownToItsLastKey;
    [Test]
    procedure TestAPathMayBeFlownShortOfItsEnd;
    [Test]
    procedure TestAPathFlownNowhereRaises;
    [Test]
    procedure TestTheFileOfLevelTwoFlies;
    [Test]
    procedure TestTheFlightsOwnCuesAreRead;
    [Test]
    procedure TestASignNotInTheFlightRaises;
    [Test]
    procedure TestAFlareNotAfterTheSignRaises;
    [Test]
    procedure TestTheStarsCuesAndTheTrackAreRead;
    [Test]
    procedure TestAStarsCueNotAfterTheOneBeforeItRaises;
    [Test]
    procedure TestATrackEndingBeforeTheLastScreenRaises;
    [Test]
    procedure TestStarsWithoutAFlightRaise;
    [Test]
    procedure TestWithoutTheStarsTheLastScreenComesAsThePathIsFlown;
    [Test]
    procedure TestTheFileOfLevelTwoEndsAtTheStars;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON;

const
  Slack = 0.0001;
  ShippedFile = 'finale.json';
  GoodCues = '"card": 10, "cardOut": 16, "flash": 17';
  FlyingCues = GoodCues + ', "flight": 19, "neon": 20, "flare": 22';
  // Where the world stood; so far from there, lifted; a place of the strip,
  // pushed, banked and pitched
  GoodKeys = '{"t": 0, "x": null, "y": 0, "z": 0, "bank": 0, "pitch": 0},'
    + '{"t": 4, "dx": -45, "y": 2, "z": 0, "bank": 0, "pitch": 0},'
    + '{"t": 9.5, "x": 1730, "y": 0, "z": 25, "bank": 5, "pitch": 3}';
  // The band of level 2's end track comes in on this second
  ShippedFlash = 17.21;
  StarsCues = FlyingCues + ', "stars": 30, "still": 40, "mission": 41, '
    + '"promise": 43, "credits": 47, "last": 56';

function BinDir: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

function TitlesFile(const ACues: string): string;
begin
  Result := '{"cues": {' + ACues + '}}';
end;

function FlyingTitlesFile(const ACues, AKeys: string): string;
begin
  Result := '{"cues": {' + ACues + '}, "path": {"keys": [' + AKeys + ']}}';
end;

// The same, its path flown as far as the second AFlownTill
function ShortFlownFile(const AFlownTill: string): string;
begin
  Result := '{"cues": {' + FlyingCues + '}, "path": {"flownTill": ' + AFlownTill
    + ', "keys": [' + GoodKeys + ']}}';
end;

// Flying titles that end at the stars, ACues theirs, the track ATrack
// long
function StarsFile(const ACues, ATrack: string): string;
begin
  Result := '{"track": {"seconds": ' + ATrack + '}, "cues": {' + ACues
    + '}, "path": {"keys": [' + GoodKeys + ']}}';
end;

// The titles of a level whose section names AFile in ADir
function ReadNamed(const AFile, ADir: string): TTitlesDef;
begin
  var Root := TJSONObject.ParseJSONValue(
    '{"titles": {"file": "' + AFile + '"}}') as TJSONObject;
  try
    Result := ReadTitles(Root, 'test', ADir);
  finally
    Root.Free;
  end;
end;

// The titles read from a file of AText
function ReadFromText(const AText: string): TTitlesDef;
begin
  var Dir := TPath.GetTempPath;
  var Name := 'moon2d-titles-' + TGUID.NewGuid.ToString + '.json';
  TFile.WriteAllText(TPath.Combine(Dir, Name), AText, TEncoding.ASCII);
  try
    Result := ReadNamed(Name, Dir);
  finally
    TFile.Delete(TPath.Combine(Dir, Name));
  end;
end;

procedure TTitlesReadTests.TestNoSectionNoTitles;
begin
  var Root := TJSONObject.Create;
  try
    Assert.IsFalse(ReadTitles(Root, 'test', BinDir).Present);
  finally
    Root.Free;
  end;
end;

procedure TTitlesReadTests.TestAMissingFileRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadNamed('no-such-titles.json', BinDir);
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestAFileThatDoesNotReadRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText('not a file of titles');
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestTheCuesAreReadAsWritten;
begin
  var Titles := ReadFromText(TitlesFile(GoodCues));
  Assert.IsTrue(Titles.Present, 'Read');
  Assert.AreEqual(10.0, Titles.Cues.Card, Slack, 'The card');
  Assert.AreEqual(16.0, Titles.Cues.CardOut, Slack, 'The card out');
  Assert.AreEqual(17.0, Titles.Cues.Flash, Slack, 'The flash');
end;

procedure TTitlesReadTests.TestACueNotAfterTheOneBeforeItRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(TitlesFile('"card": 10, "cardOut": 16, "flash": 15'));
    end, ETitlesError, 'The flash before the card is out');
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(TitlesFile('"card": 10, "cardOut": 10, "flash": 17'));
    end, ETitlesError, 'A card out as it comes in');
end;

procedure TTitlesReadTests.TestTheFileOfLevelTwoReads;
begin
  var Titles := ReadNamed(ShippedFile, BinDir);
  Assert.IsTrue(Titles.Present, 'Read');
  Assert.AreEqual(ShippedFlash, Titles.Cues.Flash, Slack, 'The band comes in');
end;

procedure TTitlesReadTests.TestWithoutAPathTheTitlesDoNotFly;
begin
  var Titles := ReadFromText(TitlesFile(GoodCues));
  Assert.IsTrue(Titles.Present, 'Read');
  Assert.IsFalse(Titles.Flies, 'The card and the logo are all of them');
end;

procedure TTitlesReadTests.TestThePathIsReadAsWritten;
begin
  var Titles := ReadFromText(FlyingTitlesFile(FlyingCues, GoodKeys));
  Assert.IsTrue(Titles.Flies, 'Flies');
  Assert.IsTrue(Abs(Titles.Cues.Flight - 19) < Slack, 'The flight''s cue');
  Assert.AreEqual(3, Integer(Length(Titles.Path.Keys)), 'Its keys');

  var Stands := Titles.Path.Keys[0];
  Assert.IsTrue(Stands.Placing = epStand, 'A null: where the world stood');
  Assert.IsTrue(Abs(Stands.Seconds) < Slack, 'Its second');

  var FromStand := Titles.Path.Keys[1];
  Assert.IsTrue(FromStand.Placing = epFromStand, 'A dx: from where it stood');
  Assert.IsTrue(Abs(FromStand.Place + 45) < Slack, 'So far to the left');
  Assert.IsTrue(Abs(FromStand.Lift - 2) < Slack, 'Its lift');

  var Along := Titles.Path.Keys[2];
  Assert.IsTrue(Along.Placing = epAlong, 'An x: along the strip');
  Assert.IsTrue(Abs(Along.Seconds - 9.5) < Slack, 'Its second');
  Assert.IsTrue(Abs(Along.Place - 1730) < Slack, 'Its place');
  Assert.IsTrue(Abs(Along.Push - 25) < Slack, 'Its push');
  Assert.IsTrue(Abs(Along.Bank - 5) < Slack, 'Its bank');
  Assert.IsTrue(Abs(Along.Pitch - 3) < Slack, 'Its pitch');
end;

procedure TTitlesReadTests.TestAPathWithoutItsFlightsCueRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(FlyingTitlesFile(GoodCues, GoodKeys));
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestAFlightNotAfterTheFlashRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(FlyingTitlesFile(GoodCues + ', "flight": 17', GoodKeys));
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestAPathOfOneKeyRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(FlyingTitlesFile(FlyingCues, '{"t": 0, "x": null}'));
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestAKeyNotAfterTheOneBeforeItRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(FlyingTitlesFile(FlyingCues,
        '{"t": 0, "x": null}, {"t": 4, "dx": -45}, {"t": 4, "x": 1730}'));
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestAPathIsFlownToItsLastKey;
begin
  var Titles := ReadFromText(FlyingTitlesFile(FlyingCues, GoodKeys));
  Assert.IsTrue(Abs(Titles.FlightTill - 9.5) < Slack, 'The second of its last key');
end;

procedure TTitlesReadTests.TestAPathMayBeFlownShortOfItsEnd;
begin
  var Titles := ReadFromText(ShortFlownFile('6.5'));
  Assert.IsTrue(Abs(Titles.FlightTill - 6.5) < Slack, 'As far as the file says');
  Assert.AreEqual(3, Integer(Length(Titles.Path.Keys)), 'All of its keys read');
end;

procedure TTitlesReadTests.TestAPathFlownNowhereRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(ShortFlownFile('0'));
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestTheFileOfLevelTwoFlies;
begin
  var Titles := ReadNamed(ShippedFile, BinDir);
  Assert.IsTrue(Titles.Flies, 'A path');
  Assert.IsTrue(Titles.Cues.Flight > Titles.Cues.Flash,
    'The camera leaves a logo that has flared');
  Assert.IsTrue(Titles.Path.Keys[0].Placing = epStand, 'From where the world stood');
  Assert.IsTrue(Titles.Path.RestTill > 0, 'It leaves along the strip, at its rest');
  var LastKey := Titles.Path.Keys[High(Titles.Path.Keys)].Seconds;
  Assert.IsTrue(Abs(Titles.FlightTill - LastKey) < Slack, 'Flown to its last key');
end;

procedure TTitlesReadTests.TestTheFlightsOwnCuesAreRead;
begin
  var Titles := ReadFromText(FlyingTitlesFile(FlyingCues, GoodKeys));
  Assert.IsTrue(Abs(Titles.Cues.Neon - 20) < Slack, 'The sign''s');
  Assert.IsTrue(Abs(Titles.Cues.Flare - 22) < Slack, 'The flare''s');
end;

procedure TTitlesReadTests.TestASignNotInTheFlightRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(FlyingTitlesFile(GoodCues + ', "flight": 19, "flare": 22', GoodKeys));
    end, ETitlesError, 'No sign''s cue');
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(FlyingTitlesFile(GoodCues + ', "flight": 19, "neon": 19, "flare": 22',
        GoodKeys));
    end, ETitlesError, 'The sign as the camera leaves');
end;

procedure TTitlesReadTests.TestAFlareNotAfterTheSignRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(FlyingTitlesFile(GoodCues + ', "flight": 19, "neon": 20, "flare": 20',
        GoodKeys));
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestTheStarsCuesAndTheTrackAreRead;
begin
  var Titles := ReadFromText(StarsFile(StarsCues, '238'));
  Assert.IsTrue(Titles.EndsAtTheStars, 'At the stars');
  Assert.IsTrue(Abs(Titles.Cues.Stars - 30) < Slack, 'The sky');
  Assert.IsTrue(Abs(Titles.Cues.Still - 40) < Slack, 'Its rest');
  Assert.IsTrue(Abs(Titles.Cues.Mission - 41) < Slack, 'The mission');
  Assert.IsTrue(Abs(Titles.Cues.Promise - 43) < Slack, 'The promise');
  Assert.IsTrue(Abs(Titles.Cues.Credits - 47) < Slack, 'The credits');
  Assert.IsTrue(Abs(Titles.Cues.Last - 56) < Slack, 'The last screen');
  Assert.IsTrue(Abs(Titles.TrackSeconds - 238) < Slack, 'The track''s length');
end;

procedure TTitlesReadTests.TestAStarsCueNotAfterTheOneBeforeItRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(StarsFile(FlyingCues + ', "stars": 22, "still": 40, "mission": 41, '
        + '"promise": 43, "credits": 47, "last": 56', '238'));
    end, ETitlesError, 'The sky with the flare');
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(StarsFile(FlyingCues + ', "stars": 30, "still": 40, "mission": 41, '
        + '"promise": 41, "credits": 47, "last": 56', '238'));
    end, ETitlesError, 'The promise with the mission');
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(StarsFile(FlyingCues + ', "stars": 30, "still": 40, "mission": 41, '
        + '"promise": 43, "credits": 47', '238'));
    end, ETitlesError, 'No last screen');
end;

procedure TTitlesReadTests.TestATrackEndingBeforeTheLastScreenRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(StarsFile(StarsCues, '50'));
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestStarsWithoutAFlightRaise;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromText(TitlesFile(GoodCues + ', "stars": 30, "still": 40, "mission": 41, '
        + '"promise": 43, "credits": 47, "last": 56'));
    end, ETitlesError);
end;

procedure TTitlesReadTests.TestWithoutTheStarsTheLastScreenComesAsThePathIsFlown;
begin
  var Titles := ReadFromText(ShortFlownFile('6.5'));
  Assert.IsFalse(Titles.EndsAtTheStars, 'No stars');
  Assert.IsTrue(Abs(Titles.Cues.Last - (19 + 6.5)) < Slack, 'Where the path is flown');
end;

procedure TTitlesReadTests.TestTheFileOfLevelTwoEndsAtTheStars;
begin
  var Titles := ReadNamed(ShippedFile, BinDir);
  Assert.IsTrue(Titles.EndsAtTheStars, 'At the stars');
  Assert.IsTrue(Titles.Cues.Stars - Titles.Cues.Flight < Titles.FlightTill,
    'The sky comes while the eye still climbs');
  Assert.IsTrue(Titles.TrackSeconds > Titles.Cues.Last, 'The track outlasts the last screen');
end;

initialization
  TDUnitX.RegisterTestFixture(TTitlesReadTests);

end.
