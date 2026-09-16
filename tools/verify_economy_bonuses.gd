extends Node
## Headless verification for economy and crafting skill payouts.
##
## Run: godot --headless res://tools/verify_economy_bonuses.tscn
##
## The point of this phase was convergence, not new features: Trade already
## discounted prices, via a hand-rolled best-in-party loop and a linear constant
## that disagreed with the per-level table. These checks assert the table is now
## the single source, and that the numbers still come out sane.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 8


func _ready() -> void:
	_check_trade_discount_comes_from_the_table()
	_check_discount_uses_best_member()
	_check_discount_is_capped()
	_check_selling_pays_more_with_trade()
	_check_consumable_power_scales_potions()
	_check_repair_efficiency_cuts_scrap_cost()
	_check_alchemy_keeps_paying_past_level_five()
	_check_a_camp_activity_can_require_a_perk()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway"
			% [checks_run, EXPECTED_CHECKS])
		failures += 1
	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK (%d checks)" % checks_run)
		get_tree().quit(0)


func _fail(m: String) -> void:
	printerr("  FAIL: ", m)
	failures += 1


func _done() -> void:
	checks_run += 1


func _party(members: Array) -> void:
	CharacterSystem.party.clear()
	for skills in members:
		var c: Dictionary = CharacterSystem.create_blank_character()
		c["skills"] = skills
		CharacterSystem.party.append(c)
	CharacterSystem.update_party_derived_stats()


## The discount must track the per-level table, not a linear constant. The two
## disagreed: 5% per level gave Trade 5 a 25% discount where the table says 35%.
func _check_trade_discount_comes_from_the_table() -> void:
	var expected: float = PerkSystem.get_base_skill_bonuses_at_level(
		"trade", 5).get("party_buy_discount_pct", 0.0) / 100.0
	if expected <= 0.0:
		_fail("the trade table has no party_buy_discount_pct at level 5")
		_done()
		return
	_party([{"trade": 5}])
	var actual: float = ShopSystem._get_total_discount()
	if absf(actual - expected) > 0.001:
		_fail("Trade 5 discounts %.3f, table says %.3f" % [actual, expected])
	_done()


## Shopping is a party activity, so the best trader in the group sets the price
## — which is what the hand-rolled loop did before PartyBonuses existed.
func _check_discount_uses_best_member() -> void:
	_party([{"swords": 10}, {"trade": 10}])
	var with_trader: float = ShopSystem._get_total_discount()
	_party([{"swords": 10}])
	var without: float = ShopSystem._get_total_discount()
	if with_trader <= without:
		_fail("a Trade-10 companion did not improve prices (%.3f vs %.3f)"
			% [with_trader, without])
	_done()


func _check_discount_is_capped() -> void:
	_party([{"trade": 10, "persuasion": 10}])
	var discount: float = ShopSystem._get_total_discount()
	if discount > 0.50:
		_fail("total discount reached %.3f — the 50%% cap is not holding" % discount)
	_done()


func _check_selling_pays_more_with_trade() -> void:
	ShopSystem._current_shop = {}
	_party([{"swords": 10}])
	var plain: int = ShopSystem.get_sell_price("health_potion")
	_party([{"trade": 10}])
	var trained: int = ShopSystem.get_sell_price("health_potion")
	if trained <= plain:
		_fail("Trade 10 sold a potion for %d, untrained gets %d" % [trained, plain])
	_done()


## Alchemy makes a potion go further. This is per-character — the one drinking
## it — so the key carries no party_ prefix.
func _check_consumable_power_scales_potions() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	c["skills"] = {"alchemy": 10}
	CharacterSystem.update_derived_stats(c)
	var pct: float = c["derived"].get("consumable_power_pct", 0.0)
	if pct <= 0.0:
		_fail("Alchemy 10 gave consumable_power_pct %.1f" % pct)
	_done()


## Smithing makes repairs cheaper in scrap.
func _check_repair_efficiency_cuts_scrap_cost() -> void:
	var unskilled: Dictionary = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(unskilled)
	var smith: Dictionary = CharacterSystem.create_blank_character()
	smith["skills"] = {"smithing": 10}
	CharacterSystem.update_derived_stats(smith)

	var plain_cost: int = CampSystem.repair_scrap_cost(unskilled)
	var smith_cost: int = CampSystem.repair_scrap_cost(smith)
	if smith_cost >= plain_cost:
		_fail("a Smithing-10 repair costs %d scrap, unskilled costs %d"
			% [smith_cost, plain_cost])
	if smith_cost < 1:
		_fail("repair cost fell to %d — it must never reach zero" % smith_cost)
	_done()


## Alchemy's potion bonus came from a six-entry table indexed by skill level,
## written when skills capped at 5. The out-of-range branch returned 0.0, so
## levels 6 through 10 paid nothing and levelling past 5 made potions worse.
func _check_alchemy_keeps_paying_past_level_five() -> void:
	# Go through the consumer, not through derived. Reading the stat directly
	# would pass even with the old cliff restored, because the cliff was in
	# _get_alchemy_bonus() and not in the data.
	var at_five: float = 0.0
	for level in [1, 3, 5, 6, 8, 10]:
		var c: Dictionary = CharacterSystem.create_blank_character()
		c["skills"] = {"alchemy": level}
		CharacterSystem.update_derived_stats(c)
		var unit := CombatUnit.new()
		unit.character_data = c
		add_child(unit)
		var pct: float = CombatManager._get_alchemy_bonus(unit)
		unit.free()
		if level == 5:
			at_five = pct
		if level > 5 and pct < at_five:
			_fail("Alchemy %d gives %.1f%% where Alchemy 5 gives %.1f%% — the "
				% [level, pct, at_five] + "curve still falls off past level 5")
		if level == 10 and pct <= 0.0:
			_fail("Alchemy 10 gives no consumable bonus at all")
	_done()


## Brew Coatings is the first camp activity gated on a PERK as well as a skill,
## because Applied Toxicology promised craftable coatings and nothing in the
## game could craft one. A `perk_req` nothing reads would hand the recipe to
## everybody.
func _check_a_camp_activity_can_require_a_perk() -> void:
	var alchemist: Dictionary = CharacterSystem.create_blank_character()
	alchemist["skills"] = {"alchemy": 9}

	var without: Array = CampSystem.get_available_activities([alchemist], 3, true)
	var has_it := func(list: Array) -> bool:
		for activity in list:
			if str(activity.get("id", "")) == "brew_coatings":
				return true
		return false
	if has_it.call(without):
		_fail("Brew Coatings was offered to an alchemist without Applied "
			+ "Toxicology — the perk requirement is not being read")

	alchemist["perks"] = ["applied_toxicology"]
	var with_perk: Array = CampSystem.get_available_activities([alchemist], 3, true)
	if not has_it.call(with_perk):
		_fail("Brew Coatings was withheld from an alchemist who has Applied "
			+ "Toxicology")

	# The skill still matters: the perk alone is not enough.
	var untrained: Dictionary = CharacterSystem.create_blank_character()
	untrained["perks"] = ["applied_toxicology"]
	if has_it.call(CampSystem.get_available_activities([untrained], 3, true)):
		_fail("Brew Coatings was offered to someone with no Alchemy at all")
	_done()
