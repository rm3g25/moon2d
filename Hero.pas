{
  Hero - the player, ported line-for-line from the release hero.pas.

  The game thinks in 512x384 units (moon.dpr:1839 SetMaxC(512,384));
  a grid cell is 32 units, the hero is exactly one cell. All original
  constants (bound=8, step=2, jump start 8, gravity step/14, landing
  snap y+16) transfer unchanged.

  Facing follows the MOUSE, not the walk direction: MouseX > x+16
  mirrors the sprite, so retreating fire produces the original's
  trademark moonwalk. Walking away from the cursor plays the walk
  cycle backwards (frame 9-Round(CurrentSprite)) - kept verbatim.

  The arm and the gun are separate sprites rotated toward the cursor
  (weapon.pas TWeapon.Put); angle math is a straight translation of
  SetWeaponAngle. SDL rotates clockwise where OpenGL rotated counter-
  clockwise: AngleSign compensates - if the arm mirrors the cursor
  vertically on the first run, flip that constant.

  Skin file (heroes/default.txt): 24 frames - 1..8 walk, 9..16 death,
  17..24 ice form (FORM=1 adds +16 to every frame index).

  Moon 2D remake. Requires Delphi 12+.
}
unit Hero;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, System.Classes, System.Math,
  Sdl2.Core, Render.Sprites, Levels.Defs, Bullets;

const
  GameWidth = 512;  // logic units, = 16 cells
  GameHeight = 384; // logic units, = 12 cells
  HeroSize = 32;

type
  THeroAction = (haStand, haWalkLeft, haWalkRight, haJump, haJumpLeft,
    haJumpRight, haFall, haFallLeft, haFallRight);

  THeroCommand = (hcGoLeft, hcGoRight, hcStopLeft, hcStopRight,
    hcJump, hcStopJump);

  THeroForm = (hfNormal, hfIce);

  // Pending side intent when the way is blocked, executed once the
  // barrier clears ('ExtraInstruction' of the original).
  TPendingSide = (psNone, psLeft, psRight);

  THero = class
  private
    FLevel: TLevel;
    // Weapon-4 muzzle geometry (see the comment in Create); fields so
    // the DEBUGKEYS NumPad tuner can move them live
    FMinigunBaseX: Double;
    FMinigunBaseY: Double;
    FMinigunMuzzleLen: Double;
    FCache: TSpriteCache;   // rooted at heroes\
    FWeaponCache: TSpriteCache; // rooted at weapon\
    FFrames: array [1..24] of PSdlTexture;
    FWeaponFrames: array [1..7] of PSdlTexture;

    FAction: THeroAction;
    FDirection: Boolean; // walk direction, True = right ('direction' of 2008)
    FPending: TPendingSide;
    FForm: THeroForm;
    FX, FY: Double;         // game units; Y is the FEET line, as in 2008
    FScreen: Integer;       // 1-based
    FCurrentSprite: Double; // walk frame 1..8, advances by 0.5 per tick
    FAcceleration: Double;
    FMouseX, FMouseY: Integer; // game units
    FCrossDX, FCrossDY: Integer; // crosshair calibration offsets
    FWeaponAngle: Double;
    FWeaponType: Integer;   // 0..4 -> gun sprite index typ+3
    // Weapon state, verbatim TWeapon: pistol = create(...,15,10,1)
    FBullets: TBurst;
    FFireCooldown: Integer;   // 'Freq': ticks between shots
    FBulletSpeed: Integer;
    FBulletGravity: Integer;  // 'influence'
    FTimeOfFire: Integer;
    FMinigunUpDown: Boolean;
    FDead: Boolean;
    FCorpseSettled: Boolean; // gravity releases the body exactly once
    FDeathFrame: Double;    // 9 -> 16
    FDeathFacingRight: Boolean;

    procedure SetWeaponAngle;
    // --- verbatim ports of the 2008 collision oracles ---
    function Solid(ACol, ARow: Integer): Boolean; // 1-based, like WhatTheSprite
    // Snaps the feet to the top of the cell below - shared by the fall
    // landings in Tick and by SetY's on-ground teleports
    procedure LandExactly;
    // Is the row just BELOW the feet line solid at the foot columns?
    // The landing question - see SettleOnGround for why CanIGoDown
    // cannot answer it.
    function GroundUnderFeet: Boolean;
    function CellOfX(APixel: Integer): Integer;   // PixelToSpriteX
    function CellOfY(APixel: Integer): Integer;   // PixelToSpriteY
    // A 32-unit span can straddle two grid cells; these return both
    // edges (equal when the span is cell-aligned). BelongToX/YSprite of 2008.
    procedure CellsOfX(APixel: Integer; out ALeftCell, ARightCell: Integer);
    procedure CellsOfY(APixel: Integer; out ATopCell, ABottomCell: Integer);
    function CanIGoLeft: Boolean;
    function CanIGoRight: Boolean;
    // Side-effect-free wall probes for external shoves: the wall half of
    // CanIGoLeft/CanIGoRight geometry, WITHOUT the ledge check that
    // starts a fall and WITHOUT the FY<32 top-of-screen pass. A shove
    // must never end inside a wall - unlike a jump arc, which that pass
    // exists to serve.
    function WallBlocksLeft: Boolean;
    function WallBlocksRight: Boolean;
    function CanIGoUp: Boolean;
    function CanIGoDown: Boolean;
    function CanIFlyLeft: Boolean;
    function CanIFlyRight: Boolean;
    procedure DrawWeapon(const ASprites: TSpriteRenderer;
      AMouseRight: Boolean);
    function FacingMouseRight: Boolean;
    // --- shared formulas of OurHero.Timer, extracted verbatim ---
    procedure AdvanceWalkFrame;
    procedure FallOneTick;
    procedure RiseOneTick(ANextFall: THeroAction);
    procedure BumpCeiling(ANextFall: THeroAction);
    procedure BeginJumpBoost;
  public
    constructor Create(const ARenderer: PSdlRenderer; const ALevel: TLevel;
      const ASkinFile, AWeaponFile: string);
    destructor Destroy; override;

    procedure Command(ACmd: THeroCommand);
    // One logic tick, verbatim OurHero.Timer (33 Hz - the REAL rate
    // of the 2008 20 ms timer, see PORTING-NOTES)
    procedure Tick;
    // Verbatim TWeapon.Fire: fires only when the cooldown has fully
    // elapsed; patterns per weapon type (0 pistol, 1 shotgun x5,
    // 2 grenade cloud x22, 3 chain x3, 4 minigun with alternating
    // side shots). Poll while LMB is held, like everything in 2008.
    // True when a shot actually left the barrel - the caller barks the
    // weapon sound then; held triggers on cooldown fire nothing
    function Fire: Boolean;
    procedure Draw(const ASprites: TSpriteRenderer);
    // AFrame 1..4: normal / green (healthy target) / yellow / red -
    // the smart cursor of 2008 (VidKursora thresholds 2/3 and 1/3).
    procedure DrawCrosshair(const ASprites: TSpriteRenderer;
      AFrame: Integer);
    procedure SetMouse(AGameX, AGameY: Integer);
    procedure PlaceAtCell(ACellX, ACellY: Integer);
    // Screen transition: X changes, Y and momentum survive the border.
    procedure SetScreenX(AX: Double);
    // Pushed by the world (monster contact): moves unit by unit and
    // stops at the first wall - the hero cannot be shoved into geometry.
    procedure ShoveX(ADeltaX: Integer);
    procedure SetY(AY: Double);
    // DEBUGKEYS live tuner for the weapon-4 muzzle (NumPad, values in
    // the window caption - same workflow as the crosshair calibration)
    procedure NudgeMinigun(ADeltaX, ADeltaY, ADeltaLen: Integer);
    // Decides stand-vs-fall after a teleport. Call it once more after
    // a heroX relocation: paired heroY+heroX triggers pass through an
    // intermediate position where any ground verdict is meaningless.
    procedure SettleOnGround;
    procedure ApplyWeaponPickup(AType, ACooldown, ASpeed, AGravity: Integer);
    procedure Kill;   // death animation starts; Tick keeps advancing it
    procedure Revive; // full reset for a level restart

    property X: Double read FX;
    property Y: Double read FY;
    property Screen: Integer read FScreen write FScreen;
    property Action: THeroAction read FAction;
    property Bullets: TBurst read FBullets;
    property MinigunBaseX: Double read FMinigunBaseX;
    property MinigunBaseY: Double read FMinigunBaseY;
    property MinigunMuzzleLen: Double read FMinigunMuzzleLen;
    property CrossDX: Integer read FCrossDX write FCrossDX;
    property CrossDY: Integer read FCrossDY write FCrossDY;
    property WeaponType: Integer read FWeaponType;
    property Dead: Boolean read FDead;
    property HeroForm: THeroForm read FForm write FForm;
  end;

implementation

// Delphi Round is banker's: Round(2.5)=2 but Round(3.5)=4, which made
// the walk cycle stutter (frames shown 1 or 3 ticks apart). Half-up
// gives every frame exactly two ticks - the one deliberate improvement
// over 2008, which stuttered the same way.
function RoundHalfUp(AValue: Double): Integer;
begin
  Result := Trunc(AValue + 0.5);
end;

resourcestring
  SSkinNotFound = 'Hero skin list not found: %s';
  SSpriteListTooShort = 'Sprite list "%s": expected %d lines, got %d';
  SWeaponListNotFound = 'Weapon sprite list not found: %s';

const
  // Original constants, names preserved for archaeology
  JumpDel = 6;       // jump deceleration divisor (bigger = floatier)
  StartUscor = 4;    // initial jump boost multiplier
  Removal = 3;       // sprite draw offset down
  Shift = -6;        // weapon anchor offset Y
  ShiftX = -4;       // weapon anchor offset X
  Bound = 8;         // transparent margin of the hero sprite
  Step = 2.0;        // 'Shag'
  WalkFrameAdvance = 0.5; // 5 * HeroFreq(0.1) per tick
  Gravity = Step / 14;     // per-tick fall acceleration, verbatim
  CeilingBumpDivisor = 6;  // head bump keeps 1/6 of the boost (a bare 6
                           // in 2008 - same digit as JumpDel, presumed
                           // coincidence, kept separate)
  IceJumpBoost = 1.25;     // the 'прыжок +25%' perk of the ice form
  DeathFrameAdvance = 0.6; // frames 9 -> 16 in ~12 ticks

  // SDL rotates clockwise, the OpenGL original counter-clockwise.
  // Confirmed on screen: the sign must flip. Barrel offsets keep the
  // ORIGINAL angle sign - they are pixel-space math, untouched by this.
  AngleSign = -1;

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

// Reads a sprite-list file (one texture name per line, trailing blanks
// tolerated) and hands each texture to AStore by 1-based index.
procedure LoadSpriteList(const AFileName: string; ACount: Integer;
  const ACache: TSpriteCache; const AStore: TProc<Integer, PSdlTexture>);
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);
    while (Lines.Count > 0) and (Trim(Lines[Lines.Count - 1]) = '') do
      Lines.Delete(Lines.Count - 1);
    if Lines.Count < ACount then
      raise ESpriteError.CreateFmt(SSpriteListTooShort,
        [AFileName, ACount, Lines.Count]);
    for var i := 1 to ACount do
      AStore(i, ACache.Get(Trim(Lines[i - 1])));
  finally
    Lines.Free;
  end;
end;

constructor THero.Create(const ARenderer: PSdlRenderer;
  const ALevel: TLevel; const ASkinFile, AWeaponFile: string);
begin
  inherited Create;
  FLevel := ALevel;
  FCache := TSpriteCache.Create(ARenderer, 'heroes');
  FWeaponCache := TSpriteCache.Create(ARenderer, 'weapon');

  FAction := haStand;
  FDirection := True; // hero looks forward at birth, as in 2008
  FForm := hfNormal;
  FScreen := 1;
  FCurrentSprite := 1;
  FDeathFrame := 9;
  FWeaponType := 0;
  // Weapon-4 muzzle: the verbatim spawn (x+16, y+8) sits at the grip -
  // visibly wrong for the minigun's wide fan. Values tuned live via
  // the NumPad tuner and confirmed on screen (review round six): only
  // X moved from the eyeballed 20, Y stayed the verbatim barrel line.
  FMinigunBaseX := 6;
  FMinigunBaseY := 8;
  FMinigunMuzzleLen := 26;
  FCrossDX := 9;  // FINAL: measured by the player against the live
  FCrossDY := 10; // cursor (NumPad tuner, 2026-07-12). Do not theorize.
  FBullets := TBurst.Create(ARenderer, 'bullet');
  FFireCooldown := 15;  // pistol: TWeapon.create('default.txt','bullet',15,10,1)
  FBulletSpeed := 10;
  FBulletGravity := 1;
  PlaceAtCell(1, 11); // original start: SpriteToPixelX(1), SpriteToPixelY(11)

  if not FileExists(ASkinFile) then
    raise ESpriteError.CreateFmt(SSkinNotFound, [ASkinFile]);
  LoadSpriteList(ASkinFile, Length(FFrames), FCache,
    procedure(AIndex: Integer; ATexture: PSdlTexture)
    begin
      FFrames[AIndex] := ATexture;
    end);

  if not FileExists(AWeaponFile) then
    raise ESpriteError.CreateFmt(SWeaponListNotFound, [AWeaponFile]);
  LoadSpriteList(AWeaponFile, Length(FWeaponFrames), FWeaponCache,
    procedure(AIndex: Integer; ATexture: PSdlTexture)
    begin
      FWeaponFrames[AIndex] := ATexture;
    end);
end;

destructor THero.Destroy;
begin
  FBullets.Free;
  FWeaponCache.Free;
  FCache.Free;
  inherited;
end;

procedure THero.PlaceAtCell(ACellX, ACellY: Integer);
begin
  FX := (ACellX - 1) * HeroSize; // SpriteToPixelX
  FY := ACellY * HeroSize;       // SpriteToPixelY: feet line
end;

procedure THero.DrawCrosshair(const ASprites: TSpriteRenderer;
  AFrame: Integer);
const
  FrameFiles: array [1..4] of string =
    ('target.bmp', 'target1.bmp', 'target2.bmp', 'target3.bmp');
begin
  // The art sits off-center inside its bitmap; the offsets are baked in
  // Create (measured live via the NumPad tuner, 2026-07-12). The tuner
  // stays parked on the corner cluster for the day a monitor disagrees.
  ASprites.DrawRotated(
    FWeaponCache.Get(FrameFiles[EnsureRange(AFrame, 1, 4)]),
    FMouseX + FCrossDX, FMouseY + FCrossDY, 0, False);
end;

procedure THero.ApplyWeaponPickup(AType, ACooldown, ASpeed,
  AGravity: Integer);
begin
  FWeaponType := AType;
  FFireCooldown := ACooldown;
  FBulletSpeed := ASpeed;
  FBulletGravity := AGravity;
  FTimeOfFire := 1;
end;

procedure THero.Kill;
begin
  FDead := True;
  FDeathFrame := 9;
  // Frozen at the moment of death: the corpse must not track the cursor
  FDeathFacingRight := FacingMouseRight;
end;

procedure THero.Revive;
begin
  FDead := False;
  FCorpseSettled := False;
  FDeathFrame := 9;
  FAction := haStand;
  FAcceleration := 0;
end;

procedure THero.SetScreenX(AX: Double);
begin
  FX := AX;
end;

function THero.WallBlocksLeft: Boolean;
var
  LeftCell, RightCell: Integer;
begin
  if FX < 2 then
    Exit(True);
  // Same probe point as the wall check inside CanIGoLeft (hero geometry:
  // leading edge FX+Bound, body row above the feet line)
  CellsOfX(Round(FX + Bound), LeftCell, RightCell);
  Result := Solid(LeftCell, CellOfY(Round(FY)) - 1);
end;

function THero.WallBlocksRight: Boolean;
var
  LeftCell, RightCell: Integer;
begin
  // Same probe point as the wall check inside CanIGoRight
  CellsOfX(Round(FX) - Bound, LeftCell, RightCell);
  Result := Solid(RightCell, CellOfY(Round(FY)) - 1);
end;

procedure THero.ShoveX(ADeltaX: Integer);
begin
  // Unit-by-unit with a probe at every position: a single pre-check
  // cannot guarantee a multi-unit displacement lands in free space
  // (bugfix queue item 12 - monster contact shoved the hero into walls)
  var StepDir := Sign(ADeltaX);
  for var i := 1 to Abs(ADeltaX) do
  begin
    if (StepDir < 0) and WallBlocksLeft then
      Exit;
    if (StepDir > 0) and WallBlocksRight then
      Exit;
    FX := FX + StepDir;
  end;
end;

procedure THero.NudgeMinigun(ADeltaX, ADeltaY, ADeltaLen: Integer);
begin
  FMinigunBaseX := FMinigunBaseX + ADeltaX;
  FMinigunBaseY := FMinigunBaseY + ADeltaY;
  FMinigunMuzzleLen := FMinigunMuzzleLen + ADeltaLen;
end;

procedure THero.SetY(AY: Double);
begin
  FY := AY;
  FAcceleration := 0;
  SettleOnGround;
end;

// The 2008 floor has TWO resting conventions and the teleport must
// speak both. CanIGoDown probes the row at FY-3: on screens where the
// feet rest on the TOP edge of a solid row it reports 'air' at the
// exact resting line, so a flush teleport sank ~3 units over several
// ticks and snapped back - the review 'stumble' (simulated on level2
// data: 64->67->snap 64). GroundUnderFeet probes the row just BELOW
// the feet and covers that case; CanIGoDown=False covers the other
// (feet on the BOTTOM edge of a solid row - screen 7 walls). Either
// verdict grounds the hero; only a genuinely airborne target falls
// (deviation 5 holds).
procedure THero.SettleOnGround;
begin
  if GroundUnderFeet or not CanIGoDown then
  begin
    LandExactly;
    FAction := haStand;
  end
  else
    FAction := haFall;
end;

function THero.GroundUnderFeet: Boolean;
var
  LeftCell, RightCell: Integer;
begin
  // Same foot columns as CanIGoDown, one row lower - the row a landing
  // snap (LandExactly) would rest the feet upon
  CellsOfX(Round(FX) + Bound + 8, LeftCell, RightCell);
  if Solid(LeftCell, CellOfY(Round(FY) + 1)) then
    Exit(True);

  if CellOfX(Round(FX)) <> 16 then
  begin
    CellsOfX(Round(FX) - Bound - 8, LeftCell, RightCell);
    if Solid(RightCell, CellOfY(Round(FY) + 1)) then
      Exit(True);
  end;

  Result := False;
end;

procedure THero.SetMouse(AGameX, AGameY: Integer);
begin
  FMouseX := AGameX;
  FMouseY := AGameY;
end;

// ---------------------------------------------------------------------------
// Coordinate oracles - verbatim from coordinates.pas, 512x384 fixed
// ---------------------------------------------------------------------------

function THero.CellOfX(APixel: Integer): Integer;
begin
  Result := Trunc(16 * APixel / GameWidth + 1);
end;

function THero.CellOfY(APixel: Integer): Integer;
begin
  Result := Trunc(12 * APixel / GameHeight + 1);
end;

procedure THero.CellsOfX(APixel: Integer; out ALeftCell, ARightCell: Integer);
begin
  ALeftCell := CellOfX(APixel);
  if APixel mod HeroSize = 0 then
    ARightCell := ALeftCell
  else
    ARightCell := ALeftCell + 1;
end;

procedure THero.CellsOfY(APixel: Integer; out ATopCell, ABottomCell: Integer);
begin
  ATopCell := CellOfY(APixel) - 1;
  if APixel mod HeroSize = 0 then
    ABottomCell := ATopCell
  else
    ABottomCell := CellOfY(APixel);
end;

function THero.Solid(ACol, ARow: Integer): Boolean;
begin
  // WhatTheSprite took 1-based cell coordinates; SolidAt is 0-based
  // and treats off-grid as air, which the original did by accident
  // (its lookup loop simply never matched).
  Result := FLevel.SolidAt(FScreen, ACol - 1, ARow - 1);
end;

// ---------------------------------------------------------------------------
// Collision oracles - verbatim from hero.pas
// ---------------------------------------------------------------------------

function THero.CanIGoLeft: Boolean;
var
  LeftCell, RightCell: Integer;
begin
  Result := True;
  if FX < 2 then
    Result := False;

  CellsOfX(Round(FX + Bound), LeftCell, RightCell);
  if Solid(LeftCell, CellOfY(Round(FY)) - 1) then
    Result := False;

  // Edge-of-platform check: nothing under either side => start falling
  CellsOfX(Round(FX) + 2 * Bound, LeftCell, RightCell);
  var NothingAhead := not Solid(LeftCell, CellOfY(Round(FY)));
  CellsOfX(Round(FX) - 2 * Bound, LeftCell, RightCell);
  var NothingBehind := not Solid(RightCell, CellOfY(Round(FY)));
  if NothingAhead and NothingBehind and Result then
  begin
    FAction := haFallLeft;
    FAcceleration := 1;
  end;

  if FY < 32 then
    Result := True;
end;

function THero.CanIGoRight: Boolean;
var
  LeftCell, RightCell: Integer;
begin
  Result := True;

  CellsOfX(Round(FX) - Bound, LeftCell, RightCell);
  if Solid(RightCell, CellOfY(Round(FY)) - 1) then
    Result := False;

  CellsOfX(Round(FX) + 2 * Bound, LeftCell, RightCell);
  var NothingAhead := not Solid(LeftCell, CellOfY(Round(FY)));
  CellsOfX(Round(FX) - 2 * Bound, LeftCell, RightCell);
  var NothingBehind := not Solid(RightCell, CellOfY(Round(FY)));
  if NothingAhead and NothingBehind and Result then
  begin
    FAction := haFallRight;
    FAcceleration := 1;
  end;

  if FY < 32 then
    Result := True;
end;

function THero.CanIGoUp: Boolean;
var
  LeftCell, RightCell: Integer;
begin
  Result := True;

  CellsOfX(Round(FX) + Bound + 8, LeftCell, RightCell);
  if Solid(LeftCell, CellOfY(Round(FY) - 4) - 1) then
    Result := False;

  if CellOfX(Round(FX)) <> 16 then
  begin
    CellsOfX(Round(FX) - Bound - 8, LeftCell, RightCell);
    if Solid(RightCell, CellOfY(Round(FY) - 4) - 1) then
      Result := False;
  end;

  if FY < 60 then
    Result := True;
end;

function THero.CanIGoDown: Boolean;
var
  LeftCell, RightCell: Integer;
begin
  Result := True;

  CellsOfX(Round(FX) + Bound + 8, LeftCell, RightCell);
  if Solid(LeftCell, CellOfY(Round(FY) - 3)) then
    Result := False;

  if CellOfX(Round(FX)) <> 16 then
  begin
    CellsOfX(Round(FX) - Bound - 8, LeftCell, RightCell);
    if Solid(RightCell, CellOfY(Round(FY) - 3)) then
      Result := False;
  end;

  // The famous hardcode: below the screen you always fall (original kept
  // y>384 from the fixed game-unit era; with SetMaxC(512,384) it's exact).
  if (FY < 4) or (FY > GameHeight) then
    Result := True;
end;

function THero.CanIFlyLeft: Boolean;
var
  TopCell, BottomCell: Integer;
begin
  Result := True;
  if FX < 2 then
  begin
    Result := False;
    FX := 2;
  end;

  CellsOfY(Round(FY), TopCell, BottomCell);
  if Solid(CellOfX(Round(FX)), TopCell) then
    Result := False;
  if Solid(CellOfX(Round(FX)), BottomCell) then
    Result := False;

  if FY < 0 then
    Result := True;
end;

function THero.CanIFlyRight: Boolean;
var
  TopCell, BottomCell: Integer;
begin
  Result := True;

  CellsOfY(Round(FY), TopCell, BottomCell);
  if Solid(CellOfX(Round(FX)) + 1, TopCell) then
    Result := False;
  if Solid(CellOfX(Round(FX)) + 1, BottomCell) then
    Result := False;

  if FY < 0 then
    Result := True;
end;

// ---------------------------------------------------------------------------
// Commands - verbatim state transitions of OurHero.command
// ---------------------------------------------------------------------------

procedure THero.Command(ACmd: THeroCommand);
begin
  if FDead then
    Exit;

  if FAction = haStand then
  begin
    if (ACmd = hcGoLeft) or (FPending = psLeft) then
    begin
      FDirection := False;
      FAction := haWalkLeft;
      FPending := psNone;
    end;
    if (ACmd = hcGoRight) or (FPending = psRight) then
    begin
      FDirection := True;
      FAction := haWalkRight;
      FPending := psNone;
    end;
    if ACmd = hcJump then
    begin
      FAction := haJump;
      BeginJumpBoost;
    end;
    Exit;
  end;

  if FAction = haJump then
  begin
    if (ACmd = hcStopJump) and (FAcceleration > Step) then
      FAcceleration := Step;
    if ((ACmd = hcGoLeft) or (FPending = psLeft)) and CanIFlyLeft then
    begin
      FDirection := False;
      FAction := haJumpLeft;
      FPending := psNone;
    end;
    if ((ACmd = hcGoRight) or (FPending = psRight)) and CanIFlyRight then
    begin
      FDirection := True;
      FAction := haJumpRight;
      FPending := psNone;
    end;
    Exit;
  end;

  if FAction = haFall then
  begin
    if ((ACmd = hcGoLeft) or (FPending = psLeft)) and CanIFlyLeft then
    begin
      FDirection := False;
      FAction := haFallLeft;
      FPending := psNone;
    end;
    if ((ACmd = hcGoRight) or (FPending = psRight)) and CanIFlyRight then
    begin
      FDirection := True;
      FAction := haFallRight;
      FPending := psNone;
    end;
    Exit;
  end;

  if FAction in [haJumpLeft, haJumpRight] then
  begin
    if (FAction = haJumpLeft) and (ACmd = hcStopLeft) then
      FAction := haJump;
    if (FAction = haJumpRight) and (ACmd = hcStopRight) then
      FAction := haJump;
    if (ACmd = hcStopJump) and (FAcceleration > Step) then
      FAcceleration := Step;
    if (ACmd = hcGoLeft) and CanIFlyLeft then
    begin
      FDirection := False;
      FAction := haJumpLeft;
    end;
    if (ACmd = hcGoRight) and CanIFlyRight then
    begin
      FDirection := True;
      FAction := haJumpRight;
    end;
    Exit;
  end;

  if FAction in [haFallLeft, haFallRight] then
  begin
    if (FAction = haFallLeft) and (ACmd = hcStopLeft) then
      FAction := haFall;
    if (FAction = haFallRight) and (ACmd = hcStopRight) then
      FAction := haFall;
    if (ACmd = hcGoLeft) and CanIFlyLeft then
    begin
      FDirection := False;
      FAction := haFallLeft;
    end;
    if (ACmd = hcGoRight) and CanIFlyRight then
    begin
      FDirection := True;
      FAction := haFallRight;
    end;
    Exit;
  end;

  if FAction in [haWalkLeft, haWalkRight] then
  begin
    if ACmd = hcJump then
    begin
      if FAction = haWalkLeft then
        FAction := haJumpLeft
      else
        FAction := haJumpRight;
      BeginJumpBoost;
      Exit;
    end;
    if (FAction = haWalkLeft) and (ACmd = hcStopLeft) then
      FAction := haStand;
    if (FAction = haWalkRight) and (ACmd = hcStopRight) then
      FAction := haStand;
    if ACmd = hcGoLeft then
    begin
      FDirection := False;
      FAction := haWalkLeft;
    end;
    if ACmd = hcGoRight then
    begin
      FDirection := True;
      FAction := haWalkRight;
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Tick - verbatim OurHero.Timer (33 Hz, the real 2008 rate)
// ---------------------------------------------------------------------------

// Promoted from a Tick-nested subprogram once SetY became the second
// caller: it never captured Tick's locals anyway.
procedure THero.LandExactly;
var
  TopCell, BottomCell: Integer;
begin
  // "So the hero lands EXACTLY on the ground, not somewhere above :)))"
  FY := FY + 16;
  CellsOfY(Round(FY), TopCell, BottomCell);
  FY := TopCell * HeroSize; // SpriteToPixelY(cell)
end;

function THero.FacingMouseRight: Boolean;
begin
  Result := FMouseX > FX + HeroSize div 2;
end;

procedure THero.AdvanceWalkFrame;
begin
  FCurrentSprite := FCurrentSprite + WalkFrameAdvance;
  if FCurrentSprite > 8.1 then // 'CurrentSprite > 8.1' verbatim
    FCurrentSprite := 1;
end;

procedure THero.FallOneTick;
begin
  FY := FY + Round(FAcceleration);
  FAcceleration := FAcceleration + Gravity;
end;

procedure THero.RiseOneTick(ANextFall: THeroAction);
begin
  FY := FY - Round(FAcceleration);
  if FAcceleration > 0 then
    FAcceleration := FAcceleration - Step / JumpDel
  else
    FAction := ANextFall; // the arc peaks: rise hands over to fall
end;

procedure THero.BumpCeiling(ANextFall: THeroAction);
begin
  FAction := ANextFall;
  FAcceleration := FAcceleration / CeilingBumpDivisor;
end;

procedure THero.BeginJumpBoost;
begin
  FAcceleration := Step * StartUscor;
  if FForm = hfIce then
    FAcceleration := FAcceleration * IceJumpBoost;
end;

procedure THero.Tick;
begin
  SetWeaponAngle;
  if FTimeOfFire < FFireCooldown then // TWeapon.Timer
    Inc(FTimeOfFire);

  if FDead then
  begin
    if FDeathFrame < 16 then
      FDeathFrame := FDeathFrame + DeathFrameAdvance;
    // Improvement over 2008 (where a corpse froze mid-air): the body
    // obeys gravity and comes to rest on the ground.
    // One-shot landing: the live hero's CanIGoDown probes upward and
    // reports 'fall' again from the very cell line a body rests on -
    // checking it every tick made the corpse bounce. Settle once, done.
    if not FCorpseSettled then
    begin
      if CanIGoDown then
        FallOneTick
      else
      begin
        FY := (Trunc(FY) div HeroSize) * HeroSize;
        FAcceleration := 0;
        FCorpseSettled := True;
      end;
    end;
    Exit;
  end;

  case FAction of
    haWalkRight:
      begin
        AdvanceWalkFrame;
        if CanIGoRight then
          FX := FX + Step;
      end;

    haWalkLeft:
      begin
        AdvanceWalkFrame;
        if CanIGoLeft then
          FX := FX - Step;
      end;

    haFall:
      if CanIGoDown then
        FallOneTick
      else
      begin
        LandExactly;
        FAction := haStand;
        if FPending = psLeft then
          FAction := haWalkLeft;
        if FPending = psRight then
          FAction := haWalkRight;
        FPending := psNone;
      end;

    haFallLeft:
      if CanIGoDown then
      begin
        if CanIFlyLeft then
        begin
          FX := FX - Step;
          FallOneTick;
        end
        else
        begin
          FAction := haFall;
          FPending := psLeft;
        end;
      end
      else
      begin
        LandExactly;
        FAction := haWalkLeft;
      end;

    haFallRight:
      if CanIGoDown then
      begin
        if CanIFlyRight then
        begin
          FX := FX + Step;
          FallOneTick;
        end
        else
        begin
          FAction := haFall;
          FPending := psRight;
        end;
      end
      else
      begin
        LandExactly;
        FAction := haWalkRight;
      end;

    haJump:
      if CanIGoUp then
        RiseOneTick(haFall)
      else
        BumpCeiling(haFall);

    haJumpRight:
      if not CanIFlyRight then
      begin
        FAction := haJump;
        FPending := psRight;
      end
      else if CanIGoUp then
      begin
        FX := FX + Step;
        RiseOneTick(haFallRight);
      end
      else
        BumpCeiling(haFallRight);

    haJumpLeft:
      if not CanIFlyLeft then
      begin
        FAction := haJump;
        FPending := psLeft;
      end
      else if CanIGoUp then
      begin
        FX := FX - Step;
        RiseOneTick(haFallLeft);
      end
      else
        BumpCeiling(haFallLeft);
  end;
end;

// ---------------------------------------------------------------------------
// Fire - verbatim TWeapon.Fire (spawn point x+16, y+8; left adds 180)
// ---------------------------------------------------------------------------

function THero.Fire: Boolean;
const
  Spread = 5; // 'rasbros'
var
  BaseAngle: Integer;
  SpawnX, SpawnY: Double;
begin
  if FDead then
    Exit(False);
  if FTimeOfFire <> FFireCooldown then
    Exit(False);

  SpawnX := Round(FX) + HeroSize div 2;
  SpawnY := Round(FY) + HeroSize div 4;
  BaseAngle := Round(FWeaponAngle);
  if not FDirection then
    BaseAngle := BaseAngle + 180;

  case FWeaponType of
    0: // pistol
      FBullets.NewBullet(FBulletSpeed, SpawnX, SpawnY, BaseAngle,
        FBulletGravity, True);

    1: // shotgun: five pellets with positional spread
      for var i := 1 to 5 do
        FBullets.NewBullet(FBulletSpeed,
          SpawnX + Random(Spread) - Spread,
          SpawnY + Random(Spread) - Spread,
          BaseAngle, FBulletGravity, True);

    2: // grenade launcher: a 22-pellet cloud
      for var i := 1 to 22 do
        FBullets.NewBullet(FBulletSpeed,
          SpawnX + Round(Random(Spread * 2) - Spread * 2),
          SpawnY + Round(Random(Spread) * 1.5 - Spread * 1.5),
          BaseAngle, FBulletGravity, True);

    3: // chain: three bullets offset by a unit each
      for var i := 0 to 2 do
        FBullets.NewBullet(FBulletSpeed, SpawnX + i, SpawnY,
          BaseAngle, FBulletGravity, True);

    4: // minigun: center + side pair alternating 15/30 degrees,
       // all three born at the muzzle (see the const block above)
      begin
        var Rad := BaseAngle * Pi / 180;
        var MuzzleX := Round(FX) + FMinigunBaseX +
          FMinigunMuzzleLen * Cos(Rad);
        var MuzzleY := Round(FY) + FMinigunBaseY -
          FMinigunMuzzleLen * Sin(Rad);
        FBullets.NewBullet(FBulletSpeed, MuzzleX, MuzzleY, BaseAngle,
          FBulletGravity, True);
        var SideAngle := IfThen(FMinigunUpDown, 15, 30);
        FBullets.NewBullet(FBulletSpeed, MuzzleX, MuzzleY,
          BaseAngle + SideAngle, FBulletGravity, True);
        FBullets.NewBullet(FBulletSpeed, MuzzleX, MuzzleY,
          BaseAngle - SideAngle, FBulletGravity, True);
        FMinigunUpDown := not FMinigunUpDown;
      end;
  end;

  FTimeOfFire := 0;
  Result := True;
end;

// ---------------------------------------------------------------------------
// Weapon angle - verbatim SetWeaponAngle
// ---------------------------------------------------------------------------

procedure THero.SetWeaponAngle;
var
  DeltaX, DeltaY, Distance: Double;
begin
  DeltaX := FMouseX - FX - 16;
  DeltaY := FMouseY - FY + 16;
  Distance := Round(Sqrt(DeltaY * DeltaY + DeltaX * DeltaX));
  if Distance = 0 then
    Exit;

  // Verbatim: the sign flips follow the WALK direction, not the cursor.
  FWeaponAngle := -Round(57.296 * ArcSin(DeltaY / Distance));
  if not FDirection then
    FWeaponAngle := -FWeaponAngle;
  if FDirection and (DeltaX < 0) then
    FWeaponAngle := -(FWeaponAngle + 180);
  if (not FDirection) and (DeltaX > 0) then
    FWeaponAngle := -(FWeaponAngle + 180);
end;

// ---------------------------------------------------------------------------
// Drawing - verbatim OurHero.Put frame selection
// ---------------------------------------------------------------------------

procedure THero.Draw(const ASprites: TSpriteRenderer);
var
  Frame: Integer;
  FacingRight: Boolean;
begin
  FacingRight := FacingMouseRight;

  if FDead then
  begin
    ASprites.Draw(FFrames[Min(Round(FDeathFrame), 16)],
      Round(FX), Round(FY - HeroSize + Removal), not FDeathFacingRight);
    Exit;
  end;

  case FAction of
    haStand:
      Frame := 1;
    haWalkLeft:
      // Walking away from the cursor plays the cycle backwards
      if FacingRight then
        Frame := 9 - RoundHalfUp(FCurrentSprite)
      else
        Frame := RoundHalfUp(FCurrentSprite);
    haWalkRight:
      if FacingRight then
        Frame := RoundHalfUp(FCurrentSprite)
      else
        Frame := 9 - RoundHalfUp(FCurrentSprite);
    haJump, haFall:
      Frame := 2;
  else
    Frame := 6; // directional jumps and falls
  end;

  Frame := EnsureRange(Frame, 1, 8);
  if FForm = hfIce then
    Frame := Frame + 16; // the ice skin lives at frames 17..24

  ASprites.Draw(FFrames[Frame], Round(FX), Round(FY - HeroSize + Removal),
    not FacingRight);

  DrawWeapon(ASprites, FacingRight);
end;

// Verbatim geometry of weapon.pas TWeapon.Put, collapsed from its four
// copy-pasted branches (walk direction x mouse side) into the three
// orthogonal switches they actually encoded:
//   - flip, anchor X (18/22) and the one-pixel gun lift (-16/-15)
//     follow the MOUSE side;
//   - the barrel trig angle follows the WALK direction (+180 when
//     walking left);
//   - the sprite draw angle takes +180 exactly when walk and mouse
//     DISAGREE - the moonwalk pose.
// Every constant is the original's, quirks included; the four cases
// were replayed against the old branches before the collapse.
procedure THero.DrawWeapon(const ASprites: TSpriteRenderer;
  AMouseRight: Boolean);
const
  AnchorMouseRight = 18; // arm pivot X offsets, weapon.pas verbatim
  AnchorMouseLeft = 22;
  BarrelReachX = 10;     // gun offset trig radii
  BarrelReachY = 8;
var
  ArmFrame: Integer;
  AnchorX, GunOffsetY: Integer;
  DrawAngle, BarrelRad: Double;
begin
  if FForm = hfNormal then
    ArmFrame := 2
  else
    ArmFrame := 1;

  if AMouseRight then
  begin
    AnchorX := AnchorMouseRight;
    GunOffsetY := -16; // the odd one-pixel lift lives on this side only
  end
  else
  begin
    AnchorX := AnchorMouseLeft;
    GunOffsetY := -15;
  end;

  DrawAngle := FWeaponAngle;
  if FDirection <> AMouseRight then
    DrawAngle := FWeaponAngle + 180;

  if FDirection then
    BarrelRad := FWeaponAngle * Pi / 180
  else
    BarrelRad := (FWeaponAngle + 180) * Pi / 180;

  var ArmX := Round(FX) + ShiftX + AnchorX;
  var ArmY := Round(FY) + Shift - 15;
  var Flip := not AMouseRight;
  ASprites.DrawRotated(FWeaponFrames[ArmFrame], ArmX, ArmY,
    AngleSign * DrawAngle, Flip);
  ASprites.DrawRotated(FWeaponFrames[FWeaponType + 3],
    ArmX + Round(BarrelReachX * Cos(BarrelRad)),
    Round(FY) + Shift + GunOffsetY - Round(BarrelReachY * Sin(BarrelRad)),
    AngleSign * DrawAngle, Flip);
end;

end.
