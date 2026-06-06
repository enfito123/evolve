import 'dart:convert';
import 'package:http/http.dart' as http;
import 'servicio_claves.dart';

class EstimacionComida {
  const EstimacionComida({required this.nombre, required this.calorias});

  final String nombre;
  final int calorias;

  factory EstimacionComida.desdeJson(Map<String, dynamic> json) {
    return EstimacionComida(
      nombre: json['nombre'] as String,
      calorias: (json['calorias'] as num).round(),
    );
  }
}

class ServicioIa {
  ServicioIa({http.Client? clienteHttp, ServicioClaves? servicioClaves})
      : _cliente = clienteHttp ?? http.Client(),
        _claves = servicioClaves ?? ServicioClaves.instancia;

  final http.Client _cliente;
  final ServicioClaves _claves;

  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<bool> claveConfigurada() => _claves.tieneClaveGemini();

  Future<List<EstimacionComida>> estimarCalorias(String descripcion) async {
    final clave = await _claves.obtenerClaveGemini();
    if (clave == null || clave.isEmpty) {
      throw const FaltaClaveGemini();
    }

    final respuesta = await _cliente.post(
      Uri.parse('$_url?key=$clave'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': _construirPrompt(descripcion)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      }),
    );

    if (respuesta.statusCode != 200) {
      throw ErrorIa(respuesta.statusCode, respuesta.body);
    }

    final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final texto = _extraerTexto(cuerpo);
    if (texto == null) {
      throw const ErrorIa(0, 'Respuesta vacía de la IA');
    }

    return _parsearComidas(texto);
  }

  Future<bool> probarClave(String clave) async {
    try {
      final respuesta = await _cliente.post(
        Uri.parse('$_url?key=$clave'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Responde únicamente: ok'},
              ],
            },
          ],
          'generationConfig': {'temperature': 0, 'maxOutputTokens': 5},
        }),
      );
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _construirPrompt(String descripcion) {
    return '''
Eres un asistente de nutrición. Analiza la siguiente descripción de comida en español y devuelve únicamente un JSON válido con este esquema:

{
  "comidas": [
    { "nombre": "Descripción breve del alimento o plato", "calorias": número entero estimado de calorías }
  ]
}

Reglas:
- Estima calorías de forma realista para una ración normal/adulta.
- Si la descripción menciona varios alimentos, desglósalos en objetos separados dentro del array.
- Si no puedes estimarlo, devuelve un solo elemento con el nombre y 0 calorías.
- No añadas texto fuera del JSON.

Descripción del usuario: "$descripcion"
''';
  }

  String? _extraerTexto(Map<String, dynamic> cuerpo) {
    final candidatos = cuerpo['candidates'] as List?;
    if (candidatos == null || candidatos.isEmpty) return null;
    final contenido = candidatos.first['content'] as Map<String, dynamic>?;
    if (contenido == null) return null;
    final partes = contenido['parts'] as List?;
    if (partes == null || partes.isEmpty) return null;
    return partes.first['text'] as String?;
  }

  List<EstimacionComida> _parsearComidas(String texto) {
    var limpio = texto.trim();
    if (limpio.startsWith('```')) {
      limpio = limpio.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      limpio = limpio.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final json = jsonDecode(limpio) as Map<String, dynamic>;
    final lista = (json['comidas'] as List?) ?? [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map(EstimacionComida.desdeJson)
        .toList();
  }

  void cerrar() => _cliente.close();
}

class FaltaClaveGemini implements Exception {
  const FaltaClaveGemini();
  @override
  String toString() => 'No has configurado tu clave de Gemini todavía';
}

class ErrorIa implements Exception {
  const ErrorIa(this.codigo, this.detalle);
  final int codigo;
  final String detalle;
  @override
  String toString() => 'Error de IA ($codigo): $detalle';
}
