# Evolve

App de entrenamiento diario. Hecha con Flutter, compatible con Android e iOS

## Requisitos

- Flutter 3.38 o superior
- Dart 3.10 o superior
- Android Studio (para SDK Android) o Xcode (para iOS)
- Dispositivo Android con depuración USB activada, o un emulador

## Puesta en marcha

```bash
flutter pub get
flutter run
```

Para listar los dispositivos disponibles:

```bash
flutter devices
```

Para ejecutar en un dispositivo concreto:

```bash
flutter run -d <id_dispositivo>
```

## Estructura

```
lib/
├── main.dart                   # Punto de entrada de la app
├── theme/                      # Colores y tema de la aplicación
│   ├── colores_app.dart
│   └── tema_app.dart
├── pages/                      # Pantallas
│   └── pagina_inicio.dart
└── widgets/                    # Componentes reutilizables
    ├── barra_navegacion.dart
    ├── tarjeta_estadistica.dart
    ├── tarjeta_funcion.dart
    └── tarjeta_sesion.dart
```

## Compilar APK de release

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.
