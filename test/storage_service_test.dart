import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beep/models/route_model.dart';
import 'package:beep/services/storage_service.dart';

RouteModel _route(String uuid) => RouteModel(
      uuid: uuid,
      startLat: -34.60,
      startLng: -58.38,
      endLat: 0,
      endLng: 0,
      amount: 5,
      startDateTime: DateTime(2026, 9, 1, 10, 30),
      uploaded: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveCurrentRoute/loadCurrentRoute hace round-trip', () async {
    final storage = StorageService();
    final route = _route('abc');

    await storage.saveCurrentRoute(route);

    final loaded = await storage.loadCurrentRoute();
    expect(loaded, isNotNull);
    expect(loaded!.uuid, route.uuid);
    expect(loaded.startLat, route.startLat);
    expect(loaded.startDateTime, route.startDateTime);
    expect(loaded.endDateTime, isNull);
  });

  test('loadCurrentRoute devuelve null cuando no hay ruta en curso', () async {
    final storage = StorageService();

    final loaded = await storage.loadCurrentRoute();

    expect(loaded, isNull);
  });

  test('clearCurrentRoute elimina la ruta en curso', () async {
    final storage = StorageService();
    await storage.saveCurrentRoute(_route('abc'));

    await storage.clearCurrentRoute();

    expect(await storage.loadCurrentRoute(), isNull);
  });

  test('la ruta en curso no contamina la lista de rutas completadas', () async {
    final storage = StorageService();
    await storage.saveCurrentRoute(_route('abc'));
    await storage.saveRoutes([_route('done')]);

    expect((await storage.loadCurrentRoute()), isNotNull);
    final routes = await storage.loadRoutes();
    expect(routes.map((r) => r.uuid), ['done']);
  });
}