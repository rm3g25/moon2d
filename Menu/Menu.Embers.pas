{
  Menu.Embers - sparks drifting off the edges of the title logo.

  At startup the outline of the letters is read from their alpha: every
  ink texel with air beside it becomes a seed, with the way to the air
  as its normal. An ember is born on a random seed, flies out along
  the normal with a lift that bends it upward, cools from orange to red
  and fades, then is reborn elsewhere. How many fly at once follows the
  length of the outline, so a redrawn logo keeps the same feel.

  Everything is measured in letter texels; Draw scales to the units of
  the rectangle the letters are drawn into.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Menu.Embers;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush;

type
  TEmberSeed = record
    X, Y: Single; // texel center
    NormalX, NormalY: Single; // unit vector toward the air
  end;

  TEmber = record
    X, Y: Single; // texels
    SpeedX, SpeedY: Single; // texels per tick
    Size: Single; // units
    Age: Integer; // ticks
    Life: Integer; // ticks
  end;

  TEmbers = class
  private
    FRenderer: PSdlRenderer;
    FTexture: PSdlTexture;
    FSeeds: TArray<TEmberSeed>;
    FEmbers: TArray<TEmber>;
    FRandom: TXorShift;
    procedure ReadOutline(ASurface: PSdlSurface);
    function Spawn: TEmber;
  public
    // The surface is the locked letters art, ABGR8888
    constructor Create(ARenderer: PSdlRenderer; ASurface: PSdlSurface);
    destructor Destroy; override;
    procedure Tick;
    procedure Draw(const ADest: TSdlFRect; AAlpha: Double;
      ALettersWidth, ALettersHeight: Integer);
  end;

implementation

uses
  System.Math, Render.Glow;

type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888

const
  // "Fire" in ASCII: the same sparks on every run. Anything but zero -
  // xorshift never leaves zero.
  EmbersSeed = $46697265;
  InkAlpha = 128;
  // One ember in flight per this many outline texels
  OutlinePerEmber = 200;
  EmberTextureSide = 8;

  EmberSizeMin = 1.2; // units
  EmberSizeMax = 2.2;
  EmberSpeedMin = 0.5; // texels per tick, along the normal
  EmberSpeedMax = 1.2;
  EmberSideSpread = 0.4; // share of the speed thrown sideways
  EmberLift = 0.015; // texels per tick per tick, upward
  EmberDrag = 0.985; // speed kept per tick
  EmberLifeMin = 70; // ticks
  EmberLifeMax = 140;
  EmberLevel = 0.7;
  EmberFadeShare = 0.4; // the last share of the life fades out

  EmberBirthColor: TRgb = (R: 255; G: 170; B: 60);
  EmberDeathColor: TRgb = (R: 255; G: 40; B: 20);

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

// ---------------------------------------------------------------------------
// TEmbers
// ---------------------------------------------------------------------------

constructor TEmbers.Create(ARenderer: PSdlRenderer; ASurface: PSdlSurface);
begin
  inherited Create;
  FRenderer := ARenderer;
  FTexture := CreateGlowShape(ARenderer, gsPoint, EmberTextureSide);
  FRandom.Seed := EmbersSeed;
  ReadOutline(ASurface);

  var Count := Max(1, Length(FSeeds) div OutlinePerEmber);
  SetLength(FEmbers, Count);
  for var i := 0 to High(FEmbers) do
  begin
    FEmbers[i] := Spawn;
    // Staggered at birth: the sky must not start with one burst
    FEmbers[i].Age := Round(FRandom.NextUnit * FEmbers[i].Life);
  end;
end;

destructor TEmbers.Destroy;
begin
  if Assigned(FTexture) then
    SDL_DestroyTexture(FTexture);
  inherited;
end;

// Every ink texel with an air neighbor; the normal is the alpha slope
// downhill, and a texel with no slope (a one-texel island) points up
procedure TEmbers.ReadOutline(ASurface: PSdlSurface);

  function AlphaAt(ACol, ARow: Integer): Integer;
  begin
    if (ACol < 0) or (ARow < 0) or (ACol >= ASurface.W) or
      (ARow >= ASurface.H) then
      Exit(0);
    Result := PPixelBytes(PByte(ASurface.Pixels) + ARow * ASurface.Pitch +
      ACol * SizeOf(TPixelBytes))[3];
  end;

begin
  for var Row := 0 to ASurface.H - 1 do
    for var Col := 0 to ASurface.W - 1 do
    begin
      if AlphaAt(Col, Row) < InkAlpha then
        Continue;
      var Left := AlphaAt(Col - 1, Row);
      var Right := AlphaAt(Col + 1, Row);
      var Above := AlphaAt(Col, Row - 1);
      var Below := AlphaAt(Col, Row + 1);
      var HasAir := Min(Min(Left, Right), Min(Above, Below)) < InkAlpha;
      if not HasAir then
        Continue;

      var Seed: TEmberSeed;
      Seed.X := Col + 0.5;
      Seed.Y := Row + 0.5;
      Seed.NormalX := Left - Right;
      Seed.NormalY := Above - Below;
      var Slope := Sqrt(Sqr(Seed.NormalX) + Sqr(Seed.NormalY));
      if Slope > 0 then
      begin
        Seed.NormalX := Seed.NormalX / Slope;
        Seed.NormalY := Seed.NormalY / Slope;
      end
      else
        Seed.NormalY := -1;
      FSeeds := FSeeds + [Seed];
    end;
end;

function TEmbers.Spawn: TEmber;
begin
  var Seed := FSeeds[Trunc(FRandom.NextUnit * Length(FSeeds))];
  var Speed := Lerp(EmberSpeedMin, EmberSpeedMax, FRandom.NextUnit);
  var Side := (2 * FRandom.NextUnit - 1) * EmberSideSpread * Speed;
  Result.X := Seed.X;
  Result.Y := Seed.Y;
  // Along the normal, plus a sideways throw along its perpendicular
  Result.SpeedX := Seed.NormalX * Speed - Seed.NormalY * Side;
  Result.SpeedY := Seed.NormalY * Speed + Seed.NormalX * Side;
  Result.Size := Lerp(EmberSizeMin, EmberSizeMax, FRandom.NextUnit);
  Result.Age := 0;
  Result.Life := Round(Lerp(EmberLifeMin, EmberLifeMax, FRandom.NextUnit));
end;

procedure TEmbers.Tick;
begin
  for var i := 0 to High(FEmbers) do
  begin
    var Ember := FEmbers[i];
    Inc(Ember.Age);
    if Ember.Age >= Ember.Life then
    begin
      FEmbers[i] := Spawn;
      Continue;
    end;
    Ember.X := Ember.X + Ember.SpeedX;
    Ember.Y := Ember.Y + Ember.SpeedY;
    Ember.SpeedX := Ember.SpeedX * EmberDrag;
    Ember.SpeedY := Ember.SpeedY * EmberDrag - EmberLift;
    FEmbers[i] := Ember;
  end;
end;

procedure TEmbers.Draw(const ADest: TSdlFRect; AAlpha: Double;
  ALettersWidth, ALettersHeight: Integer);
begin
  var UnitsX := ADest.W / ALettersWidth;
  var UnitsY := ADest.H / ALettersHeight;
  for var Ember in FEmbers do
  begin
    var Heat: Single := Ember.Age / Ember.Life; // 0 at birth, 1 at death
    var Fade: Single := (1 - Heat) / EmberFadeShare;
    if Fade > 1 then
      Fade := 1;
    var Tint := Mix(EmberBirthColor, EmberDeathColor, Heat);
    DrawGlow(FRenderer, FTexture,
      ADest.X + (Ember.X + Ember.SpeedX * AAlpha) * UnitsX,
      ADest.Y + (Ember.Y + Ember.SpeedY * AAlpha) * UnitsY,
      Ember.Size, Tint, EmberLevel * Fade);
  end;
end;

end.
