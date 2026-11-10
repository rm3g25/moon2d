{
  Game.Flock - the small barges of the Ram's air fight, flying round the
  main barge (Game.Barge) once the fight is on. A few fly at once, each on
  a path of its own, none minding the others or the hero.

  One of them is always the escort: it hangs over the main barge, a jump
  above its deck, swaying along it, so a small barge is within the moon
  form's jump of the main one at all times. After a while of that the next
  barge to come in comes as its relief; once the relief is in its place
  the old escort is let go and drifts off left like any other.

  The rest fly free, at the lanes between the Ram's belly and the escort:
  a drift along a lane with a slow swell, a few loops in place before
  drifting off, a slow climb or descent across the screen, or a pass right
  through. Every barge comes in from beyond the right edge fast and brakes
  to its path's pace - the one place the flight's speed is felt in play;
  every one leaves past the left edge, and a new one comes in after a
  short gap. How many fly is the caller's, once, at the start.

  The Ram's magnet takes barges out of the flock: a taken one flies no
  more and is the caller's till it is given back to the pool; another
  comes in for it as for one gone - at once when it was the escort.

  The barges are a pool the caller names by their widths, in its order:
  the flock tells which of them flies, where and how far it went this
  tick, and the caller moves its pads by that - the riders go with them as
  on any pad. It does not know the pads, the hero or the Ram. No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Flock;
{$I ..\Moon2D.inc}

interface

uses
  Render.Brush;

const
  // How many small barges fly at once, by the tier of the air fight
  FlockCounts: array [1..4] of Integer = (2, 3, 3, 4);
  // A barge comes in this fast, its left edge from just beyond the right
  // edge, and brakes to its path's pace
  EnterPace = 7.0;
  EnterGap = 8.0;
  // A barge gone is replaced after 1-2 s
  ReplaceGapLeast = 33;
  ReplaceGapMost = 66;
  // The decks of the free barges: under these the head of a hero standing
  // on one stays clear of the Ram's belly, over them the escort flies
  LaneHighest = 208;
  LaneLowest = 248;
  LanesApart = 20;
  // The escort: its deck this far over the main barge's, its middle
  // swaying this far either side of the main barge's middle
  EscortRise = 64.0;
  EscortSway = 64.0;
  // Within the moon form's jump, with room to spare: a deck no farther up
  // or down from the main barge's, and no farther across, edge to edge
  NeighbourRise = 80.0;
  NeighbourGap = 64.0;

type
  // fpEscort - over the main barge; the rest fly free: fpLane - along a
  // lane with a swell; fpLoop - loops in place, then drifts off; fpClimb -
  // up or down across the screen; fpPass - right through
  TFlockPath = (fpEscort, fpLane, fpLoop, fpClimb, fpPass);

  // Where the main barge is this tick
  TMainBarge = record
    Left: Double;
    Top: Double; // its deck
    Width: Double;
  end;

  TBargeFlock = class
  private type
    TFlyer = record
      Flying: Boolean;
      // Taken out of the flock and not yet given back to the pool
      Taken: Boolean;
      Path: TFlockPath;
      // Ticks since it came in
      Clock: Integer;
      Left, Top: Double;
      LastLeft, LastTop: Double;
      // The path's own numbers: where across it starts, its deck and the
      // deck a climb ends at, its pace left, the phase of an escort's sway,
      // the ticks a loop loops in place
      FromX: Double;
      Deck: Double;
      ToDeck: Double;
      Pace: Double;
      Phase: Double;
      LoopInPlace: Integer;
      // The way in: how far right of its path it came in, over how long
      ComeFromX: Double;
      ComeTicks: Integer;
    end;
  private
    FWidths: TArray<Double>;
    FFlyers: TArray<TFlyer>;
    FDice: TXorShift;
    // How many fly at once; 0 - the flock has not started
    FCount: Integer;
    // Ticks before the next may come in
    FWait: Integer;
    // The escort and its relief on the way, -1 when none
    FEscort: Integer;
    FRelief: Integer;
    // Ticks the escort has served, and how long it serves before a
    // relief is sent
    FServed: Integer;
    FServe: Integer;
    function RollRange(ALeast, AMost: Double): Double;
    function RollFreeIndex: Integer;
    function RollPath: TFlockPath;
    function RollLaneDeck(AHighest, ALowest: Double): Double;
    procedure SendIn(AIndex: Integer; APath: TFlockPath;
      const AMain: TMainBarge);
    procedure PlanPath(var AFlyer: TFlyer);
    procedure PathPlace(const AFlyer: TFlyer; AIndex: Integer;
      const AMain: TMainBarge; out AX, AY: Double);
    procedure Place(AIndex: Integer; const AMain: TMainBarge);
    procedure LetGo(AIndex: Integer);
    procedure HandOver(const AMain: TMainBarge);
    procedure Fly(const AMain: TMainBarge);
    procedure SendWhenDue(const AMain: TMainBarge);
    function Arrived(AIndex: Integer): Boolean;
  public
    // AWidths - the widths of the pool's barges, in the caller's order;
    // ASeed - the dice of the paths
    constructor Create(const AWidths: TArray<Double>; ASeed: Cardinal);
    // A death, a door, a new level: none flies, the flock not started, the
    // dice new for the new try
    procedure Clear(ASeed: Cardinal);
    // The fight is on: from now on ACount fly, the escort first, at once.
    // Nothing once started, till a clear.
    procedure Start(ACount: Integer);
    // A step: the barges fly their paths, the main barge where AMain says;
    // those wholly past the left edge are gone, a new one comes in when
    // its gap is out
    procedure Tick(const AMain: TMainBarge);
    function Started: Boolean;
    // How many of the pool fly now
    function FlyingCount: Integer;
    function Flying(AIndex: Integer): Boolean;
    function Left(AIndex: Integer): Double;
    function Top(AIndex: Integer): Double;
    function Width(AIndex: Integer): Double;
    // How far it went this tick, across and down; below 0 left and up
    function WayX(AIndex: Integer): Double;
    function WayY(AIndex: Integer): Double;
    function PathOf(AIndex: Integer): TFlockPath;
    function PoolSize: Integer;
    // The barge AIndex is taken out of the flock where it flies: the
    // caller's from now on, another comes in for it - at once when it was
    // the escort, whose relief, if one is on its way, is the escort from
    // then. Nothing for one that does not fly.
    procedure Take(AIndex: Integer);
    // Taken and not yet given back
    function Taken(AIndex: Integer): Boolean;
    // The taken barge AIndex is the pool's again, to come in anew
    procedure GiveBack(AIndex: Integer);
    // The escort's index in the pool, -1 when none flies
    property Escort: Integer read FEscort;
  end;

// A deck ALeft..ALeft + AWidth at ATop is within the moon form's jump of
// the main barge's, with room to spare
function WithinJump(const AMain: TMainBarge; ALeft, ATop,
  AWidth: Double): Boolean;

implementation

uses
  System.Math, Game.Space;

const
  // The escort swings along the main barge once in 7 s, and rises and
  // sinks a little once in 3 s; it serves 10-15 s before a relief is sent
  EscortSwayTicks = 231;
  EscortSwell = 4.0;
  EscortSwellTicks = 99;
  ServeLeast = 330;
  ServeMost = 495;
  // A lane: its pace and its swell
  LanePaceLeast = 1.0;
  LanePaceMost = 1.4;
  LaneSwell = 6.0;
  LaneSwellTicks = 132;
  // A loop: this wide and this deep, a lap in 4 s, two or three laps in
  // place before it drifts off at a lane's pace
  LoopReachX = 48.0;
  LoopReachY = 16.0;
  LoopTicks = 132;
  LoopLapsLeast = 2;
  LoopLapsMost = 3;
  // A climb crosses the screen at this pace, from one end of the lanes to
  // the other
  ClimbPace = 1.1;
  // A pass goes right through at this pace
  PassPace = 2.6;
  // The shares of the free paths, in the order of TFlockPath from fpLane
  LaneShare = 0.35;
  LoopShare = 0.25;
  ClimbShare = 0.25;
  // Where across a free path starts, as shares of the screen: the left
  // edge of a lane, a climb and a pass, the middle of a loop
  LaneFromLeast = 0.45;
  LaneFromMost = 0.75;
  LoopFromLeast = 0.4;
  LoopFromMost = 0.7;
  ClimbFrom = 0.7;
  PassFrom = 0.6;
  // Tries for a lane clear of the others' decks
  LaneTries = 8;
  NoBarge = -1;

function SmoothStep(AShare: Double): Double;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

function WithinJump(const AMain: TMainBarge; ALeft, ATop,
  AWidth: Double): Boolean;
begin
  var Rise := Abs(AMain.Top - ATop);
  var GapRight := ALeft - (AMain.Left + AMain.Width);
  var GapLeft := AMain.Left - (ALeft + AWidth);
  var Gap := Max(0.0, Max(GapRight, GapLeft));
  Result := (Rise <= NeighbourRise) and (Gap <= NeighbourGap);
end;

constructor TBargeFlock.Create(const AWidths: TArray<Double>; ASeed: Cardinal);
begin
  inherited Create;
  FWidths := Copy(AWidths);
  SetLength(FFlyers, Length(FWidths));
  Clear(ASeed);
end;

procedure TBargeFlock.Clear(ASeed: Cardinal);
begin
  for var i := 0 to High(FFlyers) do
    FFlyers[i] := Default(TFlyer);
  FCount := 0;
  FWait := 0;
  FEscort := NoBarge;
  FRelief := NoBarge;
  FServed := 0;
  FServe := 0;
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;
end;

procedure TBargeFlock.Start(ACount: Integer);
begin
  if FCount > 0 then
    Exit;
  FCount := Max(ACount, 0);
  FWait := 0;
end;

function TBargeFlock.Started: Boolean;
begin
  Result := FCount > 0;
end;

function TBargeFlock.RollRange(ALeast, AMost: Double): Double;
begin
  Result := ALeast + (AMost - ALeast) * FDice.NextUnit;
end;

// One of the pool neither flying nor taken, as the dice pick it; NoBarge
// when there is none
function TBargeFlock.RollFreeIndex: Integer;
begin
  var Idle: TArray<Integer> := [];
  for var i := 0 to High(FFlyers) do
    if not FFlyers[i].Flying and not FFlyers[i].Taken then
      Idle := Idle + [i];
  if Length(Idle) = 0 then
    Exit(NoBarge);
  Result := Idle[Min(Trunc(FDice.NextUnit * Length(Idle)), High(Idle))];
end;

function TBargeFlock.RollPath: TFlockPath;
begin
  var Roll := FDice.NextUnit;
  if Roll < LaneShare then
    Exit(fpLane);
  if Roll < LaneShare + LoopShare then
    Exit(fpLoop);
  if Roll < LaneShare + LoopShare + ClimbShare then
    Exit(fpClimb);
  Result := fpPass;
end;

// A deck between the two clear of the other free barges' by LanesApart;
// the last try when none is
function TBargeFlock.RollLaneDeck(AHighest, ALowest: Double): Double;
begin
  Result := AHighest;
  for var i := 1 to LaneTries do
  begin
    Result := Round(RollRange(AHighest, ALowest));
    var Apart := True;
    for var Other in FFlyers do
      if Other.Flying and (Other.Path <> fpEscort) and
        (Abs(Other.Top - Result) < LanesApart) then
        Apart := False;
    if Apart then
      Exit;
  end;
end;

// The numbers of a free path: where it starts, its decks, its pace
procedure TBargeFlock.PlanPath(var AFlyer: TBargeFlock.TFlyer);
begin
  case AFlyer.Path of
    fpLane:
      begin
        AFlyer.FromX := ScreenWidth * RollRange(LaneFromLeast, LaneFromMost);
        AFlyer.Deck := RollLaneDeck(LaneHighest, LaneLowest);
        AFlyer.Pace := RollRange(LanePaceLeast, LanePaceMost);
      end;
    fpLoop:
      begin
        AFlyer.FromX := ScreenWidth * RollRange(LoopFromLeast, LoopFromMost);
        AFlyer.Deck := RollLaneDeck(LaneHighest, LaneLowest - 2 * LoopReachY);
        AFlyer.Pace := RollRange(LanePaceLeast, LanePaceMost);
        AFlyer.LoopInPlace := Round(RollRange(LoopLapsLeast, LoopLapsMost)) *
          LoopTicks;
      end;
    fpClimb:
      begin
        AFlyer.FromX := ScreenWidth * ClimbFrom;
        AFlyer.Deck := LaneLowest;
        AFlyer.ToDeck := LaneHighest;
        if FDice.NextUnit < 0.5 then
        begin
          AFlyer.Deck := LaneHighest;
          AFlyer.ToDeck := LaneLowest;
        end;
        AFlyer.Pace := ClimbPace;
      end;
    fpPass:
      begin
        AFlyer.FromX := ScreenWidth * PassFrom;
        AFlyer.Deck := RollLaneDeck(LaneHighest, LaneLowest);
        AFlyer.Pace := PassPace;
      end;
  end;
end;

// Where the path puts the barge's top-left corner, the way in left out
procedure TBargeFlock.PathPlace(const AFlyer: TBargeFlock.TFlyer;
  AIndex: Integer;
  const AMain: TMainBarge; out AX, AY: Double);
begin
  var BargeWidth := FWidths[AIndex];
  var Time: Double := AFlyer.Clock;
  case AFlyer.Path of
    fpEscort:
      begin
        var Sway := Sin(2 * Pi * Time / EscortSwayTicks + AFlyer.Phase);
        var Middle := AMain.Left + AMain.Width / 2 + EscortSway * Sway;
        AX := EnsureRange(Middle - BargeWidth / 2, 0.0, ScreenWidth - BargeWidth);
        AY := AMain.Top - EscortRise +
          EscortSwell * Sin(2 * Pi * Time / EscortSwellTicks);
      end;
    fpLane:
      begin
        AX := AFlyer.FromX - AFlyer.Pace * Time;
        AY := AFlyer.Deck + LaneSwell * Sin(2 * Pi * Time / LaneSwellTicks);
      end;
    fpLoop:
      begin
        var Drifted := Max(0.0, Time - AFlyer.LoopInPlace);
        var Middle := AFlyer.FromX - AFlyer.Pace * Drifted;
        var Turn := 2 * Pi * Time / LoopTicks;
        AX := Middle + LoopReachX * Sin(Turn) - BargeWidth / 2;
        AY := AFlyer.Deck + LoopReachY * (1 - Cos(Turn));
      end;
    fpClimb:
      begin
        AX := AFlyer.FromX - AFlyer.Pace * Time;
        var CrossTicks := (AFlyer.FromX + BargeWidth) / AFlyer.Pace;
        AY := AFlyer.Deck + (AFlyer.ToDeck - AFlyer.Deck) *
          SmoothStep(Time / CrossTicks);
      end;
    fpPass:
      begin
        AX := AFlyer.FromX - AFlyer.Pace * Time;
        AY := AFlyer.Deck;
      end;
  end;
end;

// The way in eases out as a square: it comes in at EnterPace and is on
// its path at the path's own pace
procedure TBargeFlock.Place(AIndex: Integer; const AMain: TMainBarge);
var
  X, Y: Double;
begin
  PathPlace(FFlyers[AIndex], AIndex, AMain, X, Y);
  var Flyer := FFlyers[AIndex];
  var ComeShare: Double := 0;
  if Flyer.Clock < Flyer.ComeTicks then
    ComeShare := Sqr(1 - Flyer.Clock / Flyer.ComeTicks);
  FFlyers[AIndex].Left := X + Flyer.ComeFromX * ComeShare;
  FFlyers[AIndex].Top := Y;
end;

procedure TBargeFlock.SendIn(AIndex: Integer; APath: TFlockPath;
  const AMain: TMainBarge);
var
  X, Y: Double;
begin
  var Flyer := Default(TFlyer);
  Flyer.Flying := True;
  Flyer.Path := APath;
  if APath = fpEscort then
    Flyer.Phase := RollRange(0, 2 * Pi)
  else
    PlanPath(Flyer);
  PathPlace(Flyer, AIndex, AMain, X, Y);
  Flyer.ComeFromX := Max(0.0, ScreenWidth + EnterGap - X);
  var Braking := Max(EnterPace - Flyer.Pace, 1.0);
  Flyer.ComeTicks := Ceil(2 * Flyer.ComeFromX / Braking);
  FFlyers[AIndex] := Flyer;
  Place(AIndex, AMain);
  FFlyers[AIndex].LastLeft := FFlyers[AIndex].Left;
  FFlyers[AIndex].LastTop := FFlyers[AIndex].Top;
end;

function TBargeFlock.Arrived(AIndex: Integer): Boolean;
begin
  Result := FFlyers[AIndex].Clock >= FFlyers[AIndex].ComeTicks;
end;

// The old escort goes on from where it is along a lane at its deck, off
// to the left
procedure TBargeFlock.LetGo(AIndex: Integer);
begin
  var Flyer := FFlyers[AIndex];
  Flyer.Path := fpLane;
  Flyer.Clock := 0;
  Flyer.ComeTicks := 0;
  Flyer.ComeFromX := 0;
  Flyer.FromX := Flyer.Left;
  Flyer.Deck := Flyer.Top;
  Flyer.Pace := RollRange(LanePaceLeast, LanePaceMost);
  FFlyers[AIndex] := Flyer;
end;

// The relief in its place and within the jump: it is the escort now
procedure TBargeFlock.HandOver(const AMain: TMainBarge);
begin
  if (FRelief = NoBarge) or not Arrived(FRelief) then
    Exit;
  var Relief := FFlyers[FRelief];
  if not WithinJump(AMain, Relief.Left, Relief.Top, FWidths[FRelief]) then
    Exit;
  LetGo(FEscort);
  FEscort := FRelief;
  FRelief := NoBarge;
  FServed := 0;
  FServe := Round(RollRange(ServeLeast, ServeMost));
end;

// Every barge flying a tick of its path; gone once wholly past the left
// edge
procedure TBargeFlock.Fly(const AMain: TMainBarge);
begin
  for var i := 0 to High(FFlyers) do
  begin
    if not FFlyers[i].Flying then
      Continue;
    FFlyers[i].LastLeft := FFlyers[i].Left;
    FFlyers[i].LastTop := FFlyers[i].Top;
    Inc(FFlyers[i].Clock);
    Place(i, AMain);
    var Right := FFlyers[i].Left + FWidths[i];
    if Right < 0 then
      FFlyers[i].Flying := False;
  end;
end;

// Short of the count and the gap out: one of the pool comes in - the
// escort when there is none, its relief when it has served its while,
// else a free one
procedure TBargeFlock.SendWhenDue(const AMain: TMainBarge);
begin
  if FlyingCount >= FCount then
    Exit;
  if FWait > 0 then
  begin
    Dec(FWait);
    Exit;
  end;
  var Index := RollFreeIndex;
  if Index = NoBarge then
    Exit;
  var Path := RollPath;
  var WantsRelief := (FEscort <> NoBarge) and (FRelief = NoBarge) and
    (FServed >= FServe);
  if FEscort = NoBarge then
  begin
    Path := fpEscort;
    FEscort := Index;
    FServed := 0;
    FServe := Round(RollRange(ServeLeast, ServeMost));
  end
  else if WantsRelief then
  begin
    Path := fpEscort;
    FRelief := Index;
  end;
  SendIn(Index, Path, AMain);
  FWait := Round(RollRange(ReplaceGapLeast, ReplaceGapMost));
end;

procedure TBargeFlock.Tick(const AMain: TMainBarge);
begin
  if not Started then
    Exit;
  Fly(AMain);
  HandOver(AMain);
  if FEscort <> NoBarge then
    Inc(FServed);
  SendWhenDue(AMain);
end;

function TBargeFlock.FlyingCount: Integer;
begin
  Result := 0;
  for var Flyer in FFlyers do
    if Flyer.Flying then
      Inc(Result);
end;

function TBargeFlock.Flying(AIndex: Integer): Boolean;
begin
  Result := FFlyers[AIndex].Flying;
end;

function TBargeFlock.Left(AIndex: Integer): Double;
begin
  Result := FFlyers[AIndex].Left;
end;

function TBargeFlock.Top(AIndex: Integer): Double;
begin
  Result := FFlyers[AIndex].Top;
end;

function TBargeFlock.Width(AIndex: Integer): Double;
begin
  Result := FWidths[AIndex];
end;

function TBargeFlock.WayX(AIndex: Integer): Double;
begin
  Result := FFlyers[AIndex].Left - FFlyers[AIndex].LastLeft;
end;

function TBargeFlock.WayY(AIndex: Integer): Double;
begin
  Result := FFlyers[AIndex].Top - FFlyers[AIndex].LastTop;
end;

function TBargeFlock.PathOf(AIndex: Integer): TFlockPath;
begin
  Result := FFlyers[AIndex].Path;
end;

function TBargeFlock.PoolSize: Integer;
begin
  Result := Length(FWidths);
end;

procedure TBargeFlock.Take(AIndex: Integer);
begin
  if not FFlyers[AIndex].Flying then
    Exit;
  FFlyers[AIndex].Flying := False;
  FFlyers[AIndex].Taken := True;
  if AIndex = FRelief then
    FRelief := NoBarge;
  if AIndex <> FEscort then
    Exit;
  FEscort := FRelief;
  FRelief := NoBarge;
  FServed := 0;
  FServe := Round(RollRange(ServeLeast, ServeMost));
  if FEscort = NoBarge then
    FWait := 0;
end;

function TBargeFlock.Taken(AIndex: Integer): Boolean;
begin
  Result := FFlyers[AIndex].Taken;
end;

procedure TBargeFlock.GiveBack(AIndex: Integer);
begin
  FFlyers[AIndex].Taken := False;
end;

end.
