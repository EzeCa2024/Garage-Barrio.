extends Node
## GameManager - estado global del taller (Autoload recomendado: Game)
class_name GameManager

signal money_changed(new_money: int)
signal reputation_changed(new_rep: int)
signal day_changed(new_day: int)

var money: int = 500
var reputation: int = 10 # 0-100
var day: int = 1
var completed_cars: int = 0

const SAVE_PATH := "user://savegame.json"

func _ready() -> void:
	load_game()

func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)

func can_afford(cost: int) -> bool:
	return money >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	add_money(-cost)
	return true

func add_reputation(amount: int) -> void:
	reputation = clampi(reputation + amount, 0, 100)
	reputation_changed.emit(reputation)

func next_day() -> void:
	day += 1
	day_changed.emit(day)
	save_game()

func complete_car(payout: int, rep_gain: int) -> void:
	add_money(payout)
	add_reputation(rep_gain)
	completed_cars += 1
	save_game()

func save_game() -> void:
	var data := {
		"money": money,
		"reputation": reputation,
		"day": day,
		"completed_cars": completed_cars,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	money = int(parsed.get("money", money))
	reputation = int(parsed.get("reputation", reputation))
	day = int(parsed.get("day", day))
	completed_cars = int(parsed.get("completed_cars", 0))
