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
		comprobar(r.estado == "salto" and r.participantes.size() == 3, "Solo un osezno salta a la torre de tres")
		await esperar(1.5)
		comprobar(r.estado == "equilibrio" and torre._cadena(j(1)).size() == 3, "La torre se conserva al entrar en equilibrio")
		var balance_previo: float = r.equilibrio
		r.equilibrar(r.encuentro - 1, 1)
		r.equilibrar(r.encuentro, NAN)
		comprobar(r.equilibrio == balance_previo, "Descarta entradas caducadas y valores inválidos")
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
		comprobar(r.estado == "regreso" and r.miedo == 1 and r.rescatados == 0, "El miedo se llena y devuelve al osezno a la rama")
		comprobar(j(tercero).vida == 88 and j(1).vida == 100 and j(cliente).vida == 100, "El arañazo daña solo al último de la torre (12)")
		await esperar(2)
		await formar(2)
		j(tercero)._reaparecer.rpc(r.lugar() + Vector2(150, 0))
		await esperar(0.25)
		pulsar_e.rpc_id(cliente)
		await esperar(0.15)
		comprobar(r.participantes == [1, cliente], "Se puede reintentar con una torre de dos")
		forjar.rpc_id(tercero)
		await esperar(0.15)
		comprobar(not r._entradas.has(tercero), "Un espectador no puede equilibrar por otro jugador")
		control.rpc("equilibrar")
		await esperar_rescate(1)
		comprobar(r.rescatados == 1 and not f.habilitada(), "El primer rescate aún no permite hacer fuego")
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
		await formar(2)
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
			if r.rescatados >= cantidad or r.estado == "regreso":
				break
		print("Balance final: ", r.estado, " calma=", r.calma, " miedo=", r.miedo, " tiempo=", r.tiempo)

	func _process(_dt: float) -> void:
		if r == null or modo != "equilibrar" or get_tree().paused:
			return
		Input.action_release("izquierda")
		Input.action_release("derecha")
		if r.contiene(multiplayer.get_unique_id()) and absf(r.equilibrio) > 0.1:
			Input.action_press("izquierda" if r.equilibrio > 0 else "derecha")

	@rpc("authority", "call_local", "reliable")
	func control(valor: String) -> void:
		modo = valor

	@rpc("authority", "reliable")
	func forjar() -> void:
		r.equilibrar.rpc_id(1, r.encuentro, 1.0)

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
			if informes.size() == 2 and informes.values().all(func(d): return d.rescatados == r.rescatados and d.fuego == main.estacion.fogata.habilitada()):
				return

	@rpc("authority", "reliable")
	func informar() -> void:
		informe.rpc_id(1, {"rescatados": r.rescatados, "fuego": main.estacion.fogata.habilitada()})

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
