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

  The frame may be lowered before it turns - the pitch of the titles'
  flight, the nose up taking the picture down: the copy is turned about
  the point of the frame that comes to the window's middle, and the frame's
  place on the window is cleared to the background first, for the top it
  bares.

  A card with no texture large enough for the banked frame gets one for
  the frame as it is, and the frame goes through it level: the layers
  still move, the bank is not played.

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
  // How a frame comes to the window: Width by Height units, grown Cover
  // times, lowered Drop units and banked BankDegrees about its middle
  TFrameTurn = record
    Width, Height: Integer;
    BankDegrees, Drop, Cover: Single;
    // Where a point of the frame, units, lands on the window
    function PointAt(AX, AY: Single): TSdlFPoint;
  end;

  TFrameTarget = class
  private
    FRenderer: PSdlRenderer;
    FUnits: TSdlPoint;
    FMaxCover: Single;
    // The card refused the banked frame's size: every bank is played level
    FLevelOnly: Boolean;
    FTexture: PSdlTexture;
    FTextureSize: TSdlPoint;
    FRebuilt: Boolean;
    FBankDegrees: Single;
    FDrop: Single;
    FBackground: TSdlColor;
    FCover: Single;
    FWindowScale: Single;
    FScale: Single;
    FPlace: TSdlRect;
    function SizeAt(AWindowScale: Single): TSdlPoint;
    procedure Rebuild(const ASize: TSdlPoint);
    procedure PlaceLayers(AShiftX, AShiftY: Integer);
    procedure ClearFramePlace;
  public
    // AFrameWidth by AFrameHeight - the frame in units, the renderer's
    // logical size. The texture has room for a bank of AMaxBankDegrees
    // either way; a steeper one bares the window's corners
    constructor Create(ARenderer: PSdlRenderer; AFrameWidth,
      AFrameHeight: Integer; AMaxBankDegrees: Single);
    destructor Destroy; override;
    // From here to Close the drawing lands in the texture, in the frame's
    // units as on the window; on the window it is lowered ADrop units and
    // banked. Called with the window on the receiving end. False - there
    // is no texture, not even for the frame unbanked: nothing is changed,
    // and the frame is the caller's to draw straight
    function Open(ABankDegrees, ADrop: Single; const ABackground: TSdlColor): Boolean;
    // What is drawn next lands so far, in units, from the frame's place -
    // rounded to whole pixels - and is cut at the frame's edge moved with
    // it. 0, 0 is the frame's place again
    procedure ShiftLayers(AUnitsX, AUnitsY: Single);
    // The window is on the receiving end again, as it was, and the frame
    // is on it, lowered and banked
    procedure Close;
    // Where a point of the frame, units, stands on the window after the
    // last Close
    function ScreenPoint(AX, AY: Single): TSdlFPoint;
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

function TFrameTarget.Open(ABankDegrees, ADrop: Single;
  const ABackground: TSdlColor): Boolean;
var
  ScaleX, ScaleY: Single;
begin
  FRebuilt := False;
  SDL_RenderGetScale(FRenderer, @ScaleX, @ScaleY);
  var Size := SizeAt(ScaleX);
  if (Size.X <> FTextureSize.X) or (Size.Y <> FTextureSize.Y) then
    Rebuild(Size);
  // Not asked for again at a smaller window: the bank would come and go
  // with the window's size
  if (FTexture = nil) and not FLevelOnly then
  begin
    FLevelOnly := True;
    FMaxCover := 1;
    Rebuild(SizeAt(ScaleX));
  end;
  if FTexture = nil then
    Exit(False);
  // The window's viewport, scale and logical size are kept by SDL till
  // the target is the window again
  if SDL_SetRenderTarget(FRenderer, FTexture) <> 0 then
    Exit(False);

  FWindowScale := ScaleX;
  FBankDegrees := ABankDegrees;
  FDrop := ADrop;
  FBackground := ABackground;
  if FLevelOnly then
    FBankDegrees := 0;
  FCover := BankCover(FBankDegrees, FUnits.X, FUnits.Y);
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
  ClearFramePlace;

  // The point of the frame ADrop over its middle goes to the frame's
  // middle on the window, and the texture turns about it
  var PivotX: Double := FPlace.X + FUnits.X * FScale / 2;
  var PivotY: Double := FPlace.Y + (FUnits.Y / 2 - FDrop) * FScale;
  Pivot.X := PivotX;
  Pivot.Y := PivotY;
  Place.X := FUnits.X * FWindowScale / 2 - PivotX;
  Place.Y := FUnits.Y * FWindowScale / 2 - PivotY;
  Place.W := FTextureSize.X;
  Place.H := FTextureSize.Y;

  // Unbanked and not lowered every texel lies on its pixel: taken as it
  // is, the picture is the one drawn straight to the window
  if (FBankDegrees = 0) and (FDrop = 0) then
    SDL_SetTextureScaleMode(FTexture, SdlScaleModeNearest)
  else
    SDL_SetTextureScaleMode(FTexture, SdlScaleModeLinear);

  // In pixels: a texel to a pixel
  SDL_RenderSetScale(FRenderer, 1, 1);
  SDL_RenderCopyExF(FRenderer, FTexture, nil, @Place, FBankDegrees, @Pivot,
    SdlFlipNone);
  SDL_RenderSetScale(FRenderer, FWindowScale, FWindowScale);
end;

// What a lowered frame bares on the window is the background, as the
// texture's own margin is
procedure TFrameTarget.ClearFramePlace;
var
  Place: TSdlFRect;
begin
  Place.X := 0;
  Place.Y := 0;
  Place.W := FUnits.X;
  Place.H := FUnits.Y;
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeNone);
  SDL_SetRenderDrawColor(FRenderer, FBackground.R, FBackground.G, FBackground.B,
    FBackground.A);
  SDL_RenderFillRectF(FRenderer, @Place);
end;

function TFrameTarget.ScreenPoint(AX, AY: Single): TSdlFPoint;
var
  Turn: TFrameTurn;
begin
  Turn.Width := FUnits.X;
  Turn.Height := FUnits.Y;
  Turn.BankDegrees := FBankDegrees;
  Turn.Drop := FDrop;
  Turn.Cover := FCover;
  Result := Turn.PointAt(AX, AY);
end;

// SDL turns a copy clockwise on the window, as a canvas turns its picture
function TFrameTurn.PointAt(AX, AY: Single): TSdlFPoint;
begin
  var Turn: Double := BankDegrees * Pi / 180;
  var MiddleX: Double := Width / 2;
  var MiddleY: Double := Height / 2;
  var AcrossX: Double := (AX - MiddleX) * Cover;
  var AcrossY: Double := (AY + Drop - MiddleY) * Cover;
  Result.X := MiddleX + AcrossX * Cos(Turn) - AcrossY * Sin(Turn);
  Result.Y := MiddleY + AcrossX * Sin(Turn) + AcrossY * Cos(Turn);
end;

end.
