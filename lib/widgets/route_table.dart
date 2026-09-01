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
          return const SizedBox.shrink();
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
                  if (hasCurrentRoute) _buildRow(state.currentRoute!, purple, isActive: true),
                  for (final route in state.routes.reversed)
                    _buildRow(route, purple),
                ],
              ),
            ),
          ],
        );
      },
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
            flex: 2,
            child: Text(
              'Monto',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Inicio',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Fin',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Sync',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
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
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '\$${route.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.green.shade700 : null,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${route.startLat.toStringAsFixed(4)}, ${route.startLng.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              isActive
                  ? 'En curso...'
                  : '${route.endLat.toStringAsFixed(4)}, ${route.endLng.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.orange.shade700 : null,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Icon(
              route.uploaded
                  ? Icons.check_circle
                  : Icons.cancel,
              size: 18,
              color: route.uploaded
                  ? Colors.green.shade600
                  : Colors.red.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
