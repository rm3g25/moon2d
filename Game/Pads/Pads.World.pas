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
  it clear of the grid's walls. The riders are drawn with the Lift of
  their deck.

  The world is born with the level; a restart rewinds it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.World;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections,
  Sdl2.Core, Render.Sprites, Levels.Pads;

type
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
    FLeft, FTop: Double;
    FPrevLeft, FPrevTop: Double;
    FSag, FSagSpeed: Double; // units down, units a tick
    procedure BuildCycle;
    procedure PlaceOnPath;
    procedure TickSag;
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
    // Units down from the deck the pad is drawn at: the bob and the sag
    function Lift: Double;
    // How far the pad went across this tick
    function MotionX: Double;
    procedure Draw(const ASprites: TSpriteRenderer);

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
    FPads: TObjectList<TPad>;
  public
    // ACache is the level's object art and must outlive the world; a
    // picture it lacks raises here, at level load
    constructor Create(const ASprites: TSpriteRenderer;
      const ACache: TSpriteCache; const APlacements: TArray<TPadPlacement>);
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
    procedure Draw(AScreen: Integer);
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
  FLeft := FPlacement.X;
  FTop := FPlacement.Y;
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
      FLeft := From.X + (Next.X - From.X) * Share;
      FTop := From.Y + (Next.Y - From.Y) * Share;
      Exit;
    end;
    Dec(Time, FLegTicks[i]);
    if Time < FPauseTicks then
    begin
      FLeft := Next.X;
      FTop := Next.Y;
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

procedure TPad.Tick(AOnView: Boolean);
begin
  FPrevLeft := FLeft;
  FPrevTop := FTop;
  if not AOnView then
    Exit;
  Inc(FClock);
  PlaceOnPath;
  TickSag;
end;

procedure TPad.Press(ASpeed: Double);
begin
  FSagSpeed := FSagSpeed + Min(ASpeed * SagGain, SagMaxKick);
end;

function TPad.Lift: Double;
begin
  Result := FSag;
  if FPlacement.Bob <= 0 then
    Exit;
  var Phase := FClock / BobPeriodTicks + FPlacement.X / ScreenWidth;
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

procedure TPad.Draw(const ASprites: TSpriteRenderer);
var
  Dest: TSdlRect;
begin
  Dest.X := Round(FLeft);
  // As the riders are drawn, so the feet do not flicker into the deck
  Dest.Y := Round(FTop) + Round(Lift);
  Dest.W := FPlacement.Width;
  Dest.H := FPictureHeight;
  TintTexture(FTexture, FPlacement.Tint.R, FPlacement.Tint.G,
    FPlacement.Tint.B);
  ASprites.DrawRect(FTexture, Dest);
end;

// ---------------------------------------------------------------------------
// TPadWorld
// ---------------------------------------------------------------------------

constructor TPadWorld.Create(const ASprites: TSpriteRenderer;
  const ACache: TSpriteCache; const APlacements: TArray<TPadPlacement>);
begin
  inherited Create;
  FSprites := ASprites;
  FPads := TObjectList<TPad>.Create(True);
  for var Placement in APlacements do
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

function TPadWorld.FindTagged(const ATag: string): TPad;
begin
  for var Pad in FPads do
    if Pad.Tag = ATag then
      Exit(Pad);
  Result := nil;
end;

procedure TPadWorld.Draw(AScreen: Integer);
begin
  for var Pad in FPads do
    if Pad.Screen = AScreen then
      Pad.Draw(FSprites);
end;

end.
