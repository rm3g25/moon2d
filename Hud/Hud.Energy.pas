{
  Hud.Energy - the charge of the form: a small eclipse in the slot the
  heart monitor's panel grows on its right. A black disc in a light halo;
  the charge runs round its rim as an arc of light, from the top and
  clockwise, and its number stands in the middle of the disc, in percent. Full, the
  ring breathes. Until the first of the charge comes there is no slot;
  with the charge gone, the slot folds back.

  The gauge observes rather than listens, as the monitor does: it takes
  the charge every tick and reacts to the difference. A rise is eased in
  and flashes; a fall is shown at once - a death takes the charge back,
  and that is no spending to watch.

  The reading and the picture are apart: TEnergyReading counts and says
  how open the slot is and how far the arc has come; THudEnergy draws.
  The rim is drawn as strips of light along the circle - the band glow
  the go-right arrow is drawn with - so it stays round at any size of
  the window.

  At the last of the charge the gauge rides out of its slot to the top
  centre, where the level's title stands, growing on the way, and stays
  there: the slot is left open and empty. It beats with the heart there;
  the pulse is the game's to give (Game.Heartbeat), the gauge only draws
  it. TGaugeRide counts the ride.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Energy;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush;

const
  // A full charge: the form is ready
  FullEnergy = 100;

type
  TEnergyReading = class
  private
    FCharge: Integer;
    FWing: Single;
    FArc: Single;
    FFlashTicks: Integer;
    FAge: Integer;
    procedure EaseWing;
    procedure EaseArc;
  public
    // Once per logic tick, with the charge as of now, 0..FullEnergy
    procedure Tick(ACharge: Integer);
    property Charge: Integer read FCharge;
    // How open the slot is, 0..1
    property Wing: Single read FWing;
    // The charge the arc shows, eased toward Charge
    property Arc: Single read FArc;
    // The flash of a rise, 1 at the tick of it and down to 0
    function Flash: Single;
    property Age: Integer read FAge; // ticks
  end;

  // The gauge's way from its slot to the top centre: eased in and out,
  // growing as it goes; standing there once it is up
  TGaugeRide = class
  private
    FLifted: Boolean;
    FTicks: Integer;
    function Share(AAlpha: Single): Single;
  public
    // From the slot, from the start of the way
    procedure Lift;
    // Back in the slot at once
    procedure Dock;
    procedure Tick;
    // The middle of the disc on the screen, AAlpha ticks past this one
    function Center(AAlpha: Single): TSdlFPoint;
    // The disc's size against its size in the slot
    function Scale(AAlpha: Single): Single;
    // At the top centre, the way behind it
    function Up: Boolean;
    property Lifted: Boolean read FLifted;
  end;

  THudEnergy = class
  private
    FRenderer: PSdlRenderer;
    FBrush: THudBrush;
    FReading: TEnergyReading;
    FRide: TGaugeRide;
    // Where and how big this frame draws the disc
    FCenter: TSdlFPoint;
    FScale: Single;
    FBeam: PSdlTexture;
    FHalo: PSdlTexture;
    FBody: PSdlTexture;
    FVertices: TArray<TSdlVertex>;
    FIndices: TArray<Integer>;
    function Breath(AAlpha: Single): Single;
    procedure DrawHalo(AShown, ABreath, APulse: Single);
    procedure DrawRim(AFrom, ASweep, AWidth: Single; ATint: TRgb;
      ALevel: Single);
    procedure DrawArc(AShown, ABreath: Single);
    procedure DrawNumber(AShown: Single);
  public
    constructor Create(ARenderer: PSdlRenderer);
    destructor Destroy; override;
    procedure Tick(ACharge: Integer);
    // APulse - the heartbeat, 0..1; 0 when the heart is still
    procedure Draw(AAlpha, APulse: Single);
    // To the top centre, for good: the slot stays empty
    procedure Lift;
    procedure Dock;
    // Units the slot widens the monitor's panel by, as open as it is
    function WingWidth: Single;
    // The middle of the disc, on the screen: where the charge flies to
    class function Heart: TSdlFPoint;
    property Reading: TEnergyReading read FReading;
    property Ride: TGaugeRide read FRide;
  end;

implementation

uses
  System.Math, Game.Space, Render.Font, Render.Glow, Hud.Messages;

const
  SlotWidth = 32; // as the reward slot of the charge panel
  WingTicks = 8;
  FlashTicks = 14;
  // Each tick the arc closes this share of the way to the charge, and
  // stands on it once this near
  ArcPull = 0.12;
  ArcSnap = 0.05;
  BreathSpeed = 0.1; // radians a tick
  FullBreathSpeed = 0.4;

  DiscRadius = 10;
  // The moon's light, as its orbs and its burst have it
  MoonGlow: TRgb = (R: 225; G: 212; B: 255);
  MoonBody: TRgb = (R: 6; G: 0; B: 14);
  HaloAcross = 40;
  HaloLevel = 0.3;
  HaloBreath = 0.12;
  HaloFlash = 0.5;
  HaloFullBreath = 0.3;
  // The whole rim, faint: where the charge has yet to come
  TrackWidth = 1.2;
  TrackLevel = 0.15;
  // The arc: a soft strip of light under a thin bright one
  ArcHaloWidth = 4;
  ArcHaloLevel = 0.35;
  ArcCoreWidth = 1.6;
  ArcCoreLevel = 0.95;
  ArcCoreWhiteness = 0.6;
  HeadAcross = 5;
  HeadLevel = 0.9;
  // The number and its percent sign are small enough for "100%" inside
  // the disc; the sign is smaller still and stands on the line
  NumberPixel = 1.4;
  // Three digits: the corners of "100%" would touch the rim
  FullNumberPixel = 1.2;
  PercentPixel = 1.0;
  PercentGap = 1;
  GlyphCols = 3;
  GlyphRows = 5;

  // Segments of a whole circle: the arc takes its share of them
  CircleSegments = 64;
  BeamGlowSide = 64;
  GlowSide = 64;

  // The ride: about two seconds; three times its size in the slot
  RideTicks = 66;
  RideScale = 3;
  // A beat swells the disc by this share of its size and lights its halo
  PulseGrowth = 0.08;
  HaloPulse = 0.45;

{ TEnergyReading }

procedure TEnergyReading.Tick(ACharge: Integer);
begin
  Inc(FAge);
  var Rose := ACharge > FCharge;
  var Fell := ACharge < FCharge;
  FCharge := ACharge;
  if FFlashTicks > 0 then
    Dec(FFlashTicks);
  if Rose then
    FFlashTicks := FlashTicks;
  if Fell then
    FArc := FCharge;
  EaseWing;
  EaseArc;
end;

procedure TEnergyReading.EaseWing;
const
  WingStep: Single = 1 / WingTicks;
begin
  if FCharge > 0 then
    FWing := Min(FWing + WingStep, 1)
  else
    FWing := Max(FWing - WingStep, 0);
end;

procedure TEnergyReading.EaseArc;
begin
  FArc := FArc + (FCharge - FArc) * ArcPull;
  if Abs(FCharge - FArc) < ArcSnap then
    FArc := FCharge;
end;

function TEnergyReading.Flash: Single;
begin
  Result := FFlashTicks / FlashTicks;
end;

{ TGaugeRide }

procedure TGaugeRide.Lift;
begin
  FLifted := True;
  FTicks := 0;
end;

procedure TGaugeRide.Dock;
begin
  FLifted := False;
  FTicks := 0;
end;

procedure TGaugeRide.Tick;
begin
  if FLifted and (FTicks < RideTicks) then
    Inc(FTicks);
end;

function TGaugeRide.Up: Boolean;
begin
  Result := FLifted and (FTicks >= RideTicks);
end;

// 0 in the slot, 1 up; smooth at both ends of the way
function TGaugeRide.Share(AAlpha: Single): Single;
begin
  if not FLifted then
    Exit(0);
  var Way: Single := Min((FTicks + AAlpha) / RideTicks, 1);
  Result := Way * Way * (3 - 2 * Way);
end;

function TGaugeRide.Center(AAlpha: Single): TSdlFPoint;
begin
  var Slot := THudEnergy.Heart;
  var Top: TSdlFPoint;
  Top.X := FrameWidth / 2;
  Top.Y := BigMessageY + BigGlyphHeight / 2;
  var Way := Share(AAlpha);
  Result.X := Slot.X + (Top.X - Slot.X) * Way;
  Result.Y := Slot.Y + (Top.Y - Slot.Y) * Way;
end;

function TGaugeRide.Scale(AAlpha: Single): Single;
begin
  Result := 1 + (RideScale - 1) * Share(AAlpha);
end;

{ THudEnergy }

constructor THudEnergy.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FRenderer := ARenderer;
  FBrush := THudBrush.Create(ARenderer);
  FReading := TEnergyReading.Create;
  FRide := TGaugeRide.Create;
  FBeam := CreateGlowShape(ARenderer, gsBeam, BeamGlowSide);
  FHalo := CreateGlowShape(ARenderer, gsPoint, GlowSide);
  FBody := CreateShadeShape(ARenderer, gsDisc, GlowSide);

  // Two vertices a point, across the strip; two triangles a segment
  SetLength(FVertices, 2 * (CircleSegments + 1));
  SetLength(FIndices, 6 * CircleSegments);
  for var i := 0 to CircleSegments - 1 do
  begin
    var Here := 2 * i;
    var Next := 2 * (i + 1);
    FIndices[6 * i] := Here;
    FIndices[6 * i + 1] := Here + 1;
    FIndices[6 * i + 2] := Next;
    FIndices[6 * i + 3] := Here + 1;
    FIndices[6 * i + 4] := Next + 1;
    FIndices[6 * i + 5] := Next;
  end;
end;

destructor THudEnergy.Destroy;
begin
  if FBody <> nil then
    SDL_DestroyTexture(FBody);
  if FHalo <> nil then
    SDL_DestroyTexture(FHalo);
  if FBeam <> nil then
    SDL_DestroyTexture(FBeam);
  FRide.Free;
  FReading.Free;
  FBrush.Free;
  inherited;
end;

procedure THudEnergy.Tick(ACharge: Integer);
begin
  FReading.Tick(ACharge);
  FRide.Tick;
end;

procedure THudEnergy.Lift;
begin
  FRide.Lift;
end;

procedure THudEnergy.Dock;
begin
  FRide.Dock;
end;

function THudEnergy.WingWidth: Single;
begin
  Result := SlotWidth * FReading.Wing;
end;

class function THudEnergy.Heart: TSdlFPoint;
begin
  Result.X := PanelMargin + PanelW + SlotWidth / 2;
  Result.Y := PanelY + PanelH / 2;
end;

// 0..1; a full ring breathes faster
function THudEnergy.Breath(AAlpha: Single): Single;
begin
  var Speed: Single := BreathSpeed;
  if FReading.Charge >= FullEnergy then
    Speed := FullBreathSpeed;
  Result := 0.5 + 0.5 * Sin((FReading.Age + AAlpha) * Speed);
end;

procedure THudEnergy.Draw(AAlpha, APulse: Single);
begin
  var Shown := FReading.Wing;
  if Shown <= 0 then
    Exit;
  FCenter := FRide.Center(AAlpha);
  FScale := FRide.Scale(AAlpha) * (1 + PulseGrowth * APulse);

  var Breathing := Breath(AAlpha);
  DrawHalo(Shown, Breathing, APulse);
  DrawGlow(FRenderer, FBody, FCenter.X, FCenter.Y,
    2 * DiscRadius * FScale, MoonBody, Shown);
  DrawRim(0, 2 * Pi, TrackWidth, MoonGlow, TrackLevel * Shown);
  DrawArc(Shown, Breathing);
  DrawNumber(Shown);
end;

procedure THudEnergy.DrawHalo(AShown, ABreath, APulse: Single);
begin
  var Level: Single := HaloLevel + HaloBreath * ABreath +
    HaloFlash * FReading.Flash + HaloPulse * APulse;
  if FReading.Charge >= FullEnergy then
    Level := Level + HaloFullBreath * ABreath;
  DrawGlow(FRenderer, FHalo, FCenter.X, FCenter.Y, HaloAcross * FScale,
    MoonGlow, Level * AShown);
end;

// A strip AWidth across along the rim, from the top AFrom radians on and
// ASweep radians long, clockwise as the picture turns
procedure THudEnergy.DrawRim(AFrom, ASweep, AWidth: Single; ATint: TRgb;
  ALevel: Single);
begin
  var Segments := EnsureRange(Ceil(CircleSegments * ASweep / (2 * Pi)), 1,
    CircleSegments);
  var Alpha: UInt8 := Round(255 * EnsureRange(ALevel, 0, 1));
  for var i := 0 to Segments do
  begin
    var Angle: Single := -Pi / 2 + AFrom + ASweep * i / Segments;
    for var Side := 0 to 1 do
    begin
      var Radius: Single := (DiscRadius + (0.5 - Side) * AWidth) * FScale;
      var Corner := 2 * i + Side;
      FVertices[Corner].Position.X := FCenter.X + Cos(Angle) * Radius;
      FVertices[Corner].Position.Y := FCenter.Y + Sin(Angle) * Radius;
      FVertices[Corner].Color.R := ATint.R;
      FVertices[Corner].Color.G := ATint.G;
      FVertices[Corner].Color.B := ATint.B;
      FVertices[Corner].Color.A := Alpha;
      FVertices[Corner].TexCoord.X := 0.5;
      FVertices[Corner].TexCoord.Y := Side;
    end;
  end;
  SDL_RenderGeometry(FRenderer, FBeam, @FVertices[0], 2 * (Segments + 1),
    @FIndices[0], 6 * Segments);
end;

procedure THudEnergy.DrawArc(AShown, ABreath: Single);
begin
  var Sweep: Single := 2 * Pi * FReading.Arc / FullEnergy;
  if Sweep <= 0 then
    Exit;
  var CoreLevel: Single := ArcCoreLevel;
  if FReading.Charge >= FullEnergy then
    CoreLevel := 0.7 + 0.3 * ABreath;
  DrawRim(0, Sweep, ArcHaloWidth, MoonGlow, ArcHaloLevel * AShown);
  DrawRim(0, Sweep, ArcCoreWidth, Mix(MoonGlow, White, ArcCoreWhiteness),
    CoreLevel * AShown);

  var HeadAngle: Single := -Pi / 2 + Sweep;
  var HeadRadius := DiscRadius * FScale;
  DrawGlow(FRenderer, FHalo, FCenter.X + Cos(HeadAngle) * HeadRadius,
    FCenter.Y + Sin(HeadAngle) * HeadRadius, HeadAcross * FScale, White,
    HeadLevel * AShown);
end;

procedure THudEnergy.DrawNumber(AShown: Single);
begin
  var Value := FReading.Charge;
  if Value <= 0 then
    Exit;
  var Pixel: Single := NumberPixel;
  if Value >= FullEnergy then
    Pixel := FullNumberPixel;
  Pixel := Pixel * FScale;
  var SignPixel: Single := PercentPixel * FScale;
  var Gap: Single := PercentGap * FScale;
  var DigitsWidth := NumberWidth(Value, Pixel);
  var Width := DigitsWidth + Gap + GlyphCols * SignPixel;
  var X := FCenter.X - Width / 2;
  var Y := FCenter.Y - GlyphRows * Pixel / 2;
  var Color := Mix(MoonGlow, White, FReading.Flash);
  FBrush.BeginDraw;
  FBrush.DrawNumber(Value, X, Y, Color, AShown, Pixel);
  FBrush.DrawPercent(X + DigitsWidth + Gap,
    Y + GlyphRows * (Pixel - SignPixel), Color, AShown, SignPixel);
  FBrush.EndDraw;
end;

end.
