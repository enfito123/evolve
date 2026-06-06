import 'package:flutter/material.dart';
import '../theme/colores_app.dart';

class BarraNavegacion extends StatelessWidget {
  const BarraNavegacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _IconoNavegacion(icono: Icons.home_rounded, activo: true),
          _IconoNavegacion(icono: Icons.bolt_rounded, activo: false),
          _IconoNavegacion(icono: Icons.bar_chart_rounded, activo: false),
          _IconoNavegacion(icono: Icons.person_rounded, activo: false),
        ],
      ),
    );
  }
}

class _IconoNavegacion extends StatelessWidget {
  const _IconoNavegacion({required this.icono, required this.activo});

  final IconData icono;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final color = activo ? ColoresApp.acentoPrimario : ColoresApp.textoSecundario;
    return Icon(icono, color: color, size: 24);
  }
}
