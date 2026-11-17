extends Node3D
## Auto real del simulador: entra manejando, tiene partes reparables/rompibles
class_name RealCar

signal part_changed(part_id: String, hp: float)
signal car_fixed()

@export var park_position: Vector3 = Vector3(0, 0, 0)
@export var enter_from: Vector3 = Vector3(0, 0, 18)

var parts: Dictionary = {
	"capo": {"hp": 100.0, "broken": false, "label": "Capo"},
	"motor": {"hp": 35.0, "broken": true, "label": "Motor"},
	"bateria": {"hp": 20.0, "broken": true, "label": "Bateria"},
	"rueda_del_izq": {"hp": 40.0, "broken": true, "label": "Rueda delantera"},
	"aceite": {"hp": 15.0, "broken": true, "label": "Aceite"},
}
var is_parked: bool = false
var driving_in: bool = false
var _t: float = 0.0

func setup_random(rng: RandomNumberGenerator) -> void:
	var keys := parts.keys()
	keys.shuffle()
	# 2 a 4 fallas
	var count := rng.randi_range(2, 4)
	for i in keys.size():
		var k: String = keys[i]
		if i < count:
			parts[k]["hp"] = rng.randf_range(5.0, 45.0)
			parts[k]["broken"] = true
		else:
			parts[k]["hp"] = 100.0
			parts[k]["broken"] = false

func drive_in() -> void:
	global_position = enter_from
	driving_in = true
	_t = 0.0
	is_parked = false

func _process(delta: float) -> void:
	if driving_in:
		_t += delta * 0.25
		global_position = enter_from.lerp(park_position, minf(1.0, _t))
		# ruido de motor simple: vibra
		position.y = 0.05 * sin(Time.get_ticks_msec() / 90.0) if _t < 1.0 else 0.0
		if _t >= 1.0:
			driving_in = false
			is_parked = true

func damage_part(part_id: String, amount: float) -> void:
	if not parts.has(part_id):
		return
	parts[part_id]["hp"] = clampf(float(parts[part_id]["hp"]) - amount, 0.0, 100.0)
	parts[part_id]["broken"] = float(parts[part_id]["hp"]) < 70.0
	part_changed.emit(part_id, float(parts[part_id]["hp"]))

func repair_part(part_id: String, amount: float) -> bool:
	# retorna true si se arreglo del todo
	if not parts.has(part_id):
		return false
	parts[part_id]["hp"] = clampf(float(parts[part_id]["hp"]) + amount, 0.0, 100.0)
	if float(parts[part_id]["hp"]) >= 99.0:
		parts[part_id]["broken"] = false
		part_changed.emit(part_id, 100.0)
		check_fixed()
		return true
	parts[part_id]["broken"] = float(parts[part_id]["hp"]) < 70.0
	part_changed.emit(part_id, float(parts[part_id]["hp"]))
	return false

func broken_parts() -> Array:
	var out: Array = []
	for k in parts.keys():
		if bool(parts[k]["broken"]):
			out.append(k)
	return out

func check_fixed() -> void:
	if broken_parts().is_empty():
		car_fixed.emit()

func test_part(part_id: String) -> String:
	# testeo: devuelve diagnostico textual estilo scanner
	if not parts.has(part_id):
		return "?"
	var hp: float = float(parts[part_id]["hp"])
	var label: String = str(parts[part_id]["label"])
	if hp >= 70.0:
		return "%s OK (%.0f%%)" % [label, hp]
	elif hp >= 30.0:
		return "%s DESGASTADO (%.0f%%) - reparar" % [label, hp]
	else:
		return "%s CRITICO (%.0f%%) - cambio urgente" % [label, hp]
