{
  Orbs.Flock - the orbs: small lights that fly by a formula, not by
  ballistics, and take no notice of matter - no wall stops one, no floor
  bursts it. An orb is a white-hot point in a glow of its element's
  color, breathing; it is drawn in code, there is no picture of it.

  The flock keeps the orbs in the order their owner gave them and knows
  the two ways an orb ends: it implodes when its time is up and goes to
  dust when it strikes. Where an orb is the flock does not decide: the
  owner moves every one of its orbs each tick by its own formula.

  The look only: what an orb strikes, and what that costs, is the game's.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Flock;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Effects.Emitter,
  Levels.Dynamics;

type
  // The element the orbs are made of
  TOrbTint = record
    Core: TRgb; // the white-hot point
    Glow: TRgb;
  end;

  // Imploding: drawing into its point. Gone: dropped at the flock's next
  // tick.
  TOrbState = (osAlive, osImploding, osGone);

  TOrb = class
  private
    FX, FY: Single;
    // What MoveTo has carried the orb by since the flock's tick: drawn
    // on ahead between ticks
    FStepX, FStepY: Single;
    FSize: Single;
    FLevel: Single;
    FAge: Integer;
    FBreath: Single; // where in its breath the orb was born, 0..1
    FState: TOrbState;
    FImplodeAge: Integer;
    procedure GrowOlder;
  public
    // In screen units; at full size and light
    constructor Create(AX, AY: Single);
    // Where the owner's formula puts the orb this tick
    procedure MoveTo(AX, AY: Single);
    // The same for an orb that keeps beside a body drawn where the tick
    // left it, the hero: the body's step of this tick is no part of what
    // the orb is drawn on ahead by, or it would tremble against the body
    procedure MoveBeside(AX, AY, ABodyStepX, ABodyStepY: Single);

    property X: Single read FX;
    property Y: Single read FY;
    // Shares of the full size and light, 0..1: an orb coming into being
    property Size: Single read FSize write FSize;
    property Level: Single read FLevel write FLevel;
    property Age: Integer read FAge; // ticks
    property State: TOrbState read FState;
  end;

  TOrbFlock = class
  private
    FOrbs: TObjectList<TOrb>;
    FDust: TParticleSwarm;
    FTint: TOrbTint;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    procedure ThrowDust(AX, AY: Single);
    procedure DrawOrb(const ACanvas: TDynamicCanvas; const AOrb: TOrb;
      AOrigin: TSdlPoint; AAlpha: Single);
    procedure DrawDust(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  public
    constructor Create(const ATint: TOrbTint);
    destructor Destroy; override;
    // The flock owns the orb from here on
    procedure Add(const AOrb: TOrb);
    // The same, into the owner's order: before the orb at AIndex
    procedure Insert(AIndex: Integer; const AOrb: TOrb);
    // The orb's time is up: it draws into its point and is gone
    procedure Implode(const AOrb: TOrb);
    // The orb has struck: gone at once, dust where it was
    procedure Spend(const AOrb: TOrb);
    // First in the owner's tick, before it moves its orbs: an orb not
    // moved after this stands still
    procedure Tick;
    // The frame the flock flies in has become another, this far off - a
    // door: orbs and dust are there at once, nothing is drawn flying
    procedure Shift(AStepX, AStepY: Single);
    // AOrigin - the shake of the layer the orbs fly in
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure Clear;
    // The imploding and the gone among them, until Tick drops the gone
    property Orbs: TObjectList<TOrb> read FOrbs;
  end;

const
  IceOrbTint: TOrbTint = (Core: (R: 238; G: 250; B: 255);
    Glow: (R: 88; G: 200; B: 255));

implementation

uses
  Render.Glow;

const
  // Units across at full size: the halo, the body of light inside it,
  // the point
  HaloAcross = 11;
  BodyAcross = 5.6;
  CoreAcross = 3.6;
  HaloLevel = 0.5;
  BodyLevel = 0.9;
  // The halo swells and shrinks by this share of its size
  BreathDepth = 0.12;
  BreathTicks = 57;

  ImplodeTicks = 9;
  // Of its light an imploding orb keeps this share to the last
  ImplodeLevelKept = 0.5;
  // The flash of an implosion, units across: at its start and end, and
  // what its height adds
  ImplodeFlashAcross = 4;
  ImplodeFlashSwell = 10;
  ImplodeFlashLevel = 0.9;

  DustMotes = 7;
  DustSlowSpeed = 0.3; // units a tick
  DustFastSpeed = 1.4;
  DustSpeedKept = 0.9; // each tick
  DustLifeMin = 13; // ticks
  DustLifeMax = 23;
  DustAcross = 3.2;
  DustLevel = 0.9;

  DiceSeed = $4F726273; // "Orbs"

// ---------------------------------------------------------------------------
// TOrb
// ---------------------------------------------------------------------------

constructor TOrb.Create(AX, AY: Single);
begin
  inherited Create;
  FX := AX;
  FY := AY;
  FSize := 1;
  FLevel := 1;
end;

procedure TOrb.MoveTo(AX, AY: Single);
begin
  FStepX := FStepX + AX - FX;
  FStepY := FStepY + AY - FY;
  FX := AX;
  FY := AY;
end;

procedure TOrb.MoveBeside(AX, AY, ABodyStepX, ABodyStepY: Single);
begin
  MoveTo(AX, AY);
  FStepX := FStepX - ABodyStepX;
  FStepY := FStepY - ABodyStepY;
end;

procedure TOrb.GrowOlder;
begin
  Inc(FAge);
  FStepX := 0;
  FStepY := 0;
  if FState <> osImploding then
    Exit;

  Inc(FImplodeAge);
  if FImplodeAge >= ImplodeTicks then
    FState := osGone;
end;

// ---------------------------------------------------------------------------
// TOrbFlock
// ---------------------------------------------------------------------------

constructor TOrbFlock.Create(const ATint: TOrbTint);
begin
  inherited Create;
  FOrbs := TObjectList<TOrb>.Create(True);
  FDust := TParticleSwarm.Create;
  FTint := ATint;
  FRandom.Seed := DiceSeed;
end;

destructor TOrbFlock.Destroy;
begin
  FDust.Free;
  FOrbs.Free;
  inherited;
end;

procedure TOrbFlock.Add(const AOrb: TOrb);
begin
  Insert(FOrbs.Count, AOrb);
end;

procedure TOrbFlock.Insert(AIndex: Integer; const AOrb: TOrb);
begin
  AOrb.FBreath := FRandom.NextUnit;
  FOrbs.Insert(AIndex, AOrb);
end;

procedure TOrbFlock.Implode(const AOrb: TOrb);
begin
  if AOrb.FState <> osAlive then
    Exit;
  AOrb.FState := osImploding;
  AOrb.FImplodeAge := 0;
end;

procedure TOrbFlock.Spend(const AOrb: TOrb);
begin
  if AOrb.FState = osGone then
    Exit;
  AOrb.FState := osGone;
  ThrowDust(AOrb.FX, AOrb.FY);
end;

procedure TOrbFlock.ThrowDust(AX, AY: Single);
var
  Mote: TParticle;
begin
  Mote := Default(TParticle);
  Mote.X := AX;
  Mote.Y := AY;
  for var i := 1 to DustMotes do
  begin
    var Heading: Single := FRandom.NextUnit * 2 * Pi;
    var Speed: Single := DustSlowSpeed +
      FRandom.NextUnit * (DustFastSpeed - DustSlowSpeed);
    Mote.SpeedX := Cos(Heading) * Speed;
    Mote.SpeedY := Sin(Heading) * Speed;
    Mote.Life := DustLifeMin +
      Trunc(FRandom.NextUnit * (DustLifeMax - DustLifeMin + 1));
    FDust.Add(Mote);
  end;
end;

procedure TOrbFlock.Tick;
begin
  for var i := FOrbs.Count - 1 downto 0 do
  begin
    FOrbs[i].GrowOlder;
    if FOrbs[i].FState = osGone then
      FOrbs.Delete(i);
  end;
  FDust.Advance(DustSpeedKept, 0, 0);
end;

procedure TOrbFlock.Shift(AStepX, AStepY: Single);
begin
  for var Orb in FOrbs do
  begin
    Orb.FX := Orb.FX + AStepX;
    Orb.FY := Orb.FY + AStepY;
  end;
  // The swarm shifts its frame the other way: what flies stays put
  FDust.ShiftFrame(-AStepX, -AStepY);
end;

// 0 for an orb that is not imploding, up to 1 at its last moment
function ImplodedShare(const AOrb: TOrb; AAlpha: Single): Single;
begin
  Result := 0;
  if AOrb.FState <> osImploding then
    Exit;
  Result := (AOrb.FImplodeAge + AAlpha) / ImplodeTicks;
  if Result > 1 then
    Result := 1;
end;

procedure TOrbFlock.DrawOrb(const ACanvas: TDynamicCanvas; const AOrb: TOrb;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  var CenterX: Single := AOrigin.X + AOrb.FX + AOrb.FStepX * AAlpha;
  var CenterY: Single := AOrigin.Y + AOrb.FY + AOrb.FStepY * AAlpha;
  var Imploded := ImplodedShare(AOrb, AAlpha);
  var Size: Single := AOrb.FSize * (1 - Imploded);
  var Level: Single := AOrb.FLevel *
    (1 - (1 - ImplodeLevelKept) * Imploded);

  if Imploded > 0 then
  begin
    var Height: Single := Sin(Pi * Imploded);
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
      ImplodeFlashAcross + ImplodeFlashSwell * Height, FTint.Core,
      ImplodeFlashLevel * Height * AOrb.FLevel);
  end;

  var Breath: Single := 1 + BreathDepth *
    Sin(2 * Pi * ((AOrb.FAge + AAlpha) / BreathTicks + AOrb.FBreath));
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    HaloAcross * Size * Breath, FTint.Glow, HaloLevel * Level);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    BodyAcross * Size, FTint.Glow, BodyLevel * Level);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    CoreAcross * Size, FTint.Core, Level);
end;

procedure TOrbFlock.DrawDust(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var i := 0 to FDust.Count - 1 do
  begin
    var Mote := FDust[i];
    var Fade: Single := 1 - (Mote.Age + AAlpha) / Mote.Life;
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow,
      AOrigin.X + Mote.X + Mote.SpeedX * AAlpha,
      AOrigin.Y + Mote.Y + Mote.SpeedY * AAlpha,
      DustAcross, FTint.Glow, DustLevel * Fade);
  end;
end;

procedure TOrbFlock.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  for var Orb in FOrbs do
    if Orb.FState <> osGone then
      DrawOrb(ACanvas, Orb, AOrigin, AAlpha);
  DrawDust(ACanvas, AOrigin, AAlpha);
end;

procedure TOrbFlock.Clear;
begin
  FOrbs.Clear;
  FDust.Clear;
end;

end.
