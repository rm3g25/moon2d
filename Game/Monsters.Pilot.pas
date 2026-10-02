{
  Monsters.Pilot - the one who flies a monster of the mkBossFly kind:
  where its body goes this tick. The monster keeps its place, its step
  and its guns; the pilot moves the place.

  The lap is the rectangle of 2008 with its top mark lowered clear of
  the HUD: four marks flown clockwise, every side overshooting its mark
  by what the step leaves. No wall is asked: the lap runs through the
  open lanes of the boss screen.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Monsters.Pilot;
{$I ..\Moon2D.inc}

interface

type
  THeading = (hdDown, hdLeft, hdUp, hdRight);

  TPilot = class
  private
    FHeading: THeading;
  public
    constructor Create;
    // One logic tick. AX, AY - the feet point of the body.
    procedure Tick(var AX, AY: Double; AStep: Integer);
  end;

implementation

const
  // The marks a side of the lap is flown to, by the feet point of the
  // body. The top one keeps the boss in sight: the HUD panels reach y 36
  // and the body rises 32 above its Y.
  LapLeft = 32;
  LapRight = 448;
  LapTop = 96;
  LapBottom = 320;

constructor TPilot.Create;
begin
  inherited Create;
  FHeading := hdDown;
end;

procedure TPilot.Tick(var AX, AY: Double; AStep: Integer);
begin
  case FHeading of
    hdDown:
      begin
        AY := AY + AStep;
        if AY > LapBottom then
          FHeading := hdLeft;
      end;
    hdLeft:
      begin
        AX := AX - AStep;
        if AX < LapLeft then
          FHeading := hdUp;
      end;
    hdUp:
      begin
        AY := AY - AStep;
        if AY < LapTop then
          FHeading := hdRight;
      end;
    hdRight:
      begin
        AX := AX + AStep;
        if AX > LapRight then
          FHeading := hdDown;
      end;
  end;
end;

end.
