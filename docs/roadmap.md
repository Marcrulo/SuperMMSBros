# Roadmap

Each milestone ends with something you can run and try. Each gets its own implementation plan in
[`plans/`](plans/) before work starts. Specs live in [`specs/`](specs/).

| # | Milestone | Done when you can… | Main specs |
|---|---|---|---|
| M1 | Project setup | open the project, run it (empty screen at 320×180, scaled), and run the (empty) test suite from the terminal | [architecture](specs/architecture.md), [controls & display](specs/controls-and-display.md), [testing](specs/testing.md) |
| M2 | Movement on the stage | run, jump, short hop, double jump and drop through platforms on the Battlefield stage | [fighter](specs/fighter.md), [match & stage](specs/match-and-stage.md) |
| M3 | Attack, knockback, hitstun | hit a standing dummy fighter and knock it off the stage | [fighter](specs/fighter.md) |
| M4 | Match rules | play a full match against the dummy: countdown, KOs, stocks, respawn, win/draw, results, pause, restart | [match & stage](specs/match-and-stage.md) |
| M5 | CPU opponent | play a real match against the CPU; watch CPU vs CPU; run a headless CPU vs CPU match to completion | [cpu](specs/cpu.md), [architecture](specs/architecture.md) |
| M6 | Tuning and polish | play a match that feels good — **v1 done** | all |

## Milestone details

### M1 — Project setup
- Display settings (320×180, integer scaling, nearest filtering) and the Input Map actions.
- Folder structure from the architecture spec.
- GUT test framework installed; one trivial test passes headless.
- A pixel font in `assets/fonts/`.

### M2 — Movement on the stage
- `FighterStats` resource, `FighterInput`, `Controller` base class, `KeyboardController`,
  `ScriptedController` (used by the tests).
- Fighter scene with movement states (`IDLE`, `RUN`, `AIR`) and placeholder visuals.
- Battlefield stage scene with solid ground and one-way platforms.
- Match scene that drives the tick (no rules yet) with one keyboard-controlled fighter.

### M3 — Attack, knockback, hitstun
- `ATTACK` and `HITSTUN` states, hitboxes and hurtboxes, hit resolution in the Match.
- A second fighter driven by a `ScriptedController` that does nothing (the dummy).

### M4 — Match rules
- Blast zone and `KO` state, stocks, respawn with invulnerability, win/draw detection.
- Match phases, countdown, `reset()`, seeded RNG, game-state snapshot.
- HUD: stock icons, countdown, off-screen arrows, result screen, pause menu.

### M5 — CPU opponent
- `CpuController` and `CpuSettings`.
- Command-line options (`--p1`, `--p2`, `--seed`, `--autoquit`, `--speed`, `--max-ticks`).
- Headless end-to-end test.

### M6 — Tuning and polish
- Playtest and tune movement, knockback, stage layout and CPU settings.
- Fix whatever feels wrong. Update specs with the final numbers.
