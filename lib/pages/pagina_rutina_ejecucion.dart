import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../modelos/rutina.dart';
import '../servicios/servicio_beep.dart';
import '../servicios/servicio_registros.dart';
import '../theme/colores_app.dart';

enum _Fase { prep, ejercicio, descanso, bloqueDescanso, completo }

class PaginaRutinaEjecucion extends StatefulWidget {
  const PaginaRutinaEjecucion({super.key, required this.rutina, this.pesoKg = 70});
  final Rutina rutina;
  final double pesoKg;

  @override
  State<PaginaRutinaEjecucion> createState() => _EstadoRutinaEjecucion();
}

class _EstadoRutinaEjecucion extends State<PaginaRutinaEjecucion> {
  static const int _duracionPrep = 10;

  Timer? _temporizador;
  _Fase _fase = _Fase.prep;
  int _contador = _duracionPrep;

  int _bloqueIndex = 0;
  int _rondaIndex = 0;
  int _ejercicioIndex = 0;

  int _totalCompletados = 0;
  int _kcalQuemadas = 0;
  bool _enPausa = false;
  bool _cancelado = false;
  bool _enSegundoSegmento = false;

  @override
  void initState() {
    super.initState();
    ServicioBeep.instancia.iniciar();
    _iniciarPrep();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    ServicioBeep.instancia.parar();
    super.dispose();
  }

  void _iniciarPrep() {
    _fase = _Fase.prep;
    _contador = _duracionPrep;
    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _enPausa || _cancelado) return;
      setState(() {
        _contador--;
      });
      if (_contador <= 0) {
        _avanzar();
      } else if (_fase == _Fase.ejercicio && !_enSegundoSegmento) {
        final ej = widget.rutina.bloques[_bloqueIndex].ejercicios[_ejercicioIndex];
        if (ej.puntoMedio != null && _contador <= ej.puntoMedio!) {
          _enSegundoSegmento = true;
          _sonarPitidoCambio();
        }
      }
    });
  }

  void _avanzar() {
    _temporizador?.cancel();
    if (_cancelado) return;

    switch (_fase) {
      case _Fase.prep:
        _sonarPitidoInicio();
        _iniciarEjercicio();
        break;
      case _Fase.ejercicio:
        _registrarKcalEjercicio();
        _sonarPitidoFin();
        _iniciarDescanso();
        break;
      case _Fase.descanso:
        _totalCompletados++;
        if (_siguienteEjercicio()) {
          _sonarPitidoInicio();
          _iniciarEjercicio();
        }
        break;
      case _Fase.bloqueDescanso:
        _sonarPitidoInicio();
        _iniciarEjercicio();
        break;
      case _Fase.completo:
        break;
    }
  }

  void _iniciarEjercicio() {
    _fase = _Fase.ejercicio;
    _contador = widget.rutina.duracionEjercicio;
    _enSegundoSegmento = false;
    _iniciarTemporizador();
  }

  void _registrarKcalEjercicio() {
    final bloque = widget.rutina.bloques[_bloqueIndex];
    final ej = bloque.ejercicios[_ejercicioIndex];
    final kcal = widget.rutina.kcalPorEjercicio(ej, pesoKg: widget.pesoKg).round();
    _kcalQuemadas += kcal;
    final nombre = _enSegundoSegmento && ej.segundoNombre != null ? ej.segundoNombre! : ej.nombre;
    ServicioRegistros.instancia.guardarEjercicioDetalle(nombre, kcal);
  }

  Future<void> _guardarKcal() async {
    if (_kcalQuemadas > 0) {
      await ServicioRegistros.instancia.guardarEjercicio(_kcalQuemadas);
    }
  }

  void _iniciarDescanso() {
    _fase = _Fase.descanso;
    _contador = widget.rutina.duracionDescanso;
    _iniciarTemporizador();
  }

  bool _siguienteEjercicio() {
    final bloque = widget.rutina.bloques[_bloqueIndex];
    if (_ejercicioIndex < bloque.ejercicios.length - 1) {
      _ejercicioIndex++;
      return true;
    }
    if (_rondaIndex < bloque.repeticiones - 1) {
      _rondaIndex++;
      _ejercicioIndex = 0;
      return true;
    }
    if (_bloqueIndex < widget.rutina.bloques.length - 1) {
      _bloqueIndex++;
      _rondaIndex = 0;
      _ejercicioIndex = 0;
      _fase = _Fase.bloqueDescanso;
      _contador = widget.rutina.descansoBloque;
      _sonarPitidoFin();
      _iniciarTemporizador();
      return false;
    }
    setState(() => _fase = _Fase.completo);
    _temporizador?.cancel();
    _guardarKcal();
    return false;
  }

  void _sonarPitidoInicio() {
    try {
      HapticFeedback.heavyImpact();
      ServicioBeep.instancia.pitidoInicio();
    } catch (_) {}
  }

  void _sonarPitidoFin() {
    try {
      HapticFeedback.mediumImpact();
      ServicioBeep.instancia.pitidoFin();
    } catch (_) {}
  }

  void _sonarPitidoCambio() {
    try {
      HapticFeedback.selectionClick();
      ServicioBeep.instancia.pitidoCambio();
    } catch (_) {}
  }

  void _togglePausa() {
    setState(() => _enPausa = !_enPausa);
    if (!_enPausa && _fase != _Fase.completo) {
      _iniciarTemporizador();
    } else {
      _temporizador?.cancel();
    }
  }

  Future<void> _cancelarRutina() async {
    _cancelado = true;
    _temporizador?.cancel();
    if (_fase == _Fase.ejercicio) {
      _registrarKcalEjercicio();
    }
    await _guardarKcal();
    if (mounted) Navigator.of(context).pop(_kcalQuemadas);
  }

  String get _nombreBloqueActual =>
      widget.rutina.bloques[_bloqueIndex].nombre;

  String get _nombreEjercicioActual {
    final ej = widget.rutina.bloques[_bloqueIndex].ejercicios[_ejercicioIndex];
    if (_enSegundoSegmento && ej.segundoNombre != null) return ej.segundoNombre!;
    return ej.nombre;
  }

  String? get _imagenEjercicioActual {
    final ej = widget.rutina.bloques[_bloqueIndex].ejercicios[_ejercicioIndex];
    return ej.imagen;
  }

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.decimalPattern('es');

    if (_fase == _Fase.completo) {
      return _PantallaCompletado(
        totalEjercicios: _totalCompletados,
        kcalQuemadas: _kcalQuemadas,
        onVolver: () => Navigator.of(context).pop(_kcalQuemadas),
      );
    }

    final esEjercicio = _fase == _Fase.ejercicio;
    final esDescanso = _fase == _Fase.descanso || _fase == _Fase.bloqueDescanso;
    final esPrep = _fase == _Fase.prep;

    final colorFase = esEjercicio
        ? ColoresApp.acentoCalor
        : esDescanso
            ? ColoresApp.acentoVerde
            : ColoresApp.acentoPrimario;

    final labelFase = esPrep
        ? 'PREPARACIÓN'
        : esEjercicio
            ? _nombreEjercicioActual.toUpperCase()
            : 'DESCANSO';

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: ColoresApp.textoSecundario,
                    onPressed: () => _mostrarDialogoCancelar(),
                  ),
                  const Spacer(),
                  Text(
                    _nombreBloqueActual,
                    style: const TextStyle(
                      color: ColoresApp.textoPrimario,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.rutina.bloques[_bloqueIndex].repeticiones > 1) ...[
                    const SizedBox(width: 6),
                    Text(
                      'R${_rondaIndex + 1}/${widget.rutina.bloques[_bloqueIndex].repeticiones}',
                      style: const TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '$_totalCompletados/${widget.rutina.totalEjercicios}',
                    style: const TextStyle(
                      color: ColoresApp.textoSecundario,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorFase.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      labelFase,
                      style: TextStyle(
                        color: colorFase,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: _valorProgreso,
                            strokeWidth: 8,
                            backgroundColor: colorFase.withValues(alpha: 0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(colorFase),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          formato.format(_contador),
                          style: TextStyle(
                            color: colorFase,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    esPrep
                        ? 'Prepárate'
                        : _nombreEjercicioActual,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ColoresApp.textoPrimario,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!esPrep) ...[
                    const SizedBox(height: 4),
                    Text(
                      esEjercicio
                          ? '¡Ahora!'
                          : 'Siguiente: ${_siguienteNombre()}',
                      style: TextStyle(
                        color: esEjercicio
                            ? ColoresApp.acentoCalor
                            : ColoresApp.textoSecundario,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _imagenEjercicioActual != null && esEjercicio
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          _imagenEjercicioActual!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelarRutina,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: ColoresApp.textoSecundario),
                        foregroundColor: ColoresApp.textoSecundario,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _togglePausa,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorFase,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _enPausa ? 'CONTINUAR' : 'PAUSAR',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _valorProgreso {
    final total = _fase == _Fase.prep
        ? _duracionPrep
        : _fase == _Fase.ejercicio
            ? widget.rutina.duracionEjercicio
            : widget.rutina.duracionDescanso;
    if (total == 0) return 0;
    return _contador / total;
  }

  String _siguienteNombre() {
    final bloque = widget.rutina.bloques[_bloqueIndex];
    if (_ejercicioIndex < bloque.ejercicios.length - 1) {
      return bloque.ejercicios[_ejercicioIndex + 1].nombre;
    }
    if (_rondaIndex < bloque.repeticiones - 1) {
      return bloque.ejercicios[0].nombre;
    }
    if (_bloqueIndex < widget.rutina.bloques.length - 1) {
      return widget.rutina.bloques[_bloqueIndex + 1].nombre;
    }
    return '¡Fin!';
  }

  Future<void> _mostrarDialogoCancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColoresApp.tarjeta,
        title: const Text('¿Cancelar rutina?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Perderás el progreso de esta sesión.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmar == true) await _cancelarRutina();
  }
}

class _PantallaCompletado extends StatelessWidget {
  const _PantallaCompletado({
    required this.totalEjercicios,
    required this.kcalQuemadas,
    required this.onVolver,
  });

  final int totalEjercicios;
  final int kcalQuemadas;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ColoresApp.acentoVerde.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: ColoresApp.acentoVerde, size: 64),
                ),
                const SizedBox(height: 28),
                const Text(
                  '¡Rutina completada!',
                  style: TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Has completado $totalEjercicios ejercicios',
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '~$kcalQuemadas kcal quemadas',
                  style: const TextStyle(
                    color: ColoresApp.acentoCalor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Buen trabajo 💪',
                  style: TextStyle(
                    color: ColoresApp.acentoVerde,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onVolver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.acentoVerde,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('VOLVER',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
