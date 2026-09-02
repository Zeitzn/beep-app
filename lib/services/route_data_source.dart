import '../utils/route_order.dart';

abstract class RouteDataSource {
  Future<List<LatLng>> calculateOrderedRoute({
    required LatLng origin,
    int limit = 5,
  });
}