{
  Game.Pieces - what is left of a barge that breaks in the Ram's air
  fight: its picture cut into a few pieces, each flying off from where it
  was in the barge - on with a share of the barge's way, out from its
  middle and up a little - tumbling, falling with the moon's pull, gone
  once it is under the screen or past its sides.

  The pieces are decoration: neither a floor, nor a body, nor a wound. A
  death takes them away.

  TBargePieces is the rules, TBargePiecePainter draws them: each piece its
  part of the barge's picture, turned.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Pieces;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Pads.World;

type
  // A barge as it breaks: its picture Width by Height about Middle,
  // turned Spin degrees clockwise, going Speed units a tick
  TBrokenBarge = record
    // Whose picture it is; nil for a barge of no picture
    Pad: TPad;
    Middle: TSdlFPoint;
    Width, Height: Single;
    Spin: Single;
    Speed: TSdlFPoint;
  end;

  TBargePiece = record
    Pad: TPad;
    // The part of the picture it is, in shares of the picture
    Part: TSdlFRect;
    Width, Height: Single;
    // Its middle, this tick and the last, screen units
    Middle, LastMiddle: TSdlFPoint;
    Speed: TSdlFPoint;
    // Degrees clockwise, this tick and the last, and how fast it tumbles
    Spin, LastSpin: Single;
    SpinRate: Single;
    Gone: Boolean;
  end;

  TBargePieces = class
  private
    FPieces: TArray<TBargePiece>;
    FDice: TXorShift;
    function GetPiece(AIndex: Integer): TBargePiece;
    function Roll(ALeast, AMost: Single): Single;
  public
    // ASeed - the dice of the pieces' flight
    constructor Create(ASeed: Cardinal);
    procedure Shatter(const ABarge: TBrokenBarge);
    procedure Tick;
    // A death, a new level: none in the air
    procedure Clear;
    function Count: Integer;
    // Some are still on the screen
    function Falling: Boolean;
    // AAlpha of the way from the last tick to this one
    function MiddleAt(AIndex: Integer; AAlpha: Single): TSdlFPoint;
    function SpinAt(AIndex: Integer; AAlpha: Single): Single;
    property Pieces[AIndex: Integer]: TBargePiece read GetPiece; default;
  end;

  TBargePiecePainter = class
  private
    FRenderer: PSdlRenderer;
    FPieces: TBargePieces;
  public
    // APieces belongs to the caller and must outlive the painter
    constructor Create(ARenderer: PSdlRenderer; APieces: TBargePieces);
    procedure Draw(AOrigin: TSdlPoint; AAlpha: Single);
  end;

implementation

uses
  System.Math, Render.Sprites, Game.Space;

const
  // A piece is about this long; a barge breaks in two rows of them
  PieceSpan = 24.0;
  PieceRows = 2;
  // The share of the barge's way a piece keeps; out from the barge's
  // middle and up at these paces, units a tick
  KeptWay = 0.3;
  ScatterLeast = 0.6;
  ScatterMost = 2.2;
  HopLeast = 1.0;
  HopMost = 3.5;
  // Degrees a tick, either way
  TumbleLeast = 6.0;
  TumbleMost = 18.0;
  // Heavier than the hero's fall: the pieces are to be gone soon
  PieceGravity = 0.25;
  // Gone this far under the screen or past its sides
  PieceOffMargin = 40.0;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function OffTheScreen(const AMiddle: TSdlFPoint): Boolean;
begin
  Result := (AMiddle.Y > ScreenHeight + PieceOffMargin) or
    (AMiddle.X < -PieceOffMargin) or (AMiddle.X > ScreenWidth + PieceOffMargin);
end;

// ---------------------------------------------------------------------------
// TBargePieces
// ---------------------------------------------------------------------------

constructor TBargePieces.Create(ASeed: Cardinal);
begin
  inherited Create;
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;
end;

function TBargePieces.Roll(ALeast, AMost: Single): Single;
begin
  Result := ALeast + (AMost - ALeast) * FDice.NextUnit;
end;

// Each piece from its place in the turned barge, out from the barge's
// middle the way that place lies
procedure TBargePieces.Shatter(const ABarge: TBrokenBarge);
begin
  var Cols: Integer := Max(2, Round(ABarge.Width / PieceSpan));
  var Angle := DegToRad(ABarge.Spin);
  for var Row := 0 to PieceRows - 1 do
    for var Col := 0 to Cols - 1 do
    begin
      var Piece := Default(TBargePiece);
      Piece.Pad := ABarge.Pad;
      Piece.Part.X := Col / Cols;
      Piece.Part.Y := Row / PieceRows;
      Piece.Part.W := 1 / Cols;
      Piece.Part.H := 1 / PieceRows;
      Piece.Width := ABarge.Width / Cols;
      Piece.Height := ABarge.Height / PieceRows;

      var Along: Single := ((Col + 0.5) / Cols - 0.5) * ABarge.Width;
      var Down: Single := ((Row + 0.5) / PieceRows - 0.5) * ABarge.Height;
      var OutX: Single := Along * Cos(Angle) - Down * Sin(Angle);
      var OutY: Single := Along * Sin(Angle) + Down * Cos(Angle);
      Piece.Middle.X := ABarge.Middle.X + OutX;
      Piece.Middle.Y := ABarge.Middle.Y + OutY;
      Piece.LastMiddle := Piece.Middle;

      var Reach: Single := Max(Hypot(OutX, OutY), 1.0);
      var Scatter := Roll(ScatterLeast, ScatterMost);
      Piece.Speed.X := KeptWay * ABarge.Speed.X + Scatter * OutX / Reach;
      Piece.Speed.Y := KeptWay * ABarge.Speed.Y + Scatter * OutY / Reach -
        Roll(HopLeast, HopMost);

      Piece.Spin := ABarge.Spin;
      Piece.LastSpin := ABarge.Spin;
      Piece.SpinRate := Roll(TumbleLeast, TumbleMost);
      if FDice.NextUnit < 0.5 then
        Piece.SpinRate := -Piece.SpinRate;
      FPieces := FPieces + [Piece];
    end;
end;

// The last one gone, the air is empty for the next barge
procedure TBargePieces.Tick;
begin
  for var i := 0 to High(FPieces) do
  begin
    var Piece := FPieces[i];
    if Piece.Gone then
      Continue;
    Piece.LastMiddle := Piece.Middle;
    Piece.LastSpin := Piece.Spin;
    Piece.Speed.Y := Piece.Speed.Y + PieceGravity;
    Piece.Middle.X := Piece.Middle.X + Piece.Speed.X;
    Piece.Middle.Y := Piece.Middle.Y + Piece.Speed.Y;
    Piece.Spin := Piece.Spin + Piece.SpinRate;
    Piece.Gone := OffTheScreen(Piece.Middle);
    FPieces[i] := Piece;
  end;
  if not Falling then
    FPieces := nil;
end;

procedure TBargePieces.Clear;
begin
  FPieces := nil;
end;

function TBargePieces.Count: Integer;
begin
  Result := Length(FPieces);
end;

function TBargePieces.Falling: Boolean;
begin
  for var Piece in FPieces do
    if not Piece.Gone then
      Exit(True);
  Result := False;
end;

function TBargePieces.GetPiece(AIndex: Integer): TBargePiece;
begin
  Result := FPieces[AIndex];
end;

function TBargePieces.MiddleAt(AIndex: Integer; AAlpha: Single): TSdlFPoint;
begin
  var Piece := FPieces[AIndex];
  Result.X := Lerp(Piece.LastMiddle.X, Piece.Middle.X, AAlpha);
  Result.Y := Lerp(Piece.LastMiddle.Y, Piece.Middle.Y, AAlpha);
end;

function TBargePieces.SpinAt(AIndex: Integer; AAlpha: Single): Single;
begin
  Result := Lerp(FPieces[AIndex].LastSpin, FPieces[AIndex].Spin, AAlpha);
end;

// ---------------------------------------------------------------------------
// TBargePiecePainter
// ---------------------------------------------------------------------------

constructor TBargePiecePainter.Create(ARenderer: PSdlRenderer;
  APieces: TBargePieces);
begin
  inherited Create;
  FRenderer := ARenderer;
  FPieces := APieces;
end;

procedure TBargePiecePainter.Draw(AOrigin: TSdlPoint; AAlpha: Single);
var
  TextureWidth, TextureHeight: Integer;
  Source: TSdlRect;
  Dest: TSdlFRect;
begin
  for var i := 0 to FPieces.Count - 1 do
  begin
    var Piece := FPieces[i];
    if Piece.Gone or (Piece.Pad = nil) or (Piece.Pad.Texture = nil) then
      Continue;
    var Texture := Piece.Pad.Texture;
    SDL_QueryTexture(Texture, nil, nil, @TextureWidth, @TextureHeight);
    Source.X := Round(Piece.Part.X * TextureWidth);
    Source.Y := Round(Piece.Part.Y * TextureHeight);
    Source.W := Round((Piece.Part.X + Piece.Part.W) * TextureWidth) - Source.X;
    Source.H := Round((Piece.Part.Y + Piece.Part.H) * TextureHeight) - Source.Y;
    var Middle := FPieces.MiddleAt(i, AAlpha);
    Dest.X := Middle.X - Piece.Width / 2 + AOrigin.X;
    Dest.Y := Middle.Y - Piece.Height / 2 + AOrigin.Y;
    Dest.W := Piece.Width;
    Dest.H := Piece.Height;
    var Tint := Piece.Pad.Placement.Tint;
    TintTexture(Texture, Tint.R, Tint.G, Tint.B);
    SDL_SetTextureAlphaMod(Texture, 255);
    SDL_RenderCopyExF(FRenderer, Texture, @Source, @Dest,
      FPieces.SpinAt(i, AAlpha), nil, SdlFlipNone);
  end;
end;

end.
