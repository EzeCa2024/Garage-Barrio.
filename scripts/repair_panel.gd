extends Control
## Panel de reparacion: lista fallas, deja reparar una por una
class_name RepairPanel

signal repair_requested(fault_id: String)
signal deliver_car()

var current_car: CarData

@onready var title: Label = $Panel/Margin/VBox/Title
@onready var list: VBoxContainer = $Panel/Margin/VBox/FaultList
@onready var deliver_btn: Button = $Panel/Margin/VBox/DeliverButton

func _ready() -> void:
	deliver_btn.pressed.connect(_on_deliver_pressed)

func show_car(car: CarData) -> void:
	current_car = car
	visible = true
	refresh()

func refresh() -> void:
	for c in list.get_children():
		c.queue_free()
	if current_car == null or current_car.faults.is_empty():
		title.text = "✅ Auto listo para entregar"
		deliver_btn.disabled = false
		return
	title.text = "🔧 Reparando: %s (%d fallas)" % [current_car.model, current_car.faults.size()]
	deliver_btn.disabled = true
	for f in current_car.faults:
		var r: Dictionary = RepairSystem.get_recipe(f)
		var b := Button.new()
		b.text = "%s - $%d repuestos" % [r.get("label", f), int(r.get("parts_cost", 0))]
		b.custom_minimum_size = Vector2(0, 56) # grande para dedo en Android
		b.pressed.connect(_on_fault_button.bind(f))
		list.add_child(b)

func _on_fault_button(fault_id: String) -> void:
	repair_requested.emit(fault_id)

func fault_done(fault_id: String) -> void:
	if current_car:
		current_car.faults.erase(fault_id)
	refresh()

func _on_deliver_pressed() -> void:
	visible = false
	deliver_car.emit()
