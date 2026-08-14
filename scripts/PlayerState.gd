extends Node

## Autoload singleton. Tracks which schools of magic have been unlocked
## as the player travels the Nine Worlds.

var has_smithcraft := false
var has_wizardry := false
var has_sorcery := false
var has_seidr := false
var has_hamr := false


func unlock(ability: String) -> void:
	match ability:
		"smithcraft":
			has_smithcraft = true
		"wizardry":
			has_wizardry = true
		"sorcery":
			has_sorcery = true
		"seidr":
			has_seidr = true
		"hamr":
			has_hamr = true
