extends SceneTree
## Muestra la ultra fase de Mamá Osa con contactos y daño:
## --script tests/vista_osa_ultra.gd   (con ventana; guarda user://ultra_*.png)
## Con -- --largo se repite sin fin (garras seguidas y al azar) hasta cerrar la ventana.
## Con -- --jugable abre la pelea real en ultra fase, pausada hasta pulsar Esc.

var _n := 0


func _initialize() -> void:
	call_deferred("_abrir")


func _captura(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := "user://ultra_mecanicas_%d_%s.png" % [_n, nombre]
	_n += 1
	root.get_texture().get_image().save_png(ruta)
	print("CAPTURA ", ProjectSettings.globalize_path(ruta))


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
	jugador._reaparecer.rpc(Vector2(2000, 560))
	await create_timer(0.6).timeout
	var ultra = main.jefe.ultra
	if "--jugable" in OS.get_cmdline_user_args():
		jugador._reaparecer.rpc(Vector2(5300, 350))
		jugador.botellas = 6
		jugador.cervezas = 6
		main.jefe.activa = true
		main.jefe.fase = 3
		main.jefe.vida_max = 300
		main.jefe.vida = 0
		main.jefe._agotar_vida()
		await process_frame
		main._pedir_pausa(true)
		print("ULTRA JUGABLE LISTA: Esc para comenzar; 100 de vida, 6 botellas y 6 chelas.")
		return
	if "--largo" in OS.get_cmdline_user_args():
		await _largo(ultra, jugador)
		return
	ultra.asomarse()
	await create_timer(0.6).timeout
	await _captura("subiendo")
	await create_timer(1.2).timeout
	await _captura("asomada")
	ultra.mirar(-1)
	await create_timer(0.5).timeout
	await _captura("mira_izq")
	ultra.rugir()
	await create_timer(0.3).timeout
	await _captura("ruge")
	await create_timer(1.1).timeout
	ultra.garra(1700, 600, 1)
	await create_timer(0.62).timeout
	await _captura("garra_izq")
	await create_timer(0.8).timeout
	ultra.mirar(1)
	await create_timer(0.4).timeout
	ultra.rugir()
	await create_timer(1.3).timeout
	ultra.garra(2300, 600, -1)
	await create_timer(0.75).timeout
	await _captura("garra_der")
	await create_timer(1.0).timeout
	ultra.mirar(0)
	await create_timer(1.0).timeout
	await ultra.esconderse()
	for lugar in [1, -1]:
		await ultra.asomarse(1.2, lugar)
		await _captura("lado_%d" % lugar)
		ultra.rugir()
		await create_timer(0.6).timeout
		await _captura("lado_ruge_%d" % lugar)
		await create_timer(1.0).timeout
		ultra.barrer(560)
		await create_timer(0.5).timeout
		await _captura("lado_barre_%d" % lugar)
		await create_timer(1.0).timeout
		await ultra.esconderse()
	quit()


# Ronda tras ronda: se asoma, voltea, ruge y lanza garras alrededor del jugador.
func _largo(ultra, jugador) -> void:
	var vuelta := 0
	while true:
		# Se asoma por la izquierda, por la derecha y al centro, por turnos.
		var lugar: int = [-1, 1, 0][vuelta % 3]
		vuelta += 1
		if lugar != 0:
			await ultra.asomarse(1.4, lugar)
			await create_timer(0.8).timeout
			for ronda in 2:
				await ultra.rugir()
				for golpe in randi_range(2, 4):
					var y: float = clampf(jugador.global_position.y + randf_range(-50, 50), 360, 690)
					ultra.barrer(y)
					await create_timer(randf_range(0.7, 1.1)).timeout
				await create_timer(1.0).timeout
			await ultra.esconderse()
			await create_timer(1.5).timeout
			continue
		await ultra.asomarse()
		await create_timer(1.2).timeout
		for ronda in 3:
			var lado: int = [-1, 1][ronda % 2]
			ultra.mirar(lado)
			await create_timer(0.6).timeout
			await ultra.rugir()
			# Varias garras seguidas del lado al que mira, rasguñando hacia el centro.
			for golpe in randi_range(2, 4):
				var x: float = jugador.global_position.x + lado * randf_range(120, 480)
				var y: float = clampf(jugador.global_position.y + randf_range(-40, 60), 360, 690)
				ultra.garra(x, y, -lado)
				await create_timer(randf_range(0.5, 0.9)).timeout
			await create_timer(1.0).timeout
			ultra.mirar(0)
			await create_timer(1.5).timeout
		# Ataque doble: una garra de cada lado a la vez.
		ultra.mirar(0)
		await ultra.rugir()
		ultra.garra(jugador.global_position.x - 260, jugador.global_position.y, 1)
		ultra.garra(jugador.global_position.x + 260, jugador.global_position.y, -1)
		await create_timer(2.0).timeout
		await ultra.esconderse()
		await create_timer(2.0).timeout
