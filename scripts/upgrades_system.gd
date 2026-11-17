extends Node
## Catalogo de mejoras del taller
class_name UpgradesSystem

# id -> {label, desc, cost, requires (id o ""), icon}
const CATALOG := {
	"lift2": {"label": "2do Elevador", "desc": "Acepta 2 autos a la vez. Se ve en 3D.", "cost": 400, "requires": "", "icon": "🏗️"},
	"lift3": {"label": "3er Elevador", "desc": "Acepta 3 autos a la vez.", "cost": 1000, "requires": "lift2", "icon": "🏗️"},
	"tools1": {"label": "Herramientas Pro", "desc": "-15% dificultad +5% pago.", "cost": 250, "requires": "", "icon": "🧰"},
	"tools2": {"label": "Herramientas Elite", "desc": "-25% dificultad +10% pago.", "cost": 700, "requires": "tools1", "icon": "⚙️"},
	"publi1": {"label": "Cartel en la esquina", "desc": "+10% pago, +1 reputacion.", "cost": 200, "requires": "", "icon": "📢"},
	"publi2": {"label": "Publicidad barrial", "desc": "+20% pago, +2 reputacion.", "cost": 600, "requires": "publi1", "icon": "📣"},
	"deco1": {"label": "Pintura y luces", "desc": "+2 reputacion por auto. Taller se ve mejor.", "cost": 300, "requires": "", "icon": "🎨"},
	"compresor": {"label": "Compresor neumatico", "desc": "Minijuego mas facil en neumaticos y frenos.", "cost": 500, "requires": "tools1", "icon": "💨"},
}

static func all_ids() -> Array:
	return CATALOG.keys()

static func get_item(id: String) -> Dictionary:
	return CATALOG.get(id, {})

static func is_unlocked(id: String, owned: Dictionary) -> bool:
	if owned.get(id, false):
		return true
	return false

static func can_buy(id: String, owned: Dictionary, money: int) -> Dictionary:
	# retorna {ok, reason}
	var item: Dictionary = get_item(id)
	if item.is_empty():
		return {"ok": false, "reason": "No existe"}
	if owned.get(id, false):
		return {"ok": false, "reason": "Ya comprado"}
	var req: String = str(item.get("requires", ""))
	if req != "" and not owned.get(req, false):
		return {"ok": false, "reason": "Requiere: %s" % get_item(req).get("label", req)}
	if money < int(item.get("cost", 999999)):
		return {"ok": false, "reason": "Plata insuficiente"}
	return {"ok": true, "reason": ""}
