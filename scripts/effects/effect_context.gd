class_name EffectContext
extends RefCounted
## Everything EffectResolver needs to know about WHERE a list of effects came
## from: who cast it, at whom, how strongly, and which save has been rolled.
##
## One context is made per use of a container (one spell cast, one status
## tick, one test) and handed to EffectResolver.resolve() together with the
## container's effect list. The effects themselves stay plain JSON
## dictionaries; anything that changes while they resolve (the save roll) is
## kept here instead, so the JSON is never edited.

## Who is acting. Its team decides who counts as an ally or an enemy.
var caster: Node = null
## The unit the container was aimed at (the default `to`).
var target: Node = null
## Every unit inside the container's area, for the *_in_area selectors.
var area_units: Array = []

## What kind of thing holds the effects ("spell", "status", "test" ...).
var container_kind: String = ""
## Its id ("fireball", "Burning" ...). Also names persistent damage entries.
var container_id: String = ""

## The spellpower bonus, as CombatManager._calculate_spell_bonus computes it
## today: the caster's spellpower plus 2 per level in each matching school.
## Read by {"base", "per_spellpower"} magnitudes and by scale per "spellpower".
var power: int = 0
## The spell's level; a heal passes it to clear_damage ({"heal": {min_level}}).
var level: int = 0
## The spell's school ("white", "fire" ...), lower case.
var school: String = ""

## Save rolls already made for this container, one per recipient, keyed by the
## recipient's instance id. Empty until the first effect with a `save` rolls.
## Every later effect with a `save` reads the same roll for that recipient, so
## a two-branch spell ("on_save": "fail" kills, "on_save": "pass" hurts) lands
## exactly one branch (spec §4.3). Use save_for() to read it.
var save_result: Dictionary = {}

## When set, `fortify` / `drain` / `set` / `multiply` register their holds under
## this source id (a status sets it to its own id, so the hold is released when
## the status ends). When empty those modes are refused, because a hold nobody
## owns would never be released.
var hold_source: String = ""


## The save roll already made against `unit`, or {} if none has been rolled.
## A roll is SaveSystem.roll()'s dictionary: {success, roll, total, dc, margin}.
func save_for(unit: Node) -> Dictionary:
	if unit == null:
		return {}
	return save_result.get(unit.get_instance_id(), {})


## A context for `caster` casting `spell` (a spells.json entry) at `target`,
## with `power` worked out the way spell damage works it out today.
static func for_spell(caster: Node, target: Node, spell_id: String, spell: Dictionary,
		area: Array = []) -> EffectContext:
	var ctx := EffectContext.new()
	ctx.caster = caster
	ctx.target = target
	ctx.area_units = area
	ctx.container_kind = "spell"
	ctx.container_id = spell_id
	ctx.level = int(spell.get("level", 0))
	var schools: Array = spell.get("schools", [])
	ctx.school = String(schools[0]).to_lower() if not schools.is_empty() else ""
	if caster != null and caster.has_method("get_spellpower"):
		ctx.power = CombatManager._calculate_spell_bonus(caster, spell)
	return ctx
