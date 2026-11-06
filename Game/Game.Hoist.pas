{
  Game.Hoist - the way the orbs of the throw carry the hero: from where
  they caught him - on a pad, on the road, in the air - to where he is to
  hang, out of the picture of the throw: a little over the road by the
  right edge. Along the straight line between, eased in and out, the line
  bowed upward in its middle, so he is lifted off rather than dragged; a
  long way takes longer, at an even pace on average.

  Geometry alone: the game hands in where he is and where he goes, and
  asks the path where he is so many ticks on.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Hoist;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

const
  // Units a tick, on average; no carry is shorter than HoistLeastTicks
  HoistPace = 3.0;
  HoistLeastTicks = 30;
  // How far over the straight line the middle of the way is bowed
  HoistBow = 16.0;

type
  // Points are the hero's left edge and his feet line, as THero keeps them
  THoistPath = record
    From: TSdlFPoint;
    Place: TSdlFPoint;
    Ticks: Integer;
    // Where he hangs ATicks after the catch; at his place from Ticks on
    function At(ATicks: Integer): TSdlFPoint;
  end;

function PlanHoist(const AFrom, APlace: TSdlFPoint): THoistPath;

implementation

uses
  System.Math;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0, 1);
  Result := Share * Share * (3 - 2 * Share);
end;

function PlanHoist(const AFrom, APlace: TSdlFPoint): THoistPath;
begin
  Result.From := AFrom;
  Result.Place := APlace;
  var Way := Hypot(APlace.X - AFrom.X, APlace.Y - AFrom.Y);
  Result.Ticks := Max(HoistLeastTicks, Ceil(Way / HoistPace));
end;

{ THoistPath }

function THoistPath.At(ATicks: Integer): TSdlFPoint;
begin
  if ATicks <= 0 then
    Exit(From);
  if ATicks >= Ticks then
    Exit(Place);
  var Share: Single := ATicks / Ticks;
  var Eased := SmoothStep(Share);
  Result.X := From.X + (Place.X - From.X) * Eased;
  Result.Y := From.Y + (Place.Y - From.Y) * Eased - HoistBow * Sin(Pi * Share);
end;

end.
