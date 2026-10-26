extends SceneTree
## Tres procesos ENet: --host y dos --join=127.0.0.1, mismo --puerto, sin --auto.


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaFogata"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var f: Node2D
	var cliente := 0
	var espectador := 0
	var errores := 0
	var casos := 0
	var informes := {}


	func _ready() -> void:
		for accion in InputMap.get_actions():
			InputMap.action_erase_events(accion)
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for i in range(1200):
			await get_tree().process_frame
			if not main.is_node_ready():
				continue
			if multiplayer.is_server() and get_node("/root/Red").jugadores.size() == 3 and not main.juego.visible:
				for datos in get_node("/root/Red").jugadores.values():
					datos.listo = true
				get_node("/root/Red").iniciar_partida()
			if main.jugadores.get_child_count() == 3:
				break
		if main.jugadores.get_child_count() != 3:
			print("FALLO: no llegaron tres jugadores")
			get_tree().quit(1)
			return
		f = main.estacion.fogata
		main.juego.get_node("Partida").rescate.rescatados = 2 # Precondición: misión anterior completada.
		for abeja in get_tree().get_nodes_in_group("golpeables"):
			if abeja.get_script() == load("res://scripts/abejas.gd"):
				abeja.set_physics_process(false)
		if not multiplayer.is_server():
			return
		# Las comprobaciones de ritmo son finas: sin tambaleo al azar.
		f.tambaleo = false
		var peers := multiplayer.get_peers()
		peers.sort()
		cliente = peers[0]
		espectador = peers[1]
		await _esperar(0.4)
		await _probar()
		print("RESULTADO FOGATA: %d comprobaciones, %d fallos" % [casos, errores])
		_finalizar.rpc(errores)


	func _probar() -> void:
		var j := _j(1)
		var estacion: Node2D = main.estacion
		_comprobar(not f.encendida and not estacion.get_node("ArteEstacion").fuego.visible, "El lago empieza sin fuego ni humo")
		_comprobar(not main.juego.get_node("Mundo").has_node("Lena"), "Ya no existe la pieza antigua de leña")
		var arbol: Node2D = main.juego.get_node("Mundo/Arbol10")
		j._reaparecer.rpc(arbol.position + Vector2(-55, 0))
		await _esperar(0.3)
		for n in range(6):
			j.golpear(1)
			await _esperar(0.35)
			if n == 1:
				_comprobar(f.suelo.is_empty(), "Dos golpes aún no desprenden un palo")
			if n == 2:
				_comprobar(f.suelo.size() == 1, "Tercer golpe real desprende y replica un palo")
		_comprobar(f.suelo.size() == 2 and not f.faltan_palos(), "Se consiguen los dos palos sin generar infinitos")
		if f.suelo.size() != 2:
			return
		j._reaparecer.rpc(f.suelo.values()[0])
		await _esperar(0.25)
		await _e(1)
		await _e(1)
		_comprobar(f.cantidad(1) == 2 and f.suelo.is_empty(), "E recoge ambos palos en el inventario personal")
		await _consultar()
		_comprobar(_todos("bolsa", 2), "Los otros peers reciben los dos palos del anfitrión")
		_comprobar(f.cantidad(cliente) == 0, "El inventario pertenece a quien los recogió")
		await _captura("inventario")
		await _e(1)
		_comprobar(f.colocados == 0, "No se colocan lejos de la fogata")
		await _junto_a_fogata()
		await _e(1)
		_comprobar(f.colocados == 2 and f.cantidad(1) == 0 and not f.encendida, "E coloca ambos palos, sin encender por sí solo")
		await _e(1)
		await _esperar(0.3)
		_comprobar(f.participantes == [1] and f.calor == 0, "Un jugador solo espera, sin producir fuego")
		await _e(cliente)
		await _e(espectador)
		await _esperar(2.2)
		_comprobar(f.participantes == [1, cliente] and f.espectadores == [espectador], "Dos roles fijos y el tercero como espectador")
		await _consultar()
		_comprobar(_todos("vista", true) and _todos("actores", f.participantes), "Todos ven el acercamiento con los mismos dos participantes")
		if "--capturas" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://fogata_cooperativa_inicio.png")
		j.golpear(1)
		j.pedir_lanzar(0.5)
		_comprobar(not j.puede_actuar(), "Combate bloqueado dentro del acercamiento")
		# Con los brazos fuera del palo el roce no cuenta.
		for n in range(16):
			f.derivas = [0.9, 0.9]
			var signo := 1 if n % 4 < 2 else -1
			_mouse(1, Vector2(signo * 35, 0), true)
			_mouse(cliente, Vector2(-signo * 35, 0), true)
			await _esperar(0.06)
		_comprobar(f.calor == 0 and f.agarres[0] == 0.0, "Con los brazos fuera del palo frotar no calienta")
		f.derivas = [0.0, 0.0]
		for n in range(24):
			_mouse(1, Vector2(0, 35 * (1 if n % 6 < 3 else -1)), true)
			_mouse(cliente, Vector2(35, 0), true)
			_mouse(espectador, Vector2(35, 35), true)
			await _esperar(0.06)
		_comprobar(f.calor == 0, "Ejes incorrectos y espectador no aumentan el calor")
		for n in range(24):
			_mouse(1, Vector2(35, 0), true)
			_mouse(cliente, Vector2(-35, 0), true)
			await _esperar(0.06)
		_comprobar(f.calor < 0.15, "Mover siempre en la misma dirección no basta")
		for n in range(24):
			var signo := 1 if n % 4 < 2 else -1
			_mouse(1, Vector2(signo * 50, 0), true)
			_mouse(cliente, Vector2(-signo * 50, 0), true)
			await _esperar(0.06)
		_comprobar(f.calor == 0 and "Más despacio" in f.consejos, "Sacudir rápido no produce calor y pide bajar el ritmo")
		for n in range(40):
			var signo := 1 if n % 36 < 18 else -1
			_mouse(1, Vector2(signo * 35, 0), true)
			_mouse(cliente, Vector2(-signo * 35, 0), true)
			await _esperar(0.06)
		_comprobar(f.calor == 0 and "Más rápido" in f.consejos, "Los vaivenes demasiado lentos tampoco calientan")
		for n in range(40):
			var a := 1 if n % 20 < 10 else -1
			var b := 1 if (n + 5) % 20 < 10 else -1
			_mouse(1, Vector2(a * 35, 0), true)
			_mouse(cliente, Vector2(-b * 35, 0), true)
			await _esperar(0.06)
		_comprobar(f.calor < 0.03 and not f.coordinados(), "Dos ritmos válidos desfasados no avanzan juntos")
		await _trazos(2.4)
		_comprobar(f.calor > 0.08, "Mouse sostenido y trazos alternos de ambos producen calor")
		await _captura("frotando")
		var calor: float = f.calor
		main._pedir_pausa(true)
		await get_tree().create_timer(0.4, true).timeout
		_comprobar(is_equal_approx(f.calor, calor), "La pausa congela el puzle")
		main._pedir_pausa(false)
		await _esperar(1)
		_comprobar(f.calor < calor, "Sin volver a arrastrar tras pausa, el fuego se enfría")
		await _e(espectador)
		_comprobar(f.participantes.size() == 2 and f.espectadores.is_empty(), "El espectador sale sin cancelar a los participantes")
		j.proteccion = 0
		j.recibir_dano(1)
		await _esperar(0.2)
		_comprobar(f.participantes.is_empty() and f.colocados == 2 and not j.en_fogata(), "Recibir daño cancela y conserva los palos")
		await _e(1)
		await _e(cliente)
		await _esperar(2.1)
		f.tiempo = 0.1
		await _esperar(0.2)
		_comprobar(f.participantes.is_empty() and f.colocados == 2, "El tiempo agotado permite reintentar sin buscar otros palos")
		await _e(cliente)
		await _e(1)
		await _e(espectador)
		await _esperar(2.1)
		_comprobar(f.participantes == [cliente, 1], "Los papeles se asignan por llegada: los dos frotan en horizontal, cada uno de un lado")
		var antes: float = f.calor
		f.mover(f.encuentro - 1, Vector2(500, 0), true)
		f.mover(f.encuentro, Vector2(NAN, 0), true)
		_comprobar(f.calor == antes, "Rechaza intentos viejos y movimiento inválido")
		await _trazos(22.0)
		_comprobar(f.encendida and f.participantes.is_empty() and f.espectadores.is_empty(), "La cooperación enciende y devuelve a todos al mundo")
		await _consultar()
		_comprobar(_todos("fuego", true) and _todos("vista", false), "Fuego y cierre sincronizados en participantes y espectador")
		_comprobar(estacion.get_node("ArteEstacion").fuego.visible and estacion.get_node("ArteEstacion").humo.visible, "Aparecen el fuego y humo existentes después del éxito")
		await _captura("encendida")
		_comprobar(not estacion.completa(), "El fuego no sustituye la olla ni la miel")
		# Las búsquedas posteriores tienen sus propias pruebas; esta sección valida cocinar.
		main.juego.get_node("Partida").busqueda_olla.conseguida = true
		main.juego.get_node("Partida").oleadas_miel.completada = true
		for pieza in get_tree().get_nodes_in_group("piezas"):
			estacion.intentar_entregar(pieza, estacion.position)
		_comprobar(estacion.completa(), "La olla y la miel conservan su entrega y habilitan cocinar")
		j._reaparecer.rpc(estacion.position + Vector2(-35, 20))
		await _esperar(0.2)
		Input.action_press("agarrar")
		await _esperar(0.5)
		Input.action_release("agarrar")
		_comprobar(estacion.progreso > 0, "Mantener E cocina después de encender y entregar")
		main._pedir_pausa(true)
		main._preparar_sala(true)
		await _esperar(0.5)
		for datos in get_node("/root/Red").jugadores.values():
			datos.listo = true
		get_node("/root/Red").iniciar_partida()
		await _esperar(0.8)
		f = main.estacion.fogata
		main.juego.get_node("Partida").rescate.rescatados = 2 # Precondición: misión anterior completada.
		_comprobar(not f.encendida and f.colocados == 0 and f.inventario.is_empty(), "Nueva ronda limpia fuego, palos y participantes")
		f.crear_palo(_j(espectador).position)
		await _e(espectador)
		_comprobar(f.cantidad(espectador) == 1, "El otro cliente también puede recoger palos")
		_desconectar.rpc_id(espectador)
		await _esperar(0.5)
		_comprobar(f.cantidad(espectador) == 0 and f.suelo.size() == 1, "Desconectarse deja el palo recuperable en el suelo")


	func _j(id: int) -> Node2D:
		return main.jugadores.get_node(str(id))


	func _junto_a_fogata() -> void:
		for i in range(3):
			_j([1, cliente, espectador][i])._reaparecer.rpc(main.estacion.position + Vector2(-50 + i * 50, 18))
		await _esperar(0.3)


	func _e(id: int) -> void:
		if id == 1:
			_pulsar_e()
		else:
			_pulsar_e.rpc_id(id)
		await _esperar(0.2)


	@rpc("authority", "call_local", "reliable")
	func _pulsar_e() -> void:
		Input.action_press("agarrar")
		await get_tree().create_timer(0.04).timeout
		Input.action_release("agarrar")


	func _mouse(id: int, d: Vector2, pulsado: bool) -> void:
		if id == 1:
			_inyectar_mouse(d, pulsado)
		else:
			_inyectar_mouse.rpc_id(id, d, pulsado)


	@rpc("authority", "call_local", "reliable")
	func _inyectar_mouse(d: Vector2, pulsado: bool) -> void:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = pulsado
		Input.parse_input_event(b)
		var m := InputEventMouseMotion.new()
		m.button_mask = MOUSE_BUTTON_MASK_LEFT if pulsado else 0
		m.relative = d
		Input.parse_input_event(m)


	func _trazos(segundos: float) -> void:
		var horizontal: int = f.participantes[0]
		var vertical: int = f.participantes[1]
		for n in range(int(segundos / 0.06)):
			var signo := 1 if int((f.TIEMPO - f.tiempo) / f.COMPAS) % 2 == 0 else -1
			_mouse(horizontal, Vector2(signo * 35, 0), true)
			_mouse(vertical, Vector2(-signo * 35, 0), true)
			await _esperar(0.06)


	func _captura(nombre: String) -> void:
		if "--capturas" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://fogata_cooperativa_%s.png" % nombre)


	func _esperar(segundos: float) -> void:
		await get_tree().create_timer(segundos, true, true).timeout


	func _comprobar(ok: bool, texto: String) -> void:
		casos += 1
		if not ok:
			errores += 1
		print(("OK: " if ok else "FALLO: ") + texto)


	func _consultar() -> void:
		informes.clear()
		_informar.rpc()
		await _esperar(0.2)


	func _todos(clave: String, valor: Variant) -> bool:
		return informes.size() == 2 and informes.values().all(func(datos): return datos[clave] == valor)


	@rpc("authority", "reliable")
	func _informar() -> void:
		f = main.estacion.fogata
		main.juego.get_node("Partida").rescate.rescatados = 2 # Precondición: misión anterior completada.
		_informe.rpc_id(1, {"bolsa": f.cantidad(1), "actores": f.participantes, "fuego": f.encendida, "vista": f.vista.panel.visible})


	@rpc("any_peer", "reliable")
	func _informe(datos: Dictionary) -> void:
		informes[multiplayer.get_remote_sender_id()] = datos


	@rpc("authority", "reliable")
	func _desconectar() -> void:
		get_node("/root/Red").salir()
		get_tree().quit(0)


	@rpc("authority", "call_local", "reliable")
	func _finalizar(fallos: int) -> void:
		get_tree().quit(0 if fallos == 0 else 1)
