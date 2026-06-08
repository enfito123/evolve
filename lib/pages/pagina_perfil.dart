import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../modelos/perfil.dart';
import '../servicios/servicio_perfil.dart';
import '../servicios/servicio_salud.dart';
import '../theme/colores_app.dart';

class PaginaPerfil extends StatefulWidget {
  const PaginaPerfil({super.key});

  @override
  State<PaginaPerfil> createState() => _EstadoPaginaPerfil();
}

class _EstadoPaginaPerfil extends State<PaginaPerfil> {
  final _nombreCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();

  Sexo _sexo = Sexo.masculino;
  bool _cargando = true;
  bool _guardando = false;
  int? _tmbEnVivo;

  @override
  void initState() {
    super.initState();
    for (final c in [_nombreCtrl, _edadCtrl, _pesoCtrl, _alturaCtrl]) {
      c.addListener(_recalcular);
    }
    _cargar();
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _edadCtrl, _pesoCtrl, _alturaCtrl]) {
      c.removeListener(_recalcular);
      c.dispose();
    }
    super.dispose();
  }

  double? _masaMagraHC;
  double? _grasaCorporalHC;
  double? _pesoHC;

  Future<void> _cargar() async {
    final perfil = await ServicioPerfil.instancia.cargar();
    if (!mounted) return;
    if (perfil != null) {
      _nombreCtrl.text = perfil.nombre;
      _edadCtrl.text = perfil.edad.toString();
      _pesoCtrl.text = _formatearNumero(perfil.peso);
      _alturaCtrl.text = _formatearNumero(perfil.altura);
      _sexo = perfil.sexo;
    }
    setState(() => _cargando = false);
    _recalcular();
    _cargarComposicionHC();
  }

  Future<void> _cargarComposicionHC() async {
    final peso = await ServicioSalud.instancia.leerPesoActual();
    final grasa = await ServicioSalud.instancia.leerGrasaCorporal();
    final masaMagra = await ServicioSalud.instancia.leerMasaMagra();
    if (!mounted) return;
    setState(() {
      _pesoHC = peso;
      _grasaCorporalHC = grasa;
      _masaMagraHC = masaMagra;
    });
    _recalcular();
  }

  void _recalcular() {
    final edad = int.tryParse(_edadCtrl.text.trim());
    final peso = double.tryParse(_pesoCtrl.text.trim().replaceAll(',', '.'));
    final altura =
        double.tryParse(_alturaCtrl.text.trim().replaceAll(',', '.'));
    if (edad == null || peso == null || altura == null) {
      setState(() => _tmbEnVivo = null);
      return;
    }

    if (_masaMagraHC != null && _masaMagraHC! > 0) {
      setState(() => _tmbEnVivo = (370 + 21.6 * _masaMagraHC!).round());
      return;
    }

    if (_grasaCorporalHC != null && _grasaCorporalHC! > 0 && _pesoHC != null && _pesoHC! > 0) {
      final masaMagraCalc = _pesoHC! * (1 - _grasaCorporalHC! / 100);
      setState(() => _tmbEnVivo = (370 + 21.6 * masaMagraCalc).round());
      return;
    }

    final base = 10.0 * peso + 6.25 * altura - 5.0 * edad;
    final valor = _sexo == Sexo.masculino ? base + 5 : base - 161;
    setState(() => _tmbEnVivo = valor.round());
  }

  String _formatearNumero(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toString();
  }

  bool get _formularioValido {
    final nombre = _nombreCtrl.text.trim();
    final edad = int.tryParse(_edadCtrl.text.trim());
    final peso = double.tryParse(_pesoCtrl.text.trim().replaceAll(',', '.'));
    final altura =
        double.tryParse(_alturaCtrl.text.trim().replaceAll(',', '.'));
    return nombre.isNotEmpty &&
        edad != null &&
        edad > 0 &&
        peso != null &&
        peso > 0 &&
        altura != null &&
        altura > 0;
  }

  Future<void> _guardar() async {
    if (!_formularioValido || _guardando) return;
    final nombre = _nombreCtrl.text.trim();
    final edad = int.parse(_edadCtrl.text.trim());
    final peso =
        double.parse(_pesoCtrl.text.trim().replaceAll(',', '.'));
    final altura =
        double.parse(_alturaCtrl.text.trim().replaceAll(',', '.'));

    setState(() => _guardando = true);
    final perfil = ModeloPerfil(
      nombre: nombre,
      edad: edad,
      sexo: _sexo,
      peso: peso,
      altura: altura,
    );
    await ServicioPerfil.instancia.guardar(perfil);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  InputDecoration _dec(String label, String sufijo) => InputDecoration(
        labelText: label,
        suffixText: sufijo,
        labelStyle: const TextStyle(color: Colors.white54),
        suffixStyle:
            const TextStyle(color: Colors.white54, fontSize: 14),
        filled: true,
        fillColor: ColoresApp.tarjeta,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: ColoresApp.acentoPrimario, width: 1.5),
        ),
      );

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
          title: const Text('Perfil'),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(color: ColoresApp.acentoPrimario),
        ),
      );
    }

    final formato = NumberFormat.decimalPattern('es');

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(
                nombre: _nombreCtrl.text.isEmpty
                    ? 'amigo'
                    : _nombreCtrl.text,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ColoresApp.tarjeta,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.white54, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu metabolismo basal se recalcula automáticamente al cambiar peso, altura, edad o sexo.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _EtiquetaCampo(texto: 'Nombre'),
              const SizedBox(height: 6),
              TextField(
                controller: _nombreCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: _dec('', ''),
              ),
              const SizedBox(height: 16),
              const _EtiquetaCampo(texto: 'Sexo'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _OpcionSexo(
                      icono: Icons.male_rounded,
                      etiqueta: 'Hombre',
                      seleccionada: _sexo == Sexo.masculino,
                      alPulsar: () {
                        setState(() => _sexo = Sexo.masculino);
                        _recalcular();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OpcionSexo(
                      icono: Icons.female_rounded,
                      etiqueta: 'Mujer',
                      seleccionada: _sexo == Sexo.femenino,
                      alPulsar: () {
                        setState(() => _sexo = Sexo.femenino);
                        _recalcular();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _EtiquetaCampo(texto: 'Edad'),
              const SizedBox(height: 6),
              TextField(
                controller: _edadCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: _dec('', 'años'),
              ),
              const SizedBox(height: 12),
              const _EtiquetaCampo(texto: 'Peso'),
              const SizedBox(height: 6),
              TextField(
                controller: _pesoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: _dec('', 'kg'),
              ),
              const SizedBox(height: 12),
              const _EtiquetaCampo(texto: 'Altura'),
              const SizedBox(height: 6),
              TextField(
                controller: _alturaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: _dec('', 'cm'),
              ),
              const SizedBox(height: 22),
              _TmbPreview(tmb: _tmbEnVivo, formato: formato),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _formularioValido && !_guardando
                      ? _guardar
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresApp.acentoPrimario,
                    disabledBackgroundColor:
                        ColoresApp.acentoPrimario.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.nombre});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColoresApp.acentoGradiente1.withValues(alpha: 0.25),
            ColoresApp.acentoGradiente2.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  ColoresApp.acentoGradiente1,
                  ColoresApp.acentoGradiente2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu cuenta',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EtiquetaCampo extends StatelessWidget {
  const _EtiquetaCampo({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _OpcionSexo extends StatelessWidget {
  const _OpcionSexo({
    required this.icono,
    required this.etiqueta,
    required this.seleccionada,
    required this.alPulsar,
  });

  final IconData icono;
  final String etiqueta;
  final bool seleccionada;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPulsar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: seleccionada
              ? ColoresApp.acentoPrimario.withValues(alpha: 0.18)
              : ColoresApp.tarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionada
                ? ColoresApp.acentoPrimario
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icono,
                color: seleccionada
                    ? ColoresApp.acentoPrimario
                    : Colors.white54,
                size: 26),
            const SizedBox(height: 6),
            Text(
              etiqueta,
              style: TextStyle(
                color: seleccionada ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TmbPreview extends StatelessWidget {
  const _TmbPreview({required this.tmb, required this.formato});
  final int? tmb;
  final NumberFormat formato;

  @override
  Widget build(BuildContext context) {
    final listo = tmb != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: listo
            ? ColoresApp.acentoPrimario.withValues(alpha: 0.12)
            : ColoresApp.tarjetaSutil,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: listo
              ? ColoresApp.acentoPrimario.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: listo
                  ? ColoresApp.acentoPrimario.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: listo ? ColoresApp.acentoPrimario : Colors.white30,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TMB actualizada',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  listo
                      ? '${formato.format(tmb)} kcal / día'
                      : 'Completa los datos',
                  style: TextStyle(
                    color: listo ? Colors.white : Colors.white54,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
