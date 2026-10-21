extends SceneTree
## Capturas de todas las pantallas con el tema de cantina (con ventana):
##   godot --path . --resolution 1280x720 --script tests/vista_ui.gd -- --puerto=17897
## Guarda user://ui_<pantalla>.png. No hace comprobaciones, solo fotos para revisar.
var main: Node


func _initialize() -> void:
	call_deferred("_recorrer")


func _esperar(t: float) -> void:
	await create_timer(t).timeout


func _foto(nombre: String) -> void:
	await _esperar(0.3)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("user://ui_%s.png" % nombre)
	print("FOTO ", ProjectSettings.globalize_path("user://ui_%s.png" % nombre))


func _recorrer() -> void:
	main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	await _esperar(0.5)
	await _foto("menu")
	main._mostrar("unirse")
	await _foto("unirse")
	main._mostrar("opciones")
	await _foto("opciones")
	main._mostrar("menu")
	main.campo_nombre.text = "Germán"
	main._crear_partida()
	await _esperar(0.5)
	await _foto("sala")
	var red = root.get_node("Red")
	for datos in red.jugadores.values():
		datos.listo = true
	red.iniciar_partida()
	await _esperar(1.0)
	var j = main.jugadores.get_child(0)
	j.vida = 72
	j.cervezas = 3
	j.botellas = 2
	j.borrachera = 40
	main.jefe.activa = true
	main.jefe.vida_max = 1000
	main.jefe.vida = 600
	main.jefe.set_physics_process(false)
	await _foto("juego")
	main._cambiar_pausa(true, 1)
	await _foto("pausa")
	main._cambiar_pausa(false, 1)
	await _esperar(0.3)
	var filas := [{"nombre": "Germán", "fuego_amigo": 12, "vuelo": 340, "cervezas": 3, "vomitos": 1,
		"dormidas": 0, "dano_jefe": 420, "rescates": 2},
		{"nombre": "Compa", "fuego_amigo": 30, "vuelo": 0, "cervezas": 5, "vomitos": 2,
		"dormidas": 1, "dano_jefe": 180, "rescates": 0}]
	main.hud.mostrar_resultados(true, filas)
	await _foto("resultados")
	quit(0)
