import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/route/route_bloc.dart';
import '../blocs/route/route_event.dart';
import '../blocs/route/route_state.dart';

class GpsWarningBanner extends StatelessWidget {
  const GpsWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RouteBloc, RouteState>(
      buildWhen: (prev, curr) => prev.gpsEnabled != curr.gpsEnabled,
      builder: (context, state) {
        if (state.gpsEnabled) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.orange.shade100,
          child: Row(
            children: [
              Icon(
                Icons.location_off,
                color: Colors.orange.shade800,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'GPS desactivado. Activa la ubicación para usar la app.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<RouteBloc>().add(const GpsSettingsOpened());
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Activar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}