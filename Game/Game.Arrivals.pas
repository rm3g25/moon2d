{
  Game.Arrivals - the violet light a body comes down in: where the trial
  lets a gravel or a medkit down from the sky, and where a gravel that
  strayed out comes back.

  A mark is a column of light and a glow at the top edge, on its own clock:
  it gathers, peaks and dies out. The look only - the body itself is the
  monster field's.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Arrivals;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics;

type
  TArrivals = class
  private type
    TMark = record
      X: Single;
      Age: Integer;
    end;
  private
    FMarks: TList<TMark>;
    procedure DrawMark(const ACanvas: TDynamicCanvas; const AMark: TMark;
      AOrigin: TSdlPoint; AAlpha: Single);
  public
    constructor Create;
    destructor Destroy; override;
    // AX - the middle of the body, in screen units
    procedure Add(AX: Single);
    procedure Tick;
    // AOrigin - the shake of the monsters; AAlpha - the step between two
    // ticks
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // A door or a death: nothing follows the hero to the next screen
    procedure Clear;
  end;

implementation

uses
  System.Math, Render.Glow;

const
  ArrivalTicks = 14;
  // The body falls in from above the screen, so the glow stands just
  // inside the top edge
  ArrivalHeight = 14;
  ArrivalSize = 44;
  ArrivalCoreShare = 0.45;
  ArrivalBeamWidth = 14;
  ArrivalBeamLength = 60;
  ArrivalBeamLevel = 0.6;
  ArrivalColor: TRgb = (R: 168; G: 92; B: 255);
  ArrivalCoreColor: TRgb = (R: 232; G: 208; B: 255);

constructor TArrivals.Create;
begin
  inherited Create;
  FMarks := TList<TMark>.Create;
end;

destructor TArrivals.Destroy;
begin
  FMarks.Free;
  inherited Destroy;
end;

procedure TArrivals.Add(AX: Single);
begin
  var Mark: TMark;
  Mark.X := AX;
  Mark.Age := 0;
  FMarks.Add(Mark);
end;

procedure TArrivals.Tick;
begin
  for var i := FMarks.Count - 1 downto 0 do
  begin
    var Mark := FMarks[i];
    Inc(Mark.Age);
    if Mark.Age >= ArrivalTicks then
      FMarks.Delete(i)
    else
      FMarks[i] := Mark;
  end;
end;

procedure TArrivals.DrawMark(const ACanvas: TDynamicCanvas;
  const AMark: TMark; AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Share: Single := (AMark.Age + AAlpha) / ArrivalTicks;
  if Share > 1 then
    Share := 1;
  var Level: Single := Sin(Pi * Share);
  var CenterX: Single := AOrigin.X + AMark.X;
  var CenterY: Single := AOrigin.Y + ArrivalHeight;
  // The light gathers into the point the body arrives at
  var Across: Single := ArrivalSize * (1.3 - 0.5 * Share);

  var Beam: TSdlFRect;
  Beam.X := CenterX - ArrivalBeamWidth / 2;
  Beam.Y := AOrigin.Y;
  Beam.W := ArrivalBeamWidth;
  Beam.H := ArrivalBeamLength;
  DrawGlowRect(ACanvas.Renderer, ACanvas.PointGlow, Beam, ArrivalColor,
    Level * ArrivalBeamLevel);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY, Across,
    ArrivalColor, Level);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    Across * ArrivalCoreShare, ArrivalCoreColor, Level);
end;

procedure TArrivals.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  for var Mark in FMarks do
    DrawMark(ACanvas, Mark, AOrigin, AAlpha);
end;

procedure TArrivals.Clear;
begin
  FMarks.Clear;
end;

end.
