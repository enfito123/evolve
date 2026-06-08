import 'package:flutter/material.dart';
import '../modelos/rutina.dart';
import '../theme/colores_app.dart';
import 'pagina_rutina_detalle.dart';

class PaginaListaRutinas extends StatelessWidget {
  const PaginaListaRutinas({super.key});

  @override
  Widget build(BuildContext context) {
    final rutinas = [
      Rutina.acondicionamiento1,
      Rutina.acondicionamiento2,
      Rutina.acondicionamiento3,
    ];

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Entrenamientos'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rutinas.length,
        separatorBuilder: (_, b) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final rutina = rutinas[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PaginaRutinaDetalle(rutina: rutina),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColoresApp.tarjeta,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColoresApp.acentoMorado.withValues(alpha: 0.3),
                          ColoresApp.acentoMorado.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: ColoresApp.acentoMorado, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rutina.nombre,
                          style: const TextStyle(
                            color: ColoresApp.textoPrimario,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${rutina.bloques.length} bloques · ${rutina.totalEjercicios} ejercicios',
                          style: const TextStyle(
                            color: ColoresApp.textoSecundario,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: ColoresApp.textoSecundario, size: 22),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
