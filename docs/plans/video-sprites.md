# The hero and the monsters from video (step 1 after 3.0)

Status: planned (2026-10-02, 2026-10-10), no dates; first of the six
steps after 3.0 (`ROADMAP.md`, order decided 2026-11-07). Not built. The hero's look itself is a
separate thread (the HD hero, modelled on the hero of Dark Planet).

## Why
The hero walks through the game in a T-shirt and pyjamas, the monsters
are the 2008 sprites, and the 3.0 release left both alone on purpose:
they wait for the list of forms and for the frame contract (`ROADMAP.md`,
the boundary of 3.0). This step is where they are redrawn.

## The way (decided)
- The living things - the hero and the monsters - are generated as AI
  video on a green screen, and the frames are cut out of the video. Held
  to be proven possible (even models like Grok have shown it).
- The video itself is never used in the game - only the frames pulled
  from it. Not pixel art: pixel art is ruled out.
- For a monster the base picture is drawn by hand (the gravel female is
  the first example) and the video animates it; the animation must be
  flat and loop seamlessly, the start matching the end. Little work is
  expected and no film generation is needed.
- The video gives more material than the 8 walk frames of 2008, so a walk
  gets more frames - 25-33, or as many as it comes out to.
- The hero backing away is shot as a separate run - walking backward is
  done differently from walking forward.
- The division of labour: the video is generated and reviewed by hand; a
  tool cuts the frames; Claude picks the frames and wires them into the
  code. It has to be fast.

## The utility (the shape proposed 2026-11-07, not decided)
A tool that takes a video on a green screen and gives sprite frames:
keying the green out, cropping to the figure, aligning the frames on a
common anchor (the feet), trimming the loop so the last frame meets the
first, packing into an `.mset`. The successor of
`bmp_to_png_transparent.py`: raw material, then size / palette /
transparency normalized, then the sheet. Claude does not generate the
art - it builds the pipe around the generation.

## Open
- The frame contract. 2008: a sprite of 32, Bound 8, `TAnimSet` 8+8, the
  hero's 24 frames. Dense walks do not fit it; changing it after 2.x is
  allowed, but it is a decision about gameplay (hitboxes, timings), not
  about a picture - to be taken here, before the first monster is cut.
- Which forms the hero has - `hero-forms.md`; the list decides how many
  hero sets there are.
- The sizes: every new texture is made for old video cards (within 2048
  px a sheet) and for a game that one day runs in 4K.
