import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modelos/estimacion_ia.dart';
import 'servicio_claves.dart';

class ErrorGroq implements Exception {
  ErrorGroq(this.mensaje, {this.codigo});
  final String mensaje;
  final int? codigo;
  @override
  String toString() => mensaje;
}

class ResultadoPruebaClave {
  const ResultadoPruebaClave.exito() : codigo = null, detalle = null;
  const ResultadoPruebaClave.fallo(this.codigo, this.detalle);
  final int? codigo;
  final String? detalle;
  bool get exito => codigo == null;
}

class ServicioGroq {
  ServicioGroq({http.Client? cliente}) : _cliente = cliente ?? http.Client();
  final http.Client _cliente;

  static const String _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _modelo = 'llama-3.1-8b-instant';
  static const String _promptSistema = '''Eres un asistente nutricional. Tu única tarea es extraer alimentos de la frase del usuario y devolver un JSON con sus calorías estimadas.

REGLAS CRÍTICAS (cumplir todas):

1. EXTRAE CADA ALIMENTO POR SEPARADO. No agrupes ni omitas nada. Si el usuario dice "yogurt con granola y proteína", devuelve 3 alimentos, no 1.

2. RESPETA EL PESO O VOLUMEN EXACTO que indique el usuario. Si dice "60g", "70gr", "15ml", "1 scoop de 70g", el nombre DEBE llevar esa cantidad entre paréntesis. No asumas raciones estándar.

3. FORMATO DEL NOMBRE: incluye el peso/volumen entre paréntesis cuando el usuario lo dé. Ejemplos:
   - "Yogurt (60g)"
   - "Leche (15ml)"
   - "Proteína (70g)"
   - "Granola (70g)"
   - "Café" (sin cantidad si el usuario no especificó)
   - "Huevos revueltos (2 unidades)" (cuando habla de unidades, no gramos)
   - "Aceite (1 cucharada)" (cuando el usuario lo especificó así)

4. "cantidad" es 1 por defecto. Solo es > 1 si el usuario dice "2 huevos", "3 tostadas", etc. (unidades, no gramos).

5. "calorias" es el TOTAL para la cantidad especificada. SIEMPRE asume que el peso indicado es del alimento EN CRUDO/SECO (tal como se compra y se pesa), NO cocinado. Esto es crítico:
   - Arroz blanco crudo: ~350 kcal/100g (cocido ~130 kcal/100g → si dice 150g cocido, recalcula a ~50g crudo)
   - Pasta cruda: ~370 kcal/100g
   - Legumbres secas (lentejas, garbanzos): ~350 kcal/100g
   - Pollo/pecho crudo: ~110 kcal/100g
   - Carne cruda (ternera, cerdo): ~250 kcal/100g
   - Patata cruda: ~80 kcal/100g
   - Pan de molde: ~270 kcal/100g
   - Avena cruda: ~370 kcal/100g
   - Yogurt natural: ~60 kcal/100g
   - Leche entera: ~60 kcal/100ml
   - Proteína en polvo: ~380 kcal/100g
   - Granola: ~470 kcal/100g
   - Aceite de oliva: ~90 kcal/cucharada (15ml)
   - Café solo (sin azúcar): ~2 kcal
   - Frutos secos: ~600 kcal/100g
   - Fruta fresca: ~50 kcal/100g
   Si el usuario dice explícitamente "cocido", "hecho", "preparado", entonces usa el valor cocinado. En caso de duda, asume crudo.

6. Si la frase no menciona alimentos reconocibles, devuelve: {"alimentos": []}

7. No añadas texto fuera del JSON. No comentes, no expliques.

FORMATO DE SALIDA (obligatorio):
{
  "alimentos": [
    {"nombre": "Alimento (cantidad con unidad)", "cantidad": 1, "calorias": X}
  ]
}

EJEMPLOS:

Entrada: "yogurt 60g + scoop 70g de proteína + scoop 70g de granola"
Salida: {"alimentos": [
  {"nombre": "Yogurt (60g)", "cantidad": 1, "calorias": 36},
  {"nombre": "Proteína (70g)", "cantidad": 1, "calorias": 266},
  {"nombre": "Granola (70g)", "cantidad": 1, "calorias": 329}
]}

Entrada: "150g de arroz blanco"
Salida: {"alimentos": [
  {"nombre": "Arroz blanco (150g crudo)", "cantidad": 1, "calorias": 525}
]}

Entrada: "café con leche (15ml de leche)"
Salida: {"alimentos": [
  {"nombre": "Café", "cantidad": 1, "calorias": 2},
  {"nombre": "Leche (15ml)", "cantidad": 1, "calorias": 9}
]}

Entrada: "100g de pechuga de pollo a la plancha"
Salida: {"alimentos": [
  {"nombre": "Pechuga de pollo (100g)", "cantidad": 1, "calorias": 110}
]}

Entrada: "2 huevos revueltos con una cucharada de aceite"
Salida: {"alimentos": [
  {"nombre": "Huevos revueltos (2 unidades)", "cantidad": 1, "calorias": 180},
  {"nombre": "Aceite (1 cucharada)", "cantidad": 1, "calorias": 90}
]}''';

  Future<String> _obtenerClave() async {
    return ServicioClaves.instancia.obtenerClaveGroq();
  }

  Future<List<EstimacionIa>> estimar(String fraseUsuario) async {
    final clave = await _obtenerClave();
    if (clave.isEmpty) {
      throw ErrorGroq('No has configurado tu clave de Groq. Ve a Ajustes para añadirla.');
    }
    return _consultar(fraseUsuario, clave);
  }

  Future<List<EstimacionIa>> _consultar(String fraseUsuario, String clave) async {
    final cuerpo = jsonEncode({
      'model': _modelo,
      'messages': [
        {'role': 'system', 'content': _promptSistema},
        {'role': 'user', 'content': fraseUsuario},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.1,
    });

    final respuesta = await _cliente.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $clave',
        'Content-Type': 'application/json',
      },
      body: cuerpo,
    ).timeout(const Duration(seconds: 30));

    if (respuesta.statusCode != 200) {
      throw _errorDesdeCodigo(respuesta.statusCode, respuesta.body);
    }

    final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final contenido = json['choices'][0]['message']['content'] as String;
    final alimentos = jsonDecode(contenido) as Map<String, dynamic>;
    final lista = (alimentos['alimentos'] as List? ?? const []);

    return lista.map((m) {
      final mapa = m as Map<String, dynamic>;
      return EstimacionIa(
        nombre: (mapa['nombre'] as String? ?? '').trim(),
        cantidad: (mapa['cantidad'] as num?)?.toInt() ?? 1,
        caloriasTotales: (mapa['calorias'] as num?)?.toInt() ?? 0,
      );
    }).where((e) => e.nombre.isNotEmpty).toList();
  }

  Future<ResultadoPruebaClave> probarClave(String clave) async {
    if (!ServicioClaves.instancia.esClaveGroqValida(clave)) {
      return const ResultadoPruebaClave.fallo(0, 'La clave no tiene el formato esperado (debe empezar por gsk_)');
    }
    try {
      final respuesta = await _cliente.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer ${clave.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelo,
          'messages': [
            {'role': 'user', 'content': 'ok'},
          ],
          'max_tokens': 1,
        }),
      ).timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        return const ResultadoPruebaClave.exito();
      }
      return ResultadoPruebaClave.fallo(
        respuesta.statusCode,
        _extraerDetalle(respuesta.body),
      );
    } catch (_) {
      return const ResultadoPruebaClave.fallo(0, 'Sin conexión a internet');
    }
  }

  ErrorGroq _errorDesdeCodigo(int codigo, String cuerpo) {
    if (codigo == 401) {
      return ErrorGroq('Tu clave de Groq ya no es válida. Renuévala en Ajustes.', codigo: 401);
    }
    if (codigo == 429) {
      return ErrorGroq('Has alcanzado el límite diario de Groq. Vuelve a intentarlo más tarde.', codigo: 429);
    }
    return ErrorGroq('Error al conectar con Groq ($codigo). ${_extraerDetalle(cuerpo)}', codigo: codigo);
  }

  String _extraerDetalle(String cuerpo) {
    try {
      final json = jsonDecode(cuerpo) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}
