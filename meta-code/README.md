# meta-code

Aplicación de aprendizaje activo de programación en español, hecha con Flutter (Android y web).

## Secciones

| Sección | Carpeta | Qué hace hoy |
| --- | --- | --- |
| Rutas | `lib/features/learning_paths` | Rutas por módulos con teoría, prácticas con solución y cuestionarios. El progreso se guarda en el dispositivo. |
| Tutor | `lib/features/tutor_companion` | Chat con un acompañante configurable (nombre, personalidad, tono, modo conceptual o creador, nivel). Usa la API de Claude con la clave que introduce el usuario. |
| Laboratorio | `lib/features/agent_lab` | Registro de skills propias (servidor MCP o API REST) con prueba de conexión y listado de herramientas MCP. |
| Biblioteca | `lib/features/library_catalog` | Catálogo de 314 libros gratuitos con búsqueda y filtros por categoría y formato. Abre cada libro en su fuente original. |

## Desarrollo

```bash
flutter pub get
flutter run -d web-server   # vista previa en el navegador
flutter analyze
flutter test
```

## Datos

Los datos viven en `assets/data/` y se generan con los scripts de `tool/`:

- `libros_catalogo.json`: `node meta-code/tool/export_catalog.mjs` (desde la raíz del repositorio). Lo extrae del catálogo de [librosgratis.dev](https://librosgratis.dev).
- `learning_paths.json`: `python3 tool/build_learning_paths.py`. Las lecciones se escriben en ese script, en Markdown.

## Pendiente

- Cuentas de usuario, suscripción y pagos (requieren un servidor propio).
- Servidor intermedio para el tutor, para no depender de que cada usuario traiga su clave.
- Que el tutor use las skills registradas en el laboratorio.
- Más rutas: Flutter, Python, Algoritmos, Inteligencia Artificial.
- Guardar claves y tokens en almacenamiento cifrado del dispositivo.
