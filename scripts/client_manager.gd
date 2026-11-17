extends Node
## Genera clientes aleatorios segun dia y reputacion
class_name ClientManager

signal new_client_arrived(car: CarData)

var rng := RandomNumberGenerator.new()

const NAMES := ["Don Pipo", "La Tana", "El Rulo", "Marta", "Jorge", "Kevin", "Susana", "El Facha", "Doña Rosa", "Pablito"]
const MODELS := ["Familiar 98", "Corsa Barrial", "Pickup Vieja", "Sedan Gris", "Hatchback 2010", "Furgoneta"]

func _ready() -> void:
	rng.randomize()

func generate_client(day: int, reputation: int) -> CarData:
	var car := CarData.new()
	car.owner_name = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	car.model = MODELS[rng.randi_range(0, MODELS.size() - 1)]
	car.color = Color(rng.randf(), rng.randf(), rng.randf())

	# 1 a 3 fallas, mas fallas si sube el dia
	var max_faults: int = 1
	if day >= 2:
		max_faults = 2
	if day >= 4 or reputation >= 40:
		max_faults = 3

	var ids := RepairSystem.all_ids()
	ids.shuffle()
	var count := rng.randi_range(1, max_faults)
	car.faults = ids.slice(0, count)

	# Calcula pago total
	var total := 0
	for f in car.faults:
		var r: Dictionary = RepairSystem.get_recipe(f)
		total += int(r.get("payout", 50))
	car.payout = total
	return car

func send_next_client(game: GameManager) -> void:
	var car := generate_client(game.day, game.reputation)
	new_client_arrived.emit(car)
