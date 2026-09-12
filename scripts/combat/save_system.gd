class_name SaveSystem
## The one way an effect is resisted.
##
## Before this, three unrelated mechanisms decided that question:
##
##   * CombatManager._perform_save_roll() — a flat 40% + 2% per point above 10,
##     with no dice, no DC, and no input at all from whoever was attacking. A
##     Constitution-12 target resisted everything in the game at 44%.
##   * statuses.json — `save_type` on 4 of 168 statuses, read by nothing.
##   * spells.json — `save_type` on 27 of 363 spells, read at two call sites.
##
## And perk text assumed a fourth thing that existed nowhere: "Constitution save
## at -20%", "Focus save DC 16". Neither a DC nor a modifier could be expressed,
## so that text was decoration.
##
## The model is `d20 + defender attribute` against
## `DC = 10 + attacker attribute + tier`. Both sides' stats matter, which is the
## point: a stronger caster is harder to resist, a tough target shrugs things
## off.
##
##     Con 12 vs Focus 12, normal    d20 + 12 >= 22    55%
##     Con 18 vs Focus 12, normal    d20 + 18 >= 22    85%
##     Con 12 vs Focus 20, normal    d20 + 12 >= 30    15%
##
## The DC uses the attacker's ATTRIBUTE, never spellpower. Spellpower reaches
## 25-40 once equipment and affinity land, so `10 + spellpower` would put every
## DC beyond d20 reach and nothing would ever be resisted. Both sides stay on
## the 8-20 attribute scale.
##
## Event rolls are deliberately NOT routed through here. An event tier DC is
## `best_party_stat + modifier` against `d20 + best_party_stat`, so the
## attribute cancels and the tier is a flat probability — intended there, wrong
## for a saving throw. A skill check and a saving throw are different questions
## that happen to share a die.


## How much harder than even the effect is to resist.
const TIERS: Dictionary = {
	"easy":   -4,
	"normal":  0,
	"hard":    4,
	"brutal":  8,
}

## Attributes a save or a DC may be built on.
const ATTRIBUTES: Array[String] = [
	"strength", "constitution", "finesse", "focus", "awareness", "charm", "luck",
]

## Every DC starts here, so an average attacker against an average defender is
## a coin flip rather than a formality.
const BASE_DC: int = 10

## One point of d20 is five percentage points. The bonuses already in the data
## are percentages, so they are divided by this to become roll points — which
## is why nothing needed retuning when the mechanic changed.
const PERCENT_PER_ROLL_POINT: float = 5.0


static func is_valid_save_type(save_type: String) -> bool:
	return save_type in ATTRIBUTES


## The number a defender must reach. `dc_stat` is the attacker's attribute:
## `focus` for spells and mental effects, `strength` for weapon and
## forced-movement ones. `modifier` carries text like "at -20%", which is -4.
static func dc_for(attacker: Node, dc_stat: String, tier: String = "normal",
		modifier: int = 0) -> int:
	if not is_valid_save_type(dc_stat):
		push_error("SaveSystem: '%s' is not an attribute, so no DC can be built from it"
			% dc_stat)
		return BASE_DC + modifier
	if not TIERS.has(tier):
		push_error("SaveSystem: unknown save tier '%s' — expected one of %s"
			% [tier, ", ".join(TIERS.keys())])
		tier = "normal"
	return BASE_DC + _attribute_of(attacker, dc_stat) + int(TIERS[tier]) + modifier


## The defender's chance to resist, as 0.0-1.0.
##
## Exposed separately from roll() so the odds can be asserted exactly rather
## than only sampled, and so UI can show a number without rolling for it.
static func success_chance(defender: Node, save_type: String, dc: int) -> float:
	var needed: int = dc - _attribute_of(defender, save_type) - _bonus_for(defender, save_type)
	# A natural 1 always fails and a natural 20 always succeeds, so every save
	# stays possible and none is ever certain. The event system uses the same
	# floor for its "almost impossible" tier.
	return clampf(float(21 - needed) / 20.0, 0.05, 0.95)


## Roll a save. Returns {success, roll, total, dc, margin} rather than a bool,
## because callers need the numbers to log and because perks react to the fact
## of a save — Steadfast Spirit grants resistance for passing one, which a bool
## throws away.
static func roll(defender: Node, save_type: String, dc: int) -> Dictionary:
	if not is_valid_save_type(save_type):
		push_error("SaveSystem: '%s' is not an attribute, so it cannot be saved with"
			% save_type)
	var die: int = randi() % 20 + 1
	var total: int = die + _attribute_of(defender, save_type) + _bonus_for(defender, save_type)
	var success: bool = die == 20 or (die != 1 and total >= dc)
	return {
		"success": success,
		"roll": die,
		"total": total,
		"dc": dc,
		"margin": total - dc,
	}


# ─── Internal ────────────────────────────────────────────────────────────────

static func _attribute_of(unit: Node, attribute: String) -> int:
	if unit == null or not "character_data" in unit:
		return 10
	return int(unit.character_data.get("attributes", {}).get(attribute, 10))


## Percentage-shaped resistances, converted to roll points.
static func _bonus_for(unit: Node, save_type: String) -> int:
	if unit == null:
		return 0
	var percent: float = 0.0

	# Booster Shot's "+25% resistance to the next status effect".
	if unit.has_method("_get_stat_modifier_bonus"):
		percent += float(unit._get_stat_modifier_bonus("save_bonus"))

	# Mental resistance is mental: Focus saves are the mental ones, and this
	# applied only to them before the rework too.
	if save_type == "focus" and "character_data" in unit:
		percent += float(unit.character_data.get("derived", {}).get("mental_resistance_pct", 0.0))

	return int(percent / PERCENT_PER_ROLL_POINT)
