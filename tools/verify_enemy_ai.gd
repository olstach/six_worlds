extends Node
## Headless verification for enemy AI templates (resources/data/enemies/ai_templates.json).
##
## Run: godot --headless res://tools/verify_enemy_ai.tscn
##
## Checks that templates and per-archetype overrides resolve the way the
## _comment in ai_templates.json says, that built enemies carry the resolved
## knobs, and that the item AI in combat_arena.gd follows them: a field medic
## hands a potion to a hurt ally (and steps in to reach one), a grenadier bombs
## a lone target, a default enemy still wants two clustered targets. And the
## spell AI: heals go to hurt allies (never opponents), buffs and curses are not
## recast on someone who already has them, spells and bombs measure range the
## way CombatManager checks it, targeting.prefer picks the right victim, and a
## hang_back unit keeps its distance. Plus the player's side of potion handing.
##
## The arena script is loaded but never added to the tree, so none of its UI is
## built; only its combat log is given a stand-in, since every AI action logs.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var grid: CombatGrid
var arena: Node

## Every check signs off by bumping this; a runtime error that aborts a check
## partway would otherwise let the scene report OK having verified nothing.
var checks_run: int = 0
const EXPECTED_CHECKS: int = 18


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid
	arena = load("res://scripts/combat/combat_arena.gd").new()
	arena.combat_log = RichTextLabel.new()

	_check_default_matches_old_rule()
	_check_template_and_override_merge()
	_check_built_enemies_carry_their_template()
	_check_default_needs_two_clustered()
	_check_grenadier_bombs_a_lone_target()
	_check_avoid_allies_holds_a_smoke_bomb()
	_check_field_medic_heals_adjacent_ally()
	_check_field_medic_steps_in()
	_check_potion_refuses_an_opponent()
	_check_heal_spell_goes_to_an_ally()
	_check_healer_steps_into_range()
	_check_buff_is_not_recast()
	_check_curse_is_not_recast()
	_check_spell_range_counts_like_the_engine()
	_check_bomb_range_counts_like_the_engine()
	_check_targeting_prefers()
	_check_hang_back_keeps_distance()
	_check_player_hands_a_potion()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway, "
			% [checks_run, EXPECTED_CHECKS] + "so its assertions never ran")
		failures += 1

	arena.combat_log.free()
	arena.free()
	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK (%d checks)" % checks_run)
		get_tree().quit(0)


func _done() -> void:
	checks_run += 1


func _fail(message: String) -> void:
	printerr("  FAIL: ", message)
	failures += 1


func _expect(actual, expected, what: String) -> void:
	if actual != expected:
		_fail("%s: got %s, expected %s" % [what, str(actual), str(expected)])


# ── helpers ──────────────────────────────────────────────────────────────────

## A unit on the grid, in CombatManager.all_units. `ai_template` "" leaves
## character_data without an "ai" block (like a summon or party member).
func _make_unit(at: Vector2i, team: int, ai_template: String = "") -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe %s" % str(at)
	unit.team = team
	unit.max_hp = 100
	unit.current_hp = 100
	unit.character_data = CharacterSystem.create_blank_character()
	if ai_template != "":
		unit.character_data["ai"] = EnemySystem.resolve_ai({"ai_template": ai_template})
	add_child(unit)
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


## Make `unit` the one whose turn it is, with two actions.
func _give_turn(unit: CombatUnit) -> void:
	CombatManager.turn_order.clear()
	CombatManager.turn_order.append(unit)
	CombatManager.current_unit_index = 0
	unit.actions_remaining = 2


## A unit that knows `spells`, with every school trained and mana to spare.
func _make_caster(at: Vector2i, team: int, ai_template: String, spells: Array) -> CombatUnit:
	var unit := _make_unit(at, team, ai_template)
	unit.character_data["known_spells"] = spells.duplicate()
	for skill in CharacterSystem.SCHOOL_SKILLS.values():
		unit.character_data["skills"][skill] = 9
	unit.max_mana = 300
	unit.current_mana = 300
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()
	CombatManager.turn_order.clear()


func _count(unit: CombatUnit, item_id: String) -> int:
	for entry in unit.combat_inventory:
		if entry.get("item_id", "") == item_id:
			return int(entry.get("quantity", 0))
	return 0


func _opponents(units: Array) -> Array[Node]:
	var result: Array[Node] = []
	for u in units:
		result.append(u)
	return result


# ── resolution ───────────────────────────────────────────────────────────────

## An archetype with no ai_template gets "default", and default is the rule
## combat_arena hard-coded before templates: 35% HP potion, 30% mana potion,
## bombs into 2+, oil in range, one consumable a turn, no ally healing.
func _check_default_matches_old_rule() -> void:
	var ai := EnemySystem.resolve_ai({})
	_expect(ai.get("template"), "default", "no ai_template")
	var items: Dictionary = ai.get("items", {})
	_expect(items.get("heal_self_below"), 0.35, "default heal_self_below")
	_expect(items.get("mana_self_below"), 0.3, "default mana_self_below")
	_expect(items.get("bomb_min_targets"), 2, "default bomb_min_targets")
	_expect(items.get("max_per_turn"), 1, "default max_per_turn")
	_expect(items.get("heal_ally_below"), 0.0, "default heal_ally_below")
	_expect(items.get("oil_when"), "in_range", "default oil_when")
	_expect(ai.get("priority"), ["heal_self", "heal_ally", "restore_mana", "heal_spell",
		"active_skill", "buff_spell", "spell", "bomb", "oil"], "default priority")
	_expect(ai.get("targeting", {}).get("prefer"), "nearest", "default targeting")
	_expect(ai.get("movement", {}).get("style"), "advance", "default movement")
	# Units the AI drives without a built "ai" block fall back to the same
	_expect(EnemySystem.get_ai({}).get("items"), items, "get_ai fallback")
	_done()


## default <- template <- archetype "ai": dictionaries merge key by key, lists
## replace, comments never reach the result.
func _check_template_and_override_merge() -> void:
	var ai := EnemySystem.resolve_ai({
		"ai_template": "grenadier",
		"ai": {"items": {"bomb_min_targets": 3}, "priority": ["bomb"]}})
	var items: Dictionary = ai.get("items", {})
	_expect(ai.get("template"), "grenadier", "override template id")
	_expect(items.get("bomb_min_targets"), 3, "archetype override wins")
	_expect(items.get("max_per_turn"), 2, "grenadier value kept under override")
	_expect(items.get("heal_self_below"), 0.35, "default value kept under template")
	_expect(ai.get("priority"), ["bomb"], "a list override replaces, not merges")
	if ai.has("_comment") or items.has("_comment"):
		_fail("a _comment leaked into resolved AI knobs")
	# Unknown template: warns, falls back to default
	_expect(EnemySystem.resolve_ai({"ai_template": "no_such_template"}).get("template"),
		"default", "unknown template falls back")
	_done()


## The three kit archetypes carry their templates onto the built enemy dict,
## and an ordinary archetype carries "default".
func _check_built_enemies_carry_their_template() -> void:
	var cases := {
		"hell_yellow_devil_grenadier": "grenadier",
		"animal_bhramara_honey_keeper": "alchemist",
		"animal_vanara_tinkerer": "tinkerer",
		"hell_demon_warrior": "default",
		"hell_ice_priest": "healer",
		"hell_white_devil_illusionist": "enchanter",
		"hg_charnel_wraith": "hexer",
	}
	for aid in cases:
		var enemy: Dictionary = EnemySystem._build_enemy(aid, 400, "hell")
		_expect(enemy.get("ai", {}).get("template", ""), cases[aid], "%s built ai template" % aid)
	# The maneater's old ai_behavior "priority_target" is now an override
	var maneater: Dictionary = EnemySystem._build_enemy("animal_rakshasa_maneater", 400, "animal")
	_expect(maneater.get("ai", {}).get("targeting", {}).get("prefer", ""), "weakest", "maneater targeting")
	_done()


# ── bombs ────────────────────────────────────────────────────────────────────

## Default still refuses a lone target, and throws once two stand together.
func _check_default_needs_two_clustered() -> void:
	var thrower := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY, "default")
	thrower.combat_inventory = [{"item_id": "fire_bomb", "quantity": 2}]
	var a := _make_unit(Vector2i(8, 5), CombatManager.Team.PLAYER)
	_give_turn(thrower)
	var knobs: Dictionary = EnemySystem.get_ai(thrower.character_data).get("items", {})
	if arena._ai_try_use_bomb(thrower, _opponents([a]), knobs):
		_fail("default enemy bombed a lone target")
	_expect(_count(thrower, "fire_bomb"), 2, "default lone target: bombs kept")
	var b := _make_unit(Vector2i(8, 6), CombatManager.Team.PLAYER)
	if not arena._ai_try_use_bomb(thrower, _opponents([a, b]), knobs):
		_fail("default enemy did not bomb two clustered targets")
	_expect(_count(thrower, "fire_bomb"), 1, "default cluster: one bomb thrown")
	_cleanup([thrower, a, b])
	_done()


func _check_grenadier_bombs_a_lone_target() -> void:
	var thrower := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY, "grenadier")
	thrower.combat_inventory = [{"item_id": "fire_bomb", "quantity": 2}]
	var a := _make_unit(Vector2i(8, 5), CombatManager.Team.PLAYER)
	_give_turn(thrower)
	var knobs: Dictionary = EnemySystem.get_ai(thrower.character_data).get("items", {})
	if not arena._ai_try_use_bomb(thrower, _opponents([a]), knobs):
		_fail("grenadier did not bomb a lone target")
	_expect(_count(thrower, "fire_bomb"), 1, "grenadier lone target: one bomb thrown")
	_cleanup([thrower, a])
	_done()


## A smoke bomb hits everyone; bomb_avoid_allies keeps it in the pouch while an
## ally stands in the blast, and default (which never looked) still throws.
func _check_avoid_allies_holds_a_smoke_bomb() -> void:
	var thrower := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY, "grenadier")
	thrower.combat_inventory = [{"item_id": "smoke_bomb", "quantity": 1}]
	var friend := _make_unit(Vector2i(7, 6), CombatManager.Team.ENEMY)
	var a := _make_unit(Vector2i(8, 5), CombatManager.Team.PLAYER)
	_give_turn(thrower)
	var knobs: Dictionary = EnemySystem.get_ai(thrower.character_data).get("items", {})
	if arena._ai_try_use_bomb(thrower, _opponents([a]), knobs):
		_fail("grenadier threw a smoke bomb over its own ally")
	var loose: Dictionary = knobs.duplicate()
	loose["bomb_avoid_allies"] = false
	if not arena._ai_try_use_bomb(thrower, _opponents([a]), loose):
		_fail("with bomb_avoid_allies off the smoke bomb was not thrown")
	_cleanup([thrower, friend, a])
	_done()


# ── potions on allies ────────────────────────────────────────────────────────

func _check_field_medic_heals_adjacent_ally() -> void:
	var medic := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY, "field_medic")
	medic.combat_inventory = [{"item_id": "health_potion", "quantity": 1}]
	var hurt := _make_unit(Vector2i(6, 6), CombatManager.Team.ENEMY)
	hurt.current_hp = 20
	_give_turn(medic)
	var knobs: Dictionary = EnemySystem.get_ai(medic.character_data).get("items", {})
	if not arena._ai_try_heal_ally(medic, knobs):
		_fail("field medic did not heal an adjacent ally at 20% HP")
	if hurt.current_hp <= 20:
		_fail("ally's HP did not rise (still %d)" % hurt.current_hp)
	_expect(medic.current_hp, 100, "medic's own HP untouched")
	_expect(_count(medic, "health_potion"), 0, "potion spent")
	# A default unit never hands potions out
	var plain := _make_unit(Vector2i(4, 4), CombatManager.Team.ENEMY, "default")
	plain.combat_inventory = [{"item_id": "health_potion", "quantity": 1}]
	_give_turn(plain)
	if arena._ai_try_heal_ally(plain, EnemySystem.get_ai(plain.character_data).get("items", {})):
		_fail("a default enemy gave a potion to an ally")
	_cleanup([medic, hurt, plain])
	_done()


## With heal_ally_step_in, a medic out of reach spends one action moving next
## to the ally, then the second on the potion.
func _check_field_medic_steps_in() -> void:
	var medic := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY, "field_medic")
	medic.combat_inventory = [{"item_id": "health_potion", "quantity": 1}]
	var hurt := _make_unit(Vector2i(8, 5), CombatManager.Team.ENEMY)
	hurt.current_hp = 20
	_give_turn(medic)
	var knobs: Dictionary = EnemySystem.get_ai(medic.character_data).get("items", {})
	if not arena._ai_try_heal_ally(medic, knobs):
		_fail("field medic did not step in to heal an ally 3 tiles away")
	if arena._grid_distance(medic.grid_position, hurt.grid_position) > CombatManager.POTION_ALLY_REACH:
		_fail("medic did not end up beside the ally (at %s)" % str(medic.grid_position))
	_expect(medic.actions_remaining, 0, "step + potion used both actions")
	if hurt.current_hp <= 20:
		_fail("stepped-in potion did not heal the ally")
	_cleanup([medic, hurt])
	_done()


## The engine side: a potion can't be handed to an opponent, or past reach.
func _check_potion_refuses_an_opponent() -> void:
	var medic := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY, "field_medic")
	medic.combat_inventory = [{"item_id": "health_potion", "quantity": 2}]
	var foe := _make_unit(Vector2i(6, 5), CombatManager.Team.PLAYER)
	var far_friend := _make_unit(Vector2i(9, 5), CombatManager.Team.ENEMY)
	_give_turn(medic)
	if CombatManager.ai_use_combat_item(medic, "health_potion", foe.grid_position).get("success", false):
		_fail("potion was handed to an opponent")
	if CombatManager.ai_use_combat_item(medic, "health_potion", far_friend.grid_position).get("success", false):
		_fail("potion was handed to an ally 4 tiles away")
	_expect(_count(medic, "health_potion"), 2, "refused potions are not consumed")
	_cleanup([medic, foe, far_friend])
	_done()


# ── spells ───────────────────────────────────────────────────────────────────

## Bind Wounds (lesser_heal) is aimed at an ally. Before the spell AI read the
## normalised spell, every spell looked like "single enemy" and the honey-keeper
## healed the party.
func _check_heal_spell_goes_to_an_ally() -> void:
	var healer := _make_caster(Vector2i(5, 5), CombatManager.Team.ENEMY, "healer", ["lesser_heal"])
	var hurt := _make_unit(Vector2i(7, 5), CombatManager.Team.ENEMY)
	var foe := _make_unit(Vector2i(6, 5), CombatManager.Team.PLAYER)
	foe.current_hp = 10
	_give_turn(healer)
	var ai := EnemySystem.get_ai(healer.character_data)
	if arena._ai_try_heal_spell(healer, ai):
		_fail("healer cast a heal with no ally under heal_below")
	hurt.current_hp = 20
	if not arena._ai_try_heal_spell(healer, ai):
		_fail("healer did not heal an ally at 20% HP in range")
	if hurt.current_hp <= 20:
		_fail("the ally's HP did not rise (still %d)" % hurt.current_hp)
	_expect(foe.current_hp, 10, "the hurt opponent was not healed")
	_cleanup([healer, hurt, foe])
	_done()


## heal_step_in: the hurt ally is out of the spell's range, so one action
## walks into range and the second heals.
func _check_healer_steps_into_range() -> void:
	var healer := _make_caster(Vector2i(2, 5), CombatManager.Team.ENEMY, "healer", ["lesser_heal"])
	var reach: int = int(CombatManager.get_spell("lesser_heal").get("range", 1))
	var hurt := _make_unit(Vector2i(2 + reach + 1, 5), CombatManager.Team.ENEMY)
	hurt.current_hp = 20
	_give_turn(healer)
	if not arena._ai_try_heal_spell(healer, EnemySystem.get_ai(healer.character_data)):
		_fail("healer did not step into range to heal (reach %d)" % reach)
	_expect(healer.actions_remaining, 0, "step + heal used both actions")
	if hurt.current_hp <= 20:
		_fail("stepped-in heal did not land")
	_cleanup([healer, hurt])
	_done()


## Bark Skin goes to the ally nearest an opponent, and nobody gets it twice.
func _check_buff_is_not_recast() -> void:
	var caster := _make_caster(Vector2i(5, 5), CombatManager.Team.ENEMY, "enchanter", ["bark_skin"])
	var front := _make_unit(Vector2i(7, 5), CombatManager.Team.ENEMY)
	var foe := _make_unit(Vector2i(8, 5), CombatManager.Team.PLAYER)
	var status: String = CombatManager.get_spell("bark_skin").get("statuses_caused", [""])[0]
	_give_turn(caster)
	var ai := EnemySystem.get_ai(caster.character_data)
	if not arena._ai_try_buff_spell(caster, _opponents([foe]), ai):
		_fail("enchanter did not cast Bark Skin")
	if not front.has_status(status):
		_fail("Bark Skin did not go to the front-line ally")
	CombatManager._apply_status_effect(caster, status, 5)
	_give_turn(caster)
	var mana_before := caster.current_mana
	if arena._ai_try_buff_spell(caster, _opponents([foe]), ai):
		_fail("Bark Skin was recast when every ally already had %s" % status)
	_expect(caster.current_mana, mana_before, "no mana spent on a wasted buff")
	_cleanup([caster, front, foe])
	_done()


## A curse (no damage) is not cast on someone already carrying it.
func _check_curse_is_not_recast() -> void:
	var hexer := _make_caster(Vector2i(5, 5), CombatManager.Team.ENEMY, "hexer", ["curse"])
	var foe := _make_unit(Vector2i(7, 5), CombatManager.Team.PLAYER)
	for status in CombatManager.get_spell("curse").get("statuses_caused", []):
		CombatManager._apply_status_effect(foe, status, 5)
	_give_turn(hexer)
	var spells := CombatManager.get_castable_spells(hexer)
	if arena._ai_try_cast_spell(hexer, spells, _opponents([foe]), foe):
		_fail("hexer recast Curse on a cursed target")
	_expect(hexer.current_mana, 300, "no mana spent on a wasted curse")
	_cleanup([hexer, foe])
	_done()


## Spell range has no diagonal shortcut. A target three tiles away diagonally
## (six by spell count) is out of a range-4 Firebolt's reach, so the AI must not
## pick it — it used to, and the cast then failed and the turn was wasted.
func _check_spell_range_counts_like_the_engine() -> void:
	var caster := _make_caster(Vector2i(5, 5), CombatManager.Team.ENEMY, "", ["firebolt"])
	var reach: int = int(CombatManager.get_spell("firebolt").get("range", 1))
	var diag := _make_unit(Vector2i(5 + reach - 1, 5 + reach - 1), CombatManager.Team.PLAYER)
	_give_turn(caster)
	var spells := CombatManager.get_castable_spells(caster)
	if arena._ai_try_cast_spell(caster, spells, _opponents([diag]), diag):
		_fail("AI cast Firebolt at a diagonal target out of spell range")
	_expect(caster.current_mana, 300, "nothing spent on the diagonal")
	var straight := _make_unit(Vector2i(5 + reach, 5), CombatManager.Team.PLAYER)
	if not arena._ai_try_cast_spell(caster, spells, _opponents([diag, straight]), diag):
		_fail("AI did not cast Firebolt at a target in range")
	_cleanup([caster, diag, straight])
	_done()


## The same for a bomb throw: picked by the rule ai_use_combat_item checks.
func _check_bomb_range_counts_like_the_engine() -> void:
	var thrower := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY, "grenadier")
	thrower.combat_inventory = [{"item_id": "fire_bomb", "quantity": 2}]
	var reach: int = int(ItemSystem.get_item("fire_bomb").get("effect", {}).get("range", 4))
	var diag := _make_unit(Vector2i(5 + reach - 1, 5 + reach - 1), CombatManager.Team.PLAYER)
	_give_turn(thrower)
	var knobs: Dictionary = EnemySystem.get_ai(thrower.character_data).get("items", {})
	if arena._ai_try_use_bomb(thrower, _opponents([diag]), knobs):
		_fail("grenadier threw at a diagonal target out of throw range")
	_expect(_count(thrower, "fire_bomb"), 2, "diagonal: bombs kept")
	_expect(thrower.actions_remaining, 2, "diagonal: no action spent")
	var near := _make_unit(Vector2i(5 + reach - 2, 7), CombatManager.Team.PLAYER)
	if not arena._ai_try_use_bomb(thrower, _opponents([diag, near]), knobs):
		_fail("grenadier did not throw at a target in range")
	_cleanup([thrower, diag, near])
	_done()


func _check_targeting_prefers() -> void:
	var hunter := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	var close := _make_unit(Vector2i(6, 5), CombatManager.Team.PLAYER)
	var mage := _make_unit(Vector2i(9, 5), CombatManager.Team.PLAYER)
	mage.character_data["known_spells"] = ["firebolt"]
	var foes := _opponents([close, mage])
	_expect(arena._ai_pick_target(hunter, foes, "nearest"), close, "prefer nearest")
	_expect(arena._ai_pick_target(hunter, foes, "casters"), mage, "prefer casters")
	_expect(arena._ai_pick_target(hunter, foes, "wounded"), close, "wounded: both at full HP, the nearer")
	mage.current_hp = 10
	_expect(arena._ai_pick_target(hunter, foes, "wounded"), mage, "prefer wounded")
	_cleanup([hunter, close, mage])
	_done()


## hang_back: an opponent walks up to the caster; it steps away while keeping
## the opponent in spell range.
func _check_hang_back_keeps_distance() -> void:
	var caster := _make_caster(Vector2i(6, 5), CombatManager.Team.ENEMY, "hexer", ["firebolt"])
	var foe := _make_unit(Vector2i(7, 5), CombatManager.Team.PLAYER)
	var reach: int = int(CombatManager.get_spell("firebolt").get("range", 1))
	_give_turn(caster)
	var tile: Vector2i = arena._ai_hang_back_tile(caster, CombatManager.get_movement_range(caster),
			foe, _opponents([foe]), reach, 0, 0, 3)
	if arena._grid_distance(tile, foe.grid_position) < 2:
		_fail("hang_back stayed next to the opponent (chose %s)" % str(tile))
	if CombatManager.spell_distance(tile, foe.grid_position) > reach:
		_fail("hang_back left spell range (chose %s)" % str(tile))
	_cleanup([caster, foe])
	_done()


## The player can give a potion to an adjacent ally, not to one further off.
func _check_player_hands_a_potion() -> void:
	var saved := ItemSystem.get_inventory().duplicate(true)
	ItemSystem.clear_inventory()
	ItemSystem.add_to_inventory("health_potion", 2, true)
	var user := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var ally := _make_unit(Vector2i(6, 6), CombatManager.Team.PLAYER)
	var far := _make_unit(Vector2i(9, 5), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(4, 5), CombatManager.Team.ENEMY)
	ally.current_hp = 20
	far.current_hp = 20
	foe.current_hp = 20
	_give_turn(user)
	var tiles := CombatManager.handed_item_tiles(user)
	_expect(tiles.size(), 2, "potion tiles: self + the adjacent ally")
	var given := CombatManager.use_combat_item(user, "health_potion", ally.grid_position)
	if not given.get("success", false):
		_fail("player could not give a potion to an adjacent ally: %s" % given.get("reason", ""))
	if ally.current_hp <= 20:
		_fail("the ally given the potion was not healed")
	_expect(user.current_hp, 100, "giver's HP untouched")
	if CombatManager.use_combat_item(user, "health_potion", far.grid_position).get("success", false):
		_fail("potion was given to an ally 4 tiles away")
	if CombatManager.use_combat_item(user, "health_potion", foe.grid_position).get("success", false):
		_fail("potion was given to an opponent")
	_expect(ItemSystem.get_inventory_count("health_potion"), 1, "only the given potion was spent")
	_cleanup([user, ally, far, foe])
	ItemSystem.clear_inventory()
	for entry in saved:
		ItemSystem.add_to_inventory(entry.get("item_id", ""), int(entry.get("quantity", 1)), true)
	_done()
