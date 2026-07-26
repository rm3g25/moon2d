# Porting notes

Moon 2D was written in 2005–2008 in Delphi 2005, using immediate-mode OpenGL,
a hand-rolled binary level format, and a 20 ms `WM_Timer` doing duty as a game
loop. It ran. Most of it ran for reasons that were never written down.

This document is about what happened when it was rebuilt eighteen years later
on Delphi 13 and SDL2 — specifically the parts that were surprising.

---

## Why

Every company has a system nobody wants to touch. It works, it earns money,
and the people who wrote it are gone. When someone finally rewrites it, the
rewrite tends to fail — not because the new code is bad, but because nobody
remembers what the old system was supposed to *do*. The specification was
never written down. It was compiled.

Moon 2D is that problem at hobby scale, with one advantage real legacy
projects almost never have: **the original still runs.** Correct behaviour is
not a matter of opinion here. Launch the 2008 build, launch this one, compare.

That turns behavioural equivalence from an aspiration into a testable
constraint, and a game is an unusually strict place to test it. A business
application tolerates a rounding difference for years. A platformer does not:
change the jump arc by one unit and a gap that was always clearable stops
being clearable, on the fourteenth screen, in a way that feels like bad level
design rather than a bug.

There is also a smaller and more honest reason. It is my game and I wanted it
back.

### The migration itself

The version distance is not trivial. Delphi 2005 to Delphi 13 crosses the 2009
Unicode transition, where `string` stopped meaning `AnsiString` and every
codebase in the language broke at once. It crosses the arrival of generics,
inline variable declarations, and `System.IOUtils`. On the rendering side it
crosses the retirement of immediate-mode OpenGL, and on the timing side it
crosses the point where "call me every 20 ms" stopped being an acceptable way
to run a simulation — if it ever was.

None of that is exotic. It is the ordinary shape of a real migration.

---

## Method

Four rules, adopted early, and the reason the port converged instead of
drifting.

**1. Cite, don't clean.** Where the 2008 code contained a formula, the formula
was carried over verbatim, with a comment naming the file and line it came
from. It was not simplified, not refactored, not "obviously equivalent"-ed.
In legacy code the strange formula *is* the specification; the moment you
improve it you have silently changed the product and lost the ability to say
what changed.

Refactoring was allowed only where branch equivalence could be demonstrated
algebraically. That happened rarely.

**2. Never trust a comment.** Comments in the original were checked against
the code they described, every time. A meaningful fraction were wrong — not
maliciously, just left behind by an edit. A comment is a claim about the code,
and claims get verified.

**3. Enumerate every deliberate deviation.** There are exactly seven, listed
below. Anything not on that list and not matching the original is a bug, not
an improvement. Without a closed list, drift hides behind good intentions and
after six months nobody can tell a fix from a regression.

**4. One structural change at a time, each with its own play-through.** Slow,
and it is the reason there was never a session spent bisecting which of four
simultaneous changes broke the collision.

**On tooling.** Implementation written with LLM assistance; architecture,
constraints, verification and all play-testing by the author.

---

## What actually broke

### Two coordinate systems wearing the same clothes

The game logic runs in a 512×384 grid of *game units*. A cell is 32 units; the
hero is 32 units. The tile artwork is 64×64 *pixels*, cropped from the top-left
and drawn into a 32-unit cell.

So the number 64 appears throughout the original meaning two unrelated things,
and the number 32 appears meaning two more. Every tile-rendering bug in the
first weeks traced back to a value that had quietly crossed from one space into
the other. The fix was not clever code — it was naming the two constants
differently (`TileSize` in units, `TileArtSize` in pixels) so that mixing them
looks wrong on the page.

### Y is the floor, not the head

In the original, an entity's Y coordinate is the line its **feet** stand on.
Bodies are therefore drawn *upward* from Y — the sprite occupies `y-32..y` —
while bullet and contact hitboxes extend *downward*, `y..y+32`.

Reasonable once you know it. Invisible until you do, and it produces the
particular class of bug where everything looks correct and nothing connects.

### The same probe, twice, with opposite signs

This one cost the most.

The original tests the ground beneath the hero at `y-3` and the ground beneath
a monster at `y+3`. Not a typo — two separate collision oracles, written at
different times, both correct within their own caller, with opposite
conventions.

The instinct of anyone porting this is to notice the duplication and unify it.
Doing so is fatal: monsters begin sinking into floors or hovering above them,
depending on which version won. There is no shared abstraction to extract here,
because the two functions are not the same function. They only look alike.

Both were ported separately, both kept, both commented with a warning against
merging them.

### The timer that lied

The original scheduled its game loop with `WM_Timer` at 20 ms and everything
was tuned against that number — jump heights, monster speeds, animation rates,
fire rates.

`WM_Timer` on Windows does not deliver 20 ms. Its resolution is bounded by the
system clock tick, and in practice the loop ran at roughly **33 ms**. Every
constant in the game was therefore tuned against 33 ms while the source code
claimed 20.

The port runs a fixed timestep at 33 ms. It reproduces the original exactly.
It also means the source-of-truth for the original's timing was not in the
original's source at all — it was in the behaviour of an operating system
scheduler nobody documented.

### The font atlas was stored sideways

The bitmap font is a 448×448 atlas of 16×16 glyphs, indexed by `CP1251 − 1`,
with transparency by colour threshold (`R<43, G<33, B<23` — carried over
verbatim, and yes, those three numbers are all different).

Text rendered as garbage. The atlas file, opened in an image viewer, looked
fine.

The 2008 texture loader transposed image data on upload — a quirk of how it
fed the buffer to OpenGL. Nobody noticed, because the font was *authored*
through the same broken path: the glyphs were drawn, they came out wrong, the
sheet was rotated until they came out right. The file on disk has stored every
glyph rotated 90° clockwise since 2008, and it was correct, because it was
consumed by a loader that rotated it back.

SDL2 does not transpose anything. The port rotates the atlas upright at load
time and leaves the file untouched.

The general lesson is worth stating plainly: **a bug that is compensated
elsewhere is not a bug, it is a load-bearing wall.** Removing half of a
matched pair of errors breaks something that had been working for eighteen
years.

### The animation counter runs backwards

Frame selection in the original is `9 - Round(CurrentSprite)`. It counts down.
Preserved as-is.

Related: `Round` in Delphi is banker's rounding — it rounds halves to even, not
away from zero. On some frames this selects a different sprite than a naive
reading suggests. The original was inconsistent about it, so the port uses an
explicit `RoundHalfUp` where the visible result matches the original and
standard `Round` where it does not. Documented, not tidied.

### Every fourth frame was going somewhere

Windowed mode stuttered. Full screen was fine. The obvious suspects — the
multi-monitor setup, the GPU driver, the OS — were all tested and all
exonerated.

Three separate causes, found in this order:

1. **SDL2 defaults to the Direct3D 9 renderer on Windows.** Not D3D11, not
   D3D12 — D3D9, for compatibility reasons that stopped mattering years ago.
   Fixed with `SDL_SetHint(SDL_HINT_RENDER_DRIVER, 'direct3d11')` *before*
   creating the renderer; after creation the hint is ignored silently.
2. **No per-monitor DPI awareness declared.** On a multi-monitor setup with
   mixed scaling factors, Windows stretches the window bitmap on behalf of an
   application that has not said otherwise. It looks like a rendering problem
   because it is one — just not yours.
3. **No render interpolation.** With a fixed 33 ms simulation and an
   uncapped display, object positions snap between ticks. The menu already
   interpolated; the game world did not.

The first two are fixed. The third is open, and it is on the roadmap.

The point worth keeping: the answer to "why is it slow *now*" is almost never
found by profiling the slow thing. It is found by asking what *changed*. Here
nothing in the game had changed — what changed was the platform underneath a
default nobody had ever inspected.

---

## Delphi-specific traps

Collected because each of these cost real time and none of them are in the
documentation where you would look for them.

**UTF-8 BOM is mandatory.** A `.pas` file containing Cyrillic string literals
and saved *without* a byte-order mark is read by Delphi 12+ as ANSI, i.e.
CP1251, and every Russian string in the build becomes mojibake. The file looks
identical in every editor. The compiler issues no warning. Set your editor to
write the BOM and never think about it again.

**`{$DEFINE}` is file-scoped.** A symbol defined in the `.dpr` is *not* visible
to the units it uses. Conditional compilation symbols that need to be global
belong in the project options, not at the top of the program file — where they
will appear to work, because the `.dpr` itself compiles correctly.

**`exports` accepts routines only.** Not variables. The error message when you
try is not helpful.

**`SDL_BOOL` is a four-byte C enum.** Declaring it as Delphi's `ByteBool` gives
a one-byte type, and the stack misaligns on every call that returns one. Use
`LongBool`. This class of bug presents as unrelated corruption several calls
later, which is the worst way for a bug to present.

**`delayed` imports are worth the keystrokes.** Declaring DLL imports as
`delayed` means the library is resolved on first call rather than at process
start. A missing `SDL2_mixer.dll` then degrades the game to silence instead of
refusing to launch. This is how the repository can ship without its music and
still be playable.

---

## Deliberate deviations from the original

The complete list. Anything else that differs is a defect.

1. **`RoundHalfUp` for animation frames.** Banker's rounding produced visible
   frame skips in the original too; this is a fix, not a reproduction.
2. **Corpses obey gravity** and settle once on landing. In 2008 they hung in
   mid-air where they died.
3. **Crosshair offset `DX=9, DY=10`.** Calibrated against the live cursor with
   a temporary keyboard tuner rather than derived. The original's constants did
   not survive the change of rendering API.
4. **Healing restores 10, not 15.** A balance decision, taken deliberately.
5. **Teleports drop the hero** rather than leaving him standing on air.
6. **Death respawns at the current screen's checkpoint** and rebuilds the
   world. In 2008, death returned you to the menu and checkpoints existed only
   for pit falls. This is the single largest departure and it was made
   knowingly: the original's model was a coin-op convention that has not aged.
7. **Menu item column moved from 17 to 15.** The English string
   `DIFFICULTY: NORMAL` is seventeen glyphs and ran into the right edge. Moving
   the column left buys about 33 units of slack. The hover hitbox follows the
   constant automatically.

---

## What I would do differently

**Read whole functions, not grep results.** One finding in this port was
announced and then retracted, because a grep fragment looked conclusive and the
surrounding lines contradicted it. Grep locates; it does not conclude.

**Convert the asset format before the first commit, not after.** Binary
formats committed and then converted live in version-control history twice,
forever. The cost here is trivial. On a larger project it would not be.

**Write the deviations list on day one.** It was started late, which meant an
archaeological pass over changes already made to work out which had been
decisions and which had been accidents. Some of that is unrecoverable — a
decision nobody wrote down at the time is indistinguishable from a mistake six
months later, including to the person who made it.

---

## Build requirements

Developed on **Delphi 13 Florence**, targeting Win32.

The binding language constraint is inline variable declarations
(`for var i := 0 to ...`), which require **Delphi 10.3 Rio or later**. Nothing
newer than that is used deliberately, so earlier releases in that range should
work — but this has not been tested, and the project file is saved by Delphi 13
and may need its version attribute adjusted before an older IDE will open it.

The newest free Community Edition at the time of writing is **Delphi 12.1
Athens**, which is well within range on the language side.

No third-party components. `SDL2.dll` and `SDL2_mixer.dll` ship with the
repository.
