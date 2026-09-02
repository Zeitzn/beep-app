import 'package:geolocator/geolocator.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => '$latitude,$longitude';
}

/// Ordena los [points] por cercanía desde [origin] usando el algoritmo del
/// vecino más cercano: desde el origen al punto más cercano, luego desde ese
/// punto al siguiente no visitado más cercano, y así sucesivamente.
List<LatLng> orderByNearestNeighbor(
  List<LatLng> points,
  LatLng origin,
) {
  final remaining = [...points];
  final ordered = <LatLng>[];
  var current = origin;

  while (remaining.isNotEmpty) {
    var bestIndex = 0;
    var bestDistance = double.infinity;

    for (var i = 0; i < remaining.length; i++) {
      final distance = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        remaining[i].latitude,
        remaining[i].longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    current = remaining.removeAt(bestIndex);
    ordered.add(current);
  }

  return ordered;
}

/// Construye la URL de Google Maps para una ruta desde [origin] que visita
/// [ordered] en el orden dado. El último punto se establece como destino y los
/// anteriores como waypoints (hasta [maxWaypoints]).
String buildDirectionsUrl(
  LatLng origin,
  List<LatLng> ordered, {
  int maxWaypoints = 4,
}) {
  if (ordered.isEmpty) throw ArgumentError('ordered no puede estar vacío');

  final waypoints = ordered.length > 1
      ? ordered.sublist(0, ordered.length - 1).take(maxWaypoints).join('|')
      : null;

  final params = StringBuffer()
    ..write('https://www.google.com/maps/dir/?api=1')
    ..write('&origin=${'${origin.latitude},${origin.longitude}'}')
    ..write('&destination=${'${ordered.last.latitude},${ordered.last.longitude}'}');

  if (waypoints != null && waypoints.isNotEmpty) {
    params.write('&waypoints=$waypoints');
  }

  return params.toString();
}
