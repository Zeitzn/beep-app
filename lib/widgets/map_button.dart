import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import '../services/route_data_source.dart';
import '../utils/route_order.dart';

class MapButton extends StatefulWidget {
  final LocationService location;
  final RouteDataSource dataSource;
  final bool enabled;

  const MapButton({
    super.key,
    required this.location,
    required this.dataSource,
    required this.enabled,
  });

  @override
  State<MapButton> createState() => _MapButtonState();
}

class _MapButtonState extends State<MapButton> {
  bool _calculating = false;

  Future<void> _openMap() async {
    setState(() => _calculating = true);
    try {
      final gpsEnabled = await widget.location.isGpsEnabled();
      if (!gpsEnabled) {
        _showError('GPS desactivado. Activa la ubicación para ver la ruta.');
        return;
      }

      final permission = await widget.location.checkAndRequestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('Permiso de ubicación denegado.');
        return;
      }

      final position = await widget.location.getCurrentPosition();
      final origin = LatLng(position.latitude, position.longitude);
      final ordered = await widget.dataSource.calculateOrderedRoute(
        origin: origin,
      );
      final uri = Uri.parse(buildDirectionsUrl(origin, ordered));

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showError('Error al obtener la ubicación: $e');
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;
    final enabled = widget.enabled && !_calculating;

    return IconButton(
      key: const ValueKey('map'),
      onPressed: enabled ? _openMap : null,
      icon: _calculating
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: purple,
              ),
            )
          : Icon(Icons.map, color: widget.enabled ? purple : null),
      tooltip: 'Ver ruta en el mapa',
      iconSize: 28,
      padding: const EdgeInsets.all(10),
      style: IconButton.styleFrom(
        backgroundColor: widget.enabled
            ? purple.withValues(alpha: 0.08)
            : Colors.grey.shade200,
      ),
    );
  }
}