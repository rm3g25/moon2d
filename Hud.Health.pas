{
  Hud.Health - the hero's health display, one class per era. The game
  holds a THealthHud and never asks which one; the composition root
  picks the class when a level loads.

  THealthIcons is the 2008 display: one orb sprite per health point,
  top-left (heroes\health.bmp of the original, now the 'health' sprite
  of hero.mset). The remake's display lives in Hud.Vitals.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Hud.Health;
{$I Moon2D.inc}

interface

uses
  Sdl2.Core, Sprites.Sets, Render.Sprites;

type
  THealthHud = class abstract
  public
    // Once per logic tick, with the hero's health as of now
    procedure Tick(AHealth: Integer; AInvulnerable: Boolean); virtual; abstract;
    procedure Draw; virtual; abstract;
  end;

  THealthIcons = class(THealthHud)
  private
    FSprites: TSpriteRenderer;
    FSpriteSet: TSpriteSet;
    FCache: TSpriteCache;
    FHealth: Integer;
  public
    constructor Create(ARenderer: PSdlRenderer; ASprites: TSpriteRenderer);
    destructor Destroy; override;
    procedure Tick(AHealth: Integer; AInvulnerable: Boolean); override;
    procedure Draw; override;
  end;

implementation

const
  IconSpriteSet = 'hero';
  IconSprite = 'health';
  IconX = 4;
  IconY = 4;
  IconSize = 16;
  IconStep = 18;

constructor THealthIcons.Create(ARenderer: PSdlRenderer;
  ASprites: TSpriteRenderer);
begin
  inherited Create;
  FSprites := ASprites;
  FSpriteSet := TSpriteSet.Create(SpriteSetsDir + IconSpriteSet + '.mset');
  FCache := TSpriteCache.Create(ARenderer);
  FCache.AttachSpriteSet(FSpriteSet);
end;

destructor THealthIcons.Destroy;
begin
  FCache.Free;
  FSpriteSet.Free;
  inherited;
end;

procedure THealthIcons.Tick(AHealth: Integer; AInvulnerable: Boolean);
begin
  FHealth := AHealth;
end;

procedure THealthIcons.Draw;
var
  Dest: TSdlRect;
begin
  var Icon := FCache.Get(IconSprite);
  for var i := 0 to FHealth - 1 do
  begin
    Dest.X := IconX + i * IconStep;
    Dest.Y := IconY;
    Dest.W := IconSize;
    Dest.H := IconSize;
    FSprites.DrawRect(Icon, Dest);
  end;
end;

end.
