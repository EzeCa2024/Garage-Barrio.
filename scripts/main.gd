extends Node3D
## Main - junta todo: Game + Garage + Clientes + UI
# Poner este script en scenes/Main.tscn (nodo root)

@onready var game: GameManager = $Game
@onready var garage: GarageManager = $Garage
@onready var clients: ClientManager = $Clients
@onready var hud: HUD = $UI/HUD
@onready var client_panel: ClientPanel = $UI/ClientPanel
@onready var repair_panel: RepairPanel = $UI/RepairPanel
@onready var minigame: RepairMinigame = $UI/Minigame
@onready var next_btn: Button = $UI/NextClientButton
@onready var car_mesh: MeshInstance3D = $Garage/CarBody

var active_car: CarData = null
var active_lift: int = -1
var pending_fault: String = ""

func _ready() -> void:
	garage.game = game
	hud.bind(game)
	clients.new_client_arrived.connect(_on_new_client)
	client_panel.accept_car.connect(_on_accept_car)
	client_panel.skip_car.connect(_on_skip_car)
	repair_panel.repair_requested.connect(_on_repair_requested)
	repair_panel.deliver_car.connect(_on_deliver_car)
	minigame.repair_finished.connect(_on_repair_finished)
	next_btn.pressed.connect(_on_next_client_button)
	minigame.visible = false
	client_panel.visible = false
	repair_panel.visible = false

func _on_next_client_button() -> void:
	if active_car != null:
		return # ya hay un auto adentro
	if garage.is_full():
		next_btn.text = "Taller lleno"
		return
	clients.send_next_client(game)

func _on_new_client(car: CarData) -> void:
	active_car = car
	client_panel.show_car(car)
	# pinta el auto 3D con el color del cliente
	if car_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = car.color
		car_mesh.set_surface_override_material(0, mat)

func _on_skip_car(_car: CarData) -> void:
	active_car = null
	game.add_reputation(-1)

func _on_accept_car(car: CarData) -> void:
	var idx := garage.dock_car(car)
	if idx == -1:
		return
	active_lift = idx
	repair_panel.show_car(car)

func _on_repair_requested(fault_id: String) -> void:
	var recipe: Dictionary = RepairSystem.get_recipe(fault_id)
	var cost := int(recipe.get("parts_cost", 0))
	if not game.spend(cost):
		# sin plata: avisa y no inicia
		return
	pending_fault = fault_id
	minigame.difficulty = float(recipe.get("difficulty", 0.4))
	repair_panel.visible = false
	minigame.start_game()

func _on_repair_finished(success: bool, quality: float) -> void:
	minigame.visible = false
	repair_panel.visible = true
	if success:
		repair_panel.fault_done(pending_fault)
		game.add_reputation(2 if quality > 0.8 else 1)
	else:
		# fallo: devuelve la mitad del costo y no repara
		var recipe: Dictionary = RepairSystem.get_recipe(pending_fault)
		game.add_money(int(int(recipe.get("parts_cost", 0)) * 0.5))
		game.add_reputation(-1)
	pending_fault = ""

func _on_deliver_car() -> void:
	if active_car == null:
		return
	garage.release_car(active_lift)
	game.complete_car(active_car.payout, 5)
	active_car = null
	active_lift = -1
	# cada 3 autos, pasa un dia
	if game.completed_cars % 3 == 0:
		game.next_day()
		next_btn.text = "🔔 Día %d - Llamar cliente" % game.day
