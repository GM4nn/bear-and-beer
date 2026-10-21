# Audio de Bear and Beer

Todo lo que hay aquí lo genera `herramientas/componer_audio.py` (chiptune con
aire de mariachi: trompetas en terceras, vihuela rasgueada, guitarrón y maracas).
Para regenerarlo:

    python herramientas/componer_audio.py

## Poner tu propia música o efectos

Copia un `.ogg` o `.mp3` **con el mismo nombre** en la misma carpeta. El juego
lo prefiere sobre el `.wav` (orden: ogg, mp3, wav). No hay que tocar código.
Usa solo pistas con licencia libre (CC0 / CC-BY dando crédito).

| Archivo | Cuándo suena |
|---|---|
| `musica/menu` | Menú principal, opciones y sala |
| `musica/bosque` | Partida, mientras no está Mamá Osa |
| `musica/jefe` | Pelea con Mamá Osa |
| `musica/victoria` | Al ganar (no se repite) |
| `musica/derrota` | Al perder (no se repite) |
| `efectos/golpe` | El jugador conecta un golpe |
| `efectos/impacto` | El jugador recibe un golpe |
| `efectos/golpe_critico` | Golpe crítico del combo |
| `efectos/parada` | Parada exitosa (F) |
| `efectos/lanzar` | Lanzar botella |
| `efectos/botella_rompe` | Botella que se rompe |
| `efectos/tomar` | Empezar a beber |
| `efectos/eructo` | A veces, al terminar la chela |
| `efectos/vomito` | Vomitar |
| `efectos/recoger` | Recoger una chela |
| `efectos/caer` | Quedar tirado / golpe al piso de la osa |
| `efectos/chapuzon` | Meterse al lago / la osa entra o sale del agua |
| `efectos/abejas` | Zumbido de un enjambre persiguiendo (en bucle) |
| `efectos/rugido-oso` | Mamá Osa llega, ruge, embiste, cambia de fase o cae |
| `efectos/pisoton` | Pasos de la osa durante la embestida (se repite seguido mientras dura) |
| `efectos/osa_forcejeo_grunido` | Gruñido de la osa mientras forcejea con la abeja (se repite) |
| `efectos/abeja_zumbido` | Alas de la abeja musculosa mientras pelea con la osa (en bucle, de fondo) |
| `efectos/zarpazo` | Zarpazo de Mamá Osa |
| `efectos/torre_critico` | Crítico desde la torre en hombros |
| `efectos/click` | Botones de la interfaz |
