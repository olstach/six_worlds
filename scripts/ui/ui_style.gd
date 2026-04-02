## Static helpers for building consistent Tibetan-themed UI styles.
## Usage:  const UIStyle = preload("res://scripts/ui/ui_style.gd")
class_name UIStyle
extends RefCounted


## Create a StyleBoxFlat with standard Tibetan-themed borders and corners.
## `accent` is the main color; background is auto-darkened from it.
## Optional overrides: border_width (default 4), corner_radius (default 8),
## content_margin (default 12), bg_darken (default 0.55).
static func make_stylebox(accent: Color, border_width: int = 4,
		corner_radius: int = 8, content_margin: int = 12,
		bg_darken: float = 0.55) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent.darkened(bg_darken)
	sb.border_color = accent
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.content_margin_left = content_margin
	sb.content_margin_right = content_margin
	sb.content_margin_top = content_margin
	sb.content_margin_bottom = content_margin
	return sb


## Create a hover variant of a stylebox (lighter bg and border).
static func make_hover(base: StyleBoxFlat, bg_darken: float = 0.25,
		border_lighten: float = 0.2) -> StyleBoxFlat:
	var hover: StyleBoxFlat = base.duplicate()
	hover.bg_color = base.border_color.darkened(bg_darken)
	hover.border_color = base.border_color.lightened(border_lighten)
	return hover


## Apply normal + hover styleboxes to a button in one call.
static func apply_button_style(button: Button, accent: Color,
		border_width: int = 4, corner_radius: int = 8,
		content_margin: int = 12) -> void:
	var normal := make_stylebox(accent, border_width, corner_radius, content_margin)
	var hover := make_hover(normal)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover.duplicate())


## Apply standard panel styling to a PanelContainer.
static func apply_panel_style(panel: PanelContainer, accent: Color,
		border_width: int = 3, corner_radius: int = 12,
		content_margin: int = 20, bg_darken: float = 0.7) -> void:
	var sb := make_stylebox(accent, border_width, corner_radius, content_margin, bg_darken)
	panel.add_theme_stylebox_override("panel", sb)
