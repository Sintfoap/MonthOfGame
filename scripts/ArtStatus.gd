class_name ArtStatus
extends RefCounted

## Single source of truth for whether the game is still running on
## placeholder art (see assets/placeholder/ and README's "Placeholder art
## and the ship guard" section). AssetGuard.gd reads this at startup and
## refuses to run a release export while it's true.
##
## Flip this to false once every placeholder asset has been replaced with
## real art -- there's no per-asset tracking, this is deliberately a single
## switch so there's no way to half-forget one file and ship anyway.

const USING_PLACEHOLDER_ART := true
