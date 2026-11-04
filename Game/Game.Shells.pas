{
  Game.Shells - the bunker's shells in the chase. A shell is lobbed along
  a low arc seen whole, at the point where the hero's feet were: a deck
  he stood on, or the road. The arc is aimed in the world, not on the
  screen - the point rides the road, so a hero who keeps standing gets it
  and one who runs leaves it behind.

  A ring marks where it will come down, every tick anew: the first deck
  under what is left of its arc, or the road. A pad knocked off from under
  the ring sends the ring on down to what lies below.

  A shell that comes down on a deck bursts there, and the game knocks that
  pad off - whoever stood on it falls. One that misses every deck lands
  on the road and rolls along it the way it was lobbed, faster than the
  road runs. In the air or rolling, a shell that touches the hero is spent
  on him. Past either edge it is gone. What a burst does to whoever is near is the
  game's: a blast, as a tank's.

  In the bunker's second phase the shells come in pairs; where the second
  goes is SecondShellMark's. In its hunt the second goes ahead of the hero
  along his row, AheadShellMark's.

  It knows neither the pads, the hero nor the bunker: the game gives it
  the decks of the screen and the road's way of the tick, asks it what
  touches the hero, and carries out the cue. TBunkerShells is the rules,
  TShellPainter draws them with the shapes of the dynamics' canvas.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Shells;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Levels.Dynamics;

const
  // As many as can be in the air and on the road at once
  ShellSlots = 8;
  ShellRadius = 3.5;

type
  // The top of a pad's deck: where a shell bursts
  TShellDeck = record
    Left, Right, Top: Single;
  end;

  TShellState = (ssNone, ssFlying, ssRolling);

  TShell = record
    State: TShellState;
    // The middle, this tick and the last, screen units
    Middle, LastMiddle: TSdlFPoint;
    // Units a tick along the road; the road's own way comes on top
    Speed: TSdlFPoint;
    // Where it comes down, and on what: a deck or the road; the ticks till
    // then
    Ring: TSdlFPoint;
    RingOnDeck: Boolean;
    RingTicks: Integer;
    // The ticks the whole arc takes, as lobbed
    FlightTicks: Integer;
    // How far it has rolled, below 0 to the right: its picture turns by it
    Rolled: Single;
    // The way it rolls, -1 left or 1 right: the way it was lobbed
    RollWay: Integer;
    // Which lob since the clear it is: a new shell in a spent one's slot
    // has another
    Turn: Integer;
  end;

  TShellBurst = record
    At: TSdlFPoint;
    // The deck of the list given to the tick it burst on
    Deck: Integer;
  end;

  TShellCue = record
    Bursts: TArray<TShellBurst>;
    // Came down onto the road this tick
    Landed: Boolean;
  end;

  TBunkerShells = class
  private
    FShells: array [0..ShellSlots - 1] of TShell;
    FRoadY: Single;
    FLobs: Integer;
    procedure Predict(var AShell: TShell; const ADecks: TArray<TShellDeck>);
    function GetShell(AIndex: Integer): TShell;
    function Aim(const AFrom, ATarget: TSdlFPoint; out ATicks: Integer): TSdlFPoint;
    function ReachesRoad(const AFrom: TSdlFPoint; AX: Single;
      const ADecks: TArray<TShellDeck>): Boolean;
  public
    // ARoadY - the top of the road the shells roll on
    constructor Create(ARoadY: Single);
    // A shell out of AFrom that comes down on ATarget, both on the screen
    // now; False when every slot is taken
    function Lob(const AFrom, ATarget: TSdlFPoint): Boolean;
    // Where on the road, nearest AX, a shell out of AFrom comes down with
    // no deck in its way: the road at AX itself when none is clear
    function RoadMark(const AFrom: TSdlFPoint; AX: Single;
      const ADecks: TArray<TShellDeck>): TSdlFPoint;
    // ADecks - the decks of the screen this tick; AWay - what the road ran
    // this tick, below zero to the left
    function Tick(const ADecks: TArray<TShellDeck>; AWay: Single): TShellCue;
    // A shell in the air or rolling touches ABody: it is spent on it, at
    // AAt
    function Strikes(const ABody: TSdlFRect; out AAt: TSdlFPoint): Boolean;
    // A death, a door, a new level: none left
    procedure Clear;
    // In the air or on the road
    function Active: Integer;
    function MiddleAt(AIndex: Integer; AAlpha: Single): TSdlFPoint;
    property Shells[AIndex: Integer]: TShell read GetShell; default;
  end;

  TShellPainter = class
  private
    FShells: TBunkerShells;
    FTrails: array [0..ShellSlots - 1] of TSmoke;
    FTurns: array [0..ShellSlots - 1] of Integer;
    FAge: Integer;
    procedure DrawRing(const ACanvas: TDynamicCanvas; const AShell: TShell;
      AOrigin: TSdlPoint);
  public
    // AShells belongs to the caller and must outlive the painter
    constructor Create(AShells: TBunkerShells);
    destructor Destroy; override;
    // After the shells' tick: the trails follow; what they left in the air
    // rides the road's AWay
    procedure Tick(AWay: Single);
    // On the decks and the road, under the figures
    procedure DrawRings(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // The trails and the shells, with the bullets
    procedure DrawShells(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  end;

// Where the second shell of a pair goes, the hero's feet at AFeet: the
// middle of ADecks' deck he stands on; else of the nearest one a plain
// jump up that has ridden past the middle of the screen - a pad is let in
// first, so the way up is caught on the right half; else the road ahead
// of him, ARoadY, where its roll comes back at him
function SecondShellMark(const ADecks: TArray<TShellDeck>;
  const AFeet: TSdlFPoint; ARoadY: Single): TSdlFPoint;

// Where the second shell of a pair goes in the hunt, the hero's feet at
// AFeet: the middle of the nearest of ADecks' decks ahead of him - right
// of his feet - along the row he stands on, a hole where he runs; else
// the road ahead of him, ARoadY
function AheadShellMark(const ADecks: TArray<TShellDeck>;
  const AFeet: TSdlFPoint; ARoadY: Single): TSdlFPoint;

implementation

uses
  System.Math, Render.Brush, Render.Glow, Levels.Tint, Game.Space;

const
  // The moon's pull on a shell, units a tick every tick
  ShellGravity = 0.25;
  // The arc's top stands this far over the higher of its two ends: low,
  // seen whole - lower than the napalm, which climbs out of sight
  LobRise = 40.0;
  // An arc takes this long at the least and at the most
  LobLeastTicks = 18;
  LobMostTicks = 60;
  // Along the road the way it was lobbed, units a tick, on top of the
  // road's own way: faster than the road runs
  RollSpeed = 1.6;
  // Gone this far past an edge
  ShellOffMargin = 24.0;
  // Its arc looked ahead this far at most for the ring
  PredictTicks = 240;
  // A shell for the road looks for a way clear of the decks this far to
  // either side of its mark at most, by this much, not this near an edge
  RoadMarkReach = 64;
  RoadMarkStep = 8;
  RoadMarkMargin = 16.0;
  // A crossing this near a line is on it: the arc is aimed to end on the
  // line exactly, and the sums of its ticks miss it by a hair
  LineSlop = 0.01;

  ShellDark: TRgb = (R: 44; G: 40; B: 38);
  ShellHot: TRgb = (R: 255; G: 120; B: 40);
  ShellHotSize = 12.0;
  ShellHotLevel = 0.75;
  ShellCoreSize = 4.0;
  // A hot point on its rim, turning as it rolls
  RimHotSize = 3.0;

  // The ring: wide as the shell is lobbed, closing to the least as it
  // comes; flat, it lies on what it marks; it throbs
  RingMost = 14.0;
  RingLeast = 6.0;
  RingFlat = 0.35;
  RingWidth = 1.3;
  RingLevel = 0.75;
  RingThrob = 0.25;
  RingThrobTicks = 6;
  RingSegments = 32;
  RingColor: TRgb = (R: 255; G: 72; B: 32);
  RingGlowSize = 10.0;

  ShellTrail: TSmokeLook = (Rate: 40; Life: 0.6; Size: 2; EndSize: 8;
    Opacity: 0.5; Angle: 0; Cone: 360; Speed: 4; Drag: 0.5; Lift: 0;
    Wind: 0; Turbulence: 3; Spin: 40; Flow: sfSteady; Frequency: 1;
    Heat: 0.6; EndTint: (R: 40; G: 38; B: 38));
  ShellTrailTint: TColorTint = (R: 70; G: 64; B: 60);
  ShellTrailSeed = $53686C31; // "Shl1"

  // A deck he stands on lies this near his feet. One he could climb to
  // stands over them, and no higher than a plain jump clears it: the jump
  // peaks about 100 over his feet, and must clear the deck by a few units.
  UnderFeetSlop = 1.0;
  ClimbLeast = 16.0;
  ClimbMost = 92.0;
  RoadAhead = 64.0;

function UnitPoint(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

// The top of a lob of ATicks from AFromY with AClimb: the tick the climb
// is spent, the moon's pull added a tick at a time as the flight does
function ArcTop(AFromY, AClimb: Single; ATicks: Integer): Single;
begin
  Result := AFromY;
  var Y := AFromY;
  var Climb := AClimb;
  for var i := 1 to ATicks do
  begin
    Climb := Climb + ShellGravity;
    Y := Y + Climb;
    if Y < Result then
      Result := Y;
    if Climb >= 0 then
      Break;
  end;
end;

// Where a stretch from AFrom to ATo, going down, first comes down onto a
// deck or the road: the share of the stretch, the point, the deck (-1 the
// road). False when it reaches neither.
function FirstDown(const AFrom, ATo: TSdlFPoint;
  const ADecks: TArray<TShellDeck>; ARoadY: Single; out AShare: Single;
  out AAt: TSdlFPoint; out ADeck: Integer): Boolean;
begin
  Result := False;
  AShare := 2;
  ADeck := -1;
  var Fall := ATo.Y - AFrom.Y;
  if Fall <= 0 then
    Exit;
  for var i := 0 to High(ADecks) do
  begin
    var Top := ADecks[i].Top - ShellRadius;
    if (AFrom.Y > Top) or (ATo.Y < Top - LineSlop) then
      Continue;
    var Share := Min(1.0, (Top - AFrom.Y) / Fall);
    var X := Lerp(AFrom.X, ATo.X, Share);
    if (X < ADecks[i].Left - ShellRadius) or (X > ADecks[i].Right + ShellRadius) or
      (Share >= AShare) then
      Continue;
    AShare := Share;
    AAt := UnitPoint(X, ADecks[i].Top);
    ADeck := i;
    Result := True;
  end;
  var RoadTop := ARoadY - ShellRadius;
  if (AFrom.Y <= RoadTop) and (ATo.Y >= RoadTop - LineSlop) then
  begin
    var Share := Min(1.0, (RoadTop - AFrom.Y) / Fall);
    if Share < AShare then
    begin
      AShare := Share;
      AAt := UnitPoint(Lerp(AFrom.X, ATo.X, Share), ARoadY);
      ADeck := -1;
      Result := True;
    end;
  end;
end;

function DeckMiddle(const ADeck: TShellDeck): TSdlFPoint;
begin
  Result := UnitPoint((ADeck.Left + ADeck.Right) / 2, ADeck.Top);
end;

function SecondShellMark(const ADecks: TArray<TShellDeck>;
  const AFeet: TSdlFPoint; ARoadY: Single): TSdlFPoint;
begin
  for var Deck in ADecks do
    if (Abs(Deck.Top - AFeet.Y) <= UnderFeetSlop) and
      InRange(AFeet.X, Deck.Left, Deck.Right) then
      Exit(DeckMiddle(Deck));

  Result := UnitPoint(Min(AFeet.X + RoadAhead, ScreenWidth), ARoadY);
  var Nearest := MaxSingle;
  for var Deck in ADecks do
  begin
    var Rise := AFeet.Y - Deck.Top;
    var Middle := DeckMiddle(Deck);
    if (Rise < ClimbLeast) or (Rise > ClimbMost) or
      (Middle.X >= ScreenWidth / 2) then
      Continue;
    var Gap := Abs(Middle.X - AFeet.X);
    if Gap >= Nearest then
      Continue;
    Nearest := Gap;
    Result := Middle;
  end;
end;

function AheadShellMark(const ADecks: TArray<TShellDeck>;
  const AFeet: TSdlFPoint; ARoadY: Single): TSdlFPoint;
begin
  Result := UnitPoint(Min(AFeet.X + RoadAhead, ScreenWidth), ARoadY);
  var Nearest := MaxSingle;
  for var Deck in ADecks do
  begin
    var Ahead := Deck.Left - AFeet.X;
    if (Abs(Deck.Top - AFeet.Y) > UnderFeetSlop) or (Ahead <= 0) or
      (Ahead >= Nearest) or (Deck.Left >= ScreenWidth) then
      Continue;
    Nearest := Ahead;
    Result := DeckMiddle(Deck);
  end;
end;

// ---------------------------------------------------------------------------
// TBunkerShells
// ---------------------------------------------------------------------------

constructor TBunkerShells.Create(ARoadY: Single);
begin
  inherited Create;
  FRoadY := ARoadY;
  Clear;
end;

procedure TBunkerShells.Clear;
begin
  for var i := 0 to High(FShells) do
    FShells[i] := Default(TShell);
  FLobs := 0;
end;

// Of the arcs that come down on ATarget in a whole number of ticks, the
// one whose top stands nearest LobRise over the higher end
function TBunkerShells.Lob(const AFrom, ATarget: TSdlFPoint): Boolean;
begin
  var Slot := -1;
  for var i := 0 to High(FShells) do
    if FShells[i].State = ssNone then
    begin
      Slot := i;
      Break;
    end;
  if Slot < 0 then
    Exit(False);

  var Ticks: Integer;
  var Shell := Default(TShell);
  Shell.State := ssFlying;
  Shell.Middle := AFrom;
  Shell.LastMiddle := AFrom;
  Shell.Speed := Aim(AFrom, ATarget, Ticks);
  Shell.Ring := ATarget;
  Shell.RingTicks := Ticks;
  Shell.FlightTicks := Ticks;
  Shell.Turn := FLobs;
  Inc(FLobs);
  FShells[Slot] := Shell;
  Result := True;
end;

// The speed of the arc out of AFrom that comes down on ATarget, and the
// ticks it takes: its middle aimed a radius over the target, so it comes
// down touching it, its top LobRise over the higher end
function TBunkerShells.Aim(const AFrom, ATarget: TSdlFPoint;
  out ATicks: Integer): TSdlFPoint;
begin
  var Wanted := Min(AFrom.Y, ATarget.Y) - LobRise;
  var Drop := ATarget.Y - ShellRadius - AFrom.Y;
  ATicks := LobLeastTicks;
  var Nearest := MaxSingle;
  for var i := LobLeastTicks to LobMostTicks do
  begin
    var Climb := (Drop - ShellGravity * i * (i + 1) / 2) / i;
    var Off := Abs(ArcTop(AFrom.Y, Climb, i) - Wanted);
    if Off < Nearest then
    begin
      Nearest := Off;
      ATicks := i;
    end;
  end;
  Result := UnitPoint((ATarget.X - AFrom.X) / ATicks,
    (Drop - ShellGravity * ATicks * (ATicks + 1) / 2) / ATicks);
end;

// The whole arc onto the road at AX against the decks as they stand
function TBunkerShells.ReachesRoad(const AFrom: TSdlFPoint; AX: Single;
  const ADecks: TArray<TShellDeck>): Boolean;
begin
  var Ticks: Integer;
  var Speed := Aim(AFrom, UnitPoint(AX, FRoadY), Ticks);
  var Point := AFrom;
  for var i := 1 to PredictTicks do
  begin
    Speed.Y := Speed.Y + ShellGravity;
    var Next := UnitPoint(Point.X + Speed.X, Point.Y + Speed.Y);
    var Share: Single;
    var At: TSdlFPoint;
    var Deck: Integer;
    if FirstDown(Point, Next, ADecks, FRoadY, Share, At, Deck) then
      Exit(Deck < 0);
    Point := Next;
  end;
  Result := False;
end;

// The nearest first, to either side by turns, within RoadMarkReach
function TBunkerShells.RoadMark(const AFrom: TSdlFPoint; AX: Single;
  const ADecks: TArray<TShellDeck>): TSdlFPoint;
const
  Sides: array [0..1] of Integer = (-1, 1);
begin
  var Step := 0;
  while Step <= RoadMarkReach do
  begin
    for var Side in Sides do
    begin
      var X := EnsureRange(AX + Side * Step, RoadMarkMargin,
        ScreenWidth - RoadMarkMargin);
      if ReachesRoad(AFrom, X, ADecks) then
        Exit(UnitPoint(X, FRoadY));
    end;
    Inc(Step, RoadMarkStep);
  end;
  Result := UnitPoint(AX, FRoadY);
end;

// The rest of its arc against the decks as they stand: the road carries
// them and the shell alike, so along the road they keep their places
procedure TBunkerShells.Predict(var AShell: TShell;
  const ADecks: TArray<TShellDeck>);
begin
  var Point := AShell.Middle;
  var Fall := AShell.Speed.Y;
  for var i := 1 to PredictTicks do
  begin
    Fall := Fall + ShellGravity;
    var Next := UnitPoint(Point.X + AShell.Speed.X, Point.Y + Fall);
    var Share: Single;
    var At: TSdlFPoint;
    var Deck: Integer;
    if FirstDown(Point, Next, ADecks, FRoadY, Share, At, Deck) then
    begin
      AShell.Ring := At;
      AShell.RingOnDeck := Deck >= 0;
      AShell.RingTicks := i;
      Exit;
    end;
    Point := Next;
  end;
end;

function TBunkerShells.Tick(const ADecks: TArray<TShellDeck>;
  AWay: Single): TShellCue;
begin
  Result := Default(TShellCue);
  for var i := 0 to High(FShells) do
  begin
    var Shell := FShells[i];
    Shell.LastMiddle := Shell.Middle;
    case Shell.State of
      ssFlying:
        begin
          Shell.Speed.Y := Shell.Speed.Y + ShellGravity;
          // Compared along the road: where it was, carried as the decks were
          var From := UnitPoint(Shell.Middle.X + AWay, Shell.Middle.Y);
          Shell.Middle := UnitPoint(From.X + Shell.Speed.X,
            Shell.Middle.Y + Shell.Speed.Y);
          var Share: Single;
          var At: TSdlFPoint;
          var Deck: Integer;
          if FirstDown(From, Shell.Middle, ADecks, FRoadY, Share, At, Deck) then
          begin
            if Deck >= 0 then
            begin
              var Burst: TShellBurst;
              Burst.At := At;
              Burst.Deck := Deck;
              Result.Bursts := Result.Bursts + [Burst];
              Shell.State := ssNone;
            end
            else
            begin
              Shell.State := ssRolling;
              Shell.Middle := UnitPoint(At.X, FRoadY - ShellRadius);
              Shell.RollWay := -1;
              if Shell.Speed.X > 0 then
                Shell.RollWay := 1;
              Result.Landed := True;
            end;
          end
          else if (Shell.Middle.X < -ShellOffMargin) or
            (Shell.Middle.X > ScreenWidth + ShellOffMargin) then
            Shell.State := ssNone
          else
            Predict(Shell, ADecks);
        end;
      ssRolling:
        begin
          Shell.Middle.X := Shell.Middle.X + AWay + Shell.RollWay * RollSpeed;
          Shell.Rolled := Shell.Rolled - Shell.RollWay * RollSpeed;
          if (Shell.Middle.X < -ShellOffMargin) or
            (Shell.Middle.X > ScreenWidth + ShellOffMargin) then
            Shell.State := ssNone;
        end;
    end;
    FShells[i] := Shell;
  end;
end;

function TBunkerShells.Strikes(const ABody: TSdlFRect;
  out AAt: TSdlFPoint): Boolean;
begin
  for var i := 0 to High(FShells) do
  begin
    if FShells[i].State = ssNone then
      Continue;
    var Middle := FShells[i].Middle;
    var NearX := EnsureRange(Middle.X, ABody.X, ABody.X + ABody.W);
    var NearY := EnsureRange(Middle.Y, ABody.Y, ABody.Y + ABody.H);
    if Sqr(Middle.X - NearX) + Sqr(Middle.Y - NearY) > Sqr(ShellRadius) then
      Continue;
    FShells[i].State := ssNone;
    AAt := Middle;
    Exit(True);
  end;
  Result := False;
end;

function TBunkerShells.Active: Integer;
begin
  Result := 0;
  for var Shell in FShells do
    if Shell.State <> ssNone then
      Inc(Result);
end;

function TBunkerShells.GetShell(AIndex: Integer): TShell;
begin
  Result := FShells[AIndex];
end;

function TBunkerShells.MiddleAt(AIndex: Integer; AAlpha: Single): TSdlFPoint;
begin
  var Shell := FShells[AIndex];
  Result := UnitPoint(Lerp(Shell.LastMiddle.X, Shell.Middle.X, AAlpha),
    Lerp(Shell.LastMiddle.Y, Shell.Middle.Y, AAlpha));
end;

// ---------------------------------------------------------------------------
// TShellPainter
// ---------------------------------------------------------------------------

constructor TShellPainter.Create(AShells: TBunkerShells);
begin
  inherited Create;
  FShells := AShells;
  var Placement := Default(TDynamicPlacement);
  Placement.Tint := ShellTrailTint;
  for var i := 0 to High(FTrails) do
  begin
    FTrails[i] := TSmoke.CreateLook(Placement, ShellTrail, 1,
      ShellTrailSeed xor Cardinal(i + 1));
    FTurns[i] := -1;
  end;
end;

destructor TShellPainter.Destroy;
begin
  for var Trail in FTrails do
    Trail.Free;
  inherited;
end;

// A new shell in a slot: its trail starts where it is, and what the last
// one left burns out where it was
procedure TShellPainter.Tick(AWay: Single);
begin
  Inc(FAge);
  for var i := 0 to High(FTrails) do
  begin
    var Shell := FShells[i];
    var Live := Shell.State <> ssNone;
    if Live and (FTurns[i] <> Shell.Turn) then
    begin
      FTurns[i] := Shell.Turn;
      FTrails[i].ForgetOrigin;
    end;
    FTrails[i].Drift(AWay, 0);
    FTrails[i].Tick(Shell.Middle.X, Shell.Middle.Y, Live);
  end;
end;

// A flat ring of triangles, closing as the shell comes, throbbing
procedure TShellPainter.DrawRing(const ACanvas: TDynamicCanvas;
  const AShell: TShell; AOrigin: TSdlPoint);
var
  Vertices: array [0..2 * RingSegments + 1] of TSdlVertex;
  Indices: array [0..6 * RingSegments - 1] of Integer;
begin
  var Coming := EnsureRange(AShell.RingTicks / Max(1, AShell.FlightTicks), 0, 1);
  var Radius := Lerp(RingLeast, RingMost, Coming);
  var Throb := 1 - RingThrob + RingThrob * Sin(2 * Pi * FAge / RingThrobTicks);
  var CenterX := AShell.Ring.X + AOrigin.X;
  var CenterY := AShell.Ring.Y + AOrigin.Y;
  var Color := Default(TSdlColor);
  Color.R := RingColor.R;
  Color.G := RingColor.G;
  Color.B := RingColor.B;
  Color.A := Round(255 * RingLevel * Throb);
  var Inner := Max(0, Radius - RingWidth);
  for var i := 0 to RingSegments do
  begin
    var Angle := 2 * Pi * i / RingSegments;
    Vertices[2 * i].Position := UnitPoint(CenterX + Radius * Cos(Angle),
      CenterY + Radius * RingFlat * Sin(Angle));
    Vertices[2 * i + 1].Position := UnitPoint(CenterX + Inner * Cos(Angle),
      CenterY + Inner * RingFlat * Sin(Angle));
    Vertices[2 * i].Color := Color;
    Vertices[2 * i + 1].Color := Color;
  end;
  for var i := 0 to RingSegments - 1 do
  begin
    Indices[6 * i] := 2 * i;
    Indices[6 * i + 1] := 2 * i + 1;
    Indices[6 * i + 2] := 2 * i + 2;
    Indices[6 * i + 3] := 2 * i + 1;
    Indices[6 * i + 4] := 2 * i + 3;
    Indices[6 * i + 5] := 2 * i + 2;
  end;
  SDL_SetRenderDrawBlendMode(ACanvas.Renderer, SdlBlendModeBlend);
  SDL_RenderGeometry(ACanvas.Renderer, nil, @Vertices[0], Length(Vertices),
    @Indices[0], Length(Indices));
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    RingGlowSize, RingColor, RingLevel * Throb * (1 - Coming));
end;

procedure TShellPainter.DrawRings(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var i := 0 to ShellSlots - 1 do
    if FShells[i].State = ssFlying then
      DrawRing(ACanvas, FShells[i], AOrigin);
end;

procedure TShellPainter.DrawShells(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Trail in FTrails do
    Trail.Draw(ACanvas, Trail.Origin.X + AOrigin.X, Trail.Origin.Y + AOrigin.Y,
      AAlpha);
  for var i := 0 to ShellSlots - 1 do
  begin
    var Shell := FShells[i];
    if Shell.State = ssNone then
      Continue;
    var Middle := FShells.MiddleAt(i, AAlpha);
    var X := Middle.X + AOrigin.X;
    var Y := Middle.Y + AOrigin.Y;
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X, Y, ShellHotSize, ShellHot,
      ShellHotLevel);
    DrawGlowTurned(ACanvas.Renderer, ACanvas.DiscShade, X, Y, 2 * ShellRadius,
      2 * ShellRadius, 0, ShellDark, 1);
    if Shell.State = ssRolling then
    begin
      var Turn := Shell.Rolled / ShellRadius;
      DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X - ShellRadius * Cos(Turn),
        Y - ShellRadius * Sin(Turn), RimHotSize, ShellHot, 1);
    end
    else
      DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X, Y, ShellCoreSize, White, 1);
  end;
end;

end.
