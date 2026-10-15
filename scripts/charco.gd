extends Node2D
## Charco de vómito: burbujea, hace resbalar y quita vida a quien lo pise,
## incluida Mamá Osa. El anfitrión aplica el daño; el dibujo existe en cada pantalla.

const DANO := 5
const DANO_JEFE := 6
const RADIO := 50.0
const CARPETA := "res://arte/zona1/vomito/%d.png"

var _vida := 12.0
var _esperas: Dictionary = {}
var _cuadros: Array[Texture2D] = []
var _tiempo := 0.0


func _ready() -> void:
	z_index = -1
	add_to_group("charcos")
	var n := 0
	while ResourceLoader.exists(CARPETA % n):
		_cuadros.append(load(CARPETA % n))
		n += 1


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


func _draw() -> void:
	# Se encoge al final de su vida en vez de desaparecer de golpe.
	var tamano := clampf(_vida / 2.0, 0.0, 1.0)
	if _cuadros.is_empty():
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.45) * tamano)
		draw_circle(Vector2.ZERO, 38, Color(0.5, 0.65, 0.12, 0.85))
		return
	var cuadro := _cuadros[int(_tiempo * 8.0) % _cuadros.size()]
	draw_set_transform(Vector2.ZERO, 0, Vector2(2, 2) * tamano)
	draw_texture(cuadro, -cuadro.get_size() * 0.5)


## Para que Mamá Osa pueda sumar el daño del charco como cualquier golpe.
func dano_actual() -> int:
	return DANO_JEFE


func _physics_process(delta: float) -> void:
	_vida -= delta
	if not multiplayer.is_server():
		return
	var partida := get_tree().get_first_node_in_group("partida")
	if partida.finalizada:
		return
	if _vida <= 0:
		partida.quitar_charco.rpc(str(name))
		return
	for id in _esperas:
		_esperas[id] -= delta
	for j in get_tree().get_nodes_in_group("jugadores"):
		var d: Vector2 = j.position - position
		if j.caido or j.altura > 12 or j.es_invulnerable() or _esperas.get(j.name, 0.0) > 0:
			continue
		if Vector2(d.x, d.y * 2.2).length() < RADIO:
			_esperas[j.name] = 1.5
			j.recibir_golpe(j.mirando, DANO, 0.65)
	var jefe := get_tree().get_first_node_in_group("jefe")
	if jefe and jefe.activa and _esperas.get("jefe", 0.0) <= 0:
		var d: Vector2 = jefe.position - position
		if Vector2(d.x, d.y * 2.2).length() < RADIO + jefe.ancho:
			_esperas["jefe"] = 1.0
			jefe.golpeada(0, self)
