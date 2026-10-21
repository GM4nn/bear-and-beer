extends SceneTree
## Demo de un jugador: -- --host --puerto=17940. Solo esta demo fuerza la fusión.
## --capturas inspecciona automáticamente fusión y ambos lados del forcejeo.
var main: Node


func _initialize() -> void:
	call_deferred("_abrir")


func _abrir() -> void:
	var fotos := "--capturas" in OS.get_cmdline_user_args()
	if fotos:
		for accion in InputMap.get_actions():
			InputMap.action_erase_events(accion)
			Input.action_release(accion)
	main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	var red := root.get_node("Red")
	red.pedir_listo(true)
	red.iniciar_partida()
	await create_timer(0.3).timeout
	main.jefe.set_physics_process(false)
	var j: Node2D = main.jugadores.get_node("1")
	j._reaparecer.rpc(Vector2(2300, 520))
	var abeja: Node2D = main.juego.get_node("Partida").abeja_musculosa
	while is_instance_valid(abeja):
		j.vida = 100
		j.proteccion = 0
		j.aturdimiento = 0
		j._reaparecer.rpc(Vector2(2300, 520))
		var centro := j.position + Vector2(240, 0)
		abeja._fusionar.rpc(PackedVector2Array([centro + Vector2(-40, 0), centro + Vector2(30, 25), centro]), abeja.encuentro + 1)
		if fotos:
			await create_timer(0.8).timeout
			await _foto("fusion")
			await create_timer(1.4).timeout
			await _foto("caminar")
			for i in 300:
				if abeja.estado == "golpeando":
					break
				await physics_frame
			await create_timer(0.32).timeout
			await _foto("golpear")
			for i in 300:
				if abeja.estado == "forcejeo":
					break
				await physics_frame
			# Congelar la lógica, no la animación, para revisar varios cuadros sin perder.
			abeja.set_physics_process(false)
			for i in 4:
				await create_timer(0.13).timeout
				await _foto("agarre_%d" % i)
			abeja._trabar.rpc(1, j.position - Vector2(abeja.SEPARACION, 0), -1)
			await create_timer(0.3).timeout
			await _foto("izquierda")
			quit()
			return
		while abeja.estado != "inactiva":
			await create_timer(0.2).timeout
		await create_timer(2).timeout


func _foto(nombre_foto: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := "user://vista_abejas_%s.png" % nombre_foto
	root.get_texture().get_image().save_png(ruta)
	print(ProjectSettings.globalize_path(ruta))
