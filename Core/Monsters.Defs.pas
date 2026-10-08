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
  // (Game.Explosions); ekNone = no look. What the death does to the
  // bodies around is TBlastDef and does not depend on it.
  TExplosionKind = (ekNone, ekBarrel, ekMachine, ekBoss);

  // What the body is made of, by what a bullet does to it: metal throws
  // sparks (Game.Impacts); mtNone = a bullet bursts on it as on a wall
  TMonsterMaterial = (mtNone, mtMetal);

  // What a flying boss does besides his lap (Monsters.Pilot); the
  // level's events switch it.
  // - ptLaps: nothing - the lap and no more.
  // - ptDives: now and then a dive through the arena, cell by cell,
  //   after the hero.
  // - ptRams: a ram at where the hero stands, seen or not; a dive
  //   where the dash has no runway.
  // - ptHunts: no lap and no pondering any more - dives and rams by
  //   turns, one after another.
  TPilotTactics = (ptLaps, ptDives, ptRams, ptHunts);

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
    // The monster id of what a hero gets for dodging a ram
    // (Monsters.Pilot); '' = nothing
    DodgePrize: string;
    // Random pick honoring weights. Raises if the table is empty.
    function PickSpawn: string;
  end;

  // A monster drawn as a spinning disc out of layers (Monsters.Disc)
  // instead of its 'alive' frames; the death frames stay. Rates are per
  // tick, as everywhere in monsters.json. JSON "disc":
  //   {"set": "boss1-disc", "side": 36, "muzzle": 15, "spin": 9,
  //    "irisReach": 0.6, "wearFull": 75, "portAngles": [0, 51, 129]}
  TDiscDef = record
    SetName: string; // '' = no disc
    Side: Double; // the layers' square, screen units
    // How far from the axis the barrels of the art stand - where an
    // aimed shot leaves; 0 keeps the shot where any monster's leaves
    Muzzle: Double;
    Spin: Double; // degrees a tick, counterclockwise; doubles with the step
    IrisReach: Double; // how far the eye slides toward the hero, units
    // Share of the lives lost when the worn look is complete, 0..1
    WearFull: Double;
    // Where the barrels of the art point on the unturned rim, degrees
    // counterclockwise from the right: a volley is one bullet out of
    // each, Muzzle from the axis. None by default.
    PortAngles: TArray<Double>;
    function Enabled: Boolean;
  end;

  // A point of a hull's art: screen units from the top-left corner of the
  // hull
  THullPoint = record
    X, Y: Double;
  end;

  // The wheels a hull stands on (Monsters.Hull): one picture, the 'wheel'
  // of the hull's set, drawn at every axle and turned by the way the body
  // rolls. JSON "wheels":
  //   {"side": 16, "radius": 7.76, "axles": [[11.56, 23.24], [29.06, 23.24]]}
  TWheelsDef = record
    Side: Double; // the picture's square, screen units
    Radius: Double; // from the axle to the floor, units
    Axles: TArray<THullPoint>; // none = no wheels
    function Enabled: Boolean;
  end;

  // A monster drawn as a hull out of layers (Monsters.Hull) instead of its
  // 'alive' frames; the death frames stay. JSON "hull":
  //   {"set": "platform-hull", "width": 40, "height": 20.33, "wearFull": 80,
  //    "eye": [20, 4.9], "smoke": [9.5, 8.1], "sparks": [29.2, 8.7]}
  // and for one that drives: "mirrors": true, "muzzle": [5.5, 5.4],
  // "wheels": {...}
  THullDef = record
    SetName: string; // '' = no hull
    Width, Height: Double; // the hull's size on the screen, units
    // Share of the lives lost when the worn look is complete, 0..1
    WearFull: Double;
    // The middle of the lens
    Eye: THullPoint;
    // Where a wrecked body smokes, and where it sparks and shorts out
    Smoke, Sparks: THullPoint;
    // The art faces left and is mirrored whole while the monster heads
    // right; False = drawn as painted whichever way it heads
    Mirrors: Boolean;
    // The cut of the barrel a straight shot leaves; without one the shot
    // leaves where any monster's does
    HasMuzzle: Boolean;
    Muzzle: THullPoint;
    Wheels: TWheelsDef;
    function Enabled: Boolean;
  end;

  // What a monster's death does to the bodies around it: a wave out of
  // its middle that goes Radius units and takes Lives lives at the heart,
  // fewer with the distance (Game.Blasts); and what a shard of its debris
  // takes off a body it falls on, 0 - nothing. JSON "blast":
  //   {"radius": 80, "lives": 100, "shardLives": 6}
  // Absent for a monster that dies quietly.
  TBlastDef = record
    Radius: Double;
    Lives: Integer;
    ShardLives: Integer;
    function Enabled: Boolean;
  end;

  // The most lives a monster may lose in any run of Ticks ticks, however
  // many bullets land in it. JSON "damageCap" in "stats":
  //   {"lives": 30, "ticks": 33}
  // Absent for a monster with no cap: it loses every life that lands.
  TDamageCap = record
    Lives: Integer;
    Ticks: Integer;
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
    Blast: TBlastDef; // the barrel, the tank, the platform, the mount
    Explosion: TExplosionKind;
    Material: TMonsterMaterial;
    Movement: TMovementDef;
    Attack: TAttackDef;
    PickupEffect: TPickupEffectDef;
    Lives: Integer;
    Score: Integer;
    DamageCap: TDamageCap;
    AnimFreq: Double;
    DeathText: TLocalizedText;
    // WAV names in sounds\, all played together on death: most monsters
    // carry one, the tank and the boss pay double (bottle + platform) -
    // the 2008 ladder of moon.dpr 903-925, verbatim
    DeathSounds: TArray<string>;
    Boss: TBossDef;
    Disc: TDiscDef;
    Hull: THullDef;
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
    procedure ValidateDodgePrizes;
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
  SDodgePrizeUnknown = 'Boss "%s": dodgePrize references unknown id "%s"';
  SEmptySpawnTable = 'PickSpawn called on an empty spawn table';
  SBadDisc = 'Monster "%s": a disc needs a set, a positive side, a ' +
    'muzzle from 0 to half the side and wearFull above 0, up to 100';
  SBadDamageCap = 'Monster "%s": a damageCap needs positive lives and ticks';
  SBadBlast = 'Monster "%s": a blast needs a positive radius and lives, ' +
    'and shardLives of 0 or more';
  SBadPortAngles = 'Monster "%s": the portAngles of a disc are numbers';
  SBadHull = 'Monster "%s": a hull needs a set, a positive width and height ' +
    'and wearFull above 0, up to 100';
  SBadHullPoint = 'Monster "%s": the "%s" of a hull is a point of two numbers';
  SBadWheels = 'Monster "%s": the wheels of a hull need a positive side and ' +
    'radius and at least one axle';
  SBadAxle = 'Monster "%s": an axle of a hull is a point of two numbers';
  SDiscAndHull = 'Monster "%s": a monster is drawn as a disc or as a hull, ' +
    'not both';
  SMuzzleOfNoStraightShot = 'Monster "%s": the muzzle of a hull is for a ' +
    'straight shot, and the monster fires none';

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

function ParseMaterial(const AValue, AMonsterId: string): TMonsterMaterial;
begin
  if AValue = 'metal' then Exit(mtMetal);
  raise EMonsterDefError.CreateFmt(SBadEnumValue,
    [AMonsterId, 'material', AValue]);
end;

// ---------------------------------------------------------------------------
// TAttackDef / TBossDef / TDiscDef / TWheelsDef / THullDef
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

function TWheelsDef.Enabled: Boolean;
begin
  Result := Length(Axles) > 0;
end;

function THullDef.Enabled: Boolean;
begin
  Result := SetName <> '';
end;

function TDamageCap.Enabled: Boolean;
begin
  Result := (Lives > 0) and (Ticks > 0);
end;

function TBlastDef.Enabled: Boolean;
begin
  Result := (Radius > 0) and (Lives > 0);
end;

function ParsePortAngles(const AObj: TJSONObject;
  const AMonsterId: string): TArray<Double>;
begin
  Result := nil;
  var AnglesArr := AObj.GetValue<TJSONArray>('portAngles', nil);
  if AnglesArr = nil then
    Exit;

  SetLength(Result, AnglesArr.Count);
  for var i := 0 to AnglesArr.Count - 1 do
  begin
    if not (AnglesArr.Items[i] is TJSONNumber) then
      raise EMonsterDefError.CreateFmt(SBadPortAngles, [AMonsterId]);
    Result[i] := TJSONNumber(AnglesArr.Items[i]).AsDouble;
  end;
end;

// A broken disc must fail at load time, not draw a speck or a smear
function ParseDisc(const AObj: TJSONObject; const AMonsterId: string): TDiscDef;
begin
  Result.SetName := AObj.GetValue<string>('set', '');
  Result.Side := AObj.GetValue<Double>('side', 0);
  Result.Muzzle := AObj.GetValue<Double>('muzzle', 0);
  Result.Spin := AObj.GetValue<Double>('spin', 0);
  Result.IrisReach := AObj.GetValue<Double>('irisReach', 0);
  Result.WearFull := AObj.GetValue<Double>('wearFull', 100) / 100;
  Result.PortAngles := ParsePortAngles(AObj, AMonsterId);
  if (Result.SetName = '') or (Result.Side <= 0) or
    (Result.Muzzle < 0) or (Result.Muzzle > Result.Side / 2) or
    (Result.WearFull <= 0) or (Result.WearFull > 1) then
    raise EMonsterDefError.CreateFmt(SBadDisc, [AMonsterId]);
end;

function IsNumberPair(const AValue: TJSONArray): Boolean;
begin
  Result := (AValue <> nil) and (AValue.Count = 2) and
    (AValue.Items[0] is TJSONNumber) and (AValue.Items[1] is TJSONNumber);
end;

function IsBrokenHull(const AHull: THullDef): Boolean;
begin
  Result := (AHull.SetName = '') or (AHull.Width <= 0) or (AHull.Height <= 0) or
    (AHull.WearFull <= 0) or (AHull.WearFull > 1);
end;

function PointOfPair(const APair: TJSONArray): THullPoint;
begin
  Result.X := TJSONNumber(APair.Items[0]).AsDouble;
  Result.Y := TJSONNumber(APair.Items[1]).AsDouble;
end;

function ParseHullPoint(const AObj: TJSONObject;
  const AKey, AMonsterId: string): THullPoint;
begin
  var PairArr := AObj.GetValue<TJSONArray>(AKey, nil);
  if not IsNumberPair(PairArr) then
    raise EMonsterDefError.CreateFmt(SBadHullPoint, [AMonsterId, AKey]);
  Result := PointOfPair(PairArr);
end;

// Wheels that would not show, or would never turn, must fail at load time
function ParseWheels(const AObj: TJSONObject;
  const AMonsterId: string): TWheelsDef;
begin
  Result.Side := AObj.GetValue<Double>('side', 0);
  Result.Radius := AObj.GetValue<Double>('radius', 0);
  var AxlesArr := AObj.GetValue<TJSONArray>('axles', nil);
  if (Result.Side <= 0) or (Result.Radius <= 0) or (AxlesArr = nil) or
    (AxlesArr.Count = 0) then
    raise EMonsterDefError.CreateFmt(SBadWheels, [AMonsterId]);

  SetLength(Result.Axles, AxlesArr.Count);
  for var i := 0 to AxlesArr.Count - 1 do
  begin
    var PairArr: TJSONArray := nil;
    if AxlesArr.Items[i] is TJSONArray then
      PairArr := TJSONArray(AxlesArr.Items[i]);
    if not IsNumberPair(PairArr) then
      raise EMonsterDefError.CreateFmt(SBadAxle, [AMonsterId]);
    Result.Axles[i] := PointOfPair(PairArr);
  end;
end;

// A broken hull must fail at load time, not draw a speck or a smear
function ParseHull(const AObj: TJSONObject; const AMonsterId: string): THullDef;
begin
  Result.SetName := AObj.GetValue<string>('set', '');
  Result.Width := AObj.GetValue<Double>('width', 0);
  Result.Height := AObj.GetValue<Double>('height', 0);
  Result.WearFull := AObj.GetValue<Double>('wearFull', 100) / 100;
  if IsBrokenHull(Result) then
    raise EMonsterDefError.CreateFmt(SBadHull, [AMonsterId]);
  Result.Eye := ParseHullPoint(AObj, 'eye', AMonsterId);
  Result.Smoke := ParseHullPoint(AObj, 'smoke', AMonsterId);
  Result.Sparks := ParseHullPoint(AObj, 'sparks', AMonsterId);
  Result.Mirrors := AObj.GetValue<Boolean>('mirrors', False);
  Result.Muzzle := Default(THullPoint);
  Result.HasMuzzle := AObj.GetValue('muzzle') <> nil;
  if Result.HasMuzzle then
    Result.Muzzle := ParseHullPoint(AObj, 'muzzle', AMonsterId);
  Result.Wheels := Default(TWheelsDef);
  var Wheels := AObj.GetValue<TJSONObject>('wheels', nil);
  if Assigned(Wheels) then
    Result.Wheels := ParseWheels(Wheels, AMonsterId);
end;

// A blast that reaches nothing must fail at load time, not die quietly
function ParseBlast(const AObj: TJSONObject;
  const AMonsterId: string): TBlastDef;
begin
  Result.Radius := AObj.GetValue<Double>('radius', 0);
  Result.Lives := AObj.GetValue<Integer>('lives', 0);
  Result.ShardLives := AObj.GetValue<Integer>('shardLives', 0);
  if not Result.Enabled or (Result.ShardLives < 0) then
    raise EMonsterDefError.CreateFmt(SBadBlast, [AMonsterId]);
end;

// A cap that caps nothing must fail at load time, not pass for a safeguard
function ParseDamageCap(const AObj: TJSONObject;
  const AMonsterId: string): TDamageCap;
begin
  Result.Lives := AObj.GetValue<Integer>('lives', 0);
  Result.Ticks := AObj.GetValue<Integer>('ticks', 0);
  if not Result.Enabled then
    raise EMonsterDefError.CreateFmt(SBadDamageCap, [AMonsterId]);
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
  ValidateDodgePrizes;
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
  var Blast := AObj.GetValue<TJSONObject>('blast', nil);
  if Assigned(Blast) then
    Result.Blast := ParseBlast(Blast, Result.Id);
  var ExplosionId := AObj.GetValue<string>('explosion', '');
  if ExplosionId <> '' then
    Result.Explosion := ParseExplosionKind(ExplosionId, Result.Id);
  var MaterialId := AObj.GetValue<string>('material', '');
  if MaterialId <> '' then
    Result.Material := ParseMaterial(MaterialId, Result.Id);
  Result.AnimFreq := AObj.GetValue<Double>('animFreq',
    DefaultFloat('animFreq', 0.25));
  Result.DeathText := ReadLocalizedText(AObj, 'deathText');

  var Stats := AObj.GetValue<TJSONObject>('stats');
  Result.Lives := Stats.GetValue<Integer>('lives');
  Result.Score := Stats.GetValue<Integer>('score', 1);
  var Cap := Stats.GetValue<TJSONObject>('damageCap', nil);
  if Assigned(Cap) then
    Result.DamageCap := ParseDamageCap(Cap, Result.Id);

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
    Result.Boss.DodgePrize := Boss.GetValue<string>('dodgePrize', '');
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

  var Hull := AObj.GetValue<TJSONObject>('hull', nil);
  if Assigned(Hull) then
    Result.Hull := ParseHull(Hull, Result.Id);
  if Result.Disc.Enabled and Result.Hull.Enabled then
    raise EMonsterDefError.CreateFmt(SDiscAndHull, [Result.Id]);
  var FiresStraight := Result.Attack.Pattern in
    [apStraightSingle, apStraightCluster5];
  if Result.Hull.HasMuzzle and not FiresStraight then
    raise EMonsterDefError.CreateFmt(SMuzzleOfNoStraightShot, [Result.Id]);
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

// As a spawn table's reference: fails at load time, not at the first
// dodged ram
procedure TMonsterRegistry.ValidateDodgePrizes;
begin
  for var Pair in FDefs do
  begin
    var Prize := Pair.Value.Boss.DodgePrize;
    if (Prize <> '') and not FDefs.ContainsKey(Prize) then
      raise EMonsterDefError.CreateFmt(SDodgePrizeUnknown, [Pair.Key, Prize]);
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
