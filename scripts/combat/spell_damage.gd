class_name SpellDamage
## Damage that is computed rather than written down.
##
## Most spells carry a number. Seven carried a STRING — "spellpower_scaling",
## "50%_max_hp", "fall_damage", "burning_stacks_consumed" — and the reader in
## _apply_spell_effects tested `is int or is float` before applying anything, so
## all seven silently dealt nothing. Two were level 9 capstones costing 225 mana.
##
## They were not typos. Each named a formula the engine did not have, and the
## formulas are good: an execute that scales off the target's own health, a nuke
## that rewards a specialist's spellpower, a detonation that spends a
## damage-over-time for a burst. So this file gives those formulas a vocabulary
## instead of giving the strings a fallback.
##
## The vocabulary is closed and validated. An unknown formula returns 0 and says
## so loudly, rather than resolving to a default that looks like it worked —
## that default is exactly how the original bug survived.

## Formula names a spell's `damage` block may use. Each is annotated with the
## spell that asked for it.
const FORMULAS: Array[String] = [
	"spellpower",          # implosion — scales heavily with the caster
	"target_max_hp_pct",   # liberate — an execute, measured against the victim
	"status_stacks",       # spontaneous_combustion — spend a DoT for a burst
]


static func is_formula(name: String) -> bool:
	return name in FORMULAS


static func explain_unknown(name: String) -> String:
	return ("'%s' is not in SpellDamage.FORMULAS, so nothing computes it; the "
		+ "spell would resolve to zero damage") % name


## How many copies of `status` the unit is carrying.
##
## Stackable statuses append one entry per application — the non-stackable path
## refreshes and returns before it reaches the append — so the stack count is
## simply how many entries name it.
static func stacks_of(unit: Node, status: String) -> int:
	if unit == null or not "status_effects" in unit:
		return 0
	var n := 0
	for effect in unit.status_effects:
		if effect.get("status", "").to_lower() == status.to_lower():
			n += 1
	return n


## Resolve a spell's `damage` to a number.
##
## Accepts a plain number (the overwhelming majority) or a formula block:
##
##   "damage": 45
##   "damage": {"formula": "spellpower", "multiplier": 6}
##   "damage": {"formula": "target_max_hp_pct", "percent": 50}
##   "damage": {"formula": "status_stacks", "status": "Burning", "per_stack": 20}
##
## Pure: it reads state and returns a number. Consuming the status that fed a
## `status_stacks` roll is the caller's job, so that resolving damage twice —
## for a preview, for a log line — cannot spend the target's Burning twice.
static func resolve(spell: Dictionary, caster: Node, target: Node) -> int:
	var raw = spell.get("damage", null)
	if raw == null:
		return 0
	if raw is int or raw is float:
		return int(raw)
	if not (raw is Dictionary):
		push_warning("SpellDamage: spell '%s' has a %s in `damage`; expected a "
			% [spell.get("id", "?"), type_string(typeof(raw))]
			+ "number or a formula block")
		return 0

	var formula: String = raw.get("formula", "")
	match formula:
		"spellpower":
			if caster == null or not caster.has_method("get_spellpower"):
				return 0
			return maxi(0, int(caster.get_spellpower() * float(raw.get("multiplier", 1.0))))

		"target_max_hp_pct":
			if target == null or not "max_hp" in target:
				return 0
			return maxi(0, int(target.max_hp * float(raw.get("percent", 0)) / 100.0))

		"status_stacks":
			var status: String = raw.get("status", "")
			if status == "" or target == null:
				return 0
			return maxi(0, stacks_of(target, status) * int(raw.get("per_stack", 0)))

		_:
			push_warning("SpellDamage: spell '%s' — %s"
				% [spell.get("id", "?"), explain_unknown(formula)])
			return 0


## True when this spell's damage block spends a status to pay for itself, and
## the caller should remove it after the damage lands.
static func consumes_status(spell: Dictionary) -> String:
	var raw = spell.get("damage", null)
	if not (raw is Dictionary):
		return ""
	if raw.get("formula", "") != "status_stacks":
		return ""
	return raw.get("status", "") if bool(raw.get("consumes", false)) else ""
