import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../servicios/servicio_claves.dart';
import '../servicios/servicio_ia.dart';
import '../theme/colores_app.dart';

class PaginaConfiguracionGemini extends StatefulWidget {
  const PaginaConfiguracionGemini({super.key, this.claveInicial});

  final String? claveInicial;

  @override
  State<PaginaConfiguracionGemini> createState() => _EstadoConfiguracionGemini();
}

class _EstadoConfiguracionGemini extends State<PaginaConfiguracionGemini> {
  final TextEditingController _controlador = TextEditingController();
  final ServicioIa _ia = ServicioIa();
  final ServicioClaves _claves = ServicioClaves.instancia;

  bool _guardando = false;
  bool _mostrarClave = false;

  static const String _urlConsola = 'https://aistudio.google.com/app/apikey';

  @override
  void initState() {
    super.initState();
    if (widget.claveInicial != null) {
      _controlador.text = widget.claveInicial!;
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    _ia.cerrar();
    super.dispose();
  }

  Future<void> _abrirConsola() async {
    final uri = Uri.parse(_urlConsola);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pegarDelPortapapeles() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = datos?.text?.trim();
    if (texto == null || texto.isEmpty) return;
    if (!_esFormatoValido(texto)) {
      _mostrarAviso('El portapapeles no contiene una clave de Gemini (debe empezar por AIza)');
      return;
    }
    setState(() => _controlador.text = texto);
  }

  bool _esFormatoValido(String clave) {
    final limpia = clave.trim();
    return limpia.startsWith('AIza') && limpia.length >= 30;
  }

  Future<void> _guardar() async {
    final clave = _controlador.text.trim();
    if (!_esFormatoValido(clave)) {
      _mostrarAviso('La clave no parece válida. Debe empezar por AIza y tener al menos 30 caracteres.');
      return;
    }

    setState(() => _guardando = true);

    final funciona = await _ia.probarClave(clave);
    if (!funciona) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarAviso('La clave no funciona. Revísala e inténtalo de nuevo.');
      return;
    }

    await _claves.guardarClaveGemini(clave);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColoresApp.tarjeta,
        title: const Text('Desconectar Gemini'),
        content: const Text('Se eliminará tu clave guardada. Tendrás que volver a conectarla para usar la IA.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _claves.eliminarClaveGemini();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        title: const Text('Conectar con Gemini'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (widget.claveInicial != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: _eliminar,
              tooltip: 'Desconectar',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColoresApp.acentoPrimario.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: ColoresApp.acentoPrimario.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: ColoresApp.acentoPrimario, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'La clave se guarda cifrada en tu dispositivo y solo se usa para estimar calorías de tus comidas. Nunca sale de tu móvil salvo al llamar a Gemini.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _Paso(
                numero: 1,
                titulo: 'Abre Google AI Studio',
                descripcion: 'Te llevará a la consola de Google. Inicia sesión con tu cuenta y se creará una clave gratis.',
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _abrirConsola,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Abrir Google AI Studio'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: ColoresApp.textoSecundario.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _Paso(
                numero: 2,
                titulo: 'Crea tu clave',
                descripcion: 'Pulsa "Create API key" en la web y luego cópiala (empieza por AIza).',
              ),
              const SizedBox(height: 8),
              _Paso(
                numero: 3,
                titulo: 'Pégala aquí',
                descripcion: 'Usa el botón de pegar o el icono del portapapeles para traerla automáticamente.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: ColoresApp.tarjeta,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controlador,
                        obscureText: !_mostrarClave,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'AIza...',
                          hintStyle: TextStyle(color: ColoresApp.textoSecundario),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _mostrarClave ? Icons.visibility_off : Icons.visibility,
                        color: ColoresApp.textoSecundario,
                      ),
                      onPressed: () => setState(() => _mostrarClave = !_mostrarClave),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_paste_rounded,
                          color: ColoresApp.acentoPrimario),
                      onPressed: _pegarDelPortapapeles,
                      tooltip: 'Pegar del portapapeles',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresApp.acentoPrimario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'GUARDAR Y CONECTAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
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

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.titulo, required this.descripcion});

  final int numero;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ColoresApp.acentoPrimario.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$numero',
                style: const TextStyle(
                  color: ColoresApp.acentoPrimario,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
