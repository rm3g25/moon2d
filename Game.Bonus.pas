{
  Game.Bonus - the vocabulary of the bonus roulette, shared by the game
  that runs it and the HUD that shows it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Bonus;
{$I Moon2D.inc}

interface

type
  // The four rewards of bonus.pas (2008). bkNone doubles as 'slot is
  // empty'; the roulette picks uniformly from the four real ones.
  TBonusKind = (bkNone, bkHealth, bkFireRain, bkAura, bkExplosion);

const
  // Every BonusCost points buy one reward, held until the right mouse
  // button spends it - and paid for at that moment, so the score keeps
  // climbing past the cost while a reward waits
  BonusCost = 50;

implementation

end.
