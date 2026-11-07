# M3 — Stages and Camera Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); the user asked for no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Play M2's movement at 480×270 on any of the four themed stages, with the zooming camera.

**Architecture:** The look explored in the `spike-stage-look` branch, rebuilt to the specs: stages
and platform styles become resources (`StageData`, `PlatformStyle`), `Stage.apply()` dresses the
Battlefield scene, `PlatformLook` draws the perspective platforms, `MatchCamera` frames the
fighters. Gameplay geometry moves to the new layout; everything visual stays presentation only.

**Spec:** [match & stage](../specs/match-and-stage.md), [controls & display](../specs/controls-and-display.md), [architecture](../specs/architecture.md), [testing](../specs/testing.md)

## Global Constraints

- Godot 4.7.2, GUT 9.7.1; run from the repo root; `--import` only with the editor closed.
- Static typing, `class_name` on reusable types, tabs; tuning values in resources.
- Presentation (PlatformLook, background, camera) never changes gameplay state.
- Test command: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd`.
- Branch `v1-rework`; commits end with the `Co-Authored-By` line.

## Review Focus

1. A stage's look must not change collision: the same layout on every stage → `test_every_stage_has_the_same_layout`.
2. Side faces collapsing to no area when the camera looks along a platform end → `test_collapsed_shapes_are_skipped`.
3. Camera zoomed out past the blast zone → `test_zoom_is_clamped`, `test_view_stays_inside_the_blast_zone`.
4. An unknown `--stage` id → falls back to `mms` → `test_unknown_stage_falls_back_to_mms`.
5. Fighter respawn reached through the blast zone on every side → respawn tests.

---

### Task 1: Display settings and the new layout

**Files:** `project.godot`, `stage/battlefield.tscn`, `stage/stage.gd`; tests `test_project_setup.gd`, `test_stage.gd`, `test_fighter_movement.gd`, `test_match.gd`.

- [ ] Update the tests to the spec: viewport 480×270, window 1440×810, stretch `canvas_items`, snap off; main platform `Rect2(96, 192, 288, 16)`, left `Rect2(132, 160, 72, 4)`, right `Rect2(276, 160, 72, 4)`, top `Rect2(204, 128, 72, 4)`; spawns (168, 192) and (312, 192); `blast_zone == Rect2(-120, -200, 720, 520)`. Movement test constants: `FLOOR_Y 192`, `PLATFORM_Y 160`, `OPEN_SKY (110, 192)`, `UNDER_LEFT_PLATFORM (168, 192)`, ledge walk from (372, 192), middle (240, 192); match spawn positions likewise.
- [ ] Run: those tests fail on the old values.
- [ ] Change `project.godot` and the scene/script to the spec values. Run: all pass. Commit.

### Task 2: Stage data, styles and `Stage.apply()`

**Files:** create `stage/stage_data.gd`, `stage/platform_style.gd`, `stage/styles/{school_brick,modern,castle}.tres`, `stage/stages/{mms,fc,slot_day,slot_sunset}.tres`, `stage/background.gdshader`, `stage/background_parallax.gd`; modify `stage/stage.gd`, `stage/battlefield.tscn`, `match/match.gd`; copy `assets/stage/backgrounds/*.png` (528×297) from the spike; test `test_stage_data.gd`.

- `StageData` (`Resource`): `id`, `display_name`, `background: Texture2D`, `style: PlatformStyle`, `haze_color`, `light_color`. `static func load_stage(id: String) -> StageData` loads `res://stage/stages/<id>.tres`, falling back to `mms`.
- `PlatformStyle` (`Resource`): `top`, `top_edge`, `shadow`, `far_shadow`, `side`, `under` colors; `main_bands`, `thin_bands: Array` (band arrays as in the spec); `quoins: Color`, `has_quoins: bool`.
- `Stage.apply(data: StageData)`: background texture, haze shader parameter, `Light` (`CanvasModulate`) color, `PlatformLook.style`. Match reads `--stage=<id>` in `_ready()` and applies it before `reset()`.
- [ ] Tests: each of the four ids loads with the spec's `display_name`, a 528×297 background and its style; `slot_sunset` light (1.0, 0.85, 0.70) and the others white; `test_unknown_stage_falls_back_to_mms`; `test_every_stage_has_the_same_layout` (apply each, collision rects unchanged); `apply()` sets the `Light` color and the shader's `haze_color`.
- [ ] Run: fail. Implement. Run: pass. Commit.

### Task 3: Perspective platform drawing

**Files:** create `stage/platform_look.gd` (port of the spike's `stage_look_spike.gd`, reading a `PlatformStyle`); test `test_platform_look.gd`.

- `static func perspective_x(x: float, depth: float, vanish_x: float) -> float` = `vanish_x + (x − vanish_x) × (1 + 0.011 × depth)`.
- `static func is_fillable(points: PackedVector2Array) -> bool` (`Geometry2D.triangulate_polygon` not empty); every filled shape goes through it.
- [ ] Tests: `perspective_x` at depth 0 returns x for any vanish x; at depth 6, x 96 with vanish 240 → 86.496; `test_collapsed_shapes_are_skipped`: a zero-width quad is not fillable, a normal one is; a camera sweep within ±0.1 px of each thin platform's ends in 0.001 steps draws without any unfillable shape reaching `draw_colored_polygon` (count via a test hook).
- [ ] Run: fail. Implement. Run: pass. Commit.

### Task 4: The camera

**Files:** create `match/match_camera.gd`; modify `match/match.tscn`; test `test_match_camera.gd`.

- `static func target_framing(points: Array[Vector2], blast_zone: Rect2) -> Dictionary` returns `{position: Vector2, zoom: float}`: box around the points plus the stage focus (240, 160), grown 120 px sideways and 80 px vertically; zoom = min(480 / w, 270 / h) clamped to 0.67…1.4; position clamped so the 480/zoom × 270/zoom view stays inside the blast zone.
- `_process` glides toward the target (`1 − e^(−4·delta)`), first frame jumps; KO'd fighters are skipped (M7).
- [ ] Tests: two fighters at the spawns → centered between them and the focus, zoom within range; fighters far apart → `test_zoom_is_clamped` at 0.67; `test_view_stays_inside_the_blast_zone` for a fighter near a blast-zone corner; a lone point at the focus → zoom 1.4.
- [ ] Run: fail. Implement. Run: pass. Commit.

### Task 5: Instant respawn (until M7)

**Files:** `fighter/fighter.gd` (`get_center()`), `match/match.gd`; tests in `test_match.gd`.

- [ ] Tests: a fighter moved past each side of the blast zone (left, right, bottom) is back at its spawn after one step, facing its spawn facing, velocity zero, `IDLE`; inside the blast zone it stays.
- [ ] Run: fail. Implement (`_respawn_fighters_out_of_bounds()` after the fighters tick). Run: pass. Commit.

### Task 6: Check it runs

- [ ] Headless runs with `--stage=` each id: no errors. Mark this plan done.
