import 'package:flutter/material.dart';
import '../theme/colores_app.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/tarjeta_estadistica.dart';
import '../widgets/tarjeta_funcion.dart';
import '../widgets/tarjeta_sesion.dart';

class PaginaInicio extends StatelessWidget {
  const PaginaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Encabezado(),
                    const SizedBox(height: 18),
                    const _Saludo(),
                    const SizedBox(height: 18),
                    const _FilaEstadisticas(),
                    const SizedBox(height: 18),
                    const _CuadriculaFunciones(),
                    const SizedBox(height: 18),
                    const TarjetaSesion(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const BarraNavegacion(),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Evolve',
          style: TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        _IconoRedondo(icono: Icons.notifications_none_rounded),
        const SizedBox(width: 10),
        const _Avatar(),
      ],
    );
  }
}

class _IconoRedondo extends StatelessWidget {
  const _IconoRedondo({required this.icono});

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icono, color: ColoresApp.textoPrimario, size: 20),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: ColoresApp.acentoGradiente1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Saludo extends StatelessWidget {
  const _Saludo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '¡Hola, Alejandro!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(width: 6),
            const Text('⚡', style: TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hoy es Miércoles, 25 Octubre',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _FilaEstadisticas extends StatelessWidget {
  const _FilaEstadisticas();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: TarjetaEstadistica(
            icono: Icons.directions_walk_rounded,
            colorIcono: ColoresApp.acentoGradiente1,
            valor: '65%',
            etiqueta: 'Pasos',
            detalle: '6.124 / 12.500',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TarjetaEstadistica(
            icono: Icons.local_fire_department_rounded,
            colorIcono: ColoresApp.acentoCalor,
            valor: '680',
            etiqueta: 'Calorías',
            detalle: '680 / 1800 kcal',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TarjetaEstadistica(
            icono: Icons.bolt_rounded,
            colorIcono: ColoresApp.acentoVerde,
            valor: '12',
            etiqueta: 'Racha',
            detalle: 'días seguidos',
          ),
        ),
      ],
    );
  }
}

class _CuadriculaFunciones extends StatelessWidget {
  const _CuadriculaFunciones();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: const [
        TarjetaFuncion(
          icono: Icons.trending_up_rounded,
          colorIcono: ColoresApp.acentoGradiente1,
          titulo: 'Mi Progreso',
          descripcion: 'Mira tendencias, fotos, guía',
        ),
        TarjetaFuncion(
          icono: Icons.fitness_center_rounded,
          colorIcono: ColoresApp.acentoCalor,
          titulo: 'Entrenamientos',
          descripcion: 'Inicia nuevas series, busca músculos',
        ),
        TarjetaFuncion(
          icono: Icons.calendar_today_rounded,
          colorIcono: ColoresApp.acentoVerde,
          titulo: 'Programas',
          descripcion: 'Mira por tu salud',
        ),
        TarjetaFuncion(
          icono: Icons.restaurant_rounded,
          colorIcono: ColoresApp.acentoTeal,
          titulo: 'Nutrición',
          descripcion: 'Track momentos, guardar',
        ),
        TarjetaFuncion(
          icono: Icons.groups_rounded,
          colorIcono: ColoresApp.acentoMorado,
          titulo: 'Comunidad',
          descripcion: 'Desafíos, amigos',
        ),
        TarjetaFuncion(
          icono: Icons.person_rounded,
          colorIcono: ColoresApp.acentoGradiente1,
          titulo: 'Perfil',
          descripcion: 'Seguimiento, datos',
        ),
      ],
    );
  }
}
