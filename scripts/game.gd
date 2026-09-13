extends Node2D

const LUGGAGE_SCENE: PackedScene = preload("res://scenes/luggage.tscn")
const WALL_TEXTURE: Texture2D = preload("res://assets/x_clear.png")

# New core rules: a 4 x 3 tray, one-cell orthogonal movement into empty cells,
# and horizontal/vertical matches of 3 or more identical colors.
const BOARD_ROWS: int = 3
const BOARD_COLS: int = 4
const MATCH_LENGTH: int = 3
const PLAYABLE_SIZE: Vector2 = Vector2(228.0, 228.0)
const DEBUG_BOARD: bool = false

@onready var board: Node2D = $Board
@onready var tray: Sprite2D = $Tray
@onready var level_label: Label = $HUD/MarginContainer/VBoxContainer/TopBar/LevelLabel
@onready var coins_label: Label = $HUD/MarginContainer/VBoxContainer/TopBar/CoinsLabel
@onready var status_label: Label = $HUD/MarginContainer/VBoxContainer/StatusLabel
@onready var hint_button: Button = $HUD/MarginContainer/VBoxContainer/BottomBar/HintButton
@onready var reset_button: Button = $HUD/MarginContainer/VBoxContainer/BottomBar/ShuffleButton

var level_number: int = 1
var level_data: Dictionary = {}
var walls: Dictionary = {}
var grid: Dictionary = {}
var luggages: Array[Luggage] = []
var save_data: Dictionary = {}
var selected_luggage: Luggage = null
var cell_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	save_data = SaveManager.load_save()
	_configure_visuals()
	load_level(level_number)
	hint_button.pressed.connect(_on_hint_pressed)
	reset_button.pressed.connect(_on_reset_pressed)


func _configure_visuals() -> void:
	_fit_sprite_to_width(tray, 430.0)
	reset_button.text = "Reset"


func _fit_sprite_to_width(sprite: Sprite2D, target_width: float) -> void:
	if sprite == null or sprite.texture == null:
		return
	var texture_width: float = float(sprite.texture.get_width())
	if texture_width <= 0.0:
		return
	var factor: float = target_width / texture_width
	sprite.scale = Vector2(factor, factor)


func _fit_sprite_to_cell(sprite: Sprite2D, target_size: float) -> void:
	if sprite == null or sprite.texture == null:
		return
	var width: float = float(sprite.texture.get_width())
	var height: float = float(sprite.texture.get_height())
	var largest: float = maxf(width, height)
	if largest <= 0.0:
		return
	var factor: float = target_size / largest
	sprite.scale = Vector2(factor, factor)


func load_level(level_id: int) -> void:
	_clear_selection()
	level_number = level_id
	level_data = LevelManager.load_level(level_id)
	level_label.text = "Level %d" % level_id
	coins_label.text = "Coins: %d" % int(save_data.get("coins", 0))
	status_label.text = "Tap a suitcase, then an empty space"

	walls.clear()
	grid.clear()
	luggages.clear()
	for child: Node in board.get_children():
		child.queue_free()

	cell_size = Vector2(
		PLAYABLE_SIZE.x / float(BOARD_COLS),
		PLAYABLE_SIZE.y / float(BOARD_ROWS)
	)

	if DEBUG_BOARD:
		_create_debug_grid()

	for wall: Dictionary in level_data.get("walls", []):
		var wall_row: int = int(wall.get("row", 0))
		var wall_col: int = int(wall.get("col", 0))
		if not _is_inside_board(wall_row, wall_col):
			continue
		walls[Vector2i(wall_row, wall_col)] = true
		_create_wall_visual(wall_row, wall_col)

	for luggage_data: Dictionary in level_data.get("luggages", []):
		var luggage: Luggage = LUGGAGE_SCENE.instantiate() as Luggage
		if luggage == null:
			continue

		luggage.row = int(luggage_data.get("row", 0))
		luggage.col = int(luggage_data.get("col", 0))
		if not _is_inside_board(luggage.row, luggage.col):
			luggage.queue_free()
			continue

		var cell := Vector2i(luggage.row, luggage.col)
		if walls.has(cell) or grid.has(cell):
			luggage.queue_free()
			continue

		luggage.color = String(luggage_data.get("color", "red"))
		luggage.position = board_position_for(luggage.row, luggage.col)

		# Keep the whole suitcase comfortably inside its rectangular grid cell.
		var visual_target: float = minf(cell_size.x, cell_size.y) * 0.82
		var luggage_scale: float = visual_target / 44.0
		luggage.scale = Vector2(luggage_scale, luggage_scale)
		luggage.pressed.connect(_on_luggage_pressed)

		board.add_child(luggage)
		luggages.append(luggage)
		grid[cell] = luggage


func _create_debug_grid() -> void:
	for row: int in range(BOARD_ROWS):
		for col: int in range(BOARD_COLS):
			var tile_node := ColorRect.new()
			tile_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile_node.color = Color(0.2, 0.8, 1.0, 0.12)
			tile_node.size = Vector2(cell_size.x - 1.0, cell_size.y - 1.0)
			tile_node.position = board_position_for(row, col) - tile_node.size * 0.5
			board.add_child(tile_node)


func _create_wall_visual(row: int, col: int) -> void:
	var wall_node := Sprite2D.new()
	wall_node.texture = WALL_TEXTURE
	wall_node.position = board_position_for(row, col)
	wall_node.centered = true
	_fit_sprite_to_cell(wall_node, minf(cell_size.x, cell_size.y) * 0.78)
	board.add_child(wall_node)


func board_position_for(row: int, col: int) -> Vector2:
	return Vector2(
		col * cell_size.x + cell_size.x * 0.5,
		row * cell_size.y + cell_size.y * 0.5
	)


func _is_inside_board(row: int, col: int) -> bool:
	return row >= 0 and row < BOARD_ROWS and col >= 0 and col < BOARD_COLS


func _on_luggage_pressed(luggage: Luggage) -> void:
	if luggage == null or luggage.collected:
		return

	# Clicking the selected suitcase again cancels selection.
	if selected_luggage == luggage:
		_clear_selection()
		status_label.text = "Selection cancelled"
	else:
		_clear_selection()
		selected_luggage = luggage
		selected_luggage.set_selected(true)
		status_label.text = "Choose an adjacent empty space"

	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if selected_luggage == null:
		return

	var screen_position := Vector2.ZERO
	var should_try_move := false

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			screen_position = mouse_event.position
			should_try_move = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			screen_position = touch_event.position
			should_try_move = true

	if not should_try_move:
		return

	var target_cell := _screen_position_to_cell(screen_position)
	if target_cell == Vector2i(-1, -1):
		status_label.text = "Choose a space inside the tray"
		return

	_try_move_selected_to(target_cell.x, target_cell.y)


func _screen_position_to_cell(screen_position: Vector2) -> Vector2i:
	var local_position: Vector2 = board.to_local(screen_position)
	if local_position.x < 0.0 or local_position.y < 0.0:
		return Vector2i(-1, -1)
	if local_position.x >= PLAYABLE_SIZE.x or local_position.y >= PLAYABLE_SIZE.y:
		return Vector2i(-1, -1)

	var col: int = int(floor(local_position.x / cell_size.x))
	var row: int = int(floor(local_position.y / cell_size.y))
	if not _is_inside_board(row, col):
		return Vector2i(-1, -1)
	return Vector2i(row, col)


func _try_move_selected_to(target_row: int, target_col: int) -> void:
	if selected_luggage == null:
		return

	var luggage := selected_luggage
	var from_cell := Vector2i(luggage.row, luggage.col)
	var target_cell := Vector2i(target_row, target_col)

	if not _is_inside_board(target_row, target_col):
		status_label.text = "That space is outside the tray"
		return
	if walls.has(target_cell):
		status_label.text = "That space is blocked"
		return
	if grid.has(target_cell):
		status_label.text = "That space is occupied"
		return
	if not _cells_are_adjacent(from_cell, target_cell):
		status_label.text = "Move only one space up, down, left, or right"
		return

	grid.erase(from_cell)
	grid[target_cell] = luggage
	luggage.row = target_row
	luggage.col = target_col
	luggage.position = board_position_for(target_row, target_col)

	_clear_selection()
	_resolve_matches_after_move()


func _cells_are_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


func _resolve_matches_after_move() -> void:
	var matches := _find_matches()
	if matches.is_empty():
		status_label.text = "Moved — make 3 in a row"
		return

	for luggage: Luggage in matches:
		var cell := Vector2i(luggage.row, luggage.col)
		grid.erase(cell)
		luggages.erase(luggage)
		luggage.collected = true
		luggage.visible = false
		luggage.queue_free()

	status_label.text = "MATCH! %d suitcases cleared" % matches.size()
	if luggages.is_empty():
		_on_level_cleared()


func _find_matches() -> Array[Luggage]:
	var matches: Array[Luggage] = []

	# Horizontal runs.
	for row: int in range(BOARD_ROWS):
		var col: int = 0
		while col < BOARD_COLS:
			var first := grid.get(Vector2i(row, col), null) as Luggage
			if first == null:
				col += 1
				continue

			var run: Array[Luggage] = [first]
			var next_col: int = col + 1
			while next_col < BOARD_COLS:
				var next_luggage := grid.get(Vector2i(row, next_col), null) as Luggage
				if next_luggage == null or next_luggage.color != first.color:
					break
				run.append(next_luggage)
				next_col += 1

			if run.size() >= MATCH_LENGTH:
				_add_unique_matches(matches, run)
			col = next_col

	# Vertical runs.
	for col: int in range(BOARD_COLS):
		var row: int = 0
		while row < BOARD_ROWS:
			var first := grid.get(Vector2i(row, col), null) as Luggage
			if first == null:
				row += 1
				continue

			var run: Array[Luggage] = [first]
			var next_row: int = row + 1
			while next_row < BOARD_ROWS:
				var next_luggage := grid.get(Vector2i(next_row, col), null) as Luggage
				if next_luggage == null or next_luggage.color != first.color:
					break
				run.append(next_luggage)
				next_row += 1

			if run.size() >= MATCH_LENGTH:
				_add_unique_matches(matches, run)
			row = next_row

	return matches


func _add_unique_matches(matches: Array[Luggage], run: Array[Luggage]) -> void:
	for luggage: Luggage in run:
		if luggage not in matches:
			matches.append(luggage)


func _clear_selection() -> void:
	if selected_luggage != null and is_instance_valid(selected_luggage):
		selected_luggage.set_selected(false)
	selected_luggage = null


func _on_hint_pressed() -> void:
	status_label.text = "Move into an adjacent empty space. Match 3 horizontally or vertically."


func _on_reset_pressed() -> void:
	load_level(level_number)


func _on_level_cleared() -> void:
	save_data["coins"] = int(save_data.get("coins", 0)) + 20
	save_data["highest_level"] = maxi(int(save_data.get("highest_level", 1)), level_number + 1)
	SaveManager.save(save_data)
	status_label.text = "LEVEL COMPLETE"
	var scene: PackedScene = load("res://scenes/level_complete.tscn") as PackedScene
	if scene != null:
		get_tree().change_scene_to_packed(scene)
