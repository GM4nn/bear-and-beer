extends Node2D
## Decoración local: conserva los cuerpos y colisiones del bosque original.

const RUTA := "res://arte/zona1/%s.png"
# Espacio a cada lado del rectángulo Lago/Agua que ocupan las playitas de entrada.
const MARGEN_PLAYAS := 160.0
var _arboles: Array[Sprite2D] = []
var _centro_lago := Vector2.ZERO
var _radio_lago := Vector2.ZERO


func _ready() -> void:
	add_to_group("bosque")
	for nodo in $Suelo.get_children():
		nodo.hide()
	_capa("Montanas", "montanas", 0.18, 3, -200, -30)
	_capa("BosqueDistante", "bosque_lejano", 0.48, 1.5, 180, -20)
	# Alternar el reflejo une exactamente los extremos de cada franja.
	for tramo in range(-1, 7):
		var suelo := Sprite2D.new()
		suelo.texture = load(RUTA % "suelo")
		suelo.centered = false
		suelo.scale = Vector2(3, 3)
		suelo.position = Vector2(tramo * 1536, 345)
		suelo.flip_h = posmod(tramo, 2) == 1
		$Suelo.add_child(suelo)
	# Franja de arbustos entre el bosque del fondo y el suelo: tapa el corte recto
	# y las rocas y raíces que la textura del suelo trae cortadas arriba. Los
	# tramos se enciman un poco para que no se vean huecos entre ellos.
	for tramo in range(-2, 12):
		var arbustos := Sprite2D.new()
		arbustos.texture = load(RUTA % "arbustos")
		arbustos.centered = false
		arbustos.scale = Vector2(3, 3)
		arbustos.position = Vector2(tramo * 750, 228)
		arbustos.flip_h = posmod(tramo, 2) == 1
		$Suelo.add_child(arbustos)
	for objeto in $Mundo.get_children():
		if str(objeto.name).begins_with("Arbol"):
			var arbol := _vestir(objeto, "arbol2", 3 if objeto.position.y < 480 else 2)
			arbol.flip_h = objeto.name.to_int() % 2 == 0
			_arboles.append(arbol)
		elif str(objeto.name).begins_with("Roca"):
			_vestir(objeto, "roca", 2)
	_vestir($Mundo/Carpa, "carpa", 3)
	_vestir($Mundo/HieleraVacia, "hielera", 2)
	var fogata_base := _vestir($Mundo/Fogata, "fogata", 3)
	fogata_base.hide()
	$Mundo/Fogata.add_child(preload("res://scripts/arte_objetos.gd").animado({"arder": "res://arte/zona1/fogata"}, 3, 8))
	for parte in ["Poste", "Tabla"]:
		$Mundo/Cartel.get_node(parte).hide()
	var cartel := preload("res://scripts/arte_objetos.gd").estatico("cartel", 2)
	$Mundo/Cartel.add_child(cartel)
	$Mundo/Cartel/Texto.z_index = 1
	$Mundo/Cartel/Texto.position = Vector2(-50, -80)
	$Mundo/Cartel/Texto.size = Vector2(100, 26)
	$Mundo/Cartel/Texto.add_theme_font_size_override("font_size", 14)
	var fuego: Node2D = load("res://scripts/fogata_visual.gd").new()
	fuego.name = "AnimacionFuego"
	$Mundo/Fogata.add_child(fuego)
	_vestir_lago()


# El agua la dibuja un shader con olas en movimiento, en forma de óvalo
# irregular, con una entradita de arena que baja hasta el camino. El lago no
# tiene colisión: los jugadores pueden meterse y nadan (ver dentro_del_lago).
func _vestir_lago() -> void:
	var agua: ColorRect = $Lago/Agua
	var centro := agua.size * 0.5
	var radio := Vector2(agua.size.x * 0.5 - MARGEN_PLAYAS, agua.size.y * 0.5 - 20.0)
	var material := ShaderMaterial.new()
	material.shader = load("res://arte/zona1/lago.gdshader")
	material.set_shader_parameter("tamano", agua.size)
	material.set_shader_parameter("centro_agua", centro)
	material.set_shader_parameter("radio_agua", radio)
	agua.material = material
	$Lago/Texto.hide()
	$Lago/Forma.queue_free()
	_centro_lago = agua.global_position + centro
	_radio_lago = radio
	_poner_tulares()


# Tulares en las esquinas de las dos playitas.
func _poner_tulares() -> void:
	var textura: Texture2D = load(RUTA % "tular")
	for lado: float in [-1.0, 1.0]:
		for arriba: bool in [true, false]:
			var tular := Sprite2D.new()
			tular.texture = textura
			tular.scale = Vector2(2, 2)
			tular.flip_h = lado > 0.0
			tular.offset.y = -textura.get_height() * 0.5
			var x := _centro_lago.x + lado * (_radio_lago.x + (40.0 if arriba else 10.0))
			var y := _centro_lago.y + (-_radio_lago.y * 0.55 if arriba else _radio_lago.y * 0.75)
			tular.position = Vector2(x, y)
			# Va en Mundo para ordenarse por profundidad con los personajes.
			$Mundo.add_child(tular)


## Lleva un punto que cae en el agua a la orilla más cercana (para Mamá Osa,
## que no nada). Si ya está fuera, lo devuelve igual.
func fuera_del_lago(punto: Vector2) -> Vector2:
	if not dentro_del_lago(punto):
		return punto
	var d := (punto - _centro_lago) / _radio_lago
	var angulo := atan2(d.y, d.x)
	return _centro_lago + _radio_lago * (forma_lago(angulo) + 0.08) * Vector2(cos(angulo), sin(angulo))


## Si un punto del suelo (los pies de alguien) está dentro del agua. Usa la
## misma forma que el dibujo, con un pequeño margen para no nadar en la arena.
func dentro_del_lago(punto: Vector2) -> bool:
	if _radio_lago == Vector2.ZERO:
		return false
	var d := (punto - _centro_lago) / _radio_lago
	return d.length() < forma_lago(atan2(d.y, d.x)) - 0.06


## Radio relativo del óvalo del lago según el ángulo. Es la misma fórmula que
## forma() en arte/zona1/lago.gdshader; si cambias una, cambia la otra.
static func forma_lago(angulo: float) -> float:
	return 0.97 + 0.035 * sin(3.0 * angulo + 0.7) + 0.02 * sin(7.0 * angulo + 2.1) \
		+ 0.012 * sin(13.0 * angulo + 4.0)


func _capa(nombre_capa: String, imagen: String, ritmo: float, escala: float, alto: float, profundidad: int) -> void:
	var capa := Parallax2D.new()
	capa.name = nombre_capa
	capa.scroll_scale = Vector2(ritmo, 1)
	capa.z_index = profundidad
	var textura: Texture2D = load(RUTA % imagen)
	if imagen == "montanas":
		# El generador dejó margen gris lateral: usar solo el paisaje del atlas.
		var recorte := AtlasTexture.new()
		recorte.atlas = textura
		recorte.region = Rect2(32, 0, 448, 192)
		textura = recorte
	var ancho := textura.get_width() * escala
	capa.repeat_size = Vector2(ancho * 2, 0)
	add_child(capa)
	for lado in range(2):
		var fondo := Sprite2D.new()
		fondo.texture = textura
		fondo.centered = false
		fondo.scale = Vector2.ONE * escala
		fondo.position = Vector2(lado * ancho, alto)
		fondo.flip_h = lado == 1
		capa.add_child(fondo)


func _vestir(objeto: Node2D, imagen: String, escala: float) -> Sprite2D:
	for hijo in objeto.get_children():
		if hijo is ColorRect or hijo is Label:
			hijo.hide()
	var dibujo := Sprite2D.new()
	dibujo.name = "Arte"
	dibujo.texture = load(RUTA % imagen)
	dibujo.scale = Vector2.ONE * escala
	# Anclar la base visible, aunque el PNG tenga margen transparente.
	var limites := dibujo.texture.get_image().get_used_rect()
	dibujo.offset = Vector2(-dibujo.texture.get_width() * 0.5, -limites.end.y)
	dibujo.centered = false
	objeto.add_child(dibujo)
	return dibujo


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# Las copas permiten ver al compa cuando pasa por detrás de un árbol.
	var jugadores := get_tree().get_nodes_in_group("jugadores")
	for arbol in _arboles:
		var tapa := false
		var base: Vector2 = arbol.get_parent().global_position
		for jugador in jugadores:
			var pies: Vector2 = jugador.global_position
			var cabeza := pies - Vector2(0, jugador.altura + 55)
			if pies.y < base.y and arbol.get_rect().has_point(arbol.to_local(cabeza)):
				tapa = true
				break
		arbol.modulate.a = move_toward(arbol.modulate.a, 0.38 if tapa else 1.0, delta * 4)
