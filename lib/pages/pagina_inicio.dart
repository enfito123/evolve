import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../modelos/perfil.dart';
import '../servicios/servicio_nutricion.dart';
import '../servicios/servicio_pasos.dart';
import '../servicios/servicio_perfil.dart';
import '../servicios/servicio_salud.dart';
import '../theme/colores_app.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/tarjeta_estadistica.dart';
import '../widgets/tarjeta_funcion.dart';
import '../widgets/tarjeta_sesion.dart';
import 'pagina_configuracion_groq.dart';
import 'pagina_info_balance.dart';
import 'pagina_info_calorias_basales.dart';
import 'pagina_mi_progreso.dart';
import 'pagina_nutricion.dart';
import 'pagina_perfil.dart';
import 'pagina_lista_rutinas.dart';
import 'pagina_diagnostico_health.dart';
import '../servicios/servicio_registros.dart';

class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key});

  @override
  State<PaginaInicio> createState() => _EstadoPaginaInicio();
}

class _EstadoPaginaInicio extends State<PaginaInicio>
    with WidgetsBindingObserver {
  static const int _metaPasosDiaria = 10000;

  ModeloPerfil? _perfil;
  int _caloriasIngeridasHoy = 0;
  int _caloriasQuemadasEjercicio = 0;
  int _pasosHoy = 0;
  bool _pasosConectado = false;
  int _caloriasQuemadasPasosCache = 0;
  Timer? _temporizador;

  double? _pesoHC;
  double? _grasaCorporal;
  double? _masaMagra;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarPerfil();
    _cargarCaloriasIngeridas();
    _cargarCaloriasEjercicio();
    _iniciarPasos();
    _iniciarTemporizador();
  }

  @override
  void dispose() {
    _detenerTemporizador();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      _iniciarTemporizador();
      _cargarCaloriasIngeridas();
      _cargarCaloriasEjercicio();
      _cargarComposicionCorporal();
      if (mounted) setState(() {});
    } else {
      _detenerTemporizador();
    }
  }

  void _iniciarTemporizador() {
    _temporizador?.cancel();
    int contadorRefresh = 0;
    _temporizador = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (!mounted) return;
      setState(() {});
      if (_pasosConectado) {
        await _cargarPasos();
      } else {
        _recalcularKcalPasos();
      }
      contadorRefresh++;
      if (contadorRefresh % 15 == 0) {
        _cargarComposicionCorporal();
      }
    });
  }

  void _detenerTemporizador() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  Future<void> _cargarPerfil() async {
    final perfil = await ServicioPerfil.instancia.cargar();
    if (!mounted) return;
    setState(() => _perfil = perfil);
    _recalcularKcalPasos();
    _cargarComposicionCorporal();
  }

  Future<void> _cargarComposicionCorporal() async {
    final peso = await ServicioSalud.instancia.leerPesoActual();
    final grasa = await ServicioSalud.instancia.leerGrasaCorporal();
    final masaMagra = await ServicioSalud.instancia.leerMasaMagra();
    if (peso != null && _perfil != null && peso != _perfil!.peso) {
      final actualizado = _perfil!.copyWith(peso: peso);
      await ServicioPerfil.instancia.guardar(actualizado);
      if (mounted) _perfil = actualizado;
    }
    if (!mounted) return;
    setState(() {
      _pesoHC = peso;
      _grasaCorporal = grasa;
      _masaMagra = masaMagra;
    });
  }

  Future<void> _cargarCaloriasIngeridas() async {
    final comidas = await ServicioNutricion.instancia.obtenerDeFecha(
      DateTime.now(),
    );
    final total = comidas.fold<int>(0, (sum, c) => sum + c.calorias);
    if (!mounted) return;
    setState(() => _caloriasIngeridasHoy = total);
  }

  Future<void> _cargarCaloriasEjercicio() async {
    final kcal = await ServicioRegistros.instancia.kcalEjercicioHoy();
    if (!mounted) return;
    setState(() => _caloriasQuemadasEjercicio = kcal);
  }

  Future<void> _abrirNutricion() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaginaNutricion()),
    );
    await _cargarCaloriasIngeridas();
  }

  Future<void> _abrirPerfil() async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaginaPerfil()),
    );
    if (cambio == true) {
      await _cargarPerfil();
    }
  }

  Future<void> _abrirProgreso() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaginaMiProgreso()),
    );
  }

  Future<void> _iniciarPasos() async {
    final disponible = await ServicioPasos.instancia.healthConnectDisponible();
    if (!mounted) return;
    if (!disponible) return;
    final ya = await ServicioPasos.instancia.yaAutorizado();
    if (!mounted) return;
    if (ya) {
      setState(() => _pasosConectado = true);
      await _cargarPasos();
    } else {
      setState(() => _pasosConectado = false);
      _recalcularKcalPasos();
    }
  }

  Future<void> _cargarPasos() async {
    final pasos = await ServicioPasos.instancia.pasosHoy();
    if (!mounted) return;
    setState(() => _pasosHoy = pasos);
    _recalcularKcalPasos();
    if (pasos > 0 && _perfil != null) {
      final kcal = _calcularKcalPasos(pasos);
      await ServicioRegistros.instancia.guardarPasos(DateTime.now(), pasos, kcal);
    }
  }

  int _calcularKcalPasos(int pasos) {
    final perfil = _perfil;
    if (perfil == null) return 0;
    final alturaM = perfil.altura / 100.0;
    final strideM = perfil.sexo.name == 'masculino'
        ? 0.415 * alturaM
        : 0.413 * alturaM;
    final distanciaKm = (pasos * strideM) / 1000.0;
    return (distanciaKm * perfil.peso * 0.57).round();
  }

  void _recalcularKcalPasos() {
    final nuevo = _pasosConectado ? _calcularKcalPasos(_pasosHoy) : 0;
    if (nuevo != _caloriasQuemadasPasosCache) {
      _caloriasQuemadasPasosCache = nuevo;
      if (mounted) setState(() {});
    }
  }

  Future<void> _solicitarPasos() async {
    if (!mounted) return;
    final disponible = await ServicioPasos.instancia.healthConnectDisponible();
    if (!mounted) return;
    if (!disponible) {
      final instalar = await _mostrarDialogoInstalarHealthConnect();
      if (instalar == true) {
        await ServicioPasos.instancia.instalarHealthConnect();
      }
      return;
    }
    final entendido = await _mostrarDialogoExplicacion();
    if (!entendido) return;
    final ok = await ServicioPasos.instancia.solicitarPermisos();
    if (!mounted) return;
    if (ok) {
      setState(() => _pasosConectado = true);
      await _cargarPasos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pasos conectados'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _pasosConectado = false);
      _recalcularKcalPasos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se concedieron permisos. Vuelve a pulsar la tarjeta e inténtalo de nuevo.',
          ),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _mostrarDialogoExplicacion() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColoresApp.tarjeta,
        title: const Text('Conectar pasos'),
        content: const Text(
          'Android abrirá un diálogo del sistema pidiendo permiso de "Pasos".\n\n'
          'Pulsa "Permitir" en la pantalla que se abra.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  Future<bool?> _mostrarDialogoInstalarHealthConnect() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColoresApp.tarjeta,
        title: const Text('Falta Health Connect'),
        content: const Text(
          'Para leer los pasos de Google Fit, tu móvil necesita la app '
          '"Health Connect" (de Google, gratis, oficial).\n\n'
          'Te abriré la Play Store para que la instales. Cuando termine, '
          'vuelve a tocar la tarjeta de pasos.',
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

  int get _tmb {
    final perfil = _perfil;
    if (perfil == null) return 2000;

    if (_masaMagra != null && _masaMagra! > 0) {
      return (370 + 21.6 * _masaMagra!).round();
    }

    if (_grasaCorporal != null && _grasaCorporal! > 0 && _pesoHC != null && _pesoHC! > 0) {
      final masaMagraCalc = _pesoHC! * (1 - _grasaCorporal! / 100);
      return (370 + 21.6 * masaMagraCalc).round();
    }

    if (_pesoHC != null && _pesoHC! > 0 && _pesoHC != perfil.peso) {
      final base = 10.0 * _pesoHC! + 6.25 * perfil.altura - 5.0 * perfil.edad;
      final valor = perfil.sexo == Sexo.masculino ? base + 5 : base - 161;
      return valor.round();
    }

    return perfil.tmb;
  }

  int get _caloriasBasalesConsumidas {
    final ahora = DateTime.now();
    final minutos = ahora.hour * 60 + ahora.minute;
    return (_tmb * minutos / (24 * 60)).round();
  }

  int get _caloriasQuemadasPasos => _caloriasQuemadasPasosCache;

  int get _balanceEnergetico {
    return (_caloriasBasalesConsumidas +
        _caloriasQuemadasEjercicio +
        _caloriasQuemadasPasos) -
        _caloriasIngeridasHoy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Encabezado(),
                    const SizedBox(height: 18),
                    _Saludo(nombre: _perfil?.nombre ?? 'amigo'),
                    const SizedBox(height: 18),
                    _FilaEstadisticas(
                      tmb: _tmb,
                      basalesConsumidas: _caloriasBasalesConsumidas,
                      balance: _balanceEnergetico,
                      pasos: _pasosHoy,
                      pasosConectado: _pasosConectado,
                      metaPasos: _metaPasosDiaria,
                      alPulsarCalorias: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PaginaInfoCaloriasBasales(),
                          ),
                        );
                      },
                      alPulsarBalance: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaginaInfoBalance(
                              pasosHoy: _pasosHoy,
                              pasosConectado: _pasosConectado,
                              tmb: _tmb,
                            ),
                          ),
                        );
                      },
                      alPulsarPasos: _solicitarPasos,
                    ),
                    const SizedBox(height: 18),
                    _CuadriculaFunciones(
                      caloriasIngeridas: _caloriasIngeridasHoy,
                      alAbrirProgreso: _abrirProgreso,
                      alAbrirNutricion: _abrirNutricion,
                      alAbrirPerfil: _abrirPerfil,
                      alAbrirEntrenamientos: _cargarCaloriasEjercicio,
                    ),
                    const SizedBox(height: 18),
                    const TarjetaSesion(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const BarraNavegacion(),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Evolve',
          style: TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaginaConfiguracionGroq()),
          ),
          child: const _IconoRedondo(icono: Icons.tune_rounded),
        ),
        const SizedBox(width: 10),
        const _Avatar(),
      ],
    );
  }
}

class _IconoRedondo extends StatelessWidget {
  const _IconoRedondo({required this.icono});

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icono, color: ColoresApp.textoPrimario, size: 20),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: ColoresApp.acentoGradiente1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Saludo extends StatelessWidget {
  const _Saludo({required this.nombre});
  final String nombre;

  String _fechaActual(BuildContext context) {
    final fecha = DateTime.now();
    final base = DateFormat("EEEE, d 'de' MMMM", 'es').format(fecha);
    return base[0].toUpperCase() + base.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '¡Hola, $nombre!',
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Text('⚡', style: TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hoy es ${_fechaActual(context)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _FilaEstadisticas extends StatelessWidget {
  const _FilaEstadisticas({
    required this.tmb,
    required this.basalesConsumidas,
    required this.balance,
    required this.pasos,
    required this.pasosConectado,
    required this.metaPasos,
    required this.alPulsarCalorias,
    required this.alPulsarBalance,
    required this.alPulsarPasos,
  });
  final int tmb;
  final int basalesConsumidas;
  final int balance;
  final int pasos;
  final bool pasosConectado;
  final int metaPasos;
  final VoidCallback alPulsarCalorias;
  final VoidCallback alPulsarBalance;
  final VoidCallback alPulsarPasos;

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.decimalPattern('es');
    final positivo = balance >= 0;
    final balanceTexto = positivo
        ? '+${formato.format(balance)}'
        : '−${formato.format(balance.abs())}';
    final colorBalance =
        positivo ? ColoresApp.acentoVerde : ColoresApp.acentoCalor;
    final detalleBalance = positivo ? 'déficit' : 'superávit';

    final Widget tarjetaPasos = pasosConectado
        ? TarjetaEstadistica(
            icono: Icons.directions_walk_rounded,
            colorIcono: ColoresApp.acentoGradiente1,
            valor: formato.format(pasos),
            etiqueta: 'Pasos',
            detalle: '${formato.format(pasos)} / ${formato.format(metaPasos)}',
          )
        : TarjetaEstadistica(
            icono: Icons.directions_walk_rounded,
            colorIcono: ColoresApp.acentoGradiente1,
            valor: '—',
            etiqueta: 'Pasos',
            detalle: 'Toca para conectar',
            colorValor: ColoresApp.textoSecundario,
            alPulsar: alPulsarPasos,
          );

    return Row(
      children: [
        Expanded(child: tarjetaPasos),
        const SizedBox(width: 10),
        Expanded(
          child: TarjetaEstadistica(
            icono: Icons.local_fire_department_rounded,
            colorIcono: ColoresApp.acentoCalor,
            valor: '$basalesConsumidas',
            etiqueta: 'Calorías',
            detalle: '$basalesConsumidas / $tmb kcal',
            alPulsar: alPulsarCalorias,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TarjetaEstadistica(
            icono: Icons.balance_rounded,
            colorIcono: ColoresApp.acentoTeal,
            valor: balanceTexto,
            etiqueta: 'Balance',
            detalle: detalleBalance,
            colorValor: colorBalance,
            alPulsar: alPulsarBalance,
          ),
        ),
      ],
    );
  }
}

class _CuadriculaFunciones extends StatelessWidget {
  const _CuadriculaFunciones({
    required this.caloriasIngeridas,
    required this.alAbrirProgreso,
    required this.alAbrirNutricion,
    required this.alAbrirPerfil,
    required this.alAbrirEntrenamientos,
  });

  final int caloriasIngeridas;
  final Future<void> Function() alAbrirProgreso;
  final Future<void> Function() alAbrirNutricion;
  final Future<void> Function() alAbrirPerfil;
  final Future<void> Function() alAbrirEntrenamientos;

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.decimalPattern('es');
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        TarjetaFuncion(
          icono: Icons.trending_up_rounded,
          colorIcono: ColoresApp.acentoGradiente1,
          titulo: 'Mi Progreso',
          descripcion: 'Mira tendencias, fotos, guía',
          alPulsar: () => alAbrirProgreso(),
        ),
        TarjetaFuncion(
          icono: Icons.fitness_center_rounded,
          colorIcono: ColoresApp.acentoCalor,
          titulo: 'Entrenamientos',
          descripcion: '3 rutinas disponibles',
          alPulsar: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PaginaListaRutinas(),
              ),
            );
            alAbrirEntrenamientos();
          },
        ),
        const TarjetaFuncion(
          icono: Icons.calendar_today_rounded,
          colorIcono: ColoresApp.acentoVerde,
          titulo: 'Programas',
          descripcion: 'Mira por tu salud',
        ),
        TarjetaFuncion(
          icono: Icons.restaurant_rounded,
          colorIcono: ColoresApp.acentoTeal,
          titulo: 'Nutrición',
          destacado: '${formato.format(caloriasIngeridas)} kcal',
          alPulsar: () => alAbrirNutricion(),
        ),
        const TarjetaFuncion(
          icono: Icons.groups_rounded,
          colorIcono: ColoresApp.acentoMorado,
          titulo: 'Comunidad',
          descripcion: 'Desafíos, amigos',
        ),
        TarjetaFuncion(
          icono: Icons.person_rounded,
          colorIcono: ColoresApp.acentoGradiente1,
          titulo: 'Perfil',
          descripcion: 'Tus datos, TMB',
          alPulsar: () => alAbrirPerfil(),
        ),
        TarjetaFuncion(
          icono: Icons.bug_report_rounded,
          colorIcono: ColoresApp.textoSecundario,
          titulo: 'Diagnóstico HC',
          descripcion: 'Datos Insmart Health',
          alPulsar: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaginaDiagnosticoHealth()),
            );
          },
        ),
      ],
    );
  }
}
