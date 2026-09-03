import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:beep/models/route_model.dart';
import 'package:beep/services/trip_api_service.dart';

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
}
