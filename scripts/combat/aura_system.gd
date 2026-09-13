class_name AuraSystem
## Fields of effect around a unit, declared once and readable by every source.
##
## An aura is a simple idea — "while you are near me, something happens to you" —
## that had grown five separate implementations in this codebase, none of which
## could see the others:
##
##   * `_process_aura_effects()` matched hardcoded effect strings from statuses,
##     so an aura could only exist if someone wrote an `if` for it.
##   * `_process_summon_aura()` wrote three stats by hand for one summon.
##   * `_apply_mantra_tick()` had its own radius and its own ally scan.
##   * The Khatvanga read `passive_aura` off a single equipment slot inside the
##     initiative getter, which is why no other item could ever carry an aura.
##   * `avatar_of_the_storm` swept the team by hand at the moment of each hit.
##
## The cost of that was not duplication, it was reach. A robe could not have an
## aura however plainly its data said so, because the only code that read
## `passive_aura` looked in the weapon hand. `light_aura` sat in Solar_Form for
## months with no consumer anywhere. Three of the five could not express "and
## the opposite for enemies", so each invented its own sign convention.
##
## So: ONE declaration format in resources/data/auras.json, and four sources
## that all name an aura the same way —
##
##   equipment  item.passive_aura = "longlife_hp"      (+ optional aura_value)
##   statuses   status.aura       = "soothing_presence"
##   perks      perk.aura         = "avatar_of_the_storm"
##   spells     spell.aura        = "..."  — applied through its carrier status,
##                                  which is what gives a spell aura a duration
##
## TWO KINDS OF PAYLOAD, AND THE DIFFERENCE MATTERS.
##
## Continuous payloads (`stat`, `damage_taken_pct`) are computed ON DEMAND every
## time the stat is read, and never stored. Storage is what let
## mana_cost_reduction reach -500 in this codebase: a value recomputed each turn
## and added to itself. A unit that walks out of an aura loses it because the
## next read simply does not find it, with nothing to remember and nothing to
## reset.
##
## Per-turn payloads (`heal`, `damage`, `grant_status`) fire once per turn and
## are inherently safe. `max_hp` is the awkward third case: it must be stored,
## because current_hp has to be clamped when it drops. It is applied as a DELTA
## against the last value this system set, which makes a repeated refresh a
## no-op rather than a doubling.

# ── Vocabulary ───────────────────────────────────────────────────────────────
#
# Same rule as CombatStats, for the same reason: a payload kind that nothing
# resolves is a silent no-op, and silent no-ops in data are this project's most
# expensive recurring bug. Every kind here is annotated with its consumer.

## What an aura can do to a unit inside it.
const PAYLOAD_KINDS: Array[String] = [
	"stat",              # continuous — AuraSystem.stat_bonus(), via CombatUnit getters
	"grant_status",      # per turn  — CombatManager._process_auras()
	"heal",              # per turn  — CombatManager._process_auras()
	"damage",            # per turn  — CombatManager._process_auras()
	"max_hp",            # stored    — CombatManager._refresh_aura_max_hp()
	"damage_taken_pct",  # continuous — CombatManager.apply_damage()
]

## Who an aura reaches. `self_included` adds the emitter on top of any of these.
const AFFECTS: Array[String] = ["allies", "enemies", "all", "self"]

## Damage filters a `damage_taken_pct` payload may narrow itself to.
const DAMAGE_FILTERS: Array[String] = ["magic", "physical"]

const DATA_PATH := "res://resources/data/auras.json"

static var _definitions: Dictionary = {}
static var _loaded: bool = false


# ── Definitions ──────────────────────────────────────────────────────────────

## Every declared aura, keyed by id. Loaded once, cached thereafter.
static func definitions() -> Dictionary:
	if _loaded:
		return _definitions
	_loaded = true
	_definitions = {}
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("AuraSystem: cannot open %s" % DATA_PATH)
		return _definitions
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("AuraSystem: %s is not a JSON object" % DATA_PATH)
		return _definitions
	for id in parsed.get("auras", {}):
		if id.begins_with("_"):
			continue  # `_comment_*` keys are documentation, not data
		_definitions[id] = parsed["auras"][id]
	return _definitions


static func get_definition(aura_id: String) -> Dictionary:
	return definitions().get(aura_id, {})


static func exists(aura_id: String) -> bool:
	return definitions().has(aura_id)


## Discard the cache so a test can reload edited definitions.
static func reload() -> void:
	_loaded = false
	_definitions = {}


static func is_payload_kind(kind: String) -> bool:
	return kind in PAYLOAD_KINDS


## One-line explanation of why a payload will not do what its author expects,
## for error messages that are fixable from the log line alone.
static func explain_unknown_kind(kind: String) -> String:
	return ("'%s' is not in AuraSystem.PAYLOAD_KINDS, so nothing resolves it; "
		+ "the aura would be collected and then silently dropped") % kind


# ── Collection: what does this unit emit? ────────────────────────────────────

## Every aura `unit` is currently projecting, from all four sources.
##
## Returns instances, not definitions: each carries the resolved `payloads` with
## any per-source magnitude override already applied, so a caller never has to
## know whether an aura came from a robe or a mantra.
static func emitted_by(unit: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if unit == null or (("is_dead" in unit) and unit.is_dead):
		return out

	var char_data: Dictionary = unit.character_data if "character_data" in unit and unit.character_data is Dictionary else {}

	# 1. EQUIPMENT — every slot, not just the weapon hand. The old Khatvanga
	#    branch looked only at weapon_main, which is the whole reason a chest
	#    robe could carry `passive_aura` in data and do nothing in play.
	if not char_data.is_empty():
		for item_id in _equipped_item_ids(char_data):
			var item: Dictionary = ItemSystem.get_item(item_id)
			var aura_id: String = item.get("passive_aura", "")
			if aura_id == "":
				continue
			# `aura_value` lets one graded line scale a single aura across its
			# five consecrations without five aura definitions.
			var override = item.get("aura_value", null)
			var inst := _instance(aura_id, "equipment", item_id, override)
			if not inst.is_empty():
				out.append(inst)

	# 2. STATUSES — the path spells and active skills reach auras through. A
	#    spell applies its carrier status; the status declares the aura; the
	#    status's own duration is what makes the aura temporary.
	if "status_effects" in unit:
		for effect in unit.status_effects:
			var status_name: String = effect.get("status", "")
			var def: Dictionary = CombatManager.get_status_definition(status_name)
			# One status may carry several auras. Radiance both mends the allies
			# around it and dazzles whoever closes to melee, and those reach
			# different teams at different radii, so they cannot be one aura.
			for aura_id in _aura_ids_of(def):
				var inst := _instance(aura_id, "status", status_name, def.get("aura_value", null))
				if not inst.is_empty():
					out.append(inst)

	# 3. PERKS — standing auras a character carries permanently.
	if not char_data.is_empty():
		for perk_id in PerkSystem.get_owned_perk_ids(char_data):
			var pdef: Dictionary = PerkSystem.get_perk_data(perk_id)
			for aura_id in _aura_ids_of(pdef):
				var inst := _instance(aura_id, "perk", perk_id, pdef.get("aura_value", null))
				if not inst.is_empty():
					out.append(inst)

	# 4. INTRINSIC — a flag set by the code that created the unit, for auras
	#    that belong to the creature rather than to anything it carries.
	if "intrinsic_auras" in unit:
		for aura_id in unit.intrinsic_auras:
			var inst := _instance(aura_id, "intrinsic", aura_id, null)
			if not inst.is_empty():
				out.append(inst)

	return out


## Build one aura instance, applying a magnitude override if the source gave one.
static func _instance(aura_id: String, source_kind: String, source_id: String, magnitude) -> Dictionary:
	var def: Dictionary = get_definition(aura_id)
	if def.is_empty():
		push_warning("AuraSystem: %s '%s' declares unknown aura '%s'"
			% [source_kind, source_id, aura_id])
		return {}

	var payloads: Array = []
	for p in def.get("payloads", []):
		var copy: Dictionary = (p as Dictionary).duplicate()
		# An override replaces the amount on every numeric payload. Auras whose
		# payloads want different magnitudes from one another should be separate
		# definitions rather than overridden ones.
		if magnitude != null and copy.has("amount"):
			copy["amount"] = magnitude
		payloads.append(copy)

	return {
		"id": aura_id,
		"name": def.get("name", aura_id),
		"radius": int(def.get("radius", 2)),
		"affects": def.get("affects", "allies"),
		"self_included": bool(def.get("self_included", false)),
		"invert_for_enemies": bool(def.get("invert_for_enemies", false)),
		"payloads": payloads,
		"source_kind": source_kind,
		"source_id": source_id,
	}


## The auras a definition declares. `aura` may name one or list several.
static func _aura_ids_of(def: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var raw = def.get("aura", null)
	if raw is String and raw != "":
		ids.append(raw)
	elif raw is Array:
		for entry in raw:
			if entry is String and entry != "":
				ids.append(entry)
	return ids


static func _equipped_item_ids(char_data: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var equipment: Dictionary = char_data.get("equipment", {})
	var slots: Array[String] = BodySystem.get_equipment_slots(char_data)
	if slots.is_empty():
		slots = ["head", "chest", "hand_l", "hand_r", "legs", "feet",
			"ring1", "ring2", "amulet", "trinket1", "trinket2"]
	for slot in slots:
		var id: String = equipment.get(slot, "")
		if id != "" and not id in ids:
			ids.append(id)
	# The active weapon set is nested under weapon_set_N with its own key names,
	# so ask ItemSystem rather than reaching into the dictionary a second way.
	for slot in ["weapon_main", "weapon_off"]:
		var id: String = ItemSystem.get_equipped_item(char_data, slot)
		if id != "" and not id in ids:
			ids.append(id)
	return ids


# ── Reach: does this aura touch that unit? ───────────────────────────────────

## True when `target` is inside `aura` emitted by `source`.
##
## `distance` is passed in rather than computed so this file never needs to know
## how the grid measures itself.
static func reaches(aura: Dictionary, source: Node, target: Node, distance: int) -> bool:
	if target == null or (("is_dead" in target) and target.is_dead):
		return false
	if distance > int(aura.get("radius", 2)):
		return false

	if target == source:
		# The emitter is only in its own aura if it says so — a healing presence
		# heals its wearer, a Khatvanga does not slow the one holding it.
		return aura.get("affects", "allies") == "self" or aura.get("self_included", false)

	var same_team: bool = ("team" in source) and ("team" in target) and source.team == target.team
	match aura.get("affects", "allies"):
		"allies":
			return same_team
		"enemies":
			return not same_team
		"all":
			return true
		"self":
			return false
	return false


## The sign this aura's numbers take for `target` — negated for the far team
## when the aura declares `invert_for_enemies`.
static func sign_for(aura: Dictionary, source: Node, target: Node) -> float:
	if not aura.get("invert_for_enemies", false):
		return 1.0
	var same_team: bool = ("team" in source) and ("team" in target) and source.team == target.team
	return 1.0 if same_team else -1.0


# ── Continuous payloads ──────────────────────────────────────────────────────

## Total aura bonus to `stat` for `unit`, summed over every aura reaching it.
##
## Computed fresh on every call and never stored, which is what makes walking
## out of an aura work with no bookkeeping at all.
static func stat_bonus(unit: Node, stat: String, units: Array, distance_fn: Callable) -> float:
	var total := 0.0
	for other in units:
		for aura in emitted_by(other):
			var dist: int = distance_fn.call(other, unit)
			if not reaches(aura, other, unit, dist):
				continue
			var mult := sign_for(aura, other, unit)
			for p in aura["payloads"]:
				if p.get("kind", "") == "stat" and p.get("stat", "") == stat:
					total += float(p.get("amount", 0)) * mult
	return total


## Multiplier on incoming damage of `damage_kind` ("magic" or "physical") for
## `unit`, from every `damage_taken_pct` aura reaching it. 1.0 means untouched.
static func damage_taken_multiplier(unit: Node, damage_kind: String, units: Array, distance_fn: Callable) -> float:
	var mult := 1.0
	for other in units:
		for aura in emitted_by(other):
			var dist: int = distance_fn.call(other, unit)
			if not reaches(aura, other, unit, dist):
				continue
			var sign_mult := sign_for(aura, other, unit)
			for p in aura["payloads"]:
				if p.get("kind", "") != "damage_taken_pct":
					continue
				var only: String = p.get("only", "")
				if only != "" and only != damage_kind:
					continue
				mult *= 1.0 + (float(p.get("amount", 0)) * sign_mult / 100.0)
	return maxf(0.0, mult)


## Total `max_hp` granted to `unit` by auras reaching it. Stored by the caller
## as a delta — see CombatManager._refresh_aura_max_hp().
static func max_hp_bonus(unit: Node, units: Array, distance_fn: Callable) -> int:
	var total := 0
	for other in units:
		for aura in emitted_by(other):
			var dist: int = distance_fn.call(other, unit)
			if not reaches(aura, other, unit, dist):
				continue
			var mult := sign_for(aura, other, unit)
			for p in aura["payloads"]:
				if p.get("kind", "") == "max_hp":
					total += int(float(p.get("amount", 0)) * mult)
	return total
