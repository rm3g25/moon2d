{
  Effects.Lightning - lightning: a crooked channel of light that strikes
  between two points in a blink, throws branches, and fades.

  A bolt is a trunk and its branches. Each part is a straight axis with a
  sideways offset at every point, found by splitting the axis in halves
  and pushing every middle aside, by half as much at each generation. The
  first generations and every decision about branches are rolled from one
  seed, the last two generations from another: a bolt that strikes again
  keeps its big picture and branches and only shivers along the channel.

  A bolt lives in order: a dim leader feels its way from the root to the
  end, then the first stroke lights the whole channel at once, and at
  most a few strokes follow it down the same channel.

  A field holds the bolts of one source. Who shoots, where and when, and
  where a bolt ends against the walls, is the owner's business; the
  texture comes with every draw, so the field owns none and the unit
  knows no level.

  Pure decoration: a bolt wounds nobody.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Effects.Lightning;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush;

const
  MaxBoltStrokes = 8;

type
  // The trunk or a branch: the points it passes along its axis. Both
  // ends of the offsets are zero; they are measured across the axis, so
  // a channel never turns back on itself.
  TBoltLimb = record
    Parent: Integer; // -1 for the trunk
    Base: Integer; // the parent's point it leaves from
    Lean: Single; // radians off the parent's axis
    Length: Single;
    Width, Level: Single; // shares of the trunk's
    Tapers: Boolean;
    Offsets: TArray<Single>;
  end;
  TBoltShape = TArray<TBoltLimb>;

  // How a bolt ends: a bridge to a second point, a strike on a wall, a
  // short stream into the air
  TBoltEnd = (beBridge, beStrike, beStreamer);

  // Widths and lengths in units, times in ticks, the rest shares, 0..1
  TBoltLook = record
    Width, Jag, ForkChance, Flash, Jolt: Single;
    LifeTicks, LeaderTicks, Strokes: Integer;
    Tint: TRgb;
  end;

  TBoltShot = record
    RootX, RootY, EndX, EndY: Single; // in the field's frame
    Ending: TBoltEnd; // beStrike: the end stays put while the frame moves
    Seed: Cardinal;
  end;

  // The band (gsBeam) the channel lies on and the point (gsPoint) the
  // lights at its ends are, both from Render.Glow
  TBoltBrush = record
    Renderer: PSdlRenderer;
    Beam: PSdlTexture;
    Glow: PSdlTexture;
  end;

// ALength is the trunk's. The same seeds and the same arguments give the
// same shape.
function BuildBoltShape(ALength, AJag, AForkChance: Single;
  ACoarseSeed, AFineSeed: Cardinal; ATapers: Boolean): TBoltShape;
function BoltBrush(ARenderer: PSdlRenderer; ABeam, AGlow: PSdlTexture): TBoltBrush;

type
  TBoltField = class
  private type
    TBolt = record
      Shot: TBoltShot;
      Look: TBoltLook;
      Shape: TBoltShape;
      BuiltLength: Single; // of the trunk, when the shape was made
      Age: Integer;
      Stroke: Integer; // the one under way; -1 while the leader goes
      StrokeCount: Integer;
      Starts: array [0..MaxBoltStrokes - 1] of Integer;
      Levels: array [0..MaxBoltStrokes - 1] of Single;
    end;

    // Where a limb stands in the frame being drawn. Growth: the share of
    // it the leader has reached; Appears: how far along the leader the
    // limb begins.
    TLimbPose = record
      Origin, Dir: TSdlFPoint;
      Heading, Length, Appears, Growth: Single;
    end;

    TBoltPass = record
      Width: Single; // of the trunk
      Tint: TRgb;
      Level: Single;
      EveryPoint: Boolean;
    end;
  private
    FBolts: TArray<TBolt>;
    FCount: Integer;
    FJolt: Single;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    // What the frame being drawn is made of
    FDrawn: TBoltShape;
    FPoses: TArray<TLimbPose>;
    FSamples: TArray<TSdlFPoint>;
    FSampleAt: TArray<Single>;
    FVertices: TArray<TSdlVertex>;
    FVertexCount: Integer;
    FIndices: TArray<Integer>;
    FIndexCount: Integer;
    procedure Add(const ABolt: TBolt);
    procedure StartDueStrokes(var ABolt: TBolt);
    function PointOf(const APose: TLimbPose; const AOffsets: TArray<Single>;
      APosition: Single): TSdlFPoint;
    procedure PlaceLimbs(const ABolt: TBolt; const AOrigin: TSdlFPoint;
      AGrowth: Single);
    procedure EnsureRoom(AVertices, AIndices: Integer);
    procedure AppendLimb(const APass: TBoltPass; AIndex: Integer);
    procedure DrawPass(const ABrush: TBoltBrush; const APass: TBoltPass);
    procedure DrawLeader(const ABrush: TBoltBrush; const ABolt: TBolt;
      const AOrigin: TSdlFPoint; ATime: Single);
    procedure DrawStroke(const ABrush: TBoltBrush; const ABolt: TBolt;
      const AOrigin: TSdlFPoint; ATime: Single);
  public
    // A field past ACapacity drops its oldest bolt
    constructor Create(ACapacity: Integer; ASeed: Cardinal);
    procedure Shoot(const AShot: TBoltShot; const ALook: TBoltLook);
    // The owner's frame moved by (ADX, ADY). A bolt that struck a wall
    // keeps its end where it is on the screen and its channel stretches;
    // any other rides with the frame.
    procedure ShiftFrame(ADX, ADY: Single);
    procedure Tick;
    // The jolt of the strokes that began since the last ask; asking
    // empties it
    function TakeJolt: Single;
    // AOrigin - where the field's zero stands on the screen; AAlpha is
    // the timestep's, for the light between ticks
    procedure Draw(const ABrush: TBoltBrush; const AOrigin: TSdlFPoint;
      AAlpha: Single);
    procedure Clear;
    property Count: Integer read FCount;
  end;

implementation

uses
  System.Math, Render.Glow;

type
  // The three passes a stroke is drawn in, widest first
  TBoltBand = (bbHalo, bbGlow, bbCore);

  TBoltLayer = record
    Width: Single; // times the look's, across the channel
    Level: Single;
    Decay: Single; // power of what is left of the stroke's life
    Whiteness: Single; // share of the tint mixed toward white
    Bloom: Single; // extra width on the first tick
    EveryPoint: Boolean;
  end;

  // The light at a point of a bolt: the tinted halo and the white core
  TBoltLight = record
    Tint: TRgb;
    Width: Single;
    TintLevel, WhiteLevel: Single;
  end;

  // How wide the two lights of a point are, in units times the look's
  // width
  TBoltSpot = record
    Halo, Core: Single;
  end;

  TBoltForge = record
    Coarse, Fine: TXorShift;
    Jag, ForkChance: Single;
    Limbs: TBoltShape;
    function DepthOf(AIndex: Integer): Integer;
    procedure Grow(var ALimb: TBoltLimb);
    procedure Add(ALimb: TBoltLimb);
    procedure TryFork(AParent: Integer; AChance: Single);
    procedure ForkOff(AParent: Integer);
  end;

const
  // The shape. A piece of channel is about this long; a limb is split in
  // halves down to it
  PieceLength = 2.5;
  LnTwo = 0.693147180559945;
  MinGenerations = 1;
  MaxGenerations = 7;
  FineGenerations = 2;
  // A branch of the trunk may have a branch, and no more
  MaxForkDepth = 2;
  ForkSpacing = 36; // units of limb to one try at a branch
  MaxForkAttempts = 5;
  SubForkChanceShare = 0.5;
  ForkAlongMin = 0.12;
  ForkAlongMax = 0.75;
  ForkLeanMin = 18; // degrees
  ForkLeanMax = 44;
  ForkLengthMin = 0.3; // of what is left of the parent
  ForkLengthMax = 0.7;
  // Typed: Max of a number and a Single is not one call
  MinForkLength: Single = 3;
  ForkWidthShare = 0.55;
  ForkLevelShare = 0.6;
  FineSalt = $46696E65; // "Fine"
  FineWarmUp = 3;

  // The life. A stroke after the first comes this many ticks after the
  // one before it, at this share of the first's light
  RestrikeGapMin = 1;
  RestrikeGapMax = 4;
  RestrikeLevelMin = 0.6;
  RestrikeLevelMax = 0.95;

  // The drawing. A wide pass takes every few points rather than every
  // one: a wide band over a fine zigzag folds onto itself in spikes
  SpikeGuard = 0.3;
  MinSpan = 0.0001;
  MaxSamples = (1 shl MaxGenerations) + 2;
  StartVertices = 256;

  BoltLayers: array [TBoltBand] of TBoltLayer = (
    (Width: 13; Level: 0.38; Decay: 1.2; Whiteness: 0; Bloom: 0;
      EveryPoint: False),
    (Width: 5; Level: 0.7; Decay: 1.6; Whiteness: 0.5; Bloom: 0;
      EveryPoint: False),
    (Width: 2.4; Level: 1; Decay: 2; Whiteness: 1; Bloom: 0.8;
      EveryPoint: True));

  // Lights at the points of a bolt. The room light is a glow this many
  // units across at this share of a strike's.
  EndSpot: TBoltSpot = (Halo: 16; Core: 6);
  StrikeSpot: TBoltSpot = (Halo: 22; Core: 8);
  RoomAcross = 520;
  RoomShare = 0.3;

  // The leader: thin, dim, and a bright point at its tip
  LeaderHaloWidth = 4;
  LeaderCoreWidth = 1.2;
  LeaderLevel = 0.3;
  LeaderTipAcross = 8;
  LeaderTipLevel = 0.8;

function RollBetween(var ADice: TXorShift; AFrom, ATo: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * ADice.NextUnit;
end;

function GenerationsOf(ALength: Single): Integer;
begin
  if ALength <= PieceLength then
    Exit(MinGenerations);
  var Generations: Integer := Round(Ln(ALength / PieceLength) / LnTwo);
  Result := EnsureRange(Generations, MinGenerations, MaxGenerations);
end;

function BoltBrush(ARenderer: PSdlRenderer; ABeam, AGlow: PSdlTexture): TBoltBrush;
begin
  Result.Renderer := ARenderer;
  Result.Beam := ABeam;
  Result.Glow := AGlow;
end;

// The seed of one stroke's fine generations
function FineSeedOf(ACoarseSeed: Cardinal; AStroke: Integer): Cardinal;
var
  Dice: TXorShift;
begin
  Dice.Seed := (ACoarseSeed xor FineSalt) or 1;
  for var i := 1 to AStroke + FineWarmUp do
    Dice.NextUnit;
  Result := Dice.Seed;
end;

// ---------------------------------------------------------------------------
// TBoltForge
// ---------------------------------------------------------------------------

function TBoltForge.DepthOf(AIndex: Integer): Integer;
begin
  Result := 0;
  var Index := AIndex;
  while Limbs[Index].Parent >= 0 do
  begin
    Inc(Result);
    Index := Limbs[Index].Parent;
  end;
end;

procedure TBoltForge.Grow(var ALimb: TBoltLimb);
begin
  var Generations := GenerationsOf(ALimb.Length);
  var Pieces := 1 shl Generations;
  SetLength(ALimb.Offsets, Pieces + 1);
  var CoarseGenerations := Max(0, Generations - FineGenerations);
  var Shift: Single := ALimb.Length * Jag;
  for var Generation := 1 to Generations do
  begin
    var Step := Pieces shr (Generation - 1);
    var First := 0;
    while First < Pieces do
    begin
      var Roll: Single;
      if Generation <= CoarseGenerations then
        Roll := Coarse.NextUnit
      else
        Roll := Fine.NextUnit;
      var Last := First + Step;
      ALimb.Offsets[First + (Step shr 1)] :=
        (ALimb.Offsets[First] + ALimb.Offsets[Last]) / 2 + (2 * Roll - 1) * Shift;
      First := Last;
    end;
    Shift := Shift / 2;
  end;
end;

procedure TBoltForge.Add(ALimb: TBoltLimb);
begin
  Grow(ALimb);
  Limbs := Limbs + [ALimb];
end;

procedure TBoltForge.TryFork(AParent: Integer; AChance: Single);
begin
  // Every try rolls all its dice, the passed and the failed alike: a
  // branch that comes or goes must not shift the ones after it
  var Luck := Coarse.NextUnit;
  var Along := RollBetween(Coarse, ForkAlongMin, ForkAlongMax);
  var LeanDegrees := RollBetween(Coarse, ForkLeanMin, ForkLeanMax);
  var Side := Coarse.NextUnit;
  var Share := RollBetween(Coarse, ForkLengthMin, ForkLengthMax);
  if Luck >= AChance then
    Exit;

  var Parent := Limbs[AParent];
  var Pieces := High(Parent.Offsets);
  var BasePoint: Integer := Round(Along * Pieces);
  var Fork := Default(TBoltLimb);
  Fork.Parent := AParent;
  Fork.Base := EnsureRange(BasePoint, 1, Pieces - 1);
  Fork.Lean := DegToRad(LeanDegrees);
  if Side < 0.5 then
    Fork.Lean := -Fork.Lean;
  var Remaining: Single := Parent.Length * (1 - Fork.Base / Pieces);
  var Longest: Single := Remaining * Share;
  Fork.Length := Max(MinForkLength, Longest);
  Fork.Width := Parent.Width * ForkWidthShare;
  Fork.Level := Parent.Level * ForkLevelShare;
  Fork.Tapers := True;
  Add(Fork);
end;

procedure TBoltForge.ForkOff(AParent: Integer);
begin
  var Depth := DepthOf(AParent);
  if Depth >= MaxForkDepth then
    Exit;
  var Chance := ForkChance;
  if Depth > 0 then
    Chance := Chance * SubForkChanceShare;
  var Spans: Integer := Trunc(Limbs[AParent].Length / ForkSpacing);
  var Attempts := Min(MaxForkAttempts, 1 + Spans);
  for var i := 1 to Attempts do
    TryFork(AParent, Chance);
end;

function BuildBoltShape(ALength, AJag, AForkChance: Single;
  ACoarseSeed, AFineSeed: Cardinal; ATapers: Boolean): TBoltShape;
var
  Forge: TBoltForge;
begin
  Forge := Default(TBoltForge);
  Forge.Coarse.Seed := ACoarseSeed or 1;
  Forge.Fine.Seed := AFineSeed or 1;
  Forge.Jag := AJag;
  Forge.ForkChance := AForkChance;

  var Trunk := Default(TBoltLimb);
  Trunk.Parent := -1;
  Trunk.Length := ALength;
  Trunk.Width := 1;
  Trunk.Level := 1;
  Trunk.Tapers := ATapers;
  Forge.Add(Trunk);

  // Limbs are appended as they are born, so the loop meets the branches
  // of branches too
  var Index := 0;
  while Index < Length(Forge.Limbs) do
  begin
    Forge.ForkOff(Index);
    Inc(Index);
  end;
  Result := Forge.Limbs;
end;

// ---------------------------------------------------------------------------
// TBoltField
// ---------------------------------------------------------------------------

constructor TBoltField.Create(ACapacity: Integer; ASeed: Cardinal);
begin
  inherited Create;
  SetLength(FBolts, Max(1, ACapacity));
  SetLength(FSamples, MaxSamples);
  SetLength(FSampleAt, MaxSamples);
  SetLength(FVertices, StartVertices);
  SetLength(FIndices, StartVertices * 3);
  FRandom.Seed := ASeed or 1;
end;

procedure TBoltField.Add(const ABolt: TBolt);
begin
  if FCount = Length(FBolts) then
  begin
    for var i := 1 to FCount - 1 do
      FBolts[i - 1] := FBolts[i];
    Dec(FCount);
  end;
  FBolts[FCount] := ABolt;
  Inc(FCount);
end;

procedure TBoltField.Shoot(const AShot: TBoltShot; const ALook: TBoltLook);
begin
  var Bolt := Default(TBolt);
  Bolt.Shot := AShot;
  Bolt.Look := ALook;
  Bolt.Look.LifeTicks := Max(1, ALook.LifeTicks);
  Bolt.BuiltLength := Hypot(AShot.EndX - AShot.RootX, AShot.EndY - AShot.RootY);
  Bolt.StrokeCount := EnsureRange(ALook.Strokes, 1, MaxBoltStrokes);
  Bolt.Stroke := -1;
  Bolt.Starts[0] := Max(0, ALook.LeaderTicks);
  Bolt.Levels[0] := 1;
  for var i := 1 to Bolt.StrokeCount - 1 do
  begin
    var Gap: Integer := RestrikeGapMin +
      Trunc(FRandom.NextUnit * (RestrikeGapMax - RestrikeGapMin + 1));
    Bolt.Starts[i] := Bolt.Starts[i - 1] + Gap;
    Bolt.Levels[i] := RollBetween(FRandom, RestrikeLevelMin, RestrikeLevelMax);
  end;
  Bolt.Shape := BuildBoltShape(Bolt.BuiltLength, ALook.Jag, ALook.ForkChance,
    AShot.Seed, FineSeedOf(AShot.Seed, 0), AShot.Ending = beStreamer);
  StartDueStrokes(Bolt);
  Add(Bolt);
end;

procedure TBoltField.StartDueStrokes(var ABolt: TBolt);
begin
  while (ABolt.Stroke + 1 < ABolt.StrokeCount) and
    (ABolt.Age >= ABolt.Starts[ABolt.Stroke + 1]) do
  begin
    Inc(ABolt.Stroke);
    // The first stroke lights the channel the leader has found
    if ABolt.Stroke > 0 then
      ABolt.Shape := BuildBoltShape(ABolt.BuiltLength, ABolt.Look.Jag,
        ABolt.Look.ForkChance, ABolt.Shot.Seed,
        FineSeedOf(ABolt.Shot.Seed, ABolt.Stroke),
        ABolt.Shot.Ending = beStreamer);
    FJolt := FJolt + ABolt.Look.Jolt * ABolt.Levels[ABolt.Stroke];
  end;
end;

procedure TBoltField.ShiftFrame(ADX, ADY: Single);
begin
  for var i := 0 to FCount - 1 do
  begin
    if FBolts[i].Shot.Ending <> beStrike then
      Continue;
    FBolts[i].Shot.EndX := FBolts[i].Shot.EndX - ADX;
    FBolts[i].Shot.EndY := FBolts[i].Shot.EndY - ADY;
  end;
end;

procedure TBoltField.Tick;
begin
  var Kept := 0;
  for var i := 0 to FCount - 1 do
  begin
    var Bolt := FBolts[i];
    Inc(Bolt.Age);
    StartDueStrokes(Bolt);
    if Bolt.Age >= Bolt.Starts[Bolt.StrokeCount - 1] + Bolt.Look.LifeTicks then
      Continue;
    FBolts[Kept] := Bolt;
    Inc(Kept);
  end;
  // What is left past the kept ones holds shapes no one will draw
  for var i := Kept to FCount - 1 do
    FBolts[i].Shape := nil;
  FCount := Kept;
end;

function TBoltField.TakeJolt: Single;
begin
  Result := FJolt;
  FJolt := 0;
end;

procedure TBoltField.Clear;
begin
  for var i := 0 to FCount - 1 do
    FBolts[i].Shape := nil;
  FCount := 0;
  FJolt := 0;
end;

// The point of a limb at APosition, counted in pieces of its axis
function TBoltField.PointOf(const APose: TLimbPose;
  const AOffsets: TArray<Single>; APosition: Single): TSdlFPoint;
begin
  var Pieces := High(AOffsets);
  var Whole: Integer := Trunc(APosition);
  var Lower := Min(Whole, Pieces);
  var Upper := Min(Lower + 1, Pieces);
  var Fraction: Single := APosition - Lower;
  var Across: Single := AOffsets[Lower] +
    (AOffsets[Upper] - AOffsets[Lower]) * Fraction;
  var Along: Single := APosition / Pieces * APose.Length;
  Result.X := APose.Origin.X + APose.Dir.X * Along - APose.Dir.Y * Across;
  Result.Y := APose.Origin.Y + APose.Dir.Y * Along + APose.Dir.X * Across;
end;

// Parents come before their branches, so a branch finds its parent placed.
// AGrowth is how far the leader has gone, 1 once it is done.
procedure TBoltField.PlaceLimbs(const ABolt: TBolt; const AOrigin: TSdlFPoint;
  AGrowth: Single);
begin
  FDrawn := ABolt.Shape;
  SetLength(FPoses, Length(FDrawn));
  var Shot := ABolt.Shot;
  for var i := 0 to High(FDrawn) do
  begin
    var Pose := Default(TLimbPose);
    var Parent := FDrawn[i].Parent;
    if Parent < 0 then
    begin
      Pose.Origin.X := AOrigin.X + Shot.RootX;
      Pose.Origin.Y := AOrigin.Y + Shot.RootY;
      Pose.Heading := ArcTan2(Shot.EndY - Shot.RootY, Shot.EndX - Shot.RootX);
      Pose.Length := Hypot(Shot.EndX - Shot.RootX, Shot.EndY - Shot.RootY);
    end
    else
    begin
      var ParentPose := FPoses[Parent];
      var ParentPieces := High(FDrawn[Parent].Offsets);
      Pose.Origin := PointOf(ParentPose, FDrawn[Parent].Offsets,
        FDrawn[i].Base);
      Pose.Heading := ParentPose.Heading + FDrawn[i].Lean;
      Pose.Length := FDrawn[i].Length;
      Pose.Appears := ParentPose.Appears +
        (1 - ParentPose.Appears) * FDrawn[i].Base / ParentPieces;
    end;
    Pose.Dir.X := Cos(Pose.Heading);
    Pose.Dir.Y := Sin(Pose.Heading);
    Pose.Growth := EnsureRange((AGrowth - Pose.Appears) / (1 - Pose.Appears),
      0.0, 1.0);
    FPoses[i] := Pose;
  end;
end;

procedure TBoltField.EnsureRoom(AVertices, AIndices: Integer);
begin
  if FVertexCount + AVertices > Length(FVertices) then
    SetLength(FVertices, Max(FVertexCount + AVertices, 2 * Length(FVertices)));
  if FIndexCount + AIndices > Length(FIndices) then
    SetLength(FIndices, Max(FIndexCount + AIndices, 2 * Length(FIndices)));
end;

// One limb as a strip of triangles along its points, two corners at each:
// the band texture lies across it, bright in the middle
procedure TBoltField.AppendLimb(const APass: TBoltPass; AIndex: Integer);
begin
  var Pose := FPoses[AIndex];
  if Pose.Growth <= 0 then
    Exit;
  var Limb := FDrawn[AIndex];
  var Pieces := High(Limb.Offsets);
  var Across := APass.Width * Limb.Width;
  var Stride := 1;
  if not APass.EveryPoint and (Pose.Length > 0) then
  begin
    var Spikes: Integer := Round(Across * SpikeGuard * Pieces / Pose.Length);
    Stride := Max(1, Spikes);
  end;

  // The points a stride apart, and the tip the leader has reached
  var Reach := Pose.Growth * Pieces;
  var Count := 0;
  var Position := 0;
  while Position < Reach do
  begin
    FSamples[Count] := PointOf(Pose, Limb.Offsets, Position);
    FSampleAt[Count] := Position / Pieces;
    Inc(Count);
    Inc(Position, Stride);
  end;
  FSamples[Count] := PointOf(Pose, Limb.Offsets, Reach);
  FSampleAt[Count] := Reach / Pieces;
  Inc(Count);

  EnsureRoom(2 * Count, 6 * (Count - 1));
  var Level: Single := APass.Level * Limb.Level;
  var Alpha: UInt8 := Round(255 * EnsureRange(Level, 0, 1));
  var FirstCorner := FVertexCount;
  for var k := 0 to Count - 1 do
  begin
    var Before := FSamples[Max(k - 1, 0)];
    var After := FSamples[Min(k + 1, Count - 1)];
    var SpanX := After.X - Before.X;
    var SpanY := After.Y - Before.Y;
    var Span := Hypot(SpanX, SpanY);
    var NormalX: Single := 0;
    var NormalY: Single := 1;
    if Span > MinSpan then
    begin
      NormalX := -SpanY / Span;
      NormalY := SpanX / Span;
    end;
    var Half: Single := Across / 2;
    if Limb.Tapers then
      Half := Half * (1 - FSampleAt[k]);

    for var Side := 0 to 1 do
    begin
      var Sign: Single := 1 - 2 * Side;
      var Corner := FVertexCount;
      FVertices[Corner].Position.X := FSamples[k].X + Sign * NormalX * Half;
      FVertices[Corner].Position.Y := FSamples[k].Y + Sign * NormalY * Half;
      FVertices[Corner].Color.R := APass.Tint.R;
      FVertices[Corner].Color.G := APass.Tint.G;
      FVertices[Corner].Color.B := APass.Tint.B;
      FVertices[Corner].Color.A := Alpha;
      FVertices[Corner].TexCoord.X := 0.5;
      FVertices[Corner].TexCoord.Y := Side;
      Inc(FVertexCount);
    end;
  end;

  for var k := 0 to Count - 2 do
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

// Every limb of the placed bolt in one go
procedure TBoltField.DrawPass(const ABrush: TBoltBrush; const APass: TBoltPass);
begin
  FVertexCount := 0;
  FIndexCount := 0;
  for var i := 0 to High(FPoses) do
    AppendLimb(APass, i);
  if FIndexCount = 0 then
    Exit;
  SDL_RenderGeometry(ABrush.Renderer, ABrush.Beam, @FVertices[0],
    FVertexCount, @FIndices[0], FIndexCount);
end;

// ALevel is the stroke's share of the first's, ALeft what is left of
// its life
function LightOf(const ALook: TBoltLook; ALevel, ALeft: Single): TBoltLight;
begin
  Result.Tint := ALook.Tint;
  Result.Width := ALook.Width;
  var Strength := ALook.Flash * ALevel;
  Result.TintLevel := Strength * Power(ALeft, BoltLayers[bbHalo].Decay);
  Result.WhiteLevel := Strength * Power(ALeft, BoltLayers[bbCore].Decay);
end;

procedure DrawSpot(const ABrush: TBoltBrush; const APoint: TSdlFPoint;
  const ASpot: TBoltSpot; const ALight: TBoltLight);
begin
  DrawGlow(ABrush.Renderer, ABrush.Glow, APoint.X, APoint.Y,
    ASpot.Halo * ALight.Width, ALight.Tint, ALight.TintLevel);
  DrawGlow(ABrush.Renderer, ABrush.Glow, APoint.X, APoint.Y,
    ASpot.Core * ALight.Width, White, ALight.WhiteLevel);
end;

procedure DrawLights(const ABrush: TBoltBrush; const AShot: TBoltShot;
  const AOrigin: TSdlFPoint; const ALight: TBoltLight);
var
  Root, Tip: TSdlFPoint;
begin
  Root.X := AOrigin.X + AShot.RootX;
  Root.Y := AOrigin.Y + AShot.RootY;
  Tip.X := AOrigin.X + AShot.EndX;
  Tip.Y := AOrigin.Y + AShot.EndY;
  DrawSpot(ABrush, Root, EndSpot, ALight);
  case AShot.Ending of
    beBridge:
      DrawSpot(ABrush, Tip, EndSpot, ALight);
    beStrike:
      begin
        DrawSpot(ABrush, Tip, StrikeSpot, ALight);
        DrawGlow(ABrush.Renderer, ABrush.Glow, Tip.X, Tip.Y, RoomAcross,
          ALight.Tint, ALight.TintLevel * RoomShare);
      end;
  end;
end;

procedure TBoltField.DrawLeader(const ABrush: TBoltBrush; const ABolt: TBolt;
  const AOrigin: TSdlFPoint; ATime: Single);
var
  Pass: TBoltPass;
begin
  var Growth: Single := ATime / ABolt.Look.LeaderTicks;
  Growth := EnsureRange(Growth, 0, 1);
  PlaceLimbs(ABolt, AOrigin, Growth);

  Pass.Width := ABolt.Look.Width * LeaderHaloWidth;
  Pass.Tint := ABolt.Look.Tint;
  Pass.Level := LeaderLevel;
  Pass.EveryPoint := False;
  DrawPass(ABrush, Pass);
  Pass.Width := ABolt.Look.Width * LeaderCoreWidth;
  Pass.Tint := White;
  Pass.EveryPoint := True;
  DrawPass(ABrush, Pass);

  var Tip := PointOf(FPoses[0], FDrawn[0].Offsets,
    FPoses[0].Growth * High(FDrawn[0].Offsets));
  DrawGlow(ABrush.Renderer, ABrush.Glow, Tip.X, Tip.Y,
    LeaderTipAcross * ABolt.Look.Width, White, LeaderTipLevel);
end;

procedure TBoltField.DrawStroke(const ABrush: TBoltBrush; const ABolt: TBolt;
  const AOrigin: TSdlFPoint; ATime: Single);
var
  Pass: TBoltPass;
begin
  var Since := ATime - ABolt.Starts[ABolt.Stroke];
  var Left: Single := 1 - Since / ABolt.Look.LifeTicks;
  if Left <= 0 then
    Exit;
  PlaceLimbs(ABolt, AOrigin, 1);

  var Bloom: Single := 0;
  if Since < 1 then
    Bloom := 1 - Since;
  var Level := ABolt.Levels[ABolt.Stroke];
  for var Band := Low(TBoltBand) to High(TBoltBand) do
  begin
    var Layer := BoltLayers[Band];
    Pass.Width := ABolt.Look.Width * Layer.Width * (1 + Layer.Bloom * Bloom);
    Pass.Tint := Mix(ABolt.Look.Tint, White, Layer.Whiteness);
    Pass.Level := Layer.Level * Level * Power(Left, Layer.Decay);
    Pass.EveryPoint := Layer.EveryPoint;
    DrawPass(ABrush, Pass);
  end;
  DrawLights(ABrush, ABolt.Shot, AOrigin, LightOf(ABolt.Look, Level, Left));
end;

procedure TBoltField.Draw(const ABrush: TBoltBrush; const AOrigin: TSdlFPoint;
  AAlpha: Single);
begin
  for var i := 0 to FCount - 1 do
  begin
    var Time := FBolts[i].Age + AAlpha;
    if FBolts[i].Stroke < 0 then
      DrawLeader(ABrush, FBolts[i], AOrigin, Time)
    else
      DrawStroke(ABrush, FBolts[i], AOrigin, Time);
  end;
end;

end.
