extends Node
## Headless verification for the unified aura system.
##
## Run: godot --headless res://tools/verify_auras.tscn
##
## Every check drives a REAL consumer — a stat getter, apply_damage(), the
## per-turn processor — rather than asking AuraSystem what it thinks. That
## distinction matters more here than anywhere else in this codebase: the whole
## reason this refactor exists is that `passive_aura` was present in data,
## readable by a helper, and still did nothing in play, because the only code
## that looked at it looked in the wrong equipment slot. A test that asked the
## helper would have passed throughout.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var grid: CombatGrid

## A runtime error inside a check aborts it and returns control to _ready(),
## which would then find no failures and report OK having verified nothing.
var checks_run: int = 0
const EXPECTED_CHECKS: int = 19


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	# Reach and sign — the rules every payload kind depends on.
	_check_equipment_aura_from_body_slot()
	_check_aura_respects_radius()
	_check_aura_affects_enemies_only()
	_check_emitter_excluded_unless_self_included()
	_check_invert_for_enemies()

	# The bug this refactor found.
	_check_khatvanga_slows_rather_than_hastens()

	# Continuous payloads must not accumulate.
	_check_stat_aura_does_not_accumulate()
	_check_stat_aura_ends_when_the_source_leaves()

	# The four sources.
	_check_status_source()
	_check_perk_source()
	_check_intrinsic_source()

	# Per-turn payloads.
	_check_heal_payload_reaches_the_target()
	_check_grant_status_payload()

	# The stored payload, which is the one that can double.
	_check_max_hp_aura_applies_once()
	_check_max_hp_aura_clamps_on_removal()

	# Damage multipliers.
	_check_damage_taken_pct_is_filtered_by_kind()

	# Several auras from one source, and payloads that fire on a roll.
	_check_status_can_carry_several_auras()
	_check_summon_template_auras_reach_the_creature()
	_check_grant_status_chance_is_respected()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway, "
			% [checks_run, EXPECTED_CHECKS] + "so its assertions never ran")
		failures += 1

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


# ── Fixtures ─────────────────────────────────────────────────────────────────

func _make_unit(at: Vector2i, team: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d" % team
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(unit.character_data)
	add_child(unit)
	unit.max_hp = 100
	unit.current_hp = 100
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()


## Put an item in a slot directly. Goes through the equipment dictionary rather
## than equip(), because equip() enforces requirements this test does not care
## about and would quietly no-op on a blank character.
func _force_equip(unit: CombatUnit, slot: String, item_id: String) -> void:
	if not unit.character_data.has("equipment"):
		unit.character_data["equipment"] = {}
	if slot == "weapon_main":
		var set_key := "weapon_set_%d" % int(unit.character_data.get("active_weapon_set", 1))
		if not unit.character_data["equipment"].has(set_key):
			unit.character_data["equipment"][set_key] = {}
		unit.character_data["equipment"][set_key]["main"] = item_id
	else:
		unit.character_data["equipment"][slot] = item_id


# ── Reach and sign ───────────────────────────────────────────────────────────

## The original bug, verbatim: an aura declared on a CHEST item. The old reader
## looked only at weapon_main, so the healer's robe was inert no matter what its
## data said.
func _check_equipment_aura_from_body_slot() -> void:
	var healer := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	_force_equip(healer, "chest", "legendary_healers_robe")

	var auras := AuraSystem.emitted_by(healer)
	var ids: Array = []
	for a in auras:
		ids.append(a["id"])
	if not "healing_regeneration" in ids:
		_fail("a healer's robe in the chest slot emitted nothing (got %s) — "
			% str(ids) + "equipment auras are not being read from body slots")

	ally.current_hp = 50
	CombatManager._process_auras(healer)
	if ally.current_hp <= 50:
		_fail("the healer's robe aura did not heal an adjacent ally (hp %d)"
			% ally.current_hp)
	_cleanup([healer, ally])
	_done()


func _check_aura_respects_radius() -> void:
	var healer := _make_unit(Vector2i(5, 5), 0)
	var far := _make_unit(Vector2i(50, 50), 0)
	_force_equip(healer, "chest", "legendary_healers_robe")
	far.current_hp = 50
	CombatManager._process_auras(healer)
	if far.current_hp != 50:
		_fail("an aura with radius 2 healed a unit 45 tiles away (hp %d)"
			% far.current_hp)
	_cleanup([healer, far])
	_done()


## `affects` has to hold in BOTH directions, and they are separate code paths:
## a debuff aura must not catch friends, and a buff aura must not help enemies.
## Testing only one direction leaves the other free to break silently.
func _check_aura_affects_enemies_only() -> void:
	# Debuff direction: the Khatvanga is `affects: enemies`, so an ally standing
	# next to the bearer must be untouched or every debuff is friendly fire.
	var bearer := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	_force_equip(bearer, "weapon_main", "legendary_iron_khatvanga")

	var ally_init: int = ally.get_initiative()
	var baseline := _make_unit(Vector2i(80, 80), 0)
	if ally_init != baseline.get_initiative():
		_fail("an enemies-only aura changed an ALLY's initiative: %d vs %d"
			% [ally_init, baseline.get_initiative()])

	# Buff direction: the healer's robe is `affects: allies`, so the enemy
	# standing in the doorway must not be healed by it.
	var healer := _make_unit(Vector2i(20, 20), 0)
	var foe := _make_unit(Vector2i(21, 20), 1)
	_force_equip(healer, "chest", "legendary_healers_robe")
	foe.current_hp = 50
	CombatManager._process_auras(healer)
	if foe.current_hp != 50:
		_fail("an allies-only aura healed an ENEMY to %d — `affects` is not "
			% foe.current_hp + "separating the teams")
	_cleanup([bearer, ally, baseline, healer, foe])
	_done()


func _check_emitter_excluded_unless_self_included() -> void:
	# The Khatvanga does not slow its own wielder...
	var bearer := _make_unit(Vector2i(5, 5), 0)
	var baseline := _make_unit(Vector2i(80, 80), 0)
	_force_equip(bearer, "weapon_main", "legendary_iron_khatvanga")
	if bearer.get_initiative() != baseline.get_initiative():
		_fail("the Khatvanga slowed the unit carrying it: %d vs %d"
			% [bearer.get_initiative(), baseline.get_initiative()])

	# ...but a healing presence does heal its wearer, because it says so.
	var healer := _make_unit(Vector2i(20, 20), 0)
	_force_equip(healer, "chest", "legendary_healers_robe")
	healer.current_hp = 50
	CombatManager._process_auras(healer)
	if healer.current_hp <= 50:
		_fail("self_included aura did not reach its own emitter (hp %d)"
			% healer.current_hp)
	_cleanup([bearer, baseline, healer])
	_done()


func _check_invert_for_enemies() -> void:
	var summon := _make_unit(Vector2i(5, 5), 0)
	summon.intrinsic_auras.append("summon_empowerment")
	var friend := _make_unit(Vector2i(6, 5), 0)
	var foe := _make_unit(Vector2i(4, 5), 1)
	var plain_friend := _make_unit(Vector2i(80, 80), 0)
	var plain_foe := _make_unit(Vector2i(81, 81), 1)

	var friend_armor: int = friend.get_armor()
	var foe_armor: int = foe.get_armor()
	if friend_armor <= plain_friend.get_armor():
		_fail("summon aura gave an ally no armor: %d vs %d"
			% [friend_armor, plain_friend.get_armor()])
	if foe_armor >= plain_foe.get_armor():
		_fail("summon aura did not penalise an enemy's armor: %d vs %d — "
			% [foe_armor, plain_foe.get_armor()] + "invert_for_enemies is not flipping the sign")
	_cleanup([summon, friend, foe, plain_friend, plain_foe])
	_done()


## The Khatvanga aura existed before this refactor and was inverted: the reader
## did `total -= aura_value` while the data carried a NEGATIVE aura_value, so
## standing next to an enemy's Khatvanga made you FASTER. Nothing caught it
## because nothing tested it.
func _check_khatvanga_slows_rather_than_hastens() -> void:
	var bearer := _make_unit(Vector2i(5, 5), 1)
	_force_equip(bearer, "weapon_main", "legendary_iron_khatvanga")
	var victim := _make_unit(Vector2i(6, 5), 0)
	var baseline := _make_unit(Vector2i(80, 80), 0)

	var slowed: int = victim.get_initiative()
	var normal: int = baseline.get_initiative()
	if slowed >= normal:
		_fail("an adjacent enemy Khatvanga left initiative at %d (baseline %d) — "
			% [slowed, normal] + "the weight of the staff should SLOW, not hasten")
	_cleanup([bearer, victim, baseline])
	_done()


# ── Continuous payloads must not accumulate ──────────────────────────────────

## Reading a stat five times must give the same answer five times. This is the
## single most expensive bug pattern in this codebase — mana_cost_reduction
## reached -500 by being recomputed and added to itself — and continuous aura
## payloads are computed on every read, so a stored intermediate would compound
## faster than anything before it.
func _check_stat_aura_does_not_accumulate() -> void:
	var summon := _make_unit(Vector2i(5, 5), 0)
	summon.intrinsic_auras.append("summon_empowerment")
	var friend := _make_unit(Vector2i(6, 5), 0)

	var first: int = friend.get_armor()
	for _i in 5:
		friend.get_armor()
	var last: int = friend.get_armor()
	if first != last:
		_fail("armor went from %d to %d over six reads — an aura bonus is "
			% [first, last] + "being stored rather than recomputed")
	_cleanup([summon, friend])
	_done()


## Walking out of an aura must end it with no bookkeeping. If the bonus were
## stored anywhere, this is where it would linger.
func _check_stat_aura_ends_when_the_source_leaves() -> void:
	var summon := _make_unit(Vector2i(5, 5), 0)
	summon.intrinsic_auras.append("summon_empowerment")
	var friend := _make_unit(Vector2i(6, 5), 0)

	var inside: int = friend.get_armor()
	summon.grid_position = Vector2i(70, 70)
	var outside: int = friend.get_armor()
	if outside >= inside:
		_fail("armor stayed at %d after the aura source walked away (was %d inside)"
			% [outside, inside])
	_cleanup([summon, friend])
	_done()


# ── The four sources ─────────────────────────────────────────────────────────

## Spells and active skills reach auras through the status they apply, so this
## is the spell path as well as the status path.
func _check_status_source() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	CombatManager._apply_status_effect(caster, "Soothing_Presence", 3)

	ally.current_hp = 50
	CombatManager._process_auras(caster)
	if ally.current_hp <= 50:
		_fail("Soothing_Presence healed nobody (ally hp %d) — a status-declared "
			% ally.current_hp + "aura is not being collected")
	_cleanup([caster, ally])
	_done()


## Avatar of the Storm is party-wide (radius 99) rather than proximity-based, so
## the comparison has to be before-and-after on the same unit. A second ally
## standing "far away" is still inside it — which is the point of the perk.
func _check_perk_source() -> void:
	var hero := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)

	var before: int = ally.get_accuracy()
	hero.character_data["perks"] = [{"id": "avatar_of_the_storm"}]
	var after: int = ally.get_accuracy()
	if after <= before:
		_fail("a perk-declared aura gave an ally no accuracy: %d before, %d after"
			% [before, after])

	# And it reaches across the map, unlike every other aura here.
	var distant := _make_unit(Vector2i(90, 90), 0)
	if distant.get_accuracy() != after:
		_fail("the party-wide aura did not reach a distant ally: %d vs %d"
			% [distant.get_accuracy(), after])
	_cleanup([hero, ally, distant])
	_done()


func _check_intrinsic_source() -> void:
	var summon := _make_unit(Vector2i(5, 5), 0)
	var friend := _make_unit(Vector2i(6, 5), 0)
	var before: int = friend.get_dodge()
	summon.intrinsic_auras.append("summon_empowerment")
	if friend.get_dodge() <= before:
		_fail("an intrinsic aura changed nothing: dodge %d before, %d after"
			% [before, friend.get_dodge()])
	_cleanup([summon, friend])
	_done()


# ── Per-turn payloads ────────────────────────────────────────────────────────

func _check_heal_payload_reaches_the_target() -> void:
	var healer := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	_force_equip(healer, "chest", "legendary_healers_robe")
	ally.current_hp = ally.max_hp  # already full
	CombatManager._process_auras(healer)
	if ally.current_hp != ally.max_hp:
		_fail("a heal aura pushed a full-health ally to %d/%d"
			% [ally.current_hp, ally.max_hp])

	ally.current_hp = 10
	CombatManager._process_auras(healer)
	if ally.current_hp != 13:
		_fail("heal aura gave %d hp, expected 13 (10 + the robe's 3)"
			% ally.current_hp)
	_cleanup([healer, ally])
	_done()


func _check_grant_status_payload() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	CombatManager._apply_status_effect(caster, "Favorable_Wind", 3)
	CombatManager._process_auras(caster)
	if not ally.has_status("Hasted"):
		_fail("Favorable_Wind did not grant Hasted to an adjacent ally")
	if not ally.has_status("Precision"):
		_fail("Favorable_Wind did not grant Precision to an adjacent ally")
	_cleanup([caster, ally])
	_done()


# ── The stored payload ───────────────────────────────────────────────────────

## max_hp is the one payload that must be stored, so it is the one that can
## double. Refreshing repeatedly must be a no-op.
func _check_max_hp_aura_applies_once() -> void:
	var wearer := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	_force_equip(wearer, "head", "legendary_longlife_cap")
	var base: int = ally.max_hp

	CombatManager._refresh_aura_max_hp()
	var once: int = ally.max_hp
	if once <= base:
		_fail("a longlife cap on an adjacent ally granted no max hp (%d)" % once)
	for _i in 5:
		CombatManager._refresh_aura_max_hp()
	if ally.max_hp != once:
		_fail("max_hp went from %d to %d over six refreshes — the aura is "
			% [once, ally.max_hp] + "adding instead of applying a delta")
	_cleanup([wearer, ally])
	_done()


## And when it goes away, current_hp has to come with it or the unit sits above
## its own maximum.
func _check_max_hp_aura_clamps_on_removal() -> void:
	var wearer := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	_force_equip(wearer, "head", "legendary_longlife_cap")
	CombatManager._refresh_aura_max_hp()
	var boosted: int = ally.max_hp

	wearer.grid_position = Vector2i(70, 70)
	CombatManager._refresh_aura_max_hp()
	if ally.max_hp >= boosted:
		_fail("max_hp stayed at %d after the aura left (was %d)"
			% [ally.max_hp, boosted])
	if ally.current_hp > ally.max_hp:
		_fail("current_hp %d exceeds max_hp %d after the aura left"
			% [ally.current_hp, ally.max_hp])
	_cleanup([wearer, ally])
	_done()


# ── Damage multipliers ───────────────────────────────────────────────────────

## Dampening_Aura reduces MAGIC damage. A sword is not dampened, and the filter
## is what decides — so both halves are asserted.
func _check_damage_taken_pct_is_filtered_by_kind() -> void:
	var guard := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	CombatManager._apply_status_effect(guard, "Dampening_Aura", 3)

	ally.current_hp = 100
	CombatManager.apply_damage(ally, 100, "fire")
	var magic_taken: int = 100 - ally.current_hp

	ally.current_hp = 100
	CombatManager.apply_damage(ally, 100, "physical")
	var physical_taken: int = 100 - ally.current_hp

	if magic_taken >= 100:
		_fail("Dampening_Aura did not reduce magic damage: took %d of 100"
			% magic_taken)
	if physical_taken != 100:
		_fail("Dampening_Aura reduced PHYSICAL damage too: took %d of 100 — "
			% physical_taken + "the `only` filter is not being applied")
	_cleanup([guard, ally])
	_done()


# ── Several auras from one source ────────────────────────────────────────────

## Radiance mends the allies around it AND dazzles whoever closes to melee.
## Those reach different teams at different radii, so they cannot be one aura —
## the status names both.
func _check_status_can_carry_several_auras() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	var foe := _make_unit(Vector2i(4, 5), 1)
	CombatManager._apply_status_effect(caster, "Radiance", 3)

	var auras := AuraSystem.emitted_by(caster)
	if auras.size() < 2:
		_fail("Radiance produced %d aura(s); it declares two" % auras.size())

	ally.current_hp = 50
	# The glare fires on a 35% roll, so give it enough turns to land once.
	var stunned := false
	for _i in 25:
		CombatManager._process_auras(caster)
		if foe.has_status("Stunned"):
			stunned = true
			break
	if ally.current_hp <= 50:
		_fail("Radiance healed no ally (hp %d) — the healing half never fired"
			% ally.current_hp)
	if not stunned:
		_fail("Radiance never stunned an adjacent enemy across 25 turns — the "
			+ "melee half never fired")
	_cleanup([caster, ally, foe])
	_done()


## The four helper summons exist to stand somewhere and help. Their auras live
## on the creature's template, not on the sentence that summoned it.
##
## Spawned through the REAL summoning path. The first version of this check set
## intrinsic_auras by hand and then asserted the template's data separately,
## which tested both ends and not the wire between them — unhooking the spawn
## path entirely left it green.
func _check_summon_template_auras_reach_the_creature() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0)
	var result: Dictionary = CombatManager._spawn_summoned_unit(
		caster, "Singing_Birds", Vector2i(7, 5), 0)
	if not result.get("success", false):
		_fail("could not summon Singing_Birds: %s" % str(result.get("reason", "?")))
		_cleanup([caster])
		_done()
		return

	var bird: Node = result["unit"]
	if not "singing_birds" in bird.intrinsic_auras:
		_fail("the summoned birds carry auras %s — the template's `auras` never "
			% str(bird.intrinsic_auras) + "reached the creature")

	var ally := _make_unit(Vector2i(8, 5), 0)
	CombatManager._process_auras(bird)
	if not ally.has_status("Encouraged"):
		_fail("a summoned Singing Birds left the adjacent ally unencouraged")

	_cleanup([caster, ally, bird])
	_done()


## A field that charmed everyone beside it every turn would end fights by
## itself, so grant_status may fire on a roll — and the roll must be read.
func _check_grant_status_chance_is_respected() -> void:
	var apsara := _make_unit(Vector2i(5, 5), 0)
	apsara.intrinsic_auras.append("apsara_charm")
	var foe := _make_unit(Vector2i(6, 5), 1)

	# At 25% the charm must not land on the very first turn every time, but
	# must land within a generous window. Sampling both ends keeps the check
	# honest about which failure it caught.
	var first_turn_hits := 0
	var ever_hit := false
	for _trial in 20:
		foe.status_effects.clear()
		CombatManager._process_auras(apsara)
		if foe.has_status("Charmed"):
			first_turn_hits += 1
	if first_turn_hits == 20:
		_fail("a 25%% chance payload landed on all 20 first turns — the chance "
			+ "is not being rolled")
	foe.status_effects.clear()
	for _i in 60:
		CombatManager._process_auras(apsara)
		if foe.has_status("Charmed"):
			ever_hit = true
			break
	if not ever_hit:
		_fail("a 25%% chance payload never landed across 60 turns")
	_cleanup([apsara, foe])
	_done()
