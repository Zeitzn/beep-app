import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/route/route_bloc.dart';
import '../blocs/route/route_event.dart';
import '../blocs/route/route_state.dart';
import '../widgets/amount_selector.dart';
import '../widgets/gps_warning_banner.dart';
import '../widgets/route_table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RouteBloc>().add(const GpsStatusChecked());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purple = theme.colorScheme.primary;
    final purpleLight = theme.colorScheme.primaryContainer;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC),
      body: SafeArea(
        child: Column(
          children: [
            const GpsWarningBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      'Beep',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: purple,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<RouteBloc, RouteState>(
                      buildWhen: (prev, curr) =>
                          prev.currentRoute != curr.currentRoute,
                      builder: (context, state) {
                        final enRuta = state.currentRoute != null;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: enRuta
                                ? Colors.green.shade50
                                : purpleLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                enRuta
                                    ? Icons.directions_bus
                                    : Icons.check_circle_outline,
                                size: 20,
                                color: enRuta
                                    ? Colors.green.shade700
                                    : purple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                enRuta ? 'En ruta' : 'Disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: enRuta
                                      ? Colors.green.shade700
                                      : purple,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    AmountSelector(
                      onAmountSelected: (amount) {
                        setState(() {
                          _selectedAmount = amount;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    _buildActionButtons(purple),
                    const SizedBox(height: 40),
                    const RouteTable(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color purple) {
    return BlocConsumer<RouteBloc, RouteState>(
      listenWhen: (prev, curr) => prev.error != curr.error && curr.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      builder: (context, state) {
        final enRuta = state.currentRoute != null;
        final calculating = state.isLoading;

        final label = calculating
            ? 'Calculando...'
            : (enRuta ? 'Terminar ruta' : 'Iniciar ruta');

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: enRuta
              ? SizedBox(
                  key: const ValueKey('end'),
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: calculating
                        ? null
                        : () {
                            context
                                .read<RouteBloc>()
                                .add(const RouteEnded());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      disabledBackgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _buttonChild(label, calculating, Colors.white),
                  ),
                )
              : SizedBox(
                  key: const ValueKey('start'),
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (calculating || _selectedAmount == null)
                        ? null
                        : () {
                            context
                                .read<RouteBloc>()
                                .add(RouteStarted(_selectedAmount!));
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      disabledBackgroundColor: calculating
                          ? purple
                          : purple.withValues(alpha: 0.25),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: calculating
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation:
                          (calculating && _selectedAmount != null) ? 2 : 0,
                    ),
                    child: _buttonChild(label, calculating, Colors.white),
                  ),
                ),
        );
      },
    );
  }

  Widget _buttonChild(String label, bool calculating, Color color) {
    if (!calculating) {
      return Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
