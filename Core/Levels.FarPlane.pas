{
  Levels.FarPlane - the far plane of a chase as data: a strip of layers
  riding left behind the play layer at speeds of their own, and a sun that
  stands still under them all.

  A level names the screen and the layout file in its "farPlane" section,
  as "screen" and "layout" (chase-backdrop.json for level 2). The layout
  lies beside the level file and is the one tools/chase/build_stand.py
  plays on the stand, so a number tuned there is the number the game
  plays. Its pictures are the set named as the layout file without its
  extension, which the level lists among its "objectSets".

  A layer is a seamless band, repeated across, and elements standing on
  it: x their left edge along the layer, y their feet, w their width in
  units, the height following the picture. A band may start at an x of its
  layer, its left end fading in. Each layer rides by one of four motions -
  the near ground, the tunnel, the city, the ridge; how fast each runs is
  Game.FarPlane's business. An element marked "existing" is the screen's
  own backdrop, riding with its layer. The keys only the stand reads (the
  road's speed and ramp, the cliff's edge marks) are let be.

  The fangs are no layer: separate pictures of basalt rising from below
  the bottom edge, riding by on a motion of their own between the near
  ground and the road, behind the play layer. The "fangs" section gives
  their kit and the numbers of their scatter - scale, the road between
  two, where the top of a low one and of a tall one stands, how many are
  tall, their tint in the tunnel and outside; the speed is the "fangs" of
  the speeds. Where each one stands is Game.Fangs' business. A layout
  without the section has no fangs.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.FarPlane;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Render.Brush, Levels.Tint;

type
  EFarPlaneError = class(Exception);

  TFarPlaneMotion = (fmRidge, fmCity, fmTunnel, fmGround, fmFangs);

  // How far each motion has taken its layers to the left, in units
  TFarPlaneOffsets = array [TFarPlaneMotion] of Double;

  TFarPlaneSun = record
    X, Y: Single;
    // Radii, units
    Disc, Halo: Single;
    White, Tint: TRgb;
    // Over how many units at each end of a dome the sun turns its colour
    TintRamp: Single;
  end;

  // Units a second; the shares are of another layer's speed
  TFarPlaneSpeeds = record
    TunnelPeak: Single;
    TunnelCruise: Single;
    EaseSec: Single;
    CityShareInTunnel: Single;
    CityCruise: Single;
    CityBrakeZone: Single;
    CityLeast: Single;
    RidgeShareOfCity: Single;
    Ground: Single;
    Fangs: Single;
  end;

  TFarPlaneBand = record
    Present: Boolean;
    Texture: string;
    Top, Bottom: Single;
    // Over how many units its top fades in
    FadeTop: Single;
    // The band starts at this x of its layer; -1 = it runs the whole width
    From: Single;
    // Over how many units from its start it fades in
    FeatherLeft: Single;
    // How much of its colour it keeps while the tunnel is all on the
    // screen; it brightens to the full as the tunnel leaves. 1 - always full
    ShadeInTunnel: Single;
  end;

  TFarPlaneElement = record
    Id: string;
    X, Y, W, H: Single;
    // 0..1, how much of its colour the picture keeps
    Shade: Single;
    TintsSun: Boolean;
    // Over how many units its left end fades in
    FeatherLeft: Single;
    // Drawn left for right: the light of a picture lit from the wrong side
    Mirror: Boolean;
    // The screen's own backdrop, not a picture of the set
    Backdrop: Boolean;
  end;

  TFarPlaneLayer = record
    Id: string;
    Motion: TFarPlaneMotion;
    // Units along the layer; 0 = no end of its own
    Length: Single;
    Band: TFarPlaneBand;
    Elements: TArray<TFarPlaneElement>;
  end;

  // A picture of the fangs' kit: its size in units at the scale of 1
  TFangKind = record
    Sprite: string;
    W, H: Single;
    // May stand as a tall one, its top over the city
    Tall: Boolean;
  end;

  TFarPlaneFangs = record
    Kinds: TArray<TFangKind>;
    ScaleLeast, ScaleMost: Single;
    // The road between two fangs along their layer, edge to edge
    GapLeast, GapMost: Single;
    // Where the top of a low one and of a tall one may stand, y down
    LowTopHighest, LowTopLowest: Single;
    TallTopHighest, TallTopLowest: Single;
    // 0..1, of the fangs the dice make tall
    TallShare: Single;
    TintInTunnel, Tint: TColorTint;
    // How far a fang's tint may stray from the common one, percent
    TintJitter: Integer;
    function Present: Boolean;
  end;

  TFarPlaneDef = record
    // 1-based; 0 - the level has no far plane
    Screen: Integer;
    SetName: string;
    ScreenWidth, ScreenHeight: Single;
    Sun: TFarPlaneSun;
    Speeds: TFarPlaneSpeeds;
    // Back to front
    Layers: TArray<TFarPlaneLayer>;
    Fangs: TFarPlaneFangs;
    function Present: Boolean;
    // The length of the city's layer: where the strip ends
    function CityLength: Single;
    // Where the tunnel's last element ends along its layer: once that is
    // past the left edge, the tunnel is gone
    function TunnelEnd: Single;
    // How far the domes before the sun have turned it, 0 (white) .. 1
    function SunCover(const AOffsets: TFarPlaneOffsets): Single;
    // How much of the tunnel has left the screen, 0 .. 1
    function TunnelPassed(const AOffsets: TFarPlaneOffsets): Single;
    // How much of its colour a band keeps where the offsets have taken it
    function BandShade(const ABand: TFarPlaneBand;
      const AOffsets: TFarPlaneOffsets): Single;
    // The sprite of the set a picture is drawn from
    function SpriteName(const AId: string): string;
    // A fang's tint where the offsets have taken it: as dark as in the
    // tunnel while the tunnel is all on the screen, the common one once it
    // has left; AJitter percent off it
    function FangTint(AJitter: Integer; const AOffsets: TFarPlaneOffsets): TColorTint;
  end;

// The "farPlane" section of a level and its layout; absent = no far plane.
// ALevelDir - where the layout lies. A layout that is missing or does not
// read, a layer of an unknown speed, an element without width, a city
// without length and fangs that cannot be scattered raise.
function ReadFarPlane(const ARoot: TJSONObject;
  const ALevelId, ALevelDir: string): TFarPlaneDef;

implementation

uses
  System.Generics.Collections, System.IOUtils, System.Math;

resourcestring
  SFarPlaneNoLayout = 'Level "%s": the layout of its far plane "%s" is missing';
  SFarPlaneBadLayout = 'Level "%s": the layout of its far plane "%s" does not read';
  SFarPlaneBadSpeed = 'Level "%s": far plane layer "%s" takes speed "%s" - '
    + 'ridge, city, tunnel or ground';
  SFarPlaneBadElement = 'Level "%s": far plane element "%s" is %g units wide';
  SFarPlaneNoCity = 'Level "%s": its far plane has no city layer with a length';
  SFarPlaneBadColor = 'Level "%s": far plane sun colour "%s" is not three bytes';
  SFarPlaneNoFangs = 'Level "%s": the fangs of its far plane have an empty kit';
  SFarPlaneBadFang = 'Level "%s": fang "%s" is %g by %g units';
  SFarPlaneBadRange = 'Level "%s": fangs "%s" takes two numbers, the least first';
  SFarPlaneBadScale = 'Level "%s": fangs "scale" must be above zero';

const
  FullShade = 1.0;
  NoBandStart = -1;

function TFarPlaneDef.Present: Boolean;
begin
  Result := Screen > 0;
end;

function TFarPlaneDef.CityLength: Single;
begin
  Result := 0;
  for var Layer in Layers do
    if Layer.Motion = fmCity then
      Result := Max(Result, Layer.Length);
end;

function TFarPlaneDef.TunnelEnd: Single;
begin
  Result := 0;
  for var Layer in Layers do
    if Layer.Motion = fmTunnel then
      for var Element in Layer.Elements do
      begin
        var Right: Single := Element.X + Element.W;
        Result := Max(Result, Right);
      end;
end;

// Deepest of the domes: the sun is as covered as the dome it is furthest
// inside, ramped in over TintRamp at each end of its span
function TFarPlaneDef.SunCover(const AOffsets: TFarPlaneOffsets): Single;
begin
  Result := 0;
  if Sun.TintRamp <= 0 then
    Exit;
  for var Layer in Layers do
    for var Element in Layer.Elements do
    begin
      if not Element.TintsSun then
        Continue;
      var Left: Double := Element.X - AOffsets[Layer.Motion];
      var FromLeftEdge: Double := Sun.X - Left;
      var ToRightEdge: Double := Left + Element.W - Sun.X;
      var Share: Single := EnsureRange(Min(FromLeftEdge, ToRightEdge) / Sun.TintRamp, 0.0, 1.0);
      Result := Max(Result, Share);
    end;
end;

function TFarPlaneDef.TunnelPassed(const AOffsets: TFarPlaneOffsets): Single;
begin
  var Passed: Double := 1;
  if TunnelEnd > 0 then
    Passed := AOffsets[fmTunnel] / TunnelEnd;
  Result := EnsureRange(Passed, 0.0, 1.0);
end;

function TFarPlaneDef.BandShade(const ABand: TFarPlaneBand;
  const AOffsets: TFarPlaneOffsets): Single;
begin
  Result := ABand.ShadeInTunnel + (1 - ABand.ShadeInTunnel) * TunnelPassed(AOffsets);
end;

function TFarPlaneDef.SpriteName(const AId: string): string;
begin
  Result := SetName + ':' + AId;
end;

function TFarPlaneDef.FangTint(AJitter: Integer;
  const AOffsets: TFarPlaneOffsets): TColorTint;

  function Channel(AInTunnel, AOutside: Byte; APassed: Single): Byte;
  begin
    var Level: Integer := Round(AInTunnel + (AOutside - AInTunnel) * APassed) + AJitter;
    Result := EnsureRange(Level, 0, 100);
  end;

begin
  var Passed := TunnelPassed(AOffsets);
  Result.R := Channel(Fangs.TintInTunnel.R, Fangs.Tint.R, Passed);
  Result.G := Channel(Fangs.TintInTunnel.G, Fangs.Tint.G, Passed);
  Result.B := Channel(Fangs.TintInTunnel.B, Fangs.Tint.B, Passed);
end;

function TFarPlaneFangs.Present: Boolean;
begin
  Result := Length(Kinds) > 0;
end;

function ParseMotion(const AWord, ALevelId, ALayerId: string): TFarPlaneMotion;
begin
  if AWord = 'ridge' then
    Result := fmRidge
  else if AWord = 'city' then
    Result := fmCity
  else if AWord = 'tunnel' then
    Result := fmTunnel
  else if AWord = 'ground' then
    Result := fmGround
  else
    raise EFarPlaneError.CreateFmt(SFarPlaneBadSpeed, [ALevelId, ALayerId, AWord]);
end;

function ReadColor(const AObj: TJSONObject; const AKey, ALevelId: string): TRgb;
var
  Channels: TJSONArray;
begin
  if not AObj.TryGetValue<TJSONArray>(AKey, Channels) or (Channels.Count <> 3) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadColor, [ALevelId, AKey]);
  Result.R := EnsureRange(Channels.Items[0].GetValue<Integer>, 0, 255);
  Result.G := EnsureRange(Channels.Items[1].GetValue<Integer>, 0, 255);
  Result.B := EnsureRange(Channels.Items[2].GetValue<Integer>, 0, 255);
end;

function ReadSun(const AObj: TJSONObject; const ALevelId: string): TFarPlaneSun;
begin
  Result.X := AObj.GetValue<Double>('x');
  Result.Y := AObj.GetValue<Double>('y');
  Result.Disc := AObj.GetValue<Double>('disc');
  Result.Halo := AObj.GetValue<Double>('halo');
  Result.White := ReadColor(AObj, 'white', ALevelId);
  Result.Tint := ReadColor(AObj, 'tint', ALevelId);
  Result.TintRamp := AObj.GetValue<Double>('tintRamp', 0);
end;

function ReadSpeeds(const AObj: TJSONObject): TFarPlaneSpeeds;
begin
  Result.TunnelPeak := AObj.GetValue<Double>('tunnelPeak');
  Result.TunnelCruise := AObj.GetValue<Double>('tunnelCruise');
  Result.EaseSec := AObj.GetValue<Double>('easeSec');
  Result.CityShareInTunnel := AObj.GetValue<Double>('cityShareInTunnel');
  Result.CityCruise := AObj.GetValue<Double>('cityCruise');
  Result.CityBrakeZone := AObj.GetValue<Double>('cityBrakeZone');
  Result.CityLeast := AObj.GetValue<Double>('cityLeast');
  Result.RidgeShareOfCity := AObj.GetValue<Double>('ridgeShareOfCity');
  Result.Ground := AObj.GetValue<Double>('ground', 0);
  Result.Fangs := AObj.GetValue<Double>('fangs', 0);
end;

function ReadBand(const ALayer: TJSONObject): TFarPlaneBand;
var
  Obj: TJSONObject;
begin
  Result := Default(TFarPlaneBand);
  Result.From := NoBandStart;
  if not ALayer.TryGetValue<TJSONObject>('band', Obj) then
    Exit;
  Result.Present := True;
  Result.Texture := Obj.GetValue<string>('texture');
  Result.Top := Obj.GetValue<Double>('top');
  Result.Bottom := Obj.GetValue<Double>('bottom');
  Result.FadeTop := Obj.GetValue<Double>('fadeTop', 0);
  Result.From := Obj.GetValue<Double>('from', NoBandStart);
  Result.FeatherLeft := Obj.GetValue<Double>('featherLeft', 0);
  Result.ShadeInTunnel := EnsureRange(Obj.GetValue<Double>('shadeInTunnel', FullShade),
    0.0, 1.0);
end;

function ReadElement(const AObj: TJSONObject; const ALevelId: string): TFarPlaneElement;
begin
  Result.Id := AObj.GetValue<string>('id');
  Result.X := AObj.GetValue<Double>('x');
  Result.Y := AObj.GetValue<Double>('y');
  Result.W := AObj.GetValue<Double>('w');
  Result.H := AObj.GetValue<Double>('h', 0);
  if Result.W <= 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadElement, [ALevelId, Result.Id, Result.W]);
  Result.Shade := EnsureRange(AObj.GetValue<Double>('shade', FullShade), 0.0, 1.0);
  Result.TintsSun := AObj.GetValue<Boolean>('tintsSun', False);
  Result.FeatherLeft := AObj.GetValue<Double>('featherLeft', 0);
  Result.Mirror := AObj.GetValue<Boolean>('mirror', False);
  Result.Backdrop := AObj.GetValue<string>('existing', '') <> '';
end;

function ReadLayer(const AObj: TJSONObject; const ALevelId: string): TFarPlaneLayer;
var
  Items: TJSONArray;
begin
  Result.Id := AObj.GetValue<string>('id');
  Result.Motion := ParseMotion(AObj.GetValue<string>('speed'), ALevelId, Result.Id);
  Result.Length := AObj.GetValue<Double>('length', 0);
  Result.Band := ReadBand(AObj);
  Result.Elements := [];
  if AObj.TryGetValue<TJSONArray>('elements', Items) then
    for var Item in Items do
      Result.Elements := Result.Elements + [ReadElement(Item as TJSONObject, ALevelId)];
end;

procedure ReadRange(const AObj: TJSONObject; const AKey, ALevelId: string;
  out ALeast, AMost: Single);
var
  Pair: TJSONArray;
begin
  if not AObj.TryGetValue<TJSONArray>(AKey, Pair) or (Pair.Count <> 2) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadRange, [ALevelId, AKey]);
  ALeast := Pair.Items[0].GetValue<Double>;
  AMost := Pair.Items[1].GetValue<Double>;
  if ALeast > AMost then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadRange, [ALevelId, AKey]);
end;

function ReadFangKind(const AObj: TJSONObject; const ALevelId: string): TFangKind;
begin
  Result.Sprite := AObj.GetValue<string>('sprite');
  Result.W := AObj.GetValue<Double>('w', 0);
  Result.H := AObj.GetValue<Double>('h', 0);
  Result.Tall := AObj.GetValue<Boolean>('tall', False);
  if (Result.W <= 0) or (Result.H <= 0) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadFang,
      [ALevelId, Result.Sprite, Result.W, Result.H]);
end;

function ReadFangs(const ARoot: TJSONObject; const ALevelId: string): TFarPlaneFangs;
var
  Obj: TJSONObject;
  Kit: TJSONArray;
begin
  Result := Default(TFarPlaneFangs);
  if not ARoot.TryGetValue<TJSONObject>('fangs', Obj) then
    Exit;
  if Obj.TryGetValue<TJSONArray>('kit', Kit) then
    for var Item in Kit do
      Result.Kinds := Result.Kinds + [ReadFangKind(Item as TJSONObject, ALevelId)];
  if not Result.Present then
    raise EFarPlaneError.CreateFmt(SFarPlaneNoFangs, [ALevelId]);
  ReadRange(Obj, 'scale', ALevelId, Result.ScaleLeast, Result.ScaleMost);
  if Result.ScaleLeast <= 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadScale, [ALevelId]);
  ReadRange(Obj, 'gap', ALevelId, Result.GapLeast, Result.GapMost);
  if Result.GapLeast < 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadRange, [ALevelId, 'gap']);
  ReadRange(Obj, 'lowTop', ALevelId, Result.LowTopHighest, Result.LowTopLowest);
  ReadRange(Obj, 'tallTop', ALevelId, Result.TallTopHighest, Result.TallTopLowest);
  Result.TallShare := EnsureRange(Obj.GetValue<Double>('tallShare', 0), 0.0, 1.0);
  Result.TintInTunnel := ReadTint(Obj, 'fangs', 'tintInTunnel');
  Result.Tint := ReadTint(Obj, 'fangs');
  Result.TintJitter := Obj.GetValue<Integer>('tintJitter', 0);
end;

function ReadLayout(const AFileName, ALevelId: string): TFarPlaneDef;
begin
  Result := Default(TFarPlaneDef);
  if not FileExists(AFileName) then
    raise EFarPlaneError.CreateFmt(SFarPlaneNoLayout, [ALevelId, AFileName]);
  var Root := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8)) as TJSONObject;
  if Root = nil then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadLayout, [ALevelId, AFileName]);
  try
    var ScreenObj := Root.GetValue<TJSONObject>('screen');
    Result.ScreenWidth := ScreenObj.GetValue<Double>('w');
    Result.ScreenHeight := ScreenObj.GetValue<Double>('h');
    Result.Sun := ReadSun(Root.GetValue<TJSONObject>('sun'), ALevelId);
    Result.Speeds := ReadSpeeds(Root.GetValue<TJSONObject>('speeds'));
    for var Item in Root.GetValue<TJSONArray>('layers') do
      Result.Layers := Result.Layers + [ReadLayer(Item as TJSONObject, ALevelId)];
    Result.Fangs := ReadFangs(Root, ALevelId);
  finally
    Root.Free;
  end;
  if Result.CityLength <= 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneNoCity, [ALevelId]);
end;

function ReadFarPlane(const ARoot: TJSONObject;
  const ALevelId, ALevelDir: string): TFarPlaneDef;
var
  Section: TJSONObject;
begin
  Result := Default(TFarPlaneDef);
  if not ARoot.TryGetValue<TJSONObject>('farPlane', Section) then
    Exit;
  var LayoutFile := Section.GetValue<string>('layout');
  Result := ReadLayout(TPath.Combine(ALevelDir, LayoutFile), ALevelId);
  Result.Screen := Section.GetValue<Integer>('screen');
  Result.SetName := TPath.GetFileNameWithoutExtension(LayoutFile);
end;

end.
