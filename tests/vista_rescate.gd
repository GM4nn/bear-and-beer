extends SceneTree
## Capturas del rescate de los oseznos (con ventana): user://rescate_*.png


func _initialize() -> void:
	call_deferred("_abrir")


func _captura(nombre: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var ruta := "user://rescate_%s.png" % nombre
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
	var r = root.get_tree().get_first_node_in_group("rescate_oseznos")
	r.set_physics_process(false)
	j.set_physics_process(false)
	j.position = r.lugar()
	await create_timer(0.6).timeout
	r.cebo = true
	await _captura("arbol")
	r.participantes = [1]
	r.estado = "equilibrio"
	r.equilibrio = 0.7
	r.miedo = 0.4
	await _captura("tambalea")
	r.miedo = 0.8
	await _captura("miedo")
	r.estado = "regreso"
	r.tiempo = 0.1
	r.origen_salto = r.posicion_cria()
	r.mensaje = "¡Se asustó! Volvió a la rama"
	await _captura("rasguno")
	quit()
