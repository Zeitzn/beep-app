import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trip_pattern.dart';
import '../services/trip_api_service.dart';

Future<Position> _resolveUserPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('El servicio de ubicación está desactivado.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Permiso de ubicación denegado.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'El permiso de ubicación fue denegado permanentemente.',
    );
  }

  return Geolocator.getCurrentPosition();
}

class MapPage extends StatefulWidget {
  final String owner;
  final TripApiService api;
  final Set<int>? initialDays;

  MapPage({
    super.key,
    required this.owner,
    TripApiService? api,
    this.initialDays,
  }) : api = api ?? TripApiService();

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static final _initialCenter = LatLng(-13.16, -74.23);
  static const _initialZoom = 14.0;
  static const _maxZoom = 19.0;

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFF6D4C41),
    Color(0xFFD81B60),
    Color(0xFF3949AB),
    Color(0xFF00897B),
    Color(0xFFF4511E),
    Color(0xFF7CB342),
    Color(0xFF5E35B1),
    Color(0xFF039BE5),
    Color(0xFFC0CA33),
  ];

  final _mapController = MapController();
  late final Future<List<TripPattern>> _future;
  bool _fitted = false;
  bool _follow = false;
  double _followZoom = 14;
  LatLng? _userPosition;
  double? _userAccuracy;
  StreamSubscription<Position>? _positionSub;
  late final Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays ?? {DateTime.now().weekday};
    _future = widget.api.fetchPatterns(widget.owner);
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      final position = await _resolveUserPosition();
      if (!mounted) return;
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
        _userAccuracy = position.accuracy;
      });
      _centerOnUser();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).listen((position) {
        if (!mounted) return;
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
          _userAccuracy = position.accuracy;
        });
        if (_follow) _mapController.move(_userPosition!, _followZoom);
      });
    } catch (_) {
      // La ubicación no está disponible; el mapa funciona sin rastreo.
    }
  }

  void _centerOnUser() {
    final position = _userPosition;
    if (position == null) return;
    double zoom = 16;
    try {
      zoom = _mapController.camera.zoom;
    } catch (_) {
      // La cámara aún no está disponible; usar el zoom por defecto.
    }
    _followZoom = zoom;
    _mapController.move(position, zoom);
  }

  void _toggleFollow() {
    if (_userPosition == null) return;
    setState(() => _follow = !_follow);
    if (_follow) _centerOnUser();
  }

  void _moveZoom(int delta) {
    final camera = _mapController.camera;
    final zoom = (camera.zoom + delta).clamp(2.0, _maxZoom).toDouble();
    _mapController.move(camera.center, zoom);
  }

  void _zoomIn() => _moveZoom(1);

  void _zoomOut() => _moveZoom(-1);

  void _stopFollowingOnUserPan() {
    if (!_follow) return;
    setState(() => _follow = false);
  }

  void _toggleDay(int day) {
    setState(() {
      if (!_selectedDays.add(day)) _selectedDays.remove(day);
    });
  }

  void _fitToPatterns(List<TripPattern> patterns) {
    if (patterns.isEmpty || _fitted) return;
    if (_userPosition != null) return;
    _fitted = true;
    final bounds = LatLngBounds.fromPoints(
      patterns
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(),
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
        maxZoom: 16,
      ),
    );
  }

  void _showPatternDialog(TripPattern pattern, int index) {
    final color = _colors[index % _colors.length];
    showDialog<void>(
      context: context,
      builder: (_) =>
          _PatternDialog(pattern: pattern, index: index, color: color),
    );
  }

  Marker _buildMarker(TripPattern pattern, int index) {
    final color = _colors[index % _colors.length];
    return Marker(
      key: ValueKey('pattern-marker-$index'),
      point: LatLng(pattern.latitude, pattern.longitude),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      child: GestureDetector(
        key: ValueKey('pattern-tap-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _showPatternDialog(pattern, index),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _userBlue = Color(0xFF1E88E5);

  Marker _buildUserMarker() {
    return Marker(
      key: const ValueKey('user-marker'),
      point: _userPosition!,
      width: 18,
      height: 18,
      alignment: Alignment.center,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _userBlue,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  CircleMarker _buildUserAccuracyCircle(
    LatLng point,
    double accuracyMeters,
  ) {
    return CircleMarker(
      point: point,
      radius: accuracyMeters,
      useRadiusInMeter: true,
      color: _userBlue.withValues(alpha: 0.15),
      borderColor: _userBlue.withValues(alpha: 0.35),
      borderStrokeWidth: 1.5,
    );
  }

  CircleMarker _buildCircle(TripPattern pattern, int index) {
    final color = _colors[index % _colors.length];
    return CircleMarker(
      point: LatLng(pattern.latitude, pattern.longitude),
      radius: pattern.radiusMeters,
      useRadiusInMeter: true,
      color: color.withValues(alpha: 0.12),
      borderColor: color,
      borderStrokeWidth: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC),
      body: FutureBuilder<List<TripPattern>>(
        future: _future,
        builder: (context, snapshot) {
          final patterns = snapshot.data ?? const <TripPattern>[];

          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitToPatterns(patterns);
            });
          }

          final visiblePatterns = <({TripPattern pattern, int index})>[
            for (var i = 0; i < patterns.length; i++)
              if (_selectedDays.isEmpty ||
                  _selectedDays.contains(patterns[i].dayOfWeek))
                (pattern: patterns[i], index: i),
          ];
          final markers = <Marker>[
            for (final item in visiblePatterns)
              _buildMarker(item.pattern, item.index),
            if (_userPosition != null) _buildUserMarker(),
          ];
          final circles = <CircleMarker>[
            for (final item in visiblePatterns)
              _buildCircle(item.pattern, item.index),
            if (_userPosition != null && _userAccuracy != null)
              _buildUserAccuracyCircle(_userPosition!, _userAccuracy!),
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: _initialZoom,
                  maxZoom: _maxZoom,
                  onMapEvent: (event) {
                    if (event is MapEventMoveStart &&
                        (event.source == MapEventSource.dragStart ||
                            event.source == MapEventSource.onDrag)) {
                      _stopFollowingOnUserPan();
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    maxZoom: _maxZoom,
                    userAgentPackageName: 'com.example.beep',
                  ),
                  CircleLayer(circles: circles),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: _DayFilterBar(
                    selectedDays: _selectedDays,
                    onToggle: _toggleDay,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      key: const ValueKey('zoom-in-button'),
                      heroTag: 'zoom-in',
                      onPressed: _zoomIn,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      mini: true,
                      tooltip: 'Acercar',
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      key: const ValueKey('zoom-out-button'),
                      heroTag: 'zoom-out',
                      onPressed: _zoomOut,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      mini: true,
                      tooltip: 'Alejar',
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      key: const ValueKey('follow-user-button'),
                      heroTag: 'follow-user',
                      onPressed: _userPosition == null ? null : _toggleFollow,
                      backgroundColor:
                          _follow ? const Color(0xFF1E88E5) : Colors.white,
                      foregroundColor: _follow ? Colors.white : Colors.black87,
                      mini: true,
                      tooltip: 'Centrar en mi ubicación',
                      child: Icon(
                        _follow
                            ? Icons.my_location
                            : Icons.my_location_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                _buildFloatingBanner('Cargando patrones...'),
              if (snapshot.hasError)
                _buildErrorBanner(
                  'No se pudieron cargar los patrones: '
                  '${snapshot.error}',
                ),
              if (snapshot.connectionState == ConnectionState.done &&
                  !snapshot.hasError &&
                  patterns.isEmpty)
                const Center(
                  child: Text(
                    'No se encontraron patrones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingBanner(String message) {
    return Positioned(
      top: 88,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(message),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Positioned(
      top: 88,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _DayFilterBar extends StatelessWidget {
  static const _initials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;

  const _DayFilterBar({
    required this.selectedDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Día',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          for (var day = 1; day <= _initials.length; day++) ...[
            _DayButton(
              day: day,
              label: _initials[day - 1],
              isSelected: selectedDays.contains(day),
              selectedColor: primary,
              onTap: () => onToggle(day),
            ),
            if (day < _initials.length) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  static const _size = 32.0;

  final int day;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('day-filter-$day'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _size,
        height: _size,
        alignment: Alignment.center,
decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
            color:
                isSelected ? selectedColor : selectedColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : selectedColor,
          ),
        ),
      ),
    );
  }
}

class _PatternDialog extends StatefulWidget {
  final TripPattern pattern;
  final int index;
  final Color color;

  const _PatternDialog({
    required this.pattern,
    required this.index,
    required this.color,
  });

  @override
  State<_PatternDialog> createState() => _PatternDialogState();
}

class _PatternDialogState extends State<_PatternDialog> {
  bool _launching = false;

  List<(String, String)> get _rows => [
        // ('Latitud', '${widget.pattern.latitude}'),
        // ('Longitud', '${widget.pattern.longitude}'),
        // ('Radio', '${widget.pattern.radiusMeters} m'),
        ('Hora aproximada', widget.pattern.startTime),
        // ('Ventana', '${widget.pattern.timeWindowMinutes} min'),
        // ('Inicio de Ventana', widget.pattern.timeWindowStart),
        // ('Fin de Ventana', widget.pattern.timeWindowEnd),
        // ('Viajes', '${widget.pattern.tripCount}'),
        // ('Días observados', '${widget.pattern.daysObserved}'),
        // ('Recurrencia', widget.pattern.recurrencePercent),
        // ('Pasajeros esperados', '${widget.pattern.expectedPassengers}'),
        ('Confianza', widget.pattern.confidencePercent),
        ('Día', widget.pattern.dayName),
      ];

  Future<void> _openGoogleMaps() async {
    setState(() => _launching = true);
    try {
      final position = await _resolveUserPosition();
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${position.latitude},${position.longitude}'
        '&destination=${widget.pattern.latitude},${widget.pattern.longitude}'
        '&travelmode=driving',
      );
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showError('No se pudo abrir Google Maps.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 360,
          maxHeight: 420,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Patrón #${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final (label, value) in _rows)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(value),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: _launching ? null : _openGoogleMaps,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _launching
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.navigation),
                  label: Text(
                    _launching ? 'Abriendo...' : 'Ir',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}