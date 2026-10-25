"""Recorta la osa gigante de la ultra fase a la altura del moño y desvanece su
parte de abajo, para que se funda con el bosque.
Uso: python herramientas/difuminar_osa_ultra.py entrada.png salida.png [...]
"""
import sys
from PIL import Image
CORTE = 206      # fila del dibujo (512x256) donde termina
DESVANECE = 46   # filas en las que pasa de opaca a invisible
def difuminar(ruta_in, ruta_out):
    im = Image.open(ruta_in).convert("RGBA").crop((0, 0, 512, CORTE))
    px = im.load()
    for y in range(CORTE - DESVANECE, CORTE):
        f = (CORTE - y) / DESVANECE
        f = f * f * (3 - 2 * f)
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, round(a * f))
    im.save(ruta_out)
for i in range(1, len(sys.argv), 2):
    difuminar(sys.argv[i], sys.argv[i + 1])
