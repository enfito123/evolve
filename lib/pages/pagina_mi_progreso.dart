import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../modelos/perfil.dart';
import '../servicios/servicio_perfil.dart';
import '../servicios/servicio_registros.dart';
import '../servicios/servicio_salud.dart';
import '../theme/colores_app.dart';

class PaginaMiProgreso extends StatefulWidget {
  const PaginaMiProgreso({super.key});

  @override
  State<PaginaMiProgreso> createState() => _EstadoPaginaMiProgreso();
}

class _EstadoPaginaMiProgreso extends State<PaginaMiProgreso> {
  static const int _dias = 30;

  List<RegistroPeso> _pesos = [];
  List<int> _kcalPasosPorDia = List.filled(_dias, 0);
  List<int> _kcalEjercicioPorDia = List.filled(_dias, 0);
  ModeloPerfil? _perfil;
  bool _cargando = true;
  bool _autorizado = false;
  String? _error;

  int _kcalAcumuladasNuestras = 0;
  int _pasosAcumuladosNuestros = 0;
  DateTime? _fechaInicioNuestra;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    _perfil = await ServicioPerfil.instancia.cargar();
    final ya = await ServicioSalud.instancia.yaAutorizado();
    if (!mounted) return;
    setState(() => _autorizado = ya);
    if (ya) {
      await _cargar();
    } else {
      setState(() => _cargando = false);
    }
  }

  Future<void> _conectar() async {
    final disponible = await ServicioSalud.instancia.healthConnectDisponible();
    if (!mounted) return;
    if (!disponible) {
      final instalar = await _mostrarDialogoInstalar();
      if (instalar == true) {
        await ServicioSalud.instancia.instalarHealthConnect();
      }
      return;
    }
    final ok = await ServicioSalud.instancia.solicitarPermisos();
    if (!mounted) return;
    if (ok) {
      setState(() => _autorizado = true);
      await _cargar();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se concedieron permisos. Vuelve a intentarlo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _mostrarDialogoInstalar() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColoresApp.tarjeta,
        title: const Text('Falta Health Connect'),
        content: const Text(
          'Para leer datos de Google Fit (peso, pasos, calorías) tu móvil '
          'necesita la app "Health Connect" (de Google, gratis, oficial).\n\n'
          'Te abriré la Play Store para que la instales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Instalar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pesos = await ServicioSalud.instancia.leerPeso(dias: _dias);
      final pasosPorDia = await ServicioSalud.instancia.leerPasosPorDia(
        dias: _dias,
      );
      final kcalPasos = _calcularKcalPasosPorDia(pasosPorDia);
      final kcalEjercicio = await ServicioRegistros.instancia.kcalEjercicioPorDia(_dias);
      final kcalPasosNuestras = await ServicioRegistros.instancia.totalKcalDesde(
        DateTime(2020),
      );
      final kcalEjercicioNuestras = await ServicioRegistros.instancia.totalKcalEjercicioDesde(
        DateTime(2020),
      );
      final pasosNuestros = await ServicioRegistros.instancia.totalPasosDesde(
        DateTime(2020),
      );
      final fechaInicio = await ServicioRegistros.instancia.primeraFecha();
      if (!mounted) return;
      setState(() {
        _pesos = pesos;
        _kcalPasosPorDia = kcalPasos;
        _kcalEjercicioPorDia = kcalEjercicio;
        _kcalAcumuladasNuestras = kcalPasosNuestras + kcalEjercicioNuestras;
        _pasosAcumuladosNuestros = pasosNuestros;
        _fechaInicioNuestra = fechaInicio;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  List<int> _calcularKcalPasosPorDia(List<int> pasos) {
    final perfil = _perfil;
    if (perfil == null) return List.filled(pasos.length, 0);
    final alturaM = perfil.altura / 100.0;
    final strideM = perfil.sexo.name == 'masculino'
        ? 0.415 * alturaM
        : 0.413 * alturaM;
    return pasos.map((p) {
      final km = (p * strideM) / 1000.0;
      return (km * perfil.peso * 0.57).round();
    }).toList();
  }

  List<int> get _kcalTotalesPorDia {
    return List.generate(_dias, (i) => _kcalPasosPorDia[i] + _kcalEjercicioPorDia[i]);
  }

  RegistroPeso? get _pesoActual =>
      _pesos.isEmpty ? null : _pesos.last;

  RegistroPeso? get _pesoInicial =>
      _pesos.isEmpty ? null : _pesos.first;

  double? get _deltaPeso {
    if (_pesoActual == null || _pesoInicial == null) return null;
    return _pesoActual!.kilos - _pesoInicial!.kilos;
  }

  double? get _minPeso {
    if (_pesos.isEmpty) return null;
    return _pesos.map((p) => p.kilos).reduce((a, b) => a < b ? a : b);
  }

  double? get _maxPeso {
    if (_pesos.isEmpty) return null;
    return _pesos.map((p) => p.kilos).reduce((a, b) => a > b ? a : b);
  }

  double? get _promedioPeso {
    if (_pesos.isEmpty) return null;
    final suma = _pesos.fold<double>(0, (a, p) => a + p.kilos);
    return suma / _pesos.length;
  }

  int get _kcalHoy =>
      _dias > 0 ? _kcalTotalesPorDia[_dias - 1] : 0;

  int get _promedioKcal {
    if (_kcalTotalesPorDia.isEmpty) return 0;
    final suma = _kcalTotalesPorDia.fold<int>(0, (a, b) => a + b);
    return (suma / _kcalTotalesPorDia.length).round();
  }

  static const int _kcalPorKgGrasa = 7700;

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
        title: const Text('Mi Progreso'),
        actions: [
          if (_autorizado)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _cargando ? null : _cargar,
            ),
        ],
      ),
      body: SafeArea(
        child: _autorizado
            ? _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ColoresApp.acentoGradiente1,
                    ),
                  )
                : _buildContenido()
            : _buildConectar(),
      ),
    );
  }

  Widget _buildConectar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColoresApp.acentoGradiente1.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                size: 56,
                color: ColoresApp.acentoGradiente1,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Conecta Google Fit',
              style: TextStyle(
                color: ColoresApp.textoPrimario,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para mostrar tu peso, pasos y calorías a lo largo del tiempo, '
              'Evolve necesita leer datos de Google Fit / Health Connect.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _conectar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.acentoGradiente1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Conectar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroPeso(),
          const SizedBox(height: 16),
          _buildGraficoPeso(),
          const SizedBox(height: 16),
          _buildGraficoCalorias(),
          const SizedBox(height: 16),
          _buildAcumuladoYRecordatorio(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColoresApp.acentoCalor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Aviso: $_error',
                style: const TextStyle(
                  color: ColoresApp.acentoCalor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroPeso() {
    final peso = _pesoActual;
    final delta = _deltaPeso;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColoresApp.acentoGradiente1.withValues(alpha: 0.25),
            ColoresApp.acentoGradiente2.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ColoresApp.acentoGradiente1.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monitor_weight_rounded,
                  color: ColoresApp.acentoGradiente1,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PESO ACTUAL',
                      style: TextStyle(
                        color: ColoresApp.acentoGradiente1,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      peso != null
                          ? '${peso.kilos.toStringAsFixed(1)} kg'
                          : '—',
                      style: const TextStyle(
                        color: ColoresApp.acentoGradiente1,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (delta != null)
                      Text(
                        '${delta >= 0 ? '+' : '−'}${delta.abs().toStringAsFixed(1)} kg en $_dias días',
                        style: TextStyle(
                          color: delta < 0
                              ? ColoresApp.acentoVerde
                              : ColoresApp.acentoCalor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const Text(
                        'Sin datos',
                        style: TextStyle(
                          color: ColoresApp.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_promedioPeso != null && _pesos.length > 1) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: ColoresApp.acentoGradiente1.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _dato(
                    'Mínimo',
                    '${_minPeso!.toStringAsFixed(1)} kg',
                    ColoresApp.acentoVerde,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: ColoresApp.acentoGradiente1.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _dato(
                    'Promedio',
                    '${_promedioPeso!.toStringAsFixed(1)} kg',
                    ColoresApp.acentoGradiente1,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: ColoresApp.acentoGradiente1.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _dato(
                    'Máximo',
                    '${_maxPeso!.toStringAsFixed(1)} kg',
                    ColoresApp.acentoCalor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dato(String etiqueta, String valor, Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            color: c,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoPeso() {
    return _SeccionGrafico(
      icono: Icons.show_chart_rounded,
      colorIcono: ColoresApp.acentoGradiente1,
      titulo: 'Tu peso · 30 días',
      subtitulo: 'Origen: Google Fit',
      altura: 200,
      contenido: _pesos.isEmpty
          ? const _MensajeVacio(
              texto: 'Sin registros de peso.\n'
                  'Pésate en Google Fit o añade uno manualmente.',
            )
          : CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _PintorGraficoPeso(
                pesos: _pesos,
                dias: _dias,
                colorLinea: ColoresApp.acentoGradiente1,
                colorArea: ColoresApp.acentoGradiente1,
                ejes: const Color(0xFF9AA3BF),
              ),
            ),
    );
  }

  Widget _buildGraficoCalorias() {
    final tieneDatos = _kcalTotalesPorDia.any((k) => k > 0);
    return _SeccionGrafico(
      icono: Icons.local_fire_department_rounded,
      colorIcono: ColoresApp.acentoCalor,
      titulo: 'Calorías quemadas · 30 días',
      subtitulo: 'Pasos (azul) + Ejercicio (morado) — Origen: Evolve',
      altura: 200,
      extra: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(
          children: [
            _chip(
              'Hoy',
              '$_kcalHoy kcal',
              ColoresApp.acentoCalor,
            ),
            const SizedBox(width: 8),
            _chip(
              'Promedio',
              '$_promedioKcal kcal',
              ColoresApp.acentoGradiente1,
            ),
          ],
        ),
      ),
      contenido: !tieneDatos
          ? const _MensajeVacio(
              texto:
                  'Sin datos de calorías.\nConecta los pasos o registra un entrenamiento.',
            )
          : CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _PintorGraficoCalorias(
                kcalPasos: _kcalPasosPorDia,
                kcalEjercicio: _kcalEjercicioPorDia,
                dias: _dias,
                colorPasos: ColoresApp.acentoTeal,
                colorEjercicio: ColoresApp.acentoMorado,
                ejes: const Color(0xFF9AA3BF),
              ),
            ),
    );
  }

  Widget _buildAcumuladoYRecordatorio() {
    if (_kcalAcumuladasNuestras <= 0) return const SizedBox.shrink();

    final formato = NumberFormat.decimalPattern('es');
    final fechaInicio = _fechaInicioNuestra;
    final fechaInicioTexto = fechaInicio != null
        ? '${fechaInicio.day} de ${DateFormat('MMM', 'es').format(fechaInicio)}'
        : '';

    final double kgGrasa = _kcalAcumuladasNuestras / _kcalPorKgGrasa;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColoresApp.acentoVerde.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: ColoresApp.acentoVerde,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Total acumulado',
                  style: const TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Desde que has instalado la aplicación has quemado ',
                  style: TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                TextSpan(
                  text: '${formato.format(_kcalAcumuladasNuestras)} kcal',
                  style: const TextStyle(
                    color: ColoresApp.acentoVerde,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (fechaInicioTexto.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Desde el $fechaInicioTexto · ${formato.format(_pasosAcumuladosNuestros)} pasos',
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: ColoresApp.tarjetaSutil,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColoresApp.acentoCalor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: ColoresApp.acentoCalor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recordatorio: 1 kg de grasa',
                      style: TextStyle(
                        color: ColoresApp.textoPrimario,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perder 1 kg de grasa corporal requiere un déficit de ~${formato.format(_kcalPorKgGrasa)} kcal.',
                      style: const TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ColoresApp.acentoCalor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            formato.format(_kcalAcumuladasNuestras),
                            style: const TextStyle(
                              color: ColoresApp.acentoCalor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/ ${formato.format(_kcalPorKgGrasa)} kcal',
                            style: const TextStyle(
                              color: ColoresApp.textoSecundario,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '= ${kgGrasa.toStringAsFixed(2)} kg',
                            style: TextStyle(
                              color: ColoresApp.acentoCalor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Esto es solo el total quemado por pasos. El déficit real depende de lo que ingeriste (ver balance calórico).',
                      style: const TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String etiqueta, String valor, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$etiqueta: ',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 11,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

}

class _SeccionGrafico extends StatelessWidget {
  const _SeccionGrafico({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.subtitulo,
    required this.altura,
    required this.contenido,
    this.extra,
  });

  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String subtitulo;
  final double altura;
  final Widget contenido;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorIcono.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: colorIcono, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: ColoresApp.textoPrimario,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (extra != null) ...[
            const SizedBox(height: 10),
            extra!,
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: altura,
            child: contenido,
          ),
        ],
      ),
    );
  }
}

class _MensajeVacio extends StatelessWidget {
  const _MensajeVacio({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ColoresApp.textoSecundario,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _PintorGraficoPeso extends CustomPainter {
  _PintorGraficoPeso({
    required this.pesos,
    required this.dias,
    required this.colorLinea,
    required this.colorArea,
    required this.ejes,
  });

  final List<RegistroPeso> pesos;
  final int dias;
  final Color colorLinea;
  final Color colorArea;
  final Color ejes;

  @override
  void paint(Canvas canvas, Size size) {
    if (pesos.length < 2) return;

    const paddingIzq = 38.0;
    const paddingDer = 8.0;
    const paddingSup = 8.0;
    const paddingInf = 22.0;

    final ancho = size.width - paddingIzq - paddingDer;
    final alto = size.height - paddingSup - paddingInf;

    final minK = pesos.map((p) => p.kilos).reduce((a, b) => a < b ? a : b);
    final maxK = pesos.map((p) => p.kilos).reduce((a, b) => a > b ? a : b);
    final rango = (maxK - minK).abs();
    final pad = rango < 1.0 ? 0.5 : rango * 0.15;
    final yMin = minK - pad;
    final yMax = maxK + pad;
    final yRango = (yMax - yMin).abs();
    final yEscala = yRango == 0 ? 1.0 : yRango;

    final primera = pesos.first.fecha;
    double xDeFecha(DateTime f) {
      final diasDesdeInicio = f.difference(primera).inHours / 24.0;
      final totalDias = (pesos.last.fecha.difference(primera).inHours / 24.0)
          .clamp(1.0, double.infinity);
      final fraccion = (diasDesdeInicio / totalDias).clamp(0.0, 1.0);
      return paddingIzq + fraccion * ancho;
    }

    double yDeValor(double k) {
      final fraccion = (k - yMin) / yEscala;
      return paddingSup + alto - (fraccion * alto).clamp(0.0, alto);
    }

    final pinturaCuadricula = Paint()
      ..color = ejes.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    final textoEstilo = TextStyle(
      color: ejes,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    void dibujarEtiquetaY(double valor, {bool arriba = false}) {
      final y = arriba ? paddingSup : paddingSup + alto;
      final tp = TextPainter(
        text: TextSpan(text: valor.toStringAsFixed(1), style: textoEstilo),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingIzq - tp.width - 4, y - tp.height / 2));
    }

    dibujarEtiquetaY(maxK, arriba: true);
    dibujarEtiquetaY(minK);

    canvas.drawLine(
      Offset(paddingIzq, paddingSup + alto / 2),
      Offset(paddingIzq + ancho, paddingSup + alto / 2),
      pinturaCuadricula,
    );
    canvas.drawLine(
      Offset(paddingIzq, paddingSup),
      Offset(paddingIzq, paddingSup + alto),
      pinturaCuadricula,
    );

    final path = Path();
    for (int i = 0; i < pesos.length; i++) {
      final x = xDeFecha(pesos[i].fecha);
      final y = yDeValor(pesos[i].kilos);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final pathArea = Path.from(path)
      ..lineTo(xDeFecha(pesos.last.fecha), paddingSup + alto)
      ..lineTo(xDeFecha(pesos.first.fecha), paddingSup + alto)
      ..close();

    final pinturaArea = Paint()
      ..shader = LinearGradient(
        colors: [
          colorArea.withValues(alpha: 0.35),
          colorArea.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(pathArea, pinturaArea);

    final pinturaLinea = Paint()
      ..color = colorLinea
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, pinturaLinea);

    final pinturaPunto = Paint()..color = colorLinea;
    for (final p in pesos) {
      final x = xDeFecha(p.fecha);
      final y = yDeValor(p.kilos);
      canvas.drawCircle(Offset(x, y), 3.0, pinturaPunto);
      canvas.drawCircle(
        Offset(x, y),
        3.0,
        Paint()..color = const Color(0xFF0B1020),
      );
      canvas.drawCircle(Offset(x, y), 2.0, pinturaPunto);
    }

    final formatoCorto = DateFormat('d MMM', 'es');
    final tpInicio = TextPainter(
      text: TextSpan(
        text: formatoCorto.format(pesos.first.fecha),
        style: textoEstilo,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpInicio.paint(
      canvas,
      Offset(paddingIzq, paddingSup + alto + 6),
    );
    final tpFin = TextPainter(
      text: TextSpan(
        text: formatoCorto.format(pesos.last.fecha),
        style: textoEstilo,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpFin.paint(
      canvas,
      Offset(paddingIzq + ancho - tpFin.width, paddingSup + alto + 6),
    );
  }

  @override
  bool shouldRepaint(covariant _PintorGraficoPeso old) {
    return old.pesos != pesos;
  }
}

class _PintorGraficoCalorias extends CustomPainter {
  _PintorGraficoCalorias({
    required this.kcalPasos,
    required this.kcalEjercicio,
    required this.dias,
    required this.colorPasos,
    required this.colorEjercicio,
    required this.ejes,
  });

  final List<int> kcalPasos;
  final List<int> kcalEjercicio;
  final int dias;
  final Color colorPasos;
  final Color colorEjercicio;
  final Color ejes;

  @override
  void paint(Canvas canvas, Size size) {
    const paddingIzq = 36.0;
    const paddingDer = 8.0;
    const paddingSup = 8.0;
    const paddingInf = 22.0;

    final ancho = size.width - paddingIzq - paddingDer;
    final alto = size.height - paddingSup - paddingInf;

    final totales = List.generate(dias, (i) => kcalPasos[i] + kcalEjercicio[i]);
    final maxK = totales.reduce((a, b) => a > b ? a : b);
    final yMax = (maxK * 1.15).ceilToDouble();
    final yEscala = yMax == 0 ? 1.0 : yMax;

    final pinturaCuadricula = Paint()
      ..color = ejes.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    final textoEstilo = TextStyle(
      color: ejes,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    void dibujarEtiquetaY(int valor) {
      final y = paddingSup + alto - (valor / yEscala) * alto;
      final tp = TextPainter(
        text: TextSpan(
          text: valor >= 1000
              ? '${(valor / 1000).toStringAsFixed(1)}k'
              : '$valor',
          style: textoEstilo,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingIzq - tp.width - 4, y - tp.height / 2));
    }

    dibujarEtiquetaY(maxK);
    dibujarEtiquetaY((maxK / 2).round());
    dibujarEtiquetaY(0);

    canvas.drawLine(
      Offset(paddingIzq, paddingSup + alto / 2),
      Offset(paddingIzq + ancho, paddingSup + alto / 2),
      pinturaCuadricula,
    );
    canvas.drawLine(
      Offset(paddingIzq, paddingSup),
      Offset(paddingIzq, paddingSup + alto),
      pinturaCuadricula,
    );

    final anchoBarra = (ancho / dias) * 0.7;
    final espacio = (ancho / dias) * 0.3;

    for (int i = 0; i < dias; i++) {
      final xCentro = paddingIzq + (i + 0.5) * (anchoBarra + espacio);
      final total = kcalPasos[i] + kcalEjercicio[i];
      if (total == 0) continue;

      final hPasos = (kcalPasos[i] / yEscala) * alto;
      final hEjercicio = (kcalEjercicio[i] / yEscala) * alto;

      if (hPasos > 0) {
        final rectPasos = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            xCentro - anchoBarra / 2,
            paddingSup + alto - hPasos,
            anchoBarra,
            hPasos,
          ),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rectPasos, Paint()..color = colorPasos);
      }

      if (hEjercicio > 0) {
        final rectEj = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            xCentro - anchoBarra / 2,
            paddingSup + alto - hPasos - hEjercicio,
            anchoBarra,
            hEjercicio,
          ),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rectEj, Paint()..color = colorEjercicio);
      }
    }

    final hoy = DateTime.now();
    final hace30 = hoy.subtract(const Duration(days: 29));
    final textoEstiloFecha = TextStyle(
      color: ejes,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final tpInicio = TextPainter(
      text: TextSpan(
        text: DateFormat('d MMM', 'es').format(hace30),
        style: textoEstiloFecha,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpInicio.paint(canvas, Offset(paddingIzq, paddingSup + alto + 6));

    final tpFin = TextPainter(
      text: TextSpan(
        text: 'Hoy',
        style: textoEstiloFecha.copyWith(
          color: ColoresApp.acentoCalor,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpFin.paint(
      canvas,
      Offset(paddingIzq + ancho - tpFin.width, paddingSup + alto + 6),
    );

    final legendaPasos = TextPainter(
      text: TextSpan(
        text: '■ Pasos',
        style: TextStyle(
          color: colorPasos,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    legendaPasos.paint(
      canvas,
      Offset(
        paddingIzq + ancho / 2 - legendaPasos.width - 4,
        paddingSup + alto + 6,
      ),
    );

    final legendaEj = TextPainter(
      text: TextSpan(
        text: '■ Ejercicio',
        style: TextStyle(
          color: colorEjercicio,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    legendaEj.paint(
      canvas,
      Offset(
        paddingIzq + ancho / 2 + 4,
        paddingSup + alto + 6,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _PintorGraficoCalorias old) {
    return old.kcalPasos != kcalPasos || old.kcalEjercicio != kcalEjercicio;
  }
}
