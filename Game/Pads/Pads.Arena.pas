{
  Pads.Arena - the director of a boss fight over a pad group that is
  rebuilt (Levels.Pads, Pads.World): when the pads fly, and in step with
  whom.

  An event engages it (the action rebuild); from then on, and while the
  group's conductor - the monster its tag names - lives:
  - the lap is held: the conductor ends the maneuver it is in, comes back
    to its lap - a hunter flies a parade lap for it - and starts no other;
  - once it flies the lap, the alarm lamps of the group warn for a second
    (the game voices the warning: Warned);
  - the pads are rebuilt, each setting off as the conductor flies past
    it: over its column on a level side of the lap, past its row on an
    upright one. The lap is foreseen to the end (Monsters.Pilot), so the
    whole wave is planned at the start. A pad going deep sinks at once,
    as in every rebuild (Pads.Flights), and flies in the depth in its
    turn. A pad the level file puts outside the zone crosses the lap to
    fly in: in front it crosses well clear of the conductor;
  - the last pad down, the lap is let go, and the next rebuild comes the
    group's every seconds later.
  The first rebuild comes at once.

  Another event calls the fight off (the action restore): no rebuild
  more, and the pads fly back to where the level file puts them, calmly
  (Pads.World). The wave of it ripples out from the conductor - from its
  wreck, when the fight was won. A rebuild in the air lands first.

  Not here: the pads' flights (Pads.World, Pads.Flights) and what the
  conductor does with a lap let go (Monsters.Pilot).

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.Arena;
{$I ..\..\Moon2D.inc}

interface

uses
  Levels.Pads, Levels.Dynamics, Monsters, Monsters.Pilot, Pads.Formations,
  Pads.World;

type
  TArenaPhase = (arAsleep, arResting, arHolding, arWarning, arFlying,
    arRestoring);

  TPadArena = class
  private
    FPads: TPadWorld;
    FDynamics: TDynamicObjects;
    FGroups: TArray<TPadGroup>;
    FLoad: TPadLoad;
    FGroup: TPadGroup; // the one engaged
    FPhase: TArenaPhase;
    // Of the rest, of the warning, and until a restore is asked for again
    FTicksLeft: Integer;
    FWarned: Boolean;
    FLap: TArray<TLapStep>; // the conductor's lap from the rebuild's start
    FRipple: TPadCell; // the wave of a restore spreads from here
    function ReleaseOf(const ACell: TPadCell): Integer;
    function LapBars(ATick: Integer; AX, AY: Double): Boolean;
    function RippleOf(const ACell: TPadCell): Integer;
    function RippleCell(const AField: TMonsterField): TPadCell;
    procedure LetLapGo(const AField: TMonsterField);
    procedure TickRestoring(const AField: TMonsterField);
    procedure TickResting(const AConductor: TMonster);
    procedure TickHolding(const AConductor: TMonster);
    procedure TickWarning(const AConductor: TMonster);
    procedure TickFlying(const AConductor: TMonster);
    procedure FallAsleep;
  public
    // APads and ADynamics must outlive the arena; ALoad says which pad the
    // rebuilds must not take into the depth
    constructor Create(const APads: TPadWorld;
      const ADynamics: TDynamicObjects; const AGroups: TArray<TPadGroup>;
      const ALoad: TPadLoad);
    // The event's rebuild action: the group tagged AGroup is rebuilt from
    // now on. Nothing for a group without a conductor or while one is
    // engaged.
    procedure Engage(const AGroup: string);
    // The event's restore action: the group tagged AGroup is rebuilt no
    // more, its pads fly back to where the level file puts them
    procedure Restore(const AGroup: string);
    // One logic tick with the hero on AScreen, after the monsters have
    // moved: the field is reborn on a restart, so it comes every tick
    procedure Tick(AScreen: Integer; const AField: TMonsterField);
    // A restart: asleep until the event engages it again, the alarm as
    // the level file has it
    procedure Reset;
    // One tick only: the warning of a rebuild has begun
    property Warned: Boolean read FWarned;
  end;

implementation

uses
  System.Math, Render.Sprites;

const
  LogicTicksPerSecond = 33; // tickRate of Game.Config
  // The alarm lamps blink this long before the rebuild is asked for: a
  // second - long enough to read the lamps and pick a pad. The hum of the
  // warning (tools/sounds/pads.py) is made for it: 1.2 s, its tail dying
  // under the first flights.
  WarningTicks = 33;
  AlarmFadeInTicks = 2;
  AlarmFadeOutTicks = 6;
  // The lap foreseen for the wave: a whole lap even at three units a
  // tick, the step of the level-1 boss before its rage - every column
  // and row of the lap is flown past within it
  LapAheadTicks = 15 * LogicTicksPerSecond;
  // The lap is foreseen, not flown yet, and the hero's bullets shove the
  // conductor along it: a pad crossing the lap keeps this many ticks of
  // the lap either way, and this many units, clear of the body
  LapSlackTicks = 20;
  LapClearance = 16;
  // A restore ripples out: a pad a cell farther from where it spreads
  // sets off this many ticks later
  RippleTicksPerCell = 4;
  // A restore that found a pad no way - the one the hero rides has the
  // front alone to fly in - is asked for again this much later
  RestoreRetryTicks = 15;

constructor TPadArena.Create(const APads: TPadWorld;
  const ADynamics: TDynamicObjects; const AGroups: TArray<TPadGroup>;
  const ALoad: TPadLoad);
begin
  inherited Create;
  FPads := APads;
  FDynamics := ADynamics;
  FGroups := AGroups;
  FLoad := ALoad;
  FPhase := arAsleep;
end;

procedure TPadArena.Engage(const AGroup: string);
begin
  if FPhase <> arAsleep then
    Exit;
  for var Group in FGroups do
    if (Group.Tag = AGroup) and (Group.Conductor <> '') then
    begin
      FGroup := Group;
      FTicksLeft := 0;
      FPhase := arResting;
      Exit;
    end;
end;

procedure TPadArena.Restore(const AGroup: string);
begin
  for var Group in FGroups do
    if Group.Tag = AGroup then
    begin
      FallAsleep;
      FGroup := Group;
      FTicksLeft := 0;
      FPhase := arRestoring;
      Exit;
    end;
end;

procedure TPadArena.Reset;
begin
  if FGroup.Alarm <> '' then
    FDynamics.RewindTagged(FGroup.Alarm);
  FPhase := arAsleep;
  FLap := nil;
  FWarned := False;
end;

// No rebuild more; one in the air lands as planned
procedure TPadArena.FallAsleep;
begin
  if FGroup.Alarm <> '' then
    FDynamics.FadeTagged(FGroup.Alarm, 0, AlarmFadeOutTicks);
  FPhase := arAsleep;
end;

procedure TPadArena.Tick(AScreen: Integer; const AField: TMonsterField);
begin
  FWarned := False;
  if (FPhase = arAsleep) or (AScreen <> FGroup.Screen) then
    Exit;
  if FPhase = arRestoring then
  begin
    TickRestoring(AField);
    Exit;
  end;
  var Conductor := AField.FirstAliveTagged(FGroup.Conductor);
  if Conductor = nil then
  begin
    FallAsleep;
    Exit;
  end;

  case FPhase of
    arResting:
      TickResting(Conductor);
    arHolding:
      TickHolding(Conductor);
    arWarning:
      TickWarning(Conductor);
    arFlying:
      TickFlying(Conductor);
  end;
end;

procedure TPadArena.TickResting(const AConductor: TMonster);
begin
  Dec(FTicksLeft);
  if FTicksLeft > 0 then
    Exit;
  AConductor.HoldLap(True);
  FPhase := arHolding;
end;

// On the lap, no rebuild of another's - the debug key's - in the air and
// no pad knocked: the rebuild starts the next tick, in step with the lap
// foreseen
procedure TPadArena.TickHolding(const AConductor: TMonster);
begin
  var Ready := AConductor.FliesLap and not FPads.Rebuilding and
    not FPads.GroupKnocked(FGroup.Tag);
  if not Ready then
    Exit;
  if FGroup.Alarm <> '' then
    FDynamics.FadeTagged(FGroup.Alarm, 1, AlarmFadeInTicks);
  FTicksLeft := WarningTicks;
  FWarned := True;
  FPhase := arWarning;
end;

// A rebuild of another's started meanwhile: back to waiting it out, the
// lamps lit
procedure TPadArena.TickWarning(const AConductor: TMonster);
begin
  if FPads.Rebuilding then
  begin
    FPhase := arHolding;
    Exit;
  end;
  Dec(FTicksLeft);
  if FTicksLeft > 0 then
    Exit;
  FLap := AConductor.LapAhead(LapAheadTicks);
  FPads.RequestRebuild(FGroup.Tag, FLoad, ReleaseOf, LapBars);
  if FGroup.Alarm <> '' then
    FDynamics.FadeTagged(FGroup.Alarm, 0, AlarmFadeOutTicks);
  FPhase := arFlying;
end;

procedure TPadArena.TickFlying(const AConductor: TMonster);
begin
  if FPads.Rebuilding then
    Exit;
  AConductor.HoldLap(False);
  FTicksLeft := Max(1, Round(FGroup.Every * LogicTicksPerSecond));
  FPhase := arResting;
end;

// The first tick the conductor flies past the cell: over its column on a
// level side, past its row on an upright one. A cell the lap never
// passes sets off at once.
function TPadArena.ReleaseOf(const ACell: TPadCell): Integer;
begin
  for var i := 0 to High(FLap) do
  begin
    var LevelSide := FLap[i].Heading in [hdLeft, hdRight];
    var PastColumn := LevelSide and (FLap[i].Cell.Col = ACell.Col);
    var PastRow := not LevelSide and (FLap[i].Cell.Row = ACell.Row);
    if PastColumn or PastRow then
      Exit(i + 1);
  end;
  Result := 0;
end;

// The conductor's body comes too near a pad's with its top-left corner at
// AX, AY. The pads move before the monsters: a tick of the rebuild is the
// step of the lap before it.
function TPadArena.LapBars(ATick: Integer; AX, AY: Double): Boolean;
begin
  var Reach := TileSize + LapClearance;
  var First := Max(0, ATick - 1 - LapSlackTicks);
  var Last := Min(High(FLap), ATick - 1 + LapSlackTicks);
  for var i := First to Last do
  begin
    var BodyLeft := FLap[i].Feet.X;
    var BodyTop := FLap[i].Feet.Y - SpriteSize;
    if (Abs(BodyLeft - AX) < Reach) and (Abs(BodyTop - AY) < Reach) then
      Exit(True);
  end;
  Result := False;
end;

// A fight called off with the conductor alive: the lap is its own again
procedure TPadArena.LetLapGo(const AField: TMonsterField);
begin
  if FGroup.Conductor = '' then
    Exit;
  var Conductor := AField.FirstAliveTagged(FGroup.Conductor);
  if Conductor <> nil then
    Conductor.HoldLap(False);
end;

// A rebuild in the air lands first, a knocked pad comes back. Then the
// restore is asked for - again and again, until the pads are in their
// places.
procedure TPadArena.TickRestoring(const AField: TMonsterField);
begin
  LetLapGo(AField);
  if FPads.Rebuilding or FPads.GroupKnocked(FGroup.Tag) then
    Exit;
  if FPads.GroupRestored(FGroup.Tag) then
  begin
    FPhase := arAsleep;
    Exit;
  end;
  Dec(FTicksLeft);
  if FTicksLeft > 0 then
    Exit;
  FRipple := RippleCell(AField);
  FPads.RequestRestore(FGroup.Tag, FLoad, RippleOf);
  FTicksLeft := RestoreRetryTicks;
end;

// Under the middle of the conductor's body, dead or alive; the middle of
// the zone for a group without one
function TPadArena.RippleCell(const AField: TMonsterField): TPadCell;
begin
  Result.Col := (FGroup.Zone.Left + FGroup.Zone.Right) div 2;
  Result.Row := (FGroup.Zone.Top + FGroup.Zone.Bottom) div 2;
  if FGroup.Conductor = '' then
    Exit;
  var Body := AField.FirstTagged(FGroup.Conductor);
  if Body = nil then
    Exit;
  Result.Col := Floor((Body.X + SpriteSize / 2) / TileSize);
  Result.Row := Floor((Body.Y - SpriteSize / 2) / TileSize);
end;

function TPadArena.RippleOf(const ACell: TPadCell): Integer;
begin
  var Across: Double := ACell.Col - FRipple.Col;
  var Down: Double := ACell.Row - FRipple.Row;
  Result := Round(RippleTicksPerCell * Hypot(Across, Down));
end;

end.
