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
const UNIT_SIZE: Vector2 = Vector2(48, 48)
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
		if is_bleeding_out:
			status_indicator.text = "!" + str(bleed_out_turns)
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


## Get attack range (1 for melee, more for ranged)
func get_attack_range() -> int:
	# TODO: Check equipped weapon for range
	# For now, default to melee (adjacent = 1)
	return 1


## Get accuracy bonus
func get_accuracy() -> int:
	var derived = character_data.get("derived", {})
	var accuracy = derived.get("accuracy", 0)

	# Add skill bonus
	# TODO: Get weapon skill level * 2

	return accuracy


## Get dodge value
func get_dodge() -> int:
	var derived = character_data.get("derived", {})
	return derived.get("dodge", 10)


## Get attack damage
func get_attack_damage() -> int:
	var derived = character_data.get("derived", {})
	var base_damage = derived.get("damage", 5)

	# Add attribute modifier
	var attrs = character_data.get("attributes", {})
	# TODO: Check weapon type for STR vs FIN
	var str_mod = (attrs.get("strength", 10) - 10)
	base_damage += str_mod

	# Add skill bonus
	# TODO: Get weapon skill level * 2

	return base_damage


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


## Get resistance to a damage type
func get_resistance(damage_type: String) -> float:
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
