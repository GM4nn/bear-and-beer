extends SceneTree
## Mismos argumentos host/join que combate_red.gd. No inyecta inventario ni borrachera.


func _initialize() -> void:
	var prueba := Recorrido.new()
	prueba.name = "RecorridoCerveza"
	root.add_child.call_deferred(prueba)


class Recorrido extends Node:
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
		var jugador = main.jugadores.get_node(str(cliente))
		var partida = main.juego.get_node("Partida")
		await get_tree().create_timer(0.3).timeout
		_comprobar(jugador.cervezas == 0 and jugador.borrachera == 0, "Empieza sobrio y sin inventario")
		for i in 6:
			await _orden("recoger", partida.SUMINISTROS[i])
		_comprobar(jugador.cervezas == 6 and informe.cervezas == 6, "E recoge un six-pack en ambas instancias")
		await _orden("recoger", partida.SUMINISTROS[6])
		_comprobar(jugador.cervezas == 6, "El inventario respeta el límite de seis")
		for numero in range(1, 5):
			await _orden("beber")
			_comprobar(jugador.cervezas == 6 - numero and informe.cervezas == 6 - numero,
				"Q termina la cerveza %d y descuenta solo una botella" % numero)
			if numero < 4:
				_comprobar(jugador.nivel_borrachera() == numero and informe.nivel == numero,
					"La cerveza %d alcanza el nivel %d en las dos pantallas" % [numero, numero])
			if numero == 1:
				await get_tree().create_timer(4.0).timeout
				_comprobar(jugador.borrachera == 30, "La borrachera no desaparece mientras buscas más chelas")
		_comprobar(jugador.nausea > 0 and informe.nausea > 0 and informe.charcos == 0,
			"La cuarta cerveza, partiendo de sobrio, da náusea antes de vomitar")
		await _orden("vomitar")
		_comprobar(jugador.vomitando > 0 and informe.vomitando > 0 and informe.charcos == 1,
			"Machacar E con náusea provoca el vómito y el charco")
		_comprobar(partida.estadisticas[cliente].cervezas == 4, "Las estadísticas cuentan cuatro bebidas reales")
		await get_tree().create_timer(3.0).timeout
		await _orden("recoger", partida.SUMINISTROS[6])
		_comprobar(jugador.cervezas == 3 and informe.cervezas == 3, "Puedes reponer el inventario después de beber")
		print("RESULTADO RECORRIDO: %d fallos" % fallos)
		_finalizar.rpc(fallos)


	func _comprobar(condicion: bool, descripcion: String) -> void:
		print("%s: %s" % ["OK" if condicion else "FALLO", descripcion])
		if not condicion:
			fallos += 1


	func _orden(accion: String, sitio := Vector2.ZERO) -> void:
		informe = {}
		_accion.rpc_id(cliente, accion, sitio)
		for intento in range(300):
			await get_tree().process_frame
			if not informe.is_empty():
				return
		push_error("El cliente no respondió")
		get_tree().quit(1)


	@rpc("authority", "reliable")
	func _accion(accion: String, sitio: Vector2) -> void:
		var j = main.jugadores.get_node(str(multiplayer.get_unique_id()))
		if accion == "recoger":
			# Solo acorta el trayecto; recogida y bebida usan las entradas reales.
			j.position = sitio
			await get_tree().create_timer(0.2).timeout
			Input.action_press("agarrar")
			await get_tree().create_timer(0.08).timeout
			Input.action_release("agarrar")
		elif accion == "vomitar":
			for i in j.ARCADAS:
				Input.action_press("agarrar")
				await get_tree().create_timer(0.08).timeout
				Input.action_release("agarrar")
				await get_tree().create_timer(0.08).timeout
		else:
			Input.action_press("beber")
			await get_tree().create_timer(0.08).timeout
			Input.action_release("beber")
			await get_tree().create_timer(2.05).timeout
		await get_tree().create_timer(0.1).timeout
		_informar.rpc_id(1, {"cervezas": j.cervezas, "nivel": j.nivel_borrachera(),
			"vomitando": j.vomitando, "nausea": j.nausea, "charcos": get_tree().get_nodes_in_group("charcos").size()})


	@rpc("any_peer", "reliable")
	func _informar(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos


	@rpc("authority", "call_local", "reliable")
	func _finalizar(codigo: int) -> void:
		get_tree().quit(0 if codigo == 0 else 1)
