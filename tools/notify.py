#!/usr/bin/env python3
"""Daily reminder: "Your daily reward is ready. Don't break your streak!" (Roblox experience
notification, Open Cloud). Run once a day (a Claude Code routine does it).

Who gets it: players whose last daily reward was claimed yesterday (a streak to keep) or the day
before (a streak to start again). Roblox itself only delivers to players who opted in (the
🔔 REMIND ME button on the result card), aged 13+, at most one per player per day from this game;
everyone else is answered "not opted in" and skipped.

Needs ROBLOX_API_KEY with universe-datastores read/list (Economy_v1) and user.user-notification:write.
Usage: python3 tools/notify.py [--dry-run] [--max=N]
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter

U = os.environ["ROBLOX_UNIVERSE_ID"]
KEY = os.environ["ROBLOX_API_KEY"]
DS = f"https://apis.roblox.com/datastores/v1/universes/{U}/standard-datastores"


def get(url):
    req = urllib.request.Request(url, headers={"x-api-key": KEY})
    for i in range(10):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503):
                time.sleep(2 * (i + 1))
                continue
            raise
    raise RuntimeError("gave up: " + url)


def economy():
    """Every saved Economy_v1 entry: (key, data). (Standalone: the routine may run without the repo's other tools.)"""
    keys, cursor = [], ""
    while True:
        q = {"datastoreName": "Economy_v1", "limit": 100}
        if cursor:
            q["cursor"] = cursor
        d = json.loads(get(f"{DS}/datastore/entries?" + urllib.parse.urlencode(q)))
        keys += [k["key"] for k in d.get("keys", [])]
        cursor = d.get("nextPageCursor") or ""
        if not cursor:
            break
    out = []
    for k in keys:
        q = urllib.parse.urlencode({"datastoreName": "Economy_v1", "entryKey": k})
        try:
            out.append((k, json.loads(get(f"{DS}/datastore/entries/entry?" + q))))
        except Exception as e:  # (one bad entry never stops the run)
            print("skipped", k, e)
    return out


MESSAGE_ID = "4b35088f-90bc-7d4e-9361-d9ba1176dd42"  # Creator Hub > Engagement > Notifications


def send(user_id: int) -> str:
    body = json.dumps({
        "source": {"universe": f"universes/{U}"},
        "payload": {"message_id": MESSAGE_ID, "type": "MOMENT"},
        "join_experience": {"launch_data": "notify:daily"},
        "analytics_data": {"category": "daily_reward"},
    }).encode()
    req = urllib.request.Request(
        f"https://apis.roblox.com/cloud/v2/users/{user_id}/notifications",
        data=body, method="POST",
        headers={"x-api-key": KEY, "Content-Type": "application/json"},
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return "sent" if r.status == 200 else f"http {r.status}"
        except urllib.error.HTTPError as e:
            text = e.read().decode(errors="replace")
            if e.code == 429:
                time.sleep(2 * (attempt + 1))
                continue
            if "not opted in" in text:
                return "not opted in"
            if "throttl" in text.lower() or "limit" in text.lower():
                return "throttled"
            return f"error {e.code}: {text[:120]}"
    return "rate limited"


def main():
    dry = "--dry-run" in sys.argv
    cap = next((int(a.split("=", 1)[1]) for a in sys.argv if a.startswith("--max=")), 800)
    today = int(time.time() // 86400)
    econ = economy()
    targets = []
    for key, d in econ:
        d = d if isinstance(d, dict) else {}
        daily = d.get("Daily") or {}
        day = int(daily.get("Day") or 0)
        try:
            uid = int(str(key).lstrip("u"))
        except ValueError:
            continue
        if day in (today - 1, today - 2):
            targets.append((uid, day, int(daily.get("Streak") or 0)))
    print(f"{len(econ)} players, {len(targets)} with a daily reward waiting (claimed yesterday or the day before)")
    results = Counter()
    for uid, day, streak in targets[:cap]:
        if dry:
            results["would send"] += 1
            continue
        results[send(uid)] += 1
        time.sleep(0.2)
    print("results:", dict(results))


if __name__ == "__main__":
    main()
