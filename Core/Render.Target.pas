{
  Render.Target - a frame drawn into a texture and put on the window
  turned: the bank of the titles' flight.

  A banked frame is grown till it still covers the window's corners, and
  the growth is drawn, not stretched: the frame goes into the texture at
  the window's scale times the growth and comes to the window a texel to
  a pixel, turned about its middle. Unbanked it is the picture a frame
  drawn straight to the window is, to the pixel.

  A layer of the frame may be drawn moved by whole pixels, where an
  origin in units moves it a unit at a step.

  Deliberately not here: what is drawn, and the HUD - that goes to the
  window after Close and stands level whatever the bank.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Target;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

type
  TFrameTarget = class
  private
    FRenderer: PSdlRenderer;
    FUnits: TSdlPoint;
    FMaxCover: Single;
    FTexture: PSdlTexture;
    FTextureSize: TSdlPoint;
    FRebuilt: Boolean;
    FBankDegrees: Single;
    FCover: Single;
    FWindowScale: Single;
    FScale: Single;
    FPlace: TSdlRect;
    function SizeAt(AWindowScale: Single): TSdlPoint;
    procedure Rebuild(const ASize: TSdlPoint);
    procedure PlaceLayers(AShiftX, AShiftY: Integer);
  public
    // AFrameWidth by AFrameHeight - the frame in units, the renderer's
    // logical size. The texture has room for a bank of AMaxBankDegrees
    // either way; a steeper one bares the window's corners
    constructor Create(ARenderer: PSdlRenderer; AFrameWidth,
      AFrameHeight: Integer; AMaxBankDegrees: Single);
    destructor Destroy; override;
    // From here to Close the drawing lands in the texture, in the frame's
    // units as on the window. Called with the window on the receiving
    // end. False - there is no texture (too large for the card): nothing
    // is changed, and the frame is the caller's to draw straight
    function Open(ABankDegrees: Single; const ABackground: TSdlColor): Boolean;
    // What is drawn next lands so far, in units, from the frame's place -
    // rounded to whole pixels - and is cut at the frame's edge moved with
    // it. 0, 0 is the frame's place again
    procedure ShiftLayers(AUnitsX, AUnitsY: Single);
    // The window is on the receiving end again, as it was, and the frame
    // is on it, banked
    procedure Close;
    // The last Open made the texture anew: the window's size has changed
    property Rebuilt: Boolean read FRebuilt;
    property TextureSize: TSdlPoint read FTextureSize;
    // How many times the last Open grew the frame
    property Cover: Single read FCover;
  end;

// How many times a frame banked by ABankDegrees is grown to cover its own
// unbanked place still: 1 for none, 1.293 for 14 degrees of a 4:3 frame
function BankCover(ABankDegrees: Single; AFrameWidth,
  AFrameHeight: Integer): Single;

implementation

uses
  System.Math;

const
  // A turned copy's filter reads a texel past the frame's edge
  MarginPixels = 2;

function BankCover(ABankDegrees: Single; AFrameWidth,
  AFrameHeight: Integer): Single;
begin
  var Turn: Double := Abs(ABankDegrees) * Pi / 180;
  var LongerSide: Double := AFrameWidth / AFrameHeight;
  if LongerSide < 1 then
    LongerSide := 1 / LongerSide;
  Result := Cos(Turn) + LongerSide * Sin(Turn);
end;

constructor TFrameTarget.Create(ARenderer: PSdlRenderer; AFrameWidth,
  AFrameHeight: Integer; AMaxBankDegrees: Single);
begin
  inherited Create;
  FRenderer := ARenderer;
  FUnits.X := AFrameWidth;
  FUnits.Y := AFrameHeight;
  FMaxCover := BankCover(AMaxBankDegrees, AFrameWidth, AFrameHeight);
  FCover := 1;
end;

destructor TFrameTarget.Destroy;
begin
  if FTexture <> nil then
    SDL_DestroyTexture(FTexture);
  inherited;
end;

// The frame at its largest growth, and the margin round it
function TFrameTarget.SizeAt(AWindowScale: Single): TSdlPoint;
begin
  var Width: Double := FUnits.X * AWindowScale * FMaxCover;
  var Height: Double := FUnits.Y * AWindowScale * FMaxCover;
  Result.X := Ceil(Width) + 2 * MarginPixels;
  Result.Y := Ceil(Height) + 2 * MarginPixels;
end;

// A size the card refuses is kept as asked for, with no texture: it is
// not asked for again every frame
procedure TFrameTarget.Rebuild(const ASize: TSdlPoint);
begin
  if FTexture <> nil then
    SDL_DestroyTexture(FTexture);
  FTextureSize := ASize;
  FRebuilt := True;

  FTexture := SDL_CreateTexture(FRenderer, SdlPixelFormatArgb8888,
    SdlTextureAccessTarget, ASize.X, ASize.Y);
  if FTexture = nil then
    Exit;
  // The frame is opaque: its copy takes the window's pixels over
  SDL_SetTextureBlendMode(FTexture, SdlBlendModeNone);
end;

// A viewport is told in the units of the scale: in pixels only at 1
procedure TFrameTarget.PlaceLayers(AShiftX, AShiftY: Integer);
var
  Place: TSdlRect;
begin
  Place := FPlace;
  Place.X := FPlace.X + AShiftX;
  Place.Y := FPlace.Y + AShiftY;
  SDL_RenderSetScale(FRenderer, 1, 1);
  SDL_RenderSetViewport(FRenderer, @Place);
  SDL_RenderSetScale(FRenderer, FScale, FScale);
end;

function TFrameTarget.Open(ABankDegrees: Single;
  const ABackground: TSdlColor): Boolean;
var
  ScaleX, ScaleY: Single;
begin
  FRebuilt := False;
  SDL_RenderGetScale(FRenderer, @ScaleX, @ScaleY);
  var Size := SizeAt(ScaleX);
  if (Size.X <> FTextureSize.X) or (Size.Y <> FTextureSize.Y) then
    Rebuild(Size);
  if FTexture = nil then
    Exit(False);
  // The window's viewport, scale and logical size are kept by SDL till
  // the target is the window again
  if SDL_SetRenderTarget(FRenderer, FTexture) <> 0 then
    Exit(False);

  FWindowScale := ScaleX;
  FBankDegrees := ABankDegrees;
  FCover := BankCover(ABankDegrees, FUnits.X, FUnits.Y);
  if FCover > FMaxCover then
    FCover := FMaxCover;
  FScale := FWindowScale * FCover;

  var Width: Double := FUnits.X * FScale;
  var Height: Double := FUnits.Y * FScale;
  FPlace.X := MarginPixels;
  FPlace.Y := MarginPixels;
  FPlace.W := Ceil(Width);
  FPlace.H := Ceil(Height);

  // All of the texture: what the turned copy's filter reads past the
  // frame is the background
  SDL_SetRenderDrawColor(FRenderer, ABackground.R, ABackground.G, ABackground.B,
    ABackground.A);
  SDL_RenderClear(FRenderer);
  PlaceLayers(0, 0);
  Result := True;
end;

procedure TFrameTarget.ShiftLayers(AUnitsX, AUnitsY: Single);
begin
  PlaceLayers(Round(AUnitsX * FScale), Round(AUnitsY * FScale));
end;

procedure TFrameTarget.Close;
var
  Place: TSdlFRect;
  Pivot: TSdlFPoint;
begin
  SDL_SetRenderTarget(FRenderer, nil);

  // The frame's middle in the texture goes to the frame's middle on the
  // window, and the texture turns about it
  var PivotX: Double := FPlace.X + FUnits.X * FScale / 2;
  var PivotY: Double := FPlace.Y + FUnits.Y * FScale / 2;
  Pivot.X := PivotX;
  Pivot.Y := PivotY;
  Place.X := FUnits.X * FWindowScale / 2 - PivotX;
  Place.Y := FUnits.Y * FWindowScale / 2 - PivotY;
  Place.W := FTextureSize.X;
  Place.H := FTextureSize.Y;

  // Unbanked every texel lies on its pixel: taken as it is, the picture
  // is the one drawn straight to the window
  if FBankDegrees = 0 then
    SDL_SetTextureScaleMode(FTexture, SdlScaleModeNearest)
  else
    SDL_SetTextureScaleMode(FTexture, SdlScaleModeLinear);

  // In pixels: a texel to a pixel
  SDL_RenderSetScale(FRenderer, 1, 1);
  SDL_RenderCopyExF(FRenderer, FTexture, nil, @Place, FBankDegrees, @Pivot,
    SdlFlipNone);
  SDL_RenderSetScale(FRenderer, FWindowScale, FWindowScale);
end;

end.
