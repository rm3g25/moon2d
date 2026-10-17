{
  Orbs.Burst - the burst of the suit: the suit takes as much light as it
  holds, and the rest goes out of the hero. Four beats.

  - The inhale: two ticks in which the world stands and the hero does
    not. The screen under him goes out under a veil and he is a bare
    figure on it.
  - The strike: rays go out of his chest, one every fifteen degrees, the
    first straight up, all alike. A ring runs out over the room, the
    screen flashes.
  - The flight: the rays go through matter and off the screen. Where a
    ray goes into a face of matter it leaves a mark there, a soft spot of
    light.
  - The echo: motes come out of the points of his body, slow down and
    settle; the marks melt.

  A ray has no knot of light at its head: its strongest stretch stands
  behind the head, and the head thins out. In a vortex the rays leave
  curled one way, and the curl dies off as they go, or a ray would circle
  the room.

  The burst is one for every form; a form lends it its colors only. A
  light one is light added to light. A dark one is a black hole: the
  bodies of its rays, of its ring and of its motes are drawn over what is
  beneath, with a light halo about them, and its inhale is a negative -
  a light veil and a dark figure.

  The look and the time only. What a ray strikes is the game's to settle:
  the burst tells the stretches its heads have passed this tick. Matter
  it touches only for the marks.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Burst;
{$I ..\..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Effects.Emitter, Levels.Dynamics, Orbs.Harvest,
  Orbs.Rite;

type
  // The colors a form lends its burst; the burst is one for every form
  TBurstLook = record
    Glow: TRgb; // the haze, the glow, the halo
    Core: TRgb; // the heart of a light ray; the body of a dark one
    // The body is drawn over, not added: a black hole. Its inhale is a
    // negative.
    Dark: Boolean;
    Flash: TRgb;
    Veil: TRgb;
    VeilLevel: Single;
    Silhouette: TRgb;
    Mote: TRgb;
  end;

  TBurstEvent = (beNone, beStruck);

  // What a ray's head passed this tick: the game's to strike along
  TBurstStretch = record
    FromX, FromY, ToX, ToY: Single;
  end;

  // The hero's frame as a bare figure: the white mask of the frame
  // (Render.Silhouette), where the frame stands on the screen, and whether
  // it is turned
  TBurstFigure = record
    Mask: PSdlTexture;
    Frame: TSdlFRect;
    Mirrored: Boolean;
  end;

  TOrbBurst = class
  private type
    TBurstRay = record
      Heading: Single; // radians, as the picture turns: Y grows downward
      Flown: Single; // units
      // Where the head stood at every tick, the first at the hero's chest:
      // the ray is laid along it
      Track: TArray<TSdlFPoint>;
      WasOpen: Boolean; // the head stood in the open, on the screen
      Gone: Boolean;
    end;

    // One pass of a band along a ray or the ring: units across, and what
    // the full of the band's share adds to them
    TBurstBand = record
      Width, Swell: Single;
      Level: Single;
      // The core color, else the glow; on a dark look it is drawn over
      Body: Boolean;
    end;
  private
    FBodyOf: TBodyProbe;
    FLook: TBurstLook;
    FCurl: Boolean;
    FMatter: TMatter;
    // The hero's center: followed through the inhale, kept from the
    // strike on - the rays neither lag behind him nor follow him
    FCenter: TSdlFPoint;
    FInhaleLeft: Integer; // ticks
    FStruck: Boolean;
    FAge: Integer; // ticks since the strike
    FStrikeUntold: Boolean;
    FRays: TArray<TBurstRay>;
    FStretches: TArray<TBurstStretch>;
    FMarks: TParticleSwarm;
    FMotes: TParticleSwarm;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    // The band being laid: its points on the screen, and at each the
    // share of the band's swell and of its level
    FPoints: TArray<TSdlFPoint>;
    FSpreads: TArray<Single>;
    FWeights: TArray<Single>;
    FPointCount: Integer;
    FVertices: TArray<TSdlVertex>;
    FVertexCount: Integer;
    FIndices: TArray<Integer>;
    FIndexCount: Integer;
    function GetInhaling: Boolean;
    function MatterAt(AX, AY: Single): Boolean;
    procedure Strike(ACenter: TSdlFPoint);
    procedure LaunchRays;
    procedure ThrowMotes;
    procedure FlyRays;
    procedure FlyRay(var ARay: TBurstRay);
    procedure LookForFace(var ARay: TBurstRay; AX, AY, ANextX, ANextY: Single);
    procedure AddPoint(AX, AY, ASpread, AWeight: Single);
    procedure LayRay(const ARay: TBurstRay; AOrigin: TSdlPoint; AAlpha: Single);
    procedure LayRing(AOrigin: TSdlPoint; AShare: Single);
    procedure AppendStrip(const ABand: TBurstBand);
    procedure FlushBand(const ACanvas: TDynamicCanvas; const ABand: TBurstBand);
    procedure DrawRayBands(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single; const ABands: array of TBurstBand);
    procedure DrawLaidBands(const ACanvas: TDynamicCanvas;
      const ABands: array of TBurstBand);
    procedure DrawRays(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawRing(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AShare: Single);
    procedure DrawMarks(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawMotes(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  public
    // ABody is asked once a burst, at the strike: the motes come out of
    // the points it gives; with none they come out of the chest
    constructor Create(const ABody: TBodyProbe);
    destructor Destroy; override;
    // The inhale begins about the hero's center: the world is to stand
    // InhaleTicks, then the strike. One already going is dropped.
    procedure Start(const ALook: TBurstLook; ACurl: Boolean;
      ACenter: TSdlFPoint; const AMatter: TMatter);
    // Once a tick, with the hero's center where the tick has left it
    procedure Tick(ACenter: TSdlFPoint);
    // What has come to pass since the last call
    function DrainEvent: TBurstEvent;
    procedure Clear;
    // The stretches the heads passed this tick
    function Stretches: TArray<TBurstStretch>;
    // Over the world under the hero, through the inhale: the veil
    procedure DrawVeil(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint);
    // The hero as a bare figure, through the inhale, in his place
    procedure DrawSilhouette(const ACanvas: TDynamicCanvas;
      const AFigure: TBurstFigure);
    // The marks, the rays, the ring, the motes
    procedure DrawWorld(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // The flash, on the glass: no shake
    procedure DrawGlass(const ACanvas: TDynamicCanvas; AAlpha: Single);
    // The inhale: the world stands
    property Holding: Boolean read GetInhaling;
    // The inhale: the hero is drawn as a bare figure
    property Inhaling: Boolean read GetInhaling;
    // The marks left on the faces and the motes of the echo, as they are
    // now: to be read, not stirred
    property Marks: TParticleSwarm read FMarks;
    property Motes: TParticleSwarm read FMotes;
  end;

const
  InhaleTicks = 2;

  IceBurstLook: TBurstLook = (
    Glow: (R: 150; G: 225; B: 255); Core: (R: 255; G: 255; B: 255);
    Dark: False; Flash: (R: 200; G: 240; B: 255);
    Veil: (R: 2; G: 5; B: 12); VeilLevel: 0.82;
    Silhouette: (R: 255; G: 255; B: 255); Mote: (R: 200; G: 240; B: 255));
  MoonBurstLook: TBurstLook = (
    Glow: (R: 225; G: 212; B: 255); Core: (R: 6; G: 0; B: 14);
    Dark: True; Flash: (R: 225; G: 212; B: 255);
    Veil: (R: 235; G: 232; B: 245); VeilLevel: 0.88;
    Silhouette: (R: 6; G: 0; B: 14); Mote: (R: 6; G: 0; B: 14));

implementation

uses
  System.Math, Render.Glow, Render.Sprites, Game.Space;

const
  RayCount = 24;
  RaySpeed = 20; // units a tick
  RayTail = 170; // units, along the head's way
  // A ray is gone once its head is this far from the hero's center: its
  // whole tail is off the screen
  RayReach = 420 + RayTail;
  // Units: the head looks for a face this often, and the curl turns it
  // this often
  RayStep: Single = 2;
  // A vortex's rays turn this many radians a tick, and less by e for every
  // CurlFade units flown
  CurlTurn = 0.06;
  CurlFade = 220;
  // A ray's strength along it, 0 at the tail and 1 at the head: it climbs
  // as the share to this power, and over the last of the length it thins
  // out by this share at the head
  ProfilePower: Single = 0.7;
  ProfileKnee = 0.8;
  ProfileThinning = 0.6;
  // Units between the points a ray is laid on
  RaySampleStep = 4;

  // The rays and the ring leave from the chest, this far from the middle
  // of the body
  ChestY = -2;

  RingTicks = 13;
  // Units: the ring's radius at the strike and what it runs out by. It is
  // seen from above a little: its height is this share of its width.
  RingStart = 8;
  RingRun = 250;
  RingFlatness = 0.86;
  RingFadePower: Single = 1.5;
  RingPoints = 96;

  FlashTicks = 4;
  FlashLevel = 0.5;

  // A mark: units across when grown, the ticks it grows in, the ticks it
  // shows in and its whole life; its white heart - or its dark body - is
  // this share of its width
  MarkAcross = 18;
  MarkGrowTicks = 6;
  MarkShowTicks = 4;
  MarkTicks = 130;
  MarkLevel = 0.85;
  MarkHeartShare = 0.6;

  MoteCount = 56;
  // A mote leaves its point of the body away from the center, up to half
  // of this many radians off either way, at the base speed and up to the
  // spread more, units a tick, and this much faster up
  MoteScatter = 1;
  MoteSpeedBase = 0.6;
  MoteSpeedSpread = 2.4;
  MoteRise = 0.4;
  MoteDrag = 0.93; // of its speed a tick keeps
  MotePull = 0.035; // units a tick per tick, down
  MoteLifeBase = 70;
  MoteLifeSpread = 50;
  MoteSizeBase = 1; // units on a side
  MoteSizeSpread = 1.4;

  // The light about a light figure through the inhale: a cone of 46 units
  // to its edge, here a glow as wide at half its light
  InhaleGlowAcross = 130;
  InhaleGlowLevel = 0.35;
  // A light figure doubles at its edges: red to the left, blue to the
  // right, this many units aside
  FringeShift = 1.5;
  FringeLevel = 0.7;
  FringeLeft: TRgb = (R: 255; G: 60; B: 90);
  FringeRight: TRgb = (R: 60; G: 200; B: 255);

  StartVertices = 1024;

  DiceSeed = $42757273; // "Burs"

  LightRayBands: array [0..2] of TOrbBurst.TBurstBand = (
    (Width: 8; Swell: 12; Level: 0.10; Body: False),
    (Width: 3; Swell: 5; Level: 0.28; Body: False),
    (Width: 0.6; Swell: 1.2; Level: 0.35; Body: True));
  DarkRayBands: array [0..2] of TOrbBurst.TBurstBand = (
    (Width: 10; Swell: 14; Level: 0.18; Body: False),
    (Width: 4; Swell: 7; Level: 0.45; Body: False),
    (Width: 0.8; Swell: 2.2; Level: 0.90; Body: True));
  LightRingBands: array [0..0] of TOrbBurst.TBurstBand = (
    (Width: 1; Swell: 6; Level: 0.8; Body: False));
  DarkRingBands: array [0..1] of TOrbBurst.TBurstBand = (
    (Width: 4; Swell: 8; Level: 0.85; Body: False),
    (Width: 1; Swell: 4; Level: 0.90; Body: True));

function UpToOne(AShare: Single): Single;
begin
  Result := AShare;
  if Result > 1 then
    Result := 1;
end;

function Profile(AShare: Single): Single;
begin
  Result := Power(AShare, ProfilePower);
  if AShare > ProfileKnee then
    Result := Result * (1 - ProfileThinning * (AShare - ProfileKnee) /
      (1 - ProfileKnee));
end;

// The point ADistance units back from the head as drawn, along the way the
// head has come
function TrailPoint(const ATrack: TArray<TSdlFPoint>; AHead: TSdlFPoint;
  ADistance: Single): TSdlFPoint;
begin
  var Front := AHead;
  var Left := ADistance;
  for var i := High(ATrack) downto 0 do
  begin
    var Back := ATrack[i];
    var Span: Single := Hypot(Back.X - Front.X, Back.Y - Front.Y);
    if (Span > 0) and (Span >= Left) then
    begin
      Result.X := Front.X + (Back.X - Front.X) * Left / Span;
      Result.Y := Front.Y + (Back.Y - Front.Y) * Left / Span;
      Exit;
    end;
    Left := Left - Span;
    Front := Back;
  end;
  Result := Front;
end;

function OnScreen(AX, AY: Single): Boolean;
begin
  Result := (AX >= 0) and (AX < ScreenWidth) and (AY >= 0) and
    (AY < ScreenHeight);
end;

function FullFrame: TSdlFRect;
begin
  Result.X := 0;
  Result.Y := 0;
  Result.W := FrameWidth;
  Result.H := FrameHeight;
end;

// A fill of the whole frame, laid over what is beneath; the renderer's
// draw mode goes back to opaque, which the rest of the game draws in
procedure FillFrame(ARenderer: PSdlRenderer; ATint: TRgb; ALevel: Single);
begin
  var Frame := FullFrame;
  SDL_SetRenderDrawBlendMode(ARenderer, SdlBlendModeBlend);
  SDL_SetRenderDrawColor(ARenderer, ATint.R, ATint.G, ATint.B,
    Round(255 * EnsureRange(ALevel, 0.0, 1.0)));
  SDL_RenderFillRectF(ARenderer, @Frame);
  SDL_SetRenderDrawBlendMode(ARenderer, SdlBlendModeNone);
end;

function FlipFlag(AMirrored: Boolean): Integer;
begin
  if AMirrored then
    Result := SdlFlipHorizontal
  else
    Result := SdlFlipNone;
end;

// The figure AShiftX units aside, in the tint, as its mask's mode has it
procedure PaintFigure(ARenderer: PSdlRenderer; const AFigure: TBurstFigure;
  AShiftX: Single; ATint: TRgb; ALevel: Single);
begin
  var Dest := AFigure.Frame;
  Dest.X := Dest.X + AShiftX;
  SDL_SetTextureColorMod(AFigure.Mask, ATint.R, ATint.G, ATint.B);
  SDL_SetTextureAlphaMod(AFigure.Mask,
    Round(255 * EnsureRange(ALevel, 0.0, 1.0)));
  SDL_RenderCopyExF(ARenderer, AFigure.Mask, nil, @Dest, 0.0, nil,
    FlipFlag(AFigure.Mirrored));
end;

// DrawGlow laid over what is beneath instead of added: the glow texture
// adds by its make, and is put back
procedure DrawGlowOver(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  ACenterX, ACenterY, ASize: Single; ATint: TRgb; ALevel: Single);
begin
  SDL_SetTextureBlendMode(ATexture, SdlBlendModeBlend);
  DrawGlow(ARenderer, ATexture, ACenterX, ACenterY, ASize, ATint, ALevel);
  SDL_SetTextureBlendMode(ATexture, SdlBlendModeAdd);
end;

// ---------------------------------------------------------------------------
// TOrbBurst
// ---------------------------------------------------------------------------

constructor TOrbBurst.Create(const ABody: TBodyProbe);
begin
  inherited Create;
  FBodyOf := ABody;
  FMarks := TParticleSwarm.Create;
  FMotes := TParticleSwarm.Create;
  FRandom.Seed := DiceSeed;
  SetLength(FVertices, StartVertices);
  SetLength(FIndices, StartVertices * 3);
end;

destructor TOrbBurst.Destroy;
begin
  FMotes.Free;
  FMarks.Free;
  inherited;
end;

function TOrbBurst.GetInhaling: Boolean;
begin
  Result := FInhaleLeft > 0;
end;

// Matter on the screen: a solid cell or the body of a pad. Off the screen
// there is none.
function TOrbBurst.MatterAt(AX, AY: Single): Boolean;
begin
  if not OnScreen(AX, AY) then
    Exit(False);
  if FMatter.Cells[Trunc(AY / TileSize), Trunc(AX / TileSize)] then
    Exit(True);
  for var Body in FMatter.Bodies do
    if (AX >= Body.X) and (AX < Body.X + Body.W) and (AY >= Body.Y) and
      (AY < Body.Y + Body.H) then
      Exit(True);
  Result := False;
end;

procedure TOrbBurst.Start(const ALook: TBurstLook; ACurl: Boolean;
  ACenter: TSdlFPoint; const AMatter: TMatter);
begin
  Clear;
  FLook := ALook;
  FCurl := ACurl;
  FCenter := ACenter;
  FMatter := AMatter;
  FInhaleLeft := InhaleTicks;
end;

procedure TOrbBurst.Clear;
begin
  FInhaleLeft := 0;
  FStruck := False;
  FAge := 0;
  FStrikeUntold := False;
  FRays := nil;
  FStretches := nil;
  FMarks.Clear;
  FMotes.Clear;
end;

procedure TOrbBurst.Tick(ACenter: TSdlFPoint);
begin
  FStretches := nil;
  FMarks.Advance(1, 0, 0);
  FMotes.Advance(MoteDrag, 0, MotePull);
  if FInhaleLeft > 0 then
  begin
    FCenter := ACenter;
    Dec(FInhaleLeft);
    if FInhaleLeft = 0 then
      Strike(ACenter);
  end
  else if FStruck then
    Inc(FAge);
  FlyRays;
end;

procedure TOrbBurst.Strike(ACenter: TSdlFPoint);
begin
  FCenter := ACenter;
  FStruck := True;
  FAge := 0;
  FStrikeUntold := True;
  LaunchRays;
  ThrowMotes;
end;

// Evenly about the chest, the first straight up: the picture is
// symmetrical whatever the pattern was
procedure TOrbBurst.LaunchRays;
begin
  var Chest: TSdlFPoint;
  Chest.X := FCenter.X;
  Chest.Y := FCenter.Y + ChestY;
  SetLength(FRays, RayCount);
  for var k := 0 to RayCount - 1 do
  begin
    FRays[k] := Default(TBurstRay);
    FRays[k].Heading := -Pi / 2 + k * 2 * Pi / RayCount;
    FRays[k].Track := [Chest];
    FRays[k].WasOpen := OnScreen(Chest.X, Chest.Y) and
      not MatterAt(Chest.X, Chest.Y);
  end;
end;

// Out of the points of the body, away from its center, each its own way
procedure TOrbBurst.ThrowMotes;
var
  Mote: TParticle;
begin
  var Body: TBodyPoints := nil;
  if Assigned(FBodyOf) then
    Body := FBodyOf();
  if Length(Body) = 0 then
  begin
    SetLength(Body, 1);
    Body[0].X := FCenter.X;
    Body[0].Y := FCenter.Y + ChestY;
  end;

  Mote := Default(TParticle);
  for var i := 1 to MoteCount do
  begin
    var Place := Body[Trunc(FRandom.NextUnit * Length(Body))];
    var Heading: Single := ArcTan2(Place.Y - FCenter.Y, Place.X - FCenter.X) +
      MoteScatter * (FRandom.NextUnit - 0.5);
    var Speed: Single := MoteSpeedBase + FRandom.NextUnit * MoteSpeedSpread;
    Mote.X := Place.X;
    Mote.Y := Place.Y;
    Mote.SpeedX := Cos(Heading) * Speed;
    Mote.SpeedY := Sin(Heading) * Speed - MoteRise;
    Mote.Life := MoteLifeBase + Trunc(FRandom.NextUnit * MoteLifeSpread);
    Mote.Scale := MoteSizeBase + FRandom.NextUnit * MoteSizeSpread;
    FMotes.Add(Mote);
  end;
end;

procedure TOrbBurst.FlyRays;
begin
  for var i := 0 to High(FRays) do
    if not FRays[i].Gone then
      FlyRay(FRays[i]);
end;

// A tick of flight in short steps: matter is no stop to a ray, but where
// it goes into a face it leaves its mark
procedure TOrbBurst.FlyRay(var ARay: TBurstRay);
var
  Stretch: TBurstStretch;
begin
  var From := ARay.Track[High(ARay.Track)];
  var X: Single := From.X;
  var Y: Single := From.Y;
  var Left: Single := RaySpeed;
  while Left > 0 do
  begin
    var Step: Single := Min(RayStep, Left);
    Left := Left - Step;
    if FCurl then
      ARay.Heading := ARay.Heading +
        CurlTurn * Step / RaySpeed * Exp(-ARay.Flown / CurlFade);
    var NextX: Single := X + Cos(ARay.Heading) * Step;
    var NextY: Single := Y + Sin(ARay.Heading) * Step;
    LookForFace(ARay, X, Y, NextX, NextY);
    X := NextX;
    Y := NextY;
    ARay.Flown := ARay.Flown + Step;
  end;

  var Head: TSdlFPoint;
  Head.X := X;
  Head.Y := Y;
  ARay.Track := ARay.Track + [Head];
  Stretch.FromX := From.X;
  Stretch.FromY := From.Y;
  Stretch.ToX := X;
  Stretch.ToY := Y;
  FStretches := FStretches + [Stretch];
  ARay.Gone := Hypot(X - FCenter.X, Y - FCenter.Y) > RayReach;
end;

// From the open into matter on the screen: the mark goes on the last point
// in the open
procedure TOrbBurst.LookForFace(var ARay: TBurstRay; AX, AY, ANextX,
  ANextY: Single);
var
  Mark: TParticle;
begin
  if ARay.WasOpen and MatterAt(ANextX, ANextY) then
  begin
    Mark := Default(TParticle);
    Mark.X := AX;
    Mark.Y := AY;
    Mark.Life := MarkTicks;
    FMarks.Add(Mark);
  end;
  ARay.WasOpen := OnScreen(ANextX, ANextY) and not MatterAt(ANextX, ANextY);
end;

function TOrbBurst.DrainEvent: TBurstEvent;
begin
  Result := beNone;
  if not FStrikeUntold then
    Exit;
  FStrikeUntold := False;
  Result := beStruck;
end;

function TOrbBurst.Stretches: TArray<TBurstStretch>;
begin
  Result := FStretches;
end;

// ---------------------------------------------------------------------------
// Bands: a ray and the ring are strips of triangles along their points,
// the band texture (gsBeam) across them, bright in the middle
// ---------------------------------------------------------------------------

procedure TOrbBurst.AddPoint(AX, AY, ASpread, AWeight: Single);
begin
  if FPointCount = Length(FPoints) then
  begin
    var Room := Max(64, 2 * Length(FPoints));
    SetLength(FPoints, Room);
    SetLength(FSpreads, Room);
    SetLength(FWeights, Room);
  end;
  FPoints[FPointCount].X := AX;
  FPoints[FPointCount].Y := AY;
  FSpreads[FPointCount] := ASpread;
  FWeights[FPointCount] := AWeight;
  Inc(FPointCount);
end;

// The ray from its tail to its head, the head drawn on ahead between the
// ticks; the band swells and strengthens with the profile
procedure TOrbBurst.LayRay(const ARay: TBurstRay; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FPointCount := 0;
  var Last := ARay.Track[High(ARay.Track)];
  var Ahead: Single := RaySpeed * AAlpha;
  var Head: TSdlFPoint;
  Head.X := Last.X + Cos(ARay.Heading) * Ahead;
  Head.Y := Last.Y + Sin(ARay.Heading) * Ahead;
  var TailLength: Single := ARay.Flown + Ahead;
  if TailLength > RayTail then
    TailLength := RayTail;
  if TailLength <= 0 then
    Exit;

  var Steps := Max(1, Ceil(TailLength / RaySampleStep));
  for var i := Steps downto 0 do
  begin
    var Back: Single := TailLength * i / Steps;
    var Place := TrailPoint(ARay.Track, Head, Back);
    var Strength := Profile(1 - Back / TailLength);
    AddPoint(AOrigin.X + Place.X, AOrigin.Y + Place.Y, Strength, Strength);
  end;
end;

// The ring all the way round, AShare of its life gone: the band thins and
// fades as it runs out
procedure TOrbBurst.LayRing(AOrigin: TSdlPoint; AShare: Single);
begin
  FPointCount := 0;
  var Rest: Single := 1 - AShare;
  var Radius: Single := RingStart + RingRun * (1 - Rest * Rest * Rest);
  var Fade: Single := Power(Rest, RingFadePower);
  var MiddleX: Single := AOrigin.X + FCenter.X;
  var MiddleY: Single := AOrigin.Y + FCenter.Y + ChestY;
  for var i := 0 to RingPoints do
  begin
    var Turn: Single := 2 * Pi * i / RingPoints;
    AddPoint(MiddleX + Radius * Cos(Turn),
      MiddleY + Radius * RingFlatness * Sin(Turn), Rest, Fade);
  end;
end;

// The laid points as a strip, two corners at each
procedure TOrbBurst.AppendStrip(const ABand: TBurstBand);
begin
  if FPointCount < 2 then
    Exit;
  if FVertexCount + 2 * FPointCount > Length(FVertices) then
    SetLength(FVertices, Max(FVertexCount + 2 * FPointCount,
      2 * Length(FVertices)));
  if FIndexCount + 6 * FPointCount > Length(FIndices) then
    SetLength(FIndices, Max(FIndexCount + 6 * FPointCount,
      2 * Length(FIndices)));

  var Tint := FLook.Glow;
  if ABand.Body then
    Tint := FLook.Core;
  var FirstCorner := FVertexCount;
  for var k := 0 to FPointCount - 1 do
  begin
    var Before := FPoints[Max(k - 1, 0)];
    var After := FPoints[Min(k + 1, FPointCount - 1)];
    var SpanX: Single := After.X - Before.X;
    var SpanY: Single := After.Y - Before.Y;
    var Span: Single := Hypot(SpanX, SpanY);
    var NormalX: Single := 0;
    var NormalY: Single := 1;
    if Span > 0 then
    begin
      NormalX := -SpanY / Span;
      NormalY := SpanX / Span;
    end;
    var Half: Single := (ABand.Width + ABand.Swell * FSpreads[k]) / 2;
    var Alpha: UInt8 := Round(255 * EnsureRange(ABand.Level * FWeights[k],
      0.0, 1.0));

    for var Side := 0 to 1 do
    begin
      var Sign: Single := 1 - 2 * Side;
      FVertices[FVertexCount].Position.X := FPoints[k].X + Sign * NormalX * Half;
      FVertices[FVertexCount].Position.Y := FPoints[k].Y + Sign * NormalY * Half;
      FVertices[FVertexCount].Color.R := Tint.R;
      FVertices[FVertexCount].Color.G := Tint.G;
      FVertices[FVertexCount].Color.B := Tint.B;
      FVertices[FVertexCount].Color.A := Alpha;
      FVertices[FVertexCount].TexCoord.X := 0.5;
      FVertices[FVertexCount].TexCoord.Y := Side;
      Inc(FVertexCount);
    end;
  end;

  for var k := 0 to FPointCount - 2 do
  begin
    var Corner := FirstCorner + 2 * k;
    FIndices[FIndexCount] := Corner;
    FIndices[FIndexCount + 1] := Corner + 1;
    FIndices[FIndexCount + 2] := Corner + 2;
    FIndices[FIndexCount + 3] := Corner + 1;
    FIndices[FIndexCount + 4] := Corner + 3;
    FIndices[FIndexCount + 5] := Corner + 2;
    Inc(FIndexCount, 6);
  end;
end;

// Every strip of the band in one go. The band texture adds by its make; a
// dark body is laid over instead, and the texture is put back.
procedure TOrbBurst.FlushBand(const ACanvas: TDynamicCanvas;
  const ABand: TBurstBand);
begin
  if FIndexCount > 0 then
  begin
    var Over := ABand.Body and FLook.Dark;
    if Over then
      SDL_SetTextureBlendMode(ACanvas.BeamGlow, SdlBlendModeBlend);
    SDL_RenderGeometry(ACanvas.Renderer, ACanvas.BeamGlow, @FVertices[0],
      FVertexCount, @FIndices[0], FIndexCount);
    if Over then
      SDL_SetTextureBlendMode(ACanvas.BeamGlow, SdlBlendModeAdd);
  end;
  FVertexCount := 0;
  FIndexCount := 0;
end;

procedure TOrbBurst.DrawRayBands(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single; const ABands: array of TBurstBand);
begin
  for var Band in ABands do
  begin
    for var Ray in FRays do
    begin
      if Ray.Gone then
        Continue;
      LayRay(Ray, AOrigin, AAlpha);
      AppendStrip(Band);
    end;
    FlushBand(ACanvas, Band);
  end;
end;

// The points laid once, a strip of them for every band
procedure TOrbBurst.DrawLaidBands(const ACanvas: TDynamicCanvas;
  const ABands: array of TBurstBand);
begin
  for var Band in ABands do
  begin
    AppendStrip(Band);
    FlushBand(ACanvas, Band);
  end;
end;

procedure TOrbBurst.DrawRays(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  if FLook.Dark then
    DrawRayBands(ACanvas, AOrigin, AAlpha, DarkRayBands)
  else
    DrawRayBands(ACanvas, AOrigin, AAlpha, LightRayBands);
end;

// AShare - of the ring's life gone, 0..1
procedure TOrbBurst.DrawRing(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AShare: Single);
begin
  LayRing(AOrigin, AShare);
  if FLook.Dark then
    DrawLaidBands(ACanvas, DarkRingBands)
  else
    DrawLaidBands(ACanvas, LightRingBands);
end;

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

// A mark shows in a few ticks, grows a few more and melts through the
// rest of its life: a glow with a white heart, or with a dark body
procedure TOrbBurst.DrawMarks(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Renderer := ACanvas.Renderer;
  var PointGlow := ACanvas.PointGlow;
  for var i := 0 to FMarks.Count - 1 do
  begin
    var Mark := FMarks[i];
    var Since: Single := Mark.Age + AAlpha;
    var Shown: Single := Since / MarkShowTicks;
    if Since >= MarkShowTicks then
      Shown := 1 - (Since - MarkShowTicks) / (MarkTicks - MarkShowTicks);
    var Level: Single := MarkLevel * Shown;
    var Across: Single := MarkAcross * UpToOne(Since / MarkGrowTicks);
    var X: Single := AOrigin.X + Mark.X;
    var Y: Single := AOrigin.Y + Mark.Y;
    var Heart: Single := Across * MarkHeartShare;
    DrawGlow(Renderer, PointGlow, X, Y, Across, FLook.Glow, Level);
    if FLook.Dark then
      DrawGlowOver(Renderer, PointGlow, X, Y, Heart, FLook.Core, Level)
    else
      DrawGlow(Renderer, PointGlow, X, Y, Heart, FLook.Core, Level);
  end;
end;

// A mote is a speck, added on, or laid over on a dark look
procedure TOrbBurst.DrawMotes(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
var
  Speck: TSdlFRect;
begin
  if FMotes.Count = 0 then
    Exit;
  var Renderer := ACanvas.Renderer;
  if FLook.Dark then
    SDL_SetRenderDrawBlendMode(Renderer, SdlBlendModeBlend)
  else
    SDL_SetRenderDrawBlendMode(Renderer, SdlBlendModeAdd);
  for var i := 0 to FMotes.Count - 1 do
  begin
    var Mote := FMotes[i];
    var Fade: Single := 1 - (Mote.Age + AAlpha) / Mote.Life;
    Speck.W := Mote.Scale;
    Speck.H := Mote.Scale;
    Speck.X := AOrigin.X + Mote.X + Mote.SpeedX * AAlpha - Mote.Scale / 2;
    Speck.Y := AOrigin.Y + Mote.Y + Mote.SpeedY * AAlpha - Mote.Scale / 2;
    SDL_SetRenderDrawColor(Renderer, FLook.Mote.R, FLook.Mote.G, FLook.Mote.B,
      Round(255 * EnsureRange(Fade, 0.0, 1.0)));
    SDL_RenderFillRectF(Renderer, @Speck);
  end;
  SDL_SetRenderDrawBlendMode(Renderer, SdlBlendModeNone);
end;

procedure TOrbBurst.DrawVeil(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint);
begin
  if not Inhaling then
    Exit;
  FillFrame(ACanvas.Renderer, FLook.Veil, FLook.VeilLevel);
  if FLook.Dark then
    Exit;
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AOrigin.X + FCenter.X,
    AOrigin.Y + FCenter.Y, InhaleGlowAcross, White, InhaleGlowLevel);
end;

// A light figure is white, doubled into red and blue at its edges; a dark
// one is the plain shape. The mask adds by its make: a figure is laid over,
// and the mask is put back.
procedure TOrbBurst.DrawSilhouette(const ACanvas: TDynamicCanvas;
  const AFigure: TBurstFigure);
begin
  if AFigure.Mask = nil then
    Exit;
  var Renderer := ACanvas.Renderer;
  if not FLook.Dark then
  begin
    PaintFigure(Renderer, AFigure, -FringeShift, FringeLeft, FringeLevel);
    PaintFigure(Renderer, AFigure, FringeShift, FringeRight, FringeLevel);
  end;
  SDL_SetTextureBlendMode(AFigure.Mask, SdlBlendModeBlend);
  PaintFigure(Renderer, AFigure, 0, FLook.Silhouette, 1);
  SDL_SetTextureBlendMode(AFigure.Mask, SdlBlendModeAdd);
end;

procedure TOrbBurst.DrawWorld(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  if not FStruck then
    Exit;
  var Since: Single := FAge + AAlpha;
  DrawMarks(ACanvas, AOrigin, AAlpha);
  DrawRays(ACanvas, AOrigin, AAlpha);
  if Since < RingTicks then
    DrawRing(ACanvas, AOrigin, Since / RingTicks);
  DrawMotes(ACanvas, AOrigin, AAlpha);
end;

procedure TOrbBurst.DrawGlass(const ACanvas: TDynamicCanvas; AAlpha: Single);
begin
  if not FStruck then
    Exit;
  var Spent: Single := (FAge + AAlpha) / FlashTicks;
  if Spent >= 1 then
    Exit;
  FillFrame(ACanvas.Renderer, FLook.Flash, FlashLevel * (1 - Spent));
end;

end.
