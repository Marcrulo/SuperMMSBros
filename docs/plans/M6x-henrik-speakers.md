# M6x — Henrik's Speaker Jam Implementation Plan

**Goal:** Henrik's down special: he plays his guitar while a speaker on each side of him blasts
people away to the side on every beat.

**Architecture:** `SpeakerAbility` (on `down_special.tres` → `SpeakerData`) turns the move into
the phase `speaker_jam` on its frame 12 and adds two `Speaker` entities (`MatchEntity`,
`characters/henrik/speaker.gd`) in `spawn_entities`. Each speaker keeps its own age, blasts on the
beats (`collect_hits`, side = its side) and sinks once its owner's jam ends. The playing pose is
Henrik's own `down_special` strip (generator: `tools/sprites/characters/henrik.py`), the drawing
picked by the ability's `drawing()` hook; the speaker picture is generated too (`speaker.png`).
No shared game files; the sprite viewer gets the speaker in its extras (a `shared:` commit).

**Spec:** [henrik](../specs/characters/henrik.md#henrik--guitar)

- [x] **Task 1:** spec.
- [x] **Task 2:** tests — `tests/test_henrik_speakers.gd`.
- [x] **Task 3:** code + data.
- [x] **Task 4:** sprites (pose + speaker), sprite viewer.
- [ ] **Task 5:** full suite; user playtest.
