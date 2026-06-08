import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServicioClaves {
  ServicioClaves._();
  static final ServicioClaves instancia = ServicioClaves._();

  static const String _claveGroq = 'clave_groq';
  static const String _prefijoGroq = 'gsk_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String> obtenerClaveGroq() async {
    final clave = await _storage.read(key: _claveGroq);
    return clave ?? '';
  }

  Future<void> guardarClaveGroq(String clave) async {
    await _storage.write(key: _claveGroq, value: clave);
  }

  Future<void> eliminarClaveGroq() async {
    await _storage.delete(key: _claveGroq);
  }

  bool esClaveGroqValida(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return false;
    if (!limpio.startsWith(_prefijoGroq)) return false;
    if (limpio.length < 20) return false;
    if (limpio.contains(' ')) return false;
    return true;
  }
}
