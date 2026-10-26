extends SceneTree
## Demo manual: humano y dos bots junto al árbol, con la miel preparada.
## --script tests/jugar_rescate.gd -- --puerto=7946


func _initialize() -> void:
	call_deferred("_abrir")


func _abrir() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = true
	main.probar_torre_con_bots = true
	main.cantidad_bots = 2
	root.add_child(main)
	var red = root.get_node("Red")
	main._crear_partida()
	red.pedir_listo(true)
	for intento in 150:
		if red.jugadores.size() == 3 and red.todos_listos():
			break
		await create_timer(0.2).timeout
	if red.jugadores.size() != 3 or not red.todos_listos():
		push_error("No se conectaron los dos bots de rescate.")
		main._quitar_bot_de_ayuda()
		quit(1)
		return
	red.iniciar_partida()
	for intento in 100:
		if main.jugadores.get_child_count() == 3:
			break
		await create_timer(0.1).timeout
	if main.jugadores.get_child_count() != 3:
		push_error("No aparecieron los tres jugadores.")
		main._quitar_bot_de_ayuda()
		quit(1)
		return
	var r: Node = main.juego.get_node("Partida").rescate
	# Aislar este ensayo de los enemigos sin modificar la partida normal.
	for enjambre in get_nodes_in_group("enjambres"):
		enjambre.set_physics_process(false)
	main.jefe.set_physics_process(false)
	r.cebo = true
	main.juego.get_node("Mundo/Miel").soltar(r.lugar() + Vector2(-80, 20))
	var humano: Node = main.jugadores.get_node("1")
	humano._reaparecer.rpc(r.lugar())
	var numero := 0
	for compa in main.jugadores.get_children():
		if compa == humano:
			continue
		compa._reaparecer.rpc(r.lugar() + Vector2(100 + numero * 30, 0))
		numero += 1
	print("DEMO RESCATE: miel preparada, dos bots conectados; esperan tu E.")
	for intento in 200:
		await create_timer(0.1).timeout
		if humano._torre()._cadena(humano).size() == 3:
			print("PRUEBA LISTA: torre de tres. Pulsa E y sigue los objetivos manteniendo clic izquierdo.")
			return
	print("DEMO RESCATE: acércate a la zona de captura del árbol para que los bots se monten.")
