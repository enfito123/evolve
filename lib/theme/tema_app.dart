import 'package:flutter/material.dart';
import 'colores_app.dart';

class TemaApp {
  TemaApp._();

  static ThemeData get oscuro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColoresApp.fondo,
      colorScheme: const ColorScheme.dark(
        surface: ColoresApp.fondo,
        primary: ColoresApp.acentoPrimario,
        onPrimary: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: ColoresApp.textoPrimario,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: ColoresApp.textoPrimario,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: ColoresApp.textoSecundario,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          color: ColoresApp.textoSecundario,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
