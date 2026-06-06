import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../modelos/comida.dart';
import '../servicios/servicio_claves.dart';
import '../servicios/servicio_nutricion.dart';
import '../servicios/servicio_ia.dart';
import '../theme/colores_app.dart';
import 'pagina_configuracion_gemini.dart';

class PaginaNutricion extends StatefulWidget {
  const PaginaNutricion({super.key});

  @override
  State<PaginaNutricion> createState() => _EstadoPaginaNutricion();
}

class _EstadoPaginaNutricion extends State<PaginaNutricion> with WidgetsBindingObserver {
  final TextEditingController _controladorEntrada = TextEditingController();
  final ServicioNutricion _servicio = ServicioNutricion.instancia;
  final ServicioIa _ia = ServicioIa();

  List<Comida> _comidas = [];
  bool _cargando = true;
  bool _iaConfigurada = false;
  bool _procesando = false;
  bool _esperandoRegreso = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inicializar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controladorEntrada.dispose();
    _ia.cerrar();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed && _esperandoRegreso) {
      _esperandoRegreso = false;
      _intentarAutoConectar();
    }
  }

  Future<void> _inicializar() async {
    final conectada = await _ia.claveConfigurada();
    final lista = await _servicio.obtenerDeFecha(DateTime.now());
    if (!mounted) return;
    setState(() {
      _iaConfigurada = conectada;
      _comidas = lista;
      _cargando = false;
    });
  }

  Future<void> _intentarAutoConectar() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = datos?.text?.trim() ?? '';
    if (!texto.startsWith('AIza') || texto.length < 30) {
      if (!mounted) return;
      _mostrarAviso('No detecté ninguna clave de Gemini en el portapapeles. Pégala manualmente.');
      return;
    }
    final funciona = await _ia.probarClave(texto);
    if (!funciona) {
      if (!mounted) return;
      _mostrarAviso('La clave del portapapeles no funciona. Inténtalo de nuevo.');
      return;
    }
    await ServicioClaves.instancia.guardarClaveGemini(texto);
    if (!mounted) return;
    setState(() => _iaConfigurada = true);
    _mostrarExito('¡Conectado a Gemini correctamente!');
  }

  Future<void> _abrirConfiguracion({String? claveActual}) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaginaConfiguracionGemini(claveInicial: claveActual),
      ),
    );
    if (resultado == true) {
      await _inicializar();
    }
  }

  Future<void> _agregarComida() async {
    final texto = _controladorEntrada.text.trim();
    if (texto.isEmpty) return;

    setState(() => _procesando = true);

    try {
      final estimaciones = await _ia.estimarCalorias(texto);
      for (final est in estimaciones) {
        final comida = Comida(
          nombre: est.nombre,
          calorias: est.calorias,
          fechaCreacion: DateTime.now(),
        );
        await _servicio.guardar(comida);
      }
      _controladorEntrada.clear();
      await _inicializar();
    } on FaltaClaveGemini {
      if (mounted) _mostrarAviso('Conecta Gemini primero');
    } on ErrorIa catch (e) {
      if (mounted) _mostrarAviso('La IA no pudo procesar la comida (${e.codigo})');
    } catch (e) {
      if (mounted) _mostrarAviso('No se pudo conectar con la IA. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _eliminarComida(Comida comida) async {
    if (comida.id == null) return;
    await _servicio.eliminar(comida.id!);
    await _inicializar();
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: ColoresApp.acentoVerde),
    );
  }

  int get _totalCalorias => _comidas.fold(0, (suma, c) => suma + c.calorias);

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        title: const Text('Nutrición'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _iaConfigurada ? Icons.tune_rounded : Icons.bolt_rounded,
              color: _iaConfigurada ? Colors.white : ColoresApp.acentoPrimario,
            ),
            onPressed: () async {
              if (_iaConfigurada) {
                await _abrirConfiguracion();
              } else {
                setState(() => _esperandoRegreso = true);
                await _abrirConfiguracion();
              }
            },
            tooltip: _iaConfigurada ? 'Ajustes' : 'Conectar con Gemini',
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : !_iaConfigurada
                ? _EstadoVacioConectar(onConectar: _abrirConfiguracion)
                : _ContenidoNutricion(
                    fecha: fecha,
                    controlador: _controladorEntrada,
                    procesando: _procesando,
                    comidas: _comidas,
                    total: _totalCalorias,
                    alAgregar: _agregarComida,
                    alEliminar: _eliminarComida,
                  ),
      ),
    );
  }
}

class _EstadoVacioConectar extends StatelessWidget {
  const _EstadoVacioConectar({required this.onConectar});

  final Future<void> Function({String? claveActual}) onConectar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColoresApp.acentoPrimario.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: ColoresApp.acentoPrimario,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Conecta con Gemini',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Para calcular las calorías de tus comidas necesitas conectar tu cuenta de Gemini. Es gratis y solo se hace una vez.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onConectar(),
                icon: const Icon(Icons.bolt_rounded),
                label: const Text(
                  'CONECTAR',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.acentoPrimario,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoNutricion extends StatelessWidget {
  const _ContenidoNutricion({
    required this.fecha,
    required this.controlador,
    required this.procesando,
    required this.comidas,
    required this.total,
    required this.alAgregar,
    required this.alEliminar,
  });

  final String fecha;
  final TextEditingController controlador;
  final bool procesando;
  final List<Comida> comidas;
  final int total;
  final Future<void> Function() alAgregar;
  final Future<void> Function(Comida) alEliminar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              fecha[0].toUpperCase() + fecha.substring(1),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        _SeccionEntrada(
          controlador: controlador,
          procesando: procesando,
          alEnviar: alAgregar,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _ListaComidas(
            comidas: comidas,
            alEliminar: alEliminar,
          ),
        ),
        _PieTotal(total: total),
      ],
    );
  }
}

class _SeccionEntrada extends StatelessWidget {
  const _SeccionEntrada({
    required this.controlador,
    required this.procesando,
    required this.alEnviar,
  });

  final TextEditingController controlador;
  final bool procesando;
  final Future<void> Function() alEnviar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: ColoresApp.tarjeta,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant_rounded,
                color: ColoresApp.acentoTeal, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controlador,
                enabled: !procesando,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: '¿Qué has comido? Ej: 2 tostadas con aguacate',
                  hintStyle: TextStyle(color: ColoresApp.textoSecundario),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => alEnviar(),
              ),
            ),
            if (procesando)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.add_circle_rounded,
                    color: ColoresApp.acentoPrimario, size: 28),
                onPressed: alEnviar,
              ),
          ],
        ),
      ),
    );
  }
}

class _ListaComidas extends StatelessWidget {
  const _ListaComidas({required this.comidas, required this.alEliminar});

  final List<Comida> comidas;
  final Future<void> Function(Comida) alEliminar;

  @override
  Widget build(BuildContext context) {
    if (comidas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_food_rounded,
                size: 56, color: ColoresApp.textoSecundario.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Aún no has registrado ninguna comida',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: comidas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, indice) {
        final comida = comidas[indice];
        return Dismissible(
          key: ValueKey(comida.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => alEliminar(comida),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColoresApp.tarjeta,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    comida.nombre,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColoresApp.acentoTeal.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${comida.calorias} kcal',
                    style: const TextStyle(
                      color: ColoresApp.acentoTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PieTotal extends StatelessWidget {
  const _PieTotal({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.tarjetaSutil,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColoresApp.acentoPrimario.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL DEL DÍA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total kcal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColoresApp.acentoPrimario.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: ColoresApp.acentoPrimario,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
