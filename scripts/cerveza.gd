extends Node2D
## Una chela recuperable con E/Y. Se repone para no agotar la cura del prototipo.

const REPONER := 25.0
var disponible := true
var _tiempo := 0.0
var _etiqueta: Label
var _sprite: Sprite2D
var _pulso := 0.0


## Escala de dibujo de la chela (depende de si hay versión HD del dibujo).
var _escala_sprite := Vector2.ONE


func _ready() -> void:
	add_to_group("cervezas")
	_sprite = preload("res://scripts/arte_objetos.gd").estatico("chela", 1.5)
	_escala_sprite = _sprite.scale
	add_child(_sprite)
	_etiqueta = Label.new()
	_etiqueta.position = Vector2(-60, -65)
	_etiqueta.size.x = 120
	_etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_etiqueta.add_theme_font_size_override("font_size", 13)
	_etiqueta.text = "CHELA · E / Y"
	_etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_etiqueta)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 9, Color(0, 0, 0, 0.22))


func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_etiqueta.visible = false
		return
	_pulso += delta
	_sprite.position.y = sin(_pulso * 2.0) * 1.2
	# Una sola indicación junto al jugador, incluso donde hay varias botellas.
	_etiqueta.visible = false
	if not disponible:
		return
	for jugador in get_tree().get_nodes_in_group("jugadores"):
		if not jugador.is_multiplayer_authority() or not jugador.puede_actuar() or jugador.position.distance_to(position) > 44:
			continue
		var distancia: float = jugador.position.distance_to(position)
		for otra in get_tree().get_nodes_in_group("cervezas"):
			if otra != self and otra.disponible and jugador.position.distance_to(otra.position) < distancia:
				return
		_etiqueta.text = "SIX-PACK LLENO" if jugador.cervezas >= jugador.MAX_CERVEZAS else "CHELA · %s / Y" % Controles.tecla("agarrar")
		_etiqueta.visible = true
		return


func recoger(jugador: Node) -> bool:
	if not multiplayer.is_server() or not disponible or jugador.cervezas >= jugador.MAX_CERVEZAS:
		return false
	if not jugador.puede_actuar() or jugador.altura > 12 or jugador.position.distance_to(position) > 44:
		return false
	jugador.cervezas += 1
	_tiempo = REPONER
	_disponibilidad.rpc(false)
	return true


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or disponible:
		return
	_tiempo -= delta
	if _tiempo <= 0:
		_disponibilidad.rpc(true)


@rpc("authority", "call_local", "reliable")
func _disponibilidad(valor: bool) -> void:
	disponible = valor
	visible = valor
	if valor:
		_sprite.scale = Vector2.ZERO
		create_tween().tween_property(_sprite, "scale", _escala_sprite, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
