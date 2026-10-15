# BearAndBeer — Documento de diseño (GDD)

> Versión 0.5 — Octubre 2026
> Las secciones marcadas con **[DECIDIR]** están pendientes.

---

## 1. Concepto

**Pitch en una frase:**
Un oso se robó las chelas de tu campamento y se fue a emborrachar a su cueva en el cerro. Tú y hasta 5 amigos borrachos tienen que cruzar el bosque, juntar piezas, construir artilugios absurdos y derrotar uno a uno a toda la familia del oso para recuperar la cerveza.

**Jugadores:** 1 a 6, cooperativo en línea.
**Género:** aventura cooperativa 2D con misiones, recolección, construcción y peleas contra jefes.

### Historia

Un grupo de compas se va de campamento con varias hieleras llenas de chelas. En la noche, un oso enorme —**Papá Oso**— se roba todas las cervezas, se las toma él solo y se va tambaleando a su cueva en lo alto del cerro.

Para llegar hasta él, los borrachos tienen que atravesar el bosque, pero en cada zona vive un familiar de Papá Oso que les bloquea el camino. Cada uno es un jefe distinto, con sus propias fases y su propia dinámica de pelea, y no se le puede enfrentar directamente: primero hay que **recolectar piezas y construir algo** en medio del bosque para provocarlo, alcanzarlo o despertarlo.

**La familia del oso (jefes por zona):**

| # | Zona | Jefe | Qué hay que construir |
|---|---|---|---|
| 1 | El Lago | **Mamá Osa** | Papilla de miel para los oseznos: comen, lloran y llaman a su mamá |
| 2 | Cueva de Hielo | **El Abuelo** (hibernando) | "El Sonidero": una bocina gigante con música de banda para despertarlo |
| 3 | El Río | **El Tío** (en una isla) | Una balsa hecha con hieleras para llegar hasta él |
| 4 | Los Pinos Gigantes | **La Prima** (vive en lo alto de los árboles) | Una catapulta para lanzar a los jugadores hasta ella |
| 5 | El Cerro | **Papá Oso** (jefe final, borracho) | Un vehículo improvisado para subir el cerro (carrito del súper con motor) |

Al vencer al último, recuperan las chelas que sobrevivieron… y hacen la fiesta. **[DECIDIR] final / posible giro**

### Estructura de cada zona (capítulo)

1. **Llegar a la zona** y descubrir el problema (al jefe no se le puede enfrentar así nomás).
2. **Una misión:** recolectar las piezas del artilugio por la zona.
3. **Construir y hacer funcionar** el artilugio.
4. **Pelea contra el jefe:** siempre hay que pegarle hasta matarlo, pero cada jefe tiene una dinámica distinta.
5. **Recompensa:** chelas recuperadas y acceso a la siguiente zona.

**Inspiración:** el meme de "¿un hombre le gana a un oso?", el caos entre amigos de *Lethal Company* / *R.E.P.O.* / *Peak* y las peleas contra jefes con fases.

### Pilares (lo que el juego siempre debe cumplir)

1. **Caos con amigos (hasta 6):** borrachos tambaleándose, fuego amigo, gente saliendo volando.
2. **Recolectar y construir para vencer:** cada jefe se enfrenta gracias a un artilugio distinto que el equipo arma junto.
3. **Jefes con personalidad:** cada familiar del oso tiene fases y una dinámica de pelea única.
4. **Simple de jugar:** todos los jugadores tienen las mismas habilidades; te curas con cerveza.
5. **Historia ligera y cómica:** un objetivo claro (recuperar las chelas) y personajes graciosos.
6. **La cerveza es poder y riesgo:** te cura y te hace más fuerte, pero más torpe.

**Plataforma:** PC (Steam).
**Precio objetivo:** 10–15 USD. **[DECIDIR]**
**Duración meta:** campaña de 3–5 horas en grupo.
**Público:** grupos de amigos que buscan una aventura para jugar juntos y reírse.

> ⚠️ **Nota de alcance:** el desarrollo empieza con **una sola zona completa** (El Lago y Mamá Osa) con 2 jugadores. Si esa zona divierte, se agregan las demás y se sube a 6 jugadores.

---

## 2. Ciclo de juego

**Inicio del juego:**
1. **Cinemática:** el campamento, la fiesta, Papá Oso robándose las hieleras y subiendo tambaleándose a su cueva en el cerro.
2. **Tutorial jugable** en el camino al Lago: moverse, saltar, golpear, esquivar, agarrar objetos, tomar cerveza, levantar a un compañero.
3. Llegan al Lago y empieza la Zona 1.

**Ciclo de cada zona:**
Llegar → Misión (recolectar piezas) → Construir el artilugio → Pelea contra el jefe → Siguiente zona.

**Ciclo de toda la campaña:**
Cinemática → Tutorial → Mamá Osa → El Abuelo → El Tío → La Prima → Papá Oso → Final.

**Al terminar cada jefe:** pantalla de humillación con estadísticas para burlarse entre amigos.

---

## 3. Mecánicas del jugador

**Vista:** 2D lateral con profundidad (estilo *Castle Crashers*): se ve de lado, pero los jugadores caminan también hacia el fondo y hacia el frente por el suelo del bosque. El salto y el salir volando se conservan.
**Todos los jugadores son iguales:** mismas habilidades, misma vida, mismos ataques. Solo cambia el color o los cosméticos.

**Controles base:**
| Acción | Teclado | Control |
|---|---|---|
| Moverse | W A S D | Stick izq. |
| Saltar | Espacio | A |
| Golpear | Clic izq. / J | X |
| Esquivar / rodar | Shift / K | B |
| Agarrar / lanzar / colocar objeto | E | Y |
| Tomar cerveza | Q | RB |
| Lanzar botella vacía | F | LB |
| Levantar compañero caído | Mantener E | Mantener Y |
| Subir a hombros | Saltar y pulsar E sobre un compa | A y luego Y sobre un compa |
| Bajar de hombros / saltar desde arriba | E / Espacio | Y / A |

**Reglas:**
- **100 puntos de vida máxima por jugador**, iguales para todos y sin configuración en la sala. El anfitrión calcula y sincroniza automáticamente el daño y las muertes.
- **Te curas tomando cerveza.**
- Al perder la vida quedas **caído**; un compañero te levanta en unos segundos.
- **Fuego amigo activado** (los golpes y objetos sí les pegan a tus compañeros).

**Torre de compas (implementada):**
- Máximo **3 jugadores en total**, contando al que está en el suelo. Sin ajustes del anfitrión.
- Saltar y pulsar E/Y encima de un compañero. Si ya lleva a alguien, se trepa al último puesto libre de esa torre.
- La base camina y salta con el grupo; los pasajeros pueden mirar a ambos lados, pegar y lanzar botellas desde su altura.
- Posturas propias: la base sostiene con los brazos elevados, los pasajeros van sentados y el intermedio también carga al de arriba. Hay ciclos de reposo, caminar cargando y puñetazos desde cada puesto.
- **Crítico de torre:** todos los integrantes de una torre de 2 o 3 deben acertar sus puños a Mamá Osa hacia el mismo lado dentro de **0,18 segundos**. El último contacto completa **×2 del daño combinado** (40 con dos sobrios, 60 con tres), con aviso visual para todos. Fallar, golpear tarde o cambiar integrantes rompe la coordinación; no aumenta el daño a compañeros, olla ni oseznos. Lo valida el anfitrión sin opciones de configuración.
- E/Y baja al pasajero; Espacio/A permite saltar desde sus hombros. Si sale el de en medio, caen los de arriba. La base también puede pulsar E/Y para soltarlos.
- Golpes, agarres, rodada, incapacitación y desconexión del apoyo hacen caer a los que sostiene. No se puede formar una torre cargando piezas.
- E/Y en el suelo conserva la interacción con objetos y mantenerlo permite levantar a un compañero caído cuando no estás en una torre.
- Los golpes fuertes de los jefes causan **ragdoll** / salir volando.

### La cerveza: cura y Medidor de Borrachera 🍺
Tomar cerveza **te cura**, pero sube tu medidor de borrachera. Tomar tarda un par de segundos y te deja vulnerable.

| Nivel | Efecto positivo | Efecto negativo |
|---|---|---|
| 0 — Sobrio | Control normal | Golpes normales |
| 1 — Alegre | +daño | Ligero tambaleo |
| 2 — Pedo | Mucho más daño | Te tambaleas, a veces le pegas a un amigo |
| 3 — Hasta atrás | Golpe especial "Ven pa'cá" | Casi no controlas al personaje, te puedes quedar dormido unos segundos |

- El medidor **baja poco a poco** con el tiempo.
- Si te pasas, **vomitas**: quedas aturdido unos segundos (y el vómito hace resbalar a los demás).
- **Estrategia:** curarse ayuda, pero si todos se curan de más, nadie camina derecho.

### Valores del prototipo implementado (ajustables tras probar con amigos)
- **Recoger cerveza:** E/Y junto a una botella del mapa; máximo 6 en el inventario (un six-pack). Hay seis botellas juntas cerca del campamento para probar las mecánicas desde el inicio. Las botellas vuelven a aparecer tras 25 segundos para permitir intentos largos.
- **Beber:** Q/RB, con las manos libres y en el suelo. Tarda 2 segundos, inmoviliza y cura 35 puntos, hasta un máximo de 100. La botella se consume al terminar; recibir daño interrumpe la bebida sin curar ni gastar la botella, con un aviso en el HUD.
- **Borrachera:** cada bebida terminada añade 30 puntos. Permanece 12 segundos tras la última bebida y después baja 0.5 por segundo cuando no se bebe. Los niveles empiezan en 0, 25, 50 y 75 puntos; el daño es 10, 15, 22 y 30 respectivamente. Bebiendo seguido desde sobrio: primera chela alegre, segunda pedo, tercera hasta atrás y cuarta vómito. El HUD muestra el valor numérico del medidor y avisa cuando faltan chelas.
- **Torpeza:** tambaleo creciente; en nivel 2 hay un 20% de probabilidad de golpear hacia el lado equivocado. En nivel 3 se reduce la velocidad y el golpe normal se convierte en **"Ven pa'cá"**, con más alcance y empujón, pero una espera de 0.7 segundos.
- **Sueño y vómito:** mantenerse 6 segundos en nivel 3, en el suelo y sin beber, rodar ni estar aturdido, puede dejarte dormido 2.5 segundos. Llegar a 100 puntos provoca vómito durante 2.5 segundos y baja el medidor a 70. El charco dura 12 segundos y hace resbalar a quien lo pisa; se puede saltar o esquivar.
- **Caído y reanimación:** a 0 de vida sueltas la pieza y quedas inmóvil. Un compañero con las manos libres mantiene E/Y a menos de 60 píxeles durante 3 segundos; más compañeros aceleran la ayuda. Si nadie ayuda, el progreso se reinicia. Te levantas con 40 de vida y 1.5 segundos de protección.
- **Rodar:** Shift/K/B durante 0.32 segundos; evita daño en los primeros 0.2 segundos y tiene 1.1 segundos de espera. Suelta la pieza que estés cargando.
- **Fin del intento:** si todos quedan caídos durante 2 segundos, aparece la derrota. En solitario sucede al caer. El anfitrión puede volver a todo el equipo a la sala para empezar una ronda limpia, sin reconectar.
- **HUD y resultados:** barras de vida y borrachera, inventario y estado de cada jugador. Al vencer a Mamá Osa se comparte la pantalla de humillación con fuego amigo recibido, distancia máxima de vuelo en píxeles, bebidas terminadas, amigos alcanzados al vomitar, siestas en combate, daño efectivo al jefe y rescates. Los empates comparten premio; valores en cero no generan ganadores.
- El anfitrión calcula automáticamente la vida, inventario, estados, daño, reanimación y estadísticas. **No hay ajustes de vida en la sala.**

**Objetos comunes:**
- Cerveza (cura y sube el medidor)
- Botella vacía (se lanza): cada chela que te tomas te deja una. Vuela recta unos 380 píxeles, quita 12 de vida a enemigos y compañeros, y entre más borracho estás, peor puntería.
- Palo (golpe con más alcance)
- Sartén (aturde un instante)
- Silla plegable (daño alto, se rompe)

---

## 4. Los jefes

Regla general: **a todos los jefes hay que pegarles hasta matarlos**, pero cada uno tiene una **dinámica distinta** que cambia cómo se pelea. Cada jefe tiene **3 fases** según su vida (100–66%, 66–33%, 33–0%), y cada fase cambia expresión, heridas, color (shader), partículas y ataques.

### Jefe 1 — Mamá Osa (El Lago)
- **Artilugio:** papilla de miel → los oseznos lloran y llaman a Mamá Osa.
- **Dinámica: PROTEGER.** Hay que defender la olla de papilla y a los oseznos. Si alguien lastima a un osezno o se rompe la olla, Mamá Osa se enfurece y sube de fase de golpe.
- **Agarre (en las 3 fases):** se le echa encima al jugador más cercano, lo levanta con las patas y lo avienta bien lejos. Se evita rodando a tiempo, y un compañero puede soltarlo de un golpe antes de que lo aviente.
- **Fase 1:** zarpazos y empujones, revisa a sus crías.
- **Fase 2:** embiste en línea recta, ruge para aturdir.
- **Fase 3:** salta al lago y sale salpicando, golpe al piso que hace volar a todos.
- **Lo que enseña:** pelear en equipo y cuidar un objetivo.

### Jefe 2 — El Abuelo (Cueva de Hielo)
- **Artilugio:** El Sonidero, una bocina gigante con música de banda.
- **Dinámica: MANTENERLO DESPIERTO.** Si el Sonidero se apaga (se le acaba la pila o el Abuelo lo golpea), el Abuelo se vuelve a dormir y **recupera vida**. Unos jugadores pegan; otros consiguen pilas y protegen la bocina.
- **Fase 1:** lento y adormilado, bosteza (el bostezo empuja).
- **Fase 2:** baila al ritmo de la banda y ataca al compás de la música.
- **Fase 3:** la cueva se oscurece, caen picos de hielo del techo.
- **Lo que enseña:** dividirse tareas.

### Jefe 3 — El Tío (El Río)
- **Artilugio:** balsa de hieleras.
- **Dinámica: PELEA SOBRE LA BALSA.** La pelea es en la balsa mientras avanza río abajo. El Tío salta entre troncos y rocas; si la balsa se daña, hay que repararla o se hunde. Caer al agua te arrastra corriente abajo.
- **Fase 1:** lanza piedras desde la orilla.
- **Fase 2:** se sube a la balsa y la hace tambalear.
- **Fase 3:** rápidos y cascada al final; hay que acabarlo antes de llegar.
- **Lo que enseña:** pelear con equilibrio y presión de tiempo.

### Jefe 4 — La Prima (Los Pinos Gigantes)
- **Artilugio:** catapulta.
- **Dinámica: PELEA VERTICAL.** La Prima vive en lo alto de los pinos. La catapulta lanza a los jugadores hacia las ramas para pegarle; también se le pueden lanzar objetos para tumbarla. Cuando cae al suelo queda aturdida unos segundos: momento de pegarle todos.
- **Fase 1:** avienta piñas.
- **Fase 2:** salta de árbol en árbol.
- **Fase 3:** sacude los pinos y tumba a quien esté arriba.
- **Lo que enseña:** coordinarse (uno carga la catapulta, otro vuela).

### Jefe 5 — Papá Oso (El Cerro) — Jefe final
- **Artilugio:** carrito del súper con motor.
- **Dinámica: PERSECUCIÓN + PELEA FINAL.**
  - **Parte 1:** subir el cerro en el carrito mientras Papá Oso, borracho, rueda barriles de cerveza y avienta botellas desde arriba.
  - **Parte 2:** pelea en la cueva, rodeados de las hieleras robadas.
- **Fase 1:** borracho y torpe, ataques lentos e impredecibles.
- **Fase 2:** se toma más cerveza (se cura, igual que los jugadores) y pega más fuerte. Romper las cervezas cercanas evita que se cure.
- **Fase 3:** "Hasta atrás": combina ataques de toda la familia.
- **Lo que enseña:** usar todo lo aprendido.

---

## 5. Misiones (una por zona)

Antes de cada jefe hay **una sola misión**: recolectar las piezas del artilugio y construirlo.

| Zona | Piezas a recolectar (ejemplo) | Obstáculo de la misión |
|---|---|---|
| El Lago | Miel, olla, leña | Abejas furiosas al tomar la miel |
| Cueva de Hielo | Bocina, pilas, cables | Piso resbaloso y cuevas oscuras |
| El Río | Hieleras vacías, cuerdas, remo | Cruzar troncos y saltar entre rocas |
| Los Pinos | Llanta, tablas, resorte | Ardillas que se roban las piezas |
| El Cerro | Carrito, motor de podadora, gasolina | Animales borrachos que tomaron chela perdida |

- Las piezas están repartidas por la zona: conviene **dividirse**.
- Las piezas se cargan con las manos (si te pegan, la sueltas).
- Al juntar todo, se **construye en una estación** del mapa (mantener botón entre varios jugadores para hacerlo más rápido). Si se suelta el botón, el avance se baja.
- **Zona 1:** las abejas atacan a quien se acerque a un panal; molestan con menos fuerza durante la pelea y se calman al vencer al jefe. Con la papilla lista hay **30 segundos para dársela a los oseznos** (otra barra, manteniendo el botón junto a ellos). Si se logra, lloran por su mamá y empieza la pelea; si no, Mamá Osa derriba a todos y termina el intento. En este prototipo se reintenta la zona desde la sala.

---

## 6. Multijugador

- **1 a 6 jugadores**, en línea, cooperativo.
- **Conexión actual del prototipo:** ENet por IP. **Para después:** Steam (plugin **GodotSteam**) — invitas desde tu lista de amigos, sin servidores propios.
- **Modelo:** uno es **anfitrión** (decide lo que hace el jefe, el daño y los objetos). Los demás reciben la información.
- **Se sincroniza:** posiciones, vida, ataques, estado del jefe, objetos y piezas.
- **No se sincroniza (local en cada pantalla):** partículas, ragdolls cosméticos, sonidos.
- **Dificultad:** la vida de los jefes sube según cuántos jugadores haya.
- **Respaldo:** también se puede jugar local y con **Steam Remote Play Together**.
- **Regla de oro:** probar en línea desde el primer prototipo.

---

## 7. Progresión

**Se deja simple a propósito:**
- No hay niveles, tienda ni mejoras.
- Todos los jugadores tienen las mismas habilidades durante todo el juego.
- Lo que avanza es la **historia** (zonas y jefes nuevos).
- **Opcional para después:** cosméticos (sombreros, bigotes, gorras) que se desbloquean al vencer jefes.

---

## 8. Arte y estilo

- **Estilo:** pixel art, retro 16-bit, colores cálidos de bosque.
- **Tamaños:** jugador 32×32, jefes 64×64 o más.
- **Jugadores:** un solo personaje base + **cambio de colores por shader** (6 colores).
- **Herramientas:** generador de sprites con IA (base) + **Aseprite** para limpiar y animar.
- **Escenarios:** 5 zonas + campamento, con paquetes de itch.io y fondos con parallax.
- **En Godot:** filtro de textura en **Nearest**.

**Animaciones mínimas:**
- **Jugador:** quieto, caminar, saltar, golpear, esquivar, tomar cerveza, cargar objeto, recibir golpe, caído, volar, vomitar.
- **Cada jefe:** quieto, caminar, 2–3 ataques, aturdido, derrota.

**Cinemática inicial:** imágenes fijas en pixel art con un poco de movimiento (más fácil que animar todo).

> Nota: Steam pide declarar el uso de IA en el contenido del juego.

---

## 9. Audio

- Rugidos distintos por jefe y por fase.
- Golpes exagerados y cómicos (estilo caricatura).
- Música por zona; más intensa en las peleas.
- Jefe 2: música de banda (es parte de la mecánica).
- **Fuentes:** sonidos gratis (freesound.org, paquetes de itch.io). **[DECIDIR] música**

---

## 10. Interfaz (UI)

- Menú principal: Jugar / Unirse a amigo / Opciones / Salir.
- Selección de zona (las ya desbloqueadas).
- HUD: vida y medidor de borrachera de cada jugador, barra de vida del jefe con marcas de fase, piezas recolectadas.
- **Pantalla de humillación** al vencer cada jefe:
  - Quién recibió más fuego amigo
  - Quién salió volando más lejos
  - Quién tomó más cervezas
  - Quién vomitó encima de un amigo
  - Quién se quedó dormido en plena pelea
  - Quién le pegó más al jefe

---

## 11. Tecnología

- **Motor:** Godot 4 (GDScript).
- **Online:** GodotSteam.
- **Arte:** IA para sprites + Aseprite.
- **Control de versiones:** Git + GitHub (para no perder el proyecto).
- **Ayuda con código:** IA para escribir y explicar scripts.

---

## 12. Alcance

### Versión mínima (MVP) — lo que SÍ o SÍ va primero
- 2 jugadores en línea
- Zona 1 completa: misión de la miel + construir la papilla + Mamá Osa con sus 3 fases
- Moverse, saltar, golpear, esquivar, cargar objetos, levantar compañero
- Cerveza: cura + medidor de borrachera
- Pantalla de humillación

### Después (si el MVP divierte)
- Zonas 2 a 5
- Cinemática inicial
- Hasta 6 jugadores
- Cosméticos

### Fuera (por ahora no)
- Niveles, tienda o mejoras
- Habilidades distintas por jugador
- Mundo abierto

---

## 13. Plan de trabajo

**Horas por semana disponibles:** **[DECIDIR]**

| Etapa | Meta |
|---|---|
| 1 | ✅ Prototipo con cubos: 2 jugadores conectados en línea, moverse y golpear |
| 2 | ✅ Menú principal, crear partida, sala de espera con selección de jugador (personajes provisionales de colores) y bosque inicial con el campamento |
| 3 | ✅ Misión del Lago con cubos: cargar piezas (miel, olla, leña), abejas y cocinar la papilla en la fogata |
| 4 | ✅ Mamá Osa (cubo): llega cuando los oseznos comen, persigue y pega, vida y 3 fases, dinámica de proteger la olla y los oseznos |
| 5 | ✅ Cerveza (cura + borrachera, vómito y sueño), levantar compañero caído y esquivar |
| 6 | ✅ Cierre de Zona 1 con cubos, pantalla de humillación, derrota y regreso compartido a la sala; pendiente ajustar el balance con amigos |
| 7 | **Probar con amigos** y ajustar |
| 8 | ✅ Primera pasada de sprites y animaciones de Zona 1: escenario, jugadores, Mamá Osa, abejas, chelas, piezas, fogatas y oseznos. Pendiente pulido visual y revisión con amigos |
| 9 | Página de Steam + clips para redes |
| 10 | Zonas 2 a 5, una por una |
| 11 | Cinemática, 6 jugadores, pulido |
| 12 | Demo (Zona 1) para Steam Next Fest |

---

## 14. Preguntas abiertas
- ~~Nombre final del juego~~ → **BearAndBeer**
- Steam: al tener alcohol, marcar la etiqueta de contenido correspondiente en la página
- Precio
- Final de la historia (¿giro?)
- ~~Vida de los jugadores~~ → **100 puntos para todos**
- Horas por semana disponibles
- Música
