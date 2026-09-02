import 'package:flutter_test/flutter_test.dart';

import 'package:beep/utils/route_order.dart';

void main() {
  group('orderByNearestNeighbor', () {
    test('ordena puntos por cercanía desde el origen', () {
      final origin = const LatLng(0, 0);
      final points = [
        const LatLng(3, 3),
        const LatLng(1, 1),
        const LatLng(2, 2),
      ];

      final ordered = orderByNearestNeighbor(points, origin);

      expect(ordered, [
        const LatLng(1, 1),
        const LatLng(2, 2),
        const LatLng(3, 3),
      ]);
    });

    test('greedy: desde la posición actual elige el más cercano no visitado',
        () {
      final origin = const LatLng(0, 0);
      // El punto (1,1) es el más lejano del origen pero cerca de (2,2).
      // Desde el origen se va a (1,1); desde ahí al siguiente más cercano
      // de (1,1) es (2,2), no (10,10). Luego (10,10).
      final points = [
        const LatLng(10, 10),
        const LatLng(2, 2),
        const LatLng(1, 1),
      ];

      final ordered = orderByNearestNeighbor(points, origin);

      expect(ordered, [
        const LatLng(1, 1),
        const LatLng(2, 2),
        const LatLng(10, 10),
      ]);
    });

    test('un único punto se devuelve en orden', () {
      final ordered = orderByNearestNeighbor(
        [const LatLng(5, 5)],
        const LatLng(0, 0),
      );
      expect(ordered, [const LatLng(5, 5)]);
    });
  });

  group('buildDirectionsUrl', () {
    test('construye URL de directions con waypoints', () {
      final url = buildDirectionsUrl(
        const LatLng(0, 0),
        [
          const LatLng(1, 1),
          const LatLng(2, 2),
          const LatLng(3, 3),
        ],
      );

      expect(url, startsWith('https://www.google.com/maps/dir/?api=1'));
      expect(url, contains('origin=0.0,0.0'));
      expect(url, contains('destination=3.0,3.0'));
      expect(url, contains('waypoints=1.0,1.0|2.0,2.0'));
    });

    test('omite waypoints cuando hay un único punto', () {
      final url = buildDirectionsUrl(
        const LatLng(0, 0),
        [const LatLng(1, 1)],
      );

      expect(url, contains('destination=1.0,1.0'));
      expect(url, isNot(contains('waypoints')));
    });
  });
}
