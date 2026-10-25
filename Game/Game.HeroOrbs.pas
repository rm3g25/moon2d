{
  Game.HeroOrbs - the hero's orbs: the aura, the rite of the henshin, the
  burst of the suit, the fire rain, and the charge of the form with the
  orbs that carry it into the gauge. Which form the hero wears is his own
  (THero.HeroForm).

  It does not know the game. It asks about the hero through probes, and
  what an orb strikes is settled by the targets the game hands in: the
  unit decides when an orb or a ray strikes, the game what stands there
  and what a wound costs. It rewinds itself; the game only says which
  rewind it is - a new level, a restart, a new screen, the hero's death.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.HeroOrbs;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Levels.Dynamics, Monsters,
  Orbs.Flock, Orbs.Harvest, Orbs.Patterns, Orbs.Aura, Orbs.Rite, Orbs.Burst,
  Orbs.Rain, Orbs.Feed;

const
  // An orb takes an enemy bullet nearer than this on either axis: the
  // reach a hero's bullet intercepts one at
  OrbReach = 6;

type
  THeroAlive = reference to function: Boolean;
  // In screen units
  THeroCenter = reference to function: TSdlFPoint;
  // The matter of the hero's screen
  TMatterProbe = reference to function: TMatter;
  // Bursts the enemy bullet within OrbReach of the point; False when there
  // is none
  TBulletPop = reference to function(AX, AY: Single): Boolean;
  // The dangerous monster whose body holds the point, nil when none does
  TMonsterProbe = reference to function(AX, AY: Single): TMonster;
  // The monster loses a life; a kill is rewarded
  TOrbWound = reference to procedure(const AMonster: TMonster);

  // What the orbs ask about the hero
  TOrbProbes = record
    Alive: THeroAlive;
    Center: THeroCenter;
    Body: TBodyProbe;
    Matter: TMatterProbe;
  end;

  // What an orb strikes
  TOrbTargets = record
    PopBullet: TBulletPop;
    MonsterAt: TMonsterProbe;
    Wound: TOrbWound;
  end;

  THeroOrbs = class
  private
    FProbes: TOrbProbes;
    FTargets: TOrbTargets;
    FAura: TAura; // the hero's ring of orbs
    FRite: TOrbRite; // the orbs of the henshin
    FPattern: TOrbPattern; // the figure the rite builds
    FBurst: TOrbBurst; // the light the suit cannot hold
    // What the burst under way has wounded: none loses more than a life
    FBurstWounded: TList<TMonster>;
    FRain: TOrbRain; // the fire rain of orbs
    FFeed: TOrbFeed; // the charge of the form on its way to the gauge
    // The charge of the form, 0..FullEnergy, and what it was when the hero
    // came onto his screen: a death gives that back - what the screen gave
    // regrows with the field
    FEnergy: Integer;
    FEnergyAtEntry: Integer;
    procedure ClearOrbs;
    procedure ResolveOrbHits(const AFlock: TOrbFlock);
    procedure StrikeWithBurst(AX, AY: Single);
    procedure ResolveBurstHits;
  public
    constructor Create(const AProbes: TOrbProbes;
      const ATargets: TOrbTargets);
    destructor Destroy; override;

    // A new level: no orb, no charge, the level's figure for the rite
    procedure BeginLevel(const APattern: TOrbPattern);
    // A restart after a death: no orb, the charge the screen began with
    procedure Rewind;
    // The hero has come onto a new screen
    procedure Arrive;
    // The hero is dead: the orbs draw into their points, the burst is gone
    procedure Fall;
    // The hero has gone through a door and is this far from where he was.
    // The rite crosses by the door's step alone, before the new screen is
    // greeted; the aura after it, by the door's step and that of a trigger
    // of the new screen.
    procedure CarryRite(AStepX, AStepY: Single);
    procedure CarryAura(AStepX, AStepY: Single);

    procedure BeginRite;
    procedure ShedSuit;
    procedure StartBurst(const ALook: TBurstLook);
    // The ice suit's burst, as the ceremony asks for it
    procedure BurstSuit;
    procedure FeedEnergy(AAmount: Integer);
    // False over the corpse: nothing was cast
    function CastAura: Boolean;
    procedure PourRain;

    // The aura, the rite and the burst; before the ceremony's tick, which
    // hears what they tell
    procedure Tick;
    // The rain and the charge
    procedure TickAfterCeremony;
    // The orbs and the burst against the targets
    procedure Strike;
    // The first armed orb of the aura, the rite or the rain within OrbReach
    // of the stretch from AFromX to AToX at AY is spent on what flies
    // there - a shard, a cannon's round - as on an enemy bullet; False when
    // none is
    function TakesAt(AFromX, AToX, AY: Single): Boolean;
    // The burst's inhale: the world stands
    function Holding: Boolean;
    // The burst's inhale: the hero is drawn as a bare figure
    function Inhaling: Boolean;

    // The layers, from the back: the rite behind the hero; the burst's
    // veil under him; his bare figure through the inhale; the orbs over
    // the world; the burst's flash on the glass; the charge going into
    // the gauge
    procedure DrawBehind(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawVeil(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint);
    procedure DrawSilhouette(const ACanvas: TDynamicCanvas;
      const AFigure: TBurstFigure);
    procedure DrawOrbs(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawGlass(const ACanvas: TDynamicCanvas; AAlpha: Single);
    procedure DrawFeed(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);

    property Energy: Integer read FEnergy;
    // The ceremony watches them
    property Rite: TOrbRite read FRite;
    property Burst: TOrbBurst read FBurst;
  end;

implementation

uses
  Hud.Energy;

const
  // A burst strikes along the way a ray's head has passed every this many
  // units: under the orb's reach, so no bullet slips between
  BurstHitStep = 4;

constructor THeroOrbs.Create(const AProbes: TOrbProbes;
  const ATargets: TOrbTargets);
begin
  inherited Create;
  FProbes := AProbes;
  FTargets := ATargets;
  FAura := TAura.Create(IceOrbTint);
  FRite := TOrbRite.Create(IceOrbTint, FProbes.Body);
  FBurst := TOrbBurst.Create(FProbes.Body);
  FBurstWounded := TList<TMonster>.Create;
  FRain := TOrbRain.Create(IceOrbTint);
  FFeed := TOrbFeed.Create(MoonOrbTint);
end;

destructor THeroOrbs.Destroy;
begin
  FFeed.Free;
  FRain.Free;
  FBurstWounded.Free;
  FBurst.Free;
  FRite.Free;
  FAura.Free;
  inherited;
end;

procedure THeroOrbs.ClearOrbs;
begin
  FAura.Clear;
  FRite.Clear;
  FBurst.Clear;
  FBurstWounded.Clear;
  FRain.Clear;
  FFeed.Clear;
end;

procedure THeroOrbs.BeginLevel(const APattern: TOrbPattern);
begin
  FPattern := APattern;
  ClearOrbs;
  FEnergy := 0;
  FEnergyAtEntry := 0;
end;

procedure THeroOrbs.Rewind;
begin
  ClearOrbs;
  FEnergy := FEnergyAtEntry;
end;

procedure THeroOrbs.Arrive;
begin
  // The orbs still on their way are the charge's already: a death here
  // must not take back what the screen before gave
  FEnergyAtEntry := FEnergy + FFeed.Pending;
  FRain.Clear;
end;

procedure THeroOrbs.Fall;
begin
  FAura.Collapse;
  FRite.Collapse;
  FBurst.Clear;
  FRain.Collapse;
  FFeed.Collapse;
end;

procedure THeroOrbs.CarryRite(AStepX, AStepY: Single);
begin
  FRite.Carry(AStepX, AStepY);
end;

procedure THeroOrbs.CarryAura(AStepX, AStepY: Single);
begin
  FAura.Carry(AStepX, AStepY);
end;

// The rite is the living hero's: called over the corpse, it is spent on
// nothing
procedure THeroOrbs.BeginRite;
begin
  if not FProbes.Alive() then
    Exit;
  FRite.Start(FPattern, IceRiteScore, FProbes.Center(), FProbes.Matter());
end;

// The suit's orbs are the living hero's, like the rite's: over the corpse
// they are spent on nothing
procedure THeroOrbs.ShedSuit;
begin
  if not FProbes.Alive() then
    Exit;
  FRite.Shed(IceRiteScore, FProbes.Center());
end;

// The burst is the living hero's, like the rite's: over the corpse it is
// spent on nothing. A vortex sends its rays out curled.
procedure THeroOrbs.StartBurst(const ALook: TBurstLook);
begin
  if not FProbes.Alive() then
    Exit;
  FBurstWounded.Clear;
  FBurst.Start(ALook, FPattern.Name = 'vortex', FProbes.Center(),
    FProbes.Matter());
end;

procedure THeroOrbs.BurstSuit;
begin
  StartBurst(IceBurstLook);
end;

// The charge is the living hero's, like the rite's; what would run the
// gauge past full stays where it came from
procedure THeroOrbs.FeedEnergy(AAmount: Integer);
begin
  if not FProbes.Alive() then
    Exit;
  var Amount := AAmount;
  var Room := FullEnergy - FEnergy - FFeed.Pending;
  if Amount > Room then
    Amount := Room;
  FFeed.Start(Amount, THudEnergy.Heart);
end;

// The aura rings the living: called over the corpse, it is spent on
// nothing
function THeroOrbs.CastAura: Boolean;
begin
  if not FProbes.Alive() then
    Exit(False);
  FAura.Cast(FProbes.Center(), FProbes.Matter());
  Result := True;
end;

// The rain is the hero's to call, as the aura is: over a corpse it is
// spent on nothing
procedure THeroOrbs.PourRain;
begin
  if not FProbes.Alive() then
    Exit;
  FRain.Pour(FProbes.Matter());
end;

procedure THeroOrbs.Tick;
begin
  var Center := FProbes.Center();
  FAura.Tick(Center);
  FRite.Tick(Center);
  FBurst.Tick(Center);
end;

// The orbs fly, and the charge they bring in is the hero's
procedure THeroOrbs.TickAfterCeremony;
begin
  FRain.Tick;
  FFeed.Tick(FProbes.Center());
  Inc(FEnergy, FFeed.TakeLanded);
end;

procedure THeroOrbs.Strike;
begin
  ResolveOrbHits(FAura.Flock);
  ResolveOrbHits(FRite.Flock);
  ResolveBurstHits;
  ResolveOrbHits(FRain.Flock);
end;

// An orb ends on what it meets, as a hero's bullet does: an enemy bullet
// bursts, a dangerous monster loses a life. An orb not armed meets
// nothing.
procedure THeroOrbs.ResolveOrbHits(const AFlock: TOrbFlock);
begin
  for var Orb in AFlock.Orbs do
  begin
    if (Orb.State <> osAlive) or not Orb.Armed then
      Continue;

    if FTargets.PopBullet(Orb.X, Orb.Y) then
    begin
      AFlock.Spend(Orb);
      Continue;
    end;

    var Monster := FTargets.MonsterAt(Orb.X, Orb.Y);
    if Monster = nil then
      Continue;
    AFlock.Spend(Orb);
    FTargets.Wound(Monster);
  end;
end;

// A ray of the burst at a point of its way: an enemy bullet there bursts,
// a dangerous monster loses a life - one for the whole burst, however many
// rays it stands in the way of
procedure THeroOrbs.StrikeWithBurst(AX, AY: Single);
begin
  FTargets.PopBullet(AX, AY);

  var Monster := FTargets.MonsterAt(AX, AY);
  if (Monster = nil) or FBurstWounded.Contains(Monster) then
    Exit;
  FBurstWounded.Add(Monster);
  FTargets.Wound(Monster);
end;

// The burst strikes along all the way its heads have passed this tick,
// behind walls as well
procedure THeroOrbs.ResolveBurstHits;
begin
  for var Stretch in FBurst.Stretches do
  begin
    var SpanX: Single := Stretch.ToX - Stretch.FromX;
    var SpanY: Single := Stretch.ToY - Stretch.FromY;
    // A step a hair short of BurstHitStep at most, and at least one
    var Steps := Trunc(Sqrt(SpanX * SpanX + SpanY * SpanY) / BurstHitStep) + 1;
    for var i := 0 to Steps do
      StrikeWithBurst(Stretch.FromX + SpanX * i / Steps,
        Stretch.FromY + SpanY * i / Steps);
  end;
end;

function THeroOrbs.TakesAt(AFromX, AToX, AY: Single): Boolean;
var
  Flocks: TArray<TOrbFlock>;
begin
  var Nearer: Single := AFromX - OrbReach;
  var Farther: Single := AToX + OrbReach;
  if AToX < AFromX then
  begin
    Nearer := AToX - OrbReach;
    Farther := AFromX + OrbReach;
  end;
  Flocks := [FAura.Flock, FRite.Flock, FRain.Flock];
  for var Flock in Flocks do
    for var Orb in Flock.Orbs do
    begin
      var Ready := (Orb.State = osAlive) and Orb.Armed;
      var InReach := (Abs(Orb.Y - AY) < OrbReach) and (Orb.X > Nearer) and
        (Orb.X < Farther);
      if Ready and InReach then
      begin
        Flock.Spend(Orb);
        Exit(True);
      end;
    end;
  Result := False;
end;

function THeroOrbs.Holding: Boolean;
begin
  Result := FBurst.Holding;
end;

function THeroOrbs.Inhaling: Boolean;
begin
  Result := FBurst.Inhaling;
end;

procedure THeroOrbs.DrawBehind(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  FRite.DrawBehind(ACanvas, AOrigin, AAlpha);
end;

procedure THeroOrbs.DrawVeil(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint);
begin
  FBurst.DrawVeil(ACanvas, AOrigin);
end;

procedure THeroOrbs.DrawSilhouette(const ACanvas: TDynamicCanvas;
  const AFigure: TBurstFigure);
begin
  FBurst.DrawSilhouette(ACanvas, AFigure);
end;

procedure THeroOrbs.DrawOrbs(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FAura.Draw(ACanvas, AOrigin, AAlpha);
  FRite.DrawInFront(ACanvas, AOrigin, AAlpha);
  FBurst.DrawWorld(ACanvas, AOrigin, AAlpha);
  FRain.Draw(ACanvas, AOrigin, AAlpha);
end;

procedure THeroOrbs.DrawGlass(const ACanvas: TDynamicCanvas; AAlpha: Single);
begin
  FBurst.DrawGlass(ACanvas, AAlpha);
end;

procedure THeroOrbs.DrawFeed(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FFeed.Draw(ACanvas, AOrigin, AAlpha);
end;

end.
