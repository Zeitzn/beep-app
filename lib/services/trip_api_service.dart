import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/route_model.dart';

class TripApiService {
  static const _url = 'https://beep.todoprogramacionapi.xyz/trips';

  final http.Client _client;
  final _uuid = const Uuid();

  TripApiService({http.Client? client})
      : _client = client ?? http.Client();

  Future<void> sendTrips({
    required String owner,
    required List<RouteModel> routes,
  }) async {
    final pending = routes
        .where((r) => !r.uploaded && r.endDateTime != null)
        .toList();
    if (pending.isEmpty) return;

    final body = {
      'batchId': _uuid.v4(),
      'owner': owner,
      'elements': pending.map(_toElement).toList(),
    };

    final response = await _client.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw http.ClientException(
        'Trip API error: ${response.statusCode}',
        Uri.parse(_url),
      );
    }
  }

  static Map<String, dynamic> _toElement(RouteModel route) {
    final end = route.endDateTime!;
    return {
      'itemId': route.uuid,
      'originLat': route.startLat,
      'originLng': route.startLng,
      'destinationLat': route.endLat,
      'destinationLng': route.endLng,
      'startDateTime': route.startDateTime.toIso8601String(),
      'endDateTime': end.toIso8601String(),
      'amount': route.amount,
    };
  }
}
