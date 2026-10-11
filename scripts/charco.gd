extends Node2D
## El anfitrión comprueba los resbalones; el dibujo existe en cada pantalla.

var _vida := 12.0
var _esperas: Dictionary = {}


func _ready() -> void:
	z_index = -1
	add_to_group("charcos")


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 38, Color(0.5, 0.65, 0.12, 0.85))
	draw_circle(Vector2(-12, -6), 9, Color("b9bb48"))


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	var partida := get_tree().get_first_node_in_group("partida")
	if partida.finalizada:
		return
	_vida -= delta
	if _vida <= 0:
		partida.quitar_charco.rpc(str(name))
		return
	for id in _esperas:
		_esperas[id] -= delta
	for j in get_tree().get_nodes_in_group("jugadores"):
		var d: Vector2 = j.position - position
		if j.caido or j.altura > 12 or j.es_invulnerable() or _esperas.get(j.name, 0.0) > 0:
			continue
		if Vector2(d.x, d.y * 2.2).length() < 38:
			_esperas[j.name] = 1.5
			j.recibir_golpe(j.mirando, 0, 0.65)
