extends SceneTree
## --host --puerto=17812; --capturas requiere renderizador y guarda las fases.
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _comprobar(valor: bool, texto: String) -> void:
	print(("OK: " if valor else "FALLO: ") + texto)
	if not valor:
		fallos += 1


func _esperar(t: float) -> void:
	await create_timer(t).timeout


func _foto(nombre: String) -> void:
	if "--capturas" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://objetos_%s.png" % nombre)


func _probar() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	var red = root.get_node("Red")
	red.pedir_listo(true)
	red.iniciar_partida()
	await _esperar(0.3)
	var j = main.jugadores.get_node("1")
	var e = main.estacion
	var arte = e.get_node("ArteEstacion")
	main.jefe.set_physics_process(false)
	for cosa in get_nodes_in_group("golpeables"):
		if cosa.get_script() == load("res://scripts/abejas.gd"):
			cosa.set_physics_process(false)
	j._reaparecer.rpc(e.position + Vector2(-65, 10))
	await _esperar(0.7)
	_comprobar(arte.crias[0].animation == "quieto" and arte.crias[0].is_playing(), "Los oseznos esperan animados")
	_comprobar(not e.get_node("Osezno1").visible and not e.get_node("Papilla").visible, "Los cubos de la estación están ocultos")
	await _foto("espera")
	var piezas := get_nodes_in_group("piezas")
	var pieza = piezas[0]
	pieza.agarrar(1)
	await _esperar(0.1)
	_comprobar(pieza.portador == 1 and pieza._sprite.texture != null and not pieza.get_node("Visual/Color").visible,
		"Recoger una pieza muestra su sprite en las manos")
	await _foto("cargando")
	# El encendido se prueba en fogata_red.gd; aquí se revisan los sprites posteriores.
	main.juego.get_node("Partida").rescate.rescatados = 2
	e.fogata.encendida = true
	e.fogata.colocados = 2
	e.fogata._publicar()
	for p in piezas:
		e.intentar_entregar(p, e.position)
	await _esperar(0.1)
	_comprobar(e.completa() and piezas.all(func(p): return not p.visible), "Las piezas entregadas se incorporan a la estación")
	Input.action_press("agarrar")
	await _esperar(0.5)
	_comprobar(e.progreso > 0 and arte.papilla.visible and arte.papilla.is_playing(), "Mantener E cocina y anima el hervido")
	await _foto("cocinando")
	await _esperar(8.0)
	Input.action_release("agarrar")
	_comprobar(e.terminada, "La animación no altera el tiempo de cocinar")
	j._reaparecer.rpc(e.lugar_oseznos() + Vector2(0, 25))
	Input.action_press("agarrar")
	await _esperar(0.4)
	_comprobar(e.alimento > 0 and arte.crias[0].animation == "comer", "Los oseznos comen mientras reciben papilla")
	await _foto("comiendo")
	Input.action_release("agarrar")
	await _esperar(0.35)
	_comprobar(arte.crias[0].animation == "quieto", "Soltar E interrumpe también la animación de comer")
	Input.action_press("agarrar")
	await _esperar(10.5)
	Input.action_release("agarrar")
	_comprobar(e.alimentados and arte.crias[0].animation == "llorar", "Al terminar de comer lloran por su mamá")
	await _foto("llorando")
	e.danar_olla(100)
	await _esperar(0.2)
	_comprobar(arte.rota.visible and not arte.papilla.visible, "Romper la olla cambia su aspecto y detiene el hervido visible")
	await _foto("olla_rota")
	e._llego_furiosa.rpc()
	await _esperar(0.2)
	_comprobar(e.mama_osa.visible and not e.mama_osa.get_node("Cuerpo").visible, "El susto usa el sprite de Mamá Osa")
	await _foto("susto")
	print("RESULTADO OBJETOS: %d fallos" % fallos)
	quit(0 if fallos == 0 else 1)
