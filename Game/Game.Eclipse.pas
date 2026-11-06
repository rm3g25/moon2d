{
  Game.Eclipse - the scene of the henshin from the brake of the Ram to
  the beam: what it shows at each tick and what it asks for.

  The charge full, the game brakes the Ram and the road, and starts the
  scene. The road runs down for BeltRampTicks; with the world at rest the
  rite of the eclipse is called about the hero (Orbs.Moonrite). The rite
  drives the rest: with its first orb in its seat the track begins to
  fade; the darker the world, the fuller the ring; the ring full, a column
  of light falls from above onto him and stays, beating with the heart.
  The ring beats in it a while, then the scene tells its orbs to go into
  him. The burst that follows strikes the darkness off in one tick: the
  light is back, the beam gone, the gauge out for good. From the start
  nothing wounds the hero till the game says the scene spares him no
  more - at the wheel of the throw; the controls stay his, so the ring and
  the beam keep to him wherever he runs.

  The scene knows neither the Ram, the gauge nor the orbs: the game starts
  it, hands it how far the ring has come every tick, carries out its cues
  and reads its levels. TEclipsePainter draws the darkness, the ripples
  of the heart over it and the beam.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Eclipse;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Game.Belt;

const
  // The world at rest: the road has run down
  CallAt = BeltRampTicks;
  // The darkness comes in no quicker than to its depth over this many ticks
  DarkTicks = 40;
  DarkDepth = 0.85;
  // The track fades out from the first orb in its seat: about as long as
  // the ring takes to gather
  RiteFadeSeconds = 3.5;
  BeamFallTicks = 8;
  // The flash of the beam's landing dies over this many ticks
  BeamFlashTicks = 12;
  // The ring beats in the beam this long before its orbs go into him
  RingInBeamTicks = 50;

type
  // How far the ring of the rite has come: the orbs in their seats of all
  // it calls
  TRingProgress = record
    Gathered: Integer;
    Count: Integer;
    // 0..1; 0 for a ring of no seats
    function Share: Single;
    function Full: Boolean;
  end;

  TEclipseCue = record
    // The world at rest: the rite is called about him
    Called: Boolean;
    // The first orb in its seat: the track fades to silence
    FirstSeat: Boolean;
    // The ring is full: the beam starts down
    Beam: Boolean;
    // The ring has beaten in the beam: its orbs go into him
    DrawIn: Boolean;
  end;

  TEclipseScene = class
  private
    FRunning: Boolean;
    FTicks: Integer;
    // The ticks of the first orb in its seat and of the beam; -1 before
    FFirstSeatAt: Integer;
    FBeamAt: Integer;
    // The burst has struck: the light is back
    FStruck: Boolean;
    // He can be wounded again
    FSpareOver: Boolean;
    // The darkness at this tick and at the one before
    FDark: Single;
    FDarkBefore: Single;
    function Clock(AAlpha: Single): Single;
    function DrawInAt: Integer;
    procedure Deepen(const ARing: TRingProgress);
  public
    // At the brake: the first tick of the scene is the next one
    procedure Start;
    procedure Clear;
    function Tick(const ARing: TRingProgress): TEclipseCue;
    // The burst has struck: the dark, the beam and the ripples are gone at
    // once; nothing more is cued
    procedure Strike;
    // From the brake on: nothing wounds the hero, till StopSparing
    function Spares: Boolean;
    procedure StopSparing;
    // How dark the world is, 0 to DarkDepth: AAlpha of the way from the
    // last tick to this one
    function Darkness(AAlpha: Single): Single;
    // How far the gauge has gone out with the light, 0..1; out for good
    // once the burst has struck
    function Fade(AAlpha: Single): Single;
    // How strongly the heart's ripples run over the dark, 0..1: as dark as
    // it is, from the first orb in its seat till the orbs go into him
    function Ripple(AAlpha: Single): Single;
    // How far down the beam has come, 0 at the top of the screen to 1 on him
    function Beam(AAlpha: Single): Single;
    // The landing's flash: 1 as the beam reaches him, gone BeamFlashTicks on
    function BeamFlash(AAlpha: Single): Single;
    property Running: Boolean read FRunning;
    property Struck: Boolean read FStruck;
  end;

  TEclipsePainter = class
  private
    FRenderer: PSdlRenderer;
    FEclipse: TEclipseScene;
    FBand: PSdlTexture;
    FHalo: PSdlTexture;
    FVertices: TArray<TSdlVertex>;
    FIndices: TArray<Integer>;
    procedure SetCorner(AIndex: Integer; AX, AY, AAcross: Single;
      AAlpha: UInt8);
    procedure DrawColumn(AX, AFront, AAcross, ALevel: Single;
      const ATint: TSdlColor);
  public
    // The eclipse belongs to the caller and must outlive the painter
    constructor Create(ARenderer: PSdlRenderer; AEclipse: TEclipseScene);
    destructor Destroy; override;
    // Over the far plane and the play layer, under the hero and the HUD
    procedure DrawDark(AAlpha: Single);
    // Over the dark, under the beam: a ring of faint light running out from
    // ACenter, the middle of the ring of the rite, ASinceBeat ticks after
    // the heart struck; -1 - it does not beat
    procedure DrawRipple(const ACenter: TSdlFPoint; ASinceBeat, AAlpha: Single);
    // Over the dark, under the hero: straight down from the top of the
    // screen onto AFoot, his feet, swelling with APulse, the heartbeat
    procedure DrawBeam(const AFoot: TSdlFPoint; APulse, AAlpha: Single);
  end;

implementation

uses
  System.Math, Render.Brush, Render.Glow;

const
  // Deep night with a little of the moon's violet in it
  DarkTint: TRgb = (R: 6; G: 4; B: 16);
  WholeFrame: PSdlFRect = nil;
  DarkVisible = 1 / 255;

  // A ripple runs from the ring out over this many ticks, from its radius
  // to far over the world, and fades on the way
  RippleTicks = 22;
  RippleFrom = 48;
  RippleTo = 170;
  RippleLevel = 0.3;
  // The ring is drawn in points of light this far apart along it
  RippleSpacing = 6;
  RippleAcross = 14;
  RippleTint: TRgb = (R: 200; G: 186; B: 255);

  // A white core in a wide moonlit glow. The band's Gaussian leaves its
  // outer thirds faint, so the core drawn this wide reads about his width
  BeamCoreTint: TSdlColor = (R: 255; G: 255; B: 255; A: 255);
  BeamGlowTint: TSdlColor = (R: 200; G: 186; B: 255; A: 255);
  BeamCoreAcross = 44;
  BeamCoreLevel = 0.9;
  BeamGlowAcross = 150;
  BeamGlowLevel = 0.4;
  // A heartbeat swells the column by this share and brightens its glow
  BeamPulseGrowth = 0.12;
  BeamPulseGlow = 0.25;
  // The landing: the core wider and the glow brighter for a moment
  BeamFlashGrowth = 0.6;
  BeamFlashGlow = 0.5;
  // The light runs out below his feet over this much
  BeamTail = 48;
  HaloAcross = 96;
  HaloLevel = 0.45;
  HaloTint: TRgb = (R: 220; G: 210; B: 255);
  BodyHeight = 32;
  GlowTextureSide = 64;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0, 1);
  Result := Share * Share * (3 - 2 * Share);
end;

{ TRingProgress }

function TRingProgress.Share: Single;
begin
  if Count <= 0 then
    Exit(0);
  var Share: Single := Gathered / Count;
  Result := EnsureRange(Share, 0, 1);
end;

function TRingProgress.Full: Boolean;
begin
  Result := (Count > 0) and (Gathered >= Count);
end;

{ TEclipseScene }

procedure TEclipseScene.Start;
begin
  Clear;
  FRunning := True;
end;

procedure TEclipseScene.Clear;
begin
  FRunning := False;
  FTicks := 0;
  FFirstSeatAt := -1;
  FBeamAt := -1;
  FStruck := False;
  FSpareOver := False;
  FDark := 0;
  FDarkBefore := 0;
end;

// The dark and the tick before it alike, so not a frame of it is drawn
procedure TEclipseScene.Strike;
begin
  if not FRunning then
    Exit;
  FStruck := True;
  FDark := 0;
  FDarkBefore := 0;
end;

function TEclipseScene.DrawInAt: Integer;
begin
  Result := FBeamAt + BeamFallTicks + RingInBeamTicks;
end;

// The dark follows the ring, never lighter and never quicker than its
// pace; with the ring full it goes all the way
procedure TEclipseScene.Deepen(const ARing: TRingProgress);
begin
  FDarkBefore := FDark;
  if FFirstSeatAt < 0 then
    Exit;
  var Target: Single := DarkDepth * ARing.Share;
  if FBeamAt >= 0 then
    Target := DarkDepth;
  var Paced: Single := FDark + DarkDepth / DarkTicks;
  FDark := Max(FDark, Min(Target, Paced));
end;

function TEclipseScene.Tick(const ARing: TRingProgress): TEclipseCue;
begin
  Result := Default(TEclipseCue);
  if not FRunning or FStruck then
    Exit;
  Inc(FTicks);
  Result.Called := FTicks = CallAt;
  if (FFirstSeatAt < 0) and (FTicks >= CallAt) and (ARing.Gathered > 0) then
  begin
    FFirstSeatAt := FTicks;
    Result.FirstSeat := True;
  end;
  if (FBeamAt < 0) and (FFirstSeatAt >= 0) and ARing.Full then
  begin
    FBeamAt := FTicks;
    Result.Beam := True;
  end;
  Deepen(ARing);
  Result.DrawIn := (FBeamAt >= 0) and (FTicks = DrawInAt);
end;

function TEclipseScene.Spares: Boolean;
begin
  Result := FRunning and not FSpareOver;
end;

procedure TEclipseScene.StopSparing;
begin
  FSpareOver := True;
end;

function TEclipseScene.Clock(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  Result := FTicks + AAlpha;
end;

function TEclipseScene.Darkness(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  Result := FDarkBefore + (FDark - FDarkBefore) * AAlpha;
end;

function TEclipseScene.Fade(AAlpha: Single): Single;
begin
  if FStruck then
    Exit(1);
  Result := Darkness(AAlpha) / DarkDepth;
end;

function TEclipseScene.Ripple(AAlpha: Single): Single;
begin
  var Drawn := (FBeamAt >= 0) and (FTicks >= DrawInAt);
  if not FRunning or FStruck or (FFirstSeatAt < 0) or Drawn then
    Exit(0);
  Result := Fade(AAlpha);
end;

function TEclipseScene.Beam(AAlpha: Single): Single;
begin
  if not FRunning or FStruck or (FBeamAt < 0) then
    Exit(0);
  Result := SmoothStep((Clock(AAlpha) - FBeamAt) / BeamFallTicks);
end;

function TEclipseScene.BeamFlash(AAlpha: Single): Single;
begin
  if not FRunning or FStruck or (FBeamAt < 0) then
    Exit(0);
  var Since := Clock(AAlpha) - (FBeamAt + BeamFallTicks);
  if Since < 0 then
    Exit(0);
  Result := EnsureRange(1 - Since / BeamFlashTicks, 0, 1);
end;

{ TEclipsePainter }

constructor TEclipsePainter.Create(ARenderer: PSdlRenderer; AEclipse: TEclipseScene);
begin
  inherited Create;
  FRenderer := ARenderer;
  FEclipse := AEclipse;
  FBand := CreateGlowShape(ARenderer, gsBeam, GlowTextureSide);
  FHalo := CreateGlowShape(ARenderer, gsPoint, GlowTextureSide);
  // Across the band at the top of the screen, at its front and where it
  // has run out; two triangles between each pair of rows
  SetLength(FVertices, 6);
  FIndices := [0, 1, 2, 1, 3, 2, 2, 3, 4, 3, 5, 4];
end;

destructor TEclipsePainter.Destroy;
begin
  if FHalo <> nil then
    SDL_DestroyTexture(FHalo);
  if FBand <> nil then
    SDL_DestroyTexture(FBand);
  inherited;
end;

procedure TEclipsePainter.DrawDark(AAlpha: Single);
begin
  var Depth := FEclipse.Darkness(AAlpha);
  if Depth < DarkVisible then
    Exit;
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
  SDL_SetRenderDrawColor(FRenderer, DarkTint.R, DarkTint.G, DarkTint.B,
    Round(255 * Depth));
  SDL_RenderFillRectF(FRenderer, WholeFrame);
end;

// Quick away from the ring, slower as it spreads
procedure TEclipsePainter.DrawRipple(const ACenter: TSdlFPoint; ASinceBeat,
  AAlpha: Single);
begin
  var Strength := FEclipse.Ripple(AAlpha);
  if (Strength <= 0) or (ASinceBeat < 0) or (ASinceBeat >= RippleTicks) then
    Exit;
  var Spread: Single := ASinceBeat / RippleTicks;
  var Radius: Single := RippleFrom + (RippleTo - RippleFrom) *
    (1 - Sqr(1 - Spread));
  var Level: Single := RippleLevel * Strength * (1 - Spread);
  var Points := Ceil(2 * Pi * Radius / RippleSpacing);
  for var i := 0 to Points - 1 do
  begin
    var Turn: Single := 2 * Pi * i / Points;
    DrawGlow(FRenderer, FHalo, ACenter.X + Radius * Cos(Turn),
      ACenter.Y + Radius * Sin(Turn), RippleAcross, RippleTint, Level);
  end;
end;

procedure TEclipsePainter.SetCorner(AIndex: Integer; AX, AY, AAcross: Single;
  AAlpha: UInt8);
begin
  var Side := AIndex mod 2;
  FVertices[AIndex].Position.X := AX + (Side - 0.5) * AAcross;
  FVertices[AIndex].Position.Y := AY;
  FVertices[AIndex].Color.A := AAlpha;
  FVertices[AIndex].TexCoord.X := 0.5;
  FVertices[AIndex].TexCoord.Y := Side;
end;

procedure TEclipsePainter.DrawColumn(AX, AFront, AAcross, ALevel: Single;
  const ATint: TSdlColor);
begin
  var Alpha: UInt8 := Round(255 * EnsureRange(ALevel, 0, 1));
  SetCorner(0, AX, 0, AAcross, Alpha);
  SetCorner(1, AX, 0, AAcross, Alpha);
  SetCorner(2, AX, AFront, AAcross, Alpha);
  SetCorner(3, AX, AFront, AAcross, Alpha);
  SetCorner(4, AX, AFront + BeamTail, AAcross, 0);
  SetCorner(5, AX, AFront + BeamTail, AAcross, 0);
  for var i := 0 to High(FVertices) do
  begin
    FVertices[i].Color.R := ATint.R;
    FVertices[i].Color.G := ATint.G;
    FVertices[i].Color.B := ATint.B;
  end;
  SDL_RenderGeometry(FRenderer, FBand, @FVertices[0], Length(FVertices),
    @FIndices[0], Length(FIndices));
end;

// The front falls from the top of the screen; the tail runs out below it,
// so the column never ends in a hard line
procedure TEclipsePainter.DrawBeam(const AFoot: TSdlFPoint; APulse, AAlpha: Single);
begin
  var Reach := FEclipse.Beam(AAlpha);
  if Reach <= 0 then
    Exit;
  var Front := AFoot.Y * Reach;
  var Flash := FEclipse.BeamFlash(AAlpha);
  var Swell := 1 + BeamPulseGrowth * APulse;

  DrawColumn(AFoot.X, Front, BeamGlowAcross * Swell,
    BeamGlowLevel + BeamPulseGlow * APulse + BeamFlashGlow * Flash, BeamGlowTint);
  DrawColumn(AFoot.X, Front, BeamCoreAcross * Swell * (1 + BeamFlashGrowth * Flash),
    BeamCoreLevel, BeamCoreTint);
  if Reach < 1 then
    Exit;
  DrawGlow(FRenderer, FHalo, AFoot.X, AFoot.Y - BodyHeight / 2,
    HaloAcross * Swell, HaloTint, HaloLevel + BeamFlashGlow * Flash);
end;

end.
