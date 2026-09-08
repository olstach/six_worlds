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
	_check_enemies()
	_check_heroes()
	_check_reward()
	_check_equipment()
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
	expect(b.get("realm_median", {}).has("animal"), "realm_median missing animal")
	expect(float(b.get("reward_fraction", 0.0)) > 0.0, "reward_fraction not loaded")

	# Rank no longer sets difficulty — it only picks the draw pool — so what has to
	# be complete now is the ladder, and the aliases the content already speaks in.
	var steps: Dictionary = b.get("difficulty_multipliers", {})
	for w in ["trivial", "very_easy", "easy", "medium", "challenging", "dangerous", "lethal"]:
		expect(steps.has(w), "difficulty ladder missing '%s'" % w)
	for a in b.get("difficulty_aliases", {}):
		var target: String = String(b["difficulty_aliases"][a])
		expect(steps.has(target), "alias '%s' points at unknown step '%s'" % [a, target])
	for aid in EnemySystem.archetypes:
		if aid.begins_with("_"):
			continue
		var r: int = EnemySystem.archetype_rank(EnemySystem.archetypes[aid])
		expect(r >= 1 and r <= 4, "archetype '%s' has rank %d outside 1-4" % [aid, r])


func _check_resolution() -> void:
	print("-- budget resolution --")
	if not _has(EnemySystem, "budgets"):
		return
	var band_ids: Array = []
	for band in EnemySystem.budgets.get("bands", []):
		band_ids.append(String(band.get("id", "")))

	# every encounter must resolve to a positive budget, a known band and a rank range
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
		var rr: Array = r["rank_range"]
		expect(rr.size() == 2 and int(rr[0]) >= 1 and int(rr[0]) <= int(rr[1]),
			"encounter '%s' resolved a bad rank range %s" % [eid, str(rr)])
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

	# the derived range must actually rescue boss fights, which was the whole
	# reason for deriving rather than defaulting to devil
	var boss_found := 0
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var t: int = int(EnemySystem.resolve_encounter_rank_range(EnemySystem.encounters[eid])[1])
		if t >= 4:
			boss_found += 1
	expect(boss_found > 0, "no encounter derived rank 4 — derivation is not working")
	print("   encounters resolving to rank 4: %d" % boss_found)


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
	var overflow_c: Dictionary = CharacterSystem.create_blank_character()
	var overflow_spent: int = CharacterSystem.spend_xp_budget(
		overflow_c, 20000, {"strength": 3}, ["unarmed"])
	expect(overflow_spent >= 18000,
		"20000 budget only absorbed %d — overflow is not reaching attributes" % overflow_spent)
	print("   spending absorbs its budget at every scale")

	# show the shape of a build at a few budgets, so a reviewer can see whether
	# the spend produces a character or a pile of numbers
	for budget in [200, 800, 1800, 4140, 12000]:
		var br: float = EnemySystem.breadth_for_budget(budget)
		var c: Dictionary = CharacterSystem.create_blank_character()
		var spent: int = CharacterSystem.spend_xp_budget(
			c, budget, {"strength": 3, "constitution": 2, "finesse": 2},
			["unarmed", "might", "armor"], 0.6, br)
		var attrs := ""
		for a in ["strength", "finesse", "constitution", "focus", "awareness", "charm", "luck"]:
			attrs += "%s%d " % [a.substr(0, 3), int(c["attributes"][a])]
		print("   %5d XP (spent %5d, breadth %.2f)  %s" % [budget, spent, br, attrs])
		print("        skills %s" % [c["skills"]])
		expect(spent >= int(budget * 0.9), "budget %d spent only %d with breadth" % [budget, spent])

	# breadth must actually broaden: a large budget should lift the attributes
	# the archetype ignores, and pick up skills off the priority list
	var big: Dictionary = CharacterSystem.create_blank_character()
	CharacterSystem.spend_xp_budget(big, 4140, {"strength": 3},
		["unarmed"], 0.6, EnemySystem.breadth_for_budget(4140))
	expect(int(big["attributes"]["awareness"]) > 10,
		"breadth did not lift an unweighted attribute (awareness still 10)")
	expect(big["skills"].size() > 1,
		"breadth produced no skills outside the priority list")

	# and a small budget must stay focused
	var small: Dictionary = CharacterSystem.create_blank_character()
	CharacterSystem.spend_xp_budget(small, 200, {"strength": 3},
		["unarmed"], 0.6, EnemySystem.breadth_for_budget(200))
	expect(int(small["attributes"]["awareness"]) == 10,
		"a 200 XP enemy should be focused, but awareness rose")


func realm_of(e: Dictionary) -> String:
	return String(e.get("realm", "animal"))


func _check_enemies() -> void:
	print("-- enemy generation --")
	var by_realm := {}
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var realm: String = EnemySystem.encounters[eid].get("realm", "animal")
		var party: Array = EnemySystem.generate_encounter(eid, "", realm)
		expect(party.size() > 0, "%s produced no enemies" % eid)
		var total := 0
		for e in party:
			expect(int(e.get("xp_earned", 0)) > 0, "%s: enemy has no xp_earned" % eid)
			expect(String(e.get("birth", "")) != "", "%s: enemy has no birth" % eid)
			expect(int(e.get("max_hp", 0)) > 0, "%s: enemy has no hp" % eid)
			total += int(e.get("xp_earned", 0))
		by_realm[realm] = int(by_realm.get(realm, 0)) + 1
	print("   generated every encounter: %s" % [by_realm])

	# an encounter named after a creature should contain that creature
	var named := 0
	var honoured := 0
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var e: Dictionary = EnemySystem.encounters[eid]
		if e.get("fixed", false) or e.has("groups"):
			continue
		var family: Array = EnemySystem._encounter_family_tokens(eid)
		if family.is_empty():
			continue
		# Only meaningful when a family archetype exists that COULD have filled a
		# slot — same realm, inside the rank range, compatible region. Where the
		# family has nothing in range the fallback to the general pool is correct.
		var family_exists := false
		var region: String = String(e.get("region", "any"))
		var rank_range: Array = EnemySystem.resolve_encounter_rank_range(e)
		for aid in EnemySystem.archetypes:
			var a: Dictionary = EnemySystem.archetypes[aid]
			var a_rank: int = EnemySystem.archetype_rank(a)
			if a.get("realm", "") != realm_of(e):
				continue
			if a_rank < int(rank_range[0]) or a_rank > int(rank_range[1]):
				continue
			var a_region: String = String(a.get("region", "any"))
			if region != "any" and region != "" and a_region != "any" and a_region != region:
				continue
			var role_ok := false
			for role in e.get("roles", {}):
				if String(role) in a.get("roles", []):
					role_ok = true
			if not role_ok:
				continue
			for token in family:
				if token in aid:
					family_exists = true
		if not family_exists:
			continue
		named += 1
		var realm: String = e.get("realm", "animal")
		var hit := false
		for member in EnemySystem.generate_encounter(eid, "", realm):
			for token in family:
				if token in String(member.get("archetype_id", "")):
					hit = true
		if hit:
			honoured += 1

	# A preference, not a guarantee: a family may cover one of an encounter's
	# roles and not the other, and the rolled party may only use the other.
	expect(float(honoured) / float(maxi(named, 1)) >= 0.85,
		"only %d of %d named encounters contained their namesake" % [honoured, named])
	print("   %d/%d named encounters contain their namesake" % [honoured, named])

	# every enemy must carry a known disposition, and a party must agree with itself
	var disp_counts := {}
	var split_parties := 0
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var realm2: String = EnemySystem.encounters[eid].get("realm", "animal")
		var party: Array = EnemySystem.generate_encounter(eid, "", realm2)
		var seen := {}
		for member in party:
			var disp: String = String(member.get("disposition", ""))
			expect(disp in ["hostile", "wary", "neutral"],
				"%s: member has disposition '%s'" % [eid, disp])
			disp_counts[disp] = int(disp_counts.get(disp, 0)) + 1
			seen[disp] = true
		if seen.size() > 1:
			split_parties += 1
	expect(split_parties == 0, "%d parties disagreed with themselves about disposition" % split_parties)

	# the two encounters authored as neutral must actually come out neutral
	for eid in ["animal_mriga_herd", "animal_kapota_flock"]:
		if EnemySystem.encounters.has(eid):
			var party: Array = EnemySystem.generate_encounter(eid, "", "animal")
			if not party.is_empty():
				expect(String(party[0].get("disposition", "")) == "neutral",
					"%s should be neutral, got '%s'" % [eid, party[0].get("disposition", "")])
	print("   dispositions: %s" % [disp_counts])

	# Role slots no archetype can fill. Not a code fault — the content simply
	# lacks an archetype at that region/rank/role — but it silently drops the
	# encounter to a generic fallback, so it should stay visible.
	var unfillable: Array[String] = []
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var e: Dictionary = EnemySystem.encounters[eid]
		if e.get("fixed", false) or e.has("groups"):
			continue
		var realm: String = e.get("realm", "")
		var region: String = String(e.get("region", "any"))
		var rr: Array = EnemySystem.resolve_encounter_rank_range(e)
		for role in e.get("roles", {}):
			if EnemySystem._pick_archetype_for_role(String(role), region, rr, realm) == "":
				unfillable.append("%s (%s/%s/rank %d-%d)" % [eid, region, role,
					int(rr[0]), int(rr[1])])
	if not unfillable.is_empty():
		print("   %d role slots no archetype can fill:" % unfillable.size())
		for u in unfillable:
			print("      %s" % u)

	# authored group encounters must keep their shape: the same member count
	# every time, and unequal shares between the groups
	var grouped: String = ""
	for eid in EnemySystem.encounters:
		if not eid.begins_with("_") and EnemySystem.encounters[eid].has("groups"):
			grouped = eid
			break
	if grouped != "":
		var realm: String = EnemySystem.encounters[grouped].get("realm", "animal")
		var sizes := {}
		var xps := []
		for i in range(40):
			var party: Array = EnemySystem.generate_encounter(grouped, "", realm)
			sizes[party.size()] = true
			if i == 0:
				for e in party:
					xps.append(int(e.get("xp_earned", 0)))
		expect(sizes.size() == 1,
			"authored group encounter '%s' varied in size: %s" % [grouped, sizes.keys()])
		xps.sort()
		expect(xps.size() > 1 and xps[0] != xps[-1],
			"authored group encounter '%s' split its budget evenly — ranks were not honoured" % grouped)
		print("   authored groups preserved (%s: fixed size, uneven shares %s)" % [grouped, xps])


func _check_heroes() -> void:
	print("-- heroes --")
	var parties := 0
	var with_hero := 0
	var hero_share_ok := true
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var realm: String = EnemySystem.encounters[eid].get("realm", "animal")
		for i in range(6):
			var party: Array = EnemySystem.generate_encounter(eid, "", realm)
			if party.is_empty():
				continue
			parties += 1
			var ids := {}
			var hero_xp := 0
			var mook_max := 0
			var heroes := 0
			for e in party:
				if e.get("is_hero", false):
					heroes += 1
					expect(String(e.get("hero_id", "")) != "", "hero with empty hero_id in %s" % eid)
					expect(not ids.has(e["hero_id"]), "duplicate hero_id in one party (%s)" % eid)
					ids[e["hero_id"]] = true
					hero_xp = maxi(hero_xp, int(e.get("xp_earned", 0)))
				else:
					mook_max = maxi(mook_max, int(e.get("xp_earned", 0)))
			if heroes > 0:
				with_hero += 1
				# a lone hero must be worth more than any mook beside it
				if heroes == 1 and party.size() > 1 and hero_xp < mook_max:
					if hero_share_ok:
						printerr("   first offender: %s hero_xp=%d mook_max=%d size=%d"
							% [eid, hero_xp, mook_max, party.size()])
						for e in party:
							printerr("      %s xp=%d hero=%s" % [
								e.get("archetype_id", "?"), int(e.get("xp_earned", 0)),
								e.get("is_hero", false)])
					hero_share_ok = false
	expect(parties > 0, "no parties generated")
	expect(with_hero > 0, "no party ever produced a hero")
	expect(hero_share_ok, "a hero was worth less XP than a mook beside it")
	print("   %d/%d parties carried a hero" % [with_hero, parties])

	# a boss encounter must crown its boss, not one of the honour guard
	if EnemySystem.encounters.has("animal_boss_simha_king"):
		var boss_party: Array = EnemySystem.generate_encounter(
			"animal_boss_simha_king", "forest", "animal")
		var line := ""
		var crowned := ""
		for e in boss_party:
			line += "%s(%d)%s " % [e.get("archetype_id", "?"), int(e.get("xp_earned", 0)),
				"*" if e.get("is_hero", false) else ""]
			if e.get("is_hero", false):
				crowned = String(e.get("archetype_id", ""))
		print("   simha king: %s" % line)
		expect(crowned == "animal_rakshasa_maneater",
			"boss encounter crowned '%s' rather than the maneater" % crowned)


func _check_reward() -> void:
	print("-- reward --")
	var fraction: float = float(EnemySystem.budgets.get("reward_fraction", 0.0))
	expect(fraction > 0.0 and fraction < 1.0, "reward_fraction out of range: %f" % fraction)

	# division must not lose more than rounding, at any party size
	for size in [1, 2, 3, 4, 6]:
		var enemy_party_xp := 1800
		var total := int(round(float(enemy_party_xp) * fraction))
		var per_member := maxi(1, int(float(total) / float(size)))
		expect(per_member * size <= total + size,
			"size %d: division lost more than rounding" % size)
		expect(per_member >= 1, "size %d: per-member XP rounded to zero" % size)

	# what a real encounter actually pays, per realm
	for pair in [["hell", 200], ["hungry_ghost", 700], ["animal", 1800]]:
		var xp := int(pair[1])
		var total := int(round(float(xp) * fraction))
		print("   %s common (%d XP): party gains %d — solo %d, each of four %d"
			% [pair[0], xp, total, total, int(total / 4.0)])


func _check_equipment() -> void:
	print("-- equipment --")
	var mismatches := 0
	var checked := 0
	var with_food := 0
	var with_spare := 0

	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var realm: String = EnemySystem.encounters[eid].get("realm", "animal")
		for e in EnemySystem.generate_encounter(eid, "", realm):
			var w: Dictionary = e.get("equipped_weapon", {})
			var wtype: String = String(w.get("type", ""))
			if wtype == "" or wtype == "unarmed":
				continue
			checked += 1

			# the wielded weapon must match a weapon skill the character has
			var skill_for := ""
			for skill in EnemySystem.SKILL_TO_WEAPON:
				if wtype in EnemySystem.SKILL_TO_WEAPON[skill]:
					skill_for = String(skill)
			# Only a fault when the character HAS weapon skills and is still
			# holding something else. A caster with no weapon training keeps
			# whatever its archetype hands it, which is correct.
			var has_any_weapon_skill := false
			for sk in EnemySystem.SKILL_TO_WEAPON:
				if int(e.get("skills", {}).get(sk, 0)) > 0:
					has_any_weapon_skill = true
			if has_any_weapon_skill and skill_for != "" \
					and int(e.get("skills", {}).get(skill_for, 0)) == 0:
				mismatches += 1

			var weapons := 0
			for entry in e.get("inventory", []):
				var iid: String = String(entry.get("item_id", ""))
				if iid == "rations":
					with_food += 1
				var item: Dictionary = ItemSystem.get_item(iid)
				if String(item.get("slot", "")).begins_with("weapon"):
					weapons += 1
			if weapons > 1:
				with_spare += 1

	expect(checked > 0, "no armed enemies generated")
	expect(mismatches == 0,
		"%d of %d armed enemies carry a weapon they have no skill for" % [mismatches, checked])
	print("   %d armed enemies: 0 skill mismatches, %d carry food, %d carry a spare weapon"
		% [checked, with_food, with_spare])

	# tools: a practitioner should be holding their trade, not a borrowed blade
	var tool_holders := 0
	var tool_mismatch := 0
	var consumable_carriers := 0
	var kit_scales := true
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var realm: String = EnemySystem.encounters[eid].get("realm", "animal")
		for e in EnemySystem.generate_encounter(eid, "", realm):
			var w: Dictionary = e.get("equipped_weapon", {})
			if String(w.get("type", "")) == "tool":
				tool_holders += 1
				# the tool must support a skill they are actually best at
				var bonus_skills: Dictionary = w.get("skill_bonuses", {})
				var ok := false
				for sk in bonus_skills:
					if int(e.get("skills", {}).get(sk, 0)) > 0:
						ok = true
				if not ok:
					tool_mismatch += 1
			for entry in e.get("inventory", []):
				var iid: String = String(entry.get("item_id", ""))
				if iid in ["health_potion", "mana_potion", "healing_herb", "raw_reagents"]:
					consumable_carriers += 1
					break
	expect(tool_mismatch == 0,
		"%d characters carry a tool for a skill they do not have" % tool_mismatch)
	print("   %d carry a trade tool instead of a weapon, %d carry consumables"
		% [tool_holders, consumable_carriers])

	# the kit budget must rise with XP
	var small: int = EnemySystem.equipment_budget_for_xp(200)
	var large: int = EnemySystem.equipment_budget_for_xp(4140)
	expect(large > small * 5, "kit budget does not scale with XP (%d vs %d)" % [small, large])
	print("   kit budget: 200 XP -> %d gold, 4140 XP -> %d gold" % [small, large])

	# the kit must actually be spent, and must stay inside its budget
	var overspent := 0
	var samples := 0
	var carried_total := 0
	var accessories := 0
	var armour_pieces := 0
	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var realm: String = EnemySystem.encounters[eid].get("realm", "animal")
		for e in EnemySystem.generate_encounter(eid, "", realm):
			var budget: int = EnemySystem.equipment_budget_for_xp(int(e.get("xp_earned", 0)))
			var spent: int = 0
			for entry in e.get("inventory", []):
				var item: Dictionary = ItemSystem.get_item(String(entry.get("item_id", "")))
				var slot: String = String(item.get("slot", ""))
				spent += int(item.get("value", 0)) * int(entry.get("quantity", 1))
				if slot == "talisman" or slot.begins_with("trinket") or slot.begins_with("ring"):
					accessories += 1
				elif slot in ["chest", "head", "legs", "feet", "hand_l", "back"]:
					armour_pieces += 1
			samples += 1
			carried_total += spent
			# generous margin: consumables and archetype-guaranteed items sit
			# outside the pool, so this only catches gross overspend
			if spent > budget * 6 + 400:
				overspent += 1
	expect(overspent == 0, "%d of %d enemies carry gear far beyond their kit budget"
		% [overspent, samples])
	print("   %d enemies: avg kit value %d, %d armour pieces, %d accessories"
		% [samples, int(carried_total / maxi(samples, 1)), armour_pieces, accessories])
	expect(accessories > 0, "no enemy ever received an accessory")


func _dump_table() -> void:
	if not "--table" in OS.get_cmdline_user_args():
		return
	print("\n=== ENCOUNTER TABLE ===")
	for realm in ["hell", "hungry_ghost", "animal", "domain"]:
		print("\n## %s" % realm)
		var ids: Array = []
		for eid in EnemySystem.encounters:
			if eid.begins_with("_") and true:
				continue
			if EnemySystem.encounters[eid].get("realm", "") == realm:
				ids.append(eid)
		ids.sort()
		for eid in ids:
			var party: Array = EnemySystem.generate_encounter(eid, "", realm)
			if party.is_empty():
				continue
			var total: int = 0
			for e in party:
				total += int(e.get("xp_earned", 0))
			var line := "  %-32s %d members %6d XP  " % [eid, party.size(), total]
			for e in party:
				line += "[%s %s %d%s] " % [
					e.get("birth", "?"), e.get("archetype_id", "?"),
					int(e.get("xp_earned", 0)), " HERO" if e.get("is_hero", false) else ""]
			print(line)
