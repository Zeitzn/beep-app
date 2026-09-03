import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/route/route_bloc.dart';
import '../blocs/route/route_event.dart';
import 'home_screen.dart';

class PlacaScreen extends StatefulWidget {
  final String? placaPrevia;
  final bool isEditing;

  const PlacaScreen({
    super.key,
    this.placaPrevia,
    this.isEditing = false,
  });

  @override
  State<PlacaScreen> createState() => _PlacaScreenState();
}

class _PlacaScreenState extends State<PlacaScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.placaPrevia ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continuar() {
    final placa = _controller.text.trim();
    if (placa.isEmpty) return;
    context.read<RouteBloc>().add(PlacaChanged(placa));
    if (widget.isEditing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purple = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Text(
                'Beep',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: purple,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 48),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  final hasText = value.text.trim().isNotEmpty;
                  return Column(
                    children: [
                      TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Placa',
                          prefixIcon: const Icon(Icons.directions_bus),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: hasText ? _continuar : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            disabledBackgroundColor: purple.withValues(alpha: 0.25),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          iconAlignment: IconAlignment.end,
                          label: const Text(
                            'Continuar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
