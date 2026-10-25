extends Node2D
## Botella vacía volando. Todas las pantallas la mueven igual; solo el anfitrión
## decide a qué le pega y cuándo se rompe. Hay fuego amigo.

# Parábola compartida con la guía de apuntado: toque corto / carga máxima.
const GRAVEDAD := 700.0
const ALTURA_MANO := 22.0
const DANO := 12
const EMPUJON := 0.6

var direccion := Vector2.RIGHT
## Id del jugador que la lanzó (a él no le pega).
var lanzador := 0
var altura := 50.0
var fuerza := 0.0

var _origen := Vector2.ZERO
var _altura_inicial := 22.0
var _tiempo := 0.0
var _giro := 0.0
const TEXTURA := preload("res://arte/zona1/objetos/botella_vacia.png")


static func velocidad(carga: float) -> float:
	return lerpf(240.0, 480.0, clampf(carga, 0, 1))


static func impulso(carga: float) -> float:
	return lerpf(200.0, 400.0, clampf(carga, 0, 1))


static func alto_en(t: float, inicio: float, carga: float) -> float:
	return inicio + impulso(carga) * t - 0.5 * GRAVEDAD * t * t


static func tiempo_caida(inicio: float, carga: float) -> float:
	var v := impulso(carga)
	return (v + sqrt(v * v + 2.0 * GRAVEDAD * maxf(inicio, 0))) / GRAVEDAD


func _ready() -> void:
	_origen = position
	_altura_inicial = altura


func _physics_process(delta: float) -> void:
	_tiempo += delta
	position = _origen + direccion * velocidad(fuerza) * _tiempo
	altura = alto_en(_tiempo, _altura_inicial, fuerza)
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
		if cosa.is_in_group("jefe") and cosa.fase == 4 and not cosa.puede_recibir_golpe():
			continue
		var d := cosa.global_position - global_position
		var suelo: float = cosa.altura if cosa.is_in_group("jefe") else 0.0
		if absf(d.x) <= 14.0 + cosa.ancho and absf(d.y) <= 16.0 + cosa.ancho * 0.4 \
				and altura >= suelo - 8.0 and altura <= suelo + cosa.alto_botella:
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
	Audio.efecto("botella_rompe", -2.0, 0.15)
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
