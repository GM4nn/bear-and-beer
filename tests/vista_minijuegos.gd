extends SceneTree
## Capturas del reto del rescate y de la búsqueda de la olla (con ventana):
## user://mini_*.png


func _initialize() -> void:
	call_deferred("_abrir")


func _captura(nombre: String) -> void:
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var ruta := "user://mini_%s.png" % nombre
	root.get_texture().get_image().save_png(ruta)
	print("CAPTURA ", ProjectSettings.globalize_path(ruta))


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
	var partida = main.juego.get_node("Partida")
	var r = partida.rescate
	for e in get_nodes_in_group("enjambres"):
		e.set_physics_process(false)
	main.jefe.set_physics_process(false)
	j._reaparecer.rpc(r.lugar())
	await create_timer(0.5).timeout
	await _captura("arbol")
	r.cebo = true
	await _captura("arbol_cebo")
	r.cebo = false
	r.set_physics_process(false)
	r.reto.set_physics_process(false)
	r.participantes = [1]
	r.torre_ids = [1]
	r.avances = [0.4, 0.0, 0.0]
	r.reto.iniciar()
	r.estado = "ritmo"
	r.paso = 1
	r.tiempo = 1.4
	await _captura("rescate")
	r.estado = "esperando"
	r.participantes = []
	r.torre_ids = []
	var b = partida.busqueda_olla
	b.set_physics_process(false)
	b.participantes = [1]
	b.manos[1] = {"pos": Vector2(560, 470), "objeto": -1, "dolor": 0.0, "offset": Vector2.ZERO}
	b._empezar()
	await _captura("olla")
	quit()
