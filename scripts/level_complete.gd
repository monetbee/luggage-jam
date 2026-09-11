extends Control

@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var coin_label: Label = $CenterContainer/VBoxContainer/CoinLabel

func _ready() -> void:
	coin_label.text = "Coins +20"
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
