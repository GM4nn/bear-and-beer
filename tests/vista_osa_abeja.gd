extends SceneTree
## Captura del forcejeo entre Mamá Osa y la abeja musculosa:
## --script tests/vista_osa_abeja.gd   (con ventana; guarda user://osa_abeja_*.png)


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
	main.jugadores.get_node("1")._reaparecer.rpc(Vector2(5450, 600))
	await create_timer(0.5).timeout
	var jefe = main.jefe
	var abeja: Node2D = root.get_tree().get_first_node_in_group("abeja_musculosa")
	jefe.set_physics_process(false)
	abeja.set_physics_process(false)
	jefe.activa = true
	jefe.position = Vector2(5700, 560)
	jefe.mirando = 1
	jefe.estado = "rivalidad"
	abeja.lado = 1
	abeja.estado = "forcejeo_osa"
	abeja.fuerza = 0.5
	abeja.position = jefe.position + Vector2(abeja.DISTANCIA_FORCEJEO_OSA, 0)
	# Dura un rato para escuchar el gruñido y el zumbido.
	for i in 3:
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var ruta := "user://osa_abeja_%d.png" % i
		root.get_texture().get_image().save_png(ruta)
		print("CAPTURA ", ProjectSettings.globalize_path(ruta))
	await create_timer(12.0).timeout
	quit()
