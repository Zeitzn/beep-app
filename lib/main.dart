import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/route/route_bloc.dart';
import 'blocs/route/route_event.dart';
import 'blocs/route/route_state.dart';
import 'screens/home_screen.dart';
import 'screens/placa_screen.dart';
import 'services/local_route_data_source.dart';
import 'services/location_service.dart';
import 'services/route_data_source.dart';
import 'services/storage_service.dart';
import 'services/trip_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  final locationService = LocationService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: locationService),
        RepositoryProvider<RouteDataSource>.value(
          value: LocalRouteDataSource(storage: storageService),
        ),
      ],
      child: BlocProvider(
        create: (_) => RouteBloc(
          storage: storageService,
          location: locationService,
          tripApi: TripApiService(),
        )..add(const RoutesLoaded()),
        child: MaterialApp(
          title: 'Beep',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: const RootScreen(),
        ),
      ),
    ),
  );
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RouteBloc, RouteState>(
      builder: (context, state) {
        final placaVacia = state.placa.trim().isEmpty;
        if (placaVacia) {
          return const PlacaScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
