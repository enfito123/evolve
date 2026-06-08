import 'package:health/health.dart';

class ServicioPasos {
  ServicioPasos._();
  static final ServicioPasos instancia = ServicioPasos._();

  final Health _health = Health();
  bool _autorizado = false;

  static const List<HealthDataType> _tipos = [HealthDataType.STEPS];
  static const List<HealthDataAccess> _permisos = [HealthDataAccess.READ];

  Future<bool> healthConnectDisponible() async {
    try {
      return await _health.isHealthConnectAvailable();
    } catch (_) {
      return true;
    }
  }

  Future<void> instalarHealthConnect() async {
    try {
      await _health.installHealthConnect();
    } catch (_) {}
  }

  Future<bool> yaAutorizado() async {
    try {
      final tiene =
          await _health.hasPermissions(_tipos, permissions: _permisos);
      if (tiene == true) {
        _autorizado = true;
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> solicitarPermisos() async {
    if (await yaAutorizado()) {
      _autorizado = true;
      return true;
    }
    try {
      _autorizado = await _health.requestAuthorization(
        _tipos,
        permissions: _permisos,
      );
    } catch (_) {
      _autorizado = false;
    }
    return _autorizado;
  }

  Future<int> pasosHoy() async {
    if (!_autorizado) return 0;
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, ahora.day);
    try {
      final total =
          await _health.getTotalStepsInInterval(inicio, ahora) ?? 0;
      return total;
    } catch (_) {
      return 0;
    }
  }

  bool get autorizado => _autorizado;
}
