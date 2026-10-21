extends SceneTree
## Dos peers ENet reales. --captura guarda el menú y sus opciones.


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaPausa"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var informe := {}
	var salida_correcta := false


	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for accion in InputMap.get_actions():
			for evento in InputMap.action_get_events(accion):
				if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
					InputMap.action_erase_event(accion, evento)
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
		await _esperar(0.3)
		var jugador: Node2D = main.jugadores.get_node("1")
		jugador.botellas = 2
		Input.action_press("lanzar")
		await _esperar(0.12)
		_comprobar(jugador._apuntando_botella, "El jugador está apuntando antes de pausar")
		_escape()
		await _consultar()
		_comprobar(get_tree().paused and informe.get("pausada", false), "Esc pausa ambos mundos sin desconectar")
		_comprobar(main.pausa.visible and informe.get("menu", false), "Ambos ven el menú")
		_comprobar(main.pausa.boton_resumir.has_focus(), "Resumir recibe el foco de teclado")
		_comprobar(informe.get("lobby_bloqueado", false), "Solo el anfitrión puede devolver el grupo al lobby")
		var reloj: float = main.juego.get_node("Partida").torre._tiempo_juego
		var reloj_cliente: float = informe.reloj
		var sitio: Vector2 = main.jugadores.get_node("1").position
		Input.action_press("derecha")
		Input.action_press("golpear")
		await _esperar(0.45)
		await _consultar()
		_comprobar(reloj == main.juego.get_node("Partida").torre._tiempo_juego and reloj_cliente == informe.reloj,
			"Los temporizadores de juego se congelan en los dos peers")
		_comprobar(sitio == main.jugadores.get_node("1").position, "Las entradas no mueven al jugador en pausa")
		await _captura("pausa_menu")
		main.pausa.abrir_opciones()
		main.pausa.volumen.value = 0.4
		_comprobar(get_tree().paused and is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.4),
			"Opciones ajusta el volumen sin reanudar")
		await _captura("pausa_opciones")
		_escape()
		_comprobar(get_tree().paused and main.pausa.menu.visible, "Esc desde opciones vuelve a pausa")
		_tecla(KEY_ENTER)
		await _consultar()
		_comprobar(not get_tree().paused and not informe.pausada and not main.pausa.visible,
			"Enter sobre Resumir reanuda ambas pantallas")
		_comprobar(not Input.is_action_pressed("golpear") and not Input.is_action_pressed("derecha"),
			"No se guardan pulsaciones realizadas en el menú")
		_comprobar(not jugador._apuntando_botella and jugador.botellas == 2,
			"Pausar apuntando cancela la carga sin gastar ni lanzar una botella")
		await _esperar(0.15)
		_comprobar(main.juego.get_node("Partida").torre._tiempo_juego > reloj, "La física continúa al resumir")
		_orden.rpc_id(cliente, "escape")
		await _consultar()
		_comprobar(get_tree().paused and main._pausado_por == cliente and informe.pausada, "Un cliente también puede pausar")
		_orden.rpc_id(cliente, "escape")
		await _consultar()
		_comprobar(not get_tree().paused and not informe.pausada, "Esc del cliente permite reanudar")
		_escape()
		await _esperar(0.15)
		main.pausa.volver_lobby.emit()
		await _esperar(0.4)
		await _consultar()
		_comprobar(main.get_node("UI/Sala").visible and informe.sala and not get_tree().paused and not informe.pausada,
			"Volver al lobby devuelve a ambos y quita la pausa")
		_comprobar(main.jugadores.get_child_count() == 0 and informe.jugadores == 0 and multiplayer.get_peers().size() == 1,
			"Lobby limpia la ronda y conserva la conexión")
		var red := get_node("/root/Red")
		for datos in red.jugadores.values():
			datos.listo = true
		red.iniciar_partida()
		await _esperar(0.35)
		await _consultar()
		_comprobar(main.jugadores.get_child_count() == 2 and informe.jugadores == 2 and main.juego.visible,
			"Se puede iniciar una segunda ronda sobre la misma conexión")
		_orden.rpc_id(cliente, "escape")
		await _esperar(0.15)
		_orden.rpc_id(cliente, "salir_y_reconectar")
		await _esperar(0.3)
		_comprobar(not get_tree().paused and main.juego.visible and multiplayer.get_peers().is_empty(),
			"Salir el cliente que pausó libera al anfitrión y conserva su partida")
		# Reabrir el lobby para verificar también la desconexión del anfitrión.
		_escape()
		main.pausa.volver_lobby.emit()
		await _esperar(1.5)
		if multiplayer.get_peers().is_empty():
			_comprobar(false, "El cliente vuelve a conectar")
			get_tree().quit(1)
			return
		cliente = multiplayer.get_peers()[0]
		await _consultar()
		_comprobar(informe.get("salida_correcta", false), "Terminar en cliente vuelve a su menú sin pausa")
		for datos in red.jugadores.values():
			datos.listo = true
		red.iniciar_partida()
		await _esperar(0.3)
		_escape()
		await _consultar()
		_orden.rpc_id(cliente, "esperar_cierre")
		await _esperar(0.15)
		main.pausa.terminar.emit()
		await _esperar(0.3)
		_comprobar(main.get_node("UI/Menu").visible and not get_tree().paused and not main.pausa.visible,
			"Terminar en anfitrión vuelve al menú y limpia la pausa")
		print("RESULTADO PAUSA: %d fallos" % fallos)
		get_tree().quit(0 if fallos == 0 else 1)


	func _tecla(codigo: Key) -> void:
		var evento := InputEventKey.new()
		evento.keycode = codigo
		evento.pressed = true
		Input.parse_input_event(evento)
		evento = evento.duplicate()
		evento.pressed = false
		Input.parse_input_event(evento)
		Input.flush_buffered_events()


	func _escape() -> void:
		_tecla(KEY_ESCAPE)


	func _esperar(t: float) -> void:
		await get_tree().create_timer(t, true).timeout


	func _comprobar(ok: bool, texto: String) -> void:
		print("OK " if ok else "FALLO ", texto)
		if not ok:
			fallos += 1


	func _captura(nombre: String) -> void:
		if "--captura" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://%s.png" % nombre)


	func _consultar() -> void:
		await _esperar(0.12)
		informe = {}
		_pedir_informe.rpc_id(cliente)
		for i in range(120):
			await get_tree().process_frame
			if not informe.is_empty():
				return


	@rpc("authority", "reliable")
	func _pedir_informe() -> void:
		_datos.rpc_id(1, {"pausada": get_tree().paused, "menu": main.pausa.visible,
			"reloj": main.juego.get_node("Partida").torre._tiempo_juego,
			"lobby_bloqueado": main.pausa.boton_lobby.disabled,
			"sala": main.get_node("UI/Sala").visible, "jugadores": main.jugadores.get_child_count(),
			"salida_correcta": salida_correcta})


	@rpc("any_peer", "reliable")
	func _datos(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos


	@rpc("authority", "reliable")
	func _orden(accion: String) -> void:
		match accion:
			"escape":
				_escape()
			"salir_y_reconectar":
				main.pausa.terminar.emit()
				salida_correcta = main.get_node("UI/Menu").visible and not get_tree().paused and not main.pausa.visible
				await _esperar(1.0)
				main._unirse()
			"esperar_cierre":
				await _esperar(0.8)
				_comprobar(main.get_node("UI/Menu").visible and not get_tree().paused and not main.pausa.visible,
					"El cierre del anfitrión devuelve al cliente al menú sin dejarlo pausado")
				print("RESULTADO PAUSA CLIENTE: %d fallos" % fallos)
				get_tree().quit(0 if fallos == 0 else 1)
