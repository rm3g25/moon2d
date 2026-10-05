{
  Pads.Arena - the director of a boss fight over a pad group that is
  rebuilt (Levels.Pads, Pads.World): when the pads fly, and in step with
  whom.

  An event engages it (the action rebuild); from then on, and while the
  group's conductor - the monster its tag names - lives:
  - the lap is held: the conductor ends the maneuver it is in, comes back
    to its lap - a hunter flies a parade lap for it - and starts no other;
  - once it flies the lap, the alarm lamps of the group warn for a moment
    (the game voices the warning: Warned);
  - the pads are rebuilt, each setting off as the conductor flies past
    it: over its column on a level side of the lap, past its row on an
    upright one. The lap is foreseen to the end (Monsters.Pilot), so the
    whole wave is planned at the start. A pad going deep sinks at once,
    as in every rebuild (Pads.Flights), and flies in the depth in its
    turn;
  - the last pad down, the lap is let go, and the next rebuild comes the
    group's every seconds later.
  The first rebuild comes at once.

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
  TArenaPhase = (arAsleep, arResting, arHolding, arWarning, arFlying);

  TPadArena = class
  private
    FPads: TPadWorld;
    FDynamics: TDynamicObjects;
    FGroups: TArray<TPadGroup>;
    FLoad: TPadLoad;
    FGroup: TPadGroup; // the one engaged
    FPhase: TArenaPhase;
    FTicksLeft: Integer; // of the rest and of the warning
    FWarned: Boolean;
    FLap: TArray<TLapStep>; // the conductor's lap from the rebuild's start
    function ReleaseOf(const ACell: TPadCell): Integer;
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
  System.Math;

const
  LogicTicksPerSecond = 33; // tickRate of Game.Config
  // The alarm lamps blink this long before the rebuild is asked for
  WarningTicks = 13; // 0.4 s
  AlarmFadeInTicks = 2;
  AlarmFadeOutTicks = 6;
  // The lap foreseen for the wave: a whole lap even at three units a
  // tick, the step of the level-1 boss before its rage - every column
  // and row of the lap is flown past within it
  LapAheadTicks = 15 * LogicTicksPerSecond;

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

procedure TPadArena.Reset;
begin
  if FGroup.Alarm <> '' then
    FDynamics.RewindTagged(FGroup.Alarm);
  FPhase := arAsleep;
  FLap := nil;
  FWarned := False;
end;

// The conductor is gone: no rebuild more, a flying one lands as planned
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
  FPads.RequestRebuild(FGroup.Tag, FLoad, ReleaseOf);
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

end.
