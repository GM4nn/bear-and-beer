extends Node2D
## Punto del escenario al que los jugadores le pueden pegar (la olla, los
## oseznos). Solo avisa con una señal; quien lo usa decide qué pasa.

signal golpeado

## Medio ancho extra para que los golpes lo alcancen.
@export var ancho := 0.0
@export var alto_botella := 60.0


func _ready() -> void:
	add_to_group("golpeables")


func golpeada(_dir: int, _quien: Node2D) -> void:
	golpeado.emit()
