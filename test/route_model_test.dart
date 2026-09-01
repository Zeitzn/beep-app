import 'package:flutter_test/flutter_test.dart';

import 'package:beep/models/route_model.dart';

void main() {
  group('RouteModel serialization', () {
    test('round-trips all fields including endDateTime', () {
      final original = RouteModel(
        uuid: 'abc-123',
        startLat: -34.6037,
        startLng: -58.3816,
        endLat: -34.6158,
        endLng: -58.4333,
        amount: 5,
        startDateTime: DateTime(2026, 9, 1, 10, 30),
        endDateTime: DateTime(2026, 9, 1, 11, 15),
        uploaded: false,
      );

      final json = original.toJson();
      final decoded = RouteModel.fromJson(json);

      expect(decoded.uuid, original.uuid);
      expect(decoded.startLat, original.startLat);
      expect(decoded.startLng, original.startLng);
      expect(decoded.endLat, original.endLat);
      expect(decoded.endLng, original.endLng);
      expect(decoded.amount, original.amount);
      expect(decoded.startDateTime, original.startDateTime);
      expect(decoded.endDateTime, original.endDateTime);
      expect(decoded.uploaded, original.uploaded);
    });

    test('parses endDateTime as null when absent in JSON (route in progress)',
        () {
      final json = {
        'uuid': 'abc-123',
        'startLat': -34.6037,
        'startLng': -58.3816,
        'endLat': 0.0,
        'endLng': 0.0,
        'amount': 4,
        'startDateTime': DateTime(2026, 9, 1, 10, 30).toIso8601String(),
        'uploaded': false,
      };

      final decoded = RouteModel.fromJson(json);

      expect(decoded.endDateTime, isNull);
    });

    test('serializes endDateTime to ISO 8601 string', () {
      final model = RouteModel(
        uuid: 'x',
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
        amount: 3,
        startDateTime: DateTime(2026, 9, 1, 10),
        endDateTime: DateTime(2026, 9, 1, 11),
        uploaded: false,
      );

      expect(model.toJson()['endDateTime'],
          DateTime(2026, 9, 1, 11).toIso8601String());
      expect(model.toJson()['endDateTime'], isNotNull);
    });
  });
}
