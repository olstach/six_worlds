extends Node
## Headless verification for the enemy XP generation system.
##
## Run: godot --headless res://tools/verify_enemy_xp.tscn
##      godot --headless res://tools/verify_enemy_xp.tscn -- --table
##
## It runs as a scene rather than via --script because --script starts a bare
## SceneTree with no autoloads, and every check here needs EnemySystem and
## CharacterSystem to exist. Exits non-zero if any assertion fails.

var failures: int = 0


func _ready() -> void:
	_check_budgets()
	_check_resolution()
	_check_composition()
	_check_spending()
	_dump_table()
	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK")
		get_tree().quit(0)


func fail(msg: String) -> void:
	failures += 1
	printerr("  FAIL: " + msg)


func expect(cond: bool, msg: String) -> void:
	if not cond:
		fail(msg)


## Property access on a missing member is a hard script error that aborts the
## calling function — and the run would then report OK having checked nothing.
## Everything here probes with `in` first so a missing piece is a FAIL, not a crash.
func _has(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if p.get("name", "") == prop:
			return true
	return false


func _check_budgets() -> void:
	print("-- budgets --")
	if not _has(EnemySystem, "budgets"):
		fail("EnemySystem has no `budgets` property")
		return
	var b: Dictionary = EnemySystem.budgets
	expect(not b.is_empty(), "EnemySystem.budgets is empty")
	expect(b.get("realm_base", {}).has("animal"), "realm_base missing animal")
	expect(float(b.get("reward_fraction", 0.0)) > 0.0, "reward_fraction not loaded")

	# Every tier used by any archetype must have a multiplier, or budgets
	# silently collapse to 1.0 for it.
	var tiers: Dictionary = b.get("tier_multipliers", {})
	for aid in EnemySystem.archetypes:
		if aid.begins_with("_"):
			continue
		var t: String = EnemySystem.archetypes[aid].get("tier", "")
		expect(tiers.has(t), "archetype '%s' has tier '%s' with no multiplier" % [aid, t])


func _check_resolution() -> void:
	print("-- budget resolution --")
	if not _has(EnemySystem, "budgets"):
		return
	var band_ids: Array = []
	for band in EnemySystem.budgets.get("bands", []):
		band_ids.append(String(band.get("id", "")))

	# every encounter must resolve to a positive budget, a known band and a tier
	var realms := {}
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var realm: String = EnemySystem.encounters[eid].get("realm", "")
		expect(realm != "", "encounter '%s' has no realm stamped" % eid)
		realms[realm] = int(realms.get(realm, 0)) + 1
		var r: Dictionary = EnemySystem.resolve_party_budget(eid, realm)
		expect(int(r["xp"]) > 0, "encounter '%s' resolved to xp %s" % [eid, r["xp"]])
		expect(band_ids.has(String(r["band"])), "encounter '%s' rolled unknown band" % eid)
		expect(String(r["tier"]) != "", "encounter '%s' resolved an empty tier" % eid)
	print("   encounters per realm: %s" % [realms])

	# band distribution must match the configured weights
	var counts := {}
	var N := 30000
	for i in range(N):
		var b: String = EnemySystem.roll_band()
		counts[b] = int(counts.get(b, 0)) + 1
	var total_w: int = 0
	for band in EnemySystem.budgets.get("bands", []):
		total_w += int(band.get("weight", 0))
	for band in EnemySystem.budgets.get("bands", []):
		var id: String = String(band.get("id", ""))
		var want: float = float(band.get("weight", 0)) / float(total_w)
		var got: float = float(counts.get(id, 0)) / float(N)
		expect(absf(got - want) < 0.02, "band '%s' rolled %.3f, expected %.3f" % [id, got, want])
	print("   band distribution ok: %s" % [counts])

	# the derived tier must actually rescue boss fights, which was the whole
	# reason for deriving rather than defaulting to devil
	var boss_found := 0
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var t: String = EnemySystem.resolve_encounter_tier(EnemySystem.encounters[eid])
		if t == "boss":
			boss_found += 1
	expect(boss_found > 0, "no encounter derived a boss tier — derivation is not working")
	print("   encounters resolving to boss tier: %d" % boss_found)


func _check_composition() -> void:
	print("-- party composition --")
	if not _has(EnemySystem, "party_archetypes"):
		fail("EnemySystem has no `party_archetypes` property")
		return
	expect(not EnemySystem.party_archetypes.is_empty(), "party_archetypes is empty")

	var seen_templates := {}
	for band in ["common", "uncommon", "rare"]:
		for i in range(600):
			var members: Array = EnemySystem.roll_party_composition(band)
			expect(members.size() > 0, "band '%s' produced an empty party" % band)
			var heroes := 0
			var top := 0
			for m in members:
				expect(int(m.get("share", 0)) > 0, "member with non-positive share")
				top = maxi(top, int(m.get("share", 0)))
				if m.get("is_hero", false):
					heroes += 1
			# a hero is the strict top share, the sole member, or an all_heroes party
			if heroes > 0 and heroes < members.size():
				var at_top := 0
				for m in members:
					if int(m["share"]) == top:
						at_top += 1
				expect(at_top == 1 and heroes == 1,
					"band '%s': %d heroes with %d tied for top share" % [band, heroes, at_top])
			seen_templates[band] = int(seen_templates.get(band, 0)) + members.size()

	# gated templates must never appear at common: swarm caps at 8, and the
	# gated ones are the only way to exceed the ungated size range
	for i in range(3000):
		var members: Array = EnemySystem.roll_party_composition("common")
		expect(members.size() <= 8, "common band produced %d members" % members.size())
		for m in members:
			expect(int(m["share"]) <= 3, "common band produced share %d" % int(m["share"]))
	print("   composition ok across all three bands")


func _check_spending() -> void:
	print("-- xp spending --")
	if not CharacterSystem.has_method("spend_xp_budget"):
		fail("CharacterSystem has no spend_xp_budget()")
		return
	if not CharacterSystem.has_method("create_blank_character"):
		fail("CharacterSystem has no create_blank_character()")
		return

	for budget in [50, 200, 800, 1800, 4000, 12000]:
		var c: Dictionary = CharacterSystem.create_blank_character()
		var spent: int = CharacterSystem.spend_xp_budget(
			c, budget, {"strength": 3, "finesse": 2}, ["unarmed", "might"])

		expect(spent <= budget, "budget %d: spent %d, over budget" % [budget, spent])
		expect(spent >= int(budget * 0.9),
			"budget %d: spent only %d, should absorb nearly all of it" % [budget, spent])

		for sk in c.get("skills", {}):
			expect(int(c["skills"][sk]) <= CharacterSystem.SKILL_MAX_LEVEL,
				"budget %d: skill %s exceeded the cap" % [budget, sk])

		var attr_total: int = 0
		for a in c.get("attributes", {}):
			attr_total += int(c["attributes"][a])
		expect(attr_total > 70, "budget %d: attributes never rose above baseline" % budget)

	# a build whose skills cap must still absorb the rest into attributes
	var big: Dictionary = CharacterSystem.create_blank_character()
	var big_spent: int = CharacterSystem.spend_xp_budget(
		big, 20000, {"strength": 3}, ["unarmed"])
	expect(big_spent >= 18000,
		"20000 budget only absorbed %d — overflow is not reaching attributes" % big_spent)
	print("   spending absorbs its budget at every scale")

	# show the shape of a build at a few budgets, so a reviewer can see whether
	# the spend produces a character or a pile of numbers
	for budget in [200, 800, 1800, 4140]:
		var c: Dictionary = CharacterSystem.create_blank_character()
		var spent: int = CharacterSystem.spend_xp_budget(
			c, budget, {"strength": 3, "constitution": 2, "finesse": 2},
			["unarmed", "might", "armor"])
		var attrs := ""
		for a in ["strength", "finesse", "constitution", "focus", "awareness", "charm", "luck"]:
			attrs += "%s%d " % [a.substr(0, 3), int(c["attributes"][a])]
		print("   %5d XP (spent %5d)  %s | skills %s" % [budget, spent, attrs, c["skills"]])


func _dump_table() -> void:
	if not "--table" in OS.get_cmdline_user_args():
		return
	print("\n=== ENCOUNTER TABLE ===")
