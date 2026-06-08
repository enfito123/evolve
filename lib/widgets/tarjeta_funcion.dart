import 'package:flutter/material.dart';
import '../theme/colores_app.dart';

class TarjetaFuncion extends StatelessWidget {
  const TarjetaFuncion({
    super.key,
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    this.descripcion,
    this.destacado,
    this.alPulsar,
  });

  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String? descripcion;
  final String? destacado;
  final VoidCallback? alPulsar;

  @override
  Widget build(BuildContext context) {
    final contenido = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorIcono.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: colorIcono, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              if (destacado != null)
                Text(
                  destacado!,
                  style: TextStyle(
                    color: colorIcono,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else if (descripcion != null)
                Text(
                  descripcion!,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 2,
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
