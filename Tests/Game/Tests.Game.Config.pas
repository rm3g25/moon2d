{
  Tests.Game.Config - the player's volumes in the config layers: full with
  no file at all; the settings over the shipped file; a value out of range
  takes the nearest end; a saved volume reads back; saving one key keeps
  the others.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Config;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TConfigVolumeTests = class
  private
    FFolder: string;
    function FileIn(const AName: string): string;
    procedure WriteFile(const AName, AText: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNoFilesGiveFullVolumes;
    [Test]
    procedure TestTheSettingsOverrideTheShippedVolumes;
    [Test]
    procedure TestAVolumeOutOfRangeTakesTheNearestEnd;
    [Test]
    procedure TestSavedVolumesReadBack;
    [Test]
    procedure TestSavingAVolumeKeepsTheOtherKeys;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, Game.Config;

procedure TConfigVolumeTests.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, TPath.GetGUIDFileName);
  ForceDirectories(FFolder);
end;

procedure TConfigVolumeTests.TearDown;
begin
  TDirectory.Delete(FFolder, True);
end;

function TConfigVolumeTests.FileIn(const AName: string): string;
begin
  Result := TPath.Combine(FFolder, AName);
end;

procedure TConfigVolumeTests.WriteFile(const AName, AText: string);
begin
  TFile.WriteAllText(FileIn(AName), AText, TEncoding.UTF8);
end;

procedure TConfigVolumeTests.TestNoFilesGiveFullVolumes;
begin
  var Config := LoadGameConfig(FileIn('config.json'), FileIn('settings.json'));
  Assert.AreEqual(Integer(VolumeSteps), Integer(Config.MusicVolume), 'Music');
  Assert.AreEqual(Integer(VolumeSteps), Integer(Config.SoundVolume), 'Sounds');
end;

procedure TConfigVolumeTests.TestTheSettingsOverrideTheShippedVolumes;
begin
  WriteFile('config.json', '{"audio": {"music": 7, "sounds": 6}}');
  WriteFile('settings.json', '{"audio": {"music": 2}}');
  var Config := LoadGameConfig(FileIn('config.json'), FileIn('settings.json'));
  Assert.AreEqual(2, Integer(Config.MusicVolume), 'Music from the settings');
  Assert.AreEqual(6, Integer(Config.SoundVolume), 'Sounds from the shipped');
end;

procedure TConfigVolumeTests.TestAVolumeOutOfRangeTakesTheNearestEnd;
begin
  WriteFile('settings.json', '{"audio": {"music": -3, "sounds": 99}}');
  var Config := LoadGameConfig(FileIn('config.json'), FileIn('settings.json'));
  Assert.AreEqual(0, Integer(Config.MusicVolume), 'Below');
  Assert.AreEqual(Integer(VolumeSteps), Integer(Config.SoundVolume), 'Above');
end;

procedure TConfigVolumeTests.TestSavedVolumesReadBack;
begin
  var Settings := FileIn('settings.json');
  SaveMusicVolume(Settings, 0);
  SaveSoundVolume(Settings, 4);
  var Config := LoadGameConfig(FileIn('config.json'), Settings);
  Assert.AreEqual(0, Integer(Config.MusicVolume), 'Music');
  Assert.AreEqual(4, Integer(Config.SoundVolume), 'Sounds');
end;

procedure TConfigVolumeTests.TestSavingAVolumeKeepsTheOtherKeys;
begin
  var Settings := FileIn('settings.json');
  SaveGameDifficulty(Settings, dfWild);
  SaveMusicVolume(Settings, 3);
  var Config := LoadGameConfig(FileIn('config.json'), Settings);
  Assert.AreEqual(Ord(dfWild), Ord(Config.Difficulty), 'Difficulty');
  Assert.AreEqual(3, Integer(Config.MusicVolume), 'Music');
end;

initialization
  TDUnitX.RegisterTestFixture(TConfigVolumeTests);

end.
