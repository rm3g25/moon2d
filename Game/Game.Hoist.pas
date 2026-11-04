{
  Game.Hoist - the way the henshin lifts the hero: a cell up from where
  the light caught him, on a pad, on the road or in the air. Too near an
  edge of the screen or the Ram's hull he is drawn clear along the line
  he hangs on first, then lifted straight up.

  Geometry alone: the game hands in where he hangs and where the hull
  stands, and asks the path where he is so many ticks on.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Hoist;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

const
  // Room for the ring of the rite round him, from either edge
  HoistEdgeClear = 48;
  HoistHullClear = 16;
  HoistRiseTicks = 30;
  // Units a tick, on average, of the way across
  HoistDrawPace = 3;

type
  THoistWorld = record
    HasHull: Boolean;
    Hull: TSdlFRect;
  end;

  // Points are the hero's left edge and his feet line, as THero keeps them
  THoistPath = record
    From: TSdlFPoint;
    Clear: TSdlFPoint;
    Top: TSdlFPoint;
    DrawTicks: Integer;
    RiseTicks: Integer;
    function Ticks: Integer;
    // Where he hangs ATicks after the catch; at the top from Ticks on
    function At(ATicks: Integer): TSdlFPoint;
  end;

function PlanHoist(const AFrom: TSdlFPoint; const AWorld: THoistWorld): THoistPath;

implementation

uses
  System.Math, Render.Sprites, Game.Space;

const
  // The hero is a cell, and the lift is one
  BodySize = TileSize;
  HoistRise = TileSize;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0, 1);
  Result := Share * Share * (3 - 2 * Share);
end;

function Between(const AFrom, ATo: TSdlFPoint; AShare: Single): TSdlFPoint;
begin
  Result.X := AFrom.X + (ATo.X - AFrom.X) * AShare;
  Result.Y := AFrom.Y + (ATo.Y - AFrom.Y) * AShare;
end;

function KeptOffEdges(ALeft: Single): Single;
begin
  Result := EnsureRange(ALeft, HoistEdgeClear,
    ScreenWidth - HoistEdgeClear - BodySize);
end;

// The body over the whole of its lift, at ALeft, comes within the clear
// of the hull
function NearHull(ALeft, AFeet: Single; const AHull: TSdlFRect): Boolean;
begin
  var Top := AFeet - BodySize - HoistRise;
  var Across := (ALeft + BodySize > AHull.X - HoistHullClear) and
    (ALeft < AHull.X + AHull.W + HoistHullClear);
  var Along := (Top < AHull.Y + AHull.H) and (AFeet > AHull.Y);
  Result := Across and Along;
end;

// Off the hull on the side away from its middle, unless that side's edge
// leaves no room for him
function AsideOfHull(ALeft: Single; const AHull: TSdlFRect): Single;
begin
  var LeftOf := AHull.X - HoistHullClear - BodySize;
  var RightOf := AHull.X + AHull.W + HoistHullClear;
  var LeftFits := LeftOf >= HoistEdgeClear;
  var RightFits := RightOf <= ScreenWidth - HoistEdgeClear - BodySize;
  var GoesLeft := ALeft + BodySize / 2 < AHull.X + AHull.W / 2;
  if GoesLeft and not LeftFits then
    GoesLeft := False
  else if not GoesLeft and not RightFits then
    GoesLeft := LeftFits;
  if GoesLeft then
    Result := LeftOf
  else
    Result := KeptOffEdges(RightOf);
end;

function PlanHoist(const AFrom: TSdlFPoint; const AWorld: THoistWorld): THoistPath;
begin
  var Left := KeptOffEdges(AFrom.X);
  if AWorld.HasHull and NearHull(Left, AFrom.Y, AWorld.Hull) then
    Left := AsideOfHull(Left, AWorld.Hull);

  Result.From := AFrom;
  Result.Clear.X := Left;
  Result.Clear.Y := AFrom.Y;
  Result.Top.X := Left;
  Result.Top.Y := AFrom.Y - HoistRise;
  Result.DrawTicks := Ceil(Abs(Left - AFrom.X) / HoistDrawPace);
  Result.RiseTicks := HoistRiseTicks;
end;

{ THoistPath }

function THoistPath.Ticks: Integer;
begin
  Result := DrawTicks + RiseTicks;
end;

function THoistPath.At(ATicks: Integer): TSdlFPoint;
begin
  if ATicks <= 0 then
    Exit(From);
  if ATicks < DrawTicks then
    Exit(Between(From, Clear, SmoothStep(ATicks / DrawTicks)));
  Result := Between(Clear, Top, SmoothStep((ATicks - DrawTicks) / RiseTicks));
end;

end.
