extends Node

## Autoload, first in the list so this runs before anything else can. Its
## only job: refuse to run a release export while placeholder art is still
## marked active in ArtStatus.gd.
##
## OS.is_debug_build() is true from the editor and from debug exports, and
## false only for a release export template build -- exactly the
## distinction between "developing/testing this" and "the thing you'd
## actually hand to a player." That's the one this gates on, so iterating
## in the editor is never blocked, only a real release build would be.
##
## This could not be verified end-to-end in the environment it was built
## in: there's no display and no export templates installed, so there was
## no way to actually produce and run a release export to confirm the
## quit() path fires for real. What WAS verified headlessly is that this
## does nothing and doesn't interfere with normal play when
## OS.is_debug_build() is true, which is every case reachable without a
## real export. Treat the release-blocking path as reviewed, not proven --
## worth one real test export before relying on it fully.


func _ready() -> void:
	if ArtStatus.USING_PLACEHOLDER_ART and not OS.is_debug_build():
		push_error(
			"Refusing to run: placeholder art is still marked active " +
			"(ArtStatus.USING_PLACEHOLDER_ART = true). Replace the assets " +
			"in assets/placeholder/ with real art, then set that constant " +
			"to false in scripts/ArtStatus.gd."
		)
		get_tree().quit(1)
