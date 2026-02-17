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
var team: int = 0  # CombatManager.Team

# Grid position
var grid_position: Vector2i = Vector2i.ZERO

# Combat state
var current_hp: int = 100
var max_hp: int = 100
var current_mana: int = 50
var max_mana: int = 50
var actions_remaining: int = 2
var max_actions: int = 2

# Status
var is_bleeding_out: bool = false
var bleed_out_turns: int = 0
var is_dead: bool = false
var status_effects: Array = []  # Active status effects on this unit

# Consumable buffs
var talisman_buff: Dictionary = {}  # {school, mana_reduction, spellpower_bonus} - consumed on next matching spell
var weapon_oil: Dictionary = {}  # {bonus_damage, bonus_damage_type, attacks_remaining, status, status_chance, status_duration, crit_bonus}

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

	# Calculate max actions (base 2, can be modified)
	max_actions = CombatManager.BASE_ACTIONS
	# TODO: Check for haste buffs, finesse upgrades

	_update_visuals()


## Initialize unit as enemy from definition
func init_as_enemy(enemy_def: Dictionary) -> void:
	character_data = enemy_def
	unit_name = enemy_def.get("name", "Enemy")
	team = CombatManager.Team.ENEMY

	max_hp = enemy_def.get("max_hp", 50)
	current_hp = max_hp
	max_mana = enemy_def.get("max_mana", 0)
	current_mana = max_mana
	max_actions = enemy_def.get("actions", 2)

	# Set resistances from enemy definition
	var enemy_resists = enemy_def.get("resistances", {})
	for resist_type in enemy_resists:
		resistances[resist_type] = enemy_resists[resist_type]

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

	# Name label
	name_label = Label.new()
	name_label.text = unit_name
	name_label.position = Vector2(-UNIT_SIZE.x / 2, UNIT_SIZE.y / 2 + 2)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size.x = UNIT_SIZE.x
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)

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
				match status_name:
					"burning":
						icons.append("🔥")
					"poisoned":
						icons.append("☠")
					"bleeding":
						icons.append("💧")
					"frozen":
						icons.append("❄")
					"stunned":
						icons.append("⚡")
					"knocked_down":
						icons.append("⬇")
					"regenerating":
						icons.append("💚")
					"feared":
						icons.append("😨")
					_:
						icons.append("•")
			status_text = "".join(icons)
			# Color based on effect type (negative = red, positive = green)
			var has_positive = false
			var has_negative = false
			for effect in status_effects:
				var s = effect.get("status", "")
				if s == "regenerating":
					has_positive = true
				else:
					has_negative = true
			if has_negative:
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

## Check if unit is alive (not dead and not bleeding out)
func is_alive() -> bool:
	return not is_dead and not is_bleeding_out


## Check if unit can be targeted
func is_targetable() -> bool:
	return not is_dead


## Get initiative for turn order
func get_initiative() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("initiative", 10)


## Get movement range
func get_movement() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("movement", 3)


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


## Check if this unit has an active talisman matching the given spell schools
## Returns the buff data and clears it (one-shot). Schools should be lowercase.
func consume_talisman(spell_schools: Array) -> Dictionary:
	if talisman_buff.is_empty():
		return {}
	var buff_school = talisman_buff.get("school", "")
	for school in spell_schools:
		if school.to_lower() == buff_school:
			var result = talisman_buff.duplicate()
			talisman_buff = {}
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


## Get accuracy bonus
func get_accuracy() -> int:
	var derived = character_data.get("derived", {})
	var accuracy = derived.get("accuracy", 0)

	# Add weapon skill bonus (2 accuracy per level)
	var skills = character_data.get("skills", {})
	var weapon = get_equipped_weapon()
	var weapon_type = weapon.get("type", "")
	var skill_name = _get_weapon_skill_name(weapon_type)

	if skill_name != "":
		var skill_level = skills.get(skill_name, 0)
		accuracy += skill_level * 2

	return accuracy


## Get dodge value
func get_dodge() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("dodge", 10)


## Get attack damage
func get_attack_damage() -> int:
	var derived = character_data.get("derived", {})
	var base_damage = derived.get("damage", 5)

	# Add attribute modifier - Finesse for ranged, Strength for melee
	var attrs = character_data.get("attributes", {})
	var skills = character_data.get("skills", {})

	if is_ranged_weapon():
		# Ranged weapons use Finesse
		var fin_mod = (attrs.get("finesse", 10) - 10)
		base_damage += fin_mod

		# Add Ranged skill bonus (2 damage per level)
		var ranged_skill = skills.get("ranged", 0)
		base_damage += ranged_skill * 2
	else:
		# Melee weapons use Strength
		var str_mod = (attrs.get("strength", 10) - 10)
		base_damage += str_mod

		# Add weapon skill bonus based on weapon type
		var weapon = get_equipped_weapon()
		var weapon_type = weapon.get("type", "")
		var skill_name = _get_weapon_skill_name(weapon_type)
		if skill_name != "":
			var skill_level = skills.get(skill_name, 0)
			base_damage += skill_level * 2

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


## Get armor value
func get_armor() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("armor", 0)


## Get crit chance (percentage)
func get_crit_chance() -> float:
	var derived = character_data.get("derived", {})
	return float(derived.get("crit_chance", 5))


## Get spellpower
func get_spellpower() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("spellpower", 0)


## Get magic skill bonus for an element
func get_magic_skill_bonus(element: String) -> int:
	var skills = character_data.get("skills", {})
	var skill_name = element + "_magic"  # e.g., "fire_magic"
	var skill_level = skills.get(skill_name, 0)
	return skill_level * 2


## Physical damage subtypes that fall back to "physical" resistance
const PHYSICAL_SUBTYPES = ["slashing", "crushing", "piercing"]

## Get resistance to a damage type
## For physical subtypes (slashing/crushing/piercing), checks specific first then falls back to "physical"
func get_resistance(damage_type: String) -> float:
	if damage_type in PHYSICAL_SUBTYPES:
		# Check for specific resistance first (e.g., skeleton weak to crushing)
		if resistances.has(damage_type):
			return float(resistances[damage_type])
		# Fall back to generic physical resistance
		return float(resistances.get("physical", 0))
	return float(resistances.get(damage_type, 0))


## Set resistance (for buffs/debuffs)
func set_resistance(damage_type: String, value: float) -> void:
	resistances[damage_type] = value


# ============================================
# DAMAGE & HEALING
# ============================================

## Take damage
func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)
	_update_visuals()

	# Show damage number
	_show_damage_number(amount)


## Heal HP
func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)
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
	tween.tween_property(sprite, "position", sprite.position + lunge_offset, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "position", -UNIT_SIZE / 2, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


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
