Extra harness checks (run with the lune harness, `env.luau` from the scratch harness):

- `audit2_test.luau`: props that float (nothing under them), prompts buried in walls or out of
  reach from the floor, and headroom along every stair ramp for a 6.1-stud player.
- `intruder_test.luau`: Curtis in Lurk mode shoves a player who walks right up to him, bolts
  when spooked, and pushes half-open doors wide instead of getting pinned behind them.
- `navsim.luau`: a wall-aware world for the harness (the built house's parts answer
  `workspace:Raycast` / `GetPartBoundsInBox`; `Humanoid:MoveTo` walks a body that collides,
  floats over the floor and gives up after 8 s; `Model:PivotTo` moves models).
- `navgrid_test.luau`: surveys the house with `NavGrid` and checks every nav node and
  hiding-spot exit is reachable; writes ASCII maps of each floor to the scratchpad.
- `navai_test.luau sweep <seed> <trips>`: random trips between rooms and hiding spots in the
  real house; none may fail or stall. `navai_test.luau brain <seed> <seconds> [trace]`: the
  Figure brain hunting three players; reports stalls, slips, climbs and time in each state.
  (The survey is cached in the scratchpad as `navgrid_cache.json`: delete it after changing
  the house.)
