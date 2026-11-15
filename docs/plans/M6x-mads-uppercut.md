# Mads's rising uppercut Implementation Plan

**Goal:** Mads's up special becomes a rising uppercut: 3 invincible startup frames, a fast
diagonal rise with a strong clean hit on its first 4 frames and a weak late hit after, then
`HELPLESS` at the top.

**Architecture:** `UppercutAbility`/`UppercutData` in `characters/mads/`, on `up_special.tres`
(`ability`). The ability `replaces(&"up_special")` (no jump boost). In `move_tick`, on the frame
`startup` it turns toward the held side, sets the rise velocity and switches to its own phase
`uppercut_rise` (state_frame 0), like Kim's ladder. `phase_movement` applies its own gravity, no
steering. `phase_data` returns `clean_hit` or `late_hit` (their `startup`/`active` count rise
frames, so the shared `is_active_frame` picks the right one). When the rise stops
(`left_floor_in_move` / `on_floor_in_move`, velocity.y ≥ 0) it hands back to the default:
`move = up_special`, `launched = true`, so the fighter's own code makes him `HELPLESS` (or lands).
`can_be_hit` is false on move frames 1–`invulnerable_frames`. Drawings: Mads's own `up_special`
poses in `tools/sprites/characters/mads.py`; `drawing()` maps startup → 0, clean → 1, late → 2.
No shared files change.

**Spec:** `docs/specs/characters/mads.md#mads--grappler` (up special) and its `#look`.

## Steps

- [ ] Spec (done first).
- [ ] Tests `tests/test_mads_uppercut.gd`: data matches the spec; startup 3 then rises (up and
  toward facing), turns to the held side; unhittable frames 1–5, hittable on 6; clean hit on rise
  frames 1–4 (13 %), late hit after (5 %), each fighter hit once; HELPLESS at the top; once per
  air stay; the drawing per frame. Update `test_only_his_side_special_changes`.
- [ ] `UppercutData`, `UppercutAbility`, the `.tres` files; moveset points at the new up special.
- [ ] Sprites: his three `up_special` poses; regenerate slot_11; check every frame; republish
  the Sprites artifact.
- [ ] Full test suite headless; ask the user to playtest.
