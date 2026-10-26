extends SceneTree
## Capturas de los cambios de las notas de los amigos (con ventana):
## user://nota_*.png — cargar la olla caminando, tomar caminando, aguijón y tienda.


func _initialize() -> void:
	call_deferred("_abrir")


func _captura(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := "user://nota_%s.png" % nombre
	root.get_texture().get_image().save_png(ruta)
	print("CAPTURA ", ProjectSettings.globalize_path(ruta))


## Aprieta "derecha" un rato: el juego mide la velocidad real.
func _caminar(j: Node2D, segundos: float) -> void:
	var antes := j.position
	# Sin teclado ni control reales que suelten la acción simulada.
	for accion in ["izquierda", "derecha", "arriba", "abajo"]:
		InputMap.action_erase_events(accion)
	Input.action_press("derecha")
	await create_timer(segundos).timeout
	print("MOVIO ", j.position - antes, " anim=", j._animacion)
	Input.action_release("derecha")


func _abrir() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	var red = root.get_node("Red")
	main._crear_partida()
	await create_timer(0.4).timeout
	red.pedir_listo(true)
	red.iniciar_partida()
	while main.jugadores.get_node_or_null("1") == null:
		await process_frame
	await create_timer(0.8).timeout
	var j = main.jugadores.get_node("1")
	for e in get_nodes_in_group("enjambres"):
		e.set_physics_process(false)
	main.jefe.set_physics_process(false)
	var carpa: Node2D = main.juego.get_node("Mundo/Carpa")
	j._reaparecer.rpc(carpa.position + Vector2(260, 130))
	await create_timer(0.5).timeout
	# Cargando una pieza (la leña sirve igual que la olla).
	var pieza: Node2D = null
	for p in get_nodes_in_group("piezas"):
		if p.disponible():
			pieza = p
			break
	if pieza:
		pieza.agarrar(1)
	await _caminar(j, 0.6)
	await _captura("cargar_caminando")
	await create_timer(0.6).timeout
	await _captura("cargar_quieto")
	if pieza:
		pieza.soltar(j.position + Vector2(-120, 0))
	await create_timer(0.3).timeout
	# Tomando mientras camina.
	j.cervezas = 3
	j.pedir_beber()
	await _caminar(j, 0.9)
	await _captura("tomar_caminando")
	await create_timer(1.5).timeout
	# Con el aguijón: quieto y pegando.
	j.arma_tiempo = 20.0
	await create_timer(0.4).timeout
	await _captura("aguijon_quieto")
	j.golpear(1, 0)
	await create_timer(0.12).timeout
	await _captura("aguijon_golpe")
	quit()
