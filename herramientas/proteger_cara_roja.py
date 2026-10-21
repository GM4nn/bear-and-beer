"""Evita que el shader del color del jugador pinte la cara roja de borracho.

color_jugador.gdshader cambia los rojos saturados (los de la playera) por el
color de cada jugador. Las caras rojas de borracho y los cachetes caen en ese
mismo rango. Aquí se separan los rojos en manchas conectadas: las de la
playera están rodeadas de contorno oscuro y de la franja blanca, mientras que
las de la cara se funden con la piel. Las manchas que tocan mucha piel se
corren un poco hacia el naranja, fuera del rango del shader.

Uso: python herramientas/proteger_cara_roja.py anim [anim ...]
"""
import colorsys
import os
import sys
from PIL import Image

CARPETA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "arte", "jugador")
# Parte del borde de una mancha roja que debe ser piel para considerarla cara.
PIEL_MINIMA = 0.3


def hsv(p):
    return colorsys.rgb_to_hsv(p[0] / 255, p[1] / 255, p[2] / 255)


def rojo_del_shader(p):
    h, s, v = hsv(p)
    return p[3] > 0 and (h < 0.03 or h > 0.93) and s > 0.5 and v > 0.25


def piel(p):
    h, s, v = hsv(p)
    return p[3] > 0 and 0.03 <= h <= 0.12 and 0.3 <= s <= 0.85 and v > 0.45


def proteger(im):
    px = im.load()
    w, h = im.size
    visto = set()
    cambiados = 0
    for y in range(h):
        for x in range(w):
            if (x, y) in visto or not rojo_del_shader(px[x, y]):
                continue
            mancha, pila, borde_piel, borde = [], [(x, y)], 0, 0
            visto.add((x, y))
            while pila:
                cx, cy = pila.pop()
                mancha.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if not (0 <= nx < w and 0 <= ny < h):
                        continue
                    q = px[nx, ny]
                    if rojo_del_shader(q):
                        if (nx, ny) not in visto:
                            visto.add((nx, ny))
                            pila.append((nx, ny))
                    else:
                        borde += 1
                        borde_piel += piel(q)
            if borde and borde_piel / borde >= PIEL_MINIMA:
                for mx, my in mancha:
                    r, g, b, a = px[mx, my]
                    _, s, v = hsv((r, g, b, a))
                    nr, ng, nb = colorsys.hsv_to_rgb(0.04, s, v)
                    px[mx, my] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
                cambiados += len(mancha)
    return cambiados


for anim in sys.argv[1:]:
    ruta = os.path.join(CARPETA, anim)
    total = 0
    for f in os.listdir(ruta):
        if f.endswith(".png") and f[:-4].isdigit():
            im = Image.open(os.path.join(ruta, f)).convert("RGBA")
            total += proteger(im)
            im.save(os.path.join(ruta, f))
    print(anim, total, "pixeles")
