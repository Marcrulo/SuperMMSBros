---
name: check-every-frame
description: When generating sprite changes, check every frame of every animation for stray/odd poses before showing the user
metadata:
  type: feedback
---

When a generated sprite change applies across all animations (e.g. Sjippepigen's extra arms), check every drawing of every animation, not just a few sample rows — the user spotted a single run frame where two extra arms shot upward.

**Why:** the user reviews all frames in the sprite viewer and notices one-frame glitches ("be careful not to have arms randomly going upwards").

**How to apply:** add an automatic sweep over `ANIMATIONS` (e.g. "no extra arm raised unless the main arm is") plus a zoomed look at the full preview sheet before publishing; then rebuild the sprite viewer artifact ([[project-status]]).
