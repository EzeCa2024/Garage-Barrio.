extends Node3D
## Manager FPS: auto entra, primera persona repara, cobrar, tienda sigue valiendo
class_name FPSGarageManager

@onready var player: FPSPlayer = $Player
@onready var car: RealCar = $Car
@onready var interact: InteractSystem = $Interact
@onready var game: GameManager = $Game
@onready var sound: SoundManager = $Sound
@onready var spawn_tools: Node3D = $ToolShelf

@onready var hint_label: Label = $UI/Crosshair/Hint
@onready var msg_label: Label = $UI/Message
@onready var task_label: Label = $UI/TaskList
@onready var money_label: Label = $UI/TopBar/Money
@onready var call_btn: Button = $UI/BottomBar/CallButton
@onready var interact_btn: Button = $UI/BottomBar/InteractButton
@onready var drop_btn: Button = $UI/BottomBar/DropButton
@onready var joy: Control = $UI/Joystick

var rng := RandomNumberGenerator.new()
var payout_base: int = 0

func _ready() -> void:
	rng.randomize()
	interact.setup(player, car, game, sound)
	interact.focused.connect(func(t: String) -> void: hint_label.text = t)
	interact.message.connect(_show_msg)
	game.money_changed.connect(func(v: int) -> void: money_label.text = "💰 $%d" % v)
	money_label.text = "💰 $%d" % game.money
	call_btn.pressed.connect(call_client)
	interact_btn.pressed.connect(func() -> void: interact.interact())
	drop_btn.pressed.connect(_on_drop_button)
	car.car_fixed.connect(_on_car_fixed)
	car.part_changed.connect(func(_id: String, _hp: float) -> void: _refresh_tasks())
	# joystick -> player
	joy.move.connect(func(v: Vector2) -> void: player.set_move_vector(v))
	_show_msg("WASD para moverte, E para agarrar/usar, Click para golpear. En celular usa joystick + botones.")
	_refresh_tasks()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact.interact()
	if event.is_action_pressed("drop"):
		_on_drop_button()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			interact.hit_attack()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventScreenTouch and event.pressed:
		# toque rapido en mitad derecha sin arrastrar = golpear? lo dejamos al boton Interactuar
		pass

func call_client() -> void:
	if car.driving_in or not car.is_parked and car.broken_parts().size() > 0 and car.global_position.length() < 1.0:
		_show_msg("Ya hay un auto en el taller")
		return
	sound.click()
	car.setup_random(rng)
	# calcula pago segun fallas
	payout_base = 80 * car.broken_parts().size() + 40
	car.drive_in()
	_show_msg("🚗 Cliente en camino... el auto va a entrar solo al elevador")
	_refresh_tasks()

func _refresh_tasks() -> void:
	var lines: Array[String] = []
	lines.append("📋 TAREAS:")
	if not car.is_parked and not car.driving_in and car.broken_parts().is_empty():
		lines.append("- Llama un cliente con 🔔")
	elif car.driving_in:
		lines.append("- Esperando que entre el auto...")
	else:
		for p in car.broken_parts():
			lines.append("- %s" % car.test_part(p))
		if car.broken_parts().is_empty() and car.is_parked:
			lines.append("✅ Listo! Anda a la puerta y cobra (boton Cobrar)")
			call_btn.text = "💵 Cobrar $%d" % int(payout_base * game.payout_bonus_mult())
		else:
			call_btn.text = "🔔 Llamar cliente"
	task_label.text = "\n".join(lines)

func _on_car_fixed() -> void:
	sound.cash()
	call_btn.text = "💵 Cobrar $%d" % int(payout_base * game.payout_bonus_mult())
	_show_msg("✅ Auto reparado! Cobra con el boton")
	# si ya estaba listo y apretan llamar, cobra
	if not call_btn.pressed.is_connected(_on_collect):
		call_btn.pressed.disconnect(call_client)
		call_btn.pressed.connect(_on_collect)

func _on_collect() -> void:
	var pay := int(payout_base * game.payout_bonus_mult())
	game.complete_car(pay, 5 + game.reputation_bonus_extra())
	sound.cash()
	_show_msg("💵 Cobraste $%d. Llama al siguiente!" % pay)
	# resetea auto fuera
	car.global_position = Vector3(0, -5, 0)
	car.is_parked = false
	payout_base = 0
	_respawn_tools()
	call_btn.pressed.disconnect(_on_collect)
	call_btn.pressed.connect(call_client)
	_refresh_tasks()

func _on_drop_button() -> void:
	if player.held_object:
		player.drop_held()
		_show_msg("Soltaste la herramienta")

func _show_msg(t: String) -> void:
	msg_label.text = t

func _respawn_tools() -> void:
	# si se gasto aceite/bateria, reaparecen
	for c in spawn_tools.get_children():
		if c is PickableTool:
			continue
	# simple: si no hay aceite, crea uno
	var has_oil := false
	var has_bat := false
	for n in get_tree().get_nodes_in_group("tools"):
		if (n as PickableTool).tool_id == "aceite":
			has_oil = true
		if (n as PickableTool).tool_id == "bateria_nueva":
			has_bat = true
	if not has_oil:
		_spawn_tool("aceite", "Bidon Aceite", Vector3(2.2, 1.1, -4.5))
	if not has_bat:
		_spawn_tool("bateria_nueva", "Bateria Nueva", Vector3(2.6, 1.1, -4.5))

func _spawn_tool(id: String, label: String, pos: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.set_script(load("res://scripts/fps/pickable_tool.gd"))
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.25, 0.25)
	mesh.mesh = box
	rb.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.25, 0.25, 0.25)
	col.shape = shape
	rb.add_child(col)
	rb.set("tool_id", id)
	rb.set("tool_label", label)
	rb.add_to_group("tools")
	add_child(rb)
	rb.global_position = pos
