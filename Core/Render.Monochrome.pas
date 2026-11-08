{
  Render.Monochrome - a picture made black and white, its contrast raised:
  the moon form's look for as long as its frames are the ice form's,
  till the hero is drawn anew.

  The grey is the eye's (Rec. 601 weights); the contrast is stretched
  about the middle grey. What the cache would key out - pure black on a
  2008 frame - is made clear here, since the texture made here has no key.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Monochrome;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Sprites.Sets;

type
  EMonochromeError = class(Exception);

  // R, G, B, A of SdlPixelFormatAbgr8888
  TRgbaBytes = array [0..3] of Byte;

// The pixel in grey, AContrast times as far from the middle grey as it
// was, its alpha kept; pure black clear
function MonochromeOf(const APixel: TRgbaBytes; AContrast: Single): TRgbaBytes;

// The picture AName of ASkin made monochrome, as a texture of its own -
// the caller destroys it
function CreateMonochromeTexture(ARenderer: PSdlRenderer;
  const ASkin: TSpriteSet; const AName: string; AContrast: Single): PSdlTexture;

implementation

uses
  System.Math, Render.Sprites;

type
  PRgbaBytes = ^TRgbaBytes;

resourcestring
  SMonochromeFailed = 'Picture "%s" made monochrome: %s';

const
  MiddleGrey = 127.5;

function MonochromeOf(const APixel: TRgbaBytes; AContrast: Single): TRgbaBytes;
begin
  var Keyed := (APixel[0] = 0) and (APixel[1] = 0) and (APixel[2] = 0);
  var Grey: Single := 0.299 * APixel[0] + 0.587 * APixel[1] + 0.114 * APixel[2];
  var Stretched := Round(EnsureRange(MiddleGrey + (Grey - MiddleGrey) * AContrast,
    0, 255));
  Result[0] := Stretched;
  Result[1] := Stretched;
  Result[2] := Stretched;
  Result[3] := APixel[3];
  if Keyed then
    Result[3] := 0;
end;

function CreateMonochromeTexture(ARenderer: PSdlRenderer;
  const ASkin: TSpriteSet; const AName: string; AContrast: Single): PSdlTexture;
begin
  var Loaded := LoadImageSurface(ASkin, AName);
  if Loaded = nil then
    raise EMonochromeError.CreateFmt(SMonochromeFailed, [AName, SdlErrorText]);
  var Surface := SDL_ConvertSurfaceFormat(Loaded, SdlPixelFormatAbgr8888, 0);
  SDL_FreeSurface(Loaded);
  if Surface = nil then
    raise EMonochromeError.CreateFmt(SMonochromeFailed, [AName, SdlErrorText]);
  try
    SDL_LockSurface(Surface);
    try
      for var Row := 0 to Surface.H - 1 do
      begin
        var Pixel := PRgbaBytes(PByte(Surface.Pixels) + Row * Surface.Pitch);
        for var Col := 0 to Surface.W - 1 do
        begin
          Pixel^ := MonochromeOf(Pixel^, AContrast);
          Inc(Pixel);
        end;
      end;
    finally
      SDL_UnlockSurface(Surface);
    end;
    Result := SDL_CreateTextureFromSurface(ARenderer, Surface);
    if Result = nil then
      raise EMonochromeError.CreateFmt(SMonochromeFailed, [AName, SdlErrorText]);
    SDL_SetTextureBlendMode(Result, SdlBlendModeBlend);
  finally
    SDL_FreeSurface(Surface);
  end;
end;

end.
