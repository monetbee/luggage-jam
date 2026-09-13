extends Node2D

const CELL_SIZE := 52
const LUGGAGE_SCENE := preload("res://scenes/luggage.tscn")
const WALL_TEXTURE := preload("res://assets/x.jpeg")

@onready var board: Node2D = $Board
@onready var tray: Sprite2D = $Tray
@onready var exit_sprite: Sprite2D = $Exit
@onready var level_label: Label = $HUD/MarginContainer/VBoxContainer/TopBar/LevelLabel
@onready var coins_label: Label = $HUD/MarginContainer/VBoxContainer/TopBar/CoinsLabel
@onready var status_label: Label = $HUD/MarginContainer/VBoxContainer/StatusLabel
@onready var hint_button: Button = $HUD/MarginContainer/VBoxContainer/BottomBar/HintButton
@onready var shuffle_button: Button = $HUD/MarginContainer/VBoxContainer/BottomBar/ShuffleButton

var level_number: int = 1
var level_data: Dictionary = {}
var walls: Dictionary = {}
var luggages: Array[Luggage] = []
var save_data: Dictionary = {}
var collected_count: int = 0


func _ready() -> void:
	save_data = SaveManager.load_save()
	_configure_visuals()
	load_level(level_number)
	hint_button.pressed.connect(_on_hint_pressed)
	shuffle_button.pressed.connect(_on_shuffle_pressed)


func _configure_visuals() -> void:
	_fit_sprite_to_width(tray, 390.0)
	_fit_sprite_to_width(exit_sprite, 96.0)


func _fit_sprite_to_width(sprite: Sprite2D, target_width: float) -> void:
	if sprite == null or sprite.texture == null:
		return
	var texture_width := float(sprite.texture.get_width())
	if texture_width <= 0.0:
		return
	var factor := target_width / texture_width
	sprite.scale = Vector2(factor, factor)


func load_level(level_id: int) -> void:
	level_number = level_id
	level_data = LevelManager.load_level(level_id)
	level_label.text = "Level %d" % level_id
	coins_label.text = "Coins: %d" % save_data.get("coins", 0)
	status_label.text = "Ready"
	collected_count = 0
	walls.clear()
	luggages.clear()
	for child in board.get_children():
		child.queue_free()

	var board_size := int(level_data.get("size", 6))
	for row in range(board_size):
		for col in range(board_size):
			var tile_node := ColorRect.new()
			tile_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile_node.color = Color(1.0, 1.0, 1.0, 0.055)
			tile_node.size = Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
			tile_node.position = board_position_for(row, col) - Vector2((CELL_SIZE - 2) * 0.5, (CELL_SIZE - 2) * 0.5)
			board.add_child(tile_node)

	for wall in level_data.get("walls", []):
		var wall_row := int(wall["row"])
		var wall_col := int(wall["col"])
		walls[Vector2i(wall_row, wall_col)] = true
		var wall_node := Sprite2D.new()
		wall_node.texture = WALL_TEXTURE
		wall_node.position = board_position_for(wall_row, wall_col)
		_fit_sprite_to_cell(wall_node, 46.0)
		board.add_child(wall_node)

	for luggage_data in level_data.get("luggages", []):
		var luggage: Luggage = LUGGAGE_SCENE.instantiate()
		luggage.row = int(luggage_data.get("row", 0))
		luggage.col = int(luggage_data.get("col", 0))
		luggage.color = String(luggage_data.get("color", "red"))
		luggage.direction = String(luggage_data.get("direction", "right"))
		luggage.position = board_position_for(luggage.row, luggage.col)
		luggage.pressed.connect(_on_luggage_pressed)
		board.add_child(luggage)
		luggages.append(luggage)


func _fit_sprite_to_cell(sprite: Sprite2D, target_size: float) -> void:
	if sprite.texture == null:
		return
	var width := float(sprite.texture.get_width())
	var height := float(sprite.texture.get_height())
	var largest := max(width, height)
	if largest <= 0.0:
		return
	var factor := target_size / largest
	sprite.scale = Vector2(factor, factor)


func board_position_for(row: int, col: int) -> Vector2:
	return Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)


func _on_luggage_pressed(luggage: Luggage) -> void:
	if luggage.collected:
		return

	var direction_vector := luggage.direction_to_grid_vector(luggage.direction)
	var board_size := int(level_data.get("size", 6))
	var moved := false

	while true:
		var next_row := luggage.row + direction_vector.x
		var next_col := luggage.col + direction_vector.y

		if next_row < 0 or next_row >= board_size or next_col < 0 or next_col >= board_size:
			collect_luggage(luggage)
			return

		var next_cell := Vector2i(next_row, next_col)
		if walls.has(next_cell) or has_luggage_at(next_row, next_col):
			status_label.text = "Blocked" if not moved else "Moved"
			return

		luggage.row = next_row
		luggage.col = next_col
		luggage.position = board_position_for(luggage.row, luggage.col)
		moved = true


func has_luggage_at(row: int, col: int) -> bool:
	for luggage in luggages:
		if luggage.collected:
			continue
		if luggage.row == row and luggage.col == col:
			return true
	return false


func collect_luggage(luggage: Luggage) -> void:
	luggage.collected = true
	luggage.visible = false
	collected_count += 1
	status_label.text = "Luggage collected"
	if collected_count >= luggages.size():
		_on_level_cleared()


func _on_hint_pressed() -> void:
	status_label.text = "Hint: follow the arrow direction"


func _on_shuffle_pressed() -> void:
	var directions := ["up", "down", "left", "right"]
	for luggage in luggages:
		if luggage.collected:
			continue
		luggage.direction = directions[randi() % directions.size()]
		luggage.queue_redraw()
	status_label.text = "Board shuffled"


func _on_level_cleared() -> void:
	save_data["coins"] = int(save_data.get("coins", 0)) + 20
	save_data["highest_level"] = max(int(save_data.get("highest_level", 1)), level_number + 1)
	SaveManager.save(save_data)
	status_label.text = "LEVEL COMPLETE"
	var scene := load("res://scenes/level_complete.tscn")
	get_tree().change_scene_to_packed(scene)
