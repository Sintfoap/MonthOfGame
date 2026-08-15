# The Unweaving of Yggdrasil

A metroidvania about six schools of spellcasting, each a different finite
automaton. Design background and interactive prototypes for all six schools
live in the linked artifacts from the design conversation (Sigil Loom, then
Six Grammars) — this repo is where that design becomes an actual game.

## Status: vertical slice, 4 of 6 schools playable, first combat (both ways)

- **Godot 4.x**, GDScript, 2D.
- **Galdur** (rune-ring), **Smithcraft** (ore-vein), **Wizardry** (wandering
  mote), and **Sorcery** (spreading fire) are implemented as real gameplay,
  running the same automata as the prototypes.
- **Seiðr, Hamr** are designed (see the artifacts) but not yet built into
  the game.
- First enemy, contact damage, and a real collision-layer setup (World /
  Player / Enemy / Hazard) — see "Combat and collision layers" below.
  Wizardry damages enemies as well as switches, so the player has an actual
  offense, not just Galdur's wall.
- Player-built structures (currently just Smithcraft's crystal veins)
  persist across leaving and returning to a level — see "World state
  persistence" below.
- Art is placeholder greybox geometry — flat-colored rectangles, no sprites
  yet. Godot 4 was chosen for the 2D metroidvania toolchain; pixel art is
  the target style once an art pass starts.
- Verified by running the project headless (`godot --headless`) with
  simulated input, not just read — see "How this gets tested" below.

## Running it

Open this folder in Godot 4 (`project.godot` at the root) and press Play.
It boots into **Midgard**.

## Controls

| Action | Key |
|---|---|
| Move | Arrow keys |
| Jump | Space / Enter |
| Cast Galdur | J |
| Cast Smithcraft | K (once unlocked) |
| Cast Wizardry | L (once unlocked) |
| Cast Sorcery | M (once unlocked) |

## The vertical slice

Midgard has a 300px gap the player can't jump (max jump carries ~155px) and
can't fully bridge with a single Galdur ward either — that's deliberate,
Galdur's whole design is "free but short-ranged." A trapdoor trigger on the
starting platform drops the player into **Svartalfheim**, where touching the
altar grants Smithcraft. A trigger on the far side sends the player back up
to Midgard to grow a crystal bridge across the gap.

Once across, a patrolling enemy sits between the bridge landing and the
trigger to **Alfheim** — the first real use for Galdur's ward as a wall, not
just a stepping-stone. Alfheim's altar grants Wizardry, and its gate is
taller than the player's max jump — the only way past it is casting
Wizardry to land the mote on a switch on the far side, something no amount
of walking or jumping can do.

Past that same trigger back in Midgard, a second Wizardry-gated wall blocks
a third platform leading to **Muspelheim**. Its altar grants Sorcery, and
the way back out is blocked by a solid field of ice — not a gate, an actual
wall of frost that has to be melted. Casting Sorcery on it ignites a small
seed that spreads fire cell to cell through the whole field on its own,
clearing it permanently once it catches. There's no walking around it and,
unlike every other obstacle in the slice, no undoing it either.

## How the four implemented schools work

- **Galdur** (`scripts/abilities/Galdur.gd`) runs the elementary
  cellular-automaton ring from the prototype (Rule 30, wrapped in a circle).
  When it finishes growing, the final ring's cell density sets the size and
  lifetime of a temporary platform, spawned ahead of the caster at foot
  height (not below them — a caster standing on solid ground has nothing
  but more solid ground beneath them, so a ward placed there would spawn
  embedded in it, unreachable by anything walking at ground level). It's
  solid on the World layer, so it doubles as a wall: cast one in a
  patrolling enemy's path and it's physically blocked, same as hitting the
  edge of a platform. The ward takes about 0.4s to finish growing, so it
  can't stop a threat that's already on top of the caster — it has to be
  placed ahead of time, which is the intended reading of "free but
  short-ranged."
- **Smithcraft** (`scripts/abilities/Smithcraft.gd`) runs the same
  diffusion-limited-aggregation walk as the prototype's Ore-Vein: motes
  spawn near the cast point and drift until they touch the vein, then stick
  as permanent `CrystalCell` platforms. The vein persists between casts, so
  returning to grow it again extends the same structure rather than
  starting over — and, since the World State Persistence fix, across
  leaving and re-entering the level entirely.
- **Wizardry** (`scripts/abilities/Wizardry.gd`) runs a mobile automaton
  (turmite): the mote marks each cell it crosses, and only turns if it
  lands on a cell it's already marked. In practice, across open lattice it
  never revisits a cell in a short run, so it travels in a precise straight
  line — the "exact, controllable" wand the design calls for — while still
  being a genuine state-dependent automaton, not a raycast. Its trail is
  drawn by a separate `WizardryBeam` node anchored to the world, not the
  player, so it doesn't visually drag along if the caster moves afterward.
  `WizardrySwitch` nodes fire, and enemies in the `"enemy"` group take
  damage, when the mote's path passes within range — independent of
  physics collision, which is how it reaches switches behind gates the
  player's own body can't get through. Each enemy can only be hit once per
  cast (tracked per-cast, not a cooldown) so a slow-moving target doesn't
  eat two hits from consecutive steps of the same shot.
- **Sorcery** (`scripts/abilities/Sorcery.gd`, terrain in
  `scripts/world/IceField.gd`) is the odd one out: casting it doesn't grow
  or draw anything on the caster's end at all, it just ignites the nearest
  `IceField`. The spreading *is* the automaton, and it runs entirely inside
  the terrain object once lit, with no further input — matching the
  design's "self-propagating, no upkeep once it catches." Each ice cell has
  three states: Ice (solid), Fire (solid, transitional), Cleared (removed).
  Ice becomes Fire the moment *any* neighbor is Fire — genuine
  neighbor-driven cellular spread, one contact is enough, this school is
  meant to catch fast. Fire becomes Cleared after a fixed number of steps,
  regardless of neighbors. That second rule is deliberately *not*
  neighbor-counted the way the first one is: a field that starts entirely
  uniform (all Ice) has no Cleared cells anywhere to count against, so a
  neighbor-based rule for that transition would never fire — permanent
  deadlock, verified by hand-tracing it before it went anywhere near the
  engine. Time-based sidesteps that entirely and still reads as "it burned
  out," not like a different mechanism bolted on.

`scripts/world/LevelBuilder.gd` holds the shared greybox helpers
(`make_platform`, `make_trigger`, `make_switch`) the level scripts and
abilities all use.

## World state persistence

`scripts/WorldState.gd` (autoload) is a small in-memory record of
player-built structures, keyed by level name — currently just Smithcraft's
crystal cells. It exists because of something headless testing caught
while building Muspelheim: reaching it requires a round trip through
Alfheim first (to get Wizardry), and `change_scene_to_file` fully tears
down and frees the previous scene on every transition. Without persistence,
that meant a fully-built Smithcraft bridge in Midgard vanished the instant
the player stepped into Alfheim and came back — not a hypothetical, a
scripted test showed the crystal count go from 20 to 0 across exactly that
round trip. Since reaching Muspelheim *requires* that round trip, this
would have made the new content effectively unreachable through normal
play, not just inconvenient.

The fix: `Smithcraft.gd` records every cell it places into `WorldState`
keyed by the current level's name, and restores its own internal tracking
from it in `_ready()`. Each level's `_ready()` separately asks
`WorldState` for that level's cells and spawns them instantly (no growth
animation — the structure already exists, it's just being redrawn). This
is still in-memory only, not a save-to-disk system; it survives scene
transitions within one play session, not closing and reopening the game.
It also only covers Smithcraft right now — nothing else in the game
currently builds persistent structures the same way, but if one does
later, the same pattern applies.

## Combat and collision layers

First enemy is `scripts/world/Enemy.gd`: a ground patroller that turns
around at its patrol bounds or when it hits a wall, and deals contact
damage through a small Hazard-layer hitbox with a per-hit cooldown so it
doesn't chip the player every physics frame. It has 2 HP and dies to two
separate Wizardry hits (`take_damage()` -> `queue_free()` at 0), which is
currently the player's only way to actually kill something rather than
just block or avoid it.

Physics layers are named in `project.godot` and used explicitly everywhere
(`LevelBuilder.LAYER_WORLD/PLAYER/ENEMY/HAZARD`) rather than left on Godot's
default layer 1 for everything:

- **World** (project layer 1) — platforms, gates, crystal cells, ice
  fields, Galdur wards. Nothing monitors anything; it's just solid.
- **Player** (layer 2) — collides with World and Enemy, so an enemy's body
  physically blocks the player too, not just the reverse.
- **Enemy** (layer 3) — collides with World only. It doesn't need to react
  to the player physically; contact damage is handled separately.
- **Hazard** (layer 4) — the enemy's damage hitbox, an Area2D that watches
  for the Player layer specifically.

This also made the level triggers stricter: `make_trigger`'s Area2D now has
`collision_mask = LAYER_PLAYER` instead of the default (which was every
body on layer 1 — including the ground platform the trigger sits on top
of, the original cause of the self-firing scene-swap loop). The body-type
check added for that fix stays too, as a second line of defense. World-entry
triggers (the ones that call `change_scene_to_file`) also now guard
themselves with a local one-shot flag — added when a second Wizardry-gated
area was placed *past* the Alfheim trigger in Midgard, since without it,
walking back across that trigger to reach the new area would just pull the
player into Alfheim again every time.

## How this gets tested

There's no display in the environment these were built in, so bugs get
caught by running Godot headless (`godot --headless --path . <scene>
--quit-after N`) with a temporary autoloaded driver script that injects
real input events (`Input.parse_input_event`, `Input.action_press`) and
prints state — not just static code review, and not just "does it run,"
but scripted scenarios that walk a simulated player through the actual
sequence a real playthrough would follow. That's how the trigger
self-firing loop, the Smithcraft spawn-on-player pop, Galdur's ward never
being able to block anything, Wizardry's enemy-hit radius being too tight
to reliably land, and the crystal-bridge-vanishing-on-scene-change bug
above all got caught before being handed back — none of them were visible
from reading the code alone, only from watching state change against a
scripted scenario. The driver script itself is never committed; if you're
picking up this pattern, add it under `scripts/test/`, wire it as a
temporary autoload in `project.godot`, and remove both before committing.
For a level-geometry test that isn't one of the real scenes, add a
throwaway scene the same way and delete it afterward too.

## Known simplifications (expected — this is a first scaffold)

- One enemy type, no ranged attacks, no death animation — contact damage
  and a color flash only.
- On player death, the current scene just reloads — no death screen, no
  checkpoint beyond "start of this scene." Since Smithcraft structures now
  persist, a bridge already built survives a death-reload too.
- Respawn point on scene load is fixed, not the point you left from.
- No save/persistence to disk — `WorldState` only survives within one
  running session, and only tracks Smithcraft's crystal cells; a dead
  enemy or an already-melted ice field, for instance, is not remembered if
  you leave and come back (an enemy respawns, an ice field regenerates as
  solid ice). Only the one persistence gap that actually blocked reaching
  new content has been fixed so far, not persistence in general.
- No custom input map — movement uses Godot's built-in `ui_left` /
  `ui_right` / `ui_accept` actions; casting reads raw key events directly,
  so there's nothing to remap yet.
- Wizardry only aims horizontally (whichever way the player is facing) —
  there's no up/down aim yet.
- Contact with an enemy can shove the player a little via ordinary physics
  depenetration (the enemy doesn't avoid the player, only World-layer
  geometry) — reads as acceptable knockback for now, but it's incidental,
  not a designed knockback effect.
- Wizardry's per-cast hit is reliable against an approaching or stationary
  target but not perfectly consistent against one drifting a few pixels
  within a very small range — a real gap, not just an artifact of the
  tight test scenario that found it, but low priority since the actual
  in-game enemy patrols across a much wider range than that edge case.
- Sorcery has no way to be aimed away from the nearest IceField or scoped
  to "just this part of it" — `cast()` ignites every IceField in the
  scene. Fine while each level only ever has one, not fine the moment a
  level has two and the player only meant to light one.

## Next steps

Pick one:
1. Build a fifth school (Seiðr's voter-model consensus would be the first
   non-physical output in the game — information/curse instead of
   traversal, structure, or damage).
2. Start the pixel-art pass on the player, the four worlds, and the enemy.
3. Add a second enemy type or a ranged attack, now that there's a working
   damage pipeline (Hazard layer for enemies hitting the player, group +
   `take_damage()` for the player hitting enemies) to build more encounters
   on top of.
4. Extend `WorldState` persistence to cover more than Smithcraft — enemy
   deaths and melted ice fields are the two known gaps, and both would
   matter more as soon as a player can double back through more of the map.
