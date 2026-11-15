"""Nina's own drawings for the 64 px sprite generator (docs/specs/characters/nina.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)


# --- Nina's lullaby (her down special) --------------------------------------------------------

# The shared head's open grin (rows 10-13, columns 19-27 of the head grid), and the round "O"
# she sings with instead, centred under her nose.
GRIN = [(r, col) for r in range(10, 14) for col in range(19, 28)]
SING_MOUTH = [(11, 22), (11, 23), (11, 24),
              (12, 21), (12, 22), (12, 23), (12, 24), (12, 25),
              (13, 22), (13, 23), (13, 24)]
# Hands clasped at her chest (both forearms folded up in front).
CLASPED = dict(fa=0.55, fe=2.3, ba=0.45, be=2.2)
SINGING = [
    # 0: a breath in, hands rising to her chest.
    pose(bob=-0.5, fa=0.35, fe=1.4, ba=0.25, be=1.2),
    # 1-3: singing, eyes shut, head up, swaying back, upright, forward (shown 1, 2, 3, 2, ...).
    pose(sing=True, lean=-2, head_dx=-1, head_dy=-1, **CLASPED),
    pose(sing=True, head_dy=-1, **CLASPED),
    pose(sing=True, lean=2, head_dx=1, head_dy=-1, **CLASPED),
    # 4: done, hands lowering.
    pose(fa=0.3, fe=0.7, ba=0.2, be=0.6)]
SING_ANIMATIONS = {"down_special": SINGING}


def sing_head(heads):
    """The shut-eyed head with the grin turned into a round singing mouth."""
    behind, front = heads["shut"]
    front = dict(front)
    for key in GRIN:
        if front.get(key) in ("O", "T"):
            front[key] = "S"
    for key in SING_MOUTH:
        front[key] = "O"
    return behind, front


def draw_sing(ps, c, p, heads):
    """A singing drawing: the usual body, with the singing face."""
    ps = dict(ps, face="sing")
    del ps["sing"]
    return draw_frame(ps, c, p, dict(heads, sing=sing_head(heads)))


DRAWERS["sing"] = draw_sing


def applies(c):
    return c.get("lullaby")


def animations(c):
    return dict(SING_ANIMATIONS) if c.get("lullaby") else {}
