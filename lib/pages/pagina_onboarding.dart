import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modelos/perfil.dart';
import '../servicios/servicio_perfil.dart';
import '../theme/colores_app.dart';
import 'pagina_inicio.dart';

class PaginaOnboarding extends StatefulWidget {
  const PaginaOnboarding({super.key});

  @override
  State<PaginaOnboarding> createState() => _EstadoPaginaOnboarding();
}

class _EstadoPaginaOnboarding extends State<PaginaOnboarding> {
  static const int _totalPasos = 5;

  final PageController _controlador = PageController();
  int _paso = 0;

  final _nombreCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _focoNombre = FocusNode();

  Sexo _sexo = Sexo.masculino;
  bool _consentimiento = false;
  int? _tmbCalculado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(_refrescar);
    _edadCtrl.addListener(_refrescar);
    _pesoCtrl.addListener(_refrescar);
    _alturaCtrl.addListener(_refrescar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_paso == 1) _focoNombre.requestFocus();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.removeListener(_refrescar);
    _edadCtrl.removeListener(_refrescar);
    _pesoCtrl.removeListener(_refrescar);
    _alturaCtrl.removeListener(_refrescar);
    _controlador.dispose();
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    _focoNombre.dispose();
    super.dispose();
  }

  void _refrescar() => setState(() {});

  bool get _puedeAvanzar {
    switch (_paso) {
      case 0: return true;
      case 1: return _nombreCtrl.text.trim().length >= 2;
      case 2: return _consentimiento;
      case 3: return _formularioValido();
      case 4: return true;
      default: return false;
    }
  }

  bool _formularioValido() {
    final edad = int.tryParse(_edadCtrl.text.trim());
    final peso = double.tryParse(_pesoCtrl.text.trim().replaceAll(',', '.'));
    final altura = double.tryParse(_alturaCtrl.text.trim().replaceAll(',', '.'));
    return edad != null && edad >= 10 && edad <= 100 &&
        peso != null && peso >= 30 && peso <= 300 &&
        altura != null && altura >= 100 && altura <= 250;
  }

  String get _textoBoton {
    switch (_paso) {
      case 0: return 'EMPEZAR';
      case 1: return 'SIGUIENTE';
      case 2: return 'CONTINUAR';
      case 3: return 'CALCULAR';
      case 4: return 'EMPEZAR';
      default: return 'SIGUIENTE';
    }
  }

  void _avanzar() {
    if (!_puedeAvanzar) {
      if (_paso == 1) {
        _mostrarAviso('Escribe tu nombre para continuar');
      } else if (_paso == 2) {
        _mostrarAviso('Marca la casilla para continuar');
      }
      return;
    }
    if (_paso == 3) {
      _calcularYAvanzar();
    } else if (_paso == 4) {
      _guardar();
    } else {
      _irAPaso(_paso + 1);
      if (_paso + 1 == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _focoNombre.requestFocus());
      }
    }
  }

  void _retroceder() {
    if (_paso > 0) _irAPaso(_paso - 1);
  }

  void _irAPaso(int destino) {
    _controlador.animateToPage(
      destino,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  void _calcularYAvanzar() {
    final edad = int.parse(_edadCtrl.text.trim());
    final peso = double.parse(_pesoCtrl.text.trim().replaceAll(',', '.'));
    final altura = double.parse(_alturaCtrl.text.trim().replaceAll(',', '.'));
    final temp = ModeloPerfil(
      nombre: _nombreCtrl.text.trim(),
      edad: edad,
      sexo: _sexo,
      peso: peso,
      altura: altura,
    );
    setState(() => _tmbCalculado = temp.tmb);
    _irAPaso(4);
  }

  Future<void> _guardar() async {
    final edad = int.parse(_edadCtrl.text.trim());
    final peso = double.parse(_pesoCtrl.text.trim().replaceAll(',', '.'));
    final altura = double.parse(_alturaCtrl.text.trim().replaceAll(',', '.'));
    setState(() => _guardando = true);
    final perfil = ModeloPerfil(
      nombre: _nombreCtrl.text.trim(),
      edad: edad,
      sexo: _sexo,
      peso: peso,
      altura: altura,
    );
    await ServicioPerfil.instancia.guardar(perfil);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PaginaInicio()),
      (_) => false,
    );
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _BarraProgreso(paso: _paso, total: _totalPasos),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _paso > 0
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                        onPressed: _retroceder,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controlador,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _paso = i),
                children: [
                  const _PasoBienvenida(),
                  _PasoNombre(controlador: _nombreCtrl, foco: _focoNombre),
                  _PasoExplicacion(
                    consentimiento: _consentimiento,
                    alCambiar: (v) => setState(() => _consentimiento = v),
                  ),
                  _PasoFormulario(
                    edadCtrl: _edadCtrl,
                    pesoCtrl: _pesoCtrl,
                    alturaCtrl: _alturaCtrl,
                    sexo: _sexo,
                    alCambiarSexo: (s) => setState(() => _sexo = s),
                  ),
                  _PasoResultado(
                    nombre: _nombreCtrl.text.trim(),
                    tmb: _tmbCalculado ?? 0,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _puedeAvanzar ? 1.0 : 0.5,
                  child: ElevatedButton(
                    onPressed: _puedeAvanzar && !_guardando ? _avanzar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.acentoPrimario,
                      disabledBackgroundColor: ColoresApp.acentoPrimario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _textoBoton,
                            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 15),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMPONENTES COMPARTIDOS ────────────────────────────────────────────────

class _BarraProgreso extends StatelessWidget {
  const _BarraProgreso({required this.paso, required this.total});
  final int paso;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(total, (i) {
          final activo = i <= paso;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: activo ? ColoresApp.acentoPrimario : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LogoPulsante extends StatefulWidget {
  const _LogoPulsante();
  @override
  State<_LogoPulsante> createState() => _EstadoLogoPulsante();
}

class _EstadoLogoPulsante extends State<_LogoPulsante> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ColoresApp.acentoGradiente1, ColoresApp.acentoGradiente2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: ColoresApp.acentoPrimario.withValues(alpha: 0.25 + t * 0.35),
                blurRadius: 24 + t * 20,
                spreadRadius: 2 + t * 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 64),
    );
  }
}

class _TextoAnimado extends StatefulWidget {
  const _TextoAnimado({
    required this.texto,
    this.estilo,
    this.retraso = Duration.zero,
    this.alineacion = TextAlign.start,
    this.subir = true,
  });
  final String texto;
  final TextStyle? estilo;
  final Duration retraso;
  final TextAlign alineacion;
  final bool subir;

  @override
  State<_TextoAnimado> createState() => _EstadoTextoAnimado();
}

class _EstadoTextoAnimado extends State<_TextoAnimado> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    if (widget.retraso == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.retraso, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curva,
      builder: (context, child) {
        return Opacity(
          opacity: curva.value,
          child: Transform.translate(
            offset: Offset(0, widget.subir ? (1 - curva.value) * 20 : 0),
            child: child,
          ),
        );
      },
      child: Text(widget.texto, style: widget.estilo, textAlign: widget.alineacion),
    );
  }
}

class _TarjetaDeslizante extends StatefulWidget {
  const _TarjetaDeslizante({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.retraso = Duration.zero,
  });
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Duration retraso;

  @override
  State<_TarjetaDeslizante> createState() => _EstadoTarjetaDeslizante();
}

class _EstadoTarjetaDeslizante extends State<_TarjetaDeslizante> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(widget.retraso, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curva,
      builder: (context, child) {
        return Opacity(
          opacity: curva.value,
          child: Transform.translate(
            offset: Offset((1 - curva.value) * 30, 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColoresApp.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColoresApp.acentoPrimario.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icono, color: ColoresApp.acentoPrimario, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(widget.descripcion, style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContadorAnimado extends StatefulWidget {
  const _ContadorAnimado({required this.valor, this.estilo});
  final int valor;
  final TextStyle? estilo;

  @override
  State<_ContadorAnimado> createState() => _EstadoContadorAnimado();
}

class _EstadoContadorAnimado extends State<_ContadorAnimado> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _anim;
  int _mostrado = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _anim = Tween<double>(begin: 0, end: widget.valor.toDouble())
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _anim.addListener(() {
      final v = _anim.value.round();
      if (v != _mostrado) setState(() => _mostrado = v);
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('$_mostrado', style: widget.estilo);
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: seleccionada ? ColoresApp.acentoPrimario.withValues(alpha: 0.18) : ColoresApp.tarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionada ? ColoresApp.acentoPrimario : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icono, color: seleccionada ? ColoresApp.acentoPrimario : Colors.white54, size: 28),
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

// ─── PASOS ─────────────────────────────────────────────────────────────────

class _PasoBienvenida extends StatelessWidget {
  const _PasoBienvenida();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Center(child: _LogoPulsante()),
          const SizedBox(height: 48),
          const _TextoAnimado(
            texto: 'Bienvenido a Evolve',
            estilo: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.15),
            alineacion: TextAlign.center,
            retraso: Duration(milliseconds: 200),
          ),
          const SizedBox(height: 20),
          const _TextoAnimado(
            texto: 'Más que una app, tu compañero de evolución. Ejercicios interactivos, control de calorías, ranking por puntos y muchas más funciones que iremos añadiendo para ayudarte a dar lo mejor de ti.',
            estilo: TextStyle(color: Colors.white70, fontSize: 16, height: 1.55),
            alineacion: TextAlign.center,
            retraso: Duration(milliseconds: 500),
          ),
          const SizedBox(height: 64),
          const _TextoAnimado(
            texto: '↓',
            estilo: TextStyle(color: Colors.white24, fontSize: 28),
            alineacion: TextAlign.center,
            retraso: Duration(milliseconds: 1200),
          ),
          const SizedBox(height: 8),
          const _TextoAnimado(
            texto: 'Vamos allá',
            estilo: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w600),
            alineacion: TextAlign.center,
            retraso: Duration(milliseconds: 1400),
          ),
        ],
      ),
    );
  }
}

class _PasoNombre extends StatelessWidget {
  const _PasoNombre({required this.controlador, required this.foco});
  final TextEditingController controlador;
  final FocusNode foco;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const _TextoAnimado(
            texto: '¡Genial!',
            estilo: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const _TextoAnimado(
            texto: 'Vamos a conocernos',
            estilo: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
            retraso: Duration(milliseconds: 200),
          ),
          const SizedBox(height: 48),
          const _TextoAnimado(
            texto: '¿Cómo te llamas?',
            estilo: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
            retraso: Duration(milliseconds: 500),
          ),
          const SizedBox(height: 12),
          _TextoAnimado(
            texto: '',
            estilo: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            retraso: const Duration(milliseconds: 700),
            subir: false,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controlador,
            focusNode: foco,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Tu nombre',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 22, fontWeight: FontWeight.w500),
              filled: true,
              fillColor: ColoresApp.tarjeta,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: ColoresApp.acentoPrimario, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasoExplicacion extends StatelessWidget {
  const _PasoExplicacion({required this.consentimiento, required this.alCambiar});
  final bool consentimiento;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ColoresApp.acentoTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_rounded, color: ColoresApp.acentoTeal, size: 28),
          ).animateIn(),
          const SizedBox(height: 20),
          const _TextoAnimado(
            texto: 'Tus datos son tuyos',
            estilo: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            retraso: Duration(milliseconds: 150),
          ),
          const SizedBox(height: 10),
          const _TextoAnimado(
            texto: 'Antes de pedirte información personal, queremos ser transparentes sobre qué haremos con ella.',
            estilo: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            retraso: Duration(milliseconds: 300),
          ),
          const SizedBox(height: 24),
          const _TarjetaDeslizante(
            icono: Icons.calculate_rounded,
            titulo: 'Cálculo de tu metabolismo basal',
            descripcion: 'Con tu edad, sexo, peso y altura calculamos la energía mínima que tu cuerpo consume en reposo. Lo usaremos para personalizar tus calorías y cargas de entrenamiento.',
            retraso: Duration(milliseconds: 500),
          ),
          const SizedBox(height: 10),
          const _TarjetaDeslizante(
            icono: Icons.lock_rounded,
            titulo: 'Privacidad total',
            descripcion: 'Tus datos se guardan SOLO en tu móvil, cifrados. Nunca se envían a ningún servidor.',
            retraso: Duration(milliseconds: 700),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => alCambiar(!consentimiento),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: ColoresApp.tarjetaSutil,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: consentimiento ? ColoresApp.acentoPrimario.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: consentimiento ? ColoresApp.acentoPrimario : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: consentimiento ? ColoresApp.acentoPrimario : Colors.white30,
                        width: 2,
                      ),
                    ),
                    child: consentimiento
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Entiendo y acepto que mis datos se almacenen solo en mi dispositivo',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget animateIn() {
    // Pequeño helper para el icono del paso de explicación
    return _EntradaIcono(child: this);
  }
}

class _EntradaIcono extends StatefulWidget {
  const _EntradaIcono({required this.child});
  final Widget child;
  @override
  State<_EntradaIcono> createState() => _EstadoEntradaIcono();
}

class _EstadoEntradaIcono extends State<_EntradaIcono> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      builder: (context, child) {
        return Transform.scale(
          scale: _c.value,
          child: Opacity(opacity: _c.value.clamp(0.0, 1.0), child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _PasoFormulario extends StatefulWidget {
  const _PasoFormulario({
    required this.edadCtrl,
    required this.pesoCtrl,
    required this.alturaCtrl,
    required this.sexo,
    required this.alCambiarSexo,
  });
  final TextEditingController edadCtrl;
  final TextEditingController pesoCtrl;
  final TextEditingController alturaCtrl;
  final Sexo sexo;
  final ValueChanged<Sexo> alCambiarSexo;

  @override
  State<_PasoFormulario> createState() => _EstadoPasoFormulario();
}

class _EstadoPasoFormulario extends State<_PasoFormulario> {
  int? _tmbEnVivo;

  @override
  void initState() {
    super.initState();
    for (final c in [widget.edadCtrl, widget.pesoCtrl, widget.alturaCtrl]) {
      c.addListener(_recalcular);
    }
    _recalcular();
  }

  @override
  void dispose() {
    for (final c in [widget.edadCtrl, widget.pesoCtrl, widget.alturaCtrl]) {
      c.removeListener(_recalcular);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PasoFormulario old) {
    super.didUpdateWidget(old);
    if (old.sexo != widget.sexo) _recalcular();
  }

  void _recalcular() {
    final edad = int.tryParse(widget.edadCtrl.text.trim());
    final peso = double.tryParse(widget.pesoCtrl.text.trim().replaceAll(',', '.'));
    final altura = double.tryParse(widget.alturaCtrl.text.trim().replaceAll(',', '.'));
    if (edad != null && peso != null && altura != null) {
      final base = 10.0 * peso + 6.25 * altura - 5.0 * edad;
      final valor = widget.sexo == Sexo.masculino ? base + 5 : base - 161;
      setState(() => _tmbEnVivo = valor.round());
    } else {
      setState(() => _tmbEnVivo = null);
    }
  }

  InputDecoration _dec(String label, String sufijo) => InputDecoration(
        labelText: label,
        suffixText: sufijo,
        labelStyle: const TextStyle(color: Colors.white54),
        suffixStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        filled: true,
        fillColor: ColoresApp.tarjeta,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ColoresApp.acentoPrimario, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const _TextoAnimado(
            texto: 'Cuéntanos sobre ti',
            estilo: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const _TextoAnimado(
            texto: 'Necesitamos 4 datos para calcular tu metabolismo basal.',
            estilo: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            retraso: Duration(milliseconds: 200),
          ),
          const SizedBox(height: 24),
          const _TextoAnimado(
            texto: 'Sexo',
            estilo: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            retraso: Duration(milliseconds: 400),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OpcionSexo(
                  icono: Icons.male_rounded,
                  etiqueta: 'Hombre',
                  seleccionada: widget.sexo == Sexo.masculino,
                  alPulsar: () => widget.alCambiarSexo(Sexo.masculino),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OpcionSexo(
                  icono: Icons.female_rounded,
                  etiqueta: 'Mujer',
                  seleccionada: widget.sexo == Sexo.femenino,
                  alPulsar: () => widget.alCambiarSexo(Sexo.femenino),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: widget.edadCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _dec('Edad', 'años'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.pesoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _dec('Peso', 'kg'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.alturaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _dec('Altura', 'cm'),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _tmbEnVivo != null
                  ? ColoresApp.acentoPrimario.withValues(alpha: 0.12)
                  : ColoresApp.tarjetaSutil,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _tmbEnVivo != null
                    ? ColoresApp.acentoPrimario.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: _tmbEnVivo != null ? ColoresApp.acentoPrimario : Colors.white30,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tmbEnVivo != null
                        ? 'TMB estimada: ~$_tmbEnVivo kcal/día'
                        : 'Completa los datos para ver tu TMB en vivo',
                    style: TextStyle(
                      color: _tmbEnVivo != null ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
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

class _PasoResultado extends StatelessWidget {
  const _PasoResultado({required this.nombre, required this.tmb});
  final String nombre;
  final int tmb;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColoresApp.acentoVerde.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.check_rounded, color: ColoresApp.acentoVerde, size: 56),
            ),
          ).animateIn(),
          const SizedBox(height: 28),
          _TextoAnimado(
            texto: '¡Listo, $nombre!',
            estilo: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.15),
            alineacion: TextAlign.center,
            retraso: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: ColoresApp.tarjeta,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ColoresApp.acentoPrimario.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                const Text(
                  'TU METABOLISMO BASAL',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                _ContadorAnimado(
                  valor: tmb,
                  estilo: const TextStyle(color: Colors.white, fontSize: 68, fontWeight: FontWeight.w800, height: 1),
                ),
                const SizedBox(height: 4),
                const Text(
                  'kcal / día',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _TextoAnimado(
            texto: 'Es la energía mínima que tu cuerpo consume en reposo absoluto, sin hacer ejercicio. La usaremos como base para recomendarte calorías y cargas de entrenamiento.',
            estilo: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            alineacion: TextAlign.center,
            retraso: Duration(milliseconds: 800),
          ),
        ],
      ),
    );
  }
}
