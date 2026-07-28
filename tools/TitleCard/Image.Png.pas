{
  Image.Png - a minimal 8-bit RGBA PNG writer.

  Deliberately hand-rolled instead of leaning on Vcl.Imaging.pngimage or
  SDL2_image: TPngImage keeps its pixels in a DIB and hands them back in
  BGR order (a channel swap waiting to happen on a lime-green font), and
  IMG_SavePNG would drag SDL2_image.dll plus libpng into a tool that
  otherwise needs one DLL. Everything below is the PNG spec's own
  reference recipe: signature, IHDR, one IDAT, IEND, filter type None.

  Input is exactly what SDL_RenderReadPixels produces with
  SdlPixelFormatAbgr8888 - top-down rows of R,G,B,A bytes.

  Moon 2D remake. Requires Delphi 12+.
}
unit Image.Png;

interface

uses
  System.SysUtils;

type
  EPngError = class(Exception);

// AWidth * AHeight * 4 bytes, top-down, R,G,B,A per pixel.
procedure SavePngRgba(const AFileName: string; const APixels: TBytes;
  AWidth, AHeight: Integer);

implementation

uses
  System.Classes, System.ZLib;

resourcestring
  SPngBufferTooSmall = 'PNG buffer holds %d bytes, %dx%d RGBA needs %d';
  SPngEmptyImage = 'PNG image size must be positive, got %dx%d';

const
  PngSignature: array [0..7] of Byte = (137, 80, 78, 71, 13, 10, 26, 10);
  PngBitDepth = 8;
  PngColorTypeRgba = 6;
  PngFilterNone = 0;
  BytesPerPixel = 4;
  // 15 = plain zlib framing, which is exactly what an IDAT payload is.
  // +16 would emit a gzip wrapper and -15 a headerless deflate stream;
  // both produce a file every decoder rejects.
  ZlibWindowBits = 15;

var
  CrcTable: array [0..255] of UInt32;

procedure BuildCrcTable;
begin
  for var n := 0 to High(CrcTable) do
  begin
    var Remainder := UInt32(n);
    for var k := 0 to 7 do
      if Remainder and 1 <> 0 then
        Remainder := $EDB88320 xor (Remainder shr 1)
      else
        Remainder := Remainder shr 1;
    CrcTable[n] := Remainder;
  end;
end;

function UpdateCrc(ACrc: UInt32; const ABuffer; ASize: Integer): UInt32;
var
  Bytes: PByte;
begin
  Result := ACrc;
  Bytes := @ABuffer;
  for var i := 0 to ASize - 1 do
  begin
    Result := CrcTable[(Result xor Bytes[i]) and $FF] xor (Result shr 8);
  end;
end;

// PNG is big-endian everywhere; x86 is not.
function ToBigEndian(AValue: UInt32): UInt32;
begin
  Result := ((AValue and $000000FF) shl 24) or
            ((AValue and $0000FF00) shl 8) or
            ((AValue and $00FF0000) shr 8) or
            ((AValue and $FF000000) shr 24);
end;

procedure WriteChunk(const AStream: TStream; const ATag: AnsiString;
  const AData: TBytes);
var
  Crc: UInt32;
begin
  var SizeField := ToBigEndian(Length(AData));
  AStream.WriteBuffer(SizeField, SizeOf(SizeField));
  AStream.WriteBuffer(PAnsiChar(ATag)^, 4);
  if Length(AData) > 0 then
    AStream.WriteBuffer(AData[0], Length(AData));

  // The CRC covers the type tag and the data, never the length field.
  Crc := UpdateCrc($FFFFFFFF, PAnsiChar(ATag)^, 4);
  if Length(AData) > 0 then
    Crc := UpdateCrc(Crc, AData[0], Length(AData));
  Crc := ToBigEndian(Crc xor $FFFFFFFF);
  AStream.WriteBuffer(Crc, SizeOf(Crc));
end;

function BuildHeaderChunk(AWidth, AHeight: Integer): TBytes;
begin
  SetLength(Result, 13);
  var Field := ToBigEndian(AWidth);
  Move(Field, Result[0], SizeOf(Field));
  Field := ToBigEndian(AHeight);
  Move(Field, Result[4], SizeOf(Field));
  Result[8] := PngBitDepth;
  Result[9] := PngColorTypeRgba;
  Result[10] := 0; // compression: deflate, the only value there is
  Result[11] := 0; // filter method: adaptive, the only value there is
  Result[12] := 0; // interlace: none
end;

// Every PNG row carries a leading filter byte. None keeps the encoder
// honest and costs nothing here: a title card is mostly long runs of
// identical pixels, which deflate eats for breakfast.
function BuildRawScanlines(const APixels: TBytes;
  AWidth, AHeight: Integer): TBytes;
begin
  var RowSize := AWidth * BytesPerPixel;
  SetLength(Result, AHeight * (RowSize + 1));
  for var i := 0 to AHeight - 1 do
  begin
    var Target := i * (RowSize + 1);
    Result[Target] := PngFilterNone;
    Move(APixels[i * RowSize], Result[Target + 1], RowSize);
  end;
end;

function ZlibCompress(const AData: TBytes): TBytes;
var
  Output: TMemoryStream;
begin
  Output := TMemoryStream.Create;
  try
    // Delphi 12 offers Create(dest), Create(dest, level, windowBits) and
    // the legacy Create(level, dest) - there is no (dest, level) pair.
    // The three-argument form is the one that says what it does.
    var Compressor := TZCompressionStream.Create(Output, zcDefault,
      ZlibWindowBits);
    try
      if Length(AData) > 0 then
        Compressor.WriteBuffer(AData[0], Length(AData));
    finally
      Compressor.Free; // flushes the deflate tail into Output
    end;
    SetLength(Result, Output.Size);
    if Output.Size > 0 then
      Move(Output.Memory^, Result[0], Output.Size);
  finally
    Output.Free;
  end;
end;

procedure SavePngRgba(const AFileName: string; const APixels: TBytes;
  AWidth, AHeight: Integer);
var
  Stream: TFileStream;
begin
  if (AWidth <= 0) or (AHeight <= 0) then
    raise EPngError.CreateFmt(SPngEmptyImage, [AWidth, AHeight]);
  var Needed := AWidth * AHeight * BytesPerPixel;
  if Length(APixels) < Needed then
    raise EPngError.CreateFmt(SPngBufferTooSmall,
      [Length(APixels), AWidth, AHeight, Needed]);

  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    Stream.WriteBuffer(PngSignature, SizeOf(PngSignature));
    WriteChunk(Stream, 'IHDR', BuildHeaderChunk(AWidth, AHeight));
    WriteChunk(Stream, 'IDAT',
      ZlibCompress(BuildRawScanlines(APixels, AWidth, AHeight)));
    WriteChunk(Stream, 'IEND', nil);
  finally
    Stream.Free;
  end;
end;

initialization
  BuildCrcTable;

end.
