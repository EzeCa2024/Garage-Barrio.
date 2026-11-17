extends Node3D
## Main v0.2 - taller 3D simple + tienda + sonidos + multi-elevador
# Estructura esperada en Main.tscn (ver archivo .tscn v0.2)

@onready var game: GameManager = $Game
@onready var garage: GarageManager = $Garage
@onready var clients: ClientManager = $Clients
@onready var sound: SoundManager = $Sound
@onready var hud: HUD = $UI/HUD
@onready var client_panel: ClientPanel = $UI/ClientPanel
@onready var repair_panel: RepairPanel = $UI/RepairPanel
@onready var minigame: RepairMinigame = $UI/Minigame
@onready var shop: ShopPanel = $UI/ShopPanel
@onready var next_btn: Button = $UI/BottomBar/NextClientButton
@onready var shop_btn: Button = $UI/BottomBar/ShopButton

# Visuales 3D (hasta 3 puestos)
@onready var car_meshes: Array = [$Garage/CarBody1, $Garage/CarBody2, $Garage/CarBody3]
@onready var lift_meshes: Array = [$Garage/Lift1, $Garage/Lift2, $Garage/Lift3]
@onready var deco_light: OmniLight3D = $Garage/DecoLight

var pending_client: CarData = null # cliente en puerta, sin aceptar aun
var active_lift: int = -1 # puesto que estamos reparando ahora
var pending_fault: String = ""

func _ready() -> void:
	garage.game = game
	hud.bind(game)
	shop.bind(game, garage)
	# aplica mejoras guardadas
	_apply_upgrades_visual()

	clients.new_client_arrived.connect(_on_new_client)
	client_panel.accept_car.connect(_on_accept_car)
	client_panel.skip_car.connect(_on_skip_car)
	repair_panel.repair_requested.connect(_on_repair_requested)
	repair_panel.deliver_car.connect(_on_deliver_car)
	minigame.repair_finished.connect(_on_repair_finished)
	shop.upgrade_bought.connect(_on_upgrade_bought)
	next_btn.pressed.connect(_on_next_client_button)
	shop_btn.pressed.connect(func() -> void: sound.click(); shop.open_shop())
	game.upgrade_unlocked.connect(_on_upgrade_bought)

	minigame.visible = false
	client_panel.visible = false
	repair_panel.visible = false
	shop.visible = false
	_refresh_garage_visual()

func _on_next_client_button() -> void:
	sound.click()
	if pending_client != null:
		client_panel.show_car(pending_client)
		return
	if garage.is_full():
		next_btn.text = "Taller lleno (%d/%d)" % [garage.docked_count(), garage.max_lifts]
		return
	clients.send_next_client(game)

func _on_new_client(car: CarData) -> void:
	pending_client = car
	client_panel.show_car(car)

func _on_skip_car(_car: CarData) -> void:
	sound.click()
	pending_client = null
	game.add_reputation(-1)

func _on_accept_car(car: CarData) -> void:
	sound.click()
	var idx := garage.dock_car(car)
	if idx == -1:
		pending_client = null
		return
	pending_client = null
	# si no hay reparacion activa, esta pasa a ser la activa
	if active_lift == -1:
		active_lift = idx
		repair_panel.show_car(car)
	else:
		# hay otro en curso: avisa pero lo deja en cola
		repair_panel.show_car(_car_for_lift(active_lift))
	_refresh_garage_visual()
	_update_next_btn()

func _car_for_lift(idx: int) -> CarData:
	if idx < 0 or idx >= garage.lifts.size():
		return null
	return garage.lifts[idx] as CarData

func _on_repair_requested(fault_id: String) -> void:
	var recipe: Dictionary = RepairSystem.get_recipe(fault_id)
	var cost := int(recipe.get("parts_cost", 0))
	if not game.spend(cost):
		sound.fail()
		return
	sound.click()
	pending_fault = fault_id
	var base_diff := float(recipe.get("difficulty", 0.4))
	var mult := game.difficulty_mult()
	# compresor ayuda extra en frenos/neumaticos
	if game.has_upgrade("compresor") and (fault_id == "neumaticos" or fault_id == "frenos"):
		mult *= 0.85
	minigame.difficulty = clampf(base_diff * mult, 0.08, 0.95)
	repair_panel.visible = false
	minigame.start_game()

func _on_repair_finished(success: bool, quality: float) -> void:
	minigame.visible = false
	repair_panel.visible = true
	if success:
		sound.success()
		repair_panel.fault_done(pending_fault)
		game.add_reputation(2 if quality > 0.8 else 1)
	else:
		sound.fail()
		var recipe: Dictionary = RepairSystem.get_recipe(pending_fault)
		game.add_money(int(int(recipe.get("parts_cost", 0)) * 0.5))
		game.add_reputation(-1)
	pending_fault = ""

func _on_deliver_car() -> void:
	var car: CarData = _car_for_lift(active_lift)
	if car == null:
		return
	# solo se puede entregar si no tiene fallas
	if not car.faults.is_empty():
		sound.fail()
		return
	sound.cash()
	garage.release_car(active_lift)
	game.complete_car(car.payout, 5)
	# busca siguiente auto en cola
	active_lift = garage.free_lift() # truco: buscamos ocupado
	active_lift = _first_occupied_lift()
	if active_lift != -1:
		repair_panel.show_car(_car_for_lift(active_lift))
	else:
		repair_panel.visible = false
	if game.completed_cars % 3 == 0:
		game.next_day()
	_refresh_garage_visual()
	_update_next_btn()

func _first_occupied_lift() -> int:
	for i in garage.lifts.size():
		if garage.lifts[i] != null:
			return i
	return -1

func _on_upgrade_bought(_id: String) -> void:
	sound.buy()
	garage.set_max_lifts(game.max_lifts_allowed())
	_apply_upgrades_visual()
	_refresh_garage_visual()
	_update_next_btn()

func _apply_upgrades_visual() -> void:
	garage.set_max_lifts(game.max_lifts_allowed())
	# deco: luz calida si compraste pintura y luces
	if deco_light:
		if game.has_upgrade("deco1"):
			deco_light.light_color = Color(1.0, 0.85, 0.6)
			deco_light.light_energy = 1.2
		else:
			deco_light.light_color = Color(0.7, 0.75, 1.0)
			deco_light.light_energy = 0.6

func _refresh_garage_visual() -> void:
	# muestra/oculta elevadores segun max y pinta autos
	for i in 3:
		var has_slot := i < garage.max_lifts
		if i < lift_meshes.size() and lift_meshes[i]:
			lift_meshes[i].visible = has_slot
		var car_node: MeshInstance3D = car_meshes[i] if i < car_meshes.size() else null
		if car_node == null:
			continue
		if not has_slot:
			car_node.visible = false
			continue
		var car: CarData = garage.lifts[i] if i < garage.lifts.size() else null
		if car == null:
			car_node.visible = false
		else:
			car_node.visible = true
			var mat := StandardMaterial3D.new()
			mat.albedo_color = car.color
			car_node.set_surface_override_material(0, mat)

func _update_next_btn() -> void:
	if garage.is_full():
		next_btn.text = "Taller lleno (%d/%d)" % [garage.docked_count(), garage.max_lifts]
	else:
		next_btn.text = "🔔 Llamar cliente (%d/%d) — Día %d" % [garage.docked_count(), garage.max_lifts, game.day]
