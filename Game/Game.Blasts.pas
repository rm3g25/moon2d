{
  Game.Blasts - what an explosion does, as Game.Explosions is what it
  looks like: a wave that leaves the heart of a blown-up body and wounds
  what it reaches. The wave goes WaveSpeed units a tick out to the
  blast's radius and strikes a body once, at the point of the body
  nearest to the heart: the farther that point, the fewer lives and the
  weaker the shove. Solid matter between the heart and the point
  shelters the body.

  The blast knows neither a monster nor the hero: the game shows it
  bodies as objects and points, and hands out the lives and the shove
  itself.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Blasts;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Effects.Sparks, Monsters.Defs;

type
  TBlast = class
  private
    FHeart: TSdlFPoint;
    FDef: TBlastDef;
    FFront: Double; // how far the wave has gone, units
    FStruck: TList<TObject>;
    function Distance(const APoint: TSdlFPoint): Double;
  public
    constructor Create(const AHeart: TSdlFPoint; const ADef: TBlastDef);
    destructor Destroy; override;
    // A tick of the wave
    procedure Spread;
    // The wave has gone its whole radius
    function Spent: Boolean;
    // True once for a body: the wave has reached ANear, the point of the
    // body nearest to the heart, and nothing solid stands between them
    function Strikes(ABody: TObject; const ANear: TSdlFPoint;
      const ASolid: TSolidProbe): Boolean;
    // What is left of the blast at the point: 1 at the heart, 0 at the
    // radius and beyond
    function Share(const APoint: TSdlFPoint): Double;
    // AScale - the difficulty's scale of the monsters' lives: a blast
    // keeps its worth against them on every grade
    function Lives(const APoint: TSdlFPoint; AScale: Double): Integer;
    // The shove of a body struck at the point, as a bullet's knock: away
    // from the heart, by where the body's middle AMiddleX lies
    function Knock(const APoint: TSdlFPoint; AMiddleX: Single): Integer;
    property Heart: TSdlFPoint read FHeart;
  end;

// The point of the rectangle nearest to AFrom; AFrom itself when inside
function NearestPoint(const ABody: TSdlFRect;
  const AFrom: TSdlFPoint): TSdlFPoint;
// Nothing solid on the way from AFrom to ATo. ATo itself is not asked: it
// lies on the edge of a body, and a body stands flush against matter
function SightClear(const AFrom, ATo: TSdlFPoint;
  const ASolid: TSolidProbe): Boolean;

implementation

uses
  System.Math;

const
  WaveSpeed = 8; // units a tick
  // The knock at the heart; a body moves half of a knock
  HeartKnock = 32;
  // Units between the points a sight line asks: a wall is 32 thick
  SightStep = 4;

function NearestPoint(const ABody: TSdlFRect;
  const AFrom: TSdlFPoint): TSdlFPoint;
begin
  Result.X := EnsureRange(AFrom.X, ABody.X, ABody.X + ABody.W);
  Result.Y := EnsureRange(AFrom.Y, ABody.Y, ABody.Y + ABody.H);
end;

function SightClear(const AFrom, ATo: TSdlFPoint;
  const ASolid: TSolidProbe): Boolean;
begin
  var Span := Hypot(ATo.X - AFrom.X, ATo.Y - AFrom.Y);
  var Steps := Ceil(Span / SightStep);
  for var i := 0 to Steps - 1 do
  begin
    var Along := i / Steps;
    if ASolid(AFrom.X + (ATo.X - AFrom.X) * Along,
      AFrom.Y + (ATo.Y - AFrom.Y) * Along) then
      Exit(False);
  end;
  Result := True;
end;

constructor TBlast.Create(const AHeart: TSdlFPoint; const ADef: TBlastDef);
begin
  inherited Create;
  FHeart := AHeart;
  FDef := ADef;
  FStruck := TList<TObject>.Create;
end;

destructor TBlast.Destroy;
begin
  FStruck.Free;
  inherited;
end;

function TBlast.Distance(const APoint: TSdlFPoint): Double;
begin
  Result := Hypot(APoint.X - FHeart.X, APoint.Y - FHeart.Y);
end;

procedure TBlast.Spread;
begin
  FFront := FFront + WaveSpeed;
end;

function TBlast.Spent: Boolean;
begin
  Result := FFront >= FDef.Radius;
end;

function TBlast.Strikes(ABody: TObject; const ANear: TSdlFPoint;
  const ASolid: TSolidProbe): Boolean;
begin
  Result := (Distance(ANear) <= Min(FFront, FDef.Radius)) and
    not FStruck.Contains(ABody) and SightClear(FHeart, ANear, ASolid);
  if Result then
    FStruck.Add(ABody);
end;

function TBlast.Share(const APoint: TSdlFPoint): Double;
begin
  Result := Max(0.0, 1 - Distance(APoint) / FDef.Radius);
end;

function TBlast.Lives(const APoint: TSdlFPoint; AScale: Double): Integer;
begin
  // At least one: a body the wave strikes is wounded
  Result := Max(1, Round(FDef.Lives * Share(APoint) * AScale));
end;

function TBlast.Knock(const APoint: TSdlFPoint; AMiddleX: Single): Integer;
begin
  Result := Round(HeartKnock * Share(APoint)) * Sign(AMiddleX - FHeart.X);
end;

end.
