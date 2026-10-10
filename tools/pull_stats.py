#!/usr/bin/env python3
"""Pull the game's saved data (Open Cloud, read-only) and print a retention summary.

Needs ROBLOX_API_KEY with universe-datastores read/list and ordered-data-stores read.
Usage: python3 tools/pull_stats.py [out.json] [--fresh] [--logs-only]
  out.json      raw dump (default stats_dump.json); out.json.cache keeps fetched entries
  --fresh       re-fetch player records (night/lobby logs never change, so they stay cached)
  --logs-only   only the night and lobby logs (JourneyService), not the player records

Sections: player records (PlayerStats_v1, Economy_v1), then our own logs: every night
(NightLog_v1: acts, objectives, who left when and in what state, devices, frame rates) and every
lobby visit (LobbyLog_v1: bounced, queued, teleported).
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

U = os.environ["ROBLOX_UNIVERSE_ID"]
KEY = os.environ["ROBLOX_API_KEY"]
BASE = f"https://apis.roblox.com/datastores/v1/universes/{U}/standard-datastores"


def get(url):
    req = urllib.request.Request(url, headers={"x-api-key": KEY})
    for i in range(12):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read(), dict(r.headers)
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503):
                time.sleep(min(30, float(e.headers.get("Retry-After") or 0) or 2 * (i + 1)))
                continue
            raise
    raise RuntimeError("gave up: " + url)


def keys(store):
    out, cursor = [], ""
    while True:
        q = {"datastoreName": store, "limit": 100}
        if cursor:
            q["cursor"] = cursor
        try:
            body, _ = get(f"{BASE}/datastore/entries?" + urllib.parse.urlencode(q))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return out  # (nothing written to this store yet)
            raise
        d = json.loads(body)
        out += [k["key"] for k in d.get("keys", [])]
        cursor = d.get("nextPageCursor") or ""
        if not cursor:
            return out


def entry(store, key):
    q = urllib.parse.urlencode({"datastoreName": store, "entryKey": key})
    body, h = get(f"{BASE}/datastore/entries/entry?" + q)
    h = {k.lower(): v for k, v in h.items()}
    return {
        "key": key,
        "data": json.loads(body),
        "created": h.get("roblox-entry-created-time"),
        "updated": h.get("last-modified") or h.get("roblox-entry-version-created-time"),
    }


CACHE = {}


def dump(store):
    # (resumable: entries already fetched are kept in the cache file)
    ks = keys(store)
    have = CACHE.setdefault(store, {})
    todo = [k for k in ks if k not in have]
    with ThreadPoolExecutor(3) as ex:
        for e in ex.map(lambda k: entry(store, k), todo):
            have[e["key"]] = e
    return [have[k] for k in ks if k in have]


def ts(s):
    if not s:
        return None
    for fmt in ("%a, %d %b %Y %H:%M:%S %Z",):
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")[:26] + ("+00:00" if "+" not in s[19:] else ""))
    except ValueError:
        return None


def pct(a, b):
    return f"{100 * a / b:.0f}%" if b else "-"


def median(xs):
    xs = sorted(x for x in xs if x is not None)
    return xs[len(xs) // 2] if xs else None


ACTS = ["Evening", "SmallThings", "SomeoneElse", "Guest", "Below"]


def report_lobby(lobby):
    visits = [v for e in lobby for v in (e["data"] or [])]
    if not visits:
        print("\n== LOBBY (LobbyLog_v1): no visits logged yet")
        return
    print(f"\n== LOBBY: {len(visits)} visits ({len(lobby)} writes)")
    for label, group in (("all", visits), ("brand new", [v for v in visits if v.get("New")]),
                         ("never finished a night", [v for v in visits if not v.get("Nights")]),
                         ("veterans", [v for v in visits if (v.get("Nights") or 0) > 0])):
        n = len(group)
        if not n:
            continue
        q = [v for v in group if v.get("Queued") is not None]
        tp = [v for v in group if v.get("Tp") is not None]
        bounce = [v for v in group if v.get("Queued") is None and (v.get("Secs") or 0) < 60]
        print(f"  {label:<24} n={n:<4} queued {pct(len(q), n):>4}  teleported {pct(len(tp), n):>4}  "
              f"left <60s without queueing {pct(len(bounce), n):>4}  median s to queue {median([v['Queued'] for v in q])}  "
              f"median visit {median([v.get('Secs') for v in group])}s")
    dev = Counter((v.get("Perf") or {}).get("Dev") or "?" for v in visits)
    print("  devices:", dict(dev.most_common()))
    sizes = Counter(v.get("Q") for v in visits if v.get("Q"))
    print("  circle picked:", dict(sorted(sizes.items())))


def report_nights(nights):
    ns = [e["data"] for e in nights if e.get("data")]
    if not ns:
        print("\n== NIGHTS (NightLog_v1): none logged yet")
        return
    started = [n for n in ns if not n.get("NoStart")]
    print(f"\n== NIGHTS: {len(started)} started, {len(ns) - len(started)} servers where nobody started one")
    print("  group size:", dict(sorted(Counter(n.get("Size") for n in started).items())))
    print("  difficulty:", dict(Counter(n.get("Diff") for n in started)))
    print("  how it ended:", dict(Counter((n.get("End") or [None, "(no ending)"])[1] for n in started).most_common()))
    ends = [n["End"][0] for n in started if n.get("End")]
    print(f"  median minutes to the ending: {round(median(ends) / 60, 1) if ends else '-'}")
    act_at = {a: [] for a in ACTS}
    for n in started:
        for t, a in n.get("Acts") or []:
            if a in act_at:
                act_at[a].append(t)
    print("  acts start at (median min):", {a: round(median(v) / 60, 1) for a, v in act_at.items() if v})

    rows = []
    for n in started:
        for uid, p in (n.get("P") or {}).items():
            if not p.get("In") and p.get("Arr") is None:
                continue
            rows.append((n, uid, p))
    print(f"\n  players-in-a-night: {len(rows)}")
    for label, group in (("first night", [r for r in rows if r[2].get("New")]), ("veterans", [r for r in rows if not r[2].get("New")])):
        n = len(group)
        if not n:
            continue
        out = [r for r in group if r[2].get("Out") and not r[2]["Out"].get("after")]
        finished = [r for r in group if any(ev[1] == "Out" for ev in r[2].get("Ev") or []) or (r[0].get("End") and not (r[2].get("Out") and not r[2]["Out"].get("after")))]
        again = [r for r in group if any(ev[1] == "Again" for ev in r[2].get("Ev") or [])]
        print(f"  {label:<12} n={n:<4} saw the end of their night {pct(len(finished), n):>4}  quit mid-night {pct(len(out), n):>4}  "
              f"pressed ANOTHER NIGHT {pct(len(again), n):>4}")
        by_act = Counter(r[2]["Out"].get("act") for r in out)
        print(f"      quit in act: {dict(by_act.most_common())}")
        state = Counter(("tied up" if r[2]["Out"].get("cap") and not r[2]["Out"].get("dead") else
                         "dead" if r[2]["Out"].get("dead") else "hiding" if r[2]["Out"].get("hid") else "free") for r in out)
        print(f"      state when they quit: {dict(state.most_common())}")
        him = Counter(r[2]["Out"].get("him") for r in out)
        print(f"      his state when they quit: {dict(him.most_common())}")
        near = [r[2]["Out"].get("dist") for r in out if r[2]["Out"].get("dist") is not None]
        if near:
            print(f"      his distance when they quit: median {median(near)} studs, within 30: {pct(sum(1 for d in near if d <= 30), len(near))}")
        ts_ = [r[2]["Out"]["t"] for r in out]
        print(f"      minute they quit (median): {round(median(ts_) / 60, 1) if ts_ else '-'}")
        caps = [sum(1 for ev in r[2].get("Ev") or [] if ev[1] == "Cap") for r in group]
        print(f"      captures/player {sum(caps) / n:.2f}  hides/player {sum((r[2].get('Hides') or 0) for r in group) / n:.1f}  "
              f"seen/player {sum((r[2].get('Seen') or 0) for r in group) / n:.1f}")
        beats = Counter(ev[2] for r in group for ev in r[2].get("Ev") or [] if ev[1] == "Beat" and len(ev) > 2)
        if beats:
            print(f"      heartbeat minigames: {dict(beats)}")
    # devices and frame rates: quitters vs the rest
    def perf(rows_):
        p = [r[2].get("Perf") or {} for r in rows_]
        return (Counter(x.get("Dev") or "?" for x in p), median([x.get("FpsAvg") for x in p]), median([x.get("MemMax") for x in p]))
    quit_ = [r for r in rows if r[2].get("Out") and not r[2]["Out"].get("after")]
    rest = [r for r in rows if r not in quit_]
    for label, g in (("quit mid-night", quit_), ("everyone else", rest)):
        dev, fps, mem = perf(g)
        print(f"  {label:<15} devices {dict(dev.most_common())}  median fps {fps}  median peak memory {mem} MB")
    for dev in ("Phone", "Tablet", "PC", "Console"):
        g = [r for r in rows if (r[2].get("Perf") or {}).get("Dev") == dev]
        if g:
            q = [r for r in g if r in quit_]
            print(f"  {dev:<8} n={len(g):<4} quit mid-night {pct(len(q), len(g))}")
    # the team's progress: how far groups get
    steps = Counter(code for n in started for _, code in n.get("Obj") or [])
    print("  objective steps reached (nights):", dict(steps.most_common(25)))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    out = args[0] if args else "stats_dump.json"
    cache = out + ".cache"
    if os.path.exists(cache):
        CACHE.update(json.load(open(cache)))
    if "--fresh" in flags:
        CACHE.pop("PlayerStats_v1", None)
        CACHE.pop("Economy_v1", None)
    try:
        stats = [] if "--logs-only" in flags else dump("PlayerStats_v1")
        econ = [] if "--logs-only" in flags else dump("Economy_v1")
        nights = dump("NightLog_v1")
        lobby = dump("LobbyLog_v1")
    finally:
        json.dump(CACHE, open(cache, "w"))
    json.dump({"stats": stats, "economy": econ, "nights": nights, "lobby": lobby}, open(out, "w"), indent=1, default=str)
    report_lobby(lobby)
    report_nights(nights)
    if "--logs-only" in flags:
        return
    print("\n== PLAYER RECORDS")

    n = len(stats)
    nights = Counter(min(int(e["data"].get("Nights") or 0), 10) for e in stats)
    print(f"players with a saved record: {n}")
    print("nights played (10 = 10+):")
    for k in sorted(nights):
        print(f"  {k:>2}: {nights[k]:>4}  ({100 * nights[k] / max(n, 1):.0f}%)")
    esc = sum(1 for e in stats if (e["data"].get("Escapes") or 0) > 0)
    print(f"escaped at least once: {esc} ({100 * esc / max(n, 1):.0f}%)")
    endings = Counter(k for e in stats for k, v in (e["data"].get("Endings") or {}).items() if v)
    print("endings seen:", dict(endings.most_common()))
    # came back on another day: last write a day or more after the first
    back = 0
    for e in stats:
        a, b = ts(e["created"]), ts(e["updated"])
        if a and b and (b - a).total_seconds() > 20 * 3600:
            back += 1
    print(f"record touched again 20h+ after creation (rough returners): {back} ({100 * back / max(n, 1):.0f}%)")
    print(f"economy records: {len(econ)}")


if __name__ == "__main__":
    main()
