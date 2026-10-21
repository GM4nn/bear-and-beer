extends SceneTree
## Revisión visual reproducible; no altera sprites ni lógica de partida.
## --capturas guarda varios momentos del fondo y una vista del menú completo.


func _initialize() -> void:
	call_deferred("_revisar")


func _revisar() -> void:
	var main: Node = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	await create_timer(0.5).timeout
	if not "--capturas" in OS.get_cmdline_user_args():
		return
	var fondo: TextureRect = main._fondo_menu
	fondo.set_process(false)
	for segundo in [0.0, 1.6, 2.4, 3.6, 5.2, 6.6, 18.0, 35.0]:
		fondo._tiempo = segundo
		fondo._material.set_shader_parameter("tiempo", segundo)
		fondo._personajes.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://fondo_menu_%s.png" % str(segundo).replace(".", "_"))
	# El menú normal conserva el letrero. Solo esta captura lo oculta para revisar
	# el agua y los personajes que quedan detrás, sin cambiar su composición.
	main.get_node("UI/Menu").hide()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://fondo_menu_sin_letrero.png")
	print("FONDO MENU: capturas terminadas")
	quit()
