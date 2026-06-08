import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/perfil.dart';

class ServicioPerfil {
  ServicioPerfil._();
  static final ServicioPerfil instancia = ServicioPerfil._();

  static const String _clave = 'perfil_usuario';

  Future<ModeloPerfil?> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_clave);
    if (json == null) return null;
    final mapa = jsonDecode(json) as Map<String, dynamic>;
    return ModeloPerfil.desdeMapa(mapa);
  }

  Future<void> guardar(ModeloPerfil perfil) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(perfil.aMapa());
    await prefs.setString(_clave, json);
  }

  Future<void> eliminar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }
}
