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
	"save_bonus",   # SaveSystem._bonus_for()
]

## Keywords that may appear as a `stat` in perk and spell data but that never
## reach a stat modifier — a resolver translates each into something above
## before applying it. Valid to author, invalid to store.
const DATA_KEYWORDS: Array[String] = [
	"movement_mode",      # buff_self / stance: applies a status instead
	"skill_bonus",        # buff_ally: becomes accuracy + spellpower
	"status_resistance",  # buff_ally: becomes save_bonus
]

## Stats a passive perk may add to `character.derived`, each annotated with what
## consumes it. Same rule as MODIFIABLE and the same reason: PerkSystem's
## affinity bonuses computed mental_resistance_pct, healing_pct and damage_pct
## for months and dropped all three on the floor, because update_derived_stats
## only folded in the keys it happened to name.
const DERIVED: Array[String] = [
	# Flat combat stats, read by the matching CombatUnit getter.
	"max_hp",
	"max_mana",
	"max_stamina",
	"initiative",
	"movement",
	"dodge",
	"accuracy",
	"damage",
	"armor",
	"armor_pierce",
	"crit_chance",
	"spellpower",
	"weight_limit",
	# Percentage stats, each read at the point the percentage applies.
	"damage_reduction_pct",    # CombatManager.apply_damage()
	"mental_resistance_pct",   # SaveSystem._bonus_for()
	"healing_pct",             # CombatUnit.heal()
	"damage_pct",              # CombatUnit.get_damage()
	"mana_cost_reduction",     # CombatManager.cast_spell()
	"mana_cost_pct",           # CombatManager.cast_spell(), from zones and auras
	"magic_resistance_pct",    # CombatManager.apply_damage(), magic types only
	"movement_pct",            # CharacterSystem.update_derived_stats()
	"summon_hp_pct",           # CombatManager._spawn_summoned_unit()
	"consumable_power_pct",    # CombatManager._apply_potion_effect()
	"repair_efficiency_pct",   # CampSystem.repair_scrap_cost()
	"effect_duration_turns",   # CombatManager._calculate_status_duration()
	"burning_damage_pct",      # CombatManager fire damage-over-time tick
	"poison_damage_pct",       # CombatManager poison damage-over-time tick
	"status_effect_chance_pct",# CombatManager.effective_status_chance()
	"stun_chance_pct",         # CombatManager._process_on_hit_perks(), mace only
	"party_social_roll_pct",   # EventManager.get_roll_bonus(), social checks
	"party_max_companions",    # CharacterSystem.get_max_party_size()
	# Out-of-combat, read by their own systems.
	"xp_gain_pct",             # CompanionSystem
	"loot_chance_pct",         # CombatManager.luck_jackpot_chance()
]


## True when a passive may add to this derived stat.
static func is_derived(stat: String) -> bool:
	return stat in DERIVED


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


## Moments CombatManager._fire_perk_triggers() is called with — the `trigger`
## an `on_trigger` passive may listen for. Same rule as every list here: a
## trigger named in data that nothing fires is a perk that never happens, and
## looks exactly like one that works until somebody counts.
##
## Each entry names who fires and what `context` carries. `target`/`attacker`/
## `ally` in the context are also what a payload's `"target"` field can point at.
const PERK_TRIGGERS: Array[String] = [
	"on_hit",         # attack_unit, attacker; context.target = the one hit
	"on_crit",        # attack_unit, attacker, after on_hit; context.target
	"on_kill",        # attack_unit, attacker, when the hit killed; context.target
	"dodge_success",  # attack_unit, defender, on any miss; context.attacker
	"parry_success",  # attack_unit, defender, on a melee miss while holding a
	                  # melee weapon (the blow met steel); context.attacker
	"take_damage",    # apply_damage, the hurt unit, damage > 0 and still
	                  # standing; context.attacker (may be absent), damage
	"ally_damaged",   # apply_damage, every living teammate of the hurt unit;
	                  # context.ally, context.attacker (may be absent), damage
	"combat_start",   # _apply_combat_start_perks, every unit, once per fight,
	                  # before round 1's turn order is sorted (so initiative
	                  # buffs count). Fires BEFORE the unit's first turn start,
	                  # which ticks stat modifiers down once — so a buff meant
	                  # to last through that first turn needs a duration of 2.
	"turn_start",     # _start_current_turn, the unit whose turn it is, after
	                  # the turn-start ticks: a duration-1 buff lasts this turn
]

## Conditions CombatUnit._perk_condition_met() answers. A `conditions` list on
## a stat_bonus, stat_conversion or on_trigger effect must use only these.
##
## `on_terrain_<ground>` is a family rather than one word: the suffix is any
## key of resources/data/terrain.json ("on_terrain_forest"), read through
## Ground, so it is checked against that file rather than listed here.
const PERK_CONDITIONS: Array[String] = [
	"wielding_sword", "wielding_axe", "wielding_mace", "wielding_spear",
	"wielding_dagger", "wielding_staff", "wielding_ranged", "unarmed",
	"not_flanked", "did_not_move", "moved_this_turn", "from_stealth",
	"below_half_hp", "above_half_hp",
	"wearing_heavy_armor",   # any worn armour piece with a Strength requirement
	"unarmored_or_light",    # CombatManager._unit_is_unarmored(unit, true)
	"first_attack_combat",   # no weapon attack made yet this fight
	"first_attack_turn",     # no weapon attack made yet this turn
	"from_behind",           # attacker stands in the target's rear arc
	"target_bleeding",       # the target has Bleeding
	"target_debuffed",       # the target carries any status typed debuff
]

## Prefix of the terrain condition family — see PERK_CONDITIONS.
const TERRAIN_CONDITION_PREFIX: String = "on_terrain_"


## True when a passive may name this condition. Terrain conditions are checked
## against Ground, so a misspelt ground ("on_terrain_forrest") is refused too.
static func is_perk_condition(condition: String) -> bool:
	if condition in PERK_CONDITIONS:
		return true
	if condition.begins_with(TERRAIN_CONDITION_PREFIX):
		return not Ground.by_key(condition.trim_prefix(TERRAIN_CONDITION_PREFIX)).is_empty()
	return false


static func is_perk_trigger(trigger: String) -> bool:
	return trigger in PERK_TRIGGERS


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


## The derived stats that come purely from attributes. This is the ONE place
## the formulas live: CharacterSystem.update_derived_stats (player) and
## EnemySystem._calculate_derived_stats (enemies) both call it, and
## ValuePaths uses it to work out what an `attribute.` hold changes.
## `attrs` maps attribute name -> value; a missing attribute counts as 10.
## Returns max_hp, max_mana, max_stamina, initiative, movement, dodge,
## spellpower and crit_chance. Equipment and perk bonuses are added by callers.
static func attribute_terms(attrs: Dictionary) -> Dictionary:
	var con = attrs.get("constitution", 10)
	var fin = attrs.get("finesse", 10)
	var foc = attrs.get("focus", 10)
	var awa = attrs.get("awareness", 10)
	var luc = attrs.get("luck", 10)
	return {
		"max_hp": 100 + (con - 10) * 10,
		"max_mana": 50 + (awa - 10) * 10,
		"max_stamina": 50 + int((con + fin - 20) * 2.5),
		"initiative": fin + awa,
		"movement": int(fin / 3),
		"dodge": fin,
		"spellpower": foc,
		"crit_chance": 5 + int((awa + fin + luc) / 6),
	}
