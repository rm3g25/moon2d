{
  Sdl2.Core - minimal SDL2 bindings: window, renderer, events, timing,
  and the surface/texture sprite pipeline.

  Deliberately a subset: exactly what the game needs, so the project
  compiles with nothing but sdl2.dll next to the exe. Audio lives in its
  own unit (SDL2_mixer, delayed imports). Should a need outgrow this
  file, the community SDL2-for-Pascal headers are a uses-clause swap -
  the function signatures are identical.

  Moon 2D remake. Requires Delphi 12+.
}
unit Sdl2.Core;
{$I Moon2D.inc}

interface

const
  SdlLib = 'SDL2.dll';

  SdlInitVideo = $00000020;

  SdlWindowPosCentered = $2FFF0000;
  SdlWindowShown = $00000004;
  SdlWindowHidden = $00000008; // offscreen work: a renderer still needs
                               // a window, nobody needs to see it
  SdlWindowFullscreenDesktop = $00001001;

  SdlRendererSoftware = $00000001;
  SdlRendererAccelerated = $00000002;
  SdlRendererPresentVsync = $00000004;
  SdlRendererTargetTexture = $00000008;

  // SDL_TextureAccess
  SdlTextureAccessStatic = 0;
  SdlTextureAccessStreaming = 1;
  SdlTextureAccessTarget = 2; // can be passed to SDL_SetRenderTarget

  // SDL_SetHint key: which renderer backend SDL_CreateRenderer picks.
  // Values of interest here: 'direct3d11', 'direct3d' (D3D9), 'opengl',
  // 'software'. The software one has no swapchain and no driver mood
  // swings - the safe pick for offscreen rendering.
  SdlHintRenderDriver = 'SDL_RENDER_DRIVER';
  // '0' nearest, '1' linear, '2' anisotropic. A bitmap font scaled with
  // interpolation turns into porridge; offscreen tools must pin it to 0.
  SdlHintRenderScaleQuality = 'SDL_RENDER_SCALE_QUALITY';

  // Event types
  SdlEventQuit = $100;
  SdlEventKeyDown = $300;
  SdlEventKeyUp = $301;
  SdlEventMouseMotion = $400;
  SdlEventMouseButtonDown = $401;
  SdlEventMouseButtonUp = $402;

  // SDL_RendererFlip
  SdlFlipNone = 0;
  SdlFlipHorizontal = 1;
  SdlFlipVertical = 2;

  // SDL_PIXELFORMAT_ABGR8888 = RGBA32 on little-endian (the only kind of
  // endian this game will ever meet): memory byte order R, G, B, A.
  SdlPixelFormatAbgr8888 = $16762004;

  // SDL_BlendMode
  SdlBlendModeNone = 0;  // dst = src, alpha included: the only way a
                         // RenderClear actually WRITES alpha 0
  SdlBlendModeBlend = 1; // alpha blending: dst = src*a + dst*(1-a)

  // Scancodes (physical keys, layout-independent)
  SdlScancodeReturn = 40;
  SdlScancodeEscape = 41;
  SdlScancodeLCtrl = 224;
  SdlScancodeLAlt = 226;
  SdlScancodeRCtrl = 228;
  SdlScancodeRAlt = 230;
  SdlScancodeSpace = 44;
  SdlScancodeRight = 79;
  SdlScancodeLeft = 80;
  SdlScancodeDown = 81;
  SdlScancodeUp = 82;

type
  PSdlWindow = Pointer;
  PSdlRenderer = Pointer;
  PSdlTexture = Pointer;
  PSdlPixelFormat = Pointer;
  PSdlRWops = Pointer;

  TSdlRect = record
    X, Y, W, H: Integer;
  end;
  PSdlRect = ^TSdlRect;

  TSdlPoint = record
    X, Y: Integer;
  end;
  PSdlPoint = ^TSdlPoint;

  // SDL_RendererInfo: Name identifies the active backend ('direct3d11',
  // 'direct3d', 'opengl', ...) - the diagnostic for present-path issues.
  TSdlRendererInfo = record
    Name: PAnsiChar;
    Flags: UInt32;
    NumTextureFormats: UInt32;
    TextureFormats: array [0..15] of UInt32;
    MaxTextureWidth: Integer;
    MaxTextureHeight: Integer;
  end;
  PSdlRendererInfo = ^TSdlRendererInfo;

  // Float destination rectangle: sub-pixel positioning for smooth
  // movers (the marquee). SDL scales through the logical-size transform
  // with float precision instead of snapping to logical pixels.
  TSdlFRect = record
    X, Y, W, H: Single;
  end;
  PSdlFRect = ^TSdlFRect;

  // SDL_version: the linked DLL's version - the one diagnostic that
  // settles SDL_Delay granularity questions (see the Timing section).
  TSdlVersion = record
    Major: UInt8;
    Minor: UInt8;
    Patch: UInt8;
  end;
  PSdlVersion = ^TSdlVersion;

  // Partial mirror of SDL_Surface: only the leading fields the game reads.
  // SDL owns and frees these; never allocate one from Pascal.
  TSdlSurface = record
    Flags: UInt32;
    Format: PSdlPixelFormat;
    W: Integer;
    H: Integer;
    Pitch: Integer;
    Pixels: Pointer;
  end;
  PSdlSurface = ^TSdlSurface;

  TSdlKeysym = record
    Scancode: Integer;
    Sym: Integer;
    Modifiers: UInt16;
    Unused: UInt32;
  end;

  TSdlKeyboardEvent = record
    EventType: UInt32;
    Timestamp: UInt32;
    WindowId: UInt32;
    State: UInt8;
    IsRepeat: UInt8;
    Padding2: UInt8;
    Padding3: UInt8;
    Keysym: TSdlKeysym;
  end;

  TSdlMouseMotionEvent = record
    EventType: UInt32;
    Timestamp: UInt32;
    WindowId: UInt32;
    Which: UInt32;
    State: UInt32;
    X: Int32;      // in LOGICAL coordinates when logical size is set
    Y: Int32;
    XRel: Int32;
    YRel: Int32;
  end;

  TSdlMouseButtonEvent = record
    EventType: UInt32;
    Timestamp: UInt32;
    WindowId: UInt32;
    Which: UInt32;
    Button: UInt8;
    State: UInt8;
    Clicks: UInt8;
    Padding1: UInt8;
    X: Int32;
    Y: Int32;
  end;

  // SDL_Event is a C union 56 bytes wide; the padding arm guarantees the
  // full size so SDL can write any event into it safely.
  TSdlEvent = record
    case Integer of
      0: (EventType: UInt32);
      1: (Key: TSdlKeyboardEvent);
      2: (Motion: TSdlMouseMotionEvent);
      3: (Button: TSdlMouseButtonEvent);
      4: (Padding: array [0..55] of Byte);
  end;
  PSdlEvent = ^TSdlEvent;

// --- Init, window, renderer ---

function SDL_Init(AFlags: UInt32): Integer; cdecl;
  external SdlLib name 'SDL_Init';
procedure SDL_Quit; cdecl;
  external SdlLib name 'SDL_Quit';
function SDL_GetError: PAnsiChar; cdecl;
  external SdlLib name 'SDL_GetError';

function SDL_CreateWindow(const ATitle: PAnsiChar; AX, AY, AW, AH: Integer;
  AFlags: UInt32): PSdlWindow; cdecl;
  external SdlLib name 'SDL_CreateWindow';
procedure SDL_DestroyWindow(AWindow: PSdlWindow); cdecl;
  external SdlLib name 'SDL_DestroyWindow';
procedure SDL_SetWindowTitle(AWindow: PSdlWindow;
  const ATitle: PAnsiChar); cdecl;
  external SdlLib name 'SDL_SetWindowTitle';
// AFlags: SdlWindowFullscreenDesktop to go borderless-fullscreen,
// 0 to return to a window. The logical-size scaler handles the rest.
function SDL_SetWindowFullscreen(AWindow: PSdlWindow;
  AFlags: UInt32): Integer; cdecl;
  external SdlLib name 'SDL_SetWindowFullscreen';

function SDL_CreateRenderer(AWindow: PSdlWindow; AIndex: Integer;
  AFlags: UInt32): PSdlRenderer; cdecl;
  external SdlLib name 'SDL_CreateRenderer';
function SDL_GetRendererInfo(ARenderer: PSdlRenderer;
  AInfo: PSdlRendererInfo): Integer; cdecl;
  external SdlLib name 'SDL_GetRendererInfo';
procedure SDL_DestroyRenderer(ARenderer: PSdlRenderer); cdecl;
  external SdlLib name 'SDL_DestroyRenderer';
function SDL_SetRenderDrawColor(ARenderer: PSdlRenderer;
  AR, AG, AB, AA: UInt8): Integer; cdecl;
  external SdlLib name 'SDL_SetRenderDrawColor';
// Fills a rect with the current draw color - the menu language box
function SDL_RenderFillRectF(ARenderer: PSdlRenderer;
  const ARect: PSdlFRect): Integer; cdecl;
  external SdlLib name 'SDL_RenderFillRectF';
function SDL_RenderClear(ARenderer: PSdlRenderer): Integer; cdecl;
  external SdlLib name 'SDL_RenderClear';
procedure SDL_RenderPresent(ARenderer: PSdlRenderer); cdecl;
  external SdlLib name 'SDL_RenderPresent';

// --- Events ---

function SDL_PollEvent(AEvent: PSdlEvent): Integer; cdecl;
  external SdlLib name 'SDL_PollEvent';

// --- Surfaces and textures (sprite pipeline) ---

function SDL_RWFromFile(const AFile, AMode: PAnsiChar): PSdlRWops; cdecl;
  external SdlLib name 'SDL_RWFromFile';
function SDL_RWFromMem(AMem: Pointer; ASize: Integer): PSdlRWops; cdecl;
  external SdlLib name 'SDL_RWFromMem';
function SDL_LoadBMP_RW(ASrc: PSdlRWops; AFreeSrc: Integer): PSdlSurface;
  cdecl; external SdlLib name 'SDL_LoadBMP_RW';
procedure SDL_FreeSurface(ASurface: PSdlSurface); cdecl;
  external SdlLib name 'SDL_FreeSurface';
function SDL_SetColorKey(ASurface: PSdlSurface; AFlag: Integer;
  AKey: UInt32): Integer; cdecl;
  external SdlLib name 'SDL_SetColorKey';
function SDL_MapRGB(AFormat: PSdlPixelFormat;
  AR, AG, AB: UInt8): UInt32; cdecl;
  external SdlLib name 'SDL_MapRGB';
function SDL_ConvertSurfaceFormat(ASurface: PSdlSurface; AFormat: UInt32;
  AFlags: UInt32): PSdlSurface; cdecl;
  external SdlLib name 'SDL_ConvertSurfaceFormat';
function SDL_CreateRGBSurfaceWithFormat(AFlags: UInt32;
  AW, AH, ADepth: Integer; AFormat: UInt32): PSdlSurface; cdecl;
  external SdlLib name 'SDL_CreateRGBSurfaceWithFormat';
function SDL_LockSurface(ASurface: PSdlSurface): Integer; cdecl;
  external SdlLib name 'SDL_LockSurface';
procedure SDL_UnlockSurface(ASurface: PSdlSurface); cdecl;
  external SdlLib name 'SDL_UnlockSurface';
function SDL_SetTextureBlendMode(ATexture: PSdlTexture;
  ABlendMode: Integer): Integer; cdecl;
  external SdlLib name 'SDL_SetTextureBlendMode';
function SDL_SetTextureAlphaMod(ATexture: PSdlTexture;
  AAlpha: UInt8): Integer; cdecl;
  external SdlLib name 'SDL_SetTextureAlphaMod';
function SDL_CreateTextureFromSurface(ARenderer: PSdlRenderer;
  ASurface: PSdlSurface): PSdlTexture; cdecl;
  external SdlLib name 'SDL_CreateTextureFromSurface';
// AAccess = SdlTextureAccessTarget for an offscreen canvas.
function SDL_CreateTexture(ARenderer: PSdlRenderer; AFormat: UInt32;
  AAccess, AW, AH: Integer): PSdlTexture; cdecl;
  external SdlLib name 'SDL_CreateTexture';
procedure SDL_DestroyTexture(ATexture: PSdlTexture); cdecl;
  external SdlLib name 'SDL_DestroyTexture';
function SDL_QueryTexture(ATexture: PSdlTexture; AFormat: PUInt32;
  AAccess: PInteger; AW, AH: PInteger): Integer; cdecl;
  external SdlLib name 'SDL_QueryTexture';

function SDL_RenderCopy(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ASrcRect, ADstRect: PSdlRect): Integer; cdecl;
  external SdlLib name 'SDL_RenderCopy';
function SDL_RenderCopyF(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ASrcRect: PSdlRect; const ADstRect: PSdlFRect): Integer; cdecl;
  external SdlLib name 'SDL_RenderCopyF';
function SDL_RenderCopyEx(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ASrcRect, ADstRect: PSdlRect; AAngle: Double;
  const ACenter: PSdlPoint; AFlip: Integer): Integer; cdecl;
  external SdlLib name 'SDL_RenderCopyEx';
function SDL_RenderSetLogicalSize(ARenderer: PSdlRenderer;
  AW, AH: Integer): Integer; cdecl;
  external SdlLib name 'SDL_RenderSetLogicalSize';
function SDL_SetRenderDrawBlendMode(ARenderer: PSdlRenderer;
  ABlendMode: Integer): Integer; cdecl;
  external SdlLib name 'SDL_SetRenderDrawBlendMode';

// --- Offscreen rendering (tools: title cards, level editor, screenshots) ---
// ATexture must have been created with SdlTextureAccessTarget; nil puts
// the window back on the receiving end.
function SDL_SetRenderTarget(ARenderer: PSdlRenderer;
  ATexture: PSdlTexture): Integer; cdecl;
  external SdlLib name 'SDL_SetRenderTarget';
// Reads back the CURRENT render target. APitch is bytes per row.
// With SdlPixelFormatAbgr8888 the buffer comes out as plain R,G,B,A -
// straight into a PNG encoder, no channel shuffling.
function SDL_RenderReadPixels(ARenderer: PSdlRenderer;
  const ARect: PSdlRect; AFormat: UInt32; APixels: Pointer;
  APitch: Integer): Integer; cdecl;
  external SdlLib name 'SDL_RenderReadPixels';
// SDL_bool is a 4-byte C enum: LongBool reads the full EAX return.
function SDL_SetHint(const AName, AValue: PAnsiChar): LongBool; cdecl;
  external SdlLib name 'SDL_SetHint';

// --- Timing ---
// SDL_Delay granularity is version-dependent on Windows: SDL >= 2.0.16
// uses high-resolution waitable timers (accurate to ~1 ms); older DLLs
// fall back to Sleep and round UP to the 15.6 ms scheduler tick - a
// classic source of windowed-mode stutter. Ship a modern SDL2.dll;
// the version lands in the window title via SDL_GetVersion.
function SDL_GetPerformanceCounter: UInt64; cdecl;
  external SdlLib name 'SDL_GetPerformanceCounter';
function SDL_GetPerformanceFrequency: UInt64; cdecl;
  external SdlLib name 'SDL_GetPerformanceFrequency';
procedure SDL_Delay(AMilliseconds: UInt32); cdecl;
  external SdlLib name 'SDL_Delay';
procedure SDL_GetVersion(AVersion: PSdlVersion); cdecl;
  external SdlLib name 'SDL_GetVersion';

// Convenience: SDL expects UTF-8 in every string it takes.
function SdlText(const AText: string): UTF8String;
// SDL_GetError as a Delphi string - shared by every unit that reports.
function SdlErrorText: string;

implementation

function SdlText(const AText: string): UTF8String;
begin
  Result := UTF8Encode(AText);
end;

function SdlErrorText: string;
begin
  Result := string(AnsiString(SDL_GetError));
end;

end.
