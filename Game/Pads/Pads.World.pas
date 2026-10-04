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
  for them. A pad on a path only rocks.

  The world is born with the level; a restart rewinds it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.World;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections,
  Sdl2.Core, Render.Sprites, Levels.Pads, Levels.Defs;

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
    procedure BuildCycle;
    procedure PlaceOnPath;
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
    property Left: Double read FLeft;
    property Right: Double read GetRight;
    // The deck: the feet line of whatever stands on the pad
    property Top: Double read FTop;
    property PrevTop: Double read FPrevTop;
  end;

  TPadWorld = class
  private
    FSprites: TSpriteRenderer;
    FLevel: TLevel;
    FPads: TObjectList<TPad>;
    function PadStruck(AScreen: Integer; const ABlow: TPadBlow): TPad;
    function RowShut(AScreen: Integer; ALeft, ARight, AY: Double;
      const AFence: TPadFence): Boolean;
    function RoomFor(const APad: TPad; ADX, ADY: Double;
      const AFence: TPadFence): Boolean;
  public
    // ACache is the level's object art; it and ALevel must outlive the
    // world. A picture the cache lacks raises here, at level load.
    constructor Create(const ASprites: TSpriteRenderer;
      const ACache: TSpriteCache; const ALevel: TLevel);
    destructor Destroy; override;

    // Before the riders move: the pads of AScreen go on along their paths
    procedure Tick(AScreen: Integer);
    // Back to where the level file puts them
    procedure Rewind;
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
    // other pads let it
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
  var Phase := Time / BobPeriodTicks + FPlacement.X / ScreenWidth;
  Result := Result + FPlacement.Bob * Sin(2 * Pi * Phase);
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
  Result := (ALeft <= Right) and (ARight >= FLeft);
end;

function TPad.DeckSpannedBefore(ALeft, ARight: Double): Boolean;
begin
  Result := (ALeft <= FPrevLeft + FPlacement.Width) and (ARight >= FPrevLeft);
end;

function TPad.BodyHolds(AX, AY: Single): Boolean;
begin
  Result := (AX >= FLeft) and (AX < Right) and (AY >= FTop) and
    (AY < FTop + TileSize);
end;

procedure TPad.Draw(const ASprites: TSpriteRenderer; AAlpha: Single);
var
  Dest: TSdlFRect;
begin
  Dest.X := Round(FLeft);
  // As the riders are drawn, so the feet do not flicker into the deck
  Dest.Y := Round(FTop) + Lift(AAlpha);
  Dest.W := FPlacement.Width;
  Dest.H := FPictureHeight;
  TintTexture(FTexture, FPlacement.Tint.R, FPlacement.Tint.G,
    FPlacement.Tint.B);
  ASprites.DrawRectF(FTexture, Dest, Tilt(AAlpha));
end;

// ---------------------------------------------------------------------------
// TPadWorld
// ---------------------------------------------------------------------------

constructor TPadWorld.Create(const ASprites: TSpriteRenderer;
  const ACache: TSpriteCache; const ALevel: TLevel);
begin
  inherited Create;
  FSprites := ASprites;
  FLevel := ALevel;
  FPads := TObjectList<TPad>.Create(True);
  for var Placement in ALevel.Pads do
    FPads.Add(TPad.Create(Placement, ACache.Get(Placement.Sprite)));
end;

destructor TPadWorld.Destroy;
begin
  FPads.Free;
  inherited;
end;

procedure TPadWorld.Tick(AScreen: Integer);
begin
  for var Pad in FPads do
    Pad.Tick(Pad.Screen = AScreen);
end;

procedure TPadWorld.Rewind;
begin
  for var Pad in FPads do
    Pad.Rewind;
end;

function TPadWorld.DeckUnder(AScreen: Integer; ALeft, ARight,
  AFeetY: Double): TPad;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and (Abs(Pad.Top - AFeetY) < DeckSlop) and
      Pad.DeckSpans(ALeft, ARight) then
      Exit(Pad);
  Result := nil;
end;

function TPadWorld.DeckCarrying(AScreen: Integer; ALeft, ARight,
  AFeetY: Double): TPad;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and (Abs(Pad.PrevTop - AFeetY) < DeckSlop) and
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
    if DroppedThrough or (Pad.Screen <> AScreen) then
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
    if (Pad.Screen = AScreen) and Pad.BodyHolds(AX, AY) then
      Exit(True);
  Result := False;
end;

function TPadWorld.StopsBulletAt(AScreen: Integer; AX, AY: Single): Boolean;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and (Pad.Bullets = pbBlock) and
      Pad.BodyHolds(AX, AY) then
      Exit(True);
  Result := False;
end;

// A pad holding a corner of the body a step on: what the pilot's walls
// found there
function TPadWorld.PadStruck(AScreen: Integer; const ABlow: TPadBlow): TPad;
begin
  for var Pad in FPads do
  begin
    if Pad.Screen <> AScreen then
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
      not APad.ClearOf(Other, ADX, ADY) then
      Exit(False);
  Result := True;
end;

// Unit by unit along the blow, a cell's worth at most, sliding along what
// stops one way of it. A pad with no room at all still rocks, and so does
// one on a path: its room is looked for where it stands, and the path
// would take it on from there.
procedure TPadWorld.Shove(AScreen: Integer; const ABlow: TPadBlow;
  const AFence: TPadFence);
begin
  var Pad := PadStruck(AScreen, ABlow);
  if Pad = nil then
    Exit;
  if Pad.Travels then
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

procedure TPadWorld.Draw(AScreen: Integer; AAlpha: Single);
begin
  for var Pad in FPads do
    if Pad.Screen = AScreen then
      Pad.Draw(FSprites, AAlpha);
end;

end.
