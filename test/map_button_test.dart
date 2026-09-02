import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beep/services/location_service.dart';
import 'package:beep/services/route_data_source.dart';
import 'package:beep/utils/route_order.dart';
import 'package:beep/widgets/map_button.dart';

class _FakeDataSource implements RouteDataSource {
  @override
  Future<List<LatLng>> calculateOrderedRoute({
    required LatLng origin,
    int limit = 5,
  }) async {
    return const [];
  }
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('MapButton is disabled when disabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        MapButton(
          enabled: false,
          location: LocationService(),
          dataSource: _FakeDataSource(),
        ),
      ),
    );

    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('map')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('MapButton is enabled when enabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        MapButton(
          enabled: true,
          location: LocationService(),
          dataSource: _FakeDataSource(),
        ),
      ),
    );

    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('map')),
    );
    expect(button.onPressed, isNotNull);
  });
}