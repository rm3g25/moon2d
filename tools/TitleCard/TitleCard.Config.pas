{
  TitleCard.Config - TitleCard.ini next to the exe, written with
  defaults on first run so there is always something to edit.

  Asset paths are not hard-coded to "..\..": the exe usually lives in
  tools\TitleCard\Win32\Debug, which is four levels down, and one Release
  build would break a fixed guess. Instead the atlas is looked up by
  walking up from the exe until the file turns up. The INI can still
  pin an absolute path when the search guesses wrong.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit TitleCard.Config;

interface

uses
  TitleCard.Layout;

type
  TTitleCardConfig = record
    SpriteSetFileName: string;
    FontSpriteName: string;
    RenderDriver: string;
    Geometry: TCardGeometry;
    ScaleSteps: Integer; // 0 = auto-fit to the margins
    BatchPattern: string;
    UniformBatchScale: Boolean;
    function IsUsable: Boolean;
  end;

function LoadTitleCardConfig: TTitleCardConfig;
function ConfigFileName: string;

implementation

uses
  System.SysUtils, System.IniFiles, System.IOUtils;

const
  // The loose images retired into .mset containers; the font atlas is
  // a sprite named 'fonty' inside the ui set. The search below wants a
  // path relative to the repository root, not a bare file name.
  DefaultSetName = 'bin\sprites\ui.mset';
  DefaultFontSprite = 'fonty';
  // tools\TitleCard\Win32\Debug is already four rungs below the root;
  // six gives room for one more folder without another release.
  MaxLevelsUp = 6;

  SectionPaths = 'Paths';
  SectionCard = 'Card';
  SectionBatch = 'Batch';

function TTitleCardConfig.IsUsable: Boolean;
begin
  Result := (SpriteSetFileName <> '') and TFile.Exists(SpriteSetFileName);
end;

function ConfigFileName: string;
begin
  Result := TPath.ChangeExtension(ParamStr(0), '.ini');
end;

// Walks up from the exe folder looking for a file. Returns '' if the
// whole climb comes up empty - the caller reports that, we do not guess.
function FindAssetUpwards(const AFileName: string): string;
begin
  var Folder := TPath.GetDirectoryName(ParamStr(0));
  for var i := 0 to MaxLevelsUp do
  begin
    var Candidate := TPath.Combine(Folder, AFileName);
    if TFile.Exists(Candidate) then
      Exit(Candidate);
    var Parent := TPath.GetDirectoryName(Folder);
    if (Parent = '') or SameText(Parent, Folder) then
      Break;
    Folder := Parent;
  end;
  Result := '';
end;

function ResolveSpriteSet(const AConfigured: string): string;
begin
  if AConfigured = '' then
    Exit(FindAssetUpwards(DefaultSetName));
  if TPath.IsPathRooted(AConfigured) then
    Exit(AConfigured);
  Result := FindAssetUpwards(AConfigured);
end;

function DefaultConfig: TTitleCardConfig;
begin
  Result.SpriteSetFileName := '';
  Result.FontSpriteName := DefaultFontSprite;
  Result.RenderDriver := 'software';
  Result.Geometry := DefaultCardGeometry;
  Result.ScaleSteps := 2;
  Result.BatchPattern := 'card_%.2d.png';
  Result.UniformBatchScale := True;
end;

procedure WriteConfig(const AIni: TIniFile; const AConfig: TTitleCardConfig);
begin
  AIni.WriteString(SectionPaths, 'SpriteSet', AConfig.SpriteSetFileName);
  AIni.WriteString(SectionPaths, 'FontSprite', AConfig.FontSpriteName);
  AIni.WriteString(SectionPaths, 'RenderDriver', AConfig.RenderDriver);
  AIni.WriteInteger(SectionCard, 'Width', AConfig.Geometry.Width);
  AIni.WriteInteger(SectionCard, 'Height', AConfig.Geometry.Height);
  // Percent integers, not floats: WriteFloat/ReadFloat go through the
  // locale decimal separator, so an INI written on one machine and
  // hand-edited on a comma locale silently falls back to defaults.
  AIni.WriteInteger(SectionCard, 'MarginPercent',
    Round(AConfig.Geometry.MarginFraction * 100));
  AIni.WriteInteger(SectionCard, 'OpticalCenterPercent',
    Round(AConfig.Geometry.OpticalCenterFraction * 100));
  AIni.WriteInteger(SectionCard, 'LineSpacingPercent',
    Round(AConfig.Geometry.LineSpacing * 100));
  AIni.WriteInteger(SectionCard, 'ScaleSteps', AConfig.ScaleSteps);
  AIni.WriteString(SectionBatch, 'FileNamePattern', AConfig.BatchPattern);
  AIni.WriteBool(SectionBatch, 'UniformScale', AConfig.UniformBatchScale);
end;

function ReadConfig(const AIni: TIniFile): TTitleCardConfig;
begin
  Result := DefaultConfig;
  Result.SpriteSetFileName :=
    AIni.ReadString(SectionPaths, 'SpriteSet', '');
  Result.FontSpriteName := AIni.ReadString(SectionPaths, 'FontSprite',
    Result.FontSpriteName);
  Result.RenderDriver :=
    AIni.ReadString(SectionPaths, 'RenderDriver', Result.RenderDriver);
  Result.Geometry.Width :=
    AIni.ReadInteger(SectionCard, 'Width', Result.Geometry.Width);
  Result.Geometry.Height :=
    AIni.ReadInteger(SectionCard, 'Height', Result.Geometry.Height);
  Result.Geometry.MarginFraction := AIni.ReadInteger(SectionCard,
    'MarginPercent', Round(Result.Geometry.MarginFraction * 100)) / 100;
  Result.Geometry.OpticalCenterFraction := AIni.ReadInteger(SectionCard,
    'OpticalCenterPercent',
    Round(Result.Geometry.OpticalCenterFraction * 100)) / 100;
  Result.Geometry.LineSpacing := AIni.ReadInteger(SectionCard,
    'LineSpacingPercent', Round(Result.Geometry.LineSpacing * 100)) / 100;
  Result.ScaleSteps :=
    AIni.ReadInteger(SectionCard, 'ScaleSteps', Result.ScaleSteps);
  Result.BatchPattern := AIni.ReadString(SectionBatch,
    'FileNamePattern', Result.BatchPattern);
  Result.UniformBatchScale := AIni.ReadBool(SectionBatch,
    'UniformScale', Result.UniformBatchScale);
end;

function LoadTitleCardConfig: TTitleCardConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ConfigFileName);
  try
    if TFile.Exists(ConfigFileName) then
      Result := ReadConfig(Ini)
    else
    begin
      Result := DefaultConfig;
      WriteConfig(Ini, Result);
    end;
  finally
    Ini.Free;
  end;
  Result.SpriteSetFileName := ResolveSpriteSet(Result.SpriteSetFileName);
end;

end.
