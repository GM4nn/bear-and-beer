extends SceneTree
## Prueba jugable: tú y un bot que hace la misión (palos, fogata, frotar).
## --script tests/jugar_fogata.gd   (con ventana)


func _initialize() -> void:
	call_deferred("_abrir")


func _abrir() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = true
	main.probar_torre_con_bots = false
	main.cantidad_bots = 1
	root.add_child(main)
	var red = root.get_node("Red")
	main._crear_partida()
	# Esperar a que el bot entre a la sala y empezar solos.
	while red.jugadores.size() < 2:
		await create_timer(0.2).timeout
	red.pedir_listo(true)
	await create_timer(0.5).timeout
	red.iniciar_partida()
	main.juego.get_node("Partida").rescate.rescatados = 2
	print("PARTIDA LISTA: tú y 1 bot; rescate previo completado para probar la fogata")
