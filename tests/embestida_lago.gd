extends SceneTree
## --headless --path . --script tests/embestida_lago.gd -- --host --puerto=18010
## Usa el lago y la osa reales; simula ticks a distintas frecuencias.
var fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _comprobar(condicion: bool, mensaje: String) -> void:
	print(("OK: " if condicion else "FALLO: ") + mensaje)
	if not condicion:
		fallos += 1


func _probar() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	root.get_node("Red").pedir_listo(true)
	root.get_node("Red").iniciar_partida()
	await create_timer(0.3).timeout
	var osa = main.jefe
	var bosque = get_first_node_in_group("bosque")
	osa.set_physics_process(false)
	osa.activa = true
	osa.vida_max = 500
	osa.vida = 500
	# Ningún jugador, abeja u olla en la trayectoria de estos casos geométricos.
	main.jugadores.get_node("1").position = Vector2(1000, 650)
	for hz in [15, 30, 60, 120]:
		for i in range(16):
			var radial := Vector2.from_angle(TAU * i / 16.0)
			var inicio: Vector2 = bosque._centro_lago + (bosque._radio_lago + Vector2(35, 35)) * radial
			osa.position = inicio
			osa._dir = (bosque._centro_lago - inicio).normalized()
			osa._golpeados.clear()
			osa._cambiar("embestida", 1.1)
			var seca := true
			var continua := true
			var recorrida := 0.0
			var delta: float = 1.0 / hz
			for tick in range(ceili(1.1 * hz)):
				var anterior: Vector2 = osa.position
				osa._physics_process(delta)
				var paso: float = anterior.distance_to(osa.position)
				recorrida += paso
				continua = continua and paso <= osa.VELOCIDAD_EMBESTIDA * delta + 0.01
				for muestra in range(1, 9):
					seca = seca and not bosque.dentro_del_lago(anterior.lerp(osa.position, muestra / 8.0))
			_comprobar(seca and continua and recorrida > 450.0 and inicio.distance_to(osa.position) > 150.0,
				"Orilla %02d a %d Hz: sin agua, saltos ni atasco (recorre %.1f, avanza %.1f, seca %s, continua %s)" % [i, hz, recorrida, inicio.distance_to(osa.position), seca, continua])
	# Puede empezar casi tocando la costa: no exigir un margen que la encierre.
	for i in range(16):
		var angulo := TAU * i / 16.0
		var inicio: Vector2 = bosque._centro_lago + bosque._radio_lago * (bosque.forma_lago(angulo) - 0.056) * Vector2.from_angle(angulo)
		osa.position = inicio
		osa._dir = (bosque._centro_lago - inicio).normalized()
		osa._cambiar("embestida", 1.1)
		var seca := true
		for tick in range(66):
			osa._physics_process(1.0 / 60.0)
			seca = seca and not bosque.dentro_del_lago(osa.position)
		_comprobar(seca and inicio.distance_to(osa.position) > 150,
			"Arrancar pegada a la costa %02d permite alejarse sin atascarse" % i)
	osa.position = Vector2(5200, 350)
	osa._dir = Vector2.RIGHT
	osa._cambiar("embestida", 1.1)
	for i in range(60):
		osa._physics_process(1.0 / 60.0)
	_comprobar(osa.position.distance_to(Vector2(5720, 350)) < 0.1, "En terreno libre conserva dirección y velocidad")
	osa.position = Vector2(6895, 350)
	osa._dir = Vector2.RIGHT
	osa._cambiar("embestida", 1.1)
	for i in range(90):
		osa._physics_process(1.0 / 60.0)
	_comprobar(osa.ZONA.grow(0.01).has_point(osa.position) and osa.estado != "embestida", "El límite de la arena termina la carrera sin salir del mapa")
	osa.position = Vector2(5900, 410)
	osa._destino = bosque._centro_lago
	osa._cambiar("al_lago", 1.0)
	for i in range(24):
		osa._physics_process(1.0 / 60.0)
	_comprobar(osa.estado == "lago" and bosque.dentro_del_lago(osa.position), "El salto especial sigue entrando al lago")
	var j = main.jugadores.get_node("1")
	j.set_physics_process(false)
	j.position = Vector2(5470, 350)
	j.vida = 100
	j.proteccion = 0
	osa.position = Vector2(5400, 350)
	osa._dir = Vector2.RIGHT
	osa._golpeados.clear()
	osa._cambiar("embestida", 1.1)
	osa._physics_process(0.4)
	_comprobar(j.vida == 80, "Un tick largo detecta al jugador en el trayecto y solo hace un impacto")
	j._reaparecer.rpc(Vector2(5470, 350))
	j.vida = 100
	j.aturdimiento = 0
	j._espera_servidor = 0
	j.combate.espera_parada = 0
	j.combate.pedir_parada(-1)
	osa.position = Vector2(5400, 350)
	osa._sin_tambaleo = 0
	osa._golpeados.clear()
	osa._cambiar("embestida", 1.1)
	osa._physics_process(0.4)
	_comprobar(j.vida == 100 and osa.estado == "tambaleando" and osa.position.x < 5450,
		"Una parada interrumpe también los subpasos restantes de un tick largo")
	if "--diagnostico" in OS.get_cmdline_user_args():
		osa.position = Vector2(5900, 410)
		for i in range(600):
			osa._mover(Vector2(5900, 650), 1.0 / 60.0)
		print("DIAGNOSTICO PERSECUCION: tras 10 s hacia (5900, 650), posición ", osa.position)
	print("RESULTADO EMBESTIDA LAGO: %d fallos" % fallos)
	quit(0 if fallos == 0 else 1)
