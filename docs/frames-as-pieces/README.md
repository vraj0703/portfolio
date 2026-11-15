# Frames as pieces

Vishal's decision (2026-11-15), from his comment on PR #2 ("make it look like an art piece with minimal but
essential info and tags") and the discussion with mantr: **portrait frames, generated art, a wall label, and a
sheet for the detail, in the "ink on paper" treatment.**

`mock.html` in this folder is the clickable mock he judged (open it in a browser; choose "Ink on paper").
`art.py` holds the seven drawings as coordinates and each piece's label and case text.

## What changes

Today a frame is a 4:3 landscape card in a thick wooden frame, with about 70 words painted on it
(`FrameCard`). It becomes:

1. **A portrait piece, 4:5.** Height stays `frameMaxHeight` (3.0), so the piece is 2.4 wide.
2. **Ink on paper.** A thin black frame (#1B1A17), a wide paper mat (#F4EFE4, about 9% of the width on every
   side), and on the paper one drawing in ink (#1B1A17) with one accent colour per project. No words on the piece.
3. **A drawing made from the project's own facts** (see `art.py`, field 400 x 500):
   - Shunya Systems: five nodes, every one joined to every other, one filled in the accent. Accent #C1900A.
   - tantr app: five rounded squares, one inside the next, each turned 11 degrees, around an accent dot. #0F9F73.
   - Publications: twelve points on one thread (six discs, five diamonds, one accent disc). #4A40C8.
   - Twin Health: sixty-seven upright strokes in rows of ten, the last in the accent. #5B5FE0.
   - FieldAssist / PayU: a dot field with three rounded rectangles nested at its centre, the innermost in the accent. #B07D28.
   - School and College (soon): growth rings. #D98A0A. Creative Works (soon): five brush lines. #D94A3A.
   The two "soon" pieces are shown at about 42% strength, as they are dimmer today.
4. **A wall label beside the piece**, small and paper-coloured, the same on every piece: name; one line of at
   most eight words; one number; up to three tags; years. The text for each is in `art.py` (`line`, `num`,
   `tags`, `years`). Where a field is empty there (tags for Twin Health and FieldAssist / PayU, years for
   Publications) leave it out; do not invent it. With the piece 2.4 wide and frames 5 apart there is now room
   on the wall for it, which there was not at 4 wide.
5. **Walking past:** the drawing and the name only. The label must be readable when focused, not from the corridor.
6. **Focus:** as today (camera steps to the piece; previous, close, next), framing the piece together with its label.
7. **The sheet:** a "Read the case" control in the overlay (`GalleryOverlay`, real Flutter widgets, not a
   texture) slides a sheet up over the scene: name, the summary, the three stats, the stack tags, and the
   link out when the project has one. Text is real text: selectable, sharp, readable by a screen reader.
   It closes back to the focused piece. Escape or back steps back one level (sheet, then focus). The link that
   is drawn in the frame today moves to the sheet. "Soon" pieces have no sheet.
8. **Moving on:** previous and next by button, arrow keys and swipe, as far as today's controls allow; do not
   regress what works.

## Constraints

- Keep the baked-texture approach for the piece and the label (see the note on `FrameCard`): painted once with
  `Canvas`, not live widgets in the room.
- `FRAME_TONE` (warm / bold) no longer applies to the pieces; remove it or leave it unused, and say which.
- The loading work of PORTFOLIO-8 must not get slower: seven textures are still seven textures. Report the
  build-phase timing before and after (`BUILD_TIMING`), at most three loads per measurement, window minimised,
  and close what you open.
- Phone: the focused piece and its label must fit a portrait phone; the sheet must be usable with a thumb.
- Tests: the painters' layout (nothing drawn outside the paper; counts: 5 nodes, 5 squares, 12 points, 67
  strokes), the label's rule (at most eight words in the line, at most three tags), the geometry (4:5; label
  inside the gutter), and the sheet's open/close and Escape order.

## Delivery

A branch from `next`, one pull request **against `master`** (the preview job only runs for pull requests
against master; this PR therefore also shows everything in #5). Do not merge. Post the preview URL and
screenshots of: the corridor, one focused piece with its label, the sheet open, and the same three on a phone.
