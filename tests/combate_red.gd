extends SceneTree
## Ejecutar dos instancias con --headless --max-fps 60 --script tests/combate_red.gd:
## -- --host --auto --puerto=17781
## -- --join=127.0.0.1 --auto --puerto=17781


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaCombate"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var informe: Dictionary = {}


	func _ready() -> void:
		main = load("res://escenas/main.tscn").instantiate()
		get_tree().root.add_child.call_deferred(main)
		for intento in range(600):
			await get_tree().process_frame
			if main.is_node_ready() and main.jugadores.get_child_count() == 2:
				break
		if not main.is_node_ready() or main.jugadores.get_child_count() != 2:
			push_error("No se conectaron los dos jugadores de prueba")
			get_tree().quit(1)
			return
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		await _esperar(0.3)
		await _probar()
		print("RESULTADO: %d fallos" % fallos)
		_finalizar.rpc(fallos)


	func _probar() -> void:
		var anfitrion = main.jugadores.get_node("1")
		var invitado = main.jugadores.get_node(str(cliente))
		for j in [anfitrion, invitado]:
			_comprobar(j.vida == 100, "Vida inicial de 100")
			_comprobar(j.get_node("SincronizadorVida").get_multiplayer_authority() == 1,
				"La vida pertenece al servidor")

		_orden.rpc_id(cliente, "alterar_vida")
		await _esperar(0.3)
		await _consultar()
		_comprobar(invitado.vida == 100 and informe.vida == 100,
			"El servidor rechaza la vida inventada y corrige al cliente")

		_colocar.rpc()
		await _esperar(0.2)
		_orden.rpc_id(cliente, "rafaga")
		await _esperar(0.15)
		_comprobar(anfitrion.vida == 90, "Dos RPC inmediatas no superponen sus contactos")
		await _esperar(0.4)
		_colocar.rpc()
		await _esperar(0.2)
		_orden.rpc_id(cliente, "rafaga")
		await _esperar(0.15)
		_comprobar(anfitrion.vida == 80, "El siguiente contacto del cliente causa daño")

		_colocar.rpc()
		await _esperar(0.2)
		anfitrion.golpear(1)
		await _esperar(0.15)
		await _consultar()
		_comprobar(invitado.vida == 90 and informe.vida == 90,
			"El golpe del anfitrión se confirma y el cliente recibe el daño")
		invitado.recibir_dano(3)
		await _esperar(0.15)
		await _consultar()
		_comprobar(invitado.vida == 87 and informe.vida == 87,
			"Daño sin empujón, como el de las abejas, sincronizado")
		invitado.aturdir(1.6)
		await _consultar()
		_comprobar(informe.aturdido > 0, "El rugido aturde al cliente")

		_colocar.rpc()
		await _esperar(0.2)
		var pieza = main.juego.get_node("Mundo/Miel")
		pieza.agarrar(cliente)
		invitado.recibir_golpe(1, 9999, 1.0)
		await _esperar(0.3)
		await _consultar()
		_comprobar(invitado.vida == 0 and informe.vida == 0 and informe.caido,
			"Un golpe mortal deja caído al cliente, sin reaparecer")
		_comprobar(pieza.portador == 0 and informe.portador == 0,
			"La pieza se suelta al morir")
		_comprobar(informe.altura == 0, "Caer detiene el empujón")
		_orden.rpc_id(cliente, "acciones_caido")
		await _esperar(0.1)
		_comprobar(invitado.bebiendo == 0 and invitado.rodando == 0,
			"Un caído no puede beber ni rodar")
		_colocar.rpc()
		await _esperar(0.2)
		Input.action_press("agarrar")
		await _esperar(0.8)
		_comprobar(invitado.reanimacion > 0, "Mantener E junto al caído avanza la reanimación")
		Input.action_release("agarrar")
		await _esperar(0.1)
		_comprobar(invitado.reanimacion == 0, "Soltar E interrumpe la reanimación")
		Input.action_press("agarrar")
		await _esperar(3.2)
		Input.action_release("agarrar")
		await _consultar()
		_comprobar(not informe.caido and informe.vida == 40,
			"Tres segundos levantan al cliente con 40 de vida")
		_comprobar(invitado.proteccion > 0, "Al levantarse hay protección temporal")
		await _probar_supervivencia(anfitrion, invitado)

		var jefe = main.jefe
		jefe.set_physics_process(false)
		jefe.activa = true
		jefe.estado = "pausa"
		jefe._t = 10.0
		jefe.vida_max = 300
		jefe.vida = 150
		jefe._physics_process(0.0)
		_comprobar(jefe.fase == 2, "La mitad de vida corresponde a fase 2")
		jefe.enfurecer("prueba desde fase 2")
		jefe._physics_process(0.0)
		_comprobar(jefe.fase == 3, "El primer enojo en fase 2 sube a fase 3 y persiste")
		jefe.fase = 1
		jefe.vida = 300
		jefe.enojo = 0
		jefe._espera_enojo = 0.0
		jefe.enfurecer("primer osezno")
		jefe.enfurecer("golpe repetido durante la espera")
		_comprobar(jefe.fase == 2 and jefe.enojo == 1, "El enojo respeta su espera")
		jefe._physics_process(4.1)
		jefe.enfurecer("olla rota")
		_comprobar(jefe.fase == 3, "Un segundo enojo permite llegar a fase 3")
		jefe._physics_process(4.1)
		jefe.enfurecer("fase máxima")
		_comprobar(jefe.fase == 3, "La fase nunca supera 3")
		# Daño y alcance reales, no solo el valor calculado del ataque.
		jefe.estado = "pausa"
		jefe.vida = 300
		jefe.position = anfitrion.position + Vector2(60, 0)
		anfitrion.aturdimiento = 0
		anfitrion.borrachera = 30
		anfitrion._espera_servidor = 0
		anfitrion.golpear(1)
		await _esperar(0.12)
		_comprobar(jefe.vida == 285, "Alegre aumenta el daño del golpe a 15")
		anfitrion.borrachera = 80
		anfitrion._espera_servidor = 0
		jefe.position = anfitrion.position + Vector2(110, 0)
		anfitrion.golpear(1)
		await _esperar(0.12)
		_comprobar(jefe.vida == 255, "Ven pa'cá causa 30 de daño y tiene más alcance")
		await _probar_final(anfitrion, invitado)


	func _probar_supervivencia(anfitrion: Node, invitado: Node) -> void:
		var partida = main.juego.get_node("Partida")
		_colocar.rpc(Vector2(440, 550))
		await _esperar(0.2)
		var cerveza = main.juego.get_node("Mundo/Cerveza0")
		cerveza.recoger(anfitrion)
		cerveza.recoger(invitado)
		_comprobar(anfitrion.cervezas + invitado.cervezas == 1 and not cerveza.disponible,
			"Una botella no se puede recoger dos veces")
		invitado.cervezas = 3
		invitado.vida = 50
		_orden.rpc_id(cliente, "beber_doble")
		await _esperar(0.15)
		_comprobar(invitado.cervezas == 3 and invitado.vida == 50,
			"Empezar a beber no consume la botella ni cura al instante")
		await _esperar(2.0)
		await _consultar()
		_comprobar(informe.vida == 85 and informe.borrachera > 25,
			"La cerveza cura 35 y añade borrachera en ambos peers")
		_comprobar(partida.estadisticas[cliente].cervezas == 1, "Se registra la cerveza terminada")
		_orden.rpc_id(cliente, "beber_doble")
		await _esperar(0.1)
		invitado.recibir_dano(3)
		await _esperar(2.1)
		_comprobar(invitado.vida == 82 and invitado.bebiendo == 0 and invitado.cervezas == 2,
			"El daño interrumpe la bebida sin gastar la botella ni curar")
		_orden.rpc_id(cliente, "beber_doble")
		await _esperar(2.2)
		_comprobar(invitado.vida == 100, "La cura nunca supera los 100 puntos")
		invitado.cervezas = 0
		_orden.rpc_id(cliente, "beber_doble")
		await _esperar(0.1)
		_comprobar(invitado.bebiendo == 0, "Sin botellas no se puede beber")

		_colocar.rpc()
		invitado.borrachera = 80
		invitado.cervezas = 1
		anfitrion.position = Vector2(900, 520)
		await _esperar(0.2)
		_orden.rpc_id(cliente, "beber_doble")
		await _esperar(2.2)
		_comprobar(invitado.nausea > 0 and invitado.vomitando == 0,
			"El exceso primero da náusea (cachetes inflados) antes de vomitar")
		# Las arcadas con E lo hacen vomitar antes de que se acabe la náusea.
		for i in invitado.ARCADAS:
			invitado.pedir_arcada()
		await _esperar(0.2)
		await _consultar()
		_comprobar(invitado.vomitando > 0 and informe.charcos == 1,
			"El exceso provoca vómito y un charco sincronizado")
		var vida_antes_charco: int = anfitrion.vida
		anfitrion._reaparecer.rpc(get_tree().get_first_node_in_group("charcos").position)
		await _esperar(0.15)
		_comprobar(anfitrion.aturdimiento > 0, "El charco hace resbalar a otro jugador")
		_comprobar(anfitrion.vida == vida_antes_charco - 5, "Pisar el charco de vómito quita vida")
		await _esperar(2.5)
		_colocar.rpc(Vector2(1600, 520))
		await _esperar(0.2)
		invitado.borrachera = 90
		invitado._sueno = 5.9
		main.jefe.activa = true
		main.jefe.estado = "pausa"
		main.jefe._t = 100
		await _esperar(0.2)
		_comprobar(invitado.dormido > 0 and partida.estadisticas[cliente].dormidas == 1,
			"Hasta atrás puede dormirse y registra la siesta en combate")
		invitado.dormido = 0
		invitado.borrachera = 0
		invitado._sueno = 0
		var antes: int = invitado.vida
		_orden.rpc_id(cliente, "rodar")
		await _esperar(0.05)
		invitado.recibir_dano(15)
		_comprobar(invitado.vida == antes and invitado.rodando > 0,
			"La rodada evita daño durante su ventana inicial")
		await _esperar(0.4)
		_orden.rpc_id(cliente, "rodar")
		await _esperar(0.1)
		_comprobar(invitado.rodando == 0, "La rodada no ignora su enfriamiento")
		invitado.recibir_dano(15)
		_comprobar(invitado.vida == antes - 15, "Fuera de la rodada vuelve a recibir daño")


	func _probar_final(anfitrion: Node, invitado: Node) -> void:
		var partida = main.juego.get_node("Partida")
		var jefe = main.jefe
		var dano_anterior: float = partida.estadisticas[1].dano_jefe
		jefe.estado = "pausa"
		jefe.vida = 10
		jefe.position = anfitrion.position + Vector2(60, 0)
		anfitrion.aturdimiento = 0
		anfitrion.borrachera = 80
		anfitrion._espera_servidor = 0
		anfitrion.golpear(1)
		await _esperar(0.2)
		_comprobar(jefe.fase == 4 and not partida.finalizada,
			"La tercera fase termina en ultra, no en resultados anticipados")
		jefe.ultra._reloj = 100
		var punto_ultra: Vector2 = anfitrion.position + Vector2(60, 0)
		anfitrion._reaparecer.rpc(punto_ultra + Vector2(-60, 70))
		jefe.ultra._atacar.rpc(punto_ultra, false, 0)
		await _esperar(0.55)
		anfitrion._reaparecer.rpc(punto_ultra + Vector2(-60, 0))
		jefe.vida = 10
		anfitrion.golpear(1)
		await _esperar(0.2)
		await _consultar()
		_comprobar(partida.finalizada and informe.finalizada and informe.victoria,
			"La derrota del jefe abre resultados en las dos instancias")
		_comprobar(partida.estadisticas[1].dano_jefe - dano_anterior == 20,
			"Se registra el daño real al jefe, sin contar daño sobrante")
		_comprobar(partida.resultados.size() == 2 and informe.resultados == 2,
			"Los resultados incluyen a todo el equipo")
		var vida: int = invitado.vida
		invitado.recibir_dano(10)
		_comprobar(invitado.vida == vida, "La ronda terminada no acepta más daño")
		main._preparar_sala()
		await _esperar(0.3)
		_comprobar(main.jugadores.get_child_count() == 0 and not main.juego.get_node("Partida").finalizada,
			"Volver a la sala prepara una ronda limpia")
		# Iniciar otra ronda sobre la misma conexión, después de reconstruir ambos mundos.
		for datos in get_node("/root/Red").jugadores.values():
			datos.listo = true
		get_node("/root/Red").iniciar_partida()
		await _esperar(0.3)
		for j in main.jugadores.get_children():
			j._perder_vida(9999)
		await _esperar(2.2)
		await _consultar()
		_comprobar(informe.finalizada and not informe.victoria, "Si todos caen se puede cerrar y reintentar la ronda")


	func _esperar(segundos: float) -> void:
		await get_tree().create_timer(segundos).timeout


	func _consultar() -> void:
		informe = {}
		_orden.rpc_id(cliente, "informar")
		for intento in range(120):
			await get_tree().process_frame
			if not informe.is_empty():
				return
		push_error("El cliente no respondió")
		get_tree().quit(1)


	func _comprobar(condicion: bool, descripcion: String) -> void:
		print("%s: %s" % ["OK" if condicion else "FALLO", descripcion])
		if not condicion:
			fallos += 1


	@rpc("authority", "call_local", "reliable")
	func _colocar(origen := Vector2(1000, 520)) -> void:
		if multiplayer.is_server():
			for jugador in main.jugadores.get_children():
				jugador._cancelar_golpes() # Cada caso empieza sin ataques encolados del anterior.
				jugador.aturdimiento = 0
				jugador.proteccion = 0
		var j = main.jugadores.get_node(str(multiplayer.get_unique_id()))
		j.position = origen + Vector2(0 if multiplayer.is_server() else 30, 0)
		j.velocity = Vector2.ZERO
		j.altura = 0.0
		j._vel_altura = 0.0
		j._volando = false
		j._aturdido = 0.0


	@rpc("authority", "reliable")
	func _orden(accion: String) -> void:
		var j = main.jugadores.get_node(str(multiplayer.get_unique_id()))
		match accion:
			"alterar_vida":
				j.vida = 999
			"rafaga":
				j.golpear.rpc_id(1, -1)
				j.golpear.rpc_id(1, -1)
			"beber_doble":
				j.pedir_beber.rpc_id(1)
				j.pedir_beber.rpc_id(1)
			"rodar":
				j.pedir_rodar.rpc_id(1, Vector2.RIGHT)
			"acciones_caido":
				j.pedir_beber.rpc_id(1)
				j.pedir_rodar.rpc_id(1, Vector2.RIGHT)
			"informar":
				_informar.rpc_id(1, {"vida": j.vida, "posicion": j.position,
					"altura": j.altura, "aturdido": j._aturdido,
					"caido": j.caido, "borrachera": j.borrachera,
					"charcos": get_tree().get_nodes_in_group("charcos").size(),
					"finalizada": main.juego.get_node("Partida").finalizada,
					"victoria": main.juego.get_node("Partida").victoria,
					"resultados": main.juego.get_node("Partida").resultados.size(),
					"portador": main.juego.get_node("Mundo/Miel").portador})


	@rpc("any_peer", "reliable")
	func _informar(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos


	@rpc("authority", "call_local", "reliable")
	func _finalizar(codigo: int) -> void:
		get_tree().quit(0 if codigo == 0 else 1)
