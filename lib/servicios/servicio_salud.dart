import 'package:health/health.dart';

class RegistroPeso {
  RegistroPeso({required this.fecha, required this.kilos});
  final DateTime fecha;
  final double kilos;
}

class RegistroCalorias {
  RegistroCalorias({
    required this.fecha,
    required this.kcalPasos,
    required this.kcalEjercicio,
  });
  final DateTime fecha;
  final int kcalPasos;
  final int kcalEjercicio;

  int get total => kcalPasos + kcalEjercicio;
}

class ServicioSalud {
  ServicioSalud._();
  static final ServicioSalud instancia = ServicioSalud._();

  final Health _health = Health();
  bool _autorizado = false;

  static const List<HealthDataType> _tipos = [
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.STEPS,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.LEAN_BODY_MASS,
    HealthDataType.HEIGHT,
    HealthDataType.BASAL_ENERGY_BURNED,
  ];
  static const List<HealthDataAccess> _permisos = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

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

  Future<bool> solicitarPermisosComposicion() async {
    try {
      return await _health.requestAuthorization(
        _tipos,
        permissions: _permisos,
      );
    } catch (_) {
      return false;
    }
  }

  bool get autorizado => _autorizado;

  Future<List<RegistroPeso>> leerPeso({int dias = 30}) async {
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, ahora.day)
        .subtract(Duration(days: dias - 1));
    try {
      final puntos = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: inicio,
        endTime: ahora,
      );
      final porDia = <String, double>{};
      for (final punto in puntos) {
        final v = punto.value;
        if (v is! NumericHealthValue) continue;
        final kg = v.numericValue.toDouble();
        final f = punto.dateFrom;
        final clave = '${f.year}-${f.month}-${f.day}';
        porDia[clave] = kg;
      }
      final lista = <RegistroPeso>[];
      porDia.forEach((clave, kg) {
        final partes = clave.split('-');
        lista.add(RegistroPeso(
          fecha: DateTime(
            int.parse(partes[0]),
            int.parse(partes[1]),
            int.parse(partes[2]),
          ),
          kilos: kg,
        ));
      });
      lista.sort((a, b) => a.fecha.compareTo(b.fecha));
      return lista;
    } catch (_) {
      return [];
    }
  }

  Future<List<int>> leerPasosPorDia({int dias = 30}) async {
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, ahora.day)
        .subtract(Duration(days: dias - 1));
    final futures = <Future<int>>[];
    for (int i = 0; i < dias; i++) {
      final dia = inicio.add(Duration(days: i));
      final fin = dia.add(const Duration(days: 1));
      futures.add(() async {
        try {
          return await _health.getTotalStepsInInterval(dia, fin) ?? 0;
        } catch (_) {
          return 0;
        }
      }());
    }
    return Future.wait(futures);
  }

  Future<List<int>> leerCaloriasActivasPorDia({int dias = 30}) async {
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, ahora.day)
        .subtract(Duration(days: dias - 1));
    final fin = ahora.add(const Duration(days: 1));
    try {
      final puntos = await _health.getHealthIntervalDataFromTypes(
        startDate: inicio,
        endDate: fin,
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        interval: const Duration(days: 1).inMilliseconds,
      );
      final porDia = <String, int>{};
      for (final punto in puntos) {
        final v = punto.value;
        if (v is! NumericHealthValue) continue;
        final f = punto.dateFrom;
        final clave = '${f.year}-${f.month}-${f.day}';
        porDia[clave] = v.numericValue.toInt();
      }
      final lista = <int>[];
      for (int i = 0; i < dias; i++) {
        final dia = inicio.add(Duration(days: i));
        final clave = '${dia.year}-${dia.month}-${dia.day}';
        lista.add(porDia[clave] ?? 0);
      }
      return lista;
    } catch (_) {
      return List.filled(dias, 0);
    }
  }

  Future<double?> _leerUltimoDato(HealthDataType tipo) async {
    try {
      final ahora = DateTime.now();
      final inicio = ahora.subtract(const Duration(days: 90));
      final puntos = await _health.getHealthDataFromTypes(
        types: [tipo],
        startTime: inicio,
        endTime: ahora,
      );
      if (puntos.isEmpty) return null;
      puntos.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final v = puntos.first.value;
      if (v is NumericHealthValue) return v.numericValue.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<double?> leerGrasaCorporal() => _leerUltimoDato(HealthDataType.BODY_FAT_PERCENTAGE);
  Future<double?> leerMasaMagra() => _leerUltimoDato(HealthDataType.LEAN_BODY_MASS);
  Future<double?> leerPesoActual() => _leerUltimoDato(HealthDataType.WEIGHT);

  Future<int?> leerBMR() async {
    try {
      final ahora = DateTime.now();
      final inicio = ahora.subtract(const Duration(days: 90));
      final puntos = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BASAL_ENERGY_BURNED],
        startTime: inicio,
        endTime: ahora,
      );
      if (puntos.isEmpty) return null;
      puntos.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final v = puntos.first.value;
      if (v is NumericHealthValue) return v.numericValue.round();
      return null;
    } catch (_) {
      return null;
    }
  }
}
