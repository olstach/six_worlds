extends Node2D
class_name CombatUnit
## CombatUnit - Represents a unit in tactical combat
##
## Wraps character data and provides combat-specific state:
## - Grid position and movement
## - Action tracking
## - Health and status
## - Visual representation

# Unit identification
var unit_name: String = "Unit"
var unit_archetype: String = ""  # Shown as a subtitle below the name (enemies only)
var team: int = 0  # CombatManager.Team

# Grid position
var grid_position: Vector2i = Vector2i.ZERO

# Combat state
var current_hp: int = 100
var max_hp: int = 100
var current_mana: int = 50
var max_mana: int = 50
var current_stamina: int = 50
var max_stamina: int = 50
var actions_remaining: int = 2
var max_actions: int = 2

# Status
var is_bleeding_out: bool = false
var bleed_out_turns: int = 0
var is_dead: bool = false
var moved_this_turn: bool = false  # Set when unit moves; cleared at turn start (used by open_the_gate perk)
var momentum_stacks: int = 0       # Consecutive axe hits; cleared on miss or turn start (momentum perk)
var unarmed_hit_stacks: int = 0    # Consecutive unarmed hits; cleared on miss or turn start (keep_hitting perk)
var stationary_stacks: int = 0     # Turns without moving; incremented/reset at turn start (tidal_patience perk)
var last_attacker: Node = null     # Last unit that dealt damage to this unit (used for risen_dead talisman perk)
var dagger_attacks_this_turn: int = 0    # Dagger attacks made this turn; cleared at turn start (too_fast_to_count perk)
var ranged_attacks_this_turn: int = 0    # Ranged attacks made this turn; cleared at turn start (one_breath_one_arrow perk)
var knife_storm_proc_this_turn: bool = false  # Prevents knife_storm from proccing twice in one turn
var enemies_hit_this_combat: Array = []  # Tracks enemies hit for cheap_shot (first-attack crit bonus)
var hit_back_ready: bool = false          # Set when taking damage with hit_back_harder perk; grants +20% damage on next melee attack
var sorcery_kill_bonus_ready: bool = false  # Set when killing with Sorcery (spell_like_a_knife perk); next spell gets +50% Spellpower
var is_marked: bool = false               # Set by call_the_shot (Leadership 1); first ally to attack this unit gains +15% acc/dmg, then mark clears
var status_effects: Array = []  # Active status effects on this unit

# Active skill cooldowns: perk_id -> turns remaining (0 = ready)
var skill_cooldowns: Dictionary = {}

# Mantras being chanted: perk_id -> turns_active (increments each turn)
var active_mantras: Dictionary = {}

# Consumable buffs
var charm_buff: Dictionary = {}  # {school, mana_reduction, spellpower_bonus} - consumed on next matching spell
var weapon_oil: Dictionary = {}  # {bonus_damage, bonus_damage_type, attacks_remaining, status, status_chance, status_duration, crit_bonus}

# Inventory for AI consumable use (Array of {item_id, quantity})
var combat_inventory: Array = []

# Resistances (percentage, default 0%)
var resistances: Dictionary = {
	"physical": 0,
	"space": 0,
	"air": 0,
	"fire": 0,
	"water": 0,
	"earth": 0
}

# Character data reference (from CharacterSystem or enemy definition)
var character_data: Dictionary = {}

# Visual components
var sprite: ColorRect  # Placeholder until we have actual sprites
var health_bar_bg: ColorRect
var health_bar_fill: ColorRect
var name_label: Label
var archetype_label: Label  # Second line below name_label, shown for enemies
var status_indicator: Label

# Visual settings
const UNIT_SIZE: Vector2 = Vector2(38, 38)
const HEALTH_BAR_HEIGHT: int = 6
const HEALTH_BAR_OFFSET: int = 4

# Team colors
const TEAM_COLORS = {
	0: Color(0.3, 0.6, 0.9),   # Player - blue
	1: Color(0.9, 0.3, 0.3),   # Enemy - red
	2: Color(0.7, 0.7, 0.3)    # Neutral - yellow
}

func _ready() -> void:
	_create_visuals()


## Initialize unit from character data (player/party member)
func init_from_character(char_data: Dictionary, unit_team: int) -> void:
	character_data = char_data
	unit_name = char_data.get("name", "Unknown")
	team = unit_team

	# Get stats from character
	var derived = char_data.get("derived", {})
	max_hp = derived.get("max_hp", 100)
	current_hp = derived.get("current_hp", max_hp)
	max_mana = derived.get("max_mana", 50)
	current_mana = derived.get("current_mana", max_mana)
	max_stamina = derived.get("max_stamina", 50)
	current_stamina = derived.get("current_stamina", max_stamina)

	# Calculate max actions (base 2, can be modified)
	max_actions = CombatManager.BASE_ACTIONS

	# Load talisman resistance bonuses from equipped trinkets
	var equipment = char_data.get("equipment", {})
	for slot in ["trinket1", "trinket2"]:
		var item_id = equipment.get(slot, "")
		if item_id == "":
			continue
		var item = ItemSystem.get_item(item_id)
		var passive = item.get("passive", {})
		for key in passive:
			if key.ends_with("_resistance") and key != "perk":
				# e.g. "fire_resistance": 15 -> resistances["fire"] += 15
				var element = key.replace("_resistance", "")
				resistances[element] = resistances.get(element, 0) + passive[key]

	_update_visuals()


## Initialize unit as enemy from definition
func init_as_enemy(enemy_def: Dictionary) -> void:
	character_data = enemy_def
	unit_name = enemy_def.get("name", "Enemy")
	unit_archetype = enemy_def.get("archetype_name", "")
	team = CombatManager.Team.ENEMY

	max_hp = enemy_def.get("max_hp", 50)
	current_hp = max_hp
	max_mana = enemy_def.get("max_mana", 0)
	current_mana = max_mana
	var derived_stats = enemy_def.get("derived", {})
	max_stamina = derived_stats.get("max_stamina", 50)
	current_stamina = max_stamina
	max_actions = enemy_def.get("actions", 2)

	# Set resistances from enemy definition
	var enemy_resists = enemy_def.get("resistances", {})
	for resist_type in enemy_resists:
		resistances[resist_type] = enemy_resists[resist_type]

	# Load consumable inventory
	combat_inventory = enemy_def.get("inventory", []).duplicate(true)

	_update_visuals()


## Create visual components
func _create_visuals() -> void:
	# Main sprite (placeholder colored square)
	sprite = ColorRect.new()
	sprite.size = UNIT_SIZE
	sprite.position = -UNIT_SIZE / 2  # Center on position
	sprite.color = TEAM_COLORS.get(team, Color.WHITE)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through to grid
	add_child(sprite)

	# Health bar background
	health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(UNIT_SIZE.x, HEALTH_BAR_HEIGHT)
	health_bar_bg.position = Vector2(-UNIT_SIZE.x / 2, -UNIT_SIZE.y / 2 - HEALTH_BAR_HEIGHT - HEALTH_BAR_OFFSET)
	health_bar_bg.color = Color(0.2, 0.2, 0.2)
	health_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_bar_bg)

	# Health bar fill
	health_bar_fill = ColorRect.new()
	health_bar_fill.size = Vector2(UNIT_SIZE.x, HEALTH_BAR_HEIGHT)
	health_bar_fill.position = health_bar_bg.position
	health_bar_fill.color = Color(0.2, 0.8, 0.2)
	health_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_bar_fill)

	# Name label — procedural/personal name, bright white
	name_label = Label.new()
	name_label.text = unit_name
	name_label.position = Vector2(-UNIT_SIZE.x / 2, UNIT_SIZE.y / 2 + 2)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size.x = UNIT_SIZE.x
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)

	# Archetype label — role/class subtitle, muted grey, only shown for enemies
	archetype_label = Label.new()
	archetype_label.text = ""
	archetype_label.position = Vector2(-UNIT_SIZE.x / 2, UNIT_SIZE.y / 2 + 14)
	archetype_label.add_theme_font_size_override("font_size", 8)
	archetype_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	archetype_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	archetype_label.custom_minimum_size.x = UNIT_SIZE.x
	archetype_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	archetype_label.hide()
	add_child(archetype_label)

	# Status indicator (for bleed-out, buffs, etc.)
	status_indicator = Label.new()
	status_indicator.text = ""
	status_indicator.position = Vector2(UNIT_SIZE.x / 2 - 10, -UNIT_SIZE.y / 2 - 15)
	status_indicator.add_theme_font_size_override("font_size", 12)
	status_indicator.add_theme_color_override("font_color", Color.RED)
	status_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_indicator)


## Update visual components
func _update_visuals() -> void:
	if sprite:
		sprite.color = TEAM_COLORS.get(team, Color.WHITE)
		# Dim if dead or bleeding out
		if is_dead:
			sprite.color = sprite.color.darkened(0.7)
		elif is_bleeding_out:
			sprite.color = sprite.color.darkened(0.4)

	if health_bar_fill:
		var hp_ratio = float(current_hp) / float(max_hp) if max_hp > 0 else 0
		health_bar_fill.size.x = UNIT_SIZE.x * hp_ratio

		# Color based on HP percentage
		if hp_ratio > 0.5:
			health_bar_fill.color = Color(0.2, 0.8, 0.2)
		elif hp_ratio > 0.25:
			health_bar_fill.color = Color(0.8, 0.8, 0.2)
		else:
			health_bar_fill.color = Color(0.8, 0.2, 0.2)

	if name_label:
		name_label.text = unit_name

	if archetype_label:
		if unit_archetype != "":
			archetype_label.text = unit_archetype
			archetype_label.show()
		else:
			archetype_label.hide()

	if status_indicator:
		var status_text = ""

		# Show bleed-out status
		if is_bleeding_out:
			status_text = "!" + str(bleed_out_turns)
			status_indicator.add_theme_color_override("font_color", Color.RED)
		# Show status effects
		elif "status_effects" in self and not status_effects.is_empty():
			var icons: Array[String] = []
			for effect in status_effects:
				var status_name = effect.get("status", "")
				# Use short icons/abbreviations for each status
				match status_name.to_lower():
					"burning":
						icons.append("🔥")
					"poisoned", "festering", "diseased":
						icons.append("☠")
					"bleeding":
						icons.append("💧")
					"frozen":
						icons.append("❄")
					"stunned", "paralyzed":
						icons.append("⚡")
					"knocked_down", "prone":
						icons.append("⬇")
					"regenerating":
						icons.append("💚")
					"feared":
						icons.append("😨")
					"silenced":
						icons.append("🤐")
					"confused", "chaotic":
						icons.append("❓")
					"blinded":
						icons.append("👁")
					"rooted", "held":
						icons.append("⛓")
					"blessed", "hasted":
						icons.append("✨")
					"invisible":
						icons.append("👻")
					"cursed":
						icons.append("💀")
					"doomed":
						icons.append("⏳")
					_:
						icons.append("•")
			status_text = "".join(icons)
			# Color based on effect type using status definitions
			var has_positive = false
			var has_negative = false
			for effect in status_effects:
				var sname = effect.get("status", "")
				var def = CombatManager.get_status_definition(sname)
				if def.get("type", "debuff") == "buff":
					has_positive = true
				else:
					has_negative = true
			if has_negative and has_positive:
				status_indicator.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
			elif has_negative:
				status_indicator.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
			elif has_positive:
				status_indicator.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

		if status_text != "":
			status_indicator.text = status_text
			status_indicator.show()
		else:
			status_indicator.hide()


# ============================================
# STAT GETTERS
# ============================================

## Get the total bonus/penalty to a stat from active status effects.
## Checks status definitions loaded in CombatManager for stat_modifiers.
func _get_status_stat_bonus(stat: String) -> int:
	var total := 0
	for effect in status_effects:
		var status_name = effect.get("status", "")
		var def = CombatManager.get_status_definition(status_name)
		var effects = def.get("effects", [])
		# Map effect strings to stat bonuses
		match stat:
			"accuracy":
				if "attack_bonus" in effects:
					total += 10
				if "attack_penalty" in effects:
					total -= 10
				if "melee_hit_chance_halved" in effects:
					total -= 40  # Large accuracy penalty from Blinded
				if "accuracy_bonus" in effects:
					total += 10
				if "ranged_hit_chance_halved" in effects:
					total -= 40  # Ranged accuracy penalty (Rot Wood)
			"armor":
				if "defense_bonus" in effects:
					total += 10
				if "defense_penalty" in effects:
					total -= 10
				if "armor_reduced_50" in effects:
					total -= 20  # Significant armor reduction (Rust Metal)
				if "armor_reduced" in effects:
					total -= 10  # Moderate armor reduction (Melt Armor)
			"dodge":
				if "dodge_bonus" in effects:
					total += 15
				if "minor_dodge_bonus" in effects:
					total += 5
				if "evasion_bonus" in effects:
					total += 25
				if "dodge_penalty" in effects:
					total -= 15  # Dodge penalty (Bone Chill, Entangled)
				if "major_dodge_bonus" in effects:
					total += 30  # Major evasion (Be Like Water)
			"movement":
				if "speed_bonus" in effects:
					total += 2
				if "speed_penalty" in effects:
					total -= 1
				if "movement_reduced_50" in effects:
					# Use base movement (not get_movement() to avoid recursion)
					var base_move = character_data.get("derived", {}).get("movement", 3)
					total -= base_move / 2
				if "major_speed_boost" in effects:
					total += 4
			"initiative":
				if "initiative_bonus" in effects:
					total += 5
				if "initiative_penalty" in effects:
					total -= 5
			"damage":
				if "melee_damage_bonus" in effects:
					total += 5
				if "damage_bonus" in effects:
					total += 5
				if "damage_reduction" in effects:
					total -= 5  # Damage debuff (Bone Chill)
				if "strength_bonus" in effects:
					total += 3  # Strength adds to physical damage
				if "strength_bonus_major" in effects:
					total += 8  # Major strength buff (Yaksha Strength)
				if "ranged_damage_halved" in effects:
					total -= 10  # Ranged damage penalty (Rot Wood)
			"crit_chance":
				if "critical_boost" in effects:
					total += 10
				if "critical_bonus_ranged" in effects:
					total += 8
				if "luck_bonus" in effects:
					total += 5  # Lucky (Golden Ring)
			"spellpower":
				if "awareness_bonus" in effects or "focus_bonus" in effects:
					total += 3
				if "focus_bonus_major" in effects:
					total += 8  # Major focus buff (Inner Fire)
			"range":
				if "range_penalty" in effects:
					total -= 2  # Range reduction (Rain)
	return total


## Check if unit is alive (not dead and not bleeding out)
func is_alive() -> bool:
	return not is_dead and not is_bleeding_out


## Check if unit can be targeted (not dead, not invisible, not in sanctuary)
func is_targetable() -> bool:
	if is_dead:
		return false
	# Invisible and Sanctuary grant cannot_be_targeted
	for effect in status_effects:
		var status_name = effect.get("status", "")
		var def = CombatManager.get_status_definition(status_name)
		if "cannot_be_targeted" in def.get("effects", []):
			return false
	return true


## Get initiative for turn order (includes status effect bonuses)
func get_initiative() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("initiative", 10) + _get_status_stat_bonus("initiative") + CombatManager.get_passive_perk_stat_bonus(self, "initiative")


## Get movement range (includes status effect and perk bonuses)
func get_movement() -> int:
	var derived = character_data.get("derived", {})
	return maxi(0, derived.get("movement", 3) + _get_status_stat_bonus("movement") + CombatManager.get_passive_perk_stat_bonus(self, "movement"))


## Get maximum actions per turn
func get_max_actions() -> int:
	return max_actions


## Get the equipped main-hand weapon data
func get_equipped_weapon() -> Dictionary:
	# For enemies, check if weapon data is in character_data
	if character_data.has("equipped_weapon"):
		return character_data.equipped_weapon

	# For player/party units, get from equipment via ItemSystem
	if ItemSystem and character_data.has("equipment"):
		var weapon_id = ItemSystem.get_equipped_item(character_data, "weapon_main")
		if weapon_id != "":
			return ItemSystem.get_item(weapon_id)

	return {}


## Get the damage type of the equipped weapon (slashing, crushing, piercing)
## Falls back to "crushing" for unarmed
func get_weapon_damage_type() -> String:
	var weapon = get_equipped_weapon()
	if weapon.is_empty():
		return "crushing"  # Unarmed = crushing (fists)

	# Check for per-weapon override first
	var override = weapon.get("damage_type", "")
	if override != "":
		return override

	# Look up default from item_types
	var weapon_type = weapon.get("type", "")
	if ItemSystem:
		var type_info = ItemSystem.get_type_info(weapon_type)
		var type_default = type_info.get("damage_type", "")
		if type_default != "":
			return type_default

	return "crushing"


## Check if this unit has an active charm matching the given spell schools
## Returns the buff data and clears it (one-shot). Schools should be lowercase.
func consume_charm(spell_schools: Array) -> Dictionary:
	if charm_buff.is_empty():
		return {}
	var buff_school = charm_buff.get("school", "")
	for school in spell_schools:
		if school.to_lower() == buff_school:
			var result = charm_buff.duplicate()
			charm_buff = {}
			return result
	return {}


## Consume one weapon oil charge. Returns the oil data or empty dict.
func consume_oil_charge() -> Dictionary:
	if weapon_oil.is_empty():
		return {}
	var result = weapon_oil.duplicate()
	weapon_oil["attacks_remaining"] = weapon_oil.get("attacks_remaining", 0) - 1
	if weapon_oil["attacks_remaining"] <= 0:
		weapon_oil = {}
	return result


## Get the unit's movement mode based on active status effects
## Returns CombatGrid.MovementMode enum value
func get_movement_mode() -> int:
	for effect in status_effects:
		var status_name = effect.get("status", "").to_lower()
		if status_name == "flying" or status_name == "storm_lord":
			return CombatGrid.MovementMode.FLYING
	for effect in status_effects:
		var status_name = effect.get("status", "").to_lower()
		if status_name == "levitating":
			return CombatGrid.MovementMode.LEVITATE
	return CombatGrid.MovementMode.NORMAL


## Check if unit has a specific status effect (case-insensitive)
func has_status(status_name: String) -> bool:
	for effect in status_effects:
		if effect.get("status", "").to_lower() == status_name.to_lower():
			return true
	return false


## Check if equipped weapon is ranged
func is_ranged_weapon() -> bool:
	var weapon = get_equipped_weapon()
	if weapon.is_empty():
		return false

	var weapon_type = weapon.get("type", "")

	# Check item type info for ranged flag
	if ItemSystem:
		var type_info = ItemSystem.get_type_info(weapon_type)
		if type_info.get("ranged", false):
			return true

	# Fallback: check if weapon has range > 1 stat
	var stats = weapon.get("stats", {})
	return stats.get("range", 1) > 1


## Get attack range (1 for melee, more for ranged)
func get_attack_range() -> int:
	var weapon = get_equipped_weapon()
	if weapon.is_empty():
		return 1  # Default melee range when unarmed

	var stats = weapon.get("stats", {})
	return stats.get("range", 1)


## Get accuracy bonus (includes status effect bonuses)
## Weapon skill bonuses are now included in derived.accuracy via CharacterSystem.update_derived_stats()
func get_accuracy() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("accuracy", 0) + _get_status_stat_bonus("accuracy")


## Get dodge value (includes status effect bonuses)
func get_dodge() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("dodge", 10) + _get_status_stat_bonus("dodge") + CombatManager.get_passive_perk_stat_bonus(self, "dodge")


## Get attack damage
## Weapon skill bonuses (damage column) now flow through derived.damage via
## CharacterSystem.update_derived_stats() + PerkSystem.get_base_skill_bonuses_at_level().
## derived.damage already includes skill-based damage at unit creation time.
func get_attack_damage() -> int:
	var attrs = character_data.get("attributes", {})
	var derived = character_data.get("derived", {})

	# Read weapon damage directly from the equipped weapon
	var weapon = get_equipped_weapon()
	var weapon_damage = weapon.get("stats", {}).get("damage", 2)
	var base_damage = weapon_damage

	if is_ranged_weapon():
		# Ranged weapons: Finesse as primary attribute (starts contributing at 10)
		base_damage += (attrs.get("finesse", 10) - 5)
	else:
		# Melee weapons: Strength as primary attribute (starts contributing at 10)
		base_damage += (attrs.get("strength", 10) - 5)

	# Add skill-based damage bonus from derived stats (set by update_derived_stats)
	base_damage += derived.get("damage", 0)

	# Add status effect damage bonuses (Bloodlust, etc.)
	base_damage += _get_status_stat_bonus("damage")

	# Add passive perk damage bonuses
	base_damage += CombatManager.get_passive_perk_stat_bonus(self, "damage")

	return base_damage


## Map weapon type to skill name
func _get_weapon_skill_name(weapon_type: String) -> String:
	match weapon_type:
		"sword":
			return "swords"
		"dagger":
			return "daggers"
		"axe":
			return "axes"
		"mace":
			return "maces"
		"spear":
			return "spears"
		"staff":
			return "martial_arts"  # Staves use martial arts
		"bow", "thrown":
			return "ranged"
		_:
			return ""


## Get armor value (includes status effect and perk bonuses)
func get_armor() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("armor", 0) + _get_status_stat_bonus("armor") + CombatManager.get_passive_perk_stat_bonus(self, "armor")


## Get crit chance (percentage, includes status effect bonuses)
func get_crit_chance() -> float:
	var derived = character_data.get("derived", {})
	return float(derived.get("crit_chance", 5)) + float(_get_status_stat_bonus("crit_chance")) + float(CombatManager.get_passive_perk_stat_bonus(self, "crit_chance"))


## Get current stamina
func get_stamina() -> int:
	return current_stamina


## Use stamina - returns true if had enough
func use_stamina(amount: int) -> bool:
	if current_stamina < amount:
		return false
	current_stamina -= amount
	# Keep character_data in sync for UI display
	var derived = character_data.get("derived", {})
	derived["current_stamina"] = current_stamina
	return true


## Restore stamina (e.g. at start of turn)
func restore_stamina(amount: int) -> void:
	current_stamina = mini(max_stamina, current_stamina + amount)
	var derived = character_data.get("derived", {})
	derived["current_stamina"] = current_stamina


## Restore mana (clamped to max)
func restore_mana(amount: int) -> void:
	current_mana = mini(max_mana, current_mana + amount)
	var derived = character_data.get("derived", {})
	derived["current_mana"] = current_mana


## Tick cooldowns at start of turn — reduces all by 1, removes expired
func tick_cooldowns() -> void:
	var expired: Array[String] = []
	for perk_id in skill_cooldowns:
		skill_cooldowns[perk_id] -= 1
		if skill_cooldowns[perk_id] <= 0:
			expired.append(perk_id)
	for perk_id in expired:
		skill_cooldowns.erase(perk_id)


## Check if a skill is on cooldown
func is_skill_on_cooldown(perk_id: String) -> bool:
	return skill_cooldowns.has(perk_id) and skill_cooldowns[perk_id] > 0


## Set a cooldown on a skill (turns remaining)
func set_skill_cooldown(perk_id: String, turns: int) -> void:
	skill_cooldowns[perk_id] = turns


## Toggle a mantra on/off. Returns true if the mantra is now active.
func toggle_mantra(perk_id: String) -> bool:
	if perk_id in active_mantras:
		active_mantras.erase(perk_id)
		return false
	else:
		active_mantras[perk_id] = 0
		return true


## Tick all active mantras at the start of this unit's turn (increment counter).
func tick_mantras() -> void:
	for perk_id in active_mantras:
		active_mantras[perk_id] += 1


## Get spellpower (includes status effect bonuses)
func get_spellpower() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("spellpower", 0) + _get_status_stat_bonus("spellpower")


## Get magic skill bonus for an element (spellpower from the skill's base_bonuses table)
## Falls back to checking all magic schools for the element if the direct skill isn't found.
func get_magic_skill_bonus(element: String) -> int:
	# Spellpower bonuses are now included in derived.spellpower via CharacterSystem.
	# This function is kept for callers that need per-school bonuses beyond spellpower.
	# Return 0 since the data-driven spellpower is already in get_spellpower().
	return 0


## Physical damage subtypes that fall back to "physical" resistance
const PHYSICAL_SUBTYPES = ["slashing", "crushing", "piercing"]

## Get resistance to a damage type (includes status effect modifiers).
## For physical subtypes (slashing/crushing/piercing), checks specific first then falls back to "physical".
func get_resistance(damage_type: String) -> float:
	var base: float
	if damage_type in PHYSICAL_SUBTYPES:
		# Check for specific resistance first (e.g., skeleton weak to crushing)
		if resistances.has(damage_type):
			base = float(resistances[damage_type])
		else:
			# Fall back to generic physical resistance
			base = float(resistances.get("physical", 0))
	else:
		base = float(resistances.get(damage_type, 0))

	# Apply status effect resistance modifiers
	for effect in status_effects:
		var status_name = effect.get("status", "")
		var def = CombatManager.get_status_definition(status_name)
		var effects = def.get("effects", [])

		# Vulnerability effects (lower resistance)
		if damage_type == "physical" or damage_type in PHYSICAL_SUBTYPES:
			if "vulnerable_to_physical" in effects:
				base -= 50.0  # Frozen makes you take 50% more physical
			if "physical_immunity" in effects:
				base = 100.0  # Petrified/Fluid Form: immune to physical
			if "physical_resist_50" in effects:
				base += 50.0
			if "physical_damage_negation_50_percent" in effects:
				base += 50.0
			if "physical_damage_reduction_25" in effects:
				base += 25.0  # Bark Skin
			if "physical_damage_reduction_50" in effects:
				base += 50.0  # Stone Skin
			if "physical_damage_reduction_75" in effects:
				base += 75.0  # Steel Skin
			if "physical_resistance_plus_25" in effects:
				base += 25.0  # Fortified
			if "physical_resistance_plus_50" in effects:
				base += 50.0  # Golden Defense

		if damage_type == "fire":
			if "fire_resistance_minus_50" in effects:
				base -= 50.0
			if "fire_damage_immunity" in effects:
				base = 100.0  # Solar Form / Fire Immune
			if "fire_resistance_plus_25" in effects:
				base += 25.0  # Cooling Mist
		if damage_type == "water":
			if "water_resistance_minus_25" in effects:
				base -= 25.0
			if "water_resistance_minus_50" in effects:
				base -= 50.0
			if "water_damage_immunity" in effects:
				base = 100.0  # Fluid Form
		if damage_type == "air":
			if "air_damage_immunity" in effects:
				base = 100.0

		# grants_vulnerability field (used by Smoke_Form, Lightning_Form)
		var vuln = def.get("grants_vulnerability", {})
		if vuln.has(damage_type):
			base -= float(vuln[damage_type])

		# General elemental resistance boost
		if "elemental_resistance_25" in effects and damage_type not in PHYSICAL_SUBTYPES and damage_type != "physical":
			base += 25.0

		# Immune to all damage (Invulnerable)
		if "immune_to_all_damage" in effects:
			base = 100.0

	return base


## Set resistance (for buffs/debuffs)
func set_resistance(damage_type: String, value: float) -> void:
	resistances[damage_type] = value


# ============================================
# DAMAGE & HEALING
# ============================================

## Take damage
func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)
	# Keep character_data in sync so HP persists after combat
	var derived_hp = character_data.get("derived", {})
	derived_hp["current_hp"] = current_hp
	_update_visuals()

	# Show damage number
	_show_damage_number(amount)


## Heal HP
func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)
	# Keep character_data in sync so HP persists after combat
	var derived_heal = character_data.get("derived", {})
	derived_heal["current_hp"] = current_hp
	_update_visuals()

	# Show heal number
	_show_heal_number(amount)


## Show floating damage number
func _show_damage_number(amount: int) -> void:
	var label = Label.new()
	label.text = str(amount)
	label.position = Vector2(0, -UNIT_SIZE.y / 2 - 20)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	# Animate and remove
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0, 0.8)
	tween.tween_callback(label.queue_free)


## Show floating heal number
func _show_heal_number(amount: int) -> void:
	var label = Label.new()
	label.text = "+" + str(amount)
	label.position = Vector2(0, -UNIT_SIZE.y / 2 - 20)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	# Animate and remove
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0, 0.8)
	tween.tween_callback(label.queue_free)


## Show floating action name (spell/item name) above the unit
## Gold colored, positioned higher and slightly larger than damage numbers
const COLOR_ACTION_NAME = Color(0.95, 0.85, 0.3)

func show_action_name(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.position = Vector2(0, -UNIT_SIZE.y / 2 - 35)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", COLOR_ACTION_NAME)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	# Animate: float up and fade out (longer duration to avoid overlap with damage numbers)
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 25, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0, 1.0)
	tween.tween_callback(label.queue_free)


## Show floating combat text (miss, dodge, block, etc.)
func show_combat_text(text: String, color: Color = Color(0.9, 0.9, 0.9)) -> void:
	var label = Label.new()
	label.text = text
	label.position = Vector2(0, -UNIT_SIZE.y / 2 - 20)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	# Animate: float up and fade out
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0, 0.9)
	tween.tween_callback(label.queue_free)


# ============================================
# STATUS EFFECT VISUALS
# ============================================

## Element/school → color mapping for status effect floating text
const STATUS_ELEMENT_COLORS: Dictionary = {
	"fire": Color(1.0, 0.4, 0.1),       # Orange-red
	"water": Color(0.2, 0.6, 1.0),      # Blue
	"ice": Color(0.5, 0.85, 1.0),       # Light blue
	"cold": Color(0.5, 0.85, 1.0),      # Light blue
	"earth": Color(0.7, 0.55, 0.3),     # Brown
	"air": Color(0.7, 0.9, 1.0),        # Pale blue
	"space": Color(0.8, 0.6, 1.0),      # Purple
	"black": Color(0.6, 0.2, 0.6),      # Dark purple
	"white": Color(1.0, 0.95, 0.7),     # Warm white
	"holy": Color(1.0, 0.95, 0.7),      # Warm white
	"poison": Color(0.4, 0.8, 0.2),     # Green
	"physical": Color(0.9, 0.85, 0.8),  # Off-white
}

## Status category → color mapping for statuses without a clear element
const STATUS_TYPE_COLORS: Dictionary = {
	"cc": Color(0.9, 0.7, 0.2),         # Gold (crowd control)
	"dot": Color(1.0, 0.4, 0.1),        # Orange (damage over time)
	"hot": Color(0.3, 1.0, 0.5),        # Green (heal over time)
	"buff": Color(0.3, 0.85, 1.0),      # Cyan (buffs)
	"debuff": Color(0.9, 0.3, 0.3),     # Red (debuffs)
	"vulnerability": Color(0.9, 0.5, 0.2),  # Dark orange
	"immunity": Color(1.0, 0.95, 0.5),  # Bright yellow
	"protection": Color(0.5, 0.7, 1.0), # Light blue
	"aura": Color(0.8, 0.7, 1.0),       # Lavender
	"shield": Color(0.6, 0.8, 1.0),     # Steel blue
	"transformation": Color(0.9, 0.6, 1.0),  # Pink-purple
	"resistance": Color(0.6, 0.8, 0.4), # Olive green
	"divine": Color(1.0, 0.9, 0.4),     # Gold
	"stealth": Color(0.5, 0.5, 0.6),    # Grey
	"disruption": Color(0.8, 0.4, 0.2), # Rust
	"delayed": Color(0.7, 0.3, 0.5),    # Maroon
}

## Color used for "Resisted!" text — same shade as "Miss!" (grey)
const COLOR_RESISTED = Color(0.8, 0.8, 0.8)

## Color used for expired status text (grey, faded)
const COLOR_STATUS_EXPIRED = Color(0.6, 0.6, 0.6)


## Get the appropriate color for a status effect name.
## Uses the status definition's element or category to pick a color.
func _get_status_color(status_name: String) -> Color:
	var def = CombatManager.get_status_definition(status_name)
	if def.is_empty():
		return Color(0.9, 0.9, 0.9)  # Default white-ish

	# Check if the status has an explicit element (for DoTs)
	var element = def.get("element", "")
	if element != "" and STATUS_ELEMENT_COLORS.has(element):
		return STATUS_ELEMENT_COLORS[element]

	# Infer element from the effects array
	var effects = def.get("effects", [])
	for fx in effects:
		if "fire" in fx:
			return STATUS_ELEMENT_COLORS["fire"]
		if "poison" in fx:
			return STATUS_ELEMENT_COLORS["poison"]
		if "water" in fx:
			return STATUS_ELEMENT_COLORS["water"]
		if "ice" in fx or "frozen" in fx or "cold" in fx:
			return STATUS_ELEMENT_COLORS["ice"]
		if "air" in fx or "lightning" in fx:
			return STATUS_ELEMENT_COLORS["air"]
		if "space" in fx:
			return STATUS_ELEMENT_COLORS["space"]
		if "black" in fx:
			return STATUS_ELEMENT_COLORS["black"]
		if "holy" in fx or "white" in fx or "blessed" in fx:
			return STATUS_ELEMENT_COLORS["white"]
		if "physical" in fx:
			return STATUS_ELEMENT_COLORS["physical"]

	# Fall back to category color
	var category = def.get("category", "")
	if STATUS_TYPE_COLORS.has(category):
		return STATUS_TYPE_COLORS[category]

	# Fall back to type (buff/debuff)
	var stype = def.get("type", "debuff")
	if stype == "buff":
		return STATUS_TYPE_COLORS["buff"]
	return STATUS_TYPE_COLORS["debuff"]


## Show floating text when a status effect is applied.
## Displays the status name in the color associated with its element/category.
## Positioned slightly higher than damage numbers to avoid overlap.
func show_status_applied(status_name: String) -> void:
	var color = _get_status_color(status_name)
	# Use a human-readable name (replace underscores, capitalize)
	var display_name = status_name.replace("_", " ")

	var label = Label.new()
	label.text = "+" + display_name
	label.position = Vector2(0, -UNIT_SIZE.y / 2 - 28)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 25, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0, 1.0)
	tween.tween_callback(label.queue_free)


## Show floating text when a status effect expires.
## Displays the status name with strikethrough in grey, floating up and fading.
func show_status_expired(status_name: String) -> void:
	var display_name = status_name.replace("_", " ")

	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	# Strikethrough via BBCode
	label.text = "[color=#999999][s]" + display_name + "[/s][/color]"
	label.fit_content = true
	label.scroll_active = false
	label.position = Vector2(-30, -UNIT_SIZE.y / 2 - 28)
	label.custom_minimum_size = Vector2(60, 20)
	label.add_theme_font_size_override("normal_font_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 25, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0, 1.2)
	tween.tween_callback(label.queue_free)


## Show "Resisted!" floating text when a saving throw succeeds.
## Uses the same grey color as "Miss!" for consistency.
func show_resisted_text() -> void:
	show_combat_text("Resisted!", COLOR_RESISTED)


## Play attack lunge animation — move toward target and return
## target_world_pos is the world position of the defender
func play_attack_animation(target_world_pos: Vector2) -> void:
	if sprite == null:
		return

	# Calculate direction toward target, move 60% of the way (capped at 20px)
	var direction = (target_world_pos - global_position).normalized()
	var lunge_distance = minf(20.0, global_position.distance_to(target_world_pos) * 0.6)
	var lunge_offset = direction * lunge_distance

	# Tween the sprite position: lunge forward, then back
	var tween = create_tween()
	tween.tween_property(sprite, "position", sprite.position + lunge_offset, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "position", -UNIT_SIZE / 2, 0.30).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


# ============================================
# SELECTION & HIGHLIGHTING
# ============================================

## Highlight as selected
func set_selected(selected: bool) -> void:
	if sprite:
		if selected:
			# Add outline effect or brighten
			sprite.color = sprite.color.lightened(0.3)
		else:
			_update_visuals()  # Reset to normal color
