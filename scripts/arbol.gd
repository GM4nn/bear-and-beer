extends StaticBody2D
## Los golpes confirmados por el servidor desprenden un palo cada tres contactos.
var ancho := 22.0
var alto_botella := 100.0
var golpes := 0
var _sacudida := 0.0


func _ready() -> void:
	add_to_group("golpeables")
	add_to_group("arboles_con_palos")


func golpeada(dir: int, quien: Node2D) -> void:
	if not multiplayer.is_server() or quien == null:
		return
	var fogata := get_tree().get_first_node_in_group("fogata_cooperativa")
	if fogata == null or not fogata.faltan_palos():
		return
	golpes += 1
	_sacudir.rpc(dir)
	if golpes >= 3:
		golpes = 0
		fogata.crear_palo(global_position + Vector2(dir * 42, 26))


@rpc("authority", "call_local", "reliable")
func _sacudir(dir: int) -> void:
	_sacudida = 0.3 * dir
	Audio.efecto("impacto", -8.0)


func _process(delta: float) -> void:
	_sacudida = move_toward(_sacudida, 0, delta)
	var arte := get_node_or_null("Arte") as Node2D
	if arte != null:
		arte.rotation = sin(_sacudida * 75) * absf(_sacudida) * 0.08
