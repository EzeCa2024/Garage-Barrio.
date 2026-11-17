extends CharacterBody3D
## Jugador en primera persona - PC (WASD+mouse) + Android (joystick tactil)
class_name FPSPlayer

@export var walk_speed: float = 3.5
@export var sprint_mult: float = 1.6
@export var jump_force: float = 4.2
@export var mouse_sens: float = 0.0025
@export var touch_look_sens: float = 0.004

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hand: Node3D = $Head/Camera3D/Hand
@onready var grab_ray: RayCast3D = $Head/Camera3D/GrabRay

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var look_touch_id: int = -1
var look_last_pos: Vector2 = Vector2.ZERO
var move_vector: Vector2 = Vector2.ZERO # seteado por joystick tactil
var held_object: Node3D = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD) else Input.MOUSE_MODE_VISIBLE
	# en web/android el mouse capturado no aplica, se usa tactil

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		head.rotate_x(-event.relative.y * mouse_sens)
		head.rotation.x = clampf(head.rotation.x, -1.2, 1.2)
	if event is InputEventScreenDrag:
		# mitad derecha = mirar, mitad izquierda la maneja el joystick
		if event.index == look_touch_id or (look_touch_id == -1 and event.position.x > get_viewport().get_visible_rect().size.x * 0.4):
			if look_touch_id == -1:
				look_touch_id = event.index
				look_last_pos = event.position
			else:
				var d: Vector2 = event.position - look_last_pos
				look_last_pos = event.position
				rotate_y(-d.x * touch_look_sens)
				head.rotate_x(-d.y * touch_look_sens)
				head.rotation.x = clampf(head.rotation.x, -1.2, 1.2)
	if event is InputEventScreenTouch and not event.pressed and event.index == look_touch_id:
		look_touch_id = -1
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	# movimiento PC
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input_dir += move_vector # joystick android suma
	input_dir = input_dir.limit_length(1.0)
	var speed := walk_speed
	if Input.is_action_pressed("sprint"):
		speed *= sprint_mult
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir.length() > 0.01:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 8.0)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	move_and_slide()

func set_move_vector(v: Vector2) -> void:
	# joystick: x derecha, y abajo = atras. Convertimos a formato Godot (y arriba = adelante)
	move_vector = Vector2(v.x, -v.y)

func attach_to_hand(obj: Node3D) -> void:
	if held_object:
		drop_held()
	held_object = obj
	if obj.get_parent():
		obj.get_parent().remove_child(obj)
	hand.add_child(obj)
	obj.position = Vector3.ZERO
	obj.rotation = Vector3.ZERO
	if obj is RigidBody3D:
		(obj as RigidBody3D).freeze = true
		(obj as RigidBody3D).collision_layer = 0
		(obj as RigidBody3D).collision_mask = 0

func drop_held() -> void:
	if held_object == null:
		return
	var obj := held_object
	held_object = null
	hand.remove_child(obj)
	get_tree().current_scene.add_child(obj)
	obj.global_position = hand.global_position - global_transform.basis.z * 0.2
	if obj is RigidBody3D:
		var rb := obj as RigidBody3D
		rb.collision_layer = 2
		rb.collision_mask = 1 | 2
		rb.freeze = false
		rb.linear_velocity = -global_transform.basis.z * 2.5 + Vector3.UP * 1.0

func throw_held() -> void:
	if held_object == null:
		return
	var obj := held_object
	held_object = null
	hand.remove_child(obj)
	get_tree().current_scene.add_child(obj)
	obj.global_position = hand.global_position
	if obj is RigidBody3D:
		var rb := obj as RigidBody3D
		rb.collision_layer = 2
		rb.collision_mask = 1 | 2
		rb.freeze = false
		rb.linear_velocity = -global_transform.basis.z * 6.0 + Vector3.UP * 2.0
		rb.angular_velocity = Vector3(randf(), randf(), randf()) * 3.0
