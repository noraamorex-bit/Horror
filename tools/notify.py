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
import urllib.request
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pull_stats as ps  # noqa: E402  (the DataStore reader)

MESSAGE_ID = "4b35088f-90bc-7d4e-9361-d9ba1176dd42"  # Creator Hub > Engagement > Notifications


def send(user_id: int) -> str:
    body = json.dumps({
        "source": {"universe": f"universes/{ps.U}"},
        "payload": {"message_id": MESSAGE_ID, "type": "MOMENT"},
        "join_experience": {"launch_data": "notify:daily"},
        "analytics_data": {"category": "daily_reward"},
    }).encode()
    req = urllib.request.Request(
        f"https://apis.roblox.com/cloud/v2/users/{user_id}/notifications",
        data=body, method="POST",
        headers={"x-api-key": ps.KEY, "Content-Type": "application/json"},
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
    econ = ps.dump("Economy_v1")
    targets = []
    for e in econ:
        d = e.get("data") or {}
        daily = d.get("Daily") or {}
        day = int(daily.get("Day") or 0)
        try:
            uid = int(str(e["key"]).lstrip("u"))
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
