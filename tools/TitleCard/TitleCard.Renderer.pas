{
  TitleCard.Renderer - the game's renderer, first time outside the game
  loop. A hidden window, a render-target texture, one read-back.

  Why a live renderer at all: TMoonFont owns an SDL texture, and the only
  way to draw a texture is a renderer. The window exists because
  SDL_CreateRenderer demands one; nobody ever sees it, and at 64x64 it
  costs nothing.

  Why the SOFTWARE backend by default: no swapchain, no driver quirks, no
  GPU rounding to argue with, and SDL_RenderReadPixels off a target
  surface is a straight memcpy. A card is a couple of megabytes filled
  once - hardware acceleration would optimise the wrong thing. The INI
  can still switch it to direct3d11 if a card ever needs it.

  This unit is also the dress rehearsal for the level editor, which will
  want exactly this: game renderers, no game loop.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit TitleCard.Renderer;

interface

uses
  System.SysUtils, Sdl2.Core, Sprites.Sets, Render.Font, TitleCard.Layout;

type
  ECardRenderError = class(Exception);

  TCardBackground = (cbTransparent, cbBlack);

  TCardRenderer = class
  private
    FWindow: PSdlWindow;
    FRenderer: PSdlRenderer;
    FSpriteSet: TSpriteSet;
    FFont: TMoonFont;
    procedure ClearTarget(ABackground: TCardBackground);
    procedure DrawLines(const ALayout: TCardLayout);
  public
    constructor Create(const ASetFileName, AFontSpriteName,
      ARenderDriver: string);
    destructor Destroy; override;
    // Returns AWidth*AHeight*4 bytes, top-down, R,G,B,A - the exact
    // input SavePngRgba wants.
    function RenderCard(const ALayout: TCardLayout;
      AWidth, AHeight: Integer; ABackground: TCardBackground): TBytes;
    property Font: TMoonFont read FFont;
  end;

implementation

resourcestring
  SSdlInitFailed = 'SDL_Init failed: %s';
  SWindowFailed = 'Cannot create the offscreen window: %s';
  SRendererFailed = 'Cannot create the offscreen renderer: %s';
  STargetFailed = 'Cannot create a %dx%d render target: %s';
  SReadPixelsFailed = 'Cannot read the rendered card back: %s';

const
  // Nobody looks at it; it only has to exist.
  HiddenWindowSide = 64;
  // Typed on purpose: a one-character untyped constant is a Char, and
  // Char does not go where SDL_SetHint wants a PAnsiChar.
  ScaleQualityNearest: AnsiString = '0';

constructor TCardRenderer.Create(const ASetFileName, AFontSpriteName,
  ARenderDriver: string);
begin
  inherited Create;
  if SDL_Init(SdlInitVideo) <> 0 then
    raise ECardRenderError.CreateFmt(SSdlInitFailed, [SdlErrorText]);

  // Both hints must land before the renderer and its textures exist.
  SDL_SetHint(SdlHintRenderScaleQuality, PAnsiChar(ScaleQualityNearest));
  if ARenderDriver <> '' then
    SDL_SetHint(SdlHintRenderDriver, PAnsiChar(SdlText(ARenderDriver)));

  FWindow := SDL_CreateWindow(PAnsiChar(SdlText('Moon 2D TitleCard')),
    SdlWindowPosCentered, SdlWindowPosCentered,
    HiddenWindowSide, HiddenWindowSide, SdlWindowHidden);
  if FWindow = nil then
    raise ECardRenderError.CreateFmt(SWindowFailed, [SdlErrorText]);

  FRenderer := SDL_CreateRenderer(FWindow, -1, SdlRendererTargetTexture);
  if FRenderer = nil then
    raise ECardRenderError.CreateFmt(SRendererFailed, [SdlErrorText]);

  // The atlas is a sprite in a container now, so the set has to outlive
  // the font's constructor - and the font does not own it.
  FSpriteSet := TSpriteSet.Create(ASetFileName);
  FFont := TMoonFont.Create(FRenderer, AFontSpriteName, faRotatedCw,
    FSpriteSet);
end;

destructor TCardRenderer.Destroy;
begin
  // Order matters: the font holds a texture born of this renderer, and
  // it reads through the set while loading.
  FFont.Free;
  FSpriteSet.Free;
  if Assigned(FRenderer) then
    SDL_DestroyRenderer(FRenderer);
  if Assigned(FWindow) then
    SDL_DestroyWindow(FWindow);
  SDL_Quit;
  inherited;
end;

procedure TCardRenderer.ClearTarget(ABackground: TCardBackground);
begin
  // BlendMode NONE makes RenderClear WRITE the alpha instead of blending
  // a transparent colour over the target and changing nothing. Without
  // this the "transparent" card comes out opaque black.
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeNone);
  if ABackground = cbBlack then
    SDL_SetRenderDrawColor(FRenderer, 0, 0, 0, 255)
  else
    SDL_SetRenderDrawColor(FRenderer, 0, 0, 0, 0);
  SDL_RenderClear(FRenderer);
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
end;

procedure TCardRenderer.DrawLines(const ALayout: TCardLayout);
begin
  for var Line in ALayout.Lines do
    FFont.DrawScaled(Line.Text, Line.X, Line.Y, ALayout.CellHeight);
end;

function TCardRenderer.RenderCard(const ALayout: TCardLayout;
  AWidth, AHeight: Integer; ABackground: TCardBackground): TBytes;
var
  Target: PSdlTexture;
begin
  Target := SDL_CreateTexture(FRenderer, SdlPixelFormatAbgr8888,
    SdlTextureAccessTarget, AWidth, AHeight);
  if Target = nil then
    raise ECardRenderError.CreateFmt(STargetFailed,
      [AWidth, AHeight, SdlErrorText]);
  try
    SDL_SetTextureBlendMode(Target, SdlBlendModeBlend);
    if SDL_SetRenderTarget(FRenderer, Target) <> 0 then
      raise ECardRenderError.CreateFmt(STargetFailed,
        [AWidth, AHeight, SdlErrorText]);
    try
      ClearTarget(ABackground);
      DrawLines(ALayout);

      SetLength(Result, AWidth * AHeight * 4);
      if SDL_RenderReadPixels(FRenderer, nil, SdlPixelFormatAbgr8888,
        @Result[0], AWidth * 4) <> 0 then
        raise ECardRenderError.CreateFmt(SReadPixelsFailed,
          [SdlErrorText]);
    finally
      SDL_SetRenderTarget(FRenderer, nil);
    end;
  finally
    SDL_DestroyTexture(Target);
  end;
end;

end.
