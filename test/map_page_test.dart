import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:beep/screens/map_page.dart';
import 'package:beep/services/trip_api_service.dart';

Map<String, dynamic> _patternJson({int dayOfWeek = 1}) => {
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
      'dayOfWeek': dayOfWeek,
    };

MapPage _buildPageWithClient(
  http.Client client, {
  Set<int>? initialDays,
}) {
  return MapPage(
    owner: 'AB001',
    api: TripApiService(client: client),
    initialDays: initialDays,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('renders markers and opens the pattern dialog on tap',
      (WidgetTester tester) async {
    final client = MockClient(
      (request) async => http.Response(jsonEncode([_patternJson()]), 200),
    );

    await tester.pumpWidget(_wrap(_buildPageWithClient(client, initialDays: {1})));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Cargando patrones...'), findsNothing);
    expect(find.byKey(const ValueKey('pattern-marker-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pattern-tap-0')));
    await tester.pumpAndSettle();

    expect(find.text('Patrón #1'), findsOneWidget);
    expect(find.text('Hora aproximada'), findsOneWidget);
    expect(find.text('83.0%'), findsOneWidget);
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

  testWidgets('renders the day filter bar with the 7 day buttons',
      (WidgetTester tester) async {
    final client = MockClient(
      (request) async => http.Response('[]', 200),
    );

    await tester.pumpWidget(_wrap(_buildPageWithClient(client)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Día'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('M'), findsNWidgets(2));
    expect(find.text('J'), findsOneWidget);
    expect(find.text('V'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    for (var day = 1; day <= 7; day++) {
      expect(find.byKey(ValueKey('day-filter-$day')), findsOneWidget);
    }
  });

  testWidgets('renders zoom controls above the follow button',
      (WidgetTester tester) async {
    final client = MockClient(
      (request) async => http.Response('[]', 200),
    );

    await tester.pumpWidget(_wrap(_buildPageWithClient(client)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('zoom-in-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('zoom-out-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('follow-user-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('zoom-in-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('zoom-out-button')));
    await tester.pump();
  });

  testWidgets('filters markers by selected days and restores all on clear',
      (WidgetTester tester) async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode([
          _patternJson(dayOfWeek: 1),
          _patternJson(dayOfWeek: 3),
          _patternJson(dayOfWeek: 5),
        ]),
        200,
      ),
    );

    await tester.pumpWidget(
      _wrap(_buildPageWithClient(client, initialDays: {})),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('pattern-marker-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('pattern-marker-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pattern-marker-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('day-filter-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('pattern-marker-0')), findsNothing);
    expect(find.byKey(const ValueKey('pattern-marker-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pattern-marker-2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('day-filter-5')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('pattern-marker-0')), findsNothing);
    expect(find.byKey(const ValueKey('pattern-marker-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pattern-marker-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('day-filter-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('pattern-marker-1')), findsNothing);
    expect(find.byKey(const ValueKey('pattern-marker-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('day-filter-5')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('pattern-marker-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('pattern-marker-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pattern-marker-2')), findsOneWidget);
  });

  testWidgets('preselects the current day by default and toggles off',
      (WidgetTester tester) async {
    final today = DateTime.now().weekday;
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode(
          [for (var day = 1; day <= 7; day++) _patternJson(dayOfWeek: day)],
        ),
        200,
      ),
    );

    await tester.pumpWidget(_wrap(_buildPageWithClient(client)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    for (var day = 1; day <= 7; day++) {
      final visible = day == today;
      expect(
        find.byKey(ValueKey('pattern-marker-${day - 1}')),
        visible ? findsOneWidget : findsNothing,
        reason: 'day $day expected ${visible ? 'visible' : 'hidden'}',
      );
    }

    await tester.tap(find.byKey(ValueKey('day-filter-$today')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('pattern-marker-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('pattern-marker-6')), findsOneWidget);
  });
}