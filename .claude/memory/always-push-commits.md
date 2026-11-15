---
name: always-push-commits
description: User wants committed changes pushed to origin without asking each time
metadata:
  node_type: memory
  type: feedback
  originSessionId: 862d562a-5849-4fc4-8a0e-61f358e4ddf8
  modified: 2026-11-14T11:30:58.679Z
---

Always push committed changes to origin (e.g. `git push origin main` after a merge/commit).

**Why:** The user said "yes, always push committed changes" when asked whether to push. This overrides CLAUDE.md's "don't push unless asked".

**How to apply:** After committing or merging, push the branch. Still commit only when asked (or when a plan step says so). Don't force-push. See [[project-status]].
