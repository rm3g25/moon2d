{
  Game.Version - the one place the game knows its own version.

  The string here is the truth the player sees (menu corner, window
  title). It moves together with the git tag: bump it in the commit that
  becomes the version, tag that commit. The dproj carries no version
  resource, so nothing else has to agree with it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Version;
{$I ..\Moon2D.inc}

interface

const
  GameVersion = '3.0.9';

implementation

end.
