extends SceneTree
## Capturas del mapa en varios puntos (con ventana): user://mapa_<x>.png
## Uso: --script tests/vista_mapa.gd -- 800 2400 6900


func _initialize() -> void:
	call_deferred("_abrir")


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
	var jugador = main.jugadores.get_node("1")
	var puntos := []
	for arg in OS.get_cmdline_user_args():
		if arg.is_valid_float():
			puntos.append(float(arg))
	if puntos.is_empty():
		puntos = [700.0, 2200.0, 3700.0, 5200.0, 6900.0]
	for x in puntos:
		jugador._reaparecer.rpc(Vector2(x, 600))
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		var ruta := "user://mapa_%d.png" % int(x)
		root.get_texture().get_image().save_png(ruta)
		print("CAPTURA ", ProjectSettings.globalize_path(ruta))
	quit()
