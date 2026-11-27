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
## WHAT AN AURA DOES is a list of effects in the shared effect language, under
## `while_inside` (EffectVocab.validate_aura checks it). Two kinds, and the
## difference matters:
##
## A `modify` is READ-TIME. It is never applied and never stored as a hold: it
## is added up by contributions() every time the number is read, by
## ValuePaths.flat_sum / apply_scaling (the stat getters) and by
## Resistance._gather. Storage is what let mana_cost_reduction reach -500 in
## this codebase: a value recomputed each turn and added to itself. A unit that
## walks out of an aura loses it because the next read simply does not find
## it, with nothing to remember, so movement and death need no bookkeeping.
## In a breakdown each one is labelled "aura:<emitter instance id>:<aura id>".
##
## Every other effect (status, heal, damage) fires once per turn on the
## emitter's turn, through EffectResolver (CombatManager._process_auras).
## `stat.max_hp` is the awkward case: it is read like any modify, but
## CombatManager._refresh_aura_max_hp stores the result as a DELTA on the unit,
## because current_hp has to be clamped when it drops. A repeated refresh is a
## no-op rather than a doubling.
##
## Zones (zones.json) are the same idea anchored to tiles; their read-time
## modifies are added up here too, labelled "zone:<zone id>".

## Who an aura reaches. `self_included` adds the emitter on top of any of these.
const AFFECTS: Array[String] = ["allies", "enemies", "all", "self"]

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


# ── Collection: what does this unit emit? ────────────────────────────────────

## Every aura `unit` is currently projecting, from all four sources.
##
## Returns instances, not definitions: each carries the resolved `effects` with
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
				# The status entry rides along, so an effect can borrow the
				# value the spell put on it ({"from": "status.value"}).
				var inst := _instance(aura_id, "status", status_name, null, effect)
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
##
## `magnitude` is an item's or perk's `aura_value`: a SIGNED number that
## replaces the flat numbers of the aura's effects — a fortify/drain amount
## (its sign picks the mode, so a Khatvanga's -4 drains 4), a pct_of value, a
## heal or damage amount. Auras whose effects want different magnitudes from
## one another should be separate definitions rather than overridden ones.
## `status_entry` is the carrier status's entry, when a status emits it.
static func _instance(aura_id: String, source_kind: String, source_id: String, magnitude,
		status_entry: Dictionary = {}) -> Dictionary:
	var def: Dictionary = get_definition(aura_id)
	if def.is_empty():
		push_warning("AuraSystem: %s '%s' declares unknown aura '%s'"
			% [source_kind, source_id, aura_id])
		return {}

	var effects: Array = []
	for e in def.get("while_inside", []):
		var copy: Dictionary = (e as Dictionary).duplicate(true)
		if magnitude != null:
			_override(copy, float(magnitude))
		effects.append(copy)

	return {
		"id": aura_id,
		"name": def.get("name", aura_id),
		"radius": int(def.get("radius", 2)),
		"affects": def.get("affects", "allies"),
		"self_included": bool(def.get("self_included", false)),
		"invert_for_enemies": bool(def.get("invert_for_enemies", false)),
		"effects": effects,
		# Only the value: a stack count would multiply the aura's numbers,
		# which no aura has ever done.
		"status_entry": {"value": status_entry.get("value", 0)} if not status_entry.is_empty() else {},
		"source_kind": source_kind,
		"source_id": source_id,
	}


## Apply an `aura_value` override to one effect (see _instance).
static func _override(effect: Dictionary, magnitude: float) -> void:
	var op: String = str(effect.get("op", ""))
	var amount = effect.get("amount", null)
	if op == "modify" and str(effect.get("mode", "")) in ["fortify", "drain"]:
		effect["mode"] = "drain" if magnitude < 0.0 else "fortify"
		if amount is Dictionary and amount.has("pct_of"):
			amount["value"] = absf(magnitude)
		else:
			effect["amount"] = absf(magnitude)
	elif op in ["heal", "damage"] and (amount is int or amount is float):
		effect["amount"] = magnitude


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


# ── Read-time modifies: what auras and zones add to a number ─────────────────

## Every read-time `modify` reaching `unit` from an aura or a zone, as
##   {value, mode, amount, label, pct}
## `amount` is already signed for `invert_for_enemies` (a multiply inverts as
## 2 - factor, so 0.8 becomes 1.2). `pct` is true when the amount is a
## percentage of the unit's own sheet value (pct_of), so flat_total can round
## those together, as they always were.
##
## The ONE place the reach rules for read-time numbers live: ValuePaths and
## Resistance both ask here. Computed fresh on every call and never stored.
static func contributions(unit: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if unit == null or not is_instance_valid(unit) or not "grid_position" in unit:
		return out
	if CombatManager == null:
		return out
	for other in CombatManager.all_units:
		if other == null or not is_instance_valid(other) or not "grid_position" in other:
			continue
		var auras: Array[Dictionary] = emitted_by(other)
		if auras.is_empty():
			continue
		var dist: int = CombatManager._aura_distance(other, unit)
		for aura in auras:
			if not reaches(aura, other, unit, dist):
				continue
			var sign_mult: float = sign_for(aura, other, unit)
			var label: String = "aura:%d:%s" % [other.get_instance_id(), aura.id]
			for e in aura.effects:
				if str(e.get("op", "")) == "modify":
					out.append(_contribution(e, unit, aura.status_entry, sign_mult, label))
	for zone in CombatManager.zones_at(unit.grid_position):
		for e in zone.def.get("while_inside", []):
			if str(e.get("op", "")) != "modify":
				continue
			if Zone.effect_reaches(e, zone.def, zone.source, unit):
				out.append(_contribution(e, unit, {}, 1.0, "zone:%s" % zone.id))
	return out


## One effect as a contribution: its number worked out for `unit`.
static func _contribution(e: Dictionary, unit: Node, status_entry: Dictionary,
		sign_mult: float, label: String) -> Dictionary:
	var mode: String = str(e.get("mode", "fortify"))
	var spec = e.get("amount", 0)
	var pct: bool = false
	var amount: float = 0.0
	if spec is Dictionary and spec.has("pct_of"):
		# The recipient's SHEET value, never its getter: the getter is what
		# is being worked out, and asking it would ask this function again.
		var stat: String = str(spec["pct_of"]).trim_prefix("target.")
		var sheet: float = 0.0
		if "character_data" in unit:
			sheet = float(unit.character_data.get("derived", {}).get(stat, 0))
		amount = sheet * float(spec.get("value", 0)) / 100.0
		pct = true
	elif spec is Dictionary and spec.has("from"):
		var ctx := EffectContext.new()
		ctx.status_entry = status_entry
		amount = EffectResolver.borrow(spec, ctx, unit)
	else:
		amount = float(spec)
	if mode == "multiply":
		if sign_mult < 0.0:
			amount = 2.0 - amount
	else:
		amount *= sign_mult
	return {"value": str(e.get("value", "")), "mode": mode, "amount": amount,
		"label": label, "pct": pct}


## The fortify-minus-drain total auras and zones give `unit` on `value`
## ("stat.armor"). Percentages of the sheet are summed first and rounded once.
static func flat_total(unit: Node, value: String) -> float:
	var flat: float = 0.0
	var pct: float = 0.0
	for c in contributions(unit):
		if c.value != value or not c.mode in ["fortify", "drain"]:
			continue
		var signed: float = float(c.amount) if c.mode == "fortify" else -float(c.amount)
		if c.pct:
			pct += signed
		else:
			flat += signed
	return flat + roundf(pct)


## The product of the multiplies auras and zones put on `value`; 1.0 for none.
static func factor(unit: Node, value: String) -> float:
	var f: float = 1.0
	for c in contributions(unit):
		if c.value == value and c.mode == "multiply":
			f *= float(c.amount)
	return f


## The effects of an aura that fire on the emitter's turn (everything but the
## read-time modifies).
static func per_turn_effects(aura: Dictionary) -> Array:
	var out: Array = []
	for e in aura.get("effects", []):
		if str(e.get("op", "")) != "modify":
			out.append(e)
	return out
