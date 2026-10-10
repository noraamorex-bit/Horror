#!/bin/bash
# full harness suite (except the slow navsim ones); prints the last line of each
cd "$(dirname "$0")"
run() { out=$(timeout 600 /root/bin/lune run "$@" 2>&1 | grep -v TextChannels | tail -1); echo "$* :: $out"; }
for t in *_test.luau; do
  case $t in navgrid_test.luau|navai_test.luau) continue;; esac
  case $t in
    revive_test.luau) for m in solo nobuy coop credit; do run $t $m; done;;
    client_test.luau|lobby_client_test.luau) run $t; run $t touch;;
    finale_test.luau) for m in escape bedtime patrol; do run $t $m; done;;
    *) run $t;;
  esac
done
