extends Node
## Recetas de reparacion: costo repuestos, tiempo, pago
class_name RepairSystem

# id -> {label, parts_cost, work_time (seg), payout, difficulty 0-1}
const RECIPES := {
	"aceite": {"label": "Cambio de aceite", "parts_cost": 30, "work_time": 5.0, "payout": 80, "difficulty": 0.2},
	"frenos": {"label": "Pastillas de freno", "parts_cost": 60, "work_time": 8.0, "payout": 150, "difficulty": 0.4},
	"bateria": {"label": "Bateria", "parts_cost": 70, "work_time": 6.0, "payout": 140, "difficulty": 0.3},
	"neumaticos": {"label": "Neumaticos", "parts_cost": 100, "work_time": 10.0, "payout": 220, "difficulty": 0.5},
	"motor": {"label": "Afinacion de motor", "parts_cost": 120, "work_time": 14.0, "payout": 300, "difficulty": 0.7},
}

static func get_recipe(fault_id: String) -> Dictionary:
	return RECIPES.get(fault_id, {})

static func all_ids() -> Array:
	return RECIPES.keys()
