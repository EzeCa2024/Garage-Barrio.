extends Node3D
## GarageManager - controla elevadores y autos en reparacion
class_name GarageManager

signal car_docked(car: CarData, lift_index: int)
signal car_repaired(car: CarData, lift_index: int)

@export var max_lifts: int = 1
var lifts: Array = [] # cada slot: null o CarData
var game: GameManager

func _ready() -> void:
	if lifts.is_empty():
		lifts.resize(maxi(1, max_lifts))
		lifts.fill(null)
	game = get_node_or_null("/root/Game") as GameManager

func free_lift() -> int:
	for i in lifts.size():
		if lifts[i] == null:
			return i
	return -1

func dock_car(car: CarData) -> int:
	var idx := free_lift()
	if idx == -1:
		return -1
	lifts[idx] = car
	car_docked.emit(car, idx)
	return idx

func release_car(lift_index: int) -> CarData:
	if lift_index < 0 or lift_index >= lifts.size():
		return null
	var car: CarData = lifts[lift_index]
	lifts[lift_index] = null
	if car:
		car_repaired.emit(car, lift_index)
	return car

func is_full() -> bool:
	return free_lift() == -1

func set_max_lifts(n: int) -> void:
	n = clampi(n, 1, 4)
	max_lifts = n
	while lifts.size() < n:
		lifts.append(null)

func docked_count() -> int:
	var c := 0
	for x in lifts:
		if x != null:
			c += 1
	return c
