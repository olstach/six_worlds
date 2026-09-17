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
const EXPECTED_CHECKS: int = 18


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
