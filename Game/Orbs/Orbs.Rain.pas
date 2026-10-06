{
  Orbs.Rain - the fire rain: a veil of orbs poured down the hero's screen,
  wave after wave over its whole width. Each orb flies by a formula of the
  time since its birth, with nothing carried from tick to tick; it falls
  through roofs and platforms alike and is taken back by the floor of its
  column - the top of the matter that reaches the bottom of the screen -
  or, over a pit, leaves the screen. All the way down it is armed.

  Where the orbs are and when they are gone, nothing more: what an orb
  strikes is the game's to settle, through the flock.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Rain;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics,
  Orbs.Flock, Orbs.Harvest;

type
  TRainStage = (rsFalling, rsSinking);

  // What a drop is born of: its formula needs nothing else
  TDropSeed = record
    StartX: Single;
    Birth: Integer; // the rain's tick
    Sway: Single; // where in its sway it begins, radians
    Floor: Single; // where the matter of its column takes it back
  end;

  TRainDrop = class(TOrb)
  private
    FSeed: TDropSeed;
    FStage: TRainStage;
    FSunkTicks: Integer;
  end;

  TOrbRain = class
  private
    FFlock: TOrbFlock;
    FPending: TList<TDropSeed>;
    FTick: Integer;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function NewSeed(AWave, AColumn: Integer;
      const ACells: TSolidCells): TDropSeed;
    procedure BringBirths;
    procedure Fall(const ADrop: TRainDrop);
    procedure Land(const ADrop: TRainDrop);
    procedure Sink(const ADrop: TRainDrop);
  public
    constructor Create(const ATint: TOrbTint);
    destructor Destroy; override;
    // A rain over the matter of the hero's screen, added to the one
    // already falling. Only its cells make a floor: a drop falls through
    // a pad as it does through a roof.
    procedure Pour(const AMatter: TMatter);
    procedure Tick;
    // The hero is dead: the drops not yet born never are, the rest draw
    // into their points
    procedure Collapse;
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure Clear;
    // What the drops strike is the game's to settle
    property Flock: TOrbFlock read FFlock;
  end;

implementation

uses
  Game.Space, Render.Sprites;

const
  // A drop to every DropColumnWidth units of the screen's width, in
  // WaveCount waves. The stand's veil has five; in play five could not kill
  // a monster of ten lives (a body is one column wide), so there are three
  // times as many, close enough that the rain lasts as long as before.
  WaveCount = 15;
  DropColumnWidth = 16;
  DropColumns = ScreenWidth div DropColumnWidth;
  // A wave follows the one before it by this many ticks; each drop of it
  // is born up to BirthSpreadTicks later
  WaveGapTicks = 4;
  BirthSpreadTicks = 9;
  // A drop stands off the middle of its column by up to half of this
  ColumnScatter = 6;

  // A drop's flight, in units and ticks since its birth: it starts above
  // the screen, falls at an even speed and sways
  FallStartY = -10;
  FallSpeed = 5;
  SwayReach = 2.5;
  SwayPace = 0.16; // radians a tick

  // The floor takes a drop back: it fades and shrinks while it goes on
  // falling into the matter
  FloorSinkTicks = 6;
  FloorShrinkTicks = 9;
  // A drop over a pit is gone this far below the screen's bottom edge
  LeaveMargin = 20;
  // The floor of a column over a pit: none, its drops fall out of the
  // screen
  NoFloor = 1.0E9;

  DiceSeed = $5261696E; // "Rain"

// Where the rain of a column of cells ends: the top of the matter that
// reaches the bottom of the screen
function FloorOfColumn(const ACells: TSolidCells; AColumn: Integer): Single;
begin
  var Row := ScreenRows;
  while (Row > 0) and ACells[Row - 1, AColumn] do
    Dec(Row);
  if Row = ScreenRows then
    Exit(NoFloor);
  Result := Row * TileSize;
end;

function PlaceAt(const ASeed: TDropSeed; AAge: Integer): TSdlFPoint;
begin
  Result.X := ASeed.StartX + SwayReach * Sin(SwayPace * AAge + ASeed.Sway);
  Result.Y := FallStartY + FallSpeed * AAge;
end;

// ---------------------------------------------------------------------------
// TOrbRain
// ---------------------------------------------------------------------------

constructor TOrbRain.Create(const ATint: TOrbTint);
begin
  inherited Create;
  FFlock := TOrbFlock.Create(ATint);
  FPending := TList<TDropSeed>.Create;
  FRandom.Seed := DiceSeed;
end;

destructor TOrbRain.Destroy;
begin
  FPending.Free;
  FFlock.Free;
  inherited;
end;

function TOrbRain.NewSeed(AWave, AColumn: Integer;
  const ACells: TSolidCells): TDropSeed;
begin
  Result.StartX := (AColumn + 0.5) * DropColumnWidth +
    (FRandom.NextUnit - 0.5) * ColumnScatter;
  Result.Birth := FTick + AWave * WaveGapTicks +
    Trunc(FRandom.NextUnit * BirthSpreadTicks);
  Result.Sway := FRandom.NextUnit * 2 * Pi;
  Result.Floor := FloorOfColumn(ACells, Trunc(Result.StartX / TileSize));
end;

procedure TOrbRain.Pour(const AMatter: TMatter);
begin
  for var Wave := 0 to WaveCount - 1 do
    for var Column := 0 to DropColumns - 1 do
      FPending.Add(NewSeed(Wave, Column, AMatter.Cells));
end;

// The drops that are due are born where their formula puts them: an orb
// made elsewhere and moved here would be drawn on ahead by the whole way
procedure TOrbRain.BringBirths;
begin
  for var i := FPending.Count - 1 downto 0 do
  begin
    var Seed := FPending[i];
    if Seed.Birth > FTick then
      Continue;
    var Place := PlaceAt(Seed, FTick - Seed.Birth);
    var Drop := TRainDrop.Create(Place.X, Place.Y);
    Drop.FSeed := Seed;
    FFlock.Add(Drop);
    FPending.Delete(i);
  end;
end;

procedure TOrbRain.Fall(const ADrop: TRainDrop);
begin
  var Place := PlaceAt(ADrop.FSeed, FTick - ADrop.FSeed.Birth);
  ADrop.MoveTo(Place.X, Place.Y);

  if Place.Y > ScreenHeight + LeaveMargin then
    FFlock.Release(ADrop)
  else if ADrop.FStage = rsSinking then
    Sink(ADrop)
  else if Place.Y >= ADrop.FSeed.Floor then
    Land(ADrop);
end;

procedure TOrbRain.Land(const ADrop: TRainDrop);
begin
  ADrop.FStage := rsSinking;
  ADrop.FSunkTicks := 0;
  ADrop.Armed := False;
  FFlock.MarkFace(ADrop.X, ADrop.FSeed.Floor, 0, -1);
end;

procedure TOrbRain.Sink(const ADrop: TRainDrop);
begin
  Inc(ADrop.FSunkTicks);
  if ADrop.FSunkTicks >= FloorSinkTicks then
  begin
    FFlock.Release(ADrop);
    Exit;
  end;
  ADrop.Level := 1 - ADrop.FSunkTicks / FloorSinkTicks;
  ADrop.Size := 1 - ADrop.FSunkTicks / FloorShrinkTicks;
end;

procedure TOrbRain.Tick;
begin
  FFlock.Tick;
  Inc(FTick);
  BringBirths;
  for var Orb in FFlock.Orbs do
    if Orb.State = osAlive then
      Fall(Orb as TRainDrop);
end;

procedure TOrbRain.Collapse;
begin
  FPending.Clear;
  for var Orb in FFlock.Orbs do
    FFlock.Implode(Orb);
end;

procedure TOrbRain.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FFlock.Draw(ACanvas, AOrigin, AAlpha);
end;

procedure TOrbRain.Clear;
begin
  FFlock.Clear;
  FPending.Clear;
  FTick := 0;
end;

end.
