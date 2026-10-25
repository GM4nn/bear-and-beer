extends Node2D
## Ultra fase: presentación de Claude y ataques resueltos por el anfitrión.
## La osa gigante se asoma por encima del bosque, inclinada hacia los jugadores,
## detrás de los arbustos de la orilla. Desde aquí se llama a:
##   asomarse(), esconderse(), mirar(-1 / 0 / 1), rugir(), garra(x, y, lado), barrer(y)
## Los dibujos están en arte/mama_osa/ultra/ (herramientas/difuminar_osa_ultra.py
## recorta y desvanece la parte de abajo de las poses).

const CARPETA := "res://arte/mama_osa/ultra/%s.png"
const POSES := ["neutral", "parpadeo", "mira_izq", "mira_der", "rugido"]
## Escala de la cara (las poses miden 512x206) y dónde queda en la pantalla.
const ESCALA_CARA := 2.0
const ARRIBA_CARA := -150.0
## Cuánto baja escondida (fuera de vista, detrás del suelo).
const ESCONDIDA := 420.0
const ESCALA_GARRA := 1.5
const FPS_GARRA := 14.0
## Cuadro de la garra en que las uñas pegan en el piso (para sincronizar daño).
const CUADRO_IMPACTO_GARRA := 7
## Cuánto más abajo van los arbustos que la tapan, respecto a los de la orilla.
const BAJADA_ARBUSTOS := 18.0
## En Mundo todo se ordena por su altura (y): la osa se ordena como si estuviera
## en ORDEN_Y, justo detrás de la orilla. Así queda delante de los árboles del
## fondo y detrás de los jugadores. Nada de ella se dibuja más abajo de esa línea.
const ORDEN_Y := 300.0
const RECORTE := preload("res://arte/mama_osa/ultra/recorte.gdshader")
const MANGA := preload("res://scripts/manga_ultra.gd")
const DANO_GARRA := 25
const DANO_BARRIDO := 20
const RECUPERACION := 1.1
const ALTURA_SALTAR_BARRIDO := 28.0

var activa := false
var vulnerable := false
var jefe: Node2D
var _ataques: Array[Dictionary] = []
var _etapa := ""
var _reloj := 0.0
var _turno := 0
var _objetivo := 0
var _numero := 0
var _ancla := Vector2.ZERO
var _siluetas := {"garra": [], "barrer": []}

signal garra_impacto(x: float)

var _cara: Sprite2D
var _texturas := {}
var _pose := "neutral"
var _mirando := 0
## Por dónde se asoma: -1 orilla izquierda de la pantalla, 0 al centro, 1 derecha.
var _lugar := 0
## De lado: dibujo asomado de perfil (256x256, se ve al doble) y cuánto le falta
## para entrar (0 = adentro).
var _lado: AnimatedSprite2D
var _entrada := 0.0
var _cuadros_barrer: SpriteFrames
## Tela de la manga del brazo de lado y, por cuadro, qué filas ocupa en la orilla.
var _tela_barrer: Texture2D
var _orilla_barrer: Array[Vector2] = []
const ESCALA_LADO := 2.0
const ARRIBA_LADO := 104.0
const FUERA_LADO := 520.0
## Columna del dibujo de lado donde está la orilla que la corta (lado derecho).
const BORDE_LADO := 232.0
## Brazo que barre el piso de lado (256x128, se ve al doble).
const ESCALA_BARRER := 2.0
const FPS_BARRER := 14.0
## Fila del dibujo del brazo donde quedan las uñas, y cuadro en que pegan.
const PIE_BARRER := 118.0
const CUADRO_IMPACTO_BARRER := 6
## Cuánto más adentro llega el brazo (en pantalla): la manga se alarga con su tela
## desde la orilla para que la garra llegue a media pantalla.
const ALARGUE_BARRER := 260.0
var _rugiendo := false
var _parpadeo := 3.0
var _tiempo := 0.0
var _altura := ESCONDIDA
var _temblor := 0.0
var _cuadros_garra: SpriteFrames
## Tela de la manga y, por cuadro, de qué columna a qué columna llega el brazo arriba.
var _tela_manga: Texture2D
var _arriba_garra: Array[Vector2] = []


func _ready() -> void:
	for pose in POSES:
		_texturas[pose] = load(CARPETA % pose)
	_cara = Sprite2D.new()
	_cara.texture = _texturas["neutral"]
	_cara.centered = false
	_cara.scale = Vector2.ONE * ESCALA_CARA
	var recorte := ShaderMaterial.new()
	recorte.shader = RECORTE
	recorte.set_shader_parameter("limite_y", ORDEN_Y)
	_cara.material = recorte
	add_child(_cara)
	_cuadros_garra = SpriteFrames.new()
	_cuadros_garra.remove_animation("default")
	_cuadros_garra.add_animation("garra")
	_cuadros_garra.set_animation_speed("garra", FPS_GARRA)
	_cuadros_garra.set_animation_loop("garra", false)
	var i := 0
	while ResourceLoader.exists(CARPETA % ("garra/%d" % i)):
		var cuadro: Texture2D = load(CARPETA % ("garra/%d" % i))
		_cuadros_garra.add_frame("garra", cuadro)
		var imagen := cuadro.get_image()
		_siluetas.garra.append(_silueta(imagen))
		var desde := 0
		while desde < imagen.get_width() - 1 and imagen.get_pixel(desde, 0).a < 0.5:
			desde += 1
		var hasta := imagen.get_width() - 1
		while hasta > desde and imagen.get_pixel(hasta, 0).a < 0.5:
			hasta -= 1
		_arriba_garra.append(Vector2(desde, hasta))
		i += 1
	_tela_manga = load(CARPETA % "garra/manga")
	_lado = AnimatedSprite2D.new()
	var cuadros_lado := SpriteFrames.new()
	cuadros_lado.remove_animation("default")
	for anim in ["quieto", "rugido"]:
		cuadros_lado.add_animation(anim)
		cuadros_lado.set_animation_speed(anim, 8.0 if anim == "quieto" else 12.0)
		cuadros_lado.set_animation_loop(anim, anim == "quieto")
		var n := 0
		while ResourceLoader.exists(CARPETA % ("lado_%s/%d" % [anim, n])):
			cuadros_lado.add_frame(anim, load(CARPETA % ("lado_%s/%d" % [anim, n])))
			n += 1
	_lado.sprite_frames = cuadros_lado
	_lado.centered = false
	_lado.scale = Vector2.ONE * ESCALA_LADO
	_lado.visible = false
	add_child(_lado)
	_cuadros_barrer = SpriteFrames.new()
	_cuadros_barrer.remove_animation("default")
	_cuadros_barrer.add_animation("barrer")
	_cuadros_barrer.set_animation_speed("barrer", FPS_BARRER)
	_cuadros_barrer.set_animation_loop("barrer", false)
	var b := 0
	while ResourceLoader.exists(CARPETA % ("barrer/%d" % b)):
		var cuadro_b: Texture2D = load(CARPETA % ("barrer/%d" % b))
		_cuadros_barrer.add_frame("barrer", cuadro_b)
		var img := cuadro_b.get_image()
		_siluetas.barrer.append(_silueta(img))
		var arriba := 0
		while arriba < img.get_height() - 1 and img.get_pixel(img.get_width() - 1, arriba).a < 0.5:
			arriba += 1
		var abajo := img.get_height() - 1
		while abajo > arriba and img.get_pixel(img.get_width() - 1, abajo).a < 0.5:
			abajo -= 1
		_orilla_barrer.append(Vector2(arriba, abajo))
		b += 1
	_tela_barrer = load(CARPETA % "barrer/manga")
	visible = false
	_colocar.call_deferred()


# Se mete en Mundo para ordenarse con los árboles y los jugadores, y copia las
# matas de la orilla (un poco más abajo) delante de ella.
func _colocar() -> void:
	var bosque := get_tree().get_first_node_in_group("bosque")
	if bosque == null:
		return
	if bosque.has_node("Mundo") and get_parent() != bosque.get_node("Mundo"):
		reparent(bosque.get_node("Mundo"))
	global_position = Vector2(0, ORDEN_Y)
	if not bosque.has_node("Suelo"):
		return
	var capa := Node2D.new()
	capa.name = "Arbustos"
	add_child(capa)
	for mata in bosque.get_node("Suelo").get_children():
		if mata is Sprite2D and mata.visible and mata.texture != null and mata.texture.resource_path.contains("arbustos"):
			var copia: Sprite2D = mata.duplicate()
			copia.position = mata.global_position + Vector2(0, BAJADA_ARBUSTOS) - global_position
			capa.add_child(copia)


func _process(delta: float) -> void:
	_tiempo += delta
	# Pegada a la pantalla: sigue a la cámara.
	var camara := get_viewport().get_camera_2d()
	var esquina := Vector2.ZERO
	if camara != null:
		esquina = camara.get_screen_center_position() - get_viewport_rect().size * 0.5
	# En combate el encuadre es del mundo y compartido por todos los peers.
	var tamano := Vector2(1280, 720) if activa else get_viewport_rect().size
	if activa:
		esquina = _ancla - tamano * 0.5
	var ancho := _cara.texture.get_width() * ESCALA_CARA
	_temblor = move_toward(_temblor, 0.0, delta * 20.0)
	var sacudida := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _temblor
	# Respira: sube y baja muy poco.
	var respira := sin(_tiempo * 1.6) * 3.0
	_cara.position = esquina + Vector2((tamano.x - ancho) * 0.5, ARRIBA_CARA + _altura + respira) + sacudida - global_position
	# El perfil es una aparición desde el borde, no un cuerpo recortado en el mundo.
	# Solo su presentación sigue la cámara; manos y daño conservan coordenadas comunes.
	var inversa := get_viewport().get_canvas_transform().affine_inverse()
	var izquierda := (inversa * Vector2.ZERO).x
	var derecha := (inversa * get_viewport_rect().size).x
	var lateral_x := derecha - BORDE_LADO * ESCALA_LADO + _entrada
	if _lugar < 0:
		lateral_x = izquierda - (256.0 - BORDE_LADO) * ESCALA_LADO - _entrada
	_lado.position = Vector2(lateral_x, esquina.y + ARRIBA_LADO) + sacudida - global_position
	# Parpadea de vez en cuando (no mientras ruge).
	_parpadeo -= delta
	if _parpadeo <= 0.0:
		_parpadeo = randf_range(2.5, 5.0)
	var pose: String = "rugido" if _rugiendo else ["mira_izq", "neutral", "mira_der"][_mirando + 1]
	if not _rugiendo and _mirando == 0 and _parpadeo < 0.12:
		pose = "parpadeo"
	if pose != _pose:
		_pose = pose
		_cara.texture = _texturas[pose]


## Se asoma. lugar 0: sube al centro desde detrás del bosque. lugar 1 / -1:
## entra de lado por la orilla derecha / izquierda de la pantalla (otro dibujo,
## asomada de perfil mirando al centro).
func asomarse(duracion := 1.4, lugar := 0) -> void:
	_lugar = clampi(lugar, -1, 1)
	visible = true
	_temblor = 6.0
	# Los arbustos que la tapan solo van cuando se asoma al centro.
	if has_node("Arbustos"):
		get_node("Arbustos").visible = _lugar == 0
	if _lugar == 0:
		_cara.visible = true
		_lado.visible = false
		_mirando = 0
		_altura = ESCONDIDA
		var t := create_tween()
		t.tween_property(self, "_altura", 0.0, duracion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await t.finished
		return
	_cara.visible = false
	_lado.visible = true
	_lado.flip_h = _lugar < 0
	_lado.play("quieto")
	_entrada = FUERA_LADO
	var t2 := create_tween()
	t2.tween_property(self, "_entrada", 0.0, duracion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t2.finished


## Se va: al centro baja detrás del bosque; de lado sale por su orilla.
func esconderse(duracion := 1.0) -> void:
	var t := create_tween()
	if _lugar == 0:
		t.tween_property(self, "_altura", ESCONDIDA, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		t.tween_property(self, "_entrada", FUERA_LADO, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished
	visible = false


## -1 voltea a la izquierda, 1 a la derecha, 0 al frente (solo al centro).
func mirar(lado: int) -> void:
	_mirando = clampi(lado, -1, 1)


## Ruge con la boca abierta y tiembla.
func rugir(duracion := 1.3) -> void:
	_temblor = 9.0
	Audio.efecto("rugido-oso", 2.0, 0.0)
	var sacude := create_tween().set_loops(int(duracion / 0.1))
	sacude.tween_callback(func(): _temblor = maxf(_temblor, 6.0)).set_delay(0.1)
	if _lugar != 0:
		_lado.play("rugido")
		await _lado.animation_finished
		_lado.play("quieto")
		return
	_rugiendo = true
	var t := create_tween()
	t.tween_property(_cara, "scale", Vector2.ONE * ESCALA_CARA * 1.04, 0.15)
	t.tween_property(_cara, "scale", Vector2.ONE * ESCALA_CARA, duracion - 0.15)
	await t.finished
	_rugiendo = false


## Una garra gigante baja desde arriba y rasguña el piso en `x` (coordenadas del
## mundo), con las uñas en `piso_y`. lado 1 rasguña hacia la derecha, -1 hacia la
## izquierda. Emite garra_impacto cuando las uñas tocan el piso.
func garra(x: float, piso_y: float, lado := 1) -> AnimatedSprite2D:
	var dibujo := AnimatedSprite2D.new()
	dibujo.sprite_frames = _cuadros_garra
	dibujo.animation = "garra"
	dibujo.centered = false
	dibujo.scale = Vector2.ONE * ESCALA_GARRA
	dibujo.flip_h = lado < 0
	dibujo.offset = Vector2(-128, -245)
	(get_parent() if get_parent() is Node2D else self).add_child(dibujo)
	dibujo.global_position = Vector2(x, piso_y)
	var manga := MANGA.new()
	manga.name = "Manga"
	manga.texture = _tela_manga
	dibujo.add_child(manga)
	var acomodar := func():
		var tramo: Vector2 = _arriba_garra[dibujo.frame]
		var izq := tramo.x if lado > 0 else 255.0 - tramo.y
		var ancho := tramo.y - tramo.x + 1.0
		var union := Vector2(izq - 128 + ancho * 0.5, -243)
		# Solo la longitud necesaria para entrar desde arriba, con codo y estrechamiento.
		var largo := maxf(120, (piso_y + 100) / ESCALA_GARRA - 245)
		manga.colocar(union, union + Vector2(-lado * 42, -largo), ancho, ancho * 1.28, lado * 38)
	acomodar.call()
	dibujo.frame_changed.connect(acomodar)
	_registrar_ataque(dibujo, Vector2(x, piso_y), Vector2(x, piso_y), false, lado)
	return dibujo


## La posición de contacto es del mundo, nunca de la cámara del cliente.
## Sin x_contacto conserva el encuadre de la demo de Claude.
func barrer(piso_y: float, x_contacto := NAN) -> AnimatedSprite2D:
	var lado := _lugar if _lugar != 0 else 1
	var camara := get_viewport().get_camera_2d()
	var centro := camara.get_screen_center_position() if camara else Vector2(640, 360)
	var mitad := get_viewport_rect().size.x * 0.5
	var x := centro.x + mitad - 256.0 * ESCALA_BARRER - ALARGUE_BARRER if lado > 0 else centro.x - mitad + ALARGUE_BARRER
	var desfase := 140.0 if lado > 0 else 372.0
	if not is_nan(x_contacto):
		x = x_contacto - desfase
	var dibujo := AnimatedSprite2D.new()
	dibujo.sprite_frames = _cuadros_barrer
	dibujo.animation = "barrer"
	dibujo.centered = false
	dibujo.scale = Vector2.ONE * ESCALA_BARRER
	dibujo.flip_h = lado < 0
	dibujo.offset = Vector2(0, -PIE_BARRER)
	(get_parent() if get_parent() is Node2D else self).add_child(dibujo)
	dibujo.global_position = Vector2(x, piso_y)
	var manga := MANGA.new()
	manga.name = "Manga"
	manga.texture = _tela_barrer
	dibujo.add_child(manga)
	var acomodar := func():
		var filas: Vector2 = _orilla_barrer[dibujo.frame]
		var union := Vector2(254 if lado > 0 else 2, (filas.x + filas.y) * 0.5 - PIE_BARRER)
		var ancho := maxf(filas.y - filas.x, 2)
		# La manga se curva hacia el hombro; la mano conserva tamaño y alcance.
		# Alcance físico fijo: la cámara no alarga el brazo a través de todo el mapa.
		manga.colocar(union, union + Vector2(lado * (ALARGUE_BARRER / ESCALA_BARRER + 60), -16), ancho, ancho * 1.08, -lado * 12, true)
	acomodar.call()
	dibujo.frame_changed.connect(acomodar)
	_registrar_ataque(dibujo, Vector2(x, piso_y), Vector2(x + desfase, piso_y), true, -lado)
	return dibujo


func _registrar_ataque(dibujo: AnimatedSprite2D, origen: Vector2, contacto: Vector2, barrido: bool, direccion: int) -> void:
	_ataques.append({"dibujo": dibujo, "origen": origen, "contacto": contacto, "barrido": barrido,
		"direccion": direccion, "tiempo": 0.0, "resuelto": false, "golpeados": {}})


func _physics_process(delta: float) -> void:
	var partida := get_tree().get_first_node_in_group("partida")
	if partida != null and partida.finalizada:
		_limpiar_ataques()
		visible = false
		activa = false
		return
	vulnerable = false
	for ataque in _ataques.duplicate():
		var dibujo: AnimatedSprite2D = ataque.dibujo
		var fps := FPS_BARRER if ataque.barrido else FPS_GARRA
		var impacto := (CUADRO_IMPACTO_BARRER if ataque.barrido else CUADRO_IMPACTO_GARRA) / fps
		var duracion := dibujo.sprite_frames.get_frame_count(dibujo.animation) / fps + RECUPERACION
		var anterior: float = ataque.tiempo
		var hasta := minf(anterior + delta, duracion)
		# Recorrer el movimiento, incluso con pocos FPS, sin atravesar al jugador.
		var pasos := maxi(1, ceili((hasta - anterior) * 120.0))
		for paso in range(1, pasos + 1):
			var t := lerpf(anterior, hasta, float(paso) / pasos)
			_colocar_ataque(ataque, t, impacto, duracion, fps)
			var contacto_nuevo: bool = not ataque.resuelto and t >= impacto
			if contacto_nuevo:
				ataque.resuelto = true
				_temblor = 5.0
				Audio.efecto("pisoton", 2.0, 0.1)
				garra_impacto.emit(ataque.contacto.x)
			# La entrada y la retirada hacen daño; apoyada permite el contraataque.
			if t < impacto or contacto_nuevo or t >= impacto + RECUPERACION:
				_resolver_impacto(ataque)
		ataque.tiempo = hasta
		if hasta >= impacto and hasta < impacto + RECUPERACION:
			vulnerable = true
			if activa and is_instance_valid(jefe) and multiplayer.is_server():
				jefe.global_position = ataque.contacto
		if hasta >= duracion:
			dibujo.queue_free()
			_ataques.erase(ataque)
	if activa and multiplayer.is_server():
		_avanzar_pelea(delta)


func _colocar_ataque(ataque: Dictionary, t: float, impacto: float, duracion: float, fps: float) -> void:
	var dibujo: AnimatedSprite2D = ataque.dibujo
	var tiempo_anim := t if t < impacto else impacto if t < impacto + RECUPERACION else t - RECUPERACION
	dibujo.set_frame_and_progress(mini(int(tiempo_anim * fps), dibujo.sprite_frames.get_frame_count(dibujo.animation) - 1), 0)
	var recoge := maxf(t - impacto - RECUPERACION, 0) / maxf(duracion - impacto - RECUPERACION, 0.01)
	var prepara := pow(1.0 - clampf(t / impacto, 0, 1), 2)
	var desplazamiento := prepara * 150.0 + recoge * recoge * 180.0
	dibujo.global_position = ataque.origen + (Vector2(-ataque.direccion * desplazamiento, -recoge * 35) if ataque.barrido else Vector2(0, -desplazamiento))


func _silueta(imagen: Image) -> Array[PackedVector2Array]:
	var mascara := BitMap.new()
	mascara.create_from_image_alpha(imagen, 0.5)
	return mascara.opaque_to_polygons(Rect2i(Vector2i.ZERO, imagen.get_size()), 1.0)


func _toca_cuerpo(ataque: Dictionary, j: Node2D) -> bool:
	var dibujo: AnimatedSprite2D = ataque.dibujo
	# Cuerpo del jugador, sin incluir el espacio transparente de su lienzo.
	var pies: Vector2 = j.global_position - Vector2(0, j.altura)
	var cuerpo := PackedVector2Array([pies + Vector2(-14, -104), pies + Vector2(14, -104),
		pies + Vector2(14, -6), pies + Vector2(-14, -6)])
	var local := dibujo.global_transform.affine_inverse() * cuerpo
	var manga: Polygon2D = dibujo.get_node("Manga")
	if not Geometry2D.intersect_polygons(local, manga.transform * manga.polygon).is_empty():
		return true
	# El mismo cuadro y volteo que ve el jugador: uñas, mano, antebrazo y tela.
	var textura := dibujo.sprite_frames.get_frame_texture(dibujo.animation, dibujo.frame)
	var transformacion := Transform2D.IDENTITY
	if dibujo.flip_h:
		transformacion.x.x = -1
		transformacion.origin.x = textura.get_width()
	transformacion.origin += dibujo.offset
	for contorno in _siluetas[dibujo.animation][dibujo.frame]:
		if not Geometry2D.intersect_polygons(local, transformacion * contorno).is_empty():
			return true
	return false


func _resolver_impacto(ataque: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var partida := get_tree().get_first_node_in_group("partida")
	if partida == null or partida.finalizada:
		return
	for j in get_tree().get_nodes_in_group("jugadores"):
		if j.caido or ataque.golpeados.has(j.name):
			continue
		if ataque.barrido and j.altura > ALTURA_SALTAR_BARRIDO:
			continue
		if not _toca_cuerpo(ataque, j):
			continue
		# Una sola oportunidad por pasada, también si se esquivó rodando.
		ataque.golpeados[j.name] = true
		j.recibir_golpe(ataque.direccion, DANO_BARRIDO if ataque.barrido else DANO_GARRA, 1.5)


func _limpiar_ataques() -> void:
	for ataque in _ataques:
		if is_instance_valid(ataque.dibujo):
			ataque.dibujo.queue_free()
	_ataques.clear()
	vulnerable = false


func _exit_tree() -> void:
	_limpiar_ataques()


func iniciar() -> void:
	if not multiplayer.is_server():
		return
	_iniciar.rpc()


@rpc("authority", "call_local", "reliable")
func _iniciar() -> void:
	jefe = get_tree().get_first_node_in_group("jefe")
	jefe.ancho = 90.0
	jefe.alto_botella = 120.0
	activa = true
	_turno = 0
	_objetivo = 0
	_etapa = "entrada"
	_reloj = 0.0


func _presa() -> Node2D:
	var vivos := get_tree().get_nodes_in_group("jugadores").filter(func(j): return not j.caido)
	vivos.sort_custom(func(a, b): return a.name.to_int() < b.name.to_int())
	if vivos.is_empty():
		return null
	return vivos[_objetivo % vivos.size()]


func _avanzar_pelea(delta: float) -> void:
	if not is_instance_valid(jefe) or jefe.estado == "derrotada":
		terminar.rpc()
		return
	_reloj -= delta
	if _reloj > 0:
		return
	var presa := _presa()
	if presa == null:
		return
	match _etapa:
		"entrada":
			var lugar: int = [0, -1, 1][_turno % 3]
			_ancla = Vector2(presa.global_position.x, 360)
			_presentar.rpc(lugar, _ancla)
			_etapa = "rugido"
			_reloj = 1.7
		"rugido":
			_rugir.rpc()
			_etapa = "ataque"
			_reloj = 1.4
		"ataque":
			# Fijar el destino al iniciar la preparación. No sigue al jugador al impactar.
			var punto: Vector2 = presa.global_position
			_atacar.rpc(punto, _lugar != 0, _lugar)
			_etapa = "retirada"
			_reloj = 3.0
		"retirada":
			_retirar.rpc()
			_etapa = "entrada"
			_reloj = 1.5
			_turno += 1
			_objetivo += 1


@rpc("authority", "call_local", "reliable")
func _presentar(lugar: int, ancla: Vector2) -> void:
	_ancla = ancla
	asomarse(1.4, lugar)


@rpc("authority", "call_local", "reliable")
func _rugir() -> void:
	rugir()


@rpc("authority", "call_local", "reliable")
func _atacar(punto: Vector2, barrido: bool, lado: int) -> void:
	if not activa:
		return
	_lugar = lado
	_numero += 1
	if barrido:
		barrer(punto.y, punto.x)
	else:
		garra(punto.x, punto.y, 1 if _numero % 2 == 0 else -1)


@rpc("authority", "call_local", "reliable")
func _retirar() -> void:
	esconderse(0.8)


@rpc("authority", "call_local", "reliable")
func terminar() -> void:
	activa = false
	visible = false
	_limpiar_ataques()
