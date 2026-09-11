extends Control

@onready var start_button: Button = $UI/CenterContainer/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	_apply_button_style()


func _apply_button_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.96, 0.92, 1.0)
	style.border_color = Color(0.90, 0.88, 0.80, 1.0)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0.0, 0.14, 0.24, 0.28)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	start_button.add_theme_stylebox_override("normal", style)
	start_button.add_theme_stylebox_override("hover", style)
	start_button.add_theme_stylebox_override("pressed", style)
	start_button.add_theme_stylebox_override("focus", style)
	start_button.add_theme_color_override("font_color", Color(0.08, 0.13, 0.24, 1.0))
	start_button.add_theme_color_override("font_pressed_color", Color(0.08, 0.13, 0.24, 1.0))
	start_button.add_theme_color_override("font_hover_color", Color(0.08, 0.13, 0.24, 1.0))
	start_button.add_theme_font_size_override("font_size", 28)
	start_button.set("theme_override_font_sizes/font_size", 28)
	start_button.text = "START"
	start_button.pivot_offset = start_button.size * 0.5


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
