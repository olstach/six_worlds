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

## A status says what it does as effects (spec §4.4): `while_active`
## modifies, `periodic` ticks, `triggers`, a `save`, a `spread`. Each line here
## is worded from those effects themselves (the describe_* functions below),
## so the tooltip can only say what the game does.

## Readable wording for a status's `flags` (the yes/no rules it switches on),
## one entry for EVERY name in EffectVocab.FLAGS (verify_tooltips'
## every_flag_has_words fails on a flag without one). `immune:<x>` is worded
## by describe_flags() itself. tools/content/sections/statuses.py reads this
## same dictionary for CONTENT.md, so a wording is changed here, once.
const FLAG_LABELS: Dictionary = {
	"attack_breaks_invisibility": "Breaks on attacking",
	"attack_damage_buff_when_ally_dies": "Hits harder when an ally dies",
	"attacks_closest_creature": "Attacks the closest creature",
	"attacks_have_miss_chance": "Its attacks may miss",
	"breaks_concentration": "Breaks concentration",
	"breaks_on_damage_from_source": "Ends if the one who caused it hurts it",
	"breaks_on_offensive_action": "Breaks on any offensive action",
	"can_move_through_enemies": "Can move through enemies",
	"cannot_act": "Cannot act",
	"cannot_attack": "Cannot attack",
	"cannot_be_targeted": "Cannot be targeted",
	"cannot_cast": "Cannot cast spells",
	"cannot_deal_physical": "Cannot deal physical damage",
	"cannot_die": "Cannot die",
	"cannot_make_weapon_attacks": "Cannot make weapon attacks",
	"cannot_move": "Cannot move",
	"cannot_target_enemies": "Cannot target enemies",
	"cannot_use_ranged": "Cannot use ranged attacks",
	"charm_chance_on_enemy_melee_approach": "May charm enemies that approach in melee",
	"controlled_by_caster": "Controlled by the caster",
	"copies_absorb_attacks": "Its copies absorb attacks",
	"counts_as_demoralized": "Counts as demoralized",
	"crit_vulnerability": "Vulnerable to critical hits",
	"damage_on_move_attempt": "Takes damage when it tries to move",
	"damage_taken_increase": "Takes more damage",
	"death_resistance": "Resists death",
	"disengaged_from_combat": "Is out of the fight",
	"flee_from_source": "Flees from whoever caused it",
	"focus_save_on_damage": "Focus save on each hit, or lose actions",
	"forced_movement_toward_target": "Is drawn toward its target",
	"grants_extra_action": "Grants an extra action",
	"grants_flight": "Can fly",
	"grants_stealth": "Hidden from sight",
	"hp_cannot_drop_below_1": "HP cannot drop below 1",
	"hp_shield": "Damage is taken from a shield first",
	"ignores_allegiance": "Ignores who is friend or foe",
	"immune_to_ground_effects": "Immune to ground effects",
	"immune_to_melee_unless_flyer": "Immune to melee, except from flyers",
	"immune_to_ranged": "Immune to ranged attacks",
	"immune_to_terrain_hazards": "Immune to terrain hazards",
	"immune_to_water_terrain": "Immune to water terrain",
	"increase_burning_damage_dealt": "Burning damage it deals is increased",
	"lifesteals_on_hit": "Heals from the damage it deals",
	"loses_flight": "Cannot fly",
	"must_attack_taunter": "Must attack whoever taunted it",
	"next_attack_misses": "Its next attack misses",
	"next_ranged_guaranteed_hit": "Its next ranged attack always hits",
	"prevents_teleportation": "Cannot teleport",
	"prone_chance_on_movement": "May fall prone when moving",
	"random_movement": "Moves randomly",
	"random_target": "Attacks random targets",
	"ranged_damage_reduction": "Takes less damage from ranged attacks",
	"remove_all_debuffs": "Removes every debuff when applied",
	"return_on_death_next_turn": "Returns next turn if it dies",
	"riposte_next_sword_attack": "Ripostes its next sword attack",
	"rooted": "Rooted in place",
	"share_healing_75_percent": "Shares 75% of healing with its bond",
	"skip_next_action": "Loses 1 action",
	"skip_turn": "Skips next turn",
	"spell_damage_reduction": "Takes less damage from spells",
	"stealth_bonus": "Harder to spot",
	"stun_chance_on_hit": "Its hits may stun",
	"treats_caster_as_ally": "Treats the caster as an ally",
	"will_not_attack": "Will not attack",
	"will_not_attack_caster": "Will not attack the caster",
}

## The word the header shows for each polarity.
const POLARITY_WORDS: Dictionary = {"positive": "buff", "negative": "debuff"}

## How a trigger's `on` reads, as the start of its line. A `struck` or
## `attacked_in_melee` with reach 1 reads "in melee" (see _when_words).
const TRIGGER_WORDS: Dictionary = {
	"expire": "When it runs out",
	"turn_start": "At the start of its turn",
	"turn_end": "At the end of its turn",
	"struck": "When struck",
	"hit": "When it hits",
	"attacked_in_melee": "When attacked in melee",
	"incoming_attack": "When attacked",
	"incoming_spell": "When targeted by a spell",
	"enemy_enters_reach": "When an enemy comes within reach",
	"ally_threatened": "When an ally is threatened",
}

## Who `to: "source"` is, by what set the trigger off.
const SOURCE_WORDS: Dictionary = {
	"struck": "the attacker", "attacked_in_melee": "the attacker",
	"incoming_attack": "the attacker", "incoming_spell": "the caster",
	"hit": "the unit it hit", "enemy_enters_reach": "the enemy that came close",
	"ally_threatened": "the threatening enemy",
}

## What a `periodic` effect's `when` reads as.
const PERIODIC_WORDS: Dictionary = {
	"turn_start": "at the start of each turn", "turn_end": "at the end of each turn",
}


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

	# Header: the name, then whether it helps or hurts ("buff" / "debuff"),
	# from the status's polarity.
	var header: String = status_name.replace("_", " ")
	var kind: String = str(POLARITY_WORDS.get(str(def.get("polarity", "")), ""))
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
	for trigger_line in _status_trigger_lines(entry, def):
		lines.append(trigger_line)
	for aura_line in _status_aura_lines(def):
		lines.append(aura_line)
	var spread_line: String = _status_spread_line(def.get("spread", {}))
	if spread_line != "":
		lines.append(spread_line)

	# How to get rid of it. The save is rolled as the carrier's turn comes
	# round (`when: turn_start`), i.e. at the end of the turn it lost.
	var own_save: Dictionary = def.get("save", {})
	if not own_save.is_empty():
		var when: String = " at end of turn" if str(own_save.get("when", "")) == "turn_start" else ""
		lines.append("Save: %s%s" % [str(own_save.get("stat", "")).capitalize(), when])
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
## The kind comes from the status's `duration`; the remaining count from the entry.
static func _status_duration_line(entry: Dictionary, def: Dictionary) -> String:
	var duration_type: String = str(def.get("duration", {}).get("kind", "turns"))
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
	var default_turns: int = int(def.get("duration", {}).get("base", 0))
	if entry.is_empty() and default_turns > 0:
		return "Usually lasts %d turn%s" % [default_turns, "" if default_turns == 1 else "s"]
	return ""


## The bullets under a status's header, every one worded by a describe_*
## function from the status's own fields: what it holds while on, what it does
## each turn, and the yes/no rules it switches on. (What it does when
## something happens to it is _status_trigger_lines.)
static func _status_effect_bullets(entry: Dictionary, def: Dictionary) -> Array[String]:
	var bullets: Array[String] = []
	var groups: Array[PackedStringArray] = [
		describe_effects(def.get("while_active", []), entry),
		describe_periodic(def.get("periodic", {}), entry),
		describe_flags(def.get("flags", [])),
	]
	for group in groups:
		for line in group:
			if not line in bullets:
				bullets.append(line)
	return bullets


# ============================================
# THE EFFECT LANGUAGE IN WORDS
# ============================================
#
# describe_effects, describe_flags, describe_periodic and describe_triggers
# turn the shared effect language (scripts/effects/effect_vocab.gd) into
# sentences. A status's tooltip is built from nothing else, and a spell's will
# be too (stage 3). tools/content/sections/statuses.py is a Python port of the
# parts statuses.json uses, for the CONTENT.md context line: change a wording
# here and change it there.

## One sentence per effect, in the order given. `entry` is the live status
## entry (its `value` and `stacks` are what a borrowed magnitude reads); pass
## {} to describe in the abstract, which says where a number is a default.
## `on` is the trigger the effects answer, so `to: "source"` can be named
## ("the attacker") and event.damage read as damage taken or dealt.
##   {"op": "damage", "amount": 5, "type": "fire"}   ->  "5 fire damage"
##   a lasting modify                                ->  "+15 dodge"
static func describe_effects(effects: Array, entry: Dictionary = {}, on: String = "") -> PackedStringArray:
	var out := PackedStringArray()
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var text: String = _effect_sentence(effect, entry, on, "")
		if text != "":
			out.append(text)
	return out


## One line per flag, from FLAG_LABELS. `immune:<word>` reads "Immune to
## <word>". A flag with no entry reads as its id with underscores replaced
## (verify_tooltips fails on any such flag, so this is only a net).
static func describe_flags(flags: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for flag in flags:
		var id: String = str(flag)
		var text: String
		if id.begins_with(EffectVocab.IMMUNE_FLAG_PREFIX):
			text = "Immune to " + id.trim_prefix(EffectVocab.IMMUNE_FLAG_PREFIX).replace("_", " ")
		else:
			text = str(FLAG_LABELS.get(id, id.replace("_", " ").capitalize()))
		if not text in out:
			out.append(text)
	return out


## A status's `periodic` {when, effects}: each effect with when it happens.
##   "5 fire damage at the start of each turn"
static func describe_periodic(periodic: Dictionary, entry: Dictionary = {}) -> PackedStringArray:
	var out := PackedStringArray()
	var when_words: String = str(PERIODIC_WORDS.get(str(periodic.get("when", "turn_start")),
		"at the start of each turn"))
	for effect in periodic.get("effects", []):
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var text: String = _effect_sentence(effect, entry, "", when_words)
		if text != "":
			out.append(text)
	return out


## A status's `triggers`, one line each: "When struck in melee: 10 lightning
## damage to the attacker, 30% chance of Stunned (1 turn) on the attacker".
## Limits, reach and chance sit in brackets after the "when".
static func describe_triggers(triggers: Array, entry: Dictionary = {}) -> PackedStringArray:
	var out := PackedStringArray()
	for trigger in triggers:
		if typeof(trigger) != TYPE_DICTIONARY:
			continue
		var on: String = str(trigger.get("on", ""))
		var parts := describe_effects(trigger.get("effects", []), entry, on)
		if parts.is_empty():
			continue
		var line: String = _when_words(trigger) + _trigger_brackets(trigger) + ": " + ", ".join(parts)
		out.append(line)
	return out


## "When struck in melee": a `struck` with reach 1 only answers melee.
static func _when_words(trigger: Dictionary) -> String:
	var on: String = str(trigger.get("on", ""))
	if on == "struck" and typeof(trigger.get("reach", null)) in [TYPE_INT, TYPE_FLOAT] \
			and int(trigger["reach"]) == 1:
		return "When struck in melee"
	return str(TRIGGER_WORDS.get(on, on.replace("_", " ").capitalize()))


## " (50% chance, within 2 tiles, up to 3 times a turn, once per attacker)".
static func _trigger_brackets(trigger: Dictionary) -> String:
	var bits: Array[String] = []
	if trigger.has("chance"):
		bits.append("%d%% chance" % roundi(float(trigger["chance"])))
	var on: String = str(trigger.get("on", ""))
	var reach = trigger.get("reach", null)
	# Reach 1 on a `struck` is already said as "in melee".
	if reach != null and not (on == "struck" and typeof(reach) != TYPE_STRING and int(reach) == 1):
		if str(reach) == "weapon":
			bits.append("within weapon reach")
		else:
			bits.append("within %d tile%s" % [int(reach), "" if int(reach) == 1 else "s"])
	var limit: Dictionary = trigger.get("limit", {})
	if not limit.is_empty():
		var count: int = int(limit.get("count", 1))
		var times: String = "once" if count == 1 else "up to %d times" % count
		var text: String = "%s a turn" % times
		if bool(limit.get("once_per_source", false)):
			text += ", once per attacker"
		bits.append(text)
	if bits.is_empty():
		return ""
	return " (" + ", ".join(bits) + ")"


## One effect as a sentence. `when_words` ("at the start of each turn") goes
## right after what it does, ahead of any growth clause.
static func _effect_sentence(effect: Dictionary, entry: Dictionary, on: String, when_words: String) -> String:
	var op: String = str(effect.get("op", ""))
	var text: String = ""
	var note: String = _borrow_note(effect.get("amount", null), entry)
	var who: String = _source_words(effect, on)
	# The `note` ("or the spell's value") goes after who it hits, so it reads
	# "10 lightning damage to the attacker (plus the spell's value)".
	match op:
		"damage":
			var amount = effect.get("amount", 0)
			var kind: String = _damage_kind_words(effect.get("type", "physical"))
			if typeof(amount) == TYPE_DICTIONARY and str(amount.get("from", "")) == "event.damage":
				var taken: String = "taken" if on in ["struck", "attacked_in_melee", "incoming_attack", "incoming_spell"] else "dealt"
				var share: String = "%d%% of the damage %s as %s damage" % [int(amount.get("pct", 100)), taken, kind]
				text = ("reflects " + share) if taken == "taken" else share
				if amount.has("min"):
					text += " (at least %d)" % int(amount["min"])
			elif typeof(amount) == TYPE_DICTIONARY and str(amount.get("pct_of", "")) == "target.max_hp":
				text = "%d%% of max HP as %s damage" % [int(amount.get("value", 0)), kind]
				if float(amount.get("value", 0)) >= 100.0:
					text = "it dies (%s damage)" % kind
			else:
				text = "%s %s damage" % [_amount_words(amount, entry), kind]
				if who == "":
					text += note
			if who != "":
				text += " to " + who
				if not (typeof(amount) == TYPE_DICTIONARY and str(amount.get("from", "")) == "event.damage"):
					text += note
		"heal":
			var amount = effect.get("amount", 0)
			if typeof(amount) == TYPE_STRING and str(amount) == "full":
				text = "heals to full HP"
			else:
				text = "heals %s HP" % _amount_words(amount, entry)
				if who == "":
					text += note
			if who != "":
				text += " for " + who
				text += note
		"modify":
			text = _modify_sentence(effect, entry, note)
		"status":
			text = _status_sentence(effect, who)
		"attack":
			text = "makes a free attack against " + (who if who != "" else "the other unit")
			if effect.has("power_pct"):
				text += " at %d%% power" % int(effect["power_pct"])
		"negate":
			text = "the attack misses"
		"reflect":
			text = "it is turned back on whoever sent it"
		"move":
			var tiles: int = int(effect.get("tiles", 1))
			var mover: String = "moves itself" if str(effect.get("to", "")) == "caster" \
				else "moves " + (who if who != "" else "the target")
			text = "%s %d tile%s (%s)" % [mover, tiles, "" if tiles == 1 else "s",
				str(effect.get("mode", "")).replace("_", " ")]
		"summon":
			var count: int = int(effect.get("count", 1))
			var what: String = str(effect.get("as", "")).replace("_", " ")
			text = ("a %s emerges" % what) if count == 1 else ("%d %s emerge" % [count, what])
		"kill":
			text = "kills it outright"
		"zone":
			text = "lays a %s zone" % str(effect.get("zone", "")).replace("_", " ")
		"resurrect":
			text = "raises the fallen"
	if text == "":
		return ""
	if when_words != "":
		text += " " + when_words
	# Growth: a scale per turn the status has lasted, or per something else.
	var scale: Dictionary = effect.get("scale", {})
	if not scale.is_empty():
		var per: String = str(scale.get("per", ""))
		if per == "turn_active":
			text += ", %s more for each turn it has lasted" % _num(float(scale.get("amount", 0)))
		elif per != "":
			text += ", more with %s" % per.replace("_", " ")
	# A chance on a non-status effect; a status words its own (see below).
	if effect.has("chance") and op != "status" and float(effect["chance"]) < 100.0:
		text += " (%d%% chance)" % roundi(float(effect["chance"]))
	return text


## "Stunned (1 turn)", "30% chance of Stunned (1 turn) on the attacker, unless
## already Stunned", "removes Burning".
static func _status_sentence(effect: Dictionary, who: String) -> String:
	var action: String = str(effect.get("action", ""))
	if action != "apply":
		var verbs: Dictionary = {"remove": "removes", "steal": "steals", "transfer": "transfers",
			"convert": "converts"}
		var names: Array = effect.get("select", {}).get("names", [])
		var what: String = ", ".join(PackedStringArray(names)).replace("_", " ") if not names.is_empty() else "statuses"
		return "%s %s" % [str(verbs.get(action, action)), what]
	var give: String = str(effect.get("status", "")).replace("_", " ")
	var duration = effect.get("duration", 1)
	var turns_text: String
	if typeof(duration) in [TYPE_INT, TYPE_FLOAT]:
		turns_text = "%d turn%s" % [int(duration), "" if int(duration) == 1 else "s"]
	elif str(duration) == "combat":
		turns_text = "the whole fight"
	else:
		turns_text = "the spell's duration"
	var text: String = "%s (%s)" % [give, turns_text]
	if effect.has("chance") and float(effect["chance"]) < 100.0:
		text = "%d%% chance of %s" % [roundi(float(effect["chance"])), text]
	if who != "":
		text += " on " + who
	for condition in effect.get("if", []):
		if typeof(condition) == TYPE_DICTIONARY and condition.has("target_lacks"):
			text += ", unless already %s" % str(condition["target_lacks"]).replace("_", " ")
	return text


## "the attacker" for `to: "source"` in a trigger; "" when the effect names no
## other unit (it acts on the container's own carrier).
static func _source_words(effect: Dictionary, on: String) -> String:
	# An `attack` names its victim with `target`; every other op uses `to`.
	var other: String = str(effect.get("target", "")) if str(effect.get("op", "")) == "attack" \
		else str(effect.get("to", ""))
	if other != "source":
		return ""
	return str(SOURCE_WORDS.get(on, "the other unit"))


## "fire", or "fire and black" for a split.
static func _damage_kind_words(type) -> String:
	if typeof(type) == TYPE_DICTIONARY:
		var names: Array[String] = []
		for part in type:
			names.append(DamageType.display_name(str(part)).to_lower())
		return " and ".join(names)
	return DamageType.display_name(str(type)).to_lower()


## "5", "2.5".
static func _num(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


## A magnitude in words. A number reads as itself; {min,max} as "3 to 5". A
## borrowed value ({from, pct?, default?, add?}) reads as the number it works
## out to for this entry (the entry's `value` when it has one, else the
## default, else just `add`), or as what it borrows from.
static func _amount_words(amount, entry: Dictionary = {}) -> String:
	match typeof(amount):
		TYPE_INT, TYPE_FLOAT:
			return _num(float(amount))
		TYPE_STRING:
			return str(amount)
		TYPE_DICTIONARY:
			if amount.has("min") and amount.has("max") and not amount.has("from"):
				return "%s to %s" % [_num(float(amount["min"])), _num(float(amount["max"]))]
			if amount.has("base"):
				var base: String = _num(float(amount["base"]))
				if amount.has("per_spellpower"):
					base += " (+%s per spellpower)" % _num(float(amount["per_spellpower"]))
				return base
			if amount.has("from"):
				return _borrowed_words(amount, entry)
	return "?"


## The number a borrowed magnitude works out to, or what it is borrowed from.
static func _borrowed_words(amount: Dictionary, entry: Dictionary) -> String:
	var from: String = str(amount["from"])
	if from == "status.value" or from == "status.stacks":
		# Worked out as the game works it out. In the abstract (no live entry)
		# the status's own default stands in for the spell's value.
		var ctx := EffectContext.new()
		ctx.status_entry = entry
		var spec: Dictionary = amount.duplicate()
		return _num(float(EffectResolver.magnitude(spec, ctx, null)))
	if from == "event.damage":
		return "%d%% of the damage" % int(amount.get("pct", 100))
	# caster.skill.leadership, target.attribute.focus ...: "50% of the caster's Leadership".
	var who: String = from.get_slice(".", 0)
	var path: String = from.substr(who.length() + 1)
	var shown: String = path.get_slice(".", path.get_slice_count(".") - 1).replace("_", " ").capitalize()
	var pct: int = int(amount.get("pct", 100))
	var text: String = "%d%% of the %s's %s" % [pct, who, shown]
	if amount.has("add"):
		text += " + " + _num(float(amount["add"]))
	return text


## A short note after a sentence, saying where its number comes from, when
## that is not already plain: "(or the spell's value)" for a default, "(plus
## the spell's value)" for an `add`. Empty with a live entry, which has its
## own number.
static func _borrow_note(amount, entry: Dictionary) -> String:
	if typeof(amount) != TYPE_DICTIONARY or str(amount.get("from", "")) != "status.value" \
			or not entry.is_empty():
		return ""
	if amount.has("default"):
		return " (or the spell's value)"
	if amount.has("add"):
		return " (plus the spell's value)"
	return " (the spell's value)"


## A real minus sign, for "−10 armor" (the hyphen reads as a dash).
const MINUS: String = "\u2212"

## Readable names for the `stat.` values a status may hold.
const STAT_WORDS: Dictionary = {
	"initiative": "initiative", "movement": "movement", "accuracy": "accuracy",
	"dodge": "dodge", "damage": "damage", "armor": "armor",
	"crit_chance": "crit chance", "spellpower": "spellpower",
}


## A `modify` as a sentence. A lasting one reads as what it holds ("+10
## accuracy", "-2 Focus", "Movement halved", "Fire resistance +25%", "Immune
## to all damage"); an instant resource change as a verb ("restores 5 HP").
static func _modify_sentence(effect: Dictionary, entry: Dictionary, note: String) -> String:
	var value: String = str(effect.get("value", ""))
	var mode: String = str(effect.get("mode", ""))
	var amount_raw = effect.get("amount", 0)
	var ns: String = value.get_slice(".", 0)
	var name: String = value.get_slice(".", 1)
	var shown: String = _amount_words(amount_raw, entry)
	var is_number: bool = amount_raw is int or amount_raw is float
	var amount: float = float(amount_raw) if is_number else 0.0
	# Instant changes to a resource.
	if ns == "resource":
		var pool: String = {"hp": "HP", "mana": "mana", "stamina": "stamina",
			"temp_hp": "temporary HP"}.get(name, name)
		match mode:
			"restore":
				return "restores %s %s%s" % [shown, pool, note]
			"drain":
				return "drains %s %s%s" % [shown, pool, note]
			"absorb":
				return "takes %s %s from the target%s" % [shown, pool, note]
	var plus_minus: String = MINUS if mode == "drain" else "+"
	var signed_text: String = plus_minus + shown
	if is_number and is_equal_approx(amount, roundf(amount)):
		signed_text = ("%+d" % int(-amount if mode == "drain" else amount)).replace("-", MINUS)
	match ns:
		"resist":
			var what: String = _resist_name(name)
			if mode == "set" and is_number:
				if amount >= Resistance.DECLARED_IMMUNITY:
					return "Immune to %s" % what
				return "%s resistance set to %d%%" % [what.substr(0, 1).to_upper() + what.substr(1), int(amount)]
			if is_number and mode == "fortify" and amount >= Resistance.DECLARED_IMMUNITY:
				return "Immune to %s" % what
			return "%s resistance %s%%%s" % [what.substr(0, 1).to_upper() + what.substr(1), signed_text, note]
		"stat":
			var word: String = str(STAT_WORDS.get(name, name.replace("_", " ")))
			match mode:
				"fortify", "drain":
					return "%s %s%s" % [signed_text, word, note]
				"multiply":
					if is_number and is_equal_approx(amount, 0.5):
						return "%s halved" % word.capitalize()
					return "%s x%s" % [word.capitalize(), shown]
				"set":
					return "%s set to %s" % [word.capitalize(), shown]
		"attribute", "skill":
			var label: String = name.replace("_", " ").capitalize()
			match mode:
				"fortify", "drain":
					return "%s %s%s" % [signed_text, label, note]
				"damage":
					var until: String = describe_cleared_by(effect.get("cleared_by", []), value)
					return "%s%s %s (until %s)" % [MINUS, shown, label, until]
	return ""


## "fire", "all damage", "magic damage": what a `resist.<name>` covers.
static func _resist_name(key: String) -> String:
	match key:
		"all":
			return "all damage"
		"magic":
			return "magic damage"
	return DamageType.display_name(key).to_lower()


## What clears lasting damage, from a `cleared_by` list: "full rest or White
## magic 5". An empty list is the default, a full rest or a restore of the value.
static func describe_cleared_by(cleared_by: Array, value: String = "") -> String:
	var clauses: Array = cleared_by
	if clauses.is_empty():
		clauses = [{"rest": "full"}, {"restore": value}]
	var parts: Array[String] = []
	for clause in clauses:
		if typeof(clause) != TYPE_DICTIONARY:
			continue
		for kind in clause:
			var want = clause[kind]
			match str(kind):
				"rest":
					parts.append(("%s rest" % str(want)))
				"heal":
					var rule: Dictionary = want if typeof(want) == TYPE_DICTIONARY else {}
					var school: String = str(rule.get("school", "")).trim_suffix("_magic").capitalize()
					var text: String = (school + " magic") if school != "" else "healing"
					if int(rule.get("min_level", 0)) > 0:
						text += " %d" % int(rule["min_level"])
					parts.append(text)
				"restore":
					parts.append("a restore")
				"cleanse":
					var rule: Dictionary = want if typeof(want) == TYPE_DICTIONARY else {}
					parts.append("a cleanse of %s" % str(rule.get("category", "its cause")))
	return " or ".join(parts)


## The lines for a status's triggers, each with the unit-reaction wording of
## describe_triggers (kept as a function of its own for status()).
static func _status_trigger_lines(entry: Dictionary, def: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for line in describe_triggers(def.get("triggers", []), entry):
		lines.append(line)
	return lines


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


## "Can spread to an adjacent unit (15% chance each turn)", from the status's
## `spread` {to, reach?, chance, when}, as _process_status_spread() reads it.
static func _status_spread_line(spread: Dictionary) -> String:
	if spread.is_empty():
		return ""
	var chance: float = float(spread.get("chance", 0))
	if chance <= 0.0:
		return ""
	var where: String = "an adjacent unit"
	if int(spread.get("reach", 1)) > 1:
		where = "a unit within %d tiles" % int(spread.get("reach", 1))
	return "Can spread to %s (%d%% chance each turn)" % [where, roundi(chance)]


# ============================================
# LASTING DAMAGE (party screen)
# ============================================

## One line listing a character's lasting damage (`damaged_values`) and what
## clears it: "Focus −2 (until full rest or White magic 5)". Entries on the
## same value with the same cure are added together. Returns "" when the
## character has none, so the party screen shows no line at all.
static func lasting_damage_line(character: Dictionary) -> String:
	var parts: Array[String] = []
	var totals: Dictionary = {}   # "label|until" -> amount, in first-seen order
	for entry in character.get("damaged_values", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var value: String = str(entry.get("value", ""))
		var label: String = value.get_slice(".", 1).replace("_", " ").capitalize()
		var until: String = describe_cleared_by(entry.get("cleared_by", []), value)
		var key: String = "%s|%s" % [label, until]
		totals[key] = float(totals.get(key, 0.0)) + float(entry.get("amount", 0))
	for key in totals:
		parts.append("%s %s%s (until %s)" % [str(key).get_slice("|", 0), MINUS,
			_num(float(totals[key])), str(key).get_slice("|", 1)])
	return "; ".join(parts)


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
	var also: String = str(hazard.get("also_status", ""))
	if also != "":
		text = text.replace(" at turn start", " and %s at turn start" % also)
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
