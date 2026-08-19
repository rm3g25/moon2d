{
  TitleCard - prints arbitrary text in the game's own bitmap font and
  saves a PNG for the trailer edit.

  Shared units are referenced by relative path instead of a project
  search path, so the tool follows the game around without any IDE
  settings to forget.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
program TitleCard;

uses
  Vcl.Forms,
  Sdl2.Core in '..\..\Sdl2.Core.pas',
  Sdl2.Image in '..\..\Sdl2.Image.pas',
  Sprites.Sets in '..\..\Sprites.Sets.pas',
  Render.Sprites in '..\..\Render.Sprites.pas',
  Render.Font in '..\..\Render.Font.pas',
  Image.Png in 'Image.Png.pas',
  TitleCard.Layout in 'TitleCard.Layout.pas',
  TitleCard.Config in 'TitleCard.Config.pas',
  TitleCard.Renderer in 'TitleCard.Renderer.pas',
  TitleCard.Main in 'TitleCard.Main.pas' {MainForm};

{$R *.res}

begin
  EnsureImageLib;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Moon 2D TitleCard';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
