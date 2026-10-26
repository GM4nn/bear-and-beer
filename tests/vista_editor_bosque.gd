extends SceneTree
## Muestra escenas/bosque.tscn como la ve el editor (sin correr su lógica):
## --script tests/vista_editor_bosque.gd  (con ventana; guarda user://editor_<x>.png)


func _initialize() -> void:
	call_deferred("_abrir")


func _sin_scripts(nodo: Node) -> void:
	nodo.set_script(null)
	for hijo in nodo.get_children():
		_sin_scripts(hijo)


func _abrir() -> void:
	var bosque: Node2D = load("res://escenas/bosque.tscn").instantiate()
	_sin_scripts(bosque)
	root.add_child(bosque)
	var camara := Camera2D.new()
	bosque.add_child(camara)
	camara.make_current()
	for x in [700, 2300, 3900, 5500, 7000]:
		camara.position = Vector2(x, 420)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var ruta := "user://editor_%d.png" % x
		root.get_texture().get_image().save_png(ruta)
		print("CAPTURA ", ProjectSettings.globalize_path(ruta))
	quit()
