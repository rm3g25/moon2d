{
  Moon2D.inc - project-wide compile-time switches.

  Included right after the unit/program line of every source file. A
  $DEFINE in Delphi is file-scoped: a symbol defined in Moon2D.dpr never
  reaches Hero.pas. This textual include is what makes a switch mean the
  same thing everywhere, whatever configuration built it.

  This is the ONLY place a switch is turned on or off.

  Never spell a directive in braces inside this header: brace comments
  do not nest, so the first closing brace ends it and everything after
  becomes code. Write $DEFINE bare, as above.
}

// DEBUGKEYS - the developer keyboard: PgUp/PgDn browse screens, T tile
// inspector, F font atlas, G defensive aura, M music mute, V/B trailer
// frames, numpad tuners for the minigun muzzle and the crosshair.
//
// Off since 2.1.1: releases were being built from the Debug
// configuration and carried the whole keyboard into shipping archives.
// Remove the dot below for a session of tuning, put it back after.
{.$DEFINE DEBUGKEYS}

// Belt and braces. Whatever the line above says, a Release build never
// ships the debug keyboard - the dot is a habit, this is a guarantee.
{$IFDEF RELEASE}
  {$UNDEF DEBUGKEYS}
{$ENDIF}
