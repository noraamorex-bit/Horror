#!/usr/bin/env python3
"""Print what players wrote in the game's 📝 feedback box (v150, FeedbackService -> Feedback_v1).

Needs ROBLOX_API_KEY with universe-datastores read/list (the same key pull_stats.py uses).
Usage: python3 tools/pull_feedback.py [--days=N] [--json=out.json]
  --days=N     only the last N days (default: everything)
  --json=FILE  also write every entry to FILE

Each line: time (UTC), where (Lobby / Card), nights played, place version, act, then the text
(already through Roblox's filter, so personal details come out as ###).
Roblox's own feedback window (Creator Hub -> Audience -> Feedback) has no API: export its CSV
there and drop it in marketing/feedback/ to have it read too.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from datetime import datetime, timedelta, timezone

U = os.environ["ROBLOX_UNIVERSE_ID"]
KEY = os.environ["ROBLOX_API_KEY"]
BASE = f"https://apis.roblox.com/datastores/v1/universes/{U}/standard-datastores"
STORE = "Feedback_v1"


def get(url):
    req = urllib.request.Request(url, headers={"x-api-key": KEY})
    for i in range(10):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            if e.code in (429, 500, 502, 503):
                time.sleep(2 * (i + 1))
                continue
            raise
    raise RuntimeError("gave up: " + url)


def keys():
    out, cursor = [], ""
    while True:
        q = {"datastoreName": STORE, "limit": 100, "prefix": "d:"}
        if cursor:
            q["cursor"] = cursor
        body = get(f"{BASE}/datastore/entries?" + urllib.parse.urlencode(q))
        if body is None:
            return out
        d = json.loads(body)
        out += [k["key"] for k in d.get("keys", [])]
        cursor = d.get("nextPageCursor") or ""
        if not cursor:
            return out


def entries(key):
    body = get(f"{BASE}/datastore/entries/entry?" + urllib.parse.urlencode({"datastoreName": STORE, "entryKey": key}))
    data = json.loads(body) if body else []
    return data if isinstance(data, list) else []


def main():
    days = None
    out = None
    for a in sys.argv[1:]:
        if a.startswith("--days="):
            days = int(a.split("=", 1)[1])
        elif a.startswith("--json="):
            out = a.split("=", 1)[1]
    ks = sorted(keys())
    if days is not None:
        since = (datetime.now(timezone.utc) - timedelta(days=days)).strftime("d:%Y-%m-%d")
        ks = [k for k in ks if k >= since]
    allx = []
    for k in ks:
        allx += entries(k)
    allx.sort(key=lambda e: e.get("t") or 0)
    if not allx:
        print("No feedback yet (Feedback_v1 is empty).")
        return
    where = Counter(e.get("w") for e in allx)
    people = len({e.get("u") for e in allx})
    print(f"== FEEDBACK: {len(allx)} messages from {people} players ({', '.join(f'{w} {n}' for w, n in where.most_common())})")
    for e in allx:
        t = datetime.fromtimestamp(e.get("t") or 0, timezone.utc).strftime("%d %b %H:%M")
        tags = [str(e.get("w") or "?"), f"{e.get('n', 0)} nights", f"v{e.get('v', '?')}"]
        if e.get("a"):
            tags.append(str(e["a"]))
        if e.get("d"):
            tags.append("dead")
        text = " ".join(str(e.get("txt") or "").split())
        print(f"{t}  [{' · '.join(tags)}]  {text}")
    if out:
        with open(out, "w") as f:
            json.dump(allx, f, indent=1)
        print(f"(written to {out})")


if __name__ == "__main__":
    main()
