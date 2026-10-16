extends Node
## Headless verification for enemy AI templates (resources/data/enemies/ai_templates.json).
##
## Run: godot --headless res://tools/verify_enemy_ai.tscn
##
## Checks that templates and per-archetype overrides resolve the way the
## _comment in ai_templates.json says, that built enemies carry the resolved
## knobs, and that the item AI in combat_arena.gd follows them: a field medic
## hands a potion to a hurt ally (and steps in to reach one), a grenadier bombs
## a lone target, a default enemy still wants two clustered targets.
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
const EXPECTED_CHECKS: int = 9


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
	_expect(ai.get("priority"), ["heal_self", "heal_ally", "restore_mana",
		"active_skill", "spell", "bomb", "oil"], "default priority")
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
	}
	for aid in cases:
		var enemy: Dictionary = EnemySystem._build_enemy(aid, 400, "hell")
		_expect(enemy.get("ai", {}).get("template", ""), cases[aid], "%s built ai template" % aid)
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
