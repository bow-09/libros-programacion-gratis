"""Genera assets/data/learning_paths.json. El contenido se escribe aquí en
Markdown legible y el script lo vuelca a JSON.  Uso: python3 tool/build_learning_paths.py"""
import json
from pathlib import Path


def teoria(id, titulo, contenido):
    return {"id": id, "titulo": titulo, "tipo": "teoria", "contenido": contenido.strip()}


def practica(id, titulo, contenido, solucion):
    return {"id": id, "titulo": titulo, "tipo": "practica",
            "contenido": contenido.strip(), "solucion": solucion.strip()}


def quiz(id, titulo, preguntas):
    return {"id": id, "titulo": titulo, "tipo": "quiz", "preguntas": [
        {"pregunta": p, "opciones": o, "correcta": c, "explicacion": e} for p, o, c, e in preguntas]}


DART = {
    "id": "dart-fundamentos",
    "titulo": "Fundamentos de Dart",
    "descripcion": "El lenguaje detrás de Flutter: variables, tipos, funciones y colecciones, con práctica en cada paso.",
    "nivel": "Principiante",
    "libros": ["aprendiendo-dart", "programacion-estructurada-y-orientada-a-objetos-con-dart"],
    "modulos": [
        {"id": "dart-m1", "titulo": "1. Variables y tipos", "lecciones": [
            teoria("dart-m1-l1", "Tu primer programa", """
Todo programa en Dart empieza en la función `main`:

```dart
void main() {
  print('Hola, meta-code');
}
```

- `void` indica que la función no devuelve nada.
- `print` escribe un texto en la consola.
- Cada instrucción termina en punto y coma.

**Por qué importa:** Dart necesita un único punto de entrada para saber por dónde empezar. Una app de Flutter también arranca en `main`; solo cambia lo que hay dentro.

Puedes probar cualquier ejemplo de esta ruta, sin instalar nada, en [dartpad.dev](https://dartpad.dev).
"""),
            teoria("dart-m1-l2", "Variables, tipos y null safety", """
Una variable guarda un valor con un tipo:

```dart
String nombre = 'Ada';
int edad = 36;
double altura = 1.65;
bool activa = true;
```

Si el valor inicial deja claro el tipo, puedes escribir `var` y Dart lo deduce:

```dart
var ciudad = 'Londres'; // String
```

### `final` y `const`

- `final`: se asigna una sola vez, mientras el programa corre.
- `const`: su valor se conoce ya al compilar.

```dart
final ahora = DateTime.now(); // solo se sabe al ejecutar
const pi = 3.1416;            // se sabe siempre
```

### Null safety

Por defecto una variable **no puede** valer `null`. Si necesitas que pueda, añade `?` al tipo:

```dart
String? apodo;                  // puede ser null
print(apodo?.length);           // null: `?.` no falla si apodo es null
print(apodo ?? 'sin apodo');    // `??` da un valor alternativo
```

**Por qué importa:** el error más común en muchos lenguajes es usar un valor que no existe. Dart te obliga a decidirlo al escribir el código, no cuando la app ya falló en manos del usuario.
"""),
            practica("dart-m1-l3", "Práctica: ficha de usuario", """
Escribe un programa que:

1. Guarde un nombre (`String`), un año de nacimiento (`int`) y un apodo que **puede no existir**.
2. Calcule la edad que cumple la persona en 2026.
3. Imprima: `Ada (la Condesa) cumple 211 años`. Si no hay apodo, debe imprimir `sin apodo` entre los paréntesis.

Pista: dentro de un texto puedes insertar valores con `$variable` o `${expresion}`.
""", """
```dart
void main() {
  const nombre = 'Ada';
  const nacimiento = 1815;
  String? apodo = 'la Condesa';

  final edad = 2026 - nacimiento;
  print('$nombre (${apodo ?? 'sin apodo'}) cumple $edad años');
}
```

Prueba a cambiar `apodo` por `null` y comprueba que el programa sigue funcionando.
"""),
            quiz("dart-m1-l4", "Cuestionario: variables y tipos", [
                ("¿Qué diferencia hay entre `final` y `const`?",
                 ["Ninguna, son sinónimos", "`const` se conoce al compilar; `final` se asigna una vez al ejecutar", "`final` solo sirve para números"],
                 1, "`const` exige un valor conocido en compilación; `final` solo impide reasignar."),
                ("¿Qué imprime `String? a; print(a ?? 'vacío');`?",
                 ["null", "vacío", "Da un error"],
                 1, "`??` devuelve el valor de la derecha cuando el de la izquierda es null."),
                ("¿Qué tipo deduce Dart para `var x = 3.0;`?",
                 ["int", "double", "num"],
                 1, "Un literal con punto decimal es un `double`."),
            ]),
        ]},
        {"id": "dart-m2", "titulo": "2. Funciones y colecciones", "lecciones": [
            teoria("dart-m2-l1", "Funciones", """
Una función recibe datos, hace algo y devuelve un resultado:

```dart
int sumar(int a, int b) {
  return a + b;
}
```

Si el cuerpo es una sola expresión, existe la forma corta con flecha:

```dart
int sumar(int a, int b) => a + b;
```

### Parámetros con nombre

Los parámetros entre llaves se pasan por nombre, lo que hace las llamadas más legibles. `required` los vuelve obligatorios; los demás necesitan un valor por defecto o ser anulables.

```dart
String saludar({required String nombre, String saludo = 'Hola'}) => '$saludo, $nombre';

saludar(nombre: 'Ada');                    // Hola, Ada
saludar(nombre: 'Ada', saludo: 'Buenas');  // Buenas, Ada
```

**Por qué importa:** Flutter usa parámetros con nombre en todas partes (`Text('Hola', style: ...)`). Entenderlos aquí te ahorra confusión después.
"""),
            teoria("dart-m2-l2", "Listas y mapas", """
Una **lista** guarda valores en orden; un **mapa** asocia claves con valores.

```dart
final lenguajes = <String>['Dart', 'Python', 'Go'];
lenguajes.add('Rust');
print(lenguajes[0]);      // Dart
print(lenguajes.length);  // 4

final estrellas = <String, int>{'Dart': 5, 'Go': 4};
print(estrellas['Dart']);    // 5
print(estrellas['Kotlin']);  // null: la clave no existe
```

### Transformar sin bucles

```dart
final largos = lenguajes.where((l) => l.length > 2).toList();
final mayus  = lenguajes.map((l) => l.toUpperCase()).toList();
```

`where` filtra y `map` transforma. Ambos devuelven un resultado nuevo y dejan la lista original intacta.

**Por qué importa:** casi toda pantalla de una app es una lista de datos transformada en una lista de elementos visuales. `map` es justo esa operación.
"""),
            practica("dart-m2-l3", "Práctica: notas de un curso", """
Dado este mapa de notas:

```dart
final notas = {'Ana': 8.5, 'Luis': 4.0, 'Marta': 6.5, 'Iván': 9.0};
```

1. Escribe una función `aprobados` que reciba el mapa y devuelva la lista de nombres con nota mayor o igual a 5.
2. Escribe una función `media` que devuelva la nota media.
3. Imprime ambos resultados.

Pista: `notas.entries` te da pares con `.key` y `.value`; `notas.values` te da solo las notas.
""", """
```dart
List<String> aprobados(Map<String, double> notas) =>
    notas.entries.where((e) => e.value >= 5).map((e) => e.key).toList();

double media(Map<String, double> notas) =>
    notas.values.reduce((a, b) => a + b) / notas.length;

void main() {
  final notas = {'Ana': 8.5, 'Luis': 4.0, 'Marta': 6.5, 'Iván': 9.0};
  print(aprobados(notas)); // [Ana, Marta, Iván]
  print(media(notas));     // 7.0
}
```

Pregunta para pensar: ¿qué pasa con `media` si el mapa está vacío? ¿Cómo lo protegerías?
"""),
            quiz("dart-m2-l4", "Cuestionario: funciones y colecciones", [
                ("¿Qué devuelve `[1, 2, 3].map((n) => n * 2).toList()`?",
                 ["[1, 2, 3]", "[2, 4, 6]", "12"],
                 1, "`map` aplica la función a cada elemento y produce una lista nueva."),
                ("¿Qué obtienes al leer una clave que no existe en un mapa?",
                 ["Un error", "null", "Una cadena vacía"],
                 1, "Por eso el resultado de `mapa[clave]` es de tipo anulable."),
                ("¿Para qué sirve `required` en un parámetro con nombre?",
                 ["Lo hace obligatorio al llamar a la función", "Lo convierte en constante", "Le da un valor por defecto"],
                 0, "Sin `required`, un parámetro con nombre es opcional."),
            ]),
        ]},
    ],
}

GIT = {
    "id": "git-desde-cero",
    "titulo": "Git desde cero",
    "descripcion": "Guarda el historial de tu código, trabaja en ramas y publica en GitHub sin miedo a romper nada.",
    "nivel": "Principiante",
    "libros": ["pro-git", "git-la-guia-sencilla", "reglas-de-vuelo-para-git"],
    "modulos": [
        {"id": "git-m1", "titulo": "1. Guardar tu trabajo", "lecciones": [
            teoria("git-m1-l1", "Qué es Git y qué problema resuelve", """
Git guarda **fotografías** de tu proyecto a lo largo del tiempo. Cada fotografía se llama *commit* y puedes volver a cualquiera de ellas.

Sin Git acabas con `proyecto_final.zip`, `proyecto_final_v2.zip` y `proyecto_final_ahora_si.zip`. Con Git tienes una sola carpeta y un historial ordenado que explica qué cambió y por qué.

Git trabaja con tres zonas:

| Zona | Qué contiene |
| --- | --- |
| Directorio de trabajo | Tus archivos tal como los ves |
| Área de preparación (*staging*) | Los cambios que elegiste para el próximo commit |
| Repositorio | El historial de commits ya guardados |

**Por qué hay un paso intermedio:** el *staging* te deja guardar solo una parte de lo que tocaste. Así cada commit cuenta una única cosa y el historial se entiende.

Git no es GitHub: Git funciona en tu ordenador; GitHub es un sitio donde publicar una copia.
"""),
            teoria("git-m1-l2", "El ciclo básico: add y commit", """
```bash
git init                      # convierte la carpeta en un repositorio
git status                    # qué cambió y en qué zona está
git add notas.txt             # prepara un archivo
git commit -m "Añade notas"   # guarda la fotografía
git log --oneline             # historial resumido
```

`git status` es tu mejor amigo: úsalo antes y después de cada orden hasta que el ciclo te salga solo.

### Un buen mensaje de commit

Describe **qué cambia y por qué**, no qué teclas pulsaste:

- Mal: `cambios`, `arreglos varios`
- Bien: `Corrige el cálculo de la media con lista vacía`

Para ver qué cambiaste antes de guardarlo:

```bash
git diff            # cambios sin preparar
git diff --staged   # cambios ya preparados
```
"""),
            practica("git-m1-l3", "Práctica: tu primer repositorio", """
En una carpeta nueva:

1. Inicia un repositorio.
2. Crea `README.md` con una línea de texto y guárdalo en un commit.
3. Añade una segunda línea al archivo y crea un archivo `notas.txt`.
4. Haz **dos commits separados**: uno para el cambio del README y otro para `notas.txt`.
5. Comprueba que el historial muestra tres commits.
""", """
```bash
mkdir practica-git && cd practica-git
git init

echo "# Práctica de Git" > README.md
git add README.md
git commit -m "Crea el README"

echo "Segunda línea" >> README.md
echo "Mis notas" > notas.txt

git add README.md
git commit -m "Amplía el README"

git add notas.txt
git commit -m "Añade el archivo de notas"

git log --oneline
```

El paso 4 es el importante: como preparas cada archivo por separado, puedes repartir tu trabajo en commits con un solo tema cada uno.
"""),
            quiz("git-m1-l4", "Cuestionario: guardar tu trabajo", [
                ("¿Qué hace `git add archivo.txt`?",
                 ["Guarda el archivo en el historial", "Prepara el archivo para el próximo commit", "Sube el archivo a GitHub"],
                 1, "`add` solo mueve el cambio al área de preparación; quien lo guarda es `commit`."),
                ("¿Qué orden te dice en qué estado está cada archivo?",
                 ["git log", "git status", "git init"],
                 1, "`git log` muestra commits ya hechos; `git status` muestra el estado actual."),
                ("¿Cuál es la relación entre Git y GitHub?",
                 ["Son lo mismo", "GitHub es un servicio donde publicar repositorios de Git", "Git solo funciona con conexión a GitHub"],
                 1, "Git funciona por completo en local; GitHub aloja copias remotas."),
            ]),
        ]},
        {"id": "git-m2", "titulo": "2. Ramas y trabajo remoto", "lecciones": [
            teoria("git-m2-l1", "Ramas: probar sin romper", """
Una rama es una línea de trabajo independiente. Te permite probar una idea sin tocar la versión que funciona.

```bash
git switch -c nueva-funcion   # crea la rama y cambia a ella
# ...editas y haces commits...
git switch main               # vuelves a la rama principal
git merge nueva-funcion       # traes los cambios
git branch -d nueva-funcion   # borras la rama ya fusionada
```

### Conflictos

Si dos ramas cambian las mismas líneas, Git no adivina cuál quieres y marca el archivo:

```text
<<<<<<< HEAD
color = "azul"
=======
color = "verde"
>>>>>>> nueva-funcion
```

Edita el archivo para dejar la versión correcta, borra las marcas y termina con `git add` y `git commit`. Un conflicto no es un error: es Git pidiéndote una decisión que solo tú puedes tomar.
"""),
            teoria("git-m2-l2", "Remotos: publicar en GitHub", """
Un *remoto* es una copia del repositorio en otro lugar, normalmente GitHub.

```bash
git remote add origin https://github.com/usuario/proyecto.git
git push -u origin main   # sube tus commits (la primera vez, con -u)
git pull                  # trae y fusiona los cambios de otros
git clone <url>           # descarga un repositorio existente
```

El flujo habitual en equipo:

1. Creas una rama para tu cambio.
2. Haces commits y subes la rama con `git push`.
3. Abres una *pull request* en GitHub para que otra persona lo revise.
4. Tras la revisión, la rama se fusiona en `main`.

**Por qué no trabajar directamente en `main`:** la rama principal debe funcionar siempre. Las ramas y la revisión son la red de seguridad.
"""),
            practica("git-m2-l3", "Práctica: provocar y resolver un conflicto", """
En el repositorio de la práctica anterior:

1. Crea una rama `saludo` y cambia la primera línea del README. Haz commit.
2. Vuelve a `main` y cambia **esa misma línea** con otro texto. Haz commit.
3. Fusiona `saludo` en `main`. Git avisará de un conflicto.
4. Resuélvelo dejando el texto que prefieras y completa la fusión.
""", """
```bash
git switch -c saludo
# edita la primera línea del README: "# Hola desde la rama"
git commit -am "Cambia el título en la rama"

git switch main
# edita la misma línea: "# Hola desde main"
git commit -am "Cambia el título en main"

git merge saludo       # CONFLICT en README.md
# abre README.md, deja una sola versión y borra las marcas <<<<<<< ======= >>>>>>>
git add README.md
git commit             # completa la fusión
git log --oneline --graph
```

`git log --graph` dibuja cómo se separaron y volvieron a unirse las dos ramas.
"""),
            quiz("git-m2-l4", "Cuestionario: ramas y remotos", [
                ("¿Para qué sirve una rama?",
                 ["Para hacer una copia de seguridad en la nube", "Para trabajar en un cambio sin afectar a la rama principal", "Para borrar commits antiguos"],
                 1, "Una rama aísla tu trabajo hasta que decides fusionarlo."),
                ("¿Qué debes hacer ante un conflicto de fusión?",
                 ["Borrar el repositorio y clonarlo de nuevo", "Editar el archivo, dejar la versión correcta, y hacer add y commit", "Esperar a que Git lo resuelva solo"],
                 1, "Git marca las dos versiones y espera a que elijas."),
                ("¿Qué orden sube tus commits al remoto?",
                 ["git pull", "git push", "git clone"],
                 1, "`push` envía, `pull` trae y `clone` descarga un repositorio completo."),
            ]),
        ]},
    ],
}

out = Path(__file__).resolve().parent.parent / "assets" / "data" / "learning_paths.json"
out.write_text(json.dumps({"rutas": [DART, GIT]}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"{sum(len(m['lecciones']) for r in (DART, GIT) for m in r['modulos'])} lecciones en 2 rutas")
