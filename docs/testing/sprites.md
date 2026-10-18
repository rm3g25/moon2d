# Tests of the sprite sets

Tables of the tests, one section per unit under test: the test's name,
what holds, the breakage. The rules and the conveyor are in
`../TESTING.md`; a new unit's table goes into the file of its namespace.

## Sprites.Sets

State: written, 1 test, green on the first run. Tries the sets the game ships rather
than the `TSpriteSet` class: it opens every `.mset` in `bin\sprites\`
through the class's interface and reads only the PNG header of each
sprite. No window, no SDL. The unit is `Tests\Sprites\Tests.Sprites.Sets.pas`,
fixture `TSpriteSetTests`; `..\Core` is on the search path already.

2048 is a number of the design: the largest texture of Direct3D feature
level 9_1, the oldest the game runs on (MSET-FORMAT, "How big a sprite
may be").

| Test | Holds | Turns red when |
|---|---|---|
| `TestEveryShippedSpriteFitsTheOldestCards` | there is at least one set in `bin\sprites\`; every sprite of every set is a PNG no wider and no taller than 2048 px; a red run names each misfit as `set:sprite WxH` | a sprite past 2048 is packed, by any tool - the cordon's hull at 4172 px was one; or the folder is gone and the test would pass on nothing |

Left to the eye: the seams where strips of a cut picture meet.
