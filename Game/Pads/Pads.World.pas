{
  Pads.World - the level's pads (Levels.Pads) in play: where each one
  stands, what its deck carries, what its body stops, and its picture.

  The world keeps no riders. The hero and the monsters ask it for the
  deck under their feet, for the deck that stood under them a tick ago
  and carries them along, and for the deck their feet came down onto in
  a tick; the grid of 2008 goes on answering everything else. On a
  screen without pads every answer is nil or False, so the old rules
  stand alone there.

  A pad travels its path in the open, eased in and out of every stop.
  Only the pads of the hero's screen go on: a screen left behind holds
  still with whatever lies on its pads, as its monsters do. The bob and
  the sag under a landing are the pad's Lift - drawn, not felt: a pad
  standing still keeps its deck on the line the level file puts it on,
  where the 2008 wall probes, which count rows from the feet, read the
  right row. A path that climbs takes its riders between the rows: keep
  it clear of the grid's walls. The Lift is drawn in fractions of a unit,
  the bob between ticks too - a sway of a unit and a half in whole units
  would jerk from one to the next. The sag stays on the tick, where the
  lamps hung on the pad read it. The riders are drawn with the Lift of
  their deck.

  A blow - the boss's ram - knocks a pad off its place: a cell along the
  blow, or as far as the walls, the other pads and the caller's fence -
  the boss's lap - let it. Out in a few ticks, rocking, held while the
  boss lies stunned, home by the time he flies again. The riders go with
  it as with a path, and the room over the deck is kept clear of walls
  for them. A pad on a path only rocks, and so does every pad of a screen
  whose group is being rebuilt.

  A rebuild flies the pads of a group to a new formation inside its zone
  (Pads.Formations throws and judges it, Pads.Flights plans the flights).
  It is asked for and starts on the group's screen once no pad of the
  group is knocked; the pads the caller says are loaded stay in front,
  and every pad sets off no sooner than the caller lets it. A
  pad flown into the depth behind the others is neither a floor nor a
  body until it comes out on its cell: what stands on it falls. A flying
  pad does not bob; it takes up the bob again on its cell, in step with
  the ripple where it lands. Until the last pad lands, asking again does
  nothing.

  The world is born with the level; a restart rewinds it, the dice of the
  rebuilds new for the new try.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.World;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections,
  Sdl2.Core, Render.Sprites, Render.Brush, Levels.Pads, Levels.Defs,
  Pads.Formations, Pads.Flights;

type
  // The point is shut to a knocked pad, besides the walls
  TPadFence = reference to function(AX, AY: Single): Boolean;

  // A body that struck: its corners a step on, where the walls stopped
  // it - a pad holding one is struck; the way it went, a unit vector; the
  // ticks the struck pad stays out
  TPadBlow = record
    Left, Top, Right, Bottom: Single;
    WayX, WayY: Single;
    Ticks: Integer;
  end;

  TPad = class
  private
    FPlacement: TPadPlacement;
    FTexture: PSdlTexture;
    FPictureHeight: Integer;
    // The path as one cycle: from every stop to the next, the last back
    // to the first
    FStops: TArray<TPadStop>;
    FLegTicks: TArray<Integer>;
    FPauseTicks: Integer;
    FCycleTicks: Integer;
    FClock: Integer; // ticks this pad has lived on the hero's screen
    FPathLeft, FPathTop: Double; // where the path puts the pad
    // The knock: off the path by From at the blow - a pad struck again
    // before it is home - and by To at its farthest; the ticks since the
    // blow, NoKnock when there is none
    FKnockFromX, FKnockFromY: Double;
    FKnockToX, FKnockToY: Double;
    FKnockClock: Integer;
    FKnockTicks: Integer;
    FLeft, FTop: Double;
    FPrevLeft, FPrevTop: Double;
    FSag, FSagSpeed: Double; // units down, units a tick
    // The rebuild's flight, and its ticks since the start; NoFlight when
    // the pad is not in one
    FFlight: TPadFlight;
    FFlightClock: Integer;
    // The bob: the place across its ripple counts from, and how much of
    // it a flight has left - 0 in the air, 1 on the cell
    FBobX: Double;
    FBobShare: Double;
    procedure BuildCycle;
    procedure PlaceOnPath;
    procedure TickFlight;
    procedure TickBob;
    procedure TickSag;
    procedure TickKnock;
    procedure KnockOffset(out AX, AY: Double);
    function Tilt(AAlpha: Single): Double;
    function GetRight: Double;
  public
    constructor Create(const APlacement: TPadPlacement; ATexture: PSdlTexture);
    // The deck spans some of ALeft..ARight, edges included
    function DeckSpans(ALeft, ARight: Double): Boolean;
    // The same for the deck as it stood a tick ago
    function DeckSpannedBefore(ALeft, ARight: Double): Boolean;
    // The point lies in the body: the deck's width across, a cell down
    function BodyHolds(AX, AY: Single): Boolean;
    // A step of the path; AOnView - the pad is on the hero's screen
    procedure Tick(AOnView: Boolean);
    procedure Rewind;
    // Something has landed on the deck at ASpeed units a tick: the pad
    // gives under it and springs back
    procedure Press(ASpeed: Double);
    // A blow: the pad goes ADX, ADY from where it stands and is back on
    // its path ATicks later
    procedure Knock(ADX, ADY: Double; ATicks: Integer);
    function Travels: Boolean;
    function Knocked: Boolean;
    // The pad flies AFlight, its ticks counted from now
    procedure Fly(const AFlight: TPadFlight);
    function Flying: Boolean;
    // In the depth behind the others: neither a floor nor a body
    function Behind: Boolean;
    // 0 in front .. 1 all the way into the depth, eased; AAlpha as Lift's
    function Depth(AAlpha: Single): Double;
    // The body moved ADX, ADY from where it stands now would not cut into
    // AOther's; touching is no cut
    function ClearOf(const AOther: TPad; ADX, ADY: Double): Boolean;
    // Units down from the deck the pad is drawn at: the sag of this tick
    // and the bob AAlpha of the way from the last tick to this one
    function Lift(AAlpha: Single): Double;
    // How far the pad went across this tick
    function MotionX: Double;
    procedure Draw(const ASprites: TSpriteRenderer; AAlpha: Single);

    property Screen: Integer read FPlacement.Screen;
    property Tag: string read FPlacement.Tag;
    property Bullets: TPadBullets read FPlacement.Bullets;
    property Group: string read FPlacement.Group;
    property Placement: TPadPlacement read FPlacement;
    // Where the path or the flight puts the pad, the knock left out
    property HomeLeft: Double read FPathLeft;
    property HomeTop: Double read FPathTop;
    property Left: Double read FLeft;
    property Right: Double read GetRight;
    // The deck: the feet line of whatever stands on the pad
    property Top: Double read FTop;
    property PrevTop: Double read FPrevTop;
  end;

  // The pad carries a rider the rebuild must not take into the depth
  TPadLoad = reference to function(const APad: TPad): Boolean;

  // Ticks after the start of a rebuild before which the pad on ACell
  // stays home
  TPadRelease = reference to function(const ACell: TPadCell): Integer;

  TPadLayer = (plDeep, plFront);

  TPadWorld = class
  private
    FSprites: TSpriteRenderer;
    FLevel: TLevel;
    FPads: TObjectList<TPad>;
    FReach: TJumpReach;
    FDice: TXorShift;
    // The group a rebuild is asked for, '' when none; and the one flying
    FAskedGroup: string;
    FAskedLoad: TPadLoad;
    FAskedRelease: TPadRelease;
    FFlyingGroup: string;
    function PadStruck(AScreen: Integer; const ABlow: TPadBlow): TPad;
    function RowShut(AScreen: Integer; ALeft, ARight, AY: Double;
      const AFence: TPadFence): Boolean;
    function RoomFor(const APad: TPad; ADX, ADY: Double;
      const AFence: TPadFence): Boolean;
    function GroupFlying(const ATag: string): Boolean;
    function FlyingOn(AScreen: Integer): Boolean;
    function MembersOf(const ATag: string): TArray<TPad>;
    function StillSpans(const AGroup: TPadGroup): TPadSpans;
    procedure StartAskedRebuild(AScreen: Integer);
    procedure StartRebuild(const AGroup: TPadGroup);
    function TryPlanRebuild(const AGroup: TPadGroup;
      const AMembers: TArray<TPad>; out AFlights: TPadFlights): Boolean;
    procedure DrawLayer(AScreen: Integer; AAlpha: Single; ALayer: TPadLayer);
  public
    // ACache is the level's object art; it and ALevel must outlive the
    // world. A picture the cache lacks raises here, at level load.
    // AReach - how far the hero jumps, for the judge of a formation;
    // ASeed - the dice of the rebuilds.
    constructor Create(const ASprites: TSpriteRenderer;
      const ACache: TSpriteCache; const ALevel: TLevel;
      const AReach: TJumpReach; ASeed: Cardinal);
    destructor Destroy; override;

    // Before the riders move: a rebuild asked for may start, the pads of
    // AScreen go on along their paths and flights
    procedure Tick(AScreen: Integer);
    // Back to where the level file puts them, no rebuild asked for or
    // flying; ASeed - the dice of the new try
    procedure Rewind(ASeed: Cardinal);
    // The pads of the group tagged AGroup fly to a new formation, on its
    // screen once none of them is knocked; a pad ALoad says is loaded
    // stays in front, a pad sets off no sooner than ARelease says - nil:
    // all at the start. Nothing while a rebuild is asked for or flying.
    procedure RequestRebuild(const AGroup: string; const ALoad: TPadLoad;
      const ARelease: TPadRelease);
    // A rebuild is asked for or flying
    function Rebuilding: Boolean;
    // A pad of the group tagged AGroup is knocked off its place
    function GroupKnocked(const AGroup: string): Boolean;
    // The deck the feet stand on: at AFeetY, spanning some of
    // ALeft..ARight. nil when there is none.
    function DeckUnder(AScreen: Integer; ALeft, ARight,
      AFeetY: Double): TPad;
    // The deck the feet stood on a tick ago, which carries them this tick
    function DeckCarrying(AScreen: Integer; ALeft, ARight,
      AFeetY: Double): TPad;
    // The deck the feet came down onto between two ticks: the feet were
    // not below it at APrevY and are not above it at AFeetY - for the
    // hero, a deck rising into still feet catches them too. The highest one when the
    // feet passed several. AIgnored, which may be nil, is the deck the
    // feet are dropping through: every deck at its height is let by, or a
    // drop on the seam of two pads side by side would land on the
    // neighbour.
    function DeckCrossed(AScreen: Integer; ALeft, ARight, APrevY,
      AFeetY: Double; const AIgnored: TPad): TPad;
    // A body at the point: what stops the boss, the sparks and the debris
    function BodyAt(AScreen: Integer; AX, AY: Single): Boolean;
    // A body at the point that bursts bullets
    function StopsBulletAt(AScreen: Integer; AX, AY: Single): Boolean;
    // nil when no pad carries the tag
    function FindTagged(const ATag: string): TPad;
    // The boss's body struck: the pad it struck, if one, is knocked the
    // way the body went - a cell, or as far as the walls, AFence and the
    // other pads let it; on a screen whose group is being rebuilt it only
    // rocks
    procedure Shove(AScreen: Integer; const ABlow: TPadBlow;
      const AFence: TPadFence);
    procedure Draw(AScreen: Integer; AAlpha: Single);
  end;

implementation

uses
  System.Math, Game.Space;

const
  // Seconds and units a second in JSON, ticks and units a tick in the
  // code; the logic runs 33 ticks a second (tickRate of Game.Config)
  LogicTicksPerSecond = 33;
  // The feet stand on a deck this close to it: a fraction left by
  // arithmetic must not drop a rider
  DeckSlop = 0.5;
  // One sway of the bob. Neighbours sway out of step by where they stand
  // across the screen: a row of pads ripples.
  BobPeriodTicks = 3 * LogicTicksPerSecond;
  // The sag: a landing kicks the deck down by its speed times the gain,
  // no harder than the cap; a spring brings it back with a damped bounce
  SagGain = 0.6;
  SagMaxKick = 2.7; // about three units down at the deepest
  SagStiffness = 0.18;
  SagDamping = 0.3;
  SagRest = 0.05; // closer than this, at rest
  // The knock: a cell a blow; out in KnockOutTicks, home again over
  // KnockBackTicks that end with the blow's ticks - the boss's stun: when
  // he flies again, the arena is as he left it
  NoKnock = -1;
  KnockReach = TileSize;
  KnockOutTicks = 6;
  KnockBackTicks = 12;
  // The pad rocks after the blow: the tilt in degrees at its widest, how
  // fast it dies away and one rock in ticks
  KnockTilt = 7.0;
  KnockTiltDecayTicks = 12.0;
  KnockTiltPeriodTicks = 8.0;
  // A knocked body is tried against the walls a hair inside its edges:
  // flush against a wall is not in it
  WallProbeInset = 0.01;
  // Feet on the very edge of a deck stand on it: a fraction left by
  // arithmetic - a rider carried a unit at a time - must not drop them
  EdgeSlop = 0.001;
  NoFlight = -1;
  // A flying pad stills its bob over this many ticks and takes it up
  // again over as many on its cell
  BobFadeTicks = 10;
  // A pad all the way into the depth: its size and its light
  DeepScale = 0.85;
  DeepTone = 0.6;
  // A rebuild throws this many formations at most - screen 17 needs some
  // 70 at the most, a dozen on average -, then falls back on the level
  // file's own, which the level is laid out to pass the judge
  MaxThrows = 500;

// Eased in and out: the pad sets off and comes to a stop gently
function Smoothstep(AShare: Double): Double;
begin
  Result := AShare * AShare * (3 - 2 * AShare);
end;

// ---------------------------------------------------------------------------
// TPad
// ---------------------------------------------------------------------------

constructor TPad.Create(const APlacement: TPadPlacement;
  ATexture: PSdlTexture);
var
  ArtWidth, ArtHeight: Integer;
begin
  inherited Create;
  FPlacement := APlacement;
  FTexture := ATexture;
  SDL_QueryTexture(ATexture, nil, nil, @ArtWidth, @ArtHeight);
  FPictureHeight := Round(APlacement.Width * ArtHeight / ArtWidth);
  BuildCycle;
  Rewind;
end;

// The place of the level file is the first stop. There and back passes
// every stop twice but the two ends; round goes back to the first.
procedure TPad.BuildCycle;
var
  Start: TPadStop;
begin
  if FPlacement.Path.Route = prNone then
    Exit;

  Start.X := FPlacement.X;
  Start.Y := FPlacement.Y;
  FStops := [Start] + FPlacement.Path.Stops;
  if FPlacement.Path.Route = prPingPong then
    for var i := High(FPlacement.Path.Stops) - 1 downto 0 do
      FStops := FStops + [FPlacement.Path.Stops[i]];

  FPauseTicks := Round(FPlacement.Path.Pause * LogicTicksPerSecond);
  SetLength(FLegTicks, Length(FStops));
  FCycleTicks := 0;
  for var i := 0 to High(FStops) do
  begin
    var Next := FStops[(i + 1) mod Length(FStops)];
    var Distance := Hypot(Next.X - FStops[i].X, Next.Y - FStops[i].Y);
    FLegTicks[i] := Max(1,
      Round(Distance / FPlacement.Path.Speed * LogicTicksPerSecond));
    Inc(FCycleTicks, FLegTicks[i] + FPauseTicks);
  end;
end;

procedure TPad.Rewind;
begin
  FClock := 0;
  FPathLeft := FPlacement.X;
  FPathTop := FPlacement.Y;
  FKnockFromX := 0;
  FKnockFromY := 0;
  FKnockToX := 0;
  FKnockToY := 0;
  FKnockClock := NoKnock;
  FKnockTicks := 0;
  FLeft := FPathLeft;
  FTop := FPathTop;
  FPrevLeft := FLeft;
  FPrevTop := FTop;
  FSag := 0;
  FSagSpeed := 0;
  FFlightClock := NoFlight;
  FBobX := FPlacement.X;
  FBobShare := 1;
end;

// A leg, then the pause at the stop it ends at, round the cycle
procedure TPad.PlaceOnPath;
begin
  if Length(FStops) < 2 then
    Exit;

  var Time := FClock mod FCycleTicks;
  for var i := 0 to High(FStops) do
  begin
    var From := FStops[i];
    var Next := FStops[(i + 1) mod Length(FStops)];
    if Time < FLegTicks[i] then
    begin
      var Share := Smoothstep(Time / FLegTicks[i]);
      FPathLeft := From.X + (Next.X - From.X) * Share;
      FPathTop := From.Y + (Next.Y - From.Y) * Share;
      Exit;
    end;
    Dec(Time, FLegTicks[i]);
    if Time < FPauseTicks then
    begin
      FPathLeft := Next.X;
      FPathTop := Next.Y;
      Exit;
    end;
    Dec(Time, FPauseTicks);
  end;
end;

// The bob's ripple goes with the pad: on its cell the pad sways in step
// with the ripple where it has landed
procedure TPad.TickFlight;
begin
  if not Flying then
    Exit;
  Inc(FFlightClock);
  FFlight.Place(FFlightClock, FPathLeft, FPathTop);
  FBobX := FPathLeft;
  // A tick past the end: the last tick of coming out of the depth is
  // still drawn between the ticks
  if FFlightClock > FFlight.Done then
    FFlightClock := NoFlight;
end;

procedure TPad.TickBob;
begin
  if Flying then
    FBobShare := Max(0.0, FBobShare - 1 / BobFadeTicks)
  else
    FBobShare := Min(1.0, FBobShare + 1 / BobFadeTicks);
end;

procedure TPad.TickSag;
begin
  FSagSpeed := FSagSpeed - SagStiffness * FSag - SagDamping * FSagSpeed;
  FSag := FSag + FSagSpeed;
  if (Abs(FSag) < SagRest) and (Abs(FSagSpeed) < SagRest) then
  begin
    FSag := 0;
    FSagSpeed := 0;
  end;
end;

// How far off its path the pad is: eased out, held, eased home
procedure TPad.KnockOffset(out AX, AY: Double);
begin
  AX := 0;
  AY := 0;
  if FKnockClock = NoKnock then
    Exit;
  if FKnockClock < KnockOutTicks then
  begin
    var OutShare := Smoothstep(FKnockClock / KnockOutTicks);
    AX := FKnockFromX + (FKnockToX - FKnockFromX) * OutShare;
    AY := FKnockFromY + (FKnockToY - FKnockFromY) * OutShare;
    Exit;
  end;
  var BackFrom := FKnockTicks - KnockBackTicks;
  var HeldShare: Double := 1;
  if FKnockClock >= BackFrom then
    HeldShare := 1 - Smoothstep((FKnockClock - BackFrom) / KnockBackTicks);
  AX := FKnockToX * HeldShare;
  AY := FKnockToY * HeldShare;
end;

procedure TPad.TickKnock;
begin
  if FKnockClock = NoKnock then
    Exit;
  Inc(FKnockClock);
  if FKnockClock >= FKnockTicks then
    FKnockClock := NoKnock;
end;

procedure TPad.Tick(AOnView: Boolean);
begin
  FPrevLeft := FLeft;
  FPrevTop := FTop;
  if not AOnView then
    Exit;
  Inc(FClock);
  PlaceOnPath;
  TickFlight;
  TickBob;
  TickSag;
  TickKnock;
  var OffX, OffY: Double;
  KnockOffset(OffX, OffY);
  FLeft := FPathLeft + OffX;
  FTop := FPathTop + OffY;
end;

procedure TPad.Knock(ADX, ADY: Double; ATicks: Integer);
begin
  FKnockFromX := FLeft - FPathLeft;
  FKnockFromY := FTop - FPathTop;
  FKnockToX := FKnockFromX + ADX;
  FKnockToY := FKnockFromY + ADY;
  FKnockClock := 0;
  // Out and home, if nothing else
  FKnockTicks := Max(ATicks, KnockOutTicks + KnockBackTicks);
end;

function TPad.Travels: Boolean;
begin
  Result := Length(FStops) >= 2;
end;

function TPad.Knocked: Boolean;
begin
  Result := FKnockClock <> NoKnock;
end;

procedure TPad.Fly(const AFlight: TPadFlight);
begin
  FFlight := AFlight;
  FFlightClock := 0;
end;

function TPad.Flying: Boolean;
begin
  Result := FFlightClock <> NoFlight;
end;

function TPad.Behind: Boolean;
begin
  Result := Flying and FFlight.Behind(FFlightClock);
end;

function TPad.Depth(AAlpha: Single): Double;
begin
  Result := 0;
  if Flying then
    Result := Smoothstep(FFlight.Depth(FFlightClock - 1 + AAlpha));
end;

// A damped rock from the blow on, drawn only
function TPad.Tilt(AAlpha: Single): Double;
begin
  if FKnockClock = NoKnock then
    Exit(0);
  var Time := FKnockClock - 1 + AAlpha;
  if Time < 0 then
    Exit(0);
  Result := KnockTilt * Exp(-Time / KnockTiltDecayTicks) *
    Sin(2 * Pi * Time / KnockTiltPeriodTicks);
end;

function TPad.ClearOf(const AOther: TPad; ADX, ADY: Double): Boolean;
begin
  var MovedLeft := FLeft + ADX;
  var MovedTop := FTop + ADY;
  Result := (MovedLeft + FPlacement.Width <= AOther.Left) or
    (AOther.Right <= MovedLeft) or (MovedTop + TileSize <= AOther.Top) or
    (AOther.Top + TileSize <= MovedTop);
end;

procedure TPad.Press(ASpeed: Double);
begin
  FSagSpeed := FSagSpeed + Min(ASpeed * SagGain, SagMaxKick);
end;

function TPad.Lift(AAlpha: Single): Double;
begin
  Result := FSag;
  if FPlacement.Bob <= 0 then
    Exit;
  var Time := FClock - 1 + AAlpha;
  var Phase := Time / BobPeriodTicks + FBobX / ScreenWidth;
  var Sway := FPlacement.Bob * Smoothstep(FBobShare);
  Result := Result + Sway * Sin(2 * Pi * Phase);
end;

function TPad.GetRight: Double;
begin
  Result := FLeft + FPlacement.Width;
end;

function TPad.MotionX: Double;
begin
  Result := FLeft - FPrevLeft;
end;

function TPad.DeckSpans(ALeft, ARight: Double): Boolean;
begin
  Result := (ALeft <= Right + EdgeSlop) and (ARight >= FLeft - EdgeSlop);
end;

function TPad.DeckSpannedBefore(ALeft, ARight: Double): Boolean;
begin
  Result := (ALeft <= FPrevLeft + FPlacement.Width + EdgeSlop) and
    (ARight >= FPrevLeft - EdgeSlop);
end;

function TPad.BodyHolds(AX, AY: Single): Boolean;
begin
  Result := (AX >= FLeft) and (AX < Right) and (AY >= FTop) and
    (AY < FTop + TileSize);
end;

// In the depth smaller about its middle, and darker
procedure TPad.Draw(const ASprites: TSpriteRenderer; AAlpha: Single);
var
  Dest: TSdlFRect;
begin
  var Sunk := Depth(AAlpha);
  var Scale := 1 - (1 - DeepScale) * Sunk;
  var Tone := 1 - (1 - DeepTone) * Sunk;
  Dest.W := FPlacement.Width * Scale;
  Dest.H := FPictureHeight * Scale;
  Dest.X := Round(FLeft) + (FPlacement.Width - Dest.W) / 2;
  // As the riders are drawn, so the feet do not flicker into the deck
  Dest.Y := Round(FTop) + Lift(AAlpha) + (FPictureHeight - Dest.H) / 2;
  TintTexture(FTexture, Round(FPlacement.Tint.R * Tone),
    Round(FPlacement.Tint.G * Tone), Round(FPlacement.Tint.B * Tone));
  ASprites.DrawRectF(FTexture, Dest, Tilt(AAlpha));
end;

// ---------------------------------------------------------------------------
// TPadWorld
// ---------------------------------------------------------------------------

constructor TPadWorld.Create(const ASprites: TSpriteRenderer;
  const ACache: TSpriteCache; const ALevel: TLevel;
  const AReach: TJumpReach; ASeed: Cardinal);
begin
  inherited Create;
  FSprites := ASprites;
  FLevel := ALevel;
  FReach := AReach;
  FPads := TObjectList<TPad>.Create(True);
  for var Placement in ALevel.Pads do
    FPads.Add(TPad.Create(Placement, ACache.Get(Placement.Sprite)));
  Rewind(ASeed);
end;

destructor TPadWorld.Destroy;
begin
  FPads.Free;
  inherited;
end;

procedure TPadWorld.Tick(AScreen: Integer);
begin
  StartAskedRebuild(AScreen);
  for var Pad in FPads do
    Pad.Tick(Pad.Screen = AScreen);
  if not GroupFlying(FFlyingGroup) then
    FFlyingGroup := '';
end;

procedure TPadWorld.Rewind(ASeed: Cardinal);
begin
  for var Pad in FPads do
    Pad.Rewind;
  FAskedGroup := '';
  FAskedLoad := nil;
  FAskedRelease := nil;
  FFlyingGroup := '';
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;
end;

function TPadWorld.DeckUnder(AScreen: Integer; ALeft, ARight,
  AFeetY: Double): TPad;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and not Pad.Behind and
      (Abs(Pad.Top - AFeetY) < DeckSlop) and Pad.DeckSpans(ALeft, ARight) then
      Exit(Pad);
  Result := nil;
end;

function TPadWorld.DeckCarrying(AScreen: Integer; ALeft, ARight,
  AFeetY: Double): TPad;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and not Pad.Behind and
      (Abs(Pad.PrevTop - AFeetY) < DeckSlop) and
      Pad.DeckSpannedBefore(ALeft, ARight) then
      Exit(Pad);
  Result := nil;
end;

function TPadWorld.DeckCrossed(AScreen: Integer; ALeft, ARight, APrevY,
  AFeetY: Double; const AIgnored: TPad): TPad;
begin
  Result := nil;
  for var Pad in FPads do
  begin
    var DroppedThrough := (AIgnored <> nil) and
      (Abs(Pad.Top - AIgnored.Top) < DeckSlop);
    if DroppedThrough or (Pad.Screen <> AScreen) or Pad.Behind then
      Continue;
    var Crossed := (APrevY <= Pad.PrevTop) and (AFeetY >= Pad.Top);
    if not Crossed or not Pad.DeckSpans(ALeft, ARight) then
      Continue;
    if (Result = nil) or (Pad.Top < Result.Top) then
      Result := Pad;
  end;
end;

function TPadWorld.BodyAt(AScreen: Integer; AX, AY: Single): Boolean;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and not Pad.Behind and Pad.BodyHolds(AX, AY) then
      Exit(True);
  Result := False;
end;

function TPadWorld.StopsBulletAt(AScreen: Integer; AX, AY: Single): Boolean;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and (Pad.Bullets = pbBlock) and
      not Pad.Behind and Pad.BodyHolds(AX, AY) then
      Exit(True);
  Result := False;
end;

// A pad holding a corner of the body a step on: what the pilot's walls
// found there
function TPadWorld.PadStruck(AScreen: Integer; const ABlow: TPadBlow): TPad;
begin
  for var Pad in FPads do
  begin
    if (Pad.Screen <> AScreen) or Pad.Behind then
      Continue;
    var Struck := Pad.BodyHolds(ABlow.Left, ABlow.Top) or
      Pad.BodyHolds(ABlow.Right, ABlow.Top) or
      Pad.BodyHolds(ABlow.Left, ABlow.Bottom) or
      Pad.BodyHolds(ABlow.Right, ABlow.Bottom);
    if Struck then
      Exit(Pad);
  end;
  Result := nil;
end;

// Points a cell apart from ALeft to ARight at AY meet a wall, or the
// fence if one is given: every cell the row crosses is asked
function TPadWorld.RowShut(AScreen: Integer; ALeft, ARight, AY: Double;
  const AFence: TPadFence): Boolean;
begin
  for var i := 0 to Ceil((ARight - ALeft) / TileSize) do
  begin
    var X := Min(ALeft + i * TileSize, ARight);
    if FLevel.SolidAtPoint(AScreen, X, AY) then
      Exit(True);
    if Assigned(AFence) and AFence(X, AY) then
      Exit(True);
  end;
  Result := False;
end;

// The body moved ADX, ADY stays on the screen, out of the grid's walls
// and the fence, clear of every other pad of its screen; the room of its
// riders, a cell over the deck, stays out of the walls
function TPadWorld.RoomFor(const APad: TPad; ADX, ADY: Double;
  const AFence: TPadFence): Boolean;
begin
  var Left := APad.Left + ADX;
  var Right := APad.Right + ADX;
  var Deck := APad.Top + ADY;
  var OnScreen := (Left >= 0) and (Right <= ScreenWidth) and (Deck >= 0) and
    (Deck + TileSize <= ScreenHeight);
  if not OnScreen then
    Exit(False);

  // A cell deep each, the riders' room and the body are asked by their top
  // and bottom rows. The riders' room minds no fence: the lap is the
  // boss's, and he lies stunned while the pad is out.
  Left := Left + WallProbeInset;
  Right := Right - WallProbeInset;
  var Shut := RowShut(APad.Screen, Left, Right,
    Deck - TileSize + WallProbeInset, nil) or
    RowShut(APad.Screen, Left, Right, Deck - WallProbeInset, nil) or
    RowShut(APad.Screen, Left, Right, Deck + WallProbeInset, AFence) or
    RowShut(APad.Screen, Left, Right, Deck + TileSize - WallProbeInset, AFence);
  if Shut then
    Exit(False);

  for var Other in FPads do
    if (Other <> APad) and (Other.Screen = APad.Screen) and
      not Other.Behind and not APad.ClearOf(Other, ADX, ADY) then
      Exit(False);
  Result := True;
end;

// Unit by unit along the blow, a cell's worth at most, sliding along what
// stops one way of it. A pad with no room at all still rocks, and so does
// one on a path: its room is looked for where it stands, and the path
// would take it on from there. So does a pad of the group being rebuilt:
// knocked off its cell, it would cut into a pad landing next to it - and
// so does any other pad of that screen, which a flight was planned past.
procedure TPadWorld.Shove(AScreen: Integer; const ABlow: TPadBlow;
  const AFence: TPadFence);
begin
  var Pad := PadStruck(AScreen, ABlow);
  if Pad = nil then
    Exit;
  if Pad.Travels or FlyingOn(Pad.Screen) then
  begin
    Pad.Knock(0, 0, ABlow.Ticks);
    Exit;
  end;

  var WayX := ABlow.WayX;
  var WayY := ABlow.WayY;
  var KnockX: Double := 0;
  var KnockY: Double := 0;
  for var i := 1 to KnockReach do
    if RoomFor(Pad, KnockX + WayX, KnockY + WayY, AFence) then
    begin
      KnockX := KnockX + WayX;
      KnockY := KnockY + WayY;
    end
    else if RoomFor(Pad, KnockX + WayX, KnockY, AFence) then
      KnockX := KnockX + WayX
    else if RoomFor(Pad, KnockX, KnockY + WayY, AFence) then
      KnockY := KnockY + WayY
    else
      Break;
  Pad.Knock(KnockX, KnockY, ABlow.Ticks);
end;

function TPadWorld.FindTagged(const ATag: string): TPad;
begin
  for var Pad in FPads do
    if Pad.Tag = ATag then
      Exit(Pad);
  Result := nil;
end;

// ---------------------------------------------------------------------------
// The rebuild
// ---------------------------------------------------------------------------

function TPadWorld.Rebuilding: Boolean;
begin
  Result := (FAskedGroup <> '') or (FFlyingGroup <> '');
end;

function TPadWorld.GroupFlying(const ATag: string): Boolean;
begin
  for var Pad in MembersOf(ATag) do
    if Pad.Flying then
      Exit(True);
  Result := False;
end;

function TPadWorld.GroupKnocked(const AGroup: string): Boolean;
begin
  for var Pad in MembersOf(AGroup) do
    if Pad.Knocked then
      Exit(True);
  Result := False;
end;

// A group of the screen is being rebuilt
function TPadWorld.FlyingOn(AScreen: Integer): Boolean;
begin
  for var Pad in MembersOf(FFlyingGroup) do
    if Pad.Screen = AScreen then
      Exit(True);
  Result := False;
end;

// In file order; none for ''
function TPadWorld.MembersOf(const ATag: string): TArray<TPad>;
begin
  Result := [];
  if ATag = '' then
    Exit;
  for var Pad in FPads do
    if Pad.Group = ATag then
      Result := Result + [Pad];
end;

procedure TPadWorld.RequestRebuild(const AGroup: string;
  const ALoad: TPadLoad; const ARelease: TPadRelease);
begin
  if Rebuilding or (Length(MembersOf(AGroup)) = 0) then
    Exit;
  FAskedGroup := AGroup;
  FAskedLoad := ALoad;
  FAskedRelease := ARelease;
end;

// On the group's screen, once no pad of it is knocked - a knock is over
// with the boss's stun, before he flies the lap again
procedure TPadWorld.StartAskedRebuild(AScreen: Integer);
begin
  if FAskedGroup = '' then
    Exit;
  for var Pad in MembersOf(FAskedGroup) do
    if (Pad.Screen <> AScreen) or Pad.Knocked then
      Exit;
  for var Group in FLevel.PadGroups do
    if Group.Tag = FAskedGroup then
      StartRebuild(Group);
  FAskedGroup := '';
  FAskedLoad := nil;
  FAskedRelease := nil;
end;

procedure TPadWorld.StartRebuild(const AGroup: TPadGroup);
var
  Flights: TPadFlights;
begin
  var Members := MembersOf(AGroup.Tag);
  if not TryPlanRebuild(AGroup, Members, Flights) then
    Exit;
  for var i := 0 to High(Members) do
    Members[i].Fly(Flights[i]);
  FFlyingGroup := AGroup.Tag;
end;

// The screen's pads outside the group, as ground to jump from
function TPadWorld.StillSpans(const AGroup: TPadGroup): TPadSpans;
begin
  Result := [];
  for var Pad in FPads do
  begin
    if (Pad.Screen <> AGroup.Screen) or (Pad.Group = AGroup.Tag) then
      Continue;
    var Span: TPadSpan;
    Span.Left := Pad.Placement.X div TileSize;
    Span.Right := (Pad.Placement.X + Pad.Placement.Width - 1) div TileSize;
    Span.Row := Pad.Placement.Y div TileSize;
    Result := Result + [Span];
  end;
end;

function CellOfPlace(AX, AY: Double): TPadCell;
begin
  Result.Col := Round(AX / TileSize);
  Result.Row := Round(AY / TileSize);
end;

// Formations thrown until one is judged, assigned and flown; past the
// last throw the level file's formation, with the same rules for the
// assignment and the flights. False - no rebuild this time.
function TPadWorld.TryPlanRebuild(const AGroup: TPadGroup;
  const AMembers: TArray<TPad>; out AFlights: TPadFlights): Boolean;
var
  Start, FileCells, Cells, Target: TPadCells;
  Loaded: TArray<Boolean>;
  Release: TArray<Integer>;
begin
  SetLength(Start, Length(AMembers));
  SetLength(FileCells, Length(AMembers));
  SetLength(Loaded, Length(AMembers));
  // Zeros when nobody holds the pads back: all free at the start
  SetLength(Release, Length(AMembers));
  for var i := 0 to High(AMembers) do
  begin
    var Pad := AMembers[i];
    Start[i] := CellOfPlace(Pad.HomeLeft, Pad.HomeTop);
    FileCells[i] := CellOfPlace(Pad.Placement.X, Pad.Placement.Y);
    Loaded[i] := Assigned(FAskedLoad) and FAskedLoad(Pad);
    if Assigned(FAskedRelease) then
      Release[i] := FAskedRelease(Start[i]);
  end;

  var Launch := LaunchSpans(FLevel, AGroup, StillSpans(AGroup));
  for var Throw := 1 to MaxThrows do
  begin
    var Judged := TryThrowFormation(FDice, AGroup, Length(AMembers), Cells) and
      JudgeFormation(Cells, AGroup, Launch, FReach);
    var Flown := Judged and
      TryAssignFormation(FDice, Start, Cells, AGroup, Target) and
      TryPlanFlights(FDice, Start, Target, Loaded, Release, AFlights);
    if Flown then
      Exit(True);
  end;
  Result := TryAssignFormation(FDice, Start, FileCells, AGroup, Target) and
    TryPlanFlights(FDice, Start, Target, Loaded, Release, AFlights);
end;

// ---------------------------------------------------------------------------
// The picture
// ---------------------------------------------------------------------------

procedure TPadWorld.DrawLayer(AScreen: Integer; AAlpha: Single;
  ALayer: TPadLayer);
begin
  for var Pad in FPads do
  begin
    if Pad.Screen <> AScreen then
      Continue;
    var Layer := plFront;
    if Pad.Depth(AAlpha) > 0 then
      Layer := plDeep;
    if Layer = ALayer then
      Pad.Draw(FSprites, AAlpha);
  end;
end;

// The pads in the depth first: the others pass in front of them
procedure TPadWorld.Draw(AScreen: Integer; AAlpha: Single);
begin
  DrawLayer(AScreen, AAlpha, plDeep);
  DrawLayer(AScreen, AAlpha, plFront);
end;

end.
