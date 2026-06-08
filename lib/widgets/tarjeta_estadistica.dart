import 'package:flutter/material.dart';
import '../theme/colores_app.dart';

class TarjetaEstadistica extends StatelessWidget {
  const TarjetaEstadistica({
    super.key,
    required this.icono,
    required this.colorIcono,
    required this.valor,
    required this.etiqueta,
    required this.detalle,
    this.colorValor,
    this.alPulsar,
  });

  final IconData icono;
  final Color colorIcono;
  final String valor;
  final String etiqueta;
  final String detalle;
  final Color? colorValor;
  final VoidCallback? alPulsar;

  @override
  Widget build(BuildContext context) {
    final contenido = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorIcono.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: colorIcono, size: 18),
              ),
              Icon(Icons.more_horiz, color: ColoresApp.textoSecundario, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorValor,
                  fontWeight:
                      colorValor != null ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detalle,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );

    if (alPulsar == null) return contenido;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alPulsar,
        borderRadius: BorderRadius.circular(18),
        child: contenido,
      ),
    );
  }
}
