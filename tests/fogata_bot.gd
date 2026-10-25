extends SceneTree
## Host de prueba + cliente normal --bot-mision --bot-turno=1 --auto.
var main: Node
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func comprobar(ok: bool, texto: String) -> void:
	if not ok:
		fallos += 1
	print(("OK: " if ok else "FALLO: ") + texto)


func _probar() -> void:
	main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	for intento in range(600):
		await process_frame
		if main.jugadores.get_child_count() == 2:
			break
	if main.jugadores.get_child_count() != 2:
		quit(1)
		return
	var bot: Node2D = main.jugadores.get_node(str(main.multiplayer.get_peers()[0]))
	var j: Node2D = main.jugadores.get_node("1")
	var f: Node2D = main.estacion.fogata
	main.juego.get_node("Partida").rescate.rescatados = 2
	Input.use_accumulated_input = false
	j._reaparecer.rpc(Vector2(5900, 690))
	bot._reaparecer.rpc(Vector2(1300, 620))
	for i in range(180):
		await create_timer(0.1).timeout
		if f.cantidad(bot.name.to_int()) == 2:
			break
	comprobar(f.cantidad(bot.name.to_int()) == 2, "El bot golpea el árbol y recoge los dos palos")
	bot._reaparecer.rpc(Vector2(5855, 680))
	for i in range(50):
		await create_timer(0.1).timeout
		if f.participantes.size() == 1:
			break
	comprobar(f.colocados == 2 and f.participantes == [bot.name.to_int()], "El bot coloca y espera a un humano")
	j.pedir_agarrar()
	await create_timer(2.2).timeout
	for n in range(230):
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = true
		root.push_input(b, true)
		var m := InputEventMouseMotion.new()
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		var signo := 1 if int((f.TIEMPO - f.tiempo) / f.COMPAS) % 2 == 0 else -1
		m.relative = Vector2(-35 * signo, clampf(-float(f.derivas[1]) * 60.0, -15.0, 15.0)) * f.vista.escena.scale.x
		# Coordenadas del viewport: la ventana headless mide 64 px y convertirlas
		# como coordenadas físicas multiplicaba por 20 la corrección vertical.
		root.push_input(m, true)
		await create_timer(0.06).timeout
	comprobar(f.encendida, "El bot frota su eje y permite encender con el jugador")
	if not f.encendida:
		print("Diagnóstico fogata: ", f.mensaje, " calor=", f.calor, " participantes=", f.participantes,
			" ritmo=", f.ritmo, " consejos=", f.consejos, " derivas=", f.derivas, " movimientos=", f._mov)
	print("RESULTADO BOT FOGATA: %d fallos" % fallos)
	quit(0 if fallos == 0 else 1)
