extends SceneTree
## Un bot de misión con el lago en medio debe rodearlo, no quedarse nadando.
## --headless --script tests/bot_lago.gd -- --host --bot-mision


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
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
	var bot = main.jugadores.get_node("1")
	var bosque = root.get_tree().get_first_node_in_group("bosque")
	var miel: Node2D = null
	for p in root.get_tree().get_nodes_in_group("piezas"):
		if p.tipo == "miel":
			miel = p
	for abeja in root.get_tree().get_nodes_in_group("enjambres"):
		abeja.set_physics_process(false)
	var c: Vector2 = bosque._centro_lago
	var r: Vector2 = bosque._radio_lago
	var fallos := 0
	for caso in [[Vector2(c.x - r.x - 150, c.y), Vector2(c.x + r.x + 150, c.y)], [Vector2(c.x + r.x + 150, c.y + 20), Vector2(c.x - r.x - 150, c.y - 20)], [Vector2(c.x, c.y), Vector2(c.x + r.x + 200, c.y + 120)],
			# Objetivo pegado a la orilla y en la playita (antes se atoraba yendo y viniendo).
			[Vector2(c.x - r.x - 250, c.y - 60), Vector2(c.x + 150, c.y - r.y - 12)],
			[Vector2(c.x + r.x + 250, c.y + 90), Vector2(c.x - r.x - 15, c.y)],
			[Vector2(c.x - r.x - 300, c.y + 120), Vector2(c.x + 60, c.y + r.y + 15)]]:
		bot._reaparecer.rpc(caso[0])
		miel.position = caso[1]
		await create_timer(0.3).timeout
		var en_agua := 0.0
		var peor := 0.0
		var llego := false
		for i in 400:
			await create_timer(0.05).timeout
			if bot.nadando():
				en_agua += 0.05
				peor = maxf(peor, en_agua)
			else:
				en_agua = 0.0
			if bot.position.distance_to(miel.position) < 40 or miel.portador != 0:
				llego = true
				break
		var ok := llego and peor < 3.0
		if not ok:
			fallos += 1
		print(("OK" if ok else "FALLO") + ": desde %s llegó=%s, máximo seguido en el agua %.1f s, pos final %s" % [caso[0], llego, peor, bot.position])
		if miel.portador != 0:
			miel.soltar(miel.position)
	# Sin nada que hacer (miel ya ofrecida, nadie en el árbol), no se queda en el agua.
	var rescate = root.get_tree().get_first_node_in_group("rescate_oseznos")
	rescate.cebo = true
	bot._reaparecer.rpc(c + Vector2(-r.x + 60, 0))
	await create_timer(4.0).timeout
	var sale: bool = not bot.nadando()
	if not sale:
		fallos += 1
	print(("OK" if sale else "FALLO") + ": un bot sin tarea sale del agua (pos %s)" % bot.position)
	print("RESULTADO BOT LAGO: %d fallos" % fallos)
	quit(fallos)
