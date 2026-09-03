import 'package:equatable/equatable.dart';

sealed class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

final class RoutesLoaded extends RouteEvent {
  const RoutesLoaded();
}

final class RouteStarted extends RouteEvent {
  final double amount;

  const RouteStarted(this.amount);

  @override
  List<Object?> get props => [amount];
}

final class RouteEnded extends RouteEvent {
  const RouteEnded();
}

final class GpsStatusChecked extends RouteEvent {
  const GpsStatusChecked();
}

final class GpsSettingsOpened extends RouteEvent {
  const GpsSettingsOpened();
}

final class PlacaChanged extends RouteEvent {
  final String placa;

  const PlacaChanged(this.placa);

  @override
  List<Object?> get props => [placa];
}
