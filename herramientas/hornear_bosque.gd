extends SceneTree
## Guarda toda la decoración del bosque como nodos dentro de escenas/bosque.tscn,
## para verla y acomodarla en el editor de Godot (arrastrar, duplicar, borrar).
## Solo hace falta una vez (o para regenerar todo desde cero):
##   godot --headless --path . --script herramientas/hornear_bosque.gd
## Si la escena ya tiene decoración (nodo "Muro"), no hace nada.

const ESCENA := "res://escenas/bosque.tscn"


func _initialize() -> void:
	# Esperar a que carguen los autoloads (Audio, Controles…) antes de abrir la escena.
	call_deferred("_hornear")


func _hornear() -> void:
	# Se reempaca el mismo recurso para conservar su identificador (uid).
	var escena: PackedScene = load(ESCENA)
	var bosque: Node2D = escena.instantiate()
	if bosque.has_node("Muro"):
		print("La escena ya tiene la decoración; no se toca.")
		quit()
		return
	# Sin meterla al árbol de escena: así ningún otro script modifica nada.
	bosque._azar.seed = 20261018
	var antes := _todos(bosque)
	bosque.crear_decorado()
	# Árbol alto de los oseznos, como nodo normal del bosque.
	var rescate: Node2D = load("res://escenas/arbol.tscn").instantiate()
	rescate.name = "ArbolRescate"
	rescate.position = load("res://scripts/rescate_oseznos.gd").SITIO
	bosque.get_node("Mundo").add_child(rescate)
	bosque._vestir(rescate, "arbol_rescate", 1.0)
	# Todo lo nuevo pasa a ser parte de la escena.
	var nuevos := 0
	for nodo in _todos(bosque):
		if nodo not in antes:
			nodo.owner = bosque
			nuevos += 1
	var error := escena.pack(bosque)
	if error == OK:
		error = ResourceSaver.save(escena, ESCENA)
	print("Decoración guardada en la escena: %d nodos nuevos (error %d)" % [nuevos, error])
	bosque.free()
	quit(error)


func _todos(nodo: Node) -> Array:
	var lista := [nodo]
	for hijo in nodo.get_children():
		lista.append_array(_todos(hijo))
	return lista
