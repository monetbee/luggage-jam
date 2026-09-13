extends Area2D
class_name Luggage

signal pressed(luggage: Luggage)

const COLOR_MAP := {
	"red": Color(0.93, 0.31, 0.29),
	"blue": Color(0.34, 0.56, 0.93),
	"green": Color(0.39, 0.82, 0.48),
	"yellow": Color(0.96, 0.82, 0.24),
	"purple": Color(0.63, 0.43, 0.94),
}

const TEXTURE_MAP := {
	"red": preload("res://assets/luggage_red＿clear.png"),
	"blue": preload("res://assets/luggage_blue_clear.png"),
	"green": preload("res://assets/luggage_green_clear.png"),
	"yellow": preload("res://assets/luggage_yellow_clear.png"),
	"purple": preload("res://assets/luggage_purple_clear.png"),
}

@onready var suitcase_body: Sprite2D = $VisualRoot/SuitcaseBody

var row: int = 0
var col: int = 0
var color: String = "red"
var direction: String = "right"
var board_size: int = 6
var collected: bool = false


func _ready() -> void:
	input_event.connect(_on_input_event)
	_apply_texture()
	_apply_direction_rotation()
	queue_redraw()


func _apply_texture() -> void:
	if suitcase_body == null:
		return
	var texture: Texture2D = TEXTURE_MAP.get(color, null)
	if texture == null:
		suitcase_body.texture = null
		return

	suitcase_body.texture = texture
	var width: float = float(texture.get_width())
	var height: float = float(texture.get_height())
	var largest: float = maxf(width, height)
	if largest > 0.0:
		var factor: float = 44.0 / largest
		suitcase_body.scale = Vector2(factor, factor)
	suitcase_body.centered = true
	suitcase_body.offset = Vector2.ZERO


func _apply_direction_rotation() -> void:
	if suitcase_body == null:
		return
	match direction:
		"up": suitcase_body.rotation = 0.0
		"right": suitcase_body.rotation = PI * 0.5
		"down": suitcase_body.rotation = PI
		"left": suitcase_body.rotation = -PI * 0.5
		_: suitcase_body.rotation = 0.0


func refresh_direction() -> void:
	_apply_direction_rotation()
	queue_redraw()


func _draw() -> void:
	if collected:
		return

	if suitcase_body == null or suitcase_body.texture == null:
		var size: float = 38.0
		var base_color: Color = COLOR_MAP.get(color, Color.WHITE)
		draw_rect(Rect2(-size * 0.5, -size * 0.5, size, size), base_color)


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit(self)


func direction_to_vector(dir_name: String) -> Vector2:
	match dir_name:
		"up": return Vector2(0, -1)
		"down": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
		_: return Vector2(0, -1)


func direction_to_grid_vector(dir_name: String) -> Vector2i:
	match dir_name:
		"up": return Vector2i(-1, 0)
		"down": return Vector2i(1, 0)
		"left": return Vector2i(0, -1)
		"right": return Vector2i(0, 1)
		_: return Vector2i(-1, 0)
