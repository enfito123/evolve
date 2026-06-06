import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../modelos/comida.dart';

class ServicioNutricion {
  ServicioNutricion._();

  static final ServicioNutricion instancia = ServicioNutricion._();

  Database? _baseDatos;

  Future<Database> get _bd async {
    _baseDatos ??= await _abrirBaseDatos();
    return _baseDatos!;
  }

  Future<Database> _abrirBaseDatos() async {
    final ruta = p.join(await getDatabasesPath(), 'evolve_nutricion.db');
    return openDatabase(
      ruta,
      version: 1,
      onCreate: (bd, version) async {
        await bd.execute('''
          CREATE TABLE comidas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            calorias INTEGER NOT NULL,
            fecha_creacion INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> guardar(Comida comida) async {
    final bd = await _bd;
    return bd.insert('comidas', comida.aMapa()..remove('id'));
  }

  Future<int> eliminar(int id) async {
    final bd = await _bd;
    return bd.delete('comidas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Comida>> obtenerDeFecha(DateTime fecha) async {
    final bd = await _bd;
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    final filas = await bd.query(
      'comidas',
      where: 'fecha_creacion >= ? AND fecha_creacion < ?',
      whereArgs: [inicio.millisecondsSinceEpoch, fin.millisecondsSinceEpoch],
      orderBy: 'fecha_creacion DESC',
    );
    return filas.map(Comida.desdeMapa).toList();
  }
}
