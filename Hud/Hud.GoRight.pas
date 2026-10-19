{
  Hud.GoRight - the go-right arrow: the way on is open. A hollow arrow of
  neon tube in the middle of the screen, drawn as strips of light along
  its outline - the band glow of Render.Glow the bolts and the beams are
  drawn with - so it stays sharp at any size of the window. It comes up
  slowly and goes out slowly, four times, and then it is gone. Silent:
  the arrow is big enough to be seen.

  The beat and the picture are apart: TGoRightBeat counts and says how
  lit the arrow is; THudGoRight draws it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.GoRight;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

type
  TGoRightBeat = class
  private
    FShown: Boolean;
    FTick: Integer; // the tick played last; -1 - none yet
  public
    constructor Create;
    // Starts the beat over, from the first blink
    procedure Show;
    procedure Hide;
    // Once per logic tick; after the last blink the arrow hides itself
    procedure Tick;
    // How lit the arrow is, 0..1; APhase - how far the frame has gone
    // toward the next tick, 0..1
    function LevelAt(APhase: Single): Single;
    property Shown: Boolean read FShown;
  end;

  // One strip of light along the outline
  TTubePass = record
    Width: Single;
    Level: Single;
    Whiteness: Single; // 0 - the arrow's tint, 1 - white
    // How far a corner may stretch the strip, in its half-widths
    MiterLimit: Single;
  end;

  THudGoRight = class
  private
    FRenderer: PSdlRenderer;
    FBeam: PSdlTexture;
    FBeat: TGoRightBeat;
    FVertices: TArray<TSdlVertex>;
    FIndices: TArray<Integer>;
    procedure DrawTube(const APass: TTubePass; ALevel: Single);
  public
    constructor Create(ARenderer: PSdlRenderer);
    destructor Destroy; override;
    procedure Show;
    procedure Hide;
    procedure Tick;
    procedure Draw(AAlpha: Single);
  end;

implementation

uses
  System.Math, Game.Space, Render.Brush, Render.Glow;

const
  // Dark at its start and end, full in its middle
  BlinkTicks = 60;
  Blinks = 4;

  // In units from the middle of the screen, around the shape
  Outline: array [0..6] of TSdlFPoint = (
    (X: -48; Y: -9), (X: 8; Y: -9), (X: 8; Y: -27), (X: 48; Y: 0),
    (X: 8; Y: 27), (X: 8; Y: 9), (X: -48; Y: 9));

  NoMiterLimit = 1E6;
  // The halo mitered in full sticks horns out of the sharp corners; the
  // tube and the core keep the full miter, or they pinch at the corners
  TubePasses: array [0..2] of TTubePass = (
    (Width: 16; Level: 0.35; Whiteness: 0; MiterLimit: 1.5),
    (Width: 4.5; Level: 0.95; Whiteness: 0; MiterLimit: NoMiterLimit),
    (Width: 1.6; Level: 0.85; Whiteness: 1; MiterLimit: NoMiterLimit));
  BeamGlowSide = 64;

constructor TGoRightBeat.Create;
begin
  inherited Create;
  FTick := -1;
end;

procedure TGoRightBeat.Show;
begin
  FShown := True;
  FTick := -1;
end;

procedure TGoRightBeat.Hide;
begin
  FShown := False;
end;

procedure TGoRightBeat.Tick;
begin
  if not FShown then
    Exit;
  Inc(FTick);
  if FTick >= Blinks * BlinkTicks then
    Hide;
end;

function TGoRightBeat.LevelAt(APhase: Single): Single;
begin
  if not FShown or (FTick < 0) then
    Exit(0);
  var InBlink: Single := (FTick + APhase) / BlinkTicks;
  InBlink := InBlink - Trunc(InBlink);
  Result := 0.5 - 0.5 * Cos(2 * Pi * InBlink);
end;

function EdgeNormal(const AFrom, ATo: TSdlFPoint): TSdlFPoint;
begin
  var Span := Hypot(ATo.X - AFrom.X, ATo.Y - AFrom.Y);
  Result.X := -(ATo.Y - AFrom.Y) / Span;
  Result.Y := (ATo.X - AFrom.X) / Span;
end;

// From a corner of the outline to the edge of a strip AWidth across:
// along the bisector of the two edges' normals, stretched so both edges
// keep the strip's width
function MiterOffset(const ABefore, ACorner, AAfter: TSdlFPoint;
  AWidth, ALimit: Single): TSdlFPoint;
begin
  var Incoming := EdgeNormal(ABefore, ACorner);
  var Outgoing := EdgeNormal(ACorner, AAfter);
  var MiterX: Single := Incoming.X + Outgoing.X;
  var MiterY: Single := Incoming.Y + Outgoing.Y;
  var Span := Hypot(MiterX, MiterY);
  MiterX := MiterX / Span;
  MiterY := MiterY / Span;
  var Stretch: Single := 1 / (MiterX * Incoming.X + MiterY * Incoming.Y);
  if Stretch > ALimit then
    Stretch := ALimit;
  Result.X := MiterX * Stretch * AWidth / 2;
  Result.Y := MiterY * Stretch * AWidth / 2;
end;

constructor THudGoRight.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FRenderer := ARenderer;
  FBeam := CreateGlowShape(ARenderer, gsBeam, BeamGlowSide);
  FBeat := TGoRightBeat.Create;

  // Two vertices a corner, across the strip; two triangles an edge
  var Count := Length(Outline);
  SetLength(FVertices, 2 * Count);
  SetLength(FIndices, 6 * Count);
  for var i := 0 to Count - 1 do
  begin
    var Here := 2 * i;
    var Next := 2 * ((i + 1) mod Count);
    FIndices[6 * i] := Here;
    FIndices[6 * i + 1] := Here + 1;
    FIndices[6 * i + 2] := Next;
    FIndices[6 * i + 3] := Here + 1;
    FIndices[6 * i + 4] := Next + 1;
    FIndices[6 * i + 5] := Next;
  end;
end;

destructor THudGoRight.Destroy;
begin
  FBeat.Free;
  if FBeam <> nil then
    SDL_DestroyTexture(FBeam);
  inherited;
end;

procedure THudGoRight.Show;
begin
  FBeat.Show;
end;

procedure THudGoRight.Hide;
begin
  FBeat.Hide;
end;

procedure THudGoRight.Tick;
begin
  FBeat.Tick;
end;

procedure THudGoRight.DrawTube(const APass: TTubePass; ALevel: Single);
begin
  var Tint := Mix(CalmColor, White, APass.Whiteness);
  var Alpha: UInt8 := Round(255 * EnsureRange(APass.Level * ALevel, 0, 1));
  var Count := Length(Outline);
  for var i := 0 to Count - 1 do
  begin
    var Offset := MiterOffset(Outline[(i + Count - 1) mod Count], Outline[i],
      Outline[(i + 1) mod Count], APass.Width, APass.MiterLimit);
    for var Side := 0 to 1 do
    begin
      var Sign: Single := 1 - 2 * Side;
      var Corner := 2 * i + Side;
      FVertices[Corner].Position.X := FrameWidth / 2 + Outline[i].X +
        Sign * Offset.X;
      FVertices[Corner].Position.Y := FrameHeight / 2 + Outline[i].Y +
        Sign * Offset.Y;
      FVertices[Corner].Color.R := Tint.R;
      FVertices[Corner].Color.G := Tint.G;
      FVertices[Corner].Color.B := Tint.B;
      FVertices[Corner].Color.A := Alpha;
      FVertices[Corner].TexCoord.X := 0.5;
      FVertices[Corner].TexCoord.Y := Side;
    end;
  end;
  SDL_RenderGeometry(FRenderer, FBeam, @FVertices[0], Length(FVertices),
    @FIndices[0], Length(FIndices));
end;

procedure THudGoRight.Draw(AAlpha: Single);
begin
  var Level := FBeat.LevelAt(AAlpha);
  if Level <= 0 then
    Exit;
  for var Pass in TubePasses do
    DrawTube(Pass, Level);
end;

end.
