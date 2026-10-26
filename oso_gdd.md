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
- Espera corta entre golpes: entre el inicio de un ataque y el siguiente pasan al menos **0,15 segundos**; machacar más rápido no pega más rápido. La preparación dura 0,08 / 0,10 / 0,14 / 0,16 segundos. Se guardan hasta tres pulsaciones anticipadas de ataques distintos en orden para encadenar la secuencia rápida sin perder entradas; repetir el mismo ataque exige **0,30 segundos** y las repeticiones prematuras se descartan; recibir daño, rodar, montar, parar o terminar la ronda cancela lo pendiente. Mantener un botón no repite ataques. Los bots conservan su ritmo de ayuda.

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
- Sin Mamá Osa, primero golpean árboles, recogen y colocan los dos palos. Un bot ocupa un papel de la fogata y espera al humano; los otros dejan libre el segundo papel. Después buscan la olla y la miel como antes.
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
- **Torpeza:** tambaleo creciente; en nivel 2 hay un 20% de probabilidad de golpear hacia el lado equivocado. En nivel 3 se reduce la velocidad y el golpe normal se convierte en **"Ven pa'cá"**, con más alcance y empujón. La espera mínima de 0,15 segundos al alternar y de 0,30 segundos al repetir un ataque es la misma en todos los niveles.
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
- **Ultra fase (después de la tercera):** al agotar la vida normal todavía no hay victoria: aparece la osa gigante de Claude, con un último tramo de vida equivalente al **50 % de su máximo anterior** (150 sola, 250 con dos jugadores). Conserva los 100 de vida de cada compa. Alterna aparición frontal, izquierda y derecha, eligiendo por turnos entre los jugadores vivos.
- **Ataques de ultra:** la garra vertical hace **25 de daño** al tocar el suelo (cuadro 7 a 14 fps, 0,5 s); se esquiva saliendo de su carril o rodando. El barrido lateral hace **20** (cuadro 6 a 14 fps, unos 0,43 s) y pasa por debajo de quien esté a más de 28 px de altura. El daño comprueba la silueta del cuadro actual (uñas, mano, brazo y polígono de la manga) contra el cuerpo del jugador durante la entrada y la retirada. La mano quieta conserva su ventana segura para contraatacar. Cada ataque fija el destino al empezar, sin perseguir al jugador durante la preparación, y solo aplica un contacto por jugador. El perfil lateral conserva su costura fuera de pantalla cuando cambia la cámara; el brazo mantiene su alcance físico en el mundo. F no bloquea estos ataques gigantes.
- **Contraataque:** la mano queda apoyada **1,1 s** después del impacto y recibe puños, combo crítico, botellas y compazos. Fuera de esa ventana el antiguo cuerpo pequeño no recibe daño ni detiene botellas. La ultra no se tambalea ni entra en rivalidad con la abeja. Al derrotarla sí llegan los resultados de victoria.
- **Garra larga:** conserva los sprites y el alcance de Claude. La extensión de la manga usa su misma tela con curvatura y anchura progresiva; el brazo entra y se recoge mediante desplazamiento, sin estirar la mano. Los contactos los calcula el anfitrión con reloj de física y posiciones del mundo compartidas, independientes de la cámara de cada jugador. La pausa congela ataques; terminar la ronda o reconstruir el bosque los elimina.
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
| El Lago | Dos palos, olla y miel | Encender fuego entre dos; abejas junto a la miel |
| Cueva de Hielo | Bocina, pilas, cables | Piso resbaloso y cuevas oscuras |
| El Río | Hieleras vacías, cuerdas, remo | Cruzar troncos y saltar entre rocas |
| Los Pinos | Llanta, tablas, resorte | Ardillas que se roban las piezas |
| El Cerro | Carrito, motor de podadora, gasolina | Animales borrachos que tomaron chela perdida |

- Las piezas están repartidas por la zona: conviene **dividirse**.
- Las piezas se cargan con las manos (si te pegan, la sueltas).
- Al juntar todo, se **construye en una estación** del mapa (mantener botón entre varios jugadores para hacerlo más rápido). Si se suelta el botón, el avance se baja.
- **Zona 1:** las abejas atacan a quien se acerque a un panal; molestan con menos fuerza durante la pelea y se calman al vencer al jefe. Con la papilla lista hay **30 segundos para dársela a los oseznos** (otra barra, manteniendo el botón junto a ellos). Si se logra, lloran por su mamá y empieza la pelea; si no, Mamá Osa derriba a todos y termina el intento. En este prototipo se reintenta la zona desde la sala.

### Fogata cooperativa — punto 1 implementado (23/10/2026)

- La fogata bajo el lago empieza **apagada**. Se retiró la pieza fija de leña; la fogata del campamento se conserva.
- Cada **tres golpes** a un árbol desprenden un palo, hasta disponer de **dos en total**. Se recogen con **E** y el HUD personal muestra **PALOS ×1/2 o ×2/2**. Un jugador puede llevar ambos o pueden repartirse entre dos; no ocupan las manos de las piezas.
- **E** cerca del lugar de la fogata coloca los palos que lleve el jugador. Con ambos colocados, los primeros dos que pulsen E ocupan los papeles **horizontal** y **vertical**, por orden de llegada. Una sola persona espera; no puede encender el fuego por sí sola.
- Se abre una vista de acercamiento funcional con los dos brazos del color de los participantes, palos y animación vinculada a los movimientos reales. Mantener **clic izquierdo** y arrastrar de ida y vuelta en el eje indicado. Cambiar de eje, mover sin clic o mover siempre en la misma dirección no mantiene el calor.
- **Dos segundos de preparación**, luego **35 segundos** para encender. En la versión actual de Claude ambos frotan horizontalmente, en sentidos contrarios, y corrigen arriba/abajo la deriva de sus brazos. Clic sostenido da firmeza. Los trazos de 60 px deben alternar cada 0,18–0,9 s y coincidir entre compañeros dentro de 0,28 s. La guía marca 0,4 s; se requieren **8 segundos efectivos** de coordinación. Sin coordinación el calor baja 5% por segundo. El tambaleo puede separar las manos del palo: deben corregirlas. Sin configuración del anfitrión.
- Los demás jugadores pueden acercarse y pulsar **E como espectadores**: ven los mismos participantes, brazos, barra y tiempo, pero no contribuyen. **E** sale; **Esc** pausa para todos. Salir como espectador no interrumpe a los dos participantes.
- Estar en el acercamiento bloquea movimiento y combate, pero no vuelve invulnerable. Daño o incapacidad de un participante, alejarse, desconectarse o terminar la ronda cancela. Se conservan los palos colocados para volver a intentar; desconectarse con palos en el inventario los deja en el suelo. Al vencer el tiempo también se puede reintentar.
- El servidor valida identidad, papel, encuentro, distancia, eje, magnitud, alternancia e intervalo de los movimientos. La pausa congela el reloj y descarta arrastres anteriores; los observadores no pueden avanzar el fuego por RPC.
- Al completar la barra aparece la fogata con sus sprites de fuego y humo existentes. **Olla y miel conservan sus mecánicas actuales**, y cocinar exige fuego encendido además de ambas piezas entregadas.
- **Pendiente de diseño del usuario:** nuevas mecánicas para olla y miel; subir los oseznos al árbol alto pertenece a la continuación de la misión y no se implementó en este punto 1. El dibujo del acercamiento es una presentación funcional de la mecánica; no sustituye los sprites de Claude.

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


## Revisión de mecánicas y opciones — 23/10/2026

- **Versión:** `0.1.0-alpha`, definida en `project.godot` y visible en pequeño en el menú principal.
- **Audio:** corregido el orden de los argumentos de los sliders de Música/Efectos. Se aplican al bus correspondiente, cero silencia y los valores permanecen en `user://audio.cfg`, tanto desde el menú como desde pausa.
- **Controles:** botón «Ver y modificar controles» en ambas pantallas de opciones. Lista desplazable de acciones y teclas; seleccionar una acción y pulsar su nueva tecla. Se rechazan duplicados y se reservan Esc/Enter/Tab para los menús. Guarda en `user://controles.cfg`; permite restaurar los originales. El mando conserva sus bindings. Las indicaciones principales de misión/interacción/combo usan la tecla configurada.
- **Puño H:** repetir el mismo ataque requiere 0,30 s y no deja ataques repetidos en cola. Alternar H → J → K → L conserva la ventana de 0,15 s y el crítico de la patada. No se redujo el tiempo del contacto ni se cambiaron los cuadros de Claude.
- **Abeja musculosa:** vida 60 → **180**. Tras morir descansa **12 s** antes de poder fusionarse otra vez. Cada grupo de tres bajas vuelve a sortear la aparición, con garantía como máximo al segundo grupo elegible; solo una musculosa activa a la vez. Ganar el forcejeo sigue noqueándola.
- **Botín:** derrotar la musculosa deja un **aguijón** recuperable con la tecla de interactuar. Da **+50% de daño cuerpo a cuerpo durante 20 s**, sin acumular multiplicadores; desaparece al caer. El botín sin recoger dura 45 s. Lo resuelve el anfitrión y se replica a todos.
- **Reanimación:** barra visible sobre el caído con el porcentaje real sincronizado; mantener la tecla de interactuar, soltar reinicia el avance. Conserva los 3 s y la ayuda cooperativa existentes.
- **Conexión:** RTT real de ida y vuelta cada 2 s, en HUD y sala, con Buena (<90 ms), Regular (<180 ms) o Alta latencia. El anfitrión se identifica como tal; sin respuesta se muestra «Sin respuesta / midiendo», sin inventar un ping cero.
- **Guardar:** una ranura local del anfitrión, mediante Esc → Guardar partida. `user://partida.cfg`, escritura temporal y reemplazo, con versión de formato y validación antes de cargar. Rechaza guardar si todos están caídos o la ronda terminó.
- **Continuar:** botón en el menú cuando existe guardado. Crea un lobby nuevo; el anfitrión recupera su color y los compañeros eligen el color con el que guardaron para recuperar sus inventarios. Conserva posiciones, salud, cerveza/botellas/borrachera, arma temporal, misión, piezas entregadas, fuego/palos, suministros, enjambres y vida/fase de los enemigos. Los palos de un ausente quedan en el suelo. Suelta piezas transportadas en su posición, separa torres/agarres y reinicia los ataques y la fricción en curso; no serializa partículas ni proyectiles en vuelo. No es guardado en la nube ni automático.
- **Logs:** el regreso al lobby ahora detiene y confirma las réplicas antes de borrar los jugadores, evitando posiciones tardías sobre sincronizadores eliminados. La consulta de cervezas también comprueba que el peer siga conectado al cerrar un bot.


## Rescate previo de los oseznos — 24/10/2026

La secuencia de Zona 1 ahora es **miel como señuelo → rescatar los dos oseznos → dos palos y fuego cooperativo → volver a la tienda y buscar la olla → tres oleadas de abejas y reina → miel para la papilla → cocinar → alimentar → Mamá Osa**. Se conserva el arte existente de Claude.

- Árbol al extremo derecho del mapa (7020, 650), con el círculo de captura a su izquierda y la rama por encima incluso de la torre de tres. El indicador de misión lleva primero a la miel y luego al círculo bajo el árbol.
- Llevar el frasco al círculo y pulsar **E** ofrece una porción. El frasco queda recuperable cerca para la papilla; el señuelo permanece en los reintentos.
- Debe participar **todo el equipo conectado**, incluidos los bots: ningún caído queda excluido para iniciar con menos. Con 2–3 jugadores todos forman la torre (saltar + E); con 4–6, tres forman la torre y los demás juegan desde el suelo junto al árbol (a menos de 110 px del punto de captura). Primero hay que revivir a cualquier caído y reunir al equipo. Cualquier integrante de la torre pulsa E para atajar **un solo osezno por intento**. Durante el intento se bloquean golpes, lanzamientos, salto y desplazamiento; Esc sigue pausando.
- El rescate utiliza ahora el **reto cooperativo de mouse** descrito abajo. El balance con A/D y el control individual del péndulo quedan sustituidos por seis objetivos que todos deben seguir con clic sostenido.
- Cuenta atrás de 3 s y seis objetivos numerados por osezno. El primero alterna sostener, curvas y vueltas (aviso de 0,9 s, recorrido de 1,5 s, radio de 44 px). El segundo cambia la secuencia, invierte giros y añade curvas en S (aviso de 0,8 s, recorrido de 1,35 s, radio de 40 px). La interfaz muestra el avance de cada integrante y avisa que el segundo es más rápido.
- Un fallo de cualquiera **derriba a todos, incluida la base**. El osezno araña al de arriba por 12 y vuelve a su rama. Puede reintentarse sin perder los éxitos previos. El daño externo y la desconexión también cancelan el reto y separan la torre.
- Cada éxito lleva al osezno al campamento. Solo cuando están ambos abajo se habilitan los palos, el fuego y la entrega de ingredientes. Antes del rescate no hay un objetivo invisible golpeable de oseznos en el campamento.
- El anfitrión resuelve participantes, equilibrio, daño y éxitos. Los demás reciben el mismo estado; un espectador no puede mandar correcciones por los participantes.
- Los bots de ayuda buscan/ofrecen miel, suben sobre el anfitrión cuando este está en el círculo y corrigen su parte del equilibrio. El humano inicia el intento y debe aportar su corrección.
- Guardar conserva el señuelo y los oseznos ya a salvo. Cargar devuelve a la rama al que estuviera saltando, sin dejar jugadores atrapados. Los guardados anteriores que ya tenían fuego consideran completado el rescate para mantener su progreso.


### Distribución de árboles y panales — 24/10/2026

El árbol de rescate se trasladó al final del mapa, sin ampliar sus límites. El círculo queda a la izquierda del tronco para que puedan formar la torre sin pegarse al borde. Las barras se muestran al costado opuesto de la torre cuando la cámara alcanza el límite derecho.

Hay **10 árboles con panal y enjambre** (antes 4), repartidos desde x=1050 hasta x=7080. Se alternan los lados del camino, dejando el campamento inicial y el círculo del rescate fuera del radio inicial de detección. El panal que custodia el frasco de miel queda en (6420, 370), con la miel al pie, antes de llegar al árbol de los oseznos. Los demás conservan su comportamiento local, muerte y reaparición; no se duplicó el ingrediente de la misión.


## Reto de rescate con mouse — 24/10/2026

Se revisaron los cambios posteriores de Claude: escenario y decoración guardados en `bosque.tscn` para editar desde Godot, árbol de rescate propio con rama y animaciones de olfatear/saltar/asustarse/arañar, panales asociados a sus árboles y bots que rodean el lago. Se conservan esos cambios. El péndulo que había implementado se mantiene como movimiento visual del osezno, pero ya no controla el resultado del rescate.

1. La miel y la torre de hasta tres se preparan igual. E solo inicia si todo el equipo conectado está vivo y reunido: con 2–3 jugadores todos suben; con 4–6 los demás participan desde el suelo junto al árbol. El mensaje explica quién falta o necesita reanimación. Nadie conectado puede quedarse como espectador para evitar el reto.
2. Todas las pantallas muestran **el mismo círculo azul y el mismo recorrido**, sin reflejos ni desplazamientos por jugador. Cada compa mantiene su propio **clic izquierdo sostenido dentro de cualquier parte del círculo grande, incluido el contorno azul**; el punto blanco solo sirve de referencia visual. El cursor se muestra verde dentro y rojo fuera. Un anillo de aproximación indica cuándo empieza; una marca tenue anticipa el siguiente objetivo.
3. Todos completan seis objetivos. Primer osezno: sostener, curva, vuelta, sostener, curva, vuelta. Segundo: curva, vuelta inversa, S, curva, S inversa, vuelta inversa; es más rápido y exige un poco más de precisión. La variante es la misma para todos los jugadores. El clic se mantiene también al cambiar de objetivo; no se usan A/D ni un clic exclusivo del de arriba. La dificultad depende de los oseznos ya rescatados, por lo que reintentar o cargar conserva la variante correcta.
4. El servidor calcula el acierto individual a partir de posición del cursor, botón y reloj del círculo que el cliente estaba viendo. Valida la antigüedad del reloj según la latencia, no permite adelantarlo ni retrocederlo, y no acepta porcentajes ni aciertos enviados por clientes. Se quitó el desfase fijo de 80 ms que rechazaba puntos dentro del borde visible; cada muestra se juzga contra su círculo visible, sin mover después el objetivo debajo de un cursor antiguo. Rechaza intentos/pasos anteriores, secuencias repetidas, espectadores y posiciones inválidas. Cada paso exige al menos 80% de seguimiento y un error continuo de 0,28 s hace fallar al equipo.
5. Si alguien suelta, no llega o sale de la trayectoria, **todos salen despedidos de la torre**. El aviso muestra **«¡Falló [nombre]!»** para todo el equipo. Si varios no alcanzan el seguimiento mínimo al terminar un objetivo, indica sus nombres con «¡Fallaron…!». Una interrupción por muerte o desconexión mantiene su aviso general, sin atribuir un fallo de mouse. Solo el de arriba recibe el arañazo de 12. Si todos terminan, el osezno salta a las manos y baja al campamento.
6. Esc pausa el reloj. Al reanudar se repite el objetivo actual con cuenta atrás para volver a colocar el mouse. El guardado conserva los oseznos rescatados y el señuelo, pero reinicia el reto pendiente.
7. Los bots siguen su propio objetivo mediante la misma validación del servidor. Todos los jugadores conectados tienen objetivo, también quienes apoyan desde el suelo en equipos de más de tres. Un fallo de cualquiera derriba la torre; el arañazo siempre corresponde al jugador de la cima. Una muerte, separación o desconexión interrumpe el intento. La misión general no tapa las instrucciones durante el reto y la interfaz se adapta al tamaño de la ventana.

Implementación: `scripts/reto_rescate.gd` (objetivos, entrada, validación y UI); `scripts/rescate_oseznos.gd` (torre, caída, animaciones y rescate). Pruebas actuales: 28 comprobaciones con tres peers y entrada real de mouse, más 4 con bots, sin errores de script en los registros finales. Son pruebas de red local, no una simulación de Internet.

## Buscar la olla dentro de la tienda — 25/10/2026

Después del rescate y de encender el fuego, la flecha de misión devuelve al equipo a la puerta de la carpa del campamento. La olla ya no es una pieza libre del mapa: permanece oculta y bloqueada hasta superar esta búsqueda.

- **Todo el equipo conectado**, incluidos bots, debe acercarse a pie, con las manos libres, y pulsar E individualmente. Nadie es espectador. Mientras esperan se ven las manos de quienes van entrando; el montón se habilita cuando están todos (mínimo dos).
- Aparece el interior con el mensaje **«¡Los compas dejaron esto hecho un desmadre!»**. Cada compa mueve sus propias dos manos, identificadas con su color, sobre el montón compartido. La revisión de dificultad actual contiene 34 trastos y dos ollas rotas de señuelo, además de la olla válida. Se reutilizan las manos y objetos existentes del proyecto.
- Mantener clic izquierdo agarra el objeto superior bajo el cursor; arrastrar lo mueve y soltar lo avienta con el impulso reciente. Los objetos agarrados tienen dueño y no se pueden robar ni recoger a través de otros. El anfitrión valida identidad, intento, secuencia, límites y velocidad del cursor.
- Los trastos apartados forman pilas a izquierda y derecha. **Seis objetos en un lado** activan un aviso de **1,5 segundos**: quitar objetos permite estabilizarlo; retirar las manos permite evitar el daño. Se muestra la zona en peligro y su cuenta atrás.
- Si cae una pila, los trastos vuelven al centro y la olla se esconde de nuevo en otra posición. Cada compa cuyas manos o brazos atraviesen la zona de caída pierde **12 de vida** y sus manos quedan doloridas un momento. Quienes las retiraron no reciben daño. Si alguien cae, la búsqueda se interrumpe para que lo revivan.
- Al destapar la olla, deben arrastrarla al recuadro **SALIDA** y soltarla. Todos deben haber apartado al menos un objeto: nadie puede entrar y quedarse sin ayudar. El logro se comparte y la olla aparece físicamente junto a la puerta para llevarla a la fogata.
- **E** abandona la búsqueda para todo el equipo; **Esc** pausa sin perder el progreso ni dejar un objeto agarrado. Daño externo, desconexión, separación o fin de partida cancelan el acercamiento y liberan controles. Los bots entran con E y manejan sus manos mediante la misma validación de cursores.
- Guardar conserva `olla_encontrada`. Cargar una búsqueda incompleta la reinicia fuera de la tienda; una completada no se repite. Los guardados anteriores con olla ya entregada o papilla hecha mantienen ese avance.

Implementación: `scripts/busqueda_olla.gd` (autoridad, objetos, pilas y daño), `scripts/busqueda_olla_vista.gd` (interior y entrada), y conexiones en partida, jugador, pieza, estación, misión y guardado. El montón se replica como una instantánea comprimida mediante RPC fiable, para no exceder el MTU de `MultiplayerSynchronizer`.

Demo: `tests/jugar_olla.gd` prepara el fuego y el rescate, coloca al humano y dos bots junto a la carpa, y espera su E. No carga ni modifica la ranura personal de guardado.

## Oleadas de miel y abeja reina — 25/10/2026

Después de recuperar la olla, el objetivo manda a todo el equipo debajo del lago, alrededor de (5900, 665). Deben estar todos los jugadores conectados vivos, a pie y dentro de 210 px durante dos segundos. Hay un aviso de tres segundos antes de empezar. No es posible iniciar dejando atrás a un compañero caído. La olla puede entregarse antes o después de la pelea.

- **Oleada 1:** `4 + ceil(jugadores/2)` enjambres de cinco abejas. Cada golpe mata una; no reaparecen ni provocan fusiones durante este encuentro.
- **Oleada 2:** `5 + ceil(jugadores/2)` enjambres, exactamente dos preparados para fusionarse. Tras tres bajas en cada uno, o cinco segundos si siguen vivos, tres abejas giran y se juntan durante 1,8 s para convertirse en musculosas. No se usa el sorteo de los panales para estas dos fusiones.
- **Oleada 3:** `2 + ceil(jugadores/2)` musculosas. Vida individual `140 + 12 × jugadores`, puños, posibilidad de parada y botín de aguijón al derrotarlas. No abren el forcejeo E de la musculosa ambiental.
- Cada oleada termina al derrotar a todos sus enemigos y deja tres segundos de preparación. Después de la tercera aparece una sola **reina**, con `350 + 110 × jugadores` de vida.
- La reina camina y encadena dos puñetazos (15 de daño por contacto); la parada a tiempo la interrumpe. Alterna con un vuelo que marca la zona de caída y un golpe de suelo de 22 de daño, evitable alejándose o saltando. Su escupitajo sale tras la preparación, viaja como proyectil y puede esquivarse.
- Un impacto de miel bloquea movimiento y acciones, y recubre al jugador de color miel. Se libera con **diez pulsaciones alternadas de A/D**, o las acciones izquierda/derecha reasignadas. Mantener una tecla, repetir el mismo lado, pulsar ambas simultáneamente o enviar entradas demasiado rápidas no completa el reto. La UI muestra teclas y avance; hay tres segundos de protección contra otra inmovilización al soltarse. Morir, cancelar la ronda o terminar el encuentro limpia el efecto.
- Combos H/J/K/L, críticos coordinados de torre, botellas y compañeros lanzados funcionan contra los enemigos nuevos. El daño, las fusiones, las oleadas y el escape de miel se validan en el servidor. Los demás reciben una instantánea comprimida a 20 Hz; el cliente no decide su progreso.
- Durante el encuentro se apartan los enjambres ambientales y se cancela cualquier forcejeo previo. Al terminar recuperan su comportamiento normal. La miel de señuelo se consume al ofrecerla a los oseznos; **la miel para cocinar solo se habilita al vencer a la reina** y aparece junto a la estación.
- Una desconexión o cambio de equipo cancela el encuentro pendiente y permite reunirse otra vez. El guardado conserva la victoria; si se guarda a mitad de la pelea, al cargar se repite desde la primera oleada. Los guardados antiguos con la miel entregada o la papilla preparada conservan ese avance.
- Los bots se reúnen, atacan, intentan parar, evitan la zona del golpe de suelo y alternan las mismas entradas para sacudirse la miel. Intentan reanimar a un caído y evitan atacar atravesando compañeros. No tienen daño extra ni vida infinita.

Arte de la reina: variante generada con **PixelLab** a partir de la musculosa existente, más grande y con peluca violeta y corona. Clips propios de caminar, puñetazos, vuelo/golpe, escupitajo y muerte, reflejados según la dirección. Detalles de origen en `arte/abeja_reina/ORIGEN.md`. Se mantienen los sprites y el escenario existentes.

Implementación: `scripts/oleadas_miel.gd`, `scripts/enemigo_oleada.gd`, `scripts/oleadas_miel_vista.gd`. Demo manual: `tests/jugar_miel.gd` prepara las etapas anteriores y abre humano + dos bots junto al lago; `--reina` permite ir directo al miniboss. No modifica la ranura personal.
