import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServicioClaves {
  ServicioClaves._();

  static final ServicioClaves instancia = ServicioClaves._();

  static const String _claveGemini = 'gemini_api_key';

  final FlutterSecureStorage _almacen = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> obtenerClaveGemini() => _almacen.read(key: _claveGemini);

  Future<void> guardarClaveGemini(String clave) =>
      _almacen.write(key: _claveGemini, value: clave);

  Future<void> eliminarClaveGemini() => _almacen.delete(key: _claveGemini);

  Future<bool> tieneClaveGemini() async {
    final clave = await obtenerClaveGemini();
    return clave != null && clave.isNotEmpty;
  }
}
