extends Node
## Solo los contactos confirmados por el anfitrión hacen avanzar la secuencia.
const VENTANA := 0.95
const ANIMACIONES := ["golpear", "puno_izquierdo", "cabezazo", "patada"]
const IMPACTOS := [0.08, 0.10, 0.14, 0.16]
# Solo preparación hasta el contacto; no hay espera de recuperación entre golpes.
const ESPERAS := IMPACTOS
const MULTIPLICADORES := [1.0, 1.0, 1.4, 1.6]
const EFECTO := preload("res://scripts/impacto_comic.gd")
var paso := 0
var restante := 0.0
var objetivo: Node2D
var criticos := 0
var impactos := 0
var j: Node2D


func _ready() -> void:
	j = get_parent()
	set_multiplayer_authority(1)


func _physics_process(delta: float) -> void:
	if paso == 0:
		return
	restante -= delta
	if multiplayer.is_server() and (restante <= 0 or not is_instance_valid(objetivo) or not j.puede_actuar()):
		reiniciar()


func enemigo_valido(cosa: Node2D) -> bool:
	return cosa.is_in_group("jefe") and cosa.puede_recibir_golpe()


func contacto(tipo: int, cosa: Node2D) -> bool:
	if not multiplayer.is_server():
		return false
	if cosa == null or not enemigo_valido(cosa) or j.apoyo_id != 0 or j._torre().encima(j) != null:
		reiniciar()
		return false
	if tipo == 0:
		objetivo = cosa
		_estado.rpc(1)
	elif tipo == paso and objetivo == cosa and restante > 0:
		if tipo == 3:
			reiniciar()
			return true
		_estado.rpc(paso + 1)
	else:
		reiniciar()
	return false


func reiniciar() -> void:
	if multiplayer.is_server() and paso != 0:
		objetivo = null
		_estado.rpc(0)


@rpc("authority", "call_local", "reliable")
func _estado(nuevo: int) -> void:
	paso = nuevo
	restante = VENTANA if paso > 0 else 0.0


@rpc("authority", "call_local", "reliable")
func mostrar_impacto(donde: Vector2, tipo: int, critico: bool) -> void:
	impactos += 1
	Audio.efecto("golpe_critico" if critico else "golpe")
	if critico:
		criticos += 1
	var efecto := EFECTO.new()
	efecto.tipo = tipo
	efecto.critico = critico
	j.get_parent().get_parent().add_child(efecto)
	efecto.global_position = donde


func texto() -> String:
	if paso == 0:
		return ""
	return Controles.indicaciones(["", "1/4 · J/RT: puño izquierdo", "2/4 · K/L3: cabezazo", "3/4 · L/↓: ¡patada!"][paso])
