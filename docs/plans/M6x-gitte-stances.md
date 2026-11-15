# Gitte's + and − stances Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `+` gives Gitte red hands and ×1.25 knockback on every hit; `−` gives her blue hands and
a magnet tug on her normal attacks. This replaces the old "+ volley damage" and "− lifesteal".

**Architecture:** Everything lives in `StanceAbility`/`StanceData`. `+` goes through the existing
`modify_hit`/`modify_projectile` hooks. The tug goes through `resolve_contacts(match)`, which the
Match calls before it collects hits: it calls `take_hit`/`block_hit` with a built 0-damage
`MoveData`, so the Match's hit signals (spark and sound) never fire. The glow goes in `draw()`,
reading `slot_02/hands.json` from Gitte's sprite generator. No shared files change.

**Tech Stack:** Godot 4.7 GDScript, GUT; Python sprite generator (`tools/sprites/`).

**Spec:** `docs/specs/characters/gitte.md#gitte--scissors-and-stances` (and its `#look`).

## Global Constraints

- Work in `/home/mp/Desktop/SuperMMSBros-gitte` on `char/gitte`. Touch only Gitte-owned files.
- Tuning numbers live in `stances.tres`: `knockback` 1.25, `pull_cone_deg` 30, `pull_reach` 120,
  `pull_speed` 300, `small_scale` 0.75, `small_speed` 1.25, `large_scale` 1.25,
  `large_special` 1.3. Remove `projectile_damage` and `lifesteal`.
- Ticks only, no seconds. The glow's pulse is counted in `fighter.state_frame` ticks or a
  similar tick count, never in wall time. Drawing only reads.
- Static typing everywhere. Godot style guide.
- Test command: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd`
  (one file: add `-gtest=res://tests/test_gitte.gd`).

## Review Focus

- A victim inside the hitbox on the tug frame must be hit, not tugged. Covered by Task 2's
  `test_minus_jab_up_close_hits_normally`.
- The tug must aim at her center, including up and down. A grounded victim tugged upward toward
  an airborne Gitte must fly up, not along the floor. Covered by `test_tug_points_at_her_center`.
- Gitte tugging an opponent hanging on a ledge: `take_hit` clears the ledge, which is fine. Not
  tested, just watch for it in the playtest.
- She must never tug herself. Covered by `test_minus_doesnt_tug_herself`.
- One tug per attack: covered by `test_tug_happens_once`.

---

### Task 1: `+` knocks harder; data cleanup

**Files:**
- Modify: `super-mms-bros/characters/gitte/stance_data.gd`, `moves/stances.tres`,
  `stance_ability.gd`
- Test: `super-mms-bros/tests/test_gitte.gd` (replace `test_plus_projectiles_do_more_damage`, the
  three lifesteal tests, and the data assert in `test_gitte_has_her_own_specials`)

**Interfaces:**
- Produces: `StanceData.knockback: float`, `pull_cone_deg: float`, `pull_reach: float`,
  `pull_speed: float` (exported). `lifesteal()` is no longer overridden.

- [ ] **Step 1: Tests**
  - Data assert: `[s.knockback, s.pull_cone_deg, s.pull_reach, s.pull_speed, s.small_scale,
    s.small_speed, s.large_scale, s.large_special] == [1.25, 30.0, 120.0, 300.0, 0.75, 1.25, 1.25, 1.3]`.
  - `test_plus_knocks_harder`: jab at P2 15 px away. The launch speed is `_p2.velocity.length()`
    on the tick `_p2.percent` first changes. MINUS is the baseline (same size, and up close it
    doesn't tug): `assert_almost_eq(plus, minus * 1.25, 0.01)`.
  - `test_plus_keeps_damage`: the jab still does 3 % in PLUS.
  - `test_plus_volley_knocks_harder`: in PLUS the volley still does 4 damage, and the launch speed
    is ×1.25 the MINUS one.
  - `test_minus_doesnt_heal`: `_jab_heal(MINUS) == 20.0`.
- [ ] **Step 2: Run, expect FAIL** (missing fields, lifesteal still heals).
- [ ] **Step 3: Implement**
  - `modify_hit`: in PLUS, for any move, duplicate and multiply `base_knockback` and
    `knockback_growth` by `knockback`. Keep the × branch.
  - `modify_projectile` = `modify_hit(move_data, true)`.
  - Remove the `lifesteal()` override.
  - Update the doc comments.
- [ ] **Step 4: Run test_gitte.gd and test_gitte_pyramid.gd, expect PASS.**
- [ ] **Step 5: Commit** `Gitte: + stance knocks back ×1.25 instead of boosting the volley; − no longer heals`

### Task 2: `−` tug

**Files:**
- Modify: `super-mms-bros/characters/gitte/stance_ability.gd`
- Test: `super-mms-bros/tests/test_gitte.gd` (new section `# --- Minus: the tug`)

**Interfaces:**
- Consumes: Task 1's `StanceData` fields.
- Produces: `func resolve_contacts(match: Match) -> void` override.
  `static func in_cone(origin: Vector2, aim: Vector2, target: Vector2, cone_deg: float, reach: float) -> bool`.
  `func tug_data(from: Vector2, to: Vector2) -> Array` returns `[MoveData, side: int]`.

- [ ] **Step 1: Tests.** Gitte at (150, 192) facing right, MINUS, jab, unless stated. "After the
  tug" means stepping until the jab's first active frame has passed (the jab startup is in
  `_p1.stats.moveset.jab`).
  - `test_in_cone`: aim (1, 0), reach 120, 30°: (100, 0) true; (100, 50) true (26.6°);
    (100, 70) false (35°); (-100, 0) false; (130, 0) false.
  - `test_minus_tugs_in_front`: P2 at (230, 192). Afterwards `_p2.state == HITSTUN`,
    `_p2.velocity.x < 0`, `_p2.percent == 0.0`.
  - `test_tug_points_at_her_center`: P2 at (230, 192), with Gitte placed 40 px above P2's level
    (in the air, e.g. (150, 152)). Expect `_p2.velocity.y < 0` and `velocity.x < 0`.
  - `test_tug_speed`: the speed right after the tug is 300 (±1), whatever P2's % (set it to 0 and
    then 150).
  - `test_minus_doesnt_tug_behind`: P2 at (70, 192). `_p2.state != HITSTUN`, velocity.x == 0.
  - `test_minus_doesnt_tug_too_far`: P2 at (280, 192). Not tugged.
  - `test_minus_jab_up_close_hits_normally`: P2 at (165, 192). `_p2.percent == 3.0` and velocity
    is the jab's launch (x > 0).
  - `test_tug_happens_once`: P2 at (230, 192). Record velocity after the tug, step through the
    rest of the active frames, and expect no second restart (`_p2.state_frame` keeps counting up).
  - `test_shield_gets_nudged`: P2 holds shield (scripted `shield_held` inputs), at (230, 192).
    Afterwards `_p2.state == SHIELD`, `velocity.x < 0`, and `shield_health` is unchanged.
  - `test_intangible_isnt_tugged`: `_p2.invulnerable_frames = 60`. Not tugged.
  - `test_specials_dont_tug`: the cut in MINUS, P2 at (230, 192). Not tugged.
  - `test_other_stances_dont_tug`: PLUS jab, P2 at (230, 192). Not tugged.
  - `test_minus_doesnt_tug_herself`: P2 KO'd/far away. Gitte's own velocity is unaffected and
    nothing errors.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement `resolve_contacts`**
  - Act when `stance == MINUS`, `fighter.state == ATTACK`, `fighter.move in Fighter.NORMALS`,
    `fighter.is_hitbox_active()`, and the previous frame was not active
    (`not current_move().is_active_frame(fighter.state_frame - 1)`).
  - Aim = `fighter.get_hitbox_rect().get_center() - fighter.get_center()`.
  - For each other fighter in `match.get_fighters()`: skip when it can't be hit, when its hurtbox
    already intersects the hitbox, or when it isn't `in_cone`.
  - Build the tug with `tug_data`: a fresh `MoveData` with damage 0, `base_knockback = pull_speed`,
    growth 0, `angle_deg` = the angle of `(her center − its center)` with x made positive, and
    `side` = the sign of that x (`fighter.facing` when it's 0).
  - Shielding → `victim.block_hit(data, side)`. Otherwise →
    `victim.take_hit(data, side, fighter.global_position.x)`.
  - `take_hit` flips a downward launch on a grounded fighter. That only happens when Gitte is
    below a grounded fighter, which can't happen on one floor, so it's acceptable.
- [ ] **Step 4: Run test_gitte.gd, expect PASS.**
- [ ] **Step 5: Commit** `Gitte: − stance tugs opponents in her normals' cone toward her`

### Task 3: Hand glow (hands.json + drawing)

**Files:**
- Modify: `tools/sprites/characters/gitte.py` (write `hands.json` in `extra_files`).
- Regenerate: `super-mms-bros/assets/fighters/slot_02/` (`hands.json` is new; the strips should
  not change, so check with `git status`).
- Modify: `super-mms-bros/characters/gitte/stance_ability.gd` (`draw`, `glow_color`, `hands`).
- Test: `super-mms-bros/tests/test_gitte.gd` (section `# --- Look`)

**Interfaces:**
- Produces: `func glow_color() -> Color` (`Color.TRANSPARENT` unless + or −).
  `static func hands(character_id: String, animation: String, frame: int) -> Array[Vector2]`
  returns [front, back], or [] when the file has no entry. It's loaded once into a static
  dictionary, like `PotionAbility.front_hand`, but Gitte's own copy (character files don't share).

- [ ] **Step 1: Tests**
  - `test_hands_json_covers_her_drawings`: for each of "idle", "jab", "run", "forward_air",
    "down_special", "neutral_special", "up_special" in hands.json, the entry count equals that
    animation's drawing count in `FighterVisuals.ANIMATIONS`, and each entry is 2 points of 2
    numbers.
  - `test_glow_colors`: PLUS → red-ish (`r > 0.8, b < 0.4`), MINUS → blue-ish (`b > 0.8, r < 0.4`),
    DIVIDE and MULTIPLY → `a == 0`.
  - `test_hands_lookup`: `StanceAbility.hands(GITTE, "idle", 0).size() == 2`;
    `hands(GITTE, "nope", 0) == []`.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Generator.** Add `hands_json(c)` as in `tools/sprites/characters/mette.py`, but
  store `[front, back]` from `HANDS[0]`. Loop over `ANIMATIONS` plus her own `animations(c)` and
  the scissor animations. Use whatever animations the strips are written from, so the drawing
  counts match. Write it in `extra_files` when `c.get("weapon") == "scissors"`. Regenerate with
  the same command the other Gitte plans used (`docs/plans/M6k-gitte.md`), then
  `godot --headless --path super-mms-bros --import`.
- [ ] **Step 4: Drawing.** In `draw(visuals, animation, frame)`: if `glow_color().a > 0`, then for
  each hand in `hands(...)`, position = `hand * fighter.size_scale()` with x × `fighter.facing`.
  Draw a halo circle (radius 4, color alpha 0.35) and a core (radius 2, alpha 0.8). Pulse the
  halo radius ±0.5 over a 30-tick cycle using `visuals`' tick count (`fighter.state_frame` is
  fine). Colors are constants: `PLUS_GLOW = Color("#ff4a3d")`, `MINUS_GLOW = Color("#4aa8ff")`.
- [ ] **Step 5: Run the full suite, expect PASS** (including `test_character_split.gd`).
- [ ] **Step 6: Rebuild and republish the Sprites artifact** (memory rule). Ask the user to
  playtest the glow and the tug.
- [ ] **Step 7: Commit + push** `Gitte: red/blue hand glow in + and −`, plus memory updates.
