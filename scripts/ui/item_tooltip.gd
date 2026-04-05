extends PanelContainer
## ItemTooltip - Displays detailed item information on hover
##
## Shows item name (colored by rarity), type, description, stats, and requirements.
## Position this near the mouse cursor when showing.

@onready var item_name_label: Label = $MarginContainer/VBoxContainer/ItemName
@onready var item_type_label: Label = $MarginContainer/VBoxContainer/ItemType
@onready var description_label: Label = $MarginContainer/VBoxContainer/Description
@onready var stats_container: VBoxContainer = $MarginContainer/VBoxContainer/StatsContainer
@onready var requirements_label: Label = $MarginContainer/VBoxContainer/Requirements

# Stat display names (prettier than raw keys)
const STAT_NAMES := {
	"damage": "Damage",
	"armor": "Armor",
	"dodge": "Dodge",
	"accuracy": "Accuracy",
	"crit_chance": "Crit Chance",
	"spellpower": "Spellpower",
	"max_hp": "Max HP",
	"max_mana": "Max Mana",
	"max_stamina": "Max Stamina",
	"initiative": "Initiative",
	"movement": "Movement",
	"luck": "Luck",
	"armor_pierce": "Armor Pierce",
	"strength": "Strength",
	"finesse": "Finesse",
	"constitution": "Constitution",
	"focus": "Focus",
	"awareness": "Awareness",
	"charm": "Charm"
}

func _ready() -> void:
	# Start hidden
	hide()
	# Make sure tooltip doesn't block mouse
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Display item information
func show_item(item: Dictionary, global_pos: Vector2) -> void:
	if item.is_empty():
		hide()
		return

	var item_id = item.get("id", "")

	# Item name with rarity color
	var rarity_color = ItemSystem.get_rarity_color(item_id) if item_id != "" else Color.WHITE
	item_name_label.text = item.get("name", "Unknown Item")
	item_name_label.add_theme_color_override("font_color", rarity_color)

	# Item type line — use weapon_class if available (e.g. "Curved sword"), else fall back to type
	var weapon_class: String = item.get("weapon_class", "")
	var item_type: String = item.get("type", "").capitalize()
	if weapon_class != "":
		# weapon_class already encodes two-handedness ("Two-handed sword"), no suffix needed
		item_type_label.text = weapon_class
	else:
		var two_handed: String = " (Two-Handed)" if item.get("two_handed", false) else ""
		item_type_label.text = item_type + two_handed

	# Rarity
	var rarity: String = item.get("rarity", "common").capitalize()
	item_type_label.text += " — " + rarity

	# Description
	description_label.text = item.get("description", "")

	# Clear old stats
	for child in stats_container.get_children():
		child.queue_free()

	# Add stats
	var stats = item.get("stats", {})
	for stat_key in stats:
		var stat_value = stats[stat_key]
		if stat_value == 0:
			continue

		var stat_row = HBoxContainer.new()
		stats_container.add_child(stat_row)

		var stat_name = Label.new()
		stat_name.text = STAT_NAMES.get(stat_key, stat_key.capitalize())
		stat_name.custom_minimum_size.x = 100
		stat_name.add_theme_font_size_override("font_size", 12)
		stat_name.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		stat_row.add_child(stat_name)

		var stat_val = Label.new()
		var sign = "+" if stat_value > 0 else ""
		# Show as integer if the value is a whole number (avoids "5.0" display)
		var display = int(stat_value) if float(stat_value) == int(stat_value) else stat_value
		stat_val.text = sign + str(display)
		stat_val.add_theme_font_size_override("font_size", 12)
		# Green for positive, red for negative
		var val_color = Color(0.4, 0.9, 0.4) if stat_value > 0 else Color(0.9, 0.4, 0.4)
		stat_val.add_theme_color_override("font_color", val_color)
		stat_row.add_child(stat_val)

	# Skill bonuses (e.g. Monk's Robe +1 Yoga)
	var skill_bonuses: Dictionary = item.get("skill_bonuses", {})
	for skill_id in skill_bonuses:
		var bonus_total: int = 0
		for source in skill_bonuses[skill_id]:
			bonus_total += skill_bonuses[skill_id][source]
		if bonus_total == 0:
			continue
		var skill_row := HBoxContainer.new()
		stats_container.add_child(skill_row)
		var skill_name := Label.new()
		skill_name.text = skill_id.capitalize() + " skill"
		skill_name.custom_minimum_size.x = 100
		skill_name.add_theme_font_size_override("font_size", 12)
		skill_name.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		skill_row.add_child(skill_name)
		var skill_val := Label.new()
		skill_val.text = "+%d" % bonus_total
		skill_val.add_theme_font_size_override("font_size", 12)
		skill_val.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		skill_row.add_child(skill_val)

	# Charm / consumable effects
	var effect = item.get("effect", {})
	if not effect.is_empty() and item.get("type", "") == "charm":
		var eff_row = HBoxContainer.new()
		stats_container.add_child(eff_row)

		var school_str = effect.get("school", "").capitalize()
		var mana_red = effect.get("mana_reduction", 0.0)
		var sp_bonus = effect.get("spellpower_bonus", 0.0)

		var eff_label = Label.new()
		var parts: Array[String] = []
		if mana_red > 0:
			parts.append("-%d%% %s mana cost" % [int(mana_red * 100), school_str])
		if sp_bonus > 0:
			parts.append("+%d%% spellpower" % int(sp_bonus * 100))
		eff_label.text = ", ".join(parts)
		eff_label.add_theme_font_size_override("font_size", 12)
		eff_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		eff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		eff_row.add_child(eff_label)

	# Supply items (food, herbs, scrap, reagents)
	if item.get("type", "") == "supply":
		var supply_type = item.get("supply_type", "")
		var supply_amount = item.get("supply_amount", 0)
		if supply_amount > 0 and supply_type != "":
			var supply_row = HBoxContainer.new()
			stats_container.add_child(supply_row)
			var supply_label = Label.new()
			supply_label.text = "+%d %s" % [supply_amount, supply_type.capitalize()]
			supply_label.add_theme_font_size_override("font_size", 12)
			supply_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6))
			supply_row.add_child(supply_label)

	# Requirements
	var requirements = item.get("requirements", {})
	if requirements.is_empty():
		requirements_label.hide()
	else:
		requirements_label.show()
		var req_parts: Array[String] = []
		for req_key in requirements:
			req_parts.append("%s %d" % [req_key.capitalize(), requirements[req_key]])
		requirements_label.text = "Requires: " + ", ".join(req_parts)

		# Check if player meets requirements
		var player = CharacterSystem.get_player()
		if not player.is_empty():
			var can_result = ItemSystem.can_equip(player, item_id)
			if can_result.can_equip:
				requirements_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
			else:
				requirements_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	# Show and position
	show()

	# Wait a frame for size to update, then position
	await get_tree().process_frame
	_position_tooltip(global_pos)

## Position tooltip near cursor, keeping it on screen
func _position_tooltip(global_pos: Vector2) -> void:
	var viewport_size = get_viewport_rect().size
	var tooltip_size = size

	# Default: show to the right and below cursor
	var pos = global_pos + Vector2(15, 15)

	# Keep on screen horizontally
	if pos.x + tooltip_size.x > viewport_size.x - 10:
		pos.x = global_pos.x - tooltip_size.x - 15

	# Keep on screen vertically
	if pos.y + tooltip_size.y > viewport_size.y - 10:
		pos.y = global_pos.y - tooltip_size.y - 15

	# Clamp to viewport
	pos.x = clamp(pos.x, 10, viewport_size.x - tooltip_size.x - 10)
	pos.y = clamp(pos.y, 10, viewport_size.y - tooltip_size.y - 10)

	global_position = pos

## Hide the tooltip
func hide_tooltip() -> void:
	hide()
