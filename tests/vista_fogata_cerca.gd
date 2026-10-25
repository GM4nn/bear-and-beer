extends SceneTree
## Capturas del acercamiento para encender la fogata (sin red):
## --script tests/vista_fogata_cerca.gd   (con ventana; guarda user://fogata_cerca_*.png)


func _initialize() -> void:
	call_deferred("_abrir")


func _abrir() -> void:
	var vista = load("res://scripts/fogata_vista.gd")
	var escena = vista.PrimerPlano.new()
	escena.size = Vector2(1280, 720)
	root.add_child(escena)
	escena.colores = [Color("c74327"), Color("367eba")]
	for toma in [["inicio", 0.0, Vector2(-0.8, 0.6)], ["calentando", 0.45, Vector2(0.7, -0.8)], ["fuego", 0.95, Vector2(-0.3, 0.9)]]:
		escena.calor = toma[1]
		escena.gestos = toma[2]
		for i in 20:
			escena.reloj += 0.05
			escena.queue_redraw()
			await process_frame
		await RenderingServer.frame_post_draw
		var ruta := "user://fogata_cerca_%s.png" % toma[0]
		root.get_texture().get_image().save_png(ruta)
		print("CAPTURA ", ProjectSettings.globalize_path(ruta))
	quit()
