import '../utils/route_order.dart';
import 'route_data_source.dart';
import 'storage_service.dart';

class LocalRouteDataSource implements RouteDataSource {
  final StorageService storage;

  LocalRouteDataSource({required this.storage});

  @override
  Future<List<LatLng>> calculateOrderedRoute({
    required LatLng origin,
    int limit = 5,
  }) async {
    final routes = await storage.loadRoutes();
    final lastPoints = routes.reversed
        .take(limit)
        .map((r) => LatLng(r.startLat, r.startLng))
        .toList();
    return orderByNearestNeighbor(lastPoints, origin);
  }
}