#!/usr/bin/env python3
"""Download Roblox assets (models, meshes, images) through Open Cloud's asset delivery API.

Needs ROBLOX_API_KEY with the legacy-asset:manage scope (the owner added it on 13 Oct).
Usage: python3 tools/assets/fetch.py <cacheDir> <assetId> [<assetId>...]
Writes <cacheDir>/<assetId>.bin (un-gzipped) and prints its path and first bytes. Cached: an
asset already on disk isn't fetched again.
"""
import gzip
import json
import os
import sys
import time
import urllib.request

KEY = os.environ["ROBLOX_API_KEY"]


def get(url, headers=None):
    req = urllib.request.Request(url, headers=headers or {})
    for i in range(6):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503):
                time.sleep(2 * (i + 1))
                continue
            raise
    raise RuntimeError("gave up: " + url)


def fetch(cache, asset_id):
    out = os.path.join(cache, f"{asset_id}.bin")
    if os.path.exists(out) and os.path.getsize(out) > 0:
        return out
    meta = json.loads(get(f"https://apis.roblox.com/asset-delivery-api/v1/assetId/{asset_id}", {"x-api-key": KEY}))
    loc = meta.get("location")
    if not loc:
        raise RuntimeError(f"{asset_id}: {meta}")
    data = get(loc)
    if data[:2] == b"\x1f\x8b":
        data = gzip.decompress(data)
    with open(out, "wb") as f:
        f.write(data)
    return out


def main():
    cache = sys.argv[1]
    os.makedirs(cache, exist_ok=True)
    for a in sys.argv[2:]:
        a = "".join(ch for ch in a if ch.isdigit())
        try:
            p = fetch(cache, a)
            print(p, open(p, "rb").read(14))
        except Exception as e:  # keep going: report and move on
            print(f"FAIL {a}: {e}")


if __name__ == "__main__":
    main()
