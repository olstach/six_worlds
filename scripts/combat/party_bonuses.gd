class_name PartyBonuses
## Skill payouts that one party member's training gives to everyone.
##
## Some skills are useful to the person who has them; others are useful to the
## group. A medic's training is the second kind. Those payouts are named with a
## `party_` prefix in the per-level tables, and this is what spreads them.
##
## BEST MEMBER, NOT SUM. Four medics are not four times one medic — that is both
## absurd and off-theme. Taking the best also matches the rule the game already
## uses for party skill checks ("any party member meeting a requirement enables
## the choice"), and it matches map_manager._get_best_party_discovery_bonus(),
## which reached for the same rule by hand before this existed.
##
## It has a known cost, recorded in TODO: the party's second-best Medicine
## contributes nothing, so levelling it is wasted XP. Summing has the opposite
## problem. Neither pure rule is right and the question is still open.
##
## No ordering problem arises here. These read raw SKILL LEVELS, never another
## character's `derived`, so computing A's stats never waits on B's.


## The best payout any party member's skills produce for one `party_` stat.
static func best(stat_key: String) -> float:
	if not CharacterSystem:
		return 0.0
	var best_value: float = 0.0
	for member in CharacterSystem.get_party():
		best_value = maxf(best_value, for_character(member, stat_key))
	return best_value


## What one character's own skills contribute toward a stat. Exposed separately
## so the "best" can be explained in the UI — whose training is paying for this.
static func for_character(character: Dictionary, stat_key: String) -> float:
	if not PerkSystem or not CharacterSystem:
		return 0.0
	var total: float = 0.0
	for skill_id in character.get("skills", {}):
		var level: int = CharacterSystem.get_effective_skill_level(character, skill_id)
		if level <= 0:
			continue
		var bonus: Dictionary = PerkSystem.get_base_skill_bonuses_at_level(skill_id, level)
		total = maxf(total, float(bonus.get(stat_key, 0.0)))
	return total


## Which party member is currently supplying a stat, for UI that wants to say
## so. Returns {} when nobody does.
static func best_source(stat_key: String) -> Dictionary:
	if not CharacterSystem:
		return {}
	var winner: Dictionary = {}
	var best_value: float = 0.0
	for member in CharacterSystem.get_party():
		var value: float = for_character(member, stat_key)
		if value > best_value:
			best_value = value
			winner = member
	return winner
