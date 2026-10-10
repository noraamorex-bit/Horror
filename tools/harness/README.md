Extra harness checks (run with the lune harness, `env.luau` from the scratch harness):

- `audit2_test.luau`: props that float (nothing under them), prompts buried in walls or out of
  reach from the floor, and headroom along every stair ramp for a 6.1-stud player.
- `intruder_test.luau`: Curtis in Lurk mode shoves a player who walks right up to him, bolts
  when spooked, and pushes half-open doors wide instead of getting pinned behind them.
- `puzzle_test.luau`: the electrics puzzles. `Puzzle.check` takes only right answers (each wire
  to its colour; breaker taps replayed, MAIN last with everything on); the splice prompt opens the
  wires puzzle and only a right answer repairs the line; the MAIN opens the breaker puzzle and only
  solving it brings the power back; walking off closes it.
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
- `economy_test.luau`: coins. A fake DataStore another "server" writes to as well: coins and gear
  are added onto what's saved (never overwritten), a Robux pack receipt pays once, crate odds hold
  over 5000 rolls and duplicates refund, equip only what you own, the daily streak (once a day,
  resets after a gap), quests pay once, the night's loadout is handed out and used up, the night
  pays once.
- `finale_test.luau escape|bedtime|patrol`: the secret ending in the navsim world. `escape`: two
  players taken at once wake at the dinner table; a strike for struggling while he watches, one
  struggles free, gets caught off their chair and tied again, both get free; he climbs out of the
  burrow (far away, deaf to noise) while the 3 notes carry markers, a read note loses its marker,
  then he comes back down the dining-room ladder; the notes give the code, the marker moves to the
  keypad, the keypad gets the known code as a hint but never the answer and turns down a wrong
  code, the hatch takes four pushes, one climbs out to the yard; the other walks into him → Not
  Your Family. `bedtime`: nobody gets out → Forever Family. `patrol`: 120 s of patrol after he
  comes back visits the tunnel nodes without a long stall and never finds players crouched in the
  nooks.
- `client_test.luau` also feeds the finale card every phase (tied and free) and prints what it says.
