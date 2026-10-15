class_name TooltipText
## TooltipText - builds the words that go inside hover tooltips.
##
## Every function here is static and returns a plain String, so the UI code
## only has to do `some_label.tooltip_text = TooltipText.status(...)` and the
## project-wide tooltip theme (resources/themes/global_theme.tres) does the
## drawing. Keeping the text-building in one place, away from the nodes, also
## means a headless verifier can build the same strings with real data and
## check them without ever opening a window — see tools/verify_tooltips.gd.
##
## Nothing here invents rules. Each line is read from data (statuses.json,
## equipment_tables.json, spells.json) or mirrors a rule the combat code
## actually applies, with a comment saying where that rule lives.


# ============================================
# STATUS EFFECTS
# ============================================

## Readable wording for the effect tokens in statuses.json `effects` lists.
## The numbers here are the ones CombatUnit._get_status_stat_bonus() really
## applies (attack_bonus is +10 accuracy there, and so on). Tokens that are
## not listed fall back to the token itself with underscores turned to spaces,
## so a new status still says *something* true rather than nothing.
const EFFECT_LABELS: Dictionary = {
	"fire_damage_per_turn": "fire damage each turn",
	"poison_damage_per_turn": "poison damage each turn",
	"physical_damage_per_turn": "physical damage each turn",
	"black_damage_per_turn": "black damage each turn",
	"heal_per_turn": "HP healed each turn",
	"skip_turn": "Skips next turn",
	"skip_next_action": "Loses 1 action",
	"cannot_move": "Cannot move",
	"immobilized": "Cannot move",
	"cannot_act": "Cannot act",
	"cannot_cast": "Cannot cast spells",
	"silenced": "Cannot cast spells",
	"cannot_attack": "Cannot attack",
	"cannot_be_targeted": "Cannot be targeted",
	"cannot_die": "Cannot die",
	"hp_cannot_drop_below_1": "HP cannot drop below 1",
	"random_movement": "Moves randomly",
	"random_target": "Attacks random targets",
	"flee_from_source": "Flees from whoever caused it",
	"attack_bonus": "+10 accuracy",
	"defense_bonus": "+10 armor",
	"defense_penalty": "-10 armor",
	"attack_penalty": "-10 accuracy",
	"speed_bonus": "+2 movement",
	"initiative_bonus": "+10 initiative",
	"movement_reduced_50": "Movement halved",
	"melee_hit_chance_halved": "Melee accuracy halved",
	"ranged_hit_chance_halved": "Ranged accuracy halved",
	"armor_reduced_50": "Armor reduced by 50%",
	"armor_reduced": "Armor reduced",
	"attack_breaks_invisibility": "Breaks on attacking",
	"breaks_on_offensive_action": "Breaks on any offensive action",
	"treats_caster_as_ally": "Treats the caster as an ally",
	"will_not_attack_caster": "Will not attack the caster",
	"death_on_expire": "Dies when it runs out",
	"damage_on_expire": "Bursts when it runs out",
	"bleed_on_expire": "Bleeds when it runs out",
	"spawn_fungal_spawn_on_expire": "Spawns a creature when it runs out",
	"focus_save_on_damage": "Focus save on each hit, or lose actions",
	"immune_to_ground_effects": "Immune to ground effects",
}

## Tokens that the tooltip states in its own line instead of as a bullet.
const _EFFECTS_SHOWN_ELSEWHERE: Array[String] = ["save_at_end_of_turn"]


## Full tooltip for ONE status on a unit.
##
## `status_name` is the statuses.json name ("Burning"). `entry` is the live
## entry from unit.status_effects — {status, duration, value, ...} — which is
## where the REMAINING duration lives; pass {} to describe the status in the
## abstract. `def` is the statuses.json definition; when it is left empty it
## is fetched from CombatManager, which holds the loaded table.
static func status(status_name: String, entry: Dictionary = {}, def: Dictionary = {}) -> String:
	if def.is_empty():
		def = CombatManager.get_status_definition(status_name)
	var lines: Array[String] = []

	# Header: the name, then whether it helps or hurts ("buff" / "debuff").
	var header: String = status_name.replace("_", " ")
	var kind: String = str(def.get("type", ""))
	if kind != "":
		header += " (%s)" % kind
	lines.append(header)

	# Description, where statuses.json has one (39 of 187 do).
	var description: String = str(def.get("description", ""))
	if description != "":
		lines.append(description)

	# Remaining duration.
	var duration_line: String = _status_duration_line(entry, def)
	if duration_line != "":
		lines.append(duration_line)

	# What it does, one bullet per effect token.
	for bullet in _status_effect_bullets(entry, def):
		lines.append("  • " + bullet)

	# What it does to others: hitting back, a field around the bearer, and
	# jumping to neighbours. Each is structured data on the status.
	var retaliation_line: String = _status_retaliation_line(def.get("retaliation", {}))
	if retaliation_line != "":
		lines.append(retaliation_line)
	for aura_line in _status_aura_lines(def):
		lines.append(aura_line)
	var spread_line: String = _status_spread_line(def.get("spread", {}))
	if spread_line != "":
		lines.append(spread_line)

	# How to get rid of it.
	var save_type: String = str(def.get("save_type", ""))
	if save_type != "":
		var when: String = " at end of turn" \
			if "save_at_end_of_turn" in def.get("effects", []) else ""
		lines.append("Save: %s%s" % [save_type, when])
	if def.has("dispellable") and not bool(def.get("dispellable", true)):
		lines.append("Cannot be dispelled")
	else:
		var methods: Array = def.get("dispel_methods", [])
		if not methods.is_empty():
			var clean: Array[String] = []
			for m in methods:
				clean.append(str(m).replace("_", " "))
			lines.append("Cured by: " + ", ".join(clean))

	return "\n".join(lines)


## Several statuses at once — the little icon row over a unit's head shows
## all of them in one label, so its tooltip lists all of them.
static func status_list(entries: Array) -> String:
	var blocks: Array[String] = []
	for entry in entries:
		blocks.append(status(str(entry.get("status", "?")), entry))
	return "\n\n".join(blocks)


## "3 turns remaining", "Permanent", or "" when nothing useful can be said.
## duration_type comes from statuses.json; the remaining count from the entry.
static func _status_duration_line(entry: Dictionary, def: Dictionary) -> String:
	var duration_type: String = str(def.get("duration_type", "turns"))
	match duration_type:
		"permanent":
			return "Permanent"
		"until_save":
			return "Lasts until saved against"
		"until_destroyed":
			return "Lasts until destroyed"
		"instant":
			return ""
	var remaining: int = int(entry.get("duration", 0))
	if remaining > 0:
		return "%d turn%s remaining" % [remaining, "" if remaining == 1 else "s"]
	# Describing the status with no live entry: fall back to its default.
	var default_turns: int = int(def.get("default_duration", 0))
	if entry.is_empty() and default_turns > 0:
		return "Usually lasts %d turn%s" % [default_turns, "" if default_turns == 1 else "s"]
	return ""


## One readable line per effect token. Damage and healing over time are given
## their numbers — the per-instance `value` wins over the table's
## damage_per_turn, exactly as CombatManager._process_status_effects() does.
static func _status_effect_bullets(entry: Dictionary, def: Dictionary) -> Array[String]:
	var bullets: Array[String] = []
	for token in def.get("effects", []):
		var fx: String = str(token)
		if fx in _EFFECTS_SHOWN_ELSEWHERE:
			continue
		var label: String = str(EFFECT_LABELS.get(fx, fx.replace("_", " ").capitalize()))
		if fx.ends_with("damage_per_turn"):
			var dmg: int = int(def.get("damage_per_turn", 0))
			if int(entry.get("value", 0)) > 0:
				dmg = int(entry.get("value", 0))
			if dmg > 0:
				label = "%d %s" % [dmg, label]
		elif fx == "heal_per_turn":
			var heal = def.get("heal_per_turn", 0)
			if heal is bool:
				heal = 0   # a few old entries wrote true/false here
			var amount: int = int(heal) if int(heal) > 0 else int(entry.get("value", 0))
			if amount > 0:
				label = "%d %s" % [amount, label]
		if not label in bullets:
			bullets.append(label)
	# Resistances the status grants or takes away. These were effect strings
	# with a label each ("Immune to physical"); they are structured data on
	# the status now, so one line per key covers them all.
	for key in def.get("grants_resistance", {}):
		bullets.append(_resistance_bullet(str(key), float(def["grants_resistance"][key])))
	for key in def.get("grants_vulnerability", {}):
		bullets.append(_resistance_bullet(str(key), -float(def["grants_vulnerability"][key])))
	return bullets


## "Hits back at melee attackers: 10 air damage, 30% chance of Stunned (1 turn)".
## Reads the same `retaliation` keys CombatManager's on-hit code applies
## (the block that handles "Retaliation, declared on the status"): range,
## damage, element, reflect_pct, status, status_duration, status_chance.
static func _status_retaliation_line(retal: Dictionary) -> String:
	if retal.is_empty():
		return ""
	var parts: Array[String] = []
	var element: String = DamageType.display_name(str(retal.get("element", "physical"))).to_lower()
	var hit: int = int(retal.get("damage", 0))
	if hit > 0:
		parts.append("%d %s damage" % [hit, element])
	var reflect_pct: int = int(retal.get("reflect_pct", 0))
	if reflect_pct > 0:
		parts.append("reflects %d%% of the damage taken as %s" % [reflect_pct, element])
	var give: String = str(retal.get("status", "")).replace("_", " ")
	if give != "":
		var turns: int = int(retal.get("status_duration", 1))
		var status_text: String = "%s (%d turn%s)" % [give, turns, "" if turns == 1 else "s"]
		var chance: float = float(retal.get("status_chance", 1.0))
		if chance < 1.0:
			status_text = "%d%% chance of %s" % [roundi(chance * 100.0), status_text]
		parts.append(status_text)
	if parts.is_empty():
		return ""
	var who: String = "melee attackers" if str(retal.get("range", "melee")) == "melee" else "any attacker"
	return "Hits back at %s: %s" % [who, ", ".join(parts)]


## One line per aura the status emits, read from auras.json through
## AuraSystem — "Aura: Soothing Presence (allies within 2): heals 5 each turn".
static func _status_aura_lines(def: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for aura_id in AuraSystem._aura_ids_of(def):
		var adef: Dictionary = AuraSystem.get_definition(aura_id)
		if adef.is_empty():
			continue
		var radius: int = int(adef.get("radius", 2))
		var affects: String = str(adef.get("affects", "allies"))
		var who: String = "self" if affects == "self" else (
			"everyone" if affects == "all" else affects)
		if bool(adef.get("self_included", false)) and affects != "self":
			who += " and self"
		var reach: String = "the whole battlefield" if radius >= 20 else "within %d" % radius
		var effects: Array[String] = []
		for payload in adef.get("payloads", []):
			var text: String = _aura_payload_text(payload)
			if text != "":
				effects.append(text)
		lines.append("Aura: %s (%s %s): %s" % [str(adef.get("name", aura_id)), who, reach,
			", ".join(effects) if not effects.is_empty() else "no effect"])
	return lines


## Words for one aura payload — the kinds AuraSystem.PAYLOAD_KINDS lists.
static func _aura_payload_text(payload: Dictionary) -> String:
	var amount = payload.get("amount", 0)
	match str(payload.get("kind", "")):
		"grant_status":
			var sname: String = str(payload.get("status", "")).replace("_", " ")
			var text: String = sname
			var chance: float = float(payload.get("chance", 1.0))
			if chance < 1.0:
				text = "%d%% chance of %s" % [roundi(chance * 100.0), sname]
			var save_spec: Dictionary = payload.get("save", {})
			if not save_spec.is_empty():
				text += " (%s save DC %d)" % [str(save_spec.get("attribute", "focus")).capitalize(),
					int(save_spec.get("dc", 12))]
			return text + " each turn"
		"heal":
			return "heals %d each turn" % int(amount)
		"damage":
			return "%d %s damage each turn" % [int(amount),
				DamageType.display_name(str(payload.get("element", "physical"))).to_lower()]
		"stat":
			return "%+d %s" % [int(amount), str(payload.get("stat", "")).replace("_", " ")]
		"max_hp":
			return "%+d max HP" % int(amount)
		"damage_taken_pct":
			var only: String = str(payload.get("only", ""))
			return "%+d%% %sdamage taken" % [int(amount), (only + " ") if only != "" else ""]
		"resistance":
			return "%+d%% %s resistance" % [int(amount),
				DamageType.display_name(str(payload.get("type", ""))).to_lower()]
	return ""


## "Can spread to an adjacent unit (15% chance each turn)". The chance words
## are turned into numbers by CombatManager._spread_chance_to_float(), the
## same function _process_status_spread() uses.
static func _status_spread_line(spread: Dictionary) -> String:
	if spread.is_empty():
		return ""
	var chance: float = CombatManager._spread_chance_to_float(str(spread.get("chance", "none")))
	if chance <= 0.0:
		return ""
	var declared_range = spread.get("range", "melee")
	var where: String = "an adjacent unit"
	if (declared_range is int or declared_range is float) and int(declared_range) > 1:
		where = "a unit within %d tiles" % int(declared_range)
	return "Can spread to %s (%d%% chance each turn)" % [where, roundi(chance * 100.0)]


## One tooltip line for a status's resistance key: "Immune to fire",
## "+25% physical resistance", "-50% ice resistance". `key` may be a scope —
## `all` reads as "all damage", `non_physical` as "non-physical damage".
static func _resistance_bullet(key: String, amount: float) -> String:
	var what: String
	match key:
		"all":
			what = "all damage"
		"non_physical":
			what = "non-physical damage"
		_:
			what = DamageType.display_name(key).to_lower()
	if amount >= Resistance.DECLARED_IMMUNITY:
		return "Immune to %s" % what
	return "%+d%% %s resistance" % [int(amount), what]


# ============================================
# TURN ORDER
# ============================================

## Tooltip for a name in the turn-order list: who it is, how hurt, and why
## they sit where they do in the order (initiative).
static func turn_order_unit(unit: Node) -> String:
	var lines: Array[String] = []
	lines.append(str(unit.unit_name))
	if "unit_archetype" in unit and str(unit.unit_archetype) != "":
		lines.append(str(unit.unit_archetype))
	lines.append("HP: %d/%d" % [unit.current_hp, unit.max_hp])
	if unit.max_mana > 0:
		lines.append("Mana: %d/%d" % [unit.current_mana, unit.max_mana])
	lines.append("Actions: %d/%d" % [unit.actions_remaining, unit.max_actions])
	if unit.has_method("get_initiative"):
		lines.append("Initiative: %d" % unit.get_initiative())
	if unit.is_bleeding_out:
		lines.append("Bleeding out: %d turn%s left"
			% [unit.bleed_out_turns, "" if unit.bleed_out_turns == 1 else "s"])

	# Short status list — name and turns left. The full wording is one hover
	# away on the unit itself; repeating it here would make a wall of text.
	if not unit.status_effects.is_empty():
		lines.append("")
		for entry in unit.status_effects:
			var sname: String = str(entry.get("status", "?")).replace("_", " ")
			var turns: int = int(entry.get("duration", 0))
			if turns > 0:
				sname += " (%d turn%s)" % [turns, "" if turns == 1 else "s"]
			lines.append(sname)
	return "\n".join(lines)


# ============================================
# BATTLE GRID TILES
# ============================================

## What standing on a terrain effect does at the start of your turn, built
## from CombatGrid.TERRAIN_HAZARDS — the same table
## CombatManager._process_terrain_effects() applies, so the words cannot drift
## from the rule. `value` is the tile's effect_value (its damage or healing).
## Examples: "5 fire damage and Burning at turn start",
##           "2 black damage at turn start, 30% chance of Cursed".
static func terrain_hazard_text(effect: int, value: int) -> String:
	var hazard: Dictionary = CombatGrid.TERRAIN_HAZARDS.get(effect, {})
	if hazard.is_empty():
		return ""
	if bool(hazard.get("blocks_sight", false)):
		return "Blocks line of sight"
	if bool(hazard.get("heals", false)):
		return "Heals %d at turn start" % value

	var damage_type: String = str(hazard.get("damage_type", ""))
	var status_name: String = str(hazard.get("status", "")).replace("_", " ")
	var chance: float = float(hazard.get("status_chance", 1.0))
	var text: String = ""
	if damage_type != "":
		text = "%d %s damage" % [value, DamageType.display_name(damage_type).to_lower()]
		if status_name != "" and chance >= 1.0:
			text += " and " + status_name
		text += " at turn start"
		if status_name != "" and chance < 1.0:
			text += ", %d%% chance of %s" % [roundi(chance * 100.0), status_name]
	elif status_name != "":
		# No damage — just the status (ice, wet ground).
		if chance < 1.0:
			text = "%d%% chance of %s at turn start" % [roundi(chance * 100.0), status_name]
		else:
			text = "%s at turn start" % status_name
	if bool(hazard.get("water", false)):
		text += "; Water Walking ignores it"
	return text


## Which spell school draws +25% spellpower from casting while standing on
## each effect — CombatManager's terrain affinity block in the spellpower
## calculation. Blessed and cursed ground also weaken the opposed school.
const TERRAIN_EFFECT_SCHOOL: Dictionary = {
	CombatGrid.TerrainEffect.FIRE: "Fire",
	CombatGrid.TerrainEffect.ICE: "Water",
	CombatGrid.TerrainEffect.WET: "Water",
	CombatGrid.TerrainEffect.STORMY: "Air",
	CombatGrid.TerrainEffect.POISON: "Earth",
	CombatGrid.TerrainEffect.ACID: "Earth",
	CombatGrid.TerrainEffect.VOID: "Space",
	CombatGrid.TerrainEffect.BLESSED: "White",
	CombatGrid.TerrainEffect.CURSED: "Black",
}

## "The spirits of the living water answer readily here: +25% spellpower" —
## or "" when this spell gets no summoning terrain bonus on this ground.
## The rule is CombatManager.summon_terrain_affinity_for(), the same one the
## cast applies.
static func summon_terrain_line(spell: Dictionary, overworld_terrain: int) -> String:
	var affinity: Dictionary = CombatManager.summon_terrain_affinity_for(spell, overworld_terrain)
	if affinity.is_empty():
		return ""
	return "The spirits of %s answer readily here: +%d%% spellpower" % [
		str(affinity.get("label", "this place")),
		roundi(CombatManager.SUMMON_TERRAIN_BONUS_PCT * 100.0)]


const TILE_TYPE_TEXT: Dictionary = {
	CombatGrid.TileType.WALL: "Wall — impassable, blocks line of sight",
	CombatGrid.TileType.PIT: "Pit — impassable",
	CombatGrid.TileType.WATER: "Water",
	CombatGrid.TileType.DIFFICULT: "Difficult ground",
}


## Everything worth knowing about one tile of the battle grid, one fact per
## line: the ground it is, how it walks, what lies on it, how high it is, any
## hazard burning on it, and any zone laid over it. `zones` is the result of
## CombatManager.zones_at(pos), passed in so this stays testable without a
## running fight. Returns "" for a tile with nothing to say.
static func tile(grid: CombatGrid, pos: Vector2i, zones: Array = []) -> String:
	var t = grid.tiles.get(pos)
	if t == null:
		return ""
	var lines: Array[String] = []

	# Ground and passability. Plain floor on plains is the default and says
	# nothing, so it is left out to keep the common case quiet.
	var ground_name: String = Ground.name_of(t.ground) if not Ground.by_id(t.ground).is_empty() else ""
	var type_text: String = str(TILE_TYPE_TEXT.get(t.type, ""))
	var walk: String = ""
	if t.walkable and t.movement_cost > 1:
		walk = "costs %d movement" % t.movement_cost
	var ground_parts: Array[String] = []
	if ground_name != "" and (t.ground != 0 or type_text != "" or walk != ""):
		ground_parts.append(ground_name)
	if type_text != "":
		ground_parts.append(type_text)
	if walk != "":
		ground_parts.append(walk)
	if not ground_parts.is_empty():
		lines.append(" — ".join(ground_parts))

	# Obstacle (tree, rock...) and the cover it gives.
	var obs: Dictionary = grid.get_obstacle_at(pos)
	if not obs.is_empty():
		var obs_text: String = str(obs.name)
		if int(obs.hp) > 0:
			obs_text += " (HP: %d)" % int(obs.hp)
		if int(obs.cover_bonus) > 0:
			obs_text += " — +%d%% cover" % int(obs.cover_bonus)
		lines.append(obs_text)

	# Height. The bonus is RELATIVE — CombatGrid.get_height_advantage() is
	# attacker height minus target height — so it is stated per level above
	# the target rather than as a flat number for this tile.
	if t.height > 0:
		lines.append("Height %d — each level above a target: +5%% accuracy, +1 range, +damage" % t.height)

	# Terrain effect / hazard.
	if t.effect != CombatGrid.TerrainEffect.NONE:
		var eff_line: String = grid.get_effect_name(t.effect)
		if t.effect_duration > 0:
			eff_line += " (%d turn%s)" % [t.effect_duration, "" if t.effect_duration == 1 else "s"]
		elif t.effect_duration == -1:
			eff_line += " (lasting)"
		lines.append(eff_line)
		var what: String = terrain_hazard_text(t.effect, t.effect_value)
		if what != "":
			lines.append("  " + what)
		var school: String = str(TERRAIN_EFFECT_SCHOOL.get(t.effect, ""))
		if school != "":
			lines.append("  %s spells cast from here: +25%% spellpower" % school)
		# Who is spared — the same immunity rules _process_terrain_effects()
		# checks: flyers ignore everything, levitators only the harmful ones.
		var hazard: Dictionary = CombatGrid.TERRAIN_HAZARDS.get(t.effect, {})
		if bool(hazard.get("heals", false)):
			lines.append("  Flyers are untouched")
		elif not bool(hazard.get("blocks_sight", false)):
			lines.append("  Flyers and levitators are untouched")

	# Zones (mandalas, clouds, mud...). Traps are hidden by design and are
	# never named here — finding them is Thievery's job.
	for zone in zones:
		var zdef: Dictionary = zone.get("def", {})
		if bool(zdef.get("trap", false)):
			continue
		var ztext: String = str(zone.get("name", "Zone"))
		var turns: int = int(zone.get("turns_left", 0))
		if turns > 0:
			ztext += " (%d turn%s)" % [turns, "" if turns == 1 else "s"]
		lines.append(ztext)

	return "\n".join(lines)


## The tile tooltip while choosing where to move: the cover this tile would
## give (from CombatGrid.get_cover_info_at — pass {} when there is none or
## the tile is not a move destination) on top of everything tile() says.
## One label, so hazards still show while moving.
static func move_tile(grid: CombatGrid, pos: Vector2i, zones: Array = [],
		cover_info: Dictionary = {}) -> String:
	var lines: Array[String] = []
	if bool(cover_info.get("has_cover", false)):
		lines.append("+%d%% dodge vs ranged (cover: %s)"
			% [int(cover_info.get("dodge_bonus", 0)), str(cover_info.get("obstacle_name", ""))])
	var tile_text: String = tile(grid, pos, zones)
	if tile_text != "":
		lines.append(tile_text)
	return "\n".join(lines)


# ============================================
# ITEM SETS
# ============================================

## Readable names for the stat keys a set bonus may carry.
const _SET_STAT_NAMES: Dictionary = {
	"spellpower": "Spellpower", "max_mana": "Mana", "initiative": "Initiative",
	"max_hp": "HP", "damage": "Damage", "armor": "Armor", "dodge": "Dodge",
	"accuracy": "Accuracy", "crit_chance": "Crit Chance",
}


## "Set: Vajra & Bell — +3 Spellpower, +3 Mana, +2 Initiative when paired",
## built from ItemSystem.SET_BONUSES — the same table
## ItemSystem.calculate_equipment_stats() adds from. "" for an unknown set.
static func set_bonus(set_id: String) -> String:
	var set_def: Dictionary = ItemSystem.SET_BONUSES.get(set_id, {})
	if set_def.is_empty():
		return ""
	var parts: Array[String] = []
	var stats: Dictionary = set_def.get("stats", {})
	for key in stats:
		var label: String = str(_SET_STAT_NAMES.get(key, str(key).replace("_", " ").capitalize()))
		parts.append("%+d %s" % [int(stats[key]), label])
	return "Set: %s — %s when paired" % [str(set_def.get("name", set_id)), ", ".join(parts)]


# ============================================
# RITUAL IMPLEMENTS
# ============================================

## Skill id -> the school name spells.json uses. Same mapping as
## EnemySystem.SKILL_TO_SCHOOL.
const _SKILL_TO_SCHOOL: Dictionary = {
	"fire_magic": "Fire", "water_magic": "Water", "earth_magic": "Earth",
	"air_magic": "Air", "space_magic": "Space", "sorcery": "Sorcery",
	"enchantment": "Enchantment", "summoning": "Summoning",
	"white_magic": "White", "black_magic": "Black",
}


## The ritual meaning of a focus item, read from `ritual_metals` and
## `ritual_implements` in equipment_tables.json. A copper phurba serves fire
## through its metal and sorcery through its form, so it is the instrument for
## spells that are both. Returns "" for anything that is not a ritual
## implement, so callers can show the section only when it has something to say.
##
## A metal line is only shown when the item really carries that metal's skill
## bonus — the melong, for instance, is bronze but its bronze grants nothing,
## and saying otherwise would be a lie in a tooltip.
static func ritual_coding(item: Dictionary) -> String:
	if str(item.get("type", "")) != "focus":
		return ""
	var tables: Dictionary = ItemSystem.get_equipment_tables()
	var metals: Dictionary = tables.get("ritual_metals", {})
	var implements: Dictionary = tables.get("ritual_implements", {})
	var item_id: String = str(item.get("id", ""))
	var bonuses: Dictionary = item.get("skill_bonuses", {})
	var lines: Array[String] = []

	# --- The metal: which element it serves ---
	var metal_skill: String = ""
	var material: String = str(item.get("material", ""))
	if metals.has(material):
		var coding: Dictionary = metals[material]
		var grants: String = str(coding.get("grants", ""))
		if bonuses.has(grants):
			metal_skill = grants
			var element: String = str(coding.get("element", "")).capitalize()
			var skill_name: String = _skill_name(grants)
			var metal_name: String = material.replace("_", " ").capitalize()
			if element != "" and not skill_name.begins_with(element):
				# Conch, bone, turquoise: an element, but a rite rather than
				# that element's school.
				lines.append("%s belongs to %s, and serves %s." % [metal_name, element, skill_name])
			else:
				lines.append("%s serves %s." % [metal_name, skill_name])

	# --- The implement: which practice it is an instrument of ---
	# Matched on the id or name the same way verify_item_materials.gd does.
	var implement_key: String = ""
	var haystack: String = (item_id + " " + str(item.get("name", ""))).to_lower()
	for key in implements:
		if str(key).begins_with("_"):
			continue
		if str(key) in haystack:
			implement_key = str(key)
			break
	var implement_skill: String = ""
	if implement_key != "":
		var icoding: Dictionary = implements[implement_key]
		var article: String = "The " + implement_key
		if icoding.has("grants_skill"):
			implement_skill = str(icoding["grants_skill"])
			lines.append("%s is an instrument of %s." % [article, _skill_name(implement_skill)])
		elif icoding.has("grants_attribute"):
			lines.append("%s sharpens %s." % [article, str(icoding["grants_attribute"]).capitalize()])
		elif icoding.has("grants_stat"):
			# Only the melong today: magic_resistance_pct.
			lines.append("%s turns magic aside." % article)

	if lines.is_empty():
		return ""

	# --- Where the two meet: spells that draw on both ---
	var school_a: String = str(_SKILL_TO_SCHOOL.get(metal_skill, ""))
	var school_b: String = str(_SKILL_TO_SCHOOL.get(implement_skill, ""))
	if school_a != "" and school_b != "" and school_a != school_b:
		var both: Array[String] = _spells_of_both(school_a, school_b)
		if not both.is_empty():
			# "such as Ember and Firebolt" or "such as Ember, Firebolt and 18 more"
			var shown: Array[String] = []
			shown.assign(both.slice(0, 2))
			var named: String = " and ".join(shown)
			if both.size() > shown.size():
				named = "%s and %d more" % [", ".join(shown), both.size() - shown.size()]
			lines.append("Spells of both, such as %s, draw on each." % named)

	# --- Consecration grade (the id's prefix: plain .. legendary) ---
	# Malas run no consecration ladder — their material is their grade.
	if implement_key != "mala":
		var levels: Dictionary = tables.get("consecration_levels", {})
		for grade in levels:
			if item_id.begins_with(str(grade) + "_"):
				lines.append("Consecration: %s (%d of %d)"
					% [str(grade).capitalize(), int(levels[grade].get("magnitude", 0)), levels.size()])
				break

	return "\n".join(lines)


## "fire_magic" -> "Fire magic", "sorcery" -> "Sorcery".
static func _skill_name(skill_id: String) -> String:
	var words: String = skill_id.replace("_", " ")
	return words.substr(0, 1).to_upper() + words.substr(1)


## Spell names tagged with BOTH schools, lowest level first. Spells with
## exactly those two schools come before ones that carry a third, because
## they are the plainest example of the pairing.
static func _spells_of_both(school_a: String, school_b: String) -> Array[String]:
	var found: Array = []
	var spells: Dictionary = CharacterSystem.get_spell_database()
	for spell_id in spells:
		var spell = spells[spell_id]
		if typeof(spell) != TYPE_DICTIONARY:
			continue
		var schools: Array = spell.get("schools", [])
		if school_a in schools and school_b in schools:
			var extra: int = 0 if schools.size() == 2 else 1
			found.append([extra, int(spell.get("level", 99)), str(spell.get("name", spell_id))])
	# Sort by [extra schools, level, name] — plainest, lowest first.
	found.sort_custom(func(a, b):
		if a[0] != b[0]:
			return a[0] < b[0]
		if a[1] != b[1]:
			return a[1] < b[1]
		return a[2] < b[2])
	var names: Array[String] = []
	for f in found:
		names.append(f[2])
	return names
