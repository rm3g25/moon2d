{
  Moon2D.Tests - the console runner of the test suite. Every fixture the
  units below register is run, and the exit code says whether all of
  them passed.

  No window and no SDL call: the suite tries what the game counts, not
  what it draws. The executable goes to bin\ all the same, beside
  SDL2.dll, which the units under test import.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
program Moon2D.Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  Tests.Rooms in 'Tests.Rooms.pas',
  Tests.Effects.Lightning in 'Effects\Tests.Effects.Lightning.pas',
  Tests.Game.Blasts in 'Game\Tests.Game.Blasts.pas',
  Tests.Game.Shroud in 'Game\Tests.Game.Shroud.pas',
  Tests.Levels.Entities in 'Levels\Tests.Levels.Entities.pas',
  Tests.Levels.Pads in 'Levels\Tests.Levels.Pads.pas',
  Tests.Monsters in 'Monsters\Tests.Monsters.pas',
  Tests.Monsters.Bodies in 'Monsters\Tests.Monsters.Bodies.pas',
  Tests.Monsters.Damage in 'Monsters\Tests.Monsters.Damage.pas',
  Tests.Monsters.Defs in 'Monsters\Tests.Monsters.Defs.pas',
  Tests.Monsters.Hull in 'Monsters\Tests.Monsters.Hull.pas',
  Tests.Monsters.Mount in 'Monsters\Tests.Monsters.Mount.pas',
  Tests.Orbs.Flock in 'Orbs\Tests.Orbs.Flock.pas',
  Tests.Pads.Plunge in 'Pads\Tests.Pads.Plunge.pas';

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
