import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../servicios/servicio_claves.dart';
import '../servicios/servicio_groq.dart';
import '../theme/colores_app.dart';

class PaginaConfiguracionGroq extends StatefulWidget {
  const PaginaConfiguracionGroq({super.key});

  @override
  State<PaginaConfiguracionGroq> createState() => _EstadoPaginaConfiguracionGroq();
}

class _EstadoPaginaConfiguracionGroq extends State<PaginaConfiguracionGroq> {
  final TextEditingController _controlador = TextEditingController();
  final ServicioGroq _groq = ServicioGroq();
  final FocusNode _foco = FocusNode();

  bool _cargandoInicial = true;
  bool _probando = false;
  bool _esperandoRegreso = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_ObservadorCicloVida(this));
    _cargarClaveActual();
  }

  @override
  void dispose() {
    _controlador.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _cargarClaveActual() async {
    final clave = await ServicioClaves.instancia.obtenerClaveGroq();
    if (!mounted) return;
    setState(() {
      if (clave.isNotEmpty) _controlador.text = clave;
      _cargandoInicial = false;
    });
  }

  void _alVolverDelFondo() {
    if (!_esperandoRegreso) return;
    _esperandoRegreso = false;
    _intentarAutoConectar();
  }

  Future<void> _intentarAutoConectar() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = datos?.text?.trim() ?? '';
    if (!ServicioClaves.instancia.esClaveGroqValida(texto)) {
      if (!mounted) return;
      _mostrarAviso('No detecté ninguna clave de Groq en el portapapeles. Pégala manualmente.');
      return;
    }
    if (texto == _controlador.text.trim()) {
      return;
    }
    _controlador.text = texto;
    _controlador.selection = TextSelection.fromPosition(TextPosition(offset: texto.length));
    _mostrarAviso('Clave detectada del portapapeles. Pulsa "Guardar" para usarla.');
  }

  Future<void> _guardar() async {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) {
      _mostrarAviso('Pega primero tu clave de Groq');
      return;
    }
    setState(() => _probando = true);
    final resultado = await _groq.probarClave(texto);
    if (!mounted) return;
    if (!resultado.exito) {
      setState(() => _probando = false);
      _mostrarAviso(_explicarError(resultado));
      return;
    }
    await ServicioClaves.instancia.guardarClaveGroq(texto);
    if (!mounted) return;
    setState(() => _probando = false);
    _mostrarExito('¡Conectado a Groq correctamente!');
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _abrirGroqConsole() async {
    final uri = Uri.parse('https://console.groq.com/keys');
    if (await canLaunchUrl(uri)) {
      _esperandoRegreso = true;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _mostrarAviso('No se pudo abrir el navegador');
    }
  }

  Future<void> _eliminarClave() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColoresApp.tarjeta,
        title: const Text('¿Eliminar la clave?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Dejarás de poder usar las funciones de IA hasta que vuelvas a configurarla.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmar != true) return;
    await ServicioClaves.instancia.eliminarClaveGroq();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _explicarError(ResultadoPruebaClave r) {
    if (r.codigo == 401) return 'La clave no es válida o ha sido revocada. Genera una nueva en Groq Console.';
    if (r.codigo == 403) return 'La clave está bloqueada. Revisa las restricciones en Groq Console.';
    if (r.codigo == 429) return 'Has alcanzado el límite gratuito. Espera unos minutos o usa otra clave.';
    if (r.codigo == 0 && r.detalle != null) return r.detalle!;
    return 'No se pudo conectar con Groq. Revisa tu internet e inténtalo de nuevo.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text('Asistente de IA'),
        actions: [
          if (_controlador.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: _eliminarClave,
              tooltip: 'Eliminar clave',
            ),
        ],
      ),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
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
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Configura tu asistente de IA',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Para interpretar tus comidas con lenguaje natural, conecta tu cuenta gratuita de Groq. Solo se hace una vez.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ColoresApp.tarjetaSutil,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ColoresApp.acentoPrimario.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.help_outline_rounded, color: ColoresApp.acentoTeal, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Cómo conseguir tu clave',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '1. Inicia sesión en Groq con tu cuenta de Google\n'
                            '2. Abre la sección "API Keys"\n'
                            '3. Pulsa "Create API Key" y copia la clave',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _abrirGroqConsole,
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: const Text('ABRIR GROQ CONSOLE'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: ColoresApp.acentoPrimario.withValues(alpha: 0.5)),
                                foregroundColor: ColoresApp.acentoPrimario,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ColoresApp.tarjeta,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.key_rounded, color: ColoresApp.acentoTeal, size: 18),
                              const SizedBox(width: 8),
                              const Text('Clave de API de Groq', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _controlador,
                            focusNode: _foco,
                            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'gsk_...',
                              hintStyle: const TextStyle(color: Colors.white30, fontFamily: 'monospace'),
                              isDense: true,
                              filled: true,
                              fillColor: ColoresApp.tarjetaSutil,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.paste_rounded, color: Colors.white54, size: 18),
                                onPressed: () async {
                                  final datos = await Clipboard.getData(Clipboard.kTextPlain);
                                  final t = datos?.text?.trim() ?? '';
                                  if (t.isNotEmpty) {
                                    _controlador.text = t;
                                    _controlador.selection = TextSelection.fromPosition(TextPosition(offset: t.length));
                                  }
                                },
                                tooltip: 'Pegar del portapapeles',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _probando ? null : _guardar,
                        icon: _probando
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.bolt_rounded),
                        label: const Text('PROBAR Y GUARDAR', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColoresApp.acentoPrimario,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ColoresApp.tarjetaSutil,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.white54, size: 16),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tu clave se guarda cifrada en tu móvil y no se envía a ningún sitio más que a Groq.',
                              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ObservadorCicloVida extends WidgetsBindingObserver {
  _ObservadorCicloVida(this._estado);
  final _EstadoPaginaConfiguracionGroq _estado;
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      _estado._alVolverDelFondo();
    }
  }
}
