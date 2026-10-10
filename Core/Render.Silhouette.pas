{
  Render.Silhouette - what is made of the alpha of a picture: the points
  that lie in its body, a white mask in its shape and a blurred halo
  round it.

  Nothing here knows what the picture is. The caller says how large it is
  drawn, in screen units, and the points come back in those units, from
  the picture's corner as painted. The mask and the halo are glow
  textures (Render.Glow): they add onto what lies beneath.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Silhouette;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core;

type
  ESilhouetteError = class(Exception);

  // Opaque points of a picture, in units from its corner as painted
  TSeedList = TArray<TSdlFPoint>;

  // What is made of a picture's alpha
  TSilhouette = record
    Seeds: TSeedList;
    Mask: PSdlTexture; // white, with the picture's alpha
    Halo: PSdlTexture; // the alpha blurred
    HaloMarginX, HaloMarginY: Single; // units the halo reaches past the picture
    TexW, TexH: Integer; // texels of the picture
  end;

// ASurface is ABGR8888; AWidth, AHeight - the picture's size on the screen,
// in units
function BuildSilhouette(ARenderer: PSdlRenderer; ASurface: PSdlSurface;
  AWidth, AHeight: Single): TSilhouette;
procedure FreeSilhouette(var ASilhouette: TSilhouette);

implementation

uses
  Render.Glow;

resourcestring
  SSilhouetteMaskFailed = 'Cannot build a silhouette mask: %s';

type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888

const
  SeedAlpha = 128;
  // A picture wider than this is shrunk to it before it is blurred
  HaloMaxCells = 64;
  // Units, from the edge of the body
  HaloReach = 2.5;
  HaloPasses = 3;

function CollectSeeds(ASurface: PSdlSurface; AWidth, AHeight: Single): TSeedList;
begin
  SetLength(Result, ASurface.W * ASurface.H);
  var Count := 0;
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    for var Col := 0 to ASurface.W - 1 do
    begin
      if Pixel[3] >= SeedAlpha then
      begin
        Result[Count].X := (Col + 0.5) * AWidth / ASurface.W;
        Result[Count].Y := (Row + 0.5) * AHeight / ASurface.H;
        Inc(Count);
      end;
      Inc(Pixel);
    end;
  end;
  SetLength(Result, Count);
end;

function CreateMask(ARenderer: PSdlRenderer; ASurface: PSdlSurface): PSdlTexture;
begin
  var Mask := SDL_CreateRGBSurfaceWithFormat(0, ASurface.W, ASurface.H, 32,
    SdlPixelFormatAbgr8888);
  if Mask = nil then
    raise ESilhouetteError.CreateFmt(SSilhouetteMaskFailed, [SdlErrorText]);
  try
    SDL_LockSurface(Mask);
    try
      for var Row := 0 to ASurface.H - 1 do
      begin
        var Source := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
        var Target := PPixelBytes(PByte(Mask.Pixels) + Row * Mask.Pitch);
        for var Col := 0 to ASurface.W - 1 do
        begin
          Target[0] := 255;
          Target[1] := 255;
          Target[2] := 255;
          Target[3] := Source[3];
          Inc(Source);
          Inc(Target);
        end;
      end;
    finally
      SDL_UnlockSurface(Mask);
    end;
    Result := CreateGlowTexture(ARenderer, Mask);
  finally
    SDL_FreeSurface(Mask);
  end;
end;

// The picture's alpha shrunk into the middle of an apron-padded image,
// blurred and made a glow; the margins are how far the apron reaches, in units
function CreateHalo(ARenderer: PSdlRenderer; ASurface: PSdlSurface;
  AWidth, AHeight: Single; out AMarginX, AMarginY: Single): PSdlTexture;
var
  Image: TArray<Single>;
begin
  var Scale := (ASurface.W + HaloMaxCells - 1) div HaloMaxCells;
  var CellsX := (ASurface.W + Scale - 1) div Scale;
  var CellsY := (ASurface.H + Scale - 1) div Scale;
  var Radius: Integer := Round(HaloReach * CellsX / AWidth);
  if Radius < 1 then
    Radius := 1;
  var Apron := Radius * HaloPasses;
  var Width := CellsX + 2 * Apron;
  var Height := CellsY + 2 * Apron;
  SetLength(Image, Width * Height);

  var BlockArea := Scale * Scale * 255;
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    var Target := (Row div Scale + Apron) * Width + Apron;
    for var Col := 0 to ASurface.W - 1 do
    begin
      var Cell := Target + Col div Scale;
      Image[Cell] := Image[Cell] + Pixel[3] / BlockArea;
      Inc(Pixel);
    end;
  end;

  BlurImage(Image, Width, Height, Radius, HaloPasses);
  AMarginX := Apron * (AWidth * Scale / ASurface.W);
  AMarginY := Apron * (AHeight * Scale / ASurface.H);
  Result := CreateGlowFromImage(ARenderer, Image, Width, Height);
end;

function BuildSilhouette(ARenderer: PSdlRenderer; ASurface: PSdlSurface;
  AWidth, AHeight: Single): TSilhouette;
begin
  Result := Default(TSilhouette);
  Result.TexW := ASurface.W;
  Result.TexH := ASurface.H;
  SDL_LockSurface(ASurface);
  try
    Result.Seeds := CollectSeeds(ASurface, AWidth, AHeight);
    Result.Mask := CreateMask(ARenderer, ASurface);
    try
      Result.Halo := CreateHalo(ARenderer, ASurface, AWidth, AHeight,
        Result.HaloMarginX, Result.HaloMarginY);
    except
      FreeSilhouette(Result);
      raise;
    end;
  finally
    SDL_UnlockSurface(ASurface);
  end;
end;

procedure FreeSilhouette(var ASilhouette: TSilhouette);
begin
  if Assigned(ASilhouette.Mask) then
    SDL_DestroyTexture(ASilhouette.Mask);
  if Assigned(ASilhouette.Halo) then
    SDL_DestroyTexture(ASilhouette.Halo);
  ASilhouette := Default(TSilhouette);
end;

end.
