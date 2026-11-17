extends Control
## Joystick virtual izquierda para Android (tambien anda con mouse)
signal move(v: Vector2)

var radius: float = 70.0
var dragging_id: int = -1
var center: Vector2 = Vector2.ZERO

@onready var base: ColorRect = $Base
@onready var knob: ColorRect = $Base/Knob

func _ready() -> void:
	center = base.global_position + base.size * 0.5

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging_id = event.index
			_update_knob(event.position)
		elif event.index == dragging_id:
			dragging_id = -1
			knob.position = Vector2.ZERO
			move.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == dragging_id:
		_update_knob(event.position)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging_id = -2
			_update_knob(event.position)
		elif not event.pressed and dragging_id == -2:
			dragging_id = -1
			move.emit(Vector2.ZERO)
	elif event is InputEventMouseMotion and dragging_id == -2:
		_update_knob(event.position)

func _update_knob(global_pos: Vector2) -> void:
	var local: Vector2 = global_pos - (base.global_position + base.size * 0.5)
	if local.length() > radius:
		local = local.normalized() * radius
	knob.position = local
	# normaliza -1..1, y arriba = adelante
	move.emit(local / radius)
