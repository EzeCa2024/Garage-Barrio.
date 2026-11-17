# Garage-Barrio 🔧
Simulador de taller mecánico de barrio para **PC y Android**, en **Godot 4**.

## Qué es (v0.2)
Sos el mecánico del barrio. Llegan clientes, aceptás autos en tus elevadores, reparás con minijuego táctil y cobrás. Con la plata comprás mejoras en la tienda.

Loop:
1. 🔔 Llamar cliente → Aceptar / Rechazar
2. 🔧 Reparar fallas (aceite, frenos, batería, neumáticos, motor) con minijuego de timing
3. ✅ Entregar y cobrar (con bonus de mejoras)
4. 🏪 Comprar en tienda: elevadores 2 y 3, herramientas, publicidad, pintura, compresor
5. 📅 Cada 3 autos pasa un día. Todo se guarda en `user://savegame.json`

## Tienda (nuevo v0.2)
- 🏗️ 2do Elevador $400 → 2 autos a la vez (se ve en 3D)
- 🏗️ 3er Elevador $1000 → 3 autos a la vez
- 🧰 Herramientas Pro $250 → minijuego más fácil +5% pago
- ⚙️ Herramientas Elite $700 → aún más fácil +10% pago
- 📢 Cartel $200 → +10% pago +1 rep
- 📣 Publicidad $600 → +20% pago +2 rep
- 🎨 Pintura y luces $300 → +2 rep, cambia la luz del taller
- 💨 Compresor $500 → frenos/neumáticos más fáciles

Efectos reales: dificultad del minijuego baja, pagos suben, elevadores aparecen en 3D, luz cambia.

## 3D simple
Galpón con piso, pared trasera, 3 elevadores + 3 autos de colores, luz cenital + sol. Cámara fija pensada para PC y celular vertical/horizontal.

## Controles
- PC: click
- Android: toque (botones de 56-64px, paneles centrados)

## Probar en Godot (sin APK todavía)
1. Godot 4.3+
2. Abrir `project.godot`
3. F5. Botones abajo: Llamar cliente | Tienda
4. Para resetear partida: borrar `user://savegame.json` o desinstalar datos en Android

## Estructura
```
scenes/Main.tscn
scripts/game_manager.gd (plata, día, upgrades, guardado)
scripts/garage_manager.gd (elevadores 1-3)
scripts/client_manager.gd + car.gd
scripts/repair_system.gd + repair_minigame.gd
scripts/upgrades_system.gd (catálogo)
scripts/shop_panel.gd + hud/client/repair panels
scripts/sound_manager.gd (beeps generados, sin assets)
scripts/main.gd (une todo + visual 3D)
```

## Roadmap
- [x] v0.1 base jugable
- [x] v0.2 tienda + 3 puestos 3D + sonidos + guardado upgrades
- [ ] v0.3 cola visual de clientes, día/noche, eventos (cliente apurado, pieza fallada)
- [ ] v0.4 menú principal + tutorial + pausa
- [ ] v1.0 export APK definitivo + test táctil
