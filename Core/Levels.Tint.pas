{
  Levels.Tint - the color multiplier a picture placed by level JSON may
  carry: "tint": [r, g, b], a percentage per channel, applied when the
  picture is drawn. Backdrops, static objects and dynamic objects read
  it through the one reader here, so the word means one thing in the
  whole file.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Tint;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON;

type
  ETintError = class(Exception);

  // Per-channel multiplier in percent; 100 leaves the picture as
  // painted, three equal numbers are pure brightness
  TColorTint = record
    R, G, B: Byte;
    class function Neutral: TColorTint; static;
  end;

// The "tint" of AObj - or another key of the same shape; absent =
// neutral. AOwner names the picture in errors.
function ReadTint(AObj: TJSONObject; const AOwner: string;
  const AKey: string = 'tint'): TColorTint;

implementation

resourcestring
  SBadTint = '"%s" of "%s" takes three percentages, 0..100';

class function TColorTint.Neutral: TColorTint;
begin
  Result.R := 100;
  Result.G := 100;
  Result.B := 100;
end;

// A wrong shape raises: a picture that silently stays at full
// brightness looks like a tint that was never tuned
function ReadTint(AObj: TJSONObject; const AOwner: string;
  const AKey: string): TColorTint;

  function Percent(AValue: TJSONValue): Byte;
  begin
    if not (AValue is TJSONNumber) then
      raise ETintError.CreateFmt(SBadTint, [AKey, AOwner]);
    var Value := TJSONNumber(AValue).AsInt;
    if (Value < 0) or (Value > 100) then
      raise ETintError.CreateFmt(SBadTint, [AKey, AOwner]);
    Result := Value;
  end;

begin
  var Raw := AObj.GetValue(AKey);
  if Raw = nil then
    Exit(TColorTint.Neutral);
  if not (Raw is TJSONArray) or (TJSONArray(Raw).Count <> 3) then
    raise ETintError.CreateFmt(SBadTint, [AKey, AOwner]);

  var Channels := TJSONArray(Raw);
  Result.R := Percent(Channels.Items[0]);
  Result.G := Percent(Channels.Items[1]);
  Result.B := Percent(Channels.Items[2]);
end;

end.
