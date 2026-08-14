# The Unweaving of Yggdrasil

A metroidvania about six schools of spellcasting, each a different finite
automaton. Design background and interactive prototypes for all six schools
live in the linked artifacts from the design conversation (Sigil Loom, then
Six Grammars) — this repo is where that design becomes an actual game.

## Status: vertical slice, 3 of 6 schools playable, first combat (both ways)

- **Godot 4.x**, GDScript, 2D.
- **Galdur** (rune-ring), **Smithcraft** (ore-vein), and **Wizardry**
  (wandering mote) are implemented as real gameplay, running the same
  automata as the prototypes.
- **Sorcery, Seiðr, Hamr** are designed (see the artifacts) but not yet
  built into the game.
- First enemy, contact damage, and a real collision-layer setup (World /
  Player / Enemy / Hazard) — see "Combat and collision layers" below.
  Wizardry now damages enemies as well as switches, so the player has an
  actual offense, not just Galdur's wall.
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

## The vertical slice

Midgard has a 300px gap the player can't jump (max jump carries ~155px) and
can't fully bridge with a single Galdur ward either — that's deliberate,
Galdur's whole design is "free but short-ranged." A trapdoor trigger on the
starting platform drops the player into **Svartalfheim**, where touching the
altar grants Smithcraft. A trigger on the far side sends the player back up
to Midgard to grow a crystal bridge across the gap.

Once across, a patrolling enemy sits between the bridge landing and the
trigger to **Alfheim** — the first real use for Galdur's ward as a wall, not
just a stepping-stone (see below). Alfheim's altar grants Wizardry, and its
gate is taller than the player's max jump — the only way past it is casting
Wizardry to land the mote on a switch on the far side, something no amount
of walking or jumping can do.

## How the three implemented schools work

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
  starting over.
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

`scripts/world/LevelBuilder.gd` holds the shared greybox helpers
(`make_platform`, `make_trigger`, `make_switch`) the level scripts and
abilities all use.

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

- **World** (project layer 1) — platforms, gates, crystal cells, Galdur
  wards. Nothing monitors anything; it's just solid.
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
check added for that fix stays too, as a second line of defense.

## How this gets tested

There's no display in the environment these were built in, so bugs get
caught by running Godot headless (`godot --headless --path . <scene>
--quit-after N`) with a temporary autoloaded driver script that injects
real input events (`Input.parse_input_event`, `Input.action_press`) and
prints state — not just static code review. That's how the trigger
self-firing loop, the Smithcraft spawn-on-player pop, the fact that
Galdur's ward could never actually block anything, and Wizardry's
enemy-hit radius being too tight to reliably land (the mote travels 8px
below the caster's feet, an enemy's `global_position` is at *its* feet, and
that vertical gap plus 16px grid-quantized horizontal steps pushed the
worst-case combined distance past the original 10px radius) all got caught
before being handed back — none of them were visible from reading the code
alone, only from watching numbers move against a scripted scenario. The
driver script itself is never committed; if you're picking up this
pattern, add it under `scripts/test/`, wire it as a temporary autoload in
`project.godot`, and remove both before committing. For a level-geometry
test that isn't one of the three real scenes, add a throwaway scene the
same way and delete it afterward too.

## Known simplifications (expected — this is a first scaffold)

- One enemy type, no ranged attacks, no death animation — contact damage
  and a color flash only.
- On player death, the current scene just reloads — no death screen, no
  checkpoint beyond "start of this scene."
- Respawn point on scene load is fixed, not the point you left from.
- No save/persistence system.
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

## Next steps

Pick one:
1. Build a fourth school (Sorcery's cyclic automaton would be the biggest
   visual departure so far — spreading terrain transmutation instead of a
   single ability-gate payoff).
2. Start the pixel-art pass on the player, the three worlds, and the enemy.
3. Add a second enemy type or a ranged attack, now that there's a working
   damage pipeline (Hazard layer for enemies hitting the player, group +
   `take_damage()` for the player hitting enemies) to build more encounters
   on top of.
