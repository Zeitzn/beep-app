# Beep

Aplicación Flutter para registrar rutas de transporte: captura el punto de inicio y fin, monto del pasaje y persistencia local.

## Funcionalidades

- **Gestión de rutas**: cada ruta almacena `uuid`, coordenadas de inicio y fin (`startLat/Lng`, `endLat/Lng`), monto (`amount`), fechas de inicio y fin (`startDateTime`, `endDateTime`) y estado de sincronización (`uploaded`).
- **Registro de inicio**: al pulsar "Iniciar ruta" se obtiene la posición actual, se genera un `uuid` y se guarda el objeto con `uploaded: false`.
- **Registro de fin**: al pulsar "Terminar ruta" se obtiene la posición actual y se persiste el objeto finalizado en SharedPreferences.
- **Tabla de rutas**: muestra Monto, Desde/Hasta (coordenadas) e Inicio/Fin (fecha y hora) de cada ruta guardada. Incluye scroll independiente cuando la lista es larga.
- **Validación de GPS**: al ingresar a la app se chequea si el GPS está activo; si no, se muestra un aviso superior con la opción de activarlo desde la misma app.
- **Feedback de cálculo**: mientras se obtiene la ubicación, el botón muestra "Calculando..." y queda inhabilitado para evitar taps duplicados.

## Arquitectura

Uso de **BLoC** para la gestión de estados, **SharedPreferences** para la persistencia, **geolocator** para la ubicación y **uuid** para los identificadores.

```
lib/
├── main.dart                     # Entry point + wiring de providers y BlocProvider
├── models/
│   └── route_model.dart          # Modelo RouteModel (serializable a JSON)
├── services/
│   ├── location_service.dart     # GPS: posición, estado, permisos, settings
│   └── storage_service.dart      # Persistencia en SharedPreferences
├── blocs/
│   └── route/
│       ├── route_bloc.dart       # Eventos y manipulación de estado
│       ├── route_event.dart      # Eventos del BLoC
│       └── route_state.dart      # Estado del BLoC
├── screens/
│   └── home_screen.dart          # Pantalla principal
└── widgets/
    ├── amount_selector.dart      # Selector de monto (botones + input)
    ├── gps_warning_banner.dart   # Aviso de GPS desactivado
    └── route_table.dart          # Tabla de rutas guardadas
```

### Modelo `RouteModel`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `uuid` | `String` | Identificador único de la ruta |
| `startLat` / `startLng` | `double` | Coordenadas del punto de inicio |
| `endLat` / `endLng` | `double` | Coordenadas del punto de fin |
| `amount` | `double` | Monto total de la ruta |
| `startDateTime` | `DateTime` | Fecha y hora de inicio |
| `endDateTime` | `DateTime?` | Fecha y hora de fin (null en ruta en curso) |
| `uploaded` | `bool` | Indicador de sincronización pendiente/realizada |

### Eventos del BLoC

| Evento | Descripción |
|--------|-------------|
| `RoutesLoaded` | Carga las rutas guardadas al iniciar la app |
| `RouteStarted` | Inicia una ruta con el monto indicado |
| `RouteEnded` | Finaliza la ruta en curso |
| `GpsStatusChecked` | Vuelve a consultar el estado del GPS |
| `GpsSettingsOpened` | Abre los ajustes de ubicación del sistema |

El estado del GPS se mantiene en tiempo real suscribiéndose al stream de estado del servicio de `geolocator`.

## Getting Started

Requisitos: SDK de Flutter compatible con Dart `^3.13.2`.

```bash
flutter pub get
flutter run
```

### Tests

```bash
flutter analyze
flutter test
```
