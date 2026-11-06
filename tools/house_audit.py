#!/usr/bin/env python3
"""House audit (v145): every piece of furniture and dressing checked against the floors, walls and each other.
  cd tools/harness && lune run stage_dump.luau <stage.json>
  python3 tools/house_audit.py <stage.json> [--all]
Reports, per object (an outermost Model, or a loose part):
  SUNK     its bottom is below the floor it stands on
  FLOAT    its bottom is above the floor with nothing under it and no wall behind it
  WALL     it pushes into a wall (or the wall's paint / panelling / skirting)
  FACING   its front (Kit/Dress pivot, local -Z) points at a wall it stands against, its back to the room
  CLIP     two objects pass through each other
"""
import json, sys, math, collections

FLOORS = {"Basement": -13, "Ground": 1, "Upstairs": 15, "Attic": 29}
INTERIOR = {"Kitchen", "Living", "Master", "Den", "Office", "Basement", "Jamie", "Lily", "Garage", "UpperHall", "Hallway",
            "Guest", "AtticJunk", "MasterBath", "HallBath", "Nest", "Mudroom", "Bathroom", "MudHall", "Boiler", "FinishArt"}
ROOMS = [  # (name, floor, x0, x1, z0, z1): Rooms.List, small rooms first
    ("Boiler", "Basement", -40, -20, 10, 30), ("Basement", "Basement", -40, 12, -30, 30),
    ("Living", "Ground", -40, -8, -30, 2), ("Kitchen", "Ground", -40, -8, 2, 30), ("Office", "Ground", 12, 40, -30, -10),
    ("Bathroom", "Ground", 12, 22, -4, 4), ("MudHall", "Ground", 12, 22, -10, -4), ("Mudroom", "Ground", 22, 40, -10, 4),
    ("Den", "Ground", 12, 40, 4, 30), ("Hallway", "Ground", -8, 12, -30, 30), ("Garage", "Ground", 40, 66, -30, 6),
    ("Master", "Upstairs", -40, -8, -30, 0), ("MasterBath", "Upstairs", -40, -8, 0, 12), ("Jamie", "Upstairs", -40, -8, 12, 30),
    ("Guest", "Upstairs", 12, 40, -30, -6), ("HallBath", "Upstairs", 12, 40, -6, 8), ("Lily", "Upstairs", 12, 40, 8, 30),
    ("UpperHall", "Upstairs", -8, 12, -30, 30), ("Attic", "Attic", -40, 40, -30, 30),
]
WALLISH = ("Wall", "Paint", "Wainscot", "Baseboard", "ChairRail", "Crown", "BasementWall", "Siding", "Casing", "Tile", "Backsplash")
FLOORISH = ("Floor", "Slab", "HallFloor", "Foundation", "Mat")
SMALL = 0.18  # parts thinner than this in every direction but one (trim, decals) don't count as "pushing in"


def bbox(p):
    c = p["c"]
    x, y, z = c[0], c[1], c[2]
    R = c[3:12]
    hx, hy, hz = p["s"][0] / 2, p["s"][1] / 2, p["s"][2] / 2
    ex = abs(R[0]) * hx + abs(R[1]) * hy + abs(R[2]) * hz
    ey = abs(R[3]) * hx + abs(R[4]) * hy + abs(R[5]) * hz
    ez = abs(R[6]) * hx + abs(R[7]) * hy + abs(R[8]) * hz
    return (x - ex, y - ey, z - ez, x + ex, y + ey, z + ez)


def room_of(x, y, z):
    for name, fl, x0, x1, z0, z1 in ROOMS:
        f = FLOORS[fl]
        if x0 <= x <= x1 and z0 <= z <= z1 and f - 1.5 <= y <= f + 13.5:
            return name, f
    return None, None


def overlap(a, b, pad=0.0):
    return all(a[i] < b[i + 3] - pad and b[i] < a[i + 3] - pad for i in range(3))


def pen(a, b):
    return min(min(a[i + 3], b[i + 3]) - max(a[i], b[i]) for i in range(3))


def main():
    d = json.load(open(sys.argv[1]))
    show_all = "--all" in sys.argv
    parts = d["parts"]
    for p in parts:
        p["bb"] = bbox(p)
        p["top"] = p["path"].split("/")[0] if p["path"] else ""
        # (Finish's framed art counts as a wall object too, so it's checked against everything else hung there)
        if p["top"] == "Finishes" and p["n"] in ("PictureFrame", "Mat", "Canvas"):
            p["top"] = "FinishArt"
    structure = [p for p in parts if p["top"] in ("Structure", "Finishes", "Windows", "Doors")]
    walls = [p for p in structure if p["n"].startswith(WALLISH) and p["s"][1] > 1.0 and p["tr"] < 0.9]
    floors = [p for p in structure if p["n"].startswith(FLOORISH)]
    # loose parts (no model) in the same folder that touch each other are one object (a pile of clothes, a log stack)
    loose = [i for i, p in enumerate(parts) if p["top"] in INTERIOR and not p.get("oid")]
    parent = {i: i for i in loose}

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    byPath = collections.defaultdict(list)
    for i in loose:
        byPath[parts[i]["path"]].append(i)
    for path, ids_ in byPath.items():
        for a in range(len(ids_)):
            ba = parts[ids_[a]]["bb"]
            ga = (ba[0] - 0.05, ba[1] - 0.05, ba[2] - 0.05, ba[3] + 0.05, ba[4] + 0.05, ba[5] + 0.05)
            for b in range(a + 1, len(ids_)):
                if overlap(ga, parts[ids_[b]]["bb"]):
                    parent[find(ids_[a])] = find(ids_[b])
    objs = collections.defaultdict(list)
    for i, p in enumerate(parts):
        if p["top"] in INTERIOR:
            key = ("o", p["oid"]) if p.get("oid") else ("p", find(i))
            objs[key].append(p)
    piv = {o["oid"]: o for o in d.get("objs", []) if o.get("oid")}

    # spatial hash of every part for supports
    cell = 4.0
    grid = collections.defaultdict(list)
    for i, p in enumerate(parts):
        b = p["bb"]
        for gx in range(int(math.floor(b[0] / cell)), int(math.floor(b[3] / cell)) + 1):
            for gz in range(int(math.floor(b[2] / cell)), int(math.floor(b[5] / cell)) + 1):
                grid[(gx, gz)].append(i)

    def near(b):
        seen = set()
        for gx in range(int(math.floor(b[0] / cell)), int(math.floor(b[3] / cell)) + 1):
            for gz in range(int(math.floor(b[2] / cell)), int(math.floor(b[5] / cell)) + 1):
                for i in grid[(gx, gz)]:
                    if i not in seen:
                        seen.add(i)
                        yield i, parts[i]

    def floor_top(x, z, roomf):
        best = roomf
        for p in floors:
            b = p["bb"]
            if b[0] <= x <= b[3] and b[2] <= z <= b[5] and roomf - 0.5 <= b[4] <= roomf + 0.4:
                best = max(best, b[4])
        return best

    report = collections.defaultdict(list)
    obox = {}
    for key, ps in objs.items():
        bs = [p["bb"] for p in ps if p["tr"] < 0.95]
        if not bs:
            continue
        B = (min(b[0] for b in bs), min(b[1] for b in bs), min(b[2] for b in bs), max(b[3] for b in bs), max(b[4] for b in bs), max(b[5] for b in bs))
        obox[key] = B
        cx, cz = (B[0] + B[3]) / 2, (B[2] + B[5]) / 2
        room, rf = room_of(cx, B[1] + 0.3, cz)
        if room is None:
            continue
        label = ps[0]["path"] if key[0] == "o" else ps[0]["path"] + "/" + ps[0]["n"]
        where = "%s (%.1f, %.1f, %.1f)" % (label, cx, B[1], cz)
        ft = floor_top(cx, cz, rf)
        ids = set(id(p) for p in ps)
        # sunk
        if B[1] < ft - 0.06 and B[4] > ft and not label.endswith("/Rug"):
            report["SUNK"].append((ft - B[1], where, room))
        # floating: lowest parts must rest on something (or the object hangs on a wall)
        if B[1] > ft + 0.06:
            low = [p for p in ps if p["bb"][1] < B[1] + 0.06]
            supported = False
            for lp in low:
                lb = lp["bb"]
                for _, q in near(lb):
                    if id(q) in ids or q["tr"] >= 0.95:
                        continue
                    qb = q["bb"]
                    if lb[1] - 0.14 <= qb[4] <= lb[1] + 0.12 and qb[0] < lb[3] and lb[0] < qb[3] and qb[2] < lb[5] and lb[2] < qb[5]:
                        supported = True
                        break
                if supported:
                    break
            if not supported:
                # resting against something sideways (a magnet on the fridge, a key in its box, a coat on its hook)
                for p in ps:
                    pb = p["bb"]
                    grown = (pb[0] - 0.08, pb[1] - 0.08, pb[2] - 0.08, pb[3] + 0.08, pb[4] + 0.08, pb[5] + 0.08)
                    for _, q in near(grown):
                        if id(q) in ids or q["tr"] >= 0.95:
                            continue
                        if overlap(grown, q["bb"]):
                            supported = True
                            break
                    if supported:
                        break
            if not supported:
                # hung: touching a wall face (or up at the ceiling)
                hung = False
                pad = (B[0] - 0.07, B[1], B[2] - 0.07, B[3] + 0.07, B[4], B[5] + 0.07)
                for w in walls:
                    if overlap(pad, w["bb"]):
                        hung = True
                        break
                if B[4] > rf + 12.6:
                    hung = True
                if not hung:
                    report["FLOAT"].append((B[1] - ft, where, room))
        # into walls
        worst = 0
        for p in ps:
            b = p["bb"]
            dims = sorted([b[3] - b[0], b[4] - b[1], b[5] - b[2]])
            if dims[1] < SMALL or p["tr"] >= 0.95:
                continue
            for w in walls:
                wb = w["bb"]
                if overlap(b, wb):
                    worst = max(worst, pen(b, wb))
        if worst > 0.08:
            report["WALL"].append((worst, where, room))
        # facing
        if key[0] == "o" and key[1] in piv:
            c = piv[key[1]]["c"]
            look = (-c[5], -c[11])  # LookVector = -Z column: (-R02, -R22)
            ln = math.hypot(*look)
            if ln > 0.5:
                look = (look[0] / ln, look[1] / ln)

                def dist(dirx, dirz):
                    # distance from the object's box face to the first wall along (dirx, dirz)
                    best = 99
                    for w in walls:
                        wb = w["bb"]
                        if wb[4] < B[1] + 0.5 or wb[1] > B[4]:
                            continue
                        if abs(dirx) > 0.7:
                            if not (wb[2] < B[5] and B[2] < wb[5]):
                                continue
                            gap = (wb[0] - B[3]) if dirx > 0 else (B[0] - wb[3])
                        else:
                            if not (wb[0] < B[3] and B[0] < wb[3]):
                                continue
                            gap = (wb[2] - B[5]) if dirz > 0 else (B[2] - wb[5])
                        if gap > -0.3:
                            best = min(best, gap)
                    return best

                if abs(look[0]) > 0.85 or abs(look[1]) > 0.85:
                    ax = (round(look[0]), round(look[1]))
                    front, back = dist(*ax), dist(-ax[0], -ax[1])
                    if front < 0.8 and back > 1.5:
                        report["FACING"].append((back, where + " key " + str(piv[key[1]].get("key")), room))
    # clipping between objects (big pieces only)
    keys = [k for k in obox if k[0] == "o"]
    for i in range(len(keys)):
        a = obox[keys[i]]
        for j in range(i + 1, len(keys)):
            b = obox[keys[j]]
            if overlap(a, b, 0.0):
                # boxes overlap: check real parts
                pa = [p for p in objs[keys[i]] if p["tr"] < 0.95 and sorted([p["bb"][3] - p["bb"][0], p["bb"][4] - p["bb"][1], p["bb"][5] - p["bb"][2]])[1] > 0.3]
                pb = [p for p in objs[keys[j]] if p["tr"] < 0.95 and sorted([p["bb"][3] - p["bb"][0], p["bb"][4] - p["bb"][1], p["bb"][5] - p["bb"][2]])[1] > 0.3]
                worst = 0
                for x in pa:
                    for y in pb:
                        if overlap(x["bb"], y["bb"]):
                            worst = max(worst, pen(x["bb"], y["bb"]))
                if worst > 0.12:
                    report["CLIP"].append((worst, objs[keys[i]][0]["path"] + " x " + objs[keys[j]][0]["path"] + " at (%.1f, %.1f, %.1f)" % ((a[0] + a[3]) / 2, a[1], (a[2] + a[5]) / 2), ""))
    # wall things hung through each other (pictures, sconces, mirrors, posters: thin objects whose boxes cross)
    thin = [k for k in obox if min(obox[k][3] - obox[k][0], obox[k][5] - obox[k][2]) < 0.45 and obox[k][4] - obox[k][1] > 0.4]
    for i in range(len(thin)):
        a = obox[thin[i]]
        for j in range(i + 1, len(thin)):
            b = obox[thin[j]]
            if overlap(a, b) and pen(a, b) > 0.03:
                la = objs[thin[i]][0]["path"] + "/" + objs[thin[i]][0]["n"]
                lb = objs[thin[j]][0]["path"] + "/" + objs[thin[j]][0]["n"]
                report["HUNG"].append((pen(a, b), la + " x " + lb + " at (%.1f, %.1f, %.1f)" % ((a[0] + a[3]) / 2, (a[1] + a[4]) / 2, (a[2] + a[5]) / 2), ""))
    total = 0
    for kind in ("SUNK", "FLOAT", "WALL", "FACING", "CLIP", "HUNG"):
        rows = sorted(report[kind], reverse=True)
        total += len(rows)
        print("== %s: %d" % (kind, len(rows)))
        for amt, where, room in rows if show_all else rows[:60]:
            print("  %.2f  %s" % (amt, where))
    print("objects:", len(objs), "issues:", total)


if __name__ == "__main__":
    main()
