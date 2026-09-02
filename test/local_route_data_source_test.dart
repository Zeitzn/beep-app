import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beep/models/route_model.dart';
import 'package:beep/services/local_route_data_source.dart';
import 'package:beep/services/storage_service.dart';
import 'package:beep/utils/route_order.dart';

RouteModel _route(String uuid, double lat, double lng) => RouteModel(
      uuid: uuid,
      startLat: lat,
      startLng: lng,
      endLat: 0,
      endLng: 0,
      amount: 5,
      startDateTime: DateTime(2026, 9, 1, 10, 30),
      uploaded: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toma los últimos N puntos de inicio y los ordena por cercanía',
      () async {
    SharedPreferences.setMockInitialValues({});

    final storage = StorageService();
    await storage.saveRoutes([
      _route('o1', 10, 10),
      _route('o2', 9, 9),
      _route('o3', 3, 3),
      _route('o4', 2, 2),
      _route('o5', 1, 1),
      _route('o6', 0.5, 0.5),
    ]);

    final dataSource = LocalRouteDataSource(storage: storage);
    final origin = const LatLng(0, 0);

    final ordered = await dataSource.calculateOrderedRoute(origin: origin);

    // Las últimas 5 rutas (o2..o6), sin la más antigua (o1).
    // Ordenadas por cercanía: 0.5,0.5 -> 1,1 -> 2,2 -> 3,3 -> 9,9.
    expect(ordered, [
      const LatLng(0.5, 0.5),
      const LatLng(1, 1),
      const LatLng(2, 2),
      const LatLng(3, 3),
      const LatLng(9, 9),
    ]);
  });

  test('devuelve lista vacía cuando no hay rutas', () async {
    SharedPreferences.setMockInitialValues({});

    final dataSource = LocalRouteDataSource(storage: StorageService());

    final ordered = await dataSource.calculateOrderedRoute(
      origin: const LatLng(0, 0),
    );

    expect(ordered, isEmpty);
  });
}