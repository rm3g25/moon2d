{
  Moon2D.Tests - the console runner of the test suite. Every fixture the
  units below register is run, and the exit code says whether all of
  them passed.

  No window: the suite tries what the game counts, not what it draws.
  The one part of SDL it opens is the mixer, for the scene director's
  sound bank, on the dummy audio driver (Tests.Scenes.Director). The
  executable goes to bin\ all the same, beside SDL2.dll, which the units
  under test import.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
program Moon2D.Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  Tests.Matter in 'Tests.Matter.pas',
  Tests.Rooms in 'Tests.Rooms.pas',
  Tests.Effects.Lightning in 'Effects\Tests.Effects.Lightning.pas',
  Tests.Effects.Traces in 'Effects\Tests.Effects.Traces.pas',
  Tests.Game.Blasts in 'Game\Tests.Game.Blasts.pas',
  Tests.Game.Shroud in 'Game\Tests.Game.Shroud.pas',
  Tests.Game.Trial in 'Game\Tests.Game.Trial.pas',
  Tests.Game.Press in 'Game\Tests.Game.Press.pas',
  Tests.Game.Uptake in 'Game\Tests.Game.Uptake.pas',
  Tests.Game.HeroOrbs in 'Game\Tests.Game.HeroOrbs.pas',
  Tests.Game.Ram in 'Game\Tests.Game.Ram.pas',
  Tests.Game.Wrecks in 'Game\Tests.Game.Wrecks.pas',
  Tests.Game.Capsules in 'Game\Tests.Game.Capsules.pas',
  Tests.Game.StoneTank in 'Game\Tests.Game.StoneTank.pas',
  Tests.Game.Belt in 'Game\Tests.Game.Belt.pas',
  Tests.Hud.GoRight in 'Hud\Tests.Hud.GoRight.pas',
  Tests.Hud.Energy in 'Hud\Tests.Hud.Energy.pas',
  Tests.Levels.Carousels in 'Levels\Tests.Levels.Carousels.pas',
  Tests.Levels.Doors in 'Levels\Tests.Levels.Doors.pas',
  Tests.Levels.Entities in 'Levels\Tests.Levels.Entities.pas',
  Tests.Levels.Events in 'Levels\Tests.Levels.Events.pas',
  Tests.Levels.Graph in 'Levels\Tests.Levels.Graph.pas',
  Tests.Levels.Dynamics in 'Levels\Tests.Levels.Dynamics.pas',
  Tests.Levels.Pads in 'Levels\Tests.Levels.Pads.pas',
  Tests.Levels.Scenes in 'Levels\Tests.Levels.Scenes.pas',
  Tests.Monsters in 'Monsters\Tests.Monsters.pas',
  Tests.Monsters.Bodies in 'Monsters\Tests.Monsters.Bodies.pas',
  Tests.Monsters.Damage in 'Monsters\Tests.Monsters.Damage.pas',
  Tests.Monsters.Defs in 'Monsters\Tests.Monsters.Defs.pas',
  Tests.Monsters.Hull in 'Monsters\Tests.Monsters.Hull.pas',
  Tests.Monsters.Mount in 'Monsters\Tests.Monsters.Mount.pas',
  Tests.Orbs.Flock in 'Orbs\Tests.Orbs.Flock.pas',
  Tests.Orbs.Harvest in 'Orbs\Tests.Orbs.Harvest.pas',
  Tests.Orbs.Patterns in 'Orbs\Tests.Orbs.Patterns.pas',
  Tests.Orbs.Rite in 'Orbs\Tests.Orbs.Rite.pas',
  Tests.Orbs.Burst in 'Orbs\Tests.Orbs.Burst.pas',
  Tests.Orbs.Feed in 'Orbs\Tests.Orbs.Feed.pas',
  Tests.Pads.Decks in 'Pads\Tests.Pads.Decks.pas',
  Tests.Pads.Flights in 'Pads\Tests.Pads.Flights.pas',
  Tests.Pads.Plunge in 'Pads\Tests.Pads.Plunge.pas',
  Tests.Pads.Shelf in 'Pads\Tests.Pads.Shelf.pas',
  Tests.Pads.Stray in 'Pads\Tests.Pads.Stray.pas',
  Tests.Pads.World in 'Pads\Tests.Pads.World.pas',
  Tests.Scenes.Director in 'Scenes\Tests.Scenes.Director.pas',
  Tests.Sprites.Sets in 'Sprites\Tests.Sprites.Sets.pas';

procedure RunSuite;
begin
  TDUnitX.CheckCommandLine;
  var Runner := TDUnitX.CreateRunner;
  // The fixtures register themselves, each in its unit's initialization
  Runner.UseRTTI := False;
  Runner.FailsOnNoAsserts := True;
  Runner.AddLogger(TDUnitXConsoleLogger.Create(False));

  var Results := Runner.Execute;
  if not Results.AllPassed then
    ExitCode := EXIT_ERRORS;
end;

begin
  try
    RunSuite;
  except
    // The top of the program: whatever got here, the run is red
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := EXIT_ERRORS;
    end;
  end;
end.
