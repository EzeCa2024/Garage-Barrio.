extends Node3D
## Controla interaccion en primera persona: mirar + E / boton tactil
class_name InteractSystem

signal focused(text: String)
signal message(text: String)

@onready var ray: RayCast3D = $"../Player/Head/Camera3D/GrabRay"
var player: FPSPlayer
var car: RealCar
var game: GameManager
var sound: SoundManager

var hold_to_repair: float = 0.0
var current_part: String = ""

func setup(p: FPSPlayer, c: RealCar, g: GameManager, s: SoundManager) -> void:
	player = p
	car = c
	game = g
	sound = s

func _process(_delta: float) -> void:
	if ray == null or not ray.is_colliding():
		focused.emit("")
		current_part = ""
		return
	var hit: Object = ray.get_collider()
	var txt := ""
	if hit is PickableTool:
		var t := hit as PickableTool
		if player.held_object == null:
			txt = "[E] Agarrar %s" % t.tool_label
		else:
			txt = "[E] Cambiar por %s" % t.tool_label
		current_part = ""
	elif hit is Node and (hit as Node).is_in_group("car_part"):
		var part_id: String = (hit as Node).get_meta("part_id", "")
		if part_id != "":
			current_part = part_id
			if player.held_object is PickableTool:
				var tool := player.held_object as PickableTool
				txt = "[E] Usar %s en %s | [Click] golpear/romper" % [tool.tool_label, part_id]
			else:
				txt = "%s - mano vacia. Agarra una herramienta. [Click] golpear" % part_id
			# muestra testeo rapido si tenes tester? no, solo descripcion
	focused.emit(txt)

func interact() -> void:
	if ray == null or not ray.is_colliding():
		return
	var hit: Object = ray.get_collider()
	if hit is PickableTool:
		var t := hit as PickableTool
		# si ya tenes algo, lo tiras y agarras esto
		if player.held_object is PickableTool:
			player.drop_held()
		# quitar de la escena y poner en mano (reparent)
		var gp: Node = (t as Node).get_parent()
		if gp:
			gp.remove_child(t)
		player.attach_to_hand(t)
		sound.click()
		message.emit("Agarraste: %s" % t.tool_label)
	elif hit is Node and (hit as Node).is_in_group("car_part"):
		var part_id: String = (hit as Node).get_meta("part_id", "")
		if player.held_object is PickableTool:
			var tool := player.held_object as PickableTool
			var msg: String = tool.use_on_car(car, part_id)
			sound.success()
			message.emit(msg)
			# si era descartable y se gasto, mano queda vacia
			if not is_instance_valid(tool) or tool.get_parent() == null:
				# fue queue_free dentro de use_on_car, limpiar ref
				player.held_object = null
		else:
			message.emit("Necesitas una herramienta. Busca en la mesa.")

func hit_attack() -> void:
	# click sin herramienta o con herramienta: dania / hace ruido. Asi podes ROMPER.
	if ray != null and ray.is_colliding():
		var hit: Object = ray.get_collider()
		if hit is Node and (hit as Node).is_in_group("car_part"):
			var part_id: String = (hit as Node).get_meta("part_id", "")
			car.damage_part(part_id, 12.0)
			sound.fail()
			message.emit("💥 Golpeaste %s! %s" % [part_id, car.test_part(part_id)])
		elif hit is RigidBody3D:
			(hit as RigidBody3D).apply_impulse(Vector3(randf()-0.5, 0.8, randf()-0.5) * 2.0)
			sound.click()
			message.emit("Tiraste un objeto")
