extends Node2D
## Decoración local: conserva los cuerpos y colisiones del bosque original.

const RUTA := "res://arte/zona1/%s.png"
const ATARDECER := preload("res://arte/zona1/atardecer.gdshader")
const ARTE := preload("res://scripts/arte_objetos.gd")
## Luz de atardecer en el bosque. Apagada: el usuario prefiere la luz de tarde
## original. Con true vuelven el filtro cálido y el lago malva.
const ATARDECER_ACTIVO := false
# Espacio a cada lado del rectángulo Lago/Agua que ocupan las playitas de entrada.
const MARGEN_PLAYAS := 160.0
var _arboles: Array[Sprite2D] = []
var _centro_lago := Vector2.ZERO
var _radio_lago := Vector2.ZERO
var _luz_calida: ShaderMaterial
var _azar := RandomNumberGenerator.new()
var _rayos: Array[Polygon2D] = []
## Árboles que se reparten (los del panal conservan el original).
const ARBOLES := ["arbol2", "arbol_encino", "arbol_pino", "arbol_jacaranda"]
## Especies de los árboles sin panal de la fila de la orilla, por turnos.
const ARBOLES_FILA := ["arbol_encino", "arbol_pino", "arbol_jacaranda"]
## Ancho del mundo que se decora (un poco más que los límites de la cámara).
const ANCHO_MUNDO := 7400.0
## Altura media de la orilla del bosque: arriba de ella ya no se camina.
const ORILLA := 238.0


func _ready() -> void:
	add_to_group("bosque")
	_luz_calida = _material_atardecer(2)
	for nodo in $Suelo.get_children():
		nodo.hide()
	_azar.seed = 20261018
	_poner_suelo()
	# Muro de árboles cercano en vez de montañas y cielo: el claro ocupa casi
	# toda la pantalla y el cielo apenas se asoma entre las copas.
	_capa("Muro", "muro_bosque", 0.7, 3, -160, -20)
	_poner_rayos()
	_poner_orilla()
	_poner_limite_arriba()
	# Los árboles van en el claro (bosque.tscn), parejos: uno arriba y otro abajo
	# del camino, alternando sin panal y con panal; los sin panal rotan de especie.
	var lisos := $Mundo.get_children().filter(func(o): return str(o.name).begins_with("Arbol") and not str(o.name).contains("Panal"))
	lisos.sort_custom(func(a, b): return a.position.x < b.position.x)
	for objeto in $Mundo.get_children():
		var nombre := str(objeto.name)
		if nombre.begins_with("Arbol"):
			var panal := nombre.contains("Panal")
			var imagen: String = "arbol2" if panal else ARBOLES_FILA[lisos.find(objeto) % ARBOLES_FILA.size()]
			var arbol := _vestir(objeto, imagen, 3)
			arbol.flip_h = int(objeto.position.x / 406.0) % 2 == 0
			_arboles.append(arbol)
		elif nombre.begins_with("Roca"):
			_vestir(objeto, ["roca", "roca2", "roca3"][nombre.to_int() % 3], 2)
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
	_poner_adornos()
	_poner_primer_plano()


## Altura de la orilla del bosque en cada x: ondulada, no recta. La usan el
## límite de arriba (física), los arbustos del fondo y los árboles de atrás.
static func orilla_bosque(x: float) -> float:
	return ORILLA + 20.0 * sin(x * 0.0027 + 0.4) + 11.0 * sin(x * 0.0083 + 1.7)


## Centro y medio ancho del camino de tierra. Copia de camino_centro y
## camino_ancho en arte/zona1/suelo.gdshader: si cambias una, cambia la otra.
static func camino_centro(x: float) -> float:
	var libre := clampf((absf(x - 5900.0) - 650.0) / 350.0, 0.0, 1.0)
	return 535.0 + libre * (60.0 * sin(x * 0.0019 + 0.6) + 28.0 * sin(x * 0.0051 + 2.0))


static func camino_ancho(x: float) -> float:
	return 44.0 + 9.0 * sin(x * 0.0033 + 1.3) + 5.0 * sin(x * 0.0091)


# El piso es un shader que dibuja en coordenadas del mundo: no se repite.
func _poner_suelo() -> void:
	var piso := ColorRect.new()
	piso.name = "Piso"
	piso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piso.position = Vector2(-2000, 190)
	piso.size = Vector2(11200, 610)
	var material := ShaderMaterial.new()
	material.shader = load("res://arte/zona1/suelo.gdshader")
	material.set_shader_parameter("origen", piso.position)
	material.set_shader_parameter("tamano", piso.size)
	piso.material = material
	$Suelo.add_child(piso)


# Rayos de sol que se cuelan entre los árboles. Van en la capa del muro para
# moverse con él; su brillo respira despacio (ver _process).
func _poner_rayos() -> void:
	var capa: Parallax2D = get_node("Muro")
	var luz := CanvasItemMaterial.new()
	luz.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var x := 120.0
	while x < capa.repeat_size.x:
		var rayo := Polygon2D.new()
		var grueso := _azar.randf_range(40, 90)
		var caida := _azar.randf_range(170, 240)
		rayo.polygon = PackedVector2Array([Vector2(0, -160), Vector2(grueso, -160),
			Vector2(grueso + caida, 250), Vector2(caida - grueso * 0.6, 250)])
		var color := Color(1, 0.95, 0.7, 0.16)
		rayo.vertex_colors = PackedColorArray([color, color, Color(color, 0), Color(color, 0)])
		rayo.material = luz
		rayo.position.x = x
		rayo.set_meta("fase", _azar.randf() * TAU)
		capa.add_child(rayo)
		_rayos.append(rayo)
		x += _azar.randf_range(260, 520)


# Matas a lo largo de la orilla ondulada: tapan el borde de arriba del piso y
# el pie del muro de árboles. Cada mata sigue la altura de la orilla en su x.
func _poner_orilla() -> void:
	var finas := [ARTE.hd(RUTA % "arbustos"), ARTE.hd(RUTA % "arbustos2")]
	var x := -300.0
	var i := 0
	while x < ANCHO_MUNDO + 300.0:
		var mata := Sprite2D.new()
		var fina: Array = finas[i % 2]
		mata.texture = fina[0]
		mata.material = _luz_calida
		mata.centered = false
		ARTE.escalar(mata, 2.0 / fina[1])
		mata.flip_h = _azar.randf() < 0.5
		var alto := mata.texture.get_height() * mata.scale.y
		mata.position = Vector2(x, orilla_bosque(x + 256.0) + 22.0 - alto)
		$Suelo.add_child(mata)
		x += _azar.randf_range(300, 420)
		i += 1 + int(_azar.randf() < 0.3)


# El límite de arriba sigue la orilla ondulada en vez de una línea recta.
func _poner_limite_arriba() -> void:
	var recto: CollisionShape2D = get_node_or_null("Limites/Arriba")
	if recto:
		recto.disabled = true
	var puntos := PackedVector2Array([Vector2(-200, -400)])
	var x := -200.0
	while x <= ANCHO_MUNDO + 200.0:
		puntos.append(Vector2(x, orilla_bosque(x) + 14.0))
		x += 40.0
	puntos.append(Vector2(ANCHO_MUNDO + 200.0, -400))
	var limite := CollisionPolygon2D.new()
	limite.name = "OrillaBosque"
	limite.polygon = puntos
	$Limites.add_child(limite)


# Decoración mexicana y matitas sueltas. Solo se ve: no estorba al caminar.
func _poner_adornos() -> void:
	# Campamento: papel picado sobre la carpa y la fogata, sillas, mesa y asador.
	for x in [60.0, 420.0]:
		_adorno("papel_picado", Vector2(x + 192, orilla_bosque(x) - 40), 3, false, $Suelo)
	_adorno("sillas", Vector2(330, 380), 2)
	_adorno("mesa", Vector2(660, 400), 2)
	_adorno("asador", Vector2(760, 395), 2)
	_adorno("hamaca", Vector2(980, orilla_bosque(980) + 30), 2)
	_adorno("troca", Vector2(2380, orilla_bosque(2380) + 34), 2)
	_adorno("sillas", Vector2(2600, orilla_bosque(2600) + 40), 2, true)
	# Nopales y magueyes: casi todos en la orilla y algunos sueltos en el claro.
	for n in 46:
		var px := _azar.randf_range(0, ANCHO_MUNDO)
		var en_orilla := _azar.randf() < 0.6
		var py := orilla_bosque(px) + _azar.randf_range(16, 40) if en_orilla else _azar.randf_range(300, 700)
		if _sobre_camino_o_lago(px, py, 40.0):
			continue
		_adorno(["nopal", "maguey"][n % 2], Vector2(px, py), 2.0 if en_orilla else 1.5, _azar.randf() < 0.5)
	# Matitas, flores y piedritas regadas por el pasto, pegadas al piso.
	var matitas: Array[String] = []
	for archivo in ResourceLoader.list_directory("res://arte/zona1/matitas"):
		if archivo.ends_with(".png"):
			matitas.append("matitas/" + archivo.get_basename())
	if matitas.is_empty():
		return
	for n in 240:
		var px := _azar.randf_range(-100, ANCHO_MUNDO)
		var py := _azar.randf_range(orilla_bosque(px) + 20, 715)
		if _sobre_camino_o_lago(px, py, 12.0):
			continue
		_adorno(matitas[_azar.randi() % matitas.size()], Vector2(px, py), 2, _azar.randf() < 0.5, $Suelo)


func _sobre_camino_o_lago(x: float, y: float, margen: float) -> bool:
	if absf(y - camino_centro(x)) < camino_ancho(x) + margen:
		return true
	return _radio_lago != Vector2.ZERO and ((Vector2(x, y) - _centro_lago) / (_radio_lago + Vector2(200, 40))).length() < 1.0


# Un dibujo suelto con la base en `pie`. En Mundo se ordena por profundidad.
func _adorno(imagen: String, pie: Vector2, escala: float, volteado := false, padre: Node = null) -> Sprite2D:
	var dibujo := Sprite2D.new()
	var fina := ARTE.hd(RUTA % imagen)
	dibujo.texture = fina[0]
	dibujo.material = _luz_calida
	ARTE.escalar(dibujo, escala / fina[1])
	dibujo.flip_h = volteado
	var limites := dibujo.texture.get_image().get_used_rect()
	dibujo.centered = false
	dibujo.offset = Vector2(-dibujo.texture.get_width() * 0.5, -limites.end.y)
	dibujo.position = pie
	(padre if padre else $Mundo).add_child(dibujo)
	return dibujo


# Siluetas oscuras de follaje delante de todo, abajo (como en Hollow Knight o
# Rayman): enmarcan la escena y se mueven más rápido que la cámara.
func _poner_primer_plano() -> void:
	var capa := Parallax2D.new()
	capa.name = "PrimerPlano"
	capa.scroll_scale = Vector2(1.3, 1)
	capa.z_index = 40
	add_child(capa)
	var formas: Array[Texture2D] = [load(RUTA % "arbustos"), load(RUTA % "arbustos2"), load(RUTA % "maguey"), load(RUTA % "nopal")]
	var x := -400.0
	while x < ANCHO_MUNDO * 1.3 + 400.0:
		var silueta := Sprite2D.new()
		var cual := _azar.randi() % formas.size()
		silueta.texture = formas[cual]
		silueta.centered = false
		silueta.modulate = Color(0.05, 0.1, 0.08, 0.96)
		silueta.scale = Vector2.ONE * (2.0 if cual < 2 else 3.0)
		silueta.flip_h = _azar.randf() < 0.5
		# Solo asoma la parte de arriba por el borde de la pantalla.
		var asoma := _azar.randf_range(40, 70) if cual < 2 else _azar.randf_range(60, 110)
		silueta.position = Vector2(x, 720 - asoma)
		capa.add_child(silueta)
		x += _azar.randf_range(500, 1100)


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
	# El agua recoge el cielo malva y los destellos dorados del atardecer.
	if ATARDECER_ACTIVO:
		_colores_lago_atardecer(material)
	agua.material = material
	$Lago/Texto.hide()
	$Lago/Forma.queue_free()
	_centro_lago = agua.global_position + centro
	_radio_lago = radio
	_poner_tulares()


func _colores_lago_atardecer(material: ShaderMaterial) -> void:
	material.set_shader_parameter("agua_lejos", Color("986777"))
	material.set_shader_parameter("agua_cerca", Color("384653"))
	material.set_shader_parameter("reflejo", Color("454950"))
	material.set_shader_parameter("brillo", Color("edb578"))
	material.set_shader_parameter("arena", Color("c18b58"))
	material.set_shader_parameter("arena_clara", Color("dda66b"))
	material.set_shader_parameter("arena_mojada", Color("946d54"))
	material.set_shader_parameter("tierra", Color("b67b46"))
	material.set_shader_parameter("piedrita", Color("737074"))


# Tulares en las esquinas de las dos playitas.
func _poner_tulares() -> void:
	var fina := ARTE.hd(RUTA % "tular")
	var textura: Texture2D = fina[0]
	for lado: float in [-1.0, 1.0]:
		for arriba: bool in [true, false]:
			var tular := Sprite2D.new()
			tular.texture = textura
			tular.material = _luz_calida
			ARTE.escalar(tular, 2.0 / fina[1])
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
	var fina := ARTE.hd(RUTA % imagen)
	var textura: Texture2D = fina[0]
	escala /= fina[1]
	var luz := _material_atardecer(0 if imagen == "montanas" else 1)
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
		fondo.material = luz
		fondo.centered = false
		ARTE.escalar(fondo, escala)
		fondo.position = Vector2(lado * ancho, alto)
		fondo.flip_h = lado == 1
		capa.add_child(fondo)


func _material_atardecer(capa: int) -> ShaderMaterial:
	# Sin atardecer no hay material: cada dibujo conserva sus colores originales.
	if not ATARDECER_ACTIVO:
		return null
	var material := ShaderMaterial.new()
	material.shader = ATARDECER
	material.set_shader_parameter("capa", capa)
	return material


func _vestir(objeto: Node2D, imagen: String, escala: float) -> Sprite2D:
	for hijo in objeto.get_children():
		if hijo is ColorRect or hijo is Label:
			hijo.hide()
	var dibujo := Sprite2D.new()
	dibujo.name = "Arte"
	var fina := ARTE.hd(RUTA % imagen)
	dibujo.texture = fina[0]
	dibujo.material = _luz_calida
	ARTE.escalar(dibujo, escala / fina[1])
	# Anclar la base visible, aunque el PNG tenga margen transparente.
	var limites := dibujo.texture.get_image().get_used_rect()
	dibujo.offset = Vector2(-dibujo.texture.get_width() * 0.5, -limites.end.y)
	dibujo.centered = false
	objeto.add_child(dibujo)
	return dibujo


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var ahora := Time.get_ticks_msec() / 1000.0
	for rayo in _rayos:
		rayo.modulate.a = 0.65 + 0.35 * sin(ahora * 0.5 + float(rayo.get_meta("fase")))
	# Las copas permiten ver al compa cuando pasa por detrás de un árbol.
	var jugadores := get_tree().get_nodes_in_group("jugadores")
	for arbol in _arboles:
		var tapa := false
		# Los árboles de adorno cuelgan directo de Mundo: su base es su posición.
		var base: Vector2 = arbol.global_position if arbol.get_parent() == $Mundo else arbol.get_parent().global_position
		for jugador in jugadores:
			var pies: Vector2 = jugador.global_position
			var cabeza := pies - Vector2(0, jugador.altura + 55)
			if pies.y < base.y and arbol.get_rect().has_point(arbol.to_local(cabeza)):
				tapa = true
				break
		arbol.modulate.a = move_toward(arbol.modulate.a, 0.38 if tapa else 1.0, delta * 4)
