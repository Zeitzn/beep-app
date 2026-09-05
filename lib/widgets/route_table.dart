import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/route/route_bloc.dart';
import '../blocs/route/route_state.dart';
import '../models/route_model.dart';

class RouteTable extends StatelessWidget {
  const RouteTable({super.key});

  @override
  Widget build(BuildContext context) {
    final purple = Theme.of(context).colorScheme.primary;

    return BlocBuilder<RouteBloc, RouteState>(
      builder: (context, state) {
        final hasCurrentRoute = state.currentRoute != null;
        final hasRoutes = state.routes.isNotEmpty;

        if (!hasCurrentRoute && !hasRoutes) {
          return _buildEmptyState(context, purple);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Rutas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: purple,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: purple.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(purple),
                  if (hasCurrentRoute)
                    _buildRow(context, 1, state.currentRoute!, purple,
                        isActive: true),
                  for (final (i, route) in state.routes.reversed.indexed)
                    _buildRow(context, (hasCurrentRoute ? i + 2 : i + 1), route,
                        purple),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Color purple) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purple.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.route_outlined,
            size: 40,
            color: purple.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no hay viajes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: purple.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Inicia tu primera ruta y aparecerá aquí',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color purple) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: purple.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              'N°',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Desde',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Hasta',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Inicio',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Fin',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    int index,
    RouteModel route,
    Color purple, {
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withValues(alpha: 0.06) : null,
        border: Border(
          top: BorderSide(
            color: purple.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.green.shade700 : null,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _buildCoords(context, route.startLat, route.startLng),
          ),
          Expanded(
            flex: 3,
            child: isActive
                ? const Text(
                    'En curso...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : _buildCoords(context, route.endLat, route.endLng),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDateTime(route.startDateTime),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              route.endDateTime != null
                  ? _formatDateTime(route.endDateTime!)
                  : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoords(BuildContext context, double lat, double lng) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lat.toStringAsFixed(3),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          lng.toStringAsFixed(3),
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
