extends SceneTree

func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaMejoras"
	root.add_child.call_deferred(prueba)

class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var cuenta := 0
	var informe := {}

	func esperar(t: float) -> void:
		await get_tree().create_timer(t, true).timeout

	func comprobar(ok: bool, texto: String) -> void:
		cuenta += 1
		if not ok:
			fallos += 1
		print(("OK: " if ok else "FALLO: ") + texto)

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for i in 900:
			await get_tree().process_frame
			if main.is_node_ready() and main.jugadores.get_child_count() == 2:
				break
		if main.jugadores.get_child_count() != 2:
			get_tree().quit(1)
			return
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		var red := get_node("/root/Red")
		var audio := get_node("/root/Audio")
		var controles := get_node("/root/Controles")
		var guardado := get_node("/root/Guardado")
		var j: Node2D = main.jugadores.get_node("1")
		var otro: Node2D = main.jugadores.get_node(str(cliente))
		main.jefe.set_physics_process(false)
		for e in get_tree().get_nodes_in_group("enjambres"):
			e.set_physics_process(false)
		j._reaparecer.rpc(Vector2(2000, 600))
		otro._reaparecer.rpc(Vector2(2100, 600))
		await esperar(0.2)
		main._pedir_pausa(true)
		main.pausa.abrir_opciones()
		main.pausa.opciones.get_node("Volumen_musica").value = 0.25
		main.pausa.opciones.get_node("Volumen_efectos").value = 0.45
		comprobar(is_equal_approx(audio.volumen("musica"), 0.25) and is_equal_approx(audio.volumen("efectos"), 0.45), "Ambos sliders aplican el valor al bus correcto")
		audio._cargar_volumenes()
		comprobar(is_equal_approx(audio.volumen("musica"), 0.25) and is_equal_approx(audio.volumen("efectos"), 0.45), "Los valores se conservan al cargar desde disco")
		main.pausa.opciones.get_node("Volumen_efectos").value = 0
		comprobar(AudioServer.is_bus_mute(AudioServer.get_bus_index("Efectos")), "Cero silencia los efectos")
		main.pausa.opciones.get_node("Volumen_efectos").value = 0.45
		main.pausa.volver()
		main.pausa.abrir_opciones()
		comprobar(main.pausa.opciones.get_node("Volumen_musica").value == 0.25, "Reabrir opciones no reinicia el volumen")
		controles.restaurar()
		main.abrir_controles()
		main.editor_controles.botones.golpear.pressed.emit()
		var tecla := InputEventKey.new()
		tecla.physical_keycode = KEY_U
		tecla.keycode = KEY_U
		tecla.pressed = true
		Input.parse_input_event(tecla)
		Input.flush_buffered_events()
		await esperar(0.05)
		comprobar(controles.tecla("golpear") == "U", "El editor reasigna una tecla mediante entrada real")
		controles.cargar()
		comprobar(controles.tecla("golpear") == "U", "La tecla modificada persiste")
		comprobar(controles.indicaciones("Pulsa H · HOLA") == "Pulsa U · HOLA", "Las indicaciones usan la nueva tecla sin alterar palabras")
		comprobar(not controles.asignar("patada", KEY_U).is_empty(), "Rechaza teclas duplicadas")
		comprobar(not controles.asignar("golpear", KEY_ESCAPE).is_empty(), "Escape queda reservado para los menús")
		await captura("mejoras_controles")
		controles.restaurar()
		main.editor_controles.queue_free()
		await esperar(0.1)
		main._pedir_pausa(false)
		for accion in InputMap.get_actions():
			Input.action_release(accion)
		var numero: int = j._numero_golpe
		for i in 90:
			j.golpear(1, 0)
			await get_tree().physics_frame
		comprobar(j._numero_golpe - numero <= 6 and j._cola_golpes.is_empty(), "Machacar H no apila golpes ni supera su ritmo de retorno")
		await esperar(0.35)
		numero = j._numero_golpe
		for tipo in 4:
			j.golpear(1, tipo)
		await esperar(0.8)
		comprobar(j._numero_golpe - numero == 4, "H J K L rápido conserva los cuatro ataques en orden")
		var abeja: Node2D = main.juego.get_node("Partida").abeja_musculosa
		abeja.set_physics_process(false)
		abeja._fusionar.rpc(PackedVector2Array([j.position, j.position, j.position + Vector2(40, 0)]), 1)
		comprobar(abeja.vida == 180, "La musculosa tiene 180 de vida")
		abeja.estado = "buscando"
		j._dano_ataque = 10
		abeja.golpeada(1, j)
		comprobar(abeja.vida == 170, "Un puño normal ya no acaba con la musculosa en pocos golpes")
		abeja.vida = 10
		abeja.golpeada(1, j)
		abeja.golpeada(1, j)
		await esperar(0.2)
		comprobar(get_tree().get_nodes_in_group("armas_temporales").size() == 1, "Morir deja un solo botín, incluso recibiendo otro contacto")
		await consultar()
		comprobar(informe.armas == 1, "El botín también aparece en el cliente")
		var arma: Node2D = get_tree().get_first_node_in_group("armas_temporales")
		j.position = arma.position - Vector2(20, 0)
		j.pedir_agarrar()
		await esperar(0.15)
		comprobar(j.arma_tiempo > 19 and get_tree().get_nodes_in_group("armas_temporales").is_empty(), "E recoge el aguijón por 20 segundos")
		await consultar()
		comprobar(informe.arma_host > 19 and informe.armas == 0, "Equipar y retirar el botín se replica")
		j._recuperacion = 0
		j._repeticion = 0
		j.golpear(1)
		await esperar(0.12)
		comprobar(j.dano_actual() == 15, "El aguijón aumenta 50 por ciento el golpe")
		j.arma_tiempo = 0.1
		await esperar(0.25)
		comprobar(j.arma_tiempo == 0, "El arma temporal caduca")
		abeja.estado = "inactiva"
		abeja._reposo = 0
		abeja._grupos_sin_fusion = 1
		for i in 3:
			abeja.registrar_baja(j.position)
		comprobar(abeja.encuentro == 2 and abeja.estado == "fusion", "La misma ronda permite una segunda musculosa")
		abeja.cancelar()
		j._reaparecer.rpc(Vector2(2000, 600))
		otro._reaparecer.rpc(Vector2(2060, 600))
		otro.vida = 0
		otro.caido = true
		Input.action_press("agarrar")
		await esperar(1.0)
		comprobar(otro.reanimacion > 0.2 and otro._barra_revivir.visible and otro._barra_revivir.value > 0.2, "La barra muestra progreso real mientras se reanima")
		await consultar()
		comprobar(informe.reanimacion > 0.2 and informe.barra, "El compañero caído ve su progreso por red")
		await captura("mejoras_revivir")
		Input.action_release("agarrar")
		await esperar(0.12)
		comprobar(otro.reanimacion == 0, "Soltar la tecla cancela el progreso de reanimación")
		Input.action_press("agarrar")
		await esperar(3.2)
		Input.action_release("agarrar")
		comprobar(not otro.caido and not otro._barra_revivir.visible and otro.vida == 40, "Completar la barra revive y oculta el indicador")
		comprobar(red.latencias.has(cliente) and red.latencias[cliente] >= 0, "Latencia medida con ida y vuelta real")
		await consultar()
		comprobar(informe.latencia >= 0, "El cliente recibe su calidad de conexión")
		main._pedir_pausa(true)
		j.vida = 73
		j.cervezas = 3
		main.estacion.fogata.colocados = 2
		main.juego.get_node("Partida").rescate.rescatados = 2
		main.estacion.fogata.encendida = true
		main.estacion.fogata._publicar()
		main.estacion.progreso = 0.4
		main.jefe.activa = true
		main.jefe.vida = 417
		main.jefe.vida_max = 500
		main.jefe.fase = 2
		main.juego.get_node("Partida").soltar_arma(Vector2(2200, 600))
		var respuesta: String = guardado.guardar(main, "user://prueba_guardado.cfg")
		comprobar(respuesta.begins_with("Partida guardada"), "Guardar en pausa escribe la ranura")
		comprobar(guardado.guardar(main, "user://prueba_guardado.cfg").begins_with("Partida guardada"), "Sobrescribir la ranura es válido")
		var datos: Dictionary = guardado.cargar("user://prueba_guardado.cfg")
		comprobar(datos.jugadores[0].vida == 73 and datos.fogata.encendida and datos.jefe.vida == 417, "La lectura recupera misión, vida e inventario")
		var corrupto := ConfigFile.new()
		var roto := datos.duplicate(true)
		roto.jefe.vida_max = 0
		corrupto.set_value("partida", "datos", roto)
		corrupto.save("user://prueba_roto.cfg")
		comprobar(guardado.cargar("user://prueba_roto.cfg").is_empty(), "Un guardado inválido se rechaza sin cargar a medias")
		DirAccess.remove_absolute("user://prueba_roto.cfg")
		main._preparar_sala(true)
		await esperar(0.7)
		guardado.pendiente = datos
		for jugador in red.jugadores.values():
			jugador.listo = true
		red.iniciar_partida()
		await esperar(0.4)
		main._pedir_pausa(true)
		j = main.jugadores.get_node("1")
		comprobar(j.vida == 73 and j.cervezas == 3, "Continuar restaura al jugador después de reconstruir el bosque")
		comprobar(main.estacion.fogata.encendida and main.jefe.vida == 417 and main.jefe.fase == 2, "Continuar conserva fogata y fase del jefe")
		await consultar()
		comprobar(informe.vida_host == 73 and informe.fuego and informe.vida_jefe == 417, "El cliente recibe la partida restaurada")
		comprobar(get_tree().get_nodes_in_group("armas_temporales").size() == 1 and informe.armas == 1, "Continuar conserva el botín que quedó en el suelo")
		main.pausa.abrir_opciones()
		await captura("mejoras_opciones")
		await captura_menu()
		comprobar(guardado.guardar(main).begins_with("Partida guardada"), "El guardado real del menú se escribe")
		orden.rpc_id(cliente, "esperar_reconexion")
		await esperar(0.2)
		main._volver_al_menu("")
		await esperar(0.15)
		comprobar(main._continuar.visible and main._version.visible, "El menú muestra Continuar y la versión pequeña")
		await captura("mejoras_menu_guardado")
		main._continuar.pressed.emit()
		for i in 80:
			await esperar(0.1)
			if red.jugadores.size() == 2:
				break
		comprobar(red.jugadores.size() == 2, "Continuar permite reunir al grupo en un nuevo lobby")
		if red.jugadores.size() != 2:
			get_tree().quit(1)
			return
		for datos_jugador in red.jugadores.values():
			datos_jugador.listo = true
		red.iniciar_partida()
		await esperar(0.5)
		main._pedir_pausa(true)
		cliente = multiplayer.get_peers()[0]
		await consultar()
		comprobar(main.jugadores.get_node("1").vida == 73 and informe.fuego, "Continuar desde el botón restaura con nuevos identificadores de red")
		DirAccess.remove_absolute("user://prueba_guardado.cfg")
		print("RESULTADO MEJORAS: %d comprobaciones, %d fallos" % [cuenta, fallos])
		terminar.rpc(fallos)

	func captura_menu() -> void:
		main.pausa.cerrar()
		main._mostrar("menu")
		await esperar(0.1)
		await captura("mejoras_menu")
		main._mostrar("juego")

	func captura(nombre: String) -> void:
		if "--captura" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://" + nombre + ".png")

	func consultar() -> void:
		informe = {}
		pedir.rpc_id(cliente)
		for i in 120:
			await get_tree().process_frame
			if not informe.is_empty():
				return

	@rpc("authority", "reliable")
	func pedir() -> void:
		var yo: Node = main.jugadores.get_node(str(multiplayer.get_unique_id()))
		var host: Node = main.jugadores.get_node("1")
		responder.rpc_id(1, {"armas": get_tree().get_nodes_in_group("armas_temporales").size(),
			"arma_host": host.arma_tiempo, "vida_host": host.vida, "reanimacion": yo.reanimacion,
			"barra": yo._barra_revivir.visible, "fuego": main.estacion.fogata.encendida,
			"vida_jefe": main.jefe.vida, "latencia": get_node("/root/Red").latencias.get(multiplayer.get_unique_id(), -1)})

	@rpc("any_peer", "reliable")
	func responder(datos: Dictionary) -> void:
		informe = datos

	@rpc("authority", "reliable")
	func orden(accion: String) -> void:
		if accion == "esperar_reconexion":
			await esperar(1.0)
			main._unirse()

	@rpc("authority", "call_local", "reliable")
	func terminar(errores: int) -> void:
		await esperar(0.1)
		get_tree().quit(0 if errores == 0 else 1)
