class Ejercicio {
  final String nombre;
  final double met;
  final String? segundoNombre;
  final int? puntoMedio;
  final String? imagen;
  const Ejercicio(this.nombre, this.met, {this.segundoNombre, this.puntoMedio, this.imagen});
}

class BloqueRutina {
  final String nombre;
  final List<Ejercicio> ejercicios;
  final int repeticiones;
  const BloqueRutina({
    required this.nombre,
    required this.ejercicios,
    required this.repeticiones,
  });
}

class Rutina {
  final String nombre;
  final String descripcion;
  final List<BloqueRutina> bloques;
  final int duracionEjercicio;
  final int duracionDescanso;
  final int descansoBloque;
  const Rutina({
    required this.nombre,
    required this.descripcion,
    required this.bloques,
    this.duracionEjercicio = 40,
    this.duracionDescanso = 15,
    this.descansoBloque = 5,
  });

  int get totalEjercicios {
    int total = 0;
    for (final b in bloques) {
      total += b.ejercicios.length * b.repeticiones;
    }
    return total;
  }

  int get duracionTotalSegundos {
    int total = 0;
    for (final b in bloques) {
      final porRonda = b.ejercicios.length * (duracionEjercicio + duracionDescanso);
      total += porRonda * b.repeticiones;
    }
    return total;
  }

  double kcalPorEjercicio(Ejercicio ejercicio, {double pesoKg = 70}) {
    final horas = duracionEjercicio / 3600.0;
    return (ejercicio.met * pesoKg * horas);
  }

  int kcalBloque(BloqueRutina bloque, {double pesoKg = 70}) {
    double total = 0;
    for (final ej in bloque.ejercicios) {
      total += kcalPorEjercicio(ej, pesoKg: pesoKg) * bloque.repeticiones;
    }
    return total.round();
  }

  int kcalTotales({double pesoKg = 70}) {
    int total = 0;
    for (final b in bloques) {
      total += kcalBloque(b, pesoKg: pesoKg);
    }
    return total;
  }

  static const Rutina acondicionamiento1 = Rutina(
    nombre: 'Rutina de acondicionamiento 1',
    descripcion: 'Rutina de 3 bloques con calentamiento, EMON 1 y EMON 2. '
        '40s de trabajo, 15s de descanso entre ejercicios, 45s entre bloques.',
    descansoBloque: 45,
    bloques: [
      BloqueRutina(
        nombre: 'Calentamiento',
        repeticiones: 2,
        ejercicios: [
          Ejercicio('90/90', 3.0, imagen: 'Ejercicios/9090/90_90.png'),
          Ejercicio('Gusanos', 4.0, imagen: 'Ejercicios/gusanos/gusanos.png'),
          Ejercicio('Jumping Jack', 8.0, imagen: 'Ejercicios/Jumping Jack/Jumping Jack.png'),
          Ejercicio('Sentadillas', 5.0, imagen: 'Ejercicios/Sentadilla/Sentadilla.png'),
        ],
      ),
      BloqueRutina(
        nombre: 'EMON 1',
        repeticiones: 3,
        ejercicios: [
          Ejercicio('5 Flexiones / 10 Tap', 8.0, imagen: 'Ejercicios/Flexiones y tap/Flexiones y tap.png'),
          Ejercicio('Dumbell Press', 5.0, imagen: 'Ejercicios/DumbellPress/DumbellPress.png'),
          Ejercicio('Dumbell Thruster', 8.0, imagen: 'Ejercicios/DumbellThruster/DumbellThruster.png'),
        ],
      ),
      BloqueRutina(
        nombre: 'EMON 2',
        repeticiones: 3,
        ejercicios: [
          Ejercicio('V Ups', 5.0, imagen: 'Ejercicios/Vups/Vups.png'),
          Ejercicio('Burpees', 12.0, imagen: 'Ejercicios/Burpees/Burpees.png'),
          Ejercicio('Dumbell Squat', 5.0, imagen: 'Ejercicios/DumbellSquat/DumbellSquat.png'),
        ],
      ),
    ],
  );

  static const Rutina acondicionamiento2 = Rutina(
    nombre: 'Rutina de acondicionamiento 2',
    descripcion: 'Rutina de 4 bloques con calentamiento, bloque 1, bloque 2 y bloque 3. '
        '40s de trabajo, 15s de descanso entre ejercicios, 45s entre bloques.',
    descansoBloque: 45,
    bloques: [
      BloqueRutina(
        nombre: 'Calentamiento',
        repeticiones: 2,
        ejercicios: [
          Ejercicio('Apertura de pierna lateral', 3.0, imagen: 'Ejercicios/AperturaLateralPierna/AperturaLateralPierna.png'),
          Ejercicio('Retracciones cervicales', 2.0, imagen: 'Ejercicios/Retracciones cervicales/RetraccionesCervicales.png'),
          Ejercicio('Estiramiento Spiderman', 3.0, imagen: 'Ejercicios/Estiramiento Spiderman/EstiramientoSpiderman.png'),
          Ejercicio('Skipping', 8.0, imagen: 'Ejercicios/Skipping/Skipping.png'),
        ],
      ),
      BloqueRutina(
        nombre: 'Bloque 1',
        repeticiones: 3,
        ejercicios: [
          Ejercicio('Zancada con mancuernas', 6.0, imagen: 'Ejercicios/LungeMancuernas/LungeMancuernas.png'),
          Ejercicio('Burpee y salto por encima de las mancuernas', 12.0, imagen: 'Ejercicios/BurpeeConSaltoMancuernas/BurpeeConSaltoMancuernas.png'),
          Ejercicio('Peso muerto con mancuernas', 6.0, imagen: 'Ejercicios/PesoMuertoConMancuernas/PesoMuertoConMancuernas.png'),
          Ejercicio('Thruster con mancuernas', 8.0, imagen: 'Ejercicios/ThrusterConMancuernas/ThrusterConMancuernas.png'),
        ],
      ),
      BloqueRutina(
        nombre: 'Bloque 2',
        repeticiones: 3,
        ejercicios: [
          Ejercicio('Hollow Body Hold', 5.0, segundoNombre: 'VUps', puntoMedio: 20, imagen: 'Ejercicios/HollowBodyHold/HollowBodyHold.png'),
          Ejercicio('Push up x10 y Shoulder tap', 8.0, imagen: 'Ejercicios/Flexiones y tap/Flexiones y tap.png'),
          Ejercicio('Jumping Jack', 8.0, imagen: 'Ejercicios/Jumping Jack/Jumping Jack.png'),
        ],
      ),
      BloqueRutina(
        nombre: 'Bloque 3',
        repeticiones: 3,
        ejercicios: [
          Ejercicio('Devil Press con mancuernas', 10.0, imagen: 'Ejercicios/DevilPress/DevilPress.png'),
          Ejercicio('V Ups con mancuerna', 5.0, imagen: 'Ejercicios/VUpMancuernas/VupMancuernas.png'),
          Ejercicio('Sentadilla con Kettlebell', 6.0, imagen: 'Ejercicios/SentadillaKettlebell/SentadillaKettlebell.png'),
        ],
      ),
    ],
  );

  static const Rutina acondicionamiento3 = Rutina(
    nombre: 'Rutina de acondicionamiento 3',
    descripcion: 'Rutina de 3 bloques con calentamiento, bloque 1 y bloque 2. '
        '40s de trabajo, 15s de descanso entre ejercicios, 45s entre bloques.',
    descansoBloque: 45,
    bloques: [
      BloqueRutina(
        nombre: 'Calentamiento',
        repeticiones: 2,
        ejercicios: [
          Ejercicio('Plancha Abdominal', 3.0),
          Ejercicio('Zancada Lateral', 5.0),
          Ejercicio('VUps', 5.0, imagen: 'Ejercicios/Vups/Vups.png'),
          Ejercicio('Skipping', 8.0, imagen: 'Ejercicios/Skipping/Skipping.png'),
        ],
      ),
      BloqueRutina(
        nombre: 'Bloque 1',
        repeticiones: 3,
        ejercicios: [
          Ejercicio('Sentadilla con salto', 8.0),
          Ejercicio('5 Flexiones / 10 Tap', 8.0, imagen: 'Ejercicios/Flexiones y tap/Flexiones y tap.png'),
          Ejercicio('Mountain Climbers', 8.0),
          Ejercicio('Vups Alterno', 5.0),
        ],
      ),
      BloqueRutina(
        nombre: 'Bloque 2',
        repeticiones: 3,
        ejercicios: [
          Ejercicio('Comba', 8.0),
          Ejercicio('Desplazamiento lateral en sentadilla', 6.0),
          Ejercicio('Thruster', 8.0, imagen: 'Ejercicios/DumbellThruster/DumbellThruster.png'),
        ],
      ),
    ],
  );
}
