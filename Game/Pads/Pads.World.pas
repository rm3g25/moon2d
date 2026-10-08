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
  and every pad sets off no sooner than the caller lets it. A pad of the
  group the level file puts outside the zone flies in with the first
  rebuild. Out there a flight minds more than the pads: the walls, the
  ground it would skim, and what the caller says flies there. A
  pad flown into the depth behind the others is neither a floor nor a
  body until it comes out on its cell: what stands on it falls. A flying
  pad does not bob; it takes up the bob again on its cell, in step with
  the ripple where it lands. In the depth a pad is smaller and darker,
  and so is what hangs on it: the game passes DeepScale, DeepTone and
  the pad's Middle on to the dynamic objects, and draws the two layers
  of pads apart, each with its own rig. Until the last pad lands, asking
  again does nothing. What a rebuild sounds like the world only tells -
  a corner turned, a pair docked, a tick each - and the game voices.

  A restore is a rebuild flown the other way: every pad of the group
  back to the place the level file gives it, at the calm pace of
  Pads.Flights. Nothing is thrown or judged; a pad on its place already
  stays there, and the rest fly round it.

  A pad that plunges (Pads.Plunge counts its cycle) is told when the
  hero stands on it - the one thing a rider tells a pad. It falls under
  him as a path would take it: the deck goes, the rider with it, out of
  the screen and past the line where the game takes a faller out of the
  pit. No wall stops it - the level keeps the shaft under it clear. It
  climbs back as a floor, and carries up whoever lands on it. Its twitch
  is drawn with the sag, not felt.

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
  Pads.Formations, Pads.Flights, Pads.Plunge;

const
  // A pad all the way into the depth: its size and its light
  DeepScale = 0.85;
  DeepTone = 0.6;

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
    FTurnedCorner: Boolean;
    FLanded: Boolean;
    FPlunge: TPlungeCycle;
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
    // The body as a box, in screen units
    function Body: TSdlFRect;
    // A step of the path; AOnView - the pad is on the hero's screen
    procedure Tick(AOnView: Boolean);
    procedure Rewind;
    // Something has landed on the deck at ASpeed units a tick: the pad
    // gives under it and springs back
    procedure Press(ASpeed: Double);
    // The hero stands on the deck this tick: a pad that plunges starts
    // to give way
    procedure Tread;
    // A blow: the pad goes ADX, ADY from where it stands and is back on
    // its path ATicks later
    procedure Knock(ADX, ADY: Double; ATicks: Integer);
    function Travels: Boolean;
    function Knocked: Boolean;
    // The pad flies AFlight, its ticks counted from now
    procedure Fly(const AFlight: TPadFlight);
    function Flying: Boolean;
    // In no flight, or its flight is over
    function Settled: Boolean;
    // The pad works its jets hard: from a moment before it leaves its
    // place in a flight until it is on its cell. The moment before is
    // the tell of the pad about to go.
    function Thrusting: Boolean;
    // How hard the pad works its jets, 0..1: flat out while Thrusting; a
    // pad that plunges, as its cycle says; else at rest
    function Effort: Single;
    // The two stand flush side by side where their paths or flights put
    // them
    function FlushWith(const AOther: TPad): Boolean;
    // In the depth behind the others: neither a floor nor a body
    function Behind: Boolean;
    // 0 in front .. 1 all the way into the depth, eased; AAlpha as Lift's
    function Depth(AAlpha: Single): Double;
    // The middle of the picture, from its top-left corner: the point the
    // pad shrinks about in the depth
    function Middle: TSdlFPoint;
    // The body moved ADX, ADY from where it stands now would not cut into
    // AOther's; touching is no cut
    function ClearOf(const AOther: TPad; ADX, ADY: Double): Boolean;
    // Units down from the deck the pad is drawn at: the sag and the
    // twitch of this tick and the bob AAlpha of the way from the last
    // tick to this one
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
    // One tick only: a flight in front came onto its corner; a flight
    // ended on its cell
    property TurnedCorner: Boolean read FTurnedCorner;
    property Landed: Boolean read FLanded;
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

  // Something of the caller's would cut into a pad's body, its top-left
  // corner at AX, AY, at the tick of a rebuild
  TPadTraffic = reference to function(ATick: Integer; AX, AY: Double): Boolean;

  // A rebuild as it is asked for, until it starts
  TRebuildAsk = record
    Group: string; // '' when none is asked for
    Load: TPadLoad;
    Release: TPadRelease;
    Traffic: TPadTraffic;
    // Back to the level file's places, not to a new formation
    Restore: Boolean;
  end;

  // The pads gone into the depth, at whatever depth, and the rest
  TPadLayer = (plDeep, plFront);

  TPadWorld = class
  private
    FSprites: TSpriteRenderer;
    FLevel: TLevel;
    FPads: TObjectList<TPad>;
    FReach: TJumpReach;
    FDice: TXorShift;
    FAsked: TRebuildAsk;
    FFlyingGroup: string; // the group being rebuilt, '' when none
    FCornerTurned: Boolean;
    FPairDocked: Boolean;
    function PadStruck(AScreen: Integer; const ABlow: TPadBlow): TPad;
    function RowShut(AScreen: Integer; ALeft, ARight, AY: Double;
      const AFence: TPadFence): Boolean;
    function RoomFor(const APad: TPad; ADX, ADY: Double;
      const AFence: TPadFence): Boolean;
    function GroundShut(AScreen: Integer; AX, AY: Double): Boolean;
    function FlightBarOf(const AGroup: TPadGroup): TFlightBar;
    procedure TakeAsk(const AAsk: TRebuildAsk);
    function BriefOf(const AGroup: TPadGroup;
      const AMembers: TArray<TPad>): TFlightBrief;
    function TryPlanRestore(const AGroup: TPadGroup;
      const AMembers: TArray<TPad>; out AFlights: TPadFlights): Boolean;
    function GroupFlying(const ATag: string): Boolean;
    function FlyingOn(AScreen: Integer): Boolean;
    function MembersOf(const ATag: string): TArray<TPad>;
    function StillSpans(const AGroup: TPadGroup): TPadSpans;
    procedure HearFlights;
    function DocksBeside(const APad: TPad): Boolean;
    procedure StartAskedRebuild(AScreen: Integer);
    procedure StartRebuild(const AGroup: TPadGroup);
    function TryPlanRebuild(const AGroup: TPadGroup;
      const AMembers: TArray<TPad>; out AFlights: TPadFlights): Boolean;
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
    // all at the start; out of the zone a pad in front keeps clear of
    // ATraffic - nil: of the walls alone. Nothing while a rebuild is asked
    // for or flying.
    procedure RequestRebuild(const AGroup: string; const ALoad: TPadLoad;
      const ARelease: TPadRelease; const ATraffic: TPadTraffic);
    // The pads of the group tagged AGroup fly back to where the level
    // file puts them, each to its own place, calmly; asked for and
    // started as a rebuild is, ALoad and ARelease as a rebuild's. A plan
    // that finds a pad no way flies nothing: ask again.
    procedure RequestRestore(const AGroup: string; const ALoad: TPadLoad;
      const ARelease: TPadRelease);
    // A rebuild or a restore is asked for or flying
    function Rebuilding: Boolean;
    // Every pad of the group tagged AGroup stands where the level file
    // puts it
    function GroupRestored(const AGroup: string): Boolean;
    // A pad of the group tagged AGroup is knocked off its place
    function GroupKnocked(const AGroup: string): Boolean;
    // One tick only, for the game to voice: a pad in front turned the
    // corner of its flight; a pad landed flush beside one on its cell
    property CornerTurned: Boolean read FCornerTurned;
    property PairDocked: Boolean read FPairDocked;
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
    // The bodies of the screen's pads standing in front: the matter of
    // the pads. A pad in the depth is none.
    function Bodies(AScreen: Integer): TArray<TSdlFRect>;
    // nil when no pad carries the tag
    function FindTagged(const ATag: string): TPad;
    // The boss's body struck: the pad it struck, if one, is knocked the
    // way the body went - a cell, or as far as the walls, AFence and the
    // other pads let it; on a screen whose group is being rebuilt it only
    // rocks
    procedure Shove(AScreen: Integer; const ABlow: TPadBlow;
      const AFence: TPadFence);
    // The pads of one layer. The game draws the deep ones first, then
    // what hangs on them, then the ones in front, which pass before both.
    procedure Draw(AScreen: Integer; AAlpha: Single; ALayer: TPadLayer);
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
  // A pad's jets flare this many ticks before it leaves its place
  ThrustLeadTicks = 10;
  // A plunged pad comes to rest this far under the screen: past the line
  // where the game takes a faller out of the pit, 66 units under it, so a
  // hero riding the pad down is in the pit before it stops
  PlungeDepth = 3 * TileSize;
  // A rebuild throws this many formations at most - screen 17 needs some
  // two hundred at the most, a score on average -, then falls back on the
  // level file's own, if that lies in the zone
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

// The dice of a plunging pad go by where it stands: two of them twitch
// out of step
function PlungeSeed(const APlacement: TPadPlacement): Cardinal;
begin
  Result := (Cardinal(APlacement.X) shl 16) xor
    (Cardinal(APlacement.Screen) shl 8) xor Cardinal(APlacement.Y);
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
  FTurnedCorner := False;
  FLanded := False;
  FBobX := FPlacement.X;
  FBobShare := 1;
  FPlunge.Rewind(FPlacement.Plunge,
    ScreenHeight + PlungeDepth - FPlacement.Y, PlungeSeed(FPlacement));
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
  // In the depth a corner is turned out of earshot
  FTurnedCorner := not FFlight.Deep and FFlight.TurnsCorner(FFlightClock);
  FLanded := FFlightClock = FFlight.Done;
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
  FTurnedCorner := False;
  FLanded := False;
  if not AOnView then
    Exit;
  Inc(FClock);
  PlaceOnPath;
  TickFlight;
  TickBob;
  TickSag;
  TickKnock;
  FPlunge.Tick;
  var OffX, OffY: Double;
  KnockOffset(OffX, OffY);
  FLeft := FPathLeft + OffX;
  FTop := FPathTop + OffY + FPlunge.Below;
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

function TPad.Thrusting: Boolean;
begin
  Result := Flying and (FFlightClock >= FFlight.Depart - ThrustLeadTicks) and
    (FFlightClock <= FFlight.Arrive);
end;

function TPad.Effort: Single;
begin
  if Thrusting then
    Exit(1);
  Result := FPlunge.Effort;
end;

function TPad.Settled: Boolean;
begin
  Result := not Flying or (FFlightClock >= FFlight.Done);
end;

function TPad.FlushWith(const AOther: TPad): Boolean;
begin
  var OnOneLine := Abs(FPathTop - AOther.FPathTop) < DeckSlop;
  var MeetsOnLeft :=
    Abs(AOther.FPathLeft + AOther.FPlacement.Width - FPathLeft) < DeckSlop;
  var MeetsOnRight :=
    Abs(FPathLeft + FPlacement.Width - AOther.FPathLeft) < DeckSlop;
  var Meets := MeetsOnLeft or MeetsOnRight;
  Result := OnOneLine and Meets;
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

procedure TPad.Tread;
begin
  FPlunge.Tread;
end;

function TPad.Lift(AAlpha: Single): Double;
begin
  Result := FSag + FPlunge.Dip;
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

function TPad.Body: TSdlFRect;
begin
  Result.X := FLeft;
  Result.Y := FTop;
  Result.W := FPlacement.Width;
  Result.H := TileSize;
end;

function TPad.Middle: TSdlFPoint;
begin
  Result.X := FPlacement.Width / 2;
  Result.Y := FPictureHeight / 2;
end;

// In the depth smaller about its middle, and darker
procedure TPad.Draw(const ASprites: TSpriteRenderer; AAlpha: Single);
var
  Dest: TSdlFRect;
begin
  var Sunk := Depth(AAlpha);
  var Scale := 1 - (1 - DeepScale) * Sunk;
  var Tone := 1 - (1 - DeepTone) * Sunk;
  var Pivot := Middle;
  Dest.W := FPlacement.Width * Scale;
  Dest.H := FPictureHeight * Scale;
  Dest.X := Round(FLeft) + Pivot.X * (1 - Scale);
  // As the riders are drawn, so the feet do not flicker into the deck
  Dest.Y := Round(FTop) + Lift(AAlpha) + Pivot.Y * (1 - Scale);
  TintTexture(FTexture, Round(FPlacement.Tint.R * Tone),
    Round(FPlacement.Tint.G * Tone), Round(FPlacement.Tint.B * Tone));
  ASprites.DrawRectF(FTexture, Dest, Tilt(AAlpha) + FPlunge.Lean);
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
  HearFlights;
  if not GroupFlying(FFlyingGroup) then
    FFlyingGroup := '';
end;

procedure TPadWorld.HearFlights;
begin
  FCornerTurned := False;
  FPairDocked := False;
  for var Pad in FPads do
  begin
    var Docked := Pad.Landed and DocksBeside(Pad);
    FCornerTurned := FCornerTurned or Pad.TurnedCorner;
    FPairDocked := FPairDocked or Docked;
  end;
end;

// A pad of the screen, in no flight or done with it, stands flush beside
// APad
function TPadWorld.DocksBeside(const APad: TPad): Boolean;
begin
  for var Other in FPads do
    if (Other <> APad) and (Other.Screen = APad.Screen) and Other.Settled and
      APad.FlushWith(Other) then
      Exit(True);
  Result := False;
end;

procedure TPadWorld.Rewind(ASeed: Cardinal);
begin
  for var Pad in FPads do
    Pad.Rewind;
  FAsked := Default(TRebuildAsk);
  FFlyingGroup := '';
  FCornerTurned := False;
  FPairDocked := False;
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

function TPadWorld.Bodies(AScreen: Integer): TArray<TSdlFRect>;
begin
  Result := nil;
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and not Pad.Behind then
      Result := Result + [Pad.Body];
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
  Result := (FAsked.Group <> '') or (FFlyingGroup <> '');
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

procedure TPadWorld.TakeAsk(const AAsk: TRebuildAsk);
begin
  if Rebuilding or (Length(MembersOf(AAsk.Group)) = 0) then
    Exit;
  FAsked := AAsk;
end;

procedure TPadWorld.RequestRebuild(const AGroup: string;
  const ALoad: TPadLoad; const ARelease: TPadRelease;
  const ATraffic: TPadTraffic);
var
  Ask: TRebuildAsk;
begin
  Ask := Default(TRebuildAsk);
  Ask.Group := AGroup;
  Ask.Load := ALoad;
  Ask.Release := ARelease;
  Ask.Traffic := ATraffic;
  TakeAsk(Ask);
end;

procedure TPadWorld.RequestRestore(const AGroup: string;
  const ALoad: TPadLoad; const ARelease: TPadRelease);
var
  Ask: TRebuildAsk;
begin
  Ask := Default(TRebuildAsk);
  Ask.Group := AGroup;
  Ask.Load := ALoad;
  Ask.Release := ARelease;
  Ask.Restore := True;
  TakeAsk(Ask);
end;

// On the group's screen, once no pad of it is knocked - a knock is over
// with the boss's stun, before he flies the lap again
procedure TPadWorld.StartAskedRebuild(AScreen: Integer);
begin
  if FAsked.Group = '' then
    Exit;
  for var Pad in MembersOf(FAsked.Group) do
    if (Pad.Screen <> AScreen) or Pad.Knocked then
      Exit;
  for var Group in FLevel.PadGroups do
    if Group.Tag = FAsked.Group then
      StartRebuild(Group);
  FAsked := Default(TRebuildAsk);
end;

procedure TPadWorld.StartRebuild(const AGroup: TPadGroup);
var
  Flights: TPadFlights;
  Planned: Boolean;
begin
  var Members := MembersOf(AGroup.Tag);
  if FAsked.Restore then
    Planned := TryPlanRestore(AGroup, Members, Flights)
  else
    Planned := TryPlanRebuild(AGroup, Members, Flights);
  if not Planned then
    Exit;
  // A pad that stays on its cell is in no flight: it bobs on, its jets
  // idle
  for var i := 0 to High(Members) do
    if not Flights[i].Idle then
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

// The body of a pad with its top-left corner at AX, AY lies in the zone
function InsideZone(const AZone: TPadZone; AX, AY: Double): Boolean;
begin
  Result := (AX >= AZone.Left * TileSize) and (AX <= AZone.Right * TileSize) and
    (AY >= AZone.Top * TileSize) and (AY <= AZone.Bottom * TileSize);
end;

function CellsInZone(const ACells: TPadCells; const AZone: TPadZone): Boolean;
begin
  for var Cell in ACells do
  begin
    var Inside := InRange(Cell.Col, AZone.Left, AZone.Right) and
      InRange(Cell.Row, AZone.Top, AZone.Bottom);
    if not Inside then
      Exit(False);
  end;
  Result := True;
end;

// The body of a pad with its top-left corner at AX, AY cuts into a wall
// or lies flush on one: a pad skimming the ground would sweep through
// whoever stands there
function TPadWorld.GroundShut(AScreen: Integer; AX, AY: Double): Boolean;
begin
  var Left := AX + WallProbeInset;
  var Right := AX + TileSize - WallProbeInset;
  Result := RowShut(AScreen, Left, Right, AY + WallProbeInset, nil) or
    RowShut(AScreen, Left, Right, AY + TileSize - WallProbeInset, nil) or
    RowShut(AScreen, Left, Right, AY + TileSize + WallProbeInset, nil);
end;

// What bars a flight of the group besides its pads. In the zone nothing
// does - the level keeps it clear. Out of it the ground bars every
// flight, and the traffic the rebuild was asked to mind the ones in
// front: in the depth a pad passes behind it.
function TPadWorld.FlightBarOf(const AGroup: TPadGroup): TFlightBar;
begin
  var Screen := AGroup.Screen;
  var Zone := AGroup.Zone;
  var Traffic: TPadTraffic := FAsked.Traffic;
  Result :=
    function(ATick: Integer; AX, AY: Double; ADeep: Boolean): Boolean
    begin
      if InsideZone(Zone, AX, AY) then
        Exit(False);
      if GroundShut(Screen, AX, AY) then
        Exit(True);
      Result := not ADeep and Assigned(Traffic) and Traffic(ATick, AX, AY);
    end;
end;

function FileCellsOf(const AMembers: TArray<TPad>): TPadCells;
begin
  SetLength(Result, Length(AMembers));
  for var i := 0 to High(AMembers) do
    Result[i] := CellOfPlace(AMembers[i].Placement.X, AMembers[i].Placement.Y);
end;

function TPadWorld.GroupRestored(const AGroup: string): Boolean;
begin
  for var Pad in MembersOf(AGroup) do
  begin
    var OnPlace := (Pad.HomeLeft = Pad.Placement.X) and
      (Pad.HomeTop = Pad.Placement.Y);
    if Pad.Flying or not OnPlace then
      Exit(False);
  end;
  Result := True;
end;

// What the asked rebuild tells a plan of the group's pads as they stand:
// all but where they fly to and how briskly
function TPadWorld.BriefOf(const AGroup: TPadGroup;
  const AMembers: TArray<TPad>): TFlightBrief;
begin
  SetLength(Result.Start, Length(AMembers));
  SetLength(Result.Loaded, Length(AMembers));
  // Zeros when nobody holds the pads back: all free at the start
  SetLength(Result.Release, Length(AMembers));
  for var i := 0 to High(AMembers) do
  begin
    var Pad := AMembers[i];
    Result.Start[i] := CellOfPlace(Pad.HomeLeft, Pad.HomeTop);
    Result.Loaded[i] := Assigned(FAsked.Load) and FAsked.Load(Pad);
    if Assigned(FAsked.Release) then
      Result.Release[i] := FAsked.Release(Result.Start[i]);
  end;
  Result.Bar := FlightBarOf(AGroup);
end;

// Formations thrown until one is judged, assigned and flown; past the
// last throw the level file's formation - when the file keeps the whole
// group in the zone -, with the same rules for the assignment and the
// flights. False - no rebuild this time.
function TPadWorld.TryPlanRebuild(const AGroup: TPadGroup;
  const AMembers: TArray<TPad>; out AFlights: TPadFlights): Boolean;
var
  Cells: TPadCells;
begin
  var Brief := BriefOf(AGroup, AMembers);
  Brief.Pace := BriskPace;
  var Launch := LaunchSpans(FLevel, AGroup, StillSpans(AGroup));
  for var Throw := 1 to MaxThrows do
  begin
    var Judged := TryThrowFormation(FDice, AGroup, Length(AMembers), Cells) and
      JudgeFormation(Cells, AGroup, Launch, FReach);
    var Flown := Judged and
      TryAssignFormation(FDice, Brief.Start, Cells, AGroup, Brief.Target) and
      TryPlanFlights(FDice, Brief, AFlights);
    if Flown then
      Exit(True);
  end;
  var FileCells := FileCellsOf(AMembers);
  Result := CellsInZone(FileCells, AGroup.Zone) and
    TryAssignFormation(FDice, Brief.Start, FileCells, AGroup, Brief.Target) and
    TryPlanFlights(FDice, Brief, AFlights);
end;

// Every pad to its own place of the level file. False - nothing flies
// this time: a pad found no way.
function TPadWorld.TryPlanRestore(const AGroup: TPadGroup;
  const AMembers: TArray<TPad>; out AFlights: TPadFlights): Boolean;
begin
  var Brief := BriefOf(AGroup, AMembers);
  Brief.Target := FileCellsOf(AMembers);
  Brief.Pace := CalmPace;
  Result := TryPlanFlights(FDice, Brief, AFlights);
end;

// ---------------------------------------------------------------------------
// The picture
// ---------------------------------------------------------------------------

procedure TPadWorld.Draw(AScreen: Integer; AAlpha: Single;
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

end.
