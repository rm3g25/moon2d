{
  Monsters.Defs - monster definitions loaded from monsters.json.

  Replaces the fourteen hardcoded if-blocks in the old TMonster.Create
  (monst.pas, 2008). Definitions are immutable data: the registry owns them,
  gameplay code reads them and never writes.

  Moon 2D remake. Requires Delphi 10.3+ (System.JSON, inline var).
}
unit Monsters.Defs;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, System.JSON, Localization;

type
  EMonsterDefError = class(Exception);

  TMonsterCategory = (mcEnemy, mcPickup, mcProp, mcBoss);

  TMovementKind = (mkStatic, mkPatrol, mkPatrolNoEdgeCheck, mkChaseHero,
    mkBossFly);

  TAttackPattern = (apNone, apStraightSingle, apStraightCluster5,
    apAimedSingle, apAimedDouble, apRainVolley);

  TPickupEffectKind = (peNone, peHeal, peGiveWeapon);

  // How a death looks when it blows up - flash, debris, smoke - by size
  // (Game.Explosions); ekNone = no look. The fragment fans of 2008 are
  // ExplodesOnDeath and do not depend on it.
  TExplosionKind = (ekNone, ekBarrel, ekMachine, ekBoss);

  TMovementDef = record
    Kind: TMovementKind;
    Speed: Integer;
  end;

  TAttackDef = record
    Pattern: TAttackPattern;
    FireEveryTicks: Integer;
    BulletSpeed: Integer;
    SecondBulletOffsetX: Integer; // apAimedDouble only
    ClusterOffset: Integer;       // apStraightCluster5 only
    VolleyCount: Integer;         // apRainVolley only
    VolleySpacingX: Integer;      // apRainVolley only
    AngleDeg: Integer;            // apRainVolley only
    function HasAttack: Boolean;
  end;

  TPickupEffectDef = record
    Kind: TPickupEffectKind;
    // peGiveWeapon only: the 2008 pickup rewired the whole weapon
    WeaponType: Integer;
    FireCooldown: Integer;
    BulletSpeed: Integer;
    BulletGravity: Integer;
  end;

  TSpawnEntry = record
    MonsterId: string;
    Weight: Integer;
  end;

  TBossDef = record
    EndsLevelOnDeath: Boolean;
    SpawnEveryTicks: Integer;
    SpawnScreen: Integer;
    SpawnTable: TArray<TSpawnEntry>;
    // OGG in music\, loops from the rage threshold to the end of the
    // fight ('Сменить музыку' of 2008, moon.dpr 868-869); '' = none
    RageMusic: string;
    // Random pick honoring weights. Raises if the table is empty.
    function PickSpawn: string;
  end;

  // A monster drawn as a spinning disc out of layers (Monsters.Disc)
  // instead of its 'alive' frames; the death frames stay. Rates are per
  // tick, as everywhere in monsters.json. JSON "disc":
  //   {"set": "boss1-disc", "side": 36, "spin": 9, "irisReach": 0.6,
  //    "wearFull": 75}
  TDiscDef = record
    SetName: string; // '' = no disc
    Side: Double; // the layers' square, screen units
    Spin: Double; // degrees a tick, counterclockwise; doubles with the step
    IrisReach: Double; // how far the eye slides toward the hero, units
    // Share of the lives lost when the worn look is complete, 0..1
    WearFull: Double;
    function Enabled: Boolean;
  end;

  TMonsterDef = record
    Id: string;
    LegacyName: string;  // old level-file name; drop after level migration
    DisplayName: TLocalizedText;
    SpriteList: string;  // may be '' until all .mns names are recovered
    Category: TMonsterCategory;
    Dangerous: Boolean;
    AffectedByGravity: Boolean; // platforms, mounts and the boss ignore it
    ExplodesOnDeath: Boolean;   // barrel/tank/platform/mount fragment fans
    Explosion: TExplosionKind;
    Movement: TMovementDef;
    Attack: TAttackDef;
    PickupEffect: TPickupEffectDef;
    Lives: Integer;
    Score: Integer;
    AnimFreq: Double;
    DeathText: TLocalizedText;
    // WAV names in sounds\, all played together on death: most monsters
    // carry one, the tank and the boss pay double (bottle + platform) -
    // the 2008 ladder of moon.dpr 903-925, verbatim
    DeathSounds: TArray<string>;
    Boss: TBossDef;
    Disc: TDiscDef;
  end;

  // Owns all definitions. Create once at startup, free at shutdown.
  TMonsterRegistry = class
  private
    FDefs: TDictionary<string, TMonsterDef>;
    FLegacyIndex: TDictionary<string, string>; // legacyName -> id
    procedure ParseRoot(const ARoot: TJSONObject);
    function ParseMonster(const AObj: TJSONObject;
      const ADefaults: TJSONObject): TMonsterDef;
    procedure ValidateSpawnTables;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromString(const AJsonText: string);

    function Find(const AId: string): TMonsterDef;
    function FindByLegacyName(const ALegacyName: string): TMonsterDef;
    function TryFind(const AId: string; out ADef: TMonsterDef): Boolean;
    function Count: Integer;
    // Snapshot of every definition - the sound bank warms its cache
    // from here at startup instead of keeping a second list of names
    function AllDefs: TArray<TMonsterDef>;
  end;

implementation

resourcestring
  SDefsFileNotFound = 'Monster definitions file not found: %s';
  SDefsParseFailed = 'Monster definitions: invalid JSON';
  SDefsNoMonstersArray = 'Monster definitions: "monsters" array missing';
  SUnknownMonsterId = 'Unknown monster id: %s';
  SUnknownLegacyName = 'Unknown legacy monster name: %s';
  SDuplicateMonsterId = 'Duplicate monster id: %s';
  SBadEnumValue = 'Monster "%s": unknown %s value "%s"';
  SSpawnRefUnknown = 'Boss "%s": spawn table references unknown id "%s"';
  SBadSpawnWeight = 'Boss "%s": spawn weight for "%s" must be positive';
  SEmptySpawnTable = 'PickSpawn called on an empty spawn table';
  SBadDisc = 'Monster "%s": a disc needs a set, a positive side and ' +
    'wearFull above 0, up to 100';

const
  // JSON protocol keys read in more than one place
  KeyMonsters = 'monsters';
  KeyDefaults = 'defaults';
  KeyKind = 'kind';

// ---------------------------------------------------------------------------
// Enum parsing - free functions: they are about strings, not about a registry
// ---------------------------------------------------------------------------

function ParseCategory(const AValue, AMonsterId: string): TMonsterCategory;
begin
  if AValue = 'enemy' then Exit(mcEnemy);
  if AValue = 'pickup' then Exit(mcPickup);
  if AValue = 'prop' then Exit(mcProp);
  if AValue = 'boss' then Exit(mcBoss);
  raise EMonsterDefError.CreateFmt(SBadEnumValue,
    [AMonsterId, 'category', AValue]);
end;

function ParseMovementKind(const AValue, AMonsterId: string): TMovementKind;
begin
  if AValue = 'static' then Exit(mkStatic);
  if AValue = 'patrol' then Exit(mkPatrol);
  if AValue = 'patrolNoEdgeCheck' then Exit(mkPatrolNoEdgeCheck);
  if AValue = 'chaseHero' then Exit(mkChaseHero);
  if AValue = 'bossFly' then Exit(mkBossFly);
  raise EMonsterDefError.CreateFmt(SBadEnumValue,
    [AMonsterId, 'movement.kind', AValue]);
end;

function ParseAttackPattern(const AValue, AMonsterId: string): TAttackPattern;
begin
  if AValue = 'straightSingle' then Exit(apStraightSingle);
  if AValue = 'straightCluster5' then Exit(apStraightCluster5);
  if AValue = 'aimedSingle' then Exit(apAimedSingle);
  if AValue = 'aimedDouble' then Exit(apAimedDouble);
  if AValue = 'rainVolley' then Exit(apRainVolley);
  raise EMonsterDefError.CreateFmt(SBadEnumValue,
    [AMonsterId, 'attack.pattern', AValue]);
end;

function ParsePickupEffect(const AValue, AMonsterId: string): TPickupEffectKind;
begin
  if AValue = 'heal' then Exit(peHeal);
  if AValue = 'giveWeapon' then Exit(peGiveWeapon);
  raise EMonsterDefError.CreateFmt(SBadEnumValue,
    [AMonsterId, 'pickupEffect.kind', AValue]);
end;

function ParseExplosionKind(const AValue, AMonsterId: string): TExplosionKind;
begin
  if AValue = 'barrel' then Exit(ekBarrel);
  if AValue = 'machine' then Exit(ekMachine);
  if AValue = 'boss' then Exit(ekBoss);
  raise EMonsterDefError.CreateFmt(SBadEnumValue,
    [AMonsterId, 'explosion', AValue]);
end;

// ---------------------------------------------------------------------------
// TAttackDef / TBossDef / TDiscDef
// ---------------------------------------------------------------------------

function TAttackDef.HasAttack: Boolean;
begin
  Result := Pattern <> apNone;
end;

function TBossDef.PickSpawn: string;
begin
  if Length(SpawnTable) = 0 then
    raise EMonsterDefError.Create(SEmptySpawnTable);

  var TotalWeight := 0;
  for var Entry in SpawnTable do
    Inc(TotalWeight, Entry.Weight);

  var Roll := Random(TotalWeight);
  for var Entry in SpawnTable do
  begin
    Dec(Roll, Entry.Weight);
    if Roll < 0 then
      Exit(Entry.MonsterId);
  end;

  // Unreachable while weights are positive; keeps the compiler honest.
  Result := SpawnTable[High(SpawnTable)].MonsterId;
end;

function TDiscDef.Enabled: Boolean;
begin
  Result := SetName <> '';
end;

// A broken disc must fail at load time, not draw a speck or a smear
function ParseDisc(const AObj: TJSONObject; const AMonsterId: string): TDiscDef;
begin
  Result.SetName := AObj.GetValue<string>('set', '');
  Result.Side := AObj.GetValue<Double>('side', 0);
  Result.Spin := AObj.GetValue<Double>('spin', 0);
  Result.IrisReach := AObj.GetValue<Double>('irisReach', 0);
  Result.WearFull := AObj.GetValue<Double>('wearFull', 100) / 100;
  if (Result.SetName = '') or (Result.Side <= 0) or
    (Result.WearFull <= 0) or (Result.WearFull > 1) then
    raise EMonsterDefError.CreateFmt(SBadDisc, [AMonsterId]);
end;

// ---------------------------------------------------------------------------
// TMonsterRegistry
// ---------------------------------------------------------------------------

constructor TMonsterRegistry.Create;
begin
  inherited Create;
  FDefs := TDictionary<string, TMonsterDef>.Create;
  FLegacyIndex := TDictionary<string, string>.Create;
end;

destructor TMonsterRegistry.Destroy;
begin
  FLegacyIndex.Free;
  FDefs.Free;
  inherited;
end;

procedure TMonsterRegistry.LoadFromFile(const AFileName: string);
begin
  if not FileExists(AFileName) then
    raise EMonsterDefError.CreateFmt(SDefsFileNotFound, [AFileName]);
  LoadFromString(TFile.ReadAllText(AFileName, TEncoding.UTF8));
end;

procedure TMonsterRegistry.LoadFromString(const AJsonText: string);
var
  Root: TJSONObject;
begin
  Root := TJSONObject.ParseJSONValue(AJsonText) as TJSONObject;
  if Root = nil then
    raise EMonsterDefError.Create(SDefsParseFailed);
  try
    ParseRoot(Root);
  finally
    Root.Free;
  end;
  ValidateSpawnTables;
end;

procedure TMonsterRegistry.ParseRoot(const ARoot: TJSONObject);
var
  MonstersArr: TJSONArray;
begin
  MonstersArr := ARoot.GetValue<TJSONArray>(KeyMonsters, nil);
  if MonstersArr = nil then
    raise EMonsterDefError.Create(SDefsNoMonstersArray);

  var Defaults := ARoot.GetValue<TJSONObject>(KeyDefaults, nil);

  FDefs.Clear;
  FLegacyIndex.Clear;

  for var Item in MonstersArr do
  begin
    var Def := ParseMonster(Item as TJSONObject, Defaults);
    if FDefs.ContainsKey(Def.Id) then
      raise EMonsterDefError.CreateFmt(SDuplicateMonsterId, [Def.Id]);
    FDefs.Add(Def.Id, Def);
    if Def.LegacyName <> '' then
      FLegacyIndex.Add(Def.LegacyName, Def.Id);
  end;
end;

function TMonsterRegistry.ParseMonster(const AObj: TJSONObject;
  const ADefaults: TJSONObject): TMonsterDef;

  // Nested: captures ADefaults to resolve the per-monster / defaults fallback.
  function DefaultBool(const AKey: string; AFallback: Boolean): Boolean;
  begin
    Result := AFallback;
    if Assigned(ADefaults) then
      Result := ADefaults.GetValue<Boolean>(AKey, Result);
  end;

  function DefaultFloat(const AKey: string; AFallback: Double): Double;
  begin
    Result := AFallback;
    if Assigned(ADefaults) then
      Result := ADefaults.GetValue<Double>(AKey, Result);
  end;

begin
  Result := Default(TMonsterDef);

  Result.Id := AObj.GetValue<string>('id');
  Result.LegacyName := AObj.GetValue<string>('legacyName', '');
  Result.DisplayName := ReadLocalizedText(AObj, 'displayName', Result.Id);
  Result.SpriteList := AObj.GetValue<string>('spriteList', '');
  Result.Category := ParseCategory(AObj.GetValue<string>('category'),
    Result.Id);
  Result.Dangerous := AObj.GetValue<Boolean>('dangerous',
    DefaultBool('dangerous', True));
  Result.AffectedByGravity := AObj.GetValue<Boolean>('affectedByGravity',
    True);
  Result.ExplodesOnDeath := AObj.GetValue<Boolean>('explodesOnDeath',
    False);
  var ExplosionId := AObj.GetValue<string>('explosion', '');
  if ExplosionId <> '' then
    Result.Explosion := ParseExplosionKind(ExplosionId, Result.Id);
  Result.AnimFreq := AObj.GetValue<Double>('animFreq',
    DefaultFloat('animFreq', 0.25));
  Result.DeathText := ReadLocalizedText(AObj, 'deathText');

  var Stats := AObj.GetValue<TJSONObject>('stats');
  Result.Lives := Stats.GetValue<Integer>('lives');
  Result.Score := Stats.GetValue<Integer>('score', 1);

  var Movement := AObj.GetValue<TJSONObject>('movement');
  Result.Movement.Kind := ParseMovementKind(
    Movement.GetValue<string>(KeyKind), Result.Id);
  Result.Movement.Speed := Movement.GetValue<Integer>('speed', 0);

  var Attack := AObj.GetValue<TJSONObject>('attack', nil);
  if Assigned(Attack) then
  begin
    Result.Attack.Pattern := ParseAttackPattern(
      Attack.GetValue<string>('pattern'), Result.Id);
    Result.Attack.FireEveryTicks := Attack.GetValue<Integer>('fireEveryTicks');
    Result.Attack.BulletSpeed := Attack.GetValue<Integer>('bulletSpeed');
    Result.Attack.SecondBulletOffsetX :=
      Attack.GetValue<Integer>('secondBulletOffsetX', 0);
    Result.Attack.ClusterOffset := Attack.GetValue<Integer>('clusterOffset', 0);
    Result.Attack.VolleyCount := Attack.GetValue<Integer>('volleyCount', 0);
    Result.Attack.VolleySpacingX :=
      Attack.GetValue<Integer>('volleySpacingX', 0);
    Result.Attack.AngleDeg := Attack.GetValue<Integer>('angleDeg', 0);
  end;

  var Pickup := AObj.GetValue<TJSONObject>('pickupEffect', nil);
  if Assigned(Pickup) then
  begin
    Result.PickupEffect.Kind := ParsePickupEffect(
      Pickup.GetValue<string>(KeyKind), Result.Id);
    Result.PickupEffect.WeaponType := Pickup.GetValue<Integer>('weaponType', 0);
    // Fallbacks 15/10/1 mirror the pistol trio of THero.Create
    // ('TWeapon.create(...,15,10,1)') - one source of truth pending
    // the weapon-enum chapter
    Result.PickupEffect.FireCooldown :=
      Pickup.GetValue<Integer>('fireCooldown', 15);
    Result.PickupEffect.BulletSpeed :=
      Pickup.GetValue<Integer>('bulletSpeed', 10);
    Result.PickupEffect.BulletGravity :=
      Pickup.GetValue<Integer>('bulletGravity', 1);
  end;

  var SoundsArr := AObj.GetValue<TJSONArray>('deathSounds', nil);
  if Assigned(SoundsArr) then
  begin
    SetLength(Result.DeathSounds, SoundsArr.Count);
    for var i := 0 to SoundsArr.Count - 1 do
      Result.DeathSounds[i] := SoundsArr.Items[i].Value;
  end;

  var Boss := AObj.GetValue<TJSONObject>('boss', nil);
  if Assigned(Boss) then
  begin
    Result.Boss.EndsLevelOnDeath :=
      Boss.GetValue<Boolean>('endsLevelOnDeath', False);
    Result.Boss.RageMusic := Boss.GetValue<string>('rageMusic', '');
    Result.Boss.SpawnEveryTicks := Boss.GetValue<Integer>('spawnEveryTicks');
    Result.Boss.SpawnScreen := Boss.GetValue<Integer>('spawnScreen', 0);

    var TableArr := Boss.GetValue<TJSONArray>('spawnTable');
    SetLength(Result.Boss.SpawnTable, TableArr.Count);
    for var i := 0 to TableArr.Count - 1 do
    begin
      var Entry := TableArr.Items[i] as TJSONObject;
      Result.Boss.SpawnTable[i].MonsterId :=
        Entry.GetValue<string>('monsterId');
      Result.Boss.SpawnTable[i].Weight := Entry.GetValue<Integer>('weight', 1);
    end;
  end;

  var Disc := AObj.GetValue<TJSONObject>('disc', nil);
  if Assigned(Disc) then
    Result.Disc := ParseDisc(Disc, Result.Id);
end;

// Spawn tables reference other monsters by id; a broken reference must fail
// at load time, not mid-battle when the boss calls for reinforcements.
// Weights must be positive: a zero would silently vanish from PickSpawn's
// roll, a negative would corrupt it.
procedure TMonsterRegistry.ValidateSpawnTables;
begin
  for var Pair in FDefs do
    for var Entry in Pair.Value.Boss.SpawnTable do
    begin
      if not FDefs.ContainsKey(Entry.MonsterId) then
        raise EMonsterDefError.CreateFmt(SSpawnRefUnknown,
          [Pair.Key, Entry.MonsterId]);
      if Entry.Weight < 1 then
        raise EMonsterDefError.CreateFmt(SBadSpawnWeight,
          [Pair.Key, Entry.MonsterId]);
    end;
end;

function TMonsterRegistry.Find(const AId: string): TMonsterDef;
begin
  if not FDefs.TryGetValue(AId, Result) then
    raise EMonsterDefError.CreateFmt(SUnknownMonsterId, [AId]);
end;

function TMonsterRegistry.FindByLegacyName(
  const ALegacyName: string): TMonsterDef;
var
  Id: string;
begin
  if not FLegacyIndex.TryGetValue(ALegacyName, Id) then
    raise EMonsterDefError.CreateFmt(SUnknownLegacyName, [ALegacyName]);
  Result := FDefs[Id];
end;

function TMonsterRegistry.TryFind(const AId: string;
  out ADef: TMonsterDef): Boolean;
begin
  Result := FDefs.TryGetValue(AId, ADef);
end;

function TMonsterRegistry.Count: Integer;
begin
  Result := FDefs.Count;
end;

function TMonsterRegistry.AllDefs: TArray<TMonsterDef>;
begin
  Result := FDefs.Values.ToArray;
end;

end.
