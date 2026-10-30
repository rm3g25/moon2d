{
  Game.Capsules - the shuttle's medkits in the Ram's fight. A capsule
  drops from over the top of the screen straight onto its mark - a deck
  or the road - fast at first, then braking on its jet; it lands, its
  shell parts in two and the medkit stands where it landed. No line of
  the shuttle: the capsule says it.

  A capsule is decoration - neither a floor, nor a body, nor a wound;
  the medkit it leaves is the game's, a pickup like any other. What the
  capsule was dropped for, and where, is the game's too. A death takes
  the capsules away; the field the medkits stood in is reborn with it.

  TShuttleCapsules is the rules, TCapsulePainter draws them with the
  shapes of the dynamics' canvas - a hull of discs, a green beacon, the
  cross on its side, the jet under it. No texture of its own.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Capsules;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics;

const
  CapsuleWidth = 18.0;
  CapsuleHeight = 24.0;

type
  // cpFalling - on its way down, braking at the end; cpOpening - landed,
  // its shell parting
  TCapsulePhase = (cpFalling, cpOpening);

  TCapsule = record
    // The middle of its bottom on landing, screen units
    X, LandY: Single;
    // Its bottom this tick and the last
    Bottom, LastBottom: Single;
    Phase: TCapsulePhase;
    // In the phase
    Ticks: Integer;
  end;

  TCapsuleCue = record
    // One came down this tick
    Landed: Boolean;
    // Where the medkits stand from this tick: the middle of their feet
    Opened: TArray<TSdlFPoint>;
  end;

  TShuttleCapsules = class
  private
    FCapsules: TList<TCapsule>;
    function GetCapsule(AIndex: Integer): TCapsule;
  public
    constructor Create;
    destructor Destroy; override;
    // One falls onto AX, ALandY: the middle of the feet of the medkit it
    // leaves
    procedure Drop(AX, ALandY: Single);
    function Tick: TCapsuleCue;
    // A death, a new level: none in the air or on the ground
    procedure Clear;
    function Count: Integer;
    function BottomAt(AIndex: Integer; AAlpha: Single): Single;
    // 0 the tick it lands, 1 as the shell is gone
    function OpenShare(AIndex: Integer; AAlpha: Single): Single;
    // How hard the jet brakes it, 0 none to 1 the moment it lands
    function JetLevel(AIndex: Integer; AAlpha: Single): Single;
    property Capsules[AIndex: Integer]: TCapsule read GetCapsule; default;
  end;

  TCapsulePainter = class
  private
    FCapsules: TShuttleCapsules;
    FAge: Integer;
    procedure DrawJet(const ACanvas: TDynamicCanvas; AX, ABottom,
      ALevel: Single);
    procedure DrawHull(const ACanvas: TDynamicCanvas; AX, ABottom: Single);
    procedure DrawHalves(const ACanvas: TDynamicCanvas; AX, ABottom,
      AShare: Single);
  public
    // ACapsules belongs to the caller and must outlive the painter
    constructor Create(ACapsules: TShuttleCapsules);
    // After the capsules' tick: the beacon blinks
    procedure Tick;
    // With the pickups, on the monsters' shake
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  end;

implementation

uses
  System.Math, Render.Glow;

const
  // The bottom starts this far over the top of the screen: the whole
  // capsule is out of sight on its first tick
  StartBottom = -4.0;
  // A second down, whatever the height: from a deck or to the road, the
  // braking is the same
  FallTicks = 33;
  // The jet lights from this share of the fall and is at full on landing
  JetFrom = 0.4;
  OpenTicks = 27;
  // The shell has parted enough to let the medkit out
  MedkitOutTicks = 5;

  // Its picture: a hull of two discs, light over dark; the beacon on top
  // blinks; the cross on its side
  HullDark: TRgb = (R: 92; G: 102; B: 118);
  HullLight: TRgb = (R: 178; G: 190; B: 204);
  HullLightWidth = 0.6; // of the hull's
  HullLightHeight = 0.7;
  HullLightRise = 3;
  HealthGreen: TRgb = (R: 90; G: 255; B: 140);
  BeaconSize = 9;
  BeaconLevel = 0.9;
  BeaconBlinkTicks = 8; // on and off
  CrossLength = 8;
  CrossThickness = 2.5;
  CrossLevel = 0.95;
  JetHot: TRgb = (R: 255; G: 178; B: 96);
  JetSize = 26;
  JetCoreSize = 9;
  JetDrop = 4; // under the bottom
  // The shell parts: each half slides this far out and leans this many
  // degrees, fading; a green breath where the medkit comes out
  HalfSides: array [0..1] of Integer = (-1, 1);
  HalfSpread = 9;
  HalfLean = 35;
  OutFlashSize = 36;
  OutFlashLevel = 0.7;

function EaseOutCubic(AShare: Single): Single;
begin
  var Rest := 1 - AShare;
  Result := 1 - Rest * Rest * Rest;
end;

// ATicks of AWhole, held at 1
function ShareOf(ATicks: Single; AWhole: Integer): Single;
begin
  Result := ATicks / AWhole;
  if Result > 1 then
    Result := 1;
end;

// The bottom AShare of the way down: fast first, braking at the end
function FallBottom(ALandY, AShare: Single): Single;
begin
  Result := StartBottom + (ALandY - StartBottom) * EaseOutCubic(AShare);
end;

function MarkPoint(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

constructor TShuttleCapsules.Create;
begin
  inherited Create;
  FCapsules := TList<TCapsule>.Create;
end;

destructor TShuttleCapsules.Destroy;
begin
  FCapsules.Free;
  inherited;
end;

procedure TShuttleCapsules.Drop(AX, ALandY: Single);
begin
  var Capsule := Default(TCapsule);
  Capsule.X := AX;
  Capsule.LandY := ALandY;
  Capsule.Bottom := StartBottom;
  Capsule.LastBottom := StartBottom;
  Capsule.Phase := cpFalling;
  FCapsules.Add(Capsule);
end;

function TShuttleCapsules.Tick: TCapsuleCue;
begin
  Result := Default(TCapsuleCue);
  for var i := FCapsules.Count - 1 downto 0 do
  begin
    var Capsule := FCapsules[i];
    Inc(Capsule.Ticks);
    Capsule.LastBottom := Capsule.Bottom;
    case Capsule.Phase of
      cpFalling:
        begin
          Capsule.Bottom := FallBottom(Capsule.LandY,
            ShareOf(Capsule.Ticks, FallTicks));
          if Capsule.Ticks >= FallTicks then
          begin
            Capsule.Phase := cpOpening;
            Capsule.Ticks := 0;
            Result.Landed := True;
          end;
        end;
      cpOpening:
        begin
          if Capsule.Ticks = MedkitOutTicks then
            Result.Opened := Result.Opened +
              [MarkPoint(Capsule.X, Capsule.LandY)];
          if Capsule.Ticks >= OpenTicks then
          begin
            FCapsules.Delete(i);
            Continue;
          end;
        end;
    end;
    FCapsules[i] := Capsule;
  end;
end;

procedure TShuttleCapsules.Clear;
begin
  FCapsules.Clear;
end;

function TShuttleCapsules.Count: Integer;
begin
  Result := FCapsules.Count;
end;

function TShuttleCapsules.GetCapsule(AIndex: Integer): TCapsule;
begin
  Result := FCapsules[AIndex];
end;

function TShuttleCapsules.BottomAt(AIndex: Integer; AAlpha: Single): Single;
begin
  var Capsule := FCapsules[AIndex];
  Result := Capsule.LastBottom + (Capsule.Bottom - Capsule.LastBottom) * AAlpha;
end;

function TShuttleCapsules.OpenShare(AIndex: Integer; AAlpha: Single): Single;
begin
  var Capsule := FCapsules[AIndex];
  if Capsule.Phase <> cpOpening then
    Exit(0);
  Result := ShareOf(Capsule.Ticks + AAlpha, OpenTicks);
end;

function TShuttleCapsules.JetLevel(AIndex: Integer; AAlpha: Single): Single;
begin
  var Capsule := FCapsules[AIndex];
  if Capsule.Phase <> cpFalling then
    Exit(0);
  var Share := ShareOf(Capsule.Ticks - 1 + AAlpha, FallTicks);
  Result := EnsureRange((Share - JetFrom) / (1 - JetFrom), 0.0, 1.0);
end;

constructor TCapsulePainter.Create(ACapsules: TShuttleCapsules);
begin
  inherited Create;
  FCapsules := ACapsules;
end;

procedure TCapsulePainter.Tick;
begin
  Inc(FAge);
end;

procedure TCapsulePainter.Draw(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var i := 0 to FCapsules.Count - 1 do
  begin
    var X := FCapsules[i].X + AOrigin.X;
    var Bottom := FCapsules.BottomAt(i, AAlpha) + AOrigin.Y;
    if FCapsules[i].Phase = cpOpening then
    begin
      DrawHalves(ACanvas, X, Bottom, FCapsules.OpenShare(i, AAlpha));
      Continue;
    end;
    DrawJet(ACanvas, X, Bottom, FCapsules.JetLevel(i, AAlpha));
    DrawHull(ACanvas, X, Bottom);
  end;
end;

procedure TCapsulePainter.DrawJet(const ACanvas: TDynamicCanvas; AX, ABottom,
  ALevel: Single);
begin
  if ALevel <= 0 then
    Exit;
  var JetY := ABottom + JetDrop;
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, JetY, JetSize * ALevel,
    JetHot, ALevel);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, JetY, JetCoreSize, White,
    ALevel);
end;

procedure TCapsulePainter.DrawHull(const ACanvas: TDynamicCanvas; AX,
  ABottom: Single);
begin
  var MiddleY := ABottom - CapsuleHeight / 2;
  DrawGlowTurned(ACanvas.Renderer, ACanvas.DiscShade, AX, MiddleY,
    CapsuleWidth, CapsuleHeight, 0, HullDark, 1);
  DrawGlowTurned(ACanvas.Renderer, ACanvas.DiscShade, AX,
    MiddleY - HullLightRise, CapsuleWidth * HullLightWidth,
    CapsuleHeight * HullLightHeight, 0, HullLight, 1);
  DrawGlowTurned(ACanvas.Renderer, ACanvas.DiscShade, AX, MiddleY,
    CrossLength, CrossThickness, 0, HealthGreen, CrossLevel);
  DrawGlowTurned(ACanvas.Renderer, ACanvas.DiscShade, AX, MiddleY,
    CrossThickness, CrossLength, 0, HealthGreen, CrossLevel);
  if (FAge div BeaconBlinkTicks) mod 2 = 0 then
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX,
      ABottom - CapsuleHeight, BeaconSize, HealthGreen, BeaconLevel);
end;

procedure TCapsulePainter.DrawHalves(const ACanvas: TDynamicCanvas; AX,
  ABottom, AShare: Single);
begin
  var Eased := EaseOutCubic(AShare);
  var Level := 1 - AShare;
  var MiddleY := ABottom - CapsuleHeight / 2;
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, MiddleY, OutFlashSize,
    HealthGreen, OutFlashLevel * Level);
  for var Side in HalfSides do
  begin
    var HalfX := AX + Side * (CapsuleWidth / 4 + HalfSpread * Eased);
    DrawGlowTurned(ACanvas.Renderer, ACanvas.DiscShade, HalfX, MiddleY,
      CapsuleWidth / 2, CapsuleHeight, Side * HalfLean * Eased, HullDark,
      Level);
  end;
end;

end.
