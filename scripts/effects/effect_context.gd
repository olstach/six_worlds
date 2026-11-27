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
## A ground tile the container was aimed at, for ops placed at a position
## (summon, zone) when there is no unit there. NO_POS means "not set"; use
## position() to read the tile with the fallback to target's tile.
const NO_POS := Vector2i(-9999, -9999)
var target_pos: Vector2i = NO_POS
## Every unit inside the container's area, for the *_in_area selectors.
var area_units: Array = []

## What kind of thing holds the effects ("spell", "status", "test" ...).
var container_kind: String = ""
## Its id ("fireball", "Burning" ...). Also names persistent damage entries.
var container_id: String = ""

## The categories of the container that is writing (a status's `categories`).
## A `damage`-mode modify records them on its damaged_values entry as
## `source_categories`, so a later {"cleanse": {"category": c}} can match.
var source_categories: Array = []

## The spellpower bonus, as CombatManager._calculate_spell_bonus computes it
## today: the caster's spellpower plus 2 per level in each matching school.
## Read by {"base", "per_spellpower"} magnitudes and by scale per "spellpower".
var power: int = 0
## The spell's level; a heal passes it to clear_damage ({"heal": {min_level}}).
var level: int = 0
## The spell's FIRST school ("white", "fire" ...), lower case.
var school: String = ""
## Every school the spell is tagged with, lower case. A multi-school heal
## (White + Water) clears damage whose `cleared_by` names any of them. Empty
## means "just `school`"; use all_schools() to read it.
var schools: Array[String] = []

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

## The status entry (in unit.status_effects) whose effects these are, when a
## status is resolving its `while_active`, `periodic` or `triggers`; empty
## otherwise. Magnitudes read it: `stacks` multiplies them, and a scale per
## `turn_active` reads its `turns_active`.
var status_entry: Dictionary = {}

## In a status trigger that answers another unit (struck, hit, a reaction):
## that unit, the one `to: "source"` names and `source.<path>` borrows from.
var source: Node = null
## What happened, for a trigger: {"damage": n} is the blow or hit that fired
## it, read by a magnitude {"from": "event.damage"}.
var event: Dictionary = {}

## True for a status's own effects. The damage a status deals (a tick, a
## retaliation, an expiry) has never named a dealer, so it fires no one's
## "you hurt someone" or "someone hurt you" perks; that stays so here.
var anonymous_damage: bool = false
## True while a status's `periodic` damage ticks. The applier's damage-over-time
## bonuses then apply, as they always have to a tick: Fire Magic's
## burning_damage_pct and Fan the Flames to fire, Alchemy's poison_damage_pct
## to poison (CombatManager.status_tick_damage).
var dot_tick: bool = false


## The tile a position op acts on: target_pos if set, else the target unit's
## tile, else NO_POS (the caller must refuse that loudly).
func position() -> Vector2i:
	if target_pos != NO_POS:
		return target_pos
	if target != null and "grid_position" in target:
		return target.grid_position
	return NO_POS


## Every school of the container: `schools`, or [school] when only that was set.
func all_schools() -> Array[String]:
	if not schools.is_empty():
		return schools.duplicate()
	var only: Array[String] = []
	if school != "":
		only.append(school)
	return only


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
	var spell_schools: Array = spell.get("schools", [])
	ctx.school = String(spell_schools[0]).to_lower() if not spell_schools.is_empty() else ""
	# Keep them all: a heal tagged White + Water clears either school's damage.
	for each_school in spell_schools:
		ctx.schools.append(String(each_school).to_lower())
	if caster != null and caster.has_method("get_spellpower"):
		ctx.power = CombatManager._calculate_spell_bonus(caster, spell)
	return ctx
