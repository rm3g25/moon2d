# One container for the resources

Status: an open question, no dates and no place in the order
(`ROADMAP.md`). Nothing built.

## The itch
The scatter of files - `levelN.json`, `monsters.json`, `config.json`, the
sets, the music - is easy to spill when a build is handed out.

## The Doom approach
One container with a directory (a lump: name, offset, size); the engine
opens `moon.wad` and pulls resources by name, knowing nothing of the file
system. One file per release, modding by swapping the wad, a clean
hand-out.

## The fork, half closed
"Too many files fly about" could mean the RESOURCES (pack the data, the
art and the sound into a wad) or the UNITS (glue the `.pas` files
larger) - two different refactors with opposite philosophies: the wad
hides data in a container, merging units is about the structure of the
code. Half of the fork is closed: the units were not merged but sorted
into folders by layer (after 3.0.8). The wad question is only about the
resources, and open.

## When (proposed, not decided)
Not before the editor: the editor writes the files the wad would hold,
and the two must agree on one format of the directory. A natural moment
is the release script, which already gathers the files into
`Moon2D_assets`.
