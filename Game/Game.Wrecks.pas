{
  Game.Wrecks - the pads the sweeper's shock wave knocks off. A pad the
  wave reaches is put to sleep (TPad.Doze) and a wreck flies off in its
  picture: away from the blast and up, its jet still burning, until it
  is off the screen. A wreck is decoration - neither a floor, nor a body,
  nor a wound - and a death rewinds the pads and takes the wrecks away.

  The flight and the spin are apart. The wreck flies along a heading of
  its own: kicked off hard by the blast - the harder the nearer - then
  the drag takes the kick away and the jet's thrust holds what is left,
  easing the heading outward and a little up, the moon's pull on it - so
  it never comes down onto the road, wherever the Ram stood. Its picture
  spins on its own: the torn-off firework is in the picture, not in the
  path.

  No two wrecks of a blast alike: each takes its own climb, its own spin
  and its own way of spinning up, and one in a few spins against the
  others.

  TPadWrecks is the rules, TPadWreckPainter draws them: the picture of
  the pad turned with the spin, fire and smoke out of its jet, sparks
  behind it, a glow about it, small bolts over its deck.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Wrecks;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Levels.Dynamics, Pads.World;

type
  TPadWreck = record
    // Whose picture it flies in; nil for a wreck of no pad
    Pad: TPad;
    Width, Height: Single;
    // The middle of the picture, this tick and the last, screen units
    Middle, LastMiddle: TSdlFPoint;
    // Units a tick
    Speed: TSdlFPoint;
    // Radians over the level, outward; the heading eases to the climb
    Heading, Climb: Single;
    // -1 off to the left, 1 to the right
    Side: Integer;
    // Degrees clockwise, this tick and the last, how fast it spins and
    // how much faster every tick
    Spin, LastSpin: Single;
    SpinRate, SpinGain: Single;
    // Off the screen: it flies no more
    Gone: Boolean;
  end;

  TPadWrecks = class
  private
    FWrecks: TArray<TPadWreck>;
    FClears: Integer;
    function GetWreck(AIndex: Integer): TPadWreck;
  public
    // APad's picture, AWidth by AHeight about AMiddle, thrown away from
    // AFrom - the blast, whose wave dies AReach units off it
    procedure Launch(const APad: TPad; const AMiddle: TSdlFPoint;
      AWidth, AHeight: Single; const AFrom: TSdlFPoint; AReach: Single);
    procedure Tick;
    // A death, a new level: none in the air
    procedure Clear;
    function Count: Integer;
    // Some are still on the screen
    function Flying: Boolean;
    function MiddleAt(AIndex: Integer; AAlpha: Single): TSdlFPoint;
    function SpinAt(AIndex: Integer; AAlpha: Single): Single;
    property Wrecks[AIndex: Integer]: TPadWreck read GetWreck; default;
    // Counts the clears: a painter that sees it change knows what it left
    // in the air is gone
    property Clears: Integer read FClears;
  end;

  TPadWreckPainter = class
  private
    FRenderer: PSdlRenderer;
    FWrecks: TPadWrecks;
    FGlow: PSdlTexture;
    // One of each a wreck, in the order of the wrecks
    FFires: TArray<TSmoke>;
    FSparks: TArray<TSparks>;
    FBolts: TArray<TLightning>;
    FClears: Integer;
    FAge: Integer;
    procedure Grow;
    procedure Rewind;
    function JetPoint(AIndex: Integer): TSdlFPoint;
  public
    // AWrecks belongs to the caller and must outlive the painter
    constructor Create(ARenderer: PSdlRenderer; AWrecks: TPadWrecks);
    destructor Destroy; override;
    // After the wrecks' tick: the fire, the sparks and the bolts follow
    procedure Tick;
    // The fire and the smoke of the jets, under the pictures
    procedure DrawFire(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // The pads' pictures, turned
    procedure DrawBodies(const ASprites: TSpriteRenderer; AAlpha: Single);
    // The glow about each, its sparks and its bolts
    procedure DrawLight(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  end;

implementation

uses
  System.Math, Render.Brush, Render.Glow, Levels.Tint, Effects.Sparks,
  Game.Space;

const
  // Kicked off this fast next to the blast, this fast where the wave dies;
  // at least this steep, away from it
  WreckKickNear = 7.0;
  WreckKickFar = 3.5;
  WreckLeastLift = 40.0;
  // The jet keeps pushing, weaker than the drag takes off a near kick: the
  // wreck slows down, then the jet holds it. Its heading eases this much a
  // tick toward a climb of its own, outward
  WreckThrust = 0.15;
  WreckHeadingEase = 0.05;
  // Steeper than 40 and the slowest wreck stays on the screen about five
  // seconds
  WreckClimbLeast = 20.0;
  WreckClimbSpan = 20.0;
  // The moon's pull, as on the hero's fall, and the share of the speed
  // lost a tick
  WreckGravity = 2 / 14;
  WreckDrag = 0.03;
  // The picture's spin, degrees a tick at a full kick; at the wave's far
  // edge this share of it
  WreckSpinLeast = 5.0;
  WreckSpinSpan = 9.0;
  WreckSpinFarShare = 0.5;
  WreckSpinGainMost = 0.3;
  // Past about 30 a tick the pad's picture, alike every half turn, reads
  // as a propeller, not a tumble
  WreckSpinMost = 24.0;
  WreckCounterSpinShare = 0.2;
  WreckClimbSalt = 1;
  WreckCounterSpinSalt = 8;
  WreckSpinSalt = 3;
  WreckSpinGainSalt = 4;
  // Gone this far past the left, the right or the top edge; the flight
  // never reaches the road, so the bottom is not one of them
  WreckOffMargin = 60.0;

  // The jet leaves the middle of the underside, turned with the picture
  WreckJetDown = 6.0;
  WreckFire: TSmokeLook = (Rate: 90; Life: 0.35; Size: 4; EndSize: 11;
    Opacity: 0.8; Angle: -90; Cone: 360; Speed: 18; Drag: 0.6; Lift: 0;
    Wind: 0; Turbulence: 3; Spin: 60; Flow: sfSteady; Frequency: 1;
    Heat: 1; EndTint: (R: 26; G: 24; B: 24));
  // The smoke the fire cools to
  WreckFireTint: TColorTint = (R: 44; G: 42; B: 40);
  WreckSparkLook: TSparkSourceLook = (Rate: 30; Burst: 6; Frequency: 1.5;
    Spell: 0; Pause: 0; Life: 0.45; Speed: 60; Angle: -90; Cone: 360;
    Gravity: 120; Drag: 0.8; Size: 1.6; Opacity: 1; Flash: 0.3; Fork: 0.2;
    Wall: swPass; MidTint: (R: 100; G: 66; B: 27);
    EndTint: (R: 69; G: 14; B: 6));
  // A fresh spark
  WreckSparkTint: TColorTint = (R: 100; G: 96; B: 86);
  // Over the deck, the box about its width
  WreckBoltLook: TLightningLook = (Reach: 12; Spread: (X: 14; Y: 3);
    Angle: 90; Cone: 360; Collide: lcNone; Size: 0.8; Jag: 0.26; Fork: 0.18;
    Frequency: 3; Strokes: 2; Life: 0.1; Leader: 0; Spell: 0; Pause: 0;
    Flash: 0.5; Jolt: 0; Tint: (R: 66; G: 74; B: 100));
  WreckSeedSalts: array [0..2] of Cardinal = ($57724631, $57725331,
    $57724231); // "WrF1", "WrS1", "WrB1"
  // The orange glow about a burning wreck, breathing a little
  WreckGlowSide = 64;
  WreckGlowSize = 36.0;
  WreckGlowLevel = 0.45;
  WreckGlowBreath = 0.15;
  WreckGlowTicks = 7;
  WreckGlowColor: TRgb = (R: 255; G: 140; B: 48);

function UnitPoint(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

// A steady pick in [0, 1) for the wreck of this turn: the same blast throws
// the same wrecks every time, no two alike
function WreckVariety(ATurn, ASalt: Integer): Single;
begin
  Result := Frac(Abs(Sin(ATurn * 12.9898 + ASalt * 78.233) * 43758.5453));
end;

// ---------------------------------------------------------------------------
// TPadWrecks
// ---------------------------------------------------------------------------

procedure TPadWrecks.Launch(const APad: TPad; const AMiddle: TSdlFPoint;
  AWidth, AHeight: Single; const AFrom: TSdlFPoint; AReach: Single);
begin
  var Turn := Length(FWrecks);
  var Wreck := Default(TPadWreck);
  Wreck.Pad := APad;
  Wreck.Width := AWidth;
  Wreck.Height := AHeight;
  Wreck.Middle := AMiddle;
  Wreck.LastMiddle := AMiddle;
  var AwayX := AMiddle.X - AFrom.X;
  Wreck.Side := 1;
  if AwayX < 0 then
    Wreck.Side := -1;
  Wreck.Heading := Max(ArcTan2(AFrom.Y - AMiddle.Y, Abs(AwayX)),
    DegToRad(WreckLeastLift));
  Wreck.Climb := DegToRad(WreckClimbLeast +
    WreckClimbSpan * WreckVariety(Turn, WreckClimbSalt));

  var Strength: Single := 0;
  if AReach > 0 then
    Strength := EnsureRange(1 - Hypot(AwayX, AMiddle.Y - AFrom.Y) / AReach, 0, 1);
  var Kick := Lerp(WreckKickFar, WreckKickNear, Strength);
  Wreck.Speed := UnitPoint(Wreck.Side * Kick * Cos(Wreck.Heading),
    -Kick * Sin(Wreck.Heading));

  var SpinSide := Wreck.Side;
  if WreckVariety(Turn, WreckCounterSpinSalt) < WreckCounterSpinShare then
    SpinSide := -SpinSide;
  Wreck.SpinRate := SpinSide * Lerp(WreckSpinFarShare, 1, Strength) *
    (WreckSpinLeast + WreckSpinSpan * WreckVariety(Turn, WreckSpinSalt));
  Wreck.SpinGain := WreckSpinGainMost * WreckVariety(Turn, WreckSpinGainSalt);
  FWrecks := FWrecks + [Wreck];
end;

procedure TPadWrecks.Tick;
begin
  for var i := 0 to High(FWrecks) do
  begin
    var Wreck := FWrecks[i];
    Wreck.LastMiddle := Wreck.Middle;
    Wreck.LastSpin := Wreck.Spin;
    if Wreck.Gone then
    begin
      FWrecks[i] := Wreck;
      Continue;
    end;

    Wreck.Heading := Lerp(Wreck.Heading, Wreck.Climb, WreckHeadingEase);
    Wreck.Speed.X := (Wreck.Speed.X + Wreck.Side * WreckThrust * Cos(Wreck.Heading)) *
      (1 - WreckDrag);
    Wreck.Speed.Y := (Wreck.Speed.Y - WreckThrust * Sin(Wreck.Heading) +
      WreckGravity) * (1 - WreckDrag);
    Wreck.Middle.X := Wreck.Middle.X + Wreck.Speed.X;
    Wreck.Middle.Y := Wreck.Middle.Y + Wreck.Speed.Y;

    Wreck.Spin := Wreck.Spin + Wreck.SpinRate;
    Wreck.SpinRate := Sign(Wreck.SpinRate) *
      Min(Abs(Wreck.SpinRate) + Wreck.SpinGain, WreckSpinMost);

    Wreck.Gone := (Wreck.Middle.X < -WreckOffMargin) or
      (Wreck.Middle.X > ScreenWidth + WreckOffMargin) or
      (Wreck.Middle.Y < -WreckOffMargin);
    FWrecks[i] := Wreck;
  end;
end;

procedure TPadWrecks.Clear;
begin
  FWrecks := nil;
  Inc(FClears);
end;

function TPadWrecks.Count: Integer;
begin
  Result := Length(FWrecks);
end;

function TPadWrecks.Flying: Boolean;
begin
  for var Wreck in FWrecks do
    if not Wreck.Gone then
      Exit(True);
  Result := False;
end;

function TPadWrecks.GetWreck(AIndex: Integer): TPadWreck;
begin
  Result := FWrecks[AIndex];
end;

function TPadWrecks.MiddleAt(AIndex: Integer; AAlpha: Single): TSdlFPoint;
begin
  var Wreck := FWrecks[AIndex];
  Result := UnitPoint(Lerp(Wreck.LastMiddle.X, Wreck.Middle.X, AAlpha),
    Lerp(Wreck.LastMiddle.Y, Wreck.Middle.Y, AAlpha));
end;

function TPadWrecks.SpinAt(AIndex: Integer; AAlpha: Single): Single;
begin
  Result := Lerp(FWrecks[AIndex].LastSpin, FWrecks[AIndex].Spin, AAlpha);
end;

// ---------------------------------------------------------------------------
// TPadWreckPainter
// ---------------------------------------------------------------------------

constructor TPadWreckPainter.Create(ARenderer: PSdlRenderer;
  AWrecks: TPadWrecks);
begin
  inherited Create;
  FRenderer := ARenderer;
  FWrecks := AWrecks;
  FGlow := CreateGlowShape(ARenderer, gsPoint, WreckGlowSide);
end;

destructor TPadWreckPainter.Destroy;
begin
  for var Bolt in FBolts do
    Bolt.Free;
  for var Spray in FSparks do
    Spray.Free;
  for var Fire in FFires do
    Fire.Free;
  if Assigned(FGlow) then
    SDL_DestroyTexture(FGlow);
  inherited;
end;

// The sources of the wrecks launched since the last tick, seeded by their
// turn so the five never burn alike
procedure TPadWreckPainter.Grow;
begin
  var FirePlacement := Default(TDynamicPlacement);
  FirePlacement.Tint := WreckFireTint;
  var SparkPlacement := Default(TDynamicPlacement);
  SparkPlacement.Tint := WreckSparkTint;
  while Length(FFires) < FWrecks.Count do
  begin
    var Turn := Cardinal(Length(FFires) + 1);
    FFires := FFires + [TSmoke.CreateLook(FirePlacement, WreckFire, 1,
      WreckSeedSalts[0] xor Turn)];
    FSparks := FSparks + [TSparks.CreateLook(SparkPlacement, WreckSparkLook, 1,
      WreckSeedSalts[1] xor Turn)];
    FBolts := FBolts + [TLightning.CreateLook(Default(TDynamicPlacement),
      WreckBoltLook, 1, WreckSeedSalts[2] xor Turn)];
  end;
end;

// The wrecks cleared: what their sources put out is gone too, and the
// sources wait for the next wrecks
procedure TPadWreckPainter.Rewind;
begin
  for var Fire in FFires do
    Fire.Rewind;
  for var Spray in FSparks do
    Spray.Rewind;
  for var Bolt in FBolts do
    Bolt.Rewind;
end;

function TPadWreckPainter.JetPoint(AIndex: Integer): TSdlFPoint;
begin
  var Middle := FWrecks.MiddleAt(AIndex, 1);
  var Angle := DegToRad(FWrecks.SpinAt(AIndex, 1));
  Result := UnitPoint(Middle.X - Sin(Angle) * WreckJetDown,
    Middle.Y + Cos(Angle) * WreckJetDown);
end;

// A gone wreck puts out nothing more; what it put out burns out where it
// is
procedure TPadWreckPainter.Tick;
begin
  if FWrecks.Clears <> FClears then
  begin
    FClears := FWrecks.Clears;
    Rewind;
  end;
  Grow;
  Inc(FAge);
  for var i := 0 to FWrecks.Count - 1 do
  begin
    var Burning := not FWrecks[i].Gone;
    var Jet := JetPoint(i);
    FFires[i].Tick(Jet.X, Jet.Y, Burning);
    FSparks[i].Tick(Jet.X, Jet.Y, Burning);
    var Middle := FWrecks.MiddleAt(i, 1);
    FBolts[i].Tick(Middle.X, Middle.Y, Burning);
  end;
end;

procedure TPadWreckPainter.DrawFire(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var i := 0 to Min(FWrecks.Count, Length(FFires)) - 1 do
    FFires[i].Draw(ACanvas, FFires[i].Origin.X + AOrigin.X,
      FFires[i].Origin.Y + AOrigin.Y, AAlpha);
end;

procedure TPadWreckPainter.DrawBodies(const ASprites: TSpriteRenderer;
  AAlpha: Single);
begin
  for var i := 0 to FWrecks.Count - 1 do
  begin
    var Wreck := FWrecks[i];
    if Wreck.Gone or (Wreck.Pad = nil) or (Wreck.Pad.Texture = nil) then
      Continue;
    var Tint := Wreck.Pad.Placement.Tint;
    TintTexture(Wreck.Pad.Texture, Tint.R, Tint.G, Tint.B);
    ASprites.DrawSized(Wreck.Pad.Texture, FWrecks.MiddleAt(i, AAlpha),
      Wreck.Width, Wreck.Height, 1, False, FWrecks.SpinAt(i, AAlpha));
  end;
end;

procedure TPadWreckPainter.DrawLight(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Breath: Single := WreckGlowBreath * Sin(2 * Pi * FAge / WreckGlowTicks);
  for var i := 0 to Min(FWrecks.Count, Length(FFires)) - 1 do
  begin
    if not FWrecks[i].Gone then
    begin
      var Middle := FWrecks.MiddleAt(i, AAlpha);
      DrawGlow(FRenderer, FGlow, Middle.X + AOrigin.X, Middle.Y + AOrigin.Y,
        WreckGlowSize, WreckGlowColor, WreckGlowLevel + Breath);
    end;
    FSparks[i].Draw(ACanvas, FSparks[i].Origin.X + AOrigin.X,
      FSparks[i].Origin.Y + AOrigin.Y, AAlpha);
    FBolts[i].Draw(ACanvas, FBolts[i].Origin.X + AOrigin.X,
      FBolts[i].Origin.Y + AOrigin.Y, AAlpha);
  end;
end;

end.
