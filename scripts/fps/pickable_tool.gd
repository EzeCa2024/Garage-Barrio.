extends RigidBody3D
## Herramienta agarrable: llave, multimetro, bidon aceite, etc.
class_name PickableTool

@export var tool_id: String = "llave"
@export var tool_label: String = "Llave"
@export var repair_power: float = 25.0
@export var can_test: bool = false # multimetro/tester puede diagnosticar

func use_on_car(car: RealCar, part_id: String) -> String:
	# retorna mensaje para HUD
	if car == null:
		return "Sin auto"
	# logica simple por herramienta
	match tool_id:
		"llave":
			if part_id in ["rueda_del_izq", "bateria", "motor"]:
				var fixed: bool = car.repair_part(part_id, repair_power)
				# golpear de mas puede romper? si ya esta al 100 y seguis, lo danias
				if fixed:
					return "✅ %s reparado!" % part_id
				return "🔧 Reparando %s... %s" % [part_id, car.test_part(part_id)]
			return "La llave no sirve para %s" % part_id
		"aceite":
			if part_id == "aceite":
				var f: bool = car.repair_part(part_id, 60.0)
				queue_free() # se gasta (descartable) - respawnea en estanteria
				return "🛢️ Aceite cambiado!" if f else "🛢️ Echando aceite..."
			return "Eso no lleva aceite"
		"bateria_nueva":
			if part_id == "bateria":
				car.parts[part_id]["hp"] = 100.0
				car.parts[part_id]["broken"] = false
				car.part_changed.emit(part_id, 100.0)
				car.check_fixed()
				queue_free()
				return "🔋 Bateria nueva colocada!"
			return "Ahi no va la bateria"
		"tester":
			return "🔍 " + car.test_part(part_id)
		_:
			return "Nada que hacer"
