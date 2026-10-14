{
  Game.Cannons - the two TeK cannons of the gravel arena: guns clamped to
  the side faces of the wall pillars that do not aim. They ride the walls
  in unison, face to face, always on one row; at a row they warn with a red
  fire at the muzzles and sweep it with a long burst from both sides at
  once. A row a volley sweeps is closed, the others are free. The shield of
  each cannon takes the rounds of the other and the hero's bullets; a round
  wounds the hero alone - a gravel is no one's target.

  A pair lives one act of the gravel trial. When the trial moves past it,
  the shields fall, the barrels overheat, the pair races up and down the
  walls, stops face to face over the pyramid and shoots itself to pieces:
  a scene, not a death of hits, and nothing in it wounds.

  When a cannon is to ride through the rows a bank of shelves stands in
  its way at, the bank goes into the wall first, and comes out once the
  cannon has left those rows.

  The rules and the look. The game carries out the cue of a tick: the
  sounds, the hero's wound, the shelves, the sparks and the blast.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Cannons;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Render.Sprites,
  Sprites.Sets, Levels.Events, Levels.Dynamics, Game.Shield;

type
  TCannonSide = (csLeft, csRight);

  // What a hero's bullet ran into
  TCannonBlock = (cbNone, cbShield, cbHull);

  // The game's word on a round's stretch of this tick, from AFromX to
  // AToX at AY: True - something in its way took it, and it flies no more
  TRoundCatch = reference to function(AFromX, AToX, AY: Single): Boolean;

  TCannonCue = record
    // padhum: before a volley, and through the race of the scene
    Hum: Boolean;
    // A burst is speaking: one shot sound stands for a few rounds
    Shot: Boolean;
    HeroHit: Boolean;
    YieldSleep: Boolean;
    YieldWake: Boolean;
    // Rounds on bare steel in the scene: sparks, no wound
    Strikes: TArray<TSdlFPoint>;
    // Both blow up now, at these points
    Blast: Boolean;
    BlastPoints: array [TCannonSide] of TSdlFPoint;
  end;

  // The art of a cannon and the light it needs, through a cache of its
  // own: painted with soft edges, so no color key; drawn at a size of its
  // own, so linear filtering
  TCannonArt = class
  private
    FSpriteSet: TSpriteSet;
    FCache: TSpriteCache;
    FHull: PSdlTexture;
    FHeat: PSdlTexture;
    FShield: TShieldArt;
  public
    constructor Create(ARenderer: PSdlRenderer);
    destructor Destroy; override;
  end;

  TCannonPhase = (cpGone, cpArriving, cpYielding, cpRiding, cpWarning,
    cpFiring, cpResting, cpRacing, cpHalting, cpHolding, cpDueling);

  TCannonPair = class
  private type
    TRound = record
      X, LastX: Single;
      Y: Single;
      From: TCannonSide;
      Harmless: Boolean;
    end;
  private
    FArt: TCannonArt;
    FOrders: TCannonOrders;
    FAct: Integer;
    FPhase: TCannonPhase;
    // The phase a move runs in, once the shelves have gone
    FMovePhase: TCannonPhase;
    FPhaseTicks: Integer;
    // The top edge of both cannons, screen units
    FTop, FLastTop: Single;
    FTargetTop: Single;
    FSpeed: Single;
    FArrivalAge: Integer;
    FSlide, FLastSlide: Single; // 0 on the wall .. 1 beyond the edge
    FLeaving: Boolean;
    FYieldAsleep: Boolean;
    FRaceLegs: Integer;
    FHumAge: Integer;
    FRow: Integer;
    FBurstAge: Integer;
    FHeat, FLastHeat: Single; // 0..1, the barrels
    FWarm, FLastWarm: Single; // 0..1, the red fire at the muzzles
    FFlash, FLastFlash: Single; // 0..1, the flash of the last shot
    FRounds: TList<TRound>;
    FShields: array [TCannonSide] of TTekShield;
    FDice: TXorShift;
    FCue: TCannonCue;
    function CannonLeft(ASide: TCannonSide; ASlide: Single): Single;
    function Middle(ASide: TCannonSide; ATop, ASlide: Single): TSdlFPoint;
    function ArtPoint(ASide: TCannonSide; AX, AY, ATop,
      ASlide: Single): TSdlFPoint;
    function Muzzle(ASide: TCannonSide; ABarrel: Integer): TSdlFPoint;
    function CrossesBand(AFrom, ATo: Single): Boolean;
    procedure BeginMove(ATop, ASpeed: Single; APhase: TCannonPhase);
    procedure BeginVolleyMove;
    procedure BeginLeaving;
    procedure BeginRaceLeg;
    procedure TickSlide;
    procedure TickHum;
    procedure TickYield;
    procedure TickPhase;
    procedure TickMove;
    procedure Arrive;
    procedure Fire;
    procedure TickRounds(const AHeroBody: TSdlFRect; const ACatch: TRoundCatch);
    function RoundEnds(var ARound: TRound): Boolean;
    function RoundMeets(const ARound: TRound;
      const ABody: TSdlFRect): Boolean;
    function HullMeets(const ABox: TSdlFRect; out ASide: TCannonSide): Boolean;
    procedure Blow;
    procedure DrawCannon(const ASprites: TSpriteRenderer; ASide: TCannonSide;
      ATop, ASlide, AHeat: Single);
    procedure DrawRounds(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawMuzzles(const ACanvas: TDynamicCanvas; ASide: TCannonSide;
      ATop, ASlide: Single; AOrigin: TSdlPoint; AAlpha: Single);
  public
    // AArt belongs to the caller and must outlive the pair
    constructor Create(AArt: TCannonArt; ASeed: Cardinal);
    destructor Destroy; override;
    // Both slide in from beyond the edges for the act AAct of the trial
    procedure Start(const AOrders: TCannonOrders; AAct: Integer);
    // A door, a death: gone at once, with no scene
    procedure Clear;
    // AAct - the act the trial is in now, 0 when it does not run;
    // AHeroBody - where the living hero is, empty for the dead; ACatch -
    // asked of every round that can wound, before the hero is
    function Tick(AAct: Integer; const AHeroBody: TSdlFRect;
      const ACatch: TRoundCatch): TCannonCue;
    // Where a bullet's stretch of this tick runs into a cannon; a shield
    // lights up where it was struck
    function Block(const AFrom, ATo: TSdlFPoint;
      out AAt: TSdlFPoint): TCannonBlock;
    // The hero's body touches a cannon: on which side. In the scene of the
    // end nothing wounds.
    function Touches(const ABody: TSdlFRect; out ASide: TCannonSide): Boolean;
    // The bodies, through the sprites' origin
    procedure DrawBodies(const ASprites: TSpriteRenderer; AAlpha: Single);
    // The light: rounds, muzzles, lens, shields; AOrigin - the shake
    procedure DrawLight(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    function Active: Boolean;
    // The scene of their end plays: the next act waits for it
    property Leaving: Boolean read FLeaving;
    // The shelves the orders name in their way; '' - none
    property YieldBank: string read FOrders.YieldBank;
  end;

implementation

uses
  System.Math, System.SysUtils, Game.Space, Render.Glow;

const
  CannonSetName = 'tek-cannon';
  // Two cells by one; the art faces right
  CannonWidth = 64;
  CannonHeight = 32;
  // On the side faces of the pillars: col 0 and col 15 are the walls
  LeftCannonX = TileSize;
  RightCannonX = ScreenWidth - TileSize - CannonWidth;
  // Beyond the edge a cannon slides in from
  SlideDistance = TileSize + CannonWidth;
  // Measured on the art (tools/cannon/build_cannon.py), right-facing
  MuzzleX = 63.4;
  MuzzleY: array [0..1] of Single = (14.07, 21.54);
  LensX = 32.16;
  LensY = 12.37;
  // The clamp plate, the receiver, the barrels: the empty air over and
  // under the barrels does not wound
  ContactBoxes: array [0..2] of TSdlFRect = (
    (X: 0.61; Y: 0.65; W: 7.69; H: 30.56),
    (X: 8.30; Y: 7.03; W: 32.47; H: 18.69),
    (X: 40.77; Y: 11.69; W: 22.62; H: 12.26));
  ShieldRadiusX = 38;
  ShieldRadiusY = 22;

  // Where the scene plays: over the pyramid, out of the hero's way
  SceneRow = 2;
  ArrivalTicks = 30;
  RideSpeed = 3.0;
  // The red fire before a volley; the riding there is the first warning
  WarnTicks = 20;
  BurstTicks = 40;
  ShotEveryTicks = 2;
  ShotSoundEveryTicks = 4;
  RoundSpeed = 16;
  RoundLength = 18;
  RoundThickness = 3;
  // A volley's rounds reach the other shield before the pair rides on
  RestTicks = 22;
  // The shelf's own warning and its slide into the wall (0.6 + 0.25 s)
  YieldTicks = 28;
  RaceSpeed = 8.0;
  RaceLegs = 5;
  RaceTopRow = 1;
  RaceBottomRow = 6;
  // How often padhum sounds through the race: about its length
  RaceHumTicks = 36;
  HeatTicks = 100;
  HaltTicks = 16;
  DuelTicks = 50;
  // One spark fan in this many rounds of the duel
  StrikeEvery = 2;
  FlashFade = 0.5;

  FireColor: TRgb = (R: 255; G: 40; B: 18);
  FlashColor: TRgb = (R: 255; G: 232; B: 168);
  RoundColor: TRgb = (R: 255; G: 196; B: 96);
  HeatColor: TRgb = (R: 255; G: 64; B: 24);
  LensRestLevel: Single = 0.25;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

function BoxesMeet(const AFirst, ASecond: TSdlFRect): Boolean;
begin
  Result := (AFirst.X < ASecond.X + ASecond.W) and
    (ASecond.X < AFirst.X + AFirst.W) and
    (AFirst.Y < ASecond.Y + ASecond.H) and (ASecond.Y < AFirst.Y + AFirst.H);
end;

function Opposite(ASide: TCannonSide): TCannonSide;
begin
  if ASide = csLeft then
    Result := csRight
  else
    Result := csLeft;
end;

// ---------------------------------------------------------------------------
// TCannonArt
// ---------------------------------------------------------------------------

constructor TCannonArt.Create(ARenderer: PSdlRenderer);
begin
  inherited Create;
  FSpriteSet := TSpriteSet.Create(SpriteSetsDir + CannonSetName + '.mset');
  FCache := TSpriteCache.Create(ARenderer);
  FCache.DisableColorKey;
  FCache.EnableLinearFilter;
  FCache.AttachSpriteSet(FSpriteSet);
  FHull := FCache.Get('hull');
  FHeat := FCache.Get('heat');
  SDL_SetTextureBlendMode(FHeat, SdlBlendModeAdd);
  SDL_SetTextureColorMod(FHeat, HeatColor.R, HeatColor.G, HeatColor.B);
  FShield := TShieldArt.Create(ARenderer);
end;

// The cache before the set: it reads from the set, never the reverse
destructor TCannonArt.Destroy;
begin
  FShield.Free;
  FCache.Free;
  FSpriteSet.Free;
  inherited;
end;

// ---------------------------------------------------------------------------
// TCannonPair
// ---------------------------------------------------------------------------

constructor TCannonPair.Create(AArt: TCannonArt; ASeed: Cardinal);
begin
  inherited Create;
  FArt := AArt;
  FDice.Seed := ASeed or 1;
  FRounds := TList<TRound>.Create;
  for var Side := Low(TCannonSide) to High(TCannonSide) do
    FShields[Side] := TTekShield.Create(ShieldRadiusX, ShieldRadiusY);
end;

destructor TCannonPair.Destroy;
begin
  for var Side := Low(TCannonSide) to High(TCannonSide) do
    FShields[Side].Free;
  FRounds.Free;
  inherited;
end;

function TCannonPair.Active: Boolean;
begin
  Result := FPhase <> cpGone;
end;

procedure TCannonPair.Start(const AOrders: TCannonOrders; AAct: Integer);
begin
  Clear;
  FOrders := AOrders;
  FAct := AAct;
  FPhase := cpArriving;
  FTop := SceneRow * TileSize;
  FLastTop := FTop;
  FTargetTop := FTop;
  FRow := SceneRow;
  FArrivalAge := 0;
  FSlide := 1;
  FLastSlide := 1;
  for var Side := Low(TCannonSide) to High(TCannonSide) do
    FShields[Side].Rise;
end;

procedure TCannonPair.Clear;
begin
  FPhase := cpGone;
  FLeaving := False;
  FYieldAsleep := False;
  FRounds.Clear;
  FHeat := 0;
  FLastHeat := 0;
  FWarm := 0;
  FLastWarm := 0;
  FFlash := 0;
  FLastFlash := 0;
end;

function TCannonPair.CannonLeft(ASide: TCannonSide; ASlide: Single): Single;
begin
  if ASide = csLeft then
    Result := LeftCannonX - ASlide * SlideDistance
  else
    Result := RightCannonX + ASlide * SlideDistance;
end;

function TCannonPair.Middle(ASide: TCannonSide; ATop,
  ASlide: Single): TSdlFPoint;
begin
  Result.X := CannonLeft(ASide, ASlide) + CannonWidth / 2;
  Result.Y := ATop + CannonHeight / 2;
end;

// A point of the right-facing art; the right cannon is its mirror
function TCannonPair.ArtPoint(ASide: TCannonSide; AX, AY, ATop,
  ASlide: Single): TSdlFPoint;
begin
  var Across := AX;
  if ASide = csRight then
    Across := CannonWidth - AX;
  Result.X := CannonLeft(ASide, ASlide) + Across;
  Result.Y := ATop + AY;
end;

function TCannonPair.Muzzle(ASide: TCannonSide; ABarrel: Integer): TSdlFPoint;
begin
  Result := ArtPoint(ASide, MuzzleX, MuzzleY[ABarrel], FTop, FSlide);
end;

// A ride from AFrom to ATo, tops of the cannons, passes the rows of the
// yield bank
function TCannonPair.CrossesBand(AFrom, ATo: Single): Boolean;
begin
  if FOrders.YieldBank = '' then
    Exit(False);
  var BandTop: Single := MinIntValue(FOrders.YieldRows) * TileSize;
  var BandBottom: Single := (MaxIntValue(FOrders.YieldRows) + 1) * TileSize;
  Result := (Min(AFrom, ATo) < BandBottom) and
    (Max(AFrom, ATo) + CannonHeight > BandTop);
end;

// A ride to ATop at ASpeed in APhase - the shelves in its way go first
procedure TCannonPair.BeginMove(ATop, ASpeed: Single; APhase: TCannonPhase);
begin
  FTargetTop := ATop;
  FSpeed := ASpeed;
  FMovePhase := APhase;
  // Shelves still on their way into the wall: the new ride waits for them
  if FPhase = cpYielding then
    Exit;
  FPhase := APhase;
  if FYieldAsleep or not CrossesBand(FTop, FTargetTop) then
    Exit;
  FYieldAsleep := True;
  FCue.YieldSleep := True;
  FPhase := cpYielding;
  FPhaseTicks := YieldTicks;
end;

// Any row of the orders but the one they stand at
procedure TCannonPair.BeginVolleyMove;
begin
  var Choices: TArray<Integer> := nil;
  for var Row in FOrders.Rows do
    if Row <> FRow then
      Choices := Choices + [Row];
  if Choices = nil then
    Choices := FOrders.Rows;
  var Pick := Min(High(Choices), Trunc(FDice.NextUnit * Length(Choices)));
  FRow := Choices[Pick];
  BeginMove(FRow * TileSize, RideSpeed, cpRiding);
end;

procedure TCannonPair.BeginLeaving;
begin
  FLeaving := True;
  FWarm := 0;
  for var Side := Low(TCannonSide) to High(TCannonSide) do
    FShields[Side].Fall;
  for var i := 0 to FRounds.Count - 1 do
  begin
    var Flying := FRounds[i];
    Flying.Harmless := True;
    FRounds[i] := Flying;
  end;
  FRaceLegs := RaceLegs;
  FBurstAge := 0;
  FHumAge := 0;
  FCue.Hum := True;
  BeginRaceLeg;
end;

// To whichever end of the race is farther
procedure TCannonPair.BeginRaceLeg;
begin
  var Upper: Single := RaceTopRow * TileSize;
  var Lower: Single := RaceBottomRow * TileSize;
  var Target := Upper;
  if Abs(FTop - Lower) > Abs(FTop - Upper) then
    Target := Lower;
  BeginMove(Target, RaceSpeed, cpRacing);
end;

function TCannonPair.Tick(AAct: Integer; const AHeroBody: TSdlFRect;
  const ACatch: TRoundCatch): TCannonCue;
begin
  FCue := Default(TCannonCue);
  Result := FCue;
  if FPhase = cpGone then
    Exit;

  FLastTop := FTop;
  FLastHeat := FHeat;
  FLastWarm := FWarm;
  FLastFlash := FFlash;
  FFlash := FFlash * FlashFade;
  for var Side := Low(TCannonSide) to High(TCannonSide) do
    FShields[Side].Tick;

  if not FLeaving and (AAct <> FAct) then
    BeginLeaving;
  TickSlide;
  TickHum;
  TickPhase;
  TickYield;
  TickRounds(AHeroBody, ACatch);
  if FLeaving then
    FHeat := Min(FHeat + 1 / HeatTicks, 1.0);
  Result := FCue;
end;

procedure TCannonPair.TickSlide;
begin
  FLastSlide := FSlide;
  if FArrivalAge >= ArrivalTicks then
    Exit;
  Inc(FArrivalAge);
  FSlide := 1 - SmoothStep(FArrivalAge / ArrivalTicks);
end;

// padhum keeps sounding while they race
procedure TCannonPair.TickHum;
begin
  if not FLeaving or (FPhase in [cpHolding, cpDueling]) then
    Exit;
  Inc(FHumAge);
  if FHumAge mod RaceHumTicks = 0 then
    FCue.Hum := True;
end;

// Out of the band and riding no more into it: the shelves come back
procedure TCannonPair.TickYield;
begin
  if not FYieldAsleep or (FPhase = cpYielding) then
    Exit;
  if CrossesBand(FTop, FTargetTop) then
    Exit;
  FYieldAsleep := False;
  FCue.YieldWake := True;
end;

procedure TCannonPair.TickPhase;
begin
  case FPhase of
    cpArriving:
      if FArrivalAge >= ArrivalTicks then
        Arrive;
    cpYielding:
      begin
        Dec(FPhaseTicks);
        if FPhaseTicks <= 0 then
          FPhase := FMovePhase;
      end;
    cpRiding, cpRacing, cpHalting:
      TickMove;
    cpWarning:
      begin
        Dec(FPhaseTicks);
        FWarm := 1 - FPhaseTicks / WarnTicks;
        if FPhaseTicks > 0 then
          Exit;
        FPhase := cpFiring;
        FPhaseTicks := BurstTicks;
        FBurstAge := 0;
      end;
    cpFiring, cpDueling:
      begin
        Fire;
        Dec(FPhaseTicks);
        if FPhaseTicks > 0 then
          Exit;
        if FPhase = cpDueling then
        begin
          Blow;
          Exit;
        end;
        FWarm := 0;
        FPhase := cpResting;
        FPhaseTicks := RestTicks;
      end;
    cpResting:
      begin
        Dec(FPhaseTicks);
        if FPhaseTicks <= 0 then
          BeginVolleyMove;
      end;
    cpHolding:
      begin
        Dec(FPhaseTicks);
        if FPhaseTicks > 0 then
          Exit;
        FPhase := cpDueling;
        FPhaseTicks := DuelTicks;
        FBurstAge := 0;
      end;
  end;
end;

// On the wall: the first row of the fight, or the race if the act is
// over already
procedure TCannonPair.Arrive;
begin
  if FLeaving then
    BeginRaceLeg
  else
    BeginVolleyMove;
end;

procedure TCannonPair.TickMove;
begin
  var Remaining := FTargetTop - FTop;
  if Abs(Remaining) > FSpeed then
  begin
    FTop := FTop + Sign(Remaining) * FSpeed;
    Exit;
  end;
  FTop := FTargetTop;

  case FPhase of
    cpRiding:
      begin
        FPhase := cpWarning;
        FPhaseTicks := WarnTicks;
        FCue.Hum := True;
      end;
    cpRacing:
      begin
        Dec(FRaceLegs);
        if FRaceLegs > 0 then
          BeginRaceLeg
        else
          BeginMove(SceneRow * TileSize, RaceSpeed, cpHalting);
      end;
    cpHalting:
      begin
        FPhase := cpHolding;
        FPhaseTicks := HaltTicks;
      end;
  end;
end;

// Both cannons at once, the barrels in turn; the duel's rounds wound no one
procedure TCannonPair.Fire;
begin
  if FPhase = cpFiring then
    FWarm := 1;
  if FBurstAge mod ShotSoundEveryTicks = 0 then
    FCue.Shot := True;
  if FBurstAge mod ShotEveryTicks = 0 then
  begin
    var Barrel := (FBurstAge div ShotEveryTicks) mod Length(MuzzleY);
    for var Side := Low(TCannonSide) to High(TCannonSide) do
    begin
      var Start := Muzzle(Side, Barrel);
      var Shot: TRound;
      Shot.X := Start.X;
      Shot.LastX := Start.X;
      Shot.Y := Start.Y;
      Shot.From := Side;
      Shot.Harmless := FPhase = cpDueling;
      FRounds.Add(Shot);
    end;
    FFlash := 1;
  end;
  Inc(FBurstAge);
end;

procedure TCannonPair.TickRounds(const AHeroBody: TSdlFRect;
  const ACatch: TRoundCatch);
begin
  for var i := FRounds.Count - 1 downto 0 do
  begin
    var Flying := FRounds[i];
    Flying.LastX := Flying.X;
    if Flying.From = csLeft then
      Flying.X := Flying.X + RoundSpeed
    else
      Flying.X := Flying.X - RoundSpeed;
    var Caught := not Flying.Harmless and Assigned(ACatch) and
      ACatch(Flying.LastX, Flying.X, Flying.Y);
    if Caught then
    begin
      FRounds.Delete(i);
      Continue;
    end;
    if not Flying.Harmless and RoundMeets(Flying, AHeroBody) then
      FCue.HeroHit := True;
    if RoundEnds(Flying) then
      FRounds.Delete(i)
    else
      FRounds[i] := Flying;
  end;
end;

// Into the other cannon's shield, onto its bare steel in the scene, or
// into the wall behind it
function TCannonPair.RoundEnds(var ARound: TRound): Boolean;
begin
  var Target := Opposite(ARound.From);
  var Heart := Middle(Target, FTop, FSlide);
  var From: TSdlFPoint;
  From.X := ARound.LastX - Heart.X;
  From.Y := ARound.Y - Heart.Y;
  var Till: TSdlFPoint;
  Till.X := ARound.X - Heart.X;
  Till.Y := From.Y;
  var Entry: TSdlFPoint;
  if FShields[Target].TryEntry(From, Till, Entry) then
  begin
    FShields[Target].Strike(Entry);
    Exit(True);
  end;

  var Tip := Muzzle(Target, 0).X;
  var Reached := ((ARound.From = csLeft) and (ARound.X >= Tip)) or
    ((ARound.From = csRight) and (ARound.X <= Tip));
  var BareSteel := Reached and (FPhase = cpDueling) and
    (FShields[Target].State = sdDown);
  if BareSteel and (FBurstAge mod (StrikeEvery * ShotEveryTicks) = 0) then
  begin
    var Strike: TSdlFPoint;
    Strike.X := Tip;
    Strike.Y := ARound.Y;
    FCue.Strikes := FCue.Strikes + [Strike];
  end;
  if BareSteel then
    Exit(True);
  Result := (ARound.X < 0) or (ARound.X > ScreenWidth);
end;

function TCannonPair.RoundMeets(const ARound: TRound;
  const ABody: TSdlFRect): Boolean;
begin
  if (ABody.W <= 0) or (ARound.Y < ABody.Y) or (ARound.Y > ABody.Y + ABody.H) then
    Exit(False);
  var Nearer := Min(ARound.LastX, ARound.X);
  var Farther := Max(ARound.LastX, ARound.X);
  Result := (Nearer < ABody.X + ABody.W) and (Farther > ABody.X);
end;

procedure TCannonPair.Blow;
begin
  FCue.Blast := True;
  for var Side := Low(TCannonSide) to High(TCannonSide) do
    FCue.BlastPoints[Side] := Middle(Side, FTop, FSlide);
  Clear;
end;

function TCannonPair.Block(const AFrom, ATo: TSdlFPoint;
  out AAt: TSdlFPoint): TCannonBlock;
begin
  AAt := ATo;
  if FPhase = cpGone then
    Exit(cbNone);
  for var Side := Low(TCannonSide) to High(TCannonSide) do
  begin
    var Heart := Middle(Side, FTop, FSlide);
    var From: TSdlFPoint;
    From.X := AFrom.X - Heart.X;
    From.Y := AFrom.Y - Heart.Y;
    var Till: TSdlFPoint;
    Till.X := ATo.X - Heart.X;
    Till.Y := ATo.Y - Heart.Y;
    var Entry: TSdlFPoint;
    if FShields[Side].TryEntry(From, Till, Entry) then
    begin
      FShields[Side].Strike(Entry);
      AAt.X := Heart.X + Entry.X;
      AAt.Y := Heart.Y + Entry.Y;
      Exit(cbShield);
    end;
  end;

  var Point: TSdlFRect;
  Point.X := ATo.X;
  Point.Y := ATo.Y;
  Point.W := 0.01;
  Point.H := 0.01;
  var Side: TCannonSide;
  if HullMeets(Point, Side) then
    Exit(cbHull);
  Result := cbNone;
end;

function TCannonPair.Touches(const ABody: TSdlFRect;
  out ASide: TCannonSide): Boolean;
begin
  ASide := csLeft;
  if FLeaving then
    Exit(False);
  Result := HullMeets(ABody, ASide);
end;

function TCannonPair.HullMeets(const ABox: TSdlFRect;
  out ASide: TCannonSide): Boolean;
begin
  ASide := csLeft;
  if (FPhase = cpGone) or (ABox.W <= 0) then
    Exit(False);
  for var Side := Low(TCannonSide) to High(TCannonSide) do
    for var Box in ContactBoxes do
    begin
      var Corner := ArtPoint(Side, Box.X, Box.Y, FTop, FSlide);
      var Placed := Box;
      Placed.X := Corner.X;
      if Side = csRight then
        Placed.X := Corner.X - Box.W;
      Placed.Y := Corner.Y;
      if BoxesMeet(Placed, ABox) then
      begin
        ASide := Side;
        Exit(True);
      end;
    end;
  Result := False;
end;

// ---------------------------------------------------------------------------
// The picture
// ---------------------------------------------------------------------------

procedure TCannonPair.DrawCannon(const ASprites: TSpriteRenderer;
  ASide: TCannonSide; ATop, ASlide, AHeat: Single);
begin
  var Heart := Middle(ASide, ATop, ASlide);
  var Mirrored := ASide = csRight;
  ASprites.DrawSized(FArt.FHull, Heart, CannonWidth, CannonHeight, 1,
    Mirrored);
  if AHeat > 0 then
    ASprites.DrawSized(FArt.FHeat, Heart, CannonWidth, CannonHeight, AHeat,
      Mirrored);
end;

procedure TCannonPair.DrawBodies(const ASprites: TSpriteRenderer;
  AAlpha: Single);
begin
  if FPhase = cpGone then
    Exit;
  var Top := Lerp(FLastTop, FTop, AAlpha);
  var Slide := Lerp(FLastSlide, FSlide, AAlpha);
  var Heat := Lerp(FLastHeat, FHeat, AAlpha);
  for var Side := Low(TCannonSide) to High(TCannonSide) do
    DrawCannon(ASprites, Side, Top, Slide, Heat);
end;

// A streak of light, its hot end ahead
procedure DrawStreak(const ACanvas: TDynamicCanvas; AHeadX, AY: Single;
  AHeadingRight: Boolean);
begin
  var Dest: TSdlFRect;
  Dest.W := RoundLength;
  Dest.H := RoundThickness;
  Dest.Y := AY - RoundThickness / 2;
  var Flip: Integer := SdlFlipNone;
  if AHeadingRight then
    Dest.X := AHeadX - RoundLength
  else
  begin
    Dest.X := AHeadX;
    Flip := SdlFlipHorizontal;
  end;
  SDL_SetTextureColorMod(ACanvas.StreakGlow, RoundColor.R, RoundColor.G,
    RoundColor.B);
  SDL_SetTextureAlphaMod(ACanvas.StreakGlow, 255);
  SDL_RenderCopyExF(ACanvas.Renderer, ACanvas.StreakGlow, nil, @Dest, 0.0, nil,
    Flip);
end;

procedure TCannonPair.DrawRounds(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Flying in FRounds do
  begin
    var HeadX := Lerp(Flying.LastX, Flying.X, AAlpha) + AOrigin.X;
    DrawStreak(ACanvas, HeadX, Flying.Y + AOrigin.Y, Flying.From = csLeft);
  end;
end;

// The red fire before a volley, the flash of a shot, the lens
procedure TCannonPair.DrawMuzzles(const ACanvas: TDynamicCanvas;
  ASide: TCannonSide; ATop, ASlide: Single; AOrigin: TSdlPoint;
  AAlpha: Single);
const
  FireSize = 14.0;
  FlashSize = 22.0;
  LensSize = 7.0;
begin
  var Warm := Lerp(FLastWarm, FWarm, AAlpha);
  var Flash := Lerp(FLastFlash, FFlash, AAlpha);
  for var Barrel := 0 to High(MuzzleY) do
  begin
    var Tip := ArtPoint(ASide, MuzzleX, MuzzleY[Barrel], ATop, ASlide);
    var TipX: Single := Tip.X + AOrigin.X;
    var TipY: Single := Tip.Y + AOrigin.Y;
    if Warm > 0 then
      DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, TipX, TipY,
        FireSize * (0.5 + 0.5 * Warm), FireColor, Warm);
    if Flash > 0.05 then
      DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, TipX, TipY,
        FlashSize * Flash, FlashColor, Flash);
  end;

  var Lens := ArtPoint(ASide, LensX, LensY, ATop, ASlide);
  var LensLevel := Max(LensRestLevel, Warm);
  if FLeaving then
    LensLevel := 1;
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, Lens.X + AOrigin.X,
    Lens.Y + AOrigin.Y, LensSize * (0.6 + 0.4 * LensLevel), FireColor,
    LensLevel);
end;

procedure TCannonPair.DrawLight(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  if FPhase = cpGone then
    Exit;
  var Top := Lerp(FLastTop, FTop, AAlpha);
  var Slide := Lerp(FLastSlide, FSlide, AAlpha);
  DrawRounds(ACanvas, AOrigin, AAlpha);
  for var Side := Low(TCannonSide) to High(TCannonSide) do
  begin
    DrawMuzzles(ACanvas, Side, Top, Slide, AOrigin, AAlpha);
    var Heart := Middle(Side, Top, Slide);
    Heart.X := Heart.X + AOrigin.X;
    Heart.Y := Heart.Y + AOrigin.Y;
    FShields[Side].Draw(ACanvas, FArt.FShield, Heart, AAlpha);
  end;
end;

end.
