extends Node2D
## Botella vacía volando. Todas las pantallas la mueven igual; solo el anfitrión
## decide a qué le pega y cuándo se rompe. Hay fuego amigo.

const VELOCIDAD := 600.0
# Vuela casi recta, a la altura del cuerpo, y cae a unos 380 píxeles.
const GRAVEDAD := 300.0
const DANO := 12
const EMPUJON := 0.6

var direccion := Vector2.RIGHT
## Id del jugador que la lanzó (a él no le pega).
var lanzador := 0
var altura := 22.0

var _vel_altura := 60.0
var _giro := 0.0
const TEXTURA := preload("res://arte/zona1/objetos/botella_vacia.png")


func _physics_process(delta: float) -> void:
	position += direccion * VELOCIDAD * delta
	_vel_altura -= GRAVEDAD * delta
	altura += _vel_altura * delta
	_giro += delta * 14.0
	queue_redraw()
	if not multiplayer.is_server():
		# Ya cayó aquí: se esconde mientras el anfitrión avisa que se rompió.
		visible = altura > 0.0
		return
	if altura <= 0.0:
		_romper()
		return

	var dir := 1 if direccion.x >= 0.0 else -1
	for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
		var d := j.position - position
		if j.name.to_int() != lanzador and not j.caido and absf(d.x) <= 18.0 and absf(d.y) <= 18.0 \
				and altura >= j.altura - 8.0 and altura <= j.altura + 40.0:
			j.recibir_golpe(dir, DANO, EMPUJON, lanzador)
			_romper()
			return
	# Enemigos y cosas del escenario (abejas, jefe, olla, oseznos).
	var quien: Node2D = get_node_or_null("../Jugadores/%d" % lanzador)
	for cosa: Node2D in get_tree().get_nodes_in_group("golpeables"):
		var d := cosa.global_position - global_position
		if absf(d.x) <= 14.0 + cosa.ancho and absf(d.y) <= 16.0 + cosa.ancho * 0.4:
			if quien:
				quien.botellazo(cosa, dir)
			_romper()
			return


func _draw() -> void:
	draw_rect(Rect2(-7, -3, 14, 6), Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -altura), _giro)
	draw_texture(TEXTURA, -TEXTURA.get_size() * 0.5)


func _romper() -> void:
	get_tree().get_first_node_in_group("partida").quitar_botella.rpc(name)
	set_physics_process(false)


func estallar() -> void:
	var astillas := CPUParticles2D.new()
	astillas.emitting = false
	astillas.position = position - Vector2(0, maxf(altura, 0))
	astillas.amount = 8
	astillas.lifetime = 0.35
	astillas.one_shot = true
	astillas.explosiveness = 1.0
	astillas.direction = Vector2.UP
	astillas.spread = 110
	astillas.initial_velocity_min = 35
	astillas.initial_velocity_max = 100
	astillas.gravity = Vector2(0, 400)
	astillas.color = Color("ba873d")
	astillas.scale_amount_min = 2
	astillas.scale_amount_max = 3
	get_parent().add_child(astillas)
	astillas.finished.connect(astillas.queue_free)
	astillas.emitting = true
