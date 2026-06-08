enum Sexo { masculino, femenino }

class ModeloPerfil {
  const ModeloPerfil({
    required this.nombre,
    required this.edad,
    required this.sexo,
    required this.peso,
    required this.altura,
  });

  final String nombre;
  final int edad;
  final Sexo sexo;
  final double peso;
  final double altura;

  int get tmb {
    final base = 10.0 * peso + 6.25 * altura - 5.0 * edad;
    final valor = sexo == Sexo.masculino ? base + 5 : base - 161;
    return valor.round();
  }

  Map<String, dynamic> aMapa() => {
        'nombre': nombre,
        'edad': edad,
        'sexo': sexo.name,
        'peso': peso,
        'altura': altura,
      };

  ModeloPerfil copyWith({double? peso}) => ModeloPerfil(
        nombre: nombre,
        edad: edad,
        sexo: sexo,
        peso: peso ?? this.peso,
        altura: altura,
      );

  factory ModeloPerfil.desdeMapa(Map<String, dynamic> mapa) => ModeloPerfil(
        nombre: mapa['nombre'] as String,
        edad: mapa['edad'] as int,
        sexo: Sexo.values.firstWhere((s) => s.name == mapa['sexo']),
        peso: (mapa['peso'] as num).toDouble(),
        altura: (mapa['altura'] as num).toDouble(),
      );
}
