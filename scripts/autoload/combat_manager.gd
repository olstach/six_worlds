extends Node
## CombatManager - Manages tactical combat state and flow
##
## This singleton handles:
## - Combat initialization and cleanup
## - Turn order based on initiative
## - Action economy (2 actions per turn, up to 4 with buffs)
## - Win/lose condition checking
## - Damage calculation and resolution

# Signals for UI and other systems to react
signal combat_started()
signal combat_ended(victory: bool)
signal turn_started(unit: Node)
signal turn_ended(unit: Node)
signal unit_moved(unit: Node, from: Vector2i, to: Vector2i)
signal unit_attacked(attacker: Node, defender: Node, result: Dictionary)
signal unit_damaged(unit: Node, damage: int, damage_type: String)
signal unit_healed(unit: Node, amount: int)
signal unit_died(unit: Node)
signal unit_bleeding_out(unit: Node, turns_remaining: int)
signal action_used(unit: Node, actions_remaining: int)
signal spell_cast(caster: Node, spell: Dictionary, targets: Array, results: Array)
signal status_effect_triggered(unit: Node, effect_name: String, value: int, effect_type: String)
signal status_effect_expired(unit: Node, effect_name: String)
signal terrain_damage(unit: Node, damage: int, effect_name: String)
signal terrain_heal(unit: Node, amount: int, effect_name: String)
signal deployment_phase_started(can_manually_place: bool)
signal deployment_phase_ended()
signal unit_deployed(unit: Node, position: Vector2i)
signal item_used_in_combat(user: Node, item: Dictionary, result: Dictionary)
signal active_skill_used(user: Node, skill_data: Dictionary, result: Dictionary)
signal combat_log(message: String)

# Combat state
var combat_active: bool = false
var combat_grid: Node = null  # Reference to CombatGrid
var arena_scene: Node = null  # Reference to combat arena

# Units in combat
var all_units: Array[Node] = []
var turn_order: Array[Node] = []
# Lord of Death DY: units that have triggered the DY; used for resurrection-on-kill checks
var _lord_of_death_casters: Array = []
var current_unit_index: int = 0
var combat_round: int = 0  # Current round number (1 = first round); used by no_warning and similar perks

# Team constants
enum Team { PLAYER = 0, ENEMY = 1, NEUTRAL = 2 }

# Action constants
const BASE_ACTIONS: int = 2
const MAX_ACTIONS: int = 4

# Bleed-out constants
const BLEED_OUT_TURNS: int = 3

# Combat role constants (for deployment positioning)
enum CombatRole { MELEE, RANGED, CASTER }

const MELEE_SKILLS: Array[String] = ["swords", "martial_arts", "axes", "unarmed", "maces", "spears", "daggers"]
const RANGED_SKILLS: Array[String] = ["ranged"]
const CASTER_SKILLS: Array[String] = ["fire_magic", "water_magic", "earth_magic", "air_magic", "space_magic",
	"sorcery", "enchantment", "summoning", "white", "black", "ritual"]

# Tactician upgrade ID for manual deployment
const TACTICIAN_UPGRADE_ID: String = "tactician"

# Loot system constants
# Budget-based loot: enemy inventories are collected, filtered, and turned into drops.
# Items below the realm's floor value convert to gold — junk in one realm is valuable
# elsewhere, so the floor rises as the player ascends to higher realms.
# Calibrated against value_mult in equipment_tables.json:
#   hell         bone (0.35x) / obsidian (0.90x) — catches bone items (~8–17g)
#   hungry_ghost bone/obsidian/bronze (0.65x) — catches bone, passes bronze
#   animal       bronze/iron (1.00x) — catches bone/poor bronze
#   human        iron/steel (1.50x) — catches bronze, passes good iron and steel
#   demi_god     steel/damascene (2.50x) — catches iron, passes damascene (~125g+)
#   god          damascene/sky_iron (5.00x)/vajra (15x) — catches steel, passes sky_iron+
const LOOT_FLOOR_BY_REALM: Dictionary = {
	"hell":         25,
	"hungry_ghost": 35,
	"animal":       50,
	"human":        80,
	"demi_god":    150,
	"god":         300,
}
# All 8 compass directions — used by projectile deviation and bomb scatter
const DIRS_8: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

const LOOT_FLOOR_DEFAULT: int = 20  # Fallback for unknown realms
# Fraction of the above-floor loot value that actually drops as items.
# Remaining value leaks to gold at LOOT_OVERFLOW_GOLD_RATE.
const LOOT_DROP_FRACTION_MIN: float = 0.35
const LOOT_DROP_FRACTION_MAX: float = 0.65
# Below-budget overflow becomes gold at this rate (salvage value)
const LOOT_OVERFLOW_GOLD_RATE: float = 0.20
# Flat drop chance for each consumable from enemy inventory (potions, bombs, oils)
const LOOT_CONSUMABLE_DROP_CHANCE: float = 0.50
# Supplies drop alongside equipment loot — common, regenerates between fights
const SUPPLY_DROP_IDS: Array[String] = ["rations", "herb_bundle", "scrap_metal"]
const SUPPLY_DROP_CHANCE: float = 0.50
# Reagents are rarer — 25% base, 50% when casters/supports present
const REAGENT_DROP_ID: String = "raw_reagents"
const REAGENT_DROP_CHANCE: float = 0.25
const REAGENT_DROP_CHANCE_CASTER: float = 0.50
# Base rarity weights (higher = more likely to drop) — the lucky find's starting
# point, before _get_modified_rarity_weights tilts them by fight size and Luck
const RARITY_DROP_WEIGHTS: Dictionary = {
	"common": 100, "uncommon": 50, "rare": 20, "epic": 5, "legendary": 1
}
const MAX_RANDOM_DROPS: int = 5

# Spell tier display names (skill level → tier name)
const SPELL_TIER_NAMES: Dictionary = {
	1: "Outermost Circle", 3: "Outer Circle", 5: "Inner Circle",
	7: "Secret Circle", 9: "Unsurpassed Circle"
}

# School name → skill name mapping for display
const SCHOOL_TO_SKILL_NAME: Dictionary = {
	"earth": "Earth Magic", "water": "Water Magic", "fire": "Fire Magic",
	"air": "Air Magic", "space": "Space Magic", "white": "White Magic",
	"black": "Black Magic", "sorcery": "Sorcery", "enchantment": "Enchantment",
	"summoning": "Summoning"
}


## Get the tier display name for a spell (e.g. "Outer Circle of Cloud" or "Inner Circle of Fire")
static func get_spell_tier_display(spell: Dictionary) -> String:
	var level = int(spell.get("level", 1))  # Cast to int: JSON may return float, causing dict miss
	var tier_name = SPELL_TIER_NAMES.get(level, "Circle %d" % level)
	var domain = spell.get("domain", "")
	if domain != "":
		return "%s of %s" % [tier_name, domain.capitalize()]
	# Use first elemental school for the "of X" suffix
	var schools = spell.get("schools", [])
	if not schools.is_empty():
		return "%s of %s" % [tier_name, schools[0]]
	return tier_name


## Build a skill requirements string for a spell (e.g. "Requires Water Magic 3, Air Magic 3 or Sorcery 3")
static func get_spell_skill_reqs(spell: Dictionary) -> String:
	var level = spell.get("level", 1)
	var schools = spell.get("schools", [])
	var subschool = spell.get("subschool", "")
	var parts: Array[String] = []
	for school in schools:
		var skill_name = SCHOOL_TO_SKILL_NAME.get(school.to_lower(), school)
		parts.append("%s %d" % [skill_name, level])
	if subschool != "" and not subschool in schools:
		var skill_name = SCHOOL_TO_SKILL_NAME.get(subschool.to_lower(), subschool)
		parts.append("%s %d" % [skill_name, level])
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return "Requires " + parts[0]
	var last = parts.pop_back()
	return "Requires " + ", ".join(parts) + " or " + last


# Damage type → terrain effect mapping (only elements that leave ground effects)
# Physical subtypes (slashing/crushing/piercing/physical) intentionally excluded — no terrain.
const DAMAGE_TYPE_TO_TERRAIN_EFFECT: Dictionary = {
	"fire": 1,        # TerrainEffect.FIRE
	"ice": 2,         # TerrainEffect.ICE
	"poison": 3,      # TerrainEffect.POISON
	"white": 5,       # TerrainEffect.BLESSED
	"black": 6,       # TerrainEffect.CURSED
	"lightning": 8,   # TerrainEffect.STORMY
	"space": 9,       # TerrainEffect.VOID
	"solar": 1,       # TerrainEffect.FIRE (solar leaves fire)
}

# Deployment state
var _deployment_phase: bool = false
var _pending_deployment_units: Array[Node] = []
var _can_manually_deploy: bool = false

# Spell database
var _spell_database: Dictionary = {}
var _status_effects: Dictionary = {}

# Summon templates database
var _summon_templates: Dictionary = {}

# Overworld terrain this battle is taking place on (MapManager.Terrain value).
# Set by combat_arena at combat start; drives the Summoning terrain bonus below.
var battlefield_overworld_terrain: int = -1

## Zones standing on the battlefield. Each is
## {id, def, tiles: Array[Vector2i], source, turns_left, entered: Dictionary}.
## `entered` remembers who is currently standing inside, so `on_enter` fires on
## the step in and not on every round they stay.
var active_zones: Array[Dictionary] = []

## Overworld terrain → the summoning school it favours, by tradition:
## nagas in water, earth spirits in mountains, nature spirits in forest,
## hungry ghosts in ruins and charnel grounds.
## Values are MapManager.Terrain enum ints; see map_manager.gd.
# Summoning draws on the spirits native to the ground a fight is on. This was
# a table keyed on bare terrain integers with the names in comments — the same
# shape as the battlefield mapping, and the reason snow, desert and sand had no
# affinity while ice did. It lives in resources/data/terrain.json now, beside
# everything else that ground means.

## Spellpower bonus for a Summoning spell cast on ground whose spirits match
## one of its schools (see summon_terrain_affinity_for below).
const SUMMON_TERRAIN_BONUS_PCT: float = 0.25

# Combat rewards (filled before combat_ended signal, cleared on next combat start)
var last_combat_rewards: Dictionary = {}

## The summoning affinity a spell draws on, fighting on `overworld_terrain`
## (a MapManager.Terrain / Ground id), or {} when it gets none.
##
## A spell qualifies when it is a Summoning spell AND one of its schools is
## the school this ground favours — nagas answer a Water summoning on a lake,
## earth spirits an Earth summoning in the mountains. The returned dictionary
## is terrain.json's `summon_affinity` block: {school, label}.
##
## Both the cast (the spellpower calculation) and the spell tooltip in
## combat_arena.gd ask this one function, so the bonus a player is promised
## is the bonus they get.
static func summon_terrain_affinity_for(spell: Dictionary, overworld_terrain: int) -> Dictionary:
	if overworld_terrain < 0:
		return {}
	var schools_lower: Array = spell.get("schools", []).map(func(s): return str(s).to_lower())
	if not "summoning" in schools_lower:
		return {}
	var affinity: Dictionary = Ground.summon_affinity_of(overworld_terrain)
	if affinity.is_empty() or not str(affinity.get("school", "")) in schools_lower:
		return {}
	return affinity


func _ready() -> void:
	_load_spell_database()
	_load_status_definitions()
	_load_summon_templates()
	_validate_status_definitions()
	# max_hp auras are the one payload that has to be stored, so they need a
	# refresh whenever the distance between units changes.
	unit_moved.connect(_on_unit_moved_refresh_auras)
	unit_moved.connect(_on_unit_moved_check_zones)
	# Both start paths (direct and after deployment) emit combat_started once
	# every unit is in all_units — the moment to note each duellist's max HP.
	combat_started.connect(_record_duel_thresholds)
	print("CombatManager initialized with ", _spell_database.size(), " spells, ",
		_status_effects.size(), " status effects, ",
		_summon_templates.size(), " summon templates")


## Load spell definitions from JSON
func _load_spell_database() -> void:
	var file_path = "res://resources/data/spells.json"

	if not FileAccess.file_exists(file_path):
		push_warning("CombatManager: spells.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("CombatManager: Failed to parse spells.json")
		return

	var data = json.get_data()
	_spell_database = data.get("spells", {})


## Load status effect definitions from statuses.json and index by name.
## What a status blocks (acting, moving, casting, attacking) is read from its
## `flags` where it is asked: see is_unit_incapacitated(), can_unit_move() ...
func _load_status_definitions() -> void:
	var file_path = "res://resources/data/statuses.json"
	if not FileAccess.file_exists(file_path):
		push_warning("CombatManager: statuses.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("CombatManager: Failed to parse statuses.json")
		return

	var data = json.get_data()
	var statuses_array = data.get("statuses", [])

	# Index by name for O(1) lookup
	for status in statuses_array:
		var sname = status.get("name", "")
		if sname == "":
			continue

		_status_effects[sname] = status


## Check every status against EffectVocab.validate_status, loudly. Run after
## the summon templates load, since an expiry may summon one. A status that
## fails still loads (the game keeps running); the error names what to fix,
## and tools/validate_data.py fails on the same thing before it ships.
func _validate_status_definitions() -> void:
	for sname in _status_effects:
		if str(sname).begins_with("_"):
			continue
		for msg in EffectVocab.validate_status(_status_effects[sname], "status '%s'" % sname):
			push_error("CombatManager: " + msg)


## Get a status definition by name (for external use by CombatUnit, etc.)
## The whole status table. StatusOps needs it to answer "is this a debuff, and
## is it dispellable", and the overworld path needs the same answers as combat.
func get_all_status_definitions() -> Dictionary:
	return _status_effects


func get_status_definition(status_name: String) -> Dictionary:
	return _status_effects.get(status_name, {})


## True when summon_templates.json defines this template id. EffectVocab uses
## it to check `summon` effects without reaching into the private table.
func has_summon_template(template_id: String) -> bool:
	return _summon_templates.has(template_id)


## Load summon templates from summon_templates.json
func _load_summon_templates() -> void:
	var file_path = "res://resources/data/summon_templates.json"
	if not FileAccess.file_exists(file_path):
		push_warning("CombatManager: summon_templates.json not found")
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		push_error("CombatManager: Failed to parse summon_templates.json")
		return
	var data = json.get_data()
	_summon_templates = data.get("templates", {})


## Start a new combat encounter
func start_combat(grid: Node, player_units: Array, enemy_units: Array) -> void:
	if combat_active:
		push_warning("CombatManager: Combat already active")
		return

	combat_active = true
	combat_grid = grid
	all_units.clear()
	turn_order.clear()
	current_unit_index = 0
	combat_round = 1
	last_combat_rewards = {}

	# Add all units and set initial facing based on team
	for unit in player_units:
		all_units.append(unit)
		if "facing" in unit:
			unit.facing = Vector2i(1, 0)   # Players face right toward enemies
	for unit in enemy_units:
		all_units.append(unit)
		if "facing" in unit:
			unit.facing = Vector2i(-1, 0)  # Enemies face left toward players

	# Combat-start perks, round 1's turn order, the first turn.
	_begin_first_round()


## The moment a fight actually begins, shared by both ways into one —
## start_combat() and, after deployment, _finalize_combat_start().
##
## The ORDER is the point. Combat-start perks go first, then the turn order is
## built. It used to be the other way round, so Rousing Display's +Initiative
## arrived after round 1's order was already fixed and changed nothing — and
## by round 2 the buff had ticked away. Initiative only matters at the moment
## the order is sorted, so a round-1 initiative buff has to exist by then.
func _begin_first_round() -> void:
	# Apply combat-start perk effects (auras, first-round buffs)
	_apply_combat_start_perks()

	# Calculate turn order based on initiative — now including those buffs
	_calculate_turn_order()

	combat_started.emit()

	# Start first turn
	_start_current_turn()


## Apply perks that trigger once at the very start of combat.
## Both ways into a fight call this — start_combat() and, after deployment,
## _finalize_combat_start().
func _apply_combat_start_perks() -> void:
	for unit in all_units:
		_fire_perk_triggers(unit, "combat_start", {})
		var char_data = unit.character_data if "character_data" in unit else {}
		# Rousing Display (Performance 1): allies within 3 tiles gain +2 Initiative for round 1.
		# Duration 1 is right: _begin_first_round() sorts round 1 after this,
		# and the buff ticks away at the ally's first turn start — before
		# round 2's order is sorted.
		if PerkSystem.has_perk(char_data, "rousing_display"):
			for ally in get_team_units(unit.team if "team" in unit else 0):
				if ally == unit: continue
				if _grid_distance(unit.grid_position, ally.grid_position) <= 3:
					_apply_stat_modifier(ally, "initiative", 2, 1)


## DoT statuses that can persist from combat into the overworld
const OVERWORLD_DOT_STATUSES: Array = [
	"Poisoned", "Bleeding", "Burning", "Festering", "Diseased"
]

## End combat
func end_combat(victory: bool) -> void:
	if not combat_active:
		return

	# Calculate rewards BEFORE clearing units (need enemy data)
	if victory:
		last_combat_rewards = _calculate_combat_rewards()
	else:
		last_combat_rewards = {}

	# Every effect hold is combat-scoped: drop them all (and restore maxima and
	# skill bonuses) BEFORE syncing, so nothing borrowed leaks into character_data.
	for unit in all_units:
		ValuePaths.release_all_combat(unit)

	# Sync player unit state back to character_data before clearing units
	_sync_combat_state_to_characters()

	# Every combat status ends with the fight, through the one exit. Done after
	# the sync, which reads the damage-over-time statuses that carry on to the
	# map; their holds went with release_all_combat above.
	for unit in all_units:
		if "status_effects" in unit:
			for entry in unit.status_effects.duplicate():
				_end_status(unit, entry, "combat_end")

	# Persistent `damage` entries now count through update_derived_stats (the
	# fight's own holds are gone), so recompute those characters once.
	for unit in all_units:
		if unit.team == Team.PLAYER and "character_data" in unit \
				and not unit.character_data.get("damaged_values", []).is_empty():
			CharacterSystem.update_derived_stats(unit.character_data)

	# Apply post-combat emotional pressure to all player characters
	_apply_post_combat_pressure(victory)

	# Shared danger moves people toward each other, and marks the ones it marks.
	# Must run before all_units is cleared — it reads who was still standing.
	_apply_post_combat_bonds_and_traits(victory)

	combat_active = false
	_deployment_phase = false
	combat_ended.emit(victory)

	# Cleanup
	all_units.clear()
	turn_order.clear()
	combat_grid = null
	battlefield_overworld_terrain = -1
	active_zones.clear()
	_timed_obstacles.clear()
	_guarded.clear()


## Apply emotional pressure to party based on combat outcome.
func _apply_post_combat_pressure(victory: bool) -> void:
	var party = CharacterSystem.get_party()
	if victory:
		for member in party:
			PsychologySystem.apply_pressure(member, "fire", 10.0)
			PsychologySystem.apply_pressure(member, "air", 10.0)
	else:
		for member in party:
			PsychologySystem.apply_pressure(member, "earth", -10.0)
			PsychologySystem.apply_pressure(member, "space", -5.0)


## Grant Death-touched to a party member who should have died and did not.
## Called from the survive-a-fatal-blow paths; silent for enemies and summons.
func _mark_death_touched(unit: Node) -> void:
	if not TraitSystem or unit.team != Team.PLAYER:
		return
	if not "character_data" in unit or unit.character_data.is_empty():
		return
	TraitSystem.grant_trait(unit.character_data, "death_touched")


## Post-combat relationship drift and combat-history traits.
##
## Deliberately cheap: a win nudges the whole party together a little, a loss
## pushes them apart a little less, and two specific things get remembered
## permanently — killing a boss, and being the only one left standing.
func _apply_post_combat_bonds_and_traits(victory: bool) -> void:
	var party: Array = CharacterSystem.get_party()
	if party.is_empty():
		return

	if RelationshipSystem:
		# Surviving something together is the main way opinions move at all.
		RelationshipSystem.adjust_party(party, 2.0 if victory else -1.0,
				"fought together" if victory else "lost a fight together")

	if not TraitSystem or not victory:
		return

	# Bloodied — the party killed something with the boss role.
	var killed_a_boss: bool = false
	for unit in all_units:
		if unit.team != Team.ENEMY or not unit.is_dead:
			continue
		var arch_id: String = unit.character_data.get("archetype_id", "")
		if "boss" in EnemySystem.archetypes.get(arch_id, {}).get("roles", []):
			killed_a_boss = true
			break

	# Sole Survivor — everyone else went down and this one did not. Only counts
	# in a party that had someone to lose in the first place.
	var standing: Array = []
	var fell: int = 0
	for unit in all_units:
		if unit.team != Team.PLAYER or not "character_data" in unit:
			continue
		if unit.is_dead or unit.is_bleeding_out:
			fell += 1
		else:
			standing.append(unit.character_data)

	for member in party:
		if killed_a_boss:
			TraitSystem.grant_trait(member, "bloodied")
	if fell >= 2 and standing.size() == 1:
		TraitSystem.grant_trait(standing[0], "sole_survivor")


## Write current HP, mana, and persisting DoT statuses back to character_data
func _sync_combat_state_to_characters() -> void:
	for unit in all_units:
		if unit.team != Team.PLAYER:
			continue
		if not "character_data" in unit:
			continue
		var cdata = unit.character_data
		if not "derived" in cdata:
			cdata["derived"] = {}
		# HP / mana — preserve whatever the unit ended combat with
		cdata.derived["current_hp"] = unit.current_hp
		cdata.derived["current_mana"] = unit.current_mana
		# Persisting DoT statuses
		var persisting: Array = []
		for effect in unit.status_effects:
			var sname = effect.get("status", "")
			if sname in OVERWORLD_DOT_STATUSES:
				var def = _status_effects.get(sname, {})
				persisting.append({
					"status": sname,
					"duration": effect.get("duration", 1),
					"damage_per_step": StatusRules.periodic_damage_base(def, 3)
				})
		cdata["overworld_statuses"] = persisting


# ============================================
# COMBAT REWARDS
# ============================================

## Calculate XP, gold, and item rewards based on enemy difficulty vs party strength.
## Must be called while all_units is still populated.
func _calculate_combat_rewards() -> Dictionary:
	# The enemy party's XP is what it cost to build, so it is the honest measure
	# of what was just defeated. The player party earns a fraction of it, which
	# CompanionSystem then DIVIDES among its members.
	var enemy_count := 0
	var enemy_party_xp := 0
	for unit in all_units:
		if unit.team == Team.ENEMY:
			enemy_count += 1
			enemy_party_xp += int(unit.character_data.get("xp_earned", 0))

	# --- XP REWARD ---
	# A harder group pays more with no separate rule, because it cost more to
	# build. The fraction is the one tuning knob and lives in JSON.
	var fraction: float = float(EnemySystem.budgets.get("reward_fraction", 0.12))
	var xp_reward := maxi(1, int(round(float(enemy_party_xp) * fraction)))

	# --- GOLD REWARD ---
	# Gold tracks the same number rather than a second difficulty measure.
	var gold_reward := maxi(1, int(round(float(enemy_party_xp) * fraction * 0.5)))

	# Trade skill bonus: best Trade in party adds 10% per level
	var best_trade := 0
	for member in CharacterSystem.get_party():
		var trade_level: int = CharacterSystem.get_effective_skill_level(member, "trade")
		if trade_level > best_trade:
			best_trade = trade_level
	if best_trade > 0:
		gold_reward = int(gold_reward * (1.0 + best_trade * 0.1))

	# --- LUCK JACKPOT ---
	# Slim chance for a big gold bonus. Luck makes it slightly more likely
	# but the multiplier is always large - unreliable but consequential.
	# EFFECTIVE Luck (gear, traits, a shrine's blessing), best in the party.
	var best_luck := best_party_luck(CharacterSystem.get_party())

	var jackpot_triggered := false
	var jackpot_amount := 0
	var jackpot_chance := luck_jackpot_chance(best_luck, CharacterSystem.get_party())
	if randf() < jackpot_chance:
		jackpot_triggered = true
		# Jackpot: 3x to 5x the normal gold
		jackpot_amount = gold_reward * randi_range(3, 5)
		gold_reward += jackpot_amount

	# --- ITEM DROPS ---
	# Collect equipment and consumables from enemy inventories (budget-based),
	# then add supply/reagent/boss drops on top.
	var loot_result := _collect_enemy_loot()
	var item_drops: Array[String] = loot_result.get("items", [])
	gold_reward += loot_result.get("bonus_gold", 0)

	var loot_scale := clampf(float(enemy_party_xp) / 1000.0, 0.5, 3.0)
	var extra_drops: Array[String] = _generate_loot_drops(enemy_count, loot_scale, best_luck)
	for drop_id in extra_drops:
		item_drops.append(drop_id)

	var rewards := {
		"xp": xp_reward,
		"gold": gold_reward,
		"items": item_drops,
		"enemy_count": enemy_count,
		"enemy_party_xp": enemy_party_xp,
		"jackpot_triggered": jackpot_triggered,
		"jackpot_amount": jackpot_amount,
		"trade_bonus": best_trade
	}

	return rewards


## The party's best EFFECTIVE Luck — attribute plus gear, traits and Luck map
## buffs, as CharacterSystem.update_derived_stats leaves it in derived["luck"].
## Never below 10, so an unlucky party is not punished below the baseline
## (the formulas below only ever reward Luck above 10).
##
## This used to read attributes.luck directly, so a talisman "of Fortune" or a
## shrine's +Luck counted for nothing at the end of a fight.
func best_party_luck(party: Array) -> int:
	var best := 10
	for member in party:
		var attrs: Dictionary = member.get("attributes", {})
		var luck := int(member.get("derived", {}).get("luck", attrs.get("luck", 10)))
		if luck > best:
			best = luck
	return best


## The chance a won fight pays a gold jackpot, as 0.0-1.0.
##
## Base 3%, +0.5% per point of the party's best Luck above 10, capped at 10% —
## that part is Luck's own contribution. On top of it, the party's best
## `loot_chance_pct` multiplies the result: Comedy's luck_pct lands there (see
## CharacterSystem.update_derived_stats), and so does the Shivering Cairn
## shrine's +15% for one fight. Both wrote loot_chance_pct for months with
## nothing reading it.
##
## It multiplies AFTER the Luck cap on purpose. A boost swallowed by the cap
## would do nothing for exactly the luckiest party, which is the one that
## went looking for it. Best member, not sum, like every party-wide bonus.
func luck_jackpot_chance(best_luck: int, party: Array) -> float:
	var chance: float = clampf(0.03 + (best_luck - 10) * 0.005, 0.03, 0.10)
	var best_boost: float = 0.0
	for member in party:
		var boost: float = float(member.get("derived", {}).get("loot_chance_pct", 0.0))
		if boost > best_boost:
			best_boost = boost
	return chance * (1.0 + best_boost / 100.0)


## Generate supply, reagent, boss guaranteed drops, and the Luck-driven
## "lucky find".
## Role-based random equipment drops have been removed — enemies now carry real inventories
## that feed the budget-based _collect_enemy_loot() system instead.
##
## How the loot stats divide the work, so none of them is counted twice:
##   - Thievery (`loot_quality_pct`) — how much of what the ENEMIES CARRIED
##     you manage to take (the drop fraction in _collect_enemy_loot).
##   - Luck — whether fortune adds a piece nobody was carrying (the lucky
##     find, below), and how RARE that piece is (_get_modified_rarity_weights).
##   - `loot_chance_pct` (Comedy's luck_pct, the Shivering Cairn shrine) —
##     multiplies the chance of both Luck rolls, jackpot and lucky find alike,
##     because both go through luck_jackpot_chance.
func _generate_loot_drops(enemy_count: int, fight_size: float, best_luck: int) -> Array[String]:
	var drops: Array[String] = []

	# Collect enemy roles and boss archetype IDs
	var enemy_roles: Array[String] = []
	var boss_archetype_ids: Array[String] = []
	for unit in all_units:
		if unit.team != Team.ENEMY:
			continue
		var arch_id = unit.character_data.get("archetype_id", "")
		var archetype = EnemySystem.archetypes.get(arch_id, {})
		var roles = archetype.get("roles", [])
		for role in roles:
			if role == "boss":
				boss_archetype_ids.append(arch_id)
			else:
				enemy_roles.append(role)

	# --- Supply drops (rations, herbs, scrap) ---
	# 50% base chance; scale count with fight size.
	if randf() < SUPPLY_DROP_CHANCE:
		var supply_count: int = 1 + (enemy_count / 3)
		for i in range(supply_count):
			drops.append(SUPPLY_DROP_IDS[randi() % SUPPLY_DROP_IDS.size()])

	# --- Reagent drops (rarer; boosted when casters/supports were present) ---
	var has_casters := false
	for role in enemy_roles:
		if role == "caster" or role == "support":
			has_casters = true
			break
	var reagent_chance := REAGENT_DROP_CHANCE_CASTER if has_casters else REAGENT_DROP_CHANCE
	if randf() < reagent_chance:
		drops.append(REAGENT_DROP_ID)

	# --- Boss guaranteed drops ---
	for arch_id in boss_archetype_ids:
		var archetype = EnemySystem.archetypes.get(arch_id, {})
		var guaranteed = archetype.get("guaranteed_drops", [])
		for item_id in guaranteed:
			if ItemSystem.item_exists(item_id) and not item_id in drops:
				drops.append(item_id)

	# --- Lucky find ---
	# Rolled at the same odds as the gold jackpot (same Luck term, same cap,
	# same loot_chance_pct boost) but independently of it. Luck then weights
	# the rarity of what turns up — this is where "Luck: loot quality" lives.
	if randf() < luck_jackpot_chance(best_luck, CharacterSystem.get_party()):
		var found := lucky_find(fight_size, best_luck)
		if found != "":
			drops.append(found)

	return drops


## Item types a lucky find can turn up: any equipment.
func _lucky_find_types() -> Array[String]:
	var types: Array[String] = []
	types.append_array(ItemSystem.WEAPON_TYPES)
	types.append_array(ItemSystem.ARMOR_TYPES)
	types.append_array(ItemSystem.TALISMAN_TYPES)
	return types


## One piece of equipment found by luck, its rarity weighted by Luck and by
## the size of the fight. Returns an item id, or "" when nothing could be made.
func lucky_find(fight_size: float, luck: int) -> String:
	return _pick_item_from_types(_lucky_find_types(),
		_get_modified_rarity_weights(fight_size, luck))


## Collect loot from dead enemy inventories using a budget-based system.
##
## How it works (inspired by Diablo 2 treasure classes + Diablo 3 Loot 2.0):
##   - Items below LOOT_FLOOR_VALUE auto-convert to gold (no junk floods).
##   - Remaining equipment is sorted best-first by value.
##   - A randomized drop_fraction of the total value becomes the item budget.
##   - Items are taken greedily from the sorted list until the budget runs out.
##   - Over-budget items are salvaged to gold at LOOT_OVERFLOW_GOLD_RATE.
##   - Consumables (potions, bombs, oils) drop at a flat per-item chance.
##   - Thievery skill widens the drop_fraction toward the maximum.
##
## Returns {"items": Array[String], "bonus_gold": int}
func _collect_enemy_loot() -> Dictionary:
	var equipment_entries: Array = []   # {item_id: String, value: int}
	var consumable_drops: Array[String] = []
	var bonus_gold: int = 0

	# Walk every dead enemy unit's combat_inventory
	for unit in all_units:
		if unit.team != Team.ENEMY:
			continue
		for entry in unit.combat_inventory:
			var item_id: String = entry.get("item_id", "")
			if item_id == "":
				continue
			var qty: int = maxi(1, entry.get("quantity", 1))
			var item: Dictionary = ItemSystem.get_item(item_id)
			if item.is_empty():
				continue

			var item_type: String = item.get("type", "")
			var is_equipment: bool = (
				item_type in ItemSystem.WEAPON_TYPES
				or item_type in ItemSystem.ARMOR_TYPES
				or item_type in ItemSystem.TALISMAN_TYPES
			)

			if is_equipment:
				var item_value: int = item.get("value", 5)
				for _i in range(qty):
					equipment_entries.append({"item_id": item_id, "value": item_value})
			else:
				# Consumables: flat per-item drop chance
				for _i in range(qty):
					if randf() < LOOT_CONSUMABLE_DROP_CHANCE:
						consumable_drops.append(item_id)

	# Value floor — scales with realm so bone knives are junk in Hell but
	# iron swords stop dropping as items once the party reaches the human realm.
	var current_realm: String = GameState.current_world if GameState else ""
	var loot_floor: int = LOOT_FLOOR_BY_REALM.get(current_realm, LOOT_FLOOR_DEFAULT)

	var above_floor: Array = []
	for eq in equipment_entries:
		if eq.value < loot_floor:
			bonus_gold += eq.value  # Auto-coin: not worth the inventory slot here
		else:
			above_floor.append(eq)

	# Sort best items first — ensures the player always gets the most valuable pieces first
	above_floor.sort_custom(func(a, b): return a.value > b.value)

	# Drop fraction boosted by Thievery — skilled thieves know where to look.
	#
	# This was `best_thievery * 0.03` capped at 0.30, a magic number that meant
	# exactly what the Thievery table's `loot_quality_pct` says and disagreed
	# with it. The table value is read as a percentage of the HEADROOM between
	# the roll and the maximum, so a master thief gets most of the way to the
	# best case and the bound holds by construction.
	var best_quality := 0.0
	for member in CharacterSystem.get_party():
		var q: float = float(member.get("derived", {}).get("loot_quality_pct", 0.0))
		if q > best_quality:
			best_quality = q
	var rolled: float = randf_range(LOOT_DROP_FRACTION_MIN, LOOT_DROP_FRACTION_MAX)
	var headroom: float = LOOT_DROP_FRACTION_MAX - rolled
	var drop_fraction: float = clampf(
		rolled + headroom * clampf(best_quality / 100.0, 0.0, 1.0),
		LOOT_DROP_FRACTION_MIN, LOOT_DROP_FRACTION_MAX
	)

	# Budget = fraction of above-floor equipment value
	var total_value: int = 0
	for eq in above_floor:
		total_value += eq.value
	var budget: int = int(float(total_value) * drop_fraction)

	# Greedy fill: take items from best-first until budget is spent
	var result_items: Array[String] = []
	for eq in above_floor:
		if budget > 0 and eq.value <= budget:
			result_items.append(eq.item_id)
			budget -= eq.value
		else:
			# Over budget: salvage to gold at reduced rate
			bonus_gold += int(eq.value * LOOT_OVERFLOW_GOLD_RATE)

	# Append consumable drops (not subject to budget)
	for item_id in consumable_drops:
		result_items.append(item_id)

	return {"items": result_items, "bonus_gold": bonus_gold}


## Adjust rarity weights by fight size and Luck.
## A bigger fight (`fight_size`, 1.0 = a normal one; it is enemy XP / 1000,
## clamped) shifts weight toward uncommon+. Luck above 10 shifts weight toward
## rare+. Weights stay FLOATS: the old int() rounding meant legendary (base 1)
## did not move at all until Luck ~17.
func _get_modified_rarity_weights(fight_size: float, luck: int) -> Dictionary:
	var weights: Dictionary = {}
	for rarity in RARITY_DROP_WEIGHTS:
		weights[rarity] = float(RARITY_DROP_WEIGHTS[rarity])

	# Fight-size bonus: each 0.1 above 1.0 adds 10% to uncommon+ weights
	var size_bonus: float = maxf(0.0, fight_size - 1.0) * 10.0
	if size_bonus > 0.0:
		weights["uncommon"] *= 1.0 + size_bonus * 0.10
		weights["rare"] *= 1.0 + size_bonus * 0.15
		weights["epic"] *= 1.0 + size_bonus * 0.20
		weights["legendary"] *= 1.0 + size_bonus * 0.25

	# Luck bonus: each point above 10 boosts rare+ weights
	var luck_bonus: int = maxi(0, luck - 10)
	if luck_bonus > 0:
		weights["rare"] *= 1.0 + luck_bonus * 0.08
		weights["epic"] *= 1.0 + luck_bonus * 0.12
		weights["legendary"] *= 1.0 + luck_bonus * 0.15

	return weights


## Roll a rarity tier then pick a random item of that rarity from the allowed types.
## Uses procedural generation when no static items match or when the rarity roll
## favors a generated item (higher rarities are more likely to be procedural).
func _pick_item_from_types(allowed_types: Array[String], rarity_weights: Dictionary) -> String:
	# Build weighted rarity list in descending order of quality
	var rarity_order: Array[String] = ["legendary", "epic", "rare", "uncommon", "common"]
	var total_weight: float = 0.0
	for rarity in rarity_order:
		total_weight += float(rarity_weights.get(rarity, 0.0))

	if total_weight <= 0.0:
		return ""

	# Roll for rarity (a float roll, since the weights are floats)
	var roll: float = randf() * total_weight
	var rolled_rarity := "common"
	var cumulative: float = 0.0
	for rarity in rarity_order:
		cumulative += float(rarity_weights.get(rarity, 0.0))
		if roll < cumulative:
			rolled_rarity = rarity
			break

	# Check if we should generate a procedural item instead of picking static
	# Higher rarities have a higher chance of being procedural
	var proc_chance: float = ItemSystem.PROCEDURAL_CHANCE_BY_RARITY.get(rolled_rarity, 0.15)
	var generatable_types: Array[String] = []
	for item_type in allowed_types:
		if ItemSystem.can_generate_type(item_type):
			generatable_types.append(item_type)

	var current_realm = GameState.current_world if GameState else ""
	if not generatable_types.is_empty() and randf() < proc_chance:
		# Generate a procedural item of a random allowed type
		var gen_type = generatable_types[randi() % generatable_types.size()]
		var gen_id = ItemSystem.generate_item_for_type(gen_type, rolled_rarity, current_realm)
		if gen_id != "":
			return gen_id

	# Try to find a static item at the rolled rarity, fall back to lower
	var rarity_idx = rarity_order.find(rolled_rarity)
	for check_idx in range(rarity_idx, rarity_order.size()):
		var check_rarity = rarity_order[check_idx]
		var candidates: Array[String] = []

		for item_type in allowed_types:
			var items = ItemSystem.get_items_by_type(item_type)
			for item in items:
				# Skip template items — they're blueprints, not real drops
				if ItemSystem.is_template_item(item.get("id", "")):
					continue
				# Only this realm's own gear (a lucky find in hell is not
				# a damascene blade). Shops never stock fixed items from
				# the wrong realm either; they generate by realm.
				if not ItemSystem.item_fits_realm(item.get("id", ""), current_realm):
					continue
				if item.get("rarity", "") == check_rarity:
					candidates.append(item.get("id", ""))

		if not candidates.is_empty():
			return candidates[randi() % candidates.size()]

	# Last resort: if no static items matched at any rarity, try procedural generation
	if not generatable_types.is_empty():
		var gen_type = generatable_types[randi() % generatable_types.size()]
		var gen_id = ItemSystem.generate_item_for_type(gen_type, rolled_rarity, current_realm)
		if gen_id != "":
			return gen_id

	return ""


# ============================================
# DEPLOYMENT SYSTEM
# ============================================

## Start combat with automatic unit deployment based on roles
## player_characters: Array of character data dictionaries
## enemy_units: Array of enemy unit nodes (already created)
func start_combat_with_deployment(grid: Node, player_characters: Array, enemy_units: Array) -> void:
	if combat_active:
		push_warning("CombatManager: Combat already active")
		return

	combat_active = true
	combat_grid = grid
	all_units.clear()
	turn_order.clear()
	current_unit_index = 0

	# Check if any party member has Tactician upgrade for manual placement
	_can_manually_deploy = _party_has_tactician()

	# Deploy enemy units first (they use AI-controlled random placement)
	_deploy_enemy_units(enemy_units)

	if _can_manually_deploy:
		# Enter deployment phase for manual placement
		_deployment_phase = true
		_pending_deployment_units.clear()
		# Player will manually place units via deploy_unit_at()
		deployment_phase_started.emit(true)
		combat_grid.show_deployment_zones(true, false)
	else:
		# Auto-deploy player units based on roles
		_auto_deploy_player_units(player_characters)
		_finalize_combat_start()


## Auto-deploy player units based on their combat roles
func _auto_deploy_player_units(player_characters: Array) -> void:
	if combat_grid == null:
		return

	var zones = combat_grid.get_player_deployment_zones()
	var front_tiles = zones.front.duplicate()
	var back_tiles = zones.back.duplicate()

	# Sort characters by role: casters/ranged first (go to back), melee last (go to front)
	var sorted_chars = player_characters.duplicate()
	sorted_chars.sort_custom(func(a, b):
		var role_a = get_character_combat_role(a)
		var role_b = get_character_combat_role(b)
		# Casters and ranged have lower priority (placed first, in back)
		return role_a > role_b  # MELEE=0, RANGED=1, CASTER=2
	)

	for char_data in sorted_chars:
		var role = get_character_combat_role(char_data)
		var deploy_pos = Vector2i(-1, -1)

		match role:
			CombatRole.MELEE:
				# Melee goes to front, or back if front is full
				deploy_pos = _get_random_from_array(front_tiles)
				if deploy_pos == Vector2i(-1, -1):
					deploy_pos = _get_random_from_array(back_tiles)
			CombatRole.RANGED, CombatRole.CASTER:
				# Ranged/Casters go to back, or front if back is full
				deploy_pos = _get_random_from_array(back_tiles)
				if deploy_pos == Vector2i(-1, -1):
					deploy_pos = _get_random_from_array(front_tiles)

		if deploy_pos != Vector2i(-1, -1):
			var unit = _create_combat_unit(char_data, Team.PLAYER)
			combat_grid.place_unit(unit, deploy_pos)
			all_units.append(unit)
			unit_deployed.emit(unit, deploy_pos)


## Deploy enemy units (random placement in enemy zone)
func _deploy_enemy_units(enemy_units: Array) -> void:
	if combat_grid == null:
		return

	var zones = combat_grid.get_enemy_deployment_zones()
	var available_tiles = zones.all.duplicate()

	for unit in enemy_units:
		var deploy_pos = _get_random_from_array(available_tiles)
		if deploy_pos != Vector2i(-1, -1):
			combat_grid.place_unit(unit, deploy_pos)
			all_units.append(unit)
			unit_deployed.emit(unit, deploy_pos)


## Manually deploy a unit at a specific position (used during Tactician deployment phase)
func deploy_unit_manually(char_data: Dictionary, grid_pos: Vector2i) -> bool:
	if not _deployment_phase:
		push_warning("Not in deployment phase")
		return false

	if combat_grid == null:
		return false

	# Check position is in player deployment zone
	if not combat_grid.is_in_player_zone(grid_pos):
		push_warning("Position not in player deployment zone")
		return false

	# Check position is not occupied
	if combat_grid.is_occupied(grid_pos):
		push_warning("Position already occupied")
		return false

	# Create and place unit
	var unit = _create_combat_unit(char_data, Team.PLAYER)
	combat_grid.place_unit(unit, grid_pos)
	all_units.append(unit)
	unit_deployed.emit(unit, grid_pos)

	return true


## End deployment phase and start combat
func end_deployment_phase() -> void:
	if not _deployment_phase:
		return

	_deployment_phase = false
	combat_grid.clear_highlights()
	deployment_phase_ended.emit()
	_finalize_combat_start()


## Finalize combat start after deployment
func _finalize_combat_start() -> void:
	# Set initial facing based on team (deployment path)
	for unit in all_units:
		if "facing" in unit:
			unit.facing = Vector2i(1, 0) if unit.team == Team.PLAYER else Vector2i(-1, 0)

	# Combat-start perks, round 1's turn order, the first turn. This path
	# used to skip the perks, so Rousing Display did nothing in any fight that
	# had a deployment phase.
	_begin_first_round()


## Get combat role of a character based on their skills
func get_character_combat_role(char_data: Dictionary) -> int:
	var skills = char_data.get("skills", {})

	# Check for caster skills first (highest priority for back placement)
	var caster_total = 0
	for skill in CASTER_SKILLS:
		caster_total += skills.get(skill, 0)

	# Check for ranged skill
	var ranged_total = 0
	for skill in RANGED_SKILLS:
		ranged_total += skills.get(skill, 0)

	# Check for melee skills
	var melee_total = 0
	for skill in MELEE_SKILLS:
		melee_total += skills.get(skill, 0)

	# Determine primary role based on highest skill investment
	# With bias toward ranged/caster for back row placement
	if caster_total >= 3 or (caster_total > melee_total and caster_total > 0):
		return CombatRole.CASTER
	elif ranged_total >= 2 or (ranged_total > melee_total and ranged_total > 0):
		return CombatRole.RANGED
	else:
		return CombatRole.MELEE


## Check if any party member has the Tactician upgrade
func _party_has_tactician() -> bool:
	if not CharacterSystem:
		return false

	for character in CharacterSystem.get_party():
		var upgrades = character.get("upgrades", [])
		for upgrade in upgrades:
			if upgrade is Dictionary and upgrade.get("id", "") == TACTICIAN_UPGRADE_ID:
				return true
			elif upgrade is String and upgrade == TACTICIAN_UPGRADE_ID:
				return true

	return false


## Create a combat unit node from character data
func _create_combat_unit(char_data: Dictionary, team: int) -> Node:
	# For now, create a basic combat unit node
	# This will be expanded when CombatUnit scene is fully implemented
	var unit = Node2D.new()
	unit.name = char_data.get("name", "Unit")

	# Add required combat properties
	unit.set("character_data", char_data)
	unit.set("team", team)
	unit.set("grid_position", Vector2i.ZERO)
	unit.set("unit_name", char_data.get("name", "Unit"))

	# Set up HP/Mana from derived stats
	var derived = char_data.get("derived", {})
	unit.set("max_hp", derived.get("max_hp", 100))
	unit.set("current_hp", derived.get("current_hp", 100))
	unit.set("max_mana", derived.get("max_mana", 100))
	unit.set("current_mana", derived.get("current_mana", 100))
	unit.set("is_dead", false)
	unit.set("is_bleeding_out", false)
	unit.set("bleed_out_turns", 0)
	unit.set("actions_remaining", BASE_ACTIONS)

	# Add required methods as callables
	unit.set("is_alive", func(): return not unit.is_dead and not unit.is_bleeding_out)
	unit.set("get_initiative", func(): return derived.get("initiative", 10))
	unit.set("get_movement", func(): return derived.get("movement", 3))
	unit.set("get_max_actions", func(): return BASE_ACTIONS)
	unit.set("get_accuracy", func(): return derived.get("accuracy", 0))
	unit.set("get_dodge", func(): return derived.get("dodge", 10))
	unit.set("get_attack_damage", func(): return derived.get("damage", 5))
	unit.set("get_attack_range", func(): return 1)  # Default melee
	unit.set("get_armor", func(): return derived.get("armor", 0))
	unit.set("get_crit_chance", func(): return derived.get("crit_chance", 5))
	unit.set("get_spellpower", func(): return derived.get("spellpower", 10))
	unit.set("get_resistance", func(element): return 0)
	unit.set("get_magic_skill_bonus", func(element): return 0)
	unit.set("take_damage", func(amount): unit.current_hp = maxi(0, unit.current_hp - amount))
	unit.set("heal", func(amount): unit.current_hp = mini(unit.max_hp, unit.current_hp + amount))
	unit.set("is_ranged_weapon", func(): return false)  # Default melee

	# Visual representation (simple colored rect for now)
	var visual = ColorRect.new()
	visual.size = Vector2(38, 38)
	visual.position = Vector2(-19, -19)
	visual.color = Color.BLUE if team == Team.PLAYER else Color.RED
	unit.add_child(visual)

	# Add name label
	var label = Label.new()
	label.text = char_data.get("name", "?")
	label.position = Vector2(-19, 22)
	label.add_theme_font_size_override("font_size", 10)
	unit.add_child(label)

	return unit


## Helper: Get random position from array and remove it
func _get_random_from_array(arr: Array) -> Vector2i:
	if arr.is_empty():
		return Vector2i(-1, -1)
	var idx = randi() % arr.size()
	var pos = arr[idx]
	arr.remove_at(idx)
	return pos


## Helper: Get role name for debugging
func _role_name(role: int) -> String:
	match role:
		CombatRole.MELEE: return "Melee"
		CombatRole.RANGED: return "Ranged"
		CombatRole.CASTER: return "Caster"
		_: return "Unknown"


## Check if currently in deployment phase
func is_deployment_phase() -> bool:
	return _deployment_phase


## Check if manual deployment is allowed (has Tactician)
func can_manually_deploy() -> bool:
	return _can_manually_deploy


## Calculate turn order based on initiative (highest first)
##
## A unit bleeding out keeps its place: it takes no actions, but its slot is
## where its bleed-out counts down and its statuses and modifiers tick (see
## _start_current_turn). Filtering on is_alive() dropped it at the next round,
## so a downed unit never counted down and a buff on it rode on indefinitely.
func _calculate_turn_order() -> void:
	turn_order = all_units.filter(func(u): return not u.is_dead)
	turn_order.sort_custom(func(a, b): return a.get_initiative() > b.get_initiative())


## Get the current active unit
func get_current_unit() -> Node:
	if turn_order.is_empty() or current_unit_index >= turn_order.size():
		return null
	return turn_order[current_unit_index]


## Count down a unit's statuses and stat modifiers WITHOUT running anything
## else a turn start does — no damage or healing over time, no saving throws,
## no auras. For units that are skipped for actions (bleeding out, decoys):
## their time still passes. Expiry callbacks still run, since a status that
## does something when it runs out (Doomed) runs out on the downed as well.
func _tick_durations_only(unit: Node) -> void:
	if "status_effects" in unit:
		for i in range(unit.status_effects.size() - 1, -1, -1):
			if i >= unit.status_effects.size():
				continue   # an expiry above shortened the list
			var effect: Dictionary = unit.status_effects[i]
			var status_name: String = str(effect.get("status", ""))
			var effect_def: Dictionary = _status_effects.get(status_name, {})
			if str(effect_def.get("duration", {}).get("kind", "")) == "until_save":
				continue   # only a save removes these, and the downed make none
			effect["duration"] = int(effect.get("duration", 1)) - 1
			effect["turns_active"] = int(effect.get("turns_active", 0)) + 1
			if effect["duration"] > 0:
				continue
			_on_status_expired(unit, status_name, effect_def, effect)
			# The expiry callback can change the list (Doomed kills);
			# _end_status finds the entry again rather than trusting the index.
			_end_status(unit, effect, "expired")
			if unit.has_method("show_status_expired"):
				unit.show_status_expired(status_name)
			status_effect_expired.emit(unit, status_name)
	_process_stat_modifiers(unit)


## Start the current unit's turn
func _start_current_turn() -> void:
	var unit = get_current_unit()
	if unit == null:
		return

	# A trigger's `limit {per: "turn"}` lasts "until your next turn", so its
	# allowance refills here rather than on the round boundary — initiative
	# means those are not the same moment.
	if "status_effects" in unit:
		for entry in unit.status_effects:
			entry.erase("_trigger_uses")

	# Units with no actions (illusions/decoys) skip their turn automatically —
	# but their statuses and modifiers still count down here, the moment the
	# turn would have come, or a buff on them would never end.
	if unit.get_max_actions() == 0:
		_tick_durations_only(unit)
		_advance_turn()
		return

	# Process bleed-out for dying units
	if unit.is_bleeding_out:
		# Time passes for the fallen too: statuses and modifiers tick at the
		# point the turn would have come, so a buff on a downed ally does not
		# ride on into later rounds. Durations only — no DoT, healing or saves
		# on a body that is not taking turns.
		_tick_durations_only(unit)
		if unit.is_dead:
			# Something ran out that finished them (Doomed); _kill_unit has
			# already taken them out of the order.
			_advance_turn()
			return
		unit.bleed_out_turns -= 1
		unit_bleeding_out.emit(unit, unit.bleed_out_turns)

		if unit.bleed_out_turns <= 0:
			_kill_unit(unit)
			_advance_turn()
			return

		# Bleeding out units skip their turn
		_advance_turn()
		return

	# Process status effects at turn start (DoT, healing, duration tick)
	var skip_turn = _process_status_effects(unit)

	# Tick timed stat modifiers (active-skill buffs and debuffs, perk trigger
	# payloads, combat-start buffs). This is the ONE place they count down:
	# one turn of duration per turn of the unit that carries them, whether or
	# not it also carries a status, and on a stunned turn too — a stunned
	# unit's statuses tick, so its modifiers do as well.
	#
	# What a duration means, then: a modifier counts down at the START of its
	# owner's turn and is gone when it reaches 0. Duration 1 lasts until the
	# owner's next turn begins; duration 2 lasts through that next turn too.
	_process_stat_modifiers(unit)

	# Process terrain effects (standing in fire, poison, etc.)
	_process_terrain_effects(unit)

	# And any zone it starts its turn in (turn_start_inside).
	_zones_turn_trigger(unit, "turn_start_inside")

	# Check if unit died from status effect or terrain damage
	if unit.current_hp <= 0 and not unit.is_bleeding_out:
		_start_bleed_out(unit)
		_advance_turn()
		return

	# Skip turn if incapacitated (frozen, stunned, knocked down). The turn
	# still ends, so turn_end statuses tick.
	if skip_turn:
		_process_status_turn_end(unit)
		_advance_turn()
		return

	# Reset actions for this turn
	unit.actions_remaining = unit.get_max_actions()

	# Extra_Action status: grants 1 bonus action this turn, then the status is consumed
	if StatusRules.has_flag(unit, "grants_extra_action"):
		unit.actions_remaining += 1
		_remove_status_by_name(unit, "Extra_Action")
		combat_log.emit("%s surges with extra energy — gains a bonus action!" % unit.unit_name)

	# skip_next_action (Prone, Knocked_Down, …): costs 1 action to stand up at the
	# start of this turn, then every status carrying the effect is consumed.
	if StatusRules.has_flag(unit, "skip_next_action"):
		unit.actions_remaining = maxi(0, unit.actions_remaining - 1)
		var stand_up_statuses: Array = []
		for eff in StatusRules.entries_with_flag(unit, "skip_next_action"):
			stand_up_statuses.append(eff.get("status", ""))
		for sname in stand_up_statuses:
			_remove_status_by_name(unit, sname)
		combat_log.emit("%s struggles to their feet — loses 1 action." % unit.unit_name)

	# Swarmed distraction (focus_save_on_damage failed last round): −1 action
	if unit.get_meta("swarm_distracted", false):
		unit.actions_remaining = maxi(0, unit.actions_remaining - 1)
		unit.set_meta("swarm_distracted", false)
		combat_log.emit("%s swats at the swarm — loses 1 action." % unit.unit_name)

	# Dominated (controlled_by_caster): simplified — the puppet stands idle.
	# Full enemy-control AI is a dedicated feature; for now the unit loses its turn.
	if StatusRules.has_flag(unit, "controlled_by_caster"):
		combat_log.emit("%s stands slack, will bound to another." % unit.unit_name)
		_advance_turn()
		return

	# Lured (forced_movement_toward_target): compelled to step toward the lure source
	# before acting. Costs the unit 1 action.
	if StatusRules.has_flag(unit, "forced_movement_toward_target"):
		var lure_source = StatusRules.entry_with_flag(unit, "forced_movement_toward_target").get("source", null)
		if lure_source != null and is_instance_valid(lure_source) and lure_source.is_alive() and combat_grid:
			var lure_from: Vector2i = unit.grid_position
			var step: Vector2i = lure_from + _dir_toward(lure_from, lure_source.grid_position)
			if step != lure_from and combat_grid.is_tile_walkable(step) and get_unit_at(step) == null:
				combat_grid.move_unit(unit, step)
				unit_moved.emit(unit, lure_from, step)
				unit.actions_remaining = maxi(0, unit.actions_remaining - 1)
				combat_log.emit("%s is drawn helplessly toward %s!" % [unit.unit_name, lure_source.unit_name])

	# Restore stamina each turn (base 5 + Finesse/5, so characters recover ~7-12/turn)
	var finesse: int = unit_attribute(unit, "finesse")
	var stamina_regen = 5 + int(finesse / 5)
	unit.restore_stamina(stamina_regen)

	# Tick skill cooldowns
	unit.tick_cooldowns()

# Clear mantra stat bonuses every turn so aura/buff effects don't accumulate unboundedly.
	# Other units may write to this dict (e.g. Guardian Kings aura, Jeweled Pagoda summon buffs),
	# so it must be cleared for ALL units, not just active chanters.
	unit.mantra_stat_bonuses = {}

	# Tick active mantras and apply per-turn effects
	if not unit.active_mantras.is_empty():
		unit.tick_mantras()
		_process_mantra_effects_and_auras(unit)

	# Process passive perk turn-start effects
	_process_turn_start_perks(unit)
	# ...and the data-driven ones, after the per-turn counters above have reset
	# so a turn_start payload sees the turn it is starting.
	_fire_perk_triggers(unit, "turn_start", {})

	turn_started.emit(unit)


## End current unit's turn and advance to next
func end_turn() -> void:
	var unit = get_current_unit()
	if unit:
		_process_status_turn_end(unit)
		_zones_turn_trigger(unit, "turn_end_inside")
		turn_ended.emit(unit)

	_advance_turn()


## Advance to the next unit in turn order
func _advance_turn() -> void:
	current_unit_index += 1

	# Safety: clamp index if it went negative (e.g., unit died and was removed)
	if current_unit_index < 0:
		current_unit_index = 0

	# If we've gone through all units, start new round
	if current_unit_index >= turn_order.size():
		_start_new_round()
	else:
		_start_current_turn()


## Start a new round (recalculate turn order)
func _start_new_round() -> void:
	current_unit_index = 0
	combat_round += 1
	_calculate_turn_order()

	# Tick terrain effect durations
	if combat_grid:
		combat_grid.tick_terrain_effects()

	# And the zones standing on it
	_tick_zones()

	# And whatever somebody built during the fight
	_tick_placed_obstacles()

	# And whoever is standing in front of somebody else
	_tick_guards()

	# And the false images, which go when their moment passes
	_tick_decoys()

	# Check win/lose conditions
	var result = _check_combat_end()
	if result != -1:
		end_combat(result == Team.PLAYER)
		return

	if not turn_order.is_empty():
		_start_current_turn()


## Check if combat should end
## Returns: Team that won, or -1 if combat continues
func _check_combat_end() -> int:
	var player_alive = false
	var enemy_alive = false

	for unit in all_units:
		if unit.is_alive():
			if unit.team == Team.PLAYER:
				player_alive = true
			elif unit.team == Team.ENEMY:
				enemy_alive = true

	if not enemy_alive:
		return Team.PLAYER  # Player victory
	if not player_alive:
		return Team.ENEMY   # Player defeat

	# Duel stop condition — some bosses (e.g. skeleton_king_duel) have a duel_stop_hp_pct
	# field: the fight ends as a player victory when that enemy drops to or below that HP %.
	for unit in all_units:
		if unit.team != Team.ENEMY or not unit.is_alive():
			continue
		var stop_hp: int = duel_stop_hp(unit)
		if stop_hp > 0 and unit.current_hp <= stop_hp:
			combat_log.emit("%s yields — the duel is over." % unit.character_data.get("name", "Enemy"))
			return Team.PLAYER  # Duel victory

	return -1  # Combat continues


## Max HP each duelling enemy STARTED the fight with, by instance id. The
## threshold is a share of this, not of the live max_hp: a max-HP buff or
## drain mid-fight used to move the line the boss yields at.
var _duel_start_max_hp: Dictionary = {}


## Note every duellist's max HP as the fight begins (on combat_started).
func _record_duel_thresholds() -> void:
	_duel_start_max_hp.clear()
	for unit in all_units:
		if unit.team == Team.ENEMY and "character_data" in unit \
				and int(unit.character_data.get("duel_stop_hp_pct", 0)) > 0:
			_duel_start_max_hp[unit.get_instance_id()] = unit.max_hp


## The HP at or below which this enemy yields, or 0 if it does not duel.
## A unit seen for the first time (e.g. one that joined mid-fight) has its
## max HP noted now and keeps that number for the rest of the fight.
func duel_stop_hp(unit) -> int:
	if not "character_data" in unit:
		return 0
	var stop_pct: int = int(unit.character_data.get("duel_stop_hp_pct", 0))
	if stop_pct <= 0:
		return 0
	var id: int = unit.get_instance_id()
	if not _duel_start_max_hp.has(id):
		_duel_start_max_hp[id] = unit.max_hp
	# Integer maths, same rounding as before: hp*100 <= max*pct.
	return int(_duel_start_max_hp[id]) * stop_pct / 100


## Check combat end after damage/death — triggers immediately via call_deferred
## so that the current action finishes logging before the end screen appears
func _check_immediate_combat_end() -> void:
	if not combat_active:
		return
	var result = _check_combat_end()
	if result != -1:
		end_combat.call_deferred(result == Team.PLAYER)


## Use an action from the current unit
## Note: Does NOT auto-end turn. Caller must check can_act() and end_turn() as needed.
func use_action(count: int = 1) -> bool:
	var unit = get_current_unit()
	if unit == null:
		return false

	if unit.actions_remaining < count:
		return false

	unit.actions_remaining -= count
	action_used.emit(unit, unit.actions_remaining)

	return true


## Check if current unit can perform an action
func can_act(action_cost: int = 1) -> bool:
	var unit = get_current_unit()
	if unit == null:
		return false
	return unit.actions_remaining >= action_cost


## Check if it's a specific team's turn
func is_player_turn() -> bool:
	var unit = get_current_unit()
	return unit != null and unit.team == Team.PLAYER


# ============================================
# MOVEMENT
# ============================================

## Get valid movement tiles for a unit
func get_movement_range(unit: Node) -> Array[Vector2i]:
	if combat_grid == null:
		return []

	if not can_unit_move(unit):
		return []

	var movement = unit.get_movement()
	var movement_mode = unit.get_movement_mode() if unit.has_method("get_movement_mode") else CombatGrid.MovementMode.NORMAL
	var pass_through = StatusRules.has_flag(unit, "can_move_through_enemies")
	return combat_grid.get_reachable_tiles(unit.grid_position, movement, movement_mode, pass_through)


## Move a unit to a target position
func move_unit(unit: Node, target: Vector2i) -> bool:
	if combat_grid == null:
		return false

	if not can_act(1):
		return false

	# Shadow_Pinned: damage_on_move_attempt — takes damage if they try to move while pinned
	# (movement is already blocked by the cannot_move / rooted flags; this fires for AI attempts or edge cases)
	if not can_unit_move(unit):
		if StatusRules.has_flag(unit, "damage_on_move_attempt"):
			apply_damage(unit, 8, "physical")
			combat_log.emit("%s strains against the shadow pin and takes damage!" % unit.unit_name)
		return false

	var valid_tiles = get_movement_range(unit)
	if not target in valid_tiles:
		push_warning("CombatManager: Invalid move target")
		return false

	var from = unit.grid_position
	combat_grid.move_unit(unit, target)
	unit.moved_this_turn = true

	# Update facing toward movement direction
	if "facing" in unit and target != from:
		unit.facing = _dir_toward(from, target)

	use_action(1)
	unit_moved.emit(unit, from, target)

	# Slippery_Terrain: prone_chance_on_movement — 35% chance to fall prone after any move
	if StatusRules.has_flag(unit, "prone_chance_on_movement") and randf() < 0.35:
		_apply_status_effect(unit, "Knocked_Down", 1, 0, null)
		combat_log.emit("%s slips on the treacherous ground!" % unit.unit_name)

	# Zone of Control reactions: check all enemies of this unit for ZoC perks
	_check_zoc_reactions(unit, from, target)

	# Stealth detection: enemies within 5 tiles roll AWR checks per step
	if "is_stealthed" in unit and unit.is_stealthed:
		_run_stealth_detection(unit)

	return true


# ============================================
# COMBAT RESOLUTION
# ============================================

## Coordinated Strikes: after an arm kills its target, find another living enemy
## within the attacker's melee reach for the remaining arms to swing at.
func _find_chain_redirect_target(attacker: Node) -> Node:
	var reach: int = attacker.get_attack_range() if attacker.has_method("get_attack_range") else 1
	var best: Node = null
	var best_dist: int = 9999
	for unit in all_units:
		if unit == attacker or not unit.is_alive() or not unit.is_targetable():
			continue
		if "team" in unit and "team" in attacker and unit.team == attacker.team:
			continue
		var dist := _grid_distance(attacker.grid_position, unit.grid_position)
		if dist <= reach and dist < best_dist:
			best_dist = dist
			best = unit
	return best


## Chance (0–100) that arm `arm_number` fires in a multi-arm attack chain.
##
## Arm 1 is the ordinary attack and always fires. Later arms use BodySystem's
## Finesse formula, plus 20 for Akimbo. Iron Cortex makes arm 2 a certainty —
## so "arms 1 and 2 always fire" — while arms 3+ keep rolling as before.
##
## The same number also scales the wound and disease chance of that arm's hit
## (see _execute_arm_chain_attack), so a guaranteed arm hits as hard as arm 1.
func arm_chain_fire_chance(char_data: Dictionary, arm_number: int) -> float:
	if arm_number <= 1:
		return 100.0
	if arm_number == 2 and PerkSystem.has_perk(char_data, "iron_cortex"):
		return 100.0
	var finesse: int = CharacterSystem.get_effective_attribute(char_data, "finesse")
	var akimbo_bonus: float = 20.0 if PerkSystem.has_perk(char_data, "akimbo") else 0.0
	return clampf(BodySystem.get_arm_attack_chance(finesse, arm_number) + akimbo_bonus, 0.0, 100.0)


## Hardened: "50% chance to negate an incoming crit wound."
##
## Call this at the moment a crit has already rolled a wound and before
## WoundSystem applies it. Returns true when the wound is shrugged off (and logs
## it). Every crit-wound path goes through here — the main attack and each arm
## of a multi-arm chain — so the perk cannot cover one and miss the other.
## `roll` is for the verifier; leave it at -1 to roll for real.
func _crit_wound_negated(defender: Node, roll: float = -1.0) -> bool:
	var char_data: Dictionary = defender.character_data if "character_data" in defender else {}
	if not PerkSystem.has_perk(char_data, "hardened"):
		return false
	if roll < 0.0:
		roll = randf()
	if roll < 0.5:
		combat_log.emit("%s is Hardened — the blow leaves no lasting wound." % defender.unit_name)
		return true
	return false


## Apply a landed blow's damage and record what it actually cost.
##
## result["damage"] is the blow BEFORE the defender's armour, resistance,
## shields and temp HP; result["damage_taken"] is the HP the defender really
## lost — the number its red popup shows. The combat log reports the second
## (and the first beside it when they differ), so the log and the popup agree.
## Shared by the primary hit and every extra arm.
func _apply_hit_damage(attacker: Node, defender: Node, result: Dictionary) -> void:
	var tracked: bool = "damage_taken_total" in defender
	var before: int = defender.damage_taken_total if tracked else 0
	# Naming the attacker, so a take_damage passive knows who to answer. A
	# crit flags the defender first so its damage number reads "crit!" (cleared
	# straight after, so oil or enchant damage that follows shows plainly).
	# Extra arms hold their numbers back for their own "Arm N" popup anyway.
	if "next_damage_is_crit" in defender:
		defender.next_damage_is_crit = bool(result.get("crit", false))
	apply_damage(defender, result.damage, result.damage_type, attacker)
	if "next_damage_is_crit" in defender:
		defender.next_damage_is_crit = false
	result["damage_taken"] = (defender.damage_taken_total - before) if tracked else int(result.damage)


## apply_damage() for a combat-skill hit, flagging the target first so its
## floating number reads "12 crit!" like an ordinary weapon crit does.
func _apply_damage_flagging_crit(target: Node, damage: int, dmg_type: String, crit: bool) -> void:
	if "next_damage_is_crit" in target:
		target.next_damage_is_crit = crit
	apply_damage(target, damage, dmg_type)
	if "next_damage_is_crit" in target:
		target.next_damage_is_crit = false


## Weapon oil on a landed blow: bonus damage of the oil's type, and a chance
## of its status. Each blow that lands spends one of the oil's charges — so a
## four-armed swing that lands with every arm uses four.
## Shared by the primary hit and every extra arm.
func _apply_weapon_oil(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not attacker.has_method("consume_oil_charge"):
		return
	var oil = attacker.consume_oil_charge()
	if oil.is_empty():
		return
	var oil_dmg = oil.get("bonus_damage", 0)
	var oil_dmg_type = oil.get("bonus_damage_type", "fire")
	if oil_dmg > 0:
		# Resistance is applied once, inside apply_damage().
		apply_damage(defender, oil_dmg, oil_dmg_type)
		result["oil_damage"] = oil_dmg
		result["oil_damage_type"] = oil_dmg_type
	# Roll for status proc
	var oil_status = oil.get("status", "")
	var oil_chance = effective_status_chance(
		attacker.character_data if "character_data" in attacker else {},
		oil.get("status_chance", 0))
	if oil_status != "" and oil_chance > 0:
		if randf() * 100.0 <= oil_chance:
			var oil_duration = oil.get("status_duration", 2)
			# Source: the alchemist who coated the blade, so their
			# poison_damage_pct reaches the venom they mixed.
			_apply_on_hit_status(defender, oil_status, oil_duration, 0, attacker)
			result["oil_status"] = oil_status
	# Track remaining charges (unit's weapon_oil already decremented)
	var remaining = attacker.weapon_oil.get("attacks_remaining", 0) if not attacker.weapon_oil.is_empty() else 0
	result["oil_attacks_left"] = remaining


## Everything a landed weapon blow sets off once its damage is in: passive
## on-hit perks, the on_hit / on_crit / on_kill perk triggers, and the
## weapon's own procs (Trishula's on-crit status, crit wounds with Hardened's
## save, disease and poisoned-blood rolls with Undead Hunter / Diamond Body's
## immunity, the weapon's passive status procs, lifesteal, elemental damage).
##
## The primary hit and every extra arm both call this. The arm chain used to
## carry its own copy of half of it, and every fix to the main hit (Hardened,
## Undead Hunter) had to be remembered twice. One function, one place.
##
## proc_scale (0–1) scales the chance of the PERSISTENT afflictions — crit
## wounds, diseases, poisoned blood. An extra arm passes its own fire chance,
## so a glancing third-arm blow is less likely to leave a lasting wound than a
## full swing. extra_arm=true also skips the procs that belong to the whole
## attack rather than to one blow (see _process_weapon_on_hit_procs).
func _resolve_hit_procs(attacker: Node, defender: Node, result: Dictionary,
		proc_scale: float = 1.0, extra_arm: bool = false) -> void:
	_process_on_hit_perks(attacker, defender, result)
	_fire_perk_triggers(attacker, "on_hit", {"target": defender})
	if result.get("crit", false):
		_fire_perk_triggers(attacker, "on_crit", {"target": defender})
	if not defender.is_alive():
		_fire_perk_triggers(attacker, "on_kill", {"target": defender})
	_process_weapon_on_hit_procs(attacker, defender, result, proc_scale, extra_arm)


## Count one weapon swing on the attacker's per-turn and per-fight counters
## (the first_attack_turn / first_attack_combat conditions, Too Fast to
## Count's "first dagger attack each turn", the first-ranged-shot perks).
## Every swing counts, an extra arm's included, hit or miss.
func _count_weapon_attack(attacker: Node) -> void:
	if "attacks_this_turn" in attacker:
		attacker.attacks_this_turn += 1
		attacker.attacks_this_combat += 1
	if attacker.has_method("get_equipped_weapon"):
		if attacker.get_equipped_weapon().get("type", "") == "dagger":
			attacker.dagger_attacks_this_turn += 1
	if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
		attacker.ranged_attacks_this_turn += 1


## Execute one extra arm hit in the multi-arm attack chain.
##
## chain_chance (0–100) is the probability that made this arm fire. It scales
## the arm's chance of inflicting persistent wounds and diseases (arm 2 at a
## 50% fire chance gets half the primary arm's rates — a glancing brush is less
## likely to maim), via _resolve_hit_procs' proc_scale.
##
## The arm lands its blow through the same functions the primary hit uses —
## _apply_hit_damage, _apply_weapon_oil, _resolve_hit_procs and
## _count_weapon_attack — so it cannot drift from it again. What it does NOT
## do: cost an action, start a further chain, spend ammo, wear the weapon, or
## sweep (Urumi). Those belong to the attack as a whole, not to each blow.
##
## Nothing is written to the combat log here: the arena's unit_attacked
## handler logs every arm once, from the result this returns.
func _execute_arm_chain_attack(attacker: Node, defender: Node, arm_number: int, chain_chance: float) -> Dictionary:
	var weapon_dmg_type: String = "crushing"
	if attacker.has_method("get_weapon_damage_type"):
		weapon_dmg_type = attacker.get_weapon_damage_type()
	var hit_chance: float = calculate_hit_chance(attacker, defender)
	var roll: float = randf() * 100.0
	var hit: bool = roll <= hit_chance
	var result: Dictionary = {
		"arm_number": arm_number,
		"hit": hit,
		"hit_chance": hit_chance,
		"roll": roll,
		"damage": 0,
		"crit": false,
		"damage_type": weapon_dmg_type,
		# Who this arm struck. Usually the attack's defender, but Coordinated
		# Strikes can redirect the chain after a kill — the combat UI needs to
		# know whose head to put the "Arm N" popup over.
		"target": defender,
		"damage_taken": 0,
	}
	if hit:
		if "last_attacker" in defender:
			defender.last_attacker = attacker
		var damage_result := calculate_physical_damage(attacker, defender, weapon_dmg_type)
		result.merge(damage_result, true)
		# Hold back the defender's plain damage number while this arm's blow
		# lands: the arena shows it as a labelled, staggered "Arm N: X" popup
		# instead, so it doesn't stack on top of the primary hit's number.
		var holds: bool = defender.has_method("begin_held_damage")
		if holds:
			defender.begin_held_damage()
		_apply_hit_damage(attacker, defender, result)
		if holds:
			defender.end_held_damage()
		# Oil damage is held back the same way, so the arm's popup can fold it
		# in ("Arm 2: 12 +4 fire") instead of a plain number floating beside it.
		if holds:
			defender.begin_held_damage()
		_apply_weapon_oil(attacker, defender, result)
		if holds:
			result["oil_damage_taken"] = defender.end_held_damage()
		_resolve_hit_procs(attacker, defender, result, chain_chance / 100.0, true)
	_count_weapon_attack(attacker)
	return result


## Perform an attack from one unit to another.
## reaction=true: skips can_act() check and use_action() cost (for free attacks and ZoC reactions).
func attack_unit(attacker: Node, defender: Node, reaction: bool = false) -> Dictionary:
	if not reaction and not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	# Forgetful / Pacified units cannot attack
	if not can_unit_attack(attacker):
		return {"success": false, "reason": "Cannot attack in current state"}

	# Disarmed units cannot make weapon attacks (they can still cast spells)
	if StatusRules.has_flag(attacker, "cannot_make_weapon_attacks"):
		combat_log.emit("%s is disarmed and cannot make weapon attacks!" % attacker.unit_name)
		return {"success": false, "reason": "Disarmed — cannot make weapon attacks"}

	# Sanctuary: attacker under Sanctuary cannot target enemies
	if StatusRules.has_flag(attacker, "cannot_target_enemies"):
		return {"success": false, "reason": "Sanctuary — cannot target enemies"}

	# Sanctuary on defender: cannot be targeted by attacks
	if StatusRules.has_flag(defender, "cannot_be_targeted") and not StatusRules.has_flag(defender, "grants_stealth"):
		return {"success": false, "reason": "Target is protected — cannot be attacked"}

	# Somebody may be standing in front of this one. Stalwart Guardian is the
	# only thing that does it: the blow is aimed at the ward and lands on the
	# guard, which is the whole of what guarding means.
	var guard: Node = redirect_target(defender, attacker)
	if guard != null and guard != attacker:
		combat_log.emit("%s steps into the blow meant for %s."
			% [guard.unit_name, defender.unit_name])
		defender = guard

	# Charmed units cannot attack the caster who charmed them
	var charm_source = get_cc_source(attacker, "charmed")
	if charm_source == defender:
		return {"success": false, "reason": "Cannot attack — charmed by this target"}

	# Blinded units cannot use ranged attacks
	var is_ranged_check = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false
	if is_ranged_check:
		if StatusRules.has_flag(attacker, "cannot_use_ranged"):
			return {"success": false, "reason": "Cannot use ranged attacks while blinded"}
		# Storm_Lord's immune_to_ranged: ranged attacks against this defender auto-fail
		if StatusRules.has_flag(defender, "immune_to_ranged"):
			combat_log.emit("%s's storm form deflects the ranged attack!" % defender.unit_name)
			return {"success": false, "reason": "Target immune to ranged attacks"}

	# Check range (adjacent for melee, will expand for ranged later)
	var distance = _grid_distance(attacker.grid_position, defender.grid_position)
	var attack_range = attacker.get_attack_range()
	var is_ranged = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false

	# Add height range bonus for ranged attacks
	if is_ranged and combat_grid:
		attack_range += combat_grid.get_height_range_bonus(attacker.grid_position, defender.grid_position)

	if distance > attack_range:
		return {"success": false, "reason": "Target out of range"}

	# Check line of sight for ranged attacks
	if is_ranged and combat_grid:
		if not combat_grid.has_line_of_sight(attacker.grid_position, defender.grid_position):
			return {"success": false, "reason": "No line of sight"}

	# Flying defenders are out of reach of grounded melee attackers
	if not is_ranged and StatusRules.has_flag(defender, "immune_to_melee_unless_flyer"):
		var attacker_mode = attacker.get_movement_mode() if attacker.has_method("get_movement_mode") else CombatGrid.MovementMode.NORMAL
		if attacker_mode != CombatGrid.MovementMode.FLYING:
			combat_log.emit("%s is airborne — melee attacks cannot reach!" % defender.unit_name)
			return {"success": false, "reason": "Target is flying — melee cannot reach"}

	# Update attacker facing toward defender
	if "facing" in attacker:
		attacker.facing = _dir_toward(attacker.grid_position, defender.grid_position)

	# Sanctuary breaks when attacker takes any offensive action
	if StatusRules.has_flag(attacker, "breaks_on_offensive_action"):
		_remove_status_by_name(attacker, "Sanctuary")
		combat_log.emit("%s's Sanctuary shatters as they take aggressive action!" % attacker.unit_name)

	# Shadow Strike: first attack from stealth is a guaranteed crit
	var _stealth_attack = "is_stealthed" in attacker and attacker.is_stealthed

	# Calculate hit chance
	var hit_chance = calculate_hit_chance(attacker, defender)
	var roll = randf() * 100.0
	var hit = _stealth_attack or (roll <= hit_chance)  # stealth = auto-hit

	# Force-miss: that_was_supposed_to_miss perk applied this flag to the attacker
	if not _stealth_attack and "will_miss_next_attack" in attacker and attacker.will_miss_next_attack:
		hit = false
		attacker.will_miss_next_attack = false
		combat_log.emit("%s swings wide — it was supposed to miss!" % attacker.unit_name)
	# Force_Miss status (next_attack_misses effect) also forces a miss and then expires
	if not _stealth_attack and hit and StatusRules.has_flag(attacker, "next_attack_misses"):
		hit = false
		_remove_status_by_name(attacker, "Force_Miss")
		combat_log.emit("%s's attack goes completely wide!" % attacker.unit_name)

	# Blessed_Shot: next_ranged_guaranteed_hit forces a hit for ranged weapon attacks, then expires
	var _is_ranged_bshot = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false
	if not hit and _is_ranged_bshot and StatusRules.has_flag(attacker, "next_ranged_guaranteed_hit"):
		hit = true
		_remove_status_by_name(attacker, "Blessed_Shot")
		combat_log.emit("%s's shot is divinely guided — guaranteed hit!" % attacker.unit_name)

	# Mirror Images: an illusory copy absorbs the strike instead of the real target
	if hit and StatusRules.has_flag(defender, "copies_absorb_attacks"):
		hit = false
		_consume_mirror_image(defender)
		combat_log.emit("%s's blow passes through an illusory copy of %s!" % [attacker.unit_name, defender.unit_name])

	# --- Intercepting triggers: the defender's statuses answer the blow before
	# it lands (EffectVocab.INTERCEPT_TRIGGERS). `incoming_attack` first (Reflect:
	# the strike rebounds on the attacker, for the damage the defender would have
	# taken), then `attacked_in_melee` (the stances: Heavenly Counterflow turns it
	# aside). Whatever else those triggers do — a counter-attack, a step away —
	# waits in `pending` until the blow is over.
	var negated := false
	var pending: Array = []
	if hit and attacker != defender:
		var seen: Dictionary = _intercept(defender, attacker, "incoming_attack", true, pending)
		if seen.reflect:
			hit = false
			var refl_type: String = attacker.get_weapon_damage_type() if attacker.has_method("get_weapon_damage_type") else "crushing"
			var refl_result = calculate_physical_damage(attacker, defender, refl_type)
			var refl_dmg: int = maxi(1, refl_result.get("damage", 1))
			apply_damage(attacker, refl_dmg, refl_type)
			combat_log.emit("%s's mirror turns the blow back — %s takes %d damage!" % [defender.unit_name, attacker.unit_name, refl_dmg])
		elif seen.negate:
			hit = false
			negated = true
	if hit and _grid_distance(attacker.grid_position, defender.grid_position) <= 1:
		var seen: Dictionary = _intercept(defender, attacker, "attacked_in_melee", true, pending)
		if seen.negate:
			hit = false
			negated = true
			combat_log.emit("%s: %s — the blow finds nobody there."
				% [defender.unit_name, str(seen.by).replace("_", " ")])

	# Get weapon damage type (slashing, crushing, piercing)
	var weapon_dmg_type = attacker.get_weapon_damage_type() if attacker.has_method("get_weapon_damage_type") else "crushing"

	var result = {
		"success": true,
		"hit": hit,
		"hit_chance": hit_chance,
		"roll": roll,
		"damage": 0,
		"crit": false,
		"damage_type": weapon_dmg_type,
		"cover": _last_cover_result
	}
	if negated:
		# Turned aside by a status, not missed: it reads as a dodge.
		result["dodged"] = true
		result["negated"] = true

	if hit:
		# Reactions decided before the blow answer it once it has landed
		# (_process_reactive_statuses runs them first).
		result["_pending_reactions"] = pending
		# Track last attacker for risen_dead and similar effects
		if "last_attacker" in defender:
			defender.last_attacker = attacker

		# Calculate damage
		var damage_result = calculate_physical_damage(attacker, defender, weapon_dmg_type)
		result.merge(damage_result, true)

		# Air_Shield: ranged attacks deal 25% less damage to the defender
		if is_ranged and StatusRules.has_flag(defender, "ranged_damage_reduction"):
			result["damage"] = int(result["damage"] * 0.75)
		# `ranged` resistance — Silk armour's +10 — is the same axis as Air_Shield:
		# a resistance to how the hit arrived, not what it is made of. So it is
		# read here, beside it, rather than by the damage-type resolver. A hit
		# that was landing for something still lands for at least 1.
		if is_ranged and result["damage"] > 0:
			var turned: float = Resistance.delivery(defender, "ranged")
			if turned != 0.0:
				result["damage"] = maxi(1, int(result["damage"] * (1.0 - turned / 100.0)))

		# Riposte_Ready (riposte perk): next sword attack +25% damage, −2 stamina, consumed
		if StatusRules.has_flag(attacker, "riposte_next_sword_attack"):
			var rip_weapon: Dictionary = attacker.get_equipped_weapon() if attacker.has_method("get_equipped_weapon") else {}
			if rip_weapon.get("type", "") == "sword":
				result["damage"] = int(result["damage"] * 1.25)
				if attacker.has_method("restore_stamina"):
					attacker.restore_stamina(2)
				_remove_status_by_name(attacker, "Riposte_Ready")
				combat_log.emit("%s ripostes — the counter lands harder!" % attacker.unit_name)

		# Shadow Strike: stealth attack is always a crit (apply crit multiplier if not already a crit)
		if _stealth_attack and not result.get("crit", false):
			result["crit"] = true
			result["damage"] = int(result["damage"] * 1.5)
		# Break stealth / invisibility after attacking
		if _stealth_attack:
			var _att_char_sd = attacker.character_data if "character_data" in attacker else {}
			# A status that breaks on attacking but leaves stealth in place (Invisible).
			var _is_invisible: bool = StatusRules.has_flag(attacker, "attack_breaks_invisibility")
			if _is_invisible:
				# Invisible: attacking consumes the Invisible status but stealth persists
				_remove_status_by_name(attacker, "Invisible")
				combat_log.emit("%s's invisibility shatters — but remains in the shadows." % attacker.unit_name)
			else:
				# Regular stealth: break rules apply
				var _shady = PerkSystem.has_perk(_att_char_sd, "shady_dealings")
				var _is_melee_sd = not (attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon())
				if _is_melee_sd:
					_leave_stealth(attacker)
					combat_log.emit("%s breaks stealth with a melee attack!" % attacker.unit_name)
				elif not _shady:
					_leave_stealth(attacker)
					combat_log.emit("%s breaks stealth with an attack!" % attacker.unit_name)
				else:
					if _shady_dealings_detected(attacker):
						_leave_stealth(attacker)
						combat_log.emit("An enemy detected %s despite Shady Dealings!" % attacker.unit_name)
					else:
						combat_log.emit("%s stays hidden (Shady Dealings)." % attacker.unit_name)

		# Apply damage (recording the HP it actually cost), then weapon oil —
		# the same two helpers every extra arm uses.
		_apply_hit_damage(attacker, defender, result)
		_apply_weapon_oil(attacker, defender, result)

		# --- An imbued arrow delivers its spell on hit ---
		#
		# Arcane Archer: the spell was paid for when the arrow was drawn, so
		# this applies its effects with the ranged accuracy that already
		# decided the hit — which is the whole trick of the perk.
		if attacker.has_meta("imbued_spell"):
			var imbued_id: String = str(attacker.get_meta("imbued_spell"))
			attacker.remove_meta("imbued_spell")
			var imbued: Dictionary = get_spell(imbued_id)
			# Spare the fallen: if the arrow itself dropped the defender, the
			# spell spends itself on nothing — no statuses ride a downed body
			# into its revive (same rule as _apply_on_hit_status).
			if not imbued.is_empty() and not defender.is_alive():
				combat_log.emit("%s's %s fades — the target is already down."
					% [attacker.unit_name, imbued.get("name", imbued_id)])
			elif not imbued.is_empty():
				var bonus: int = _calculate_spell_bonus(attacker, imbued)
				var delivered: Dictionary = _apply_spell_effects(
					attacker, defender, imbued, bonus)
				result["imbued_spell"] = imbued_id
				result["imbued_result"] = delivered
				combat_log.emit("%s's arrow carries %s home."
					% [attacker.unit_name, imbued.get("name", imbued_id)])

		# --- Reactive status effects on hit ---
		_process_reactive_statuses(attacker, defender, result)

		# --- Damage from caster breaks Charmed ---
		# If the attacker was the one who charmed the defender, break charm
		if "status_effects" in defender:
			var charms: Array = []
			for se in StatusRules.entries_with_flag(defender, "breaks_on_damage_from_source"):
				if se.get("source", null) == attacker:
					charms.append(se)
			charms.reverse()
			for charm in charms:
				var charm_name: String = str(charm.get("status", ""))
				_end_status(defender, charm, "removed")
				if defender.has_method("show_status_expired"):
					defender.show_status_expired(charm_name)
				status_effect_expired.emit(defender, charm_name)

		# --- Talisman: Thorns — reflect 3 damage to melee attackers ---
		var is_melee_attack = _grid_distance(attacker.grid_position, defender.grid_position) <= 1
		if is_melee_attack and _unit_has_talisman_perk(defender, "thorns"):
			apply_damage(attacker, 3, "physical")
			result["thorns_damage"] = 3

		# --- Attacker lifesteal statuses ---
		if StatusRules.has_flag(attacker, "lifesteals_on_hit"):
			var steal_pct = 0.5
			if _unit_has_perk(attacker, "blood_pact"):
				steal_pct *= 1.25  # Blood Pact: lifesteal heals 25% more
			var steal = int(result.damage * steal_pct)
			if steal > 0:
				attacker.heal(steal)
				unit_healed.emit(attacker, steal)
				result["lifesteal"] = steal

		# --- On-hit perks, perk triggers and weapon procs ---
		# Shared with the extra arms of a multi-arm chain.
		_resolve_hit_procs(attacker, defender, result)
		# --- Ammo special effects (fire arrow AoE, status procs) ---
		if "get_selected_ammo" in attacker:
			var ammo = attacker.get_selected_ammo()
			if ammo.has("special_effect"):
				_process_ammo_special_effect(attacker, defender, ammo)
		# --- Weapon durability ---
		_deduct_weapon_durability(attacker)

		# --- Urumi sweep: hit all other adjacent enemies at -15 accuracy ---
		if attacker.has_method("get_equipped_weapon"):
			var sweep_weapon = attacker.get_equipped_weapon()
			if sweep_weapon.get("special_attack", "") == "sweep":
				var sweep_targets = _get_enemies_in_range(attacker, 1)
				sweep_targets.erase(defender)  # primary target already hit
				for sweep_target in sweep_targets:
					if not sweep_target.is_alive():
						continue
					var sweep_hit_chance = calculate_hit_chance(attacker, sweep_target) - 15.0
					if randf() * 100.0 <= sweep_hit_chance:
						var sweep_dmg_result = calculate_physical_damage(attacker, sweep_target, weapon_dmg_type)
						# No crit bonus on sweep hits
						sweep_dmg_result["crit"] = false
						sweep_dmg_result["damage"] = int(sweep_dmg_result.get("damage", 0) * 0.75)
						apply_damage(sweep_target, maxi(1, sweep_dmg_result.get("damage", 0)), weapon_dmg_type)
						combat_log.emit("%s's urumi sweeps %s!" % [attacker.unit_name, sweep_target.unit_name])
						result["sweep_hit"] = true

	else:
		# Attack missed — check dodge/parry perks on defender. A blow a status
		# turned aside (negated) was not dodged by the defender's own skill, so
		# it fires none of them; it answers with its own trigger's effects.
		if negated:
			_run_pending_triggers(pending)
		else:
			_process_on_dodge_perks(defender, attacker)
			_fire_dodge_success(defender, attacker, is_ranged)
		# A melee blow that missed someone holding a melee weapon met steel:
		# that is a parry as well as a dodge, and fires both. Riposte has
		# always read "dodge or parry" as one moment; this keeps the two
		# apart for perks that want only the second.
		if not negated and _is_parry(defender, attacker, is_ranged):
			_fire_perk_triggers(defender, "parry_success", {"attacker": attacker})
		# Reset consecutive hit streaks on miss
		attacker.momentum_stacks = 0
		attacker.unarmed_hit_stacks = 0
		# Ranged misses: projectile deviates and may hit someone else.
		# Clamp to 0 so forced-miss perks (will_miss_next_attack) don't produce negative margin.
		if is_ranged:
			var miss_margin: float = maxf(0.0, result.roll - result.hit_chance)
			var dev = _resolve_projectile_deviation(attacker, defender, miss_margin)
			result.merge(dev, true)

	# "Your next attack gains…" buffs (Borrowed Force, Borrowed Opening) have
	# now been used by this blow — hit or miss — whatever turn they had left.
	_spend_next_attack_modifiers(attacker)

	# Track per-turn attack type counters (after resolving, so 'first attack' checks work)
	_count_weapon_attack(attacker)
	if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
		# Consume one ammo; revert to default if depleted
		if "selected_ammo_id" in attacker and attacker.selected_ammo_id != "":
			var still_has_ammo = ItemSystem.consume_ammo(attacker.selected_ammo_id)
			if not still_has_ammo:
				var ammo_name = ItemSystem.get_ammo(attacker.selected_ammo_id).get("name", attacker.selected_ammo_id)
				combat_log.emit("%s's %s ran out — falling back to bone arrows." % [attacker.unit_name, ammo_name])
				attacker.selected_ammo_id = ""

	if not reaction:
		use_action(1)

	# Multi-arm attack chain: each arm beyond the first fires probabilistically based on Finesse.
	# Melee only; chain stops when an arm fails its roll (coordination degraded).
	var extra_arm_results: Array[Dictionary] = []
	if not reaction and not is_ranged and BodySystem:
		var char_data: Dictionary = attacker.character_data if "character_data" in attacker else {}
		var arm_count: int = BodySystem.get_attack_arm_count(char_data)
		if arm_count > 1:
			# Only chain for dual-wielders, natural weapon species, or genuinely multi-armed characters
			var should_chain: bool = (arm_count > 2)
			if not should_chain:
				# The off hand lives inside the active weapon set
				# (equipment.weapon_set_N.off); ItemSystem knows which set is
				# active. Reading equipment["weapon_off"] directly found nothing,
				# so a two-armed dual-wielder never chained at all.
				var oh_id: String = ItemSystem.get_equipped_item(char_data, "weapon_off")
				should_chain = (oh_id != "")
			if not should_chain:
				var primary_nw: Dictionary = BodySystem.get_natural_weapon(char_data, "hand_r")
				should_chain = primary_nw.get("locked", false)
			if should_chain:
				# Coordinated Strikes: when an arm's blow kills, the chain resets —
				# the remaining arms redirect to a fresh target instead of stopping.
				var has_coordinated: bool = PerkSystem.has_perk(char_data, "coordinated_strikes")
				var chain_target: Node = defender
				for arm_index in range(1, arm_count):
					var arm_number: int = arm_index + 1
					# Finesse formula + Akimbo, or a flat 100 for Iron Cortex's
					# second arm. randf() never exceeds 1.0, so 100 always fires.
					var fire_chance: float = arm_chain_fire_chance(char_data, arm_number)
					if randf() * 100.0 <= fire_chance:
						if chain_target != null and chain_target.is_alive():
							var extra := _execute_arm_chain_attack(attacker, chain_target, arm_number, fire_chance)
							extra_arm_results.append(extra)
							if not chain_target.is_alive():
								if not has_coordinated:
									break
								# Redirect to the nearest living enemy still in reach
								chain_target = _find_chain_redirect_target(attacker)
								if chain_target == null:
									break
								combat_log.emit("%s's momentum carries on — Coordinated Strikes redirects to %s!" % [
									attacker.unit_name, chain_target.unit_name])
					else:
						break  # Coordination degraded; remaining arms don't roll
	result["extra_arm_results"] = extra_arm_results

	unit_attacked.emit(attacker, defender, result)
	return result


## Resolve a ranged projectile miss — calculate deviation and apply damage if it hits someone.
## Returns a dict with deviation_* fields merged into the attack result.
func _resolve_projectile_deviation(attacker: Node, defender: Node, miss_margin: float) -> Dictionary:
	# Deviation distance scales with how badly the shot missed (margin already clamped ≥0 by caller)
	var dev_tiles: int
	if miss_margin <= 15.0:
		dev_tiles = 1
	elif miss_margin <= 35.0:
		dev_tiles = 2
	else:
		dev_tiles = 3

	var intended_pos: Vector2i = defender.grid_position

	# Exclude the direction pointing back toward the attacker so the shot never reverses
	var back_dir := Vector2i(
		signi(attacker.grid_position.x - intended_pos.x),
		signi(attacker.grid_position.y - intended_pos.y)
	)
	var valid_dirs: Array[Vector2i] = []
	for d: Vector2i in DIRS_8:
		if d != back_dir:
			valid_dirs.append(d)

	var dir: Vector2i = valid_dirs[randi() % valid_dirs.size()]
	var landing := intended_pos + dir * dev_tiles

	# Clamp to grid bounds
	if combat_grid != null:
		landing.x = clampi(landing.x, 0, combat_grid.grid_size.x - 1)
		landing.y = clampi(landing.y, 0, combat_grid.grid_size.y - 1)

	var dev_result := {
		"deviation_tiles": dev_tiles,
		"deviation_landing_pos": landing,
		"deviation_hit_unit_name": "",
		"deviation_hit_team": -1,
		"deviation_damage": 0
	}

	# Check if any living unit occupies the landing tile.
	# Explicitly exclude the original defender — a miss should never hit them as a stray.
	var stray_target := get_unit_at(landing)
	if stray_target != null and stray_target != defender and stray_target.is_alive():
		var dmg_type: String = attacker.get_weapon_damage_type() if attacker.has_method("get_weapon_damage_type") else "physical"
		var dmg_result := calculate_physical_damage(attacker, stray_target, dmg_type)
		var dmg: int = dmg_result.get("damage", 0)
		apply_damage(stray_target, dmg, dmg_type)
		dev_result["deviation_hit_unit_name"] = stray_target.unit_name
		dev_result["deviation_hit_team"] = stray_target.team
		dev_result["deviation_damage"] = dmg
		combat_log.emit("  Projectile deviates %d tile(s) — stray hit on %s for %d!" % [
			dev_tiles, stray_target.unit_name, dmg
		])
	else:
		combat_log.emit("  Projectile deviates %d tile(s) — lands wide." % dev_tiles)

	return dev_result


## Calculate hit chance (percentage)
## Returns the hit chance and stores cover info in _last_cover_result for logging
var _last_cover_result: Dictionary = {}

## Hit chance and damage are both worked out by reading the attacker's stat
## getters, and a passive perk can make those getters depend on the target
## ("+10% crit against a bleeding enemy"). A getter has no target argument, so
## for the length of the calculation the attacker is told who it is aiming at
## through perk_attack_target, then told again what it was told before — a
## reaction attack can start inside another attack's calculation.
func calculate_hit_chance(attacker: Node, defender: Node) -> float:
	var previous: Node = _aim_perks_at(attacker, defender)
	var chance: float = _calculate_hit_chance(attacker, defender)
	_aim_perks_at(attacker, previous)
	return chance


func calculate_physical_damage(attacker: Node, defender: Node, dmg_type: String = "crushing") -> Dictionary:
	var previous: Node = _aim_perks_at(attacker, defender)
	var result: Dictionary = _calculate_physical_damage(attacker, defender, dmg_type)
	_aim_perks_at(attacker, previous)
	return result


## Point `attacker`'s target-dependent perk conditions at `target`, returning
## whatever they pointed at before so the caller can put it back.
func _aim_perks_at(attacker: Node, target: Node) -> Node:
	if attacker == null or not "perk_attack_target" in attacker:
		return null
	var previous: Node = attacker.perk_attack_target
	attacker.perk_attack_target = target
	return previous


func _calculate_hit_chance(attacker: Node, defender: Node) -> float:
	var base_chance = 80.0
	var accuracy = attacker.get_accuracy()
	var dodge = defender.get_dodge()

	var hit_chance = base_chance + accuracy - dodge

	# Every Opening Is an Invitation: +15% accuracy against enemies suffering a status
	var att_char = attacker.character_data if "character_data" in attacker else {}
	if _opening_is_an_invitation(attacker, defender):
		hit_chance += 15.0

	# Close and Personal: +15% accuracy when adjacent to exactly one enemy
	if PerkSystem.has_perk(att_char, "close_and_personal"):
		var adjacent_enemies = _get_enemies_in_range(attacker, 1)
		if adjacent_enemies.size() == 1:
			hit_chance += 15.0

	# Disciplined Formation: +10% accuracy while adjacent to an ally
	if PerkSystem.has_perk(att_char, "disciplined_formation"):
		if _get_allies_in_range(attacker, 1).size() > 0:
			hit_chance += 10.0

	# Water Finds the Gap: spear attacks vs enemies who moved last turn +15% accuracy
	if PerkSystem.has_perk(att_char, "water_finds_the_gap"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "spear":
				if "moved_this_turn" in defender and defender.moved_this_turn:
					hit_chance += 15.0

	# Offhand Jab: +10% accuracy when main weapon is a dagger AND off-hand slot also holds a dagger
	if PerkSystem.has_perk(att_char, "offhand_jab"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "dagger":
				var oh_id = ItemSystem.get_equipped_item(att_char, "weapon_off")  # active weapon set
				if oh_id != "" and ItemSystem.get_item(oh_id).get("type", "") == "dagger":
					hit_chance += 10.0

	# Too Fast to Count: first dagger attack each turn is guaranteed to hit
	if PerkSystem.has_perk(att_char, "too_fast_to_count"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "dagger":
				if "dagger_attacks_this_turn" in attacker and attacker.dagger_attacks_this_turn == 0:
					hit_chance = 95.0  # clamp max ensures guaranteed hit

	# One Breath, One Arrow: first ranged attack each turn gains +15% accuracy
	if PerkSystem.has_perk(att_char, "one_breath_one_arrow"):
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			if "ranged_attacks_this_turn" in attacker and attacker.ranged_attacks_this_turn == 0:
				hit_chance += 15.0

	# Crushing Depths (Water 4): +15% accuracy vs enemies on water/ice terrain or with 2+ water debuffs
	if PerkSystem.has_perk(att_char, "crushing_depths"):
		var crushing_bonus = false
		# Check terrain at defender's position
		if combat_grid and "grid_position" in defender:
			var terrain_eff = combat_grid.get_terrain_effect(defender.grid_position)
			if terrain_eff in [2, 7]:  # ICE=2, WET=7
				crushing_bonus = true
		# Or check for 2+ water-type debuffs
		if not crushing_bonus and "status_effects" in defender:
			var water_debuffs = ["Slowed", "Frozen", "Chilled", "Waterlogged", "Rooted"]
			var wdc = 0
			for se in defender.status_effects:
				if se.get("status", "") in water_debuffs:
					wdc += 1
			if wdc >= 2:
				crushing_bonus = true
		if crushing_bonus:
			hit_chance += 15.0

	# Wall of Points: attacker suffers -10% accuracy when within 2 tiles of a spear-wielding defender
	var def_char_wop = defender.character_data if "character_data" in defender else {}
	if PerkSystem.has_perk(def_char_wop, "wall_of_points"):
		if defender.has_method("get_equipped_weapon") and defender.get_equipped_weapon().get("type", "") == "spear":
			if _grid_distance(attacker.grid_position, defender.grid_position) <= 2:
				hit_chance -= 10.0

	# Call the Shot (Leadership 1): marked targets are easier to hit — +15% accuracy
	# The mark is consumed on the first damaging hit (see calculate_physical_damage)
	if "is_marked" in defender and defender.is_marked:
		hit_chance += 15.0

	# Height advantage bonus (+5 per level, -5 penalty when lower)
	if combat_grid:
		hit_chance += combat_grid.get_height_accuracy_bonus(attacker.grid_position, defender.grid_position)

	# Cover penalty for ranged attacks — obstacles between attacker and defender
	_last_cover_result = {}
	var is_ranged = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false
	if is_ranged and combat_grid:
		var cover = combat_grid.get_cover_bonus(attacker.grid_position, defender.grid_position)
		if cover.has_cover:
			hit_chance -= cover.dodge_bonus
			_last_cover_result = cover

	# Call the Shot (Leadership 1): next ally to attack a marked target gets +15% accuracy
	for ally in get_team_units(attacker.team if "team" in attacker else 0):
		if "marked_target" in ally and ally.marked_target == defender:
			hit_chance += 15.0
			break  # only check, don't clear — damage calc clears it

	# Ally flank defense: each adjacent ally standing on the defender's exact flank tile
	# reduces hit chance by 10% (shields the flanks — enables shieldwall tactics)
	if "facing" in defender and "grid_position" in defender and defender.facing != Vector2i.ZERO:
		var df = defender.facing
		var left_flank  = defender.grid_position + Vector2i(-df.y,  df.x)
		var right_flank = defender.grid_position + Vector2i( df.y, -df.x)
		for ally in get_team_units(defender.team if "team" in defender else 0):
			if ally == defender or ally.is_dead or ally.is_bleeding_out:
				continue
			if ally.grid_position == left_flank or ally.grid_position == right_flank:
				hit_chance -= 10.0

	# Blurred: defender's blurred state causes an extra 20% miss chance on all attacks
	if StatusRules.has_flag(defender, "attacks_have_miss_chance"):
		hit_chance -= 20.0

	# Clamp to 10-95%
	return clampf(hit_chance, 10.0, 95.0)


## Every Opening Is an Invitation (Guile 5): "+15% Attack and +10% crit
## chance against enemies SUFFERING from any status effect." Suffering is the
## word — it counted any status at all, so a Blessed or Hasted enemy opened
## itself up to you. Debuffs only, by the same test target_debuffed uses.
## One function so the accuracy and the crit half cannot drift apart.
func _opening_is_an_invitation(attacker: Node, defender: Node) -> bool:
	var att_char: Dictionary = attacker.character_data if "character_data" in attacker else {}
	return PerkSystem.has_perk(att_char, "every_opening_is_an_invitation") \
		and unit_has_debuff(defender)


## Living Fortress: "While in heavy armor, immune to critical hits." True
## when this defender has the perk and wears any heavy piece right now.
func _crit_turned_by_living_fortress(defender: Node) -> bool:
	if not "character_data" in defender or not defender.has_method("is_wearing_heavy_armor"):
		return false
	return PerkSystem.has_perk(defender.character_data, "living_fortress") \
		and defender.is_wearing_heavy_armor()


## Calculate physical damage (slashing, crushing, or piercing).
## Called through calculate_physical_damage() above, which aims the perks.
func _calculate_physical_damage(attacker: Node, defender: Node, dmg_type: String = "crushing") -> Dictionary:
	# Thin_Air: unit cannot deal physical damage at all
	if StatusRules.has_flag(attacker, "cannot_deal_physical"):
		return {"damage": 0, "crit": false, "armor_pen": 0}

	# Base damage from weapon + attribute + skill
	var base_damage = attacker.get_attack_damage()

	# Height damage bonus
	var height_bonus = 0
	if combat_grid:
		var is_ranged = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false
		height_bonus = combat_grid.get_height_damage_bonus(attacker.grid_position, defender.grid_position, is_ranged)
		base_damage += height_bonus

	# Variance ±15%
	var variance = randf_range(0.85, 1.15)
	var damage = int(base_damage * variance)

	# Check for crit (include weapon oil crit bonus if active)
	var crit_chance = attacker.get_crit_chance()
	if not attacker.weapon_oil.is_empty():
		crit_chance += attacker.weapon_oil.get("crit_bonus", 0)
	# Every Opening Is an Invitation: +10% crit against enemies suffering a status
	var att_char_eoia = attacker.character_data if "character_data" in attacker else {}
	if _opening_is_an_invitation(attacker, defender):
		crit_chance += 10.0

	# Cheap Shot (Guile 1): +15% crit on the first attack vs each individual enemy
	if PerkSystem.has_perk(att_char_eoia, "cheap_shot"):
		if not ("enemies_hit_this_combat" in attacker and defender in attacker.enemies_hit_this_combat):
			crit_chance += 15.0

	# Offhand Jab: +5% crit when main and off-hand are both daggers
	if PerkSystem.has_perk(att_char_eoia, "offhand_jab"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "dagger":
			var oh_id_oj = ItemSystem.get_equipped_item(att_char_eoia, "weapon_off")  # active weapon set
			if oh_id_oj != "" and ItemSystem.get_item(oh_id_oj).get("type", "") == "dagger":
				crit_chance += 5.0

	# Clean Line: +10% crit vs isolated targets (no allies adjacent to defender)
	if PerkSystem.has_perk(att_char_eoia, "clean_line"):
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			var def_has_adj_ally = false
			for u in get_team_units(defender.team if "team" in defender else 1):
				if u == defender:
					continue
				if _grid_distance(u.grid_position, defender.grid_position) <= 1:
					def_has_adj_ally = true
					break
			if not def_has_adj_ally:
				crit_chance += 10.0

	# Facing zone: positional bonuses based on where attacker stands relative to defender's facing
	# Rear gives +20% crit chance; flank and rear both give +20% damage (applied after armor below)
	var _facing_zone = _get_facing_zone(attacker.grid_position, defender)
	if _facing_zone == "rear":
		crit_chance += 20.0

	# Backstab (Daggers perk): dagger + stealth required for the full perk bonus.
	# Works from flank or rear only — impossible from front.
	var _backstab_triggered = false
	if PerkSystem.has_perk(att_char_eoia, "backstab"):
		var is_dagger_bs = attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "dagger"
		var is_stealthed_bs = "is_stealthed" in attacker and attacker.is_stealthed
		if is_dagger_bs and is_stealthed_bs and _facing_zone in ["flank", "rear"]:
			# Rear gives bigger bonus (+35%) than flank (+25%)
			crit_chance += 35.0 if _facing_zone == "rear" else 25.0
			_backstab_triggered = true
			if defender.has_method("show_combat_text"):
				var bs_crit = 35 if _facing_zone == "rear" else 25
				defender.show_combat_text("Backstab! +%d%% crit" % bs_crit, Color(0.75, 0.1, 0.9))

	# Marked_for_Death: defender has crit_vulnerability (+25% crit chance against them)
	if StatusRules.has_flag(defender, "crit_vulnerability"):
		crit_chance += 25.0

	var crit = randf() * 100.0 <= crit_chance
	# Living Fortress (Armor 9): in heavy armour no hit against you is a
	# critical — it lands as a normal hit (no extra damage, armour holds).
	if crit and _crit_turned_by_living_fortress(defender):
		crit = false
	# Backstab crits deal 2x damage (replacing the 1.5x standard multiplier)
	var crit_multi = 2.0 if (_backstab_triggered and crit) else 1.5

	if crit:
		damage = int(damage * crit_multi)

	# Hard Knuckles: unarmed attacks ignore 25% of target's Armor
	var att_char_phys = attacker.character_data if "character_data" in attacker else {}
	var is_unarmed_attack = false
	if attacker.has_method("get_equipped_weapon"):
		var w = attacker.get_equipped_weapon()
		is_unarmed_attack = w.is_empty() or w.get("type", "") in ["", "unarmed"]

	# Anatomy Knowledge: +10% damage vs biological enemies
	if PerkSystem.has_perk(att_char_phys, "anatomy_knowledge") and _unit_is_biological(defender):
		damage = int(damage * 1.10)

	# Close and Personal: +15% damage when adjacent to exactly one enemy
	if PerkSystem.has_perk(att_char_phys, "close_and_personal"):
		var adjacent_enemies = _get_enemies_in_range(attacker, 1)
		if adjacent_enemies.size() == 1:
			damage = int(damage * 1.15)

	# Apply armor (flat reduction)
	var armor = defender.get_armor()
	if crit:
		armor = int(armor * 0.5)  # Crits ignore 50% armor

	# Hard Knuckles reduces effective armor by 25% for unarmed attacks
	if PerkSystem.has_perk(att_char_phys, "hard_knuckles") and is_unarmed_attack:
		armor = int(armor * 0.75)
	# Water Finds the Gap: spear vs target who moved — ignore 15% armor
	if PerkSystem.has_perk(att_char_phys, "water_finds_the_gap"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "spear":
				if "moved_this_turn" in defender and defender.moved_this_turn:
					armor = int(armor * 0.85)

	# Between the Ribs: daggers ignore 25% of the target's armor
	if PerkSystem.has_perk(att_char_phys, "between_the_ribs"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "dagger":
			armor = int(armor * 0.75)

	# One Breath, One Arrow: first ranged attack that crits ignores all armor
	if PerkSystem.has_perk(att_char_phys, "one_breath_one_arrow") and crit:
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			if "ranged_attacks_this_turn" in attacker and attacker.ranged_attacks_this_turn == 0:
				armor = 0

	# Weapon armor pierce — flat reduction to effective armor before damage
	if attacker.has_method("get_armor_pierce"):
		var pierce = attacker.get_armor_pierce()
		if pierce > 0:
			armor = maxi(0, armor - pierce)

	damage = maxi(1, damage - armor)

	# Facing zone damage bonus (applied post-armor so it amplifies effective damage)
	if _facing_zone == "flank":
		damage = int(damage * 1.20)
		combat_log.emit("%s attacks from the flank! (+20%% dmg)" % attacker.unit_name)
		if not _backstab_triggered and defender.has_method("show_combat_text"):
			defender.show_combat_text("Flanking! +20%", Color(1.0, 0.65, 0.0))
	elif _facing_zone == "rear":
		damage = int(damage * 1.20)
		combat_log.emit("%s attacks from behind! (+20%% dmg, +20%% crit)" % attacker.unit_name)
		if not _backstab_triggered and defender.has_method("show_combat_text"):
			defender.show_combat_text("From Behind! +20%", Color(1.0, 0.45, 0.0))

	# Hit Back Harder (Might 3): +20% melee damage after taking any damage; consumed on first attack
	if "hit_back_ready" in attacker and attacker.hit_back_ready:
		var is_melee_hbh = _grid_distance(attacker.grid_position, defender.grid_position) <= 1
		if is_melee_hbh:
			damage = int(damage * 1.20)
			attacker.hit_back_ready = false

	# Permafrost (Water 5): Frozen enemies take +30% all damage
	if defender.has_status("Frozen"):
		damage = int(damage * 1.30)

	# Steady Aim: +10% damage if didn't move this turn (ranged only)
	if PerkSystem.has_perk(att_char_phys, "steady_aim"):
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			if not ("moved_this_turn" in attacker and attacker.moved_this_turn):
				damage = int(damage * 1.10)

	# Sudden End (Daggers 7): first stealth attack deals +100% crit damage vs any target
	# (bleed is applied in _process_on_hit_perks after the hit lands)
	if PerkSystem.has_perk(att_char_phys, "sudden_end"):
		if "is_stealthed" in attacker and attacker.is_stealthed:
			if not crit:
				# Force crit multiplier even if not a crit (stealth backstab)
				damage = int(damage * 2.0)
			else:
				# Already crit — add 100% on top (brutal stealth crit)
				damage = int(damage * 2.0)

	# Skull Crack: +20% damage vs Stunned or Dazed targets (maces only)
	if PerkSystem.has_perk(att_char_phys, "skull_crack"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			if defender.has_status("Stunned") or defender.has_status("Dazed"):
				damage = int(damage * 1.20)

	# Call the Shot (Leadership 1): +15% damage on first ally attack vs marked target; clears mark
	for ally_cts in get_team_units(attacker.team if "team" in attacker else 0):
		if "marked_target" in ally_cts and ally_cts.marked_target == defender:
			damage = int(damage * 1.15)
			ally_cts.marked_target = null  # consume the mark
			if "is_marked" in defender:
				defender.is_marked = false  # sync both mark representations
			combat_log.emit("Called shot lands! +15% damage.")
			break

	# Resistance is NOT applied here. apply_damage() resolves it once, for every
	# source of damage in the game — which is what stopped nine call sites out
	# of sixty-one from being the only ones that respected it.

	# Lord of Death DY: empowered summons deal 30% bonus damage
	if "lord_of_death_empowered" in attacker and attacker.lord_of_death_empowered:
		damage = int(damage * 1.3)

	# A braced spear hits harder than a swing of opportunity. Set around
	# attack_unit() by free_reaction_attack() and cleared immediately after.
	if not is_equal_approx(_reaction_damage_mult, 1.0):
		damage = int(damage * _reaction_damage_mult)

	return {
		"damage": damage,
		"base_damage": base_damage,
		"crit": crit,
		"armor_reduced": armor,
		"height_bonus": height_bonus,
		"damage_type": dmg_type
	}


## Calculate elemental magic damage
func calculate_magic_damage(caster: Node, target: Node, base_spell_damage: int, element: String) -> Dictionary:
	var spellpower = caster.get_spellpower()
	var skill_bonus = caster.get_magic_skill_bonus(element)

	# Spellpower contributes at half value — prevents it dominating over spell base damage.
	# Formula: spell_base + (spellpower / 2) + skill_bonus
	# Example: Firebolt(15) + spellpower 10 → 15+5+10=30, not 15+10+10=35
	var base_damage = base_spell_damage + (spellpower / 2) + skill_bonus

	# Variance ±15%
	var variance = randf_range(0.85, 1.15)
	var damage = int(base_damage * variance)

	# Feed the Fire (Fire 3): +20% fire spell damage vs Burning targets
	var caster_char_ff = caster.character_data if "character_data" in caster else {}
	if element == "fire" and PerkSystem.has_perk(caster_char_ff, "feed_the_fire"):
		if target.has_status("Burning"):
			damage = int(damage * 1.20)

	# Permafrost (Water 5): Frozen targets take +30% all damage
	if target.has_status("Frozen"):
		damage = int(damage * 1.30)

	# Resistance is resolved once, in apply_damage(). Reported here so the UI
	# and the log can still say how much of the hit the target will turn.
	return {
		"damage": damage,
		"base_damage": base_damage,
		"element": element,
		"resistance": target.get_resistance(element),
		"damage_type": element
	}


## Apply damage to a unit, in one documented order.
##
## THE ORDER, and it is a multiplicative chain:
##
##   1. Resistance to the damage type, through `Resistance` — compound types
##      split and each half resisted separately; absorption heals instead.
##   2. Defender-side multipliers: Marked_for_Death.
##   3. Armour (physical only) and the Yoga table's equanimity (magic only),
##      each capped at 90%.
##   4. Aura and zone `damage_taken_pct`.
##   5. Shields, the ancestors' reprieve, and the floors that keep a unit at
##      1 HP.
##
## Attacker-side multipliers are deliberately NOT here. Feed the Fire,
## Permafrost, brands and called shots are facts about the attack rather than
## the defender, so they belong where the damage is computed — which is also
## why Permafrost's +30% lands before resistance and Marked_for_Death's +50%
## after it. That was an accident before it was a rule; now it is the rule.
## `source` is whoever dealt the damage, when the caller knows. It is optional
## because most of the sixty-odd callers (ticks, terrain, splash) have no one to
## name; it is only read by the take_damage / ally_damaged passive triggers.
func apply_damage(unit: Node, damage: int, damage_type: String, source: Node = null) -> void:
	# God mode: player units take no damage
	if CheatConsole and CheatConsole.god_mode and "team" in unit and unit.team == Team.PLAYER:
		unit_damaged.emit(unit, 0, damage_type)
		return

	# ── 1. Resistance to the damage type ────────────────────────────────────
	#
	# This is the step that was missing. `apply_damage` never consulted
	# resistance; every caller was expected to have applied it already, as
	# `damage * (1.0 - r / 100.0)`, hand-written. Of 61 call sites, 9 did. So
	# damage-over-time ticks, terrain hazards, aura and zone payloads,
	# retaliation, splash, cleave and every perk burst ignored resistance and
	# immunity entirely: a Solar Form character, immune to fire, took full
	# damage standing in a fire tile.
	#
	# Resolving it here covers every source at once, splits compound types so
	# each half meets its own resistance, and is where absorption turns a hit
	# into healing.
	if damage > 0 and _ignoring_resistance:
		# Too Fast to React: this one spell answers to nothing. The flag is
		# consumed by cast_spell, not here, because a spell that hits five
		# targets should ignore resistance on all five.
		pass
	elif damage > 0:
		var resisted: Dictionary = Resistance.resolve(unit, damage, damage_type)
		if int(resisted.healed) > 0:
			# The unit is not hurt by this, it is fed: a fire elemental drinks
			# fire. No damage side effects fire, because nothing was damaged.
			var fed: int = int(resisted.healed)
			unit.heal(fed)
			unit_healed.emit(unit, fed)
			combat_log.emit("%s drinks in the %s." % [unit.unit_name,
				DamageType.display_name(damage_type).to_lower()])
			if int(resisted.damage) <= 0:
				return
		damage = int(resisted.damage)
		if damage <= 0:
			unit_damaged.emit(unit, 0, damage_type)
			return

	# ── 2. Defender-side multipliers ────────────────────────────────────────
	#
	# Marked_for_Death: damage_taken_increase makes the unit take 50% more.
	# Attacker-side multipliers (Feed the Fire, Permafrost, brands) stay where
	# the damage is computed — they are facts about the attack, not the target.
	if damage > 0 and StatusRules.has_flag(unit, "damage_taken_increase"):
		damage = int(damage * 1.5)

	# ── 3. Armour, and equanimity ───────────────────────────────────────────
	#
	# The Armor table's flat reduction is PHYSICAL ONLY. It used to reduce every
	# damage type, magic included, on top of the Yoga table's magic resistance —
	# so a heavy-armour build resisted fireballs too and the two tables were not
	# complementary but stacked, with armour the better buy at every point.
	# Both stay capped at 90%.
	if damage > 0 and "character_data" in unit:
		var derived: Dictionary = unit.character_data.get("derived", {})
		if DamageType.is_physical(damage_type) and not DamageType.ignores_armour(damage_type):
			var reduction: float = derived.get("damage_reduction_pct", 0.0)
			if reduction > 0.0:
				damage = maxi(1, int(damage * (1.0 - minf(reduction, 90.0) / 100.0)))

		# Magic resistance from the Yoga table. A sword is not resisted by
		# equanimity, and neither is venom — see DamageType.is_magic().
		if DamageType.is_magic(damage_type):
			var magic_resist: float = derived.get("magic_resistance_pct", 0.0)
			if magic_resist > 0.0:
				damage = maxi(1, int(damage * (1.0 - minf(magic_resist, 90.0) / 100.0)))

	# ── 4. Auras and the ground ─────────────────────────────────────────────
	#
	# Dampening_Aura, the Vajra Mandala and anything else that multiplies
	# stat.magic_damage_taken / stat.physical_damage_taken: an aura reaching the
	# unit, the zone it stands in, or a status's hold, all read through
	# ValuePaths. Multiplicative with everything above, and with each other.
	if damage > 0:
		var kind: String = "magic" if DamageType.is_magic(damage_type) else "physical"
		var aura_mult: float = maxf(0.0, ValuePaths.apply_to(
			unit, "stat.%s_damage_taken" % kind, 1.0))
		if not is_equal_approx(aura_mult, 1.0):
			damage = maxi(1, int(damage * aura_mult))

	# ── 5. Shields, and the things that keep a unit alive ───────────────────
	#
	# Mantric_Armor: hp_shield absorbs damage before HP. Shield pool lives in the
	# status entry's "value" field (0/unset → default 25); status expires when spent.
	if damage > 0:
		for effect in unit.status_effects:
			var sdef_shield = _status_effects.get(effect.get("status", ""), {})
			if StatusRules.def_has_flag(sdef_shield, "hp_shield"):
				var pool: int = int(effect.get("value", 0))
				if pool <= 0:
					pool = 25
				var absorbed: int = mini(damage, pool)
				damage -= absorbed
				effect["value"] = pool - absorbed
				combat_log.emit("%s's mantric armor absorbs %d damage." % [unit.unit_name, absorbed])
				if effect["value"] <= 0:
					_remove_status_by_name(unit, effect.get("status", ""))
					combat_log.emit("%s's mantric armor is destroyed!" % unit.unit_name)
				break

	# Unbroken (Armor 10): once per combat, stop at 25% HP and double Armor.
	# Before the death-saves below, so it is spent first.
	if damage > 0 and unit.has_method("trigger_unbroken"):
		damage = unit.trigger_unbroken(damage)

	# Ancestors_Blessing: death_resistance — survive one otherwise-fatal hit at 1 HP,
	# consuming the blessing.
	if damage >= unit.current_hp and unit.current_hp > 0 and StatusRules.has_flag(unit, "death_resistance"):
		damage = unit.current_hp - 1
		var dr_entry: Dictionary = StatusRules.entry_with_flag(unit, "death_resistance")
		if not dr_entry.is_empty():
			_remove_status_by_name(unit, dr_entry.get("status", ""))
		combat_log.emit("The ancestors hold %s back from the brink!" % unit.unit_name)
		_mark_death_touched(unit)

	# Swarmed: focus_save_on_damage — each hit forces a Focus save (DC 12) or the
	# swarm's distraction costs the unit an action on its next turn.
	if damage > 0 and StatusRules.has_flag(unit, "focus_save_on_damage"):
		var focus_val: int = unit_attribute(unit, "focus")
		if randi() % 20 + 1 + int(focus_val / 2.0) < 12 and not unit.get_meta("swarm_distracted", false):
			unit.set_meta("swarm_distracted", true)
			combat_log.emit("%s loses focus amid the swarm!" % unit.unit_name)

	# Death_Immunity: hp_cannot_drop_below_1 — cap damage so unit stays at 1 HP minimum.
	# `cannot_die` says the same thing in the words its tooltip uses, so it
	# is read here too (Death_Immunity carries both).
	if damage > 0 and StatusRules.has_any_flag(unit, ["hp_cannot_drop_below_1", "cannot_die"]):
		damage = mini(damage, unit.current_hp - 1)
		damage = maxi(0, damage)

	unit.take_damage(damage)
	unit_damaged.emit(unit, damage, damage_type)
	# Data-driven passives that answer being hurt, and allies being hurt.
	if damage > 0:
		_fire_damage_triggers(unit, damage, damage_type, source)
	# Hit Back Harder (Might 3): taking damage sets a ready flag for +20% bonus on next melee attack
	if damage > 0 and unit.is_alive() and "hit_back_ready" in unit:
		var char_data = unit.character_data if "character_data" in unit else {}
		if PerkSystem.has_perk(char_data, "hit_back_harder"):
			unit.hit_back_ready = true

	# Taking damage breaks Pacified (dispel_methods includes "taking_damage")
	if damage > 0 and "status_effects" in unit:
		var to_remove: Array[int] = []
		for i in range(unit.status_effects.size()):
			var sname = unit.status_effects[i].get("status", "")
			var sdef = _status_effects.get(sname, {})
			if "taking_damage" in sdef.get("dispel_methods", []):
				to_remove.append(i)
		to_remove.reverse()
		var broken: Array = []
		for idx in to_remove:
			broken.append(unit.status_effects[idx])
		for entry in broken:
			var sname = entry.get("status", "")
			_end_status(unit, entry, "removed")
			if unit.has_method("show_status_expired"):
				unit.show_status_expired(sname)
			status_effect_expired.emit(unit, sname)

	# Glass_Globe: shatters on any damage, dealing slashing AoE + guaranteed Bleeding to nearby enemies.
	# Fires even on lethal hits (the globe shatters as the bearer falls).
	if damage > 0 and unit.has_status("Glass_Globe"):
		var globe_def = _status_effects.get("Glass_Globe", {})
		var shatter = globe_def.get("special", {}).get("shatters_on_damage_received", {})
		var shatter_dmg: int = shatter.get("damage", 20)
		var shatter_radius: int = shatter.get("radius", 2)
		# Remove the status first so the shatter itself can't re-trigger
		for i in range(unit.status_effects.size() - 1, -1, -1):
			if unit.status_effects[i].get("status", "") == "Glass_Globe":
				_end_status(unit, unit.status_effects[i], "consumed")
				if unit.has_method("show_status_expired"):
					unit.show_status_expired("Glass_Globe")
				status_effect_expired.emit(unit, "Glass_Globe")
				break
		combat_log.emit("%s's Glass Globe shatters! Razor shards fly outward!" % unit.unit_name)
		for nearby in _get_enemies_in_range(unit, shatter_radius):
			apply_damage(nearby, shatter_dmg, "slashing")
			_apply_status_effect(nearby, "Bleeding", 3, 0, null)

	# Crystal_Diadem: 50% chance (configurable) to shatter and be lost on any damage received.
	if damage > 0 and unit.has_status("Crystal_Diadem"):
		var diadem_def = _status_effects.get("Crystal_Diadem", {})
		var lose_chance: int = diadem_def.get("special", {}).get("chance_to_lose_on_damage_received", 50)
		if randi() % 100 < lose_chance:
			for i in range(unit.status_effects.size() - 1, -1, -1):
				if unit.status_effects[i].get("status", "") == "Crystal_Diadem":
					_end_status(unit, unit.status_effects[i], "consumed")
					if unit.has_method("show_status_expired"):
						unit.show_status_expired("Crystal_Diadem")
					status_effect_expired.emit(unit, "Crystal_Diadem")
					break
			combat_log.emit("%s's Crystal Diadem shatters!" % unit.unit_name)

	if unit.current_hp <= 0 and not unit.is_bleeding_out:
		_start_bleed_out(unit)
		# Check if combat should end immediately (all enemies or all players down)
		_check_immediate_combat_end()
	elif damage > 0 and unit.team == Team.ENEMY and "character_data" in unit \
			and int(unit.character_data.get("duel_stop_hp_pct", 0)) > 0:
		# A duelling boss (e.g. skeleton_king_duel) yields the moment it drops
		# to its stop threshold — not at the start of the next round, which is
		# the only other place _check_combat_end runs. Without this the rest of
		# the round plays out: the boss takes its own turn below 10% and the
		# party can simply kill it, so the "he stops it himself" ending never
		# happens.
		_check_immediate_combat_end()

	# Heavy hit: ≥15% of max HP breaks concentration
	# Uses post-absorption damage (what was actually received). This is intentional:
	# attacks reduced below 15% effective damage by armor do not disrupt mantras.
	if damage > 0 and unit.is_alive():
		var max_hp = unit.max_hp
		if max_hp > 0 and float(damage) / float(max_hp) >= 0.15:
			_interrupt_mantras(unit, "%s's concentration breaks from the heavy blow!" % unit.unit_name)


## Start bleed-out state for a unit
func _start_bleed_out(unit: Node) -> void:
	unit.is_bleeding_out = true
	unit.bleed_out_turns = BLEED_OUT_TURNS
	unit.current_hp = 0
	AudioManager.play("debuff_apply")
	unit_bleeding_out.emit(unit, BLEED_OUT_TURNS)


## Consume one Mirror_Images copy from the unit; the status expires when no copies remain.
## The copy count lives in the status entry's "value" field (0/unset → default 3 images).
func _consume_mirror_image(unit: Node) -> void:
	for effect in unit.status_effects:
		var def = _status_effects.get(effect.get("status", ""), {})
		if StatusRules.def_has_flag(def, "copies_absorb_attacks"):
			var copies: int = int(effect.get("value", 0))
			if copies <= 0:
				copies = 3
			copies -= 1
			effect["value"] = copies
			if copies <= 0:
				_remove_status_by_name(unit, effect.get("status", ""))
				combat_log.emit("%s's last mirror image shatters!" % unit.unit_name)
			return


## Permanently kill a unit
func _kill_unit(unit: Node) -> void:
	# Eternal_Vow: instead of dying, the unit is pulled back by their vow at 20% HP.
	# The vow is consumed. (Simplification of "returns next turn" — the return is immediate.)
	if StatusRules.has_flag(unit, "return_on_death_next_turn"):
		unit.is_bleeding_out = false
		unit.bleed_out_turns = 0
		unit.current_hp = maxi(1, int(unit.max_hp * 0.20))
		var vow_entry: Dictionary = StatusRules.entry_with_flag(unit, "return_on_death_next_turn")
		if not vow_entry.is_empty():
			_remove_status_by_name(unit, vow_entry.get("status", ""))
		combat_log.emit("%s's eternal vow refuses death — they rise again!" % unit.unit_name)
		unit_healed.emit(unit, unit.current_hp)
		_mark_death_touched(unit)
		return

	unit.is_dead = true
	unit.is_bleeding_out = false
	AudioManager.play("debuff_apply")

	# Grave soil and its relatives care where you fell.
	_zones_on_death(unit)

	# Witnessing a party member die affects all other player units emotionally
	if unit.team == Team.PLAYER:
		for other_unit in all_units:
			if other_unit == unit or other_unit.team != Team.PLAYER:
				continue
			if "character_data" in other_unit:
				PsychologySystem.apply_pressure(other_unit.character_data, "water", -15.0)

	unit_died.emit(unit)

	# Shadow Strike (Daggers 3 + Guile 3): killing an enemy enters stealth
	# Ambush Predator: kills from stealth immediately reset stealth (no gap)
	var killer = unit.get("last_attacker")
	if killer != null and not killer.is_dead:
		var killer_char_ss = killer.character_data if "character_data" in killer else {}
		var was_stealthed = "is_stealthed" in killer and killer.is_stealthed
		if PerkSystem.has_perk(killer_char_ss, "shadow_strike"):
			_enter_stealth(killer)
		elif was_stealthed and PerkSystem.has_perk(killer_char_ss, "ambush_predator"):
			_enter_stealth(killer)  # Reset stealth immediately (kill from stealth)
			combat_log.emit("%s remains in shadow (Ambush Predator)!" % killer.unit_name)

		# Gone Before the Body Falls (Daggers 9): dagger kill → restore 1 action
		if PerkSystem.has_perk(killer_char_ss, "gone_before_the_body_falls"):
			if killer.has_method("get_equipped_weapon") and killer.get_equipped_weapon().get("type", "") == "dagger":
				killer.actions_remaining = mini(killer.actions_remaining + 1, killer.max_actions)
				combat_log.emit("%s: Gone Before the Body Falls — free action!" % killer.unit_name)

	# Dharma Warrior (cross-skill): killing an enemy during mantra chanting advances each active mantra by +1
	if killer != null and not killer.is_dead and not killer.active_mantras.is_empty():
		var killer_char_dw = killer.character_data if "character_data" in killer else {}
		if PerkSystem.has_perk(killer_char_dw, "dharma_warrior"):
			for m_id in killer.active_mantras:
				killer.active_mantras[m_id] += 1
			combat_log.emit("%s: Dharma Warrior — kill advances mantra!" % killer.unit_name)

	# Risen Dead talisman perk: 15% chance the slain enemy rises as an allied undead
	if killer != null and not killer.is_dead and _unit_has_talisman_perk(killer, "risen_dead"):
		if randf() < 0.15 and combat_grid != null:
			# Build a simplified undead enemy def from the dead unit's data
			var risen_def: Dictionary = unit.character_data.duplicate(true)
			risen_def["name"] = "Risen " + unit.unit_name
			var risen_derived = risen_def.get("derived", {}).duplicate()
			risen_derived["max_hp"] = maxi(1, risen_derived.get("max_hp", 20) / 2)
			risen_derived["current_hp"] = risen_derived["max_hp"]
			risen_def["derived"] = risen_derived

			# Create a new CombatUnit for the risen undead, on the killer's team
			var risen = CombatUnit.new()
			risen.init_as_enemy(risen_def)
			risen.team = killer.team

			# Find a nearby unoccupied tile to place it
			var spawn_pos = Vector2i(-1, -1)
			var dead_pos = unit.grid_position
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var candidate = dead_pos + Vector2i(dx, dy)
					if combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
						spawn_pos = candidate
						break
				if spawn_pos != Vector2i(-1, -1):
					break

			if spawn_pos != Vector2i(-1, -1):
				combat_grid.place_unit(risen, spawn_pos)
				all_units.append(risen)
				# Insert into turn order right after current unit so it acts next round
				turn_order.append(risen)
				unit_deployed.emit(risen, spawn_pos)

	# Necromancer (Black 3 + Summoning 3): kill → spend 10 Mana to raise undead at 50% stats, max 2 per combat
	if killer != null and not killer.is_dead and killer.necromancer_raises < 2:
		var killer_char_nc = killer.character_data if "character_data" in killer else {}
		if PerkSystem.has_perk(killer_char_nc, "necromancer") and killer.current_mana >= 10 and combat_grid != null:
			killer.current_mana -= 10
			killer.necromancer_raises += 1
			var nc_def: Dictionary = unit.character_data.duplicate(true)
			nc_def["name"] = "Risen " + unit.unit_name
			var nc_derived = nc_def.get("derived", {}).duplicate()
			nc_derived["max_hp"] = maxi(1, nc_derived.get("max_hp", 20) / 2)
			nc_derived["current_hp"] = nc_derived["max_hp"]
			nc_derived["max_mana"] = 0
			nc_derived["current_mana"] = 0
			nc_def["derived"] = nc_derived
			# Strip spells so the risen just attacks
			nc_def["known_spells"] = []

			var nc_unit = CombatUnit.new()
			nc_unit.init_as_enemy(nc_def)
			nc_unit.team = killer.team

			var nc_pos = Vector2i(-1, -1)
			var nc_dead_pos = unit.grid_position
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var candidate = nc_dead_pos + Vector2i(dx, dy)
					if combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
						nc_pos = candidate
						break
				if nc_pos != Vector2i(-1, -1):
					break

			if nc_pos != Vector2i(-1, -1):
				combat_grid.place_unit(nc_unit, nc_pos)
				all_units.append(nc_unit)
				turn_order.append(nc_unit)
				unit_deployed.emit(nc_unit, nc_pos)
				combat_log.emit("%s raises %s! (%d/2 this combat)" % [killer.unit_name, nc_unit.unit_name, killer.necromancer_raises])

	# Cleave (Axes cross): kill → free attack on the nearest adjacent enemy
	_trigger_cleave(killer, unit.grid_position)

	# Lord of Death DY: 40% chance to raise a zombie/skeleton when an enemy dies near a registered caster
	var dead_pos = unit.grid_position
	for lod_caster in _lord_of_death_casters:
		if lod_caster == null or lod_caster.is_dead:
			continue
		# Only trigger if the dead unit was on the opposing team
		if "team" in unit and "team" in lod_caster and unit.team == lod_caster.team:
			continue
		if _grid_distance(dead_pos, lod_caster.grid_position) > 4:
			continue
		if randf() < 0.40:
			var undead_template = ["zombie", "skeleton"][randi() % 2]
			_spawn_summoned_unit(lod_caster, undead_template, dead_pos, 0)
			combat_log.emit("The Lord of Death claims %s's soul!" % unit.unit_name)
			break  # Only one resurrection per death event

	# Ancestral_Vengeance: when an ally dies, each other ally with this status gains a damage buff
	var dead_team = unit.team if "team" in unit else -1
	for av_unit in all_units:
		if av_unit == unit or av_unit.is_dead:
			continue
		if "team" in av_unit and av_unit.team == dead_team:
			if StatusRules.has_flag(av_unit, "attack_damage_buff_when_ally_dies"):
				_apply_status_effect(av_unit, "Rage", 2, 0, null)
				combat_log.emit("%s is filled with ancestral rage at the loss of %s!" % [av_unit.unit_name, unit.unit_name])

	# Remove from turn order and fix the current index
	var idx = turn_order.find(unit)
	if idx != -1:
		turn_order.remove_at(idx)
		# Use >= so that when the current unit dies, the index adjusts correctly:
		# after removal, the next unit slides into idx, and _advance_turn will
		# increment from (idx-1) back to idx, landing on the right unit.
		if current_unit_index >= idx:
			current_unit_index -= 1

	# Check if combat should end immediately
	_check_immediate_combat_end()


# ============================================
# ZONES
# ============================================

## Put a zone on the ground.
##
## The footprint comes from the casting spell's own `aoe` block, so every shape
## AoEResolver knows is available without zones naming any of them.
## Put two ends of a gate on the ground, linked to each other.
##
## Returns whether both went down. A gate with one end is a hole.
func place_gate(zone_id: String, here: Array, there: Array, source: Node,
		turns: int) -> bool:
	if not place_zone(zone_id, here, source, turns):
		return false
	var first: Dictionary = active_zones[-1]
	if not place_zone(zone_id, there, source, turns):
		active_zones.erase(first)
		return false
	var second: Dictionary = active_zones[-1]
	first["linked_to"] = second
	second["linked_to"] = first
	combat_log.emit("A door stands open.")
	return true


## The tiles a zone covers: the container's own `aoe` block, defaulting to a
## circle of size 2 on the target. `container` is a spell or a zone effect.
## Shared by cast_spell and EffectResolver so the default lives once.
func zone_footprint(container: Dictionary, caster: Node, target_pos: Vector2i) -> Array:
	var grid_sz := Vector2i(16, 10)
	if combat_grid:
		grid_sz = combat_grid.grid_size
	var footprint: Dictionary = container.get("aoe",
		{"type": "circle", "size": 2, "origin": "target"})
	return AoEResolver.get_tiles(footprint, caster.grid_position, target_pos, grid_sz)


## How many rounds a zone lasts: `duration` (a number, or "spellpower" for the
## cast's spellpower bonus), default 3, clamped to 2..12.
func zone_turns(container: Dictionary, spellpower_bonus: int) -> int:
	var turns: int = spellpower_bonus if str(container.get("duration", 0)) == "spellpower" \
		else int(container.get("duration", 3))
	return clampi(turns, 2, 12)


func place_zone(zone_id: String, tiles: Array, source: Node, turns: int) -> bool:
	var def: Dictionary = Zone.get_definition(zone_id)
	if def.is_empty():
		push_warning("CombatManager: no zone '%s'" % zone_id)
		return false
	if tiles.is_empty():
		return false

	var footprint: Dictionary = {}
	for tile in tiles:
		footprint[tile] = true

	var zone: Dictionary = {
		"id": zone_id,
		"name": def.get("name", zone_id),
		"def": def,
		"tiles": footprint,
		"source": source,
		"turns_left": turns,
		"entered": {},
	}
	active_zones.append(zone)
	combat_log.emit("%s settles over the ground." % zone.name)

	# Anyone already standing in it counts as having entered, so the circle
	# does not charge them for a line they never crossed.
	for unit in all_units:
		if is_instance_valid(unit) and "grid_position" in unit \
				and footprint.has(unit.grid_position):
			zone.entered[unit.get_instance_id()] = true
	return true


## Every zone covering this tile.
func zones_at(tile: Vector2i) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for zone in active_zones:
		if (zone.tiles as Dictionary).has(tile):
			found.append(zone)
	return found


## Advance every zone one round: fire `while_inside`, drift, expire.
##
## Called once per round rather than once per unit's turn, because a zone
## belongs to the ground and not to anybody's initiative. Only the effects
## that happen fire here; a `while_inside` modify is read where it applies
## (AuraSystem.contributions) and is skipped.
func _tick_zones() -> void:
	for i in range(active_zones.size() - 1, -1, -1):
		var zone: Dictionary = active_zones[i]

		var per_round: Array = []
		for e in zone.def.get("while_inside", []):
			if str(e.get("op", "")) != "modify":
				per_round.append(e)
		if not per_round.is_empty():
			for unit in all_units:
				if not is_instance_valid(unit) or unit.is_dead or not "grid_position" in unit:
					continue
				if not (zone.tiles as Dictionary).has(unit.grid_position):
					continue
				_run_zone_effects(zone, unit, per_round)

		if str(zone.def.get("drift", "")) == "random":
			_drift_zone(zone)

		zone.turns_left = int(zone.turns_left) - 1
		if zone.turns_left <= 0:
			combat_log.emit("%s disperses." % zone.name)
			active_zones.remove_at(i)


## Run `effects` of `zone` on `unit`, who is standing in it.
##
## Each effect reaches the unit only if Zone.effect_reaches says so (its `to`,
## or the zone's `affects`). They go through EffectResolver with the zone's
## owner as the caster and the unit's tile — a zone tile — as the position.
## Returns the resolver's log.
func _run_zone_effects(zone: Dictionary, unit: Node, effects: Array) -> Array[Dictionary]:
	var reaching: Array = []
	for e in effects:
		if Zone.effect_reaches(e, zone.def, zone.source, unit):
			reaching.append(e)
	var source: Node = zone.source if zone.source != null and is_instance_valid(zone.source) else null
	return _resolve_area_effects(source, unit, {"id": zone.id, "name": zone.name},
		reaching, 1.0, "zone")


## Fire `turn_start_inside` or `turn_end_inside` for every zone the unit is
## standing in, at the start or end of its own turn.
func _zones_turn_trigger(unit: Node, trigger: String) -> void:
	if not is_instance_valid(unit) or unit.is_dead or not "grid_position" in unit:
		return
	for zone in zones_at(unit.grid_position):
		var effects: Array = zone.def.get(trigger, [])
		if not effects.is_empty():
			_run_zone_effects(zone, unit, effects)


## Move a whole zone one tile in a random direction, keeping its shape.
func _drift_zone(zone: Dictionary) -> void:
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var step: Vector2i = dirs[randi() % dirs.size()]
	var moved: Dictionary = {}
	for tile in (zone.tiles as Dictionary):
		var to: Vector2i = tile + step
		if combat_grid == null or combat_grid.is_valid_position(to):
			moved[to] = true
	if moved.is_empty():
		return   # drifted off the field entirely; stay put rather than vanish
	zone.tiles = moved
	# Anyone the zone has moved off no longer counts as inside, so it may
	# charge them again if it wanders back over them.
	var still_in: Dictionary = {}
	for unit in all_units:
		if is_instance_valid(unit) and "grid_position" in unit \
				and moved.has(unit.grid_position):
			still_in[unit.get_instance_id()] = true
	zone.entered = still_in


## Fire `on_enter` for any zone this unit has just stepped into, and forget the
## ones it has left.
func _zones_check_entry(unit: Node) -> void:
	if not is_instance_valid(unit) or not "grid_position" in unit:
		return
	for zone in active_zones:
		var inside: bool = (zone.tiles as Dictionary).has(unit.grid_position)
		var was_inside: bool = (zone.entered as Dictionary).has(unit.get_instance_id())
		if inside and not was_inside:
			zone.entered[unit.get_instance_id()] = true
			# A trap is a thing you can spot. Thievery's `trap_detection_pct`
			# was written into derived stats and read by nothing, because until
			# Trap Maker there were no traps to detect.
			if bool(zone.def.get("trap", false)) and _steps_around_trap(unit):
				combat_log.emit("%s spots the trap and steps around it."
					% unit.unit_name)
				continue
			_run_zone_effects(zone, unit, zone.def.get("on_enter", []))
			# A gate puts you out of its other end. Marked as having entered
			# THAT end too, or the far side charges you for arriving.
			if str(zone.def.get("pair", "")) == "gate" and zone.has("linked_to"):
				_step_through_gate(unit, zone)
		elif was_inside and not inside:
			zone.entered.erase(unit.get_instance_id())


## Does this unit notice the trap in time?
##
## Their own skill, not the party's best: spotting a snare is something you do
## with your own eyes, and the table key is unprefixed for that reason.
func _steps_around_trap(unit: Node) -> bool:
	if not "character_data" in unit:
		return false
	var chance: float = float(unit.character_data.get("derived", {}).get(
		"trap_detection_pct", 0.0))
	if chance <= 0.0:
		return false
	return randf() < clampf(chance / 100.0, 0.0, 0.95)


## Move a unit from one end of a gate to the other.
func _step_through_gate(unit: Node, entrance: Dictionary) -> void:
	var exit_zone: Dictionary = entrance.linked_to
	if exit_zone == null or exit_zone.is_empty():
		return
	var landing := Vector2i(-1, -1)
	for tile in (exit_zone.tiles as Dictionary):
		if combat_grid == null or (combat_grid.is_valid_position(tile)
				and not combat_grid.is_occupied(tile)):
			landing = tile
			break
	if landing.x < 0:
		combat_log.emit("The far side of the door is blocked.")
		return
	if combat_grid != null:
		combat_grid.move_unit(unit, landing)
	else:
		unit.grid_position = landing
	exit_zone.entered[unit.get_instance_id()] = true
	unit_moved.emit(unit, entrance.tiles.keys()[0], landing)
	combat_log.emit("%s steps through the door." % unit.unit_name)


## Fire `on_death_inside` for whichever zone the unit died on.
##
## This is what Grave Soil is: nothing happens while you stand on it, and an
## enemy that falls there gets up again on your side. A trap rather than a
## hazard — its value is deciding where the fighting happens.
func _zones_on_death(unit: Node) -> void:
	if not is_instance_valid(unit) or not "grid_position" in unit:
		return
	for zone in active_zones:
		if not (zone.tiles as Dictionary).has(unit.grid_position):
			continue
		# A `summon from: corpse` stands its creature on the fallen unit's tile.
		for entry in _run_zone_effects(zone, unit, zone.def.get("on_death_inside", [])):
			if entry.op == "summon" and entry.applied:
				combat_log.emit("%s rises from the %s." % [unit.unit_name, str(zone.name).to_lower()])


## Raise the dead, at whatever tier the spell asked for.
##
##   "resurrection": {"tier": "revive", "hp_pct": 1}
##   "resurrection": {"tier": "revive", "hp_pct": 30, "scope": "all_allies"}
##
## See Resurrection for why stabilise, revive and raise are three acts rather
## than one.
func _apply_resurrection(caster: Node, target: Node, spec: Dictionary,
		result: Dictionary) -> void:
	var tier: String = spec.get("tier", "revive")
	if not Resurrection.is_tier(tier):
		push_warning("CombatManager: %s" % Resurrection.explain_unknown_tier(tier))
		return

	var scope: String = spec.get("scope", "single")
	var hp_pct: int = int(spec.get("hp_pct", 100))
	var candidates: Array = []
	if scope == "all_allies":
		# Everyone on the caster's side who is down, which is the whole point of
		# a 225-mana spell called Breath of Heaven.
		for unit in all_units:
			if is_instance_valid(unit) and "team" in unit and unit.team == caster.team:
				candidates.append(unit)
	else:
		candidates.append(target)

	var raised := 0
	for unit in candidates:
		var check: Dictionary = Resurrection.can_revive(unit)
		if not check.ok:
			if scope == "single":
				combat_log.emit(check.reason)
				result.effects_applied.append({"type": "no_effect", "reason": check.reason})
			continue
		var hp: int = Resurrection.hp_for(unit, hp_pct)
		unit.is_dead = false
		unit.is_bleeding_out = false
		unit.bleed_out_turns = 0
		unit.current_hp = hp
		if spec.get("cleanse", false):
			for entry in unit.status_effects.duplicate():
				_end_status(unit, entry, "cleansed")
		if unit.has_method("_update_visuals"):
			unit._update_visuals()
		unit_healed.emit(unit, hp)
		combat_log.emit("%s rises again with %d HP." % [unit.unit_name, hp])
		result.effects_applied.append({"type": "resurrect", "target": unit, "hp": hp})
		raised += 1

	if raised > 0 and scope == "all_allies":
		combat_log.emit("%s calls %d of the fallen back." % [caster.unit_name, raised])


## Revive a bleeding out unit
func revive_unit(unit: Node, hp_amount: int) -> void:
	if not unit.is_bleeding_out:
		return

	unit.is_bleeding_out = false
	unit.bleed_out_turns = 0
	unit.current_hp = hp_amount


# ============================================
# SPELL CASTING
# ============================================

## Every spell id in the database. Sweeps that must cover the whole spell list —
## verify_spells.tscn asserts no spell carries an unreadable `damage` — need to
## enumerate it rather than restate it.
func get_all_spell_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _spell_database:
		if not key.begins_with("_"):
			ids.append(key)
	return ids


## A unit's attribute as every combat roll and formula should read it: the
## EFFECTIVE value (base + gear + traits + holds - damage), from
## CharacterSystem.get_effective_attribute. 10 for a unit with no
## character_data, the same fallback the old raw reads used.
func unit_attribute(unit: Node, attr: String) -> int:
	if unit == null or not "character_data" in unit:
		return 10
	return CharacterSystem.get_effective_attribute(unit.character_data, attr)


## A unit's skill level as combat formulas should read it: the EFFECTIVE level
## (CharacterSystem.get_effective_skill_level), so a mid-fight skill hold
## counts. Counted from 0 upward, the same as the old raw reads: a negative
## level (a trait like Forgetful) reads as 0 here. Only the skills listed in
## CharacterSystem.NEGATIVE_SKILL_PENALTIES are penalised for going negative,
## and that happens in the derived stats, not here.
## 0 for a unit with no character_data.
func unit_skill(unit: Node, skill_id: String) -> int:
	if unit == null or not "character_data" in unit:
		return 0
	return maxi(0, CharacterSystem.get_effective_skill_level(unit.character_data, skill_id))


## Get a spell by ID (normalizes data format)
func get_spell(spell_id: String) -> Dictionary:
	if spell_id in _spell_database:
		var spell = _spell_database[spell_id].duplicate(true)
		spell["id"] = spell_id

		# Normalize targeting format: spell.target.type -> spell.targeting
		if not "targeting" in spell and "target" in spell:
			var target = spell.target
			var target_type = target.get("type", "single")
			var eligible = target.get("eligible", "enemy")

			# Any spell with an "aoe" block is an AoE spell, regardless of target.type
			if "aoe" in spell:
				spell["targeting"] = "aoe"
				var aoe: Dictionary = spell["aoe"].duplicate()
				# Normalize the primary size field (accept base_size / radius as aliases)
				if not "size" in aoe:
					if "base_size" in aoe and not (aoe.base_size is String):
						aoe["size"] = int(aoe.base_size)
					elif "radius" in aoe:
						aoe["size"] = int(aoe.radius)
					else:
						aoe["size"] = 2
				# "battlefield_width" string → -1 sentinel (resolved to grid.x at runtime)
				if str(aoe.get("size", "")) == "battlefield_width":
					aoe["size"] = -1
				# Ensure origin is set
				if not "origin" in aoe:
					if aoe.get("type") == "around_caster":
						aoe["origin"] = "caster"
					elif target.get("origin") == "caster" or target.get("centered_on") == "caster":
						aoe["origin"] = "caster"
					else:
						aoe["origin"] = "target"
				spell["aoe"] = aoe
				# Keep aoe_radius for backwards compat (ground effects + item code uses it)
				var sz: int = aoe.get("size", 2)
				spell["aoe_radius"] = sz if sz > 0 else 2
			else:
				# No aoe block: dispatch on target.type
				match target_type:
					"single":
						if eligible == "ally":
							spell["targeting"] = "single_ally"
						elif eligible == "corpse":
							spell["targeting"] = "single_corpse"
						else:
							spell["targeting"] = "single"
					"self":
						spell["targeting"] = "self"
					"aoe", "circle":
						# Legacy: no aoe block, treat as circle
						spell["targeting"] = "aoe"
						var r: int = target.get("radius", 2)
						spell["aoe"] = {"type": "circle", "size": r, "origin": "target"}
						spell["aoe_radius"] = r
					"chain":
						spell["targeting"] = "chain"
					"battlefield":
						# A third spelling of "the whole field", used by three
						# spells and resolved by nothing. `global` is the one
						# _get_spell_targets knows.
						spell["targeting"] = "global"
					_:
						spell["targeting"] = target_type

		# Default targeting if still missing
		if not "targeting" in spell:
			spell["targeting"] = "single"

		# Parse range from target data or default based on level
		var target_data = spell.get("target", {})
		var raw_range = target_data.get("range", spell.get("range", ""))
		if raw_range is String:
			if raw_range == "melee":
				spell["range"] = 1
			else:
				# Default range based on spell tier (level 1,3,5,7,9 → tier 1-5)
				var level = spell.get("level", 1)
				var tier = ceili(level / 2.0)  # 1→1, 2→1, 3→2, 4→2, 5→3, 7→4, 9→5
				spell["range"] = 3 + tier  # Range 4-8 based on tier
		elif raw_range is int or raw_range is float:
			spell["range"] = int(raw_range)
		else:
			var level = spell.get("level", 1)
			var tier = ceili(level / 2.0)
			spell["range"] = 3 + tier

		return spell
	return {}


## Get all spells a unit can cast (must know spell + meet requirements)
func get_castable_spells(unit: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# Effective levels: a temporary skill hold lets a unit cast above its
	# bought level (see CharacterSystem.meets_spell_skill).
	var skills: Dictionary = CharacterSystem.get_effective_skills(unit.character_data)
	var known_spells = unit.character_data.get("known_spells", [])

	# If no known_spells array, unit can't cast any spells
	if known_spells.is_empty():
		return result

	# Only check spells the unit knows
	for spell_id in known_spells:
		if not spell_id in _spell_database:
			continue
		var spell = _spell_database[spell_id]
		var can_cast = _can_cast_spell(unit, spell, skills)
		if can_cast.success:
			var spell_copy = spell.duplicate(true)
			spell_copy["id"] = spell_id
			result.append(spell_copy)

	return result


## Check if a unit can cast a specific spell
func _can_cast_spell(unit: Node, spell: Dictionary, skills: Dictionary) -> Dictionary:
	# Check mana (account for charm reduction if the unit has a matching one)
	var mana_cost = spell.get("mana_cost", 0)
	if unit.has_method("consume_charm") and not unit.charm_buff.is_empty():
		var buff_school = unit.charm_buff.get("school", "")
		var spell_schools = spell.get("schools", [])
		var subschool = spell.get("subschool", "")
		for school in spell_schools:
			if school.to_lower() == buff_school:
				mana_cost = int(mana_cost * (1.0 - unit.charm_buff.get("mana_reduction", 0.0)))
				break
		if subschool.to_lower() == buff_school:
			mana_cost = int(mana_cost * (1.0 - unit.charm_buff.get("mana_reduction", 0.0)))
	if unit.current_mana < mana_cost:
		return {"success": false, "reason": "Not enough mana"}

	# Check skill requirements - need at least one school at required skill level.
	# The spell's "level" field IS the minimum skill level required (1,2,3,4,5,7,9).
	if not CharacterSystem.meets_spell_skill({"skills": skills}, spell):
		return {"success": false, "reason": "Insufficient skill level"}

	return {"success": true}


## Cast a spell
func cast_spell(caster: Node, spell_id: String, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	# Silenced / blinded units cannot cast spells
	if not can_unit_cast(caster):
		return {"success": false, "reason": "Cannot cast while silenced"}

	# Sanctuary: block offensive spells; break Sanctuary if they try to cast offensively
	if StatusRules.has_flag(caster, "cannot_target_enemies"):
		var spell_check = get_spell(spell_id)
		var spell_targeting = spell_check.get("targeting", "single")
		# Self/ally spells are still allowed under Sanctuary
		if spell_targeting not in ["self", "ally", "allies"]:
			return {"success": false, "reason": "Sanctuary — cannot cast offensive spells"}

	# Sanctuary breaks when casting any offensive spell
	if StatusRules.has_flag(caster, "breaks_on_offensive_action"):
		var spell_break_check = get_spell(spell_id)
		if spell_break_check.get("targeting", "single") not in ["self", "ally", "allies"]:
			_remove_status_by_name(caster, "Sanctuary")
			combat_log.emit("%s's Sanctuary shatters as they cast offensively!" % caster.unit_name)

	# Stealth: spell casting breaks stealth unless invisible or Shady Dealings
	if "is_stealthed" in caster and caster.is_stealthed:
		var _is_inv: bool = StatusRules.has_flag(caster, "attack_breaks_invisibility")
		if _is_inv:
			# Invisible: casting consumes the Invisible status, stealth persists
			_remove_status_by_name(caster, "Invisible")
			combat_log.emit("%s's invisibility shatters from spellcasting — but remains hidden." % caster.unit_name)
		else:
			var caster_char_sd = caster.character_data if "character_data" in caster else {}
			if not PerkSystem.has_perk(caster_char_sd, "shady_dealings"):
				_leave_stealth(caster)
				combat_log.emit("%s breaks stealth by casting a spell!" % caster.unit_name)
			elif _shady_dealings_detected(caster):
				_leave_stealth(caster)
				combat_log.emit("An enemy detected %s casting despite Shady Dealings!" % caster.unit_name)
			else:
				combat_log.emit("%s casts from the shadows (Shady Dealings)." % caster.unit_name)

	var spell = get_spell(spell_id)
	if spell.is_empty():
		return {"success": false, "reason": "Unknown spell"}

	# Effective levels, the same map get_castable_spells builds.
	var skills: Dictionary = CharacterSystem.get_effective_skills(caster.character_data)
	var can_cast = _can_cast_spell(caster, spell, skills)
	if not can_cast.success:
		return can_cast

	# Check range
	var spell_range = spell.get("range", 1)
	var targeting = spell.get("targeting", "single")

	# Update caster facing toward target (non-self spells)
	if targeting != "self" and "facing" in caster and target_pos != caster.grid_position:
		caster.facing = _dir_toward(caster.grid_position, target_pos)

	# Self-targeting spells don't need range check
	if targeting != "self":
		var distance = spell_distance(caster.grid_position, target_pos)
		if distance > spell_range:
			return {"success": false, "reason": "Target out of range"}

	# Get targets based on targeting type
	var summon_id = spell.get("summon", "")
	var targets = _get_spell_targets(caster, spell, target_pos)
	# Ground-targeting (summoning) spells don't need a unit target — just a valid tile
	# AoE spells may legally fire into empty space (terrain effects still apply)
	if targets.is_empty() and targeting != "self" and targeting != "ground" and targeting != "aoe":
		return {"success": false, "reason": "No valid targets"}

	# Calculate base mana cost
	var mana_cost = spell.get("mana_cost", 0)

	# Check for charm buff (reduces mana cost and may boost spellpower)
	var charm_used: Dictionary = {}
	if caster.has_method("consume_charm"):
		var spell_schools = spell.get("schools", [])
		# Also check subschool
		var subschool = spell.get("subschool", "")
		if subschool != "":
			spell_schools = spell_schools + [subschool]
		charm_used = caster.consume_charm(spell_schools)
		if not charm_used.is_empty():
			var reduction = charm_used.get("mana_reduction", 0.0)
			mana_cost = int(mana_cost * (1.0 - reduction))

	# Perk-based mana cost reductions (multiplicative with charm reduction)
	var caster_char_perks = caster.character_data if "character_data" in caster else {}
	# Clean Cast (Sorcery 1): Sorcery spells cost 10% less mana
	if PerkSystem.has_perk(caster_char_perks, "clean_cast"):
		if spell.get("schools", []).any(func(s): return s.to_lower() == "sorcery"):
			mana_cost = int(mana_cost * 0.90)
	# Efficient Enchanting (Enchantment 1): Enchantment spells cost 10% less mana
	if PerkSystem.has_perk(caster_char_perks, "efficient_enchanting"):
		if spell.get("schools", []).any(func(s): return s.to_lower() == "enchantment"):
			mana_cost = int(mana_cost * 0.90)

	# Overcast bonus: push_the_words, burn_the_breath, one_perfect_sentence, grand_working
	# Consume the queued bonus and apply mana cost multiplier
	var _overcast: Dictionary = {}
	if "pending_overcast_bonus" in caster and not caster.pending_overcast_bonus.is_empty():
		_overcast = caster.pending_overcast_bonus
		caster.pending_overcast_bonus = {}
		var mana_mult = _overcast.get("mana_cost_multiplier", 1.0)
		mana_cost = int(mana_cost * mana_mult)
		combat_log.emit("%s casts with overcast power!" % caster.unit_name)

	# Damaru rhythm charge discount: at 3 charges → 40% off mana cost, then reset
	if "damaru_charges" in caster and caster.damaru_charges >= 3:
		mana_cost = int(mana_cost * 0.60)
		caster.damaru_charges = 0
		combat_log.emit("%s's Damaru rhythm peaks — spell costs 40%% less mana!" % caster.unit_name)

	# Ground that makes casting cheaper. `mana_cost_pct` is continuous — read
	# where it applies, like every other zone and aura stat — so an Inscribed
	# Circle discounts whoever is standing in it rather than whoever drew it.
	var ground_mana_pct: int = mana_cost_pct_of(caster)
	if ground_mana_pct != 0:
		mana_cost = maxi(1, int(mana_cost * (1.0 + float(ground_mana_pct) / 100.0)))

	# Skill-level mana cost reduction (see apply_skill_mana_reduction).
	mana_cost = apply_skill_mana_reduction(caster, spell, int(mana_cost))

	# Deduct mana (sync to character_data so it persists after combat)
	caster.current_mana -= mana_cost
	var caster_derived = caster.character_data.get("derived", {})
	caster_derived["current_mana"] = caster.current_mana

	# Overcast self-damage (burn_the_breath: caster takes damage equal to % of mana spent)
	if not _overcast.is_empty():
		var self_dmg_pct = _overcast.get("self_damage_pct_of_mana", 0)
		if self_dmg_pct > 0:
			var self_dmg = ceili(mana_cost * self_dmg_pct / 100.0)
			apply_damage(caster, self_dmg, "fire")
			combat_log.emit("%s burns from the overcast! (%d self-damage)" % [caster.unit_name, self_dmg])

	# Calculate spell power bonus from all applicable schools
	var spellpower_bonus = _calculate_spell_bonus(caster, spell)

	# Apply overcast spellpower multiplier
	if not _overcast.is_empty():
		var sp_pct = _overcast.get("spellpower_bonus_pct", 0)
		if sp_pct > 0:
			spellpower_bonus = int(spellpower_bonus * (1.0 + sp_pct / 100.0))

	# Spell Like a Knife (Sorcery 5): killing with Sorcery grants +50% Spellpower on next spell
	if "sorcery_kill_bonus_ready" in caster and caster.sorcery_kill_bonus_ready:
		spellpower_bonus = int(spellpower_bonus * 1.50)
		caster.sorcery_kill_bonus_ready = false

	# Add charm spellpower bonus (percentage of base spellpower)
	if not charm_used.is_empty():
		var charm_sp_pct = charm_used.get("spellpower_bonus", 0.0)
		if charm_sp_pct > 0:
			spellpower_bonus += int(spellpower_bonus * charm_sp_pct)

	# Terrain affinity: caster standing on matching elemental terrain gets +25% spellpower;
	# opposed terrain (blessed vs black, cursed vs white) gives -15%.
	if combat_grid != null:
		var caster_tile = combat_grid.tiles.get(caster.grid_position)
		if caster_tile != null and caster_tile.has_effect():
			var spell_schools_lower = spell.get("schools", []).map(func(s): return s.to_lower())
			var terrain_sp_pct := 0.0
			var terrain_label := ""
			match caster_tile.effect:
				CombatGrid.TerrainEffect.FIRE:
					if "fire" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "fire"
				CombatGrid.TerrainEffect.ICE, CombatGrid.TerrainEffect.WET:
					if "water" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "water"
				CombatGrid.TerrainEffect.STORMY:
					if "air" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "air"
				CombatGrid.TerrainEffect.POISON, CombatGrid.TerrainEffect.ACID:
					if "earth" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "earth"
				CombatGrid.TerrainEffect.VOID:
					if "space" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "void"
				CombatGrid.TerrainEffect.BLESSED:
					if "white" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "blessed"
					elif "black" in spell_schools_lower:
						terrain_sp_pct = -0.15
						terrain_label = "blessed (opposed)"
				CombatGrid.TerrainEffect.CURSED:
					if "black" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "cursed"
					elif "white" in spell_schools_lower:
						terrain_sp_pct = -0.15
						terrain_label = "cursed (opposed)"
			if terrain_sp_pct != 0.0:
				var delta = int(spellpower_bonus * terrain_sp_pct)
				spellpower_bonus += delta
				if delta > 0:
					combat_log.emit("%s draws power from the %s terrain! (+%d spellpower)" % [caster.unit_name, terrain_label, delta])
				else:
					combat_log.emit("%s is weakened by the %s terrain! (%d spellpower)" % [caster.unit_name, terrain_label, delta])

	# Summoning terrain affinity: the spirits native to this ground answer more
	# readily. +25% spellpower for Summoning spells whose element matches the
	# overworld terrain the battle is being fought on.
	# The rule itself lives in summon_terrain_affinity_for(), which the spell
	# tooltip also reads, so the player sees the bonus before casting.
	var summon_affinity: Dictionary = summon_terrain_affinity_for(spell, battlefield_overworld_terrain)
	if not summon_affinity.is_empty():
		var summon_delta := int(spellpower_bonus * SUMMON_TERRAIN_BONUS_PCT)
		spellpower_bonus += summon_delta
		combat_log.emit("The spirits of %s answer %s readily! (+%d spellpower)" % [
			summon_affinity.get("label", "this place"), caster.unit_name, summon_delta])

	# Lunar & weekday spellpower bonuses
	var calendar_schools: Array = spell.get("schools", []).map(func(s: String): return s.to_lower())

	# Full moon → White +20%; new moon → Black +20%
	if GameState.is_full_moon() and "white" in calendar_schools:
		var delta := int(spellpower_bonus * 0.20)
		spellpower_bonus += delta
		combat_log.emit("%s is empowered by the full moon! (+%d spellpower)" % [caster.unit_name, delta])
	elif GameState.is_new_moon() and "black" in calendar_schools:
		var delta := int(spellpower_bonus * 0.20)
		spellpower_bonus += delta
		combat_log.emit("%s draws power from the new moon's darkness! (+%d spellpower)" % [caster.unit_name, delta])

	# Weekday school bonus: each day of the week favours one magic school (+20%)
	# Sun=Fire, Mon=Water, Tue=Sorcery, Wed=Space, Thu=Air, Fri=Enchantment, Sat=Earth
	var weekday_school := GameState.get_weekday_school()
	if weekday_school in calendar_schools:
		var delta := int(spellpower_bonus * 0.20)
		spellpower_bonus += delta
		combat_log.emit("%s, %s magic — +%d spellpower" % [GameState.get_weekday_name(), weekday_school.capitalize(), delta])

	# --- Summoning spells: spawn a unit instead of applying effects to targets ---
	if summon_id != "" and targeting == "ground":
		use_action(1)
		var summon_result = _spawn_summoned_unit(caster, summon_id, target_pos, spellpower_bonus)
		spell_cast.emit(caster, spell, [], [summon_result])
		return {"success": true, "spell": spell, "targets": [], "results": [summon_result], "mana_cost": mana_cost}

	# --- Zones: an area left standing on the ground ---
	#
	# The footprint is the spell's own `aoe` block, so a zone inherits every
	# shape AoEResolver knows without zones having to name any of them.
	#
	# A spell may both hit and leave something behind: Rain of Mud's torrent
	# blinds or slows whoever fails a Finesse save, and THEN the ground stays
	# mud. So the zone is laid down here but the cast only returns from here
	# when there is nobody to resolve it against — returning unconditionally
	# dropped the save gate of every spell that does both, which is the same
	# shape as any other effect declared in data and read by nothing.
	var zone_left: Dictionary = {}
	if spell.has("zone"):
		var zone_id: String = str(spell["zone"])
		var tiles: Array = zone_footprint(spell, caster, target_pos)
		var turns: int = zone_turns(spell, spellpower_bonus)
		if not place_zone(zone_id, tiles, caster, turns):
			return {"success": false, "reason": "The ground will not hold it"}
		zone_left = {"type": "zone", "zone": zone_id, "tiles": tiles.size()}
		if targets.is_empty():
			use_action(1)
			var zone_results: Array = [{"target": caster, "effects_applied": [zone_left]}]
			spell_cast.emit(caster, spell, [], zone_results)
			_process_spell_cast_perks(caster, null, spell, zone_results[0])
			return {"success": true, "spell": spell, "targets": [],
				"results": zone_results, "mana_cost": mana_cost}

	# --- Repositioning the caster: Blink, Jump, Get Out, Teleport ---
	#
	# These aim at a tile rather than a unit, so they never reach the per-target
	# path where the rest of a spell resolves. Each one had its own unread
	# `special` key — teleport_self, blink_out_of_melee, ignores_terrain — and
	# each is the same mechanic with a different range.
	if spell.has("reposition") and bool(spell["reposition"].get("self", false)):
		var self_spec: Dictionary = spell["reposition"]
		var move_result: Dictionary = reposition(caster, self_spec, caster, target_pos)
		if not move_result.get("ok", false):
			return {"success": false, "reason": move_result.get("reason", "cannot move there")}
		use_action(1)   # mana was already deducted above, with every other spell
		combat_log.emit("%s steps through space." % caster.unit_name)
		var move_results: Array = [{"target": caster, "effects_applied": [
			{"type": "reposition", "mode": self_spec.get("mode", "teleport")}]}]
		spell_cast.emit(caster, spell, [caster], move_results)
		return {"success": true, "spell": spell, "targets": [caster],
			"results": move_results, "mana_cost": mana_cost}

	# --- Illusion spells: spawn a decoy unit that draws enemy attacks ---
	if targeting == "ground" and spell.get("special", {}).get("creates_illusion", false):
		use_action(1)
		var duration = spellpower_bonus if spell.get("duration", 0) == "spellpower" else int(spell.get("duration", 3))
		if duration <= 0:
			duration = 3
		var illusion_hp = maxi(5, spellpower_bonus * 2)
		var illusion_data: Dictionary = {
			"name": "Decoy",
			"archetype_name": "Illusion",
			"max_hp": illusion_hp,
			"max_mana": 0,
			"actions": 0,  # Illusions can't act
			"inventory": [],
			"skills": {},
			"known_spells": [],
			"perks": [],
			"tags": ["illusion", "decoy"],
			"derived": {
				"max_hp": illusion_hp, "current_hp": illusion_hp,
				"max_mana": 0, "current_mana": 0,
				"max_stamina": 10, "current_stamina": 10,
				"initiative": 0, "movement": 0,
				"dodge": 0, "armor": 0, "crit_chance": 0.0,
				"accuracy": 0, "damage": 0, "damage_type": "none",
				"resistances": {},
			},
			"equipped_weapon": {"name": "None", "damage": 0, "damage_type": "none", "range": 1}
		}
		var decoy_unit = CombatUnit.new()
		decoy_unit.summoner_id = caster.get_instance_id()
		decoy_unit.init_as_enemy(illusion_data)
		decoy_unit.team = caster.team
		# Find a valid spawn position
		var spawn_pos = Vector2i(-1, -1)
		if combat_grid != null and not combat_grid.is_occupied(target_pos) and combat_grid.is_valid_position(target_pos):
			spawn_pos = target_pos
		else:
			for radius in range(1, 4):
				for dx in range(-radius, radius + 1):
					for dy in range(-radius, radius + 1):
						if abs(dx) != radius and abs(dy) != radius:
							continue
						var candidate = target_pos + Vector2i(dx, dy)
						if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
							spawn_pos = candidate
							break
					if spawn_pos != Vector2i(-1, -1):
						break
				if spawn_pos != Vector2i(-1, -1):
					break
		if spawn_pos == Vector2i(-1, -1):
			return {"success": false, "reason": "No space for decoy", "mana_cost": 0}
		combat_grid.place_unit(decoy_unit, spawn_pos)
		all_units.append(decoy_unit)
		turn_order.append(decoy_unit)
		unit_deployed.emit(decoy_unit, spawn_pos)
		combat_log.emit("%s creates a Decoy — %d HP, lasts %d turns!" % [caster.unit_name, illusion_hp, duration])
		var illusion_result = {"success": true, "type": "illusion", "unit": decoy_unit, "position": spawn_pos, "duration": duration}
		spell_cast.emit(caster, spell, [], [illusion_result])
		_process_spell_cast_perks(caster, null, spell, illusion_result)
		return {"success": true, "spell": spell, "targets": [], "results": [illusion_result], "mana_cost": mana_cost}

	# --- Ground-effect spells: place terrain effects at target location ---
	# e.g. smoke_cloud — blocks_line_of_sight in spell.special means SMOKE terrain
	if targeting == "ground" and spell.get("special", {}).get("blocks_line_of_sight", false):
		use_action(1)
		var aoe_radius = spell.get("aoe", {}).get("base_size", 1)
		var duration = spellpower_bonus if spell.get("duration", 0) == "spellpower" else int(spell.get("duration", 3))
		if duration <= 0:
			duration = 3
		var tiles_in_area = combat_grid.get_tiles_in_radius(target_pos, aoe_radius)
		for pos in tiles_in_area:
			var tile = combat_grid.tiles.get(pos)
			if tile != null and tile.walkable:
				combat_grid.add_terrain_effect(pos, CombatGrid.TerrainEffect.SMOKE, duration)
		combat_log.emit("%s casts Smoke Cloud — sight blocked for %d turns!" % [caster.unit_name, duration])
		var ground_result = {"effect": "smoke", "tiles_affected": tiles_in_area.size(), "duration": duration}
		spell_cast.emit(caster, spell, [], [ground_result])
		_process_spell_cast_perks(caster, null, spell, ground_result)
		return {"success": true, "spell": spell, "targets": [], "results": [ground_result], "mana_cost": mana_cost}

	# Apply effects to each target
	#
	# Too Fast to React, if it is queued: held across every target of this one
	# cast and dropped afterwards, so a spell that hits five people ignores
	# resistance on all five and the next spell is ordinary again.
	_ignoring_resistance = bool(caster.get_meta("ignore_resistances_next", false))
	if _ignoring_resistance:
		caster.set_meta("ignore_resistances_next", false)
		combat_log.emit("%s's spell answers to nothing." % caster.unit_name)

	var results: Array[Dictionary] = []
	var is_offensive = _spell_is_offensive(spell)
	for target in targets:
		# Talisman: Magic Mirror — 10% chance to reflect hostile spells back at caster
		if is_offensive and target != caster and _unit_has_talisman_perk(target, "magic_mirror"):
			if randf() < 0.10:
				# Reflect! Apply spell to caster instead
				var reflect_result = _apply_spell_effects(caster, caster, spell, spellpower_bonus)
				reflect_result["reflected"] = true
				results.append(reflect_result)
				if target.has_method("show_combat_text"):
					target.show_combat_text("Reflected!", Color(0.6, 0.3, 1.0))
				continue

		var effect_result = _apply_spell_effects(caster, target, spell, spellpower_bonus)
		results.append(effect_result)

	# Create ground effects for AoE spells that deal elemental damage
	if targeting == "aoe":
		var spell_damage_type = spell.get("damage_type", "")
		if spell_damage_type != "":
			var aoe_radius = spell.get("aoe_radius", 1)
			_create_ground_effects_from_damage(target_pos, aoe_radius, spell_damage_type, 2)

	_ignoring_resistance = false

	# The ground the spell left behind, reported next to what it did to people.
	if not zone_left.is_empty():
		results.append({"target": caster, "effects_applied": [zone_left]})

	# Use action
	use_action(1)

	var cast_result = {
		"success": true,
		"spell": spell,
		"targets": targets,
		"results": results,
		"mana_cost": mana_cost
	}

	spell_cast.emit(caster, spell, targets, results)
	return cast_result


## Get targets for a spell based on targeting type
func _get_spell_targets(caster: Node, spell: Dictionary, target_pos: Vector2i) -> Array[Node]:
	var targets: Array[Node] = []
	var targeting = spell.get("targeting", "single")

	match targeting:
		"self":
			targets.append(caster)

		"single", "single_ally":
			var unit = get_unit_at(target_pos)
			if unit:
				if targeting == "single_ally":
					if unit.team == caster.team:
						targets.append(unit)
				else:
					targets.append(unit)

		"single_corpse":
			# Revive spells. This filtered on is_bleeding_out alone, so the only
			# people a resurrection could reach were the ones not yet dead —
			# the same shape as single_ally filtering on is_alive() and missing
			# the person the spell exists for.
			var unit = get_unit_at(target_pos)
			if unit and (unit.is_bleeding_out or unit.is_dead):
				targets.append(unit)

		"global":
			# The whole field, filtered by who the spell is for. Four spells
			# declared `target: global` and got no targets at all, because
			# nothing here matched the word.
			var eligible: String = spell.get("target", {}).get("eligible", "enemy")
			for unit in all_units:
				if not is_instance_valid(unit):
					continue
				var same_team: bool = "team" in unit and unit.team == caster.team
				match eligible:
					"all":
						targets.append(unit)
					"others":
						# Everyone except the caster, both sides. Time stops for
						# the whole field and the person who stopped it keeps
						# moving; the sound hits everyone and the one making it
						# feels nothing.
						if unit != caster:
							targets.append(unit)
					"ally", "dead_ally":
						if same_team:
							targets.append(unit)
					_:
						if not same_team:
							targets.append(unit)

		"aoe":
			var aoe_def: Dictionary = spell.get("aoe", {"type": "circle", "size": 2, "origin": "target"})
			var grid_sz = Vector2i(16, 10)
			if combat_grid:
				grid_sz = combat_grid.grid_size
			# cone_forward: direction is locked to the caster's facing, not the aim tile
			var effective_target := target_pos
			if aoe_def.get("type", "") == "cone_forward" and "facing" in caster:
				effective_target = caster.grid_position + caster.facing
			var aoe_tiles = AoEResolver.get_tiles(aoe_def, caster.grid_position, effective_target, grid_sz)
			# WHO an area spell catches comes from the spell's own
			# `target.eligible`, the same word the single-target branch reads.
			# It used to come from _spell_is_offensive(), which looked for a
			# `spell.effects` array — a key no spell in the database has. So it
			# answered false for all 57 area spells, and every one of them
			# selected the CASTER'S OWN TEAM: Meteor Shower fell on your party
			# and spared the enemy standing in it.
			var eligible: String = str(spell.get("target", {}).get("eligible", "enemy"))
			for unit in all_units:
				if not unit.is_alive() and not unit.is_bleeding_out:
					continue
				if not unit.grid_position in aoe_tiles:
					continue
				if _eligible_reaches(eligible, caster, unit):
					targets.append(unit)

		"all_enemies":
			for unit in all_units:
				if unit.is_alive() and unit.team != caster.team:
					targets.append(unit)

		"all_allies":
			for unit in all_units:
				if unit.is_alive() and unit.team == caster.team and unit != caster:
					targets.append(unit)

		"chain":
			# Start with primary target, chain to nearby enemies
			var primary = get_unit_at(target_pos)
			if primary and primary.team != caster.team:
				targets.append(primary)
				var chain_count = spell.get("chain_targets", 3) - 1
				var hit_positions: Array[Vector2i] = [target_pos]

				while chain_count > 0 and targets.size() < spell.get("chain_targets", 3):
					var last_target = targets[-1]
					var nearest: Node = null
					var nearest_dist = 999

					for unit in all_units:
						if not unit.is_alive():
							continue
						if unit.team == caster.team:
							continue
						if unit.grid_position in hit_positions:
							continue
						var dist = _grid_distance(last_target.grid_position, unit.grid_position)
						if dist <= 3 and dist < nearest_dist:  # Chain range of 3
							nearest_dist = dist
							nearest = unit

					if nearest:
						targets.append(nearest)
						hit_positions.append(nearest.grid_position)
					else:
						break
					chain_count -= 1

	return targets


## Check if spell is offensive (deals damage)
func _spell_is_offensive(spell: Dictionary) -> bool:
	# What the spell says about who it is for, first. `eligible` is a closed
	# word list the database already uses everywhere and the targeting
	# normaliser already reads.
	var eligible: String = str(spell.get("target", {}).get("eligible", ""))
	if eligible != "":
		if "enemy" in eligible:
			return true
		if eligible in ["ally", "ally_or_self", "self", "corpse", "dead_ally",
				"others", "party"]:
			return false

	# Otherwise from what it does. This function read `spell.effects` for
	# months — an array no spell in the database carries — so it returned false
	# for every spell ever cast, including Fireball.
	var dmg = spell.get("damage", null)
	if (dmg is int or dmg is float) and float(dmg) > 0.0:
		return true
	if dmg is Dictionary or dmg is String:
		return true
	if spell.has("on_failed_save") or spell.has("statuses_caused_on_failed_save"):
		return true
	for tag in spell.get("tags", []):
		if str(tag) in ["damage", "debuff", "cc"]:
			return true
	return false


## Does a spell whose targets are `eligible` reach `unit`, cast by `caster`?
##
## One reading of the word for every targeting branch that needs it, rather
## than a team comparison written out at each site.
func _eligible_reaches(eligible: String, caster: Node, unit: Node) -> bool:
	var same_team: bool = "team" in unit and "team" in caster and unit.team == caster.team
	match eligible:
		"ally", "ally_or_self", "party", "dead_ally":
			return same_team
		"self":
			return unit == caster
		"others":
			return unit != caster
		"all", "any":
			return true
		"undead_enemy":
			return not same_team and "undead" in unit.character_data.get("tags", [])
		"living_enemy":
			return not same_team and not ("undead" in unit.character_data.get("tags", []))
	return not same_team   # "enemy", and the default


## Skill-level mana cost reduction, applied to `mana_cost` and returned.
## It applies only when at least one of the spell's schools matches a magic
## skill the caster has (school-specific efficiency): bought, or held only for
## this fight. The reduction is flat (e.g. space_magic 5 → -75) and never takes
## the cost below 10% of the spell's base cost.
func apply_skill_mana_reduction(caster: Node, spell: Dictionary, mana_cost: int) -> int:
	var skill_mana_reduction: int = caster.character_data.get("derived", {}).get("mana_cost_reduction", 0)
	if skill_mana_reduction < 0:
		var spell_schools_lower: Array = spell.get("schools", []).map(func(s): return s.to_lower())
		# Every skill the caster has at an effective level, bonus-only ones
		# included, so a +5 hold on a school never bought still counts.
		var caster_skills: Dictionary = CharacterSystem.get_effective_skills(caster.character_data)
		const MAGIC_SKILL_TO_SCHOOL = {
			"space_magic": "space", "air_magic": "air", "fire_magic": "fire",
			"water_magic": "water", "earth_magic": "earth", "sorcery": "sorcery",
			"enchantment": "enchantment", "white_magic": "white", "black_magic": "black",
			"summoning": "summoning", "ritual": "ritual"
		}
		var school_matches := false
		for sk in caster_skills:
			if MAGIC_SKILL_TO_SCHOOL.has(sk) and MAGIC_SKILL_TO_SCHOOL[sk] in spell_schools_lower:
				school_matches = true
				break
		if school_matches:
			var base_cost: int = spell.get("mana_cost", 0)
			var max_reduction: int = int(base_cost * 0.90)
			mana_cost = max(int(base_cost * 0.10), mana_cost + skill_mana_reduction)
			mana_cost = max(mana_cost, int(spell.get("mana_cost", 0)) - max_reduction)
	return mana_cost


## Calculate total spell bonus from all applicable schools
func _calculate_spell_bonus(caster: Node, spell: Dictionary) -> int:
	var total_bonus = caster.get_spellpower()
	var schools = spell.get("schools", [])

	for school in schools:
		# Lowercase school name for comparison (spells.json uses capitalized names)
		var school_lower = school.to_lower()
		var skill_name = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space", "white", "black"] else school_lower
		# Effective level, so a skill hold raises spell power mid-fight.
		var skill_level: int = unit_skill(caster, skill_name)
		total_bonus += skill_level * 2  # Each skill level adds 2 to spell power

	return total_bonus


## Unified status effect duration calculation.
## Base 2 turns + Enchantment skill (main modifier, +1 per 2 levels) + Spellpower (secondary, +1 per 15 points).
## Enchantment is the primary scaling axis: a dedicated enchanter doubles the duration
## that raw spellpower alone would produce.
##
## Fixed integer durations in spells.json are intentional balance decisions and pass through
## unchanged (e.g. Blessed Shot = 1 turn, Searing Orb terrain = 4 turns).
## "combat": used by spells that last until combat ends (returns 999; status definition
## or special handler owns the real cleanup logic).
## Other special strings ("permanent", "until_save", "until_destroyed") return 3 as a safe
## fallback — those spells rely on their status definition's duration_type for actual expiry.
func _calculate_status_duration(caster: Node, spell: Dictionary, bonus: int) -> int:
	var dur_field = spell.get("duration", null)

	# Numeric: hard-coded duration — intentional balance decision, pass through unchanged
	if dur_field is int or dur_field is float:
		return int(dur_field)

	# "combat": lasts the entire combat encounter
	if dur_field == "combat":
		return 999

	# "spellpower" or legacy "spellpower_turns" (or absent): unified scaling formula.
	# Enchantment is the main modifier; spellpower contributes less to keep dedicated
	# enchanters clearly ahead of raw-power builds.
	if dur_field == "spellpower" or dur_field == "spellpower_turns" or dur_field == null:
		# Enchantment's contribution comes from its per-level table
		# (effect_duration_turns), not from a rule restated here. It used to be
		# `int(level / 2)` in this function while the table carried a parallel
		# effect_duration_pct that nothing read — two statements of one mechanic,
		# one of them dead. The table now holds the same numbers it always
		# produced, in a place they can be tuned.
		var enc_contribution: int = 0
		if "character_data" in caster:
			enc_contribution = int(caster.character_data.get("derived", {}).get(
				"effect_duration_turns", 0))
		# Spellpower: +1 turn per 15 points (secondary — typical SP 10–30 adds +0 to +2)
		var sp_contribution: int = int(bonus / 15)
		return maxi(1, 2 + enc_contribution + sp_contribution)

	# Other special strings ("permanent", "until_save", "until_destroyed"):
	# the status definition's duration_type field handles the real logic; return safe fallback
	return 3


## Apply spell effects to a target
## Reads directly from spells.json format: damage, damage_type, heal, statuses_caused
func _apply_spell_effects(caster: Node, target: Node, spell: Dictionary, bonus: int) -> Dictionary:
	# `incoming_spell` triggers answer an offensive spell before it lands.
	# Magic_Mirror's (50%) reflects it back at the caster; target == caster
	# afterwards, so a mirrored caster can't bounce it again.
	if target != caster and _spell_is_offensive(spell):
		var seen: Dictionary = _intercept(target, caster, "incoming_spell", false, [])
		if seen.reflect:
			combat_log.emit("%s's magic mirror hurls the spell back at %s!" % [target.unit_name, caster.unit_name])
			return _apply_spell_effects(caster, caster, spell, bonus)

	var result = {
		"target": target,
		"effects_applied": []
	}

	# --- Direct damage (from spell.damage and spell.damage_type) ---
	#
	# `damage` is usually a number and sometimes a formula block — an execute
	# measured against the target's own health, a nuke that scales off the
	# caster, a detonation that spends a damage-over-time. SpellDamage owns that
	# vocabulary. The guard that used to sit here tested `is int or is float`
	# and silently dropped every formula, which is how seven spells (two of them
	# 225-mana capstones) came to deal nothing at all.
	#
	# A spell may also require a status on its target to work at all; without it
	# there is no damage to compute.
	var required_status: String = spell.get("requires_status", "")
	if required_status != "" and not target.has_status(required_status):
		result.effects_applied.append({"type": "no_effect", "reason": "requires " + required_status})
		return result

	var base_damage: int = SpellDamage.resolve(spell, caster, target)
	if base_damage > 0:
		var element = spell.get("damage_type", "physical")
		var total_damage = int(base_damage) + bonus

		# Chains of Suffering: +15% Black spell damage vs targets with any debuff
		var caster_char = caster.character_data if "character_data" in caster else {}
		if element == "black" and PerkSystem.has_perk(caster_char, "chains_of_suffering"):
			if target.status_effects.size() > 0:
				total_damage = int(total_damage * 1.15)

		# Elementalist: +25% damage when targeting an elemental weakness (negative resistance)
		if PerkSystem.has_perk(caster_char, "elementalist"):
			if target.get_resistance(element) < 0:
				total_damage = int(total_damage * 1.25)

		# Variance ±15%
		var variance = randf_range(0.85, 1.15)
		total_damage = int(total_damage * variance)

		# Magic_Shield / Golden_Defense: 25% spell damage reduction
		if StatusRules.has_flag(target, "spell_damage_reduction"):
			total_damage = int(total_damage * 0.75)

		# Lord of Death DY: empowered summons deal 30% bonus spell damage
		if "lord_of_death_empowered" in caster and caster.lord_of_death_empowered:
			total_damage = int(total_damage * 1.3)

		apply_damage(target, total_damage, element, caster)
		result.effects_applied.append({"type": "damage", "amount": total_damage, "element": element})

		# A status_stacks formula is paid for with the status it counted.
		var spent: String = SpellDamage.consumes_status(spell)
		if spent != "":
			_remove_status_by_name(target, spent)

	# --- Forced movement (from spell.push and spell.scatter) ---
	#
	# Fifteen spells had their whole identity written into unread `special`
	# keys. Surge is the clearest: a level 1 Water spell dealing 5 damage, whose
	# point is that it shoves someone into a wall for 10 more. The water ladder
	# — surge, wave, ripple, tsunami — escalates exactly that idea, and none of
	# it reached the field.
	if spell.has("push") and target.is_alive():
		var push_result: Dictionary = _apply_push(caster, target, spell["push"])
		var slam: int = push_result.get("blocked_damage", 0)
		if slam > 0:
			var slam_type: String = spell.get("damage_type", "physical")
			apply_damage(target, slam, slam_type)
			combat_log.emit("%s is slammed into an obstacle!" % target.unit_name)
			result.effects_applied.append({"type": "damage", "amount": slam,
				"element": slam_type, "cause": "blocked_push"})
		result.effects_applied.append({"type": "push",
			"moved": push_result.get("moved", 0), "lost": push_result.get("lost", 0)})

	# Repositioning aimed at the TARGET: Behind You, Burrow, Space Swap. The
	# caster is the one who moves in the first two, so `mover` says who.
	if spell.has("reposition") and not bool(spell["reposition"].get("self", false)):
		var spec: Dictionary = spell["reposition"]
		var mover: Node = caster if spec.get("mover", "caster") == "caster" else target
		var move_result: Dictionary = reposition(mover, spec, caster, target.grid_position)
		result.effects_applied.append({"type": "reposition",
			"mode": spec.get("mode", "push"), "ok": move_result.get("ok", false),
			"reason": move_result.get("reason", "")})

	if spell.has("scatter") and target.is_alive():
		var scatter_spec := {"mode": "scatter", "range": int(spell["scatter"].get("range", 2))}
		if reposition(target, scatter_spec, caster, target.grid_position).get("ok", false):
			result.effects_applied.append({"type": "scatter",
				"range": scatter_spec["range"]})

	# --- Direct healing (from spell.heal) ---
	var base_heal = spell.get("heal", null)
	if base_heal != null and (base_heal is int or base_heal is float):
		if int(base_heal) > 0:
			var total_heal = int(base_heal) + int(bonus * 0.5)
			# Healing Waters (Water 1): Water healing spells are 15% more effective
			var caster_char_hw = caster.character_data if "character_data" in caster else {}
			var is_water_heal = spell.get("schools", []).any(func(s): return s.to_lower() == "water")
			if is_water_heal and PerkSystem.has_perk(caster_char_hw, "healing_waters"):
				total_heal = int(total_heal * 1.15)
			target.heal(total_heal)
			unit_healed.emit(target, total_heal)
			result.effects_applied.append({"type": "heal", "amount": total_heal})
			# Karmic_Bond: healing one bonded unit flows to the other(s) at 75%
			if StatusRules.has_flag(target, "share_healing_75_percent"):
				var shared_heal: int = int(total_heal * 0.75)
				if shared_heal > 0:
					for other in all_units:
						if other == target or not other.is_alive():
							continue
						if StatusRules.has_flag(other, "share_healing_75_percent"):
							other.heal(shared_heal)
							unit_healed.emit(other, shared_heal)
							combat_log.emit("The karmic bond carries %d healing to %s." % [shared_heal, other.unit_name])
			# Lingering Warmth (White 3): healing spells also apply regeneration (15% of heal over 3 turns)
			var is_white_heal = spell.get("schools", []).any(func(s): return s.to_lower() == "white")
			if is_white_heal and PerkSystem.has_perk(caster_char_hw, "lingering_warmth"):
				var regen_per_turn = maxi(1, int(total_heal * 0.15 / 3))
				_apply_status_effect(target, "Regenerating", 3, regen_per_turn, caster)
			# Purifying Stream (Water 2): Water healing spells also remove 1 negative status effect
			if is_water_heal and PerkSystem.has_perk(caster_char_hw, "purifying_stream"):
				_cleanse_status_effects(target, 1)

	# --- Status effects (from spell.statuses_caused) ---
	var statuses = spell.get("statuses_caused", [])
	if not statuses.is_empty():
		var duration: int = _calculate_status_duration(caster, spell, bonus)
		for status_name in statuses:
			_apply_status_effect(target, status_name, duration, 0, caster)
			result.effects_applied.append({"type": "status", "status": status_name, "applied": true})

	# --- Per-team outcomes: a spell that treats the two sides differently ---
	#
	# Up to Eleven stuns the enemy and merely rattles your own people. That is
	# one spell with two payloads, not two spells, and expressing it needed a
	# branch on whose side the target is standing.
	var side_branch: Dictionary = spell.get(
		"on_allies" if ("team" in target and "team" in caster and target.team == caster.team)
		else "on_enemies", {})
	if not side_branch.is_empty() and target != caster:
		var side_duration: int = _calculate_status_duration(caster, spell, bonus)
		var side_passed := false
		if side_branch.has("save_type"):
			var side_spell: Dictionary = spell.duplicate()
			side_spell["save_tier"] = side_branch.get("save_tier", spell.get("save_tier", "normal"))
			# Everything a side branch carries is statuses, so Ritual applies.
			side_passed = _spell_save(caster, target, side_spell,
				String(side_branch["save_type"]).to_lower(), true).success
		if not side_passed:
			for side_status in side_branch.get("statuses", []):
				_apply_status_effect(target, side_status, side_duration, 0, caster)
				result.effects_applied.append({"type": "status",
					"status": side_status, "applied": true})

	# --- Outcomes gated on a saving throw ---
	#
	# One roll, two branches. Three separate fields used to say this —
	# `statuses_caused_on_failed_save`, `on_failed_save_random_one_of`, and a
	# pile of `*_on_failed_save` keys in `special` that nothing read — for a
	# pattern that is the same every time: roll once, and what happens depends
	# on the result. Bitter Word's author note spelled it out exactly ("Focus
	# save negates the Silence; damage always applies"), which is why the damage
	# above this block is deliberately not gated.
	if spell.has("on_failed_save") or spell.has("on_passed_save"):
		_apply_save_gated(caster, target, spell, bonus, result)

	# --- Resource operations (from spell.resource_ops) ---
	if spell.has("resource_ops"):
		for res_spec in spell["resource_ops"]:
			_apply_resource_op(caster, target, res_spec, result)

	# --- Status removal (from spell.statuses_removed) ---
	#
	# The list says WHICH statuses to remove, not how many. Reading its length
	# as a count meant `cleanse: ["all_negative"]` removed exactly one debuff,
	# and `cooling_mist: ["Burning"]` removed one arbitrary debuff that was
	# probably not the burning. The overworld path read the same field correctly
	# the whole time, so a spell behaved one way on the map and another in a fight.
	var statuses_removed = spell.get("statuses_removed", [])
	if not statuses_removed.is_empty():
		var selector: Dictionary = StatusOps.selector_from_removed_list(statuses_removed)
		var cleansed: int = _remove_selected_statuses(target, selector)
		result.effects_applied.append({"type": "cleanse", "removed": cleansed})
		# Gentle Removal (White 1): cleansing spells also heal target for 20% of caster Spellpower
		var caster_char_gr = caster.character_data if "character_data" in caster else {}
		var is_white_cleanse = spell.get("schools", []).any(func(s): return s.to_lower() == "white")
		if is_white_cleanse and PerkSystem.has_perk(caster_char_gr, "gentle_removal") and cleansed > 0:
			var cleanse_heal = maxi(1, int(caster.get_spellpower() * 0.20))
			target.heal(cleanse_heal)
			unit_healed.emit(target, cleanse_heal)

	# --- Resurrection (from spell.resurrection) ---
	if spell.has("resurrection"):
		_apply_resurrection(caster, target, spell["resurrection"], result)

	# --- Corpse destruction: a body burned to nothing cannot be raised ---
	if spell.get("special", {}).get("prevents_resurrection", false):
		if "corpse_destroyed" in target:
			target.corpse_destroyed = true

	# --- Status operations (from spell.status_ops) ---
	if spell.has("status_ops"):
		for op_spec in spell["status_ops"]:
			_apply_status_op(caster, target, op_spec, result)

	# --- Special effects (from spell.special) ---
	var special = spell.get("special", {})
	if not special.is_empty():
		_apply_spell_special(caster, target, spell, special, result)

	# --- Legacy effects array support (for future hand-crafted spells) ---
	var effects = spell.get("effects", [])
	for effect in effects:
		var effect_type = effect.get("type", "")
		var effect_result = {}

		match effect_type:
			"damage":
				var element = effect.get("element", "physical")
				var base_value = effect.get("base_value", 10)
				var total_damage = base_value + bonus
				var variance = randf_range(0.85, 1.15)
				total_damage = int(total_damage * variance)
				apply_damage(target, total_damage, element, caster)
				effect_result = {"type": "damage", "amount": total_damage, "element": element}

			"heal":
				var base_value = effect.get("base_value", 10)
				var total_heal = base_value + int(bonus * 0.5)
				target.heal(total_heal)
				unit_healed.emit(target, total_heal)
				effect_result = {"type": "heal", "amount": total_heal}

			"buff", "debuff":
				var stat = effect.get("stat", "")
				var value = effect.get("value", 0)
				var duration = effect.get("duration", 3)
				_apply_stat_modifier(target, stat, value, duration)
				effect_result = {"type": effect_type, "stat": stat, "value": value, "duration": duration}

			"status":
				var status = effect.get("status", "")
				var duration = effect.get("duration", 1)
				# The caster's Ritual makes it land more often.
				var chance: float = effective_status_chance(
					caster.character_data if "character_data" in caster else {},
					float(effect.get("chance", 100)))
				if randf() * 100 <= chance:
					_apply_status_effect(target, status, duration, effect.get("value", 0), caster)
					effect_result = {"type": "status", "status": status, "applied": true}
				else:
					effect_result = {"type": "status", "status": status, "applied": false}

			"revive":
				if target.is_bleeding_out:
					var hp_percent = effect.get("hp_percent", 1)
					var revive_hp = maxi(1, int(target.max_hp * hp_percent / 100.0))
					revive_unit(target, revive_hp)
					effect_result = {"type": "revive", "hp": revive_hp}

		if not effect_result.is_empty():
			result.effects_applied.append(effect_result)

	# --- Post-effects: perk triggers on spell cast ---
	_process_spell_cast_perks(caster, target, spell, result)

	return result


## Spawn a summoned unit at or near target_pos on the caster's team.
## Called by cast_spell() when the spell has a "summon" key and "ground" targeting.
## Stats scale with the caster's Summoning skill level and spellpower bonus.
## Template data lives in resources/data/summon_templates.json (75 templates).
func _spawn_summoned_unit(caster: Node, summon_id: String, target_pos: Vector2i, spellpower_bonus: int) -> Dictionary:
	var template = _summon_templates.get(summon_id, {})
	if template.is_empty():
		push_warning("CombatManager: No summon template for: " + summon_id)
		# Fall back to a generic weak unit so the spell isn't a total no-op
		template = {
			"display_name": summon_id.replace("_", " "),
			"base_hp": 30, "base_mana": 0, "base_stamina": 40, "actions": 2,
			"base_damage": 8, "damage_type": "physical",
			"base_initiative": 10, "base_movement": 3,
			"base_dodge": 10, "base_armor": 0, "base_crit": 5, "base_accuracy": 0,
			"resistances": {}
		}

	# Scale factor based on caster's Summoning skill (0.5x at skill 0, 1.0x at skill 5, 1.5x at skill 10)
	var summoning_level: int = unit_skill(caster, "summoning")
	var scale: float = 0.5 + summoning_level / 10.0

	# Calculate scaled stats
	var scaled_hp = maxi(1, int(template.get("base_hp", 30) * scale) + spellpower_bonus * 2)
	var scaled_mana = int(template.get("base_mana", 0) * scale)
	var scaled_stamina = maxi(10, int(template.get("base_stamina", 40) * scale))
	var scaled_damage = maxi(1, int(template.get("base_damage", 5) * scale) + int(spellpower_bonus * 0.3))
	var scaled_initiative = template.get("base_initiative", 10)
	var scaled_movement = template.get("base_movement", 3)
	var scaled_dodge = template.get("base_dodge", 10)
	var scaled_armor = template.get("base_armor", 0)
	var scaled_crit = float(template.get("base_crit", 5))
	var scaled_accuracy = template.get("base_accuracy", 0)

	# Build character_data dict matching what init_as_enemy() and CombatUnit getters expect
	# What the creature's attack deals. `special.attack_damage_type` names it
	# explicitly (the Domain Crystal's laser); otherwise the template's own type.
	var attack_dtype: String = str(template.get("special", {}).get("attack_damage_type",
			template.get("damage_type", "physical")))

	var summon_data: Dictionary = {
		"name": template.get("display_name", summon_id.replace("_", " ")),
		"archetype_name": "Summon",
		"max_hp": scaled_hp,
		"max_mana": scaled_mana,
		"actions": template.get("actions", 2),
		"inventory": [],
		"skills": {},
		"known_spells": [],
		"perks": [],
		"tags": template.get("tags", []),
		"derived": {
			"max_hp": scaled_hp,
			"current_hp": scaled_hp,
			"max_mana": scaled_mana,
			"current_mana": scaled_mana,
			"max_stamina": scaled_stamina,
			"current_stamina": scaled_stamina,
			"initiative": scaled_initiative,
			"movement": scaled_movement,
			"dodge": scaled_dodge,
			"armor": scaled_armor,
			"crit_chance": scaled_crit,
			"accuracy": scaled_accuracy,
			"damage": scaled_damage,
			"damage_type": attack_dtype,
			# Where CombatUnit.init_as_enemy reads resistances, for every unit.
			"resistances": template.get("resistances", {}).duplicate(),
		},
		"equipped_weapon": {
			"name": "Natural Attack",
			"damage": scaled_damage,
			"damage_type": attack_dtype,
			"range": 1
		}
	}

	# Create the CombatUnit node
	var summon_unit = CombatUnit.new()
	summon_unit.summoner_id = caster.get_instance_id()  # Track ownership for mantra effects
	summon_unit.init_as_enemy(summon_data)
	summon_unit.team = caster.team  # Summon fights on the caster's side

	# Auras the creature projects by its nature. Four summons — the singing
	# birds, the guiding light, the apsara, the gandharva host — exist entirely
	# to stand somewhere and help whoever is near them, and every one of them
	# described that in an unread `special` key on its summoning spell. It
	# belongs on the creature, not on the sentence that called it.
	for aura_id in template.get("auras", []):
		summon_unit.intrinsic_auras.append(str(aura_id))

	# Summoning skill makes what you raise sturdier. Applied before any
	# empowerment below, so the two multiply rather than one overwriting the
	# other.
	var summon_hp_pct: float = caster.character_data.get("derived", {}).get(
		"summon_hp_pct", 0.0) if "character_data" in caster else 0.0
	if summon_hp_pct > 0.0:
		var trained_hp: int = int(summon_unit.max_hp * (1.0 + summon_hp_pct / 100.0))
		summon_unit.max_hp = trained_hp
		summon_unit.current_hp = trained_hp
		summon_unit.character_data.get("derived", {})["max_hp"] = trained_hp
		summon_unit.character_data.get("derived", {})["current_hp"] = trained_hp
	# Jeweled Pagoda DY: if caster.next_summon_empowered is set, consume it and apply buffs
	if "next_summon_empowered" in caster and caster.next_summon_empowered:
		caster.next_summon_empowered = false
		# HP × 3, damage × 2
		var emp_hp = summon_unit.max_hp * 3
		summon_unit.max_hp = emp_hp
		summon_unit.current_hp = emp_hp
		var d = summon_unit.character_data.get("derived", {})
		d["max_hp"] = emp_hp
		d["current_hp"] = emp_hp
		d["damage"] = d.get("damage", 0) * 2  # derived.damage is read by get_attack_damage()
		summon_unit.intrinsic_auras.append("summon_empowerment")
		combat_log.emit("%s: Empowered summon — %s is supercharged!" % [caster.unit_name, summon_unit.unit_name])

	# Apply flying status if template specifies it
	if template.get("movement_mode", "") == "flying":
		# Written directly rather than through _apply_status_effect: the summon
		# is not in the scene yet (no floating text) and is born flying, so no
		# immunity check applies. It still gets an id like every entry.
		summon_unit.status_effects.append({
			"id": StatusRules.new_instance_id(),
			"status": "Flying", "duration": 999, "value": 0, "turns_active": 0,
			"source": caster.unit_name
		})

	# Find a valid spawn position at or near target_pos
	var spawn_pos = Vector2i(-1, -1)
	if combat_grid != null and not combat_grid.is_occupied(target_pos) and combat_grid.is_valid_position(target_pos):
		spawn_pos = target_pos
	else:
		# Search outward in a 3-tile radius
		for radius in range(1, 4):
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					if abs(dx) != radius and abs(dy) != radius:
						continue
					var candidate = target_pos + Vector2i(dx, dy)
					if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
						spawn_pos = candidate
						break
				if spawn_pos != Vector2i(-1, -1):
					break
			if spawn_pos != Vector2i(-1, -1):
				break

	if spawn_pos == Vector2i(-1, -1):
		push_warning("CombatManager: No space to spawn summon " + summon_id)
		return {"success": false, "reason": "No space for summon"}

	# Place the unit on the grid and register it
	combat_grid.place_unit(summon_unit, spawn_pos)
	all_units.append(summon_unit)
	turn_order.append(summon_unit)
	unit_deployed.emit(summon_unit, spawn_pos)
	combat_log.emit("%s summons %s!" % [caster.unit_name, summon_unit.unit_name])

	return {"success": true, "type": "summon", "unit": summon_unit, "position": spawn_pos}


## Process spell.special fields: battlefield dispels, see-through-stealth, etc.
func _apply_spell_special(caster: Node, target: Node, spell: Dictionary, special: Dictionary, result: Dictionary) -> void:
	# Crystal Light: dispels_all_battlefield — strip listed statuses from ALL units
	var bf_dispel = special.get("dispels_all_battlefield", [])
	if not bf_dispel.is_empty():
		var stripped_count: int = 0
		for unit in all_units:
			if unit.is_dead:
				continue
			for status_name in bf_dispel:
				if unit.has_status(status_name):
					_remove_status_by_name(unit, status_name)
					stripped_count += 1
			# Also break stealth on all units (Crystal Light reveals everything)
			if "is_stealthed" in unit and unit.is_stealthed:
				_leave_stealth(unit)
				combat_log.emit("%s is revealed by the blinding light!" % unit.unit_name)
				stripped_count += 1
		combat_log.emit("Crystal Light strips %d concealment effects!" % stripped_count)
		result.effects_applied.append({"type": "battlefield_dispel", "count": stripped_count})

	# Divine Eye: see_through_stealth — grant the target permanent stealth vision
	var see_through = special.get("see_through_stealth", [])
	if not see_through.is_empty():
		if "see_through_stealth" in target:
			target.see_through_stealth = true
		else:
			target.set("see_through_stealth", true)
		combat_log.emit("%s gains true sight — stealth and illusions cannot fool them!" % target.unit_name)
		result.effects_applied.append({"type": "true_sight"})

	# stealth_bonus: mark that this spell grants stealth advantage (for detection DC)
	if special.get("stealth_bonus", false):
		if "is_stealthed" in target:
			target.is_stealthed = true
			combat_log.emit("%s is cloaked in shadow." % target.unit_name)


## Process passive perks that trigger when a spell hits a target.
## Called from _apply_spell_effects() after all effects are applied.
func _process_spell_cast_perks(caster: Node, target: Node, spell: Dictionary, result: Dictionary) -> void:
	var caster_char = caster.character_data if "character_data" in caster else {}
	var element = spell.get("damage_type", "")
	var schools = spell.get("schools", [])
	var has_damage = result.effects_applied.any(func(e): return e.get("type") == "damage")
	var has_debuff = result.effects_applied.any(func(e): return e.get("type") == "status")
	# Elements here are damage TYPES (damage_types.json): there is no "air",
	# "water" or "earth" damage any more. Air's is lightning, Water's is ice;
	# Earth deals crushing, but so do Water's waves, so Earth perks key on the
	# Earth SCHOOL only. Stat penalties on the target go through
	# _apply_on_hit_stat_modifier, which spares a target this spell just dropped.

	# Touch of Gloom: debuff spells also apply -1 Movement and -3 Initiative for 2 turns
	if PerkSystem.has_perk(caster_char, "touch_of_gloom") and has_debuff:
		var is_black_spell = schools.any(func(s): return s.to_lower() == "black")
		if is_black_spell:
			_apply_on_hit_stat_modifier(target, "movement", -1, 2)
			_apply_on_hit_stat_modifier(target, "initiative", -3, 2)

	# Measured Radiance: white damage spells have 25% chance to blind for 1 turn
	if PerkSystem.has_perk(caster_char, "measured_radiance") and has_damage:
		var is_white = element == "white" or schools.any(func(s): return s.to_lower() == "white")
		if is_white and randf() < 0.25:
			_apply_on_hit_status(target, "Blinded", 1, 0, caster)

	# Mental Aftershock: space damage spells apply -10% Focus and -3 Initiative for 2 turns
	if PerkSystem.has_perk(caster_char, "mental_aftershock") and has_damage:
		var is_space = element == "space" or schools.any(func(s): return s.to_lower() == "space")
		if is_space:
			# -3 initiative as stat modifier; -10% focus as a flat -1 (focus is usually ~10)
			_apply_on_hit_stat_modifier(target, "initiative", -3, 2)
			_apply_on_hit_stat_modifier(target, "focus", -1, 2)

	# Creeping Cold: ice/cold spells that deal damage also apply -1 Movement for 2 turns
	if PerkSystem.has_perk(caster_char, "creeping_cold") and has_damage:
		var is_cold = element == "ice" or schools.any(func(s): return s.to_lower() == "water")
		if is_cold:
			_apply_on_hit_stat_modifier(target, "movement", -1, 2)

	# No Warning (Sorcery 3): first combat round only, Sorcery spells deal +30% bonus damage
	if PerkSystem.has_perk(caster_char, "no_warning") and has_damage and combat_round == 1:
		var is_sorcery_nw = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery_nw:
			var nw_bonus = int(result.get("damage", 0) * 0.30)
			if nw_bonus > 0:
				apply_damage(target, nw_bonus, element)
				result["no_warning_bonus"] = nw_bonus

	# Spell Like a Knife (Sorcery 5): single-target Sorcery kill → set bonus ready flag for next spell
	if PerkSystem.has_perk(caster_char, "spell_like_a_knife") and has_damage:
		var is_sorcery_slk = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery_slk and not target.is_alive() and "sorcery_kill_bonus_ready" in caster:
			caster.sorcery_kill_bonus_ready = true

	# Nothing Burns Alone (Fire 4): when a burning enemy dies, spread Burning (2 turns) to enemies within 1 tile
	if PerkSystem.has_perk(caster_char, "nothing_burns_alone"):
		var is_fire_nba = element == "fire" or schools.any(func(s): return s.to_lower() == "fire")
		if is_fire_nba and not target.is_alive() and target.has_status("Burning"):
			for adj in _get_enemies_in_range(target, 1):
				if adj != target and adj.is_alive():
					_apply_status_effect(adj, "Burning", 2, 0, caster)

	# Tremor (Earth 2): Earth AoE spells have 25% chance to knock all targets prone
	if PerkSystem.has_perk(caster_char, "tremor") and has_damage:
		var is_earth_tr = schools.any(func(s): return s.to_lower() == "earth")
		var is_aoe_tr = spell.get("targeting", "").begins_with("aoe")
		if is_earth_tr and is_aoe_tr and randf() < 0.25:
			_apply_on_hit_status(target, "Knocked_Down", 1, 0, caster)

	# Ashes Remember Heat (Fire 5): killing a burning enemy leaves burning terrain for 3 turns
	if PerkSystem.has_perk(caster_char, "ashes_remember_heat") and has_damage:
		var is_fire_arh = element == "fire" or schools.any(func(s): return s.to_lower() == "fire")
		if is_fire_arh and not target.is_alive() and target.has_status("Burning"):
			if combat_grid and "grid_position" in target:
				combat_grid.add_terrain_effect(target.grid_position, "fire", 3)

	# Scattering Gust (Air 1): push/knockback spells have 25% chance to also Knockdown
	var has_push = result.effects_applied.any(func(e): return e.get("status", "") in ["Pushed", "Knocked_Back", "Pulled"])
	if PerkSystem.has_perk(caster_char, "scattering_gust") and has_push:
		var is_air_sg = schools.any(func(s): return s.to_lower() == "air")
		if is_air_sg and randf() < 0.25:
			_apply_on_hit_status(target, "Knocked_Down", 1, 0, caster)

	# Riptide (Water 3): push/pull spells gain +1 tile displacement (applied to stat mod) + save vs knockdown
	# The extra displacement is handled by adding a brief Move debuff to simulate root
	if PerkSystem.has_perk(caster_char, "riptide") and has_push:
		var is_water_r = schools.any(func(s): return s.to_lower() == "water")
		if is_water_r:
			# Chance for knockdown in addition to the push
			if randf() < 0.40:
				_apply_on_hit_status(target, "Knocked_Down", 1, 0, caster)

	# Mystic Healer (White 3 + Enchantment 2): single-target healing also applies a random minor buff (2 turns)
	var has_heal = result.effects_applied.any(func(e): return e.get("type") == "heal")
	if PerkSystem.has_perk(caster_char, "mystic_healer") and has_heal:
		var is_white_mh = schools.any(func(s): return s.to_lower() == "white")
		if is_white_mh:
			var buffs = ["Strengthened", "Hastened", "Shielded", "Inspired"]
			_apply_status_effect(target, buffs[randi() % buffs.size()], 2, 0, caster)

	# Crystalline Edge (Earth 2): Earth damage spells have 20% chance to apply Brittle (-15% Armor, 2 turns)
	if PerkSystem.has_perk(caster_char, "crystalline_edge") and has_damage:
		var is_earth = schools.any(func(s): return s.to_lower() == "earth")
		if is_earth and randf() < 0.20:
			var brittle_amt = int(target.get_armor() * 0.15)
			if brittle_amt > 0:
				_apply_on_hit_stat_modifier(target, "armor", -brittle_amt, 2)

	# Weight of the Mountain (Earth 3): Earth damage spells apply -1 Movement for 2 turns
	if PerkSystem.has_perk(caster_char, "weight_of_the_mountain") and has_damage:
		var is_earth_wm = schools.any(func(s): return s.to_lower() == "earth")
		if is_earth_wm:
			_apply_on_hit_stat_modifier(target, "movement", -1, 2)

	# Tidal Surge (Water 2): after casting a Water spell, caster gains +1 Movement for 1 turn
	if PerkSystem.has_perk(caster_char, "tidal_surge"):
		var is_water_ts = element == "ice" or schools.any(func(s): return s.to_lower() == "water")
		if is_water_ts:
			_apply_stat_modifier(caster, "movement", 1, 1)

	# Static Edge (Air 1): all attacks deal +10% weapon damage as Air damage
	# Wired in get_continuous_stat_bonus; here we add it as a bonus damage proc on spell hits
	# Chain Spark (Air 7): lightning spells have a 30% chance to chain to 1 more
	# target within 2 tiles, for 50% of the damage.
	if PerkSystem.has_perk(caster_char, "chain_spark") and has_damage:
		# Lightning damage only: an Air spell dealing physical damage is not lightning.
		var is_lightning = element == "lightning"
		if is_lightning and randf() < 0.30:
			var chain_targets = _get_enemies_in_range(target, 2)
			chain_targets.erase(target)
			chain_targets.erase(caster)
			if not chain_targets.is_empty():
				var chain_target = chain_targets[randi() % chain_targets.size()]
				var chain_dmg = int(result.get("damage", 0) * 0.50)
				chain_dmg = maxi(1, chain_dmg)
				apply_damage(chain_target, chain_dmg, "lightning")
				result["chain_spark_damage"] = chain_dmg

	# Weakening Gaze (Enchantment 1): Enchantment debuff spells last extra turns,
	# scaling with Enchantment skill (1 extra turn per 3 levels, minimum 1).
	if PerkSystem.has_perk(caster_char, "weakening_gaze") and has_debuff:
		var is_enchant = schools.any(func(s): return s.to_lower() == "enchantment")
		if is_enchant:
			if not target.status_effects.is_empty():
				var last_effect = target.status_effects[-1]
				if last_effect.get("status", "") != "":
					var enc_lv: int = CharacterSystem.get_effective_skill_level(caster_char, "enchantment")
					last_effect["duration"] = last_effect.get("duration", 1) + maxi(1, int(enc_lv / 3))

	# Sudden Silence (Sorcery 3): Sorcery damage spells reduce target Spellpower by 25% for 1 turn
	if PerkSystem.has_perk(caster_char, "sudden_silence") and has_damage:
		var is_sorcery = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery:
			var sp_pen = int(target.get_spellpower() * 0.25) if target.has_method("get_spellpower") else 3
			if sp_pen > 0:
				_apply_on_hit_stat_modifier(target, "spellpower", -sp_pen, 1)

	# Snap Decision (Sorcery 4): Sorcery spells reduce target Initiative by 25% for 1 turn
	if PerkSystem.has_perk(caster_char, "snap_decision") and has_damage:
		var is_sorcery_sd = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery_sd:
			var init_pen = int(target.get_initiative() * 0.25) if target.has_method("get_initiative") else 3
			if init_pen > 0:
				_apply_on_hit_stat_modifier(target, "initiative", -init_pen, 1)

	# No Follow-Up Needed (Sorcery 4): Killing with a Sorcery spell refunds 50% of its mana cost
	if PerkSystem.has_perk(caster_char, "no_follow_up_needed") and has_damage:
		var is_sorcery_nfun = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery_nfun and not target.is_alive():
			var refund = int(spell.get("mana_cost", 0) * 0.50)
			if refund > 0:
				caster.current_mana = mini(caster.current_mana + refund, caster.max_mana)
				unit_healed.emit(caster, 0)  # triggers mana display refresh

	# Fear Is the Mindkiller (Black 4): enemies with 2+ Black debuffs must save or become Feared (once per enemy per combat)
	if PerkSystem.has_perk(caster_char, "fear_is_the_mindkiller") and has_debuff:
		var is_black_fitm = schools.any(func(s): return s.to_lower() == "black")
		if is_black_fitm:
			# Count Black-type debuffs on target (check known Black statuses as proxy)
			var black_debuff_names = ["Weakened", "Blinded", "Slowed", "Silenced", "Cursed", "Doomed",
				"Damage_Debuff", "Dodge_Debuff", "Feared", "Demoralized"]
			var black_debuff_count = 0
			for se in target.status_effects:
				if se.get("status", "") in black_debuff_names:
					black_debuff_count += 1
			if black_debuff_count >= 2 and not target.has_status("Feared"):
				# Focus save vs DC 12 (simplified as 40% resist chance)
				if randf() > 0.40:
					_apply_on_hit_status(target, "Feared", 2, 0, caster)

	# Amplified Misfortune: black debuff spells also spread status effects to 1 adjacent enemy
	if PerkSystem.has_perk(caster_char, "amplified_misfortune") and has_debuff:
		var is_black = schools.any(func(s): return s.to_lower() == "black")
		if is_black:
			var nearby = _get_enemies_in_range(target, 1)
			nearby.erase(caster)
			if not nearby.is_empty():
				var splash = nearby[randi() % nearby.size()]
				for applied in result.effects_applied:
					if applied.get("type") == "status":
						var sname = applied.get("status", "")
						if sname != "":
							_apply_status_effect(splash, sname, 2, 0, caster)

	# Damaru rhythm charge: increment when caster has Damaru in off-hand (charges max at 3, discount fires in cast_spell)
	if "damaru_charges" in caster and caster.damaru_charges < 3:
		var caster_char_data = caster.character_data if "character_data" in caster else {}
		var damaru_id = ItemSystem.get_equipped_item(caster_char_data, "weapon_off")
		if damaru_id != "":
			var damaru_item = ItemSystem.get_item(damaru_id)
			if damaru_item.get("special_mechanic", "") == "damaru_charges":
				caster.damaru_charges += 1
				combat_log.emit("%s's Damaru builds rhythm (%d/3)." % [caster.unit_name, caster.damaru_charges])


## A stat penalty an on-hit or on-cast proc lays on its target. Spares the
## fallen exactly as _apply_on_hit_status does: a spell that drops its target
## must not leave a -3 Initiative waiting for whoever revives them.
func _apply_on_hit_stat_modifier(target: Node, stat: String, value: int, duration: int) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	_apply_stat_modifier(target, stat, value, duration)


## Apply a temporary stat modifier
func _apply_stat_modifier(unit: Node, stat: String, value: int, duration: int) -> void:
	# Refuse a stat no getter reads back rather than storing it forever. A
	# modifier on an unknown name is invisible in play and indistinguishable
	# from a balance problem, so it has to be loud here.
	if not CombatStats.is_modifiable(stat):
		push_error("CombatManager: cannot modify %s — %s"
			% [stat, CombatStats.explain_unknown(stat)])
		return

	# Store modifiers on the unit for processing each turn
	if not "stat_modifiers" in unit:
		unit.set("stat_modifiers", [])

	unit.get("stat_modifiers").append({
		"stat": stat,
		"value": value,
		"duration": duration
	})


## A modifier that lasts until the unit's NEXT ATTACK, or failing that through
## its next turn. "When you dodge, your next attack…" fires on the ENEMY's turn;
## with one tick per turn a duration-1 buff counted down at the start of the
## holder's own turn and was gone before it could swing. Duration 2 survives
## that tick, and attack_unit() spends it on the first blow (hit or miss) via
## _spend_next_attack_modifiers.
func _apply_next_attack_modifier(unit: Node, stat: String, value: int) -> void:
	_apply_stat_modifier(unit, stat, value, 2)
	if "stat_modifiers" in unit and not unit.stat_modifiers.is_empty() \
			and unit.stat_modifiers[-1].get("stat", "") == stat:
		unit.stat_modifiers[-1]["until_next_attack"] = true


## Remove every "until your next attack" modifier — called once the attack
## that used them has been resolved.
func _spend_next_attack_modifiers(unit: Node) -> void:
	if not "stat_modifiers" in unit:
		return
	for i in range(unit.stat_modifiers.size() - 1, -1, -1):
		if unit.stat_modifiers[i].get("until_next_attack", false):
			unit.stat_modifiers.remove_at(i)


## A modifier that is REFRESHED rather than stacked: re-applying the same `key`
## resets the existing entry's duration instead of adding a second copy. For a
## buff some unit re-casts every turn (Avatar of the Wind), so it never doubles.
func _refresh_stat_modifier(unit: Node, stat: String, value: int, duration: int,
		key: String) -> void:
	if "stat_modifiers" in unit:
		for mod in unit.stat_modifiers:
			if mod.get("key", "") == key and mod.get("stat", "") == stat:
				mod["value"] = value
				mod["duration"] = maxi(int(mod.get("duration", 0)), duration)
				return
	_apply_stat_modifier(unit, stat, value, duration)
	if "stat_modifiers" in unit and not unit.stat_modifiers.is_empty() \
			and unit.stat_modifiers[-1].get("stat", "") == stat:
		unit.stat_modifiers[-1]["key"] = key


## Check if a unit's talisman perks grant immunity or resistance to a status.
## Returns true if the status should be blocked entirely.
## Is this unit wearing something that refuses this status outright?
func _equipment_grants_immunity(unit: Node, status: String) -> bool:
	if not "character_data" in unit:
		return false
	# Walk the equipment dictionary itself rather than asking per slot: a
	# weapon SET stores a dictionary under one slot key, and
	# get_equipped_item() is typed for the simple case.
	var equipment: Dictionary = unit.character_data.get("equipment", {})
	var worn: Array[String] = []
	for slot in equipment:
		var value = equipment[slot]
		if value is String and value != "":
			worn.append(value)
		elif value is Dictionary:
			for inner in value.values():
				if inner is String and inner != "":
					worn.append(inner)
	for item_id in worn:
		var item: Dictionary = ItemSystem.get_item(item_id)
		for named in item.get("passive", {}).get("status_immunity", []):
			if str(named) == status:
				return true
	return false


func _check_talisman_status_immunity(unit: Node, status: String) -> bool:
	var perks = _get_talisman_perks(unit)
	if perks.is_empty():
		return false

	var status_lower = status.to_lower()

	# Full immunity perks
	var immunity_map = {
		"bleed_immune": ["bleeding"],
		"poison_immune": ["poisoned"],
		"fear_immune": ["feared"],
		"charm_immune": ["charmed"],
		"stun_immune": ["stunned"],
		"mental_immune": ["feared", "charmed", "confused", "berserk"],
	}

	for perk_id in perks:
		if perk_id in immunity_map:
			if status_lower in immunity_map[perk_id]:
				return true

	# 50% resistance perks
	var resist_map = {
		"bleed_resist": ["bleeding"],
		"poison_resist": ["poisoned"],
		"fear_resist": ["feared"],
		"charm_resist": ["charmed"],
		"stun_resist": ["stunned"],
	}

	for perk_id in perks:
		if perk_id in resist_map:
			if status_lower in resist_map[perk_id]:
				if randf() < 0.5:
					return true

	return false


## Apply a status effect.
## How a second application behaves is the status's `stacking.mode`: refresh
## (the longer duration wins), stack (one entry counts up) or independent (a
## new entry beside the old one, e.g. Burning).
func _apply_status_effect(unit: Node, status: String, duration: int, value: int = 0, source: Node = null) -> bool:
	if not "status_effects" in unit:
		unit.set("status_effects", [])

	var def = _status_effects.get(status, {})

	# --- Talisman perk immunity/resistance checks ---
	if _check_talisman_status_immunity(unit, status):
		if unit.has_method("show_resisted_text"):
			unit.show_resisted_text()
		return false

	# --- Character perk immunity/resistance checks ---
	if _check_perk_status_immunity(unit, status, source):
		if unit.has_method("show_resisted_text"):
			unit.show_resisted_text()
		return false

	# --- Equipment that simply says no ---
	#
	# An item may declare `passive.status_immunity`, and the item names the
	# status rather than the code naming the item: Smoked Glass Lenses said in
	# a `todo` key for months that they should stop you being Blinded, and no
	# code read it.
	if _equipment_grants_immunity(unit, status):
		combat_log.emit("%s's gear turns the %s aside."
			% [unit.unit_name, status.replace("_", " ")])
		if unit.has_method("show_resisted_text"):
			unit.show_resisted_text()
		return false

	# --- Affliction resistance: a chance not to catch it at all ---
	#
	# Some resistances are to a THING THAT HAPPENS TO YOU rather than to a
	# damage type: you resist starting to bleed, not the damage once you are.
	# Stone Body's "+25% resistance to bleed" meant this from the day it was
	# written and was read by nothing — PerkSystem wrote `bleed` into
	# derived.resistances and no code ever asked. The status declares which
	# affliction it is, so the rule is data rather than a list of status names.
	var affliction: String = str(def.get("affliction", ""))
	if affliction != "" and Resistance.resists_affliction(unit, affliction):
		combat_log.emit("%s shrugs off the %s." % [unit.unit_name, affliction])
		if unit.has_method("show_resisted_text"):
			unit.show_resisted_text()
		return false

	# --- An `immune:<name | category | polarity>` flag on something it carries ---
	#
	# Mental_Immunity and Resolute say `immune:Charmed`, `immune:Feared`...;
	# Cleansed says `immune:negative`. One rule, in data, for all of them.
	if StatusRules.immune_to(unit, status, def):
		if unit.has_method("show_resisted_text"):
			unit.show_resisted_text()
		return false

	# Kindled (Fire 1): Burning effects applied by the caster last 1 extra turn
	if status == "Burning" and source != null and "character_data" in source:
		if PerkSystem.has_perk(source.character_data, "kindled"):
			duration += 1

	# Lingering Touch (Enchantment 1): buff statuses last extra turns, scaling with
	# Enchantment skill (1 extra turn per 3 levels, minimum 1).
	if def.get("polarity", "") == "positive" and source != null and "character_data" in source:
		if PerkSystem.has_perk(source.character_data, "lingering_touch"):
			var enc_lv: int = CharacterSystem.get_effective_skill_level(source.character_data, "enchantment")
			duration += maxi(1, int(enc_lv / 3))

	# Check if already present and handle stacking.
	#
	# A definition in the new shape says how with `stacking.mode`:
	#   refresh  one entry; keep the longer duration; its holds are untouched
	#   stack    one entry with a `stacks` count (up to `max`); its holds are
	#            re-resolved at the new count, so +15 dodge at 3 stacks is +45
	#   independent  every application is a new entry of its own, with its own
	#            duration and id (Burning: two fires burn twice)
	# A definition with no `stacking` refreshes.
	var stacking_mode: String = str(def.get("stacking", {}).get("mode", ""))
	if unit.has_status(status) and stacking_mode == "stack":
		var stacked: Dictionary = _status_entry_named(unit, status)
		stacked["duration"] = maxi(int(stacked.get("duration", 0)), duration)
		if source != null:
			stacked["source"] = source
		var cap: int = int(def.get("stacking", {}).get("max", 0))
		var was: int = int(stacked.get("stacks", 1))
		var now: int = was + 1 if cap <= 0 else mini(was + 1, cap)
		if now != was:
			stacked["stacks"] = now
			_refresh_status_holds(unit, stacked)
		if unit.has_method("_update_visuals"):
			unit._update_visuals()
		return true
	if unit.has_status(status):
		if stacking_mode != "independent":
			# refresh: keep the longer duration
			for existing in unit.status_effects:
				if existing.get("status", "").to_lower() == status.to_lower():
					existing.duration = maxi(existing.duration, duration)
					if value > 0:
						existing.value = value
					if source != null:
						existing["source"] = source
					# Hard CC breaks concentration even on a refresh
					if StatusRules.def_has_flag(def, "breaks_concentration"):
						_interrupt_mantras(unit, "%s's concentration is broken by %s!" % [unit.unit_name, status])
					return true

	# The new entry. `id` names it wherever it leaves a mark (the holds its
	# while_active places), `turns_active` counts the turns it has been on.
	var effect_entry = {
		"id": StatusRules.new_instance_id(),
		"status": status,
		"duration": duration,
		"value": value,
		"turns_active": 0,
	}
	if stacking_mode == "stack":
		effect_entry["stacks"] = 1
	if source != null:
		effect_entry["source"] = source
	unit.get("status_effects").append(effect_entry)

	# What the status holds while it is on (stat, resistance, attribute and
	# skill holds, under the entry's id). _end_status releases them.
	_resolve_status_effects(unit, effect_entry, def.get("while_active", []), true)

	# Hard CC breaks concentration on the affected unit
	if StatusRules.def_has_flag(def, "breaks_concentration"):
		_interrupt_mantras(unit, "%s's concentration is broken by %s!" % [unit.unit_name, status])

	# Cleansed: remove_all_debuffs fires immediately on application
	if StatusRules.def_has_flag(def, "remove_all_debuffs"):
		var removed_count = _cleanse_status_effects(unit, 99)
		if removed_count > 0:
			combat_log.emit("%s is cleansed of all debuffs!" % unit.unit_name)

	# Invisible status grants stealth automatically
	if StatusRules.def_has_flag(def, "grants_stealth") and "is_stealthed" in unit:
		unit.is_stealthed = true
		combat_log.emit("%s fades from sight." % unit.unit_name)

	# Show floating status applied text on the unit
	if unit.has_method("show_status_applied"):
		unit.show_status_applied(status)

	# Update visuals to show new status icon
	if unit.has_method("_update_visuals"):
		unit._update_visuals()
	return true


# ── The status container: one way in, one way out ───────────────────────────
#
# _apply_status_effect() above is the ONE way a status goes onto a unit and
# _end_status() below the ONE way it comes off. Between them a status may:
#   hold values    `while_active` effects, resolved once on entry with the
#                  entry's id as the hold source, so ending it releases them
#   tick           `periodic` effects at the start or end of the carrier's turn
#   react          `triggers`: on expire, turn_start and turn_end, and on what
#                  other units do (struck, hit, the intercepting triggers
#                  before an attack lands, the movement reactions)
# Every one of these goes through EffectResolver with an EffectContext whose
# status_entry is the entry, so a magnitude can read its stacks and turns.

## Why a status ended, as _end_status() is told it:
##   expired     its duration ran out            (fires `expire` triggers)
##   upkeep      its upkeep could not be paid    (fires `expire` triggers)
##   dispelled   a dispel took it                (clears damage it caused)
##   cleansed    a cleanse took it               (clears damage it caused)
##   removed     something else took it off (a rule, a broken condition)
##   stolen      it moved to another unit, which gets a new entry
##   consumed    it was used up (a shield emptied, a charge spent)
##   death       its carrier died
##   combat_end  the fight is over
const STATUS_END_REASONS: Array[String] = [
	"expired", "dispelled", "cleansed", "removed", "stolen", "consumed",
	"death", "combat_end", "upkeep",
]


## The first status entry on `unit` named `status_name` (any letter case,
## as CombatUnit.has_status reads it), or {} if there is none.
func _status_entry_named(unit: Node, status_name: String) -> Dictionary:
	for entry in unit.status_effects:
		if str(entry.get("status", "")).to_lower() == status_name.to_lower():
			return entry
	return {}


## The index of `entry` in unit.status_effects, by identity rather than by
## content, so two look-alike entries are never confused. -1 if it is gone.
func _status_entry_index(unit: Node, entry: Dictionary) -> int:
	for i in unit.status_effects.size():
		if is_same(unit.status_effects[i], entry):
			return i
	return -1


## The EffectContext a status's own effects resolve in: whoever applied it is
## the caster, the carrier is the target, and the entry rides along.
func _status_context(unit: Node, entry: Dictionary) -> EffectContext:
	var status_name: String = str(entry.get("status", ""))
	var ctx := EffectContext.new()
	var source = entry.get("source", null)
	# The source is normally the unit that applied it; an old entry may hold a
	# name instead, and a source may have left the fight since.
	if typeof(source) == TYPE_OBJECT and is_instance_valid(source):
		ctx.caster = source
	ctx.target = unit
	ctx.container_kind = "status"
	ctx.container_id = status_name
	ctx.status_entry = entry
	ctx.source_categories = Array(StatusRules.categories_of(_status_effects.get(status_name, {})))
	# A status's damage names no dealer, as it never has (see EffectContext).
	ctx.anonymous_damage = true
	return ctx


## Resolve `effects` belonging to the status `entry` on `unit`. With `holds`,
## lasting modifies register under the entry's id (that is `while_active`);
## without, a lasting modify is refused, as it would never be released.
func _resolve_status_effects(unit: Node, entry: Dictionary, effects: Array, holds: bool) -> void:
	if effects.is_empty():
		return
	var ctx := _status_context(unit, entry)
	if holds:
		ctx.hold_source = str(entry.get("id", ""))
	EffectResolver.resolve(effects, ctx)


## The stack count of `entry` changed: put its holds back at the new count.
## Only the HOLDS are redone. Anything else in `while_active` (a persistent
## `damage` modify, an instant op) happened once when the status arrived and
## is not repeated for every stack.
func _refresh_status_holds(unit: Node, entry: Dictionary) -> void:
	var id: String = str(entry.get("id", ""))
	if id == "":
		return
	ValuePaths.release(unit, id)
	var def: Dictionary = _status_effects.get(str(entry.get("status", "")), {})
	var held: Array = []
	for effect in def.get("while_active", []):
		if typeof(effect) == TYPE_DICTIONARY and effect.get("op", "") == "modify" \
				and effect.get("mode", "") in ["fortify", "drain", "set", "multiply"]:
			held.append(effect)
	_resolve_status_effects(unit, entry, held, true)


## Fire every trigger of the status `entry` whose `on` is `event`. `info` is
## what happened: {"source": the other unit, "damage": the blow's damage}.
## Returns the last trigger's outcome (see _run_status_trigger).
func _fire_status_triggers(unit: Node, entry: Dictionary, event: String,
		info: Dictionary = {}) -> Dictionary:
	var outcome: Dictionary = {}
	var triggers: Array = _status_effects.get(str(entry.get("status", "")), {}).get("triggers", [])
	for i in triggers.size():
		if typeof(triggers[i]) == TYPE_DICTIONARY and str(triggers[i].get("on", "")) == event:
			outcome = _run_status_trigger(unit, entry, i, info)
	return outcome


## The events in which a status trigger merely ticks or ends with its carrier;
## in every other one it answers another unit, and the carrier is the one acting.
const _SELF_TRIGGERS: Array[String] = ["expire", "turn_start", "turn_end"]


## Run trigger number `index` of the status `entry` on `unit`.
##   1. its `limit` (or, for a reaction, EffectVocab.DEFAULT_TRIGGER_LIMIT a
##      turn) must have room, for this source too if once_per_source
##   2. its `if` conditions must hold and its `chance` (percent) must roll
##   3. intercept ops (negate, reflect) are not resolved: they come back in
##      the outcome for the hook to act on
##   4. the other effects resolve now, or with `defer` come back in
##      outcome.pending for _run_pending_triggers() once the attack is over
##   5. if it did anything at all, one use of its limit is spent
## A reaction that could not reach its target (an attack out of range) did
## nothing, so it spends nothing: a braced spear stays braced.
## Returns {fired, acted, negate, reflect, log, pending}.
func _run_status_trigger(unit: Node, entry: Dictionary, index: int, info: Dictionary,
		defer: bool = false) -> Dictionary:
	var out := {"fired": false, "acted": false, "negate": false, "reflect": false,
		"log": [], "pending": {}}
	var trigger: Dictionary = _status_effects.get(str(entry.get("status", "")), {}).get("triggers", [])[index]
	var against: Node = info.get("source", null)
	if not _trigger_has_room(entry, index, trigger, against):
		return out
	var ctx := _status_context(unit, entry)
	if not str(trigger.get("on", "")) in _SELF_TRIGGERS:
		ctx.caster = unit
	ctx.source = against
	ctx.event = info
	for cond in trigger.get("if", []):
		if not EffectResolver._condition_met(cond, ctx, unit):
			return out
	if trigger.has("chance") and not randf() * 100.0 < float(trigger["chance"]):
		return out
	out.fired = true
	var rest: Array = []
	for effect in trigger.get("effects", []):
		var op: String = str(effect.get("op", ""))
		if op in EffectVocab.INTERCEPT_OPS:
			out[op] = true
			out.acted = true
		else:
			rest.append(effect)
	if defer and not rest.is_empty():
		out.pending = {"unit": unit, "entry": entry, "index": index, "ctx": ctx,
			"effects": rest, "spent": out.acted, "against": against}
	elif not rest.is_empty():
		out.log = EffectResolver.resolve(rest, ctx)
		for item in out.log:
			if bool(item.get("applied", false)):
				out.acted = true
	if out.acted:
		_spend_trigger(entry, index, trigger, against)
	return out


## Resolve the effects intercepting triggers held back until the attack was
## over (a counter-attack, a step away), spending a use where that is what
## made the trigger act.
func _run_pending_triggers(pending: Array) -> void:
	for p in pending:
		if not is_instance_valid(p.unit) or p.unit.is_dead:
			continue
		var acted := false
		for item in EffectResolver.resolve(p.effects, p.ctx):
			if bool(item.get("applied", false)):
				acted = true
		if acted and not p.spent:
			var trigger: Dictionary = _status_effects.get(str(p.entry.get("status", "")), {}).get("triggers", [])[p.index]
			_spend_trigger(p.entry, p.index, trigger, p.against)


## The intercepting triggers on `unit` for `event` ("incoming_attack",
## "attacked_in_melee", "incoming_spell"), set off by `against`. Returns
## {negate, reflect, by}: whether any said negate / reflect, and which status
## said it first. With `defer`, each trigger's other effects are added to
## `pending` instead of resolving now.
func _intercept(unit: Node, against: Node, event: String, defer: bool, pending: Array) -> Dictionary:
	var seen := {"negate": false, "reflect": false, "by": ""}
	if unit == null or not is_instance_valid(unit) or unit.is_dead or not "status_effects" in unit:
		return seen
	if against == null or not is_instance_valid(against) or against.is_dead:
		return seen
	for entry in unit.status_effects.duplicate():
		if _status_entry_index(unit, entry) == -1:
			continue
		var triggers: Array = _status_effects.get(str(entry.get("status", "")), {}).get("triggers", [])
		for i in triggers.size():
			if typeof(triggers[i]) != TYPE_DICTIONARY or str(triggers[i].get("on", "")) != event:
				continue
			var out: Dictionary = _run_status_trigger(unit, entry, i, {"source": against}, defer)
			for op in EffectVocab.INTERCEPT_OPS:
				if out[op] and not seen[op]:
					seen[op] = true
					if seen.by == "":
						seen.by = str(entry.get("status", ""))
			if not out.pending.is_empty():
				pending.append(out.pending)
	return seen


## How a trigger is limited: its own `limit`, or for a reaction (EffectVocab.
## REACTION_TRIGGERS) DEFAULT_TRIGGER_LIMIT a turn; {} means unlimited.
func _trigger_limit(trigger: Dictionary) -> Dictionary:
	if trigger.has("limit"):
		return trigger["limit"]
	if str(trigger.get("on", "")) in EffectVocab.REACTION_TRIGGERS:
		return {"per": "turn", "count": EffectVocab.DEFAULT_TRIGGER_LIMIT}
	return {}


## Has trigger `index` of `entry` room left this turn (for `against`, if it
## is once_per_source)? The count lives on the status ENTRY, so two stances
## do not share one allowance and a refreshed stance keeps counting.
func _trigger_has_room(entry: Dictionary, index: int, trigger: Dictionary, against: Node) -> bool:
	var lim: Dictionary = _trigger_limit(trigger)
	if lim.is_empty():
		return true
	var uses: Dictionary = entry.get("_trigger_uses", {}).get(index, {})
	if int(uses.get("used", 0)) >= int(lim.get("count", EffectVocab.DEFAULT_TRIGGER_LIMIT)):
		return false
	if bool(lim.get("once_per_source", false)) and against != null \
			and uses.get("seen", {}).has(against.get_instance_id()):
		return false
	return true


## Record one use of trigger `index` of `entry`, against `against`.
func _spend_trigger(entry: Dictionary, index: int, trigger: Dictionary, against: Node) -> void:
	if _trigger_limit(trigger).is_empty():
		return
	var all: Dictionary = entry.get("_trigger_uses", {})
	var uses: Dictionary = all.get(index, {"used": 0, "seen": {}})
	uses["used"] = int(uses.get("used", 0)) + 1
	if against != null:
		uses["seen"][against.get_instance_id()] = true
	all[index] = uses
	entry["_trigger_uses"] = all


## How many times the limited triggers of `entry` have fired since its
## carrier's turn began (what a test asks of a stance).
func trigger_uses(entry: Dictionary) -> int:
	var total := 0
	for uses in entry.get("_trigger_uses", {}).values():
		total += int(uses.get("used", 0))
	return total


## How far a trigger reaches, in tiles: its `reach`, where "weapon" means the
## carrier's own attack range (a Kill Zone is everything you could have shot).
## A trigger with no reach reaches 1.
func trigger_reach(trigger: Dictionary, unit: Node) -> int:
	var declared = trigger.get("reach", 1)
	if typeof(declared) == TYPE_STRING and str(declared) == "weapon":
		if unit != null and unit.has_method("get_attack_range"):
			return int(unit.get_attack_range())
		return 1
	return maxi(1, int(declared))


## Say what a reacting trigger did, the way the arena log reads it: one
## "reactive" line per damage dealt (its amount) and per status given (0).
func _announce_trigger(unit: Node, status_name: String, outcome: Dictionary) -> void:
	for item in outcome.get("log", []):
		if not bool(item.get("applied", false)):
			continue
		match str(item.get("op", "")):
			"damage":
				status_effect_triggered.emit(unit, status_name, int(item.get("amount", 0)), "reactive")
			"status":
				status_effect_triggered.emit(unit, status_name, 0, "reactive")


## Run the `periodic` effects (and `when`-matching triggers) of every status on
## `unit` that ticks at `when` ("turn_start" or "turn_end"). A list copy is
## walked, so an effect that removes a status cannot upset the loop; an entry
## that has gone by the time its turn comes is skipped.
func _tick_status_effects_at(unit: Node, when: String) -> void:
	for entry in unit.status_effects.duplicate():
		if _status_entry_index(unit, entry) == -1:
			continue
		var def: Dictionary = _status_effects.get(str(entry.get("status", "")), {})
		var periodic: Dictionary = def.get("periodic", {})
		if not periodic.is_empty() and str(periodic.get("when", "turn_start")) == when:
			_tick_periodic(unit, entry, periodic.get("effects", []))
		_fire_status_triggers(unit, entry, when)


## One tick of a status's `periodic` effects. The applier's damage-over-time
## bonuses apply to its damage (ctx.dot_tick, see status_tick_damage), and
## each tick is announced as the arena log expects: "damage" with what was
## dealt, "heal" (and unit_healed) with what was healed.
func _tick_periodic(unit: Node, entry: Dictionary, effects: Array) -> void:
	if effects.is_empty():
		return
	var status_name: String = str(entry.get("status", ""))
	var ctx := _status_context(unit, entry)
	ctx.dot_tick = true
	for item in EffectResolver.resolve(effects, ctx):
		if not bool(item.get("applied", false)):
			continue
		var amount: int = int(item.get("amount", 0))
		match str(item.get("op", "")):
			"damage":
				status_effect_triggered.emit(unit, status_name, amount, "damage")
			"heal":
				unit_healed.emit(unit, amount)
				status_effect_triggered.emit(unit, status_name, amount, "heal")


## A damage-over-time tick of `damage` of type `element`, after the bonuses of
## whoever applied it (`source`, which may be null or gone). Fire Magic makes a
## burn bite harder through burning_damage_pct, Alchemy a venom through
## poison_damage_pct, and Fan_the_Flames (the flag increase_burning_damage_dealt
## on the source) adds half again to fire. Read off the applier, the way the
## status entry has always remembered them: the poisoner's skill, not the
## victim's.
func status_tick_damage(source: Node, element: String, damage: int) -> int:
	if source == null or not is_instance_valid(source):
		return damage
	var derived: Dictionary = source.character_data.get("derived", {}) \
		if "character_data" in source else {}
	if element == "poison":
		var venom_pct: float = float(derived.get("poison_damage_pct", 0.0))
		if venom_pct > 0.0:
			damage = int(damage * (1.0 + venom_pct / 100.0))
	elif element == "fire":
		var burn_pct: float = float(derived.get("burning_damage_pct", 0.0))
		if burn_pct > 0.0:
			damage = int(damage * (1.0 + burn_pct / 100.0))
		if StatusRules.has_flag(source, "increase_burning_damage_dealt"):
			damage = int(damage * 1.5)
	return damage


## The end of `unit`'s turn: the turn_end half of _process_status_effects.
## Called from end_turn() and when a turn is skipped by a status.
func _process_status_turn_end(unit: Node) -> void:
	if unit == null or not "status_effects" in unit or unit.status_effects.is_empty():
		return
	_tick_status_effects_at(unit, "turn_end")


## THE way a status comes off a unit. `reason` is one of STATUS_END_REASONS.
##   1. the entry leaves unit.status_effects (found by identity)
##   2. every hold it placed is released (ValuePaths, by the entry's id)
##   3. if it ran out (expired / upkeep), its `expire` triggers fire
##   4. if it was cleansed or dispelled, and no other entry of the same
##      status is left, persistent damage it caused is cleared
## The entry is taken off FIRST, so an expire trigger that applies the same
## status again starts a fresh one instead of refreshing the dying one.
##
## Floating text and the status_effect_expired signal stay with the callers,
## which have always decided those for themselves. So does the Invisible rule
## in _on_status_expired. What a status does when it runs out (Doomed kills,
## Infected bursts and hatches) is its `expire` triggers, fired here.
func _end_status(unit: Node, entry: Dictionary, reason: String) -> void:
	if not reason in STATUS_END_REASONS:
		push_error("CombatManager._end_status: unknown reason '%s' (%s)"
			% [reason, ", ".join(STATUS_END_REASONS)])
	if unit == null or not "status_effects" in unit:
		return
	var status_name: String = str(entry.get("status", ""))
	var id: String = str(entry.get("id", ""))
	var idx: int = _status_entry_index(unit, entry)
	if idx != -1:
		unit.status_effects.remove_at(idx)
	# An entry from before ids existed placed no holds.
	if id != "":
		ValuePaths.release(unit, id)
	if idx == -1:
		return   # already ended: nothing more to fire or clear
	if reason in ["expired", "upkeep"]:
		_fire_status_triggers(unit, entry, "expire")
	if reason in ["cleansed", "dispelled"] and not unit.has_status(status_name):
		_clear_damage_for_removed(unit, status_name)


## Take `count` stacks off a stacking status. Its holds drop to the new count;
## at zero the status ends, for `reason`. An entry without a `stacks` count is
## one stack.
func _remove_stacks(unit: Node, entry: Dictionary, count: int, reason: String) -> void:
	var left: int = int(entry.get("stacks", 1)) - count
	if left <= 0:
		_end_status(unit, entry, reason)
		return
	entry["stacks"] = left
	_refresh_status_holds(unit, entry)


## A cleanse or dispel just took `status_name` off `unit`: undo any persistent
## `damage` the unit carries whose entry is {"cleanse": {"category": c}} for a
## category of that status. A status with no `categories` (all of today's data
## until stage 2b Task 4) clears nothing.
func _clear_damage_for_removed(unit: Node, status_name: String) -> void:
	var cats: Array = _status_effects.get(status_name, {}).get("categories", [])
	if cats.is_empty() or not ValuePaths.is_party_unit(unit):
		return
	for c in cats:
		ValuePaths.clear_damage(unit.character_data, "cleanse", {"category": c}, unit)
	CharacterSystem.update_derived_stats(unit.character_data)


## Remove a specific status effect by name from a unit. Returns true if found and removed.
## The newest entry of that name goes. `reason` is passed to _end_status.
func _remove_status_by_name(unit: Node, status_name: String, reason: String = "removed") -> bool:
	if not "status_effects" in unit:
		return false
	for i in range(unit.status_effects.size() - 1, -1, -1):
		if unit.status_effects[i].get("status", "") == status_name:
			var def = _status_effects.get(status_name, {})
			var entry: Dictionary = unit.status_effects[i]
			_on_status_expired(unit, status_name, def, entry)
			_end_status(unit, entry, reason)
			status_effect_expired.emit(unit, status_name)
			if unit.has_method("show_status_expired"):
				unit.show_status_expired(status_name)
			return true
	return false


## Remove negative status effects using the dispellable flag from status definitions.
## Only removes debuffs that are marked dispellable. Returns the count removed.
## Remove every status on `unit` that `selector` picks. Returns how many went.
## `reason` is passed to _end_status: a remove op is a cleanse (which clears
## the damage a cleansed status caused); convert spends them ("consumed").
func _remove_selected_statuses(unit: Node, selector: Dictionary,
		reason: String = "cleansed") -> int:
	var picked: Array = StatusOps.select(unit, selector, _status_effects)
	var removed := 0
	for entry in picked:
		if _remove_status_by_name(unit, entry.get("status", ""), reason):
			removed += 1
	return removed


## Which unit a status op means by "caster", "target", "all_allies", "all_enemies".
func _units_for_role(role: String, caster: Node, target: Node) -> Array:
	match role:
		"caster":
			return [caster]
		"target":
			return [target]
		"all_allies":
			return get_team_units(caster.team if "team" in caster else 0)
		"all_enemies":
			return get_team_units(1 - (caster.team if "team" in caster else 0))
		"nearest_enemy":
			# The closest living enemy to the CASTER, or nobody. Draw Out the
			# Venom needs somewhere to put what it pulls out of an ally, and
			# "the nearest enemy" is the answer a spell like that wants.
			var closest: Node = null
			var best: int = 1 << 30
			for unit in all_units:
				if not is_instance_valid(unit) or unit.is_dead:
					continue
				if not "team" in unit or unit.team == caster.team:
					continue
				var dist: int = _grid_distance(caster.grid_position, unit.grid_position)
				if dist < best:
					best = dist
					closest = unit
			return [closest] if closest != null else []
	return [target]


## Perform one status operation.
##
##   {"op": "remove",   "select": {"tag": "magical"}, "on": "target"}
##   {"op": "steal",    "select": {"tag": "positive"}, "from": "target", "to": "caster"}
##   {"op": "transfer", "select": {"names": ["Burning"]}, "from": "all_allies", "to": "all_enemies"}
##   {"op": "convert",  "select": {"tag": "all_negative"}, "on": "caster",
##    "into": "damage", "per_status": 12, "damage_type": "white", "radius": 2}
func _apply_status_op(caster: Node, target: Node, op_spec: Dictionary,
		result: Dictionary) -> void:
	var op: String = op_spec.get("op", "")
	if not StatusOps.is_op(op):
		push_warning("CombatManager: spell status op — %s"
			% StatusOps.explain_unknown_op(op))
		return
	var selector: Dictionary = op_spec.get("select", {})

	match op:
		"remove":
			var total := 0
			for unit in _units_for_role(op_spec.get("on", "target"), caster, target):
				total += _remove_selected_statuses(unit, selector)
			result.effects_applied.append({"type": "cleanse", "removed": total})

		"steal":
			# The thief keeps whatever duration was left, which is what makes
			# stealing a raised shield worth more than stealing a fading one.
			var thief: Node = _units_for_role(op_spec.get("to", "caster"), caster, target)[0]
			var taken := 0
			for victim in _units_for_role(op_spec.get("from", "target"), caster, target):
				for entry in StatusOps.select(victim, selector, _status_effects):
					var name: String = entry.get("status", "")
					var left: int = int(entry.get("duration", 1))
					var value: int = int(entry.get("value", 0))
					if _remove_status_by_name(victim, name, "stolen"):
						_apply_status_effect(thief, name, left, value, caster)
						taken += 1
			if taken > 0:
				combat_log.emit("%s takes %d blessing(s) for itself!"
					% [thief.unit_name, taken])
			result.effects_applied.append({"type": "steal", "count": taken})

		"transfer":
			# Group to group, spread evenly, nothing lost. Heat Transfer lifts
			# every burning stack off the party and hands it to the people who
			# lit them; a stack removed from an ally must land on an enemy.
			var sources: Array = _units_for_role(op_spec.get("from", "caster"), caster, target)
			var sinks: Array = _units_for_role(op_spec.get("to", "target"), caster, target)
			sinks = sinks.filter(func(u): return is_instance_valid(u) and not u.is_dead)
			if sinks.is_empty():
				result.effects_applied.append({"type": "transfer", "count": 0})
				return
			var carried: Array = []
			for source in sources:
				for entry in StatusOps.select(source, selector, _status_effects):
					var name: String = entry.get("status", "")
					var left: int = int(entry.get("duration", 1))
					if _remove_status_by_name(source, name, "stolen"):
						carried.append({"status": name, "duration": left})
			# Even distribution, front to back, so a remainder does not vanish.
			for i in range(carried.size()):
				var sink: Node = sinks[i % sinks.size()]
				_apply_status_effect(sink, carried[i]["status"],
					carried[i]["duration"], 0, caster)
			if not carried.is_empty():
				combat_log.emit("%d effect(s) change hands." % carried.size())
			result.effects_applied.append({"type": "transfer", "count": carried.size()})

		"convert":
			# Spend the statuses for something else. Each one removed becomes a
			# bolt, so a heavily-debuffed caster detonates harder.
			var on_unit: Node = _units_for_role(op_spec.get("on", "caster"), caster, target)[0]
			var spent: int = _remove_selected_statuses(on_unit, selector, "consumed")
			if spent <= 0:
				result.effects_applied.append({"type": "convert", "count": 0})
				return
			var per: int = int(op_spec.get("per_status", 0))
			var element: String = op_spec.get("damage_type", "physical")
			var radius: int = int(op_spec.get("radius", 2))
			var burst: int = spent * per
			var struck := 0
			for unit in all_units:
				if unit.is_dead or not "team" in unit or unit.team == on_unit.team:
					continue
				if _grid_distance(on_unit.grid_position, unit.grid_position) > radius:
					continue
				apply_damage(unit, burst, element)
				struck += 1
			combat_log.emit("%s sheds %d affliction(s) as light!"
				% [on_unit.unit_name, spent])
			result.effects_applied.append({"type": "convert", "count": spent,
				"damage": burst, "struck": struck})


func _cleanse_status_effects(unit: Node, count: int) -> int:
	if not "status_effects" in unit:
		return 0

	var removed = 0
	var to_remove: Array[int] = []

	for i in range(unit.status_effects.size()):
		if removed >= count:
			break
		var status_name = unit.status_effects[i].get("status", "")
		var def = _status_effects.get(status_name, {})
		# Only cleanse debuffs that are marked as dispellable
		if def.get("polarity", "") == "negative" and def.get("dispellable", false):
			to_remove.append(i)
			removed += 1

	# Remove in reverse order to maintain indices
	to_remove.reverse()
	var entries: Array = []
	for idx in to_remove:
		entries.append(unit.status_effects[idx])
	for expired in entries:
		var sname = expired.get("status", "")
		_end_status(unit, expired, "cleansed")
		# Show expired visual
		if unit.has_method("show_status_expired"):
			unit.show_status_expired(sname)
		status_effect_expired.emit(unit, sname)

	return removed


## Process status effects at turn start.
## Damage and healing over time are the statuses' `periodic` effects, run first
## (_tick_status_effects_at). Then, status by status: incapacitation, the
## status's own `save`, the duration, and expiry; then spread and auras.
## Returns true if the unit should skip their turn (incapacitated).
func _process_status_effects(unit: Node) -> bool:
	if not "status_effects" in unit or unit.status_effects.is_empty():
		return false

	var skip_turn = false
	var effects_to_remove: Array = []

	# New-shape statuses first: `periodic` effects with when turn_start, and
	# turn_start triggers. A periodic reads `turns_active` before this turn
	# counts, so its first tick sees 0.
	_tick_status_effects_at(unit, "turn_start")

	# A copy of the list is walked: a tick above or below (a DoT that kills,
	# a trigger that removes) may change the real one. An entry that has gone
	# meanwhile is skipped.
	for effect in unit.status_effects.duplicate():
		if _status_entry_index(unit, effect) == -1:
			continue
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})

		# --- Incapacitation check ---
		if StatusRules.def_has_any_flag(effect_def, ["skip_turn", "cannot_act"]):
			skip_turn = true

		# --- The status's own save, {stat, dc, when} (Stunned shakes itself off) ---
		# d20 + the carrier's effective attribute against the fixed DC, with no
		# natural 1 or 20 and no save bonuses: the roll statuses have always made.
		var saved = false
		var own_save: Dictionary = effect_def.get("save", {})
		if not own_save.is_empty() and str(own_save.get("when", "")) == "turn_start":
			var save_attr: int = unit_attribute(unit, str(own_save.get("stat", "constitution")).to_lower())
			var roll = randi_range(1, 20) + save_attr
			if roll >= int(own_save.get("dc", 15)):
				saved = true
				effect.duration = 0  # Will be removed below
				# Show "Resisted!" floating text
				if unit.has_method("show_resisted_text"):
					unit.show_resisted_text()

		# --- Duration: "until_save" statuses only expire on save ---
		if str(effect_def.get("duration", {}).get("kind", "")) == "until_save":
			if not saved:
				# Don't decrement — only saves can remove this
				pass
			# If saved, duration is already 0 from above
		else:
			# Normal duration decrement
			effect.duration -= 1

		# One more turn on.
		effect["turns_active"] = int(effect.get("turns_active", 0)) + 1

		# Mark for removal if expired
		if effect.duration <= 0:
			effects_to_remove.append(effect)

	# Remove expired effects, newest first as before.
	effects_to_remove.reverse()
	for expired_effect in effects_to_remove:
		var status_name = expired_effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		# Process expiry callbacks before removing
		_on_status_expired(unit, status_name, effect_def, expired_effect)
		_end_status(unit, expired_effect, "expired")
		# Show expired visual (grey strikethrough)
		if unit.has_method("show_status_expired"):
			unit.show_status_expired(status_name)
		status_effect_expired.emit(unit, status_name)

	# Process status spread (e.g. Burning can spread to adjacent units)
	_process_status_spread(unit)

	# Process aura effects (buff nearby allies each turn)
	_refresh_aura_max_hp()
	_process_auras(unit)

	# Stat modifiers are NOT ticked here any more. They used to be — and then
	# again in _process_turn_start_perks — so every timed buff and debuff lost
	# two turns of duration per turn and lasted half what the data said. (And
	# only when the unit happened to carry a status: with none, this function
	# returns early and they ticked once.) _start_current_turn() ticks them
	# exactly once now, right after this call.

	return skip_turn


## What the code still does as a status goes, whatever took it off: Invisible
## takes stealth with it. What a status does when it RUNS OUT (Doomed kills,
## Infected bursts, bleeds and hatches) is data now: its `expire` triggers,
## which _end_status fires on expiry only.
func _on_status_expired(unit: Node, status_name: String, def: Dictionary, _effect_instance: Dictionary = {}) -> void:
	# Invisible expiry: drop stealth unless unit has Blend In (own stealth ability)
	if StatusRules.def_has_flag(def, "grants_stealth"):
		if "is_stealthed" in unit and unit.is_stealthed:
			var char_data = unit.character_data if "character_data" in unit else {}
			if not PerkSystem.has_perk(char_data, "blend_in"):
				_leave_stealth(unit)
				combat_log.emit("%s becomes visible as the spell fades." % unit.unit_name)
			else:
				combat_log.emit("%s's invisibility fades but stays hidden (Blend In)." % unit.unit_name)


## The movement triggers of `reactor`'s statuses, for `mover` having just
## moved from old_dist to new_dist tiles away (ending on new_pos):
##   enemy_enters_reach  crossing IN to the trigger's reach, not merely being
##                       in it: a unit walking about inside provokes once
##   ally_threatened     the mover ended next to an ally standing within the
##                       trigger's reach of the reactor
func _fire_move_reactions(reactor: Node, mover: Node, old_dist: int, new_dist: int,
		_old_pos: Vector2i, new_pos: Vector2i) -> void:
	if not "status_effects" in reactor:
		return
	for entry in reactor.status_effects.duplicate():
		if _status_entry_index(reactor, entry) == -1:
			continue
		var triggers: Array = _status_effects.get(str(entry.get("status", "")), {}).get("triggers", [])
		for i in triggers.size():
			var trigger = triggers[i]
			if typeof(trigger) != TYPE_DICTIONARY:
				continue
			var on: String = str(trigger.get("on", ""))
			if on != "enemy_enters_reach" and on != "ally_threatened":
				continue
			var reach: int = trigger_reach(trigger, reactor)
			var fires := false
			if on == "enemy_enters_reach":
				fires = new_dist <= reach and old_dist > reach
			else:
				# Somebody has come for one of the people you are standing over.
				for ally in all_units:
					if ally == reactor or ally.is_dead or not "team" in ally:
						continue
					if ally.team != reactor.team or not "grid_position" in ally:
						continue
					if _grid_distance(reactor.grid_position, ally.grid_position) > reach:
						continue
					if _grid_distance(new_pos, ally.grid_position) <= 1:
						fires = true
						break
			if fires:
				_run_status_trigger(reactor, entry, i, {"source": mover})


## The `attack` op: a free weapon attack by `unit` against `against`, at
## `power_pct` percent damage (Set for Charge's braced spear: 200). It still has
## to be able to reach — a stance may threaten two tiles because it is a spear
## stance, and the same rule keeps a swordsman from answering across the gap —
## and returns false when it could not, so the trigger spends nothing.
## `label` (the status name) goes in the combat log.
func free_reaction_attack(unit: Node, against: Node, power_pct: float, label: String) -> bool:
	if not is_instance_valid(against) or against.is_dead:
		return false
	var range_ok: int = unit.get_attack_range() if unit.has_method("get_attack_range") else 1
	if _grid_distance(unit.grid_position, against.grid_position) > range_ok:
		return false
	combat_log.emit("%s: %s!" % [unit.unit_name, label.replace("_", " ")])
	var mult: float = power_pct / 100.0
	if is_equal_approx(mult, 1.0):
		attack_unit(unit, against, true)
	else:
		# A braced spear hits harder than a swing of opportunity.
		_reaction_damage_mult = mult
		attack_unit(unit, against, true)
		_reaction_damage_mult = 1.0
	return true


## Multiplier applied to the next reaction attack, set around attack_unit()
## because the attack path takes no such argument (free_reaction_attack sets
## it from an `attack` op's power_pct), and cleared immediately.
var _reaction_damage_mult: float = 1.0


## Heal somebody who is not you.
##
## `_resolve_heal_self` ignored its own `targeting` field and always healed the
## user, so Field Medic — "heal an ADJACENT ALLY" — healed the medic.
func _resolve_heal_ally(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var target: Node = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No ally there"}
	if not "team" in target or target.team != user.team:
		return {"success": false, "reason": "Not an ally"}
	var reach: int = int(combat_data.get("range", 1))
	if _grid_distance(user.grid_position, target_pos) > reach:
		return {"success": false, "reason": "Out of reach"}

	var amount: int = int(combat_data.get("heal_value", 0))
	var scale: String = str(combat_data.get("scale_stat", ""))
	var pct: float = float(combat_data.get("scale_pct", 25)) / 100.0
	match scale:
		"spellpower":
			amount += int(user.get_spellpower() * pct)
		"awareness":
			amount += int(unit_attribute(user, "awareness") * pct)
		"focus":
			amount += int(unit_attribute(user, "focus") * pct)
	amount = maxi(1, amount)
	target.heal(amount)
	unit_healed.emit(target, amount)
	combat_log.emit("%s patches %s up for %d." % [user.unit_name, target.unit_name, amount])
	return {"success": true, "effects": [{"type": "heal", "target": target, "amount": amount}]}


## A trap is a zone that waits: nothing happens until somebody steps on it.
##
## Which is why it costs nothing new — zones already answer "who just walked
## in", and Trap Maker is that question with the trapper's Focus behind it.
func _resolve_place_trap(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var reach: int = int(combat_data.get("range", 1))
	if _grid_distance(user.grid_position, target_pos) > reach:
		return {"success": false, "reason": "Too far to reach the ground there"}
	if combat_grid != null and combat_grid.is_occupied(target_pos):
		return {"success": false, "reason": "Somebody is standing there"}

	var zone_id: String = str(combat_data.get("zone", "snare_trap"))
	var turns: int = int(combat_data.get("duration", 6))
	if not place_zone(zone_id, [target_pos], user, turns):
		return {"success": false, "reason": "The ground will not take it"}

	# The trap's bite scales with whoever set it, so a master trapper's snare
	# is worth stepping around.
	var focus: int = unit_attribute(user, "focus")
	var scaled: int = maxi(1, int(focus * float(combat_data.get("damage_pct_of_focus", 30)) / 100.0))
	active_zones[-1]["payload_scale"] = scaled
	combat_log.emit("%s sets a trap." % user.unit_name)
	return {"success": true, "effects": [{"type": "trap", "pos": target_pos}]}


## Everyone, somewhere else. One side of the field at a time, through the same
## repositioning vocabulary a single teleport uses.
func _resolve_mass_teleport(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var side: String = str(combat_data.get("side", "allies"))
	var spec: Dictionary = {
		"mode": str(combat_data.get("mode", "scatter")),
		"range": int(combat_data.get("tiles", 4)),
		"tiles": int(combat_data.get("tiles", 4)),
	}
	var moved: Array = []
	for unit in all_units:
		if unit.is_dead or not "team" in unit or not "grid_position" in unit:
			continue
		var same: bool = unit.team == user.team
		if (side == "allies" and not same) or (side == "enemies" and same):
			continue
		if combat_grid != null and not combat_grid.has_line_of_sight(
				user.grid_position, unit.grid_position):
			continue
		var result: Dictionary = reposition(unit, spec, user, target_pos)
		if result.get("ok", false):
			moved.append(unit)
	if moved.is_empty():
		return {"success": false, "reason": "Nobody to move"}
	combat_log.emit("%s rearranges the field — %d moved." % [user.unit_name, moved.size()])
	return {"success": true, "effects": [{"type": "mass_teleport", "count": moved.size()}]}


## Stand in front of somebody. Attacks aimed at them may find you instead.
func _resolve_guard_ally(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var ward: Node = get_unit_at(target_pos)
	if ward == null or ward == user or not ward.is_alive():
		return {"success": false, "reason": "No ally there"}
	if not "team" in ward or ward.team != user.team:
		return {"success": false, "reason": "Not an ally"}
	if _grid_distance(user.grid_position, target_pos) > int(combat_data.get("range", 1)):
		return {"success": false, "reason": "Out of reach"}

	_guarded[ward.get_instance_id()] = {
		"guard": user,
		"chance": float(combat_data.get("redirect_chance", 50)) / 100.0,
		"turns_left": int(combat_data.get("duration", 1)),
	}
	for entry in combat_data.get("statuses", []):
		_apply_status_effect(user, str(entry.get("status", "")), int(entry.get("duration", 1)))
	combat_log.emit("%s steps in front of %s." % [user.unit_name, ward.unit_name])
	return {"success": true, "effects": [{"type": "guard", "target": ward}]}


## Set while a spell that ignores resistance is resolving. A flag rather than a
## damage type, because the spell is ordinary in every other way — and cleared
## in the same breath it is set, so nothing can leak past one cast.
var _ignoring_resistance: bool = false


## Who is standing in front of whom: {warded_id: {guard, chance, turns_left}}.
var _guarded: Dictionary = {}


## The guard who may take this blow instead, or null.
func redirect_target(defender: Node, attacker: Node = null) -> Node:
	var entry: Dictionary = _guarded.get(defender.get_instance_id(), {})
	if entry.is_empty():
		return null
	var guard: Node = entry.get("guard")
	if guard == null or not is_instance_valid(guard) or guard.is_dead:
		_guarded.erase(defender.get_instance_id())
		return null
	if _grid_distance(guard.grid_position, defender.grid_position) > 2:
		return null   # they have been separated
	# And the blow has to be able to find them: stepping in front of somebody
	# only works if you are somewhere the attacker could have struck.
	if attacker != null and "grid_position" in attacker:
		var reach: int = attacker.get_attack_range() \
			if attacker.has_method("get_attack_range") else 1
		if _grid_distance(attacker.grid_position, guard.grid_position) > reach:
			return null
	if randf() > float(entry.get("chance", 0.5)):
		return null
	return guard


## Count down every guard, and forget the ones whose watch has ended.
func _tick_guards() -> void:
	for warded_id in _guarded.keys():
		var entry: Dictionary = _guarded[warded_id]
		entry.turns_left = int(entry.turns_left) - 1
		if int(entry.turns_left) <= 0:
			_guarded.erase(warded_id)


## The next spell this unit casts answers to no resistance.
##
## Too Fast to React is the only thing that does this, and it is a flag rather
## than a damage type because the spell is ordinary in every other way.
func _resolve_ignore_resistances(user: Node, combat_data: Dictionary) -> Dictionary:
	user.set_meta("ignore_resistances_next", true)
	for entry in combat_data.get("statuses", []):
		_apply_status_effect(user, str(entry.get("status", "")), int(entry.get("duration", 1)))
	combat_log.emit("%s gathers a spell nothing will turn." % user.unit_name)
	return {"success": true, "effects": [{"type": "ignore_resistances"}]}


## Count down every false image and dismiss the ones whose time is up.
func _tick_decoys() -> void:
	for i in range(all_units.size() - 1, -1, -1):
		var unit: Node = all_units[i]
		if not is_instance_valid(unit) or not unit.has_meta("decoy_turns_left"):
			continue
		var left: int = int(unit.get_meta("decoy_turns_left")) - 1
		unit.set_meta("decoy_turns_left", left)
		if left > 0:
			continue
		combat_log.emit("%s fades." % unit.unit_name)
		if combat_grid != null:
			combat_grid.remove_unit(unit)
		all_units.erase(unit)
		turn_order.erase(unit)
		unit.queue_free()


## One false image: a unit with no actions that draws attacks and cannot act.
##
## The illusion spell path built this inline; Smoke and Mirrors wants several
## of them, so it is a function now and both callers use it.
func _spawn_decoy(owner: Node, at: Vector2i, hp: int, duration: int) -> Node:
	if combat_grid == null or combat_grid.is_occupied(at):
		return null
	var decoy_data: Dictionary = {
		"name": "Decoy",
		"archetype_name": "Illusion",
		"max_hp": maxi(1, hp),
		"max_mana": 0,
		"actions": 0,        # an image cannot act
		"inventory": [], "skills": {}, "known_spells": [], "perks": [],
		"tags": ["illusion", "decoy"],
		"derived": {
			"max_hp": maxi(1, hp), "current_hp": maxi(1, hp),
			"max_mana": 0, "current_mana": 0,
			"max_stamina": 10, "current_stamina": 10,
			"initiative": 0, "movement": 0,
			"dodge": 60,     # hard to hit, which is what makes it worth swinging at
			"armor": 0, "crit_chance": 0, "accuracy": 0,
			"damage": 0, "damage_type": "none",
			"resistances": {},
		},
		"equipped_weapon": {"name": "None", "damage": 0, "damage_type": "none", "range": 1},
	}
	var decoy := CombatUnit.new()
	decoy.summoner_id = owner.get_instance_id()
	decoy.init_as_enemy(decoy_data)
	decoy.team = owner.team
	combat_grid.place_unit(decoy, at)
	all_units.append(decoy)
	turn_order.append(decoy)
	decoy.set_meta("decoy_turns_left", duration)
	unit_deployed.emit(decoy, at)
	return decoy


## A skill that offers several things and does one of them.
##
## The option is chosen by whoever called: the arena passes `chosen_option`
## when a player picks, and an AI or a test can pass one too. With no choice
## made it falls back to `default_option`, so the skill is usable before the
## picker UI exists rather than wired to its first branch as a stopgap.
##
## Each option names an `effect` and carries its own data, which is dispatched
## through the same table every other skill uses — a skill that offers three
## things does not want a second copy of the code that knows how to do them.
func _resolve_choose_one(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var options: Array = combat_data.get("options", [])
	if options.is_empty():
		return {"success": false, "reason": "Nothing to choose between"}

	var index: int = int(combat_data.get("chosen_option",
		combat_data.get("default_option", 0)))
	index = clampi(index, 0, options.size() - 1)
	var option: Dictionary = options[index]

	# The option inherits the skill's own fields — range, targeting, costs —
	# and overrides whatever it names itself.
	var merged: Dictionary = combat_data.duplicate(true)
	merged.erase("options")
	for key in option:
		merged[key] = option[key]

	var chosen_effect: String = str(option.get("effect", ""))
	if chosen_effect == "" or chosen_effect == "choose_one":
		return {"success": false, "reason": "That choice does nothing"}
	var result: Dictionary = _dispatch_skill_effect(user, chosen_effect, merged, target_pos)
	if bool(result.get("success", false)):
		combat_log.emit("%s chooses %s." % [user.unit_name,
			str(option.get("label", chosen_effect.replace("_", " ")))])
		result["chosen"] = index
	return result


## Spend a charm from the party's stores to empower the next spell of its
## school.
##
## Charms already existed as consumables that set `charm_buff`; what Attune
## Charm adds is a RITUAL reading of the same object — the charm is prepared
## rather than merely used, so it grants what the perk names on top of the
## charm's own mana discount.
func _resolve_consume_charm(user: Node, combat_data: Dictionary) -> Dictionary:
	var school: String = str(combat_data.get("school", ""))
	var found: String = ""
	for entry in ItemSystem.get_inventory():
		var item_id: String = str(entry.get("item_id", ""))
		var item: Dictionary = ItemSystem.get_item(item_id)
		if str(item.get("type", "")) != "charm":
			continue
		var charm_school: String = str(item.get("effect", {}).get("school", ""))
		if school != "" and charm_school != school:
			continue
		found = item_id
		break
	if found == "":
		return {"success": false, "reason": "No charm to attune"}

	var charm: Dictionary = ItemSystem.get_item(found)
	var effect: Dictionary = charm.get("effect", {})
	ItemSystem.remove_from_inventory(found, 1)
	user.charm_buff = {
		"school": str(effect.get("school", "")),
		"mana_reduction": float(effect.get("mana_reduction", 0.0)),
		"spellpower_bonus": float(effect.get("spellpower_bonus", 0.0))
			+ float(combat_data.get("spellpower_bonus", 0.0)),
		"duration_bonus": int(combat_data.get("duration_bonus", 0)),
		"accuracy_bonus": float(combat_data.get("accuracy_bonus", 0.0)),
	}
	combat_log.emit("%s attunes %s." % [user.unit_name, charm.get("name", found)])
	return {"success": true, "effects": [{"type": "charm",
		"school": user.charm_buff.school, "item": found}]}


## False images that draw attention and cannot act.
##
## The decoy machinery already existed on a spell path (`creates_illusion`);
## this is the same spawn, several times, from a skill.
func _resolve_create_images(user: Node, combat_data: Dictionary) -> Dictionary:
	if combat_grid == null:
		return {"success": false, "reason": "No battlefield"}
	var wanted: int = randi_range(int(combat_data.get("min_images", 1)),
		int(combat_data.get("max_images", 3)))
	var duration: int = int(combat_data.get("duration", 3))
	var made: Array = []
	for _i in range(wanted):
		var spot: Vector2i = _free_tile_near(user.grid_position, 2)
		if spot.x < 0:
			break
		var decoy: Node = _spawn_decoy(user, spot, int(combat_data.get("image_hp", 1)), duration)
		if decoy != null:
			made.append(decoy)
	if made.is_empty():
		return {"success": false, "reason": "No room for the images"}
	combat_log.emit("%s is suddenly several people." % user.unit_name)
	return {"success": true, "effects": [{"type": "images", "count": made.size()}]}


## The first free, walkable tile within `radius`, or (-1,-1).
func _free_tile_near(centre: Vector2i, radius: int) -> Vector2i:
	for r in range(1, radius + 1):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var at: Vector2i = centre + Vector2i(dx, dy)
				if combat_grid.is_valid_position(at) and not combat_grid.is_occupied(at) \
						and combat_grid.is_tile_walkable(at):
					return at
	return Vector2i(-1, -1)


## Take something off an enemy without their noticing.
##
## Consumables first, because a stolen potion is a stolen potion and a stolen
## breastplate is a fight. Does not break stealth: that is the whole point of
## the perk, and the attack path is never entered.
func _resolve_steal_item(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var mark: Node = get_unit_at(target_pos)
	if mark == null or not mark.is_alive():
		return {"success": false, "reason": "Nobody there"}
	if not "team" in mark or mark.team == user.team:
		return {"success": false, "reason": "Not a mark"}
	if _grid_distance(user.grid_position, target_pos) > int(combat_data.get("range", 1)):
		return {"success": false, "reason": "Too far to reach a pocket"}

	var inventory: Array = mark.character_data.get("inventory", [])
	var taken: String = ""
	for i in range(inventory.size()):
		var item_id: String = str(inventory[i])
		var item: Dictionary = ItemSystem.get_item(item_id)
		if item.is_empty():
			continue
		if str(item.get("type", "")) in ["potion", "bomb", "oil", "charm", "herb", "medicine"]:
			taken = item_id
			inventory.remove_at(i)
			break
	if taken == "" and not inventory.is_empty():
		taken = str(inventory[0])
		inventory.remove_at(0)
	if taken == "":
		return {"success": false, "reason": "Their pockets are empty"}

	ItemSystem.add_to_inventory(taken, 1)
	combat_log.emit("%s lifts %s off %s." % [user.unit_name,
		ItemSystem.get_item(taken).get("name", taken), mark.unit_name])
	return {"success": true, "effects": [{"type": "steal", "item": taken, "from": mark}]}


## Put a spell on an arrow. The next ranged attack delivers it on hit.
##
## The spell is chosen by the caller where a picker exists; absent one, the
## highest-level single-target spell the caster can afford, which is the
## choice an archer would make anyway.
func _resolve_imbued_attack(user: Node, combat_data: Dictionary) -> Dictionary:
	if not user.is_ranged_weapon():
		return {"success": false, "reason": "Needs a ranged weapon"}
	var spell_id: String = str(combat_data.get("spell", ""))
	if spell_id == "":
		spell_id = _best_imbuable_spell(user)
	if spell_id == "":
		return {"success": false, "reason": "No single-target spell to imbue"}
	var spell: Dictionary = get_spell(spell_id)
	var cost: int = int(spell.get("mana_cost", 0))
	if user.current_mana < cost:
		return {"success": false, "reason": "Not enough mana for %s" % spell.get("name", spell_id)}

	user.current_mana -= cost
	user.set_meta("imbued_spell", spell_id)
	combat_log.emit("%s draws with %s on the arrow."
		% [user.unit_name, spell.get("name", spell_id)])
	return {"success": true, "effects": [{"type": "imbue", "spell": spell_id}]}


## The best single-target spell this unit knows and can pay for.
func _best_imbuable_spell(user: Node) -> String:
	var best: String = ""
	var best_level: int = -1
	for spell_id in user.character_data.get("known_spells", []):
		var spell: Dictionary = get_spell(str(spell_id))
		if spell.is_empty():
			continue
		if str(spell.get("targeting", "")) != "single":
			continue
		if int(spell.get("mana_cost", 0)) > user.current_mana:
			continue
		if int(spell.get("level", 1)) > best_level:
			best_level = int(spell.get("level", 1))
			best = str(spell_id)
	return best


## Talk somebody out of the fight, or into your side of it.
##
## Two Charm saves, as the perk says: fail both and they join you, fail one and
## they simply stop. Joining means changing sides for THIS fight — whether a
## recruit stays afterwards is a companion question, and recorded as one.
func _resolve_recruit_or_pacify(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var mark: Node = get_unit_at(target_pos)
	if mark == null or not mark.is_alive():
		return {"success": false, "reason": "Nobody there"}
	if not "team" in mark or mark.team == user.team:
		return {"success": false, "reason": "They are already yours"}
	if _grid_distance(user.grid_position, target_pos) > int(combat_data.get("range", 4)):
		return {"success": false, "reason": "Too far to be heard"}

	var dc: int = int(combat_data.get("save_dc", 13))
	var failed := 0
	for _attempt in 2:
		if not SaveSystem.roll(mark, "charm", dc).success:
			failed += 1

	if failed >= 2:
		mark.team = user.team
		mark.set_meta("recruited_by_magnetism", true)
		# A recruit stops fighting for its old side immediately, which means
		# dropping whatever was making it fight.
		if "status_effects" in mark:
			for entry in mark.status_effects.duplicate():
				var def: Dictionary = _status_effects.get(str(entry.get("status", "")), {})
				if def.get("polarity", "") == "negative":
					_remove_status_by_name(mark, str(entry.get("status", "")))
		combat_log.emit("%s talks %s round — they change sides."
			% [user.unit_name, mark.unit_name])
		return {"success": true, "effects": [{"type": "recruit", "target": mark}]}

	if failed == 1:
		_apply_status_effect(mark, "Pacified", int(combat_data.get("pacify_duration", 3)), 0, user)
		combat_log.emit("%s gives %s pause." % [user.unit_name, mark.unit_name])
		return {"success": true, "effects": [{"type": "pacify", "target": mark}]}

	combat_log.emit("%s is unmoved." % mark.unit_name)
	return {"success": true, "effects": [{"type": "no_effect"}]}


## Put something on the ground that was not there before.
##
## Nine active perks wanted this and none of them could have it: Black Ice, Fog
## of War, Gravity Well, Raise Wall, Crumbling Avalanche, Improvised Barricade,
## Prepared Ground, Inscribed Circle and The Door Stands Open. What was missing
## was never the grid — `set_tile_obstacle`, `add_terrain_effect` and zones all
## existed — but a resolver that reads what a perk wants to place, and a
## DURATION for the things that should not be permanent.
##
## Three kinds of thing, any combination, declared in `places`:
##
##   {"zone": "black_ice", "aoe": {...}, "duration": 3}
##   {"terrain": "smoke", "radius": 2, "duration": 3}
##   {"obstacle": "barricade", "shape": "line", "length": 3, "duration": 4, "hp": 30}
func _resolve_create_terrain(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	if combat_grid == null:
		return {"success": false, "reason": "No battlefield"}

	var effects: Array = []
	var placed_anything := false
	var bonus: int = user.get_spellpower() if user.has_method("get_spellpower") else 0

	for spec in combat_data.get("places", []):
		var duration: int = int(spec.get("duration", 3))

		# --- A zone -------------------------------------------------------
		if spec.has("zone"):
			var footprint: Dictionary = spec.get("aoe",
				{"type": "circle", "size": 1, "origin": "target"})
			var where: Vector2i = user.grid_position \
				if str(spec.get("origin", "target")) == "caster" else target_pos
			var tiles: Array = AoEResolver.get_tiles(
				footprint, user.grid_position, where, combat_grid.grid_size)
			if place_zone(str(spec["zone"]), tiles, user, duration):
				placed_anything = true
				effects.append({"type": "zone", "zone": str(spec["zone"]),
					"tiles": tiles.size()})

		# --- A terrain effect on the tiles themselves ---------------------
		if spec.has("terrain"):
			var effect_id: int = _hazard_id(str(spec["terrain"]))
			var radius: int = int(spec.get("radius", 1))
			var centre: Vector2i = user.grid_position \
				if str(spec.get("origin", "target")) == "caster" else target_pos
			var touched := 0
			for tile in combat_grid.get_tiles_in_radius(centre, radius):
				combat_grid.add_terrain_effect(tile, effect_id, duration,
					int(spec.get("value", 0)))
				touched += 1
			if touched > 0:
				placed_anything = true
				effects.append({"type": "terrain", "effect": str(spec["terrain"]),
					"tiles": touched})

		# --- An obstacle, which now knows when to fall down ----------------
		if spec.has("obstacle"):
			var obstacle_id: int = _obstacle_id(str(spec["obstacle"]))
			var hp: int = int(spec.get("hp", -1))
			if hp < 0 and spec.has("hp_from_spellpower"):
				hp = maxi(10, int(bonus * float(spec["hp_from_spellpower"])))
			var spots: Array = _obstacle_footprint(user, spec, target_pos)
			var built := 0
			for spot in spots:
				if combat_grid.is_occupied(spot) or combat_grid.has_blocking_obstacle(spot):
					continue
				combat_grid.set_tile_obstacle(spot, obstacle_id, hp)
				_timed_obstacles.append({
					"pos": spot, "turns_left": duration, "owner": user,
				})
				built += 1
			if built > 0:
				placed_anything = true
				effects.append({"type": "obstacle", "obstacle": str(spec["obstacle"]),
					"tiles": built})

	if not placed_anything:
		return {"success": false, "reason": "Nowhere to put it"}
	return {"success": true, "effects": effects}


## The tiles an obstacle covers: one tile, or a line of them drawn across the
## caster's line of sight to the target, which is what a wall is for.
func _obstacle_footprint(user: Node, spec: Dictionary, target_pos: Vector2i) -> Array:
	var spots: Array = [target_pos]
	var length: int = int(spec.get("length", 1))
	if str(spec.get("shape", "tile")) != "line" or length <= 1:
		return spots
	# Perpendicular to the direction the wall is raised in, so it blocks rather
	# than points.
	var facing: Vector2i = _dir_toward(user.grid_position, target_pos)
	var across := Vector2i(-facing.y, facing.x)
	if across == Vector2i.ZERO:
		across = Vector2i(0, 1)
	spots.clear()
	var half: int = length / 2
	for step in range(-half, length - half):
		var at: Vector2i = target_pos + across * step
		if combat_grid.is_valid_position(at):
			spots.append(at)
	return spots


## Open a gate between two tiles: where you stand and where you point.
##
## The near end is the caster's own tile, so "between any two tiles you can
## see" costs the caster the ground they are on — which is the decision the
## perk is actually offering.
func _resolve_open_gate(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var zone_id: String = str(combat_data.get("zone", "open_door"))
	var turns: int = int(combat_data.get("duration", 3))
	var here: Array = [user.grid_position]
	var there: Array = [target_pos]
	if combat_grid != null and not combat_grid.is_valid_position(target_pos):
		return {"success": false, "reason": "Nowhere to open it onto"}
	if not place_gate(zone_id, here, there, user, turns):
		return {"success": false, "reason": "The door will not hold"}
	return {"success": true, "effects": [{"type": "gate", "from": here[0], "to": there[0]}]}


## Bring down something you put up, on whoever is standing near it.
##
## Only your own: `_collapse_placed_obstacle` looks through the obstacles this
## unit placed, so an avalanche cannot be called down out of a tree that was
## always there.
func _resolve_collapse_terrain(user: Node, combat_data: Dictionary,
		target_pos: Vector2i) -> Dictionary:
	var fallen: Dictionary = _collapse_placed_obstacle(user, target_pos)
	if fallen.is_empty():
		return {"success": false, "reason": "Nothing of yours to bring down"}

	var at: Vector2i = fallen.pos
	var radius: int = int(combat_data.get("radius", 2))
	var bonus: int = user.get_spellpower() if user.has_method("get_spellpower") else 0
	var damage: int = maxi(1, int(bonus * float(combat_data.get("damage_pct_of_spellpower", 50)) / 100.0))
	var element: String = str(combat_data.get("damage_type", "crushing"))
	var save_attr: String = str(combat_data.get("save_type", "constitution")).to_lower()
	var give: String = str(combat_data.get("status", ""))

	var effects: Array = []
	for unit in all_units:
		if unit == user or unit.is_dead or not "grid_position" in unit:
			continue
		if not "team" in unit or unit.team == user.team:
			continue
		if _grid_distance(at, unit.grid_position) > radius:
			continue
		apply_damage(unit, damage, element)
		effects.append({"type": "damage", "target": unit, "amount": damage})
		if give != "":
			# A fixed DC from data, raised by the user's Ritual because a
			# status is what rides on it.
			var roll: Dictionary = SaveSystem.roll(unit, save_attr,
				int(combat_data.get("save_dc", 13)) + status_save_dc_bonus(user))
			if not roll.success:
				_apply_status_effect(unit, give, int(combat_data.get("status_duration", 1)), 0, user)
	combat_log.emit("%s brings the stone down." % user.unit_name)
	return {"success": true, "effects": effects}


## Obstacles placed by a skill, which fall down again when their time runs out.
## The grid's own obstacles are permanent, and should be: these are the ones
## somebody built during a fight.
var _timed_obstacles: Array[Dictionary] = []


## Count down every placed obstacle and remove what has expired.
func _tick_placed_obstacles() -> void:
	for i in range(_timed_obstacles.size() - 1, -1, -1):
		var entry: Dictionary = _timed_obstacles[i]
		entry.turns_left = int(entry.turns_left) - 1
		if int(entry.turns_left) > 0:
			continue
		if combat_grid != null:
			combat_grid.remove_obstacle(entry.pos)
		_timed_obstacles.remove_at(i)


## Remove one obstacle `owner` placed, nearest to `near`, and say where it was.
## Crumbling Avalanche brings down your own wall; it should not be able to
## bring down a tree that was always there.
func _collapse_placed_obstacle(owner: Node, near: Vector2i) -> Dictionary:
	var best := -1
	var best_dist := 1 << 30
	for i in range(_timed_obstacles.size()):
		if _timed_obstacles[i].owner != owner:
			continue
		var dist: int = _grid_distance(near, _timed_obstacles[i].pos)
		if dist < best_dist:
			best_dist = dist
			best = i
	if best < 0:
		return {}
	var at: Vector2i = _timed_obstacles[best].pos
	if combat_grid != null:
		combat_grid.remove_obstacle(at)
	_timed_obstacles.remove_at(best)
	return {"pos": at}


## Terrain effect and obstacle names, resolved through the same words
## BattlefieldGenerator uses so the data reads the same everywhere.
func _hazard_id(name: String) -> int:
	match name:
		"fire":    return CombatGrid.TerrainEffect.FIRE
		"ice":     return CombatGrid.TerrainEffect.ICE
		"poison":  return CombatGrid.TerrainEffect.POISON
		"acid":    return CombatGrid.TerrainEffect.ACID
		"blessed": return CombatGrid.TerrainEffect.BLESSED
		"cursed":  return CombatGrid.TerrainEffect.CURSED
		"wet":     return CombatGrid.TerrainEffect.WET
		"stormy":  return CombatGrid.TerrainEffect.STORMY
		"void":    return CombatGrid.TerrainEffect.VOID
		"smoke":   return CombatGrid.TerrainEffect.SMOKE
	push_warning("CombatManager: no terrain effect named '%s'" % name)
	return CombatGrid.TerrainEffect.NONE


func _obstacle_id(name: String) -> int:
	match name:
		"tree":        return CombatGrid.ObstacleType.TREE
		"rock":        return CombatGrid.ObstacleType.ROCK
		"pillar":      return CombatGrid.ObstacleType.PILLAR
		"barricade":   return CombatGrid.ObstacleType.BARRICADE
		"fallen_tree": return CombatGrid.ObstacleType.FALLEN_TREE
	push_warning("CombatManager: no obstacle named '%s'" % name)
	return CombatGrid.ObstacleType.NONE


## Process status spread: a status's `spread` {to, reach?, chance, when} lets it
## jump, with `chance` percent each turn, to one unit within `reach` tiles
## (default 1, adjacent) that does not have it yet. Called once per unit per
## turn, after normal status processing.
func _process_status_spread(unit: Node) -> void:
	if not "status_effects" in unit or unit.status_effects.is_empty():
		return

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var def = _status_effects.get(status_name, {})
		var spread: Dictionary = def.get("spread", {})
		if spread.is_empty() or str(spread.get("when", "turn_start")) != "turn_start":
			continue

		var chance: float = float(spread.get("chance", 0)) / 100.0
		if chance <= 0.0 or randf() > chance:
			continue

		var reach: int = maxi(1, int(spread.get("reach", 1)))
		var adjacent = _get_units_in_range(unit, reach)
		for adj in adjacent:
			if adj.is_dead or adj.is_bleeding_out:
				continue
			if not adj.has_status(status_name):
				var spread_duration = int(def.get("duration", {}).get("base", 2))
				_apply_status_effect(adj, status_name, spread_duration)
				break  # Spread to one unit per tick


## Fire the per-turn effects of every aura this unit emits.
##
## Called once per unit per turn. The unit's own auras tick on its own turn,
## which is what keeps a two-emitter fight from healing anyone twice per round.
##
## Only the effects that happen resolve here (status, heal, damage). An aura's
## `modify` effects are read-time: they are added up where the number is read,
## so that stepping out of an aura removes them with no bookkeeping. See
## AuraSystem.
##
## Reactive effects are not auras and stay where they are: the lightning
## retaliation on Storm_Lord and Lightning_Form fires when someone attacks, and
## Magnetizing_Aura's charm fires on approach. An aura is a standing field; a
## trigger is a response.
func _process_auras(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or unit.is_dead:
		return
	if not "grid_position" in unit:
		return

	for aura in AuraSystem.emitted_by(unit):
		var effects: Array = AuraSystem.per_turn_effects(aura)
		if effects.is_empty():
			continue
		for target in all_units:
			if not is_instance_valid(target) or not "grid_position" in target:
				continue
			var dist: int = _grid_distance(unit.grid_position, target.grid_position)
			if not AuraSystem.reaches(aura, unit, target, dist):
				continue
			_resolve_area_effects(unit, target, aura, effects,
				AuraSystem.sign_for(aura, unit, target), "aura")


## Resolve the effects of one aura or zone (`area`: its id, name and, for a
## status-carried aura, `status_entry`) on one unit inside it, through
## EffectResolver, and show what happened.
##
## The context: `source` (the emitter, or the zone's owner, maybe null) is the
## caster, `target` the recipient and its tile the position, the area the
## container. The damage names no dealer, as an aura's never has. A heal on a
## unit already at full HP is skipped, so no "+0" floats up. For a unit on the
## far side of an `invert_for_enemies` aura (`sign_mult` -1) a heal or damage
## does nothing, as a negative amount always did.
##
## Effects resolve one at a time so each popup can say what that one did (a
## zone's popups use the "aura" colour, as they always have); they share one
## context, so one save is rolled per recipient.
func _resolve_area_effects(source: Node, target: Node, area: Dictionary, effects: Array,
		sign_mult: float, kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if effects.is_empty() or target == null or not is_instance_valid(target):
		return out
	var ctx := EffectContext.new()
	ctx.caster = source
	ctx.target = target
	ctx.area_units = [target]
	ctx.target_pos = target.grid_position
	ctx.container_kind = kind
	ctx.container_id = str(area.get("id", ""))
	ctx.status_entry = area.get("status_entry", {})
	ctx.anonymous_damage = true
	var name: String = str(area.get("name", ctx.container_id))
	for e in effects:
		var op: String = str(e.get("op", ""))
		if op in ["heal", "damage"] and sign_mult < 0.0:
			continue
		if op == "heal" and target.current_hp >= target.max_hp:
			continue
		var hp_before: int = target.current_hp
		var log: Array[Dictionary] = EffectResolver.resolve([e], ctx)
		out.append_array(log)
		for entry in log:
			match op:
				"heal":
					var healed: int = target.current_hp - hp_before
					if healed > 0:
						unit_healed.emit(target, healed)
						status_effect_triggered.emit(source, name, healed, "aura")
				"damage":
					if entry.applied:
						status_effect_triggered.emit(source, name, int(entry.amount), "aura")
				"status":
					# Landed or resisted: either way the field reached them.
					if entry.applied or entry.reason == "resisted":
						status_effect_triggered.emit(source, name, 0, "aura")
	return out


## Recompute every unit's aura-granted max HP.
##
## stat.max_hp is the one number that cannot only be read on demand, because
## current_hp has to be clamped when the bonus goes away. So it is stored — and
## applied as a DELTA against what this function set last time, which makes a
## repeated call a no-op instead of a doubling. That distinction is the whole
## reason mana_cost_reduction once reached -500 in this codebase.
func _refresh_aura_max_hp() -> void:
	for unit in all_units:
		if not is_instance_valid(unit) or unit.is_dead:
			continue
		if not "grid_position" in unit or not "aura_max_hp" in unit:
			continue
		# Every fortify / drain on stat.max_hp: the auras and zones reaching
		# the unit and any hold a status placed (ValuePaths.flat_sum).
		var want: int = int(round(ValuePaths.flat_sum(unit, "stat.max_hp")))
		var delta: int = want - unit.aura_max_hp
		if delta == 0:
			continue
		unit.aura_max_hp = want
		unit.max_hp = maxi(1, unit.max_hp + delta)
		if delta > 0:
			# Walking into a protective aura should feel like protection, so the
			# granted HP arrives filled rather than as an empty bar extension.
			unit.current_hp += delta
		unit.current_hp = clampi(unit.current_hp, 1, unit.max_hp)


## Any movement can move a unit into or out of a max_hp aura, so recheck all of
## them. Cheap: a refresh that changes nothing exits on a zero delta.
func _on_unit_moved_refresh_auras(_unit: Node, _from: Vector2i, _to: Vector2i) -> void:
	_refresh_aura_max_hp()


## Crossing into a zone is a movement event, so it rides the movement signal —
## which means a push, a teleport and a walk all trigger it alike.
func _on_unit_moved_check_zones(unit: Node, _from: Vector2i, _to: Vector2i) -> void:
	_zones_check_entry(unit)


## Distance between two units, as AuraSystem wants it: a Callable, so that file
## never needs to know how this grid measures itself.
func _aura_distance(a: Node, b: Node) -> int:
	if not "grid_position" in a or not "grid_position" in b:
		return 9999
	return _grid_distance(a.grid_position, b.grid_position)


## Get all alive allied units within range of source (same team, excludes self)
func _get_allies_in_range(source: Node, radius: int) -> Array[Node]:
	var result: Array[Node] = []
	for u in all_units:
		if u == source or u.is_dead:
			continue
		if u.team == source.team and _grid_distance(source.grid_position, u.grid_position) <= radius:
			result.append(u)
	return result


## Get all alive enemy units within range of source (different team)
func _get_enemies_in_range(source: Node, radius: int) -> Array[Node]:
	var result: Array[Node] = []
	for u in all_units:
		if u == source or u.is_dead:
			continue
		if u.team != source.team and _grid_distance(source.grid_position, u.grid_position) <= radius:
			result.append(u)
	return result


## Get all alive units within a given range of a source unit
func _get_units_in_range(source: Node, radius: int) -> Array[Node]:
	var result: Array[Node] = []
	for u in all_units:
		if u == source or u.is_dead:
			continue
		if _grid_distance(source.grid_position, u.grid_position) <= radius:
			result.append(u)
	return result


## A weapon attack has just hit `defender`. First the reactions its
## intercepting triggers chose before the blow (a counter-attack) answer it,
## then its `struck` triggers fire: Fireshield's flames, Pain Mirror's
## reflection, Lightning Form's shock and stun. A trigger with `reach` 1
## answers only a melee attacker; one without answers any.
func _process_reactive_statuses(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not "status_effects" in defender:
		return
	_run_pending_triggers(result.get("_pending_reactions", []))
	result.erase("_pending_reactions")

	var distance: int = _grid_distance(attacker.grid_position, defender.grid_position)
	var is_melee: bool = distance <= 1
	var info := {"source": attacker, "damage": int(result.get("damage", 0))}
	for effect in defender.status_effects.duplicate():
		if _status_entry_index(defender, effect) == -1:
			continue
		var status_name = effect.get("status", "")
		var def = _status_effects.get(status_name, {})
		var triggers: Array = def.get("triggers", [])
		for i in triggers.size():
			var trigger = triggers[i]
			if typeof(trigger) != TYPE_DICTIONARY or str(trigger.get("on", "")) != "struck":
				continue
			if trigger.has("reach") and distance > trigger_reach(trigger, defender):
				continue
			_announce_trigger(defender, status_name, _run_status_trigger(defender, effect, i, info))

		# Magnetizing Aura — chance to charm melee attackers. Kept as a flag: the
		# charm it gives has no source, which a `status` op would set to the
		# carrier (and so stop the charmed unit attacking it).
		if StatusRules.def_has_flag(def, "charm_chance_on_enemy_melee_approach") and is_melee:
			# 25% chance to charm the attacker for 1 turn, raised by Ritual
			if randf() < ritual_chance(defender, 0.25):
				_apply_status_effect(attacker, "Charmed", 1)
				status_effect_triggered.emit(defender, status_name, 0, "reactive")


## A unit's weapon attack has just hit `defender`: its statuses' `hit`
## triggers fire (Burning_Weapon's extra fire, Electrified_Weapon's lightning:
## a fifth of the hit again, rounded up, at least 1). `source` in those
## effects is the unit that was hit.
func _process_status_weapon_enchants(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not "status_effects" in attacker:
		return
	var info := {"source": defender, "damage": int(result.get("damage", 0))}
	for entry in attacker.status_effects.duplicate():
		if _status_entry_index(attacker, entry) != -1:
			_fire_status_triggers(attacker, entry, "hit", info)


## Process stat modifier durations
func _process_stat_modifiers(unit: Node) -> void:
	if not "stat_modifiers" in unit or unit.stat_modifiers.is_empty():
		return

	var to_remove: Array[int] = []

	for i in range(unit.stat_modifiers.size()):
		var mod = unit.stat_modifiers[i]
		mod.duration -= 1

		if mod.duration <= 0:
			to_remove.append(i)

	# Remove expired modifiers
	to_remove.reverse()
	for idx in to_remove:
		unit.stat_modifiers.remove_at(idx)


## Process terrain effects for a unit (fire, poison, blessed ground, etc.)
## Flying units are completely immune. Levitating units are immune to damaging effects
## but still benefit from blessed ground.
func _process_terrain_effects(unit: Node) -> void:
	if combat_grid == null:
		return

	# Check movement mode for terrain immunity
	var movement_mode = unit.get_movement_mode() if unit.has_method("get_movement_mode") else CombatGrid.MovementMode.NORMAL
	if movement_mode == CombatGrid.MovementMode.FLYING:
		return  # Flying units are fully immune to all ground effects

	var grid_pos = unit.grid_position
	var terrain = combat_grid.get_terrain_effect(grid_pos)

	if terrain.is_empty():
		return

	var effect = terrain.effect
	var value = terrain.value
	var effect_name = combat_grid.get_effect_name(effect)

	# What this effect does comes from CombatGrid.TERRAIN_HAZARDS — the same
	# table the tile hover tooltip reads, so the two can never disagree.
	var hazard: Dictionary = CombatGrid.TERRAIN_HAZARDS.get(effect, {})
	if hazard.is_empty():
		return
	var benign: bool = bool(hazard.get("heals", false))

	# Levitating units are immune to damaging ground effects (still get blessed)
	if movement_mode == CombatGrid.MovementMode.LEVITATE and not benign:
		return

	# Status-based terrain immunity (Levitating, Flying statuses even without movement mode set)
	if StatusRules.has_flag(unit, "immune_to_ground_effects") or StatusRules.has_flag(unit, "immune_to_terrain_hazards"):
		if not benign:
			return

	# Water_Walking: immune to water/wet terrain effects
	if StatusRules.has_flag(unit, "immune_to_water_terrain") and bool(hazard.get("water", false)):
		return

	# Healing ground
	if benign:
		unit.heal(value)
		unit_healed.emit(unit, value)
		terrain_heal.emit(unit, value, effect_name)
		return

	# Damage, if the effect deals any
	var damage_type: String = str(hazard.get("damage_type", ""))
	if damage_type != "":
		apply_damage(unit, value, damage_type)

	# The matching status (Burning on fire, Slowed on ice...) — only when the
	# unit does not already have it, and only on a successful roll for the
	# chance-based ones (cursed ground, storms).
	var status_name: String = str(hazard.get("status", ""))
	if status_name != "" and randf() < float(hazard.get("status_chance", 1.0)):
		var blocked: bool = unit.has_status(status_name)
		for other in hazard.get("status_blocked_by", []):
			if unit.has_status(str(other)):
				blocked = true
		if not blocked:
			_apply_status_effect(unit, status_name, int(hazard.get("status_turns", 1)))

	# A second status some ground adds as well — wet ground leaves you Soaked
	# (vulnerable to lightning) on top of slowing you.
	var also: String = str(hazard.get("also_status", ""))
	if also != "" and not unit.has_status(also):
		_apply_status_effect(unit, also, int(hazard.get("status_turns", 1)))

	if damage_type != "":
		terrain_damage.emit(unit, value, effect_name)


## Create ground effects on tiles from AoE damage (fire leaves fire, ice leaves ice, etc.)
## Also damages obstacles caught in the area
func _create_ground_effects_from_damage(center: Vector2i, radius: int, damage_type: String, duration: int = 2) -> void:
	if combat_grid == null:
		return

	var tiles_in_area = combat_grid.get_tiles_in_radius(center, radius)

	# Damage obstacles in the area (AoE hits everything)
	for pos in tiles_in_area:
		var tile = combat_grid.tiles.get(pos)
		if tile != null and tile.obstacle != CombatGrid.ObstacleType.NONE and tile.obstacle_hp > 0:
			# AoE deals roughly 10 damage to obstacles
			combat_grid.damage_obstacle(pos, 10, damage_type)

	var effect_type = DAMAGE_TYPE_TO_TERRAIN_EFFECT.get(damage_type, -1)
	# Handle composite damage types (e.g., "fire_black" → fire terrain, "physical_fire" → fire)
	if effect_type < 0 and "_" in damage_type:
		for part in damage_type.split("_"):
			effect_type = DAMAGE_TYPE_TO_TERRAIN_EFFECT.get(part, -1)
			if effect_type >= 0:
				break  # Use the first element that maps to a terrain effect
	if effect_type < 0:
		return  # No ground effect for this damage type (physical, etc.)

	for pos in tiles_in_area:
		var tile = combat_grid.tiles.get(pos)
		if tile != null and tile.walkable:
			combat_grid.add_terrain_effect(pos, effect_type, duration)


## Check if unit is currently incapacitated by status effects
func is_unit_incapacitated(unit: Node) -> bool:
	if not "status_effects" in unit:
		return false

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		if StatusRules.def_has_any_flag(effect_def, ["skip_turn", "cannot_act"]):
			return true

	return false


## Check if unit can move (not blocked by effects)
func can_unit_move(unit: Node) -> bool:
	if not "status_effects" in unit:
		return true

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		if StatusRules.def_has_any_flag(effect_def, ["cannot_move", "rooted"]):
			return false

	return true


## Check if unit can cast spells (not silenced/blinded)
func can_unit_cast(unit: Node) -> bool:
	if not "status_effects" in unit:
		return true

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		if StatusRules.def_has_any_flag(effect_def, ["cannot_cast"]):
			return false

	return true


## Check if unit can make weapon attacks (not Forgetful/Pacified)
func can_unit_attack(unit: Node) -> bool:
	if not "status_effects" in unit:
		return true

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		if StatusRules.def_has_any_flag(effect_def, ["cannot_attack", "will_not_attack"]):
			return false

	return true


## Get the CC behavior override for a unit, if any.
## Returns a string indicating forced behavior, or "" for no CC override.
## CC behaviors (checked in priority order):
##   "stunned"  — skip turn (already handled by the skip_turn / cannot_act flags)
##   "feared"   — flee away from fear source each turn
##   "confused" — move randomly, attack random adjacent target
##   "berserk"  — attack nearest creature regardless of team
##   "charmed"  — won't attack the caster, treats them as ally
##   "pacified" — won't attack anyone, can only move or end turn
func get_cc_behavior(unit: Node) -> String:
	if not "status_effects" in unit:
		return ""

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})

		# Feared — flee from source (highest priority after stun)
		if StatusRules.def_has_flag(effect_def, "flee_from_source"):
			return "feared"

		# Confused — random movement and targeting
		if StatusRules.def_has_any_flag(effect_def, ["random_movement", "random_target"]):
			return "confused"

		# Berserk — attack nearest regardless of allegiance
		if StatusRules.def_has_any_flag(effect_def, ["attacks_closest_creature", "ignores_allegiance"]):
			return "berserk"

		# Charmed — won't attack caster
		if StatusRules.def_has_any_flag(effect_def, ["will_not_attack_caster", "treats_caster_as_ally"]):
			return "charmed"

		# Pacified — won't fight
		if StatusRules.def_has_any_flag(effect_def, ["will_not_attack", "disengaged_from_combat"]):
			return "pacified"

	return ""


## Get the source unit of a CC effect (the caster who applied it).
## Used for Feared (flee from source) and Charmed (won't attack caster).
func get_cc_source(unit: Node, cc_type: String) -> Node:
	if not "status_effects" in unit:
		return null

	var target_effects: Array[String] = []
	match cc_type:
		"feared":
			target_effects = ["flee_from_source"]
		"charmed":
			target_effects = ["will_not_attack_caster", "treats_caster_as_ally"]

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})

		for te in target_effects:
			if StatusRules.def_has_flag(effect_def, te):
				# The source is stored on the effect instance when applied
				var source_ref = effect.get("source", null)
				if source_ref is Node and is_instance_valid(source_ref):
					return source_ref

	return null


## Get valid target positions for a spell
func get_spell_targets(caster: Node, spell_id: String) -> Array[Vector2i]:
	var spell = get_spell(spell_id)
	if spell.is_empty():
		return []

	var valid_positions: Array[Vector2i] = []
	var targeting = spell.get("targeting", "single")
	var spell_range = spell.get("range", 1)

	match targeting:
		"self":
			valid_positions.append(caster.grid_position)

		"single":
			# Any enemy in range (Manhattan/diamond for spells)
			var caster_true_sight = "see_through_stealth" in caster and caster.see_through_stealth
			for unit in all_units:
				if not unit.is_alive():
					continue
				if unit.team == caster.team:
					continue
				# Stealthed/invisible units cannot be targeted unless caster has true sight
				if not unit.is_targetable() and not caster_true_sight:
					continue
				var dist = spell_distance(caster.grid_position, unit.grid_position)
				if dist <= spell_range:
					valid_positions.append(unit.grid_position)

		"single_ally":
			# Any ally in range
			for unit in all_units:
				if not unit.is_alive():
					continue
				if unit.team != caster.team:
					continue
				var dist = spell_distance(caster.grid_position, unit.grid_position)
				if dist <= spell_range:
					valid_positions.append(unit.grid_position)

		"single_corpse":
			# Downed allies, dead or still bleeding. This is the tile-highlight
			# path, so excluding the dead here meant a resurrection could not
			# even be aimed at one.
			for unit in all_units:
				if not (unit.is_bleeding_out or unit.is_dead):
					continue
				if unit.team != caster.team:
					continue
				var dist = spell_distance(caster.grid_position, unit.grid_position)
				if dist <= spell_range:
					valid_positions.append(unit.grid_position)

		"aoe", "chain":
			# Any position in range (for AoE center selection)
			if combat_grid:
				for x in range(combat_grid.grid_size.x):
					for y in range(combat_grid.grid_size.y):
						var pos = Vector2i(x, y)
						var dist = spell_distance(caster.grid_position, pos)
						if dist <= spell_range:
							valid_positions.append(pos)

		"ground":
			# Summoning spells: any unoccupied, walkable tile in range
			if combat_grid:
				for x in range(combat_grid.grid_size.x):
					for y in range(combat_grid.grid_size.y):
						var pos = Vector2i(x, y)
						var dist = spell_distance(caster.grid_position, pos)
						if dist <= spell_range and combat_grid.is_valid_position(pos) and not combat_grid.is_occupied(pos):
							valid_positions.append(pos)

	return valid_positions


# ============================================
# CONSUMABLE ITEMS
# ============================================

## Use a consumable item in combat
## Self-targeting: potions, charms, oils (target_pos ignored)
## Targeted: scrolls, bombs (target_pos = aim position)
func use_combat_item(user: Node, item_id: String, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return {"success": false, "reason": "Item not found"}

	if ItemSystem.get_inventory_count(item_id) <= 0:
		return {"success": false, "reason": "None in inventory"}

	var item_type = item.get("type", "")

	# Pre-validate targeting BEFORE consuming the item
	if item_type == "scroll":
		var spell_id = item.get("spell_id", "")
		var spell = get_spell(spell_id)
		if spell.is_empty():
			return {"success": false, "reason": "Unknown spell on scroll"}
		var targeting = spell.get("targeting", "single")
		if targeting != "self":
			var spell_range = spell.get("range", 1)
			var distance = spell_distance(user.grid_position, target_pos)
			if distance > spell_range:
				return {"success": false, "reason": "Target out of range"}
			var targets = _get_spell_targets(user, spell, target_pos)
			if targets.is_empty():
				return {"success": false, "reason": "No valid targets"}
	elif item_type == "bomb":
		var effect = item.get("effect", {})
		var bomb_range = effect.get("range", 4)
		var distance = spell_distance(user.grid_position, target_pos)
		if distance > bomb_range:
			return {"success": false, "reason": "Target out of range"}

	# A potion, medicine or herb can be given to an adjacent ally instead
	var recipient: Node = user
	if item_type in HANDED_ITEM_TYPES:
		var handed := handed_item_recipient(user, target_pos)
		if not handed.has("recipient"):
			return {"success": false, "reason": handed.reason}
		recipient = handed.recipient

	# Consume the item from inventory
	var consume_result = ItemSystem.use_consumable(item_id)
	if not consume_result.success:
		return consume_result

	# Apply the effect based on item type
	var result: Dictionary = {}
	match item_type:
		"potion":
			result = _apply_potion_effect(user, item, recipient)
			result["recipient"] = recipient
		"scroll":
			result = _use_scroll(user, item, target_pos)
		"charm":
			result = _apply_charm(user, item)
		"bomb":
			result = _use_bomb(user, item, target_pos)
		"oil":
			result = _apply_oil(user, item)
		"medicine", "herb":
			result = _apply_potion_effect(user, item, recipient)
			result["recipient"] = recipient
			# Field Surgeon (Medicine 6): on success, attempt to treat one wound
			# mid-combat — the user's training, the recipient's wound
			if result.get("success", false) and WoundSystem and PerkSystem.has_perk(user.character_data, "field_surgeon"):
				var wounds := WoundSystem.get_wounds(recipient.character_data)
				if not wounds.is_empty():
					var med_level := CharacterSystem.get_effective_skill_level(user.character_data, "medicine")
					var roll := randi_range(1, 20) + med_level
					if roll >= 14:
						var wound_id: String = wounds[0].get("id", "")
						var wdef: Dictionary = WoundSystem.WOUND_TYPES.get(wound_id, {})
						WoundSystem.cure_wound(recipient.character_data, wound_id)
						combat_log.emit("%s's field surgeon training — %s's %s treated mid-combat!" % [
							user.unit_name, recipient.unit_name, wdef.get("display_name", wound_id)
						])
					else:
						combat_log.emit("%s attempts field surgery — conditions too chaotic. (Rolled %d, need 14)" % [user.unit_name, roll])
		_:
			return {"success": false, "reason": "Unknown consumable type: " + item_type}

	if result.get("success", false):
		use_action(1)
		item_used_in_combat.emit(user, item, result)

	return result


## Apply potion effects. `user` is whoever administers it (their Alchemy sets
## the strength); `recipient` is who it lands on — the user unless given
## (AI units can hand a potion to an adjacent ally, see ai_use_combat_item).
func _apply_potion_effect(user: Node, item: Dictionary, recipient: Node = null) -> Dictionary:
	var effect = item.get("effect", {})
	var effect_type = effect.get("type", "")
	var result = {"success": true, "effects_applied": []}

	# Alchemy skill bonus: increases potion effectiveness
	var alchemy_bonus = _get_alchemy_bonus(user)
	# From here on `user` means the one drinking it
	if recipient != null:
		user = recipient

	match effect_type:
		"heal":
			var base_value = effect.get("value", 0)
			var heal_amount = int(base_value * (1.0 + alchemy_bonus / 100.0))
			user.heal(heal_amount)
			unit_healed.emit(user, heal_amount)
			result.effects_applied.append({"type": "heal", "amount": heal_amount})

		"restore_mana":
			var base_value = effect.get("value", 0)
			var mana_amount = int(base_value * (1.0 + alchemy_bonus / 100.0))
			user.current_mana = mini(user.max_mana, user.current_mana + mana_amount)
			result.effects_applied.append({"type": "restore_mana", "amount": mana_amount})

		"buff":
			var value = effect.get("value", 0)
			var duration = effect.get("duration", 3)
			# Check if it's a resistance buff
			var resistance_type = effect.get("resistance", "")
			if resistance_type != "":
				# Apply as a status effect with resistance boost
				var status_name = effect.get("status", "Buffed")
				_apply_status_effect(user, status_name, duration, value)
				result.effects_applied.append({
					"type": "buff", "status": status_name,
					"resistance": resistance_type, "value": value, "duration": duration
				})
			else:
				var stat = effect.get("stat", "")
				_apply_stat_modifier(user, stat, value, duration)
				result.effects_applied.append({
					"type": "buff", "stat": stat, "value": value, "duration": duration
				})

		"cleanse":
			var statuses_to_remove = effect.get("statuses_removed", [])
			var removed_count = 0
			for i in range(user.status_effects.size() - 1, -1, -1):
				var se = user.status_effects[i]
				if se.get("status", "") in statuses_to_remove:
					var removed_name = se.get("status", "")
					_end_status(user, se, "cleansed")
					status_effect_expired.emit(user, removed_name)
					removed_count += 1
			result.effects_applied.append({"type": "cleanse", "removed": removed_count})

		_:
			result.success = false
			result["reason"] = "Unknown potion effect: " + effect_type

	return result


## Use a scroll: cast the referenced spell without mana cost or skill requirement
func _use_scroll(user: Node, item: Dictionary, target_pos: Vector2i) -> Dictionary:
	var spell_id = item.get("spell_id", "")
	var spell = get_spell(spell_id)
	if spell.is_empty():
		return {"success": false, "reason": "Unknown spell on scroll: " + spell_id}

	# Get targets using existing targeting logic
	var targets = _get_spell_targets(user, spell, target_pos)

	# Self-targeting spells target the caster
	if spell.get("targeting", "single") == "self" and targets.is_empty():
		targets.append(user)

	# Baseline scroll power: equivalent to Focus 16 + max(5, spell level) per school
	# This makes scrolls useful regardless of who casts them
	var baseline_spellpower := 16
	var spell_schools: Array = spell.get("schools", [])
	var baseline_school_bonus := 0
	for school in spell_schools:
		var school_lower: String = str(school).to_lower()
		var skill_name: String = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space", "white", "black"] else school_lower
		var min_skill_level := maxi(5, spell.get("level", 1))
		baseline_school_bonus += min_skill_level * 2
	var scroll_bonus = baseline_spellpower + baseline_school_bonus + item.get("spell_bonus", 0)

	# Apply effects using existing spell effect system
	var results: Array[Dictionary] = []
	for target in targets:
		var effect_result = _apply_spell_effects(user, target, spell, scroll_bonus)
		results.append(effect_result)

	return {
		"success": true,
		"spell": spell,
		"targets": targets,
		"results": results,
		"is_scroll": true
	}


## Get valid target positions for a scroll item (wraps spell targeting)
func get_scroll_targets(user: Node, item_id: String) -> Array[Vector2i]:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty() or item.get("type", "") != "scroll":
		return []
	var spell_id = item.get("spell_id", "")
	return get_spell_targets(user, spell_id)


## Get the throw range for a bomb item
func get_bomb_range(item_id: String) -> int:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty() or item.get("type", "") != "bomb":
		return 0
	return item.get("effect", {}).get("range", 4)


## Get the AoE radius for a bomb item
func get_bomb_aoe_radius(item_id: String) -> int:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty() or item.get("type", "") != "bomb":
		return 0
	return item.get("effect", {}).get("aoe_radius", 1)


## Get Alchemy skill consumable_power bonus percentage
## Matches perks.json: 10/20/35/50/75 per skill level
## Alchemy's effect on a consumable, as a percentage.
##
## This was a six-entry table indexed by skill level, written when skills capped
## at 5. Skills have gone to 10 since, and the out-of-range branch returned 0.0 —
## so Alchemy 6 through 10 gave no bonus at all while Alchemy 5 gave 75%, and
## levelling the skill past 5 made your potions worse. It reads
## consumable_power_pct from the per-level table now, which covers every level
## and can be tuned in data.
func _get_alchemy_bonus(user: Node) -> float:
	if not "character_data" in user:
		return 0.0
	return float(user.character_data.get("derived", {}).get("consumable_power_pct", 0.0))


## Apply a charm: stores a buff on the unit that reduces mana cost of the next matching spell
func _apply_charm(user: Node, item: Dictionary) -> Dictionary:
	var effect = item.get("effect", {})
	var school = effect.get("school", "")
	var mana_reduction = effect.get("mana_reduction", 0.0)
	var spellpower_bonus = effect.get("spellpower_bonus", 0.0)

	# Overwrite any existing charm (only one active at a time)
	user.charm_buff = {
		"school": school,
		"mana_reduction": mana_reduction,
		"spellpower_bonus": spellpower_bonus
	}

	return {
		"success": true,
		"effects_applied": [{
			"type": "charm",
			"school": school,
			"mana_reduction": mana_reduction,
			"spellpower_bonus": spellpower_bonus
		}]
	}


## Use a bomb: deal AoE damage at target position, optionally apply status effects
func _use_bomb(user: Node, item: Dictionary, target_pos: Vector2i) -> Dictionary:
	var effect = item.get("effect", {})
	var base_damage = effect.get("damage", 0)
	var damage_type = effect.get("damage_type", "fire")
	var aoe_radius = effect.get("aoe_radius", 1)
	var statuses = effect.get("statuses", [])
	var hits_all = effect.get("hits_all", false)  # true = hits allies too (smoke bomb)

	# Alchemy bonus increases bomb damage
	var alchemy_bonus = _get_alchemy_bonus(user)
	var total_damage = int(base_damage * (1.0 + alchemy_bonus / 100.0))

	# Bomb scatter: low Alchemy skill means the throw can land off-target by 1 tile.
	# Alchemy 0 → 50% scatter chance; Alchemy 3+ → no scatter.
	var actual_target_pos := target_pos
	var bomb_scattered := false
	var alchemy_level: int = unit_skill(user, "alchemy")
	var scatter_chance := maxf(0.0, 50.0 - alchemy_level * 17.0)
	if scatter_chance > 0.0 and randf() * 100.0 < scatter_chance:
		var scatter_dir: Vector2i = DIRS_8[randi() % DIRS_8.size()]
		actual_target_pos = target_pos + scatter_dir
		if combat_grid != null:
			actual_target_pos.x = clampi(actual_target_pos.x, 0, combat_grid.grid_size.x - 1)
			actual_target_pos.y = clampi(actual_target_pos.y, 0, combat_grid.grid_size.y - 1)
		bomb_scattered = true
		combat_log.emit("  Bomb lands off-target — scattered 1 tile!")

	# Find units in AoE
	var hit_units: Array[Node] = []
	for unit in all_units:
		if not unit.is_alive():
			continue
		var dist = _grid_distance(unit.grid_position, actual_target_pos)
		if dist <= aoe_radius:
			if hits_all:
				hit_units.append(unit)
			elif unit.team != user.team:
				hit_units.append(unit)

	var results: Array[Dictionary] = []
	for target in hit_units:
		var unit_result: Dictionary = {"target": target, "effects_applied": []}

		# Apply damage (respects resistance)
		if total_damage > 0:
			apply_damage(target, total_damage, damage_type)
			unit_result.effects_applied.append({
				"type": "damage", "amount": total_damage, "element": damage_type
			})

		# Apply status effects
		for raw_entry in statuses:
			# A bomb may list a status as a bare name ("Blinded") with one
			# shared `status_duration`, or as {name, duration, chance}. The
			# flashbang and acid flask use the bare form, and `.get()` on a
			# String is a script error, so turn it into the long form first.
			var status_entry: Dictionary = raw_entry if raw_entry is Dictionary \
				else {"name": str(raw_entry), "duration": int(effect.get("status_duration", 2))}
			# The thrower's Ritual makes it land more often.
			var chance: float = effective_status_chance(
				user.character_data if "character_data" in user else {},
				float(status_entry.get("chance", 100)))
			if randf() * 100.0 <= chance:
				var status_name = status_entry.get("name", "")
				var duration = status_entry.get("duration", 2)
				# The thrower is the source, so their Fire Magic / Alchemy
				# (burning_damage_pct, poison_damage_pct) scales the burn or
				# venom a bomb leaves, the same as one from a spell or blade.
				_apply_status_effect(target, status_name, duration, 0, user)
				unit_result.effects_applied.append({
					"type": "status", "status": status_name, "duration": duration
				})

		results.append(unit_result)

	# Create ground effects from bomb damage type at actual landing position
	_create_ground_effects_from_damage(actual_target_pos, aoe_radius, damage_type, 2)

	return {
		"success": true,
		"is_bomb": true,
		"target_pos": actual_target_pos,
		"aimed_pos": target_pos,
		"bomb_scattered": bomb_scattered,
		"aoe_radius": aoe_radius,
		"hit_units": hit_units,
		"results": results
	}


## Apply an oil: coats the user's weapon with bonus effects for N attacks
func _apply_oil(user: Node, item: Dictionary) -> Dictionary:
	var effect = item.get("effect", {})
	var attacks = effect.get("attacks", 3)

	# Alchemy bonus adds extra attacks at level 3+ and 5
	var alchemy_level: int = unit_skill(user, "alchemy")
	if alchemy_level >= 5:
		attacks += 2
	elif alchemy_level >= 3:
		attacks += 1

	# Poisoner: "weapon coatings last twice as long (double applications per
	# dose)". The perk said so in its description and nothing read it.
	if PerkSystem.has_perk(user.character_data, "poisoner"):
		attacks *= 2

	# Overwrite any existing oil (only one active at a time)
	user.weapon_oil = {
		"bonus_damage": effect.get("bonus_damage", 0),
		"bonus_damage_type": effect.get("bonus_damage_type", "fire"),
		"attacks_remaining": attacks,
		"status": effect.get("status", ""),
		"status_chance": effect.get("status_chance", 0),
		"status_duration": effect.get("status_duration", 0),
		"crit_bonus": effect.get("crit_bonus", 0)
	}

	return {
		"success": true,
		"effects_applied": [{
			"type": "oil",
			"bonus_damage_type": effect.get("bonus_damage_type", "fire"),
			"attacks": attacks
		}]
	}


# ============================================
# UTILITY
# ============================================

## Calculate grid distance (Chebyshev - diagonal = 1)
func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Return an 8-directional unit step vector from `from` toward `to`.
func _dir_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var diff = to - from
	return Vector2i(sign(diff.x), sign(diff.y))


## Return the facing zone of `target_unit` as seen from `from_pos`.
## "front"  — attacker is within ±45° of target's facing (target can see them)
## "flank"  — attacker is roughly 90° to target's side
## "rear"   — attacker is within ±45° of target's back
## Uses dot-product with threshold ±0.5 (cos 60°) so the three arcs are symmetric.
func _get_facing_zone(from_pos: Vector2i, target_unit: Node) -> String:
	if not ("facing" in target_unit and "grid_position" in target_unit):
		return "front"
	var facing: Vector2i = target_unit.facing
	if facing == Vector2i.ZERO:
		return "front"
	# Vector from target to attacker
	var to_attacker = from_pos - target_unit.grid_position
	if to_attacker == Vector2i.ZERO:
		return "front"
	var facing_f   = Vector2(facing.x, facing.y).normalized()
	var to_att_f   = Vector2(to_attacker.x, to_attacker.y).normalized()
	var dot        = facing_f.dot(to_att_f)
	if dot > 0.5:
		return "front"
	elif dot < -0.5:
		return "rear"
	else:
		return "flank"


## Manhattan distance (diamond shape) — the range rule for spells, scrolls and
## thrown bombs. Walking, weapon reach and blast radii count diagonals as one
## step (_grid_distance) instead. Public so the enemy AI measures a throw or a
## cast exactly the way this file will check it.
func spell_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Get all units on a specific team
func get_team_units(team: int) -> Array[Node]:
	var result: Array[Node] = []
	for unit in all_units:
		if unit.team == team:
			result.append(unit)
	return result


## Get all alive units
func get_alive_units() -> Array[Node]:
	var result: Array[Node] = []
	for unit in all_units:
		if unit.is_alive():
			result.append(unit)
	return result


## Get unit at grid position
func get_unit_at(pos: Vector2i) -> Node:
	if combat_grid:
		return combat_grid.get_unit_at(pos)
	return null


# ============================================
# AI CONSUMABLE USAGE
# ============================================

## How far a potion can be handed to an ally: adjacent only (diagonals count).
## A potion is given, not thrown. Both sides can do it: the player through
## use_combat_item, enemies through ai_use_combat_item.
const POTION_ALLY_REACH: int = 1

## Item types that are drunk or applied by hand, and so can be given to an
## adjacent ally instead of used on yourself.
const HANDED_ITEM_TYPES: Array[String] = ["potion", "medicine", "herb"]


## Who a handed item (HANDED_ITEM_TYPES) lands on when `user` aims it at
## `target_pos`: the user on its own tile, otherwise the living ally standing
## there within POTION_ALLY_REACH. Returns {"recipient": unit} or
## {"reason": why not}. Checked before the item is spent, so a refusal costs
## nothing.
func handed_item_recipient(user: Node, target_pos: Vector2i) -> Dictionary:
	if target_pos == user.grid_position:
		return {"recipient": user}
	var ally: Node = get_unit_at(target_pos)
	if ally == null or not ally.is_alive() or ally.team != user.team:
		return {"reason": "No ally there"}
	if _grid_distance(user.grid_position, target_pos) > POTION_ALLY_REACH:
		return {"reason": "Ally out of reach"}
	return {"recipient": ally}


## Tiles a handed item can go to: the user's own, plus every living ally
## within POTION_ALLY_REACH. The arena highlights these when a potion is picked.
func handed_item_tiles(user: Node) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = [user.grid_position]
	for unit in get_team_units(user.team):
		if unit != user and unit.is_alive() \
				and _grid_distance(user.grid_position, unit.grid_position) <= POTION_ALLY_REACH:
			tiles.append(unit.grid_position)
	return tiles


## Use a combat item from an AI unit's own combat_inventory (not the player shared inventory).
## Works like use_combat_item but consumes from the unit's personal stash.
## A potion goes to the user when target_pos is its own tile, or to the ally
## standing on target_pos if that ally is within POTION_ALLY_REACH.
func ai_use_combat_item(user: Node, item_id: String, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return {"success": false, "reason": "Item not found: " + item_id}

	# Check the unit's personal inventory
	var inv_index = -1
	for i in range(user.combat_inventory.size()):
		if user.combat_inventory[i].get("item_id", "") == item_id:
			if user.combat_inventory[i].get("quantity", 0) > 0:
				inv_index = i
				break
	if inv_index == -1:
		return {"success": false, "reason": "Not in inventory"}

	var item_type = item.get("type", "")

	# Validate targeting for bombs
	if item_type == "bomb":
		var effect = item.get("effect", {})
		var bomb_range = effect.get("range", 4)
		var distance = spell_distance(user.grid_position, target_pos)
		if distance > bomb_range:
			return {"success": false, "reason": "Target out of range"}

	# Validate the recipient for a potion handed to an ally (before consuming)
	var recipient: Node = user
	if item_type == "potion":
		var handed := handed_item_recipient(user, target_pos)
		if not handed.has("recipient"):
			return {"success": false, "reason": handed.reason}
		recipient = handed.recipient

	# Consume from personal inventory
	user.combat_inventory[inv_index].quantity -= 1
	if user.combat_inventory[inv_index].quantity <= 0:
		user.combat_inventory.remove_at(inv_index)

	# Apply the effect
	var result: Dictionary = {}
	match item_type:
		"potion":
			result = _apply_potion_effect(user, item, recipient)
			result["recipient"] = recipient
		"bomb":
			result = _use_bomb(user, item, target_pos)
		"oil":
			result = _apply_oil(user, item)
		_:
			return {"success": false, "reason": "AI cannot use item type: " + item_type}

	if result.get("success", false):
		use_action(1)
		item_used_in_combat.emit(user, item, result)

	return result


# ============================================
# ACTIVE SKILLS
# ============================================

## What the Yoga table's magic_resistance_pct applies to now lives in
## damage_types.json, behind DamageType.is_magic(). The constant that was here
## listed holy, shadow and arcane — dealt by nothing — and omitted black and
## white, so equanimity did nothing against the two schools most obviously
## made of magic.


## Effect strings `use_active_skill` below dispatches to a real resolver.
## Keep in step with its match block — the UI greys out anything not listed here
## rather than letting the player spend an action on "not yet implemented".
const IMPLEMENTED_SKILL_EFFECTS: Array[String] = [
	"attack_with_bonus", "dash_attack", "buff_self", "debuff_target",
	"aoe_attack", "teleport", "stance", "heal_self", "enter_stealth",
	"mark_target", "examine", "bonus_movement", "restore_stamina",
	"restore_armor", "revive", "debuff_enemies", "buff_allies", "buff_ally",
	"destroy_obstacle", "cleanse_and_buff", "grant_extra_action", "force_miss",
	"grapple", "overcast", "retreat", "aoe_damage_and_status",
	"buff_allies_debuff_enemies", "dispel_and_invert", "aggro_aura",
	"share_buffs", "double_buffs", "chod_offering", "throw_phurba",
	"create_terrain", "collapse_terrain", "open_gate", "heal_ally",
	"place_trap", "mass_teleport", "guard_ally", "ignore_resistances",
	"choose_one", "consume_charm", "create_images", "steal_item",
	"imbued_attack", "recruit_or_pacify",
]


## A status's chance to land, after the applier's Ritual training.
##
## Takes a character dict rather than a unit so non-combat callers can use it
## too. A zero chance stays zero — an effect with no chance to apply is saying
## it does not apply, not that it is unlikely — and nothing exceeds 100.
##
## Works in floats (0-100) because weapon procs carry fractional chances like
## 7.5, and rounding those to whole numbers before the roll would quietly
## change the base. Every chance-to-apply site calls this: spell `status`
## effects, bombs, weapon procs and oils.
func effective_status_chance(character: Dictionary, base_chance: float) -> float:
	if base_chance <= 0.0:
		return base_chance
	var bonus: float = float(character.get("derived", {}).get("status_effect_chance_pct", 0.0))
	return clampf(base_chance * (1.0 + bonus / 100.0), 0.0, 100.0)


## The same Ritual bonus, for a status that lands on a FAILED SAVE instead of
## on a percentage roll.
##
## A save has no percentage to multiply, so the bonus goes onto the DC through
## the conversion SaveSystem already uses for percentages — one d20 point is
## five percentage points (SaveSystem.PERCENT_PER_ROLL_POINT). That is the same
## rule that turns Yoga's mental_resistance_pct into save points, so a
## ritualist's +DC and a yogi's +save are measured in the same coin and meet on
## equal terms: Ritual 10 (30%) is +6 to the DC, Yoga 10 (40%) is +8 to resist.
##
## Note the two routes are not identical in size: on a roll the bonus is a
## multiplier (a 50% chance becomes 65% at Ritual 10), on a save it is flat
## points (+30 percentage points on the d20). Additive is what the save system
## does with every other percentage, so this follows it rather than inventing
## a third conversion.
func status_save_dc_bonus(applier: Node) -> int:
	if applier == null or not is_instance_valid(applier) or not "character_data" in applier:
		return 0
	var pct: float = float(applier.character_data.get("derived", {}).get(
		"status_effect_chance_pct", 0.0))
	return int(pct / SaveSystem.PERCENT_PER_ROLL_POINT)


## effective_status_chance for a unit and a 0.0-1.0 chance, the scale auras,
## retaliation and the hard-coded perk procs use. `source` may be null (a
## ground zone has no owner), and then the chance is returned unchanged.
func ritual_chance(source: Node, chance: float) -> float:
	if chance >= 1.0 or source == null or not is_instance_valid(source) \
			or not "character_data" in source:
		return chance
	return effective_status_chance(source.character_data, chance * 100.0) / 100.0


## True when an effect string resolves to something that actually happens.
func is_active_skill_effect_implemented(effect: String) -> bool:
	return effect in IMPLEMENTED_SKILL_EFFECTS



## Dispatch one active-skill effect to its resolver.
##
## Pulled out of use_active_skill() so that `choose_one` can hand a chosen
## option straight back in — a skill that offers three things does not want a
## second copy of the table that knows how to do them.
func _dispatch_skill_effect(user: Node, effect_type: String,
		combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var result: Dictionary = {"success": true, "effects": []}

	match effect_type:
		"attack_with_bonus":
			result = _resolve_attack_skill(user, combat_data, target_pos)
		"dash_attack":
			result = _resolve_dash_attack(user, combat_data, target_pos)
		"buff_self":
			result = _resolve_buff_self(user, combat_data)
		"debuff_target":
			result = _resolve_debuff_target(user, combat_data, target_pos)
		"aoe_attack":
			result = _resolve_aoe_skill(user, combat_data, target_pos)
		"teleport":
			result = _resolve_teleport(user, combat_data, target_pos)
		"stance":
			result = _resolve_stance(user, combat_data)
		"heal_self":
			result = _resolve_heal_self(user, combat_data)
		"enter_stealth":
			result = _resolve_enter_stealth(user)
		"mark_target":
			result = _resolve_mark_target(user, combat_data, target_pos)
		"examine":
			# Reveal enemy info via examine window — handled by combat_arena via signal
			var target = get_unit_at(target_pos)
			if target == null or not target.is_alive():
				return {"success": false, "reason": "No target"}
			result = {"success": true, "examine_target": target, "effects": []}
		# --- Batch 2 resolvers ---
		"bonus_movement":
			result = _resolve_bonus_movement(user, combat_data)
		"restore_stamina":
			result = _resolve_restore_stamina(user, combat_data)
		"restore_armor":
			result = _resolve_restore_armor(user, combat_data, target_pos)
		"revive":
			result = _resolve_revive_ally(user, combat_data, target_pos)
		"debuff_enemies":
			result = _resolve_debuff_enemies_aoe(user, combat_data, target_pos)
		"buff_allies":
			result = _resolve_buff_allies_all(user, combat_data)
		"buff_ally":
			result = _resolve_buff_ally_single(user, combat_data, target_pos)
		"destroy_obstacle":
			result = _resolve_destroy_obstacle(user, combat_data, target_pos)
		"cleanse_and_buff":
			result = _resolve_cleanse_and_buff(user, combat_data)
		"grant_extra_action":
			result = _resolve_grant_extra_action(user, combat_data, target_pos)
		"force_miss":
			result = _resolve_force_miss(user, combat_data, target_pos)
		"grapple":
			result = _resolve_grapple(user, combat_data, target_pos)
		"overcast":
			result = _resolve_overcast(user, combat_data)
		"retreat":
			result = _resolve_retreat(user, combat_data)
		"aoe_damage_and_status":
			result = _resolve_aoe_damage_and_status(user, combat_data, target_pos)
		"buff_allies_debuff_enemies":
			result = _resolve_buff_allies_debuff_enemies(user, combat_data)
		"dispel_and_invert":
			result = _resolve_dispel_and_invert(user, combat_data, target_pos)
		"aggro_aura":
			result = _resolve_aggro_aura(user, combat_data)
		"share_buffs":
			result = _resolve_share_buffs(user, combat_data)
		"double_buffs":
			result = _resolve_double_buffs(user, combat_data, target_pos)
		"create_terrain":
			result = _resolve_create_terrain(user, combat_data, target_pos)
		"collapse_terrain":
			result = _resolve_collapse_terrain(user, combat_data, target_pos)
		"open_gate":
			result = _resolve_open_gate(user, combat_data, target_pos)
		"heal_ally":
			result = _resolve_heal_ally(user, combat_data, target_pos)
		"place_trap":
			result = _resolve_place_trap(user, combat_data, target_pos)
		"mass_teleport":
			result = _resolve_mass_teleport(user, combat_data, target_pos)
		"guard_ally":
			result = _resolve_guard_ally(user, combat_data, target_pos)
		"ignore_resistances":
			result = _resolve_ignore_resistances(user, combat_data)
		"choose_one":
			result = _resolve_choose_one(user, combat_data, target_pos)
		"consume_charm":
			result = _resolve_consume_charm(user, combat_data)
		"create_images":
			result = _resolve_create_images(user, combat_data)
		"steal_item":
			result = _resolve_steal_item(user, combat_data, target_pos)
		"imbued_attack":
			result = _resolve_imbued_attack(user, combat_data)
		"recruit_or_pacify":
			result = _resolve_recruit_or_pacify(user, combat_data, target_pos)
		"chod_offering":
			result = _resolve_chod_offering(user, combat_data)
		"throw_phurba":
			result = _resolve_throw_phurba(user, combat_data, target_pos)
		# --- Still deferred ---
		"summon_aura":
			return {"success": false, "reason": "Skill not yet implemented: " + effect_type}
		_:
			return {"success": false, "reason": "Unknown skill effect: " + effect_type}
	return result

## Use an active skill. skill_data comes from perks.json with added combat_data.
## target_pos is used for targeted skills (single_enemy, aoe); ignored for self skills.
func use_active_skill(user: Node, skill_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	var combat_data = skill_data.get("combat_data", {})
	if combat_data.is_empty():
		return {"success": false, "reason": "Skill has no combat data"}

	var perk_id = skill_data.get("id", "")
	var stamina_cost = combat_data.get("stamina_cost", 0)

	# Check cooldown
	if user.is_skill_on_cooldown(perk_id):
		return {"success": false, "reason": "Skill on cooldown (%d turns)" % user.skill_cooldowns.get(perk_id, 0)}

	# Check once-per-turn restriction (free-action skills like call_the_shot)
	if combat_data.get("once_per_turn", false):
		var used_flag = perk_id + "_used_this_turn"
		if used_flag in user and user.get(used_flag):
			return {"success": false, "reason": "Already used this turn"}

	# Check stamina
	if stamina_cost > 0 and user.current_stamina < stamina_cost:
		return {"success": false, "reason": "Not enough stamina (%d/%d)" % [user.current_stamina, stamina_cost]}

	# Check weapon requirement — weapon skills need the matching weapon equipped
	var perk_skill = skill_data.get("skill", "")
	if not unit_has_required_weapon(user, perk_skill):
		var required = get_required_weapon_types(perk_skill)
		return {"success": false, "reason": "Requires %s weapon equipped" % "/".join(required)}

	var effect_type = combat_data.get("effect", "")
	var targeting = combat_data.get("targeting", "self")

	# Resolve the skill effect
	var result: Dictionary = {"success": true, "effects": []}

	result = _dispatch_skill_effect(user, effect_type, combat_data, target_pos)

	if result.get("success", false):
		# Play sound based on effect type
		match effect_type:
			"buff_self", "stance", "buff_allies", "buff_ally", "share_buffs", "double_buffs":
				AudioManager.play("buff_apply")
			"debuff_target", "debuff_enemies", "mark_target", "aggro_aura":
				AudioManager.play("debuff_apply")
			"heal_self", "revive", "cleanse_and_buff":
				AudioManager.play("heal")
			"teleport", "enter_stealth", "retreat", "bonus_movement":
				AudioManager.play("hit_miss")
			"overcast", "dispel_and_invert":
				AudioManager.play("spell_cast")
			"restore_stamina", "restore_armor", "grant_extra_action":
				AudioManager.play("buff_apply")
			# attack_with_bonus, dash_attack, aoe_attack, etc. already play attack sounds internally
		# Deduct stamina
		if stamina_cost > 0:
			user.use_stamina(stamina_cost)
		# Use action — free_action skills cost nothing
		if not combat_data.get("free_action", false):
			use_action(1)
		# Apply cooldown
		var cooldown = combat_data.get("cooldown", 0)
		if cooldown > 0:
			user.set_skill_cooldown(perk_id, cooldown)
		# Once-per-combat skills get a huge cooldown; once-per-turn skills cool down in 1 turn
		if combat_data.get("once_per_combat", false):
			user.set_skill_cooldown(perk_id, 999)
		# Mark once-per-turn skills as used (reset at turn start)
		if combat_data.get("once_per_turn", false):
			var used_flag = perk_id + "_used_this_turn"
			if used_flag in user:
				user.set(used_flag, true)
		# Emit signal
		active_skill_used.emit(user, skill_data, result)

	return result


## ── Stealth Detection System ─────────────────────────────────────────────────
## 5-tile detection radius.  Each enemy within range rolls:
##     d20 + Awareness  vs  DC
## DC scales with distance, Guile skill, Soft Step perk, and Invisibility.
##
## Distance → base DC:  5→10, 4→14, 3→18, 2→22, 1→26
## Guile level:   +2 DC per level
## Soft Step:     +4 DC
## Invisibility:  +10 DC  (nearly undetectable)
##
## Called after each movement step and by Shady Dealings on non-melee actions.

const _STEALTH_BASE_DC: Dictionary = {5: 10, 4: 14, 3: 18, 2: 22, 1: 26}

## Run detection checks for all enemies within 5 tiles of a stealthed unit.
## Returns true if detected (stealth broken).
func _run_stealth_detection(unit: Node) -> bool:
	if not ("is_stealthed" in unit and unit.is_stealthed):
		return false

	var char_data = unit.character_data if "character_data" in unit else {}
	var guile_level: int = unit_skill(unit, "guile")
	var has_soft_step: bool = PerkSystem.has_perk(char_data, "soft_step")
	var is_invisible: bool = StatusRules.has_flag(unit, "grants_stealth")

	for enemy in all_units:
		if enemy.is_dead or enemy.team == unit.team:
			continue
		var dist = _grid_distance(unit.grid_position, enemy.grid_position)
		if dist < 1 or dist > 5:
			continue

		var base_dc: int = _STEALTH_BASE_DC.get(dist, 10)

		# Facing zone modifier: sneaking up behind someone is easier;
		# sneaking into their front arc is much harder (they can see you coming)
		var facing_dc_mod := 0
		var facing_roll_mod := 0
		if "facing" in enemy:
			match _get_facing_zone(unit.grid_position, enemy):
				"front":
					facing_roll_mod = enemy.attributes.get("awareness", 8) / 2 if "attributes" in enemy else 4
				"rear":
					facing_dc_mod = 6

		var dc: int = base_dc + (guile_level * 2) + facing_dc_mod
		if has_soft_step:
			dc += 4
		if is_invisible:
			dc += 10
		# Chameleon / Shadow_Cloaked: supernatural camouflage makes detection much harder
		if StatusRules.has_flag(unit, "stealth_bonus"):
			dc += 6

		var awareness: int = 8
		if "attributes" in enemy:
			awareness = enemy.attributes.get("awareness", 8)
		var roll: int = randi_range(1, 20) + awareness + facing_roll_mod

		if roll >= dc:
			combat_log.emit("%s (AWR %d, rolled %d vs DC %d) spots %s at range %d!" % [
				enemy.unit_name, awareness, roll, dc, unit.unit_name, dist])
			_leave_stealth(unit)
			return true

	return false


## Enter stealth (blend_in active skill).
func _resolve_enter_stealth(user: Node) -> Dictionary:
	if "is_stealthed" in user and user.is_stealthed:
		return {"success": false, "reason": "Already stealthed"}
	_enter_stealth(user)
	return {"success": true, "effects": [{"type": "enter_stealth"}]}


## Central helper: enter stealth for a unit and apply all enter-stealth perk effects.
func _enter_stealth(unit: Node) -> void:
	unit.is_stealthed = true
	combat_log.emit("%s blends into the shadows." % unit.unit_name)

	var char_data = unit.character_data if "character_data" in unit else {}

	# Now You See Me (Guile 3): entering stealth removes all 1-turn duration debuffs
	# and breaks enemy targeting (clears marks, taunts pointed at this unit)
	if PerkSystem.has_perk(char_data, "now_you_see_me"):
		for i in range(unit.status_effects.size() - 1, -1, -1):
			var se = unit.status_effects[i]
			var sdef = get_status_definition(se.get("status", ""))
			if sdef.get("polarity", "") == "negative" and se.get("duration", 0) <= 1:
				var sname = se.get("status", "")
				_end_status(unit, se, "removed")
				status_effect_expired.emit(unit, sname)
		# Break enemy targeting: clear marks and taunt locks aimed at this unit
		if "is_marked" in unit:
			unit.is_marked = false
		for other in all_units:
			if "marked_target" in other and other.marked_target == unit:
				other.marked_target = null
		combat_log.emit("Now You See Me — debuffs cleared, enemy targeting broken!")


## Central helper: leave stealth for a unit and apply all leave-stealth perk effects.
func _leave_stealth(unit: Node) -> void:
	unit.is_stealthed = false
	var char_data = unit.character_data if "character_data" in unit else {}

	# Where I Meant to Be (Guile 5): leaving stealth → +15% Attack and +15% Dodge for 1 turn
	if PerkSystem.has_perk(char_data, "where_i_meant_to_be"):
		_apply_status_effect(unit, "Inspired", 1, 0, unit)   # +accuracy proxy
		_apply_status_effect(unit, "Dodge_Buff", 1, 0, unit) # +dodge proxy
		combat_log.emit("Where I Meant to Be — +15%% Attack and Dodge for 1 turn!")


## Shady Dealings (Guile 7): when a stealthed unit performs a non-melee action,
## use the standard detection system (enemies within 5 tiles get AWR checks).
func _shady_dealings_detected(unit: Node) -> bool:
	return _run_stealth_detection(unit)


## Mark an enemy (call_the_shot). The marking unit's field marks the target node.
## Any ally who attacks that target gets the accuracy+damage bonus, then the mark clears.
func _resolve_mark_target(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No valid target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot mark allies"}
	var distance = _grid_distance(user.grid_position, target_pos)
	var max_range = combat_data.get("range", 6)
	if distance > max_range:
		return {"success": false, "reason": "Out of range"}
	# Place the mark on both the marking unit (for team-wide queries) and the target (for quick checks)
	user.marked_target = target
	if "is_marked" in target:
		target.is_marked = true
	combat_log.emit("%s calls the shot on %s!" % [user.unit_name, target.unit_name])
	return {"success": true, "effects": [{"type": "mark_target", "target": target}]}


## Attack with accuracy/damage bonuses (Measured Strike, Aimed Shot, Final Cut, etc.)
func _resolve_attack_skill(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No valid target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot target allies"}

	var distance = _grid_distance(user.grid_position, target_pos)
	var max_range = combat_data.get("range", user.get_attack_range())
	if distance > max_range:
		return {"success": false, "reason": "Out of range"}

	# Calculate hit with bonus accuracy
	var accuracy_bonus = combat_data.get("accuracy_bonus", 0)
	var damage_bonus_pct = combat_data.get("damage_bonus_pct", 0)
	var armor_ignore_pct = combat_data.get("armor_ignore_pct", 0)
	var resist_ignore_pct = combat_data.get("resist_ignore_pct", 0)
	var ignore_dodge = combat_data.get("ignore_dodge", false)

	# Roll to hit
	var hit_chance = calculate_hit_chance(user, target) + accuracy_bonus
	if ignore_dodge:
		hit_chance = 95.0  # Near guaranteed but not immune to nat 1
	var roll = randf() * 100.0
	var hit = roll <= hit_chance

	if not hit:
		return {"success": true, "hit": false, "roll": roll, "hit_chance": hit_chance, "target": target, "effects": []}

	# Calculate damage
	var dmg_type = user.get_weapon_damage_type()
	var dmg_result = calculate_physical_damage(user, target, dmg_type)
	var damage = dmg_result.damage

	# Forced movement, resolved before damage because an effect may make its
	# bonus conditional on the push failing — Overwhelming Blow deals its extra
	# 25% only when the target had nowhere to go.
	var push_result: Dictionary = {}
	if combat_data.has("push"):
		push_result = _apply_push(user, target, combat_data["push"])
		damage_bonus_pct += int(push_result.get("damage_bonus_pct", 0))

	# Apply damage bonus
	if damage_bonus_pct > 0:
		damage = int(damage * (1.0 + damage_bonus_pct / 100.0))

	# Apply armor/resist ignore
	if armor_ignore_pct > 0:
		# Recalculate without some armor
		var armor = target.get_armor()
		var armor_reduced = int(armor * armor_ignore_pct / 100.0)
		damage += armor_reduced  # Add back the armor that was subtracted

	# Apply damage
	_apply_damage_flagging_crit(target, damage, dmg_type, bool(dmg_result.crit))
	_check_immediate_combat_end()

	var result = {
		"success": true, "hit": true, "damage": damage, "target": target,
		"roll": roll, "hit_chance": hit_chance, "crit": dmg_result.crit,
		"effects": []
	}

	# Apply on-hit buff to self
	var self_buff = combat_data.get("self_buff", {})
	if not self_buff.is_empty():
		var stat = self_buff.get("stat", "")
		var value = self_buff.get("value", 0)
		var duration = self_buff.get("duration", 1)
		_apply_stat_modifier(user, stat, value, duration)
		result.effects.append({"type": "self_buff", "stat": stat, "value": value, "duration": duration})

	# Apply on-hit debuff to target
	var target_debuff = combat_data.get("target_debuff", {})
	if not target_debuff.is_empty() and target.is_alive():
		var stat = target_debuff.get("stat", "")
		var value = target_debuff.get("value", 0)
		var duration = target_debuff.get("duration", 2)
		_apply_stat_modifier(target, stat, -value, duration)
		result.effects.append({"type": "target_debuff", "stat": stat, "value": value, "duration": duration})

	if not push_result.is_empty():
		result.effects.append({"type": "push", "target": target,
			"moved": push_result.get("moved", 0), "lost": push_result.get("lost", 0)})

	# Stamina refund on kill
	var refund_on_kill = combat_data.get("refund_on_kill", 0)
	if refund_on_kill > 0 and not target.is_alive():
		user.restore_stamina(refund_on_kill)
		result.effects.append({"type": "refund", "amount": refund_on_kill})

	return result


## Dash + Attack (Lunge, Whirling Advance, etc.)
func _resolve_dash_attack(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No valid target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot target allies"}

	var dash_range = combat_data.get("dash_range", 2)
	var distance = _grid_distance(user.grid_position, target_pos)
	if distance > dash_range + user.get_attack_range():
		return {"success": false, "reason": "Target too far to dash-attack"}

	# Move toward target (find closest adjacent tile)
	var best_tile = user.grid_position
	var best_dist = 999
	if combat_grid:
		var movement_mode = user.get_movement_mode() if user.has_method("get_movement_mode") else 0
		var reachable = combat_grid.get_reachable_tiles(user.grid_position, dash_range, movement_mode)
		for tile in reachable:
			var d = _grid_distance(tile, target_pos)
			if d > 0 and d <= user.get_attack_range() and d < best_dist:
				best_dist = d
				best_tile = tile

	# Move without using an action (it's part of the skill)
	if best_tile != user.grid_position and combat_grid:
		var from = user.grid_position
		combat_grid.move_unit(user, best_tile)
		unit_moved.emit(user, from, best_tile)

	# Now attack
	var damage_bonus_pct = combat_data.get("damage_bonus_pct", 0)
	var hit_chance = calculate_hit_chance(user, target)
	var roll = randf() * 100.0
	var hit = roll <= hit_chance

	if not hit:
		return {"success": true, "hit": false, "roll": roll, "hit_chance": hit_chance,
				"target": target, "moved_to": best_tile, "effects": []}

	var dmg_type = user.get_weapon_damage_type()
	var dmg_result = calculate_physical_damage(user, target, dmg_type)
	var damage = int(dmg_result.damage * (1.0 + damage_bonus_pct / 100.0))

	_apply_damage_flagging_crit(target, damage, dmg_type, bool(dmg_result.crit))
	_check_immediate_combat_end()

	return {
		"success": true, "hit": true, "damage": damage, "target": target,
		"moved_to": best_tile, "roll": roll, "hit_chance": hit_chance,
		"crit": dmg_result.crit, "effects": []
	}


## Buff self (Cloud Step, defensive stances, etc.)
func _resolve_buff_self(user: Node, combat_data: Dictionary) -> Dictionary:
	var buffs = combat_data.get("buffs", [])
	var effects: Array = []

	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 1)

		if stat == "movement_mode":
			# Special: grant a movement mode status
			var status_name = buff.get("status", "levitating")
			_apply_status_effect(user, status_name, duration)
			effects.append({"type": "status", "status": status_name, "duration": duration})
		elif stat != "":
			_apply_stat_modifier(user, stat, value, duration)
			effects.append({"type": "buff", "stat": stat, "value": value, "duration": duration})

	# Apply status effects from skill
	var statuses = combat_data.get("statuses", [])
	for status_entry in statuses:
		var status_name = status_entry.get("status", "")
		var duration = status_entry.get("duration", 2)
		var value = status_entry.get("value", 0)
		_apply_status_effect(user, status_name, duration, value)
		effects.append({"type": "status", "status": status_name, "duration": duration})

	return {"success": true, "effects": effects}


## Debuff a target (Disrupting Palm, etc.)
func _resolve_debuff_target(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No valid target"}

	var max_range = combat_data.get("range", 1)
	var distance = _grid_distance(user.grid_position, target_pos)
	if distance > max_range:
		return {"success": false, "reason": "Out of range"}

	# Some debuff skills still attack first
	var deals_damage = combat_data.get("deals_damage", false)
	var damage = 0
	var hit = true

	if deals_damage:
		var hit_chance = calculate_hit_chance(user, target)
		var roll = randf() * 100.0
		hit = roll <= hit_chance

		if hit:
			var dmg_type = user.get_weapon_damage_type()
			var dmg_result = calculate_physical_damage(user, target, dmg_type)
			damage = dmg_result.damage
			apply_damage(target, damage, dmg_type)
			_check_immediate_combat_end()

	if not hit:
		return {"success": true, "hit": false, "target": target, "effects": []}

	var effects: Array = []

	# Forced movement on a landed hit.
	if combat_data.has("push") and target.is_alive():
		var push_result: Dictionary = _apply_push(user, target, combat_data["push"])
		effects.append({"type": "push", "target": target,
			"moved": push_result.get("moved", 0), "lost": push_result.get("lost", 0)})

	# Apply debuffs
	var debuffs = combat_data.get("debuffs", [])
	for debuff in debuffs:
		var stat = debuff.get("stat", "")
		var value = debuff.get("value", 0)
		var duration = debuff.get("duration", 2)
		if stat != "" and target.is_alive():
			_apply_stat_modifier(target, stat, -value, duration)
			effects.append({"type": "debuff", "stat": stat, "value": value, "duration": duration})

	# Apply status effects
	var statuses = combat_data.get("statuses", [])
	for status_entry in statuses:
		var status_name = status_entry.get("status", "")
		var duration = status_entry.get("duration", 2)
		if target.is_alive():
			_apply_status_effect(target, status_name, duration)
			effects.append({"type": "status", "status": status_name, "duration": duration})

	return {"success": true, "hit": true, "damage": damage, "target": target, "effects": effects}


## AoE skill (Volley, Ground Slam, etc.)
## Units an active skill's area covers, using the same AoEResolver shapes spells
## use. Pass team = -1 for everyone, or a team id to filter.
##
## Shape comes from a canonical `aoe` block ({"type": "arc", "size": 1, ...}).
## A skill that only declares the flat `aoe_radius` is read as a circle of that
## radius, which is what the hand-rolled distance checks here used to do — so
## perks can move onto real shapes one at a time.
## The canonical `aoe` block for a skill, resolved once so the tile lookup, the
## damage falloff and the UI preview cannot disagree about the shape.
##
## A skill that only declares the flat `aoe_radius` reads as a circle of that
## radius, which is what the hand-rolled distance checks used to do — so the
## perks that genuinely want a burst stay untouched.
func _skill_aoe_block(combat_data: Dictionary) -> Dictionary:
	var aoe: Dictionary = combat_data.get("aoe", {})
	if aoe.is_empty():
		return {"type": "circle", "size": combat_data.get("aoe_radius", 1)}
	return aoe


func _units_in_skill_aoe(user: Node, combat_data: Dictionary, target_pos: Vector2i,
		team: int = -1) -> Array:
	var aoe: Dictionary = _skill_aoe_block(combat_data)

	var grid_sz: Vector2i = combat_grid.grid_size if combat_grid else Vector2i(48, 30)
	var tiles: Array[Vector2i] = AoEResolver.get_tiles(
		aoe, user.grid_position, target_pos, grid_sz)

	var hit: Array = []
	for unit in all_units:
		if not unit.is_alive():
			continue
		if team >= 0 and unit.team != team:
			continue
		if unit.grid_position in tiles:
			hit.append(unit)
	return hit


func _resolve_aoe_skill(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 4)
	var distance = _grid_distance(user.grid_position, target_pos)
	if distance > max_range:
		return {"success": false, "reason": "Out of range"}

	var damage_pct = combat_data.get("damage_pct", 60)  # % of normal damage

	var enemy_team: int = 1 - (user.team if "team" in user else 0)
	var hit_targets: Array = _units_in_skill_aoe(user, combat_data, target_pos, enemy_team)

	var effects: Array = []
	var aoe_block: Dictionary = _skill_aoe_block(combat_data)
	for target in hit_targets:
		var dmg_type = user.get_weapon_damage_type()
		var dmg_result = calculate_physical_damage(user, target, dmg_type)
		var damage = int(dmg_result.damage * damage_pct / 100.0)
		# Opt-in per-ring falloff. Returns 1.0 unless the shape declares one.
		damage = int(damage * AoEResolver.falloff_at(
			aoe_block, user.grid_position, target_pos, target.grid_position))
		apply_damage(target, damage, dmg_type)
		effects.append({"type": "aoe_damage", "target": target, "damage": damage})

	_check_immediate_combat_end()
	return {"success": true, "hit_count": hit_targets.size(), "effects": effects}


## Teleport (Step Between Moments, etc.)
func _resolve_teleport(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var teleport_range = combat_data.get("teleport_range", 3)
	var distance = _grid_distance(user.grid_position, target_pos)
	if distance > teleport_range:
		return {"success": false, "reason": "Teleport destination too far"}

	# Check tile is walkable and unoccupied
	if combat_grid:
		var unit_there = combat_grid.get_unit_at(target_pos)
		if unit_there != null:
			return {"success": false, "reason": "Tile occupied"}
		if not combat_grid.is_tile_walkable(target_pos):
			return {"success": false, "reason": "Tile not walkable"}

	# Teleport
	var from = user.grid_position
	if combat_grid:
		combat_grid.move_unit(user, target_pos)
	unit_moved.emit(user, from, target_pos)

	# Apply post-teleport buffs
	var effects: Array = []
	var buffs = combat_data.get("buffs", [])
	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 1)
		_apply_stat_modifier(user, stat, value, duration)
		effects.append({"type": "buff", "stat": stat, "value": value, "duration": duration})

	return {"success": true, "teleported_to": target_pos, "effects": effects}


## Stance (Stand in the Gap, Counterstrike — end turn, gain defensive effect)
func _resolve_stance(user: Node, combat_data: Dictionary) -> Dictionary:
	var effects: Array = []

	# Apply stance buffs
	var buffs = combat_data.get("buffs", [])
	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 1)
		_apply_stat_modifier(user, stat, value, duration)
		effects.append({"type": "buff", "stat": stat, "value": value, "duration": duration})

	# Apply stance status effects
	var statuses = combat_data.get("statuses", [])
	for status_entry in statuses:
		_apply_status_effect(user, status_entry.get("status", ""), status_entry.get("duration", 1))
		effects.append({"type": "status", "status": status_entry.status, "duration": status_entry.duration})

	# Most stances end your turn — that is the cost of holding one. Two do not
	# say so in their own text (Counterstrike, Heavenly Counterflow), so the
	# data decides rather than the resolver.
	var ends_turn: bool = bool(combat_data.get("ends_turn", true))
	if ends_turn:
		var unit = get_current_unit()
		if unit == user:
			while unit.actions_remaining > 1:  # Leave 1 for use_active_skill's use_action
				unit.actions_remaining -= 1

	return {"success": true, "ends_turn": ends_turn, "effects": effects}


## Heal self (Mantra of Healing, etc.)
func _resolve_heal_self(user: Node, combat_data: Dictionary) -> Dictionary:
	var base_heal = combat_data.get("heal_value", 20)
	# Scale with spellpower or other stat
	var scale_stat = combat_data.get("scale_stat", "")
	var heal_amount = base_heal
	if scale_stat == "spellpower":
		heal_amount += int(user.get_spellpower() * 0.5)
	elif scale_stat == "focus":
		var focus: int = unit_attribute(user, "focus")
		heal_amount += (focus - 10) * 2

	var effects: Array = []

	if heal_amount > 0:
		user.heal(heal_amount)
		unit_healed.emit(user, heal_amount)
		effects.append({"type": "heal", "amount": heal_amount})

	# Stamina restore (for skills like Second Wind)
	var stamina_restore_pct = combat_data.get("stamina_restore_pct", 0)
	if stamina_restore_pct > 0:
		var stamina_amount = int(user.max_stamina * stamina_restore_pct / 100.0)
		user.restore_stamina(stamina_amount)
		effects.append({"type": "stamina_restore", "amount": stamina_amount})

	# Apply any buffs from the skill (e.g., damage resistance from Second Wind)
	var buffs = combat_data.get("buffs", [])
	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 1)
		if stat != "":
			_apply_stat_modifier(user, stat, value, duration)
			effects.append({"type": "buff", "stat": stat, "value": value, "duration": duration})

	return {"success": true, "heal_amount": heal_amount, "effects": effects}


## Get the targeting type for a skill's combat_data
func get_skill_targeting(combat_data: Dictionary) -> String:
	return combat_data.get("targeting", "self")


# ============================================
# ACTIVE SKILL RESOLVER — BATCH 2
# (bonus_movement, restore_stamina, revive, debuff_enemies, buff_allies, buff_ally,
#  destroy_obstacle, cleanse_and_buff, grant_extra_action, force_miss, grapple,
#  overcast, retreat, aoe_damage_and_status, buff_allies_debuff_enemies,
#  dispel_and_invert, aggro_aura, share_buffs, double_buffs, restore_armor)
# ============================================

## True when a failed save on this spell would land a status — which is when
## the caster's Ritual raises the DC. Deathfog killing outright or Midas Touch
## turning someone to gold is not a status, and a ritualist should not be
## better at executions than an executioner.
func _save_gates_status(spell: Dictionary) -> bool:
	var failed_branch: Dictionary = spell.get("on_failed_save", {})
	return not failed_branch.get("statuses", []).is_empty() \
		or not failed_branch.get("random_one_of", []).is_empty()


## Roll the spell's save once and apply whichever branch it landed in.
##
##   "save_type": "Constitution",
##   "on_failed_save": {"instant_kill": true},
##   "on_failed_save": {"statuses": ["Damage_Debuff"], "random_one_of": [...]},
##   "on_passed_save": {"damage_pct_of_max_hp": 50}
##
## The gate is general on purpose. Midas Touch turns someone to gold, Deathfog
## kills outright and settles for damage if resisted, Metal to Mud corrodes
## armour — the same roll, different consequences, and previously three
## different fields plus several unread `special` keys.
func _apply_save_gated(caster: Node, target: Node, spell: Dictionary,
		bonus: int, result: Dictionary) -> void:
	var save_attr: String = String(spell.get("save_type", "constitution")).to_lower()
	var roll: Dictionary = _spell_save(caster, target, spell, save_attr,
		_save_gates_status(spell))
	var branch: Dictionary = spell.get(
		"on_passed_save" if roll.success else "on_failed_save", {})
	result.effects_applied.append({"type": "save", "passed": roll.success,
		"roll": roll.get("roll", 0), "dc": roll.get("dc", 0)})
	if branch.is_empty():
		return

	# Statuses, named or drawn at random from a set.
	var duration: int = _calculate_status_duration(caster, spell, bonus)
	for status_name in branch.get("statuses", []):
		_apply_status_effect(target, status_name, duration, 0, caster)
		result.effects_applied.append({"type": "status", "status": status_name,
			"applied": true})
	var pool: Array = branch.get("random_one_of", [])
	if not pool.is_empty():
		var chosen: String = pool[randi() % pool.size()]
		_apply_status_effect(target, chosen, duration, 0, caster)
		result.effects_applied.append({"type": "status", "status": chosen,
			"applied": true})

	# Damage measured against the victim rather than written flat, which is
	# what an execute wants on a passed save.
	if branch.has("damage_pct_of_max_hp"):
		var dmg: int = maxi(1, int(target.max_hp * float(branch["damage_pct_of_max_hp"]) / 100.0))
		apply_damage(target, dmg, spell.get("damage_type", "physical"))
		result.effects_applied.append({"type": "damage", "amount": dmg,
			"element": spell.get("damage_type", "physical"), "cause": "passed_save"})

	if branch.has("damage"):
		var flat: int = int(branch["damage"])
		if flat > 0:
			apply_damage(target, flat, spell.get("damage_type", "physical"))
			result.effects_applied.append({"type": "damage", "amount": flat,
				"element": spell.get("damage_type", "physical")})

	# Outright death, and the rewards a death can carry.
	if bool(branch.get("instant_kill", false)) and not target.is_dead:
		combat_log.emit("%s is undone." % target.unit_name)
		apply_damage(target, target.current_hp + target.max_hp, "true")
		result.effects_applied.append({"type": "instant_kill", "target": target})
		_grant_kill_reward(caster, target, spell.get("on_kill", {}), result)


## What a kill pays out, beyond the usual end-of-combat rewards.
##
## Midas Touch turns its victim to gold, and Golden Blade and the golden cage
## want the same thing. The amount is a fraction of the target's `xp_earned` —
## the same measure the end-of-combat gold already uses, so a spell that pays
## you for a kill cannot quietly out-earn the fight it happened in.
func _grant_kill_reward(killer: Node, victim: Node, on_kill: Dictionary,
		result: Dictionary) -> void:
	if on_kill.is_empty() or not "team" in killer or killer.team != Team.PLAYER:
		return
	var gold_spec: Dictionary = on_kill.get("gold", {})
	if gold_spec.is_empty():
		return
	var worth: int = 0
	if "character_data" in victim:
		worth = int(victim.character_data.get("xp_earned", 0))
	var gold: int = int(gold_spec.get("flat", 0)) \
		+ int(worth * float(gold_spec.get("pct_of_xp_worth", 0)) / 100.0)
	if gold <= 0:
		return
	GameState.add_gold(gold)
	combat_log.emit("%s's remains turn to gold — %d coin." % [victim.unit_name, gold])
	result.effects_applied.append({"type": "gold", "amount": gold})


## Drain, restore or move a resource between units.
##
##   {"op": "transfer", "resource": "mana", "from": "target", "to": "caster",
##    "amount": {"pct_of_current": 60}}
##
## See ResourceOps: the vocabulary is shared so a vampiric weapon, a
## restorative meal and this spell all say the same thing the same way.
func _apply_resource_op(caster: Node, target: Node, spec: Dictionary,
		result: Dictionary) -> void:
	var mode: String = spec.get("op", "drain")
	var resource: String = spec.get("resource", "mana")
	if not ResourceOps.is_mode(mode):
		push_warning("CombatManager: %s" % ResourceOps.explain_unknown_mode(mode))
		return
	if not ResourceOps.is_resource(resource):
		push_warning("CombatManager: %s" % ResourceOps.explain_unknown_resource(resource))
		return

	var from_unit: Node = target if spec.get("from", "target") == "target" else caster
	var to_unit: Node = caster if spec.get("to", "caster") == "caster" else target
	var amount_spec: Dictionary = spec.get("amount", {})

	match mode:
		"drain":
			var taken: int = ResourceOps.drain(from_unit, resource,
				ResourceOps.amount_for(amount_spec, resource, from_unit, caster))
			result.effects_applied.append({"type": "drain", "resource": resource,
				"amount": taken})
		"restore":
			var given: int = ResourceOps.restore(to_unit, resource,
				ResourceOps.amount_for(amount_spec, resource, to_unit, caster))
			result.effects_applied.append({"type": "restore", "resource": resource,
				"amount": given})
		"transfer":
			# Only what was actually there gets handed on, or a drain against an
			# empty pool would create the resource out of nothing.
			var moved: int = ResourceOps.drain(from_unit, resource,
				ResourceOps.amount_for(amount_spec, resource, from_unit, caster))
			var landed: int = ResourceOps.restore(to_unit, resource, moved)
			if moved > 0:
				combat_log.emit("%s draws %d %s from %s."
					% [to_unit.unit_name, moved, resource, from_unit.unit_name])
			result.effects_applied.append({"type": "transfer", "resource": resource,
				"amount": moved, "landed": landed})


## Roll a save against a spell. The caster's Focus sets the DC unless the spell
## names another attribute; `save_tier` and `save_dc_modifier` let one spell be
## harder to shrug off than another.
##
## See SaveSystem for the model. The percentage-based roll this replaced took no
## input at all from the caster, so a Constitution-12 target resisted every
## effect in the game at exactly 44% whoever cast it.
##
## `gates_status` is true when what rides on the save is a status — then the
## caster's Ritual raises the DC (see status_save_dc_bonus). A save that only
## halves damage or stands between the target and an instant kill is not a
## status landing, and Ritual stays out of it.
func _spell_save(caster: Node, target: Node, spell: Dictionary,
		save_type: String, gates_status: bool = false) -> Dictionary:
	var modifier: int = int(spell.get("save_dc_modifier", 0))
	if gates_status:
		modifier += status_save_dc_bonus(caster)
	var dc: int = SaveSystem.dc_for(
		caster,
		String(spell.get("dc_stat", "focus")).to_lower(),
		String(spell.get("save_tier", "normal")),
		modifier)
	return SaveSystem.roll(target, save_type, dc)


## Roll a save against an active skill, reading the same fields out of its
## combat_data. Weapon skills default their DC to Strength; a skill that is
## really a mental effect says `"dc_stat": "focus"`.
##
## Every caller gates a status or a stat debuff on this save, so the user's
## Ritual always raises the DC here (see status_save_dc_bonus).
func _skill_save(user: Node, target: Node, combat_data: Dictionary,
		save_type: String) -> Dictionary:
	var dc: int = SaveSystem.dc_for(
		user,
		String(combat_data.get("dc_stat", "strength")).to_lower(),
		String(combat_data.get("save_tier", "normal")),
		int(combat_data.get("save_dc_modifier", 0)) + status_save_dc_bonus(user))
	return SaveSystem.roll(target, save_type, dc)


## Bonus movement (spring_step, quick_escape): add movement tiles for rest of this turn.
func _resolve_bonus_movement(user: Node, combat_data: Dictionary) -> Dictionary:
	var bonus = combat_data.get("bonus_movement", 2)
	_apply_stat_modifier(user, "movement", bonus, 1)  # Expires at next turn start
	combat_log.emit("%s gains +%d movement this turn!" % [user.unit_name, bonus])
	return {"success": true, "effects": [{"type": "buff", "stat": "movement", "value": bonus}]}


## Restore stamina to all allies (comic_relief).
func _resolve_restore_stamina(user: Node, combat_data: Dictionary) -> Dictionary:
	var pct = combat_data.get("stamina_restore_pct", 15)
	var effects: Array = []
	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive():
			continue
		var amount = maxi(1, int(ally.max_stamina * pct / 100.0))
		ally.restore_stamina(amount)
		effects.append({"type": "stamina_restore", "target": ally, "amount": amount})
		# Psychology: comic relief lifts air (levity/wit) and space (freedom from worry) pressure in allies
		if "character_data" in ally:
			PsychologySystem.apply_pressure(ally.character_data, "air", 8.0)
			PsychologySystem.apply_pressure(ally.character_data, "space", 5.0)
	combat_log.emit("%s rallies the party — all allies restore %d%% stamina!" % [user.unit_name, pct])
	return {"success": true, "effects": effects}


## Restore armor as a temporary buff (field_repair).
func _resolve_restore_armor(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 2)
	var target: Node
	var dist = _grid_distance(user.grid_position, target_pos)
	if dist == 0:
		target = user
	else:
		target = get_unit_at(target_pos)
		if target == null or not target.is_alive():
			return {"success": false, "reason": "No target"}
		if dist > max_range:
			return {"success": false, "reason": "Out of range"}
		if target.team != user.team:
			return {"success": false, "reason": "Can only repair allies"}

	var pct = combat_data.get("armor_restore_pct", 25)
	var base_armor = target.character_data.get("derived", {}).get("armor", 0) if "character_data" in target else 0
	var armor_amount = maxi(2, int(base_armor * pct / 100.0))
	_apply_stat_modifier(target, "armor", armor_amount, 3)
	combat_log.emit("%s repairs %s's armor (+%d for 3 turns)." % [user.unit_name, target.unit_name, armor_amount])
	return {"success": true, "effects": [{"type": "buff", "stat": "armor", "value": armor_amount}]}


## Revive a bleeding-out or downed ally (miraculous_recovery).
func _resolve_revive_ally(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 2)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null:
		return {"success": false, "reason": "No target"}
	if not (target.is_bleeding_out or target.is_dead):
		return {"success": false, "reason": "Target is not downed"}
	if target.team != user.team:
		return {"success": false, "reason": "Can only revive allies"}

	var heal_pct = combat_data.get("heal_pct", 30)
	var heal_amount = maxi(1, int(target.max_hp * heal_pct / 100.0))

	target.is_bleeding_out = false
	target.is_dead = false
	target.bleed_out_turns = 0
	target.current_hp = mini(heal_amount, target.max_hp)

	if combat_data.get("cleanse_all_debuffs", false):
		for entry in target.status_effects.duplicate():
			_end_status(target, entry, "cleansed")

	unit_healed.emit(target, heal_amount)
	if target.has_method("_update_visuals"):
		target._update_visuals()
	combat_log.emit("%s miraculously revives %s with %d HP!" % [user.unit_name, target.unit_name, heal_amount])
	return {"success": true, "effects": [{"type": "revive", "target": target, "hp": heal_amount}]}


## Debuff enemies in an AoE with a saving throw (intimidating_stance, the_laughter_turns).
func _resolve_debuff_enemies_aoe(user: Node, combat_data: Dictionary, _target_pos: Vector2i) -> Dictionary:
	var aoe_radius = combat_data.get("aoe_radius", 2)
	var targeting = combat_data.get("targeting", "aoe_self")
	var save_type = combat_data.get("save_type", "focus")
	var requires_demoralized = combat_data.get("requires_demoralized", false)
	var statuses_to_apply = combat_data.get("statuses", [])
	var alt_status = combat_data.get("alternate_status", {})
	var effects: Array = []

	var enemy_team = 1 - (user.team if "team" in user else 0)
	var candidates: Array = []
	if targeting == "all_enemies":
		for enemy in get_team_units(enemy_team):
			if enemy.is_alive():
				candidates.append(enemy)
	else:
		# Self-centred: the shape anchors on the user, not on a clicked tile.
		var aoe: Dictionary = combat_data.get("aoe", {"type": "circle", "size": aoe_radius})
		aoe = aoe.duplicate()
		aoe["origin"] = "caster"
		candidates = _units_in_skill_aoe(
			user, {"aoe": aoe}, user.grid_position, enemy_team)

	for enemy in candidates:
		# the_laughter_turns: only targets demoralised enemies; uses alternate status otherwise
		if requires_demoralized:
			var is_demoralised = StatusRules.has_flag(enemy, "counts_as_demoralized")
			if not is_demoralised:
				if not alt_status.is_empty() and not _skill_save(user, enemy, combat_data, save_type).success:
					_apply_status_effect(enemy, alt_status.get("status", "Confused"), alt_status.get("duration", 2), 0, user)
					effects.append({"type": "status", "target": enemy, "status": alt_status.get("status", "")})
				continue

		if _skill_save(user, enemy, combat_data, save_type).success:
			continue  # Resisted

		for se in statuses_to_apply:
			_apply_status_effect(enemy, se.get("status", ""), se.get("duration", 2), 0, user)
			effects.append({"type": "status", "target": enemy, "status": se.get("status", "")})

		# And stat penalties, which this resolver could not do while its buff
		# twin (_resolve_buff_allies_all) always could — so a skill that wanted
		# "-10% to everything nearby" had nothing to say it with.
		for debuff in combat_data.get("debuffs", []):
			var stat: String = str(debuff.get("stat", ""))
			if stat == "":
				continue
			_apply_stat_modifier(enemy, stat, int(debuff.get("value", 0)),
				int(debuff.get("duration", 2)))
			effects.append({"type": "debuff", "target": enemy, "stat": stat,
				"value": debuff.get("value", 0)})

	combat_log.emit("%s uses an intimidating action on nearby enemies!" % user.unit_name)
	return {"success": true, "effects": effects}


## Buff all allies with stat modifiers and/or status effects (breath_easy, perfect_volley, roots_of_the_world).
func _resolve_buff_allies_all(user: Node, combat_data: Dictionary) -> Dictionary:
	var buffs = combat_data.get("buffs", [])
	var statuses = combat_data.get("statuses", [])
	var effects: Array = []

	# A radius, when the skill names one. This resolver buffed the whole team
	# whatever the skill said, so Improvised Masterpiece's "within 3 tiles"
	# was decoration — and a bard three rooms away was inspiring.
	var radius: int = int(combat_data.get("radius", 0))
	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive():
			continue
		if radius > 0 and "grid_position" in ally \
				and _grid_distance(user.grid_position, ally.grid_position) > radius:
			continue
		for buff in buffs:
			var stat = buff.get("stat", "")
			var value = buff.get("value", 0)
			var duration = buff.get("duration", 2)
			if stat != "":
				_apply_stat_modifier(ally, stat, value, duration)
				effects.append({"type": "buff", "target": ally, "stat": stat, "value": value})
		for se in statuses:
			_apply_status_effect(ally, se.get("status", ""), se.get("duration", 2), 0, user)
			effects.append({"type": "status", "target": ally, "status": se.get("status", "")})

	combat_log.emit("%s buffs all allies!" % user.unit_name)
	return {"success": true, "effects": effects}


## Buff a single ally (bark_orders, booster_shot, crossdisciplinary_insight).
func _resolve_buff_ally_single(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 4)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team != user.team:
		return {"success": false, "reason": "Can only buff allies"}

	var buffs = combat_data.get("buffs", [])
	var effects: Array = []
	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 2)
		if stat == "skill_bonus":
			# crossdisciplinary_insight: generic skill bonus; proxy as accuracy + spellpower bump
			_apply_stat_modifier(target, "accuracy", value * 5, duration)
			_apply_stat_modifier(target, "spellpower", value * 2, duration)
			effects.append({"type": "buff", "target": target, "stat": "skill_bonus", "value": value})
		elif stat == "status_resistance":
			# booster_shot: +25% status resistance — apply as save bonus proxy via stat modifier
			_apply_stat_modifier(target, "save_bonus", value, duration)
			effects.append({"type": "buff", "target": target, "stat": "status_resistance", "value": value})
		elif stat != "":
			_apply_stat_modifier(target, stat, value, duration)
			effects.append({"type": "buff", "target": target, "stat": stat, "value": value})

	var statuses = combat_data.get("statuses", [])
	for se in statuses:
		_apply_status_effect(target, se.get("status", ""), se.get("duration", 2), 0, user)

	combat_log.emit("%s buffs %s!" % [user.unit_name, target.unit_name])
	return {"success": true, "target": target, "effects": effects}


## Destroy an obstacle at the target tile (universal_solvent).
func _resolve_destroy_obstacle(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 3)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	if combat_grid == null:
		return {"success": false, "reason": "No combat grid"}

	var obs = combat_grid.get_obstacle_at(target_pos)
	if obs.is_empty() or obs.get("type", 0) == 0:
		return {"success": false, "reason": "No obstacle at target"}

	combat_grid.remove_obstacle(target_pos)
	combat_log.emit("%s dissolves the obstacle!" % user.unit_name)
	return {"success": true, "effects": [{"type": "destroy_obstacle", "pos": target_pos}]}


## Cleanse specific statuses then buff all allies in AoE (rally_the_banner).
func _resolve_cleanse_and_buff(user: Node, combat_data: Dictionary) -> Dictionary:
	var cleanse_list = combat_data.get("cleanses", [])  # Status names or categories to remove
	var buffs = combat_data.get("buffs", [])
	var effects: Array = []

	var aoe: Dictionary = combat_data.get(
		"aoe", {"type": "circle", "size": combat_data.get("aoe_radius", 3)}).duplicate()
	aoe["origin"] = "caster"
	for ally in _units_in_skill_aoe(user, {"aoe": aoe}, user.grid_position,
			user.team if "team" in user else 0):
		# Cleanse matching statuses or categories
		var to_remove: Array[int] = []
		for i in range(ally.status_effects.size()):
			var se_name = ally.status_effects[i].get("status", "")
			if se_name in cleanse_list:
				to_remove.append(i)
			elif "mental" in cleanse_list:
				var def = _status_effects.get(se_name, {})
				if "mental" in StatusRules.categories_of(def):
					to_remove.append(i)
		to_remove.reverse()
		var cleansed: Array = []
		for idx in to_remove:
			cleansed.append(ally.status_effects[idx])
		for entry in cleansed:
			var removed = entry.get("status", "")
			_end_status(ally, entry, "cleansed")
			effects.append({"type": "cleanse", "target": ally, "status": removed})

		# Apply buffs
		for buff in buffs:
			var stat = buff.get("stat", "")
			var value = buff.get("value", 0)
			var duration = buff.get("duration", 2)
			if stat != "":
				_apply_stat_modifier(ally, stat, value, duration)
				effects.append({"type": "buff", "target": ally, "stat": stat, "value": value})

	combat_log.emit("%s rallies nearby allies!" % user.unit_name)
	return {"success": true, "effects": effects}


## Grant an extra action to allies in range (this_is_the_moment, summoners_command).
func _resolve_grant_extra_action(user: Node, combat_data: Dictionary, _target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 6)
	var max_targets = combat_data.get("max_targets", 4)
	var summon_only = combat_data.get("summon_only", false)
	var effects: Array = []

	var eligible: Array = []
	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive() or ally == user:
			continue
		if _grid_distance(user.grid_position, ally.grid_position) > max_range:
			continue
		if summon_only and not ("is_summoned" in ally and ally.is_summoned):
			continue
		eligible.append(ally)

	# Sort by proximity, take the closest max_targets
	eligible.sort_custom(func(a, b):
		return _grid_distance(user.grid_position, a.grid_position) < _grid_distance(user.grid_position, b.grid_position))

	var given = 0
	for target in eligible:
		if given >= max_targets:
			break
		target.actions_remaining = mini(target.actions_remaining + 1, target.max_actions + 1)
		effects.append({"type": "extra_action", "target": target})
		combat_log.emit("%s grants %s an extra action!" % [user.unit_name, target.unit_name])
		given += 1

	return {"success": true, "effects": effects}


## Force an enemy's next attack to miss (that_was_supposed_to_miss).
func _resolve_force_miss(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 6)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot jinx allies"}

	if "will_miss_next_attack" in target:
		target.will_miss_next_attack = true
	else:
		target.set("will_miss_next_attack", true)

	combat_log.emit("%s jinxes %s — their next attack will miss!" % [user.unit_name, target.unit_name])
	return {"success": true, "target": target, "effects": [{"type": "force_miss", "target": target}]}


## Grapple a melee target (brawlers_grapple): hit roll then apply Grappled status.
func _resolve_grapple(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 1)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range (grapple is melee only)"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot grapple allies"}

	# Accuracy roll (uses normal melee hit chance)
	var hit_chance = calculate_hit_chance(user, target)
	if randf() * 100.0 > hit_chance:
		combat_log.emit("%s fails to grapple %s!" % [user.unit_name, target.unit_name])
		return {"success": true, "hit": false, "effects": []}

	# Apply statuses from combat_data (Grappled with duration 99 = until escaped)
	var statuses = combat_data.get("statuses", [{"status": "Immobilized", "duration": 2}])
	for se in statuses:
		_apply_status_effect(target, se.get("status", "Immobilized"), se.get("duration", 2), 0, user)

	combat_log.emit("%s grapples %s!" % [user.unit_name, target.unit_name])
	return {"success": true, "hit": true, "target": target, "effects": [{"type": "grapple", "target": target}]}


## Queue an overcast bonus for the caster's next spell (push_the_words, burn_the_breath, etc.).
func _resolve_overcast(user: Node, combat_data: Dictionary) -> Dictionary:
	var next_spell_bonus = combat_data.get("next_spell_bonus", {})
	if next_spell_bonus.is_empty():
		return {"success": false, "reason": "No overcast bonus defined"}

	# requires="ritual_circle": check if standing on one (simplified: log a note if missing)
	if combat_data.get("requires", "") == "ritual_circle":
		# Future: check combat_grid tile effect at user position
		# For now, allow it and log
		combat_log.emit("%s channels power through a ritual circle!" % user.unit_name)
	else:
		combat_log.emit("%s focuses power for an empowered spell!" % user.unit_name)

	if "pending_overcast_bonus" in user:
		user.pending_overcast_bonus = next_spell_bonus
	else:
		user.set("pending_overcast_bonus", next_spell_bonus)

	return {"success": true, "effects": [{"type": "overcast_ready", "bonus": next_spell_bonus}]}


## Teleport the unit to their deployment zone back row (strategic_withdrawal).
func _resolve_retreat(user: Node, _combat_data: Dictionary) -> Dictionary:
	if combat_grid == null:
		return {"success": false, "reason": "No combat grid"}

	var zones: Dictionary
	if ("team" in user) and user.team == 0:
		zones = combat_grid.get_player_deployment_zones()
	else:
		zones = combat_grid.get_enemy_deployment_zones()

	var retreat_tiles: Array = zones.get("back", [])
	if retreat_tiles.is_empty():
		retreat_tiles = zones.get("all", [])

	var dest = Vector2i(-1, -1)
	for tile in retreat_tiles:
		if combat_grid.get_unit_at(tile) == null and combat_grid.is_tile_walkable(tile):
			dest = tile
			break

	if dest == Vector2i(-1, -1):
		return {"success": false, "reason": "No safe position to retreat to"}

	var from = user.grid_position
	combat_grid.move_unit(user, dest)
	unit_moved.emit(user, from, dest)
	combat_log.emit("%s makes a strategic withdrawal!" % user.unit_name)
	return {"success": true, "effects": [{"type": "retreat", "destination": dest}]}


## AoE spell-like damage + status with save (drowning_pressure).
func _resolve_aoe_damage_and_status(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 5)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var damage_pct = combat_data.get("damage_pct", 75)
	var damage_element = combat_data.get("damage_element", "physical")
	var save_type = combat_data.get("save_type", "focus")
	var statuses = combat_data.get("statuses", [])
	var effects: Array = []

	var enemy_team: int = 1 - (user.team if "team" in user else 0)
	for enemy in _units_in_skill_aoe(user, combat_data, target_pos, enemy_team):
		# Spellpower-scaled damage, with opt-in per-ring falloff.
		var base_dmg = int(user.get_spellpower() * damage_pct / 100.0)
		base_dmg = int(base_dmg * AoEResolver.falloff_at(
			_skill_aoe_block(combat_data), user.grid_position, target_pos,
			enemy.grid_position))
		apply_damage(enemy, base_dmg, damage_element)
		effects.append({"type": "damage", "target": enemy, "damage": base_dmg})

		# Status on failed save
		if not _skill_save(user, enemy, combat_data, save_type).success and enemy.is_alive():
			for se in statuses:
				_apply_status_effect(enemy, se.get("status", ""), se.get("duration", 2), 0, user)
				effects.append({"type": "status", "target": enemy, "status": se.get("status", "")})

	_check_immediate_combat_end()
	combat_log.emit("%s unleashes a devastating wave!" % user.unit_name)
	return {"success": true, "effects": effects}


## Buff all allies AND debuff all enemies (crowd_influence).
## Enemy debuff values in combat_data are already negative.
func _resolve_buff_allies_debuff_enemies(user: Node, combat_data: Dictionary) -> Dictionary:
	var ally_buffs = combat_data.get("ally_buffs", [])
	var enemy_debuffs = combat_data.get("enemy_debuffs", [])
	var enemy_save_type = combat_data.get("enemy_save_type", "focus")
	var effects: Array = []

	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive():
			continue
		for buff in ally_buffs:
			var stat = buff.get("stat", "")
			var value = buff.get("value", 0)
			var duration = buff.get("duration", 3)
			if stat != "":
				_apply_stat_modifier(ally, stat, value, duration)
				effects.append({"type": "buff", "target": ally, "stat": stat, "value": value})

	for enemy in get_team_units(1 - (user.team if "team" in user else 0)):
		if not enemy.is_alive():
			continue
		if _skill_save(user, enemy, combat_data, enemy_save_type).success:
			continue
		for debuff in enemy_debuffs:
			var stat = debuff.get("stat", "")
			var value = debuff.get("value", 0)  # Already negative in combat_data
			var duration = debuff.get("duration", 3)
			if stat != "":
				_apply_stat_modifier(enemy, stat, value, duration)
				effects.append({"type": "debuff", "target": enemy, "stat": stat, "value": value})

	combat_log.emit("%s shifts the tide of battle!" % user.unit_name)
	return {"success": true, "effects": effects}


## Remove buffs from target and apply them inverted as debuffs (unraveling).
func _resolve_dispel_and_invert(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 5)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}

	var duration = combat_data.get("duration", 2)
	var effects: Array = []

	# Remove all buff statuses from target
	var to_remove: Array[int] = []
	for i in range(target.status_effects.size()):
		var se_name = target.status_effects[i].get("status", "")
		var def = _status_effects.get(se_name, {})
		if def.get("polarity", "") == "positive":
			to_remove.append(i)
	to_remove.reverse()
	var dispelled: Array = []
	for idx in to_remove:
		dispelled.append(target.status_effects[idx])
	for entry in dispelled:
		var removed = entry.get("status", "")
		_end_status(target, entry, "dispelled")
		effects.append({"type": "dispelled", "status": removed})

	# Invert positive stat_modifiers into negatives
	var inverted_count = 0
	if "stat_modifiers" in target:
		for mod in target.stat_modifiers:
			if mod.get("value", 0) > 0:
				_apply_stat_modifier(target, mod.get("stat", ""), -mod.get("value", 0), duration)
				inverted_count += 1

	# Apply Cursed as a general debuff token representing the inversion
	if to_remove.size() > 0 or inverted_count > 0:
		_apply_status_effect(target, "Cursed", duration, 0, user)
		effects.append({"type": "inverted", "count": to_remove.size() + inverted_count})

	combat_log.emit("%s unravels %s's buffs!" % [user.unit_name, target.unit_name])
	return {"success": true, "target": target, "effects": effects}


## Taunt: set aggro aura so enemies prefer to attack this unit (look_at_me).
func _resolve_aggro_aura(user: Node, combat_data: Dictionary) -> Dictionary:
	var duration = combat_data.get("duration", 2)
	if "taunt_active" in user:
		user.taunt_active = true
		user.taunt_duration = duration
	else:
		user.set("taunt_active", true)
		user.set("taunt_duration", duration)
	combat_log.emit("%s draws all nearby attention!" % user.unit_name)
	return {"success": true, "effects": [{"type": "aggro_aura", "duration": duration}]}


## Share active buffs from caster to all allies (absolute_presence).
func _resolve_share_buffs(user: Node, combat_data: Dictionary) -> Dictionary:
	var cap_duration = combat_data.get("duration", 2)
	var effects: Array = []

	# Collect caster's positive stat modifiers and buff statuses
	var user_mods: Array = user.stat_modifiers if "stat_modifiers" in user else []
	var user_buff_statuses: Array = []
	for se in user.status_effects:
		var def = _status_effects.get(se.get("status", ""), {})
		if def.get("polarity", "") == "positive":
			user_buff_statuses.append(se)

	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive() or ally == user:
			continue
		for mod in user_mods:
			if mod.get("value", 0) > 0:
				_apply_stat_modifier(ally, mod.get("stat", ""), mod.get("value", 0),
					mini(mod.get("duration", 1), cap_duration))
				effects.append({"type": "shared_buff", "target": ally, "stat": mod.get("stat", "")})
		for buff_se in user_buff_statuses:
			_apply_status_effect(ally, buff_se.get("status", ""),
				mini(buff_se.get("duration", 1), cap_duration), 0, user)
			effects.append({"type": "shared_status", "target": ally, "status": buff_se.get("status", "")})

	combat_log.emit("%s shares their power with all allies!" % user.unit_name)
	return {"success": true, "effects": effects}


## Double all active buff modifiers on a single ally (masterwork).
func _resolve_double_buffs(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 4)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team != user.team:
		return {"success": false, "reason": "Can only use on allies"}

	var effects: Array = []
	if "stat_modifiers" in target:
		for mod in target.stat_modifiers:
			if mod.get("value", 0) > 0:
				mod.value *= 2
				effects.append({"type": "doubled", "stat": mod.get("stat", ""), "new_value": mod.value})

	combat_log.emit("%s's masterwork doubles %s's active buffs!" % [user.unit_name, target.unit_name])
	return {"success": true, "target": target, "effects": effects}


## Chöd Offering (Kangling): sacrifice 25% of max mana, or HP if mana insufficient.
## Gain ceil(cost/2) Spellpower stacking until end of combat.
func _resolve_chod_offering(user: Node, _combat_data: Dictionary) -> Dictionary:
	var cost = int(floor(user.max_mana * 0.25))
	if cost <= 0:
		cost = 1  # minimum sacrifice

	# Deduct from mana first, remainder from HP
	var mana_used = mini(cost, user.current_mana)
	var hp_used = cost - mana_used
	user.current_mana -= mana_used
	if "character_data" in user:
		user.character_data.get("derived", {})["current_mana"] = user.current_mana

	if hp_used > 0:
		apply_damage(user, hp_used, "sacrifice")  # bypass armor — it's a ritual sacrifice
		combat_log.emit("%s's Chöd cuts into flesh — mana depleted, spending %d HP!" % [user.unit_name, hp_used])
	else:
		combat_log.emit("%s performs Chöd Offering — sacrifices %d mana!" % [user.unit_name, mana_used])

	# Gain accumulated Spellpower
	var sp_gain = ceili(cost / 2.0)
	user.chod_spellpower_bonus += sp_gain
	combat_log.emit("%s gains +%d Spellpower from the offering (total +%d)." % [user.unit_name, sp_gain, user.chod_spellpower_bonus])

	return {
		"success": true,
		"mana_sacrificed": mana_used,
		"hp_sacrificed": hp_used,
		"spellpower_gained": sp_gain,
		"effects": [{"type": "chod_spellpower", "amount": sp_gain}]
	}


## Throw Phurba: ranged attack (any range), Sorcery-scaled damage.
## Target makes DC 16 Focus save; failure = Subjugated 3 turns.
func _resolve_throw_phurba(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var item_id = combat_data.get("item_id", "")
	var item = ItemSystem.get_item(item_id) if item_id != "" else {}
	var mana_cost = item.get("throw_mana_cost", 15)
	var base_damage = item.get("throw_base_damage", 8)
	var save_dc = item.get("throw_save_dc", 16)

	if user.current_mana < mana_cost:
		return {"success": false, "reason": "Not enough mana (%d/%d)" % [user.current_mana, mana_cost]}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot throw at allies"}

	# Deduct mana
	user.current_mana -= mana_cost
	if "character_data" in user:
		user.character_data.get("derived", {})["current_mana"] = user.current_mana

	# Calculate damage: base + sorcery_skill_level * 2
	var sorcery_level: int = unit_skill(user, "sorcery")
	var total_damage = base_damage + sorcery_level * 2
	apply_damage(target, total_damage, "physical")
	combat_log.emit("%s hurls a Phurba at %s for %d damage!" % [user.unit_name, target.unit_name, total_damage])

	# Focus save vs DC — defender's Focus attribute vs DC
	var defender_focus: int = unit_attribute(target, "focus")
	var save_roll = randi() % 20 + 1 + defender_focus  # d20 + Focus
	var subjugated = false
	if save_roll < save_dc:
		_apply_status_effect(target, "Subjugated", 3, 0, user)
		subjugated = true
		combat_log.emit("%s fails the Focus save — Subjugated for 3 turns!" % target.unit_name)
	else:
		combat_log.emit("%s resists the Phurba's binding (save %d vs DC %d)." % [target.unit_name, save_roll, save_dc])

	return {
		"success": true,
		"hit": true,
		"damage": total_damage,
		"target": target,
		"subjugated": subjugated,
		"effects": [{"type": "aoe_damage", "target": target, "damage": total_damage}]
	}


## Get valid target tiles for an active skill based on its targeting type
func get_active_skill_targets(user: Node, combat_data: Dictionary) -> Array[Vector2i]:
	var targeting = combat_data.get("targeting", "self")
	var skill_range = combat_data.get("range", 1)
	var result: Array[Vector2i] = []

	match targeting:
		"self":
			result.append(user.grid_position)
		"single_enemy":
			# All enemy tiles within range (hidden enemies excluded)
			for unit in all_units:
				if not unit.is_alive() or unit.team == user.team:
					continue
				if not unit.is_targetable():
					continue
				var dist = _grid_distance(user.grid_position, unit.grid_position)
				if dist <= skill_range:
					result.append(unit.grid_position)
		"single_ally":
			for unit in all_units:
				if not unit.is_alive() or unit.team != user.team:
					continue
				var dist = _grid_distance(user.grid_position, unit.grid_position)
				if dist <= skill_range:
					result.append(unit.grid_position)
		"downed_ally":
			# is_alive() is false for a bleeding-out unit, so single_ally can
			# never see the ally a revive exists to reach.
			for unit in all_units:
				if unit.team != user.team:
					continue
				if not (unit.is_bleeding_out or unit.is_dead):
					continue
				var dist = _grid_distance(user.grid_position, unit.grid_position)
				if dist <= skill_range:
					result.append(unit.grid_position)
		"aoe_point":
			# Any tile within range
			if combat_grid:
				for x in range(combat_grid.grid_width):
					for y in range(combat_grid.grid_height):
						var tile = Vector2i(x, y)
						var dist = _grid_distance(user.grid_position, tile)
						if dist <= skill_range:
							result.append(tile)
		"teleport":
			# Any walkable unoccupied tile within range
			if combat_grid:
				for x in range(combat_grid.grid_width):
					for y in range(combat_grid.grid_height):
						var tile = Vector2i(x, y)
						var dist = _grid_distance(user.grid_position, tile)
						if dist <= skill_range and combat_grid.is_tile_walkable(tile):
							var unit_at = combat_grid.get_unit_at(tile)
							if unit_at == null or unit_at == user:
								result.append(tile)
		"dash_attack":
			# All enemy tiles within dash_range + attack_range
			var dash_range = combat_data.get("dash_range", 2)
			var attack_range = user.get_attack_range()
			for unit in all_units:
				if not unit.is_alive() or unit.team == user.team:
					continue
				if not unit.is_targetable():
					continue
				var dist = _grid_distance(user.grid_position, unit.grid_position)
				if dist <= dash_range + attack_range:
					result.append(unit.grid_position)

	return result


## Map a perk's skill name to the weapon types that satisfy it.
## Returns an empty array if the skill doesn't require a specific weapon.
func get_required_weapon_types(skill_name: String) -> Array:
	match skill_name:
		"swords":
			return ["sword"]
		"axes":
			return ["axe"]
		"maces":
			return ["mace"]
		"spears":
			return ["spear"]
		"daggers":
			return ["dagger"]
		"ranged":
			return ["bow", "thrown"]
		"unarmed":
			return ["unarmed"]  # Special: must have NO weapon equipped
		"martial_arts":
			return ["staff", "unarmed"]  # Staff or bare-handed
		_:
			return []  # Non-weapon skills (might, medicine, etc.) — no requirement


## Check if a unit has the right weapon equipped for a given perk skill.
## Returns true if the weapon requirement is satisfied.
func unit_has_required_weapon(unit: Node, skill_name: String) -> bool:
	var required = get_required_weapon_types(skill_name)
	if required.is_empty():
		return true  # No weapon requirement

	var weapon = unit.get_equipped_weapon()
	var weapon_type = weapon.get("type", "") if not weapon.is_empty() else ""

	# "unarmed" means no weapon equipped
	if "unarmed" in required:
		if weapon.is_empty() or weapon_type == "":
			return true

	# Check if the equipped weapon type is in the required list
	if weapon_type in required:
		return true

	return false


# ============================================
# PASSIVE PERK COMBAT INTEGRATION
# ============================================
# Framework for checking passive perks during combat events.
# Passive perks (no combat_data) describe effects in text; this section
# implements the mechanical effects for the most impactful ones.
#
# Perk checking helpers:
# - _unit_has_perk(unit, perk_id) -> bool
# - _get_passive_stat_bonus(unit, stat) -> int/float
# - _process_on_hit_perks(attacker, defender, result) -> void
# - _process_on_dodge_perks(unit, attacker) -> void
# - _process_turn_start_perks(unit) -> void


## Check if a combat unit has a specific perk.
## Works for both CombatUnit nodes and basic unit nodes with character_data.
func _unit_has_perk(unit: Node, perk_id: String) -> bool:
	var char_data = unit.character_data if "character_data" in unit else {}
	return PerkSystem.has_perk(char_data, perk_id)


## Get all talisman perk IDs for a unit (from trinket1 and trinket2 slots)
func _get_talisman_perks(unit: Node) -> Array[String]:
	var perks: Array[String] = []
	var char_data = unit.character_data if "character_data" in unit else {}
	var equipment = char_data.get("equipment", {})
	for slot in ["trinket1", "trinket2"]:
		var item_id = equipment.get(slot, "")
		if item_id == "":
			continue
		var item = ItemSystem.get_item(item_id)
		var perk_id = item.get("passive", {}).get("perk", "")
		if perk_id != "":
			perks.append(perk_id)
	return perks


## Check if a unit has a specific talisman perk
func _unit_has_talisman_perk(unit: Node, perk_id: String) -> bool:
	return perk_id in _get_talisman_perks(unit)


## Check if a character perk grants immunity or resistance to a status effect.
## Returns true if the status should be blocked.
## `source` is the unit applying it, when there is one — a few immunities
## depend on WHO is doing it (Undead Hunter only refuses undead and diseased
## attackers), not just what is being done.
func _check_perk_status_immunity(unit: Node, status: String, source: Node = null) -> bool:
	var char_data = unit.character_data if "character_data" in unit else {}
	var status_lower = status.to_lower()

	# Diamond Body: immune to poison and disease while unarmored
	if PerkSystem.has_perk(char_data, "diamond_body") and _unit_is_unarmored(unit):
		if status_lower in ["poisoned", "diseased"]:
			return true

	# Undead Hunter: immune to the diseases undead and diseased enemies carry.
	# Only from those enemies — a plague spell from a living caster, or a
	# disease from an event, still lands. Covers both the Diseased status and
	# the persistent disease an undead hit can leave (the on-hit procs ask here).
	if status_lower == "diseased" and PerkSystem.has_perk(char_data, "undead_hunter") \
			and _is_undead_or_diseased(source):
		return true

	# Empty Center: +20% resistance to mental effects
	# Centered Stance: +15% resistance to mental effects while wielding a sword
	var mental_statuses = ["feared", "charmed", "confused", "berserk", "mind_controlled"]
	if status_lower in mental_statuses:
		var mental_resist_pct = 0.0
		if PerkSystem.has_perk(char_data, "empty_center"):
			mental_resist_pct += 0.20
		if PerkSystem.has_perk(char_data, "centered_stance"):
			if unit.has_method("get_equipped_weapon"):
				if unit.get_equipped_weapon().get("type", "") == "sword":
					mental_resist_pct += 0.15
		if mental_resist_pct > 0.0 and randf() < mental_resist_pct:
			return true

	# Empty Center: +25% save vs forced movement, stuns, knockdowns
	var physical_cc = ["stunned", "knocked_down", "pushed", "pulled"]
	if status_lower in physical_cc:
		if PerkSystem.has_perk(char_data, "empty_center"):
			if randf() < 0.25:
				return true

	# Diamond Body while unarmored: +25% general status resistance
	if PerkSystem.has_perk(char_data, "diamond_body") and _unit_is_unarmored(unit):
		if randf() < 0.25:
			return true

	# Laughing at the Abyss: immune to fear, despair, intimidation
	var comedy_immune = ["feared", "intimidated", "demoralized", "despair"]
	if status_lower in comedy_immune:
		if PerkSystem.has_perk(char_data, "laughing_at_the_abyss"):
			return true

	# Bare Chest: +25% resistance to fear and pain effects while unarmored or in light armor
	var fear_pain = ["feared", "agonized", "pain"]
	if status_lower in fear_pain:
		if PerkSystem.has_perk(char_data, "bare_chest") and _unit_is_unarmored(unit, true):
			if randf() < 0.25:
				return true

	# Juggernaut: at 50%+ HP, immune to Slow, knockback, and forced movement
	var juggernaut_immune = ["slowed", "pushed", "pulled", "knocked_back", "rooted"]
	if status_lower in juggernaut_immune:
		if PerkSystem.has_perk(char_data, "juggernaut"):
			if "current_hp" in unit and "max_hp" in unit:
				if unit.current_hp >= unit.max_hp * 0.5:
					return true

	# Pain Is Just Information (Might 4): +25% resistance to Stun, Knockdown, and Exhaustion
	var pain_immune = ["stunned", "knocked_down", "exhausted"]
	if status_lower in pain_immune:
		if PerkSystem.has_perk(char_data, "pain_is_just_information"):
			if randf() < 0.25:
				return true

	# Unbroken Circle (Leadership 4): +15% mental status resistance with 2+ allies standing
	var mental_cc = ["feared", "charmed", "confused", "berserk", "mind_controlled", "intimidated", "demoralized"]
	if status_lower in mental_cc:
		var ub_ally_count = get_team_units(unit.team if "team" in unit else 0).size() - 1
		if ub_ally_count >= 2:
			var ub_resist = 0.15 + 0.03 * (ub_ally_count - 2)  # +3% per additional ally
			# Also check if any ally has the perk (aura) or if the unit itself has it
			var has_leader = PerkSystem.has_perk(char_data, "unbroken_circle")
			if not has_leader:
				for ally in get_team_units(unit.team if "team" in unit else 0):
					if ally == unit: continue
					var ally_char = ally.character_data if "character_data" in ally else {}
					if PerkSystem.has_perk(ally_char, "unbroken_circle"):
						has_leader = true
						break
			if has_leader and randf() < ub_resist:
				return true

	return false


## Returns true if the unit is tagged as biological (affected by anatomy_knowledge, pressure_points).
## Non-biological: constructs, elementals, undead, ethereals.
func _unit_is_biological(unit: Node) -> bool:
	var char_data = unit.character_data if "character_data" in unit else {}
	return "biological" in char_data.get("tags", [])


## True when `unit` is an undead or diseased enemy — the attackers whose hits
## can leave a disease, and the ones Undead Hunter is immune to. A null unit
## (a status with no source, e.g. from terrain or an event) is neither.
func _is_undead_or_diseased(unit: Node) -> bool:
	if unit == null or not "character_data" in unit:
		return false
	var tags: Array = unit.character_data.get("tags", [])
	return "undead" in tags or "diseased" in tags


## Worn item types that are clothing, not armour. Wearing any of these still
## counts as "unarmored": a monk in robe, trousers, sandals and wraps is the
## person Diamond Body and Flowing Footwork were written for. Prosthetics are a
## replacement limb, not protection. Everything else in an armour slot —
## body armour, helmets, gauntlets, bracers, greaves — is armour.
const CLOTHING_TYPES: Array[String] = [
	"robe", "cloth", "hat", "circlet", "gloves", "pants", "leggings",
	"boots", "shoes", "sandals", "prosthetic",
]


## Is this unit unarmored — or, with `allow_light`, at most lightly armoured?
##
## The perks say two different things, and both are honoured here:
##   * "while unarmored" — Diamond Body, Iron Shirt Technique. No armour piece
##     on at all; clothing (CLOTHING_TYPES) is fine.
##   * "while unarmored or in light armor" — Flowing Footwork, Bare Chest and
##     the `unarmored_or_light` condition. Armour is allowed as long as no piece
##     is HEAVY, and heavy means a Strength requirement — the same rule as
##     `wearing_heavy_armor` (CombatUnit.is_wearing_heavy_armor), and exactly
##     what generate_armor writes for its heavy pieces.
##
## Every armour slot is read: head, chest, legs, feet and every hand slot
## (`hand_l`, `hand_r`, and a multi-armed body's `hand_l2`/`hand_r2`). This
## used to read a `hands` slot that does not exist, so gauntlets never counted
## as armour — while trousers and boots, which are clothing, did.
func _unit_is_unarmored(unit: Node, allow_light: bool = false) -> bool:
	var char_data = unit.character_data if "character_data" in unit else {}
	var equipment: Dictionary = char_data.get("equipment", {})
	for slot in equipment:
		var slot_name := str(slot)
		var is_armour_slot: bool = slot_name in ["head", "chest", "legs", "feet"] \
			or slot_name.begins_with("hand_")
		if not is_armour_slot:
			continue
		var item_id = equipment[slot]
		if not item_id is String or item_id == "":
			continue
		var item: Dictionary = ItemSystem.get_item(item_id)
		var item_type := str(item.get("type", ""))
		# No type at all is not something we can call armour.
		if item_type == "" or item_type in CLOTHING_TYPES:
			continue
		# An armour piece. Strictly unarmored: that settles it.
		if not allow_light:
			return false
		# Light armour is allowed; heavy (needs Strength) is not.
		if ItemSystem.is_heavy_armor_piece(item):
			return false
	return true


## Every standing bonus to `stat` that is computed fresh rather than stored:
## perks, equipment passives, and auras projected by anyone on the field.
##
## Called by the CombatUnit stat getters. Nothing here is ever written to the
## unit, which is precisely what makes it safe — a bonus that stops applying
## (the aura walked away, the weapon was swapped) disappears because the next
## read does not find it, with no reset step to forget.
##
## Named for perks alone until auras joined it; the shape was always "what does
## this unit get right now, from everything around it".
## The percentage change to `unit`'s spell costs from stat.mana_cost_pct: an
## Inscribed Circle under it, or anything else holding that value.
func mana_cost_pct_of(unit: Node) -> int:
	return int(round(ValuePaths.apply_to(unit, "stat.mana_cost_pct", 0.0)))


func get_continuous_stat_bonus(unit: Node, stat: String) -> int:
	var total := 0
	var char_data = unit.character_data if "character_data" in unit else {}

	# Auras and zones are not added here any more: their modifies are
	# read-time and reach the getters through ValuePaths (AuraSystem.contributions).

	# --- Equipment-based bonuses (apply regardless of whether the unit has perks) ---
	match stat:
		"armor":
			# Bichawa parry: off-hand Bichawa adds (accuracy × parry_effectiveness / 100) to armor
			var bichawa_id = ItemSystem.get_equipped_item(char_data, "weapon_off")
			if bichawa_id != "":
				var bichawa_item = ItemSystem.get_item(bichawa_id)
				var parry_eff = bichawa_item.get("stats", {}).get("parry_effectiveness", 0)
				if parry_eff > 0:
					var acc = unit.get_accuracy() if unit.has_method("get_accuracy") else 0
					total += int(acc * parry_eff / 100.0)
	if not char_data.has("perks"):
		return total  # No perks — return equipment-only bonuses

	match stat:
		"armor":
			# Parry: 20% of Attack added to Armor while wielding a sword
			if PerkSystem.has_perk(char_data, "parry"):
				if unit.has_method("get_equipped_weapon"):
					var weapon = unit.get_equipped_weapon()
					if weapon.get("type", "") == "sword":
						var attack = unit.get_accuracy() if unit.has_method("get_accuracy") else 0
						total += int(attack * 0.2)
			# Improved Parry: 40% of Attack added to Armor
			if PerkSystem.has_perk(char_data, "improved_parry"):
				if unit.has_method("get_equipped_weapon"):
					var weapon = unit.get_equipped_weapon()
					if weapon.get("type", "") == "sword":
						var attack = unit.get_accuracy() if unit.has_method("get_accuracy") else 0
						# Improved replaces base parry bonus (not additive)
						total += int(attack * 0.2)  # Extra 20% on top of parry's 20%
			# Stone Adept: +10% Armor (use base derived armor to avoid recursion)
			if PerkSystem.has_perk(char_data, "stone_adept"):
				var derived = char_data.get("derived", {})
				total += int(derived.get("armor", 0) * 0.1)
			# Iron Shirt Technique: 30% of unarmed Attack added to Armor while unarmored
			if PerkSystem.has_perk(char_data, "iron_shirt_technique"):
				if _unit_is_unarmored(unit):
					var unarmed_attack = unit.get_attack_damage() if unit.has_method("get_attack_damage") else 0
					total += int(unarmed_attack * 0.3)
			# Tidal Patience: +5% Armor per stationary stack (up to +15%)
			if PerkSystem.has_perk(char_data, "tidal_patience"):
				if "stationary_stacks" in unit and unit.stationary_stacks > 0:
					var derived_armor = char_data.get("derived", {}).get("armor", 0)
					total += int(derived_armor * 0.05 * unit.stationary_stacks)
			# Disciplined Formation: +10% Armor while adjacent to an ally
			if PerkSystem.has_perk(char_data, "disciplined_formation"):
				var allies = _get_allies_in_range(unit, 1)
				if allies.size() > 0:
					var derived_armor = char_data.get("derived", {}).get("armor", 0)
					total += int(derived_armor * 0.1)
			# Grounded (Might 2): +15% Armor when you haven't moved this turn
			if PerkSystem.has_perk(char_data, "grounded"):
				if not ("moved_this_turn" in unit and unit.moved_this_turn):
					var derived_armor = char_data.get("derived", {}).get("armor", 0)
					total += int(derived_armor * 0.15)
			# No One Left Behind (Leadership 3): when below 30% HP, gain +20% Armor if any ally has this perk
			if "current_hp" in unit and "max_hp" in unit:
				if unit.current_hp < unit.max_hp * 0.30:
					var leader_present = PerkSystem.has_perk(char_data, "no_one_left_behind")
					if not leader_present:
						for ally in get_team_units(unit.team if "team" in unit else 0):
							if ally == unit: continue
							var ally_char = ally.character_data if "character_data" in ally else {}
							if PerkSystem.has_perk(ally_char, "no_one_left_behind"):
								leader_present = true
								break
					if leader_present:
						var derived_armor = char_data.get("derived", {}).get("armor", 0)
						total += int(derived_armor * 0.20)

		"damage":
			# Use base derived damage to avoid recursion (get_attack_damage calls us)
			var derived_dmg = char_data.get("derived", {}).get("damage", 0)
			# All In: +25% axe damage below 50% HP
			if PerkSystem.has_perk(char_data, "all_in"):
				if "current_hp" in unit and "max_hp" in unit:
					if unit.current_hp < unit.max_hp / 2:
						if unit.has_method("get_equipped_weapon"):
							if unit.get_equipped_weapon().get("type", "") == "axe":
								total += int(derived_dmg * 0.25)
			# Weapon Master: +10% all weapon damage
			if PerkSystem.has_perk(char_data, "weapon_master"):
				total += int(derived_dmg * 0.1)
			# Commitment: +20% damage if you did not move before attacking
			if PerkSystem.has_perk(char_data, "commitment"):
				if not ("moved_this_turn" in unit and unit.moved_this_turn):
					if unit.has_method("get_equipped_weapon"):
						if unit.get_equipped_weapon().get("type", "") == "axe":
							total += int(derived_dmg * 0.2)
			# Momentum: +10% damage per consecutive axe hit stack
			if PerkSystem.has_perk(char_data, "momentum"):
				if "momentum_stacks" in unit and unit.momentum_stacks > 0:
					if unit.has_method("get_equipped_weapon"):
						if unit.get_equipped_weapon().get("type", "") == "axe":
							total += int(derived_dmg * 0.1 * unit.momentum_stacks)
			# Keep Hitting: +10% damage per consecutive unarmed hit stack
			if PerkSystem.has_perk(char_data, "keep_hitting"):
				if "unarmed_hit_stacks" in unit and unit.unarmed_hit_stacks > 0:
					if unit.has_method("get_equipped_weapon"):
						var w = unit.get_equipped_weapon()
						if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
							total += int(derived_dmg * 0.1 * unit.unarmed_hit_stacks)
			# Tidal Patience: +5% Damage per stationary stack (up to +15%)
			if PerkSystem.has_perk(char_data, "tidal_patience"):
				if "stationary_stacks" in unit and unit.stationary_stacks > 0:
					total += int(derived_dmg * 0.05 * unit.stationary_stacks)
			# Disciplined Formation: +10% damage (accuracy) while adjacent to an ally
			if PerkSystem.has_perk(char_data, "disciplined_formation"):
				if _get_allies_in_range(unit, 1).size() > 0:
					total += int(derived_dmg * 0.1)

		"max_hp":
			# Stone Adept: +10% max HP
			if PerkSystem.has_perk(char_data, "stone_adept"):
				total += int(unit.max_hp * 0.1) if "max_hp" in unit else 0

		"initiative":
			# Centered Stance: +10% Initiative while wielding a sword
			if PerkSystem.has_perk(char_data, "centered_stance"):
				if unit.has_method("get_equipped_weapon"):
					if unit.get_equipped_weapon().get("type", "") == "sword":
						var derived_init = char_data.get("derived", {}).get("initiative", 0)
						total += int(derived_init * 0.1)

		"movement":
			# Wind Adept: +1 permanent Movement
			if PerkSystem.has_perk(char_data, "wind_adept"):
				total += 1
			# Flowing Footwork: +1 Movement while unarmored or in light armor
			if PerkSystem.has_perk(char_data, "flowing_footwork"):
				if _unit_is_unarmored(unit, true):
					total += 1

		"crit_chance":
			# Open the Gate: +15% crit chance after moving at least 1 tile this turn
			if PerkSystem.has_perk(char_data, "open_the_gate"):
				if "moved_this_turn" in unit and unit.moved_this_turn:
					total += 15
			# Short Range Violence: +10% crit with unarmed attacks
			if PerkSystem.has_perk(char_data, "short_range_violence"):
				if unit.has_method("get_equipped_weapon"):
					var w = unit.get_equipped_weapon()
					if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
						total += 10

		"dodge":
			# Flowing Footwork: +10% Dodge while unarmored or in light armor
			if PerkSystem.has_perk(char_data, "flowing_footwork"):
				if _unit_is_unarmored(unit, true):
					total += 10
			# Summoner's Bond: +5% Dodge/saves while 1+ summon is active
			# (Summons are units with the 'summoned' tag on their character_data)
			if PerkSystem.has_perk(char_data, "summoners_bond"):
				for ally in get_team_units(unit.team if "team" in unit else 0):
					var ally_char = ally.character_data if "character_data" in ally else {}
					if "summoned" in ally_char.get("tags", []):
						total += 5
						break
			# Talisman: Blur — +10% dodge chance
			if _unit_has_talisman_perk(unit, "blur"):
				total += 10
			# Talisman: Lucky Escape — +15% dodge below 25% HP
			if _unit_has_talisman_perk(unit, "lucky_escape"):
				if "current_hp" in unit and "max_hp" in unit:
					if unit.current_hp < unit.max_hp * 0.25:
						total += 15

	return total


## Process on-hit procs from weapon passive dict.
## ── Data-driven passive triggers ─────────────────────────────────────────────
## Sits alongside _process_on_hit_perks() and friends, which stay as the home
## for the 164 perks wired by id. This is for perks that describe themselves in
## an `effects` array instead. A perk uses one mechanism or the other — never
## both, or it fires twice — verify_passive_perks (_check_no_double_wiring)
## fails on any perk that is both.
func _fire_perk_triggers(unit: Node, trigger: String, context: Dictionary = {}) -> void:
	if unit == null or not "character_data" in unit or not PerkSystem:
		return
	# Re-entrancy guard. A payload can cause the very thing that fires a
	# trigger: a take_damage perk that hurt its attacker would fire the
	# attacker's take_damage, whose answer fires ours, and round it goes. So
	# while one trigger's payload is resolving, no other trigger fires — the
	# answer to an answer is silence, never a loop.
	if _resolving_perk_trigger:
		return
	if not CombatStats.is_perk_trigger(trigger):
		push_error("CombatManager: _fire_perk_triggers called with '%s', which is not in CombatStats.PERK_TRIGGERS"
			% trigger)
		return
	# The other unit in this moment, for conditions like target_bleeding: the
	# one hit, or the attacker that missed, or failing both nobody.
	var other: Node = context.get("target", context.get("attacker", null))
	for entry in PerkSystem.get_combat_passives(unit.character_data):
		var effect: Dictionary = entry.effect
		if effect.get("type", "") != "on_trigger":
			continue
		if effect.get("trigger", "") != trigger:
			continue
		if unit.has_method("_all_perk_conditions_met") \
				and not unit._all_perk_conditions_met(effect.get("conditions", []), other):
			continue
		var chance: float = float(effect.get("chance", 100))
		if chance < 100.0 and randf() * 100.0 > chance:
			continue
		_resolving_perk_trigger = true
		_apply_trigger_effect(unit, entry.perk_id, effect.get("effect", {}), context)
		_resolving_perk_trigger = false


## True while a perk trigger's payload is being resolved. See _fire_perk_triggers.
var _resolving_perk_trigger: bool = false


## take_damage for the hurt unit, ally_damaged for each living teammate.
## Called from apply_damage() once damage has actually landed.
func _fire_damage_triggers(unit: Node, damage: int, damage_type: String, source: Node) -> void:
	var context := {"damage": damage, "damage_type": damage_type}
	if source != null and is_instance_valid(source) and source != unit:
		context["attacker"] = source
	# A unit that just went down does not react to it.
	if unit.is_alive():
		_fire_perk_triggers(unit, "take_damage", context)
	var ally_context := context.duplicate()
	ally_context["ally"] = unit
	for ally in get_team_units(unit.team if "team" in unit else 0):
		if ally == unit or not ally.is_alive():
			continue
		_fire_perk_triggers(ally, "ally_damaged", ally_context)


## A miss counts as a parry when it was a melee blow and the defender had a
## melee weapon in hand to turn it with.
## dodge_success is "a melee attack missed you" (Borrowed Opening's text says
## so): an arrow that misses fires nothing.
func _fire_dodge_success(defender: Node, attacker: Node, attack_was_ranged: bool) -> void:
	if attack_was_ranged:
		return
	_fire_perk_triggers(defender, "dodge_success", {"attacker": attacker})


func _is_parry(defender: Node, attacker: Node, attack_was_ranged: bool) -> bool:
	if attack_was_ranged or attacker == null or not defender.has_method("get_equipped_weapon"):
		return false
	if defender.get_equipped_weapon().is_empty():
		return false   # bare hands block nothing
	if defender.has_method("is_ranged_weapon") and defender.is_ranged_weapon():
		return false   # nor does a bow
	return true


## True when `unit` carries any status whose definition is negative (polarity) —
## the same test _apply_status_effect uses for debuff immunity.
func unit_has_debuff(unit: Node) -> bool:
	if unit == null or not "status_effects" in unit:
		return false
	for effect in unit.status_effects:
		if _status_effects.get(effect.get("status", ""), {}).get("polarity", "") == "negative":
			return true
	return false


## Resolve one fired trigger's payload.
func _apply_trigger_effect(unit: Node, perk_id: String, payload: Dictionary,
		context: Dictionary) -> void:
	# Who the payload lands on: "self" (default), "attacker", "victim" (the
	# one this unit hit), or "ally" (the teammate an ally_damaged is about).
	# A payload aimed at someone the moment does not have is dropped rather
	# than redirected onto self — "burn the attacker" must not burn you.
	var target: Node = unit
	match payload.get("target", "self"):
		"attacker":
			target = context.get("attacker", null)
		"victim":
			target = context.get("target", null)
		"ally":
			target = context.get("ally", null)
	if target == null or not is_instance_valid(target) or not target.is_alive():
		return

	match payload.get("type", ""):
		"buff":
			# `until_next_attack`: lasts until the target's next attack (see
			# _apply_next_attack_modifier) instead of a number of turns.
			if payload.get("until_next_attack", false):
				_apply_next_attack_modifier(target, payload.get("stat", ""),
					int(payload.get("value", 0)))
			else:
				_apply_stat_modifier(target, payload.get("stat", ""),
					int(payload.get("value", 0)), int(payload.get("duration", 1)))
		"status":
			_apply_status_effect(target, payload.get("status", ""),
				int(payload.get("duration", 1)), 0, unit)
		"heal":
			if target.has_method("heal"):
				target.heal(int(payload.get("value", 0)))
		"restore_stamina":
			if target.has_method("restore_stamina"):
				target.restore_stamina(int(payload.get("value", 0)))
		_:
			push_error("CombatManager: perk '%s' has an on_trigger payload of unknown type '%s'"
				% [perk_id, payload.get("type", "")])
			return
	combat_log.emit("%s: %s" % [unit.unit_name, PerkSystem.get_perk_data(perk_id).get("name", perk_id)])


## Apply a status as part of a hit — a perk proc, a weapon proc, an oil, an
## arrow, a spell perk's rider. Exactly _apply_status_effect(), except that a
## defender the hit has already dropped gets nothing.
##
## Every on-hit proc runs AFTER the damage lands, so the blow that drops a
## unit used to go on to stun, daze and poison the body. A bleeding-out unit
## does not tick statuses, so the stun simply waited — and the ally who revived
## them got back someone who lost their first turn to a mace that had already
## finished with them.
func _apply_on_hit_status(defender: Node, status: String, duration: int,
		value: int = 0, source: Node = null) -> void:
	if not is_instance_valid(defender) or not defender.is_alive():
		return
	_apply_status_effect(defender, status, duration, value, source)


## Called through _resolve_hit_procs() after a blow's damage lands — by the
## primary hit and by every extra arm of a multi-arm chain.
## proc_scale (0–1) scales the persistent afflictions only (crit wounds,
## diseases, poisoned blood); see _resolve_hit_procs.
## extra_arm=true skips Chakram pass_through: that is the THROWN ring flying on
## through the line, one flight per attack. Arm chains are melee-only, so this
## cannot come up today, but an arm swing must never launch a second flight.
func _process_weapon_on_hit_procs(attacker: Node, defender: Node, result: Dictionary,
		proc_scale: float = 1.0, extra_arm: bool = false) -> void:
	if not attacker.has_method("get_equipped_weapon"):
		return
	var weapon = attacker.get_equipped_weapon()

	# Trishula on_crit_status: apply a status when this attack was a crit
	if result.get("crit", false):
		var on_crit_status = weapon.get("on_crit_status", "")
		if on_crit_status != "":
			_apply_on_hit_status(defender, on_crit_status, 1)
			result["on_crit_status"] = on_crit_status
		# 20% chance a crit inflicts a persistent wound on player characters.
		# Hardened gives a 50% chance to negate it — see _crit_wound_negated.
		# Ranged weapons (skill_tag: "ranged") draw from the ranged wound pool.
		if WoundSystem and defender.team == Team.PLAYER and randf() < 0.20 * proc_scale:
			var char_data = defender.character_data
			if not _crit_wound_negated(defender):
				var is_ranged: bool = weapon.get("skill_tag", "") == "ranged"
				var wound_id: String
				if is_ranged:
					wound_id = WoundSystem.apply_random_ranged_crit_wound(char_data)
				else:
					wound_id = WoundSystem.apply_random_crit_wound(char_data)
				if wound_id != "":
					combat_log.emit("%s received a %s!" % [
						defender.unit_name,
						WoundSystem.WOUND_TYPES.get(wound_id, {}).get("display_name", wound_id)
					])
					result["persistent_wound"] = wound_id

	# 15% chance hits from undead/diseased enemies inflict a disease on player characters.
	# 15% chance hits from poison-tagged enemies inflict poisoned blood.
	# Both procs ask _check_perk_status_immunity first, which is where Undead
	# Hunter (disease, from these attackers only) and Diamond Body (disease and
	# poison, while unarmored) live — no perk is checked by id here.
	if WoundSystem and attacker.team == Team.ENEMY and defender.team == Team.PLAYER:
		var attacker_tags: Array = attacker.character_data.get("tags", [])
		# Perk immunities are checked here as well as for the Diseased status:
		# Diamond Body claims immunity to disease, and catching rot sickness from
		# an undead hit is exactly the thing it is claiming immunity to. Reusing
		# _check_perk_status_immunity keeps its "while unarmored" condition,
		# which a trait-granted resistance could not express.
		if ("undead" in attacker_tags or "diseased" in attacker_tags) and randf() < 0.15 * proc_scale \
				and not _check_perk_status_immunity(defender, "diseased", attacker):
			var tag_source = "undead" if "undead" in attacker_tags else "diseased"
			var char_data = defender.character_data
			var disease_id = WoundSystem.apply_random_disease(char_data, tag_source)
			if disease_id != "":
				combat_log.emit("%s has been afflicted with %s!" % [
					defender.unit_name,
					WoundSystem.WOUND_TYPES.get(disease_id, {}).get("display_name", disease_id)
				])
				result["persistent_disease"] = disease_id
		elif "poison" in attacker_tags and randf() < 0.15 * proc_scale \
				and not _check_perk_status_immunity(defender, "poisoned", attacker):
			var char_data = defender.character_data
			var disease_id = WoundSystem.apply_random_poison_disease(char_data)
			if disease_id != "":
				combat_log.emit("%s has been afflicted with %s!" % [
					defender.unit_name,
					WoundSystem.WOUND_TYPES.get(disease_id, {}).get("display_name", disease_id)
				])
				result["persistent_disease"] = disease_id

	# Chakram pass_through: hit the next unit in the attack line beyond the defender
	var pass_count: int = 0 if extra_arm else int(weapon.get("pass_through", 0))
	if pass_count > 0 and "grid_position" in attacker and "grid_position" in defender:
		var dir = (defender.grid_position - attacker.grid_position)
		var step_x: int = 0 if dir.x == 0 else (1 if dir.x > 0 else -1)
		var step_y: int = 0 if dir.y == 0 else (1 if dir.y > 0 else -1)
		var step := Vector2i(step_x, step_y)
		var check_pos: Vector2i = defender.grid_position + step
		var passed := 0
		for _i in range(10):  # sanity cap — walk forward through the grid
			if passed >= pass_count:
				break
			var through_target: Node = null
			for u in all_units:
				if u == attacker or u == defender:
					continue
				if "grid_position" in u and u.grid_position == check_pos and u.is_alive():
					through_target = u
					break
			if through_target != null:
				var pass_dmg = int(result.get("damage", 0) * 0.75)
				pass_dmg = maxi(1, pass_dmg)
				apply_damage(through_target, pass_dmg, result.get("damage_type", "physical"))
				combat_log.emit("%s's chakram passes through to %s!" % [attacker.unit_name, through_target.unit_name])
				result["pass_through_hit"] = true
				passed += 1
			check_pos += step

	var passive = weapon.get("passive", {})
	if passive.is_empty():
		return

	# Status procs — roll each chance independently
	var status_procs = {
		"poison_chance":  "Poisoned",
		"bleed_chance":   "Bleeding",
		"stun_chance":    "Stunned",
		"burn_chance":    "Burning",
		"freeze_chance":  "Chilled",
		"silence_chance": "Silenced",
	}
	var wielder_data: Dictionary = attacker.character_data if "character_data" in attacker else {}
	for key in status_procs:
		# The wielder's Ritual makes the proc land more often.
		if key in passive and randf() * 100.0 <= effective_status_chance(
				wielder_data, float(passive[key])):
			# The attacker is the source, so a burn or a venom applied by a
			# weapon scales with the skill of whoever swung it — the same way
			# one applied by a spell already did.
			_apply_on_hit_status(defender, status_procs[key], 3, 0, attacker)

	# Dispel: remove one random buff from the defender
	# status_effects is an Array of {status, duration} dicts — NOT a Dictionary
	if "dispel_chance" in passive and randf() * 100.0 <= passive["dispel_chance"]:
		if "status_effects" in defender:
			var buff_indices: Array = []
			for i in range(defender.status_effects.size()):
				var effect = defender.status_effects[i]
				var sdef = get_status_definition(effect.get("status", ""))
				if sdef.get("polarity", "negative") == "positive":
					buff_indices.append(i)
			if buff_indices.size() > 0:
				_end_status(defender, defender.status_effects[buff_indices[randi() % buff_indices.size()]],
					"dispelled")

	# Lifesteal
	if "lifesteal" in passive:
		var steal = int(result.get("damage", 0) * passive["lifesteal"] / 100.0)
		if steal > 0:
			attacker.heal(steal)
			unit_healed.emit(attacker, steal)
			result["weapon_lifesteal"] = steal

	# Manasteal
	if "manasteal" in passive:
		var steal_mana = int(result.get("damage", 0) * passive["manasteal"] / 100.0)
		if steal_mana > 0 and "current_mana" in defender:
			var actual = mini(steal_mana, defender.current_mana)
			defender.current_mana = defender.current_mana - actual
			attacker.restore_mana(actual)
			result["weapon_manasteal"] = actual

	# Elemental damage bonus attacks
	if "elemental_damage" in passive:
		for element in passive["elemental_damage"]:
			var dmg = passive["elemental_damage"][element]
			if dmg > 0:
				apply_damage(defender, dmg, element)
				if not "elemental_procs" in result:
					result["elemental_procs"] = {}
				result["elemental_procs"][element] = dmg


## Process special effects from ammo: fire arrow AoE or status proc arrows.
## Called on hit only — a missed shot produces no explosion or status.
## apply_damage() is used for AoE hits (handles death, bleed-out, mantra interruption).
func _process_ammo_special_effect(attacker: Node, defender: Node, ammo: Dictionary) -> void:
	var effect = ammo.get("special_effect", {})
	match effect.get("type", ""):

		"aoe_fire":
			var radius = effect.get("radius", 1)
			var aoe_damage = effect.get("damage", 10)
			var element = effect.get("element", "fire")
			combat_log.emit("%s's %s explodes!" % [attacker.unit_name, ammo.get("name", "arrow")])
			for unit in all_units:
				if not unit.is_alive():
					continue
				var dist = abs(unit.grid_position.x - defender.grid_position.x) \
						 + abs(unit.grid_position.y - defender.grid_position.y)
				if dist > 0 and dist <= radius:
					apply_damage(unit, aoe_damage, element)
					combat_log.emit("%s is caught in the explosion." % unit.unit_name)

		"status":
			var chance = effect.get("chance", 100)
			if randi() % 100 < chance:
				var status = effect.get("status", "")
				var duration = effect.get("duration", 2)
				if status != "":
					_apply_on_hit_status(defender, status, duration, 0, attacker)
					combat_log.emit("%s is afflicted with %s from the arrow." % [defender.unit_name, status])


## Deduct durability from the attacker's equipped weapon after use.
## Durability cost per attack comes from ItemSystem.get_item_fragility(), which
## answers for both item populations — generated items from the material they
## were built with, authored items from the material they now declare, at a
## gentler rate. Vajra and quest oddments still never degrade.
func _deduct_weapon_durability(unit: Node) -> void:
	if not unit.has_method("get_equipped_weapon"):
		return
	var weapon = unit.get_equipped_weapon()
	if weapon.is_empty():
		return
	var fragility: float = ItemSystem.get_item_fragility(weapon)
	if fragility <= 0.0:
		return  # Indestructible or not a generated item
	if not "character_data" in unit:
		return
	var item_id = ItemSystem.get_equipped_item(unit.character_data, "weapon_main")
	if item_id == "" or not item_id.begins_with("gen_"):
		return  # Static items don't track wear
	var current_dur: int = weapon.get("durability", 1)
	var new_dur: int = maxi(0, current_dur - int(ceil(fragility)))
	ItemSystem.update_item_durability(item_id, new_dur)
	if new_dur == 0:
		combat_log.emit("%s's %s has broken!" % [unit.unit_name, weapon.get("name", "weapon")])


## Process passive perks that trigger when a unit hits an enemy.
## Called from attack_unit() after damage is applied.
func _process_on_hit_perks(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not result.get("hit", false):
		return

	# Flame Fist: crits cause 3-turn burn on unarmed attacks
	if _unit_has_perk(attacker, "flame_fist") and result.get("crit", false):
		if attacker.has_method("get_equipped_weapon"):
			var weapon = attacker.get_equipped_weapon()
			if weapon.is_empty() or weapon.get("type", "") in ["", "unarmed"]:
				_apply_on_hit_status(defender, "Burning", 3)

	# Sudden End (Daggers 7): stealth first attack applies severe bleed (10% max HP/turn, 3t)
	if _unit_has_perk(attacker, "sudden_end") and "is_stealthed" in attacker and attacker.is_stealthed:
		var bleed_val = ceili(defender.max_hp * 0.10)
		_apply_on_hit_status(defender, "Bleeding", 3, bleed_val, attacker)

	# Relentless (Unarmed cross): crit with unarmed → free unarmed attack on the same target
	if _unit_has_perk(attacker, "relentless") and result.get("crit", false) and not attacker.in_free_attack:
		if attacker.has_method("get_equipped_weapon"):
			var rel_w = attacker.get_equipped_weapon()
			if rel_w.is_empty() or rel_w.get("type", "") in ["", "unarmed"]:
				_trigger_free_attack(attacker, defender)

	# Thunder Breaker: stuns also silence
	if _unit_has_perk(attacker, "thunder_breaker"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "mace":
				if defender.has_status("Stunned"):
					_apply_on_hit_status(defender, "Silenced", 1)

	# Curseblade: dagger crits have 30% chance to apply Weakness, Blind, or Slow for 2 turns
	if _unit_has_perk(attacker, "curseblade") and result.get("crit", false):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "dagger":
				if randf() < 0.30:
					var curses = ["Weakened", "Blinded", "Slowed"]
					var chosen = curses[randi() % curses.size()]
					_apply_on_hit_status(defender, chosen, 2, 0, attacker)
					result["curseblade_curse"] = chosen

	# Rattle the Cage: unarmed crits apply Stun for 1 turn
	if _unit_has_perk(attacker, "rattle_the_cage") and result.get("crit", false):
		if attacker.has_method("get_equipped_weapon"):
			var w = attacker.get_equipped_weapon()
			if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
				_apply_on_hit_status(defender, "Stunned", 1, 0, attacker)

	# See Stars: unarmed hit vs statused target → 25% chance Stun/Knockdown/Blind (1 turn)
	if _unit_has_perk(attacker, "see_stars"):
		if attacker.has_method("get_equipped_weapon"):
			var w = attacker.get_equipped_weapon()
			if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
				if "status_effects" in defender and defender.status_effects.size() > 0:
					if randf() < 0.25:
						var cc = ["Stunned", "Knocked_Down", "Blinded"]
						_apply_on_hit_status(defender, cc[randi() % cc.size()], 1, 0, attacker)

	# No Time to Breathe: unarmed hit → -5% dodge, -2 initiative on target (stackable, 2 turns)
	if _unit_has_perk(attacker, "no_time_to_breathe"):
		if attacker.has_method("get_equipped_weapon"):
			var w = attacker.get_equipped_weapon()
			if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
				_apply_stat_modifier(defender, "dodge", -5, 2)
				_apply_stat_modifier(defender, "initiative", -2, 2)

	# Heavy Swing: axe hits reduce target Armor by 5% for 1 turn (stacking)
	if _unit_has_perk(attacker, "heavy_swing"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "axe":
				var armor_pen = int(defender.get_armor() * 0.05)
				if armor_pen > 0:
					_apply_stat_modifier(defender, "armor", -armor_pen, 1)

	# Wide Arc: axe attack deals 50% splash damage to one random adjacent enemy
	if _unit_has_perk(attacker, "wide_arc"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "axe":
				var splash_targets = _get_enemies_in_range(attacker, 1)
				splash_targets.erase(defender)  # don't double-hit primary target
				if not splash_targets.is_empty():
					var splash_target = splash_targets[randi() % splash_targets.size()]
					var splash_dmg = maxi(1, result.get("damage", 0) / 2)
					apply_damage(splash_target, splash_dmg, result.get("damage_type", "slashing"))
					result["splash_damage"] = splash_dmg

	# Concussive Force: 20% chance to Daze target for 1 turn on any mace hit
	if _unit_has_perk(attacker, "concussive_force"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			if randf() < 0.20:
				_apply_on_hit_status(defender, "Dazed", 1, 0, attacker)

	# Shieldbreaker: mace hits reduce target Armor by 10% for 3 turns (stacking debuff)
	if _unit_has_perk(attacker, "shieldbreaker"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			var shatter_amt = int(defender.get_armor() * 0.10)
			if shatter_amt > 0:
				_apply_stat_modifier(defender, "armor", -shatter_amt, 3)

	# Thunderous Impact: mace crits knock defender prone (Knocked_Down) and Daze for 2 turns
	if _unit_has_perk(attacker, "thunderous_impact") and result.get("crit", false):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			_apply_on_hit_status(defender, "Knocked_Down", 1, 0, attacker)
			_apply_on_hit_status(defender, "Dazed", 2, 0, attacker)

	# Relentless Advance: mace hit grants +1 Move for 1 turn
	if _unit_has_perk(attacker, "relentless_advance"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			_apply_stat_modifier(attacker, "movement", 1, 1)

	# Exposed Target: ranged crits apply -15% Dodge debuff for 2 turns
	if _unit_has_perk(attacker, "exposed_target") and result.get("crit", false):
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			var dodge_pen = int(defender.get_dodge() * 0.15)
			if dodge_pen > 0:
				_apply_stat_modifier(defender, "dodge", -dodge_pen, 2)

	# Knife Storm: 25% chance of a free bonus dagger attack on hit (max 1 per turn)
	if _unit_has_perk(attacker, "knife_storm"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "dagger":
			if not attacker.knife_storm_proc_this_turn and randf() < 0.25:
				attacker.knife_storm_proc_this_turn = true
				# Execute a bonus attack at 75% damage (simplified — apply damage directly)
				var bonus_dmg_result = calculate_physical_damage(attacker, defender, "piercing")
				var bonus_dmg = int(bonus_dmg_result.damage * 0.75)
				bonus_dmg = maxi(1, bonus_dmg)
				apply_damage(defender, bonus_dmg, "piercing")
				result["knife_storm_damage"] = bonus_dmg

	# Flowing Tide: spear kill grants +2 Move for 1 turn
	if _unit_has_perk(attacker, "flowing_tide"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "spear":
			if not defender.is_alive():
				_apply_stat_modifier(attacker, "movement", 2, 1)

	# Maces stun. The skill table has carried a stun chance since before there
	# was anywhere to read it; this is that place. Mace only — the payout is for
	# swinging something blunt and heavy, not for hitting hard in general.
	if "character_data" in attacker and attacker.has_method("get_equipped_weapon"):
		if attacker.get_equipped_weapon().get("type", "") == "mace":
			var stun_pct: float = attacker.character_data.get("derived", {}).get(
				"stun_chance_pct", 0.0)
			if stun_pct > 0.0 and randf() * 100.0 < stun_pct:
				_apply_on_hit_status(defender, "Stunned", 1, 0, attacker)
				combat_log.emit("%s's mace rings %s's skull!"
					% [attacker.unit_name, defender.unit_name])

	# Put Your Weight Into It (Might 1): 15% chance to knockback 1 tile OR stun 1 turn on melee hit
	if _unit_has_perk(attacker, "put_your_weight_into_it"):
		var is_melee_hit = _grid_distance(attacker.grid_position, defender.grid_position) <= 1
		if is_melee_hit and randf() < ritual_chance(attacker, 0.15):
			if randf() < 0.5:
				_apply_on_hit_status(defender, "Knocked_Down", 1, 0, attacker)
			else:
				_apply_on_hit_status(defender, "Stunned", 1, 0, attacker)

	# Play Dirty (Guile 2): 20% chance to apply a random minor debuff on any hit
	if _unit_has_perk(attacker, "play_dirty") and randf() < ritual_chance(attacker, 0.20):
		var dirty_debuffs = ["Weakened", "Slowed", "Blinded", "Dodge_Debuff", "Damage_Debuff"]
		_apply_on_hit_status(defender, dirty_debuffs[randi() % dirty_debuffs.size()], 1, 0, attacker)

	# Nothing Wasted (Might 4): overkill — when killing a target, deal 50% of the kill-blow damage to 1 adjacent enemy
	if _unit_has_perk(attacker, "nothing_wasted") and not defender.is_alive():
		var splash_targets = _get_enemies_in_range(attacker, 1)
		splash_targets.erase(defender)
		if not splash_targets.is_empty():
			var splash_target = splash_targets[randi() % splash_targets.size()]
			var splash_dmg = maxi(1, result.get("damage", 0) / 2)
			apply_damage(splash_target, splash_dmg, result.get("damage_type", "crushing"))
			result["nothing_wasted_damage"] = splash_dmg

	# Press the Advantage (Leadership 4): killing an enemy grants nearby allies +3 Initiative & +10% Attack (2 turns)
	if _unit_has_perk(attacker, "press_the_advantage") and not defender.is_alive():
		var press_allies = _get_allies_in_range(attacker, 3)
		press_allies.erase(attacker)
		for ally in press_allies:
			_apply_stat_modifier(ally, "initiative", 3, 2)
			var ally_dmg = int(ally.get_attack_damage() * 0.10) if ally.has_method("get_attack_damage") else 2
			if ally_dmg > 0:
				_apply_stat_modifier(ally, "damage", ally_dmg, 2)
			# Psychology: rallying leadership inspires earth stability and fire drive in nearby allies
			if "character_data" in ally:
				PsychologySystem.apply_pressure(ally.character_data, "earth", 5.0)
				PsychologySystem.apply_pressure(ally.character_data, "fire", 3.0)

	# Avatar of the Storm (Air 5): all allies gain +5% Air bonus damage and 10% stun chance on attacks
	# Applied as an aura: if any ally of the attacker has this perk, the bonus applies
	var _aots_active = _unit_has_perk(attacker, "avatar_of_the_storm")
	if not _aots_active:
		for ally in get_team_units(attacker.team if "team" in attacker else 0):
			if ally != attacker and _unit_has_perk(ally, "avatar_of_the_storm"):
				_aots_active = true
				break
	if _aots_active:
		var aots_air_dmg = maxi(1, int(result.get("damage", 0) * 0.05))
		apply_damage(defender, aots_air_dmg, "lightning")
		result["aots_air_damage"] = aots_air_dmg
		if randf() < 0.10:
			_apply_on_hit_status(defender, "Stunned", 1, 0, attacker)

	# Static Edge (Air 1): attacks deal +10% weapon damage as bonus Air damage
	if _unit_has_perk(attacker, "static_edge"):
		var air_dmg = maxi(1, int(result.get("damage", 0) * 0.10))
		apply_damage(defender, air_dmg, "lightning")
		result["static_edge_damage"] = air_dmg

	# Cheap Shot: record that this enemy has now been attacked (removes the crit bonus on future attacks)
	if "enemies_hit_this_combat" in attacker and not defender in attacker.enemies_hit_this_combat:
		attacker.enemies_hit_this_combat.append(defender)

	# --- Update consecutive hit streaks ---
	if attacker.has_method("get_equipped_weapon"):
		var w = attacker.get_equipped_weapon()
		var weapon_type = w.get("type", "")
		if weapon_type == "axe":
			attacker.momentum_stacks += 1
		else:
			attacker.momentum_stacks = 0
		if w.is_empty() or weapon_type in ["", "unarmed"]:
			attacker.unarmed_hit_stacks += 1
			# One Mind, One Fist (cross-skill): unarmed hits during active mantras advance each mantra by +1
			if not attacker.active_mantras.is_empty():
				var att_char_omomof = attacker.character_data if "character_data" in attacker else {}
				if PerkSystem.has_perk(att_char_omomof, "one_mind_one_fist"):
					for m_id in attacker.active_mantras:
						attacker.active_mantras[m_id] += 1  # Extra progress point
		else:
			attacker.unarmed_hit_stacks = 0

	# Every Opening Is an Invitation: +10% crit vs statused — applied via get_continuous_stat_bonus
	# Anatomy Knowledge: +10% damage vs biological enemies — applied in calculate_physical_damage
	# Shadow Strike: stealth attacks auto-hit + crit (implemented in attack_unit)
	# Blood in the Wind: +movement when enemies bleeding (checked in stat getter)

	# Electrified_Weapon: stun_chance_on_hit — 25% chance to Stun defender for 1 turn on any hit
	if StatusRules.has_flag(attacker, "stun_chance_on_hit") and randf() < 0.25:
		_apply_on_hit_status(defender, "Stunned", 1, 0, attacker)
		result["electrified_stun"] = true

	# Pressure Points (Medicine 7): melee hits vs biological → 15% chance for random debuff
	var att_char_pp = attacker.character_data if "character_data" in attacker else {}
	if PerkSystem.has_perk(att_char_pp, "pressure_points"):
		var is_melee = _grid_distance(attacker.grid_position, defender.grid_position) <= 1
		if is_melee and _unit_is_biological(defender) and randf() < 0.15:
			# -10% Attack (Damage_Debuff), -10% Dodge (Dodge_Debuff), or -1 Movement (Slowed)
			var debuffs = ["Damage_Debuff", "Dodge_Debuff", "Slowed"]
			var chosen = debuffs[randi() % debuffs.size()]
			_apply_on_hit_status(defender, chosen, 2)

	# --- Talisman perk on-hit effects ---
	var talisman_perks = _get_talisman_perks(attacker)
	if not talisman_perks.is_empty():
		var base_damage = result.get("damage", 0)

		# Elemental brands: +X% of base damage as bonus elemental damage.
		# The second entry is a damage TYPE, not a school — Frost, Stone and
		# Storm brands dealt `water`, `earth` and `air` until 2026-10-15, which
		# nothing resists, so the brand's name is the guide: ice, crushing,
		# lightning. validate_data.py checks these literals.
		var brand_map = {
			"fire_brand_minor": ["fire", 0.05], "fire_brand": ["fire", 0.10], "fire_brand_greater": ["fire", 0.15],
			"water_brand_minor": ["ice", 0.05], "water_brand": ["ice", 0.10], "water_brand_greater": ["ice", 0.15],
			"earth_brand_minor": ["crushing", 0.05], "earth_brand": ["crushing", 0.10], "earth_brand_greater": ["crushing", 0.15],
			"air_brand_minor": ["lightning", 0.05], "air_brand": ["lightning", 0.10], "air_brand_greater": ["lightning", 0.15],
			"space_brand_minor": ["space", 0.05], "space_brand": ["space", 0.10], "space_brand_greater": ["space", 0.15],
			"phys_brand_minor": ["physical", 0.05], "phys_brand": ["physical", 0.10], "phys_brand_greater": ["physical", 0.15],
			"poison_brand_minor": ["poison", 0.05], "poison_brand": ["poison", 0.10], "poison_brand_greater": ["poison", 0.15],
		}

		for perk_id in talisman_perks:
			if perk_id in brand_map:
				var element = brand_map[perk_id][0]
				var pct = brand_map[perk_id][1]
				var bonus_dmg = ceili(base_damage * pct)
				if bonus_dmg > 0:
					apply_damage(defender, bonus_dmg, element)
					result["brand_damage"] = result.get("brand_damage", 0) + bonus_dmg
					result["brand_element"] = element

				# Poison brands also have a chance to inflict Poisoned
				if element == "poison":
					var poison_chance = pct  # 5/10/15%
					if randf() < poison_chance:
						# The attacker is the source, so their Alchemy's
						# poison_damage_pct scales this venom like any other.
						_apply_on_hit_status(defender, "Poisoned", 3, 0, attacker)

		# Lifesteal: heal 15% of attack damage dealt (Blood Pact boosts all lifesteal by 25%)
		if "lifesteal" in talisman_perks:
			var steal_pct = 0.15
			if _unit_has_perk(attacker, "blood_pact"):
				steal_pct *= 1.25
			var steal = int(base_damage * steal_pct)
			if steal > 0:
				attacker.heal(steal)
				unit_healed.emit(attacker, steal)
				result["talisman_lifesteal"] = steal

	# --- Status-based weapon enchant on-hit effects ---
	# Handles any "adds_X_damage_to_attacks" effect (fire, air, etc.)
	_process_status_weapon_enchants(attacker, defender, result)


## Process passive perks that trigger when a unit dodges an attack.
## Called from attack_unit() when the attack misses.
func _process_on_dodge_perks(unit: Node, attacker: Node) -> void:
	# Riposte: When you dodge or parry, next sword attack costs -2 Stamina and +25% damage
	if _unit_has_perk(unit, "riposte"):
		if unit.has_method("get_equipped_weapon"):
			if unit.get_equipped_weapon().get("type", "") == "sword":
				# Apply a temporary riposte buff (stored as status effect for tracking)
				# Duration 2: this fires on the enemy's turn, and a 1-turn status
				# would tick away at the start of yours, before the sword moved.
				_apply_status_effect(unit, "Riposte_Ready", 2, 25)  # value = damage bonus %

	# Borrowed Force: +30% damage bonus on next attack after dodging a melee attack
	if _unit_has_perk(unit, "borrowed_force"):
		var is_melee = _grid_distance(unit.grid_position, attacker.grid_position) <= 1
		if is_melee:
			var bonus = int(unit.get_attack_damage() * 0.3) if unit.has_method("get_attack_damage") else 5
			_apply_next_attack_modifier(unit, "damage", bonus)

	# Opportunist: when a melee attack misses you and you're holding a dagger, make a free counterattack
	if _unit_has_perk(unit, "opportunist"):
		var is_melee_miss = _grid_distance(unit.grid_position, attacker.grid_position) <= 1
		if is_melee_miss and unit.has_method("get_equipped_weapon"):
			if unit.get_equipped_weapon().get("type", "") == "dagger":
				# Free counter — apply 75% damage directly without consuming an action
				var counter_result = calculate_physical_damage(unit, attacker, "piercing")
				var counter_dmg = int(counter_result.damage * 0.75)
				counter_dmg = maxi(1, counter_dmg)
				apply_damage(attacker, counter_dmg, "piercing")
				unit_attacked.emit(unit, attacker, {"success": true, "hit": true, "damage": counter_dmg, "crit": false, "opportunist": true})


## Process passive perks at the start of a unit's turn.
## Called from _start_current_turn().
func _process_turn_start_perks(unit: Node) -> void:
	# (Timed stat modifiers are ticked once in _start_current_turn(), next to
	# the status tick — not here. Ticking them here as well halved them.)

	# Tick aggro-aura duration (look_at_me perk)
	if "taunt_active" in unit and unit.taunt_active:
		unit.taunt_duration -= 1
		if unit.taunt_duration <= 0:
			unit.taunt_active = false

	# Reset per-turn flags
	if unit.moved_this_turn:
		unit.stationary_stacks = 0  # Tidal Patience: reset if moved last turn
	else:
		unit.stationary_stacks = mini(unit.stationary_stacks + 1, 3)  # max 3 stacks
	unit.moved_this_turn = false
	unit.momentum_stacks = 0
	unit.unarmed_hit_stacks = 0
	unit.dagger_attacks_this_turn = 0
	unit.ranged_attacks_this_turn = 0
	unit.attacks_this_turn = 0
	unit.knife_storm_proc_this_turn = false
	unit.call_the_shot_used_this_turn = false
	# Call the Shot: mark on defender expires at the start of their own turn
	if "is_marked" in unit and unit.is_marked:
		unit.is_marked = false
		combat_log.emit("%s shakes off the mark." % unit.unit_name)

	# Diamond Body: +25% status resist (handled via saving throw bonuses)
	# Field Commander: companions reposition — only applies round 1 (handled in deployment)

	# Deep Freeze (Water 3): if a unit's effective movement has been reduced to 0 by ice/water debuffs, freeze it
	# Check at turn start — if movement stat is 0 and unit has a water debuff, apply Frozen
	if not unit.has_status("Frozen"):
		var cur_move = unit.get_movement() if unit.has_method("get_movement") else 99
		if cur_move <= 0:
			# Check if any caster with deep_freeze caused the movement penalty
			for caster_u in get_team_units(1 - unit.team if "team" in unit else 1):
				var caster_char_df = caster_u.character_data if "character_data" in caster_u else {}
				if PerkSystem.has_perk(caster_char_df, "deep_freeze"):
					_apply_status_effect(unit, "Frozen", 1, 0, caster_u)
					break

	# Avatar of the Wind (Air 5): all allies gain +1 Move, +2 Initiative, +5% Dodge each round.
	# Duration 2, refreshed rather than stacked: modifiers tick at the start of
	# their OWNER's turn, so a duration-1 buff laid on an ally here expired at
	# that ally's next turn start — before it ever acted with it. Two survives
	# that one tick, so every ally gets exactly one turn of its own with the
	# wind behind it, and the holder's next turn tops it back up.
	if _unit_has_perk(unit, "avatar_of_the_wind"):
		for ally in get_team_units(unit.team if "team" in unit else 0):
			if ally == unit: continue
			_refresh_stat_modifier(ally, "movement", 1, 2, "avatar_of_the_wind")
			_refresh_stat_modifier(ally, "initiative", 2, 2, "avatar_of_the_wind")
			_refresh_stat_modifier(ally, "dodge", 5, 2, "avatar_of_the_wind")

	# Hungry Flames (Fire 2): Burning enemies have 25% chance/turn to spread to 1 adjacent enemy
	# Processed on the perk-holder's turn rather than each burning enemy's turn
	if _unit_has_perk(unit, "hungry_flames"):
		var enemies = get_team_units(1 - unit.team if "team" in unit else 1)
		for enemy in enemies:
			if enemy.has_status("Burning") and randf() < 0.25:
				var adj_enemies = _get_enemies_in_range(enemy, 1)
				adj_enemies.erase(enemy)  # don't spread to self
				for adj in adj_enemies:
					if not adj.has_status("Burning") and adj.is_alive():
						_apply_status_effect(adj, "Burning", 2, 0, unit)
						break

	# Blood in the Wind: +movement when enemies are bleeding
	if _unit_has_perk(unit, "blood_in_the_wind"):
		var any_bleeding = false
		for enemy in get_team_units(1 - unit.team if "team" in unit else 1):
			if enemy.has_status("Bleeding"):
				any_bleeding = true
				break
		if any_bleeding:
			_apply_stat_modifier(unit, "movement", 1, 1)

	# Soothing Presence aura (perk-granted, not status-granted)
	# Handled via status effect system — the status applies the aura

	# --- Talisman perk turn-start effects ---
	var talisman_perks = _get_talisman_perks(unit)

	# HP regeneration: regen_minor (+2%), regen_moderate (+4%), regen_greater (+7%)
	var regen_pct = 0.0
	if "regen_greater" in talisman_perks:
		regen_pct = maxf(regen_pct, 0.07)
	if "regen_moderate" in talisman_perks:
		regen_pct = maxf(regen_pct, 0.04)
	if "regen_minor" in talisman_perks:
		regen_pct = maxf(regen_pct, 0.02)
	# If unit has two trinkets with regen, use the better one (already maxf'd)
	# but also add the lesser one at half value for stacking
	if talisman_perks.count("regen_greater") + talisman_perks.count("regen_moderate") + talisman_perks.count("regen_minor") > 1:
		var second_pct = 0.0
		for tp in talisman_perks:
			var val = 0.0
			match tp:
				"regen_greater": val = 0.07
				"regen_moderate": val = 0.04
				"regen_minor": val = 0.02
			if val > 0.0 and val < regen_pct:
				second_pct = maxf(second_pct, val * 0.5)
		regen_pct += second_pct

	if regen_pct > 0.0 and unit.current_hp < unit.max_hp:
		var heal_amount = ceili(unit.max_hp * regen_pct)
		unit.heal(heal_amount)
		unit_healed.emit(unit, heal_amount)

	# Mana regeneration: mana_trickle (+2%), mana_stream (+4%), mana_cascade (+7%)
	var mana_pct = 0.0
	if "mana_cascade" in talisman_perks:
		mana_pct = maxf(mana_pct, 0.07)
	if "mana_stream" in talisman_perks:
		mana_pct = maxf(mana_pct, 0.04)
	if "mana_trickle" in talisman_perks:
		mana_pct = maxf(mana_pct, 0.02)
	if talisman_perks.count("mana_cascade") + talisman_perks.count("mana_stream") + talisman_perks.count("mana_trickle") > 1:
		var second_pct = 0.0
		for tp in talisman_perks:
			var val = 0.0
			match tp:
				"mana_cascade": val = 0.07
				"mana_stream": val = 0.04
				"mana_trickle": val = 0.02
			if val > 0.0 and val < mana_pct:
				second_pct = maxf(second_pct, val * 0.5)
		mana_pct += second_pct

	if mana_pct > 0.0 and unit.current_mana < unit.max_mana:
		var mana_amount = ceili(unit.max_mana * mana_pct)
		unit.restore_mana(mana_amount)

# ============================================
# FORCED MOVEMENT
# ============================================

## Move a unit against its will, one tile at a time, and report what happened.
##
## Returns {moved, lost, blocked_by, immune}:
##   moved      tiles actually travelled
##   lost       tiles the push asked for and did not get
##   blocked_by the unit that stopped it, or null for a wall or the map edge
##   immune     true when the target cannot be moved at all
##
## `tiles` may be negative to pull instead of push, so one primitive serves
## both and there is no second copy of the walk to keep in step.
##
## THIS FUNCTION DECIDES NOTHING ABOUT CONSEQUENCES. It reports lost tiles and
## the caller chooses what they mean. Baking "impact damage per tile" in here
## would force every push in the game to share one rule, and a gust of wind and
## a mace blow should not have to.
func _displace_unit(unit: Node, direction: Vector2i, tiles: int,
		_source: Node = null) -> Dictionary:
	var result := {"moved": 0, "lost": 0, "blocked_by": null, "immune": false}
	if unit == null or direction == Vector2i.ZERO or tiles == 0:
		return result

	# A pull is a push the other way.
	var step_dir: Vector2i = direction
	var distance: int = tiles
	if distance < 0:
		step_dir = -direction
		distance = -distance

	# Juggernaut and friends. _check_perk_status_immunity already owns the
	# question "can this unit be moved against its will", via the Pushed status.
	if _check_perk_status_immunity(unit, "Pushed"):
		result.immune = true
		result.lost = distance
		combat_log.emit("%s cannot be moved." % unit.unit_name)
		return result

	if combat_grid == null:
		result.lost = distance
		return result

	for _i in range(distance):
		var next: Vector2i = unit.grid_position + step_dir
		if not combat_grid.is_valid_position(next) or not combat_grid.is_tile_walkable(next):
			break
		var occupant = combat_grid.get_unit_at(next)
		if occupant != null:
			result.blocked_by = occupant
			break
		var from: Vector2i = unit.grid_position
		if not combat_grid.move_unit(unit, next):
			break
		unit_moved.emit(unit, from, next)
		result.moved += 1

	result.lost = distance - result.moved
	return result


## Run an effect's `push` block against a target and report the consequence the
## effect asked for.
##
##   "push": {"tiles": 1, "blocked_damage_bonus_pct": 25}
##   "push": {"tiles": 2, "per_spellpower": 0.16, "blocked_damage": 70}
##   "push": {"tiles": 2, "variance": 1, "direction": "random", "blocked_damage": 25}
##
## That is Overwhelming Blow's description implemented literally — "pushes the
## enemy 1 tile. If they can't be pushed (wall, another unit), they take +25%
## damage instead."
##
## One parser, because this same block appears in perk combat_data, in spell
## data and in perk on_trigger payloads. Three copies of a schema is how the
## vocabulary defects this project spent a week unwinding got in.
func _apply_push(source: Node, target: Node, push_data: Dictionary) -> Dictionary:
	var spec: Dictionary = push_data.duplicate()
	if not spec.has("mode"):
		spec["mode"] = "pull" if spec.get("direction", "") == "toward" else "push"
	return reposition(target, spec, source, target.grid_position if target != null
		else Vector2i.ZERO)


## Move a unit somewhere it did not choose to go. THE one entry point.
##
## Every mode shares the same refusals — a unit immune to being moved, a missing
## grid, nowhere to land — and the same reporting, so callers never have to know
## whether they asked for a shove or a teleport. See Repositioning for the
## vocabulary and for why travelled and placed modes are different things.
##
##   "reposition": {"mode": "push", "tiles": 1, "blocked_damage": 10}
##   "reposition": {"mode": "teleport", "range": 6}
##   "reposition": {"mode": "behind"}
##
## `aim` is the tile the caster picked, and only the placed modes read it.
func reposition(unit: Node, spec: Dictionary, source: Node = null,
		aim: Vector2i = Vector2i.ZERO) -> Dictionary:
	var result := {"moved": 0, "lost": 0, "blocked_by": null, "immune": false,
		"damage_bonus_pct": 0, "blocked_damage": 0, "ok": false, "reason": ""}
	if unit == null or not is_instance_valid(unit) or not "grid_position" in unit:
		result.reason = "no unit"
		return result

	var mode: String = spec.get("mode", "push")
	if not Repositioning.is_mode(mode):
		push_warning("CombatManager.reposition: %s" % Repositioning.explain_unknown(mode))
		result.reason = "unknown mode"
		return result

	# Juggernaut and friends. One immunity question for every mode: can this
	# unit be moved against its will? Dimensional Anchor answers it for the
	# placed modes only — being nailed to the plane does not stop a shove.
	if _check_perk_status_immunity(unit, "Pushed"):
		result.immune = true
		result.reason = "cannot be moved"
		combat_log.emit("%s cannot be moved." % unit.unit_name)
		return result
	if not Repositioning.is_travelled(mode) and StatusRules.has_flag(unit, "prevents_teleportation"):
		result.immune = true
		result.reason = "anchored to this plane"
		combat_log.emit("%s is anchored and cannot be displaced." % unit.unit_name)
		return result

	if Repositioning.is_travelled(mode):
		var tiles: int = Repositioning.distance_for(spec, source)
		if mode == "pull":
			tiles = -tiles
		var direction: Vector2i = Repositioning.direction_for(spec, source, unit)
		var travelled: Dictionary = _displace_unit(unit, direction, tiles, source)
		result.merge(travelled, true)
		result.ok = travelled.get("moved", 0) > 0

		# Two ways to be paid for a blocked push, because two kinds of effect
		# want it. A perk adds a percentage to damage it was already dealing; a
		# spell that deals almost nothing on its own — Surge is 5 — pays a flat
		# amount, so the wall behind the target is the point of casting it.
		var stopped: bool = travelled.get("lost", 0) > 0
		result.damage_bonus_pct = int(spec.get("blocked_damage_bonus_pct", 0)) if stopped else 0
		result.blocked_damage = int(spec.get("blocked_damage", 0)) if stopped else 0
		return result

	# Placed: leaves one tile, arrives at another, nothing in between.
	var plan: Dictionary = Repositioning.destination(
		mode, unit, source, spec, aim, combat_grid)
	if not plan.get("ok", false):
		result.reason = plan.get("reason", "")
		return result

	var from: Vector2i = unit.grid_position
	var dest: Vector2i = plan["tile"]
	var partner: Node = plan.get("swap_with", null)

	if partner != null:
		# Both units leave at once, so neither destination is occupied when the
		# other arrives. Moving them one at a time would have the first blocked
		# by the second.
		var partner_from: Vector2i = partner.grid_position
		combat_grid.unit_positions.erase(from)
		combat_grid.unit_positions.erase(partner_from)
		unit.grid_position = dest
		partner.grid_position = from
		combat_grid.unit_positions[dest] = unit
		combat_grid.unit_positions[from] = partner
		unit_moved.emit(unit, from, dest)
		unit_moved.emit(partner, partner_from, from)
	else:
		if not combat_grid.move_unit(unit, dest):
			result.reason = "the grid refused the move"
			return result
		unit_moved.emit(unit, from, dest)

	result.ok = true
	result.moved = maxi(absi(dest.x - from.x), absi(dest.y - from.y))
	return result


# ============================================
# ZONE OF CONTROL REACTIONS
# ============================================

## Check and fire ZoC reaction attacks after a unit moves.
## mover: the unit that just moved; old_pos/new_pos: previous and current grid positions.
func _check_zoc_reactions(mover: Node, old_pos: Vector2i, new_pos: Vector2i) -> void:
	# Skirmisher (Ranged 3 + Grace 3): free disengage — immune to ZoC reactions on all moves
	var mover_char = mover.character_data if "character_data" in mover else {}
	if PerkSystem.has_perk(mover_char, "skirmisher"):
		return

	# Reaction stances first: an enemy stepping into a threatened area, or up to
	# an ally somebody is guarding — the `enemy_enters_reach` and
	# `ally_threatened` triggers of the reactor's statuses. Declared by the
	# status rather than branched on per perk — the three branches below this
	# are the older way, kept because they are passives rather than stances.
	for reactor in all_units:
		if reactor.is_dead or not "team" in reactor or reactor.team == mover.team:
			continue
		var old_dist: int = _grid_distance(reactor.grid_position, old_pos)
		var new_dist: int = _grid_distance(reactor.grid_position, new_pos)
		_fire_move_reactions(reactor, mover, old_dist, new_dist, old_pos, new_pos)

	# Scan all enemies of the mover (i.e., potential reactors on the other team)
	for reactor in all_units:
		if reactor.is_dead or reactor.team == mover.team:
			continue
		if not reactor.has_method("get_equipped_weapon"):
			continue

		var reactor_char = reactor.character_data if "character_data" in reactor else {}
		var weapon_type = reactor.get_equipped_weapon().get("type", "")
		var is_spear = weapon_type == "spear"
		var reactor_pos = reactor.grid_position
		var dist_old = _grid_distance(reactor_pos, old_pos)
		var dist_new = _grid_distance(reactor_pos, new_pos)
		var reach = 2 if is_spear else 1

		# Frost Warden: +1 reach while stationary
		if is_spear and PerkSystem.has_perk(reactor_char, "frost_warden") and not reactor.moved_this_turn:
			reach += 1

		# First to Strike (Spears 1): reaction attack when enemy enters 2-tile spear range
		if is_spear and PerkSystem.has_perk(reactor_char, "first_to_strike"):
			if dist_new <= reach and dist_old > reach:
				combat_log.emit("%s: First to Strike reaction!" % reactor.unit_name)
				attack_unit(reactor, mover, true)

		# Frost Warden: reaction Slow when enemy enters reach
		if is_spear and PerkSystem.has_perk(reactor_char, "frost_warden"):
			if dist_new <= reach and dist_old > reach:
				_apply_status_effect(mover, "Slowed", 2, 0, reactor)

		# None Shall Pass was here as an always-on passive: a free attack with
		# no turn-ending and no -2 Movement, which is not what the perk says.
		# It is a stance now — see the None_Shall_Pass status.

		# Sentinel (Swords/MA cross): reaction attack when enemy LEAVES melee range (1 tile)
		if PerkSystem.has_perk(reactor_char, "sentinel"):
			var sentinel_weapon = weapon_type in ["sword", ""] or weapon_type.is_empty()
			if sentinel_weapon and dist_old <= 1 and dist_new > 1:
				combat_log.emit("%s: Sentinel reaction!" % reactor.unit_name)
				attack_unit(reactor, mover, true)


# ============================================
# FREE ATTACK SYSTEM (cleave, relentless)
# ============================================

## Perform one free attack from attacker against target, with a recursion guard
## so free attacks can never chain into further free attacks.
func _trigger_free_attack(attacker: Node, target: Node) -> void:
	if attacker == null or attacker.is_dead or target == null or not target.is_alive():
		return
	if attacker.in_free_attack:
		return  # Prevent chaining
	attacker.in_free_attack = true
	combat_log.emit("%s makes a free attack on %s!" % [attacker.unit_name, target.unit_name])
	attack_unit(attacker, target, true)  # reaction=true: no action cost
	attacker.in_free_attack = false


## Check and trigger Cleave (Axes cross) after a kill.
## dead_pos: grid position where the killed unit was standing.
func _trigger_cleave(killer: Node, dead_pos: Vector2i) -> void:
	if killer == null or killer.is_dead or killer.in_free_attack:
		return
	var killer_char = killer.character_data if "character_data" in killer else {}
	if not PerkSystem.has_perk(killer_char, "cleave"):
		return
	# Must be wielding an axe
	if not killer.has_method("get_equipped_weapon"):
		return
	if killer.get_equipped_weapon().get("type", "") != "axe":
		return
	# Find the nearest enemy adjacent to the dead unit's tile
	var nearest: Node = null
	var best_dist = 9999
	for u in all_units:
		if u.is_dead or u.team == killer.team:
			continue
		var d = _grid_distance(dead_pos, u.grid_position)
		if d <= 1 and d < best_dist:
			best_dist = d
			nearest = u
	_trigger_free_attack(killer, nearest)


## Return all live units whose summoner_id matches caster.get_instance_id()
func _get_owned_summons(caster: Node) -> Array:
	var caster_id = caster.get_instance_id()
	var result: Array = []
	for u in all_units:
		if not u.is_dead and "summoner_id" in u and u.summoner_id == caster_id:
			result.append(u)
	return result


# ============================================
# MANTRA SYSTEM
# ============================================

## Interrupt all active mantras on a unit (heavy hit, hard CC, or spell cast).
## Returns immediately if there are no active mantras (cheap guard).
func _interrupt_mantras(unit: Node, reason: String) -> void:
	if not ("active_mantras" in unit) or unit.active_mantras.is_empty():
		return
	unit.active_mantras = {}
	unit.mantra_stat_bonuses = {}
	_lord_of_death_casters.erase(unit)
	combat_log.emit(reason)


## Process all active mantras for a unit at the start of their turn.
## Rebuilds mantra_stat_bonuses and applies per-turn aura/damage/heal effects.
## Triggers Deity Yoga automatically when the mantra reaches 5 stacks.
func _process_mantra_effects_and_auras(unit: Node) -> void:
	# Lord of Death cleanup: if DY was triggered but mantra is no longer active, remove from list
	if not "mantra_of_the_lord_of_death" in unit.active_mantras:
		_lord_of_death_casters.erase(unit)

	var char_data = unit.character_data if "character_data" in unit else {}
	var spellpower = unit.get_spellpower()

	# Rebuild stat bonuses from scratch (so they don't accumulate unboundedly)
	unit.mantra_stat_bonuses = {}

	# Walking Meditation (cross-skill perk): +2 Move while any mantra is active
	if PerkSystem.has_perk(char_data, "walking_meditation"):
		unit.mantra_stat_bonuses["movement"] = unit.mantra_stat_bonuses.get("movement", 0) + 2

	for perk_id in unit.active_mantras:
		var stacks = mini(unit.active_mantras[perk_id], 5)
		if stacks == 0:
			continue  # Just started chanting this turn — no effect yet

		_apply_mantra_tick(unit, perk_id, stacks, spellpower, char_data)

		# Trigger Deity Yoga once when stacks reach 5
		if unit.active_mantras[perk_id] >= 5 and not unit.deity_yoga_triggered.get(perk_id, false):
			unit.deity_yoga_triggered[perk_id] = true
			_trigger_deity_yoga(unit, perk_id, spellpower)

## Apply the per-turn aura effect for a specific mantra at the given stack level.
## stacks: 1-5; spellpower: caster's current spellpower.
func _apply_mantra_tick(unit: Node, perk_id: String, stacks: int, spellpower: int, char_data: Dictionary) -> void:
	var allies = _get_allies_in_range(unit, 3)  # Most mantras have 3-tile radius
	var allies_with_self: Array = [unit] + allies
	var enemies_3 = _get_enemies_in_range(unit, 3)
	var enemies_4 = _get_enemies_in_range(unit, 4)
	var all_enemies = _get_enemies_in_range(unit, 99)  # line-of-sight mantras use all visible enemies

	match perk_id:

		# ---- SPACE MAGIC ----
		"lady_of_the_turquoise_mirror_mantra":
			# Caster gains stacking +5% Dodge and +5% magic resist per stack
			unit.mantra_stat_bonuses["dodge"] = unit.mantra_stat_bonuses.get("dodge", 0) + stacks * 5

		"diamond_nail_mantra":
			# Enemies in 3 tiles suffer -1 Move per stack (up to -5)
			for e in enemies_3:
				_apply_status_effect(e, "Slowed", 2, 0, unit)  # 1 Slowed per turn; stacks via the status system

		# ---- WHITE MAGIC ----
		"lotus_refuge_mantra":
			# Allies in 3 tiles regen 3% max HP × stacks each turn
			var heal_pct = stacks * 3
			for a in allies_with_self:
				var heal_amt = ceili(a.max_hp * heal_pct / 100.0)
				a.heal(heal_amt)
				unit_healed.emit(a, heal_amt)

		"golden_wheel_mantra":
			# Enemies in LOS suffer -5% Accuracy per stack (applied as Weakened each turn)
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					_apply_status_effect(e, "Weakened", 2, 0, unit)

		"immovable_light_mantra":
			# Caster gains +5% Armor and immunity to forced movement per stack
			unit.mantra_stat_bonuses["armor"] = unit.mantra_stat_bonuses.get("armor", 0) + stacks * 5

		# ---- BLACK MAGIC ----
		"mantra_of_the_great_black_one":
			# Enemies in 3 tiles: -5% Armor per stack + drain 3% Stamina/Mana per stack
			for e in enemies_3:
				_apply_status_effect(e, "Weakened", 2, 0, unit)  # simulates armor/resist reduction
				var drain = ceili(e.max_stamina * 0.03 * stacks)
				e.current_stamina = maxi(0, e.current_stamina - drain)
				var mana_drain = ceili(e.max_mana * 0.03 * stacks)
				e.current_mana = maxi(0, e.current_mana - mana_drain)

		"mantra_of_the_blood_drinkers":
			# Enemies in LOS take Black damage 5% Spellpower × stacks; heal caster + nearby allies
			var dmg_per_enemy = ceili(spellpower * 0.05 * stacks)
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					apply_damage(e, dmg_per_enemy, "black")
					# Lifesteal: heal caster and allies within 2 tiles
					var healers = [unit] + _get_allies_in_range(unit, 2)
					for h in healers:
						var h_amt = ceili(dmg_per_enemy * 0.5)
						h.heal(h_amt)
						unit_healed.emit(h, h_amt)

		"mantra_of_the_lord_of_death":
			# 1. Heal black-tagged owned summons within 4 tiles (10% of their max HP)
			for s in _get_owned_summons(unit):
				if "character_data" in s and "tags" in s.character_data and "black" in s.character_data["tags"]:
					if _grid_distance(unit.grid_position, s.grid_position) <= 4:
						var heal_amt = ceili(s.max_hp * 0.10)
						s.heal(heal_amt)
						unit_healed.emit(s, heal_amt)
			# 2. Stacking black damage to enemies in 4 tiles (3% spellpower × stacks)
			var lod_dmg = ceili(spellpower * 0.03 * stacks)
			for e in enemies_4:
				apply_damage(e, lod_dmg, "black")

		# ---- YOGA ----
		"mantra_of_the_white_saviouress":
			# Caster + allies in 3 tiles regain 2%+stacks% max HP, Mana, Stamina
			var pct = (1 + stacks) / 100.0
			for a in allies_with_self:
				var hp_amt = ceili(a.max_hp * pct)
				a.heal(hp_amt)
				unit_healed.emit(a, hp_amt)
				a.current_mana = mini(a.max_mana, a.current_mana + ceili(a.max_mana * pct))
				a.current_stamina = mini(a.max_stamina, a.current_stamina + ceili(a.max_stamina * pct))

		"mantra_of_the_lotus_pinnacle":
			# Allies in 3 tiles gain +3% all resist per stack (applied as armor bonus proxy)
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 3

		# ---- AIR MAGIC ----
		"mantra_of_the_green_saviouress":
			# Allies in 3 tiles gain +1 to all d20 rolls per stack → +5% accuracy per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + stacks * 5

		"mantra_of_the_roaring_one":
			# Allies in 3 tiles gain +1 Move, +3% crit per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + stacks
				a.mantra_stat_bonuses["crit_chance"] = a.mantra_stat_bonuses.get("crit_chance", 0.0) + stacks * 3.0

		# ---- RITUAL ----
		"mantra_of_interdependent_arising":
			# Caster + allies in 3 tiles regain 2% Mana per stack
			var mana_pct = stacks * 2 / 100.0
			for a in allies_with_self:
				var mana_amt = ceili(a.max_mana * mana_pct)
				a.current_mana = mini(a.max_mana, a.current_mana + mana_amt)

		"mantra_of_multiplying":
			# Caster gains +5% Spellpower per stack (up to +25%)
			unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + stacks * (spellpower / 20)

		# ---- FIRE MAGIC ----
		"mantra_of_the_lotus_blaze":
			# Enemies in LOS: CON save (DC 10 + 2×stacks) or gain Burning
			var dc = 10 + stacks * 2
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					var con: int = unit_attribute(e, "constitution")
					var roll = randi() % 20 + 1 + con - 10
					if roll < dc:
						_apply_status_effect(e, "Burning", 2, 0, unit)

		"mantra_of_the_red_lotus_lady":
			# Enemies in 3 tiles: Focus save (DC 10 + 2×stacks) or get Charmed 2t
			var dc_r = 10 + stacks * 2
			for e in enemies_3:
				var foc: int = unit_attribute(e, "focus")
				var roll = randi() % 20 + 1 + foc - 10
				if roll < dc_r:
					_apply_status_effect(e, "Charmed", 2, 0, unit)

		"mantra_of_the_horse_lord":
			# Allies in 3 tiles gain +2 Initiative, +1 Move per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["initiative"] = a.mantra_stat_bonuses.get("initiative", 0) + stacks * 2
				a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + stacks

		# ---- SORCERY ----
		"mantra_of_the_lionheaded_curse_devourer":
			# Allies in 3 tiles gain +5% magic resist per stack → armor proxy
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 5

		# ---- WATER MAGIC ----
		"mantra_of_the_medicine_buddha":
			# Ally with lowest HP% in 3 tiles heals 5% Spellpower per stack
			var heal_amt = ceili(spellpower * 0.05 * stacks)
			var lowest: Node = null
			var lowest_pct = 1.0
			for a in allies_with_self:
				var pct_hp = float(a.current_hp) / float(a.max_hp)
				if pct_hp < lowest_pct:
					lowest_pct = pct_hp
					lowest = a
			if lowest != null:
				lowest.heal(heal_amt)
				unit_healed.emit(lowest, heal_amt)

		"mantra_of_the_unshakeable_one":
			# Enemies in 3 tiles take Cold damage 3% Spellpower × stacks; allies +3% resist per stack
			var cold_dmg = ceili(spellpower * 0.03 * stacks)
			for e in enemies_3:
				apply_damage(e, cold_dmg, "ice")
				_apply_status_effect(e, "Slowed", 2, 0, unit)
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 3

		# ---- ENCHANTMENT ----
		"mantra_of_the_wishfulfilling_jewel":
			# Allies in 3 tiles get a random +5% buff to one stat each turn
			var buff_options = ["dodge", "armor", "initiative", "crit_chance", "spellpower"]
			for a in allies_with_self:
				var chosen = buff_options[randi() % buff_options.size()]
				a.mantra_stat_bonuses[chosen] = a.mantra_stat_bonuses.get(chosen, 0) + 5

		"mantra_of_the_binding_word":
			# Enemies in LOS get a random -5% debuff each turn
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					_apply_status_effect(e, "Weakened", 2, 0, unit)

		# ---- EARTH MAGIC ----
		"mantra_of_the_earth_store_bodhisattva":
			# Allies in 3 tiles +5% Armor per stack; enemies in 3 tiles -5% Attack per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 5
			for e in enemies_3:
				_apply_status_effect(e, "Weakened", 2, 0, unit)

		"mantra_of_the_jeweled_mountain":
			# Enemies -5% Attack per stack; allies +5% Armor per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 5
			for e in enemies_3:
				_apply_status_effect(e, "Weakened", 2, 0, unit)

		# ---- SUMMONING ----
		"mantra_of_the_four_guardian_kings":
			# 1. Maintain up to 4 spirit guardians around the caster
			var owned = _get_owned_summons(unit)
			var guardian_count = 0
			for s in owned:
				if "character_data" in s and "tags" in s.character_data and "guardian_spirit" in s.character_data["tags"]:
					guardian_count += 1
			if guardian_count < 4:
				# Find first free tile within 2 of caster
				var found_tile = Vector2i(-1, -1)
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						if found_tile != Vector2i(-1, -1):
							break
						var candidate = unit.grid_position + Vector2i(dx, dy)
						if candidate == unit.grid_position:
							continue
						if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
							found_tile = candidate
					if found_tile != Vector2i(-1, -1):
						break
				if found_tile != Vector2i(-1, -1):
					_spawn_summoned_unit(unit, "spirit_guardian", found_tile, 0)
					# Refresh owned list after spawn
					owned = _get_owned_summons(unit)

			# 2. Each spirit guardian gives +3 armor to the nearest ally within 3 tiles
			for s in owned:
				if not ("character_data" in s and "tags" in s.character_data and "guardian_spirit" in s.character_data["tags"]):
					continue
				var nearest_ally: Node = null
				var nearest_ally_dist = 999
				for a in allies_with_self:
					var d = _grid_distance(s.grid_position, a.grid_position)
					if d <= 3 and d < nearest_ally_dist:
						nearest_ally_dist = d
						nearest_ally = a
				if nearest_ally != null:
					nearest_ally.mantra_stat_bonuses["armor"] = nearest_ally.mantra_stat_bonuses.get("armor", 0) + 3

		"mantra_of_the_jeweled_pagoda":
			# 1. Caster gains +5 * stacks flat spellpower bonus
			unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + stacks * 5
			# 2. Each owned summon gains stacks*3 to damage, armor, dodge
			for s in _get_owned_summons(unit):
				s.mantra_stat_bonuses["damage"] = s.mantra_stat_bonuses.get("damage", 0) + stacks * 3
				s.mantra_stat_bonuses["armor"] = s.mantra_stat_bonuses.get("armor", 0) + stacks * 3
				s.mantra_stat_bonuses["dodge"] = s.mantra_stat_bonuses.get("dodge", 0) + stacks * 3


## Trigger the Deity Yoga burst for a mantra at stack 5.
## Called once per mantra activation when active_mantras[perk_id] first reaches 5.
func _trigger_deity_yoga(unit: Node, perk_id: String, spellpower: int) -> void:
	var allies = _get_allies_in_range(unit, 3)
	var allies_with_self: Array = [unit] + allies
	var enemies_3 = _get_enemies_in_range(unit, 3)
	var enemies_4 = _get_enemies_in_range(unit, 4)
	var all_enemies = _get_enemies_in_range(unit, 99)
	var mantra_name = perk_id.replace("_", " ").capitalize()
	combat_log.emit("DEITY YOGA — %s!" % mantra_name)

	match perk_id:

		# SPACE
		"lady_of_the_turquoise_mirror_mantra":
			# All attacks targeting caster have 60% reflect chance for 3 turns
			_apply_status_effect(unit, "Reflect", 3, 0, unit)
			# Share dodge bonus with allies in 3 tiles
			for a in allies:
				a.mantra_stat_bonuses["dodge"] = a.mantra_stat_bonuses.get("dodge", 0) + 25

		"diamond_nail_mantra":
			# Enemies in 4 tiles take Space damage 50% Spellpower/turn — apply big Slow + damage burst
			var dmg = ceili(spellpower * 0.50)
			for e in enemies_4:
				apply_damage(e, dmg, "space")
				_apply_status_effect(e, "Rooted", 2, 0, unit)

		# WHITE
		"lotus_refuge_mantra":
			# All allies heal 20% max HP; all healing maximized for 2 turns
			for a in allies_with_self:
				var heal = ceili(a.max_hp * 0.20)
				a.heal(heal)
				unit_healed.emit(a, heal)
				_apply_status_effect(a, "Fortified", 2, 0, unit)

		"golden_wheel_mantra":
			# Enemies who attack take 30% of dealt damage as White; allies +20% attack for 3 turns
			for a in allies_with_self:
				_apply_status_effect(a, "Inspired", 3, 0, unit)
			for e in all_enemies:
				_apply_status_effect(e, "Weakened", 3, 0, unit)

		"immovable_light_mantra":
			# Caster cannot drop below 1 HP; allies within 3 tiles +30% all resist for 3 turns
			_apply_status_effect(unit, "Invincible", 3, 0, unit)
			for a in allies:
				_apply_status_effect(a, "Fortified", 3, 0, unit)

		# BLACK
		"mantra_of_the_great_black_one":
			# All enemies in LOS: -20% Attack, -20% Armor, -5 Init, drain 8% Stamina/Mana
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					_apply_status_effect(e, "Weakened", 3, 0, unit)
					_apply_status_effect(e, "Slowed", 3, 0, unit)
					e.current_stamina = maxi(0, e.current_stamina - ceili(e.max_stamina * 0.08))
					e.current_mana = maxi(0, e.current_mana - ceili(e.max_mana * 0.08))

		"mantra_of_the_blood_drinkers":
			# Massive drain: 25% Spellpower Black to all LOS enemies; heal allies 50% dealt
			var dmg = ceili(spellpower * 0.25)
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					apply_damage(e, dmg, "black")
					for a in allies_with_self:
						var h = ceili(dmg * 0.5)
						a.heal(h)
						unit_healed.emit(a, h)

		"mantra_of_the_lord_of_death":
			# Existing burst: black damage + Fear to all enemies in 4 tiles
			var lod_dy_dmg = ceili(spellpower * 0.20)
			for e in enemies_4:
				apply_damage(e, lod_dy_dmg, "black")
				_apply_status_effect(e, "Feared", 3, 0, unit)
			# 1. Bonus turns for all owned summons + empower them
			var owned_summons = _get_owned_summons(unit)
			for s in owned_summons:
				s.lord_of_death_empowered = true
				combat_log.emit("%s acts under the Lord of Death's command!" % s.unit_name)
				if get_tree() != null:
					var arena = get_tree().get_first_node_in_group("combat_arena")
					if arena != null and arena.has_method("_run_bonus_turn"):
						arena._run_bonus_turn(s)
			# 2. Register this caster for resurrection-on-kill tracking
			if not unit in _lord_of_death_casters:
				_lord_of_death_casters.append(unit)

		# YOGA
		"mantra_of_the_white_saviouress":
			# All allies: immunity to mental effects + 50% debuff resist for 3 turns
			for a in allies_with_self:
				_apply_status_effect(a, "Resolute", 3, 0, unit)

		"mantra_of_the_lotus_pinnacle":
			# All enemies in LOS: Focus save vs Pacified; else -50% Attack/Damage
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					var foc: int = unit_attribute(e, "focus")
					var roll = randi() % 20 + 1 + foc - 10
					if roll < 15:
						_apply_status_effect(e, "Pacified", 2, 0, unit)
					else:
						_apply_status_effect(e, "Weakened", 2, 0, unit)

		# AIR
		"mantra_of_the_green_saviouress":
			# Caster's rolls gain +10 and can't critically fail; allies +5 accuracy for 3 turns
			unit.mantra_stat_bonuses["accuracy"] = unit.mantra_stat_bonuses.get("accuracy", 0) + 20
			for a in allies:
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 10

		"mantra_of_the_roaring_one":
			# Stat burst for all allies (+5 movement, +15% crit)
			for a in allies_with_self:
				a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + 5
				a.mantra_stat_bonuses["crit_chance"] = a.mantra_stat_bonuses.get("crit_chance", 0.0) + 15.0
			# Spawn 1–3 Rudras near the caster (try adjacent tiles in order)
			var rudra_count = 1 + randi() % 3
			var spawned = 0
			var offsets = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0),
						   Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]
			for offset in offsets:
				if spawned >= rudra_count:
					break
				var candidate = unit.grid_position + offset
				if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
					_spawn_summoned_unit(unit, "rudra", candidate, spellpower)
					spawned += 1

		# RITUAL
		"mantra_of_interdependent_arising":
			# All allies: 50% mana refund on next spell + +50% Spellpower for 3 turns
			for a in allies_with_self:
				a.mantra_stat_bonuses["spellpower"] = a.mantra_stat_bonuses.get("spellpower", 0) + spellpower / 2

		"mantra_of_multiplying":
			# +50% Spellpower burst for caster
			unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + spellpower / 2

		# FIRE
		"mantra_of_the_lotus_blaze":
			# All burning enemies explode: 10% max HP × Burning stacks AoE fire damage
			for e in all_enemies:
				if e.has_status("Burning"):
					var burst_stacks = 0
					for se in e.status_effects:
						if se.get("status", "") == "Burning":
							burst_stacks += 1
					var burst_dmg = ceili(e.max_hp * 0.10 * burst_stacks)
					apply_damage(e, burst_dmg, "fire")
					# AoE splash to adjacent enemies
					for nearby in _get_enemies_in_range(e, 1):
						apply_damage(nearby, ceili(burst_dmg * 0.5), "fire")

		"mantra_of_the_red_lotus_lady":
			# All enemies must Focus save vs Charmed; crit fails → Dominated (here: Confused)
			for e in all_enemies:
				var foc_r: int = unit_attribute(e, "focus")
				var roll_r = randi() % 20 + 1 + foc_r - 10
				if roll_r < 8:
					_apply_status_effect(e, "Confused", 3, 0, unit)  # Dominated approximation
				elif roll_r < 15:
					_apply_status_effect(e, "Charmed", 3, 0, unit)

		"mantra_of_the_horse_lord":
			# All allies: full Move/Init burst + +20% Atk/Dmg + Burning on melee for 3 turns
			for a in allies_with_self:
				a.mantra_stat_bonuses["initiative"] = a.mantra_stat_bonuses.get("initiative", 0) + 10
				a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + 5
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 20
			for e in all_enemies:
				_apply_status_effect(e, "Weakened", 3, 0, unit)

		# SORCERY
		"mantra_of_the_lionheaded_curse_devourer":
			# Transfer all debuffs from allies to enemies; big Spellpower/resist burst
			for a in allies_with_self:
				# Cleanse one debuff per ally
				for i in range(a.status_effects.size() - 1, -1, -1):
					var sname = a.status_effects[i].get("status", "")
					var sdef = get_status_definition(sname)
					if sdef.get("polarity", "") == "negative":
						_end_status(a, a.status_effects[i], "cleansed")
						status_effect_expired.emit(a, sname)
						break
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 20
			for e in all_enemies:
				_apply_status_effect(e, "Weakened", 3, 0, unit)

		# WATER
		"mantra_of_the_medicine_buddha":
			# All allies heal 50% max HP and are cleansed of all debuffs
			for a in allies_with_self:
				var heal = ceili(a.max_hp * 0.50)
				a.heal(heal)
				unit_healed.emit(a, heal)
				# Cleanse all debuffs
				for i in range(a.status_effects.size() - 1, -1, -1):
					var sname = a.status_effects[i].get("status", "")
					var sdef = get_status_definition(sname)
					if sdef.get("polarity", "") == "negative":
						_end_status(a, a.status_effects[i], "cleansed")
						status_effect_expired.emit(a, sname)

		"mantra_of_the_unshakeable_one":
			# All enemies in LOS: Frozen; big cold damage burst; allies +30% resist
			var cold_burst = ceili(spellpower * 0.30)
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					apply_damage(e, cold_burst, "ice")
					_apply_status_effect(e, "Frozen", 2, 0, unit)
			for a in allies_with_self:
				_apply_status_effect(a, "Fortified", 3, 0, unit)

		# ENCHANTMENT
		"mantra_of_the_wishfulfilling_jewel":
			# All allies +25% to all stats for 3 turns
			for a in allies_with_self:
				a.mantra_stat_bonuses["dodge"] = a.mantra_stat_bonuses.get("dodge", 0) + 25
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 25
				a.mantra_stat_bonuses["initiative"] = a.mantra_stat_bonuses.get("initiative", 0) + 10
				a.mantra_stat_bonuses["crit_chance"] = a.mantra_stat_bonuses.get("crit_chance", 0.0) + 10.0
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 25

		"mantra_of_the_binding_word":
			# All enemies in LOS: heavy multi-debuff
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					_apply_status_effect(e, "Weakened", 3, 0, unit)
					_apply_status_effect(e, "Slowed", 3, 0, unit)
					_apply_status_effect(e, "Dazed", 3, 0, unit)

		# EARTH
		"mantra_of_the_earth_store_bodhisattva":
			# Heal all allies 20% HP; big armor burst
			for a in allies_with_self:
				var heal = ceili(a.max_hp * 0.20)
				a.heal(heal)
				unit_healed.emit(a, heal)
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 25

		"mantra_of_the_jeweled_mountain":
			# Crushing burst (25% Spellpower) to all enemies in 4 tiles; allies
			# +30% armor. `earth` was a damage type once; a mountain arriving
			# is impact, and the Earth SCHOOL is a different question.
			var dmg = ceili(spellpower * 0.25)
			for e in enemies_4:
				apply_damage(e, dmg, "crushing")
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 30

		# SUMMONING
		"mantra_of_the_four_guardian_kings":
			# Stat burst for all allies (+25 armor, +25 accuracy)
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 25
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 25
			# Spawn a Guardian King in each of 4 cardinal directions (search outward up to radius 3)
			var cardinal_offsets = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]
			for base_offset in cardinal_offsets:
				var spawn_tile = Vector2i(-1, -1)
				# Try exact cardinal tile, then 1 further, then 2 further (along the same axis)
				for r in range(0, 3):
					if spawn_tile != Vector2i(-1, -1):
						break
					var candidate = unit.grid_position + base_offset * (1 + r)
					if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
						spawn_tile = candidate
				if spawn_tile != Vector2i(-1, -1):
					_spawn_summoned_unit(unit, "stone_guardian", spawn_tile, 0)

		"mantra_of_the_jeweled_pagoda":
			# Set the empowered flag — consumed by _spawn_summoned_unit() on next summon cast
			unit.next_summon_empowered = true
			combat_log.emit("%s's next summon will be empowered!" % unit.unit_name)
