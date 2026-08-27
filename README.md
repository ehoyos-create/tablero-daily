# Tablero Daily

Un tablero de tareas, un marcador semanal y una página de norte, para un equipo pequeño.

**Un archivo HTML y una base de Supabase.** No hay build, no hay dependencias, no hay
`npm install`. Se abre en el navegador y se edita a mano.

```
tablero-daily/
├── index.html      todo: estructura, CSS y JS en un solo archivo
├── esquema.sql     se pega entero en el editor SQL de Supabase, una vez
├── verificar.py    el chequeo de antes de desplegar
└── vercel.json     cabeceras de seguridad, y noindex
```

---

## Ponerlo a andar · 5 minutos

1. **Creá un proyecto en [Supabase](https://supabase.com).** El plan gratis alcanza de sobra.
2. **Pegá `esquema.sql` entero** en el editor SQL y corrélo. Crea las dos tablas, sus
   disparadores, sus permisos y el bucket de las imágenes.
3. **Copiá la URL y la llave publicable** de `Settings → API`.
4. **Abrí `index.html`** y llená el bloque `CONFIG` de arriba del `<script>`:

```js
const CONFIG={
  equipo:'Mi equipo',
  supabase:{
    url:'https://xxxxxxxx.supabase.co',
    llave:'sb_publishable_...'
  },
  personas:[ {n:'Ana',f:null}, {n:'Beto',f:null} ],
  ...
};
```

5. **Abrí el archivo en el navegador.** Ya funciona. Si querés un enlace para el equipo,
   `vercel deploy --prod` desde esta carpeta y listo.

> ⚠️ La llave que va acá es la **publicable** (`sb_publishable_…`), nunca la de servicio.
> Esta página es pública y la llave viaja en el HTML a la vista de cualquiera.

---

## ⚠️ Antes de usarlo: quién puede entrar

Tal como viene, **cualquiera que tenga el enlace puede leer y editar.** No hay cuentas ni
contraseña, a propósito: así el equipo entra sin registrarse.

Es la decisión correcta para un tablero interno cuyo enlace no circula. **No lo es para
nada con datos sensibles.** Si necesitás cerrarlo, activá Supabase Auth y cambiá
`to anon, authenticated` por `to authenticated` en las ocho políticas de `esquema.sql`.

---

## Las tres páginas

Se cambia de página en una **barra lateral que asoma al acercar el mouse al borde izquierdo**.
Se puede fijar, y entonces el lienzo se corre. La página abierta y si la barra estaba fijada
se recuerdan en el navegador.

| Página | Qué es |
|---|---|
| **📋 Daily** | El tablero de tareas: Board y Timeline |
| **📈 Pulso** | El marcador semanal, con una insignia de cómo va la semana |
| **🧭 Norte** | Misión, visión, valores, metas y objetivos |

---

## El Daily

**Board** con tres columnas y **Timeline** con barras que se arrastran a los lados para mover
fechas y arriba o abajo para priorizar.

### Toda tarea se escribe SMART, y la regla no vive en el navegador

No se puede crear una tarea sin fecha, y la que le falte algo sale con `⚠️` diciendo
exactamente qué le falta.

| Letra | Campo | Qué significa acá |
|---|---|---|
| **S** Específica | `nombre` | Empieza con un verbo y nombra el entregable. «Modelo financiero» es un tema, «Armar el modelo financiero» es una tarea |
| **M** Medible | `resultado_esperado` | Qué existe cuando esté lista, y cómo se verifica sin preguntar |
| **A** Alcanzable | `persona` + `talla` | Tiene dueño y cabe en el tiempo declarado. Si no cabe en 8 horas es un proyecto, hay que partirlo |
| **R** Relevante | `para_que` | A qué objetivo sirve, o qué se frena si no está |
| **T** Acotada | `fecha` | Una fecha, no un «pronto» |

**`smart` es una columna generada de Postgres.** La regla vive en un solo sitio y ninguna app
puede saltársela, ni siquiera escribiendo directo contra la base.

### Lo demás que trae

- **La prioridad es un solo número (`orden`)** compartido por las dos vistas. Lo que se sube en
  el Board queda arriba en el Timeline, y al revés.
- **Una tarea nueva nace en su fecha, no al fondo.** Es lo único automático del orden; de ahí en
  adelante manda la mano. Y se compara contra el orden que hay en pantalla, no contra un orden
  cronológico ideal: si alguien ya movió cosas, la nueva se mete donde encaja **sin reordenar el
  trabajo de nadie**.
- **`creado` es intocable**, lo blinda un disparador. La antigüedad se ve en la tarjeta
  (`3 d`, `2 sem`) y en el panel.
- **Varios responsables por tarea.** El menú no se cierra al elegir. En la tarjeta se ven las
  fotos apiladas, o los monogramas si no hay fotos.
- **Bloqueada**, por otra tarea o por un motivo escrito, que en el Timeline se pinta **rayada en
  ámbar**. Es ámbar y no rojo a propósito: el rojo ya significa «va tarde», y son dos problemas
  distintos. Una barra puede estar tarde **y** bloqueada, y se distinguen.
- **Destrabada**, que es el tercer estado y no tiene botón: la manera de decir que el bloqueo se
  resolvió es **pasar la tarea a `En curso`**, porque si arrancó es que ya no la frena nada.
  Entonces la barra conserva **el mismo rayado** pero **en azul claro**, con el candado abierto
  🔓. `bloqueado` no se borra: así queda el rastro de que estuvo trabada y la flecha del mapa no
  desaparece, que es justo lo que explica por qué arrancó tarde.
- **Duplicar**, en la cabecera del panel. Copia los diez campos y abre la copia. Una copia de algo
  en `Lista` nace en `Por hacer`: si naciera terminada, le sumaría sus horas otra vez al Pulso de
  esta semana, que es trabajo que nadie hizo.
- **Filtros** por persona y por tiempo, e **historial** de lo archivado.
- **Agrupar** y **Por fecha**, en el Timeline. `Agrupar` junta las barras por responsable;
  `Por fecha` renumera la prioridad siguiendo las fechas. Son dos botones a propósito: si agrupar
  reordenara solo, se llevaría por delante el orden que alguien acaba de poner a mano. Dentro de
  cada grupo sigue mandando `orden`, así que **el arrastre no se pierde**: vertical cambia la
  prioridad, horizontal las fechas. El vertical queda **acotado al grupo**, porque soltar una barra
  en el grupo de otra persona sería reasignarle la tarea sin decirlo. Una tarea con dos dueños cae
  en el grupo del **primero** en el orden del equipo, no en los dos: dos barras con el mismo id y
  el arrastre no sabría cuál se está moviendo. El fantasma punteado se posiciona leyendo el
  `offsetTop` real de cada fila y no como `índice × alto`: las cabeceras de grupo miden distinto y
  la cuenta se desfasaba una fila.
- **Flechas de bloqueo** en el Timeline: una línea del final de la que bloquea al arranque de la
  bloqueada, en blanco bajito y detrás de las barras, sin capturar el ratón. Si alguna de las dos
  no cae en el mes que se ve, no se dibuja. Van en **dos trazos**: el bloqueo vivo sólido, el que
  ya se destrabó punteado y azulado. Tienen que ser dos `<path>` porque el `stroke-dasharray` lo
  pone el path y no cada segmento.
- **La meta de cada barra va en columnas**, en este orden: **anillo de progreso · talla · nombre ·
  bloqueo · aviso**. El anillo va de primero, pegado a la barra, porque es lo que se barre con la
  vista bajando por el Timeline, y **su color dice qué tan lleno está** (`1–33%` azul claro,
  `34–66%` azul, `67–99%` verde, `100%` verde vivo con el centro relleno). La rampa va de azul a
  verde a propósito: es el mismo viaje que hace la tarea, de `En curso` a `Lista`. No se usa rojo
  ni ámbar, que serían los colores obvios de «va poquito», porque acá el rojo ya significa «va
  tarde» y el ámbar «bloqueada». La talla va en un **carril de ancho fijo que se pinta aunque esté
  vacío**, y el aro se pinta aunque el progreso esté en cero: sin eso, cada nombre arrancaría en
  una x distinta y la columna saldría dentada. En el Timeline sale el `⚠️` pero **no el `✅`**: que
  una tarea esté bien escrita es lo normal, y marcarlas todas con un visto hace que el aviso de la
  que sí tiene un problema se pierda entre los vistos.
- **El tablero se abre donde se dejó.** Se recuerdan la página, la barra fijada, la vista (Board o
  Timeline), el filtro de persona, el rango de fecha y si el Timeline estaba agrupado. Vive en
  `localStorage`, o sea que es **por navegador**: nada de esto viaja a la base ni lo ve nadie más,
  y el mismo enlace abierto en otro computador arranca con lo suyo.
  Lo que **no** se recuerda, a propósito: **la tarea abierta** (el panel es un gesto del momento;
  volver al otro día y encontrarse el panel de una tarea encima del tablero es una pantalla que
  nadie pidió, así que se vuelve a la vista con sus filtros, no a la tarea), **el historial** (no
  es un filtro sino otra consulta a la base, y arrancar en el archivo hace parecer que el tablero
  de hoy está vacío) y **el mes del Timeline** (al abrir se quiere ver hoy). El filtro de persona
  se valida contra el equipo: si alguien se va, su nombre guardado dejaría el tablero en blanco
  sin decir por qué.

### Las notas son un editor de verdad

Barra flotante al seleccionar texto (**negrita, cursiva, subrayado, tachado, código, enlace,
quitar formato**) y **menú de comandos con `/`**, como en Notion: Texto, Título, Subtítulo,
Apartado, Lista, Lista numerada, Casilla, Cita, Código, Imagen, Enlace y Separador.

- **Imágenes** por el menú `/`, pegando con ⌘V o arrastrando el archivo. Van al bucket `notas`
  de Storage, **nunca incrustadas en base64**, y **se borran solas** cuando salen de la nota o
  cuando se borra la tarea.
- **Las casillas son los caracteres ☐ y ☑**, no `<input>`: una lista copiada a un WhatsApp se
  sigue leyendo como lista.
- **Todo lo que entra pasa por un saneador de lista blanca**: lo que se pega, lo que estaba
  guardado y lo que sale hacia la base.
- ⌘K enlaza, ⌘⇧8 pone casilla, y ⌘/Ctrl+clic abre un enlace.
- **Tab: dentro de una lista anida y ⇧Tab desanida**, como en Notion. **Fuera de una lista mete
  una tabulación de texto**, no una sangría de bloque, y la diferencia importa: con `indent` el
  bloque quedaba envuelto en un `<blockquote>` con margen, y entonces el cursor no podía volver al
  principio de la línea ni se podía borrar la sangría, porque no había nada antes del texto. Una
  tabulación de verdad se recorre con la flecha y se quita con Backspace, de a un tab. **Enter
  hereda el arranque de la línea**, tabulaciones y casilla, y si la línea queda vacía la limpia:
  es la salida para dejar de estar sangrado.
- **`<body translate="no">`**, y no es un detalle: el traductor de Chrome reescribe el DOM metiendo
  `<font>` con el texto traducido, y dentro de un editable eso **se guarda**. La nota quedaría en
  la base traducida, encima del original.

---

## El Pulso

El marcador de la reunión semanal. Dos embudos, cada uno de contacto a resultado, definidos en
`CONFIG.pulso`. La meta es **por persona y por semana**; una métrica con `meta: null` se cuenta
pero no se exige.

**El esfuerzo no se escribe: se deduce.** Sale de las tareas que pasaron a `Lista`, tomando el
punto medio de su talla (`1h - 2h` → 1,5 h) y la fecha en que se marcaron, que la sella la base.
**Una tarea con varios responsables reparte sus horas entre ellos**: dándole las horas completas
a cada uno, el total del equipo dejaría de ser trabajo real y pasaría a ser suma de créditos.

**Regla de compensación.** Lo que no se hizo una semana se suma a la siguiente:

```
objetivo(semana) = meta + deuda que entra
deuda que sale   = max(0, objetivo - hecho)
```

Hizo 2 de 6 → la otra semana debe 10. **Pasarse de la meta no da crédito a favor**, y la semana
en curso no genera deuda todavía: solo la carga. Dos consecuencias que conviene tener presentes,
porque no son descuidos: la deuda corre para todos desde la primera semana en que alguien cargue
algo, y **no hay tope**, así que cuatro semanas flojas dan un objetivo que ya no empuja.

**Los tres colores de las gráficas no se eligen a ojo.** Son cupos de una paleta validada contra
este fondo exacto: banda de luminosidad, piso de croma, separación bajo daltonismo y contraste.
Si se tocan, hay que volver a validarlos.

---

## El Norte

Misión, visión, valores, metas y objetivos. **No se edita desde la app a propósito:** se escribe
a mano en `index.html`. Dos sitios editables son dos verdades.

---

## Antes de desplegar

**Corré `verificar.py`, y no es intercambiable con `node --check`.** `node --check` solo mira
sintaxis: le da luz verde a un archivo al que le falta media docena de funciones. Eso pasó, y
estuvo en producción.

```bash
python3 verificar.py     # que toda función que se llama esté declarada
```

Si desplegás en Vercel con un alias propio, **el alias hay que reapuntarlo en cada despliegue**:

```bash
vercel deploy --prod --yes
vercel alias set <deployment> mi-tablero.vercel.app
```

---

## Por qué está hecho así

- **Un solo archivo.** No hay build ni dependencias, así que no se pudre. Se puede abrir dentro de
  cinco años y va a funcionar igual.
- **Las reglas duras viven en Postgres, no en el navegador.** `smart` es una columna generada y
  `creado` lo blinda un disparador. Una regla que vive en la app es una regla que la próxima app
  se salta.
- **Nada que se pueda deducir se escribe a mano.** El esfuerzo sale de las tareas terminadas, no
  de un campo que alguien tiene que llenar.
- **Lo que está sin decidir se deja escrito.** En el Norte hay una sección para eso. Lo que se
  anota como abierto es lo que se termina resolviendo.

---

## Licencia

MIT. Hacé con esto lo que quieras.
