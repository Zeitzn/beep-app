import 'package:flutter_test/flutter_test.dart';

import 'package:beep/models/trip_pattern.dart';

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

void main() {
  test('fromJson parses all fields', () {
    final pattern = TripPattern.fromJson(_patternJson());

    expect(pattern.latitude, -13.1556);
    expect(pattern.longitude, -74.2174);
    expect(pattern.radiusMeters, 82.4);
    expect(pattern.startTime, '07:30');
    expect(pattern.timeWindowMinutes, 45);
    expect(pattern.timeWindowStart, '07:07');
    expect(pattern.timeWindowEnd, '07:52');
    expect(pattern.tripCount, 12);
    expect(pattern.daysObserved, 5);
    expect(pattern.recurrenceRate, 0.71);
    expect(pattern.expectedPassengers, 2.4);
    expect(pattern.confidenceScore, 0.83);
    expect(pattern.dayOfWeek, 1);
  });

  test('fromJson tolerates num values regardless of int/double', () {
    final json = _patternJson();
    json['latitude'] = -13;
    json['tripCount'] = 12.0;

    final pattern = TripPattern.fromJson(json);

    expect(pattern.latitude, -13.0);
    expect(pattern.tripCount, 12);
  });

  test('dayName maps 1 to Lunes and unknown to fallback', () {
    expect(TripPattern.fromJson(_patternJson()).dayName, 'Lunes');

    final unknown = _patternJson()..['dayOfWeek'] = 99;
    expect(TripPattern.fromJson(unknown).dayName, 'Día 99');
  });

  test('recurrence and confidence render as percentages', () {
    final pattern = TripPattern.fromJson(_patternJson());

    expect(pattern.recurrencePercent, '71.0%');
    expect(pattern.confidencePercent, '83.0%');
  });
}