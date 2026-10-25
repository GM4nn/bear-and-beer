extends SceneTree
## Host + cliente --auto, mismo puerto. --captura en un host con ventana.
const SITIO := Vector2(2300, 520)

func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaCompas"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var informe: Dictionary = {}


	func _ready() -> void:
		# El mando conectado sigue enviando ejes incluso a una ventana oculta.
		# Esta prueba usa acciones sintéticas; ignorar entradas físicas externas.
		for accion in InputMap.get_actions():
			InputMap.action_erase_events(accion)
			Input.action_release(accion)
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for intento in range(600):
			await get_tree().process_frame
			if main.is_node_ready() and main.jugadores.get_child_count() == 2:
				break
		if main.jugadores.get_child_count() != 2:
			get_tree().quit(1)
			return
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		var host = _j(1)
		var compa = _j(cliente)
		var oso = main.jefe
		oso.set_physics_process(false)
		oso.activa = true
		oso.vida_max = 500
		oso.vida = 500
		await _preparar()
		oso.position = SITIO + Vector2(80, 0)
		oso.mirando = -1
		Input.action_press("parada")
		await _esperar(0.05)
		Input.action_release("parada")
		await _foto("guardia")
		oso._cambiar("aviso_zarpazo", 0)
		oso._siguiente()
		_comprobar(host.vida == 100 and oso.estado == "tambaleando" and host.combate.paradas_logradas == 1,
			"Parar a tiempo evita el daño y tambalea a la osa")
		await _foto("parada")
		host.combate.pedir_parada(1)
		_comprobar(host.combate.parada == 0, "No se puede renovar la parada durante su espera")
		await _consultar()
		_comprobar(informe.get("paradas", 0) == 1 and informe.get("estado") == "tambaleando",
			"El cliente ve la parada y el tambaleo")
		await _esperar(1.0)
		Input.action_press("parada")
		await _esperar(0.3)
		oso._cambiar("aviso_zarpazo", 0)
		oso._siguiente()
		_comprobar(host.vida == 85 and host.combate.paradas_logradas == 1,
			"Parar demasiado pronto recibe el zarpazo normal")
		await _esperar(1.0)
		_comprobar(host.combate.parada == 0, "Mantener el botón no repite la parada automáticamente")
		Input.action_release("parada")
		await _preparar()
		host.combate.pedir_parada(-1)
		oso._cambiar("aviso_zarpazo", 0)
		oso._siguiente()
		_comprobar(host.vida == 85, "Una parada mirando al lado contrario no protege la espalda")
		await _preparar()
		host.combate.pedir_parada(1)
		oso._cambiar("embestida", 1)
		oso._golpeados.clear()
		oso._pegar(SITIO, 60, 30, 20, 1.6)
		_comprobar(host.vida == 100 and oso.estado == "tambaleando", "La parada también interrumpe una embestida")
		# Recién recuperada no se puede volver a tambalear, pero la parada sigue protegiendo.
		oso._cambiar("pausa", 60)
		host.combate.espera_parada = 0
		host._espera_servidor = 0
		host.combate.pedir_parada(1)
		oso._cambiar("embestida", 1)
		oso._golpeados.clear()
		oso._pegar(SITIO, 60, 30, 20, 1.6)
		_comprobar(host.vida == 100 and oso.estado == "embestida",
			"Tras tambalearse queda un rato sin volver a tambalearse; la parada aún evita el daño")
		oso._pegar(SITIO, 60, 30, 20, 1.6)
		_comprobar(host.vida == 100,
			"Una embestida ya parada no vuelve a dañar al mismo jugador en el siguiente contacto")
		await _preparar()
		host.combate.pedir_parada(1)
		oso._cambiar("aviso_piso", 0)
		oso._siguiente()
		_comprobar(host.vida == 85, "El golpe al suelo conserva su defensa de saltar, no se para")
		await _preparar()
		_orden_ajena.rpc_id(cliente)
		await _esperar(0.1)
		_comprobar(host.combate.parada == 0 and not host.combate.volando and not compa.combate.volando,
			"Un cliente no puede activar acciones en nombre de otro")
		compa._reaparecer.rpc(SITIO)
		host._reaparecer.rpc(SITIO + Vector2(0, 150))
		await _esperar(0.2)
		_accion.rpc_id(cliente, "parada")
		await _esperar(0.1)
		oso._cambiar("aviso_zarpazo", 0)
		oso._siguiente()
		_comprobar(compa.vida == 100 and compa.combate.paradas_logradas == 1 and oso.estado == "tambaleando",
			"El cliente también puede parar a tiempo con su propio botón")
		await _preparar()

		# R lanza al compañero cercano hacia la osa.
		compa._reaparecer.rpc(SITIO + Vector2(30, 0))
		oso.position = SITIO + Vector2(300, 0)
		await _esperar(0.2)
		Input.action_press("empujar_compa")
		await _esperar(0.04)
		Input.action_release("empujar_compa")
		_comprobar(compa.combate.volando, "R convierte al compañero cercano en un proyectil")
		await _esperar(0.25)
		await _foto("vuelo")
		await _esperar(0.45)
		_comprobar(oso.vida == 460 and compa.vida == 85 and oso.estado == "tambaleando",
			"El choque hace 40 al oso, 15 al compañero y tambalea al oso")
		await _foto("compazo")
		await _consultar()
		_comprobar(informe.get("vida_oso") == 460 and informe.get("vida_compa") == 85 and informe.get("impactos") == 1,
			"El cliente recibe ambos daños y un solo impacto")
		await _esperar(0.9)
		_comprobar(oso.vida == 460 and compa.vida == 85 and compa.combate.impactos_logrados == 1,
			"El mismo vuelo no aplica daño varias veces")
		await _preparar()
		compa._reaparecer.rpc(SITIO + Vector2(30, 0))
		oso.position = SITIO + Vector2(300, 100)
		await _esperar(0.2)
		host.combate.pedir_empujon(1)
		await _esperar(1.2)
		_comprobar(not compa.combate.volando and compa.vida == 100 and oso.vida == 460,
			"Si falla, aterriza sin causar daño a distancia ni quedarse como proyectil")
		await _preparar()
		host.combate.pedir_empujon(1)
		_comprobar(not compa.combate.volando, "R no alcanza a un compañero lejano")

		# El cliente puede lanzar al anfitrión usando su propio botón.
		compa._reaparecer.rpc(SITIO)
		host._reaparecer.rpc(SITIO + Vector2(30, 0))
		oso.position = SITIO + Vector2(300, 0)
		await _esperar(0.2)
		_accion.rpc_id(cliente, "empujar_compa")
		await _esperar(0.8)
		_comprobar(host.vida == 85 and oso.vida == 420, "El cliente puede lanzar al anfitrión y ambos reciben el resultado correcto")
		for id in [1, cliente]:
			await _preparar()
			oso.position = SITIO + Vector2(1000, 0)
			var base = _j(id)
			var pasajero = _j(cliente if id == 1 else 1)
			base.botellas = 2
			base._torre()._montar.rpc(pasajero.name.to_int(), id)
			await _esperar(0.2)
			if id == 1:
				_lanzar_sostenido()
			else:
				_lanzar_sostenido.rpc_id(id)
			await _esperar(0.1)
			_comprobar(pasajero.combate.volando and base.botellas == 2,
				"R desde la base lanza al pasajero sin gastar botella (%s)" % id)
			await _esperar(1.1)
			_comprobar(base.botellas == 2 and not base._apuntando_botella,
				"Mantener y soltar R después del compazo no lanza una botella (%s)" % id)
			pasajero._reaparecer.rpc(base.position + Vector2(30, 0))
			await _esperar(0.15)
			if id == 1:
				_accion("lanzar")
			else:
				_accion.rpc_id(id, "lanzar")
			await _esperar(0.3)
			_comprobar(base.botellas == 1 and not pasajero.combate.volando,
				"Fuera de torre R lanza botella aunque haya un compañero cercano (%s)" % id)
		await _preparar()
		oso.position = SITIO + Vector2(800, 0)
		host._torre()._montar.rpc(cliente, 1)
		await _esperar(0.15)
		Input.action_press("lanzar")
		await _esperar(0.05)
		Input.action_release("lanzar")
		_comprobar(compa.apoyo_id == 0 and compa.combate.volando and compa.altura > host._torre().ALTURA_HOMBROS,
			"R también lanza al pasajero desde los hombros y deshace su apoyo")
		main.juego.get_node("Partida").terminar(false)
		await _esperar(0.1)
		_comprobar(not compa.combate.volando, "Terminar la ronda cancela el proyectil")
		print("RESULTADO COMBATE COMPAS: %d fallos" % fallos)
		_finalizar.rpc()


	func _j(id: int) -> Node2D:
		return main.jugadores.get_node(str(id))


	func _preparar() -> void:
		for id in [1, cliente]:
			var j = _j(id)
			j._reaparecer.rpc(SITIO + Vector2(0, 150 if id != 1 else 0))
			j.vida = 100
			j.aturdimiento = 0
			j.proteccion = 0
			j._espera_servidor = 0
			j.combate.espera_parada = 0
			j.combate.espera_lanzamiento = 0
		main.jefe._sin_tambaleo = 0
		main.jefe._cambiar("pausa", 60)
		await _esperar(0.3)


	func _esperar(t: float) -> void:
		await get_tree().create_timer(t, true, true).timeout


	func _comprobar(ok: bool, texto: String) -> void:
		print(("OK: " if ok else "FALLO: ") + texto)
		if not ok:
			fallos += 1
			for j in get_tree().get_nodes_in_group("jugadores"):
				print("ESTADO ", j.name, " vida=", j.vida, " posición=", j.position, " altura=", j.altura,
					" parada=", j.combate.parada, " vuelo=", j.combate.volando, " aturdido=", j.aturdimiento)
			print("OSA ", main.jefe.estado, " vida=", main.jefe.vida, " informe=", informe)


	func _foto(nombre: String) -> void:
		if "--captura" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://combate_%s.png" % nombre)


	@rpc("authority", "reliable")
	func _lanzar_sostenido() -> void:
		Input.action_press("lanzar")
		await _esperar(0.9)
		Input.action_release("lanzar")


	@rpc("authority", "reliable")
	func _accion(accion: String) -> void:
		Input.action_press(accion)
		await _esperar(0.04)
		Input.action_release(accion)


	@rpc("authority", "reliable")
	func _orden_ajena() -> void:
		_j(1).combate.pedir_parada.rpc_id(1, 1)
		_j(1).combate.pedir_empujon.rpc_id(1, 1)


	func _consultar() -> void:
		# El RPC fiable puede llegar antes que el siguiente snapshot del sincronizador.
		await _esperar(0.15)
		informe = {}
		_pedir_informe.rpc_id(cliente)
		for intento in range(120):
			await get_tree().process_frame
			if not informe.is_empty():
				return


	@rpc("authority", "reliable")
	func _pedir_informe() -> void:
		var yo = _j(multiplayer.get_unique_id())
		_datos.rpc_id(1, {"paradas": _j(1).combate.paradas_logradas, "estado": main.jefe.estado,
			"vida_oso": main.jefe.vida, "vida_compa": yo.vida, "impactos": yo.combate.impactos_logrados})


	@rpc("any_peer", "reliable")
	func _datos(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos


	@rpc("authority", "call_local", "reliable")
	func _finalizar() -> void:
		get_tree().quit(0 if fallos == 0 else 1)
