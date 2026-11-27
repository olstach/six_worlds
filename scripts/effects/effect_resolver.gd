class_name EffectResolver
extends RefCounted
## Carries out a list of effects (the shared JSON effect language) against
## the units an EffectContext names.
##
## One effect is a dictionary like {"op": "damage", "amount": 20, "type": "fire"}
## (spec: docs/superpowers/specs/2026-11-25-effect-normalization-design.md §4).
## resolve() walks the list in order and, for each effect:
##   0. validates it with EffectVocab; an invalid effect is refused, loudly
##   1. `to`       picks the recipients (default "target")
## and then, separately for each recipient:
##   2. `if`       every condition must hold
##   3. `chance`   rolled, through CombatManager.effective_status_chance
##   4. `save`     rolled once per recipient and shared by every later effect
##                 of the container; `on_save` picks which branch runs
##   5. magnitude  the amount, then `scale`, then `bonus_vs`
##   6. the op itself: damage, heal or modify (this stage)
##
## Every effect-and-recipient pair adds one entry to the returned log:
##   {"op", "to": unit_name, "applied": bool, "reason": String, "amount": float}
## `reason` says why an entry did not apply ("chance", "save passed" ...), so a
## caller or a test can see what happened without re-deriving it.
##
## Every op in EffectVocab.OPS is built. status, move, kill, summon, zone and
## resurrect only DELEGATE: each calls the CombatManager function that cast_spell
## already uses, so the old and new paths cannot drift apart. `attack` is a free
## weapon attack by the caster at the trigger's source. `negate` and `reflect`
## are never resolved here: they change an attack that is still on its way, so
## the hook that fired the intercepting trigger reads them (see
## CombatManager._run_status_trigger), and the vocabulary refuses them anywhere
## else.


## Ops placed at a ground tile rather than done to a unit.
const POSITION_OPS: Array[String] = ["summon", "zone"]


# ── Public API ───────────────────────────────────────────────────────────────

## Resolve `effects` in order against the units `ctx` names. Returns the log,
## one entry per effect per recipient (one entry for a refused effect).
static func resolve(effects: Array, ctx: EffectContext) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in effects.size():
		var effect = effects[i]
		var where: String = "%s %s effects[%d]" % [ctx.container_kind, ctx.container_id, i]
		if typeof(effect) != TYPE_DICTIONARY:
			push_error("EffectResolver: %s is not an effect object" % where)
			out.append(_entry("?", null, false, "invalid: %s is not an object" % where, 0.0))
			continue
		var op: String = str(effect.get("op", "?"))
		# Rule 0: an effect the vocabulary rejects never runs.
		var errs: Array[String] = EffectVocab.validate(effect, where)
		if not errs.is_empty():
			push_error("EffectResolver: refusing an invalid effect: %s" % errs[0])
			out.append(_entry(op, null, false, "invalid: " + errs[0], 0.0))
			continue
		# Position ops (summon, zone) happen once per effect, at a tile, no
		# matter what `to` says; every other op runs once per recipient.
		if op in POSITION_OPS:
			out.append(_resolve_one(effect, ctx, ctx.target))
			continue
		# A free attack is made once, by the caster, at whoever set the
		# trigger off; `if` and `chance` are asked of that unit.
		if op == "attack":
			out.append(_resolve_one(effect, ctx, ctx.source))
			continue
		for unit in recipients(str(effect.get("to", "target")), ctx):
			out.append(_resolve_one(effect, ctx, unit))
	return out


## How big `spec` is for `recipient`. `spec` is any magnitude shape:
##   20                                a plain number
##   "full"                            the recipient's max_hp (heal)
##   {"base": 10, "per_spellpower": 0.5}   base + 0.5 x ctx.power
##   {"min": 5, "max": 10}             rolled; whole numbers if both are
##   {"pct_of": "target.max_hp", "value": 25}   25% of that value
##   {"from": "caster.skill.leadership", "pct": 50}   a borrowed value: see
##                                     EffectVocab.BORROW_SOURCES and borrow()
## For pct_of, "target." means the recipient and "caster." the caster, each
## followed by a derived stat; a bare value path ("resource.mana") is read on
## the recipient.
static func magnitude(spec: Variant, ctx: EffectContext, recipient: Node) -> float:
	match typeof(spec):
		TYPE_INT, TYPE_FLOAT:
			return float(spec)
		TYPE_STRING:
			if spec == "full" and recipient != null and "max_hp" in recipient:
				return float(recipient.max_hp)
			push_error("EffectResolver.magnitude: unknown magnitude '%s'" % spec)
			return 0.0
		TYPE_DICTIONARY:
			if spec.has("base"):
				return float(spec["base"]) + float(spec.get("per_spellpower", 0)) * ctx.power
			if spec.has("min") and spec.has("max"):
				if typeof(spec["min"]) == TYPE_INT and typeof(spec["max"]) == TYPE_INT:
					return float(randi_range(spec["min"], spec["max"]))
				return randf_range(float(spec["min"]), float(spec["max"]))
			if spec.has("pct_of"):
				return _read_source(str(spec["pct_of"]), ctx, recipient) \
					* float(spec.get("value", 0)) / 100.0
			if spec.has("from"):
				return borrow(spec, ctx, recipient)
	push_error("EffectResolver.magnitude: cannot read magnitude %s" % [spec])
	return 0.0


## A borrowed magnitude {from, pct?, default?, add?, round?, min?}, worked out
## in that order (EffectVocab documents each key):
##   {"from": "status.value", "default": 5}       the spell's value, else 5
##   {"from": "status.value", "add": 5}           5 plus the spell's value
##   {"from": "event.damage", "pct": 20, "round": "up", "min": 1}
static func borrow(spec: Dictionary, ctx: EffectContext, recipient: Node) -> float:
	var raw: float = _borrowed_raw(str(spec["from"]), ctx, recipient)
	var v: float = raw * float(spec.get("pct", 100)) / 100.0
	if raw <= 0.0 and spec.has("default"):
		v = float(spec["default"])
	v += float(spec.get("add", 0))
	match str(spec.get("round", "")):
		"up":
			v = ceilf(v)
		"down":
			v = floorf(v)
	if spec.has("min"):
		v = maxf(v, float(spec["min"]))
	return v


## The number a borrowed magnitude's `from` names, before pct and the rest.
static func _borrowed_raw(source: String, ctx: EffectContext, recipient: Node) -> float:
	match source:
		"status.value":
			return float(ctx.status_entry.get("value", 0))
		"status.stacks":
			return float(ctx.status_entry.get("stacks", 1))
		"event.damage":
			return float(ctx.event.get("damage", 0))
	var prefix: String = source.get_slice(".", 0)
	var path: String = source.substr(prefix.length() + 1)
	match prefix:
		"caster":
			return _read_value_path(path, ctx.caster)
		"target":
			return _read_value_path(path, recipient)
		"source":
			return _read_value_path(path, ctx.source)
	push_error("EffectResolver: cannot borrow from '%s'" % source)
	return 0.0


## The units a `to` selector names. Area selectors read ctx.area_units and
## judge "ally" and "enemy" by the CASTER's team; `party` is every living unit
## on the caster's team in the fight.
static func recipients(selector: String, ctx: EffectContext) -> Array:
	var out: Array = []
	match selector:
		"target":
			if ctx.target != null:
				out.append(ctx.target)
		"caster":
			if ctx.caster != null:
				out.append(ctx.caster)
		"allies_in_area", "enemies_in_area", "all_in_area":
			for unit in ctx.area_units:
				if unit == null or not _alive(unit):
					continue
				var same: bool = _same_team(unit, ctx.caster)
				if selector == "all_in_area" \
						or (selector == "allies_in_area" and same) \
						or (selector == "enemies_in_area" and not same):
					out.append(unit)
		"party":
			for unit in CombatManager.all_units:
				if unit != null and _alive(unit) and _same_team(unit, ctx.caster):
					out.append(unit)
		"source":
			# A dead source is nobody to answer: no slowing or burning a corpse.
			if ctx.source != null and is_instance_valid(ctx.source) and _alive(ctx.source):
				out.append(ctx.source)
		_:
			push_error("EffectResolver.recipients: unknown selector '%s'" % selector)
	return out


## The creature tags `unit` has, for `target_is` and `bonus_vs`: its data's
## `tags`, plus "boss" when its enemy archetype lists the boss role, plus
## "living" unless it is undead or a construct.
static func unit_tags(unit: Node) -> Array[String]:
	var tags: Array[String] = []
	if unit == null:
		return tags
	var data: Dictionary = unit.character_data if "character_data" in unit else {}
	for tag in data.get("tags", []):
		tags.append(str(tag))
	if "boss" in _archetype_of(unit).get("roles", []) and not "boss" in tags:
		tags.append("boss")
	if not "undead" in tags and not "construct" in tags and not "living" in tags:
		tags.append("living")
	return tags


# ── One effect on one recipient ──────────────────────────────────────────────

static func _resolve_one(effect: Dictionary, ctx: EffectContext, unit: Node) -> Dictionary:
	var op: String = str(effect["op"])

	# A position op may have no unit at all (a ground-aimed cast); `if` and
	# `save` need one.
	if unit == null and (effect.has("if") or effect.has("save")):
		push_error("EffectResolver: %s has `if`/`save` but no target unit" % op)
		return _entry(op, null, false, "no target unit for if/save", 0.0)

	# 2. `if`: every condition must hold.
	for cond in effect.get("if", []):
		if not _condition_met(cond, ctx, unit):
			return _entry(op, unit, false, "condition %s not met" % [cond], 0.0)

	# 3. `chance`, adjusted by the caster's status-chance bonus as every other
	# chance-to-apply roll is.
	if effect.has("chance"):
		var caster_data: Dictionary = {}
		if ctx.caster != null and "character_data" in ctx.caster:
			caster_data = ctx.caster.character_data
		var chance: float = CombatManager.effective_status_chance(caster_data, float(effect["chance"]))
		if not randf() * 100.0 < chance:
			return _entry(op, unit, false, "chance", 0.0)

	# 4. `save`: rolled once per recipient, then reused.
	if effect.has("save"):
		var roll: Dictionary = _save_roll(effect["save"], ctx, unit)
		var wanted: String = str(effect.get("on_save", "fail"))
		var passed: bool = bool(roll.get("success", false))
		if (wanted == "fail" and passed) or (wanted == "pass" and not passed):
			return _entry(op, unit, false, "save %s" % ("passed" if passed else "failed"), 0.0)

	# 5. How much: the magnitude, then scale, then bonus_vs.
	var m: float = _scaled_magnitude(effect, ctx, unit)

	# 6. The op.
	match op:
		"damage":
			return _do_damage(effect, ctx, unit, m)
		"heal":
			return _do_heal(ctx, unit, m)
		"modify":
			return _do_modify(effect, ctx, unit, m)
		"status":
			return _do_status(effect, ctx, unit)
		"move":
			return _do_move(effect, ctx, unit)
		"kill":
			return _do_kill(effect, unit)
		"summon":
			return _do_summon(effect, ctx)
		"zone":
			return _do_zone(effect, ctx)
		"resurrect":
			return _do_resurrect(effect, ctx, unit)
		"attack":
			return _do_attack(effect, ctx, unit)
	push_error("EffectResolver: op '%s' is not built yet" % op)
	return _entry(op, unit, false, "op '%s' not built yet" % op, 0.0)


static func _scaled_magnitude(effect: Dictionary, ctx: EffectContext, unit: Node) -> float:
	var m: float = magnitude(effect.get("amount", 0), ctx, unit)
	if effect.has("scale"):
		var scale: Dictionary = effect["scale"]
		var grow: float = float(scale.get("amount", 0)) * _scale_count(str(scale.get("per", "")), ctx, unit)
		if scale.has("cap"):
			grow = minf(grow, float(scale["cap"]))
		m += grow
	if effect.has("bonus_vs"):
		var tags: Array[String] = unit_tags(unit)
		for tag in effect["bonus_vs"]:
			if str(tag) in tags:
				m *= float(effect["bonus_vs"][tag])
	# A stacking status (stacking.mode "stack") keeps one entry with a
	# `stacks` count; its magnitudes multiply by that count (spec §4.4).
	if ctx.status_entry.has("stacks"):
		m *= float(ctx.status_entry["stacks"])
	return m


# ── Ops ──────────────────────────────────────────────────────────────────────

## The containers whose damage below 1 does nothing at all: a status (its
## periodic ticks and its triggers, such as the reflection of a blow that did
## no damage), an aura or a zone. A spell's damage always reaches apply_damage,
## even 0, as it did in stage 1.
const NO_ZERO_DAMAGE_KINDS: Array[String] = ["status", "aura", "zone"]


## Typed damage through CombatManager.apply_damage (resistance, absorption and
## on-hit reactions all live there). A split type hits once per part.
## In a NO_ZERO_DAMAGE_KINDS container nothing at all happens for an amount
## below 1, as no status ever dealt zero damage on purpose.
## A status's own damage names no dealer (ctx.anonymous_damage), and a status
## tick gets its applier's damage-over-time bonuses (ctx.dot_tick).
static func _do_damage(effect: Dictionary, ctx: EffectContext, unit: Node, m: float) -> Dictionary:
	var type = effect["type"]
	var dealer: Node = null if ctx.anonymous_damage else ctx.caster
	if ctx.dot_tick and typeof(type) == TYPE_STRING:
		m = float(CombatManager.status_tick_damage(ctx.caster, str(type), int(m)))
	if int(m) <= 0 and ctx.container_kind in NO_ZERO_DAMAGE_KINDS:
		return _entry("damage", unit, false, "no damage", 0.0)
	if typeof(type) == TYPE_DICTIONARY:
		for part in type:
			CombatManager.apply_damage(unit, int(m * float(type[part])), str(part), dealer)
	else:
		CombatManager.apply_damage(unit, int(m), str(type), dealer)
	return _entry("damage", unit, true, "", m)


## Heal HP (CombatUnit.heal applies healing_pct), then let the heal clear any
## persistent damage whose cleared_by accepts this school and level. A
## status's heal over time, or an aura's or zone's heal, is not a spell's
## heal, so it clears nothing.
static func _do_heal(ctx: EffectContext, unit: Node, m: float) -> Dictionary:
	if not unit.has_method("heal"):
		push_error("EffectResolver: %s cannot be healed" % unit)
		return _entry("heal", unit, false, "cannot be healed", 0.0)
	unit.heal(int(m))
	if ValuePaths.is_party_unit(unit) and not ctx.container_kind in ["status", "aura", "zone"]:
		_clear_damage(unit, "heal", {"school": ctx.all_schools(), "level": ctx.level})
	return _entry("heal", unit, true, "", m)


## The Morrowind effect: change `value` by `mode`. See the table in spec §4.2.
static func _do_modify(effect: Dictionary, ctx: EffectContext, unit: Node, m: float) -> Dictionary:
	var value: String = str(effect["value"])
	var mode: String = str(effect["mode"])
	var ns: String = value.get_slice(".", 0)
	var name: String = value.get_slice(".", 1)

	# Pressure is instant and has no hold: it goes straight to PsychologySystem.
	if ns == "pressure":
		return _do_pressure(unit, name, mode, m)

	# A group target is its members, one after another, with the same effect.
	# The entry reports the members' total.
	if ns in ["skills", "attributes"]:
		if mode in ["fortify", "drain"]:
			# One hold call: add_hold itself expands the group under one source.
			if ctx.hold_source.is_empty():
				push_error("EffectResolver: '%s' %s needs ctx.hold_source (who releases the hold?)"
					% [mode, value])
				return _entry("modify", unit, false, "no hold_source for %s" % mode, 0.0)
			ValuePaths.add_hold(unit, value, mode, m, ctx.hold_source)
			return _entry("modify", unit, true, "", m)
		var members: Array[String] = ValuePaths.expand(value)
		var total: float = 0.0
		var any_applied: bool = false
		var reason: String = ""
		for member in members:
			var each: Dictionary = effect.duplicate()
			each["value"] = member
			var one: Dictionary = _do_modify(each, ctx, unit, m)
			if bool(one.get("applied", false)):
				any_applied = true
				total += float(one.get("amount", 0.0))
			else:
				reason = str(one.get("reason", ""))
		return _entry("modify", unit, any_applied, "" if any_applied else reason, total)

	# Resources move at once and keep no hold.
	if ns == "resource":
		match mode:
			"restore":
				return _entry("modify", unit, true, "", float(_resource_restore(unit, name, int(m))))
			"drain":
				return _entry("modify", unit, true, "", float(_resource_drain(unit, name, int(m))))
			"absorb":
				if ctx.caster == null:
					push_error("EffectResolver: absorb on %s has no caster to give it to" % value)
					return _entry("modify", unit, false, "absorb needs a caster", 0.0)
				var taken: int = _resource_drain(unit, name, int(m))
				_resource_restore(ctx.caster, name, taken)
				return _entry("modify", unit, true, "", float(taken))

	# Persistent harm, and what undoes it.
	if mode == "damage":
		ValuePaths.apply_damage_mode(unit, value, m, effect.get("cleared_by", []),
			"%s:%s" % [ctx.container_kind, ctx.container_id], ctx.source_categories)
		return _entry("modify", unit, true, "", m)
	if mode == "restore":
		if ValuePaths.is_party_unit(unit):
			_clear_damage(unit, "restore", {"value": value, "amount": m})
			return _entry("modify", unit, true, "", m)
		return _entry("modify", unit, true, "", ValuePaths.reduce_damage_holds(unit, value, m))

	# fortify / drain / set / multiply: a hold someone must own.
	if ctx.hold_source.is_empty():
		push_error("EffectResolver: '%s' %s needs ctx.hold_source (who releases the hold?)"
			% [mode, value])
		return _entry("modify", unit, false, "no hold_source for %s" % mode, 0.0)
	ValuePaths.add_hold(unit, value, mode, m, ctx.hold_source)
	return _entry("modify", unit, true, "", m)


## `pressure.<element>`: fortify adds emotional pressure, drain relieves it
## (PsychologySystem.apply_pressure scales it by the character's affinity).
## Only a sheet PsychologySystem keeps state for takes it: one with no
## `emotional_pressure` is refused, and so is an enemy's (the sheet is the same
## shape, so the state exists, but nothing ever runs psychology for it: no
## drift, no crisis UI). Refusal is a reason in the log entry, never an error.
static func _do_pressure(unit: Node, element: String, mode: String, m: float) -> Dictionary:
	var sheet: Dictionary = unit.character_data if "character_data" in unit else {}
	if not sheet.get("emotional_pressure", {}).has(element):
		return _entry("modify", unit, false, "no psychology", 0.0)
	var signed: float = m if mode == "fortify" else -m
	PsychologySystem.apply_pressure(sheet, element, signed)
	return _entry("modify", unit, true, "", signed)


## Apply a status (through CombatManager._apply_status_effect, which holds every
## immunity and resistance check) or run a status operation (remove, steal,
## transfer, convert ... through CombatManager._apply_status_op).
##   {"op":"status","action":"apply","status":"Burning","duration":3}
##   {"op":"status","action":"remove","select":{"names":["Burning"]}}
## `duration` is a number, "combat" or "spellpower" (the last two go through
## _calculate_status_duration like a spell's). `stacks` repeats the apply.
static func _do_status(effect: Dictionary, ctx: EffectContext, unit: Node) -> Dictionary:
	var action: String = str(effect["action"])
	if action == "apply":
		var duration: int
		if typeof(effect.get("duration", null)) in [TYPE_INT, TYPE_FLOAT]:
			duration = int(effect["duration"])
		else:
			duration = CombatManager._calculate_status_duration(ctx.caster,
				{"duration": effect.get("duration", "spellpower")}, ctx.power)
		# _apply_status_effect answers false when the status was resisted (an
		# immunity, a talisman, gear, an affliction resistance). The log must
		# say so, or a spell's report claims a status that never landed.
		var landed: bool = false
		for i in maxi(1, int(effect.get("stacks", 1))):
			if CombatManager._apply_status_effect(unit, str(effect["status"]), duration, 0, ctx.caster):
				landed = true
		if not landed:
			return _entry("status", unit, false, "resisted", 0.0)
		return _entry("status", unit, true, "", float(duration))
	# Any other action: today's status_ops shape is {op, select, from, to, on}.
	# The recipient plays "target", so `on` and `from` default to it.
	var op_spec: Dictionary = effect.duplicate(true)
	op_spec["op"] = action
	for shared in ["action", "to", "if", "chance", "save", "on_save"]:
		op_spec.erase(shared)
	var result: Dictionary = {"effects_applied": []}
	CombatManager._apply_status_op(ctx.caster, unit, op_spec, result)
	# Each op reports how much it did: `removed` for a remove, `count` for the
	# rest. Nothing done means nothing matched, which the log must not call applied.
	var done: int = 0
	for logged in result.effects_applied:
		done += int(logged.get("removed", logged.get("count", 0)))
	if done <= 0:
		return _entry("status", unit, false, "nothing to remove", 0.0)
	return _entry("status", unit, true, "", float(done))


## Forced movement through CombatManager: push and pull via _apply_push (as a
## spell's `push` block), every other mode via reposition() aimed at the
## context's target tile. A blocked push slams the unit for its blocked_damage
## (physical), as cast_spell does.
## A placed mode (scatter, teleport ...) reads how far it may go from `range`,
## which a `move` effect has no field for, so its `tiles` is passed on as the
## range (Heavenly Counterflow's scatter of 2 tiles).
static func _do_move(effect: Dictionary, ctx: EffectContext, unit: Node) -> Dictionary:
	var spec: Dictionary = effect.duplicate()
	for shared in ["op", "to", "if", "chance", "save", "on_save"]:
		spec.erase(shared)
	if spec.has("tiles") and not spec.has("range") and not Repositioning.is_travelled(str(spec["mode"])):
		spec["range"] = spec["tiles"]
	var moved: Dictionary
	if spec["mode"] in ["push", "pull"]:
		moved = CombatManager._apply_push(ctx.caster, unit, spec)
		var slam: int = int(moved.get("blocked_damage", 0))
		if slam > 0 and unit.is_alive():
			CombatManager.apply_damage(unit, slam, "physical", ctx.caster)
			CombatManager.combat_log.emit("%s is slammed into an obstacle!" % unit.unit_name)
	else:
		var aim: Vector2i = ctx.target.grid_position if ctx.target != null else unit.grid_position
		moved = CombatManager.reposition(unit, spec, ctx.caster, aim)
	return _entry("move", unit, bool(moved.get("ok", false)), str(moved.get("reason", "")),
		float(moved.get("moved", 0)))


## Outright death, the same two lines _apply_save_gated uses for instant_kill
## (lethal true damage: the unit starts bleeding out, then dies, as ever).
## `immune` (default ["boss"]) lists creature tags that refuse it: a refused
## kill does nothing at all, says so in the combat log and records "immune".
static func _do_kill(effect: Dictionary, unit: Node) -> Dictionary:
	var immune: Array = effect.get("immune", ["boss"])
	var tags: Array[String] = unit_tags(unit)
	for tag in immune:
		if str(tag) in tags:
			CombatManager.combat_log.emit("%s cannot be undone outright." % unit.unit_name)
			return _entry("kill", unit, false, "immune", 0.0)
	if not unit.is_alive():     # dead or already bleeding out
		return _entry("kill", unit, false, "already dead", 0.0)
	CombatManager.combat_log.emit("%s is undone." % unit.unit_name)
	CombatManager.apply_damage(unit, unit.current_hp + unit.max_hp, "true")
	return _entry("kill", unit, true, "", 0.0)


## A position op's log entry: `to` names what was placed, not a unit.
static func _placed_entry(op: String, what: String, applied: bool, reason: String,
		amount: float) -> Dictionary:
	return {"op": op, "to": what, "applied": applied, "reason": reason, "amount": amount}


## Refuse a position op that has no tile, loudly.
static func _no_position(op: String, what: String) -> Dictionary:
	push_error("EffectResolver: %s '%s' has no position (set ctx.target_pos or ctx.target)" % [op, what])
	return _placed_entry(op, what, false, "no position", 0.0)


## Summon `count` of template `as` for the caster at the context's position
## (the spawner finds the nearest free tile when it is taken). Power is ctx.power.
## `from: corpse` stands it on the tile of the unit the effect is aimed at
## (ctx.target), which must be dead: Grave Soil raising what fell on it.
static func _do_summon(effect: Dictionary, ctx: EffectContext) -> Dictionary:
	var what: String = str(effect["as"])
	var at: Vector2i = ctx.position()
	if str(effect.get("from", "")) == "corpse":
		if ctx.target == null or _alive(ctx.target):
			return _placed_entry("summon", what, false, "no corpse to raise", 0.0)
		at = ctx.target.grid_position
	if at == EffectContext.NO_POS:
		return _no_position("summon", what)
	# Whose side it fights on, and whose Summoning scales it.
	var owner: Node = ctx.target if str(effect.get("owner", "caster")) == "target" else ctx.caster
	if owner == null:
		push_error("EffectResolver: summon '%s' has no %s to fight for" % [what, effect.get("owner", "caster")])
		return _placed_entry("summon", what, false, "no owner", 0.0)
	var made: int = 0
	for i in maxi(1, int(effect.get("count", 1))):
		var spawned: Dictionary = CombatManager._spawn_summoned_unit(
			owner, what, at, ctx.power)
		if spawned.get("success", false):
			made += 1
	return _placed_entry("summon", what, made > 0, "" if made > 0 else "no space for summon", float(made))


## Lay a zone on the ground with CombatManager.place_zone. Footprint and turns
## come from CombatManager.zone_footprint / zone_turns, the same functions
## cast_spell uses for spell.zone, reading the effect's `aoe` and `duration`.
static func _do_zone(effect: Dictionary, ctx: EffectContext) -> Dictionary:
	var what: String = str(effect["zone"])
	var at: Vector2i = ctx.position()
	if at == EffectContext.NO_POS:
		return _no_position("zone", what)
	var tiles: Array = CombatManager.zone_footprint(effect, ctx.caster, at)
	var turns: int = CombatManager.zone_turns(effect, ctx.power)
	var placed: bool = CombatManager.place_zone(what, tiles, ctx.caster, turns)
	return _placed_entry("zone", what, placed, "" if placed else "the ground will not hold it", float(tiles.size()))


## Raise the dead through CombatManager._apply_resurrection (tier, hp_pct and
## scope as a spell's `resurrection` block). Applied only if someone rose.
static func _do_resurrect(effect: Dictionary, ctx: EffectContext, unit: Node) -> Dictionary:
	var spec: Dictionary = {"tier": effect["tier"]}
	for key in ["hp_pct", "scope"]:
		if effect.has(key):
			spec[key] = effect[key]
	var result: Dictionary = {"effects_applied": []}
	CombatManager._apply_resurrection(ctx.caster, unit, spec, result)
	var raised: int = 0
	var why: String = ""
	for item in result.effects_applied:
		if item.get("type", "") == "resurrect":
			raised += 1
		else:
			why = str(item.get("reason", ""))
	return _entry("resurrect", unit, raised > 0, why, float(raised))


## A free weapon attack by the caster at `victim` (the trigger's source), at
## `power_pct` percent damage. It needs the victim alive and within the
## caster's own attack range; out of reach it does nothing and reports so,
## which keeps a stance's per-turn allowance unspent.
static func _do_attack(effect: Dictionary, ctx: EffectContext, victim: Node) -> Dictionary:
	if ctx.caster == null or victim == null:
		return _entry("attack", victim, false, "nobody to attack", 0.0)
	var struck: bool = CombatManager.free_reaction_attack(ctx.caster, victim,
		float(effect.get("power_pct", 100)), ctx.container_id)
	return _entry("attack", victim, struck, "" if struck else "out of reach", 1.0 if struck else 0.0)


## clear_damage on a party unit's character, passing the unit so held entries
## lift at once; if anything changed, recompute the character's derived stats.
static func _clear_damage(unit: Node, kind: String, detail: Dictionary) -> void:
	var character: Dictionary = unit.character_data
	var before: float = _damage_sum(character)
	ValuePaths.clear_damage(character, kind, detail, unit)
	if _damage_sum(character) != before:
		CharacterSystem.update_derived_stats(character)


static func _damage_sum(character: Dictionary) -> float:
	var total: float = 0.0
	for entry in character.get("damaged_values", []):
		total += float(entry.get("amount", 0))
	return total


## temp_hp has no maximum and is not one of ResourceOps' pools, so it is
## handled here; hp / mana / stamina go through ResourceOps.
static func _resource_restore(unit: Node, resource: String, amount: int) -> int:
	if resource == "temp_hp":
		var given: int = maxi(0, amount)
		unit.temp_hp = int(unit.temp_hp) + given
		return given
	return ResourceOps.restore(unit, resource, amount)


static func _resource_drain(unit: Node, resource: String, amount: int) -> int:
	if resource == "temp_hp":
		var taken: int = mini(maxi(0, amount), int(unit.temp_hp))
		unit.temp_hp = int(unit.temp_hp) - taken
		return taken
	return ResourceOps.drain(unit, resource, amount)


# ── Shared-field helpers ─────────────────────────────────────────────────────

## One `if` entry. A string goes to the caster's perk-condition test (with the
## recipient as its target); {"target_has": status or status tag} and
## {"target_is": creature tag} are checked on the recipient.
static func _condition_met(cond, ctx: EffectContext, unit: Node) -> bool:
	if typeof(cond) == TYPE_STRING:
		if ctx.caster == null or not ctx.caster.has_method("_perk_condition_met"):
			return false
		return ctx.caster._perk_condition_met(cond, unit)
	var key: String = str(cond.keys()[0])
	var arg: String = str(cond[key])
	match key:
		"target_has":
			if StatusOps.is_tag(arg):
				return not StatusOps.select(unit, {"tag": arg},
					CombatManager.get_all_status_definitions()).is_empty()
			return unit.has_method("has_status") and unit.has_status(arg)
		"target_is":
			return arg in unit_tags(unit)
		"target_lacks":
			return not _condition_met({"target_has": arg}, ctx, unit)
		"spell_school":
			# The spell that set a `casts` trigger off carries its schools in
			# the event ("fire", "sorcery"...), lower case.
			return arg.to_lower() in ctx.event.get("schools", [])
	push_error("EffectResolver: unknown condition %s" % [cond])
	return false


## The save against `unit` for this container, rolling it the first time.
## The DC is built on the caster's Focus, as spell saves are by default.
##
## A save with a fixed `dc` (an aura's or zone's) uses that number plus the
## caster's status-chance bonus (CombatManager.status_save_dc_bonus), minus
## `dc_drop_per_pass` for every time this recipient has passed this container's
## save before. The passes are remembered on the recipient, in
## `aura_save_passes` keyed by the container id, so Shining Mirage wears out
## against whoever keeps their head and against nobody else.
static func _save_roll(save: Dictionary, ctx: EffectContext, unit: Node) -> Dictionary:
	var key: int = unit.get_instance_id()
	if not ctx.save_result.has(key):
		var stat: String = str(save.get("stat", ""))
		if save.has("dc"):
			var passes: int = int(unit.aura_save_passes.get(ctx.container_id, 0)) \
				if "aura_save_passes" in unit else 0
			var dc: int = int(save["dc"]) - passes * int(save.get("dc_drop_per_pass", 0)) \
				+ CombatManager.status_save_dc_bonus(ctx.caster)
			var roll: Dictionary = SaveSystem.roll(unit, stat, maxi(1, dc))
			if roll.success and "aura_save_passes" in unit:
				unit.aura_save_passes[ctx.container_id] = passes + 1
			ctx.save_result[key] = roll
		else:
			var dc: int = SaveSystem.dc_for(ctx.caster, "focus", str(save.get("tier", "normal")))
			ctx.save_result[key] = SaveSystem.roll(unit, stat, dc)
	return ctx.save_result[key]


## How many times a `scale` applies ("per" in EffectVocab.SCALE_PER).
static func _scale_count(per: String, ctx: EffectContext, unit: Node) -> float:
	if per.begins_with(EffectVocab.SCALE_STATUS_STACK_PREFIX):
		var wanted: String = per.trim_prefix(EffectVocab.SCALE_STATUS_STACK_PREFIX).to_lower()
		var stacks: int = 0
		for entry in unit.status_effects:
			if str(entry.get("status", "")).to_lower() == wanted:
				# One entry per stack (the old `stackable`), or one entry
				# carrying a `stacks` count (stacking.mode "stack").
				stacks += int(entry.get("stacks", 1))
		return float(stacks)
	match per:
		"spellpower":
			return float(ctx.power)
		"turn_active":
			# Turns the status running this effect has been on: 0 on its
			# first tick. Only a status's own effects have an entry to read.
			if ctx.status_entry.is_empty():
				push_error("EffectResolver: scale per 'turn_active' outside a status")
				return 0.0
			return float(ctx.status_entry.get("turns_active", 0))
		"debuff_on_target", "buff_on_target":
			var polarity: String = "negative" if per == "debuff_on_target" else "positive"
			var defs: Dictionary = CombatManager.get_all_status_definitions()
			var n: int = 0
			for entry in unit.status_effects:
				if defs.get(str(entry.get("status", "")), {}).get("polarity", "") == polarity:
					n += 1
			return float(n)
		"ally_in_area":
			var n: int = 0
			for other in ctx.area_units:
				if other != null and other != ctx.caster and _alive(other) \
						and _same_team(other, ctx.caster):
					n += 1
			return float(n)
	push_error("EffectResolver: unknown scale per '%s'" % per)
	return 0.0


## The number a pct_of names. "target.<derived>" reads the recipient,
## "caster.<derived>" the caster; anything else is a value path on the recipient.
static func _read_source(source: String, ctx: EffectContext, recipient: Node) -> float:
	var unit: Node = recipient
	var key: String = source
	if source.begins_with("target."):
		key = source.trim_prefix("target.")
	elif source.begins_with("caster."):
		unit = ctx.caster
		key = source.trim_prefix("caster.")
	else:
		return _read_value_path(source, unit)
	if unit == null:
		return 0.0
	if key in unit:                         # max_hp, max_mana ... live on the unit
		return float(unit.get(key))
	if unit.has_method("get_" + key):       # get_dodge(), get_spellpower() ...
		return float(unit.call("get_" + key))
	return float(unit.character_data.get("derived", {}).get(key, 0))


static func _read_value_path(path: String, unit: Node) -> float:
	if unit == null:
		return 0.0
	var name: String = path.get_slice(".", 1)
	match path.get_slice(".", 0):
		"resource":
			if name == "temp_hp":
				return float(unit.temp_hp)
			return float(ResourceOps.current(unit, name))
		"stat":
			return float(unit.call("get_" + name)) if unit.has_method("get_" + name) else 0.0
		"attribute":
			# Effective, like "skill." below: an amount that scales with
			# attribute.focus sees a Focus hold.
			return float(CharacterSystem.get_effective_attribute(unit.character_data, name))
		"skill":
			return float(CharacterSystem.get_effective_skill_level(unit.character_data, name))
		"resist":
			return Resistance.total(unit, name)
		"affinity":
			return float(PerkSystem.calculate_element_affinity(unit.character_data, name))
	push_error("EffectResolver: cannot read value path '%s'" % path)
	return 0.0


# ── Small helpers ────────────────────────────────────────────────────────────

## The enemy archetype `unit` was built from, or {}. Read by id; the name kept
## in unit_archetype is only a fallback, since several archetypes could share it.
static func _archetype_of(unit: Node) -> Dictionary:
	if EnemySystem == null:
		return {}
	var data: Dictionary = unit.character_data if "character_data" in unit else {}
	var id: String = str(data.get("archetype_id", ""))
	if id != "" and EnemySystem.archetypes.has(id):
		return EnemySystem.archetypes[id]
	if "unit_archetype" in unit and str(unit.unit_archetype) != "":
		for arch in EnemySystem.archetypes.values():
			if str(arch.get("name", "")) == str(unit.unit_archetype):
				return arch
	return {}


static func _same_team(a: Node, b: Node) -> bool:
	return b != null and "team" in a and "team" in b and a.team == b.team


static func _alive(unit: Node) -> bool:
	if unit.has_method("is_alive"):
		return unit.is_alive()
	return not ("is_dead" in unit and unit.is_dead)


static func _entry(op: String, unit: Node, applied: bool, reason: String, amount: float) -> Dictionary:
	var who: String = ""
	if unit != null:
		who = str(unit.unit_name) if "unit_name" in unit else str(unit)
	return {"op": op, "to": who, "applied": applied, "reason": reason, "amount": amount}
