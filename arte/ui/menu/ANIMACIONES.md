# Animaciones del fondo del menú

Se conservan los PNG base de Claude: `fondo.png`, `bolsa.png`, `silla.png` y `tronco.png`, con sus posiciones originales (2,104), (34,58) y (160,74) sobre el lienzo de 256×144.

- `tronco_anim/0.png` a `8.png`: animación que Claude ya había generado en PixelLab, recuperada del trabajo `4295a910-a907-47f7-bb8b-8a2d532abe8a`, galería `997e9dab-8662-520f-ad2d-a3c2b35ed1b6`. El cuadro 0 es el original. Se reproduce de ida y vuelta con pausas para descansar y beber; no se salta del último al primero.
- Sleeping: sprite completamente quieto, únicamente Z animadas. Silla: sprite quieto, sin respiración ni cabeceo; un hilito de baba crece desde la boca, forma una gota y cae antes de desaparecer. Se conservan los sprites originales.
- `ambiente.gdshader`: movimiento localizado sobre el fondo original; nubes centrales lentas, ondas horizontales y reflejo tenue en el agua, y llama con base fija. Usa la cuadrícula de 256×144 para evitar romper el tamaño del píxel.
- `scripts/fondo_menu.gd`: reloj local, reproducción, brasas y Z. No avanza mientras el fondo está oculto. Los cuadros antiguos de `fondo_anim` se conservan, pero ya no se superponen al paisaje al azar.

Se probaron generaciones nuevas para los dos personajes que descansan (`25deaaf1-4650-4ff3-affc-70979a6dcb9b` y `424b16e4-9f3d-4922-bedb-27b533f4e43c`); permanecieron bloqueadas y se cancelaron. No son dependencias del juego. La versión integrada usa los originales y animación por código.

Revisión: `godot --path . --script tests/vista_fondo_menu.gd -- --capturas`. Sin `--capturas` deja el menú funcionando para mirar los ciclos completos.
