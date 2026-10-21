extends SceneTree
## Dos instancias --host/--join con --auto. El host puede usar --captura con ventana.

func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaArco"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var informe: Dictionary = {}


	func _ready() -> void:
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
		var j = main.jugadores.get_node("1")
		var otro = main.jugadores.get_node(str(cliente))
		var partida = main.juego.get_node("Partida")
		j._reaparecer.rpc(Vector2(2300, 520))
		otro._reaparecer.rpc(Vector2(2450, 520))
		j.botellas = 3
		await _esperar(0.3)
		Input.action_press("lanzar")
		await _esperar(0.15)
		_comprobar(j._apuntando_botella and j.botellas == 3 and partida._numero_botella == 0,
			"Mantener F muestra la guía y no gasta una botella")
		await _esperar(1.2)
		_comprobar(is_equal_approx(j._carga_botella, 1.0), "La fuerza se limita al 100%")
		if "--captura" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://botella_trayectoria.png")
		Input.action_release("lanzar")
		await _esperar(0.2)
		var b = main.juego.get_node("Mundo/Botella1")
		_comprobar(j.botellas == 2 and b.fuerza == 1.0 and b.altura > 70,
			"Soltar F lanza una sola botella que sube en un arco alto")
		_consultar.rpc_id(cliente)
		await _esperar(0.1)
		_comprobar(informe.get("fuerza", -1) == 1.0 and informe.get("alto", 0) > 70,
			"El cliente recibe la fuerza y ve el mismo arco alto")
		await _esperar(0.5)
		var antes: float = b.altura
		await _esperar(0.1)
		_comprobar(b.altura < antes, "La botella desciende después de pasar el punto más alto")
		await _esperar(0.5)
		_comprobar(otro.vida == 100 and not main.juego.get_node("Mundo").has_node("Botella1"),
			"El tiro alto pasa por encima del compañero cercano y se rompe al caer")
		Input.action_press("lanzar")
		await _esperar(0.02)
		Input.action_release("lanzar")
		await _esperar(0.9)
		_comprobar(otro.vida == 88 and j.botellas == 1, "Un toque corto cae cerca y sí alcanza al compañero")
		Input.action_press("lanzar")
		await _esperar(0.25)
		j.recibir_golpe(-1, 1, 0.1)
		await _esperar(0.1)
		Input.action_release("lanzar")
		await _esperar(0.1)
		_comprobar(not j._apuntando_botella and j.botellas == 1 and partida._numero_botella == 2,
			"Recibir un golpe cancela el apuntado sin gastar la botella")
		otro.botellas = 1
		otro.pedir_lanzar(NAN)
		_comprobar(otro.botellas == 1 and partida._numero_botella == 2, "El servidor rechaza una fuerza no válida")
		await _esperar(0.5)
		_cargar_cliente.rpc_id(cliente)
		await _esperar(0.9)
		var remota = main.juego.get_node("Mundo").get_node_or_null("Botella3")
		_comprobar(remota != null and remota.fuerza > 0.45 and remota.fuerza < 0.65 and otro.botellas == 0,
			"Un cliente también carga y lanza; el servidor descuenta su botella")
		print("RESULTADO ARCO: %d fallos" % fallos)
		_finalizar.rpc()


	func _esperar(t: float) -> void:
		await get_tree().create_timer(t).timeout


	func _comprobar(ok: bool, texto: String) -> void:
		print(("OK: " if ok else "FALLO: ") + texto)
		if not ok:
			fallos += 1


	@rpc("authority", "reliable")
	func _cargar_cliente() -> void:
		Input.action_press("lanzar")
		await _esperar(0.65)
		Input.action_release("lanzar")


	@rpc("authority", "reliable")
	func _consultar() -> void:
		var botella = main.juego.get_node("Mundo").get_node_or_null("Botella1")
		_datos.rpc_id(1, {"fuerza": botella.fuerza if botella else -1, "alto": botella.altura if botella else -1})


	@rpc("any_peer", "reliable")
	func _datos(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos


	@rpc("authority", "call_local", "reliable")
	func _finalizar() -> void:
		get_tree().quit(0 if fallos == 0 else 1)
