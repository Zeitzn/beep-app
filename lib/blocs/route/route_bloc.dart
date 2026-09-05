import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../models/route_model.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../services/trip_api_service.dart';
import 'route_event.dart';
import 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  static const _syncInterval = Duration(minutes: 30);

  final StorageService storage;
  final LocationService location;
  final _uuid = const Uuid();
  final TripApiService? tripApi;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  Timer? _syncTimer;
  bool _syncing = false;

  RouteBloc({
    required this.storage,
    required this.location,
    this.tripApi,
  }) : super(const RouteState()) {
    on<RoutesLoaded>(_onRoutesLoaded);
    on<RouteStarted>(_onRouteStarted);
    on<RouteEnded>(_onRouteEnded);
    on<GpsStatusChecked>(_onGpsStatusChecked);
    on<GpsSettingsOpened>(_onGpsSettingsOpened);
    on<PlacaChanged>(_onPlacaChanged);
    on<TripsSynced>(_onTripsSynced);
    on<TripsSyncRequested>(_syncPending);

    _serviceStatusSub = location.serviceStatusStream().listen((_) {
      add(const GpsStatusChecked());
    });

    if (tripApi != null) {
      _scheduleSync();
    }
  }

  void _scheduleSync() {
    add(const TripsSyncRequested());
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      add(const TripsSyncRequested());
    });
  }

  Future<void> _syncPending(
    TripsSyncRequested event,
    Emitter<RouteState> emit,
  ) async {
    final api = tripApi;
    if (api == null || _syncing) return;
    _syncing = true;
    final pending = <RouteModel>[];
    try {
      final routes = await storage.loadRoutes();
      final owner = await storage.loadPlaca();
      if (owner.trim().isEmpty) return;

      pending.addAll(
        routes.where((r) => !r.uploaded && r.endDateTime != null),
      );
      if (pending.isEmpty) return;

      await api.sendTrips(owner: owner, routes: pending);

      final pendingIds = pending.map((r) => r.uuid).toSet();
      final remaining = routes
          .where((r) => !pendingIds.contains(r.uuid))
          .toList();
      await storage.saveRoutes(remaining);
      add(TripsSynced(remaining));
    } catch (e) {
      emit(state.copyWith(
        error: () => 'No se pudieron subir ${pending.length} ruta(s): $e',
      ));
    } finally {
      _syncing = false;
    }
  }

  Future<void> _onTripsSynced(
    TripsSynced event,
    Emitter<RouteState> emit,
  ) async {
    emit(state.copyWith(routes: event.routes));
  }

  @override
  Future<void> close() {
    _serviceStatusSub?.cancel();
    _syncTimer?.cancel();
    return super.close();
  }

  Future<void> _onRoutesLoaded(
    RoutesLoaded event,
    Emitter<RouteState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final routes = await storage.loadRoutes();
      final currentRoute = await storage.loadCurrentRoute();
      final gpsEnabled = await location.isGpsEnabled();
      final placa = await storage.loadPlaca();
      emit(state.copyWith(
        routes: routes,
        currentRoute: () => currentRoute,
        gpsEnabled: gpsEnabled,
        placa: placa,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: () => 'Error al cargar rutas: $e',
      ));
    }
  }

  Future<void> _onRouteStarted(
    RouteStarted event,
    Emitter<RouteState> emit,
  ) async {
    try {
      emit(state.copyWith(error: () => null));
      final gpsEnabled = await location.isGpsEnabled();
      if (!gpsEnabled) {
        emit(state.copyWith(
          gpsEnabled: false,
          error: () => 'GPS desactivado. Activa la ubicación para iniciar una ruta.',
        ));
        return;
      }

      final permission = await location.checkAndRequestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          error: () => 'Permiso de ubicación denegado.',
        ));
        return;
      }

      emit(state.copyWith(isLoading: true));

      final position = await location.getCurrentPosition();
      final route = RouteModel(
        uuid: _uuid.v4(),
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: 0,
        endLng: 0,
        amount: event.amount,
        startDateTime: DateTime.now(),
        uploaded: false,
      );

      emit(state.copyWith(
        currentRoute: () => route,
        isLoading: false,
        error: () => null,
      ));

      try {
        await storage.saveCurrentRoute(route);
      } catch (e) {
        emit(state.copyWith(
          error: () => 'Error al guardar la ruta en proceso: $e',
        ));
      }
    } on TimeoutException {
      emit(state.copyWith(
        isLoading: false,
        error: () =>
            'No se pudo obtener la ubicación. Verifica la señal GPS e intenta de nuevo.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: () => 'Error al obtener ubicación: $e',
      ));
    }
  }

  Future<void> _onRouteEnded(
    RouteEnded event,
    Emitter<RouteState> emit,
  ) async {
    if (state.currentRoute == null) return;

    try {
      emit(state.copyWith(isLoading: true));

      final position = await location.getCurrentPosition();
      final completed = state.currentRoute!.copyWith(
        endLat: position.latitude,
        endLng: position.longitude,
        endDateTime: DateTime.now(),
      );

      final updatedRoutes = [...state.routes, completed];
      await storage.saveRoutes(updatedRoutes);
      await storage.clearCurrentRoute();

      emit(state.copyWith(
        routes: updatedRoutes,
        currentRoute: () => null,
        isLoading: false,
        error: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: () => 'Error al finalizar ruta: $e',
      ));
    }
  }

  Future<void> _onGpsStatusChecked(
    GpsStatusChecked event,
    Emitter<RouteState> emit,
  ) async {
    final enabled = await location.isGpsEnabled();
    emit(state.copyWith(gpsEnabled: enabled));
  }

  Future<void> _onGpsSettingsOpened(
    GpsSettingsOpened event,
    Emitter<RouteState> emit,
  ) async {
    await location.openGpsSettings();
  }

  Future<void> _onPlacaChanged(
    PlacaChanged event,
    Emitter<RouteState> emit,
  ) async {
    emit(state.copyWith(placa: event.placa));
    await storage.savePlaca(event.placa);
  }
}