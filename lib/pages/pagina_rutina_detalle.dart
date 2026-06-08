import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../modelos/rutina.dart';
import '../servicios/servicio_perfil.dart';
import '../theme/colores_app.dart';
import 'pagina_rutina_ejecucion.dart';

class PaginaRutinaDetalle extends StatefulWidget {
  const PaginaRutinaDetalle({super.key, required this.rutina});

  final Rutina rutina;

  @override
  State<PaginaRutinaDetalle> createState() => _EstadoPaginaRutinaDetalle();
}

class _EstadoPaginaRutinaDetalle extends State<PaginaRutinaDetalle> {
  double _pesoKg = 70;

  @override
  void initState() {
    super.initState();
    _cargarPeso();
  }

  Future<void> _cargarPeso() async {
    final perfil = await ServicioPerfil.instancia.cargar();
    if (!mounted) return;
    setState(() => _pesoKg = perfil?.peso ?? 70);
  }

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.decimalPattern('es');
    final duracionMin = widget.rutina.duracionTotalSegundos ~/ 60;
    final duracionSeg = widget.rutina.duracionTotalSegundos % 60;
    final kcalTotal = widget.rutina.kcalTotales(pesoKg: _pesoKg);
    final rutina = widget.rutina;

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Detalle rutina'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: ColoresApp.tarjeta,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.all(16),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          collapsedIconColor: ColoresApp.textoSecundario,
                          iconColor: ColoresApp.acentoMorado,
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColoresApp.acentoMorado.withValues(alpha: 0.3),
                                  ColoresApp.acentoMorado.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.fitness_center_rounded,
                                color: ColoresApp.acentoMorado, size: 24),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rutina.nombre,
                                style: const TextStyle(
                                  color: ColoresApp.textoPrimario,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _MiniChip(texto: '${formato.format(duracionMin)}:${duracionSeg.toString().padLeft(2, '0')}'),
                                  _MiniChip(texto: '${rutina.totalEjercicios} ejercicios'),
                                  _MiniChip(texto: '~$kcalTotal kcal', color: ColoresApp.acentoCalor),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaginaRutinaEjecucion(rutina: rutina, pesoKg: _pesoKg),
                                    ),
                                  );
                                  if (context.mounted) Navigator.of(context).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: ColoresApp.acentoMorado,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.expand_more_rounded, size: 22, color: ColoresApp.textoSecundario),
                            ],
                          ),
                          children: [
                            Text(
                              rutina.descripcion,
                              style: const TextStyle(
                                color: ColoresApp.textoSecundario,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...rutina.bloques.map((bloque) => _TarjetaBloque(
                                  rutina: rutina,
                                  bloque: bloque,
                                  formato: formato,
                                  pesoKg: _pesoKg,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ColoresApp.tarjetaSutil,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.white54, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cada ejercicio: 40s trabajo / 15s descanso. '
                              'Las kcal son estimadas según tu peso, altura y sexo.',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.texto, this.color});
  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? ColoresApp.textoSecundario;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(texto,
          style: TextStyle(
              color: c,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _TarjetaBloque extends StatelessWidget {
  const _TarjetaBloque({
    required this.rutina,
    required this.bloque,
    required this.formato,
    required this.pesoKg,
  });

  final Rutina rutina;
  final BloqueRutina bloque;
  final NumberFormat formato;
  final double pesoKg;

  @override
  Widget build(BuildContext context) {
    final kcalBloque = rutina.kcalBloque(bloque, pesoKg: pesoKg);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColoresApp.acentoMorado.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.view_module_rounded,
                    color: ColoresApp.acentoMorado, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bloque.nombre,
                      style: const TextStyle(
                        color: ColoresApp.textoPrimario,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${bloque.ejercicios.length} ej × ${bloque.repeticiones} rondas',
                      style: const TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '~$kcalBloque kcal',
                style: const TextStyle(
                  color: ColoresApp.acentoCalor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(bloque.ejercicios.length, (i) {
            final ej = bloque.ejercicios[i];
            final kcalPorRep = rutina.kcalPorEjercicio(ej, pesoKg: pesoKg);
            final kcalTotal = (kcalPorRep * bloque.repeticiones).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ColoresApp.acentoMorado.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: ColoresApp.acentoMorado,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ej.nombre,
                      style: const TextStyle(
                        color: ColoresApp.textoPrimario,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '~$kcalTotal kcal',
                    style: const TextStyle(
                      color: ColoresApp.acentoCalor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
