extends Node2D
## Lee el estado replicado de la misión; las animaciones no deciden su avance.
const ARTE := preload("res://scripts/arte_objetos.gd")
var olla: Sprite2D
var papilla: AnimatedSprite2D
var rota: Sprite2D
var crias: Array[AnimatedSprite2D] = []
var _alimento_anterior := 0.0
var _comiendo := 0.0
var _susto_crias := 0.0
var _vida_anterior := 100
var _sacudida := 0.0
var _tiempo := 0.0


func _ready() -> void:
	var estacion := get_parent()
	for nombre in ["Piedras", "Fuego", "Papilla", "Osezno1", "Osezno2"]:
		estacion.get_node(nombre).hide()
	var fuego := ARTE.animado({"arder": "res://arte/zona1/fogata"}, 3, 8)
	add_child(fuego)
	add_child(load("res://scripts/fogata_visual.gd").new())
	olla = ARTE.estatico("olla", 1.5)
	olla.position.y = -18
	add_child(olla)
	papilla = ARTE.animado({"hervir": "res://arte/zona1/objetos/hervir"}, 1.5, 7)
	papilla.position.y = -18
	add_child(papilla)
	rota = ARTE.estatico("olla_rota", 1.5)
	add_child(rota)
	for i in range(2):
		var cria := ARTE.animado({"quieto": "res://arte/zona1/objetos/quieto",
			"comer": "res://arte/zona1/objetos/comer", "llorar": "res://arte/zona1/objetos/llorar"}, 1.5, 7)
		cria.position = Vector2(98 + i * 50, i * 6)
		cria.modulate = Color.WHITE if i == 0 else Color(0.88, 0.94, 1)
		add_child(cria)
		crias.append(cria)
		cria.set_frame_and_progress(i, 0.3)
	# El susto al fallar usa el mismo arte del jefe, sin otro enemigo ni daño.
	var mama: Node2D = estacion.get_node("MamaOsa")
	for parte in mama.get_children():
		if parte is ColorRect:
			parte.hide()
	var rugido := ARTE.animado({"rugido": "res://arte/mama_osa/fase3/rugido"}, 3, 9)
	rugido.flip_h = true
	mama.add_child(rugido)
	_actualizar(0)


func asustar() -> void:
	_susto_crias = 0.45


func _process(delta: float) -> void:
	_actualizar(delta)


func _actualizar(delta: float) -> void:
	var e := get_parent()
	_tiempo += delta
	_comiendo = maxf(_comiendo - delta, 0)
	_susto_crias = maxf(_susto_crias - delta, 0)
	_sacudida = maxf(_sacudida - delta, 0)
	if e.alimento > _alimento_anterior:
		_comiendo = 0.22
	_alimento_anterior = e.alimento
	if e.vida_olla < _vida_anterior:
		_sacudida = 0.25
	_vida_anterior = e.vida_olla
	var tiene_olla: bool = "olla" in e.entregadas()
	var cocinando: bool = e.completa() and (e.progreso > 0 or e.terminada or e.alimentados)
	olla.visible = tiene_olla and not cocinando and e.vida_olla > 0
	papilla.visible = cocinando and e.vida_olla > 0
	# El hervido se acelera al cocinar y queda suave cuando está lista.
	papilla.speed_scale = 1.0 if not e.terminada else 0.65
	rota.visible = tiene_olla and e.vida_olla <= 0
	olla.position.x = sin(_tiempo * 65) * 3 if _sacudida > 0 else 0
	papilla.position.x = olla.position.x
	var anim := "llorar" if e.alimentados or e._susto > 0 or _susto_crias > 0 else "comer" if _comiendo > 0 else "quieto"
	for cria in crias:
		if cria.animation != anim:
			cria.play(anim)
