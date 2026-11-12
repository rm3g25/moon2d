{
  Game.Mortar - the stern mortar on the Ram's rear block, its second weapon
  aloft. Folded behind the block till it is given a turn: then it rises,
  turns toward the hero's feet, lobs a shell at the deck he stands on, and
  waits till that shell is gone - burst or fallen - before it aims the
  next. One shell at a time, never a pair. Its shells spent, it folds back
  behind the block and the turn is over.

  A hero who stands on no deck when it is ready is waited for a while; one
  who stays in the air past that costs it the shell.

  It knows neither the shells nor the decks: the caller says where its
  pivot and his feet are, whether he stands on a deck and how many shells
  are in the air, and lobs the shell it is told of. No drawing.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Mortar;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

const
  // Out from behind the block and back, ticks
  MortarRiseTicks = 20;
  MortarFoldTicks = 20;
  // Turning toward his feet before a lob; then it waits for him to stand
  // on a deck this long at most
  MortarAimTicks = 16;
  MortarWaitTicks = 40;
  // Its last shell gone, this long before the next is aimed
  MortarGapTicks = 20;
  // It leans toward his feet, degrees either way at most, the whole lean
  // this far across from its pivot
  MortarTiltMost = 15.0;
  MortarTiltReach = 180.0;
  // The kick of a lob dies out over this long
  MortarKickTicks = 6;

type
  // msStowed - behind the block; msRising - coming out; msAiming - turning
  // to his feet, waiting for him to stand; msWaiting - its shell in the
  // air, then the gap; msFolding - going back behind the block
  TMortarStage = (msStowed, msRising, msAiming, msWaiting, msFolding);

  // What the mortar sees this tick
  TMortarSight = record
    // Its pivot - the bottom of its base - on the screen
    Pivot: TSdlFPoint;
    // The middle of his feet
    Feet: TSdlFPoint;
    // He stands on a deck
    OnDeck: Boolean;
    // Shells in the air or on their way down
    ShellsAloft: Integer;
  end;

  TMortarCue = record
    // It starts to come out: the turn is on
    Rises: Boolean;
    // A shell out of its muzzle at his feet
    Lob: Boolean;
    LobAt: TSdlFPoint;
    // Folded back: the turn is over
    Folded: Boolean;
  end;

  TMortar = class
  private
    FStage: TMortarStage;
    FTicks: Integer;
    FLeft: Integer;
    FOut, FLastOut: Single;
    FTilt, FLastTilt: Single;
    FKick, FLastKick: Single;
    procedure TickRising;
    procedure TickAiming(const ASight: TMortarSight; var ACue: TMortarCue);
    procedure TickWaiting(const ASight: TMortarSight);
    procedure TickFolding(var ACue: TMortarCue);
    procedure NextShell;
    procedure TiltToward(AWanted: Single);
  public
    constructor Create;
    // A death, a new fight: folded, its turn gone
    procedure Clear;
    // A turn of AShells: out from behind the block, then one at a time;
    // nothing unless folded
    procedure BeginTurn(AShells: Integer);
    function Tick(const ASight: TMortarSight): TMortarCue;
    property Stage: TMortarStage read FStage;
    // Out, or on its way out or back: its turn
    function Busy: Boolean;
    // Shells of the turn not lobbed yet
    property ShellsLeft: Integer read FLeft;
    // AAlpha of the way from the last tick to this one: 0 behind the block
    // to 1 out; degrees clockwise it leans; 1 the tick it lobs, dying out
    function OutAt(AAlpha: Single): Single;
    function TiltAt(AAlpha: Single): Single;
    function KickAt(AAlpha: Single): Single;
  end;

// Degrees clockwise a mortar at APivot leans to lob at AFeet
function MortarTilt(const APivot, AFeet: TSdlFPoint): Single;

implementation

uses
  System.Math;

const
  // Each tick the lean goes this share of the way to the one it wants
  TiltLearn = 0.25;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

function MortarTilt(const APivot, AFeet: TSdlFPoint): Single;
begin
  Result := MortarTiltMost *
    EnsureRange((AFeet.X - APivot.X) / MortarTiltReach, -1.0, 1.0);
end;

constructor TMortar.Create;
begin
  inherited Create;
  Clear;
end;

procedure TMortar.Clear;
begin
  FStage := msStowed;
  FTicks := 0;
  FLeft := 0;
  FOut := 0;
  FLastOut := 0;
  FTilt := 0;
  FLastTilt := 0;
  FKick := 0;
  FLastKick := 0;
end;

procedure TMortar.BeginTurn(AShells: Integer);
begin
  if (FStage <> msStowed) or (AShells <= 0) then
    Exit;
  FStage := msRising;
  FTicks := 0;
  FLeft := AShells;
end;

function TMortar.Busy: Boolean;
begin
  Result := FStage <> msStowed;
end;

function TMortar.Tick(const ASight: TMortarSight): TMortarCue;
begin
  Result := Default(TMortarCue);
  FLastOut := FOut;
  FLastTilt := FTilt;
  FLastKick := FKick;
  FKick := Max(0, FKick - 1 / MortarKickTicks);
  case FStage of
    msRising:
      begin
        Result.Rises := FTicks = 0;
        TickRising;
      end;
    msAiming:
      TickAiming(ASight, Result);
    msWaiting:
      TickWaiting(ASight);
    msFolding:
      TickFolding(Result);
  end;
end;

procedure TMortar.TickRising;
begin
  Inc(FTicks);
  FOut := SmoothStep(FTicks / MortarRiseTicks);
  if FTicks < MortarRiseTicks then
    Exit;
  FStage := msAiming;
  FTicks := 0;
end;

procedure TMortar.TiltToward(AWanted: Single);
begin
  FTilt := Lerp(FTilt, AWanted, TiltLearn);
end;

// Turned to his feet for MortarAimTicks; it lobs the first tick after that
// he stands on a deck - or gives the shell up once he has kept off one
// for MortarWaitTicks more
procedure TMortar.TickAiming(const ASight: TMortarSight; var ACue: TMortarCue);
begin
  Inc(FTicks);
  TiltToward(MortarTilt(ASight.Pivot, ASight.Feet));
  if FTicks < MortarAimTicks then
    Exit;
  if ASight.OnDeck then
  begin
    ACue.Lob := True;
    ACue.LobAt := ASight.Feet;
    FKick := 1;
    Dec(FLeft);
    FStage := msWaiting;
    FTicks := 0;
    Exit;
  end;
  if FTicks < MortarAimTicks + MortarWaitTicks then
    Exit;
  Dec(FLeft);
  NextShell;
end;

// The gap counts from the moment no shell is in the air
procedure TMortar.TickWaiting(const ASight: TMortarSight);
begin
  if ASight.ShellsAloft > 0 then
  begin
    FTicks := 0;
    Exit;
  end;
  Inc(FTicks);
  if FTicks >= MortarGapTicks then
    NextShell;
end;

procedure TMortar.NextShell;
begin
  FTicks := 0;
  if FLeft > 0 then
    FStage := msAiming
  else
    FStage := msFolding;
end;

procedure TMortar.TickFolding(var ACue: TMortarCue);
begin
  Inc(FTicks);
  TiltToward(0);
  FOut := 1 - SmoothStep(FTicks / MortarFoldTicks);
  if FTicks < MortarFoldTicks then
    Exit;
  FOut := 0;
  FTilt := 0;
  FStage := msStowed;
  FTicks := 0;
  ACue.Folded := True;
end;

function TMortar.OutAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastOut, FOut, AAlpha);
end;

function TMortar.TiltAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastTilt, FTilt, AAlpha);
end;

function TMortar.KickAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastKick, FKick, AAlpha);
end;

end.
