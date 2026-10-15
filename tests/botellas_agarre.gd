extends SceneTree
## Mismos argumentos host/join que combate_red.gd. Comprueba las botellas vacías
## lanzables y el agarre de Mamá Osa, en anfitrión y cliente.

const SITIO := Vector2(2300, 520)   # tramo del camino lejos de abejas y del jefe


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaBotellasAgarre"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var informe: Dictionary = {}
	var fallos := 0


	func _ready() -> void:
		main = load("res://escenas/main.tscn").instantiate()
		get_tree().root.add_child.call_deferred(main)
		for intento in range(600):
			await get_tree().process_frame
			if main.is_node_ready() and main.jugadores.get_child_count() == 2:
				break
		if not main.is_node_ready() or main.jugadores.get_child_count() != 2:
			get_tree().quit(1)
			return
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		var anfitrion = main.jugadores.get_node("1")
		var invitado = main.jugadores.get_node(str(cliente))
		var partida = main.juego.get_node("Partida")
		var jefe = main.jefe
		await _esperar(0.3)

		# --- Botellas vacías ---
		_comprobar(invitado.botellas == 0, "Empieza sin botellas vacías")
		invitado.pedir_lanzar()
		await _esperar(0.3)
		_comprobar(partida._numero_botella == 0, "Sin botellas vacías no se lanza nada")

		invitado.cervezas = 1
		invitado.vida = 50
		invitado.pedir_beber()
		await _esperar(invitado.TIEMPO_BEBER + 0.3)
		_comprobar(invitado.botellas == 1 and invitado.cervezas == 0, "Terminar una chela deja una botella vacía")

		invitado._reaparecer.rpc(SITIO)
		anfitrion._reaparecer.rpc(SITIO + Vector2(150, 0))
		await _esperar(0.4)
		var vida_antes: int = anfitrion.vida
		invitado.pedir_lanzar()
		await _esperar(1.5)
		await _pedir_informe()
		_comprobar(invitado.botellas == 0 and informe.botellas == 0, "Lanzar gasta la botella en las dos pantallas")
		_comprobar(anfitrion.vida == vida_antes - 12 and informe.vida_anfitrion == anfitrion.vida,
			"El botellazo le quita 12 de vida al compañero (fuego amigo)")
		_comprobar(partida.estadisticas[1].fuego_amigo == 12, "El botellazo cuenta como fuego amigo")
		_comprobar(_botellas_en_vuelo() == 0 and informe.en_vuelo == 0, "La botella se rompe y desaparece en ambas pantallas")

		# --- Botellazo al jefe ---
		anfitrion._reaparecer.rpc(SITIO + Vector2(0, 150))
		jefe.activa = true
		jefe.vida_max = 500
		jefe.vida = 500
		jefe.position = SITIO + Vector2(170, 0)
		jefe._cambiar("pausa", 60.0)
		await _esperar(0.4)
		invitado.botellas = 1
		invitado.pedir_lanzar()
		await _esperar(1.2)
		_comprobar(jefe.vida == 488, "Una botella le quita 12 de vida a Mamá Osa")
		_comprobar(partida.estadisticas[cliente].dano_jefe == 12, "El botellazo cuenta como daño al jefe")

		# --- Agarre ---
		invitado.vida = 100
		invitado._reaparecer.rpc(jefe.position + Vector2(-90, 0))
		await _esperar(0.4)
		jefe.mirando = -1
		jefe._cambiar("aviso_agarre", 0.05)
		await _esperar(0.5)
		var mano: Vector2 = jefe.position + jefe.MANO * Vector2(-1, 1)
		_comprobar(jefe.estado == "agarrando" and invitado.aturdimiento > 0, "Mamá Osa agarra al jugador que tiene enfrente")
		_comprobar(invitado.position.distance_to(mano) < 12 and invitado.altura > 40,
			"El agarrado queda sostenido en el aire junto a sus patas")
		var x_antes: float = invitado.position.x
		await _esperar(3.0)
		_comprobar(invitado.vida == 100 - jefe.DANO_AGARRE, "Al aventarlo le quita la vida del agarre")
		_comprobar(x_antes - invitado.position.x > 400 and invitado.altura == 0,
			"Sale volando bien lejos hacia donde mira la osa (%d px)" % (x_antes - invitado.position.x))
		_comprobar(partida.estadisticas[cliente].vuelo > 400, "El vuelo queda en las estadísticas")

		# --- Esquivar el agarre ---
		jefe._cambiar("pausa", 60.0)
		invitado._reaparecer.rpc(jefe.position + Vector2(-90, 0))
		await _esperar(0.4)
		invitado.proteccion = 2.0
		var vida_previa: int = invitado.vida
		jefe._cambiar("aviso_agarre", 0.05)
		await _esperar(0.4)
		_comprobar(jefe.estado == "pausa" and invitado.vida == vida_previa and invitado.altura == 0,
			"Un jugador invulnerable (rodando) no puede ser agarrado")

		# --- Rescate justo antes del lanzamiento, con víctima local y remota ---
		for victima in [anfitrion, invitado]:
			var rescatista = invitado if victima == anfitrion else anfitrion
			jefe._cambiar("pausa", 60.0)
			rescatista._reaparecer.rpc(SITIO + Vector2(0, 150))
			victima._reaparecer.rpc(jefe.position + Vector2(-90, 0))
			victima.vida = 100
			victima.proteccion = 0.0
			await _esperar(0.4)
			jefe._agarrado = jefe._atrapar()
			jefe._cambiar("agarrando", jefe.TIEMPO_SUJETANDO)
			await _esperar(0.7)
			_comprobar(jefe._agarrado == victima and victima.altura > 40,
				"La víctima %s está agarrada antes del rescate" % victima.name)
			# Ruta de daño de un golpe amigo; todavía no hubo un paso de movimiento.
			victima.recibir_golpe(-1, 10, 1.0, rescatista.name.to_int())
			_comprobar(victima.position.distance_to(jefe.position + jefe.MANO * Vector2(-1, 1)) < 60,
				"El rescate de %s ocurre sin haber salido del alcance de la mano" % victima.name)
			jefe._siguiente()
			_comprobar(victima.vida == 90 and jefe.estado == "pausa",
				"Mamá Osa no vuelve a dañar ni lanza a %s tras el rescate" % victima.name)
			await _esperar(0.2)
			await _pedir_informe()
			var vida_remota: int = informe.vida_anfitrion if victima == anfitrion else informe.vida
			var sujecion_local: float = victima._sujeto if victima == anfitrion else informe.sujeto
			_comprobar(vida_remota == 90 and sujecion_local <= 0.0,
				"El rescate de %s conserva la vida y suelta al dueño en red" % victima.name)

		print("RESULTADO BOTELLAS Y AGARRE: %d fallos" % fallos)
		_finalizar.rpc(fallos)


	func _esperar(segundos: float) -> void:
		await get_tree().create_timer(segundos).timeout


	func _botellas_en_vuelo() -> int:
		var total := 0
		for nodo in main.juego.get_node("Mundo").get_children():
			if nodo.name.begins_with("Botella"):
				total += 1
		return total


	func _comprobar(condicion: bool, descripcion: String) -> void:
		print("%s: %s" % ["OK" if condicion else "FALLO", descripcion])
		if not condicion:
			fallos += 1


	func _pedir_informe() -> void:
		informe = {}
		_informar_al_anfitrion.rpc_id(cliente)
		for intento in range(300):
			await get_tree().process_frame
			if not informe.is_empty():
				return
		push_error("El cliente no respondió")
		get_tree().quit(1)


	@rpc("authority", "reliable")
	func _informar_al_anfitrion() -> void:
		var yo = main.jugadores.get_node(str(multiplayer.get_unique_id()))
		_informar.rpc_id(1, {"botellas": yo.botellas, "vida_anfitrion": main.jugadores.get_node("1").vida,
			"en_vuelo": _botellas_en_vuelo(), "vida": yo.vida, "sujeto": yo._sujeto})


	@rpc("any_peer", "reliable")
	func _informar(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos


	@rpc("authority", "call_local", "reliable")
	func _finalizar(codigo: int) -> void:
		get_tree().quit(0 if codigo == 0 else 1)
