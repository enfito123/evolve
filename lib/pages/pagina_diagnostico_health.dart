import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../theme/colores_app.dart';

class PaginaDiagnosticoHealth extends StatefulWidget {
  const PaginaDiagnosticoHealth({super.key});

  @override
  State<PaginaDiagnosticoHealth> createState() => _EstadoDiagnostico();
}

class _EstadoDiagnostico extends State<PaginaDiagnosticoHealth> {
  final Health _health = Health();
  bool _cargando = true;
  String? _error;
  final Map<String, List<_DatoHealth>> _datos = {};

  static const List<HealthDataType> _tipos = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.LEAN_BODY_MASS,
    HealthDataType.HEIGHT,
    HealthDataType.BASAL_ENERGY_BURNED,
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _datos.clear();
    });
    try {
      final tiene = await _health.hasPermissions(
        _tipos,
        permissions: List.filled(_tipos.length, HealthDataAccess.READ),
      );
      if (tiene != true) {
        final ok = await _health.requestAuthorization(
          _tipos,
          permissions: List.filled(_tipos.length, HealthDataAccess.READ),
        );
        if (ok != true) {
          if (!mounted) return;
          setState(() {
            _cargando = false;
            _error = 'Permisos no concedidos. Otorga los permisos de Health Connect manualmente.';
          });
          return;
        }
      }
      final ahora = DateTime.now();
      final inicio = ahora.subtract(const Duration(days: 90));
      for (final tipo in _tipos) {
        try {
          final datos = await _health.getHealthDataFromTypes(
            types: [tipo],
            startTime: inicio,
            endTime: ahora,
          );
          if (datos.isNotEmpty) {
            final lista = <_DatoHealth>[];
            for (final d in datos) {
              final v = d.value;
              String valor = '';
              if (v is NumericHealthValue) {
                valor = v.numericValue.toStringAsFixed(2);
              } else {
                valor = v.toString();
              }
              lista.add(_DatoHealth(
                valor: valor,
                fecha: d.dateFrom,
                origen: d.sourceName,
                tipo: tipo.name,
                unit: d.unit.name,
              ));
            }
            lista.sort((a, b) => b.fecha.compareTo(a.fecha));
            _datos[tipo.name] = lista;
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _cargando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Diagnóstico Health Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: ColoresApp.acentoMorado))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center),
                  ),
                )
              : _datos.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron datos de body measurement\nen los últimos 90 días.\n\n'
                        'Asegúrate de que Insmart Health esté sincronizando\n'
                        'datos con Health Connect.',
                        style: TextStyle(color: ColoresApp.textoSecundario),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _datos.entries.map((entry) {
                        final registros = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${entry.key} (${registros.length} registros)',
                                style: const TextStyle(
                                  color: ColoresApp.acentoMorado,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ...registros.take(10).map((d) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ColoresApp.tarjeta,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${d.valor} ${d.unit}',
                                          style: const TextStyle(
                                            color: ColoresApp.textoPrimario,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${d.fecha.day}/${d.fecha.month}/${d.fecha.year}',
                                        style: const TextStyle(
                                          color: ColoresApp.textoSecundario,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Origen: ${d.origen}',
                                    style: TextStyle(
                                      color: d.origen.toLowerCase().contains('insmart')
                                          ? ColoresApp.acentoVerde
                                          : ColoresApp.textoSecundario,
                                      fontSize: 11,
                                      fontWeight: d.origen.toLowerCase().contains('insmart')
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ),
    );
  }
}

class _DatoHealth {
  final String valor;
  final DateTime fecha;
  final String origen;
  final String tipo;
  final String unit;
  const _DatoHealth({
    required this.valor,
    required this.fecha,
    required this.origen,
    required this.tipo,
    required this.unit,
  });
}
