# Super MMS Bros — Vision

A small 2D platform fighter in the spirit of *Super Smash Bros*, with a pixel-art look, built in Godot 4.

## The game in one paragraph

Two fighters on a floating stage try to knock each other off. Every hit adds damage %, and the
higher your %, the farther hits launch you. You lose a stock when you're launched out of the blast
zone; lose all three and the match is over. The stages are real places in Denmark — Marie Mørks
Skole, Frederiksborgcenteret and Frederiksborg Slot — drawn as pixel-art backdrops behind
perspective platforms. v1 has one fighter design with a full Smash-style move set, and a CPU
opponent.

## Pillars

1. **Simple and readable.** The core of Smash with as few mechanics as possible. Every mechanic has to
   earn its place.
2. **Feels good to control.** Tight movement and clear hits beat feature count. Numbers live in data
   files and get tuned by playtesting.
3. **Built to grow.** More characters, local multiplayer (up to 4 players), a trained AI opponent,
   online play and hand-drawn art are all planned for later — v1 is structured so they can be added
   without rewrites. Characters, moves and stages are data.
4. **Hand-made pixel art (later).** v1 ships with generated placeholder sprites; the final art will
   be drawn by hand in Pixelorama, following [the art guide](specs/art-guide.md).

## First version (v1) — in scope

- Single player: you vs one CPU opponent, 1v1, 3 stocks each.
- One fighter design ("default"), used by both players (red shirt for P1, blue for P2), drawn as
  big-headed pixel-art sprites (generated placeholders).
- Movement: run, jump, short hop, one double jump, crouch, drop through platforms, shield.
- Damage % and knockback that grows with it.
- Attacks (Smash terms): jab (A), down tilt (Down+A), up tilt (Up+A), side tilt (Side+A); the same
  moves in the air.
- Default specials: neutral B (charged punch), down B (ground energy burst), side B (projectile),
  up B (jump boost, then helpless until landing).
- KOs by leaving the blast zone; respawn with brief invulnerability.
- Five stages sharing a Battlefield-style layout (main platform plus three pass-through platforms),
  each with its own background, platform style and light: **MMS**,
  **Frederiksborgcenteret**, **Frederiksborg Castle Sunset**, **Cafe Station** and **Lindevej**.
  Chosen on a stage select screen (or with a command-line option).
- 480×270 pixel-art rendering, smooth-zooming camera that frames the fighters.
- Five air attacks (neutral, forward, back, up, down) next to the four ground attacks.
- Character select (one playable character, the rest locked) and stage select before the match
  (see [menus](specs/menus.md)).
- Match flow: countdown → match → result screen (Restart / Quit). Pause menu on Esc.
- Keyboard and gamepad controls.
- CPU vs CPU mode, including headless (no window) for automated testing.

## Explicitly out of scope for v1

- More than one fighter design (the character select shows locked slots for later ones); smash
  attacks; dodges, grabs,
  ledge grabbing
- Different stage layouts
- Menus beyond character select, stage select, pause and results (title screen, settings)
- Sound effects (each stage has looping music)
- Local multiplayer, online play
- Trained (machine-learning) AI
- Final hand-drawn pixel art
- Match time limit

## Later — ideas, in no particular order

- **More characters**, each with their own sprites, stats and special moves (the default set is
  the template).
- **Hand-drawn pixel art** for fighters and platforms (the code already loads sprite strips).
- **Deeper combat**: smash attacks, dodges, grabs, ledges.
- **Local multiplayer with up to 4 players** (stages are already sized for it).
- **Different stage layouts.**
- **Trained AI opponent**: reinforcement learning via the Godot RL Agents plugin and Python libraries
  such as Stable-Baselines3, trained headless against the hand-written CPU.
- **Smarter hand-written CPU**: difficulty levels, edge-guarding.
- **Online multiplayer**: would need rollback netcode.
- **Sound effects** and more menus (title screen, settings).
