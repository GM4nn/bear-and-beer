extends SceneTree
## Cuatro instancias: una --host y tres --join=127.0.0.1, mismo --puerto.
## Sin --auto: la prueba inicia al conectar los cuatro jugadores.

const SITIO := Vector2(2300, 520)


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaTorre"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var fallos := 0
	var informes: Dictionary = {}


	func _ready() -> void:
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for intento in range(1200):
			await get_tree().process_frame
			if main.is_node_ready() and get_node("/root/Red").jugadores.size() == 4:
				break
		if get_node("/root/Red").jugadores.size() != 4:
			push_error("La torre necesita cuatro instancias de prueba")
			get_tree().quit(1)
			return
		if not multiplayer.is_server():
			return
		for datos in get_node("/root/Red").jugadores.values():
			datos.listo = true
		get_node("/root/Red").iniciar_partida()
		await _esperar(0.5)
		var ids := multiplayer.get_peers()
		ids.sort()
		var medio: int = ids[0]
		var cima: int = ids[1]
		var cuarto: int = ids[2]
		for id in [1, medio, cima, cuarto]:
			_j(id)._reaparecer.rpc(SITIO + Vector2(0, 100 if id != 1 else 0))
		await _esperar(0.2)

		# E en el suelo no convierte la interacción con objetos en una montura.
		_j(medio)._reaparecer.rpc(SITIO + Vector2(5, 0))
		await _esperar(0.2)
		_accion.rpc_id(medio, "agarrar")
		await _esperar(0.2)
		_comprobar(_j(medio).apoyo_id == 0, "E en el suelo no monta al compañero")
		await _subir(medio, 1)
		_comprobar(_j(medio).apoyo_id == 1, "Saltar y pulsar E monta al cliente sobre el anfitrión")
		await _subir(cima, 1)
		_comprobar(_j(cima).apoyo_id == medio, "El tercer compañero ocupa los hombros superiores")
		_comprobar(is_equal_approx(_j(cima).altura, 80.0), "La torre tiene dos niveles sobre la base")
		await _consultar()
		_comprobar(_todos_apoyos(medio, 1) and _todos_apoyos(cima, medio), "Los cuatro peers ven la misma torre")
		_comprobar(_j(1)._animacion == "cargar_quieto" and _j(medio)._animacion == "hombros_cargar"
			and _j(cima)._animacion == "hombros_quieto", "Cada piso tiene su postura de cargar o ir sentado")
		_comprobar(informes.values().all(func(d): return d[1].animacion == "cargar_quieto" \
			and d[medio].animacion == "hombros_cargar" and d[cima].animacion == "hombros_quieto"),
			"Las posturas de los tres pisos se ven también en los clientes")
		await _probar_critico([1, medio, cima])
		if "--captura" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://torre_revision.png")
			print("CAPTURA: ", ProjectSettings.globalize_path("user://torre_revision.png"))

		var x_antes: float = _j(1).position.x
		Input.action_press("derecha")
		await _esperar(0.35)
		_comprobar(_j(1)._animacion == "cargar_caminar" and _j(medio)._animacion == "hombros_cargar",
			"La base camina sujetando y el pasajero permanece sentado")
		Input.action_release("derecha")
		await _esperar(0.2)
		await _consultar()
		var juntos := _j(1).position.x > x_antes + 40
		for datos: Dictionary in informes.values():
			juntos = juntos and Vector2(datos[medio].posicion).distance_to(datos[1].posicion) < 2 \
				and Vector2(datos[cima].posicion).distance_to(datos[1].posicion) < 2
		_comprobar(juntos, "La torre acompaña el movimiento de la base en todas las pantallas")
		_accion.rpc_id(1, "saltar")
		await _esperar(0.2)
		_comprobar(_j(1).altura > 30 and is_equal_approx(_j(cima).altura - _j(1).altura, 80.0),
			"La base puede saltar manteniendo los niveles de la torre")
		await _esperar(0.6)

		await _subir(cuarto, 1)
		_comprobar(_j(cuarto).apoyo_id == 0 and _j(cima).apoyo_id == medio,
			"Un cuarto jugador no cabe ni desplaza a los que ya están")
		_accion.rpc_id(cima, "agarrar")
		await _esperar(0.2)
		_comprobar(_j(cima).apoyo_id == 0 and _j(medio).apoyo_id == 1,
			"E baja al de arriba sin desarmar la base y el medio")
		await _subir(cima, 1)
		_accion.rpc_id(medio, "saltar")
		await _esperar(0.2)
		_comprobar(_j(medio).apoyo_id == 0 and _j(cima).apoyo_id == 0 and _j(medio).altura > 80,
			"Saltar desde el medio libera a los de arriba y permite saltar desde los hombros")
		await _esperar(0.8)

		await _subir(medio, 1)
		await _subir(cima, 1)
		_j(1).recibir_golpe(-1, 10, 1.0)
		await _esperar(0.15)
		_comprobar(_j(medio).apoyo_id == 0 and _j(cima).apoyo_id == 0,
			"Un golpe a la base hace caer a los dos pasajeros")
		await _esperar(0.8)
		_j(1)._reaparecer.rpc(SITIO)
		await _subir(medio, 1)
		_j(1).pedir_rodar(Vector2.LEFT)
		await _esperar(0.15)
		_comprobar(_j(medio).apoyo_id == 0, "Rodar con un pasajero lo suelta")
		await _esperar(0.5)

		_j(1)._reaparecer.rpc(SITIO)
		await _subir(medio, 1)
		_j(medio).dormido = 0.8
		await _esperar(0.45)
		_comprobar(_j(medio).apoyo_id == 0 and _j(medio).altura <= 0.0,
			"Dormirse en los hombros suelta al pasajero y cae hasta el suelo")
		await _esperar(1.5)
		await _subir(medio, 1)
		_accion.rpc_id(1, "agarrar")
		await _esperar(0.2)
		_comprobar(_j(medio).apoyo_id == 0, "La base puede pulsar E para soltar al pasajero")
		await _esperar(0.5)

		# Comprobar autoridad: otro peer no puede decidir el E del anfitrión.
		_j(1)._reaparecer.rpc(SITIO)
		await _subir(medio, 1)
		_orden_ajena.rpc_id(cuarto)
		await _esperar(0.2)
		_comprobar(_j(medio).apoyo_id == 1, "Un cliente no puede soltar la torre en nombre del anfitrión")
		_j(1)._perder_vida(1000)
		await _esperar(0.15)
		_comprobar(_j(1).caido and _j(medio).apoyo_id == 0, "Quedar caído no deja a nadie suspendido")
		_j(1).levantar()
		await _esperar(1.7)

		# Base remota: el anfitrión también puede ser pasajero.
		_j(medio)._reaparecer.rpc(SITIO)
		await _esperar(0.2)
		await _subir(cima, medio)
		await _subir(1, medio)
		_comprobar(_j(1).apoyo_id == cima and _j(cima).apoyo_id == medio,
			"El anfitrión puede subir a una torre sostenida por un cliente")
		_j(1).botellas = 1
		_j(1).pedir_lanzar()
		var botella = main.juego.get_node("Mundo").get_node_or_null("Botella1")
		_comprobar(botella != null and botella.altura >= 80,
			"La botella sale de la altura del pasajero, no desde el suelo")
		_desconectar.rpc_id(medio)
		await _esperar(0.5)
		_comprobar(not main.jugadores.has_node(str(medio)) and _j(cima).apoyo_id == 0 and _j(1).apoyo_id == 0,
			"Desconectar al apoyo libera a todos los que estaban encima")
		await _consultar()
		_comprobar(_todos_apoyos(cima, 0) and _todos_apoyos(1, 0), "La caída por desconexión se replica a los demás")
		print("RESULTADO TORRE: %d fallos" % fallos)
		_finalizar.rpc(fallos)


	func _j(id: int) -> Node2D:
		return main.jugadores.get_node(str(id))


	func _probar_critico(ids: Array) -> void:
		var jefe = main.jefe
		jefe.set_physics_process(false)
		jefe.activa = true
		jefe.estado = "persiguiendo"
		jefe.vida = 1000
		jefe.position = _j(1).position + Vector2(40, 0)
		var torre = _j(1)._torre()
		for id: int in ids:
			_accion.rpc_id(id, "golpear")
		await _esperar(0.16)
		_comprobar(jefe.vida == 940 and torre.criticos == 1,
			"Tres puñetazos coordinados hacen 60 de daño y un solo crítico")
		_comprobar(_j(ids[0])._animacion == "cargar_golpear" and _j(ids[1])._animacion == "hombros_cargar_golpear"
			and _j(ids[2])._animacion == "hombros_golpear", "Al golpear conservan el asiento y un brazo de apoyo")
		if "--captura" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://torre_critico.png")
		await _esperar(0.4)
		await _consultar()
		_comprobar(informes.values().all(func(d): return d[1].criticos == 1 and d[1].vida_jefe == 940),
			"Daño y aviso de crítico llegan a los tres clientes")
		for id: int in [ids[0], ids[1]]:
			_accion.rpc_id(id, "golpear")
		await _esperar(0.5)
		_comprobar(jefe.vida == 920 and torre.criticos == 1,
			"Si falta el tercer integrante los dos golpes son normales")
		_accion.rpc_id(ids[0], "golpear")
		await _esperar(0.25)
		for id: int in [ids[1], ids[2]]:
			_accion.rpc_id(id, "golpear")
		await _esperar(0.5)
		_comprobar(jefe.vida == 890 and torre.criticos == 1,
			"Golpes separados más de 0,18 s no generan crítico")
		# Dos rivales distintos tampoco completan la coordinación.
		_accion.rpc_id(ids[0], "golpear")
		_accion.rpc_id(ids[1], "golpear")
		await _esperar(0.11)
		jefe.position.x += 400
		_accion.rpc_id(ids[2], "golpear")
		await _esperar(0.5)
		_comprobar(jefe.vida == 870 and torre.criticos == 1,
			"Golpear al aire no completa el crítico de la torre")
		# Cambiar integrantes entre contactos invalida el intento, aunque acierten.
		jefe.position = _j(1).position + Vector2(40, 0)
		_accion.rpc_id(ids[0], "golpear")
		_accion.rpc_id(ids[1], "golpear")
		await _esperar(0.11)
		torre.bajar(_j(ids[2]), false)
		_accion.rpc_id(ids[2], "golpear")
		await _esperar(0.6)
		_comprobar(jefe.vida == 840 and torre.criticos == 1,
			"Bajarse entre los contactos cancela el intento de crítico")
		# Retirar a la cima deja una torre válida de dos personas.
		_j(ids[2])._reaparecer.rpc(SITIO + Vector2(200, 80))
		jefe.position = _j(1).position + Vector2(40, 0)
		for id: int in [ids[0], ids[1]]:
			_accion.rpc_id(id, "golpear")
		await _esperar(0.5)
		_comprobar(jefe.vida == 800 and torre.criticos == 2,
			"Una torre de dos compas coordinados hace 40 de daño")
		jefe.activa = false
		jefe.position = Vector2(6800, 500)
		jefe.set_physics_process(true)
		await _subir(ids[2], 1)


	func _esperar(segundos: float) -> void:
		await get_tree().create_timer(segundos).timeout


	func _subir(id: int, base: int) -> void:
		# Apartar espectadores: E elige al apoyo cercano, no un ID fijado por la prueba.
		var sitio := 0
		for otro in main.jugadores.get_children():
			if otro.name.to_int() in [id, base] or otro.apoyo_id != 0:
				continue
			if otro._torre().encima(otro) != null:
				continue
			otro._reaparecer.rpc(Vector2(2000 + sitio * 100, 650))
			sitio += 1
		_j(id)._reaparecer.rpc(_j(base).position + Vector2(5, 0))
		_j(id).aturdimiento = 0
		await _esperar(0.2)
		_accion.rpc_id(id, "saltar")
		await _esperar(0.22)
		_accion.rpc_id(id, "agarrar")
		await _esperar(0.2)


	func _comprobar(condicion: bool, descripcion: String) -> void:
		print("%s: %s" % ["OK" if condicion else "FALLO", descripcion])
		if not condicion:
			fallos += 1


	@rpc("authority", "call_local", "reliable")
	func _accion(accion: String) -> void:
		Input.action_press(accion)
		await get_tree().physics_frame
		await get_tree().physics_frame
		Input.action_release(accion)


	@rpc("authority", "reliable")
	func _orden_ajena() -> void:
		_j(1).pedir_agarrar.rpc_id(1)


	func _consultar() -> void:
		informes = {}
		_pedir_informe.rpc()
		for intento in range(300):
			await get_tree().process_frame
			if informes.size() == multiplayer.get_peers().size():
				return
		_comprobar(false, "Los clientes responden al informe")


	func _todos_apoyos(id: int, apoyo: int) -> bool:
		return not informes.is_empty() and informes.values().all(func(datos): return datos[id].apoyo == apoyo)


	@rpc("authority", "reliable")
	func _pedir_informe() -> void:
		var datos := {}
		for compa in main.jugadores.get_children():
			datos[compa.name.to_int()] = {"apoyo": compa.apoyo_id, "posicion": compa.position, "altura": compa.altura,
				"criticos": compa._torre().criticos, "vida_jefe": main.jefe.vida, "animacion": compa._animacion}
		_informar.rpc_id(1, datos)


	@rpc("any_peer", "reliable")
	func _informar(datos: Dictionary) -> void:
		if multiplayer.is_server():
			informes[multiplayer.get_remote_sender_id()] = datos


	@rpc("authority", "reliable")
	func _desconectar() -> void:
		multiplayer.multiplayer_peer.close()
		get_tree().quit()


	@rpc("authority", "call_local", "reliable")
	func _finalizar(codigo: int) -> void:
		get_tree().quit(0 if codigo == 0 else 1)
