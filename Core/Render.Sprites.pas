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

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Sprites;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.Generics.Collections, Sdl2.Core,
  Sprites.Sets;

const
  // Where the .mset containers live, relative to the working dir (bin).
  SpriteSetsDir = 'sprites\';

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

type
  ESpriteError = class(Exception);

  TFrameIndex = 0 .. FramesAlive - 1;

  // Owns every texture it ever loaded; frames shared between monsters
  // (e1.bmp and friends) are loaded exactly once.
  TSpriteCache = class
  private
    FRenderer: PSdlRenderer;
    FSpriteSets: TList<TSpriteSet>; // attached, not owned
    FTextures: TDictionary<string, PSdlTexture>;
    FUseColorKey: Boolean;
    FKeyR, FKeyG, FKeyB: UInt8;
    FLinearFilter: Boolean;
    function FindSet(const AName: string): TSpriteSet;
    function NamedSet(const AId: string): TSpriteSet;
    function LoadTexture(const ASurface: PSdlSurface;
      const AName: string): PSdlTexture;
  public
    constructor Create(const ARenderer: PSdlRenderer);
    destructor Destroy; override;

    // Adds a sprite set as a source, in declaration order: the first
    // attached set containing a name wins, and a name no set knows
    // still falls back to the folder. Sets are not owned - whoever
    // opened them frees them, after every cache using them is gone.
    procedure AttachSpriteSet(const ASpriteSet: TSpriteSet);

    // Of the names given, the ones asked for WITHOUT a qualifier that
    // more than one attached set carries - reported as
    // 'name: winner, loser'. Those resolve silently by declaration
    // order, so reordering the declaration would change the picture
    // without changing the palette. Two sets merely sharing a name is
    // not a problem; asking bare is, and qualifying the name fixes it.
    function AmbiguousNames(const AWanted: TArray<string>): TArray<string>;

    // The attached set a sprite name resolves to, and the name as that
    // set knows it - the same rules as Get: path and extension dropped,
    // 'set:name' asks one set, a bare name the first set carrying it.
    // Raises when no set does.
    function SourceOf(const AName: string; out ABare: string): TSpriteSet;
    // Returns a cached texture, loading the image on first request.
    // Callers may keep passing 'level1\doom1.png': for the set lookup
    // the path and extension are dropped, because sets name sprites,
    // not files. Only the folder fallback reads the name as a path.
    function Get(const AFileName: string): PSdlTexture;
    // Color key applies to textures loaded AFTER the call; set it up first.
    procedure SetColorKey(AR, AG, AB: UInt8);
    procedure DisableColorKey;
    // For art denser than the logical screen (HD backdrops): the global
    // filter is nearest, and nearest downscaling turns detail into grain.
    // Applies to textures loaded after the call, like the color key.
    procedure EnableLinearFilter;
    function Count: Integer;
  end;

  // One monster's animation set: the 16 frames of an .mns file.
  TAnimSet = record
    Alive: array [TFrameIndex] of PSdlTexture;
    Death: array [TFrameIndex] of PSdlTexture;
    function IsLoaded: Boolean;
  end;

// Free function: parsing a text file into a record needs no object state.
// Decodes one sprite out of a set. The single place in the engine that
// turns stored bytes into a surface - the cache, the menu and the font
// atlas ask here rather than each opening its own reader. Returns nil
// on failure; the caller words the error, since only it knows what the
// picture was for.
function LoadImageSurface(const ASpriteSet: TSpriteSet;
  const AName: string): PSdlSurface;

// The 'alive' and 'death' sequences must both be exactly eight frames:
// TAnimSet is the 2008 contract and it is fixed-size. The cache must
// have the same set attached - names resolve through it.
function LoadAnimSet(const ACache: TSpriteCache;
  const ASpriteSet: TSpriteSet): TAnimSet;

// Multiplies the texture's colors per channel, in percent (100 = as
// painted). The texture keeps it until the next call, so pictures shared
// under different tints set it before every draw.
procedure TintTexture(ATexture: PSdlTexture; ARed, AGreen, ABlue: Byte);
// One channel of a tint as the color mod SDL takes, for a caller that
// passes the color on instead of setting it on a texture
function PercentToColorMod(APercent: Byte): UInt8;

type
  TSpriteRenderer = class
  private
    FRenderer: PSdlRenderer;
    FOrigin: TSdlPoint;
  public
    constructor Create(const ARenderer: PSdlRenderer;
      ALogicalWidth, ALogicalHeight: Integer);

    // Every draw below lands shifted by Origin - the screen-shake hook.
    // Layers that must stay put (backdrop, cursor, HUD) draw with it at
    // zero; the caller sets it per layer, nothing here resets it.
    property Origin: TSdlPoint read FOrigin write FOrigin;

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
    // A square ASide units across centered on the point, turned
    // AAngleDegrees clockwise, at ALevel opacity (0..1). Float all the
    // way: a logical unit is several screen pixels, and a mover drawn
    // between ticks must not snap to them.
    procedure DrawTurned(ATexture: PSdlTexture; const ACenter: TSdlFPoint;
      ASide: Single; AAngleDegrees: Double; ALevel: Single = 1);
  end;

implementation

uses
  System.Math, Sdl2.Image;

resourcestring
  SBmpLoadFailed = 'Cannot load sprite "%s": %s';
  STextureCreateFailed = 'Cannot create texture for "%s": %s';
  SNoSuchSet = 'No sprite set "%s" is attached (asked for "%s")';
  SNoSuchSprite = 'Sprite "%s" is not in set "%s"';
  SNotInAnySet = 'No attached sprite set has "%s"';
  SSequenceLength =
    'Sequence "%s" of set "%s" must be %d frames, got %d';

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

constructor TSpriteCache.Create(const ARenderer: PSdlRenderer);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSpriteSets := TList<TSpriteSet>.Create;
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
  FSpriteSets.Free; // the list, not the sets - they have owners
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

procedure TSpriteCache.EnableLinearFilter;
begin
  FLinearFilter := True;
end;

function TSpriteCache.Count: Integer;
begin
  Result := FTextures.Count;
end;

function LoadImageSurface(const ASpriteSet: TSpriteSet;
  const AName: string): PSdlSurface;
begin
  if ASpriteSet = nil then
    Exit(nil);

  var Bare := ChangeFileExt(ExtractFileName(AName), '');
  if not ASpriteSet.Contains(Bare) then
    Exit(nil);

  var Blob := ASpriteSet.ReadSprite(Bare);
  Result := IMG_Load_RW(SDL_RWFromMem(@Blob[0], Length(Blob)), 1);
end;

function TSpriteCache.FindSet(const AName: string): TSpriteSet;
begin
  for var Attached in FSpriteSets do
    if Attached.Contains(AName) then
      Exit(Attached);
  Result := nil;
end;

function TSpriteCache.NamedSet(const AId: string): TSpriteSet;
begin
  for var Attached in FSpriteSets do
    if SameText(Attached.Id, AId) then
      Exit(Attached);
  Result := nil;
end;

function TSpriteCache.SourceOf(const AName: string;
  out ABare: string): TSpriteSet;
begin
  // 'common:pustota' - say which set and declaration order stops
  // mattering. Written where two declared sets share a sprite name.
  // Split before the path goes: on Windows ExtractFileName cuts at ':'
  // too, as at a drive letter, and would drop the set.
  var Split := Pos(SetQualifier, AName);
  var SetId := Copy(AName, 1, Split - 1);
  // Sets name sprites, not files, and the 2008 spellings survive in
  // level palettes: 'level1\doom1.png' and 'doom1' are one sprite.
  ABare := ChangeFileExt(ExtractFileName(Copy(AName, Split + 1,
    Length(AName))), '');
  if Split = 0 then
  begin
    Result := FindSet(ABare);
    if Result = nil then
      raise ESpriteError.CreateFmt(SNotInAnySet, [ABare]);
    Exit;
  end;

  Result := NamedSet(SetId);
  if Result = nil then
    raise ESpriteError.CreateFmt(SNoSuchSet, [SetId, AName]);
  if not Result.Contains(ABare) then
    raise ESpriteError.CreateFmt(SNoSuchSprite, [ABare, SetId]);
end;

function TSpriteCache.Get(const AFileName: string): PSdlTexture;
var
  Bare: string;
begin
  var Source := SourceOf(AFileName, Bare);

  // The key carries the set: 'common:pustota' and
  // 'mine-interior:pustota' are two pictures and two slots.
  var Key := LowerCase(Source.Id + SetQualifier + Bare);
  if FTextures.TryGetValue(Key, Result) then
    Exit;

  var Surface := LoadImageSurface(Source, Bare);
  if Surface = nil then
    raise ESpriteError.CreateFmt(SBmpLoadFailed, [AFileName, SdlErrorText]);

  Result := LoadTexture(Surface, AFileName);
  FTextures.Add(Key, Result);
end;

function TSpriteCache.AmbiguousNames(
  const AWanted: TArray<string>): TArray<string>;
begin
  Result := [];
  for var Wanted in AWanted do
  begin
    if Pos(SetQualifier, Wanted) > 0 then
      Continue;

    var Bare := ChangeFileExt(ExtractFileName(Wanted), '');
    var Holders: TArray<string> := [];
    for var Attached in FSpriteSets do
      if Attached.Contains(Bare) then
        Holders := Holders + [Attached.Id];

    if Length(Holders) > 1 then
      Result := Result + [Format('%s: %s',
        [Bare, string.Join(', ', Holders)])];
  end;
end;

procedure TSpriteCache.AttachSpriteSet(const ASpriteSet: TSpriteSet);
begin
  FSpriteSets.Add(ASpriteSet);
end;

// The sources differ only in where the bytes came from; the color key
// and texture creation are one pipeline, and it starts here.
function TSpriteCache.LoadTexture(const ASurface: PSdlSurface;
  const AName: string): PSdlTexture;
var
  Surface: PSdlSurface;
begin
  Surface := ASurface;
  try
    if FUseColorKey then
      SDL_SetColorKey(Surface, 1,
        SDL_MapRGB(Surface.Format, FKeyR, FKeyG, FKeyB));

    Result := SDL_CreateTextureFromSurface(FRenderer, Surface);
    if Result = nil then
      raise ESpriteError.CreateFmt(STextureCreateFailed,
        [AName, SdlErrorText]);
    if FLinearFilter then
      SDL_SetTextureScaleMode(Result, SdlScaleModeLinear);
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
  const ASpriteSet: TSpriteSet): TAnimSet;

  function FramesOf(const ASequence: string): TArray<string>;
  begin
    Result := ASpriteSet.SequenceFrames(ASequence);
    if Length(Result) <> FramesAlive then
      raise ESpriteError.CreateFmt(SSequenceLength,
        [ASequence, ASpriteSet.Id, FramesAlive, Length(Result)]);
  end;

begin
  Result := Default(TAnimSet);
  var Alive := FramesOf('alive');
  var Death := FramesOf('death');
  for var i := Low(TFrameIndex) to High(TFrameIndex) do
  begin
    Result.Alive[i] := ACache.Get(Alive[i]);
    Result.Death[i] := ACache.Get(Death[i]);
  end;
end;

function PercentToColorMod(APercent: Byte): UInt8;
begin
  Result := Round(APercent * 255 / 100);
end;

procedure TintTexture(ATexture: PSdlTexture; ARed, AGreen, ABlue: Byte);
begin
  SDL_SetTextureColorMod(ATexture, PercentToColorMod(ARed),
    PercentToColorMod(AGreen), PercentToColorMod(ABlue));
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

  Dest.X := AGridX * TileSize + FOrigin.X;
  Dest.Y := AGridY * TileSize + FOrigin.Y;
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
  Dest.X := AX + FOrigin.X;
  Dest.Y := AY + FOrigin.Y;
  Dest.W := SpriteSize;
  Dest.H := SpriteSize;

  SDL_RenderCopyEx(FRenderer, ATexture, nil, @Dest, 0.0, nil,
    FlipOf(AMirrored));
end;

procedure TSpriteRenderer.DrawRect(ATexture: PSdlTexture;
  const ADest: TSdlRect);
begin
  var Dest := ADest;
  Dest.X := Dest.X + FOrigin.X;
  Dest.Y := Dest.Y + FOrigin.Y;
  SDL_RenderCopy(FRenderer, ATexture, nil, @Dest);
end;

procedure TSpriteRenderer.DrawRotated(ATexture: PSdlTexture;
  ACenterX, ACenterY: Integer; AAngleDegrees: Double; AMirrored: Boolean);
var
  Dest: TSdlRect;
begin
  Dest.X := ACenterX - SpriteSize div 2 + FOrigin.X;
  Dest.Y := ACenterY - SpriteSize div 2 + FOrigin.Y;
  Dest.W := SpriteSize;
  Dest.H := SpriteSize;

  // Center = nil rotates around Dest's middle - exactly what bullets need.
  SDL_RenderCopyEx(FRenderer, ATexture, nil, @Dest, AAngleDegrees, nil,
    FlipOf(AMirrored));
end;

procedure TSpriteRenderer.DrawTurned(ATexture: PSdlTexture;
  const ACenter: TSdlFPoint; ASide: Single; AAngleDegrees: Double;
  ALevel: Single);
var
  Dest: TSdlFRect;
begin
  Dest.X := ACenter.X - ASide / 2 + FOrigin.X;
  Dest.Y := ACenter.Y - ASide / 2 + FOrigin.Y;
  Dest.W := ASide;
  Dest.H := ASide;
  SDL_SetTextureAlphaMod(ATexture, EnsureRange(Round(255 * ALevel), 0, 255));
  SDL_RenderCopyExF(FRenderer, ATexture, nil, @Dest, AAngleDegrees, nil,
    SdlFlipNone);
end;

end.
