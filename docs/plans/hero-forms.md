# Several forms, several henshins, a third kind of bullet

Status: an idea (recorded 2026-09-27), no dates and no place in the order
(`ROADMAP.md`). What a level asks for comes first. The ice form and its
henshin are built (`mechanics/henshin.md`); the moon form and its rite at
the end of level 2 are arena 3's (`mechanics/arena-3/`).

## Forms and ceremonies
The hero will have several forms and several transformation ceremonies -
the ice form with its henshin is the first, not the only one. For this
the henshin was moved into its own unit (3.0.2): `THenshin` is the first
ceremony; from here either a class per ceremony or a table of scripts.
`THeroForm` grows past `hfNormal` / `hfIce` (the moon form is its next
value - arena 3). The finished game (decided 2026-09-30) has five forms
besides the ice one.

## The third kind of bullet
After the hero's bullets and the monsters' bullets: bullets that fly by
program - the trajectory set by code, not by the ballistics of 2008 -
that do not burst on obstacles but wound monsters. Both a projectile and
a building material.

The next henshin is built on them: the hero gathers the bullets onto
himself, on the way they wound monsters, and the suit is assembled from
the gathered bullets. The ceremony is not only a spectacle over the hero
but an attack and the assembly of the form at once; the end of the
ceremony = a suit made of what flew in.

Note: the orbs (`mechanics/orbs.md`, 3.0.33 on) already are such a kind -
drawn by code, moved by formulas, ignoring matter, touching only enemies
and their bullets - and the henshin on orbs (3.0.49) already builds the
suit from them. Whether the third kind is the orbs grown up or a kind
beside them is open.

## What it means for the code
- `TBurst` / `TBullet` get a third flight mode (today two: the baseline
  physics `dy += g/100` and `Contact` for the interception).
- The hero's form is not a Boolean and not a pair but an enum with a
  behaviour per form (the +25% jump of the ice form is the first
  particular case).
- Each ceremony is its own state machine after the pattern of
  `Game.Henshin`, with a common interface to start it
  (`StartCountdown` / `Start` / `Tick` / `DrawCountdown` / `Reset`).
- The mega-lightning - a strike from above (`mechanics/lightning.md`) -
  is reserved for the second henshin.
