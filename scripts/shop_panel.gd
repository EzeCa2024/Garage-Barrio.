extends Control
## Tienda de mejoras: lista, compra, aplica. Botones grandes para Android.
class_name ShopPanel

signal upgrade_bought(upgrade_id: String)

var game: GameManager
var garage: GarageManager

@onready var title: Label = $Panel/Margin/VBox/Title
@onready var money_label: Label = $Panel/Margin/VBox/MoneyLabel
@onready var list: VBoxContainer = $Panel/Margin/VBox/ShopList
@onready var close_btn: Button = $Panel/Margin/VBox/CloseButton

func _ready() -> void:
	close_btn.pressed.connect(func() -> void: visible = false)

func bind(g: GameManager, gar: GarageManager) -> void:
	game = g
	garage = gar
	if game:
		game.money_changed.connect(func(_v: int) -> void: refresh())
	refresh()

func open_shop() -> void:
	visible = true
	refresh()

func refresh() -> void:
	if game == null:
		return
	for c in list.get_children():
		c.queue_free()
	money_label.text = "💰 $%d" % game.money
	title.text = "🏪 Tienda del taller — Día %d" % game.day
	for id in UpgradesSystem.all_ids():
		var item: Dictionary = UpgradesSystem.get_item(id)
		var owned: bool = game.upgrades.get(id, false)
		var check: Dictionary = UpgradesSystem.can_buy(id, game.upgrades, game.money)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := Label.new()
		info.custom_minimum_size = Vector2(300, 0)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var status := "✅" if owned else ("$%d" % int(item.get("cost", 0)))
		info.text = "%s %s\n%s [%s]" % [item.get("icon", "🔧"), item.get("label", id), item.get("desc", ""), status]
		row.add_child(info)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 56)
		if owned:
			btn.text = "Comprado"
			btn.disabled = true
		else:
			btn.text = "Comprar"
			btn.disabled = not bool(check.get("ok", false))
			btn.tooltip_text = str(check.get("reason", ""))
			btn.pressed.connect(_on_buy.bind(id))
		row.add_child(btn)
		list.add_child(row)

func _on_buy(id: String) -> void:
	if game == null:
		return
	var item: Dictionary = UpgradesSystem.get_item(id)
	var check: Dictionary = UpgradesSystem.can_buy(id, game.upgrades, game.money)
	if not bool(check.get("ok", false)):
		return
	if game.spend(int(item.get("cost", 0))):
		game.unlock_upgrade(id)
		upgrade_bought.emit(id)
		refresh()
