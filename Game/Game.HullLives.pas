{
  Game.HullLives - the lives of the Ram's hull, which only the orb
  launcher takes, and the long bar along the top of the screen that shows
  them.

  Armed as the gun comes to the hero: the bar comes down into its place
  between the HUD's panels, then lights a cell at a time, as a head's row
  does after its lock. Each orb that sinks into a hot part of the hull
  takes a life and flashes the bar. With no life left it takes none more:
  the blast that ends the fight is not here. After a death past a door of
  the fight the caller resumes it with the lives of that door, not all of
  them.

  The bar tells whether the hull can be hurt: armoured while no part of it
  is hot, pulsing while one is - which parts are hot is the caller's to
  say, every tick.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.HullLives;
{$I ..\Moon2D.inc}

interface

const
  // The first grade's; the others' by the grade's share. A first guess,
  // to be tuned in the live run.
  RamHullLives = 240;
  HullBarCells = 30;
  // The bar comes down into its place over this long, then lights its
  // cells over HullBarBootTicks
  HullBarDropTicks = 16;
  HullBarBootTicks = 30;
  // The terminal's key is heard every this many cells lit
  HullBarKeyCells = 3;
  // A hit flashes the bar this long
  HullBarHitTicks = 8;
  // While a part is hot the bar pulses once in this long
  HullBarPulseTicks = 16;

type
  // The bar as the HUD draws it
  THullBar = record
    Shown: Boolean;
    // 0 out of sight over the top of the screen, 1 in its place
    Drop: Single;
    // Cells lit so far as the bar comes up
    Lit: Integer;
    // Lives left of the full
    Share: Single;
    // Ticks since the last life was taken
    HitTicks: Integer;
    // A part of the hull is hot: it can be hurt. Pulse - 0 to 1 and back
    // while it is.
    Hot: Boolean;
    Pulse: Single;
  end;

  THullLives = class
  private
    FArmed: Boolean;
    FLives: Integer;
    FFullLives: Integer;
    FTicks: Integer;
    FLastTicks: Integer;
    FHitTicks: Integer;
    FHot: Boolean;
    FHotTicks: Integer;
    function LitAt(ATicks: Integer): Integer;
  public
    constructor Create;
    // The gun has come: RamHullLives times ALivesShare, the bar coming
    // down and up from none
    procedure Arm(ALivesShare: Single);
    // Armed, ALives of the full are left: a restart past a door of the
    // fight. Within none and the full.
    procedure Resume(ALives: Integer);
    // A death, a new fight: no lives, no bar
    procedure Clear;
    // AHot - a part of the hull is hot this tick. True on the ticks the
    // terminal's key is heard: every HullBarKeyCells cells lit.
    function Tick(AHot: Boolean = False): Boolean;
    // An orb sank into a hot part: a life gone, the bar flashes. False when
    // there is none to take: not armed, or none left.
    function Wound: Boolean;
    // AAlpha of the way from the last tick to this one
    function Bar(AAlpha: Single): THullBar;
    property Armed: Boolean read FArmed;
    property Lives: Integer read FLives;
    property FullLives: Integer read FFullLives;
  end;

implementation

uses
  System.Math;

constructor THullLives.Create;
begin
  inherited Create;
  Clear;
end;

procedure THullLives.Arm(ALivesShare: Single);
begin
  FArmed := True;
  FFullLives := Max(1, Round(RamHullLives * ALivesShare));
  FLives := FFullLives;
  FTicks := 0;
  FLastTicks := 0;
  FHitTicks := HullBarHitTicks;
  FHot := False;
  FHotTicks := 0;
end;

procedure THullLives.Resume(ALives: Integer);
begin
  if not FArmed then
    Exit;
  FLives := EnsureRange(ALives, 0, FFullLives);
end;

procedure THullLives.Clear;
begin
  FArmed := False;
  FLives := 0;
  FFullLives := 0;
  FTicks := 0;
  FLastTicks := 0;
  FHitTicks := HullBarHitTicks;
  FHot := False;
  FHotTicks := 0;
end;

function THullLives.LitAt(ATicks: Integer): Integer;
begin
  var Booted := ATicks - HullBarDropTicks;
  if Booted <= 0 then
    Exit(0);
  Result := Min(HullBarCells, Booted * HullBarCells div HullBarBootTicks);
end;

function THullLives.Tick(AHot: Boolean): Boolean;
begin
  Result := False;
  if not FArmed then
    Exit;
  if FHitTicks < HullBarHitTicks then
    Inc(FHitTicks);
  // The pulse starts anew with every heat
  if AHot and FHot then
    Inc(FHotTicks)
  else
    FHotTicks := 0;
  FHot := AHot;
  FLastTicks := FTicks;
  if FTicks >= HullBarDropTicks + HullBarBootTicks then
    Exit;
  Inc(FTicks);
  Result := LitAt(FTicks) div HullBarKeyCells > LitAt(FLastTicks) div HullBarKeyCells;
end;

function THullLives.Wound: Boolean;
begin
  if not FArmed or (FLives = 0) then
    Exit(False);
  Dec(FLives);
  FHitTicks := 0;
  Result := True;
end;

function THullLives.Bar(AAlpha: Single): THullBar;
begin
  Result := Default(THullBar);
  if not FArmed then
    Exit;
  Result.Shown := True;
  var Clock: Single := FLastTicks + (FTicks - FLastTicks) * AAlpha;
  Result.Drop := EnsureRange(Clock / HullBarDropTicks, 0, 1);
  Result.Lit := LitAt(FTicks);
  Result.Share := FLives / FFullLives;
  Result.HitTicks := FHitTicks;
  Result.Hot := FHot;
  if FHot then
    Result.Pulse := 0.5 - 0.5 * Cos(2 * Pi * (FHotTicks + AAlpha) / HullBarPulseTicks);
end;

end.
