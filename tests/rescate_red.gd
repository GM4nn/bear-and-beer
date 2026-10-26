extends SceneTree
## Tres procesos: --host y dos --join=127.0.0.1, mismo puerto, sin --auto.
func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaRescate"
	root.add_child.call_deferred(prueba)

class Prueba extends Node:
	var main: Node
	var r: Node
	var fallos := 0
	var casos := 0
	var informes := {}
	var modo := "quieto"
	var cliente := 0
	var tercero := 0
	var foto_curva := false

	func esperar(t: float) -> void:
		await get_tree().create_timer(t, true, true).timeout

	func comprobar(ok: bool, texto: String) -> void:
		casos += 1
		if not ok:
			fallos += 1
		print(("OK: " if ok else "FALLO: ") + texto)

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for i in 1200:
			await get_tree().process_frame
			if not main.is_node_ready():
				continue
			if multiplayer.is_server() and get_node("/root/Red").jugadores.size() == 3 and not main.juego.visible:
				for d in get_node("/root/Red").jugadores.values():
					d.listo = true
				get_node("/root/Red").iniciar_partida()
			if main.jugadores.get_child_count() == 3:
				break
		if main.jugadores.get_child_count() != 3:
			get_tree().quit(1)
			return
		r = main.juego.get_node("Partida").rescate
		main.jefe.set_physics_process(false)
		for e in get_tree().get_nodes_in_group("enjambres"):
			e.set_physics_process(false)
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		tercero = multiplayer.get_peers()[1]
		await esperar(0.5)
		await probar()
		print("RESULTADO RESCATE: %d comprobaciones, %d fallos" % [casos, fallos])
		terminar.rpc(fallos)

	func j(id: int) -> Node2D:
		return main.jugadores.get_node(str(id))

	func probar() -> void:
		var torre: Node = main.juego.get_node("Partida").torre
		var f: Node = main.estacion.fogata
		var primeros := PackedVector2Array()
		for paso in r.reto.PASOS:
			primeros.append(r.reto.objetivo(paso, 0, 0.25))
		var duracion_inicial: float = r.reto.duracion()
		var radio_inicial: float = r.reto.radio()
		comprobar(r.rescatados == 0 and not f.habilitada() and not f.faltan_palos(), "El rescate bloquea fuego y palos")
		comprobar(r.rama(0).y < r.lugar().y - torre.ALTURA_HOMBROS * 2 - 130, "La rama supera la torre máxima de tres")
		comprobar(not main.estacion.get_node("ArteEstacion").crias[0].visible, "Los oseznos aún no están en el campamento")
		j(1)._reaparecer.rpc(f.global_position)
		await esperar(0.25)
		f.colocados = 2
		j(1).pedir_agarrar()
		comprobar(f.participantes.is_empty() and not f.encendida, "Ni con palos preparados se puede saltar el rescate")
		f.colocados = 0
		await formar(3)
		j(1).pedir_agarrar()
		comprobar(not r.activo(), "La torre no atrae al osezno sin miel")
		torre.romper_desde(j(1))
		await esperar(1)
		var miel: Node2D = main.juego.get_node("Mundo/Miel")
		miel.agarrar(1)
		j(1)._reaparecer.rpc(r.lugar())
		await esperar(0.2)
		j(1).pedir_agarrar()
		comprobar(r.cebo and miel.portador == 0 and not miel.entregada, "E ofrece miel sin perder el frasco para cocinar")
		await formar(3)
		j(1).pedir_agarrar()
		comprobar(r.estado == "preparando" and r.participantes.size() == 3, "El reto prepara a los tres participantes")
		await esperar(1.5)
		comprobar(r.estado == "preparando" and torre._cadena(j(1)).size() == 3, "La torre se conserva durante la cuenta atrás")
		var entrada_previa: Dictionary = r.reto.entradas[1].duplicate()
		r.reto.mover(r.encuentro - 1, r.paso, 100, Vector2.ONE, true)
		r.reto.mover(r.encuentro, r.paso, 100, Vector2(NAN, 0), true)
		r.reto.mover(r.encuentro, r.paso, 100, Vector2(2, 0), true)
		comprobar(r.reto.entradas[1] == entrada_previa, "Descarta intentos viejos, NaN y posiciones fuera del lienzo")
		main._pedir_pausa(true)
		var tiempo_previo: float = r.tiempo
		await esperar(0.35)
		comprobar(r.tiempo == tiempo_previo, "Pausar congela el rescate en todos sus tiempos")
		main._pedir_pausa(false)
		var golpes: int = j(1)._numero_golpe
		j(1).golpear(1)
		comprobar(j(1)._numero_golpe == golpes and not j(1).puede_actuar(), "No se puede atacar mientras se sostiene al osezno")
		await captura("torre")
		# Sin correcciones el desequilibrio llena el miedo por sí solo.
		for i in 200:
			await esperar(0.1)
			if r.estado == "regreso":
				break
		comprobar(r.estado == "regreso" and r.miedo == 1 and r.rescatados == 0, "No seguir el primer círculo devuelve al osezno a la rama")
		comprobar(j(tercero).vida == 88 and j(1).vida == 100 and j(cliente).vida == 100, "El arañazo daña solo al último de la torre (12)")
		comprobar([1, cliente, tercero].all(func(id): return j(id).apoyo_id == 0) and j(1).aturdimiento > 0, "El fallo derriba todos los pisos y también la base")
		await esperar(2)
		await formar(3)
		control.rpc("equilibrar")
		j(1).pedir_agarrar()
		await esperar(4.6)
		comprobar(r.estado == "ritmo", "Los tres mantienen el primer objetivo con el mouse")
		control.rpc_id(cliente, "soltar")
		await esperar(0.7)
		comprobar(r.estado == "regreso" and [1, cliente, tercero].all(func(id): return j(id).apoyo_id == 0), "Un solo cliente suelta el clic y caen TODOS, aunque los otros acierten")
		comprobar(r.mensaje.begins_with("¡Falló %s!" % j(cliente).nombre), "El aviso identifica al compa que soltó el clic")
		await consultar()
		comprobar(informes.size() == 2 and informes.values().all(func(d): return d.mensaje == r.mensaje), "Todos reciben el mismo nombre en el aviso de fallo")
		control.rpc("equilibrar")
		await esperar(2)
		await formar(3)
		j(1).pedir_agarrar()
		await esperar(4.5)
		control.rpc_id(tercero, "fuera")
		await esperar(0.7)
		comprobar(r.estado == "regreso" and r.rescatados == 0, "Mantener clic fuera del recorrido también hace fallar al equipo")
		comprobar(r.mensaje.begins_with("¡Falló %s!" % j(tercero).nombre), "El aviso identifica a quien se salió del recorrido")
		control.rpc("equilibrar")
		await esperar(2)
		await formar(3)
		j(1).pedir_agarrar()
		# Cubrir menos del 80% también identifica a todos los que no completaron.
		r.estado = "ritmo"
		r.tiempo = r.reto.aviso() + r.reto.duracion()
		for piso in r.participantes.size():
			var id: int = r.participantes[piso]
			r.reto.cubierto[id] = r.reto.duracion() if id == 1 else 0.5
			r.reto.entradas[id] = {"pos": r.reto.objetivo(r.paso, piso, 1.0), "pulsa": true, "cuando": r.reto.reloj, "paso": r.paso, "secuencia": 0, "visto": r.tiempo, "dentro": true}
		r.reto._physics_process(0.0)
		comprobar(r.estado == "regreso" and r.mensaje.begins_with("¡Fallaron %s, %s!" % [j(cliente).nombre, j(tercero).nombre]), "El seguimiento insuficiente muestra los nombres correctos, sin culpar a quien acertó")
		await esperar(2)
		await formar(2)
		j(tercero)._reaparecer.rpc(r.lugar() + Vector2(150, 0))
		await esperar(0.25)
		pulsar_e.rpc_id(cliente)
		await esperar(0.15)
		comprobar(not r.activo() and r.participantes.is_empty(), "No inicia con dos si falta el tercer jugador de la partida")
		forjar.rpc_id(tercero)
		await esperar(0.15)
		comprobar(not r.reto.entradas.has(tercero), "Un espectador no puede equilibrar por otro jugador")
		j(tercero)._perder_vida(100)
		j(1).pedir_agarrar()
		comprobar(j(tercero).caido and not r.activo() and r.mensaje.contains("revivan"), "Un compañero muerto sigue siendo obligatorio y bloquea el inicio")
		j(tercero).levantar()
		j(tercero)._reaparecer.rpc(r.lugar() + Vector2(75, 0))
		await esperar(0.25)
		j(1).pedir_agarrar()
		comprobar(not r.activo(), "Con tres jugadores no basta revivir: los tres deben formar la torre")
		await formar(3)
		pulsar_e.rpc_id(cliente)
		await esperar(0.15)
		comprobar(r.participantes.size() == 3 and r.torre_ids == r.participantes, "Al reunirse los tres puede iniciar también un cliente")
		control.rpc("equilibrar")
		await esperar_rescate(1)
		comprobar(r.rescatados == 1 and not f.habilitada(), "El primer rescate aún no permite hacer fuego")
		var distintos := true
		for paso in r.reto.PASOS:
			distintos = distintos and primeros[paso].distance_to(r.reto.objetivo(paso, 0, 0.25)) > 0.01
		comprobar(distintos and r.reto.tipo(2) == 3, "El segundo osezno cambia todos los recorridos y añade curvas en S")
		comprobar(r.reto.duracion() < duracion_inicial and r.reto.radio() < radio_inicial, "El segundo osezno exige más velocidad y precisión")
		await consultar()
		comprobar(informes.size() == 2 and informes.values().all(func(d): return d.rescatados == 1), "Ambos clientes reciben el primer osezno rescatado")
		comprobar(main.estacion.get_node("ArteEstacion").crias[0].visible and not main.estacion.get_node("ArteEstacion").crias[1].visible, "Solo el rescatado aparece abajo")
		# El guardado conserva éxitos, nunca deja a un jugador encerrado a mitad de salto.
		j(1).pedir_agarrar()
		await esperar(0.3)
		main._pedir_pausa(true)
		var guardado := get_node("/root/Guardado")
		var ruta := "user://rescate_prueba.cfg"
		var texto: String = guardado.guardar(main, ruta)
		var datos: Dictionary = guardado.cargar(ruta)
		comprobar(texto.begins_with("Partida guardada") and datos.get("rescate", {}).get("rescatados") == 1, "Guardar conserva miel y oseznos ya rescatados")
		guardado.restaurar_mundo(main, datos)
		comprobar(r.rescatados == 1 and r.cebo and not r.activo() and r.participantes.is_empty(), "Cargar cancela el salto pendiente sin perder el rescate anterior")
		DirAccess.remove_absolute(ruta)
		main._pedir_pausa(false)
		await esperar(0.4)
		await formar(3)
		j(1).pedir_agarrar()
		await esperar_rescate(2)
		comprobar(r.listo() and f.habilitada() and f.faltan_palos(), "Rescatar los dos habilita la misión de fuego")
		await consultar()
		comprobar(informes.size() == 2 and informes.values().all(func(d): return d.rescatados == 2 and d.fuego), "Los dos clientes también habilitan los palos")
		await captura("completo")
		# Interrumpir por daño no duplica un éxito ni deja controles bloqueados.
		r.rescatados = 1
		j(1).pedir_agarrar()
		await esperar(0.15)
		j(1)._perder_vida(1)
		comprobar(r.estado == "regreso" and r.participantes.is_empty() and not j(1).en_rescate(), "El daño externo devuelve al osezno y libera los controles")
		await esperar(1.5)
		await formar(3)
		j(1).pedir_agarrar()
		await esperar(0.2)
		desconectar.rpc_id(cliente)
		await esperar(0.5)
		comprobar(not r.activo() and r.participantes.is_empty() and not j(1).en_rescate(), "Desconectar un participante cancela el rescate sin bloquear al compañero")

	func formar(cuantos: int) -> void:
		var torre: Node = main.juego.get_node("Partida").torre
		torre.romper_desde(j(1))
		await esperar(0.1)
		for id in [1, cliente, tercero]:
			j(id)._reaparecer.rpc(r.lugar())
			j(id).aturdimiento = 0
			j(id).proteccion = 0
		await esperar(0.3)
		torre._montar.rpc(cliente, 1)
		if cuantos == 3:
			torre._montar.rpc(tercero, cliente)
		await esperar(0.3)

	func esperar_rescate(cantidad: int) -> void:
		for i in 300:
			await esperar(0.1)
			if not foto_curva and r.estado == "ritmo" and r.paso == 1 and r.tiempo > 1.5:
				foto_curva = true
				await captura("curva")
			if r.rescatados >= cantidad or r.estado == "regreso":
				break
		print("Balance final: ", r.estado, " calma=", r.calma, " miedo=", r.miedo, " tiempo=", r.tiempo)

	func _process(_dt: float) -> void:
		if r == null or modo == "quieto" or get_tree().paused:
			return
		var yo := multiplayer.get_unique_id()
		if r.contiene(yo) and r.estado in ["preparando", "ritmo"]:
			var reto: Node = r.reto
			if reto._paso_mostrado < 0:
				return
			var punto_logico: Vector2 = reto.objetivo(reto._paso_mostrado, r.participantes.find(yo), reto.progreso_mostrado()) * reto.LIENZO
			# Pasar ambos oseznos por el interior cercano al borde, lejos del punto blanco.
			if "--borde" in OS.get_cmdline_user_args():
				punto_logico += Vector2.from_angle(Time.get_ticks_msec() * 0.004) * (reto.radio() - 2)
			var punto: Vector2 = punto_logico * reto._vista.scale + reto._vista.position
			if modo == "fuera":
				punto = Vector2(1200, 680) * reto._vista.scale + reto._vista.position
			var b := InputEventMouseButton.new()
			b.button_index = MOUSE_BUTTON_LEFT
			b.pressed = modo != "soltar"
			b.position = punto
			get_viewport().push_input(b, true)
			var m := InputEventMouseMotion.new()
			m.position = punto
			m.button_mask = MOUSE_BUTTON_MASK_LEFT if modo != "soltar" else 0
			get_viewport().push_input(m, true)

	@rpc("authority", "call_local", "reliable")
	func control(valor: String) -> void:
		modo = valor

	@rpc("authority", "reliable")
	func forjar() -> void:
		r.reto.mover.rpc_id(1, r.encuentro, r.paso, 1000, Vector2(0.5, 0.5), true)

	@rpc("authority", "reliable")
	func pulsar_e() -> void:
		Input.action_press("agarrar")
		await esperar(0.05)
		Input.action_release("agarrar")

	@rpc("authority", "reliable")
	func desconectar() -> void:
		get_node("/root/Red").salir()
		get_tree().quit(0)

	func consultar() -> void:
		informes.clear()
		# El RPC de consulta puede adelantarse al siguiente paquete de estado.
		# Esperar convergencia acotada, no exigir que ambos canales lleguen juntos.
		for intento in 10:
			informar.rpc()
			await esperar(0.2)
			if informes.size() == 2 and informes.values().all(func(d): return d.rescatados == r.rescatados and d.fuego == main.estacion.fogata.habilitada() and d.mensaje == r.mensaje):
				return

	@rpc("authority", "reliable")
	func informar() -> void:
		informe.rpc_id(1, {"rescatados": r.rescatados, "fuego": main.estacion.fogata.habilitada(), "mensaje": r.mensaje})

	@rpc("any_peer", "reliable")
	func informe(datos: Dictionary) -> void:
		informes[multiplayer.get_remote_sender_id()] = datos

	func captura(nombre: String) -> void:
		if "--capturas" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://rescate_%s.png" % nombre)

	@rpc("authority", "call_local", "reliable")
	func terminar(errores: int) -> void:
		get_tree().quit(0 if errores == 0 else 1)
