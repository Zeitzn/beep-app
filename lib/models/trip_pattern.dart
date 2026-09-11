class TripPattern {
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String startTime;
  final int timeWindowMinutes;
  final String timeWindowStart;
  final String timeWindowEnd;
  final int tripCount;
  final int daysObserved;
  final double recurrenceRate;
  final double expectedPassengers;
  final double confidenceScore;
  final int dayOfWeek;

  const TripPattern({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.startTime,
    required this.timeWindowMinutes,
    required this.timeWindowStart,
    required this.timeWindowEnd,
    required this.tripCount,
    required this.daysObserved,
    required this.recurrenceRate,
    required this.expectedPassengers,
    required this.confidenceScore,
    required this.dayOfWeek,
  });

  factory TripPattern.fromJson(Map<String, dynamic> json) {
    return TripPattern(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      startTime: json['startTime'] as String,
      timeWindowMinutes: (json['timeWindowMinutes'] as num).toInt(),
      timeWindowStart: json['timeWindowStart'] as String,
      timeWindowEnd: json['timeWindowEnd'] as String,
      tripCount: (json['tripCount'] as num).toInt(),
      daysObserved: (json['daysObserved'] as num).toInt(),
      recurrenceRate: (json['recurrenceRate'] as num).toDouble(),
      expectedPassengers: (json['expectedPassengers'] as num).toDouble(),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
    );
  }

  String get dayName => _dayNames[dayOfWeek] ?? 'Día $dayOfWeek';

  String get recurrencePercent =>
      _percent(recurrenceRate);

  String get confidencePercent => _percent(confidenceScore);

  static String _percent(double value) =>
      '${(value * 100).toStringAsFixed(1)}%';

  static const _dayNames = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };
}