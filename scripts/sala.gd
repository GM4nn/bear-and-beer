extends VBoxContainer
## Sala de espera: cada jugador elige su color (su personaje provisional) y
## marca que está listo; el anfitrión empieza cuando todos lo están.

const Jugador := preload("res://scripts/jugador.gd")

var _botones_color: Array[Button] = []

@onready var info: Label = $Info
@onready var lugares: GridContainer = $Lugares
@onready var colores: HBoxContainer = $Colores
@onready var listo: Button = $Listo
@onready var empezar: Button = $Empezar


func _ready() -> void:
	for i in Jugador.COLORES.size():
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(48, 48)
		for estado in ["normal", "hover", "pressed", "disabled"]:
			var caja := StyleBoxFlat.new()
			caja.bg_color = Jugador.COLORES[i]
			if estado == "disabled":
				caja.bg_color.a = 0.2
			caja.set_corner_radius_all(6)
			boton.add_theme_stylebox_override(estado, caja)
		boton.pressed.connect(Red.pedir_color.bind(i))
		colores.add_child(boton)
		_botones_color.append(boton)

	listo.toggled.connect(Red.pedir_listo)
	empezar.pressed.connect(Red.iniciar_partida)
	Red.jugadores_cambiaron.connect(_actualizar)
	visibility_changed.connect(_actualizar)


func _actualizar() -> void:
	if not is_visible_in_tree():
		return
	var mi_id := multiplayer.get_unique_id()
	var yo: Dictionary = Red.jugadores.get(mi_id, {})

	for hijo in lugares.get_children():
		hijo.queue_free()
	var ids := Red.jugadores.keys()
	ids.sort()
	for n in Red.MAX_JUGADORES:
		lugares.add_child(_lugar(ids[n] if n < ids.size() else 0, mi_id))

	var usados := Red.jugadores.values().map(func(j): return j.color)
	for i in _botones_color.size():
		var es_mio: bool = yo.get("color", -1) == i
		_botones_color[i].disabled = i in usados and not es_mio
		_botones_color[i].text = "TÚ" if es_mio else ""

	listo.set_pressed_no_signal(yo.get("listo", false))
	listo.text = "¡Listo! (clic para cancelar)" if listo.button_pressed else "Estoy listo"

	empezar.visible = multiplayer.is_server()
	empezar.disabled = not Red.todos_listos()
	empezar.text = "Empezar partida" if Red.todos_listos() else "Faltan jugadores por estar listos"
	if multiplayer.is_server():
		info.text = "Tus amigos se unen con esta IP: %s" % Red.ip_local()
	else:
		info.text = "Esperando a que el anfitrión empiece la partida"


func _lugar(id: int, mi_id: int) -> Control:
	var caja := VBoxContainer.new()
	caja.custom_minimum_size = Vector2(160, 0)
	var retrato := Control.new()
	retrato.custom_minimum_size = Vector2(80, 100)
	retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var nombre := Label.new()
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var estado := Label.new()
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estado.modulate.a = 0.7

	if id == 0:
		var vacio := Label.new()
		vacio.text = "+"
		vacio.position = Vector2(28, 24)
		vacio.add_theme_font_size_override("font_size", 34)
		vacio.modulate.a = 0.25
		retrato.add_child(vacio)
		nombre.text = "Vacío"
	else:
		var datos: Dictionary = Red.jugadores[id]
		var compa := AnimatedSprite2D.new()
		compa.sprite_frames = Jugador._cuadros_compartidos()
		compa.offset = Jugador.DESFASE_SPRITE
		compa.position = Vector2(40, 92)
		compa.scale = Vector2(3, 3)
		var tinte := ShaderMaterial.new()
		tinte.shader = Jugador.SHADER_COLOR
		tinte.set_shader_parameter("color_jugador", Jugador.COLORES[datos.color])
		compa.material = tinte
		compa.play("quieto")
		retrato.add_child(compa)
		nombre.text = datos.nombre + (" (tú)" if id == mi_id else "")
		estado.text = "Listo" if datos.listo else "Eligiendo..."

	caja.add_child(retrato)
	caja.add_child(nombre)
	caja.add_child(estado)
	return caja
