{
  Tests.Sprites.Sets - the sets the game ships, read as the oldest video
  cards meet them. Every sprite becomes one texture, and a Direct3D 9_1
  card takes none wider or taller than 2048 px: a bigger sprite is not
  created there, and nothing on a modern card says so.

  The sets are read from bin\sprites\ beside the test executable; of each
  sprite only its PNG header is looked at.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Sprites.Sets;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TSpriteSetTests = class
  public
    [Test]
    procedure TestEveryShippedSpriteFitsTheOldestCards;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, Sprites.Sets;

const
  // Direct3D feature level 9_1, the oldest the game still runs on
  MaxTextureSide = 2048;
  // The signature, then the IHDR chunk: its length and type, width, height
  PngWidthOffset = 16;
  PngHeightOffset = 20;
  PngHeaderSize = 24;

function BigEndianAt(const ABytes: TBytes; AOffset: Integer): Cardinal;
begin
  Result := (Cardinal(ABytes[AOffset]) shl 24) or
    (Cardinal(ABytes[AOffset + 1]) shl 16) or
    (Cardinal(ABytes[AOffset + 2]) shl 8) or ABytes[AOffset + 3];
end;

function TryReadPngSize(const AData: TBytes; out AWidth,
  AHeight: Cardinal): Boolean;
begin
  Result := (Length(AData) >= PngHeaderSize) and (AData[1] = Ord('P')) and
    (AData[2] = Ord('N')) and (AData[3] = Ord('G'));
  if not Result then
    Exit;
  AWidth := BigEndianAt(AData, PngWidthOffset);
  AHeight := BigEndianAt(AData, PngHeightOffset);
end;

// "set:sprite WxH" for every sprite of the file the oldest cards refuse
function MisfitsOf(const AFileName: string): TArray<string>;
var
  Width, Height: Cardinal;
begin
  Result := [];
  var SpriteSet := TSpriteSet.Create(AFileName);
  try
    for var Entry in SpriteSet.Entries do
    begin
      var Where := SpriteSet.Id + SetQualifier + Entry.Name;
      if not TryReadPngSize(SpriteSet.ReadSprite(Entry.Name), Width, Height) then
        Result := Result + [Where + ' is not a PNG']
      else if (Width > MaxTextureSide) or (Height > MaxTextureSide) then
        Result := Result + [Format('%s %dx%d', [Where, Width, Height])];
    end;
  finally
    SpriteSet.Free;
  end;
end;

procedure TSpriteSetTests.TestEveryShippedSpriteFitsTheOldestCards;
begin
  var SetsDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'sprites');
  var Files := TDirectory.GetFiles(SetsDir, '*.mset');
  Assert.IsTrue(Length(Files) > 0, 'no sets in ' + SetsDir);

  var Misfits: TArray<string> := [];
  for var FileName in Files do
    Misfits := Misfits + MisfitsOf(FileName);
  Assert.AreEqual<Integer>(0, Length(Misfits), string.Join('; ', Misfits));
end;

initialization
  TDUnitX.RegisterTestFixture(TSpriteSetTests);

end.
