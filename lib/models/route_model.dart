import 'dart:convert';

class RouteModel {
  final String uuid;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double amount;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final bool uploaded;

  const RouteModel({
    required this.uuid,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.amount,
    required this.startDateTime,
    this.endDateTime,
    required this.uploaded,
  });

  RouteModel copyWith({
    String? uuid,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    double? amount,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? uploaded,
  }) {
    return RouteModel(
      uuid: uuid ?? this.uuid,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      amount: amount ?? this.amount,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'amount': amount,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'uploaded': uploaded,
    };
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      uuid: json['uuid'] as String,
      startLat: (json['startLat'] as num).toDouble(),
      startLng: (json['startLng'] as num).toDouble(),
      endLat: (json['endLat'] as num).toDouble(),
      endLng: (json['endLng'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      startDateTime:
          DateTime.tryParse(json['startDateTime'] ?? '') ?? DateTime.now(),
      endDateTime: DateTime.tryParse(json['endDateTime'] ?? ''),
      uploaded: json['uploaded'] as bool,
    );
  }

  static List<RouteModel> listFromJson(String jsonString) {
    final list = jsonDecode(jsonString) as List;
    return list
        .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<RouteModel> routes) {
    return jsonEncode(routes.map((r) => r.toJson()).toList());
  }
}
