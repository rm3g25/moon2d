{
  Game.BargeFire - the fire on a knocked barge: a flame where the shell
  struck its deck, a glow flickering about it, black smoke the flight's
  wind tears off and streams back, and the shorts of its torn wiring -
  small bolts crackling out of the wound in fits. One for each barge of the
  pool. It burns while the caller says, where the caller says; once its
  barge is gone what it put in the air goes on streaming back and fades.

  It knows neither the flock nor the pads: the caller gives each barge's
  wound every tick, and the wind. Decoration - nothing here wounds.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.BargeFire;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Levels.Dynamics;

type
  // Where a barge of the pool burns this tick, if it does
  TBargeWound = record
    At: TSdlFPoint;
    Burning: Boolean;
  end;

  TBargeFire = class
  private
    FFlames: TArray<TSmoke>;
    FSmokes: TArray<TSmoke>;
    FShorts: TArray<TLightning>;
    FBurning: TArray<Boolean>;
    // The wound, this tick and the last, for the glow between the ticks
    FWounds, FLastWounds: TArray<TSdlFPoint>;
    FAge: Integer;
  public
    // One fire for each of ACount barges
    constructor Create(ACount: Integer);
    destructor Destroy; override;
    // A death, a new level: nothing burns, nothing in the air
    procedure Clear;
    // AWounds - one for each barge, in the caller's order: where it burns
    // this tick, if it does; what the fires put out drifts AWind across,
    // below 0 to the left. A fire that starts starts at its wound.
    procedure Tick(const AWounds: TArray<TBargeWound>; AWind: Single);
    // The smoke, then the flames, their glow and the shorts
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  end;

implementation

uses
  System.Math, Render.Brush, Render.Glow, Levels.Tint;

const
  // Short and hot, licking up out of the wound
  FlameLook: TSmokeLook = (Rate: 70; Life: 0.3; Size: 3; EndSize: 9;
    Opacity: 0.85; Angle: 90; Cone: 70; Speed: 22; Drag: 0.6; Lift: 0;
    Wind: 0; Turbulence: 4; Spin: 60; Flow: sfSteady; Frequency: 1;
    Heat: 1; EndTint: (R: 26; G: 24; B: 24));
  FlameTint: TColorTint = (R: 44; G: 42; B: 40);
  // Long and black, rising and spreading as the wind takes it
  SmokeLook: TSmokeLook = (Rate: 44; Life: 1.8; Size: 5; EndSize: 32;
    Opacity: 0.55; Angle: 90; Cone: 40; Speed: 20; Drag: 0.5; Lift: 8;
    Wind: 0; Turbulence: 5; Spin: 30; Flow: sfGusty; Frequency: 2;
    Heat: 0.15; EndTint: (R: 70; G: 68; B: 66));
  SmokeTint: TColorTint = (R: 34; G: 32; B: 30);
  // The flames' share of the wind: they cling to the wound
  FlameWindShare = 0.3;
  FlameSeed = $42466C31; // "BFl1"
  SmokeSeed = $42536D31; // "BSm1"
  ShortSeed = $42536831; // "BSh1"

  // The torn wiring shorting out: small crooked bolts about the wound, a
  // fit of crackling, then a pause
  ShortLook: TLightningLook = (Reach: 14; Spread: (X: 10; Y: 3);
    Angle: 90; Cone: 360; Collide: lcNone; Size: 0.7; Jag: 0.3; Fork: 0.25;
    Frequency: 6; Strokes: 2; Life: 0.08; Leader: 0; Spell: 0.6; Pause: 0.7;
    Flash: 0.35; Jolt: 0; Tint: (R: 66; G: 74; B: 100));

  GlowColor: TRgb = (R: 255; G: 130; B: 40);
  GlowSize = 20.0;
  GlowLevel = 0.7;
  // The glow flickers by this share, over two beats that drift apart
  GlowFlicker = 0.3;
  GlowBeatTicks = 3.0;
  GlowSlowBeatTicks = 7.0;

constructor TBargeFire.Create(ACount: Integer);
begin
  inherited Create;
  var FlamePlacement := Default(TDynamicPlacement);
  FlamePlacement.Tint := FlameTint;
  var SmokePlacement := Default(TDynamicPlacement);
  SmokePlacement.Tint := SmokeTint;
  SetLength(FFlames, ACount);
  SetLength(FSmokes, ACount);
  SetLength(FShorts, ACount);
  SetLength(FBurning, ACount);
  SetLength(FWounds, ACount);
  SetLength(FLastWounds, ACount);
  for var i := 0 to ACount - 1 do
  begin
    FFlames[i] := TSmoke.CreateLook(FlamePlacement, FlameLook, 1,
      FlameSeed xor Cardinal(i + 1));
    FSmokes[i] := TSmoke.CreateLook(SmokePlacement, SmokeLook, 1,
      SmokeSeed xor Cardinal(i + 1));
    FShorts[i] := TLightning.CreateLook(Default(TDynamicPlacement), ShortLook,
      1, ShortSeed xor Cardinal(i + 1));
  end;
end;

destructor TBargeFire.Destroy;
begin
  for var Short in FShorts do
    Short.Free;
  for var Smoke in FSmokes do
    Smoke.Free;
  for var Flame in FFlames do
    Flame.Free;
  inherited;
end;

procedure TBargeFire.Clear;
begin
  for var i := 0 to High(FFlames) do
  begin
    FFlames[i].Rewind;
    FSmokes[i].Rewind;
    FShorts[i].Rewind;
    FBurning[i] := False;
  end;
end;

procedure TBargeFire.Tick(const AWounds: TArray<TBargeWound>; AWind: Single);
begin
  Inc(FAge);
  for var i := 0 to Min(High(AWounds), High(FFlames)) do
  begin
    var Wound := AWounds[i];
    if Wound.Burning and not FBurning[i] then
    begin
      FFlames[i].ForgetOrigin;
      FSmokes[i].ForgetOrigin;
      FShorts[i].ForgetOrigin;
      FWounds[i] := Wound.At;
    end;
    // Out, the source stays where it last burned: what it put out is
    // drawn from there
    if not Wound.Burning then
      Wound.At := FWounds[i];
    FBurning[i] := Wound.Burning;
    FLastWounds[i] := FWounds[i];
    FWounds[i] := Wound.At;
    FFlames[i].Drift(AWind * FlameWindShare, 0);
    FSmokes[i].Drift(AWind, 0);
    FFlames[i].Tick(Wound.At.X, Wound.At.Y, Wound.Burning);
    FSmokes[i].Tick(Wound.At.X, Wound.At.Y, Wound.Burning);
    FShorts[i].Tick(Wound.At.X, Wound.At.Y, Wound.Burning);
  end;
end;

procedure TBargeFire.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  for var Smoke in FSmokes do
    Smoke.Draw(ACanvas, Smoke.Origin.X + AOrigin.X, Smoke.Origin.Y + AOrigin.Y,
      AAlpha);
  for var Flame in FFlames do
    Flame.Draw(ACanvas, Flame.Origin.X + AOrigin.X, Flame.Origin.Y + AOrigin.Y,
      AAlpha);
  var Time := FAge + AAlpha;
  var Flicker := 1 - GlowFlicker * (0.5 + 0.25 * Sin(2 * Pi * Time / GlowBeatTicks) +
    0.25 * Sin(2 * Pi * Time / GlowSlowBeatTicks));
  for var i := 0 to High(FBurning) do
  begin
    if not FBurning[i] then
      Continue;
    var X := FLastWounds[i].X + (FWounds[i].X - FLastWounds[i].X) * AAlpha;
    var Y := FLastWounds[i].Y + (FWounds[i].Y - FLastWounds[i].Y) * AAlpha;
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X + AOrigin.X, Y + AOrigin.Y,
      GlowSize, GlowColor, GlowLevel * Flicker);
  end;
  for var Short in FShorts do
    Short.Draw(ACanvas, Short.Origin.X + AOrigin.X, Short.Origin.Y + AOrigin.Y,
      AAlpha);
end;

end.
