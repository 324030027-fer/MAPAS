# NULLCORE MAPS

Mapa interactivo del campus universitario (UPJR) hecho en Flutter para Android, iOS, Web y escritorio.
Ayuda a estudiantes, aspirantes de nuevo ingreso y visitantes a ubicar sitios del campus.

## Funciones

- Mapa interactivo con zoom, búsqueda y filtros por categoría; al pasar el mouse por un edificio aparece una vista previa
- Recorridos virtuales 360° por edificio, con flechas sobre el piso y ventanas flotantes de laboratorios (info, encargado y horarios)
- Horarios de laboratorios y buscador global (materia, profesor, grupo, día)
- Directorio de contactos de profesores
- Diseño "liquid glass" con tema claro y oscuro
- Panel de administración para editar pins y horarios

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
| `lib/models/` | Modelos (`Tour`, `MapLocation`, horarios) |
| `lib/screens/` | Pantallas (mapa, recorridos, visor 360°, administración) |
| `lib/widgets/` | Componentes (cristal, flechas, ventanas de laboratorio) |
| `assets/` | Imágenes y panorámicas 360° |
| `third_party/` | Copias locales corregidas de `panorama` y `motion_sensors` (ver su motivo en `pubspec.yaml`) |
| `docs/` | Guías |
| `test/` | Pruebas automáticas |
