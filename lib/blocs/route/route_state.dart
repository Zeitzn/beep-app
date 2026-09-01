import 'package:equatable/equatable.dart';
import '../../models/route_model.dart';

class RouteState extends Equatable {
  final List<RouteModel> routes;
  final RouteModel? currentRoute;
  final bool gpsEnabled;
  final bool isLoading;
  final String? error;

  const RouteState({
    this.routes = const [],
    this.currentRoute,
    this.gpsEnabled = false,
    this.isLoading = false,
    this.error,
  });

  RouteState copyWith({
    List<RouteModel>? routes,
    RouteModel? Function()? currentRoute,
    bool? gpsEnabled,
    bool? isLoading,
    String? Function()? error,
  }) {
    return RouteState(
      routes: routes ?? this.routes,
      currentRoute:
          currentRoute != null ? currentRoute() : this.currentRoute,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props =>
      [routes, currentRoute, gpsEnabled, isLoading, error];
}
