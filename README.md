# The Unweaving of Yggdrasil

A metroidvania about six schools of spellcasting, each a different finite
automaton. Design background and interactive prototypes for all six schools
live in the linked artifacts from the design conversation (Sigil Loom, then
Six Grammars) — this repo is where that design becomes an actual game.

## Status: vertical slice, 3 of 6 schools playable

- **Godot 4.x**, GDScript, 2D.
- **Galdur** (rune-ring), **Smithcraft** (ore-vein), and **Wizardry**
  (wandering mote) are implemented as real gameplay, running the same
  automata as the prototypes.
- **Sorcery, Seiðr, Hamr** are designed (see the artifacts) but not yet
  built into the game.
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

Once across, a second trigger on the far platform leads to **Alfheim**,
where touching its altar grants Wizardry. Alfheim also has a gate taller
than the player's max jump — the only way past it is casting Wizardry to
land the mote on a switch on the far side, something no amount of walking
or jumping can do.

## How the three implemented schools work

- **Galdur** (`scripts/abilities/Galdur.gd`) runs the elementary
  cellular-automaton ring from the prototype (Rule 30, wrapped in a circle).
  When it finishes growing, the final ring's cell density sets the size and
  lifetime of a temporary platform — a stepping-stone ward, not a weapon.
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
  `WizardrySwitch` nodes fire when the mote's path passes within range,
  independent of physics collision — which is how it reaches switches
  behind gates the player's own body can't get through.

`scripts/world/LevelBuilder.gd` holds the shared greybox helpers
(`make_platform`, `make_trigger`, `make_switch`) the level scripts and
abilities all use.

## How this gets tested

There's no display in the environment these were built in, so bugs get
caught by running Godot headless (`godot --headless --path . <scene>
--quit-after N`) with a temporary autoloaded driver script that injects
real input events (`Input.parse_input_event`, `Input.action_press`) and
prints state — not just static code review. That's how the trigger
self-firing loop and the Smithcraft spawn-on-player pop got caught before
being handed back. The driver script itself is never committed; if you're
picking up this pattern, add it under `scripts/test/`, wire it as a
temporary autoload in `project.godot`, and remove both before committing.

## Known simplifications (expected — this is a first scaffold)

- No enemies or combat yet — the slice is pure traversal/ability-gating.
- Respawn point on scene load is fixed, not the point you left from.
- No save/persistence system.
- No custom input map — movement uses Godot's built-in `ui_left` /
  `ui_right` / `ui_accept` actions; casting reads raw key events directly,
  so there's nothing to remap yet.
- Wizardry only aims horizontally (whichever way the player is facing) —
  there's no up/down aim yet.

## Next steps

Pick one:
1. Build a fourth school (Sorcery's cyclic automaton would be the biggest
   visual departure so far — spreading terrain transmutation instead of a
   single ability-gate payoff).
2. Start the pixel-art pass on the player and the three existing worlds.
3. Add the first enemy and give Galdur's ward an actual combat use.
