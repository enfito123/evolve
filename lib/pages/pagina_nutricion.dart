import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../modelos/comida.dart';
import '../modelos/estimacion_ia.dart';
import '../servicios/servicio_claves.dart';
import '../servicios/servicio_groq.dart';
import '../servicios/servicio_nutricion.dart';
import '../theme/colores_app.dart';
import 'pagina_configuracion_groq.dart';

class PaginaNutricion extends StatefulWidget {
  const PaginaNutricion({super.key});

  @override
  State<PaginaNutricion> createState() => _EstadoPaginaNutricion();
}

class _EstadoPaginaNutricion extends State<PaginaNutricion> {
  final TextEditingController _controladorEntrada = TextEditingController();
  final ServicioNutricion _servicio = ServicioNutricion.instancia;
  final ServicioGroq _groq = ServicioGroq();

  List<Comida> _comidas = [];
  bool _cargando = true;
  bool _analizando = false;
  bool _claveConfigurada = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _controladorEntrada.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    final clave = await ServicioClaves.instancia.obtenerClaveGroq();
    final lista = await _servicio.obtenerDeFecha(DateTime.now());
    if (!mounted) return;
    setState(() {
      _claveConfigurada = clave.isNotEmpty;
      _comidas = lista;
      _cargando = false;
    });
  }

  Future<void> _abrirConfiguracion() async {
    final guardo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaginaConfiguracionGroq()),
    );
    if (guardo == true) {
      await _inicializar();
    }
  }

  Future<void> _analizar() async {
    final texto = _controladorEntrada.text.trim();
    if (texto.isEmpty) return;

    setState(() => _analizando = true);
    HapticFeedback.lightImpact();

    try {
      final estimaciones = await _groq.estimar(texto);
      if (!mounted) return;

      if (estimaciones.isEmpty) {
        _mostrarAviso('La IA no pudo identificar alimentos en: "$texto"');
        return;
      }

      final resultados = await _mostrarSheetResultados(texto, estimaciones);
      if (resultados == null || resultados.isEmpty) return;

      for (final est in resultados) {
        await _servicio.guardar(Comida(
          nombre: est.cantidad > 1
              ? '${est.cantidad} × ${est.nombre}'
              : est.nombre,
          calorias: est.caloriasTotales,
          fechaCreacion: DateTime.now(),
        ));
      }
      _controladorEntrada.clear();
      await _inicializar();
      if (mounted) {
        _mostrarExito(resultados.length == 1
            ? 'Guardado: ${resultados.first.nombre}'
            : 'Guardado: ${resultados.length} alimentos');
      }
    } on ErrorGroq catch (e) {
      if (mounted) _mostrarAviso(e.mensaje);
    } catch (e) {
      if (mounted) _mostrarAviso('No se pudo conectar con la IA. Revisa tu internet.');
    } finally {
      if (mounted) setState(() => _analizando = false);
    }
  }

  Future<List<EstimacionIa>?> _mostrarSheetResultados(String frase, List<EstimacionIa> estimaciones) {
    return showModalBottomSheet<List<EstimacionIa>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColoresApp.fondo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SheetResultados(frase: frase, estimacionesIniciales: estimaciones),
    );
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
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : !_claveConfigurada
                ? _EstadoVacioConectar(onConectar: _abrirConfiguracion)
                : Column(
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
                        controlador: _controladorEntrada,
                        procesando: _analizando,
                        alEnviar: _analizar,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _ListaComidas(
                          comidas: _comidas,
                          alEliminar: _eliminarComida,
                        ),
                      ),
                      _PieTotal(total: _totalCalorias),
                    ],
                  ),
      ),
    );
  }
}

class _EstadoVacioConectar extends StatelessWidget {
  const _EstadoVacioConectar({required this.onConectar});
  final Future<void> Function() onConectar;

  Future<void> _abrirGroq() async {
    final uri = Uri.parse('https://console.groq.com/keys');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
              'Conecta con Groq',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Para interpretar tus comidas con IA necesitas conectar tu cuenta de Groq. Es gratis y solo se hace una vez.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConectar,
                icon: const Icon(Icons.bolt_rounded),
                label: const Text(
                  'CONECTAR',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.acentoPrimario,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _abrirGroq,
              icon: const Icon(Icons.open_in_new_rounded, color: ColoresApp.acentoTeal, size: 16),
              label: const Text(
                'No tengo clave, ¿cómo la consigo?',
                style: TextStyle(color: ColoresApp.acentoTeal, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
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
            const Icon(Icons.restaurant_rounded, color: ColoresApp.acentoTeal, size: 22),
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
                icon: const Icon(Icons.send_rounded,
                    color: ColoresApp.acentoPrimario, size: 24),
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

class _FilaResultado {
  _FilaResultado({String nombre = '', String cantidad = '1', String calorias = '0'})
      : nombreCtrl = TextEditingController(text: nombre),
        cantidadCtrl = TextEditingController(text: cantidad),
        caloriasCtrl = TextEditingController(text: calorias);
  final TextEditingController nombreCtrl;
  final TextEditingController cantidadCtrl;
  final TextEditingController caloriasCtrl;
  void dispose() {
    nombreCtrl.dispose();
    cantidadCtrl.dispose();
    caloriasCtrl.dispose();
  }
}

class _SheetResultados extends StatefulWidget {
  const _SheetResultados({required this.frase, required this.estimacionesIniciales});
  final String frase;
  final List<EstimacionIa> estimacionesIniciales;

  @override
  State<_SheetResultados> createState() => _EstadoSheetResultados();
}

class _EstadoSheetResultados extends State<_SheetResultados> {
  late List<_FilaResultado> _filas;

  @override
  void initState() {
    super.initState();
    _filas = widget.estimacionesIniciales
        .map((e) => _FilaResultado(
              nombre: e.nombre,
              cantidad: e.cantidad.toString(),
              calorias: e.caloriasTotales.toString(),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final f in _filas) {
      f.dispose();
    }
    super.dispose();
  }

  void _agregarFila() {
    setState(() => _filas.add(_FilaResultado()));
  }

  void _eliminarFila(int indice) {
    setState(() {
      _filas[indice].dispose();
      _filas.removeAt(indice);
    });
  }

  void _guardar() {
    final estimaciones = <EstimacionIa>[];
    for (final fila in _filas) {
      final nombre = fila.nombreCtrl.text.trim();
      final cantidad = int.tryParse(fila.cantidadCtrl.text.trim()) ?? 0;
      final calorias = int.tryParse(fila.caloriasCtrl.text.trim()) ?? 0;
      if (nombre.isNotEmpty && cantidad > 0 && calorias > 0) {
        estimaciones.add(EstimacionIa(
          nombre: nombre,
          cantidad: cantidad,
          caloriasTotales: calorias,
        ));
      }
    }
    Navigator.of(context).pop(estimaciones.isEmpty ? null : estimaciones);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                'Comidas detectadas',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                'Dijiste: "${widget.frase}"',
                style: const TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                shrinkWrap: true,
                itemCount: _filas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, indice) {
                  return _TarjetaFila(
                    fila: _filas[indice],
                    onEliminar: () => _eliminarFila(indice),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _agregarFila,
                  icon: const Icon(Icons.add_rounded, color: ColoresApp.acentoPrimario, size: 18),
                  label: const Text(
                    'Añadir otro',
                    style: TextStyle(color: ColoresApp.acentoPrimario, fontSize: 13),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: ColoresApp.fondo,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresApp.acentoPrimario,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Guardar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
}

class _TarjetaFila extends StatelessWidget {
  const _TarjetaFila({required this.fila, required this.onEliminar});
  final _FilaResultado fila;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, color: ColoresApp.acentoTeal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: fila.nombreCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Nombre',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                onPressed: onEliminar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.numbers_rounded, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: fila.cantidadCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 16, color: Colors.white24),
              const SizedBox(width: 8),
              const Icon(Icons.local_fire_department_rounded, color: ColoresApp.acentoPrimario, size: 16),
              const SizedBox(width: 6),
              const Text('kcal', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: fila.caloriasCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
