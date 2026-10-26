extends SceneTree
## Demo manual: humano + dos bots, rescate/fuego listos, junto a la tienda.
func _initialize() -> void:
	call_deferred("_abrir")

func _abrir() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = true
	main.probar_torre_con_bots = false
	main.cantidad_bots = 2
	root.add_child(main)
	var red := root.get_node("Red")
	main._crear_partida()
	red.pedir_listo(true)
	for intento in 200:
		await create_timer(0.1).timeout
		if red.jugadores.size() == 3 and red.todos_listos():
			break
	if red.jugadores.size() != 3:
		main._quitar_bot_de_ayuda()
		quit(1)
		return
	red.iniciar_partida()
	for intento in 100:
		await create_timer(0.1).timeout
		if main.jugadores.get_child_count() == 3:
			break
	if main.jugadores.get_child_count() != 3:
		main._quitar_bot_de_ayuda()
		quit(1)
		return
	var partida: Node = main.juego.get_node("Partida")
	partida.rescate.rescatados = 2
	main.estacion.fogata.encendida = true
	main.estacion.fogata._publicar()
	main.jefe.set_physics_process(false)
	for e in get_nodes_in_group("enjambres"):
		e.set_physics_process(false)
	var i := 0
	for j in main.jugadores.get_children():
		j._reaparecer.rpc(partida.busqueda_olla.lugar() + Vector2((i - 1) * 40, 30))
		i += 1
	print("PRUEBA OLLA LISTA: pulsa E junto a la tienda. Cada compa tiene sus propias manos.")
	if "--auto-prueba" in OS.get_cmdline_user_args():
		main.jugadores.get_node("1")._bot = "mision"
		for intento in 900:
			await create_timer(0.1).timeout
			if intento % 100 == 0:
				print("BOTS OLLA: ", partida.busqueda_olla.estado, " dentro=", partida.busqueda_olla.participantes.size(), " aportes=", partida.busqueda_olla.aportes)
			if partida.busqueda_olla.conseguida:
				print("RESULTADO BOTS OLLA: todos entraron y sacaron la olla")
				main._quitar_bot_de_ayuda()
				quit(0)
				return
		push_error("Los bots no terminaron la búsqueda de la olla")
		main._quitar_bot_de_ayuda()
		quit(1)
