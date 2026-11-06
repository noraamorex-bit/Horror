#!/usr/bin/env python3
"""Strict rest check (v146): every object in the house (an outermost model, or a group of touching loose parts) must sit
exactly on whatever is under it: the floor, a table top, a shelf. For each object's lowest parts, the highest surface below
them (any other part whose footprint overlaps theirs, within 0.6 under to 0.3 inside) gives the gap: + it floats, - it's
pushed in. Wall- and ceiling-hung things are skipped (they touch a wall within 0.07 or hang from above).
  python3 tools/rest_audit.py <stage.json> [threshold=0.04]
"""
import json, sys, collections, math
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from house_audit import bbox, INTERIOR, WALLISH, overlap

def main():
    d = json.load(open(sys.argv[1]))
    thr = float(sys.argv[2]) if len(sys.argv) > 2 else 0.04
    parts = d["parts"]
    for p in parts:
        p["bb"] = bbox(p)
        p["top"] = p["path"].split("/")[0] if p["path"] else ""
    walls = [p for p in parts if p["top"] in ("Structure", "Finishes") and p["n"].startswith(WALLISH) and p["s"][1] > 1.0]
    # objects
    objs = collections.defaultdict(list)
    loose = [i for i, p in enumerate(parts) if p["top"] in INTERIOR and not p.get("oid")]
    parent = {i: i for i in loose}
    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]; i = parent[i]
        return i
    byPath = collections.defaultdict(list)
    for i in loose: byPath[parts[i]["path"]].append(i)
    for ids in byPath.values():
        for a in range(len(ids)):
            ba = parts[ids[a]]["bb"]; ga = (ba[0]-.05, ba[1]-.05, ba[2]-.05, ba[3]+.05, ba[4]+.05, ba[5]+.05)
            for b in range(a + 1, len(ids)):
                if overlap(ga, parts[ids[b]]["bb"]): parent[find(ids[a])] = find(ids[b])
    for i, p in enumerate(parts):
        if p["top"] in INTERIOR:
            objs[("o", p["oid"]) if p.get("oid") else ("p", find(i))].append((i, p))
    cell = 4.0
    grid = collections.defaultdict(list)
    for i, p in enumerate(parts):
        b = p["bb"]
        for gx in range(int(math.floor(b[0] / cell)), int(math.floor(b[3] / cell)) + 1):
            for gz in range(int(math.floor(b[2] / cell)), int(math.floor(b[5] / cell)) + 1):
                grid[(gx, gz)].append(i)
    rows = []
    for key, ps in objs.items():
        vis = [(i, p) for i, p in ps if p["tr"] < 0.95]
        if not vis: continue
        B = [min(p["bb"][k] for _, p in vis) if k < 3 else max(p["bb"][k] for _, p in vis) for k in range(6)]
        mine = set(i for i, _ in ps)
        # hung on a wall or from the ceiling: skip
        pad = (B[0] - .07, B[1], B[2] - .07, B[3] + .07, B[4], B[5] + .07)
        if any(overlap(pad, w["bb"]) for w in walls) and B[1] > 1.5 + (14 if B[1] > 14 else 0) - 0.0 and (B[1] % 14) > 0.6:
            continue
        low = [p for _, p in vis if p["bb"][1] < B[1] + 0.05]
        best = None
        for lp in low:
            lb = lp["bb"]
            seen = set()
            for gx in range(int(math.floor(lb[0] / cell)), int(math.floor(lb[3] / cell)) + 1):
                for gz in range(int(math.floor(lb[2] / cell)), int(math.floor(lb[5] / cell)) + 1):
                    for j in grid[(gx, gz)]:
                        if j in mine or j in seen: continue
                        seen.add(j)
                        q = parts[j]
                        if q["tr"] >= 0.95: continue
                        qb = q["bb"]
                        # footprint overlap (inset a little so neighbours touching side-on don't count)
                        if not (qb[0] < lb[3] - 0.03 and lb[0] + 0.03 < qb[3] and qb[2] < lb[5] - 0.03 and lb[2] + 0.03 < qb[5]): continue
                        # (a support starts below the object: not a plate lying on the placemat in question)
                        if lb[1] - 0.6 <= qb[4] <= lb[1] + 0.3 and qb[1] < lb[1] - 0.005:
                            if best is None or qb[4] > best[0]: best = (qb[4], q)
        if best is None:
            continue
        gap = B[1] - best[0]
        if abs(gap) > thr:
            lab = vis[0][1]["path"] + ("" if key[0] == "o" else "/" + vis[0][1]["n"])
            rows.append((gap, lab, (B[0] + B[3]) / 2, B[1], (B[2] + B[5]) / 2, best[1]["path"] + "/" + best[1]["n"]))
    rows.sort(key=lambda r: -abs(r[0]))
    for r in rows:
        print("%+.2f  %-40s at (%.1f, %.2f, %.1f) on %s" % r)
    print("REST:", len(rows), "objects off their surface by more than", thr)

main()
