{
  Game.OrbLauncher - the orb launcher coming to the hero once the Ram
  hangs, as a pickup: when it appears, where, and when it lies on the
  road to be taken.

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
unit Game.OrbLauncher;
{$I ..\Moon2D.inc}

interface

const
  // The hull settled, this long before the gun appears
  OrbLauncherBreathTicks = 33;
  // From his middle to the gun's at the least: the next cell, never his
  OrbLauncherClearance = 32.0;

type
  // olWaiting - the breath; olAppearing - the gun put together under its
  // shroud; olLying - on the road, to be taken; olTaken - his
  TOrbLauncherStage = (olNone, olWaiting, olAppearing, olLying, olTaken);

  TOrbLauncherCue = record
    // The gun's shroud starts at its place
    Appear: Boolean;
    // Put together: the pickup lies on the road from now on
    Lay: Boolean;
  end;

  TOrbLauncherArrival = class
  private
    FStage: TOrbLauncherStage;
    FTicks: Integer;
  public
    // The hull hangs: the breath begins; nothing once started
    procedure Start;
    // AAssembling - the gun's shroud is still putting it together
    function Tick(AAssembling: Boolean): TOrbLauncherCue;
    // He has taken it; nothing unless it lies
    procedure Take;
    // A death, a new level: none of it
    procedure Clear;
    property Stage: TOrbLauncherStage read FStage;
  end;

// The middle of the gun along the screen, the middle of the hero at
// AHeroMiddle: the middle of the screen, or the next cell when he stands
// there - on the side the screen is wider
function OrbLauncherSpotX(AHeroMiddle: Single): Single;

implementation

uses
  Game.Space;

procedure TOrbLauncherArrival.Start;
begin
  if FStage <> olNone then
    Exit;
  FStage := olWaiting;
  FTicks := 0;
end;

function TOrbLauncherArrival.Tick(AAssembling: Boolean): TOrbLauncherCue;
begin
  Result := Default(TOrbLauncherCue);
  case FStage of
    olWaiting:
      begin
        Inc(FTicks);
        if FTicks < OrbLauncherBreathTicks then
          Exit;
        FStage := olAppearing;
        Result.Appear := True;
      end;
    olAppearing:
      if not AAssembling then
      begin
        FStage := olLying;
        Result.Lay := True;
      end;
  end;
end;

procedure TOrbLauncherArrival.Take;
begin
  if FStage = olLying then
    FStage := olTaken;
end;

procedure TOrbLauncherArrival.Clear;
begin
  FStage := olNone;
  FTicks := 0;
end;

function OrbLauncherSpotX(AHeroMiddle: Single): Single;
begin
  Result := ScreenWidth / 2;
  if Abs(Result - AHeroMiddle) >= OrbLauncherClearance then
    Exit;
  if AHeroMiddle <= Result then
    Result := AHeroMiddle + OrbLauncherClearance
  else
    Result := AHeroMiddle - OrbLauncherClearance;
end;

end.
