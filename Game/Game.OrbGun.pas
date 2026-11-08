{
  Game.OrbGun - the orb gun coming to the hero once the Ram hangs, as a
  pickup: when it appears, where, and when it lies on the road to be
  taken.

  The hull settled, a breath; then the gun appears in the middle of the
  screen, put together under the shroud of the respawn, and once put
  together it lies on the road, a pickup like any. He takes it, and the
  fight with the bare hull begins. The middle is the gun's place unless
  he stands there: then it lies on the next cell, on the side of the
  wider screen, not on his.

  The arrival knows neither the Ram, the hero nor the shroud: the game
  starts it while the hull hangs, hands in whether the gun is still being
  put together, carries out its cues and tells it of the take.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.OrbGun;
{$I ..\Moon2D.inc}

interface

const
  // The hull settled, this long before the gun appears
  OrbGunBreathTicks = 33;
  // From his middle to the gun's at the least: the next cell, never his
  OrbGunClearance = 32.0;

type
  // ogWaiting - the breath; ogAppearing - the gun put together under its
  // shroud; ogLying - on the road, to be taken; ogTaken - his
  TOrbGunStage = (ogNone, ogWaiting, ogAppearing, ogLying, ogTaken);

  TOrbGunCue = record
    // The gun's shroud starts at its place
    Appear: Boolean;
    // Put together: the pickup lies on the road from now on
    Lay: Boolean;
  end;

  TOrbGunArrival = class
  private
    FStage: TOrbGunStage;
    FTicks: Integer;
  public
    // The hull hangs: the breath begins; nothing once started
    procedure Start;
    // AAssembling - the gun's shroud is still putting it together
    function Tick(AAssembling: Boolean): TOrbGunCue;
    // He has taken it; nothing unless it lies
    procedure Take;
    // A death, a new level: none of it
    procedure Clear;
    property Stage: TOrbGunStage read FStage;
  end;

// The middle of the gun along the screen, the middle of the hero at
// AHeroMiddle: the middle of the screen, or the next cell when he stands
// there - on the side the screen is wider
function OrbGunSpotX(AHeroMiddle: Single): Single;

implementation

uses
  Game.Space;

procedure TOrbGunArrival.Start;
begin
  if FStage <> ogNone then
    Exit;
  FStage := ogWaiting;
  FTicks := 0;
end;

function TOrbGunArrival.Tick(AAssembling: Boolean): TOrbGunCue;
begin
  Result := Default(TOrbGunCue);
  case FStage of
    ogWaiting:
      begin
        Inc(FTicks);
        if FTicks < OrbGunBreathTicks then
          Exit;
        FStage := ogAppearing;
        Result.Appear := True;
      end;
    ogAppearing:
      if not AAssembling then
      begin
        FStage := ogLying;
        Result.Lay := True;
      end;
  end;
end;

procedure TOrbGunArrival.Take;
begin
  if FStage = ogLying then
    FStage := ogTaken;
end;

procedure TOrbGunArrival.Clear;
begin
  FStage := ogNone;
  FTicks := 0;
end;

function OrbGunSpotX(AHeroMiddle: Single): Single;
begin
  Result := ScreenWidth / 2;
  if Abs(Result - AHeroMiddle) >= OrbGunClearance then
    Exit;
  if AHeroMiddle <= Result then
    Result := AHeroMiddle + OrbGunClearance
  else
    Result := AHeroMiddle - OrbGunClearance;
end;

end.
