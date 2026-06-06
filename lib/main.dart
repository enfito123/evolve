import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/tema_app.dart';
import 'pages/pagina_inicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const AppEvolve());
}

class AppEvolve extends StatelessWidget {
  const AppEvolve({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evolve',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.oscuro,
      home: const PaginaInicio(),
    );
  }
}
