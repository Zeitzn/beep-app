import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:beep/screens/map_page.dart';
import 'package:beep/services/trip_api_service.dart';

Map<String, dynamic> _patternJson() => {
      'latitude': -13.1556,
      'longitude': -74.2174,
      'radiusMeters': 82.4,
      'startTime': '07:30',
      'timeWindowMinutes': 45,
      'timeWindowStart': '07:07',
      'timeWindowEnd': '07:52',
      'tripCount': 12,
      'daysObserved': 5,
      'recurrenceRate': 0.71,
      'expectedPassengers': 2.4,
      'confidenceScore': 0.83,
      'dayOfWeek': 1,
    };

MapPage _buildPageWithClient(http.Client client) {
  return MapPage(owner: 'AB001', api: TripApiService(client: client));
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('renders markers and opens the pattern dialog on tap',
      (WidgetTester tester) async {
    final client = MockClient(
      (request) async => http.Response(jsonEncode([_patternJson()]), 200),
    );

    await tester.pumpWidget(_wrap(_buildPageWithClient(client)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Cargando patrones...'), findsNothing);
    expect(find.byKey(const ValueKey('pattern-marker-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pattern-tap-0')));
    await tester.pumpAndSettle();

    expect(find.text('Patrón #1'), findsOneWidget);
    expect(find.text('Latitud'), findsOneWidget);
    expect(find.text('71.0%'), findsOneWidget);
    expect(find.text('Lunes'), findsOneWidget);
  });

  testWidgets('shows the error banner when the API fails',
      (WidgetTester tester) async {
    final client = MockClient(
      (request) async => http.Response('error', 500),
    );

    await tester.pumpWidget(_wrap(_buildPageWithClient(client)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('No se pudieron cargar los patrones'),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty message when there are no patterns',
      (WidgetTester tester) async {
    final client = MockClient(
      (request) async => http.Response('[]', 200),
    );

    await tester.pumpWidget(_wrap(_buildPageWithClient(client)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No se encontraron patrones'), findsOneWidget);
  });
}