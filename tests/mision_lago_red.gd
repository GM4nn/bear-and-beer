extends SceneTree
## Dos procesos: --host / --join=127.0.0.1, ambos --auto y mismo --puerto.
## Acciones reales. Se acortan los traslados; enemigos quietos en casos aislados.


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaMisionLago"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var informe: Dictionary = {}


	func _ready() -> void:
		for accion in InputMap.get_actions():
			InputMap.action_erase_events(accion)
			Input.action_release(accion)
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for i in range(600):
			await get_tree().process_frame
			if main.is_node_ready() and main.jugadores.get_child_count() == 2:
				break
		if main.jugadores.get_child_count() != 2:
			get_tree().quit(1)
			return
		for abeja in get_tree().get_nodes_in_group("golpeables"):
			if abeja.get_script() == load("res://scripts/abejas.gd"):
				abeja.set_physics_process(false)
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		await _esperar(0.3)
		await _probar()
		print("RESULTADO MISION LAGO: %d fallos" % fallos)
		_finalizar.rpc(fallos)


	func _probar() -> void:
		var host = _j(1)
		var compa = _j(cliente)
		var osa = main.jefe
		var estacion = main.estacion
		osa.set_physics_process(false)
		osa.activa = true
		osa.vida = 700
		osa.vida_max = 700
		osa.position = Vector2(5300, 350)
		osa._cambiar("pausa", 60)
		for id in [1, cliente]:
			_j(id)._reaparecer.rpc(Vector2(5240, 350))
			_j(cliente if id == 1 else 1)._reaparecer.rpc(Vector2(5100, 650))
			await _esperar(0.2)
			await _pulsar(id, "derecha", 0.03)
			await _pulsar(id, "saltar", 0.05)
			await _esperar(0.12)
			_comprobar(_j(id).altura > 12, "Salto real del jugador %d" % id)
			var antes: int = osa.vida
			await _pulsar(id, "golpear", 0.05)
			await _esperar(0.1)
			_comprobar(osa.vida == antes - 10, "El puño en el aire alcanza a la osa (%d)" % id)
			osa._golpeados.clear()
			osa._cambiar("aviso_piso", 0)
			osa._siguiente()
			_comprobar(_j(id).vida == 100, "Saltar evita el golpe al piso (%d)" % id)
			await _esperar(0.6)
			osa._golpeados.clear()
			osa._cambiar("aviso_piso", 0)
			osa._siguiente()
			_comprobar(_j(id).altura <= 0 and _j(id).vida == 85, "Aterrizar vuelve a exponer al golpe al piso (%d)" % id)
			_j(id)._reaparecer.rpc(Vector2(5900, 525))
			_j(id).vida = 100
			_j(id).aturdimiento = 0
			await _esperar(0.2)
			await _pulsar(id, "saltar", 0.05)
			await _pulsar(id, "golpear", 0.05)
			_comprobar(_j(id).nadando() and _j(id).altura == 0 and not _j(id).puede_actuar(),
				"En el agua se nada y no se salta ni combate (%d)" % id)
		# Recoger con E, caminar cargando y entregar con E: sin asignar progreso.
		osa.activa = false
		osa._cambiar("dormida", 0)
		host._reaparecer.rpc(Vector2(1000, 650))
		compa._reaparecer.rpc(Vector2(1200, 650))
		var piezas := get_tree().get_nodes_in_group("piezas")
		for i in range(piezas.size()):
			var pieza = piezas[i]
			var id: int = cliente if i == 1 else 1
			var j = _j(id)
			j._reaparecer.rpc(pieza.position + Vector2(0, 25))
			await _esperar(0.2)
			await _pulsar(id, "agarrar", 0.05)
			await _esperar(0.15)
			_comprobar(pieza.portador == id, "E recoge %s (%d)" % [pieza.tipo, id])
			j._reaparecer.rpc(estacion.position + Vector2(-130, 0))
			await _esperar(0.15)
			await _pulsar(id, "derecha", 0.5)
			await _pulsar(id, "agarrar", 0.05)
			await _esperar(0.15)
			_comprobar(pieza.entregada and pieza.portador == 0, "Caminar y entregar %s con E" % pieza.tipo)
			j._reaparecer.rpc(Vector2(1200 + i * 100, 650))
		_comprobar(estacion.completa(), "Se reunieron las tres piezas distintas")
		host._reaparecer.rpc(estacion.position + Vector2(-30, 0))
		compa._reaparecer.rpc(estacion.position + Vector2(30, 0))
		await _esperar(0.2)
		Input.action_press("agarrar")
		await _esperar(0.9)
		Input.action_release("agarrar")
		var avance: float = estacion.progreso
		await _esperar(0.3)
		_comprobar(avance > 0.08 and estacion.progreso < avance, "Cocinar avanza; soltar E pierde avance")
		Input.action_press("agarrar")
		_entrada.rpc_id(cliente, "agarrar", true)
		await _esperar(4.3)
		Input.action_release("agarrar")
		_entrada.rpc_id(cliente, "agarrar", false)
		_comprobar(estacion.terminada, "Dos jugadores cocinan juntos en unos cuatro segundos")
		if "--fallar-mision" in OS.get_cmdline_user_args():
			await _esperar(32.0)
			await _consultar()
			_comprobar(host.caido and compa.caido and informe.get("finalizada", false) and not informe.get("victoria", true),
				"Agotar los 30 segundos sin alimentar derriba al equipo y finaliza la ronda en ambos peers")
			return
		host._reaparecer.rpc(estacion.lugar_oseznos() + Vector2(-20, 20))
		compa._reaparecer.rpc(estacion.lugar_oseznos() + Vector2(20, 20))
		await _esperar(0.2)
		Input.action_press("agarrar")
		_entrada.rpc_id(cliente, "agarrar", true)
		await _esperar(5.4)
		Input.action_release("agarrar")
		_entrada.rpc_id(cliente, "agarrar", false)
		_comprobar(estacion.alimentados and estacion.tiempo > 0, "Alimentación cooperativa completada dentro del límite")
		osa.set_physics_process(true)
		await _esperar(1.5)
		_comprobar(osa.activa and osa.vida == osa.VIDA_BASE + osa.VIDA_POR_JUGADOR,
			"La misión invoca a la osa con vida para dos jugadores")
		osa.set_physics_process(false)
		host._reaparecer.rpc(Vector2(5100, 650))
		compa._reaparecer.rpc(Vector2(5200, 650))
		osa.position = Vector2(5900, 410)
		osa._dir = Vector2.DOWN
		osa._cambiar("embestida", 1.1)
		osa.set_physics_process(true)
		await _esperar(1.15)
		osa.set_physics_process(false)
		await _consultar()
		_comprobar(informe.get("alimentados", false) and informe.get("osa_pos", Vector2.ZERO).distance_to(osa.position) < 2,
			"El cliente recibe misión completada y posición del desvío junto al lago")
		# Blanco quieto para comprobar la victoria con daño real de combos completos.
		osa.position = Vector2(5300, 350)
		osa._cambiar("pausa", 60)
		host._reaparecer.rpc(Vector2(5240, 350))
		await _esperar(0.3)
		await _pulsar(1, "derecha", 0.03)
		for intento in range(10):
			for accion in ["golpear", "puno_izquierdo", "cabezazo", "patada"]:
				await _pulsar(1, accion, 0.05)
				await _esperar(0.16)
			if main.juego.get_node("Partida").finalizada:
				break
		await _esperar(0.2)
		await _consultar()
		_comprobar(osa.estado == "derrotada" and informe.get("victoria", false), "Los golpes reales vencen al jefe y ambos reciben la victoria")


	func _j(id: int) -> Node2D:
		return main.jugadores.get_node(str(id))

	func _esperar(t: float) -> void:
		await get_tree().create_timer(t, true, true).timeout

	func _pulsar(id: int, accion: String, tiempo: float) -> void:
		if id == 1:
			_entrada(accion, true)
		else:
			_entrada.rpc_id(id, accion, true)
		await _esperar(tiempo)
		if id == 1:
			_entrada(accion, false)
		else:
			_entrada.rpc_id(id, accion, false)

	@rpc("authority", "reliable")
	func _entrada(accion: String, pulsada: bool) -> void:
		if pulsada:
			Input.action_press(accion)
		else:
			Input.action_release(accion)

	func _comprobar(ok: bool, mensaje: String) -> void:
		print(("OK: " if ok else "FALLO: ") + mensaje)
		if not ok:
			fallos += 1

	func _consultar() -> void:
		await _esperar(0.2)
		informe = {}
		_informar.rpc_id(cliente)
		for i in range(120):
			await get_tree().process_frame
			if not informe.is_empty():
				return

	@rpc("authority", "reliable")
	func _informar() -> void:
		_datos.rpc_id(1, {"alimentados": main.estacion.alimentados, "osa_pos": main.jefe.position,
			"victoria": main.juego.get_node("Partida").victoria,
			"finalizada": main.juego.get_node("Partida").finalizada})

	@rpc("any_peer", "reliable")
	func _datos(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos

	@rpc("authority", "call_local", "reliable")
	func _finalizar(errores: int) -> void:
		get_tree().quit(0 if errores == 0 else 1)
