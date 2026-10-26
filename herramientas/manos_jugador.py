"""Calcula dónde está la mano de enfrente en cada cuadro del jugador.

Busca la piel (naranja) más adelantada (mirando a la derecha) debajo de la
barbilla y escribe scripts/manos_jugador.gd con una tabla por animación, en
píxeles del lienzo de 180x180. jugador.gd la usa para poner el aguijón (u otra
arma) en la mano.

Uso: python herramientas/manos_jugador.py
"""
import os
import numpy as np
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CARPETA = os.path.join(RAIZ, "arte", "jugador")
SALIDA = os.path.join(RAIZ, "scripts", "manos_jugador.gd")
# Debajo de la barbilla y arriba de las rodillas.
FILAS = (70, 136)


def mano(ruta, anterior):
    a = np.array(Image.open(ruta).convert("RGBA")).astype(int)
    r, g, b, al = a[:, :, 0], a[:, :, 1], a[:, :, 2], a[:, :, 3]
    piel = (al > 0) & (r > 170) & (g > 90) & (g < 185) & (b < 125) & (r - b > 80)
    piel[:FILAS[0]] = False
    piel[FILAS[1]:] = False
    ys, xs = np.nonzero(piel)
    if len(xs) < 4:
        return anterior
    x = xs.max()
    # Centro del puño: la piel cercana a la punta.
    cerca = xs >= x - 6
    return (int(round(xs[cerca].mean())), int(round(ys[cerca].mean())))


tabla = {}
for anim in sorted(os.listdir(CARPETA)):
    ruta = os.path.join(CARPETA, anim)
    if not os.path.isdir(ruta) or not os.path.exists(os.path.join(ruta, "0.png")):
        continue
    puntos = []
    previo = (114, 100)
    n = 0
    while os.path.exists(os.path.join(ruta, "%d.png" % n)):
        previo = mano(os.path.join(ruta, "%d.png" % n), previo)
        puntos.append(previo)
        n += 1
    tabla[anim] = puntos

with open(SALIDA, "w", encoding="utf-8", newline="\n") as f:
    f.write("## Generado por herramientas/manos_jugador.py: mano de enfrente por cuadro\n")
    f.write("## (píxeles del lienzo de 180x180, mirando a la derecha).\n")
    f.write("const MANOS := {\n")
    for anim, puntos in tabla.items():
        f.write('\t"%s": [%s],\n' % (anim, ", ".join("Vector2(%d, %d)" % p for p in puntos)))
    f.write("}\n")
print("animaciones", len(tabla))
