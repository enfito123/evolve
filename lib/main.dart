import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'servicios/servicio_perfil.dart';
import 'theme/colores_app.dart';
import 'theme/tema_app.dart';
import 'pages/pagina_inicio.dart';
import 'pages/pagina_onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const AppEvolve());
}

class AppEvolve extends StatefulWidget {
  const AppEvolve({super.key});

  @override
  State<AppEvolve> createState() => _EstadoAppEvolve();
}

class _EstadoAppEvolve extends State<AppEvolve> {
  Widget? _pantallaInicial;

  @override
  void initState() {
    super.initState();
    _cargarPantalla();
  }

  Future<void> _cargarPantalla() async {
    final perfil = await ServicioPerfil.instancia.cargar();
    if (!mounted) return;
    setState(() {
      _pantallaInicial = perfil == null ? const PaginaOnboarding() : const PaginaInicio();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evolve',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.oscuro,
      home: _pantallaInicial ?? const Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
