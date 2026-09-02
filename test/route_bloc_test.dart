import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beep/blocs/route/route_bloc.dart';
import 'package:beep/blocs/route/route_event.dart';
import 'package:beep/models/route_model.dart';
import 'package:beep/services/location_service.dart';
import 'package:beep/services/storage_service.dart';

class FakeLocationService extends LocationService {
  @override
  Future<bool> isGpsEnabled() async => true;

  @override
  Future<LocationPermission> checkAndRequestPermission() async =>
      LocationPermission.always;

  @override
  Future<Position> getCurrentPosition() async => Position(
        longitude: -58.3816,
        latitude: -34.6037,
        timestamp: DateTime(2026, 9, 1, 10, 30),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  @override
  Stream<ServiceStatus> serviceStatusStream() => const Stream.empty();
}

RouteModel _storedCurrentRoute() => RouteModel(
      uuid: 'restored',
      startLat: -34.60,
      startLng: -58.38,
      endLat: 0,
      endLng: 0,
      amount: 7,
      startDateTime: DateTime(2026, 9, 1, 9, 0),
      uploaded: false,
    );

Future<RouteModel?> _waitForSavedCurrentRoute(StorageService storage) async {
  RouteModel? saved;
  for (var i = 0; i < 50; i++) {
    saved = await storage.loadCurrentRoute();
    if (saved != null) break;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return saved;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('RouteStarted persiste la ruta en curso en el storage', () async {
    final storage = StorageService();
    final bloc = RouteBloc(
      storage: storage,
      location: FakeLocationService(),
    );

    bloc.add(const RouteStarted(5));
    await bloc.stream.firstWhere((s) => s.currentRoute != null);

    final saved = await _waitForSavedCurrentRoute(storage);
    expect(saved, isNotNull);
    expect(saved!.amount, 5);
    expect(saved.startLat, -34.6037);
    expect(saved.endDateTime, isNull);

    await bloc.close();
  });

  test('RoutesLoaded restaura la ruta en curso guardada', () async {
    await StorageService().saveCurrentRoute(_storedCurrentRoute());

    final bloc = RouteBloc(
      storage: StorageService(),
      location: FakeLocationService(),
    );

    bloc.add(const RoutesLoaded());
    final state = await bloc.stream.firstWhere((s) => !s.isLoading);

    expect(state.currentRoute, isNotNull);
    expect(state.currentRoute!.uuid, 'restored');
    expect(state.currentRoute!.amount, 7);

    await bloc.close();
  });

  test('RouteEnded limpia la ruta en curso y la agrega a las completadas',
      () async {
    await StorageService().saveCurrentRoute(_storedCurrentRoute());

    final storage = StorageService();
    final bloc = RouteBloc(
      storage: storage,
      location: FakeLocationService(),
    );

    bloc.add(const RoutesLoaded());
    await bloc.stream.firstWhere((s) => !s.isLoading);

    bloc.add(const RouteEnded());
    final state = await bloc.stream.firstWhere((s) => !s.isLoading);

    expect(state.currentRoute, isNull);
    expect(state.routes, hasLength(1));
    expect(state.routes.single.uuid, 'restored');
    expect(state.routes.single.endDateTime, isNotNull);
    expect(state.routes.single.endLat, -34.6037);

    expect(await storage.loadCurrentRoute(), isNull);
    expect(await storage.loadRoutes(), hasLength(1));

    await bloc.close();
  });
}