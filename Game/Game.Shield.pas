{
  Game.Shield - the shield of a TeK machine while it cannot be hit: a pale
  gold honeycomb about the machine, always seen, on its rim alone: the
  machine inside stays in plain view. A hit lights the cells about its point, and the
  flare dies out in about half a second. No sparks: sparks are the game's
  sign of a wound, and a shield takes none.

  A shield that falls blinks its cells a few times and goes out; it does
  not come back by itself. The rules and the look of one shield; the
  machine says where its middle is.

  A shield is an ellipse about a small machine (the cannons), or it lies
  over the body of a big one (the Ram) a little past its outline: the rim
  is then the outline itself, and an ellipse round a long low hull would
  hang its cells in the air over the hull and leave its corners bare. A
  body that stands on the floor shows no rim along the floor.

  Or it is a strip: a short row of small cells, every one of them rim -
  a plate that guards one side of a gun (the Ram's sweeper from below).

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Shield;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Levels.Dynamics;

type
  // One cell of the honeycomb, in additive light: one texture for every
  // shield of the game
  TShieldArt = class
  private
    FRenderer: PSdlRenderer;
    FCell: PSdlTexture;
  public
    constructor Create(ARenderer: PSdlRenderer);
    destructor Destroy; override;
  end;

  TShieldState = (sdUp, sdFalling, sdDown);

  // The body of a machine on a grid of units, row by row from its top-left
  // corner, and where its middle is on that grid
  TShieldMask = record
    Width, Height: Integer;
    Solid: TArray<Boolean>; // Width * Height
    Middle: TSdlFPoint;
    // False off the grid
    function At(ACol, ARow: Integer): Boolean;
  end;

  TTekShield = class
  private type
    // From the middle of the machine, screen units
    TCell = record
      X, Y: Single;
      Rim: Single; // 0 in the middle .. 1 at the edge
    end;

    TFlare = record
      X, Y: Single;
      Age: Integer;
    end;
  private
    FRadiusX, FRadiusY: Single;
    // Over a body: the body a margin wider, its corner from the middle
    FOverBody: Boolean;
    FField: TShieldMask;
    FFieldX, FFieldY: Single;
    // A strip: a row of cells along X, its half-length and half-height in
    // FRadiusX, FRadiusY; the cells this much of their full size
    FStrip: Boolean;
    FScale: Single;
    FCells: TArray<TCell>;
    FFlares: TList<TFlare>;
    FState: TShieldState;
    FFallAge: Integer;
    procedure LayCells;
    procedure LayCellsOverBody;
    procedure LayStrip(ACells: Integer);
    function FlareShare(const ACell: TCell; AAlpha: Single): Single;
    function FallLevel(AAlpha: Single): Single;
  public
    // An ellipse of these half-axes about the middle of the machine
    constructor Create(ARadiusX, ARadiusY: Single);
    // Over the body, a margin past its outline; the middle of the machine
    // is the body's
    constructor CreateOver(const ABody: TShieldMask);
    // ACells in a row about the middle, at AScale of the full cell
    constructor CreateStrip(ACells: Integer; AScale: Single);
    destructor Destroy; override;
    // Up again, with no flare on it
    procedure Rise;
    procedure Fall;
    // A bullet, a round met the shield at this point from the middle
    procedure Strike(const APoint: TSdlFPoint);
    // The point, from the middle, is inside
    function Holds(const APoint: TSdlFPoint): Boolean;
    // Where a stretch from AFrom to ATo, both from the middle, first comes
    // into the shield; False if it stays outside or the shield is not up
    function TryEntry(const AFrom, ATo: TSdlFPoint;
      out AEntry: TSdlFPoint): Boolean;
    procedure Tick;
    // ACenter - the middle of the machine on the screen, shake included
    procedure Draw(const ACanvas: TDynamicCanvas; AArt: TShieldArt;
      const ACenter: TSdlFPoint; AAlpha: Single);
    property State: TShieldState read FState;
  end;

implementation

uses
  System.Types, System.Math, Render.Brush, Render.Glow;

const
  // From the middle of a cell to a corner; the cells are pointy-topped
  HexSize = 3.4;
  CellSide = 48;
  // The texture holds the hexagon and a little of its glow past the corners
  CellSpan = 1.15;
  EdgeWidth = 0.14;
  FillLevel = 0.06;
  RestLevel = 0.2;
  // The honeycomb lies on the rim alone: the machine inside stays in plain
  // view. Rim shares of the ellipse where the cells come in, and where a
  // flare still reaches - a hit lands on the rim, its light spills a
  // little inward
  RestRimFrom = 0.72;
  FlareRimFrom = 0.5;
  RimFull = 0.95;
  // A cell this faint is not drawn
  DimmestLevel = 0.01;
  FlareReach = 9.0;
  FlareTicks = 16;
  FlareLevel = 0.85;
  FallTicks = 14;
  FallBlinkTicks = 2;
  ShieldColor: TRgb = (R: 255; G: 214; B: 128);
  FlareColor: TRgb = (R: 255; G: 244; B: 206);
  // Along a stretch the shield is looked for this often
  EntryStep = 1.0;
  // Over a body: units the shield stands past its outline, and the depth
  // under the outline that counts as the whole of the rim - about what
  // the rim of a cannon's ellipse is across, so the two look alike
  BodyMargin = 2;
  RimDepth = 28.0;

// 1 on the edge of a pointy-topped hexagon whose corners are a unit out
function HexNorm(AX, AY: Single): Single;
begin
  var AcrossX := Abs(AX);
  Result := Max(AcrossX * 2 / Sqrt(3), AcrossX / Sqrt(3) + Abs(AY));
end;

procedure FillCell(ASurface: PSdlSurface);
type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888
begin
  var Half := ASurface.W / 2;
  SDL_LockSurface(ASurface);
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    for var Col := 0 to ASurface.W - 1 do
    begin
      var Norm := HexNorm((Col + 0.5 - Half) / Half * CellSpan,
        (Row + 0.5 - Half) / Half * CellSpan);
      var Level := Exp(-Sqr((1 - Norm) / EdgeWidth));
      if Norm < 1 then
        Level := Max(Level, FillLevel);
      Pixel[0] := 255;
      Pixel[1] := 255;
      Pixel[2] := 255;
      Pixel[3] := Round(255 * EnsureRange(Level, 0.0, 1.0));
      Inc(Pixel);
    end;
  end;
  SDL_UnlockSurface(ASurface);
end;

// 0 up to AFrom, 1 from RimFull on, smooth between
function RimBand(ARim, AFrom: Single): Single;
begin
  var Share := EnsureRange((ARim - AFrom) / (RimFull - AFrom), 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

function MixColor(const AFrom, ATo: TRgb; AShare: Single): TRgb;
begin
  Result.R := Round(AFrom.R + (ATo.R - AFrom.R) * AShare);
  Result.G := Round(AFrom.G + (ATo.G - AFrom.G) * AShare);
  Result.B := Round(AFrom.B + (ATo.B - AFrom.B) * AShare);
end;

// ---------------------------------------------------------------------------
// TShieldMask
// ---------------------------------------------------------------------------

function TShieldMask.At(ACol, ARow: Integer): Boolean;
begin
  if (ACol < 0) or (ARow < 0) or (ACol >= Width) or (ARow >= Height) then
    Exit(False);
  Result := Solid[ARow * Width + ACol];
end;

// The body a margin wider on every side but the floor
function Widen(const ABody: TShieldMask; AMargin: Integer): TShieldMask;
begin
  Result.Width := ABody.Width + 2 * AMargin;
  Result.Height := ABody.Height + AMargin;
  Result.Middle.X := ABody.Middle.X + AMargin;
  Result.Middle.Y := ABody.Middle.Y + AMargin;
  SetLength(Result.Solid, Result.Width * Result.Height);
  for var Row := 0 to Result.Height - 1 do
    for var Col := 0 to Result.Width - 1 do
    begin
      var Near := False;
      for var dy := -AMargin to AMargin do
        for var dx := -AMargin to AMargin do
          if (Sqr(dx) + Sqr(dy) <= Sqr(AMargin)) and
            ABody.At(Col - AMargin + dx, Row - AMargin + dy) then
            Near := True;
      Result.Solid[Row * Result.Width + Col] := Near;
    end;
end;

// How deep under the outline every cell of the field lies, in units:
// a chamfer of two passes. Off the grid is open to the sides and above,
// and solid below - the floor the body stands on is no outline.
function DepthsOf(const AField: TShieldMask): TArray<Single>;
const
  Diagonal = 1.414;
  Deep = 1E6;
var
  Depths: TArray<Single>;

  function DepthAt(ACol, ARow: Integer): Single;
  begin
    if ARow >= AField.Height then
      Exit(Deep);
    if (ACol < 0) or (ARow < 0) or (ACol >= AField.Width) then
      Exit(0);
    Result := Depths[ARow * AField.Width + ACol];
  end;

  procedure Relax(ACol, ARow: Integer; const ASteps: array of TPoint);
  begin
    var Index := ARow * AField.Width + ACol;
    for var Step in ASteps do
    begin
      var Cost: Single := 1;
      if (Step.X <> 0) and (Step.Y <> 0) then
        Cost := Diagonal;
      Depths[Index] := Min(Depths[Index],
        DepthAt(ACol + Step.X, ARow + Step.Y) + Cost);
    end;
  end;

begin
  SetLength(Depths, Length(AField.Solid));
  for var i := 0 to High(Depths) do
    if AField.Solid[i] then
      Depths[i] := Deep
    else
      Depths[i] := 0;
  for var Row := 0 to AField.Height - 1 do
    for var Col := 0 to AField.Width - 1 do
      Relax(Col, Row, [Point(-1, 0), Point(0, -1), Point(-1, -1),
        Point(1, -1)]);
  for var Row := AField.Height - 1 downto 0 do
    for var Col := AField.Width - 1 downto 0 do
      Relax(Col, Row, [Point(1, 0), Point(0, 1), Point(1, 1), Point(-1, 1)]);
  Result := Depths;
end;

// ---------------------------------------------------------------------------
// TShieldArt
// ---------------------------------------------------------------------------

constructor TShieldArt.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FRenderer := ARenderer;
  var Surface := SDL_CreateRGBSurfaceWithFormat(0, CellSide, CellSide, 32,
    SdlPixelFormatAbgr8888);
  if Surface = nil then
    raise EGlowError.Create(SdlErrorText);
  try
    FillCell(Surface);
    FCell := CreateGlowTexture(ARenderer, Surface);
  finally
    SDL_FreeSurface(Surface);
  end;
end;

destructor TShieldArt.Destroy;
begin
  if Assigned(FCell) then
    SDL_DestroyTexture(FCell);
  inherited;
end;

// ---------------------------------------------------------------------------
// TTekShield
// ---------------------------------------------------------------------------

constructor TTekShield.Create(ARadiusX, ARadiusY: Single);
begin
  inherited Create;
  FRadiusX := ARadiusX;
  FRadiusY := ARadiusY;
  FScale := 1;
  FFlares := TList<TFlare>.Create;
  LayCells;
end;

constructor TTekShield.CreateOver(const ABody: TShieldMask);
begin
  inherited Create;
  FOverBody := True;
  FScale := 1;
  FField := Widen(ABody, BodyMargin);
  FFieldX := -FField.Middle.X;
  FFieldY := -FField.Middle.Y;
  FFlares := TList<TFlare>.Create;
  LayCellsOverBody;
end;

constructor TTekShield.CreateStrip(ACells: Integer; AScale: Single);
begin
  inherited Create;
  FStrip := True;
  FScale := AScale;
  FRadiusX := ACells * Sqrt(3) * HexSize * AScale / 2;
  FRadiusY := HexSize * AScale;
  FFlares := TList<TFlare>.Create;
  LayStrip(ACells);
end;

destructor TTekShield.Destroy;
begin
  FFlares.Free;
  inherited;
end;

// Rows a cell and a half apart, every other one shifted by half a cell:
// the cells of a honeycomb, kept where they lie inside the ellipse
procedure TTekShield.LayCells;
begin
  var StepX := Sqrt(3) * HexSize;
  var StepY := 1.5 * HexSize;
  var Rows := Ceil(FRadiusY / StepY);
  var Cols := Ceil(FRadiusX / StepX) + 1;
  FCells := nil;
  for var Row := -Rows to Rows do
    for var Col := -Cols to Cols do
    begin
      var Cell: TCell;
      Cell.X := Col * StepX;
      if Odd(Row) then
        Cell.X := Cell.X + StepX / 2;
      Cell.Y := Row * StepY;
      Cell.Rim := Sqrt(Sqr(Cell.X / FRadiusX) + Sqr(Cell.Y / FRadiusY));
      if Cell.Rim <= 1 then
        FCells := FCells + [Cell];
    end;
end;

// The same honeycomb, kept where it lies over the body; the rim share is
// how close to the outline a cell lies
procedure TTekShield.LayCellsOverBody;
begin
  var Depths := DepthsOf(FField);
  var StepX := Sqrt(3) * HexSize;
  var StepY := 1.5 * HexSize;
  var Rows := Ceil(FField.Height / StepY);
  var Cols := Ceil(FField.Width / StepX) + 1;
  FCells := nil;
  for var Row := 0 to Rows do
    for var Col := 0 to Cols do
    begin
      var AcrossX := Col * StepX;
      if Odd(Row) then
        AcrossX := AcrossX + StepX / 2;
      var DownY := Row * StepY;
      var FieldCol := Trunc(AcrossX);
      var FieldRow := Trunc(DownY);
      if not FField.At(FieldCol, FieldRow) then
        Continue;
      var Cell: TCell;
      Cell.X := AcrossX + FFieldX;
      Cell.Y := DownY + FFieldY;
      var Depth := Depths[FieldRow * FField.Width + FieldCol];
      Cell.Rim := 1 - Min(Depth, RimDepth) / RimDepth;
      FCells := FCells + [Cell];
    end;
end;

// Side by side about the middle; a strip is all rim
procedure TTekShield.LayStrip(ACells: Integer);
begin
  var StepX := Sqrt(3) * HexSize * FScale;
  FCells := nil;
  for var i := 0 to ACells - 1 do
  begin
    var Cell: TCell;
    Cell.X := (i - (ACells - 1) / 2) * StepX;
    Cell.Y := 0;
    Cell.Rim := 1;
    FCells := FCells + [Cell];
  end;
end;

procedure TTekShield.Rise;
begin
  FState := sdUp;
  FFallAge := 0;
  FFlares.Clear;
end;

procedure TTekShield.Fall;
begin
  if FState <> sdUp then
    Exit;
  FState := sdFalling;
  FFallAge := 0;
end;

procedure TTekShield.Strike(const APoint: TSdlFPoint);
begin
  if FState <> sdUp then
    Exit;
  var Flare: TFlare;
  Flare.X := APoint.X;
  Flare.Y := APoint.Y;
  Flare.Age := 0;
  FFlares.Add(Flare);
end;

function TTekShield.Holds(const APoint: TSdlFPoint): Boolean;
begin
  if FOverBody then
    Exit(FField.At(Floor(APoint.X - FFieldX), Floor(APoint.Y - FFieldY)));
  if FStrip then
    Exit((Abs(APoint.X) <= FRadiusX) and (Abs(APoint.Y) <= FRadiusY));
  Result := Sqr(APoint.X / FRadiusX) + Sqr(APoint.Y / FRadiusY) <= 1;
end;

function TTekShield.TryEntry(const AFrom, ATo: TSdlFPoint;
  out AEntry: TSdlFPoint): Boolean;
begin
  AEntry := AFrom;
  if FState <> sdUp then
    Exit(False);
  var Span := Sqrt(Sqr(ATo.X - AFrom.X) + Sqr(ATo.Y - AFrom.Y));
  var Steps := Max(1, Ceil(Span / EntryStep));
  for var i := 0 to Steps do
  begin
    AEntry.X := AFrom.X + (ATo.X - AFrom.X) * i / Steps;
    AEntry.Y := AFrom.Y + (ATo.Y - AFrom.Y) * i / Steps;
    if Holds(AEntry) then
      Exit(True);
  end;
  Result := False;
end;

procedure TTekShield.Tick;
begin
  for var i := FFlares.Count - 1 downto 0 do
  begin
    var Flare := FFlares[i];
    Inc(Flare.Age);
    if Flare.Age >= FlareTicks then
      FFlares.Delete(i)
    else
      FFlares[i] := Flare;
  end;

  if FState <> sdFalling then
    Exit;
  Inc(FFallAge);
  if FFallAge >= FallTicks then
  begin
    FState := sdDown;
    FFlares.Clear;
  end;
end;

// How much of a flare's light the cell takes, 0..1
function TTekShield.FlareShare(const ACell: TCell; AAlpha: Single): Single;
begin
  Result := 0;
  for var Flare in FFlares do
  begin
    var Fade: Single := 1 - (Flare.Age + AAlpha) / FlareTicks;
    if Fade <= 0 then
      Continue;
    var Distance := Sqrt(Sqr(ACell.X - Flare.X) + Sqr(ACell.Y - Flare.Y));
    Result := Result + Fade * Exp(-Sqr(Distance / FlareReach));
  end;
  if Result > 1 then
    Result := 1;
end;

// Up - whole; falling - blinking out; down - nothing
function TTekShield.FallLevel(AAlpha: Single): Single;
begin
  case FState of
    sdUp:
      Result := 1;
    sdFalling:
      begin
        if Odd(FFallAge div FallBlinkTicks) then
          Exit(0);
        Result := 1.6 * (1 - (FFallAge + AAlpha) / FallTicks);
      end;
  else
    Result := 0;
  end;
end;

procedure TTekShield.Draw(const ACanvas: TDynamicCanvas; AArt: TShieldArt;
  const ACenter: TSdlFPoint; AAlpha: Single);
begin
  var Whole := FallLevel(AAlpha);
  if Whole <= 0 then
    Exit;
  var CellSize: Single := 2 * HexSize * CellSpan * FScale;
  for var Cell in FCells do
  begin
    var Flare := FlareShare(Cell, AAlpha) * RimBand(Cell.Rim, FlareRimFrom);
    var Rest := RestLevel * RimBand(Cell.Rim, RestRimFrom);
    var Level := Whole * (Rest + (FlareLevel - Rest) * Flare);
    if Level < DimmestLevel then
      Continue;
    DrawGlow(ACanvas.Renderer, AArt.FCell, ACenter.X + Cell.X,
      ACenter.Y + Cell.Y, CellSize, MixColor(ShieldColor, FlareColor, Flare),
      Min(Level, 1));
  end;
end;

end.
