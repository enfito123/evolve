import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class ServicioBeep {
  ServicioBeep._();
  static final ServicioBeep instancia = ServicioBeep._();

  late final Uint8List _bytesInicio;
  late final Uint8List _bytesFin;
  late final Uint8List _bytesCambio;
  AudioPlayer? _player;
  bool _listo = false;

  AudioPlayer get _ensurePlayer {
    if (_player == null) {
      _player = AudioPlayer();
    }
    return _player!;
  }

  Future<void> iniciar() async {
    if (_listo) return;
    _bytesInicio = _generarBeep(frecuencia: 880, duracionMs: 150, volumen: 0.8);
    _bytesFin = _generarBeep(frecuencia: 440, duracionMs: 200, volumen: 0.6);
    _bytesCambio = _generarBeep(frecuencia: 660, duracionMs: 120, volumen: 0.7);
    _listo = true;
  }

  Future<void> pitidoInicio() async {
    await iniciar();
    final player = _ensurePlayer;
    await player.stop();
    await player.setSource(BytesSource(_bytesInicio));
    await player.resume();
  }

  Future<void> pitidoFin() async {
    await iniciar();
    final player = _ensurePlayer;
    await player.stop();
    await player.setSource(BytesSource(_bytesFin));
    await player.resume();
  }

  Future<void> pitidoCambio() async {
    await iniciar();
    final player = _ensurePlayer;
    await player.stop();
    await player.setSource(BytesSource(_bytesCambio));
    await player.resume();
  }

  Future<void> parar() async {
    await _player?.stop();
  }

  Uint8List _generarBeep({
    required double frecuencia,
    required int duracionMs,
    required double volumen,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * duracionMs / 1000).round();
    final int dataSize = numSamples * 2;
    const int headerSize = 44;
    final ByteData data = ByteData(headerSize + dataSize);
    _escribirHeaderWav(data, sampleRate, dataSize);
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double envelope = max(0.0, 1.0 - t / (duracionMs / 1000.0));
      final double sample =
          sin(2 * pi * frecuencia * t) * volumen * envelope;
      final int valor = (sample * 32767).clamp(-32768, 32767).toInt();
      data.setUint16(headerSize + i * 2, valor, Endian.little);
    }
    return data.buffer.asUint8List();
  }

  void _escribirHeaderWav(ByteData data, int sampleRate, int dataSize) {
    void writeString(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    data.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    data.setUint32(40, dataSize, Endian.little);
  }
}
