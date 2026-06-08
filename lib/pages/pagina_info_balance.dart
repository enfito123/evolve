import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../modelos/perfil.dart';
import '../servicios/servicio_nutricion.dart';
import '../servicios/servicio_perfil.dart';
import '../servicios/servicio_registros.dart';
import '../theme/colores_app.dart';

class PaginaInfoBalance extends StatefulWidget {
  const PaginaInfoBalance({
    super.key,
    this.pasosHoy = 0,
    this.pasosConectado = false,
    required this.tmb,
  });

  final int pasosHoy;
  final bool pasosConectado;
  final int tmb;

  @override
  State<PaginaInfoBalance> createState() => _EstadoPaginaInfoBalance();
}

class _EstadoPaginaInfoBalance extends State<PaginaInfoBalance> {
  int _ejercicio = 0;

  int _tmb = 2000;
  int _ingeridasHoy = 0;
  int _basalesConsumidas = 0;
  ModeloPerfil? _perfil;
  bool _cargando = true;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _cargar();
    _temporizador = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    final perfil = await ServicioPerfil.instancia.cargar();
    final tmb = widget.tmb;
    final comidas =
        await ServicioNutricion.instancia.obtenerDeFecha(DateTime.now());
    final total = comidas.fold<int>(0, (sum, c) => sum + c.calorias);
    final ahora = DateTime.now();
    final minutos = ahora.hour * 60 + ahora.minute;
    final basales = (tmb * minutos / (24 * 60)).round();
    final ejercicio = await ServicioRegistros.instancia.kcalEjercicioHoy();

    if (!mounted) return;
    setState(() {
      _perfil = perfil;
      _tmb = tmb;
      _ingeridasHoy = total;
      _basalesConsumidas = basales;
      _ejercicio = ejercicio;
      _cargando = false;
    });
  }

  int get _kcalCaminando {
    if (!widget.pasosConectado || _perfil == null) return 0;
    final alturaM = _perfil!.altura / 100.0;
    final strideM = _perfil!.sexo.name == 'masculino'
        ? 0.415 * alturaM
        : 0.413 * alturaM;
    final distanciaKm = (widget.pasosHoy * strideM) / 1000.0;
    return (distanciaKm * _perfil!.peso * 0.57).round();
  }

  int get _kcalQuemadas =>
      _basalesConsumidas + _kcalCaminando + _ejercicio;

  int get _balance => _kcalQuemadas - _ingeridasHoy;

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: ColoresApp.fondo,
        appBar: AppBar(
          backgroundColor: ColoresApp.fondo,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Balance calórico'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ColoresApp.acentoCalor),
        ),
      );
    }

    final positivo = _balance >= 0;
    final color = positivo ? ColoresApp.acentoVerde : ColoresApp.acentoCalor;
    final estado = positivo ? 'déficit' : 'superávit';
    final formato = NumberFormat.decimalPattern('es');
    final balanceTexto = positivo
        ? '+${formato.format(_balance)}'
        : '−${formato.format(_balance.abs())}';

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Balance calórico'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EstadoHero(
                balance: _balance,
                color: color,
                estado: estado,
                balanceTexto: balanceTexto,
                kcalQuemadas: _kcalQuemadas,
                kcalIngeridas: _ingeridasHoy,
                formato: formato,
              ),
              const SizedBox(height: 16),
              const _SeccionInfo(
                icono: Icons.question_mark_rounded,
                colorIcono: ColoresApp.acentoGradiente1,
                titulo: '¿Qué es?',
                texto:
                    'El balance calórico compara la energía que gastas con la que ingieres. Te dice si hoy vas por encima o por debajo de tu metabolismo basal.\n\n'
                    'En Evolve: Balance = (Basal + Caminando + Ejercicio) − Ingeridas.',
              ),
              const SizedBox(height: 12),
              _SeccionGrafico(
                tmb: _tmb,
                basal: _basalesConsumidas,
                caminando: _kcalCaminando,
                ejercicio: _ejercicio,
                ingeridas: _ingeridasHoy,
                pasosHoy: widget.pasosHoy,
                pasosConectado: widget.pasosConectado,
                formato: formato,
              ),
              const SizedBox(height: 12),
              const _SeccionInfo(
                icono: Icons.calculate_rounded,
                colorIcono: ColoresApp.acentoTeal,
                titulo: '¿Cómo se interpreta?',
                texto:
                    'Si el balance es positivo (verde), estás en déficit: tu cuerpo ha gastado más energía de la que has repuesto. Es el terreno donde se pierde peso.\n\n'
                    'Si es negativo (naranja), estás en superávit: has comido más de lo que tu cuerpo ha quemado. Es donde se gana peso.\n\n'
                    'Para mantenerte, busca un balance cercano a cero al final del día.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoHero extends StatelessWidget {
  const _EstadoHero({
    required this.balance,
    required this.color,
    required this.estado,
    required this.balanceTexto,
    required this.kcalQuemadas,
    required this.kcalIngeridas,
    required this.formato,
  });

  final int balance;
  final Color color;
  final String estado;
  final String balanceTexto;
  final int kcalQuemadas;
  final int kcalIngeridas;
  final NumberFormat formato;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.05),
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
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.balance_rounded, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estado.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      balanceTexto,
                      style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'kcal de balance',
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
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: color.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _dato(
                  'Quemadas',
                  kcalQuemadas,
                  ColoresApp.acentoCalor,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: color.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _dato(
                  'Ingeridas',
                  kcalIngeridas,
                  ColoresApp.acentoTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dato(String etiqueta, int valor, Color c) {
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
          '${formato.format(valor)} kcal',
          style: const TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SeccionInfo extends StatelessWidget {
  const _SeccionInfo({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.texto,
  });

  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String texto;

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
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            texto,
            style: const TextStyle(
              color: ColoresApp.textoPrimario,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionGrafico extends StatelessWidget {
  const _SeccionGrafico({
    required this.tmb,
    required this.basal,
    required this.caminando,
    required this.ejercicio,
    required this.ingeridas,
    required this.pasosHoy,
    required this.pasosConectado,
    required this.formato,
  });

  final int tmb;
  final int basal;
  final int caminando;
  final int ejercicio;
  final int ingeridas;
  final int pasosHoy;
  final bool pasosConectado;
  final NumberFormat formato;

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
                  color: ColoresApp.acentoMorado.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: ColoresApp.acentoMorado,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tu día en calorías',
                  style: TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _GraficoBarras(
            tmb: tmb,
            basal: basal,
            caminando: caminando,
            ejercicio: ejercicio,
            ingeridas: ingeridas,
            formato: formato,
          ),
          const SizedBox(height: 18),
          const Divider(color: ColoresApp.tarjetaSutil, height: 1),
          const SizedBox(height: 14),
          _ListaComponentes(
            basal: basal,
            caminando: caminando,
            ejercicio: ejercicio,
            ingeridas: ingeridas,
            pasosHoy: pasosHoy,
            pasosConectado: pasosConectado,
            formato: formato,
          ),
        ],
      ),
    );
  }
}

class _GraficoBarras extends StatelessWidget {
  const _GraficoBarras({
    required this.tmb,
    required this.basal,
    required this.caminando,
    required this.ejercicio,
    required this.ingeridas,
    required this.formato,
  });

  final int tmb;
  final int basal;
  final int caminando;
  final int ejercicio;
  final int ingeridas;
  final NumberFormat formato;

  @override
  Widget build(BuildContext context) {
    final maximo = [
      tmb,
      basal,
      caminando,
      ejercicio,
      ingeridas,
    ].reduce((a, b) => a > b ? a : b);
    final escala = (maximo * 1.15).ceilToDouble();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Barra(
                etiqueta: 'Ingeridas',
                valor: ingeridas,
                escala: escala,
                color: ColoresApp.acentoTeal,
                formato: formato,
              ),
              _Barra(
                etiqueta: 'Basal',
                valor: basal,
                escala: escala,
                color: ColoresApp.acentoCalor,
                formato: formato,
              ),
              _Barra(
                etiqueta: 'Caminar',
                valor: caminando,
                escala: escala,
                color: ColoresApp.acentoVerde,
                formato: formato,
              ),
              _Barra(
                etiqueta: 'Ejercicio',
                valor: ejercicio,
                escala: escala,
                color: ColoresApp.acentoMorado,
                formato: formato,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text(
              'TMB',
              style: TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '→',
              style: TextStyle(
                color: ColoresApp.acentoGradiente1,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${formato.format(tmb)} kcal',
              style: const TextStyle(
                color: ColoresApp.acentoGradiente1,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Text(
              'meta diaria',
              style: TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.etiqueta,
    required this.valor,
    required this.escala,
    required this.color,
    required this.formato,
  });

  final String etiqueta;
  final int valor;
  final double escala;
  final Color color;
  final NumberFormat formato;

  @override
  Widget build(BuildContext context) {
    final altura = escala == 0 ? 0.0 : (valor / escala) * 130.0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              formato.format(valor),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: ColoresApp.tarjetaSutil,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  height: altura,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              etiqueta,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaComponentes extends StatelessWidget {
  const _ListaComponentes({
    required this.basal,
    required this.caminando,
    required this.ejercicio,
    required this.ingeridas,
    required this.pasosHoy,
    required this.pasosConectado,
    required this.formato,
  });

  final int basal;
  final int caminando;
  final int ejercicio;
  final int ingeridas;
  final int pasosHoy;
  final bool pasosConectado;
  final NumberFormat formato;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilaComponente(
          icono: Icons.local_dining_rounded,
          color: ColoresApp.acentoTeal,
          etiqueta: 'Ingeridas',
          valor: ingeridas,
          subtitulo: 'lo que has comido',
          formato: formato,
        ),
        const SizedBox(height: 10),
        _FilaComponente(
          icono: Icons.local_fire_department_rounded,
          color: ColoresApp.acentoCalor,
          etiqueta: 'Calorías basales',
          valor: basal,
          subtitulo: 'metabolismo en reposo',
          formato: formato,
        ),
        const SizedBox(height: 10),
        _FilaComponente(
          icono: Icons.directions_walk_rounded,
          color: ColoresApp.acentoVerde,
          etiqueta: 'Caminando',
          valor: caminando,
          subtitulo: pasosConectado
              ? '${formato.format(pasosHoy)} pasos hoy'
              : 'sin pasos conectados',
          formato: formato,
        ),
        const SizedBox(height: 10),
        _FilaEjercicioDesplegable(
          ejercicio: ejercicio,
          formato: formato,
        ),
      ],
    );
  }
}

class _FilaEjercicioDesplegable extends StatefulWidget {
  const _FilaEjercicioDesplegable({
    required this.ejercicio,
    required this.formato,
  });

  final int ejercicio;
  final NumberFormat formato;

  @override
  State<_FilaEjercicioDesplegable> createState() => _EstadoFilaEjercicio();
}

class _EstadoFilaEjercicio extends State<_FilaEjercicioDesplegable> {
  bool _desplegado = false;
  List<Map<String, dynamic>> _detalle = [];
  bool _cargandoDetalle = false;

  Future<void> _toggle() async {
    if (_desplegado) {
      setState(() => _desplegado = false);
      return;
    }
    setState(() {
      _desplegado = true;
      _cargandoDetalle = true;
    });
    final detalle = await ServicioRegistros.instancia.ejerciciosHoyDetalle();
    if (!mounted) return;
    setState(() {
      _detalle = detalle;
      _cargandoDetalle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColoresApp.acentoMorado.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: ColoresApp.acentoMorado, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ejercicio',
                          style: TextStyle(
                            color: ColoresApp.textoPrimario,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.ejercicio > 0
                              ? '${widget.ejercicio} kcal quemadas'
                              : 'sin registros',
                          style: const TextStyle(
                            color: ColoresApp.textoSecundario,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.formato.format(widget.ejercicio),
                    style: const TextStyle(
                      color: ColoresApp.acentoMorado,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      color: ColoresApp.textoSecundario,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _desplegado
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: ColoresApp.textoSecundario,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_desplegado) ...[
            const Divider(color: ColoresApp.tarjetaSutil, height: 1, indent: 44),
            if (_cargandoDetalle)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColoresApp.acentoMorado,
                  ),
                ),
              )
            else if (_detalle.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay ejercicios registrados hoy',
                  style: TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              )
            else
              ..._detalle.map((e) => _FilaEjercicioDetalle(
                    nombre: e['nombre'] as String,
                    kcal: e['kcal'] as int,
                    formato: widget.formato,
                  )),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _FilaEjercicioDetalle extends StatelessWidget {
  const _FilaEjercicioDetalle({
    required this.nombre,
    required this.kcal,
    required this.formato,
  });

  final String nombre;
  final int kcal;
  final NumberFormat formato;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: ColoresApp.acentoMorado,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nombre,
              style: const TextStyle(
                color: ColoresApp.textoPrimario,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${formato.format(kcal)} kcal',
            style: const TextStyle(
              color: ColoresApp.acentoMorado,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaComponente extends StatelessWidget {
  const _FilaComponente({
    required this.icono,
    required this.color,
    required this.etiqueta,
    required this.valor,
    required this.subtitulo,
    required this.formato,
  });

  final IconData icono;
  final Color color;
  final String etiqueta;
  final int valor;
  final String subtitulo;
  final NumberFormat formato;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(
                  color: ColoresApp.textoPrimario,
                  fontSize: 13,
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
        Text(
          formato.format(valor),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'kcal',
          style: TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
