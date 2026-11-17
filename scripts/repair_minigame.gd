extends Control
## Minijuego de reparacion: deten la aguja en la zona verde (click o toque)
class_name RepairMinigame

signal repair_finished(success: bool, quality: float) # quality 0-1

@export var difficulty: float = 0.4 # 0 facil - 1 dificil
var _t: float = 0.0
var _speed: float = 2.2
var _playing: bool = false
var _target_center: float = 0.5
var _target_size: float = 0.25

@onready var _bar: ColorRect = $Panel/VBox/Bar
@onready var _needle: ColorRect = $Panel/VBox/Bar/Needle
@onready var _zone: ColorRect = $Panel/VBox/Bar/Zone
@onready var _label: Label = $Panel/VBox/Label

func _ready() -> void:
	_target_size = lerpf(0.3, 0.12, clampf(difficulty, 0.0, 1.0))
	_speed = lerpf(1.6, 3.4, clampf(difficulty, 0.0, 1.0))
	_target_center = randf_range(0.25, 0.75)

func start_game() -> void:
	_playing = true
	_t = 0.0
	visible = true
	_label.text = "¡Toca / Click cuando la aguja este en VERDE!"

func _process(delta: float) -> void:
	if not _playing:
		return
	_t += delta * _speed
	var pos := (sin(_t * PI) * 0.5 + 0.5) # 0..1 ping-pong
	_needle.position.x = pos * (_bar.size.x - _needle.size.x)
	# actualiza zona verde
	_zone.anchor_left = _target_center - _target_size * 0.5
	_zone.anchor_right = _target_center + _target_size * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if not _playing or not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_attempt()
	elif event is InputEventScreenTouch and event.pressed:
		_attempt()

func _attempt() -> void:
	_playing = false
	var needle_center: float = _needle.position.x / maxf(1.0, _bar.size.x - _needle.size.x)
	var dist := absf(needle_center - _target_center)
	var half := _target_size * 0.5
	if dist <= half:
		var quality := 1.0 - (dist / half) * 0.5 # 0.5..1.0
		repair_finished.emit(true, quality)
	else:
		repair_finished.emit(false, 0.0)
