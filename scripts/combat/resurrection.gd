class_name Resurrection
## Bringing someone back, and the three different acts that phrase covers.
##
## The game had two revive paths and no system. `revive_unit()` only touched a
## unit that was still bleeding out; `_resolve_revive_ally()`, written for one
## perk, handled the dead as well and was reachable from nowhere else. Meanwhile
## `raise_dead`, `resurrect` and `breath_of_heaven` — 135, 225 and 225 mana —
## declared their intent in unread `special` keys and did nothing at all, so the
## game had no working resurrection at any tier.
##
## THREE ACTS, NOT ONE. They differ in what they undo, and conflating them is
## how a level 7 spell and a level 1 perk end up indistinguishable.
##
##   STABILISE — a unit is bleeding out and stops. Nothing is returned; they are
##     simply no longer on their way out. Cheap, and the right thing for a
##     battlefield medic.
##   REVIVE — a unit is dead ON THE FIELD and stands up again, at some fraction
##     of their health. This is the one that needs to cost a great deal, and the
##     one that a destroyed corpse refuses.
##   RAISE — a companion died in an earlier fight and was taken out of the party
##     entirely. Bringing them back is not a combat action at all; it belongs to
##     events, shrines and whatever else the world offers. CharacterSystem keeps
##     the record of the dead so that this has something to reach for.
##
## What the fiction cares about is the second and third. What the code cares
## about is that they are separate, because the checks differ: a stabilise asks
## only "are they still dying", a revive asks "is the body intact", and a raise
## asks "is there room in the party".

## The three acts, in ascending order of what they undo.
const TIERS: Array[String] = ["stabilise", "revive", "raise"]

## Scopes a resurrection effect may cover.
const SCOPES: Array[String] = ["single", "all_allies"]


static func is_tier(tier: String) -> bool:
	return tier in TIERS


static func is_scope(scope: String) -> bool:
	return scope in SCOPES


static func explain_unknown_tier(tier: String) -> String:
	return ("'%s' is not in Resurrection.TIERS, so nothing performs it; the "
		+ "spell would report success and raise nobody") % tier


## Can this unit be brought back where it lies?
##
## Returns {ok, reason}. The reason is worth carrying: "their body is destroyed"
## and "they are not dead" are different answers, and a player who casts a
## 225-mana spell deserves to be told which.
static func can_revive(unit: Node) -> Dictionary:
	if unit == null or not is_instance_valid(unit):
		return {"ok": false, "reason": "nobody there"}
	if not ("is_dead" in unit) and not ("is_bleeding_out" in unit):
		return {"ok": false, "reason": "that cannot be raised"}
	if not unit.is_dead and not unit.is_bleeding_out:
		return {"ok": false, "reason": "%s is not dead" % unit.unit_name}
	# Balefire and the funeral pyre leave nothing to raise. This is the only
	# hard refusal in the system, and it is what makes those spells worth their
	# cost against a party with a white mage.
	if "corpse_destroyed" in unit and unit.corpse_destroyed:
		return {"ok": false, "reason": "%s's body is destroyed" % unit.unit_name}
	return {"ok": true, "reason": ""}


## How much health someone comes back with.
##
## Always at least 1, because a resurrection that returns someone at zero is a
## resurrection that kills them again on the same frame.
static func hp_for(unit: Node, hp_pct: int) -> int:
	if unit == null or not "max_hp" in unit:
		return 1
	return clampi(int(unit.max_hp * hp_pct / 100.0), 1, unit.max_hp)


## Can this fallen companion be brought back into the party?
##
## `party_size` and `max_party` are passed in rather than read, so this stays
## testable without a live CharacterSystem and so the caller decides what
## counts as the party.
static func can_raise(fallen_index: int, fallen_count: int, party_size: int,
		max_party: int) -> Dictionary:
	if fallen_index < 0 or fallen_index >= fallen_count:
		return {"ok": false, "reason": "no such person among the dead"}
	if party_size >= max_party:
		return {"ok": false, "reason": "there is no room in the party"}
	return {"ok": true, "reason": ""}
