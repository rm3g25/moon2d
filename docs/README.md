# docs/

Two documents, two different jobs. Do not merge them — they age at
different speeds and are read for different reasons.

## CODEBASE-MAP.md — a structural snapshot

What lives where: every code unit, its classes and records, the JSON data
files, and a task-routing table. Written for someone (human or LLM)
arriving cold who needs to know which files a given task touches.

- **Genre:** build artifact that happens to be convenient to keep in git.
- **Updated:** once per milestone, by regenerating it from the source —
  not by patching individual lines. Patching is how a map starts lying
  quietly.
- **Authority:** none. If the map and the code disagree, the code is
  right. The map carries a commit stamp so you can see how stale it is.
- **Russian twin:** `CODEBASE-MAP-ru.md`, same content. Regenerate both
  or neither.

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
