{
  Game.Uptake - the hero takes a pickup in: the picture stays where it lay,
  fills with color, crumbles, and the crumbs fly into his body, each one
  lighting the point it enters. A pickup that is destroyed instead is
  filled and crumbled the same way, but its crumbs fall and seek no one.

  Two classes, two reasons to change:
  - TUptake counts: the scenes, the crumbs, the spots of light on the body,
    the clock. It touches no SDL and owns no resources.
  - TUptakePainter draws, and keeps what is made of the pickups' pictures
    at load: the frame, the silhouette, the light of a cross. It also draws
    the light of the pickups that lie.

  What differs between a medkit, a weapon and a wreck is numbers only - a
  TUptakeLook; the game says which one to start and when. Nothing here
  takes the controls from the hero.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Uptake;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.Generics.Collections, Sdl2.Core, Render.Brush,
  Render.Silhouette, Effects.Sparks, Levels.Dynamics, Hero, Monsters;

const
  // How long the spot a crumb leaves on the body lives
  SpotTicks = 6;

type
  EUptakeError = class(Exception);

  TUptakeOrder = (uoScattered, uoTopDown, uoNearFirst);

  // Ticks, screen units and shares
  TUptakeLook = record
    Fill: Integer; // the picture takes the color
    Crumble: Integer; // the crumbs leave, from the first to the last
    Order: TUptakeOrder;
    Crumb: Single; // the side of a crumb
    Flash: Single; // the halo of the filled picture
    Apart: Boolean; // the crumbs fall and seek no one
    Scatter: Single; // a crumb's speed as it leaves, units a tick
    Burst: Integer; // ticks it flies free before the pull
    Pull: Single; // toward the hero, units a tick per tick
    Pulse: Single; // the light the whole picture gives the body
    PulseTicks: Integer; // the light is all but gone in this many
    Tint: TRgb;
  end;

  // A picture's alpha and its size on the screen
  TUptakeShape = record
    Alpha: TArray<Byte>; // row by row
    TexW, TexH: Integer;
    Width, Height: Single; // units
  end;

  TCrumbCell = record
    Source: TSdlRect; // texels
    X, Y, W, H: Single; // units from the picture's corner
    MidX, MidY: Single; // the middle of what is painted in it
    Cover: Single; // the share of it that is painted
  end;

  TCrumbState = (csSitting, csFlying, csGone);

  TCrumb = record
    Cell: TCrumbCell;
    LeaveAt: Single; // the scene's age it leaves at
    State: TCrumbState;
    X, Y, SpeedX, SpeedY: Single;
    Age, Life: Integer; // in flight
    Size: Single;
    Seed: TSdlFPoint; // its point on the hero's frame
  end;

  TUptakeScene = record
    Look: TUptakeLook;
    Picture: Integer; // the painter's, the count only carries it
    Left, Top: Single; // the picture's corner on the screen
    Mirrored: Boolean;
    Age: Integer;
    CenterX, CenterY: Single; // the middle of all that is painted, units
    Crumbs: TArray<TCrumb>;
  end;

  TBodySpot = record
    Seed: TSdlFPoint;
    Age: Integer;
    Tint: TRgb;
    Size: Single;
  end;

  // The light a crumb gives the body it has gone into
  TFeedLight = reference to procedure(ATint: TRgb; AShare, AKeep: Single);

// The cells of the grid that hold paint, in rows from the top left
function CutCrumbs(const AShape: TUptakeShape; ACrumb: Single): TArray<TCrumbCell>;

type
  TUptake = class
  private
    FSolid: TSolidProbe;
    FFeed: TFeedLight;
    FDice: TXorShift;
    FClock: Integer;
    FScenes: TArray<TUptakeScene>;
    FSpots: TArray<TBodySpot>;
    procedure QueueCrumbs(var AScene: TUptakeScene; const AHero: TSdlFPoint);
    procedure AgeSpots;
    procedure DropFinished;
    procedure StepScene(var AScene: TUptakeScene; const APose: THeroPose;
      const ASeeds: TSeedList);
    procedure Launch(const AScene: TUptakeScene; var ACrumb: TCrumb;
      const ASeeds: TSeedList);
    procedure BeginFall(var ACrumb: TCrumb);
    function RollFallLife: Integer;
    function PickSeed(const ASeeds: TSeedList): TSdlFPoint;
    procedure FlyHome(const AScene: TUptakeScene; var ACrumb: TCrumb;
      const APose: THeroPose);
    procedure FlyApart(var ACrumb: TCrumb);
    procedure Arrive(const AScene: TUptakeScene; const ACrumb: TCrumb);
    procedure DropScene(var AScene: TUptakeScene);
    procedure FeedWhatIsLeft(const AScene: TUptakeScene);
  public
    // ASolid answers in screen units
    constructor Create(const ASolid: TSolidProbe; const AFeed: TFeedLight;
      ASeed: Cardinal);
    // AHero - the middle of the hero, for the crumbs that leave nearest first
    procedure Start(const ALook: TUptakeLook; APicture: Integer;
      const AShape: TUptakeShape; ALeft, ATop: Single; AMirrored: Boolean;
      const AHero: TSdlFPoint);
    procedure Tick(const APose: THeroPose; const ASeeds: TSeedList);
    // A door: what was taken is the hero's at once
    procedure Settle;
    // The hero is dead: the crumbs fall where they are
    procedure Drop;
    procedure Clear;
    // Ticks counted; a restart of the level does not reset it
    property Clock: Integer read FClock;
    property Scenes: TArray<TUptakeScene> read FScenes;
    property Spots: TArray<TBodySpot> read FSpots;
  end;

  TUptakePainter = class
  private
    type
      TPicture = record
        Shape: TUptakeShape;
        Art: TSilhouette;
        Frame: PSdlTexture;
        Light: PSdlTexture; // the cross; nil when the set has none
        LightX, LightY: Single; // the middle of the cross, units
      end;
    var
      FRenderer: PSdlRenderer;
      FUptake: TUptake;
      FPictures: TList<TPicture>;
      FIndex: TDictionary<string, Integer>;
    function BuildPicture(const AName: string): TPicture;
    function MakeFrameTexture(ASurface: PSdlSurface): PSdlTexture;
    procedure PaintHalo(const APicture: TPicture; ALeft, ATop: Single;
      ATint: TRgb; ALevel: Single; AMirrored: Boolean);
    procedure DrawSceneHalos(AOrigin: TSdlPoint; AAlpha: Single);
    procedure DrawLyingHalos(const AField: TMonsterField; AScreen: Integer;
      AOrigin: TSdlPoint; AAlpha: Single);
    procedure DrawLyingCrosses(const ACanvas: TDynamicCanvas;
      const AField: TMonsterField; AScreen: Integer; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawScenePictures(AOrigin: TSdlPoint; AAlpha: Single);
    procedure DrawFilling(const AScene: TUptakeScene;
      const APicture: TPicture; AOrigin: TSdlPoint; AShare: Single);
    procedure DrawSittingCrumbs(const AScene: TUptakeScene;
      const APicture: TPicture; AOrigin: TSdlPoint);
    procedure DrawFlying(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawSpots(const ACanvas: TDynamicCanvas; const APose: THeroPose;
      AOrigin: TSdlPoint; ALift: Single);
  public
    constructor Create(ARenderer: PSdlRenderer; const AUptake: TUptake);
    destructor Destroy; override;
    // The picture of a sprite set, built on the first ask; the number is
    // what Start takes
    function PictureOf(const ASetName: string): Integer;
    function ShapeOf(APicture: Integer): TUptakeShape;
    // Under the pickups: the halos of the weapons that lie and of the
    // pictures being filled
    procedure DrawBehind(const AField: TMonsterField; AScreen: Integer;
      AOrigin: TSdlPoint; AAlpha: Single);
    // Over them: the light of the crosses, the filled pictures, the
    // crumbs that sit
    procedure DrawLoot(const ACanvas: TDynamicCanvas; const AField: TMonsterField;
      AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
    // Over the hero: the crumbs in flight and the spots on his body
    procedure DrawOver(const ACanvas: TDynamicCanvas; const APose: THeroPose;
      AOrigin: TSdlPoint; ALift, AAlpha: Single);
  end;

const
  MedkitUptake: TUptakeLook = (
    Fill: 5; Crumble: 6; Order: uoScattered; Crumb: 2; Flash: 0.9;
    Apart: False; Scatter: 1.6; Burst: 3; Pull: 1.4; Pulse: 0.65;
    PulseTicks: 14; Tint: (R: 64; G: 208; B: 96));
  WeaponUptake: TUptakeLook = (
    Fill: 5; Crumble: 6; Order: uoScattered; Crumb: 2; Flash: 0.9;
    Apart: False; Scatter: 1.6; Burst: 3; Pull: 1.4; Pulse: 0.65;
    PulseTicks: 14; Tint: (R: 255; G: 178; B: 56));
  PickupBurst: TUptakeLook = (
    Fill: 2; Crumble: 2; Order: uoScattered; Crumb: 2; Flash: 1.3;
    Apart: True; Scatter: 3.2; Burst: 0; Pull: 1.0; Pulse: 0;
    PulseTicks: 8; Tint: (R: 236; G: 240; B: 255));

implementation

uses
  System.Math, Sprites.Sets, Render.Sprites, Render.Glow, Monsters.Defs;

resourcestring
  SShapeTooShort = 'A pickup picture of %dx%d texels has only %d alpha bytes';
  SPictureFailed = 'Cannot read the pickup picture "%s": %s';
  SNoPictureFrame = 'The sprite set "%s" has no frame in its alive sequence';
  STextureFailed = 'Cannot make a texture of a pickup picture: %s';

type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888

const
  AliveSequence = 'alive';
  LightSprite = 'light';
  // As the monsters' cache: a frame wider than this is dense art with its
  // own alpha, the narrower ones are 2008 frames on black
  SmallPictureSide = 64;

  // The cutting
  PaintedAlpha = 128;
  MinCover = 0.12;
  GridEpsilon = 0.0001;
  TopDownSpanFloor = 0.001;
  NearSpanFloor = 1;
  QueueSpread = 0.8;
  QueueJitter = 0.2;
  CrumbSizeBase = 0.7;
  CrumbSizeCover = 0.6;

  // Leaving
  ScatterFloor = 0.4;
  ScatterSpan = 0.6;
  LaunchLift = 0.35;
  CenterPush = 0.06;

  // Flying to the hero
  BurstDrag = 0.86;
  PullDrag = 0.78;
  PullGrowTicks = 25;
  ArriveFloor = 3;
  FeedShare = 2;
  FeedDecay = 3;

  // Falling
  FallKickFloor = 1;
  FallKickSpan = 1.5;
  FallLifeFloor = 20;
  FallLifeSpan = 22;
  FallGravity = 0.32;
  FallDrag = 0.97;
  BounceKeep = -0.3;
  BounceSlide = 0.7;

  // Drawing
  MaskWhite = 0.2;
  // Half a screen pixel at the common window sizes, units
  CrumbBleed = 0.15;
  FlySpotSize = 2;
  FlySpotLevel = 0.8;
  FlyCoreSize = 0.8;
  FlyCoreWhite = 0.8;
  SpotGrowth = 3.2;
  SpotWhite = 0.5;
  SpotLevel = 0.9;

  // Light of a pickup that lies
  MedkitLightLevel = 0.60;
  MedkitLightPeriod = 50;
  WeaponLightLevel = 0.55;
  WeaponLightPeriod = 60;
  WaveFloor = 0.45;
  WaveSpan = 0.55;
  CrossWhite = 0.25;
  CrossLevel = 0.85;
  CrossSpotSize = 15;
  CrossSpotLevel = 0.55;

  ApartFadePower: Single = 1.2;

function AtLeast(AValue, AFloor: Single): Single;
begin
  if AValue < AFloor then
    Result := AFloor
  else
    Result := AValue;
end;

function AtMost(AValue, ACeiling: Single): Single;
begin
  if AValue > ACeiling then
    Result := ACeiling
  else
    Result := AValue;
end;

function Limit(AValue, ALow, AHigh: Single): Single;
begin
  Result := AtMost(AtLeast(AValue, ALow), AHigh);
end;

function Ease(AShare: Single): Single;
begin
  var Rest: Single := 1 - AShare;
  Result := 1 - Rest * Rest * Rest;
end;

function FlipFlag(AMirrored: Boolean): Integer;
begin
  if AMirrored then
    Result := SdlFlipHorizontal
  else
    Result := SdlFlipNone;
end;

function RectOf(AX, AY, AWidth, AHeight: Single): TSdlFRect;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.W := AWidth;
  Result.H := AHeight;
end;

function TexelOf(AValue: Single): Integer;
begin
  Result := Round(AValue);
end;

// The share of the light a tick leaves
function KeepOf(const ALook: TUptakeLook): Single;
begin
  if ALook.PulseTicks <= 0 then
    Exit(0);
  Result := Exp(-FeedDecay / ALook.PulseTicks);
end;

// ---------------------------------------------------------------------------
// Cutting a picture into crumbs
// ---------------------------------------------------------------------------

// Painted texels of one row between two columns; ASumX gets their columns
function PaintedInRow(const AShape: TUptakeShape; ARow, AFrom, ATo: Integer;
  var ASumX: Double): Integer;
begin
  Result := 0;
  for var i := AFrom to ATo - 1 do
  begin
    if AShape.Alpha[ARow * AShape.TexW + i] < PaintedAlpha then
      Continue;
    Inc(Result);
    ASumX := ASumX + i + 0.5;
  end;
end;

// Cover and middle of the cell's texels; False when it holds too little paint
function MeasureCell(const AShape: TUptakeShape; var ACell: TCrumbCell): Boolean;
begin
  var Painted := 0;
  var SumX: Double := 0;
  var SumY: Double := 0;
  for var Row := ACell.Source.Y to ACell.Source.Y + ACell.Source.H - 1 do
  begin
    var InRow := PaintedInRow(AShape, Row, ACell.Source.X,
      ACell.Source.X + ACell.Source.W, SumX);
    Inc(Painted, InRow);
    SumY := SumY + InRow * (Row + 0.5);
  end;

  ACell.Cover := Painted / (ACell.Source.W * ACell.Source.H);
  if (Painted = 0) or (ACell.Cover < MinCover) then
    Exit(False);
  ACell.MidX := SumX / Painted * AShape.Width / AShape.TexW;
  ACell.MidY := SumY / Painted * AShape.Height / AShape.TexH;
  Result := True;
end;

function TryCutCell(const AShape: TUptakeShape; ACrumb: Single; ACol, ARow: Integer;
  out ACell: TCrumbCell): Boolean;
begin
  ACell := Default(TCrumbCell);
  var ScaleX: Single := AShape.TexW / AShape.Width;
  var ScaleY: Single := AShape.TexH / AShape.Height;
  var Right := TexelOf((ACol * ACrumb + ACrumb) * ScaleX);
  var Bottom := TexelOf((ARow * ACrumb + ACrumb) * ScaleY);
  if Right > AShape.TexW then
    Right := AShape.TexW;
  if Bottom > AShape.TexH then
    Bottom := AShape.TexH;

  ACell.Source.X := TexelOf(ACol * ACrumb * ScaleX);
  ACell.Source.Y := TexelOf(ARow * ACrumb * ScaleY);
  ACell.Source.W := Right - ACell.Source.X;
  ACell.Source.H := Bottom - ACell.Source.Y;
  if (ACell.Source.W <= 0) or (ACell.Source.H <= 0) then
    Exit(False);

  ACell.X := ACell.Source.X / ScaleX;
  ACell.Y := ACell.Source.Y / ScaleY;
  ACell.W := ACell.Source.W / ScaleX;
  ACell.H := ACell.Source.H / ScaleY;
  Result := MeasureCell(AShape, ACell);
end;

procedure CutRow(const AShape: TUptakeShape; ACrumb: Single; ARow: Integer;
  const ACells: TList<TCrumbCell>);
begin
  var Col := 0;
  while Col * ACrumb < AShape.Width - GridEpsilon do
  begin
    var Cell: TCrumbCell;
    if TryCutCell(AShape, ACrumb, Col, ARow, Cell) then
      ACells.Add(Cell);
    Inc(Col);
  end;
end;

function CutCrumbs(const AShape: TUptakeShape; ACrumb: Single): TArray<TCrumbCell>;
begin
  Result := nil;
  if (AShape.TexW <= 0) or (AShape.TexH <= 0) or (ACrumb <= 0) then
    Exit;
  if Length(AShape.Alpha) < AShape.TexW * AShape.TexH then
    raise EUptakeError.CreateFmt(SShapeTooShort,
      [AShape.TexW, AShape.TexH, Length(AShape.Alpha)]);

  var Cells := TList<TCrumbCell>.Create;
  try
    var Row := 0;
    while Row * ACrumb < AShape.Height - GridEpsilon do
    begin
      CutRow(AShape, ACrumb, Row, Cells);
      Inc(Row);
    end;
    Result := Cells.ToArray;
  finally
    Cells.Free;
  end;
end;

// ---------------------------------------------------------------------------
// A scene's plan
// ---------------------------------------------------------------------------

procedure MirrorCells(var ACrumbs: TArray<TCrumb>; AWidth: Single);
begin
  for var i := 0 to High(ACrumbs) do
  begin
    ACrumbs[i].Cell.X := AWidth - ACrumbs[i].Cell.X - ACrumbs[i].Cell.W;
    ACrumbs[i].Cell.MidX := AWidth - ACrumbs[i].Cell.MidX;
  end;
end;

// The middle of all that is painted, each cell by the paint it holds
procedure SetCenter(var AScene: TUptakeScene);
begin
  var Weight: Double := 0;
  var SumX: Double := 0;
  var SumY: Double := 0;
  for var Crumb in AScene.Crumbs do
  begin
    var Area: Double := Crumb.Cell.Cover * Crumb.Cell.W * Crumb.Cell.H;
    Weight := Weight + Area;
    SumX := SumX + Area * Crumb.Cell.MidX;
    SumY := SumY + Area * Crumb.Cell.MidY;
  end;
  AScene.CenterX := SumX / Weight;
  AScene.CenterY := SumY / Weight;
end;

// What the order of leaving goes by: height, or distance to the hero
function CrumbKey(const AScene: TUptakeScene; const ACrumb: TCrumb;
  const AHero: TSdlFPoint): Single;
begin
  case AScene.Look.Order of
    uoTopDown:
      Result := ACrumb.Cell.MidY;
    uoNearFirst:
      begin
        var DeltaX := AScene.Left + ACrumb.Cell.MidX - AHero.X;
        var DeltaY := AScene.Top + ACrumb.Cell.MidY - AHero.Y;
        Result := Sqrt(DeltaX * DeltaX + DeltaY * DeltaY);
      end;
  else
    Result := 0;
  end;
end;

function KeySpanFloor(AOrder: TUptakeOrder): Single;
begin
  if AOrder = uoNearFirst then
    Result := NearSpanFloor
  else
    Result := TopDownSpanFloor;
end;

// ---------------------------------------------------------------------------
// TUptake
// ---------------------------------------------------------------------------

constructor TUptake.Create(const ASolid: TSolidProbe; const AFeed: TFeedLight;
  ASeed: Cardinal);
begin
  inherited Create;
  FSolid := ASolid;
  FFeed := AFeed;
  FDice.Seed := ASeed;
  // A zero seed would freeze the stream at zero
  if FDice.Seed = 0 then
    FDice.Seed := 1;
end;

procedure TUptake.Start(const ALook: TUptakeLook; APicture: Integer;
  const AShape: TUptakeShape; ALeft, ATop: Single; AMirrored: Boolean;
  const AHero: TSdlFPoint);
begin
  var Cells := CutCrumbs(AShape, ALook.Crumb);
  if Length(Cells) = 0 then
    Exit;

  var Scene := Default(TUptakeScene);
  Scene.Look := ALook;
  Scene.Picture := APicture;
  Scene.Left := ALeft;
  Scene.Top := ATop;
  Scene.Mirrored := AMirrored;
  SetLength(Scene.Crumbs, Length(Cells));
  for var i := 0 to High(Cells) do
  begin
    Scene.Crumbs[i] := Default(TCrumb);
    Scene.Crumbs[i].Cell := Cells[i];
  end;
  if AMirrored then
    MirrorCells(Scene.Crumbs, AShape.Width);
  SetCenter(Scene);
  QueueCrumbs(Scene, AHero);

  SetLength(FScenes, Length(FScenes) + 1);
  FScenes[High(FScenes)] := Scene;
end;

procedure TUptake.QueueCrumbs(var AScene: TUptakeScene; const AHero: TSdlFPoint);
begin
  var Keys: TArray<Single>;
  SetLength(Keys, Length(AScene.Crumbs));
  for var i := 0 to High(Keys) do
    Keys[i] := CrumbKey(AScene, AScene.Crumbs[i], AHero);

  var Nearest := Keys[0];
  var Farthest := Keys[0];
  for var Key in Keys do
  begin
    Nearest := AtMost(Nearest, Key);
    Farthest := AtLeast(Farthest, Key);
  end;
  var Span := AtLeast(Farthest - Nearest, KeySpanFloor(AScene.Look.Order));

  for var i := 0 to High(Keys) do
  begin
    var Queue: Single;
    if AScene.Look.Order = uoScattered then
      Queue := FDice.NextUnit
    else
      Queue := QueueSpread * (Keys[i] - Nearest) / Span + QueueJitter * FDice.NextUnit;
    AScene.Crumbs[i].LeaveAt := AScene.Look.Fill + Queue * AScene.Look.Crumble;
    AScene.Crumbs[i].Size := AScene.Look.Crumb *
      (CrumbSizeBase + CrumbSizeCover * AScene.Crumbs[i].Cell.Cover);
  end;
end;

procedure TUptake.Tick(const APose: THeroPose; const ASeeds: TSeedList);
begin
  Inc(FClock);
  AgeSpots;
  for var i := 0 to High(FScenes) do
    StepScene(FScenes[i], APose, ASeeds);
  DropFinished;
end;

procedure TUptake.AgeSpots;
begin
  var Kept := 0;
  for var i := 0 to High(FSpots) do
  begin
    Inc(FSpots[i].Age);
    if FSpots[i].Age >= SpotTicks then
      Continue;
    FSpots[Kept] := FSpots[i];
    Inc(Kept);
  end;
  SetLength(FSpots, Kept);
end;

function IsFinished(const AScene: TUptakeScene): Boolean;
begin
  Result := True;
  for var Crumb in AScene.Crumbs do
    if Crumb.State <> csGone then
      Exit(False);
end;

procedure TUptake.DropFinished;
begin
  var Kept := 0;
  for var i := 0 to High(FScenes) do
  begin
    if IsFinished(FScenes[i]) then
      Continue;
    FScenes[Kept] := FScenes[i];
    Inc(Kept);
  end;
  SetLength(FScenes, Kept);
end;

procedure TUptake.StepScene(var AScene: TUptakeScene; const APose: THeroPose;
  const ASeeds: TSeedList);
begin
  Inc(AScene.Age);
  for var i := 0 to High(AScene.Crumbs) do
  begin
    if (AScene.Crumbs[i].State = csSitting) and
      (AScene.Crumbs[i].LeaveAt <= AScene.Age) then
      Launch(AScene, AScene.Crumbs[i], ASeeds);
    if AScene.Crumbs[i].State <> csFlying then
      Continue;
    if AScene.Look.Apart then
      FlyApart(AScene.Crumbs[i])
    else
      FlyHome(AScene, AScene.Crumbs[i], APose);
  end;
end;

procedure TUptake.Launch(const AScene: TUptakeScene; var ACrumb: TCrumb;
  const ASeeds: TSeedList);
begin
  var Look := AScene.Look;
  var Angle: Single := FDice.NextUnit * 2 * Pi;
  var Speed: Single := Look.Scatter * (ScatterFloor + ScatterSpan * FDice.NextUnit);
  var OutX := ACrumb.Cell.MidX - AScene.CenterX;
  var OutY := ACrumb.Cell.MidY - AScene.CenterY;

  ACrumb.State := csFlying;
  ACrumb.Age := 0;
  ACrumb.X := AScene.Left + ACrumb.Cell.MidX;
  ACrumb.Y := AScene.Top + ACrumb.Cell.MidY;
  ACrumb.SpeedX := Cos(Angle) * Speed + OutX * CenterPush * Look.Scatter;
  ACrumb.SpeedY := Sin(Angle) * Speed - LaunchLift * Look.Scatter +
    OutY * CenterPush * Look.Scatter;
  if Look.Apart then
    BeginFall(ACrumb)
  else
    ACrumb.Seed := PickSeed(ASeeds);
end;

function TUptake.RollFallLife: Integer;
begin
  Result := FallLifeFloor + Trunc(FallLifeSpan * FDice.NextUnit);
end;

procedure TUptake.BeginFall(var ACrumb: TCrumb);
begin
  ACrumb.SpeedY := ACrumb.SpeedY - (FallKickFloor + FallKickSpan * FDice.NextUnit);
  ACrumb.Life := RollFallLife;
end;

// The die is rolled even when the frame shows no point, so a stream does
// not depend on what the hero looks like
function TUptake.PickSeed(const ASeeds: TSeedList): TSdlFPoint;
begin
  var Roll := FDice.NextUnit;
  if Length(ASeeds) = 0 then
  begin
    Result.X := HeroSize / 2;
    Result.Y := HeroSize / 2;
    Exit;
  end;
  var Index: Integer := Trunc(Roll * Length(ASeeds));
  if Index > High(ASeeds) then
    Index := High(ASeeds);
  Result := ASeeds[Index];
end;

procedure TUptake.FlyHome(const AScene: TUptakeScene; var ACrumb: TCrumb;
  const APose: THeroPose);
begin
  Inc(ACrumb.Age);
  if ACrumb.Age <= AScene.Look.Burst then
  begin
    ACrumb.SpeedX := ACrumb.SpeedX * BurstDrag;
    ACrumb.SpeedY := ACrumb.SpeedY * BurstDrag;
    ACrumb.X := ACrumb.X + ACrumb.SpeedX;
    ACrumb.Y := ACrumb.Y + ACrumb.SpeedY;
    Exit;
  end;

  var SeedX := ACrumb.Seed.X;
  if APose.Mirrored then
    SeedX := HeroSize - SeedX;
  var ToX := APose.Left + SeedX - ACrumb.X;
  var ToY := APose.Top + ACrumb.Seed.Y - ACrumb.Y;
  var Distance := Sqrt(ToX * ToX + ToY * ToY);
  var Speed := Sqrt(ACrumb.SpeedX * ACrumb.SpeedX + ACrumb.SpeedY * ACrumb.SpeedY);
  if Distance < AtLeast(ArriveFloor, Speed) then
  begin
    Arrive(AScene, ACrumb);
    ACrumb.State := csGone;
    Exit;
  end;

  var Pull := AScene.Look.Pull * (1 + (ACrumb.Age - AScene.Look.Burst) / PullGrowTicks);
  ACrumb.SpeedX := ACrumb.SpeedX * PullDrag + ToX / Distance * Pull;
  ACrumb.SpeedY := ACrumb.SpeedY * PullDrag + ToY / Distance * Pull;
  ACrumb.X := ACrumb.X + ACrumb.SpeedX;
  ACrumb.Y := ACrumb.Y + ACrumb.SpeedY;
end;

procedure TUptake.FlyApart(var ACrumb: TCrumb);
begin
  Inc(ACrumb.Age);
  ACrumb.SpeedY := ACrumb.SpeedY + FallGravity;
  ACrumb.SpeedX := ACrumb.SpeedX * FallDrag;
  ACrumb.X := ACrumb.X + ACrumb.SpeedX;
  ACrumb.Y := ACrumb.Y + ACrumb.SpeedY;
  if Assigned(FSolid) and FSolid(ACrumb.X, ACrumb.Y) then
  begin
    ACrumb.Y := ACrumb.Y - ACrumb.SpeedY;
    ACrumb.SpeedY := ACrumb.SpeedY * BounceKeep;
    ACrumb.SpeedX := ACrumb.SpeedX * BounceSlide;
  end;
  if ACrumb.Age >= ACrumb.Life then
    ACrumb.State := csGone;
end;

procedure TUptake.Arrive(const AScene: TUptakeScene; const ACrumb: TCrumb);
begin
  if Assigned(FFeed) then
    FFeed(AScene.Look.Tint,
      FeedShare * AScene.Look.Pulse / Length(AScene.Crumbs), KeepOf(AScene.Look));

  var Spot := Default(TBodySpot);
  Spot.Seed := ACrumb.Seed;
  Spot.Tint := AScene.Look.Tint;
  Spot.Size := ACrumb.Size;
  SetLength(FSpots, Length(FSpots) + 1);
  FSpots[High(FSpots)] := Spot;
end;

// What has not arrived is the hero's now: one feed for the whole of it
procedure TUptake.FeedWhatIsLeft(const AScene: TUptakeScene);
begin
  if AScene.Look.Apart or not Assigned(FFeed) then
    Exit;
  var Left := 0;
  for var Crumb in AScene.Crumbs do
    if Crumb.State <> csGone then
      Inc(Left);
  FFeed(AScene.Look.Tint,
    FeedShare * AScene.Look.Pulse * Left / Length(AScene.Crumbs),
    KeepOf(AScene.Look));
end;

procedure TUptake.Settle;
begin
  for var Scene in FScenes do
    FeedWhatIsLeft(Scene);
  Clear;
end;

procedure TUptake.DropScene(var AScene: TUptakeScene);
begin
  if AScene.Look.Apart then
    Exit;
  AScene.Look.Apart := True;
  for var i := 0 to High(AScene.Crumbs) do
    if AScene.Crumbs[i].State = csFlying then
      AScene.Crumbs[i].Life := AScene.Crumbs[i].Age + RollFallLife;
end;

procedure TUptake.Drop;
begin
  for var i := 0 to High(FScenes) do
    DropScene(FScenes[i]);
  FSpots := nil;
end;

procedure TUptake.Clear;
begin
  FScenes := nil;
  FSpots := nil;
end;

// ---------------------------------------------------------------------------
// Drawing a texture over the screen
// ---------------------------------------------------------------------------

// A glow texture (additive by its own make), or a piece of one
procedure PaintGlow(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ASource: PSdlRect; const ADest: TSdlFRect; ATint: TRgb; ALevel: Single;
  AMirrored: Boolean);
begin
  SDL_SetTextureColorMod(ATexture, ATint.R, ATint.G, ATint.B);
  SDL_SetTextureAlphaMod(ATexture, Round(255 * Limit(ALevel, 0, 1)));
  SDL_RenderCopyExF(ARenderer, ATexture, ASource, @ADest, 0.0, nil,
    FlipFlag(AMirrored));
end;

// The picture's own texture as painted; its alpha mod is never touched
procedure PaintFrame(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ADest: TSdlFRect; AMirrored: Boolean);
begin
  SDL_RenderCopyExF(ARenderer, ATexture, nil, @ADest, 0.0, nil,
    FlipFlag(AMirrored));
end;

// Where a pickup that lies is drawn, with the sway of the deck under it
function LootCorner(const AMonster: TMonster; AOrigin: TSdlPoint;
  AAlpha: Single): TSdlFPoint;
begin
  Result.X := Round(AMonster.X) + AOrigin.X;
  Result.Y := Round(AMonster.Y) - SpriteSize + AOrigin.Y + AMonster.DeckLift(AAlpha);
end;

function IsLying(const AMonster: TMonster; AScreen: Integer): Boolean;
begin
  Result := (AMonster.Screen = AScreen) and
    (AMonster.Def.Category = mcPickup) and (AMonster.Life = mlAlive);
end;

// The breath of the light of a pickup that lies; AClock - ticks and a fraction
function LyingLevel(ALevel: Single; APeriod: Integer; AClock: Single): Single;
begin
  var Wave: Single := 0.5 + 0.5 * Sin(2 * Pi * AClock / APeriod);
  Result := ALevel * (WaveFloor + WaveSpan * Wave);
end;

// ---------------------------------------------------------------------------
// TUptakePainter
// ---------------------------------------------------------------------------

constructor TUptakePainter.Create(ARenderer: PSdlRenderer; const AUptake: TUptake);
begin
  inherited Create;
  FRenderer := ARenderer;
  FUptake := AUptake;
  FPictures := TList<TPicture>.Create;
  FIndex := TDictionary<string, Integer>.Create;
end;

destructor TUptakePainter.Destroy;
begin
  for var Picture in FPictures do
  begin
    var Art := Picture.Art;
    FreeSilhouette(Art);
    if Assigned(Picture.Frame) then
      SDL_DestroyTexture(Picture.Frame);
    if Assigned(Picture.Light) then
      SDL_DestroyTexture(Picture.Light);
  end;
  FIndex.Free;
  FPictures.Free;
  inherited;
end;

// The frame in ABGR8888, whatever the file held
function LoadAbgrSurface(const ASpriteSet: TSpriteSet; const AName: string): PSdlSurface;
begin
  var Loaded := LoadImageSurface(ASpriteSet, AName);
  if Loaded = nil then
    raise EUptakeError.CreateFmt(SPictureFailed, [AName, SdlErrorText]);
  Result := SDL_ConvertSurfaceFormat(Loaded, SdlPixelFormatAbgr8888, 0);
  SDL_FreeSurface(Loaded);
  if Result = nil then
    raise EUptakeError.CreateFmt(SPictureFailed, [AName, SdlErrorText]);
end;

function ShapeOfSurface(ASurface: PSdlSurface): TUptakeShape;
begin
  Result.TexW := ASurface.W;
  Result.TexH := ASurface.H;
  Result.Width := SpriteSize;
  Result.Height := SpriteSize;
  SetLength(Result.Alpha, ASurface.W * ASurface.H);
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    for var Col := 0 to ASurface.W - 1 do
    begin
      Result.Alpha[Row * ASurface.W + Col] := Pixel[3];
      Inc(Pixel);
    end;
  end;
end;

// The middle of the paint, weighed by alpha, in units from the corner
procedure FindCrossMiddle(ASurface: PSdlSurface; out AX, AY: Single);
begin
  var Weight: Double := 0;
  var SumX: Double := 0;
  var SumY: Double := 0;
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    for var Col := 0 to ASurface.W - 1 do
    begin
      Weight := Weight + Pixel[3];
      SumX := SumX + Pixel[3] * (Col + 0.5);
      SumY := SumY + Pixel[3] * (Row + 0.5);
      Inc(Pixel);
    end;
  end;
  AX := SpriteSize / 2;
  AY := SpriteSize / 2;
  if Weight = 0 then
    Exit;
  AX := SumX / Weight * SpriteSize / ASurface.W;
  AY := SumY / Weight * SpriteSize / ASurface.H;
end;

function TUptakePainter.MakeFrameTexture(ASurface: PSdlSurface): PSdlTexture;
begin
  var IsDense := ASurface.W > SmallPictureSide;
  if not IsDense then
    SDL_SetColorKey(ASurface, 1, SDL_MapRGB(ASurface.Format, 0, 0, 0));
  Result := SDL_CreateTextureFromSurface(FRenderer, ASurface);
  if Result = nil then
    raise EUptakeError.CreateFmt(STextureFailed, [SdlErrorText]);
  if IsDense then
    SDL_SetTextureScaleMode(Result, SdlScaleModeLinear);
end;

function TUptakePainter.BuildPicture(const AName: string): TPicture;
begin
  Result := Default(TPicture);
  var SpriteSet := TSpriteSet.Create(SpriteSetsDir + AName + '.mset');
  try
    var Frames := SpriteSet.SequenceFrames(AliveSequence);
    if Length(Frames) = 0 then
      raise EUptakeError.CreateFmt(SNoPictureFrame, [AName]);

    var Surface := LoadAbgrSurface(SpriteSet, Frames[0]);
    try
      Result.Shape := ShapeOfSurface(Surface);
      Result.Art := BuildSilhouette(FRenderer, Surface, SpriteSize, SpriteSize);
      Result.Frame := MakeFrameTexture(Surface);
    finally
      SDL_FreeSurface(Surface);
    end;

    if SpriteSet.Contains(LightSprite) then
    begin
      var LightSurface := LoadAbgrSurface(SpriteSet, LightSprite);
      try
        Result.Light := CreateGlowTexture(FRenderer, LightSurface);
        FindCrossMiddle(LightSurface, Result.LightX, Result.LightY);
      finally
        SDL_FreeSurface(LightSurface);
      end;
    end;
  finally
    SpriteSet.Free;
  end;
end;

function TUptakePainter.PictureOf(const ASetName: string): Integer;
begin
  var Key := LowerCase(ASetName);
  if FIndex.TryGetValue(Key, Result) then
    Exit;
  FPictures.Add(BuildPicture(ASetName));
  Result := FPictures.Count - 1;
  FIndex.Add(Key, Result);
end;

function TUptakePainter.ShapeOf(APicture: Integer): TUptakeShape;
begin
  Result := FPictures[APicture].Shape;
end;

// The halo of a picture, drawn twice when the level is above one
procedure TUptakePainter.PaintHalo(const APicture: TPicture; ALeft, ATop: Single;
  ATint: TRgb; ALevel: Single; AMirrored: Boolean);
begin
  if ALevel <= 0 then
    Exit;
  var Art := APicture.Art;
  var Dest := RectOf(ALeft - Art.HaloMarginX, ATop - Art.HaloMarginY,
    APicture.Shape.Width + 2 * Art.HaloMarginX,
    APicture.Shape.Height + 2 * Art.HaloMarginY);
  PaintGlow(FRenderer, Art.Halo, nil, Dest, ATint, AtMost(ALevel, 1), AMirrored);
  if ALevel > 1 then
    PaintGlow(FRenderer, Art.Halo, nil, Dest, ATint, ALevel - 1, AMirrored);
end;

function SittingShare(const AScene: TUptakeScene): Single;
begin
  var Sitting := 0;
  for var Crumb in AScene.Crumbs do
    if Crumb.State = csSitting then
      Inc(Sitting);
  Result := Sitting / Length(AScene.Crumbs);
end;

procedure TUptakePainter.DrawSceneHalos(AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Scene in FUptake.Scenes do
  begin
    var Time := Scene.Age + AAlpha;
    var Level: Single;
    if Time < Scene.Look.Fill then
      Level := Scene.Look.Flash * Ease(Time / Scene.Look.Fill)
    else
      Level := Scene.Look.Flash * SittingShare(Scene);
    PaintHalo(FPictures[Scene.Picture], Scene.Left + AOrigin.X,
      Scene.Top + AOrigin.Y, Scene.Look.Tint, Level, Scene.Mirrored);
  end;
end;

// A weapon has no cross to light: the halo of its silhouette breathes instead
procedure TUptakePainter.DrawLyingHalos(const AField: TMonsterField;
  AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Clock := FUptake.Clock + AAlpha;
  var Level := LyingLevel(WeaponLightLevel, WeaponLightPeriod, Clock);
  for var Monster in AField.Monsters do
  begin
    if not IsLying(Monster, AScreen) then
      Continue;
    var Picture := FPictures[PictureOf(Monster.ArtSet)];
    if Picture.Light <> nil then
      Continue;
    var Corner := LootCorner(Monster, AOrigin, AAlpha);
    PaintHalo(Picture, Corner.X, Corner.Y, WeaponUptake.Tint, Level,
      Monster.Mirrored);
  end;
end;

procedure TUptakePainter.DrawBehind(const AField: TMonsterField; AScreen: Integer;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  DrawSceneHalos(AOrigin, AAlpha);
  DrawLyingHalos(AField, AScreen, AOrigin, AAlpha);
end;

// A medkit's cross lit from within: its own sprite and a spot at its middle
procedure TUptakePainter.DrawLyingCrosses(const ACanvas: TDynamicCanvas;
  const AField: TMonsterField; AScreen: Integer; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  var Clock := FUptake.Clock + AAlpha;
  var Level := LyingLevel(MedkitLightLevel, MedkitLightPeriod, Clock);
  var Tint := MedkitUptake.Tint;
  var Light := Mix(Tint, White, CrossWhite);
  for var Monster in AField.Monsters do
  begin
    if not IsLying(Monster, AScreen) then
      Continue;
    var Picture := FPictures[PictureOf(Monster.ArtSet)];
    if Picture.Light = nil then
      Continue;

    var Corner := LootCorner(Monster, AOrigin, AAlpha);
    PaintGlow(FRenderer, Picture.Light, nil,
      RectOf(Corner.X, Corner.Y, SpriteSize, SpriteSize), Light,
      Level * CrossLevel, Monster.Mirrored);
    var CrossX := Picture.LightX;
    if Monster.Mirrored then
      CrossX := SpriteSize - CrossX;
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, Corner.X + CrossX,
      Corner.Y + Picture.LightY, CrossSpotSize, Tint, Level * CrossSpotLevel);
  end;
end;

// The picture as painted, and over it the same shape in the color's own,
// rising to a solid silhouette. The mask is additive by its make; here it
// is laid on plainly and put back before this returns.
procedure TUptakePainter.DrawFilling(const AScene: TUptakeScene;
  const APicture: TPicture; AOrigin: TSdlPoint; AShare: Single);
begin
  var Dest := RectOf(AScene.Left + AOrigin.X, AScene.Top + AOrigin.Y,
    APicture.Shape.Width, APicture.Shape.Height);
  PaintFrame(FRenderer, APicture.Frame, Dest, AScene.Mirrored);

  SDL_SetTextureBlendMode(APicture.Art.Mask, SdlBlendModeBlend);
  try
    PaintGlow(FRenderer, APicture.Art.Mask, nil, Dest,
      Mix(AScene.Look.Tint, White, MaskWhite), AShare, AScene.Mirrored);
  finally
    SDL_SetTextureBlendMode(APicture.Art.Mask, SdlBlendModeAdd);
  end;
end;

// The crumbs that have not left are the filled picture, cut in pieces. Each
// is a little wider than its cell: on a window scaled to fractions, the
// seams between neighbors would show as hairs.
procedure TUptakePainter.DrawSittingCrumbs(const AScene: TUptakeScene;
  const APicture: TPicture; AOrigin: TSdlPoint);
begin
  var Tint := Mix(AScene.Look.Tint, White, MaskWhite);
  SDL_SetTextureBlendMode(APicture.Art.Mask, SdlBlendModeBlend);
  try
    for var Crumb in AScene.Crumbs do
    begin
      if Crumb.State <> csSitting then
        Continue;
      var Source := Crumb.Cell.Source;
      var Dest := RectOf(AScene.Left + AOrigin.X + Crumb.Cell.X - CrumbBleed,
        AScene.Top + AOrigin.Y + Crumb.Cell.Y - CrumbBleed,
        Crumb.Cell.W + 2 * CrumbBleed, Crumb.Cell.H + 2 * CrumbBleed);
      PaintGlow(FRenderer, APicture.Art.Mask, @Source, Dest, Tint, 1,
        AScene.Mirrored);
    end;
  finally
    SDL_SetTextureBlendMode(APicture.Art.Mask, SdlBlendModeAdd);
  end;
end;

procedure TUptakePainter.DrawScenePictures(AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Scene in FUptake.Scenes do
  begin
    var Picture := FPictures[Scene.Picture];
    var Time := Scene.Age + AAlpha;
    if Time < Scene.Look.Fill then
      DrawFilling(Scene, Picture, AOrigin, Ease(Time / Scene.Look.Fill))
    else
      DrawSittingCrumbs(Scene, Picture, AOrigin);
  end;
end;

procedure TUptakePainter.DrawLoot(const ACanvas: TDynamicCanvas;
  const AField: TMonsterField; AScreen: Integer; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  DrawLyingCrosses(ACanvas, AField, AScreen, AOrigin, AAlpha);
  DrawScenePictures(AOrigin, AAlpha);
end;

procedure TUptakePainter.DrawFlying(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Scene in FUptake.Scenes do
  begin
    var Tint := Scene.Look.Tint;
    var CoreTint := Mix(Tint, White, FlyCoreWhite);
    for var Crumb in Scene.Crumbs do
    begin
      if Crumb.State <> csFlying then
        Continue;
      var Strength: Single := 1;
      if Scene.Look.Apart then
        Strength := Power(AtLeast(1 - Crumb.Age / Crumb.Life, 0), ApartFadePower);
      var X := Crumb.X + Crumb.SpeedX * AAlpha + AOrigin.X;
      var Y := Crumb.Y + Crumb.SpeedY * AAlpha + AOrigin.Y;
      DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X, Y, FlySpotSize * Crumb.Size,
        Tint, FlySpotLevel * Strength);
      DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X, Y, FlyCoreSize * Crumb.Size,
        CoreTint, Strength);
    end;
  end;
end;

// The flash where a crumb went in, on the hero's frame as he stands now
procedure TUptakePainter.DrawSpots(const ACanvas: TDynamicCanvas;
  const APose: THeroPose; AOrigin: TSdlPoint; ALift: Single);
begin
  for var Spot in FUptake.Spots do
  begin
    var SeedX := Spot.Seed.X;
    if APose.Mirrored then
      SeedX := HeroSize - SeedX;
    var Level := (1 - Spot.Age / SpotTicks) * SpotLevel;
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, APose.Left + SeedX + AOrigin.X,
      APose.Top + Spot.Seed.Y + AOrigin.Y + ALift, SpotGrowth * Spot.Size,
      Mix(Spot.Tint, White, SpotWhite), Level);
  end;
end;

procedure TUptakePainter.DrawOver(const ACanvas: TDynamicCanvas;
  const APose: THeroPose; AOrigin: TSdlPoint; ALift, AAlpha: Single);
begin
  DrawFlying(ACanvas, AOrigin, AAlpha);
  DrawSpots(ACanvas, APose, AOrigin, ALift);
end;

end.
