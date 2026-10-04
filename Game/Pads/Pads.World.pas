{
  Pads.World - the level's pads (Levels.Pads) in play: where each one
  stands, what its deck carries, what its body stops, and its picture.

  The world keeps no riders. The hero and the monsters ask it for the
  deck under their feet, and for the deck their feet came down onto in
  a tick; the grid of 2008 goes on answering everything else. On a
  screen without pads every answer is nil or False, so the old rules
  stand alone there.

  The pads stand still for now. The world is born with the level and
  lives through a restart.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.World;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections,
  Sdl2.Core, Render.Sprites, Levels.Pads;

type
  TPad = class
  private
    FPlacement: TPadPlacement;
    FTexture: PSdlTexture;
    FPictureHeight: Integer;
    FLeft, FTop: Double;
    function GetRight: Double;
  public
    constructor Create(const APlacement: TPadPlacement; ATexture: PSdlTexture);
    // The deck spans some of ALeft..ARight, edges included
    function DeckSpans(ALeft, ARight: Double): Boolean;
    // The point lies in the body: the deck's width across, a cell down
    function BodyHolds(AX, AY: Single): Boolean;
    procedure Draw(const ASprites: TSpriteRenderer);

    property Screen: Integer read FPlacement.Screen;
    property Tag: string read FPlacement.Tag;
    property Bullets: TPadBullets read FPlacement.Bullets;
    property Left: Double read FLeft;
    property Right: Double read GetRight;
    // The deck: the feet line of whatever stands on the pad
    property Top: Double read FTop;
  end;

  TPadWorld = class
  private
    FSprites: TSpriteRenderer;
    FPads: TObjectList<TPad>;
  public
    // ACache is the level's object art and must outlive the world; a
    // picture it lacks raises here, at level load
    constructor Create(const ASprites: TSpriteRenderer;
      const ACache: TSpriteCache; const APlacements: TArray<TPadPlacement>);
    destructor Destroy; override;

    // The deck the feet stand on: at AFeetY, spanning some of
    // ALeft..ARight. nil when there is none.
    function DeckUnder(AScreen: Integer; ALeft, ARight,
      AFeetY: Double): TPad;
    // The deck the feet came down onto between two ticks - from APrevY to
    // AFeetY, the highest one when they passed several. AIgnored, which
    // may be nil, is the deck the feet are dropping through: every deck
    // at its height is let by, or a drop on the seam of two pads side by
    // side would land on the neighbour.
    function DeckCrossed(AScreen: Integer; ALeft, ARight, APrevY,
      AFeetY: Double; const AIgnored: TPad): TPad;
    // A body at the point: what stops the boss, the sparks and the debris
    function BodyAt(AScreen: Integer; AX, AY: Single): Boolean;
    // A body at the point that bursts bullets
    function StopsBulletAt(AScreen: Integer; AX, AY: Single): Boolean;
    // nil when no pad carries the tag
    function FindTagged(const ATag: string): TPad;
    procedure Draw(AScreen: Integer);
  end;

implementation

const
  // The feet stand on a deck this close to it: positions are whole
  // units, and a fraction left by arithmetic must not drop a rider
  DeckSlop = 0.5;

// ---------------------------------------------------------------------------
// TPad
// ---------------------------------------------------------------------------

constructor TPad.Create(const APlacement: TPadPlacement;
  ATexture: PSdlTexture);
var
  ArtWidth, ArtHeight: Integer;
begin
  inherited Create;
  FPlacement := APlacement;
  FTexture := ATexture;
  SDL_QueryTexture(ATexture, nil, nil, @ArtWidth, @ArtHeight);
  FPictureHeight := Round(APlacement.Width * ArtHeight / ArtWidth);
  FLeft := APlacement.X;
  FTop := APlacement.Y;
end;

function TPad.GetRight: Double;
begin
  Result := FLeft + FPlacement.Width;
end;

function TPad.DeckSpans(ALeft, ARight: Double): Boolean;
begin
  Result := (ALeft <= Right) and (ARight >= FLeft);
end;

function TPad.BodyHolds(AX, AY: Single): Boolean;
begin
  Result := (AX >= FLeft) and (AX < Right) and (AY >= FTop) and
    (AY < FTop + TileSize);
end;

procedure TPad.Draw(const ASprites: TSpriteRenderer);
var
  Dest: TSdlRect;
begin
  Dest.X := Round(FLeft);
  Dest.Y := Round(FTop);
  Dest.W := FPlacement.Width;
  Dest.H := FPictureHeight;
  TintTexture(FTexture, FPlacement.Tint.R, FPlacement.Tint.G,
    FPlacement.Tint.B);
  ASprites.DrawRect(FTexture, Dest);
end;

// ---------------------------------------------------------------------------
// TPadWorld
// ---------------------------------------------------------------------------

constructor TPadWorld.Create(const ASprites: TSpriteRenderer;
  const ACache: TSpriteCache; const APlacements: TArray<TPadPlacement>);
begin
  inherited Create;
  FSprites := ASprites;
  FPads := TObjectList<TPad>.Create(True);
  for var Placement in APlacements do
    FPads.Add(TPad.Create(Placement, ACache.Get(Placement.Sprite)));
end;

destructor TPadWorld.Destroy;
begin
  FPads.Free;
  inherited;
end;

function TPadWorld.DeckUnder(AScreen: Integer; ALeft, ARight,
  AFeetY: Double): TPad;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and (Abs(Pad.Top - AFeetY) < DeckSlop) and
      Pad.DeckSpans(ALeft, ARight) then
      Exit(Pad);
  Result := nil;
end;

function TPadWorld.DeckCrossed(AScreen: Integer; ALeft, ARight, APrevY,
  AFeetY: Double; const AIgnored: TPad): TPad;
begin
  Result := nil;
  for var Pad in FPads do
  begin
    var DroppedThrough := (AIgnored <> nil) and
      (Abs(Pad.Top - AIgnored.Top) < DeckSlop);
    if DroppedThrough or (Pad.Screen <> AScreen) then
      Continue;
    var Crossed := (APrevY <= Pad.Top) and (AFeetY >= Pad.Top);
    if not Crossed or not Pad.DeckSpans(ALeft, ARight) then
      Continue;
    if (Result = nil) or (Pad.Top < Result.Top) then
      Result := Pad;
  end;
end;

function TPadWorld.BodyAt(AScreen: Integer; AX, AY: Single): Boolean;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and Pad.BodyHolds(AX, AY) then
      Exit(True);
  Result := False;
end;

function TPadWorld.StopsBulletAt(AScreen: Integer; AX, AY: Single): Boolean;
begin
  for var Pad in FPads do
    if (Pad.Screen = AScreen) and (Pad.Bullets = pbBlock) and
      Pad.BodyHolds(AX, AY) then
      Exit(True);
  Result := False;
end;

function TPadWorld.FindTagged(const ATag: string): TPad;
begin
  for var Pad in FPads do
    if Pad.Tag = ATag then
      Exit(Pad);
  Result := nil;
end;

procedure TPadWorld.Draw(AScreen: Integer);
begin
  for var Pad in FPads do
    if Pad.Screen = AScreen then
      Pad.Draw(FSprites);
end;

end.
