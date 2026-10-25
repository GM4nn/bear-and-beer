extends SceneTree
## Prueba jugable: arranca directo en la ultra fase de Mamá Osa.
## --script tests/jugar_ultra.gd   (con ventana; se juega con los controles normales)


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
	jugador._reaparecer.rpc(Vector2(2200, 560))
	await create_timer(0.5).timeout
	# Saltar las tres fases normales: la osa queda directo en la ultra.
	var jefe = main.jefe
	jefe.activa = true
	jefe.position = Vector2(2500, 560)
	jefe.fase = 3
	jefe.vida_max = jefe.VIDA_BASE
	jefe._agotar_vida()
	print("ULTRA FASE LISTA: vida de la osa ", jefe.vida, "/", jefe.vida_max)
