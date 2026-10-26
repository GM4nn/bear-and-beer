# Pruebas del combate y la supervivencia

## Círculo compartido y validación del borde — 25/10/2026

Todos ven el mismo círculo azul y trayectoria; cada jugador mantiene su propia entrada y un fallo sigue derribando al equipo. `rescate_circulo.gd`: **16 comprobaciones aprobadas**, igualdad entre seis puestos, interior y contorno válidos, exterior inválido, seis objetivos de ambos oseznos con muestras a 20 Hz y retrasos simulados de 0/120/250 ms, relojes inválidos y transición de cuenta atrás a trazado. Reproduce los falsos rechazos del antiguo desfase de 80 ms.

`rescate_red.gd -- --host --puerto=7982 --borde` y dos clientes con `--join --puerto=7982 --borde`: **37 comprobaciones aprobadas** con conexiones ENet reales locales. Los tres inyectan clic y movimiento cerca del borde, lejos del punto blanco, y completan ambos oseznos; también se comprueban fallo individual, nombre replicado, pausa, guardado y desconexión. Registros `user://logs/rescate_circulo.log` y `rescate_borde_final_{0,1,2}.log`, sin errores de script. El retraso se simula en la prueba de muestras; la prueba ENet no reproduce las condiciones de Internet.

## Nombre de quien falla el rescate — 25/10/2026

`rescate_red.gd` comprueba además el nombre del cliente que suelta el clic, el de quien sale de la trayectoria, los nombres de quienes no completan el seguimiento mínimo y la coincidencia del aviso en ambos clientes. **37 comprobaciones aprobadas**, registros `user://logs/rescate_nombre_{0,1,2}.log`, con tres conexiones ENet y nombres distintos (`--nombre=Tono`, `--nombre=Luna`, `--nombre=Paco`). Las interrupciones ajenas al mouse conservan su aviso general. El ejecutable actualizado se exportó y arrancó con salida 0.

## Oleadas de miel y reina — 25/10/2026

`miel_red.gd`: un anfitrión y dos clientes ENet, todos con el mismo script y puerto, sin `--auto`. Para seis, un host y cinco clientes con `--cantidad=6` en todos. **42 comprobaciones aprobadas con tres y 42 con seis**: señuelo y premio separados, olla como precondición, todo el equipo cerca/vivo, tres oleadas, dos fusiones, reina después de la tercera, daño real de ambos puños y suelo, salto/parada, proyectil de miel, escape A/D con entradas reales del cliente, rechazo de entradas antiguas/repetidas/imposibles/pausadas, inmunidad temporal, muerte, críticos H/J/K/L, botellas, compazo, premio sincronizado, guardado y desconexión.

```powershell
godot --headless --max-fps 60 --path . --script tests/miel_red.gd -- --host --puerto=7977
godot --headless --max-fps 60 --path . --script tests/miel_red.gd -- --join=127.0.0.1 --puerto=7977
# Ejecutar el comando de cliente en dos terminales distintas.
```

Registros: `user://logs/miel_validada_{0,1,2}.log`, `miel_seis_{0,1,2,3,4,5}.log`. Regresiones: **37 de fogata/cocina** (`miel_regresion_fogata_final_*.log`) y **25 de la búsqueda de olla actual** (`miel_regresion_olla_*.log`). Pruebas locales; no simulan pérdida de paquetes ni latencia de Internet. Se usa y elimina `miel_prueba.cfg`, sin escribir en la ranura personal.

Pelea libre de tres bots (`miel_bots_final.log`): completaron las tres oleadas y llegaron a la reina, que los derrotó. Esto verifica el recorrido de su IA sin forzar bajas ni curarlos; **no demuestra una victoria autónoma ni sustituye ajustar la dificultad con jugadores humanos**. Los tests deterministas anteriores sí verifican la derrota de la reina, recompensa y continuación de la misión.

Demo manual con dos bots: `godot --path . --script tests/jugar_miel.gd -- --puerto=7978`. Empieza con rescate, fuego y olla resueltos, junto al lago. Añadir `--reina` para probar solo el miniboss. `--captura` guarda `user://miel_reina.png`, `miel_vuelo.png` y `miel_empapado.png`, y cierra sus procesos; se revisaron posición de pies, peluca, aviso de caída, recubrimiento de miel y ausencia de avisos superpuestos. `--auto-prueba` hace jugar al anfitrión como tercer bot, sin vida infinita ni daño especial, y registra el resultado de la pelea completa.

## Búsqueda de la olla — 25/10/2026

`olla_red.gd`: un host y dos clientes, todos con este script, mismo puerto, sin `--auto`. Para seis jugadores, lanzar un host y cinco clientes con `--cantidad=6` en todos. Verifica entrada E individual de todo el equipo, bloqueo previo al rescate/fuego y con un caído, olla oculta, cursores inválidos o de intentos anteriores, selección superior y propiedad exclusiva, arrastre y depósito, participación mínima de todos, pausa, guardado pendiente/completado, aviso de pila, derrumbe, daño a brazos/manos expuestos, reocultación, salida, éxito con entrada real de mouse, desbloqueo replicado, transporte y desconexión.

**25 comprobaciones aprobadas con tres y 25 con seis**, registros `user://logs/olla_final_{0,1,2}.log` y `olla_seis_final_{0,1,2,3,4,5}.log`, sin errores de script. Con renderizador y `--captura` guarda `user://olla_interior.png`; se revisó el interior con seis pares de manos. Son pruebas locales ENet.

Demo manual: `godot --path . --script tests/jugar_olla.gd -- --puerto=7962`. Abre una ventana con humano + dos bots junto a la tienda, rescate y fuego ya completados. Pulsa E para entrar, arrastra con clic izquierdo sostenido y suelta para aventar; al destapar la olla, llévala a SALIDA. La opción `--auto-prueba` después de `--` hace que también el anfitrión juegue como bot, valida el éxito y cierra las tres instancias; aprobó con `RESULTADO BOTS OLLA: todos entraron y sacaron la olla` (`olla_bots.log`). Las pruebas usan y eliminan `olla_prueba.cfg`, sin tocar la ranura personal.

## Equipo completo obligatorio (25/10/2026)

El rescate consulta el registro completo de jugadores, incluidos caídos y bots. Con 2–3 jugadores todos suben; con 4–6 hay tres en la torre y el resto juega junto al árbol desde el suelo. No arranca si alguien falta o necesita reanimación. La composición del equipo se comprueba durante todo el intento. Guardar/cargar limpia tanto participantes como integrantes de la torre.

`rescate_red.gd` añade el caso reportado: tres conectados, uno caído y una torre de dos; rechaza el inicio, permite reanimar y exige reunir a los tres. `rescate_equipo.gd` comprueba partidas reales de **2 y 6 procesos**, con `--cantidad=2` o `--cantidad=6` en todos, un `--host` y los demás `--join=127.0.0.1`, mismo puerto y sin `--auto`. Con seis verifica compañero lejano, caído, participación desde el suelo, fallo individual que derriba la torre, arañazo al de la cima y éxito de todo el equipo.

Resultado: **43 comprobaciones aprobadas** (33 con tres jugadores, 7 con seis y 3 con dos), sin errores de script en los registros finales `user://logs/rescate_todos_validado_*.log`, `rescate_seis_*.log` y `rescate_dos_*.log`. Validación en red local.

## Dificultad y segundo osezno (25/10/2026)

El primer rescate tiene objetivos un poco más rápidos y estrechos. El segundo cambia la secuencia y dirección, añade curvas en S y aumenta velocidad/precisión. `rescate_red.gd`: **30 comprobaciones aprobadas**, incluyendo diferencias de recorrido y dificultad, completar ambos rescates, cargar antes del segundo, pausa y caída conjunta. `rescate_bot.gd`: **4 aprobadas**, ambos oseznos con dos bots. Registros `user://logs/rescate_dificultad_{0,1,2}.log` y `rescate_dificultad_bots_{0,1,2}.log`, sin errores de script. Pruebas en red local.

Prueba jugable: `godot --path . --script tests/jugar_rescate.gd -- --puerto=7946`. Prepara miel y dos bots junto al árbol. Esperar a que se forme la torre y pulsar E; mantener clic izquierdo dentro del círculo grande (incluido su contorno). El segundo se inicia con E tras completar el primero.

## Rescate de ritmo con mouse (24/10/2026)

`rescate_red.gd` mantiene los tres procesos ENet sin `--auto` (uno `--host`, dos `--join=127.0.0.1`, mismo puerto). Ahora inyecta eventos de mouse en coordenadas locales del viewport: **28 comprobaciones aprobadas**, incluidos clic sostenido, todos los tipos de objetivo, un solo cliente soltando mientras los demás aciertan, salida del recorrido con clic pulsado, caída de toda la torre, pausa/reintento, autoridad, guardado, daño y desconexión. Las consultas esperan convergencia de las réplicas, sin exigir orden entre canales. Registros: `user://logs/ritmo_validado_{0,1,2}.log`. Con `--capturas` y renderizador, añade `rescate_curva.png` para revisar un deslizador en marcha.

`rescate_bot.gd` usa el mismo arranque que antes: host con script y dos clientes normales `--auto --bot-torre --bot-turno=1/2`. El humano de prueba envía mouse y los bots completan sus propios objetivos. **4 comprobaciones aprobadas**, registro `user://logs/ritmo_bots_0.log`. Total de esta revisión: **32**, sin errores del motor en los logs finales. El test de rescate usa `rescate_prueba.cfg`, que elimina al terminar; no escribe la ranura personal.

### Registro anterior del equilibrio con teclas


`rescate_red.gd`: tres procesos ENet con el mismo puerto, sin `--auto`, uno `--host` y dos `--join=127.0.0.1`. El anfitrión inicia al entrar los tres. **24 comprobaciones aprobadas**: altura de rama, bloqueo previo de fuego/palos, miel recuperable, torres de dos/tres, E desde un pasajero, salto individual, pausa, combate bloqueado, entradas inválidas o de espectadores, miedo por falta de corrección, arañazo únicamente al de arriba, reintentos, éxito usando entradas de teclado en cada peer, réplica del progreso, guardado en archivo de prueba y restauración, desbloqueo tras el segundo, cancelación por daño y desconexión. Registros `user://logs/rescate_final_{0,1,2}.log`; tres salidas 0. Con renderizador y `--capturas` guarda `rescate_torre.png` y `rescate_completo.png` en `user://`.

`rescate_bot.gd`: anfitrión con este script y `--host`, dos clientes normales con `--auto --bot-torre --bot-turno=1` y `--bot-turno=2`. Acorta el viaje hasta el árbol para probar recogida/ofrenda de miel, subida real con salto/E y equilibrio de los bots junto al humano. No usa montajes directos para formar esa torre. **4 comprobaciones aprobadas**, registro `user://logs/rescate_bots_validado_0.log`.

Las pruebas centradas en fuego, cocina, opciones y combate preparan `Partida.rescate.rescatados = 2` como precondición; esta prueba cubre el rescate anterior. `jugar_fogata.gd` también salta esa etapa para seguir sirviendo de demo del fuego. `fogata_bot.gd` inyecta mouse en coordenadas locales del viewport: evita que la ventana headless de 64 px multiplique artificialmente por veinte la corrección vertical. Su revisión final aprobó las tres comprobaciones, incluido el tambaleo.

Revisión conjunta: **140 comprobaciones aprobadas** (24 de rescate, 4 con bots de rescate, 3 con bot de fogata, 37 de fogata, 38 de opciones/guardado y 34 de combos). Regresiones en `user://logs/rescate_regresion_*`; se respaldaron y restauraron los ajustes y el guardado personal. Pruebas de red locales; no simulan Internet con pérdida de paquetes.

## Opciones, combate, conexión y guardado (23/10/2026)

`mejoras_red.gd` usa dos procesos ENet, ambos con `--auto` y el mismo puerto (18130, por ejemplo). Uno `--host`, otro `--join=127.0.0.1`. Ejecutar `godot --headless --max-fps 60 --path . --script tests/mejoras_red.gd` antes de `--`. **38 comprobaciones aprobadas**: sliders reales, silencio, persistencia, editor de teclas con eventos, conflictos, indicaciones reasignadas, límite de repetición y secuencia completa, vida y segunda aparición de la musculosa, botín único/equipamiento/daño/caducidad por red, barra de reanimación interrumpible, RTT, guardado/sobrescritura/corrupción/restauración y botón Continuar con desconexión y nuevos IDs. Con renderizador en el anfitrión y `--captura`, guarda `mejoras_controles.png`, `mejoras_opciones.png`, `mejoras_revivir.png`, `mejoras_menu.png` y `mejoras_menu_guardado.png` en `user://`.

**Esta prueba escribe ajustes y una partida de prueba:** respaldar `user://audio.cfg`, `controles.cfg` y `partida.cfg` antes de ejecutarla y restaurarlos después, incluida la ausencia original del archivo. La ejecución de revisión utiliza copia de respaldo externa y restaura esos archivos al terminar. No usar simultáneamente con una partida personal. `prueba_guardado.cfg` y `prueba_roto.cfg` son archivos temporales de la prueba.

Registros de esta revisión: `user://logs/validado_mejoras_red_{host,cliente}.log`, `comprobado_combo_red_{0,1}.log`, `revision_abejas_red_{host,cliente}.log` y `validado_pausa_red_{host,cliente}.log`. La prueba de combo ahora espera que H repetida demasiado pronto se descarte; H/J/K/L debe seguir completándose en menos de 0,8 s en ambos peers. El test evita esperar capturas cuando se ejecuta headless. El regreso al lobby se verifica tras detener las réplicas; los logs finales de opciones/guardado y pausa no contienen errores del motor. Estas mediciones LAN no simulan pérdidas ni latencia de Internet.

## Registros anteriores y pruebas del resto del juego

**Fogata cooperativa (23/10/2026):** `fogata_red.gd` necesita **tres procesos** ENet, sin `--auto`: uno `--host` y dos `--join=127.0.0.1`, con el mismo `--puerto` (ejemplo 18066). Usa `godot --headless --max-fps 60 --path . --script tests/fogata_red.gd` antes de `--`. El anfitrión inicia al conectar los tres. Verifica golpes reales al árbol, límite de dos palos, inventario y recogida/colocación con E, roles en ambos órdenes, espectador, bloqueo de combate, arrastre real inyectado como eventos de mouse, eje incorrecto, falta de alternancia, pausa, enfriamiento, daño, reintento, tiempo agotado, datos inválidos, fuego sincronizado, cocina, ronda nueva y recuperación del inventario tras desconexión. agarre con clic sostenido (las palmas deben cerrarse sobre el palo antes de frotar; el tambaleo al azar se apaga con `f.tambaleo = false` para medir el ritmo). **37 comprobaciones aprobadas**, los tres procesos con salida 0. Con renderizador en el anfitrión y `--capturas`, guarda `user://fogata_cooperativa_*.png` (inventario, acercamiento, fricción y fuego encendido).

`fogata_bot.gd` usa un anfitrión con `--script tests/fogata_bot.gd -- --host --auto --puerto=18068` y un cliente normal sin script con `-- --join=127.0.0.1 --auto --bot-mision --bot-turno=1 --bot-ayuda --puerto=18068`. **Tres comprobaciones aprobadas:** el bot obtiene los dos palos con golpes, los coloca y espera, y completa su eje mientras el anfitrión usa eventos de mouse en el otro. Se acortan los traslados con reposicionamientos. No representa un recorrido autónomo completo por el mapa.

**Registro de la primera implementación:** 33 comprobaciones de fogata + 3 de bot + 22 de misión = **58 aprobadas**, todas las instancias con salida 0. Las cifras posteriores de fogata corresponden a pruebas añadidas.

`mision_lago_red.gd` y `objetos_visuales.gd` preparan la fogata encendida como precondición de sus pruebas de cocina; el encendido completo se prueba en `fogata_red.gd`. La prueba antigua de bots ahora verifica búsqueda de árboles/palos antes de las torres. Registros: `user://logs/fogata_revision_*.log`, `fogata_bot_*.log` y `mision_fogata_*.log`. En esa ejecución previa aparecía el aviso de sincronizadores/paquetes tardíos al reconstruir el lobby (corregido en la revisión de opciones/guardado arriba); no impidió iniciar ni limpiar la segunda ronda. No se considera una prueba de latencia de Internet.

**Regresión del contacto ultra:** `ultra_contacto.gd -- --puerto=18043` comprueba mano, brazo y manga en ambos lados, exclusión de transparencia, daño único a 15/30/60/120 Hz y ticks largos, retirada, contraataque, saltos, rodadas y desplazamiento del jugador/cámara. Con renderizador y `--capturas` guarda `user://ultra_contacto_*.png` para comprobar las costuras laterales fuera de pantalla. **43 comprobaciones aprobadas** con salida 0 y revisión de capturas; se mantiene el alcance fijo del brazo, sin extender la manga a todo el mapa.

**Ultra fase (21/10/2026):** `ultra_red.gd` usa dos procesos ENet con `--auto` y el mismo puerto, uno `--host` y otro `--join=127.0.0.1`. Ejecutar `godot --headless --max-fps 60 --path . --script tests/ultra_red.gd` antes de `--`. Verifica transición tras la tercera fase, daño al contacto y una sola vez, esquivas, salto, pausa compartida, cámaras distintas, autoridad, vulnerabilidad de la mano, combo, botellas, compazo, IA automática, victoria, otra ronda y cancelación de daño pendiente. El intento deliberado de inventar un ataque desde el cliente produce un rechazo RPC de Godot esperado. Los demás casos no deben producir errores de script. `vista_osa_ultra.gd` conserva la presentación de Claude, ahora con daño, y guarda `user://ultra_mecanicas_*.png`; `--largo` repite la demostración. La pelea normal activa la ultra al terminar las tres fases.

Resultado del 21/10: **32 comprobaciones de ultra**, más **132** de combo, compazo, combate general y misión cooperativa: todas aprobadas, ambos peers con salida 0. Revisión visual de ambas garras y aparición/rugido mediante las 12 capturas de la demo. Se actualizó la aserción antigua de altura del compazo para respetar los hombros de 40 px que cambió Claude, sin alterar esa mecánica. Registros en `user://logs/revision_ultra_2026-10-21/`. Persisten los avisos MP3 al cerrar; una ejecución intermedia también registró un paquete de sincronización tardío al reconstruir el lobby, sin impedir la siguiente ronda. Estas pruebas locales no sustituyen una sesión de balance ni pruebas con latencia de Internet.

Revisión de mecánicas del 20/10/2026: ver [revision_mecanicas.md](revision_mecanicas.md), con resultados, límites de las pruebas y pendientes reproducidos.

`embestida_lago.gd` se ejecuta solo: `godot --headless --path . --script tests/embestida_lago.gd -- --host --puerto=18010`. Comprueba 16 direcciones de orilla a 15/30/60/120 Hz, otros 16 arranques pegados al agua, velocidad en seco, límites de arena, salto especial al lago, contacto único e interrupción por parada en un tick largo. Son 85 comprobaciones. `--diagnostico` añade la reproducción del pendiente de persecución normal a través del lago; ese diagnóstico no es una regresión resuelta.

`mision_lago_red.gd` usa dos procesos con `--auto` y el mismo puerto: uno `--host`, otro `--join=127.0.0.1`. Comprueba saltar, pegar en el aire, evitar el golpe al suelo, restricciones al nadar, recoger/entregar piezas con E desde ambos peers, avance e interrupción de cocina, cooperación, alimentación, aparición del jefe, réplica de su desvío y victoria con golpes reales. Se acortan traslados y se inmovilizan enemigos en los casos aislados; no representa una partida humana completa. Añadir `--fallar-mision` a ambos procesos verifica el vencimiento real de los 30 segundos de alimentación y la derrota del equipo. Deben terminar con `RESULTADO MISION LAGO: 0 fallos`.

Revisión del fondo del menú: `godot --path . --script tests/vista_fondo_menu.gd` abre el menú con su animación normal. Añadir `-- --capturas` guarda ocho momentos reproducibles y una vista sin botones en `user://fondo_menu_*.png`, y termina. Usar renderizador, no `--headless`. Revisar sleeping quieto con Z, baba del compa de la silla, sorbo completo, nubes, reflejo del lago y fuego; la tienda, árboles, muebles, suelo y encuadre deben conservarse.

`pausa_red.gd` prueba dos peers reales con `--auto` y el mismo puerto (por ejemplo 17973). Ejecutar uno con `--host` y otro con `--join=127.0.0.1`, usando `--headless --max-fps 60 --path . --script tests/pausa_red.gd` antes de `--`. Verifica Esc desde ambos peers, congelación de física y reloj, foco/Enter, opciones y volumen, cancelación del apuntado sin lanzar botellas, regreso al lobby, una segunda ronda, salida del cliente que pausó, reconexión y cierre del anfitrión. Ambos deben salir con código 0 y `RESULTADO PAUSA: 0 fallos` / `RESULTADO PAUSA CLIENTE: 0 fallos`. Con renderizador y `--captura` en el anfitrión guarda `user://pausa_menu.png` y `user://pausa_opciones.png`.

El combate rápido se comprueba en `combo_red.gd`: secuencia completa en menos de 0,8 s desde ambos peers, tres pulsaciones rápidas del mismo puño (salen cada 0,15 s, sin perderse), orden de entrada al acabar un contacto y cancelación de toda la cola al recibir daño. Comprueba H/J/K/L, Espacio para saltar, Shift para rodar y F para parar, sin conflictos entre teclas ni acciones de combate ligadas al ratón. Entre el inicio de un golpe y el siguiente pasan al menos 0,15 s; las pruebas generales limpian entradas pendientes entre casos.

`combo_red.gd` usa anfitrión y cliente con `--auto` y el mismo puerto (por ejemplo 17876). Verifica los cuatro contactos reales, daño normal y crítico, sincronización en ambos sentidos, orden incorrecto, espera, fallo al aire, interrupción por daño, tipos inválidos, jefe en el lago, dirección izquierda, torre y fin de ronda. También comprueba los controles de teclado sin conflictos, la ausencia de combate con ratón y que los efectos desaparezcan. Usa acciones sintéticas e ignora el mando físico para evitar interferencias. Con ventana y `--captura` en el anfitrión guarda `user://combo_0.png` a `combo_3.png`. Debe terminar con `RESULTADO COMBO: 0 fallos` y ambos procesos con salida 0.

`combate_compas.gd` usa anfitrión y cliente con `--auto` y el mismo puerto, como `combate_red.gd`. Verifica parada a tiempo, dirección, espera, embestida, rechazo del golpe al suelo, permisos por jugador, lanzamiento desde ambos peers, daño único a osa y compañero, fallo sin daño, alcance, lanzamiento desde hombros y cancelación al terminar. Con ventana y `--captura` en el anfitrión guarda `user://combate_*.png`. Termina con `RESULTADO COMBATE COMPAS: 0 fallos`.

`botella_arco.gd` se ejecuta en anfitrión y cliente con `--auto` y el mismo puerto (por ejemplo 17861). Comprueba diez casos: mantener R sin gastar, límite de carga, soltar, arco replicado, ascenso/descenso, pasar por encima de alguien, tiro corto con fuego amigo, cancelación por daño, rechazo de fuerza inválida y carga desde el cliente. Con ventana y `--captura` en el anfitrión guarda `user://botella_trayectoria.png`. Termina con `RESULTADO ARCO: 0 fallos`. La demo de `bots_torre.gd` también entrega seis botellas para probar a mano.

`bots_torre.gd` prueba los bots reales en tres procesos: anfitrión con `--script tests/bots_torre.gd -- --host --puerto=17850`, dos clientes con `-- --join=127.0.0.1 --auto --bot-torre --bot-ayuda --bot-turno=1 --puerto=17850` (el segundo usa `--bot-turno=2`). Comprueba que sin Mamá Osa no se montan y van por las piezas, que con ella presente suben solos, esperan el puñetazo del anfitrión, generan un único crítico por pulsación hacia ambos lados, bajan con E, vuelven a subir y se bajan solos cuando la osa ya no está. El modo `--demo` del anfitrión, con ventana y sin clientes manuales, lanza los dos bots y deja a Mamá Osa inmóvil con 5000 de vida para practicar; no cambia su balance en las partidas normales.

Los dos bots de ayuda del menú usan el modo torre: ayudan con la misión y solo se montan en el anfitrión mientras pelea Mamá Osa. Para restaurar los bots de misión, desactivar `probar_torre_con_bots` en Main; `bot_de_ayuda = false` continúa desactivándolos por completo.

`objetos_visuales.gd` verifica 11 estados de los sprites: oseznos en espera, piezas cargadas y entregadas, hervido al mantener E, alimentación interrumpible, llanto, olla rota y susto de Mamá Osa. Se ejecuta en una instancia con `--host --puerto=17812`, sin `--auto`. Termina con `RESULTADO OBJETOS: 0 fallos`. Para guardar capturas de cada estado, quitar `--headless` y añadir `--capturas` después de `--`; las imágenes quedan como `user://objetos_*.png`.

`vista_campamento.gd -- --host --puerto=17825 --capturas` permite revisar la sala, el campamento, el bosque, el cartel y el lago con renderizador. Guarda `user://vista_*.png` y se cierra. Sin `--capturas` deja la partida abierta.

`combate_red.gd` abre la escena real y conecta dos instancias por ENet. Comprueba vida autoritativa, espera entre golpes, cerveza, reanimación interrumpible, vómito, resbalones, sueño, rodada, daño aumentado, fases del jefe, resultados y una segunda ronda sobre la misma conexión.

Desde la raíz del proyecto, abrir dos terminales y ejecutar (sustituir `godot` por la ruta del ejecutable de Godot 4):

```powershell
godot --headless --max-fps 60 --path . --script tests/combate_red.gd -- --host --auto --puerto=17781
```

```powershell
godot --headless --max-fps 60 --path . --script tests/combate_red.gd -- --join=127.0.0.1 --auto --puerto=17781
```

Iniciar el cliente antes de que termine la espera inicial de 10 segundos del anfitrión. La prueba tarda unos 25 segundos y ambas instancias se cierran solas. Debe terminar con `RESULTADO: 0 fallos`, código de salida 0 y sin errores de Godot en ninguna instancia. Usa un puerto distinto al de una partida normal.

Prueba manual de balance: recoger una botella con E/Y, beber con Q/RB, rodar con Shift/B y mantener E/Y junto a un compañero caído. Saltar con Espacio/A. Para el combo: H → J → K → L. Verificar en dos computadoras la latencia y la dificultad real del Lago; las pruebas locales no sustituyen esa sesión.

`botellas_agarre.gd` se ejecuta igual. Comprueba que terminar una chela deja una botella vacía, que lanzarla la gasta, le pega al compañero (fuego amigo) y al jefe, y que Mamá Osa agarra, sostiene y avienta lejos al jugador que tiene enfrente, salvo que esté invulnerable. También verifica que un golpe amigo libera tanto al anfitrión como al cliente justo antes del lanzamiento, aunque todavía estén junto a la mano, sin recibir el daño adicional del agarre. Termina con `RESULTADO BOTELLAS Y AGARRE: 0 fallos`.

`cerveza_recorrido.gd` se ejecuta con los mismos comandos sustituyendo el nombre del script. Parte con el inventario vacío y el medidor en cero; usa las acciones E/Q para recoger seis botellas, beber cuatro, pasar por los tres niveles de borrachera, vomitar y reponer el inventario. No asigna cerveza ni borrachera artificialmente; solo acorta el recorrido entre botellas. Comprueba los valores en anfitrión y cliente y termina con `RESULTADO RECORRIDO: 0 fallos`.

`animacion_jugador.gd` se ejecuta en una sola instancia, con `--host --puerto=17792` (sin `--auto` ni cliente). Verifica que el puñetazo espere a la extensión de la mano, cause daño una sola vez y se cancele si recibe un empujón, rueda o termina la ronda durante la preparación. También comprueba la dirección visual del puño y la transición entre caminar, pegar y detenerse. Termina con `RESULTADO ANIMACIÓN: 0 fallos`.

`torre_red.gd` usa cuatro instancias: un anfitrión y tres clientes. Ejecutar el comando del cliente en tres terminales; iniciar las cuatro instancias en menos de 20 segundos. No añadir `--auto`: la prueba espera a los cuatro y abre la partida.

```powershell
godot --headless --max-fps 60 --path . --script tests/torre_red.gd -- --host --puerto=17794
godot --headless --max-fps 60 --path . --script tests/torre_red.gd -- --join=127.0.0.1 --puerto=17794
```

Comprueba las acciones reales de salto/E, límite de tres contando la base, movimiento y salto compartidos, bajar desde cada nivel, caídas por golpe, rodada, sueño, muerte y desconexión, rechazo de órdenes ajenas y altura inicial de botellas. Verifica la relación de hombros en las cuatro pantallas. Termina con `RESULTADO TORRE: 0 fallos`. Para revisar su aspecto, quitar `--headless` del anfitrión y añadir `--captura` después de `--`; guarda `torre_revision.png` en la carpeta de datos del juego (`user://`).

También comprueba las posturas de base/intermedio/cima en los cuatro peers, caminar sujetando y puñetazos sentados. El crítico se prueba con entradas reales: tres golpes coordinados (60), dos en una torre de tres (20), golpes tardíos (30), un fallo al aire y una torre válida de dos (40). Daño y aviso deben coincidir en los clientes. `--captura` guarda además `torre_critico.png`. El bonus se aplica al último contacto; los puños individuales mantienen su impacto a los 0,08 s.

## Abejas y forcejeo

`abejas_red.gd` se ejecuta con dos peers ENet reales y `--auto`, ambos en el puerto 17912. Comprueba bajas individuales por entradas H de ambos jugadores, ausencia de bajas duplicadas, reaparición real a los ocho segundos, ambas ramas del sorteo con semillas deterministas, fusión previa al agarre, un solo encuentro activo, pulsación frente a botón mantenido, identidad y número de encuentro, bloqueo de otras acciones, victoria de anfitrión y cliente, derrota, límite de tiempo, torre, pieza transportada, caída, fin de ronda, segunda ronda limpia y desconexión. La semilla solo se fija en la prueba; la partida normal usa azar real.

```powershell
godot --headless --max-fps 60 --path . --script tests/abejas_red.gd -- --host --auto --puerto=17912
godot --headless --max-fps 60 --path . --script tests/abejas_red.gd -- --join=127.0.0.1 --auto --puerto=17912
```

Ejecutar cada comando en una terminal distinta. Debe finalizar con `RESULTADO ABEJAS: 0 fallos`, ambos procesos con salida 0 y sin errores. Con renderizador y `--captura` en el anfitrión guarda `user://abejas_*.png`.

Demo manual sin depender del sorteo: `godot --path . --script tests/vista_abejas.gd -- --host --puerto=17940`. Arranca solo, muestra la fusión, permite machacar **E** y prepara otro duelo dos segundos después de cada resultado. Solo en esta demo se restaura la vida y se fuerza la aparición. Con `--capturas` inspecciona ambos lados y varios cuadros, guarda `user://vista_abejas_*.png` y se cierra.
