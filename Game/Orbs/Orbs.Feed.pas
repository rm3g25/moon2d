{
  Orbs.Feed - the orbs that carry a charge into its gauge. They come out
  of the hero one after another, slowly, as if he could not hold them;
  hang about him for a while, each over its own spot above his
  shoulders, keeping to him as he goes; and then fly up to the gauge,
  each its own curve, gathering speed, and go into it.

  The charge is split among the orbs; the feed tells how much of it has
  reached the gauge and how much is still on its way. What the charge is
  for is the game's. An orb of the feed strikes nothing.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Feed;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Levels.Dynamics,
  Orbs.Flock;

type
  TOrbFeed = class
  private type
    TFedOrb = record
      Orb: TOrb; // the flock's; nil until it comes out
      Amount: Integer; // the charge it carries
      WaitTicks: Integer; // until it comes out
      Age: Integer; // ticks since it came out
      HoverTicks: Integer;
      // Where it hangs, from the hero's center
      OffsetX, OffsetY: Single;
      Phase: Single; // of its sway as it hangs
      Bend: Single; // units its flight bows aside at the middle
      Launched: Boolean;
      LaunchX, LaunchY: Single;
    end;
  private
    FFlock: TOrbFlock;
    FOrbs: TList<TFedOrb>;
    FTarget: TSdlFPoint;
    FHeroCenter: TSdlFPoint;
    FLanded: Integer;
    // Own stream, not Random: that one feeds the boss spawn table
    FDice: TXorShift;
    function NewOrb(AIndex, ACount, AAmount: Integer): TFedOrb;
    procedure ComeOut(var AFed: TFedOrb);
    procedure Rise(var AFed: TFedOrb; AStepX, AStepY: Single);
    procedure Hang(var AFed: TFedOrb; AStepX, AStepY: Single);
    // True once the orb is in the gauge
    function Fly(var AFed: TFedOrb): Boolean;
  public
    constructor Create(const ATint: TOrbTint);
    destructor Destroy; override;
    // AAmount of the charge leaves the hero for the gauge at ATarget. A
    // feed under way goes on: the new orbs join it.
    procedure Start(AAmount: Integer; const ATarget: TSdlFPoint);
    // Once per logic tick, the hero's center as of now - also while no
    // feed is under way: an orb comes out where the last tick saw him
    procedure Tick(const AHeroCenter: TSdlFPoint);
    // The charge that has gone into the gauge since the last call
    function TakeLanded: Integer;
    // The charge still on its way, the landed but not taken among it
    function Pending: Integer;
    // The hero is gone: the orbs draw into their points, the charge with
    // them
    procedure Collapse;
    procedure Clear;
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    property Flock: TOrbFlock read FFlock;
  end;

const
  // The most orbs a charge is split into
  FeedOrbs = 5;

implementation

uses
  System.Math;

const
  // A beat after the taking, then one orb this many ticks after another
  FirstWaitTicks = 15;
  StepTicks = 9;
  RiseTicks = 30;
  HoverMinTicks = 60;
  HoverSpreadTicks = 25;
  FlyTicks = 40;
  // The orb grows out of a point to its full size as it rises, and is a
  // little smaller when it goes in
  BornSize = 0.2;
  LandedSize = 0.65;
  // The spots above the hero: an arc of this share of a half-circle, its
  // middle straight up, this far out, and a little higher
  ArcShare = 0.7;
  HangRadius = 22;
  HangRadiusSpread = 8;
  HangLift = 4;
  // The sway of a hanging orb: units across and up, radians a tick
  SwayX = 2;
  SwayY = 2.5;
  SwaySpeedX = 0.07;
  SwaySpeedY = 0.09;
  BendSpread = 50;
  DiceSeed = $46656564; // "Feed"

constructor TOrbFeed.Create(const ATint: TOrbTint);
begin
  inherited Create;
  FFlock := TOrbFlock.Create(ATint);
  FOrbs := TList<TFedOrb>.Create;
  FDice.Seed := DiceSeed;
end;

destructor TOrbFeed.Destroy;
begin
  FOrbs.Free;
  FFlock.Free;
  inherited;
end;

procedure TOrbFeed.Start(AAmount: Integer; const ATarget: TSdlFPoint);
begin
  if AAmount <= 0 then
    Exit;
  FTarget := ATarget;
  var Count := Min(AAmount, FeedOrbs);
  for var i := 0 to Count - 1 do
  begin
    var Share := AAmount div Count;
    if i < AAmount mod Count then
      Inc(Share);
    FOrbs.Add(NewOrb(i, Count, Share));
  end;
end;

function TOrbFeed.NewOrb(AIndex, ACount, AAmount: Integer): TFedOrb;
begin
  Result := Default(TFedOrb);
  Result.Amount := AAmount;
  Result.WaitTicks := FirstWaitTicks + AIndex * StepTicks;
  Result.HoverTicks := HoverMinTicks +
    Trunc(FDice.NextUnit * (HoverSpreadTicks + 1));

  // Left to right over the hero's head; a lone orb straight above him
  var Along: Single := 0.5;
  if ACount > 1 then
    Along := AIndex / (ACount - 1);
  var Angle: Single := Pi + Pi * ((1 - ArcShare) / 2 + ArcShare * Along);
  var Radius: Single := HangRadius + FDice.NextUnit * HangRadiusSpread;
  Result.OffsetX := Cos(Angle) * Radius;
  Result.OffsetY := Sin(Angle) * Radius - HangLift;
  Result.Phase := FDice.NextUnit * 2 * Pi;
  Result.Bend := (FDice.NextUnit - 0.5) * BendSpread;
end;

procedure TOrbFeed.ComeOut(var AFed: TFedOrb);
begin
  AFed.Orb := TOrb.Create(FHeroCenter.X, FHeroCenter.Y);
  AFed.Orb.Size := BornSize;
  AFed.Orb.Level := 0;
  AFed.Orb.Armed := False;
  FFlock.Add(AFed.Orb);
end;

procedure TOrbFeed.Rise(var AFed: TFedOrb; AStepX, AStepY: Single);
begin
  var Share: Single := AFed.Age / RiseTicks;
  var Eased: Single := 1 - Sqr(1 - Share);
  AFed.Orb.Size := BornSize + (1 - BornSize) * Eased;
  AFed.Orb.Level := Eased;
  AFed.Orb.MoveBeside(FHeroCenter.X + AFed.OffsetX * Eased,
    FHeroCenter.Y + AFed.OffsetY * Eased, AStepX, AStepY);
end;

procedure TOrbFeed.Hang(var AFed: TFedOrb; AStepX, AStepY: Single);
begin
  var Swaying := AFed.Age - RiseTicks;
  AFed.Orb.MoveBeside(
    FHeroCenter.X + AFed.OffsetX + Sin(Swaying * SwaySpeedX + AFed.Phase) * SwayX,
    FHeroCenter.Y + AFed.OffsetY + Cos(Swaying * SwaySpeedY + AFed.Phase) * SwayY,
    AStepX, AStepY);
end;

function TOrbFeed.Fly(var AFed: TFedOrb): Boolean;
begin
  if not AFed.Launched then
  begin
    AFed.Launched := True;
    AFed.LaunchX := AFed.Orb.X;
    AFed.LaunchY := AFed.Orb.Y;
  end;
  var Share: Single := (AFed.Age - RiseTicks - AFed.HoverTicks) / FlyTicks;
  if Share > 1 then
    Share := 1;
  var Eased: Single := Share * Share * Share;
  var Bow: Single := Sin(Pi * Share) * AFed.Bend;
  AFed.Orb.Size := 1 - (1 - LandedSize) * Eased;
  AFed.Orb.MoveTo(AFed.LaunchX + (FTarget.X - AFed.LaunchX) * Eased + Bow,
    AFed.LaunchY + (FTarget.Y - AFed.LaunchY) * Eased);
  Result := Share >= 1;
end;

procedure TOrbFeed.Tick(const AHeroCenter: TSdlFPoint);
begin
  FFlock.Tick;
  var StepX: Single := AHeroCenter.X - FHeroCenter.X;
  var StepY: Single := AHeroCenter.Y - FHeroCenter.Y;
  FHeroCenter := AHeroCenter;
  for var i := FOrbs.Count - 1 downto 0 do
  begin
    var Fed := FOrbs[i];
    if Fed.WaitTicks > 0 then
    begin
      Dec(Fed.WaitTicks);
      if Fed.WaitTicks = 0 then
        ComeOut(Fed);
      FOrbs[i] := Fed;
      Continue;
    end;

    Inc(Fed.Age);
    if Fed.Age <= RiseTicks then
      Rise(Fed, StepX, StepY)
    else if Fed.Age <= RiseTicks + Fed.HoverTicks then
      Hang(Fed, StepX, StepY)
    else if Fly(Fed) then
    begin
      Inc(FLanded, Fed.Amount);
      FFlock.Release(Fed.Orb);
      FOrbs.Delete(i);
      Continue;
    end;
    FOrbs[i] := Fed;
  end;
end;

function TOrbFeed.TakeLanded: Integer;
begin
  Result := FLanded;
  FLanded := 0;
end;

function TOrbFeed.Pending: Integer;
begin
  Result := FLanded;
  for var Fed in FOrbs do
    Inc(Result, Fed.Amount);
end;

procedure TOrbFeed.Collapse;
begin
  for var Fed in FOrbs do
    if Fed.Orb <> nil then
      FFlock.Implode(Fed.Orb);
  FOrbs.Clear;
  FLanded := 0;
end;

procedure TOrbFeed.Clear;
begin
  FFlock.Clear;
  FOrbs.Clear;
  FLanded := 0;
end;

procedure TOrbFeed.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FFlock.Draw(ACanvas, AOrigin, AAlpha);
end;

end.
