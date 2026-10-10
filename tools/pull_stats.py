#!/usr/bin/env python3
"""Pull the game's saved player data (Open Cloud, read-only) and print a retention summary.

Needs ROBLOX_API_KEY with universe-datastores read/list and ordered-data-stores read.
Usage: python3 tools/pull_stats.py [out.json]   (raw dump goes to out.json, default stats_dump.json)
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
        body, _ = get(f"{BASE}/datastore/entries?" + urllib.parse.urlencode(q))
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


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "stats_dump.json"
    cache = out + ".cache"
    if os.path.exists(cache):
        CACHE.update(json.load(open(cache)))
    try:
        stats = dump("PlayerStats_v1")
        econ = dump("Economy_v1")
    finally:
        json.dump(CACHE, open(cache, "w"))
    json.dump({"stats": stats, "economy": econ}, open(out, "w"), indent=1, default=str)

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
