{
  Tests.Levels.Titles - the titles of a level as data: a level without the
  section has none; the file it names must be there and must read; its
  cues are read as written; a cue that does not come after the one before
  it raises. The file level 2 ships reads.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Titles;

interface

uses
  DUnitX.TestFramework,
  Levels.Titles;

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
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON;

const
  Slack = 0.0001;
  ShippedFile = 'finale.json';
  GoodCues = '"card": 10, "cardOut": 16, "flash": 17';
  // The band of level 2's end track comes in on this second
  ShippedFlash = 17.21;

function BinDir: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

function TitlesFile(const ACues: string): string;
begin
  Result := '{"cues": {' + ACues + '}}';
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

end.
