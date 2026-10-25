extends Node2D
## Botín único de la musculosa: 20 s de golpes con aguijón, sin acumular bonos.
const DURACION := 20.0
var disponible := true
var restante := 45.0
var etiqueta: Label

func _ready() -> void:
	add_to_group("armas_temporales")
	etiqueta = Label.new()
	etiqueta.position = Vector2(-140, -60)
	etiqueta.size.x = 280
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 13)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(etiqueta)

func _process(_delta: float) -> void:
	etiqueta.text = "AGUIJÓN · %s · 20s" % Controles.tecla("agarrar")

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or not disponible:
		return
	restante -= delta
	if restante <= 0:
		_retirar.rpc()

func recoger(j: Node2D) -> bool:
	if not multiplayer.is_server() or not disponible or not j.puede_actuar() or j.altura > 12 or j.position.distance_to(position) > 44:
		return false
	j.arma_tiempo = DURACION
	_retirar.rpc()
	return true

@rpc("authority", "call_local", "reliable")
func _retirar() -> void:
	disponible = false
	queue_free()

func _draw() -> void:
	# Indicador sencillo del botín; no modifica las animaciones de Claude.
	draw_circle(Vector2.ZERO, 18, Color("2b160b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -4), Vector2(9, -30), Vector2(4, -5), Vector2(14, -5), Vector2(-7, 12)]), Color("ffcf33"))
