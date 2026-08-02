{
  Sdl2.Image - SDL2_image bindings, PNG loading for every asset.

  Retires SDL_LoadBMP across the codebase: sprites, tiles, backgrounds,
  the font atlas and the menu art all moved from BMP to PNG with baked
  alpha (tools/bmp2png/convert.py wrote them, preserving the exact
  color-key rule: pure black -> transparent).

  Imports are delay-loaded like SDL2_mixer's - but unlike sound, a game
  with no art is no game, so a missing DLL here is fatal.

  Moon 2D remake. Requires SDL2_image 2.6+ (PNG decoder built in,
  single self-contained DLL).
}
unit Sdl2.Image;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core;

const
  ImageLib = 'SDL2_image.dll';

  ImgInitPng = $00000002; // IMG_INIT_PNG

type
  EImageError = class(Exception);

// Same deliberate Windows-only 'delayed' choice as Audio.pas - the DLL
// ships beside the exe. W1002 acknowledged, scoped tight.
{$WARN SYMBOL_PLATFORM OFF}
function IMG_Init(AFlags: Integer): Integer; cdecl;
  external ImageLib name 'IMG_Init' delayed;
procedure IMG_Quit; cdecl;
  external ImageLib name 'IMG_Quit' delayed;
function IMG_Load_RW(ASrc: PSdlRWops; AFreeSrc: Integer): PSdlSurface;
  cdecl; external ImageLib name 'IMG_Load_RW' delayed;
{$WARN SYMBOL_PLATFORM DEFAULT}

// Call once at startup, before any asset loads. Raises EImageError with
// a plain-language message if the DLL is absent or PNG support is not.
procedure EnsureImageLib;

implementation

resourcestring
  SImageLibMissing =
    'SDL2_image.dll is missing or has no PNG support. ' +
    'Put SDL2_image.dll (2.6 or newer) next to Moon2D.exe.';

procedure EnsureImageLib;
begin
  try
    if (IMG_Init(ImgInitPng) and ImgInitPng) = 0 then
      raise EImageError.Create(SImageLibMissing);
  except
    // Delay-load failure surfaces as an external exception on the first
    // call; translate it instead of letting the loader speak hex.
    on EImageError do
      raise;
    on Exception do
      raise EImageError.Create(SImageLibMissing);
  end;
end;

end.
