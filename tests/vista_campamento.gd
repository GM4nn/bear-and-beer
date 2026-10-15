extends SceneTree
## Abre el campamento sin bot: --script tests/vista_campamento.gd -- --host
## --capturas guarda la sala y cuatro vistas; sin ese argumento queda jugable.


func _initialize() -> void:
	call_deferred("_abrir")


func _abrir() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	var red = root.get_node("Red")
	red.pedir_listo(true)
	if "--capturas" in OS.get_cmdline_user_args():
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://vista_sala.png")
	red.iniciar_partida()
	await create_timer(1.0).timeout
	if "--capturas" not in OS.get_cmdline_user_args():
		return
	var jugador = main.jugadores.get_node("1")
	for vista in [["campamento", Vector2(380, 540)], ["bosque", Vector2(2000, 540)], ["cartel", Vector2(3450, 540)], ["lago", Vector2(5800, 560)]]:
		jugador._reaparecer.rpc(vista[1])
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		var ruta := "user://vista_%s.png" % vista[0]
		var error := root.get_texture().get_image().save_png(ruta)
		print("CAPTURA %s: %s (%d)" % [vista[0], ProjectSettings.globalize_path(ruta), error])
	quit()
