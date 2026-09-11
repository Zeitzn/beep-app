import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:beep/models/route_model.dart';
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

RouteModel _pendingRoute() => RouteModel(
      uuid: 'route-1',
      startLat: -34.6037,
      startLng: -58.3816,
      endLat: -32.9467,
      endLng: -60.6393,
      amount: 2500,
      startDateTime: DateTime(2026, 9, 2, 9, 0),
      endDateTime: DateTime(2026, 9, 2, 12, 0),
      uploaded: false,
    );

RouteModel _uploadedRoute() => _pendingRoute().copyWith(uuid: 'route-2', uploaded: true);

RouteModel _incompleteRoute() => RouteModel(
      uuid: 'route-3',
      startLat: -34.6037,
      startLng: -58.3816,
      endLat: 0,
      endLng: 0,
      amount: 2500,
      startDateTime: DateTime(2026, 9, 2, 9, 0),
      endDateTime: null,
      uploaded: false,
    );

void main() {
  test('sendTrips only includes complete, not-yet-uploaded routes', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('ok', 200);
    });

    final service = TripApiService(client: client);
    await service.sendTrips(
      owner: 'AB001',
      routes: [_pendingRoute(), _uploadedRoute(), _incompleteRoute()],
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['owner'], 'AB001');
    expect((body['batchId'] as String), isNotEmpty);

    final elements = body['elements'] as List;
    expect(elements, hasLength(1));

    final element = elements.single as Map<String, dynamic>;
    expect(element['itemId'], 'route-1');
    expect(element['originLat'], -34.6037);
    expect(element['originLng'], -58.3816);
    expect(element['destinationLat'], -32.9467);
    expect(element['destinationLng'], -60.6393);
    expect(element['startDateTime'], '2026-09-02T09:00:00.000');
    expect(element['endDateTime'], '2026-09-02T12:00:00.000');
    expect(element['amount'], 2500);
  });

  test('sendTrips does nothing when there are no pending routes', () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('ok', 200);
    });

    final service = TripApiService(client: client);
    await service.sendTrips(
      owner: 'AB001',
      routes: [_uploadedRoute(), _incompleteRoute()],
    );

    expect(called, isFalse);
  });

  test('sendTrips throws on non-2xx status', () async {
    final client = MockClient((request) async => http.Response('error', 500));

    final service = TripApiService(client: client);
    expect(
      () => service.sendTrips(owner: 'AB001', routes: [_pendingRoute()]),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('fetchPatterns GETs the owner patterns endpoint and parses the list',
      () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(jsonEncode([_patternJson()]), 200);
    });

    final service = TripApiService(client: client);
    final patterns = await service.fetchPatterns('AB001');

    expect(captured.method, 'GET');
    expect(captured.url.path, '/trips/owner/AB001/patterns');
    expect(patterns, hasLength(1));
    expect(patterns.single.latitude, -13.1556);
    expect(patterns.single.radiusMeters, 82.4);
    expect(patterns.single.recurrenceRate, 0.71);
    expect(patterns.single.dayOfWeek, 1);
  });

  test('fetchPatterns returns an empty list for an empty array', () async {
    final client = MockClient((request) async => http.Response('[]', 200));

    final service = TripApiService(client: client);
    final patterns = await service.fetchPatterns('AB001');

    expect(patterns, isEmpty);
  });

  test('fetchPatterns throws on non-2xx status', () async {
    final client = MockClient((request) async => http.Response('error', 500));

    final service = TripApiService(client: client);
    expect(
      () => service.fetchPatterns('AB001'),
      throwsA(isA<http.ClientException>()),
    );
  });
}
