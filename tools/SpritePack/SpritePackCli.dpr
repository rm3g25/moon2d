{
  SpritePackCli - the .mset sprite set tool, console half.

  Deliberately two executables over one shared unit, not one executable
  wearing two hats: a VCL program with a command line has to attach a
  console it was not born with, and the result never quite behaves like
  either kind of program. SpritePack.exe (the form, later) and this file
  both do nothing but wrap Sprites.Sets - the work lives there.

  Commands:

    SpritePackCli pack <folder> <out.mset> [--id <name>] [--list <file>]
    SpritePackCli list <file.mset>
    SpritePackCli unpack <file.mset> <folder>

  pack takes every PNG in the folder in natural order (2 before 10,
  which plain alphabetical gets wrong). --list points at a 2008 sprite
  list - a monster .mns, the hero's default.txt, the weapon's - and
  turns it into named sequences, so the existing art migrates without
  anyone retyping twenty-four filenames.

  After the migration the set is the only source: names, descriptions
  and frame order live in its manifest and are edited in SpritePack.exe.
  No authoring file sits beside it waiting to disagree with it.

  unpack writes the images back plus the manifest, so a set can always
  be taken apart and rebuilt. A format that can only be read by the tool
  that wrote it is a trap, not a format.

  Moon 2D remake.
}
program SpritePackCli;

{$APPTYPE CONSOLE}
{$I ..\..\Moon2D.inc}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  System.Generics.Defaults,
  Sprites.Sets in '..\..\Sprites.Sets.pas';

const
  ManifestFileName = 'manifest.json';
  // Sprite list lengths the 2008 loaders expected.
  MonsterListLines = 16;
  HeroListLines = 24;

resourcestring
  SUsage =
    'SpritePackCli - Moon 2D sprite set tool' + sLineBreak + sLineBreak +
    '  pack   <folder> <out.mset> [--id <name>] [--list <file>]' +
      sLineBreak +
    '  list   <file.mset>' + sLineBreak +
    '  unpack <file.mset> <folder>' + sLineBreak;
  SUnknownCommand = 'Unknown command: %s';
  SNeedArguments = 'Command "%s" needs %d arguments';
  SNoFolder = 'Folder not found: %s';
  SNoImages = 'No PNG files in %s';
  SListEmpty = 'Sprite list "%s" is empty';
  SListUneven = 'Sprite list "%s": %d lines do not divide into %d sequences';
  SPacked = 'Packed %d sprites (%s) into %s';
  SUnpacked = 'Unpacked %d sprites into %s';

function FormatSize(ABytes: Integer): string;
begin
  if ABytes >= 1024 * 1024 then
    Result := Format('%.1f MB', [ABytes / (1024 * 1024)])
  else if ABytes >= 1024 then
    Result := Format('%.0f KB', [ABytes / 1024])
  else
    Result := Format('%d bytes', [ABytes]);
end;

// Natural order: the digits inside a name compare as numbers, so 2
// lands before 10. Plain string compare puts 10 in the middle of the
// walk cycle, which is the kind of bug that looks like bad animation.
function NaturalCompare(const ALeft, ARight: string): Integer;
var
  LeftPos: Integer;
  RightPos: Integer;

  function ReadNumber(const AText: string; var APos: Integer): Int64;
  begin
    Result := 0;
    while (APos <= Length(AText)) and CharInSet(AText[APos], ['0'..'9']) do
    begin
      Result := Result * 10 + (Ord(AText[APos]) - Ord('0'));
      Inc(APos);
    end;
  end;

begin
  LeftPos := 1;
  RightPos := 1;
  while (LeftPos <= Length(ALeft)) and (RightPos <= Length(ARight)) do
  begin
    if CharInSet(ALeft[LeftPos], ['0'..'9'])
      and CharInSet(ARight[RightPos], ['0'..'9']) then
    begin
      var LeftNumber := ReadNumber(ALeft, LeftPos);
      var RightNumber := ReadNumber(ARight, RightPos);
      if LeftNumber <> RightNumber then
        Exit(CompareValue(LeftNumber, RightNumber));
    end
    else
    begin
      var Order := CompareText(ALeft[LeftPos], ARight[RightPos]);
      if Order <> 0 then
        Exit(Order);
      Inc(LeftPos);
      Inc(RightPos);
    end;
  end;
  Result := (Length(ALeft) - LeftPos) - (Length(ARight) - RightPos);
end;

function SortedImageNames(const AFolder: string): TArray<string>;
begin
  Result := [];
  for var Path in TDirectory.GetFiles(AFolder, '*.png') do
    Result := Result + [TPath.GetFileName(Path)];
  TArray.Sort<string>(Result, TComparer<string>.Construct(NaturalCompare));
end;

// Each 2008 loader knew its own list length and split it by position:
// a monster list is sixteen lines (walk, then dying), the hero's is
// twenty-four (walk, dying, transformed), a weapon list is one group of
// frames. The length IS the format, so it is what says where one
// sequence ends and the next begins. Nothing is guessed here - this is
// the same arithmetic the original loaders did, given a name.
function SequenceNamesFor(ALineCount: Integer): TArray<string>;
begin
  case ALineCount of
    MonsterListLines: Result := ['alive', 'death'];
    HeroListLines: Result := ['walk', 'death', 'henshin'];
  else
    Result := ['frames'];
  end;
end;

procedure AddListSequences(const AWriter: TSpriteSetWriter;
  const AListFileName: string);
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AListFileName);
    while (Lines.Count > 0) and (Trim(Lines[Lines.Count - 1]) = '') do
      Lines.Delete(Lines.Count - 1);
    if Lines.Count = 0 then
      raise Exception.CreateFmt(SListEmpty, [AListFileName]);

    var Names := SequenceNamesFor(Lines.Count);
    var GroupSize := Lines.Count div Length(Names);
    if GroupSize * Length(Names) <> Lines.Count then
      raise Exception.CreateFmt(SListUneven,
        [AListFileName, Lines.Count, Length(Names)]);

    for var Group := 0 to High(Names) do
    begin
      var Frames: TArray<string> := [];
      for var i := 0 to GroupSize - 1 do
        Frames := Frames + [TPath.GetFileNameWithoutExtension(
          Trim(Lines[Group * GroupSize + i]))];
      AWriter.AddSequence(Names[Group], Frames);
    end;
  finally
    Lines.Free;
  end;
end;

procedure CommandPack(const AFolder, AOutput, AId, AListFileName: string);
var
  Writer: TSpriteSetWriter;
begin
  if not TDirectory.Exists(AFolder) then
    raise Exception.CreateFmt(SNoFolder, [AFolder]);

  var SetId := AId;
  if SetId = '' then
    SetId := TPath.GetFileName(ExcludeTrailingPathDelimiter(AFolder));

  Writer := TSpriteSetWriter.Create(SetId);
  try
    var Names := SortedImageNames(AFolder);
    if Length(Names) = 0 then
      raise Exception.CreateFmt(SNoImages, [AFolder]);
    for var Name in Names do
      Writer.AddSpriteFile(TPath.GetFileNameWithoutExtension(Name), '',
        TPath.Combine(AFolder, Name));
    if AListFileName <> '' then
      AddListSequences(Writer, AListFileName);

    TDirectory.CreateDirectory(TPath.GetDirectoryName(TPath.GetFullPath(
      AOutput)));
    Writer.SaveToFile(AOutput);

    var Total := 0;
    for var Entry in Writer.Entries do
      Inc(Total, Entry.Size);
    Writeln(Format(SPacked, [Length(Writer.Entries),
      FormatSize(Total), AOutput]));
  finally
    Writer.Free;
  end;
end;

procedure CommandList(const AFileName: string);
var
  Sprites: TSpriteSet;
begin
  Sprites := TSpriteSet.Create(AFileName);
  try
    Writeln(Format('set: %s', [Sprites.Id]));
    if Sprites.Description <> '' then
      Writeln(Format('description: %s', [Sprites.Description]));
    Writeln(Format('sprites: %d', [Length(Sprites.Entries)]));
    for var Entry in Sprites.Entries do
    begin
      Write(Format('  %-20s %8d bytes at %8d', [Entry.Name, Entry.Size,
        Entry.Offset]));
      if Entry.Description <> '' then
        Write('  ', Entry.Description);
      Writeln;
    end;
    for var Sequence in Sprites.Sequences do
    begin
      Write(Format('  sequence %s: %s',
        [Sequence.Name, string.Join(', ', Sequence.Frames)]));
      if Sequence.Description <> '' then
        Write('  ', Sequence.Description);
      Writeln;
    end;
  finally
    Sprites.Free;
  end;
end;

procedure CommandUnpack(const AFileName, AFolder: string);
var
  Sprites: TSpriteSet;
  Root: TJSONObject;
begin
  Sprites := TSpriteSet.Create(AFileName);
  try
    TDirectory.CreateDirectory(AFolder);

    Root := TJSONObject.Create;
    try
      Root.AddPair('id', Sprites.Id);
      Root.AddPair('description', Sprites.Description);

      var List := TJSONArray.Create;
      for var Entry in Sprites.Entries do
      begin
        TFile.WriteAllBytes(TPath.Combine(AFolder, Entry.Name + '.png'),
          Sprites.ReadSprite(Entry.Name));
        var Item := TJSONObject.Create;
        Item.AddPair('name', Entry.Name);
        Item.AddPair('description', Entry.Description);
        List.Add(Item);
      end;
      Root.AddPair('sprites', List);

      var Sequences := TJSONArray.Create;
      for var Sequence in Sprites.Sequences do
      begin
        var Item := TJSONObject.Create;
        Item.AddPair('name', Sequence.Name);
        Item.AddPair('description', Sequence.Description);
        var Frames := TJSONArray.Create;
        for var Frame in Sequence.Frames do
          Frames.Add(Frame);
        Item.AddPair('frames', Frames);
        Sequences.Add(Item);
      end;
      Root.AddPair('sequences', Sequences);

      TFile.WriteAllText(TPath.Combine(AFolder, ManifestFileName),
        Root.Format(2), TEncoding.UTF8);
    finally
      Root.Free;
    end;

    Writeln(Format(SUnpacked, [Length(Sprites.Entries), AFolder]));
  finally
    Sprites.Free;
  end;
end;

function Option(const AName: string): string;
begin
  Result := '';
  for var i := 1 to ParamCount - 1 do
    if SameText(ParamStr(i), AName) then
      Exit(ParamStr(i + 1));
end;

procedure Run;
begin
  if ParamCount < 1 then
  begin
    Write(SUsage);
    Exit;
  end;

  var Command := LowerCase(ParamStr(1));
  if Command = 'pack' then
  begin
    if ParamCount < 3 then
      raise Exception.CreateFmt(SNeedArguments, [Command, 2]);
    CommandPack(ParamStr(2), ParamStr(3), Option('--id'),
      Option('--list'));
  end
  else if Command = 'list' then
  begin
    if ParamCount < 2 then
      raise Exception.CreateFmt(SNeedArguments, [Command, 1]);
    CommandList(ParamStr(2));
  end
  else if Command = 'unpack' then
  begin
    if ParamCount < 3 then
      raise Exception.CreateFmt(SNeedArguments, [Command, 2]);
    CommandUnpack(ParamStr(2), ParamStr(3));
  end
  else
    raise Exception.CreateFmt(SUnknownCommand, [ParamStr(1)]);
end;

begin
  try
    Run;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.Message);
      // A build script needs to know that a step failed, and the only
      // thing it reads is this number.
      ExitCode := 1;
    end;
  end;
end.
