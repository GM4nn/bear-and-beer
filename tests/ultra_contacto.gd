extends SceneTree
## Regresión del cuerpo completo y del recorte lateral al mover la cámara.
## --capturas requiere renderizador y guarda user://ultra_contacto_*.png.
var main: Node
var ultra: Node2D
var jugador: Node2D
var fallos := 0
var casos := 0
const SITIO := Vector2(2200, 650)


func _initialize() -> void:
	call_deferred("_probar")


func comprobar(ok: bool, texto: String) -> void:
	casos += 1
	if not ok:
		fallos += 1
	print(("OK: " if ok else "FALLO: ") + texto)


func _probar() -> void:
	for accion in InputMap.get_actions():
		InputMap.action_erase_events(accion)
	main = load("res://escenas/main.tscn").instantiate()
	main.bot_de_ayuda = false
	root.add_child(main)
	main._crear_partida()
	root.get_node("Red").pedir_listo(true)
	root.get_node("Red").iniciar_partida()
	await create_timer(0.8).timeout
	jugador = main.jugadores.get_node("1")
	jugador.set_physics_process(false)
	main.jefe.activa = true
	main.jefe.fase = 3
	main.jefe.vida_max = 300
	main.jefe._agotar_vida()
	ultra = main.jefe.ultra
	ultra.set_physics_process(false)
	ultra._reloj = 10000
	for barrido in [false, true]:
		for lado in [-1, 1]:
			for parte in ["mano", "brazo", "manga"]:
				var dibujo := preparar(barrido, lado)
				var local: Vector2
				if barrido:
					local = {"mano": Vector2(65, -25), "brazo": Vector2(155, -55), "manga": Vector2(430, -65)}[parte]
					if lado < 0:
						local.x = 256 - local.x
				else:
					local = {"mano": Vector2(-18, -30), "brazo": Vector2(-24, -130), "manga": Vector2(-20, -290)}[parte]
					if dibujo.flip_h:
						local.x = -local.x
				var ataque: Dictionary = ultra._ataques[0]
				var impacto: float = 6.0 / 14 if barrido else 7.0 / 14
				ultra._colocar_ataque(ataque, impacto, impacto, 3, 14)
				jugador.global_position = dibujo.to_global(local) + Vector2(0, 50)
				ultra._resolver_impacto(ataque)
				comprobar(jugador.vida == (80 if barrido else 75), "%s, lado %d, contacto con %s" % ["barrido" if barrido else "vertical", lado, parte])
				ultra._resolver_impacto(ataque)
				comprobar(jugador.vida == (80 if barrido else 75), "Sin daño duplicado en %s" % parte)
	for hz in [15, 30, 60, 120]:
		preparar(false, 1)
		jugador.global_position = SITIO
		for paso in range(hz * 3):
			ultra._physics_process(1.0 / hz)
		comprobar(jugador.vida == 75, "Contacto único durante entrada, apoyo y retirada a %d Hz" % hz)
	preparar(false, -1)
	jugador.global_position = SITIO
	ultra._physics_process(3)
	comprobar(jugador.vida == 75, "Tick de tres segundos no salta el contacto")
	preparar(false, 1)
	jugador.global_position = SITIO + Vector2(-350, 0)
	ultra._physics_process(0.8)
	jugador.global_position = SITIO
	ultra._physics_process(0.5)
	comprobar(jugador.vida == 100 and ultra.vulnerable, "Acercarse a la mano quieta permite contraatacar")
	ultra._physics_process(0.5)
	comprobar(jugador.vida == 75, "La retirada vuelve a comprobar contacto")
	preparar(false, 1)
	jugador.global_position = SITIO + Vector2(-350, 0)
	ultra._physics_process(3)
	comprobar(jugador.vida == 100, "El espacio transparente junto al brazo no daña")
	for lado in [-1, 1]:
		preparar(true, lado)
		jugador.global_position = SITIO
		jugador.altura = 60
		ultra._physics_process(3)
		comprobar(jugador.vida == 100, "Saltar todo el barrido, lado %d" % lado)
	preparar(false, 1)
	jugador.global_position = SITIO
	jugador.rodando = 0.32
	ultra._physics_process(0.6)
	jugador.rodando = 0
	ultra._physics_process(2)
	comprobar(jugador.vida == 100, "Una rodada evita toda esa pasada, sin cobro tardío")
	ultra._limpiar_ataques()
	jugador._reaparecer.rpc(SITIO)
	jugador.proteccion = 100
	jugador.set_physics_process(true)
	var camara := root.get_camera_2d()
	for lado in [-1, 1]:
		ultra._presentar(lado, Vector2(SITIO.x, 360))
		await create_timer(1.5).timeout
		for desplazamiento in [-1100, 0, 1100]:
			camara.offset.x = desplazamiento
			await create_timer(0.3).timeout
			ultra._temblor = 0
			ultra._process(0)
			var borde_local := Vector2(0 if lado < 0 else 256, 128)
			var borde: Vector2 = root.get_canvas_transform() * ultra._lado.to_global(borde_local)
			comprobar(borde.x <= 0 if lado < 0 else borde.x >= root.get_visible_rect().size.x,
				"Costura fuera de pantalla: lado %d, cámara %d" % [lado, desplazamiento])
			if "--capturas" in OS.get_cmdline_user_args():
				ultra._limpiar_ataques()
				ultra.barrer(SITIO.y, SITIO.x)
				var ataque: Dictionary = ultra._ataques[0]
				ultra._colocar_ataque(ataque, 6.0 / 14, 6.0 / 14, 3, 14)
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("user://ultra_contacto_lado%d_camara%d.png" % [lado, desplazamiento])
	# Desplazamiento real sostenido, con seguimiento de cámara y ataque activo.
	camara.offset = Vector2.ZERO
	jugador._reaparecer.rpc(SITIO)
	for direccion in [-1, 1]:
		var accion := "izquierda" if direccion < 0 else "derecha"
		var inicio: float = jugador.global_position.x
		Input.action_press(accion)
		await create_timer(2).timeout
		Input.action_release(accion)
		comprobar((jugador.global_position.x - inicio) * direccion > 100, "Desplazamiento real del jugador hacia %d" % direccion)
	print("RESULTADO CONTACTO ULTRA: %d comprobaciones, %d fallos" % [casos, fallos])
	quit(0 if fallos == 0 else 1)


func preparar(barrido: bool, lado: int) -> AnimatedSprite2D:
	ultra._limpiar_ataques()
	jugador._reaparecer.rpc(SITIO + Vector2(0, 180))
	jugador.vida = 100
	jugador.proteccion = 0
	jugador.rodando = 0
	jugador.aturdimiento = 0
	jugador.altura = 0
	ultra._lugar = lado
	return ultra.barrer(SITIO.y, SITIO.x) if barrido else ultra.garra(SITIO.x, SITIO.y, lado)
