import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> isGpsEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Stream<ServiceStatus> serviceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
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
