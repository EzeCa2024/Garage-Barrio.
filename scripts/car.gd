extends Node
## Datos de un auto cliente y sus fallas
class_name CarData

var owner_name: String = "Vecino"
var model: String = "Familiar 98"
var color: Color = Color(0.7, 0.2, 0.2)
var faults: Array = [] # Array de String ids, ej ["frenos","aceite"]
var payout: int = 0
var paid_parts_cost: int = 0

const FAULT_NAMES := {
	"aceite": "Cambio de aceite",
	"frenos": "Pastillas de freno",
	"bateria": "Bateria",
	"neumaticos": "Neumaticos",
	"motor": "Afinacion de motor",
}

static func fault_display(id: String) -> String:
	return FAULT_NAMES.get(id, id)

func get_description() -> String:
	var parts: Array = []
	for f in faults:
		parts.append(fault_display(f))
	return "%s (%s)\nFallas: %s" % [model, owner_name, ", ".join(parts)]
