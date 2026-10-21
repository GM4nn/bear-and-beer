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
| Puño derecho | H | X |
| Puño izquierdo | J | RT |
| Cabezazo | K | L3 (pulsar stick izquierdo) |
| Patada | L | Cruceta abajo |
| Parada a tiempo | F | LT |
| Esquivar / rodar | Shift | B |
| Agarrar / lanzar / colocar objeto | E | Y |
| Tomar cerveza | Q | RB |
| Apuntar / lanzar botella vacía | Mantener R / soltar R | Mantener LB / soltar LB |
| Lanzar al compa que cargas en hombros | R (siendo la base de una torre) | LB (siendo la base de una torre) |
| Lanzar al compa que tienes enfrente | — (pendiente en teclado) | R3 |
| Levantar compañero caído | Mantener E | Mantener Y |
| Subir a hombros | Saltar y pulsar E sobre un compa | A y luego Y sobre un compa |
| Bajar de hombros / saltar desde arriba | E / Espacio | Y / A |
| Pausar / resumir | Esc | — |

**Pausa (implementada):** Esc detiene el mundo y abre **Resumir, Opciones, Terminar partida y Volver al lobby**. Se navega con flechas y Enter; Esc en Opciones vuelve a la pausa, y Esc en la pausa reanuda. Opciones permite cambiar volumen y pantalla completa sin mover el mundo. En cooperativo cualquier jugador puede pausar o reanudar para todos. El anfitrión puede devolver al grupo al lobby y comenzar una ronda nueva conservando la conexión. Terminar partida lleva al menú principal: el anfitrión cierra la sesión para todos; un cliente solo abandona su propia sesión. Si quien pausó se desconecta, se reanuda automáticamente. Se congelan física, animaciones y temporizadores de combate; se cancela el apuntado de botella sin gastarla y no se acumulan pulsaciones dentro del menú.

Movimiento y combate completos con teclado: mano izquierda en WASD y mano derecha en **H/J/K/L**, una tecla por golpe, con **F** para parar. Se eligió esta fila porque cada dedo queda sobre su golpe; la distribución anterior (J/K/U/I) obligaba a mover la mano. El combo se introduce con **H → J → K → L**. El ratón no tiene acciones de combate; queda disponible para la interfaz y futuros puzles. Se conserva la compatibilidad con mando.

**Reglas:**
- **100 puntos de vida máxima por jugador**, iguales para todos y sin configuración en la sala. El anfitrión calcula y sincroniza automáticamente el daño y las muertes.
- **Te curas tomando cerveza.**
- Al perder la vida quedas **caído**; un compañero te levanta en unos segundos.
- **Fuego amigo activado** (los golpes y objetos sí les pegan a tus compañeros).

**Combo individual y golpes de cómic (implementados):**
- Secuencia: **puño derecho → puño izquierdo → cabezazo → patada crítica**. Los tres primeros contactos preparan el remate; deben acertar a la misma Mamá Osa, con menos de **0,95 segundos entre contactos**. Un golpe al aire, orden incorrecto, recibir daño, quedar incapacitado o terminar la ronda rompe el combo. Repetir el puño derecho comienza una secuencia nueva.
- Daños estando sobrio: **10 / 10 / 14 / 16**; la patada que completa el combo hace **40** (×2,5) y tambalea a la osa durante **0,9 segundos**. Después de cualquier tambaleo (combo, compazo o parada) la osa no puede volver a tambalearse durante **3 segundos**; la parada sigue evitando el daño en ese rato. Se conserva el aumento de daño por borrachera. No se aplica el crítico a compañeros, oseznos ni objetos.
- El combo individual requiere estar fuera de una torre y no cargar piezas para los ataques nuevos. E/Y permite bajar o soltar; las torres conservan sus puños y su crítico coordinado.
- Cada contacto real muestra un estallido breve de **tinta negra y destello blanco**, con borde irregular y trazos radiales como la referencia del usuario, **sin palabras ni letras**. Dura 0,24 s; el crítico usa el mismo efecto más grande durante 0,34 s. Fallar no muestra un impacto. El HUD indica el siguiente ataque y todos los clientes reciben los efectos confirmados por el servidor.
- Animaciones propias del segundo brazo, cabezazo y patada; el daño se aplica cuando el miembro alcanza el cuadro de contacto, una sola vez por ataque.
- Espera corta entre golpes: entre el inicio de un ataque y el siguiente pasan al menos **0,15 segundos**; machacar más rápido no pega más rápido. La preparación dura 0,08 / 0,10 / 0,14 / 0,16 segundos. Se guardan hasta tres pulsaciones anticipadas en orden para encadenar la secuencia rápida sin perder entradas; recibir daño, rodar, montar, parar o terminar la ronda cancela lo pendiente. Mantener un botón no repite ataques. Los bots conservan su ritmo de ayuda.

**Compazo y parada a tiempo (implementados):**
- **Compazo:** siendo la base de una torre, R/LB lanza al de más arriba; con mando, R3 también lanza al compañero cercano que tienes delante (en teclado esto aún no tiene tecla). El compañero vuela girando en arco; al chocar con Mamá Osa le hace **40 de daño**, recibe **15 de daño** y rebota. La osa se tambalea durante **0,75 segundos**. Un vuelo solo cuenta una vez; si falla, aterriza sin daño de choque. Espera entre lanzamientos: **1,4 segundos**.
- **Parada:** F/LT sube la guardia (antebrazos frente a la cara, rodillas dobladas y un empujón para desviar). La ventana útil dura **0,22 segundos**, aunque la animación se ve completa (0,35 s) salvo que te peguen. Si un zarpazo o una embestida te alcanza en esa ventana y miras hacia la osa, evitas el daño y la tambaleas durante **0,8 segundos**, con destello, aviso **¡PARADA!** y un arco de guardia. Espera entre intentos: **0,9 segundos**; mantener el botón no repite la parada. Una parada cancela el ataque completo, así que también protege a quien esté a tu lado en ese momento.
- Se hacen desde el suelo y sin cargar piezas. La parada no detiene agarres, rugidos ni golpes al suelo; estos últimos siguen requiriendo saltar. El daño y las ventanas se validan en el servidor.

**Mamá Osa tambaleando (mareada):**
- La tambalean tres cosas: la patada crítica del combo (0,9 s), el compazo (0,75 s) y la parada (0,8 s). Mientras dura no ataca y suelta a quien tuviera agarrado.
- Se ve **mareada**: animación propia en cada una de sus 3 fases (se bambolea, le da vueltas la cabeza, ojos perdidos) y **tres estrellitas** girando sobre su cabeza, con el aviso **¡TAMBALEANDO!**.
- Después de recuperarse queda **3 segundos sin poder volver a tambalearse**, para que no la puedan dejar trabada; en ese rato la parada sigue evitando el daño, pero ya no la marea. En esta excepción la embestida continúa: quien la paró queda protegido frente a todos los contactos restantes de esa misma carrera, aunque los demás todavía pueden recibirla.

**Torre de compas (implementada):**
- Máximo **3 jugadores en total**, contando al que está en el suelo. Sin ajustes del anfitrión.
- Saltar y pulsar E/Y encima de un compañero. Si ya lleva a alguien, se trepa al último puesto libre de esa torre.
- La base camina y salta con el grupo; los pasajeros pueden mirar a ambos lados, pegar y lanzar botellas desde su altura.
- Posturas propias, todos del mismo tamaño: la base sostiene con los brazos elevados las piernas del de en medio; el de en medio va sentado en sus hombros y sostiene con las dos manos al de arriba; el de arriba va sentado. Hay ciclos de reposo, caminar cargando y golpes desde cada puesto: la base patea al frente, el de en medio suelta una mano para pegar con la otra sin dejar de sostener, y el de arriba lanza puñetazos sentado.
- Los nuevos golpes del combo (puño izquierdo, cabezazo, patada) no se usan en torre; ahí solo cuenta el puño derecho (H/X) para el crítico de torre.
- **Crítico de torre:** todos los integrantes de una torre de 2 o 3 deben acertar sus puños a Mamá Osa hacia el mismo lado dentro de **0,18 segundos**. El último contacto completa **×2 del daño combinado** (40 con dos sobrios, 60 con tres), con aviso visual para todos. Fallar, golpear tarde o cambiar integrantes rompe la coordinación; no aumenta el daño a compañeros, olla ni oseznos. Lo valida el anfitrión sin opciones de configuración.
- E/Y baja al pasajero; Espacio/A permite saltar desde sus hombros. Si sale el de en medio, caen los de arriba. La base también puede pulsar E/Y para soltarlos.
- Golpes, agarres, rodada, incapacitación y desconexión del apoyo hacen caer a los que sostiene. No se puede formar una torre cargando piezas.
- E/Y en el suelo conserva la interacción con objetos y mantenerlo permite levantar a un compañero caído cuando no estás en una torre.
- Los golpes fuertes de los jefes causan **ragdoll** / salir volando.

**Bots de ayuda (solo para probar, se apagan con `bot_de_ayuda` en Main):**
- Al crear partida se unen 2 bots (configurable con `cantidad_bots`).
- Sin Mamá Osa, ayudan con la misión: van por la miel, la olla y la leña y las llevan a la fogata.
- Cuando aparece Mamá Osa, se montan en los hombros del anfitrión y acompañan cada golpe suyo para hacer el crítico de torre. Si traían una pieza, la sueltan antes de subir. Cuando ella ya no está, se bajan solos.

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
- **Torpeza:** tambaleo creciente; en nivel 2 hay un 20% de probabilidad de golpear hacia el lado equivocado. En nivel 3 se reduce la velocidad y el golpe normal se convierte en **"Ven pa'cá"**, con más alcance y empujón. La espera mínima de 0,15 segundos entre golpes es la misma en todos los niveles.
- **Sueño y vómito:** mantenerse 6 segundos en nivel 3, en el suelo y sin beber, rodar ni estar aturdido, puede dejarte dormido 2.5 segundos. Llegar a 100 puntos provoca vómito durante 2.5 segundos y baja el medidor a 70. El charco dura 12 segundos y hace resbalar a quien lo pisa; se puede saltar o esquivar.
- **Caído y reanimación:** a 0 de vida sueltas la pieza y quedas inmóvil. Un compañero con las manos libres mantiene E/Y a menos de 60 píxeles durante 3 segundos; más compañeros aceleran la ayuda. Si nadie ayuda, el progreso se reinicia. Te levantas con 40 de vida y 1.5 segundos de protección.
- **Rodar:** Shift/B durante 0.32 segundos; evita daño en los primeros 0.2 segundos y tiene 1.1 segundos de espera. Suelta la pieza que estés cargando.
- **Fin del intento:** si todos quedan caídos durante 2 segundos, aparece la derrota. En solitario sucede al caer. El anfitrión puede volver a todo el equipo a la sala para empezar una ronda limpia, sin reconectar.
- **HUD y resultados:** barras de vida y borrachera, inventario y estado de cada jugador. Al vencer a Mamá Osa se comparte la pantalla de humillación con fuego amigo recibido, distancia máxima de vuelo en píxeles, bebidas terminadas, amigos alcanzados al vomitar, siestas en combate, daño efectivo al jefe y rescates. Los empates comparten premio; valores en cero no generan ganadores.
- El anfitrión calcula automáticamente la vida, inventario, estados, daño, reanimación y estadísticas. **No hay ajustes de vida en la sala.**

**Objetos comunes:**
- Cerveza (cura y sube el medidor)
- Botella vacía (se lanza): cada chela que te tomas te deja una. Mantener R/LB carga la fuerza durante 1,2 s y muestra la parábola y el punto de caída; soltar lanza. Desde el suelo alcanza aproximadamente 160–570 píxeles según la carga, y desde los hombros llega más lejos. Puede pasar por encima de un objetivo; causa 12 de daño al impactar y conserva el fuego amigo. Recibir daño o quedar incapacitado cancela la carga. La guía muestra el tiro ideal; la borrachera sigue empeorando la puntería real.
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
- **Fase 2:** anuncia una dirección y embiste; al encontrar agua se desvía por la orilla manteniendo el mismo lado de desvío. No vuelve a apuntar al jugador durante la carrera. Termina al acercarse al borde de la arena. Ruge para aturdir.
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

### Abejas y forcejeo — mecánica propia del Lago

El combate básico queda cerrado. Las mecánicas adicionales dependen de la zona y de su jefe.

- Cada panal tiene **5 abejas individuales**. Un impacto de puño, cabezazo, patada o botella mata una; cae girando y desaparece. Cada baja reaparece a los **8 segundos**. Un enjambre vacío deja de picar y de recibir impactos hasta que se repone.
- Las bajas cuentan **entre todos los jugadores y panales**. Cada grupo de **3 bajas** sortea un **50 % de probabilidad** de fusión. Tres siluetas de abeja giran, convergen y forman una **abeja musculosa**, algo mayor que el compa, tras **1,8 segundos**.
- Solo puede haber **una musculosa activa**. Los grupos de tres bajas durante ese encuentro se consumen sin acumular futuras fusiones. La musculosa no cuenta como otra baja de abeja pequeña.
- Conserva el diseño aprobado: cuerpo de abeja amarillo, ojos negros grandes, alas azules y brazos musculosos. Se acerca **caminando**, prepara **dos puñetazos de 5 de daño** (0,7 s cada uno, contacto a los 0,32 s), y después busca al rival para el empuje. Los puños se pueden evitar saltando, alejándose, rodando o haciendo parada con F; un fallo también cuenta entre los dos intentos.
- Después de esos dos puños, busca a un jugador cercano en el suelo y lo reta al entrar en contacto: ambos se ven de perfil, con piernas abiertas, cuerpo inclinado hacia delante y las dos manos unidas haciendo fuerza. Al compa se le ven brazos musculosos solo durante el duelo. Suelta lo que lleva y desmonta su torre si la tenía; no agarra jugadores caídos, saltando, nadando o incapacitados.
- **Pulsar E repetidamente** (Y en mando) empuja la barra hacia la victoria. Mantener el botón no repite pulsaciones. La barra empieza al 50 %; la abeja resta 8,5 puntos porcentuales por segundo tras 0,35 s de preparación, y cada pulsación suma 6,5. Hay un máximo de **8 segundos** para llevarla al 100 %; al llegar a cero o agotar el tiempo gana la abeja.
- Ganar manda volando a la musculosa y la elimina. Perder causa **15 de daño** y un empujón; la abeja se marcha. El compa recupera sus controles en ambos casos y obtiene **1,2 segundos de protección** para salir del encuentro.
- Durante el forcejeo se pausan los otros estados del compa, sus movimientos y sus acciones; recibe protección frente a golpes externos. E no recoge objetos, no monta hombros y no levanta compañeros en ese momento. Los demás ven quién está forcejeando y la misma barra.
- Si no encuentra rival durante 15 s, la musculosa se retira. Desconexión, caída del contendiente y fin de ronda cancelan el duelo. Una ronda nueva reinicia contador y encuentro.
- El anfitrión decide bajas, azar y resultado; el cliente solo envía pulsaciones propias, validadas por identidad, encuentro e intervalo mínimo. No hay opciones de configuración para el anfitrión.

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

**Fondo del menú:** se conserva el campamento al atardecer de `arte/ui/menu/fondo.png`, con los tres compas en sus posiciones originales y el estilo de cantina de Claude. El fondo ya no intercambia recortes aleatorios de paisajes: un shader mueve suavemente las nubes centrales, las vetas del reflejo en el lago y las llamas, manteniendo la cuadrícula del pixel art, la orilla y la base de la fogata. Unas pocas brasas suben y desaparecen. El compa del tronco tiene una secuencia real de bajar la botella, descansar y volver a beber, con tiempos de espera. Las animaciones son locales y su reloj se detiene cuando el fondo está oculto durante la partida.

El compa del sleeping permanece completamente quieto; solo sus Z suben y se desvanecen. El compa de la silla también queda quieto, sin respiración ni cabeceo: su animación es un hilito de baba que crece desde la boca, forma una gota y cae. Se conservan ambos sprites originales.

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
