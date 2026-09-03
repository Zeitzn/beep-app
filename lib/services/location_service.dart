import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> isGpsEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Stream<ServiceStatus> serviceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }

  Future<Position> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  Future<void> openGpsSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<LocationPermission> checkAndRequestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }
}
