extends SceneTree
## Demo manual: humano + dos bots, etapas anteriores resueltas, junto al lago.
## --reina empieza directamente con el miniboss. --captura verifica vistas y cierra.
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
	var partida: Node = main.juego.get_node("Partida")
	partida.rescate.rescatados = 2
	partida.rescate.cebo = true
	partida.busqueda_olla.conseguida = true
	main.estacion.fogata.encendida = true
	main.estacion.fogata._publicar()
	main.juego.get_node("Mundo/Olla").entregar(main.estacion.position + Vector2(0, 20))
	main.jefe.set_physics_process(false)
	var b: Node = partida.oleadas_miel
	var i := 0
	for j in main.jugadores.get_children():
		j._reaparecer.rpc(b.CENTRO + Vector2((i - 1) * 80, 0))
		i += 1
	print("PRUEBA MIEL LISTA: tres oleadas + reina. H J K L, F parada, R botella; A/D alternadas para soltar miel.")
	if "--reina" in OS.get_cmdline_user_args() or "--captura" in OS.get_cmdline_user_args():
		b._equipo = red.jugadores.keys()
		b.encuentro += 1
		b.iniciar_ola(4)
	if "--auto-prueba" in OS.get_cmdline_user_args():
		b.jugador(1)._bot = "mision"
		for intento in 1500:
			await create_timer(0.1).timeout
			if intento % 100 == 0:
				print("BOTS MIEL: ola=", b.ola, " quedan=", b.restantes(), " vidas=", main.jugadores.get_children().map(func(j): return j.vida))
			if b.completada or partida.finalizada:
				print("RESULTADO BOTS MIEL: ", "victoria" if b.completada else "equipo derrotado")
				main._quitar_bot_de_ayuda()
				quit(0 if b.completada else 1)
				return
		push_error("Los bots no terminaron las oleadas dentro de 150 segundos")
		main._quitar_bot_de_ayuda()
		quit(1)
		return
	if "--captura" in OS.get_cmdline_user_args():
		var e: Node2D = b.enemigos[0]
		e.set_physics_process(false)
		b.set_physics_process(false)
		e.position = b.CENTRO + Vector2(190, 0)
		e.mirando = -1
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://miel_reina.png")
		e._iniciar("vuelo", b.CENTRO - Vector2(90, 0))
		e.tiempo = 1.0
		e.vuelo = 180
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://miel_vuelo.png")
		e._descansar(0)
		b.empapar(b.jugador(1))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://miel_empapado.png")
		main._quitar_bot_de_ayuda()
		quit(0)
