import 'package:flutter/material.dart';
import '../theme/colores_app.dart';

class PaginaInfoCaloriasBasales extends StatelessWidget {
  const PaginaInfoCaloriasBasales({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        backgroundColor: ColoresApp.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Calorías basales'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Hero(),
              const SizedBox(height: 16),
              const _SeccionInfo(
                icono: Icons.question_mark_rounded,
                colorIcono: ColoresApp.acentoGradiente1,
                titulo: '¿Qué son?',
                texto:
                    'Las calorías basales, también llamadas Tasa Metabólica Basal (TMB), son la cantidad mínima de energía que tu cuerpo necesita para mantener sus funciones vitales en reposo: respirar, bombear sangre, regular la temperatura, mantener el cerebro activo y renovar células.\n\n'
                    'Es lo que gastarías si pasaras 24 horas en la cama sin moverte. Es el suelo de calorías que tu cuerpo te pide solo por existir.',
              ),
              const SizedBox(height: 12),
              const _SeccionInfo(
                icono: Icons.calculate_rounded,
                colorIcono: ColoresApp.acentoTeal,
                titulo: '¿Cómo se calculan?',
                texto:
                    'Evolve usa la fórmula de Mifflin-St Jeor, considerada la más precisa para adultos sanos. Tiene en cuenta tu peso, altura, edad y sexo biológico.',
                abajo: _FormulaCard(),
              ),
              const SizedBox(height: 12),
              const _SeccionInfo(
                icono: Icons.schedule_rounded,
                colorIcono: ColoresApp.acentoVerde,
                titulo: '¿Cómo funciona en la app?',
                texto:
                    'Tu TMB diaria se reparte de forma proporcional a lo largo del día. La tarjeta de Calorías muestra la parte que tu cuerpo ya ha consumido a la hora actual:',
                abajo: _LineasHora(),
              ),
              const SizedBox(height: 12),
              const _SeccionInfo(
                icono: Icons.balance_rounded,
                colorIcono: ColoresApp.acentoCalor,
                titulo: '¿Y las otras tarjetas?',
                texto:
                    'Tu balance diario combina tres piezas:\n\n'
                    '• Calorías basales (esta tarjeta): lo que tu cuerpo gasta en reposo.\n'
                    '• Calorías ingeridas: lo que comes, registrado desde Nutrición.\n'
                    '• Calorías por ejercicio: pendiente de integrar más adelante.\n\n'
                    'Balance = Basal − Ingeridas − Ejercicio. Si es positivo, estás en déficit; si es negativo, en superávit.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColoresApp.acentoCalor.withValues(alpha: 0.25),
            ColoresApp.acentoCalor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColoresApp.acentoCalor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: ColoresApp.acentoCalor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasa Metabólica Basal',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  'La energía mínima que tu cuerpo necesita en reposo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionInfo extends StatelessWidget {
  const _SeccionInfo({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.texto,
    this.abajo,
  });

  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String texto;
  final Widget? abajo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorIcono.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: colorIcono, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            texto,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresApp.textoPrimario,
                  height: 1.4,
                ),
          ),
          if (abajo != null) ...[
            const SizedBox(height: 14),
            abajo!,
          ],
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard();

  @override
  Widget build(BuildContext context) {
    final estiloMono = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          color: ColoresApp.textoPrimario,
          fontSize: 13,
        );
    final estiloEtiqueta = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ColoresApp.acentoTeal,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColoresApp.acentoTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hombres', style: estiloEtiqueta),
          const SizedBox(height: 4),
          Text('TMB = 10·peso + 6,25·altura − 5·edad + 5', style: estiloMono),
          const SizedBox(height: 12),
          Text('Mujeres', style: estiloEtiqueta),
          const SizedBox(height: 4),
          Text('TMB = 10·peso + 6,25·altura − 5·edad − 161', style: estiloMono),
          const SizedBox(height: 10),
          Text(
            'Peso en kg, altura en cm, edad en años.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.textoSecundario,
                ),
          ),
        ],
      ),
    );
  }
}

class _LineasHora extends StatelessWidget {
  const _LineasHora();

  @override
  Widget build(BuildContext context) {
    final estiloLinea = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ColoresApp.textoPrimario,
          fontSize: 13,
        );
    final estiloHora = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ColoresApp.acentoVerde,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        );
    Widget fila(String hora, String texto) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hora, style: estiloHora),
            const SizedBox(width: 10),
            Expanded(child: Text(texto, style: estiloLinea)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fila('00:00', 'has consumido 0 kcal'),
        fila('08:00', 'has consumido ~⅓ de tu TMB'),
        fila('12:00', 'has consumido la mitad'),
        fila('18:00', 'has consumido ~¾'),
        fila('23:59', 'has consumido prácticamente todo'),
        const SizedBox(height: 8),
        Text(
          'La tarjeta se actualiza cada minuto y, al volver de background, lee la hora del teléfono para mostrar el valor exacto sin consumir batería.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoSecundario,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}
