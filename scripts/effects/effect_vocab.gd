class_name EffectVocab
extends RefCounted
## The approved vocabulary of the shared effect language, and the validator
## that checks authored effects against it.
##
## An "effect" is one JSON object: {"op": "damage", "amount": 20, "type": "fire"}.
## Spells, statuses, items and perks will all write effects in this one shape
## (see docs/superpowers/specs/2026-11-25-effect-normalization-design.md).
##
## RULES FOR THIS FILE
##   * A list contains ONLY what is built. A name is added in the same change
##     that makes the game read it. Listing something unbuilt would let data
##     validate and then silently do nothing, which is the bug this whole
##     refactor exists to end.
##   * Unknown names are errors, never silently defaulted. validate() returns
##     human-readable strings; an empty array means the effect is valid.
##   * tools/effect_check.py (the Python mirror, imported by
##     tools/validate_data.py and tested by tools/test_effect_vocab.py) reads
##     the literal `const NAME: Array[String] = [...]` lists and the two
##     Dictionary consts below with a regex, so every list it needs stays a
##     plain literal of quoted strings. Change a rule here, change it there.

# ── The approved lists ───────────────────────────────────────────────────────

## What an effect can do. aura, cast, grant and the map ops arrive with the
## stages that build them. `attack` (a free weapon attack), `negate` and
## `reflect` came with stage 2b Task 6, for statuses that answer what is done
## to their carrier.
const OPS: Array[String] = [
	"damage", "heal", "modify", "status", "move", "kill", "summon", "zone", "resurrect",
	"attack", "negate", "reflect",
]

## Ops that only make sense BEFORE an attack or spell lands, because they
## change what it does: `negate` (it misses outright) and `reflect` (it turns
## back on whoever sent it). They are refused anywhere except in a status
## trigger whose `on` is one of INTERCEPT_TRIGGERS, where the hook that fired
## the trigger reads them and acts on the attack itself.
const INTERCEPT_OPS: Array[String] = ["negate", "reflect"]

## Whom an `attack` op swings at. `source` is whoever set the trigger off.
const ATTACK_TARGETS: Array[String] = ["source"]

## Whose side a `summon` fights on: the caster's (default) or the target's.
## `target` is for a status whose expiry hatches something out of its carrier
## (Infected), which has always joined the carrier's side.
const SUMMON_OWNERS: Array[String] = ["caster", "target"]

## How a `modify` changes a value.
const MODES: Array[String] = [
	"fortify", "drain", "damage", "restore", "absorb", "set", "multiply",
]

## Which modes each namespace accepts. `resource` modes are all instant
## (restore / drain / absorb act once); the others last while their status does.
const MODES_BY_NAMESPACE: Dictionary = {
	"resource": ["restore", "drain", "absorb"],
	"attribute": ["fortify", "drain", "damage", "restore"],
	"skill": ["fortify", "drain", "damage", "restore"],
	"stat": ["fortify", "drain", "set", "multiply"],
	"resist": ["fortify", "drain", "set"],
}

## The first word of a value path ("attribute.strength"). `propagation`,
## `spell`, `party` and `world` are added in later stages.
const NAMESPACES: Array[String] = ["attribute", "skill", "resource", "stat", "resist"]

const ATTRIBUTES: Array[String] = [
	"strength", "constitution", "finesse", "focus", "awareness", "charm", "luck",
]

const RESOURCES: Array[String] = ["hp", "mana", "stamina", "temp_hp"]

## The stats a `stat.` path may name in stage 1: exactly the ones whose
## CombatUnit getter reads timed modifiers back (CombatStats.MODIFIABLE minus
## save_bonus, which SaveSystem reads instead). Keys from CombatStats.DERIVED
## join this list when a later stage reads them through ValuePaths. A literal
## on purpose, so the Python mirror can read it.
const STATS: Array[String] = [
	"initiative", "movement", "accuracy", "dodge",
	"damage", "armor", "crit_chance", "spellpower",
]

## Extra resist names beyond the damage types in damage_types.json. Each names
## a group of types, and Resistance decides which hits it reaches:
##   all_elemental  the types of category `element` (fire, lightning, space, ice)
##   all            every damage type (Invulnerable)
##   magic          every type marked `magic` (the elements, white, black)
## `resist.physical` also reaches the three physical subtypes; that is
## DamageType.scope_covers(), not a group here.
const RESIST_GROUPS: Array[String] = ["all_elemental", "all", "magic"]

## The `to` field: who an effect hits, relative to its container.
## `source` is whoever set a status trigger off (the attacker, the mover).
const SELECTORS: Array[String] = [
	"target", "caster", "allies_in_area", "enemies_in_area", "all_in_area", "party", "source",
]

## Fields any effect may carry, whatever its op.
const SHARED_FIELDS: Array[String] = [
	"op", "to", "chance", "save", "on_save", "if", "scale", "bonus_vs", "cleared_by",
]

## What a `scale` may grow with. `status_stack:<name>` is accepted by prefix.
## `turn_active` is the number of turns the status running the effect has been
## on (read from its entry, so it only means something inside a status).
const SCALE_PER: Array[String] = [
	"spellpower", "debuff_on_target", "buff_on_target", "ally_in_area", "turn_active",
]
const SCALE_STATUS_STACK_PREFIX: String = "status_stack:"

## Plain-string conditions: whatever CombatUnit._perk_condition_met answers.
## The structured forms {"target_has": ...} and {"target_is": ...} are checked
## in _condition_error(). See CONDITION_KEYS.
const CONDITIONS: Array[String] = CombatStats.PERK_CONDITIONS
## `target_lacks` is the opposite of `target_has`: a retaliation that only
## stuns someone not already stunned.
const CONDITION_KEYS: Array[String] = ["target_has", "target_is", "target_lacks"]

## Borrowed values (spec §10.3 extension 3): a magnitude may be read from
## somewhere else instead of written as a number,
##   {"from": "caster.skill.leadership", "pct": 50}
## "half the caster's Leadership". `from` is one of BORROW_SOURCES, or one of
## BORROW_UNIT_PREFIXES followed by a value path ("target.attribute.focus"):
##   status.value    the status entry's `value` (what the spell that applied
##                   it put there, e.g. a Burning that ticks 9)
##   status.stacks   the entry's stack count
##   event.damage    the damage of the event that fired the trigger (the blow
##                   that struck, the hit that landed)
##   caster.<path>   the unit the effects belong to (who applied a status, or
##                   the carrier, in a trigger that answers something)
##   target.<path>   the recipient
##   source.<path>   whoever set the trigger off
## The other keys are optional, applied in this order:
##   pct      percent of the borrowed value (default 100)
##   default  used instead when the borrowed value is missing or not above 0
##   add      a flat number added after that
##   round    "down" or "up" to a whole number
##   min      the smallest the result may be
const BORROW_SOURCES: Array[String] = ["status.value", "status.stacks", "event.damage"]
const BORROW_UNIT_PREFIXES: Array[String] = ["caster", "target", "source"]
const BORROW_FIELDS: Array[String] = ["from", "pct", "default", "add", "round", "min"]
const ROUNDINGS: Array[String] = ["down", "up"]

## What may clear a `damage`-mode modify. `cleanse` clears when a status of the
## named category is removed ({"cleanse": {"category": "curse"}}); `service`
## and `time` come in stage 5.
const CLEARED_BY: Array[String] = ["rest", "heal", "restore", "cleanse"]

# ── The status shape (stage 2b) ──────────────────────────────────────────────
# A status is a container of effects, like a spell. validate_status() checks
# one definition against these lists. They are literals so the Python mirror
# (tools/effect_check.py) can read them.

## Is the status good or bad for whoever carries it.
const POLARITIES: Array[String] = ["positive", "negative", "neutral"]

## What a status IS, for cleansing and immunity. `elemental.<element>` is also
## accepted, by prefix, for each of ELEMENTS.
const STATUS_CATEGORIES: Array[String] = [
	"magical", "physical", "mental", "disease", "poison", "curse", "blessing",
	"control", "stance", "transformation", "stealth", "shield", "aura", "wound", "quest",
]
const ELEMENTAL_CATEGORY_PREFIX: String = "elemental."
const ELEMENTS: Array[String] = ["space", "air", "fire", "water", "earth"]

## Where a status lives: one fight, the overworld clock, or until removed.
const SCOPES: Array[String] = ["combat", "world", "persistent"]

## What `duration.kind` may be.
const DURATION_KINDS: Array[String] = [
	"turns", "spellpower", "until_save", "until_destroyed", "permanent", "instant",
]

## What `stacking.mode` may be.
##   refresh      one entry; a second application keeps the longer duration
##   stack        one entry with a `stacks` count; its holds scale with it
##   independent  every application is its own entry with its own duration
##                (Burning: two fires burn twice)
const STACKING_MODES: Array[String] = ["refresh", "stack", "independent"]

## The `modify` modes that LAST (and so may sit in a status's `while_active`).
## restore and absorb are instant, so they belong in `periodic` or a trigger.
const LASTING_MODES: Array[String] = ["fortify", "drain", "set", "multiply", "damage"]

## Rule flags a status may carry: the yes/no rules statuses.json used to say
## as words in `effects` (and the status-name lists CombatManager kept in code).
## Each is enforced where the code asks StatusRules.has_flag(unit, "<flag>");
## validate_data.py fails on a flag nothing asks for. The form
## `immune:<status name | category | polarity>` is always accepted as well.
## Alphabetical. The word-by-word record is docs/plans/STATUS_MIGRATION_2026-11.md.
const FLAGS: Array[String] = [
	"attack_breaks_invisibility", "attack_damage_buff_when_ally_dies",
	"attacks_closest_creature", "attacks_have_miss_chance",
	"breaks_concentration", "breaks_on_damage_from_source", "breaks_on_offensive_action",
	"can_move_through_enemies", "cannot_act", "cannot_attack", "cannot_be_targeted",
	"cannot_cast", "cannot_deal_physical", "cannot_die", "cannot_make_weapon_attacks",
	"cannot_move", "cannot_target_enemies", "cannot_use_ranged",
	"charm_chance_on_enemy_melee_approach", "controlled_by_caster",
	"copies_absorb_attacks", "counts_as_demoralized", "crit_vulnerability",
	"damage_on_move_attempt", "damage_taken_increase", "death_resistance",
	"disengaged_from_combat", "flee_from_source", "focus_save_on_damage",
	"forced_movement_toward_target", "grants_extra_action", "grants_flight",
	"grants_stealth", "hp_cannot_drop_below_1", "hp_shield", "ignores_allegiance",
	"immune_to_ground_effects", "immune_to_melee_unless_flyer", "immune_to_ranged",
	"immune_to_terrain_hazards", "immune_to_water_terrain",
	"increase_burning_damage_dealt", "lifesteals_on_hit", "loses_flight",
	"must_attack_taunter", "next_attack_misses", "next_ranged_guaranteed_hit",
	"prevents_teleportation", "prone_chance_on_movement", "random_movement",
	"random_target", "ranged_damage_reduction", "remove_all_debuffs",
	"return_on_death_next_turn", "riposte_next_sword_attack", "rooted",
	"share_healing_75_percent", "skip_next_action", "skip_turn", "spell_damage_reduction",
	"stealth_bonus", "stun_chance_on_hit",
	"treats_caster_as_ally", "will_not_attack", "will_not_attack_caster",
]
const IMMUNE_FLAG_PREFIX: String = "immune:"

## When a status's `triggers` may fire.
##   expire              the status ran out (its duration, or its upkeep), not
##                       when it was cleansed, dispelled or removed
##   turn_start/turn_end the carrier's own turn
##   struck              a weapon attack hit the carrier (after it landed)
##   hit                 the carrier's weapon attack hit someone (after)
##   attacked_in_melee   a melee blow is about to land on the carrier
##   incoming_attack     any weapon attack is about to land on the carrier
##   incoming_spell      an offensive spell is about to land on the carrier
##   enemy_enters_reach  an enemy moved into the carrier's reach
##   ally_threatened     an enemy moved next to an ally within the carrier's reach
## In a trigger that answers something another unit did (all but expire,
## turn_start and turn_end) the carrier acts: it is the effects' caster, and
## `to: "source"` names the other unit (the attacker, the mover, or for `hit`
## the unit that was hit).
const STATUS_TRIGGERS: Array[String] = [
	"expire", "turn_start", "turn_end", "struck", "hit",
	"attacked_in_melee", "incoming_attack", "incoming_spell",
	"enemy_enters_reach", "ally_threatened",
]

## Triggers that run BEFORE the attack or spell resolves. Only these may use
## INTERCEPT_OPS. Their other effects (a counter-attack, a step away) wait
## until the attack is over, so they answer it rather than pre-empt it.
const INTERCEPT_TRIGGERS: Array[String] = ["attacked_in_melee", "incoming_attack", "incoming_spell"]

## Triggers that answer a unit near the carrier. REACTION_TRIGGERS are limited
## to DEFAULT_TRIGGER_LIMIT firings a turn when they do not say otherwise, so
## that a stance cannot end a fight on its own. REACH_TRIGGERS may take a
## `reach` (tiles, or "weapon" for the carrier's own attack range; a `struck`
## with reach 1 answers melee attackers only).
const REACTION_TRIGGERS: Array[String] = ["attacked_in_melee", "enemy_enters_reach", "ally_threatened"]
const REACH_TRIGGERS: Array[String] = ["struck", "attacked_in_melee", "enemy_enters_reach", "ally_threatened"]
const DEFAULT_TRIGGER_LIMIT: int = 3

## Fields a trigger may carry. `limit` is {per: "turn", count, once_per_source?}:
## at most `count` firings until the carrier's next turn begins, and with
## once_per_source at most one for each other unit.
const TRIGGER_FIELDS: Array[String] = ["on", "if", "chance", "effects", "reach", "limit"]
const LIMIT_PER: Array[String] = ["turn"]

## When a status's `periodic` effects run: the start or the end of the
## carrier's turn. Left out, `when` means turn_start.
const PERIODIC_WHEN: Array[String] = ["turn_start", "turn_end"]

## Top-level fields of a status definition, in the new shape.
## `dispellable` and `dispel_methods` are still how dispels choose; stage 3
## moves dispel onto `categories` and retires them.
const STATUS_FIELDS: Array[String] = [
	"name", "icon", "polarity", "categories", "scope", "duration", "stacking",
	"flags", "while_active", "periodic", "triggers", "save", "aura", "spread",
	"cleared_by", "upkeep", "link", "description", "notes",
	"dispellable", "dispel_methods",
]

## Old fields a few statuses still carry, outside stage 2b's scope: each is
## read by its own code (Glass_Globe's `special`, the map's movement and
## travel keys, an aura's `aura_value`) and moves with the stage that owns it
## (stage 3 for `special`, stage 5 for the world keys). Nothing new should be
## added here. The fields stage 2b removed (effects, damage_per_turn,
## retaliation, reaction, save_type, the *_on_expire keys ...) are NOT here,
## so validate_status rejects them.
const LEGACY_STATUS_FIELDS: Array[String] = [
	"affliction", "special", "default_duration_range", "aura_value",
	"damage_increase_pct", "grants_travel_speed_pct", "grants_concealment",
	"grants_movement_ability", "_comment", "_note",
]

## A status's own `save` {stat, dc, when}: at `when` the carrier rolls d20 +
## its effective `stat` against `dc`, and the status ends on a success.
## (A tier needs a caster attribute to build the DC from; a status save uses a
## fixed `dc`, which is what Stunned has always rolled against.)
const SAVE_WHEN: Array[String] = ["turn_start"]

## A status's `spread` {to, reach?, chance, when}: at `when`, with `chance`
## percent, it jumps to one unit within `reach` tiles (default 1) that does
## not have it yet. `to: adjacent` is the one target rule built.
const SPREAD_TO: Array[String] = ["adjacent"]
const SPREAD_WHEN: Array[String] = ["turn_start"]

## Values of {"rest": ...}.
const REST_KINDS: Array[String] = ["quick", "camp", "full"]

## Fields each op may carry besides SHARED_FIELDS. `required` ones are listed
## separately in _validate_op().
const OP_FIELDS: Dictionary = {
	"damage": ["amount", "type"],
	"heal": ["amount"],
	"modify": ["value", "mode", "amount"],
	"status": ["action", "status", "duration", "stacks", "select", "count"],
	"move": ["mode", "tiles", "blocked_damage", "variance", "direction"],
	"kill": ["immune"],
	"summon": ["as", "count", "owner"],
	"zone": ["zone", "aoe", "duration"],
	"resurrect": ["tier", "hp_pct", "scope"],
	"attack": ["target", "power_pct"],
	"negate": [],
	"reflect": [],
}

## Creature tags can't be a const: they come from enemy and race data. Cached
## on first use by creature_tags().
static var _creature_tags: Array[String] = []
static var _creature_tags_loaded: bool = false

## Creature tags that mean something to the rules without appearing in data.
const BUILT_IN_CREATURE_TAGS: Array[String] = ["boss", "living"]

const ENEMY_DATA_DIR: String = "res://resources/data/enemies"
const RACES_PATH: String = "res://resources/data/races.json"


# ── Public API ───────────────────────────────────────────────────────────────

## Validate one effect. `where` names its location ("fireball.effects[2]") and
## prefixes every message. Returns human-readable errors; empty means valid.
## `intercepting` is true only for the effects of a trigger in
## INTERCEPT_TRIGGERS, the one place INTERCEPT_OPS may appear.
static func validate(effect: Dictionary, where: String, intercepting: bool = false) -> Array[String]:
	var errs: Array[String] = []
	var op = effect.get("op", null)
	if typeof(op) != TYPE_STRING or not op in OPS:
		errs.append("%s: unknown op '%s' (approved: %s)" % [where, op, ", ".join(OPS)])
		return errs
	if op in INTERCEPT_OPS and not intercepting:
		errs.append("%s: '%s' only works in a status trigger that runs before the attack "
			% [where, op] + "or spell lands (on: %s)" % ", ".join(INTERCEPT_TRIGGERS))
		return errs

	# Unknown field names are almost always typos ("chanse"), so they fail.
	var allowed: Array = SHARED_FIELDS + OP_FIELDS[op]
	for key in effect:
		if not key in allowed:
			errs.append("%s: unknown field '%s' on a %s effect" % [where, key, op])

	_validate_shared(effect, where, errs)
	_validate_op(String(op), effect, where, errs)
	return errs


## Validate one status definition. Returns human-readable errors; empty means
## valid. The few LEGACY_STATUS_FIELDS are tolerated; any other key fails.
static func validate_status(def: Dictionary, where: String) -> Array[String]:
	var errs: Array[String] = []
	for key in def:
		if not key in STATUS_FIELDS and not key in LEGACY_STATUS_FIELDS:
			errs.append("%s: unknown status field '%s'" % [where, key])

	if def.has("polarity") and not def["polarity"] in POLARITIES:
		errs.append("%s: polarity '%s' unknown (%s)" % [where, def["polarity"], ", ".join(POLARITIES)])
	if def.has("scope") and not def["scope"] in SCOPES:
		errs.append("%s: scope '%s' unknown (%s)" % [where, def["scope"], ", ".join(SCOPES)])

	if def.has("categories"):
		if typeof(def["categories"]) != TYPE_ARRAY:
			errs.append("%s: 'categories' must be a list" % where)
		else:
			for c in def["categories"]:
				if not is_status_category(c):
					errs.append("%s: unknown category '%s' (approved: %s, or elemental.<element>)"
						% [where, c, ", ".join(STATUS_CATEGORIES)])

	if def.has("duration"):
		var d = def["duration"]
		if typeof(d) != TYPE_DICTIONARY:
			errs.append("%s: 'duration' must be {kind, base?}" % where)
		else:
			for k in d:
				if not k in ["kind", "base"]:
					errs.append("%s: duration has unknown key '%s'" % [where, k])
			if not d.get("kind", null) in DURATION_KINDS:
				errs.append("%s: duration kind '%s' unknown (%s)"
					% [where, d.get("kind", null), ", ".join(DURATION_KINDS)])
			if d.has("base") and not _is_number(d["base"]):
				errs.append("%s: duration base must be a number" % where)

	if def.has("stacking"):
		var st = def["stacking"]
		if typeof(st) != TYPE_DICTIONARY:
			errs.append("%s: 'stacking' must be {mode, max?}" % where)
		else:
			for k in st:
				if not k in ["mode", "max"]:
					errs.append("%s: stacking has unknown key '%s'" % [where, k])
			if not st.get("mode", null) in STACKING_MODES:
				errs.append("%s: stacking mode '%s' unknown (%s)"
					% [where, st.get("mode", null), ", ".join(STACKING_MODES)])
			if st.has("max") and not _is_number(st["max"]):
				errs.append("%s: stacking max must be a number" % where)

	if def.has("flags"):
		if typeof(def["flags"]) != TYPE_ARRAY:
			errs.append("%s: 'flags' must be a list" % where)
		else:
			for f in def["flags"]:
				if typeof(f) != TYPE_STRING:
					errs.append("%s: a flag must be a string" % where)
				elif f.begins_with(IMMUNE_FLAG_PREFIX):
					if f.length() == IMMUNE_FLAG_PREFIX.length():
						errs.append("%s: flag 'immune:' names nothing" % where)
				elif not f in FLAGS:
					errs.append("%s: unknown flag '%s' (approved: %s, or immune:<...>)"
						% [where, f, ", ".join(FLAGS)])

	if def.has("while_active"):
		if typeof(def["while_active"]) != TYPE_ARRAY:
			errs.append("%s: 'while_active' must be a list of effects" % where)
		else:
			errs.append_array(validate_list(def["while_active"], where + ".while_active"))
			for i in def["while_active"].size():
				var e = def["while_active"][i]
				if typeof(e) == TYPE_DICTIONARY and e.get("op", "") == "modify" \
						and not e.get("mode", "") in LASTING_MODES:
					errs.append("%s.while_active[%d]: mode '%s' is instant, not lasting (%s)"
						% [where, i, e.get("mode", ""), ", ".join(LASTING_MODES)])

	if def.has("periodic"):
		var per = def["periodic"]
		if typeof(per) != TYPE_DICTIONARY or typeof(per.get("effects", null)) != TYPE_ARRAY:
			errs.append("%s: 'periodic' must be an object with an 'effects' list" % where)
		else:
			if per.has("when") and not per["when"] in PERIODIC_WHEN:
				errs.append("%s: periodic when '%s' unknown (%s)"
					% [where, per["when"], ", ".join(PERIODIC_WHEN)])
			errs.append_array(validate_list(per["effects"], where + ".periodic.effects"))

	if def.has("triggers"):
		if typeof(def["triggers"]) != TYPE_ARRAY:
			errs.append("%s: 'triggers' must be a list" % where)
		else:
			for i in def["triggers"].size():
				var t = def["triggers"][i]
				var label := "%s.triggers[%d]" % [where, i]
				if typeof(t) != TYPE_DICTIONARY:
					errs.append("%s: a trigger must be an object" % label)
					continue
				_validate_trigger(t, label, errs)

	if def.has("save"):
		var sv = def["save"]
		if typeof(sv) != TYPE_DICTIONARY:
			errs.append("%s: 'save' must be {stat, dc, when}" % where)
		else:
			for k in sv:
				if not k in ["stat", "dc", "when"]:
					errs.append("%s: save has unknown key '%s'" % [where, k])
			if not String(sv.get("stat", "")).to_lower() in SaveSystem.ATTRIBUTES:
				errs.append("%s: save stat '%s' is not an attribute" % [where, sv.get("stat", "")])
			if not _is_number(sv.get("dc", null)):
				errs.append("%s: save needs a number 'dc'" % where)
			if not sv.get("when", null) in SAVE_WHEN:
				errs.append("%s: save when '%s' unknown (%s)"
					% [where, sv.get("when", null), ", ".join(SAVE_WHEN)])

	if def.has("spread"):
		var sp = def["spread"]
		if typeof(sp) != TYPE_DICTIONARY:
			errs.append("%s: 'spread' must be {to, reach?, chance, when}" % where)
		else:
			for k in sp:
				if not k in ["to", "reach", "chance", "when"]:
					errs.append("%s: spread has unknown key '%s'" % [where, k])
			if not sp.get("to", null) in SPREAD_TO:
				errs.append("%s: spread to '%s' unknown (%s)" % [where, sp.get("to", null), ", ".join(SPREAD_TO)])
			if not sp.get("when", null) in SPREAD_WHEN:
				errs.append("%s: spread when '%s' unknown (%s)"
					% [where, sp.get("when", null), ", ".join(SPREAD_WHEN)])
			var c = sp.get("chance", null)
			if not _is_number(c) or c < 0 or c > 100:
				errs.append("%s: spread chance must be a number from 0 to 100" % where)
			if sp.has("reach") and not (_is_number(sp["reach"]) and sp["reach"] >= 1):
				errs.append("%s: spread reach must be a number of tiles, 1 or more" % where)

	if def.has("cleared_by"):
		_validate_cleared_by(def["cleared_by"], where, errs)

	return errs


## One entry of a status's `triggers`.
static func _validate_trigger(t: Dictionary, label: String, errs: Array[String]) -> void:
	for k in t:
		if not k in TRIGGER_FIELDS:
			errs.append("%s: unknown trigger field '%s' (approved: %s)" % [label, k, ", ".join(TRIGGER_FIELDS)])
	var on = t.get("on", null)
	if not on in STATUS_TRIGGERS:
		errs.append("%s: unknown trigger '%s' (approved: %s)"
			% [label, on, ", ".join(STATUS_TRIGGERS)])
	if t.has("chance") and (not _is_number(t["chance"]) or t["chance"] < 0 or t["chance"] > 100):
		errs.append("%s: trigger chance must be a number from 0 to 100" % label)
	if t.has("if"):
		if typeof(t["if"]) != TYPE_ARRAY:
			errs.append("%s: 'if' must be a list of conditions" % label)
		else:
			for cond in t["if"]:
				var msg := _condition_error(cond)
				if not msg.is_empty():
					errs.append("%s: %s" % [label, msg])
	if t.has("reach"):
		if not on in REACH_TRIGGERS:
			errs.append("%s: a '%s' trigger takes no reach (%s do)" % [label, on, ", ".join(REACH_TRIGGERS)])
		var r = t["reach"]
		if not (typeof(r) == TYPE_STRING and r == "weapon") and not (_is_number(r) and r >= 1):
			errs.append("%s: reach must be a number of tiles or \"weapon\"" % label)
	if t.has("limit"):
		var lim = t["limit"]
		if typeof(lim) != TYPE_DICTIONARY:
			errs.append("%s: 'limit' must be {per, count, once_per_source?}" % label)
		else:
			for k in lim:
				if not k in ["per", "count", "once_per_source"]:
					errs.append("%s: limit has unknown key '%s'" % [label, k])
			if not lim.get("per", null) in LIMIT_PER:
				errs.append("%s: limit per '%s' unknown (%s)" % [label, lim.get("per", null), ", ".join(LIMIT_PER)])
			if not (_is_number(lim.get("count", null)) and lim["count"] >= 1):
				errs.append("%s: limit count must be a number, 1 or more" % label)
			if lim.has("once_per_source") and typeof(lim["once_per_source"]) != TYPE_BOOL:
				errs.append("%s: limit once_per_source must be true or false" % label)
	if t.has("effects"):
		if typeof(t["effects"]) != TYPE_ARRAY:
			errs.append("%s: 'effects' must be a list" % label)
		else:
			errs.append_array(validate_list(t["effects"], label + ".effects", on in INTERCEPT_TRIGGERS))


## True when `c` is a status category: a STATUS_CATEGORIES name, or
## "elemental.<element>".
static func is_status_category(c) -> bool:
	if typeof(c) != TYPE_STRING:
		return false
	if c in STATUS_CATEGORIES:
		return true
	return c.begins_with(ELEMENTAL_CATEGORY_PREFIX) \
		and c.trim_prefix(ELEMENTAL_CATEGORY_PREFIX) in ELEMENTS


## Validate a list of effects, labelling each by index. `intercepting`: see
## validate().
static func validate_list(effects: Array, where: String, intercepting: bool = false) -> Array[String]:
	var errs: Array[String] = []
	for i in effects.size():
		var label := "%s[%d]" % [where, i]
		if typeof(effects[i]) != TYPE_DICTIONARY:
			errs.append("%s: an effect must be an object, got %s" % [label, type_string(typeof(effects[i]))])
			continue
		errs.append_array(validate(effects[i], label, intercepting))
	return errs


## True when `path` is "<namespace>.<name>" with both parts approved.
static func is_value_path(path: String) -> bool:
	return _value_path_error(path).is_empty()


## Every creature tag the data uses, plus "boss" and "living". Read from the
## `tags` arrays anywhere in enemies/*.json and races.json, once, then cached.
static func creature_tags() -> Array[String]:
	if _creature_tags_loaded:
		return _creature_tags
	_creature_tags_loaded = true
	_creature_tags = BUILT_IN_CREATURE_TAGS.duplicate()
	var dir := DirAccess.open(ENEMY_DATA_DIR)
	if dir == null:
		push_error("EffectVocab: cannot open %s" % ENEMY_DATA_DIR)
	else:
		for file_name in dir.get_files():
			if file_name.ends_with(".json"):
				_collect_tags(_read_json(ENEMY_DATA_DIR + "/" + file_name))
	_collect_tags(_read_json(RACES_PATH))
	_creature_tags.sort()
	return _creature_tags


# ── Shared fields ────────────────────────────────────────────────────────────

static func _validate_shared(effect: Dictionary, where: String, errs: Array[String]) -> void:
	if effect.has("to") and not effect["to"] in SELECTORS:
		errs.append("%s: unknown 'to' '%s' (approved: %s)" % [where, effect["to"], ", ".join(SELECTORS)])

	if effect.has("chance"):
		var c = effect["chance"]
		if not _is_number(c) or c < 0 or c > 100:
			errs.append("%s: 'chance' must be a number from 0 to 100, got %s" % [where, c])

	if effect.has("save"):
		var s = effect["save"]
		if typeof(s) != TYPE_DICTIONARY:
			errs.append("%s: 'save' must be {stat, tier}" % where)
		else:
			if not String(s.get("stat", "")).to_lower() in SaveSystem.ATTRIBUTES:
				errs.append("%s: save stat '%s' is not an attribute" % [where, s.get("stat", "")])
			if not SaveSystem.TIERS.has(s.get("tier", "")):
				errs.append("%s: save tier '%s' unknown (known: %s)"
					% [where, s.get("tier", ""), ", ".join(SaveSystem.TIERS.keys())])
	if effect.has("on_save"):
		if not effect["on_save"] in ["fail", "pass"]:
			errs.append("%s: 'on_save' must be \"fail\" or \"pass\"" % where)
		if not effect.has("save"):
			errs.append("%s: 'on_save' without a 'save'" % where)

	if effect.has("if"):
		if typeof(effect["if"]) != TYPE_ARRAY:
			errs.append("%s: 'if' must be a list of conditions" % where)
		else:
			for cond in effect["if"]:
				var msg := _condition_error(cond)
				if not msg.is_empty():
					errs.append("%s: %s" % [where, msg])

	if effect.has("scale"):
		_validate_scale(effect["scale"], where, errs)

	if effect.has("bonus_vs"):
		if typeof(effect["bonus_vs"]) != TYPE_DICTIONARY:
			errs.append("%s: 'bonus_vs' must map creature tag to multiplier" % where)
		else:
			for tag in effect["bonus_vs"]:
				if not tag in creature_tags():
					errs.append("%s: bonus_vs names unknown creature tag '%s'" % [where, tag])
				if not _is_number(effect["bonus_vs"][tag]):
					errs.append("%s: bonus_vs['%s'] must be a number" % [where, tag])

	if effect.has("cleared_by"):
		if effect.get("op") != "modify" or effect.get("mode") != "damage":
			errs.append("%s: 'cleared_by' is only valid on a modify with mode \"damage\"" % where)
		_validate_cleared_by(effect["cleared_by"], where, errs)


static func _validate_scale(scale, where: String, errs: Array[String]) -> void:
	if typeof(scale) != TYPE_DICTIONARY:
		errs.append("%s: 'scale' must be {per, amount, cap}" % where)
		return
	var per = scale.get("per", "")
	var per_ok: bool = per in SCALE_PER
	if not per_ok and typeof(per) == TYPE_STRING and per.begins_with(SCALE_STATUS_STACK_PREFIX):
		var status_name: String = per.trim_prefix(SCALE_STATUS_STACK_PREFIX)
		per_ok = _status_error(status_name).is_empty()
	if not per_ok:
		errs.append("%s: scale.per '%s' is not approved (%s, or %s<status>)"
			% [where, per, ", ".join(SCALE_PER), SCALE_STATUS_STACK_PREFIX])
	if not _is_number(scale.get("amount", null)):
		errs.append("%s: scale.amount must be a number" % where)
	if scale.has("cap") and not _is_number(scale["cap"]):
		errs.append("%s: scale.cap must be a number" % where)


static func _validate_cleared_by(list, where: String, errs: Array[String]) -> void:
	if typeof(list) != TYPE_ARRAY or list.is_empty():
		errs.append("%s: 'cleared_by' must be a non-empty list" % where)
		return
	for entry in list:
		if typeof(entry) != TYPE_DICTIONARY or entry.size() != 1:
			errs.append("%s: each cleared_by entry is a one-key object like {\"rest\": \"full\"}" % where)
			continue
		var kind: String = String(entry.keys()[0])
		var arg = entry[kind]
		match kind:
			"rest":
				if not arg in REST_KINDS:
					errs.append("%s: cleared_by rest '%s' unknown (%s)" % [where, arg, ", ".join(REST_KINDS)])
			"heal":
				if typeof(arg) != TYPE_DICTIONARY:
					errs.append("%s: cleared_by heal takes {school?, min_level?}" % where)
					continue
				for k in arg:
					if not k in ["school", "min_level"]:
						errs.append("%s: cleared_by heal has unknown key '%s'" % [where, k])
				if arg.has("school") and not (String(arg["school"]) + "_magic" in PerkSystem.MAGIC_SCHOOLS
						or String(arg["school"]) in PerkSystem.MAGIC_SCHOOLS):
					errs.append("%s: cleared_by heal school '%s' is not a magic school" % [where, arg["school"]])
				if arg.has("min_level") and not _is_number(arg["min_level"]):
					errs.append("%s: cleared_by heal min_level must be a number" % where)
			"restore":
				if typeof(arg) != TYPE_STRING:
					errs.append("%s: cleared_by restore takes a value path string" % where)
				else:
					var msg := _value_path_error(arg)
					if not msg.is_empty():
						errs.append("%s: cleared_by restore: %s" % [where, msg])
			"cleanse":
				if typeof(arg) != TYPE_DICTIONARY or arg.size() != 1 or not arg.has("category"):
					errs.append("%s: cleared_by cleanse takes {\"category\": <status category>}" % where)
				elif not is_status_category(arg["category"]):
					errs.append("%s: cleared_by cleanse category '%s' unknown" % [where, arg["category"]])
			_:
				errs.append("%s: unknown cleared_by kind '%s' (approved: %s)"
					% [where, kind, ", ".join(CLEARED_BY)])


# ── Ops ──────────────────────────────────────────────────────────────────────

static func _validate_op(op: String, effect: Dictionary, where: String, errs: Array[String]) -> void:
	match op:
		"damage":
			_require(effect, ["amount", "type"], where, errs)
			_validate_magnitude(effect, "amount", false, where, errs)
			if effect.has("type"):
				_validate_damage_type(effect["type"], where, errs)
		"heal":
			_require(effect, ["amount"], where, errs)
			_validate_magnitude(effect, "amount", true, where, errs)
		"modify":
			_require(effect, ["value", "mode", "amount"], where, errs)
			_validate_modify(effect, where, errs)
		"status":
			_validate_status(effect, where, errs)
		"move":
			_require(effect, ["mode"], where, errs)
			if effect.has("mode") and not (typeof(effect["mode"]) == TYPE_STRING
					and Repositioning.is_mode(effect["mode"])):
				errs.append("%s: move mode '%s' unknown (%s)" % [where, effect["mode"], ", ".join(Repositioning.MODES)])
		"kill":
			if effect.has("immune"):
				if typeof(effect["immune"]) != TYPE_ARRAY:
					errs.append("%s: kill 'immune' must be a list of creature tags" % where)
				else:
					for tag in effect["immune"]:
						if not tag in creature_tags():
							errs.append("%s: kill immune names unknown creature tag '%s'" % [where, tag])
		"summon":
			_require(effect, ["as"], where, errs)
			if effect.has("as") and not CombatManager.has_summon_template(String(effect["as"])):
				errs.append("%s: summon template '%s' is not in summon_templates.json" % [where, effect["as"]])
			if effect.has("count") and not _is_number(effect["count"]):
				errs.append("%s: summon count must be a number" % where)
			if effect.has("owner") and not effect["owner"] in SUMMON_OWNERS:
				errs.append("%s: summon owner '%s' unknown (%s)" % [where, effect["owner"], ", ".join(SUMMON_OWNERS)])
		"attack":
			if not effect.get("target", "source") in ATTACK_TARGETS:
				errs.append("%s: attack target '%s' unknown (%s)"
					% [where, effect.get("target", ""), ", ".join(ATTACK_TARGETS)])
			if effect.has("power_pct") and not (_is_number(effect["power_pct"]) and effect["power_pct"] > 0):
				errs.append("%s: attack power_pct must be a number above 0" % where)
		"negate", "reflect":
			pass   # no fields: the hook that fired the trigger does the work
		"zone":
			_require(effect, ["zone"], where, errs)
			if effect.has("zone") and not Zone.exists(String(effect["zone"])):
				errs.append("%s: zone '%s' is not in zones.json" % [where, effect["zone"]])
		"resurrect":
			_require(effect, ["tier"], where, errs)
			if effect.has("tier") and not Resurrection.is_tier(String(effect["tier"])):
				errs.append("%s: %s" % [where, Resurrection.explain_unknown_tier(String(effect["tier"]))])
			if effect.has("scope") and not Resurrection.is_scope(String(effect["scope"])):
				errs.append("%s: resurrect scope '%s' unknown (%s)"
					% [where, effect["scope"], ", ".join(Resurrection.SCOPES)])
			if effect.has("hp_pct") and not _is_number(effect["hp_pct"]):
				errs.append("%s: resurrect hp_pct must be a number" % where)


static func _validate_modify(effect: Dictionary, where: String, errs: Array[String]) -> void:
	var mode = effect.get("mode", null)
	if effect.has("mode") and not mode in MODES:
		errs.append("%s: unknown mode '%s' (approved: %s)" % [where, mode, ", ".join(MODES)])
	if effect.has("value"):
		var msg := _value_path_error(String(effect["value"]))
		if not msg.is_empty():
			errs.append("%s: %s" % [where, msg])
		elif mode in MODES:
			var ns: String = String(effect["value"]).get_slice(".", 0)
			if not mode in MODES_BY_NAMESPACE[ns]:
				errs.append("%s: mode '%s' is not allowed on %s. values (allowed: %s)"
					% [where, mode, ns, ", ".join(MODES_BY_NAMESPACE[ns])])
	_validate_magnitude(effect, "amount", false, where, errs)


static func _validate_status(effect: Dictionary, where: String, errs: Array[String]) -> void:
	_require(effect, ["action"], where, errs)
	var action = effect.get("action", "")
	if effect.has("action") and not (action == "apply" or action in StatusOps.OPS):
		errs.append("%s: status action '%s' unknown (apply, %s)" % [where, action, ", ".join(StatusOps.OPS)])
		return
	if action == "apply":
		_require(effect, ["status"], where, errs)
		if effect.has("status"):
			var msg := _status_error(String(effect["status"]))
			if not msg.is_empty():
				errs.append("%s: %s" % [where, msg])
	elif effect.has("action"):
		_require(effect, ["select"], where, errs)
		var sel = effect.get("select", {})
		if typeof(sel) != TYPE_DICTIONARY:
			errs.append("%s: 'select' must be {names} or {tag} plus optional count" % where)
		else:
			for n in sel.get("names", []):
				var msg := _status_error(String(n))
				if not msg.is_empty():
					errs.append("%s: select: %s" % [where, msg])
			if sel.has("tag") and not StatusOps.is_tag(String(sel["tag"])):
				errs.append("%s: select: %s" % [where, StatusOps.explain_unknown_tag(String(sel["tag"]))])


## A magnitude is a number, "full" (heal only), {base, per_spellpower},
## {pct_of, value} or {min, max}.
static func _validate_magnitude(effect: Dictionary, field: String, allow_full: bool,
		where: String, errs: Array[String]) -> void:
	if not effect.has(field):
		return
	var m = effect[field]
	if _is_number(m):
		return
	if typeof(m) == TYPE_STRING:
		if not (allow_full and m == "full"):
			errs.append("%s: '%s' string '%s' not allowed%s" % [where, field, m,
				"" if allow_full else " (\"full\" is for heal only)"])
		return
	if typeof(m) != TYPE_DICTIONARY:
		errs.append("%s: '%s' must be a number or a magnitude object" % [where, field])
		return
	var keys: Array = m.keys()
	keys.sort()
	if keys == ["base", "per_spellpower"] or keys == ["base"]:
		if not (_is_number(m["base"]) and _is_number(m.get("per_spellpower", 0))):
			errs.append("%s: %s base/per_spellpower must be numbers" % [where, field])
	elif keys == ["max", "min"]:
		if not (_is_number(m["min"]) and _is_number(m["max"])) or m["min"] > m["max"]:
			errs.append("%s: %s {min, max} must be numbers with min <= max" % [where, field])
	elif keys == ["pct_of", "value"]:
		var msg := _pct_of_error(String(m["pct_of"]))
		if not msg.is_empty():
			errs.append("%s: %s" % [where, msg])
		if not _is_number(m["value"]):
			errs.append("%s: %s pct_of value must be a number" % [where, field])
	elif m.has("from"):
		_validate_borrow(m, field, where, errs)
	else:
		errs.append("%s: '%s' object has keys %s; expected {base, per_spellpower}, {pct_of, value}, {min, max} or {from, ...}"
			% [where, field, keys])


## A borrowed magnitude {from, pct?, default?, add?, round?, min?}.
static func _validate_borrow(m: Dictionary, field: String, where: String, errs: Array[String]) -> void:
	for k in m:
		if not k in BORROW_FIELDS:
			errs.append("%s: %s borrowed value has unknown key '%s' (approved: %s)"
				% [where, field, k, ", ".join(BORROW_FIELDS)])
	var msg := borrow_source_error(str(m["from"]))
	if not msg.is_empty():
		errs.append("%s: %s" % [where, msg])
	for k in ["pct", "default", "add", "min"]:
		if m.has(k) and not _is_number(m[k]):
			errs.append("%s: %s borrowed '%s' must be a number" % [where, field, k])
	if m.has("round") and not m["round"] in ROUNDINGS:
		errs.append("%s: %s borrowed round '%s' unknown (%s)" % [where, field, m["round"], ", ".join(ROUNDINGS)])


## Empty when a magnitude may borrow from `source`, otherwise the reason.
static func borrow_source_error(source: String) -> String:
	if source in BORROW_SOURCES:
		return ""
	var prefix: String = source.get_slice(".", 0)
	if prefix in BORROW_UNIT_PREFIXES and source.count(".") == 2:
		var msg := _value_path_error(source.substr(prefix.length() + 1))
		return "" if msg.is_empty() else "borrowed from '%s': %s" % [source, msg]
	return "cannot borrow from '%s' (%s, or %s.<value path>)" % [source,
		", ".join(BORROW_SOURCES), "/".join(BORROW_UNIT_PREFIXES)]


## `type` is one damage type, or a split {type: share} whose shares sum to 1.
static func _validate_damage_type(t, where: String, errs: Array[String]) -> void:
	if typeof(t) == TYPE_STRING:
		if not DamageType.exists(t):
			errs.append("%s: %s" % [where, DamageType.explain_unknown(t)])
	elif typeof(t) == TYPE_DICTIONARY:
		var total := 0.0
		for name in t:
			if not DamageType.exists(String(name)):
				errs.append("%s: %s" % [where, DamageType.explain_unknown(String(name))])
			if not _is_number(t[name]):
				errs.append("%s: damage split share for '%s' must be a number" % [where, name])
			else:
				total += float(t[name])
		if t.is_empty() or absf(total - 1.0) > 0.001:
			errs.append("%s: damage split shares sum to %s, must be 1" % [where, total])
	else:
		errs.append("%s: damage 'type' must be a name or a {type: share} split" % where)


# ── Names ────────────────────────────────────────────────────────────────────

## Empty string when `path` is a valid value path, otherwise the reason.
static func _value_path_error(path: String) -> String:
	var parts := path.split(".")
	if parts.size() != 2:
		return "value path '%s' must look like namespace.name" % path
	var ns := parts[0]
	var name := parts[1]
	if not ns in NAMESPACES:
		return "unknown namespace '%s' in '%s' (approved: %s)" % [ns, path, ", ".join(NAMESPACES)]
	match ns:
		"attribute":
			if not name in ATTRIBUTES:
				return "unknown attribute '%s' in '%s'" % [name, path]
		"resource":
			if not name in RESOURCES:
				return "unknown resource '%s' in '%s' (approved: %s)" % [name, path, ", ".join(RESOURCES)]
		"stat":
			if not name in STATS:
				return "unknown stat '%s' in '%s' (approved: %s)" % [name, path, ", ".join(STATS)]
		"skill":
			var skills := PerkSystem.get_all_skill_ids()
			if skills.is_empty():
				push_error("EffectVocab: PerkSystem has loaded no skills; cannot check '%s'" % path)
				return "skills.json is not loaded, so '%s' cannot be checked" % path
			if not name in skills:
				return "unknown skill '%s' in '%s'" % [name, path]
		"resist":
			if not (name in RESIST_GROUPS or DamageType.exists(name)):
				return "unknown resist '%s' in '%s' (a damage type, or %s)" % [name, path, ", ".join(RESIST_GROUPS)]
	return ""


## pct_of names a value path, or target./caster. plus a CombatStats.DERIVED key.
static func _pct_of_error(source: String) -> String:
	for prefix in ["target.", "caster."]:
		if source.begins_with(prefix):
			var key := source.trim_prefix(prefix)
			if key in CombatStats.DERIVED:
				return ""
			return "pct_of '%s': '%s' is not a derived stat" % [source, key]
	return _value_path_error(source)


## Empty string when the status exists in statuses.json, otherwise the reason.
static func _status_error(status_name: String) -> String:
	var defs: Dictionary = CombatManager.get_all_status_definitions()
	if defs.is_empty():
		push_error("EffectVocab: CombatManager has loaded no statuses; cannot check '%s'" % status_name)
		return "statuses.json is not loaded, so '%s' cannot be checked" % status_name
	if not defs.has(status_name):
		return "status '%s' is not in statuses.json" % status_name
	return ""


## One entry of an `if` list: a plain condition string, {"target_has": status
## or status tag}, or {"target_is": creature tag}. Empty string means valid.
static func _condition_error(cond) -> String:
	if typeof(cond) == TYPE_STRING:
		if CombatStats.is_perk_condition(cond):
			return ""
		return "unknown condition '%s'" % cond
	if typeof(cond) == TYPE_DICTIONARY and cond.size() == 1:
		var key: String = String(cond.keys()[0])
		var arg := String(cond[key])
		match key:
			"target_has":
				if StatusOps.is_tag(arg) or _status_error(arg).is_empty():
					return ""
				return "target_has '%s' is neither a status nor a status tag" % arg
			"target_is":
				if arg in creature_tags():
					return ""
				return "target_is '%s' is not a creature tag" % arg
			"target_lacks":
				if StatusOps.is_tag(arg) or _status_error(arg).is_empty():
					return ""
				return "target_lacks '%s' is neither a status nor a status tag" % arg
		return "unknown condition form '%s' (approved: %s)" % [key, ", ".join(CONDITION_KEYS)]
	return "a condition is a name or a one-key object, got %s" % [cond]


# ── Small helpers ────────────────────────────────────────────────────────────

static func _require(effect: Dictionary, fields: Array, where: String, errs: Array[String]) -> void:
	for f in fields:
		if not effect.has(f):
			errs.append("%s: %s effect needs '%s'" % [where, effect.get("op", "?"), f])


static func _is_number(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


static func _read_json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("EffectVocab: cannot open %s" % path)
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed


## Walk any parsed JSON and gather every string in a "tags" array.
static func _collect_tags(node) -> void:
	if typeof(node) == TYPE_DICTIONARY:
		for key in node:
			if key == "tags" and typeof(node[key]) == TYPE_ARRAY:
				for tag in node[key]:
					if typeof(tag) == TYPE_STRING and not tag in _creature_tags:
						_creature_tags.append(tag)
			else:
				_collect_tags(node[key])
	elif typeof(node) == TYPE_ARRAY:
		for item in node:
			_collect_tags(item)
