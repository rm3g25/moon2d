{
  Levels.Pads - the pads section of level JSON: platforms apart from the
  collision grid. Model and parser, no game logic - the game runs them
  in Pads.World.

  A pad holds from above only. Its deck, the top edge, carries what lands
  on it; from below and from the side anything passes through. Under the
  deck the pad has a body one cell deep: it stops the boss's flight, the
  sparks and the debris, and the bullets unless the pad lets them by.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Pads;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Levels.Tint;

type
  EPadError = class(Exception);

  // What a pad's body does to a bullet: bursts it, or lets it by
  TPadBullets = (pbBlock, pbPass);

  TPadPlacement = record
    Sprite: string; // in the level's object art, as a static object's
    Screen: Integer; // 1-based
    // The top-left corner and the width in screen units, as a static
    // object's; Y is the deck. The picture's height follows its aspect.
    X: Integer;
    Y: Integer;
    Width: Integer;
    Tint: TColorTint;
    // Names the pad for the dynamic objects hung on it; '' = none
    Tag: string;
    Bullets: TPadBullets;
  end;

const
  PadBulletsIds: array [TPadBullets] of string = ('block', 'pass');

// The section; absent = no pads. A width of zero or less and a bullets
// word out of PadBulletsIds raise.
function ParsePads(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TPadPlacement>;

implementation

resourcestring
  SPadBadWidth = 'Level "%s": pad "%s" is %d units wide';
  SPadBadBullets = 'Level "%s": pad "%s" takes bullets "%s" - block or pass';

function ReadBullets(const AObj: TJSONObject;
  const ALevelId, ASprite: string): TPadBullets;
begin
  var Id := AObj.GetValue<string>('bullets', PadBulletsIds[pbBlock]);
  for var Bullets := Low(TPadBullets) to High(TPadBullets) do
    if SameText(Id, PadBulletsIds[Bullets]) then
      Exit(Bullets);
  raise EPadError.CreateFmt(SPadBadBullets, [ALevelId, ASprite, Id]);
end;

function ParsePads(const ARoot: TJSONObject;
  const ALevelId: string): TArray<TPadPlacement>;
var
  Section: TJSONArray;
begin
  Result := [];
  if not ARoot.TryGetValue<TJSONArray>('pads', Section) then
    Exit;

  for var Item in Section do
  begin
    var Obj := Item as TJSONObject;
    var Pad: TPadPlacement;
    Pad.Sprite := Obj.GetValue<string>('sprite');
    Pad.Screen := Obj.GetValue<Integer>('screen');
    Pad.X := Obj.GetValue<Integer>('x');
    Pad.Y := Obj.GetValue<Integer>('y');
    Pad.Width := Obj.GetValue<Integer>('width');
    Pad.Tint := ReadTint(Obj, Pad.Sprite);
    Pad.Tag := Obj.GetValue<string>('tag', '');
    Pad.Bullets := ReadBullets(Obj, ALevelId, Pad.Sprite);

    if Pad.Width <= 0 then
      raise EPadError.CreateFmt(SPadBadWidth, [ALevelId, Pad.Sprite, Pad.Width]);

    Result := Result + [Pad];
  end;
end;

end.
