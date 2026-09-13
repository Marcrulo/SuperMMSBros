# Super MMS Bros — Vision

A small 2D platform fighter in the spirit of *Super Smash Bros*, with a pixel-art look, built in Godot 4.

## The game in one paragraph

Two fighters on a floating stage try to knock each other off. You lose a stock when you leave the
screen; lose all three and the match is over. The first version is deliberately tiny: one fighter
design, one stage, one attack, and a CPU opponent — just enough to be a real, playable game that
everything else can grow from.

## Pillars

1. **Simple and readable.** The core of Smash with as few mechanics as possible. Every mechanic has to
   earn its place.
2. **Feels good to control.** Tight movement and clear hits beat feature count. Numbers live in data
   files and get tuned by playtesting.
3. **Built to grow.** Local multiplayer, a trained AI opponent, online play, more depth and hand-drawn
   art are all planned for later — the first version is structured so they can be added without
   rewrites.
4. **Hand-made pixel art (later).** The game ships with placeholder shapes first; the final art will be
   drawn by hand in Pixelorama, following [the art guide](specs/art-guide.md).

## First version (v1) — in scope

- Single player: you vs one CPU opponent, 1v1, 3 stocks each.
- One fighter design, used by both players (red for you, blue for the CPU).
- Movement: run, jump, short hop, one double jump, drop through platforms.
- One attack button with fixed knockback and hitstun.
- KOs by leaving the blast zone; respawn with brief invulnerability.
- One stage: a Battlefield-style layout (main platform plus three pass-through platforms).
- Match flow: countdown → match → result screen (Restart / Quit). Pause menu on Esc.
- Keyboard and gamepad controls.
- Placeholder art (colored rectangles), rendered at 320×180 and scaled up pixel-perfectly.
- CPU vs CPU mode, including headless (no window) for automated testing.

## Explicitly out of scope for v1

- Damage % and knockback that scales with damage
- Directional attacks, special moves, shield, dodge, grabs, ledge grabbing
- More than one fighter design or stage
- Menus beyond pause and results (title screen, character/stage select, settings)
- Sound and music
- Local multiplayer, online play
- Trained (machine-learning) AI
- Final pixel art
- Match time limit

## Later — ideas, in no particular order

- **Hand-drawn pixel art** for fighters and stage (the code is already structured for it).
- **Damage %**: hits add damage and knockback grows with it — the classic Smash rule.
- **Deeper combat**: directional attacks (up/down/side/neutral), a special-move button, shield and dodge.
- **Trained AI opponent**: reinforcement learning via the Godot RL Agents plugin and Python libraries
  such as Stable-Baselines3, trained headless against the hand-written CPU.
- **Smarter hand-written CPU**: difficulty levels, edge-guarding (chasing opponents off stage).
- **Local multiplayer**: more human players via more input devices.
- **Online multiplayer**: would need rollback netcode.
- **Sound, menus, more fighters and stages.**
