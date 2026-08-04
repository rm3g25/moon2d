{
  Sprites.Sets - the .mset sprite set container.

  A set is one file holding many sprites: a table of contents in plain
  JSON, then every image concatenated behind it. Nothing separates one
  image from the next - the manifest says where each begins and how long
  it runs, so reading a sprite is a seek and a read, never a search.

    [ 'MSET' ][ version: word ][ manifest size: cardinal ]   10 bytes
    [ manifest: UTF-8 JSON                              ]
    [ image 1 ][ image 2 ][ image 3 ] ...                    raw PNG

  The manifest carries a description for the set and for every sprite -
  free text or JSON, whatever the author wants to remember - plus named
  frame sequences, which retire the .mns side files.

  Opening a set parses the manifest only. Image bytes are read when
  something asks for them, so a level that declares five sets and uses
  three tiles from one of them pays for three tiles.

  One unit serves all three readers of this format: the game, the
  packer and the level editor. A format that is awkward to use from
  three places is a format that will be wrong in at least one of them.

  Moon 2D remake.
}
unit Sprites.Sets;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

const
  MsetVersion = 1;

  // Separates a set name from a sprite name: 'common:pustota'. Chosen
  // over '.' because it cannot be mistaken for a file extension, and
  // over '\' because it cannot be mistaken for a path. A qualified
  // name resolves in the named set only, ignoring declaration order.
  SetQualifier = ':';

type
  ESpriteSetError = class(Exception);

  // Offset is measured from the first byte of the blob block, not from
  // the start of the file: the manifest can grow or shrink without a
  // single image moving.
  TSpriteEntry = record
    Name: string;
    Description: string;
    Offset: Cardinal;
    Size: Cardinal;
  end;

  // A named frame order. The engine asks for 'alive' and 'death'; the
  // format takes any name, so a monster that later needs 'idle' or
  // 'transform' costs a manifest line, not a format version.
  TSpriteSequence = record
    Name: string;
    // Free-form, like the set's and the sprite's. Somewhere to write
    // down the speed, whether it loops, which frame lands the hit -
    // as prose now, as JSON later if something starts reading it.
    Description: string;
    Frames: TArray<string>;
  end;

  TSpriteSet = class
  private
    FFileName: string;
    FStream: TFileStream;
    FBlobBase: Int64;
    FId: string;
    FDescription: string;
    FEntries: TArray<TSpriteEntry>;
    FSequences: TArray<TSpriteSequence>;
    FIndex: TDictionary<string, Integer>;
    procedure ReadManifest;
    procedure ParseManifest(const AText: string);
    function IndexOfSprite(const AName: string): Integer;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    function Contains(const AName: string): Boolean;
    // Raises if the name is unknown: a missing sprite is a broken set,
    // not an empty picture, and it should say so at the point of asking.
    function ReadSprite(const AName: string): TBytes;
    function SequenceFrames(const AName: string): TArray<string>;

    property FileName: string read FFileName;
    property Id: string read FId;
    property Description: string read FDescription;
    property Entries: TArray<TSpriteEntry> read FEntries;
    property Sequences: TArray<TSpriteSequence> read FSequences;
  end;

  // Sprites land in the file in the order they are added, and that is
  // the order `list` prints. Writing is deterministic: the same input
  // produces the same bytes, so rebuilding a set that did not change is
  // not a diff.
  TSpriteSetWriter = class
  private
    FId: string;
    FDescription: string;
    FEntries: TArray<TSpriteEntry>;
    FBlobs: TArray<TBytes>;
    FSequences: TArray<TSpriteSequence>;
    function BuildManifest: TBytes;
    procedure CheckSequences;
  public
    constructor Create(const AId: string);

    procedure AddSprite(const AName, ADescription: string;
      const AData: TBytes);
    procedure AddSpriteFile(const AName, ADescription, AFileName: string);
    procedure AddSequence(const AName: string; const AFrames: TArray<string>;
      const ADescription: string = '');
    procedure SaveToFile(const AFileName: string);

    property Description: string read FDescription write FDescription;
    property Entries: TArray<TSpriteEntry> read FEntries;
  end;

implementation

uses
  System.JSON;

resourcestring
  SNotAMset = 'Not a sprite set: %s';
  SBadVersion = 'Sprite set "%s" is version %d, this build reads up to %d';
  SManifestBroken = 'Sprite set "%s": manifest is not valid JSON';
  SManifestField = 'Sprite set "%s": manifest is missing "%s"';
  STruncated = 'Sprite set "%s": sprite "%s" runs past the end of the file';
  SNoSuchSprite = 'Sprite set "%s" has no sprite named "%s"';
  SNoSuchSequence = 'Sprite set "%s" has no sequence named "%s"';
  SDuplicateName = 'Sprite "%s" is already in this set';
  SSequenceFrame = 'Sequence "%s" refers to "%s", which is not in the set';
  SFileMissing = 'Cannot add "%s": file not found';

const
  // Field names of the manifest. A typo in a string literal compiles
  // happily and fails at the customer; a typo in a constant name does
  // not compile at all.
  KeyId = 'id';
  KeyDescription = 'description';
  KeySprites = 'sprites';
  KeySequences = 'sequences';
  KeyName = 'name';
  KeyOffset = 'offset';
  KeySize = 'size';
  KeyFrames = 'frames';

type
  // Named, not anonymous: two identical-looking array[0..3] of AnsiChar
  // declarations are two distinct types to the compiler, and neither
  // assignment nor comparison between them will build.
  TMsetMagic = array[0..3] of AnsiChar;

  TMsetHeader = packed record
    Magic: TMsetMagic;
    Version: Word;
    ManifestSize: Cardinal;
  end;

const
  MsetMagic: TMsetMagic = ('M', 'S', 'E', 'T');

function ReadWholeFile(const AFileName: string): TBytes;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, Stream.Size);
    if Length(Result) > 0 then
      Stream.ReadBuffer(Result[0], Length(Result));
  finally
    Stream.Free;
  end;
end;

// TSpriteSet

constructor TSpriteSet.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FIndex := TDictionary<string, Integer>.Create;
  FStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  ReadManifest;
end;

destructor TSpriteSet.Destroy;
begin
  FStream.Free;
  FIndex.Free;
  inherited;
end;

procedure TSpriteSet.ReadManifest;
var
  Header: TMsetHeader;
  Raw: TBytes;
begin
  if FStream.Size < SizeOf(Header) then
    raise ESpriteSetError.CreateFmt(SNotAMset, [FFileName]);

  FStream.ReadBuffer(Header, SizeOf(Header));
  if Header.Magic <> MsetMagic then
    raise ESpriteSetError.CreateFmt(SNotAMset, [FFileName]);
  if Header.Version > MsetVersion then
    raise ESpriteSetError.CreateFmt(SBadVersion,
      [FFileName, Header.Version, MsetVersion]);

  SetLength(Raw, Header.ManifestSize);
  if Header.ManifestSize > 0 then
    FStream.ReadBuffer(Raw[0], Header.ManifestSize);
  FBlobBase := SizeOf(Header) + Int64(Header.ManifestSize);

  ParseManifest(TEncoding.UTF8.GetString(Raw));
end;

procedure TSpriteSet.ParseManifest(const AText: string);
var
  Root: TJSONObject;
  Sprites: TJSONArray;
  Sequences: TJSONArray;
begin
  Root := TJSONObject.ParseJSONValue(AText) as TJSONObject;
  if Root = nil then
    raise ESpriteSetError.CreateFmt(SManifestBroken, [FFileName]);
  try
    FId := Root.GetValue<string>(KeyId, '');
    FDescription := Root.GetValue<string>(KeyDescription, '');

    if not Root.TryGetValue<TJSONArray>(KeySprites, Sprites) then
      raise ESpriteSetError.CreateFmt(SManifestField,
        [FFileName, KeySprites]);

    SetLength(FEntries, Sprites.Count);
    for var i := 0 to Sprites.Count - 1 do
    begin
      var Item := Sprites.Items[i] as TJSONObject;
      FEntries[i].Name := Item.GetValue<string>(KeyName, '');
      FEntries[i].Description := Item.GetValue<string>(KeyDescription, '');
      FEntries[i].Offset := Item.GetValue<Cardinal>(KeyOffset, 0);
      FEntries[i].Size := Item.GetValue<Cardinal>(KeySize, 0);
      FIndex.AddOrSetValue(FEntries[i].Name, i);
    end;

    if Root.TryGetValue<TJSONArray>(KeySequences, Sequences) then
    begin
      SetLength(FSequences, Sequences.Count);
      for var i := 0 to Sequences.Count - 1 do
      begin
        var Item := Sequences.Items[i] as TJSONObject;
        FSequences[i].Name := Item.GetValue<string>(KeyName, '');
        FSequences[i].Description :=
          Item.GetValue<string>(KeyDescription, '');
        var Frames := Item.GetValue<TJSONArray>(KeyFrames);
        SetLength(FSequences[i].Frames, Frames.Count);
        for var j := 0 to Frames.Count - 1 do
          FSequences[i].Frames[j] := Frames.Items[j].Value;
      end;
    end;
  finally
    Root.Free;
  end;
end;

function TSpriteSet.IndexOfSprite(const AName: string): Integer;
begin
  if not FIndex.TryGetValue(AName, Result) then
    Result := -1;
end;

function TSpriteSet.Contains(const AName: string): Boolean;
begin
  Result := FIndex.ContainsKey(AName);
end;

function TSpriteSet.ReadSprite(const AName: string): TBytes;
begin
  var Position := IndexOfSprite(AName);
  if Position < 0 then
    raise ESpriteSetError.CreateFmt(SNoSuchSprite, [FFileName, AName]);

  var Entry := FEntries[Position];
  if FBlobBase + Entry.Offset + Entry.Size > FStream.Size then
    raise ESpriteSetError.CreateFmt(STruncated, [FFileName, AName]);

  SetLength(Result, Entry.Size);
  FStream.Position := FBlobBase + Entry.Offset;
  if Entry.Size > 0 then
    FStream.ReadBuffer(Result[0], Entry.Size);
end;

function TSpriteSet.SequenceFrames(const AName: string): TArray<string>;
begin
  for var Sequence in FSequences do
    if Sequence.Name = AName then
      Exit(Sequence.Frames);
  raise ESpriteSetError.CreateFmt(SNoSuchSequence, [FFileName, AName]);
end;

// TSpriteSetWriter

constructor TSpriteSetWriter.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
end;

procedure TSpriteSetWriter.AddSprite(const AName, ADescription: string;
  const AData: TBytes);
begin
  for var Entry in FEntries do
    if Entry.Name = AName then
      raise ESpriteSetError.CreateFmt(SDuplicateName, [AName]);

  var Added: TSpriteEntry;
  Added.Name := AName;
  Added.Description := ADescription;
  Added.Offset := 0; // assigned at save time, when the order is final
  Added.Size := Length(AData);

  FEntries := FEntries + [Added];
  FBlobs := FBlobs + [AData];
end;

procedure TSpriteSetWriter.AddSpriteFile(const AName, ADescription,
  AFileName: string);
begin
  if not FileExists(AFileName) then
    raise ESpriteSetError.CreateFmt(SFileMissing, [AFileName]);
  AddSprite(AName, ADescription, ReadWholeFile(AFileName));
end;

procedure TSpriteSetWriter.AddSequence(const AName: string;
  const AFrames: TArray<string>; const ADescription: string);
begin
  var Added: TSpriteSequence;
  Added.Name := AName;
  Added.Description := ADescription;
  Added.Frames := AFrames;
  FSequences := FSequences + [Added];
end;

procedure TSpriteSetWriter.CheckSequences;
begin
  for var Sequence in FSequences do
    for var Frame in Sequence.Frames do
    begin
      var Known := False;
      for var Entry in FEntries do
        if Entry.Name = Frame then
        begin
          Known := True;
          Break;
        end;
      if not Known then
        raise ESpriteSetError.CreateFmt(SSequenceFrame,
          [Sequence.Name, Frame]);
    end;
end;

function TSpriteSetWriter.BuildManifest: TBytes;
var
  Root: TJSONObject;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair(KeyId, FId);
    Root.AddPair(KeyDescription, FDescription);

    var Sprites := TJSONArray.Create;
    for var Entry in FEntries do
    begin
      var Item := TJSONObject.Create;
      Item.AddPair(KeyName, Entry.Name);
      Item.AddPair(KeyDescription, Entry.Description);
      Item.AddPair(KeyOffset, TJSONNumber.Create(Entry.Offset));
      Item.AddPair(KeySize, TJSONNumber.Create(Entry.Size));
      Sprites.Add(Item);
    end;
    Root.AddPair(KeySprites, Sprites);

    var Sequences := TJSONArray.Create;
    for var Sequence in FSequences do
    begin
      var Item := TJSONObject.Create;
      Item.AddPair(KeyName, Sequence.Name);
      Item.AddPair(KeyDescription, Sequence.Description);
      var Frames := TJSONArray.Create;
      for var Frame in Sequence.Frames do
        Frames.Add(Frame);
      Item.AddPair(KeyFrames, Frames);
      Sequences.Add(Item);
    end;
    Root.AddPair(KeySequences, Sequences);

    Result := TEncoding.UTF8.GetBytes(Root.ToJSON);
  finally
    Root.Free;
  end;
end;

procedure TSpriteSetWriter.SaveToFile(const AFileName: string);
var
  Header: TMsetHeader;
  Stream: TFileStream;
begin
  CheckSequences;

  // Offsets are handed out in add order, and the blobs are written in
  // that same order below. The two loops must not drift apart.
  var Running: Cardinal := 0;
  for var i := 0 to High(FEntries) do
  begin
    FEntries[i].Offset := Running;
    Inc(Running, FEntries[i].Size);
  end;

  var Manifest := BuildManifest;

  Header.Magic := MsetMagic;
  Header.Version := MsetVersion;
  Header.ManifestSize := Length(Manifest);

  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    Stream.WriteBuffer(Header, SizeOf(Header));
    if Length(Manifest) > 0 then
      Stream.WriteBuffer(Manifest[0], Length(Manifest));
    for var Blob in FBlobs do
      if Length(Blob) > 0 then
        Stream.WriteBuffer(Blob[0], Length(Blob));
  finally
    Stream.Free;
  end;
end;

end.
