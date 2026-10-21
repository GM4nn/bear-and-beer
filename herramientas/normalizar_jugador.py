"""Copia las animaciones del jugador (PixelLab, lienzo 180x180) a arte/jugador.

Todas salen del mismo dibujo base, así que comparten lugar en el lienzo: solo
se corren en x para que el cuerpo quede centrado (al voltear el sprite no
brinca) y los pies quedan en la fila PIES. En jugador.gd, DESFASE_SPRITE pone
esa fila en el origen del nodo.

Uso: python herramientas/normalizar_jugador.py <carpeta_con_animaciones> [anim ...]
(cada animación en <carpeta>/<anim>/<n>.png). Sin nombres copia todas.
"""
import os
import sys
from PIL import Image

LIENZO = 180
PIES = 153
# Centro del cuerpo del dibujo base (quieto, cuadro 0) en el lienzo de PixelLab.
CENTRO_ORIGINAL = 87
DESTINO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "arte", "jugador")

origen = sys.argv[1]
nombres = sys.argv[2:] or sorted(d for d in os.listdir(origen) if os.path.isdir(os.path.join(origen, d)))
for nombre in nombres:
    carpeta = os.path.join(origen, nombre)
    cuadros = sorted((f for f in os.listdir(carpeta) if f.endswith(".png")), key=lambda s: int(s[:-4]))
    salida = os.path.join(DESTINO, nombre)
    os.makedirs(salida, exist_ok=True)
    # Quitar los cuadros viejos (y sus .import) para no mezclar tamaños.
    for viejo in os.listdir(salida):
        if viejo.split(".")[0].isdigit():
            os.remove(os.path.join(salida, viejo))
    for i, f in enumerate(cuadros):
        im = Image.open(os.path.join(carpeta, f)).convert("RGBA")
        lienzo = Image.new("RGBA", (LIENZO, LIENZO))
        lienzo.alpha_composite(im, (LIENZO // 2 - CENTRO_ORIGINAL, 0))
        lienzo.save(os.path.join(salida, f"{i}.png"))
    print(nombre, len(cuadros))
