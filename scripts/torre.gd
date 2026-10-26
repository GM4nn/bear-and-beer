extends Node
## Relaciones autoritativas de hombros. Cada pantalla deriva la posición de los
## pasajeros desde la base para que no se separen por el orden de los paquetes.

const MAX_COMPAS := 3
const ALTURA_HOMBROS := 40.0
const RADIO_X := 28.0
const RADIO_Y := 22.0
const VENTANA_CRITICO := 0.18
var _impactos: Dictionary = {}
var _tiempo_juego := 0.0
## Contador visual local, también útil para comprobar que el aviso se replica.
var criticos := 0


func _ready() -> void:
	# Física después de mover jugadores; dibujo antes de actualizar sus sprites.
	process_physics_priority = 10
	process_priority = -10


func jugador(id: int) -> Node2D:
	return get_node_or_null("../../Mundo/Jugadores/%d" % id)


func encima(compa: Node2D) -> Node2D:
	for otro: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if otro.apoyo_id == compa.name.to_int():
			return otro
	return null


func _base(compa: Node2D) -> Node2D:
	var vistos: Array = []
	while compa != null and compa.apoyo_id != 0:
		if compa in vistos or vistos.size() >= MAX_COMPAS:
			return null
		vistos.append(compa)
		compa = jugador(compa.apoyo_id)
	return compa


func _cadena(base: Node2D) -> Array:
	var compas: Array = []
	while base != null and base not in compas and compas.size() <= MAX_COMPAS:
		compas.append(base)
		base = encima(base)
	return compas


func _equilibrado(compa: Node2D) -> bool:
	if compa.en_rescate():
		return get_parent().rescate.puede_sostener(compa)
	return compa.puede_actuar() and compa._pieza_cargada() == null


## La petición llega por la acción E del jugador; el cliente no elige el apoyo.
func intentar_subir(compa: Node2D) -> void:
	if not multiplayer.is_server() or get_parent().finalizada or compa.apoyo_id != 0 \
			or not _equilibrado(compa) or encima(compa) != null:
		return
	var mejor: Node2D = null
	for base: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if base == compa or base.apoyo_id != 0 or not _equilibrado(base):
			continue
		var d := compa.position - base.position
		# E requiere estar saltando por encima del compañero. Si ya lleva a uno,
		# la trepada termina en el hueco superior: no exige duplicar el salto.
		var diferencia_altura: float = compa.altura - base.altura
		if absf(d.x) > RADIO_X or absf(d.y) > RADIO_Y \
				or diferencia_altura < 35.0 or diferencia_altura > 95.0:
			continue
		if mejor == null or d.length_squared() < compa.position.distance_squared_to(mejor.position):
			mejor = base
	if mejor == null:
		return
	var compas := _cadena(mejor)
	if compas.size() >= MAX_COMPAS:
		compa._avisar_bebida.rpc("Torre llena · máximo 3 compas en total")
		return
	for apoyo: Node2D in compas:
		if not _equilibrado(apoyo):
			return
	_montar.rpc(compa.name.to_int(), compas.back().name.to_int())


@rpc("authority", "call_local", "reliable")
func _montar(id: int, apoyo: int) -> void:
	_invalidar_impactos(id)
	_invalidar_impactos(apoyo)
	var compa := jugador(id)
	if compa == null:
		return
	compa.apoyo_id = apoyo
	compa.velocity = Vector2.ZERO
	compa._vel_altura = 0.0
	compa._volando = false
	compa._cancelar_golpes()
	compa._anim_golpe = 0.0
	compa.manteniendo = false
	_alinear()


func bajar(compa: Node2D, saltando: bool) -> void:
	if multiplayer.is_server() and compa.apoyo_id != 0:
		_alinear()
		var compas := _cadena(compa)
		for pasajero: Node2D in compas:
			_soltar.rpc(pasajero.name.to_int(), pasajero.position, pasajero.altura,
				pasajero.SALTO if saltando and pasajero == compa else 20.0)


func soltar_encima(compa: Node2D) -> void:
	var pasajero := encima(compa)
	if pasajero != null:
		bajar(pasajero, false)


func romper_desde(compa: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if compa.apoyo_id != 0:
		bajar(compa, false)
	else:
		soltar_encima(compa)


@rpc("authority", "call_local", "reliable")
func _soltar(id: int, sitio: Vector2, alto: float, impulso: float) -> void:
	_invalidar_impactos(id)
	var compa := jugador(id)
	if compa == null:
		return
	compa.apoyo_id = 0
	compa.position = sitio
	compa.altura = alto
	compa.velocity = Vector2(compa.mirando * 80.0, 0)
	compa._vel_altura = impulso
	compa._volando = false
	compa.manteniendo = false


func _physics_process(_delta: float) -> void:
	_tiempo_juego += _delta * 1000.0
	for clave in _impactos.keys():
		if _tiempo_juego - _impactos[clave].inicio > VENTANA_CRITICO * 1000:
			_impactos.erase(clave)
	if get_parent().finalizada:
		_impactos.clear()
		return
	if multiplayer.is_server():
		for compa: Node2D in get_tree().get_nodes_in_group("jugadores"):
			if not _equilibrado(compa) or (compa.apoyo_id != 0 and _base(compa) == null):
				romper_desde(compa)
	_alinear()


func _process(_delta: float) -> void:
	if not get_parent().finalizada:
		_alinear()


func _alinear() -> void:
	for base: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if base.apoyo_id != 0:
			continue
		var compas := _cadena(base)
		for piso in range(1, compas.size()):
			var compa: Node2D = compas[piso]
			compa.position = base.position
			if base.en_rescate():
				compa.position.x += get_parent().rescate.equilibrio * 12.0 * piso
			compa.altura = base.altura + ALTURA_HOMBROS * piso
			compa.velocity = Vector2.ZERO


func _invalidar_impactos(id: int) -> void:
	for clave in _impactos.keys():
		if id in _impactos[clave].ids:
			_impactos.erase(clave)


## Los puños conservan su contacto inmediato. Al acertar el último integrante,
## el bonus completa x2 del daño total; nunca se reutilizan golpes anteriores.
## La olla y los oseznos no reciben este bonus de combate contra enemigos.
func bono_impacto(compa: Node2D, objetivo: Node2D, dir: int, dano: int) -> int:
	if not multiplayer.is_server() or get_parent().finalizada or not (objetivo.is_in_group("jefe") or objetivo.is_in_group("enemigos_oleada")):
		return 0
	if not objetivo.puede_recibir_golpe():
		return 0
	var compas := _cadena(_base(compa))
	if compas.size() < 2 or compas.size() > MAX_COMPAS or not compas.all(_equilibrado):
		return 0
	var ids := compas.map(func(j): return j.name.to_int())
	var clave := objetivo.get_instance_id()
	var ahora := _tiempo_juego
	var registro: Dictionary = _impactos.get(clave, {})
	if registro.is_empty() or registro.ids != ids or registro.dir != dir \
			or ahora - registro.inicio > VENTANA_CRITICO * 1000:
		registro = {"ids": ids, "dir": dir, "inicio": ahora, "golpes": {}}
	registro.golpes[compa.name.to_int()] = dano
	_impactos[clave] = registro
	if registro.golpes.size() != compas.size():
		return 0
	var bonus := 0
	for valor: int in registro.golpes.values():
		bonus += valor
	_impactos.erase(clave)
	_mostrar_critico.rpc(objetivo.global_position - Vector2(0, 100), ids)
	return bonus


@rpc("authority", "call_local", "reliable")
func _mostrar_critico(donde: Vector2, ids: Array) -> void:
	criticos += 1
	Audio.efecto("torre_critico", 0.0, 0.0)
	var aviso := Label.new()
	aviso.text = "¡CRÍTICO DE TORRE! ×2"
	aviso.add_theme_color_override("font_color", Color("ffe575"))
	aviso.add_theme_color_override("font_outline_color", Color("392014"))
	aviso.add_theme_constant_override("outline_size", 4)
	aviso.add_theme_font_size_override("font_size", 22)
	aviso.z_index = 30
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("../../Mundo").add_child(aviso)
	aviso.global_position = donde - Vector2(125, 0)
	for id: int in ids:
		var compa := jugador(id)
		if compa != null:
			compa._parpadeo = 0.18
	var efecto := aviso.create_tween().set_parallel(true)
	efecto.tween_property(aviso, "position:y", aviso.position.y - 45, 0.7)
	efecto.tween_property(aviso, "modulate:a", 0.0, 0.35).set_delay(0.35)
	efecto.chain().tween_callback(aviso.queue_free)
