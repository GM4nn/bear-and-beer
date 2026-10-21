extends SceneTree
## Capturas de Mamá Osa junto al jugador, en varias posturas y fases:
## --script tests/vista_osa.gd   (con ventana; guarda user://osa_*.png)


func _initialize() -> void:
	call_deferred("_abrir")


func _abrir() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	var red = root.get_node("Red")
	main._crear_partida()
	await create_timer(0.5).timeout
	red.pedir_listo(true)
	red.iniciar_partida()
	while main.jugadores.get_node_or_null("1") == null:
		await process_frame
	await create_timer(0.8).timeout
	var jugador = main.jugadores.get_node("1")
	jugador._reaparecer.rpc(Vector2(5600, 560))
	await create_timer(0.5).timeout
	var jefe = main.jefe
	jefe.set_physics_process(false)
	jefe.activa = true
	jefe.vida_max = 1000
	jefe.vida = 1000
	jefe.position = Vector2(5820, 560)
	jefe.mirando = -1
	for toma in [["quieta", 1, "pausa"], ["zarpazo", 1, "zarpazo"], ["rugido", 2, "rugido"], ["mareada", 3, "tambaleando"]]:
		jefe.fase = toma[1]
		jefe.estado = toma[2]
		await create_timer(0.35).timeout
		await RenderingServer.frame_post_draw
		var ruta := "user://osa_%s.png" % toma[0]
		root.get_texture().get_image().save_png(ruta)
		print("CAPTURA ", ProjectSettings.globalize_path(ruta))
	quit()
