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
const EXPECTED_CHECKS: int = 38


func _ready() -> void:
	_check_trade_discount_comes_from_the_table()
	_check_discount_uses_best_member()
	_check_discount_is_capped()
	_check_selling_pays_more_with_trade()
	_check_consumable_power_scales_potions()
	_check_repair_efficiency_cuts_scrap_cost()
	_check_alchemy_keeps_paying_past_level_five()
	_check_a_camp_activity_can_require_a_perk()

	# The last of the stat keys nothing read, and the trait promises kept in a
	# `todo` field.
	_check_crafting_yield_pays_for_coatings()
	_check_loot_quality_widens_the_drop()
	_check_an_insatiable_eats_more()
	_check_an_insatiable_sleeps_worse()

	# The overworld perks: five of the seven that were data with no consumer.
	_check_foraging_reads_the_ground()
	_check_a_forager_finds_more()
	_check_scouting_ahead_reaches_further()
	_check_a_lesson_teaches_something_castable()
	_check_reinforcing_improves_one_instance()
	_check_a_sermon_stacks_twice_and_no_more()

	# Training prices: the exchange rate, the escalation and the cap.
	_check_skill_prices_track_the_exchange_rate()
	_check_the_skill_table_reaches_every_trainer_cap()
	_check_an_attribute_costs_more_the_higher_it_is()
	_check_lessons_escalate_one_then_two_and_a_half_then_five()
	_check_a_trainer_stops_after_three_lessons()
	_check_the_allowance_is_per_character_and_per_trainer()
	_check_the_ledger_survives_a_save()

	# The rack: a trader restocks on a cadence, not on a visit.
	_check_a_rack_is_the_same_rack_on_the_next_visit()
	_check_buying_takes_it_off_the_rack()
	_check_the_rack_refills_after_a_week()
	_check_a_racked_item_is_not_binned_on_close()

	# The purse, barter, and what a death takes with it.
	_check_a_shop_pays_only_what_it_has()
	_check_a_town_outbids_a_teahouse()
	_check_buying_puts_money_back_in_the_till()
	_check_barter_settles_in_goods_before_gold()
	_check_a_shortfall_needs_confirming()
	_check_a_new_life_keeps_nothing_of_the_old_world()

	# The cap is a property of the town now, not of the shop template.
	_check_a_village_caps_a_master()
	_check_a_capital_teaches_further_than_a_town()
	_check_a_roadside_shop_is_capped_only_by_its_own_skill()

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


## `crafting_yield_pct` is Alchemy's, and Brew Coatings is the one camp activity
## Alchemy owns — so this is the consumer it waited for.
func _check_crafting_yield_pays_for_coatings() -> void:
	var novice: Dictionary = CharacterSystem.create_blank_character()
	novice["skills"] = {"alchemy": 1}
	novice["perks"] = ["applied_toxicology"]
	CharacterSystem.update_derived_stats(novice)
	var master: Dictionary = CharacterSystem.create_blank_character()
	master["skills"] = {"alchemy": 10}
	master["perks"] = ["applied_toxicology"]
	CharacterSystem.update_derived_stats(master)

	if float(master.derived.get("crafting_yield_pct", 0.0)) <= 0.0:
		_fail("Alchemy 10 produced no crafting_yield_pct at all")

	var novice_total := 0
	var master_total := 0
	for _run in 30:
		GameState.herbs = 99
		novice_total += _brew(novice)
		GameState.herbs = 99
		master_total += _brew(master)
	if novice_total == 0 or master_total == 0:
		_fail("brewing produced nothing (novice %d, master %d)"
			% [novice_total, master_total])
	elif master_total <= novice_total:
		_fail("thirty brews yielded %d coatings for a master and %d for a "
			% [master_total, novice_total] + "novice")
	_done()


## How many coatings one Brew Coatings produced.
func _brew(performer: Dictionary) -> int:
	var before: int = ItemSystem.get_inventory_count("poison_oil") \
		+ ItemSystem.get_inventory_count("paralyzing_oil") \
		+ ItemSystem.get_inventory_count("whetstone_oil") \
		+ ItemSystem.get_inventory_count("warding_oil") \
		+ ItemSystem.get_inventory_count("void_oil")
	CampSystem.execute_activity("brew_coatings", performer, [performer])
	var after: int = ItemSystem.get_inventory_count("poison_oil") \
		+ ItemSystem.get_inventory_count("paralyzing_oil") \
		+ ItemSystem.get_inventory_count("whetstone_oil") \
		+ ItemSystem.get_inventory_count("warding_oil") \
		+ ItemSystem.get_inventory_count("void_oil")
	return after - before


## The loot drop fraction was `best_thievery * 0.03`, a magic number that meant
## what the Thievery table's `loot_quality_pct` says and disagreed with it.
func _check_loot_quality_widens_the_drop() -> void:
	var thief: Dictionary = CharacterSystem.create_blank_character()
	thief["skills"] = {"thievery": 10}
	CharacterSystem.update_derived_stats(thief)
	if float(thief.derived.get("loot_quality_pct", 0.0)) <= 0.0:
		_fail("Thievery 10 produced no loot_quality_pct at all")
	var plain: Dictionary = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(plain)
	if float(plain.derived.get("loot_quality_pct", 0.0)) != 0.0:
		_fail("an untrained character has loot_quality_pct %.0f"
			% float(plain.derived.get("loot_quality_pct", 0.0)))
	_done()


func _check_an_insatiable_eats_more() -> void:
	var ordinary: Dictionary = CharacterSystem.create_blank_character()
	var hungry: Dictionary = CharacterSystem.create_blank_character()
	hungry["traits"] = ["insatiable"]
	var plain_mult: float = TraitSystem.food_multiplier(ordinary)
	var hungry_mult: float = TraitSystem.food_multiplier(hungry)
	if not is_equal_approx(plain_mult, 1.0):
		_fail("an ordinary character eats %.2f shares" % plain_mult)
	if hungry_mult <= plain_mult:
		_fail("an Insatiable eats %.2f shares where an ordinary character eats "
			% hungry_mult + "%.2f" % plain_mult)
	_done()


func _check_an_insatiable_sleeps_worse() -> void:
	var ordinary: Dictionary = CharacterSystem.create_blank_character()
	var hungry: Dictionary = CharacterSystem.create_blank_character()
	hungry["traits"] = ["insatiable"]
	var plain_rest: float = TraitSystem.rest_recovery_multiplier(ordinary)
	var hungry_rest: float = TraitSystem.rest_recovery_multiplier(hungry)
	if not is_equal_approx(plain_rest, 1.0):
		_fail("an ordinary character recovers %.2f of a rest" % plain_rest)
	if hungry_rest >= plain_rest:
		_fail("an Insatiable recovers %.2f of a rest where an ordinary "
			% hungry_rest + "character recovers %.2f" % plain_rest)
	_done()


## The camp's forage gave herbs and food wherever you stood — a mountainside
## yielded the same as a forest — while the perk promised "food in forests,
## herbs in meadows, minerals in mountains" and was read by nothing.
func _check_foraging_reads_the_ground() -> void:
	var forager: Dictionary = CharacterSystem.create_blank_character()
	forager["skills"] = {"logistics": 3}
	CharacterSystem.update_derived_stats(forager)

	var forest: Dictionary = _forage_on(forager, MapManager.Terrain.FOREST)
	var mountain: Dictionary = _forage_on(forager, MapManager.Terrain.MOUNTAINS)
	if int(forest.get("food", 0)) <= 0:
		_fail("a forest yielded no food")
	if int(mountain.get("scrap", 0)) <= 0:
		_fail("a mountainside yielded no minerals")
	if int(mountain.get("food", 0)) >= int(forest.get("food", 0)):
		_fail("a mountainside yielded %d food and a forest %d"
			% [int(mountain.get("food", 0)), int(forest.get("food", 0))])
	_done()


## What one forage on `terrain` actually added to the stores.
func _forage_on(performer: Dictionary, terrain: int) -> Dictionary:
	MapManager.tiles[MapManager.party_position] = terrain
	var before := {"food": GameState.food, "herbs": GameState.herbs,
		"scrap": GameState.scrap, "reagents": GameState.reagents}
	CampSystem.execute_activity("forage", performer, [performer])
	return {
		"food": GameState.food - before.food,
		"herbs": GameState.herbs - before.herbs,
		"scrap": GameState.scrap - before.scrap,
		"reagents": GameState.reagents - before.reagents,
	}


func _check_a_forager_finds_more() -> void:
	var plain: Dictionary = CharacterSystem.create_blank_character()
	plain["skills"] = {"logistics": 3}
	CharacterSystem.update_derived_stats(plain)
	var trained: Dictionary = CharacterSystem.create_blank_character()
	trained["skills"] = {"logistics": 3}
	trained["perks"] = ["forage"]
	CharacterSystem.update_derived_stats(trained)

	var plain_total := 0
	var trained_total := 0
	for _run in 5:
		var a: Dictionary = _forage_on(plain, MapManager.Terrain.FOREST)
		var b: Dictionary = _forage_on(trained, MapManager.Terrain.FOREST)
		for key in a:
			plain_total += int(a[key])
			trained_total += int(b[key])
	if plain_total == 0:
		_fail("an untrained forager found nothing at all in five forests")
	if trained_total <= plain_total:
		_fail("a trained forager found %d where an untrained one found %d"
			% [trained_total, plain_total])

	# And somebody trained finds something even on bare ground.
	var barren: Dictionary = _forage_on(trained, MapManager.Terrain.BRIDGE)
	var barren_total := 0
	for key in barren:
		barren_total += int(barren[key])
	if barren_total <= 0:
		_fail("a trained forager found nothing on ground that yields nothing — "
			+ "knowing how to look is the perk")
	_done()


func _check_scouting_ahead_reaches_further() -> void:
	var scout: Dictionary = CharacterSystem.create_blank_character()
	scout["skills"] = {"logistics": 6}
	scout["perks"] = ["scout_ahead"]
	CharacterSystem.update_derived_stats(scout)

	# The ordinary watch reveals four tiles; this reads the country.
	var far := MapManager.party_position + Vector2i(7, 0)
	MapManager.visited_tiles.erase(far)
	CampSystem.execute_activity("scout", scout, [scout])
	var after_watch: bool = MapManager.visited_tiles.has(far)
	CampSystem.execute_activity("scout_ahead", scout, [scout])
	if not MapManager.visited_tiles.has(far):
		_fail("Scout Ahead did not reveal ground seven tiles out")
	if after_watch:
		_fail("the ordinary watch already revealed it, so this proves nothing")
	_done()


func _check_a_lesson_teaches_something_castable() -> void:
	var teacher: Dictionary = CharacterSystem.create_blank_character()
	teacher["skills"] = {"learning": 5, "fire_magic": 5, "sorcery": 5}
	teacher["perks"] = ["guided_practice"]
	teacher["known_spells"] = ["firebolt"]
	CharacterSystem.update_derived_stats(teacher)

	var able: Dictionary = CharacterSystem.create_blank_character()
	able["name"] = "Able"
	able["skills"] = {"fire_magic": 5}
	able["known_spells"] = []
	CharacterSystem.update_derived_stats(able)

	var result: Dictionary = CampSystem.execute_activity("guided_practice",
		teacher, [teacher, able])
	if not bool(result.get("ok", false)):
		_fail("guided_practice failed: %s" % str(result.get("message", "?")))
	elif not able["known_spells"].has("firebolt"):
		_fail("the student learned nothing: %s" % str(able["known_spells"]))

	# A second lesson to the same student teaches nothing new: they already
	# know it, and the teacher knows nothing else.
	var before: int = able["known_spells"].size()
	CampSystem.execute_activity("guided_practice", teacher, [teacher, able])
	if able["known_spells"].size() != before:
		_fail("the same spell was taught twice — the student already knew it")

	# Somebody who cannot work the school learns nothing from the same lesson.
	var unable: Dictionary = CharacterSystem.create_blank_character()
	unable["name"] = "Unable"
	unable["skills"] = {}
	unable["known_spells"] = []
	CharacterSystem.update_derived_stats(unable)
	var second: Dictionary = CampSystem.execute_activity("guided_practice",
		teacher, [teacher, unable])
	if bool(second.get("ok", false)) and unable["known_spells"].has("firebolt"):
		_fail("a spell was taught to somebody who cannot work its school")
	_done()


## Permanently, and to ONE piece: improving the shared definition would improve
## every sword of that make in the world.
func _check_reinforcing_improves_one_instance() -> void:
	var smith: Dictionary = CharacterSystem.create_blank_character()
	smith["skills"] = {"smithing": 5}
	smith["perks"] = ["reinforce"]
	CharacterSystem.update_derived_stats(smith)
	ItemSystem.add_to_inventory("iron_sword", 1)
	ItemSystem.equip_item(smith, "iron_sword", "weapon_main")

	var before_id: String = ItemSystem.get_equipped_item(smith, "weapon_main")
	if before_id == "":
		_fail("the probe smith could not equip a sword")
		_done()
		return
	var before_damage: int = int(ItemSystem.get_item(before_id).get("stats", {}).get("damage", 0))
	GameState.scrap = 99

	var result: Dictionary = CampSystem.execute_activity("reinforce", smith, [smith])
	if not bool(result.get("ok", false)):
		_fail("reinforce failed: %s" % str(result.get("message", "?")))
		_done()
		return
	var after_id: String = ItemSystem.get_equipped_item(smith, "weapon_main")
	var after_damage: int = int(ItemSystem.get_item(after_id).get("stats", {}).get("damage", 0))
	if after_id == before_id:
		_fail("the equipped item was changed in place rather than instanced")
	if after_damage <= before_damage:
		_fail("reinforcing left the damage at %d (was %d)"
			% [after_damage, before_damage])
	# The definition everybody else's sword comes from is untouched.
	if int(ItemSystem.get_item("iron_sword").get("stats", {}).get("damage", 0)) != before_damage:
		_fail("every iron sword in the world was reinforced")
	_done()


func _check_a_sermon_stacks_twice_and_no_more() -> void:
	var speaker: Dictionary = CharacterSystem.create_blank_character()
	speaker["perks"] = ["inspiring_sermon"]
	CharacterSystem.update_derived_stats(speaker)
	GameState.set_flag("sermon_stacks", 0)
	GameState.set_flag("sermon_skill_bonus", 0)
	GameState.active_map_buffs.clear()

	var first: Dictionary = CampSystem.execute_activity("inspiring_sermon", speaker, [speaker])
	var second: Dictionary = CampSystem.execute_activity("inspiring_sermon", speaker, [speaker])
	var third: Dictionary = CampSystem.execute_activity("inspiring_sermon", speaker, [speaker])
	if not bool(first.get("ok", false)) or not bool(second.get("ok", false)):
		_fail("the first two sermons did not both take")
	if bool(third.get("ok", false)):
		_fail("a third sermon took, and the perk says twice")
	if GameState.active_map_buffs.is_empty():
		_fail("the sermon left no buff for the next fight")
	# And the skill bonus is spent by the next check rather than lingering.
	var bonus_before: int = int(GameState.flags.get("sermon_skill_bonus", 0))
	if bonus_before <= 0:
		_fail("the sermon promised a skill-check bonus and stored none")
	EventManager.get_roll_bonus({"skill": "persuasion", "difficulty": "medium"})
	if int(GameState.flags.get("sermon_skill_bonus", 0)) != 0:
		_fail("the sermon's skill bonus was not spent by the next check")
	GameState.active_map_buffs.clear()
	_done()


# ============================================================================
# TRAINING PRICES
#
# Gold bought progression at a rate that fell as the character grew: attributes
# were a flat 200 against an XP cost of (value - 9) * 3, so the trainer was
# 66.7 gold/XP at attribute 10 and 3.2 at attribute 30. These checks pin the
# rate, the escalation and the cap so a later tuning pass cannot quietly undo
# any of the three. See docs/plans/ECONOMY_FLOWS.md.
# ============================================================================

## A shop with no price modifier and no discount, so a price is the bare
## calculation. Returns the character the caller should train.
func _lone_trainee(shop_id: String) -> Dictionary:
	_party([{}])
	ShopSystem._current_shop = {"id": shop_id, "price_modifier": 1.0}
	return CharacterSystem.party[0]


## The gold table and the XP table are the same table. The hand-tuned first
## five levels are a discount that converges on the rate (10, 15, 16.7, 17.9,
## 17.9 gold/XP); levels 6-10 were derived from it and should sit on it exactly.
## Asserting both halves separately is the honest version — a single tolerance
## wide enough for level 1 would not catch anything.
func _check_skill_prices_track_the_exchange_rate() -> void:
	var c: Dictionary = _lone_trainee("rate_probe")
	var rate := float(ShopSystem.GOLD_PER_XP)

	# Levels 1-5: at or below the rate, and never getting cheaper per XP.
	var previous := 0.0
	for level in range(0, 5):
		var xp: int = CharacterSystem.SKILL_COSTS[level + 1]
		var actual: float = float(ShopSystem.get_skill_training_cost(level, c)) / float(xp)
		if actual > rate + 0.5:
			_fail("skill ->%d prices at %.1f gold/XP, above the %d rate"
				% [level + 1, actual, ShopSystem.GOLD_PER_XP])
		if actual < previous - 0.01:
			_fail("skill ->%d prices at %.1f gold/XP, cheaper than ->%d at %.1f"
				% [level + 1, actual, level, previous])
		previous = actual

	# Levels 6-10: derived from the rate, so exact.
	for level in range(5, CharacterSystem.SKILL_MAX_LEVEL):
		var xp2: int = CharacterSystem.SKILL_COSTS[level + 1]
		var expected: int = xp2 * ShopSystem.GOLD_PER_XP
		var gold: int = ShopSystem.get_skill_training_cost(level, c)
		if gold != expected:
			_fail("skill ->%d costs %d, the rate says %d" % [level + 1, gold, expected])
	_done()


## weapon_master advertises max_skill_level 7 and the price table stopped at 5,
## so get_skill_training_cost returned 0 and the purchase refused. Every cap a
## shop advertises must be reachable.
func _check_the_skill_table_reaches_every_trainer_cap() -> void:
	var c: Dictionary = _lone_trainee("cap_probe")
	var worst: int = 0
	for shop_id in ShopSystem.get_shop_ids():
		var training: Dictionary = ShopSystem.get_shop(shop_id).get("training", {})
		if training.get("skills", []).is_empty():
			continue
		worst = maxi(worst, int(training.get("max_skill_level",
			CharacterSystem.SKILL_MAX_LEVEL)))
	# Priced by the level being left, so reaching level N reads index N-1.
	if ShopSystem.get_skill_training_cost(worst - 1, c) <= 0:
		_fail("a trainer advertises max_skill_level %d but level %d has no price"
			% [worst, worst])
	_done()


## The point of the rewrite: a point of Strength costs more at 20 than at 10,
## because that is what it costs in XP.
func _check_an_attribute_costs_more_the_higher_it_is() -> void:
	var c: Dictionary = _lone_trainee("attr_probe")
	c["attributes"]["strength"] = 10
	var cheap: int = ShopSystem.get_attribute_training_cost(c, "strength")
	c["attributes"]["strength"] = 20
	var dear: int = ShopSystem.get_attribute_training_cost(c, "strength")
	if dear <= cheap:
		_fail("strength at 20 costs %d, at 10 costs %d — should be dearer" % [dear, cheap])
	var xp: int = CharacterSystem.calculate_attribute_cost(20, 1)
	var expected: int = xp * ShopSystem.GOLD_PER_XP
	if dear != expected:
		_fail("strength at 20 costs %d, the XP cost at the rate is %d" % [dear, expected])
	_done()


## Each lesson from one trainer costs more than the last: 1x, 2.5x, 5x.
func _check_lessons_escalate_one_then_two_and_a_half_then_five() -> void:
	var c: Dictionary = _lone_trainee("steps_probe")
	var first: int = ShopSystem.get_skill_training_cost(2, c)
	ShopSystem._record_training_purchase(c)
	var second: int = ShopSystem.get_skill_training_cost(2, c)
	ShopSystem._record_training_purchase(c)
	var third: int = ShopSystem.get_skill_training_cost(2, c)
	if second != int(float(first) * 2.5):
		_fail("second lesson costs %d, expected %d" % [second, int(float(first) * 2.5)])
	if third != first * 5:
		_fail("third lesson costs %d, expected %d" % [third, first * 5])
	_done()


## Three lessons and the trainer is done, whatever kind they were: the
## allowance is shared, so two skills and an attribute exhaust it.
func _check_a_trainer_stops_after_three_lessons() -> void:
	var c: Dictionary = _lone_trainee("cap_three")
	ShopSystem._current_shop["training"] = {
		"skills": ["swords"], "attributes": ["strength"], "max_skill_level": 10
	}
	GameState.gold = 1000000
	var bought: int = 0
	for attempt in range(5):
		var r: Dictionary = ShopSystem.buy_skill_training(c, "swords")
		if r.get("success", false):
			bought += 1
	if bought != ShopSystem.TRAINING_PURCHASE_CAP:
		_fail("trainer sold %d lessons, cap is %d" % [bought, ShopSystem.TRAINING_PURCHASE_CAP])
	# And the shared allowance means the attribute is refused too.
	if ShopSystem.buy_attribute_training(c, "strength").get("success", false):
		_fail("an exhausted trainer still sold an attribute point")
	_done()


## One character using up a trainer must not use it up for the rest of the
## party, and a second trainer must start fresh.
func _check_the_allowance_is_per_character_and_per_trainer() -> void:
	_party([{}, {}])
	ShopSystem._current_shop = {"id": "shop_a", "price_modifier": 1.0}
	var first: Dictionary = CharacterSystem.party[0]
	var second: Dictionary = CharacterSystem.party[1]
	for i in range(ShopSystem.TRAINING_PURCHASE_CAP):
		ShopSystem._record_training_purchase(first)
	if ShopSystem.get_training_lessons_left(first) != 0:
		_fail("the exhausted character still has lessons left here")
	if ShopSystem.get_training_lessons_left(second) != ShopSystem.TRAINING_PURCHASE_CAP:
		_fail("one character's lessons were charged to another")
	ShopSystem._current_shop = {"id": "shop_b", "price_modifier": 1.0}
	if ShopSystem.get_training_lessons_left(first) != ShopSystem.TRAINING_PURCHASE_CAP:
		_fail("a different trainer inherited the first trainer's ledger")
	_done()


## The ledger is worthless if reloading refills every trainer in the world.
func _check_the_ledger_survives_a_save() -> void:
	var c: Dictionary = _lone_trainee("save_probe")
	ShopSystem._record_training_purchase(c)
	var restored: Dictionary = CharacterSystem.get_save_data()["party"][0]
	if int(restored.get("training_purchases", {}).get("save_probe", 0)) != 1:
		_fail("the training ledger did not survive get_save_data")
	_done()


# ============================================================================
# THE RACK
#
# `get_shop` hands back a deep copy of the template and `open_shop` rolled a
# fresh procedural rack into it, so leaving and re-entering rerolled the
# weapons and a purchase depleted nothing that outlived the visit. That makes
# the rack infinite, and it makes regional material selection pointless —
# you could reroll until the smith offered what you wanted.
# ============================================================================

## A shop standing on a map object, with one procedural weapon slot.
func _open_rack_shop(object_id: String) -> void:
	ShopSystem._current_shop = {
		"id": "rack_probe",
		"price_modifier": 1.0,
		"_object_id": object_id,
		"items": {},
		"procedural_slots": [{"category": "weapon", "rarity": "common", "count": 2}]
	}
	ShopSystem._generate_procedural_stock()


## Walking out and back in must show the same weapons, not new ones.
func _check_a_rack_is_the_same_rack_on_the_next_visit() -> void:
	GameState.shop_stock.clear()
	_open_rack_shop("obj_same")
	var first: Array = ShopSystem._current_shop["items"].keys()
	first.sort()
	_open_rack_shop("obj_same")
	var second: Array = ShopSystem._current_shop["items"].keys()
	second.sort()
	if first.is_empty():
		_fail("the rack generated nothing, so the check proves nothing")
	elif first != second:
		_fail("revisiting rerolled the rack: %s then %s" % [first, second])
	_done()


## And what was bought is gone when you come back.
func _check_buying_takes_it_off_the_rack() -> void:
	GameState.shop_stock.clear()
	_open_rack_shop("obj_buy")
	var sold: String = str(ShopSystem._current_shop["items"].keys()[0])
	GameState.gold = 1000000
	if not ShopSystem.buy_item(sold).get("success", false):
		_fail("could not buy from the rack to test depletion")
		_done()
		return
	_open_rack_shop("obj_buy")
	if sold in ShopSystem._current_shop["items"]:
		_fail("a sold item was back on the rack on the next visit")
	_done()


## After RESTOCK_DAYS the rack fills back up to its slot count — and the
## unsold item is still hanging there rather than being swept away.
func _check_the_rack_refills_after_a_week() -> void:
	GameState.shop_stock.clear()
	_open_rack_shop("obj_refill")
	var kept: String = str(ShopSystem._current_shop["items"].keys()[1])
	var sold: String = str(ShopSystem._current_shop["items"].keys()[0])
	GameState.gold = 1000000
	ShopSystem.buy_item(sold)

	GameState.shop_stock["obj_refill"]["day"] = \
		GameState.current_day - ShopSystem.RESTOCK_DAYS
	_open_rack_shop("obj_refill")
	var now: Dictionary = ShopSystem._current_shop["items"]
	if now.size() != 2:
		_fail("a restocked rack holds %d of its 2 slots" % now.size())
	if not kept in now:
		_fail("the restock swept away stock nobody had bought")
	_done()


## close_shop bins generated items nobody owns. Now that a rack outlives the
## visit, binning one leaves the rack full of ids resolving to nothing.
func _check_a_racked_item_is_not_binned_on_close() -> void:
	GameState.shop_stock.clear()
	_open_rack_shop("obj_close")
	var racked: String = str(ShopSystem._current_shop["items"].keys()[0])
	ShopSystem.close_shop()
	if not ItemSystem.item_exists(racked):
		_fail("closing the shop binned an item still on its rack")
	_done()


# ============================================================================
# THE PURSE, BARTER, AND REINCARNATION
# ============================================================================

func _open_purse_shop(object_id: String, shop_type: String) -> void:
	ShopSystem._current_shop = {
		"id": "purse_probe", "type": shop_type, "price_modifier": 1.0,
		"_object_id": object_id, "items": {}, "buys_items": true
	}


## A shop hands over what is in the till and no more, and says what it could
## not cover rather than quietly paying full price.
func _check_a_shop_pays_only_what_it_has() -> void:
	GameState.shop_purses.clear()
	_open_purse_shop("obj_poor", "teahouse")
	var item_id: String = ItemSystem.generate_weapon("", "rare", "", "", "animal")
	if item_id == "":
		_fail("could not generate an item to sell")
		_done()
		return
	ItemSystem.add_to_inventory(item_id)
	GameState.shop_purses["obj_poor"] = {"gold": 10, "day": GameState.current_day}
	var asking: int = ShopSystem.get_sell_price(item_id)
	var before: int = GameState.gold
	var r: Dictionary = ShopSystem.sell_item(item_id)
	if int(r.get("price", 0)) != 10:
		_fail("a till holding 10 paid %d" % int(r.get("price", 0)))
	if GameState.gold - before != 10:
		_fail("the player received %d from a till of 10" % (GameState.gold - before))
	if int(r.get("shortfall", -1)) != asking - 10:
		_fail("shortfall reported %d, expected %d" % [int(r.get("shortfall", -1)), asking - 10])
	if ShopSystem.get_shop_purse() != 0:
		_fail("the till still holds %d after paying out" % ShopSystem.get_shop_purse())
	_done()


## Where you sell should matter: a town brokers what a teahouse cannot.
func _check_a_town_outbids_a_teahouse() -> void:
	GameState.shop_purses.clear()
	_open_purse_shop("obj_town", "town")
	var rich: int = ShopSystem.get_shop_purse()
	_open_purse_shop("obj_tea", "teahouse")
	var poor: int = ShopSystem.get_shop_purse()
	if rich <= poor:
		_fail("a town's till holds %d against a teahouse's %d" % [rich, poor])
	_done()


## Spending at a shop refills its till, so selling then buying back works.
func _check_buying_puts_money_back_in_the_till() -> void:
	GameState.shop_purses.clear()
	_open_purse_shop("obj_till", "general")
	var item_id: String = ItemSystem.generate_weapon("", "common", "", "", "animal")
	ShopSystem._current_shop["items"] = {item_id: 1}
	GameState.shop_purses["obj_till"] = {"gold": 0, "day": GameState.current_day}
	GameState.gold = 1000000
	var price: int = ShopSystem.get_buy_price(item_id)
	ShopSystem.buy_item(item_id)
	if ShopSystem.get_shop_purse() != price:
		_fail("buying for %d left %d in the till" % [price, ShopSystem.get_shop_purse()])
	_done()


## Goods against goods first: an even swap needs no gold from either side, so
## a shop with an empty till can still make the trade.
func _check_barter_settles_in_goods_before_gold() -> void:
	GameState.shop_purses.clear()
	_open_purse_shop("obj_swap", "general")
	var mine: String = ItemSystem.generate_weapon("", "common", "", "", "animal")
	var theirs: String = ItemSystem.generate_weapon("", "common", "", "", "animal")
	ItemSystem.add_to_inventory(mine)
	ShopSystem._current_shop["items"] = {theirs: 1}
	GameState.shop_purses["obj_swap"] = {"gold": 0, "day": GameState.current_day}

	var deal: Dictionary = ShopSystem.evaluate_barter([mine], [theirs])
	if not deal.get("ok", false):
		_fail("an even-ish swap was refused: %s" % deal.get("reason", ""))
		_done()
		return
	var give_v: int = int(deal["give_value"])
	var take_v: int = int(deal["take_value"])
	if give_v <= 0 or take_v <= 0:
		_fail("barter priced a side at zero (%d for %d)" % [give_v, take_v])
	if int(deal["balance"]) != give_v - take_v:
		_fail("balance %d does not match %d - %d" % [int(deal["balance"]), give_v, take_v])
	_done()


## The shop cannot make change, so the player is asked before losing it.
func _check_a_shortfall_needs_confirming() -> void:
	GameState.shop_purses.clear()
	_open_purse_shop("obj_change", "general")
	var mine: String = ItemSystem.generate_weapon("", "rare", "", "", "animal")
	ItemSystem.add_to_inventory(mine)
	ShopSystem._current_shop["items"] = {}
	GameState.shop_purses["obj_change"] = {"gold": 5, "day": GameState.current_day}

	var blocked: Dictionary = ShopSystem.execute_barter([mine], [], false)
	if blocked.get("success", false):
		_fail("a deal the shop could not pay for went through unconfirmed")
	if str(blocked.get("reason", "")) != "shortfall_unconfirmed":
		_fail("refusal reason was '%s'" % str(blocked.get("reason", "")))
	if ItemSystem.get_inventory_count(mine) <= 0:
		_fail("the item was taken despite the deal being refused")

	var taken: Dictionary = ShopSystem.execute_barter([mine], [], true)
	if not taken.get("success", false):
		_fail("the confirmed deal was still refused")
	elif int(taken.get("shortfall", 0)) <= 0:
		_fail("the confirmed deal reported no shortfall")
	_done()


## A death regenerates the world, so nothing keyed to the old map survives —
## racks and purses above all, since their ids are never issued again.
func _check_a_new_life_keeps_nothing_of_the_old_world() -> void:
	GameState.shop_stock["ghost_rack"] = {"day": 0, "slots": [["x"]]}
	GameState.shop_purses["ghost_purse"] = {"gold": 99, "day": 0}
	GameState.guild_spell_lists["ghost_guild"] = ["spell"]
	GameState.gold = 99999
	GameState.start_new_run("hungry_ghost")
	if not GameState.shop_stock.is_empty():
		_fail("a rack from the previous world survived reincarnation")
	if not GameState.shop_purses.is_empty():
		_fail("a purse from the previous world survived reincarnation")
	if not GameState.guild_spell_lists.is_empty():
		_fail("a guild curriculum from the previous world survived reincarnation")
	if GameState.gold != 100:
		_fail("gold carried across a death: %d" % GameState.gold)
	_done()


# ============================================================================
# WHERE YOU ARE DECIDES HOW FAR YOU GET
# ============================================================================

func _open_trainer_in(tier: int, capital: bool, taught: int) -> void:
	ShopSystem._current_shop = {
		"id": "cap_probe", "type": "skill_trainer", "price_modifier": 1.0,
		"training": {"skills": ["swords"], "max_skill_level": taught}
	}
	if tier > 0:
		ShopSystem._current_shop["settlement"] = "Probe"
		ShopSystem._current_shop["settlement_tier"] = tier
		ShopSystem._current_shop["settlement_capital"] = capital


## weapon_master taught to 7 wherever it landed. A village is a village.
func _check_a_village_caps_a_master() -> void:
	_open_trainer_in(2, false, 7)
	var capped: int = ShopSystem.get_trainer_skill_cap()
	var expected: int = int(ShopSystem.SETTLEMENT_SKILL_CAP[2])
	if capped != expected:
		_fail("a master in a village teaches to %d, the village allows %d"
			% [capped, expected])
	_done()


## And the journey to the capital has to buy something.
func _check_a_capital_teaches_further_than_a_town() -> void:
	_open_trainer_in(3, false, 10)
	var town: int = ShopSystem.get_trainer_skill_cap()
	_open_trainer_in(3, true, 10)
	var capital: int = ShopSystem.get_trainer_skill_cap()
	if capital <= town:
		_fail("a capital teaches to %d against a town's %d" % [capital, town])
	# The teacher is still the other half of the ceiling.
	_open_trainer_in(3, true, 4)
	if ShopSystem.get_trainer_skill_cap() != 4:
		_fail("a limited teacher in the capital taught to %d, not 4"
			% ShopSystem.get_trainer_skill_cap())
	_done()


## An event shop met on the road is not a place, so no place caps it.
func _check_a_roadside_shop_is_capped_only_by_its_own_skill() -> void:
	_open_trainer_in(0, false, 6)
	if ShopSystem.get_trainer_skill_cap() != 6:
		_fail("a roadside trainer capped at %d rather than its own 6"
			% ShopSystem.get_trainer_skill_cap())
	if ShopSystem.get_settlement_skill_cap() != CharacterSystem.SKILL_MAX_LEVEL:
		_fail("a shop in no settlement reported a settlement cap")
	_done()
