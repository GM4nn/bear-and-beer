extends Node2D
## Enemigos del encuentro de miel. Posiciones, contactos y vida los decide el host.
const CAMPOS := ["position", "tipo", "estado", "vida", "vida_max", "tiempo", "mirando", "destino", "fusionable", "bolas", "vuelo", "_reposo", "fase"]
## La reina tiene 3 fases (por su vida): cada una más rápida, con más puños y
## más bolas de miel; al cambiar de fase ruge y llama refuerzos.
const UMBRALES_FASE := [0.66, 0.33]
const ESPERA_ESPECIAL := [3.0, 2.2, 1.5]
const VELOCIDAD_REINA := [80.0, 95.0, 118.0]
const PUNOS_REINA := [2, 2, 3]
const BOLAS_REINA := [1, 2, 3]
const DURACION_RUGIDO := 1.3
var tipo := "enjambre"
var estado := "inactivo"
var vida := 0
var vida_max := 1
var tiempo := 0.0
var mirando := 1
var destino := Vector2.ZERO
var fusionable := false
var ancho := 22.0
var alto_botella := 130.0
## Bolas de miel en el aire: [origen, dirección, altura].
var bolas: Array = []
var proyectil: bool:
	get:
		return not bolas.is_empty()
var fase := 1
## Musculosas de la oleada trampa: también escupen miel.
var escupe_miel := false
var vuelo := 0.0
var altura: float:
	get:
		return vuelo
var _edad := 0.0
var _reposo := 0.0
var _turno := 0
var _contactos := 0
var _parpadeo := 0.0
var _sprites: Array = []
var _cuadros := {}
var _abeja: Array = []

func _ready() -> void:
	add_to_group("enemigos_oleada")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for familia in ["abeja_musculosa", "abeja_reina"]:
		_cuadros[familia] = {}
		for anim in ["quieto", "caminar", "boxeo", "vuelo", "miel", "muerte"]:
			var cuadros: Array = []
			var n := 0
			while ResourceLoader.exists("res://arte/%s/%s/%d.png" % [familia, anim, n]):
				cuadros.append(load("res://arte/%s/%s/%d.png" % [familia, anim, n]))
				n += 1
			_cuadros[familia][anim] = cuadros
	var n := 0
	while ResourceLoader.exists("res://arte/zona1/abeja/%d.png" % n):
		_abeja.append(load("res://arte/zona1/abeja/%d.png" % n))
		n += 1
	for i in 5:
		var s := Sprite2D.new()
		add_child(s)
		_sprites.append(s)

func vivo() -> bool:
	return estado not in ["inactivo", "muerte"] and vida > 0

func puede_recibir_golpe() -> bool:
	return vivo() and estado not in ["fusion", "rugido"] and vuelo < 45

func activar(clase: String, sitio: Vector2, fusion: bool, equipo: int) -> void:
	tipo = clase
	position = sitio
	fusionable = fusion
	vida_max = 5 if tipo == "enjambre" else 140 + equipo * 12 if tipo == "musculosa" else 350 + equipo * 110
	vida = vida_max
	estado = "caminar"
	tiempo = 0
	_edad = 0
	_reposo = 1.2
	_turno = 0
	_contactos = 0
	bolas.clear()
	vuelo = 0
	fase = 1
	escupe_miel = false

func golpeada(dir: int, quien: Node2D = null) -> void:
	if not multiplayer.is_server() or not puede_recibir_golpe() or quien == null:
		return
	vida = maxi(0, vida - (1 if tipo == "enjambre" else quien._dano_ataque))
	_parpadeo = 0.12
	if tipo == "enjambre" and fusionable and vida <= 2:
		_fusionar()
	elif vida <= 0:
		estado = "muerte"
		tiempo = 0
		bolas.clear()
		vuelo = 0
		if tipo == "musculosa":
			get_parent().partida().soltar_arma(position)
	else:
		position.x += dir * (8 if tipo == "enjambre" else 2)
		if tipo == "reina" and fase <= UMBRALES_FASE.size() and float(vida) / vida_max <= UMBRALES_FASE[fase - 1]:
			_cambiar_fase(fase + 1)


## La reina se enoja: ruge (no se le puede pegar), empuja a los cercanos y
## llama refuerzos desde los lados.
func _cambiar_fase(nueva: int) -> void:
	fase = nueva
	estado = "rugido"
	tiempo = 0
	vuelo = 0
	_contactos = 0
	get_parent().refuerzos(fase, position)

func tambalear(segundos: float) -> void:
	if not multiplayer.is_server() or not vivo() or estado == "fusion":
		return
	estado = "caminar"
	tiempo = 0
	vuelo = 0
	_reposo = maxf(_reposo, segundos)

func _fusionar() -> void:
	estado = "fusion"
	tiempo = 0
	vida = 3
	fusionable = false

func _objetivo() -> Node2D:
	var mejor: Node2D = null
	for j in get_tree().get_nodes_in_group("jugadores"):
		if j.caido or j.en_tienda() or j.en_rescate() or j.en_fogata():
			continue
		if mejor == null or position.distance_squared_to(j.position) < position.distance_squared_to(mejor.position):
			mejor = j
	return mejor

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or get_parent().partida().finalizada:
		return
	tiempo += delta
	_edad += delta
	_reposo -= delta
	if not vivo():
		return
	if not bolas.is_empty():
		_actualizar_miel(delta)
	if estado == "fusion":
		if tiempo >= 1.8:
			tipo = "musculosa"
			vida_max = 140 + Red.jugadores.size() * 12
			vida = vida_max
			estado = "caminar"
			tiempo = 0
			_reposo = 0.8
		return
	if tipo == "enjambre" and fusionable and _edad > 5:
		_fusionar()
		return
	if estado == "rugido":
		if tiempo >= 0.45 and _contactos == 0:
			_contactos = 1
			for j in get_tree().get_nodes_in_group("jugadores"):
				var d: Vector2 = j.position - position
				if d.length() < 170 and j.altura < 60 and not j.caido:
					j.recibir_golpe(1 if d.x >= 0 else -1, 6, 0.6)
		if tiempo >= DURACION_RUGIDO:
			_descansar(0.3)
		return
	if estado == "boxeo":
		var punos: int = PUNOS_REINA[fase - 1] if tipo == "reina" else 1
		for golpe in punos:
			if tiempo >= 0.5 + golpe * 0.35 and (_contactos & (1 << golpe)) == 0:
				_contactos |= 1 << golpe
				_punos()
		if tiempo >= 1.25 + maxi(punos - 2, 0) * 0.35:
			_descansar(_pausa(0.9))
		return
	if estado == "vuelo":
		if tiempo < 0.7:
			vuelo = lerpf(0, 180, tiempo / 0.7)
		elif tiempo < 1.65:
			vuelo = 180
			position = position.move_toward(destino, 380 * delta)
		else:
			vuelo = maxf(0, 180 * (1 - (tiempo - 1.65) / 0.35))
		if tiempo >= 2.0 and _contactos == 0:
			_contactos = 1
			for j in get_tree().get_nodes_in_group("jugadores"):
				if position.distance_to(j.position) < 125 and j.altura < 35:
					j.recibir_golpe(1 if j.position.x >= position.x else -1, 22, 1.1)
		if tiempo >= 2.8:
			_descansar(_pausa(1.0))
		return
	if estado == "miel":
		if tiempo >= 0.75 and _contactos == 0:
			_contactos = 1
			# En abanico: 1, 2 o 3 bolas según la fase de la reina.
			var cuantas: int = BOLAS_REINA[fase - 1] if tipo == "reina" else 1
			var origen := position + Vector2(mirando * 45, 0)
			var rumbo := (destino - origen).normalized()
			var rapidez := 300.0 + (fase - 1) * 50.0
			for k in cuantas:
				var giro := (k - (cuantas - 1) * 0.5) * 0.32
				bolas.append([origen, rumbo.rotated(giro) * rapidez, 125.0])
		if tiempo >= 1.5:
			_descansar(_pausa(1.0))
		return
	var j := _objetivo()
	if j == null:
		return
	var d := j.position - position
	mirando = 1 if d.x >= 0 else -1
	if _reposo > 0:
		return
	if tipo == "reina" and _edad > ESPERA_ESPECIAL[fase - 1] and _turno % 3 != 0:
		_iniciar("vuelo" if _turno % 3 == 1 else "miel", j.position)
		_turno += 1
		_edad = 0
		return
	if escupe_miel and _edad > 3.5 and _turno % 3 == 2:
		_iniciar("miel", j.position)
		_turno += 1
		_edad = 0
		return
	var rango := 28.0 if tipo == "enjambre" else 105.0 if tipo == "reina" else 68.0
	if absf(d.x) <= rango and absf(d.y) <= 28:
		if tipo == "enjambre":
			if j.altura < 90:
				j.recibir_dano(3)
			_reposo = 1.1
		else:
			_iniciar("boxeo", j.position)
			_turno += 1
	else:
		var velocidad: float = 135.0 if tipo == "enjambre" else VELOCIDAD_REINA[fase - 1] if tipo == "reina" else 100.0
		var nuevo := position.move_toward(j.position - Vector2(mirando * rango * 0.7, 0), velocidad * delta)
		var bosque := get_parent().get_parent().get_parent()
		if tipo != "enjambre" and bosque.dentro_del_lago(nuevo):
			nuevo = bosque.fuera_del_lago(nuevo)
		position = Vector2(clampf(nuevo.x, 40, 7140), clampf(nuevo.y, 265, 690))

func _iniciar(ataque: String, sitio: Vector2) -> void:
	estado = ataque
	tiempo = 0
	_contactos = 0
	destino = sitio
	if ataque == "vuelo":
		var bosque := get_parent().get_parent().get_parent()
		destino = bosque.fuera_del_lago(destino)
		destino.y = clampf(destino.y, 265, 690)

## En la última fase la reina casi no descansa.
func _pausa(segundos: float) -> float:
	return segundos * (0.6 if tipo == "reina" and fase == 3 else 1.0)


func _descansar(segundos: float) -> void:
	estado = "caminar"
	tiempo = 0
	vuelo = 0
	_reposo = segundos

func _punos() -> void:
	for j in get_tree().get_nodes_in_group("jugadores"):
		var d: Vector2 = j.position - position
		if d.x * mirando < -15 or absf(d.x) > (120 if tipo == "reina" else 90) or absf(d.y) > 38 or j.altura > 100:
			continue
		if j.combate.intentar_parada(self):
			tambalear(0.8)
			return
		j.recibir_golpe(mirando, (15 + (fase - 1) * 3) if tipo == "reina" else 8, 0.65)

func _actualizar_miel(delta: float) -> void:
	for k in range(bolas.size() - 1, -1, -1):
		var bola: Array = bolas[k]
		var anterior: Vector2 = bola[0]
		bola[2] = move_toward(bola[2], 65, 120 * delta)
		bola[0] = anterior + bola[1] * delta
		if Vector2(bola[0]).distance_to(position) > 850:
			bolas.remove_at(k)
			continue
		for j in get_tree().get_nodes_in_group("jugadores"):
			var cerca := Geometry2D.get_closest_point_to_segment(j.position, anterior, bola[0])
			if not j.caido and j.altura < 100 and cerca.distance_to(j.position) < 28:
				get_parent().empapar(j)
				bolas.remove_at(k)
				break

func datos() -> Dictionary:
	var d := {}
	for clave in CAMPOS:
		d[clave] = get(clave)
	return d

func aplicar(d: Dictionary) -> void:
	for clave in CAMPOS:
		set(clave, d[clave])

func _process(delta: float) -> void:
	visible = estado != "inactivo" and (estado != "muerte" or tiempo < 1.2)
	if puede_recibir_golpe() and not is_in_group("golpeables"):
		add_to_group("golpeables")
	elif not puede_recibir_golpe() and is_in_group("golpeables"):
		remove_from_group("golpeables")
	ancho = 36 if tipo == "reina" else 22
	_parpadeo = maxf(0, _parpadeo - delta)
	var reloj := Time.get_ticks_msec() / 1000.0
	for i in _sprites.size():
		var s: Sprite2D = _sprites[i]
		s.visible = visible and (i == 0 or tipo == "enjambre" and i < vida)
		if not s.visible:
			continue
		s.flip_h = mirando < 0
		s.modulate = Color(2, 2, 2) if _parpadeo > 0 else Color.WHITE
		if tipo == "enjambre":
			if not _abeja.is_empty():
				s.texture = _abeja[int(reloj * 14 + i) % _abeja.size()]
			s.scale = Vector2.ONE
			var radio := maxf(0, 34 * (1 - tiempo / 1.8)) if estado == "fusion" else 24.0
			s.position = Vector2(cos(reloj * 6 + i * TAU / 5), sin(reloj * 6 + i * TAU / 5)) * radio - Vector2(0, 45)
		else:
			var familia: Dictionary = _cuadros["abeja_reina" if tipo == "reina" else "abeja_musculosa"]
			var anim := estado if familia.has(estado) and not familia[estado].is_empty() else "quieto"
			if estado == "caminar" and _reposo > 0:
				anim = "quieto"
			var cuadros: Array = familia[anim]
			if cuadros.is_empty():
				continue
			var duracion := 2.8 if anim == "vuelo" else 1.5 if anim == "miel" else 1.25 if anim == "boxeo" else 1.2
			var progreso := fmod(reloj * 1.5, 1.0) if anim in ["caminar", "quieto"] else clampf(tiempo / duracion, 0, 0.999)
			s.texture = cuadros[mini(int(progreso * cuadros.size()), cuadros.size() - 1)]
			s.scale = Vector2.ONE * (3.7 if tipo == "reina" else 3.0)
			# Los PNG tienen margen transparente: anclar los pies, no el lienzo.
			var pie := 52.0 if tipo == "reina" else 80.0
			s.position = Vector2(0, (s.texture.get_height() * 0.5 - pie) * s.scale.y - vuelo)
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	if vivo():
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, 33 if tipo == "reina" else 20, Color(0, 0, 0, 0.25))
		draw_set_transform(Vector2.ZERO)
	if estado == "vuelo" and tiempo < 2:
		draw_arc(destino - position, 125, 0, TAU, 64, Color(1, 0.3, 0.1, 0.8), 4)
	if estado == "boxeo" and tiempo < 0.5:
		draw_line(Vector2(mirando * 30, -20), Vector2(mirando * 130, -20), Color(1, 0.4, 0.2, 0.8), 4)
	for bola: Array in bolas:
		var donde: Vector2 = bola[0] - position - Vector2(0, bola[2])
		draw_circle(donde, 13, Color("e6a322"))
		draw_circle(donde - Vector2(3, 4), 5, Color("ffdf69"))
	if estado == "rugido":
		var onda := clampf(tiempo / 0.6, 0, 1)
		draw_arc(Vector2(0, -40), 40 + onda * 140, 0, TAU, 48, Color(1, 0.75, 0.2, 1 - onda), 5)
	if vivo() and tipo == "musculosa":
		draw_rect(Rect2(-30, -150, 60, 5), Color("292022"))
		draw_rect(Rect2(-30, -150, 60.0 * vida / vida_max, 5), Color("ffc15a"))
