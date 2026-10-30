# Guía de recorridos 360°

Cómo crear el recorrido de un edificio nuevo, de cero a terminado, y cómo
mejorar las imágenes de uno existente. Está escrita sobre cómo funciona hoy el
proyecto (el recorrido del edificio LT es el ejemplo completo).

## Cómo está armado

| Qué | Dónde |
| --- | --- |
| Modelo de un recorrido (paradas, tramos, laboratorios) y su validación | `lib/models/tour.dart` |
| Datos de cada edificio | `lib/data/tours/<edificio>_tour.dart` (ejemplo: `lt_tour.dart`) |
| Lista de todos los recorridos | `lib/data/tours/tours.dart` (`kTours`) |
| Visor 360° (flechas, laboratorios, orientación) | `lib/screens/panorama_viewer.dart` |
| Flecha de cristal | `lib/widgets/tour_arrow.dart` |
| Tarjeta y ventanas de laboratorio | `lib/widgets/lab_tour_widgets.dart` |
| Orientación de llegada (recto / esquinas) | `lib/core/utils/tour_utils.dart` |
| Ficha de cada laboratorio (encargado, descripción, foto) | `MapProvider` (`_getDefaultMapPoints`) |
| Horarios de los laboratorios | `lib/data/default_schedules.dart` |
| Prueba automática de los recorridos | `test/tour_data_test.dart` |

Un recorrido es un grafo: **paradas** (una panorámica cada una) unidas por
**tramos**. Cada tramo se declara una sola vez y el visor genera solo las
flechas de ida y de vuelta.

---

## 1. Antes de tomar fotos: planea el edificio

1. Dibuja el plano del edificio y marca las paradas: entradas, esquinas,
   pasillos, baños, laboratorios, salones y oficinas.
2. Decide la ruta como un grafo (qué parada conecta con cuál). Un edificio en
   forma de H, por ejemplo, es un lazo cerrado.
3. Ponle a cada parada un **id corto** (`E1`, `P1`, `BH`...). Los ids solo
   deben ser únicos **dentro de cada recorrido**, así que dos edificios pueden
   usar los mismos.

## 2. Toma las fotos 360°

- Cámara 360° (Insta360, Ricoh Theta...) o la app Google Street View / Photo
  Sphere. Exporta en **equirectangular 2:1** (por ejemplo 4096×2048).
- **Truco que ahorra trabajo:** toma cada foto con la cámara apuntando siempre
  en el **sentido de la marcha**. Así el "adelante" cae siempre en 0° y el
  "atrás" en 180°, y los rumbos de las flechas dejan de ser un cálculo a ojo.
- Misma altura (~1.5 m), trípode, buena luz y sin gente en medio.
- Una foto cada 3 a 6 m, y una en cada esquina, cruce y puerta de laboratorio.

## 3. Prepara las imágenes

- Tamaño **4096×2048**, JPG calidad 80–85, de 0.8 a 1.5 MB.
- No pases de 4096 de ancho: algunos celulares fallan con texturas mayores.
- Nómbralas por edificio y parada (p. ej. `UD1_E1.jpg`) y guárdalas en
  `assets/`. El `pubspec.yaml` ya incluye `assets/` (solo archivos sueltos). Si
  creas subcarpetas, agrega cada una al `pubspec.yaml` (`- assets/ud1/`).

## 4. Crea el archivo del edificio

Copia `lib/data/tours/lt_tour.dart` como `lib/data/tours/<edificio>_tour.dart` y
edítalo:

```dart
final Tour ud1Tour = Tour(
  id: 'ud1',
  title: 'Recorrido UD1',
  shortName: 'UD1',                       // se usa en el botón "Iniciar recorrido"
  subtitle: 'Aulas · Pasillos',
  coverAsset: 'assets/UD1_E1.jpg',        // imagen de la tarjeta
  startId: 'E1',                          // parada donde empieza
  mapLocationId: 'UD1',                   // id del edificio en el mapa (opcional)
  stops: const [
    // (id, título, categoría, panorama)
    TourStop('E1', 'Entrada', 'Entrada', 'assets/UD1_E1.jpg'),
    TourStop('P1', 'Pasillo 1', 'Pasillo', 'assets/UD1_P1.jpg'),
  ],
  edges: const [
    // (A, rumbo en A hacia B, B, rumbo en B hacia A)
    TourEdge('E1', 0, 'P1', 180),
  ],
);
```

Y regístralo en `lib/data/tours/tours.dart`:

```dart
final List<Tour> kTours = [
  ltTour,
  ud1Tour,   // <- nuevo
];
```

Con eso aparece solo una tarjeta nueva en la pestaña Recorridos y, si definiste
`mapLocationId`, el botón "Iniciar recorrido 360°" en la hoja de ese edificio.

### Categorías de las paradas

- `Entrada`, `Baños H` y `Baños M`: su flecha muestra el nombre del destino.
- `Pasillo`, `Esquina` y cualquier otra: solo la flecha, sin nombre.
  (La lista se cambia en `kImportantTourCategories`, en `tour_utils.dart`.)

## 5. Cómo sacar los rumbos (yaw) de las flechas

Abre el panorama y mide la columna `x` y la fila `y`, en píxeles, del centro de
la puerta o del pasillo al que quieres ir:

```
yaw   = (x / ancho) × 360 − 180        (de −180 a 180)
pitch = 90 − (y / alto) × 180
```

Si tomaste todas las fotos mirando en el sentido de la marcha, casi todo es
`0` (adelante) y `180` (atrás). Las flechas se colocan solas sobre el piso.

La vista de llegada se resuelve sola:

- En pasillos (el siguiente tramo sigue más o menos recto) mira recto.
- En esquinas (exactamente dos enlaces que forman menos de 120°) mira a la
  bisectriz entre ambos pasillos y se aleja para que se vean los dos.

## 6. Laboratorios, salones y oficinas

1. **Ficha:** en `_getDefaultMapPoints` (`MapProvider`), dentro del edificio
   (`careers` → `LabInfo`): nombre, descripción, encargado, contacto, foto de
   referencia (`imageThumbnail`) y su panorama (`asset360`).
2. **Horarios:** en `lib/data/default_schedules.dart` (o desde el panel de
   administración): materia, día, hora de inicio y fin, grupo y profesor.
3. **Parada del interior:** añade su panorama como `TourStop` y un `TourEdge`
   desde el pasillo (rumbo de la puerta y rumbo de la salida dentro del salón).
4. **Registro** en el campo `labs` del recorrido:

```dart
labs: const {
  'LT': TourLabRef(
    locationId: 'LT_MAP',            // edificio del mapa que tiene la ficha
    labName: 'LAB. DE TELEMÁTICA',   // nombre en LabInfo
    scheduleName: 'Telemática',      // nombre en los horarios
    wallYaw: 180,                    // pared donde va la ventana (rumbo)
    wallPitch: 6,                    // altura de la ventana (grados)
  ),
},
```

Con eso salen solas: la tarjeta flotante en el pasillo (con foto, resumen y
flecha para entrar), la ventana de información anclada a la pared, los botones
**Información** y **Salir**, y los horarios por día, módulo, grupo y profesor.
La vista entra mirando a la pared de `wallYaw`: elige la pared más despejada
del salón.

Las oficinas y salones funcionan igual. Si necesitan otra información (por
ejemplo responsable y horario de atención), hay que generalizar esas ventanas.

## 7. Prueba antes de dar por bueno un tramo

1. Corre las pruebas automáticas:

   ```bash
   flutter test test/tour_data_test.dart
   ```

   Revisan que el recorrido esté bien armado (paradas, tramos, laboratorios),
   que existan todas las imágenes, que cada tramo tenga ida y vuelta y que cada
   laboratorio tenga ficha y horarios. También imprimen un **reporte de calidad**
   de las imágenes (no 2:1, resolución baja o demasiado grandes).
2. `flutter analyze` sin errores.
3. Recorre el edificio completo **de ida y de vuelta**: las flechas deben
   apuntar al pasillo correcto y las esquinas deben mostrar ambos caminos.
4. Revisa cada laboratorio: tarjeta, entrar, ventana, horarios y Salir.

> **Datos guardados en el dispositivo.** El mapa y los horarios se guardan en
> el dispositivo la primera vez (`mapPoints` y `location_schedules_v1`). Si
> cambias los datos por defecto en el código, los equipos que ya los tenían
> guardados **no verán el cambio**. Para probar, borra los datos de la app: en
> web, "borrar datos del sitio"; en Windows, el archivo `shared_preferences.json`
> en `AppData\Roaming\com.example\nullcore_maps`; en celular, desinstala la
> app o borra sus datos.
>
> Los recorridos (paradas y tramos) **no** se guardan: viven en el código y
> siempre se actualizan.

---

## Cómo mejorar las imágenes de baja calidad

El reporte de `flutter test test/tour_data_test.dart` marca cuáles son. Para el
recorrido LT, hoy son:

- `P2.jpg` y `S3.jpg` (Baños Mujeres): 1600×800, la mitad de resolución que el
  resto. Son las más borrosas.
- `P1.jpg`: 3556×2248, no es 2:1, así que se ve estirada.

Otras imágenes del proyecto que conviene revisar aunque no sean del recorrido:
`moviles.jpg` mide 8704×4352 y pesa 4.9 MB (demasiado grande, aporta al lag) y
`redes.jpg` mide 1600×900, así que no sirve como panorama.

**Para reemplazar una imagen**

1. Lo ideal es **volver a tomarla** en equirectangular 4096×2048 y con la
   cámara en el mismo sentido que las demás. Reescalar una foto pequeña no
   mejora su calidad. Si no puedes volver a tomarla, un escalador con IA
   (por ejemplo Upscayl, gratis) ayuda algo, aunque deja artefactos.
2. Para reducir las demasiado grandes usa Squoosh (squoosh.app) o, por línea de
   comandos:

   ```bash
   magick entrada.jpg -resize 4096x2048 -quality 82 salida.jpg
   ```

3. **Guárdala con el mismo nombre** en `assets/`. No hace falta cambiar código.
4. Si la nueva foto está **girada** respecto a la anterior, hay que recalcular
   los rumbos de sus flechas: una rotación de X° suma X° a todos. Por eso
   conviene mantener siempre el sentido de la marcha.
5. Vuelve a correr `flutter test test/tour_data_test.dart` (el reporte debe
   quedar sin avisos) y relanza la app. Con hot restart (`R`) o
   `flutter run -d windows` se recoge la imagen nueva; en web, vuelve a compilar.
