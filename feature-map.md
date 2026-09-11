# Feature Map — Patrón de viajes en Beep

## Purpose

Replicar el comportamiento del mapa `patterns-map.html` (Leaflet + OpenStreetMap) dentro de la app Flutter **Beep**. La vista consulta los patrones de viaje del usuario (owner), dibuja un marcador por patrón con el área sombreada que abarca su radio de dispersión, y al tocar un marcador muestra la información completa del patrón.

La referencia `patterns-map.html` vive en `/home/zeit/Documents/Proyectos/beep/patterns-map.html`. El backend expone los patrones en `beep-api` (`GET /trips/owner/{owner}/patterns`).

## Architecture / Standards

La vista sigue los patrones existentes de la app:

- Modelo Dart en `lib/models/` con `fromJson` y tolerancia a números/strings, igual que `RouteModel`.
- Fetch HTTP en `lib/services/trip_api_service.dart`, reutilizando la misma base URL e inyectando `http.Client` (testeable con `MockClient`, como `sendTrips`).
- Pantalla en `lib/screens/` con estado local (StatefulWidget), igual que el resto de vistas de lectura.
- Navegación con `Navigator.push(MaterialPageRoute(...))`, igual que `PlacaScreen`.
- `` `Ver mapa` `` button in the action card, debajo del botón "Iniciar ruta".

Dependencias nuevas: `flutter_map` + `latlong2`. Se eligió `flutter_map` sobre `google_maps_flutter` porque usa tiles OpenStreetMap (misma fuente que la referencia Leaflet), no requiere API key ni configuración de plataforma, y `CircleMarker(useRadiusInMeter: true)` permite reproducir el radio exacto en metros del patrón.

**Nota flutter_map 8.x**: `PopupMarkerLayer` fue removido de la librería base; el tap sobre marcadores se maneja con un `GestureDetector` dentro del `child` del `Marker`, y el popup se muestra como un diálogo modal (`showDialog`) con la tabla de información. La interacción, el contenido y el orden de campos son idénticos a la referencia.

## API Contract

- **Endpoint**: `GET https://beep.todoprogramacionapi.xyz/trips/owner/{owner}/patterns`
- **`owner`**: la placa guardada en storage (`RouteBloc.state.placa`). Es el mismo identificador utilizado en `sendTrips`.
- **Response 200**: array JSON de `TripPattern` (ordenado por confianza desc, pasajeros desc, viajes desc — sorting del backend).

```json
[
  {
    "latitude": -13.1556,
    "longitude": -74.2174,
    "radiusMeters": 82.4,
    "startTime": "07:30",
    "timeWindowMinutes": 45,
    "timeWindowStart": "07:07",
    "timeWindowEnd": "07:52",
    "tripCount": 12,
    "daysObserved": 5,
    "recurrenceRate": 0.71,
    "expectedPassengers": 2.4,
    "confidenceScore": 0.83,
    "dayOfWeek": 1
  }
]
```

- Response 200 con array vacío cuando el owner no tiene viajes.
- Códigos >= 400 → el servicio lanza `http.ClientException`, MapPage muestra banner de error.

## TripPattern Model (`lib/models/trip_pattern.dart`)

| Campo                | Tipo JSON     | Dart type   |
| -------------------- | ------------- | ----------- |
| `latitude`           | number        | `double`    |
| `longitude`          | number        | `double`    |
| `radiusMeters`       | number        | `double`    |
| `startTime`          | string "HH:mm" | `String`    |
| `timeWindowMinutes`  | number        | `int`       |
| `timeWindowStart`    | string "HH:mm" | `String`    |
| `timeWindowEnd`      | string "HH:mm" | `String`    |
| `tripCount`          | number        | `int`       |
| `daysObserved`       | number        | `int`       |
| `recurrenceRate`     | number 0–1    | `double`    |
| `expectedPassengers` | number        | `double`    |
| `confidenceScore`    | number 0–1    | `double`    |
| `dayOfWeek`          | number 1–7    | `int`       |

Reglas de parseo (igual que `RouteModel`): usar `(json['x'] as num).toDouble()` / `.toInt()`; `TimeWindowStart/End` se dejan como `String` cruda para mostrarla literal.

Formateos de presentación (helper en el modelo o en la vista):
- `recurrenceRate` y `confidenceScore` → `(value * 100).toStringAsFixed(1)%`.
- `dayOfWeek` → `1=Lunes … 7=Domingo` (mapa estático).
- `radiusMeters` → `'${radiusMeters} m'`.

## MapPage Requirements (`lib/screens/map_page.dart`)

`MapPage` es una `StatefulWidget` con constructor `MapPage({required String owner})`.

### Estados de la vista
- **Cargando**: N/A mientras `fetchPatterns` no completa → pill top-center "Cargando patrones…" (blanco, sombra). Tras cargar, la capa de tiles y los marcadores entran en un solo frame.
- **Vacío**: `patterns.isEmpty` → mensaje centrado "No se encontraron patrones".
- **Error**: banner top-center con fondo `#D32F2F`, texto blanco "No se pudieron cargar los patrones: <motivo>".
- La vista siempre puede hacer *pull* al recrear el estado (initState) — sin retry manual obligatorio.

### Mapa base
- `FlutterMap` con `TileLayer` OpenStreetMap:
  - `urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'`
  - `maxZoom: 19`
  - Atribución automática de tiles.
- Vista inicial: `LatLng(-13.16, -74.23)` (Ayacucho), zoom 14 — igual que la referencia.
- Tras cargar patrones: `MapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds(...), padding: EdgeInsets.all(50), maxZoom: 16))` — equivalente a `map.fitBounds(bounds, {padding: 50, maxZoom: 16})`.

### Marcadores
Para cada patrón en orden (índice `i`):
- Color = paleta `COLORS[i % COLORS.length]` con la misma paleta de 15 de la referencia (hex → `Color(0xFF…)`).
- Marcador tipo lágrima (igual al `.custom-marker` CSS):
  - Contenedor 24×24, `borderRadius` 50% (esquina inferior-izquierda a 0), fondo `color`, borde 2px blanco, sombra `0 2px 6px rgba(0,0,0,0.45)`.
  - Punto interior blanco de 8×8 centrado.
  - Rotado `-45°`; anclado en la punta (centro-inf).
  - Se implementa con `Transform.rotate` sobre un `Container`, envuelto en el `Marker` de `MarkerLayer` con `alignment: Alignment.bottomCenter`.
- Tocar el marcador → popup.

### Círculos (área que abarca el punto)
- `CircleLayer` con un `CircleMarker` por patrón:
  - `point`: `LatLng(latitude, longitude)`
  - `radius`: `pattern.radiusMeters` con **`useRadiusInMeter: true`** (radio real en metros).
  - `color`: `color.withValues(alpha: 0.12)` (equivalente a `fillOpacity: 0.12`).
  - `borderColor`: `color`, `borderStrokeWidth: 2` (equivalente a `weight: 2`).

### Popup
- El `child` de cada `Marker` está envuelto en un `GestureDetector`; al tocar se abre un diálogo modal (`showDialog`) con la información completa (equivalente a `bindPopup`).
- Título: `Patrón #N` (N = índice 1-based).
- Tabla de 13 filas en el mismo orden que la referencia:
  1. Latitud → `latitude`
  2. Longitud → `longitude`
  3. Radio → `${radiusMeters} m`
  4. Hora → `startTime`
  5. Ventana → `${timeWindowMinutes} min`
  6. Inicio de Ventana → `timeWindowStart`
  7. Fin de Ventana → `timeWindowEnd`
  8. Viajes → `tripCount`
  9. Días observados → `daysObserved`
  10. Recurrencia → `(recurrenceRate * 100).toStringAsFixed(1)%`
  11. Pasajeros esperados → `expectedPassengers`
  12. Confianza → `(confidenceScore * 100).toStringAsFixed(1)%`
  13. Día → nombre derivado de `dayOfWeek`
- La primera columna (etiqueta) en negrita; separadores finos.

## TripApiService Changes (`lib/services/trip_api_service.dart`)

- Reusar la constante existente: `_url = 'https://beep.todoprogramacionapi.xyz/trips'`.
- Nuevo método:

```dart
Future<List<TripPattern>> fetchPatterns(String owner) async {
  final uri = Uri.parse('$_url/owner/$owner/patterns');
  final response = await _client.get(uri);
  if (response.statusCode >= 400) {
    throw http.ClientException('Trip API error: ${response.statusCode}', uri);
  }
  final list = jsonDecode(response.body) as List;
  return list
      .map((e) => TripPattern.fromJson(e as Map<String, dynamic>))
      .toList();
}
```

## HomeScreen Changes (`lib/screens/home_screen.dart`)

- En `_buildActionButtons`, dentro de la `Column` que ya contiene el botón "Iniciar ruta"/"Terminar ruta", debajo de él:
  - `SizedBox(height: 12)`
  - Botón secundario full-width, altura 48 (menor que el principal de 56), texto **"Ver mapa"** con icono `Icons.map`.
  - Estilo `TextButton`/`OutlinedButton` con color primario (`purple`), bordes redondeados 12, fondo `purple.withValues(alpha: 0.08)`.
- `onPressed` → `Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapPage(owner: state.placa)))`.
- El owner siempre está disponible: `HomeScreen` solo se muestra cuando hay placa (`RootScreen`).
- Se elimina el bloque comentado del `MapButton` (dead code) dentro de `_buildActionButtons`.

## Tests

- `test/trip_pattern_test.dart` — parsing de `TripPattern.fromJson`: números flotantes/int, tolerancia `num`, valores de referencia; helper de nombre de día.
- `test/trip_api_service_test.dart` (extender) — `fetchPatterns`:
  - GET correcto a `/trips/owner/{owner}/patterns`, parámetro `owner` en el path.
  - 200 con array válido → devuelve lista parseada.
  - 200 con `[]` → lista vacía.
  - 500 → `http.ClientException`.
- `test/map_page_test.dart` — widget test de `MapPage` con `MockClient`:
  - Loading → render de marcadores + popup al tocar (o al menos sin error y sin banner).
  - Error HTTP → banner rojo visible.
- `test/home_screen_test.dart` (o widget test) — el botón "Ver mapa" navega a `MapPage`.

## Verification

```bash
export PATH="/home/zeit/fvm/versions/3.47.2/bin:$PATH"
flutter pub get
flutter analyze
flutter test
```

## Files

| Archivo                              | Acción    |
| ------------------------------------ | --------- |
| `feature-map.md`                     | nuevo     |
| `pubspec.yaml`                       | modificar (flutter_map, latlong2) |
| `lib/models/trip_pattern.dart`       | nuevo     |
| `lib/services/trip_api_service.dart` | modificar |
| `lib/screens/map_page.dart`          | nuevo     |
| `lib/screens/home_screen.dart`       | modificar |
| `test/trip_pattern_test.dart`        | nuevo     |
| `test/trip_api_service_test.dart`    | modificar |
| `test/map_page_test.dart`            | nuevo     |