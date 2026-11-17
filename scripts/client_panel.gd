extends Control
## Panel de cliente: muestra auto, fallas y boton Diagnosticar/Aceptar
class_name ClientPanel

signal accept_car(car: CarData)
signal skip_car(car: CarData)

var current_car: CarData

@onready var title: Label = $Panel/Margin/VBox/Title
@onready var desc: Label = $Panel/Margin/VBox/Desc
@onready var payout: Label = $Panel/Margin/VBox/Payout
@onready var accept_btn: Button = $Panel/Margin/VBox/AcceptButton
@onready var skip_btn: Button = $Panel/Margin/VBox/SkipButton

func _ready() -> void:
	accept_btn.pressed.connect(_on_accept_pressed)
	skip_btn.pressed.connect(_on_skip_pressed)

func show_car(car: CarData) -> void:
	current_car = car
	visible = true
	title.text = "🚗 Nuevo cliente: %s" % car.owner_name
	desc.text = car.get_description()
	payout.text = "Pago estimado: $%d" % car.payout

func _on_accept_pressed() -> void:
	if current_car:
		accept_car.emit(current_car)
	visible = false

func _on_skip_pressed() -> void:
	if current_car:
		skip_car.emit(current_car)
	visible = false
