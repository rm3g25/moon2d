# docs/

Two documents, two different jobs. Do not merge them — they age at
different speeds and are read for different reasons.

## CODEBASE-MAP.md — a structural snapshot

What lives where: every code unit, its classes and records, the JSON data
files, and a task-routing table. Written for someone (human or LLM)
arriving cold who needs to know which files a given task touches.

- **Genre:** build artifact that happens to be convenient to keep in git.
- **Updated:** two ways, for two kinds of staleness.
  - *Patched* by every change that moves what the map names - a unit, a
    type, a public method or signature, a field it lists, a size that
    jumps. The sections that change is about are rewritten in the docs
    commit of its series, describing the code as it is now, not how it
    got there. A patch that would touch most of the map is a
    regeneration instead.
  - *Regenerated* from the source once per release. Patches only reach
    what their change knew about; the quiet drift in between - a size
    creeping up, a neighbour renamed - is caught here.
- **Authority:** none. If the map and the code disagree, the code is
  right. The stamp at the top says both when it was last regenerated
  and how far it has been patched since.
- **Russian twin:** `CODEBASE-MAP-ru.md`, same content. Both change
  together or neither does.

## PORTING-NOTES.md — a living journal

Deliberate deviations from the 2008 original, the bugfix queue,
architectural decisions and their reasoning, the roadmap. Written for
continuity: a new session starts by reading this.

- **Genre:** journal. Append-only in spirit; entries stay even when
  superseded, because the reasoning is the value.
- **Updated:** every session.
- **Authority:** high on *intent*. When the code does something odd and
  the notes explain why, the notes win the argument about whether it is
  a bug.

## The one-line test

Asking "where does X live?" → CODEBASE-MAP.
Asking "why is X like that?" → PORTING-NOTES.
