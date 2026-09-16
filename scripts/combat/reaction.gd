class_name Reaction
## What a unit does when something happens on somebody else's turn.
##
## The game already had two reaction hooks and no reaction system. Movement
## reactions lived as hardcoded `if PerkSystem.has_perk(reactor, "...")`
## branches inside `_check_zoc_reactions` — First to Strike, Frost Warden and
## None Shall Pass, each written out in full. Being-hit reactions lived in
## `retaliation` blocks on statuses, which could deal flat damage, reflect a
## percentage or apply a status, but could not swing a weapon.
##
## Six active perks were waiting on the half that did not exist: Counterstrike,
## Stand in the Gap, Set for Charge, Kill Zone, Heavenly Counterflow and None
## Shall Pass. They are one mechanic — *when X happens near me, do Y* — with
## different triggers and different answers, so they are one vocabulary, read
## by the two hooks that already existed.
##
## A REACTION IS A STATUS. That is what makes the stances work: the perk
## applies a status lasting until your next turn, the status declares the
## reaction, and the hooks read whoever has one. Nothing needs to know which
## perk put it there, a dispel can take it away, and a monster can have the
## same trick without a perk at all.

## When a reaction fires.
const TRIGGERS: Array[String] = [
	"attacked_in_melee",   # someone strikes you at reach 1
	"enemy_enters_reach",  # an enemy moves into your threatened area
	"ally_threatened",     # an enemy moves within reach of an ally you guard
]

## What it does about it. A reaction may declare several.
const RESPONSES: Array[String] = [
	"attack",      # a free weapon attack against whoever triggered it
	"status",      # apply a status to them
	"auto_dodge",  # the triggering blow misses outright
	"reposition",  # step away afterwards, using the repositioning vocabulary
]

## How many times one reaction may fire before the reactor's next turn, when
## the status does not say. A stance that answered everything would end fights
## on its own.
const DEFAULT_MAX_PER_ROUND: int = 3


static func is_trigger(name: String) -> bool:
	return name in TRIGGERS


static func is_response(name: String) -> bool:
	return name in RESPONSES


static func explain_unknown_trigger(name: String) -> String:
	return ("'%s' is not in Reaction.TRIGGERS, so nothing fires it: the stance "
		+ "would be applied, last its turn and never answer anything") % name


static func explain_unknown_response(name: String) -> String:
	return ("'%s' is not in Reaction.RESPONSES, so the reaction fires and does "
		+ "nothing") % name


## The reaction a status declares, or {} if it declares none.
static func of(status_def: Dictionary) -> Dictionary:
	var spec: Dictionary = status_def.get("reaction", {})
	return spec if spec is Dictionary else {}


## How far this reaction reaches. `weapon` means the reactor's own attack
## range, which is what a Kill Zone is: everything you could have shot.
static func reach_of(spec: Dictionary, unit: Node) -> int:
	var declared = spec.get("reach", 1)
	if typeof(declared) == TYPE_STRING and str(declared) == "weapon":
		if unit != null and unit.has_method("get_attack_range"):
			return int(unit.get_attack_range())
		return 1
	return maxi(1, int(declared))


## Has this reaction already fired as often as it may this round?
##
## The budget lives on the status ENTRY rather than on the unit, so two stances
## do not share one allowance and a refreshed stance starts clean.
static func can_fire(spec: Dictionary, entry: Dictionary, against: Node) -> bool:
	var used: int = int(entry.get("_reactions_used", 0))
	var cap: int = int(spec.get("max_per_round", DEFAULT_MAX_PER_ROUND))
	if used >= cap:
		return false
	if bool(spec.get("once_per_attacker", false)) and against != null:
		var seen: Dictionary = entry.get("_reacted_to", {})
		if seen.has(against.get_instance_id()):
			return false
	return true


## Record that it fired.
static func spend(entry: Dictionary, against: Node) -> void:
	entry["_reactions_used"] = int(entry.get("_reactions_used", 0)) + 1
	if against != null:
		var seen: Dictionary = entry.get("_reacted_to", {})
		seen[against.get_instance_id()] = true
		entry["_reacted_to"] = seen


## Clear the per-round budget. Called when the reactor's own turn comes round
## again, which is what "until your next turn" means.
static func refresh(entry: Dictionary) -> void:
	entry["_reactions_used"] = 0
	entry["_reacted_to"] = {}
