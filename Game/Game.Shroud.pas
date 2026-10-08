{
  Game.Shroud - the hero's shroud: smoke and light that gather round him
  when he appears and when he changes his suit.

  A shroud is a picture over the hero's frame that lives on its own
  clock and dies out: bands of smoke and light cross the body, the body
  may be put together out of strips, a halo flares round it and motes
  drift off. What differs between the scenes is numbers only - a
  TShroudLook; the game says which one to start and when. The shroud
  never takes the controls from the hero.

  Two classes, two reasons to change:
  - THeroShroud counts: the clock, the bands, the strips, the motes. It
    touches no SDL and owns no resources.
  - TShroudPainter draws, and keeps what is made of the hero's art at
    load: the masks, the halos and the points a mote is born at.

  Nothing here knows how the hero looks. Sizes and shapes come from the
  frames, so a redrawn hero brings its own shroud.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Shroud;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Render.Brush, Effects.Emitter, Effects.Sparks,
  Levels.Dynamics, Hero;

const
  ShroudStrips = 16;

type
  EShroudError = class(Exception);

  TShroudOrder = (soTogether, soTopDown, soBottomUp);

  // Ticks, screen units and shares
  TShroudLook = record
    Life: Integer;
    Bands: Integer;
    WidthFrom, WidthTo: Single; // a band at birth and at its end
    Travel: Single; // down the body over a band's life; up below zero
    Order: TShroudOrder;
    Stagger: Single; // the share of Life the last part waits, 0..0.7
    Smoke: Single; // the density of a band's puff
    Light: Single; // the level of a band's light
    Reveal: Boolean; // the body is put together out of strips
    Shift: Single; // how far aside a strip is born
    Flash: Single; // the halo at its peak; above 1 it is drawn twice
    FlashAt: Single; // the share of Life the peak falls on, 0..0.95
    Motes: Single; // born a tick at the peak
    Lift: Single; // a mote's pull, units a tick per tick; up below zero
    Tint: TRgb;
  end;

  TShroudBand = record
    At: Single; // 0 at the head .. 1 at the feet
    Side: Integer; // -1 comes from the left, 1 from the right
    Puff: Integer; // which of the canvas' puffs
    Wide: Single; // its own share of the look's width
    InFront: Boolean; // over the hero, else behind him
  end;

  // Opaque points of one frame, in units from the picture's corner as painted
  TSeedList = TArray<TSdlFPoint>;

  THeroShroud = class
  private
    FSolid: TSolidProbe;
    FDice: TXorShift;
    FLook: TShroudLook;
    FActive: Boolean;
    FAge: Integer;
    FBands: TArray<TShroudBand>;
    FStripSides: array [0..ShroudStrips - 1] of Single;
    FMotes: TParticleSwarm;
    FMoteDebt: Single;
    function GetAssembling: Boolean;
    procedure RollBands;
    procedure RollStrips;
    procedure BirthMotes(const APose: THeroPose; const ASeeds: TSeedList);
    procedure BirthMote(const APose: THeroPose; const ASeed: TSdlFPoint);
    procedure FlyMotes;
    procedure SettleMotes;
  public
    // ASolid answers in screen units
    constructor Create(const ASolid: TSolidProbe; ASeed: Cardinal);
    destructor Destroy; override;
    procedure Start(const ALook: TShroudLook);
    procedure Tick(const APose: THeroPose; const ASeeds: TSeedList);
    // A door: what is in flight stays behind, the light goes with the hero
    procedure LeaveMotes;
    procedure Clear;
    // The share of life gone, 0..1; AAlpha - the step between two ticks
    function Time(AAlpha: Single): Single;
    // The own clock of a place along the body, 0..1
    function PartTime(ATime, AAt: Single): Single;
    function Glow(ATime: Single): Single;
    // Units aside a strip stands at ATime; zero once it is home
    function StripShift(AStrip: Integer; ATime: Single): Single;
    property Active: Boolean read FActive;
    // The body is being put together: the game leaves the hero undrawn
    property Assembling: Boolean read GetAssembling;
    property Look: TShroudLook read FLook;
    property Bands: TArray<TShroudBand> read FBands;
    property Motes: TParticleSwarm read FMotes;
  end;

  // What is made of one hero frame at load
  TShroudFrameArt = record
    Seeds: TSeedList;
    Mask: PSdlTexture; // white, with the frame's alpha
    Halo: PSdlTexture; // the frame's alpha blurred
    HaloMarginX, HaloMarginY: Single; // units the halo reaches past the frame
    TexW, TexH: Integer; // texels of the frame
  end;

  // Where and when the shroud is drawn this frame
  TShroudView = record
    Pose: THeroPose;
    Left, Top: Single; // the frame's corner on the screen, shake and sag in
    Time: Single;
    Glow: Single;
  end;

  TShroudPainter = class
  private
    FRenderer: PSdlRenderer;
    FHero: THero;
    FShroud: THeroShroud;
    FArt: TArray<TShroudFrameArt>;
    procedure BuildFrame(AIndex: Integer; const AName: string);
    function ViewOf(AOrigin: TSdlPoint; ALift, AAlpha: Single): TShroudView;
    procedure DrawBands(const ACanvas: TDynamicCanvas; const AView: TShroudView;
      AInFront: Boolean);
    procedure DrawBand(const ACanvas: TDynamicCanvas; const AView: TShroudView;
      const ABand: TShroudBand);
    procedure DrawHalo(const ACanvas: TDynamicCanvas; const AView: TShroudView);
    procedure DrawStrips(const AView: TShroudView);
    procedure DrawBodyLight(const AView: TShroudView);
    procedure DrawMotes(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
  public
    constructor Create(ARenderer: PSdlRenderer; const AHero: THero;
      const AShroud: THeroShroud);
    destructor Destroy; override;
    function SeedsOf(AFrame: Integer): TSeedList;
    // Behind the hero: the far bands, the halo
    procedure DrawUnder(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      ALift, AAlpha: Single);
    // Over him: the strips while he is assembled, the light on the body,
    // the near bands, the motes
    procedure DrawOver(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      ALift, AAlpha: Single);
  end;

const
  // Back from a pit: quick, the body gathers from the sides
  PitLook: TShroudLook = (
    Life: 14; Bands: 5; WidthFrom: 150; WidthTo: 30; Travel: -3;
    Order: soTogether; Stagger: 0.15; Smoke: 0.75; Light: 0.70;
    Reveal: True; Shift: 18; Flash: 0.9; FlashAt: 0.80;
    Motes: 1.5; Lift: -0.15; Tint: (R: 236; G: 240; B: 255));
  // The first screen of a level: the body comes together from the head down
  EntryLook: TShroudLook = (
    Life: 40; Bands: 9; WidthFrom: 190; WidthTo: 34; Travel: -4;
    Order: soTopDown; Stagger: 0.55; Smoke: 0.80; Light: 0.60;
    Reveal: True; Shift: 26; Flash: 1.1; FlashAt: 0.85;
    Motes: 2.0; Lift: -0.20; Tint: (R: 236; G: 240; B: 255));
  // Alive again after a death: the body comes together from the feet up
  ReviveLook: TShroudLook = (
    Life: 24; Bands: 7; WidthFrom: 120; WidthTo: 32; Travel: -6;
    Order: soBottomUp; Stagger: 0.40; Smoke: 0.90; Light: 0.50;
    Reveal: True; Shift: 12; Flash: 0.8; FlashAt: 0.80;
    Motes: 1.0; Lift: -0.25; Tint: (R: 236; G: 240; B: 255));
  // The ice suit is on: frost spreads off the body and runs down
  IceOnLook: TShroudLook = (
    Life: 130; Bands: 4; WidthFrom: 26; WidthTo: 110; Travel: 30;
    Order: soTopDown; Stagger: 0.60; Smoke: 0.55; Light: 0.25;
    Reveal: False; Shift: 0; Flash: 1.3; FlashAt: 0;
    Motes: 2.5; Lift: 0.12; Tint: (R: 120; G: 200; B: 255));
  // Sparks rising off a suit that burns; nothing starts it yet
  HeatOnLook: TShroudLook = (
    Life: 110; Bands: 0; WidthFrom: 30; WidthTo: 30; Travel: 0;
    Order: soTogether; Stagger: 0; Smoke: 0; Light: 0;
    Reveal: False; Shift: 0; Flash: 1.4; FlashAt: 0;
    Motes: 4.0; Lift: -0.30; Tint: (R: 255; G: 120; B: 48));
  // The ice suit shatters: frost flies off the body
  IceOffLook: TShroudLook = (
    Life: 18; Bands: 4; WidthFrom: 28; WidthTo: 160; Travel: 0;
    Order: soTogether; Stagger: 0.10; Smoke: 0.60; Light: 0.60;
    Reveal: False; Shift: 0; Flash: 1.0; FlashAt: 0;
    Motes: 5.0; Lift: -0.10; Tint: (R: 120; G: 200; B: 255));

implementation

uses
  System.Math, Sprites.Sets, Render.Sprites, Render.Glow, Render.Puff;

resourcestring
  SShroudFrameFailed = 'Cannot build the shroud of the hero frame "%s": %s';
  SShroudMaskFailed = 'Cannot build a shroud mask: %s';

type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888

const
  // A band's place along the body is moved by up to this share of the gap
  // between bands, either way
  BandJitter = 0.5;
  BandWideBase = 0.8;
  BandWideSpread = 0.4;
  StripReachBase = 0.6;
  StripReachSpread = 0.8;

  // The halo dies off as exp(-GlowDecay) over the life that remains after
  // its peak
  GlowDecay = 4;

  // Motes
  MoteDrift = 0.8;
  MoteRise = 3;
  MoteLifeBase = 18;
  MoteLifeSpread = 26;
  MoteSizeBase = 2.5;
  MoteSizeSpread = 3.5;
  MoteDrag = 0.96;
  MotePull = 0.12;
  // A mote lying in matter crawls sideways, faster each tick
  MoteCreep = 1.06;
  MoteStrengthCap = 1.2;
  MoteSpotSize = 2;
  MoteSpotLevel = 0.8;
  MoteCoreSize = 0.8;
  MoteCoreWhite = 0.8;

  // Bands
  BandSlide = 0.25;
  BandsFloor = 3;
  BandThickness = 1.5;
  BandThicknessFloor = 5;
  BandSwell = 0.9;
  SmokeRise = 2;
  SmokeWide = 1.2;
  SmokeThick = 1.3;
  SmokeGrow = 0.8;
  SmokeDensity = 0.85;
  LightWide = 1.1;
  LightThick = 0.7;
  LightWhite = 0.55;

  // Strips
  StripBodyRamp = 2.5;
  StripWhite = 0.7;
  StripLightLevel = 0.8;

  // Light on the body
  SpotSize = 80;
  SpotLevel = 0.35;
  BodyLightLevel = 0.55;
  WhiteFrom = 0.6;
  WhiteLevel = 0.9;
  WhiteMix = 0.7;

  // Frame art
  SeedAlpha = 128;
  // A frame wider than this is shrunk to it before it is blurred
  HaloMaxCells = 64;
  // Units, from the edge of the body
  HaloReach = 2.5;
  HaloPasses = 3;

  // Typed: Power has three overloads
  SmokeWavePower: Single = 0.5;
  LightWavePower: Single = 1.4;
  StripLightPower: Single = 1.5;
  MoteFadePower: Single = 1.2;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function Limit(AValue, ALow, AHigh: Single): Single;
begin
  if AValue < ALow then
    Exit(ALow);
  if AValue > AHigh then
    Exit(AHigh);
  Result := AValue;
end;

function AtLeast(AValue, AFloor: Single): Single;
begin
  if AValue < AFloor then
    Result := AFloor
  else
    Result := AValue;
end;

function AtMost(AValue, ACeiling: Single): Single;
begin
  if AValue > ACeiling then
    Result := ACeiling
  else
    Result := AValue;
end;

function Ease(AShare: Single): Single;
begin
  var Rest: Single := 1 - AShare;
  Result := 1 - Rest * Rest * Rest;
end;

function StripAt(AStrip: Integer): Single;
begin
  Result := (AStrip + 0.5) / ShroudStrips;
end;

function FlipFlag(AMirrored: Boolean): Integer;
begin
  if AMirrored then
    Result := SdlFlipHorizontal
  else
    Result := SdlFlipNone;
end;

function CenteredRect(ACenterX, ACenterY, AWidth, AHeight: Single): TSdlFRect;
begin
  Result.X := ACenterX - AWidth / 2;
  Result.Y := ACenterY - AHeight / 2;
  Result.W := AWidth;
  Result.H := AHeight;
end;

// ---------------------------------------------------------------------------
// Drawing a texture over the screen. The hero's own frame is borrowed for
// the strips and the light: each of these puts the texture's state back
// to alpha 255 and plain blending, or the hero would stay translucent
// or glowing for good.
// ---------------------------------------------------------------------------

procedure PaintHeroPiece(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ASource: PSdlRect; const ADest: TSdlFRect; ALevel: Single;
  AMirrored: Boolean);
begin
  SDL_SetTextureAlphaMod(ATexture, Round(255 * Limit(ALevel, 0, 1)));
  SDL_RenderCopyExF(ARenderer, ATexture, ASource, @ADest, 0.0, nil,
    FlipFlag(AMirrored));
  SDL_SetTextureAlphaMod(ATexture, 255);
end;

procedure PaintHeroLight(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ADest: TSdlFRect; ALevel: Single; AMirrored: Boolean);
begin
  SDL_SetTextureBlendMode(ATexture, SdlBlendModeAdd);
  PaintHeroPiece(ARenderer, ATexture, nil, ADest, ALevel, AMirrored);
  SDL_SetTextureBlendMode(ATexture, SdlBlendModeBlend);
end;

// A piece of a glow texture (additive by its own make), flipped when the
// hero is
procedure PaintGlowPiece(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ASource: PSdlRect; const ADest: TSdlFRect; ATint: TRgb; ALevel: Single;
  AMirrored: Boolean);
begin
  SDL_SetTextureColorMod(ATexture, ATint.R, ATint.G, ATint.B);
  SDL_SetTextureAlphaMod(ATexture, Round(255 * Limit(ALevel, 0, 1)));
  SDL_RenderCopyExF(ARenderer, ATexture, ASource, @ADest, 0.0, nil,
    FlipFlag(AMirrored));
end;

// ---------------------------------------------------------------------------
// What is made of a frame
// ---------------------------------------------------------------------------

function CollectSeeds(ASurface: PSdlSurface): TSeedList;
begin
  SetLength(Result, ASurface.W * ASurface.H);
  var Count := 0;
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    for var Col := 0 to ASurface.W - 1 do
    begin
      if Pixel[3] >= SeedAlpha then
      begin
        Result[Count].X := (Col + 0.5) * HeroSize / ASurface.W;
        Result[Count].Y := (Row + 0.5) * HeroSize / ASurface.H;
        Inc(Count);
      end;
      Inc(Pixel);
    end;
  end;
  SetLength(Result, Count);
end;

function CreateFrameMask(ARenderer: PSdlRenderer;
  ASurface: PSdlSurface): PSdlTexture;
begin
  var Mask := SDL_CreateRGBSurfaceWithFormat(0, ASurface.W, ASurface.H, 32,
    SdlPixelFormatAbgr8888);
  if Mask = nil then
    raise EShroudError.CreateFmt(SShroudMaskFailed, [SdlErrorText]);
  try
    SDL_LockSurface(Mask);
    try
      for var Row := 0 to ASurface.H - 1 do
      begin
        var Source := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
        var Target := PPixelBytes(PByte(Mask.Pixels) + Row * Mask.Pitch);
        for var Col := 0 to ASurface.W - 1 do
        begin
          Target[0] := 255;
          Target[1] := 255;
          Target[2] := 255;
          Target[3] := Source[3];
          Inc(Source);
          Inc(Target);
        end;
      end;
    finally
      SDL_UnlockSurface(Mask);
    end;
    Result := CreateGlowTexture(ARenderer, Mask);
  finally
    SDL_FreeSurface(Mask);
  end;
end;

// The frame's alpha shrunk into the middle of an apron-padded image, blurred
// and made a glow; the margins are how far the apron reaches, in units
function CreateFrameHalo(ARenderer: PSdlRenderer; ASurface: PSdlSurface;
  out AMarginX, AMarginY: Single): PSdlTexture;
var
  Image: TArray<Single>;
begin
  var Scale := (ASurface.W + HaloMaxCells - 1) div HaloMaxCells;
  var CellsX := (ASurface.W + Scale - 1) div Scale;
  var CellsY := (ASurface.H + Scale - 1) div Scale;
  var Radius: Integer := Round(HaloReach * CellsX / HeroSize);
  if Radius < 1 then
    Radius := 1;
  var Apron := Radius * HaloPasses;
  var Width := CellsX + 2 * Apron;
  var Height := CellsY + 2 * Apron;
  SetLength(Image, Width * Height);

  var BlockArea := Scale * Scale * 255;
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    var Target := (Row div Scale + Apron) * Width + Apron;
    for var Col := 0 to ASurface.W - 1 do
    begin
      var Cell := Target + Col div Scale;
      Image[Cell] := Image[Cell] + Pixel[3] / BlockArea;
      Inc(Pixel);
    end;
  end;

  BlurImage(Image, Width, Height, Radius, HaloPasses);
  AMarginX := Apron * (HeroSize * Scale / ASurface.W);
  AMarginY := Apron * (HeroSize * Scale / ASurface.H);
  Result := CreateGlowFromImage(ARenderer, Image, Width, Height);
end;

// ---------------------------------------------------------------------------
// THeroShroud
// ---------------------------------------------------------------------------

constructor THeroShroud.Create(const ASolid: TSolidProbe; ASeed: Cardinal);
begin
  inherited Create;
  FSolid := ASolid;
  FDice.Seed := ASeed;
  // A zero seed would freeze the stream at zero
  if FDice.Seed = 0 then
    FDice.Seed := 1;
  FMotes := TParticleSwarm.Create;
end;

destructor THeroShroud.Destroy;
begin
  FMotes.Free;
  inherited;
end;

function THeroShroud.GetAssembling: Boolean;
begin
  Result := FActive and FLook.Reveal;
end;

procedure THeroShroud.Start(const ALook: TShroudLook);
begin
  FLook := ALook;
  FAge := 0;
  FActive := True;
  FMoteDebt := 0;
  RollBands;
  RollStrips;
end;

procedure THeroShroud.RollBands;
begin
  SetLength(FBands, FLook.Bands);
  for var i := 0 to High(FBands) do
  begin
    var Band: TShroudBand;
    Band.At := (i + 0.5) / FLook.Bands +
      (FDice.NextUnit - 0.5) * BandJitter / FLook.Bands;
    if Odd(i) then
      Band.Side := 1
    else
      Band.Side := -1;
    Band.Puff := i mod PuffShapes;
    Band.Wide := BandWideBase + BandWideSpread * FDice.NextUnit;
    Band.InFront := not Odd(i);
    FBands[i] := Band;
  end;
end;

procedure THeroShroud.RollStrips;
begin
  for var j := 0 to ShroudStrips - 1 do
  begin
    var Reach: Single := StripReachBase + StripReachSpread * FDice.NextUnit;
    if Odd(j) then
      FStripSides[j] := Reach
    else
      FStripSides[j] := -Reach;
  end;
end;

procedure THeroShroud.Tick(const APose: THeroPose; const ASeeds: TSeedList);
begin
  if FActive then
  begin
    Inc(FAge);
    if FAge >= FLook.Life then
      FActive := False;
  end;
  if FActive then
    BirthMotes(APose, ASeeds);
  FlyMotes;
end;

procedure THeroShroud.LeaveMotes;
begin
  FMotes.Clear;
end;

procedure THeroShroud.Clear;
begin
  FActive := False;
  FMotes.Clear;
end;

function THeroShroud.Time(AAlpha: Single): Single;
begin
  if not FActive or (FLook.Life <= 0) then
    Exit(1);
  Result := Limit((FAge + AAlpha) / FLook.Life, 0, 1);
end;

function THeroShroud.PartTime(ATime, AAt: Single): Single;
begin
  var Queue: Single := 0;
  case FLook.Order of
    soTopDown: Queue := AAt;
    soBottomUp: Queue := 1 - AAt;
  end;
  Result := Limit((ATime - Queue * FLook.Stagger) / (1 - FLook.Stagger), 0, 1);
end;

function THeroShroud.Glow(ATime: Single): Single;
begin
  if FLook.Flash <= 0 then
    Exit(0);
  if ATime < FLook.FlashAt then
    Result := FLook.Flash * Sqr(ATime / FLook.FlashAt)
  else
    Result := FLook.Flash *
      Exp(-GlowDecay * (ATime - FLook.FlashAt) / (1 - FLook.FlashAt));
end;

function THeroShroud.StripShift(AStrip: Integer; ATime: Single): Single;
begin
  var Part := PartTime(ATime, StripAt(AStrip));
  Result := Round(FStripSides[AStrip] * FLook.Shift * (1 - Ease(Part)));
end;

procedure THeroShroud.BirthMotes(const APose: THeroPose;
  const ASeeds: TSeedList);
begin
  if (FLook.Flash <= 0) or (Length(ASeeds) = 0) then
    Exit;
  var Strength := Limit(Glow(Time(0)) / FLook.Flash, 0, MoteStrengthCap);
  FMoteDebt := FMoteDebt + FLook.Motes * Strength;
  while FMoteDebt >= 1 do
  begin
    FMoteDebt := FMoteDebt - 1;
    BirthMote(APose, ASeeds[Trunc(FDice.NextUnit * Length(ASeeds))]);
  end;
end;

procedure THeroShroud.BirthMote(const APose: THeroPose;
  const ASeed: TSdlFPoint);
begin
  var Mote := Default(TParticle);
  var SeedX := ASeed.X;
  if APose.Mirrored then
    SeedX := HeroSize - SeedX;
  Mote.X := APose.Left + SeedX;
  Mote.Y := APose.Top + ASeed.Y;
  Mote.SpeedX := (FDice.NextUnit - 0.5) * MoteDrift;
  Mote.SpeedY := FLook.Lift * (0.5 + FDice.NextUnit) * MoteRise;
  Mote.Life := MoteLifeBase + Trunc(FDice.NextUnit * MoteLifeSpread);
  Mote.Scale := MoteSizeBase + MoteSizeSpread * FDice.NextUnit;
  Mote.Weight := 1;
  FMotes.Add(Mote);
end;

procedure THeroShroud.FlyMotes;
begin
  FMotes.Advance(MoteDrag, 0, FLook.Lift * MotePull);
  if (FLook.Lift > 0) and Assigned(FSolid) then
    SettleMotes;
end;

// A sinking mote that has gone into matter steps back the way it came, loses
// its fall and creeps aside: frost lies on floors and pads
procedure THeroShroud.SettleMotes;
begin
  var Pull := FLook.Lift * MotePull;
  for var i := 0 to FMotes.Count - 1 do
  begin
    var Mote := FMotes[i];
    if not FSolid(Mote.X, Mote.Y) then
      Continue;
    Mote.Y := Mote.Y - (Mote.SpeedY - Pull) / MoteDrag;
    Mote.SpeedY := 0;
    Mote.SpeedX := Mote.SpeedX * MoteCreep;
  end;
end;

// ---------------------------------------------------------------------------
// TShroudPainter
// ---------------------------------------------------------------------------

constructor TShroudPainter.Create(ARenderer: PSdlRenderer; const AHero: THero;
  const AShroud: THeroShroud);
begin
  inherited Create;
  FRenderer := ARenderer;
  FHero := AHero;
  FShroud := AShroud;

  var Names: TArray<string> := [];
  for var Sequence in HeroFrameSequences do
    Names := Names + AHero.SkinSet.SequenceFrames(Sequence);
  SetLength(FArt, Length(Names));
  for var i := 0 to High(Names) do
    BuildFrame(i, Names[i]);
end;

destructor TShroudPainter.Destroy;
begin
  for var Art in FArt do
  begin
    if Assigned(Art.Mask) then
      SDL_DestroyTexture(Art.Mask);
    if Assigned(Art.Halo) then
      SDL_DestroyTexture(Art.Halo);
  end;
  inherited;
end;

procedure TShroudPainter.BuildFrame(AIndex: Integer; const AName: string);
begin
  var Loaded := LoadImageSurface(FHero.SkinSet, AName);
  if Loaded = nil then
    raise EShroudError.CreateFmt(SShroudFrameFailed, [AName, SdlErrorText]);
  var Surface := SDL_ConvertSurfaceFormat(Loaded, SdlPixelFormatAbgr8888, 0);
  SDL_FreeSurface(Loaded);
  if Surface = nil then
    raise EShroudError.CreateFmt(SShroudFrameFailed, [AName, SdlErrorText]);
  try
    FArt[AIndex].TexW := Surface.W;
    FArt[AIndex].TexH := Surface.H;
    SDL_LockSurface(Surface);
    try
      FArt[AIndex].Seeds := CollectSeeds(Surface);
      FArt[AIndex].Mask := CreateFrameMask(FRenderer, Surface);
      FArt[AIndex].Halo := CreateFrameHalo(FRenderer, Surface,
        FArt[AIndex].HaloMarginX, FArt[AIndex].HaloMarginY);
    finally
      SDL_UnlockSurface(Surface);
    end;
  finally
    SDL_FreeSurface(Surface);
  end;
end;

function TShroudPainter.SeedsOf(AFrame: Integer): TSeedList;
begin
  if (AFrame < 1) or (AFrame > Length(FArt)) then
    Exit(nil);
  Result := FArt[AFrame - 1].Seeds;
end;

function TShroudPainter.ViewOf(AOrigin: TSdlPoint; ALift,
  AAlpha: Single): TShroudView;
begin
  Result.Pose := FHero.Pose;
  Result.Left := Result.Pose.Left + AOrigin.X;
  Result.Top := Result.Pose.Top + AOrigin.Y + ALift;
  Result.Time := FShroud.Time(AAlpha);
  Result.Glow := FShroud.Glow(Result.Time);
end;

procedure TShroudPainter.DrawUnder(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; ALift, AAlpha: Single);
begin
  if not FShroud.Active then
    Exit;
  var View := ViewOf(AOrigin, ALift, AAlpha);
  DrawBands(ACanvas, View, False);
  DrawHalo(ACanvas, View);
end;

procedure TShroudPainter.DrawOver(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; ALift, AAlpha: Single);
begin
  if FShroud.Active then
  begin
    var View := ViewOf(AOrigin, ALift, AAlpha);
    if FShroud.Assembling then
      DrawStrips(View);
    DrawBodyLight(View);
    DrawBands(ACanvas, View, True);
  end;
  DrawMotes(ACanvas, AOrigin, AAlpha);
end;

procedure TShroudPainter.DrawBands(const ACanvas: TDynamicCanvas;
  const AView: TShroudView; AInFront: Boolean);
begin
  for var Band in FShroud.Bands do
    if Band.InFront = AInFront then
      DrawBand(ACanvas, AView, Band);
end;

procedure TShroudPainter.DrawBand(const ACanvas: TDynamicCanvas;
  const AView: TShroudView; const ABand: TShroudBand);
begin
  var Look := FShroud.Look;
  var Part := FShroud.PartTime(AView.Time, ABand.At);
  if (Part <= 0) or (Part >= 1) then
    Exit;

  var Eased := Ease(Part);
  var Wide := Lerp(Look.WidthFrom, Look.WidthTo, Eased) * ABand.Wide;
  var Slide: Single := 0;
  if Look.WidthFrom > Look.WidthTo then
    Slide := ABand.Side * (Wide - Look.WidthTo) * BandSlide;
  var MidX: Single := AView.Left + HeroSize / 2 + Slide;
  var Row := AtMost(AView.Top + ABand.At * HeroSize + Look.Travel * Eased,
    AView.Top + HeroSize - 1);
  var Thickness: Single := AtLeast(
    HeroSize / Max(Look.Bands, BandsFloor) * BandThickness,
    BandThicknessFloor) * (1 + BandSwell * Part);
  var Wave: Single := Sin(Pi * Part);

  var SmokeRect := CenteredRect(MidX, Row - SmokeRise * Part, SmokeWide * Wide,
    Thickness * (SmokeThick + SmokeGrow * Part));
  var SmokeLevel := Power(Wave, SmokeWavePower) * Look.Smoke * SmokeDensity;
  DrawPuffRect(ACanvas.Renderer, ACanvas.Puffs[ABand.Puff], SmokeRect,
    Look.Tint, Limit(SmokeLevel, 0, 1));

  var LightRect := CenteredRect(MidX, Row, LightWide * Wide,
    LightThick * Thickness);
  var LightLevel := Power(Wave, LightWavePower) * Look.Light;
  DrawGlowRect(ACanvas.Renderer, ACanvas.PointGlow, LightRect,
    Mix(Look.Tint, White, LightWhite), Limit(LightLevel, 0, 1));
end;

procedure TShroudPainter.DrawHalo(const ACanvas: TDynamicCanvas;
  const AView: TShroudView);
begin
  if AView.Glow <= 0 then
    Exit;
  var Look := FShroud.Look;
  var Art := FArt[AView.Pose.Frame - 1];

  var Spot := CenteredRect(AView.Left + HeroSize / 2, AView.Top + HeroSize / 2,
    SpotSize, SpotSize);
  DrawGlowRect(ACanvas.Renderer, ACanvas.PointGlow, Spot, Look.Tint,
    Limit(AView.Glow * SpotLevel, 0, 1));

  var Dest: TSdlFRect;
  Dest.X := AView.Left - Art.HaloMarginX;
  Dest.Y := AView.Top - Art.HaloMarginY;
  Dest.W := HeroSize + 2 * Art.HaloMarginX;
  Dest.H := HeroSize + 2 * Art.HaloMarginY;
  PaintGlowPiece(FRenderer, Art.Halo, nil, Dest, Look.Tint,
    AtMost(AView.Glow, 1), AView.Pose.Mirrored);
  if AView.Glow > 1 then
    PaintGlowPiece(FRenderer, Art.Halo, nil, Dest, Look.Tint,
      AView.Glow - 1, AView.Pose.Mirrored);
end;

procedure TShroudPainter.DrawStrips(const AView: TShroudView);
begin
  var Look := FShroud.Look;
  var Art := FArt[AView.Pose.Frame - 1];
  var Light := Mix(Look.Tint, White, StripWhite);
  for var i := 0 to ShroudStrips - 1 do
  begin
    var Part := FShroud.PartTime(AView.Time, StripAt(i));
    if Part <= 0 then
      Continue;

    var Source: TSdlRect;
    Source.X := 0;
    Source.Y := i * Art.TexH div ShroudStrips;
    Source.W := Art.TexW;
    Source.H := (i + 1) * Art.TexH div ShroudStrips - Source.Y;

    var Dest: TSdlFRect;
    Dest.X := AView.Left + FShroud.StripShift(i, AView.Time);
    Dest.Y := AView.Top + Source.Y * HeroSize / Art.TexH;
    Dest.W := HeroSize;
    Dest.H := Source.H * HeroSize / Art.TexH;

    PaintHeroPiece(FRenderer, AView.Pose.Texture, @Source, Dest,
      Part * StripBodyRamp, AView.Pose.Mirrored);
    var Rest: Single := 1 - Part;
    PaintGlowPiece(FRenderer, Art.Mask, @Source, Dest, Light,
      Power(Rest, StripLightPower) * StripLightLevel, AView.Pose.Mirrored);
  end;
end;

procedure TShroudPainter.DrawBodyLight(const AView: TShroudView);
begin
  if AView.Glow <= 0 then
    Exit;
  var Frame: TSdlFRect;
  Frame.X := AView.Left;
  Frame.Y := AView.Top;
  Frame.W := HeroSize;
  Frame.H := HeroSize;
  PaintHeroLight(FRenderer, AView.Pose.Texture, Frame,
    AView.Glow * BodyLightLevel, AView.Pose.Mirrored);
  if AView.Glow > WhiteFrom then
    PaintGlowPiece(FRenderer, FArt[AView.Pose.Frame - 1].Mask, nil, Frame,
      Mix(FShroud.Look.Tint, White, WhiteMix),
      (AView.Glow - WhiteFrom) * WhiteLevel, AView.Pose.Mirrored);
end;

procedure TShroudPainter.DrawMotes(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Swarm := FShroud.Motes;
  var Tint := FShroud.Look.Tint;
  var CoreTint := Mix(Tint, White, MoteCoreWhite);
  for var i := 0 to Swarm.Count - 1 do
  begin
    var Mote := Swarm[i];
    var Fade: Single := 1 - Mote.Age / Mote.Life;
    var Strength: Single := Power(Fade, MoteFadePower);
    var X := Mote.X + Mote.SpeedX * AAlpha + AOrigin.X;
    var Y := Mote.Y + Mote.SpeedY * AAlpha + AOrigin.Y;
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X, Y,
      MoteSpotSize * Mote.Scale, Tint, MoteSpotLevel * Strength);
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, X, Y,
      MoteCoreSize * Mote.Scale, CoreTint, Strength);
  end;
end;

end.
