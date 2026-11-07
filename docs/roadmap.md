# Roadmap

Each milestone ends with something you can run and try. Each gets its own implementation plan in
[`plans/`](plans/) before work starts. Specs live in [`specs/`](specs/).

The design was reworked after M2 (bigger resolution, moving camera, four stages, sprites, a full
move set, damage %). The look was explored first in throwaway spike branches
(`spike-stage-look`, `spike-fighter-body`); the milestones below build it properly, with tests.
The parked `m3-attack` branch (one attack, fixed knockback, dummy) is reused inside M5.

| # | Milestone | Done when you can… | Main specs |
|---|---|---|---|
| M1 | Project setup ✅ | open the project, run it, and run the test suite from the terminal | [architecture](specs/architecture.md), [controls & display](specs/controls-and-display.md), [testing](specs/testing.md) |
| M2 | Movement on the stage ✅ | run, jump, short hop, double jump and drop through platforms | [fighter](specs/fighter.md), [match & stage](specs/match-and-stage.md) |
| M3 | Stages and camera | play M2's movement at 480×270 on any of the four themed stages, with the zooming camera | [match & stage](specs/match-and-stage.md), [controls & display](specs/controls-and-display.md) |
| M4 | Sprites, crouch and new controls | move a big-headed sprite fighter with the new key layout, crouch, and drop through platforms with a double tap | [fighter](specs/fighter.md), [art guide](specs/art-guide.md), [controls & display](specs/controls-and-display.md) |
| M5 | Attacks and damage % | hit a dummy with jab and the three tilts (on the ground and in the air), see its % rise and knock it off the stage | [fighter](specs/fighter.md), [moves](specs/moves.md) |
| M6 | Shield and specials | shield, break a shield, and use all four specials, including the projectile and the up B recovery | [fighter](specs/fighter.md), [moves](specs/moves.md) |
| M6b | Launch angles and aerials | feel each move launch along its own angle, use five air attacks, and spike with the Down B dive | [moves](specs/moves.md) |
| M6c | Select screens | pick your fighter (nine more slots locked) and a stage before the match | [menus](specs/menus.md) |
| M7 | Match rules | play a full match against the dummy: countdown, KOs, stocks, respawn, damage HUD, win/draw, results, pause, restart | [match & stage](specs/match-and-stage.md) |
| M8 | CPU opponent | play a real match against the CPU; watch CPU vs CPU; run a headless CPU vs CPU match to completion | [cpu](specs/cpu.md), [architecture](specs/architecture.md) |
| M9 | Tuning and polish | play a match that feels good — **v1 done** | all |

## Milestone details

### M1 — Project setup ✅
- Display settings and the Input Map actions, folder structure, GUT, a pixel font.

### M2 — Movement on the stage ✅
- `FighterStats`, `FighterInput`, controllers, the fighter's movement states, the Battlefield
  stage, the Match tick loop.

### M3 — Stages and camera
- 480×270 display with `canvas_items` stretch; the Battlefield layout scaled to the new size.
- `StageData` resources for the four stages (name, background, platform style, haze, light) and
  `--stage=<id>`.
- Perspective platform drawing in each stage's style, with shadows and side faces; hazed
  background with slight parallax; per-stage light.
- The smash-style camera.
- Blast zone and instant respawn (the M7 KO rule replaces it).

### M4 — Sprites, crouch and new controls
- New Input Map: `up`, `special`, `shield`; W is `up`, Space jumps.
- Placeholder sprite generator (`tools/gen_placeholder_sprites.py`) and the sprite-based
  `FighterVisuals`, with the P2 shirt recolor.
- Hurtbox that covers the head; `CROUCH` with its smaller hurtbox; double-tap drop-through.
- Hitbox/hurtbox debug view (F1).

### M5 — Attacks and damage %
- `MoveData` resources and the move table; jab, down tilt, up tilt, side tilt, in the air too.
- Damage %, scaling knockback and hitstun; hit resolution in the Match (from `m3-attack`).
- A dummy P2.

### M6 — Shield and specials
- `SHIELD`, shield health, block stun, shield break.
- Neutral B (charge), down B (burst, with the air dive), side B (projectile, owned by the Match),
  up B (boost, then `HELPLESS`).

### M7 — Match rules
- Done early, from playtest feedback: `KO` state, stocks, respawn with invulnerability, the
  smaller blast zone, and the HUD's player cards (portrait, name, stocks, damage %).
- `KO` state, stocks, respawn with invulnerability, win/draw.
- Phases, countdown, `reset()`, seeded RNG, game-state snapshot.
- HUD: damage % and stock icons, countdown, off-screen arrows, result screen, pause menu.

### M8 — CPU opponent
- `CpuController` and `CpuSettings`, using the move set.
- Command-line options (`--p1`, `--p2`, `--seed`, `--autoquit`, `--speed`, `--max-ticks`).
- Headless end-to-end test.

### M9 — Tuning and polish
- Playtest and tune movement, moves, knockback, stages, camera and CPU.
- Fix whatever feels wrong. Update specs with the final numbers.
