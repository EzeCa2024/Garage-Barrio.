extends Control
## HUD superior: plata, dia, reputacion + botones
class_name HUD

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var day_label: Label = $TopBar/DayLabel
@onready var rep_label: Label = $TopBar/RepLabel

var game: GameManager

func bind(g: GameManager) -> void:
	game = g
	game.money_changed.connect(_on_money)
	game.reputation_changed.connect(_on_rep)
	game.day_changed.connect(_on_day)
	refresh()

func refresh() -> void:
	if game == null:
		return
	_on_money(game.money)
	_on_rep(game.reputation)
	_on_day(game.day)

func _on_money(v: int) -> void:
	money_label.text = "💰 $%d" % v

func _on_rep(v: int) -> void:
	rep_label.text = "⭐ %d" % v

func _on_day(v: int) -> void:
	day_label.text = "Día %d" % v
