class_name CombatStats
## The vocabulary of stat and targeting names combat data is allowed to use.
##
## This file exists because the same three mistakes kept being made, all with
## the same shape: a key was read with `.get(name, default)` in one place and
## written with a different spelling somewhere else, and the default quietly
## covered the gap. Nothing failed, the effect just never happened.
##
##   * A buff on a stat no getter reads back is stored on the unit and summed
##     forever without ever reaching a number the player sees. `save_bonus` did
##     exactly this from the day Booster Shot was written.
##   * `targeting` is consumed by two callers that want different answers from
##     it — "which tiles may I click" and "does this resolve without a click".
##     Asking a string the wrong question gives a targeting mode with nothing
##     highlighted.
##   * A targeting mode can be subtly wrong for one skill: `single_ally`
##     filters on is_alive(), which excludes the bleeding-out ally that Revive
##     exists for.
##
## So: one list per vocabulary, `is_*` helpers instead of inline string
## comparisons, and callers that fail loudly rather than defaulting. Tools read
## these lists rather than restating them — a second copy of a vocabulary is
## how the first bug got in.


## Stats a timed modifier can target, because CombatUnit sums
## `_get_stat_modifier_bonus(stat)` back into the matching getter.
##
## Adding a name here without also adding it to a getter recreates the original
## bug. `tools/verify_active_perks.tscn` checks the pairing.
const MODIFIABLE: Array[String] = [
	"initiative",   # CombatUnit.get_initiative()
	"movement",     # CombatUnit.get_movement()
	"accuracy",     # CombatUnit.get_accuracy()
	"dodge",        # CombatUnit.get_dodge()
	"damage",       # CombatUnit.get_damage()
	"armor",        # CombatUnit.get_armor()
	"crit_chance",  # CombatUnit.get_crit_chance()
	"spellpower",   # CombatUnit.get_spellpower()
	"save_bonus",   # CombatManager._perform_save_roll()
]

## Keywords that may appear as a `stat` in perk and spell data but that never
## reach a stat modifier — a resolver translates each into something above
## before applying it. Valid to author, invalid to store.
const DATA_KEYWORDS: Array[String] = [
	"movement_mode",      # buff_self / stance: applies a status instead
	"skill_bonus",        # buff_ally: becomes accuracy + spellpower
	"status_resistance",  # buff_ally: becomes save_bonus
]

## Targeting modes CombatManager.get_active_skill_targets() can turn into tiles.
const TARGETING: Array[String] = [
	"self",         # resolves immediately on the user, no click
	"single_enemy",
	"single_ally",  # living allies only — use downed_ally to reach the fallen
	"downed_ally",  # bleeding-out or dead allies, for revive effects
	"aoe_point",    # any tile in range
	"teleport",     # walkable unoccupied tiles in range
	"dash_attack",  # enemies within dash_range + attack range
]


## True when a timed modifier on this stat will actually be read back.
static func is_modifiable(stat: String) -> bool:
	return stat in MODIFIABLE


## True when `stat` is legal to write in data, whether or not it survives to
## become a stat modifier.
static func is_authorable(stat: String) -> bool:
	return stat in MODIFIABLE or stat in DATA_KEYWORDS


static func is_targeting(mode: String) -> bool:
	return mode in TARGETING


## True when the skill needs no target tile, so the arena should resolve it on
## the spot rather than entering a targeting mode. Ask this instead of
## comparing `targeting` to "self" by hand: self-centred areas resolve
## immediately too, and they say so through their `aoe` block, not through
## their targeting mode.
static func resolves_immediately(combat_data: Dictionary) -> bool:
	return combat_data.get("targeting", "self") == "self"


## One-line explanation of why a stat name will not do what its author expects.
## Used in error messages so the fix is obvious from the log line alone.
static func explain_unknown(stat: String) -> String:
	if stat in DATA_KEYWORDS:
		return ("'%s' is a data keyword — a resolver must translate it before "
			+ "it reaches a stat modifier") % stat
	return ("'%s' is not in CombatStats.MODIFIABLE, so no getter reads it back; "
		+ "the modifier would be stored and never applied") % stat
