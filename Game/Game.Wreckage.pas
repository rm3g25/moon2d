{
  Game.Wreckage - what is left of the Ram's hull once it bursts in the air:
  a few big pieces of it - the hull cut in a grid, the magnet, the mortar,
  the engine bays and their nozzles - each flying off from where it was
  on the hull, out from the heart of the burst, up a little, on with a
  share of the hull's way. They fall slowly, as the moon pulls, tumbling
  slowly; the flight's wind takes them back, so they fall behind the
  barges ever faster, up to the world's pace. Each is gone once it is
  under the screen or past its sides.

  The pieces are decoration: neither a floor, nor a body, nor a wound. The
  fire and the smoke that trail each are the caller's; so are the blasts
  of the series (Game.Breakup) and where on the hull each piece was.

  TWreckage is the rules; TWreckagePainter draws them - each piece its
  part of its pictures, one over the other, turned.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Wreckage;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush;

type
  // A piece as it leaves the hull: the part of its pictures it is, drawn
  // one over the other, Width by Height about Middle, turned Spin degrees
  // clockwise, mirrored as the hull was
  TWreckPart = record
    Layers: TArray<PSdlTexture>;
    // In shares of each picture
    Part: TSdlFRect;
    Width, Height: Single;
    Middle: TSdlFPoint;
    Spin: Single;
    Mirrored: Boolean;
  end;

  TWreckPiece = record
    Shape: TWreckPart;
    // Its middle, this tick and the last, screen units
    Middle, LastMiddle: TSdlFPoint;
    Speed: TSdlFPoint;
    // Degrees clockwise, this tick and the last, and how fast it tumbles
    Spin, LastSpin: Single;
    SpinRate: Single;
    Gone: Boolean;
  end;

  TWreckage = class
  private
    FPieces: TArray<TWreckPiece>;
    FDice: TXorShift;
    function GetPiece(AIndex: Integer): TWreckPiece;
    function Roll(ALeast, AMost: Single): Single;
  public
    // ASeed - the dice of the pieces' flight
    constructor Create(ASeed: Cardinal);
    // The hull bursts at AHeart, going AWay a tick: AParts fly, in their
    // order - what flew before is gone
    procedure Shatter(const AParts: TArray<TWreckPart>; const AHeart,
      AWay: TSdlFPoint);
    // AWind - the world's pace past the barges, units a tick to the left
    procedure Tick(AWind: Single);
    // A death, a new level: none in the air
    procedure Clear;
    function Count: Integer;
    // Some are still on the screen
    function Falling: Boolean;
    // AAlpha of the way from the last tick to this one
    function MiddleAt(AIndex: Integer; AAlpha: Single): TSdlFPoint;
    function SpinAt(AIndex: Integer; AAlpha: Single): Single;
    property Pieces[AIndex: Integer]: TWreckPiece read GetPiece; default;
  end;

  TWreckagePainter = class
  private
    FRenderer: PSdlRenderer;
    FWreckage: TWreckage;
  public
    // AWreckage belongs to the caller and must outlive the painter
    constructor Create(ARenderer: PSdlRenderer; AWreckage: TWreckage);
    procedure Draw(AOrigin: TSdlPoint; AAlpha: Single);
  end;

implementation

uses
  System.Math, Game.Space;

const
  // The share of the hull's way a piece keeps; out from the heart and up
  // at these paces, units a tick
  KeptWay = 0.5;
  ScatterLeast = 0.3;
  ScatterMost = 1.0;
  HopLeast = 0.5;
  HopMost = 1.3;
  // Degrees a tick, either way: big and slow
  TumbleLeast = 1.0;
  TumbleMost = 4.0;
  // The moon's pull, a fifth of a barge piece's: about four seconds from
  // the middle of the screen to under it
  WreckGravity = 0.05;
  // The share of the gap to the world's pace it closes a tick
  WindDrag = 0.008;
  // Gone this far under the screen or past its sides
  WreckOffMargin = 64.0;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function OffTheScreen(const AMiddle: TSdlFPoint): Boolean;
begin
  Result := (AMiddle.Y > ScreenHeight + WreckOffMargin) or
    (AMiddle.X < -WreckOffMargin) or (AMiddle.X > ScreenWidth + WreckOffMargin);
end;

// ---------------------------------------------------------------------------
// TWreckage
// ---------------------------------------------------------------------------

constructor TWreckage.Create(ASeed: Cardinal);
begin
  inherited Create;
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;
end;

function TWreckage.Roll(ALeast, AMost: Single): Single;
begin
  Result := ALeast + (AMost - ALeast) * FDice.NextUnit;
end;

procedure TWreckage.Shatter(const AParts: TArray<TWreckPart>; const AHeart,
  AWay: TSdlFPoint);
begin
  FPieces := nil;
  for var Part in AParts do
  begin
    var Piece := Default(TWreckPiece);
    Piece.Shape := Part;
    Piece.Middle := Part.Middle;
    Piece.LastMiddle := Part.Middle;

    var OutX: Single := Part.Middle.X - AHeart.X;
    var OutY: Single := Part.Middle.Y - AHeart.Y;
    var Reach: Single := Hypot(OutX, OutY);
    if Reach < 1 then
    begin
      OutX := 0;
      OutY := -1;
      Reach := 1;
    end;
    var Scatter := Roll(ScatterLeast, ScatterMost);
    Piece.Speed.X := KeptWay * AWay.X + Scatter * OutX / Reach;
    Piece.Speed.Y := KeptWay * AWay.Y + Scatter * OutY / Reach -
      Roll(HopLeast, HopMost);

    Piece.Spin := Part.Spin;
    Piece.LastSpin := Part.Spin;
    Piece.SpinRate := Roll(TumbleLeast, TumbleMost);
    if FDice.NextUnit < 0.5 then
      Piece.SpinRate := -Piece.SpinRate;
    FPieces := FPieces + [Piece];
  end;
end;

// The last one gone, the air is empty
procedure TWreckage.Tick(AWind: Single);
begin
  for var i := 0 to High(FPieces) do
  begin
    var Piece := FPieces[i];
    if Piece.Gone then
      Continue;
    Piece.LastMiddle := Piece.Middle;
    Piece.LastSpin := Piece.Spin;
    Piece.Speed.X := Piece.Speed.X + (-AWind - Piece.Speed.X) * WindDrag;
    Piece.Speed.Y := Piece.Speed.Y + WreckGravity;
    Piece.Middle.X := Piece.Middle.X + Piece.Speed.X;
    Piece.Middle.Y := Piece.Middle.Y + Piece.Speed.Y;
    Piece.Spin := Piece.Spin + Piece.SpinRate;
    Piece.Gone := OffTheScreen(Piece.Middle);
    FPieces[i] := Piece;
  end;
end;

procedure TWreckage.Clear;
begin
  FPieces := nil;
end;

function TWreckage.Count: Integer;
begin
  Result := Length(FPieces);
end;

function TWreckage.Falling: Boolean;
begin
  for var Piece in FPieces do
    if not Piece.Gone then
      Exit(True);
  Result := False;
end;

function TWreckage.GetPiece(AIndex: Integer): TWreckPiece;
begin
  Result := FPieces[AIndex];
end;

function TWreckage.MiddleAt(AIndex: Integer; AAlpha: Single): TSdlFPoint;
begin
  var Piece := FPieces[AIndex];
  Result.X := Lerp(Piece.LastMiddle.X, Piece.Middle.X, AAlpha);
  Result.Y := Lerp(Piece.LastMiddle.Y, Piece.Middle.Y, AAlpha);
end;

function TWreckage.SpinAt(AIndex: Integer; AAlpha: Single): Single;
begin
  Result := Lerp(FPieces[AIndex].LastSpin, FPieces[AIndex].Spin, AAlpha);
end;

// ---------------------------------------------------------------------------
// TWreckagePainter
// ---------------------------------------------------------------------------

constructor TWreckagePainter.Create(ARenderer: PSdlRenderer;
  AWreckage: TWreckage);
begin
  inherited Create;
  FRenderer := ARenderer;
  FWreckage := AWreckage;
end;

// A mirrored piece is its part of the pictures flipped: the hull drew the
// whole of them flipped, and the part's place with them
procedure TWreckagePainter.Draw(AOrigin: TSdlPoint; AAlpha: Single);
var
  TextureWidth, TextureHeight: Integer;
  Source: TSdlRect;
  Dest: TSdlFRect;
begin
  for var i := 0 to FWreckage.Count - 1 do
  begin
    var Piece := FWreckage[i];
    if Piece.Gone then
      Continue;
    var Shape := Piece.Shape;
    var Middle := FWreckage.MiddleAt(i, AAlpha);
    Dest.X := Middle.X - Shape.Width / 2 + AOrigin.X;
    Dest.Y := Middle.Y - Shape.Height / 2 + AOrigin.Y;
    Dest.W := Shape.Width;
    Dest.H := Shape.Height;
    var Flip: Integer := SdlFlipNone;
    if Shape.Mirrored then
      Flip := SdlFlipHorizontal;
    var Spin := FWreckage.SpinAt(i, AAlpha);
    for var Texture in Shape.Layers do
    begin
      if Texture = nil then
        Continue;
      SDL_QueryTexture(Texture, nil, nil, @TextureWidth, @TextureHeight);
      Source.X := Round(Shape.Part.X * TextureWidth);
      Source.Y := Round(Shape.Part.Y * TextureHeight);
      Source.W := Round((Shape.Part.X + Shape.Part.W) * TextureWidth) - Source.X;
      Source.H := Round((Shape.Part.Y + Shape.Part.H) * TextureHeight) - Source.Y;
      SDL_SetTextureColorMod(Texture, 255, 255, 255);
      SDL_SetTextureAlphaMod(Texture, 255);
      SDL_RenderCopyExF(FRenderer, Texture, @Source, @Dest, Spin, nil, Flip);
    end;
  end;
end;

end.
