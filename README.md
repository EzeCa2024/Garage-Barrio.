# Garage-Barrio 🔧
Simulador de taller mecánico de barrio para **PC y Android**, hecho en **Godot 4**.

## Idea (v0.1)
Sos el mecánico del barrio. Llegan clientes con autos rotos:
1. Recibís el auto y hacés diagnóstico
2. Elegís la reparación (frenos, aceite, motor, neumáticos, batería)
3. Reparás con un minijuego de timing (funciona con click o toque)
4. Cobrás, ganás reputación y plata
5. Mejorás el taller: más elevadores, herramientas, decoración

## Controles
- **PC:** click mouse
- **Android:** toque (botones grandes, UI expandible)

## Estructura
```
scenes/
  Main.tscn         -> escena principal (Garage 3D + UI)
  Garage.tscn       -> galpon, 2 elevadores, zona clientes
  UI/HUD.tscn       -> plata, dia, reputacion
  UI/ClientPanel.tscn -> ficha del cliente / diagnostico
  UI/RepairPanel.tscn -> elegir reparacion + minijuego
scripts/
  game_manager.gd   -> estado global, plata, dia, guardado
  garage_manager.gd -> elevadores, autos en reparacion
  client_manager.gd -> genera clientes aleatorios
  car.gd            -> datos del auto + fallas
  repair_system.gd  -> recetas de reparacion, tiempos y costos
  repair_minigame.gd-> minijuego de timing
  hud.gd / client_panel.gd / repair_panel.gd -> UI
  save_system.gd    -> guardado JSON (user://savegame.json)
```

## Cómo abrir
1. Godot 4.3+ (recomendado 4.x estable)
2. Abrir `project.godot` en Godot
3. F5 para probar en PC
4. Para Android: Proyecto -> Exportar -> Android (necesitás export templates + SDK)

## Roadmap
- [x] v0.1: base jugable (diagnostico -> reparar -> cobrar)
- [ ] v0.2: 2 elevadores, guardado, sonidos
- [ ] v0.3: tienda de mejoras, reputación por barrio
- [ ] v0.4: export Android APK + test táctil
- [ ] v1.0: día/noche, eventos, personalización del taller
