{
  Game.Eclipse - the scene of the henshin from the brake of the Ram to
  the beam: the clock it runs by and what it shows at each tick.

  The charge full, the game brakes the Ram and the road, and starts the
  clock. The road runs down for BeltRampTicks; with the world at rest the
  controls are taken and the hero is caught where he is and lifted a
  cell (Game.Hoist) - the rite's orbs (stage 16d) come in on that lift.
  Then the light goes: the world darkens under one overlay, the gauge
  goes out with it, the track fades to silence. In the dark a column of
  light falls from above onto him and stays, beating with the heart.
  From the start nothing wounds the hero.

  The clock knows neither the Ram nor the gauge: the game starts it,
  carries out its cues and reads its levels. TEclipsePainter draws the
  darkness and the beam.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Eclipse;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Game.Belt;

const
  LogicTicksPerSecond = 33;
  // The world at rest: the road has run down
  CatchAt = BeltRampTicks;
  // He is up: the light begins to go
  DimAt = CatchAt + 30;
  // The darkness comes in over this many ticks, the track fading out with it
  DarkTicks = 40;
  EclipseFadeSeconds = DarkTicks / LogicTicksPerSecond;
  DarkDepth = 0.85;
  // The dark is in
  BeamAt = DimAt + DarkTicks;
  BeamFallTicks = 8;
  // The flash of the beam's landing dies over this many ticks
  BeamFlashTicks = 12;

type
  TEclipseCue = record
    // The world at rest: the controls are taken, he is caught and lifted
    Caught: Boolean;
    // The light goes: the darkness starts in, the track fades to silence
    Dim: Boolean;
    // The beam starts down from above
    Beam: Boolean;
  end;

  TEclipseScene = class
  private
    FRunning: Boolean;
    FTicks: Integer;
    function Clock(AAlpha: Single): Single;
  public
    // At the brake: the first tick of the scene is the next one
    procedure Start;
    procedure Clear;
    function Tick: TEclipseCue;
    // From the brake on: nothing wounds the hero
    function Spares: Boolean;
    // From the catch on: the controls are not his
    function Holds: Boolean;
    // Whole ticks since the catch; -1 before
    function Hoisted: Integer;
    // How dark the world is, 0 to DarkDepth, AAlpha ticks past this one
    function Darkness(AAlpha: Single): Single;
    // How far the gauge has gone out with the light, 0..1
    function Fade(AAlpha: Single): Single;
    // How far down the beam has come, 0 at the top of the screen to 1 on him
    function Beam(AAlpha: Single): Single;
    // The landing's flash: 1 as the beam reaches him, gone BeamFlashTicks on
    function BeamFlash(AAlpha: Single): Single;
    property Running: Boolean read FRunning;
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
  // The light runs out below his feet over this much: down to the road
  // he was lifted off
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

{ TEclipseScene }

procedure TEclipseScene.Start;
begin
  FRunning := True;
  FTicks := 0;
end;

procedure TEclipseScene.Clear;
begin
  FRunning := False;
  FTicks := 0;
end;

function TEclipseScene.Tick: TEclipseCue;
begin
  Result := Default(TEclipseCue);
  if not FRunning then
    Exit;
  Inc(FTicks);
  Result.Caught := FTicks = CatchAt;
  Result.Dim := FTicks = DimAt;
  Result.Beam := FTicks = BeamAt;
end;

function TEclipseScene.Spares: Boolean;
begin
  Result := FRunning;
end;

function TEclipseScene.Holds: Boolean;
begin
  Result := FRunning and (FTicks >= CatchAt);
end;

function TEclipseScene.Hoisted: Integer;
begin
  if not Holds then
    Exit(-1);
  Result := FTicks - CatchAt;
end;

function TEclipseScene.Clock(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  Result := FTicks + AAlpha;
end;

function TEclipseScene.Darkness(AAlpha: Single): Single;
begin
  Result := DarkDepth * Fade(AAlpha);
end;

function TEclipseScene.Fade(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  Result := SmoothStep((Clock(AAlpha) - DimAt) / DarkTicks);
end;

function TEclipseScene.Beam(AAlpha: Single): Single;
begin
  if not FRunning or (FTicks < BeamAt) then
    Exit(0);
  Result := SmoothStep((Clock(AAlpha) - BeamAt) / BeamFallTicks);
end;

function TEclipseScene.BeamFlash(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  var Since := Clock(AAlpha) - (BeamAt + BeamFallTicks);
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
