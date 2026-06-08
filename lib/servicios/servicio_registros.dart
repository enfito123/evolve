import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ServicioRegistros {
  ServicioRegistros._();
  static final ServicioRegistros instancia = ServicioRegistros._();

  Database? _baseDatos;

  Future<Database> get _bd async {
    _baseDatos ??= await _abrirBaseDatos();
    return _baseDatos!;
  }

  Future<Database> _abrirBaseDatos() async {
    final ruta = p.join(await getDatabasesPath(), 'evolve_registros.db');
    return openDatabase(
      ruta,
      version: 3,
      onCreate: (bd, version) async {
        await bd.execute('''
          CREATE TABLE registros_pasos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha INTEGER NOT NULL UNIQUE,
            pasos INTEGER NOT NULL,
            kcal INTEGER NOT NULL
          )
        ''');
        await bd.execute('''
          CREATE TABLE registros_ejercicio (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            kcal INTEGER NOT NULL
          )
        ''');
        await bd.execute('''
          CREATE TABLE registros_ejercicio_detalle (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            nombre TEXT NOT NULL,
            kcal INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (bd, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await bd.execute('''
            CREATE TABLE registros_ejercicio (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fecha TEXT NOT NULL,
              kcal INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await bd.execute('''
            CREATE TABLE registros_ejercicio_detalle (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fecha TEXT NOT NULL,
              nombre TEXT NOT NULL,
              kcal INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> guardarEjercicio(int kcal) async {
    if (kcal <= 0) return;
    final bd = await _bd;
    await bd.execute('''
      CREATE TABLE IF NOT EXISTS registros_ejercicio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        kcal INTEGER NOT NULL
      )
    ''');
    final hoy = DateTime.now();
    final fechaStr = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    await bd.insert('registros_ejercicio', {'fecha': fechaStr, 'kcal': kcal});
  }

  Future<void> guardarEjercicioDetalle(String nombre, int kcal) async {
    if (kcal <= 0 || nombre.isEmpty) return;
    final bd = await _bd;
    await bd.execute('''
      CREATE TABLE IF NOT EXISTS registros_ejercicio_detalle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        nombre TEXT NOT NULL,
        kcal INTEGER NOT NULL
      )
    ''');
    final hoy = DateTime.now();
    final fechaStr = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    await bd.insert('registros_ejercicio_detalle', {'fecha': fechaStr, 'nombre': nombre, 'kcal': kcal});
  }

  Future<List<Map<String, dynamic>>> ejerciciosHoyDetalle() async {
    final bd = await _bd;
    await bd.execute('''
      CREATE TABLE IF NOT EXISTS registros_ejercicio_detalle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        nombre TEXT NOT NULL,
        kcal INTEGER NOT NULL
      )
    ''');
    final hoy = DateTime.now();
    final fechaStr = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    return bd.query('registros_ejercicio_detalle', where: 'fecha = ?', whereArgs: [fechaStr]);
  }

  Future<int> kcalEjercicioHoy() async {
    final bd = await _bd;
    await bd.execute('''
      CREATE TABLE IF NOT EXISTS registros_ejercicio_detalle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        nombre TEXT NOT NULL,
        kcal INTEGER NOT NULL
      )
    ''');
    final hoy = DateTime.now();
    final fechaStr = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    final resultado = await bd.rawQuery(
      'SELECT COALESCE(SUM(kcal), 0) as total FROM registros_ejercicio_detalle WHERE fecha = ?',
      [fechaStr],
    );
    return (resultado.first['total'] as int?) ?? 0;
  }

  Future<void> guardarPasos(DateTime fecha, int pasos, int kcal) async {
    final bd = await _bd;
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final ms = inicio.millisecondsSinceEpoch;
    await bd.insert(
      'registros_pasos',
      {'fecha': ms, 'pasos': pasos, 'kcal': kcal},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerTodosLosPasos() async {
    final bd = await _bd;
    return bd.query('registros_pasos', orderBy: 'fecha ASC');
  }

  Future<int> totalKcalDesde(DateTime desde) async {
    final bd = await _bd;
    final ms = desde.millisecondsSinceEpoch;
    final resultado = await bd.rawQuery(
      'SELECT COALESCE(SUM(kcal), 0) as total FROM registros_pasos WHERE fecha >= ?',
      [ms],
    );
    return (resultado.first['total'] as int?) ?? 0;
  }

  Future<int> totalKcalEjercicioDesde(DateTime desde) async {
    final bd = await _bd;
    await bd.execute('''
      CREATE TABLE IF NOT EXISTS registros_ejercicio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        kcal INTEGER NOT NULL
      )
    ''');
    final fechaStr = '${desde.year}-${desde.month.toString().padLeft(2, '0')}-${desde.day.toString().padLeft(2, '0')}';
    final resultado = await bd.rawQuery(
      'SELECT COALESCE(SUM(kcal), 0) as total FROM registros_ejercicio WHERE fecha >= ?',
      [fechaStr],
    );
    return (resultado.first['total'] as int?) ?? 0;
  }

  Future<List<int>> kcalEjercicioPorDia(int dias) async {
    final bd = await _bd;
    await bd.execute('''
      CREATE TABLE IF NOT EXISTS registros_ejercicio_detalle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        nombre TEXT NOT NULL,
        kcal INTEGER NOT NULL
      )
    ''');
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, ahora.day).subtract(Duration(days: dias - 1));
    final resultado = await bd.rawQuery(
      'SELECT fecha, SUM(kcal) as total FROM registros_ejercicio_detalle WHERE fecha >= ? GROUP BY fecha ORDER BY fecha ASC',
      ['${inicio.year}-${inicio.month.toString().padLeft(2, '0')}-${inicio.day.toString().padLeft(2, '0')}'],
    );
    final mapa = <String, int>{};
    for (final fila in resultado) {
      mapa[fila['fecha'] as String] = (fila['total'] as int?) ?? 0;
    }
    return List.generate(dias, (i) {
      final fecha = inicio.add(Duration(days: i));
      final clave = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      return mapa[clave] ?? 0;
    });
  }

  Future<int> totalPasosDesde(DateTime desde) async {
    final bd = await _bd;
    final ms = desde.millisecondsSinceEpoch;
    final resultado = await bd.rawQuery(
      'SELECT COALESCE(SUM(pasos), 0) as total FROM registros_pasos WHERE fecha >= ?',
      [ms],
    );
    return (resultado.first['total'] as int?) ?? 0;
  }

  Future<DateTime?> primeraFecha() async {
    final bd = await _bd;
    final filas = await bd.query(
      'registros_pasos',
      orderBy: 'fecha ASC',
      limit: 1,
    );
    if (filas.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(filas.first['fecha'] as int);
  }
}
