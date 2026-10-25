"""Borra las piernas del que va sentado en hombros.

Las piernas del de arriba ya vienen dibujadas en la animación de quien lo carga
(colgando al frente del pecho, sostenidas con las manos). En los cuadros del que
va sentado se borran los muslos que van hacia adelante (desde la fila MUSLOS y la
columna FRENTE) y todo lo de la fila FONDO para abajo, para que no salgan dobles.
Las pompas y la cadera se quedan, detrás de la cabeza del que carga (ver
ALTURA_HOMBROS en torre.gd).

Uso: python herramientas/cortar_piernas_jinete.py [anim ...]
"""
import os
import sys
from PIL import Image

CARPETA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "arte", "jugador")
MUSLOS = 108
FRENTE = 89
FONDO = 117
ANIMS = sys.argv[1:] or ["hombros_quieto", "hombros_golpear", "hombros_cargar", "hombros_cargar_golpear"]

for anim in ANIMS:
    ruta = os.path.join(CARPETA, anim)
    n = 0
    for f in os.listdir(ruta):
        if f.endswith(".png") and f[:-4].isdigit():
            im = Image.open(os.path.join(ruta, f)).convert("RGBA")
            px = im.load()
            for y in range(MUSLOS, im.height):
                for x in range(im.width):
                    if y >= FONDO or x >= FRENTE:
                        px[x, y] = (0, 0, 0, 0)
            im.save(os.path.join(ruta, f))
            n += 1
    print(anim, n)
