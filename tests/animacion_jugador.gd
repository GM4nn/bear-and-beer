extends SceneTree
## Prueba local: --headless --max-fps 60 --script tests/animacion_jugador.gd
## -- --host --puerto=17792

var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _comprobar(condicion: bool, descripcion: String) -> void:
	print("%s: %s" % ["OK" if condicion else "FALLO", descripcion])
	if not condicion:
		fallos += 1


func _esperar(segundos: float) -> void:
	await create_timer(segundos).timeout


func _probar() -> void:
	var main = load("res://escenas/main.tscn").instantiate()
	root.add_child(main)
	var red = root.get_node("Red")
	red.pedir_listo(true)
	red.iniciar_partida()
	await _esperar(0.2)
	var jugador = main.jugadores.get_node("1")
	var jefe = main.jefe
	jefe.set_physics_process(false)
	jefe.activa = true
	jefe.vida_max = 500
	jefe.vida = 500
	jefe.estado = "pausa"
	jugador._reaparecer.rpc(Vector2(2300, 520))
	jefe.position = jugador.position + Vector2(60, 0)
	jugador.borrachera = 30
	jugador.golpear(1)
	_comprobar(jefe.vida == 500, "La preparación del puño todavía no hace daño")
	jugador.mirando = -1
	await _esperar(0.12)
	_comprobar(jefe.vida == 485, "El puño hace daño al llegar al contacto")
	_comprobar(not jugador.sprite.flip_h, "Cambiar de dirección no invierte un puñetazo en curso")
	await _esperar(0.4)
	_comprobar(jefe.vida == 485, "La recuperación del brazo no repite el daño")

	jugador.golpear(1)
	jugador.recibir_golpe(-1, 10, 1.0)
	await _esperar(0.15)
	_comprobar(jefe.vida == 485, "Recibir un empujón durante la preparación cancela el contacto")
	await _esperar(0.6)
	jugador._reaparecer.rpc(Vector2(2300, 520))
	jugador.aturdimiento = 0
	jugador.golpear(1)
	jugador.pedir_rodar(Vector2.LEFT)
	await _esperar(0.15)
	_comprobar(jefe.vida == 485, "Rodar durante la preparación cancela el contacto")
	await _esperar(0.4)

	# Recuperar el mismo paso después del golpe, en vez de arrancar de cero.
	jugador._reaparecer.rpc(Vector2(2300, 520))
	jugador.borrachera = 0
	Input.action_press("derecha")
	await _esperar(0.25)
	var fase_antes: float = (jugador.sprite.frame + jugador.sprite.frame_progress) / jugador.sprite.sprite_frames.get_frame_count("caminar")
	jugador._mostrar_golpe(1)
	await _esperar(0.04)
	_comprobar(jugador.sprite.animation == "golpear" and jugador.sprite.speed_scale == 1.0,
		"Caminar no acelera la animación del puñetazo")
	_comprobar(absf(jugador._fase_paso - fase_antes) < 0.15, "Se conserva la fase del paso al comenzar el golpe")
	await _esperar(0.32)
	_comprobar(jugador.sprite.animation == "caminar", "Después de pegar vuelve al ciclo de caminar")
	Input.action_release("derecha")
	await _esperar(0.2)
	_comprobar(jugador.sprite.animation == "quieto", "Al frenar vuelve a quieto sin repetir el golpe")

	jugador._reaparecer.rpc(Vector2(2300, 520))
	jefe.position = jugador.position + Vector2(60, 0)
	jugador.golpear(1)
	main.juego.get_node("Partida").terminar(false)
	await _esperar(0.15)
	_comprobar(jefe.vida == 485, "Un golpe pendiente no daña después de terminar la ronda")
	print("RESULTADO ANIMACIÓN: %d fallos" % fallos)
	quit(0 if fallos == 0 else 1)
