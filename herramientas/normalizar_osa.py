"""Copia las animaciones de Mamá Osa (PixelLab, lienzo 256x256) a arte/mama_osa/fase1..3.

Todas salen del mismo dibujo base: solo se corren en x para centrar el cuerpo
(al voltear no brinca). Las fases 2 y 3 son el mismo dibujo con el pelaje
cada vez más oscuro y rojizo (se enfurece); el gorrito, el delantal y la falda
no cambian. En mama_osa.gd, DESFASE_SPRITE pone la fila PIES en el origen.

Uso: python herramientas/normalizar_osa.py <carpeta_con_animaciones> [anim ...]
"""
import colorsys
import os
import sys
from PIL import Image

LIENZO = 256
# Centro del cuerpo del dibujo base (quieta, cuadro 0) en el lienzo de PixelLab.
CENTRO_ORIGINAL = int(os.environ.get("CENTRO_OSA", "128"))
DESTINO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "arte", "mama_osa")
# Fase -> (corrimiento de tono hacia el rojo, multiplicador de brillo, de saturación).
FASES = {1: (0.0, 1.0, 1.0), 2: (-0.015, 0.88, 1.08), 3: (-0.04, 0.78, 1.25)}


def pelaje(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return 0.025 <= h <= 0.13 and s >= 0.35 and 0.12 <= v <= 0.8, (h, s, v)


def furia(im, fase):
    corrimiento, brillo, saturacion = FASES[fase]
    if fase == 1:
        return im
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            es, (h, s, v) = pelaje(r, g, b)
            if es:
                nr, ng, nb = colorsys.hsv_to_rgb(max(h + corrimiento, 0.0), min(s * saturacion, 1), v * brillo)
                px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    return im


origen = sys.argv[1]
nombres = sys.argv[2:] or sorted(d for d in os.listdir(origen) if os.path.isdir(os.path.join(origen, d)))
for nombre in nombres:
    carpeta = os.path.join(origen, nombre)
    cuadros = sorted((f for f in os.listdir(carpeta) if f.endswith(".png")), key=lambda s: int(s[:-4]))
    for fase in FASES:
        salida = os.path.join(DESTINO, f"fase{fase}", nombre)
        os.makedirs(salida, exist_ok=True)
        for viejo in os.listdir(salida):
            if viejo.split(".")[0].isdigit():
                os.remove(os.path.join(salida, viejo))
        for i, f in enumerate(cuadros):
            im = Image.open(os.path.join(carpeta, f)).convert("RGBA")
            lienzo = Image.new("RGBA", (LIENZO, LIENZO))
            lienzo.alpha_composite(im, (LIENZO // 2 - CENTRO_ORIGINAL, 0))
            furia(lienzo, fase).save(os.path.join(salida, f"{i}.png"))
    print(nombre, len(cuadros))
