extends Node
## Música y efectos de todo el juego (autoload "Audio").
##
## Cada sonido tiene un nombre fijo en arte/audio/musica o arte/audio/efectos.
## Los WAV los compone herramientas/componer_audio.py; si pones ahí un .ogg o
## .mp3 con el mismo nombre (por ejemplo musica/bosque.ogg), se usa ese.
##
## Los sonidos se disparan en cada pantalla desde código que ya corre en todos
## los jugadores (RPC call_local o propiedades sincronizadas), así cada quien
## escucha lo mismo sin mandar nada extra por la red.

const CARPETA := "res://arte/audio/%s/%s.%s"
const FORMATOS := ["ogg", "mp3", "wav"]
const CONFIG := "user://audio.cfg"
## Pistas que no se repiten al terminar.
const SIN_REPETIR := ["victoria", "derrota"]
const FUNDIDO := 1.2
const VOCES := 12

var _cache := {}
var _musicas: Array[AudioStreamPlayer] = []
var _actual := 0
var _pista := ""
var _voces: Array[AudioStreamPlayer] = []
var _siguiente_voz := 0
## Para no apilar el mismo efecto varias veces en el mismo instante.
var _ultimo := {}
var _seguidos := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Musica", "Efectos"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for i in 2:
		var musica := AudioStreamPlayer.new()
		musica.bus = "Musica"
		musica.volume_db = -80.0
		musica.finished.connect(_termino_musica.bind(musica))
		add_child(musica)
		_musicas.append(musica)
	for i in VOCES:
		var voz := AudioStreamPlayer.new()
		voz.bus = "Efectos"
		add_child(voz)
		_voces.append(voz)
	_cargar_volumenes()
	get_tree().node_added.connect(_nodo_agregado)


# Soltar los sonidos al cerrar para que Godot no avise de recursos sin liberar.
func _exit_tree() -> void:
	for reproductor in _musicas + _voces + _seguidos.values():
		reproductor.stop()
		reproductor.stream = null
	_cache.clear()


func _sonido(carpeta: String, nombre: String) -> AudioStream:
	var clave := carpeta + "/" + nombre
	if not _cache.has(clave):
		_cache[clave] = null
		for formato in FORMATOS:
			var ruta := CARPETA % [carpeta, nombre, formato]
			if ResourceLoader.exists(ruta):
				_cache[clave] = load(ruta)
				break
	return _cache[clave]


## Cambia la música con un fundido cruzado. Si ya suena esa pista, no hace nada.
func musica(nombre: String) -> void:
	if nombre == _pista:
		return
	_pista = nombre
	var anterior := _musicas[_actual]
	_actual = 1 - _actual
	var nueva := _musicas[_actual]
	var tween := create_tween().set_parallel()
	tween.tween_property(anterior, "volume_db", -80.0, FUNDIDO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var stream := _sonido("musica", nombre)
	if stream == null:
		return
	nueva.stream = stream
	nueva.volume_db = -30.0
	nueva.play()
	tween.tween_property(nueva, "volume_db", 0.0, FUNDIDO * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func pista_actual() -> String:
	return _pista


func _termino_musica(reproductor: AudioStreamPlayer) -> void:
	# Las pistas largas se repiten; los jingles se quedan en silencio.
	if reproductor == _musicas[_actual] and _pista not in SIN_REPETIR:
		reproductor.play()


## Reproduce un efecto. `volumen` en dB; el tono varía un poco para que los
## golpes repetidos no suenen idénticos.
func efecto(nombre: String, volumen := 0.0, variacion := 0.08) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - int(_ultimo.get(nombre, -1000)) < 40:
		return
	_ultimo[nombre] = ahora
	var stream := _sonido("efectos", nombre)
	if stream == null:
		return
	var voz := _voces[_siguiente_voz]
	_siguiente_voz = (_siguiente_voz + 1) % VOCES
	voz.stream = stream
	voz.volume_db = volumen
	voz.pitch_scale = randf_range(1.0 - variacion, 1.0 + variacion)
	voz.play()


## Como `efecto`, pero con una sola voz para ese nombre: cada vez corta al
## anterior. Sirve para pasos seguidos (los pisotones de la embestida) sin
## acaparar todas las voces.
func efecto_seguido(nombre: String, volumen := 0.0, variacion := 0.08) -> void:
	var stream := _sonido("efectos", nombre)
	if stream == null:
		return
	if not _seguidos.has(nombre):
		var voz := AudioStreamPlayer.new()
		voz.bus = "Efectos"
		add_child(voz)
		_seguidos[nombre] = voz
	var voz: AudioStreamPlayer = _seguidos[nombre]
	voz.stream = stream
	voz.volume_db = volumen
	voz.pitch_scale = randf_range(1.0 - variacion, 1.0 + variacion)
	voz.play()


## Sonido en bucle que se oye igual sin importar dónde esté la cámara.
func bucle(nodo: Node, nombre: String, volumen := 0.0) -> AudioStreamPlayer:
	var reproductor := AudioStreamPlayer.new()
	reproductor.bus = "Efectos"
	reproductor.stream = _sonido("efectos", nombre)
	reproductor.volume_db = volumen
	reproductor.finished.connect(reproductor.play)
	nodo.add_child(reproductor)
	return reproductor


## Sonido que se repite pegado a un nodo (el zumbido de un enjambre): se oye
## más fuerte cuanto más cerca está de la cámara.
func bucle_en(nodo: Node2D, nombre: String, volumen := 0.0) -> AudioStreamPlayer2D:
	var reproductor := AudioStreamPlayer2D.new()
	reproductor.bus = "Efectos"
	reproductor.stream = _sonido("efectos", nombre)
	reproductor.volume_db = volumen
	reproductor.max_distance = 900.0
	reproductor.finished.connect(reproductor.play)
	nodo.add_child(reproductor)
	return reproductor


# Todos los botones hacen "clic", también los que se crean después (pausa, resultados).
func _nodo_agregado(nodo: Node) -> void:
	if nodo is BaseButton:
		nodo.pressed.connect(efecto.bind("click", -6.0, 0.0))


# --- Volúmenes ("general", "musica", "efectos"), de 0 a 1 y guardados ---

const BUSES := {"general": "Master", "musica": "Musica", "efectos": "Efectos"}


func volumen(cual: String) -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUSES[cual])))


func cambiar_volumen(cual: String, valor: float) -> void:
	if not BUSES.has(cual) or not is_finite(valor):
		return
	valor = clampf(valor, 0.0, 1.0)
	var bus := AudioServer.get_bus_index(BUSES[cual])
	AudioServer.set_bus_volume_db(bus, linear_to_db(valor))
	AudioServer.set_bus_mute(bus, valor <= 0.001)
	var archivo := ConfigFile.new()
	archivo.load(CONFIG)
	archivo.set_value("volumen", cual, valor)
	archivo.save(CONFIG)


func _cargar_volumenes() -> void:
	var archivo := ConfigFile.new()
	var hay := archivo.load(CONFIG) == OK
	for cual in BUSES:
		# La música arranca un poco más baja que los efectos.
		var defecto := 0.7 if cual == "musica" else 1.0
		var valor: float = archivo.get_value("volumen", cual, defecto) if hay else defecto
		var bus := AudioServer.get_bus_index(BUSES[cual])
		AudioServer.set_bus_volume_db(bus, linear_to_db(valor))
		AudioServer.set_bus_mute(bus, valor <= 0.001)


## Agrega a unas Opciones los deslizadores de Música y Efectos, justo antes del
## hijo número `antes`. Se ponen al día cada vez que se muestran.
func agregar_deslizadores(padre: Container, antes: int, tamano_texto := 16) -> void:
	for cual in ["musica", "efectos"]:
		var texto := Label.new()
		texto.text = "Música" if cual == "musica" else "Efectos"
		texto.add_theme_font_size_override("font_size", tamano_texto)
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var deslizador := HSlider.new()
		deslizador.max_value = 1.0
		deslizador.step = 0.05
		deslizador.custom_minimum_size.y = 28
		deslizador.value = volumen(cual)
		deslizador.name = "Volumen_" + cual
		deslizador.value_changed.connect(func(valor): cambiar_volumen(cual, valor))
		deslizador.visibility_changed.connect(func():
			if deslizador.is_visible_in_tree():
				deslizador.set_value_no_signal(volumen(cual)))
		# Al soltar el de efectos suena un golpe de muestra.
		if cual == "efectos":
			deslizador.drag_ended.connect(func(_cambio): efecto("golpe"))
		padre.add_child(texto)
		padre.move_child(texto, antes)
		padre.add_child(deslizador)
		padre.move_child(deslizador, antes + 1)
		antes += 2
