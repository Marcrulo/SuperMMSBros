# M6x — Nina's Lullaby Implementation Plan

**Goal:** Nina's Down+B is a song: everyone within range (shield or not) falls asleep for 2 s.
She sings (own strip) and pixel music notes float out to the song's range; sleepers show "z"s.

**Architecture:** `SongData` (AbilityData on `down_special`) + `SongAbility` (phase `song`: picks
the special on the ground and in the air, hovers, puts fighters to sleep with `Fighter.stun()`,
draws the notes) + `SleepMark` (MatchEntity that follows a sleeper and draws its "z"s). Her
singing strip comes from `tools/sprites/characters/nina.py`. No shared files.

**Spec:** [nina](../specs/characters/nina.md#down-special--lullaby)

- [x] **Task 1:** spec.
- [x] **Task 2:** tests — `tests/test_nina_song.gd`.
- [x] **Task 3:** code + data.
- [x] **Task 4:** singing strip (sprite generator) + Sprites artifact.
- [ ] **Task 5:** full suite; user playtest.
