#!/usr/bin/env python3
"""Pull the game's saved data (Open Cloud, read-only) and print a retention summary.

Needs ROBLOX_API_KEY with universe-datastores read/list and ordered-data-stores read.
Usage: python3 tools/pull_stats.py [out.json] [--fresh] [--logs-only] [--since=VERSION]
  out.json      raw dump (default stats_dump.json); out.json.cache keeps fetched entries
  --fresh       re-fetch player records (night/lobby logs never change, so they stay cached)
  --logs-only   only the night and lobby logs (JourneyService), not the player records
  --since=N     only logs written by place version N or later (logs carry Ver from v74 on)

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
    late = [v for v in visits if v.get("Late")]
    tp = [v for v in visits if v.get("Tp") is not None]
    print(f"  joined a night in progress (MatchService, v78+): {len(late)} of {len(tp)} teleports")


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
              f"seen/player {sum((r[2].get('Seen') or 0) for r in group) / n:.1f}  "
              f"surprised/player {sum((r[2].get('Surprised') or 0) for r in group) / n:.2f}  "
              f"leaps over furniture/player {sum((r[2].get('Leaps') or 0) for r in group) / n:.2f}")
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
    # where quitters were, by device (act at the moment they left; dead players excluded)
    for dev in ("Phone", "Tablet", "PC", "Console"):
        g = [r for r in quit_ if (r[2].get("Perf") or {}).get("Dev") == dev and not r[2]["Out"].get("dead")]
        if g:
            print(f"  {dev:<8} quit (alive) in act: {dict(Counter(r[2]['Out'].get('act') for r in g).most_common())}")
    # captures: where, and how people got free; deaths; the heartbeat minigame
    caps = Counter(ev[2] if len(ev) > 2 else None for r in rows for ev in r[2].get("Ev") or [] if ev[1] == "Cap")
    frees = Counter(ev[2] for r in rows for ev in r[2].get("Ev") or [] if ev[1] == "Free" and len(ev) > 2)
    print(f"  captured in: {dict(caps.most_common(8))}  freed by: {dict(frees)}")
    outs = Counter(ev[2] for r in rows for ev in r[2].get("Ev") or [] if ev[1] == "Out" and len(ev) > 2)
    print(f"  out early: {dict(outs)}")
    beats = Counter(ev[2] for r in rows for ev in r[2].get("Ev") or [] if ev[1] == "Beat" and len(ev) > 2)
    print(f"  heartbeat minigame: {dict(beats)}  (Pass = survived it)")
    again = Counter(ev[1] for r in rows for ev in r[2].get("Ev") or [] if ev[1] in ("Again", "Lobby", "Revive"))
    print(f"  card buttons: {dict(again)}")
    # idle time: act II's last task -> the blackout
    idle = []
    for n in started:
        obj = {c: t for t, c in n.get("Obj") or []}
        st = [t for t, a in n.get("Acts") or [] if a == "SomeoneElse"]
        last = max([obj[k] for k in ("News", "Investigate", "LockUp") if k in obj] or [None]) if obj else None
        if st and last is not None and st[0] > last:
            idle.append(st[0] - last)
    if idle:
        print(f"  act II last task -> blackout: median {median(idle):.0f}s (n={len(idle)})")
    # outcomes by group size (solo nights used to be abandoned almost every time)
    for size in (1, 2, 3, 4):
        g = [n for n in started if n.get("Size") == size]
        if g:
            ends = Counter((n.get("End") or [None, "(no ending)"])[1] for n in g)
            print(f"  size {size}: {len(g)} nights, no ending {pct(ends['(no ending)'], len(g))}: {dict(ends.most_common())}")
    # after the ending: pressed ANOTHER NIGHT, LOBBY, or neither
    after = Counter()
    for n in started:
        if not n.get("End"):
            continue
        for p in (n.get("P") or {}).values():
            if p.get("In"):
                ev = [e[1] for e in p.get("Ev") or []]
                after["again" if "Again" in ev else "lobby" if "Lobby" in ev else "neither"] += 1
    print(f"  on the result card: {dict(after)}")
    # minutes per player in these logs (nights + lobby)
    mins = Counter()
    for n in started:
        for u, p in (n.get("P") or {}).items():
            if p.get("In"):
                end = p["Out"]["t"] if p.get("Out") else (n.get("Len") or 0)
                mins[u] += max(0, end) / 60
    if mins:
        m = sorted(mins.values())
        print(f"  minutes in nights per player: median {m[len(m) // 2]:.1f}, 30+ min: {sum(1 for x in m if x >= 30)} of {len(m)}")
    # the team's progress: how far groups get
    steps = Counter(code for n in started for _, code in n.get("Obj") or [])
    print("  objective steps reached (nights):", dict(steps.most_common(25)))
    # how help came (v78+: Okafor = the neighbour called it in because nobody else did)
    helps = Counter(next((c for _, c in n.get("Obj") or [] if c.startswith("Help:")), "none") for n in started
                    if any(a == "SomeoneElse" for _, a in n.get("Acts") or []))
    print("  help called (nights that reached the blackout):", dict(helps.most_common()))
    joined = sum(1 for n in started for p in (n.get("P") or {}).values() if any(ev[1] == "Joined" for ev in p.get("Ev") or []))
    invited = sum(1 for n in started for p in (n.get("P") or {}).values()
                  if any(ev[1] == "Joined" and len(ev) > 2 and ev[2] == "invite" for ev in p.get("Ev") or []))
    print(f"  late arrivals who joined a night in progress: {joined} (brought by a friend's invite: {invited})")
    # (v100) how he got about: wedged / step-backs / slips / failed routes, per night, and A* time
    navs = [n["Nav"] for n in started if n.get("Nav")]
    if navs:
        tot = Counter()
        for nv in navs:
            tot.update(nv)
        k = len(navs)
        print(f"  his navigation ({k} nights): per night wedged {tot['Wedged'] / k:.1f}, step-backs {tot['StepBack'] / k:.1f}, "
              f"slips {tot['Slip'] / k:.1f}, failed routes {tot['Fail'] / k:.1f}, routes {tot['Plans'] / k:.0f} "
              f"({tot['PlanMs'] / max(tot['Plans'], 1):.1f} ms each)")
    # script errors (v82+): on players' devices (Perf.Err) and on the game servers (SErr)
    cerr, cwho, serr = Counter(), Counter(), Counter()
    for n in started:
        for e in n.get("SErr") or []:
            serr[e.get("M")] += e.get("N") or 1
        for p in (n.get("P") or {}).values():
            for e in ((p.get("Perf") or {}).get("Err") or []):
                cerr[e.get("M")] += e.get("N") or 1
                cwho[e.get("M")] += 1
    if cerr or serr:
        print("  script errors on devices (count, players):")
        for m, c in cerr.most_common(10):
            print(f"    {c:5} x  {cwho[m]:3} players  {m}")
        print("  script errors on game servers:")
        for m, c in serr.most_common(10):
            print(f"    {c:5} x  {m}")


def report_sales():
    # (v92+) passes and products sold per UTC day: Sales_v1 "YYYYMMDD" -> {Key: [count, robux]}
    try:
        days = sorted(keys("Sales_v1"))
    except Exception as e:  # (no read access yet, or nothing sold)
        print(f"\n== SALES: couldn't read Sales_v1 ({e})")
        return
    if not days:
        print("\n== SALES: nothing logged yet")
        return
    print("\n== SALES (per UTC day: count x, Robux spent; from v98 also how often each was asked)")
    total = Counter()
    asks, sold = Counter(), Counter()
    for day in days:
        d = entry("Sales_v1", day)["data"] or {}
        buys = {k: v for k, v in d.items() if not k.startswith("Ask:")}
        row = ", ".join(f"{k} {v[0]}x {v[1]}R$" for k, v in sorted(buys.items(), key=lambda kv: -kv[1][1]))
        ask = ", ".join(f"{k[4:]} {v[0]}" for k, v in sorted(d.items(), key=lambda kv: -kv[1][0]) if k.startswith("Ask:"))
        print(f"  {day}: {row}" + (f"\n      asked: {ask}" if ask else ""))
        for k, v in buys.items():
            total[k] += v[1]
            if any(a.startswith("Ask:") for a in d):
                sold[k] += v[0]
        for k, v in d.items():
            if k.startswith("Ask:"):
                asks[k[4:]] += v[0]
    print(f"  total: {sum(total.values())} R$  " + ", ".join(f"{k} {v}" for k, v in total.most_common()))
    if asks:
        print("  bought / asked (days with funnel logs): " + ", ".join(f"{k} {sold[k]}/{n}" for k, n in asks.most_common()))


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
    since = next((int(a.split("=", 1)[1]) for a in flags if a.startswith("--since=")), None)
    if since is not None:
        nights = [e for e in nights if (e.get("data") or {}).get("Ver") and e["data"]["Ver"] >= since]
        lobby = [{**e, "data": [v for v in (e.get("data") or []) if (v.get("Ver") or 0) >= since]} for e in lobby]
        print(f"(only logs from version {since} on)")
    report_lobby(lobby)
    report_nights(nights)
    report_sales()
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
