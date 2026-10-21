extends SceneTree
## Dos peers --auto. Prueba entradas reales, bajas, azar, reaparición y forcejeos.
const SITIO := Vector2(2300, 520)


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaAbejas"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var informe := {}
	var abeja: Node2D
	var enjambre: Node2D


	func _ready() -> void:
		for accion in InputMap.get_actions():
			InputMap.action_erase_events(accion)
			Input.action_release(accion)
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for i in 600:
			await get_tree().process_frame
			if main.is_node_ready() and main.jugadores.get_child_count() == 2:
				break
		if main.jugadores.get_child_count() != 2:
			get_tree().quit(1)
			return
		abeja = main.juego.get_node("Partida").abeja_musculosa
		enjambre = main.juego.get_node("Mundo/Abejas2")
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		main.jefe.set_physics_process(false)
		for e in get_tree().get_nodes_in_group("enjambres"):
			e.set_physics_process(false)
		enjambre.set_physics_process(true)
		enjambre._aturdidas = 100
		_semilla(false)
		for id in [1, cliente, 1]:
			await _matar(id)
		_comprobar(abeja.bajas == 3 and enjambre.vivas == 24, "Tres golpes de ambos peers matan tres abejas individuales")
		_comprobar(abeja.estado == "inactiva", "El sorteo puede no producir una fusión")
		for i in 2:
			await _matar(1)
		_comprobar(enjambre.vivas == 0 and not enjambre.is_in_group("golpeables"), "Sin abejas vivas no queda un blanco invisible")
		enjambre.golpeada(1, _j(1))
		_comprobar(abeja.bajas == 5, "Pegar a un enjambre vacío no suma bajas")
		await _consultar()
		_comprobar(informe.get("vivas") == 0 and informe.get("bajas") == 5, "El cliente ve las mismas bajas y abejas muertas")
		await _colocar(1)
		await _esperar(8.2)
		_comprobar(enjambre.vivas == 31 and enjambre.is_in_group("golpeables"), "Las cinco abejas reaparecen tras ocho segundos y vuelven a ser golpeables")
		await _consultar()
		_comprobar(informe.get("vivas") == 31, "La reaparición también llega al cliente")
		var bajas_antes: int = abeja.bajas
		_j(1).botellazo(enjambre, 1)
		_comprobar(abeja.bajas == bajas_antes + 1 and enjambre.vivas == 30, "Un botellazo también mata una abeja y cuenta una sola baja")

		abeja.cancelar()
		abeja._bajas_recientes.clear()
		_semilla(true)
		for id in [1, cliente, 1]:
			await _matar(id)
		_comprobar(abeja.estado == "fusion" and abeja.contendiente == 0, "El tercer golpe inicia la animación sin agarrar antes de terminar")
		await _foto("fusion")
		await _esperar(1.9)
		for i in 180:
			if abeja.estado == "golpeando":
				break
			await get_tree().physics_frame
		_comprobar(abeja.estado == "golpeando" and not _j(1).en_forcejeo(), "Antes del empuje la abeja prepara sus puñetazos sin inmovilizar al jugador")
		await _foto("golpe_abeja")
		for i in 480:
			if abeja.estado == "forcejeo":
				break
			await get_tree().physics_frame
		await _esperar(0.1)
		_comprobar(abeja.golpes_previos == abeja.GOLPES_ANTES and _j(1).vida == 100 - 10 * abeja.GOLPES_ANTES,
			"Tres combos de boxeo (seis puños de cinco) ocurren antes del forcejeo")
		_comprobar(abeja.estado == "forcejeo" and _j(1).en_forcejeo(), "La abeja grande busca al jugador y traba las manos al acercarse")
		await _foto("forcejeo_derecha")
		await _consultar()
		_comprobar(informe.get("estado") == "forcejeo" and informe.get("contendiente") == 1 and informe.get("anim_host") == "forcejeo", "Forcejeo, músculos y rival replicados al cliente")
		var numero: int = abeja.encuentro
		for i in 3:
			abeja.registrar_baja(SITIO)
		_comprobar(abeja.encuentro == numero, "Otras tres bajas no crean una segunda musculosa simultánea")
		var hp: int = _j(1).vida
		_j(1).recibir_golpe(1, 10, 1)
		_comprobar(_j(1).vida == hp and _j(1).en_forcejeo(), "Otros golpes no interrumpen el duelo de fuerza")
		var fuerza_antes: float = abeja.fuerza
		_incorrecta.rpc_id(cliente, numero)
		abeja.pulsar(numero - 1)
		await _esperar(0.15)
		_comprobar(abeja.fuerza <= fuerza_antes, "Rechaza pulsaciones de otro jugador y de encuentros anteriores")
		await _accion("agarrar", 0.9)
		_comprobar(abeja.estado == "forcejeo" and abeja.fuerza < fuerza_antes + 0.07, "Mantener E aporta solo una pulsación, no fuerza automática")
		fuerza_antes = abeja.fuerza
		for i in 100:
			abeja.pulsar(numero)
		_comprobar(is_equal_approx(abeja.fuerza - fuerza_antes, abeja.FUERZA_PULSACION), "Cien peticiones en el mismo instante solo aportan una pulsación")
		var sitio: Vector2 = _j(1).position
		var ataques: int = _j(1)._numero_golpe
		for accion in ["golpear", "saltar", "parada", "lanzar", "derecha"]:
			await _accion(accion, 0.04)
		_comprobar(_j(1).position.distance_to(sitio) < 1 and _j(1)._numero_golpe == ataques and not _j(1).manteniendo, "E del duelo no recoge objetos y el resto de acciones queda bloqueado")
		for i in 20:
			if abeja.estado != "forcejeo":
				break
			await _accion("agarrar", 0.04)
			await _esperar(0.09)
		_comprobar(abeja.ganados == 1 and not _j(1).en_forcejeo() and _j(1).vida == hp, "Pulsar E repetidamente vence sin daño y libera al anfitrión")
		_comprobar(abeja.estado == "muriendo" and abeja.vida == 0, "Ganar el forcejeo noquea a la abeja al instante")
		await _foto("victoria")
		await _esperar(0.6)
		await _foto("muerte")
		await _esperar(1.4)
		_comprobar(abeja.estado == "inactiva" and _j(1).puede_actuar(), "Tras la animación de muerte desaparece y se recuperan los controles")
		await _colocar(1)
		abeja.vida = abeja.VIDA_MAX
		abeja.position = SITIO + Vector2(240, 0)
		abeja.golpes_previos = 0
		abeja.estado = "buscando"
		abeja.tiempo = 0
		abeja._busqueda = 0
		await _esperar(0.25)
		_comprobar(abeja.caminando and abeja.position.x < SITIO.x + 230, "Se acerca caminando antes de golpear")
		for i in 180:
			if abeja.estado == "golpeando":
				break
			await get_tree().physics_frame
		await _esperar(0.16)
		_comprobar(_j(1).vida == 100, "La preparación del puño no adelanta el daño")
		await _accion("parada", 0.04)
		await _esperar(0.22)
		_comprobar(_j(1).vida == 100 and _j(1).combate.paradas_logradas > 0, "F a tiempo bloquea el puñetazo de la abeja")
		# Salir de la línea en cuanto empieza el combo esquiva el jab y el recto.
		# (Primero se corta el combo anterior: su recto aún podía llegar.)
		abeja.cancelar()
		await _colocar(1)
		abeja.position = SITIO + Vector2(240, 0)
		abeja.golpes_previos = 0
		abeja.estado = "buscando"
		abeja.tiempo = 0
		for i in 180:
			if abeja.estado == "golpeando":
				break
			await get_tree().physics_frame
		await _accion("abajo", 0.5)
		await _esperar(0.3)
		_comprobar(_j(1).vida == 100, "Salir de la línea a tiempo esquiva los dos puños del combo")
		abeja.cancelar()
		# El contacto desmonta la torre y suelta la pieza, sin dejar pasajeros bloqueados.
		await _colocar(1)
		main.juego.get_node("Partida").torre._montar.rpc(cliente, 1)
		abeja.lado = 1
		abeja.position = SITIO + Vector2(abeja.SEPARACION, 0)
		abeja._empezar(_j(1))
		await _esperar(0.15)
		_comprobar(_j(cliente).apoyo_id == 0 and _j(1).en_forcejeo(), "El agarre desmonta una torre y deja libre al pasajero")
		abeja.cancelar()
		await _colocar(1)
		var pieza: Node2D = main.juego.get_node("Mundo/Miel")
		pieza.agarrar(1)
		abeja._empezar(_j(1))
		await _esperar(0.15)
		_comprobar(pieza.portador == 0 and _j(1).en_forcejeo(), "El jugador suelta la miel antes de agarrar las manos de la abeja")
		abeja.cancelar()
		pieza.position = Vector2(6940, 615)

		await _iniciar(cliente, -1)
		await _consultar()
		_comprobar(informe.get("contendiente") == cliente and informe.get("anim_cliente") == "forcejeo", "También atrapa al cliente y mira correctamente hacia la izquierda")
		for i in 15:
			if abeja.estado != "forcejeo":
				break
			_accion.rpc_id(cliente, "agarrar", 0.04)
			await _esperar(0.14)
		_comprobar(abeja.ganados == 2 and not _j(cliente).en_forcejeo(), "El cliente puede ganar usando sus propias pulsaciones E")
		await _consultar()
		_comprobar(informe.get("ganados") == 2 and informe.get("contendiente") == 0, "Resultado y liberación coinciden en ambos peers")
		await _iniciar(cliente, 1)
		_modo_bot.rpc_id(cliente, true)
		await _esperar(4)
		_modo_bot.rpc_id(cliente, false)
		_comprobar(abeja.ganados == 3 and abeja.contendiente == 0, "Un bot atrapado también responde con pulsaciones normales")

		await _iniciar(1, -1)
		await _foto("forcejeo_izquierda")
		hp = _j(1).vida
		await _esperar(6.5)
		_comprobar(abeja.perdidos == 1 and _j(1).vida == hp - 15 and not _j(1).en_forcejeo(), "Sin pulsar E gana la abeja: quince de daño, empujón y liberación")
		_comprobar(abeja.estado == "paliza" and _j(1).noqueado() and not _j(1).puede_actuar(), "Perder deja al jugador K.O. y aturdido")
		await _esperar(0.9)
		await _consultar()
		_comprobar(informe.get("anim_host") == "caido", "El cliente ve al noqueado tirado en el suelo")
		await _foto("ko")
		await _esperar(2.4)
		_comprobar(_j(1).vida < hp - 15, "Mientras está K.O. la abeja le sigue pegando")
		_comprobar(not _j(1).noqueado() and abeja.estado in ["buscando", "golpeando"] and abeja.golpes_previos <= 1,
			"Al terminar la paliza vuelve a buscar pelea para otro forcejeo")
		# Los compas pueden ayudar: a golpes también se le acaba la vida.
		await _colocar(1)
		abeja.cancelar()
		abeja.vida = 8
		abeja.lado = 1
		abeja.position = SITIO + Vector2(40, 0)
		abeja.golpes_previos = 0
		abeja.estado = "buscando"
		abeja.tiempo = 0
		await _esperar(0.05)
		_j(1).mirando = 1
		await _accion("golpear", 0.04)
		await _esperar(0.25)
		_comprobar(abeja.vida == 0 and abeja.estado == "muriendo" and abeja.ganados == 3,
			"Bajarle la vida a golpes también la noquea, sin contar como forcejeo ganado")
		await _esperar(2)
		abeja.vida = abeja.VIDA_MAX
		await _probar_pleito_osa()
		await _iniciar(1, 1)
		abeja.tiempo = abeja.DURACION_FORCEJEO - 0.02
		abeja.fuerza = 0.8
		await _esperar(0.1)
		_comprobar(abeja.perdidos == 2 and not _j(1).en_forcejeo(), "El límite de ocho segundos impide forcejeos infinitos")

		await _iniciar(cliente, 1)
		_j(cliente).caido = true
		await _esperar(0.1)
		_comprobar(abeja.contendiente == 0 and abeja.estado == "inactiva", "Caída externa cancela el agarre sin dejar al jugador bloqueado")
		_j(cliente).caido = false
		await _iniciar(1, 1)
		main.juego.get_node("Partida").terminar(false)
		await _consultar()
		_comprobar(abeja.contendiente == 0 and informe.get("contendiente") == 0 and abeja.estado == "inactiva", "Terminar ronda libera a todos y oculta la barra en red")
		main._preparar_sala()
		await _esperar(0.4)
		abeja = main.juego.get_node("Partida").abeja_musculosa
		_comprobar(abeja.estado == "inactiva" and abeja.bajas == 0 and abeja.contendiente == 0,
			"Volver a la sala reinicia contador y encuentro")
		for datos in get_node("/root/Red").jugadores.values():
			datos.listo = true
		get_node("/root/Red").iniciar_partida()
		await _esperar(0.4)
		main.jefe.set_physics_process(false)
		await _iniciar(cliente, 1)
		_desconectar.rpc_id(cliente, fallos)
		await _esperar(0.5)
		_comprobar(abeja.contendiente == 0 and abeja.estado == "inactiva", "Desconectar al contendiente libera el encuentro sin errores")
		print("RESULTADO ABEJAS: %d fallos" % fallos)
		get_tree().quit(0 if fallos == 0 else 1)


	## Mamá Osa y la abeja se pegan de casualidad, se pelean y forcejean entre ellas.
	func _probar_pleito_osa() -> void:
		var oso: Node2D = main.jefe
		abeja.cancelar()
		await _colocar(1)
		oso.activa = true
		oso.vida = 1000
		oso.vida_max = 1000
		oso._sin_tambaleo = 0
		oso._cambiar("pausa", 60)
		# La osa queda entre la abeja y el jugador: el jab se la lleva a ella.
		abeja.vida = abeja.VIDA_MAX
		abeja.lado = 1
		abeja.position = SITIO + Vector2(abeja.SEPARACION, 0)
		oso.position = abeja.position - Vector2(70, 0)
		abeja._blanco = 1
		abeja._siguiente_contacto = 0
		abeja.golpes_previos = 1
		abeja.estado = "golpeando"
		abeja.tiempo = 0
		await _esperar(0.45)
		_comprobar(abeja.estado == "rina_osa" and oso.estado == "rivalidad" and oso.vida < 1000 and _j(1).vida == 100,
			"Si la abeja golpea a la osa de casualidad, dejan al jugador y se pelean")
		await _esperar(0.8)
		await _consultar()
		_comprobar(informe.get("estado") == "rina_osa" and abeja.vida < abeja.VIDA_MAX and oso.vida < 990,
			"En el pleito se dan golpes entre ellas y el cliente lo ve")
		await _foto("pleito")
		await _esperar(1.5)
		_comprobar(abeja.estado == "forcejeo_osa" and oso.estado == "rivalidad", "Después de los golpes forcejean entre ellas")
		await _foto("forcejeo_osa")
		await _esperar(1.0)
		await _foto("forcejeo_osa_2")
		await _esperar(3.3)
		_comprobar(oso.estado != "rivalidad" and abeja.estado not in ["rina_osa", "forcejeo_osa"],
			"El forcejeo entre ellas termina solo y la osa vuelve a lo suyo")
		# Gana la abeja: le quita vida y la deja mareada.
		abeja.cancelar()
		await _esperar(0.1)
		oso._sin_tambaleo = 0
		oso._cambiar("pausa", 60)
		abeja.vida = abeja.VIDA_MAX
		abeja.lado = 1
		abeja.position = oso.position + Vector2(oso.ancho + 45, 0)
		abeja.estado = "buscando"
		abeja.provocar_osa()
		abeja.estado = "forcejeo_osa"
		abeja.fuerza = 1.0
		var vida_osa: int = oso.vida
		await _esperar(0.1)
		_comprobar(oso.estado == "tambaleando" and oso.vida == vida_osa - abeja.DANO_GANA_ABEJA and abeja.estado in ["buscando", "golpeando"],
			"Si gana la abeja, la osa queda mareada y pierde vida extra")
		# Un zarpazo de la osa que alcanza a la abeja también arma el pleito.
		abeja.cancelar()
		await _esperar(0.1)
		oso._cambiar("pausa", 60)
		oso.mirando = 1
		abeja.vida = abeja.VIDA_MAX
		abeja.position = oso.position + Vector2(60, 0)
		abeja.estado = "buscando"
		var vida_abeja: int = abeja.vida
		oso._cambiar("aviso_zarpazo", 0)
		oso._siguiente()
		_comprobar(abeja.estado == "rina_osa" and oso.estado == "rivalidad" and abeja.vida < vida_abeja,
			"Si el zarpazo de la osa alcanza a la abeja, también se pelean")
		# Gana la osa: la abeja queda noqueada.
		abeja.estado = "forcejeo_osa"
		abeja.fuerza = 0.0
		await _esperar(0.1)
		_comprobar(abeja.estado == "muriendo" and oso.estado == "pausa", "Si gana la osa, noquea a la abeja")
		await _esperar(2)
		abeja.cancelar()
		oso.activa = false
		oso._cambiar("pausa", 60)
		oso.position = Vector2(6800, 500)


	func _j(id: int) -> Node2D:
		return main.jugadores.get_node(str(id))


	func _semilla(fusion: bool) -> void:
		var muestra := RandomNumberGenerator.new()
		for s in 100:
			muestra.seed = s
			if (muestra.randf() < abeja.PROBABILIDAD) == fusion:
				abeja.azar.seed = s
				return


	func _colocar(id: int) -> void:
		for peer in [1, cliente]:
			var j := _j(peer)
			j._reaparecer.rpc(SITIO + Vector2(0, 0 if peer == id else 180))
			j.vida = 100
			j.caido = false
			j.proteccion = 0
			j.aturdimiento = 0
			j._recuperacion = 0
			j._espera_servidor = 0
		await _esperar(0.2)


	func _matar(id: int) -> void:
		enjambre._aturdidas = 100
		await _colocar(id)
		enjambre.position = SITIO + Vector2(40, 0)
		_j(id).mirando = 1
		if id == 1:
			await _accion("golpear", 0.04)
		else:
			_accion.rpc_id(id, "golpear", 0.04)
		await _esperar(0.2)


	func _iniciar(id: int, direccion: int) -> void:
		abeja.cancelar()
		await _colocar(id)
		abeja.encuentro += 1
		abeja.golpes_previos = abeja.GOLPES_ANTES # Los casos siguientes aíslan el minijuego tras el combo.
		abeja.vida = abeja.VIDA_MAX
		abeja._busqueda = 0
		abeja.lado = direccion
		abeja.position = SITIO + Vector2(direccion * abeja.SEPARACION, 0)
		abeja.estado = "buscando"
		abeja.tiempo = 0
		await _esperar(0.2)


	func _esperar(t: float) -> void:
		await get_tree().create_timer(t, true, true).timeout


	@rpc("authority", "call_remote", "reliable")
	func _accion(accion: String, t: float) -> void:
		Input.action_press(accion)
		await _esperar(t)
		Input.action_release(accion)


	@rpc("authority", "call_remote", "reliable")
	func _incorrecta(numero: int) -> void:
		for i in 10:
			abeja.pulsar.rpc_id(1, numero)


	@rpc("authority", "call_remote", "reliable")
	func _modo_bot(activo: bool) -> void:
		_j(multiplayer.get_unique_id())._bot = "torre" if activo else ""


	func _comprobar(ok: bool, texto: String) -> void:
		print(("OK: " if ok else "FALLO: ") + texto)
		if not ok:
			fallos += 1
			print("Estado ", abeja.estado, " fuerza ", abeja.fuerza, " bajas ", abeja.bajas, " cliente ", informe)


	func _consultar() -> void:
		await _esperar(0.15)
		informe = {}
		_pedir_informe.rpc_id(cliente)
		for i in 120:
			await get_tree().process_frame
			if not informe.is_empty():
				return


	@rpc("authority", "reliable")
	func _pedir_informe() -> void:
		_datos.rpc_id(1, {"estado": abeja.estado, "contendiente": abeja.contendiente, "ganados": abeja.ganados,
			"vivas": enjambre.vivas, "bajas": abeja.bajas, "anim_host": _j(1)._animacion,
			"anim_cliente": _j(multiplayer.get_unique_id())._animacion})


	@rpc("any_peer", "reliable")
	func _datos(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos


	func _foto(nombre_foto: String) -> void:
		if "--captura" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://abejas_%s.png" % nombre_foto)


	@rpc("authority", "call_local", "reliable")
	func _desconectar(errores: int) -> void:
		multiplayer.multiplayer_peer.close()
		get_tree().quit(0 if errores == 0 else 1)
