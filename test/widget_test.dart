import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beep/blocs/route/route_bloc.dart';
import 'package:beep/screens/home_screen.dart';
import 'package:beep/services/location_service.dart';
import 'package:beep/services/storage_service.dart';

void main() {
  testWidgets('HomeScreen renders title and start-route button',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final bloc = RouteBloc(
      storage: StorageService(),
      location: LocationService(),
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: StorageService()),
          RepositoryProvider.value(value: LocationService()),
        ],
        child: BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      ),
    );

    expect(find.text('Beep'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Iniciar ruta'), findsOneWidget);
  });
}