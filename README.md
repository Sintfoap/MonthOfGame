# The Unweaving of Yggdrasil

A metroidvania about six schools of spellcasting, each a different finite
automaton. Design background and interactive prototypes for all six schools
live in the linked artifacts from the design conversation (Sigil Loom, then
Six Grammars) — this repo is where that design becomes an actual game.

## Status: vertical slice, 2 of 6 schools playable

- **Godot 4.x**, GDScript, 2D.
- **Galdur** (rune-ring) and **Smithcraft** (ore-vein) are implemented as
  real gameplay, running the same automata as the prototypes.
- **Wizardry, Sorcery, Seiðr, Hamr** are designed (see the artifacts) but
  not yet built into the game.
- Art is placeholder greybox geometry — flat-colored rectangles, no sprites
  yet. Godot 4 was chosen for the 2D metroidvania toolchain; pixel art is
  the target style once an art pass starts.

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

## The vertical slice

Midgard has a 300px gap the player can't jump (max jump carries ~155px) and
can't fully bridge with a single Galdur ward either — that's deliberate,
Galdur's whole design is "free but short-ranged." A trapdoor trigger on the
starting platform drops the player into **Svartalfheim**, where touching the
altar grants Smithcraft. A trigger on the far side sends the player back up
to Midgard to grow a crystal bridge across the gap and finish the loop.

## How the two implemented schools work

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

`scripts/world/LevelBuilder.gd` holds the shared greybox helpers
(`make_platform`, `make_trigger`) both level scripts and Galdur's ward use.

## Known simplifications (expected — this is a first scaffold)

- No enemies or combat yet — the slice is pure traversal/ability-gating.
- Respawn point on scene load is fixed, not the point you left from.
- No save/persistence system.
- No custom input map — movement uses Godot's built-in `ui_left` /
  `ui_right` / `ui_accept` actions; casting reads raw key events directly,
  so there's nothing to remap yet.

## Next steps

Pick one:
1. Build a third school (Wizardry is the natural next pick — precision
   traversal/puzzle-solving pairs well with a metroidvania's locked doors).
2. Start the pixel-art pass on the player and the two existing worlds.
3. Add the first enemy and give Galdur's ward an actual combat use.
