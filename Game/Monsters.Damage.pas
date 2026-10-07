{
  Monsters.Damage - the window of a monster's damage cap: how many lives
  it may still lose, counting the ticks it is asked about. It remembers
  what landed on each of the last Ticks ticks and lets a blow's lives
  through only while their sum is under the cap; the rest are lost, not
  held over for a later tick.

  Not here: the knockback, the thresholds and the sparks of a blow. A
  blow over the cap is still a blow - only its lives do not count.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Monsters.Damage;
{$I ..\Moon2D.inc}

interface

uses
  Monsters.Defs;

type
  TDamageWindow = class
  private
    FCap: Integer;
    // Lives landed on each tick of the window, the current tick at FSlot
    FLanded: TArray<Integer>;
    FSlot: Integer;
    FTotal: Integer;
  public
    constructor Create(const ACap: TDamageCap);
    // The next tick begins: the tick that leaves the window is forgotten
    procedure Advance;
    // How many of ALosses count; the rest are over the cap
    function Admit(ALosses: Integer): Integer;
  end;

implementation

uses
  System.Math;

constructor TDamageWindow.Create(const ACap: TDamageCap);
begin
  inherited Create;
  FCap := ACap.Lives;
  SetLength(FLanded, ACap.Ticks);
end;

procedure TDamageWindow.Advance;
begin
  FSlot := (FSlot + 1) mod Length(FLanded);
  Dec(FTotal, FLanded[FSlot]);
  FLanded[FSlot] := 0;
end;

function TDamageWindow.Admit(ALosses: Integer): Integer;
begin
  Result := EnsureRange(FCap - FTotal, 0, ALosses);
  Inc(FLanded[FSlot], Result);
  Inc(FTotal, Result);
end;

end.
