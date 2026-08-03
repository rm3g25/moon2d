# The `.mset` sprite set format

A sprite set is one file holding many sprites. It exists to replace a
thousand loose files in a shipping folder with about two dozen, without
giving up the ability to see what changed, take a set apart, or load one
sprite without loading the rest.

## Layout

```
offset  size  what
     0     4  'MSET'
     4     2  version, currently 1        (word, little-endian)
     6     4  manifest size in bytes      (cardinal, little-endian)
    10     n  manifest, UTF-8 JSON
  10+n     …  every image, concatenated, no padding, no separators
```

Nothing marks where one image ends and the next begins. The manifest
carries an offset and a length for each, so reading a sprite is a seek
and a read. Searching for a separator would be slower and, worse,
ambiguous — the bytes of a separator can occur inside a PNG.

Offsets are counted from the first byte of the image block, not from the
start of the file. The manifest can grow or shrink without a single
image moving.

## Manifest

```json
{
  "id": "gravel",
  "description": "Free text, or JSON, or nothing. Whatever the author
                  wants to remember about this set.",
  "sprites": [
    { "name": "1", "description": "", "offset": 0, "size": 2148 },
    { "name": "2", "description": "", "offset": 2148, "size": 1980 }
  ],
  "sequences": [
    { "name": "alive", "description": "",
      "frames": ["1", "2", "3", "4", "5", "6", "7", "8"] },
    { "name": "death", "description": "last frame holds",
      "frames": ["d1", "d2", "d3", "d4"] }
  ]
}
```

- **`id`** — the set's name. Levels and monsters refer to sets by this,
  not by filename.
- **`description`** — free-form, on the set and on every sprite. The
  format never parses it; it is there so that a decision made today is
  still legible in a year.
- **`sprites`** — order matters: it is the order they were packed and the
  order tools list them in.
- **`sequences`** — named frame orders, each with its own free-form
  description. The engine asks for `alive` and `death`; any other name is
  legal and simply waits for something to ask for it. A frame may appear
  in several sequences — a sequence names sprites, it does not own them.
  This is what retires the `.mns` side files.

Images are stored exactly as they came off disk — raw PNG bytes, no
re-encoding, no compression on top. A PNG is already compressed, and
re-encoding art on every build is a good way to lose a pixel to a
rounding difference.

## Who owns which set

- **Monsters own their sprites.** `monsters.json` names the set; a level
  that places a monster gets its art automatically. A level never lists
  monster sets, because then two lists would have to agree, and one day
  they would not.
- **The hero is the default.** Loaded by the engine, named in no JSON.
- **Levels declare environment only** — tiles, backgrounds, decorations:
  `"spriteSets": ["moon-surface", "machinery"]`. Sets are searched in the
  order declared, first match wins.

Environment sets are split by theme, not by level. Tiles have always
crossed level boundaries — level 2 uses art from level 1 — so a set per
level would need duplication or cross-references from the first day.
When a theme needs more art, the set grows. A second set is created for
a new theme, never because an old one got large: sets are loaded lazily,
so size costs nothing, while a name to remember costs every time.

## The tile sets

Twelve sets hold the 2008 tile art, grouped by subject. Both levels draw
from the same folders, so the split is by what a tile depicts, not by
where it is used: brick is brick whichever level stands on it.

| set | what | tiles |
|---|---|---|
| `brickwork` | the brick wall families b1x, b2x, b3x | 24 |
| `mine-structure` | floors, wall edges, posts, hook | 11 |
| `moon-surface` | lunar ground and caves | 6 |
| `machinery` | coolers, fans, pipes, lamps, hull plating | 19 |
| `facility` | bases, crates, TEK-branded structures | 6 |
| `common` | void, screen transition | 3 |
| `conveyor` | the belt system in every variant | 25 |
| `mining-rig` | diggers and their machinery | 16 |
| `railway` | rails, wagons, platforms, posts | 20 |
| `mine-walls` | rough and TEK-panelled mine walls | 11 |
| `cargo` | goods and crates | 15 |
| `mine-interior` | doors, windows, railings, ceilings | 33 |

Four names exist twice with different pictures behind them — `mash1`,
`mash2`, `mash3` and `pustota` live in both `textures\` and
`textures\level1\`. They are routed to sets that hold no other tile of
that name, so nothing collides inside a set. A level that declares both
sides gets the first declared, which is the rule everywhere else too.

This art is finished: levels 3 and up are drawn fresh, so these twelve
sets are frozen and will not grow. The grow-do-not-multiply rule applies
to the new art, where a residential sector or a train earns its own set
the moment it is a new subject rather than more of an old one.

## Reading

Opening a set parses the manifest and stops. Image bytes are read when
something asks for them. A level declaring five sets and using three
tiles from one of them reads three tiles.

## In the repository

Sets are committed as `.mset`; the loose PNGs are not. Anything inside
can be recovered with `SpritePackCli unpack`, so keeping both would be
storing the same bytes twice.

Because a set is binary, `git diff` says only that it changed. To see
*what* changed, teach git to read it — the manifest is text, and the
tool prints it:

```
# .gitattributes
*.mset diff=mset

# .git/config
[diff "mset"]
    textconv = bin/SpritePackCli.exe list
```

Then a renamed sprite or a reordered animation shows up as a line, the
way it should.

## Tools

```
SpritePackCli pack   <folder> <out.mset> [--id <name>] [--list <file>]
SpritePackCli list   <file.mset>
SpritePackCli unpack <file.mset> <folder>
```

`pack` takes every PNG in the folder in natural order. `--list` points
at a 2008 sprite list — a monster's `.mns`, the hero's `default.txt`,
the weapon's — and splits it into named sequences by its length: sixteen
lines are `alive` and `death`, twenty-four are `walk`, `death` and
`henshin`, anything else is one group called `frames`. That is not a
guess; it is the arithmetic each 2008 loader already did, given a name.

This is a migration path, used once. Afterwards the set is the only
source — names, descriptions and frame order live in its manifest and
are edited in the tool. No authoring file sits beside a set waiting to
disagree with it, and the sprite lists retire along with the loose
images.

`unpack` writes the images back out along with `manifest.json`, so any
set can be taken apart and rebuilt. A format only its own tool can read
is a trap; this one has a way out.

The round trip is the acceptance test: pack a folder, unpack it
elsewhere, compare the bytes. Writing is deterministic — the same input
produces the same file — so a rebuilt set that did not change is not a
diff either.
