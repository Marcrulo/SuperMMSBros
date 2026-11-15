---
name: hands-on-building
description: "Claude builds everything (scenes, resources, gameplay code, tests); user decides larger design questions and playtests/inspects visuals"
metadata:
  node_type: memory
  type: feedback
  originSessionId: aaefc143-0836-4f60-bdc0-9522361f8fdc
  modified: 2026-11-07T08:32:14.532Z
---

Claude builds the milestones itself: scenes, resources, gameplay code, tests, tooling, git. The user no longer wants to hand-build in the editor (changed 2026-11-03, during M2 Task 4: "you just go ahead and build things for me. This should also be the standard from now on"). This replaces the earlier 2026-09-15 preference where the user did the game-dev parts.

The user wants to be involved in **larger decisions** (design choices, trade-offs, anything that changes a spec) and to **playtest gameplay and inspect visuals**; they think they have a good eye for look and feel.

**Why:** Hand-building was slowing things down; the user's value is in judgment, feel and visuals, not clicking through the Inspector.

Don't send the user to the editor to look at files, scenes, resources or settings (no "editor tours", even when a plan step suggests one — skip those steps). The editor/game is for them only to playtest and validate how things look and feel. Reaffirmed 2026-11-03 after Claude offered an optional editor tour at the end of M2.

Batching: on 2026-11-07 the user chose to have M3–M6 built back to back (each with plan + tests) and only then playtest everything at once — "get the basics out of the way, then I point at things". Default to batching milestones unless they ask to see something sooner. BUT: after the M3–M6 batch (2026-11-07) the user said "you seem to work for quite a while… let's shrink the amount of work you do" — prefer smaller chunks (about one milestone) between check-ins, and keep status updates short.

**How to apply:** Run plan tasks inline without stopping for the user on routine steps (still no subagents unless asked). Stop and ask for genuine decisions. After anything visible or playable lands, ask the user to run it and give feedback on feel/visuals. Keep briefly explaining the Godot concepts behind what was built (CLAUDE.md "Talking to the user" still applies). Avoid writing `project.godot` or running `--import` while their editor is open.
