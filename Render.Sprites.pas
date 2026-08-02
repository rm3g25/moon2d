{
  Render.Sprites - sprite loading and drawing on top of SDL_Renderer.

  Ports the GlSprites.pas family (2008): PutStaticSprite / PutQuadSprite /
  PutMirrorQuadSprite / PutAngleSprite collapse into TSpriteRenderer.Draw*
  calls - SDL_RenderCopyEx handles mirror and rotation natively, so the
  translate/rotate/untranslate dance of the OpenGL version is gone.

  Coordinates are PIXELS in a fixed logical resolution; SDL scales to the
  real window. The old normalized-GL coordinates (0.083, 1/16...) die here.

  Sprite data model follows the 2008 .mns format, which proved itself:
  16 lines of .png names - lines 1-8 the "alive" loop, lines 9-16 the
  death animation. Frames shared between monsters (e1..e8.bmp explosions)
  are loaded once thanks to the cache.

  Transparency: the 2008 renderer had none - black sprite corners simply
  dissolved into the night sky. Here black is a color key by default, so
  the sprites finally become honestly transparent on any background.

  Moon 2D remake. Requires Delphi 12+.
}
unit Render.Sprites;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Sdl2.Core;

const
  SpriteSize = 32;        // entity sprite side, as in 2008 (SptSize)
  TileSize = 32;          // tile side in GAME UNITS: logic runs in 512x384
  TileArtSize = 64;       // tile side in TEXTURE PIXELS (sttextures 64x64
                          // crop) - a different space than game units;
                          // mixing the two once cost us zoomed quarters
                          // (moon.dpr line 1839: SetMaxC(512,384)); the
                          // 64px tile art downsamples 2:1 into logic and
                          // scales back up with the window - net loss zero
  FramesAlive = 8;
  FramesDeath = 8;
  MnsLineCount = FramesAlive + FramesDeath;

type
  ESpriteError = class(Exception);

  TFrameIndex = 0 .. FramesAlive - 1;

  // Owns every texture it ever loaded; frames shared between monsters
  // (e1.bmp and friends) are loaded exactly once.
  TSpriteCache = class
  private
    FRenderer: PSdlRenderer;
    FBaseDir: string;
    FTextures: TDictionary<string, PSdlTexture>;
    FUseColorKey: Boolean;
    FKeyR, FKeyG, FKeyB: UInt8;
    function LoadTexture(const AFileName: string): PSdlTexture;
  public
    constructor Create(const ARenderer: PSdlRenderer; const ABaseDir: string);
    destructor Destroy; override;

    // Returns a cached texture, loading the BMP on first request.
    function Get(const AFileName: string): PSdlTexture;
    // Color key applies to textures loaded AFTER the call; set it up first.
    procedure SetColorKey(AR, AG, AB: UInt8);
    procedure DisableColorKey;
    function Count: Integer;
  end;

  // One monster's animation set: the 16 frames of an .mns file.
  TAnimSet = record
    Alive: array [TFrameIndex] of PSdlTexture;
    Death: array [TFrameIndex] of PSdlTexture;
    function IsLoaded: Boolean;
  end;

// Free function: parsing a text file into a record needs no object state.
function LoadAnimSet(const ACache: TSpriteCache;
  const AMnsFileName: string): TAnimSet;

type
  TSpriteRenderer = class
  private
    FRenderer: PSdlRenderer;
  public
    constructor Create(const ARenderer: PSdlRenderer;
      ALogicalWidth, ALogicalHeight: Integer);

    // PutStaticSprite: draw at a sprite-grid cell, forced to 32x32.
    procedure DrawCell(ATexture: PSdlTexture; AGridX, AGridY: Integer);
    // Level tile: the 2008 loader (sttextures.pas) reads exactly the
    // top-left 64x64 region of ANY bitmap, whatever its size on disk.
    // Reproduced verbatim: source cropped to 64x64, destination one cell.
    procedure DrawTile(ATexture: PSdlTexture; AGridX, AGridY: Integer);
    // PutQuadSprite / PutMirrorQuadSprite: draw at a game-unit
    // position, native size, optionally mirrored (walking direction).
    procedure Draw(ATexture: PSdlTexture; AX, AY: Integer;
      AMirrored: Boolean = False);
    // Arbitrary destination rectangle (backgrounds, scaled effects).
    procedure DrawRect(ATexture: PSdlTexture; const ADest: TSdlRect);
    // PutAngleSprite / PutMirrorAngleSprite: rotation around the sprite
    // center. Angle in degrees, clockwise, 0 = art's natural orientation.
    // The 2008 code drew bullets with a -90 offset because the art pointed
    // up; apply such offsets at the call site, not here.
    procedure DrawRotated(ATexture: PSdlTexture; ACenterX, ACenterY: Integer;
      AAngleDegrees: Double; AMirrored: Boolean = False);
  end;

implementation

uses
  System.Math, Sdl2.Image;

resourcestring
  SBmpLoadFailed = 'Cannot load sprite "%s": %s';
  STextureCreateFailed = 'Cannot create texture for "%s": %s';
  SMnsNotFound = 'Sprite list not found: %s';
  SMnsTooShort = 'Sprite list "%s": expected %d frame lines, got %d';

// Free function: mapping a Boolean to an SDL flip flag needs no state
function FlipOf(AMirrored: Boolean): Integer;
begin
  if AMirrored then
    Result := SdlFlipHorizontal
  else
    Result := SdlFlipNone;
end;

// ---------------------------------------------------------------------------
// TSpriteCache
// ---------------------------------------------------------------------------

constructor TSpriteCache.Create(const ARenderer: PSdlRenderer;
  const ABaseDir: string);
begin
  inherited Create;
  FRenderer := ARenderer;
  FBaseDir := IncludeTrailingPathDelimiter(ABaseDir);
  FTextures := TDictionary<string, PSdlTexture>.Create;

  // 2008 sprites live on black backgrounds; key it out by default.
  FUseColorKey := True;
  FKeyR := 0;
  FKeyG := 0;
  FKeyB := 0;

  // Nearest-neighbor scaling: pixel art must stay square, not soapy.
  // A global hint in a per-cache constructor looks misplaced, but SDL
  // reads it at TEXTURE CREATION time - it must precede the first Get,
  // and every cache re-asserting the same value is idempotent. Moving
  // it to renderer setup is fine ONLY if that provably runs first.
  SDL_SetHint('SDL_RENDER_SCALE_QUALITY', '0');
end;

destructor TSpriteCache.Destroy;
begin
  if Assigned(FTextures) then
  begin
    for var Texture in FTextures.Values do
      SDL_DestroyTexture(Texture);
    FTextures.Free;
  end;
  inherited;
end;

procedure TSpriteCache.SetColorKey(AR, AG, AB: UInt8);
begin
  FUseColorKey := True;
  FKeyR := AR;
  FKeyG := AG;
  FKeyB := AB;
end;

procedure TSpriteCache.DisableColorKey;
begin
  FUseColorKey := False;
end;

function TSpriteCache.Count: Integer;
begin
  Result := FTextures.Count;
end;

function TSpriteCache.Get(const AFileName: string): PSdlTexture;
var
  Key: string;
begin
  Key := LowerCase(AFileName);
  if FTextures.TryGetValue(Key, Result) then
    Exit;

  Result := LoadTexture(AFileName);
  FTextures.Add(Key, Result);
end;

function TSpriteCache.LoadTexture(const AFileName: string): PSdlTexture;
var
  Surface: PSdlSurface;
begin
  var FullPath := FBaseDir + AFileName;

  Surface := IMG_Load_RW(
    SDL_RWFromFile(PAnsiChar(SdlText(FullPath)), 'rb'), 1);
  if Surface = nil then
    raise ESpriteError.CreateFmt(SBmpLoadFailed, [FullPath, SdlErrorText]);
  try
    if FUseColorKey then
      SDL_SetColorKey(Surface, 1,
        SDL_MapRGB(Surface.Format, FKeyR, FKeyG, FKeyB));

    Result := SDL_CreateTextureFromSurface(FRenderer, Surface);
    if Result = nil then
      raise ESpriteError.CreateFmt(STextureCreateFailed,
        [FullPath, SdlErrorText]);
  finally
    SDL_FreeSurface(Surface);
  end;
end;

// ---------------------------------------------------------------------------
// TAnimSet
// ---------------------------------------------------------------------------

function TAnimSet.IsLoaded: Boolean;
begin
  Result := Assigned(Alive[Low(TFrameIndex)]);
end;

function LoadAnimSet(const ACache: TSpriteCache;
  const AMnsFileName: string): TAnimSet;
var
  Lines: TStringList;
begin
  Result := Default(TAnimSet);

  if not FileExists(AMnsFileName) then
    raise ESpriteError.CreateFmt(SMnsNotFound, [AMnsFileName]);

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AMnsFileName);

    // Trailing blank lines are part of the 2008 charm; drop them.
    while (Lines.Count > 0) and (Trim(Lines[Lines.Count - 1]) = '') do
      Lines.Delete(Lines.Count - 1);

    if Lines.Count < MnsLineCount then
      raise ESpriteError.CreateFmt(SMnsTooShort,
        [AMnsFileName, MnsLineCount, Lines.Count]);

    for var i := Low(TFrameIndex) to High(TFrameIndex) do
    begin
      Result.Alive[i] := ACache.Get(Trim(Lines[i]));
      Result.Death[i] := ACache.Get(Trim(Lines[FramesAlive + i]));
    end;
  finally
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
// TSpriteRenderer
// ---------------------------------------------------------------------------

constructor TSpriteRenderer.Create(const ARenderer: PSdlRenderer;
  ALogicalWidth, ALogicalHeight: Integer);
begin
  inherited Create;
  FRenderer := ARenderer;
  // The game thinks in a fixed pixel resolution; SDL letterboxes and
  // scales it to whatever window the player actually has.
  SDL_RenderSetLogicalSize(ARenderer, ALogicalWidth, ALogicalHeight);
end;

procedure TSpriteRenderer.DrawCell(ATexture: PSdlTexture;
  AGridX, AGridY: Integer);
begin
  Draw(ATexture, AGridX * SpriteSize, AGridY * SpriteSize);
end;

procedure TSpriteRenderer.DrawTile(ATexture: PSdlTexture;
  AGridX, AGridY: Integer);
var
  Src, Dest: TSdlRect;
  NativeW, NativeH: Integer;
begin
  // QueryTexture per call is fine at the background-build cadence this
  // runs at (once per screen). If a caller ever draws tiles per FRAME,
  // hoist the crop out of the loop first.
  SDL_QueryTexture(ATexture, nil, nil, @NativeW, @NativeH);

  // Source crop is in TEXTURE PIXELS: the 2008 loader read exactly the
  // top-left 64x64 of any bitmap, whatever its size on disk.
  Src.X := 0;
  Src.Y := 0;
  Src.W := Min(NativeW, TileArtSize);
  Src.H := Min(NativeH, TileArtSize);

  Dest.X := AGridX * TileSize;
  Dest.Y := AGridY * TileSize;
  // Destination is ONE CELL in game units; the 64px art downsamples into
  // it and scales back up with the window (net 1:1 at 1024x768).
  Dest.W := TileSize;
  Dest.H := TileSize;

  SDL_RenderCopy(FRenderer, ATexture, @Src, @Dest);
end;

procedure TSpriteRenderer.Draw(ATexture: PSdlTexture; AX, AY: Integer;
  AMirrored: Boolean);
var
  Dest: TSdlRect;
begin
  Dest.X := AX;
  Dest.Y := AY;
  Dest.W := SpriteSize;
  Dest.H := SpriteSize;

  SDL_RenderCopyEx(FRenderer, ATexture, nil, @Dest, 0.0, nil,
    FlipOf(AMirrored));
end;

procedure TSpriteRenderer.DrawRect(ATexture: PSdlTexture;
  const ADest: TSdlRect);
begin
  SDL_RenderCopy(FRenderer, ATexture, nil, @ADest);
end;

procedure TSpriteRenderer.DrawRotated(ATexture: PSdlTexture;
  ACenterX, ACenterY: Integer; AAngleDegrees: Double; AMirrored: Boolean);
var
  Dest: TSdlRect;
begin
  Dest.X := ACenterX - SpriteSize div 2;
  Dest.Y := ACenterY - SpriteSize div 2;
  Dest.W := SpriteSize;
  Dest.H := SpriteSize;

  // Center = nil rotates around Dest's middle - exactly what bullets need.
  SDL_RenderCopyEx(FRenderer, ATexture, nil, @Dest, AAngleDegrees, nil,
    FlipOf(AMirrored));
end;

end.
