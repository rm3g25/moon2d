{
  TitleCard.Main - the window around the renderer.

  All measurements in the UI are whole percents on purpose: no decimal
  separator ever reaches a parser, so the tool behaves the same on any
  locale. Preview is always composited over black because that is what a
  card looks like in the edit; the alpha channel only matters in the
  saved file, and the checkbox says so.

  Moon 2D remake. Requires Delphi 12+.
}
unit TitleCard.Main;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  TitleCard.Config, TitleCard.Layout, TitleCard.Renderer;

type
  TMainForm = class(TForm)
    SidePanel: TPanel;
    TextLabel: TLabel;
    TextMemo: TMemo;
    AspectLabel: TLabel;
    AspectCombo: TComboBox;
    ScaleLabel: TLabel;
    ScaleCombo: TComboBox;
    MarginLabel: TLabel;
    MarginEdit: TEdit;
    CenterLabel: TLabel;
    CenterEdit: TEdit;
    SpacingLabel: TLabel;
    SpacingEdit: TEdit;
    BlackBackgroundCheck: TCheckBox;
    WrapCheck: TCheckBox;
    UniformBatchCheck: TCheckBox;
    StatusLabel: TLabel;
    RenderButton: TButton;
    SaveButton: TButton;
    BatchButton: TButton;
    PreviewPanel: TPanel;
    PreviewImage: TImage;
    SavePngDialog: TSaveDialog;
    OpenTextDialog: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SettingsChanged(Sender: TObject);
    procedure RenderButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure BatchButtonClick(Sender: TObject);
  private
    FConfig: TTitleCardConfig;
    FRenderer: TCardRenderer;
    FCardBitmap: TBitmap;
    procedure FillCombos;
    procedure ApplyConfigToUi;
    function ReadGeometry: TCardGeometry;
    function ReadScale: TCardScale;
    function ReadBackground: TCardBackground;
    function BuildLayout(const AText: string;
      const AScale: TCardScale): TCardLayout;
    function RenderCardBytes(const ALayout: TCardLayout): TBytes;
    procedure ShowStatus(const ALayout: TCardLayout);
    procedure UpdatePreview;
    procedure UpdatePreviewImage;
    function BatchScaleFor(const ACards: TArray<string>): TCardScale;
    procedure DisableRendering(const AReason: string);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  // Winapi.Windows brings its own TBitmap (tagBITMAP) and, being listed
  // AFTER the interface uses, shadows Vcl.Graphics.TBitmap everywhere in
  // this section - hence the fully qualified spellings below.
  Winapi.Windows, System.Types, System.Math, System.IOUtils,
  Render.Font, Image.Png;

resourcestring
  SAtlasMissing = 'fonty.png not found next to the tool or up to six ' +
    'folders above it. Point [Paths] Atlas in %s at it.';
  SStatusFits = 'Scale x%.2f (cell %d px) - up to %d characters per line.';
  SStatusOver = 'Line %d is %d characters over the margin.';
  SStatusBelowNative = 'Below x1: glyphs are downscaled, the bitmap ' +
    'font will smear. Break the line or widen the card.';
  SBatchDone = '%d cards written to %s';
  SBatchEmpty = 'No cards found: separate them with a blank line.';
  SNoRenderer = 'Rendering is unavailable: %s';

const
  ScaleAutoInteger = 0; // combo item order
  ScaleAutoFree = 1;
  ScaleFirstFixed = 2;
  MaxFixedScaleSteps = 6;
  PreviewMargin = 8;
  BatchFolderName = 'cards';

type
  TCardPreset = record
    Caption: string;
    Width: Integer;
    Height: Integer;
  end;

const
  CardPresets: array [0..3] of TCardPreset = (
    (Caption: '1920 x 1080  (16:9)'; Width: 1920; Height: 1080),
    (Caption: '1080 x 1440  (3:4)'; Width: 1080; Height: 1440),
    (Caption: '1080 x 1080  (1:1)'; Width: 1080; Height: 1080),
    (Caption: '1080 x 1920  (9:16)'; Width: 1080; Height: 1920));

// ---------------------------------------------------------------------------
// Pixel plumbing
// ---------------------------------------------------------------------------

// SDL hands back R,G,B,A; a 24-bit DIB scanline wants B,G,R. Alpha is
// dropped here on purpose - the preview lives on black.
procedure RgbaToBitmap(const APixels: TBytes; AWidth, AHeight: Integer;
  const ABitmap: Vcl.Graphics.TBitmap);
begin
  ABitmap.PixelFormat := pf24bit;
  ABitmap.SetSize(AWidth, AHeight);
  for var y := 0 to AHeight - 1 do
  begin
    var Target := PByte(ABitmap.ScanLine[y]);
    var Source := PByte(@APixels[y * AWidth * 4]);
    for var x := 0 to AWidth - 1 do
    begin
      Target[0] := Source[2];
      Target[1] := Source[1];
      Target[2] := Source[0];
      Inc(Target, 3);
      Inc(Source, 4);
    end;
  end;
end;

// HALFTONE makes StretchDraw average instead of dropping pixels; without
// it a 1920 px card squeezed into a 600 px preview loses whole glyph
// rows and the font looks broken when it is not.
procedure DrawScaled(const ASource, ATarget: Vcl.Graphics.TBitmap);
begin
  SetStretchBltMode(ATarget.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(ATarget.Canvas.Handle, 0, 0, nil);
  ATarget.Canvas.StretchDraw(Rect(0, 0, ATarget.Width, ATarget.Height),
    ASource);
end;

function FitInside(AWidth, AHeight, ABoxWidth, ABoxHeight: Integer): TPoint;
begin
  if (AWidth <= 0) or (AHeight <= 0) then
    Exit(Point(1, 1));
  var Factor := Min(ABoxWidth / AWidth, ABoxHeight / AHeight);
  Result.X := Max(1, Round(AWidth * Factor));
  Result.Y := Max(1, Round(AHeight * Factor));
end;

// ---------------------------------------------------------------------------
// TMainForm
// ---------------------------------------------------------------------------

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCardBitmap := Vcl.Graphics.TBitmap.Create;
  PreviewImage.Picture.Bitmap.PixelFormat := pf24bit;

  FConfig := LoadTitleCardConfig;
  FillCombos;
  ApplyConfigToUi;

  if not FConfig.IsUsable then
  begin
    DisableRendering(Format(SAtlasMissing, [ConfigFileName]));
    Exit;
  end;

  try
    FRenderer := TCardRenderer.Create(FConfig.AtlasFileName,
      FConfig.RenderDriver);
  except
    on E: Exception do
    begin
      DisableRendering(E.Message);
      Exit;
    end;
  end;
  UpdatePreview;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FRenderer.Free;
  FCardBitmap.Free;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  UpdatePreviewImage;
end;

procedure TMainForm.DisableRendering(const AReason: string);
begin
  StatusLabel.Caption := Format(SNoRenderer, [AReason]);
  RenderButton.Enabled := False;
  SaveButton.Enabled := False;
  BatchButton.Enabled := False;
end;

procedure TMainForm.FillCombos;
begin
  AspectCombo.Items.BeginUpdate;
  try
    AspectCombo.Items.Clear;
    for var Preset in CardPresets do
      AspectCombo.Items.Add(Preset.Caption);
  finally
    AspectCombo.Items.EndUpdate;
  end;

  ScaleCombo.Items.BeginUpdate;
  try
    ScaleCombo.Items.Clear;
    ScaleCombo.Items.Add('Auto - whole steps');
    ScaleCombo.Items.Add('Auto - free');
    for var i := 1 to MaxFixedScaleSteps do
      ScaleCombo.Items.Add(Format('x%d  (cell %d px)',
        [i, i * FontCellPx]));
  finally
    ScaleCombo.Items.EndUpdate;
  end;
end;

procedure TMainForm.ApplyConfigToUi;
begin
  AspectCombo.ItemIndex := 0;
  for var i := 0 to High(CardPresets) do
    if (CardPresets[i].Width = FConfig.Geometry.Width) and
       (CardPresets[i].Height = FConfig.Geometry.Height) then
      AspectCombo.ItemIndex := i;

  if (FConfig.ScaleSteps >= 1) and
     (FConfig.ScaleSteps <= MaxFixedScaleSteps) then
    ScaleCombo.ItemIndex := ScaleFirstFixed + FConfig.ScaleSteps - 1
  else
    ScaleCombo.ItemIndex := ScaleAutoInteger;

  MarginEdit.Text :=
    IntToStr(Round(FConfig.Geometry.MarginFraction * 100));
  CenterEdit.Text :=
    IntToStr(Round(FConfig.Geometry.OpticalCenterFraction * 100));
  SpacingEdit.Text := IntToStr(Round(FConfig.Geometry.LineSpacing * 100));
  UniformBatchCheck.Checked := FConfig.UniformBatchScale;
end;

function TMainForm.ReadGeometry: TCardGeometry;
begin
  Result := FConfig.Geometry;
  var Preset := CardPresets[Max(0, AspectCombo.ItemIndex)];
  Result.Width := Preset.Width;
  Result.Height := Preset.Height;
  Result.MarginFraction := StrToIntDef(MarginEdit.Text, 15) / 100;
  Result.OpticalCenterFraction := StrToIntDef(CenterEdit.Text, 45) / 100;
  Result.LineSpacing := StrToIntDef(SpacingEdit.Text, 160) / 100;
end;

function TMainForm.ReadScale: TCardScale;
begin
  if ScaleCombo.ItemIndex >= ScaleFirstFixed then
    Result := TCardScale.Steps(ScaleCombo.ItemIndex - ScaleFirstFixed + 1)
  else if ScaleCombo.ItemIndex = ScaleAutoFree then
    Result := TCardScale.FitFree
  else
    Result := TCardScale.FitInteger;
end;

function TMainForm.ReadBackground: TCardBackground;
begin
  if BlackBackgroundCheck.Checked then
    Result := cbBlack
  else
    Result := cbTransparent;
end;

function TMainForm.BuildLayout(const AText: string;
  const AScale: TCardScale): TCardLayout;
begin
  var Geometry := ReadGeometry;
  Result := BuildCardLayout(FRenderer.Font, AText, Geometry, AScale);
  if not (WrapCheck.Checked and Result.HasOverflow) then
    Exit;
  // Emergency wrap: re-break at the cell height we just settled on, then
  // lay the card out again - one extra line can change the fit.
  var Wrapped := WrapCardText(AText, Geometry, Result.CellHeight);
  Result := BuildCardLayout(FRenderer.Font, Wrapped, Geometry, AScale);
end;

function TMainForm.RenderCardBytes(const ALayout: TCardLayout): TBytes;
begin
  var Geometry := ReadGeometry;
  Result := FRenderer.RenderCard(ALayout, Geometry.Width, Geometry.Height,
    ReadBackground);
end;

procedure TMainForm.ShowStatus(const ALayout: TCardLayout);
var
  Report: string;
begin
  Report := Format(SStatusFits, [ALayout.ScaleSteps,
    Round(ALayout.CellHeight), ALayout.CharLimit]);
  for var i := 0 to High(ALayout.Lines) do
    if ALayout.Lines[i].OverflowChars > 0 then
      Report := Report + sLineBreak +
        Format(SStatusOver, [i + 1, ALayout.Lines[i].OverflowChars]);
  if ALayout.ScaleSteps < 1 then
    Report := Report + sLineBreak + SStatusBelowNative;
  StatusLabel.Caption := Report;
end;

procedure TMainForm.UpdatePreview;
begin
  if not Assigned(FRenderer) then
    Exit;
  var Layout := BuildLayout(TextMemo.Lines.Text, ReadScale);
  var Geometry := ReadGeometry;
  RgbaToBitmap(RenderCardBytes(Layout), Geometry.Width, Geometry.Height,
    FCardBitmap);
  ShowStatus(Layout);
  UpdatePreviewImage;
end;

procedure TMainForm.UpdatePreviewImage;
begin
  if (FCardBitmap = nil) or (FCardBitmap.Width = 0) then
    Exit;
  var Box := FitInside(FCardBitmap.Width, FCardBitmap.Height,
    Max(1, PreviewPanel.ClientWidth - 2 * PreviewMargin),
    Max(1, PreviewPanel.ClientHeight - 2 * PreviewMargin));
  var Preview := PreviewImage.Picture.Bitmap;
  Preview.PixelFormat := pf24bit;
  Preview.SetSize(Box.X, Box.Y);
  DrawScaled(FCardBitmap, Preview);
  PreviewImage.Invalidate;
end;

procedure TMainForm.SettingsChanged(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TMainForm.RenderButtonClick(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TMainForm.SaveButtonClick(Sender: TObject);
begin
  if not SavePngDialog.Execute then
    Exit;
  var Layout := BuildLayout(TextMemo.Lines.Text, ReadScale);
  var Geometry := ReadGeometry;
  SavePngRgba(SavePngDialog.FileName, RenderCardBytes(Layout),
    Geometry.Width, Geometry.Height);
end;

// One scale for the whole batch: the smallest that every card can hold.
// Cards of wandering type size read as an accident, not as a trailer.
function TMainForm.BatchScaleFor(const ACards: TArray<string>): TCardScale;
begin
  Result := ReadScale;
  if (Result.Mode = smExplicit) or not UniformBatchCheck.Checked then
    Exit;

  var Smallest: Double := MaxDouble;
  for var Card in ACards do
    Smallest := Min(Smallest, BuildLayout(Card, Result).CellHeight);
  if Smallest < MaxDouble then
    Result := TCardScale.Explicit(Smallest);
end;

procedure TMainForm.BatchButtonClick(Sender: TObject);
var
  Cards: TArray<string>;
begin
  if not OpenTextDialog.Execute then
    Exit;

  Cards := SplitCards(TFile.ReadAllText(OpenTextDialog.FileName,
    TEncoding.UTF8));
  if Length(Cards) = 0 then
  begin
    ShowMessage(SBatchEmpty);
    Exit;
  end;

  var Folder := TPath.Combine(
    TPath.GetDirectoryName(OpenTextDialog.FileName), BatchFolderName);
  TDirectory.CreateDirectory(Folder);

  var Scale := BatchScaleFor(Cards);
  var Geometry := ReadGeometry;
  for var i := 0 to High(Cards) do
  begin
    var Layout := BuildLayout(Cards[i], Scale);
    SavePngRgba(
      TPath.Combine(Folder, Format(FConfig.BatchPattern, [i + 1])),
      RenderCardBytes(Layout), Geometry.Width, Geometry.Height);
  end;
  ShowMessage(Format(SBatchDone, [Length(Cards), Folder]));
end;

end.
