{
  Game.Throw - the scene of the throw, after the burst of the henshin: the
  Ram drives off to the left, a cell of road behind it, the orbs carry the
  hero out of the picture - a little over the road by the right edge - then
  fly out of his body to the pads on the screen and cling to their beams;
  a pad gripped, its jets die and it glides, slowly, to its place on a
  wide arc round the Ram's right side from just under the top of the
  screen, every place as far from the Ram - room for the pads to gather
  speed at the volley; every pad gripped, they spin up on the quickening
  heart, and the Ram's lamps and eye blink in alarm. Spun up, the hint of
  the press shows over him.

  The press - or three seconds with none - and the volley: the heart
  stops, the hum is cut, and each pad is let go at its own small delay,
  flying at the Ram's honeycomb. Each that meets it blows up and breaks a
  piece of it off; the last a big blast, and the rest of the honeycomb
  crumbles. Then the scene stands: he hangs in his place, the controls
  not his, till the wheel.

  The burst struck, the scene waits a second - the Ram thrown and smoking
  first - and catches him: from then on the controls are not his, and the
  game puts him on his way (Game.Hoist) every tick. In his place, the
  orbs go out (Orbs.Grip); the game tells the scene each pad they grip,
  and the pad is the game's to hold (Game.Wrecks). The last pad held, the
  spin runs up over four seconds, faster on every beat - the pads gliding
  to their places as long; then the hint. The game hands in the press
  (Press) and tells the scene each pad that struck (PadStruck).

  Too few pads on the screen, and the game calls the rest in from the pool
  of the chase as he is caught, to stand where PlaceCalledPads says: they
  are in by the time he is in his place. Too many, and the ones nearest
  him are taken; the rest stay on their jets.

  The scene knows neither the pads, the Ram nor the orbs: it tells its
  cues, keeps its clock and plans the arc (PlanArc, ArcOrder); the game
  carries them out. TThrowPainter draws the hint.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Throw;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Game.Space, Game.Hoist;

const
  // The Ram thrown and smoking first
  CatchAfterTicks = 33;
  // The spin runs up over this long, and a gripped pad glides to its
  // place as long
  SpinUpTicks = 132;
  GlideTicks = 132;
  // Degrees a tick a held pad spins at, spun up: past about this the pad's
  // picture reads as a propeller (Game.Wrecks). A thump speeds it by
  // SpinBeatSurge of itself.
  SpunUpSpin = 24.0;
  SpinBeatSurge = 0.3;
  ThrowLeastPads = 4;
  ThrowMostPads = 7;
  // The beam of the deck of the chase's pads, units down from the top of
  // the picture: 38 px of 103 at 6 px a unit (city-pad and city-pad-long
  // of level2-objects.mset); the engines hang under it
  PadBeamDepth = 6.3;
  // The Ram drives off to stand with its left edge here, a cell of road
  // left behind it; its middle is the middle of the arc
  RamPlaceLeft = 32;
  // The hero hangs this far from the right edge, this far over the road
  HeroPlaceEdge = 48;
  HeroHover = 8;
  // Spun up, the pads go by themselves this long after with no press;
  // each is let go up to this long after the volley's start
  ThrowAfterTicks = 99;
  LetGoMostTicks = 6;

type
  // tsWaiting - the burst has struck, he is not caught yet; tsCarrying -
  // caught, on his way to his place; tsGripping - in it, the orbs out to
  // the pads; tsSpinning - every pad held, spinning up; tsSpunUp - the
  // hint; tsVolley - let go, flying; tsStruck - every pad has struck
  TThrowStage = (tsIdle, tsWaiting, tsCarrying, tsGripping, tsSpinning,
    tsSpunUp, tsVolley, tsStruck);

  TThrowCue = record
    // He is caught: the controls are taken; the game plans his way and
    // hands it in (Carry), and calls in the pads the screen lacks
    Catch: Boolean;
    // He is in his place: the orbs go out; the game hands in to how many
    // pads (Grip)
    Grip: Boolean;
    // The last pad held: the spin runs up
    SpinUp: Boolean;
    // Spun up: the hint
    SpunUp: Boolean;
    // Pressed, or the wait over: the silence; the pads are let go
    Volley: Boolean;
    // The pads let go this tick, by their number
    LetGo: TArray<Integer>;
  end;

  TThrowScene = class
  private
    FStage: TThrowStage;
    // Ticks into the stage
    FTicks: Integer;
    FPath: THoistPath;
    FPads: Integer;
    FHeld: Integer;
    FPressed: Boolean;
    FStruck: Integer;
    procedure Enter(AStage: TThrowStage);
    function LettingGo: TArray<Integer>;
  public
    // The burst has struck
    procedure Start;
    procedure Clear;
    // His way, planned as he is caught
    procedure Carry(const APath: THoistPath);
    // In his place: the orbs go out to ACount pads
    procedure Grip(ACount: Integer);
    // The orbs have gripped one more pad
    procedure PadHeld;
    // The press of the throw: heard spun up, nothing before
    procedure Press;
    // One more pad let go has struck
    procedure PadStruck;
    // Every pad let go has struck; with no pad, at once
    function AllStruck: Boolean;
    function Tick: TThrowCue;
    function Running: Boolean;
    // From the catch on he hangs where HeroAt puts him
    function Holds: Boolean;
    // From the catch on the heart beats again, till the volley
    function Beats: Boolean;
    // His left edge and feet line on his way, in his place once there
    function HeroAt: TSdlFPoint;
    // How far the spin has run up, 0..1
    function Spin: Single;
    // Degrees a tick a held pad spins at, APulse the heart's pulse
    function SpinRate(APulse: Single): Single;
    // How far the hint has come in, 0..1, AAlpha of the way from the last
    // tick to this one
    function Hint(AAlpha: Single): Single;
    property Stage: TThrowStage read FStage;
  end;

  // A pad the scene calls in: its corner on its deck and its width, and
  // how far off its place it comes in from - beyond the nearer side edge
  TCalledPad = record
    Left, Deck: Single;
    Width: Integer;
    From: TSdlFPoint;
  end;

  TThrowPainter = class
  private
    FScene: TThrowScene;
    FBrush: THudBrush;
  public
    // The scene belongs to the caller and must outlive the painter
    constructor Create(ARenderer: PSdlRenderer; AScene: TThrowScene);
    destructor Destroy; override;
    // Over AHead, the middle of the top of his body, swelling with APulse,
    // the heart's
    procedure DrawHint(const AHead: TSdlFPoint; APulse, AAlpha: Single);
  end;

// Where AMissing pads the scene lacks come to stand: clear of ATaken - the
// pads standing, the hull and the hero in his place - each as far from the
// rest as it can be. Fewer when the screen has no room for them.
function PlaceCalledPads(const ATaken: TArray<TSdlFRect>;
  AMissing: Integer): TArray<TCalledPad>;

// The places of the middles of the beams of ACount pads round ACenter,
// the Ram's middle: on an arc from up and left of it over its top - just
// under the top of the screen - to its right, a little over its middle;
// evenly apart over the whole of it, all as far from it. The first up and
// left. No more than ThrowMostPads: the long ones spinning would meet.
function PlanArc(const ACenter: TSdlFPoint;
  ACount: Integer): TArray<TSdlFPoint>;

// The place of APlaces (as PlanArc lays them) each of APoints goes to:
// by their turn about ACenter, so no two ways cross
function ArcOrder(const ACenter: TSdlFPoint;
  const APoints: TArray<TSdlFPoint>): TArray<Integer>;

implementation

uses
  System.Math, Pads.Drift, Hud.Charge;

const
  HintInTicks = 8;

  // A called pad stands on the decks of the rows of the hunt's wave, this
  // far off the screen's edges, tried every CalledStep across; its body is
  // CalledDepth deep, with CalledRoom kept about it and about what is taken
  CalledMargin = 16;
  CalledStep = 16;
  CalledDepth = 16;
  CalledRoom = 16;
  // It comes in from this far past the edge
  CalledComeBeyond = 16;

  // The arc, degrees counter-clockwise from straight right, the screen's
  // up being up; its top this far under the top of the screen, so a long
  // pad spinning there stays on it
  ArcFrom = 105.0;
  ArcTill = 10.0;
  ArcTopClear = 36.0;

  // Over his head by this much, at this many times the HUD's size, the
  // whole glyph swelling on a thump by HintSwell and its button lit by it
  HintRise = 6;
  HintScale = 2.0;
  HintSwell = 0.2;
  HintButtonRest = 0.45;

{ TThrowScene }

procedure TThrowScene.Start;
begin
  Clear;
  Enter(tsWaiting);
end;

procedure TThrowScene.Clear;
begin
  FStage := tsIdle;
  FTicks := 0;
  FPath := Default(THoistPath);
  FPads := 0;
  FHeld := 0;
  FPressed := False;
  FStruck := 0;
end;

procedure TThrowScene.Enter(AStage: TThrowStage);
begin
  FStage := AStage;
  FTicks := 0;
end;

procedure TThrowScene.Carry(const APath: THoistPath);
begin
  FPath := APath;
end;

procedure TThrowScene.Grip(ACount: Integer);
begin
  FPads := Max(ACount, 0);
  FHeld := 0;
end;

procedure TThrowScene.PadHeld;
begin
  if FStage = tsGripping then
    Inc(FHeld);
end;

procedure TThrowScene.Press;
begin
  if FStage = tsSpunUp then
    FPressed := True;
end;

procedure TThrowScene.PadStruck;
begin
  if FStage = tsVolley then
    Inc(FStruck);
end;

function TThrowScene.AllStruck: Boolean;
begin
  Result := (FStage >= tsVolley) and (FStruck >= FPads);
end;

// Each pad at its own delay, spread over the most by the golden share:
// the first at once, no two neighbours close
function LetGoDelay(ANumber: Integer): Integer;
const
  GoldenShare = 0.618034;
begin
  Result := Round(LetGoMostTicks * Frac(ANumber * GoldenShare));
end;

function TThrowScene.LettingGo: TArray<Integer>;
begin
  Result := [];
  for var i := 0 to FPads - 1 do
    if LetGoDelay(i) = FTicks then
      Result := Result + [i];
end;

function TThrowScene.Tick: TThrowCue;
begin
  Result := Default(TThrowCue);
  if FStage = tsIdle then
    Exit;
  Inc(FTicks);
  case FStage of
    tsWaiting:
      if FTicks >= CatchAfterTicks then
      begin
        Enter(tsCarrying);
        Result.Catch := True;
      end;
    tsCarrying:
      if FTicks >= FPath.Ticks then
      begin
        Enter(tsGripping);
        Result.Grip := True;
      end;
    tsGripping:
      if FHeld >= FPads then
      begin
        Enter(tsSpinning);
        Result.SpinUp := True;
      end;
    tsSpinning:
      if FTicks >= SpinUpTicks then
      begin
        Enter(tsSpunUp);
        Result.SpunUp := True;
      end;
    tsSpunUp:
      if FPressed or (FTicks >= ThrowAfterTicks) then
      begin
        Enter(tsVolley);
        Result.Volley := True;
      end;
    tsVolley:
      if AllStruck then
        Enter(tsStruck);
  end;
  if FStage = tsVolley then
    Result.LetGo := LettingGo;
end;

function TThrowScene.Running: Boolean;
begin
  Result := FStage <> tsIdle;
end;

function TThrowScene.Holds: Boolean;
begin
  Result := FStage >= tsCarrying;
end;

function TThrowScene.Beats: Boolean;
begin
  Result := Holds and (FStage < tsVolley);
end;

function TThrowScene.HeroAt: TSdlFPoint;
begin
  if FStage = tsCarrying then
    Exit(FPath.At(FTicks));
  Result := FPath.Place;
end;

function TThrowScene.Spin: Single;
begin
  case FStage of
    tsSpinning:
      Result := Min(FTicks / SpinUpTicks, 1);
    tsSpunUp, tsVolley:
      Result := 1;
  else
    Result := 0;
  end;
end;

function TThrowScene.SpinRate(APulse: Single): Single;
begin
  Result := SpunUpSpin * Spin * (1 + SpinBeatSurge * APulse);
end;

function TThrowScene.Hint(AAlpha: Single): Single;
begin
  if FStage <> tsSpunUp then
    Exit(0);
  Result := Min((FTicks + AAlpha) / HintInTicks, 1);
end;

{ PlanArc, ArcOrder }

function PlanArc(const ACenter: TSdlFPoint;
  ACount: Integer): TArray<TSdlFPoint>;
begin
  SetLength(Result, Max(ACount, 0));
  if ACount <= 0 then
    Exit;
  var Span: Single := DegToRad(ArcFrom - ArcTill);
  var Radius: Single := ACenter.Y - ArcTopClear;
  for var i := 0 to ACount - 1 do
  begin
    var Turn: Single := DegToRad((ArcFrom + ArcTill) / 2);
    if ACount > 1 then
      Turn := DegToRad(ArcFrom) - Span * i / (ACount - 1);
    Result[i].X := ACenter.X + Radius * Cos(Turn);
    Result[i].Y := ACenter.Y - Radius * Sin(Turn);
  end;
end;

// Counter-clockwise from straight right, the screen's up being up; under
// the middle below zero
function TurnAbout(const ACenter, APoint: TSdlFPoint): Single;
begin
  Result := ArcTan2(ACenter.Y - APoint.Y, APoint.X - ACenter.X);
end;

// How many of APoints go before the one at AIndex, the most
// counter-clockwise first; of two at one turn, the first of APoints
function PlacesBefore(const ACenter: TSdlFPoint;
  const APoints: TArray<TSdlFPoint>; AIndex: Integer): Integer;
begin
  Result := 0;
  var Turn := TurnAbout(ACenter, APoints[AIndex]);
  for var i := 0 to High(APoints) do
  begin
    var Other := TurnAbout(ACenter, APoints[i]);
    var EarlierAtTheTurn := (Other = Turn) and (i < AIndex);
    if (Other > Turn) or EarlierAtTheTurn then
      Inc(Result);
  end;
end;

// The places go from the most counter-clockwise; so do the points
function ArcOrder(const ACenter: TSdlFPoint;
  const APoints: TArray<TSdlFPoint>): TArray<Integer>;
begin
  SetLength(Result, Length(APoints));
  for var i := 0 to High(APoints) do
    Result[i] := PlacesBefore(ACenter, APoints, i);
end;

{ PlaceCalledPads }

function Inflated(const ABox: TSdlFRect; ARoom: Single): TSdlFRect;
begin
  Result.X := ABox.X - ARoom;
  Result.Y := ABox.Y - ARoom;
  Result.W := ABox.W + 2 * ARoom;
  Result.H := ABox.H + 2 * ARoom;
end;

function Overlap(const A, B: TSdlFRect): Boolean;
begin
  Result := (A.X < B.X + B.W) and (B.X < A.X + A.W) and (A.Y < B.Y + B.H) and
    (B.Y < A.Y + A.H);
end;

function MiddleOf(const ABox: TSdlFRect): TSdlFPoint;
begin
  Result.X := ABox.X + ABox.W / 2;
  Result.Y := ABox.Y + ABox.H / 2;
end;

function CalledBox(ALeft, ADeck: Single): TSdlFRect;
begin
  Result.X := ALeft;
  Result.Y := ADeck;
  Result.W := HighWidth;
  Result.H := CalledDepth;
end;

// Clear of every box with room about it
function RoomAt(const ABox: TSdlFRect; const ABoxes: TArray<TSdlFRect>): Boolean;
begin
  for var Taken in ABoxes do
    if Overlap(ABox, Inflated(Taken, CalledRoom)) then
      Exit(False);
  Result := True;
end;

// From the box's middle to the nearest middle of the rest
function ApartFromNearest(const ABox: TSdlFRect;
  const ABoxes: TArray<TSdlFRect>): Single;
begin
  Result := MaxSingle;
  var Middle := MiddleOf(ABox);
  for var Taken in ABoxes do
  begin
    var Other := MiddleOf(Taken);
    Result := Min(Result, Hypot(Middle.X - Other.X, Middle.Y - Other.Y));
  end;
end;

// Every place a called pad may stand, row by row
function CalledSpots: TArray<TSdlFRect>;
begin
  Result := [];
  for var Deck in RowDecks do
  begin
    var Left: Single := CalledMargin;
    while Left + HighWidth <= ScreenWidth - CalledMargin do
    begin
      Result := Result + [CalledBox(Left, Deck)];
      Left := Left + CalledStep;
    end;
  end;
end;

// The spot with room about it farthest from the rest; False when none has
// room
function TryPickSpot(const ASpots, ABoxes: TArray<TSdlFRect>;
  out ABest: TSdlFRect): Boolean;
begin
  Result := False;
  var BestApart: Single := -1;
  for var Spot in ASpots do
  begin
    if not RoomAt(Spot, ABoxes) then
      Continue;
    var Apart := ApartFromNearest(Spot, ABoxes);
    if Apart <= BestApart then
      Continue;
    ABest := Spot;
    BestApart := Apart;
    Result := True;
  end;
end;

function ComingFrom(ALeft: Single): TSdlFPoint;
begin
  Result.Y := 0;
  if ALeft + HighWidth / 2 < ScreenWidth / 2 then
    Result.X := -(ALeft + HighWidth + CalledComeBeyond)
  else
    Result.X := ScreenWidth - ALeft + CalledComeBeyond;
end;

function PlaceCalledPads(const ATaken: TArray<TSdlFRect>;
  AMissing: Integer): TArray<TCalledPad>;
begin
  Result := [];
  var Spots := CalledSpots;
  var Boxes := ATaken;
  for var n := 1 to AMissing do
  begin
    var Best: TSdlFRect;
    if not TryPickSpot(Spots, Boxes, Best) then
      Exit;
    var Called: TCalledPad;
    Called.Left := Best.X;
    Called.Deck := Best.Y;
    Called.Width := HighWidth;
    Called.From := ComingFrom(Best.X);
    Result := Result + [Called];
    Boxes := Boxes + [Best];
  end;
end;

{ TThrowPainter }
{ TThrowPainter }

constructor TThrowPainter.Create(ARenderer: PSdlRenderer; AScene: TThrowScene);
begin
  inherited Create;
  FScene := AScene;
  FBrush := THudBrush.Create(ARenderer);
end;

destructor TThrowPainter.Destroy;
begin
  FBrush.Free;
  inherited;
end;

procedure TThrowPainter.DrawHint(const AHead: TSdlFPoint; APulse, AAlpha: Single);
begin
  var Shown := FScene.Hint(AAlpha);
  if Shown <= 0 then
    Exit;
  var Scale: Single := HintScale * (1 + HintSwell * APulse);
  var Width := MouseGlyphWidth * Scale;
  var Height := MouseGlyphHeight * Scale;
  var Button := HintButtonRest + (1 - HintButtonRest) * Min(APulse, 1);

  FBrush.BeginDraw;
  DrawMouseGlyph(FBrush, AHead.X - Width / 2, AHead.Y - HintRise - Height,
    Scale, Shown, Button * Shown);
  FBrush.EndDraw;
end;

end.
