{
  Game.Fangs - the fangs of a chase: spurs of basalt rising from below the
  bottom edge, riding by right to left on a motion of their own, between
  the near ground and the road, behind the play layer - the posts by the
  road that sell the speed. Separate pictures, nothing to loop.

  They come one after another along their layer, the road between two
  rolled by the dice, and every number of every fang is the dice's: which
  of the kit, how big, how high its top, mirrored or not, a little off the
  common tint. Most are low - their tops down where the near ground already
  hides the feet of the city, so they cover nothing that shows. A few are
  tall, their tops over the city, and never two tall ones on the screen at
  once: the city is what matters. A fang is never too short to reach below
  the bottom edge from its top - it is made bigger, as far as the kit's
  scale lets it, then sunk.

  The first one waits at the right edge from the start: it comes in the
  moment the road runs. A fang sent comes in at the right edge and is let
  go once past the left one.

  TFangRow is the rules: it does not know the belt or SDL - the game hands
  in how far the fangs' layer has ridden (Game.FarPlane). TFangPainter
  draws them, dark in the tunnel and lighter out of it, as the near ground.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Fangs;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Render.Sprites, Levels.FarPlane;

type
  // A fang on its way: X its left edge along the fangs' layer, Top its top
  // on the screen, W and H its size as drawn; Jitter its tint off the
  // common one, percent
  TFang = record
    Kind: Integer;
    // Far along the layer, so to the precision of the road's run
    X: Double;
    Top, W, H: Single;
    Tall: Boolean;
    Mirror: Boolean;
    Jitter: Integer;
  end;

  TFangRow = class
  private
    FDef: TFarPlaneDef;
    FDice: TXorShift;
    // Where along the layer the next fang's left edge goes
    FCursor: Double;
    // The right edge of the last tall one along the layer
    FTallEnd: Double;
    FFangs: TArray<TFang>;
    function RollBetween(ALeast, AMost: Single): Single;
    function RollKind(ATall: Boolean): Integer;
    function HasTallKind: Boolean;
    function NextFang: TFang;
    procedure LetGoPassed(ATravel: Double);
  public
    // ADef - the level's far plane; one without fangs sends none.
    // ASeed - the dice of the scatter
    constructor Create(const ADef: TFarPlaneDef; ASeed: Cardinal);
    // A death, a door, a new level: none sent, the dice new for the new try
    procedure Clear(ASeed: Cardinal);
    // ATravel - how far the fangs' layer has ridden left: the fangs past
    // the left edge go, the ones due by now come in at the right
    procedure Tick(ATravel: Double);
    property Def: TFarPlaneDef read FDef;
    property Fangs: TArray<TFang> read FFangs;
  end;

  TFangPainter = class
  private
    FRenderer: PSdlRenderer;
    FRow: TFangRow;
    // By kind
    FPictures: TArray<PSdlTexture>;
  public
    // Resolves every picture of the kit now, so a sprite the sets lack
    // raises at level load. ACache and ARow belong to the caller and must
    // outlive the painter.
    constructor Create(ARenderer: PSdlRenderer; ACache: TSpriteCache;
      ARow: TFangRow);
    // AOffsets - the far plane's, between ticks: the fangs ride by their
    // own, the tunnel's tells how dark they are
    procedure Draw(const AOffsets: TFarPlaneOffsets);
  end;

implementation

uses
  System.Math;

const
  // An xorshift seeded with zero stays at zero
  NonZeroSeed = 1;
  MirrorShare = 0.5;
  NoTallYet = -MaxInt;

constructor TFangRow.Create(const ADef: TFarPlaneDef; ASeed: Cardinal);
begin
  inherited Create;
  FDef := ADef;
  Clear(ASeed);
end;

procedure TFangRow.Clear(ASeed: Cardinal);
begin
  FDice.Seed := ASeed or NonZeroSeed;
  FCursor := FDef.ScreenWidth;
  FTallEnd := NoTallYet;
  FFangs := [];
end;

function TFangRow.RollBetween(ALeast, AMost: Single): Single;
begin
  Result := ALeast + (AMost - ALeast) * FDice.NextUnit;
end;

function TFangRow.HasTallKind: Boolean;
begin
  Result := False;
  for var Kind in FDef.Fangs.Kinds do
    if Kind.Tall then
      Exit(True);
end;

// Any of the kit for a low one, the kinds that may be tall for a tall one
function TFangRow.RollKind(ATall: Boolean): Integer;
var
  Candidates: TArray<Integer>;
begin
  Candidates := [];
  for var i := 0 to High(FDef.Fangs.Kinds) do
    if FDef.Fangs.Kinds[i].Tall or not ATall then
      Candidates := Candidates + [i];
  var Pick := Min(Trunc(FDice.NextUnit * Length(Candidates)), High(Candidates));
  Result := Candidates[Pick];
end;

function TFangRow.NextFang: TFang;
begin
  var Fangs := FDef.Fangs;
  Result := Default(TFang);
  var TallRoom := FCursor - FTallEnd >= FDef.ScreenWidth;
  Result.Tall := TallRoom and (FDice.NextUnit < Fangs.TallShare) and HasTallKind;
  Result.Kind := RollKind(Result.Tall);
  var Kind := Fangs.Kinds[Result.Kind];

  var Top: Single;
  if Result.Tall then
    Top := RollBetween(Fangs.TallTopHighest, Fangs.TallTopLowest)
  else
    Top := RollBetween(Fangs.LowTopHighest, Fangs.LowTopLowest);
  var Reaching: Single := (FDef.ScreenHeight - Top) / Kind.H;
  var Scale: Single := Max(RollBetween(Fangs.ScaleLeast, Fangs.ScaleMost), Reaching);
  Scale := Min(Scale, Fangs.ScaleMost);
  Result.W := Kind.W * Scale;
  Result.H := Kind.H * Scale;
  Result.Top := Max(Top, FDef.ScreenHeight - Result.H);

  Result.Mirror := FDice.NextUnit < MirrorShare;
  Result.Jitter := Round(RollBetween(-Fangs.TintJitter, Fangs.TintJitter));
  Result.X := FCursor;

  FCursor := FCursor + Result.W + RollBetween(Fangs.GapLeast, Fangs.GapMost);
  if Result.Tall then
    FTallEnd := Result.X + Result.W;
end;

procedure TFangRow.LetGoPassed(ATravel: Double);
var
  Kept: TArray<TFang>;
begin
  Kept := [];
  for var Fang in FFangs do
    if Fang.X + Fang.W - ATravel > 0 then
      Kept := Kept + [Fang];
  FFangs := Kept;
end;

procedure TFangRow.Tick(ATravel: Double);
begin
  if not FDef.Fangs.Present then
    Exit;
  while FCursor - ATravel <= FDef.ScreenWidth do
    FFangs := FFangs + [NextFang];
  LetGoPassed(ATravel);
end;

constructor TFangPainter.Create(ARenderer: PSdlRenderer; ACache: TSpriteCache;
  ARow: TFangRow);
begin
  inherited Create;
  FRenderer := ARenderer;
  FRow := ARow;
  for var Kind in FRow.Def.Fangs.Kinds do
    FPictures := FPictures + [ACache.Get(Kind.Sprite)];
end;

// The kit is shared with the level's own objects, which set their tint on
// every draw, so the colour mod is set here on every draw as well
procedure TFangPainter.Draw(const AOffsets: TFarPlaneOffsets);
var
  Dest: TSdlFRect;
begin
  var Def := FRow.Def;
  for var Fang in FRow.Fangs do
  begin
    Dest.X := Fang.X - AOffsets[fmFangs];
    if (Dest.X >= Def.ScreenWidth) or (Dest.X + Fang.W <= 0) then
      Continue;
    Dest.Y := Fang.Top;
    Dest.W := Fang.W;
    Dest.H := Fang.H;
    var Picture := FPictures[Fang.Kind];
    var Tint := Def.FangTint(Fang.Jitter, AOffsets);
    TintTexture(Picture, Tint.R, Tint.G, Tint.B);
    var Flip: Integer := SdlFlipNone;
    if Fang.Mirror then
      Flip := SdlFlipHorizontal;
    SDL_RenderCopyExF(FRenderer, Picture, nil, @Dest, 0.0, nil, Flip);
  end;
end;

end.
