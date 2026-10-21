extends SceneTree
## Dos instancias --auto. --captura guarda cada contacto con ventana.
const SITIO := Vector2(2300, 520)


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaCombo"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var informe := {}
	var controles_ok := false


	func _ready() -> void:
		var teclas := {"golpear": KEY_H, "puno_izquierdo": KEY_J, "cabezazo": KEY_K,
			"patada": KEY_L, "saltar": KEY_SPACE, "esquivar": KEY_SHIFT, "parada": KEY_F, "lanzar": KEY_R}
		controles_ok = true
		for accion in teclas:
			controles_ok = controles_ok and InputMap.action_get_events(accion).any(
				func(e): return e is InputEventKey and e.physical_keycode == teclas[accion])
			for otra in InputMap.get_actions():
				if otra == accion or otra.begins_with("ui_"):
					continue
				controles_ok = controles_ok and not InputMap.action_get_events(otra).any(
					func(e): return e is InputEventKey and e.physical_keycode == teclas[accion])
		for accion in InputMap.get_actions():
			if not accion.begins_with("ui_"):
				controles_ok = controles_ok and not InputMap.action_get_events(accion).any(func(e): return e is InputEventMouseButton)
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
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		main.jefe.set_physics_process(false)
		_comprobar(controles_ok, "Combo H/J/K/L, parada F y lanzamiento R sin teclas duplicadas ni combate con ratón")
		await _preparar()
		var host = _j(1)
		_comprobar(["puno_izquierdo", "cabezazo", "patada"].all(func(a): return host.sprite.sprite_frames.get_frame_count(a) == 8),
			"Los tres ataques tienen ocho cuadros propios cargados")
		for tipo in range(4):
			await _golpe(1, tipo, true)
			_comprobar(main.jefe.vida == [990, 980, 966, 926][tipo], "Daño correcto en contacto %d" % (tipo + 1))
			await _consultar()
			_comprobar(informe.get("paso") == (tipo + 1) % 4 and informe.get("vida") == main.jefe.vida,
				"El cliente ve el progreso y daño del contacto %d" % (tipo + 1))
		_comprobar(host.combo.criticos == 1 and informe.get("criticos") == 1 and main.jefe.estado == "tambaleando",
			"La patada final es crítica una sola vez, con aviso en ambos peers y tambaleo")
		await _esperar(0.7)
		_comprobar(main.jefe.vida == 926 and host.combo.paso == 0, "El crítico no se repite al terminar la animación")
		_comprobar(get_tree().get_nodes_in_group("impactos_comic").is_empty(), "Los estallidos se retiran al terminar")

		await _preparar()
		for tipo in [0, 2, 1, 3]:
			await _golpe(1, tipo)
		_comprobar(main.jefe.vida == 950 and host.combo.criticos == 1, "Orden incorrecto conserva daños normales sin crítico")
		await _preparar()
		await _golpe(1, 0)
		await _esperar(1.0)
		_comprobar(host.combo.paso == 0, "Esperar demasiado rompe el combo")
		await _golpe(1, 1)
		_comprobar(host.combo.paso == 0, "El puño izquierdo no puede iniciar el combo")
		await _preparar()
		await _golpe(1, 0)
		main.jefe.position.x += 500
		var efectos: int = host.combo.impactos
		await _golpe(1, 1)
		_comprobar(host.combo.paso == 0 and host.combo.impactos == efectos, "Fallar al aire rompe el combo y no dibuja un impacto")
		await _preparar()
		await _golpe(1, 0)
		host.recibir_dano(3)
		_comprobar(host.combo.paso == 0, "Recibir daño rompe la secuencia inmediatamente")
		await _preparar()
		host.golpear(1, 99)
		_comprobar(host._golpe_pendiente < 0, "El servidor rechaza tipos de ataque inválidos")
		host.golpear(1, 2)
		host.recibir_golpe(-1, 10, 1)
		await _esperar(0.25)
		_comprobar(main.jefe.vida == 1000, "Recibir un golpe durante el cabezazo cancela el daño pendiente")
		await _preparar()
		main.jefe.estado = "lago"
		await _golpe(1, 0)
		_comprobar(host.combo.paso == 0 and main.jefe.vida == 1000, "Un jefe fuera del alcance de ataques no alimenta el combo")

		# El cliente controla una secuencia completa usando sus propias acciones.
		await _preparar(cliente)
		for tipo in range(4):
			await _golpe(cliente, tipo)
		_comprobar(main.jefe.vida == 926 and _j(cliente).combo.criticos == 1,
			"El cliente puede ejecutar los cuatro ataques y conseguir el mismo crítico")
		await _consultar()
		_comprobar(informe.get("criticos_cliente") == 1 and informe.get("vida") == 926,
			"El crítico del cliente y su daño quedan sincronizados")
		await _preparar()
		host.mirando = -1
		main.jefe.position = SITIO - Vector2(60, 0)
		for tipo in range(4):
			await _golpe(1, tipo)
		_comprobar(main.jefe.vida == 926 and host.combo.criticos == 2, "La secuencia completa también funciona hacia la izquierda")
		await _preparar()
		for tipo in [0, 1, 2]:
			await _golpe(1, tipo)
		_j(cliente)._reaparecer.rpc(SITIO + Vector2(30, 0))
		await _esperar(0.1)
		await _golpe(1, 3)
		_comprobar(main.jefe.vida == 926 and _j(cliente).vida == 84,
			"La patada crítica contra la osa conserva daño normal de fuego amigo")
		await _preparar()
		Input.action_press("cabezazo")
		await _esperar(1.2)
		Input.action_release("cabezazo")
		_comprobar(main.jefe.vida == 986, "Mantener cabezazo no repite ataques automáticamente")
		for id in [1, cliente]:
			await _preparar(id)
			var criticos_antes: int = _j(id).combo.criticos
			if id == 1:
				_rafaga([0, 1, 2, 3])
			else:
				_rafaga.rpc_id(id, [0, 1, 2, 3])
			await _esperar(0.8)
			_comprobar(main.jefe.vida == 926 and _j(id).combo.criticos == criticos_antes + 1,
				"La ráfaga rápida completa el combo en menos de 0,8 s desde %s" % ("host" if id == 1 else "cliente"))
		await _preparar()
		_rafaga([0, 0, 0])
		await _esperar(0.2)
		_comprobar(main.jefe.vida == 990, "Machacar no adelanta golpes: entre uno y otro pasan al menos 0,15 s")
		await _esperar(0.35)
		_comprobar(main.jefe.vida == 970, "Las tres pulsaciones rápidas se guardan y dan tres contactos")
		await _preparar()
		host.golpear(1, 0)
		host.golpear(1, 1)
		# Simular el intervalo del mismo tick entre resolver un contacto y leer entrada nueva.
		host._actualizar_golpe(0.1)
		host.golpear(1, 2)
		host.golpear(1, 3)
		await _esperar(0.8)
		_comprobar(main.jefe.vida == 926, "Una pulsación al terminar el contacto no se adelanta a las ya guardadas")
		await _preparar()
		for tipo in range(4):
			host.golpear(1, tipo)
		host.recibir_dano(3)
		await _esperar(0.7)
		_comprobar(main.jefe.vida == 1000 and host._cola_golpes.is_empty(), "Recibir daño cancela también todos los ataques guardados")
		await _preparar()
		await _golpe(1, 0)
		host._torre()._montar.rpc(cliente, 1)
		await _esperar(0.1)
		host.golpear(1, 1)
		await _esperar(0.15)
		_comprobar(main.jefe.vida == 990, "La torre conserva sus puños coordinados sin animaciones de pie superpuestas")
		await _preparar()
		await _golpe(1, 0)
		host.golpear(1, 1)
		main.juego.get_node("Partida").terminar(false)
		await _esperar(0.25)
		_comprobar(main.jefe.vida == 990 and host.combo.paso == 0, "Terminar la ronda cancela el combo y el daño pendiente")
		print("RESULTADO COMBO: %d fallos" % fallos)
		_finalizar.rpc(fallos)


	func _j(id: int) -> Node2D:
		return main.jugadores.get_node(str(id))


	func _esperar(t: float) -> void:
		await get_tree().create_timer(t, true, true).timeout


	func _preparar(atacante := 1) -> void:
		for id in [1, cliente]:
			var j = _j(id)
			j._reaparecer.rpc(SITIO + Vector2(0, 0 if id == atacante else 150))
			j.vida = 100
			j.borrachera = 0
			j.aturdimiento = 0
			j.proteccion = 0
			j._espera_servidor = 0
			j._espera = 0
			j._recuperacion = 0
			j.mirando = 1
		main.jefe._sin_tambaleo = 0
		main.jefe.activa = true
		main.jefe.vida = 1000
		main.jefe.vida_max = 1000
		main.jefe.position = SITIO + Vector2(60, 0)
		main.jefe._cambiar("pausa", 60)
		await _esperar(0.5)


	func _golpe(id: int, tipo: int, foto := false) -> void:
		if id == 1:
			_accion(tipo)
		else:
			_accion.rpc_id(id, tipo)
		await _esperar(_j(id).combo.IMPACTOS[tipo] + 0.05)
		if foto and "--captura" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://combo_%d.png" % tipo)
		await _esperar(_j(id).combo.ESPERAS[tipo] - _j(id).combo.IMPACTOS[tipo] + 0.06)


	@rpc("authority", "call_remote", "reliable")
	func _rafaga(tipos: Array) -> void:
		for tipo in tipos:
			await _accion(tipo)


	@rpc("authority", "call_remote", "reliable")
	func _accion(tipo: int) -> void:
		var accion: String = ["golpear", "puno_izquierdo", "cabezazo", "patada"][tipo]
		Input.action_press(accion)
		await _esperar(0.04)
		Input.action_release(accion)


	func _comprobar(ok: bool, texto: String) -> void:
		print(("OK: " if ok else "FALLO: ") + texto)
		if not ok:
			fallos += 1
			print("VIDA ", main.jefe.vida, " PASO ", _j(1).combo.paso, " INFORME ", informe)


	func _consultar() -> void:
		await _esperar(0.1)
		informe = {}
		_pedir_informe.rpc_id(cliente)
		for i in range(120):
			await get_tree().process_frame
			if not informe.is_empty():
				return


	@rpc("authority", "reliable")
	func _pedir_informe() -> void:
		_datos.rpc_id(1, {"vida": main.jefe.vida, "paso": _j(1).combo.paso,
			"criticos": _j(1).combo.criticos, "criticos_cliente": _j(multiplayer.get_unique_id()).combo.criticos})


	@rpc("any_peer", "reliable")
	func _datos(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos


	@rpc("authority", "call_local", "reliable")
	func _finalizar(errores: int) -> void:
		get_tree().quit(0 if errores == 0 else 1)
