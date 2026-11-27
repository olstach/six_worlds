class_name Resistance
## Every source that decides how much damage of a given type a unit takes, in
## one place, in one documented order.
##
## Before this there were six, and none of them knew about the others:
## `get_resistance()` ran sixty lines of hand-written `if`s; the Armor table's
## `damage_reduction_pct` and the Yoga table's `magic_resistance_pct` sat inside
## `apply_damage()`; aura and zone `damage_taken_pct` sat beside them;
## `spell_damage_reduction` sat on one spell path only. Additive inside,
## multiplicative outside, capped in two places out of six, and stated nowhere.
##
## THE RULE THAT MAKES ABSORPTION SAFE. Resistance above 100 heals — a fire
## elemental drinks fire, which is the mechanic Final Fantasy called absorb.
## But you must not be able to REACH it by addition, or three defensive buffs
## quietly turn a character into something that feeds on fireballs. So:
##
##   * Contributions are summed and the sum is clamped to [-100, +90]. No
##     stack of buffs makes anyone untouchable, and no stack of curses makes a
##     hit hurt more than double.
##   * A SINGLE DECLARATION of 100 or more is different in kind: it is a
##     statement about what the unit IS. 100 is immunity, above 100 is
##     absorption, and the excess is healed.
##
## One sentence: you cannot buff your way into absorption; being the kind of
## thing that drinks fire is what does it.
##
## WHAT LIVES HERE AND WHAT DOES NOT. This answers "how much of this type does
## the defender take". Attacker-side multipliers — Feed the Fire, Permafrost,
## brands, called shots — stay where the damage is computed, because they are
## facts about the attack rather than the defender. The order that results is
## the one `CombatManager.apply_damage()` documents.

## The sum of additive contributions is clamped to this band.
const REDUCTION_CAP: float = 90.0
const VULNERABILITY_FLOOR: float = -100.0

## A single declaration at or above this is immunity; above it, absorption.
const DECLARED_IMMUNITY: float = 100.0

## And absorption is capped here, so nothing heals for more than the hit.
const ABSORPTION_CAP: float = 200.0

## Afflictions a unit can resist the ONSET of, rather than the damage. These are
## things that happen to you: you resist catching them, not the harm once
## caught. `disease` and `poison` are read by WoundSystem; `bleed` is read by
## CombatManager when a status is applied.
const AFFLICTIONS: Array[String] = ["bleed", "poison", "disease"]

## The highest chance any affliction resistance may reach. Something must always
## be able to go wrong.
const AFFLICTION_CAP: float = 0.95


## How much of `damage_type` this unit resists, as a percentage.
##
## Positive reduces, negative increases, 100 is immunity and above 100 is
## absorption. See the class comment for why only a single declaration may
## cross 100.
static func total(unit: Node, damage_type: String) -> float:
	var gathered: Dictionary = _gather(unit, damage_type)
	var result: float
	if float(gathered.declared) >= DECLARED_IMMUNITY:
		result = minf(float(gathered.declared), ABSORPTION_CAP)
	else:
		result = clampf(float(gathered.sum), VULNERABILITY_FLOOR, REDUCTION_CAP)
	return _apply_holds(unit, damage_type, result)


## Pass a finished resistance through the unit's `set` holds.
##
## Fortify and drain holds on `resist.` are NOT applied here: _gather() counts
## each one as a contribution like any other (step 2 there), so they sum and
## clamp with everything else, and a single fortify of 100 or more is a
## declaration of immunity exactly as a race's or a status's always was.
##
## A `set` hold is a declaration of what the unit IS: it replaces the result
## and may reach the absorption cap. Of several sets that reach this type
## (resist.fire, resist.all_elemental, resist.all ...) the last one added wins.
static func _apply_holds(unit: Node, damage_type: String, base: float) -> float:
	if unit == null or not "effect_holds" in unit or unit.effect_holds.is_empty():
		return base
	var has_set: bool = false
	var set_to: float = 0.0
	for hold in unit.effect_holds:
		if str(hold.mode) != "set":
			continue
		var value: String = str(hold.value)
		if value.begins_with("resist.") and hold_covers(value.trim_prefix("resist."), damage_type):
			has_set = true
			set_to = float(hold.amount)
	if not has_set:
		return base
	return clampf(set_to, VULNERABILITY_FLOOR, ABSORPTION_CAP)


## Does a `resist.<name>` hold reach a hit of `damage_type`? `name` is a damage
## type, `physical` (which also covers its three subtypes), or one of
## EffectVocab.RESIST_GROUPS:
##   all_elemental  types of category `element` in damage_types.json
##   all            everything
##   magic          every type marked `magic`
## DamageType.scope_covers() is the rule for the type, `physical`, `all` and
## `magic`; `all_elemental` is answered here from the type's category.
static func hold_covers(name: String, damage_type: String) -> bool:
	if name == "all_elemental":
		return DamageType.category_of(damage_type) == "element"
	return DamageType.scope_covers(name, damage_type)


## Does this unit shrug off the ONSET of an affliction — bleeding, poison,
## disease? A chance rather than a discount, because catching something is not
## a quantity.
##
## Stone Body's "+25% resistance to bleed" meant this all along, and was read
## by nothing: PerkSystem wrote `bleed` into derived.resistances and no code
## ever asked.
##
## The chance is the unit's own resistance plus every fortify / drain on
## exactly `resist.<affliction>`: the holds a status places and the read-time
## modifies of the auras and zones reaching it (Immune System's 15). A `set`
## hold replaces the total. Only the exact name counts: `resist.all` is about
## damage, not about catching things.
static func resists_affliction(unit: Node, affliction: String) -> bool:
	if unit == null or not "character_data" in unit:
		return false
	var value: String = "resist." + affliction
	var pct: float = float(_own_resistances(unit).get(affliction, 0.0))
	var has_set: bool = false
	var set_to: float = 0.0
	for hold in ValuePaths.holds_on(unit, value):
		match str(hold.mode):
			"fortify": pct += float(hold.amount)
			"drain": pct -= float(hold.amount)
			"set":
				has_set = true
				set_to = float(hold.amount)   # the last one added wins
	pct += AuraSystem.flat_total(unit, value)
	if has_set:
		pct = set_to
	if pct <= 0.0:
		return false
	return randf() < clampf(pct / 100.0, 0.0, AFFLICTION_CAP)


## Resistance to HOW a hit arrived rather than what it is made of. `ranged` is
## the only one so far: Silk armour turns arrows whatever their heads are made
## of. It is not a damage type — it sits in damage_types.json's
## `other_resistances` beside the afflictions — so total() never sees it, and
## the attack path reads it here, next to Air_Shield's ranged_damage_reduction,
## which is the same axis.
##
## Read from the unit's own resistances only (race, traits, equipment and
## material, perks). Clamped like any summed resistance: nothing turns every
## arrow, and a vulnerability at most doubles the hit.
static func delivery(unit: Node, how: String) -> float:
	if unit == null or not is_instance_valid(unit):
		return 0.0
	return clampf(float(_own_resistances(unit).get(how, 0.0)),
		VULNERABILITY_FLOOR, REDUCTION_CAP)


## Resolve a hit of `damage_type` for `damage` points against this unit.
##
## Returns {damage, healed, parts}.
##
## A COMPOUND ARRIVES AS WHICHEVER COMPONENT THE TARGET RESISTS LESS. A solar
## hit against something fireproof lands as white; against a thing that fears
## fire it lands as fire. So a mixed type cannot be walled off by resisting one
## half, and choosing one is a decision about the target rather than a hedge —
## which is the whole reason to have them.
##
## That is why resolution lives here and not in DamageType: which half arrives
## depends on the defender, and DamageType has no defender. An earlier version
## split the damage in half and resisted each half separately; this is the same
## vocabulary read the other way.
##
## `healed` is absorption: the unit is not hurt, it is fed.
static func resolve(unit: Node, damage: int, damage_type: String) -> Dictionary:
	var out: Dictionary = {"damage": 0, "healed": 0, "parts": []}
	if damage <= 0:
		return out
	if DamageType.ignores_resistance(damage_type):
		out.damage = damage
		return out

	var arriving: String = concrete_type(unit, damage_type)
	var pct: float = total(unit, arriving)

	if pct > DECLARED_IMMUNITY:
		# Absorption: the excess over immunity is healed.
		var healed: int = maxi(1, int(round(float(damage)
			* (pct - DECLARED_IMMUNITY) / 100.0)))
		out.healed = healed
		out.parts.append({"type": arriving, "damage": 0, "healed": healed,
			"resistance": pct})
		return out

	var taken: int = maxi(0, int(round(float(damage) * (1.0 - pct / 100.0))))
	# A hit that was not fully resisted still lands for something, so rounding
	# cannot turn a real hit into nothing. Immunity takes nothing at all.
	if taken == 0 and pct < DECLARED_IMMUNITY:
		taken = 1
	out.damage = taken
	out.parts.append({"type": arriving, "damage": taken, "healed": 0,
		"resistance": pct})
	return out


## Which damage type a hit of `damage_type` actually arrives as, against this
## unit: itself for a simple type, a roll for a random one, and for a compound
## the component this unit resists LEAST.
##
## Ties go to the first component listed, so the vocabulary decides and the
## result is stable.
static func concrete_type(unit: Node, damage_type: String) -> String:
	var components: Array = DamageType.components_of(damage_type)
	if components.is_empty():
		return DamageType.concrete(damage_type)   # itself, or a random roll
	var best: String = str(components[0])
	var best_pct: float = total(unit, best)
	for i in range(1, components.size()):
		var candidate: String = str(components[i])
		var pct: float = total(unit, candidate)
		if pct < best_pct:
			best = candidate
			best_pct = pct
	return best


## The one number a character sheet can show: what percentage of a hit of this
## type the unit actually takes, after resistance, armour and the Yoga table.
##
## The examine panel read `unit.resistances` — the static dict — so nothing a
## status, perk, aura or zone contributed ever showed. This is what it should
## ask instead.
static func damage_taken_pct(unit: Node, damage_type: String) -> float:
	# No early-out for immunity: at 100 the multiplier is already zero, and
	# above it the clamp at the end catches the negative. A branch that cannot
	# change the answer is a branch nothing can test.
	var pct: float = total(unit, damage_type)
	var multiplier: float = 1.0 - pct / 100.0

	var derived: Dictionary = unit.character_data.get("derived", {}) \
		if "character_data" in unit else {}
	if not DamageType.ignores_armour(damage_type) and DamageType.is_physical(damage_type):
		var armour: float = minf(float(derived.get("damage_reduction_pct", 0.0)), 90.0)
		multiplier *= 1.0 - armour / 100.0
	if DamageType.is_magic(damage_type):
		var equanimity: float = minf(float(derived.get("magic_resistance_pct", 0.0)), 90.0)
		multiplier *= 1.0 - equanimity / 100.0

	return maxf(0.0, multiplier * 100.0)


## Explain where a unit's resistance to a type comes from, for the UI and for
## anyone debugging a number that looks wrong.
static func breakdown(unit: Node, damage_type: String) -> Array[Dictionary]:
	return (_gather(unit, damage_type).sources as Array[Dictionary])


# ── gathering ────────────────────────────────────────────────────────────────


## Every contribution to `damage_type`, as {sum, declared, sources}.
##
## `sum` is the additive total before clamping. `declared` is the largest
## SINGLE declaration, which is the only thing allowed to cross 100.
static func _gather(unit: Node, damage_type: String) -> Dictionary:
	# An accumulator dictionary rather than local floats, because the
	# contributions are added from several places and GDScript lambdas capture
	# by VALUE — a closure doing `sum += amount` updates its own copy and the
	# caller sees nothing. Inner Flame's +25% fire vanished exactly that way,
	# and a check that drove the real getter is what noticed.
	var acc: Dictionary = {"sum": 0.0, "declared": 0.0, "sources": [] as Array[Dictionary]}

	if unit == null or not is_instance_valid(unit):
		return {"sum": 0.0, "declared": 0.0, "sources": acc.sources}

	# 1. The unit's own dictionary — race, traits, equipment and permanent perk
	#    bonuses, already merged by update_derived_stats(). A physical subtype
	#    falls back to generic physical where the unit declares none of its own,
	#    which is how a skeleton can be weak to crushing in particular.
	var own: Dictionary = _own_resistances(unit)
	if own.has(damage_type):
		_add(acc, float(own[damage_type]), "innate")
	else:
		var fallback: String = DamageType.subtype_of(damage_type)
		if fallback != "" and own.has(fallback):
			_add(acc, float(own[fallback]), "innate (%s)" % fallback)

	# 2. Effect holds — what statuses (and anything else holding a value)
	#    add or take away: each fortify / drain on a `resist.<name>` that
	#    reaches this hit (hold_covers) is its own declaration, labelled with
	#    the status it came from. `set` holds are applied afterwards, in
	#    _apply_holds().
	#
	#    Statuses said this with `grants_resistance` / `grants_vulnerability`
	#    until 2026-11-26, and with twenty named effect strings before that.
	#    They are `while_active` modifies now, held under the status's id.
	if "effect_holds" in unit:
		for hold in unit.effect_holds:
			var value: String = str(hold.value)
			if not value.begins_with("resist.") \
					or not hold_covers(value.trim_prefix("resist."), damage_type):
				continue
			match str(hold.mode):
				"fortify":
					_add(acc, float(hold.amount), _hold_label(unit, str(hold.source_id)))
				"drain":
					_add(acc, -float(hold.amount), _hold_label(unit, str(hold.source_id)))

	# 3. Mantras, which cover magic only — not poison, which is no more magic
	#    than a sword is.
	if DamageType.is_magic(damage_type) and "mantra_stat_bonuses" in unit:
		var mantra: float = float(unit.mantra_stat_bonuses.get("magic_resist", 0))
		if mantra != 0.0:
			_add(acc, mantra, "mantra")

	# 4. Auras and the ground underfoot. Their `resist.` modifies are
	#    read-time (AuraSystem.contributions, the one place their reach is
	#    worked out): each one reaching this unit is its own contribution,
	#    labelled "aura:<emitter instance id>:<aura id>" or "zone:<zone id>".
	for c in AuraSystem.contributions(unit):
		var path: String = str(c.value)
		if not path.begins_with("resist.") \
				or not hold_covers(path.trim_prefix("resist."), damage_type):
			continue
		match str(c.mode):
			"fortify":
				_add(acc, float(c.amount), str(c.label))
			"drain":
				_add(acc, -float(c.amount), str(c.label))

	return acc


## What to call a hold's source in breakdown(): the status it belongs to when
## the source is a status entry's id, otherwise the source id itself.
static func _hold_label(unit: Node, source_id: String) -> String:
	if "status_effects" in unit:
		for entry in unit.status_effects:
			if str(entry.get("id", "")) == source_id:
				return str(entry.get("status", source_id))
	return source_id


## One contribution: added to the sum, and remembered as a single declaration.
##
## `declared` is the LARGEST single contribution, and it is the only thing
## allowed to cross 100 into immunity and absorption. That is what stops three
## defensive buffs from summing their way into drinking fireballs.
static func _add(acc: Dictionary, amount: float, label: String) -> void:
	acc.sum = float(acc.sum) + amount
	acc.declared = maxf(float(acc.declared), amount)
	(acc.sources as Array).append({"source": label, "amount": amount})


static func _own_resistances(unit: Node) -> Dictionary:
	if unit == null:
		return {}
	if "resistances" in unit and unit.resistances is Dictionary:
		return unit.resistances
	if "character_data" in unit:
		return unit.character_data.get("derived", {}).get("resistances", {})
	return {}
