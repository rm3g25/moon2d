{
  Moon2D - entry point of the remake.

  Reads the config and the language, finds the levels on disk and runs
  the game (TMoonGame, Game.Moon) in the SDL host.
}
program Moon2D;

{$APPTYPE GUI}
{$I Moon2D.inc}

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  Sdl2.Core in 'Core\Sdl2.Core.pas',
  Sdl2.Image in 'Core\Sdl2.Image.pas',
  Sprites.Sets in 'Core\Sprites.Sets.pas',
  Game.Config in 'Core\Game.Config.pas',
  Game.Version in 'Game\Game.Version.pas',
  Game.Loop in 'Game\Game.Loop.pas',
  Monsters.Defs in 'Core\Monsters.Defs.pas',
  Render.Sprites in 'Core\Render.Sprites.pas',
  Levels.Tint in 'Core\Levels.Tint.pas',
  Levels.Dynamics in 'Core\Levels.Dynamics.pas',
  Levels.Defs in 'Core\Levels.Defs.pas',
  Levels.Events in 'Core\Levels.Events.pas',
  Levels.Scenes in 'Core\Levels.Scenes.pas',
  Levels.Pads in 'Core\Levels.Pads.pas',
  Levels.Carousels in 'Core\Levels.Carousels.pas',
  Levels.Rigs in 'Core\Levels.Rigs.pas',
  Render.Tiles in 'Core\Render.Tiles.pas',
  Render.Objects in 'Core\Render.Objects.pas',
  Render.Puff in 'Core\Render.Puff.pas',
  Effects.Emitter in 'Core\Effects.Emitter.pas',
  Effects.Sparks in 'Core\Effects.Sparks.pas',
  Effects.Lightning in 'Core\Effects.Lightning.pas',
  Effects.Traces in 'Core\Effects.Traces.pas',
  Effects.Debris in 'Core\Effects.Debris.pas',
  Render.Dynamics in 'Core\Render.Dynamics.pas',
  Render.Shake in 'Core\Render.Shake.pas',
  Hero in 'Game\Hero.pas',
  Bullets in 'Game\Bullets.pas',
  Monsters in 'Game\Monsters.pas',
  Monsters.Disc in 'Game\Monsters.Disc.pas',
  Monsters.Hull in 'Game\Monsters.Hull.pas',
  Monsters.Pilot in 'Game\Monsters.Pilot.pas',
  Monsters.Damage in 'Game\Monsters.Damage.pas',
  Pads.Formations in 'Game\Pads\Pads.Formations.pas',
  Pads.Flights in 'Game\Pads\Pads.Flights.pas',
  Pads.Plunge in 'Game\Pads\Pads.Plunge.pas',
  Pads.Shelf in 'Game\Pads\Pads.Shelf.pas',
  Pads.Stray in 'Game\Pads\Pads.Stray.pas',
  Pads.World in 'Game\Pads\Pads.World.pas',
  Pads.Arena in 'Game\Pads\Pads.Arena.pas',
  Render.Font in 'Core\Render.Font.pas',
  Hud.Typewriter in 'Hud\Hud.Typewriter.pas',
  Hud.Terminal in 'Hud\Hud.Terminal.pas',
  Hud.Briefing in 'Hud\Hud.Briefing.pas',
  Hud.Messages in 'Hud\Hud.Messages.pas',
  Render.Brush in 'Core\Render.Brush.pas',
  Hud.Vitals in 'Hud\Hud.Vitals.pas',
  Game.Bonus in 'Game\Game.Bonus.pas',
  Game.Space in 'Core\Game.Space.pas',
  Game.Henshin in 'Game\Game.Henshin.pas',
  Game.Shroud in 'Game\Game.Shroud.pas',
  Game.Uptake in 'Game\Game.Uptake.pas',
  Game.Sphere in 'Game\Game.Sphere.pas',
  Game.Trial in 'Game\Game.Trial.pas',
  Game.Press in 'Game\Game.Press.pas',
  Game.Arrivals in 'Game\Game.Arrivals.pas',
  Game.Shield in 'Game\Game.Shield.pas',
  Game.Cannons in 'Game\Game.Cannons.pas',
  Game.Explosions in 'Game\Game.Explosions.pas',
  Game.Blasts in 'Game\Game.Blasts.pas',
  Game.Impacts in 'Game\Game.Impacts.pas',
  Orbs.Flock in 'Game\Orbs\Orbs.Flock.pas',
  Orbs.Harvest in 'Game\Orbs\Orbs.Harvest.pas',
  Orbs.Aura in 'Game\Orbs\Orbs.Aura.pas',
  Orbs.Rain in 'Game\Orbs\Orbs.Rain.pas',
  Orbs.Patterns in 'Game\Orbs\Orbs.Patterns.pas',
  Orbs.Rite in 'Game\Orbs\Orbs.Rite.pas',
  Orbs.Burst in 'Game\Orbs\Orbs.Burst.pas',
  Orbs.Feed in 'Game\Orbs\Orbs.Feed.pas',
  Events.Director in 'Game\Events\Events.Director.pas',
  Scenes.Director in 'Game\Scenes\Scenes.Director.pas',
  Hud.Charge in 'Hud\Hud.Charge.pas',
  Hud.Marks in 'Hud\Hud.Marks.pas',
  Hud.GoRight in 'Hud\Hud.GoRight.pas',
  Hud.Energy in 'Hud\Hud.Energy.pas',
  Audio in 'Game\Audio.pas',
  Localization in 'Core\Localization.pas',
  Render.Glow in 'Core\Render.Glow.pas',
  Render.Silhouette in 'Core\Render.Silhouette.pas',
  Render.Globe in 'Core\Render.Globe.pas',
  Menu.Starfield in 'Menu\Menu.Starfield.pas',
  Menu.Globe in 'Menu\Menu.Globe.pas',
  Menu.Embers in 'Menu\Menu.Embers.pas',
  Menu.Logo in 'Menu\Menu.Logo.pas',
  Menu in 'Menu\Menu.pas',
  Game.HeroOrbs in 'Game\Game.HeroOrbs.pas',
  Game.Moon in 'Game\Game.Moon.pas';

const
  MaxLevelSlots = 99;
  // Shipped defaults, read only. The player's choices go to
  // UserSettingsFileName, so this file stays as committed
  ConfigFileName = 'config.json';

resourcestring
  // Developer-facing startup error - may fire before any dictionary
  // is loaded, hence English and outside the localization system
  SNoLevelsFound = 'No levels found (level1.json onward)';

// Peeks at a level manifest for its display title without building the
// whole TLevel - the menu only needs the label on the door.
function ReadLevelTitle(const AFileName: string): TLocalizedText;
begin
  var Root := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8)) as TJSONObject;
  if Root = nil then
    Exit(MakeLocalizedText(AFileName)); // the label on a broken door
  try
    Result := ReadLocalizedText(Root, 'title', AFileName);
  finally
    Root.Free;
  end;
end;

function DiscoverLevels: TArray<TLevelChoice>;
begin
  Result := nil;
  for var i := 1 to MaxLevelSlots do
  begin
    var FileName := Format(LevelFilePattern, [i]);
    if not FileExists(FileName) then
      Break; // numbering is contiguous - the first gap ends the list
    var Choice: TLevelChoice;
    Choice.FileName := FileName;
    Choice.Title := ReadLevelTitle(FileName);
    Result := Result + [Choice];
  end;
end;

procedure RunGame;
const
  MonstersFileName = 'monsters.json';
var
  Monsters: TMonsterRegistry;
  Host: TGameHost;
  Game: TMoonGame;
begin
  // 2008 seeded inside MoonTimer of all places; without ANY call the
  // bonus roulette and the moon fly the same route every run
  Randomize;

  EnsureImageLib;

  var Config := LoadGameConfig(ConfigFileName, UserSettingsFileName);
  // The dictionary must stand before the first Tr() - the menu builds
  // its captions inside TMoonGame.Create. A missing or broken language
  // file dies here, in the startup message box, not mid-frame.
  LoadLanguage(Config.Language);
  var Levels := DiscoverLevels;
  if Levels = nil then
    raise Exception.Create(SNoLevelsFound);

  Monsters := TMonsterRegistry.Create;
  try
    Monsters.LoadFromFile(MonstersFileName);

    Host := TGameHost.Create(Config, 'Moon 2D ' + GameVersion);
    try
      Game := TMoonGame.Create(Monsters, Host.Renderer, Host.Window,
        Levels, Config);
      try
        Host.Run(Game);
      finally
        Game.Free;
      end;
    finally
      Host.Free;
    end;
  finally
    Monsters.Free;
    IMG_Quit;
  end;
end;

begin
  try
    RunGame;
  except
    on E: Exception do
      MessageBox(0, PChar(E.Message), 'Moon 2D - startup error',
        MB_OK or MB_ICONERROR);
  end;
end.
