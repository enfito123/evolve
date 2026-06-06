class Comida {
  Comida({
    this.id,
    required this.nombre,
    required this.calorias,
    required this.fechaCreacion,
  });

  final int? id;
  final String nombre;
  final int calorias;
  final DateTime fechaCreacion;

  Map<String, Object?> aMapa() {
    return {
      'id': id,
      'nombre': nombre,
      'calorias': calorias,
      'fecha_creacion': fechaCreacion.millisecondsSinceEpoch,
    };
  }

  factory Comida.desdeMapa(Map<String, Object?> mapa) {
    return Comida(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
      calorias: mapa['calorias'] as int,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(mapa['fecha_creacion'] as int),
    );
  }

  bool esDeFecha(DateTime fecha) {
    return fechaCreacion.year == fecha.year &&
        fechaCreacion.month == fecha.month &&
        fechaCreacion.day == fecha.day;
  }
}
