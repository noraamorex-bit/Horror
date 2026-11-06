#!/usr/bin/env python3
"""actpose_view: draw the player action poses (tools/harness/actpose_dump.luau) as stick figures:
side and front (third person) and the first-person view (what's on your screen).
usage: python3 actpose_view.py poses.json out.png"""
import json, sys, math
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

poses = json.load(open(sys.argv[1]))
kinds = sorted({p["kind"] for p in poses})
fig, axes = plt.subplots(len(kinds), 3, figsize=(9, 2.6 * len(kinds)))

def body(ax, p, proj):
    u = p["upper"]
    c = u[0]; up = u[1]
    top = [c[i] + up[i] * 0.8 for i in range(3)]
    bot = [c[i] - up[i] * 0.8 for i in range(3)]
    # legs (static) and torso
    for x in (-0.5, 0.5):
        ax.plot(*proj([[x, -0.2, 0], [x, -2.1, 0]]), color="#999", lw=6)
    ax.plot(*proj([bot, top]), color="#555", lw=14)
    h = p["head"][0]
    ax.plot(*proj([h]), "o", color="#c96", ms=22)
    hl = p["head"][1]
    ax.plot(*proj([h, [h[i] + hl[i] * 0.6 for i in range(3)]]), color="#c96", lw=2)
    for side, col in (("R", "#d33"), ("L", "#36c")):
        pts = p[side]
        ax.plot(*proj(pts), color=col, lw=4, marker="o", ms=4)

for r, k in enumerate(kinds):
    tp = next(p for p in poses if p["kind"] == k and not p["fp"])
    fpp = next(p for p in poses if p["kind"] == k and p["fp"])
    side = lambda pts: ([-q[2] for q in pts], [q[1] for q in pts])  # forward = right
    front = lambda pts: ([-q[0] for q in pts], [q[1] for q in pts])  # facing us
    for ax, proj, title in ((axes[r][0], side, "side"), (axes[r][1], front, "front")):
        body(ax, tp, proj)
        ax.set_xlim(-2, 2.5); ax.set_ylim(-2.3, 2.3); ax.set_aspect("equal"); ax.axis("off")
        ax.set_title(f"{k} {title}", fontsize=8)
    # first person: perspective from the eye (head centre in the waist-only frame), fov 70
    ax = axes[r][2]
    eye = [0, 0.2 + 0.8 + 0.8 + 0.5, 0]  # LowerTorso space: waist 0.2, upper 0.8, neck 0.8 (unleaned)
    f = 1 / math.tan(math.radians(35))
    def fpproj(pts):
        xs, ys = [], []
        for q in pts:
            d = [q[i] - eye[i] for i in range(3)]
            z = -d[2]
            if z < 0.05:
                z = 0.05
            xs.append(d[0] / z * f); ys.append(d[1] / z * f)
        return xs, ys
    for side_, col in (("R", "#d33"), ("L", "#36c")):
        ax.plot(*fpproj(fpp[side_]), color=col, lw=4, marker="o", ms=4)
    ax.add_patch(plt.Rectangle((-16/9, -1), 32/9, 2, fill=False, color="k"))
    ax.set_xlim(-2, 2); ax.set_ylim(-1.2, 1.2); ax.set_aspect("equal"); ax.axis("off")
    ax.set_title(f"{k} first person", fontsize=8)
plt.tight_layout()
plt.savefig(sys.argv[2], dpi=70)
