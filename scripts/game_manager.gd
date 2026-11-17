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
var upgrades: Dictionary = {} # id -> true

signal upgrade_unlocked(upgrade_id: String)

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
	# aplica bonus de tienda
	var bonus_pay := payout_bonus_mult()
	var bonus_rep := reputation_bonus_extra()
	add_money(int(round(payout * bonus_pay)))
	add_reputation(rep_gain + bonus_rep)
	completed_cars += 1
	save_game()

func unlock_upgrade(id: String) -> void:
	upgrades[id] = true
	upgrade_unlocked.emit(id)
	save_game()

func has_upgrade(id: String) -> bool:
	return bool(upgrades.get(id, false))

func payout_bonus_mult() -> float:
	var m := 1.0
	if has_upgrade("tools1"): m += 0.05
	if has_upgrade("tools2"): m += 0.10
	if has_upgrade("publi1"): m += 0.10
	if has_upgrade("publi2"): m += 0.20
	return m

func reputation_bonus_extra() -> int:
	var r := 0
	if has_upgrade("publi1"): r += 1
	if has_upgrade("publi2"): r += 2
	if has_upgrade("deco1"): r += 2
	return r

func difficulty_mult() -> float:
	var m := 1.0
	if has_upgrade("tools1"): m *= 0.85
	if has_upgrade("tools2"): m *= 0.75
	return m

func max_lifts_allowed() -> int:
	var n := 1
	if has_upgrade("lift2"): n += 1
	if has_upgrade("lift3"): n += 1
	return n

func save_game() -> void:
	var data := {
		"money": money,
		"reputation": reputation,
		"day": day,
		"completed_cars": completed_cars,
		"upgrades": upgrades,
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
	var u = parsed.get("upgrades", {})
	if typeof(u) == TYPE_DICTIONARY:
		upgrades = u
