extends SceneTree
## Host + dos clientes reales --bot-torre --bot-turno=1/2. --demo abre la prueba jugable.
var main: Node
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _esperar(t: float) -> void:
	await create_timer(t).timeout


func _comprobar(ok: bool, texto: String) -> void:
	print(("OK: " if ok else "FALLO: ") + texto)
	if not ok:
		fallos += 1


func _torre_lista() -> bool:
	var base = main.jugadores.get_node_or_null("1")
	return base != null and base._torre()._cadena(base).size() == 3


func _esperar_torre() -> void:
	for intento in range(100):
		if _torre_lista():
			return
		await _esperar(0.1)


func _probar() -> void:
	var demo := "--demo" in OS.get_cmdline_user_args()
	main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = demo
	root.add_child(main)
	var red = root.get_node("Red")
	for intento in range(200):
		if red.jugadores.size() == 3:
			break
		await _esperar(0.1)
	if red.jugadores.size() != 3:
		push_error("No se conectaron los dos bots")
		quit(1)
		return
	for datos in red.jugadores.values():
		datos.listo = true
	red.iniciar_partida()
	await _esperar(0.5)
	await _esperar_torre()
	_comprobar(_torre_lista(), "Los dos bots se acercan, saltan y forman la torre sin órdenes manuales")
	if not _torre_lista():
		quit(1)
		return
	var j = main.jugadores.get_node("1")
	var jefe = main.jefe
	jefe.set_physics_process(false)
	jefe.activa = true
	jefe.estado = "persiguiendo"
	jefe.vida = 5000 if demo else 1000
	jefe.vida_max = jefe.vida
	jefe.position = j.position + Vector2(80 if demo else 40, 0)
	if demo:
		var instrucciones := Label.new()
		instrucciones.text = "PRUEBA: acércate a Mamá Osa y pulsa J. Los bots pegan contigo. E los suelta; vuelven a subir solos."
		instrucciones.position = Vector2(16, 260)
		instrucciones.add_theme_color_override("font_outline_color", Color.BLACK)
		instrucciones.add_theme_constant_override("outline_size", 4)
		main.get_node("UI").add_child(instrucciones)
		print("DEMO LISTA: dos bots en hombros; Mamá Osa inmóvil para practicar críticos")
		return
	await _esperar(0.4)
	_comprobar(jefe.vida == 1000, "Los bots esperan tu golpe y no atacan solos")
	Input.action_press("golpear")
	await _esperar(0.55)
	Input.action_release("golpear")
	_comprobar(jefe.vida == 940 and j._torre().criticos == 1,
		"Ambos bots detectan un golpe del anfitrión y completan el crítico una sola vez")
	await _esperar(0.3)
	Input.action_press("golpear")
	await _esperar(0.05)
	Input.action_release("golpear")
	await _esperar(0.4)
	_comprobar(jefe.vida == 880 and j._torre().criticos == 2, "El siguiente golpe vuelve a coordinar a los dos bots")
	Input.action_press("izquierda")
	await _esperar(0.06)
	Input.action_release("izquierda")
	await _esperar(0.15)
	jefe.position = j.position - Vector2(40, 0)
	Input.action_press("golpear")
	await _esperar(0.04)
	Input.action_release("golpear")
	await _esperar(0.4)
	_comprobar(jefe.vida == 820 and j._torre().criticos == 3, "Los bots también acompañan el golpe hacia la izquierda")
	Input.action_press("agarrar")
	await _esperar(0.04)
	Input.action_release("agarrar")
	await _esperar(0.2)
	_comprobar(j._torre().encima(j) == null, "E suelta a ambos bots y respetan una pausa antes de volver")
	await _esperar_torre()
	_comprobar(_torre_lista(), "Los bots vuelven a formar la torre después de soltarlos")
	if not _torre_lista():
		for compa in main.jugadores.get_children():
			print("ESTADO BOT ", compa.nombre, " posición ", compa.position, " altura ", compa.altura, " apoyo ", compa.apoyo_id)
	Input.action_press("derecha")
	await _esperar(0.3)
	Input.action_release("derecha")
	await _esperar(0.2)
	_comprobar(_torre_lista(), "La torre de bots sigue al anfitrión mientras camina")
	print("RESULTADO BOTS TORRE: %d fallos" % fallos)
	quit(0 if fallos == 0 else 1)
