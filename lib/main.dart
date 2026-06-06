import 'package:flutter/material.dart';
import 'theme/tema_app.dart';
import 'pages/pagina_inicio.dart';

void main() {
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
