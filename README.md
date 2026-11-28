# NULLCORE MAPS

Mapa interactivo del campus universitario (UPJR) hecho en Flutter para Android, iOS, Web y escritorio.
Ayuda a estudiantes, aspirantes de nuevo ingreso y visitantes a ubicar sitios del campus.

## Funciones

- Mapa interactivo con zoom, búsqueda y filtros por categoría; al pasar el mouse por un edificio aparece una vista previa
- Acceso directo a cada salón en 360° (por número o nombre, desde el mapa, la ficha del edificio o Recorridos)
- Recorridos virtuales 360° por edificio, con flechas sobre el piso y ventanas flotantes de laboratorios (info y encargado)
- Pestaña Escolar: calendario escolar 2026 interactivo y directorio de profesores por carrera / clase
- Más: solicitar constancia, enlaces a SITO y a la página de la UPJR, apariencia y Acerca de
- Diseño "liquid glass" con tema claro y oscuro
- Panel de administración para editar pines

## Ejecutar

```bash
flutter pub get
flutter run -d chrome    # web
flutter run -d windows   # escritorio
flutter run              # dispositivo conectado
```

## Pruebas

```bash
flutter analyze
flutter test
```

`test/tour_data_test.dart` valida los recorridos 360° (estructura, imágenes, laboratorios) y reporta la calidad de sus imágenes.

## Documentación

- **[Guía de recorridos 360°](docs/GUIA_RECORRIDOS.md)**: cómo crear el recorrido de un edificio nuevo, agregar laboratorios y mejorar las imágenes.

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `lib/data/tours/` | Un archivo por edificio con su recorrido (`kTours` en `tours.dart`) |
| `lib/data/rooms.dart` | Salones con acceso directo en 360° |
| `lib/data/academic_calendar.dart` | Calendario escolar (transcrito del PDF oficial) |
| `lib/models/` | Modelos (`Tour`, `MapLocation`, `Room`, `Contact`) |
| `lib/screens/` | Pantallas (mapa, recorridos, visor 360°, administración) |
| `lib/widgets/` | Componentes (cristal, flechas, ventanas de laboratorio) |
| `assets/` | Imágenes y panorámicas 360° |
| `third_party/` | Copias locales corregidas de `panorama` y `motion_sensors` (ver su motivo en `pubspec.yaml`) |
| `docs/` | Guías |
| `test/` | Pruebas automáticas |
