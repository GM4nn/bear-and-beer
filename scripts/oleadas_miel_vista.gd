extends CanvasLayer
var titulo: Label
var aviso: Label
var barra: ProgressBar
## Con la reina suena la música de jefe; al terminar vuelve la del bosque.
var _con_reina := false

func _ready() -> void:
	layer = 7
	var raiz := Control.new()
	raiz.theme = TemaUI.tema()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	titulo = Label.new()
	titulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	titulo.position = Vector2(-450, 96)
	titulo.size = Vector2(900, 36)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", Color("ffe59b"))
	titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	titulo.add_theme_constant_override("outline_size", 6)
	raiz.add_child(titulo)
	barra = ProgressBar.new()
	barra.position = Vector2(-220, 135)
	barra.size = Vector2(440, 18)
	barra.set_anchors_preset(Control.PRESET_CENTER_TOP)
	barra.show_percentage = false
	raiz.add_child(barra)
	aviso = Label.new()
	aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	aviso.position = Vector2(-430, 175)
	aviso.size = Vector2(860, 70)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 18)
	aviso.add_theme_color_override("font_color", Color("ffdb65"))
	aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	aviso.add_theme_constant_override("outline_size", 7)
	raiz.add_child(aviso)

func _process(_delta: float) -> void:
	var evento := get_parent()
	var reina: bool = evento.activa() and evento.ola == evento.OLA_REINA
	if reina != _con_reina:
		_con_reina = reina
		Audio.musica("jefe" if reina else "bosque")
	visible = evento.is_visible_in_tree() and not evento.partida().finalizada and (evento.habilitada() or evento.activa())
	titulo.text = evento.mensaje
	if evento.estado == "combate" and evento.ola < evento.OLA_REINA:
		titulo.text += " · quedan %d" % evento.restantes()
	elif evento.estado == "combate" and evento.restantes() > 1:
		titulo.text += " · fase %d/3 · escoltas %d" % [evento.enemigos[0].fase, evento.restantes() - 1]
	barra.visible = evento.activa() and evento.ola == evento.OLA_REINA
	if barra.visible:
		barra.max_value = evento.enemigos[0].vida_max
		barra.value = evento.enemigos[0].vida
	var id := multiplayer.get_unique_id()
	aviso.visible = evento.pegados.has(id)
	if aviso.visible:
		aviso.text = "¡EMPAPADO DE MIEL!\nAlterna %s y %s para soltarte  %d/%d" % [Controles.tecla("izquierda").get_slice(" / ", 0), Controles.tecla("derecha").get_slice(" / ", 0), evento.pegados[id].pasos, evento.SACUDIDAS]
