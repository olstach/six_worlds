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

## The named status-effect strings that mean "+N% resistance to X", each used
## by exactly one status. Seven of them are different spellings of "+N%
## physical".
##
## This table is a way station, not a destination: it turns twenty hand-written
## `if` branches into one lookup so that migrating the statuses to the
## structured `grants_resistance` they should have been using all along is a
## DATA change with nothing to rewrite here. `amount` may be overridden by a
## field on the status definition, which is how Fire_Vulnerable_50 carries its
## own number.
const LEGACY_EFFECTS: Dictionary = {
	# Physical, seven ways.
	"physical_resist_50":                  {"type": "physical", "amount": 50.0},
	"physical_damage_negation_50_percent": {"type": "physical", "amount": 50.0},
	"physical_damage_reduction_25":        {"type": "physical", "amount": 25.0},
	"physical_damage_reduction_50":        {"type": "physical", "amount": 50.0},
	"physical_damage_reduction_75":        {"type": "physical", "amount": 75.0},
	"physical_resistance_plus_25":         {"type": "physical", "amount": 25.0},
	"physical_resistance_plus_50":         {"type": "physical", "amount": 50.0},
	"vulnerable_to_physical":              {"type": "physical", "amount": -50.0},
	"physical_immunity":                   {"type": "physical", "amount": 100.0},
	"physical_immune":                     {"type": "physical", "amount": 100.0},

	# Elements.
	"fire_resistance_plus_25":   {"type": "fire",  "amount": 25.0},
	"fire_resistance_minus_50":  {"type": "fire",  "amount": -50.0},
	"fire_damage_immunity":      {"type": "fire",  "amount": 100.0},
	"fire_vulnerability":        {"type": "fire",  "amount": -50.0, "field": "vulnerability_pct", "negated": true},
	# The four strings below still say `water` and `air` because that is what
	# the statuses declaring them say. The TYPES those used to name are gone:
	# water damage was impact, ice and drowning wearing one name, and air
	# damage was lightning every time it was dealt. Fluid Form's immunity is to
	# ice and Lightning Form's is to lightning.
	"water_resistance_minus_25": {"type": "ice",       "amount": -25.0},
	"water_resistance_minus_50": {"type": "ice",       "amount": -50.0},
	"water_damage_immunity":     {"type": "ice",       "amount": 100.0},
	"air_damage_immunity":       {"type": "lightning", "amount": 100.0},
	"air_immune":                {"type": "lightning", "amount": 100.0},

	# Everything that is not force.
	"elemental_resistance_25": {"scope": "non_physical", "amount": 25.0},
	"all_element_resistance":  {"scope": "non_physical", "amount": 25.0, "field": "resistance_pct"},
	"magic_resistance_bonus":  {"scope": "non_physical", "amount": 15.0},

	# And everything.
	"immune_to_all_damage": {"scope": "all", "amount": 100.0},
}

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
	if float(gathered.declared) >= DECLARED_IMMUNITY:
		return minf(float(gathered.declared), ABSORPTION_CAP)
	return clampf(float(gathered.sum), VULNERABILITY_FLOOR, REDUCTION_CAP)


## Does this unit shrug off the ONSET of an affliction — bleeding, poison,
## disease? A chance rather than a discount, because catching something is not
## a quantity.
##
## Stone Body's "+25% resistance to bleed" meant this all along, and was read
## by nothing: PerkSystem wrote `bleed` into derived.resistances and no code
## ever asked.
static func resists_affliction(unit: Node, affliction: String) -> bool:
	if unit == null or not "character_data" in unit:
		return false
	var pct: float = float(_own_resistances(unit).get(affliction, 0.0))
	if pct <= 0.0:
		return false
	return randf() < clampf(pct / 100.0, 0.0, AFFLICTION_CAP)


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

	# 2. Statuses, structured first.
	var physical: bool = DamageType.is_physical(damage_type)
	if "status_effects" in unit:
		for effect in unit.status_effects:
			var status_name: String = str(effect.get("status", ""))
			var def: Dictionary = CombatManager.get_status_definition(status_name)
			if def.is_empty():
				continue

			var grants: Dictionary = def.get("grants_resistance", {})
			if grants.has(damage_type):
				_add(acc, float(grants[damage_type]), status_name)
			var vuln: Dictionary = def.get("grants_vulnerability", {})
			if vuln.has(damage_type):
				_add(acc, -float(vuln[damage_type]), status_name)

			# 3. And the named strings, through one table rather than twenty ifs.
			for name in def.get("effects", []):
				var rule: Dictionary = LEGACY_EFFECTS.get(str(name), {})
				if rule.is_empty():
					continue
				if not _rule_applies(rule, damage_type, physical):
					continue
				var amount: float = float(rule.get("amount", 0.0))
				if rule.has("field") and def.has(rule["field"]):
					amount = float(def[rule["field"]])
					if bool(rule.get("negated", false)):
						amount = -amount
				_add(acc, amount, "%s (%s)" % [status_name, str(name)])

	# 4. Mantras, which only ever covered magic.
	if not physical and "mantra_stat_bonuses" in unit:
		var mantra: float = float(unit.mantra_stat_bonuses.get("magic_resist", 0))
		if mantra != 0.0:
			_add(acc, mantra, "mantra")

	return acc


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


static func _rule_applies(rule: Dictionary, damage_type: String, physical: bool) -> bool:
	if rule.has("type"):
		var target: String = str(rule["type"])
		# A rule about "physical" covers its subtypes, which is what made
		# Petrified stop a sword and a mace alike.
		return target == damage_type \
			or (target == "physical" and physical)
	match str(rule.get("scope", "")):
		"all":
			return true
		"non_physical":
			return not physical
	return false
