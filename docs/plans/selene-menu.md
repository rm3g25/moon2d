# Selene in the menu

Status: an idea (recorded 2026-09-30), no dates and no place in the order
(`ROADMAP.md`). The texture is done; the game code is not touched. The
menu globe as built is `mechanics/menu.md` and `mechanics/sky.md`.

## The idea
When the hero reaches Selene (the dimension shift in the finale of the
arc - a living Moon under a dead Earth), the moon of the menu becomes
Selene: the same geography, the same seas where the lunar seas lie, but
water, forests, deserts, ice, clouds. The face of the Moon is recognized -
that is the point: not another planet, the same Moon in which the world
turned over.

The change itself is a separate short cutscene (decided), not an instant
swap of the texture in the menu.

## Done
The texture. The tool `tools/Selene` (Python) paints the map from
`moonmap`; the approved look lies in `tools/Selene/out` (the surface, the
clouds as a separate layer, the water mask for the glint). The session is
in `mechanics/sky.md` ("Селена, текстура глобуса").

## Not done (the game code is untouched)
- The flag "has been on Selene" - the player's layer `settings.json`
  (3.0.9), not the `config.json` of the delivery.
- `Menu.Globe` takes the map by the flag (a map of the same shape -
  2048x1024, a power of two, the pyramid built the same way).
- The glint on the water, a blue haze toward the limb, a warm soft
  terminator - they depend only on the point of the disc (the sun stands
  still in the menu), are computed at start beside `Shade`, and are
  nearly free in the frame.
- The clouds - a second pass over the texture in the frame, the globe
  about twice as dear; options: half resolution, an update every N ticks.
- The cutscene of the change.

Before that the source is to be replaced: `moonmap` is not an honest map
(see the session); with the real LROC + LOLA the menu Moon gets a far
side, and Selene an ocean where the Aitken basin is.
